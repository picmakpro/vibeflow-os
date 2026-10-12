# Phase 31 — Anatomie du moteur d'install (nœud `rech-moteur`)

**Produit le** : 2026-08-16, avant la pause de mission. **Régime** : Explore read-only, aucune
écriture de code. **Cible** : vibeflow-os v2.53.0, post-Phase-30, HEAD `378a37c`.
**Statut** : livré et complet — le nœud `rech-moteur` du DAG est `done`, **ne pas le re-dispatcher**.

> Faits constatés sur pièces. Aucune recommandation : les arbitrages appartiennent au cadrage
> (`31-CONTEXT.md`), qui n'a pas encore été écrit.

---

## 1. `plugin/_internal/vibeflow-update.sh` (1036 lignes)

### 1.1 Fonctions

| Lignes | Fonction | Rôle |
|---|---|---|
| 30 | `log` | `echo "[vibeflow-update] $*" >&2` |
| 31 | `err` | idem + `exit 1`, préfixe `ERROR:` |
| 86-88 | `require_cache` | échoue si `$CACHE_DIR` absent |
| 90-99 | `list_available_modules` | itère `$CACHE_DIR/*/`, skip `_internal`, exige `VERSION` |
| 101-104 | `module_version_available` | `cat $CACHE_DIR/$mod/VERSION` sinon `—` |
| 106-113 | `module_version_installed` | grep dans le registre sinon `—` |
| 115-124 | `mark_installed` | **écrit** le registre (tmp+mv) |
| 126-132 | `mark_uninstalled` | **réécrit** le registre sans le module |
| 137-144 | `find_resolver` | cascade cache → voisin du script |
| 149-160 | `resolve_closure` | fermeture transitive, fallback bruyant si résolveur absent |
| 165-173 | `gitignore_add_one` | **écrit** `./.gitignore` (idempotent) |
| 175-244 | `gitignore_add_paths` | énumère les chemins posés d'un module (scope `local` seul) |
| 250-255 | `find_command_generator` | localise `generate-agent-commands.sh` |
| 257-269 | `generate_agent_command_for` | délègue → écrit `commands/<mod>.md` |
| 276-282 | `find_mcp_injector` | localise `inject-mcp-tools.sh` |
| 284-298 | `inject_lab_mcp_into_agents` | délègue → réécrit les `agents/*.md` flaggés |
| 306-311 | `find_engine_lib` | localise `lib/vf-portable.sh` |
| 317 | `VF_ENGINE_LIB_COPIED` | garde d'idempotence intra-processus |
| 319-344 | `copy_engine_lib` | **pose** `scripts/vf-portable.sh` (cp tmp + `mv -f`) |
| 350-355 | `find_hooks_merger` | localise `merge-hooks.sh` |
| 357-363 | `scripts_prefix_for_scope` | préfixe littéral `"$HOME"` vs `"$CLAUDE_PROJECT_DIR"` |
| 365-408 | `merge_module_hooks` | backup settings + délègue à `merge-hooks.sh` (échec propagé, VG-3) |
| 410-436 | `remove_module_hooks` | délègue `remove` (best-effort, échec non propagé) |
| 441-465 | `copy_module_scripts` | **copie** `scripts/*.sh\|.mjs\|.js\|.txt` + `tests/` |
| 477-487 | `seed_module_registres` | lance `seed-registres.sh --quiet` (écrit `.claude/memory/`) |
| 489-500 | `sync_module_governance` | chemin « version inchangée » : lib + scripts + hooks + registres |
| 506-511 | `module_is_mandatory` | grep `"mandatory": true` dans `module.json` |
| 517-530 | `ensure_mandatory_baseline` | installe les modules mandatory manquants |
| 538-543 | `find_retired_manifest` | localise `retired-modules.txt` |
| 545-566 | `cleanup_retired_modules` | **`rm -rf`** des artefacts orphelins + désenregistrement |
| 569-761 | `install_module` | pose complète d'un module (cf. §5) |
| 764-783 | `backup_module` | **copie** vers `$BACKUP_DIR/<mod>-<ts>/` |
| 785-805 | `rollback_module` | **`rm -rf` + `cp`** depuis le dernier backup |
| 808-895 | `uninstall_module` | **`rm`** de tous les artefacts possédés |
| 898-914 | `show_status` | table Module/Installed/Available/Status (stdout) |
| 917-940 | `update_module` | delta version → `install_module`, sinon `sync_module_governance` |

### 1.2 Inventaire EXHAUSTIF des écritures disque — la matière première de MANI-02

**Écritures directes**

- Registre `$TARGET_ROOT/scripts/.vibeflow-installed` : `mkdir -p` 118, `touch` 119, `>` 121, `>>` 122, `mv` 123 ; `>` 129 + `mv` 130 (uninstall).
- `./.gitignore` (scope `local` seul) : `: >` 168, `>>` 170.
- Lib engine : `mkdir -p` 330, `cp` + `mv -f` 336, `rm -f` du tmp 341.
- Backup settings : `mkdir -p` 380, `cp` 381 → `$BACKUP_DIR/settings-<ts>.json`.
- Scripts de module : `mkdir -p` 445, `cp`+`chmod +x` 447, `cp` (.txt) 456, `mkdir -p` 459, `cp -r` 460 et 461, `chmod +x` 462.
- Nettoyage retirés : `rm -rf "$target"` 563.
- `install_module` : `mkdir -p` 595 / `cp` 596 (SKILL.md) · `mkdir -p` 605 / `cp -r` 606 (skills imbriqués) · `mkdir -p` 613 / `cp` 614 (AGENT.md) · `mkdir -p` 621 / `cp` 624 (multi-agents) · `mkdir -p` 634 / `cp -r` 635 (**`docs/<mod>/`, hors TARGET_ROOT, relatif au cwd**) · `mkdir -p` 644 / `cp` 645 (rules) · `mkdir -p` 651 / `cp -r` 652 (references skill) · `mkdir -p` 659 / `cp -r` 660 (references agent) · `mkdir -p` 667 / `cp -r` 668 (config).
- `backup_module` : `mkdir -p` 769, `cp -r` 770, `mkdir -p`+`cp` 772, `cp -r` 773, `mkdir -p` 776, `cp` 779.
- `rollback_module` : `rm -rf` 794, `cp -r` 795, `cp`+`chmod +x` 800.
- `uninstall_module` : `rm -rf` 815, 826 · `rm -f` 834, 852 · `rm` 842, 861, 869, 886 · `rm -rf` 846, 874 · `rmdir` 876, 877, 879.

**Écritures indirectes (sous-processus) — le piège d'un `--dry-run` naïf**

- 264 `generate-agent-commands.sh --agent <mod>` → `$TARGET_ROOT/commands/<mod>.md`
- 293 `inject-mcp-tools.sh --target $TARGET_ROOT/agents --mcp-json ./.mcp.json` → réécrit des `agents/*.md`
- 396-400 / 427-429 `merge-hooks.sh merge|remove` → `settings.json` **et** `settings.local.json`
- 680 `build-gsd-index.sh` (env `VF_INDEX_OUT`) → `agents/<mod>-references/gsd-skills-index.md`
- 695 `build-gsd-capabilities-index.sh` (env `VF_CAPS_INDEX_OUT`) → `gsd-capabilities-index.md`
- 717 `ensure-design-deps.sh --quiet` → installe/corrige une chaîne d'outils design
- 482 (appelée 499 et 738) `seed-registres.sh --quiet` → crée `.claude/memory/*`
- 159 `resolve-deps.sh` (lecture seule) ; `date` 381/767 (horodatage des backups → **non déterministe**, à neutraliser pour un test « dry-run == diff disque réel »)

### 1.3 TARGET_ROOT et scope

- Défaut `VF_SCOPE="${VF_SCOPE:-project}"` (39) — fallback LEGACY d'appel direct ; en production le skill passe toujours un scope explicite.
- Parsing `--scope <v>` / `--scope=<v>` **avant** `cmd="$1"` (43-59), tableau `_positional` re-injecté (61-65, garde bash 3.2 tableau vide).
- Validation stricte `user|project|local` (68-71), sinon `err`.
- Résolution (74-77) : `user → $HOME/.claude` · `project|local → ./.claude`. `export VF_SCOPE` (78).
- Dérivés : `CACHE_DIR="${VIBEFLOW_CACHE:-.vibeflow-cache}"` (81), `INSTALLED_REGISTRY` (82), `BACKUP_DIR="$TARGET_ROOT/.backups"` (83).
- `project` vs `local` diffèrent **uniquement** par `gitignore_add_paths` (gardée en 178) ; le routage `--settings-local` (391-393, 422-424) est actif pour project **et** local.
- Le vocabulaire produit « project-no-commit » = scope `local`.

### 1.4 Chemins d'entrée (`case` 951-1036)

`cmd="$1"` (948), `arg="${2:-}"` (949). **Aucune sous-commande `calibrate` dans l'engine** : `/vf-calibrate` est un skill qui appelle `vibeflow-update.sh update <module>` (`plugin/conductor/skills/vf-calibrate/SKILL.md:72`).

- `install` (952-970) : `--all` · `--with-deps <mod>` (lit `resolve_closure`, strip `\r` 962) · `<mod>` · sinon `err`
- `update` (971-995) : `--all` → `cleanup_retired_modules` (977), boucle registre (979-981), puis `ensure_mandatory_baseline` (986) · `<mod>` → `update_module`
- `uninstall` (996-1020) : `--all` (snapshot figé du registre 1002-1005) · `<mod>`
- `rollback <mod>` (1021-1024) · `status` (1025-1027) · `sync` (1028-1031, no-op explicite) · défaut (1032-1035) : imprime l'entête `# ` en usage, exit 1. Sans argument : idem, exit 0 (943-946).
- Le verbe est `uninstall`, **pas** `remove`. **Aucun flag `--dry-run`, `--plan` ou `--verbose` nulle part.**

### 1.5 Conventions de journalisation

- Un seul helper : `log()` → **stderr**, préfixe fixe `[vibeflow-update] `. Pas de niveaux, **pas de `[ok]` ni de `[plan]`** (le format proposé dans l'issue #20 est donc à créer, pas à réutiliser).
- Sous-lignes indentées de 2 espaces (`log "  copied … → …"`).
- Marqueurs observés : `✓ <mod> <version> installé` (760), `✓ <mod> désinstallé` (894), `✓ <mod> rollback OK` (804), `  ERROR: …` en préfixe manuel (327, 342, 375, 405), `(… best-effort)` pour les dégradations.
- `show_status` est la **seule** sortie stdout (printf tabulé 900-912).
- `merge-hooks.sh` a son propre préfixe `[merge-hooks] `.

### 1.6 Manifestes déjà présents

- **Écrit** : `$TARGET_ROOT/scripts/.vibeflow-installed`, format `module=version` (82, 115-132). Seul état persisté par le moteur.
- **Lus, jamais écrits** : `_internal/retired-modules.txt` (format `module:artefact`, 7 lignes, 1 seule entrée active `feature-dev-gates:rules/feature-dev-gates.md`) · `<mod>/module.json` (`requires`, `mandatory`) · `<mod>/VERSION`.
- `known-versions.txt` **n'est pas** un manifeste d'install : c'est une donnée du module `infrastructure-audit`, recopiée par la boucle `*.txt` (455-457, commentaire 450-454).
- **Aucun manifeste de pose n'existe.** `uninstall_module` reconstruit la liste **depuis le cache** — donc fausse dès que le module a disparu du cache, trou aujourd'hui rattrapé en dur par `retired-modules.txt`.

## 2. `plugin/_internal/merge-hooks.sh` (412 lignes) — contrat post-Phase-30

- Deux modes seulement, positionnels : `merge <fragment.json>` et `remove <fragment.json>` (39-46). **Pas de `dedupe`** — la déduplication est interne au `merge`.
- Flags : `--settings` (requis, 52-53) · `--settings-local` (optionnel, 54-55) · `--scripts-prefix` (requis en `merge`, 56-57, 63-65). Argument inconnu → `err` (58).
- **Aucune capacité dry-run / preview / diff** : ni flag, ni sortie de plan. Seule trace : un commentaire ligne 269 mentionnant un dry-run de Phase 10.
- Cibles : `settings.json` (toujours) + `settings.local.json` (si `--settings-local`). Répartition bornée par `is_local_entry()` (201-206) : **seules** les entrées dont le `command` brut porte `{{VF_BASH}}` vont en local ; `split_fragment_hooks` (208-236).
- Écriture réelle : `write_json()` (388-401) — `os.makedirs` + `tempfile.mkstemp` + `os.replace`, appelée 406 et 408. Les deux fichiers sont **créés s'ils n'existent pas** (`load_settings_dict` 143-156).
- Corps = heredoc Python (116-412), résolution `PYBIN` (72-84), `resolve_bash_abs()` (96-114, surcharge de test `VF_BASH_BIN`).
- Substitutions : `{{VF_SCRIPTS}}` → `--scripts-prefix` · `{{VF_BASH}}` → chemin absolu de bash (308, 319) ; tout `{{` résiduel → `die` (309, 320).
- Dédup par basename de script (`SCRIPT_RE` 161, `references()` 175-196) sur la cible **et** l'autre cible (`other_hooks`, 336-345). `remove` balaie **les deux cibles** (380-386) — conforme au contrat 30-01 cité au brief.
- Sortie : `[merge-hooks] <mode> OK → <settings>[ (+ <local>)]` sur stderr (411). Codes : 0 OK / 1 erreur.

## 3. Contenu complet de `plugin/_internal/`

- `vibeflow-update.sh` (1036 l.) — moteur install/update/uninstall/rollback/status scope-aware
- `merge-hooks.sh` (412 l.) — merge/retrait idempotent des fragments `hooks/hooks.json`
- `resolve-deps.sh` (60 l.) — fermeture transitive des `requires` ; racine `VF_MODULES_ROOT` ; termine même sur cycle
- `retired-modules.txt` (7 l.) — manifeste en dur des modules retirés du parc (`module:artefact`)
- `lib/vf-portable.sh` (8.9K, né en Phase 30) — lib **sourcée** de portabilité Windows : `vf_resolve_python`, `vf_python`, `vf_py_probe`, `jqx`, `vf_guard_unavailable` (contrat PR #29). Possédée par l'engine, posée par `copy_engine_lib()`
- `tests/` : `test-vibeflow-update.sh`, `test-merge-hooks.sh`, `test-resolve-deps.sh`, `test-vf-portable.sh`, `test-gsd-cohabitation.sh`, `test-windows-crlf.sh` + `tests/fixtures/gsd-core-settings.json`

## 4. Infrastructure de test

- **Emplacements** : `plugin/_internal/tests/` (6 suites) · `plugin/<module>/scripts/tests/` (majorité) · `plugin/conductor/skills/vf-new-lab/scripts/tests/` · `scripts/tests/` (4 suites)
- **Nommage** : `test-<cible>.sh`, toujours sous un dossier `tests/`. Convention interne : helpers `ok()/ko()/skip()`, asserts numérotés, `set -uo pipefail`, exit 1 si ≥ 1 KO (modèle : `plugin/_internal/tests/test-vibeflow-update.sh:29-41`)
- **Runner** : **aucun script runner local n'existe.** La découverte est faite par la CI —
  `.github/workflows/ci.yml:210-237`, job `tests`, étape « Découvrir et lancer toutes les suites ».
  Pattern (213) : `find plugin scripts -type f -path '*/tests/test-*.sh' | sort`, puis `bash "$t"` par suite (225) ; **découverte vide = échec** (217-220, contrat F13 anti-vert-à-vide).
  Équivalent local : `find plugin scripts -type f -path '*/tests/test-*.sh' | sort | while read t; do bash "$t" || echo "FAIL $t"; done`
- **Deux suites re-lancées nommément** (ci.yml:903-917) : `plugin/_internal/tests/test-windows-crlf.sh` et `plugin/consolidator/scripts/tests/test-windows-guards.sh`
- **Compteur « N suites »** : `README.md:124` (« 61 suites in CI ») et `README.fr.md:128` (« `61 suites` en CI »). Découverte réelle = **61** → synchro à ce jour.

### ⚠️ Correction de prémisse (à porter au cadrage)

Le brief de mission suppose que « le gate `check-version-sync` doit rester vert » sur le compteur de
suites. **C'est faux** : `scripts/check-version-sync.sh` (8.1K) vérifie `marketplace.json`,
`plugin.json`, les badges de version des 2 README (45-58), le compteur de **modules** (61-71),
l'historique README vs VERSION (88-101) et l'en-tête `**Version**` des README de modules (103-112).
**Il ne vérifie PAS le compteur de suites — aucun gate ne le fait.** La valeur `61` n'est contrôlée
nulle part : si la Phase 31 fait naître des suites, la mise à jour des deux README est une
**discipline humaine non gatée**, pas une contrainte machine. Deux options pour le cadrage (à
trancher, non tranché ici) : (a) mettre à jour les compteurs à la main dans le commit qui crée la
suite ; (b) profiter de la phase pour **gater** ce compteur dans `check-version-sync.sh` — ce qui
serait un nouveau gate, donc soumis à QUAL-01 (trois issues + mutation rouge).

Autres gates de `scripts/` : `bump.sh`, `check-gsd-core-update.sh`, `check-machine-paths.sh`,
`check-release-tag.sh`, `traffic-snapshot.sh`.

## 5. Énumération des fichiers d'un module à la pose

**Le moteur ne lit PAS `module.json` pour savoir quoi poser.** `module.json` ne sert qu'à `requires`
(`resolve-deps.sh:46-52`) et `mandatory` (`vibeflow-update.sh:506-511`).

La pose est décidée par **détection de convention de structure** dans `install_module()` (569-761),
une série de `if [ -f ]` / `if [ -d ]` sur `$CACHE_DIR/$mod` :

| Type | Test (ligne) | Source → Destination |
|---|---|---|
| 1 skill mono | `-f SKILL.md` (594) | `SKILL.md` → `$TARGET_ROOT/skills/<mod>/SKILL.md` |
| 2 multi-skills | `-d skills/` (601) | `skills/<n>/*` → `$TARGET_ROOT/skills/<n>/` (`cp -r`, dossier entier) |
| 3 agent | `-f AGENT.md` (612) | → `$TARGET_ROOT/agents/<mod>.md` |
| 3b multi-agents | `-d agents/` (620) | `agents/*.md` → `$TARGET_ROOT/agents/<basename>` |
| 4 doc | `-d content/` (632) | `content/*` → **`docs/<mod>/`** (hors TARGET_ROOT, relatif au cwd) |
| 5 rules | `-d rules/` (643) | `rules/*.md` → `$TARGET_ROOT/rules/` |
| refs skill | `-d references/` + `-f SKILL.md` (650) | → `skills/<mod>/references/` |
| refs agent | `-d references/` + (AGENT.md \|\| agents/) + **pas** SKILL.md (658) | → `agents/<mod>-references/` |
| config | `-d config/` + `-f SKILL.md` (666) | → `skills/<mod>/config/` |
| scripts | `copy_module_scripts` (441-465, appelée 673) | globs `*.sh`,`*.mjs`,`*.js` (chmod +x) et `*.txt` (sans +x) **à plat** vers `$TARGET_ROOT/scripts/` ; plus `scripts/tests/*.sh` et `scripts/tests/fixtures/*` |
| hooks | `-f hooks/hooks.json` (367) | mergé dans `settings*.json` |

Mélange de deux régimes : **fichier par fichier** via glob (rules, agents, scripts) vs **dossier
entier** via `cp -r <dir>/*` (skills imbriqués, content, references, config, fixtures).

### Le fait structurant de la phase : trois énumérations parallèles

`install_module()` (569-761), `gitignore_add_paths()` (175-244) et `uninstall_module()` (808-895)
**ré-implémentent chacune la même énumération**, à leur façon, en relisant le cache — trois listes
parallèles à garder cohérentes à la main. C'est exactement la dette que MANI-01 supprime : un
manifeste écrit par l'écrivain unique devient la source de vérité que les deux autres consomment.

`gitignore_add_paths` couvre en outre **deux cas que l'énumération d'install ne produit pas** :
`.claude/memory/` (221, déclenché par la présence de `scripts/seed-registres.sh`) et
`.claude/scripts/vf-portable.sh` (243, inconditionnel — posé par l'engine, pas par un module).
Un manifeste dérivé de la seule énumération d'install manquerait ces deux entrées.

## Sources

Lecture intégrale de `plugin/_internal/vibeflow-update.sh`, `plugin/_internal/merge-hooks.sh`,
`plugin/_internal/resolve-deps.sh`, `.github/workflows/ci.yml`, `scripts/check-version-sync.sh`,
`plugin/conductor/skills/vf-calibrate/SKILL.md`, plus l'inventaire de `plugin/_internal/` et des
dossiers `tests/` du dépôt.
