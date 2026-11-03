// vf-cockpit-terminal — serveur Q du terminal intégré du cockpit (71-01 ; P71-D-02, D-09, D-10, D-11, D-17).
// serve.mjs (patch vibeflow P25) l'importe seulement sous `--terminal` : AUCUN effet de bord à l'import.
// Export : preparerTerminal({ here, root, jetons, plateforme }) -> { actif, indisponible, injection(), frameSrc(), occupe(), routeP(req, res), demarrer(portP) }.
// Q est un second écouteur HTTP du MÊME processus, sur 127.0.0.1 seulement, d'un port éphémère : une origine distincte de la page hôte P.
// Chaque requête passe par controle() avant tout routage : Host exact, Origin exacte de Q, secret de session en temps constant. Aucun
// WebSocket, aucun `upgrade`, aucun cookie, aucun en-tête CORS, aucun secret dans une adresse. L'assistant PTY se lit dans l'arbre du moteur
// (VF_COCKPIT_ENGINE_DIR, posé par le lanceur), jamais dans la sortie du lab. Les messages nomment des états, jamais des données.
// Routes de Q : GET / · POST /amorce · GET /flux · POST /entree · POST /taille · GET /etat. Côté P : GET /api/vf/terminal -> { etat, port? }.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { realUnder } from './vf-cockpit-paths.mjs';
import { FICHIER_AMORCE, nouveauSecret, egal, consommerAmorce } from './vf-cockpit-terminal-amorce.mjs';
import { creerSessions, TAILLE_MAX } from './vf-cockpit-terminal-session.mjs';
import { preparerPage, pageTerminal } from './vf-cockpit-terminal-page.mjs';
import { injectionTiroir } from './vf-cockpit-terminal-tiroir.mjs';

const log = (m) => console.error(`vf-cockpit (terminal) : ${m}`);
const json = (res, statut, objet) => { res.writeHead(statut, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' }); res.end(JSON.stringify(objet)); };
export const CORPS_ENTREE_MAX = 65536; // P71-D-10 : au-delà, 413 et rien n'est écrit au shell
export { TAILLE_MAX }; // définie avec la session, qui la fait respecter aussi à l'attache du flux
const CORPS_TAILLE_MAX = 32;
// lit le corps par morceaux jusqu'à `max` octets ; null au-delà (le reste est écarté sans être gardé). Content-Length annoncé trop grand : null sans rien lire.
const lireCorps = (req, max) => new Promise((resolve) => {
  const annonce = Number(req.headers['content-length']);
  if (Number.isFinite(annonce) && annonce > max) { req.resume(); return resolve(null); }
  const morceaux = []; let n = 0, fini = false;
  const clore = (v) => { if (!fini) { fini = true; resolve(v); } };
  req.on('data', (c) => { n += c.length; if (n > max) { morceaux.length = 0; clore(null); req.resume(); } else if (!fini) morceaux.push(c); });
  req.on('end', () => clore(Buffer.concat(morceaux)));
  req.on('error', () => clore(null));
});

export function preparerTerminal({ here, root, jetons = () => [], plateforme = process.platform } = {}) {
  let etat = 'arrete'; // 'actif' | 'arrete' | 'indisponible'
  let portQ = null, portP = null, sessions = null;
  const secret = nouveauSecret();
  const fichierAmorce = path.join(here || '.', '.cache', FICHIER_AMORCE);
  const inerte = (indisponible) => ({
    actif: false, indisponible, injection: () => injectionTiroir({ indisponible }), frameSrc: () => '', occupe: () => false,
    routeP: (req, res) => { json(res, 200, { etat: indisponible ? 'indisponible' : 'arrete' }); return true; }, demarrer: () => {},
  });

  if (plateforme === 'win32') { log('Terminal indisponible sous Windows.'); return inerte(true); }
  const moteur = process.env.VF_COCKPIT_ENGINE_DIR;
  const assistant = moteur && path.isAbsolute(moteur) ? path.join(moteur, 'terminal', 'vf-cockpit-pty.py') : null;
  const ordinaire = (f) => { try { return fs.lstatSync(f).isFile() && !realUnder(f, path.join(root, '.vibeflow')); } catch { return false; } };
  if (!assistant || !ordinaire(assistant)) { log('assistant du terminal introuvable dans le moteur du cockpit : réinstaller le module cockpit.'); return inerte(false); }
  try { preparerPage({ engineDir: moteur }); } catch (e) { log(`${e.message}`); return inerte(false); }
  sessions = creerSessions({ engineDir: moteur, lab: root, jetons: () => [...jetons(), secret] });

  const origineQ = () => `http://127.0.0.1:${portQ}`;
  // un seul point d'entrée, appelé avant tout routage et toute lecture de corps : null si la requête est admise, sinon { statut, raison }
  function controle(req, url) {
    if (req.method !== 'GET' && req.method !== 'POST') return { statut: 403, raison: 'méthode' }; // aucun préflight (OPTIONS), aucune autre méthode
    const page = req.method === 'GET' && url.pathname === '/';
    const hotes = [`127.0.0.1:${portQ}`, ...(page ? [`localhost:${portQ}`] : [])]; // localhost : la page seule, jamais une route d'action
    if (!hotes.includes(String(req.headers.host || '').toLowerCase())) return { statut: 403, raison: 'Host' };
    const o = req.headers.origin;
    if (o === undefined) { if (!page) return { statut: 403, raison: 'Origin absente' }; } else if (o !== origineQ()) return { statut: 403, raison: 'Origin' };
    return null;
  }
  // toute réponse, refus compris : jamais d'en-tête CORS, de cookie ni de X-Frame-Options ; la page de Q remplace la CSP de base par la sienne
  const entetes = (res) => {
    res.setHeader('Referrer-Policy', 'no-referrer'); res.setHeader('X-Content-Type-Options', 'nosniff'); res.setHeader('Cache-Control', 'no-store');
    res.setHeader('Content-Security-Policy', "default-src 'none'; frame-ancestors 'none'");
  };
  let nRefus = 0;
  const refus = (res, statut, raison) => { // le journal nomme la raison, jamais une valeur reçue ; plafonné
    if (raison && ++nRefus <= 50) log(`requête refusée : ${raison}.`);
    res.writeHead(statut, statut === 413 ? { Connection: 'close' } : {}); res.end();
  };
  const taille = (v) => { const m = /^(\d{1,4})x(\d{1,4})$/.exec(String(v || '')); return m ? { lignes: Number(m[1]), colonnes: Number(m[2]) } : null; };
  const tailleCorps = (b) => { // « <lignes> <colonnes> » : deux entiers décimaux dans les bornes
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
    if (p === '/amorce' && m === 'POST') { // l'amorçage n'est jamais lu qu'à l'échange ; il se consomme une seule fois
      if (!consommerAmorce(fichierAmorce, req.headers['x-vf-amorce'])) return refus(res, 403, 'amorçage');
      return json(res, 200, { secret });
    }
    // le secret précède le routage : une route inconnue ne se devine pas sans lui
    if (!egal(req.headers['x-vf-terminal'], secret)) return refus(res, 401, 'secret');
    const routes = { '/amorce': 'POST', '/flux': 'GET', '/entree': 'POST', '/taille': 'POST', '/etat': 'GET' };
    if (!(p in routes)) return refus(res, 404);
    if (routes[p] !== m) return refus(res, 405);
    const onglet = req.headers['x-vf-onglet'];
    if (p === '/etat') return json(res, 200, sessions.etat());
    if (p === '/flux') {
      const t = req.headers['x-vf-taille'] === undefined ? { lignes: 24, colonnes: 80 } : taille(req.headers['x-vf-taille']);
      if (!t) return refus(res, 400);
      const r = sessions.attacher(req, res, { onglet, ...t }); return r === 200 ? undefined : refus(res, r);
    }
    const corps = await lireCorps(req, p === '/entree' ? CORPS_ENTREE_MAX : CORPS_TAILLE_MAX);
    if (p === '/entree') return corps ? refus(res, sessions.ecrire(corps, onglet)) : refus(res, 413, 'corps trop grand');
    const t = corps ? tailleCorps(corps) : null; // /taille
    return refus(res, t ? sessions.redimensionner(t.l, t.c, onglet) : 400);
  }

  const q = http.createServer((req, res) => { traiter(req, res).catch(() => { try { if (!res.headersSent) refus(res, 500); else res.end(); } catch {} }); });
  return {
    get actif() { return etat === 'actif'; }, indisponible: false,
    injection: () => injectionTiroir({ indisponible: false }),
    frameSrc: () => (portQ ? `; frame-src http://127.0.0.1:${portQ}` : ''),
    occupe: () => sessions.occupe(),
    routeP(req, res) { json(res, 200, etat === 'actif' ? { etat: 'actif', port: portQ } : { etat: 'arrete' }); return true; },
    demarrer(port) {
      portP = port;
      q.on('error', (e) => { log(`le serveur du terminal ne démarre pas (${e.code || 'erreur'}).`); etat = 'arrete'; });
      q.listen(0, '127.0.0.1', () => {
        portQ = q.address().port; etat = 'actif';
        try { // server.json gagne la clé terminal { url } : jamais un secret
          const f = path.join(here, '.cache', 'server.json'); const j = JSON.parse(fs.readFileSync(f, 'utf8'));
          fs.writeFileSync(f, JSON.stringify({ ...j, terminal: { url: origineQ() } }, null, 2), { mode: 0o600 }); fs.chmodSync(f, 0o600);
        } catch { log('server.json illisible : l\'adresse du terminal n\'a pas pu être publiée.'); }
        log('terminal actif (127.0.0.1 seulement).');
      });
      process.on('exit', () => { sessions.arreterTout(); try { fs.unlinkSync(fichierAmorce); } catch {} });
    },
  };
}
