---
name: cascade-de-resolution-par-fausse-analogie
description: Une cascade de résolution copiée sur une autre « identique » ne résout jamais — 2 cas en une seule phase, dont un bloquant qui désactivait toute la capacité livrée
metadata:
  type: project
---

Dans cet engine, la **cascade de résolution de script** (`$TARGET_ROOT/scripts/` → `$(dirname "$0")`
→ `$CACHE_DIR/...`) est le motif le plus copié — et le plus copié **à tort**. Une cascade est
correcte **relativement à l'endroit d'où on appelle** ; la recopier depuis un appelant différent la
casse silencieusement.

**Why:** Phase 38 (2026-08-28), **deux occurrences indépendantes**, toutes deux « silencieuses » :

1. **BLOQUANT** — `runtime-cli-dispatch.sh` (neuf) documentait sa résolution comme « cascade
   **EXACTE** de `find_hooks_merger()` ». Or `find_hooks_merger()` est appelée par
   `vibeflow-update.sh` **lui-même**, dont `$0` reste toujours adjacent à `_internal/` : son repli
   résout **toujours**. Le nouveau script est au contraire résolu par des scripts **POSÉS**
   (`ensure-deps.sh`, `check-plugin-update.sh`), dont le `$0` devient `$TARGET_ROOT/scripts/…` à
   toute ré-invocation — et **rien ne le copiait là**. Résultat : la capacité multi-runtime entière
   ne s'activait **qu'au tout premier run d'install**, jamais ensuite. Trouvé par la **revue de
   jointure** seulement : chaque relecteur de lot voyait un code correct dans son périmètre.
2. Le plan de FIDE-02 prescrivait `TARGET_ROOT/scripts` → `dirname "$0"` → `CACHE_DIR/_internal`
   pour joindre `check-artifact-fidelity.sh` — qui vit sous `conductor/scripts/`, **jamais** sous
   `_internal/`. Appliquée à la lettre, la fonctionnalité aurait été un **no-op permanent**. Le
   worker l'a détecté en la testant au lieu de la recopier.

**How to apply:**
1. Devant toute cascade de résolution, poser **une seule question** : *qui est `$0` au moment de
   l'appel, et à chaque ré-invocation ?* Un script **posé** n'a pas le même `$0` qu'un script du
   **cache**, et `/vf-update`, `/vf-calibrate` et le hook SessionStart ré-invoquent depuis
   `$TARGET_ROOT/scripts/`.
2. **Un fichier partagé résolu par des appelants posés DOIT avoir son pas de pose.** Le précédent
   correct est `vf-portable.sh` : fonction `copy_engine_lib()` + entrée `.gitignore` + exclusion de
   manifeste. Vérifier ces **trois** pièces, pas seulement la première.
3. Une cascade ne se teste jamais **depuis sa position source** — c'est le seul endroit où elle
   marche toujours. Le test doit **ré-invoquer un appelant POSÉ**.
4. « Cascade identique à X » dans un commentaire est un **signal d'alarme**, pas une garantie :
   c'est la formule exacte qui a masqué le cas bloquant. Même famille que
   [[mesure-juste-attribution-fausse]] — l'analogie est juste sur la forme, fausse sur le contexte.
