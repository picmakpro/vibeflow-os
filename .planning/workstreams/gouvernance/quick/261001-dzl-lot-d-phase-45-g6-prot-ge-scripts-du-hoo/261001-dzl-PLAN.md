---
quick_id: 261001-dzl
description: Lot D de la Phase 45 (nœud fix-45-D) — G6 protège les scripts du hook (Q-G6 = b) ; découplage de deux suites de l'état d'armement (Q-ARM)
base: d65a801
workstream: gouvernance
---

# Quick 261001-dzl — lot D, Phase 45

Décisions humaines portées par le mandat du manager (vf-dev-manager, 2026-10-01) — réponses de Willy, pas des choix d'agent :

- **Q-G6 = (b)** — Willy, AskUserQuestion session principale, 2026-10-01 : G6 protège les scripts du hook (`planning-hook.sh` et son canary `check-gates-alive.sh`)
  là où l'installeur les pose en scope projet (`<lab>/.claude/scripts/`) ; les réglages `.claude/settings*.json` deviennent une limite déclarée.
- **Q-ARM = oui** — Willy, AskUserQuestion session principale, 2026-09-30 : `test-planning-gates.sh` et `test-planning-hook-installed.sh` (et, sous la même
  autorisation, les suites couplées) deviennent indépendantes de l'état d'armement courant. Garde-fous : aucun cas supprimé, aucun mutant retiré,
  chaque cas modifié prouvé rouge sur son mutant avec la trace. AUCUN armement dans ce lot.

## Tâches

1. G6 (b) : `script_protege` dans `planning-hook.sh` (identité : realpath du parent comparé par `samefile`, nom en casefold, existant par `samefile` : lien dur, lien
   symbolique, casse, `..`, relatif) ; verdict G6 sur `.claude/scripts/<nom>`, dérogation nominative possible ; hors adhésion, silence (GATE-10).
   Tests rouge -> vert (R-G6-06 à R-G6-09, banc, R-INST-07/08, R-REJEU-10), mutants G6-SCRIPTS, G6-SCRIPT-RACINE, -CASEFOLD, -SAMEFILE, -ADHESION, -DEROG, REJEU-SCRIPTS-G6.
   Référence : limite (y) seulement.
2. Découplage : `copie_armee` (observe|armed), R-TABLE-03 reconstruit sur une incohérence vraie dans tout état (nouveau mutant TABLE-ORDRE-REFUS), mutants de la
   référence inversés au lieu d'être posés, scripts rejoués de `test-planning-hook-registered.sh` et hook frère de `test-rejeu-gates.sh` forcés à `observe`.
   Preuve d'indépendance : les cinq états (livré, G6+G5, +G1, +G7, +ROLE) rejoués sur des copies du dépôt dans le scratchpad, jamais commitées.

## Hors périmètre

STATE.md, ROADMAP.md, REQUIREMENTS.md ; toute constante `ARMEMENT_*` et `TABLE_ATTENDUE` du dépôt ; VERSION, CHANGELOG, README du module (le manager décide du bump).
