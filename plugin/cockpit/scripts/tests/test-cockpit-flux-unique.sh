#!/usr/bin/env bash
# test-cockpit-flux-unique.sh — AUDC-H1 (lot 0) puis SOCL-18 (79-14, P79-D-14, C4) : les onglets d'un même lab ne tiennent qu'UN flux d'événements.
#   FU0 la mesure a eu lieu · FU1 un seul EventSource construit pour tous les onglets, au chemin /api/vf/events
#   FU2 le serveur compte un seul flux (/api/status tabs et /api/vf/etat clients valent 1), le dernier onglet lit /api/vf/state en 200,
#       un onglet élu et les autres suiveurs, un `who` émis sur le flux de l'élu atteint tous les onglets, aucune violation de CSP
#   FU3 l'élu fermé, un autre onglet reprend sans rechargement (reprise puis ouvert, jeton de sa page, un seul flux compté)
#   FU4 le rechargement automatique (la carte est reconstruite) passe par le flux partagé : tous les onglets restants se rechargent seuls
# Chrome headless ; sans navigateur la suite est SAUTÉE hors CI, et ÉCHOUE en CI (jamais un vert à vide).
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
F69="$ENG/assets/ui/69-vf-flux.js"
FV() { node "$HERE_T/flux-scenarios.mjs" "$F69" "$1"; } # une ligne JSON par scénario du navigateur simulé
echo "=== FV — relais, jeton, lab, repli, rejeu, interface, entrées du canal (navigateur simulé, sans Chrome) ==="
R="$(FV election)"
assert_eq "FV1.1 — sept onglets du même lab : un seul flux construit, un élu et six suiveurs" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.flux + ":" + j.roles.slice().sort().join()')" "1:elu,suiveur,suiveur,suiveur,suiveur,suiveur,suiveur"
assert_eq "FV1.2 — chaque événement de la liste est livré une fois à chacun des sept, dans l'ordre d'émission" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.nbNoms + ":" + j.unique + ":" + j.dansLOrdre')" "11:true:true"
R="$(FV reprise)"
assert_eq "FV2.1 — l'élu fermé : un seul nouvel élu, un flux de plus au jeton de SA page, reprise puis ouvert, les restants servis, aucun rechargement" "$(printf '%s' "$R" | node "$AUX/ev.mjs" '[j.apres.elus, j.apres.fluxTotal, j.apres.urlJeton, j.apres.conns, j.apres.servis, j.apres.rechargements].join()')" "1,2,true,reprise,ouvert,true,0"
assert_eq "FV2.2 — un suiveur fermé : rien ne change (un flux, un élu)" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.avant.flux + "," + j.apresSuiveur.flux + "," + j.apresSuiveur.elus')" "1,1,1"
assert_eq "FV2.3 — fermetures successives de l'élu : le dernier onglet est seul élu" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.finale + ":" + j.restantsFinal')" "elu:1"
R="$(FV jeton)"
assert_eq "FV3.1 — aucun message du canal ne porte un jeton (témoin positif : les jetons sont dans les adresses de flux et les en-têtes de lecture)" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.aucunJeton + ":" + j.temoin')" "true:true"
assert_eq "FV3.2 — une charge qui contient le jeton de l'élu n'est pas relayée mais livrée à l'onglet qui l'a reçue ; le relais continue ensuite" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.nonRelaye + ":" + j.relaiEncore')" "true:true"
R="$(FV lab)"
assert_eq "FV4.1 — deux labs sur la même origine : un canal suffixé de l'empreinte par lab, deux flux, deux élus" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.flux + ":" + j.elus + ":" + j.suffixes + ":" + j.canaux.length')" "2:2:true:2"
assert_eq "FV4.2 — les onglets de deux empreintes ne s'échangent rien" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.chezA + ":" + j.chezB')" "true:true"
R="$(FV repli)"
assert_eq "FV5 — sans verrous, sans canal, hors contexte sûr, empreinte illisible, en erreur HTTP, mal formée ou en majuscules : un flux par page, aucun message, livraison locale" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'Object.values(j).every((c) => c.roles === "page,page" && c.flux === 2 && c.messages === 0 && c.local)')" "true"
R="$(FV rejeu)"
assert_eq "FV6.1 — un onglet tardif reçoit hello, lock, who rejoués une fois chacun (le who périmé non rejoué), marqués rejeu et relayé, sans doublon chez les autres" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.rejoues.join("|") + ":" + j.meta + ":" + j.sansDoublon')" 'hello:{"seq":1}|lock:{"l":1}|who:{"w":2}:[["hello",true,true],["lock",true,true],["who",true,true]]:true'
assert_eq "FV6.2 — la perte du flux vide la mémoire : un onglet tardif ne reçoit rien" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.memoireVideeAPerte')" "true"
assert_eq "FV6.3 — une source rouverte dans le même onglet reçoit l'état connu et l'ancienne ne reçoit plus rien" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.apresReouverture.length + ":" + j.ancienne + ":" + j.nouvelle')" "3:0:true"
R="$(FV api)"
assert_eq "FV8.1 — ecouter : RangeError sur un nom inconnu, TypeError sur un rappel qui n'en est pas un" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.inconnu + "," + j.typeRappel')" "RangeError,TypeError"
assert_eq "FV8.2 — ordre d'inscription, exception d'un rappel isolée, désinscription" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.ordre + "|" + j.apresDesinscription + "|" + j.isolation')" "1,3|1,3,3|ok"
assert_eq "FV8.3 — l'objet VF_FLUX et sa liste sont gelés, le diagnostic ne porte aucun jeton, la liste est celle des onze événements (79-15 : graphe entre frise et git)" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.gele + ":" + j.sansJeton + ":" + j.noms')" "true:true:etat,frise,graphe,git,hello,lock,patch,reload,structural,vie,who"
R="$(FV entree)"
assert_eq "FV7.1 — les classes hostiles du canal sont refusées, les messages conformes livrés (aucune exception, aucun cas hors oracle)" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.nbCas + ":" + JSON.stringify(j.ko)')" "37:[]"
assert_eq "FV7.2 — le compteur des refus augmente exactement du nombre de messages refusés" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.refusesTotal === j.attendus')" "true"
assert_eq "FV7.5 — la liste des cinq clés interdites de la page est celle du contrat cockpit-who@2 (témoin de dérive)" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.derive')" "true"
if [ -z "$CHROME" ]; then
  . "$(dirname "$0")/chrome-saut.sh"; vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur — le flux unique dans Chrome n'est PAS vérifié, non compté comme réussi"
  vf_hyg_assert; echo ""; echo "  Résultats : $PASS PASS / $FAIL FAIL"; [ "$FAIL" -eq 0 ]; exit $?
fi
mesure() { # mesure <lab> <nombre d'onglets> <scénario> -> JSON sur la sortie ; arrête le serveur ensuite
  local o="$1/.vibeflow/cockpit"; srv "$o"
  local r; r="$(REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-flux-unique.mjs" "$CHROME" "$SRV_PORT" "$o/index.html" "$2" "$3")"
  vf_hyg_kill TERM "$SRV_REAL"
  printf '%s\n' "$r"
}
LAB="$WORK/lab"; mklab "$LAB"
echo "=== FU — sept onglets du même lab (Code, Projet, Équipe), un seul flux ==="
R="$(mesure "$LAB" "${FLUX_ONGLETS:-7}" complet)"; [ -n "${DBG:-}" ] && echo "RAW: $R"
J() { printf '%s' "$R" | node "$AUX/ev.mjs" "$1"; }
assert_eq "FU0 — la mesure a eu lieu" "$(J '!!j.erreur')" "false"
assert_eq "FU1 — un seul EventSource construit par les sept onglets, au chemin du direct" "$(J 'j.fluxParOnglet.flat()')" '["/api/vf/events"]'
assert_eq "FU2.1 — les sept onglets chargent (plafond de six connexions franchi) et leur rôle est résolu" "$(J 'j.charges.length + ":" + j.charges.every(Boolean) + ":" + j.pret')" "7:true:true"
assert_eq "FU2.2 — le serveur compte un seul flux (tabs et clients valent 1)" "$(J 'j.tabs + "," + j.clients')" "1,1"
assert_eq "FU2.3 — le septième onglet lit /api/vf/state en 200 en moins de 2 s" "$(J 'j.etat200 && j.msEtat < 2000')" "true"
assert_eq "FU2.4 — un onglet élu, six onglets suiveurs" "$(J 'j.roles.slice().sort().join()')" "elu,suiveur,suiveur,suiveur,suiveur,suiveur,suiveur"
assert_eq "FU2.5 — un who émis sur le flux de l'élu atteint les sept onglets" "$(J 'j.whoAtteint')" "true"
assert_eq "FU2.6 — aucune violation de CSP relevée" "$(J 'j.violations')" "0"
assert_eq "FU3.1 — l'élu fermé, un autre onglet devient élu en moins de 10 s, aucun marqueur de page n'a disparu (aucun rechargement)" "$(J 'j.reprise.nouvelElu + ":" + j.reprise.marqueursIntacts + ":" + j.reprise.rolesApres.filter((r) => r === "elu").length')" "true:true:1"
assert_eq "FU3.2 — la connexion du nouvel élu passe par reprise puis ouvert" "$(J 'j.reprise.suite')" "reprise,ouvert"
assert_eq "FU3.3 — le serveur compte toujours un flux après la reprise" "$(J 'j.reprise.tabs + "," + j.reprise.clients')" "1,1"
assert_eq "FU3.4 — le flux du nouvel élu porte le jeton de SA page" "$(J 'j.reprise.jetonPropre')" "true"
assert_eq "FU3.5 — un who émis sur le flux du nouvel élu atteint les autres onglets restants" "$(J 'j.reprise.whoAtteint')" "true"
assert_eq "FU4 — la carte reconstruite recharge tous les onglets restants par le flux partagé, puis le serveur recompte un flux" "$(J 'j.rechargees + ":" + j.nbVivants + ":" + j.tabsApres + "," + j.clientsApres')" "6:6:1,1"
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ "$FAIL" -eq 0 ]
