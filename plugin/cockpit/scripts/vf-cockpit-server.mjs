// vf-cockpit-server — le crochet VibeFlow du serveur unique (67-04, P67-D-13, P67-D-14). Le serveur patché
// (serve.mjs, patch P13) l'importe à côté de lui et lui délègue tout /api/vf/* APRÈS son contrôle du Host et du
// jeton : même port que la page, aucun en-tête CORS. Le direct vient de vf-cockpit-live.mjs.
// Export : attach({ here, root, token, inject, log }) -> { ptoken, load, pageProjet, pageEquipe, jetonValide, route, stop,
//   avantQuestion, modes, argsAgent } (les trois derniers : crochets P14 des questions, 67-05).
//   GET /api/vf/events  flux SSE : retry, hello { seq, lock, who }, puis patch / structural / who / lock
//   GET /api/vf/etat    { mode, seq, derniereMaj, clients }
//   GET /api/vf/journal  { evenements } : les 100 derniers événements du direct (nom, séquence, date, compte), sans contenu
//   GET /api/vf/doing?id=  dernière commande d'UNE session, à la demande (schéma vibeflow/cockpit-doing@1)
//   GET /api/vf/transcript?id=  transcript réduit d'UN agent connu (mandat, messages, outils), à la demande (schéma vibeflow/cockpit-transcript@1)
//   GET /api/vf/modeles    { modeles, defaut, lab } : liste fermée des modèles, défaut effectif, identifiant du lab
//   GET /api/vf/git        topologie Git du lab (schéma vibeflow/cockpit-git@1), lecture seule (78-05)
//   GET /api/vf/git/entete dépôt, branche, worktree (schéma vibeflow/cockpit-git-entete@1)
//   GET /api/vf/lancer/cibles · POST /api/vf/lancer  lancement depuis les cartes (72-09) : servies par vf-cockpit-lancer.mjs, SEULEMENT sous `--terminal` (sinon une route inconnue)
// La dernière commande et le transcript ne figurent jamais dans le flux ni dans un fichier : la garde d'émission refuse tout
// objet qui porte une clé de la liste `interdits` du contrat (vf-cockpit-interface.json, à côté), à n'importe quelle profondeur.
// Contrat illisible ou liste vide : rien n'est émis (fermé par défaut).
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { startLive } from './vf-cockpit-live.mjs';
import { revealDoing, revealTranscript } from './vf-cockpit-who.mjs';
import { resolveScriptsDir } from './vf-cockpit-paths.mjs';
import { ID_RE } from './vf-cockpit-lecture.mjs';
import { extraireGraphe, insererGraphe } from './vf-cockpit-embed.mjs';
import { buildEquipeGraph, missionsEnCours } from './vf-cockpit-equipe-carte.mjs';
import { answerLocally, instructions } from './vf-cockpit-ask.mjs';
import { MODELES, resoudreModele, argsAgent as argsConfines } from './vf-cockpit-agent.mjs';
import { routeGit } from './vf-cockpit-git.mjs';
import { creerLancer } from './vf-cockpit-lancer.mjs';

let INTERDITS = []; // une seule source : le contrat, lu une fois au chargement
try { const l = JSON.parse(fs.readFileSync(path.join(path.dirname(fileURLToPath(import.meta.url)), 'vf-cockpit-interface.json'), 'utf8')).schemas?.['vibeflow/cockpit-who@2']?.interdits; if (Array.isArray(l)) INTERDITS = l.filter((k) => typeof k === 'string' && k); } catch { INTERDITS = []; }
const porteInterdit = (o) => !INTERDITS.length || (!!o && typeof o === 'object' && Object.entries(o).some(([k, v]) => INTERDITS.includes(k) || porteInterdit(v)));

export function attach({ here, root, token, inject, log = () => {} }) {
  const ptoken = crypto.randomBytes(16).toString('hex'); // onglet Projet : dit de quel onglet vient une requête
  let pageP = null, GP = null, gabarit = null, genP = 0, memoE = null; // genP : génération du gabarit ; memoE : la page Équipe déjà construite (AUDC-B-03)
  const load = () => { // relue après chaque réécriture de project.html par le direct
    genP++;
    try {
      const html = fs.readFileSync(path.join(here, 'project.html'), 'utf8');
      GP = extraireGraphe(html); gabarit = html; pageP = html.replace('</head>', inject.replace(token, ptoken) + '</head>');
    } catch { pageP = null; GP = null; gabarit = null; }
  };
  load();
  const lancer = creerLancer({ root, here, ptoken, log });
  if (!INTERDITS.length) log('error', 'contrat illisible : la liste des clés interdites est vide, rien ne sera émis');
  const dep = resoudreModele({ env: process.env });
  if (dep.avertissement) log('warn', dep.avertissement);

  const clients = new Set();
  // journal du direct (derniers événements poussés, borné à 100) : GET /api/vf/journal, derrière le jeton ; que des comptes et des dates, jamais de contenu interdit
  const journal = [];
  const noter = (nom, d) => {
    const e = { evenement: nom, seq: d?.seq ?? null, at: d?.at ?? Date.now() };
    if (nom === 'patch') e.statuts = Array.isArray(d.patch) ? d.patch.length : 0;
    else if (nom === 'who') e.actifs = (d.who?.workers || []).filter((w) => !w.stale && w.etat !== 'termine').length;
    journal.push(e); if (journal.length > 100) journal.shift();
  };
  const diffuser = (nom, data) => {
    if (porteInterdit(data)) { log('error', `événement ${nom} refusé : contenu interdit`); return; }
    noter(nom, data);
    const s = `event: ${nom}\ndata: ${JSON.stringify(data)}\n\n`;
    for (const c of clients) c.write(s);
  };
  let live = null;
  try {
    live = startLive({ root, sortie: here, log, onEvent: (nom, data) => { if (nom === 'structural' || nom === 'patch') load(); diffuser(nom, data); } });
  } catch (e) { log('error', `direct indisponible : ${e.message}`); }
  lancer.sourceWho(() => (live ? live.snapshot().who : null)); // états attendue / vue / terminee des cartes lancées (72-07)

  const json = (res, code, obj) => { res.writeHead(code, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' }); res.end(JSON.stringify(obj)); };

  function route(req, res, url) {
    if (!url.pathname.startsWith('/api/vf/')) return false;
    if (req.method !== 'GET') { if (lancer.reconnait(url)) { lancer.traiter(req, res, url); return true; } res.writeHead(405); res.end(); return true; }
    if (url.pathname === '/api/vf/events') {
      res.writeHead(200, { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-store', Connection: 'keep-alive' });
      res.write('retry: 1000\n\n');
      const snap = live ? live.snapshot() : { seq: 0, lock: { available: false }, who: { workers: [], sources: {} } };
      if (porteInterdit(snap)) { log('error', 'hello refusé : contenu interdit'); res.end(); return true; }
      res.write(`event: hello\ndata: ${JSON.stringify(snap)}\n\n`);
      clients.add(res);
      const ka = setInterval(() => res.write(': ka\n\n'), 15000);
      req.on('close', () => { clearInterval(ka); clients.delete(res); });
      return true;
    }
    if (url.pathname === '/api/vf/etat') { json(res, 200, { ...(live ? live.etat() : { mode: 'absent', seq: 0, derniereMaj: null }), clients: clients.size }); return true; }
    if (url.pathname === '/api/vf/journal') { json(res, 200, { evenements: journal }); return true; }
    if (url.pathname === '/api/vf/doing') {
      const id = url.searchParams.get('id');
      if (typeof id !== 'string' || !ID_RE.test(id)) { json(res, 400, { erreur: 'id-invalide' }); return true; }
      // jamais journalisée ni écrite : la réponse part et c'est tout
      json(res, 200, revealDoing(root, id, { scriptsDir: resolveScriptsDir(here) }));
      return true;
    }
    if (url.pathname === '/api/vf/transcript') {
      const id = url.searchParams.get('id');
      if (typeof id !== 'string' || !ID_RE.test(id)) { json(res, 400, { erreur: 'id-invalide' }); return true; }
      // à la demande seulement, jamais journalisée ni écrite (P69-D-19) : la réponse part et c'est tout
      json(res, 200, revealTranscript(root, id, { scriptsDir: resolveScriptsDir(here) }));
      return true;
    }
    if (url.pathname === '/api/vf/modeles') {
      let reel = root; try { reel = fs.realpathSync(root); } catch {} // le lab peut disparaître en cours de route : jamais une exception
      json(res, 200, { modeles: MODELES, defaut: dep.modele, lab: crypto.createHash('sha256').update(reel).digest('hex').slice(0, 12) });
      return true;
    }
    if (routeGit(req, res, url, { root, json })) return true; // 78-05 : topologie Git, GET seul
    if (lancer.get(req, res, url)) return true;
    res.writeHead(404); res.end(); return true;
  }

  // ---- crochets des questions (P14) : la page d'où vient la question se reconnaît à son jeton ----
  function avantQuestion({ req, body, send }) {
    body.project = req.headers['x-floorplan-token'] === ptoken && !!GP; // jamais lu du corps : le navigateur ne le fixe pas
    const r = resoudreModele({ choix: body.model, env: process.env });
    if (r.erreur) { send('failure', { code: 'modele_refuse', message: `Modèle refusé : seuls ${MODELES.join(', ')} sont admis.` }); return 'repondu'; }
    body.modeleResolu = r.modele; // écrasé à chaque question, jamais écrit sur disque ni journalisé avec la question
    if (body.project && (!body.mode || body.mode === 'ask')) { // même avec une conversation de l'agent en cours : le navigateur renvoie `session` après toute réponse de l'agent, et une forme courante doit rester immédiate (recette 67, 2026-11-02)
      const t0 = Date.now();
      let local = null;
      try { local = answerLocally(GP, String(body.question || '')); } catch (e) { log('warn', `réponse locale en échec, repli sur l'agent : ${String(e.message).slice(0, 120)}`); } // jamais une exception qui tue le serveur
      if (local) { log('local', `projet · réponse locale · ${Date.now() - t0} ms`); send('answer', local); return 'repondu'; }
    }
    return 'agent';
  }
  const modes = (MODES, body) => (body.project && GP ? { ...MODES, ask: { ...MODES.ask, instructions: instructions(GP) } } : MODES); // flow et change gardent leur schéma
  const argsAgent = (args, body) => argsConfines(args, { modele: body.modeleResolu || resoudreModele({ env: process.env }).modele });

  return {
    ptoken, load, route, avantQuestion, modes, argsAgent,
    pageProjet: () => pageP,
    // onglet Équipe (69-05, P69-D-17) : construite en mémoire depuis le gabarit de project.html, jamais écrite ; jeton de la page Code (inject tel quel)
    // AUDC-B-03 : mémorisée tant que rien n'a changé (même gabarit, même instantané du direct, mêmes cartes lancées) : une requête de plus ne reconstruit pas 2,5 Mo
    pageEquipe: () => {
      if (!gabarit) return null;
      const who = live ? live.snapshot().who : null;
      if (!INTERDITS.length || (who && porteInterdit(who))) { log('error', 'page Équipe refusée : contrat illisible ou contenu interdit'); return null; } // même garde que le flux, fermée par défaut
      // `nom` : celui que la page Projet affiche (P69-D-33), jamais le nom du dossier
      const cles = JSON.stringify([...lancer.lancees()]);
      if (memoE && memoE.gen === genP && memoE.who === who && memoE.cles === cles) return memoE.html;
      const g = buildEquipeGraph(who, { nom: String(GP?.project?.name || '').replace(/ — Projet$/, '') || GP?.meta?.rootName || path.basename(root), racine: GP?.meta?.root, logos: GP?.meta?.vfLogos, git: GP?.meta?.vfGit, missions: missionsEnCours(GP), lancees: lancer.lancees() }); // 78-04 : en-tête Git et bloc de vue
      const html = insererGraphe(gabarit, g).replace(/<title>[^<]*<\/title>/, '<title>VibeFlow · Équipe</title>').replace('</head>', () => inject + '</head>');
      memoE = { gen: genP, who, cles, html };
      return html;
    },
    jetonValide: (j) => typeof j === 'string' && j === ptoken,
    stop() { live?.stop(); for (const c of clients) c.end(); },
  };
}
