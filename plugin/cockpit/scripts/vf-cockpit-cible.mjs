// vf-cockpit-cible — la règle UNIQUE de réduction d'un chemin à une cible d'affichage (79-13, SOCL-17 ; A23, A33, A45, A46, P79-D-11).
// Exports : HORS (« un fichier hors du lab »), fin(texte) (blancs écrasés, secrets masqués, borne d'affichage de 120 unités),
//  reduireCible(valeur, arbres, defaut)
//   -> null (valeur absente ou vide) | { arbre, cible } (cible relative, ou HORS avec arbre nul), racinesDeComparaison(racineDuLab, arbres) -> table
//   [{ nom, racine, base }], arbreDeNom(table, arbre) -> l'entrée admise ou null.
// Une cible est jugée, jamais ouverte : la résolution est celle du noyau (cheminPhysique de 79-07, mode plus proche parent), un échec rend HORS. Aucun
// chemin absolu ne sort d'ici. Aucune lecture de fichier hors de cette résolution, aucun processus, aucune variable d'environnement.
import path from 'node:path';
import { masque } from './vf-cockpit-lecture.mjs';
import { cheminPhysique } from './vf-cockpit-git-sortant.mjs';
import { nettoie } from './vf-cockpit-arbres.mjs';

export const HORS = 'un fichier hors du lab';
const HORS_R = Object.freeze({ arbre: null, cible: HORS }), BORNE = 120;
const OPTION = { plusProcheParent: true }; // garde:cible-parent
const dedans = (p, r) => p === r || p.startsWith(r.endsWith(path.sep) ? r : r + path.sep); // garde:cible-dedans

// borne d'affichage : blancs écrasés, masque, puis coupe ; au-delà de la borne les 119 premières unités (118 si la 119e ouvre une paire de
//  substitution),
// puis la marque ; 120 unités ou moins restent intactes
export function fin(s) {
  const t = masque(String(typeof s === 'string' ? s : '').replace(/\s+/g, ' ').trim());
  if (t.length <= BORNE) return t;
  const c = t.charCodeAt(BORNE - 2), n = c >= 0xd800 && c <= 0xdbff ? BORNE - 2 : BORNE - 1;
  return t.slice(0, n) + '…'; // garde:cible-fin
}

export function reduireCible(valeur, arbres, defaut = null) {
  if (typeof valeur !== 'string' || valeur === '') return null;
  if (valeur.includes('\0')) return HORS_R;
  let abs = valeur;
  if (!path.isAbsolute(valeur)) { // jamais de normalisation : le noyau résout
    if (!defaut || !defaut.base) return HORS_R;
    abs = defaut.base + path.sep + valeur;
  }
  const phys = cheminPhysique(abs, OPTION); // garde:cible-physique
  if (phys === null) return HORS_R; // garde:cible-echec
  let proprio = null;
  for (const e of Array.isArray(arbres) ? arbres : []) if (dedans(phys, e.racine) && (!proprio || e.racine.length > proprio.racine.length)) proprio = e;
  if (!proprio || proprio.base === null || !dedans(phys, proprio.base)) return HORS_R;
  return { arbre: proprio.nom, cible: path.relative(proprio.base, phys).split(path.sep).join('/') || '.' };
}

// la table des arbres : une entrée { nom, racine, base } par arbre de `arbres` (arbre principal puis worktrees PROUVÉS par arbresGit, jamais
//  déclarés ici).
// `nom` : nul pour l'arbre principal, sinon le dernier élément du chemin passé par `nettoie`. `base` : racine plus le chemin du lab dans le
//  dépôt (A33), nulle
// quand elle ne se résout pas ou que le nom est porté par deux arbres, le dossier de l'arbre principal compris (A46) : l'entrée reste dans la liste pour
// rester propriétaire de sa racine, elle n'est pas admise.
export function racinesDeComparaison(racineDuLab, arbres) {
  const lab = cheminPhysique(racineDuLab);
  if (lab === null) return [];
  const liste = Array.isArray(arbres) && arbres.length ? arbres : [{ chemin: lab, principal: true }];
  const premier = cheminPhysique(liste[0].chemin), sous = premier !== null && dedans(lab, premier) ? path.relative(premier, lab) : '';
  const nom = (a) => (a.principal === true ? null : nettoie(path.basename(a.chemin), 200));
  const occupants = new Map();
  for (const a of liste) if (nom(a) !== null) occupants.set(nom(a), (occupants.get(nom(a)) || 0) + 1);
  const principal = nettoie(path.basename(premier ?? lab), 200);
  occupants.set(principal, (occupants.get(principal) || 0) + 1); // garde:cible-principal
  const table = [];
  for (const a of liste) {
    const racine = cheminPhysique(a.chemin);
    if (racine === null) continue;
    const ambigu = nom(a) !== null && occupants.get(nom(a)) > 1; // garde:cible-collision
    table.push({ nom: nom(a), racine, base: ambigu ? null : cheminPhysique(sous ? racine + path.sep + sous : racine) });
  }
  return table;
}

// l'entrée ADMISE de la valeur d'`arbre` que l'index persiste (nul : l'arbre principal ; un nom : le worktree prouvé de ce nom) ; jamais un nom
//  pris pour un chemin
export function arbreDeNom(table, arbre) {
  if (!Array.isArray(table) || (arbre !== null && arbre !== undefined && typeof arbre !== 'string')) return null;
  return table.find((e) => e.base !== null && e.nom === (arbre ?? null)) || null; // garde:cible-arbre
}
