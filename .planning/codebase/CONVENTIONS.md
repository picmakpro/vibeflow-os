# Coding Conventions

**Analysis Date:** 2026-10-02

Repo de **distribution** du plugin Claude Code VibeFlow : 17 modules (`plugin/*/module.json`) +
engine d'install (`plugin/_internal/`) + gates racine (`scripts/`). Stack : bash portable +
markdown (SKILL.md / AGENT.md / agents frontmatter YAML) + micro-python inline dans les hooks.
Tout est en **français** (docs, commentaires, commits, messages d'erreur).

## Naming Patterns

**Files:**
- Scripts shell : `kebab-case.sh` (`check-agents.sh`, `resolve-deps.sh`, `kpis-writer.sh`, `planning-hook.sh`)
- Suites : `test-<script-ou-module>.sh` sous un dossier `tests/` (découvertes par la CI, voir `.planning/codebase/TESTING.md`)
- Docs canoniques : `UPPERCASE.md` (`SKILL.md`, `AGENT.md`, `CHANGELOG.md`, `README.md`, `VERSION`)
- Modules : dossiers `kebab-case` (`planning-core`, `software-architecture`, `mobile-test-team`)
- Agents : `kebab-case.md`, souvent préfixés `vf-` (`plugin/content-bundle/agents/vf-content-writer.md`)
- IDs de registres : `CAPS-DIGITS` (`LRN-106`, `ADR-054`, `BLK-005`)

**Functions (shell):**
- `snake_case` ; helpers courts `ok()`, `ko()`, `skip()`, `err()`, `diag()`
- Wrapper obligatoire `jqx()` pour tout appel jq (voir Portabilité)
- Traduction de code de sortie vers le harnais : une fonction nommée `hook_exit()` par script de hook (voir Contrat de sortie des hooks)

**Variables:**
- Env de surcharge : préfixe `VF_` (`VF_SCOPE`, `VF_MODULES_ROOT`, `VF_ARCH_WARN`, `VF_DRIVER_LOCK`) ; exception historique `VIBEFLOW_CACHE` (source des modules pour l'engine, `plugin/_internal/vibeflow-update.sh`)
- Constantes shell : `UPPER_SNAKE` ; locales : minuscules
- Constantes d'armement d'un gate : `ARMEMENT_<GATE>` (`plugin/planning-core/scripts/planning-hook.sh`)

**Identifiants de décision, de limite et de test (hook central et phases) :**
- Décision d'un registre : `P45-D-20`, `P44-D-14` (préfixe du registre d'origine, voir Traçabilité) ; suffixe de lettre pour un amendement (`P45-D-12a`, `P45-D-06b`).
- Exigence : `GATE-08`, `PROT-05`, `PORT-05`, `QUAL-01` ; limite déclarée du modèle : `limite (a)` à `(ae)` dans `plugin/planning-core/references/modele-cycles.md`.
- Famille de tests : `R-<SUJET>-NN` (`R-CMD-01`, `R-G6-06`, `R-REJEU-ETAPE`) ; mutant : `MUT-<NOM>` (`MUT-CROISE-JUGE`) ; cas de canary : `<GATE>-<cas>` dans la table `CANARIS` de `plugin/planning-core/scripts/check-gates-alive.sh`.

## Densité (ADR-029) — charte machine-visée

- **Agents : avertissement dès 251 lignes, bloque au-delà de 300 ; skills ≤ 500 lignes, bootstrap ≤ 2000 tokens** (règle non négociable, `CLAUDE.md` racine + `docs/ADR.md`).
- Outillage : `plugin/software-architecture/scripts/check-file-size.sh` — seuil warn par défaut **250** (`VF_ARCH_WARN`), bloquant via `VF_ARCH_BLOCK` ; hook compagnon `guard-file-size.sh`.
- Budget d'instructions : `plugin/conductor/scripts/check-instruction-budget.sh` contre la baseline `.planning/instruction-budget-baselines.tsv` ; la colonne INSTRUCTIONS est la seule bloquante, sa hausse exige une citation d'arbitrage (G-1, voir Traçabilité).
- Compat bash 3.2 exigée par ces scripts (pas de `mapfile`).

## Agents natifs machine-enforced (ADR-044)

Gate : `plugin/conductor/scripts/check-agents.sh` (lint du frontmatter des agents `.claude/agents/*.md`).

- **BLOQUANT** : frontmatter absent · `name` absent/invalide · `description` absente · `model` absent ou hors `{sonnet, opus, haiku, fable, inherit, claude-*}` · `memory` absente ou hors `{user, project, local}` · `effort`/`permissionMode`/`isolation`/`background`/`maxTurns` invalides.
- **WARNING** : `skills` absent · skill déclaré introuvable (ERROR en `--strict`) · description < 30 caractères · `tools` absent · champ inconnu · `name` ≠ nom de fichier.
- `--strict` : les skills déclarés doivent EXISTER ; résolution par nom de dossier PUIS par le `name:` du frontmatter des SKILL.md installés. `--resolve-agents=strict` ferme le monde des agents (union de tous les `plugin/*/agents`).
- **Invariants de rôle** (messages `invariant I1`..`I7` de `check-agents.sh`) : I5 un **juge** (`disallowedTools` retire Write et Edit, aucune allowlist `Agent(...)`) exige `omitClaudeMd: true` ; I6 un **manager** (allowlist `Agent(...)` non vide, non `vf-internal`) exige `SendMessage` dans `tools:` ; I1 `vf-internal: true` ⇔ marqueur « Worker interne » dans `description:` ; I2/I3 monde fermé des workers dispatchés. Le hook central `planning-hook.sh` réimplémente I5/I6 pour dériver le rôle ; le contrôle croisé est `scripts/tests/test-role-hook-vs-check-agents.sh` : tout changement d'un prédicat se fait dans les deux endroits.
- **`vf-internal: true`** : worker interne dispatché uniquement par un orchestrateur → pas de commande d'incarnation exposée (Pattern 12, cf. `plugin/conductor/scripts/generate-agent-commands.sh`).
- Enforcement continu : hook PreToolUse `guard-agent-write.sh` (bloque l'écriture d'un agent non conforme) + SessionStart `check-agents.sh --hook` (`plugin/conductor/hooks/hooks.json`).

## Portabilité bash (ADR-054) — règles dures

Leçon des 2 rapports terrain Windows 11 + Git Bash (2026-07) :

- **`set -uo pipefail` SANS `-e`** : c'est le préambule standard (192 scripts sous `plugin/` et `scripts/`). Chaque échec est capturé et rendu BRUYANT explicitement (`rc=$?` puis verdict), jamais un abort implicite. Une vingtaine de scripts gardent `set -euo pipefail` (ex. `plugin/_internal/vibeflow-update.sh`) — n'en ajoute pas de nouveaux. Le lanceur de hook `planning-hook.sh` utilise `set -u` seul, son rôle étant de ne rien décider.
- **jq nu interdit** : toujours via `jqx() ( set -o pipefail; command jq "$@" | tr -d '\r'; )` — normalise le CRLF du jq Windows, propage le code retour. Gate T7 de `plugin/_internal/tests/test-windows-crlf.sh`.
- **Pas de `mapfile`/`readarray`** (bash 3.2 macOS = rc 127) → `while IFS= read -r` + process substitution (`plugin/consolidator/scripts/reindex.sh`, rotation des backups).
- **Pas de `sed -i` nu** : forme portable `sed -i.bak … && rm -f …bak` (macOS vs GNU) ; dans les suites, aucun `sed -i`.
- **Pas de `grep -P`** (aucune occurrence exécutable dans `plugin/` ni `scripts/`) ; `[[:space:]]` plutôt que `\s`.
- **Ni `readlink -f`, ni `stat -f/-c`, ni `timeout`, ni tableau associatif** (`declare -A`) ; comparaisons de fichiers par `cmp -s` ou `comm`, jamais `diff` (proxifié et trompeur sur certains postes).
- **Comptes et balayages de gate en `awk`**, pas par un `grep` pipé : le grep de certains runtimes tronque silencieusement (`scripts/check-machine-paths.sh`).
- **python3 résolu par CHEMIN** dans les hooks : rejet du stub `WindowsApps`, repli `python` (`case "$(command -v python3)" in ''|*WindowsApps*)`) ; le cœur embarqué se lance en `"$PYBIN" -I -S -` (mode isolé).
- **Chemins de scripts pleinement qualifiés** dans les SKILL.md (jamais de nom nu deviné par le LLM).
- **Aucun chemin absolu de poste dans un fichier versionné** (le dossier personnel d'un vrai compte, sous macOS comme sous Linux) : gate `scripts/check-machine-paths.sh`. Écrire un chemin relatif au dépôt, ou un segment de compte non identifiant (`<user>`), ou un placeholder fermé (`dev`, `runner`, `user`) ; le marqueur `vf-allow-machine-path` sur la ligne n'est que pour le cas où le littéral EST le sujet (une suite qui fabrique un chemin fautif).
- `.gitattributes` force `eol=lf` ; préflight bloquant `plugin/installer/scripts/preflight.sh` (git, jq, python3 réel, bash dans le PATH).

## Contrat de sortie des hooks et codes de sortie

Source durable : `docs/HOOKS-CONTRAT-SORTIE.md` (inventaire machine-recompté des entrées de hooks).

**Frontière harnais** : `0` = rien à signaler ou signal émis ; non nul = le script n'a pas pu travailler ; `2` = blocage explicite voulu, jamais émis involontairement (seul `plugin/planning-core/scripts/guard-planning-updated.sh`, hook `Stop`, bloque par `exit 2`).

**Flux** : le silence est un contrat de flux — stdout **strictement vide** (zéro octet) sur le chemin nominal, diagnostics humains sur **stderr** (`diag()`), jamais sur stdout (le stdout d'un `SessionStart` est injecté dans la session). Quand un hook parle : **UN SEUL** objet JSON, produit par un encodeur (`json.dumps`, `jq -n`), jamais par concaténation de chaînes ; vérifier avec un parseur de document (`json.loads`), jamais avec `jq` (qui accepte `{…}{…}`).

**Codes internes des scripts de gate** (tous énumérés dans l'en-tête de chaque script) : `0` conforme · `1` non conforme · `2` NON VÉRIFIABLE (base introuvable, entrée imparsable) · `3` silence non bloquant (rien à juger, plage vide, cible vide — jamais un vert, contrat F13) · `4` INDÉTERMINÉ où le script distingue SAIN de INDÉTERMINÉ (`check-gates-alive.sh` : `3` SAIN, `4` INDÉTERMINÉ) · `64` erreur d'usage (argument inconnu, valeur manquante).

**Traduction `--hook`** : sous `--hook` seulement, un script traduit `3` (et `4`) en `0` via `hook_exit()` ; sans le drapeau (CLI, suites) les codes restent intacts. Hooks SessionStart advisory en forme shell → suffixe `|| true`.

**Hook central de planning-core** (`plugin/planning-core/scripts/planning-hook.sh`, commande enregistrée dans `plugin/planning-core/hooks/hooks.json`, matcher `Write|Edit|NotebookEdit|Bash|Agent|Task`, `timeout` 20) :
- **Fail-closed dans un lab adhérent** : un lab est adhérent quand `.planning/config.json` porte `"planning_version": "cycles-v1"`. La commande enregistrée reprend tout code non nul du lanceur : script absent, `python3` absent, faute du lanceur (codes `3`, `70` mktemp, `71` stdin, `72` interpréteur, `73` échéance interne `ECHEANCE_COEUR_S = 8.0`) → `permissionDecision: deny` pour Write, Edit, NotebookEdit, Agent, Task ; **`Bash` reste ouvert** (limite déclarée, P45-D-06b). Hors lab adhérent (labs dev, ce dépôt compris) : stdout d'octet vide et code 0 (GATE-10, P45-D-04).
- **Un refus est un JSON `hookSpecificOutput` avec code 0**, jamais `exit 2` (P45-D-08) ; un avertissement (G2) passe par `additionalContext`, jamais par `permissionDecision`.
- **Armement dans le code livré** : une constante par gate, une ligne chacune, valeurs `observe` (calcule, journalise, laisse passer) ou `armed` (refuse), commentée `# etape-N` ; la table de la suite (`TABLE_ATTENDUE` de `plugin/planning-core/scripts/tests/test-planning-gates.sh`) et la référence du modèle suivent dans le MÊME commit. Aucune variable d'environnement ne change l'armement ni l'adhésion (P45-D-12a) : le cœur Python ne lit AUCUNE variable d'environnement ; le lanceur ne lit que `TMPDIR`, `XDG_CACHE_HOME`, `HOME` et les passe en arguments, chacune choisit un chemin, jamais une décision. La racine du lab se dérive du chemin écrit puis du `cwd` du payload, jamais de `$CLAUDE_PROJECT_DIR` (P45-D-12).
- **Livraison** : cœur Python en heredoc quoté dans le script (`<<'PY_PLANNING_HOOK_EOF'`), aucun fichier `.py` posé ; payload par fichier `mktemp` 0600 supprimé par `trap`, jamais par argv.
- **Lignes marqueurs** : chaque ligne qu'un mutant vise porte un commentaire marqueur unique (`# role-juge`, `# echeance-armee`, `# motif-adhesion-repli`) pour que `make_script_mutant` trouve un motif à occurrence unique.
- **Dérogation** : uniquement par `plugin/planning-core/scripts/deroger-gate.sh` (nominative, usage unique, citée, journal append-only), jamais liée à l'urgence, sans effet en `observe`.
- **Canary de session** `plugin/planning-core/scripts/check-gates-alive.sh --hook` : rejoue la commande de référence sur un lab synthétique et signale (jamais ne bloque) ; n'exécute jamais une autre commande que la référence.

## Traçabilité des arbitrages, marqueurs de gate et identifiants de décision

**Citation d'arbitrage** (`CLAUDE.md` § Traçabilité) : un commit, une ligne de code ou un document qui invoque une décision humaine nomme le **canal et la date** : « arbitrage Samuel, AskUserQuestion session principale, 2026-09-09 », « Willy, AskUserQuestion session principale, 2026-10-01 ». Forme vérifiée par `scripts/check-baseline-arbitrage.sh` (G-1) : une ligne du message portant `arbitrage` ou `décision`/`decision`, **au moins deux virgules** et une **date ISO** `AAAA-MM-JJ`. La forme est vérifiée, jamais la véracité : un simple « arbitrage Samuel » a la même forme vrai ou fabriqué, d'où la forme longue.
- Une décision du **manager** (agent `vf-dev-manager`) n'est pas un arbitrage humain : l'écrire « décisions du manager vf-dev-manager, <date> » ; ce n'est pas un marqueur d'autorité et ce libellé ne doit jamais s'écrire « arbitrage ».
- Une hausse de la colonne INSTRUCTIONS de `.planning/instruction-budget-baselines.tsv`, ou la neutralisation d'une sentinelle `.planning/.*-armed`, exige cette citation dans le commit non-merge qui porte le changement (G-1).

**Préfixage des identifiants de décision (ADR-075)** : un identifiant court porte son registre d'origine : `P41-D-02` (décision D-02 du registre de la Phase 41), `P45-D-20` (Phase 45), `PART-D-02` (mission « partition »). Motif : deux registres numérotés chacun depuis `D-01` se confondent, et l'outil `.planning/workstreams/fiabilite/phases/VFDO-41-posture-de-protection-du-d-p-t/tools/check-trace-arbitrage.sh` reconnaît seulement `P41-D-01`..`P41-D-10` (avec « arbitrage Samuel », « sur arbitrage », « décision de Samuel », `*-DECISION:`) comme marqueur d'invocation d'autorité. Un `D-02` nu reste lisible en prose mais n'engage plus aucun outil. Règle prospective : on ne réécrit jamais un identifiant déjà posé dans l'historique. Un nouveau registre choisit son préfixe (`P<phase>-D-NN`, `<MISSION>-D-NN`) avant d'écrire la première décision.

**Marqueur `Gate-Touche:`** (G-2, `scripts/check-gate-touche.sh`) : tout commit qui touche un gate, sa suite, le workflow CI ou un hook porte un trailer
```
Gate-Touche: <chemin-ou-motif> — <raison de 10 caractères non blancs au moins>
```
- Surface : `plugin/conductor/scripts/check-*.sh`, `scripts/check-*.sh`, leurs suites (`plugin/conductor/scripts/tests/test-*.sh`, `scripts/tests/test-*.sh`), `.github/workflows/ci.yml`, tout chemin sous `scripts/hooks/`. Statuts A, M, D, R comptent tous comme « touché » (un gate supprimé est la modification la plus radicale).
- **Un trailer = un chemin ou un motif glob, jamais une liste séparée par des virgules** (une virgule rend le trailer `MARQUEUR-MAL-FORME` : `case` ne fait pas d'union). Séparateur nominal ` — ` ; ` - ` accepté.
- Portée **branche** : un commit ultérieur de la même branche peut couvrir un chemin touché plus tôt ; ne jamais réécrire un commit déjà poussé. Déclaratif : forme et présence vérifiées, jamais la véracité de la raison.
- Les commits du hook central posent aussi le trailer sur les fichiers de `plugin/planning-core/` qui gardent le hook (`hooks.json`, `planning-hook.sh`, `check-gates-alive.sh`, suites) même hors de la surface G-2 : reproduire ce geste.
- Codes : `0` déclaré · `1` `CHEMIN-NON-DECLARE` ou `MARQUEUR-MAL-FORME` · `2` non vérifiable · `3` rien à juger ou plage vide · `64` usage.

**Limite de fond** : une garde qui vit dans le dépôt peut être modifiée par la PR qu'elle juge ; elle rend visible et trace, elle ne verrouille rien (ADR-072). Ne jamais présenter G-1 à G-4 comme une fermeture.

## Discipline de release (règle non négociable)

- **Toute VERSION racine = un tag git annoté `vX.Y.Z`** poussé sur origin (le tag reprend exactement `VERSION`, préfixe `v` inclus), plus une release GitHub sur le tag. Cause : dérive de `main` en 2026-07 (v2.10→v2.16 jamais taggées).
- **Une release ne se déclenche que pour une évolution fonctionnelle** (ADR-073, `CLAUDE.md` « Quand publier ») : une PR de doc, de specs ou de planning (`docs/`, `.planning/`) se merge sans release.
- **Sources synchronisées** (gate `scripts/check-version-sync.sh`, 7 contrôles) : `VERSION` ↔ `plugin/.claude-plugin/plugin.json` ↔ `.claude-plugin/marketplace.json` ↔ badges version des 2 README ↔ compteur de modules (badges + phrase « N modules ») ↔ **triade par module** (`plugin/<mod>/VERSION` ↔ `module.json .version`) ↔ première entrée d'historique des README = VERSION courante.
- Outillage : `scripts/bump.sh` (bump toutes sources + squelette CHANGELOG), `scripts/check-release-tag.sh --remote` (vérifie tag local, tag poussé et release GitHub), hook pre-push optionnel (`git config core.hooksPath scripts/hooks`).
- Numérotation : nouveau module/capacité → **minor** ; correctif/durcissement → **patch**.

## Commits

- **En français**, style `type(scope): résumé` : `release: v2.36.1 — …`, `fix(planning-core): …`, `docs(planning): …`, `test(planning-gates): …`, `docs(missions): …`. Le scope est le module ou la zone touchée ; un correctif d'un lot de quick porte son identifiant en fin de titre (`(quick 261001-wtd)`).
- Le corps cite les arbitrages avec canal et date (voir Traçabilité) et nomme la décision préfixée (`P45-D-12a`), jamais un `D-NN` nu.
- Les commits qui portent un changement non fonctionnel le disent : « Aucune release, VERSION inchangée (ADR-073) ».
- Jamais de fix sans validation humaine (ADR-031).
- Une branche par PR ; un écrivain = un worktree (ADR-064).

## Documentation FR/EN

- Racine bilingue : `README.md` (EN) + `README.fr.md` (FR) **synchronisés** — badges, compteur de modules (« N modules, each versioned » / « N modules, chacun versionné ») et historique vérifiés machine par `check-version-sync.sh`.
- Docs internes de modules (CHANGELOG, SKILL.md, ADR) : français uniquement.
- ADRs canoniques dans `docs/ADR.md` (index + définitions héritées) ; référencer l'ADR dans les en-têtes de scripts (`# … (ADR-044)`).
- En-tête d'un script ou d'une suite : décrit le contrat (usage, codes de sortie énumérés, limites nommées) ; un script de gate nomme sa **limite de fond** et ce qu'il ne couvre pas, jamais un mot d'achevement pour une observation seulement « signalée et tracée ».

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
└── references/        # doc préchargeable (ex. plugin/planning-core/references/modele-cycles.md)
```

- `mandatory: true` + `requires: []` pilotent la baseline (`plugin/_internal/resolve-deps.sh`).
- Cas particuliers sans `module.json` : `plugin/_internal/` (engine) et `plugin/installer/` (skill d'install marketplace).
- Hooks SessionStart advisory → suffixe `|| true` ; hooks PreToolUse de registres/agents (`guard-agent-write.sh`, `guard-read-registres.sh`, `guard-bash-registres.sh`) → décision JSON `deny`, code 0, fail-open si interpréteur absent (avec signal `probe-memory-guards.sh`) ; **le hook central de planning-core fait exception : fail-closed** dans un lab adhérent (voir Contrat de sortie).
- `merge-hooks.sh` purge toute entrée qui référence les mêmes scripts dans TOUS les groupes d'un événement : un hook à plusieurs outils se pose en **une seule entrée** à matcher combiné, jamais en deux entrées sous deux matchers.
- Un script posé chez l'utilisateur vit dans `plugin/<module>/scripts/` ; un gate d'hygiène du dépôt (non distribué aux labs) vit dans `scripts/`.

---

*Convention analysis: 2026-10-02*
