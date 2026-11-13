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

export const HORS = 'un fichier hors du lab';
const HORS_R = Object.freeze({ arbre: null, cible: HORS }), BORNE = 120;
const OPTION = { plusProcheParent: true }; // garde:cible-parent
const dedans = (p, r) => p === r || p.startsWith(r.endsWith(path.sep) ? r : r + path.sep); // garde:cible-dedans

// borne d'affichage : masque puis coupe ; au-delà de la borne les 119 premières unités (118 si la 119e ouvre une paire de substitution), puis la marque
export function fin(s) {
  const t = masque(String(typeof s === 'string' ? s : '').replace(/\s+/g, ' ').trim());
  return t.slice(0, BORNE); // garde:cible-fin
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

// table des arbres : version réduite, seul l'arbre principal est admis
export function racinesDeComparaison(racineDuLab) {
  const racine = cheminPhysique(racineDuLab);
  return racine === null ? [] : [{ nom: null, racine, base: racine }];
}
export const arbreDeNom = (table, arbre) => ((arbre === null || arbre === undefined) && Array.isArray(table)
  ? table.find((e) => e.nom === null && e.base !== null) || null : null);
