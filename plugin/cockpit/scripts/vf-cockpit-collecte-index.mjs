// vf-cockpit-collecte-index — l'étape d'INDEX de la collecte, dans le fil (79-09, P79-D-12, P79-D-29, P79-D-33, SOCL-12). Synchrone, aucun réseau.
// Export : etapeIndex({ racine, sortie, home, memo, maintenant, sansIndex }) -> rapport { etat, tronque, voies, formeInconnue, evinces } EN COMPTES : les voies
//          restent dans `memo.index` (le fil), jamais dans un résultat posté. `etat` : `ok`, `tronque` (une voie a perdu une ligne trop longue ou des voies
//          ont été évincées), `suspendu` (sansIndex : le pilote a relancé le fil sans index), `erreur`.
// Aucun fichier de transcript n'est lu ici : l'énumération, la lecture incrémentale et la réduction sont celles de 79-08 (vf-cockpit-index.mjs).
//   - le fichier d'index (<sortie>/.cache/index-transcripts.json) est chargé UNE fois (chargement non fiable de 79-08) et réécrit seulement quand
//     une voie a changé ;
//   - `vivantes` : les sessions non terminées de l'état officiel déjà lu dans le fil (P79-D-29) ; carte absente ou en échec : ensemble vide ; seule
//     cette liste retient une voie au-delà de 24 h (jamais un appel d'outil ouvert) ;
//   - `arbreDe` (P79-D-33, A45, A46) : `{ arbre: null }` pour l'arbre principal, `{ arbre: <nom> }` pour un worktree dont l'appartenance au dépôt est
//     PROUVÉE par la vérification du tiroir Git (`worktreeVerifie`, celle de `verifie: true`), `null` (voie non créée) pour tout autre dossier et pour
//     un nom porté par deux arbres. Jamais un chemin, jamais un libellé déclaré.
import path from 'node:path';
import { enumerer, mettreAJour, bilan } from './vf-cockpit-index.mjs';
import { FICHIER_INDEX, chargerIndex, ecrireIndex, indexVide } from './vf-cockpit-index-cache.mjs';
import { CONTRAT } from './vf-cockpit-index-voie.mjs';
import { lire as lireOfficiel } from './vf-cockpit-etat-officiel.mjs';
import { GIT_SUR, shBorne } from './vf-cockpit-paths.mjs';
import { cheminPhysique } from './vf-cockpit-git-sortant.mjs';
import { worktreeVerifie } from './vf-cockpit-git-details.mjs';
import { nettoie } from './vf-cockpit-arbres.mjs';

const git = (racine, ...a) => shBorne('git', [...GIT_SUR, '-C', racine, ...a], racine, racine);

// les arbres PROUVÉS du dépôt : [{ chemin (physique), nom, principal }] ; le premier bloc de `git worktree list` est l'arbre principal
function arbresProuves(racine) {
  const commun = cheminPhysique(git(racine, 'rev-parse', '--path-format=absolute', '--git-common-dir').trim());
  if (!commun) return [];
  const arbres = [];
  for (const bloc of git(racine, 'worktree', 'list', '--porcelain').split('\n\n')) {
    const brut = /^worktree (.*)$/m.exec(bloc)?.[1], chemin = brut ? cheminPhysique(brut) : null, principal = arbres.length === 0;
    if (!chemin) continue;
    if (!principal && !worktreeVerifie(commun, chemin)) continue; // garde:index-arbre
    arbres.push({ chemin, nom: nettoie(path.basename(chemin), 200), principal });
  }
  return arbres;
}

export function creerArbreDe(racine) {
  const arbres = arbresProuves(racine), compte = new Map();
  for (const a of arbres) compte.set(a.nom, (compte.get(a.nom) || 0) + 1);
  const ambigu = (n) => compte.get(n) > 1; // garde:index-collision
  return (cwd) => {
    const c = typeof cwd === 'string' && path.isAbsolute(cwd) ? cheminPhysique(cwd) : null;
    if (!c) return null;
    let meilleur = null; // l'arbre le plus spécifique qui contient le dossier
    for (const a of arbres) if ((c === a.chemin || c.startsWith(a.chemin + path.sep)) && (!meilleur || a.chemin.length > meilleur.chemin.length)) meilleur = a;
    if (!meilleur) return null;
    if (meilleur.principal) return { arbre: null };
    return ambigu(meilleur.nom) ? null : { arbre: meilleur.nom };
  };
}

const rapportDe = (etat, b = {}) => ({
  etat, tronque: etat === 'tronque', voies: b.voies ?? 0, formeInconnue: b.formeInconnue ?? 0, evinces: b.evinces ?? 0,
});

export function etapeIndex({ racine, sortie, home, memo, maintenant = Date.now(), sansIndex = false }) {
  if (sansIndex) return rapportDe('suspendu');
  try {
    const fichier = path.join(sortie, '.cache', FICHIER_INDEX);
    let ecrire = false;
    if (!memo.index) {
      const c = chargerIndex(fichier, racine, { maintenant });
      memo.index = c.etat === 'lu' ? c.index : indexVide(CONTRAT.claudeCode?.verifieSur);
      memo.memoHors = new Map(); ecrire = c.etat !== 'lu';
    }
    const vivantes = new Set(), carte = lireOfficiel(home);
    if (carte) for (const [id, v] of carte) if (v.etat !== 'termine') vivantes.add(id);
    const cands = enumerer(path.join(home, '.claude', 'projects'));
    const r = mettreAJour(memo.index, cands, { maintenant, arbreDe: creerArbreDe(racine), vivantes, memoHors: memo.memoHors });
    memo.index = r.index;
    if (r.change || ecrire) ecrireIndex(fichier, racine, memo.index);
    const b = bilan(memo.index);
    return rapportDe(b.tronque ? 'tronque' : 'ok', b);
  } catch { return rapportDe('erreur'); }
}
