---
phase: 68-vf-signal-embarque-socle-partage
plan: 05
requirements: [VFSG-11, VFSG-05, VFSG-06]
status: complete
---

# 68-05 — Appel du socle par le mod, erreurs en clair, en-tête (VFSG-11, VFSG-05, VFSG-06)

Trace du rouge, du vert et des mutants : `68-05-RED-TRACE.md`. Claude Code 2.1.318. Branche `feat/phase-68-w05`, partie de `0f016873`.

## Commits (ordre : tests, trace, code)

| Empreinte | Objet |
|-----------|-------|
| `b512d0a9` | test : témoins K1-K6, K9, K13, K14 et fixture `signal@1`, rouges |
| `4c9caa26` | docs : trace du rouge avant le code |
| `12a1f137` | test : faux lab corrigé (rejet par `{ deny }`, `init.cwd`) |
| `e0e0727e` | test : retouche minimale de `vf-signal.test.tsx` (voir écart 3) |
| `2d6423b8` | docs : rouge rejoué avec les tests corrigés (8 pass / 9 fail) |
| `b84d3cb8` | feat : `socle.ts`, `refreshSignal`, type `Signal`, `en-tete.tsx` (phase + erreurs), `pane.tsx` |
| `e5c4ae48` | test : K7, K8, K10, K11, K15, K16, K17 |
| `771ce052` | docs : rouge de l'en-tête complet |
| `8914f4ce` | test : K14 attend la fin du vol |
| `c5dbd73d` | docs : vert et mutants |
| `925cb419` | feat : retard, worktrees, mission courante |

## Résultats

- `claude plugin test plugin` : 24 pass, 0 fail (3 rejeux) ; `claude plugin validate --strict plugin` rc=0.
- `test-cockpit-signal-mod.sh` 19 ok / 0 ko ; `test-cockpit-signal.sh` 43 PASS / 0 FAIL ; `check-machine-paths.sh` rc=0.
- Longueurs : `socle.ts` 57, `en-tete.tsx` 77, `pane.tsx` 198, `refresh.ts` 93 (plafond 300).
- Mutants : 11, chacun rougit sur l'assertion visée (annexe de la trace).

## Écarts au plan

1. **Forme d'appel de l'émetteur** : conforme à la CLI de 68-03 (un argument, la racine de session). Aucun écart.
2. **Harnais de test** (trouvé en écrivant le code, rejoué en rouge) : un gestionnaire `process.run` qui lève donne « no implementation for process.run » (le rejet se simule par `{ deny: … }`) ; l'événement porte `{ argv, init: { cwd, timeoutMs } }` ; `$.plugin.root` n'existe pas sur le `$` du test, K1 déduit la racine du plugin du script (`argv[1] === <cwd>/cockpit/scripts/vf-cockpit-signal.mjs`, `cwd` ≠ `/lab`). L'import dynamique est refusé par le chargeur de mods, K14 passe par la pression de `rafraichir`. Le test réel de l'ENOENT par le moteur reste donc non prouvé (le moteur n'est pas atteint sous `claude plugin test`) : à confirmer à la recette de 68-09.
3. **Retouche d'un test existant** (`vf-signal.test.tsx`, commit `e0e0727e`, isolée) : l'en-tête ne lit plus le jalon ni la phase du STATE ; le faux lab répond à l'émetteur et l'assertion `/equipe-produit-v1\.0/` + `/Bundle produit/` devient `/phase 59 Bundle produit/`. **Le jalon n'est plus affiché** dans l'en-tête (le signal ne porte pas le libellé de jalon de STATE ; `jalons[]` existe, non utilisé ici). Verte avant et après le code.
4. **Témoins ajoutés** aux K1-K9 du plan : K5 (schéma), K10 (compact), K11 (mission inconnue, P68-D-23), K13 (délai), K14 (appel unique), K15 (singulier + origine), K16 (aucun fetch), K17 (garde : arbre à jour).
5. **Libellés** : si `fetchAgeS` est `null` la ligne dit « …, aucun fetch connu » (et non « dernier fetch il y a aucun fetch connu ») ; si `main` vaut 0 mais `origin` > 0, la ligne ne porte que le segment « origin/<base> local : en retard de M ».
6. **En-tête dockée** : la ligne de phase de l'arbre courant est celle de sa ligne de worktree (marquée ▶), pas une ligne séparée. Compact : `<ws> · phase … (libellé) · retard N · <étape>`. Couleurs : celles du design existant, la couleur par état vient en 68-08.
7. Sur échec de lecture, `signal` retombe à `null` (aucune donnée affichée à moitié) et `signalErreur` porte le message ; une lecture réussie remet l'erreur à `null`. `racine de session inconnue` si `$.session.root()` échoue.
8. Les vues et `derive.ts` lisent toujours la lecture maison (état intermédiaire assumé, retrait en 68-06).

## Artefacts posés d'office dans le dossier de phase

`68-05-RED-TRACE.md`, `68-05-SUMMARY.md` (aucun autre).

## Estimate / actuals

estimate du plan : 75 000 tokens, 2 tâches, confiance basse. actuals : non mesurés (exécution inline, pas de `gsd-execute-phase`).
