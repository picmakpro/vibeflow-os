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

## Import mécanique (commit C) — verts

- `claude plugin validate --strict plugin` : rc=0 (Claude Code 2.1.318). Il déclare `state: vibeflow.disk … vibeflow.bandHiddenFor`.
- Argument de `claude plugin test` qui découvre les tests (« Runs every *.test.ts and *.test.tsx under dir ») : le dossier du plugin.
  Sortie : `3 pass, 0 fail, Ran 3 tests across 1 file` (rc=0), fichier `cockpit/signal/tests/vf-signal.test.tsx`.
  `claude plugin test` n'écrit aucun typing : le dossier `plugin/.claude-plugin/types/` n'existe pas après validate ni test
  (non mesuré : les typings sont générés au chargement du plugin dans une session ; `tsconfig.json` du mod étend ce chemin prévu).

ARG_TEST=plugin

- Retouche forcée par la mesure, hors des trois prévues : le test source nomme `plugin: 'vf-signal'` dans ses événements de rendu
  (PANE, BAND) ; sous le plugin `vibeflow`, `press` ne trouvait plus les boutons (2 échecs : « no Button of vf-signal keyed … »).
  Les deux littéraux passent à `vibeflow` ; la forme `command: 'vf-signal'` et les titres restent (c'est le nom de la commande).
- `test-cockpit-signal-mod.sh` : 17 ok, 0 ko (M0 à M5). `test-vibeflow-update-cockpit.sh` : 13 ok, 0 ko.

## Annexe — I9 : le contrôle du cache réel devient un témoin (rouge sur copie mutée)

Copie jetable du dossier `plugin/` ; `copy_module_scripts` de `vibeflow-update.sh` y est muté pour poser `signal/` sous la cible
(`cp -R "$module_dir/signal/." "$TARGET_ROOT/signal/"`). `test-vibeflow-update-cockpit.sh` joué sur la copie (rc=1, 12 ok, 2 ko) :

```
  ✓ I9a témoin rouge : un fragment réduit à modules fait échouer l'install (rc=1, fragment sans clé 'hooks')
  ✗ I9b : fichier .ts/.tsx posé par l'engine : <tmp>/lab-reel/.claude/signal/types/index.d.ts
  ✗ I9b : dossier signal/ posé par l'engine : <tmp>/lab-reel/.claude/signal
== resultat : 12 ok, 2 ko ==
rc=1
```

Pour la bonne raison : le `.d.ts` et le dossier `signal/` posés sont nommés. Copie supprimée ; `git diff --stat -- plugin/_internal/vibeflow-update.sh`
vide (engine du dépôt intact) ; I9 vert sur le dépôt :

```
  ✓ I9a témoin rouge : un fragment réduit à modules fait échouer l'install (rc=1, fragment sans clé 'hooks')
  ✓ I9 : cache piégé refusé (fragment sans clé 'hooks'), vrai cache installé sans .ts/.tsx ni signal/ sous la cible
== resultat : 13 ok, 0 ko ==
rc=0
```
