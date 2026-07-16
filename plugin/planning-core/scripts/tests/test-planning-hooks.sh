#!/usr/bin/env bash
# test-planning-hooks.sh — Tests des hooks planning ADR-050 :
#   planning-context.sh (SessionStart, digest index-first)
#   planning-task-context.sh (UserPromptSubmit, STATE du compartiment ciblé)
#   guard-planning-updated.sh (Stop, blocage si planning pas à jour + anti-piège)
set -u

SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
PC="$SCRIPTS/planning-context.sh"
PT="$SCRIPTS/planning-task-context.sh"
G="$SCRIPTS/guard-planning-updated.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
ok()  { echo "  ✅ $1"; PASS=$((PASS+1)); }
ko()  { echo "  ❌ $1"; FAIL=$((FAIL+1)); }
exit_is() { # $1 input $2 expected $3 label [$4 env]
  local code; printf '%s' "$1" | env ${4:-} bash "$G" >/dev/null 2>&1; code=$?
  [ "$code" = "$2" ] && ok "$3 (exit=$code)" || ko "$3 (exit=$code, attendu $2)"
}
has()  { echo "$1" | grep -q "$2" && ok "$3" || ko "$3"; }
hasnt(){ echo "$1" | grep -q "$2" && ko "$3" || ok "$3"; }

echo "=== guard-planning-updated.sh (Stop) ==="
R="$WORK/repo"; mkdir -p "$R/.planning"; cd "$R"
git init -q; git config user.email t@t.co; git config user.name t
printf 'last_updated: 2026-07-16\n# STATE\n' > .planning/STATE.md
echo base > deliverable.md; git add -A; git commit -qm init
echo modif >> deliverable.md
exit_is '{"stop_hook_active": false}' 2 "S1 livrable changé + planning non maj → BLOQUE"
echo maj >> .planning/STATE.md
exit_is '{"stop_hook_active": false}' 0 "S2 livrable + planning maj → autorise"
git add -A; git commit -qm s2; echo x >> deliverable.md
exit_is '{"stop_hook_active": true}' 0 "S3 anti-boucle (stop_hook_active) → autorise"
touch .planning/.session-noop
exit_is '{"stop_hook_active": false}' 0 "S4 échappatoire marqueur → autorise"
[ -f .planning/.session-noop ] && ko "S4b marqueur consommé" || ok "S4b marqueur consommé (one-shot)"
exit_is '{"stop_hook_active": false}' 0 "S5 mode warn → autorise" "VF_PLANNING_STOP=warn"
exit_is '{"stop_hook_active": false}' 0 "S6 mode off → autorise" "VF_PLANNING_STOP=off"
git add -A; git commit -qm s4; mkdir -p .claude/memory; echo r >> .claude/memory/DECISIONS.md
exit_is '{"stop_hook_active": false}' 0 "S7 seulement .claude/ (méta) → autorise"
git add -A; git commit -qm s7
exit_is '{"stop_hook_active": false}' 0 "S8 rien changé → autorise"
mkdir -p "$WORK/nogit/.planning"; cd "$WORK/nogit"; echo x > d.md
exit_is '{"stop_hook_active": false}' 0 "S9 hors repo git → autorise (pas de trappe)"

echo "=== planning-context.sh (SessionStart) ==="
M="$WORK/mono"; mkdir -p "$M/.planning"; cd "$M"
printf 'last_updated: 2026-07-16\n# STATE\n## En cours\n- tache A\n' > .planning/STATE.md
out=$(bash "$PC"); has "$out" "extrait borné" "C1 mono : header extrait STATE"; has "$out" "tache A" "C1 mono : contenu injecté"
MU="$WORK/multi"; mkdir -p "$MU/.planning" "$MU/projects/acquisition/.planning"; cd "$MU"
printf '# INDEX\n| acquisition | actif |\n' > .planning/INDEX.md
printf 'last_updated: 2026-07-16\n# acq\n- séquence CTO\n' > projects/acquisition/.planning/STATE.md
out=$(bash "$PC"); has "$out" "compartiments" "C2 multi : header INDEX"; has "$out" "acquisition" "C2 multi : INDEX injecté"
hasnt "$out" "séquence CTO" "C2 multi : ne charge PAS les STATE des compartiments (anti-saturation)"
N="$WORK/none"; mkdir -p "$N"; cd "$N"
out=$(bash "$PC"); [ -z "$out" ] && ok "C3 pas de .planning → silencieux" || ko "C3 devrait être vide"

echo "=== planning-task-context.sh (UserPromptSubmit) ==="
cd "$MU"
out=$(printf '{"prompt":"aide sur la séquence acquisition"}' | bash "$PT")
has "$out" "acquisition" "T1 compartiment ciblé détecté"; has "$out" "séquence CTO" "T1 STATE du compartiment injecté"
out=$(printf '{"prompt":"quelle heure"}' | bash "$PT"); [ -z "$out" ] && ok "T2 aucun match → silencieux" || ko "T2 devrait être vide"
cd "$M"; out=$(printf '{"prompt":"tache A"}' | bash "$PT"); [ -z "$out" ] && ok "T3 lab mono → silencieux" || ko "T3 devrait être vide"

echo ""
echo "== BILAN : $PASS PASS / $FAIL FAIL =="
[ "$FAIL" -eq 0 ]
