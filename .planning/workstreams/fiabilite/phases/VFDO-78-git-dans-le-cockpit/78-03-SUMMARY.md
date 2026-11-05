---
phase: 78
plan: "03"
subsystem: cockpit
tags: [git, shell-quoting, tiroir-git]
requires: []
provides: [plugin/cockpit/scripts/vf-cockpit-git-commandes.mjs]
affects: [78-05, 78-06, 78-08, 78-10]
key-files:
  created:
    - plugin/cockpit/scripts/vf-cockpit-git-commandes.mjs
    - plugin/cockpit/scripts/tests/test-cockpit-git-commandes.sh
    - .planning/workstreams/fiabilite/phases/VFDO-78-git-dans-le-cockpit/78-03-RED-TRACE.md
requirements-completed: [GITC-10]
---

# Phase 78 Plan 03 : commandes à copier du tiroir Git — Summary

Module pur (27 lignes, aucun `child_process`, une seule citation `citer`) et suite de 33 assertions qui EXÉCUTENT les commandes
(bash, zsh, sh) dans des dépôts jetables : noms nommés, échantillon généré (150 noms, graine 78), citation à l'octet, parité avec `nettoie`
sur U+0000..U+10FFFF, 13 mutants. Traces : `78-03-RED-TRACE.md`.

## Texte exact produit par chaque commande (pour les témoins de 78-06 et 78-10)

| Constructeur | Sortie |
|---|---|
| `cmdCd('/a b/c')` | `cd -- '/a b/c'` |
| `cmdSwitch('feat/x')` | `git switch --end-of-options 'feat/x'` |
| `cmdDetacher('4759171')` | `git switch --detach --end-of-options 4759171` |
| `cmdBranchSupprimer('feat/x')` | `git branch -d --end-of-options 'feat/x'` |
| `cmdShowStat('4759171')` | `git show --stat --end-of-options 4759171` |
| `cmdStashShow('stash@{0}')` | `git stash show --stat 'stash@{0}'` |
| `cmdCommitInitial()` | `git commit -m "premier commit"` |
| `cmdStatus()` | `git status` |

L'UI-SPEC §3 montre des formes plus courtes (`git switch '<branche>'`) : le manager les aligne sur ce tableau (P78-D-14).

## Formes retenues pour `--end-of-options` (git 2.50.1, sondées par exécution, C2)

`git branch -d --end-of-options '-x'` : rc 0, branche supprimée (sans l'option : `error: unknown switch 'x'`, rc 129) ;
`git show --stat --end-of-options <sha7>` : rc 0 ; `git switch --detach --end-of-options <sha7>` : rc 0, HEAD détaché ;
`git switch --end-of-options '--all'` : rc 0. Aucune retombée sur la forme `-- ` n'a été nécessaire.

## Deviations / à décider

1. **Défaut trouvé par l'échantillon généré** : `git switch` lit `-` (branche précédente) et `@` (HEAD) comme raccourcis même après
   `--end-of-options`. `cmdSwitch` rend `null` pour ces deux noms (ajout hors plan, témoin C1.8a). `git branch -d` les vise correctement.
2. **`null` = pas de commande, l'UI doit le montrer** (plans 06 et 10) : nom/chemin vide, de plus de 200 caractères, avec un caractère
   que l'affichage retire, `-`/`@` pour switch, sha ou ref de stash hors motif. Un chemin de worktree de plus de 200 caractères n'a donc
   pas de commande `cd` : l'UI affiche l'absence (jamais une commande tronquée).
3. **Masque des secrets** (finding, non traité) : `nettoie` masque aussi les jetons (`[masqué]`). Si 78-05/78-08 font passer le champ
   `commande` par `nettoie`/`masque`, un nom de branche qui ressemble à un secret donnerait une commande copiée différente du nom réel.
   À trancher au merge : ne pas masquer `commande`, ou refuser la commande si `masque(nom) !== nom`.
4. Limite : l'exécution est en `sh -c` non interactif ; l'expansion d'historique `!` d'un shell interactif n'est pas jouée (les guillemets
   simples la protègent dans bash et zsh).
5. Le `<verify>` de la Tâche 1 ne contrôle que `C1.1` et `C1.3` en texte : la suite rend déjà exit 1 sur tout FAIL, l'exit code est le
   contrôle complet (`Résultats : 33 PASS, 0 FAIL`).
