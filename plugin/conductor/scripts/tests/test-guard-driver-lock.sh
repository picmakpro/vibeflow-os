#!/usr/bin/env bash
# test-guard-driver-lock.sh — Suite de tests pour guard-driver-lock.sh (LOCK-02/03/05, D-32-05).
#
# Tâche 1 (tracer) — tranche verticale commit/checkout, niveau définitif :
#   A1/A2/A4 — commit d'une session tierce sous lock vivant : deny, motif porteur, détenteur passe
#   A5 (BL-1) — chaînage par SAUT DE LIGNE : le 2e segment n'est pas invisible
#   A6 (BL-2) — options globales de `git` (-C, -c) : le sous-verbe est reconnu malgré elles
#   B1/B4     — checkout d'une session tierce : deny, détenteur passe
#   R1/R2/R3  — lock absent/périmé/pré-Phase-32 (sans session_ids) : allow inconditionnel
#   P0/P1     — préfiltre pur-bash : zéro spawn d'interprète sur payload non concerné
#
# Tâche 2 — surface complète (S1-S10), voie Write/Edit (C1-C5), limite assumée (L1).
#
# Tâche 3 — QUAL-01, les QUATRE issues distinctes (jamais trois) :
#   Q1 PASS (déjà couvert par A4/B4/C3) · Q2 DENY (déjà couvert par A1/B1/C1)
#   Q3/Q3b/Q3c — payload IMPARSABLE ou atypique, ou meta illisible → fail-open SILENCIEUX
#     (code 0 ET stdout STRICTEMENT VIDE, les deux assertés — jamais un allow qui parle)
#   Q4 — interprète INDISPONIBLE → fail-open BRUYANT (code 17, stdout vide, stderr préfixé,
#     marqueur de santé écrit) — DISTINCT du silencieux, jamais confondu avec lui
#   Q5 — anti-vert-à-vide : le compteur d'assertions exécutées est vérifié non nul
#
# Convention du dossier : set -uo pipefail sans -e, mktemp -d + trap EXIT, VF_* pour rediriger le
# système sous test, préflights séparés des assertions métier.

set -uo pipefail
cd "$(dirname "$0")/../.."
GUARD="$(pwd)/scripts/guard-driver-lock.sh"
DRIVER="$(pwd)/scripts/driver-lock.sh"
BASH_BIN="${BASH:-bash}"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
LOCK="$WORK_DIR/DRIVER.lock"
export VF_DRIVER_LOCK="$LOCK"

PASS=0; FAIL=0
assert()      { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): $3"; echo "     obtenu:  $2"; FAIL=$((FAIL+1)); fi; }
assert_empty() { if [ -z "$2" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (sortie non vide)"; echo "     obtenu:  $2"; FAIL=$((FAIL+1)); fi; }
assert_exit()  { if [ "$2" -eq "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (exit $2 ≠ $3)"; FAIL=$((FAIL+1)); fi; }
num_eq()       { if [ "$2" -eq "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (=$2, attendu $3)"; FAIL=$((FAIL+1)); fi; }
preflight()    { if [ "$2" -eq 0 ]; then echo "  ✅ PREFLIGHT OK — $1"; PASS=$((PASS+1)); return 0; else echo "  ❌ PREFLIGHT FAIL — $1 (fixture cassé, pas de verdict métier)"; FAIL=$((FAIL+1)); return 1; fi; }

# Payloads construits par un interprète (échappement JSON fiable), jamais par concaténation
# de chaînes à la main.
mk_bash() { # cmd session_id cwd
  python3 -c '
import json, sys
print(json.dumps({"tool_name": "Bash", "tool_input": {"command": sys.argv[1]},
                   "session_id": sys.argv[2], "cwd": sys.argv[3]}))' "$1" "$2" "$3"
}

mk_write() { # file_path content session_id
  python3 -c '
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]},
                   "session_id": sys.argv[3]}))' "$1" "$2" "$3"
}

mk_edit() { # file_path old new session_id
  python3 -c '
import json, sys
print(json.dumps({"tool_name": "Edit", "tool_input": {"file_path": sys.argv[1], "old_string": sys.argv[2], "new_string": sys.argv[3]},
                   "session_id": sys.argv[4]}))' "$1" "$2" "$3" "$4"
}

mk_other() { # tool_name session_id
  python3 -c '
import json, sys
print(json.dumps({"tool_name": sys.argv[1], "tool_input": {"file_path": "x"}, "session_id": sys.argv[2]}))' "$1" "$2"
}

run_guard() { # payload
  printf '%s' "$1" | VF_DRIVER_LOCK="$LOCK" "$BASH_BIN" "$GUARD" 2>/dev/null
}

# Antidate un lock existant AU-DELÀ du TTL — même patron que age_stale() de test-driver-lock.sh,
# reproduit ici (pas de harness partagé entre suites du dossier, convention TESTING.md).
age_stale() {
  local lock="$1" old; old=$(( $(date +%s) - 999999 ))
  if [ -L "$lock" ]; then
    local gen; gen="$(readlink "$lock")"
    [ -f "$lock/meta" ] && sed -i.bak "s/^heartbeat_epoch=.*/heartbeat_epoch=$old/" "$lock/meta" 2>/dev/null
    rm -f "$lock/meta.bak" 2>/dev/null
    touch -t 202001010000 "$(dirname "$lock")/$gen" 2>/dev/null || true
  elif [ -f "$lock/meta" ]; then
    sed -i.bak "s/^heartbeat_epoch=.*/heartbeat_epoch=$old/" "$lock/meta" && rm -f "$lock/meta.bak"
  else
    touch -t 202001010000 "$lock" 2>/dev/null || true
  fi
}

# Retire la ligne "session_ids=" du meta — fixture de rétrocompatibilité (R3), même patron que
# meta_drop_key() de test-driver-lock.sh.
meta_drop_key() {
  local lock="$1" key="$2" meta
  if [ -L "$lock" ]; then meta="$(dirname "$lock")/$(readlink "$lock")/meta"; else meta="$lock/meta"; fi
  [ -f "$meta" ] && sed -i.bak "/^${key}=/d" "$meta" 2>/dev/null && rm -f "${meta}.bak"
}

meta_of() { # rend le chemin du meta du lock courant
  [ -L "$LOCK" ] && echo "$(dirname "$LOCK")/$(readlink "$LOCK")/meta" || echo "$LOCK/meta"
}

echo "=== Fixture principale : lock vivant, mission-X / sess-holder ==="
rm -rf "$LOCK"
CLAUDE_CODE_SESSION_ID=sess-holder "$DRIVER" acquire --owner=mission-X --step=t32 >/dev/null
ST="$("$DRIVER" status)"
case "$ST" in *'"present": true'*) preflight "fixture: lock présent" 0 ;; *) preflight "fixture: lock présent" 1 ;; esac
case "$ST" in *'"stale": false'*) preflight "fixture: lock non périmé" 0 ;; *) preflight "fixture: lock non périmé" 1 ;; esac
case "$ST" in *'sess-holder'*) preflight "fixture: session_ids peuplé (sess-holder)" 0 ;; *) preflight "fixture: session_ids peuplé (sess-holder)" 1 ;; esac
[ -x "$GUARD" ] || chmod +x "$GUARD" 2>/dev/null
case "-$(bash -n "$GUARD" 2>&1)" in -) preflight "fixture: guard syntaxiquement valide" 0 ;; *) preflight "fixture: guard syntaxiquement valide" 1 ;; esac

echo ""
echo "=== A1/A2/A4 — commit d'une session tierce sous lock vivant ==="
PAY_A1=$(mk_bash 'git add F && git commit -m "hors mandat"' sess-intrus .)
OUT_A1="$(run_guard "$PAY_A1")"
assert "A1 — deny (permissionDecision)" "$OUT_A1" '"permissionDecision": "deny"'
assert "A2a — motif porte owner mission-X" "$OUT_A1" "mission-X"
assert "A2b — motif porte la commande exacte de reclaim" "$OUT_A1" "reclaim --owner=mission-X"
PAY_A4=$(mk_bash 'git add F && git commit -m "hors mandat"' sess-holder .)
OUT_A4="$(run_guard "$PAY_A4")"
assert_empty "A4 — DISCRIMINANCE : le détenteur (sess-holder) passe, sortie vide (ne JAMAIS retirer)" "$OUT_A4"

echo ""
echo "=== A5 (BL-1) — chaînage par SAUT DE LIGNE : le commit n'est pas le 1er segment ==="
PAY_A5=$(mk_bash "$(printf 'git add F\ngit commit -m "hors mandat"')" sess-intrus .)
OUT_A5="$(run_guard "$PAY_A5")"
assert "A5 — deny malgré le saut de ligne avant le commit" "$OUT_A5" '"permissionDecision": "deny"'

echo ""
echo "=== A6 (BL-2) — options globales de git avant le sous-verbe ==="
PAY_A6a=$(mk_bash 'git -C /tmp commit -m x' sess-intrus .)
OUT_A6a="$(run_guard "$PAY_A6a")"
assert "A6a — deny malgré 'git -C /tmp'" "$OUT_A6a" '"permissionDecision": "deny"'
PAY_A6b=$(mk_bash 'git -c core.hooksPath=/dev/null commit -m x' sess-intrus .)
OUT_A6b="$(run_guard "$PAY_A6b")"
assert "A6b — deny malgré 'git -c core.hooksPath=/dev/null'" "$OUT_A6b" '"permissionDecision": "deny"'

echo ""
echo "=== B1/B4 — checkout d'une session tierce ==="
PAY_B1=$(mk_bash 'git checkout -b autre-branche' sess-intrus .)
OUT_B1="$(run_guard "$PAY_B1")"
assert "B1 — deny" "$OUT_B1" '"permissionDecision": "deny"'
PAY_B4=$(mk_bash 'git checkout -b autre-branche' sess-holder .)
OUT_B4="$(run_guard "$PAY_B4")"
assert_empty "B4 — DISCRIMINANCE : le détenteur passe (ne JAMAIS retirer)" "$OUT_B4"

echo ""
echo "=== R1 — lock ABSENT : allow inconditionnel ==="
rm -rf "$LOCK"
OUT_R1="$(run_guard "$(mk_bash 'git commit -m x' sess-intrus .)")"
assert_empty "R1 — sortie vide, aucun lock" "$OUT_R1"

echo ""
echo "=== R2 — lock PÉRIMÉ : traité comme absent ==="
CLAUDE_CODE_SESSION_ID=sess-holder "$DRIVER" acquire --owner=mission-X --step=t32 >/dev/null
age_stale "$LOCK"
OUT_R2="$(run_guard "$(mk_bash 'git commit -m x' sess-intrus .)")"
assert_empty "R2 — sortie vide, lock périmé (zombie ne bloque jamais)" "$OUT_R2"

echo ""
echo "=== R3 — lock frais SANS session_ids (rétrocompat pré-Phase-32) ==="
rm -rf "$LOCK"
CLAUDE_CODE_SESSION_ID=sess-holder "$DRIVER" acquire --owner=mission-X --step=t32 >/dev/null
meta_drop_key "$LOCK" session_ids
_r3_n=$(grep -c '^session_ids=' "$(meta_of)")
num_eq "R3.0 — (SE-7) fixture: la ligne session_ids= est réellement absente" "$_r3_n" 0
OUT_R3="$(run_guard "$(mk_bash 'git commit -m x' sess-intrus .)")"
assert_empty "R3 — sortie vide, meta sans identité (règle 2)" "$OUT_R3"

echo ""
echo "=== P0 — SE-1 : sonde d'existence AVANT tout spawn (lock absent, PATH sans interprète) ==="
rm -rf "$LOCK"
P0_BIN="$WORK_DIR/p0-bin"
mkdir -p "$P0_BIN"
for t in cat dirname basename sed grep mkdir rm mv date readlink stat; do
  p="$(command -v "$t" 2>/dev/null)" && ln -sf "$p" "$P0_BIN/$t" 2>/dev/null
done
_p0_py=0
command -v python3 >/dev/null 2>&1 && _p0_py=1
if PATH="$P0_BIN" command -v python3 >/dev/null 2>&1 || PATH="$P0_BIN" command -v python >/dev/null 2>&1; then
  preflight "P0 fixture: PATH réellement privé d'interprète" 1
else
  preflight "P0 fixture: PATH réellement privé d'interprète" 0
  PAY_P0=$(mk_bash 'git commit -m x' sess-intrus .)
  OUT_P0="$(printf '%s' "$PAY_P0" | VF_DRIVER_LOCK="$LOCK" PATH="$P0_BIN" "$BASH_BIN" "$GUARD" 2>/dev/null)"; RC_P0=$?
  assert_exit "P0 — exit 0 sans lock, même sans interprète disponible" "$RC_P0" 0
  assert_empty "P0 — sortie vide sans lock, même sans interprète disponible" "$OUT_P0"
fi

echo ""
echo "=== P1 — préfiltre : commande sans verbe concerné (lock présent, PATH sans interprète) ==="
CLAUDE_CODE_SESSION_ID=sess-holder "$DRIVER" acquire --owner=mission-X --step=t32 >/dev/null
PAY_P1=$(mk_bash 'ls -la' sess-intrus .)
OUT_P1="$(printf '%s' "$PAY_P1" | VF_DRIVER_LOCK="$LOCK" PATH="$P0_BIN" "$BASH_BIN" "$GUARD" 2>/dev/null)"; RC_P1=$?
assert_exit "P1 — exit 0, commande sans verbe concerné" "$RC_P1" 0
assert_empty "P1 — sortie vide, commande sans verbe concerné" "$OUT_P1"

"$DRIVER" release --owner=mission-X >/dev/null 2>&1

echo ""
echo "=== S1 — chaque famille de la surface A, session tierce, lock vivant : deny ==="
rm -rf "$LOCK"
CLAUDE_CODE_SESSION_ID=sess-holder "$DRIVER" acquire --owner=mission-X --step=s1 >/dev/null
s1_cmds=(
  "git merge autre-branche"
  "git rebase main"
  "git cherry-pick abc123"
  "git revert abc123"
  "git reset --hard HEAD~1"
  "git clean -fd"
  "git push origin main"
  "git tag v9.9.9"
  "git branch -D autre-branche"
  "git stash pop"
  "git worktree remove ../ailleurs"
  "gh pr create --title x"
  "gh release create v1.0.0"
)
for c in "${s1_cmds[@]}"; do
  OUT="$(run_guard "$(mk_bash "$c" sess-intrus .)")"
  assert "S1 — '$c' → deny" "$OUT" '"permissionDecision": "deny"'
done

echo ""
echo "=== S2 (EXEMPTION NOMMÉE) — 'git worktree add' reste ouvert, même sous lock tiers ==="
OUT_S2="$(run_guard "$(mk_bash 'git worktree add ../ailleurs -b b' sess-intrus .)")"
assert_empty "S2 — worktree add jamais bloqué (porte de sortie du lock)" "$OUT_S2"

echo ""
echo "=== S3 — position de commande : un motif de recherche n'est pas une commande ==="
OUT_S3="$(run_guard "$(mk_bash 'grep -n "git commit" fichier.md' sess-intrus .)")"
assert_empty "S3 — 'grep -n \"git commit\" …' → allow (verbe en position ARGUMENT, quoté)" "$OUT_S3"
OUT_S3B="$(run_guard "$(mk_bash 'echo git commit -m x' sess-intrus .)")"
assert_empty "S3b — 'echo git commit -m x' → allow (git en position ARGUMENT d'echo, pas en position de commande)" "$OUT_S3B"

echo ""
echo "=== S4 — document en ligne citant un commit : texte, pas une commande ==="
HEREDOC_CMD=$(printf 'cat <<EOF\ngit commit -m x\nEOF')
OUT_S4="$(run_guard "$(mk_bash "$HEREDOC_CMD" sess-intrus .)")"
assert_empty "S4 — heredoc citant 'git commit' → allow (contenu = texte)" "$OUT_S4"

echo ""
echo "=== S5 — wrappers transparents (sudo, env) ==="
OUT_S5a="$(run_guard "$(mk_bash 'sudo git commit -m x' sess-intrus .)")"
assert "S5a — 'sudo git commit' → deny (wrapper transparent)" "$OUT_S5a" '"permissionDecision": "deny"'
OUT_S5b="$(run_guard "$(mk_bash 'env FOO=1 git commit -m x' sess-intrus .)")"
assert "S5b — 'env FOO=1 git commit' → deny (wrapper transparent)" "$OUT_S5b" '"permissionDecision": "deny"'

echo ""
echo "=== S6 — chaînage classique (&&) ==="
OUT_S6="$(run_guard "$(mk_bash 'ls && git commit -m x' sess-intrus .)")"
assert "S6 — 'ls && git commit' → deny" "$OUT_S6" '"permissionDecision": "deny"'

echo ""
echo "=== S7/S8 — ÉCHAPPATOIRE (marqueur littéral / variable d'environnement) ==="
OUT_S7="$(run_guard "$(mk_bash 'git commit -m x  # vibeflow:allow-lock-override' sess-intrus .)")"
assert_empty "S7 — marqueur littéral dans la commande → allow" "$OUT_S7"
OUT_S8="$(printf '%s' "$(mk_bash 'git commit -m x' sess-intrus .)" | VF_DRIVER_LOCK="$LOCK" VF_DRIVER_LOCK_OVERRIDE=1 "$BASH_BIN" "$GUARD" 2>/dev/null)"
assert_empty "S8 — variable d'environnement d'exception → allow" "$OUT_S8"

echo ""
echo "=== S9 (BL-7, EXEMPTION NOMMÉE) — issue de secours rebase/merge/cherry-pick ==="
for c in "git rebase --abort" "git rebase --continue" "git merge --abort" "git cherry-pick --abort"; do
  OUT="$(run_guard "$(mk_bash "$c" sess-intrus .)")"
  assert_empty "S9 — '$c' → allow (issue de secours, jamais fermée)" "$OUT"
done

echo ""
echo "=== S10 (contrepoint de S9, ne jamais retirer) — rebase SANS option de sortie reste refusé ==="
OUT_S10="$(run_guard "$(mk_bash 'git rebase -i main' sess-intrus .)")"
assert "S10 — 'git rebase -i main' → deny (seule l'OPTION de sortie est exemptée)" "$OUT_S10" '"permissionDecision": "deny"'

echo ""
echo "=== C1/C2/C3 — Write|Edit sous .planning/, session tierce vs détenteur ==="
OUT_C1="$(run_guard "$(mk_write .planning/STATE.md 'contenu' sess-intrus)")"
assert "C1 — Write sous .planning/ (session tierce) → deny" "$OUT_C1" '"permissionDecision": "deny"'
OUT_C2="$(run_guard "$(mk_edit .planning/STATE.md 'ancien' 'nouveau' sess-intrus)")"
assert "C2 — Edit sous .planning/ (session tierce) → deny" "$OUT_C2" '"permissionDecision": "deny"'
OUT_C3W="$(run_guard "$(mk_write .planning/STATE.md 'contenu' sess-holder)")"
assert_empty "C3 — Write sous .planning/ (détenteur) → allow (discriminance)" "$OUT_C3W"
OUT_C3E="$(run_guard "$(mk_edit .planning/STATE.md 'ancien' 'nouveau' sess-holder)")"
assert_empty "C3 — Edit sous .planning/ (détenteur) → allow (discriminance)" "$OUT_C3E"

echo ""
echo "=== C4 — Write HORS .planning/ : jamais bloqué, même sous lock tiers ==="
OUT_C4="$(run_guard "$(mk_write src/foo.ts 'contenu' sess-intrus)")"
assert_empty "C4 — Write hors .planning/ → allow (D-32-B borne le périmètre)" "$OUT_C4"

echo ""
echo "=== C5 — outil hors périmètre (ni Bash, ni Write, ni Edit) ==="
OUT_C5="$(run_guard "$(mk_other Read sess-intrus)")"
assert_empty "C5 — outil 'Read' → allow (hors périmètre du guard)" "$OUT_C5"

echo ""
echo "=== L1 (LIMITE ASSUMÉE, HORS DE PORTÉE ASSUMÉE — rouge documenté, non corrigé) ==="
OUT_L1="$(run_guard "$(mk_bash 'bash ./scripts/release.sh' sess-intrus .)")"
assert_empty "L1 — script du dépôt qui commite en interne → allow (HORS DE PORTÉE ASSUMÉE, documenté en en-tête, pas corrigé)" "$OUT_L1"

echo ""
echo "=== Q3/Q3b/Q3c — fail-open SILENCIEUX (rc 0 ET stdout STRICTEMENT VIDE, les deux assertés) ==="
# Q3 : entrée qui n'est pas du JSON, mais qui contient une sous-chaîne du préfiltre (sinon le
# préfiltre sort avant d'atteindre le chemin testé, et le cas ne mesurerait rien).
Q3_RAW='ceci n est pas du json mais ca contient le mot commit quelque part'
Q3_OUT="$(printf '%s' "$Q3_RAW" | VF_DRIVER_LOCK="$LOCK" "$BASH_BIN" "$GUARD" 2>/dev/null)"; Q3_RC=$?
assert_exit "Q3 — payload imparsable → exit 0" "$Q3_RC" 0
assert_empty "Q3 — payload imparsable → stdout STRICTEMENT VIDE (silence = contrat de FLUX)" "$Q3_OUT"

# Q3b : JSON valide mais structurellement atypique (command absent).
Q3B_RAW='{"tool_name": "Bash", "tool_input": {}, "session_id": "sess-intrus"}'
Q3B_OUT="$(printf '%s' "$Q3B_RAW" | VF_DRIVER_LOCK="$LOCK" "$BASH_BIN" "$GUARD" 2>/dev/null)"; Q3B_RC=$?
assert_exit "Q3b — command absent → exit 0" "$Q3B_RC" 0
assert_empty "Q3b — command absent → stdout vide" "$Q3B_OUT"
# Variante : command d'un autre type (nombre au lieu d'une chaîne).
Q3B2_RAW='{"tool_name": "Bash", "tool_input": {"command": 42}, "session_id": "sess-intrus"}'
Q3B2_OUT="$(printf '%s' "$Q3B2_RAW" | VF_DRIVER_LOCK="$LOCK" "$BASH_BIN" "$GUARD" 2>/dev/null)"; Q3B2_RC=$?
assert_exit "Q3b2 — command d'un autre type → exit 0" "$Q3B2_RC" 0
assert_empty "Q3b2 — command d'un autre type → stdout vide" "$Q3B2_OUT"

# Q3c : meta du lock présent MAIS illisible (permissions retirées) — allow silencieux, jamais un
# refus sur erreur interne.
rm -rf "$LOCK"
CLAUDE_CODE_SESSION_ID=sess-holder "$DRIVER" acquire --owner=mission-X --step=q3c >/dev/null
Q3C_META="$(meta_of)"
chmod 000 "$Q3C_META" 2>/dev/null
Q3C_OUT="$(run_guard "$(mk_bash 'git commit -m x' sess-intrus .)")"; Q3C_RC=$?
chmod 644 "$Q3C_META" 2>/dev/null
assert_exit "Q3c — meta illisible → exit 0" "$Q3C_RC" 0
assert_empty "Q3c — meta illisible → stdout vide (jamais un deny sur erreur interne)" "$Q3C_OUT"
"$DRIVER" release --owner=mission-X >/dev/null 2>&1

echo ""
echo "=== Q4 — fail-open BRUYANT (issue DISTINCTE du silencieux) : interprète INDISPONIBLE ==="
rm -rf "$LOCK"
CLAUDE_CODE_SESSION_ID=sess-holder "$DRIVER" acquire --owner=mission-X --step=q4 >/dev/null
Q4_BIN="$WORK_DIR/q4-bin"
mkdir -p "$Q4_BIN"
for t in cat dirname basename sed grep mkdir rm mv date readlink stat; do
  p="$(command -v "$t" 2>/dev/null)" && ln -sf "$p" "$Q4_BIN/$t" 2>/dev/null
done
Q4_PREFLIGHT_OK=1
for t in cat dirname mkdir mv rm date; do [ -x "$Q4_BIN/$t" ] || Q4_PREFLIGHT_OK=0; done
if PATH="$Q4_BIN" command -v python3 >/dev/null 2>&1 || PATH="$Q4_BIN" command -v python >/dev/null 2>&1; then Q4_PREFLIGHT_OK=0; fi
if [ "$Q4_PREFLIGHT_OK" -eq 1 ]; then preflight "Q4 fixture: outils présents, aucun interprète joignable" 0; else preflight "Q4 fixture: outils présents, aucun interprète joignable" 1; fi
if [ "$Q4_PREFLIGHT_OK" -eq 1 ]; then
  Q4_HEALTH="$WORK_DIR/q4-health"
  PAY_Q4=$(mk_bash 'git commit -m x' sess-intrus .)
  Q4_OUT="$(printf '%s' "$PAY_Q4" | VF_DRIVER_LOCK="$LOCK" VF_GUARD_HEALTH_DIR="$Q4_HEALTH" PATH="$Q4_BIN" "$BASH_BIN" "$GUARD" 2>"$WORK_DIR/q4.err")"; Q4_RC=$?
  assert_exit "Q4 — interprète indisponible → code de garde 17" "$Q4_RC" 17
  assert_empty "Q4 — interprète indisponible → stdout vide" "$Q4_OUT"
  assert "Q4 — diagnostic préfixé sur stderr" "$(cat "$WORK_DIR/q4.err" 2>/dev/null)" "guard-driver-lock.sh"
  [ -f "$Q4_HEALTH/guard-driver-lock.sh.marker" ] && Q4_MARKER=present || Q4_MARKER=absent
  assert "Q4 — marqueur de santé écrit ($Q4_HEALTH/guard-driver-lock.sh.marker)" "$Q4_MARKER" "present"
fi
"$DRIVER" release --owner=mission-X >/dev/null 2>&1

echo ""
echo "=== Q5 — anti-vert-à-vide : le compteur d'assertions exécutées n'est jamais zéro ==="
Q5_TOTAL=$((PASS+FAIL))
num_eq "Q5 — au moins une assertion exécutée avant l'épilogue (=$Q5_TOTAL, jamais 0)" "$([ "$Q5_TOTAL" -gt 0 ] && echo 1 || echo 0)" 1

echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
# (Q5) Garde anti-vert-à-vide STRUCTURELLE, dans l'épilogue lui-même — pas seulement un cas de
# test mid-suite qui pourrait être neutralisé en même temps que le reste : si AUCUNE assertion
# n'a tourné (PASS+FAIL == 0), le résultat n'est jamais un succès, quel que soit FAIL.
if [ "$((PASS+FAIL))" -eq 0 ]; then
  echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"
  exit 1
fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
