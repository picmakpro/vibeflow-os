// vf-cockpit-git-entete — données de l'en-tête du cockpit : dépôt principal, branche, worktree (78-04 ; P78-D-01, P78-D-02, P78-D-11).
// Export : enteteGit(lab, { sh = shBorne }) -> { etat: 'ok'|'indisponible'|'absent', depot, branche, worktree, detache, sha7 }.
// Seul point de lancement de git : shBorne, ou lancerGit pour dire « délai » (échéance bornée, PATH assaini). Aucune exception : git absent, lab hors dépôt ou lecture en échec
// rendent 'absent' ou 'indisponible'. Toute chaîne qui sort passe par nettoie (contrôles retirés, secrets masqués, bornée à 200).
import fs from 'node:fs';
import path from 'node:path';
import { GIT_SUR, shBorne, lancerGit } from './vf-cockpit-paths.mjs';
import { nettoie } from './vf-cockpit-arbres.mjs';

const reel = (p) => { try { return fs.realpathSync(p); } catch { return path.resolve(p); } };

export function enteteGit(lab, { sh = shBorne } = {}) {
  // PU-G-003 (parité R3.3 avec enteteAsync) : un git MUET (délai dépassé) rend « indisponible », jamais « absent ». `shBorne` ne rend que la sortie : sur le lanceur par défaut, la lecture passe par `lancerGit`
  // (même exécuteur, même échéance, même environnement) qui dit `delai` ; un `sh` injecté (tests) garde son contrat de chaîne.
  let muet = false;
  const git = (...a) => { try {
    if (sh === shBorne) { const r = lancerGit(lab, a); if (r.delai) muet = true; return String(r.sortie ?? '').trim(); }
    return String(sh('git', [...GIT_SUR, '-C', lab, ...a], undefined, lab) ?? '').trim();
  } catch { return ''; } };
  const vide = (etat, depot) => ({ etat, depot: nettoie(depot, 200), branche: null, worktree: null, detache: false, sha7: null });
  const commun = git('rev-parse', '--path-format=absolute', '--git-common-dir');
  if (!commun) return vide(muet ? 'indisponible' : 'absent', path.basename(path.resolve(lab)));
  const racine = path.basename(commun) === '.git' ? path.dirname(commun) : commun.replace(/[\\/]+$/, '').replace(/\.git$/, '');
  const haut = git('rev-parse', '--show-toplevel');
  const worktree = haut && reel(haut) !== reel(racine) ? path.basename(haut) : null;
  const branche = git('symbolic-ref', '--quiet', '--short', 'HEAD');
  const sha7 = branche || muet ? '' : git('rev-parse', '--short=7', 'HEAD'); // git muet : pas de « HEAD détaché » déduit d'un délai
  const base = { depot: nettoie(path.basename(racine), 200), worktree: worktree && nettoie(worktree, 200) };
  if (branche && !muet) return { etat: 'ok', ...base, branche: nettoie(branche, 200), detache: false, sha7: null };
  if (sha7 && !muet) return { etat: 'ok', ...base, branche: null, detache: true, sha7: nettoie(sha7, 40) };
  return { etat: 'indisponible', ...base, branche: null, detache: false, sha7: null };
}
