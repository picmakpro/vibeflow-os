#!/usr/bin/env bash
# test-dag.sh — Suite de tests pour dag.sh (ADR-053, Pattern B)
#
# T1 init + add (ready/blocked selon deps) · T2 mark done promeut la frontière
# T3 reopen = ré-entrée (dépendants transitifs remis blocked) · T4 collision d'id remappée
# T5 mark id inconnu / statut invalide → erreur · T6 status compteurs
# T9 tree = rendu arbre (ids + connecteurs) · T10 tree borne les cycles (pas de hang)
# T25 ready : stages recouvrement -> etages distincts · T26 stages disjoint -> meme etage
# T27 ready/count inchanges en presence de stages + determinisme de ready
# T28 stages sur DAG sans cle scope (P-02) · T29 CLI amont VRAIMENT introuvable -> stages:null
# T30 frontiere vide -> stages=[] sans sous-processus
# T31 CLI resolue qui ECHOUE (returncode != 0) -> stages:null, jamais [] · T32 node absent mais
# gsd-tools .cjs resolu -> stages:null (branche node, distincte de T29) · T33 non-regression :
# gsd-tools.cjs TRACKE au CWD jamais resolu ni execute (vecteur RCE retire, dag.sh D-07)
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

echo "=== T13 — --scope declare et persiste le perimetre du noeud (D-13) ==="
SF="$WORK_DIR/scope.dag.json"; "$SCRIPT" init --file="$SF" >/dev/null
out=$("$SCRIPT" add --file="$SF" --id=A --step=x --scope="src/a/**,src/b.ts")
assert "T13.1 — add avec --scope reste ready (sortie inchangee)" "$out" '"status": "ready"'
scope_a=$(python3 -c "import json; print(json.load(open('$SF'))['nodes'][0]['scope'])")
assert "T13.2 — scope A = 2 entrees exactes"                     "$scope_a" "['src/a/**', 'src/b.ts']"

out=$("$SCRIPT" add --file="$SF" --id=B --step=y)
assert "T13.3 — add sans --scope reste ready (sortie inchangee)" "$out" '"status": "ready"'
scope_b=$(python3 -c "import json; print(json.load(open('$SF'))['nodes'][1]['scope'])")
assert "T13.4 — B sans flag → scope = []"                        "$scope_b" '[]'

"$SCRIPT" add --file="$SF" --id=C --step=z --scope="  src/a/**  ,  , src/b.ts " >/dev/null
scope_c=$(python3 -c "import json; print(json.load(open('$SF'))['nodes'][2]['scope'])")
assert "T13.5 — espaces rognes + entree vide ignoree (meme regle que --deps)" "$scope_c" "['src/a/**', 'src/b.ts']"

echo "=== T14 — retro-compatibilite : DAG sans cle scope (ecrit par la version precedente, P-02) ==="
RC="$WORK_DIR/retro.dag.json"
cat > "$RC" <<'JSONEOF'
{
  "nodes": [
    {"id": "A", "step": "a", "stage": "", "deps": [], "status": "done"},
    {"id": "B", "step": "b", "stage": "", "deps": ["A"], "status": "ready"},
    {"id": "revue-1", "step": "revue", "stage": "", "deps": ["B"], "status": "blocked"}
  ]
}
JSONEOF
ready_out=$("$SCRIPT" ready --file="$RC"); rc1=$?
assert_exit "T14.1 — ready sur DAG sans scope (exit 0)"   "$rc1" 0
assert      "T14.2 — ready rend B"                         "$ready_out" '"B"'
status_out=$("$SCRIPT" status --file="$RC"); rc2=$?
assert_exit "T14.3 — status sur DAG sans scope (exit 0)"  "$rc2" 0
mark_out=$("$SCRIPT" mark --file="$RC" --id=B --status=done); rc3=$?
assert_exit "T14.4 — mark sur DAG sans scope (exit 0)"    "$rc3" 0
reopen_out=$("$SCRIPT" reopen --file="$RC" --id=A); rc4=$?
assert_exit "T14.5 — reopen sur DAG sans scope (exit 0)"  "$rc4" 0
tree_out=$(run_bounded "$SCRIPT" tree --file="$RC"); rc5=$?
assert_exit "T14.6 — tree sur DAG sans scope (exit 0)"    "$rc5" 0
assert      "T14.7 — tree rend quand meme A"               "$tree_out" 'A'

echo "=== T15 — reopen force review_regime=full transitivement sur revue/join, jamais sur exec (D-14) ==="
RG="$WORK_DIR/regime.dag.json"; "$SCRIPT" init --file="$RG" >/dev/null
"$SCRIPT" add --file="$RG" --id=exec-1  --step=x >/dev/null
"$SCRIPT" add --file="$RG" --id=revue-1 --step=r --deps=exec-1  >/dev/null
"$SCRIPT" add --file="$RG" --id=join-1  --step=j --deps=revue-1 >/dev/null
"$SCRIPT" mark --file="$RG" --id=exec-1  --status=done >/dev/null
"$SCRIPT" mark --file="$RG" --id=revue-1 --status=done >/dev/null
"$SCRIPT" mark --file="$RG" --id=join-1  --status=done >/dev/null
"$SCRIPT" reopen --file="$RG" --id=exec-1 >/dev/null
regime_field() { python3 -c "import json; n=[x for x in json.load(open('$1'))['nodes'] if x['id']=='$2'][0]; print(n.get('review_regime'))"; }
assert "T15.1 — revue-1 rouvert transitivement -> review_regime=full" "$(regime_field "$RG" revue-1)" "full"
assert "T15.2 — join-1 rouvert transitivement -> review_regime=full"  "$(regime_field "$RG" join-1)"  "full"
assert "T15.3 — exec-1 (cible, pas un noeud de revue) -> pas de champ" "$(regime_field "$RG" exec-1)" "None"

echo "=== T16 — reopen direct : les 4 formes d'identifiant reconnues (D-14) ==="
RD="$WORK_DIR/regime-direct.dag.json"; "$SCRIPT" init --file="$RD" >/dev/null
"$SCRIPT" add --file="$RD" --id="revue:ecran-home" --step=r >/dev/null
"$SCRIPT" add --file="$RD" --id="join-x"            --step=j >/dev/null
"$SCRIPT" add --file="$RD" --id="join:y"            --step=j >/dev/null
"$SCRIPT" add --file="$RD" --id="join"              --step=j >/dev/null
"$SCRIPT" mark --file="$RD" --id="revue:ecran-home" --status=done >/dev/null
"$SCRIPT" mark --file="$RD" --id="join-x"            --status=done >/dev/null
"$SCRIPT" mark --file="$RD" --id="join:y"            --status=done >/dev/null
"$SCRIPT" mark --file="$RD" --id="join"              --status=done >/dev/null
"$SCRIPT" reopen --file="$RD" --id="revue:ecran-home" >/dev/null
"$SCRIPT" reopen --file="$RD" --id="join-x"            >/dev/null
"$SCRIPT" reopen --file="$RD" --id="join:y"            >/dev/null
"$SCRIPT" reopen --file="$RD" --id="join"              >/dev/null
assert "T16.1 — revue:ecran-home (prefixe deux-points) -> full" "$(regime_field "$RD" "revue:ecran-home")" "full"
assert "T16.2 — join-x (prefixe tiret) -> full"                 "$(regime_field "$RD" "join-x")"            "full"
assert "T16.3 — join:y (prefixe deux-points) -> full"           "$(regime_field "$RD" "join:y")"            "full"
assert "T16.4 — join (identifiant exact) -> full"                "$(regime_field "$RD" "join")"              "full"

echo "=== T17 — selecteur ferme : rejette les faux positifs, jamais un test de sous-chaine (D-14) ==="
FP="$WORK_DIR/regime-faux-positif.dag.json"; "$SCRIPT" init --file="$FP" >/dev/null
"$SCRIPT" add --file="$FP" --id="refonte-joint-bas" --step=x >/dev/null
"$SCRIPT" add --file="$FP" --id="exec-2"            --step=x >/dev/null
"$SCRIPT" add --file="$FP" --id="plan-2"            --step=x >/dev/null
"$SCRIPT" mark --file="$FP" --id="refonte-joint-bas" --status=done >/dev/null
"$SCRIPT" mark --file="$FP" --id="exec-2"            --status=done >/dev/null
"$SCRIPT" mark --file="$FP" --id="plan-2"            --status=done >/dev/null
"$SCRIPT" reopen --file="$FP" --id="refonte-joint-bas" >/dev/null
"$SCRIPT" reopen --file="$FP" --id="exec-2" >/dev/null
"$SCRIPT" reopen --file="$FP" --id="exec-2" >/dev/null   # deuxieme reopen : toujours aucun champ
"$SCRIPT" reopen --file="$FP" --id="plan-2" >/dev/null
assert "T17.1 — refonte-joint-bas (« join » en milieu de chaine) -> pas de champ" "$(regime_field "$FP" "refonte-joint-bas")" "None"
assert "T17.2 — exec-2 rouvert 2x -> jamais de champ"                             "$(regime_field "$FP" "exec-2")"            "None"
assert "T17.3 — plan-2 rouvert -> jamais de champ"                                "$(regime_field "$FP" "plan-2")"            "None"

echo "=== T18 — idempotence : un second reopen ne duplique pas la cle (D-14) ==="
ID_F="$WORK_DIR/regime-idempotence.dag.json"; "$SCRIPT" init --file="$ID_F" >/dev/null
"$SCRIPT" add --file="$ID_F" --id="revue-9" --step=r >/dev/null
"$SCRIPT" mark --file="$ID_F" --id="revue-9" --status=done >/dev/null
"$SCRIPT" reopen --file="$ID_F" --id="revue-9" >/dev/null
"$SCRIPT" mark --file="$ID_F" --id="revue-9" --status=done >/dev/null
"$SCRIPT" reopen --file="$ID_F" --id="revue-9" >/dev/null
key_count=$(grep -c '"review_regime"' "$ID_F")
assert "T18.1 — une seule occurrence de la cle apres 2 reopens" "$key_count" "1"
assert "T18.2 — valeur toujours full apres 2 reopens"           "$(regime_field "$ID_F" "revue-9")" "full"

echo "=== T19 — sortie de reopen etendue : liste des ids passes en regime plein (D-14) ==="
out19=$("$SCRIPT" reopen --file="$RD" --id="join")
assert "T19.1 — cles existantes preservees (reopened)" "$out19" '"reopened": "join"'
assert "T19.2 — review_regime_full liste bien l'id passe en regime plein" "$out19" '"review_regime_full": ['$'\n''    "join"'

echo "=== T20 — status expose les perimetres GELES : noeuds non termines a scope non vide (D-15 §2) ==="
FZ="$WORK_DIR/frozen.dag.json"; "$SCRIPT" init --file="$FZ" >/dev/null
"$SCRIPT" add --file="$FZ" --id=exec-1 --step=x --scope="src/a/**" >/dev/null
"$SCRIPT" add --file="$FZ" --id=exec-2 --step=y --scope="src/b/**" --deps=exec-1 >/dev/null
"$SCRIPT" add --file="$FZ" --id=exec-3 --step=z --deps=exec-2 >/dev/null
"$SCRIPT" mark --file="$FZ" --id=exec-1 --status=done >/dev/null
"$SCRIPT" mark --file="$FZ" --id=exec-2 --status=running >/dev/null
SO="$WORK_DIR/status_out.json"
"$SCRIPT" status --file="$FZ" > "$SO"
frozen_ids=$(python3 -c "import json; print([f['id'] for f in json.load(open('$SO'))['frozen']])")
assert "T20.1 — exactement 1 entree gelee : exec-2 (exec-1 done exclu, exec-3 scope vide exclu)" "$frozen_ids" "['exec-2']"
frozen_entry=$(python3 -c "import json; f=json.load(open('$SO'))['frozen'][0]; print(f['status'], f['scope'])")
assert "T20.2 — l'entree porte son statut (running) et son scope"                                "$frozen_entry" "running ['src/b/**']"

echo "=== T21 — aucun perimetre declare : la cle frozen est presente et vide, jamais absente ==="
EMPTY="$WORK_DIR/empty-scope.dag.json"; "$SCRIPT" init --file="$EMPTY" >/dev/null
"$SCRIPT" add --file="$EMPTY" --id=x --step=x >/dev/null
SE="$WORK_DIR/status_empty.json"
"$SCRIPT" status --file="$EMPTY" > "$SE"
frozen_empty=$(python3 -c "import json; print(json.load(open('$SE'))['frozen'])")
assert "T21.1 — cle frozen presente et vide (consommateur ne distingue jamais absent de vide)" "$frozen_empty" "[]"

echo "=== T22 — retro-compatibilite status : DAG sans cle scope du tout (version precedente, P-02) ==="
RC2="$WORK_DIR/retro-status.dag.json"
cat > "$RC2" <<'JSONEOF'
{
  "nodes": [
    {"id": "A", "step": "a", "stage": "", "deps": [], "status": "running"},
    {"id": "B", "step": "b", "stage": "", "deps": ["A"], "status": "blocked"}
  ]
}
JSONEOF
status_rc=$("$SCRIPT" status --file="$RC2"); rc=$?
assert_exit "T22.1 — status sur DAG sans cle scope (exit 0)" "$rc" 0
SR2="$WORK_DIR/status_retro.json"; echo "$status_rc" > "$SR2"
frozen_retro=$(python3 -c "import json; print(json.load(open('$SR2'))['frozen'])")
assert "T22.2 — frozen = [] sans cle scope sur les noeuds (P-02)" "$frozen_retro" "[]"

echo "=== T23 — aucune regression de cle existante sur status (total/counts/ready) ==="
assert "T23.1 — total preserve"  "$(cat "$SO")" '"total": 3'
assert "T23.2 — counts preserve" "$(cat "$SO")" '"counts"'
assert "T23.3 — ready preserve"  "$(cat "$SO")" '"ready"'

echo "=== T24 — determinisme : deux appels consecutifs -> sortie octet pour octet identique ==="
S1="$WORK_DIR/s1.json"; S2="$WORK_DIR/s2.json"
"$SCRIPT" status --file="$FZ" > "$S1"
"$SCRIPT" status --file="$FZ" > "$S2"
if diff -q "$S1" "$S2" >/dev/null; then diffres="identical"; else diffres="differ"; fi
assert "T24.1 — deux invocations successives produisent une sortie identique" "$diffres" "identical"

echo "=== T25 — deux noeuds ready declarant le meme chemin dans scope[] sortent dans deux etages distincts ==="
F25="$WORK_DIR/t25.dag.json"; "$SCRIPT" init --file="$F25" >/dev/null
"$SCRIPT" add --file="$F25" --id=p1 --step=p1 --scope=src/shared.ts >/dev/null
"$SCRIPT" add --file="$F25" --id=p2 --step=p2 --scope=src/shared.ts >/dev/null
out25=$("$SCRIPT" ready --file="$F25")
same_stage25=$(printf '%s' "$out25" | python3 -c "
import json, sys
st = json.load(sys.stdin)['stages']
print(any(('p1' in s) and ('p2' in s) for s in st))
")
assert      "T25.1 — p1 et p2 (meme scope) ne partagent jamais le meme etage" "$same_stage25" "False"
count25=$(printf '%s' "$out25" | python3 -c "import json,sys; print(len(json.load(sys.stdin)['stages']))")
assert      "T25.2 — exactement 2 etages produits"                           "$count25"      "2"

echo "=== T26 — deux noeuds ready a scope disjoint sortent dans un seul et meme etage ==="
F26="$WORK_DIR/t26.dag.json"; "$SCRIPT" init --file="$F26" >/dev/null
"$SCRIPT" add --file="$F26" --id=q1 --step=q1 --scope=src/a.ts >/dev/null
"$SCRIPT" add --file="$F26" --id=q2 --step=q2 --scope=src/b.ts >/dev/null
out26=$("$SCRIPT" ready --file="$F26")
same_stage26=$(printf '%s' "$out26" | python3 -c "
import json, sys
st = json.load(sys.stdin)['stages']
print(any(('q1' in s) and ('q2' in s) for s in st))
")
assert      "T26.1 — q1 et q2 (scope disjoint) partagent le meme etage" "$same_stage26" "True"
count26=$(printf '%s' "$out26" | python3 -c "import json,sys; print(len(json.load(sys.stdin)['stages']))")
assert      "T26.2 — un seul etage produit"                             "$count26"      "1"

echo "=== T27 — en presence de stages, ready/count gardent exactement leurs valeurs d'avant ce plan + determinisme ==="
assert "T27.1 — ready = [p1, p2] (2 ids exacts, tableau plat inchange)" "$out25" '"ready": ['$'\n''    "p1",'$'\n''    "p2"'
assert "T27.2 — count = 2 (inchange)"                                  "$out25" '"count": 2'
R1="$WORK_DIR/ready1.json"; R2="$WORK_DIR/ready2.json"
"$SCRIPT" ready --file="$F25" > "$R1"
"$SCRIPT" ready --file="$F25" > "$R2"
if diff -q "$R1" "$R2" >/dev/null; then readydiff="identical"; else readydiff="differ"; fi
assert "T27.3 — deux invocations successives de ready produisent une sortie identique (sur le modele de T24)" "$readydiff" "identical"

echo "=== T28 — DAG ecrit sans cle scope du tout (version anterieure au champ, P-02) produit un stages calcule, non nul ==="
F28="$WORK_DIR/t28.dag.json"
cat > "$F28" <<'JSONEOF'
{
  "nodes": [
    {"id": "r1", "step": "r1", "stage": "", "deps": [], "status": "ready"},
    {"id": "r2", "step": "r2", "stage": "", "deps": [], "status": "ready"}
  ]
}
JSONEOF
out28=$("$SCRIPT" ready --file="$F28"); rc28=$?
assert_exit "T28.1 — ready sur DAG sans scope (exit 0)"                                   "$rc28" 0
stages28=$(printf '%s' "$out28" | python3 -c "import json,sys; print(json.load(sys.stdin)['stages'])")
assert_not  "T28.2 — stages calcule, non nul (pas de crash sur l'absence de cle scope)"    "$stages28" "None"
assert      "T28.3 — r1 et r2 coexistent (scope absent = aucun recouvrement declare, P-02)" "$stages28" "'r1', 'r2'"

echo "=== T29 — CLI amont VRAIMENT introuvable (PATH + GSD_TOOLS + CLAUDE_CONFIG_DIR + HOME tous neutralises) : stages:null, ready/count intacts, exit 0 ==="
F29="$WORK_DIR/t29.dag.json"; "$SCRIPT" init --file="$F29" >/dev/null
"$SCRIPT" add --file="$F29" --id=n1 --step=n1 --scope=src/x.ts >/dev/null
"$SCRIPT" add --file="$F29" --id=n2 --step=n2 --scope=src/x.ts >/dev/null
# Restreint le PATH a un repertoire ne contenant QUE python3 (dag.sh en depend deja pour tourner
# du tout) — ni `gsd-tools` ni `node` n'y sont resolvables. Invoque via le binaire bash resolu
# AVANT la restriction : un PATH tronque passe a `"$SCRIPT"` directement ferait echouer la
# resolution du shebang `#!/usr/bin/env bash` lui-meme (env ne trouverait pas bash), ce qui
# testerait un tout autre echec que celui vise ici.
BASH_BIN="$(command -v bash)"
RESTRICTED_BIN="$WORK_DIR/restricted-bin"; mkdir -p "$RESTRICTED_BIN"
ln -s "$(command -v python3)" "$RESTRICTED_BIN/python3"
# HOME/CLAUDE_CONFIG_DIR EGALEMENT neutralises (M2, revue) : sur un poste ou
# ~/.claude/gsd-core/bin/gsd-tools.cjs existe reellement, la cascade le RESOUT sans eux — et
# c'est alors l'absence de `node` (PATH restreint) qui produit stages:null, pas « CLI amont
# introuvable » comme ce test le pretend. Sans neutraliser aussi ces deux variables, ce test
# exercerait une branche differente sur une machine sans cette installation (CI, autre poste) tout
# en affirmant la meme sortie — faux negatif silencieux. Pointes vers des repertoires vides : la
# cascade entiere echoue a resoudre quoi que ce soit, jamais seulement le maillon node.
FAKE_HOME29="$WORK_DIR/fake-home29"; mkdir -p "$FAKE_HOME29"
out29=$(PATH="$RESTRICTED_BIN" GSD_TOOLS="/nonexistent/gsd-tools.cjs" HOME="$FAKE_HOME29" CLAUDE_CONFIG_DIR="$FAKE_HOME29/.claude-cfg" "$BASH_BIN" "$SCRIPT" ready --file="$F29"); rc29=$?
assert_exit "T29.1 — exit 0 malgre la CLI amont indisponible (jamais un crash du socle)" "$rc29" 0
assert      "T29.2 — ready reste intact"                                                 "$out29" '"ready": ['$'\n''    "n1",'$'\n''    "n2"'
assert      "T29.3 — count reste intact"                                                 "$out29" '"count": 2'
assert      "T29.4 — stages degrade a null (jamais absent, jamais un tableau vide)"      "$out29" '"stages": null'

echo "=== T31 — CLI amont RESOLUE mais qui ECHOUE (returncode != 0) : stages:null, jamais stages:[] (M1, revue) ==="
# Distinct de T29/T30 : ici la resolution REUSSIT (un `gsd-tools` existe et est trouve sur le
# PATH), mais le sous-processus rend un code de retour non nul. La doctrine (mission-flow.md)
# ecrit que stages:[] et stages:null ne se confondent JAMAIS — [] = « frontiere ready vide »,
# null = « degrade ». Ce test cible precisement la ligne `if result.returncode != 0: return None`
# de compute_stages() : une mutation qui la remplacerait par `return []` doit faire rougir CE test.
F31="$WORK_DIR/t31.dag.json"; "$SCRIPT" init --file="$F31" >/dev/null
"$SCRIPT" add --file="$F31" --id=m1 --step=m1 --scope=src/m.ts >/dev/null
"$SCRIPT" add --file="$F31" --id=m2 --step=m2 --scope=src/m.ts >/dev/null
FAKE_BIN31="$WORK_DIR/fake-bin31"; mkdir -p "$FAKE_BIN31"
cat > "$FAKE_BIN31/gsd-tools" <<'FAKEEOF'
#!/usr/bin/env bash
exit 1
FAKEEOF
chmod +x "$FAKE_BIN31/gsd-tools"
out31=$(PATH="$FAKE_BIN31:$PATH" GSD_TOOLS="" "$SCRIPT" ready --file="$F31"); rc31=$?
assert_exit "T31.1 — exit 0 malgre l'echec de la CLI resolue"                  "$rc31" 0
assert      "T31.2 — ready reste intact"                                       "$out31" '"ready": ['$'\n''    "m1",'$'\n''    "m2"'
assert      "T31.3 — count reste intact"                                       "$out31" '"count": 2'
assert      "T31.4 — stages degrade a null (CLI resolue MAIS returncode != 0, jamais [])" "$out31" '"stages": null'

echo "=== T32 — node ABSENT mais gsd-tools (.cjs) RESOLU et present : stages:null via l'absence de node specifiquement (M2, revue) ==="
# Cas distinct de T29 (rien ne resout) et de T31 (CLI resolue qui echoue) : ici la resolution
# aboutit a un chemin `.cjs` EXISTANT (via GSD_TOOLS), mais `node` n'est pas sur le PATH — c'est la
# branche `if resolved.endswith(".cjs"): node_bin = shutil.which("node") ... return None`. Le
# fichier cible est lui-meme un script bash EXECUTABLE valide (chmod +x, shebang bash) qui
# produirait un JSON de stages valide s'il etait lance directement — ce qui rend le test
# discriminant : une mutation qui ignorerait l'absence de node et executerait quand meme le chemin
# resolu produirait un stages non nul (« evil » cote reel), et non un stages:null.
F32="$WORK_DIR/t32.dag.json"; "$SCRIPT" init --file="$F32" >/dev/null
"$SCRIPT" add --file="$F32" --id=v1 --step=v1 --scope=src/v.ts >/dev/null
"$SCRIPT" add --file="$F32" --id=v2 --step=v2 --scope=src/v.ts >/dev/null
FAKE_CJS32="$WORK_DIR/fake-gsd-tools32.cjs"
# `echo` (builtin bash), jamais `cat`/`printf` externe : sur le PATH volontairement restreint
# ci-dessous, tout appel a une commande EXTERNE a l'intérieur de ce script echouerait (exit 127)
# et ferait accidentellement rentrer stages a null par un tout autre chemin que celui vise — le
# script piege doit pouvoir reussir SEUL une fois lance, pour que la preuve par mutation soit valide.
cat > "$FAKE_CJS32" <<'CJSEOF'
#!/usr/bin/env bash
echo '{"summary": {"stagesByWave": [[["v1", "v2"]]]}}'
CJSEOF
chmod +x "$FAKE_CJS32"
RESTRICTED_BIN32="$WORK_DIR/restricted-bin32"; mkdir -p "$RESTRICTED_BIN32"
ln -s "$(command -v python3)" "$RESTRICTED_BIN32/python3"
# `bash` reste sur ce PATH restreint (seul `node` en est absent) : le fichier piege ci-dessus a un
# shebang `#!/usr/bin/env bash` que son propre interpreteur doit pouvoir resoudre pour que la
# preuve par mutation soit valide — sans lui, une mutation qui executerait le chemin resolu SANS
# node echouerait de toute facon (bash introuvable), et le test resterait vert par accident au
# lieu de rougir sur la mutation ciblee.
ln -s "$(command -v bash)" "$RESTRICTED_BIN32/bash"
out32=$(PATH="$RESTRICTED_BIN32" GSD_TOOLS="$FAKE_CJS32" "$BASH_BIN" "$SCRIPT" ready --file="$F32"); rc32=$?
assert_exit "T32.1 — exit 0 malgre node absent"                                          "$rc32" 0
assert      "T32.2 — ready reste intact"                                                 "$out32" '"ready": ['$'\n''    "v1",'$'\n''    "v2"'
assert      "T32.3 — stages degrade a null (gsd-tools .cjs resolu, node introuvable)"    "$out32" '"stages": null'
assert_not  "T32.4 — le script cible n'a jamais tourne (son JSON n'apparait pas)"        "$out32" 'v1", "v2"]]'

echo "=== T33 — NON-REGRESSION (vecteur RCE, 5e passage) : un gsd-tools.cjs TRACKE au CWD n'est JAMAIS resolu ni execute (D-07) ==="
# Reconstitue le PoC de securite : un fichier `gsd-core/bin/gsd-tools.cjs` pose a la racine du
# repertoire de travail courant (le cas d'une branche/PR malveillante). AUCUNE autre resolution ne
# doit reussir (PATH/HOME/CLAUDE_CONFIG_DIR neutralises, comme T29) — c'est precisement le scenario
# ou l'ANCIEN candidat cwd-relatif etait le seul a resoudre quoi que ce soit. `node` reste
# DISPONIBLE (contrairement a T29/T32) : la preuve ne doit RIEN a l'absence de node, seulement au
# retrait du candidat. Le fichier piege, s'il etait execute, ecrirait un marqueur sur disque ET
# rendrait un JSON reconnaissable ("evil") — deux signaux independants de non-execution.
F33="$WORK_DIR/t33.dag.json"; "$SCRIPT" init --file="$F33" >/dev/null
"$SCRIPT" add --file="$F33" --id=w1 --step=w1 --scope=src/w.ts >/dev/null
"$SCRIPT" add --file="$F33" --id=w2 --step=w2 --scope=src/w.ts >/dev/null
CWD_TRAP="$WORK_DIR/cwd-trap"; mkdir -p "$CWD_TRAP/gsd-core/bin"
MARKER33="$WORK_DIR/rce-marker33"; rm -f "$MARKER33"
cat > "$CWD_TRAP/gsd-core/bin/gsd-tools.cjs" <<CJSEOF2
require('fs').writeFileSync('$MARKER33', 'pwned');
console.log(JSON.stringify({summary:{stagesByWave:[[["evil"]]]}}));
CJSEOF2
RCE_BIN33="$WORK_DIR/rce-bin33"; mkdir -p "$RCE_BIN33"
ln -s "$(command -v python3)" "$RCE_BIN33/python3"
ln -s "$(command -v node)"    "$RCE_BIN33/node"
FAKE_HOME33="$WORK_DIR/fake-home33"; mkdir -p "$FAKE_HOME33"
out33=$(cd "$CWD_TRAP" && PATH="$RCE_BIN33" GSD_TOOLS="" HOME="$FAKE_HOME33" CLAUDE_CONFIG_DIR="$FAKE_HOME33/.claude-cfg" "$BASH_BIN" "$SCRIPT" ready --file="$F33"); rc33=$?
assert_exit "T33.1 — exit 0 malgre l'absence de toute resolution (jamais un crash)"        "$rc33" 0
assert      "T33.2 — le fichier pose au CWD n'est JAMAIS execute (marqueur disque absent)" "$([ -f "$MARKER33" ] && echo present || echo absent)" "absent"
assert      "T33.3 — stages degrade a null (candidat cwd retire, node disponible pourtant)" "$out33" '"stages": null'
assert_not  "T33.4 — le contenu du script piege n'apparait jamais dans la sortie"          "$out33" 'evil'

echo "=== T30 — frontiere vide (tous les noeuds blocked ou done) : stages=[] et aucun sous-processus n'est lance ==="
F30="$WORK_DIR/t30.dag.json"; "$SCRIPT" init --file="$F30" >/dev/null
"$SCRIPT" add --file="$F30" --id=z1 --step=z1 >/dev/null
"$SCRIPT" add --file="$F30" --id=z2 --step=z2 --deps=z1 >/dev/null
"$SCRIPT" mark --file="$F30" --id=z1 --status=running >/dev/null   # z1 running (ni ready ni done) ; z2 reste blocked
out30=$("$SCRIPT" ready --file="$F30")
assert "T30.1 — frontiere vide : ready=[] et count=0"                                              "$out30" '"ready": [],'$'\n''  "count": 0'
# stages=[] (et non null) prouve le court-circuit : si compute_stages() etait quand meme invoquee
# sur une liste vide, emit-workflow rejetterait un `plans` vide (ok:false) et degraderait a null —
# un mutant qui supprimerait la garde « if frontier_nodes else [] » ferait donc echouer CE test,
# pas seulement produire un resultat different sans verification (cas discriminant).
assert "T30.2 — stages=[] (jamais null) : preuve que compute_stages() n'a pas ete appelee"          "$out30" '"stages": []'

DRIVER_LOCK_SCRIPT="$(pwd)/scripts/driver-lock.sh"

echo "=== T34 — lock acquis : dag.sh mark avance progress_epoch sur le lock courant (WTCH-01) ==="
export VF_DRIVER_LOCK="$WORK_DIR/t34.lock"
rm -rf "$VF_DRIVER_LOCK"
"$DRIVER_LOCK_SCRIPT" acquire --owner=tester --step=s1 >/dev/null
F34="$WORK_DIR/t34.dag.json"
"$SCRIPT" init --file="$F34" >/dev/null
"$SCRIPT" add --file="$F34" --id=n1 --step=n1 >/dev/null
"$SCRIPT" mark --file="$F34" --id=n1 --status=running >/dev/null
st34="$("$DRIVER_LOCK_SCRIPT" status)"
page34="$(printf '%s' "$st34" | grep -o '"progress_age_seconds": [0-9]*' | grep -o '[0-9]*$')"
if [ -n "$page34" ] && [ "$page34" -le 2 ]; then
  echo "  ✅ PASS — T34.1 — progress_age_seconds proche de 0 après mark (${page34}s)"; PASS=$((PASS+1))
else
  echo "  ❌ FAIL — T34.1 — progress_age_seconds proche de 0 après mark"; echo "     attendu: <=2"; echo "     obtenu:  ${page34:-vide}"; FAIL=$((FAIL+1))
fi
"$DRIVER_LOCK_SCRIPT" release --owner=tester >/dev/null 2>&1
rm -rf "$VF_DRIVER_LOCK"

echo "=== T35 — aucun lock present : dag.sh mark inchange (sortie identique a avant ce plan) ==="
export VF_DRIVER_LOCK="$WORK_DIR/t35.lock-absent"
rm -rf "$VF_DRIVER_LOCK"
F35="$WORK_DIR/t35.dag.json"
"$SCRIPT" init --file="$F35" >/dev/null
"$SCRIPT" add --file="$F35" --id=n1 --step=n1 >/dev/null
out35="$("$SCRIPT" mark --file="$F35" --id=n1 --status=running)"; rc35=$?
assert_exit "T35.1 — exit 0 sans lock present"                      "$rc35" 0
assert      "T35.2 — sortie JSON porte toujours id/status/ready"    "$out35" '"id": "n1"'
assert      "T35.3 — status running toujours present"               "$out35" '"status": "running"'
assert      "T35.4 — cle ready toujours presente"                   "$out35" '"ready":'
unset VF_DRIVER_LOCK

echo "=== T36 — sibling driver-lock.sh ISOLE en panne (exit 1, pas de JSON) : mark reste vert, DAG mis a jour sur disque ==="
ISO36="$WORK_DIR/iso36"; mkdir -p "$ISO36"
cp "$SCRIPT" "$ISO36/dag.sh"
cat > "$ISO36/driver-lock.sh" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
chmod +x "$ISO36/driver-lock.sh"
# Controle positif de la fixture (T36.0) : le faux script echoue reellement quand invoque seul.
"$ISO36/driver-lock.sh" >/dev/null 2>&1; rc360=$?
assert_exit "T36.0 — controle positif : la fixture panne echoue bien seule (exit 1)" "$rc360" 1
F36="$WORK_DIR/t36.dag.json"
"$ISO36/dag.sh" init --file="$F36" >/dev/null
"$ISO36/dag.sh" add --file="$F36" --id=n1 --step=n1 >/dev/null
out36="$("$ISO36/dag.sh" mark --file="$F36" --id=n1 --status=running)"; rc36=$?
assert_exit "T36.1 — exit 0 malgre driver-lock.sh en panne (exit 1 sans JSON)" "$rc36" 0
assert      "T36.2 — sortie mark reflete bien le nouveau statut"               "$out36" '"status": "running"'
assert      "T36.3 — le fichier DAG SUR DISQUE porte le nouveau statut (preuve que save(dag) a eu lieu avant l'appel driver-lock defaillant)" "$(cat "$F36")" '"status": "running"'

echo "=== T37 — sibling driver-lock.sh ISOLE qui rend du JSON illisible : mark reste vert, DAG mis a jour normalement ==="
ISO37="$WORK_DIR/iso37"; mkdir -p "$ISO37"
cp "$SCRIPT" "$ISO37/dag.sh"
cat > "$ISO37/driver-lock.sh" <<'EOF'
#!/usr/bin/env bash
echo "not-json"
exit 0
EOF
chmod +x "$ISO37/driver-lock.sh"
# Controle positif de la fixture (T37.0) : la sortie n'est vraiment pas du JSON valide.
out370="$("$ISO37/driver-lock.sh" status)"
assert_not "T37.0 — controle positif : la fixture rend bien une sortie non-JSON" "$out370" '{'
F37="$WORK_DIR/t37.dag.json"
"$ISO37/dag.sh" init --file="$F37" >/dev/null
"$ISO37/dag.sh" add --file="$F37" --id=n1 --step=n1 >/dev/null
out37="$("$ISO37/dag.sh" mark --file="$F37" --id=n1 --status=running)"; rc37=$?
assert_exit "T37.1 — exit 0 malgre un JSON illisible cote driver-lock.sh" "$rc37" 0
assert      "T37.2 — DAG SUR DISQUE mis a jour normalement"              "$(cat "$F37")" '"status": "running"'

echo "=== T38 — sibling driver-lock.sh ISOLE qui PEND (sleep 30) : mark revient en MOINS DE 5s, DAG deja sauve avant l'appel pendant ==="
ISO38="$WORK_DIR/iso38"; mkdir -p "$ISO38"
cp "$SCRIPT" "$ISO38/dag.sh"
cat > "$ISO38/driver-lock.sh" <<'EOF'
#!/usr/bin/env bash
sleep 30
EOF
chmod +x "$ISO38/driver-lock.sh"
# Controle positif de la fixture (T38.0) : le processus est encore vivant apres 1s (borne, jamais
# un sleep non borne dans le test lui-meme) — preuve qu'il pend reellement plutot que de sortir vite.
"$ISO38/driver-lock.sh" >/dev/null 2>&1 &
p38=$!
sleep 1
if kill -0 "$p38" 2>/dev/null; then
  echo "  ✅ PASS — T38.0 — controle positif : la fixture pend bien (processus vivant après 1s)"; PASS=$((PASS+1))
else
  echo "  ❌ FAIL — T38.0 — controle positif : la fixture pend bien"; FAIL=$((FAIL+1))
fi
kill -9 "$p38" 2>/dev/null; wait "$p38" 2>/dev/null
F38="$WORK_DIR/t38.dag.json"
"$ISO38/dag.sh" init --file="$F38" >/dev/null
"$ISO38/dag.sh" add --file="$F38" --id=n1 --step=n1 >/dev/null
t0_38=$(date +%s)
# NE PAS capturer run_bounded via $(...) ici : le watcher interne de run_bounded
# (`( sleep 5; kill -9 "$pid" ) &`) n'a pas son propre stdout redirige et herite donc du pipe de
# la substitution de commande englobante — meme apres que `wait "$pid"` rende la main et que le
# watcher soit tue, `$(...)` peut rester bloque jusqu'a ce que CE descripteur herite se ferme,
# soit jusqu'au kill -9 du watcher lui-meme a 5s (fausse alerte reproduite et mesuree : 5.0-5.03s
# systematique avec capture directe, 2.0-2.1s sans — piege classique de bash, pas un defaut de
# record_progress). Rediriger vers un fichier evite le pipe et cette dependance.
OUT38FILE="$WORK_DIR/t38.out"
run_bounded "$ISO38/dag.sh" mark --file="$F38" --id=n1 --status=running >"$OUT38FILE"; rc38=$?
out38="$(cat "$OUT38FILE" 2>/dev/null)"
t1_38=$(date +%s)
elapsed38=$((t1_38 - t0_38))
assert_exit "T38.1 — exit 0 malgre un driver-lock.sh qui pend"                          "$rc38" 0
if [ "$elapsed38" -lt 5 ]; then
  echo "  ✅ PASS — T38.2 — retour en moins de 5s (mesure : ${elapsed38}s, timeout=2 interne)"; PASS=$((PASS+1))
else
  echo "  ❌ FAIL — T38.2 — retour en moins de 5s"; echo "     attendu: <5"; echo "     obtenu:  ${elapsed38}s"; FAIL=$((FAIL+1))
fi
assert "T38.3 — DAG SUR DISQUE porte deja le nouveau statut (save(dag) a eu lieu avant l'appel pendant)" "$(cat "$F38")" '"status": "running"'

echo "=== T39 — non-regression statique : aucun subprocess.run vers les siblings ne passe par une chaine shell ==="
assert_exit "T39.1 — grep positif sur l'appel status en LISTE"       "$(grep -c '\[driver_lock_sh, "status"\]' "$SCRIPT" >/dev/null; echo $?)" 0
assert_exit "T39.2 — grep positif sur l'appel mark-progress en LISTE" "$(grep -c '\[driver_lock_sh, "mark-progress"' "$SCRIPT" >/dev/null; echo $?)" 0
assert_exit "T39.3 — aucun shell=True dans dag.sh"                    "$([ "$(grep -c 'shell=True' "$SCRIPT")" -eq 0 ]; echo $?)" 0

echo "=== T40 — lock present+detenu mais mark-progress ECHOUE (exit 1) : mark reste vert, DAG mis a jour, avertissement BRUYANT sur stderr (4e issue QUAL-01) ==="
ISO40="$WORK_DIR/iso40"; mkdir -p "$ISO40"
cp "$SCRIPT" "$ISO40/dag.sh"
cat > "$ISO40/driver-lock.sh" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "status" ]; then
  echo '{"present": true, "owner": "tester", "step": "s", "age_seconds": 1}'
  exit 0
fi
if [ "$1" = "mark-progress" ]; then
  exit 1
fi
exit 1
EOF
chmod +x "$ISO40/driver-lock.sh"
# Controle positif de la fixture (T40.0) : status confirme present+owner, mark-progress echoue reellement.
st400="$("$ISO40/driver-lock.sh" status)"
assert     "T40.0a — controle positif : la fixture rend bien present+owner=tester" "$st400" '"owner": "tester"'
"$ISO40/driver-lock.sh" mark-progress --owner=tester >/dev/null 2>&1; rc400=$?
assert_exit "T40.0b — controle positif : la fixture echoue bien sur mark-progress" "$rc400" 1
F40="$WORK_DIR/t40.dag.json"
"$ISO40/dag.sh" init --file="$F40" >/dev/null
"$ISO40/dag.sh" add --file="$F40" --id=n1 --step=n1 >/dev/null
ERR40="$WORK_DIR/t40.stderr"
out40="$("$ISO40/dag.sh" mark --file="$F40" --id=n1 --status=running 2>"$ERR40")"; rc40=$?
assert_exit "T40.1 — exit 0 malgre l'echec de mark-progress sur lock sain"           "$rc40" 0
assert      "T40.2 — DAG SUR DISQUE mis a jour"                                     "$(cat "$F40")" '"status": "running"'
assert      "T40.3 — avertissement BRUYANT sur stderr (lock present+detenu, ecriture refusee)" "$(cat "$ERR40")" 'mark-progress'

echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then
  echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"
  exit 1
fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
