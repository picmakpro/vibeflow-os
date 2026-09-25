---
phase: 42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des
plan: 05
subsystem: governance-tooling
tags: [check-agents, invariants, doctrine, D-06, D-07, D-08, D-18, D-19, mutation-testing, python, bash]

# Dependency graph
requires:
  - phase: 42-04
    provides: "make_gate_mutant/okmut/komut (patron de mutation QUAL-01 a un fichier unique par cas), fraicheur du manifeste"
  - phase: 42-02
    provides: "vf-internal: true + marqueur Worker interne sur vf-test-orchestrator (forme D-18 a deux dispatcheurs)"
  - phase: 42-03
    provides: "SendMessage sur les managers"
provides:
  - "invariant_i1() (D-06), invariant_i4(), invariant_i7() — armes en ERREUR dans tous les modes (D-11), une ligne d'appel unique par invariant"
  - "parse_token (analyse pure, extrait d'analyze_token) et allowlist_agents(fmlines) — jamais un second tokenizer"
  - "invariant_i6() (D-07, TOUJOURS arme) et invariant_i5() (D-08, arme car ARBITRAGE-MAINTENIR) — armes en ERREUR dans tous les modes"
  - "T91/T91b/T92/T93/T94/T95/T96 (jumeaux positifs/negatifs) + mutations reelles sur plugin/mobile-test-team/agents/vf-test-runner.md (I1, I7), plugin/business-pilot-bundle/agents/vf-business-manager.md (I6), plugin/content-bundle/agents/content-clarity-judge.md (I5)"
  - "MUT-I1, MUT-I4, MUT-I5, MUT-I6, MUT-I7 tues (QUAL-01)"
  - "omitClaudeMd: true pose sur les quatre juges (quality-gate-client, content-clarity-judge, growth-quality-judge, vf-design-judge), un commit + bump patch separe par module"
affects: [VFDO-42-06]

# Actuals (#2632)
actuals:
  tokens: 5507
  tasks: 1
  commits: 1
plan_head_before: 6bb3cde

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "juger_mutation_reelle <id> <copie-originale> <copie-mutee> <jeton> : generalisation du patron T75 (mutation sur l'arbre reel, discriminance prouvee par cmp) pour toute mutation sur un porteur reel, invoquee via $CHECK --file (mode PAR DEFAUT — les invariants sont des erreurs dans tous les modes, D-11)"
    - "invariant_iN(base, ...) rend une LISTE de messages (jamais un booleen ni une exception) ; check_file() les etend a errors via UNE ligne d'appel unique par invariant (errors.extend(invariant_iN(...))), cible exclusive des mutants MUT-IN"
    - "parse_token(tok) analyse PURE, sans effet de bord ; analyze_token() devient une enveloppe qui appelle parse_token et ajoute son message a errors (texte inchange, T26-T41 verts) ; allowlist_agents(fmlines) consomme parse_token directement, jamais analyze_token (§ Don't Hand-Roll)"

key-files:
  created: []
  modified:
    - plugin/conductor/scripts/check-agents.sh
    - plugin/conductor/scripts/tests/test-check-agents.sh
    - plugin/business-pilot-bundle/agents/quality-gate-client.md
    - plugin/business-pilot-bundle/VERSION
    - plugin/business-pilot-bundle/module.json
    - plugin/business-pilot-bundle/CHANGELOG.md
    - plugin/business-pilot-bundle/README.md
    - plugin/content-bundle/agents/content-clarity-judge.md
    - plugin/content-bundle/VERSION
    - plugin/content-bundle/module.json
    - plugin/content-bundle/CHANGELOG.md
    - plugin/content-bundle/README.md
    - plugin/growth-bundle/agents/growth-quality-judge.md
    - plugin/growth-bundle/VERSION
    - plugin/growth-bundle/module.json
    - plugin/growth-bundle/CHANGELOG.md
    - plugin/growth-bundle/README.md
    - plugin/design-orchestrator/agents/vf-design-judge.md
    - plugin/design-orchestrator/VERSION
    - plugin/design-orchestrator/module.json
    - plugin/design-orchestrator/CHANGELOG.md
    - plugin/design-orchestrator/README.md
    - .planning/workstreams/gouvernance/phases/VFDO-42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des/42-CONTEXT.md
    - docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md

key-decisions:
  - "Tache 1 (I1, I4, I7) executee integralement et committee (23009b4, session precedente) — ces trois invariants ne dependent d'aucun arbitrage D-08."
  - "Tache 2 (checkpoint D-19/D-08) : la reprise de cette session a rejoue la sonde de la Tache 2 en premier geste (halt condition du mandat de reprise) : verdict ARBITRAGE-MAINTENIR, rc=0. La transcription de l'arbitrage dans 42-D19-MESURE.md (section « ## Arbitrage D-08 », Decision: maintenir) avait ete faite dans une session anterieure (commit 95a304d, hors du perimetre de ce plan) — cette session ne l'a pas re-ecrite, seulement rejouee et constatee."
  - "Tache 3 executee integralement, branche ARBITRAGE-MAINTENIR : etape 0 (omitClaudeMd: true sur les quatre juges, un commit + bump patch SECOND et separe par module, distinct du commit SendMessage deja pose en 42-02/42-03) puis invariant_i6 (TOUJOURS) et invariant_i5 (SEULEMENT SI MAINTENIR), chacun dans un commit separe sur le gate (item d de la mission : deux decisions gatees par des conditions differentes, deux commits distincts)."
  - "Analyse pure des allowlists : parse_token(tok, field, base) extrait d'analyze_token, rend (nom, agent_names, message_ou_None) sans effet de bord ; analyze_token devient une enveloppe qui ajoute le message a errors avec le texte EXACT d'avant (T26 a T41 inchanges, aucune erreur de syntaxe d'allowlist dupliquee). allowlist_agents(fmlines) consomme parse_token directement — jamais analyze_token — pour accumuler les noms d'agents d'un tools: Agent(...)/Task(...) sans message d'erreur."
  - "Remise en conformite de vingt et une fixtures preexistantes de test-check-agents.sh : dix fixtures manager-shaped (allowlist Agent(...)/Task(...) non vide, non vf-internal, sans SendMessage) recoivent SendMessage avant leur Agent(/Task( — T25, T28, T28b, T29, T30b, T31, T33, T35, T36, T53 ; onze fixtures juge-shaped (disallowedTools: Write, Edit sans allowlist de dispatch) recoivent omitClaudeMd: true — T59, T62-T66 (via mk_mcp_agent), T67, T70, T77/T78/T79/T82/T84/T85/T86 (via mk_conforme_agent), T80 (agent-listagents), T81, T83, T87, T90, MUT-F2. rc attendus et assertions inchanges dans tous les cas — verifie par relecture du diff et par la suite complete (147 OK, 0 KO)."
  - "Deux commits sur le gate pour la Tache 3 (au lieu d'un seul) : le premier pose I6 seul (toujours arme, independant de D-19), le second ajoute I5 (arme seulement parce que ARBITRAGE-MAINTENIR). Split reconstruit a partir de l'etat final unique initialement ecrit, en retirant precisement les elements I5 (fonction invariant_i5, sa ligne d'appel, son paragraphe d'en-tete, le bloc de test T93/MUT-I5, les onze fixtures juge-shaped) pour obtenir un etat intermediaire I6-only verifie vert (142 OK, 0 KO) avant de restaurer l'etat final pour le second commit (147 OK, 0 KO)."
  - "FABR-03 reste PARTIELLE au sens de REQUIREMENTS.md a l'issue de cette execution : I1, I4, I5, I6, I7 (locaux) sont armes et prouves, mais I2 et I3 (monde ferme, D-09) restent a 42-06 — la case FABR-03 de REQUIREMENTS.md n'est donc PAS cochee par ce plan (le plan lui-meme parle de « FABR-03 (partie locale) » dans ses success_criteria). 42-05 est en revanche coche dans ROADMAP.md : ce plan est complet."

patterns-established:
  - "Un checkpoint qui gate une tache sur un arbitrage humain absent doit etre rejoue MECANIQUEMENT (rc de la sonde, jamais une relecture en prose) avant tout travail de la tache suivante — applique au premier geste de cette session de reprise."
  - "Deux gestes gates par des conditions differentes (SendMessage inconditionnel vs omitClaudeMd conditionnel a un arbitrage) restent deux commits distincts, meme quand ils vivent dans le meme fichier et la meme tache de plan — reconstruit ici par retrait/restauration cible plutot que par staging partiel, pour un historique lisible."

requirements-completed: []

coverage:
  - id: D1
    description: "invariant_i1 (D-06) : vf-internal: true <-> marqueur « Worker interne » dans description:, dans les deux sens, tolerant a la forme a deux dispatcheurs nommes (D-18) — arme en ERREUR dans tous les modes"
    requirement: FABR-03
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-agents.sh#T91, T91b, MUT-I1"
        status: pass
    human_judgment: false
  - id: D2
    description: "invariant_i4 : disallowedTools ne tolere aucun jeton porteur d'un specifieur parenthese"
    requirement: FABR-03
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-agents.sh#T92, MUT-I4"
        status: pass
    human_judgment: false
  - id: D3
    description: "invariant_i7 : toute cle vf-mcp-* exige vf-requires citant mcp-servers (meme jointure que check-capability-activation.sh regle 4)"
    requirement: FABR-03
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-agents.sh#T95, MUT-I7"
        status: pass
    human_judgment: false
  - id: D4
    description: "Corpus reel (six plugin/*/agents, six plugin/*/AGENT.md, neuf blueprints) sous I1/I4/I5/I6/I7 armes : zero diagnostic invariant I, CI-REPLAY fail=0"
    requirement: FABR-05
    verification:
      - kind: integration
        ref: "check-agents.sh --strict --manifest-freshness=strict (+ --resolve-agents=strict) sur chaque plugin/*/agents et chaque plugin/*/AGENT.md, plus check-blueprints.sh — rejoues manuellement lors de cette execution, tous rc=0 (CI-REPLAY fail=0)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Checkpoint D-19/D-08 (Tache 2) : arbitrage de Samuel sur le maintien de D-08 — verdict ARBITRAGE-MAINTENIR (rc=0) constate au premier geste de cette session (transcription deja faite dans une session anterieure, commit 95a304d)"
    verification:
      - kind: manual
        ref: "sonde du plan, verbatim, rejouee contre 42-D19-MESURE.md : ARBITRAGE-MAINTENIR, rc=0"
        status: pass
    human_judgment: true
    rationale: "Arbitrage humain (session principale, decision deleguee par Willy au head, 2026-09-25) transcrit dans 42-D19-MESURE.md ; cette session l'a rejoue mecaniquement, jamais relu en prose seule."
  - id: D6
    description: "invariant_i6 (D-07, TOUJOURS) : manager (allowlist Agent(...)/Task(...) non vide, non vf-internal) sans SendMessage dans tools: — analyse pure allowlist_agents/parse_token"
    requirement: FABR-03
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-agents.sh#T94, T96, MUT-I6"
        status: pass
    human_judgment: false
  - id: D7
    description: "invariant_i5 (D-08, arme car ARBITRAGE-MAINTENIR) : juge (disallowedTools retire Write et Edit, allowlist de dispatch vide) sans omitClaudeMd: true"
    requirement: FABR-03
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-agents.sh#T93, T96, MUT-I5"
        status: pass
    human_judgment: false

# Metrics
duration: ~2h30
completed: 2026-09-25
status: complete
---

# Phase 42 Plan 05: Invariants I1/I4/I5/I6/I7 armes — checkpoint D-19/D-08 leve (ARBITRAGE-MAINTENIR) Summary

**Les cinq invariants locaux de la spec §4 (I1, I4, I5, I6, I7) sont armes en erreur dans tous les modes, jumeaux negatifs et mutations prouvees rouges pour chacun, corpus reel et blueprints conformes (CI-REPLAY fail=0). Le checkpoint D-19/D-08 (Tache 2) rend ARBITRAGE-MAINTENIR : les quatre juges recoivent `omitClaudeMd: true` et I5 s'arme selon sa definition D-08 telle quelle. La doctrine du motif 3 de l'arbitrage (« tout ce qu'un juge doit verifier vit dans sa grille, jamais dans .claude/rules ni dans CLAUDE.md ») est consignee a la section D-08 de 42-CONTEXT.md et dans la spec fabrique.**

## Performance

- **Duration:** ~35 min (session anterieure, Tache 1) + ~2h (cette session, reprise Tache 2/3 + doctrine)
- **Completed:** 2026-09-25
- **Tasks:** 3/3 executees (Tache 1 committee session anterieure ; Tache 2 rejouee et confirmee ; Tache 3 executee integralement, branche MAINTENIR)
- **Files modified:** 23 au total sur ce plan (2 pour le gate/tests, 20 pour les quatre modules de juges, 1 (42-CONTEXT.md) + 1 (spec fabrique) pour la doctrine — 21 hors gate/tests)

## Accomplissements (Tache 1, session anterieure — rappel)

- `invariant_i1(base, fm)` (D-06), `invariant_i4(base, fmlines)`, `invariant_i7(base, fm)` armes en erreur, T91/T91b/T92/T95, MUT-I1/I4/I7 tues. Voir commit `23009b4` pour le detail complet (deja documente dans une revision anterieure de ce SUMMARY, remplace ici par la vue complete des trois taches).

## Accomplissements (Tache 2 — reprise de cette session)

- Premier geste du mandat de reprise (halt condition) : rejeu verbatim de la sonde de la Tache 2 contre `42-D19-MESURE.md` → **`ARBITRAGE-MAINTENIR`, rc=0**. La transcription de la reponse de Samuel (section `## Arbitrage D-08`, `**Décision :** maintenir`) avait deja ete faite dans une session anterieure a celle-ci (commit `95a304d`, hors perimetre de ce plan — pas un fichier autorise a ce mandat). Cette session ne l'a pas modifiee, seulement rejouee et constatee.
- Aucune ecriture sur `42-D19-MESURE.md` par cette session (fichier en lecture seule pour ce mandat).

## Accomplissements (Tache 3 — cette session, branche ARBITRAGE-MAINTENIR)

**Etape 0 — `omitClaudeMd: true` sur les quatre juges :**
- `quality-gate-client.md` (business-pilot-bundle), `content-clarity-judge.md` (content-bundle), `growth-quality-judge.md` (growth-bundle), `vf-design-judge.md` (design-orchestrator) recoivent `omitClaudeMd: true` juste apres `memory: project`, rien d'autre dans leur frontmatter, corps inchanges (verifie par `git diff --stat` : 1 insertion par fichier).
- Un commit **par module**, avec un bump de patch **SECOND et SEPARE** du commit `SendMessage` deja pose en 42-02/42-03 : `business-pilot-bundle` v2.0.10 → v2.0.11, `content-bundle` v2.0.10 → v2.0.11, `growth-bundle` v2.0.10 → v2.0.11, `design-orchestrator` v1.5.9 → v1.5.10. VERSION, `module.json`, ligne Version du README, entree CHANGELOG citant l'arbitrage (canal + date) pour chacun.
- Les quatre suites de module (`test-business-pilot-bundle.sh`, `test-content-bundle.sh`, `test-growth-bundle.sh`, `test-design-orchestrator.sh`) rejouees : toutes vertes (14, 12, 12, 49 OK respectivement, 0 KO).

**Analyse pure des allowlists :**
- `parse_token(raw_tok, field, base)` extrait d'`analyze_token` : rend `(nom, agent_names, message_ou_None)` sans effet de bord. `analyze_token` devient une enveloppe qui appelle `parse_token` et ajoute son message a `errors` avec le texte EXACT d'avant (T26 a T41 verts, inchanges).
- `allowlist_agents(fmlines)` : jetons du champ `tools:` via `extract_raw_field`/`tokenize_field` (liste vide si champ absent ou profondeur non nulle) ; pour chaque jeton SANS message d'erreur dont le nom est un outil de dispatch (`Agent`/`Task`) avec une allowlist non vide, accumule ses noms — consomme `parse_token` directement, jamais `analyze_token` (§ Don't Hand-Roll, aucune erreur de syntaxe dupliquee).

**`invariant_i6` (D-07, TOUJOURS) :**
- Manager = `dispatch` non vide ET `vf-internal` ≠ « true ». Sans `SendMessage` dans `bare_tokens(fmlines, "tools")` → erreur « invariant I6 ». Ligne d'appel unique dans `check_file()`.
- T94 (jumeaux positif/negatif + forme interne + `Agent` nu, 4 fixtures) et mutation reelle sur `plugin/business-pilot-bundle/agents/vf-business-manager.md` (copie sans son jeton `SendMessage`) → rouge, restauree → verte. MUT-I6 tue.
- T96 : corpus reel (six `plugin/*/agents`, six `plugin/*/AGENT.md`) + `check-blueprints.sh` — zero diagnostic « invariant I6 », rc=0 partout.
- Commit separe : `feat(conductor): invariant I6 — managers avec SendMessage (FABR-03)`.

**`invariant_i5` (D-08, arme car ARBITRAGE-MAINTENIR) :**
- Juge = `Write` ET `Edit` dans `bare_tokens(fmlines, "disallowedTools")` ET `dispatch` vide. Sans `omitClaudeMd: true` → erreur « invariant I5 ». Un agent porteur d'une allowlist non vide (forme `vf-reviewer`/`vf-auditer`) reste hors classe juge quel que soit son `disallowedTools`.
- T93 (jumeaux positif/negatif + forme `vf-reviewer`, 3 fixtures) et mutation reelle sur `plugin/content-bundle/agents/content-clarity-judge.md` (deja porteur d'`omitClaudeMd: true` depuis l'etape 0 de cette meme tache — copie sans sa ligne) → rouge, restauree → verte. MUT-I5 tue.
- T96 etendu : zero diagnostic « invariant I5 » sur le corpus reel (les quatre juges portent deja le champ).
- Commit separe : `feat(conductor): invariant I5 — juges sans CLAUDE.md, arbitrage D-08 : maintenir (FABR-03)`.

**Remise en conformite (vingt et une fixtures preexistantes de `test-check-agents.sh`) :**
- Dix fixtures manager-shaped recoivent `SendMessage` avant leur `Agent(`/`Task(` : T25 (`vf-mixte.md`), T28 (`reed.md`), T28b (`lu.md`), T29 (`typo-nom.md`), T30b (`nom-ok.md`), T31 (`flow.md`, flow-list), T33 (`taskalias.md`, alias `Task`), T35 (`quote-tools.md`, tools: quote), T36 (`blank-block.md`, liste bloc), T53 (`vf-mixte2.md`).
- Onze fixtures juge-shaped recoivent `omitClaudeMd: true` : T59 (`silencieux.md`), T62-T66 (template `mk_mcp_agent`, 5 invocations), T67 (`mcp-tools-ok.md`), T70 (`juge-avec-barriere.md` — nommee explicitement par le plan), T77/T78/T79/T82/T84/T85/T86 (template `mk_conforme_agent`, reutilise par sept cas), T80 (`agent-listagents.md`), T81 (`agent-t81.md`), T83 (`agent-t83.md`), T87 (`agent-t87.md`), T90 (`T90_SRC`/`agent-t90`), MUT-F2 (`agent-mutf2.md`).
- rc attendus et assertions inchanges dans tous les cas — verifie par relecture du diff ET par la suite complete (147 OK, 0 KO).

**Deux commits pour le gate (item d) :**
- Le premier pose I6 seul (analyse pure + invariant_i6 + T94/T96(I6)/MUT-I6 + les dix fixtures manager-shaped) — verifie vert isolement (142 OK, 0 KO) avant restauration de l'etat final.
- Le second ajoute I5 (invariant_i5 + T93/MUT-I5 + T96 etendu + les onze fixtures juge-shaped) — 147 OK, 0 KO au final.

**Doctrine (motif 3 de l'arbitrage) :**
- Une phrase ajoutee a la section D-08 de `42-CONTEXT.md` et a la ligne I5 de `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md` : « tout ce qu'un juge doit verifier vit dans sa grille, jamais dans `.claude/rules` ni dans `CLAUDE.md` », avec la reference a l'arbitrage (session principale, decision deleguee par Willy au head, 2026-09-25). Commit de documentation separe.

## Verification globale (cette session)

- `bash plugin/conductor/scripts/tests/test-check-agents.sh` : **147 OK · 0 KO** (T91-T96, MUT-I1/I4/I5/I6/I7 tous verts).
- CI-REPLAY (trois etapes `--strict --manifest-freshness=strict` [+ `--resolve-agents=strict`] sur les six `plugin/*/agents` et `plugin/*/AGENT.md`, plus `check-blueprints.sh`) : **CI-REPLAY fail=0**.
- `bash plugin/conductor/scripts/check-instruction-budget.sh` : **0 depassement(s)** (31 fichiers, deux agents en `OK+LIGNES-EN-HAUSSE` — `growth-quality-judge.md` et `vf-test-orchestrator.md` — +1 ligne chacun, `omitClaudeMd`/deja pose, sans depassement).
- `bash plugin/conductor/scripts/tests/test-guard-agent-write.sh` : **14 OK · 0 KO**.
- `bash plugin/conductor/scripts/check-blueprints.sh` : **9 blueprint(s) conformes**.
- `bash scripts/check-gate-touche.sh` : **DECLARE** (14/14 marqueurs conformes).

## Task Commits

1. **Tache 1 (tdd) — invariants I1, I4, I7 armes en erreur, T91/T91b/T92/T95, MUT-I1/I4/I7** — `23009b4` (session anterieure)
2. **Tache 3, etape 0 (module)** — `26c9d9e` fix(business-pilot-bundle v2.0.11), `1ef8298` fix(content-bundle v2.0.11), `24b79c7` fix(growth-bundle v2.0.11), `b613e88` fix(design-orchestrator v1.5.10)
3. **Tache 3, gate — I6** — `9f645e2` feat(conductor): invariant I6 — managers avec SendMessage (FABR-03)
4. **Tache 3, gate — I5** — `e102394` feat(conductor): invariant I5 — juges sans CLAUDE.md, arbitrage D-08 : maintenir (FABR-03)
5. **Doctrine (motif 3)** — `9aff97c` docs(42): consigne la doctrine D-08 (motif 3) dans le contexte et la spec fabrique

**Plan metadata:** ce commit SUMMARY (docs).

## Files Created/Modified

- `plugin/conductor/scripts/check-agents.sh` — `parse_token`, `allowlist_agents`, `invariant_i5`, `invariant_i6`, section d'en-tete etendue
- `plugin/conductor/scripts/tests/test-check-agents.sh` — T93, T94, T96, MUT-I5, MUT-I6, remise en conformite de 21 fixtures preexistantes
- `plugin/business-pilot-bundle/{agents/quality-gate-client.md,VERSION,module.json,CHANGELOG.md,README.md}` — v2.0.11
- `plugin/content-bundle/{agents/content-clarity-judge.md,VERSION,module.json,CHANGELOG.md,README.md}` — v2.0.11
- `plugin/growth-bundle/{agents/growth-quality-judge.md,VERSION,module.json,CHANGELOG.md,README.md}` — v2.0.11
- `plugin/design-orchestrator/{agents/vf-design-judge.md,VERSION,module.json,CHANGELOG.md,README.md}` — v1.5.10
- `.planning/workstreams/gouvernance/phases/VFDO-42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des/42-CONTEXT.md` — phrase de doctrine D-08 (motif 3)
- `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md` — phrase de doctrine I5 (motif 3)

## Decisions Made

Voir `key-decisions` en frontmatter.

## Deviations from Plan

None sur la logique — la reconstruction en deux commits distincts pour I6/I5 (au lieu d'un seul geste d'ecriture) est un choix d'historisation demande par le plan lui-meme (action step 7 : « un second commit... SEULEMENT si arme »), pas une deviation de son contenu.

## Issues Encountered

None de nouveau dans cette session — le mandat de reprise a demarre par la halt condition (rejeu de la sonde) qui a confirme `ARBITRAGE-MAINTENIR`, rc=0, avant toute ecriture.

## User Setup Required

None — aucune configuration de service externe requise.

## Next Phase Readiness

- **42-05 est COMPLETE** (les trois taches executees) ; **FABR-03 reste PARTIELLE au sens de REQUIREMENTS.md** — I1, I4, I5, I6, I7 (locaux) sont armes, mais I2 et I3 (monde ferme, D-09) restent a 42-06. La case FABR-03 de REQUIREMENTS.md n'a donc pas ete cochee par ce plan.
- 42-06 (vague 4, decouverte recursive D-10, I2/I3 en monde ferme D-09, conductor en mineure) reste bloque en attendant l'orchestration du manager — ce plan ne l'execute pas.
- Relecture de Samuel demandee en PR (D-12) pour le module `design-orchestrator` (commit `b613e88`), comme deja pratique en 42-02/42-03.

---
*Phase: 42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des*
*Completed: 2026-09-25*
