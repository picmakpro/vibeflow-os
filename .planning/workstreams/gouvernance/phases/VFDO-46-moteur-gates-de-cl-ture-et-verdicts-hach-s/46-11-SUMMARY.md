---
phase: 46-moteur-gates-de-cl-ture-et-verdicts-hach-s
plan: 11
subsystem: planning-core
status: complete
requirements: [CLOT-10]
tags: [armement, etape-5, rejeu-reel, scission, g3-arme]
commit_list:
  - 69961c23 — relevé du rejeu réel de l'étape 5 (46-11)
  - b703d73d — armement de G3 seul, étape 5 scindée
estimate:
  tokens: 110000
  raw_tokens: 110000
  tasks: 2
  confidence: low
actuals:
  tasks: 2
  note: "tâche 1 tranchée en amont ; tâche 2 menée jusqu'à la décision mécanique (non armé) ; tokens non mesurés (aucun diff de code, seulement deux fichiers de planning)"
verdicts:
  code_review: absent
  nyquist: absent
  secure: absent
key-files:
  modified:
    - plugin/planning-core/scripts/planning-hook.sh
    - plugin/planning-core/scripts/tests/test-planning-gates.sh
    - plugin/planning-core/references/modele-cycles.md
  created:
    - .planning/workstreams/gouvernance/phases/VFDO-46-moteur-gates-de-cl-ture-et-verdicts-hach-s/46-REJEU-ETAPE-5.md
---

# Phase 46 Plan 11 : armement de l'étape 5 — rejeu joué, non armé (faux refus G4 et G7)

Réponse de la Tâche 1 : `rejeu-5-6-oui` — arbitrage Willy, AskUserQuestion session principale, 2026-10-06. Mise au repos de `~/BusinessFlow-Lab` : « La mission arrête les processus » — arbitrage Willy, AskUserQuestion session principale, 2026-10-06 (12 processus arrêtés : SIGTERM sur 9, SIGKILL sur les 3 `zsh` restants ; détail dans le relevé).

Banc : `COMPTE G3 faux-refus=0 faux-accept=0`, `COMPTE G4 faux-refus=0 faux-accept=0` (73 OK, 0 KO). Canary : 29 OK, 0 KO.

Rejeu réel joué (commit rejoué `99efa381`, une exécution, labs au repos avant et après) : `REJEU-ETAPE-5 faux-refus=349 faux-accept=0 refus-conforme-modele=196` ; `EMPREINTE-ARBRE-IDENTIQUE` pour chacun des deux labs, aucune divergence. G3 : 0/0 sur 52 cas. Les 349 faux refus : G4 343 (`SUMMARY.md` réels de `~/jarvis-keystone` sans `VERDICT.md`), G7 6 (créations de `.planning/config.json`).

Décision mécanique : condition « 0 faux refus » non remplie, donc `ARMEMENT_G3` et `ARMEMENT_G4` restent `observe` ; `ARMEMENT_G4P` inchangé ; aucun attendu nominatif ajouté (la décision sur le périmètre de G4 revient à Willy). Ligne d'escalade : `ESCALADE-WILLY ETAPE-5`.

Lignes `BORNE-LIVRABLES` : 8, au relevé ; aucune ligne `G4P-AGENT` (hors étape 5).

## État final — étape 5 scindée, G3 armé seul

Décision humaine : étape 5 → « (c) Armer G3 seul (Recommandé) » — arbitrage Willy, AskUserQuestion session principale, 2026-10-06. Commit d'armement `b703d73d` : `ARMEMENT_G3` vaut `armed`, `ARMEMENT_G4` et `ARMEMENT_G4P` restent `observe`. La table de `modele-cycles.md` et `TABLE_ATTENDUE` suivent ; la limite (bp) nomme le cas reporté (343 `SUMMARY.md` de `~/jarvis-keystone` sans `VERDICT.md`, G4 en observation).

**Déviation** : le plan arme G3 et G4 d'un seul geste (P46-D-11, étape 5 unique, garde `G3 == G4` dans `armement_valide`) ; l'arbitrage scinde l'étape en 5a (G3, armée) et 5b (G4, observation). `armement_valide` accepte désormais « G3 armé, G4 en observation », refuse G4 armé sans G3, G4P armé sans G3 ET G4, tout désordre de 1 à 4 ; R-TABLE-02/04 réécrits, mutant `ARMEMENT-G3-G4` tué (R-TABLE-04 rougit), R-CANG-G3-02 rejoue l'état livré. Suites : planning-gates 497/0 (804 s sous charge, 497 s au premier passage), hook-installed 29/0, cloture-gates 73/0, hook-registered 113/0 (1013 s), rejeu-gates 100/0, d1-surveillance 45/0, g4p-sortie-brute 19/0, juges-canary 14/0.

Reste hors de ce mandat : Tâche 3 de 46-12 (VERSION, CHANGELOG, README du module).
