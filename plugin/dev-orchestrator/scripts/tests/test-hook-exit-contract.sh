#!/usr/bin/env bash
# test-hook-exit-contract.sh — Suite de contrat de sortie des 5 scripts SessionStart de dev-orchestrator
#
# Ferme le trou identifié par RESEARCH.md (Wave 0 Gaps, Pitfall 2) : « aucun test ne capture stdout
# et stderr séparément ». Suite NEUVE et dédiée (plutôt qu'une extension de
# test-dev-orchestrator.sh) : elle a besoin d'un harness particulier — deux flux capturés dans deux
# fichiers DISTINCTS sous mktemp -d, jamais fusionnés (aucun `2>` suivi de `&1` nulle part dans ce
# fichier) — et elle doit rester lisible comme la preuve d'un contrat, pas se diluer dans 700 lignes.
#
# Couvre les 5 scripts normalisés par le plan VFDO-30-04 (D-06) puis étendus par le plan 18-01
# (LEDG-02) : check-dev-bootstrap.sh, discover-unintegrated-docs.sh, check-doc-drift.sh,
# check-gsd-config.sh, check-requirements-survival.sh — tous partagent la MÊME fonction hook_exit()
# (texte identique, vérifié par grep) : sous --hook, le SEUL code de silence interne (3) devient 0 à
# la frontière du harness ; tous les autres codes restent inchangés, avec ou sans --hook.
#
# Matrice de cas, RÉPLIQUÉE À L'IDENTIQUE pour chacun des 5 scripts (5 x 5 = 25 cas de base) :
#   1. silencieux, SANS --hook   → code de silence documenté (3), stdout vide (non-régression CLI)
#   2. silencieux, AVEC --hook   → code 0 ET stdout STRICTEMENT vide (zéro octet) — critère 5 de la
#      spec, tenu par un test et non par relecture
#   3. avec signal, AVEC --hook  → code 0 ET stdout NON vide (le signal est bien injecté — la
#      normalisation ne doit pas éteindre les signaux au passage)
#   4. erreur d'argument, AVEC --hook → code 64, message sur stderr, stdout vide
#   5. mutuelle exclusion (--hook + --quiet) → code 64
#
# Trois issues par cas (QUAL-01), jamais un skip silencieux, jamais un vert par défaut :
#   - succès (ok)
#   - échec EXPLICITE nommant la dimension fautive — code, stdout ou stderr (ko)
#   - échec BRUYANT si l'exécution est imparsable — script introuvable, ou code de sortie rendu
#     hors du contrat {0, 3, 64} (abort)
#
# Discrimination par MUTATION (convention du dépôt : un test vert sous mutation ne prouve rien).
# Les 5 scripts partagent la MÊME fonction hook_exit() (texte identique) : une seule paire de
# patrons sed, appliquée aux 5 copies mutées, suffit à prouver la discrimination sur le parc entier
# plutôt que sur un seul script :
#   (m1) hook_exit ignore le mode --hook (neutralise la condition HOOK) → les cas « silencieux avec
#        --hook » (attendu 0) rougissent : ils obtiennent 3.
#   (m2) hook_exit traduit 3 → 0 SANS condition de mode → les cas de non-régression CLI (« silencieux
#        SANS --hook », attendu 3) rougissent : ils obtiennent 0.
#   (m3) hook_exit écrit une ligne sur stdout dans le chemin silencieux AVANT de traduire → le cas
#        « silencieux avec --hook » rougit sur la dimension STDOUT (attendu vide, obtenu non vide)
#        alors que le CODE reste bon (0) — c'est la mutation qui prouve que la suite teste le FLUX,
#        pas seulement le code.
# Chaque mutation est jouée contre les 5 scripts (15 cas), restaurée immédiatement après (les
# mutants vivent sous mktemp -d, jamais dans l'arbre réel — aucun fichier du dépôt n'est modifié par
# cette suite).
#
# Fixtures : entièrement sous mktemp -d, jamais le .planning/ réel du dépôt qui exécute cette suite.
# La suite tourne hors ligne (check-doc-drift.sh construit son propre dépôt git local jetable —
# aucun accès réseau).
#
# Convention : compteurs ok()/ko()/abort(), exit 0 si 0 KO/0 ABORT (affiche « 0 KO »), exit 1 sinon.
# Référence : PORT-03, D-06, docs/HOOKS-CONTRAT-SORTIE.md.

set -uo pipefail

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$(cd "$SELF_DIR/.." && pwd)"

BOOTSTRAP="$SCRIPTS_DIR/check-dev-bootstrap.sh"
DISCOVER="$SCRIPTS_DIR/discover-unintegrated-docs.sh"
DOCDRIFT="$SCRIPTS_DIR/check-doc-drift.sh"
GSDCONFIG="$SCRIPTS_DIR/check-gsd-config.sh"
SURVIVAL="$SCRIPTS_DIR/check-requirements-survival.sh"

pass=0; fail=0
ok()    { echo "  ✓ $1"; pass=$((pass+1)); }
ko()    { echo "  ✗ $1"; fail=$((fail+1)); }
abort() { echo "  ✗✗ IMPARSABLE — $1"; fail=$((fail+1)); }

CASES_DIR="$(mktemp -d)" || { echo "mktemp -d a échoué — suite imparsable" >&2; exit 1; }
trap 'rm -rf "$CASES_DIR"' EXIT

# ==================================================================================================
# Harness — deux flux, DEUX fichiers, jamais fusionnés. CASE_ENV (optionnel, "NOM=val NOM2=val2")
# est consommé et effacé à chaque appel — jamais réutilisé par accident d'un cas au suivant.
# ==================================================================================================
CASE_ENV=""
run_case() { # <label> <script> <expect_rc> <stdout_mode: empty|nonempty|any> <stderr_mode: empty|nonempty|any> -- <args...>
  local label="$1" script="$2" expect_rc="$3" stdout_mode="$4" stderr_mode="$5"; shift 5
  local out err rc dims=""
  if [ ! -x "$script" ] && [ ! -f "$script" ]; then
    abort "$label — script introuvable : $script"
    CASE_ENV=""
    return
  fi
  out="$(mktemp -p "$CASES_DIR")"
  err="$(mktemp -p "$CASES_DIR")"
  if [ -n "$CASE_ENV" ]; then
    env $CASE_ENV bash "$script" "$@" >"$out" 2>"$err"
  else
    bash "$script" "$@" >"$out" 2>"$err"
  fi
  rc=$?
  CASE_ENV=""
  case "$rc" in
    0|3|64) : ;;
    *) abort "$label — code de sortie HORS CONTRAT : $rc (attendu un parmi 0/3/64)"; return ;;
  esac
  if [ "$rc" -ne "$expect_rc" ]; then
    dims="${dims}code(attendu ${expect_rc}, obtenu ${rc}) "
  fi
  case "$stdout_mode" in
    empty)    [ -s "$out" ] && dims="${dims}stdout(attendu vide, obtenu $(wc -c < "$out" | tr -d ' ') octets) " ;;
    nonempty) [ -s "$out" ] || dims="${dims}stdout(attendu non vide, obtenu vide) " ;;
    any) : ;;
  esac
  case "$stderr_mode" in
    empty)    [ -s "$err" ] && dims="${dims}stderr(attendu vide, obtenu $(wc -c < "$err" | tr -d ' ') octets) " ;;
    nonempty) [ -s "$err" ] || dims="${dims}stderr(attendu non vide, obtenu vide) " ;;
    any) : ;;
  esac
  if [ -n "$dims" ]; then
    ko "$label — dimension(s) fautive(s) : $dims"
  else
    ok "$label"
  fi
}

# ==================================================================================================
# Fixtures — sous CASES_DIR (mktemp -d), jamais le .planning/ réel.
# ==================================================================================================

# Cas « silencieux » : un répertoire vide suffit pour les 4 scripts (absence de code ET de
# .planning/, absence de docs/superpowers, hors dépôt git, absence de .planning/config.json).
EMPTY_DIR="$(mktemp -d -p "$CASES_DIR")"

# Signal check-dev-bootstrap.sh : code source présent, .planning/ absent → état 1 [onboard].
BOOTSTRAP_SIGNAL_DIR="$(mktemp -d -p "$CASES_DIR")"
printf 'print("hi")\n' > "$BOOTSTRAP_SIGNAL_DIR/main.py"

# Signal discover-unintegrated-docs.sh : un spec non cité par aucun registre.
DISCOVER_SIGNAL_DIR="$(mktemp -d -p "$CASES_DIR")"
mkdir -p "$DISCOVER_SIGNAL_DIR/docs/superpowers/specs" "$DISCOVER_SIGNAL_DIR/.planning"
printf '# spec\n' > "$DISCOVER_SIGNAL_DIR/docs/superpowers/specs/example-spec.md"

# Signal check-doc-drift.sh : dépôt git jetable, un commit de doc PUIS un commit de code, seuil 1.
DOCDRIFT_SIGNAL_DIR="$(mktemp -d -p "$CASES_DIR")"
git -C "$DOCDRIFT_SIGNAL_DIR" init -q
git -C "$DOCDRIFT_SIGNAL_DIR" config user.email "t@example.invalid"
git -C "$DOCDRIFT_SIGNAL_DIR" config user.name "test"
mkdir -p "$DOCDRIFT_SIGNAL_DIR/docs"
printf 'doc\n' > "$DOCDRIFT_SIGNAL_DIR/docs/x.md"
git -C "$DOCDRIFT_SIGNAL_DIR" add -A
git -C "$DOCDRIFT_SIGNAL_DIR" commit -q -m "doc: x"
printf 'code\n' > "$DOCDRIFT_SIGNAL_DIR/code.txt"
git -C "$DOCDRIFT_SIGNAL_DIR" add -A
git -C "$DOCDRIFT_SIGNAL_DIR" commit -q -m "feat: code"

# Signal check-gsd-config.sh : config.json avec un bloc de premier niveau inconnu, moteur factice
# minimal (VF_GSD_CORE_LIB) portant les 3 sources lisibles du script (schema, capability-registry,
# defaults) — jamais le moteur réel de la machine qui exécute cette suite.
GSDCONFIG_ROOT="$(mktemp -d -p "$CASES_DIR")"
GSDCONFIG_LIB="$GSDCONFIG_ROOT/engine/bin/lib"
mkdir -p "$GSDCONFIG_ROOT/lab/.planning" "$GSDCONFIG_LIB" "$GSDCONFIG_ROOT/engine/bin/shared"
printf '{"totally_unknown_block": true}\n' > "$GSDCONFIG_ROOT/lab/.planning/config.json"
: > "$GSDCONFIG_LIB/config.cjs"
printf '{"validKeys": ["workflow.code_review"], "dynamicKeyPatterns": []}\n' \
  > "$GSDCONFIG_ROOT/engine/bin/shared/config-schema.manifest.json"
printf 'const configKeys = { "workflow.pattern_mapper": true };\n' \
  > "$GSDCONFIG_LIB/capability-registry.cjs"
printf '{"workflow": {"code_review": true}}\n' \
  > "$GSDCONFIG_ROOT/engine/bin/shared/config-defaults.manifest.json"

# Signal check-requirements-survival.sh (LEDG-02, plan 18-01) : jalon clos déclaré dans
# MILESTONES.md, .planning/REQUIREMENTS.md absent, archive de reconstitution présente → [ledger-absent].
SURVIVAL_SIGNAL_DIR="$(mktemp -d -p "$CASES_DIR")"
mkdir -p "$SURVIVAL_SIGNAL_DIR/.planning/milestones"
printf '# Milestones\n\n## \xe2\x9c\x85 demo-v1 \xe2\x80\x94 Un jalon clos (fixture de contrat de sortie)\n\nDétail.\n' \
  > "$SURVIVAL_SIGNAL_DIR/.planning/MILESTONES.md"
printf -- '- [x] **AAAA-01**: texte\n\n## Traceability\n\n| Requirement | Phase | Status |\n|---|---|---|\n| AAAA-01 | Phase 1 | Done |\n' \
  > "$SURVIVAL_SIGNAL_DIR/.planning/milestones/demo-v1-REQUIREMENTS.md"

# ==================================================================================================
# Matrice de base — 5 cas x 5 scripts = 25 cas.
# ==================================================================================================

echo "== check-dev-bootstrap.sh =="
run_case "check-dev-bootstrap.sh — silencieux, sans --hook"      "$BOOTSTRAP" 3  empty    any      --path "$EMPTY_DIR"
run_case "check-dev-bootstrap.sh — silencieux, avec --hook"      "$BOOTSTRAP" 0  empty    any      --path "$EMPTY_DIR" --hook
run_case "check-dev-bootstrap.sh — signal, avec --hook"          "$BOOTSTRAP" 0  nonempty any      --path "$BOOTSTRAP_SIGNAL_DIR" --hook
run_case "check-dev-bootstrap.sh — erreur d'argument, avec --hook" "$BOOTSTRAP" 64 empty  nonempty --hook --ne-existe-pas
run_case "check-dev-bootstrap.sh — mutuelle exclusion"           "$BOOTSTRAP" 64 empty    nonempty --path "$EMPTY_DIR" --hook --quiet

echo "== discover-unintegrated-docs.sh =="
run_case "discover-unintegrated-docs.sh — silencieux, sans --hook"      "$DISCOVER" 3  empty    any      --path "$EMPTY_DIR"
run_case "discover-unintegrated-docs.sh — silencieux, avec --hook"      "$DISCOVER" 0  empty    any      --path "$EMPTY_DIR" --hook
run_case "discover-unintegrated-docs.sh — signal, avec --hook"          "$DISCOVER" 0  nonempty any      --path "$DISCOVER_SIGNAL_DIR" --hook
run_case "discover-unintegrated-docs.sh — erreur d'argument, avec --hook" "$DISCOVER" 64 empty  nonempty --hook --ne-existe-pas
run_case "discover-unintegrated-docs.sh — mutuelle exclusion"           "$DISCOVER" 64 empty    nonempty --path "$EMPTY_DIR" --hook --quiet

echo "== check-doc-drift.sh =="
run_case "check-doc-drift.sh — silencieux, sans --hook"      "$DOCDRIFT" 3  empty    any      --path "$EMPTY_DIR"
run_case "check-doc-drift.sh — silencieux, avec --hook"      "$DOCDRIFT" 0  empty    any      --path "$EMPTY_DIR" --hook
run_case "check-doc-drift.sh — signal, avec --hook"          "$DOCDRIFT" 0  nonempty any      --path "$DOCDRIFT_SIGNAL_DIR" --hook --threshold 1
run_case "check-doc-drift.sh — erreur d'argument, avec --hook" "$DOCDRIFT" 64 empty  nonempty --hook --ne-existe-pas
run_case "check-doc-drift.sh — mutuelle exclusion"           "$DOCDRIFT" 64 empty    nonempty --path "$EMPTY_DIR" --hook --quiet

echo "== check-gsd-config.sh =="
run_case "check-gsd-config.sh — silencieux, sans --hook"      "$GSDCONFIG" 3  empty    any      --path "$EMPTY_DIR"
run_case "check-gsd-config.sh — silencieux, avec --hook"      "$GSDCONFIG" 0  empty    any      --path "$EMPTY_DIR" --hook
CASE_ENV="VF_GSD_CORE_LIB=$GSDCONFIG_LIB"
run_case "check-gsd-config.sh — signal, avec --hook"          "$GSDCONFIG" 0  nonempty any      --path "$GSDCONFIG_ROOT/lab" --hook
run_case "check-gsd-config.sh — erreur d'argument, avec --hook" "$GSDCONFIG" 64 empty  nonempty --hook --ne-existe-pas
run_case "check-gsd-config.sh — mutuelle exclusion"           "$GSDCONFIG" 64 empty    nonempty --path "$EMPTY_DIR" --hook --quiet

echo "== check-requirements-survival.sh =="
run_case "check-requirements-survival.sh — silencieux, sans --hook"      "$SURVIVAL" 3  empty    any      --path "$EMPTY_DIR"
run_case "check-requirements-survival.sh — silencieux, avec --hook"      "$SURVIVAL" 0  empty    any      --path "$EMPTY_DIR" --hook
run_case "check-requirements-survival.sh — signal, avec --hook"          "$SURVIVAL" 0  nonempty any      --path "$SURVIVAL_SIGNAL_DIR" --hook
run_case "check-requirements-survival.sh — erreur d'argument, avec --hook" "$SURVIVAL" 64 empty  nonempty --hook --ne-existe-pas
run_case "check-requirements-survival.sh — mutuelle exclusion"           "$SURVIVAL" 64 empty    nonempty --path "$EMPTY_DIR" --hook --quiet

# ==================================================================================================
# Discrimination par MUTATION — m1/m2/m3, jouées contre les 5 scripts (15 cas). Mutants sous
# CASES_DIR uniquement : aucun fichier du dépôt réel n'est jamais modifié par cette suite.
# ==================================================================================================

# make_mutant écrit le mutant dans un RÉPERTOIRE dédié (jamais un fichier nu) sous le NOM RÉEL du
# script : check-requirements-survival.sh découvre sa primitive par dirname($0) — un fichier renommé
# ou isolé casserait ce sourcing et ferait basculer le mutant sur l'issue « outil absent » plutôt que
# sur la mutation testée. Le répertoire est retourné sur stdout.
make_mutant() { # <mutation_id> <script_reel> <dstdir> -> imprime le chemin du mutant
  local mid="$1" src="$2" dstdir="$3"
  local dst="$dstdir/$(basename "$src")"
  mkdir -p "$dstdir"
  case "$mid" in
    m1) sed -e '/^hook_exit()/,/^}/ s/\[ "\$HOOK" -eq 1 \]/[ "$HOOK" -eq 9 ]/' "$src" > "$dst" ;;
    m2) sed -e '/^hook_exit()/,/^}/ s/if \[ "\$HOOK" -eq 1 \] && \[ "\$code" -eq 3 \]; then/if [ "$code" -eq 3 ]; then/' "$src" > "$dst" ;;
    m3) sed -e '/^hook_exit()/,/^}/ s/^    exit 0$/    echo "mutation-m3-leak"; exit 0/' "$src" > "$dst" ;;
  esac
  chmod +x "$dst"
  printf '%s' "$dst"
}

MUT_TRACE=""
mutant_case() { # <mutation_id> <label_script> <script_mutant> <expect_rc> <stdout_mode> -- <args...>
  local mid="$1" slabel="$2" script="$3" expect_rc="$4" stdout_mode="$5"; shift 5
  local out err rc dims=""
  out="$(mktemp -p "$CASES_DIR")"
  err="$(mktemp -p "$CASES_DIR")"
  bash "$script" "$@" >"$out" 2>"$err"
  rc=$?
  if [ "$rc" -ne "$expect_rc" ]; then
    dims="${dims}code(attendu ${expect_rc} — comportement correct —, obtenu ${rc} sous la mutation) "
  fi
  case "$stdout_mode" in
    empty) [ -s "$out" ] && dims="${dims}stdout(attendu vide — comportement correct —, obtenu $(wc -c < "$out" | tr -d ' ') octets sous la mutation) " ;;
  esac
  if [ -n "$dims" ]; then
    ok "MUTATION $mid ($slabel) rougit comme attendu : $dims"
    MUT_TRACE="${MUT_TRACE}${mid} · ${slabel} : ${dims}
"
  else
    ko "MUTATION $mid ($slabel) — N'A PAS ROUGI : la suite ne discrimine pas ce défaut sur ce script"
  fi
}

echo "== Mutations m1/m2/m3 (discrimination, jouées contre les 5 scripts) =="
for pair in "$BOOTSTRAP:check-dev-bootstrap.sh" "$DISCOVER:discover-unintegrated-docs.sh" \
            "$DOCDRIFT:check-doc-drift.sh" "$GSDCONFIG:check-gsd-config.sh" \
            "$SURVIVAL:check-requirements-survival.sh"; do
  SRC="${pair%%:*}"; NAME="${pair##*:}"
  DIR_M1="$(mktemp -d -p "$CASES_DIR")"; MUT_M1="$(make_mutant m1 "$SRC" "$DIR_M1")"
  DIR_M2="$(mktemp -d -p "$CASES_DIR")"; MUT_M2="$(make_mutant m2 "$SRC" "$DIR_M2")"
  DIR_M3="$(mktemp -d -p "$CASES_DIR")"; MUT_M3="$(make_mutant m3 "$SRC" "$DIR_M3")"
  # check-requirements-survival.sh découvre sa primitive par dirname($0) : sans une copie NON
  # mutée de requirements-survival-detect.sh à côté, le mutant basculerait sur [ledger-outil-absent]
  # au lieu d'exercer réellement hook_exit() muté.
  if [ "$NAME" = "check-requirements-survival.sh" ]; then
    cp "$SCRIPTS_DIR/requirements-survival-detect.sh" "$DIR_M1/"
    cp "$SCRIPTS_DIR/requirements-survival-detect.sh" "$DIR_M2/"
    cp "$SCRIPTS_DIR/requirements-survival-detect.sh" "$DIR_M3/"
  fi

  # m1 casse le cas « silencieux avec --hook » (attendu 0) → doit rougir sur le CODE.
  mutant_case "m1" "$NAME" "$MUT_M1" 0 empty --path "$EMPTY_DIR" --hook
  # m2 casse le cas « silencieux sans --hook » (attendu 3, non-régression CLI) → doit rougir sur le CODE.
  mutant_case "m2" "$NAME" "$MUT_M2" 3 empty --path "$EMPTY_DIR"
  # m3 laisse le CODE bon (0) mais fait fuiter du texte sur stdout → doit rougir sur STDOUT seul.
  mutant_case "m3" "$NAME" "$MUT_M3" 0 empty --path "$EMPTY_DIR" --hook
done

echo
echo "-- Trace des rougissements de mutation (à citer dans le SUMMARY) --"
printf '%s' "$MUT_TRACE"

echo
echo "== résultat : $pass OK / $fail KO =="
[ "$fail" -eq 0 ] && exit 0 || exit 1
