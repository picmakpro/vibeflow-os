// vf-cockpit-cibles — les cibles d'une voie : table fermée des outils comptés, pli d'une ligne de transcript, bornes, listes triées (79-13,
//  SOCL-17 ; A22, A24).
// Exports : OUTILS_CIBLES (table fermée), CHAMPS_LUS (chemins de transcript lus, déclarés au contrat `claudeCode.cibles`), LIMITES_CIBLES, cibleVide(),
//   plierLigneCibles(etat, ligne, arbres, defaut, maintenant, cache) -> [entrées touchées, quelque chose est sorti ou a été écarté],
//   listesDeCibles(etat).
// Seul `Read` compte en lecture ; `Write`, `Edit`, `MultiEdit`, `NotebookEdit` en écriture ; tout autre outil (Grep, Glob, Bash…) ne produit aucune cible.
// Règle d'ajout : un outil compté de plus s'inscrit dans la table, au contrat et par amendement daté de A24. Une entrée est { arbre, cible, n,
//  dernierMs } ;
// la structure interne est une table de correspondance (jamais un objet dont la clé est une cible). Aucune écriture de fichier ici.
import { reduireCible, fin } from './vf-cockpit-cible.mjs';

const T = (sens, champ) => Object.freeze({ sens, champ });
export const OUTILS_CIBLES = Object.freeze(Object.assign(Object.create(null), {
  Read: T('lectures', 'file_path'), Write: T('ecritures', 'file_path'), Edit: T('ecritures', 'file_path'), // garde:cibles-outils
  MultiEdit: T('ecritures', 'file_path'), NotebookEdit: T('ecritures', 'notebook_path'),
}));
export const CHAMPS_LUS = Object.freeze(['type', 'timestamp', 'message.content', 'name', 'input.file_path', 'input.notebook_path']);
export const LIMITES_CIBLES = Object.freeze({ parSens: 200, total: 20000, fenetreMs: 86400000, valeurMax: 4096 });

export const cibleVide = () => ({ ecritures: new Map(), lectures: new Map(), tronque: false });
const cmp = (a, b) => (a < b ? -1 : a > b ? 1 : 0);

// la plus ancienne par `dernierMs` (à égalité, la clé la plus petite) sort : le résultat ne dépend pas de l'ordre d'insertion des égaux
function evincer(m) {
  let pire = null;
  for (const [k, e] of m) if (pire === null || e.dernierMs < pire[1].dernierMs || (e.dernierMs === pire[1].dernierMs && k < pire[0])) pire = [k, e];
  m.delete(pire[0]);
}

export function plierLigneCibles(etat, d, arbres, defaut, maintenant, cache = {}) {
  const L = cache.limites || LIMITES_CIBLES;
  if (!d || typeof d !== 'object' || d.type !== 'assistant') return [0, false];
  const c = d.message && d.message.content;
  if (!Array.isArray(c)) return [0, false];
  const t = typeof d.timestamp === 'string' ? Date.parse(d.timestamp) : NaN;
  if (!Number.isFinite(t) || t < maintenant - L.fenetreMs || t > maintenant + 86400000) return [0, false];
  let vus = 0, perdu = false;
  for (const b of c) {
    if (!b || typeof b !== 'object' || b.type !== 'tool_use' || typeof b.name !== 'string' || !Object.hasOwn(OUTILS_CIBLES, b.name)) continue;
    const o = OUTILS_CIBLES[b.name], v = b.input && typeof b.input === 'object' ? b.input[o.champ] : undefined;
    if (typeof v !== 'string' || v.length > L.valeurMax || v.includes('\0')) continue; // un chemin ne porte jamais d'octet nul
    const cle = `${defaut ? defaut.nom ?? '' : '\u0001'}\0${v}`;
    let r = cache.reduits ? cache.reduits.get(cle) : undefined;
    if (r === undefined) { r = reduireCible(v, arbres, defaut); if (cache.reduits && cache.reduits.size < 20000) cache.reduits.set(cle, r); }
    if (r === null) continue;
    const cible = fin(r.cible), m = etat[o.sens], k = `${r.arbre ?? ''}\0${cible}`, e = m.get(k);
    vus++;
    if (e) { e.n++; if (t > e.dernierMs) e.dernierMs = t; continue; }
    if (cache.somme && cache.somme.n >= L.total) { perdu = true; continue; }
    m.set(k, { arbre: r.arbre, cible, n: 1, dernierMs: t }); if (cache.somme) cache.somme.n++;
    if (m.size > L.parSens) { evincer(m); perdu = true; if (cache.somme) cache.somme.n--; }
  }
  return [vus, perdu];
}

const liste = (m) => [...m.values()].map((e) => ({ arbre: e.arbre, cible: e.cible, n: e.n, dernierMs: e.dernierMs }))
  .sort((a, b) => b.dernierMs - a.dernierMs || cmp(a.arbre ?? '', b.arbre ?? '') || cmp(a.cible, b.cible));
export const listesDeCibles = (etat) => ({ ecritures: liste(etat.ecritures), lectures: liste(etat.lectures) });
