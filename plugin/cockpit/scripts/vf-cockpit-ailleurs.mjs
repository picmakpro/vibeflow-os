#!/usr/bin/env node
// vf-cockpit-ailleurs — l'avancement d'une phase mené dans un AUTRE arbre git du même dépôt (worktree), repris dans la lecture de l'arbre courant (N5, recette 68).
// Exports : ETAT_ORDRE, lireAilleurs(root, { arbres }) -> [{ chemin, nom, branche, pl }], fusionner(phases, ailleurs) -> Map des phases, avancement éventuellement remplacé.
// Règle de priorité (une seule, documentée dans le README du module) : l'état le plus avancé gagne (à faire < en cours < à recetter) ; un état clos sur l'arbre courant
// reste clos ; une clôture lue seulement dans un worktree vaut « à recetter » (rien n'est clos avant d'être fusionné) ; à égalité l'arbre courant garde la main.
// Lecture seule : des fichiers, jamais une exécution de fichier pris dans un worktree (P68-D-34) ; chaque lecture est confinée à la racine réelle de son arbre,
// donc un lien symbolique qui en sort n'est pas suivi ; git ne passe que par arbresGit (GIT_SUR, environnement assaini de vf-cockpit-env.mjs).
import path from 'node:path';
import { planningLayout } from './vf-cockpit-paths.mjs';
import { readPlanning, lireConfine } from './vf-cockpit-planning.mjs';
import { arbresGit, nettoie } from './vf-cockpit-arbres.mjs';

export const ETAT_ORDRE = ['a-faire', 'en-cours', 'a-recetter'];
const meme = (a, b) => path.resolve(a) === path.resolve(b);

// planning de chaque arbre autre que `root`, lu sous confinement ; `arbres` injectable (le signal a déjà la liste). Un arbre illisible est écarté, jamais fatal.
export function lireAilleurs(root, { arbres, opts = {} } = {}) {
  root = path.resolve(root);
  const sortie = [];
  for (const a of arbres || arbresGit(root)) {
    if (meme(a.chemin, root)) continue;
    try {
      const pl = lireConfine(a.chemin, () => readPlanning(a.chemin, planningLayout(a.chemin), { ...opts, lab: root, sansTags: true }));
      sortie.push({ chemin: a.chemin, nom: nettoie(path.basename(a.chemin), 80), branche: nettoie(a.branche, 80), pl });
    } catch { /* arbre sans planning lisible : ignoré */ }
  }
  return sortie;
}

// copie de `phases` où chaque phase non close prend l'avancement du worktree le plus avancé s'il dépasse celui de l'arbre courant ; `phases` n'est jamais modifiée
export function fusionner(phases, ailleurs) {
  const rang = (e) => ETAT_ORDRE.indexOf(e);
  const sortie = new Map();
  for (const [k, ph] of phases) {
    let meilleur = null, rg = rang(ph.avancement?.etat);
    if (!ph.done && !ph.archive && ph.avancement?.etat !== 'fait') for (const a of ailleurs) {
      const q = a.pl.phases.get(k);
      if (!q || q.archive || !q.avancement) continue;
      const clos = q.avancement.etat === 'fait', etat = clos ? 'a-recetter' : q.avancement.etat; // clôture non fusionnée : il ne reste que la clôture elle-même
      if (rang(etat) > rg) { rg = rang(etat); meilleur = { a, av: { ...q.avancement, etat, ...(clos ? { reste: ['cloture'] } : {}) } }; }
    }
    sortie.set(k, meilleur ? { ...ph, avancement: { ...meilleur.av, ailleurs: { arbre: meilleur.a.nom, branche: meilleur.a.branche } } } : ph);
  }
  return sortie;
}
