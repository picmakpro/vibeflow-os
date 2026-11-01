// vf-cockpit-server — le crochet VibeFlow du serveur unique (67-04, P67-D-13, P67-D-14). Le serveur patché
// (serve.mjs, patch P13) l'importe à côté de lui et lui délègue tout /api/vf/* APRÈS son contrôle du Host et du
// jeton : même port que la page, aucun en-tête CORS. Le direct vient de vf-cockpit-live.mjs.
// Export : attach({ here, root, token, inject, log }) -> { ptoken, load, pageProjet, jetonValide, route, stop,
//   avantQuestion, modes, argsAgent } (les trois derniers : crochets P14 des questions, 67-05).
//   GET /api/vf/events  flux SSE : retry, hello { seq, lock, who }, puis patch / structural / who / lock
//   GET /api/vf/etat    { mode, seq, derniereMaj, clients }
//   GET /api/vf/doing?id=  dernière commande d'UNE session, à la demande (schéma vibeflow/cockpit-doing@1)
//   GET /api/vf/modeles    { modeles, defaut, lab } : liste fermée des modèles, défaut effectif, identifiant du lab
// La dernière commande (`doing`) ne figure jamais dans le flux ni dans un fichier : un test interne refuse
// d'émettre tout objet qui porte cette clé, à n'importe quelle profondeur (ceinture en plus des bretelles du socle).
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { startLive } from './vf-cockpit-live.mjs';
import { revealDoing } from './vf-cockpit-who.mjs';
import { resolveScriptsDir } from './vf-cockpit-paths.mjs';
import { extraireGraphe } from './vf-cockpit-embed.mjs';
import { answerLocally, instructions } from './vf-cockpit-ask.mjs';
import { MODELES, resoudreModele, argsAgent as argsConfines } from './vf-cockpit-agent.mjs';

const porteDoing = (o) => !!o && typeof o === 'object' && Object.entries(o).some(([k, v]) => k === 'doing' || porteDoing(v));
const ID_RE = /^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$/;

export function attach({ here, root, token, inject, log = () => {} }) {
  const ptoken = crypto.randomBytes(16).toString('hex'); // onglet Projet : dit de quel onglet vient une requête
  let pageP = null, GP = null;
  const load = () => { // relue après chaque réécriture de project.html par le direct
    try {
      const html = fs.readFileSync(path.join(here, 'project.html'), 'utf8');
      GP = extraireGraphe(html); pageP = html.replace('</head>', inject.replace(token, ptoken) + '</head>');
    } catch { pageP = null; GP = null; }
  };
  load();
  const dep = resoudreModele({ env: process.env });
  if (dep.avertissement) log('warn', dep.avertissement);

  const clients = new Set();
  const diffuser = (nom, data) => {
    if (porteDoing(data)) { log('error', `événement ${nom} refusé : porte une clé doing`); return; }
    const s = `event: ${nom}\ndata: ${JSON.stringify(data)}\n\n`;
    for (const c of clients) c.write(s);
  };
  let live = null;
  try {
    live = startLive({ root, sortie: here, log, onEvent: (nom, data) => { if (nom === 'structural' || nom === 'patch') load(); diffuser(nom, data); } });
  } catch (e) { log('error', `direct indisponible : ${e.message}`); }

  const json = (res, code, obj) => { res.writeHead(code, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' }); res.end(JSON.stringify(obj)); };

  function route(req, res, url) {
    if (!url.pathname.startsWith('/api/vf/')) return false;
    if (req.method !== 'GET') { res.writeHead(405); res.end(); return true; }
    if (url.pathname === '/api/vf/events') {
      res.writeHead(200, { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-store', Connection: 'keep-alive' });
      res.write('retry: 1000\n\n');
      const snap = live ? live.snapshot() : { seq: 0, lock: { available: false }, who: { workers: [], sources: {} } };
      if (porteDoing(snap)) { log('error', 'hello refusé : porte une clé doing'); res.end(); return true; }
      res.write(`event: hello\ndata: ${JSON.stringify(snap)}\n\n`);
      clients.add(res);
      const ka = setInterval(() => res.write(': ka\n\n'), 15000);
      req.on('close', () => { clearInterval(ka); clients.delete(res); });
      return true;
    }
    if (url.pathname === '/api/vf/etat') { json(res, 200, { ...(live ? live.etat() : { mode: 'absent', seq: 0, derniereMaj: null }), clients: clients.size }); return true; }
    if (url.pathname === '/api/vf/doing') {
      const id = url.searchParams.get('id');
      if (typeof id !== 'string' || !ID_RE.test(id)) { json(res, 400, { erreur: 'id-invalide' }); return true; }
      // jamais journalisée ni écrite : la réponse part et c'est tout
      json(res, 200, revealDoing(root, id, { scriptsDir: resolveScriptsDir(here) }));
      return true;
    }
    if (url.pathname === '/api/vf/modeles') {
      let reel = root; try { reel = fs.realpathSync(root); } catch {} // le lab peut disparaître en cours de route : jamais une exception
      json(res, 200, { modeles: MODELES, defaut: dep.modele, lab: crypto.createHash('sha256').update(reel).digest('hex').slice(0, 12) });
      return true;
    }
    res.writeHead(404); res.end(); return true;
  }

  // ---- crochets des questions (P14) : la page d'où vient la question se reconnaît à son jeton ----
  function avantQuestion({ req, body, send }) {
    body.project = req.headers['x-floorplan-token'] === ptoken && !!GP; // jamais lu du corps : le navigateur ne le fixe pas
    const r = resoudreModele({ choix: body.model, env: process.env });
    if (r.erreur) { send('failure', { code: 'modele_refuse', message: `Modèle refusé : seuls ${MODELES.join(', ')} sont admis.` }); return 'repondu'; }
    body.modeleResolu = r.modele; // écrasé à chaque question, jamais écrit sur disque ni journalisé avec la question
    if (body.project && (!body.mode || body.mode === 'ask') && !body.session) {
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
    jetonValide: (j) => typeof j === 'string' && j === ptoken,
    stop() { live?.stop(); for (const c of clients) c.end(); },
  };
}
