// vf-cockpit-routes — mécanisme des routes GET /api/vf/* du serveur unique (79-05, SOCL-06 ; A10, A11, C0).
// Rôle : un répartiteur à table validée, un vérificateur d'accès intérieur et les régimes de route. La table elle-même (ROUTES) vit dans
// vf-cockpit-server.mjs : ajouter une route = importer un lecteur et ajouter UNE ligne `[chemin, lecteur, régime?]` à sa place alphabétique.
// Exports : HISTORIQUE, FLUX (régimes), reponse(code, corps, entetes), estReponse(o), controlerAcces(req, { entete, jetonValide, port }),
//   creerRepartiteur({ table, contexte, repondre, json, acces, log }) -> { servir(req, res, url) }.
// Régimes : sans marqueur = gardé (accès contrôlé, garde d'émission, no-store, 503) ; HISTORIQUE = réponse JSON simple, comportement antérieur
//   conservé (le portail de serve.mjs a déjà contrôlé l'accès) ; FLUX = le lecteur écrit lui-même (flux SSE).
// Aucun fichier lu, aucun processus, aucun écouteur.
import { ENTETE_JETON } from './vf-cockpit-lancer-post.mjs';

export const HISTORIQUE = 'historique';
export const FLUX = 'flux';

const MARQUE = Symbol('vf-cockpit-reponse');
export const reponse = (code, corps, entetes) => Object.freeze({ [MARQUE]: true, code, corps, entetes: { ...(entetes || {}) } });
export const estReponse = (o) => !!o && typeof o === 'object' && o[MARQUE] === true;

// C0 « Accès » : hôte, origine, jeton, méthode, dans cet ordre ; fermé par défaut (paramètre manquant ou invalide : 403)
export function controlerAcces(req, { entete = ENTETE_JETON, jetonValide, port } = {}) {
  const h = (req && req.headers) || {};
  const p = port === undefined ? req && req.socket && req.socket.localPort : port;
  const hote = typeof h.host === 'string' ? h.host.toLowerCase() : '';
  if (typeof jetonValide !== 'function' || !Number.isInteger(p)) return { ok: false, code: 403 };
  if (hote !== `127.0.0.1:${p}` && hote !== `localhost:${p}`) return { ok: false, code: 403 }; // garde:acces-hote
  if (h.origin && h.origin !== `http://${h.host}`) return { ok: false, code: 403 }; // garde:acces-origine
  if (!jetonValide(h[entete])) return { ok: false, code: 403 }; // garde:acces-jeton
  if (!req || req.method !== 'GET') return { ok: false, code: 405 }; // garde:acces-methode
  return { ok: true };
}

// la table est validée à la création : une table invalide fait échouer le démarrage, jamais une requête
function indexer(table) {
  if (!Array.isArray(table)) throw new Error('table des routes : un tableau est attendu');
  const index = new Map();
  for (const ligne of table) {
    const [chemin, lecteur, regime] = Array.isArray(ligne) ? ligne : [];
    if (typeof chemin !== 'string' || !chemin.startsWith('/api/vf/')) throw new Error(`table des routes : chemin invalide (${String(chemin).slice(0, 60)})`);
    if (index.has(chemin)) throw new Error(`table des routes : chemin en double (${chemin})`);
    if (typeof lecteur !== 'function') throw new Error(`table des routes : lecteur absent (${chemin})`);
    if (regime !== undefined && regime !== HISTORIQUE && regime !== FLUX) throw new Error(`table des routes : régime inconnu (${chemin})`);
    index.set(chemin, [lecteur, regime]);
  }
  return index;
}

export function creerRepartiteur({ table, contexte, repondre, json, acces, log = () => {} }) {
  const index = indexer(table);
  const gardees = [...index.values()].some(([, r]) => r === undefined);
  const outils = typeof acces === 'function' && typeof repondre === 'function';
  if (gardees && !outils) throw new Error('table des routes : contrôle d\'accès et réponse gardée obligatoires');
  const echec = (res) => { log('error', 'lecteur de route en échec'); try { if (!res.headersSent) res.writeHead(500); res.end(); } catch {} };
  const gardee = (lecteur, req, res, url) => {
    const a = acces(req);
    if (!a || a.ok !== true) { res.writeHead(Number(a && a.code) || 403); res.end(); return; }
    let r;
    try { r = lecteur(contexte, req, url); } catch { echec(res); return; }
    Promise.resolve(r).then((v) => {
      if (estReponse(v)) repondre(req, res, v.corps, { code: v.code, entetes: v.entetes }); else repondre(req, res, v, {});
    }).catch(() => echec(res));
  };
  return {
    servir(req, res, url) {
      const e = index.get(url.pathname);
      if (!e) return false;
      const [lecteur, regime] = e;
      if (regime === FLUX) lecteur(contexte, req, url, res);
      else if (regime === HISTORIQUE) { const v = lecteur(contexte, req, url); if (estReponse(v)) json(res, v.code, v.corps); else json(res, 200, v); }
      else gardee(lecteur, req, res, url);
      return true;
    },
  };
}
