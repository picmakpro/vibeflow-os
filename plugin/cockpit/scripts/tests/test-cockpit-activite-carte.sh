#!/usr/bin/env bash
# test-cockpit-activite-carte.sh — Phase 75, plan 75-07 : le canal de marquage des cartes (ui/75-vf-marques.js), par un harnais `vm`.
# Première moitié du plan : D1 (canal, objet gelé du moteur jamais étendu), D2 (pile des couches exclusives), D2b (couche non exclusive),
# D5 (agrégat aux ancêtres : palier maximal et compte, jamais une somme), D18 (inscription par cle, nettoyage, aucun doublement),
# D19 (point d'entrée du dessin, tolérant), D20 (file de résolution tardive : une pose déposée avant le canal est appliquée une fois).
# Seconde moitié (navigateur, un Chrome sans affichage, lab construit par la suite) : D3 (marque, mot par textContent), D4 (géométrie invariante),
# D6 à D12 et D17 (pied réservé, glyphes, contraste, zooms, prévues), D13 à D16 (nom accessible, collisions, XSS). Sans navigateur : saut explicite.
# Régime allégé (mandat commun de la Phase 75) : seuls les mutants de la chaîne XSS (D3, D15) sont joués (MUTANT-ROUGE — <nom>).
# Variable MARQUES_JS : un autre fichier du canal (le témoin rouge se rejoue sur la base, où le fichier n'existe pas).
# Forme : « PASS — <id> : <texte> », « ❌ FAIL — <id> : <texte> », ligne finale « BILAN : <n> PASS, <m> FAIL » ; sort en 1 au premier FAIL.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
MODULE="${MARQUES_JS:-$HERE/../../skills/cockpit-moteur/assets/ui/75-vf-marques.js}"
FX="$HERE/fixtures/test-cockpit-activite-carte"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"
cleanup() { type vf_hyg_fin > /dev/null 2>&1 && vf_hyg_fin; rm -rf "$WORK"; }; trap cleanup EXIT
PASS=0; FAIL=0

fin() { echo "BILAN : $PASS PASS, $FAIL FAIL"; [ "$FAIL" -eq 0 ]; exit $?; }
assert_eq() { # id texte obtenu attendu
  if [ "$3" = "$4" ]; then echo "  ✅ PASS — $1 : $2"; PASS=$((PASS+1))
  else echo "  ❌ FAIL — $1 : $2"; echo "     attendu: [$4]"; echo "     obtenu:  [$3]"; FAIL=$((FAIL+1)); fin; fi
}

OUT="$WORK/observations.txt"
node "$FX/marques-harness.mjs" "$MODULE" > "$OUT" 2> "$WORK/erreur.txt"; RC=$?
if [ "$RC" -ne 0 ]; then echo "  ❌ FAIL — D0 : le harnais a échoué (code $RC)"; sed 's/^/     /' "$WORK/erreur.txt" | head -20; FAIL=$((FAIL+1)); fin; fi
val() { grep -F -m1 "$1=" "$OUT" | sed "s/^$1=//"; } # une observation, ou rien si elle manque

echo "== D1 le canal existe, l'objet du moteur n'est pas étendu =="
assert_eq D1 "window.VF_MARQUES expose poser, retirer, active et lire" "$(val D1.api)" "poser:function retirer:function active:function lire:function"
assert_eq D1 "window.VibeFlow reste gelé" "$(val D1.moteur-gele)" "true"
assert_eq D1 "window.VibeFlow n'a gagné aucune clé" "$(val D1.moteur-cles)" "true"
assert_eq D1 "le canal est lui-même gelé" "$(val D1.canal-gele)" "true"
assert_eq D1 "poser et retirer ne relancent ni render ni rerender" "$(val D1.relances)" "0+0"

echo "== D2 couches exclusives : la pile =="
assert_eq D2 "poser a puis b : seule b est visible" "$(val D2.b-seule)" "b|0|b"
assert_eq D2 "retirer b restitue a (et rend son nom)" "$(val D2.retrait-de-b)" "a|a|a|0"
assert_eq D2 "reposer une couche la passe au-dessus" "$(val D2.repose-passe-dessus)" "a|0|moyen"
assert_eq D2 "retirer dépile couche par couche, un nom inconnu ne change rien" "$(val D2.retrait-inconnu)" "a|b|null|null"
assert_eq D2 "un nom vide ou une table qui n'en est pas une est refusé" "$(val D2.refus)" "false,false,false"

echo "== D2b couche non exclusive =="
assert_eq D2b "visible en même temps que l'exclusive" "$(val D2b.ensemble)" "a+col"
assert_eq D2b "une autre exclusive masque la première, jamais la non exclusive" \
  "$(val D2b.exclusive-masque-l-autre-exclusive-pas-la-non-exclusive)" "col|b|b"
assert_eq D2b "retirer l'exclusive rend la précédente, la non exclusive reste" "$(val D2b.apres-retrait)" "a+col"
assert_eq D2b "retirer une exclusive ne touche pas la non exclusive" "$(val D2b.exclusive-retiree-ne-touche-pas-l-autre)" "col|null"

echo "== D5 agrégat aux ancêtres =="
assert_eq D5 "nœud de deux fichiers hauts : palier haut et compte 2" "$(val D5.noeud-x)" "haut|2|2 chauds|true"
assert_eq D5 "nœud sans fichier haut : le palier maximal est moyen, compte 1 (singulier)" "$(val D5.noeud-y)" "moyen|1|1 moyen|true"
assert_eq D5 "ancêtre commun : palier haut et compte 2, jamais la somme (4) des paliers" "$(val D5.noeud-haut)" "haut|2|2 chauds|true"
assert_eq D5 "la carte « non assignés » suit la même règle" "$(val D5.non-assignes)" "haut|1|1 chaud|true"
assert_eq D5 "une carte marquée garde sa marque propre, la racine n'en porte aucune" "$(val D5.carte-propre)" "false|0"
assert_eq D5 "sans palier haut ni moyen : « peu changés »" "$(val D5.tous-bas)" "bas|2|2 peu changés|true"
assert_eq D5 "collisions : l'unité est le fichier (deux sources sur f:a comptent un fichier)" "$(val D5.collisions-en-fichiers)" "1|2|2 fichiers|null"
assert_eq D5 "un seul fichier : le singulier" "$(val D5.un-fichier)" "1 chaud"
assert_eq D5 "sans moteur : la pose réussit, aucun agrégat, aucune erreur" "$(val D5.sans-moteur)" "true|0|1"
assert_eq D5 "données hostiles (__proto__, constructor, rangées invalides) : texte littéral, aucune pollution" \
  "$(val D5b.hostiles)" "true|1|2|undefined|undefined"
assert_eq D5 "textes plafonnés (300 et 600 caractères)" "$(val D5b.long)" "300|600"

echo "== D18 inscription par cle =="
assert_eq D18 "Code, Projet, Code, Projet, Code : une inscription pour la cle, aucune couche posée sur Projet, un écouteur" \
  "$(val D18.arrivees)" "code:1:true:2:1 projet:1:false:0:1 code:1:true:2:1 projet:1:false:0:1 code:1:true:2:1"
assert_eq D18 "deux réexécutions du script : même nombre d'inscriptions et d'écouteurs, une couche par pose" \
  "$(val D18.rejeu)" "1|1|1->1|1|1|1"
assert_eq D18 "l'arrivée sur Projet retire toutes les couches" "$(val D18.projet-vide)" "0|null"

echo "== D19 point d'entrée du dessin =="
assert_eq D19 "un appel du peintre à la pose, un à l'événement render, la table porte la carte et ses ancêtres" \
  "$(val D19.dessin)" "1|1|f:a:1,n:x:1,n:top:1"
assert_eq D19 "canal fermé : render n'appelle plus le peintre" "$(val D19.ferme)" "0"
assert_eq D19 "sans moteur : rien ne casse ; un rappel invalide se débranche sans effet" "$(val D19.sans-moteur)" "true|function|undefined"

echo "== D20 file de résolution tardive =="
assert_eq D20 "une pose déposée avant le canal est appliquée une fois, la file est vidée, les éléments invalides sont ignorés" \
  "$(val D20.appliquee)" "relecture|1|3|0"
assert_eq D20 "la réexécution du script ne rejoue rien" "$(val D20.rejeu)" "0|0"
assert_eq D20 "les poses de la file s'appliquent dans l'ordre de dépôt" "$(val D20.ordre)" "b|col|b"
assert_eq D20 "sans file : aucune erreur, aucune file créée" "$(val D20.sans-file)" "null|undefined"

# ====================== moitié navigateur ======================
SCRIPTS="$(cd "$HERE/.." && pwd)"
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" > /dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then . "$HERE/chrome-saut.sh"; vf_chrome_saut "  ⊘ MOITIÉ NAVIGATEUR SAUTÉE : aucun navigateur (Chrome, Chromium) — la marque sur la carte NON vérifiée, non comptée comme réussie"; fin; fi
mkdir -p "$WORK/home/.claude"; export REAL_HOME="$HOME"; export HOME="$WORK/home"; AUX="$WORK/aux"; mkdir -p "$AUX"
. "$HERE/hygiene.sh"; vf_hyg_init
. "$HERE/socle-serveur.sh"
. "$FX/mk-lab.sh"
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; let j; try { j = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { console.log('sortie illisible'); process.exit(0); }
if (j.erreur) { console.log('mesure indisponible : ' + j.erreur); process.exit(0); }
const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
LAB="$WORK/lab"; mklab75 "$LAB"
mesurer() { REAL_HOME="$REAL_HOME" node "$HERE/chrome-activite-carte.mjs" "$CHROME" "http://127.0.0.1:$VF_PORT" "$1" > "$WORK/mesure.json" 2> "$WORK/mesure.err"; cat "$WORK/mesure.json"; } # sections en $1 ; le serveur courant (VF_PORT)
E() { printf '%s' "$R" | node "$AUX/ev.mjs" "$1"; }
mutant_rouge() { # mutant_rouge <nom> <sections> <expression de mutation sed, sur chaque source de page> <expression js : vraie quand la suite a VU le mutant> ; le serveur du mutant est arrêté ensuite
  local nom="$1" sec="$2" sed_="$3" vu="$4" RM
  if ! cockpit_module_muter_page "$nom" "$sed_"; then ok_ko "$nom : la mutation n'a rien changé (ancre périmée)"; return; fi
  cockpit_lancer "$LAB"; local rc=$?
  if [ "$rc" -ne 0 ]; then ok_ko "$nom : le serveur du mutant ne démarre pas (code $rc)"; unset COCKPIT_MODULE; return; fi
  RM="$(mesurer "$sec")"; cockpit_arreter; unset COCKPIT_MODULE; export VF_PORT="$PORT" # le serveur du lab (non muté) reste celui des témoins suivants
  if [ "$(printf '%s' "$RM" | node "$AUX/ev.mjs" "$vu")" = "true" ]; then echo "  MUTANT-ROUGE — $nom"; else ok_ko "$nom : le mutant n'est pas vu rouge (attendu: vrai)"; fi
}
ok_ko() { echo "  ❌ FAIL — MUTANT : $1"; FAIL=$((FAIL+1)); fin; }
cockpit_lancer "$LAB"; PORT="${VF_PORT:-0}"
assert_eq D0 "serveur du lab démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"

echo "== D3 la marque, le mot par textContent, noms hostiles =="
R="$(mesurer d3)"
assert_eq D3 "le dossier aux fichiers hostiles (balises, très long, U+2028) garde ses 17 cartes" "$(E 'j.d3.cartesB')" "17"
assert_eq D3 "une marque posée sur une carte ajoute UN .lm dans son pied" "$(E 'j.d3.n')" "1"
assert_eq D3 "le mot hostile est lu tel quel, sans aucun élément enfant" "$(E 'j.d3.mot === j.d3.hostile && j.d3.enfants === 0')" "true"
assert_eq D3 "l'infobulle est le texte littéral" "$(E 'j.d3.titre === j.d3.hostile')" "true"
assert_eq D3 "aucun élément injecté, aucun script exécuté, marque cachée aux lecteurs d'écran" "$(E 'j.d3.injectes === j.d3.avant && j.d3.xss && j.d3.cache')" "true"
mutant_rouge "D3-texte-par-innerHTML" d3 's/e\.textContent = txt/e.innerHTML = txt/' 'j.d3.injectes > j.d3.avant || !j.d3.xss'

echo "== D4 géométrie invariante, aucun render() après une pose =="
R="$(mesurer d4)"
assert_eq D4 "trois largeurs, deux conteneurs, trois paliers de zoom : 18 séries mesurées" "$(E 'j.d4.length')" "18"
assert_eq D4 "la pose a marqué des cartes dans chaque série qui en a un pied (mesure non aveugle ; les cartes de fichier sans pied : tâche 2)" "$(E 'j.d4.filter((x) => x.marques > 0).length')" "9"
assert_eq D4 "géométrie des cartes et hauteur des pieds identiques à 0 px après poser, retirer, cinq bascules et une mise à jour" "$(E 'j.d4.filter((x) => x.ecarts.length).length')" "0"
assert_eq D4 "aucun événement render après les poses" "$(E 'j.d4.filter((x) => x.renders > 0).length')" "0"
mutant_rouge "D4-pose-relance-le-placement" d4 's/const change = () => { index = null; dessiner(); };/const change = () => { index = null; dessiner(); if (moteur() \&\& moteur().rerender) moteur().rerender(); };/' 'j.d4.some((x) => x.renders > 0)'

fin
