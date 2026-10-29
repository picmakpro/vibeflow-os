# Skills et agents GSD non utilisés : lesquels brancher dans VibeFlow

Étude en lecture seule, 2026-10-29. Sources lues : `~/.claude/skills/gsd-*/SKILL.md` (72),
`~/.claude/gsd-core/workflows/*.md`, `~/.claude/agents/gsd-*.md` (35), gsd-core installé,
et dans le dépôt sur `origin/main` (`56067e98`) : `plugin/dev-orchestrator/agents/*`,
`references/{mission-flow,mission-contracts,intent-routing,GSD-PIPELINE,docs-flow,gsd-capabilities-index}.md`,
`plugin/design-orchestrator/AGENT.md`, `plugin/conductor/references/team-kernel.md`, `.planning/seeds/SEED-002|003`.

Le brief a été amendé en cours d'étude (Samuel, 2026-10-29). Il n'y a plus de plafond au classement.
« Un ajout = un retrait », le plafond de 2 agents en parallèle et la profondeur ne sont plus traités
comme de la doctrine. La profondeur reste une limite **technique** du harness, mesurée le 2026-09-17 :
à la profondeur 3, l'outil `Agent` n'est plus visible. Chaque déclencheur ci-dessous est donc conçu
pour tenir dans cette limite.

---

## 0. Faits mesurés pendant l'étude (ils fondent les verdicts)

| Fait | Mesure | Commande / source |
|---|---|---|
| Les étages que le moteur insère après exécution (nyquist, sécurité, revue de code) ne sont pas vus en pratique | 75 rapports dans `.planning/missions/`. Seuls 2 portent le champ `verdicts`, et dans ces deux rapports `code_review`, `nyquist` et `secure` valent tous `absent` | `grep -rhoE '"(nyquist\|secure\|code_review)": "[a-z_]+' .planning/missions` |
| Les toggles de ces étages sont pourtant armés dans ce lab | `nyquist_validation: true`, `security_enforcement: true`, `code_review: true`, `intel.enabled: true`, `ui_review: false` | `.planning/config.json` |
| Validation Nyquist : des lacunes constatées mais jamais comblées | 20 `*-VALIDATION.md`, dont **15 `nyquist_compliant: false`** et 14 `wave_0_complete: false` | grep sur le frontmatter |
| Des vérifications attendent une recette humaine qui n'a jamais lieu | 34 `*-VERIFICATION.md` : 21 `passed`, **6 `human_needed`**, **7 `gaps_found`**. Il existe **0** fichier `*-UAT.md` | grep `^status:` |
| Le savoir des étapes n'est jamais extrait | **0** `LEARNINGS.md` dans `.planning/`. Pourtant `plan-phase.md:777` les fait lire au planificateur (les 3 dernières étapes closes) | `find .planning -name '*LEARNINGS*'` |
| Peu d'audits de sécurité écrits sur disque | 4 `*-SECURITY.md`. `vf-auditer` dispatche `gsd-security-auditor` sans passer par le skill `gsd-secure-phase` (il n'a pas l'outil `Skill`) | `plugin/dev-orchestrator/agents/vf-auditer.md` |
| `intel` est armé, mais son producteur n'a aucun appelant | `gsd-intel-updater` n'est appelé par aucun workflow (seul `agent-contracts.md` le cite). `.planning/intel/` ne contient que `API-SURFACE.md` (247 o) | grep dans `~/.claude/gsd-core/workflows` |
| Agents appelés hors du périmètre mesuré (toute la base `~/.claude/projects`) | `gsd-project-researcher` ×12, `gsd-roadmapper` ×2, `gsd-research-synthesizer` ×2 (une seule session `new-project`), `gsd-integration-checker` ×2 (une session) | `grep -rho '"subagent_type":"gsd-…"'` |
| `gsd-debug` invoqué 2 fois, sans qu'aucun de ses agents parte | `gsd-debug-session-manager` : 0 appel ; `gsd-debugger` : 0 appel | même grep |

**Ce qu'on en tire.** VibeFlow compte sur le moteur pour déclencher lui-même nyquist, sécurité et
revue de code à l'intérieur de `gsd-execute-phase` (1 413 lignes de workflow plus les étapes, lu
par `vf-coder` en sonnet, effort medium). En pratique, ces étages ne sortent pas. La cause n'est
pas mesurée : un saut d'étape par le modèle, ou une résolution des toggles via `--ws` qui retombe
sur un `config.json` de compartiment réduit à une clé, sont les deux hypothèses, non vérifiées car
lancer `gsd-tools loop render-hooks` m'était interdit. La conclusion pratique tient malgré tout :
**les gains les plus sûrs viennent de nœuds explicites posés par le manager**, qui ne dépendent pas
d'un hook enfoui dans un workflow de 1 400 lignes.

---

## 1. Inventaire — 64 skills et 25 agents non utilisés

Verdicts : **B** = brancher (déclenchement automatique sur un fait machine) · **D** = à la demande
(garder routable) · **R** = redondant · **I** = inutile pour nous. Les chemins sont relatifs au dépôt.

### 1.1 Cycle de phase

| Brique | Rôle | Couvert par VibeFlow ? | Verdict |
|---|---|---|---|
| `gsd-verify-work` | Recette UAT conversationnelle d'une étape exécutée | Prescrite comme étage de test hors mobile (`vf-dev-manager.md` §Orchestration 3) mais jamais lancée : 6 VERIFICATION `human_needed`, 0 UAT | **B** (P1) |
| `gsd-spec-phase` | Fixe le QUOI d'une étape, avec un score d'ambiguïté, dans un SPEC.md | Ligne des briques dormantes (`mission-flow.md` §Briques dormantes), déclencheur au jugement | **B** (P2) |
| `gsd-mvp-phase` | Planifie une étape en tranche verticale (user story, SPIDR) | `intent-routing.md` | D |
| `gsd-autonomous` | Enchaîne discuss→plan→execute sur toutes les étapes | `vf-auto` + `vf-dev-manager`. Ses modes d'enchaînement déclenchent l'auto-approbation (règle 5, `GSD-PIPELINE.md` §9) | R |
| `gsd-fast` | Tâche triviale exécutée sur place, sans vérification | Le head mandate `gsd-quick --validate` | R |
| `gsd-manager` | Console multi-étapes interactive | `vf-dev-manager` | R |
| `gsd-next` | Porte d'entrée qui route vers la bonne commande | `vibeflow-head` (exclusion écrite dans `intent-routing.md` §Couverture) | R |
| `gsd-progress` | État d'avancement et suite | Le head propose le next step depuis ROADMAP/STATE | D |
| `gsd-ultraplan-phase` | Planification déportée dans le cloud (bêta) | Sort du verrou et du DAG | I |

### 1.2 Vérification et qualité

| Brique | Rôle | Couvert ? | Verdict |
|---|---|---|---|
| `gsd-secure-phase` (+ `gsd-security-auditor`, déjà utilisé) | Ferme le registre de menaces du PLAN et écrit SECURITY.md (`threats_open`) | `vf-auditer` appelle l'agent nu : pas de SECURITY.md, pas de `threats_open` | **B** (P1) |
| `gsd-validate-phase` | Comble les lacunes Nyquist (génère des tests, met à jour VALIDATION.md) | Hook `verify:post` jamais vu ; 15/20 non conformes | **B** (P1) |
| `gsd-audit-uat` | Inventaire transverse des UAT et VERIFICATION en attente, puis plan de test humain priorisé | Rien | **B** (P1) |
| `gsd-ui-review` | Audit visuel rétroactif sur 6 piliers, noté (UI-REVIEW.md) | `vf-design-judge`, mais seulement quand un DESIGN.md existe | **B** (P2, labs UI) |
| `gsd-eval-review` | Couverture des évaluations d'une étape IA comparée à AI-SPEC.md | Rien | **B** (P3, conditionnel) |
| `gsd-forensics` | Post-mortem d'un cycle raté | Ligne des briques dormantes, au jugement | **B** (P2) |
| `gsd-code-review` | Revue des fichiers modifiés | `vf-reviewer` → 2× `gsd-code-reviewer` (axes Standards et Spec) | R |
| `gsd-audit-fix` | Pipeline autonome audit → correction → commit | Contredit ADR-031 | I |
| `gsd-review` | Revue croisée des plans par d'autres IA (CLI externes) | ADR-061 : opt-in, non câblée | D |
| `gsd-plan-review-convergence` | Boucle « replanifier jusqu'à convergence » avec d'autres IA | Rejoint SEED-002 | D |

### 1.3 Tests

| Brique | Rôle | Couvert ? | Verdict |
|---|---|---|---|
| `gsd-add-tests` | Génère des tests unitaires et E2E d'une étape, après un plan validé par l'humain | Ligne des briques dormantes (« nyquist partiel ») | D. En automatique, `gsd-validate-phase` est plus ciblé : il remplace `add-tests` dans cette ligne |

### 1.4 Sécurité

Couverte en 1.2 (`gsd-secure-phase`).

### 1.5 Documentation et connaissance

| Brique | Rôle | Couvert ? | Verdict |
|---|---|---|---|
| `gsd-extract-learnings` | LEARNINGS.md d'une étape (décisions, leçons, surprises), lu par le planificateur des étapes suivantes | Ligne des briques dormantes, jamais déclenchée (0 fichier) | **B** (P1) |
| `gsd-docs-update` | 6 + 3 documents produit, vérifiés contre le code | Nœud `docs` de fin de mission (`docs-flow.md`). Interdit sur `vibeflow-os` | **B** (P2, déjà doctriné, hors vibeflow-os) |
| `gsd-map-codebase` | Cartographie `.planning/codebase/` (4 mappeurs en parallèle) | `docs-flow.md` famille code. La directive de dérive du moteur (« Run /gsd-map-codebase --paths ») n'a aucun consommateur | **B** (P2) |
| `gsd-ingest-docs`, `gsd-import` | Specs, ADR et PRD versés dans `.planning/` | `ingestion-flow.md`, confirmation humaine obligatoire | D |
| `gsd-graphify` | Graphe de connaissance | Refusé en Phase 24 | I |
| `gsd-mempalace-capture`, `gsd-mempalace-recall` | Mémoire MemPalace (produit tiers) | `consolidator` (ADR-052, ADR-057) | I |

### 1.6 UI et design

| Brique | Rôle | Couvert ? | Verdict |
|---|---|---|---|
| `gsd-ui-phase` | Contrat UI-SPEC.md avant le plan | Hook `plan:pre` du moteur (`workflow.ui_phase`, vrai par défaut). `vf-crafter` produit des specs | D. Le hook amont suffit ; redondant quand `vf-crafter` est passé |
| `gsd-spike` | Prototype de code jetable | `intent-routing.md` | D |
| `gsd-explore` | Idéation socratique | `superpowers:brainstorming` (que E1 doit internaliser) | D |

### 1.7 IA et évaluations

| Brique | Rôle | Couvert ? | Verdict |
|---|---|---|---|
| `gsd-ai-integration-phase` | AI-SPEC.md : choix du framework, recherche, plan d'éval | Hook `plan:pre` du moteur (`workflow.ai_integration_phase`, vrai par défaut) | D (le hook amont suffit) |

### 1.8 Jalons et feuille de route

| Brique | Rôle | Couvert ? | Verdict |
|---|---|---|---|
| `gsd-audit-milestone` | Confronte le jalon à son intention, contrôle l'intégration | Chaîne de clôture de `vf-dev-manager` (§Contrôle de flux) | **B** (P2, déjà doctriné) |
| `gsd-complete-milestone` | Archive le jalon | Même chaîne, confirmations internes | D (geste humain) |
| `gsd-cleanup` | Archive les dossiers d'étape | Même chaîne. Piège connu : archiver casse `check-divergence` | D |
| `gsd-milestone-summary` | Synthèse de jalon pour l'onboarding | Rien | **B** (P3) |
| `gsd-new-milestone`, `gsd-new-project`, `gsd-onboard` | Amorçages interactifs | `intent-routing.md`, `vf-new-lab`, `vf-split-planning` | D |
| `gsd-review-backlog`, `gsd-capture` | Backlog, graines, notes | `.planning/seeds/`, `BACKLOG.md` tenus à la main | D |

### 1.9 État et session

| Brique | Rôle | Couvert ? | Verdict |
|---|---|---|---|
| `gsd-pause-work`, `gsd-resume-work` | Passation de contexte | `vf-auto`, STATE, rapports de mission | D |
| `gsd-undo` | Revert sûr d'une étape ou d'un plan | Ligne des briques dormantes | D. Toujours humain, jamais automatique |
| `gsd-health` | Intégrité de `.planning/` | `check-state-integrity.sh`, `check-divergence.sh`, `check-mission-invariants.sh` | R (D en réparation) |
| `gsd-stats` | Statistiques | Rien d'utile | I |
| `gsd-thread` | Fils de contexte persistants | Mémoire, consolidator | I |

### 1.10 Workspace et ops

| Brique | Rôle | Couvert ? | Verdict |
|---|---|---|---|
| `gsd-ship` | PR + revue + merge | ADR-059 et ADR-064 : la PR est un geste VibeFlow ; le ship reste gaté humain | I |
| `gsd-pr-branch` | Branche de PR sans les commits `.planning/` | Contredit `commit_docs: true` et ADR-059 | I |
| `gsd-workspace`, `gsd-workstreams` | Espaces isolés et compartiments | `vf-split-planning`, `workstreams.md`, worktrees (ADR-064) | R |
| `gsd-update` | Mise à jour de GSD | `vf-update` | R |
| `gsd-config`, `gsd-settings` | Réglages | `gsd-run.sh config-set` | D |
| `gsd-surface`, `gsd-help` | Exposition des commandes | L'utilisateur ne tape jamais de `/gsd-*` | I |
| `gsd-inbox` | Tri des issues et PR GitHub | Fait à la main (clôture des issues 2026-10-29) | D |
| `gsd-profile-user` | Profil comportemental | Refusé en Phase 24 | I |
| `gsd-ns-context/-ideate/-manage/-project/-review/-workflow` (6) | Routeurs de namespace | Ce serait une couche de synonymes | I |

### 1.11 Agents non utilisés (25)

| Agent | Lignes | Appelé par (amont) | Verdict |
|---|---|---|---|
| `gsd-assumptions-analyzer` | 110 | discuss-phase en mode `assumptions` | **B** (P1, éclaireur du cadrage) |
| `gsd-integration-checker` | 477 | audit-milestone | **B** (P1, nœud de jointure et de fin de mission) |
| `gsd-nyquist-auditor` | 207 | validate-phase | B, via `gsd-validate-phase` |
| `gsd-ui-auditor` | 588 | ui-review | B, via `gsd-ui-review` |
| `gsd-codebase-mapper` | 856 | map-codebase, porte de dérive | B, via `gsd-map-codebase --paths` |
| `gsd-doc-writer` | 632 | docs-update | B, via le nœud `docs` (hors vibeflow-os) |
| `gsd-eval-auditor` | 192 | eval-review | B (P3), via `gsd-eval-review` |
| `gsd-dom-verifier` | 170 | capability `live-dom-uat` (`execute:wave:post`) | **B** (P3, labs web : armer `workflow.live_dom_uat`) |
| `gsd-debug-session-manager`, `gsd-debugger` | 422 + 1 280 | gsd-debug | À réparer (profondeur, §3) |
| `gsd-ui-researcher`, `gsd-ui-checker` | 475 + 418 | ui-phase | D (hook amont) |
| `gsd-framework-selector`, `gsd-ai-researcher`, `gsd-domain-researcher`, `gsd-eval-planner` | 159 + 117 + 150 + 155 | ai-integration-phase | D (hook amont) |
| `gsd-doc-classifier`, `gsd-doc-synthesizer` | 276 + 266 | ingest-docs | D (humain) |
| `gsd-roadmapper`, `gsd-project-researcher`, `gsd-research-synthesizer` | 785 + 617 + 265 | new-project, new-milestone | D (amorçage, utilisés hors du périmètre mesuré) |
| `gsd-code-fixer` | 771 | `gsd-code-review --fix` | R. ADR-031 : la correction ciblée passe par `vf-coder` |
| `gsd-intel-updater` | 340 | **aucun workflow** | I (orphelin côté amont) |
| `gsd-mempalace-curator` | 50 | ship:post MemPalace | I |
| `gsd-user-profiler` | 175 | profile-user | I |

### 1.12 Compte par verdict

| | Brancher | À la demande | Redondant | Inutile | Total |
|---|---|---|---|---|---|
| Skills | 13 | 24 | 9 | 18 | 64 |
| Agents | 8 (+2 à réparer : debug-session-manager, debugger) | 11 | 1 | 3 | 25 |

Les 13 skills **B** : verify-work, spec-phase, secure-phase, validate-phase, audit-uat, ui-review,
eval-review, forensics, extract-learnings, docs-update, map-codebase, audit-milestone,
milestone-summary. La réparation de `gsd-debug` (skill déjà utilisé) est comptée à part.

---

## 2. Branchements : déclencheur, condition machine, produit, consommateur, coût

Profondeurs : head = 0 (session principale), manager = 1, worker = 2, et les agents qu'un skill
lance depuis un worker = 3 (feuilles, sans `Agent`). Tous les déclencheurs ci-dessous tiennent dans
cette limite. La colonne « Prof. » indique où atterrit l'agent le plus profond.

| # | Brique | Qui, quand | Condition machine | Produit → consommateur | Coût (ordre de grandeur, non mesuré) | Gain | Prio | Prof. |
|---|---|---|---|---|---|---|---|---|
| 1 | `gsd-extract-learnings` | `vf-dev-manager` pose un nœud `learn-N` (deps=`revue-N`), en petit mandat `vf-coder` (ou en queue du nœud `docs`) | `{phase}-VERIFICATION.md` `status: passed` ET aucun `*-LEARNINGS.md` dans le dossier d'étape | LEARNINGS.md → `gsd-plan-phase` des étapes suivantes (`plan-phase.md:777`), le consolidator, le rapport | Inline, sans agent : 15–30 k tokens, 1–3 min | Le planificateur de N+1 reçoit enfin les décisions et surprises de N. Aujourd'hui cette entrée est toujours vide (0 fichier) | P1 | 2 |
| 2 | `gsd-audit-uat` | Le head à l'ouverture de session (`/vf-dev`), ou `vf-dev-manager` au démarrage de mission, en mandat lecture seule | ≥ 1 VERIFICATION `human_needed`/`gaps_found`, ou une UAT `status ≠ complete` (mesure du jour : 13) | Plan de test humain priorisé → le head le propose comme next step ferme | Sans agent, 127 lignes : 10–20 k tokens | 13 vérifications ouvertes sortent de l'invisibilité ; la recette repasse dans le flux | P1 | 1–2 |
| 3 | `gsd-validate-phase` (+ `gsd-nyquist-auditor`) | `vf-dev-manager`, nœud `nyq-N` après `exec-N`, en mandat `vf-coder` (il écrit des tests, ce n'est pas un juge) | `{phase}-VALIDATION.md` `nyquist_compliant: false` (15/20 aujourd'hui), ou `verdicts.nyquist` = `absent` dans le bloc de `vf-coder` | Tests ajoutés + VALIDATION.md à jour → revue `revue-N` et `vf-reviewer` | 1 agent : 40–80 k tokens, 5–15 min | Ferme la lacune que le gate constate aujourd'hui sans la combler | P1 | 3 (feuille) |
| 4 | `gsd-secure-phase` (+ `gsd-security-auditor`) | `vf-auditer`, à qui on ajoute l'outil `Skill`, l'invoque au lieu de l'agent nu, à l'étage de vérification (parallèle de la revue) | Le PLAN de l'étape porte un registre de menaces (`<threat_model>` / IDs `T-NN-NN`), ou le diff touche les globs « sécurité » de `MISSION-INVARIANTS.md`, ou `verdicts.secure` = `absent` | SECURITY.md avec `threats_open` → porte `ship:pre`, `vf-dev-manager`, preuve E6 | Inchangé par rapport à aujourd'hui (1 agent, 30–60 k) | Les menaces sont fermées sur disque et vérifiables (`threats_open: 0`), plus seulement décrites en prose. Le dispatch passe aussi d'un jugement à un fait | P1 | 3 (feuille) |
| 5 | `gsd-assumptions-analyzer` | `vf-dev-manager`, avant le premier tour de questions du cadrage (Pattern F : « un fait ne se demande jamais à l'humain, un éclaireur l'établit ») | Pas de `CONTEXT.md` dans le dossier d'étape au moment du cadrage | Hypothèses avec preuves dans le code → le manager ne garde que les vraies décisions | 1 agent, 110 lignes : 20–40 k, 2–5 min | Moins de questions posées à Samuel, aucun fait demandé. C'est l'outil qui manquait à Pattern F | P1 | 2 |
| 6 | `gsd-integration-checker` | `vf-dev-manager`, nœud `join-N` (en plus de `vf-reviewer`), ou nœud `integ` en fin de mission | ≥ 2 nœuds `exec-*` dans la mission, ou une étape de la ROADMAP qui `Depends on` une étape de la mission | Rapport d'intégration E2E → correction ciblée de `vf-coder` | 1 agent, 477 lignes : 40–80 k | La jointure (meilleur rendement mesuré en Phase 20 : 4 bloquants, 9 majeurs) gagne un juge de flux bout en bout, pas seulement de diff | P1 | 2 |
| 7 | `gsd-verify-work` | `vf-dev-manager` en mode superviser : il porte la conversation lui-même, comme le cadrage (il a AskUserQuestion, avec repli SendMessage(main)). En autonome : il pose UAT.md et escalade | `{phase}-VERIFICATION.md` `status: human_needed` après `exec-N` | UAT.md + verdict → clôture d'étape, `gsd-audit-uat` | Temps humain d'abord ; 30–60 k tokens | Six étapes `human_needed` aujourd'hui, jamais recettées. La « règle d'or » de `GSD-PIPELINE.md` §1 est violée en silence | P1 | 1 |
| 8 | `gsd-forensics` | Le head (sortie de manager) ou `vf-dev-manager` | Rapport typé `blocked` avec `decompte` (budget épuisé), `takeover` avec `orphans_count > 0`, ou mission `failed` | Rapport post-mortem → humain, puis mémoire | Sans agent, 285 lignes : 20–40 k | Un échec se comprend au lieu d'être rejoué | P2 | 1–2 |
| 9 | `gsd-map-codebase --paths` (+ `gsd-codebase-mapper`) | `vf-dev-manager`, nœud `map` avant le nœud `docs` | Directive de dérive du moteur (`codebase drift detected`, `action_required`) dans le retour de `vf-coder`, ou `.planning/codebase/STRUCTURE.md` plus ancien que le dernier changement de structure | `.planning/codebase/` à jour → `gsd-planner`, `vf-auditer` (CONCERNS) | 4 mappeurs en parallèle : 100–200 k, sauf en `--fast --focus` | CONCERNS.md et ARCHITECTURE.md restent vrais pour l'auditeur et le planificateur | P2 | 2 (depuis le manager) |
| 10 | `gsd-ui-review` (+ `gsd-ui-auditor`) | `vf-dev-manager`, en parallèle de `revue-N` | Le diff de `exec-N` touche des globs UI (`*.tsx`, `*.jsx`, `*.vue`, `*.svelte`, `*.css`, vues SwiftUI…) ET l'étage design est sauté (pas de DESIGN.md, donc pas de `vf-design-judge`) | UI-REVIEW.md noté → correction ciblée | 1 agent, 588 lignes : 40–80 k | Un regard visuel même sans direction artistique. Aujourd'hui une UI sans DESIGN.md n'a aucun juge | P2 | 3 (feuille) |
| 11 | `gsd-audit-milestone` (+ integration-checker) | `vf-dev-manager`, fin de jalon (déjà prescrit) | Toutes les étapes du jalon cochées dans la ROADMAP | MILESTONE-AUDIT → clôture humaine | 50–100 k | Déjà doctriné, rarement atteint ; à garder | P2 | 2 |
| 12 | `gsd-docs-update` (+ writer et verifier) | Nœud `docs` (déjà doctriné, `docs-flow.md`) | 4 déclencheurs factuels existants. Interdit sur vibeflow-os | Docs produit vérifiées | 9 rédacteurs + vérificateurs : 150–300 k | Déjà en place ; vérifier sur un lab produit qu'il tombe | P2 | 2 |
| 13 | `gsd-spec-phase` | `vf-dev-manager`, porté comme le cadrage | L'étape de la ROADMAP n'a ni `Success Criteria` ni IDs REQ | SPEC.md verrouillé → le cadrage ne pose plus de questions de périmètre | 30–60 k + temps humain | Moins de dérive de périmètre | P2 | 1 |
| 14 | Réparation de `gsd-debug` | Le manager dispatche lui-même `gsd-debug-session-manager` (prof. 2), qui lance `gsd-debugger` (prof. 3) | Mandat de debug (bug persistant, ADR-045) | Session de debug persistante | 100–250 k | Aujourd'hui la chaîne ne démarre pas depuis `vf-coder` (§3) | P2 | 3 |
| 15 | `gsd-dom-verifier` | Moteur, `execute:wave:post`, toggle `workflow.live_dom_uat` armé par le lab | Lab web (package.json avec next, vite…) ET MCP navigateur présent | DOM-VERIFY.md, additif, jamais bloquant | 1 agent par vague | Critères d'acceptation vérifiés dans un vrai DOM | P3 | 3 |
| 16 | `gsd-eval-review` (+ eval-auditor) | `vf-dev-manager` après `exec-N` | `AI-SPEC.md` présent dans le dossier d'étape | EVAL-REVIEW.md | 30–60 k | Les évals promises sont vérifiées | P3 | 3 |
| 17 | `gsd-milestone-summary` | Chaîne de clôture de jalon | Jalon archivé | Synthèse pour Willy et l'onboarding | 20–40 k | Passation entre co-mainteneurs | P3 | 1 |

`gsd-ui-phase` et `gsd-ai-integration-phase` ne demandent pas de nœud VibeFlow : leur hook `plan:pre`
est déjà armé par défaut. Il suffit de ne pas le désarmer.

---

## 3. Agents autorisés dans les allowlists mais jamais dispatchés

Allowlists sur `origin/main` : `vf-coder` en liste 18 `gsd-*`, `vf-dev-manager` 10,
`vf-design-manager` 1, `vf-reviewer` 1, `vf-auditer` 1. Sur ces 31 entrées, **17 agents distincts**
ne sont jamais partis. L'allowlist n'est **pas appliquée** à l'appel (mesuré le 2026-09-17).

| Agent | Allowlist | Pourquoi jamais dispatché |
|---|---|---|
| `gsd-assumptions-analyzer` | vf-coder | Le cadrage est passé au manager (Pattern F), et `discuss_mode: "discuss"` ne déclenche jamais le mode assumptions. Il est inscrit chez le mauvais agent |
| `gsd-codebase-mapper` | vf-coder | La directive de dérive du moteur n'a pas de consommateur ; `map-codebase` n'est jamais demandé |
| `gsd-code-fixer` | vf-coder | Par construction : la correction ciblée passe par `vf-coder` (ADR-031). Entrée morte |
| `gsd-debugger` | vf-coder | « Voie unique » : via le skill `gsd-debug`, dont la chaîne est session-manager → debugger. Depuis `vf-coder` (prof. 2), le session-manager atterrit en prof. 3, **sans `Agent`**, et ne peut pas lancer le debugger. Les 2 invocations de `gsd-debug` ont donné 0 dispatch |
| `gsd-integration-checker` | vf-coder, vf-dev-manager | Aucune prose ne le déclenche hors audit de jalon |
| `gsd-nyquist-auditor` | vf-coder | Passe seulement par validate-phase et le hook `verify:post`, jamais vu (verdicts `absent`) |
| `gsd-ui-researcher`, `gsd-ui-checker`, `gsd-ui-auditor` | vf-coder | Via ui-phase et ui-review. Aucune étape UI dans le périmètre mesuré (non mesuré dans le détail) ; `ui_review: false` ici |
| `gsd-framework-selector`, `gsd-ai-researcher`, `gsd-domain-researcher`, `gsd-eval-planner` | vf-coder | Condition « étape IA » jamais remplie |
| `gsd-doc-writer` | vf-dev-manager | `docs-update` est interdit sur vibeflow-os ; aucun autre lab mesuré n'a fait tomber le nœud `docs` |
| `gsd-doc-classifier`, `gsd-doc-synthesizer` | vf-dev-manager | `ingest-docs` est gaté humain et doit passer par le skill |
| `gsd-roadmapper` | vf-dev-manager | Amorçage seulement (new-project, new-milestone) |

**Cause commune.** `vf-coder.md` §Garanties pose la « voie unique » : on passe par le skill, jamais
par un agent nu. Son allowlist de 18 agents n'est donc qu'un repli « skill non invocable » qui ne se
produit jamais. **Gain le plus rapide :** déplacer `assumptions-analyzer` et `integration-checker`
dans le flux explicite du manager (n° 5 et 6), retirer de l'allowlist de `vf-coder` les entrées
mortes par construction (`code-fixer`, `codebase-mapper`, `debugger`, `assumptions-analyzer`), et
donner `Skill` à `vf-auditer` (n° 4).

---

## 4. Classement complet par rapport gain/coût, avec taille de réécriture E3

Taille E3 = lignes skill + workflow + agent(s) GSD (mesurées avec `wc -l`). Petite < 500,
moyenne 500–1 200, grosse > 1 200.

| Rang | Brique | Gain / coût | Lignes (skill + wf + agents) | Taille E3 |
|---|---|---|---|---|
| 1 | `gsd-extract-learnings` | Très élevé / très bas | 27 + 272 + 0 = 299 | petite |
| 2 | `gsd-audit-uat` | Élevé / très bas | 25 + 127 + 0 = 152 | petite |
| 3 | `gsd-assumptions-analyzer` (éclaireur du cadrage) | Élevé / bas | agent 110 (+ wf `discuss-phase-assumptions` 715, non requis) | petite |
| 4 | `gsd-secure-phase` (rebranchement de `vf-auditer`) | Élevé / nul (coût déjà payé) | 41 + 205 + 176 = 422 | petite |
| 5 | `gsd-validate-phase` | Élevé / moyen | 41 + 197 + 207 = 445 | petite |
| 6 | `gsd-integration-checker` (jointure, fin de mission) | Élevé / moyen | agent 477 | petite |
| 7 | `gsd-verify-work` | Élevé / temps humain | 44 + 939 + 0 = 983 | moyenne |
| 8 | `gsd-forensics` | Moyen / bas (rare) | 60 + 285 = 345 | petite |
| 9 | `gsd-ui-review` (labs UI sans DA) | Moyen / moyen | 38 + 214 + 588 = 840 | moyenne |
| 10 | `gsd-spec-phase` | Moyen / moyen | 65 + 559 = 624 | moyenne |
| 11 | Réparation de `gsd-debug` (profondeur) | Moyen / moyen | 58 + 297 + 422 + 1 280 = 2 057 | grosse |
| 12 | `gsd-map-codebase --paths` | Moyen / élevé | 87 + 505 + 856 = 1 448 | grosse |
| 13 | `gsd-audit-milestone` | Moyen / moyen (rare) | 42 + 391 + 477 = 910 | moyenne |
| 14 | `gsd-docs-update` (labs produit) | Moyen / élevé | 54 + 1 015 + 632 + 220 = 1 921 | grosse |
| 15 | `gsd-eval-review` | Bas (conditionnel) / bas | 38 + 172 + 192 = 402 | petite |
| 16 | `gsd-dom-verifier` | Moyen (web) / moyen | agent 170 (capability amont) | petite |
| 17 | `gsd-milestone-summary` | Bas / bas | 55 + 235 = 290 | petite |

Le **top 10** du résumé correspond aux rangs 1 à 10.

**Où plus de parallélisme paierait** (le plafond de 2 n'étant plus une contrainte) :

- L'étage de vérification après `exec-N` regroupe `vf-reviewer` (qui lance déjà 2 `gsd-code-reviewer`), `vf-auditer`/secure-phase, `ui-review`, `integration-checker` et `vf-design-judge`. Tous sont des juges en lecture seule : on peut les lancer dans un seul message, soit 4 à 6 agents.
- `validate-phase` écrit des tests sur un périmètre disjoint du code : il peut tourner en parallèle des juges, avec `isolation: worktree` si besoin.
- `map-codebase` lance nativement 4 mappeurs.
- Le panel `gsd-advisor-researcher` est déjà prévu ×3.
- Le pipelining N/N+1 permet de lancer `learn-N` et `assumptions(N+1)` en même temps qu'`exec(N+1)`.
- La config du lab dit déjà `max_concurrent_agents: 3`. La doctrine existante (`vf-reviewer` ×2, frontière parallèle) dépasse donc déjà le plafond de 2. Il est à mesurer (mémoire par agent), pas à présumer.

---

## 5. Ce qui ne doit pas être branché

| Brique | Pourquoi |
|---|---|
| `gsd-audit-fix`, `gsd-code-fixer` | Corrigent en autonomie : contredit ADR-031. La correction ciblée passe par `vf-coder` |
| `gsd-ship`, `gsd-pr-branch` | ADR-059 et ADR-064 ; ship toujours gaté humain ; `pr-branch` retire les commits `.planning/` alors que ce lab les commite |
| `gsd-autonomous`, `gsd-fast`, `gsd-ultraplan-phase` | Modes d'enchaînement (auto-approbation par la règle 5), aucune vérification, ou sortie du verrou et du DAG |
| `gsd-next`, `gsd-progress`, `gsd-manager`, `gsd-ns-*` (6) | Un routeur de plus au-dessus du head : la couche de synonymes supprimée en v2.33 |
| `gsd-undo` | Revert : geste humain seulement, jamais sur déclencheur |
| `gsd-review`, `gsd-plan-review-convergence` | CLI externes (Codex) ; injection constatée (« le dépôt jugé pilote le juge ») ; restent à la demande, et SEED-002 en reprend l'idée côté VibeFlow |
| `gsd-mempalace-*`, `gsd-graphify`, `gsd-profile-user` et leurs agents | Refusés (ADR-057, Phase 24) ; le consolidator est le canon |
| `gsd-intel-updater` | Aucun appelant amont. `intel.enabled: true` ne produit que `API-SURFACE.md` : la promesse de `docs-flow.md` §Frontière (« 5 JSON ») n'est pas tenue. À signaler, pas à brancher |
| `gsd-workspace`, `gsd-workstreams`, `gsd-update`, `gsd-config`, `gsd-settings`, `gsd-surface`, `gsd-help`, `gsd-stats`, `gsd-thread`, `gsd-health` | Ops déjà portées par VibeFlow (`vf-split-planning`, `vf-update`, `gsd-run.sh`, `check-state-integrity.sh`) ou sans valeur |
| Amorçages (`new-project`, `onboard`, `new-milestone`, `ingest-docs`, `import`, `complete-milestone`, `cleanup`) | Gestes humains rares, déjà routés. Aucun déclencheur automatique |

---

## 6. Règles de VibeFlow qui brident l'efficacité

1. **La « voie unique » (`vf-coder.md` §Garanties, `GSD-PIPELINE.md` §9).** Elle se justifie pour plan et exécution, où l'agent nu fait sauter des étages. Elle n'a pas de sens pour les **juges feuilles** (assumptions-analyzer, integration-checker, ui-auditor, security-auditor), qui n'ont aucun étage à sauter. Elle rend 18 entrées d'allowlist mortes et casse `gsd-debug` en profondeur. Proposition : restreindre la règle aux briques de cycle (plan, exécution).
2. **Le dispatch de `vf-auditer` « au jugement »** (« si l'étape touche sécurité, données, infra »). Il contredit `mission-flow.md` §3, qui exige un fait constatable. Fait disponible : le registre de menaces du PLAN.
3. **`vf-auditer` sans l'outil `Skill`.** Il ne peut appeler que l'agent nu, ce qui le prive de SECURITY.md et de la porte `threats_open` (4 SECURITY.md seulement).
4. **La confiance dans les hooks internes du moteur.** Nyquist, sécurité et revue après exécution sont délégués à un workflow de 1 400 lignes lu par un worker sonnet. Le témoin `verdicts` les montre `absent`. Le manager devrait poser ces étages en **nœuds explicites** du DAG, plutôt que d'espérer qu'un hook enfoui se déclenche.
5. **« Jamais d'heuristique mécanique sur les fichiers » pour l'étage design** (`vf-dev-manager.md` §Étage design). Elle est saine pour l'étage design complet, mais elle empêche un filet visuel automatique quand aucun DESIGN.md n'existe. Proposition : un filet `ui-review` sur les globs UI, réservé à ce cas.
6. **Le plafond de 2 en parallèle.** Il vient d'un crash non mesuré, alors que la doctrine (`vf-reviewer` ×2 plus frontière parallèle) et la config (`max_concurrent_agents: 3`) le dépassent déjà. À remplacer par une mesure de mémoire par agent.
7. **Les déclencheurs des briques dormantes rédigés au jugement** (« le QUOI n'est pas stabilisé », « blocage à comprendre »). Ce sont eux qui expliquent les 0 déclenchement. Chacun a un fait machine équivalent (§2, n° 8 et 13).

---

## 7. Non mesuré

- La cause exacte de l'absence des hooks `verify:post` (saut par le modèle, ou résolution des toggles via `--ws`) : je n'ai pas pu lancer `gsd-tools loop render-hooks`.
- La présence d'étapes UI ou IA dans le second projet du périmètre.
- Les coûts en tokens et en temps : ce sont des ordres de grandeur tirés de la taille des agents, aucun n'a été mesuré sur un run.
- La consommation mémoire par agent (pour le plafond de parallélisme).
