#!/usr/bin/env bash
# test-cockpit-reconnexion.sh — E-6 (CKPT-05) : un serveur arrêté ne fait pas tourner la page à 2 requêtes par seconde sans fin.
#   N1 recul : requêtes rapides, puis espacées · N2 arrêt : plus aucune requête après le délai, avec un message et un bouton « Réessayer »
#   N3 « Réessayer » relance le sondage · N4 témoin rouge : le module d'avant (le navigateur réessaie seul, chaque seconde, pour son flux — la page n'en ouvre plus qu'un, AUDC-H1)
# Les délais sont raccourcis par la page (window.__vfLive.reco) : 200 ms jusqu'à 1,5 s, 600 ms, arrêt à 4 s. Chrome headless ; sans navigateur la suite est SAUTÉE.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"; ENG="$SCRIPTS/../skills/cockpit-moteur"
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then . "$(dirname "$0")/chrome-saut.sh"; vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur — la reconnexion à recul n'est PAS vérifiée, non comptée comme réussie"; exit 0; fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [${2:0:400}]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [${2:0:400}]"; FAIL=$((FAIL+1)); fi; }
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
srv() { # srv <sortie> -> SRV_PORT SRV_PID
  local o="$1" lab; lab="$(cd "$1/../.." && pwd)"
  COCKPIT_SORTIE="$o" cockpit_lancer "$lab" VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS"
  SRV_PID="${VF_PID:-}"; SRV_PORT="${VF_PORT:-0}"
}
reco() { # le PID du serveur est celui que celui-ci écrit dans server.json (SRV_PID est celui du sous-shell)
  local o="$1/.vibeflow/cockpit" pid; srv "$o"; pid="$VF_PID"
  local r; r="$(REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-reco.mjs" "$CHROME" "http://127.0.0.1:$SRV_PORT/$2" "$pid" "$SRV_PORT")"
  vf_hyg_kill TERM "$pid" # la mesure l'arrête déjà ; si elle a échoué avant (Chrome sous charge), le serveur ne doit pas survivre à l'appel
  printf '%s\n' "$r"
}

LAB="$WORK/lab"; mklab "$LAB"
echo "=== N1-N3 — serveur arrêté pendant que la page est ouverte ==="
R="$(reco "$LAB" project.html)"; [ -n "${DBG:-}" ] && echo "RAW: $R"
assert_eq "N0 — la mesure a eu lieu" "$(printf '%s' "$R" | node "$AUX/ev.mjs" '!!j.erreur')" "false"
assert_eq "N1.1 — recul : au moins 3 requêtes dans la première seconde et demie" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.rapide>=3')" "true"
assert_eq "N1.2 — recul : pas plus de 6 requêtes entre 1,7 s et 3,9 s (délai allongé)" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.lent>=1&&j.lent<=6')" "true"
assert_eq "N2.1 — arrêt : aucune requête entre 5 s et 9 s" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.tard')" "0"
assert_has "N2.2 — un message dit que le cockpit ne répond plus" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.banniere')" "ne répond plus"
assert_has "N2.3 — le message porte le bouton « Réessayer »" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.banniere')" "Réessayer"
assert_eq "N3.1 — « Réessayer » relance le sondage" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.apresClic>=2')" "true"
echo "=== N4 — témoin rouge : le module d'avant (la page ne ferme pas son flux : le navigateur réessaie seul, chaque seconde) ==="
LABM="$WORK/lab-mutant"; cp -R "$LAB" "$LABM"; MP="$LABM/.vibeflow/cockpit/project.html"
assert_eq "N4.0 — le mutant retire bien la fermeture du flux coupé et son inscription au sondage (motif présent avant, absent après)" "$(before=$(grep -c "es.onerror = () => { es.close(); perdu('direct', connecter); };" "$MP"); sed -i.bak "s#es.onerror = () => { es.close(); perdu('direct', connecter); };#es.onerror = () => {}; /* mutant N4 */#" "$MP"; echo "$before,$(grep -c "es.onerror = () => { es.close(); perdu('direct', connecter); };" "$MP")")" "1,0"
RM="$(reco "$LABM" project.html)"
assert_eq "N4.1 — témoin rouge : sans le recul, des requêtes continuent entre 5 s et 9 s (N2.1 rougirait)" "$(printf '%s' "$RM" | node "$AUX/ev.mjs" '!j.erreur && j.tard>0')" "true"

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
