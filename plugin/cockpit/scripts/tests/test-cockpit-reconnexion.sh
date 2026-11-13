#!/usr/bin/env bash
# test-cockpit-reconnexion.sh — E-6 (CKPT-05) : un serveur arrêté ne fait pas tourner la page à 2 requêtes par seconde sans fin.
#   N1 recul : requêtes rapides, puis espacées · N2 arrêt : plus aucune requête après le délai, avec un message et un bouton « Réessayer »
#   N3 « Réessayer » relance le sondage · N4 témoin rouge : le module d'avant (le navigateur réessaie seul, chaque seconde, pour son flux — la page n'en ouvre plus qu'un, AUDC-H1)
#   RV perte relayée et vol de verrou (navigateur simulé, jouée même sans Chrome) · N5 deux onglets, serveur arrêté (Chrome) (79-14)
# Les délais sont raccourcis par la page (window.__vfLive.reco) : 200 ms jusqu'à 1,5 s, 600 ms, arrêt à 4 s. Chrome headless ; sans navigateur la suite est SAUTÉE.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"; ENG="$SCRIPTS/../skills/cockpit-moteur"
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
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

F69="$ENG/assets/ui/69-vf-flux.js"
echo "=== RV — perte relayée et reprise d'un élu muet par vol de verrou (navigateur simulé, sans Chrome) ==="
RP="$(node "$HERE_T/flux-veille.mjs" "$F69" perdu)"; RO="$(node "$HERE_T/flux-veille.mjs" "$F69" vol)"; RS="$(node "$HERE_T/flux-veille.mjs" "$F69" sain)"
J1() { printf '%s' "$RP" | node "$AUX/ev.mjs" "$1"; }; J2() { printf '%s' "$RO" | node "$AUX/ev.mjs" "$1"; }; J3() { printf '%s' "$RS" | node "$AUX/ev.mjs" "$1"; }
assert_eq "RV1 — la perte du flux de l'élu : connexion perdu, un message perdu posté, les suiveurs coupés sans attendre 45 s, la mémoire de rejeu vidée" "$(J1 '[j.eluConn, j.eluPertes, j.messagePerdu, j.suivConn, j.suivPertes, j.ms < 45000, j.memoireVidee].join()')" "perdu,1,1,perdu,perdu,1,1,true,true"
assert_eq "RV2 — élu gelé : un suiveur rouvre sa source, interroge l'élu, vole le verrou après le délai, construit un flux au jeton de SA page (un seul flux de plus)" "$(J2 '[j.apresVol.vols, j.apresVol.avantDelai, j.apresVol.elus, j.apresVol.fluxOuverts, j.urlJeton].join()')" "1,0,1,2,true"
assert_eq "RV2.2 — l'ancien élu dégelé apprend l'abandon (AbortError), ferme son flux et redevient suiveur : un seul flux ouvert" "$(J2 '[j.ancien.role, j.ancien.fluxOuverts, j.ancien.fluxAncienFerme].join()')" "suiveur,1,true"
assert_eq "RV3 — élu qui répond (suiveur sourd seulement) : jamais volé, un seul flux, un seul élu" "$(J3 '[j.vols, j.elus, j.fluxOuverts, j.suiveur].join()')" "0,1,1,suiveur"
assert_eq "RV4 — cinq suiveurs d'un élu gelé : une seule prise de verrou (la gigue étale les demandes, le flux du premier arrive avant les autres)" "$(J2 'j.apresVol.vols')" "1"
assert_eq "RV5 — le suiveur qui a volé relaie : tous les autres onglets reçoivent" "$(J2 'j.relais')" "true"
if [ -z "$CHROME" ]; then
  . "$(dirname "$0")/chrome-saut.sh"; vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur — la reconnexion à recul n'est PAS vérifiée, non comptée comme réussie"
  vf_hyg_assert; echo ""; echo "  Résultats : $PASS PASS / $FAIL FAIL"; [ "$FAIL" -eq 0 ]; exit $?
fi
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
# 79-16 : le module d'avant est une COPIE DU MODULE dont la source de page (ui/*.js) perd la fermeture du flux coupé ; la sortie du lab ne porte que des données
MOTIF="es.onerror = () => { es.close(); perdu('direct', connecter); };"
n4_pages() { local a="$1/skills/cockpit-moteur/assets"; cat "$a/viewer.html" "$a"/ui/*.js | grep -cF "$MOTIF" || true; }
cockpit_module_muter_page n4 "s#es.onerror = () => { es.close(); perdu('direct', connecter); };#es.onerror = () => {}; /* mutant N4 */#"; MN4="${COCKPIT_MODULE:-}"
assert_eq "N4.0 — le mutant retire bien la fermeture du flux coupé et son inscription au sondage (motif présent avant, absent après)" "$(n4_pages "$(cd "$SCRIPTS/.." && pwd)"),$([ -n "$MN4" ] && n4_pages "$MN4" || echo ?)" "1,0"
RM="$(COCKPIT_MODULE="$MN4" reco "$LAB" project.html)"; unset COCKPIT_MODULE
assert_eq "N4.1 — témoin rouge : sans le recul, des requêtes continuent entre 5 s et 9 s (N2.1 rougirait)" "$(printf '%s' "$RM" | node "$AUX/ev.mjs" '!j.erreur && j.tard>0')" "true"

echo "=== N5 — deux onglets du même lab, le serveur s'arrête : le suiveur est informé par l'élu ==="
reco2() { # le PID du serveur est celui de server.json
  local o="$1/.vibeflow/cockpit" pid; srv "$o"; pid="$VF_PID"
  local r; r="$(REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-reco-onglets.mjs" "$CHROME" "http://127.0.0.1:$SRV_PORT/" "$pid")"
  vf_hyg_kill TERM "$pid"; printf '%s\n' "$r"
}
R5="$(reco2 "$LAB")"; [ -n "${DBG:-}" ] && echo "RAW: $R5"
assert_eq "N5.0 — la mesure a eu lieu" "$(printf '%s' "$R5" | node "$AUX/ev.mjs" '!!j.erreur')" "false"
assert_eq "N5.1 — le serveur arrêté, les DEUX pastilles passent en classe off en moins de dix secondes" "$(printf '%s' "$R5" | node "$AUX/ev.mjs" 'j.tOff.every((t) => t !== null)')" "true"
assert_eq "N5.2 — le suiveur n'a construit aucun flux : il a été informé par le relais" "$(printf '%s' "$R5" | node "$AUX/ev.mjs" 'j.roles.slice().sort().join() + "," + j.fluxSuiveur')" "elu,suiveur,0"
assert_eq "N5.3 — chaque onglet sonde (au moins un sondage)" "$(printf '%s' "$R5" | node "$AUX/ev.mjs" 'j.sondages.every((n) => n >= 1)')" "true"
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
