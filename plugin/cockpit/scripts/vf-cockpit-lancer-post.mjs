// vf-cockpit-lancer-post — mécanisme POST de la page P (Phase 72, LANC-03 ; P72-D-09, P72-D-10, P72-D-11).
// Rôle : accepter, sur une TABLE explicite de chemins exacts, une requête dont l'hôte, l'origine, le jeton de page, le type de contenu, la taille et le
// schéma du corps sont exactement ceux attendus, puis remettre au gestionnaire de la route une copie des SEULS champs déclarés. « La page propose,
// le terminal dispose » : proposer doit être difficile à forger hors de la page. Depuis la page, deux pouvoirs seulement : PROPOSER une commande (la confirmation et l'écriture au shell restent dans Q) et demander la FIN du shell (AUDC-M10, route « terminer »), tous deux par le même canal fermé vers Q (P72-D-10).
// Interface : creerPost({ routes, jetons, journal }) -> { reconnait(url) (synchrone), traiter(req, res, url) (async, ne rejette jamais) }.
//   routes  = { '<chemin exact>': { champs: { <nom>: { type: 'string', max, requis } }, gestionnaire: async (valide) => ({ statut, corps }) } }
//   jetons  = () => liste des jetons de page acceptés (le module n'en connaît aucun autre) ; journal = (code) => … (ne reçoit QUE des codes de REFUS)
// Ordre des contrôles, premier échec = refus à code fermé : hôte, méthode, origine, jeton, type, chaîne de requête, corps (taille, UTF-8, objet JSON), schéma.
// Le gestionnaire ne voit jamais le texte brut du corps. Rien du corps, du jeton ni d'un en-tête reçu n'est écrit dans une réponse, un journal ni sur la console (aucun appel).
// Aucun en-tête de partage entre origines : une requête de contrôle préalable reçoit 405. Aucun écouteur, aucune lecture de fichier, aucun accès à l'environnement.
import { egal } from './vf-cockpit-terminal-amorce.mjs';

export const ENTETE_JETON = 'x-vf-cockpit-token'; // renommé à l'assemblage par renommerTexte (comme vf-cockpit-server.mjs) ; l'ancien nom est alors refusé
export const CORPS_MAX = 512;
export const REFUS = Object.freeze({ hote: 403, methode: 405, origine: 403, jeton: 403, type: 415, taille: 413, corps: 400, schema: 400, interne: 500 });

const hoteDe = (req) => (typeof req.headers.host === 'string' ? req.headers.host.toLowerCase() : '');
const simple = (o) => o !== null && typeof o === 'object' && !Array.isArray(o);

export function controleHote(req) {
  const port = req.socket && req.socket.localPort;
  if (!Number.isInteger(port)) return 'hote';
  const h = hoteDe(req);
  return h === `127.0.0.1:${port}` || h === `localhost:${port}` ? null : 'hote';
}
export function controleMethode(req) { return req.method === 'POST' ? null : 'methode'; }
export function controleOrigine(req) {
  const o = req.headers.origin; // dupliquée : Node la joint par « , » et elle ne peut plus être égale
  return typeof o === 'string' && o === `http://${hoteDe(req)}` ? null : 'origine';
}
export function controleJeton(req, jetons) {
  const entete = req.headers[ENTETE_JETON];
  if (typeof entete !== 'string' || entete.length === 0) return 'jeton';
  try {
    for (const j of jetons()) {
      if (egal(entete, j)) return null;
    }
  } catch { return 'jeton'; }
  return 'jeton';
}
export function controleType(req) {
  const t = req.headers['content-type'];
  return typeof t === 'string' && t.split(';')[0].trim().toLowerCase() === 'application/json' ? null : 'type';
}
export async function lireCorps(req, max) {
  const annonce = req.headers['content-length'];
  if (annonce !== undefined && !(Number(annonce) <= max)) { req.resume(); return { ok: false, code: 'taille' }; }
  const morceaux = []; let n = 0;
  const flux = await new Promise((resolve) => {
    let fini = false; const clore = (v) => { if (!fini) { fini = true; resolve(v); } };
    req.on('data', (c) => { n += c.length; if (n > max) { morceaux.length = 0; clore(null); req.resume(); } else if (!fini) morceaux.push(c); });
    req.on('end', () => clore(Buffer.concat(morceaux)));
    req.on('error', () => clore(false));
    req.on('close', () => clore(false));
  });
  if (flux === null) return { ok: false, code: 'taille' };
  if (flux === false) return { ok: false, code: 'corps' };
  try { return { ok: true, brut: new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(flux) }; } catch { return { ok: false, code: 'corps' }; }
}
export function controleSchema(objet, champs) {
  if (!simple(objet)) return 'schema';
  for (const k of Object.keys(objet)) if (!Object.hasOwn(champs, k)) return 'schema';
  for (const [nom, d] of Object.entries(champs)) {
    if (!Object.hasOwn(objet, nom)) { if (d.requis) return 'schema'; continue; }
    const v = objet[nom];
    if (typeof v !== d.type || (typeof v === 'string' && v.length > d.max)) return 'schema';
  }
  return null;
}

export function creerPost({ routes, jetons, journal: journalExterne = () => {} }) {
  // un journal qui échoue ne change pas le refus ; il reçoit tout ce qu'on lui donne (le contrôle de ce qu'on lui donne est celui de la suite)
  const journal = (...a) => { try { journalExterne(...a); } catch { /* sans effet sur la réponse */ } };
  const envoyer = (res, statut, objet, entetes = {}) => {
    res.writeHead(statut, { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff', ...entetes });
    res.end(JSON.stringify(objet));
    return true;
  };
  const refuser = (res, code, entetes) => {
    journal(code);
    return envoyer(res, REFUS[code], { refus: code }, entetes);
  };
  const reconnait = (url) => Object.hasOwn(routes, url.pathname);
  async function executer(req, res, url, route) {
    let c = controleHote(req);
    if (c === null) c = controleMethode(req);
    if (c === 'methode') return refuser(res, c, { Allow: 'POST' });
    if (c === null) c = controleOrigine(req);
    if (c === null) c = controleJeton(req, jetons);
    if (c === null) c = controleType(req);
    if (c === null && url.search !== '') c = 'schema';
    if (c !== null) return refuser(res, c);
    const lu = await lireCorps(req, CORPS_MAX);
    if (!lu.ok) return refuser(res, lu.code, lu.code === 'taille' ? { Connection: 'close' } : undefined);
    const brut = lu.brut;
    let objet;
    try { objet = JSON.parse(brut); } catch { return refuser(res, 'corps'); }
    if (!simple(objet)) return refuser(res, 'corps');
    const s = controleSchema(objet, route.champs);
    if (s !== null) return refuser(res, s);
    const valide = Object.create(null);
    for (const nom of Object.keys(route.champs)) if (Object.hasOwn(objet, nom)) valide[nom] = objet[nom];
    let r;
    try { r = await route.gestionnaire(valide); } catch { return refuser(res, 'interne'); }
    if (!simple(r) || !Number.isInteger(r.statut) || r.statut < 100 || r.statut > 599 || !simple(r.corps)) return refuser(res, 'interne');
    return envoyer(res, r.statut, r.corps);
  }
  async function traiter(req, res, url) {
    const route = Object.hasOwn(routes, url.pathname) ? routes[url.pathname] : null;
    if (route === null) return false;
    try { return await executer(req, res, url, route); } catch { return res.headersSent ? true : refuser(res, 'interne'); }
  }
  return { reconnait, traiter };
}
