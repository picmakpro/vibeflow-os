// vf-cockpit-lanceur-verrou — verrou de lanceur et reprise d'un serveur orphelin (AUDC-H3), pour vf-cockpit.mjs.
// Aucune adresse ni PID n'est cru sans contrôle : le PID doit être le serveur de CE lab (estNotre, fourni par le lanceur ;
// identité dans vf-cockpit-serveur-vivant.mjs).
import fs from 'node:fs';
import path from 'node:path';
import { confiner } from './vf-cockpit-paths.mjs';
import { detecterServeur } from './vf-cockpit-serveur-vivant.mjs';

// AUDC-H3 : tout fichier que le lanceur écrit dans la sortie du lab (journal, état) y reste. Rien n'est modifié ni bloqué avant le contrôle : aucun composant du chemin sous le lab n'est un lien
// symbolique (lstat de chacun), le fichier existant est régulier et à un seul lien dur (lstat), l'ouverture ne suit pas de lien et ne bloque pas (O_NOFOLLOW, O_NONBLOCK), le type est revérifié sur
// le descripteur, et la troncature (mode non ajout) n'a lieu qu'ensuite. Rend le descripteur, ou null.
const BAS = (fs.constants.O_NOFOLLOW || 0) | (fs.constants.O_NONBLOCK || 0);
export function ouvrirSur(lab, f, { ajout = false, mode = 0o600 } = {}) {
  try {
    confiner(lab, f);
    let p = path.resolve(lab);
    for (const c of path.relative(p, path.resolve(f)).split(path.sep)) {
      p = path.join(p, c); let st; try { st = fs.lstatSync(p); } catch (e) { if (e.code === 'ENOENT') break; throw e; }
      if (st.isSymbolicLink() || (p === path.resolve(f) && (!st.isFile() || st.nlink !== 1))) return null;
    }
    const fd = fs.openSync(f, fs.constants.O_WRONLY | fs.constants.O_CREAT | BAS | (ajout ? fs.constants.O_APPEND : 0), mode);
    try { const st = fs.fstatSync(fd); if (st.isFile() && st.nlink === 1) { if (!ajout) fs.ftruncateSync(fd, 0); return fd; } } catch {}
    fs.closeSync(fd);
  } catch {}
  return null;
}
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
// AUDC-H3 : un serveur de CE lab déjà à l'écoute alors que server.json manque (fichier perdu) est repris, jamais doublé. La DÉTECTION (page à jeton,
// /api/status, PID reconnu par estNotre) vit dans vf-cockpit-serveur-vivant.mjs et n'écrit rien (79-06, D-M13) ; l'ADOPTION, qui écrit
// server.json, reste ici : c'est le geste de `open`.
export async function serveurOrphelin(lab, sortie, port0, { estNotre, etatFile, adresseLocale, serveurVivant, noter }) {
  const o = await detecterServeur(lab, sortie, port0, { estNotre: (pid) => estNotre(pid, path.join(sortie, 'serve.mjs'), lab) });
  if (!o) return null;
  // adopté : server.json est réécrit (0600) pour que `status`, `stop` et les relances le retrouvent
  const fd = ouvrirSur(lab, etatFile(sortie)); if (fd === null) return null; // jamais à travers un lien, jamais hors du lab
  const etat = { pid: o.pid, port: o.port, url: adresseLocale(o.port), token: o.token, hash: o.hash, startedAt: new Date().toISOString() };
  try { fs.writeSync(fd, JSON.stringify(etat, null, 2)); } catch { return null; } finally { fs.closeSync(fd); }
  noter(sortie, `serveur déjà à l'écoute (PID ${o.pid}, port ${o.port}) sans server.json : repris, aucun second serveur lancé`);
  return serveurVivant(sortie);
}
