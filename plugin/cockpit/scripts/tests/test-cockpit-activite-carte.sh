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
LAB="$WORK/lab"; mklab75 "$LAB"; LABG="$WORK/lab-nogit"; mklab75 "$LABG" nogit
node "$FX/mk-agents.mjs" "$HOME" "$LAB" aaaa1111-2222-3333-4444-555555555555
cat > "$AUX/cmp.mjs" <<'JS'
import fs from 'node:fs'; const [, , fa, fb, expr] = process.argv; const lire = (f) => { try { const j = JSON.parse(fs.readFileSync(f, 'utf8')); return j.erreur ? { erreur: j.erreur } : j; } catch { return { erreur: 'illisible' }; } };
const a = lire(fa), b = lire(fb); if (a.erreur || b.erreur) { console.log('mesure indisponible : ' + (a.erreur || b.erreur)); process.exit(0); }
const v = new Function('a', 'b', 'return (' + expr + ')')(a, b); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
mesurer() { REAL_HOME="$REAL_HOME" node "$HERE/chrome-activite-carte.mjs" "$CHROME" "http://127.0.0.1:$VF_PORT" "$1" "${2:-}" > "$WORK/mesure.json" 2> "$WORK/mesure.err"; cat "$WORK/mesure.json"; } # sections en $1 (et la session d'équipe en $2) ; le serveur courant (VF_PORT)
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
assert_eq D4 "la pose a marqué des cartes dans chacune des 18 séries (mesure non aveugle : toute carte marquable a son pied)" "$(E 'j.d4.filter((x) => x.marques > 0).length')" "18"
assert_eq D4 "géométrie des cartes et hauteur des pieds identiques à 0 px après poser, retirer, cinq bascules et une mise à jour" "$(E 'j.d4.filter((x) => x.ecarts.length).length')" "0"
assert_eq D4 "aucun événement render après les poses" "$(E 'j.d4.filter((x) => x.renders > 0).length')" "0"
mutant_rouge "D4-pose-relance-le-placement" d4 's/const change = () => { index = null; dessiner(); };/const change = () => { index = null; dessiner(); if (moteur() \&\& moteur().rerender) moteur().rerender(); };/' 'j.d4.some((x) => x.renders > 0)'

echo "== D6 le pied est réservé à la construction, sans lentille =="
R="$(mesurer d6)"
FICH='(c, z) => Object.values(j.d6).flatMap((o) => o[z]).filter((x) => x[0] === "f:")'
assert_eq D6 "toute carte de fichier de l'onglet Code a un pied de 20 à l'ouverture, sans lentille ni taille" "$(E "(${FICH})(0, 'ouverture').every((x) => x[1] === 20)")" "true"
assert_eq D6 "28 à lod-mid et à lod-low" "$(E "(${FICH})(0, 'mid').every((x) => x[1] === 28) && (${FICH})(0, 'bas').every((x) => x[1] === 28)")" "true"
assert_eq D6 "témoin positif : il y a des cartes de fichier (31) et des connecteurs sans aucun pied" "$(E "[(${FICH})(0, 'ouverture').length, Object.values(j.d6).flatMap((o) => o.ouverture).filter((x) => x[0] === 'x:').length > 0, Object.values(j.d6).flatMap((o) => o.ouverture).filter((x) => x[0] === 'x:').every((x) => x[1] === null)].join('|')")" "31|true|true"
echo "== D7 la réserve ne dépend ni de la lentille ni de git =="
PORT_GIT="$VF_PORT"; cockpit_lancer "$LABG"; R7="$(mesurer d6)"; export VF_PORT="$PORT_GIT"
printf '%s' "$R" > "$WORK/r-git.json"; printf '%s' "$R7" > "$WORK/r-nogit.json"
assert_eq D7 "lab sans git : mêmes pieds, au même instant (aucune lentille posée dans les deux cas)" "$(node "$AUX/cmp.mjs" "$WORK/r-git.json" "$WORK/r-nogit.json" 'JSON.stringify(a.d6) === JSON.stringify(b.d6) && Object.keys(a.d6).length === 2')" "true"
cockpit_module_muter_page sans-reserve 's/const reserve = /const reserve = false \&\& /' || { ok_ko "D6b : la mutation « sans réserve » n'a rien changé"; }
cockpit_lancer "$LAB"; PORT_BASE="$VF_PORT"
echo "== D6b, D8, D8b la réserve est bornée à l'onglet Code, et ne change aucun palier de zoom =="
mesurer d8 mgr1 > "$WORK/d8-base.json"; cockpit_arreter; unset COCKPIT_MODULE; export VF_PORT="$PORT"
mesurer d8 mgr1 > "$WORK/d8-reel.json"
assert_eq D6b "Projet : géométrie de chaque carte (x, y, largeur, hauteur, pied) IDENTIQUE à celle du module sans réserve" "$(node "$AUX/cmp.mjs" "$WORK/d8-base.json" "$WORK/d8-reel.json" 'a.d8.projet.length > 150 && a.d8.projet === b.d8.projet')" "true"
assert_eq D6b "Équipe : même géométrie, identique à 0 px" "$(node "$AUX/cmp.mjs" "$WORK/d8-base.json" "$WORK/d8-reel.json" 'a.d8.equipe.length > 150 && a.d8.equipe === b.d8.equipe')" "true"
assert_eq D6b "témoin positif : sur Code la réserve change bien la hauteur des cartes sans pied (le sans réserve en compte, le réel aucune)" "$(node "$AUX/cmp.mjs" "$WORK/d8-base.json" "$WORK/d8-reel.json" 'a.d8.code.some((x) => x.sansPied > 0) && b.d8.code.every((x) => x.sansPied === 0)')" "true"
echo "  D8 (chiffres, avant → après la réserve) :"
node "$AUX/cmp.mjs" "$WORK/d8-base.json" "$WORK/d8-reel.json" 'a.d8.code.map((x, i) => `${x.w} px ${x.cont} : ${x.cartes} cartes, ${x.sansPied} sans pied, hauteur ${x.H} → ${b.d8.code[i].H}, largeur ${x.W} → ${b.d8.code[i].W}, k ${x.k} → ${b.d8.code[i].k}`).join("\n")' | sed 's/^/    /'
PAL='(k) => (k < 0.42 ? "bas" : k < 0.65 ? "mid" : "ouverture")'
if [ "$(node "$AUX/cmp.mjs" "$WORK/d8-base.json" "$WORK/d8-reel.json" "a.d8.code.every((x, i) => (${PAL})(x.k) === (${PAL})(b.d8.code[i].k))")" != true ]; then echo "  ARRET-D25 : la réserve du pied change le palier de zoom d'ouverture (0,65 ou 0,42) : arrêt, à remonter au manager"; FAIL=$((FAIL+1)); fin; fi
assert_eq D8b "le k d'ouverture reste dans son palier (0,65 et 0,42) à 1440 et à 390 px, sur les quatre niveaux" "oui" "oui"

echo "== D9 silhouettes à k = 0,42, paliers de barres, pavé d'encre =="
R="$(mesurer d9)"
assert_eq D9 "les quatre silhouettes d'Empreinte : distance de Jaccard >= 0,25 deux à deux" "$(E "j.d9.empreinte.filter((p) => p[1] < 0.25).map((p) => p.join('=')).join(',')")" ""
assert_eq D9 "bouclier plein contre bouclier évidé barré : >= 0,25" "$(E "j.d9.boucliers.filter((p) => p[1] < 0.25).map((p) => p.join('=')).join(',')")" ""
assert_eq D9 "{confluent, bouclier plein, bouclier évidé} deux à deux : >= 0,25" "$(E "j.d9.trio.filter((p) => p[1] < 0.25).map((p) => p.join('=')).join(',')")" ""
assert_eq D9 "chaque glyphe à >= 0,25 du triangle « tolere » existant" "$(E "j.d9.tolere.filter((p) => p[1] < 0.25).map((p) => p.join('=')).join(',')")" ""
assert_eq D9 "encre minimale : au moins 5 % de la boîte pour chacun des onze glyphes" "$(E "j.d9.encre.filter((p) => p[1] < 0.05).map((p) => p.join('=')).join(',')")" ""
assert_eq D9b "barres 1, 2, 3 : autant de hauteurs distinctes que de barres, chacune séparée d'une colonne éteinte, aux quatre décalages" "$(E "j.d9.barres.filter(([, n, v]) => v.some((x) => x.groupes !== n || x.hauteurs !== n)).map((b) => b[0]).join(',')")" ""
assert_eq D9b "palier bas à >= 0,25 du tiret « fini »" "$(E 'j.d9.basFini >= 0.25')" "true"
assert_eq D9d "le pavé d'encre de chacun des onze glyphes tient dans [1,5 ; 14,5]² du viewBox, trait compris" "$(E "Object.entries(j.d9.ink).filter(([k, v]) => k !== 'tolere' && (v[0] < 1.45 || v[1] < 1.45 || v[2] > 14.55 || v[3] > 14.55)).map(([k, v]) => k + ':' + v.join('/')).join(',')")" ""

echo "== D10 contraste, deux thèmes =="
R="$(mesurer d10)"
for TH in dark light; do
  assert_eq D10 "thème $TH : chaque glyphe >= 3:1 sur --surface, --raise et le canevas (en cours : --recent sur --surface et le canevas, --recent-text sur .module)" "$(E "Object.entries(j.d10.$TH.min).filter(([, v]) => v < 3).map((p) => p.join('=')).join(',')")" ""
  assert_eq D10 "thème $TH : --recent n'est employé que par « en cours » ; sur .module le glyphe « en cours » prend --recent-text" "$(E "[j.d10.$TH.recentHors.length, j.d10.$TH.enCoursSurRaise, j.d10.$TH.enCoursSurSurface].join('|')")" "0|true|true"
done

echo "== D11 trois zooms, D3b largeur, D11b pied de lod-mid, D12 aucun fond =="
R="$(mesurer d11)"
assert_eq D11 "ouverture : glyphe de 1,45 em (16 px), mot complet, pied de 20, bord droit dans la carte, bord bas dans le pied" "$(E "(({ a }) => [Math.abs(a.lgPx - 16) <= 1, a.lw !== 'none', a.lc === 'none', a.pied === 20, a.droit, a.bas].join('|'))(j.d11.zooms.ouverture)")" "true|true|true|true|true|true"
assert_eq D11 "lod-mid : glyphe de 24 unités, forme courte, padding 0 12, pied de 28" "$(E "(({ a }) => [a.lgPx === 24, a.lw === 'none', a.lc !== 'none', a.pad === '12px|12px|0px', a.pied === 28, a.droit, a.bas].join('|'))(j.d11.zooms.mid)")" "true|true|true|true|true|true|true"
assert_eq D11 "lod-low : glyphe seul (24 unités), mot et forme courte masqués, pied de 28" "$(E "(({ a }) => [a.lgPx === 24, a.lw === 'none', a.lc === 'none', a.pied === 28, a.droit, a.bas].join('|'))(j.d11.zooms.bas)")" "true|true|true|true|true|true"
assert_eq D3 "S8 : un mot très long s'ellipse à l'ouverture, le glyphe garde sa taille et la marque reste dans la carte" "$(E "(({ b }) => [b.ellipse, b.lgPx > 14, b.droit, b.mot === 300].join('|'))(j.d11.zooms.ouverture)")" "true|true|true|true"
assert_eq D11b "lod-mid : un .meta long s'ellipse sans faire sortir la marque ni déborder le pied de 28" "$(E "[j.d11.metaLong.ellipse, j.d11.metaLong.droit, j.d11.metaLong.bas, j.d11.metaLong.pied].join('|')")" "true|true|true|28"
assert_eq D12 "la marque n'ajoute ni fond, ni image, ni ombre, ni liseré, ni contour, ni rayon ; l'ombre de la carte est inchangée" "$(E "j.d11.style.marque.every((x) => x === 'rgba(0, 0, 0, 0)|none|none|0px|none|0px') && j.d11.style.carteAvant === j.d11.style.carteApres")" "true"
echo "== D17 respiration du glyphe « en cours », coupée en mouvement réduit =="
R="$(mesurer d17)"
echo "  (keyframe vfrespire chargé sur l'onglet Code : $(E 'j.d17.keyframeVfrespire'))"
assert_eq D17 "animation calculée présente en mouvement normal, absente sous prefers-reduced-motion: reduce" "$(E "[j.d17.normal !== 'none', j.d17.reduit === 'none'].join('|')")" "true|true"

fin
