# Phase 19: Migration du moteur GSD pilotée par /vf-update - Pattern Map

**Mapped:** 2026-07-28
**Files analyzed:** 8 (livre CONTEXT.md, hors release-meta générique)
**Analogs found:** 6 / 8 (release-meta et ADR n'ont pas d'analog code — patron doc pur)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `plugin/dev-orchestrator/scripts/check-gsd-engine.sh` (créé) | utility/gate (advisory) | request-response (probe → stdout+exit) | `plugin/dev-orchestrator/scripts/check-doc-drift.sh` | exact |
| `plugin/dev-orchestrator/scripts/tests/test-check-gsd-engine.sh` (créé) | test | batch (black-box subprocess) | `plugin/dev-orchestrator/scripts/tests/test-check-doc-drift.sh` | exact |
| `plugin/dev-orchestrator/scripts/ensure-deps.sh` (modifié) | utility/bootstrap (side-effecting) | CRUD-like (detect → install → patch) | lui-même (patch en place — pas d'analog externe nécessaire) | n/a (self-modify) |
| `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` (modifié, mode `--verify`) | utility/transform (frontmatter rewrite) | file-I/O | lui-même (extension du `case` de parsing existant) | n/a (self-modify) |
| `plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh` (étendu) | test | batch | lui-même (ajout de cas Tn) | n/a (self-extend) |
| `plugin/conductor/skills/vf-update/SKILL.md` (modifié) | skill/orchestration doc | request-response (diagnostic → confirmation → exécution) | lui-même (étapes 1/3/4b, §Garde-fous réécrites) | n/a (self-modify) |
| Release-meta (`VERSION`, `module.json`, `CHANGELOG.md`, `README.md` ×2 modules) | config/doc | batch (bump cohérent) | Release-meta de Phase 13/17 (patron répété, non relu ici — cité dans CONTEXT.md D-10) | role-match (doc pattern, pas de code) |
| `docs/ADR.md` (nouvel ADR) | doc | n/a | ADR-051/ADR-054 existants dans le même fichier (style d'entrée ADR) | role-match |

## Pattern Assignments

### `plugin/dev-orchestrator/scripts/check-gsd-engine.sh` (gate, request-response)

**Analog:** `plugin/dev-orchestrator/scripts/check-doc-drift.sh` (154 lignes, lu intégralement)

**En-tête / doctrine à répliquer** (lignes 1-60) : commentaire de tête qui documente heuristique,
convention F13, contrat d'exit, AVANT tout code. Le nouveau script doit avoir la même densité de
commentaire, adaptée aux 3 états `absent/legacy/gsd-core` (D-03) au lieu du seuil de drift.

**Parsing des flags** (lignes 61-88) :
```bash
set -uo pipefail
shopt -s nullglob

ROOT="."
THRESHOLD="20"
HOOK=0
QUIET=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      if [ "$#" -lt 2 ]; then
        echo "[check-doc-drift] --path nécessite une valeur" >&2
        exit 64
      fi
      ROOT="$2"; shift 2 ;;
    --hook) HOOK=1; shift ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-doc-drift] argument inconnu : $1" >&2; exit 64 ;;
  esac
done
```
Pour `check-gsd-engine.sh` : reprendre exactement ce squelette (`--hook`/`--quiet` mutuellement
exclusifs, `-h|--help` qui grep le propre en-tête `# `), sans `--path`/`--threshold` (pas
pertinents ici) — remplacer par rien de spécifique sauf option interne éventuelle laissée à la
discrétion du planner.

**Gate de mutuelle exclusion `--hook`/`--quiet`** (lignes 90-94) — copier tel quel :
```bash
if [ "$HOOK" -eq 1 ] && [ "$QUIET" -eq 1 ]; then
  echo "[check-doc-drift] --hook et --quiet sont mutuellement exclusifs" >&2
  exit 64
fi
```

**Helper `say()`** (ligne 104) — patron à reprendre à l'identique avec le nom du nouveau script :
```bash
say() { [ "$QUIET" -eq 1 ] || echo "[check-doc-drift] $*" >&2; }
```

**Contrat d'exit F13 — mapping pour ce script (D-02, différent des 0/3/64 de check-doc-drift)** :
- `0` = legacy détecté, migration à proposer (cas actionnable — **inversé** par rapport à
  check-doc-drift où 0 = signal ; ici aussi 0 = signal, donc même polarité en fait)
- `2` = erreur d'usage (check-doc-drift utilise `64` — **noter la divergence explicite** : le
  CONTEXT.md D-02 fixe `2` pour ce script précis, pas `64`. Le planner doit trancher/valider ce
  point avec le contrat F13 du repo — `CONVENTIONS.md` fait foi en cas de doute).
- `3` = INDÉTERMINÉ (absent, ou déjà gsd-core) — identique au patron `check-doc-drift.sh:56-60`.

**Détection par cascade réutilisée, pas réécrite** (D-03) — depuis `ensure-deps.sh:60-72` :
```bash
default_gsd_home_new() {
  local root claude_home
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  claude_home="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  if [ -d "$root/.claude/gsd-core" ]; then
    echo "$root/.claude/gsd-core"
  else
    echo "$claude_home/gsd-core"
  fi
}
GSD_HOME_NEW="$(default_gsd_home_new)"
GSD_VERSION_FILE_NEW="$GSD_HOME_NEW/VERSION"
GSD_VERSION_FILE_LEGACY="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/get-shit-done/VERSION"
```
Le nouveau gate doit soit dupliquer cette fonction (script indépendant testable en boîte noire —
motif D-01 explicite : "un gate séparé est testable en boîte noire"), soit la sourcer — à trancher
par le planner, mais **le contenu de la cascade est fixe et vient de là, ne pas réinventer**.

**Piège n°1 documenté à recopier dans le nouvel en-tête** (`ensure-deps.sh:116-121`) :
```bash
# Détecte GSD : cascade fichier VERSION UNIQUEMENT (jamais de test PATH — piège n°1). Un shim
# legacy (ex. gsd-sdk) peut rester sur le PATH après migration : un `command -v` ferait toujours
# renvoyer vrai et gsd-core ne serait jamais installé (panne silencieuse et durable).
detect_gsd() {
  [ -f "$GSD_VERSION_FILE_NEW" ] || [ -f "$GSD_VERSION_FILE_LEGACY" ]
}
```
Cette fonction booléenne existante doit devenir, dans le nouveau gate, une fonction à **3 retours**
(`absent`/`legacy`/`gsd-core`) plutôt qu'un booléen — c'est le cœur de D-03/D-04.

**Silence hors dépôt / silence hors condition (patron `check-doc-drift.sh:117-121`)** — même
gabarit d'`if` + `say` + `exit 3` à réutiliser pour l'état `absent`.

**Signal final imprimé sur stdout** (patron `check-doc-drift.sh:144-150`) :
```bash
if [ "$COUNT" -ge "$THRESHOLD" ]; then
  say "seuil atteint : ..."
  printf '%s\n' "[doc-drift] ${COUNT} ..."
  printf '%s\n' "            → propose gsd-docs-update."
  exit 0
fi
```
Pour le nouveau gate : `printf '%s\n' "[check-gsd-engine] moteur GSD legacy 1.42.3 → ..."` — même
usage de `printf` (jamais `echo` pour le signal capturé) + préfixe `[check-gsd-engine]` cohérent
avec `say()`.

---

### `plugin/dev-orchestrator/scripts/tests/test-check-gsd-engine.sh` (test)

**Analog:** `plugin/dev-orchestrator/scripts/tests/test-check-doc-drift.sh` (233 lignes, lu
intégralement)

**Squelette complet à copier** (lignes 1-31) :
```bash
#!/usr/bin/env bash
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-doc-drift.sh"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
```
Remplacer `SCRIPT=".../check-doc-drift.sh"` par `.../check-gsd-engine.sh`. Le couple `ok()/ko()`
et le `TMP`/`trap` sont à reprendre à l'identique (isolation `HOME` factice requise ici puisque le
gate lit des fichiers sous `$HOME/.claude/...` ou `<root>/.claude/...` — adapter `mk_git_root` en
un helper `mk_gsd_home` qui pose/enlève des fichiers `VERSION` factices aux deux layouts).

**Style d'un cas** (patron répété partout, ex. lignes 80-83) :
```bash
# === Cas 1 — Hors dépôt git → stdout vide, exit 3 ================================================
D="$TMP/not-a-repo"; mkdir -p "$D"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "1 hors dépôt git → silence, exit 3"; else ko "1 hors dépôt git → silence, exit 3" "rc=$rc out=[$out]"; fi
```
Reprendre ce gabarit `# === Cas N — <titre> ===` + capture séparée de `out`/`rc` + assertion
combinée dans un seul `if`, jamais un test qui déduit l'un de l'autre (piège D-14 explicitement
rappelé en CONTEXT.md).

**Cas obligatoires listés par D-11** (à mapper sur ce gabarit, un `# === Cas N ===` par état) :
1. état `absent` (aucun fichier VERSION, ni nouveau ni legacy layout)
2. état `legacy` (seul `GSD_VERSION_FILE_LEGACY` existe)
3. état `gsd-core` (seul `GSD_VERSION_FILE_NEW` existe)
4. cas dual (D-04) : les deux fichiers VERSION existent → état `gsd-core` + signal distinct de
   reliquat legacy à nettoyer
5. couple exact `1.42.3 → 1.8.0 ⇒ à migrer` (D-05) — fixture VERSION contenant ces valeurs
   littérales, assertion que le message contient bien les deux numéros et pas de comparaison
   semver
6. scénario réel du rapport : legacy installé + plugin à jour → migration détectée

**Fin de fichier** (lignes 230-233) — patron d'issue de suite, à copier tel quel :
```bash
echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
```

**Portabilité (D-11 §Portabilité / ADR-054)** — la suite `test-check-doc-drift.sh` n'a pas de garde
`bash -n` propre à elle mais en contient un cas (`Cas 20`, ligne 219-220) :
```bash
if bash -n "$SCRIPT" 2>/dev/null; then ok "20 bash -n passe sur check-doc-drift.sh"; else ko ... ; fi
```
À répliquer pour `check-gsd-engine.sh`.

---

### `plugin/dev-orchestrator/scripts/ensure-deps.sh` (modification en place)

**Zones exactes à toucher (D-06, D-08), citées par ligne dans CONTEXT.md et vérifiées à la
lecture** :

**`detect_gsd()` actuel** (lignes 116-121) — le `||` booléen à remplacer par un état à 3 valeurs :
```bash
detect_gsd() {
  [ -f "$GSD_VERSION_FILE_NEW" ] || [ -f "$GSD_VERSION_FILE_LEGACY" ]
}
```

**`detect_gsd_legacy()`** (lignes 126-128) — inchangé dans sa forme, mais son usage en aval change
(capturé avant l'install, D-08 point 3) :
```bash
detect_gsd_legacy() {
  [ -f "$GSD_VERSION_FILE_LEGACY" ]
}
```

**`ensure_gsd()` — l'early-return/skip actuel à corriger** (lignes 130-137) :
```bash
ensure_gsd() {
  if detect_gsd && ! { [ -n "$DRY_RUN" ] && [ -n "$FORCE" ]; }; then
    log "GSD déjà présent (skip)."
    log_legacy_cleanup_if_needed
    return 0
  fi
  ...
```
Le skip (":133" selon CONTEXT.md) ne doit plus s'appliquer si l'état est `legacy` : c'est le cœur
de D-06. Le nouveau chemin `--migrate-engine` doit enchaîner l'install (même bloc npx que
lignes 162-170) puis appeler `patch_gsd_executor_mcp` (déjà fait en fin de `main`, ligne 313) dans
le **même run**.

**Bloc npx avec plafond semver `@^1` intouchable** (lignes 162-170) — à ne PAS toucher, juste
invoqué depuis le nouveau chemin :
```bash
log "GSD absent — installation via npx (non-interactif, scope=$SCOPE → $GSD_SCOPE_FLAG)..."
if run_cmd npx -y "@opengsd/gsd-core@^1" --claude "$GSD_SCOPE_FLAG"; then
    log "GSD installé via npx."
    log_legacy_cleanup_if_needed
    return 0
  fi
```

**`log_legacy_cleanup_if_needed()` — message à corriger (D-08 points 1-2)** (lignes 184-191) :
```bash
log_legacy_cleanup_if_needed() {
  if detect_gsd_legacy; then
    log "Artefacts legacy détectés (~/.claude/get-shit-done/) — nettoyage manuel recommandé :"
    log "  npm uninstall -g get-shit-done-cc"
    log "  npm uninstall -g @gsd-build/sdk"
    log "  rm -rf ~/.claude/get-shit-done"
  fi
}
```
À corriger : les deux lignes `npm uninstall` ne doivent apparaître **que si `npm ls -g` confirme**
le paquet réellement installé (D-08.1), et une ligne de retrait de l'arborescence vide doit
s'ajouter (D-08.2) — probablement via `find <dir> -type d -empty -delete` proposé, jamais exécuté
(ADR-031, patron "Proposer, jamais exécuter" déjà en vigueur ici : tout le corps de cette fonction
n'est que des `log`, aucune exécution).

**`patch_gsd_executor_mcp()` déjà idempotent/best-effort à réutiliser tel quel** (lignes 248-284) —
patron best-effort à copier pour toute nouvelle sonde cross-module (D-00/D-07) :
```bash
patch_gsd_executor_mcp() {
  local injector
  injector="$(dirname "$0")/inject-mcp-tools.sh"
  if [ ! -f "$injector" ]; then
    log "gsd-executor : inject-mcp-tools.sh introuvable à côté de ce script — patch MCP sauté (best-effort)."
    return 0
  fi
  ...
```

**Helpers `log()`/`err()`** (lignes 76-82) — convention à respecter partout dans ce fichier :
```bash
log() { echo "[ensure-deps] $*" >&2; }
err() { echo "[ensure-deps] ERROR: $*" >&2; }
```

---

### `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` (mode `--verify`, D-09)

**Bloc de parsing existant, point d'insertion exact** (lignes 52-65) :
```bash
while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)    [ "$#" -ge 2 ] || { err "--target nécessite une valeur"; exit 1; }; TARGET="$2"; shift 2 ;;
    --target=*)  TARGET="${1#--target=}"; shift ;;
    --mcp-json)  [ "$#" -ge 2 ] || { err "--mcp-json nécessite une valeur"; exit 1; }; MCP_JSON="$2"; shift 2 ;;
    --mcp-json=*) MCP_JSON="${1#--mcp-json=}"; shift ;;
    --servers)   [ "$#" -ge 2 ] || { err "--servers nécessite une valeur"; exit 1; }; SERVERS="$2"; shift 2 ;;
    --servers=*) SERVERS="${1#--servers=}"; shift ;;
    --force)     FORCE="true"; shift ;;
    --dry-run)   DRY_RUN="true"; shift ;;
    -h|--help)   grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *)           err "argument inconnu : $1"; exit 1 ;;
  esac
done
```
`--verify` s'insère comme un flag booléen de plus, même forme que `--force`/`--dry-run` :
`--verify)   VERIFY="true"; shift ;;` déclaré avec `VERIFY="false"` en tête (même style que
`FORCE`/`DRY_RUN` lignes 49-50).

**Garde `--force` référencée en D-09** (lignes 165-168, dans le bloc python embarqué) — logique de
lecture du frontmatter/flag à réutiliser pour composer le "relire le `tools:` final" du mode
`--verify` :
```python
if single and not force and not has_flag(text):
    logline("%s : pas de flag vf-mcp-consumer et pas de --force — ignore." % base)
    continue
```

**Contrat "dit fort, jamais avalé" (D-09)** — le mode `--verify` doit produire une sortie bruyante
(`err`, pas `log`) si un serveur manquant, cohérent avec `err()` déjà défini ligne 44 :
```bash
log() { echo "[inject-mcp-tools] $*" >&2; }
err() { echo "[inject-mcp-tools] ERROR: $*" >&2; }
```
Le calcul des tokens attendus (`want_tokens`) et la lecture de `existing` (lignes 108-114 et
188-196 du bloc python) sont directement réutilisables pour le diff de vérification :
```python
want_tokens = ["mcp__%s__*" % s for s in servers]
...
existing = [tok.strip() for tok in value.split(",") if tok.strip()]
missing = [tok for tok in want_tokens if tok not in existing]
```

---

### `plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh` (extension, cas `--verify`)

**Analog:** lui-même — suite déjà existante à étendre, pas remplacer.

**Squelette de fixtures et helpers déjà en place** (lignes 1-33) :
```bash
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/inject-mcp-tools.sh"
pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }
md5of() { md5 -q "$1" 2>/dev/null || md5sum "$1" | cut -d' ' -f1; }
toolsline() { grep -m1 '^tools:' "$1"; }
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
```

**Fixtures réutilisables telles quelles** (`mk_flagged`, `mk_gsd_executor`, `mk_notools` — lignes
36-80) : le nouveau cas `--verify` doit réemployer `mk_gsd_executor` (agent hors plugin, sans
flag) pour couvrir exactement le scénario D-09 (gsd-executor patché puis vérifié).

**Convention de numérotation** — la suite utilise des labels `T1`…`T9` en commentaire d'en-tête
(lignes 4-15) : ajouter `T10 — --verify détecte un serveur manquant (sortie bruyante, non nul)` et
`T11 — --verify confirme silencieusement quand tout est injecté` dans la liste d'en-tête ET comme
nouveaux blocs de test en bas de fichier, même style `ok()/ko()`.

---

### `plugin/conductor/skills/vf-update/SKILL.md` (modification de doctrine)

**Analog:** lui-même (82 lignes, lu intégralement) — pas de script sur ce fichier, patron
markdown/skill à modifier en place.

**Étape 1 actuelle à réécrire (D-07)** (lignes 30-36) :
```markdown
### 1 — Diagnostic de version

Lance `bash <S>/check-plugin-update.sh --print`. Parse le JSON `{update_available, installed, latest}`.

- `latest` vaut `unknown` (réseau KO) → dis-le, propose de réessayer plus tard, **stop**.
- `update_available` = false → annonce « VibeFlow est à jour (v<installed>) » et **stop**.
- Sinon continue.
```
Devient un diagnostic à deux volets : appeler AUSSI `check-gsd-engine.sh` (sonde best-effort dans
`<S>`, silence total si absent) AVANT le `stop` de la ligne `update_available = false` — ce stop ne
doit plus être atteint tant que l'état moteur n'a pas été consulté.

**Résolution `<S>` déjà écrite, à réutiliser sans nouvelle mécanique** (lignes 22-26) :
```markdown
Les scripts vivent dans le dossier `scripts/` de conductor. Localise-les dans cet ordre (prends le
premier existant) : `$HOME/.claude/scripts/` → `./.claude/scripts/` → `${CLAUDE_PLUGIN_ROOT}/conductor/scripts/`.
Note ce dossier `<S>` pour les étapes suivantes.
```
La sonde D-07 vers `check-gsd-engine.sh` s'y branche telle quelle (même `<S>`, même ordre de
cascade) — c'est un script de `dev-orchestrator` matérialisé à plat dans le même `<S>` (D-00).

**Étape 3 actuelle — flags `--check`/`--modules-only`** (lignes 46-52) :
```markdown
### 3 — Confirmation (ADR-031 — jamais d'update sans validation humaine)

Récapitule via **AskUserQuestion** : « Plugin v<installed> → v<latest> + les modules installés
seront mis à jour. Continuer ? ». Gère les flags de `$ARGUMENTS` :

- `--check` → affiche seulement les étapes 1–2, **ne demande pas**, **stop**.
- `--modules-only` → saute l'étape 4a (ne touche pas au plugin).
```
La ligne moteur (« moteur GSD legacy 1.42.3 → `@opengsd/gsd-core` 1.8.0 ») s'ajoute dans le
récapitulatif `AskUserQuestion`, acceptable/refusable indépendamment (D-07). `--check` doit
afficher l'état moteur sans jamais proposer ; `--modules-only` ne doit PAS proposer la migration
moteur (borné par son nom).

**§Garde-fous actuel — phrase à réécrire (D-07)** (lignes 74-81) :
```markdown
## Garde-fous

- **Aucune mise à jour sans confirmation explicite** (sauf `--modules-only`/`--check` qui restent
  cadrés). ADR-031.
- **Best-effort réseau** : une détection impossible n'est jamais une erreur bloquante.
- **Ne jamais downgrader** : l'engine saute les modules déjà à jour (comparaison de version).
- Périmètre : le **plugin VibeFlow** et ses modules. La chaîne d'outils interne (GSD/Superpowers)
  a sa propre mise à jour (`gsd-update`) — hors périmètre de ce skill.
```
Le dernier tiret (« la chaîne d'outils interne… hors périmètre ») est **la phrase devenue fausse**
à réécrire pour dire que le moteur GSD entre dans le périmètre (détecté et proposé, jamais
installé sans accord), Superpowers restant hors périmètre.

---

## Shared Patterns

### Contrat d'exit F13 (advisory gates)
**Source:** `plugin/dev-orchestrator/scripts/check-doc-drift.sh:56-60`
**Apply to:** `check-gsd-engine.sh`
```
0  = signal émis (cas actionnable)
3  = rien à signaler (silence)
64 = argument invalide (check-doc-drift) — noter que D-02 fixe `2` pour check-gsd-engine.sh,
     divergence à valider par le planner contre `.planning/codebase/CONVENTIONS.md`.
```

### Helper `say()`/`log()`/`err()` — un préfixe `[nom-script]` par fichier
**Source:** `check-doc-drift.sh:104`, `ensure-deps.sh:76-82`, `inject-mcp-tools.sh:43-44`
**Apply to:** tous les fichiers du Livre — chaque script conserve son propre préfixe, jamais un
préfixe générique partagé.

### Best-effort sans dégradation (sonde cross-module)
**Source:** `ensure-deps.sh:251-254` (`patch_gsd_executor_mcp`, injecteur absent → log + return 0),
`ensure-deps.sh:263-266` (agent cible introuvable → log + return 0)
**Apply to:** la sonde `check-gsd-engine.sh` dans `SKILL.md` étape 1 (absent → silence total,
D-07) et le mode `--verify` d'`inject-mcp-tools.sh` (python3 absent → no-op exit 0, ligne 72-75).

### Harnais de test maison
**Source:** `test-check-doc-drift.sh:1-31`, `test-inject-mcp-tools.sh:1-33`
**Apply to:** `test-check-gsd-engine.sh` (nouveau) et l'extension de `test-inject-mcp-tools.sh`.
`ok()/ko()`, `mktemp -d` + `trap ... EXIT`, capture séparée stdout/exit-code, jamais d'assertion
combinée déduisant l'un de l'autre (piège D-14, rappelé explicitement dans le CONTEXT.md pour
cette phase).

### FAIT vs JUGEMENT (ADR-055 §3)
**Source:** en-tête `check-doc-drift.sh:1-6` (« ne dit JAMAIS que la doc est fausse... seulement
qu'elle n'a pas bougé »)
**Apply to:** `check-gsd-engine.sh` — le script **constate** l'état du moteur, jamais ne lance
d'install ni ne qualifie l'urgence ; c'est l'agent (skill) qui juge et propose.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `docs/ADR.md` (nouvel ADR) | doc | n/a | Patron doc pur, pas de code — copier le format des ADR voisins déjà cités (ADR-051, ADR-054) dans le même fichier, non relus ligne à ligne ici (hors scope pattern-code). |
| Release-meta ×2 modules (`VERSION`/`module.json`/`CHANGELOG.md`/`README.md`) | config/doc | batch | Patron répété de Phases 13/17 (D-10 le cite explicitement) — mécanique déjà connue du planner, pas un pattern de code à extraire ici. |

## Metadata

**Analog search scope:** `plugin/dev-orchestrator/scripts/` (+ `tests/`), `plugin/conductor/skills/vf-update/`
**Files read in full:** `check-doc-drift.sh` (154 lignes), `ensure-deps.sh` (324 lignes),
`test-check-doc-drift.sh` (233 lignes), `inject-mcp-tools.sh` (216 lignes),
`test-inject-mcp-tools.sh` (lignes 1-80, fixtures + en-tête — suffisant, pas de re-lecture requise),
`vf-update/SKILL.md` (82 lignes).
**Pattern extraction date:** 2026-07-28
