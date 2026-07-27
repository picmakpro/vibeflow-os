#!/usr/bin/env bash
# test-dag.sh — Suite de tests pour dag.sh (ADR-053, Pattern B)
#
# T1 init + add (ready/blocked selon deps) · T2 mark done promeut la frontière
# T3 reopen = ré-entrée (dépendants transitifs remis blocked) · T4 collision d'id remappée
# T5 mark id inconnu / statut invalide → erreur · T6 status compteurs
# T9 tree = rendu arbre (ids + connecteurs) · T10 tree borne les cycles (pas de hang)
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
# run_bounded — exécute une commande sous une limite de temps portable (macOS n'a pas `timeout`).
# stdout est renvoyé ; le code retour est celui de la commande, ou ≠0 si un watchdog a dû la tuer
# (⇒ un `tree` qui bouclerait à l'infini ferait échouer le test au lieu de figer la suite).
run_bounded() {
  local out; out="$(mktemp)"
  "$@" >"$out" 2>/dev/null &
  local pid=$!
  ( sleep 5; kill -9 "$pid" 2>/dev/null ) &
  local watcher=$!
  wait "$pid" 2>/dev/null; local rc=$?
  kill "$watcher" 2>/dev/null
  cat "$out"; rm -f "$out"
  return "$rc"
}

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

echo "=== T9 — tree rend l'arbre (ids + connecteur └─) ==="
T="$WORK_DIR/t.dag.json"; "$SCRIPT" init --file="$T" >/dev/null
"$SCRIPT" add --file="$T" --id=E1 --step=cadrage >/dev/null
"$SCRIPT" add --file="$T" --id=E2 --step=dev --deps=E1 >/dev/null
"$SCRIPT" add --file="$T" --id=E3 --step=revue --deps=E2 >/dev/null
"$SCRIPT" mark --file="$T" --id=E1 --status=done >/dev/null
"$SCRIPT" mark --file="$T" --id=E2 --status=done >/dev/null
tree_out=$("$SCRIPT" tree --file="$T")
assert "T9.1 — E1 présent"            "$tree_out" 'E1'
assert "T9.2 — E2 présent"            "$tree_out" 'E2'
assert "T9.3 — E3 présent"            "$tree_out" 'E3'
assert "T9.4 — connecteur └─ présent" "$tree_out" '└─'

echo "=== T10 — tree borne les cycles (pas de hang, marqueur cycle) ==="
CY="$WORK_DIR/cy.dag.json"; "$SCRIPT" init --file="$CY" >/dev/null
"$SCRIPT" add --file="$CY" --id=A --step=a >/dev/null
"$SCRIPT" add --file="$CY" --id=B --step=b --deps=A >/dev/null
# force un cycle A→B / B→A (add refuse les deps inconnues → on l'injecte via python, comme T8)
python3 -c "import json; d=json.load(open('$CY')); [n.__setitem__('deps',['B']) for n in d['nodes'] if n['id']=='A']; json.dump(d,open('$CY','w'))"
tree_out=$(run_bounded "$SCRIPT" tree --file="$CY"); rc=$?
assert_exit "T10.1 — tree termine (exit 0, pas de hang)" "$rc" 0
assert "T10.2 — cycle signalé" "$tree_out" '(cycle)'

echo "=== T11 — tree rend les composants orphelins (cycle isolé + vraie racine) ==="
# ROOT (racine réelle) coexiste avec un sous-graphe 100% cyclique C1⇄C2 (aucun sans-deps).
# Sans la passe orpheline, C1/C2 disparaîtraient silencieusement de l'arbre.
OR="$WORK_DIR/orphan.dag.json"; "$SCRIPT" init --file="$OR" >/dev/null
"$SCRIPT" add --file="$OR" --id=ROOT --step=r  >/dev/null
"$SCRIPT" add --file="$OR" --id=C1   --step=c1 >/dev/null
"$SCRIPT" add --file="$OR" --id=C2   --step=c2 --deps=C1 >/dev/null
# force le cycle C1→C2 / C2→C1 (comme T8/T10) → C1 n'est plus une racine
python3 -c "import json; d=json.load(open('$OR')); [n.__setitem__('deps',['C2']) for n in d['nodes'] if n['id']=='C1']; json.dump(d,open('$OR','w'))"
tree_out=$(run_bounded "$SCRIPT" tree --file="$OR"); rc=$?
assert_exit "T11.1 — tree termine (exit 0)" "$rc" 0
assert "T11.2 — racine ROOT rendue"          "$tree_out" 'ROOT'
assert "T11.3 — orphelin C1 rendu"           "$tree_out" 'C1'
assert "T11.4 — orphelin C2 rendu"           "$tree_out" 'C2'

echo "=== T12 — DAG hétérogène cross-métier (dev + design, Phase 15) ==="
# Le kernel est métier-agnostique : un nœud design (id à « : », convention craft:<écran>) doit
# coexister dans un DAG dev sans traitement spécial, et sans être confondu avec le mécanisme de
# remap déterministe sur collision (« id::stage », double « : »). Deux juges read-only cross-
# métier (critique design + revue code) doivent pouvoir sortir dans la MÊME frontière `ready`.
M="$WORK_DIR/mixte.dag.json"; "$SCRIPT" init --file="$M" >/dev/null
"$SCRIPT" add --file="$M" --id=discuss-5 --step="cadrage étape 5" >/dev/null
"$SCRIPT" add --file="$M" --id=plan-5    --step="plan étape 5" --deps=discuss-5 >/dev/null

craft_out=$("$SCRIPT" add --file="$M" --id=craft:ecran-home --step="craft design écran" --deps=plan-5)
assert "T12.1 — id craft:ecran-home NON remappé (un « : » simple ≠ la syntaxe de remap « :: »)" "$craft_out" '"added": "craft:ecran-home"'
assert "T12.2 — remapped:false sur ce premier add (pas de collision)"                            "$craft_out" '"remapped": false'

"$SCRIPT" add --file="$M" --id=exec-5              --step="implémentation"  --deps=craft:ecran-home,plan-5 >/dev/null
"$SCRIPT" add --file="$M" --id=critique:ecran-home --step="critique design" --deps=exec-5 >/dev/null
"$SCRIPT" add --file="$M" --id=revue-5             --step="revue code"     --deps=exec-5 >/dev/null

"$SCRIPT" mark --file="$M" --id=discuss-5 --status=done >/dev/null
"$SCRIPT" mark --file="$M" --id=plan-5    --status=done >/dev/null
r1=$("$SCRIPT" ready --file="$M")
assert "T12.3 — le nœud design craft:ecran-home entre dans la frontière d'un DAG dev (kernel métier-agnostique)" "$r1" 'craft:ecran-home'

"$SCRIPT" mark --file="$M" --id=craft:ecran-home --status=done >/dev/null
"$SCRIPT" mark --file="$M" --id=exec-5           --status=done >/dev/null
r2=$("$SCRIPT" ready --file="$M")
assert "T12.4 — juge design (critique:ecran-home) présent dans la frontière" "$r2" 'critique:ecran-home'
assert "T12.5 — revue code (revue-5) présente DANS LA MÊME frontière"        "$r2" 'revue-5'

# Contraste : une VRAIE collision (même id réajouté) déclenche bien le remap déterministe
# id::stage — preuve que T12.1/T12.2 (fresh id à « : » simple, non remappé) discriminent
# effectivement l'absence de collision de la présence d'une collision réelle.
collide_out=$("$SCRIPT" add --file="$M" --id=craft:ecran-home --stage=v2 --step="craft v2")
assert "T12.6 — collision réelle (même id relancé) → remapped:true" "$collide_out" '"remapped": true'
assert "T12.7 — collision réelle → suffixe :: déterministe"         "$collide_out" '"added": "craft:ecran-home::v2"'

echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
