// vf-cockpit-lanceur-verrou — verrou de lanceur et reprise d'un serveur orphelin (AUDC-H3), pour vf-cockpit.mjs.
// Aucune adresse ni PID n'est cru sans contrôle : le PID doit être le serve.mjs de la sortie du lab (estNotre, fourni par le lanceur).
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import { confiner } from './vf-cockpit-paths.mjs';

// AUDC-H3 : tout fichier que le lanceur écrit dans la sortie du lab (journal, état) y reste. Contrôle de sortie (confiner : ni lien symbolique, ni dossier parent hors du lab),
// ouverture sans suivre de lien (O_NOFOLLOW) et type vérifié sur le descripteur ouvert : fichier régulier, un seul lien dur. Rend le descripteur, ou null.
const SANS_LIEN = fs.constants.O_NOFOLLOW || 0;
export function ouvrirSur(lab, f, { ajout = false, mode = 0o600 } = {}) {
  try {
    confiner(lab, f);
    const fd = fs.openSync(f, fs.constants.O_WRONLY | fs.constants.O_CREAT | SANS_LIEN | (ajout ? fs.constants.O_APPEND : fs.constants.O_TRUNC), mode);
    try { const st = fs.fstatSync(fd); if (st.isFile() && st.nlink === 1) return fd; } catch {}
    fs.closeSync(fd);
  } catch {}
  return null;
}
// Une valeur de server.json (fichier que le lab peut fournir) n'entre jamais dans une ligne ni dans un fichier sans forme valide.
export const hashSur = (h) => (h === undefined || h === null ? undefined : typeof h === 'string' && /^[0-9a-f]{1,64}$/.test(h) ? h : 'illisible'); // illisible = code inconnu : le serveur est remplacé
export const pidSur = (v) => (Number.isInteger(v) && v > 0 ? v : null);
// Journal du serveur (serveur.log), décisions du lanceur datées avec leur motif (jamais un jeton ni un contenu). Une ligne = une ligne : aucun retour à la ligne n'y passe.
export function noter(sortie, msg) {
  const fd = ouvrirSur(path.resolve(sortie, '..', '..'), path.join(sortie, '.cache', 'serveur.log'), { ajout: true });
  if (fd === null) return;
  try { fs.writeSync(fd, `${new Date().toISOString()} lanceur : ${String(msg).replace(/[\r\n\u2028\u2029]+/g, ' ')}\n`); } catch {} finally { fs.closeSync(fd); }
}

// AUDC-H3 : verrou de lanceur — deux lanceurs ne se croisent pas. Fichier créé en exclusif (jamais un lien suivi), PID du détenteur ;
// un détenteur mort, ou un verrou de plus de 2 minutes, est repris. Le second lanceur attend, puis trouve le serveur déjà là.
const VERROU_MAX_MS = 120000;
export async function prendreVerrou(lab, sortie, { vivant, attendre }) {
  const f = path.join(sortie, '.cache', 'lanceur.lock'); // sous le dossier ignoré de la sortie
  fs.mkdirSync(path.dirname(f), { recursive: true }); confiner(lab, f);
  const fin = Date.now() + VERROU_MAX_MS;
  for (;;) {
    try {
      const fd = fs.openSync(f, 'wx', 0o600);
      try { fs.writeSync(fd, String(process.pid)); } finally { fs.closeSync(fd); }
      let rendu = false;
      return () => { if (rendu) return; rendu = true; try { if (fs.readFileSync(f, 'utf8') === String(process.pid)) fs.unlinkSync(f); } catch {} };
    } catch (e) {
      if (e.code !== 'EEXIST') throw e;
      let pid = 0, age = 0, vide = false;
      try { const t = fs.readFileSync(f, 'utf8'); vide = t === ''; pid = Number(t); age = Date.now() - fs.statSync(f).mtimeMs; } catch { continue; }
      if (vide && age < 2000) { await attendre(50); continue; } // créé à l'instant, PID pas encore écrit : jamais pris pour un verrou périmé
      if (!Number.isInteger(pid) || pid <= 1 || !vivant(pid) || age > VERROU_MAX_MS) { try { fs.unlinkSync(f); } catch {} continue; }
      if (Date.now() > fin) { console.error('un autre lanceur tient le verrou depuis plus de 2 minutes : relancer plus tard.'); process.exit(5); }
      await attendre(100);
    }
  }
}
// AUDC-H3 : un serveur de CE lab déjà à l'écoute alors que server.json manque (fichier perdu) est repris, jamais doublé. Le serveur se reconnaît à sa page (jeton) et à /api/status
// (racine du lab, PID) ; le PID doit être le serve.mjs de cette sortie (estNotre). Seuls les ports du lab (préféré et repli de 20) sont sondés, sur 127.0.0.1.
const lireHttp = (port, chemin, jeton) => new Promise((resolve) => {
  const r = http.get({ host: '127.0.0.1', port, path: chemin, timeout: 1500, headers: { Host: `127.0.0.1:${port}`, ...(jeton ? { 'x-vf-cockpit-token': jeton } : {}) } }, (res) => {
    let b = ''; res.on('data', (c) => { if (b.length < 3 << 20) b += c; }); res.on('end', () => resolve({ code: res.statusCode, corps: b }));
  });
  r.on('error', () => resolve(null)); r.on('timeout', () => { r.destroy(); resolve(null); });
});
export async function serveurOrphelin(lab, sortie, port0, { estNotre, etatFile, adresseLocale, serveurVivant, noter }) {
  let racine; try { racine = fs.realpathSync(lab); } catch { return null; }
  for (let p = port0; p <= Math.min(65535, port0 + 20); p++) {
    const page = await lireHttp(p, '/');
    const jeton = page && page.code === 200 ? /VF_COCKPIT_SERVER=\{"token":"([0-9a-f]{1,128})"/.exec(page.corps)?.[1] : null;
    if (!jeton) continue;
    const st = await lireHttp(p, '/api/status', jeton);
    let o = null; try { o = JSON.parse(st?.corps || ''); } catch {}
    if (!o || !Number.isInteger(o.pid) || typeof o.root !== 'string') continue;
    let r; try { r = fs.realpathSync(o.root); } catch { continue; }
    if (r !== racine || !estNotre(o.pid, path.join(sortie, 'serve.mjs'), lab)) continue;
    // adopté : server.json est réécrit (0600) pour que `status`, `stop` et les relances le retrouvent
    const fd = ouvrirSur(lab, etatFile(sortie)); if (fd === null) return null; // jamais à travers un lien, jamais hors du lab
    try { fs.writeSync(fd, JSON.stringify({ pid: o.pid, port: p, url: adresseLocale(p), token: jeton, hash: hashSur(o.hash), startedAt: new Date().toISOString() }, null, 2)); } catch { return null; } finally { fs.closeSync(fd); }
    noter(sortie, `serveur déjà à l'écoute (PID ${o.pid}, port ${p}) sans server.json : repris, aucun second serveur lancé`);
    return serveurVivant(sortie);
  }
  return null;
}

