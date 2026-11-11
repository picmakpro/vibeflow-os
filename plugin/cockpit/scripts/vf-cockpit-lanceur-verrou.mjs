// vf-cockpit-lanceur-verrou — verrou de lanceur et reprise d'un serveur orphelin (AUDC-H3), pour vf-cockpit.mjs.
// Aucune adresse ni PID n'est cru sans contrôle : le PID doit être le serve.mjs de la sortie du lab (estNotre, fourni par le lanceur).
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import { confiner } from './vf-cockpit-paths.mjs';

// AUDC-H3 : verrou de lanceur — deux lanceurs ne se croisent pas. Fichier créé en exclusif (jamais un lien suivi), PID du détenteur ;
// un détenteur mort, ou un verrou de plus de 2 minutes, est repris. Le second lanceur attend, puis trouve le serveur déjà là.
const VERROU_MAX_MS = 120000;
export async function prendreVerrou(lab, sortie, { vivant, attendre }) {
  const f = path.join(path.dirname(sortie), 'cockpit-lanceur.lock');
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
      let pid = 0, age = 0;
      try { pid = Number(fs.readFileSync(f, 'utf8')); age = Date.now() - fs.statSync(f).mtimeMs; } catch { continue; }
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
    const jeton = page && page.code === 200 ? /VF_COCKPIT_SERVER=\{"token":"([0-9a-f]+)"/.exec(page.corps)?.[1] : null;
    if (!jeton) continue;
    const st = await lireHttp(p, '/api/status', jeton);
    let o = null; try { o = JSON.parse(st?.corps || ''); } catch {}
    if (!o || !Number.isInteger(o.pid) || typeof o.root !== 'string') continue;
    let r; try { r = fs.realpathSync(o.root); } catch { continue; }
    if (r !== racine || !estNotre(o.pid, path.join(sortie, 'serve.mjs'), lab)) continue;
    // adopté : server.json est réécrit (0600) pour que `status`, `stop` et les relances le retrouvent
    try { fs.writeFileSync(etatFile(sortie), JSON.stringify({ pid: o.pid, port: p, url: adresseLocale(p), token: jeton, hash: o.hash, startedAt: new Date().toISOString() }, null, 2), { mode: 0o600 }); } catch { return null; }
    noter(sortie, `serveur déjà à l'écoute (PID ${o.pid}, port ${p}) sans server.json : repris, aucun second serveur lancé`);
    return serveurVivant(sortie);
  }
  return null;
}

