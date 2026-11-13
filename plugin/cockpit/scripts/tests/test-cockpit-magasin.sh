#!/usr/bin/env bash
# test-cockpit-magasin.sh — SOCL-21 (79-17, C4, A13) : le magasin d'état de la page, window.VF_ETAT.
#   A  l'API (clés fermées, abonnement, ordre, isolation, gel)           F  l'alimentation par le flux partagé (hello, who, lock, git, graphe, planning, connexion)
#   L  les lectures d'état et de frise (une requête en vol, un rattrapage) J  jeton et lecture JSON bornée aux routes de l'API
#   K  (Chrome) un who et un changement de planning, du flux à l'écran    C  (Chrome) la vie à travers six changements d'onglet
#   O  le cliquet des observateurs de mutations, par fichier de ui/         R  les observateurs de réparation retirés
# A, F, L, J, O, R sans navigateur ; K et C dans Chrome headless : sans navigateur elles sont SAUTÉES hors CI et ÉCHOUENT en CI (jamais un vert à vide).
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
UI="$ENG/assets/ui"; STORE="$UI/70-vf-etat.js"
VM() { node "$HERE_T/magasin-vm.mjs" "$STORE" "$1"; }
J() { printf '%s' "$R" | node "$AUX/ev.mjs" "$1"; }

echo "=== A — l'API : huit clés fermées, abonnement, ordre, isolation, gel ==="
R="$(VM api)"
assert_eq "A0 — témoin : le scénario s'exécute (aucune erreur)" "$(J '!!j.erreur')" "false"
assert_eq "A1 — avant la première réception, lire rend null pour les huit clés, dans l'ordre alphabétique de CLES" "$(J 'j.A1')" "true"
assert_eq "A2 — une clé inconnue (__proto__, constructor, toString, vide, un nombre, null) : RangeError à la lecture et à l'abonnement" "$(J 'j.A2.join()')" "RangeError/RangeError,RangeError/RangeError,RangeError/RangeError,RangeError/RangeError,RangeError/RangeError,RangeError/RangeError"
assert_eq "A2b — les huit clés restent intactes après ces essais" "$(J 'j.A2b')" "true"
assert_eq "A3 — un rappel qui n'est pas une fonction : TypeError" "$(J 'j.A3.join()')" "TypeError,TypeError,TypeError"
assert_eq "A4 — trois abonnés d'une clé : appelés dans l'ordre d'inscription, une fois chacun" "$(J 'j.A4')" "1,2,3"
assert_eq "A5 — la désinscription arrête les appels et est idempotente" "$(J 'j.A5')" "1"
assert_eq "A5b — un abonné désinscrit avant son tour (par un abonné précédent) n'est pas appelé" "$(J 'j.A5b')" "a"
assert_eq "A6 — un abonné inscrit pendant une notification n'est appelé qu'aux suivantes" "$(J 'j.A6')" "p|p,p,n"
assert_eq "A7 — un rappel qui lève : les autres sont appelés, la valeur est lue, une seule ligne d'erreur" "$(J 'j.A7')" "2|2|1"
assert_eq "A8 — abonnes() compte les inscriptions vivantes des huit clés" "$(J 'j.A8')" "true,1,3,2"
assert_eq "A8b — la désinscription ramène le compte" "$(J 'j.A8b')" "true"
assert_eq "A9 — un second chargement garde l'objet, l'état et les abonnements" "$(J 'j.A9')" "true,true,1"
assert_eq "A10 — l'objet et CLES sont gelés, rien ne s'y réécrit" "$(J 'j.A10')" "true,true,function"
assert_eq "A11 — hors page de serveur (ni flux ni serveur) : l'objet existe, tout est null, jeton null, rien ne lève" "$(J 'j.A11')" "true,,aucune"
assert_eq "A11b — sans flux : lire rend null sans lever" "$(J 'j.A11b')" "aucune"

echo "=== F — l'alimentation par le flux partagé ==="
R="$(VM alimentation)"
assert_eq "F0 — témoin : le scénario s'exécute (aucune erreur)" "$(J '!!j.erreur')" "false"
assert_eq "F1 — hello : who, lock, connexion « ouvert », état lu par la route (seq 3), une seule notification de connexion" "$(J 'j.F1')" "ouvert,who,lock,3,true,1"
assert_eq "F2 — hello sans who (avant la première collecte) : who reste null, lock garde sa forme" "$(J 'j.F2')" ',"absente"'
assert_eq "F3 — who : la clé égale l'objet who de la charge" "$(J 'j.F3')" "true"
assert_eq "F4 — lock : la clé égale la charge { seq, at, verrous }" "$(J 'j.F4')" "true"
assert_eq "F5 — git : { seq, at, sig }" "$(J 'j.F5')" '{"seq":6,"at":6,"sig":"abc"}'
assert_eq "F6 — graphe : le dernier événement, deux onglets d'affilée donnent deux notifications" "$(J 'j.F6')" "2,projet"
assert_eq "F7 — structural : planning égale { seq, at }, at numérique même si la charge n'en porte pas" "$(J 'j.F7')" "9,number,at,seq"
assert_eq "F8 — perte, reprise, retour : chaque transition notifie une fois (une répétition ne notifie pas)" "$(J 'j.F8')" "perdu,reprise,ouvert|ouvert"
assert_eq "F9 — une charge mal formée (non objet, champ absent, nombres hors bornes) est ignorée sans lever, sans notifier" "$(J 'j.F9')" "aucune,true,true"
assert_eq "F10 — vie, patch, reload : aucune clé touchée" "$(J 'j.F10')" "true"

echo "=== L — les lectures d'état et de frise ==="
R="$(VM lectures)"
assert_eq "L0 — témoin : le scénario s'exécute (aucune erreur)" "$(J '!!j.erreur')" "false"
assert_eq "L1 — état lu au hello puis à chaque événement etat, par /api/vf/state seulement" "$(J 'j.L1')" "1,2,2,true"
assert_eq "L2 — réponse hors schéma, seq non numérique, null, nombre, 503 : la clé garde sa valeur, aucune relance" "$(J 'j.L2')" "5,6,6"
assert_eq "L3 — dix événements pendant une lecture : une seule lecture de rattrapage, la dernière valeur vient d'elle" "$(J 'j.L3')" "1,2,2,200"
assert_eq "L4 — frise : aucune lecture sans inscription, une à la première inscription, une par événement avec inscription, périmée sans inscription puis relue à la réinscription" "$(J 'j.L4')" "0,1,2,2,3,lue"
assert_eq "L5 — la reprise relit l'état et la frise (inscrite) au hello suivant" "$(J 'j.L5')" "3,5,3"
assert_eq "L6 — une lecture qui rejette ne laisse aucune promesse non gérée et garde la clé vide" "$(J 'j.L6')" "0,"

echo "=== J — jeton et lecture JSON bornée aux routes de l'API ==="
R="$(VM json)"
assert_eq "J0 — témoin : le scénario s'exécute (aucune erreur)" "$(J '!!j.erreur')" "false"
assert_eq "J1 — jeton() suit VF_COCKPIT_SERVER.token à chaque appel" "$(J 'j.J1')" "jeton-synthetique-1,jeton-synthetique-2"
assert_eq "J2 — la requête : GET, en-tête x-vf-cockpit-token, cache no-store, redirection refusée, aucun corps" "$(J 'j.J2')" "/api/vf/state|GET|jeton-synthetique-2|no-store|error|false|cache,headers,method,redirect"
assert_eq "J3 — les routes réelles sont acceptées (neuf requêtes)" "$(J 'j.J3')" "true:9"
assert_eq "J4 — les chemins hostiles sont refusés (statut 0) sans aucune requête" "$(J 'j.J4')" "22,22,0"
assert_eq "J5 — statut 403, 404, 500 : rejet portant le statut, jamais le corps" "$(J 'j.J5')" "403:false,404:false,500:false"
assert_eq "J6 — erreur réseau : statut 0, message sans la cause" "$(J 'j.J6')" "0:false"
assert_eq "J7 — JSON invalide : statut -1" "$(J 'j.J7')" "-1"
assert_eq "J8 — jeton null : refus sans requête" "$(J 'j.J8')" "0:0"
assert_eq "J9 — aucun jeton dans une valeur du magasin ni dans le journal" "$(J 'j.J9')" "true"

echo "=== forme du fichier du magasin (R1, R9) ==="
G() { rtk proxy grep -c "$@" "$STORE" 2>/dev/null; }
assert_eq "S1 — moins de 300 lignes, aucune ligne de plus de 160 colonnes" "$(awk 'END{print NR}' "$STORE" 2>/dev/null | awk '{print ($1 < 300 && $1 > 0)}')|$(awk 'length > 160' "$STORE" 2>/dev/null | awk 'END{print NR}')" "1|0"
assert_eq "S2 — persistant : le marqueur est dans les huit premières lignes" "$(head -n 8 "$STORE" 2>/dev/null | rtk proxy grep -c 'vf-coquille: persistant')" "1"
assert_eq "S3 — aucune clé ni mot de la liste interdite (doing, mandat, messages, outils, fil), commentaires compris" "$(G -w -E 'doing|mandat|messages|outils|fil')" "0"
assert_eq "S4 — ni écouteur, ni minuterie, ni observateur, ni flux, ni eval, ni Function, ni blob, ni insertion de script, ni nom du moteur" "$(G -E 'addEventListener|setInterval|setTimeout|MutationObserver|EventSource|eval|new Function|blob:|importScripts|createElement|document[.]write|Floorplan|FLOORPLAN')" "0"
assert_eq "S5 — la ligne AJOUT de VENDORED.txt" "$(rtk proxy grep -c '^AJOUT assets/ui/70-vf-etat.js$' "$ENG/VENDORED.txt")" "1"

if [ -z "$CHROME" ]; then
  . "$(dirname "$0")/chrome-saut.sh"; vf_chrome_saut "  ⊘ SECTIONS K ET C SAUTÉES : aucun navigateur — le magasin dans Chrome n'est PAS vérifié, non compté comme réussi"
else
  mklab() {
    local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle"
    printf 'export const u = () => 1;\n' > "$L/src/util.js"; printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n' > "$B/ROADMAP.md"
    printf '<objective>Faire le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"; echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
    git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
    node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
  }
  mesure() { # mesure <lab> <mode> -> JSON ; le serveur est lancé puis arrêté
    local lab="$1" o="$1/.vibeflow/cockpit"
    COCKPIT_SORTIE="$o" cockpit_lancer "$lab" VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS"
    local port="${VF_PORT:-0}" pid="${VF_PID:-0}" r
    r="$(REAL_HOME="$REAL_HOME" VF_CDP_ECHEANCE_MS="${VF_CDP_ECHEANCE_MS:-45000}" node "$HERE_T/magasin-chrome.mjs" "$CHROME" "$port" "$lab" "$2")"
    vf_hyg_stop "$pid"
    printf '%s\n' "$port|$r"
  }
  echo "=== K — un who et un changement de planning, du flux à l'écran (Chrome, serveur réel) ==="
  LAB="$WORK/lab-k"; mklab "$LAB"; RK="$(mesure "$LAB" tracer)"; R="${RK#*|}"; [ -n "${DBG:-}" ] && echo "RAW: $R"
  assert_eq "K0.1 — témoin : le serveur est prêt (port supérieur à 0)" "$([ "${RK%%|*}" -gt 0 ] && echo oui)" "oui"
  assert_eq "K0.2 — témoin : la page se charge et le moteur est rendu" "$(J 'j.erreur || j.k02')" "true"
  assert_eq "K0.3 — témoin de la sonde : l'enveloppe voit un flux /api/vf/events" "$(J 'j.k03')" "true"
  assert_eq "K0.4 — A30 : l'objet du moteur est gelé et ne porte ni VF_ETAT, ni lire, ni abonner, ni jeton, ni lireJson" "$(J 'j.k04')" "[true,false]"
  assert_eq "K0.5 — A40 : /_vf/ui/70-vf-etat.js répond 200 avec un ETag, est dans le manifeste, n'est pas en ligne, aucune violation de CSP" "$(J 'JSON.stringify(j.k05)')" '{"statut":200,"etag":true,"manifeste":true,"enLigne":false,"violations":0}'
  assert_eq "K1.1 — window.VF_ETAT est un objet gelé qui porte lire, abonner, jeton, lireJson, abonnes et huit clés" "$(J 'j.k11')" '["object",true,true,8]'
  assert_eq "K1.2 — jeton() égale VF_COCKPIT_SERVER.token" "$(J 'j.k12')" "true"
  assert_eq "K1.3 — après le hello du serveur réel : connexion ouvert, état cockpit-state@1 de seq numérique, lu par la route" "$(J 'j.k13')" '["ouvert","vibeflow/cockpit-state@1","number",true]'
  assert_eq "K1.4 — un who livré : le magasin lui est égal, la pastille dit « 1 au travail », l'abonné de la sonde reçoit exactement une notification" "$(J 'j.k14')" '[true,"1 au travail",1]'
  assert_eq "K1.5 — un plan ajouté au lab : la clé planning avance, { seq, at } avec at numérique (la page Code ne se recharge pas)" "$(J 'j.k15')" '[true,"number","at,seq"]'
  assert_eq "K1.6 — lireJson lit /api/vf/state, refuse /api/export sans requête (statut 0), aucune erreur de page" "$(J 'j.k16')" '["vibeflow/cockpit-state@1",0,false,0]'
  echo "=== C — la vie à travers six changements d'onglet (Chrome, serveur réel) ==="
  LAB="$WORK/lab-c"; mklab "$LAB"; RC="$(mesure "$LAB" onglets)"; R="${RC#*|}"; [ -n "${DBG:-}" ] && echo "RAW: $R"
  assert_eq "C0 — témoin : la mesure a eu lieu" "$(J '!!j.erreur')" "false"
  assert_eq "C2 — six changements d'onglet (code, equipe, projet, projet, code, equipe) : abonnes() égale le compte d'un chargement à froid à chaque pas" "$(J 'j.pas.map((p) => p[0] + "=" + p[1]).join()')" "code=true,equipe=true,projet=true,projet=true,code=true,equipe=true"
  assert_eq "C3 — la pastille d'un onglet neuf dit « 1 au travail » sans nouvel événement (lue dans le magasin au chargement)" "$(J 'j.badge')" "1 au travail"
  assert_eq "C5 — le magasin n'a pas été ré-exécuté et la page n'a pas été rechargée : l'origine des temps est la même, la valeur de who lue avant les changements d'onglet est gardée" "$(J 'j.memeObjet')" "true"
  assert_eq "C4.1 — une perte de connexion pose perdu et la pastille dit « Direct coupé »" "$(J 'j.perdu')" "Direct coupé"
  assert_eq "C4.2 — le retour pose ouvert, la pastille n'est plus « Direct coupé » et dit l'état que le serveur redonne au hello (personne : le who d'essai n'est pas le sien)" "$(J 'j.retour.join("|")')" "ouvert|Personne"
fi

echo "=== O — le cliquet des observateurs de mutations, par fichier de ui/ ==="
CLQ="$HERE_T/observateurs-cliquet.mjs"; BASE="$HERE_T/observateurs-baseline.txt"
cq() { node "$CLQ" "$@" 2>&1; echo "rc=$?"; }
assert_eq "O1.1 — le vrai dossier ui/ contre la baseline versionnée : conforme (code 0)" "$(cq juger "$UI" "$BASE" | tail -1)" "rc=0"
assert_eq "O1.2 — le total mesuré sur le vrai dossier égale la somme de la baseline, et il y a au moins un fichier mesuré" "$(awk '!/^#/ && NF==2 {t+=$2; n++} END{print (n > 0 ? "t=" t " n=" n : "vide")}' "$BASE" 2>/dev/null)" "$(node "$CLQ" mesurer "$UI" 2>/dev/null | awk '{t+=$2; n++} END{print (n > 0 ? "t=" t " n=" n : "vide")}')"
FX="$WORK/cliquet"; mkdir -p "$FX/ui"; printf 'const a = 1;\n' > "$FX/ui/a.js"; printf 'new MutationObserver(() => {}).observe(document.body, {});\n' > "$FX/ui/b.js"
printf '# entête\nb.js 1\n' > "$FX/base.txt"
assert_eq "O1.3 — témoin : fixture conforme (un observateur dans b.js, baseline b.js 1) : code 0" "$(cq juger "$FX/ui" "$FX/base.txt" | tail -1)" "rc=0"
printf 'new MutationObserver(() => {});\n' > "$FX/ui/a.js"
assert_eq "O2.1 — un observateur ajouté dans un fichier à baseline 0 : HAUSSE nommant le fichier, code 1" "$(cq juger "$FX/ui" "$FX/base.txt" | rtk proxy grep -E 'HAUSSE a.js réel=1 baseline=0|rc=1' | tr '\n' ' ')" "HAUSSE a.js réel=1 baseline=0 rc=1 "
assert_eq "O2.1b — un observateur de plus dans un fichier à baseline 1 : HAUSSE" "$(printf 'new MutationObserver(() => {});\n' >> "$FX/ui/b.js"; printf 'b.js 1\n' > "$FX/b1.txt"; printf 'a.js 1\n' >> "$FX/b1.txt"; cq juger "$FX/ui" "$FX/b1.txt" | rtk proxy grep -c 'HAUSSE b.js réel=2 baseline=1')" "1"
printf 'const a = 1;\n' > "$FX/ui/a.js"; printf 'new MutationObserver(() => {}).observe(document.body, {});\n' > "$FX/ui/b.js"
printf 'a.js 3\nb.js 1\n' > "$FX/haute.txt"
assert_eq "O2.2 — une baseline au-dessus du réel : PERIMEE (a.js réel=0), code 1" "$(cq juger "$FX/ui" "$FX/haute.txt" | rtk proxy grep -E 'PERIMEE a.js réel=0 baseline=3|rc=1' | tr '\n' ' ')" "PERIMEE a.js réel=0 baseline=3 rc=1 "
assert_eq "O2.2b — abaisser réécrit la baseline au réel (b.js 1 seul) puis le verdict est conforme" "$(cq abaisser "$FX/ui" "$FX/haute.txt" | tail -1)|$(rtk proxy grep -v '^#' "$FX/haute.txt" | tr '\n' ' ')|$(cq juger "$FX/ui" "$FX/haute.txt" | tail -1)" "rc=0|b.js 1 |rc=0"
printf 'new MutationObserver(() => {});\nnew MutationObserver(() => {});\n' > "$FX/ui/c.js"; cp "$FX/haute.txt" "$FX/intacte.txt"
assert_eq "O2.3 — abaisser quand le réel monte (c.js à 2, absent de la baseline) : code 1, baseline intacte à l'octet" "$(cq abaisser "$FX/ui" "$FX/haute.txt" | tail -1)|$(cmp -s "$FX/haute.txt" "$FX/intacte.txt" && echo intacte)" "rc=1|intacte"
rm -f "$FX/ui/c.js"; printf 'b.js 1\nabsent.js 2\n' > "$FX/orph.txt"
assert_eq "O2.4 — l'entrée d'un fichier absent : ORPHELINE, code 1" "$(cq juger "$FX/ui" "$FX/orph.txt" | rtk proxy grep -E 'ORPHELINE absent.js|rc=1' | tr '\n' ' ')" "ORPHELINE absent.js baseline=2 rc=1 "
for forme in 'b.js un' 'b.js 0' '/etc/b.js 1' '../b.js 1' 'b.js 1 2' 'b.js'; do
  printf '%s\n' "$forme" > "$FX/forme.txt"
  assert_eq "O2.5 — ligne mal formée « $forme » : FORME, code 1" "$(cq juger "$FX/ui" "$FX/forme.txt" | rtk proxy grep -c -E '^FORME ligne 1 |rc=1')" "2"
done
printf '// la forme new MutationObserver(cb) dans un commentaire\n' > "$FX/ui/d.js"; printf 'b.js 1\n' > "$FX/com.txt"
assert_eq "O2.6 — un commentaire qui porte la forme compte (témoin positif de la mesure)" "$(cq juger "$FX/ui" "$FX/com.txt" | rtk proxy grep -c 'HAUSSE d.js réel=1 baseline=0')" "1"
rm -f "$FX/ui/d.js"
assert_eq "O2.7 — dossier illisible, baseline illisible, usage : code 2, jamais 0 (fermé par défaut)" "$(cq juger "$FX/nulle-part" "$FX/base.txt" | tail -1)|$(cq juger "$FX/ui" "$FX/nulle-part.txt" | tail -1)|$(cq juger | tail -1)" "rc=2|rc=2|rc=2"

echo "=== R — les observateurs de réparation retirés, un événement existant à la place de chacun ==="
A70="$UI/70-vf-live.js"; A72="$UI/72-vf-equipe.js"; A76="$UI/76-vf-git-entete.js"
n() { rtk proxy grep -c -F "$1" "$2"; }
assert_eq "R1.1 — 70 sans observateur de mutations (le panneau est reposé par l'événement panel)" "$(n 'new MutationObserver' "$A70")" "0"
assert_eq "R1.2 — 70 porte l'événement panel (ancre imposée : focus rendu, puis réponses « dernière commande » reposées)" "$(n "SC.on('panel', () => { rendreFocus(); " "$A70")|$(n "for (const b of document.querySelectorAll('#panel [data-vf-doing]')) poser(b);" "$A70")" "1|1"
assert_eq "R1.3 — 72 ne garde qu'un observateur (le garde de cadrage) et porte l'événement panel" "$(n 'new MutationObserver' "$A72")|$(n "SC.on('panel', remettre);" "$A72")" "1|1"
assert_eq "R1.4 — 76 sans observateur et deux écouteurs de vf-git:etat (l'arrêt de tabulation du titre suit l'ouverture du tiroir Git)" "$(n 'new MutationObserver' "$A76")|$(n "addEventListener('vf-git:etat'" "$A76")" "0|2"
assert_eq "R1.5 — le magasin n'est pas touché par les retraits : aucun observateur, aucun écouteur de document dans 70-vf-etat.js" "$(n 'MutationObserver' "$STORE")|$(n 'addEventListener' "$STORE")" "0|0"
assert_eq "R1.6 — les fichiers que ce plan ne touche pas gardent leur observateur sans événement source (73, 77 tiroir Git)" "$(n 'new MutationObserver' "$UI/73-vf-tiroir-travail.js")|$(n 'new MutationObserver' "$UI/77-vf-git-tiroir.js")" "1|1"

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ "$FAIL" -eq 0 ]
