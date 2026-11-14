// vf-cockpit-trace-memoire-git — passages git de la mémoire des agents (76-03 ; TRAC-07, TRAC-08 ; P76-D-09, D-19, D-22). LECTURE SEULE.
// Exports : BORNES_MEMOIRE, fichiersSuivis(root, { fin, max }) -> { chemins, tronque }, nonSuivis(root, { fin }) -> { n },
//   cheminsHead(root, sha, { fin }) -> Set, cheminsSupprimes(root, sha, { fin, max }) -> { chemins: Set, tronque },
//   joursMemoire(root, sha, { fin, max }) -> Map(chemin -> 'AAAA-MM-JJ').
// Seul point de lancement de git : lancerGitAsync (environnement durci, GIT_* retirés, filtres vidés). Sha de 40 caractères, `--end-of-options`, `--`.
// Seuls les fichiers SUIVIS par git sous la racine de mémoire, à la profondeur agent/fichier, sont listés ; les non suivis ne sont que comptés (leurs noms
// ne sortent jamais d'ici). Borne atteinte, délai ou sortie tronquée -> `tronque: true`, jamais une liste donnée pour complète.
// `fin` est reçue de l'appelant (date butoir posée une fois par calcul) : ce module n'en fixe aucune.
import { lancerGitAsync } from './vf-cockpit-paths.mjs';

export const BORNES_MEMOIRE = { fichiers: 2000, commits: 2000, echeanceMs: 10000, tampon: 8 << 20 };
const RACINE = '.claude/agent-memory/';
const PROFONDEUR = /^\.claude\/agent-memory\/[^/]+\/[^/]+\.md$/;
const SHA40 = /^[0-9a-f]{40}$/;
const ARBRE_VIDE = '4b825dc642cb6eb9a060e54bf8d69288fbee4904'; // arbre vide de git (SHA-1) : diff-tree contre lui = tous les chemins d'un arbre
const noms = (s) => String(s ?? '').split('\0').filter(Boolean);

// un passage git ; jamais d'exception : { sortie, mauvais } où `mauvais` = tronqué, hors délai, en échec ou refusé
async function passage(root, args, fin) {
  let r;
  try { r = await lancerGitAsync(root, args, { fin, maxBuffer: BORNES_MEMOIRE.tampon }); } catch { return { sortie: '', mauvais: true }; }
  return { sortie: String(r.sortie ?? ''), mauvais: Boolean(r.tronque || r.delai || !r.ok || r.refuse) };
}

export async function fichiersSuivis(root, { fin, max = BORNES_MEMOIRE.fichiers } = {}) {
  const r = await passage(root, ['ls-files', '-z', '--end-of-options', '--', RACINE], fin);
  const chemins = [], index = [];
  let n = 0, tronque = r.mauvais;
  for (const c of noms(r.sortie).filter((p) => PROFONDEUR.test(p)).sort()) {
    if (c.endsWith('/MEMORY.md')) { index.push(c); continue; } // un index ne compte pas dans la borne
    if (n >= max) { tronque = true; continue; }
    n++; chemins.push(c);
  }
  return { chemins: [...index, ...chemins], tronque };
}

export async function nonSuivis(root, { fin } = {}) {
  let n = 0;
  for (const extra of [[], ['-i']]) { // non suivis non ignorés, puis non suivis ignorés (`-o -i`) : deux comptes sommés
    const r = await passage(root, ['ls-files', '-z', '-o', ...extra, '--exclude-standard', '--end-of-options', '--', RACINE], fin);
    n += noms(r.sortie).filter((p) => p.startsWith(RACINE)).length; // les noms sont comptés puis jetés
  }
  return { n };
}

export async function cheminsHead(root, sha, { fin } = {}) {
  if (!SHA40.test(String(sha))) return new Set();
  const r = await passage(root, ['diff-tree', '-r', '-z', '--name-only', '--end-of-options', ARBRE_VIDE, sha], fin);
  return r.mauvais ? new Set() : new Set(noms(r.sortie)); // ensemble vide = HEAD illisible : l'appelant ne juge alors aucun chemin
}

// chemins supprimés dans l'historique, SANS détection de renommage : un fichier déplacé compte comme supprimé à son ancien chemin
export async function cheminsSupprimes(root, sha, { fin, max = BORNES_MEMOIRE.commits } = {}) {
  if (!SHA40.test(String(sha))) return { chemins: new Set(), tronque: false };
  const args = ['log', '--no-renames', '--diff-filter=D', '--name-only', '-z', '--format=%x01', `--max-count=${max}`, '--end-of-options', sha, '--'];
  const r = await passage(root, args, fin);
  const recs = r.sortie.split('\x01').slice(1); // un enregistrement par commit : la borne atteinte se constate au nombre de commits lus
  return { chemins: new Set(recs.flatMap((x) => noms(x).map((c) => c.replace(/^\n+/, '')).filter(Boolean))), tronque: r.mauvais || recs.length >= max };
}

// jour (AAAA-MM-JJ) du dernier commit de chaque chemin de la racine de mémoire : première apparition dans le journal, du plus récent au plus ancien
export async function joursMemoire(root, sha, { fin, max = BORNES_MEMOIRE.commits } = {}) {
  const jours = new Map();
  if (!SHA40.test(String(sha))) return jours;
  const args = ['log', '--format=%x01%ad', '--date=short', '--name-only', '-z', `--max-count=${max}`, '--end-of-options', sha, '--', RACINE];
  const r = await passage(root, args, fin);
  for (const rec of r.sortie.split('\x01').slice(1)) {
    const [jour, ...chemins] = rec.split('\0');
    for (const c of chemins.map((x) => x.replace(/^\n/, '')).filter(Boolean)) if (!jours.has(c)) jours.set(c, jour.trim());
  }
  return jours;
}
