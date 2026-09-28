#!/usr/bin/env bash
# test-check-method-budget.sh — Suite de check-method-budget.sh (budgets de méthode, v2.67.0).
#
#   S1/S2 — STATE sous et au-dessus du budget ; S3 — STATE de workstream compté aussi
#   S4 — budget surchargé par l'environnement ; S5 — pas de .planning : non applicable, rend 0
#   S6 — workstreams/ illisible : NON VÉRIFIABLE dit, rc 2 sous --strict (jamais un 0 de complaisance)
#   W1 — worktrees sous le budget ; W2 — dépassement ; W3 — RANGEABLE (branche intégrée)
#   W4 — worktree neuf (sans commit) jamais dit RANGEABLE ; W5 — ORPHELIN (dossier supprimé)
#   W6 — lab multi-dépôts : worktree frère compté UNE fois, pas comme un dépôt de plus
#   X1 — sans --strict un dépassement rend 0 ; X2 — avec --strict il rend 1 ; X3 — arguments
#        et budgets invalides rendent 64 ; X4 — lecture seule : rien n'est supprimé
#   Q5 — anti-vert-à-vide
#
# Convention du dossier : set -uo pipefail sans -e, mktemp -d + trap EXIT, fixtures jetables.

set -uo pipefail
cd "$(dirname "$0")/../.."
CHECK="$(pwd)/scripts/check-method-budget.sh"

# Chemin réel (/var -> /private/var sous macOS), comme git le rend. Jamais `cd "$(mktemp -d)"` en
# une fois : si mktemp échoue, cd "" reste sur place et le trap effacerait le dossier courant.
TMP_RAW="$(mktemp -d)" || exit 1
[ -n "$TMP_RAW" ] && [ -d "$TMP_RAW" ] || exit 1
WORK_DIR="$(cd "$TMP_RAW" && pwd -P)" || exit 1
trap 'rm -rf "$WORK_DIR"' EXIT
unset VF_STATE_BUDGET_KB VF_WORKTREE_BUDGET

PASS=0; FAIL=0
assert()     { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): $3"; echo "     obtenu:  $2"; FAIL=$((FAIL+1)); fi; }
refute()     { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     inattendu: $3"; echo "     obtenu:  $2"; FAIL=$((FAIL+1)); fi; }
assert_rc()  { if [ "$2" -eq "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (rc $2 ≠ $3)"; FAIL=$((FAIL+1)); fi; }

G() { git -c user.name=t -c user.email=t@t -c init.defaultBranch=main "$@" >/dev/null 2>&1; }
mk_repo() { # <dir> : dépôt avec un commit sur main
  mkdir -p "$1" && G -C "$1" init && echo a > "$1/a" && G -C "$1" add a && G -C "$1" commit -m init
}
fill() { # <fichier> <Ko>
  mkdir -p "$(dirname "$1")"; head -c $(( $2 * 1024 )) /dev/zero | tr '\0' 'x' > "$1"
}

echo "=== S — budget du fichier d'état ==="
LAB="$WORK_DIR/lab"; mk_repo "$LAB"
fill "$LAB/.planning/STATE.md" 4
OUT="$(bash "$CHECK" --root "$LAB")"; RC=$?
assert "S1 — STATE de 4 Ko dans le budget de 8" "$OUT" "STATE ok"
assert_rc "S1 — rend 0" "$RC" 0
fill "$LAB/.planning/STATE.md" 20
OUT="$(bash "$CHECK" --root "$LAB")"
assert "S2 — STATE de 20 Ko : dépassement signalé" "$OUT" "STATE DÉPASSÉ"
assert "S2 — le constat dit quoi faire" "$OUT" ".planning/archives/state/"
fill "$LAB/.planning/STATE.md" 2
fill "$LAB/.planning/workstreams/ws1/STATE.md" 12
OUT="$(bash "$CHECK" --root "$LAB")"
assert "S3 — STATE de workstream compté" "$OUT" "workstreams/ws1/STATE.md fait 12 Ko"
OUT="$(VF_STATE_BUDGET_KB=16 bash "$CHECK" --root "$LAB")"
refute "S4 — budget relevé à 16 Ko par l'environnement : plus de dépassement" "$OUT" "DÉPASSÉ"
mkdir -p "$LAB/.planning"; rm -rf "$LAB/.planning/workstreams"; echo x > "$LAB/.planning/workstreams"
OUT="$(bash "$CHECK" --root "$LAB" 2>/dev/null)"; RC=$?
assert "S6 — workstreams/ illisible (fichier) : non vérifiable, dit" "$OUT" "NON VÉRIFIABLE"
assert_rc "S6 — sans --strict : rend 0" "$RC" 0
bash "$CHECK" --root "$LAB" --strict >/dev/null 2>&1; assert_rc "S6 — avec --strict : rend 2, jamais 0" "$?" 2
rm -rf "$LAB/.planning"
OUT="$(bash "$CHECK" --root "$LAB")"; RC=$?
assert "S5 — pas de .planning : non applicable" "$OUT" "non applicable"
assert_rc "S5 — rend 0" "$RC" 0

echo ""
echo "=== W — budget des worktrees ==="
G -C "$LAB" worktree add "$LAB/.claude/worktrees/w1" -b w1
OUT="$(bash "$CHECK" --root "$LAB")"
assert "W1 — un worktree : dans le budget" "$OUT" "en a 1 actifs (budget 3)"
for n in 2 3 4; do G -C "$LAB" worktree add "$LAB/.claude/worktrees/w$n" -b "w$n"; done
OUT="$(bash "$CHECK" --root "$LAB")"
assert "W2 — quatre worktrees : dépassement" "$OUT" "worktrees DÉPASSÉ"
echo b > "$LAB/.claude/worktrees/w2/b"; G -C "$LAB/.claude/worktrees/w2" add b; G -C "$LAB/.claude/worktrees/w2" commit -m b
G -C "$LAB" merge --ff-only w2
echo c > "$LAB/.claude/worktrees/w3/c"; G -C "$LAB/.claude/worktrees/w3" add c; G -C "$LAB/.claude/worktrees/w3" commit -m c
OUT="$(bash "$CHECK" --root "$LAB")"
assert "W3 — branche w2 intégrée dans main : RANGEABLE" "$OUT" "RANGEABLE : $LAB/.claude/worktrees/w2 [w2]"
refute "W3 — branche w3 non intégrée : jamais RANGEABLE" "$OUT" "RANGEABLE : $LAB/.claude/worktrees/w3"
refute "W4 — worktree neuf sans commit : jamais RANGEABLE" "$OUT" "RANGEABLE : $LAB/.claude/worktrees/w4"
assert "W4 — worktree neuf signalé comme tel" "$OUT" "w4 [w4] neuf, aucun commit"
rm -rf "$LAB/.claude/worktrees/w1"
OUT="$(bash "$CHECK" --root "$LAB")"
assert "W5 — dossier supprimé : ORPHELIN" "$OUT" "ORPHELIN : $LAB/.claude/worktrees/w1"
assert "W5 — l'orphelin ne compte pas dans les actifs" "$OUT" "en a 3 actifs"
G -C "$LAB" worktree add "$LAB/.claude/worktrees/w5" -b w5  # de nouveau 4 actifs, pour la série X
[ -d "$LAB/.claude/worktrees/w2" ] && X4=present || X4=absent
assert "X4 — lecture seule : le worktree rangeable est toujours là" "$X4" "present"

MULTI="$WORK_DIR/multi"; mk_repo "$MULTI/front"; mk_repo "$MULTI/back"
G -C "$MULTI/front" worktree add "$MULTI/front-wt-a" -b a
G -C "$MULTI/front" worktree add "$MULTI/front-wt-b" -b b
OUT="$(bash "$CHECK" --root "$MULTI")"
N_FRONT=$(printf '%s\n' "$OUT" | grep -c 'worktrees ok : .*front')
assert_rc "W6 — lab multi-dépôts : le dépôt front compté une seule fois" "$N_FRONT" 1
assert "W6 — ses deux worktrees frères sont bien comptés" "$OUT" "front en a 2 actifs"
assert "W6 — le dépôt back est vu" "$OUT" "back en a 0 actifs"

echo ""
echo "=== X — codes de sortie ==="
bash "$CHECK" --root "$LAB" >/dev/null; assert_rc "X1 — dépassement sans --strict : 0" "$?" 0
bash "$CHECK" --root "$LAB" --strict >/dev/null; assert_rc "X2 — dépassement avec --strict : 1" "$?" 1
bash "$CHECK" --root "$MULTI" --strict >/dev/null; assert_rc "X2b — dans les budgets avec --strict : 0" "$?" 0
bash "$CHECK" --inconnu >/dev/null 2>&1; assert_rc "X3a — argument inconnu : 64" "$?" 64
VF_WORKTREE_BUDGET=abc bash "$CHECK" --root "$LAB" >/dev/null 2>&1; assert_rc "X3b — budget non numérique : 64" "$?" 64
bash "$CHECK" --root "$WORK_DIR/absent" >/dev/null 2>&1; assert_rc "X3c — racine introuvable : 64" "$?" 64
OUT="$(bash "$CHECK" --root "$LAB" --quiet)"
refute "X5 — --quiet tait les constats conformes" "$OUT" "actif : $LAB/.claude/worktrees/w3"
assert "X5 — --quiet garde les dépassements" "$OUT" "DÉPASSÉ"

echo ""
echo "=== Q5 — anti-vert-à-vide ==="
TOTAL=$((PASS+FAIL))
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
if [ "$TOTAL" -eq 0 ]; then
  echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"
  exit 1
fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
