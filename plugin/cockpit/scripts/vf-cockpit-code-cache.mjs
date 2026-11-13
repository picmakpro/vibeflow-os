// vf-cockpit-code-cache — la signature du lab qui décide si l'assemblage relance le scan du moteur (79-09, AB1, P79-D-21). Lecture seule sur le lab.
// Exports : signatureDuLab({ lab, moteur, etatGit }) -> chaîne hexadécimale | null (plus de MAX_ENTREES entrées : pas de cache),
//           lireSignature(sortie) -> chaîne | null, ecrireSignature(lab, sortie, signature) (temporaire puis renommage, 0600, confiné au lab).
// La signature couvre : le chemin, la taille et la date de CHAQUE entrée du lab hors `.git`, `.vibeflow` et `node_modules` (à toute profondeur,
// aucun lien suivi), l'index git, HEAD et sa référence, l'état de l'environnement git du moteur (`etatGit`, posé par l'assembleur), la taille et
// la date du scan et de ses bibliothèques, la version majeure de node. Par fichiers et non par dossiers seuls : la date d'un dossier ne bouge
// pas à l'édition d'un fichier.
// Lectures de `.git` (gitfile, HEAD, références) : 512 octets au plus, sans suivre de lien ni attendre un tube nommé, fichier régulier exigé (texte vide sinon).
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { confiner } from './vf-cockpit-paths.mjs';

export const MAX_ENTREES = 200000;
const IGNORES = new Set(['.git', '.vibeflow', 'node_modules']);
const FICHIER = 'scan-signature.json';
const stat = (f) => { try { const s = fs.lstatSync(f); return `${s.size}:${s.mtimeMs}`; } catch { return 'absent'; } };
// lecture bornée à 512 octets : ni lien suivi, ni tube nommé attendu (O_NOFOLLOW, O_NONBLOCK), type revérifié sur le descripteur ouvert ; tout autre cas rend ''
const BAS = (fs.constants.O_NOFOLLOW || 0) | (fs.constants.O_NONBLOCK || 0);
function texte(f) {
  let fd = -1;
  try { fd = fs.openSync(f, fs.constants.O_RDONLY | BAS); if (!fs.fstatSync(fd).isFile()) return ''; const b = Buffer.alloc(512), n = fs.readSync(fd, b, 0, 512, 0); return b.toString('utf8', 0, n).trim(); } catch { return ''; } finally { if (fd >= 0) try { fs.closeSync(fd); } catch {} } // garde:code-cache-lecture
}

// le dossier git du lab (`.git` dossier ou fichier `gitdir:`), en remontant : un lab peut être un sous-dossier du dépôt
function dossierGit(lab) {
  for (let d = lab; ; d = path.dirname(d)) {
    const g = path.join(d, '.git');
    try {
      const s = fs.statSync(g); if (s.isDirectory()) return g;
      const m = /^gitdir:\s*(.+)$/m.exec(texte(g)); if (m) return path.resolve(d, m[1].trim());
    } catch {}
    if (path.dirname(d) === d) return null;
  }
}

export function signatureDuLab({ lab, moteur, etatGit = '' }) {
  const h = crypto.createHash('sha256'), mise = (s) => h.update(s + '\n');
  let n = 0, trop = false;
  const marche = (dir, rel) => {
    let ents; try { ents = fs.readdirSync(dir, { withFileTypes: true }); } catch { return; }
    for (const e of ents.sort((a, b) => (a.name < b.name ? -1 : a.name > b.name ? 1 : 0))) {
      if (trop) return;
      if (IGNORES.has(e.name)) continue;
      if (++n > MAX_ENTREES) { trop = true; return; }
      const p = path.join(dir, e.name), r = rel ? `${rel}/${e.name}` : e.name;
      if (e.isDirectory()) marche(p, r);
      if (!e.isDirectory()) mise(`${r}\0${stat(p)}`); // garde:scan-cache-fichiers
    }
  };
  marche(lab, '');
  if (trop) return null;
  const g = dossierGit(lab);
  if (g) {
    const head = texte(path.join(g, 'HEAD')), ref = /^ref:\s*(\S+)/.exec(head)?.[1], commun = texte(path.join(g, 'commondir'));
    const base = commun ? path.resolve(g, commun) : g, cible = ref ? texte(path.join(base, ref)) : '';
    mise(`git\0${stat(path.join(g, 'index'))}\0${head}\0${cible}\0${stat(path.join(base, 'packed-refs'))}`);
  }
  mise(`env\0${etatGit}\0node${process.versions.node.split('.')[0]}`);
  const sc = path.join(moteur, 'scripts');
  mise(`moteur\0${stat(path.join(sc, 'scan.mjs'))}`);
  let libs = []; try { libs = fs.readdirSync(path.join(sc, 'lib')).filter((f) => f.endsWith('.mjs')).sort(); } catch {}
  for (const f of libs) mise(`lib\0${f}\0${stat(path.join(sc, 'lib', f))}`);
  return h.digest('hex');
}

export function lireSignature(sortie) {
  try {
    const j = JSON.parse(fs.readFileSync(path.join(sortie, '.cache', FICHIER), 'utf8'));
    return typeof j?.signature === 'string' ? j.signature : null;
  } catch { return null; }
}

export function ecrireSignature(lab, sortie, signature) {
  const dir = path.join(sortie, '.cache'), f = path.join(dir, FICHIER), tmp = `${f}.${process.pid}.tmp`;
  try {
    fs.mkdirSync(dir, { recursive: true }); confiner(lab, f);
    fs.writeFileSync(tmp, JSON.stringify({ signature }), { mode: 0o600 }); fs.renameSync(tmp, f);
  } catch { try { fs.rmSync(tmp, { force: true }); } catch {} }
}
