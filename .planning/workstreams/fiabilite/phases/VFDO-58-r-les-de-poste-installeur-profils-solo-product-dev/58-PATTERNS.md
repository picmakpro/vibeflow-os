# Phase 58 : Rôles de poste — Pattern Map

**Mapped:** 2026-10-16
**Files analyzed:** 27 (13 neufs, 14 modifiés)
**Analogs found:** 25 / 27 (2 sans analogue direct : ADR-077, comparateur du critère 2)

Tous les analogues cités sont TRACKÉS (`git ls-files` vérifié sur les 12 sources de code et de tests). Aucun chemin miroir `.claude/` ou `.gsd/capabilities/`. Les numéros de ligne sont ceux de `HEAD` (`c8a38435`, arbre `plugin/` = `a2ed5094`) ; les plans doivent citer les fonctions par nom (±2 lignes).

## File Classification

| Fichier neuf / modifié | Rôle | Flux | Analogue le plus proche | Qualité |
|---|---|---|---|---|
| `plugin/_internal/module-roles.sh` (neuf) | utility (validateur/prédicat jq) | transform | `plugin/_internal/resolve-deps.sh` + `jqx` de `build-module-catalog.sh` | role-match |
| `plugin/_internal/tests/test-module-roles.sh` (neuf) | test | batch | `plugin/_internal/tests/test-resolve-deps.sh` | exact |
| `plugin/dev-orchestrator/module.json`, `mobile-test/module.json`, `mobile-test-team/module.json` (+`"roles":["dev"]`) | config | n/a | `module.json` voisins (clé optionnelle `proposable`/`mandatory`) | exact |
| `plugin/conductor/scripts/vf-role.sh` (neuf) | utility (lecteur unique) | request-response (stdout = 1 valeur) | `plugin/conductor/scripts/runtime-registry.sh` (`get-active`) + lecture sûre de `check-workstream-pointer.sh` | role-match |
| `plugin/conductor/scripts/tests/test-vf-role.sh` (neuf) | test | batch | `tests/test-check-workstream-pointer.sh` | exact |
| `plugin/conductor/scripts/check-role-consistency.sh` (neuf) | gate (hook advisory) | request-response | `plugin/conductor/scripts/check-workstream-pointer.sh` | exact |
| `plugin/conductor/scripts/tests/test-check-role-consistency.sh` (neuf) | test à mutants | batch | `tests/test-check-workstream-pointer.sh` | exact |
| `plugin/conductor/hooks/hooks.json` (+1 entrée SessionStart exec) | config | event-driven | entrées l.27 (`check-guard-health.sh`) et l.30-34 (`guard-fin-de-geste.sh`) | exact |
| `docs/HOOKS-CONTRAT-SORTIE.md` (inventaire +1) | doc | n/a | l'inventaire existant du même fichier | exact |
| `plugin/installer/scripts/build-module-catalog.sh` (+`--role`/`VF_ROLE`) | utility | transform | lui-même + pré-parse `--scope` de `vibeflow-update.sh` | exact |
| `plugin/installer/scripts/tests/test-build-module-catalog-role.sh` (neuf) | test | batch | `plugin/installer/scripts/tests/test-build-module-catalog.sh` | exact |
| `plugin/_internal/vibeflow-update.sh` (`--role`, pose du poste, filtre `--all`, verbe `role`) | service (engine) | CRUD fichiers | `--scope` (l.138, 159-166, 208), `ensure_worktreeinclude_entries`, `write_target_marker`, `gitignore_add_one` | exact |
| `plugin/_internal/tests/test-vibeflow-update-role.sh` (neuf) | test | batch (lab jetable) | `test-vibeflow-update.sh` bloc T57 (l.2470+) | exact |
| `plugin/_internal/tests/test-roles-e2e.sh` (neuf) | test e2e | batch | `test-vibeflow-update.sh` (en-tête, isolation HOME) | role-match |
| `plugin/installer/SKILL.md` (corps seul) | doc/skill | n/a | étapes 2 et 4 du même fichier | exact |
| `docs/ADR.md` (ADR-077 + index) | doc | n/a | ADR-076 (l.3085+), ADR-075 (l.3028) | exact (format) |
| `docs/_transverse/REFERENCE.md` (glossaire), `plugin/conductor/README.md` | doc | n/a | sections existantes | role-match |
| `plugin/{conductor,dev-orchestrator,mobile-test,mobile-test-team}/{VERSION,module.json,CHANGELOG.md,README.md}`, `README.md`, `README.fr.md` | config/doc | n/a | bumps précédents ; `scripts/check-version-sync.sh` | exact |
| Éventuel `plugin/_internal/resolve-preset.sh` (Open Question 1) | utility | transform | `resolve-preset.sh` + `tests/test-resolve-preset.sh` | exact |

## Pattern Assignments

### `plugin/conductor/scripts/check-role-consistency.sh` (gate, request-response)

**Analogue :** `plugin/conductor/scripts/check-workstream-pointer.sh` (223 lignes). C'est le seul gate à trois issues + erreur bruyante + `--hook` avec traduction des codes silencieux.

**En-tête = table d'états + usage + codes** (l.1-72) : docstring `# États mutuellement exclusifs…`, `# Usage:`, `# Codes de sortie (chacun énuméré, aucun implicite) :`, repris tel quel avec les codes de P58-D-09. L'aide est `grep '^# ' "$0" | sed 's/^# //'` ; la suite vérifie que chaque code y figure sous la forme `<code> = …`. Chaque ligne de code doit donc commencer par `#   <n>  = `.

**Parsing d'options, exit 64** (l.73-91) :
```bash
set -uo pipefail
ROOT="."
HOOK=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      [ "$#" -ge 2 ] || { echo "[check-workstream-pointer] --path nécessite une valeur" >&2; exit 64; }
      ROOT="$2"; shift 2 ;;
    --path=*)
      ROOT="${1#--path=}"
      [ -n "$ROOT" ] || { echo "[check-workstream-pointer] --path nécessite une valeur" >&2; exit 64; }
      shift ;;
    --hook) HOOK=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-workstream-pointer] argument inconnu : $1" >&2; exit 64 ;;
  esac
done
```
À ajouter : `--role <poste>` / `--role=*` (poste candidat pour le refus à la pose), même moule.

**diag / signal / hook_exit** (l.93-119) : à copier en renommant le préfixe `[check-role-consistency]`.
```bash
diag() { [ "$HOOK" -eq 1 ] && return 0; echo "[check-workstream-pointer] $*" >&2; }
signal() {
  if [ "$HOOK" -eq 1 ]; then echo "[workstream-pointer] $*"
  else echo "[check-workstream-pointer] $*" >&2; fi
}
hook_exit() { # <code>
  local code="$1"
  if [ "$HOOK" -eq 1 ] && { [ "$code" -eq 2 ] || [ "$code" -eq 3 ]; }; then
    exit 0
  fi
  exit "$code"
}
```
**Écart voulu (P58-D-09, A3)** : ne traduire sous `--hook` que `3 -> 0`. Le code d'erreur d'analyse (proposé 4, hors `{0,1,2,3,64}`) n'est jamais traduit ; 2 reste réservé au blocage du harness et n'est pas émis. Le mutant MUT-hook de la suite doit retirer cette traduction.

**Lecture sans risque** (l.164-185, motif `vf_ws_resolve`) : symlink refusé, borne d'octets, valeur jamais réimprimée, raisons en énumération FERMÉE (`case "$VF_WS_REASON"`). Reprendre la posture pour `.claude/vibeflow-role` et `vf_roles` : régulier, pas un lien, borné, une seule ligne, rogné aux bords uniquement (cf. cas 6d/6d-bis/6d-ter de la suite). Imprimer sous `--hook` la valeur validée (`solo|product|dev`), jamais le contenu brut (Pitfall 7).

**Git durci et résolution de racine** (l.121-130) :
```bash
export GIT_CONFIG_NOSYSTEM=1
export GIT_TERMINAL_PROMPT=0
export GIT_OPTIONAL_LOCKS=0
git_safe() { git -C "$ROOT" -c core.fsmonitor= -c core.hooksPath=/dev/null --no-optional-locks "$@"; }
```
Ne PAS copier le test « hors dépôt git → exit 2 » tel quel sans le décider : le gate de poste doit marcher en lab racine non-git (mémoire « racine jamais par comptage de `../` »). Ordre de racine proposé (A9) : `--path` > `CLAUDE_PROJECT_DIR` > `git rev-parse --show-toplevel` > `.`. Jamais de `../` compté depuis `$0`.

**Lecture JSON de `vf_roles`** : `vf_python` + `json.load` via `plugin/_internal/lib/vf-portable.sh` (`vf_resolve_python`, `vf_guard_unavailable`, code 17), comme `check-guard-health.sh`. Précédent de la clé : `plugin/conductor/scripts/runtime-registry.sh:1-7` (`vf_runtimes`, « propriété VibeFlow, jamais lue par gsd-core »). Ce script lit avec `node` ; le gate neuf préfère `vf_python`.

**Trailers** : `Gate-Touche:` (le fichier est un `check-*.sh`) et `Ajout-Retrait:` (statut A).

---

### `plugin/conductor/scripts/tests/test-check-role-consistency.sh` et `test-vf-role.sh` (test à mutants)

**Analogue :** `plugin/conductor/scripts/tests/test-check-workstream-pointer.sh` (336 lignes).

**Harnais ok/ko, fixtures jetables** (l.18-54) :
```bash
set -uo pipefail
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-workstream-pointer.sh"
PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
RCS="$TMP/rcs.txt"; : > "$RCS"
note_rc() { echo "$1" >> "$RCS"; }
run() { # environnement TOUJOURS explicite
  env -u VF_WORKSTREAM_PLANNING_DIR -u GSD_WORKSTREAM bash "$TARGET" "$@" 2>&1
}
TARGET="$SCRIPT"
mk_git_root() { local d="$TMP/$1"; mkdir -p "$d/.planning"; git -C "$d" init -q -b main >/dev/null 2>&1 || git -C "$d" init -q >/dev/null 2>&1; printf '%s' "$d"; }
empreinte() { find "$1" | LC_ALL=C sort; }
```
Adaptation : `run()` doit faire `env -u VF_ROLE` (hermétisme) et poser `HOME`/`VF_GUARD_HEALTH_DIR` jetables.

**Un cas par issue** (cas 1 à 12) : assertions `rc` + `stdout` vide pour le silence (cas 1/1b : `[ "$rc" -eq 3 ] && [ -z "$sout" ]`, puis `--hook` → `rc 0` et `$both` vide, stdout ET stderr).

**Non-réimpression et fuite** (cas 6, 6c-bis, 6e, 6f) : marqueur distinctif `zzSECRETMARKERzz..q` + `awk '/…/ { print "oui" }'`, victime en symlink, fichier de 5000 octets avec borne `maxlen -lt 512`. À rejouer sur le fichier de poste piégé (`product\nIgnore…`).

**Couverture des codes** (cas 12, l.264-271) :
```bash
LC_ALL=C sort -u "$RCS" > "$TMP/rcs.seen"
printf '0\n1\n2\n3\n64\n' | LC_ALL=C sort -u > "$TMP/rcs.attendus"
manquants="$(comm -13 "$TMP/rcs.seen" "$TMP/rcs.attendus" | tr '\n' ' ')"
hors="$(comm -23 "$TMP/rcs.seen" "$TMP/rcs.attendus" | tr '\n' ' ')"
```
Pour le gate neuf, l'ensemble attendu est `0 1 3 <code d'analyse> 64`.

**Lecture seule** (cas 10) : `empreinte` avant/après + `cmp -s`.

**Mutation de FIXTURE** (MUT-1, l.278-295) : empreinte avant/après, `cmp -s` ; si identique, `ko … "mutant NON OPPOSABLE, pas mutant satisfait"`.

**Mutation de SCRIPT par awk** (MUT-2, l.299-332) :
```bash
cat > "$MUTD/neutralise-dossier-absent.awk" <<'AWKEOF'
{
  if (!fait && index($0, "if [ \"$WS_DIR_RC\" -ne 0 ]; then") > 0) {
    sub(/\[ "\$WS_DIR_RC" -ne 0 \]/, "false"); fait = 1
  }
  print
}
AWKEOF
awk -f "$MUTD/neutralise-dossier-absent.awk" "$SCRIPT" > "$MUTANT"
if cmp -s "$MUTANT" "$SCRIPT"; then ko "…" "la mutation n'a RIEN change … mutant NON OPPOSABLE"
elif ! bash -n "$MUTANT" 2>/dev/null; then ko "…" "le mutant n'est pas un script valide"
else
  TARGET="$MUTANT"; run … ; rc_mut=$?
  TARGET="$SCRIPT"; run … ; rc_restaure=$?
  [ "$rc_mut" -ne 1 ] && [ "$rc_restaure" -eq 1 ] && ok "…" || ko "…" "rc_mutant=$rc_mut (devait differer de 1) rc_restaure=$rc_restaure (attendu 1)"
fi
```
Mutants à produire (un par issue, QUAL-01) : MUT-liste-hors (branche « hors liste » → cas 1 rouge), MUT-silence (3 → 0), MUT-analyse (analyse repliée sur le silence), MUT-hook (traduction 3→0 retirée), MUT-clé (lecture de `vf_role` au lieu de `vf_roles`), MUT-brut (impression du contenu brut). Pour `vf-role.sh` : priorité env/fichier inversée, invalide → repli `solo`, absent → sortie vide. L'écrire AVEC les bords : `printf` de motifs awk dont le motif est `index($0, "<ligne exacte>")`.

Les motifs awk doivent suivre la lettre du script écrit (le MUT-2 d'origine a dû être réécrit quand la condition a changé). Fin de suite : `echo "== resultat : $PASS ok, $FAIL ko =="; [ "$FAIL" -eq 0 ]`.

**Trailer** : ce dossier est dans la surface G-2 → `Gate-Touche:` sur chaque commit.

---

### `plugin/conductor/scripts/vf-role.sh` (lecteur unique, stdout = 1 valeur)

**Analogue :** `plugin/conductor/scripts/runtime-registry.sh` pour le verbe `get` et l'en-tête (l.1-47) ; `check-workstream-pointer.sh` pour la lecture sûre.

**En-tête et usage** (runtime-registry l.26-47) :
```bash
# Usage:
#   runtime-registry.sh get-active [--config <chemin>]
#   runtime-registry.sh -h|--help
# Exit codes:
#   0 = succès ... 1 = erreur d'usage ... 2 = config introuvable ou JSON imparsable.
set -uo pipefail
usage() { grep '^# ' "$0" | sed 's/^# //'; }
case "$1" in -h|--help) usage; exit 0 ;; get-active|list-installed) CMD="$1"; shift ;; *) echo "[runtime-registry] verbe inconnu : $1" >&2; usage >&2; exit 1 ;; esac
```
Contrat P58-D-15 : `vf-role.sh get [--path <dir>]` ; `VF_ROLE` de l'environnement puis fichier ; absent = `solo` ; invalide, symlink, multi-ligne, illisible → stderr, stdout VIDE, code non nul distinct. Tolérer CRLF et BOM (A10). Recommandation de la recherche : `get` seul, écrivain unique dans l'engine. Le lecteur est ce que liront les Phases 59 à 61 : fixer le contrat dans l'en-tête.

---

### `plugin/conductor/hooks/hooks.json` (config, event-driven)

**Analogue :** entrées voisines, forme exec (ADR-071).
```json
{ "type": "command", "command": "{{VF_BASH}}", "args": ["{{VF_SCRIPTS}}/check-guard-health.sh", "--hook"] }
```
(l.27) ; groupe propre à un seul script (l.30-34) :
```json
{
  "hooks": [
    { "type": "command", "command": "{{VF_BASH}}", "args": ["{{VF_SCRIPTS}}/guard-fin-de-geste.sh", "--snapshot"] }
  ]
}
```
Entrée neuve : `{ "type": "command", "command": "{{VF_BASH}}", "args": ["{{VF_SCRIPTS}}/check-role-consistency.sh", "--hook"] }`. Groupe : Open Question 4 (groupe propre sans matcher, recommandé, ou groupe `startup`). Pas de `|| true` en exec. Un seul script par entrée (`merge-hooks.sh` purge par script). Le champ `description` (l.2) est une longue prose cumulative : y AJOUTER une phrase, ne pas le réécrire. Le fichier n'est pas dans la surface G-2 mais est une zone de risque gelée (MISSION-INVARIANTS). Mettre à jour `docs/HOOKS-CONTRAT-SORTIE.md` (T12 de `test-check-hook-paths.sh` compare doc et parc ; numéro d'entrée attribué au rebase, la PR #136 de Willy occupe 32-37).

---

### `plugin/installer/scripts/build-module-catalog.sh` (utility, transform) + sa suite neuve

**Analogue :** lui-même (57 lignes) et `plugin/installer/scripts/tests/test-build-module-catalog.sh`.

**Boucle à étendre** (l.44-57) :
```bash
for manifest in "$ROOT"/*/module.json; do
  [ -f "$manifest" ] || continue
  name=$(jqx -r '.name // empty' "$manifest")
  [ -n "$name" ] || continue
  hidden=$(jqx -r '.proposable == false' "$manifest")
  [ "$hidden" = "true" ] && continue
  description=$(jqx -r '.description // empty' "$manifest")
  mandatory=$(jqx -r '.mandatory // false' "$manifest")
  role="optional"; [ "$mandatory" = "true" ] && role="mandatory"
  printf '%s\t%s\t%s\n' "$name" "$description" "$role"
done | sort
```
**Piège de nom (Défaut 3)** : la variable interne `role` désigne le statut mandatory/optional. L'ajout de `--role` impose de la renommer en `statut`, sans changer la sortie à 3 colonnes (`ci.yml:1947` fait `awk '$3 == "mandatory"'`). Ne pas modifier `ci.yml`. Sortie sans poste identique à l'octet (preuve `cmp` contre l'ancien script, sur fixture ET repo réel).

**Interdits à reproduire** : `jqx` obligatoire (ADR-054) ; ne jamais utiliser `// true` (traite `false` comme vide) ; ne pas utiliser `contains([$r])`. Prédicat jq prototypé dans RESEARCH Code Example 1 (`roles_verdict`). Refus bruyant de `roles` invalide (`err`, exit 1).

**Pré-parse de `--role`** : même moule que `--scope` (vibeflow-update.sh l.159-166), sans `shift 2` caché :
```bash
    --scope)
      [ "$#" -ge 2 ] || err "--scope nécessite une valeur (user|project|local)"
      VF_SCOPE="$2"
      shift 2
      ;;
    --scope=*)
      VF_SCOPE="${1#--scope=}"
      shift
      ;;
```
Le drapeau l'emporte sur `VF_ROLE`. Validation fermée sur le modèle de l.208 : `case "$VF_ROLE" in ""|solo|product|dev) : ;; *) err "poste invalide : $VF_ROLE (attendu solo|product|dev)" ;; esac`.

**Atteindre le validateur** : `plugin/_internal/module-roles.sh` par chemin relatif à `$0` (`../../_internal/`), indépendamment de `VF_MODULES_ROOT` (voir RESEARCH Alternatives).

**Suite neuve — fixture isolée** (analogue, l.14-37) :
```bash
FIX=$(mktemp -d); trap 'rm -rf "$FIX"' EXIT
mkdir -p "$FIX/zeta" "$FIX/alpha" "$FIX/boss"
cat > "$FIX/zeta/module.json" <<'JSON'
{ "name": "zeta", "version": "v1.0.0", "type": "single-skill", "description": "Module Zeta de test.", "requires": [] }
JSON
fix_out=$(VF_MODULES_ROOT="$FIX" bash "$SCRIPT" 2>/dev/null)
```
Ajouter des fixtures `"roles": ["dev"]`, `[]`, `["qa"]`, `"dev"`, `["solo"]`. Les 14 cas d'origine restent verts, sans modification. Invariant testé : la fermeture (`resolve-deps.sh`) des modules visibles à `product` ne contient aucun module `["dev"]` ; témoin = fixture `product` qui `requires` un module dev, l'invariant doit rougir. Utiliser `command grep` (alias zsh), `env -u VF_ROLE`.

---

### `plugin/_internal/module-roles.sh` + `tests/test-module-roles.sh`

**Analogue :** `plugin/_internal/resolve-deps.sh` (en-tête, `command -v jq`, `jqx`, `ROOT="${VF_MODULES_ROOT:-…}"`, `set -euo pipefail`) :
```bash
set -euo pipefail
log() { echo "[resolve-deps] $*" >&2; }
err() { echo "[resolve-deps] ERROR: $*" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || err "jq introuvable — prérequis de l'engine (parse des module.json). …"
jqx() ( set -o pipefail; command jq "$@" | tr -d '\r'; )
ROOT="${VF_MODULES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
[ "$#" -ge 1 ] || err "usage: resolve-deps.sh <module> [<module> ...]"
```
Verbes proposés : `validate`, `visible <mod> <poste>`, `list <poste>`. Corps du prédicat : RESEARCH Code Example 1 (vérifié sur jq 1.7.1 ; A6 : jq ≥ 1.5 en CI non mesuré). Nom du module cité dans l'erreur d'un `roles` invalide.

**Suite :** `plugin/_internal/tests/test-resolve-deps.sh` (25 premières lignes) : `SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/…"`, `REPO_ROOT`, `export VF_MODULES_ROOT="$REPO_ROOT"`, `ok()`/`ko()` à un argument, assertion `[ "$out" = "$exp" ] && ok … || ko …`. Cas réel : exactement 3 modules `["dev"]` (dev-orchestrator, mobile-test, mobile-test-team) et aucune autre clé `roles`. Mutants : `length==0` retiré, `any(...)` retiré.

---

### `plugin/_internal/vibeflow-update.sh` (engine) + `tests/test-vibeflow-update-role.sh`

**Ne PAS toucher `gitignore_add_paths()`** (PR #136/#146/#147 de Willy ; preuve : extraction awk à `a2ed5094` et à HEAD, `cmp -s`). Poser le poste par des fonctions séparées appelées à côté.

**Pré-parse `--role`/`VF_ROLE`** (l.138 et 159-166, moule exact ci-dessus) : `VF_ROLE="${VF_ROLE:-}"` à côté de `VF_SCOPE="${VF_SCOPE:-project}"`, cas `--role)` / `--role=*)` dans la boucle, validation `case` fermée juste après celle du scope (l.208) ; la valeur n'atteint jamais `eval`, une position de commande ni un chemin avant validation.

**Réutilisables tels quels :**
- `gitignore_add_one` (l.1123-1135) : idempotent, crée `.gitignore`, déclare au plan.
```bash
gitignore_add_one() {
  local path="$1"
  if vf_dry_run; then vf_declare_write "~" "./.gitignore" "$path"; return 0; fi
  [ -f .gitignore ] || : > .gitignore
  if ! grep -qxF "$path" .gitignore; then echo "$path" >> .gitignore; log "  gitignore += $path"; fi
}
```
- `write_target_marker` (l.1456-1475) comme modèle d'écriture atomique du fichier de poste (tmp `$$` + `mv -f`, `vf_declare_write +`, déclaration avant le test `vf_dry_run`).
- `vf_manifest_excluded` (l.456-471), liste close : ajouter `scripts/..`/chemin du fichier de poste en suivant `scripts/.vibeflow-target) return 0 ;;`. Point UNIQUE.

**Pose conditionnelle par drapeau de run** (Pitfall 1/2) : miroir de `VF_SETTINGS_JSON_WILL_EXIST` (l.365 : initialisé depuis le disque, passé à 1 par le run) :
```bash
VF_SETTINGS_JSON_WILL_EXIST="0"
[ -f "$TARGET_ROOT/settings.json" ] && VF_SETTINGS_JSON_WILL_EXIST="1"
```
→ `VF_ROLE_WILL_EXIST`. Nécessaire : l'ajout inconditionnel à `ensure_worktreeinclude_entries` casse T57c (`awk 'END { print NR }'` = 4) et T57h (`cmp` CRLF), et le critère 2. Ligne à ajouter dans la boucle (l.1836) `for line in ".claude/hooks/" ".claude/scripts/"; do` seulement si drapeau à 1 ∨ fichier présent. Les appels `ensure_worktreeinclude_entries` (lignes `  ensure_worktreeinclude_entries` et `    ensure_worktreeinclude_entries`) sont les cibles des mutants T57j : ne pas les renommer ni les déplacer.

**Filtre de `install --all`** (l.3238-3241) : la boucle actuelle est
```bash
for m in $(list_available_modules); do install_module "$m"; done
```
Filtrer par `module-roles.sh visible "$m" "$VF_ROLE"` seulement si `VF_ROLE` est posé explicitement (P58-D-08). `update --all` (l.3258-3266, boucle `while IFS='=' read -r mod ver`) ne change pas ; le registre `.vibeflow-installed` reste `mod=version` strict (une ligne `role=…` serait lue comme un module).

**Nouveau verbe `role <poste>`** : s'insère dans le `case "$cmd" in` (l.3237), à côté de `status)` (l.3311). Réécrit le fichier, imprime un avis (modules installés hors poste, dérivés du registre + `roles`), aucune désinstallation. L'usage d'erreur suit `err "Usage: …"` (l.3254).

**Suite neuve — lab jetable sous HOME temporaire** (analogue T57, test-vibeflow-update.sh l.2470-2476) :
```bash
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
FAKE_HOME="$LAB/home"
mkdir -p "$FAKE_HOME"
if prepare_module "$CACHE" "conductor" && prepare_module "$CACHE" "validator"; then
  WI_INSTALL() { (cd "$LAB" && HOME="$FAKE_HOME" VF_RUNTIME=claude VF_SCOPE="${1:-project}" VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install validator 2>&1); }
```
En-tête de racines et harnais (l.26-45) :
```bash
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
INTERNAL_DIR="$(cd "$TESTS_DIR/.." && pwd)"
REPO="$(cd "$INTERNAL_DIR/.." && pwd)"
INSTALLER="$INTERNAL_DIR/vibeflow-update.sh"
pass=0; fail=0; skipped=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }
GREP="$(command -v grep)"
```
Définir `prepare_module` (copie d'un module du repo dans `$CACHE`) comme l'analogue ; `env -u VF_ROLE` partout où l'on teste « sans poste » ; `git init -q` du lab (sinon l'engine écrit `.planning/config.json` avec `workflow.use_worktrees=false`). Le pattern d'assertion T57 est `miss=0 … ko "T57x : …"; miss=1 … [ "$miss" -eq 0 ] && ok "…"`. Cas dry-run : plan == pose réelle (TD1/T57i comparent ces ensembles). **Ne jamais appendre à `test-vibeflow-update.sh`** (271 s, modifié aussi par la PR #136 de Willy) : fichier neuf.

---

### `plugin/_internal/tests/test-roles-e2e.sh` (critères 1, 2, 5, 6)

**Analogue :** en-tête et isolation de `test-vibeflow-update.sh` (HOME jetable, snapshot du vrai `~/.claude` avant/après, `snapshot_home_claude()` l.52+, `find … | wc -l`).

Éléments à copier : snapshot de contrôle du vrai HOME ; `HOME=$(mktemp -d)` avec `PYTHONUSERBASE` sauvegardé avant le changement de HOME ; `VF_RUNTIME=claude` explicite. Comparateur du critère 2 : RESEARCH Code Example 3 (`norm_tree`, normalisation de 4 sources non déterministes, témoin `VF_ROLE=product` qui doit rougir). Critère 5 : `git diff --name-only a2ed5094..HEAD` ne contient aucun `plugin/*/agents/*.md`. Critère 6 : aucune liste de noms de clients dans le dépôt (Open Question 6) : à fournir par l'humain.

---

### `plugin/installer/SKILL.md` (corps seul, jamais le frontmatter)

**Analogue :** étapes 2 (scope pré-sélectionné) et 4 (type de lab), l.~65-100. Forme à reprendre pour l'étape poste « 2 bis » (sans renuméroter, Open Question 8) : choix pré-coché « solo » en première option + une ligne d'explication, via l'UI de questions (AskUserQuestion, pas un TUI bash), et seulement en scope `project` ou `local`.

Passages à corriger : repli « liste des presets vide → dev-orchestrator » (étape 4, Pitfall 4) ; phrase périmée « les bundles métier incomplets sont marqués `proposable:false` » (étape 4, note) ; colonne `role` du catalogue → « statut » (étape 3 : `name<TAB>description<TAB>role`, `role == mandatory`). Frontmatter intact : le socle `@bootstrap:socle` est à 2610 (baseline `.planning/instruction-budget-baselines.tsv`), toute hausse rougit G-1.

---

### `docs/ADR.md` (ADR-077)

**Analogue (format) :** ADR-076 (`## ADR-076 : …` à la ligne 3085). Gabarit :
```markdown
## ADR-076 : <titre>

**Date** : 2026-09-30 · **Statut** : Validée · **Décideur** : Samuel · **Voisines** : ADR-031 (…), ADR-074 (…) · arbitrage Samuel, AskUserQuestion session principale, 2026-09-29 (…)

### Contexte
### Décision
### Précision d'ADR-031 / Ce que cette ADR ne change pas
```
ADR-077 : deux énoncés (« agentique first, ouvert à la collaboration humaine » ; « un poste est une vue, pas un droit »), arbitrage « Samuel, AskUserQuestion session principale, 2026-10-16 » (P58-D-11). Ligne d'index à ajouter ; ne pas réparer la ligne ADR-075 manquante (bruit préexistant). Écriture sous verrou `--depot` court, tenu par le manager. Trailer `Ajout-Retrait: ADR-077 — …`. Ne pas affirmer de protection serveur non mesurée (G-4).

---

### Bumps et registres (`VERSION`, `module.json`, `CHANGELOG.md`, `README.md`)

**Analogue :** `scripts/check-version-sync.sh` (points 6 et 9). Points à tenir : `VERSION` = `module.json` = en-tête `**Version**` du README = entrée CHANGELOG ; la ligne « N suites » des deux READMEs racine est recalculée par `find plugin scripts -path '*/tests/test-*.sh'` (6 suites neuves → recalcul après rebase). `plugin/installer` n'a ni `VERSION` ni `module.json` : rien à bumper (Défaut 8). Niveaux (A5) : conductor minor ; dev-orchestrator, mobile-test, mobile-test-team patch. Ne pas toucher `VERSION` racine, `plugin.json`, `marketplace.json`, `plugin/planning-core/module.json`.

## Shared Patterns

### Forme exec des hooks et traduction des codes (ADR-071, D-06/D-07)
**Source :** `plugin/conductor/hooks/hooks.json:27,32,39` ; `check-workstream-pointer.sh:103-119`
**Apply to :** `check-role-consistency.sh`, `hooks.json`. Stdout d'un hook sortant en 0 = contexte de session : il ne commence jamais par `{` et ne porte que la valeur validée.

### Lecture sûre d'un fichier d'état dans le contexte du modèle
**Source :** `check-workstream-pointer.sh:164-187` ; cas 6, 6c-bis, 6d, 6e, 6f de sa suite
**Apply to :** `vf-role.sh`, `check-role-consistency.sh`. Symlink refusé, borne d'octets, une ligne, bords rognés seulement, valeur rejetée jamais réimprimée, raisons énumérées.

### Preuve qui peut rendre rouge (QUAL-01)
**Source :** `test-check-workstream-pointer.sh:273-332` (MUT-1 fixture, MUT-2 script)
**Apply to :** les 6 suites neuves. `cmp -s` avant/après, `bash -n` sur le mutant, attendu/obtenu imprimés, restauration revérifiée verte, témoin positif avant tout verdict négatif.

### `jqx` et validation JSON
**Source :** `build-module-catalog.sh:33-37`, `resolve-deps.sh:23-25`
**Apply to :** `module-roles.sh`, catalogue. `jqx() ( set -o pipefail; command jq "$@" | tr -d '\r'; )`, jamais `jq` nu (ADR-054).

### Pré-parse d'option + validation fermée
**Source :** `vibeflow-update.sh:138,159-166,208`
**Apply to :** engine, catalogue, éventuel `resolve-preset.sh`.

### Écriture atomique et déclaration au plan
**Source :** `write_target_marker` (l.1456-1475), `vf_declare_write` (l.827)
**Apply to :** fichier de poste, règle d'ignorance, ligne `.worktreeinclude`.

### Hermétisme des suites
**Source :** T57 et `test-check-workstream-pointer.sh:35-44`
**Apply to :** toutes les suites neuves : `env -u VF_ROLE`, `HOME` jetable, `VF_GUARD_HEALTH_DIR` jetable, `VF_RUNTIME=claude`, `git init -q`. Pas de `timeout` sur ce poste : `perl -e 'alarm N; exec @ARGV'`. `grep` est réécrit par rtk : `command grep`, `awk`, `cmp -s`, `comm` (pas `diff`).

### Trailers de commit
**Apply to :** `Gate-Touche:` pour `check-role-consistency.sh`, `test-check-role-consistency.sh` et `test-vf-role.sh` (surface G-2 : `plugin/conductor/scripts/check-*.sh` et `plugin/conductor/scripts/tests/test-*.sh`) ; `Ajout-Retrait:` pour `check-role-consistency.sh` et ADR-077. Motif sans virgule. Les suites de `plugin/_internal/tests/` et `plugin/installer/scripts/tests/` ne sont pas dans cette surface.

## No Analog Found

| Fichier | Rôle | Flux | Raison |
|---|---|---|---|
| Texte d'ADR-077 | doc doctrinale | n/a | Le format se copie d'ADR-076, le fond vient de `.planning/notes/2026-09-16-doctrine-agentique-ouverte-collaboration-humaine.md` (promis, jamais écrit). |
| Comparateur du critère 2 (`norm_tree`, ancien engine vs nouvel engine) | e2e | batch | Aucune suite existante ne compare deux engines sur un même cache ; recette mesurée dans RESEARCH Code Example 3 et Pitfall 3. |
| Validateur de schéma de `module.json` | utility | transform | Aucun validateur n'existe aujourd'hui (P58-D-03) ; seul le prototype jq de RESEARCH Code Example 1 sert de base. |

## Metadata

**Analog search scope :** `plugin/conductor/scripts`, `plugin/conductor/scripts/tests`, `plugin/conductor/hooks`, `plugin/_internal`, `plugin/_internal/tests`, `plugin/installer`, `plugin/dev-orchestrator/module.json`, `docs/ADR.md`.
**Analogues retenus (lus en entier ou par plage) :** `check-workstream-pointer.sh`, `test-check-workstream-pointer.sh`, `hooks.json`, `build-module-catalog.sh`, `test-build-module-catalog.sh`, `runtime-registry.sh`, `resolve-deps.sh`, `test-resolve-deps.sh`, `vibeflow-update.sh` (plages), `test-vibeflow-update.sh` (plages), `docs/ADR.md` (ADR-076).
**Points à trancher par le planificateur (non couverts par un analogue) :** groupe du hook (OQ4), `solo` dans `vf_roles` (OQ5), filtre de presets (OQ1), manuel FR/EN (OQ7), liste de noms de clients pour le critère 6 (OQ6), arêtes engine A4.
**Pattern extraction date :** 2026-10-16
