---
phase: 06-dev-orchestrator-first-use
plan: 01
subsystem: dev-orchestrator
tags: [agent, first-use, garde-fou, routing, vf-init]
requires:
  - "dev-orchestrator/AGENT.md (agent routeur vibeflow-dev)"
  - "dev-orchestrator/skills/vf-init/SKILL.md (séquence d'init déléguée)"
provides:
  - "Garde-fou first-use dans AGENT.md : détection .planning absent + délégation vf-init avant routage d'un verbe de dev"
  - "Axe de test T7 régressif sur la présence du garde-fou first-use"
affects:
  - "dev-orchestrator/AGENT.md"
  - "dev-orchestrator/scripts/tests/test-dev-orchestrator.sh"
tech-stack:
  added: []
  patterns:
    - "grep-gate sur fichier filtré des commentaires (^#) pour éviter qu'un commentaire suffise"
    - "délégation skill (pas de duplication de séquence) entre agent et vf-init"
key-files:
  created: []
  modified:
    - "dev-orchestrator/AGENT.md"
    - "dev-orchestrator/scripts/tests/test-dev-orchestrator.sh"
decisions:
  - "Garde-fou placé AVANT la table de routage (point logique de décision router-vs-proposer)"
  - "Séquence d'init NON dupliquée : le garde-fou délègue au skill vf-init existant"
  - "Réaffirmation de BOOT-04 (new-project jamais seul) plutôt que redéfinition"
metrics:
  duration: "~1 min"
  completed: "2026-06-04"
requirements: [FIRST-01, FIRST-02]
---

# Phase 06 Plan 01 : Garde-fou first-use dev-orchestrator — Summary

Garde-fou de premier usage ajouté à l'agent `vibeflow-dev` : avant de router une intention de dev structurante, l'agent détecte un projet non GSD-initialisé via l'absence de `.planning/PROJECT.md` (`test -f`, FIRST-01) et bascule sur le skill `vf-init` pour proposer cartographie puis démarrage de projet sur confirmation — jamais `gsd-new-project` seul (FIRST-02, BOOT-04). Axe de test T7 ajouté pour rendre la régression détectable.

## Tasks réalisées

| Task | Nom | Commit | Fichiers |
| ---- | --- | ------ | -------- |
| 1 | Garde-fou first-use dans AGENT.md (détection `.planning` + délégation vf-init), ≤250L | `3db8acf` | `dev-orchestrator/AGENT.md` |
| 2 | Axe T7 du test module — garde-fou first-use présent dans AGENT.md | `3298305` | `dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` |

## Détail

### Task 1 — Garde-fou first-use (AGENT.md)
- Nouvelle sous-section `## Garde-fou premier usage (first-use)` placée AVANT la table de routage.
- (a) Détection FIRST-01 : critère `.planning/PROJECT.md`, commande `test -f .planning/PROJECT.md`.
- (b) Proposition FIRST-02 : délégation explicite au skill `vf-init` (cartographie si code → démarrage sur confirmation), jamais `gsd-new-project` seul ni en autonomie (BOOT-04 / Iron Law 4).
- Cohérence locale : puce ajoutée dans `## Garde-fous` + anti-pattern « router une intention de dev sur un projet non initialisé sans proposer l'init ».
- Table de routage (≥11 intentions/cibles) intacte — T3 reste verte.
- Densité : AGENT.md = 143L (≤250, T5). Vérif imprime `OK-AGENT 143L`.

### Task 2 — Axe T7 (test du module)
- T7 inséré APRÈS T6, AVANT le bilan `echo "== résultat ..."`.
- Réutilise `$GREP` (binaire système, immunisé alias zsh ugrep), `$AGENT_FILE` (résolu en tête source/lab), `ok()`/`ko()`.
- 4 conditions sur fichier filtré `'^#'` : `has_marker` (first-use/premier usage), `has_detect` (`.planning`), `has_vfinit` (`vf-init`), `has_noauto` (`new-project`). `ko()` reporte les flags 0/1 et casse le bilan `[ "$fail" -eq 0 ]` si le garde-fou disparaît.
- Bandeau d'en-tête mis à jour (ligne `#   T7 — ...`).
- Aucun check de densité dupliqué (T5 le porte déjà).

## Verification

- Task 1 : `OK-AGENT 143L` (≤250, garde-fou présent : `.planning`, `vf-init`, `new-project`, marker first-use).
- Task 2 : suite complète `bash test-dev-orchestrator.sh` → **13 OK / 0 KO / 0 SKIP**, exit 0. `OK-TEST T7 vert`. T1–T6 inchangés.
- Note runtime (assumée) : le routage conditionnel effectif (proposer l'init plutôt que router) reste de la doctrine d'agent ; le plan rend testable la PRÉSENCE du garde-fou (T7) et documente la commande de détection.

## Deviations from Plan

None - plan exécuté exactement comme écrit.

## Self-Check: PASSED

- FOUND: dev-orchestrator/AGENT.md (modifié, 143L)
- FOUND: dev-orchestrator/scripts/tests/test-dev-orchestrator.sh (modifié, T7 présent)
- FOUND: commit 3db8acf (Task 1)
- FOUND: commit 3298305 (Task 2)
</content>
</invoke>
