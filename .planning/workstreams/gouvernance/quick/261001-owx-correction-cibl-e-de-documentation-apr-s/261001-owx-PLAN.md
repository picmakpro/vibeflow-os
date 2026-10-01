---
quick_id: 261001-owx
mode: quick-full (--validate, dégradé séquentiel : plan écrit par l'orchestrateur du lot, comme au lot F)
workstream: gouvernance
phase: 45
node: maj-45-10
base_head: 239df76d
must_haves:
  truths:
    - "scripts/check-machine-paths.sh rend rc=0 (aucun chemin absolu de machine dans le PLAN 261001-m8c)"
    - "README, modele-cycles.md, CHANGELOG v2.9.0 disent que G6, G5, G1, G7 et ROLE sont armés (refusent, fermés sur défaillance) et que seul G2 avertit"
    - "R-REFERENCE exige la limite (z) avec ses mots-clés SIGALRM, Alarm clock, faux refus ; aucun mot-clé existant affaibli"
    - "le message de succès de R-REFERENCE dit que la phrase « Aucun gate n'est armé » suit l'état d'armement"
    - "45-10-SUMMARY, 45-COUT-MIGRATION, 45-VALIDATION décrivent l'état armé, les faits datés restent datés"
  artifacts:
    - plugin/planning-core/README.md
    - plugin/planning-core/CHANGELOG.md
    - plugin/planning-core/references/modele-cycles.md
    - plugin/planning-core/scripts/tests/test-planning-gates.sh
  key_links:
    - "LIMITES_REFERENCE (test-planning-gates.sh) <-> lignes « - **limite (X)** » de modele-cycles.md"
---

# Quick 261001-owx — correction ciblée de documentation après l'armement (Phase 45)

Décisions : Q-ARM (Willy, AskUserQuestion session principale, 2026-09-30) ; Q-G6 = b (Willy, AskUserQuestion session principale, 2026-10-01).

<tasks>

<task type="auto">
  <name>Tâche 1 : régression de gate et revue de l'armement (F1, F3, F4, F6)</name>
  <files>.planning/workstreams/gouvernance/quick/261001-m8c-lot-f-45-f-mineurs-m1-m5-re-revue-lot-e/261001-m8c-PLAN.md, plugin/planning-core/README.md, plugin/planning-core/references/modele-cycles.md, plugin/planning-core/scripts/tests/test-planning-gates.sh</files>
  <action>Chemins du PLAN m8c rendus portables ; README à l'état armé ; « Armés à la livraison v2.9.0 » ; libellé de succès de R-REFERENCE (étiquette seulement).</action>
  <verify>bash scripts/check-machine-paths.sh : rc=0 ; VF_GATES_SECTIONS=reference sur test-planning-gates.sh : 0 KO</verify>
  <done>rc=0 ; libellé à jour</done>
</task>

<task type="auto">
  <name>Tâche 2 : limite (z), faux refus sous forte charge</name>
  <files>plugin/planning-core/references/modele-cycles.md, plugin/planning-core/scripts/tests/test-planning-gates.sh, plugin/planning-core/CHANGELOG.md</files>
  <action>Ligne « - **limite (z)** » après (y) ; entrée ("z", ("SIGALRM", "Alarm clock", "faux refus")) dans LIMITES_REFERENCE ; mention au CHANGELOG v2.9.0.</action>
  <verify>suite verte sur la vraie référence ; rouge (ECART limite (z) : mots-clés absents) sur une copie sans SIGALRM</verify>
  <done>trace rouge captée</done>
</task>

<task type="auto">
  <name>Tâche 3 : phrases périmées à l'état vrai</name>
  <files>plugin/planning-core/CHANGELOG.md, 45-10-SUMMARY.md, 45-COUT-MIGRATION.md, 45-VALIDATION.md</files>
  <action>Entrée v2.9.0 à l'état livré ; 45-10-SUMMARY : section datée « Armement en cascade (2026-10-01) », faits antérieurs datés ; COUT-MIGRATION et VALIDATION : rejeu final cité. SUMMARY et VERIFICATION des quick passées, 45-REJEU-*.md et PLAN laissés tels quels.</action>
  <verify>grep des formules périmées ; check-machine-paths.sh rc=0</verify>
  <done>aucune phrase d'état courant ne dit « observe » ou « aucun gate armé »</done>
</task>

</tasks>
