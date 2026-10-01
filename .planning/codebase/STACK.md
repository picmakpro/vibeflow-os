# Technology Stack

**Analysis Date:** 2026-10-02

## Nature du repo

Repo de **distribution** du plugin Claude Code VibeFlow (marketplace + plugin à modules
toggables). Pas d'application déployée, pas de `package.json`, pas de build system : la "stack"
est du **bash portable**, du **Python 3 embarqué en heredoc** (stdlib seule), du **markdown
structuré** (agents/skills/references/rules), du **JSON** (manifestes, fragments de hooks) et
l'écosystème plugin de Claude Code.

## Languages

**Primary:**
- Bash — tout l'outillage exécutable : engine d'install `plugin/_internal/vibeflow-update.sh`
  (~3270 lignes), résolveurs `plugin/_internal/resolve-deps.sh` et
  `plugin/_internal/resolve-preset.sh`, merge de hooks `plugin/_internal/merge-hooks.sh`, lib
  de portabilité sourcée `plugin/_internal/lib/vf-portable.sh`, dispatch multi-runtime
  `plugin/_internal/runtime-cli-dispatch.sh`, gates `plugin/conductor/scripts/` (33 fichiers :
  `check-agents.sh`, `guard-agent-write.sh`, `check-instruction-budget.sh`,
  `check-state-integrity.sh`…), scripts de planning `plugin/planning-core/scripts/`, scripts de
  release et de garde `scripts/` (`bump.sh`, `check-version-sync.sh`, `check-release-tag.sh`,
  `check-baseline-arbitrage.sh`, `check-gate-touche.sh`, `check-push-sans-pr.sh`,
  `check-machine-paths.sh`…), 98 suites `*/tests/test-*.sh` (comptées sur disque).
- Markdown structuré — le "code" fonctionnel du plugin : agents (`plugin/*/AGENT.md`,
  `plugin/*/agents/*.md`), skills (`plugin/*/skills/**/SKILL.md`, `plugin/installer/SKILL.md`),
  commandes (`plugin/commands/*.md` : `vibeflow`, `vf-update`, `vf-audit`, `vf-planning`,
  `vf-calibrate`, `vf-new-lab`, `vf-notify`), references/rules, doctrine
  `plugin/reference/content/`, manuel utilisateur `manual/fr/` et `manual/en/`.

**Secondary:**
- Python 3 (≥ 3.8, `manual/fr/01-demarrer/prerequis.md`) — **jamais en fichier `.py` posé chez
  l'utilisateur** : l'installeur ne pose que `*.sh` en exécutable et `*.txt`/`*.json` en données
  (voie (a) de P44-D-14). Le programme Python est embarqué en heredoc quoté dans un script bash.
  Deux gros moteurs en Python embarqué :
  - **cœur du hook central** de planning-core : `plugin/planning-core/scripts/planning-hook.sh`
    (~2000 lignes ; lanceur bash + heredoc `PY_PLANNING_HOOK_EOF`). Lancé en
    `"$PYBIN" -I -S - <fichier-de-transport> <XDG_CACHE_HOME> <HOME> <mode>` : mode isolé (`-I`),
    **sans module `site`** (`-S`), programme lu sur stdin, payload passé par un fichier `mktemp`
    (0600, supprimé par `trap`), jamais par argv. **Stdlib uniquement** (`collections`,
    `datetime`, `json`, `os`, `re`, `shlex`, `stat`, `sys`, `time`, `urllib.parse`, plus `fcntl`,
    `threading`, `signal` en import protégé) : aucune dépendance pip, aucune variable
    d'environnement lue par le cœur (P45-D-12a).
  - **moteur de recalcul d'état** `plugin/planning-core/scripts/recalc-planning.sh` (~2085
    lignes) : dérive du disque `INDEX.md`, `STATE.md`, `cloture.log` d'un lab adhérent `cycles-v1`.
  Python embarqué plus petit : `plugin/planning-core/scripts/poser-verdict.sh` (hash sha256 par
  `hashlib`, écriture atomique), `plugin/planning-core/scripts/deroger-gate.sh` (journal
  append-only, `fcntl.flock`), `plugin/_internal/merge-hooks.sh` (merge JSON des fragments hooks),
  `plugin/conductor/scripts/check-plugin-update.sh` (lecture `installed_plugins.json`), scripts
  consolidator.
- Node.js (`.mjs`) — un seul adaptateur sans dépendance externe :
  `plugin/_internal/runtime-adapter/agent-to-codex.mjs` (conversion d'agents pour le runtime
  Codex), posé avec `plugin/_internal/runtime-adapter/register-codex-agent.sh`.
- JSON — manifestes déclaratifs : `.claude-plugin/marketplace.json` (racine),
  `plugin/.claude-plugin/plugin.json`, `plugin/<module>/module.json` (nom, version, `requires`,
  `mandatory`), `plugin/<module>/hooks/hooks.json` (fragments hooks Claude Code),
  `plugin/_internal/presets.json` (presets d'install), `.github/rulesets/*.json` (protection de
  branche).
- YAML — workflows GitHub Actions `.github/workflows/ci.yml` et
  `.github/workflows/traffic-snapshot.yml`.

## Runtime

**Environment:**
- Claude Code (CLI `claude` avec sous-commande `plugin`) — runtime de référence : le plugin est
  copié dans le cache de plugins Claude Code, les modules sont posés dans `.claude/` (scope
  project/local) ou `~/.claude/` (scope user). Les scripts de module atterrissent dans
  `<cible>/scripts/` (`.claude/scripts/`), tests compris (`<cible>/scripts/tests/`).
- Autres runtimes supportés à l'install : Codex, OpenCode, kimi-code. Détection par
  `plugin/_internal/runtime-cli-dispatch.sh detect` : `VF_RUNTIME` (override) sinon cascade
  `command -v` claude, codex, opencode ; kimi-code est sondé **par capacité** (binaire `kimi`,
  needle `--output-format`), jamais par nom.
- bash ≥ 3.2 — compat macOS `/bin/bash` explicitement testée
  (`plugin/_internal/tests/test-windows-crlf.sh` accepte `BASH_BIN=/bin/bash` ; pas de tableaux
  vides sous `set -u`, cf. `plugin/dev-orchestrator/scripts/ensure-deps.sh`).
- Python 3 — **dépendance d'exécution du hook central** (voir section dédiée ci-dessous).
- Windows : Git Bash (Git for Windows) — voir contraintes ADR-054 ci-dessous.

**Package Manager:**
- Aucun pour le repo lui-même (pas de lockfile, pas de `node_modules`, pas de `requirements.txt`).
- npm/npx est un **prérequis runtime indirect** : utilisé par
  `plugin/dev-orchestrator/scripts/ensure-deps.sh` pour installer la dépendance GSD, avec Node ≥ 24
  (`NODE_MIN_MAJOR=24`, BOOT-01).

## Dépendance Python du hook central (planning-core)

Le hook `PreToolUse` central de planning-core (Phase 45) exige un interpréteur Python 3 **au
moment de chaque appel d'outil** dans un lab adhérent `cycles-v1`. Contrat :

- **Résolution de l'interpréteur** (`plugin/planning-core/scripts/planning-hook.sh`) : `python3` ;
  si `python3` est absent ou résolu sous `*WindowsApps*` (stub Microsoft Store, ADR-054), repli
  sur `python` ; sinon code 72. Même logique dans `plugin/planning-core/scripts/deroger-gate.sh`,
  `plugin/planning-core/scripts/poser-verdict.sh` et `plugin/planning-core/scripts/recalc-planning.sh`.
- **Codes du lanceur bash** (il ne décide de rien, la commande enregistrée tranche) : `0` décidé,
  `3` erreur Python avant adhésion connue, `70` `mktemp` impossible, `71` lecture de stdin
  impossible, `72` aucun interpréteur Python, `73` échéance interne du cœur dépassée
  (`ECHEANCE_COEUR_S = 8.0`, `SIGALRM`).
- **Sortie** : rien, ou UN objet JSON `hookSpecificOutput` (`permissionDecision: deny` ou
  `additionalContext`), **toujours code 0** — jamais `exit 2` (P45-D-08).
- **Fail-closed seulement dans un lab adhérent** : si le script ou `python3` manque ou plante, la
  commande enregistrée dans `plugin/planning-core/hooks/hooks.json` refuse `Write`, `Edit`,
  `NotebookEdit`, `Agent`, `Task` avec un message de réparation ; `Bash` reste ouvert (limite
  déclarée P45-D-06b, pour que la réparation soit possible). Hors lab adhérent (labs dev, ce dépôt
  compris) : sortie vide, code 0.
- **Prérequis installeur** : `plugin/installer/scripts/preflight.sh` sonde par exécution réelle un
  Python 3 (hors stub WindowsApps) ; absent = échec dur (« câblage des hooks de gouvernance »).
- **Pas de `.py` livré** : toute évolution du cœur passe par le heredoc de
  `plugin/planning-core/scripts/planning-hook.sh`.

## Contraintes de portabilité (ADR-054, Windows)

Issues du rapport terrain 2026-07-22 (Windows 11 + Git Bash), machine-enforced par
`plugin/_internal/tests/test-windows-crlf.sh` (reproduit les pannes sans poste Windows) :

- **jq Windows natif émet du CRLF** (mode texte) → wrapper obligatoire `jqx()` dans
  `plugin/_internal/resolve-deps.sh:27` : `command jq "$@" | tr -d '\r'`. Ceintures
  `m="${m%$'\r'}"` dans `plugin/_internal/vibeflow-update.sh:2159,3199` (jamais de nom de module
  \r-suffixé). Lib partagée `plugin/_internal/lib/vf-portable.sh` (sourcée, jamais exécutée seule,
  posée par `copy_engine_lib()`).
- **jq absent du PATH** → échec BRUYANT et actionnable, jamais une fermeture de deps vide
  silencieuse : `plugin/_internal/resolve-deps.sh:21-22` sort une erreur avec la commande
  d'install par OS (`brew install jq` / `winget install jqlang.jq` / `apt-get install jq`). jq
  reste un prérequis **dur** de l'engine, vérifié par `plugin/installer/scripts/preflight.sh`.
- **Stub Microsoft Store `python3.exe`** : présent dans le PATH mais inerte. `preflight.sh` fait
  une sonde d'EXÉCUTION réelle gardée par `timeout` sous Windows ; `check-plugin-update.sh:45`,
  `planning-hook.sh` et les autres scripts Python détectent le stub par chemin (`*WindowsApps*`) et
  replient sur `python`.
- **Sorties CRLF de python/claude natifs Windows** : strip `${var%$'\r'}` systématique avant
  d'écrire du JSON (`plugin/conductor/scripts/check-plugin-update.sh`).
- **Pas de `grep -P`** dans les scripts livrés (aucun usage exécutable hors tests et
  commentaires) — grep POSIX/BRE/ERE uniquement.
- Prérequis documentés utilisateur : `manual/fr/01-demarrer/prerequis.md` (bash ≥ 3.2, jq ≥ 1.6,
  python3 ≥ 3.8 ; Git for Windows requis sous Windows). `INSTALL.md` est un sommaire qui renvoie
  vers le manuel.

## Versions

**Canon racine :** `VERSION` = **v2.67.1**, synchronisé (gate `scripts/check-version-sync.sh`)
avec `plugin/.claude-plugin/plugin.json` (`"version": "2.67.1"`),
`.claude-plugin/marketplace.json` (`"version": "2.67.1"`) et les badges des deux README
(`README.md`, `README.fr.md`). Le tag `v2.67.1` existe (release du 2026-09-29).

**17 modules versionnés**, chacun avec la triade `VERSION` + `module.json` + `CHANGELOG.md`
(état de `HEAD`, branche `gouvernance/phase-45-execution`) :

| Module | Version | Module | Version |
|---|---|---|---|
| `plugin/conductor/` (mandatory) | v1.45.1 | `plugin/kpi-analyst/` | v1.0.6 |
| `plugin/planning-core/` | **v2.9.0 (sans release)** | `plugin/mobile-test/` | v1.0.2 |
| `plugin/dev-orchestrator/` | v2.25.0 | `plugin/mobile-test-team/` | v1.4.6 |
| `plugin/design-orchestrator/` | v1.5.11 | `plugin/audit-architecture/` | v1.0.3 |
| `plugin/validator/` | v1.3.5 | `plugin/infrastructure-audit/` | v1.3.2 |
| `plugin/consolidator/` | v1.10.0 | `plugin/software-architecture/` | v1.6.1 |
| `plugin/skill-creator/` | v1.1.1 | `plugin/content-bundle/` | v2.0.13 |
| `plugin/reference/` | v2.5.6 | `plugin/growth-bundle/` | v2.0.12 |
| `plugin/business-pilot-bundle/` | v2.0.13 | | |

**`planning-core` v2.9.0 n'est pas publié.** Le tag `v2.67.1` embarque `planning-core` v2.7.2
(`git show v2.67.1:plugin/planning-core/VERSION`) ; la v2.8.0 (Phase 44, moteur de recalcul) est
mergée sur `main` sans release, la v2.9.0 (Phase 45, hook central par rôle et gates d'écriture)
est sur la branche `gouvernance/phase-45-execution`. Aucune release tant que le périmètre n'est
pas arbitré : une release ne se déclenche que pour une évolution fonctionnelle (CLAUDE.md « Quand
publier », `docs/ADR.md` § ADR-073). Ne PAS bumper `VERSION` racine pour embarquer
`planning-core` sans ce geste explicite.

Dossiers **non-modules** sous `plugin/` (pas de triade) : `_internal/` (engine), `commands/`
(commandes plugin), `installer/` (skill `/vibeflow-install`), `.claude-plugin/`. Modules retirés
tracés dans `plugin/_internal/retired-modules.txt` (ex. `feature-dev-gates`, fusionné dans
`software-architecture` v1.3.0).

**Discipline de release** (CLAUDE.md, machine-enforced) : tout bump de `VERSION` racine → tag git
annoté `vX.Y.Z` poussé + release GitHub. Gates : `scripts/check-release-tag.sh --remote` (CI,
main uniquement), hook `scripts/hooks/pre-push` optionnel
(`git config core.hooksPath scripts/hooks`), `scripts/hooks/post-merge` (filet de divergence,
opt-in). Outil de bump : `scripts/bump.sh`.

## Key Dependencies

**Dépendances externes réelles (auto-installées par `plugin/dev-orchestrator/scripts/ensure-deps.sh`) :**
- **GSD** (`@opengsd/gsd-core`, plafond `^1` : `GSD_PACKAGE`/`GSD_RANGE` dans `ensure-deps.sh`) —
  moteur de planning dev. Install non-interactive : `npx -y "@opengsd/gsd-core@^1" --claude
  --global|--local` (scope user → `--global`, project/local → `--local`). Payload sous
  `~/.claude/gsd-core/` (scope user) ou `<projet>/.claude/gsd-core/` (scope projet/local, gitignoré
  dans ce dépôt), fichier `VERSION` faisant autorité. **Node ≥ 24 requis** (`engines` passé à
  `node>=24` en 1.11.0 ; sous Node 22 npm installe silencieusement 1.10.0) : `ensure-deps.sh`
  pose Node ≥ 24 sous `$HOME` via nvm (tag épinglé `NVM_PINNED_TAG`), fnm ou volta — jamais de
  `sudo`, jamais de gestionnaire système, refus sous MSYS/Cygwin. Mise à jour d'un gsd-core
  périmé : `VF_ENSURE_UPGRADE_ENGINE=1` ou `--upgrade-engine` ; sonde de fraîcheur lecture seule
  `--check-engine-update`. Détection : cascade fichier `VERSION` uniquement, jamais de test PATH
  (nouveau layout prioritaire, legacy `~/.claude/get-shit-done/` détecté en repli, jamais réinstallé
  ni supprimé automatiquement, ADR-031). L'outil CLI s'appelle `gsd-tools`, résolu **par cascade**
  (jamais un chemin en dur) — voir `plugin/dev-orchestrator/references/mission-contracts.md`.
  Post-install : patch MCP de `gsd-executor.md` via
  `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` (ADR-051) et index via
  `plugin/dev-orchestrator/scripts/build-gsd-index.sh`. Détection moteur côté lab :
  `plugin/planning-core/scripts/detect-gsd-engine.sh` (ADR-055) — un planning tenu par GSD fait
  refuser (code 3) `plugin/planning-core/scripts/recalc-planning.sh`.
- **Superpowers** (plugin Claude Code) —
  `claude plugin install superpowers@claude-plugins-official --scope <user|project|local>`,
  fallback `claude plugin marketplace add anthropics/claude-plugins-official` puis retry, puis
  étape manuelle affichée. Jamais d'échec silencieux ; jamais désinstallé automatiquement.

**Prérequis système (durs, vérifiés par `plugin/installer/scripts/preflight.sh`) :**
- `git` — `ls-remote` (bandeau update) et labs cibles ; `jq` ≥ 1.6 — parse des manifestes ;
  `python3` utilisable (sonde d'exécution réelle) — merge-hooks **et hook central de planning**.
- Node/npm et CLI `claude` : requis seulement pour l'auto-install des deps externes ; absents →
  étapes manuelles affichées, exit 0 (BOOT-03).

## Configuration

**Environment (variables de l'outillage, pas de .env) :**
- `VF_SCOPE` = `user|project|local` — scope d'install partout (engine + ensure-deps). Défauts
  LEGACY divergents documentés : engine `project` (`vibeflow-update.sh`), ensure-deps `user` ;
  en prod le skill `/vibeflow-install` passe TOUJOURS un scope explicite.
- `VIBEFLOW_CACHE` (défaut `.vibeflow-cache`) — source des modules ; en prod = cache du plugin.
- `VF_RUNTIME` — override de la détection de runtime (`runtime-cli-dispatch.sh`).
- `VF_ENSURE_DRY_RUN`, `VF_ENSURE_FORCE`, `VF_ENSURE_AUTO_MAP`, `VF_ENSURE_AUTO_NODE`,
  `VF_ENSURE_UPGRADE_ENGINE` — modes de `ensure-deps.sh`.
- `BASH_BIN` — surcharge d'interpréteur pour les tests de compat (bash 3.2).
- `GSD_HOME` — surchargeable pour les tests. Non fourni, résolu par cascade : projet-local
  `.claude/gsd-core` > global `~/.claude/gsd-core` > legacy `~/.claude/get-shit-done` > défaut
  `gsd-core`.
- Hook central de planning : **aucune variable d'environnement ne change l'armement ni
  l'adhésion** (P45-D-12a). Seules `TMPDIR` (où poser le fichier de transport),
  `XDG_CACHE_HOME`/`HOME` (chemin du journal d'observation et racine des agents du compte) sont
  lues, et chacune ne choisit qu'un CHEMIN. `CLAUDE_PROJECT_DIR` sert à `check-gates-alive.sh` et
  au préfixe de script posé dans les réglages, jamais à l'adhésion.
- Adhésion d'un lab au moteur de planning : `.planning/config.json` avec
  `"planning_version": "cycles-v1"` (lu par le hook, `recalc-planning.sh`, `poser-verdict.sh`,
  `deroger-gate.sh`).
- Constantes d'armement dans le code du hook (`plugin/planning-core/scripts/planning-hook.sh`) :
  `ARMEMENT_G6`, `ARMEMENT_G5`, `ARMEMENT_G1`, `ARMEMENT_G7`, `ARMEMENT_ROLE` = `"armed"` ;
  `G2_MODE = "avertit"`. Armer ou désarmer un gate = éditer ces constantes (une étape = un commit,
  relevé de rejeu `45-REJEU-ETAPE-<n>` dans le compartiment `gouvernance`) ; `check-gates-alive.sh`
  signale un gate armé sans cas de test. À ne pas confondre avec les sentinelles
  `.planning/.instruction-budget-armed` et `.planning/.requirements-survival-armed` (gates de
  budget d'instructions et de survie des exigences, gardées par
  `scripts/check-baseline-arbitrage.sh`).

**Build:**
- Aucun build. "Packaging" = le repo lui-même : Claude Code copie `plugin/` dans son cache à
  l'install du plugin. Catalogue généré à la volée par
  `plugin/installer/scripts/build-module-catalog.sh`.

## Platform Requirements

**Development (contributeurs du repo) :**
- macOS / Linux / Windows Git Bash ; bash ≥ 3.2, jq, python3 (≥ 3.8), git ; Node ≥ 24 + npm
  uniquement pour exercer l'install GSD.
- Tests : `bash <suite>` sur les 98 suites `plugin/**/tests/test-*.sh` et
  `scripts/**/tests/test-*.sh` (mêmes suites que la CI). Les suites de hook sous charge machine
  forte peuvent dépasser l'échéance interne de 8 s du cœur (limite (z) de
  `plugin/planning-core/references/modele-cycles.md`).

**"Production" (utilisateurs) :**
- Claude Code à jour (commande `claude plugin`). Install en 2 commandes, zéro auth :
  `claude plugin marketplace add picmakpro/vibeflow-os` puis `claude plugin install vibeflow`
  (procédure complète : `manual/fr/01-demarrer/installation.md`).

---

*Stack analysis: 2026-10-02*
