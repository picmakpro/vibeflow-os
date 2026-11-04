// vf-cockpit-terminal-processus — le serveur Q du terminal intégré, dans son PROCESSUS ENFANT (Phase 71 ; P71-D-33, D-34, D-35).
// vf-cockpit-terminal.mjs (dans le processus de serve.mjs) le lance par child_process.fork : Q n'est plus sur la boucle d'événements de serve.mjs,
// dont le travail synchrone (minuterie de 5 s) gelait frappes et sortie. Canal parent/enfant = l'IPC de fork (jamais l'argv, jamais l'environnement) :
//   parent -> enfant : { t:'init', engineDir, root, here, jetons, portP, envOrigine } · { t:'jetons', jetons } · { t:'arret' }
//   enfant -> parent : { t:'pret', port } · { t:'occupe', v } · { t:'echec', code }
// Contrôles, amorçage, session unique, grâce, tampon : inchangés (voir vf-cockpit-terminal-session.mjs). Le parent meurt (même par SIGKILL) :
// l'IPC se ferme, ou le ppid change, et l'enfant arrête toute la session puis sort. Arrêt volontaire du parent (message `arret`) : état « arret »,
// les flux sont fermés, GET /etat répond { etat: 'arret' } pendant ARRET_MS (au moins 1 s) puis l'enfant sort. Aucun octet du terminal n'est journalisé.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { FICHIER_AMORCE, FICHIER_OUVRIR, DUREE_AMORCE_MS, nouveauSecret, egal, consommerAmorce } from './vf-cockpit-terminal-amorce.mjs';
import { creerSessions, resoudrePython3, TAILLE_MAX } from './vf-cockpit-terminal-session.mjs';
import { preparerPage, pageTerminal } from './vf-cockpit-terminal-page.mjs';

const log = (m) => console.error(`vf-cockpit (terminal) : ${m}`);
const json = (res, statut, objet) => { res.writeHead(statut, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' }); res.end(JSON.stringify(objet)); };
export const CORPS_ENTREE_MAX = 65536; // P71-D-10 : au-delà, 413 et rien n'est écrit au shell
const CORPS_TAILLE_MAX = 32;
export const ARRET_MS = 2500; // P71-D-35 : Q répond encore « arret » ce temps (plus d'une seconde), puis sort
const lireCorps = (req, max) => new Promise((resolve) => {
  const annonce = Number(req.headers['content-length']);
  if (Number.isFinite(annonce) && annonce > max) { req.resume(); return resolve(null); }
  const morceaux = []; let n = 0, fini = false;
  const clore = (v) => { if (!fini) { fini = true; resolve(v); } };
  req.on('data', (c) => { n += c.length; if (n > max) { morceaux.length = 0; clore(null); req.resume(); } else if (!fini) morceaux.push(c); });
  req.on('end', () => clore(Buffer.concat(morceaux)));
  req.on('error', () => clore(null));
});

function demarrerQ({ engineDir, root, here, jetons: jetons0, portP, envOrigine }) {
  let jetons = jetons0 || [], portQ = null, phase = 'actif';
  const secret = nouveauSecret();
  const fichierAmorce = path.join(here, '.cache', FICHIER_AMORCE);
  const fichierOuvrir = path.join(here, '.cache', FICHIER_OUVRIR);
  const retirerOuvrir = () => { try { fs.unlinkSync(fichierOuvrir); } catch {} };
  const balayerOuvrir = () => { try { const st = fs.lstatSync(fichierOuvrir); if (Date.now() - st.mtimeMs > DUREE_AMORCE_MS) retirerOuvrir(); } catch {} };
  preparerPage({ engineDir });
  const pythonAbsent = !resoudrePython3(envOrigine.PATH); // P71-D-34 : journalisé une fois, annoncé par /etat
  if (pythonAbsent) log('python3 introuvable : le terminal est indisponible.');
  const sessions = creerSessions({ engineDir, lab: root, jetons: () => [...jetons, secret], env: envOrigine });
  const origineQ = () => `http://127.0.0.1:${portQ}`;

  function controle(req, url) {
    if (req.method !== 'GET' && req.method !== 'POST') return { statut: 403, raison: 'méthode' };
    const page = req.method === 'GET' && url.pathname === '/';
    const hotes = [`127.0.0.1:${portQ}`, ...(page ? [`localhost:${portQ}`] : [])];
    if (!hotes.includes(String(req.headers.host || '').toLowerCase())) return { statut: 403, raison: 'Host' };
    // P71-D-24 : GET /flux et GET /etat, SEULS, admettent l'absence d'Origin si Sec-Fetch-Site vaut same-origin ET le secret en en-tête est valide.
    const navigateur = req.method === 'GET' && (url.pathname === '/flux' || url.pathname === '/etat')
      && req.headers['sec-fetch-site'] === 'same-origin' && egal(req.headers['x-vf-terminal'], secret);
    const o = req.headers.origin;
    if (o === undefined) { if (!page && !navigateur) return { statut: 403, raison: 'Origin absente' }; } else if (o !== origineQ()) return { statut: 403, raison: 'Origin' };
    return null;
  }
  const entetes = (res) => {
    res.setHeader('Referrer-Policy', 'no-referrer'); res.setHeader('X-Content-Type-Options', 'nosniff'); res.setHeader('Cache-Control', 'no-store');
    res.setHeader('Content-Security-Policy', "default-src 'none'; frame-ancestors 'none'");
  };
  let nRefus = 0;
  const refus = (res, statut, raison) => {
    if (raison && ++nRefus <= 50) log(`requête refusée : ${raison}.`);
    res.writeHead(statut, statut === 413 ? { Connection: 'close' } : {}); res.end();
  };
  const taille = (v) => { const m = /^(\d{1,4})x(\d{1,4})$/.exec(String(v || '')); return m ? { lignes: Number(m[1]), colonnes: Number(m[2]) } : null; };
  const tailleCorps = (b) => {
    const m = /^(\d{1,4}) (\d{1,4})$/.exec(b.toString('utf8')); if (!m) return null;
    const l = Number(m[1]), c = Number(m[2]);
    return l >= 1 && l <= TAILLE_MAX.lignes && c >= 1 && c <= TAILLE_MAX.colonnes ? { l, c } : null;
  };

  async function traiter(req, res) {
    entetes(res);
    let url; try { url = new URL(req.url, origineQ()); } catch { return refus(res, 400, 'adresse'); }
    const c = controle(req, url); if (c) return refus(res, c.statut, c.raison);
    const { pathname: p } = url, m = req.method;
    if (p === '/' && m === 'GET') {
      const { html, csp } = pageTerminal({ theme: url.searchParams.get('theme') === 'light' ? 'light' : 'dark', origineP: `http://127.0.0.1:${portP}` });
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Content-Security-Policy': csp }); return res.end(html);
    }
    if (p === '/amorce' && m === 'POST') {
      if (phase === 'arret' || !consommerAmorce(fichierAmorce, req.headers['x-vf-amorce'])) return refus(res, 403, 'amorçage');
      retirerOuvrir();
      return json(res, 200, { secret });
    }
    if (!egal(req.headers['x-vf-terminal'], secret)) return refus(res, 401, 'secret');
    const routes = { '/amorce': 'POST', '/flux': 'GET', '/entree': 'POST', '/taille': 'POST', '/etat': 'GET' };
    if (!(p in routes)) return refus(res, 404);
    if (routes[p] !== m) return refus(res, 405);
    const onglet = req.headers['x-vf-onglet'];
    if (p === '/etat') { // P71-D-35 : « arret » (arrêt volontaire) ; P71-D-34 : « indisponible » (python3 absent) ; sinon l'état de la session
      if (phase === 'arret') return json(res, 200, { etat: 'arret' });
      if (pythonAbsent) return json(res, 200, { etat: 'indisponible', raison: 'python3-absent' });
      return json(res, 200, sessions.etat());
    }
    if (phase === 'arret' || pythonAbsent) return refus(res, 503);
    if (p === '/flux') {
      const t = req.headers['x-vf-taille'] === undefined ? { lignes: 24, colonnes: 80 } : taille(req.headers['x-vf-taille']);
      if (!t) return refus(res, 400);
      const r = sessions.attacher(req, res, { onglet, ...t }); return r === 200 ? undefined : refus(res, r);
    }
    const corps = await lireCorps(req, p === '/entree' ? CORPS_ENTREE_MAX : CORPS_TAILLE_MAX);
    if (p === '/entree') return corps ? refus(res, sessions.ecrire(corps, onglet)) : refus(res, 413, 'corps trop grand');
    const t = corps ? tailleCorps(corps) : null;
    return refus(res, t ? sessions.redimensionner(t.l, t.c, onglet) : 400);
  }

  const q = http.createServer((req, res) => { traiter(req, res).catch(() => { try { if (!res.headersSent) refus(res, 500); else res.end(); } catch {} }); });
  let vuOccupe = false;
  const signaler = () => { const v = sessions.occupe(); if (v !== vuOccupe) { vuOccupe = v; if (process.connected) { try { process.send({ t: 'occupe', v }); } catch {} } } }; // canal fermé : jamais d'envoi (il émettrait un 'error' non rattrapé)
  // les fichiers d'amorçage ne se retirent QU'À l'entrée en « arret » (arrêt volontaire, comme l'ancien `exit`), jamais à la sortie différée ni à la mort du
  // parent : un serveur voisin ou suivant peut déjà avoir posé les siens au même chemin
  let sortie = false;
  const sortir = () => { if (sortie) return; sortie = true; sessions.arreterTout(); process.exit(0); };
  const arret = () => { // arrêt volontaire du parent : flux fermés, session arrêtée, « arret » annoncé, puis sortie
    if (phase === 'arret') return; phase = 'arret'; sessions.arreterTout(); try { fs.unlinkSync(fichierAmorce); } catch {} retirerOuvrir();
    setTimeout(sortir, ARRET_MS);
  };
  q.on('error', (e) => { log(`le serveur du terminal ne démarre pas (${e.code || 'erreur'}).`); try { process.send({ t: 'echec', code: e.code || 'erreur' }); } catch {} process.exit(1); });
  q.listen(0, '127.0.0.1', () => { portQ = q.address().port; log('terminal actif (127.0.0.1 seulement).'); process.send({ t: 'pret', port: portQ }); });
  setInterval(signaler, 250).unref();
  setInterval(balayerOuvrir, 2000).unref();
  retirerOuvrir();
  // mort du parent, même par SIGKILL : l'IPC se ferme (immédiat) ; le ppid change (filet) -> sortie sans message « arret » (coupure brutale)
  const ppid0 = process.ppid;
  process.on('disconnect', () => { if (phase !== 'arret') sortir(); });
  setInterval(() => { if (process.ppid !== ppid0 && phase !== 'arret') sortir(); }, 500).unref();
  return { jetons: (j) => { jetons = j || []; }, arret };
}

if (process.send) {
  process.on('error', () => {}); // IPC fermé par la mort du parent : rien ne doit faire tomber l'enfant pendant l'état « arret »
  let Q = null;
  process.on('message', (msg) => {
    if (!msg || typeof msg !== 'object') return;
    if (msg.t === 'init' && !Q) { try { Q = demarrerQ(msg); } catch (e) { log(`${e.message}`); try { process.send({ t: 'echec', code: 'init' }); } catch {} process.exit(1); } }
    else if (msg.t === 'jetons' && Q) Q.jetons(msg.jetons);
    else if (msg.t === 'arret' && Q) Q.arret();
  });
  for (const sig of ['SIGINT', 'SIGHUP']) process.on(sig, () => {}); // le groupe du terminal du lanceur signale aussi l'enfant : c'est le parent qui décide
  process.on('SIGTERM', () => { if (Q) Q.arret(); else process.exit(0); });
}
