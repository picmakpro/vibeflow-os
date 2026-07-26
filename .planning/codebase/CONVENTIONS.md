# Coding Conventions

**Analysis Date:** 2026-07-26

Repo de **distribution** du plugin Claude Code VibeFlow : 17 modules (`plugin/*/module.json`) +
engine d'install (`plugin/_internal/`) + gates racine (`scripts/`). Stack : bash portable +
markdown (SKILL.md / AGENT.md / agents frontmatter YAML) + micro-python inline dans les hooks.
Tout est en **français** (docs, commentaires, commits, messages d'erreur).

## Naming Patterns

**Files:**
- Scripts shell : `kebab-case.sh` (`check-agents.sh`, `resolve-deps.sh`, `kpis-writer.sh`)
- Docs canoniques : `UPPERCASE.md` (`SKILL.md`, `AGENT.md`, `CHANGELOG.md`, `README.md`, `VERSION`)
- Modules : dossiers `kebab-case` (`planning-core`, `software-architecture`, `mobile-test-team`)
- Agents : `kebab-case.md`, souvent préfixés `vf-` (`plugin/content-bundle/agents/vf-content-writer.md`)
- IDs de registres : `CAPS-DIGITS` (`LRN-106`, `ADR-054`, `BLK-005`)

**Functions (shell):**
- `snake_case` ; helpers courts `ok()`, `ko()`, `skip()`, `err()`
- Wrapper obligatoire `jqx()` pour tout appel jq (voir Portabilité)

**Variables:**
- Env de surcharge : préfixe `VF_` (`VF_SCOPE`, `VF_MODULES_ROOT`, `VF_ARCH_WARN`, `VF_DRIVER_LOCK`) ; exception historique `VIBEFLOW_CACHE` (source des modules pour l'engine, `plugin/_internal/vibeflow-update.sh:81`)
- Constantes shell : `UPPER_SNAKE` ; locales : minuscules

## Densité (ADR-029) — charte machine-visée

- **Agents ≤ 250 lignes, skills ≤ 500 lignes, bootstrap ≤ 2000 tokens** (règle non négociable, `CLAUDE.md` racine + `docs/ADR.md`).
- Outillage : `plugin/software-architecture/scripts/check-file-size.sh` — seuil warn par défaut **250** (`VF_ARCH_WARN`), bloquant via `VF_ARCH_BLOCK` ; hook compagnon `guard-file-size.sh`.
- Compat bash 3.2 exigée par ces scripts (pas de `mapfile`, cf. `check-file-size.sh:75`).

## Agents natifs machine-enforced (ADR-044)

Gate : `plugin/conductor/scripts/check-agents.sh` (lint du frontmatter des agents `.claude/agents/*.md`).

- **BLOQUANT** : frontmatter absent · `name` absent/invalide · `description` absente · `model` absent ou hors `{sonnet, opus, haiku, fable, inherit, claude-*}` · `memory` absente ou hors `{user, project, local}` · `effort`/`permissionMode`/`isolation`/`background`/`maxTurns` invalides.
- **WARNING** : `skills` absent · skill déclaré introuvable (ERROR en `--strict`) · description < 30 caractères · `tools` absent · champ inconnu · `name` ≠ nom de fichier.
- `--strict` : les skills déclarés doivent EXISTER ; résolution par nom de dossier PUIS par le `name:` du frontmatter des SKILL.md installés.
- **`vf-internal: true`** : worker interne dispatché uniquement par un orchestrateur → pas de commande d'incarnation exposée (Pattern 12, cf. `plugin/conductor/scripts/generate-agent-commands.sh`).
- Enforcement continu : hook PreToolUse `guard-agent-write.sh` (bloque l'écriture d'un agent non conforme) + SessionStart `check-agents.sh --hook` (`plugin/conductor/hooks/hooks.json`).

## Portabilité bash (ADR-054) — règles dures

Leçon des 2 rapports terrain Windows 11 + Git Bash (2026-07) :

- **`set -uo pipefail` SANS `-e`** : c'est le préambule standard (63 scripts). Chaque échec est capturé et rendu BRUYANT explicitement (`rc=$?` puis verdict), jamais un abort implicite. Quelques scripts de l'engine gardent `set -euo pipefail` (ex. `plugin/_internal/vibeflow-update.sh`) — n'en ajoute pas de nouveaux.
- **jq nu interdit** : toujours via `jqx() ( set -o pipefail; command jq "$@" | tr -d '\r'; )` — normalise le CRLF du jq Windows, propage le code retour. Gate T7 de `plugin/_internal/tests/test-windows-crlf.sh`.
- **Pas de `mapfile`/`readarray`** (bash 3.2 macOS = rc 127) → `while read` + process substitution (`plugin/consolidator/scripts/reindex.sh:358`).
- **Pas de `sed -i` nu** : forme portable `sed -i.bak … && rm -f …bak` (macOS vs GNU).
- **Pas de `grep -P`** (aucune occurrence dans `plugin/`) ; `[[:space:]]` plutôt que `\s`.
- **python3 résolu par CHEMIN** dans les hooks : rejet du stub `WindowsApps`, repli `python` (`case "$(command -v python3)" in ''|*WindowsApps*)`).
- **Chemins de scripts pleinement qualifiés** dans les SKILL.md (jamais de nom nu deviné par le LLM).
- `.gitattributes` force `eol=lf` ; préflight bloquant `plugin/installer/scripts/preflight.sh` (git, jq, python3 réel, bash dans le PATH).

**Codes de sortie normalisés** : `0` conforme · `1` non conforme · `2` erreur d'usage · **`3` = INDÉTERMINÉ** (cible absente/vide : aucun verdict — jamais de « vert par absence de cible », contrat F13).

**Logs/erreurs** : `[nom-script] ✗ message` sur stderr ; `ok()`/`ko()` avec `✓`/`✗`.

## Discipline de release (règle non négociable)

- **Toute VERSION racine = un tag git annoté `vX.Y.Z`** poussé sur origin (le tag reprend exactement `VERSION`, préfixe `v` inclus). Cause : dérive de `main` en 2026-07 (v2.10→v2.16 jamais taggées).
- **Sources synchronisées** (gate `scripts/check-version-sync.sh`, 7 contrôles) : `VERSION` ↔ `plugin/.claude-plugin/plugin.json` ↔ `.claude-plugin/marketplace.json` ↔ badges version des 2 README ↔ compteur de modules (badges + phrase « N modules ») ↔ **triade par module** (`plugin/<mod>/VERSION` ↔ `module.json .version`) ↔ première entrée d'historique des README = VERSION courante.
- Outillage : `scripts/bump.sh` (bump toutes sources + squelette CHANGELOG), `scripts/check-release-tag.sh --remote` (vérifie tag local + poussé), hook pre-push optionnel (`git config core.hooksPath scripts/hooks`).
- Numérotation : nouveau module/capacité → **minor** ; correctif/doc/durcissement → **patch**.

## Commits

- **En français**, style `type(scope): résumé` : `release: v2.36.1 — …`, `fix(gates): …`, `docs(readme): …`, `fix(baseline): …`.
- Jamais de fix sans validation humaine (ADR-031).

## Documentation FR/EN

- Racine bilingue : `README.md` (EN) + `README.fr.md` (FR) **synchronisés** — badges, compteur de modules (« N modules, each versioned » / « N modules, chacun versionné ») et historique vérifiés machine par `check-version-sync.sh`.
- Docs internes de modules (CHANGELOG, SKILL.md, ADR) : français uniquement.
- ADRs canoniques dans `docs/ADR.md` (index + définitions héritées) ; référencer l'ADR dans les en-têtes de scripts (`# … (ADR-044)`).

## Structure d'un module

Layout canonique (`plugin/<module>/`) :

```
plugin/conductor/
├── VERSION            # vX.Y.Z du module (triade avec module.json — gate VG-2)
├── module.json        # name, version, type, description, mandatory, requires[]
├── CHANGELOG.md       # historique du module (avec sections « validé en production »)
├── README.md          # vitrine du module (en-tête Version alignée — gate)
├── AGENT.md et/ou SKILL.md   # incarnation (frontmatter YAML : name, description, model, memory, skills)
├── agents/            # agents additionnels *.md (lintés par check-agents --strict en CI)
├── skills/            # skills embarqués (<skill>/SKILL.md)
├── hooks/hooks.json   # hooks mergés à l'install (placeholder {{VF_SCRIPTS}} résolu par merge-hooks.sh)
├── scripts/           # exécutables du module
│   └── tests/         # test-*.sh + fixtures/ (découverts par la CI)
└── references/        # doc préchargeable
```

- `mandatory: true` + `requires: []` pilotent la baseline (`plugin/_internal/resolve-deps.sh`).
- Cas particuliers sans `module.json` : `plugin/_internal/` (engine) et `plugin/installer/` (skill d'install marketplace).
- Hooks SessionStart advisory → suffixe `|| true` ; hooks PreToolUse guards → bloquants, fail-open uniquement si interpréteur absent (avec signal `probe-memory-guards.sh`).

---

*Convention analysis: 2026-07-26*
