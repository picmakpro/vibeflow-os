# Testing Patterns

**Analysis Date:** 2026-07-26

## Test Framework

**Runner:**
- Bash pur, zéro framework externe. Chaque suite est un exécutable autonome `test-*.sh` avec helpers `ok()/ko()` ou `assert()` maison.
- **37 suites** découvertes par le motif `*/tests/test-*.sh` (vérifié sur disque au 2026-07-26), toutes sous `plugin/`.

**Run Commands:**
```bash
# Une suite (depuis n'importe où — chaque suite se `cd` elle-même)
bash plugin/conductor/scripts/tests/test-dag.sh

# Toutes les suites (la boucle exacte de la CI)
find plugin scripts -type f -path '*/tests/test-*.sh' | sort | while IFS= read -r t; do bash "$t"; done

# Exit code : 0 si tout passe, 1 si au moins un KO (SKIP non bloquant)
```

## CI — `.github/workflows/ci.yml` (3 jobs, push toutes branches + PR)

**Job `tests` — Suites de tests (découverte non vide) :**
- `find plugin scripts -type f -path '*/tests/test-*.sh'` puis exécution de chaque suite dans un `::group::`.
- **Contrat de découverte (F13)** : 0 suite découverte = `exit 1` — la CI refuse le « vacuous green » (un vert rendu sans rien vérifier est un faux vert).
- Bilan final : `== bilan : N suite(s), M échec(s) ==`.

**Job `gates` — Gates de qualité (mode strict) :**
- `check-agents.sh --strict --agents-dir=<d>` sur **chaque** `plugin/*/agents` (6 dossiers : business-pilot-bundle, content-bundle, design-orchestrator, dev-orchestrator, growth-bundle, mobile-test-team) — découverte non vide assertée.
- `bash scripts/check-version-sync.sh` (canon VERSION ↔ plugin.json ↔ marketplace ↔ badges ↔ triade par module ↔ historique README).
- `bash scripts/check-release-tag.sh --remote` — **sur `main` uniquement** (une branche de feature porte légitimement une VERSION pas encore taggée ; `fetch-depth: 0` pour l'historique des tags).

**Job `lab-frais` — install baseline + Gate C (leçon UAT 2026-07-25, F2) :**
- Lab vierge `mktemp -d` + `git init` ; fermeture transitive de `conductor` calculée par `plugin/_internal/resolve-deps.sh conductor` ; chaque module installé par le **vrai engine** : `VIBEFLOW_CACHE="$GITHUB_WORKSPACE/plugin" VF_SCOPE=project bash plugin/_internal/vibeflow-update.sh install <m>`.
- Gate C : la baseline doit passer **ses propres gates sans intervention** — `bash .claude/scripts/check-agents.sh --strict`, `check-registres.sh --strict --allow-empty` (verdict propre attendu : rc 0 ou 3, jamais un crash), et `grep -q "guard" .claude/settings.json` (hooks de gouvernance réellement mergés).

## Test File Organization

**Location :** colocalisé avec l'implémentation — `plugin/<module>/scripts/tests/test-*.sh` (+ `fixtures/`) ; engine sous `plugin/_internal/tests/`.

**Répartition des 37 suites :**
| Emplacement | Suites |
|---|---|
| `plugin/conductor/scripts/tests/` (+1 sous `skills/vf-new-lab/scripts/tests/`) | 11 |
| `plugin/consolidator/scripts/tests/` | 6 |
| `plugin/planning-core/scripts/tests/` | 5 |
| `plugin/_internal/tests/` | 4 |
| `plugin/dev-orchestrator/`, `plugin/software-architecture/` | 2 chacun |
| business-pilot-bundle, content-bundle, design-orchestrator, growth-bundle, infrastructure-audit, installer, kpi-analyst | 1 chacun |

**Naming :** `test-<script-ou-module>.sh` ; l'en-tête liste les truths couvertes (T1, T2, …) et le contrat de sortie.

## Test Structure

**Pattern canonique** (cf. `plugin/conductor/scripts/tests/test-dag.sh`, `plugin/_internal/tests/test-vibeflow-update.sh`) :
```bash
#!/usr/bin/env bash
# test-x.sh — en-tête : liste des truths T1..Tn couvertes. Exit 0 si tout passe, 1 sinon.
set -uo pipefail                 # SANS -e : chaque échec est capturé et rendu bruyant
cd "$(dirname "$0")/../.."       # racine du module

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT   # cleanup garanti

pass=0; fail=0; skipped=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }
# variante : assert "T1.1 — nom" "$output" "sous-chaîne attendue" (compteurs PASS/FAIL)

# ... asserts numérotés T1.x, T2.x ...

echo "== résultat : $pass ok, $fail ko =="   # bannière présente dans 19 suites (variantes de casse)
[ "$fail" -eq 0 ]
```

**Isolation :**
- Tout état dans `mktemp -d` ; le vrai `~/.claude` n'est **jamais** touché — scope user testé via `HOME=$(mktemp -d)` + snapshot avant/après du vrai `~/.claude` (ceinture-bretelles, `test-vibeflow-update.sh:49`).
- Surcharge par variables d'environnement `VF_*` : `VF_SCOPE`, `VF_MODULES_ROOT`, `VF_DRIVER_LOCK`, `VF_SCRIPTS`, `VF_ARCH_WARN`/`VF_ARCH_BLOCK`, `VF_TARGET_ROOT`, `MEMORY_DIR`, `VIBEFLOW_CACHE`.
- Scripts appelés en boîte noire (subprocess réel), verdicts sur exit code + stdout (match sous-chaîne, JSON asserté en substring).

## Mocking

**Framework :** aucun. Substituts par environnement :
- **Env override** pour rediriger les chemins (voir `VF_*` ci-dessus).
- **Shims sur le PATH** pour simuler Windows sans poste Windows : jq qui émet du CRLF, stub `WindowsApps/python3` factice, PATH sans jq (`plugin/_internal/tests/test-windows-crlf.sh`, `plugin/consolidator/scripts/tests/test-windows-guards.sh`).
- **Asserts statiques** sur le source (ex. T4 : aucun `git clone`/`git pull` dans l'engine).
- **Ne pas mocker** : la logique des scripts, les outils POSIX (awk/grep/sed), le vrai I/O fichier.

## Fixtures and Factories

- Fixtures statiques dans `<module>/scripts/tests/fixtures/` — mini-registres réalistes (index + body, dates figées 2026-01-0x, orphelins/collisions volontaires) : `plugin/consolidator/scripts/tests/fixtures/LEARNINGS-mini.md`, `BLOCKERS-mini.md`.
- Modules/labs factices générés inline par helpers (`prepare_module()` dans `test-vibeflow-update.sh`). Pas de factory framework.

## Gates = tests permanents

Les gates tournent à chaque push (CI) et en local, et suivent tous le **contrat F13** (cible vide → exit 3 INDÉTERMINÉ, jamais un vert) :
- `scripts/check-version-sync.sh` — 7 contrôles de synchro versions (dont triade par module et historique README) ; appelé par `check-release-tag.sh` en pre-push.
- `scripts/check-release-tag.sh` — VERSION taggée (+ `--remote` : tag poussé).
- `plugin/conductor/scripts/check-agents.sh --strict` — conformité native des agents (ADR-044).
- Guards de hooks, **eux-mêmes testés** : `test-guard-bash-registres.sh`, `test-guard-read-registres.sh`, `test-windows-guards.sh` (consolidator), `test-guard-file-size.sh` (software-architecture), `test-check-agents.sh`, `test-driver-lock.sh` (conductor).

## Coverage

Aucun outil de couverture (non applicable au bash). Proxy : chaque ADR récent exige ses suites (ex. ADR-054 → `test-windows-crlf.sh` + `test-windows-guards.sh`, rejouables sur macOS/Linux).

## Ce qui n'est PAS couvert

- **6 modules sans aucune suite** : `validator`, `skill-creator`, `audit-architecture`, `mobile-test`, `mobile-test-team`, `reference` (modules majoritairement markdown/agents — seuls leurs frontmatters passent `check-agents --strict` en CI ; la prose SKILL.md/AGENT.md n'est pas testée).
- **Scripts racine sans suite dédiée** : `scripts/bump.sh`, `scripts/check-version-sync.sh`, `scripts/check-release-tag.sh` — exercés uniquement en tant que gates (le `find` CI inclut `scripts` mais n'y trouve aucun `tests/`).
- **Windows réel** : simulé par shims (CRLF, stub Store) — aucun runner Windows en CI.
- **Comportement LLM** : le routage des agents, la sémantique des skills et les workflows d'orchestration ne sont validés qu'en UAT sur labs (cf. sections « validé en production » des CHANGELOG).
- **Install marketplace depuis GitHub** : le job lab-frais installe depuis le cache local (`VIBEFLOW_CACHE=$GITHUB_WORKSPACE/plugin`), pas via la fiche marketplace publiée.

---

*Testing analysis: 2026-07-26*
