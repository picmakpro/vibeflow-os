# Technology Stack

**Analysis Date:** 2026-07-26

## Nature du repo

Repo de **distribution** du plugin Claude Code VibeFlow (marketplace + plugin à modules
toggables). Pas d'application déployée, pas de `package.json`, pas de build system : la "stack"
est du **bash portable**, du **markdown structuré** (agents/skills/references/rules), du **JSON**
(manifestes) et l'écosystème plugin de Claude Code.

## Languages

**Primary:**
- Bash — tout l'outillage exécutable : engine d'install `plugin/_internal/vibeflow-update.sh`
  (~838 lignes), résolveur de deps `plugin/_internal/resolve-deps.sh`, merge de hooks
  `plugin/_internal/merge-hooks.sh`, gates `plugin/conductor/scripts/` (check-agents.sh,
  guard-agent-write.sh, check-overlaps.sh…), scripts de release `scripts/` (bump.sh,
  check-version-sync.sh, check-release-tag.sh), 37 suites de tests `*/tests/test-*.sh`.
- Markdown structuré — le "code" fonctionnel du plugin : agents (`plugin/*/AGENT.md`,
  `plugin/*/agents/*.md`), skills (`plugin/*/skills/**/SKILL.md`, `plugin/installer/SKILL.md`),
  commandes (`plugin/commands/*.md` : vibeflow, vf-update, vf-audit, vf-planning, vf-calibrate,
  vf-new-lab), references/rules, doctrine `plugin/reference/content/`.

**Secondary:**
- Python 3 (≥ 3.8) — embarqué en heredocs dans les scripts bash pour la manipulation JSON fiable :
  `plugin/_internal/merge-hooks.sh` (merge des fragments hooks dans settings.json),
  `plugin/conductor/scripts/check-plugin-update.sh` (lecture installed_plugins.json), scripts de
  consolidator/planning-core. Jamais de script Python standalone dans la chaîne d'install.
- JSON — manifestes déclaratifs : `.claude-plugin/marketplace.json` (racine),
  `plugin/.claude-plugin/plugin.json`, `plugin/<module>/module.json` (nom, version, `requires`,
  `mandatory`), `plugin/<module>/hooks/hooks.json` (fragments hooks Claude Code).

## Runtime

**Environment:**
- Claude Code (CLI `claude` avec sous-commande `plugin`) — runtime cible : le plugin est copié
  dans le cache de plugins Claude Code, les modules sont posés dans `.claude/` (scope project/local)
  ou `~/.claude/` (scope user).
- bash ≥ 3.2 — compat macOS `/bin/bash` explicitement testée
  (`plugin/_internal/tests/test-windows-crlf.sh` accepte `BASH_BIN=/bin/bash` ; commentaire
  "incompatible bash 3.2/macOS" dans `plugin/dev-orchestrator/scripts/ensure-deps.sh` justifiant
  l'évitement des tableaux vides sous `set -u`).
- Windows : Git Bash (Git for Windows) — voir contraintes ADR-054 ci-dessous.

**Package Manager:**
- Aucun pour le repo lui-même (pas de lockfile, pas de node_modules).
- npm/npx est un **prérequis runtime indirect** : utilisé par
  `plugin/dev-orchestrator/scripts/ensure-deps.sh` pour installer la dépendance GSD.

## Contraintes de portabilité (ADR-054, Windows)

Issues du rapport terrain 2026-07-22 (Windows 11 + Git Bash), machine-enforced par
`plugin/_internal/tests/test-windows-crlf.sh` (reproduit les deux pannes sans poste Windows) :

- **jq Windows natif émet du CRLF** (mode texte) → wrapper obligatoire `jqx()` dans
  `plugin/_internal/resolve-deps.sh` : `command jq "$@" | tr -d '\r'`. Ceintures `${m%$'\r'}`
  dans `plugin/_internal/vibeflow-update.sh:386,765` (jamais de nom de module \r-suffixé).
- **jq absent du PATH** → échec BRUYANT et actionnable, jamais une fermeture de deps vide
  silencieuse : `resolve-deps.sh:21-22` sort une erreur avec la commande d'install par OS
  (`brew install jq` / `winget install jqlang.jq` / `apt-get install jq`). jq reste un prérequis
  **dur** de l'engine (parse des module.json), vérifié par `plugin/installer/scripts/preflight.sh`.
- **Stub Microsoft Store `python3.exe`** : présent dans le PATH mais inerte (App Execution Alias).
  `preflight.sh` fait une sonde d'EXÉCUTION réelle gardée par `timeout` sous Windows ;
  `check-plugin-update.sh:44-47` détecte le stub par chemin (`*WindowsApps*`) et replie sur
  `python` puis `claude plugin list`.
- **Sorties CRLF de python/claude natifs Windows** : strip `${var%$'\r'}` systématique avant
  d'écrire du JSON (`plugin/conductor/scripts/check-plugin-update.sh:64`).
- **Pas de `grep -P`** dans les scripts livrés (vérifié : zéro occurrence hors tests) — grep
  POSIX/BRE uniquement.
- Prérequis documentés utilisateur : `INSTALL.md` (bash ≥ 3.2, jq ≥ 1.6, python3 ≥ 3.8, awk,
  grep, sed ; Git for Windows requis sous Windows).

## Versions

**Canon racine :** `VERSION` = **v2.36.1**, synchronisé (gate `scripts/check-version-sync.sh`)
avec `plugin/.claude-plugin/plugin.json` (`"version": "2.36.1"`),
`.claude-plugin/marketplace.json` (`"version": "2.36.1"`) et les badges des deux README
(`README.md`, `README.fr.md`).

**17 modules versionnés**, chacun avec la triade `VERSION` + `module.json` + `CHANGELOG.md`
(vérifiée sur disque, exigée par check-version-sync) :

| Module | Version | Module | Version |
|---|---|---|---|
| `plugin/conductor/` (mandatory) | v1.14.1 | `plugin/kpi-analyst/` | v1.0.2 |
| `plugin/planning-core/` | v2.5.1 | `plugin/mobile-test/` | v1.0.1 |
| `plugin/dev-orchestrator/` | v2.1.1 | `plugin/mobile-test-team/` | v1.4.0 |
| `plugin/design-orchestrator/` | v1.2.1 | `plugin/audit-architecture/` | v1.0.1 |
| `plugin/validator/` | v1.3.1 | `plugin/infrastructure-audit/` | v1.2.1 |
| `plugin/consolidator/` | v1.8.0 | `plugin/software-architecture/` | v1.5.2 |
| `plugin/skill-creator/` | v1.0.2 | `plugin/content-bundle/` | v2.0.1 |
| `plugin/reference/` | v2.5.1 | `plugin/growth-bundle/` | v2.0.1 |
| `plugin/business-pilot-bundle/` | v2.0.1 | | |

Dossiers **non-modules** sous `plugin/` (pas de triade) : `_internal/` (engine),
`commands/` (commandes plugin), `installer/` (skill /vibeflow-install), `.claude-plugin/`.
Modules retirés tracés dans `plugin/_internal/retired-modules.txt` (ex. feature-dev-gates,
fusionné dans software-architecture v1.3.0).

**Discipline de release** (CLAUDE.md, machine-enforced) : tout bump de `VERSION` racine → tag git
annoté `vX.Y.Z` poussé. Gates : `scripts/check-release-tag.sh --remote` (CI, main uniquement),
hook `scripts/hooks/pre-push` optionnel (`git config core.hooksPath scripts/hooks`).
Outil de bump : `scripts/bump.sh`.

## Key Dependencies

**Dépendances externes réelles (auto-installées par `plugin/dev-orchestrator/scripts/ensure-deps.sh`) :**
- **GSD** (`get-shit-done-cc`) — moteur de planning dev. Install non-interactive :
  `npx -y get-shit-done-cc@latest --claude --global|--local` (scope user → `--global`,
  project/local → `--local`). Détection : binaire `gsd-sdk` ou `~/.claude/get-shit-done/VERSION`.
  Post-install : patch MCP de `gsd-executor.md` via
  `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` (ADR-051) et index via
  `plugin/dev-orchestrator/scripts/build-gsd-index.sh`. Détection moteur côté lab :
  `plugin/planning-core/scripts/detect-gsd-engine.sh` (ADR-055).
- **Superpowers** (plugin Claude Code) —
  `claude plugin install superpowers@claude-plugins-official --scope <user|project|local>`,
  fallback `claude plugin marketplace add anthropics/claude-plugins-official` puis retry, puis
  étape manuelle affichée. Jamais d'échec silencieux ; jamais désinstallé automatiquement.

**Prérequis système (durs, vérifiés par `plugin/installer/scripts/preflight.sh`) :**
- `git` — ls-remote (bandeau update) et labs cibles ; `jq` ≥ 1.6 — parse des manifestes ;
  `python3` ≥ 3.8 utilisable (sonde d'exécution réelle) — merge-hooks.
- Node/npm et CLI `claude` : requis seulement pour l'auto-install des deps externes ; absents →
  étapes manuelles affichées, exit 0 (BOOT-03).

## Configuration

**Environment (variables de l'outillage, pas de .env) :**
- `VF_SCOPE` = `user|project|local` — scope d'install partout (engine + ensure-deps). Défauts
  LEGACY divergents documentés : engine `project` (`vibeflow-update.sh`), ensure-deps `user` ;
  en prod le skill `/vibeflow-install` passe TOUJOURS un scope explicite.
- `VIBEFLOW_CACHE` (défaut `.vibeflow-cache`) — source des modules ; en prod = cache du plugin.
- `VF_ENSURE_DRY_RUN`, `VF_ENSURE_FORCE`, `VF_ENSURE_AUTO_MAP` — modes de `ensure-deps.sh`.
- `BASH_BIN` — surcharge d'interpréteur pour les tests de compat (bash 3.2).
- `GSD_HOME` (défaut `~/.claude/get-shit-done`) — surchargeable pour les tests.

**Build:**
- Aucun build. "Packaging" = le repo lui-même : Claude Code copie `plugin/` dans son cache à
  l'install du plugin. Catalogue généré à la volée par
  `plugin/installer/scripts/build-module-catalog.sh`.

## Platform Requirements

**Development (contributeurs du repo) :**
- macOS / Linux / Windows Git Bash ; bash ≥ 3.2, jq, python3, git.
- Tests : `bash <suite>` sur les 37 suites `plugin/**/tests/test-*.sh` et
  `scripts/**/tests/test-*.sh` (mêmes suites que la CI).

**"Production" (utilisateurs) :**
- Claude Code à jour (commande `claude plugin`). Install en 2 commandes, zéro auth
  (`INSTALL.md`) : `claude plugin marketplace add picmakpro/vibeflow-os` puis
  `claude plugin install vibeflow`.

---

*Stack analysis: 2026-07-26*
