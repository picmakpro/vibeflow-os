// vf-cockpit-server — le crochet VibeFlow du serveur unique (67-04, P67-D-13, P67-D-14). Le serveur patché
// (serve.mjs, patch P13) l'importe à côté de lui et lui délègue tout /api/vf/* APRÈS son contrôle du Host et du
// jeton : même port que la page, aucun en-tête CORS. Le direct vient de vf-cockpit-live.mjs.
// Export : attach({ here, root, token, inject, log, routes = ROUTES, scriptsDir = trustedScriptsDir() }) -> { ptoken, load, pageProjet, pageEquipe, jetonValide,
//   route, stop, avantQuestion, modes, argsAgent, substituerConsigne } (les quatre derniers : crochets P14 des questions, 67-05 ; 79-06 : le dossier du module,
//   parent du dossier de scripts, remplace le jeton `<module>` des consignes et des règles de l'agent ; refusé ou introuvable, l'agent est indisponible), ROUTES, repondreGardee.
// Routes GET /api/vf/* : la table ROUTES (une ligne par route : chemin, lecteur, régime). Ajouter une route = un lecteur et UNE ligne à sa place
//   alphabétique ; sa réponse sort par repondreGardee (accès contrôlé, garde d'émission, no-store, 503 emission-refusee). Régimes HISTORIQUE (réponse
//   JSON simple, comportement antérieur) et FLUX (le lecteur écrit le flux). Mécanisme : vf-cockpit-routes.mjs. Le sous-routeur Git (/api/vf/git…)
//   et celui du lanceur (/api/vf/lancer/cibles · POST /api/vf/lancer, SEULEMENT sous `--terminal`) restent des délégués placés après la table.
// GET /api/vf/state (79-12, SOCL-16) : l'état du cockpit en une enveloppe, lu en mémoire (vf-cockpit-state.mjs) ; jamais une collecte à la demande.
// La dernière commande et le transcript ne figurent jamais dans le flux ni dans un fichier : la garde d'émission refuse tout
// objet qui porte une clé de la liste `interdits` du contrat (vf-cockpit-interface.json, à côté), à n'importe quelle profondeur.
// Contrat illisible ou liste vide : rien n'est émis (fermé par défaut).
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { startLive } from './vf-cockpit-live.mjs';
import { revealDoing, revealTranscript } from './vf-cockpit-who.mjs';
import { resolveScriptsDir, trustedScriptsDir, finDans } from './vf-cockpit-paths.mjs';
import { dossierModule, substituerModule } from './vf-cockpit-module.mjs';
import { ID_RE } from './vf-cockpit-lecture.mjs';
import { extraireGraphe, insererGraphe } from './vf-cockpit-embed.mjs';
import { buildEquipeGraph, missionsEnCours } from './vf-cockpit-equipe-carte.mjs';
import { answerLocally, instructions } from './vf-cockpit-ask.mjs';
import { MODELES, resoudreModele, argsAgent as argsConfines } from './vf-cockpit-agent.mjs';
import { routeGit } from './vf-cockpit-git.mjs';
import { creerLancer } from './vf-cockpit-lancer.mjs';
import { HISTORIQUE, FLUX, reponse, controlerAcces, creerRepartiteur } from './vf-cockpit-routes.mjs';
import { lireState, LECTEURS } from './vf-cockpit-state.mjs';
import { brancherFluxEtat, VIE_MS } from './vf-cockpit-flux-etat.mjs';
import os from 'node:os';
import { ailleurs, demander, REPIT_MS } from './vf-cockpit-etat-officiel.mjs';
import { arbresGitAsync } from './vf-cockpit-arbres.mjs';

let INTERDITS = []; // une seule source : le contrat, lu une fois au chargement
try { const l = JSON.parse(fs.readFileSync(path.join(path.dirname(fileURLToPath(import.meta.url)), 'vf-cockpit-interface.json'), 'utf8')).schemas?.['vibeflow/cockpit-who@2']?.interdits; if (Array.isArray(l)) INTERDITS = l.filter((k) => typeof k === 'string' && k); } catch { INTERDITS = []; }
const porteInterdit = (o) => !INTERDITS.length || (!!o && typeof o === 'object' && Object.entries(o).some(([k, v]) => INTERDITS.includes(k) || porteInterdit(v)));

// comparaison de jeton en temps constant (AUDC-B-06) : jamais un `===` sur un secret
const memeJeton = (a, b) => { if (typeof a !== 'string' || typeof b !== 'string') return false; const x = Buffer.from(a), y = Buffer.from(b); return x.length === y.length && crypto.timingSafeEqual(x, y); };

// réponse gardée (A11, C0) : accès contrôlé (`acces` obligatoire), puis garde d'émission, puis en-têtes, puis écriture ; jamais de CORS
export function repondreGardee(req, res, corps, { code = 200, entetes = {}, acces, log = () => {} } = {}) {
  if (typeof acces !== 'function') throw new Error('repondreGardee : contrôle d\'accès absent');
  const a = acces(req);
  if (!a || a.ok !== true) { res.writeHead(Number(a && a.code) || 403); res.end(); return; }
  const base = { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' }; // garde:reponse-nostore
  if (corps !== undefined && porteInterdit(corps)) {
    log('error', 'réponse refusée : contenu interdit ou contrat illisible');
    res.writeHead(503, base); res.end('{"erreur":"emission-refusee"}'); return; // garde:reponse-503
  }
  const extra = {};
  for (const [k, v] of Object.entries(entetes || {})) if (!/^(access-control-|content-type$|cache-control$)/i.test(k)) extra[k] = v;
  res.writeHead(code, { ...extra, ...base }); res.end(corps === undefined ? undefined : JSON.stringify(corps));
}

// lecteurs : `lecteur(ctx, req, url)` rend un corps JSON, une reponse(…) ou une promesse de l'un ou de l'autre ; ctx est gelé (root, here, log, dep, clients, journal, live, fluxFerme)
const lireEtat = (c) => ({ ...(c.live ? c.live.etat() : { mode: 'absent', seq: 0, derniereMaj: null }), clients: c.clients.size });
const lireJournal = (c) => ({ evenements: c.journal });
const idOuRefus = (url) => { const id = url.searchParams.get('id'); return typeof id === 'string' && ID_RE.test(id) ? id : null; };
const lireDoing = (c, req, url) => { // jamais journalisée ni écrite : la réponse part et c'est tout
  const id = idOuRefus(url);
  return id === null ? reponse(400, { erreur: 'id-invalide' }) : revealDoing(c.root, id, { scriptsDir: resolveScriptsDir(c.here) });
};
const lireTranscript = (c, req, url) => { // à la demande seulement, jamais journalisée ni écrite (P69-D-19)
  const id = idOuRefus(url);
  return id === null ? reponse(400, { erreur: 'id-invalide' }) : revealTranscript(c.root, id, { scriptsDir: resolveScriptsDir(c.here) });
};
const lireModeles = (c) => {
  let reel = c.root; try { reel = fs.realpathSync(c.root); } catch {} // le lab peut disparaître en cours de route : jamais une exception
  return { modeles: MODELES, defaut: c.dep.modele, lab: crypto.createHash('sha256').update(reel).digest('hex').slice(0, 12) };
};
// GET /api/vf/ailleurs (73-02, P73-D-16, P73-D-35) : sessions d'AUTRES labs qui vous attendent, par NOM de lab seulement ; dérive de
// la dernière lecture officielle gardée en mémoire de CE processus (la collecte lit la sienne dans son fil : invisible ici ;
// `demander` relance la lecture au plus une fois par REPIT_MS, jamais une par requête). Les arbres du lab sont relus au plus une
// fois par REPIT_MS ; jamais de git dans un autre dépôt ; la route attend (BORNE_AILLEURS_MS) les lectures en vol, null si aucune lecture fraîche n'aboutit.
// Garde d'émission propre à ailleurs@1 (audit 73-02) : la liste d'interdits de who@2 (porteInterdit) ne dit rien de ce contrat ;
// chaque entrée a EXACTEMENT les clés { lab, n }, sinon elle ne sort pas.
const exacte = (e) => !!e && typeof e === 'object' && Object.keys(e).sort().join() === 'lab,n';
const racinesLab = new Map(); // racine du lab -> { at, liste }
const BORNE_AILLEURS_MS = 3000; // revue 73 : la route attend les lectures en vol, au plus ce temps (la boucle reste libre : attente asynchrone)
const lireAilleurs = async (c) => {
  const now = Date.now();
  const officiel = demander({ home: os.homedir(), cwd: c.root });
  let m = racinesLab.get(c.root);
  if (!m) { m = { at: 0, liste: null, enCours: false, vol: null }; racinesLab.set(c.root, m); }
  if (!m.enCours && now - m.at >= REPIT_MS) { // lecture ASYNCHRONE (P78-D-41) ; la route attend sa fin, bornée
    m.enCours = true; m.at = now;
    m.vol = arbresGitAsync(c.root, { fin: finDans(5000) }).then((a) => { m.liste = a.map((t) => t.chemin); }, () => { m.liste = null; })
      .finally(() => { m.enCours = false; });
  }
  let minuteur; // lectures en vol (état officiel, arbres du lab) attendues ensemble ;
  // au-delà de la borne : ce que la mémoire porte déjà (null si rien de frais)
  await Promise.race([Promise.all([officiel, m.enCours ? m.vol : null]), new Promise((fin) => { minuteur = setTimeout(fin, BORNE_AILLEURS_MS); })]);
  clearTimeout(minuteur);
  const l = ailleurs(os.homedir(), { racines: m.liste });
  return { schema: 'vibeflow/cockpit-ailleurs@1', ailleurs: Array.isArray(l) ? l.filter(exacte) : l };
};
function ouvrirFlux(c, req, url, res) {
  res.writeHead(200, { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-store', Connection: 'keep-alive' });
  res.write('retry: 1000\n\n');
  let ouvert = true;
  req.on('close', () => { ouvert = false; c.clients.delete(res); c.fluxFerme(); }); // inscrite avant tout délai : un onglet fermé pendant l'attente ne reçoit rien
  c.live?.reveil?.(); // AUDC-H2 : rien n'a été collecté depuis un moment s'il n'y avait aucun onglet
  // 79-09 : `hello` attend la première collecte (5 s au plus), puis part complet ; les doubles de suites n'ont pas `pret`
  Promise.resolve(c.live?.pret?.(5000)).catch(() => {}).then(() => {
    if (!ouvert) return;
    const vide = { seq: 0, at: Date.now(), verrous: { etat: 'absente', plat: false, liste: [] } }; // A15 : la forme de hello.lock avant toute collecte
    const snap = c.live ? c.live.snapshot() : { seq: 0, lock: vide, who: { workers: [], sources: {} } };
    if (porteInterdit(snap)) { c.log('error', 'hello refusé : contenu interdit'); res.end(); return; }
    res.write(`event: hello\ndata: ${JSON.stringify(snap)}\n\n`);
    c.clients.add(res);
  });
}

// la table des routes (A10) : une ligne par route, ordre alphabétique par chemin ; sans régime = gardée
export const ROUTES = [
  ['/api/vf/ailleurs', lireAilleurs],
  ['/api/vf/doing', lireDoing, HISTORIQUE],
  ['/api/vf/etat', lireEtat, HISTORIQUE],
  ['/api/vf/events', ouvrirFlux, FLUX],
  ['/api/vf/journal', lireJournal, HISTORIQUE],
  ['/api/vf/modeles', lireModeles, HISTORIQUE],
  ['/api/vf/state', lireState],
  ['/api/vf/transcript', lireTranscript, HISTORIQUE],
];

export function attach({ here, root, token, inject, log = () => {}, routes = ROUTES, scriptsDir = trustedScriptsDir(), vieMs = VIE_MS }) {
  const dossier = dossierModule(scriptsDir); // racine réelle du module (null si introuvable : jamais une exception ici, l'agent est refusé à la question)
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
  let dernierFlux = 0; // AUDC-H3 : instant de la dernière fermeture d'un flux de page ; le délai d'inactivité repart de là
  // journal du direct (derniers événements poussés, borné à 100) : GET /api/vf/journal, derrière le jeton ; que des comptes et des dates, jamais de contenu interdit
  const journal = [];
  const noter = (nom, d) => {
    const e = { evenement: nom, seq: d?.seq ?? null, at: d?.at ?? Date.now() };
    if (nom === 'patch') e.statuts = Array.isArray(d.patch) ? d.patch.length : 0;
    else if (nom === 'who') e.actifs = (d.who?.workers || []).filter((w) => !w.stale && w.etat !== 'termine' && w.etat !== 'au-repos' && w.etat !== 'attend').length;
    journal.push(e); if (journal.length > 100) journal.shift();
  };
  const diffuser = (nom, data) => {
    if (porteInterdit(data)) { log('error', `événement ${nom} refusé : contenu interdit`); return; }
    if (nom !== 'vie') noter(nom, data); // garde:vie-journal
    const s = `event: ${nom}\ndata: ${JSON.stringify(data)}\n\n`;
    for (const c of clients) c.write(s);
  };
  const aClient = () => clients.size > 0 || LECTEURS.actif(); // garde:lecteur-arme
  let live = null;
  try {
    live = startLive({ root, sortie: here, log, onEvent: (nom, data) => { if (nom === 'structural' || nom === 'patch') load(); diffuser(nom, data); }, aClient, nbClients: () => clients.size, garde: (o) => !porteInterdit(o) }); // AUDC-H2 : le filet ne collecte que si un onglet écoute ; garde : l'instantané passe la garde d'émission avant sa pose
  } catch (e) { log('error', `direct indisponible : ${e.message}`); }
  const fluxEtat = brancherFluxEtat({ diffuser, seq: () => (live ? live.etat().seq : 0), nbClients: () => clients.size, vieMs }); // 79-12 : `vie` et `etat`
  lancer.sourceWho(() => (live ? live.snapshot().who : null)); // états attendue / vue / terminee des cartes lancées (72-07)

  const json = (res, code, obj) => { res.writeHead(code, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' }); res.end(JSON.stringify(obj)); };

  const acces = (req) => controlerAcces(req, { jetonValide: (j) => memeJeton(j, token) || memeJeton(j, ptoken) }); // le jeton de la page Code ou celui de la page Projet
  const contexte = Object.freeze({ root, here, log, dep, clients, journal, get live() { return live; }, fluxFerme: () => { dernierFlux = Date.now(); } });
  const repondre = (req, res, corps, o) => repondreGardee(req, res, corps, { ...o, acces, log });
  const repartiteur = creerRepartiteur({ table: routes, contexte, repondre, json, acces, log });

  function route(req, res, url) {
    if (!url.pathname.startsWith('/api/vf/')) return false;
    if (req.method !== 'GET') { if (lancer.reconnait(url)) { lancer.traiter(req, res, url); return true; } res.writeHead(405); res.end(); return true; }
    if (repartiteur.servir(req, res, url)) return true;
    if (routeGit(req, res, url, { root, json })) return true; // 78-05 : topologie Git, GET seul
    if (lancer.get(req, res, url)) return true;
    res.writeHead(404); res.end(); return true;
  }

  // ---- crochets des questions (P14) : la page d'où vient la question se reconnaît à son jeton ----
  function avantQuestion({ req, body, send }) {
    body.project = memeJeton(req.headers['x-vf-cockpit-token'], ptoken) && !!GP; // jamais lu du corps : le navigateur ne le fixe pas
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
  const substituerConsigne = (texte) => substituerModule(texte, dossier); // lève (français) si le dossier du module est refusé : appelée à la question, jamais au chargement
  const modes = (MODES, body) => { // flow et change gardent leur schéma ; chaque consigne reçoit le chemin du module à la place du jeton
    const base = body.project && GP ? { ...MODES, ask: { ...MODES.ask, instructions: instructions(GP) } } : MODES;
    return Object.fromEntries(Object.entries(base).map(([nom, m]) => [nom, { ...m, instructions: substituerConsigne(m.instructions) }]));
  };
  const argsAgent = (args, body) => argsConfines(args, { modele: body.modeleResolu || resoudreModele({ env: process.env }).modele, dossierModule: dossier });

  return {
    ptoken, load, route, avantQuestion, modes, argsAgent, substituerConsigne,
    pageProjet: () => pageP,
    // onglet Équipe (69-05, P69-D-17) : construite en mémoire depuis le gabarit de project.html, jamais écrite ; jeton de la page Code (inject tel quel)
    // AUDC-B-03 : mémorisée tant que rien n'a changé (même gabarit, même instantané du direct, mêmes cartes lancées) : une requête de plus ne reconstruit pas 2,5 Mo
    pageEquipe: () => {
      if (!gabarit) return null;
      live?.reveil?.();
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
    dernierFlux: () => dernierFlux,
    ouverts: () => clients.size, // AUDC-H3 : des flux de page ouverts retiennent l'arrêt sur inactivité
    jetonValide: (j) => memeJeton(j, ptoken),
    // AUDC-H1 : une page n'ouvre qu'UN flux (celui-ci). Le rechargement de la carte y passe (sans séquence ni journal : la page se recharge) et chaque flux ouvert compte comme une page ouverte.
    diffuserCarte: (nom, data) => { if (nom !== 'reload') return; const s = `event: reload\ndata: ${JSON.stringify(data || {})}\n\n`; for (const c of clients) c.write(s); },
    nbPages: () => clients.size,
    stop() { fluxEtat.stop(); live?.stop(); for (const c of clients) c.end(); },
  };
}
