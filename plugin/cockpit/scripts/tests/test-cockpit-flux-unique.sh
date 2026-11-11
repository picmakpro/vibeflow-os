#!/usr/bin/env bash
# test-cockpit-flux-unique.sh — AUDC-H1 (lot 0 de l'audit du cockpit) : une page ouvre UN seul flux d'événements.
#   F1 la page ne crée qu'un flux, celui du direct (/api/vf/events) — jamais /api/events en plus
#   F2 scénario « trois onglets » : Code, Projet, Équipe ouverts, une quatrième page charge ; les quatre sont vues du serveur et une requête
#      d'état répond vite (avec deux flux par page, six connexions saturent l'origine : la quatrième page ne charge jamais)
#   F3 le rechargement automatique (la carte est reconstruite) passe par le flux unique : la page se recharge seule
# Chrome headless ; sans navigateur la suite est SAUTÉE hors CI, et ÉCHOUE en CI (jamais un vert à vide).
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"; ENG="$SCRIPTS/../skills/cockpit-moteur"
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then
  if [ -n "${CI:-}" ]; then echo "  ❌ FAIL — aucun navigateur en CI : le flux unique n'est PAS vérifié"; exit 1; fi
  echo "  ⊘ SUITE SAUTÉE : aucun navigateur — le flux unique n'est PAS vérifié, non compté comme réussi"; exit 0
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
mesure() { # mesure <lab> -> JSON sur la sortie ; arrête le serveur ensuite
  local o="$1/.vibeflow/cockpit"; srv "$o"
  local r; r="$(REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-flux-unique.mjs" "$CHROME" "$SRV_PORT" "$o/index.html")"
  vf_hyg_kill TERM "$SRV_REAL"
  printf '%s\n' "$r"
}
LAB="$WORK/lab"; mklab "$LAB"
echo "=== F1-F3 — trois onglets, une quatrième page, puis la carte reconstruite ==="
R="$(mesure "$LAB")"; [ -n "${DBG:-}" ] && echo "RAW: $R"
assert_eq "F0 — la mesure a eu lieu" "$(printf '%s' "$R" | node "$AUX/ev.mjs" '!!j.erreur')" "false"
assert_eq "F1 — la page ne crée qu'un flux : celui du direct" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.flux')" '["/api/vf/events"]'
assert_eq "F2.1 — les quatre pages sont vues du serveur (la quatrième a chargé)" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.tabs')" "4"
assert_eq "F2.2 — quatre flux du direct, pas huit" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.clients')" "4"
assert_eq "F2.3 — une requête d'état répond en moins de 2 s avec quatre pages ouvertes" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.ok && j.ms < 2000')" "true"
assert_eq "F3 — la carte reconstruite recharge la page par le flux unique" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.rechargee')" "true"
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ "$FAIL" -eq 0 ]
