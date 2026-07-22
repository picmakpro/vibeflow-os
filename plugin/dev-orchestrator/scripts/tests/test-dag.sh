#!/usr/bin/env bash
# test-dag.sh — Suite de tests pour dag.sh (ADR-053, Pattern B)
#
# T1 init + add (ready/blocked selon deps) · T2 mark done promeut la frontière
# T3 reopen = ré-entrée (dépendants transitifs remis blocked) · T4 collision d'id remappée
# T5 mark id inconnu / statut invalide → erreur · T6 status compteurs
#
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
cd "$(dirname "$0")/../.."
SCRIPT="$(pwd)/scripts/dag.sh"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
F="$WORK_DIR/m.dag.json"

PASS=0; FAIL=0
assert()     { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: $3"; echo "     obtenu:  $2"; FAIL=$((FAIL+1)); fi; }
assert_not() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (a trouvé « $3 »)"; FAIL=$((FAIL+1)); fi; }
assert_exit(){ if [ "$2" -eq "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (exit $2 ≠ $3)"; FAIL=$((FAIL+1)); fi; }

echo "=== T1 — init + add (ready/blocked) ==="
"$SCRIPT" init --file="$F" >/dev/null
assert "T1.1 — A sans deps → ready"      "$("$SCRIPT" add --file="$F" --id=A --step=cadrage)" '"status": "ready"'
assert "T1.2 — B dep A → blocked"        "$("$SCRIPT" add --file="$F" --id=B --step=code --deps=A)" '"status": "blocked"'
"$SCRIPT" add --file="$F" --id=C --step=revue --deps=B >/dev/null
assert "T1.3 — frontière = [A] seul"     "$("$SCRIPT" ready --file="$F")" '"ready": ['$'\n''    "A"'

echo "=== T2 — mark done promeut la frontière ==="
assert "T2.1 — A done → B devient ready"  "$("$SCRIPT" mark --file="$F" --id=A --status=done)" '"B"'
assert "T2.2 — B done → C devient ready"  "$("$SCRIPT" mark --file="$F" --id=B --status=done)" '"C"'

echo "=== T3 — reopen = ré-entrée ==="
out=$("$SCRIPT" reopen --file="$F" --id=A)
assert "T3.1 — dépendants transitifs reset (B,C)" "$out" '"dependents_reset": ['$'\n''    "B",'$'\n''    "C"'
assert "T3.2 — A redevient ready"                 "$out" '"ready": ['$'\n''    "A"'
assert "T3.3 — B/C repassés blocked"              "$("$SCRIPT" status --file="$F")" '"blocked": 2'

echo "=== T4 — collision d'id remappée ==="
out=$("$SCRIPT" add --file="$F" --id=A --stage=hotfix)
assert "T4.1 — remapped true" "$out" '"remapped": true'
assert "T4.2 — id::stage"     "$out" '"added": "A::hotfix"'

echo "=== T5 — erreurs ==="
o1=$("$SCRIPT" mark --file="$F" --id=NOPE --status=done); r1=$?
assert "T5.1 — mark id inconnu → error" "$o1" '"error": "unknown-id"'
assert_exit "T5.2 — exit 1" "$r1" 1
o2=$("$SCRIPT" mark --file="$F" --id=C --status=bogus); r2=$?
assert "T5.3 — statut invalide → error" "$o2" '"error": "invalid-status"'
assert_exit "T5.4 — exit 1" "$r2" 1

echo "=== T6 — status compteurs ==="
assert "T6.1 — total 4 noeuds" "$("$SCRIPT" status --file="$F")" '"total": 4'

echo "=== T7 — dépendance vers un id inexistant refusée (M1) ==="
G="$WORK_DIR/g.dag.json"; "$SCRIPT" init --file="$G" >/dev/null
out=$("$SCRIPT" add --file="$G" --id=X --step=x --deps=NEXISTEPAS); rc=$?
assert "T7.1 — unknown-dep" "$out" '"error": "unknown-dep"'
assert_exit "T7.2 — exit 1" "$rc" 1

echo "=== T8 — reopen sur cycle exclut le nœud cible (L1) ==="
C="$WORK_DIR/c.dag.json"; "$SCRIPT" init --file="$C" >/dev/null
"$SCRIPT" add --file="$C" --id=A --step=a >/dev/null
"$SCRIPT" add --file="$C" --id=B --step=b --deps=A >/dev/null
# introduit un cycle A→B et B→A en éditant la dep de A (add valide, on force le cycle via python)
python3 -c "import json; d=json.load(open('$C')); [n.__setitem__('deps',['B']) for n in d['nodes'] if n['id']=='A']; json.dump(d,open('$C','w'))"
out=$("$SCRIPT" reopen --file="$C" --id=A)
assert_not "T8.1 — A absent de ses propres dépendants" "$out" '"dependents_reset": ['$'\n''    "A"'
assert "T8.2 — B bien listé" "$out" '"B"'

echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
