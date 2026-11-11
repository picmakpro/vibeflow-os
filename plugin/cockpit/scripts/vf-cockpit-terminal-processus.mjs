// vf-cockpit-terminal-processus — le serveur Q du terminal intégré, dans son PROCESSUS ENFANT (Phase 71 ; P71-D-33, D-34, D-35).
// vf-cockpit-terminal.mjs (dans le processus de serve.mjs) le lance par child_process.fork : Q n'est plus sur la boucle d'événements de serve.mjs,
// dont le travail synchrone (minuterie de 5 s) gelait frappes et sortie. Canal parent/enfant = l'IPC de fork (jamais l'argv, jamais l'environnement) :
//   parent -> enfant : { t:'init', engineDir, root, here, jetons, portP, envOrigine } · { t:'jetons', jetons } · { t:'arret' }
//     · { t:'terminer' } (fin de la session du shell, AUDC-M10) · { t:'cibles', cibles } (liste fermée recalculée par P) · { t:'proposition', cible, verbe, chat?, bloquants, avertissements } (72-10 ; P72-D-10, D-12)
//   enfant -> parent : { t:'pret', port } · { t:'occupe', v } · { t:'echec', code } · { t:'lancee', cible, verbe, session, at } (la ligne a été écrite au shell)
// Lancement (72-10) : GET /proposition, POST /lancer { id, mode, chat? } et POST /annuler { id } sous les contrôles des routes voisines. La ligne ne vient JAMAIS du client (P72-D-13) :
// elle est composée par l'état de Q (vf-cockpit-lancer-q.mjs) ; elle est écrite au shell sans retour chariot, une fois, seulement armée et le shell au repos ; aucune ligne ni UUID n'est journalisé.
// Mode retenu (72-16 ; P72-D-20) : Q écrit le mode d'un lancement ACCEPTÉ dans le dossier d'état du poste, par projet (vf-cockpit-lancer-mode.mjs ; AUDC-B-05) et le sert dans GET /proposition (mode_retenu) ; jamais transmis par l'IPC.
// Contrôles, amorçage, session unique, grâce, tampon : inchangés (voir vf-cockpit-terminal-session.mjs). Le parent meurt (même par SIGKILL) :
// l'IPC se ferme, ou le ppid change, et l'enfant arrête toute la session puis sort. Arrêt volontaire du parent (message `arret`) : état « arret »,
// les flux sont fermés, GET /etat répond { etat: 'arret' } pendant ARRET_MS (au moins 1 s) puis l'enfant sort. Aucun octet du terminal n'est journalisé.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { FICHIER_AMORCE, FICHIER_OUVRIR, DUREE_AMORCE_MS, nouveauSecret, egal, consommerAmorce } from './vf-cockpit-terminal-amorce.mjs';
import { creerSessions, resoudrePython3, TAILLE_MAX } from './vf-cockpit-terminal-session.mjs';
import { preparerPage, pageTerminal } from './vf-cockpit-terminal-page.mjs';
import { creerEtatLancer } from './vf-cockpit-lancer-q.mjs';
import * as gabarit from './vf-cockpit-lancer-gabarit.mjs';
import { creerMemoireModePoste } from './vf-cockpit-lancer-mode.mjs';

const log = (m) => console.error(`vf-cockpit (terminal) : ${m}`);
const json = (res, statut, objet) => { res.writeHead(statut, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' }); res.end(JSON.stringify(objet)); };
export const CORPS_ENTREE_MAX = 65536; // P71-D-10 : au-delà, 413 et rien n'est écrit au shell
const CORPS_TAILLE_MAX = 32;
export const ARRET_MS = 2500; // P71-D-35 : Q répond encore « arret » ce temps (plus d'une seconde), puis sort
const CORPS_LANCER_MAX = 512;
// motif de refus de l'état de Q (72-05) -> statut ; refus de l'écriture (72-02) -> statut. Tables fermées lues par Object.hasOwn : un motif inconnu est 400, jamais 204.
const STATUT_MOTIF = { inconnue: 404, consommee: 404, annulee: 404, remplacee: 404, expiree: 404, absente: 404, 'pas-arme': 425, occupee: 409, bloquee: 409, mode: 400, chat: 400 };
const STATUT_LANCER = { 'premier-plan': 409, absente: 410, alphabet: 400, invalide: 400, delai: 504, ecriture: 410 }; // ecriture : le PTY a refusé l'écriture, la session n'est plus utilisable
const statutDe = (table, motif) => (Object.hasOwn(table, motif) ? table[motif] : 400);
// corps -> objet JSON non tableau aux seules clés `cles`, dont chaque clé de `requises` est une chaîne et dont `chat`, s'il est présent, est un booléen strict ; sinon null
function lireDemande(brut, cles, requises) {
  let o; try { o = JSON.parse(brut.toString('utf8')); } catch { return null; }
  if (!o || typeof o !== 'object' || Array.isArray(o) || !Object.keys(o).every((k) => cles.includes(k))) return null;
  return requises.every((k) => typeof o[k] === 'string') && (o.chat === undefined || typeof o.chat === 'boolean') ? o : null;
}
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
  // P71-D-34 puis P71-D-36 (R3) : python3 se vérifie à CHAQUE lancement de shell (premier démarrage, « Relancer le shell », nouvelle session), jamais une fois pour toutes :
  // il peut disparaître en cours de session. Journalisé une fois par absence (remise à zéro quand il revient), annoncé par /etat. Une session déjà vivante n'en dépend pas.
  let refusPython = false, pythonDit = false;
  const pythonAbsent = () => { const a = !resoudrePython3(envOrigine.PATH); if (!a) { refusPython = false; pythonDit = false; } return a; };
  const direAbsent = () => { if (!pythonDit) { pythonDit = true; log('python3 introuvable : le terminal est indisponible.'); } };
  if (pythonAbsent()) direAbsent();
  const sessions = creerSessions({ engineDir, lab: root, jetons: () => [...jetons, secret], env: envOrigine });
  const origineQ = () => `http://127.0.0.1:${portQ}`;
  let proprietaire = null;
  const gabaritQ = gabarit;
  const lq = creerEtatLancer({ gabarit: gabaritQ });
  const memoireMode = creerMemoireModePoste({ racine: root }); // garde:mode-support : le dossier d'état du poste, par projet (AUDC-B-05), jamais le dossier du lab
  const recevoirCibles = (l) => lq.definirCibles(l);
  const recevoirProposition = (m) => lq.proposer(m);
  const lireProposition = () => { const p = lq.lire(); return p.etat === 'en-attente' ? { ...p, mode_retenu: memoireMode.lire() } : p; }; // garde:mode-servi
  // seule fonction qui atteint sessions.lancer : réserve (consommer), écrit, puis acte (confirmer, message `lancee`) ou restitue (rendre) ; rend un statut HTTP
  async function lancer(demande, onglet) {
    const vivante = sessions.etat().session; if (vivante !== 'vivante' && vivante !== 'detachee') return 410;
    if (onglet !== proprietaire) return 409;
    const idDemande = demande.id;
    const r = lq.consommer(idDemande, demande.mode, demande.chat);
    if (!r.ok) return statutDe(STATUT_MOTIF, r.motif);
    const ligneQ = r.ligne;
    const w = await sessions.lancer(ligneQ, onglet);
    if (!w.ok) { lq.rendre(idDemande); return statutDe(STATUT_LANCER, w.motif); }
    memoireMode.ecrire(demande.mode); // garde:mode-ecrit
    const msg = lq.confirmer(idDemande);
    if (msg && process.connected) { try { process.send(msg); } catch {} } // canal fermé : jamais d'envoi
    return 204;
  }

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
    // GET /proposition passe par EXACTEMENT les contrôles de GET /etat (Host, Origin ou Sec-Fetch-Site same-origin + secret) : un seul code, aucune ligne de contrôle dupliquée ni reformulée
    const c = controle(req, url.pathname === '/proposition' ? new URL('/etat', origineQ()) : url); if (c) return refus(res, c.statut, c.raison);
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
    const routes = { '/amorce': 'POST', '/flux': 'GET', '/entree': 'POST', '/taille': 'POST', '/etat': 'GET', '/proposition': 'GET', '/lancer': 'POST', '/annuler': 'POST' };
    if (!(p in routes)) return refus(res, 404);
    if (routes[p] !== m) return refus(res, 405);
    const onglet = req.headers['x-vf-onglet'];
    if (p === '/etat') { // P71-D-35 : « arret » (arrêt volontaire) ; P71-D-34 : « indisponible » (python3 absent) ; sinon l'état de la session
      if (phase === 'arret') return json(res, 200, { etat: 'arret' });
      if (!sessions.occupe() && pythonAbsent() && (refusPython || sessions.etat().session === 'absente')) { direAbsent(); return json(res, 200, { etat: 'indisponible', raison: 'python3-absent' }); }
      return json(res, 200, sessions.etat());
    }
    if (phase === 'arret') return refus(res, 503);
    if (p === '/flux') {
      if (!sessions.occupe() && pythonAbsent()) { refusPython = true; direAbsent(); return refus(res, 503); } // un shell à lancer sans python3 : jamais de boucle « session fermée »
      const t = req.headers['x-vf-taille'] === undefined ? { lignes: 24, colonnes: 80 } : taille(req.headers['x-vf-taille']);
      if (!t) return refus(res, 400);
      const r = sessions.attacher(req, res, { onglet, ...t });
      if (r === 200) proprietaire = onglet;
      return r === 200 ? undefined : refus(res, r);
    }
    if (p === '/proposition') return json(res, 200, lireProposition());
    if (p === '/lancer' || p === '/annuler') {
      const brut = await lireCorps(req, CORPS_LANCER_MAX);
      if (!brut) return refus(res, 413, 'corps trop grand');
      const lancement = p === '/lancer';
      const demande = lireDemande(brut, lancement ? ['id', 'mode', 'chat'] : ['id'], lancement ? ['id', 'mode'] : ['id']);
      if (!demande) return refus(res, 400);
      if (lancement) return refus(res, await lancer(demande, onglet));
      if (onglet !== proprietaire) return refus(res, 409);
      return refus(res, lq.annuler(demande.id).ok ? 204 : 404);
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
  // AUDC-M10 : fin volontaire de la SESSION (le shell), jamais du serveur : flux fermé, EOF et signal à l'assistant, la place reste prise jusqu'à la mort de l'ancien shell (une attache entre-temps : 503), puis une attache neuve lance un autre shell. Sans session : sans effet.
  const terminer = () => { if (phase !== 'arret') sessions.fermer(); };
  return { jetons: (j) => { jetons = j || []; }, cibles: recevoirCibles, proposition: recevoirProposition, arret, terminer };
}

if (process.send) {
  process.on('error', () => {}); // IPC fermé par la mort du parent : rien ne doit faire tomber l'enfant pendant l'état « arret »
  let Q = null;
  process.on('message', (msg) => {
    if (!msg || typeof msg !== 'object') return;
    if (msg.t === 'init' && !Q) { try { Q = demarrerQ(msg); } catch (e) { log(`${e.message}`); try { process.send({ t: 'echec', code: 'init' }); } catch {} process.exit(1); } }
    else if (msg.t === 'jetons' && Q) Q.jetons(msg.jetons);
    else if (msg.t === 'cibles' && Q) Q.cibles(msg.cibles);
    else if (msg.t === 'proposition' && Q) Q.proposition(msg);
    else if (msg.t === 'terminer' && Q) Q.terminer();
    else if (msg.t === 'arret' && Q) Q.arret();
  });
  for (const sig of ['SIGINT', 'SIGHUP']) process.on(sig, () => {}); // le groupe du terminal du lanceur signale aussi l'enfant : c'est le parent qui décide
  process.on('SIGTERM', () => { if (Q) Q.arret(); else process.exit(0); });
}
