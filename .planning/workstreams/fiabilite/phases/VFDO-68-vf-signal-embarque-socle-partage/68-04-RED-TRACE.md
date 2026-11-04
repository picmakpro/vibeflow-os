# 68-04 — Trace du rouge (VFSG-01 ; P68-D-11, P68-D-13)

Claude Code : 2.1.318. Arbre : worktree `phase-68-w04`, commit des témoins `e19b2762`, joués AVANT l'import du mod.

## Rouge avant l'import — `bash plugin/cockpit/scripts/tests/test-cockpit-signal-mod.sh` (rc=1)

Contrôles positifs M0.1 à M0.3, M1.1, M1.6, M1.7, M3 : verts (la suite sait rougir, le balayage voit 6 fragments).
Assertions rouges (attendu / obtenu) :

```
  ❌ FAIL — M1.2 — le manifeste déclare hooks → ./cockpit/signal/hooks/hooks.json (attendu [./cockpit/signal/hooks/hooks.json], obtenu [absent])
  ❌ FAIL — M1.3 — le fichier déclaré existe (attendu [oui], obtenu [non])
  ❌ FAIL — M1.4 — il ne porte que la clé modules (attendu [modules], obtenu [aucun])
  ❌ FAIL — M1.5 — le manifeste déclare types → ./cockpit/signal/types/index.d.ts (attendu [./cockpit/signal/types/index.d.ts], obtenu [absent])
  ❌ FAIL — M2.1 — aucune déclaration d'atome trouvée (un vert à vide serait un faux vert)
  ❌ FAIL — M2.3 — types/index.d.ts absent
  ❌ FAIL — M4.1 — plugin/cockpit/signal/ absent
  ❌ FAIL — M5 — aucun fichier du mod : plugin/cockpit/signal/ absent ou vide
=== bilan : 9 ok, 8 ko ===
```

M1 (le manifeste ne porte ni `hooks` ni `types`, fichier déclaré absent), M2 (aucune déclaration d'atome : jamais un vert à vide),
M4 (le mod est absent) et M5 (aucun fichier à mesurer) rougissent pour la bonne raison : le mod n'est pas là.

## Rouge avant l'import — install de l'engine sur un cache piégé (I9a, témoin VFSG-01)

`bash plugin/_internal/tests/test-vibeflow-update-cockpit.sh` (rc=0, 13 ok) ; la ligne du témoin :

```
  ✓ I9a témoin rouge : un fragment réduit à modules fait échouer l'install (rc=1, fragment sans clé 'hooks')
  ✓ I9 : cache piégé refusé (fragment sans clé 'hooks'), vrai cache installé sans .ts/.tsx ni signal/ sous la cible
```

Le cache piégé (`cockpit/hooks/hooks.json` réduit à `{ "modules": [...] }`) fait échouer l'install : `rc=1`, message
`fragment sans clé 'hooks' exploitable` (merge-hooks.sh l. 303-304). C'est le seul rouge de la suite d'install avant l'import.

**Le contrôle du cache réel (I9b) n'est PAS un témoin avant l'import** : le cache n'a alors aucun `signal/` ni `.tsx` à écarter,
il est vert à vide. Il ne devient un témoin qu'après l'import (annexe ci-dessous).
