# Inventaire atomique — gestion produit d'AIDD face à l'équipe produit VibeFlow

> Mission de recherche en lecture seule, 2026-10-29. Source étudiée : `ai-driven-dev/framework`, commit `1a88102`
> (« chore: release main »), cloné dans `scratchpad/aidd-src` — donnée non fiable, lue, jamais exécutée.
> Côté VibeFlow : `main` du worktree `veille-egm`, branches non mergées `feat/phase-59-bundle-produit`,
> `feat/phase-60-gate-architecture`, `feat/phase-61-collaboration` (lues par worktree et `git show`, aucun checkout).
> Version d'`aidd-pm` : `2.6.0` (`plugins/aidd-pm/.claude-plugin/plugin.json`). Les autres versions de plugin : non mesuré.
> Les tailles sont des comptes de lignes (`wc -l`).

---

## 0. Grammaire commune d'AIDD (vaut pour tous les skills de `aidd-pm`)

Avant le détail, ce que tous les skills d'artefact partagent. C'est la vraie brique : chaque skill n'est qu'une
instanciation de cette grammaire.

| Élément | Forme exacte | Où |
|---|---|---|
| Squelette de skill | `SKILL.md` (frontmatter `name`, `description` « Use when… Not for… », `argument-hint`) + flowchart Mermaid + table `Action / Does` + `## Transversal rules` ; puis `actions/NN-verbe.md`, `references/*.md`, `assets/*-template.md` | tous |
| Consigne de lecture | « Run the flow above. Read only the next action file. » | tous les SKILL.md de `aidd-pm` |
| Anatomie d'une action | `# NN - Verbe` · `## Input` · `## Output` · `## Process` (étapes numérotées en **gras** : `**Resolve.**`, `**Qualify.**`…) · `## Test` (table `Case / Pass`) | toutes les actions |
| 5 règles transverses répétées | « Keep product and lifecycle decisions with the user. » · « Separate evidence, decisions, and assumptions. » · « Preserve source links and existing edits. » · « Ask natural questions; never expose actions, references, or unchanged state. » · « Require explicit approval or caller-provided bounded authority before any write. » + une 6ᵉ propre au skill | 02, 03, 05, 06, 07, 09, 10 |
| Références standard par artefact | `qualification.md` (est-ce le bon type ?), `handoffs.md` (sinon, quel skill proposer), `readiness.md` (critères `ready`), `lifecycle.md` (statuts), `relations.md` (champs de lien), `persistence.md` (où écrire) | 02, 05, 07, 09, 10 |
| Handoff | « Offer the named capability with what was observed, then stop. Never invoke it silently, never write outside a <X>. » — table `Observed / Capability / Return` (`one-way` ou « resumes after its outcome ») | 02, 06, 07, 09, 10 |
| Reçu d'écriture | « report each stable identity, changed fields as `before -> after`, affected relations, and the verification result. For a draft or no-write result, state that no persisted change occurred. » | finalize de 02, 05, 06, 07, 09, 10 |
| Relations | « Store each relation once, on its owner; `related_to` on the artifact whose path sorts first. Inverse links are never stored: `children`, `blocked_by`, `superseded_by`. Readers derive them. » | relations.md de 02, 05, 07, 09, 10 |
| Statut | `status` en frontmatter, jamais dans le corps ; table `Status / Meaning / May move to` ; terminal `cancelled` exige `## Cancellation` | lifecycle.md |
| Changement de sens | « A changed need/outcome/mismatch creates a new X and preserves the completed one » + champ `supersedes` | lifecycle.md |
| Cascade de statut | « A <X> that changes state decides nothing for its parent… propose their fate with it. » / « Closing every child does not complete an Epic without its success evidence. » | lifecycle.md 02, 07, 09, 10 |
| Support | « Markdown is the only support these skills write today. Naming another one is a project's own integration. » ; sans cible : « ask session or Markdown » | persistence.md |
| Chemins | `aidd_docs/backlog/{epics,stories,tasks,spikes,defects}/<slug>.md` (titre en kebab-case) ; `aidd_docs/product/<product-slug>.md` ; `aidd_docs/tasks/<yyyy_mm>/<yyyy_mm_dd>_<slug>/{spec.md,brainstorm.md,plan.md,qa.md}` ; PRD : `aidd_docs/tasks/<yyyy_mm>/<yyyy_mm_dd>-<feature_name>-prd.md` (tiret, pas underscore — incohérence interne) | persistence.md, actions |

---

## 1. Inventaire skill par skill

### 1.1 `aidd-pm` [4.1] `01-ticket-info` — 66 lignes au total

| Fichier | Lignes |
|---|---|
| `SKILL.md` | 20 |
| `actions/01-ticket-info.md` | 24 |
| `assets/ticket-template.md` | 12 |
| `references/tool-detection.md` | 10 |

- **Déclencheur** : « see, show, or look up a ticket's details » ; `argument-hint: ticket`. Not for : créer, commenter, transitionner, réassigner.
- **Entrée** : id ou URL optionnel ; sinon « auto-detect it from the current branch name ».
- **Sortie** : affichage seul (aucun fichier). Gabarit : `# <Title>` + table `Status | Assignee | Priority | URL` + description.
- **Étapes** : `Resolve` (outil + id via tool-detection) → `Query` → `Display`.
- **Détection d'outil**, dans l'ordre : project memory → repo configuration → environment. Id formaté « per the project's ticketing convention (prefix, separator, casing) ».
- **Liens** : appelé par `aidd-orchestrator:01-sdlc` zone Frame (`/aidd-pm:01-ticket-info`) quand la source référence un ticket.
- **Point d'arrêt humain** : aucun (lecture seule).

### 1.2 `aidd-pm` [4.2] `02-user-stories` — 352 lignes

| Fichier | Lignes |
|---|---|
| `SKILL.md` | 41 |
| `actions/01-frame.md` 27 · `02-slice.md` 28 · `03-write.md` 30 · `04-assess.md` 30 · `05-estimation.md` 25 · `06-order.md` 28 · `07-finalize.md` 34 | 202 |
| `assets/user-story-template.md` | 18 |
| `references/estimation.md` 9 · `handoffs.md` 11 · `lifecycle.md` 15 · `ordering.md` 14 · `persistence.md` 17 · `qualification.md` 9 · `readiness.md` 14 · `relations.md` 17 · `slicing.md` 14 | 120 |

- **Déclencheur** : « slice, write, assess, order, or persist Stories » ; `argument-hint: request | epic`. Not for : Epics, implémentation.
- **Entrées** : request, Product Brief, PRD, Epic, ou Stories existantes ; « already persisted » saute directement à `finalize`.
- **Flux** : `frame → slice → write → assess → estimation → order → finalize` ; boucles `assess -reshape-> slice`, `order -reslice-> slice`, `finalize -revise-> write`.
- **6ᵉ règle** : « Draft only after actor, need, and outcome are explicit in the source or confirmed. »
- **Étapes et arrêts humains** :
  1. `frame` : Resolve / Qualify / Bound / **Confirm** (« Ask one question and wait when any missing value can change the Story »).
  2. `slice` : Slice / Relate / Classify / **Confirm** seulement si des découpes alternatives changent la valeur livrée.
  3. `write` : State / Accept (« use examples or Gherkin only when clearer ») / Relate / Clean / **Feedback** (« complete set shown; no write; response ends with one open question »).
  4. `assess` : Quality (readiness) / Unknowns / Reshape / Status (`ready` seulement si tout passe, sinon `proposed`) / Feedback.
  5. `estimation` : seulement si le projet a une échelle ; « Record only user- or team-confirmed estimates ».
  6. `order` : **Decide** par l'utilisateur ; « Never manufacture a numeric score ».
  7. `finalize` : Resolve / Status / **Authorize** / Link / Write / Verify / Report.
- **Gabarit** (`user-story-template.md`) : frontmatter `type: story`, `status: proposed` ; `# Story: <title>` ; `**As** <actor>` / `**I want** <need>` / `**So that** <outcome>` ; `## Acceptance` (puces « observable condition ») ; `## Cancellation`.
- **Vocabulaire** : statuts `proposed → ready → in-progress → done | cancelled` ; champs `source`, `parent` (Epic), `depends_on`, `related_to`, `supersedes`, `order`, `estimate` — « A Story carries no other field ».
- **Readiness = INVEST** (table Independent / Negotiable / Valuable / Estimable / Small / Testable) ; « Acceptance is the Story's own proof… Quality gates the whole team applies belong to the Definition of Done, never here. » ; « a blocking unknown becomes a Spike ».
- **Slicing** : user workflow / business rules / data variation / operations CRUD / learning-only → Spike / several outcomes → Epics ; « Avoid splitting by frontend, backend, database, component, service, or delivery phase. »
- **Ordering** : signaux admis (predecessor, blocker, earlier user value, urgent cost, decisive learning) ; « unsupported value or urgency | has no ordering weight ».
- **Handoffs** : plusieurs tranches → Epic ; sans valeur indépendante → Task ; mismatch → Defect ; incertitude → Spike (reprise après).
- **Persistance** : `aidd_docs/backlog/stories/<slug>.md`, un fichier par Story.

### 1.3 `aidd-pm` [4.3] `03-prd` — 118 lignes

| Fichier | Lignes |
|---|---|
| `SKILL.md` | 30 |
| `actions/01-draft.md` 27 · `02-finalize.md` 24 | 51 |
| `assets/prd-template.md` | 37 |

- **Déclencheur** : « draft or generate a PRD or product requirements » ; `argument-hint: need | brainstorm`. Not for : user stories, plan technique.
- **6ᵉ règle** : « State what and why; never a technical plan or user stories. »
- **Étapes** : `draft` (Parse / Fill / **Show** « wait for explicit approval » / Revise) → `finalize` (Save / Verify).
- **Test clé** : « Solution detail proposed | none: no tech-stack, data-model, architecture section, or code ».
- **Sortie** : `aidd_docs/tasks/<yyyy_mm>/<yyyy_mm_dd>-<feature_name>-prd.md`.
- **Gabarit, 8 sections** : `# [Project name]` + pitch ; `## Overview` ; `## Problem Statement` ; `## Goals` (« observable and measurable ») ; `## Non-Goals` ; `## User Stories` (« As a [persona], I want [goal], so that [reason] ») ; `## Acceptance Criteria` (« observable and user-facing. Behavior, not code ») ; `## Dependencies` ; `## Open Questions`. Pas de frontmatter.
- **Liens** : source admissible d'Epic, de Stories, de Spec (`04-spec` « lift its target, hard constraints, non-goals and done-when »).

### 1.4 `aidd-pm` [4.4] `04-spec` — 184 lignes

| Fichier | Lignes |
|---|---|
| `SKILL.md` | 29 |
| `actions/01-build.md` 29 · `02-refine.md` 30 | 59 |
| `assets/spec-template.md` 41 · `assets/spec-validator.yml` 48 | 89 |
| `references/tbd-marker.md` | 7 |

- **Déclencheur** : « draft or refine a spec » ; `argument-hint: request | prd | spec`. Not for : code, PRD complet, « changing a locked spec ».
- **Règles** : « Never invent; mark every gap instead of guessing. » · « Never explore the codebase. » · « Hold intent, never implementation: solution-agnostic, no how, few acceptance criteria. » · « Immutable once validated: never rewrite a locked spec. »
- **`build`** : Qualify (trop vague → une question, pas d'écriture) / Source / Gaps / Check / Write `aidd_docs/tasks/<yyyy_mm>/<yyyy_mm_dd>_<slug>/spec.md` / Return (chemin + gaps).
- **`refine`** : Map finding→section / Rewrite en place / Gaps (`None` quand vide) / Check / Verify (`before -> after`).
- **Gabarit** (ordre figé : « never add, rename, or reorder one ») : `## Target` (une phrase vérifiable) · `## Hard constraints` · `## Non-goals` · `## Done-when` (« The outcome, never the command that checks it ») · `## Open Questions` · `## Stakeholders` (optionnel : Decider / Owner / Consumer) · `## Context` (optionnel, « Link out, never restate »).
- **Validateur** (`spec-validator.yml`) : critères pondérés `target` 25, `hard_constraints` 20, `non_goals` 20, `done_when` 25, `open_questions` 0 (requis), `stakeholders` 5, `context` 5 ; `hard_thresholds` → `invalid` : `any_required_unfulfilled`, `target_unclear_or_multiple_targets`, `done_when_unverifiable`, `contains_implementation_details`, `open_questions_outside_their_section` ; `pass_threshold: 90`. Qui l'exécute : non mesuré (aucune action ne le cite ; probablement le checker de 03-check).
- **Marqueur** : `TBD: <precise question>` ; « Every gap goes to the template's open questions section, once, and to no other section. »
- **Liens** : appelé par `01-sdlc` Frame (`/aidd-pm:04-spec`) ; produit le `$contract` remis à `aidd-dev:01-plan`.

### 1.5 `aidd-pm` [4.5] `05-spike` — 255 lignes

| Fichier | Lignes |
|---|---|
| `SKILL.md` | 36 |
| `actions/01-create.md` 32 · `02-investigate.md` 26 · `03-conclude.md` 29 | 87 |
| `assets/spike-template.md` | 39 |
| `references/capabilities.md` 12 · `investigation.md` 13 · `lifecycle.md` 12 · `persistence.md` 16 · `qualification.md` 14 · `relations.md` 15 | 82 |

- **Déclencheur** : « frame, investigate, resume, or conclude » une incertitude bloquant estimation, faisabilité ou design ; `argument-hint: question | spike`.
- **6ᵉ règle** : « Bound the question; never answer beyond its stop condition. »
- **Flux** : `create` → (`save for later` → done | `investigate now` → `investigate` → `conclude`) ; `inconclusive` reboucle.
- **Gabarit** : frontmatter `type: spike`, `status: open` ; `## Question` · `## Decision` (ce que la réponse débloque) · `## Bounds` (`Evidence needed:` / `Stop when:`) · `## Investigation` (table `Attempt | Evidence | Result`) · `## Outcome` (`Result` / `Confidence` / `Remaining uncertainty`) · `## Follow-up` · `## Cancellation`.
- **Statuts** : `open → in-progress → blocked | resolved | inconclusive | cancelled` ; `inconclusive → in-progress` « with a new path ».
- **Qualification** : pas de spike si la question ne peut changer « estimation, feasibility, design, decomposition, or material-risk handling », si répondable dans l'échange, si « routine implementation or general research ».
- **Investigation** : « Bound research by decisive evidence, not elapsed time » ; chaque essai consigne méthode, source, résultat ; « retries differ ».
- **Capabilities** : délègue par effet (« Find a capability by the outcome it must produce. Invoke it; never copy or simulate it ») — discovery (→ `01-brainstorm`), fact-checking (→ `04-fact-check`), challenge (→ `02-challenge`).
- **Relations** : `source`, `parents` (pluriel : Epics/Stories/Tasks bloqués), `depends_on`, `related_to`, `supersedes` ; « holds neither `order` nor `estimate` ».
- **Persistance** : `aidd_docs/backlog/spikes/<slug>.md`.

### 1.6 `aidd-pm` [4.6] `06-product-brief` — 305 lignes

| Fichier | Lignes |
|---|---|
| `SKILL.md` | 43 |
| `actions/01-frame.md` 29 · `02-discover.md` 30 · `03-visualize.md` 25 · `04-shape.md` 28 · `05-finalize.md` 33 | 145 |
| `assets/product-brief.md` | 47 |
| `references/brief-quality.md` 10 · `evidence.md` 18 · `handoffs.md` 11 · `persistence.md` 11 · `techniques.md` 12 · `visuals.md` 8 | 70 |

- **Déclencheur** : « frame or revisit a product opportunity and how it will be validated » ; `argument-hint: idea | product`. Not for : exigences, design technique, planning.
- **6ᵉ règle** : « Frame the opportunity; never write requirements. »
- **Flux** : `frame → discover → (visualize) → shape → finalize` ; boucles `shape -evidence gap-> discover`, `finalize -learn more-> discover / -change visual-> visualize / -revise brief-> shape`.
- **Arrêts humains** : `frame` Resolve (« otherwise ask for the idea and wait ») + Confirm ; `discover` **Probe** (« Ask one question about the highest-impact gap and wait ») en boucle tant qu'un gap conséquent non accepté demeure ; `visualize` Show+wait ; `shape` Show sans persister ; `finalize` Authorize (« Without persistence authority, ask session or persist and wait »).
- **Gabarit** : frontmatter `objective: "<one sentence>"`, `revision: current` ; `# Product Brief: <product>` ; `## Opportunity` · `## Audience and Context` · `## Product Bet` · `## Evidence and Assumptions` (table `Claim | Status | Basis or next check`, statut ∈ decision/evidence/assumption) · `## Boundaries` (`Addresses:` / `Leaves out:`) · `## Success` (« earned value metric ») · `## Validation and Feedback` · `## Product View` · `## Open Decisions`.
- **Qualité** (`brief-quality.md`) : Coherence (« one falsifiable claim »), Boundary (« stays outside requirements »), Success, Validation (« targets the riskiest assumption »), Feedback (« a post-use signal can change a product decision »), Decisions.
- **Preuves** (`evidence.md`) : table source → peut établir / ne peut pas établir (conversation : intention, pas comportement observé ; code : comportement implémenté, pas motivation…) ; « Untested greenfield claim → assumption » ; « date is not evidence ».
- **Techniques** : JTBD, behavioral personas, value proposition, North Star, opportunity mapping, journey mapping — « only when it resolves a live uncertainty ».
- **Visuels** : une seule vue (table compacte, Mermaid, wireframe ASCII), « no new claim ».
- **Persistance** : `aidd_docs/product/<product-slug>.md` ; remplacement = nouveau fichier `current` + `supersedes`, ancien → `revision: superseded`.
- **Handoffs** : exigences d'un produit arrêté → « a requirements capability » (PRD) ; plusieurs tranches → Epic (« the brief stays its goal ») ; un comportement → User Story ; mismatch → Defect.

### 1.7 `aidd-pm` [4.7] `07-epic` — 247 lignes

| Fichier | Lignes |
|---|---|
| `SKILL.md` | 35 |
| `actions/01-shape.md` 30 · `02-review.md` 29 · `03-finalize.md` 33 | 92 |
| `assets/epic-template.md` | 31 |
| `references/handoffs.md` 13 · `lifecycle.md` 15 · `persistence.md` 20 · `qualification.md` 6 · `readiness.md` 17 · `relations.md` 19 | 90 |

- **Déclencheur** : « frame, review, resume, or persist an Epic » ; `argument-hint: request | epic`. 6ᵉ règle : « Stay at outcome level; do not propose child slices or implementation. »
- **Flux** : `shape → review → finalize` (+ boucles revise).
- **`shape`** : Gap (« highest-consequence unknown… Do not fill it by inference ») / **Question** (« one focused open question… Offer options only when the user needs anchors, with no unsupported default ») / Shape / Feedback.
- **`review`** : Compare (doublon/chevauchement) / Assess (readiness) / Challenge / **Route** (l'utilisateur choisit revision, finalisation, handoff) — aucune écriture.
- **Gabarit** : `type: epic`, `status: proposed` ; `# Epic: <outcome>` ; `## Context and Value` · `## Boundaries` (`Includes` / `Excludes`) · `## Success Evidence` · `## Dependencies and Unknowns` (table `Item | Kind | Handling`, kind ∈ dependency/assumption/decision/spike) · `## Cancellation`.
- **Readiness** : Outcome / Goal (lien Product Brief, ou absent) / Context / Boundaries / Success / Relations / Unknowns (« accepted, deferred, or assigned a Spike ») ; « An assumption is accepted once it is stated to the user and left uncontradicted ».
- **Statuts** : `ready` = « outcome and bounds support decomposition » ; `done` = « success evidence confirms the outcome ».
- **Relations** : `source`, `goal` (Product Brief, « outside the backlog »), `depends_on`, `related_to`, `supersedes`, `order` (« across the Epic set »), `estimate` ; « It holds no `parent`: children identify their Epic » ; « `goal` and `source` never hold the same reference ».
- **Persistance** : `aidd_docs/backlog/epics/<slug>.md`.

### 1.8 `aidd-pm` [4.8] `08-three-amigos` — 126 lignes

| Fichier | Lignes |
|---|---|
| `SKILL.md` | 30 |
| `actions/01-assess.md` 29 · `02-reconcile.md` 31 | 60 |
| `references/assessment.md` 25 · `reconciliation.md` 11 | 36 |

- **Déclencheur** : « refine one before a backlog change » ; `argument-hint: artifact | reports`. Not for : « spawning or writing ».
- **Règles** : « Run one route per invocation. » · « Never spawn, delegate, persist, or mutate. » · « Treat roles as analytical lenses, not human authorities. » · « Ground every finding and question in cited evidence; never invent a decision. » · « Return proposals only; the caller decides. »
- **`assess`** : entrée = un snapshot Epic/Story + `role: product|delivery|quality` ; une lentille par invocation.
  - product : outcome, audience, value, scope, evidence, product assumptions ;
  - delivery : feasibility, dependencies, interfaces, constraints, operability, delivery unknowns ;
  - quality : acceptance observability, states, edge cases, failure modes, verification gaps.
  - « Do not decide priority, solution, scope, estimate, or acceptance on the user's behalf. »
- **Rapport** : `target`, `snapshot`, `role`, `verdict` (`ready` | `revise` | `blocked`), `sources`, `findings`, `questions` ; finding = id stable, impact `blocking|material|minor`, une claim, pointeur de source, extrait décisif ; amendement seulement « when the evidence entails it ».
- **`reconcile`** : exactement trois rapports, même snapshot ; claims équivalentes fusionnées en gardant tous les rôles ; contradiction → les deux positions + une question, « no lens ranked above another » ; amendement = `before`, `after`, finding ids, evidence ; « silence, majority, and severity are not approval ».
- **Liens** : orchestré par `aidd-orchestrator:02-backlog` action `05-assess` (« run Three Amigos in three isolated parallel assessments, one per role, on the same snapshot ») ; le skill lui-même ne lance rien.

### 1.9 `aidd-pm` [4.9] `09-defect` — 236 lignes

| Fichier | Lignes |
|---|---|
| `SKILL.md` | 35 |
| `actions/01-capture.md` 30 · `02-assess.md` 29 · `03-finalize.md` 35 | 94 |
| `assets/defect-template.md` | 38 |
| `references/handoffs.md` 11 · `lifecycle.md` 15 · `persistence.md` 18 · `qualification.md` 7 · `readiness.md` 12 · `relations.md` 16 | 79 |

- **Déclencheur** : « report, assess, link, order, transition, or verify a defect » ; `argument-hint: report | defect`. 6ᵉ règle : « Record the mismatch; never diagnose or implement its fix. »
- **Gabarit** : `type: defect`, `status: reported` ; `## Context` · `## Expected` · `## Actual` · `## Reproduction` · `## Impact` · `## Evidence` · `## Verification` · `## Cancellation`.
- **Statuts** : `reported → ready → in-progress → done | cancelled` ; `done` = « verification proves expected behavior » ; « A duplicate is cancelled only after the retained identity is known ».
- **Readiness** : Mismatch / Impact / Evidence / Scope / Relations / Verifiable.
- **Relations** : `source`, `depends_on`, `related_to` (« the affected artifacts »), `supersedes`, `order` (« product impact and project policy decide it, not severity alone »), `estimate` ; pas de `parent` : « resolution work is a Task whose `parent` is the Defect ».
- **Handoffs** : comportement nouveau souhaité → Story ; travail de résolution → Task ; inconnue → Spike ; « active service disruption → incident response, out of backlog ».
- **Persistance** : `aidd_docs/backlog/defects/<slug>.md`.

### 1.10 `aidd-pm` [4.10] `10-task` — 235 lignes

| Fichier | Lignes |
|---|---|
| `SKILL.md` | 35 |
| `actions/01-frame.md` 30 · `02-review.md` 29 · `03-finalize.md` 34 | 93 |
| `assets/task-template.md` | 27 |
| `references/handoffs.md` 11 · `lifecycle.md` 15 · `persistence.md` 17 · `qualification.md` 7 · `readiness.md` 12 · `relations.md` 18 | 80 |

- **Déclencheur** : travail de livraison borné « without independent user value » ; `argument-hint: request | task`. 6ᵉ règle : « Record delivery work; never plan or implement it. »
- **Gabarit** : `type: task`, `status: proposed` ; `## Outcome` · `## Scope` (`Includes` / `Excludes`) · `## Done When` · `## Completion Evidence` · `## Cancellation`.
- **Statuts** : `proposed → ready → in-progress → done | cancelled` ; `done` = « completion evidence passes ».
- **Relations** : `source`, `parent` (Epic, Story ou Defect), `depends_on`, `related_to`, `supersedes`, `order`, `estimate`, `work_kind` (`functional` | `technical`, « only when the project uses it »).
- **Test notable** : « Order conflict | no write; the occupied value is returned without choosing another ».
- **Persistance** : `aidd_docs/backlog/tasks/<slug>.md`.

### 1.11 `aidd-orchestrator` `02-backlog` — 362 lignes

| Fichier | Lignes |
|---|---|
| `SKILL.md` | 48 |
| `actions/01-inspect.md` 33 · `02-triage.md` 28 · `03-review.md` 30 · `04-route.md` 27 · `05-assess.md` 25 · `06-decide.md` 29 · `07-apply.md` 30 · `08-verify.md` 26 | 228 |
| `references/change-set.md` 13 · `events.md` 16 · `intake.md` 13 · `modes.md` 11 · `review.md` 18 · `supports.md` 19 | 90 |

- **Déclencheur** : « ask what it holds, or run intake, triage, refinement, review, lifecycle events, ordering, health checks, or repair » ; `argument-hint: ask | create | manage | review | refine`.
- **Flux** : `inspect` → (`ask` → réponse du read model | `create` → `triage` → `route` | `manage` → `route` | `refine` → `assess` | `review` → `review`) → `decide` → (`revise` → route | `no change` | `authorize` → `apply` → `verify` → `invalid` → route | `coherent`).
- **Règles** : « Delegate artifact work to its owning capability, resolved by purpose and verified as installed before delegating. » · « Store each relation once » · « Change only authorized artifacts and fields. »
- **Étapes clés** :
  - `inspect` : supports, read model, event, mode, scope ; « Backlog held elsewhere | read model reported as partial, never as an empty backlog » ; « No mode | interactive authority ».
  - `triage` (intake) : même résultat → réutiliser ; plusieurs tranches → Epic ; un comportement → Story ; travail sans valeur → Task ; incertitude → Spike ; mismatch → Defect ; incident → hors backlog.
  - `review` (santé) : 12 signaux (`review.md`), ex. « `ready` or `in-progress` Epic whose goal is absent », « Task or Story without a parent → confirm that standalone work is intentional », « live child under a terminal parent », « durable outcome or failure lesson not yet retained → offer a matching learning capability » ; « Never infer a WIP limit, stale date, priority, or product decision ».
  - `route` : demande des **propositions** aux skills propriétaires (« Delegation stops before the capability persists anything »).
  - `assess` : Three Amigos en trois évaluations isolées parallèles + réconciliation.
  - `decide` : **Authorize** — « ask one open question for correction, rejection, or approval and wait for the reply before the change set is frozen » ; **Freeze** — « Allow no unlisted mutation ».
  - `apply` : chaque skill propriétaire écrit, « without re-asking approval » ; stop sur échec en gardant le travail fait.
  - `verify` : chaque propriétaire prouve ses écritures ; mutation non autorisée = échec.
- **Change set** (`change-set.md`) : `identity` (`new` avant création), `artifact` (Epic/Story/Task/Spike/Defect), `operation` (create, update, transition, relate, order, estimate, cancel), `owner`, `before`, `after`, `evidence` ; « Never persist the change set ».
- **Modes** : aucun signal → interactif ; « autonomous with bounds » ; « autonomous without bounds → apply changes inside the resolved scope » ; « Every mode stops for a new product decision: what to build, for whom, at what value. »
- **Supports** : « Each artifact and field has one authority. Across supports, keep a stable link or a configured projection, never a second copy. »

### 1.12 `aidd-orchestrator` `01-sdlc/references/01-frame.md` (50) et `mode.md` (28) ; `SKILL.md` 56 ; pour contexte `02-deliver.md` 57, `03-check.md` 80

- **SDLC** : `$request → 01 Frame → 02 Deliver → 03 Check → $pull_request` ; `argument-hint: request | interactive request`.
- **Frame** : « Start from `$source` only. Resolve a ticket when the source references one. Use the source directly when it is planning-ready. Otherwise clarify only the intent that can change what is built, then formalize the missing contract requirements. Commit whatever this zone wrote before handing the resulting contract to Deliver. »
  - **Définition** : « A source is planning-ready when it names the artifact to change, states the observable outcome, and leaves open no decision that changes what is built. »
  - Routage : ticket → `/aidd-pm:01-ticket-info` ; intention qui change ce qui est construit → `/aidd-refine:01-brainstorm` → `/aidd-pm:04-spec` ; seuls les requis manquent → `/aidd-pm:04-spec` ; produit `$contract`.
- **Mode** : `auto` par défaut (« Operate autonomously from the request to a draft pull request: decide and act without confirmation ») ; `interactive` si le **premier mot** de la requête est `interactive`. Toujours : « Ask only before spending money, taking an irreversible action, or making a decision that requires user authority. »
  - Interactif : **trois pauses**, une par artefact (contrat, plan, résultat avant PR) ; « An artifact produced anew pauses again. »
  - Refus : « A refusal at a pause is a finding against that artifact » ; contrat/spec → Frame, plan → Deliver, outcome → Deliver ou Frame ; « Only the user bounds this loop. »
- **Deliver** : `/aidd-dev:01-plan` → `@aidd-dev:executor` → `02-implement` → `03-assert` → (`06-test` e2e si le plan l'exige) → `/aidd-vcs:01-commit`.
- **Check** : `@aidd-dev:checker` frais → `/aidd-dev:05-review` → `/aidd-refine:02-challenge` → findings routés (produit → Frame ; implémentation indépendante → `/aidd-dev:10-batch` ; dépendante → Deliver) → `/aidd-vcs:02-pull-request` (draft). « A finding already acted on is never routed twice. »

### 1.13 `aidd-refine` — 5 skills

#### `01-brainstorm` — 158 lignes
`SKILL.md` 29 · `actions/01-capture.md` 17 · `02-explore.md` 26 · `03-conclude.md` 24 · `assets/discovery-brief.md` 17 · `references/discovery-map.md` 29 · `persistence.md` 9 · `probing.md` 15.
- Déclencheur : « half-formed idea, ambiguous request… brainstorm, discover, refine, or clarify » ; `argument-hint: idea`.
- Règles : « Clarify only: never plan or code. » · « Ask a question only if its answer changes the outcome. » · « After questions, approval or persistence options, wait. »
- Flux : `capture` (redire l'idée « in the user's words ») → `explore` (boucle questions/réponses ; « On a contradiction, ask which one stands » ; « When facts converge, state your leaning and its tradeoff ») → `conclude` (approve / correct / explore more) → persistance au choix.
- **Discovery map** (ordre) : actor/pain/desired change → trigger/steps/visible behavior → non-goals/smallest slice → inputs/state/API/permissions/invariants → acceptance/metric/done signal → edge case/dependency/rollout/risk ; branches « Tradeoff », « Codebase boundary », « Data contract », « Change path ».
- **Probing** : Name the fork, Force a choice, Reach the outcome, Alternatives, Hidden assumption, Limits, Premortem.
- Gabarit `discovery-brief.md` : `# <Idea title>` + phrase ; `## Clear` · `## Assumed` (« Default taken, and why ») · `## Open`.
- Persistance : chat | `aidd_docs/tasks/<yyyy_mm>/<yyyy_mm_dd>_<slug>/brainstorm.md` avec `status: approved` | ticket.

#### `02-challenge` — 84 lignes
`SKILL.md` 31 · `actions/01-challenge.md` 31 · `assets/report-template.md` 12 · `references/confidence-rubric.md` 10.
- Rejoue un travail contre la référence convenue ; trois questions de confiance (« Am I proud… », « Am I confident in every consequential choice… », « Will the user be satisfied with the real end-to-end outcome? ») ; classement Correctness / Deal breaker / Suggestion ; rubric 100 % / 75-95 % / 50-74 % / <50 % ; « Deal breakers non-empty only when confidence is below 75% ».
- Appelé par `01-sdlc` Check après la revue ; capacité « challenge » de `05-spike`.

#### `03-shadow-areas` — 387 lignes
`SKILL.md` 40 · `actions/01-detect.md` 28 · `02-render-report.md` 35 · `03-diff.md` 28 · `assets/report-template.md` 51 · `references/categories.md` 75 · `locked-sets.json` 31 · `probe-style.md` 37 · `severity-rubric.md` 62.
- Déclencheur : « Scan a markdown artifact (idea, stories, PRD, spec) for blind spots » ; `argument-hint: file | text`.
- **7 catégories verrouillées** : `unstated assumption`, `ambiguous term`, `missing edge case`, `missing actor`, `missing failure mode`, `missing acceptance criterion`, `missing dependency` (chacune avec définition, exemple positif, contre-exemple).
- **3 sévérités** : `blocker` (arrêt dur d'une phase aval), `major` (reprise), `minor` (clarté seule) ; « Do not assign `blocker` for gaps that are discoverable and fixable within the current phase. »
- **Sonde** : question directe, l'une des 14 formes (`what`, `when`, `who`…), finit par `?`, une seule cible.
- Rapport écrit **à côté de la source** : `<source sans dernière extension>-shadow-report.md`, frontmatter `source`, `generated_at`, `status: clean` quand 0 blocker et 0 major ; mode diff `Closed` / `Still Open` / `Newly Introduced`, appariement « by category and snippet, never by question wording ».
- « Never modify the source artifact. »

#### `04-fact-check` — 245 lignes
`SKILL.md` 41 · `actions/01-identify-claims.md` 23 · `02-verify.md` 24 · `03-report.md` 27 · `assets/report-template.md` 22 · `references/claim-categories.md` 24 · `report-output-discipline.md` 25 · `verification-cascade.md` 37.
- Catégories : `version`, `api-signature`, `date-event-person`, `project-fact`, `hard-to-know` ; cascade mémoire → code → web, court-circuit ; verdicts `verified` / `refuted` / `conflict` / `unverified` ; marqueur littéral `(unverified - no source found)` ; `## Sources` en notes `[n]`.

#### `05-improve` — 103 lignes de prose + 342 lignes d'assets HTML/CSS/JS
`SKILL.md` 30 · `actions/01-read-conversation.md` 25 · `02-recommend.md` 22 · `03-target-edits.md` 21 · `assets/conversation-sources.md` 9 · `report-template.html` 129 · `report.css` 109 · `report.js` 104.
- Lit une conversation complète, mesure temps/tokens/coût, recommande des retouches minimales ; « Run all three actions in order without confirmation » ; lecture seule du projet, rapport HTML temporaire. Hors chaîne produit.

### 1.14 `aidd-qa` `01-acceptance-qa` — 271 lignes

`SKILL.md` 32 · `actions/01-load-scope.md` 31 · `02-prerequisites.md` 28 · `03-prepare-run.md` 28 · `04-run-scenarios.md` 31 · `assets/qa-report-template.md` 21 · `references/interface-browser-playwright-cli.md` 100.

- **Déclencheur** : « acceptance criteria exist and a browser-observable journey needs proof it holds » ; `argument-hint: acceptance criteria | reviewed candidate`. Not for : revue de diff, tests unitaires, correctifs.
- **Règle fondatrice** : « Never derive a scenario from the diff or the source code; every scenario traces to an acceptance criterion. »
- **`load-scope`** : critères pris de « the issue, spec, story, or user; never a plan » ; au plus **1 happy path** + edge cases seulement s'ils sont nommés par un critère ; critères non observables au navigateur → « Out of interface » cité ; rien de gardé → `qa.md` `skipped`.
- **`prerequisites`** : `npx`, `@playwright/cli@0.1.17`, `ffmpeg`, `ffprobe` ; dépendance manquante → **une question** (l'humain installe, ou autorise l'installation) ; « Never add runner or media dependencies to the application manifest. »
- **`prepare-run`** : réutilise la section `Browser QA` de `aidd_docs/memory/testing.md` ; viewport 1280×720 ; « never pick a live record by guesswork » ; scénario à état sans teardown vérifié → rejeté.
- **`run-scenarios`** : une prise WebM par scénario, ≤ 12 s, `qa/happy-path.webm`, `qa/edge-case-<slug>.webm` ; verdict `pass | fail | blocked | skipped` ; « fail over blocked or rejected over pass ».
- **Gabarit** `qa.md` : `# Acceptance QA: {{feature}}` ; Verdict / Source / Candidate / Run ; `## Out of interface` ; `## Scenarios` (table `Scenario | Criteria | Expected | Actual | Verdict | Duration | Evidence`) ; `## Rejected`.
- **Liens** : **n'est appelé par aucun autre skill** (grep : seule mention hors `aidd-qa` dans `aidd-dev/CHANGELOG.md`) ; il n'est pas dans le Check de `01-sdlc`.

### 1.15 `aidd-context` — ce qui sert l'amont produit

#### `00-onboard` — 351 lignes
`SKILL.md` 32 · `actions/01-scan.md` 27 · `02-assess.md` 25 · `03-present.md` 40 · `04-run.md` 33 · `assets/banner.txt` 7 · `report.md` 66 · `references/flow.md` 27 · `order/idle-menu.md` 14 · `order/ranking.md` 10 · `order/screen-map.md` 9 · `run/replies.md` 14 · `run/return.md` 3 · `run/tiers.md` 13 · `state/detection.md` 18 · `state/done-rule.md` 6 · `state/hedge.md` 12 · `state/zones.md` 41.
- Boucle `scan → assess → present → run → scan`. Fondations (greenfield : tech stack → project memory → wiring ; existant : memory → wiring) puis **flux feature en 8 étapes** : `brainstorm → spec* → plan → implement → assert → review → commit → PR` (`*` optionnel) ; « `[1]` walk with me… `[2]` hand the whole flow to `aidd-orchestrator:01-sdlc` ».
- Détection d'étape : spec sous `aidd_docs/` ; `plan.md` ; code ; PR de la **branche courante** seulement ; « hedge » par `status:` du plan (`pending`, `in-progress`, `implemented`, `reviewed`, `blocked`).
- Tiers d'exécution : `AUTO` / `GUIDED` / `MANUAL` ; « Never run a GUIDED step unattended » ; « Wait for an explicit reply before running anything ».
- **Ne mentionne aucun skill `aidd-pm`** : le parcours guidé saute product-brief, epic, stories.

#### `02-project-memory` — 1 108 lignes au total dont gabarits de mémoire
`SKILL.md` 33 · `actions/01-scan.md` 30 · `02-write.md` 30 · `03-check.md` 38 · `04-sync.md` 34 · `assets/report.md` 56 · `scan-summary.md` 23 · `templates/AGENTS.md` 47 · `CONTRIBUTING.md` 21 · `GUIDELINES.md` 20 · `README.md` 17 · `templates/memory/**` (24 fichiers, 17 à 50 lignes) · `references/capability-signals.md` 24 · `ecosystem-signals.md` 47 · `memory-destinations.md` 36 · `memory-rules.md` 13 · `reading-sources.md` 45 · `review-protocol.md` 16 · `structure.md` 20 · `tools.md` 17.
- Pour l'amont produit, trois éléments comptent :
  1. **`memory/core/project-brief.md`** (29) : `## What it is` · `## Why it exists` · `## Domain language` (table `Term | Meaning`) · `## Key features` ; « Personas and user journeys only if it is a user-facing product ».
  2. **`memory/backlog/backlog.md`** (50), posé quand la capability `backlog` est détectée : `## Supports` (`Support | Authority for | Role`) · `## Structure` (Mermaid Product goal → Epic → User Story → Task ; Spike, Defect) · `## Representation` · `## Workflow` (`Native status | Meaning`) · `## Planning` (Priority, Estimation, Iteration, Milestone) · `## Relations` (Parent, Dependency, Cross-support).
  3. Capability `backlog` détectée par « local backlog artifacts, issue templates, a ticketing tool in use ».
- Règles : « A bank that already exists changes only through what the user approved, file by file and line by line. »

#### `10-learn` (lu car fin de chaîne) — 214 lignes environ
`SKILL.md` 35 · actions 26/25/29/29/28 · assets `adr-template.md` 24 · `learning-packet.md` 13 · `recommendation-table.md` 5 · `write-report.md` 7 · references `assessment.md` 25 · `destinations.md` 27 · `gather-protocol.md` 34 · `review-protocol.md` 13 · `sources.md` 28 · `sync-arguments.md` 17.
- Source (`conversation | file | diff | review`) → gather → assess (score 0-10 sur durabilité, réutilisation, adéquation, risque ; réconciliation `new | covered | updates | supersedes | retracts`) → **approve / modify / skip** par paquet → write (memory, ADR `aidd_docs/memory/internal/decisions/<slug>.md`, contract) ou handoff (rule, skill) → sync.
- Appelé par `02-backlog` review (« offer a matching learning capability »).

---

## 2. La chaîne produit d'AIDD de bout en bout

### 2.1 En une ligne

`besoin → 01-brainstorm (discovery brief) → 06-product-brief (aidd_docs/product/) → 03-prd (aidd_docs/tasks/…-prd.md) → 07-epic → 02-user-stories (+ 05-spike / 10-task / 09-defect) ⇄ 02-backlog + 08-three-amigos → [ticket GitHub, hors aidd-pm] → 01-sdlc Frame (01-ticket-info → 04-spec = contrat) → Deliver (01-plan → executor → implement/assert/test → commit) → Check (checker → 05-review → 02-challenge) → draft PR → 01-acceptance-qa (qa.md + WebM, non câblé) → 10-learn`

### 2.2 Deux chaînes faiblement couplées, pas une

Constat structurant : AIDD a **deux chaînes** qui ne s'appellent pas.

| Chaîne | Pilote | Artefacts | Couplage |
|---|---|---|---|
| **Backlog produit** | `aidd-orchestrator:02-backlog` (et chaque skill d'artefact en direct) | Product Brief, PRD, Epic, Story, Task, Spike, Defect | les skills se proposent l'un l'autre par **nom de capacité** (« Epic », « Spike », « a requirements capability »), jamais par identifiant de slash-command |
| **Livraison** | `aidd-orchestrator:01-sdlc` | `$contract` (spec), `plan.md`, candidat commité, PR | appelle par identifiant : `/aidd-pm:01-ticket-info`, `/aidd-refine:01-brainstorm`, `/aidd-pm:04-spec`, `/aidd-dev:*`, `/aidd-vcs:*` |

Le pont entre les deux n'est **pas outillé** : une Story `ready` ne déclenche rien ; `01-sdlc` part d'un `$source` (texte, fichier ou ticket). `00-onboard` ne propose que la chaîne livraison. `01-acceptance-qa` n'est câblé nulle part. Mesuré par grep sur `plugins/` (§1.14).

### 2.3 Carte des artefacts

| Artefact | Producteur | Chemin | Frontmatter / statut | Consommateur |
|---|---|---|---|---|
| Discovery brief | `aidd-refine:01-brainstorm` | `aidd_docs/tasks/<yyyy_mm>/<yyyy_mm_dd>_<slug>/brainstorm.md` (ou chat, ou ticket) | `status: approved` | `04-spec` via Frame |
| Product Brief | `aidd-pm:06-product-brief` | `aidd_docs/product/<product-slug>.md` | `objective`, `revision: current|superseded`, `supersedes` | Epic (`goal`), PRD (source) |
| PRD | `aidd-pm:03-prd` | `aidd_docs/tasks/<yyyy_mm>/<yyyy_mm_dd>-<feature_name>-prd.md` | aucun | Epic, Stories, Spec (lift) |
| Epic | `aidd-pm:07-epic` | `aidd_docs/backlog/epics/<slug>.md` | `type: epic`, `status`, relations | Stories (`parent`) |
| User Story | `aidd-pm:02-user-stories` | `aidd_docs/backlog/stories/<slug>.md` | `type: story`, `status`, `parent`, `order`, `estimate` | Task, Spike, acceptance-qa (critères) |
| Task | `aidd-pm:10-task` | `aidd_docs/backlog/tasks/<slug>.md` | `type: task`, `work_kind` | — |
| Spike | `aidd-pm:05-spike` | `aidd_docs/backlog/spikes/<slug>.md` | `type: spike`, `parents` | parent réévalué |
| Defect | `aidd-pm:09-defect` | `aidd_docs/backlog/defects/<slug>.md` | `type: defect`, `status: reported` | Task (`parent`) |
| Rapport Three Amigos | `aidd-pm:08-three-amigos` | jamais persisté | `verdict ready|revise|blocked` | `02-backlog` decide |
| Change set | `02-backlog` | jamais persisté (« Never persist the change set ») | — | apply |
| Spec (contrat) | `aidd-pm:04-spec` | `aidd_docs/tasks/<yyyy_mm>/<yyyy_mm_dd>_<slug>/spec.md` | aucun ; « immutable once validated » | `aidd-dev:01-plan` |
| Rapport d'ombre | `aidd-refine:03-shadow-areas` | à côté de la source, `*-shadow-report.md` | `source`, `generated_at`, `status: clean` | auteur |
| Plan | `aidd-dev:01-plan` | même dossier de feature : `plan.md` + `phase-N.md` | `objective`, `status: pending|in-progress|implemented|reviewed|blocked` | executor, onboard hedge |
| Rapport QA | `aidd-qa:01-acceptance-qa` | `<dossier feature>/qa.md` + `qa/*.webm` | verdict en corps | relecteur humain |
| Rapport de vérif mémoire | `02-project-memory` check | `aidd_docs/tasks/<yyyy_mm>/<yyyy_mm_dd>_memory-check/report.md` | — | humain |
| ADR / mémoire | `aidd-context:10-learn` | `aidd_docs/memory/*.md`, `aidd_docs/memory/internal/decisions/<slug>.md` | `Status: Accepted`, `Supersedes` | sessions suivantes |

### 2.4 Backlog et tickets

- Les skills `aidd-pm` n'écrivent **que du Markdown local**. Tout autre support (GitHub Issues, Jira) est « a project's own integration », résolu via `aidd_docs/memory/backlog.md` (table `Supports`) et les « native fields when supported ».
- Création de ticket : `aidd-vcs:04-issue-create` (31 + 26 + 67 + 48 lignes), outil détecté depuis la mémoire puis l'URL distante, **validation explicite** du titre, corps, labels, type, projects et milestone avant création. Gabarit : `# ✨ Issue Title`, `## 🌟 Objective / Problem`, `## 🛠️ Proposed Solution`, `## 🔍 Context / Technical Constraints`, `## 📎 Attachments / References`, `## 🙏 QA`.
- **Usage réel par AIDD sur son propre dépôt** (`aidd_docs/memory/backlog.md`) : GitHub Issues = autorité des work items (type `Feature` / `Bug` / `Task` posé par le formulaire d'issue, pas par label) ; board « AIDD Roadmap » (org project 8) = ordre et statut (`Ideation`, `Todo`, `In Progress`, `In review`, `Done`, déplacé à la main) ; Milestones = thèmes ; Discussions = idées classées par 👍 ; `aidd_docs/` = plans/specs locaux, « never a substitute for the issue ». Labels : « Labels categorize nothing: one exists only when a bot or a human reads it. »
- Donc **Epic/Story ne sont pas utilisés par AIDD sur lui-même** : leur propre backlog est Feature/Bug/Task en issues.

### 2.5 Three Amigos

Trois lentilles analytiques (product, delivery, quality), lancées en parallèle isolé par `02-backlog/05-assess` sur le **même snapshot** d'une Epic ou Story, puis réconciliées. Aucune n'écrit, aucune n'a autorité ; conflit = question ouverte, jamais vote. Intervient **avant** l'écriture d'un changement de backlog (refinement), pas avant le code.

### 2.6 Descente des critères d'acceptation jusqu'à la QA

1. Product Brief : pas de critère, seulement `Success` et `Validation and Feedback`.
2. PRD : `## Acceptance Criteria` (« observable and user-facing ») et `## Goals`.
3. Story : `## Acceptance` (« observable condition », Gherkin optionnel) ; condition de `ready` (INVEST « Testable ») et de `done`.
4. Spec : `## Done-when` (« observable conditions… never the command that checks it ») ; le PRD y est « lifted ».
5. Plan : `phase-N.md` porte `## Test acceptance criteria` (table `Task | Acceptance criteria`, vérifiée par `validate-plan.cjs`) ; `02-implement` code « until every acceptance criterion holds » ; `05-review/03-review-functional` « Trace the diff against the plan's acceptance criteria ».
6. QA : `01-acceptance-qa` reprend les critères **depuis l'issue, la spec, la story ou l'utilisateur, jamais depuis le plan**, et rejette tout scénario issu du diff ou du code. C'est le seul garde-fou d'indépendance entre critère et preuve.

Rupture constatée : rien ne relie mécaniquement les `## Acceptance` d'une Story au `Done-when` d'une spec ; la traçabilité est manuelle.

---

## 3. Mise en regard VibeFlow, brique par brique

Légende statut : `existe` · `partiel` · `absent` · `contraire` (contredit la doctrine). Branches : **59** = `feat/phase-59-bundle-produit`, **60** = `feat/phase-60-gate-architecture`, **61** = `feat/phase-61-collaboration` (empilées : 61 contient 60 qui contient 59).

| # | Brique AIDD | Équivalent VibeFlow (chemin) | Statut | Reco | Raison (une phrase) |
|---|---|---|---|---|---|
| 1 | Product Brief (06), 9 rubriques + `objective` | **59** `plugin/product-team-bundle/references/BRIEF.template.md` (31 l., 5 rubriques : Problème, Utilisateurs, Valeur, Contraintes, Hors périmètre) + `vf-product-analyst.md` | partiel | adapter | Notre BRIEF n'a ni table `Claim / Status / Basis` (preuve, hypothèse, décision) ni « Validation and Feedback » : ce sont les deux apports qui manquent, à ajouter comme rubriques du même fichier. |
| 2 | Règle « Separate evidence, decisions, and assumptions » + `evidence.md` (ce qu'une source peut établir ou non) | 59 : `vf-product-analyst` « n'invente aucun fait… cite tes sources » | partiel | reprendre tel quel | La table source → peut / ne peut pas établir est une grille de juge directement utilisable par `prd-gate`. |
| 3 | `brief-quality.md` (6 contrôles) | 59 `prd-gate` critère « BRIEF complet et lisible sans être dev » (20 pts) | partiel | adapter | Coherence (« one falsifiable claim ») et Validation (« targets the riskiest assumption ») affineraient les 20 points du critère BRIEF. |
| 4 | PRD (03), fichier séparé à 8 sections | 59 `plugin/planning-core/references/templates/product/PROJECT.template.md` (44) + `REQUIREMENTS.template.md` (51), exigence `PRD-NN` + `Acceptation :` + `Priorité : must|should|could` | existe | écarter | A-06 interdit un `PRD.md` ; notre forme par exigence est plus forte (critère par ligne, contrôlé par `check-prd.sh`). |
| 5 | Section PRD `## Open Questions` / marqueur `TBD: <question>` confiné à une section | 59 `check-prd.sh` traite `TBD` comme éliminatoire ; aucune section de questions ouvertes dans les gabarits product | absent | adapter | Un endroit unique pour les inconnues, hors des exigences, permet d'arrêter de les cacher sans rendre le PRD rouge. |
| 6 | Spec (04) + `spec-validator.yml` pondéré + seuils durs | GSD `gsd-spec-phase` (SPEC.md) ; 59 `prd-gate` rubric /100 seuil 80 | partiel | adapter | Les « hard_thresholds » (`contains_implementation_details`, `target_unclear_or_multiple_targets`) sont des éliminatoires que `prd-gate` n'a pas. |
| 7 | Epic (07) | Milestone et phases de `ROADMAP.md` ; `gsd-audit-milestone` | existe | écarter (le terme) / adapter (une règle) | Q-11 ferme « epic » ; la règle « Closing every child does not complete an Epic without its success evidence » vaut pour la clôture d'un jalon. |
| 8 | User Story (02) : gabarit As/I want/So that | Exigences `PRD-NN` (59) et plans de phase | contraire (le terme) | écarter | Q-11 fermée par doctrine, et ce serait une couche de synonymes au-dessus des exigences. |
| 9 | Readiness INVEST + `slicing.md` (« Avoid splitting by frontend, backend, database… ») | aucun contrôle INVEST trouvé (grep `INVEST` : 0 occurrence significative sur `main`) | absent | adapter | Les six critères INVEST et la règle de découpe verticale donneraient au dev qui valide une phase proposée (A-07) une grille, sans créer d'artefact « story ». |
| 10 | Spike (05) | `gsd-spike` (cité par `plugin/dev-orchestrator/references/gsd-skills-index.md`, `intent-routing.md`) | existe | écarter (adapter `Bounds`) | Le geste existe ; seul le couple `Evidence needed` / `Stop when` mérite d'entrer dans un brief de spike. |
| 11 | Defect (09) | `gsd-debug`, registre BLOCKERS, issues GitHub | partiel | écarter | Le jalon equipe-produit ne porte pas l'intake de bugs ; à reconsidérer hors jalon (le gabarit Expected/Actual/Reproduction/Impact/Evidence/Verification est propre). |
| 12 | Task (10) | `gsd-quick`, tâches des PLAN.md | existe | écarter | Doublon direct du geste dev existant. |
| 13 | Three Amigos (08) : trois lentilles en lecture seule + réconciliation | 59 `prd-gate` (une lentille produit) ; `vf-reviewer`/`vf-auditer` (après code) ; 60 `vf-product-architect` (produit, ne juge pas) | partiel | adapter | Trois juges frais product/delivery/quality sur le PRD avant découpage collent au Pattern 12, et la règle « silence, majority, and severity are not approval » est ADR-031 en une phrase. |
| 14 | `02-backlog` change set (`identity, artifact, operation, owner, before, after, evidence`) + decide/freeze | 60 `vf-validation.sh` + marqueur `**Validation:**` ; `gsd-review-backlog` | partiel | adapter | Le format de change set est exactement ce qu'un dev doit voir pour valider une phase proposée (A-07). |
| 15 | `02-backlog` modes autonomes (« autonomous without bounds → apply changes inside the resolved scope ») | ADR-031, ship gaté humain | contraire | écarter | Écrire sans validation humaine contredit ADR-031. |
| 16 | `02-backlog` review (12 signaux de santé) | `check-divergence.sh` (Phase 39), 61 hook `post-merge` ; validator | partiel | adapter | « live child under a terminal parent » et « Task or Story without a parent » se transposent en contrôles de cohérence ROADMAP/REQUIREMENTS. |
| 17 | `01-ticket-info` + `04-issue-create` (outil détecté depuis la mémoire) | aucun module ; skills perso `to-issues`, `triage` dans `~/.agents/skills` (hors VibeFlow) | absent | écarter | Hors périmètre du jalon (pas de ticketing dans SEED-001). |
| 18 | `01-sdlc` Frame : définition de « planning-ready » | `vibeflow-head` + garde-fou premier usage ; 60 ARCG-05 (le head consulte le gate architecture avant découpage) | partiel | reprendre tel quel | La définition en trois conditions (artefact nommé, résultat observable, aucune décision ouverte qui change ce qu'on construit) est un test d'entrée prêt à citer dans `product-routing.md`. |
| 19 | `01-sdlc` mode `auto` (« decide and act without confirmation » jusqu'à la PR) | `vf-auto` (garde-fous), ship toujours gaté | contraire | écarter | Agir à la place de l'humain jusqu'à la PR contredit ADR-031 et la règle ship gaté. |
| 20 | `mode.md` interactif : trois pauses, une par artefact ; refus = finding routé par artefact | managers : AskUserQuestion / SendMessage, halt conditions | partiel | adapter | « A refusal at a pause is a finding against that artifact… routes by artifact » clarifierait où repart un refus du PRD (vers `vf-product-pm`) ou de l'architecture. |
| 21 | `01-brainstorm` (discovery map + probing) | `gsd-explore`, `gsd-discuss-phase`, emprunts Pocock Phase 41.4 (grilling) ; `plugin/conductor/skills/vf-new-lab/references/elicitation-methods.md` | existe | adapter | La discovery map ordonnée (acteur → déclencheur → non-objectifs → données → acceptation → cas limites) peut guider les questions de `vf-product-analyst`, sans nouveau skill. |
| 22 | `02-challenge` (auto-critique avec % de confiance) | juges frais read-only (Pattern 12), « aucun vert auto-déclaré » | contraire | écarter | Le travail se juge lui-même ; notre doctrine exige un juge distinct de l'auteur. |
| 23 | `03-shadow-areas` (7 catégories, 3 sévérités, sondes, diff entre passes, `status: clean`) | aucun équivalent (grep `shadow` : seulement des faux positifs) | absent | reprendre tel quel (logique) / adapter (sortie) | Grille déterministe et réutilisable pour un juge en lecture seule du BRIEF et du PRD ; la sortie doit aller au rapport du juge, pas en fichier écrit à côté de la source. |
| 24 | `04-fact-check` | disposition admit/refute/abstain des passes de recherche (SEED-001) | partiel | écarter | Hors de l'équipe produit ; déjà couvert par la discipline de recherche. |
| 25 | `05-improve` | Phase 52 (télémétrie, jalon ecc-inspiration) | absent | écarter | Hors du jalon produit. |
| 26 | `01-acceptance-qa` : scénario uniquement depuis un critère, jamais du diff ; `qa.md` + WebM | `gsd-verify-work` (UAT conversationnel), `mobile-test` (Maestro), agent `gsd-dom-verifier` | partiel | adapter | La règle d'indépendance (critère → scénario, jamais code → scénario) et la colonne « Out of interface » relieraient enfin `Acceptation :` du PRD à la recette ; l'outillage Playwright/WebM est secondaire. |
| 27 | `00-onboard` (écran unique, prochaine action) | `vibeflow-head` (`/vf-dev`), `gsd-progress`, `gsd-onboard` | existe | écarter | Un second menu d'orientation serait une couche de synonymes au-dessus du head. |
| 28 | `memory/core/project-brief.md` table `Domain language` | 59 `PROJECT.template.md` (pas de glossaire) | absent | adapter | Une rubrique « Vocabulaire du métier » dans PROJECT product aide les deux postes à parler pareil, sans fichier nouveau. |
| 29 | `memory/backlog/backlog.md` (supports, autorité par champ, workflow natif) | aucun | absent | adapter (plus tard) | Utile seulement si un lab branche un tracker ; la règle « one authority per field, never a second copy » rejoint « le disque fait foi ». |
| 30 | `10-learn` (score 0-10, réconciliation `new/covered/updates/supersedes/retracts`, approve/modify/skip) | `gsd-extract-learnings`, consolidator, registres LEARNINGS/DECISIONS ; 61 champ `role:` | existe | adapter | Les cinq valeurs de réconciliation sont un vocabulaire de mise à jour de registre qui manque au consolidator. |
| 31 | Grammaire transverse : reçu d'écriture `before -> after`, relations à propriétaire unique sans lien inverse, `## Cancellation` + `supersedes` | managers : rapports typés ; registres | partiel | reprendre tel quel (reçu d'écriture) | Un reçu `identité / avant → après / relations / vérification` à la fin de chaque geste simple de `vibeflow-product` rend le non-écrit explicite. |
| 32 | Handoff « Offer the named capability… then stop. Never invoke it silently » | 59 `product-routing.md` (« le head ne le lance pas à la place de l'humain ») ; règle head « propose, ne lance pas » | existe | écarter | Déjà notre doctrine, mot pour mot. |

### Top 8 à reprendre (ordre de valeur pour le jalon)

1. **Three Amigos → trois juges frais sur le PRD** (#13) — partiel (59 n'a que la lentille produit). Adapter.
2. **Shadow areas comme grille de juge** (#23) — absent. Reprendre la logique.
3. **Table Preuve / Hypothèse / Décision dans le BRIEF + `evidence.md`** (#1, #2) — partiel. Adapter / reprendre.
4. **Change set pour la validation des phases proposées** (#14) — partiel (60). Adapter.
5. **INVEST + découpe verticale comme grille du dev qui valide** (#9) — absent. Adapter.
6. **Indépendance critère → recette (acceptance-qa load-scope)** (#26) — partiel. Adapter.
7. **Définition « planning-ready » + refus routé par artefact** (#18, #20) — partiel. Reprendre / adapter.
8. **Questions ouvertes confinées + seuils durs de spec dans `prd-gate`** (#5, #6) — absent / partiel. Adapter.

---

## 4. Collisions avec les arbitrages de SEED-001

| Arbitrage | Ce qu'AIDD ferait | Collision | Issue proposée |
|---|---|---|---|
| **A-06** — PRD = `PROJECT.md` + `REQUIREMENTS.md`, `BRIEF.md` seul fichier nouveau | trois fichiers amont distincts (product brief, PRD, spec) + cinq dossiers de backlog (`aidd_docs/backlog/*`) | **forte** : toute reprise d'artefact AIDD en tant que fichier viole A-06 | reprendre les **règles** (rubriques, grilles, seuils) dans BRIEF/PROJECT/REQUIREMENTS existants, jamais les fichiers |
| **A-06** (corollaire) — tout vit sous `.planning/` | tout vit sous `aidd_docs/` | forte | aucun chemin `aidd_docs/` |
| **A-10** — garder l'existant côté dev, aligner seulement le vocabulaire du rôle product sur des noms courants | vocabulaire Agile complet : Epic, Story, Task, Spike, Defect, Product Brief, PRD, Spec, Three Amigos, Definition of Done | **forte** sur Epic/Story/Task (Q-11 fermée : « la bascule agentique interdit les synonymes ») ; faible sur « PRD », « brief », « critère d'acceptation » (déjà nos mots) | ne rien importer comme nom d'artefact ; « Three Amigos » ne doit pas devenir un nom d'agent (ce serait une marque de pratique, pas une capacité) — nommer les juges par leur lentille |
| **A-10** (source) — aligner sur BMAD courant | AIDD est un **troisième** vocabulaire, ni BMAD ni GSD | moyenne | A-10 vise BMAD ; reprendre AIDD n'autorise pas de nouveaux noms |
| **A-07** — phase proposée jusqu'à validation par un dev, auto-validée en solo, pas de hook bloquant | statut `proposed → ready` par readiness ; mode « autonomous with bounds » qui écrit sans redemander | faible sur les statuts (même mot `proposed`, sens voisin : 60 utilise `**Validation:** proposed|validated`) ; **contraire** pour les modes autonomes | reprendre la grille de readiness comme **aide au dev qui valide**, jamais comme validation automatique ; écarter les modes autonomes |
| **A-07** — « ce n'est pas de la sécurité : un rôle est une vue » | Three Amigos : « Treat roles as analytical lenses, not human authorities » | aucune, convergence | citer la convergence |
| **A-02** — trois profils solo/product/dev, pas de QA ni d'architecte | lentilles product/delivery/quality | faible : les lentilles ne sont pas des postes | implémenter en juges, jamais en postes |
| **A-08** — gate architecture séparé avant découpage | rien d'équivalent ; seulement « Include architecture conformance whenever the project documents architecture » dans Deliver | aucune, AIDD n'apporte rien ici | — |
| **ADR-031** (transverse) | `01-sdlc` auto, `02-backlog` autonomous, `05-improve` « without confirmation », `00-onboard` tier `AUTO` | **contraire** | écarter tous les modes qui écrivent ou ouvrent une PR sans validation humaine |

---

## 5. Licence et conditions de reprise

- **Licence AIDD** : MIT, « Copyright (c) 2026 AI-Driven Dev contributors » (`LICENSE`, 21 lignes). `CITATION.cff` demande de citer « The AI-Driven Dev contributors » si on utilise le framework (demande, pas obligation légale).
- **Condition MIT** : « The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. » Donc :
  - **Transposition d'idées** (grilles, règles reformulées, structure de flux) : aucune obligation légale.
  - **Copie de texte substantielle** (gabarits, tables de référence, `locked-sets.json`, rubriques mot pour mot, même traduites de près) : la notice MIT et le copyright doivent accompagner la copie.
- **Compatibilité avec VibeFlow** : le `LICENSE` de VibeFlow est **propriétaire** (« Copyright (c) 2026 picmakpro. All rights reserved. », redistribution limitée). MIT autorise la sous-licence dans un produit propriétaire, à condition de garder la notice MIT sur la portion copiée.
- **Véhicule** : VibeFlow n'a aujourd'hui **aucun** fichier `THIRD_PARTY*` / `NOTICE` (mesuré : seul `LICENSE` à la racine). Si une portion substantielle est copiée, il faut en créer un (par exemple `THIRD_PARTY_NOTICES.md` à la racine, reproduisant le texte MIT d'AIDD et listant les fichiers concernés), ou mettre la notice en tête du fichier copié. Le fichier `THIRD_PARTY_LICENSES.md` d'AIDD ne couvre que ses dépendances de développement : il n'impose rien à un réutilisateur.
- **Marques** : aucun `TRADEMARK.md` trouvé dans AIDD (contrairement à BMAD). Non mesuré au-delà de l'absence du fichier.
- **Recommandation** : transposer en français dans nos propres mots (règle déjà tenue pour BMAD et GSD : « on transpose, on ne copie ni ses prompts ni ses personas », spec §5.5) et tracer l'origine dans le CHANGELOG du module et le commit. La notice MIT ne devient obligatoire que si l'on recopie.

---

## 6. Ce qui n'a pas été lu ou mesuré

- `plugins/aidd-pm/CHANGELOG.md` (196 l.), `aidd-refine/CHANGELOG.md` (184 l.), `CATALOG.md` des plugins (index généré, survolé) : non lus en entier.
- `aidd-context/02-project-memory/assets/templates/memory/**` : 3 gabarits lus (`README.md`, `backlog.md`, `project-brief.md`) sur 24 ; les 21 autres (api, auth, ui, etc.) non lus (hors amont produit).
- `aidd-refine/05-improve/assets/*.html|css|js` : non lus (rendu de rapport).
- `aidd-dev` (plan, implement, review, checker, executor) : survolé par grep seulement, pour la descente des critères.
- Qui exécute `spec-validator.yml` : non mesuré.
- Versions des plugins autres qu'`aidd-pm` : non mesuré.
- Côté VibeFlow : PLAN et SUMMARY des Phases 59/60/61 non lus en entier ; lu le ledger `REQUIREMENTS.md` (PRDT-01..12, ARCG-01..11, COLB-01..09), les agents et gabarits de 59, `product-routing.md`, `ARCHITECTURE.template.md` de 60. Phase 62 : rien sur disque (TBD au ROADMAP).
- Aucun test exécuté, ni côté AIDD ni côté VibeFlow (lecture seule).
