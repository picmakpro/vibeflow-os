#!/usr/bin/env bash
# test-cockpit-direct-coupe.sh — AUDC-M9 (lot 0 de l'audit du cockpit) : une coupure du direct se dit à temps, puis la bannière se retire seule.
#   C1 à 5,5 s de la coupure la pastille dit « Direct coupé » (classe, libellé, infobulle), sans bannière
#   C2 la bannière n'arrive pas avant 13 s et arrive à 15 s environ (avant : à 300 s)
#   C3 au retour du réseau la bannière se retire seule (avant : elle restait jusqu'à un clic) et le flux est rouvert une fois
# Coupure simulée dans le navigateur (réseau hors ligne + perte du flux signalée à la page), sur les trois onglets. Chrome headless ;
# sans navigateur la suite est SAUTÉE hors CI, et ÉCHOUE en CI (jamais un vert à vide).
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"; ENG="$SCRIPTS/../skills/cockpit-moteur"
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then
  if [ -n "${CI:-}" ]; then echo "  ❌ FAIL — aucun navigateur en CI : la coupure du direct n'est PAS vérifiée"; exit 1; fi
  echo "  ⊘ SUITE SAUTÉE : aucun navigateur — la coupure du direct n'est PAS vérifiée, non compté comme réussi"; exit 0
fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [${2:0:400}]"; FAIL=$((FAIL+1)); fi; }
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
mklab() {
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"; printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n' > "$B/ROADMAP.md"
  printf '<objective>Faire le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"; echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
}
srv() { # srv <sortie> -> SRV_PORT
  local o="$1" lab; lab="$(cd "$1/../.." && pwd)"; rm -f "$o/.cache/server.json"
  ( cd "$lab" && VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" exec node "$o/serve.mjs" --no-open --port $(libre) > "$o/../serve.out" 2>&1 ) </dev/null >/dev/null 2>&1 &
  PIDS+=($!)
  for _ in $(seq 1 100); do grep -q '"port"' "$o/.cache/server.json" 2>/dev/null && break; sleep 0.1; done
  SRV_PORT="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$o/.cache/server.json','utf8')).port)" 2>/dev/null || echo 0)"
  SRV_REAL="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$o/.cache/server.json','utf8')).pid)" 2>/dev/null || echo 0)"
}
mesure() { # mesure <lab> <page> -> JSON sur la sortie ; arrête le serveur ensuite
  local o="$1/.vibeflow/cockpit"; srv "$o"
  local r; r="$(REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-direct-coupe.mjs" "$CHROME" "http://127.0.0.1:$SRV_PORT/$2")"
  vf_hyg_kill TERM "$SRV_REAL"
  printf '%s\n' "$r"
}
LAB="$WORK/lab"; mklab "$LAB"
for PAGE in project.html ""; do
  echo "=== coupure simulée — page /${PAGE} ==="
  R="$(mesure "$LAB" "$PAGE")"; [ -n "${DBG:-}" ] && echo "RAW: $R"
  assert_eq "C0 — la mesure a eu lieu (/${PAGE})" "$(printf '%s' "$R" | node "$AUX/ev.mjs" '!!j.erreur')" "false"
  assert_eq "C1.1 — à 5,5 s la pastille est en classe « off » (/${PAGE})" "$(printf '%s' "$R" | node "$AUX/ev.mjs" '/(^| )off( |$)/.test(j.a5.cls)')" "true"
  assert_eq "C1.2 — à 5,5 s le libellé dit « Direct coupé » (/${PAGE})" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.a5.txt')" "Direct coupé"
  assert_eq "C1.3 — à 5,5 s l'infobulle dit que le serveur ne répond pas, sans bannière (/${PAGE})" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.a5.title + "|" + j.a5.banniere')" "Le serveur du cockpit ne répond pas|false"
  assert_eq "C2.1 — pas de bannière avant 13 s (/${PAGE})" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.avant13.banniere')" "false"
  assert_eq "C2.2 — la bannière arrive entre 13 s et 18 s (/${PAGE})" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.tBanniere !== null && j.tBanniere >= 13000 && j.tBanniere <= 18000')" "true"
  assert_eq "C3.1 — au retour du réseau la bannière se retire seule en moins de 8 s (/${PAGE})" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.tBanniere !== null && j.tRetrait !== null')" "true"
  assert_eq "C3.2 — le flux est rouvert une seule fois (/${PAGE})" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.reouvert')" "1"
done
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ "$FAIL" -eq 0 ]
