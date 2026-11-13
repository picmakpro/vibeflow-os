// vf-cockpit-activite-log — parseur du journal git de la lentille « activité » (Phase 75, plan 75-01 ; P75-D-07, P75-D-09, P75-D-11). PUR sur chaînes
//   : aucun appel git, aucune exception levée sur une entrée inattendue.
// Exports : STATUT, lireLog(sortie), fusionner(nouveaux, anciens, plafond), purger(commits, depuis), resoudre(commits) -> [{h, at, chemins}]
// Disposition mesurée de `log --no-merges -M -l400 --name-status -z --format=%x00%H%x00%ct` : `\0<H>\0<ct>\0` puis, pour chaque entrée,
//   `<St>\0<chemin>\0` (deux chemins pour R et C), la
// première entrée précédée d'un `\n` ; le commit suivant commence par `\0`. Un commit vide (aucune entrée) enchaîne deux NUL. Seul NUL sépare : un
//   chemin peut contenir retour ligne, U+2028, tabulation.
// Tout écart d'alignement rend { ok: false, raison } (P78-D-22) : jamais un résultat partiel présenté comme complet. Les chemins sont BRUTS (nettoie
//   n'intervient qu'à l'affichage, côté page).
import { MOTIF_SHA } from './vf-cockpit-git-graphe.mjs';

export const STATUT = /^([AMDTUXB]|[RC]\d{1,3})$/;
const ENTIER = /^[0-9]+$/;
const ko = (raison) => ({ ok: false, raison });

export function lireLog(sortie) {
  if (typeof sortie !== 'string') return ko('sortie absente');
  const j = sortie.split('\0');
  if (j.pop() !== '') return ko('sortie non terminée par NUL');
  const commits = [];
  let i = 0;
  while (i < j.length) {
    if (j[i] !== '') return ko('entête attendu');
    if (i + 2 >= j.length) return ko('entête coupé');
    const h = j[i + 1], at = j[i + 2];
    if (!MOTIF_SHA.test(h)) return ko('sha mal formé');
    if (!ENTIER.test(at)) return ko('date mal formée');
    const entrees = [];
    i += 3;
    while (i < j.length && j[i] !== '') {
      const st = entrees.length === 0 ? j[i].replace(/^\n/, '') : j[i];
      if (!STATUT.test(st)) return ko('statut inconnu');
      const n = /^[RC]/.test(st) ? 2 : 1;
      if (i + n >= j.length) return ko('chemin coupé');
      const chemins = j.slice(i + 1, i + 1 + n);
      if (chemins.some((c) => c === '')) return ko('chemin vide');
      entrees.push({ st: st[0], chemins });
      i += 1 + n;
    }
    commits.push({ h, at: Number(at), entrees });
  }
  return { ok: true, commits };
}

// incrémental : `nouveaux` (ancien..HEAD) devant `anciens`, une seule occurrence par sha, ordre par date décroissante (tri stable : à date égale, les
//   nouveaux d'abord), plafond respecté
export function fusionner(nouveaux, anciens, plafond) {
  const vus = new Set(), tous = [];
  for (const c of [...nouveaux, ...anciens]) if (!vus.has(c.h)) { vus.add(c.h); tous.push(c); }
  tous.sort((a, b) => b.at - a.at);
  return tous.slice(0, plafond);
}

// ce qui sort de la fenêtre (même règle que `--since` : un commit exactement à la borne reste)
export const purger = (commits, depuis) => commits.filter((c) => c.at >= depuis);

// Chemins ACTUELS touchés par chaque commit, une fois chacun. Parcours du plus récent au plus ancien : à `R<nn> ancien nouveau`, `alias[ancien] =
//   alias[nouveau] ?? nouveau`, les commits plus
// anciens qui citent `ancien` comptent pour le chemin actuel. L'alias n'agit que sous le renommage : un chemin recréé après lui reste distinct. Copie
//   (C) : seul le chemin neuf est touché.
export function resoudre(commits) {
  const alias = new Map(), rendu = [];
  for (const c of commits) {
    const chemins = new Set();
    for (const { st, chemins: p } of c.entrees) {
      const nom = p[p.length - 1], actuel = alias.get(nom) ?? nom;
      chemins.add(actuel);
      if (st === 'R') alias.set(p[0], actuel);
    }
    rendu.push({ h: c.h, at: c.at, chemins: [...chemins] });
  }
  return rendu;
}
