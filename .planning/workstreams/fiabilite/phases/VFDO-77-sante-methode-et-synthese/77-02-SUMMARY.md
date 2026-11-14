# 77-02 — SUMMARY

## Livré
- `vf-cockpit-burnup.mjs` (module pur, 45 lignes) : `CLOTURE`, `INSCRIPTION`, `dates`, `burnup` ; dates lues sur la ligne de checklist du ROADMAP, série en escalier, phases sans date nommées, rien d'estimé ; pourcentage injecté (la fonction `pct` du pied de jalon).
- `vf-cockpit-blocages.mjs` (module pur, 35 lignes) : section « Blockers/Concerns » du STATE → `[{ h, t }]`, `t` nettoyé par `nettoie` et borné, `h` condensat de 12 hexadécimaux du texte normalisé.
- Branchement : `readPlanning` renvoie `blocages` (texte du STATE déjà lu) ; `buildProjectGraph` pose `meta.vf.burnup` (jalon mis en avant) et `meta.vf.blocagesState` (forme `{ h, t }`, inchangée pour 77-04) ; la clé de la prose `last_activity_desc` n'est plus produite.
- Contrat : `burnup` et `blocagesState` ajoutés à `optionnels.metaVf` de `cockpit-project@1`, phrase sur `base.h` dans la description de `cockpit-git@1`, aucune version montée.
- Suites neuves `test-cockpit-burnup.sh` (26 PASS) et `test-cockpit-blocages.sh` (17 PASS), R3.25 réécrite, inscription des deux suites dans `scripts/ci-shard-suites.sh`, CHANGELOG du cockpit (`### Ajouté` et `### Retiré`), « 234 suites » dans les deux README (remesuré sous verrou, `check-version-sync.sh` vert).
- Témoin BU11 jouable (79-01, 79-07, 79-09 présents dans la base) : `instantane().projet` porte les deux champs, égaux à ceux de `buildProjectGraph`.

## Écarts
- Écart : la forme du contrat depuis 76-04 range les facultatifs de `meta.vf` sous `optionnels.metaVf` (liste), pas sous un sous-bloc `meta.vf` avec `optionnels` et `dit` comme le disait le plan ; les deux champs y sont ajoutés et leur forme est dite dans la `description` de `cockpit-project@1`. BL11 lit cet endroit. Aucun contrat consommé par une autre phase ne change.
- Écart : `construireGraphe` finit par `projeterTrace(graphe, …)` (76-04) ; les deux ajouts s'insèrent avant cet appel, sans déplacer de ligne de la 76.
- Écart : tâches 1 et 2 regroupées pour le code (le module `burnup` est écrit en une fois avec sa série) : 4 commits (témoins rouges, burn-up, retrait de la prose, blocages et contrat) au lieu de 5.
- Écart : le plafond de 160 colonnes (cliquet `colonnes-cliquet.mjs`) a rougi V4c.9a sur trois fichiers après un premier jet ; lignes recoupées, baseline inchangée.
- Poids du graphe Projet sérialisé (même lab : le worktree de la phase, même commande `buildProjectGraph`) : avant 2 824 869 octets, après 2 825 927 octets (+1 058).
- `ui/00-vibeflow.js` non touché : à verser par la jointure : ligne morte de lecture de la prose dans `ui/00-vibeflow.js:211` (Phase 80).
- rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) — pas de mutant (M-PONDERE, M-ESTIME, M-COCHE, M-PREMIERE, M-PROSE, M-NETTOIE, M-SECTION, M-CONDENSAT, M-BORNE non joués) ; la sonde BL7 reste en suite.

## Suites jouées (verdicts, secondes)
Sur la tête finale commitée : burnup 26 PASS (2 s), blocages 17 PASS (2 s), vendor 252 PASS (83 s), projet-visite vert (647 s), projet-graphe 119 PASS (485 s, en parallèle de la visite).
Sur la tête avant recoupe des lignes longues (changement sans effet de comportement) : serveur 98 PASS (56 s), securite 103 PASS (72 s), signal 76 PASS (32 s), transcript 103 PASS, lancer-suivi 39 PASS ; `test-ci-shard-suites.sh` 22 PASS (5 s) ; `check-version-sync.sh` vert.
Premier rouge rencontré : V4c.9a (cliquet de colonnes) de `test-cockpit-vendor.sh`, corrigé en recoupant mes lignes ; vendor vert ensuite. T28-F de `test-dev-orchestrator.sh` non jouée (rouge local connu).

## Correction après CI
PC3.2 de `test-cockpit-projet-champs.sh` (rouge déterministe en CI, shard 6) attendait `metaVf` sans mes deux champs : `burnup` et `blocagesState` y sont inscrits à la suite de ceux de 76-04, rien d'autre n'est modifié. Rouge vu en local avant, vert après (suite rejouée une fois).
