---
phase: 68-vf-signal-embarque-socle-partage
plan: 08
requirements: [VFSG-07, VFSG-06]
status: complete
---

# 68-08 — Direction « Graphite » dans la pane (VFSG-07, VFSG-06 ; P68-D-05, P68-D-06, P68-D-09, P68-D-17, P68-PL-10)

Trace du rouge, du vert et des mutants : `68-08-RED-TRACE.md`. Claude Code 2.1.318. Branche `feat/phase-68-w08`, partie de `f0a850bd`.
Précondition P68-D-09 tenue : `DESIGN.md` « Graphite » est sur `main` (identique à celui de l'arbre ; `shasum` `eb6928e61288eee5d10ad82e0bc501e2538f1ad1`, dernier commit `db8f6736`).

## Commits (ordre : tests, trace, code)

| Empreinte | Objet |
|-----------|-------|
| `fb49f6eb` | test : R8-G1..G5b (9 tests), M9 et M10 de la suite statique (trailer `Gate-Touche:`), rouges |
| `7d9af482` | docs : trace du rouge |
| `adbe3b79` | feat : `tokens.ts`, thème lu de `$.config.list()` en `session.start`, en-tête en tokens, type `Theme` |
| `c9c9d5cd` | feat : la palette « Signal » quitte `ds.ts` ; pane, bandeau, boutons, vues mission/macro/équipe en tokens ; regex de R8-G5 ancrée |
| `d9a45336` | test : M10 lisible sous zsh (trailer `Gate-Touche:`) |

## Résultats

- `claude plugin test plugin` : 63 pass, 0 fail ; `claude plugin validate --strict plugin` rc=0.
- `test-cockpit-signal-mod.sh` : 40 ok / 0 ko sous bash et sous zsh (M0 à M10) ; `check-machine-paths.sh` rc=0 ; `check-gate-touche.sh` : RIEN-A-JUGER (exit 3).
- Plus long fichier touché : `register.tsx` 202 lignes ; `graphite.test.tsx` 125 ; suite statique 180 (plafond 300).
- Mutants : 9 familles, chacune rougit sur l'assertion visée (annexe de la trace).

## Choix de couleur (tous tranchés par `DESIGN.md`, aucun goût inventé)

`done` -> `st-done` ; `running`, `en-cours`, `a-recetter`, attention humaine (action, retard, orphelin, refus du tour, contexte >= 85 %, ancien mod) -> `st-active` ; `ready`, `a-faire`, `abandonnee`, `inconnu`, terminé -> `st-todo` ; `failed`, verrou périmé, erreur du socle, échec du lanceur -> `st-blocked` ; le reste en `text` à `text-4`. Le fil de la boucle : étape courante `text` (gras), faites `text-3`, à venir `text-4`.

## Écarts au plan

1. **`boutons.tsx` modifié alors qu'il n'est pas dans `files_modified`** (le plan précède 68-07, qui l'a créé) : il importait `C` de `ds.ts` ; sans retouche, retirer `C` (P68-D-17) casse la pane. Retouche minimale : une palette passée en argument, deux couleurs (`text-2`, `st-blocked`). `views/common.tsx`, `band.tsx` sont dans la liste ; `refresh.ts` et `derive.ts` non touchés.
2. **Découpage des commits** : un commit « tokens + en-tête » puis un commit « ds, pane, bandeau, boutons, trois vues » (le plan en prévoyait trois : macro et équipe ensemble avec le deuxième, parce que `row`/`head`/`ghost` de `common.tsx` prennent désormais la palette et auraient cassé macro et équipe entre deux commits). Les G1 à G3 ne sont donc pas rejoués sur l'état intermédiaire `adbe3b79` : le vert est tracé sur l'état final.
3. **Identifiants `R8-G…`** au lieu de `G1…` (préfixe demandé par le mandat) ; tests supplémentaires : R8-G3b (thème `dark`), R8-G4b (mission abandonnée dans la vue), R8-G5b (équipe).
4. **Le libellé d'avancement de l'arbre est un `Text` imbriqué** `(à recetter)` coloré par `phaseActive.etat` (le plan l'exigeait en G2 sans dire où) ; le texte concaténé de la ligne est inchangé.
5. **Thème lu une fois** en `session.start` (comme prévu) : un changement de thème en cours de session ne se voit qu'au prochain démarrage ou `/clear` non rejoué ; non prouvé sous un vrai moteur : `$.config.list()` est simulé par `on('config.list')`, la forme réelle des lignes (`key: 'theme'`, valeur chaîne contenant `light`) vient du type d'API et n'est pas constatée en réel.
6. **Cohérence « à recetter »** : la mission non vivante ou inconnue est `st-todo`, la mission `running` prend `st-active` (jamais l'ancien « cyan machine »).
7. **`ds.ts` garde `G`, `STAGES`, libellés et durées** ; plus aucune couleur. `DESIGN.md` non touché. Aucun `.mjs` du socle touché.
8. **Non prouvé** : le rendu réel des couleurs hexadécimales par un terminal (le harnais lit les props, pas la peinture) ; contraste `text-4` (`#5c5c5c`) sur le fond d'un terminal clair ou sombre non mesuré, c'est la valeur que `DESIGN.md` fixe pour « à faire ».

## Artefacts posés d'office dans le dossier de phase

`68-08-RED-TRACE.md`, `68-08-SUMMARY.md` (aucun autre).

## Estimate / actuals

estimate du plan : 90 000 tokens, 3 tâches, confiance basse. actuals : non mesurés (exécution inline, pas de `gsd-execute-phase`).
