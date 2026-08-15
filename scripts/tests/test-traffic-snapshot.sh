#!/usr/bin/env bash
# test-traffic-snapshot.sh — Suite de vérification de scripts/traffic-snapshot.sh (quick task 260815-tl6).
#
# Neuf cas, sur fixtures verbatim (scripts/tests/fixtures/traffic-snapshot/) : la couture
# VF_TRAFFIC_FIXTURES fait lire les payloads sur disque au lieu du réseau, mais parsing,
# agrégation par jour, calcul de l'ajustement, fusion et écriture restent le chemin de
# production — la couture n'injecte que des réponses d'API, jamais un résultat (leçon des
# Phases 13/17/19 : un test qui n'exerce pas le code réellement émis ne teste rien).
#
# Fixtures (3 jours, 3 runs) :
#   2026-08-04 — nominal : 227 clones / 84 jobs CI (run 1001)  → clones_adjusted attendu 143
#   2026-08-05 — borne à zéro : 5 clones / 9 jobs CI (runs 1002+1003, 4+5) → clones_adjusted attendu 0
#   2026-08-06 — présent seulement côté vues (15 vues, absent de clones.json) → clones: 0
# Les entrées de clones.json et views.json sont volontairement écrites dans le désordre
# chronologique (T8 : seul un tri explicite peut produire une sortie triée).
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$(cd "$HERE/.." && pwd)/traffic-snapshot.sh"
FIXTURES="$HERE/fixtures/traffic-snapshot"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

# Exécute le script sous couture fixtures, dans un répertoire de travail jetable.
# $1 = fichier --out (peut préexister pour T5/T6) ; le reste = arguments additionnels.
run_snapshot() {
  local out="$1"; shift
  VF_TRAFFIC_FIXTURES="$FIXTURES" bash "$SCRIPT" --out "$out" "$@"
}

echo "== traffic-snapshot — suite sur fixtures =="

# --- T1 : --help sort 0 et cite --dry-run --------------------------------------------------------
D="$(mktemp -d)"; trap 'rm -rf "$D"' RETURN 2>/dev/null || true
out="$(bash "$SCRIPT" --help 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q -- '--dry-run'; then
  ok "T1 --help sort 0 et cite --dry-run"
else
  ko "T1 --help sort 0 et cite --dry-run" "rc=$rc"
fi
rm -rf "$D"

# --- T2 : ajustement nominal — 227 clones / 84 jobs -> 143 ----------------------------------------
D="$(mktemp -d)"
OUT="$D/traffic.json"
run_snapshot "$OUT" >/dev/null 2>"$D/err.log"; rc=$?
val="$(jq -r '.["2026-08-04"].clones_adjusted // "MISSING"' "$OUT" 2>/dev/null)"
if [ "$rc" -eq 0 ] && [ "$val" = "143" ]; then
  ok "T2 ajustement nominal — 227/84 -> 143"
else
  ko "T2 ajustement nominal — 227/84 -> 143" "rc=$rc val=$val ($(cat "$D/err.log" 2>/dev/null))"
fi
rm -rf "$D"

# --- T3 : borne à zéro — 5 clones / 9 jobs -> 0, jamais négatif -----------------------------------
D="$(mktemp -d)"
OUT="$D/traffic.json"
run_snapshot "$OUT" >/dev/null 2>"$D/err.log"; rc=$?
val="$(jq -r '.["2026-08-05"].clones_adjusted // "MISSING"' "$OUT" 2>/dev/null)"
if [ "$rc" -eq 0 ] && [ "$val" = "0" ]; then
  ok "T3 borne à zéro — 5/9 -> 0"
else
  ko "T3 borne à zéro — 5/9 -> 0" "rc=$rc val=$val"
fi
rm -rf "$D"

# --- T4 : union des dates — jour vu seulement côté vues rend clones: 0 ----------------------------
D="$(mktemp -d)"
OUT="$D/traffic.json"
run_snapshot "$OUT" >/dev/null 2>"$D/err.log"; rc=$?
clones_val="$(jq -r '.["2026-08-06"].clones // "MISSING"' "$OUT" 2>/dev/null)"
clones_u_val="$(jq -r '.["2026-08-06"].clones_uniques // "MISSING"' "$OUT" 2>/dev/null)"
views_val="$(jq -r '.["2026-08-06"].views // "MISSING"' "$OUT" 2>/dev/null)"
if [ "$rc" -eq 0 ] && [ "$clones_val" = "0" ] && [ "$clones_u_val" = "0" ] && [ "$views_val" = "15" ]; then
  ok "T4 union des dates — jour vues-seul rend clones: 0"
else
  ko "T4 union des dates — jour vues-seul rend clones: 0" "rc=$rc clones=$clones_val clones_uniques=$clones_u_val views=$views_val"
fi
rm -rf "$D"

# --- T5 : fusion idempotente / conservation — date hors fenêtre survit intacte --------------------
D="$(mktemp -d)"
OUT="$D/traffic.json"
printf '%s\n' '{"2020-01-01":{"clones":999,"clones_uniques":1,"views":1,"views_uniques":1,"ci_jobs":0,"clones_adjusted":999}}' > "$OUT"
run_snapshot "$OUT" >/dev/null 2>"$D/err.log"; rc=$?
val="$(jq -Sc '.["2020-01-01"]' "$OUT" 2>/dev/null)"
expected="$(printf '%s' '{"clones":999,"clones_uniques":1,"views":1,"views_uniques":1,"ci_jobs":0,"clones_adjusted":999}' | jq -Sc .)"
if [ "$rc" -eq 0 ] && [ "$val" = "$expected" ]; then
  ok "T5 conservation — date hors fenêtre intacte"
else
  ko "T5 conservation — date hors fenêtre intacte" "rc=$rc val=$val"
fi
rm -rf "$D"

# --- T6 : fusion idempotente / rafraîchissement — date dans la fenêtre écrasée par le frais --------
D="$(mktemp -d)"
OUT="$D/traffic.json"
printf '%s\n' '{"2026-08-04":{"clones":1,"clones_uniques":1,"views":1,"views_uniques":1,"ci_jobs":1,"clones_adjusted":0}}' > "$OUT"
run_snapshot "$OUT" >/dev/null 2>"$D/err.log"; rc=$?
val="$(jq -r '.["2026-08-04"].clones_adjusted // "MISSING"' "$OUT" 2>/dev/null)"
if [ "$rc" -eq 0 ] && [ "$val" = "143" ]; then
  ok "T6 rafraîchissement — date dans la fenêtre écrasée"
else
  ko "T6 rafraîchissement — date dans la fenêtre écrasée" "rc=$rc val=$val"
fi
rm -rf "$D"

# --- T7 : stabilité — deux exécutions successives produisent une sortie identique octet pour octet -
D="$(mktemp -d)"
OUT="$D/traffic.json"
run_snapshot "$OUT" >/dev/null 2>"$D/err1.log"
cp "$OUT" "$D/first.json"
run_snapshot "$OUT" >/dev/null 2>"$D/err2.log"; rc=$?
if [ "$rc" -eq 0 ] && cmp -s "$D/first.json" "$OUT"; then
  ok "T7 stabilité — deux passages identiques octet pour octet"
else
  ko "T7 stabilité — deux passages identiques octet pour octet" "rc=$rc"
fi
rm -rf "$D"

# --- T8 : tri — les clés sortent en ordre chronologique croissant ----------------------------------
D="$(mktemp -d)"
OUT="$D/traffic.json"
run_snapshot "$OUT" >/dev/null 2>"$D/err.log"; rc=$?
keys_actual="$(jq -r 'keys[]' "$OUT" 2>/dev/null | tr '\n' ' ')"
keys_sorted="$(jq -r 'keys[]' "$OUT" 2>/dev/null | sort | tr '\n' ' ')"
if [ "$rc" -eq 0 ] && [ "$keys_actual" = "$keys_sorted" ] && [ -n "$keys_actual" ]; then
  ok "T8 tri — clés en ordre chronologique croissant ($keys_actual)"
else
  ko "T8 tri — clés en ordre chronologique croissant" "rc=$rc actual=[$keys_actual] sorted=[$keys_sorted]"
fi
rm -rf "$D"

# --- T9 : discriminance de la couture — aucun appel réseau sous fixtures, PATH sans gh -------------
# PATH restreint : jq, mktemp, mv, cat et l'interpréteur bash, mais PAS gh. Prouve que la couture
# court-circuite bien les quatre fonctions d'appel (sinon le script échouerait, faute de `gh`).
D="$(mktemp -d)"
OUT="$D/traffic.json"
RESTRICTED_BIN="$D/bin"
mkdir -p "$RESTRICTED_BIN"
for tool in jq mktemp mv cat bash sh dirname wc tr sort head cut basename mkdir rm printf; do
  p="$(command -v "$tool" 2>/dev/null)" || continue
  ln -sf "$p" "$RESTRICTED_BIN/$tool"
done
if command -v gh >/dev/null 2>&1 && [ -e "$RESTRICTED_BIN/gh" ]; then rm -f "$RESTRICTED_BIN/gh"; fi
PATH_NO_GH="$RESTRICTED_BIN"
rc="$(PATH="$PATH_NO_GH" VF_TRAFFIC_FIXTURES="$FIXTURES" bash "$SCRIPT" --out "$OUT" >/dev/null 2>"$D/err.log"; echo $?)"
val="$(jq -r '.["2026-08-04"].clones_adjusted // "MISSING"' "$OUT" 2>/dev/null)"
if [ "$rc" -eq 0 ] && [ "$val" = "143" ]; then
  ok "T9 discriminance — vert sans gh sur le PATH (fixtures court-circuitent le réseau)"
else
  ko "T9 discriminance — vert sans gh sur le PATH" "rc=$rc val=$val ($(cat "$D/err.log" 2>/dev/null))"
fi
# Preuve que T9 mesure quelque chose : sans VF_TRAFFIC_FIXTURES, le même PATH restreint DOIT rougir
# (le script tente alors un vrai appel réseau via `gh`, absent du PATH).
rc2="$(PATH="$PATH_NO_GH" bash "$SCRIPT" --out "$D/should-fail.json" >/dev/null 2>"$D/err-noseam.log"; echo $?)"
if [ "$rc2" -ne 0 ]; then
  ok "T9b contrôle négatif — sans la couture, le même PATH restreint rougit bien"
else
  ko "T9b contrôle négatif — sans la couture, le même PATH restreint rougit bien" "rc=$rc2 (T9 ne mesurerait rien)"
fi
rm -rf "$D"

echo ""
echo "== bilan : $PASS OK / $FAIL KO =="
[ "$FAIL" -eq 0 ]
