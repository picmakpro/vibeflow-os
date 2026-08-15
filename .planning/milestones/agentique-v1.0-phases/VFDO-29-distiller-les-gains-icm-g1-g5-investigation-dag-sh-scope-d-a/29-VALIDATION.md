---
phase: 29
slug: distiller-les-gains-icm-g1-g5-investigation-dag-sh-scope-d-a
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-15
---

# Phase 29 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | suites bash maison (`test-*.sh`, conventions du repo : cas verts/rouges, mutations cmp-attestées) |
| **Config file** | none — chaque suite est autoporteuse sous `plugin/<module>/scripts/tests/` |
| **Quick run command** | `bash plugin/conductor/scripts/tests/test-dag.sh` (suite du mécanisme à ne pas régresser) |
| **Full suite command** | `for t in plugin/conductor/scripts/tests/test-*.sh plugin/dev-orchestrator/scripts/tests/test-*.sh; do bash "$t" || exit 1; done` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash plugin/conductor/scripts/tests/test-dag.sh` + la suite du script touché par la tâche
- **After every plan wave:** Run la commande full suite ci-dessus
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| T-29-01-1 | 29-01 | 1 | ICMD-01, ICMD-02 | T-29-01-01, T-29-01-02 | Le socle `--scope` est intact et la baseline est **exécutée**, jamais présumée depuis une lecture de code | regression + doc/grep | `bash plugin/conductor/scripts/tests/test-dag.sh` · `git diff --name-only -- plugin/conductor/scripts/dag.sh plugin/conductor/scripts/tests/test-dag.sh \| wc -l` · `grep -rn "27/D-13" plugin/ reports/` | ✅ existe (suite du socle, 33 cas) | ⬜ pending |
| T-29-01-2 | 29-01 | 1 | ICMD-01 | T-29-01-03 | Seul `REQUIREMENTS.md` bouge sous `.planning/` — structure GSD intacte (ADR-055) | doc/grep | `grep -c '^- \[ \] \*\*ICMD-' .planning/REQUIREMENTS.md` · `git status --porcelain .planning/ \| grep -v "REQUIREMENTS.md\|ROADMAP.md\|STATE.md\|phases/VFDO-29-" \| wc -l` | N/A (ledger markdown) | ⬜ pending |
| T-29-02-1 | 29-02 | 2 | ICMD-03, ICMD-05 | T-29-02-01, T-29-02-02, T-29-02-04 | Wrapper git durci (une seule invocation nue, dans le wrapper) · chemins quotés · plancher `NON VÉRIFIABLE` sur cible vide | unit/bash | `bash plugin/conductor/scripts/tests/test-check-map-drift.sh` · `bash plugin/conductor/scripts/check-map-drift.sh --path "$(mktemp -d)"; echo $?` (attendu **3** + `NON VÉRIFIABLE`) | ❌ Wave 0 — naît avec le script (tâche 1) | ⬜ pending |
| T-29-02-2 | 29-02 | 2 | ICMD-04 | T-29-02-04, T-29-02-06 | Discriminance des deux paires prouvée par **mutation** attestée par `cmp`, jamais déclarée | unit/bash + mutation | `bash plugin/conductor/scripts/tests/test-check-map-drift.sh` (≥ 18 cas, ≥ 2 mutations) · `grep -c 'cmp -s' plugin/conductor/scripts/tests/test-check-map-drift.sh` | ❌ Wave 0 (même fichier, étendu) | ⬜ pending |
| T-29-02-3 | 29-02 | 2 | ICMD-06 | T-29-02-03 | Aucun mode correctif (ADR-031) · bornes de non-couverture écrites en en-tête | unit/bash + grep | `bash plugin/conductor/scripts/check-map-drift.sh --help \| grep -c "Bornes"` · `grep -v '^#' plugin/conductor/scripts/check-map-drift.sh \| grep -cE -- '--update\|--fix\|--write'` (attendu **0**) | ❌ Wave 0 (même fichier, étendu) | ⬜ pending |
| T-29-03-1 | 29-03 | 2 | ICMD-07 | T-29-03-01, T-29-03-03 | Zéro ligne modifiée dans le socle · la bullet est un **cache**, la clause « le disque gagne » reste dernière | regression + doc/grep | `bash plugin/conductor/scripts/tests/test-dag.sh` · `grep -c '^- NE charge PAS' plugin/dev-orchestrator/references/mission-contracts.md` (attendu **1**) · `git diff --name-only -- plugin/conductor/scripts/dag.sh \| wc -l` | ✅ existe (suite du socle) | ⬜ pending |
| T-29-03-2 | 29-03 | 2 | ICMD-08 | T-29-03-04, T-29-03-05, T-29-03-06 | Miroir tenu à l'octet · aucun agent au plafond touché · aucune adoption de label externe | doc/manual + `cmp`/`wc -l` | `cmp -s plugin/reference/content/methodology/patterns/03-agents.md docs/reference/methodology/patterns/03-agents.md` · `wc -l plugin/dev-orchestrator/agents/vf-dev-manager.md plugin/validator/AGENT.md` (attendu **250**/**250**) · `grep -rn "Interpretable Context Methodology\|méthodologie ICM\|label ICM" plugin/ docs/` | N/A (doctrine markdown) | ⬜ pending |
| T-29-03-3 | 29-03 | 2 | ICMD-09 | T-29-03-02, T-29-03-04 | La règle est bornée par ADR-031 (consigner, pas amender en autonome) · déposée en `references/`, jamais inline dans un agent au plafond | doc/manual + `wc -l` | `wc -l plugin/dev-orchestrator/agents/vf-dev-manager.md plugin/validator/AGENT.md` · `git diff --numstat -- plugin/dev-orchestrator/references/mission-flow.md` (attendu `1<TAB>0`) · `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` | ✅ existe (suite du module) | ⬜ pending |
| T-29-04-1 | 29-04 | 2 | ICMD-10 | T-29-04-01, T-29-04-02, T-29-04-04 | Idempotence prouvée à l'octet · aucun geste destructif acquis · un seul chemin d'écriture | unit/bash | `bash plugin/conductor/scripts/tests/test-scaffold-docs.sh` · `grep -v '^#' plugin/conductor/scripts/scaffold-docs.sh \| grep -c '> "\$path"'` (attendu **1**) | ❌ Wave 0 — première suite du scaffolder (tâche 1) | ⬜ pending |
| T-29-04-2 | 29-04 | 2 | ICMD-11 | T-29-04-02, T-29-04-05 | Flag d'index refuse un dossier inexistant (sortie 2) plutôt que de le créer · l'index ne s'auto-liste pas | unit/bash | `bash plugin/conductor/scripts/tests/test-scaffold-docs.sh` (≥ 17 cas) · `grep -c '_index.md' plugin/dev-orchestrator/references/_index.md` (attendu **0**) | ❌ Wave 0 (même fichier, étendu) | ⬜ pending |
| T-29-04-3 | 29-04 | 2 | ICMD-10, ICMD-11 | T-29-04-03 | Aucune écriture sous `.planning/` (ADR-055), prouvée par fixture comparée à l'octet | unit/bash + fixture | `bash plugin/conductor/scripts/tests/test-scaffold-docs.sh` (≥ 19 cas) · `git diff --name-only -- plugin/planning-core/references/compartments.md \| wc -l` (attendu **0**) | ❌ Wave 0 (même fichier, étendu) | ⬜ pending |
| T-29-05-1 | 29-05 | 3 | ICMD-12 | T-29-05-02, T-29-05-04 | Plafond de densité tenu · aucun signal de la grille sacrifié · l'invocation câblée est **réelle** (0 ou 3, jamais 64) | unit/bash + `wc -l` | `wc -l plugin/validator/AGENT.md` (attendu **≤ 250**) · `bash plugin/conductor/scripts/check-agents.sh --strict` · `grep -c "check-map-drift" plugin/validator/AGENT.md` (≥ 2) | ✅ existe (`test-check-agents.sh`) | ⬜ pending |
| T-29-05-2 | 29-05 | 3 | ICMD-12 | T-29-05-03, T-29-05-05, T-29-05-06 | Compteur de suites **re-dérivé** par la commande de découverte de la CI · release racine non prise | gate/bash | `bash scripts/check-version-sync.sh` · `find plugin scripts -type f -path '*/tests/test-*.sh' \| wc -l` vs `grep -o '[0-9][0-9]* suites' README.md \| head -1` · `git diff --name-only main...HEAD -- VERSION plugin/.claude-plugin/plugin.json .claude-plugin/marketplace.json \| wc -l` (attendu **0**) | ✅ existe (gate racine) | ⬜ pending |
| T-29-05-3 | 29-05 | 3 | ICMD-12 | T-29-05-01, T-29-05-07 | Aucun finding corrigé automatiquement (ADR-031) · l'humain tranche utile/bavard avant distribution | **human-check** (checkpoint bloquant) | `bash plugin/conductor/scripts/check-map-drift.sh --path .` (exécution réelle, findings présentés) puis verdict humain « approuvé » | N/A (checkpoint) | ⬜ pending |

**Continuité d'échantillonnage** : 13 tâches, **12** portent un `<automated>` exécutable ; la seule
exception est le checkpoint humain terminal (T-29-05-3), qui est précédé de deux tâches
automatisées — aucune séquence de 3 tâches consécutives sans vérification automatique.

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test-dag.sh` vert AVANT tout geste de la phase (baseline de non-régression `--scope`, T1-T33) — infrastructure existante, aucun stub à créer. Porté par la `<precondition>` de **29-01 tâche 1**, re-vérifié en `<precondition>` de **29-03 tâche 1**.
- [ ] `plugin/conductor/scripts/tests/test-check-map-drift.sh` — **MANQUANTE**, naît AVEC son script en **29-02 tâche 1** (jamais après).
- [ ] `plugin/conductor/scripts/tests/test-scaffold-docs.sh` — **MANQUANTE** : `scaffold-docs.sh` n'a aujourd'hui **aucune** suite. Elle naît en **29-04 tâche 1** et couvre l'extension **et** le comportement préexistant (les 4 stubs d'hier), sans quoi la non-régression du scaffolder serait supposée au lieu d'être prouvée.
- [ ] `bash plugin/dev-orchestrator/scripts/tests/test-check-doc-drift.sh` vert avant **29-02** (`<precondition>` de la tâche 1) : c'est le harnais dont la nouvelle suite copie la structure de fixtures.

**Conséquence de distribution** : +2 suites → le compteur « N suites » des deux README racine passe
de 52 à 54, re-dérivé (jamais recopié) par **29-05 tâche 2**, gaté par `scripts/check-version-sync.sh`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Lisibilité de la bullet « NE charge PAS » et de sa règle de composition | ICMD-07 | Un gabarit se juge à sa remplissabilité : « un manager saurait-il la remplir sans poser de question ? » ne se teste pas en bash — sa présence, sa forme et le budget de 30 lignes, si | Relire `plugin/dev-orchestrator/references/mission-contracts.md` §Digest ; vérifier `grep -c '^- NE charge PAS'` = 1 et que le bloc de gabarit tient en ≤ 30 lignes. Présenté au checkpoint **29-05 tâche 3**. |
| Justesse du seuil de la règle d'édition-à-la-source (deux occurrences) et du comportement en autonome | ICMD-09 | C'est un arbitrage de gouvernance, pas un fait vérifiable : seul l'humain peut dire si le seuil est le bon | Relire `plugin/conductor/references/team-kernel.md` §Règles d'instanciation ; vérifier `wc -l` ≤ plafonds sur les deux agents saturés. Présenté au checkpoint **29-05 tâche 3**. |
| Findings réels du gate sur ce dépôt : **utiles ou bavards ?** | ICMD-03, ICMD-04 | Un gate advisory qui remonte du bruit sera ignoré ; le distribuer avant d'avoir tranché rejouerait le motif de la Phase 28. **Aucun finding n'est corrigé** (ADR-031) | `bash plugin/conductor/scripts/check-map-drift.sh --path .` puis verdict humain. Le réglage se fait dans les **bornes** du gate, jamais en filtrant sa sortie. Checkpoint bloquant **29-05 tâche 3**. |
| Qualité des 11 résumés d'une ligne de l'index de dossier | ICMD-11 | Un résumé qui permet de **choisir** (vs qui décrit) est un jugement rédactionnel ; la **cohérence** index↔dossier, elle, est machine-vérifiable par la paire P2 du gate | Relire `plugin/dev-orchestrator/references/_index.md` ; la complétude (11 entrées, aucune auto-citation, aucun doublon) est déjà gatée par les critères de 29-04 tâche 2. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies — 12 tâches sur 13 portent un `<automated>` ; la 13e est le checkpoint humain terminal, dont c'est la nature.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify — la seule tâche sans commande automatique est précédée de deux tâches gatées.
- [x] Wave 0 covers all MISSING references — les deux suites manquantes (`test-check-map-drift.sh`, `test-scaffold-docs.sh`) naissent **avec** leur script dans la tâche 1 de leur plan respectif ; la baseline `test-dag.sh` est une `<precondition>` exécutable.
- [x] No watch-mode flags — toutes les suites sont des scripts bash autoporteurs à exécution unique.
- [x] Feedback latency < 90s — `test-dag.sh` ~1-2 s ; les deux nouvelles suites sont du même ordre (fixtures en `mktemp -d`, aucun réseau).
- [ ] `nyquist_compliant: true` set in frontmatter — à basculer par `/gsd-validate-phase` une fois les deux suites réellement posées (elles n'existent pas encore sur disque).

**Approval:** plans posés le 2026-08-15 — carte de vérification remplie, sign-off machine en attente de la Wave 2.
