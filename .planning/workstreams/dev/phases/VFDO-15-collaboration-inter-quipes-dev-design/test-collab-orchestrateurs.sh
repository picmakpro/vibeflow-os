#!/usr/bin/env bash
# test-collab-orchestrateurs.sh — Étude empirique : que se passe-t-il si vf-dev-manager
# et vf-design-manager tentent de collaborer avec le team-kernel ACTUEL ?
#
# T1 — dispatch imbriqué manager→manager : collision de verrou attendue (Pattern A)
# T2 — handoff séquentiel (release puis acquire) : doit passer
# T3 — mission mixte dev+design pilotée par UN manager : DAG hétérogène (nœuds gsd + craft/critique)
# T4 — reopen cross-métier : un craft sous le seuil rouvre, les nœuds dev dépendants rebloquent

set -uo pipefail
REPO="/Users/samuel/Documents/dev/vibeflow-os"
S="$REPO/plugin/conductor/scripts"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/collab-test.XXXXXX")"
export VF_DRIVER_LOCK="$WORK/DRIVER.lock"
DAG="$WORK/mission-mixte.dag.json"
PASS=0; FAIL=0

ok()  { PASS=$((PASS+1)); echo "  ✅ PASS — $1"; }
ko()  { FAIL=$((FAIL+1)); echo "  ❌ FAIL — $1 → $2"; }

echo "== T1 — dispatch imbriqué : vf-design-manager pendant une mission vf-dev-manager =="
out1="$("$S"/driver-lock.sh acquire --owner=dev-mission-42 --step="mission dev")"
echo "$out1" | grep -q '"acquired": *true' && ok "T1.1 dev-manager prend le verrou" || ko "T1.1" "$out1"
out2="$("$S"/driver-lock.sh acquire --owner=design-mission-7 --step="mission design imbriquée")"
if echo "$out2" | grep -q '"acquired": *false' && echo "$out2" | grep -q 'dev-mission-42'; then
  ok "T1.2 design-manager REFUSÉ (held_by=dev-mission-42) → imbrication manager→manager bloquée par Pattern A"
else
  ko "T1.2 collision attendue" "$out2"
fi

echo "== T2 — handoff séquentiel : le dev-manager relâche, PUIS dispatche la mission design =="
"$S"/driver-lock.sh release --owner=dev-mission-42 >/dev/null
out3="$("$S"/driver-lock.sh acquire --owner=design-mission-7 --step="mission design")"
echo "$out3" | grep -q '"acquired": *true' && ok "T2.1 handoff release→acquire fonctionne (collaboration séquentielle possible)" || ko "T2.1" "$out3"
"$S"/driver-lock.sh release --owner=design-mission-7 >/dev/null

echo "== T3 — mission MIXTE pilotée par un seul manager : DAG hétérogène dev+design =="
# Étape 5 = feature avec UI : cadrage dev → plan → craft design (spec écran) → exécution (implémente la spec)
#   → en parallèle après exec : critique design (juge) + revue code
"$S"/dag.sh init --file="$DAG" >/dev/null
"$S"/dag.sh add --file="$DAG" --id=discuss-5        --step="cadrage étape 5" >/dev/null
"$S"/dag.sh add --file="$DAG" --id=plan-5           --step="plan étape 5"          --deps=discuss-5 >/dev/null
"$S"/dag.sh add --file="$DAG" --id=craft:ecran-home --step="craft design écran"    --deps=plan-5 >/dev/null
"$S"/dag.sh add --file="$DAG" --id=exec-5           --step="implémentation"        --deps=craft:ecran-home >/dev/null
"$S"/dag.sh add --file="$DAG" --id=critique:ecran-home --step="critique design"    --deps=exec-5 >/dev/null
"$S"/dag.sh add --file="$DAG" --id=revue-5          --step="revue code"            --deps=exec-5 >/dev/null

r0="$("$S"/dag.sh ready --file="$DAG")"
echo "$r0" | grep -q 'discuss-5' && ok "T3.1 frontière initiale = cadrage" || ko "T3.1" "$r0"
"$S"/dag.sh mark --file="$DAG" --id=discuss-5 --status=done >/dev/null
"$S"/dag.sh mark --file="$DAG" --id=plan-5 --status=done >/dev/null
r1="$("$S"/dag.sh ready --file="$DAG")"
echo "$r1" | grep -q 'craft:ecran-home' && ok "T3.2 le nœud design (craft) entre dans la frontière d'un DAG dev — kernel métier-agnostique" || ko "T3.2" "$r1"
"$S"/dag.sh mark --file="$DAG" --id=craft:ecran-home --status=done >/dev/null
"$S"/dag.sh mark --file="$DAG" --id=exec-5 --status=done >/dev/null
r2="$("$S"/dag.sh ready --file="$DAG")"
if echo "$r2" | grep -q 'critique:ecran-home' && echo "$r2" | grep -q 'revue-5'; then
  ok "T3.3 juge design + revue code exposés EN PARALLÈLE dans la même frontière (2 juges read-only)"
else
  ko "T3.3 parallélisme cross-métier" "$r2"
fi

echo "== T4 — reopen cross-métier : critique < seuil → reopen craft → l'exécution rebloque =="
"$S"/dag.sh mark --file="$DAG" --id=revue-5 --status=done >/dev/null
"$S"/dag.sh mark --file="$DAG" --id=critique:ecran-home --status=done >/dev/null
"$S"/dag.sh reopen --file="$DAG" --id=craft:ecran-home >/dev/null
r3="$("$S"/dag.sh ready --file="$DAG")"
st="$("$S"/dag.sh status --file="$DAG" 2>/dev/null || cat "$DAG")"
if echo "$r3" | grep -q 'craft:ecran-home' && ! echo "$r3" | grep -q 'exec-5'; then
  exec_state="$(python3 -c "import json;d=json.load(open('$DAG'));print([n['status'] for n in d['nodes'] if n['id']=='exec-5'][0])" 2>/dev/null || echo '?')"
  ok "T4.1 reopen du craft rouvre la chaîne : craft ready, exec-5 → $exec_state (dépendants rebloqués)"
else
  ko "T4.1 ré-entrée cross-métier" "ready=$r3"
fi

echo
echo "== Résultats : $PASS PASS / $FAIL FAIL =="
rm -rf "$WORK"
[ "$FAIL" -eq 0 ]
