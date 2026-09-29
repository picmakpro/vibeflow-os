# Phase 44: Moteur — modèle de données et recalcul d'état — Pattern Map

**Mapped:** 2026-09-27
**Files analyzed:** 13 (nouveau) + 4 (modifiés/version)
**Analogs found:** 13 / 13 direct-file matches, 0 sans analogue (tous les analogues cités sont
**git-tracked**, vérifié `git ls-files`, aucun ne provient d'un miroir `.gsd/capabilities/`)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `plugin/planning-core/scripts/recalc-planning.sh` (nom délégué) | CLI / controller (point d'entrée bash mince) | transform (lecture disque → état dérivé) | `plugin/conductor/scripts/dag.sh` | exact (même patron : Python embarqué en heredoc quoté, résolution siblings par répertoire de script, JSON en sortie) |
| — module Python embarqué dans `recalc-planning.sh` (parseur frontmatter, dérivation 8 états, cache incrémental, écriture atomique, `cloture.log` append-only) | service (logique métier de recalcul) | batch + transform + event-driven (append-only log) | `plugin/conductor/scripts/dag.sh` (corps `PYEOF`) — pour la structure générale ; **aucun analogue direct** pour parseur frontmatter / cache versionné / écriture atomique (absents du dépôt, confirmé par RESEARCH.md Code Examples) | role-match (structure du heredoc), pas de match sur le contenu métier — voir « No Analog Found » |
| `plugin/planning-core/scripts/tests/test-recalc-planning.sh` | test (suite bash, fixtures + mutation testing) | request-response (assertions sur stdout/exit code) | `plugin/conductor/scripts/tests/test-dag.sh` | exact (même domaine : test d'un moteur Python embarqué en `.sh`, fixtures temporaires, assertions sur JSON stdout, mutation testée) |
| `plugin/planning-core/scripts/tests/fixtures/recalc-bench/**` (arborescence synthétique, ≥18 cas nommés) | test fixture (arborescence `.planning/` synthétique) | file-I/O (arbre de fichiers versionné) | `plugin/conductor/scripts/tests/fixtures/` (fichiers `check-map-drift-pre-*.sh`, fixtures figées d'un état antérieur d'un script) | role-match seulement (fixtures existantes sont des scripts figés, pas une arborescence `.planning/` synthétique) — voir « No Analog Found » pour le format exact |
| `plugin/planning-core/references/modele-cycles.md` (nom délégué) | référence de modèle (doc + contrat de format) | — (documentation) | `plugin/planning-core/references/GUIDE.md` / `plugin/planning-core/references/compartments.md` | role-match (structure de référence du module, prose + tableaux) |
| `plugin/planning-core/references/templates/CYCLE.template.md` (nouveau) | template | — | `plugin/planning-core/references/templates/STATE.template.md` | exact (gabarit frontmatter + corps Markdown, même dossier, même convention `[placeholder]`) |
| `plugin/planning-core/references/templates/CADRAGE.template.md` (nouveau, registre d'inconnues à colonne structurante) | template | — | `plugin/planning-core/references/templates/INDEX.template.md` (structure frontmatter + tableau) **combiné avec** la contrainte A2 de RESEARCH.md (registre en liste structurée frontmatter, pas un tableau Markdown parsé) | role-match — le contenu (registre) n'a pas d'analogue, voir Pitfall 3/A2 |
| — `PLAN.template.md` du nouveau modèle (champ `ecrit:`, D-03) | template | — | `plugin/planning-core/references/templates/PLAN.template.md` **existant (socle v2, NE PAS ÉCRASER, D-01b)** | exact structurel, mais fichier neuf **à côté**, jamais un remplacement |
| — `SUMMARY.template.md` du nouveau modèle | template | — | `plugin/planning-core/references/templates/SUMMARY.template.md` **existant (socle v2, NE PAS ÉCRASER, D-01b)** | exact structurel, fichier neuf à côté |
| — `VERDICT.template.md` (nouveau, champs `hash`+`tentative`, D-09) | template | — | `plugin/planning-core/references/templates/STATE.template.md` (frontmatter + placeholders) | role-match (aucun `VERDICT.md` n'existe dans le corpus) |
| — marqueur de clôture de plan (fichier séparé, nom délégué, D-03) | marker file / template | — | aucun fichier-marqueur comparable dans le dépôt (concept neuf) | no analog — voir ci-dessous |
| `plugin/planning-core/references/templates/config.template.json` (nouveau, à côté — ne pas écraser l'existant) | config | CRUD (clé `planning_version` nouvelle valeur) | `plugin/planning-core/references/templates/config.template.json` **existant** | exact (même fichier comme squelette, valeur `planning_version` à changer, D-02) |
| `plugin/planning-core/VERSION` | config (version module) | — | valeur actuelle `v2.7.1` → bump **mineur** | exact (fichier à modifier in place) |
| `plugin/planning-core/module.json` | config (version module) | — | champ `"version": "v2.7.1"` → même bump | exact |
| `plugin/planning-core/CHANGELOG.md` | doc (changelog) | — | entrée `## [v2.7.1] — ...` la plus récente | exact (patron d'entrée à reproduire) |
| `plugin/planning-core/README.md` | doc (readme module) | — | section « Contenu du module » (arborescence commentée) | exact (patron à étendre avec les nouveaux fichiers) |

## Pattern Assignments

### `plugin/planning-core/scripts/recalc-planning.sh` (CLI, transform)

**Analog:** `plugin/conductor/scripts/dag.sh`

**Imports/shebang + arg parsing pattern** (dag.sh lignes 69-88) :
```bash
set -uo pipefail

ACTION=""; FILE=""; ID=""; STEP=""; STAGE=""; DEPS=""; STATUS=""; SCOPE=""
for arg in "$@"; do
  case "$arg" in
    init|add|ready|mark|reopen|status|tree) ACTION="$arg" ;;
    --file=*)   FILE="${arg#*=}" ;;
    ...
    -h|--help)  grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done
```
Pour la Phase 44 : remplacer les flags par ceux du recalcul (`--path`, `--write`/`--read-only`
D-02a, etc.). Garder le patron `case "$arg" in --flag=*) VAL="${arg#*=}" ;; esac` (Don't Hand-Roll,
RESEARCH.md — pas de `getopts`).

**Résolution de siblings** (dag.sh lignes 90-101, à reproduire à l'identique) :
```bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd 2>/dev/null || dirname "$0")"
DRIVER_LOCK_SH="$SCRIPT_DIR/driver-lock.sh"
```
→ Pour la Phase 44 : `DETECT_GSD_SH="$SCRIPT_DIR/detect-gsd-engine.sh"` (D-02a). **Jamais** un
chemin relatif au cwd — c'est le vecteur RCE fermé par dag.sh D-07 (commentaire lignes 160-170,
5e occurrence du motif sur ce dépôt).

**Invocation Python embarquée** (dag.sh lignes 103-108) :
```bash
python3 - "$ACTION" "$FILE" "$ID" ... "$DRIVER_LOCK_SH" <<'PYEOF'
import sys, os, json, subprocess, tempfile, shutil

action, file, nid, step, stage, deps_raw, status, scope_raw = sys.argv[1:9]
driver_lock_sh = sys.argv[9]
...
PYEOF
```
**Heredoc impérativement quoté** (`<<'PYEOF'`, jamais `<<PYEOF` nu) — sinon bash interpole `$` et
backticks dans le corps Python avant de le passer à l'interpréteur (RESEARCH.md Pattern 1).
`sys.exit(code)` en dernier appel Python devient le code de sortie du `.sh`.

**Subprocess sibling réutilisé en sous-processus** (adaptation directe du patron `record_progress`
de dag.sh lignes 189-221, best-effort documenté dans RESEARCH.md « Invocation avec siblings ») :
```python
def gsd_engine_active(path):
    try:
        r = subprocess.run([detect_gsd_sh, "--quiet", "--path", path],
                            capture_output=True, timeout=5, check=False)
        return r.returncode == 0
    except Exception:
        return False
```
Contrairement au best-effort silencieux de dag.sh, ici l'échec ne doit **jamais** ouvrir
l'écriture par défaut : `detect-gsd-engine.sh` absent/en échec doit être traité comme un signal
d'incertitude qui bloque l'écriture (pas de `except Exception: return False` permissif côté
« GSD actif » — inverser la polarité par rapport à dag.sh selon D-02a : sécurité par défaut, pas
dégradation silencieuse).

**Sortie JSON** (dag.sh ligne 137-138) :
```python
def emit(obj):
    print(json.dumps(obj, indent=2, ensure_ascii=False))
```
**À DURCIR pour la Phase 44** (dag.sh ne le fait PAS, RESEARCH.md Pattern 2) : ajouter
`sort_keys=True` pour le déterminisme requis par D-10/MOTR-10. Ne pas reproduire l'oubli de
dag.sh.

**Anti-pattern signalé par la recherche à ne PAS copier de `dag.sh`** : `save()` (dag.sh lignes
117-121) écrit directement `open(file, "w")`, **non atomique**. Pour `INDEX.md`/`STATE.md`
(protégés par un futur G6, Phase 45), utiliser le patron `write_atomic()` proposé en Code Examples
de RESEARCH.md (`tempfile.mkstemp` + `os.replace`), pas le patron `dag.sh.save()`.

---

### `plugin/planning-core/scripts/tests/test-recalc-planning.sh` (test, request-response)

**Analog:** `plugin/conductor/scripts/tests/test-dag.sh` (1005 lignes — grep ciblé, pas de lecture
intégrale) + `plugin/planning-core/scripts/tests/test-detect-gsd-engine.sh` (218 lignes, lu
intégralement, plus proche en taille et en domaine planning-core)

**En-tête + setup + helpers d'assertion** (test-detect-gsd-engine.sh lignes 1-25, patron le plus
proche du module cible car même répertoire `plugin/planning-core/scripts/tests/`) :
```bash
#!/usr/bin/env bash
# test-detect-gsd-engine.sh — Tests du détecteur de moteur de planning GSD.
# Portable, sans réseau. Fixtures temporaires + vérification des exit codes.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DETECT="$SCRIPT_DIR/detect-gsd-engine.sh"
PASS=0; FAIL=0

check_exit() { # <description> <expected_code> <actual_code>
  if [ "$2" -eq "$3" ]; then echo "  ✓ $1 (exit $3)"; PASS=$((PASS+1));
  else echo "  ✗ $1 — attendu $2, obtenu $3"; FAIL=$((FAIL+1)); fi
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
```

**Helpers d'assertion plus riches** (test-dag.sh lignes 24-30, à combiner si le recalcul émet du
JSON structuré comme dag.sh) :
```bash
assert()     { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: $3"; echo "     obtenu:  $2"; FAIL=$((FAIL+1)); fi; }
assert_not() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (a trouvé « $3 »)"; FAIL=$((FAIL+1)); fi; }
assert_exit(){ if [ "$2" -eq "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (exit $2 ≠ $3)"; FAIL=$((FAIL+1)); fi; }
assert_eq()  { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
```
`assert_eq` (égalité stricte) est nécessaire pour MOTR-10 (sortie déterministe byte-identique) —
une simple sous-chaîne (`assert`) ne suffit pas à prouver l'identité octet pour octet ; comparer
avec `diff`/`cmp` de deux exécutions successives, patron à construire sur ce modèle.

**Fixture builder par cas nommé** (test-detect-gsd-engine.sh lignes 22-25) :
```bash
mk_state() { # <dir> <première_clé_frontmatter>
  mkdir -p "$1/.planning"
  printf -- '---\n%s: 1.0\nlast_updated: "2026-07-25"\n---\n\n# État\n' "$2" > "$1/.planning/STATE.md"
}
```
→ Pour la Phase 44 : un helper équivalent par type de fixture du modèle-cycles (ex.
`mk_plan_with_marker`, `mk_verdict_sans_marqueur`) construisant l'arborescence synthétique sous
`$TMP` pour les cas ponctuels, **et** un jeu de fixtures **versionnées** (pas générées à la volée)
sous `scripts/tests/fixtures/recalc-bench/` pour le banc D-06 gaté en CI.

**Patron de mutation testing tracée** (test-detect-gsd-engine.sh lignes 200-214, cas MUT-1 —
c'est LE modèle direct pour D-17 « chaque garde prouvée par une mutation rouge, avec la trace du
rouge ») :
```bash
# Cas 25 (MUT-1, QUAL-01) : MUTATION — la primitive `vf_ws_enumerate` est neutralisée (stub rendant
# 3, stdout vide) dans une COPIE de la politique ; le script doit alors RETOMBER sur son ancien
# comportement racine-seule (rc=3) sur la fixture du cas 20. Preuve que c'est bien la consommation
# de la primitive — et non la fixture — qui discrimine. Un TÉMOIN non muté encadre la mesure.
MUTD="$TMP/mut-detect"; mkdir -p "$MUTD"
cp "$DETECT" "$MUTD/detect-gsd-engine.sh"
cp "$SCRIPT_DIR/workstream-policy.sh" "$MUTD/workstream-policy.sh"
( cd "$TMP/lab20" && GSD_HOME="$FAKE_GSD" bash "$MUTD/detect-gsd-engine.sh" --quiet ); rc_temoin=$?
printf '\n%s\n' 'vf_ws_enumerate() { return 3; }' >> "$MUTD/workstream-policy.sh"
( cd "$TMP/lab20" && GSD_HOME="$FAKE_GSD" bash "$MUTD/detect-gsd-engine.sh" --quiet ); rc_mutant=$?
[ "$rc_temoin" -eq 0 ] && [ "$rc_mutant" -eq 3 ]
check_bool "MUT-1 : mutant tué — primitive neutralisée → retour au verdict racine-seule (témoin=$rc_temoin, mutant=$rc_mutant)" $?
# Le fichier réel n'a jamais été muté (seule une copie l'a été) — prouvé par cmp.
cmp -s "$DETECT" "$MUTD/detect-gsd-engine.sh"
check_bool "MUT-1 (hygiène...) : le script réel est intact" $?
```
→ Reproduire ce patron pour chaque garde de D-08/D-13/D-11 (ex. mutation qui remplace
`hashlib.sha256` par un hash constant → doit faire rougir le test d'incrémentalité ; mutation qui
ouvre `cloture.log` en `"w"` au lieu de `"a"` → doit faire rougir le test append-only). **Toujours**
muter une COPIE, jamais le script réel — `cmp -s` en clôture pour le prouver, comme ci-dessus.

**Patron alternatif de mutation** vu dans `test-dag.sh` (ligne 413, cité en commentaire, structure
similaire — grep ciblé, pas de lecture intégrale des ~590 lignes environnantes) : mutations
inline sur une copie de `dag.sh` pour prouver que `compute_stages()`/la garde de frontière vide
font effectivement rougir un test dédié quand elles sont supprimées. Même discipline : commentaire
qui nomme explicitement ce que la mutation retire et ce que le test doit alors observer.

**Boucle de test rejouée sous deux shells (D-17)** — aucun exemple direct trouvé dans le corpus
(les suites existantes sont invoquées via `bash "$t"` par la CI, jamais explicitement sous zsh) ;
patron à construire : invoquer `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh`
**et** `zsh plugin/planning-core/scripts/tests/test-recalc-planning.sh` en local, documenté dans
le corps de test ou dans le SUMMARY de la tâche correspondante.

---

### Fixtures `plugin/planning-core/scripts/tests/fixtures/recalc-bench/**` (test fixture)

**Analog partiel :** aucune arborescence `.planning/` synthétique n'existe dans le dépôt à ce jour
— les fixtures de `plugin/conductor/scripts/tests/fixtures/` sont des **scripts bash figés**
(`check-map-drift-pre-*.sh`, snapshots d'un script à une version antérieure), pas des arbres de
fichiers `.planning/`. Rôle comparable (fixture versionnée) mais format sans rapport.

**Contrainte d'installation vérifiée (nouvelle donnée pour le plan, absente de RESEARCH.md) :**
`plugin/_internal/vibeflow-update.sh` lignes 2042-2056 (Site #4) pose `scripts/tests/*.sh` **et**
`scripts/tests/fixtures/*` mais avec un glob **non récursif** (`"$module_dir/scripts/tests/fixtures/"*`,
un seul niveau, filtré `[ -f "$f" ]`) :
```bash
for f in "$module_dir/scripts/tests/fixtures/"*; do
  [ -f "$f" ] || continue
  vf_place_file "$f" "$TARGET_ROOT/scripts/tests/fixtures/$(basename "$f")" || { ... }
done
```
Une arborescence `recalc-bench/` à sous-dossiers imbriqués (`cycles/*/phases/*/`, requise par le
modèle) **ne serait pas installée récursivement** par ce site. **Sans conséquence fonctionnelle**
pour cette phase : la CI découvre et exécute les suites directement depuis l'arbre du **dépôt
source** (`find plugin scripts -type f -path '*/tests/test-*.sh'`, jamais depuis une copie
installée), donc les fixtures du banc n'ont pas besoin d'être « installables » pour gater en CI
(D-06 : « Il est le seul à gater en CI »). À signaler au planificateur : ne pas dépendre de
l'installeur pour la disponibilité des fixtures de test.

---

### `plugin/planning-core/references/templates/CYCLE.template.md` / `CADRAGE.template.md` (template)

**Analog:** `plugin/planning-core/references/templates/STATE.template.md` (lu intégralement, 40
lignes)

**Frontmatter + placeholders pattern** (STATE.template.md lignes 1-12) :
```markdown
---
planning_version: 1.0
profile: leger | standard | complet
milestone: "[jalon courant]"
status: "[cadrage | en cours | en vérification | livré]"
stopped_at: "[dernière action terminée / point de reprise précis]"
last_updated: "[YYYY-MM-DD]"
progress:
  total_steps: 0
  completed_steps: 0
  percent: 0
---
```
Convention à reprendre : frontmatter YAML minimal (clés plates + un seul niveau de nesting,
`progress:` sur 3 sous-clés) — c'est exactement le niveau que le parseur frontmatter minimal de
D-12 doit couvrir (RESEARCH.md A2/Pitfall « tableau Markdown prosaïque à éviter »). Le registre
d'inconnues de `CADRAGE.template.md` (colonne structurante, spec §7.5) doit suivre ce même patron
de nesting simple (liste de mappings sous une clé, jamais un tableau `| col1 | col2 |` en corps de
document à parser).

**Corps Markdown avec placeholders `[...]`** (STATE.template.md lignes 14-40) — même convention à
reprendre pour `CYCLE.template.md` : sections `##`, placeholders entre crochets, note en `>` pour
les invariants (« ★ Clé de voûte », etc.).

---

### `plugin/planning-core/references/templates/config.template.json` (config, nouvelle valeur `planning_version`)

**Analog:** `plugin/planning-core/references/templates/config.template.json` **existant** (28
lignes, lu intégralement) — **squelette à créer à côté**, jamais à écraser (D-01b) :
```json
{
  "planning_version": "2.0",
  "project_code": "[CODE]",
  "scope": "lab",
  "type": null,
  "profile": "leger",
  "domain": "[dev | contenu | vente | dossier | design | recherche | autre]",
  ...
  "compartments": { "enabled": false, "root": "projects", ... },
  "memory_bridge": { "enabled": true, "registries_path": ".claude/memory" }
}
```
D-02 impose une valeur `planning_version` **nouvelle**, distincte des 5 occurrences déjà présentes
de "1.0" (STATE.template.md) et "2.0" (INDEX.template.md, BOARD.template.md,
config.template.json) — RESEARCH.md « State of the Art » : choisir une valeur qui ne collisionne
ni ne ressemble à un incrément numérique (ex. non-numérique explicite), documentée dans
`references/modele-cycles.md`.

---

### `plugin/planning-core/VERSION` / `module.json` / `CHANGELOG.md` / `README.md` (version bump mineur)

**Analog:** état actuel du module lui-même — patron d'entrée changelog à reproduire
(`plugin/planning-core/CHANGELOG.md` lignes 1-14, dernière entrée) :
```markdown
# Changelog — planning-core

## [v2.7.1] — 2026-09-24 (gates de planning workstream-aware, Phase 41.1)

**Patch** (durcissement de gates workstream-aware, Phase 41.1) :

- **`scripts/workstream-policy.sh`** : `vf_ws_enumerate` (neuve) — primitive **unique**
  d'énumération disque des compartiments `.planning/workstreams/<nom>/`, ...
```
→ Nouvelle entrée `## [v2.8.0] — 2026-XX-XX (moteur — modèle de données et recalcul d'état,
Phase 44)`, libellée **Minor** (nouvelle capacité, pas un durcissement de l'existant — D-18).

`module.json` actuel :
```json
{
  "name": "planning-core",
  "version": "v2.7.1",
  "type": "skill + references + scripts",
  "description": "...",
  "requires": []
}
```
→ bump du seul champ `"version"`, cohérent avec `VERSION` (`scripts/check-version-sync.sh` vérifie
la triade `VERSION`/`module.json`/CHANGELOG — cité en RESEARCH.md Integration Points). **Aucun
bump de la `VERSION` racine ni tag** (D-18, garde-fou du jalon gouvernance).

`README.md` — section « Contenu du module » (lignes 69-94) à étendre avec les nouveaux fichiers
`recalc-planning.sh`, `references/modele-cycles.md`, `references/templates/CYCLE.template.md`,
`references/templates/CADRAGE.template.md`, en gardant le même style de commentaire inline
(`# rôle en une ligne`) déjà utilisé pour chaque entrée de l'arborescence.

## Shared Patterns

### Python embarqué en heredoc bash (patron `dag.sh`)
**Source:** `plugin/conductor/scripts/dag.sh` lignes 69-108
**Apply to:** `recalc-planning.sh` (seul fichier concerné dans cette phase — aucun autre point
d'entrée Python n'est requis par D-14 voie a)
```bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd 2>/dev/null || dirname "$0")"
python3 - "$ARG1" "$ARG2" <<'PYEOF'
import sys
...
sys.exit(0)
PYEOF
```
Non négociable : heredoc **quoté**, résolution de sibling **par répertoire de script jamais par
cwd** (vecteur RCE fermé documenté dag.sh lignes 160-170), arguments **positionnels** (`sys.argv`),
jamais de données métier passées par variable d'environnement.

### Détection GSD réutilisée en subprocess (D-02a)
**Source:** `plugin/planning-core/scripts/detect-gsd-engine.sh` (script complet, 193 lignes) +
patron d'invocation proposé en RESEARCH.md « Invocation avec siblings »
**Apply to:** `recalc-planning.sh`, mode écriture uniquement
```bash
python3 - "$MODE" "$PLANNING_DIR" "$DETECT_GSD_SH" <<'PYEOF'
import sys, subprocess
mode, planning_dir, detect_gsd_sh = sys.argv[1:4]
def gsd_engine_active(path):
    try:
        r = subprocess.run([detect_gsd_sh, "--quiet", "--path", path],
                            capture_output=True, timeout=5, check=False)
        return r.returncode == 0
    except Exception:
        return False
if mode == "write" and gsd_engine_active(planning_dir):
    print("refus: planning GSD actif, ecriture refusee (D-02a)", file=sys.stderr)
    sys.exit(1)
PYEOF
```
`detect-gsd-engine.sh` n'est **jamais réimplémenté** (D-01d : aucune dépendance de code vers
gsd-core, mais réutiliser un script du même module planning-core est le patron déjà établi par
`dag.sh` → `driver-lock.sh`/`check-guard-health.sh`/`notify.sh`).

### Déterminisme de sortie (à durcir par rapport à `dag.sh`)
**Source:** `plugin/conductor/scripts/dag.sh` ligne 120 (`json.dump(dag, fh, indent=2,
ensure_ascii=False)` — **sans** `sort_keys=True`, un oubli documenté par RESEARCH.md à ne pas
reproduire)
**Apply to:** toute écriture JSON du recalcul (`INDEX.md` n'est pas du JSON mais le cache l'est)
et tout parcours de répertoire :
```python
for cycle in sorted(os.listdir(cycles_dir)):   # jamais os.listdir() nu, ordre FS non garanti
    ...
json.dump(obj, fh, indent=2, ensure_ascii=False, sort_keys=True)
```

### Test bash avec fixtures + mutation testing tracée
**Source:** `plugin/planning-core/scripts/tests/test-detect-gsd-engine.sh` (lu intégralement,
patron `check_exit`/`check_bool`, cas MUT-1 lignes 200-214) et
`plugin/conductor/scripts/tests/test-dag.sh` (assertions `assert`/`assert_exit`/`assert_eq`)
**Apply to:** `test-recalc-planning.sh`
- `set -uo pipefail`, `TMP=$(mktemp -d)` + `trap 'rm -rf "$TMP"' EXIT`
- un helper `mk_*()` par famille de fixture, PASS/FAIL comptés en variables shell
- toute garde de D-08/D-11/D-13 prouvée par une mutation sur une **copie** du script, jamais
  l'original, `cmp -s` en clôture pour l'attester
- code de sortie final `[ "$FAIL" -eq 0 ]`

### Frontmatter minimal + placeholders `[...]`
**Source:** `plugin/planning-core/references/templates/STATE.template.md` (frontmatter YAML plat +
un seul niveau de nesting), `config.template.json` (JSON plat + sous-objets nommés)
**Apply to:** tous les nouveaux templates (`CYCLE.template.md`, `CADRAGE.template.md`,
`VERDICT.template.md`) — registre d'inconnues de `CADRAGE.md` en **liste de mappings sous une clé
frontmatter**, jamais un tableau Markdown en corps de document (contrainte A2 de RESEARCH.md,
directement liée à ce que le parseur minimal de D-12 peut couvrir sans sur-ingénierie).

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| Parseur de frontmatter minimal (module Python) | service (transform) | transform | Aucun parseur frontmatter maison n'existe dans le dépôt — `detect-gsd-engine.sh` ne fait qu'un `awk` borné pour une seule clé (`has_frontmatter_key`, lignes 79-86), pas un parseur généraliste. RESEARCH.md fournit une proposition `[ASSUMED]` (Code Examples), à concevoir de novo au plan. |
| Cache incrémental versionné (`cache_schema_version`) | service (state) | CRUD | Aucun cache de ce type dans le corpus ; `dag.sh` n'a pas de notion de schéma versionné pour son propre fichier `.dag.json`. Proposition `[ASSUMED]` en RESEARCH.md (Pitfall 2 + Code Examples) à valider au plan. |
| Écriture atomique (`tempfile.mkstemp` + `os.replace`) | utility | file-I/O | Aucun exemple dans le corpus — `dag.sh.save()` est justement l'anti-pattern à ne pas reproduire (RESEARCH.md le signale explicitement). Proposition stdlib standard en RESEARCH.md Code Examples. |
| Fichier marqueur de clôture de plan (D-03) | marker file | file-I/O | Concept neuf, aucun fichier de ce rôle n'existe dans le dépôt (le socle v2 marque la clôture par des champs dans `SUMMARY.md`/`STATE.md`, jamais un fichier séparé). Nom et contenu délégués au planificateur ; format à documenter dans `references/modele-cycles.md`. |
| `VERDICT.template.md` (champs `hash`+`tentative`) | template | — | Aucun `VERDICT.md` n'existe dans le socle v2 (qui n'a pas de notion de verdict jugé/haché) — livrable de cette phase, extrapolé de la spec §3/§10 (RESEARCH.md Open Question #1). |
| Fixtures arborescence `.planning/` synthétique multi-fichiers | test fixture | file-I/O | Aucune fixture « arbre `.planning/` complet » dans le dépôt ; les fixtures existantes de `conductor/scripts/tests/fixtures/` sont des scripts figés, format sans rapport. |

## Metadata

**Analog search scope:** `plugin/conductor/scripts/`, `plugin/conductor/scripts/tests/`,
`plugin/planning-core/scripts/`, `plugin/planning-core/scripts/tests/`,
`plugin/planning-core/references/`, `plugin/planning-core/references/templates/`,
`plugin/planning-core/{VERSION,module.json,CHANGELOG.md,README.md}`,
`plugin/_internal/vibeflow-update.sh` (sites d'installation)
**Files scanned:** 14 fichiers lus intégralement ou par grep ciblé (dag.sh 491 lignes lu en
entier ; detect-gsd-engine.sh 193 lignes lu en entier ; test-detect-gsd-engine.sh 218 lignes lu en
entier ; test-dag.sh 1005 lignes — grep ciblé + 90 premières lignes lues, pas de lecture
intégrale ; 5 templates + config.template.json lus en entier ; module.json/VERSION/CHANGELOG(40
lignes)/README lus ; vibeflow-update.sh — 3 extraits ciblés lignes ~1180-2075)
**Pattern extraction date:** 2026-09-27
**Tracked-source gate :** les 14 chemins d'analogue cités sont vérifiés `git ls-files` (tous
présents, tous sous `plugin/` du dépôt de distribution lui-même — aucun miroir
`.gsd/capabilities/` en jeu sur ce dépôt).
