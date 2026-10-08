---
name: rtk-git-log-masque-les-merges
description: `git log` passé par rtk n'affiche pas les commits de merge — la pointe d'origin/main lue ainsi est fausse ; lire la base par `git rev-parse`
metadata:
  type: project
---

`git log --oneline -N origin/main` réécrit par rtk a affiché `2aa307df` en tête alors que la pointe réelle était le merge `0c14757b` (PR #130). `git log -1 --format='%H %P' <merge>` a même rendu le hash d'un autre commit. Mesuré le 2026-10-02 (mission manuel, PR #132) : ma boucle d'attente comparait HEAD à un SHA de base faux et concluait « commit fait » dès le premier tour.

**Why:** rtk filtre la sortie de `git log` et masque apparemment les commits de merge. Une base de diff, une boucle d'attente, un `sha` de preuve E6 dérivés de cette sortie sont faux sans aucun signal.

**How to apply:** pour la pointe d'une ref ou une base de diff, utiliser `git rev-parse <ref>` (ou `rtk proxy git log`). Ne jamais tirer un SHA de la sortie filtrée de `git log`. Voir [[base-de-diff-derivee-du-parent]], [[grep-proxifie-tronque]].
