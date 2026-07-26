# External Integrations

**Analysis Date:** 2026-07-26

## APIs & External Services

**GitHub (repo PUBLIC `picmakpro/vibeflow-os`) :**
- Rôle : hébergement du marketplace Claude Code ET du plugin. Le repo héberge son propre
  `.claude-plugin/marketplace.json` (racine) qui pointe `"source": "./plugin"`.
- Install **zéro-auth** (`INSTALL.md:19` : « Aucun accès privé, aucun clone, aucune auth `gh` ne
  sont requis ») :
  ```bash
  claude plugin marketplace add picmakpro/vibeflow-os
  claude plugin install vibeflow
  ```
- Mise à jour : `/vf-update` (commande `plugin/commands/vf-update.md`, script
  `plugin/conductor/scripts/vf-update-run.sh`) ou `claude plugin update vibeflow@vibeflow-os`
  (identifiant complet obligatoire, piège du cache de catalogue documenté dans `INSTALL.md`).
- Accès réseau sortant du plugin installé : `plugin/conductor/scripts/check-plugin-update.sh`
  fait un `git ls-remote` (sans clone, `GIT_TERMINAL_PROMPT=0`, bornes lowSpeed) vers le repo
  pour comparer le plus grand tag `vX.Y.Z` à la version installée. Best-effort, jamais bloquant,
  cache `${XDG_CACHE_HOME:-~/.cache}/vibeflow/update-check.json`, consommé par le bandeau
  SessionStart `plugin/conductor/scripts/update-banner.sh`.

**npm registry :**
- `plugin/dev-orchestrator/scripts/ensure-deps.sh` installe GSD via
  `npx -y @opengsd/gsd-core@latest --claude --global|--local` (non-interactif, scope-aware ; pin
  `@latest`, jamais `@next` — dist-tag amont périmé). Depuis Phase 11, remplace l'ancien
  `get-shit-done-cc` (déprécié) ; fenêtre de compatibilité : l'ancien layout
  `~/.claude/get-shit-done/` reste détecté (jamais réinstallé) pour les labs pas encore migrés.

**Marketplace officiel Anthropic :**
- `ensure-deps.sh` installe Superpowers via
  `claude plugin install superpowers@claude-plugins-official --scope <scope>`, avec fallback
  `claude plugin marketplace add anthropics/claude-plugins-official` puis retry, puis étape
  manuelle affichée (jamais d'échec silencieux).

## Chaîne d'install (cache plugin → engine scope-aware)

**PLUS de git clone depuis la Phase 3.** L'en-tête de `plugin/_internal/vibeflow-update.sh` est
explicite : « Source : le cache local fourni par l'appelant (`VIBEFLOW_CACHE`, défaut
`.vibeflow-cache`). Plus de clone/pull git : le cache DOIT exister (sinon erreur). » La commande
`sync` est un **no-op**.

Chaîne complète :
1. `claude plugin install vibeflow` → Claude Code copie le bundle `plugin/` (modules + skill
   `installer/` + engine `_internal/` + commandes) dans son cache de plugins.
2. L'utilisateur lance **manuellement** `/vibeflow-install` (`plugin/installer/SKILL.md`) —
   aucune ouverture automatique au démarrage de session (`INSTALL.md:57-60`).
3. `plugin/installer/scripts/preflight.sh` — prérequis durs (git, jq, python3 exécutable) +
   sondes ADR-054 (CRLF jq, stub python3 Microsoft Store).
4. `plugin/installer/scripts/build-module-catalog.sh` — catalogue des modules depuis le cache
   (toggles multi-select de l'UX).
5. `plugin/_internal/resolve-deps.sh` — fermeture transitive des `requires` des `module.json`
   (ex. `conductor` requiert `planning-core`, `validator`, `skill-creator`), récapitulée avant
   install.
6. `plugin/_internal/vibeflow-update.sh` — engine scope-aware :
   - `--scope user` → `~/.claude` ; `--scope project|local` → `./.claude` (local ajoute les
     chemins au `./.gitignore`) ; `VF_SCOPE` en env, `--scope` prioritaire.
   - Commandes : `install [--with-deps|--all]`, `update [--all]`, `uninstall [--all]`,
     `rollback`, `status`.
   - Registre des modules installés : `.vibeflow-installed` ; backup automatique avant
     écrasement/suppression ; cleanup des modules retirés via
     `plugin/_internal/retired-modules.txt` (convergence à `update --all`).
7. `plugin/dev-orchestrator/scripts/ensure-deps.sh` — pose GSD + Superpowers au même scope
   (`VF_SCOPE` unique partout, cohérence ID4).

Désinstallation en deux couches (ordre imposé, `INSTALL.md`) : modules d'abord
(`vibeflow-update.sh uninstall --all` tant que l'engine est en cache), plugin ensuite
(`claude plugin uninstall vibeflow`). GSD/Superpowers ne sont jamais désinstallés automatiquement.

## Hooks Claude Code posés par les modules

Chaque module porteur d'un fragment `hooks/hooks.json` le fait merger dans le `settings.json`
du lab par `plugin/_internal/merge-hooks.sh` (merge/retrait idempotent, python3 embarqué,
placeholder `{{VF_SCRIPTS}}` → préfixe scripts du scope) — ADR-043 : la gouvernance est POSÉE
par la machine, jamais copiée-collée. La CI « lab frais » vérifie leur présence
(`grep -q "guard" .claude/settings.json`).

| Module | Fragment | Événements | Rôle |
|---|---|---|---|
| conductor | `plugin/conductor/hooks/hooks.json` | PreToolUse(Write), SessionStart | `guard-agent-write.sh` (agents natifs ADR-044), `check-agents.sh --hook`, `check-debug-research.sh` (ADR-045), `update-banner.sh` |
| planning-core | `plugin/planning-core/hooks/hooks.json` | SessionStart, UserPromptSubmit, Stop | fraîcheur + digest index-first, 8e signal de dette, baseline de session (ADR-040/050/055) |
| consolidator | `plugin/consolidator/hooks/hooks.json` | PreToolUse, PostToolUse, SessionStart, SessionEnd | gouvernance mémoire machine-enforced (ADR-032) : lecture index-first bloquante, réindex, archivage |
| software-architecture | `plugin/software-architecture/hooks/hooks.json` | PreToolUse | porte blindée Iron Law 300L (ADR-035) |
| infrastructure-audit | `plugin/infrastructure-audit/hooks/hooks.json` | SessionStart | audit de drift si snapshot > 14 jours (ADR-031/043) |

Note : `INSTALL.md:151` (« le plugin n'enregistre aucun hook ») parle du **plugin bundle**
lui-même — les hooks ci-dessus sont posés dans le lab par l'engine à l'install des modules,
pas par le plugin au chargement.

## CI/CD & Deployment

**CI Pipeline :** `.github/workflows/ci.yml` (push toutes branches + pull_request), 3 jobs sur
`ubuntu-latest`, principe F13 « contrat de découverte » : une découverte vide = échec, jamais un
vert par absence de cible (vacuous green).

- **`tests`** — découvre et lance **toutes les suites** `plugin/**/tests/test-*.sh` et
  `scripts/**/tests/test-*.sh` (**37 suites** sur disque au 2026-07-26) ; 0 suite découverte =
  exit 1.
- **`gates`** — `check-agents.sh --strict` sur chaque `plugin/*/agents` (0 dossier = échec) ;
  `scripts/check-version-sync.sh` (canon VERSION ↔ plugin.json ↔ marketplace ↔ badges README ↔
  triade VERSION/module.json/CHANGELOG par module) ; `scripts/check-release-tag.sh --remote`
  (**main uniquement** — une branche de feature porte légitimement une VERSION pas encore
  taggée).
- **`lab-frais`** (leçon UAT 2026-07-25, F2) — installe la baseline dans un lab vierge
  (`mktemp -d` + `git init`) avec le **vrai engine** :
  `closure=$(resolve-deps.sh conductor)` puis
  `VIBEFLOW_CACHE=$GITHUB_WORKSPACE/plugin VF_SCOPE=project vibeflow-update.sh install <m>`
  pour chaque module ; puis **Gate C** sans intervention : `.claude/scripts/check-agents.sh
  --strict`, `.claude/scripts/check-registres.sh --strict --allow-empty` (rc 0 ou 3 tolérés),
  hooks de gouvernance présents dans `.claude/settings.json`.

**Hosting :** GitHub, repo public. Pas de déploiement applicatif — la « release » = tag annoté
`vX.Y.Z` sur main (discipline CLAUDE.md, garde-fous `scripts/check-release-tag.sh` +
`scripts/hooks/pre-push`).

## Data Storage

**Databases :** aucune.
**File Storage :** filesystem local uniquement — cache plugin Claude Code
(`~/.claude/plugins/cache`), cibles d'install (`.claude/skills/`, `.claude/agents/`,
`.claude/scripts/`, `.claude/rules/`, `docs/`), registre `.vibeflow-installed`, backups
automatiques, cache update `~/.cache/vibeflow/update-check.json`.
**Caching :** cache de plugins Claude Code (remplace l'ancien `.vibeflow-cache` git-cloné).

## Authentication & Identity

Aucune. Zéro secret dans le repo, zéro `.env`, zéro clé API. L'install est anonyme
(repo public, `git ls-remote` sans credentials).

## Monitoring & Observability

**Error Tracking :** aucun service externe. Logs stderr préfixés par script
(`[vibeflow-update]`, `[ensure-deps]`, `[preflight]`…). Bandeau d'update best-effort en
SessionStart (`update-banner.sh`).

## Webhooks & Callbacks

**Incoming :** aucun.
**Outgoing :** aucun webhook — seules sorties réseau : `git ls-remote` (check update), `npx`
(GSD), `claude plugin install/marketplace` (Superpowers).

---

*Integration audit: 2026-07-26*
