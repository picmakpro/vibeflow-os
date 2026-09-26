---
phase: 43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-c
plan: 06
subsystem: infra
tags: [gate, skills, mcp, version-bump, changelog, release-notes, bootstrap, rejeu]

# Dependency graph
requires:
  - phase: 43-01
    provides: "43-BASE-PHASE.md (base de phase figée B43), check-skills.sh (tracer), manifeste à sept listes"
  - phase: 43-02
    provides: "detecter_derive()/ecart_nature_marqueurs(), corpus réel mesuré (26 avertissements, 11/21 SKILL.md)"
  - phase: 43-03
    provides: "question vf-nature des deux étages de skill-creator"
  - phase: 43-04
    provides: "plafond ADR-029 des SKILL.md (500 lignes), métrique bootstrap ratchet-socle, ligne de baseline @bootstrap:socle (2499), décision Q1 citée"
  - phase: 43-05
    provides: "grammaire vf-mcp-tools validée par check-agents.sh, serveur MCP nommé absent signalé jusqu'au journal d'installation"
  - phase: 43-07
    provides: "spec fabrique §1.2/§7.2 amendée (D-Q3), dev-orchestrator en patch v2.24.2"
provides:
  - "vf-calibrate/SKILL.md : dernier texte du dépôt à une seule clé MCP corrigé (FABR-10 c) — cible désormais les agents vf-mcp-consumer ET vf-mcp-tools"
  - "conductor v1.44.0 : README et CHANGELOG décrivant check-skills.sh, check-agents.sh à sept listes + grammaire vf-mcp-tools, check-instruction-budget.sh (plafond SKILL.md, métrique bootstrap ratchet-socle)"
  - "Rejeu de bout en bout vert : suites voisines, corpus réel (check-skills.sh + check-agents.sh), G-1, G-2, deux témoins lab frais sous HOME temporaire"
  - "Relevés de clôture de phase : Relecture Samuel, Couverture FABR-09, Résidus signalés, Artifacts this phase produces"
affects: []

# Actuals (#2632) — chars/4 sur le diff réalisé (Tâche 1 uniquement, Tâche 2 n'a modifié aucun
# fichier suivi hors .planning/), jamais un compte harnais.
actuals:
  tokens: 4153
  tasks: 2
  commits: 3
  plan_head_before: 31b41637cdfdbbe9b61517e8f7fe0eab06ab469a

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Comptes de documentation (scripts, suites) toujours re-mesurés à l'exécution, jamais recopiés d'un plan écrit avant coup — même patron que le correctif hors-plan de 43-01 (89→90 suites)"
    - "Bump de version prouvé contre la base de phase figée (B43), jamais contre la valeur sur disque au moment de la rédaction du plan"

key-files:
  modified:
    - plugin/conductor/skills/vf-calibrate/SKILL.md
    - plugin/conductor/VERSION
    - plugin/conductor/module.json
    - plugin/conductor/README.md
    - plugin/conductor/CHANGELOG.md

key-decisions:
  - "Bump mineur de conductor (v1.43.0 → v1.44.0) prouvé contre la valeur lue à la base de phase figée (B43=22179fa5), jamais un numéro deviné ni recopié du plan."
  - "Comptes de scripts/suites du README re-mesurés au jour de l'exécution (30 scripts, 31 suites) plutôt que recopiés des valeurs estimées par le plan (29/30) — écart dû à check-planning-consumers-registered.sh, déjà présent à la base de phase mais non catalogué, hors périmètre de cette correction."
  - "Aucune retouche des README.md/README.fr.md racine : leur compteur de suites (89→90) a déjà été corrigé hors-plan par 43-01 (commits b2a1f0c/31b4163, décision du head sous délégation technique de Willy, session principale, 2026-09-26) ; check-version-sync.sh est déjà vert (rc=0) à l'entrée de ce plan — rien à faire ici."
  - "Tâche 2 : aucun rougissement au rejeu (suites, corpus réel, G-1, G-2, labs frais) — aucune correction du CHANGELOG de conductor nécessaire, conformément à l'action de la tâche (elle ne modifie un fichier que si une incohérence apparaît)."

requirements-completed: [FABR-06, FABR-07, FABR-09, FABR-10]

coverage:
  - id: D1
    description: "vf-calibrate/SKILL.md ré-affirme les deux déclarations MCP (vf-mcp-consumer ET vf-mcp-tools) — dernier texte du dépôt à une seule clé (FABR-10 c, durcissement c)"
    requirement: "FABR-10"
    verification:
      - kind: other
        ref: "grep -c 'vf-mcp-tools' vf-calibrate/SKILL.md = 1 ; git diff -U0 B43 HEAD -- ce fichier ne touche aucune ligne description:/titre (0)"
        status: pass
    human_judgment: false
  - id: D2
    description: "conductor bumpé en mineure (v1.44.0) prouvé contre B43, README et CHANGELOG décrivant check-skills.sh, check-agents.sh (sept listes, grammaire vf-mcp-tools) et check-instruction-budget.sh (plafond SKILL.md, bootstrap ratchet-socle, citation mot pour mot), comptes de scripts/suites re-mesurés"
    requirement: "FABR-09"
    verification:
      - kind: other
        ref: "triade VERSION/module.json/README alignée sur v1.44.0 ; head -5 CHANGELOG.md = ## [v1.44.0] ; bash scripts/check-version-sync.sh rc=0 ; COMPTES-FIN scripts=30 suites=31 sans ligne COMPTE-FAUX ; BOOTSTRAP-DOC huit valeurs non nulles"
        status: pass
    human_judgment: false
  - id: D3
    description: "Rejeu de bout en bout vert : 15 suites voisines, budget d'instructions (SKILL.md + bootstrap), check-version-sync.sh, check-blueprints.sh, corpus réel (check-skills.sh + check-agents.sh sur tous les modules), G-1, G-2, aucun fichier .github touché, aucun merge amont dans la plage, deux témoins lab frais sous HOME temporaire"
    requirement: "FABR-09"
    verification:
      - kind: e2e
        ref: "REJEU-FIN (aucune ligne ROUGE) ; CORPUS-REEL fail=0 ; G2 rc=0 ; G1 rc=0 ; .github touché=0 ; MERGES-DANS-LA-PLAGE 0 ; LAB-FRAIS-FIN-OK"
        status: pass
    human_judgment: false
  - id: D4
    description: "SUMMARY de clôture portant les quatre sections requises (Relecture Samuel, Couverture FABR-09, Résidus signalés, Artifacts this phase produces), prêt pour la revue code owner de Samuel (plugin/dev-orchestrator, plugin/_internal, la baseline CODEOWNERS du budget d'instructions)"
    verification:
      - kind: other
        ref: "SAMUEL-PLAGE n=5 manquants=0 (commande de vérification du plan, rejouée) ; sections présentes dans ce fichier"
        status: pass
    human_judgment: true
    rationale: "La plage B43..HEAD sur plugin/dev-orchestrator, plugin/_internal et .planning/instruction-budget-baselines.tsv touche un chemin CODEOWNERS (baseline du budget d'instructions) — la PR qui porte ces commits exige la revue code owner de Samuel ou un contournement tracé (D-02bis), une décision humaine que ce SUMMARY prépare mais ne peut pas se substituer."

duration: ~1h10 (session unique)
completed: 2026-09-26
status: complete
---

# Phase 43 Plan 06: Clôture de phase — vf-calibrate à deux déclarations, conductor en mineure, rejeu de bout en bout Summary

**Dernier texte à une seule clé MCP corrigé (vf-calibrate), conductor bumpé en v1.44.0 avec une documentation qui dit exactement ce que font ses trois gates, phase rejouée intégralement verte (suites, corpus réel, G-1, G-2, deux labs frais).**

Base T2 : 99ddf85029b943ca5bbcb5f9804bbedbe82632f0

## Performance

- **Duration:** ~1h10 (session unique)
- **Tasks:** 2/2 completed
- **Files modified:** 5 (Tâche 1 : vf-calibrate/SKILL.md, VERSION, module.json, README.md, CHANGELOG.md de conductor ; Tâche 2 : aucun fichier suivi hors `.planning/`)
- **Commits:** 3 (mesuré : `git rev-list --count 31b41637cdfdbbe9b61517e8f7fe0eab06ab469a..HEAD`)

## Accomplishments

- `vf-calibrate/SKILL.md` (étape 3 de la migration, l.92) ne cible plus seulement les agents flaggés `vf-mcp-consumer` : la ré-affirmation de l'allowlist MCP vise désormais aussi les agents porteurs de `vf-mcp-tools` (allowlist nommée, ex. `vf-reviewer`) — dernier site du dépôt qui ne nommait qu'une seule des deux déclarations MCP (FABR-10, durcissement c).
- `conductor` passe de v1.43.0 à v1.44.0 (mineure, prouvée contre la valeur lue à la base de phase figée B43) : README et CHANGELOG décrivent désormais ce que font ses trois gates — `check-skills.sh` (nouvelle entrée, non câblé au `SessionStart` dans cette phase et pourquoi), `check-agents.sh` (manifeste étendu à sept listes, grammaire `vf-mcp-tools` validée), `check-instruction-budget.sh` (plafond des SKILL.md à 500 lignes, métrique bootstrap ratchet-socle avec la citation de l'arbitrage mot pour mot).
- Comptes de documentation re-mesurés au jour de l'exécution et corrigés partout où ils apparaissaient faux : titre « Scripts (30) », ligne « **Tests** : 31 suites », arborescence `scripts/ # 30 scripts … + tests/ (31 suites)`, notes de re-dérivation re-datées.
- Rejeu de bout en bout intégralement vert : 15 suites voisines (`test-check-skills.sh`, `test-check-agents.sh`, `test-check-instruction-budget.sh`, `test-guard-agent-write.sh`, `test-check-blueprints.sh`, `test-check-artifact-fidelity.sh`, `test-hook-exit-parc.sh`, `test-inject-mcp-tools.sh`, `test-check-capability-activation.sh`, `test-dev-orchestrator.sh`, `test-vibeflow-update.sh`, et les quatre suites de bundles/design-orchestrator), `check-instruction-budget.sh`, `check-version-sync.sh` (déjà vert grâce au correctif hors-plan de 43-01), `check-blueprints.sh` — aucune ligne ROUGE.
- Corpus réel jugé sous les deux gates sur tous les modules non doc-only : `CORPUS-REEL fail=0`.
- Gardes de gouvernance G-1 (`check-baseline-arbitrage.sh`) et G-2 (`check-gate-touche.sh`) conformes (`G1 rc=0`, `G2 rc=0`) ; aucun fichier `.github/` touché depuis B43 ; aucun merge amont dans la plage (`MERGES-DANS-LA-PLAGE 0`, seulement des merges internes de vagues).
- Deux témoins lab frais rejoués sous `HOME` temporaire (`LAB-FRAIS-FIN-OK`) : un lab neuf posé par l'installeur voit `check-skills.sh`/`check-agents.sh` verts et le journal d'installation relaie bien le `WARNING` nommé pour un serveur MCP (`XcodeBuildMCP`, cité via `vf-mcp-tools` sur `vf-reviewer.md`) absent de l'union des scopes — preuve vivante du durcissement FABR-10 (b).

## Task Commits

Each task was committed atomically:

1. **Tâche 1, étape 1 (durcissement c) : vf-calibrate ré-affirme les deux déclarations MCP** - `d61adab` (fix)
2. **Tâche 1, étapes 2-5 : conductor v1.44.0, README et CHANGELOG** - `99ddf85` (feat)
3. **Tâche 2 : rejeu complet, G-1/G-2, témoins lab frais, relevés de clôture (ce SUMMARY)** - commit séparé après ce fichier (`.planning/` uniquement)

**Plan metadata:** ce fichier + STATE/ROADMAP/REQUIREMENTS sont commités par l'orchestrateur après la vague (mode parallèle — worktree ; mandat de dispatch : ne pas toucher STATE.md/ROADMAP.md).

## Files Created/Modified

- `plugin/conductor/skills/vf-calibrate/SKILL.md` — ré-affirmation MCP à deux déclarations (1 ligne modifiée, aucune ligne `description:` ni titre touché)
- `plugin/conductor/VERSION` — v1.43.0 → v1.44.0
- `plugin/conductor/module.json` — `.version` v1.43.0 → v1.44.0
- `plugin/conductor/README.md` — nouvelle entrée `check-skills.sh`, entrées `check-agents.sh`/`check-instruction-budget.sh` élargies, comptes de scripts/suites re-mesurés (30/31), ligne Version
- `plugin/conductor/CHANGELOG.md` — entrée en tête `## [v1.44.0]`, résumé FABR-06/07/09/10, citations des décisions de Willy
- `.planning/workstreams/gouvernance/phases/VFDO-43-.../43-06-SUMMARY.md` — ce fichier (Base T2 consignée, relevés de clôture)

## Decisions Made

Voir `key-decisions` en frontmatter (bump prouvé contre B43, comptes re-mesurés, aucune retouche des README racine déjà corrigés par 43-01, aucune correction nécessaire au rejeu de la Tâche 2). Aucune décision architecturale nouvelle — toutes les valeurs numériques (version attendue, comptes de scripts/suites) sont dérivées par commande, jamais devinées.

## Deviations from Plan

None au sens des Règles 1-4 (aucun bug, aucune fonctionnalité critique manquante, aucun blocage, aucun changement architectural) — le plan a été exécuté tel qu'écrit. Deux écarts de mesure entre le texte du plan (rédigé avant exécution) et l'état réel du dépôt à l'exécution ont été rectifiés en suivant l'instruction du plan elle-même de rejouer les commandes de comptage plutôt que de recopier ses valeurs :

**1. [Ajustement de mesure, prescrit par le plan lui-même] Comptes de scripts/suites différents des valeurs écrites dans le plan**
- **Found during:** Tâche 1, étape 2 (lecture des comptes réels)
- **Issue:** le plan anticipait 29 scripts / 30 suites au moment de l'exécution (mesure de planification, 2026-09-25). La mesure réelle au moment de l'exécution est 30 scripts / 31 suites — écart de +1 sur chaque compte, dû à `check-planning-consumers-registered.sh` (et sa suite `test-skill-doc-paths.sh`), déjà présent à la base de phase figée (B43) mais jamais catalogué dans le README, hors périmètre de cette correction (aucun mandat de le documenter ici).
- **Fix:** les valeurs effectivement écrites dans le README sont les valeurs mesurées à l'exécution (30/31), conformément à l'instruction explicite du plan (« jamais un nombre deviné ni recopié d'ici »).
- **Files modified:** `plugin/conductor/README.md`
- **Verification:** `COMPTES-FIN scripts=30 suites=31` sans aucune ligne `COMPTE-FAUX`.
- **Committed in:** `99ddf85`

---

**Total deviations:** 0 auto-fixé au sens des Règles 1-4 ; 1 ajustement de mesure explicitement prescrit par le plan.
**Impact on plan:** Aucun — le plan demandait exactement ce rejeu de mesure avant écriture.

## Issues Encountered

None.

## User Setup Required

None - aucune configuration de service externe requise.

## Relecture Samuel

Plage complète, prouvée par commande (`B43=22179fa50ad2c420ccdc6e3d7eb0fb6f0d054703`,
`git log --format='%h %s' "$B43"..HEAD -- plugin/dev-orchestrator plugin/_internal .planning/instruction-budget-baselines.tsv`, base de phase figée toujours ancêtre de HEAD) :

- `3f5a8fa` — chore(dev-orchestrator v2.24.2): durcissements MCP (FABR-10) [43-07]
- `450ab9c` — merge(43-05): intègre le durcissement MCP conservé (FABR-10) [vague 2, merge interne]
- `9141997` — fix(dev-orchestrator): valeur vf-mcp-tools malformée refusée à l'install (FABR-10 a) [43-05]
- `c3a62c9` — feat(conductor): métrique bootstrap ratchet-socle et ligne @bootstrap:socle du budget d'instructions (FABR-09) [43-04] — chemin CODEOWNERS (`.planning/instruction-budget-baselines.tsv`) : la ligne ajoutée est `@bootstrap:socle	0	2499`, citée mot pour mot « décision déléguée par Willy au head (/vf-decide), AskUserQuestion session principale, 2026-09-26 » — revue code owner de Samuel ou contournement tracé requis (D-02bis, `CLAUDE.local.md`)
- `551ac21` — fix(dev-orchestrator): serveur nommé absent signalé jusqu'au journal d'installation (FABR-10 b, c) [43-05]

Aucun autre commit de la plage ne touche `plugin/dev-orchestrator`, `plugin/_internal` ou la baseline du budget d'instructions.

**Constat T23 à T31** : ces neuf cas de découverte du scope global (union `.mcp.json` ∪ `~/.claude.json`) sont documentés dans l'en-tête de `test-inject-mcp-tools.sh` depuis la Phase 21 mais n'ont jamais existé dans le code de la suite — fantômes, restaurés seulement pour T32/T33 par 43-05. La restauration complète reste hors périmètre de la Phase 43, laissée à la revue de Samuel (déjà signalé par `43-05-SUMMARY.md`).

**Changement de comportement de l'installeur (relais WARNING/ERROR)** : `vibeflow-update.sh` (`inject_lab_mcp_into_agents`) ne jette plus stdout ET stderr de l'injecteur — stdout reste jeté (verbeux, routine), chaque ligne `WARNING:`/`ERROR:` de stderr est désormais relayée dans le journal d'installation. Le best-effort est inchangé (la fonction rend toujours 0). Preuve vivante rejouée dans ce plan : le témoin lab frais de la Tâche 2 montre le `WARNING` nommant `XcodeBuildMCP` (absent de l'union des scopes, cité via `vf-mcp-tools` sur `vf-reviewer.md`) apparaître dans le journal d'installation d'un lab neuf.

## Couverture FABR-09

FABR-09 est couverte en entier par la Phase 43 (volet manifeste/champs de skills : 43-01 ; volet SKILL.md + bootstrap : 43-04 ; documentation et bump de version : ce plan) :

- **Manifeste daté étendu à sept listes** (`check-agents-manifest.json`) : `champs_frontmatter_skills` s'ajoute aux six listes natives de la Phase 42, validée identiquement par `check-agents.sh` et `check-skills.sh` (43-01).
- **Plafond des `SKILL.md`** : 500 lignes (fichier entier, hors modules doc-only), bloquant, aucun seuil d'avertissement — `DEPASSEMENT-SKILL-ADR029` (43-04). Mesure du jour, rejouée dans ce plan : `BILAN-SKILLS : 21 SKILL.md, 0 depassement(s) du plafond 500, 0 non verifiable(s), 4 exclu(s)`.
- **Métrique bootstrap, option ratchet-socle** : socle du bootstrap (fermeture `resolve-deps.sh conductor` + skill `installer` + commandes du plugin) borné par la ligne de baseline `@bootstrap:socle` (`.planning/instruction-budget-baselines.tsv`, valeur `0	2499`) : toute hausse au-dessus de cette ligne bloque (`DEPASSEMENT-BOOTSTRAP`, rc 1 sous ratchet armé) ; une mesure au-dessus du plafond ADR-029 de 2000 tokens mais sans hausse sur la ligne publie `AU-DESSUS-PLAFOND-ADR029`, non bloquant — le plafond ADR-029 de 2000 tokens reste un objectif, retour sous 2000 inscrit au BACKLOG (commit `433fea0`, section « Ramener le socle du bootstrap sous 2 000 tokens (ADR-029) — DIFFÉRÉ (2026-09-26) »).
  décision déléguée par Willy au head (/vf-decide), AskUserQuestion session principale, 2026-09-26
  Mesure du jour rejouée dans ce plan (Tâche 2) : `BOOTSTRAP : 2499 tokens estimes (octets/4) sur socle (18 fichiers), plafond 2000, ligne 2499, verdict AU-DESSUS-PLAFOND-ADR029` — identique au bit près à la mesure de 43-04-SUMMARY.md (2499 tokens, 9997 octets, 18 fichiers). Écart : aucun.
- **Documentation** (ce plan) : README et CHANGELOG de conductor décrivent les trois gates et l'option ratchet-socle avec la citation mot pour mot, prouvé par la sonde `BOOTSTRAP-DOC` (huit valeurs non nulles).

## Résidus signalés

- **G-1 ne voit pas une ligne de baseline AJOUTÉE** : `check-baseline-arbitrage.sh` ne classe que les lignes présentes à la fois à la base ET à HEAD de la plage jugée — la ligne `@bootstrap:socle` (43-04) n'est gardée que par sa citation et la revue de Samuel (chemin CODEOWNERS) ; seules ses hausses FUTURES seront couvertes par G-1.
- **Socle du bootstrap au-dessus du plafond ADR-029** (2499 tokens contre 2000) : écart entériné par le ratchet-socle, non bloquant (`AU-DESSUS-PLAFOND-ADR029`), retour sous 2000 tokens inscrit au BACKLOG (commit `433fea0`).
- **`check-skills.sh` non câblé au `SessionStart`** : décision de plan, à poser avec la mise en conformité du corpus (backlog `e36e6f2`).
- **Liste de dérive du corpus réel** (43-02, sous la règle Q-PORTEE) : 26 avertissements « derive » sur 11/21 `SKILL.md`, 0 « ecart » — laissée non corrigée, alimente le backlog `e36e6f2` avec la liste détaillée publiée par `43-02-SUMMARY.md`.
- **`--verify` de l'injecteur `inject-mcp-tools.sh` inchangé sur une valeur `vf-mcp-tools` malformée** : le mode lecture-seule `--verify` (comparaison du `tools:` final aux sources) n'a pas été durci par 43-05 pour signaler explicitement une valeur malformée rencontrée en relecture — seul le mode d'injection (écriture) refuse (rc 1). Résidu hors périmètre de ce plan.
- **Harnais de `test-check-agents.sh`** : les 16 appels historiques (Phase 42) du helper de mutation `make_gate_mutant` en substitution de commande (`$(...)`) perdent le comptage d'un refus dans le sous-shell créé — seul `MUT-M1` (43-05) l'appelle directement (sortie redirigée vers un fichier, refus compté dans le shell de la suite, prouvé par `MUT-M1-REFUS-COMPTE`). La nouvelle suite `test-check-skills.sh` n'appelle jamais le helper en substitution de commande (constat vérifié le 2026-09-26 : `grep -c '\$(make_gate_mutant' plugin/conductor/scripts/tests/test-check-agents.sh` = 16 — toujours vrai à l'exécution de ce plan). Correction reportée à un plan séparé.
- **Troncature à 1 536 caractères des descriptions non gatée** : résidu de portée documentaire signalé par le plan, non vérifié indépendamment par ce plan (hors de son `files_modified`) — reporté tel quel.
- **Fidélité des clés `vf-*` des skills sur les runtimes tiers non mesurée** : `check-artifact-fidelity.sh` (`FIELDS`) couvre les clés d'agent (`vf-mcp-consumer`, `vf-mcp-tools`, `vf-requires`, etc.) mais pas encore les clés `vf-nature`/`ecrit`/`vf-rubrique-juge`/marqueurs des `SKILL.md` posées par cette phase — vérifié le 2026-09-26 (`grep -n '^FIELDS' check-artifact-fidelity.sh`, aucune clé de skill présente).
- **Échéance du manifeste daté** : six listes `verifie_le: 2026-09-23` (`valide_jours: 30`) périment à partir du **2026-10-24** ; la septième (43-01) périme à sa `verifie_le` + 31 jours. À l'exécution de ce plan (2026-09-26), aucune liste n'est périmée (`check-agents.sh --manifest-freshness=strict` a rendu rc=0, pas 3, précondition de la Tâche 2 satisfaite) — **aucun rafraîchissement n'a eu lieu** dans ce plan, aucun commit de rafraîchissement à consigner.

## Artifacts this phase produces

| Symbole / chemin | Nature | Posé par |
|---|---|---|
| `plugin/conductor/scripts/check-skills.sh` (options `--skills-dir=`, `--file`, `--strict`, `--allow-empty`, `--hook`, `--third-party-prefix=`, `--no-third-party-prefix`) | nouveau gate | 43-01 |
| `plugin/conductor/scripts/tests/test-check-skills.sh` (T1 à T31 et `test-check-skills:T32`, T26 en T26a à T26h ; MUT-S1 à MUT-S3, MUT-SD1, MUT-SD2, MUT-DR1 à MUT-DR3 ; gardes du harnais MUT-SYNTAXE et MUT-REFUS-COMPTE) | nouvelle suite | 43-01, 43-02 |
| clés de frontmatter des skills `vf-nature`, `ecrit`, `vf-rubrique-juge`, `vf-gate-bloquant`, `vf-livrable-tiers`, `vf-couche-qualite` ; ensemble `VIBEFLOW_SKILL_FIELDS` | contrat de clés (costly) | 43-01 |
| liste de manifeste `champs_frontmatter_skills` (septième liste de `check-agents-manifest.json`) | manifeste daté | 43-01 |
| `decouvrir_skills()`, `valider_nature()`, `valider_ecrit()`, `invariant_procedure()` | check-skills.sh | 43-01 |
| `detecter_derive()`, `ecart_nature_marqueurs()`, `lignes_de_portee()`, `marqueurs_constates()`, `MOTIFS_MARQUEURS`, constantes `DERIVE_PROSE_MIN_DISTINCTS = 2` et `DERIVE_TITRE_MIN = 1` (règle Q-PORTEE, décision déléguée par Willy au head (/vf-decide), AskUserQuestion session principale, 2026-09-26) | check-skills.sh | 43-02 |
| `T107` (manifeste sans septième liste), `T108` à `T115`, `MUT-M1` (appel direct du helper), garde `MUT-M1-REFUS-COMPTE`, `valider_mcp_tools()` (lignes brutes, règle d'extraction commune avec l'injecteur, ordre trim puis déquotage) | check-agents.sh et sa suite | 43-01, 43-05 |
| `VF_SKILL_LINE_CAP`, verdict `DEPASSEMENT-SKILL-ADR029`, `BILAN-SKILLS`, `SKILL-1` à `SKILL-6`, `MUT-8` à `MUT-10` | check-instruction-budget.sh et sa suite | 43-04 |
| `VF_BOOTSTRAP_TOKEN_CAP`, ligne `BOOTSTRAP :`, verdicts `DEPASSEMENT-BOOTSTRAP` (bloquant) et `AU-DESSUS-PLAFOND-ADR029` (non bloquant), clé de baseline `@bootstrap:socle` (option ratchet-socle, citée, signalée à Samuel), `BOOT-1` à `BOOT-5`, `MUT-11`, `MUT-12` | métrique bootstrap | 43-04 |
| `malformed_found`, refus ERROR + rc 1 d'une vf-mcp-tools malformée ; déquotage d'une paire de guillemets et règle d'extraction commune (parité avec le gate pour toute valeur) ; message honnête de serveur absent et sources nommées ; `T16` durci, `T22a` à `T22j`, `test-inject-mcp-tools:T32` à `test-inject-mcp-tools:T34`, `MUT-A` | inject-mcp-tools.sh et sa suite | 43-05 |
| relais WARNING/ERROR dans `inject_lab_mcp_into_agents` ; `T55`, `T56` | vibeflow-update.sh et sa suite | 43-05 |
| spec fabrique §1.2 et §7.2 amendées | documentation | 43-07 |
| question vf-nature des deux étages de skill-creator | prompts | 43-03 |
| `plugin/conductor/skills/vf-calibrate/SKILL.md` : ré-affirmation MCP à deux déclarations (dernier site, FABR-10 c) | documentation | 43-06 |
| conductor v1.44.0 (README, CHANGELOG documentant les trois gates et le bootstrap ratchet-socle), skill-creator en mineure, dev-orchestrator en patch v2.24.2 | versions de module | 43-06, 43-03, 43-07 |

## Next Phase Readiness

- FABR-06, FABR-07, FABR-09 et FABR-10 sont couvertes en entier par la Phase 43 ; ce plan clôt la phase avec un rejeu de bout en bout vert et les relevés de PR.
- `requirements.mark-complete` n'a PAS été appelé par cet exécuteur (mode parallèle — worktree ; mandat de dispatch : ne pas toucher STATE.md/ROADMAP.md/REQUIREMENTS.md, l'orchestrateur les met à jour après la vague — précédent établi par 43-01/43-02/43-04/43-05).
- La PR de la Phase 43 exige la revue code owner de Samuel sur le commit `c3a62c9` (43-04, ligne `@bootstrap:socle` de `.planning/instruction-budget-baselines.tsv`), ou un contournement tracé (D-02bis).
- Blocage de jalon inchangé : aucune exécution du jalon gouvernance avant la clôture de `fiabilite-v1.0` (rappel non modifié par ce plan) ; conductor est partagé avec `fiabilite` — la renumérotation au rebase après un merge de `fiabilite` change uniquement le numéro attendu, jamais l'ordre ni le contenu du commit de bump.
- Aucun blocage connu pour la suite (PR, revue, merge).

---
*Phase: 43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-c*
*Completed: 2026-09-26*

## Self-Check: PASSED

- Fichiers modifiés (5/5) trouvés sur disque : `plugin/conductor/skills/vf-calibrate/SKILL.md`, `plugin/conductor/VERSION`, `plugin/conductor/module.json`, `plugin/conductor/README.md`, `plugin/conductor/CHANGELOG.md`.
- Commits `d61adab`, `99ddf85` trouvés dans `git log --oneline --all`.
- Tâche 1, verify 1 : `grep -c vf-mcp-tools` = 1 ; diff description:/titre = 0.
- Tâche 1, verify 2 : `vb=v1.43.0`, `att=v1.44.0`, `v=v1.44.0` (match) ; triade et README alignés ; `head -5 CHANGELOG.md` = `## [v1.44.0]` ; `check-skills.sh` présent dans README et CHANGELOG ; `bash scripts/check-version-sync.sh` rc=0.
- Tâche 1, verify 3 (COMPTES-FIN) : `scripts=30 suites=31`, aucune ligne `COMPTE-FAUX`.
- Tâche 1, verify 4 (BOOTSTRAP-DOC) : huit valeurs, toutes non nulles.
- Tâche 2, verify 1 (REJEU-FIN) : aucune ligne `SUITE-ROUGE`/`BUDGET-ROUGE`/`VERSION-SYNC-ROUGE`/`BLUEPRINTS-ROUGE`.
- Tâche 2, verify 2 : `CORPUS-REEL fail=0`.
- Tâche 2, verify 3 : `G2 rc=0`, `G1 rc=0`, `.github` touché = 0, `MERGES-DANS-LA-PLAGE 0`.
- Tâche 2, verify 4 : `LAB-FRAIS-FIN-OK`.
- Acceptance criteria SAMUEL-PLAGE : `n=5 manquants=0` (commande rejouée, cinq commits réels de la plage tous cités dans la section « Relecture Samuel »).
