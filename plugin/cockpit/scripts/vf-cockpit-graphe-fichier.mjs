// vf-cockpit-graphe-fichier — les deux fichiers de données du graphe dans la sortie du lab (79-15, SOCL-19 ; A29, R2, R7). Jamais évalués : du JSON,
// rien d'autre.
// Exports : FICHIER_PROJET (`projet.json`), ecrireProjet(lab, sortie, g) -> booléen (jamais d'exception ; temporaire ouvert sans suivre de lien, un
// seul lien dur, 0600,
// confinement, renommage ; un échec journalise un avertissement une fois), lireProjet(sortie) -> graphe validé ou lève une erreur à message court
// (fichier ordinaire,
// 32 Mio au plus, schéma exact), lireGrapheCode(sortie, memo) -> { g, brut, sig } ou null (graph.json de la sortie, `repos` vidé comme la page Code,
// mémoïsé par date et taille).
import fs from 'node:fs';
import path from 'node:path';
import { confiner } from './vf-cockpit-paths.mjs';
import { ouvrirSur } from './vf-cockpit-lanceur-verrou.mjs';
import { signatureGraphe } from './vf-cockpit-graphe.mjs';

export const FICHIER_PROJET = 'projet.json';
const SCHEMA_PROJET = 'vibeflow/cockpit-project@1', TAILLE_MAX = 32 * 1024 * 1024;
let averti = false;
const avertir = (msg) => { if (!averti) { averti = true; try { console.error(`vf-cockpit : ${msg}`); } catch {} } };

export function ecrireProjet(lab, sortie, g) {
  try {
    const f = path.join(sortie, FICHIER_PROJET), tmp = f + '.tmp';
    let fd = ouvrirSur(lab, tmp);
    if (fd === null) { try { fs.unlinkSync(tmp); } catch {} fd = ouvrirSur(lab, tmp); } // un temporaire hostile (lien) est retiré lui-même, jamais suivi
    if (fd === null) { avertir('projet.json non écrit : fichier temporaire refusé'); return false; }
    try { fs.writeSync(fd, JSON.stringify(g)); } finally { fs.closeSync(fd); }
    // un lien posé à la place du fichier est retiré LUI-MÊME (jamais suivi), puis remplacé par le renommage
    try { if (fs.lstatSync(f).isSymbolicLink()) fs.unlinkSync(f); } catch {}
    confiner(lab, f); // le chemin final reste sous le lab
    fs.renameSync(tmp, f);
    return true;
  } catch (e) { avertir(`projet.json non écrit : ${String(e && e.message).slice(0, 120)}`); return false; }
}

function lireFichier(f) {
  const st = fs.lstatSync(f);
  if (!st.isFile()) throw new Error('fichier ordinaire attendu');
  if (st.size > TAILLE_MAX) throw new Error('fichier trop gros');
  return { texte: fs.readFileSync(f, 'utf8'), st };
}

export function lireProjet(sortie) {
  let g;
  try { g = JSON.parse(lireFichier(path.join(sortie, FICHIER_PROJET)).texte); }
  catch (e) {
    const cause = e && e.code === 'ENOENT' ? 'absent' : String(e && e.message).slice(0, 60);
    throw new Error(`projet.json illisible (${cause}) : relancer « vf-cockpit build »`);
  }
  const ok = g && typeof g === 'object' && g.schema === SCHEMA_PROJET && Array.isArray(g.nodes) && Array.isArray(g.files)
    && g.meta && typeof g.meta === 'object' && !Array.isArray(g.meta);
  if (!ok) throw new Error('projet.json invalide (schéma ou forme inattendus) : relancer « vf-cockpit build »');
  return g;
}

export function lireGrapheCode(sortie, memo = {}) {
  try {
    const f = path.join(sortie, 'graph.json'), st = fs.lstatSync(f);
    if (!st.isFile() || st.size > TAILLE_MAX) return null;
    const cle = `${st.mtimeMs}:${st.size}`;
    if (memo.cle === cle && memo.val) return memo.val;
    const g0 = JSON.parse(fs.readFileSync(f, 'utf8'));
    if (!g0 || typeof g0 !== 'object' || Array.isArray(g0)) return null;
    const g = { ...g0, meta: { ...g0.meta, repos: [] } }; // la page Code embarque ce graphe : le remote d'un dépôt (jeton possible) n'y est pas
    const val = { g, brut: JSON.stringify(g), sig: signatureGraphe(g) };
    memo.cle = cle; memo.val = val;
    return val;
  } catch { return null; }
}
