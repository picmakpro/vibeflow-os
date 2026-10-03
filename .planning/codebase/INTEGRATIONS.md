# External Integrations

**Analysis Date:** 2026-10-02

## APIs & External Services

**GitHub (repo PUBLIC `picmakpro/vibeflow-os`) :**
- Rôle : hébergement du marketplace Claude Code ET du plugin. Le repo héberge son propre
  `.claude-plugin/marketplace.json` (racine) qui pointe `"source": "./plugin"`.
- Install **zéro-auth** (`manual/fr/01-demarrer/installation.md`, sommaire `INSTALL.md`) :
  ```bash
  claude plugin marketplace add picmakpro/vibeflow-os
  claude plugin install vibeflow
  ```
- Mise à jour : `/vf-update` (commande `plugin/commands/vf-update.md`, script
  `plugin/conductor/scripts/vf-update-run.sh`) ou `claude plugin update vibeflow@vibeflow-os`
  (identifiant complet obligatoire, piège du cache de catalogue documenté dans
  `manual/fr/01-demarrer/mettre-a-jour-et-desinstaller.md`).
- Accès réseau sortant du plugin installé : `plugin/conductor/scripts/check-plugin-update.sh`
  fait un `git ls-remote` (sans clone, `GIT_TERMINAL_PROMPT=0`, bornes lowSpeed) vers le repo
  pour comparer le plus grand tag `vX.Y.Z` à la version installée. Best-effort, jamais bloquant,
  cache `${XDG_CACHE_HOME:-~/.cache}/vibeflow/update-check.json`, consommé par le bandeau
  SessionStart `plugin/conductor/scripts/update-banner.sh`.
- **API GitHub via `gh api` (outillage du dépôt, pas livré aux utilisateurs)** :
  `scripts/check-push-sans-pr.sh` (G-3, quelles PR référencent un commit arrivé sur `main`),
  `scripts/measure-server-rulesets.sh` (relevé daté des rulesets dans
  `.planning/server-rulesets-measurement.json`, lu par `scripts/check-affirmation-non-mesuree.sh`),
  `scripts/traffic-snapshot.sh`, `scripts/check-release-tag.sh --remote` (tag poussé + release
  GitHub). Discipline commune : un échec d'API (`gh` absent, non-2xx, JSON non tableau) rend un
  code « non vérifiable » (rc 2), jamais confondu avec une liste vide.

**npm registry :**
- `plugin/dev-orchestrator/scripts/ensure-deps.sh` installe GSD via
  `npx -y "@opengsd/gsd-core@^1" --claude --global|--local` (non-interactif, scope-aware ; plafond
  `GSD_RANGE="^1"`). Node ≥ 24 requis (`NODE_MIN_MAJOR=24`), posé si besoin sous `$HOME` via
  nvm/fnm/volta (jamais `sudo`). Sonde de fraîcheur en lecture seule `npm view` (flag
  `--check-engine-update`), jamais `npx`. Fenêtre de compatibilité : l'ancien layout
  `~/.claude/get-shit-done/` reste détecté (jamais réinstallé) pour les labs pas encore migrés.
- Veille de release `scripts/check-gsd-core-update.sh` : **sonde désarmée le 2026-09-07**
  (signal consommé), conservée et invocable à la main (`--status`) ; ne pas la ré-armer sur une
  simple montée de version.

**Marketplace officiel Anthropic :**
- `ensure-deps.sh` installe Superpowers via
  `claude plugin install superpowers@claude-plugins-official --scope <scope>`, avec fallback
  `claude plugin marketplace add anthropics/claude-plugins-official` puis retry, puis étape
  manuelle affichée (jamais d'échec silencieux).

**Autres runtimes (installation hors Claude Code) :**
- `plugin/_internal/runtime-cli-dispatch.sh` : table de dispatch des verbes CLI compagnons
  (`list`, `install`, `enable`, `marketplace-add`, `ensure-codex-preconditions`) pour `claude`,
  `codex`, `opencode` et `kimi-code` (binaire `kimi`, sondé par capacité). Override : `VF_RUNTIME`.
- Codex : `plugin/_internal/runtime-adapter/agent-to-codex.mjs` (conversion d'un agent) et
  `plugin/_internal/runtime-adapter/register-codex-agent.sh` ; session de juge
  `plugin/_internal/runtime-adapter/codex-judge-session-command.md`. Guide :
  `manual/fr/01-demarrer/autres-runtimes.md`.

## Chaîne d'install (cache plugin → engine scope-aware)

**PLUS de git clone depuis la Phase 3.** L'en-tête de `plugin/_internal/vibeflow-update.sh` est
explicite : « Source : le cache local fourni par l'appelant (`VIBEFLOW_CACHE`, défaut
`.vibeflow-cache`). Plus de clone/pull git : le cache DOIT exister (sinon erreur). » La commande
`sync` est un **no-op**.

Chaîne complète :
1. `claude plugin install vibeflow` → Claude Code copie le bundle `plugin/` (modules + skill
   `installer/` + engine `_internal/` + commandes) dans son cache de plugins.
2. L'utilisateur lance **manuellement** `/vibeflow-install` (`plugin/installer/SKILL.md`) —
   aucune ouverture automatique au démarrage de session.
3. `plugin/installer/scripts/preflight.sh` — prérequis durs (git, jq, python3 exécutable, utilisé
   aussi par le hook central de planning) + sondes ADR-054 (CRLF jq, stub python3 Microsoft Store).
4. `plugin/installer/scripts/build-module-catalog.sh` — catalogue des modules depuis le cache
   (toggles multi-select de l'UX) ; presets via `plugin/_internal/resolve-preset.sh` et
   `plugin/_internal/presets.json`.
5. `plugin/_internal/resolve-deps.sh` — fermeture transitive des `requires` des `module.json`
   (ex. `conductor` requiert `planning-core`, `validator`, `skill-creator` ; `planning-core` ne
   requiert rien), récapitulée avant install.
6. `plugin/_internal/vibeflow-update.sh` — engine scope-aware :
   - `--scope user` → `~/.claude` ; `--scope project|local` → `./.claude` (local ajoute les
     chemins au `./.gitignore`) ; `VF_SCOPE` en env, `--scope` prioritaire.
   - Commandes : `install [--with-deps|--all]`, `update [--all]`, `uninstall [--all]`,
     `rollback`, `status`.
   - Pose des scripts d'un module dans `<cible>/scripts/` (chmod +x, tests sous
     `<cible>/scripts/tests/`), lib engine `plugin/_internal/lib/vf-portable.sh` copiée sans
     bit exécutable (sourcée seulement).
   - Registre des modules installés : `.vibeflow-installed` ; backup automatique avant
     écrasement/suppression ; cleanup des modules retirés via
     `plugin/_internal/retired-modules.txt` (convergence à `update --all`).
   - Merge des hooks : `plugin/_internal/merge-hooks.sh` (voir section suivante).
7. `plugin/dev-orchestrator/scripts/ensure-deps.sh` — pose GSD + Superpowers au même scope
   (`VF_SCOPE` unique partout).

Désinstallation en deux couches (ordre imposé) : modules d'abord
(`vibeflow-update.sh uninstall --all` tant que l'engine est en cache), plugin ensuite
(`claude plugin uninstall vibeflow`). GSD/Superpowers ne sont jamais désinstallés automatiquement.

## Hooks Claude Code posés par les modules

Le **plugin bundle** lui-même n'enregistre aucun hook : chaque module porteur d'un fragment
`hooks/hooks.json` le fait merger dans le `settings.json` du lab par
`plugin/_internal/merge-hooks.sh` (ADR-043 : la gouvernance est POSÉE par la machine, jamais
copiée-collée).

**Mécanique du merge (`merge-hooks.sh merge|remove|plan`) :**
- Idempotent (dédup par basename de script référencé), hooks tiers préservés, retrait chirurgical.
- Placeholder `{{VF_SCRIPTS}}` résolu par `--scripts-prefix` : scope project/local →
  `"$CLAUDE_PROJECT_DIR"/.claude/scripts`, scope user → `"$HOME"/.claude/scripts`. **Forme shell**
  (`"command": "bash …"`) : le shell expanse la variable. **Forme exec** (`command` = `{{VF_BASH}}`
  + `args`) : aucun shell, le préfixe est dérivé en variante exec-safe ; `{{VF_BASH}}` est un
  chemin absolu de bash propre à la machine, donc routé vers `settings.local.json` (jamais
  committé) via `--settings-local`.
- Contrat de sortie des hooks (code 0 = rien ou signal émis, non nul = vraie erreur, 2 = blocage
  explicite réservé) : `docs/HOOKS-CONTRAT-SORTIE.md`, gardé par
  `scripts/tests/test-hook-exit-parc.sh`.
- La CI « lab frais » vérifie leur présence dans `.claude/settings.json`
  (`.github/workflows/ci.yml`, jobs `lab-frais` et `lab-frais-arme`).

| Module | Fragment | Événements | Rôle |
|---|---|---|---|
| conductor | `plugin/conductor/hooks/hooks.json` | PreToolUse(Write ; Bash\|Write\|Edit), SessionStart(startup) | `guard-agent-write.sh` (agents natifs ADR-044), `guard-driver-lock.sh` (verrou de pilote, forme exec), `check-agents.sh --hook`, `check-debug-research.sh`, `update-banner.sh`, `check-branch-claim.sh`, `check-workstream-pointer.sh`, `check-guard-health.sh` |
| planning-core | `plugin/planning-core/hooks/hooks.json` | SessionStart, UserPromptSubmit, Stop, **PreToolUse** | voir section dédiée ci-dessous |
| consolidator | `plugin/consolidator/hooks/hooks.json` | PreToolUse(Read ; Bash), PostToolUse(Edit\|Write\|Bash), SessionStart, SessionEnd | gouvernance mémoire machine-enforced (ADR-032) : `guard-read-registres.sh`, `guard-bash-registres.sh`, `post-edit-reindex.sh`, `seed-registres.sh`, `check-registres.sh`, `probe-memory-guards.sh`, `archive.sh --async --apply` |
| dev-orchestrator | `plugin/dev-orchestrator/hooks/hooks.json` | SessionStart(startup) | `check-dev-bootstrap.sh`, `discover-unintegrated-docs.sh`, `check-doc-drift.sh`, `check-gsd-config.sh`, `check-requirements-survival.sh`, `check-hook-paths.sh` (forme exec) |
| software-architecture | `plugin/software-architecture/hooks/hooks.json` | PreToolUse(Edit\|Write) | `guard-file-size.sh` — porte blindée Iron Law 300L (ADR-035) |
| infrastructure-audit | `plugin/infrastructure-audit/hooks/hooks.json` | SessionStart | `audit-infra.sh --quick --if-older-than=14d` (drift si snapshot > 14 jours) |

### Hook central de planning-core (Phase 45, planning-core v2.9.0, non publié)

Fragment : `plugin/planning-core/hooks/hooks.json`.

**Entrées SessionStart / UserPromptSubmit / Stop (forme shell, tolérantes `|| true`, sauf Stop) :**
- `SessionStart` matcher `startup` : `check-planning-state.sh --defer-to-gsd`,
  `planning-context.sh --defer-to-gsd` (fraîcheur + digest index-first, retirés quand GSD tient le
  projet, ADR-055), `detect-planning-debt.sh` (8e signal de dette), `check-gates-alive.sh --hook`
  (canary, voir plus bas) ; entrée sans matcher : `planning-session-snapshot.sh` (baseline de
  session).
- `UserPromptSubmit` : `planning-task-context.sh` (STATE du compartiment ciblé).
- `Stop` : `guard-planning-updated.sh` — garde-fou **bloquant** si le planning n'est pas à jour.

**Entrée PreToolUse, UNE seule, matcher `Write|Edit|NotebookEdit|Bash|Agent|Task`, timeout 20 :**
- Forme **shell** (`command` multi-ligne), pas d'`args`. Elle lit le payload sur stdin
  (`I=$(cat)`), le rejoue dans `bash "$S"` avec `S={{VF_SCRIPTS}}/planning-hook.sh` et :
  - code 0 du script → relaie sa sortie (vide, ou un objet JSON `hookSpecificOutput`) et sort 0 ;
  - script absent, `python3` absent ou script en erreur → **fail-closed dans un lab adhérent
    seulement** : un décodeur shell de repli (fonctions `vf_get`, `vf_norm`, `vf_cl`, `vf_tight`)
    cherche le chemin écrit (`file_path`, `notebook_path`, sinon `cwd`), remonte l'arborescence
    jusqu'à un `.planning/config.json` portant `"planning_version": "cycles-v1"`, et émet un `deny`
    (`permissionDecision`, `permissionDecisionReason` « hook central indisponible… Réparer : mettre
    à jour VibeFlow (/vf-update) ou installer python3 ») pour `Write`, `Edit`, `NotebookEdit`,
    `Agent`, `Task` ; hors lab adhérent, ou pour `Bash`, silence et code 0 (limite P45-D-06b : `Bash`
    reste ouvert quand le hook ne peut pas tourner, pour que la réparation soit possible). Un chemin
    non analysable ou trop long (> 4096) qui nomme `.planning` ou `.claude` est refusé par
    précaution.
  - Un refus est TOUJOURS un `deny` JSON avec code 0, jamais un `exit 2`.
- Lanceur + cœur : `plugin/planning-core/scripts/planning-hook.sh` (bash + Python embarqué, voir
  `.planning/codebase/STACK.md` § Dépendance Python). Il lit `tool_name`, `tool_input` et `cwd`
  du payload Claude Code ; la racine du lab est dérivée du chemin écrit, jamais de
  `$CLAUDE_PROJECT_DIR`.
- Gates portés par le cœur (états livrés : G6, G5, G1, G7, ROLE = `armed` ; G2 = `avertit`) :
  G6 (fichiers générés, cache, journal de dérogation, adhésion de `config.json`, scripts du hook),
  G5 (`VERDICT.md` interdit à l'écriture par outil), G1 (pas de plan sans cadrage), G7 (pas de
  planning orphelin), ROLE (juge : aucune écriture par outil ; worker : dispatch limité à son
  allowlist), G2 (avertit sur écriture hors `ecrit:` des plans ouverts, ne refuse jamais). Limites
  déclarées (a) à (z) : `plugin/planning-core/references/modele-cycles.md`.
- Journal d'observation : `<XDG_CACHE_HOME>/vibeflow/gates-observation/observation.log`, à défaut
  `<HOME>/.cache/vibeflow/gates-observation/observation.log` (aucun contenu de payload journalisé).
- Journal de dérogation : `.planning/derogations-gates.log` du lab (append-only).

**Scripts compagnons du hook (tous dans `plugin/planning-core/scripts/`) :**

| Script | Rôle | Qui le lance |
|---|---|---|
| `check-gates-alive.sh` | Canary de **session** : retrouve la commande PreToolUse enregistrée dans `$CLAUDE_PROJECT_DIR/.claude/settings.json` puis `$HOME/.claude/settings.json`, la rejoue telle quelle sur un lab adhérent synthétique (`mktemp`), SIGNALE sans jamais bloquer (hook absent, commande non reconnue, mode dégradé, gate armé sans cas, couverture incomplète). `--hook` : stdout vide hors signal ; `--couverture`, `--settings=`, `--reference=` (réservé aux suites) | hook `SessionStart` ; manuel |
| `rejeu-gates.sh` | Rejeu **en lecture seule** sur une COPIE d'un lab (`--lab=… --etape=<1\|2\|3\|4> [--attendus=] [--rapport=] [--hook=]`) : faux refus, faux accept, refus conformes au modèle ; simule adhésion et armement | manuel, avant d'armer une étape |
| `rejeu-reel.sh` | Geste de rejeu sur labs **réels** : empreinte de TOUT l'arbre avant/après (`cmp -s`), extérieure à `rejeu-gates.sh` ; lignes `EMPREINTE-ARBRE-IDENTIQUE`/`DIVERGENTE`, `MESURE-VIDE` ; `--rapport` obligatoire | manuel |
| `poser-verdict.sh` | SEUL chemin légitime vers `VERDICT.md` (`--unite= --juge= --tentative= --score= --constat=<critère>::<passé\|échec>`) ; hash sha256 du `PLAN.md`, tentative vérifiée, écriture atomique. Codes : 0, 1, 2 (lab non adhérent), 64 | juge (s'il a Bash) ou manager |
| `deroger-gate.sh` | Dérogation nominative à un gate (`--lab= --gate=<G1\|G5\|G6\|G7\|ROLE> --chemin= --qui= --canal= --date= --raison=`), usage unique par (gate, chemin), journal append-only. Codes : 0, 1, 2, 64 | humain, via Bash |
| `recalc-planning.sh` | Dérive du disque `INDEX.md`, `STATE.md`, `cloture.log` (`--planning= --read-only`). Codes : 0, 1, 2 (refus d'adhésion), 3 (refus GSD), 64 | manuel, `rejeu-gates.sh` (`--read-only` sur la copie) |

**Canary de CI** : `plugin/_internal/tests/test-planning-hook-installed.sh` installe planning-core
dans un lab jetable par l'installeur inchangé, lit la commande POSÉE dans `.claude/settings.json`
(jamais `hooks.json`) et la rejoue sous `/bin/sh -c` ; la suite compare aussi `COMMANDE_REFERENCE`
de `check-gates-alive.sh` à `hooks.json` octet pour octet. Bloquant à chaque push, sans changer
`.github/workflows/ci.yml` (la CI découvre les suites par motif).

**Limites d'intégration** : les réglages `.claude/settings*.json` ne sont pas protégés par G6
(limite (y)) ; en scope compte (`~/.claude/scripts/`) les scripts du hook ne sont pas protégés,
sauf si `HOME` est lui-même un lab adhérent (R-INST-08).

## CI/CD & Deployment

**CI Pipeline :** `.github/workflows/ci.yml` (push toutes branches sauf `traffic-data`, et
`pull_request`), 4 jobs sur `ubuntu-latest`, principe F13 « contrat de découverte » : une
découverte vide = échec, jamais un vert par absence de cible (vacuous green).

- **`tests`** (« Suites de tests (découverte non vide) ») — installe bash/jq/python3 et le moteur
  GSD (`@opengsd/gsd-core@^1`), puis découvre et lance **toutes les suites**
  `plugin/**/tests/test-*.sh` et `scripts/**/tests/test-*.sh` (98 suites sur disque au
  2026-10-02) ; 0 suite découverte = exit 1. Inclut un canari de forme du moteur GSD.
- **`gates`** (« Gates de qualité (mode strict) ») — `check-agents.sh --strict` sur chaque
  `plugin/*/agents` et `plugin/*/AGENT.md`, `--resolve-agents=strict` ; `check-blueprints.sh` ;
  `scripts/check-version-sync.sh` (canon `VERSION` ↔ `plugin.json` ↔ marketplace ↔ badges README ↔
  triade par module) ; `check-state-integrity.sh` (frontmatter de `STATE.md`, ADR-063, une invocation par
  compartiment `.planning/workstreams/*` énuméré) ; gates workstream-aware sur un arbre partitionné jetable ; `check-divergence.sh` ;
  `check-planning-consumers-registered.sh` ; `check-capability-activation` ;
  `scripts/check-machine-paths.sh` (aucun chemin absolu de machine dans les fichiers versionnés —
  les `.planning/codebase/*.md` y sont soumis) ; `check-instruction-budget.sh` (ADR-029) ; gardes de
  protection `scripts/check-baseline-arbitrage.sh` (G-1), `scripts/check-gate-touche.sh` (G-2),
  `scripts/check-affirmation-non-mesuree.sh` (G-4), `scripts/check-push-sans-pr.sh` (G-3,
  fixture sans condition + mesure réelle sur push vers `main`) ; `scripts/check-release-tag.sh
  --remote` (**main uniquement**, étape non requise).
- **`lab-frais`** (« Lab frais (install baseline + Gate C…) ») — installe la baseline dans un lab
  vierge (`mktemp -d` + `git init`) avec le **vrai engine** (`resolve-deps.sh conductor` puis
  `VIBEFLOW_CACHE=… VF_SCOPE=project vibeflow-update.sh install <m>`), puis **Gate C** sans
  intervention : `check-agents.sh --strict`, `check-registres.sh --strict --allow-empty`, hooks de
  gouvernance présents dans `.claude/settings.json`.
- **`lab-frais-arme`** (« Lab frais arme (as-installed testing…) ») — installe la fermeture
  `dev-orchestrator` (9 modules) dans un lab armé, invoque les gates INSTALLÉS sans surcharge,
  plancher d'au moins deux artefacts armés, vérifie la forme exec des `settings.json` /
  `settings.local.json` POSÉS (PORT-05) et des conditions Windows simulées.

**Protection de `main` et des tags (source versionnée) :** `.github/rulesets/main.json` (PR
obligatoire, 0 approbation, revue code owner, 4 checks requis = les 4 jobs ci-dessus, branche à
jour, pas de suppression ni de non-fast-forward, contournement `always` pour deux utilisateurs
nommés) et `.github/rulesets/tags-v.json` (tags `v*` : suppression, réécriture et update refusés
hors liste de contournement) ; `.github/CODEOWNERS` (`/.github/`,
`/.planning/instruction-budget-baselines.tsv`, `/.planning/.*-armed`, `/scripts/hooks/`).
L'état posé côté GitHub se vérifie par `gh api repos/picmakpro/vibeflow-os/rulesets`, jamais depuis
ces fichiers (ADR-072). `.github/PULL_REQUEST_TEMPLATE.md` et `.github/ISSUE_TEMPLATE/` complètent.

**Autre workflow :** `.github/workflows/traffic-snapshot.yml` — snapshot hebdomadaire (lundi 06:00
UTC) des stats GitHub traffic via `scripts/traffic-snapshot.sh`, commit sur la branche
`traffic-data`. Secret de dépôt `TRAFFIC_PAT` (PAT fine-grained, Administration:read) ; **non
activé** tant que le secret n'est pas posé (runs planifiés verts avec avertissement).

**Hosting :** GitHub, repo public. Pas de déploiement applicatif — la « release » = tag annoté
`vX.Y.Z` sur main + release GitHub (discipline `CLAUDE.md`, garde-fous
`scripts/check-release-tag.sh` + `scripts/hooks/pre-push`). Une PR de doc/specs/planning se merge
sans release (ADR-073).

## Data Storage

**Databases :** aucune.
**File Storage :** filesystem local uniquement — cache plugin Claude Code
(`~/.claude/plugins/cache`), cibles d'install (`.claude/skills/`, `.claude/agents/`,
`.claude/scripts/`, `.claude/rules/`, `docs/`), registre `.vibeflow-installed`, backups
automatiques, cache update `~/.cache/vibeflow/update-check.json`, journal d'observation des gates
`~/.cache/vibeflow/gates-observation/observation.log`, journal de dérogation par lab
`.planning/derogations-gates.log`.
**Caching :** cache de plugins Claude Code (remplace l'ancien `.vibeflow-cache` git-cloné).

## Authentication & Identity

Aucune pour l'utilisateur final. Zéro secret dans le repo, zéro `.env`, zéro clé API. L'install est
anonyme (repo public, `git ls-remote` sans credentials). Seul secret CI : `TRAFFIC_PAT`
(workflow `traffic-snapshot.yml`, non posé). Le `--qui` de `deroger-gate.sh` est déclaratif
(limite T-45-34) : aucune identité vérifiée.

## Monitoring & Observability

**Error Tracking :** aucun service externe. Logs stderr préfixés par script (`[vibeflow-update]`,
`[ensure-deps]`, `[preflight]`, `[recalc-planning]`, `[deroger-gate]`…). Bandeau d'update
best-effort en SessionStart (`update-banner.sh`). Canary de session `check-gates-alive.sh` pour
l'état du hook central ; `plugin/conductor/scripts/check-guard-health.sh` pour les gardes du
conductor.

## Environment Configuration

**Required env vars :** aucune obligatoire. Variables d'outillage : `VF_SCOPE`, `VIBEFLOW_CACHE`,
`VF_RUNTIME`, `VF_ENSURE_*`, `GSD_HOME` (détail : `.planning/codebase/STACK.md`). Entrées
runtime Claude Code lues par les hooks : `CLAUDE_PROJECT_DIR`, `HOME`, `XDG_CACHE_HOME`, `TMPDIR`.
**Secrets location :** aucun secret versionné ; `TRAFFIC_PAT` serait un secret de dépôt GitHub.

## Webhooks & Callbacks

**Incoming :** aucun.
**Outgoing :** aucun webhook — seules sorties réseau : `git ls-remote` (check update), `npx`/`npm
view` (GSD), `claude plugin install/marketplace` (Superpowers), `gh api` (outillage et CI du
dépôt).

---

*Integration audit: 2026-10-02*
