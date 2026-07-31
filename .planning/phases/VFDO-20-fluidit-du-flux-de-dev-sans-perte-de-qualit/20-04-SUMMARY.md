---
phase: 20-fluidite-du-flux-de-dev-sans-perte-de-qualite
plan: 04
subsystem: design-orchestrator, business-pilot-bundle, content-bundle, growth-bundle
tags: [agents, security, disallowedtools, juges, frontmatter, runtime]

requires:
  - phase: "20-01"
    provides: "check-agents.sh connaît disallowedTools et porte la règle anti-régression memory: + tools: sans Write/Edit"
provides:
  - "Les 4 juges portent `disallowedTools: Write, Edit` — la barrière d'écriture devient une contrainte runtime au lieu d'une simple absence dans tools:"
  - "vf-design-judge dit le fait exact au lieu d'affirmer une barrière complète qu'il n'a pas (il conserve Bash)"
  - "Les 4 managers justifient le dispatch parallèle de leur juge par le mécanisme réel, plus par l'adjectif « read-only »"
affects: ["20-06 (doctrine de dispatch des managers)", "20-07 (ADR-060 et team-kernel.md citent le mécanisme)"]

tech-stack:
  added: []
  patterns:
    - "Barrière d'écriture posée par `disallowedTools` (contrainte runtime) plutôt que par omission dans `tools:` — l'omission est rouverte par `memory: project`"
    - "Une description d'agent énonce ce que le runtime pose réellement, jamais une garantie que la configuration ne produit pas"

key-files:
  created: []
  modified:
    - plugin/design-orchestrator/agents/vf-design-judge.md
    - plugin/business-pilot-bundle/agents/quality-gate-client.md
    - plugin/content-bundle/agents/content-clarity-judge.md
    - plugin/growth-bundle/agents/growth-quality-judge.md
    - plugin/design-orchestrator/agents/vf-design-manager.md
    - plugin/business-pilot-bundle/agents/vf-business-manager.md
    - plugin/content-bundle/agents/vf-content-manager.md
    - plugin/growth-bundle/agents/vf-growth-manager.md

key-decisions:
  - "D-06 tranché par le plan : `disallowedTools: Write, Edit` sur les 4 juges, sans toucher une seule ligne de check-agents.sh — le champ lui était déjà connu depuis 20-01"
  - "D-07 : `Bash` n'est PAS retiré de vf-design-judge (retrait non mandaté, l'outil sert à l'inspection du rendu). La décision est de documenter honnêtement l'angle mort, pas de le refermer par un geste hors mandat"
  - "Effet de bord assumé et écrit dans les 4 corps : un juge sous cette contrainte ne peut plus écrire son fichier de mémoire (il continue de le lire) — cohérent avec l'exigence de regard frais"
  - "Extension hors files_modified assumée : les 4 managers justifiaient le dispatch parallèle par « read-only », argument bâti sur du vide tant que la barrière n'existait pas. Le plan qui rend la barrière réelle doit corriger la justification qu'il rend enfin vraie"

patterns-established:
  - "Distinguer par écrit une barrière posée par le runtime (frontmatter) d'un engagement de prompt (retenue sur un canal ouvert) — appliqué au canal Bash de vf-design-judge"

requirements-completed: ["SC2"]

coverage:
  - id: D1
    description: "Les 4 juges portent `disallowedTools: Write, Edit` dans leur frontmatter"
    requirement: "SC2"
    verification:
      - kind: unit
        ref: "grep -c '^disallowedTools: Write, Edit' = 1 sur chacun des 4 juges"
        status: pass
    human_judgment: false
  - id: D2
    description: "Aucune ligne de check-agents.sh n'a été modifiée par ce plan, et le gate sort 0 en mode strict sur les 4 modules concernés"
    requirement: "SC2"
    verification:
      - kind: unit
        ref: "check-agents.sh --strict sur design-orchestrator, business-pilot-bundle, content-bundle, growth-bundle (rc=0 sur les 4)"
        status: pass
    human_judgment: false
  - id: D3
    description: "vf-design-judge est le SEUL des 4 à porter Bash ; sa description et son corps cessent d'affirmer une barrière d'écriture complète"
    requirement: "SC2"
    verification:
      - kind: unit
        ref: "tools: des 4 juges — vf-design-judge = 'Read, Bash, Glob, Grep', les 3 autres = 'Read, Glob, Grep'"
        status: pass
    human_judgment: false
  - id: D4
    description: "Les 4 managers citent le mécanisme réel de la barrière au lieu de l'adjectif « read-only » ; vf-design-manager dit le fait exact sans prétendre une barrière complète"
    requirement: "SC2"
    verification:
      - kind: manual_procedural
        ref: "Relecture des 4 justifications de dispatch parallèle (commit 8ec2f99)"
        status: pass
    human_judgment: true
    rationale: "Exactitude d'un texte de doctrine — pas de gate automatisable ; vérifié par relecture puis par la revue de mission."

duration: ~35min
completed: 2026-07-29
status: complete
---

# Phase 20 / Plan 04: Barrière d'écriture réelle des 4 juges Summary

**La barrière d'écriture des juges cesse d'être une absence dans `tools:` — rouverte
silencieusement au runtime par `memory: project` — pour devenir une contrainte posée par le
frontmatter, et les textes qui l'invoquaient cessent d'affirmer plus que ce que le runtime pose.**

## Performance

- **Duration:** ~35 min
- **Tasks:** 2 (barrière sur les 4 juges ; justifications des 4 managers)
- **Files modified:** 8 (4 juges + 4 managers)

## Accomplishments

- Les 4 juges (`vf-design-judge`, `quality-gate-client`, `content-clarity-judge`,
  `growth-quality-judge`) portent `disallowedTools: Write, Edit`. Le champ était **déjà connu de
  `check-agents.sh`** depuis 20-01 : la barrière devient réelle **sans qu'une seule ligne du gate
  n'ait été modifiée par ce plan**.
- `vf-design-judge`, seul des 4 à conserver `Bash`, cesse d'affirmer une barrière d'écriture
  complète. Sa description et son corps disent désormais le fait exact : outils d'édition
  interdits par frontmatter, canal shell conservé pour l'inspection du rendu, et retenue sur ce
  canal qui reste **un engagement de prompt, pas une barrière**.
- Les 3 juges de bundle ne portent pas `Bash` : leur lecture seule est **complète** après ce
  changement, et leurs descriptions n'avaient donc rien à retirer — aucune retouche cosmétique
  n'a été faite sur eux au-delà du champ ajouté.
- Effet de bord documenté dans les 4 corps : un juge sous cette contrainte **ne peut plus écrire
  son fichier de mémoire** (il continue de le lire). C'est un choix cohérent avec l'exigence de
  regard frais, pas un oubli.
- Les 4 managers justifiaient le dispatch parallèle de leur juge par son caractère « read-only » —
  un argument de sûreté de concurrence bâti sur du vide tant que la barrière n'était qu'une
  omission. Ils citent maintenant le mécanisme qui la rend vraie ; `vf-design-manager`, qui ne peut
  pas en dire autant sans mentir, énonce le fait exact.

## Task Commits

1. **Task 1: la barrière des 4 juges devient une contrainte runtime (D-06, D-07)** - `e270254` (fix)
2. **Task 2: les justifications de dispatch des 4 managers citent le mécanisme réel** - `8ec2f99` (fix)

## Files Created/Modified

- `plugin/design-orchestrator/agents/vf-design-judge.md` - `disallowedTools` + description et corps
  alignés sur ce que le runtime pose réellement (canal `Bash` conservé et nommé)
- `plugin/business-pilot-bundle/agents/quality-gate-client.md` - `disallowedTools` (+3 lignes)
- `plugin/content-bundle/agents/content-clarity-judge.md` - `disallowedTools` (+3 lignes)
- `plugin/growth-bundle/agents/growth-quality-judge.md` - `disallowedTools` (+3 lignes)
- `plugin/design-orchestrator/agents/vf-design-manager.md` - définition du « vert » : plus de
  « read-only » plat, le fait exact
- `plugin/business-pilot-bundle/agents/vf-business-manager.md` - justification du dispatch parallèle
- `plugin/content-bundle/agents/vf-content-manager.md` - justification du dispatch parallèle
- `plugin/growth-bundle/agents/vf-growth-manager.md` - justification du dispatch parallèle

## Decisions Made

- **`Bash` reste chez `vf-design-judge`.** Le retrait n'a pas été demandé et l'outil sert
  vraisemblablement à l'inspection du rendu. Documenter honnêtement l'angle mort plutôt que le
  refermer par un geste non mandaté.
- **Le périmètre a été étendu aux 4 managers**, hors `files_modified` du plan — voir Déviations.
- **Non-régression tenue** : les 4 agents conservent `tools:`, modèle, mémoire, marqueur de worker
  interne, rubrique de score et bloc typé de retour inchangés.

## Deviations from Plan

- **Extension à 4 fichiers de managers non listés dans `files_modified`.** Le plan ne couvrait que
  les 4 juges. Mais la justification du dispatch parallèle chez leurs managers reposait sur
  l'adjectif « read-only », c'est-à-dire sur la propriété que ce plan rend précisément vraie —
  laisser le texte en l'état aurait figé un argument de sûreté de concurrence sans fondement
  vérifiable. Extension jugée dans l'esprit du plan et validée par le manager de mission.

## Issues Encountered

- **Piège de séquence intercepté hors plan** (consigné au rapport de mission du 2026-07-29) : la
  règle de lint issue de 20-01 attrapait **6 agents, pas 4** — `vf-auditer` n'appartenait à aucun
  périmètre de plan. Traité pendant la mission.
- **SUMMARY rattrapé après coup.** Le travail a été livré et vérifié le 2026-07-29 (43 suites
  vertes, `check-agents --strict` vert sur les 6 dossiers d'agents), mais ce fichier n'a pas été
  écrit à ce moment-là. Rédigé le **2026-07-31** à partir des commits `e270254` / `8ec2f99` et
  d'une **re-vérification sur disque** (4/4 juges portent le champ, `tools:` conformes à D-07,
  gate `--strict` rc=0 sur les 4 modules). Aucune ré-exécution n'a été nécessaire.

## User Setup Required

Aucun.

## Next Phase Readiness

- La barrière étant réelle, `20-07` peut documenter le mécanisme dans `team-kernel.md` et la
  vitrine du module sans affirmer davantage que ce que la configuration pose (SC2 / D-08).
- Angle mort connu et assumé, à ne pas présenter comme fermé : le canal `Bash` de
  `vf-design-judge` reste ouvert ; la retenue sur ce canal est un engagement de prompt.
- Point ouvert hérité du rapport de mission : `guard-agent-write.sh` s'exécute **sans `--strict`**,
  donc un futur juge écrit sans barrière ne serait pas bloqué à l'écriture — traité depuis par le
  commit `447e75a`.

---
*Phase: 20-fluidite-du-flux-de-dev-sans-perte-de-qualite*
*Completed: 2026-07-29 (SUMMARY rattrapé le 2026-07-31)*
