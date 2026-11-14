# 75-02 — Gardes : résumé

Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).
Mutants et preuve générative chronométrée levés ; témoins d'équivalence vus rouges puis verts (voir `75-02-RED-TRACE.md`).

## Livré

- `plugin/cockpit/scripts/vf-cockpit-activite-gardes.mjs` (202 lignes, aucune ligne au-delà de 160 colonnes, aucune `RegExp` construite, aucun
  `child_process`) : `decouvrirSuites`, `gatesDeCi`, `contexteGardes` (asynchrone : `git ls-files -z` par `lancerGitAsync`), `suitesQuiNomment(f, ctx)`,
  `estGarde`, `CLASSES_GARDE` (un tableau), `estSuite`, `globLineaire` (itératif, un point de reprise, `*` `?` `[..]` `\x`), `calculerGardes(lab, carteCode)`.
- `plugin/cockpit/scripts/tests/test-cockpit-activite-gardes.sh` : 25 témoins. E0 découverte (égale à `ci-shard-suites.sh --all`, lien symbolique exclu ;
  `.git` et `node_modules` sautés), E1 à E7 et E9 équivalence avec `scripts/ci-suites-perimetre.sh --liste` exécuté sur un dépôt fixture, E8 gates de `ci.yml`,
  E10 `ls-files` (fichier supprimé, 300 pilotes déclarés, hors dépôt), P1 parité des six classes avec `check-gate-touche.sh` (26 chemins), P2 tuples,
  P3 lab non VibeFlow / sans suite / `ls-files` refusé, P4 `globLineaire` contre le `case` de bash (28 couples) et croissance N/2N, P5 coût.
- `75-02-RED-TRACE.md`.

## Écarts

- Modules de la fixture nommés `mod-a` et `mod-t`, pas `a` et `t` : le nom `a` est une sous-chaîne de tout texte, donc « la suite cite le module » serait vrai
  partout et E7 inatteignable. Les suites leurres (`test-s3x.sh`, `test-s4x.sh`) citent le nom seul : sous `plugin/<m>/`, citer le dossier implique citer le module,
  donc sans leurre E3 et E4 ne distingueraient pas la règle d'ambiguïté du calcul naïf.
- `SOUS_COMMANDES_FILTRANTES` (cité par le plan, E10) n'existe pas dans le code livré : `ls-files` figure dans `SOUS_COMMANDES_AUTORISEES`
  (`vf-cockpit-git-durci.mjs`), le refus vient de `MAX_FILTRES` (plus de 256 pilotes déclarés) via `REFUS_GIT`. E10 déclare 300 filtres dans `.git/config`.
- La découverte vit à la ligne 268 de `ci-shard-suites.sh` (257 dans le plan), même forme `find plugin scripts -type f -path '*/tests/test-*.sh' | LC_ALL=C sort`.
- Interprétation de D-16 : les gates de `ci.yml` entrent dans le corpus de citation au même titre que les suites (un gate qui nomme un fichier le garde) ;
  `suitesQuiNomment` rend donc des chemins de suites ET de gates. Sur ce dépôt : 234 suites, 24 gates.
- Le code de la tâche 2 (`CLASSES_GARDE`, `estGarde`, `globLineaire`, `calculerGardes`) a été écrit avec celui de la tâche 1 ; le rouge de la tâche 2 est mesuré sur
  une copie du module sans ces exports, via la variable `VF_GARDES_MODULES` lue par la suite (sans elle, le module du dépôt).
- La suite sort en fin de course (comme les suites voisines), pas au premier FAIL ; le seuil de croissance passe de `+2 ms` à `+20 ms` (poste partagé).
- Le plan situe `ls-files` « suivis » comme fichiers du lab ; un lab sous-dossier d'un dépôt est lu relativement à ce dossier (comportement de `ls-files`).

## Suites jouées

- `bash plugin/cockpit/scripts/tests/test-cockpit-activite-gardes.sh` : vert, 25 PASS, 0 FAIL, 9 s (tête `e02337a0`). Contre-épreuve : rouge, 9 FAIL, sur la copie sans les quatre exports.
- `node plugin/cockpit/scripts/tests/colonnes-cliquet.mjs verifier plugin/cockpit plugin/cockpit/scripts/tests/colonnes-baseline.txt` : le module ne figure pas parmi les
  écarts (les écarts relevés sont ceux des fichiers des plans voisins).
- `bash scripts/check-machine-paths.sh` : vert.

## À la jointure (hors fichiers de ce plan)

- Le compteur « N suites » des README racine (`scripts/check-version-sync.sh`) et la table des durées de `ci-shard-suites.sh` voient une suite de plus ; durée mesurée : 9 s.
- `calculerGardes` est asynchrone ; `carteCode` = `graph.json` du cockpit (`meta.vfCodeExtractor`, `files[].p`, `l` = `docs` pour un doc, `st` = `prevu` pour une carte prévue).
