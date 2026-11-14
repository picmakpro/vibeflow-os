#!/usr/bin/env bash
# test-cockpit-direct-coupe.sh — AUDC-M9 (lot 0 de l'audit du cockpit) : une coupure du direct se dit à temps, puis la bannière se retire seule.
#   C1 à 5,5 s de la coupure la pastille dit « Direct coupé » (classe, libellé, infobulle), sans bannière
#   C1b avec un agent actif la coupure l'emporte sur « au travail » (classe, pulsation)
#   C2 la bannière n'arrive pas avant 13 s et arrive à 15 s environ (avant : à 300 s)
#   C3 au retour du réseau la bannière se retire seule (avant : elle restait jusqu'à un clic) et le flux est rouvert une fois
#   DV veille de 45 s par instants (navigateur simulé, jouée même sans Chrome) · S1 la même veille dans Chrome, horloge décalée de l'extérieur (79-14)
# Coupure simulée dans le navigateur (réseau hors ligne + perte du flux signalée à la page), sur les trois onglets. Chrome headless ;
# sans navigateur la suite est SAUTÉE hors CI, et ÉCHOUE en CI (jamais un vert à vide).
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
  local o="$1" lab; lab="$(cd "$1/../.." && pwd)"
  COCKPIT_SORTIE="$o" cockpit_lancer "$lab" VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS"
  SRV_PORT="${VF_PORT:-0}"; SRV_REAL="${VF_PID:-0}"
}
mesure() { # mesure <lab> <page> -> JSON sur la sortie ; arrête le serveur ensuite
  local o="$1/.vibeflow/cockpit"; srv "$o"
  local r; r="$(REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-direct-coupe.mjs" "$CHROME" "http://127.0.0.1:$SRV_PORT/$2")"
  vf_hyg_kill TERM "$SRV_REAL"
  printf '%s\n' "$r"
}
F69="$ENG/assets/ui/69-vf-flux.js"
echo "=== DV — veille de 45 s par instants (navigateur simulé, sans Chrome) ==="
R="$(node "$HERE_T/flux-veille.mjs" "$F69" veille)"; JV() { printf '%s' "$R" | node "$AUX/ev.mjs" "$1"; }
assert_eq "DV1.1 — écarts de 44 999 ms et de 45 000 ms exactement : pas perdu (au passage de la minuterie)" "$(JV '[j.ecart44999.apres, j.ecart44999.conn, j.ecart45000.apres, j.ecart45000.conn].join()')" "0,ouvert,0,ouvert"
assert_eq "DV1.2 — écarts de 45 001 ms et de plus de 90 000 ms : perdu, une seule déclaration, connexion perdu" "$(JV '[j.ecart45001.apres, j.ecart45001.conn, j.ecart90001.apres, j.ecart90001.conn].join()')" "1,perdu,1,perdu"
assert_eq "DV1.3 — minuterie d'une seconde : pas perdu à 45 000 ms, perdu à 46 000 ms" "$(JV 'j.regulier.a45000 + "," + j.regulier.a46000 + "," + j.regulier.conn')" "0,1,perdu"
assert_eq "DV1.4 — un flux sain dont seul le battement vie arrive toutes les 15 s n'est jamais déclaré perdu" "$(JV 'j.vieSeule.sansPerte + "," + j.vieSeule.conn')" "true,ouvert"
assert_eq "DV2.1 — minuterie ralentie à 60 s : perte déclarée au premier passage (un compteur de passages ne le ferait pas)" "$(JV 'j.ralenti.avant + "," + j.ralenti.auPremierPassage')" "0,1"
assert_eq "DV2.2 — le retour de visibilité contrôle immédiatement (aucune perte à l'arrière-plan sans passage, perte au retour)" "$(JV 'j.visibilite.avant + "," + j.visibilite.cache + "," + j.visibilite.apresRetour')" "0,0,1"
assert_eq "DV3 — un recul d'horloge d'une heure ne cause aucune perte tant que les événements continuent ; le silence qui suit est compté depuis le premier passage" "$(JV 'j.recul.sansPerteEnVie + "," + (j.recul.secondesAvantPerte >= 45 && j.recul.secondesAvantPerte <= 48)')" "true,true"
assert_eq "DV5 — sans setInterval : aucune exception, aucune minuterie vivante" "$(JV 'j.sansMinuterie.minuteurs + "," + j.sansMinuterie.pertes + "," + j.sansMinuterieLeve')" "0,0,false"
if [ -z "$CHROME" ]; then
  . "$(dirname "$0")/chrome-saut.sh"; vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur — la coupure du direct dans Chrome n'est PAS vérifiée, non compté comme réussi"
  vf_hyg_assert; echo ""; echo "  Résultats : $PASS PASS / $FAIL FAIL"; [ "$FAIL" -eq 0 ]; exit $?
fi
LAB="$WORK/lab"; mklab "$LAB"
for PAGE in project.html ""; do
  echo "=== coupure simulée — page /${PAGE} ==="
  R="$(mesure "$LAB" "$PAGE")"; [ -n "${DBG:-}" ] && echo "RAW: $R"
  assert_eq "C0 — la mesure a eu lieu (/${PAGE})" "$(printf '%s' "$R" | node "$AUX/ev.mjs" '!!j.erreur')" "false"
  assert_eq "C1.1 — à 5,5 s la pastille est en classe « off » (/${PAGE})" "$(printf '%s' "$R" | node "$AUX/ev.mjs" '/(^| )off( |$)/.test(j.a5.cls)')" "true"
  assert_eq "C1.2 — à 5,5 s le libellé dit « Direct coupé » (/${PAGE})" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.a5.txt')" "Direct coupé"
  assert_eq "C1.3 — à 5,5 s l'infobulle dit que le serveur ne répond pas, sans bannière (/${PAGE})" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.a5.title + "|" + j.a5.banniere')" "Le serveur du cockpit ne répond pas|false"
  assert_eq "C1.4 — témoin : avec un agent actif la pastille est « held » avant la coupure (/${PAGE})" "$(printf '%s' "$R" | node "$AUX/ev.mjs" '/(^| )held( |$)/.test(j.avantCoupure.cls) && j.avantCoupure.pulse !== "none"')" "true"
  assert_eq "C1.5 — avec un agent actif, la coupure l'emporte : classe « off », plus « held », plus de pulsation (/${PAGE})" "$(printf '%s' "$R" | node "$AUX/ev.mjs" '/(^| )off( |$)/.test(j.a5.cls) && !/held/.test(j.a5.cls) && j.a5.pulse === "none"')" "true"
  assert_eq "C2.1 — pas de bannière avant 13 s (/${PAGE})" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.avant13.banniere')" "false"
  assert_eq "C2.2 — la bannière arrive entre 13 s et 18 s (/${PAGE})" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.tBanniere !== null && j.tBanniere >= 13000 && j.tBanniere <= 18000')" "true"
  assert_eq "C3.1 — au retour du réseau la bannière se retire seule en moins de 8 s (/${PAGE})" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.tBanniere !== null && j.tRetrait !== null')" "true"
  assert_eq "C3.2 — le flux est rouvert une seule fois (/${PAGE})" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.reouvert')" "1"
done
echo "=== S1 — silence du flux, horloge de la page décalée de l'extérieur (Chrome) ==="
silence() { # silence <scénario> -> JSON ; un serveur par mesure, arrêté ensuite
  local o="$LAB/.vibeflow/cockpit"; srv "$o"
  local r; r="$(REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-silence.mjs" "$CHROME" "http://127.0.0.1:$SRV_PORT/" "$1")"
  vf_hyg_kill TERM "$SRV_REAL"; printf '%s\n' "$r"
}
R="$(silence muet)"; [ -n "${DBG:-}" ] && echo "RAW: $R"
assert_eq "S1.0 — la mesure a eu lieu" "$(printf '%s' "$R" | node "$AUX/ev.mjs" '!!j.erreur')" "false"
assert_eq "S1.1 — avant le silence la pastille n'est pas « coupé » et la connexion vaut ouvert" "$(printf '%s' "$R" | node "$AUX/ev.mjs" '!j.avant.off + "," + j.avant.conn')" "true,ouvert"
assert_eq "S1.2 — silence de 44 s : toujours pas coupé" "$(printf '%s' "$R" | node "$AUX/ev.mjs" '!j.a44.off + "," + j.a44.conn')" "true,ouvert"
assert_eq "S1.3 — silence de 46 s : la pastille dit « Direct coupé » en moins de 8 s réelles, connexion perdu" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.a46.off + "," + j.a46.txt + "," + j.a46.conn + "," + (j.tCoupe !== null && j.tCoupe < 8000)')" "true,Direct coupé,perdu,true"
assert_eq "S1.4 — le silence levé : le flux est rouvert (au moins une seconde construction), la pastille quitte off, connexion ouvert" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.reouvert')" "true"
R="$(silence sain)"; [ -n "${DBG:-}" ] && echo "RAW: $R"
assert_eq "S1.5 — flux sain : un vie du vrai serveur reçu en 18 s, la pastille n'est jamais passée en off" "$(printf '%s' "$R" | node "$AUX/ev.mjs" '(j.vie >= 1) + "," + j.jamaisOff')" "true,true"
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ "$FAIL" -eq 0 ]
