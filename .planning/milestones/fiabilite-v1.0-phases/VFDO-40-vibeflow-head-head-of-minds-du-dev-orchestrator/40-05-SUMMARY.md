---
phase: VFDO-40-vibeflow-head-head-of-minds-du-dev-orchestrator
plan: 05
subsystem: exec-workers
tags: [head-03, d-05, adr-029, adr-030, adr-044]
requires: ["40-02"]
provides: [emetteurs-preuves-e6]
affects: [plugin/dev-orchestrator/agents/vf-coder.md, plugin/dev-orchestrator/agents/vf-reviewer.md, plugin/dev-orchestrator/agents/vf-auditer.md]
tech-stack:
  added: []
  patterns: ["gabarit du précédent direct (paragraphe `verdicts` de vf-coder.md, section `## Retour` de vf-reviewer.md/vf-auditer.md) imité pour le nouveau paragraphe `preuves`", "diff purement additif en fin de fichier, aucune ligne existante réécrite"]
key-files:
  created: []
  modified:
    - plugin/dev-orchestrator/agents/vf-coder.md
    - plugin/dev-orchestrator/agents/vf-reviewer.md
    - plugin/dev-orchestrator/agents/vf-auditer.md
key-decisions:
  - "vf-coder.md : paragraphe `**\`preuves\`**` ajouté après le paragraphe `verdicts` existant (fin de fichier), renvoi nommé vers `mission-contracts.md §Contrat de preuves E6 (verdict → head)`. Verdict `recette` marqué `{\"verdict\": \"recette\", \"preuve\": \"amont\"}` par défaut (hook gsd-execute-phase jamais rejoué), triplet réel seulement si commande Bash personnellement capturée. Application littérale de D-05 aux gates techniques (arbitrage Samuel, option b) : une entrée `{\"verdict\": \"gate:<nom>\", \"preuve\": \"amont\"}` par sous-champ non `absent` de `verdicts` (code_review/nyquist/secure)."
  - "vf-reviewer.md et vf-auditer.md : même gabarit, verdict propre (`revue`/`audit`), triplet réel seulement si le worker a lui-même lancé la commande de vérification (Bash ou MCP), sinon `preuve: amont`."
  - "Interdits machine du plan-check tenus : aucune forme grasse `**\`gate\`**`/`**\`reprise\`**` introduite dans le nouveau paragraphe de vf-coder.md (comptage littéral = 1 chacune, avant ET après édition) ; ligne vide de séparation entre chaque nouveau paragraphe et le précédent ; aucune occurrence de `gsd-planner`/`gsd-executor` introduite (T29)."
requirements-completed: [HEAD-03]
duration: "non tracé"
completed: "2026-09-15"
coverage:
  - deliverable: "Paragraphe `preuves` dans vf-coder.md (verdict recette + gates techniques D-05)"
    verification:
      - kind: "command"
        ref: "awk (bloc `**\\`preuves\\`**`)|grep exit_code && grep -qi amont && grep mission-contracts.md && grep recette && grep 'gate:' — rouge avant édition (bloc absent), vert après"
        status: pass
    human_judgment: false
  - deliverable: "Paragraphe `preuves` dans vf-reviewer.md (verdict revue)"
    verification:
      - kind: "command"
        ref: "même sonde, témoins exit_code/amont/mission-contracts.md/revue — rouge avant, vert après"
        status: pass
    human_judgment: false
  - deliverable: "Paragraphe `preuves` dans vf-auditer.md (verdict audit)"
    verification:
      - kind: "command"
        ref: "même sonde, témoins exit_code/amont/mission-contracts.md/audit — rouge avant, vert après"
        status: pass
    human_judgment: false
  - deliverable: "Diff purement additif sur les trois fichiers, aucune ligne préexistante réécrite"
    verification:
      - kind: "command"
        ref: "BASE=$(git merge-base HEAD main); git diff --unified=0 \"$BASE\" -- <fichier> | tail -n +5 | grep -c '^-' = 0 pour les trois"
        status: pass
    human_judgment: false
  - deliverable: "Ancres `**\\`gate\\`**`/`**\\`reprise\\`**` de vf-coder.md non dupliquées"
    verification:
      - kind: "command"
        ref: "grep -oF '**\\`gate\\`**' | wc -l = 1 ; grep -oF '**\\`reprise\\`**' | wc -l = 1"
        status: pass
    human_judgment: false
  - deliverable: "ADR-029 tenu sur les trois fichiers"
    verification:
      - kind: "command"
        ref: "awk 'END{print NR}' ≤ 250 : vf-coder.md 108→122, vf-reviewer.md 69→79, vf-auditer.md 49→59"
        status: pass
    human_judgment: false
  - deliverable: "ADR-044 tenu sur les trois fichiers"
    verification:
      - kind: "command"
        ref: "bash plugin/conductor/scripts/check-agents.sh --strict --file <fichier> — exit=0 pour les trois (warnings préexistants inchangés, aucun nouveau)"
        status: pass
    human_judgment: false
  - deliverable: "Suite du module verte"
    verification:
      - kind: "command"
        ref: "bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh — 201 OK / 0 KO / 0 SKIP (identique avant/après)"
        status: pass
    human_judgment: false
notes: >
  Exécuté inline (mandat explicite : pas de gsd-execute-phase, lot L3 (40-04) tournant en parallèle
  sur des fichiers disjoints — aucune collision constatée). Trois commits atomiques par pathspec
  exact (jamais `git add -A` ni commit nu) : 6f91296 (vf-coder.md, +14), d25362e (vf-reviewer.md,
  +10), 9bde511 (vf-auditer.md, +10). Chaque `git show --stat` confirme un seul fichier par commit.
  Sonde `preuves` rejouée manuellement rouge AVANT édition (bloc vide constaté sur les trois
  fichiers, `BASE=$(git merge-base HEAD main)` = 8be3a0d) et verte APRÈS, sur les trois. Sonde
  d'ancre parasite (comptage littéral `**\`gate\`**`/`**\`reprise\`**` = 1 chacune) verte. Suite
  complète rejouée deux fois (avant modifications pour confirmer le rouge de la sonde dédiée,
  après les trois commits) : 201 OK / 0 KO les deux fois — aucune ancre structurelle de
  vf-coder.md (T24, T26, T29) heurtée. `check-agents.sh --strict --file` vert sur les trois,
  warnings pré-existants (« aucun skill câblé », « nom d'agent non résolu vf-reviewer ») inchangés,
  aucun nouveau warning introduit par l'édition. Arbre non suivi préexistant (.gsd/,
  .planning/state.json, .planning/MISSION-*.dag.json, .claude/agent-memory/…, ~23 entrées) ni
  commité ni nettoyé.
---

# 40-05 — Émetteurs du contrat de preuves E6 (lot L5, exec-workers)

Trois tâches exécutées inline, une par fichier, en parallèle du lot L3 (`40-04-PLAN.md`, le gate de
sortie E6) sur un périmètre de fichiers strictement disjoint. Détail des SHA :

- `6f91296` — Task 1 : paragraphe `**\`preuves\`**` dans `vf-coder.md` (verdict `recette` +
  application littérale de D-05 aux gates techniques `code_review`/`nyquist`/`secure`)
- `d25362e` — Task 2 : paragraphe `**\`preuves\`**` dans `vf-reviewer.md` (verdict `revue`)
- `9bde511` — Task 3 : paragraphe `**\`preuves\`**` dans `vf-auditer.md` (verdict `audit`)

Le contrat E6 posé par `40-02` a désormais trois émetteurs réels, au même format (tableau plat
`{verdict, commande, exit_code, sha}` ou substitution `{verdict, preuve: "amont"}`), une seule
voix (ADR-030) : les trois paragraphes renvoient nommément à `mission-contracts.md §Contrat de
preuves E6 (verdict → head)`, aucun ne redéfinit le format localement.

Aucun point nécessitant une décision ou l'attention de l'utilisateur — le plan a été suivi tel
quel, aucune déviation.
