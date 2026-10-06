---
phase: 46-moteur-gates-de-cl-ture-et-verdicts-hach-s
plan: 11
subsystem: planning-core
status: escalated
requirements: [CLOT-10]
tags: [armement, etape-5, rejeu-reel, escalade]
commit_list:
  - voir le journal git du commit « relevé du rejeu réel de l'étape 5 (46-11) »
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
  created:
    - .planning/workstreams/gouvernance/phases/VFDO-46-moteur-gates-de-cl-ture-et-verdicts-hach-s/46-REJEU-ETAPE-5.md
---

# Phase 46 Plan 11 : armement de l'étape 5 — rejeu joué, non armé (faux refus G4 et G7)

Réponse de la Tâche 1 : `rejeu-5-6-oui` — arbitrage Willy, AskUserQuestion session principale, 2026-10-06. Mise au repos de `~/BusinessFlow-Lab` : « La mission arrête les processus » — arbitrage Willy, AskUserQuestion session principale, 2026-10-06 (12 processus arrêtés : SIGTERM sur 9, SIGKILL sur les 3 `zsh` restants ; détail dans le relevé).

Banc : `COMPTE G3 faux-refus=0 faux-accept=0`, `COMPTE G4 faux-refus=0 faux-accept=0` (73 OK, 0 KO). Canary : 29 OK, 0 KO.

Rejeu réel joué (commit rejoué `99efa381`, une exécution, labs au repos avant et après) : `REJEU-ETAPE-5 faux-refus=349 faux-accept=0 refus-conforme-modele=196` ; `EMPREINTE-ARBRE-IDENTIQUE` pour chacun des deux labs, aucune divergence. G3 : 0/0 sur 52 cas. Les 349 faux refus : G4 343 (`SUMMARY.md` réels de `~/jarvis-keystone` sans `VERDICT.md`), G7 6 (créations de `.planning/config.json`).

Décision mécanique : condition « 0 faux refus » non remplie, donc `ARMEMENT_G3` et `ARMEMENT_G4` restent `observe` ; `ARMEMENT_G4P` inchangé ; aucun attendu nominatif ajouté (la décision sur le périmètre de G4 revient à Willy). Ligne d'escalade : `ESCALADE-WILLY ETAPE-5`.

Lignes `BORNE-LIVRABLES` : 8, au relevé ; aucune ligne `G4P-AGENT` (hors étape 5).
