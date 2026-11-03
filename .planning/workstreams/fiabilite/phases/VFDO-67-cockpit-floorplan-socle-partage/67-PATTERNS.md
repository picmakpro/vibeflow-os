# Phase 67: Cockpit floorplan sur socle partagé - Pattern Map

**Mapped:** 2026-11-01
**Files analyzed:** ~30 (module neuf + dag.sh + enregistrements)
**Analogs found:** 14 / 16 familles de fichiers

Toutes les analogues citées sont suivies par git (vérifié par `git ls-files` sur les dossiers `plugin/...`). Aucune n'est un miroir `.claude/` ou `.gsd/`.

## PIÈGES D'INSTALLATION (à lire avant de déclarer les périmètres)

Chacun est mesuré dans `plugin/_internal/vibeflow-update.sh` (VU) ou dans les gates.

1. **Un module n'a pas de dossier `commands/`.** Aucun fichier suivi ne correspond à `plugin/*/commands/*`. VU ne pose de commande que pour l'incarnation d'un agent (`VU:2184`, `commands/${mod}.md`). Les verbes à tirets vivent dans `plugin/commands/*.md` (racine du plugin, non toggables). `plugin/commands/vf-notify.md` est le patron : un frontmatter `description` et `argument-hint`, puis « Invoque le skill X : $ARGUMENTS ». **Conséquence :** `plugin/cockpit/commands/vf-cockpit.md` (prévu dans le mandat) ne serait jamais posé chez l'utilisateur. Trois options pour le plan :
   - (a) `plugin/commands/vf-cockpit.md` qui invoque le skill. Cette option est exposée même module absent.
   - (b) Un skill `vf-invocation: user`, qui est le verbe.
   - (c) Étendre l'engine pour poser `commands/`.

   Le choix est à trancher au plan.
2. **`@bootstrap:socle` du budget d'instructions compte « les commandes du plugin »** (`.planning/instruction-budget-baselines.tsv:21`, valeur 2610, gate `check-instruction-budget.sh:595`, boucle `plugin/commands/*.md`). Ajouter `plugin/commands/vf-cockpit.md` peut faire monter la clé. Une hausse exige un trailer d'arbitrage (canal + date) dans le commit (G-1, `scripts/check-baseline-arbitrage.sh`). L'option (b) évite ce coût.
3. **`scripts/` posé à plat** (`copy_module_scripts`, VU:2985-3060). Globs : `*.sh *.mjs *.js` (exec), `*.txt`, `*.json`, plus `scripts/tests/*.sh` et `scripts/tests/fixtures/*` (fichiers à plat). **Aucun sous-dossier de `scripts/`** : la bibliothèque du socle (`who.mjs`, `vf-project-graph.mjs`, `vf-code-arch.mjs`, `vf-ask.mjs`, `vf-query.mjs`, `vf-types.mjs`) doit y être à plat, avec des imports relatifs `./x.mjs`. Les tests de module sont à **`plugin/cockpit/scripts/tests/test-*.sh`**, pas `plugin/cockpit/tests/`, sinon l'engine ne les pose pas.
4. **`skills/<nom>/` copié en arbre entier** (`vf_place_tree`, VU:3258-3261, `cp -r`) vers `$TARGET_ROOT/skills/<nom>/`. C'est le seul endroit où l'arbre vendorisé (assets, `elk.bundled.js`, polices, png) peut vivre. `vf_place_tree` ignore les entrées de premier niveau commençant par `.`. La réécriture de références n'agit que sur `*.md|*.sh|*.json|*.mjs|*.js|*.txt|*.yml|*.yaml` (`vf_target_rewrite_ext`, VU:1474) : **un test d'install doit comparer les octets des binaires** (le mandat l'appelle « non vérifié »).
5. **Le code vendorisé sous `skills/` est copié sous `$TARGET_ROOT/skills/<nom>/`, mais les scripts à plat vont sous `$TARGET_ROOT/scripts/`.** Le serveur et `vf-ask`/`vf-query` (scripts) doivent donc trouver l'arbre vendorisé par un chemin relatif aux deux racines, ou par un fichier `.vibeflow-target` (VU:2384, marqueur de cible). Prévoir un résolveur testé dans les scopes user, project et local.
6. **`check-skills.sh` exige `vf-invocation: user|model`** (`check-skills.sh:531`). `user` impose aussi `disable-model-invocation: true` (`check-skills.sh:735`). Tout `SKILL.md` sous `plugin/` est jugé, **y compris un `SKILL.md` amont vendorisé** : ne pas livrer celui de floorplan (ou le renommer).
7. **Gate « ajout = retrait » SOBR-05** (`check-ajout-retrait.sh`, consultatif) : tout `SKILL.md` ajouté sous `plugin/` et tout `scripts/check-*.sh` / `guard-*.sh` ajouté exigent un trailer `Ajout-Retrait:` ou un retrait compensatoire.
8. **Gate-Touche G-2** (CLAUDE.md racine) : le trailer `Gate-Touche: <chemin> — <raison>` est requis si un plan touche un gate, sa suite, `ci.yml`, un hook, ou une fixture surveillée (`plugin/conductor/scripts/tests/fixtures/**`, `scripts/tests/fixtures/**`). `dag.sh` et `test-dag.sh` ne sont **pas** des gates. Une nouvelle suite dans `plugin/cockpit/scripts/tests/` n'en déclenche pas.
9. **ADR-035 (300 lignes).** Le marqueur `vibeflow:allow-large-file` doit figurer dans les **5 premières lignes** du fichier (`plugin/software-architecture/scripts/check-file-size.sh:37`, `guard-file-size.sh:91`). Ni le gate ni le guard ne tournent dans `ci.yml` (`git grep` vide) : l'exemption n'est appliquée que chez les labs qui installent `software-architecture`. Un fichier `.json` ou un `.html` ne porte pas toujours un commentaire : prévoir la liste dans `VENDORED.txt` (D-07).
10. **`VENDORED.txt` est un `*.txt`** : s'il est placé dans `scripts/`, l'engine le posera. Sous `skills/<nom>/` il est posé par l'arbre. Choisir l'emplacement exprès.

## File Classification

| Fichier neuf ou modifié | Rôle | Flux de données | Analogue le plus proche | Qualité |
|---|---|---|---|---|
| `plugin/cockpit/module.json` | config | n/a | `plugin/mobile-test/module.json`, `plugin/skill-creator/module.json` | exact |
| `plugin/cockpit/VERSION` | config | n/a | `plugin/skill-creator/VERSION` (`v1.1.3`, avec préfixe `v`) | exact |
| `plugin/cockpit/CHANGELOG.md` | doc | n/a | `plugin/mobile-test/CHANGELOG.md` | exact |
| `plugin/cockpit/README.md` | doc | n/a | `plugin/mobile-test/README.md`, `plugin/skill-creator/README.md` | rôle |
| verbe `/vf-cockpit` | commande ou skill | request-response | `plugin/commands/vf-notify.md` | rôle (voir piège 1) |
| `plugin/cockpit/skills/vf-cockpit/SKILL.md` | skill (classe `user`) | request-response | `plugin/conductor/skills/vf-notify/SKILL.md` (frontmatter) | rôle |
| `plugin/cockpit/skills/<vendor>/**` (floorplan patché) | vendor | file-I/O | `plugin/skill-creator/skills/skill-creator/` (assets HTML, `LICENSE.txt`, `scripts/`) | rôle |
| `plugin/cockpit/scripts/who.mjs`, `vf-project-graph.mjs`, `vf-code-arch.mjs`, `vf-ask.mjs`, `vf-query.mjs`, `vf-types.mjs`, `live.mjs` | utilitaire node | transform, streaming | `plugin/mobile-test/scripts/mobile-test-run.mjs` ; sources : `.planning/spikes/00{2..6}/*.mjs` | rôle |
| `plugin/cockpit/scripts/tests/test-*.sh` | test | n/a | `plugin/conductor/scripts/tests/test-dag.sh` (harnais) | exact |
| `plugin/conductor/scripts/dag.sh` `save()` | utilitaire (python en ligne) | file-I/O | `dag.sh:132-135` lui-même ; fichier temporaire + `os.replace` : voir `plugin/conductor/scripts/` (non cherché, voir Sans analogue) | modif |
| suite du correctif `dag.sh` | test | file-I/O | `plugin/conductor/scripts/tests/test-dag.sh` | exact |
| test d'install de `cockpit` | test | file-I/O | `plugin/_internal/tests/test-vibeflow-update.sh` (T2, `prepare_module`) | exact |
| enregistrements hors module | config, doc | n/a | voir section dédiée | exact |

## Pattern Assignments

### `plugin/cockpit/module.json` (config)

**Analogues :** `plugin/mobile-test/module.json`, `plugin/skill-creator/module.json`.

```json
{
  "name": "skill-creator",
  "version": "v1.1.3",
  "type": "agent+skills",
  "description": "...",
  "requires": []
}
```

- `mobile-test` ajoute `"roles": ["dev"]`. Sans clé `roles`, le module est visible de tous les postes (`plugin/_internal/module-roles.sh:50`, `if has("roles")|not then "yes"`). La décision « tous les labs » (P67-D-01) pointe vers **l'absence de `roles`**.
- `check-version-sync.sh` (section 6) exige `plugin/cockpit/VERSION` et `module.json .version` identiques, comparés sans le `v`.
- Un module n'a pas d'entrée de liste dans l'installeur : l'engine lit `$CACHE_DIR/<mod>/module.json`. Un module hors preset (`plugin/_internal/presets.json`) reste installable par son nom. Ne pas toucher `presets.json` sauf décision explicite.
- `requires` : `[]`, sauf dépendance voulue sur un module qui porte `driver-lock.sh` (le socle appelle `driver-lock.sh status --all`, livré par `conductor`, module mandatory).

### `plugin/cockpit/CHANGELOG.md`

**Analogue :** `plugin/mobile-test/CHANGELOG.md`. Titre `# Changelog — <module>`, puis `## v1.0.5 — 2026-10-29 — publiée dans v2.72.0`, puis `### Modifié` / `**Patch**`. Une première entrée `## v1.0.0 — <date>` avec `### Ajouté`. Les trailers d'arbitrage citent **canal + date** : « arbitrage Samuel, AskUserQuestion session principale, 2026-11-01 ».

### `plugin/cockpit/skills/vf-cockpit/SKILL.md` (skill, classe user)

**Analogue (frontmatter) :** `plugin/conductor/skills/vf-notify/SKILL.md:1-4` (`name`, `description`, `vf-invocation`). Mais ce skill est `model`. Pour une classe `user`, ajouter `disable-model-invocation: true` (`check-skills.sh:735`).
Densité : skills ≤ 500 lignes. Pas de `SKILL.md` amont dans l'arbre vendorisé, sinon `check-skills.sh` le juge.

### Arbre vendorisé (floorplan v0.6.0 @ 92d6854, patché)

**Analogue :** `plugin/skill-creator/skills/skill-creator/` contient `LICENSE.txt`, `assets/eval_review.html`, `eval-viewer/viewer.html`, `scripts/*.py`, `scripts/tests/test-quick-validate.sh`. Précédent d'un arbre posé en entier avec ses assets HTML.

Sources à vendoriser : `.planning/spikes/002-cockpit-code-projet/` (`VENDORED.txt`, `patches/serve.mjs.diff`, `patches/viewer.html.diff`, `extensions/00-vibeflow.js`, `70-vf-live.js`, `80-vf-fr.js`, `build-cockpit.mjs`).

**Piège de chemins déjà visible :** un `tests/` sous `plugin/skill-creator/skills/skill-creator/scripts/tests/test-quick-validate.sh` est découvert par la CI (`find plugin scripts -path '*/tests/test-*.sh'`, `scripts/ci-shard-suites.sh:23`). Tout fichier `*/tests/test-*.sh` de l'arbre vendorisé est donc joué. À éviter ou à assumer.

**Marqueur de taille (ADR-035) :** dans les 5 premières lignes, `// vibeflow:allow-large-file` pour les `.mjs` et `.js` vendorisés (`serve.mjs` 647, `health.mjs` 1198, `screens.mjs` 638, `extract.mjs` 598, `build.mjs` 482, `scan.mjs` 316, `elk.bundled.js` 6696). Le rendu de la marque blanche par renommage mécanique (D-03) réécrit ces fichiers à l'assemblage : le test doit vérifier que le marqueur survit au renommage.

### Bibliothèque du socle (`scripts/*.mjs`, utilitaires node)

**Analogue d'organisation :** `plugin/mobile-test/scripts/mobile-test-run.mjs` — shebang `#!/usr/bin/env node`, bloc d'en-tête qui documente les sous-commandes, imports `node:` natifs, JSON sur stdout, aucune valeur machine codée en dur :

```js
#!/usr/bin/env node
import { execFileSync, spawn } from 'node:child_process';
import { readFileSync, mkdirSync, writeFileSync, existsSync, openSync } from 'node:fs';
import { join } from 'node:path';
```

**Sources à promouvoir** (toutes ≤ 300 lignes, donc sans exemption) :
- `.planning/spikes/004-signal-au-travail/who.mjs` (142 lignes). Imports `node:fs/os/path/child_process` ; `execFileSync` sans shell ; chaque source rend son état (lue, absente, en erreur) ; usage `node who.mjs <root> [--fresh 180] [--json]`.
- `.planning/spikes/002-cockpit-code-projet/vf-project-graph.mjs` (197) : `root = path.resolve(process.argv[2] || '.')` à la ligne 11 : un script CLI, pas une bibliothèque. **P67-D-12 exige une interface importable et un schéma versionné** : exporter des fonctions, garder la CLI derrière un test `import.meta.url === ...`.
- `vf-code-arch.mjs` (104), `vf-ask.mjs` (108), `vf-query.mjs` (61), `vf-types.mjs` (20), `live.mjs` (139).

Le plan doit donner la forme du schéma JSON versionné (clé `schema`, p. ex. `vibeflow.cockpit.who/1`) : aucun analogue dans le dépôt pour un schéma nommé de bibliothèque. Les analogues de contrat sont le JSON de `driver-lock.sh status --all` et le DAG `nodes[]`.

### Correctif `plugin/conductor/scripts/dag.sh` `save()` (file-I/O)

**Code actuel** (`dag.sh:132-135`, lu le 2026-11-01) :

```python
def save(dag):
    os.makedirs(os.path.dirname(file) or ".", exist_ok=True)
    with open(file, "w", encoding="utf-8") as fh:
        json.dump(dag, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
```

Remplacer par un fichier temporaire **du même dossier** (`tempfile.mkstemp(dir=os.path.dirname(file) or ".")`), `fh.flush()` puis `os.fsync`, puis `os.replace(tmp, file)`, avec nettoyage du temporaire en cas d'exception. `load()` (l.125-130) n'a pas besoin de changer.

**Suite de test :** `plugin/conductor/scripts/tests/test-dag.sh` (63,6 Ko, ~950 lignes). Harnais à réutiliser (l.28-60) : `PASS/FAIL`, `assert`, `assert_not`, `assert_exit`, `assert_eq`, `run_bounded` (watchdog portable, car macOS n'a pas `timeout`), `WORK_DIR=$(mktemp -d)`, `trap 'rm -rf' EXIT`, `cd "$(dirname "$0")/../.."`, `SCRIPT=...scripts/dag.sh`. Pied de fichier à copier : le garde-fou ANTI-VERT-À-VIDE (`TOTAL=0` → exit 1). Dernière section : T49. Numéroter la suite suivante en **T50+**.

Deux options : ajouter un T50 dans `test-dag.sh`, ou créer une petite suite `test-dag-atomic-save.sh` qui reprend ce harnais (le fichier existant est déjà très gros). Recommandé : une petite suite à côté (un T50 de plus allonge un fichier de 950 lignes). Le **témoin rouge d'abord** (P67-D-09 ; mémoire « une preuve doit pouvoir rendre rouge ») : jouer le test contre l'ancien `save()` et constater le rouge avant le correctif. Le mécanisme : ralentir l'écriture (p. ex. `json.dump` d'un gros DAG ou un `sleep` injecté via une variable d'environnement de test) pendant qu'un lecteur boucle sur `dag.sh status`.

### Tests du module (`plugin/cockpit/scripts/tests/test-*.sh`)

**Analogue :** `plugin/conductor/scripts/tests/test-dag.sh` (harnais ci-dessus) ; pour un module livré avec son test : `plugin/business-pilot-bundle/scripts/tests/test-business-pilot-bundle.sh`, `plugin/skill-creator/skills/skill-creator/scripts/tests/test-quick-validate.sh`.

Découverte CI : `scripts/ci-shard-suites.sh:23` : `find plugin scripts -type f -path '*/tests/test-*.sh'`, répartie en shards (job `tests-shard`, partition vérifiée par le job `tests`, `ci.yml:~370-390`). **Aucune liste à compléter** : un fichier nommé `test-*.sh` dans un dossier `tests/` est joué. Node 24 dans le job tests.

Suites attendues par les exigences : forme des transcripts et `meta.json` (CKPT-01), grep sans `run.app|waitlist|auth status` (CKPT-03), grep insensible à la casse « floorplan » sur le rendu servi (CKPT-04), `doing` absent du SSE et de `exportMap` (CKPT-08), chrome sans anglais (CKPT-09), installation (CKPT-10). Chaque test de grep doit avoir un **témoin positif** (injecter une occurrence et constater le rouge).

### Test d'installation d'un module (CKPT-10)

**Analogue :** `plugin/_internal/tests/test-vibeflow-update.sh`, T2 (l.101-118). Isolation par `LAB=$(mktemp -d)`, `CACHE="$LAB/cache"`, `prepare_module "$CACHE" "<mod>"`, puis :

```bash
(cd "$LAB" && VIBEFLOW_CACHE="$CACHE" \
   bash "$INSTALLER" install dev-orchestrator >/dev/null 2>&1)
```

Variantes de scope : `HOME="$FAKE_HOME" VF_SCOPE=user` (l.84), `VF_SCOPE=local`. Helpers `ok()`, `ko()`, `skip()`. Et un snapshot avant/après du vrai `~/.claude` (garde-fou anti-pollution). Pour un test de module, mettre la suite dans `plugin/cockpit/scripts/tests/` et appeler l'engine par un chemin relatif à la racine (`../../../_internal/vibeflow-update.sh`). À vérifier : `prepare_module` n'est défini que dans ce fichier (à copier ou à factoriser).

À poser dans le test : fichiers à plat sous `$TARGET_ROOT/scripts/`, arbre sous `$TARGET_ROOT/skills/<nom>/`, comparaison d'octets des binaires (`cmp`), et idempotence (2e pose).

### Sortie dans le lab (`.vibeflow/cockpit/`)

**Précédent :** `.vibeflow/mobile-test.json` (`plugin/mobile-test/config/mobile-test.example.json`, `plugin/mobile-test-team/README.md:43`). Le `.gitignore` interne « * » est à créer par le script à l'exécution, pas par l'engine. L'engine ne connaît pas `.vibeflow/`.

## Fichiers à enregistrer hors du module (périmètres des plans)

| Fichier | Quoi toucher | Gate qui le vérifie | Source |
|---|---|---|---|
| `README.md` | badge `badge/modules-18` passe à 19 ; phrase `18 modules, each versioned` (l.114) ; tableau d'historique (en tête = `VERSION`) uniquement à la release | `scripts/check-version-sync.sh` (sections 5 et 7) | mesuré |
| `README.fr.md` | idem : badge et phrase `N modules, chacun versionné` | idem | mesuré |
| `VERSION`, `plugin/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugin/.codex-plugin/plugin.json` | **non touchés dans la phase** : toute release est un geste humain hors périmètre. Mais le compteur de modules (README) bouge dès l'ajout du module, sans bump de version | `check-version-sync.sh` | mandat + CLAUDE.md |
| `manual/en/03-modules/catalog.md` et `manual/fr/03-modules/catalogue.md` | une entrée `- **cockpit**` (précédent : `mobile-test`, l.89) | non gaté à ma connaissance ; à confirmer | mesuré |
| `manual/*/06-reference/skills.md` | entrée du skill si le skill est exposé | idem | mesuré (`mobile-test` y figure) |
| `.planning/instruction-budget-baselines.tsv` | **seulement** si agents ajoutés (la découverte du gate est `plugin/*/agents/*.md` + `plugin/*/AGENT.md`) ; ou la clé `@bootstrap:socle` si `plugin/commands/` grossit (piège 2) | `check-instruction-budget.sh`, G-1 | mesuré |
| `plugin/conductor/scripts/check-overlaps.sh` | liste des modules ? `mobile-test` y est cité. À lire avant de décider | `check-overlaps.sh` | grep seul, non lu |
| `plugin/_internal/presets.json` | aucun, sauf si un preset doit inclure `cockpit` | `resolve-preset.sh` | mesuré |
| `.github/workflows/ci.yml` | aucun pour les suites (découverte par motif). Toute modification exige `Gate-Touche:` | G-2 | mesuré |
| `.planning/workstreams/fiabilite/REQUIREMENTS.md`, `ROADMAP.md` | CKPT-01..11 et ligne `Requirements` de la Phase 67 | `check-divergence.sh` | CONTEXT |
| `.planning/notes/2026-10-29-HANDOFF-jalon-v2.md` | à commiter tel quel (P67-D-10) | n/a | CONTEXT |
| `plugin/conductor/CHANGELOG.md` | entrée pour le correctif `dag.sh` (bump patch de `conductor` : `VERSION` + `module.json` + CHANGELOG, triade vérifiée) | `check-version-sync.sh` section 6 | mesuré |

Triade du module `conductor` : tout bump patch pour le correctif `dag.sh` oblige à aligner `plugin/conductor/VERSION` et `plugin/conductor/module.json`. Les releases sont humaines : décider au plan si le bump est fait dans la phase (précédent : `mobile-test` v1.0.5 « publiée dans v2.72.0 », le bump précède la release).

## Shared Patterns

### Densité et classement
- Skills ≤ 500 lignes, `vf-invocation` obligatoire. Agents (si l'agent des questions devient un agent natif) : `check-agents.sh` exige `description`, `model`, `memory`. Le mandat décrit `claude -p` en sous-processus, pas un agent natif : aucun agent à déclarer, donc pas de baseline.
- Notre code ≤ 300 lignes par fichier (D-07). Les spikes (≤ 197 lignes) tiennent.

### Traçabilité
- Commits en français ; un arbitrage cité nomme canal + date. Identifiants de décision préfixés (`P67-D-xx`).
- Gardes in-repo : G-1 baseline, G-2 `Gate-Touche`, SOBR-05 `Ajout-Retrait` (voir pièges 7 et 8).

### Isolation des tests
- `mktemp -d` + `trap 'rm -rf' EXIT` ; `HOME` factice ; jamais le vrai `~/.claude`.
- Anti-vert-à-vide : compter les assertions et refuser `TOTAL=0`.
- Mémoire du dépôt : « une preuve doit pouvoir rendre rouge » ; tout test de grep ou de blocage a un témoin positif.

### Pose multiplateforme (CI Linux)
- CI en `ubuntu-latest` = Ubuntu 26.04 avec coreutils uutils (`ln -sh`, `mv -h` cassés). Éviter les options BSD/GNU-only dans les scripts et tests shell.
- Windows : `fs.watch` récursif inégal, d'où le repli polling (P67-D-16). Pas d'analogue suivi dans `main` : la branche `feat/vf-cockpit-module` (`vf-cockpit-watch.mjs`) n'est pas mergée.

## No Analog Found

| Fichier | Rôle | Flux | Raison |
|---|---|---|---|
| Commande de module `plugin/cockpit/commands/` | commande | request-response | L'engine ne pose pas de `commands/` de module (piège 1) ; analogue le plus proche = `plugin/commands/vf-notify.md` |
| Résolution d'un arbre `skills/<nom>/` depuis un script posé à plat | utilitaire | file-I/O | Aucun module ne le fait ; `VU:2384` (`.vibeflow-target`) est le seul mécanisme de cible |
| Serveur HTTP/SSE local (`127.0.0.1`, jeton, contrôle du `Host`) | service | streaming | Aucun serveur dans `plugin/` ; sources = `serve.mjs` vendorisé et `live.mjs` du spike 003 |
| Schéma JSON nommé et versionné pour bibliothèque node | contrat | transform | Seuls contrats existants : JSON de `driver-lock.sh status --all` et DAG `nodes[]` |
| Écriture atomique (`os.replace`) déjà en usage dans `plugin/conductor/scripts/` | utilitaire | file-I/O | Non cherché : à lancer `git grep -n "os.replace\|mkstemp" -- plugin` avant d'écrire le plan, pour réutiliser un précédent |

## Metadata

**Analog search scope :** `plugin/`, `plugin/_internal/`, `scripts/`, `.github/workflows/ci.yml`, `.planning/spikes/`, README racine.
**Non lus (à vérifier au plan) :** corps complet de `check-overlaps.sh`, `check-agents.sh`, `check-skills.sh` (seuls les points cités ont été lus), `manual/*/06-reference/skills.md`, définition de `prepare_module`, `plugin/.codex-plugin/plugin.json` (contenu).
**Pattern extraction date :** 2026-11-01
