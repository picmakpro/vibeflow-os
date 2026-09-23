---
phase: VFDO-40-vibeflow-head-head-of-minds-du-dev-orchestrator
plan: 02
subsystem: mission-contracts-e6
tags: [head-03, d-05, d-13, d-12, d-14, d-06, adr-029, adr-030]
requires: ["40-01"]
provides: [contrat-preuves-e6, decompte-mission, vf-dev-manager-relais-e6]
affects: [plugin/dev-orchestrator/references/mission-contracts.md, plugin/dev-orchestrator/agents/vf-dev-manager.md]
tech-stack:
  added: []
  patterns: ["gabarit du précédent direct (§Contrat estimate/actuals) imité pour le nouveau §Contrat de preuves E6", "compensation à budget de lignes constant (5 lignes remplacées par 5 lignes) sur un fichier au plafond ADR-029"]
key-files:
  created: []
  modified:
    - plugin/dev-orchestrator/references/mission-contracts.md
    - plugin/dev-orchestrator/agents/vf-dev-manager.md
key-decisions:
  - "Section « ## Contrat de preuves E6 (verdict → head) » ajoutée dans mission-contracts.md, immédiatement avant § Rapport de mission : tableau plat `preuves` (verdict/commande/exit_code/sha), variante `preuve: amont` pour les verdicts relayés d'un hook moteur (jamais rejoués, D-05), trois règles non négociables (commande canonique D-12, sha = HEAD au moment du verdict D-15, relais verbatim), ancrage machine sur disque `## Preuves E6` (source unique lue par le gate de sortie E6), absence = indéterminé jamais conforme (D-06), conduite du head par renvoi à head-governance.md §3 (pas de recopie, ADR-030)."
  - "Trois lignes `Décompte (mission)` ajoutées au gabarit § Rapport de mission, juste après la ligne « Décompte (si bloqué) » existante : minds dispatchés (comptés sur les mandats émis), tours consommés (recopiés verbatim des blocs typés), gates rejoués E6 (0 à la remise, complété par le head après le gate de sortie)."
  - "vf-dev-manager.md : les cinq lignes du paragraphe de calibration (`**Calibration estimate:/actuals:**...`) remplacées par cinq lignes fusionnant calibration, verdicts, preuves E6 et décompte de mission sous un seul intitulé « Relais verbatim », avec les trois renvois de section vers mission-contracts.md. Édition strictement line-neutral (5 lignes → 5 lignes) : fichier resté à 250/250, marge ADR-029 toujours nulle. Diff confiné à ces cinq lignes (rtk proxy git diff -U0 vérifié), rien d'autre touché — ni le renommage de la ligne 3 du frontmatter (lot L1), ni mission-contracts.md (Task 1 de ce même plan), ni les deux dernières lignes de relâchement du verrou de driver (inchangées au mot et à la place)."
requirements-completed: [HEAD-03]
duration: "non tracé"
completed: "2026-09-15"
coverage:
  - deliverable: "Section `## Contrat de preuves E6 (verdict → head)` dans mission-contracts.md"
    verification:
      - kind: "command"
        ref: "grep -qxF '## Contrat de preuves E6 (verdict → head)' mission-contracts.md ; awk (section)|grep -qE '`?preuve`?[[:space:]:]+.*amont'"
        status: pass
    human_judgment: false
  - deliverable: "Trois lignes `Décompte (mission)` dans le gabarit § Rapport de mission"
    verification:
      - kind: "command"
        ref: "awk (section Rapport de mission)|grep -c 'Décompte (mission)' = 3"
        status: pass
    human_judgment: false
  - deliverable: "vf-dev-manager.md relaie E6 et le décompte, ≤ 250 lignes, ancre de verrou et mot verdicts intacts"
    verification:
      - kind: "command"
        ref: "awk 'END{print NR}' = 250 (≤250) ; awk(section)|grep 'driver-lock.sh release' ; awk(section)|grep 'Preuves E6' ; grep -c verdicts = 3 (>2) ; grep mission-contracts présent"
        status: pass
    human_judgment: false
  - deliverable: "Suite du module verte"
    verification:
      - kind: "command"
        ref: "bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh"
        status: pass
    human_judgment: false
  - deliverable: "Gate check-capability-activation.sh vert"
    verification:
      - kind: "command"
        ref: "bash plugin/dev-orchestrator/scripts/check-capability-activation.sh"
        status: pass
    human_judgment: false
notes: >
  Exécuté inline (mandat explicite : pas de gsd-execute-phase, lot L4 (plan 40-03) tournant en
  parallèle sur des fichiers disjoints — confirmé au commit de Task 1 : le worker voisin avait déjà
  posé fca953c (head-governance.md + _index.md) entre-temps, sans collision). Compte de lignes de
  vf-dev-manager.md : 250 avant édition, 250 après (compensation stricte, aucune ligne nette
  ajoutée). Les deux <verify> `bash test-dev-orchestrator.sh` (Task 1 et Task 2) et les quatre
  <automated> ciblés ont tous été rejoués après chaque tâche : 201 OK / 0 KO / 0 SKIP les deux fois,
  T35 (d) annonçant marge 0, T30-C2 et T9 toujours verts. mission-flow.md non touché (absent de
  files_modified, kernel intact). Commits scopés par pathspec exact, jamais `git add -A` ni commit
  nu — arbre non suivi préexistant (.gsd/, .planning/state.json, .planning/MISSION-*.dag.json,
  .claude/agent-memory/…) ni commité ni nettoyé.
---

# 40-02 — Contrat de preuves E6 et décompte de mission (lot L2, exec-e6)

Deux tâches exécutées inline. Détail des SHA :

- `4c5a9c1` — Tâche 1 : section `## Contrat de preuves E6 (verdict → head)` + trois lignes
  `Décompte (mission)` dans `mission-contracts.md`
- `3c36ad8` — Tâche 2 : relais E6 dans `vf-dev-manager.md`, budget de lignes constant (250/250)

Ce plan pose le CONTRAT (format, règles, ancrage disque) mais ne câble aucun ÉMETTEUR : aucun
worker (`vf-coder`, `vf-reviewer`, `vf-auditer`) ne produit encore le triplet
`{commande, exit_code, sha}` dans son bloc typé à l'issue de ce plan — c'est le lot `40-05`
(vague 3, `depends_on: ["40-02"]`) qui les câble, au format défini ici.
