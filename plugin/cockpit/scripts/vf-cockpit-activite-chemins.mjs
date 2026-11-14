// vf-cockpit-activite-chemins — normalisation PURE des cibles de la frise et jointure par (arbre, cible) (75-03, ACTV-08, ACTV-09, ACTV-10 ;
//   P75-D-14, P75-D-30, P75-D-31, A33, A45, A46).
// Exports : HORS_LAB, MAX_OCTETS, parcourir(chemin) (vrai si le chemin remonte au-dessus de sa racine), raisonRejet(chemin) (null si le chemin est
//   acceptable), gardeFilesModified(chemin) (booléen), normaliser({ arbre, cible }, contexte) -> { etat:
//   'carte'|'hors-carte'|'hors-lab'|'coupee'|'rejete', chemin },
//   rassembler(entrees, contexte) -> { groupes, compte, etats }.
// contexte : { cartes: Set (chemins relatifs au lab, comparés BRUTS), libelleHorsLab, worktreesVerifies: [noms], nomPrincipal }. `prefixeLab` n'est
//   jamais lu : la
//   cible arrive DÉJÀ relative au lab (A33), le préfixe n'est pas retiré une seconde fois.
// Aucune lecture de disque ni de git, aucune résolution physique (celle-ci est la fonction unique de 79-07, appelée en amont par 79-13) : ce module
//   ne juge que
//   la FORME d'un texte. Aucune RegExp construite d'une entrée, aucune clé d'objet construite d'un chemin (des Map). Un lien résolu hors du lab
//   arrive en amont
//   sous le libellé « un fichier hors du lab » : sentinelle, jamais une cible.
export const HORS_LAB = 'un fichier hors du lab'; // libellé livré par 79-13 (vf-cockpit-cible.mjs, HORS) ; un témoin le compare à la valeur livrée
export const MAX_OCTETS = 4096;
const COUPEE = '…';
const CTRL = /[\u0000-\u001f\u007f-\u009f\u2028\u2029]/; // caractères de contrôle, NUL, retours à la ligne, tabulation, U+2028 et U+2029
const ABSOLU = /^(?:[\\/]|[A-Za-z]:)/;

// une seule passe, une pile qui ne se recopie jamais : le coût est linéaire (preuve en N et 2N)
export function parcourir(chemin) {
  const pile = [];
  for (const s of chemin.split('/')) {
    if (s === '' || s === '.') continue;
    if (s === '..') { if (pile.length === 0) return true; pile.pop(); } else pile.push(s);
  }
  return false;
}

// la raison du rejet d'un chemin textuel, ou null. Rien n'est affiché ni exécuté d'un chemin rejeté.
export function raisonRejet(chemin) {
  if (typeof chemin !== 'string') return 'type';
  if (chemin === '') return 'vide';
  if (chemin.length > MAX_OCTETS || Buffer.byteLength(chemin, 'utf8') > MAX_OCTETS) return 'taille'; // garde:chemins-taille
  if (CTRL.test(chemin)) return 'controle'; // garde:chemins-controle
  if (ABSOLU.test(chemin)) return 'absolu'; // garde:chemins-absolu
  if (parcourir(chemin)) return 'remonte'; // garde:chemins-remonte
  return null;
}

// A37 : aucune validation de chemin textuel n'est exportée par 79-06 ni 79-07 (seule la résolution physique l'est) : la garde est limitée à la forme
export const gardeFilesModified = (chemin) => raisonRejet(chemin) === null;

const comptes = new WeakMap(); // contexte -> Map nom d'arbre -> nombre de worktrees VÉRIFIÉS qui le portent
function porteurs(c) {
  let m = comptes.get(c);
  if (m) return m;
  m = new Map();
  for (const x of Array.isArray(c.worktreesVerifies) ? c.worktreesVerifies : []) m.set(x, (m.get(x) || 0) + 1);
  comptes.set(c, m);
  return m;
}

// l'arbre principal (nul) est toujours admis ; un worktree l'est s'il est vérifié, s'il est seul à porter son nom ET si ce nom n'est pas celui de
// l'arbre principal (A46, fermé par défaut : un nom absent de la liste des vérifiés n'est jamais admis, même s'il égale le nom de base du principal)
function admis(arbre, c) {
  if (arbre === null || arbre === undefined) return true;
  if (typeof arbre !== 'string' || !Array.isArray(c.worktreesVerifies)) return false;
  const n = porteurs(c).get(arbre) || 0;
  return n === 1 && arbre !== c.nomPrincipal; // garde:chemins-arbre-unique
}

export function normaliser(entree, contexte = {}) {
  const cible = entree && entree.cible;
  if (raisonRejet(cible) !== null) return { etat: 'rejete', chemin: null };
  if (cible === (contexte.libelleHorsLab ?? HORS_LAB)) return { etat: 'hors-lab', chemin: null }; // garde:chemins-sentinelle
  if (!admis(entree.arbre, contexte)) return { etat: 'hors-lab', chemin: null };
  if (cible.endsWith(COUPEE)) return { etat: 'coupee', chemin: null }; // garde:chemins-coupee : jamais jointe, ni à une carte ni à une jumelle entière
  return { etat: contexte.cartes && contexte.cartes.has(cible) ? 'carte' : 'hors-carte', chemin: cible };
}

// jointure par le couple (arbre, cible) : deux arbres, deux groupes ; sentinelle, coupée et rejetée écartées et COMPTÉES. `ref` est rendu tel quel.
export function rassembler(entrees, contexte = {}) {
  const compte = { carte: 0, horsCarte: 0, horsLab: 0, coupees: 0, rejetes: 0 };
  const parArbre = new Map(), etats = [], groupes = [];
  for (const e of entrees) {
    const n = normaliser(e, contexte);
    etats.push(n);
    if (n.etat === 'rejete') { compte.rejetes++; continue; }
    if (n.etat === 'hors-lab') { compte.horsLab++; continue; }
    if (n.etat === 'coupee') { compte.coupees++; continue; }
    const cle = e.arbre ?? null; // garde:chemins-jointure
    let m = parArbre.get(cle);
    if (!m) { m = new Map(); parArbre.set(cle, m); }
    let g = m.get(n.chemin);
    if (!g) { g = { arbre: cle, chemin: n.chemin, carte: n.etat === 'carte', refs: [] }; m.set(n.chemin, g); groupes.push(g); }
    g.refs.push(e.ref);
    if (n.etat === 'carte') compte.carte++; else compte.horsCarte++;
  }
  return { groupes, compte, etats };
}
