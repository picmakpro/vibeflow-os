# 77-01 — SUMMARY : sortie TSV des deux gates de méthode (SYNT-02, SYNT-04)

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) — triple passe, preuve générative et rejeu suite par suite au-delà de ce que le plan nomme. Plan de gate : témoin rouge ET un mutant par garde conservés (MF1..MF8, MI1..MI6).

## Livré

- `check-method-budget.sh --format=tsv` : en-tête `#vf-budget@1`, huit types (`state`, `state-prose`, `backlog-ouverts`, `backlog-entree`, `backlog-clos`, `roadmap`, `memory-index`, `worktrees`), chemins relatifs (`rel`), budgets effectifs, `NON-VERIFIABLE` / `NON-APPLICABLE` sans valeur. Prose de STATE et entrée de BACKLOG : valeur la plus haute vue (awk `EMAX`, enregistrement `M`), lue seulement en mode TSV. Mode TSV : `--no-remote` implicite, passe de rangement sautée, `say`/`flag` muets, refus 64 de `--auto`, `--archive`, `--dry-run` et de tout autre format.
- `check-instruction-budget.sh --format=tsv` : `agent`, `skill`, `socle`, `socle-baseline` ; lab sans corpus d'agents : en-tête et trois lignes `NON-APPLICABLE` (`agent`, `skill`, `socle`), code 2 gardé ; tout autre format : 64.
- Suites : sections `TF1`..`TF13` + mutants `MF1`..`MF8`, `TI1`..`TI9` + mutants `MI1`..`MI6` ; deux copies figées `check-method-budget-pre-4a246c4c.sh` et `check-instruction-budget-pre-394c7956.sh` (suffixes inchangés : aucun commit n'a touché les gates depuis la planification).
- Entrée de CHANGELOG du module `conductor` (Minor, section `[Non publié]`, aucun bump de `VERSION`). `77-01-RED-TRACE.md`.
- Commits : tests et trace, gate de méthode, gate de densité + CHANGELOG + SUMMARY.

## Écarts

- Écart : le TSV du gate de densité est dérivé, en fin de script, des deux fichiers de rapport que le gate écrit déjà (awk), et non écrit à chaque site de mesure : aucune ligne de mesure du gate n'est touchée (cibles MUT-1..13 intactes), le verdict est celui que le gate a posé.
- Écart : tâche 1 et gate de méthode en deux commits (tests + trace d'abord, gate entier ensuite) au lieu d'un traceur partiel ; le rouge est prouvé sur la copie figée du gate (RED-TRACE), pas sur un traceur intermédiaire.
- Écart : la mesure « aucune cible retirée » lit le diff par hunk (awk) et non par `sed '^-\([^-]…'` : cette dernière rate une cible qui commence par `-` (sonde dans la RED-TRACE, bash et zsh).
- Précisions du contrat `#vf-budget@1` (aucun changement de forme) : `socle-baseline` porte en `valeur` la ligne de baseline lue (la mesure est sur la ligne `socle`), budget `-` ; une mesure au-dessus de la baseline donne `socle` en `DEPASSE` (`DEPASSEMENT-BOOTSTRAP`) ; `AU-DESSUS-PLAFOND-ADR029` (non bloquant) donne aussi `DEPASSE` (le dépôt lui-même : 2610 jetons pour 2000) ; un BACKLOG illisible rend trois lignes `NON-VERIFIABLE` (`backlog-ouverts`, `backlog-clos`, `backlog-entree`) ; compartiments illisibles : `state` `-` `-` `<budget>` `Ko` `NON-VERIFIABLE`.
- Région `vf-archive-writer` : quatre lignes d'awk modifiées en place, pas ajoutées (238 lignes, borne X9 inchangée).
- KL1 (`.gitignore` du dépôt source) rouge dans une copie d'arbre hors dépôt : propre à la copie, vert dans l'arbre.

## Suites jouées (sur la tête commitée, une fois)

- `test-check-method-budget.sh` : 594 PASS / 0 FAIL, 175 s
- `test-check-instruction-budget.sh` : 86 ok / 0 ko, 39 s
- Consommateurs sans modification : `test-guard-fin-de-geste.sh` 61 s, `test-check-divergence.sh` 2 s, `test-check-mission-exit.sh` 165 s, `test-check-mission-exit-ws.sh` 110 s, `test-fin-de-mandat.sh` 7 s, `test-check-baseline-arbitrage.sh` 60 s, `check-blueprints.sh`, étape CI `check-instruction-budget` extraite de `ci.yml` et rejouée (ligne « les sept bascules isolées sont prouvées » imprimée) 2 s : tous verts.
- Non rejoué : `check-gate-touche.sh` en local sur la branche (les quatre commits portent les `Gate-Touche:` des chemins touchés).

- Correction de sécurité après audit : `check-instruction-budget.sh` ne lance plus `resolve-deps.sh` pris sous `--path` (un lab piégé exécutait son propre script) ; le résolveur se résout depuis le dossier du gate, et absent à côté de lui le socle est `NON-VERIFIABLE`, dit (rc 2), jamais exécuté depuis le lab. Surcharge de test `VF_BUDGET_RESOLVER`. Preuves : TS1..TS3 (rouge sur `cacdd1b8`, vu d'abord) et mutant MS1 ; BOOT-4 et TI8 adaptés (écart voulu, dit). Aucun autre site du gate ne lance de script sous `$ROOT` ; le gate de méthode ne lance que des scripts voisins de lui. Suites : `test-check-instruction-budget.sh` 90 ok / 0 ko (26 s), `test-cockpit-jauges.sh` 60 PASS / 0 FAIL (32 s).
