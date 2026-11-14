#!/usr/bin/env bash
# test-cockpit-synthese-blocs.sh — les blocs 2 et 3 de la Synthèse : burn-up du jalon et santé de la méthode (77-06, SYNT-01, SYNT-04, SYNT-08 ; P77-D-02, P77-D-04 à P77-D-06, P77-D-14, P77-D-20).
#   CS  fichiers ui/74-vf-synthese-{burnup,jauges}.js : CSP, jeton, plafonds, couleurs et grille (css-jetons)
#   BG  pur sous `vm`, sans `document` : tête, courbe, étiquettes, liste, notes, aria-label, mots, raisons, valeurs, bilan, chargement des deux fichiers
#   W8 burn-up · W9 verdicts des jauges · JA1-JA7 lecture, attente, erreur, ordre, baseline, chemins · W4b-W7b styles · W13b focus · W14b mouvement · W16b cibles · BO1 onglets · OB ordre · E0 · CS2
#   M-INNERHTML  la seule garde du plan : un chemin venu du lab est du texte libre (rendu par textContent) ; le mutant le rend par innerHTML
# Quatre serveurs lancés par cockpit_lancer sur une COPIE du module (charge prouvée) : « main », « ok », « partiel », « tout64 » ; faux gates posés dans la copie, pilotés par l'environnement.
# Chrome headless ; sans navigateur la partie navigateur est SAUTÉE hors CI, et ÉCHOUE en CI. Mutants autres que M-INNERHTML levés (régime allégé, 2026-11-13).
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE GIT_CEILING_DIRECTORIES
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; TESTS="$SCRIPTS/tests"; MOD="$(cd "$SCRIPTS/.." && pwd -P)"; ENG="$MOD/skills/cockpit-moteur"; UI="$ENG/assets/ui"
BANC="$TESTS/chrome-synthese.mjs"; BLOCS="$TESTS/chrome-synthese-blocs.mjs"
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
REAL_HOME="$(node -e 'console.log(require("os").userInfo().homedir)')"; export HOME="$WORK/home"
trap 'vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"
PASS=0; FAIL=0
assert_eq() { if [ "$#" -ne 3 ]; then echo "  ❌ FAIL — $1 (assert_eq a reçu $# arguments au lieu de 3)"; FAIL=$((FAIL+1)); elif [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [${3:0:400}]"; echo "     obtenu:  [${2:0:400}]"; FAIL=$((FAIL+1)); fi; }
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; let j; try { j = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { console.log('illisible'); process.exit(0); }
let v; try { v = new Function('j', 'return (' + process.argv[2] + ')')(j); } catch (e) { v = 'erreur:' + e.message; } console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/largeur.mjs" <<'JS'
// largeur.mjs <fichier…> : « fichier lignes colonnes_max » par fichier (colonnes en points de code, jamais en octets)
import fs from 'node:fs'; for (const f of process.argv.slice(2)) { const l = fs.readFileSync(f, 'utf8').split('\n'); if (l.at(-1) === '') l.pop(); console.log(f, l.length, Math.max(0, ...l.map((x) => [...x.replace(/\r$/, '')].length))); }
JS
cat > "$AUX/bg.mjs" <<'JS'
// bg.mjs <burnup.js> <jauges.js> : charge chaque fichier sous `vm` SANS document, rend en JSON les sorties des fonctions pures sur des fixtures écrites en dur
import fs from 'node:fs'; import vm from 'node:vm';
const charger = (f) => { const w = {}; try { vm.runInContext(fs.readFileSync(f, 'utf8'), vm.createContext({ window: w, console }), { filename: f }); return { w, err: '' }; } catch (e) { return { w, err: String(e && e.message) }; } };
const [, , fb, fj] = process.argv, B = charger(fb), G = charger(fj), bu = B.w.__vfSyntheseBurnup || {}, ja = G.w.__vfSyntheseJauges || {};
const pt = (d, perimetre, clos, closes = []) => ({ d, perimetre, clos, closes });
const F1 = { jalon: 'v1', clos: 2, total: 4, pct: 50, ouverture: '2026-11-01', serie: [pt('2026-11-01', 3, 0), pt('2026-11-03', 3, 1, ['1']), pt('2026-11-05', 4, 2, ['2'])], closesSansDate: [], inscritesSansDate: [] };
const F2 = { jalon: 'v2', clos: 2, total: 2, pct: 100, ouverture: '2026-11-02', serie: [pt('2026-11-02', 2, 0), pt('2026-11-06', 2, 2, ['1', '2'])], closesSansDate: [], inscritesSansDate: [] };
const F3 = { jalon: 'v3', clos: 1, total: 1, pct: 100, ouverture: '2026-11-03', serie: [pt('2026-11-03', 1, 1, ['1'])], closesSansDate: [], inscritesSansDate: [] };
const F4 = { jalon: 'v4', clos: 19, total: 20, pct: 95, ouverture: '2026-11-01', serie: [pt('2026-11-01', 20, 19)], closesSansDate: [], inscritesSansDate: [] };
const F5 = { jalon: 'v5', clos: 6, total: 11, pct: 55, ouverture: '2026-08-01', serie: [pt('2026-08-01', 11, 0), pt('2026-09-30', 11, 1, ['67']), pt('2026-12-02', 11, 3, ['68', '69']), pt('2027-02-14', 11, 6, ['70', '71', '72'])], closesSansDate: [], inscritesSansDate: [] };
const F6 = { ...F1, closesSansDate: [{ n: '70', nom: 'x' }], inscritesSansDate: [{ n: '79', nom: 'y' }] };
const F7 = { ...F1, closesSansDate: [{ n: '70' }, { n: '71' }, { n: '72' }], inscritesSansDate: [{ n: '79' }, { n: '80' }] };
const F8 = { ...F1, clos: 0, pct: 0, serie: [pt('2026-11-01', 3, 0), pt('2026-11-03', 4, 0)] };
const sur = (f, ...a) => { try { return f(...a); } catch (e) { return 'erreur:' + e.message; } };
const J = (n) => Array.from({ length: n }, () => ({}));
const v = (...l) => l.map((x) => ({ verdict: x }));
const GR = (r) => r;
console.log(JSON.stringify({
  charge: { b: B.err, j: G.err, blocs: (B.w.__vfSyntheseBlocs || []).concat(G.w.__vfSyntheseBlocs || []).map((x) => x.id + ':' + x.titre), bu: Object.keys(bu).sort(), ja: Object.keys(ja).sort(), gel: [Object.isFrozen(bu), Object.isFrozen(ja)] },
  tete: sur(bu.tete, F1), c1: sur(bu.courbe, F1, '2026-11-09'), c2: sur(bu.courbe, F2, '2026-11-20'), c3: sur(bu.courbe, F3, '2026-11-03'), c4: sur(bu.courbe, F4, '2026-11-09'),
  liste: sur(bu.liste, F5), notes: [sur(bu.notes, F6), sur(bu.notes, F7), sur(bu.notes, F1)], aria: [sur(bu.ariaLabel, F1), sur(bu.ariaLabel, F3), sur(bu.ariaLabel, F8), sur(bu.ariaLabel, F2)],
  noms: ja.NOMS, groupes: ja.GROUPES, mots: ja.MOTS, raisons: ja.RAISONS,
  valeurs: [sur(ja.valeurTexte, { valeur: 21, budget: 8 }, 'Ko'), sur(ja.valeurTexte, { valeur: 11, budget: 3 }, 'worktrees'), sur(ja.valeurTexte, { valeur: 2, budget: 0 }, 'sujets'), sur(ja.valeurTexte, { valeur: 0, budget: 0 }, 'sujets'),
    sur(ja.valeurTexte, { valeur: 2610, budget: 2000 }, 'jetons'), sur(ja.valeurTexte, { valeur: null, budget: 300, verdict: 'indispo' }, 'lignes'), sur(ja.valeurTexte, null, 'lignes'), sur(ja.valeurTexte, { valeur: 5, budget: null }, 'lignes')],
  bilan: [sur(ja.bilan, [...v('ok', 'ok', 'ok', 'ok', 'ok', 'ok', 'ok', 'ok', 'depasse', 'depasse', 'depasse')]), sur(ja.bilan, v('ok', 'surveiller', 'na', 'indispo')), sur(ja.bilan, v('format', 'format', 'indispo', 'indispo', 'indispo', 'na', 'na')),
    sur(ja.bilan, v('depasse')), sur(ja.bilan, v('zzz'))],
}));
JS
JN() { printf '%s' "$RN" | node "$AUX/ev.mjs" "$1"; }; JO() { printf '%s' "$RO" | node "$AUX/ev.mjs" "$1"; }; JP() { printf '%s' "$RP" | node "$AUX/ev.mjs" "$1"; }; J6() { printf '%s' "$R6" | node "$AUX/ev.mjs" "$1"; }
JB() { printf '%s' "$BG" | node "$AUX/ev.mjs" "$1"; }
NBSP=$' '

echo "=== CS1 (statique) — ui/74-vf-synthese-burnup.js et -jauges.js : CSP, jeton, plafonds, couleurs et grille ==="
FB="$UI/74-vf-synthese-burnup.js"; FJ="$UI/74-vf-synthese-jauges.js"
assert_eq "CS1.0 — témoin : les deux fichiers existent (jamais un vert à vide)" "$([ -f "$FB" ] && echo oui || echo non)|$([ -f "$FJ" ] && echo oui || echo non)" "oui|oui"
FICH=(); [ ! -f "$FB" ] || FICH+=("$FB"); [ ! -f "$FJ" ] || FICH+=("$FJ")
if [ "${#FICH[@]}" -gt 0 ]; then
  assert_eq "CS1.1 — aucun attribut on*, eval, new Function, blob:, en-tête de jeton, linearGradient ni route de dernière commande ou de transcript" "$(/usr/bin/grep -lE 'x-floorplan-token|x-vf-cockpit-token|eval\(|new Function|blob:| on[a-z]+=|linearGradient|/api/vf/(doing|transcript)' "${FICH[@]}" 2>/dev/null | tr '\n' ' ')" ""
  assert_eq "CS1.2 — chaque fichier : au plus 299 lignes et 160 points de code par ligne (mesure en points de code)" "$(node "$AUX/largeur.mjs" "${FICH[@]}" 2>/dev/null | awk '$2 > 299 || $3 > 160 { print $1 }' | tr '\n' ' ')" ""
  node "$TESTS/css-jetons.mjs" "${FICH[@]}" > /dev/null 2>&1; CJ=$?
  assert_eq "CS1.3 — css-jetons : aucune couleur littérale ni espacement hors grille" "$CJ" "0"
  assert_eq "CS1.4 — la page est sans stockage ni cookie ; la seule route lue est /api/vf/methode" "$(/usr/bin/grep -cE 'localStorage|sessionStorage|document\.cookie' "$FB" "$FJ" | tr '\n' ' ' | sed 's/[^ ]*://g')|$(/usr/bin/grep -ho '/api/vf/[a-z]*' "$FB" "$FJ" | sort -u | tr '\n' ' ')" "0 0 |/api/vf/methode "
else
  for e in CS1.1 CS1.2 CS1.3 CS1.4; do assert_eq "$e — fichiers absents : non vérifiable" "absent" "présent"; done
fi

echo "=== BG — pur sous vm (sans document) ==="
node "$TESTS/css-jetons.mjs" "$AUX/ev.mjs" > /dev/null 2>&1
BG="$(node "$AUX/bg.mjs" "$FB" "$FJ" 2>&1)"; [ -n "${DBG:-}" ] && echo "RAW BG: $BG"
case "$BG" in "{"*) ;; *) echo "  ❌ FAIL — BG — le chargeur ne rend pas de JSON : ${BG:0:300}"; FAIL=$((FAIL+1)); BG='{}' ;; esac
assert_eq "BG8 — les deux fichiers se chargent sous vm sans document ni exception, chacun inscrit son bloc, chacun pose son objet gelé aux exports du plan" "$(JB 'JSON.stringify(j.charge)')" '{"b":"","j":"","blocs":["burnup:Burn-up du jalon","methode:Santé de la méthode"],"bu":["ariaLabel","courbe","liste","notes","tete"],"ja":["GROUPES","MOTS","NOMS","RAISONS","bilan","valeurTexte"],"gel":[true,true]}'
assert_eq "BG1 — tete : « {clos} sur {total} · {pct} % » en espaces insécables" "$(JB 'j.tete')" "2${NBSP}sur${NBSP}4${NBSP}·${NBSP}50${NBSP}%"
assert_eq "BG2.1 — courbe, jalon en cours (aujourd'hui 9 nov.) : escaliers aux coordonnées calculées à la main (x : 26 par jour, y : 28 par phase)" "$(JB 'JSON.stringify(j.c1.chemins)')" '{"clos":"M28 128H28V128H80V100H132V72H236","perimetre":"M28 44H80V44H132V16H236"}'
assert_eq "BG2.2 — jalon entièrement clos : le tracé s'arrête à la dernière clôture (6 nov., pas aujourd'hui) ; le périmètre finit à M" "$(JB 'JSON.stringify(j.c2.chemins)')" '{"clos":"M28 128H28V128H236V16H236","perimetre":"M28 16H236V16H236"}'
assert_eq "BG2.3 — jalon à une seule date : au moins un jour d'écart (jamais une division par zéro)" "$(JB 'JSON.stringify(j.c3.chemins)')" '{"clos":"M28 128H28V16H236","perimetre":"M28 16H236"}'
assert_eq "BG3.1 — étiquettes : 0 et M à gauche (x 20, ancrage fin), dates sous la base, étiquettes directes à x 244" "$(JB 'JSON.stringify(j.c1.etiquettes)')" '[{"x":20,"y":132,"texte":"0","ancre":"end"},{"x":20,"y":20,"texte":"4","ancre":"end"},{"x":28,"y":142,"texte":"1er nov.","ancre":"start"},{"x":236,"y":142,"texte":"9 nov.","ancre":"end"},{"x":244,"y":20,"texte":"périmètre 4","ancre":"start"},{"x":244,"y":76,"texte":"closes 2","ancre":"start"}]'
assert_eq "BG3.2 — règle des 14 unités : « closes » est la plus basse, à 14 unités au moins de « périmètre » (tout clos, puis 19 sur 20)" "$(JB '[j.c2, j.c4].map((c) => c.etiquettes.filter((e) => e.x === 244).map((e) => e.texte + "@" + e.y).join(",")).join("|")')" "périmètre 2@20,closes 2@34|périmètre 20@20,closes 19@34"
assert_eq "BG4 — liste : mois abrégés (août, sept., déc., févr.), « 1er », phases closes nommées après « : » (« Phase », « Phases … et … », « Phases …, … et … »)" "$(JB 'j.liste.map((l) => l.texte).join("\n")')" "1er août · périmètre 11 · closes 0
30 sept. · périmètre 11 · closes 1 : Phase 67
2 déc. · périmètre 11 · closes 3 : Phases 68 et 69
14 févr. · périmètre 11 · closes 6 : Phases 70, 71 et 72"
assert_eq "BG5 — notes : au singulier, au pluriel (Phases 70, 71 et 72 ; 79 et 80), aucune note sans phase sans date" "$(JB 'j.notes.slice(0, 2).map((n) => n.join(" // ")).join("\n")')
$(JB 'j.notes[2].length')" "Close, date non écrite : Phase 70. Elle compte dans le pourcentage, sans marche sur la courbe. // Inscrite sans date : Phase 79. Comptée dès l'ouverture du jalon, le 1er nov.
Closes, date non écrite : Phases 70, 71 et 72. Elles comptent dans le pourcentage, sans marche sur la courbe. // Inscrites sans date : Phases 79 et 80. Comptées dès l'ouverture du jalon, le 1er nov.
0"
assert_eq "BG6 — ariaLabel : singulier et pluriel, aucune phase close datée dite" "$(JB 'j.aria.join("\n")')" "Burn-up du jalon v1 : 2 phases closes sur 4, 50 %. Périmètre de 3 phases le 1er nov. à 4 phases le 5 nov. ; 2 phases closes datées entre le 3 nov. et le 5 nov.
Burn-up du jalon v3 : 1 phase close sur 1, 100 %. Périmètre de 1 phase le 3 nov. à 1 phase le 3 nov. ; 1 phase close datée le 3 nov.
Burn-up du jalon v1 : 0 phase close sur 4, 0 %. Périmètre de 3 phases le 1er nov. à 4 phases le 3 nov. ; aucune phase close datée.
Burn-up du jalon v2 : 2 phases closes sur 2, 100 %. Périmètre de 2 phases le 2 nov. à 2 phases le 6 nov. ; 2 phases closes datées entre le 6 nov. et le 6 nov."
assert_eq "BG7.1 — NOMS (onze libellés) et GROUPES (trois groupes, ordre fixe)" "$(JB 'JSON.stringify([j.noms, j.groupes])')" '[{"state":"Taille de STATE.md","state-prose":"Paragraphe de prose de STATE.md","backlog-ouverts":"Sujets ouverts du BACKLOG","backlog-entree":"Longueur d'"'"'une entrée du BACKLOG","backlog-clos":"Sujets clos encore au BACKLOG","roadmap":"Taille de ROADMAP.md","memory-index":"Index de mémoire MEMORY.md","worktrees":"Worktrees actifs","agent":"Agents : lignes du plus long","skill":"Skills : lignes du plus long","socle":"Socle de démarrage"},[{"titre":"Planning","types":["state","state-prose","backlog-ouverts","backlog-entree","backlog-clos","roadmap"]},{"titre":"Mémoire et chantiers","types":["memory-index","worktrees"]},{"titre":"Instructions des agents","types":["agent","skill","socle"]}]]'
assert_eq "BG7.2 — MOTS (mot et classe de glyphe) et RAISONS (non applicable, indisponible par cause, format)" "$(JB 'JSON.stringify([j.mots, j.raisons])')" '[{"ok":["Dans le budget","vst-done"],"surveiller":["À surveiller","vst-tolere"],"depasse":["Dépassé","vst-ignore"],"na":["Non applicable dans ce lab","vst-abandonnee"],"indispo":["Indisponible","vst-todo"],"format":["Format non reconnu","vst-info"]},{"na":"Ce contrôle ne mesure que le dépôt de distribution de VibeFlow.","indispo":{"absent":"Le contrôle n'"'"'est pas installé.","ancien":"Le contrôle installé est trop ancien. Mettez VibeFlow à jour : /vf-update.","delai":"Le contrôle n'"'"'a pas répondu à temps.","format":"Le cockpit ne reconnaît pas la forme de cette mesure.","defaut":"Mesure indisponible."},"format":"Le cockpit ne reconnaît pas la forme de cette mesure."}]'
assert_eq "BG7.3 — valeurTexte : « 21 sur 8 Ko », « 11 sur 3 worktrees actifs », « 2, budget 0 », « 0, budget 0 », milliers insécables, null sans valeur ni budget" "$(JB 'JSON.stringify(j.valeurs)')" "[\"21 sur 8 Ko\",\"11 sur 3 worktrees actifs\",\"2, budget 0\",\"0, budget 0\",\"2${NBSP}610 sur 2${NBSP}000 jetons\",null,null,null]"
assert_eq "BG7.4 — bilan : catégories non nulles, accordées, dans l'ordre ; un verdict inconnu compte comme « format non reconnu »" "$(JB 'j.bilan.join("\n").replace(/\u00a0/g, " ")')" "11 jauges · 8 dans le budget · 3 dépassées
4 jauges · 1 dans le budget · 1 à surveiller · 1 non applicable · 1 indisponible
7 jauges · 2 non applicables · 3 indisponibles · 2 format non reconnu
1 jauge · 1 dépassée
1 jauge · 1 format non reconnu"

if [ -z "$CHROME" ]; then
  . "$(dirname "$0")/chrome-saut.sh"; vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur — W8, W9, JA1 à JA7, W4b à W7b, W13b, W14b, BO1 et M-INNERHTML ne sont PAS vérifiés, non comptés comme réussis"
  vf_hyg_assert; echo ""; echo "  Résultats : $PASS PASS / $FAIL FAIL"; [ "$FAIL" -eq 0 ]; exit $?
fi

echo "=== Préparation — labs, copie du module, faux gates ==="
mklab() { local L; L="$(node "$BLOCS" lab "$WORK/$1" "$1")" || return 1; node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build-$1.out" 2>&1 || cat "$WORK/build-$1.out"; printf '%s\n' "$L"; }
LABN="$(mklab normal)"; LABS="$(mklab sansdate)"
copie_blocs() { local d; d="$(cockpit_module_copie "$WORK/mod-$1")" || return 1; node "$BLOCS" copie "$d"; node "$BANC" temoin "$d"; printf '%s\n' "$d"; }
COP="$(copie_blocs blocs)"
assert_eq "B1 — labs : cinq phases datées, deux closes ; la variante sans date ne date pas la clôture de la phase 2 ; la copie ne garde, hors burn-up et jauges, que le bloc témoin ; deux faux gates posés" "$(/usr/bin/grep -c 'complete 2026' "$LABN/.planning/ROADMAP.md")|$(/usr/bin/grep -c 'complete 2026' "$LABS/.planning/ROADMAP.md")|$(ls "$COP"/skills/cockpit-moteur/assets/ui/ | /usr/bin/grep '74-vf-synthese-' | /usr/bin/grep -vcE '(burnup|jauges)')|$(ls "$COP"/scripts/check-*-budget.sh | wc -l | tr -d ' ')" "2|1|1|2"
mesurer() { REAL_HOME="$REAL_HOME" node "$BLOCS" scenario "$CHROME" "$VF_PORT" "$@"; }
scenario() { # <nom> <lab> [NOM=valeur…] : serveur lancé sur la copie, scénario joué, serveur arrêté ; la mesure est dans $SORTIE
  local nom="$1" lab="$2"; shift 2; export COCKPIT_MODULE="${COP_COURANTE:-$COP}"
  cockpit_lancer "$lab" "$@"; local rl=$?; [ "$rl" -eq 0 ] || { echo "  ❌ FAIL — $nom — lancement du serveur : code $rl"; FAIL=$((FAIL+1)); SORTIE='{"erreur":"lancement"}'; return; }
  SORTIE="$(mesurer "$nom")"; [ -z "${DBG:-}" ] || echo "RAW $nom: $SORTIE"; cockpit_arreter
}
scenario main "$LABN" FAUX_DELAI=1; RN="$SORTIE"
scenario ok "$LABS" FAUX_METHODE=xss FAUX_DENSITE=ok; RO="$SORTIE"
scenario partiel "$LABN" FAUX_METHODE=64 FAUX_DENSITE=tiers; RP="$SORTIE"
scenario tout64 "$LABN" FAUX_METHODE=64 FAUX_DENSITE=64; R6="$SORTIE"
assert_eq "B2 — mesures obtenues sans erreur nommée (quatre serveurs) ; les faux gates ont été joués (au moins une jauge lue dans main)" "$(JN 'j.erreur||""')|$(JO 'j.erreur||""')|$(JP 'j.erreur||""')|$(J6 'j.erreur||""')|$(JN '(j.ja && j.ja.lis.length) || 0')" "||||11"

echo "=== W8 — burn-up du jalon ==="
VOC='["Dans le budget","À surveiller","Dépassé","Non applicable dans ce lab","Indisponible","Format non reconnu"]'
assert_eq "W8.1 — la tête « N sur M · P % » est égale au pied de la carte du jalon (clos et pourcentage), même fixture" "$(JN '(() => { const t = /^(\d+) sur (\d+) · (\d+) %$/.exec(j.bu.tete.replace(/\s/g, " ")); const f = /^(\d+) clos.* (\d+) %$/.exec(j.bu.pied || ""); return t && f ? [t[1], t[2], t[3], f[1], f[2]].join("|") : "illisible:" + j.bu.tete + "/" + j.bu.pied; })()')" "2|5|40|2|40"
assert_eq "W8.2 — titre, aide (jalon nommé, sans pondération par les plans) et sous-titre du bloc" "$(JN '[j.bu.titre, /^Phases closes du jalon .+, sans pondération par les plans\.$/.test(j.bu.aide)].join("|")')" "Burn-up du jalon|true"
assert_eq "W8.3 — svg.vf-sy-courbe : role=img, aria-label contenant « sur » et « % », focusable=false, aucun enfant lu" "$(JN '[j.bu.svg, j.bu.role, / sur /.test(j.bu.aria) && /%/.test(j.bu.aria), j.bu.aria.includes("2 phases closes sur 5, 40 %"), j.bu.focusable].join("|")')" "true|img|true|true|false"
assert_eq "W8.4 — exactement deux chemins de série : clôtures en trait plein --text-3, périmètre en tirets --text-4 ; deux traits de largeurs distinctes" "$(JN '(() => { const s = j.bu.series, c = s.find((x) => x.serie === "clos"), p = s.find((x) => x.serie === "perimetre"); return [s.length, c && c.tirets === "none", c && c.stroke === j.bu.t3, p && p.tirets !== "none" && p.tirets !== "", p && p.stroke === j.bu.t4, c && p && c.largeur !== p.largeur, j.bu.t3 !== j.bu.t4].join("|"); })()')" "2|true|true|true|true|true|true"
assert_eq "W8.5 — aucun dégradé, aucune légende à pastille ; deux étiquettes directes au bout des séries ; des étiquettes d'axe en plus" "$(JN '[j.bu.degrades, j.bu.pastilles, j.bu.directes.join(","), j.bu.textes >= 6].join("|")')" "0|0|périmètre 5,closes 2|true"
assert_eq "W8.6 — liste datée : une ligne par date où quelque chose change, valeurs cumulées ; sur ordinateur, dans un repli « Liste datée » fermé" "$(JN '[j.bu.liste.n, j.bu.liste.premiere, j.bu.details.n, j.bu.details.resume, j.bu.details.ouvert, j.bu.liste.dansDetails].join("|")')" "3|1er nov. · périmètre 3 · closes 0|1|Liste datée|false|true"
assert_eq "W8.7 — à 700 px : pas de courbe, la liste datée est affichée ouverte, sans repli, sans double contenu ; à 701 px : la courbe, et la liste dans un repli fermé" "$(JN '(() => { const a = j.largeurs["700"], b = j.largeurs["701"]; return [a.svg, a.liste.visible, a.liste.dansDetails, a.details.n, b.svgVisible, b.liste.dansDetails, b.details.ouvert, b.liste.visible].join("|"); })()')" "false|true|false|0|true|true|false|false"
assert_eq "W8.8 — phase inscrite sans date dite, comptée dès l'ouverture, jamais estimée (lab daté) ; aucune note de clôture sans date dans ce lab" "$(JN 'j.bu.notes.join(" // ")')" "Inscrite sans date : Phase 5. Comptée dès l'ouverture du jalon, le 1er nov."
assert_eq "W8.9 — lab dont la phase 2 est close sans date : la note la nomme, elle compte dans le pourcentage (même tête que le lab daté)" "$(JO 'j.bu.notes[0]')|$(JO 'j.bu.tete.replace(/\s/g, " ")')" "Close, date non écrite : Phase 2. Elle compte dans le pourcentage, sans marche sur la courbe.|2 sur 5 · 40 %"
assert_eq "W8.11 — décompte sans aucune date au ROADMAP : la tête reste, le bloc ne dit plus « Burn-up indisponible » mais « Courbe indisponible : aucune date écrite au ROADMAP. » ; pas de courbe ; la phase close n'est pas listée dans « Inscrites sans date »" "$(JN 'j.sansDates.tete.replace(/\s/g, " ")')|$(JN 'j.sansDates.texte.includes("Courbe indisponible : aucune date écrite au ROADMAP.")')|$(JN 'j.sansDates.texte.includes("Burn-up indisponible")')|$(JN 'j.sansDates.svg')|$(JN 'j.sansDates.notes.join(" // ")')" "1 sur 3 · 33 %|true|false|false|Close, date non écrite : Phase 1. Elle compte dans le pourcentage, sans marche sur la courbe. // Inscrites sans date : Phases 2 et 3. Comptées dès l'ouverture du jalon."
MARCHES='(d) => { const y = [Number(/^M[\d.]+ ([\d.]+)/.exec(d)[1]), ...[...d.matchAll(/V([\d.]+)/g)].map((x) => Number(x[1]))]; return y.filter((v, i) => i && v !== y[i - 1]).length; }'
assert_eq "W8.10 — marches de la série des clôtures : deux avec les deux dates (la fonction compte les marches du lab daté : sonde positive), une seule quand la date de la phase 2 manque" "$(JN "($MARCHES)(j.bu.series.find((s) => s.serie === \"clos\").d)")|$(JO "($MARCHES)(j.bu.series.find((s) => s.serie === \"clos\").d)")" "2|1"

echo "=== W9 — verdicts des jauges ==="
assert_eq "W9.1 — onze jauges, chacune avec un .vst au mot du vocabulaire fermé et un glyphe (masque ::before non none), dans l'ordre fixe des groupes ; trois groupes, trois listes" "$(JN '[j.ja.lis.length, j.ja.lis.every((l) => '"$VOC"'.includes(l.mot) && l.glyphe), j.ja.lis.map((l) => l.type).join(","), j.ja.groupes.join("/"), j.ja.nbUl].join("|")')" "11|true|state,state-prose,backlog-ouverts,backlog-entree,backlog-clos,roadmap,memory-index,worktrees,agent,skill,socle|Planning/Mémoire et chantiers/Instructions des agents|3"
assert_eq "W9.2 — un dépassement porte le mot, le glyphe, la valeur chiffrée et une barre hachurée pleine ; une jauge dans le budget a une barre non hachurée à sa proportion ; la barre est aria-hidden" "$(JN '(() => { const d = j.ja.lis.find((l) => l.type === "state"), o = j.ja.lis.find((l) => l.type === "state-prose"), s = j.ja.lis.find((l) => l.type === "roadmap"), z = j.ja.lis.find((l) => l.type === "backlog-clos"); return [d.verdict, d.mot, d.glyphe, d.val, d.hach, d.largeur, d.ariaBarre, o.mot, o.hach, o.largeur, s.mot, s.largeur, z.val, z.largeur].join("|"); })()')" "depasse|Dépassé|true|21 sur 8 Ko|true|100%|true|Dans le budget|false|41.7%|À surveiller|93.8%|0, budget 0|0%"
assert_eq "W9.3 — valeurs : « 2 sur 3 worktrees actifs » et jetons à milliers insécables" "$(JN '[j.ja.lis.find((l) => l.type === "worktrees").val, j.ja.lis.find((l) => l.type === "socle").val.replace(/ /g, "_")].join("|")')" "2 sur 3 worktrees actifs|2_610 sur 2_000 jetons"
assert_eq "W9.4 — contrôle de méthode ancien (code 64) + densité hors dépôt de distribution : huit « Indisponible » (« trop ancien », /vf-update), trois « Non applicable dans ce lab » ; ni barre, ni valeur, ni chiffre, ni « 0 » dans ces lignes" "$(JP '(() => { const i = j.ja.lis.filter((l) => l.verdict === "indispo"), n = j.ja.lis.filter((l) => l.verdict === "na"); const nu = (l) => !l.barre && l.val === "" && !/\d/.test(l.texte); return [i.length, n.length, i.every(nu) && n.every(nu), i.every((l) => l.mot === "Indisponible" && l.texte.includes("Le contrôle installé est trop ancien. Mettez VibeFlow à jour : /vf-update.")), n.every((l) => l.mot === "Non applicable dans ce lab" && l.texte.includes("Ce contrôle ne mesure que le dépôt de distribution de VibeFlow.")), j.ja.bilan.replace(/\u00a0/g, " ")].join("|"); })()')" "8|3|true|true|true|11 jauges · 3 non applicables · 8 indisponibles"
assert_eq "W9.5 — les deux contrôles anciens : une seule phrase « Aucune jauge n'a pu être lue. » avec la raison commune et « Relire les jauges », pas onze lignes" "$(J6 '[j.ja.lis.length, j.ja.texte.includes("Aucune jauge n'"'"'a pu être lue."), j.ja.texte.includes("Le contrôle installé est trop ancien."), j.ja.relire].join("|")')" "0|true|true|true"

echo "=== JA — lecture à l'ouverture, attente, erreur, ordre, baseline, chemins ==="
assert_eq "JA1 — aucune requête /api/vf/methode avant l'ouverture (le journal voit des GET /api/vf/ avec jeton : sonde positive), une seule à l'ouverture" "$(JN '[j.avant.methode, j.avant.api >= 1, j.apres.methode, j.compteMethode].join("|")')" "0|true|1|1"
assert_eq "JA2.1 — pendant la lecture (faux gate de 1 s) : « Lecture des jauges en cours. » et aria-busy=true ; à l'arrivée aria-busy retiré et contenu remplacé" "$(JN '[j.attente.busy, j.attente.texte, j.ja.busy, j.ja.lis.length].join("|")')" "true|Lecture des jauges en cours.||11"
assert_eq "JA2.2 — l'arrivée des jauges ne déplace ni le focus (bouton du bloc témoin, vu focalisé avant), ni le défilement (vu positif avant) ; annonce unique « Jauges lues : … »" "$(JN '[j.avantArrivee.focus.texte, j.avantArrivee.scroll > 0, JSON.stringify(j.avantArrivee.focus) === JSON.stringify(j.apresArrivee.focus), j.avantArrivee.scroll === j.apresArrivee.scroll, j.apresArrivee.sr.replace(/\u00a0/g, " "), j.apresArrivee.muts].join("|")')" "Bouton témoin|true|true|true|Jauges lues : 6 dans le budget, 2 à surveiller, 3 dépassées.|1"
assert_eq "JA3.1 — réponse en erreur : la phrase d'erreur et « Relire les jauges »" "$(JN '[j.echec.texte.includes("Les jauges sont indisponibles : le serveur du cockpit n'"'"'a pas répondu."), j.echec.relire.join(",")].join("|")')" "true|Relire les jauges"
assert_eq "JA3.2 — pendant la relecture : aria-disabled=true (jamais disabled), le focus reste sur le bouton ; une seule lecture de plus" "$(JN '[j.relecture.aria, j.relecture.disabled, j.relecture.focus.tag, j.relecture.focus.texte, j.relecture.nb].join("|")')" "true|false|BUTTON|Relire les jauges|3"
assert_eq "JA3.3 — nouvel échec : phrase d'erreur et bouton de nouveau actif, focus gardé dessus ; une relecture réussie remplace le contenu (onze jauges) sans perdre le focus sur le corps de page" "$(JN '[j.apresEchec.focus.tag, j.apresEchec.aria !== "true", j.apresEchec.texte.includes("n'"'"'a pas répondu"), j.apresSucces.lis, j.apresSucces.focus.tag !== "BODY"].join("|")')" "BUTTON|true|true|11|true"
assert_eq "JA4 — aucun contrôle lu (code 64 des deux) : aucune ligne de jauge, un bilan absent, l'annonce « Jauges indisponibles. »" "$(J6 '[j.ja.lis.length, j.ja.bilan === "", j.ja.texte.includes("Aucune jauge")].join("|")')" "0|true|true"
assert_eq "JA5 — l'ordre des lignes est le même, jauges dans le budget ou en dépassement (jamais trié par gravité) ; la sonde de barre voit des barres sur le faux gate « tout dans le budget »" "$(JN 'j.ja.lis.map((l) => l.type).join()')|$(JO 'j.ja.lis.map((l) => l.type).join()')" "state,state-prose,backlog-ouverts,backlog-entree,backlog-clos,roadmap,memory-index,worktrees,agent,skill,socle|state,state-prose,backlog-ouverts,backlog-entree,backlog-clos,roadmap,memory-index,worktrees,agent,skill,socle"
assert_eq "JA5.b — faux gate « tout dans le budget » : onze jauges, barres présentes et non hachurées, un seul « À surveiller » (agent)" "$(JO '[j.ja.lis.length, j.ja.lis.filter((l) => l.barre).length, j.ja.lis.filter((l) => l.hach).length, j.ja.lis.filter((l) => l.verdict === "surveiller").map((l) => l.type).join()].join("|")')" "11|11|0|agent"
assert_eq "JA6 — la ligne de baseline du socle est dite avec la relation que la route sert, et le verdict de la jauge reste celui de la route (dépassé : la page ne le recalcule pas)" "$(JN '(() => { const s = j.ja.lis.find((l) => l.type === "socle"); return [s.texte.replace(/ /g, " ").includes("Ligne de baseline : 2 610 jetons, mesure égale."), s.verdict, s.mot].join("|"); })()')" "true|depasse|Dépassé"
assert_eq "JA7 — aucun chemin affiché ne commence par / ou ~ ; une coupure <wbr> après chaque « / » (des chemins à barre vus : sonde positive) ; aucun préfixe de dossier du poste dans le texte du panneau" "$(JN '[j.ja.chemins.length > 0, j.ja.chemins.some((c) => c.t.includes("/")), j.ja.chemins.every((c) => !/^[\/~]/.test(c.t) && c.wbr === (c.t.match(/\//g) || []).length), j.interdits].join("|")')" "true|true|true|false"
assert_eq "JA7.b — sous-liste des autres mesures hors budget : cinq au plus, puis « et 2 autres » ; pied « Mesuré à … par les contrôles de la méthode. » ; bilan accordé" "$(JN '(() => { const s = j.ja.lis.find((l) => l.type === "state"); return [s.sous, s.autres, /^Mesuré à \d{1,2} h \d{2} par les contrôles de la méthode\.$/.test(j.ja.pied), j.ja.bilan.replace(/\u00a0/g, " ")].join("|"); })()')" "5|et 2 autres|true|11 jauges · 6 dans le budget · 2 à surveiller · 3 dépassées"
assert_eq "JA8 — chemin piégé venu du lab (balise et attribut) : rendu en texte, aucun élément injecté, aucun script exécuté ; le texte littéral est lisible" "$(JO '(() => { const s = j.ja.lis.find((l) => l.type === "state"); return [j.ja.lis.reduce((n, l) => n + l.imgs, 0), j.ja.xss, s.texte.includes("<img src=x onerror=window.__xss=1>")].join("|"); })()')" "0|false|true"

echo "=== W4b-W7b, W13b, W14b, W16b, BO1, OB, E0 — styles, focus, mouvement, cibles, onglets, ordre ==="
AU() { printf '%s' "$1" | node "$AUX/ev.mjs" "$2"; }
assert_eq "W4b/W7b — sous les blocs 2 et 3 : aucune couleur calculée non neutre (texte, fond, traits, glyphes, SVG), aucune ombre ; la sonde voit une teinte injectée" "$(JN '[j.audits.burnup.n >= 15, j.audits.methode.n >= 60, j.audits.burnup.couleur.concat(j.audits.methode.couleur, j.audits.burnup.ombre, j.audits.methode.ombre).join(";"), j.sondeAudit >= 1].join("|")')" "true|true||true"
assert_eq "W5b — espacements calculés dans la grille fermée (0, 2, 4, 6, 8, 12, 16, 20, 24, 32), sous les deux blocs" "$(JN '[j.audits.burnup.n >= 15, j.audits.methode.n >= 60, j.audits.burnup.espacement.concat(j.audits.methode.espacement).join(";")].join("|")')" "true|true|"
assert_eq "W6b — tailles de police 20, 13.5, 12.5, 11 px ; graisses 400, 500, 600 ; polices Inter et JetBrains Mono seulement" "$(JN '[j.audits.burnup.n >= 15, j.audits.methode.n >= 60, j.audits.burnup.police.concat(j.audits.methode.police).join(";")].join("|")')" "true|true|"
assert_eq "W14b — mouvement réduit : aucune animation, aucune transition sous les blocs 2 et 3 (au moins dix éléments mesurés)" "$(JN '(j.mouvement.n >= 10) + "," + j.mouvement.animations + "," + j.mouvement.transitions')" "true,0,0"
assert_eq "W16b — à 800 px : le repli « Liste datée » fait au moins 44 px de haut" "$(JN 'j.cible800 >= 44')" "true"
assert_eq "OB — ordre des blocs dans le DOM : le bloc témoin « visite » (le vrai est au plan 77-08), puis burn-up, puis santé" "$(JN 'j.blocs.join("-") + "|" + j.bu.titre + "|" + j.ja.lis.length')" "visite-burnup-methode|Burn-up du jalon|11"
assert_eq "BO1 — après deux cycles d'onglet (code, projet, code, projet) : un seul bloc burn-up et un seul bloc santé ; écouteurs de document, de window et de listes de requêtes média égaux (la sonde voit un écouteur de média posé puis retiré) ; jamais de rechargement" "$(JN '[j.cycles.blocs.join("-"), j.cycles.burnup, j.cycles.methode, JSON.stringify(j.ecout1) === JSON.stringify(j.ecout2), j.mq1 >= 1, j.mq1 === j.mq2, j.cycles.mq3 === j.mq2, j.sondeMQ, j.cycles.memeDocument].join("|")')" "visite-burnup-methode|1|1|true|true|true|true|true|true"
assert_eq "E0 — aucune exception de page, aucune violation de CSP, aucun POST ni route interdite, chaque lecture de l'API porte le jeton (quatre serveurs)" "$(for r in "$RN" "$RO" "$RP" "$R6"; do printf '%s' "$r" | node "$AUX/ev.mjs" '[j.erreursPage.length, j.csp, j.reseau.posts, j.reseau.interdites, j.reseau.lecturesSansJeton, j.bu.tete !== ""].join(",")'; done | tr '\n' ' ')" "0,0,0,0,0,true 0,0,0,0,0,true 0,0,0,0,0,true 0,0,0,0,0,true "

echo "=== M-INNERHTML — le chemin venu du lab rendu par innerHTML : JA8 rougit ==="
cockpit_module_muter innerhtml "$FJ" 's/e\.textContent = t;/e.innerHTML = t;/' 2>"$WORK/mut.err"; RCM=$?
if [ "$RCM" -ne 0 ]; then echo "  ❌ FAIL — M-INNERHTML — copie mutée impossible : $(head -c 200 "$WORK/mut.err")"; FAIL=$((FAIL+1)); else
  COP_COURANTE="$COCKPIT_MODULE"; node "$BLOCS" copie "$COP_COURANTE"; node "$BANC" temoin "$COP_COURANTE"
  scenario ok "$LABS" FAUX_METHODE=xss FAUX_DENSITE=ok; RM="$SORTIE"; COP_COURANTE=""
  assert_eq "M-INNERHTML — la copie mutée est chargée de façon prouvée ; la balise du chemin est injectée (au moins un élément), JA8 rougit" "$(printf '%s' "$RM" | node "$AUX/ev.mjs" '(j.erreur || "") + "|" + (j.ja ? j.ja.lis.reduce((n, l) => n + l.imgs, 0) >= 1 : "absent")')" "|true"
fi
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ "$FAIL" -eq 0 ]
