---
phase: VFDO-39-workstreams-partition-du-planning-et-collaboration-concurren
plan: 03
subsystem: ws-proof-mecanisme-d02-d06
tags: [d-08, d-02, d-03, d-06, clone-jetable, deux-workers-concurrents]
requires: ["39-01", "39-02"]
provides: [ws-proof-mecanisme-effet-filesystem, d02-declencheur-de-reprise, d06-veille-evenement]
affects: [.planning/STATE.md, .planning/ROADMAP.md]
tech-stack:
  added: []
  patterns: ["preuve par EFFET filesystem plutôt que par interception PATH (le shim est inerte sur ce poste)", "compartiment poubelle (sink) pour décorréler le défaut ambiant du compartiment testé", "peuplement du compartiment cible AVANT dispatch pour rendre l'empreinte discriminante"]
key-files:
  created: []
  modified:
    - .planning/STATE.md
    - .planning/ROADMAP.md
key-decisions:
  - "Preuve d'observance de --ws réalisée sur un clone jetable (mktemp, git clone --local --no-hardlinks de vibeflow-os), jamais sur le dépôt de travail réel — paradoxe D-01/D-02/D-03 honoré littéralement, aucune trace .planning/workstreams/ n'a existé sous le dépôt réel à aucun moment."
  - "Deux workers vf-coder dispatchés en parallèle (même tour, même CLAUDE_CODE_SESSION_ID parent) sur deux compartiments distincts (legacy, scratch), chacun avec GSD_SESSION_KEY préfixé inline (jamais export séparé — l'état exporté ne survit pas d'un appel Bash au suivant sur ce poste) et --ws explicite sur chaque appel, sans GSD_WORKSTREAM dans leur environnement."
  - "Compartiment sink créé juste après la migration pour absorber le défaut ambiant du moteur (setActiveWorkstream pointe vers le dernier workstream créé) ; scratch peuplé d'un repère unique (PART-99-ws-proof-marker) AVANT dispatch, pour que les trois sorties (legacy / scratch / sans-drapeau=sink) soient mutuellement distinctes."
  - "Le contrôle réellement porteur est la comparaison de chaque artefact worker contre la propre relecture --ws du contrôleur pour ce compartiment (byte-for-byte, modulo un saut de ligne final bénin ajouté par l'outil Write) — pas la comparaison à la sortie sans drapeau, qui n'est que corroborante et ne rougit ici que par coïncidence de forme."
  - "D-02 : déclencheur de reprise inscrit dans STATE.md § Decisions — condition de RAPPEL objective et datée (clôture du jalon fiabilite-v1.0 OU dispatch réel de ≥2 workers vf-* concurrents sur scopes disjoints), jamais un auto-déclenchement ; la partition elle-même reste un geste humain sur demande explicite."
  - "D-06 : veille datée sur ÉVÉNEMENT inscrite dans STATE.md — prochaine publication gsd-core au-delà de 1.13.0, re-mesure K2 en ré-exécutant le script d'ADR.md, jamais sur seuil chiffré figé."
requirements-completed: [PART-03, PART-07, PART-08, PART-09]
duration: "non tracé"
completed: "2026-09-10"
coverage:
  - deliverable: "Clone jetable partitionné, migration réelle intacte (files_moved 4/4), deux workers vf-coder concurrents passant --ws explicitement, prouvé par effet filesystem"
    verification:
      - kind: "command"
        ref: "bloc <verify> canonique de la Tâche 1 (clone auto-contenu) -> MIGRATION_AND_GATE_AND_TWO_WORKER_PROOF_OK"
        status: pass
      - kind: "manual"
        ref: "contrôleur : existence des deux artefacts, absence de fuite croisée, cmp byte-for-byte (modulo saut de ligne final) contre --ws legacy / --ws scratch, non-match contre le défaut sans-drapeau (sink)"
        status: pass
    human_judgment: false
  - deliverable: "Trois gates (check-workstream-pointer.sh, check-state-integrity.sh, check-divergence.sh) verts sur le clone, inchangés sur le dépôt réel non touché"
    verification:
      - kind: "command"
        ref: "GSD_WORKSTREAM=legacy check-workstream-pointer.sh --path $CLONE (rc=0) ; idem check-state-integrity.sh (rc=0) ; check-divergence.sh --path $CLONE (rc=0) ; mêmes trois gates --path vibeflow-os réel -> rc=3 / rc=0 / rc=3 (inchangé)"
        status: pass
    human_judgment: false
  - deliverable: "D-02 déclencheur de reprise daté + D-06 veille événement inscrits dans STATE.md ; ROADMAP.md confirme la ligne D-02 préexistante sans duplication"
    verification:
      - kind: "command"
        ref: "grep -c Déclencheur de reprise / Veille datée sur ÉVÉNEMENT .planning/STATE.md ; grep -c Partition réelle de...vibeflow-os (=1) / Confirmé par le plan 39-03 .planning/ROADMAP.md ; test -d .planning/workstreams (absent)"
        status: pass
    human_judgment: false
notes: >
  Cette preuve établit un mécanisme, pas un usage concurrent réel sur le dépôt vivant (D-03) — le
  clone est détruit, aucune trace partitionnée ne subsiste sur `vibeflow-os`. Aucune commande
  `gsd-tools state.*` invoquée ; STATE.md édité exclusivement via Edit scopé. Aucun `/gsd-ship`,
  PR, merge ou push. Aucune issue postée chez OpenGSD (aucun appel réseau). Le mismatch cmp initial
  entre chaque artefact worker et la relecture du contrôleur (1763 vs 1762 octets, 1765 vs 1764)
  provient uniquement d'un saut de ligne final que l'outil Write ajoute systématiquement aux
  fichiers .md — vérifié par comparaison normalisée (contenu strictement identique une fois ce
  saut de ligne neutralisé des deux côtés) ; ce n'est pas un indice d'omission de --ws.
---

# 39-03 — Clone jetable : preuve d'observance --ws (D-08), déclencheurs D-02/D-06

Deux tâches exécutées **inline**, sur mandat explicite du manager (pas de `gsd-execute-phase` —
il filtre par vague et aurait redispatché d'autres plans de cette phase déjà livrés).

## Tâche 1 — Clone, partition, deux workers concurrents, trois gates

1. Clone jetable créé sous `mktemp -d` (`git clone -q --local --no-hardlinks
   "$(git rev-parse --show-toplevel)" "$CLONE"`), jamais le dépôt de travail réel.
2. `workstream create scratch --migrate-name legacy` — migration confirmée : `files_moved`
   contient `ROADMAP.md`, `STATE.md`, `REQUIREMENTS.md`, `phases` (4/4, conforme à la recherche
   de cadrage §5).
3. `workstream create sink` (compartiment poubelle, jamais assigné à un worker) pour décorréler
   le défaut ambiant du moteur du compartiment `scratch` testé.
4. `scratch` peuplé d'un repère unique (`PART-99-ws-proof-marker` + `ROADMAP.md` d'une ligne)
   **avant** le dispatch des workers.
5. Empreintes MD5 mesurées mutuellement distinctes avant dispatch :
   - `--ws legacy` → `97640e1b708345333d891c7efb79d77a`
   - `--ws scratch` (peuplé) → `3de0fce2431674fe0e3576b6bb514041`
   - sans drapeau (résout `sink`, vide) → `926ec824ff4329d9af3d3b705a7bb7a6`
6. Deux `vf-coder` dispatchés en parallèle (même tour, cwd = clone) :
   - Worker A → compartiment `legacy`, `GSD_SESSION_KEY=ws-proof-A-legacy` préfixé inline,
     `--ws legacy` sur chaque appel, artefact écrit à
     `.planning/workstreams/legacy/.ws-proof-A.md`.
   - Worker B → compartiment `scratch`, `GSD_SESSION_KEY=ws-proof-B-scratch` préfixé inline,
     `--ws scratch` sur chaque appel, artefact écrit à
     `.planning/workstreams/scratch/.ws-proof-B.md`.
   - Ni l'un ni l'autre n'a reçu `GSD_WORKSTREAM` dans son environnement.
7. Contrôle du contrôleur (indépendant du transcript des workers) :
   - Les deux artefacts existent ; aucun n'a fui dans l'autre compartiment.
   - Recoupement byte-for-byte contre la propre relecture `--ws legacy` / `--ws scratch` du
     contrôleur : **match confirmé** (modulo un saut de ligne final systématiquement ajouté par
     l'outil Write — vérifié par comparaison normalisée, contenu JSON strictement identique).
   - Recoupement corroborant contre le rendu sans drapeau (`sink`, vide) : **aucun des deux
     artefacts ne matche** — le check porteur reste le recoupement `--ws` du point précédent.
8. Trois gates verts sur le clone (`GSD_WORKSTREAM=legacy` préfixé inline pour les deux premiers) :
   `check-workstream-pointer.sh` rc=0, `check-state-integrity.sh` rc=0, `check-divergence.sh`
   rc=0. Les mêmes trois gates, en lecture seule, sur le dépôt réel : rc=3, rc=0, rc=3 —
   inchangé par rapport à l'état avant cette phase.
9. Bloc `<verify>` canonique de la tâche (auto-contenu, propre clone) exécuté séparément :
   `MIGRATION_AND_GATE_AND_TWO_WORKER_PROOF_OK`.
10. Clone détruit (`rm -rf`) ; confirmé absent après coup.

## Tâche 2 — Déclencheurs D-02/D-06, confirmation ROADMAP

- `.planning/STATE.md` § Decisions : deux nouvelles entrées datées 2026-09-10 insérées **au-dessus**
  des quatre entrées 2026-09-09/2026-09-10 préexistantes (édition via `Edit` scopé, jamais
  `gsd-tools state.*`) — le déclencheur de reprise D-02 (condition de rappel objective et datée) et
  la veille datée sur événement D-06 (prochaine publication `gsd-core` > 1.13.0).
- `.planning/ROADMAP.md` § Phase 39 : la ligne de croisement D-02 existait déjà (posée par une
  passe de correction antérieure sur cette même phase) — confirmée présente exactement une fois
  (`grep -c` = 1), jamais dupliquée ; clause de confirmation ajoutée immédiatement après :
  « Confirmé par le plan 39-03 (§Task 2, 2026-09-10) — présence non dupliquée vérifiée. »
- Clone déjà détruit par la Tâche 1 ; reconfirmé absent.
- `.planning/workstreams/` absent du dépôt réel à la fin des deux tâches.

## Vérification finale

- `.planning/STATE.md` : 1171 → 1192 lignes (+21, deux entrées ajoutées), les quatre entrées
  2026-09-09/2026-09-10 préexistantes intactes et présentes (désormais précédées des deux
  nouvelles).
- Bloc `<verify>` Tâche 2 : `OK` (a≥1, b≥1, c=1, d≥1, leak=NO_LEAK).
