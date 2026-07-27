#!/usr/bin/env bash
# test-check-dev-bootstrap.sh — Suite de vérification de check-dev-bootstrap.sh (SIG-01, plan 17-01).
#
# Un cas par piège. Fixtures isolées via mktemp -d + --path, jamais sur le repo réel.
# Piège central (D-14) : à l'état 3, le script IMPRIME une ligne ET sort en 3 — rupture assumée
# de la convention « exit 3 ⇔ silence ». Chaque cas capture stdout ET le code de retour dans DEUX
# variables distinctes (out=...; rc=$?) et les teste par DEUX conditions séparées — jamais une
# assertion qui déduit l'absence de sortie du code 3.

set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-dev-bootstrap.sh"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Crée $TMP/<nom> et rien d'autre — chaque cas construit son propre état.
mk_root() { # <name> -> imprime le chemin
  local d="$TMP/$1"
  mkdir -p "$d"
  printf '%s' "$d"
}

# Fixture état 3 complète (PROJECT.md, config.json, codebase/ non vide, ROADMAP.md avec en-tête
# de phase, STATE.md avec frontmatter valide) — réutilisée par plusieurs cas de l'état 3.
mk_complete_planning() { # <name> [milestone] [phase] [status]
  local d="$TMP/$1" milestone="${2:-milestone-x}" phase="${3:-7}" status="${4:-shipped}"
  mkdir -p "$d/.planning/codebase"
  printf '# proj\n' > "$d/.planning/PROJECT.md"
  printf '{}' > "$d/.planning/config.json"
  printf 'x' > "$d/.planning/codebase/ARCH.md"
  printf '### Phase 1: x\n' > "$d/.planning/ROADMAP.md"
  printf -- '---\nmilestone: %s\ncurrent_phase: %s\nstatus: %s\n---\n' "$milestone" "$phase" "$status" \
    > "$d/.planning/STATE.md"
  printf '%s' "$d"
}

echo "== test-check-dev-bootstrap =="

# === Cas 1 — État 0 : répertoire vide → stdout vide ET exit 3 (deux conditions distinctes) =====
D="$(mk_root c1)"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "1 état 0 — répertoire vide → silence, exit 3"; else ko "1 état 0 — répertoire vide → silence, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 2 — État 1 : code présent, aucun .planning/ → [onboard] seul, exit 0 ===================
D="$(mk_root c2)"
printf 'print(1)\n' > "$D/main.py"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_onboard=0; case "$out" in *"[onboard]"*) has_onboard=1 ;; esac
leak=0; case "$out" in *"[bootstrap]"*|*"[gsd-engine]"*) leak=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_onboard" -eq 1 ] && [ "$leak" -eq 0 ]; then ok "2 état 1 — code sans .planning/ → [onboard] seul, exit 0"; else ko "2 état 1 — code sans .planning/ → [onboard] seul, exit 0" "rc=$rc out=[$out]"; fi

# === Cas 3 — État 2 : PROJECT.md présent, config.json seul manquant → [bootstrap], exit 0 ======
D="$(mk_root c3)"
mkdir -p "$D/.planning/codebase"
printf '# proj\n' > "$D/.planning/PROJECT.md"
printf 'x' > "$D/.planning/codebase/ARCH.md"
printf '### Phase 1: x\n' > "$D/.planning/ROADMAP.md"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_bootstrap=0; case "$out" in *"[bootstrap]"*"config"*) has_bootstrap=1 ;; esac
leak=0; case "$out" in *"[onboard]"*|*"[gsd-engine]"*) leak=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_bootstrap" -eq 1 ] && [ "$leak" -eq 0 ]; then ok "3 état 2 — config.json seul manquant → [bootstrap], exit 0"; else ko "3 état 2 — config.json seul manquant → [bootstrap], exit 0" "rc=$rc out=[$out]"; fi

# === Cas 4 — État 2, ordre figé (D-03) : config avant codebase avant roadmap, positions =========
D="$(mk_root c4)"
mkdir -p "$D/.planning"
printf '# proj\n' > "$D/.planning/PROJECT.md"
printf 'code\n' > "$D/main.py"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
line1="$(printf '%s\n' "$out" | head -n 1)"
pos_config=$(printf '%s' "$line1" | awk '{print index($0,"config.json")}')
pos_codebase=$(printf '%s' "$line1" | awk '{print index($0,"codebase")}')
pos_roadmap=$(printf '%s' "$line1" | awk '{print index($0,"feuille de route")}')
if [ "$rc" -eq 0 ] && [ "$pos_config" -gt 0 ] && [ "$pos_codebase" -gt "$pos_config" ] && [ "$pos_roadmap" -gt "$pos_codebase" ]; then ok "4 état 2 — ordre figé config < codebase < roadmap"; else ko "4 état 2 — ordre figé config < codebase < roadmap" "rc=$rc pos=[$pos_config,$pos_codebase,$pos_roadmap] out=[$out]"; fi

# === Cas 4bis — Idempotence : deux exécutions consécutives sur la même fixture, sortie identique
out2="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc2=$?
if [ "$rc2" -eq "$rc" ] && [ "$out2" = "$out" ]; then ok "4bis état 2 — deux exécutions consécutives, sortie octet pour octet identique"; else ko "4bis état 2 — deux exécutions consécutives, sortie octet pour octet identique" "rc=$rc rc2=$rc2 out=[$out] out2=[$out2]"; fi

# === Cas 5 — État 2, item codebase conditionné : greenfield (aucun code) → codebase absent ======
D="$(mk_root c5)"
mkdir -p "$D/.planning"
printf '# proj\n' > "$D/.planning/PROJECT.md"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_codebase_item=0; case "$out" in *"codebase"*) has_codebase_item=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_codebase_item" -eq 0 ]; then ok "5 état 2 — greenfield sans code, item codebase absent"; else ko "5 état 2 — greenfield sans code, item codebase absent" "rc=$rc out=[$out]"; fi

# === Cas 6 — État 3 (D-14) : stdout NON VIDE assert POSITIVEMENT ET exit 3, 2 lignes ============
D="$(mk_complete_planning c6 gsd-migration 16 shipped)"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
nlines="$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
if [ "$rc" -eq 3 ] && [ -n "$out" ] && [ "$nlines" = "2" ] && printf '%s' "$out" | grep -q 'gsd-migration' && printf '%s' "$out" | grep -q '16'; then ok "6 état 3 — D-14 : sortie NON VIDE ET exit 3, valeurs du frontmatter reprises"; else ko "6 état 3 — D-14 : sortie NON VIDE ET exit 3, valeurs du frontmatter reprises" "rc=$rc out=[$out]"; fi

# === Cas 7 — État 3 — mutuelle exclusion : ni [onboard] ni [bootstrap] ne fuient ================
leak=0; case "$out" in *"[onboard]"*|*"[bootstrap]"*) leak=1 ;; esac
if [ "$leak" -eq 0 ]; then ok "7 état 3 — mutuelle exclusion, aucun autre marqueur ne fuit"; else ko "7 état 3 — mutuelle exclusion, aucun autre marqueur ne fuit" "out=[$out]"; fi

# === Cas 8 — Soupape D-04 : STATE.md absent → silence total, exit 3 =============================
D="$(mk_complete_planning c8)"
rm -f "$D/.planning/STATE.md"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "8 soupape D-04 — STATE.md absent → silence, exit 3"; else ko "8 soupape D-04 — STATE.md absent → silence, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 9 — Soupape D-04 : ligne 1 n'est pas le délimiteur exact → silence, exit 3 =============
D="$(mk_complete_planning c9)"
printf 'milestone: x\ncurrent_phase: 1\nstatus: shipped\n---\n' > "$D/.planning/STATE.md"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "9 soupape D-04 — ligne 1 non conforme au délimiteur → silence, exit 3"; else ko "9 soupape D-04 — ligne 1 non conforme au délimiteur → silence, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 10 — Soupape D-04 : clé status absente du frontmatter → silence, exit 3 ================
D="$(mk_complete_planning c10)"
printf -- '---\nmilestone: x\ncurrent_phase: 1\n---\n' > "$D/.planning/STATE.md"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "10 soupape D-04 — clé status absente → silence, exit 3"; else ko "10 soupape D-04 — clé status absente → silence, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 11 — Assainissement (T-17-01) : octet de contrôle dans milestone → silence, contenu absent
D="$(mk_complete_planning c11)"
printf -- '---\nmilestone: evil\001inject\ncurrent_phase: 3\nstatus: shipped\n---\n' > "$D/.planning/STATE.md"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
leak=0; case "$out" in *"evil"*) leak=1 ;; esac
if [ "$rc" -eq 3 ] && [ -z "$out" ] && [ "$leak" -eq 0 ]; then ok "11 assainissement — octet de contrôle dans milestone → silence, aucune fuite"; else ko "11 assainissement — octet de contrôle dans milestone → silence, aucune fuite" "rc=$rc out=[$out]"; fi

# === Cas 12 — Assainissement : séquence d'échappement (backslash-n littéral) → silence ==========
D="$(mk_complete_planning c12)"
printf -- '---\nmilestone: evil\\ninject\ncurrent_phase: 3\nstatus: shipped\n---\n' > "$D/.planning/STATE.md"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
leak=0; case "$out" in *"evil"*) leak=1 ;; esac
if [ "$rc" -eq 3 ] && [ -z "$out" ] && [ "$leak" -eq 0 ]; then ok "12 assainissement — séquence d'échappement dans milestone → silence, aucune fuite"; else ko "12 assainissement — séquence d'échappement dans milestone → silence, aucune fuite" "rc=$rc out=[$out]"; fi

# === Cas 13 — Assainissement : valeur > 80 caractères → silence, exit 3 =========================
D="$(mk_complete_planning c13)"
long="$(printf 'x%.0s' $(seq 1 90))"
printf -- '---\nmilestone: %s\ncurrent_phase: 3\nstatus: shipped\n---\n' "$long" > "$D/.planning/STATE.md"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "13 assainissement — valeur > 80 caractères → silence, exit 3"; else ko "13 assainissement — valeur > 80 caractères → silence, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 14 — Élagage (D-02) : node_modules peuplé seul (par ailleurs vide) → toujours état 0 ===
D="$(mk_root c14)"
mkdir -p "$D/node_modules/pkg"
printf 'x' > "$D/node_modules/pkg/index.js"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "14 élagage D-02 — node_modules peuplé seul → état 0, silence"; else ko "14 élagage D-02 — node_modules peuplé seul → état 0, silence" "rc=$rc out=[$out]"; fi

# === Cas 15 — Élagage (D-02) : fichier sous docs/ seul → toujours état 0 =========================
D="$(mk_root c15)"
mkdir -p "$D/docs"
printf 'x' > "$D/docs/readme.md"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "15 élagage D-02 — fichier sous docs/ seul → état 0, silence"; else ko "15 élagage D-02 — fichier sous docs/ seul → état 0, silence" "rc=$rc out=[$out]"; fi

# === Cas 16 — Env VF_BOOTSTRAP_PLANNING_DIR : override change l'état constaté ===================
D="$(mk_root c16-code)"
printf 'code\n' > "$D/main.py"
D2="$(mk_complete_planning c16-planning gsd-migration 9 shipped)"
out="$(VF_BOOTSTRAP_PLANNING_DIR="$D2/.planning" bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -n "$out" ] && printf '%s' "$out" | grep -q 'gsd-engine'; then ok "16 env VF_BOOTSTRAP_PLANNING_DIR — override pointe vers un état 3 hors --path"; else ko "16 env VF_BOOTSTRAP_PLANNING_DIR — override pointe vers un état 3 hors --path" "rc=$rc out=[$out]"; fi

# === Cas 17 — Arguments : --hook + --quiet ensemble → exit 64, stdout vide ======================
errfile="$TMP/c17.err"
out="$(bash "$SCRIPT" --hook --quiet 2>"$errfile")"; rc=$?
err="$(cat "$errfile")"
if [ "$rc" -eq 64 ] && [ -z "$out" ] && [ -n "$err" ]; then ok "17 --hook + --quiet ensemble → exit 64, stdout vide, stderr non vide"; else ko "17 --hook + --quiet ensemble → exit 64, stdout vide, stderr non vide" "rc=$rc out=[$out] err=[$err]"; fi

# === Cas 18 — Arguments : argument inconnu → exit 64 ============================================
bash "$SCRIPT" --nope >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "18 argument inconnu → exit 64"; else ko "18 argument inconnu → exit 64" "rc=$rc"; fi

# === Cas 19 — Arguments : --path sans valeur → exit 64 ==========================================
bash "$SCRIPT" --path >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "19 --path sans valeur → exit 64"; else ko "19 --path sans valeur → exit 64" "rc=$rc"; fi

# === Cas 20 — Arguments : --help → exit 0, sortie non vide ======================================
out="$(bash "$SCRIPT" --help 2>/dev/null)"; rc=$?
if [ "$rc" -eq 0 ] && [ -n "$out" ]; then ok "20 --help → exit 0, sortie non vide"; else ko "20 --help → exit 0, sortie non vide" "rc=$rc out=[$out]"; fi

# === Cas 21 — Lecture seule (D-15) : empreinte find identique avant/après exécution =============
D="$(mk_complete_planning c21 gsd-migration 5 shipped)"
before="$(find "$D" | LC_ALL=C sort)"
bash "$SCRIPT" --path "$D" >/dev/null 2>&1
after="$(find "$D" | LC_ALL=C sort)"
if [ "$before" = "$after" ]; then ok "21 lecture seule D-15 — empreinte find identique avant/après"; else ko "21 lecture seule D-15 — empreinte find identique avant/après" "before=[$before] after=[$after]"; fi

# === Cas 22 — bash -n passe sur le script (syntaxe) =============================================
if bash -n "$SCRIPT" 2>/dev/null; then ok "22 bash -n passe sur check-dev-bootstrap.sh"; else ko "22 bash -n passe sur check-dev-bootstrap.sh" "syntax error"; fi

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
