---
description: Vérifie si le framework VibeFlow a évolué et recalibre/migre le lab (mise à jour structure/doctrine) sous validation humaine.
argument-hint: "[optionnel : précision sur ce qu'on recalibre]"
---

Invoque le skill **`vf-calibrate`** (propagation d'update + migration) : $ARGUMENTS

Le skill détecte l'écart de version framework ↔ lab (`framework-version.sh drift`), lit ce qui a
changé (en distinguant bugfix / nouvelle capacité / breaking-doctrine), propose un plan de migration
explicite, l'applique **sous validation humaine** (ADR-031, snapshot avant/après), re-stampe la
version et déclenche un ré-audit via `vibeflow-validator`.

Si le module `conductor` n'est pas installé, lance d'abord `vibeflow-install`.
