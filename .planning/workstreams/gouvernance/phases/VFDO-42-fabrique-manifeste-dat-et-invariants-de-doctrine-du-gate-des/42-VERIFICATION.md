---
phase: VFDO-42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des
verified: 2026-09-25T00:00:00Z
status: human_needed
score: 5/5 must-haves verified (FABR-01 à FABR-05)
covered_files:
  - ".github/workflows/ci.yml"
  - ".planning/workstreams/gouvernance/REQUIREMENTS.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des/42-01-PLAN.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des/42-01-SUMMARY.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des/42-02-PLAN.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des/42-02-SUMMARY.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des/42-03-PLAN.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des/42-03-SUMMARY.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des/42-04-PLAN.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des/42-04-SUMMARY.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des/42-05-PLAN.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des/42-05-SUMMARY.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des/42-06-PLAN.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des/42-06-SUMMARY.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des/42-CONTEXT.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des/42-D19-MESURE.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des/42-DISCUSSION-LOG.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des/42-PATTERNS.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des/42-RESEARCH.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des/42-VALIDATION.md"
  - "plugin/conductor/CHANGELOG.md"
  - "plugin/conductor/README.md"
  - "plugin/conductor/VERSION"
  - "plugin/conductor/module.json"
  - "plugin/conductor/references/team-kernel.md"
  - "plugin/conductor/scripts/check-agents-manifest.json"
  - "plugin/conductor/scripts/check-agents.sh"
  - "plugin/conductor/scripts/tests/test-check-agents.sh"
covered_digest: "v1:sha256:46eec6a0bec5338428d3c425f65066046742d413d0e980152c5b10d9c2000cf2"
behavior_unverified: 0
overrides_applied: 0
human_verification:
  - test: "Relecture Samuel (D-12) des commits listés au SUMMARY 42-06 (mobile-test-team 0ab324b, design-orchestrator f820f08/b613e88, business-pilot-bundle 26c9d9e, content-bundle 1ef8298, growth-bundle 24b79c7) et du commit CODEOWNERS .github/workflows/ci.yml (4d69837, 42-04, W5) — au moins l'un des deux (revue de Samuel ou contournement explicite tracé), jamais un simple constat."
    expected: "Approbation ou contournement tracé de Samuel sur le chemin CODEOWNERS `.github/`, et ratification (ou objection) sur les modules de sa polarité avant merge de la PR."
    why_human: "CLAUDE.md exige la revue de Samuel (ou un contournement explicite tracé) sur .github/ — un grep ne peut pas constater une approbation humaine qui n'a pas encore eu lieu."
  - test: "Vérifier que la prohibition « MUST NOT rendre la CI verte en désarmant/rétrogradant/exemptant un invariant I1-I7 au lieu de corriger le corpus » tient, au-delà des vérifications automatiques déjà faites par ce rapport (aucun mécanisme d'exemption trouvé dans check-agents.sh, corpus corrigé par de vrais commits de fond)."
    expected: "Aucune liste d'exemption, aucun contournement d'invariant caché dans le diff de la PR."
    why_human: "Le plan lui-même déclare cette prohibition `unresolved` — sonde spec-less sans contrôle câblé ; ma vérification par grep (aucune occurrence de mécanisme d'exemption) est un indice, pas une preuve exhaustive sur l'intégralité du diff."
  - test: "Vérifier que le CHANGELOG/commits n'attribuent jamais l'arbitrage D-08 (armement d'I5) à une décision humaine sans la nuance « décision de cadrage de Claude sous délégation explicite de Willy, Samuel non consulté »."
    expected: "Toute mention d'arbitrage D-08 dans CHANGELOG, commits ou SUMMARY porte cette attribution précise."
    why_human: "Vérifié par grep sur les occurrences trouvées (CHANGELOG.md:26,49 portent bien la formule) — mais le plan déclare cette prohibition `unresolved` (pas de contrôle câblé sur l'ensemble des artefacts de la PR), donc laissée à la relecture humaine par construction du plan."
---

# Phase VFDO-42: Fabrique — manifeste daté et invariants de doctrine du gate des agents — Verification Report

**Phase Goal:** Le gate des agents (`check-agents.sh`) lit ses listes de référence — outils, champs, types natifs, modèles, modes, niveaux d'effort — dans un **manifeste daté** et rend **INDÉTERMINÉ** quand ce manifeste est périmé ; il tient les invariants de doctrine I1 à I7 et découvre les agents récursivement.
**Verified:** 2026-09-25
**Status:** human_needed
**Re-verification:** No — initial verification (first VERIFICATION.md for this phase; all 6 plans have SUMMARY.md)

## Goal Achievement

### Observable Truths

| # | Truth (FABR requirement) | Status | Evidence |
|---|---------|------------|----------|
| 1 | **FABR-01** — Les six listes de référence de `check-agents.sh` vivent dans un manifeste daté versionné (`check-agents-manifest.json`), source unique, sans copie de repli ; chaque liste porte `verifie_le` + `source` ; manifeste absent/illisible = refus explicite | ✓ VERIFIED | `plugin/conductor/scripts/check-agents-manifest.json` existe, contient les 6 listes (`outils`, `champs_frontmatter`, `types_natifs`, `modeles`, `modes_permission`, `niveaux_effort`) chacune avec `verifie_le`/`source`/`valeurs` ; `charger_manifeste()` (l.335) + jeton `MANIFESTE-ILLISIBLE` (l.415) dans `check-agents.sh` |
| 2 | **FABR-02** — Manifeste périmé rend le gate INDÉTERMINÉ (exit 3) en CI (`--manifest-freshness=strict`), avertissement chez l'utilisateur, jamais un refus sur liste fermée | ✓ VERIFIED | `manifeste_perime()` (l.387), jetons `MANIFESTE-PERIME`/`DATE-FUTURE`, `VF_MANIFEST_FRESHNESS` ; les 4 étapes `check-agents` de `.github/workflows/ci.yml` (l.267, 297, 325, 2060) passent toutes `--manifest-freshness=strict` |
| 3 | **FABR-03** — Le gate refuse les violations des invariants I1 à I7 (I2/I3 sous `--resolve-agents=strict` seulement), chaque invariant a son jumeau négatif et sa mutation prouvée rouge | ✓ VERIFIED | `invariant_i1..i7` tous définis et câblés (`errors.extend(invariant_iN(...))` × 7, greps confirmés) ; suite `test-check-agents.sh` rejouée par le vérificateur : **166 OK · 0 KO**, mutants MUT-I1, MUT-I2, MUT-I3, MUT-I4, MUT-I5, MUT-I6, MUT-I7 tous « TUE » ; T91-T96 (I1,I4,I5,I6,I7), T100-T102 (I2,I3) verts ; monde fermé réel rejoué par le vérificateur : `MONDE-FERME fail=0` (mutations réelles sur vf-test-orchestrator.md/vf-test-runner.md confirmées par le plan et re-jouées vertes après restauration) |
| 4 | **FABR-04** — La découverte des agents est récursive, exclusions (dossiers cachés, `-references/`, fichiers tiers) prouvées par test | ✓ VERIFIED | `decouvrir_agents()` (l.291, `os.walk(..., followlinks=False)`, 2 élagages distincts) ; plus de `glob.glob` à un niveau (`grep -c` = 0) ; T97/T98/T99, MUT-D1/MUT-D2 verts dans le rejeu ; témoin lab frais réel rejoué par le vérificateur : `LAB-RECURSIF-OK` (`.claude/agents/conductor-references/*.md` posé par l'installeur réel jamais pris pour un agent) |
| 5 | **FABR-05** — Corpus du dépôt passe `--strict` et `--resolve-agents=strict` avec les invariants armés ; un commit par module touché avec bump patch ; T76 corrigé | ✓ VERIFIED | Rejeu monde fermé réel : `fail=0` ; versions sur disque confirmées : mobile-test-team v1.4.6, design-orchestrator v1.5.10, business-pilot-bundle/content-bundle/growth-bundle v2.0.11 (chacune avec un commit dédié, hashes vérifiés existants : `0ab324b`, `f820f08`/`b613e88`, `26c9d9e`, `1ef8298`, `24b79c7`) ; `conductor` v1.43.0 sur `VERSION`/`module.json`/README ligne Version, cohérents ; CHANGELOG `## [v1.43.0]` en tête ; T76 vert (`✓ T76` × 2 dans le rejeu) ; `check-blueprints.sh` → 9 blueprints conformes |

**Score:** 5/5 truths verified (0 present-behavior-unverified, 0 overrides)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `plugin/conductor/scripts/check-agents-manifest.json` | manifeste daté, 6 listes + `valide_jours`/`rafraichissement` | ✓ VERIFIED | Présent, structure conforme, `verifie_le: 2026-09-23`, `valide_jours: 30` (échéance 2026-10-23, cohérent avec la dette signalée au STATE.md) |
| `plugin/conductor/scripts/check-agents.sh` | `decouvrir_agents`, `index_agents`, `invariant_i1..i7`, `construire_univers_dispatch`, `invariant_i2`, `invariant_i3` | ✓ VERIFIED | Toutes les fonctions présentes et câblées dans la boucle principale (greps ligne par ligne confirmés) |
| `plugin/conductor/scripts/tests/test-check-agents.sh` | T77-T102, MUT-F1/F2/D1/D2/D20/I1-I7 | ✓ VERIFIED | Suite rejouée par le vérificateur : 166 OK · 0 KO, tous les mutants cités « TUE » |
| `plugin/conductor/VERSION` / `module.json` / `README.md` | v1.43.0 synchronisés | ✓ VERIFIED | `cat VERSION` = v1.43.0 ; `module.json .version` = v1.43.0 ; ligne Version README = v1.43.0 |
| `plugin/conductor/CHANGELOG.md` | entrée `## [v1.43.0]` en tête | ✓ VERIFIED | Présente, décrit manifeste/fraîcheur/7 invariants/découverte récursive/corpus |
| `plugin/conductor/references/team-kernel.md` | ligne Mobile documente `vf-test-orchestrator` worker interne | ✓ VERIFIED | `grep '^| Mobile'` confirme le texte attendu |
| `.github/workflows/ci.yml` | 4 étapes `check-agents` avec `--manifest-freshness=strict`, 1 étape monde fermé avec `--resolve-agents=strict` | ✓ VERIFIED | Lignes 267, 297, 325, 2060 (fraîcheur) ; ligne 306-325 (monde fermé, un `--agent-registry-dir` par `plugin/*/agents`) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|----|--------|---------|
| `decouvrir_agents()` | boucle principale + `index_agents()` + univers du monde fermé | une seule fonction de découverte | ✓ WIRED | `index_agents()` (l.309) et `construire_univers_dispatch()` (l.860) appellent tous deux `decouvrir_agents()` — pas de second mécanisme de parcours trouvé |
| `.github/workflows/ci.yml` (étape monde fermé) | `invariant_i2` / `invariant_i3` | `--resolve-agents=strict` + `--agent-registry-dir` par `plugin/*/agents` | ✓ WIRED | Étape CI reproduite localement par le vérificateur (`MONDE-FERME fail=0`) sur les 6 dossiers réels du dépôt |
| Sonde `ARBITRAGE-*` (42-05 Tâche 2) | armement d'I5 en Tâche 3 de 42-06 | rejeu verbatim de la sonde, branchement conditionnel du texte README/CHANGELOG | ✓ WIRED | `42-D19-MESURE.md` confirme `ARBITRAGE-MAINTENIR` (arbitrage D-08, 2026-09-25) ; CHANGELOG/README citent bien les sept invariants (jamais « six invariants ») |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Suite complète du gate | `bash plugin/conductor/scripts/tests/test-check-agents.sh` | `166 OK · 0 KO` | ✓ PASS |
| Témoin lab frais (installeur réel) | script scratchpad reproduisant `resolve-deps.sh` + `vibeflow-update.sh install` + `check-agents.sh --strict --manifest-freshness=strict` | `LAB-RECURSIF-OK` | ✓ PASS |
| Monde fermé réel (6 `plugin/*/agents`) | script scratchpad reproduisant l'étape CI (`--strict --resolve-agents=strict --manifest-freshness=strict` × 6 dossiers avec tous les registres) | `MONDE-FERME fail=0` | ✓ PASS |
| T76 (kernel non contredit par le gate) | `bash .../test-check-agents.sh \| grep T76` | 2 lignes `✓ T76` | ✓ PASS |
| `check-gate-touche.sh` (G-2) | `bash scripts/check-gate-touche.sh` | `DECLARE`, `rc=0` | ✓ PASS |
| `check-instruction-budget.sh` | idem | `0 depassement(s)` | ✓ PASS |
| `check-version-sync.sh` | idem | tout synchronisé (v2.66.0, 17 modules), triade conductor v1.43.0 alignée | ✓ PASS |
| `check-blueprints.sh` | idem | `9 blueprint(s)` conformes | ✓ PASS |
| Aucun bump racine | `git diff --name-only <merge-base> HEAD -- VERSION marketplace.json plugin.json README.md README.fr.md` | 0 fichier | ✓ PASS |
| Commits de relecture Samuel cités au SUMMARY | `git log -1 --format=... <hash>` × 7 hashes | tous existent, sujets cohérents avec le SUMMARY | ✓ PASS |
| `dev-orchestrator` intact | `git log origin/main..HEAD -- plugin/dev-orchestrator` | sortie vide | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| FABR-01 | 42-01 | Manifeste daté, source unique, refus explicite | ✓ SATISFIED | Voir Truth #1 ; REQUIREMENTS.md le marque déjà `Complete` |
| FABR-02 | 42-04 | Fraîcheur → INDÉTERMINÉ en CI, avertissement utilisateur | ✓ SATISFIED | Voir Truth #2 ; REQUIREMENTS.md le marque déjà `Complete` |
| FABR-03 | 42-05, 42-06 | I1-I7 armés, jumeaux négatifs, mutation rouge | ✓ SATISFIED | Voir Truth #3 ; REQUIREMENTS.md **case non cochée** — bookkeeping à faire par l'orchestrateur post-vérification (le SUMMARY 42-06 le documente explicitement comme mandat de l'orchestrateur, pas du plan) |
| FABR-04 | 42-06 | Découverte récursive, exclusions prouvées | ✓ SATISFIED | Voir Truth #4 ; REQUIREMENTS.md **case non cochée**, même remarque |
| FABR-05 | 42-02, 42-03, 42-06 | Corpus conforme, commits/bumps par module, T76 corrigé | ✓ SATISFIED | Voir Truth #5 ; REQUIREMENTS.md **case non cochée**, même remarque |

Aucun requirement orphelin trouvé (`grep -E "Phase 42"` sur REQUIREMENTS.md ne renvoie que FABR-01..05, tous déjà couverts par un plan).

### Anti-Patterns Found

Fichiers modifiés par la phase scannés (`check-agents.sh`, `test-check-agents.sh`, `CHANGELOG.md`, `README.md`, `team-kernel.md`, `module.json`, `VERSION`) : aucun marqueur de dette (`TBD`/`FIXME`/`XXX`) non référencé, aucun `TODO`/`HACK`/`PLACEHOLDER`, aucune implémentation vide, aucun stub détecté. Le seul hit `XXX` (`CHANGELOG.md:1507`, `DEC-XXX`) est une convention de numérotation historique pré-existante, sans rapport avec cette phase.

**🛑 Blocker:** aucun.
**⚠️ Warning:** aucun bloquant technique — voir la section Human Verification ci-dessous pour les deux prohibitions `unresolved` du plan 42-06 (sondes spec-less sans contrôle câblé, laissées à la relecture par construction du plan lui-même).
**ℹ️ Info:** REQUIREMENTS.md n'a pas encore ses cases FABR-03/04/05 cochées ni sa ligne de traçabilité passée à `Complete` — geste de clôture attendu de l'orchestrateur, pas un gap technique (documenté explicitement dans le SUMMARY 42-06, section « Next Phase Readiness »).

### Human Verification Required

Cette phase est de nature infrastructure/tooling (gate de gouvernance, aucun élément utilisateur). Conformément à la règle de scoping des phases infra (`verifier-phase-gates.md`), l'UAT est auto-passée — sauf que le plan 42-06 lui-même déclare deux prohibitions `must_haves.prohibitions` en statut `unresolved` (« sonde spec-less, sans contrôle câblé ») et une clause `human_judgment: true` explicite dans sa propre couverture (relecture éditoriale/doctrinale de Samuel, D-12). Ces trois points ne sont pas des étapes utilisateur fabriquées : ce sont des points de jugement que le plan lui-même route vers la relecture PR plutôt que vers un gate machine. Voir la liste structurée en frontmatter (`human_verification`).

### Gaps Summary

Aucun gap technique trouvé : les cinq exigences FABR-01 à FABR-05 sont vérifiées directement dans le code (fonctions présentes, câblées, testées) et par ré-exécution indépendante des suites et témoins (166/0 KO, `LAB-RECURSIF-OK`, `MONDE-FERME fail=0`, gates G-2/budget/version-sync/blueprints tous verts). Le seul point ouvert est le bookkeeping de `REQUIREMENTS.md` (cases FABR-03/04/05 à cocher) et la relecture humaine de Samuel sur les chemins qu'elle concerne — attendus par construction du plan, pas des échecs de vérification.

---

*Verified: 2026-09-25*
*Verifier: Claude (gsd-verifier)*
