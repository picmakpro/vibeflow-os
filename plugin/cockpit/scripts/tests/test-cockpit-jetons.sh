#!/usr/bin/env bash
# test-cockpit-jetons.sh — jetons d'état défaillants repris (80-16, FORM-14, P80-D-20, P80-D-31, P80-D-46), un vrai Chrome, deux thèmes, sans réseau.
#   JT1 glyphe « En cours » lisible en clair, --sev-medium inchangé, 01-vf-ensemble.js découpé, servi et chargé par arrivée
#   JT2 carte active claire sur --surface, cartes estompées lisibles avec leur pastille pleine, sombre inchangé
#   JT3 DESIGN.md à jour avec ses mesures, table des contrastes de 80-UI-SPEC.md § 5 remesurée en rendu
#   Régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) : pas de mutant.
#   JT_SCRIPTS = dossier de scripts à bâtir (rejeu sur la base).
# Sans navigateur : SUITE SAUTÉE (exit 0, message explicite), jamais un vert à vide.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"; ENG="$SCRIPTS/../skills/cockpit-moteur"
CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
if [ -z "$CHROME" ]; then
  . "$HERE_T/chrome-saut.sh"
  vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — les jetons d'état NON vérifiés, non comptés comme réussis"; exit 0
fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0; SC_BASE="${JT_SCRIPTS:-$SCRIPTS}"
. "$HERE_T/couloirs-commun.sh"
UIDIR="$ENG/assets/ui"; ENS="$UIDIR/01-vf-ensemble.js"; VIEWER="$ENG/assets/viewer.html"; DESIGN="$SCRIPTS/../../../DESIGN.md"
mesurer() { REAL_HOME="$REAL_HOME" node "$HERE_T/$1" "$CHROME" "http://127.0.0.1:$PORT" "${2:-}" 2>"$WORK/mesure.err"; }
sonde() { [ -n "${SONDE:-}" ] && { printf '%s\n' "$1"; cat "$WORK/mesure.err"; }; return 0; }
LAB="$WORK/lab"; mklab "$LAB"
build_serve "$LAB"
assert_eq "JT0 — serveur du lab démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"

echo "=== JT1 — glyphe « En cours » lisible en clair, découpe de 00-vibeflow.js ==="
R1="$(mesurer chrome-jetons.mjs jt1)"; sonde "$R1"; E1() { E "$1" "$R1"; }
assert_eq "JT1.1 — clair : glyphe En cours du canevas et du couloir ≥ 3,5:1 sur --bg et ≥ 3:1 sur --surface (base : 3,06 et 3,40)" \
  "$(E1 '[j.clair.canevas.bg >= 3.5, j.clair.canevas.surface >= 3, j.clair.couloir.bg >= 3.5, j.clair.couloir.surface >= 3]')" '[true,true,true,true]'
assert_eq "JT1.1b — sombre : le même glyphe tient les mêmes seuils" \
  "$(E1 '[j.sombre.canevas.bg >= 3.5, j.sombre.canevas.surface >= 3, j.sombre.couloir.bg >= 3.5]')" '[true,true,true]'
assert_eq "JT1.2 — --sev-medium identique dans les deux thèmes (clair #b88100, sombre #ffe08a) ; texte des puces sur --sev-medium ≥ 4,5:1" \
  "$(E1 '[j.clair.sev, j.sombre.sev, j.clair.puce >= 4.5, j.sombre.puce >= 4.5]')" '["184,129,0","255,224,138",true,true]'
assert_eq "JT1.3 — sombre : --st-active inchangé (= --sev-medium) ; --st-recette suit --st-active dans les deux thèmes" \
  "$(E1 '[j.sombre.actif, j.sombre.recette === j.sombre.actif, j.clair.recette === j.clair.actif,
    j.clair.actif !== j.clair.sev]')" \
  '["255,224,138",true,true,true]'
LIG() { awk 'END { print NR }' "$1"; }
LONG() { awk 'length($0) > 160 { n++ } END { print n + 0 }' "$1"; }
assert_eq "JT1.4 — 00-vibeflow.js et 01-vf-ensemble.js ≤ 299 lignes, aucune ligne de plus de 160 colonnes "\
"dans le fichier neuf, M5.1 : --st-active: var(--sev-medium) gardé" \
  "$([ -f "$ENS" ] && [ "$(LIG "$UIDIR/00-vibeflow.js")" -le 299 ] && [ "$(LIG "$ENS")" -le 299 ] \
    && echo ok || echo ko)|$([ -f "$ENS" ] && LONG "$ENS" || echo absent)\
|$(grep -c -e '--st-active: var(--sev-medium)' "$UIDIR/00-vibeflow.js")" "ok|0|1"
cockpit_get /_vf/ui/01-vf-ensemble.js > /dev/null; CODE15="${VF_CODE:-000}"
R15="$(mesurer chrome-jetons.mjs jt15)"; sonde "$R15"
assert_eq "JT1.5 — 01-vf-ensemble.js servi sous /_vf/ui/ (200), chargé par la page, et chargé exactement comme "\
"00-vibeflow.js à chaque arrivée d'onglet (extension d'onglet, jamais persistante)" \
  "$CODE15|$(E '[j.jt15.charge[0] >= 1, j.jt15.charge[0] === j.jt15.charge[1],
    j.jt15.apres1[0] === j.jt15.apres1[1], j.jt15.apres2[0] === j.jt15.apres2[1],
    j.jt15.apres2[0] > j.jt15.apres1[0], j.jt15.onglet]' "$R15")" \
  '200|[true,true,true,true,true,"project"]'

echo "=== JT2 — carte active claire, cartes estompées ==="
R2="$(mesurer chrome-jetons.mjs jt2)"; sonde "$R2"; E2() { E "$1" "$R2"; }
assert_eq "JT2.1 — clair : carte st-active et st-recette sur --surface (ni fond grisé ni teinté), --shadow-card gardé, aucun contour ajouté" \
  "$(E2 '[j.clair.actif, j.clair.recette].map((c) => c && [c.fond === c.surface, c.fond !== c.melange,
    c.ombre, c.bord])')" \
  '[[true,true,true,"0px|none"],[true,true,true,"0px|none"]]'
assert_eq "JT2.2 — cartes estompées, les deux thèmes : texte composé avec l'opacité ≥ 4,5:1 ; "\
"pastille d'état à opacité 1, glyphe ≥ 3:1 (≥ 3,5:1 pour En cours)" \
  "$(E2 '["clair", "sombre"].map((t) => [j[t].dim, j[t].texte.n > 0, j[t].texte.min >= 4.5,
    j[t].pastilles.length > 0,
    j[t].pastilles.every((p) => p.alpha === 1 && p.ratio >= (/vst-active/.test(p.cls) ? 3.5 : 3))])')" \
  '[[true,true,true,true,true],[true,true,true,true,true]]'
assert_eq "JT2.3 — sombre : carte active et à recetter inchangées (fond = mélange --raise 70 % / --surface, ombre = --shadow-card)" \
  "$(E2 '[j.sombre.actif, j.sombre.recette].map((c) => c && [c.fond === c.melange, c.ombre])')" '[[true,true],[true,true]]'

echo "=== JT3 — DESIGN.md et table des contrastes ==="
RJ3="$(mesurer chrome-jetons.mjs jt3)"; sonde "$RJ3"
assert_eq "JT3.1 — DESIGN.md : phrase de l'anneau de focus (§ 9), rangée de liste dense (§ 4), "\
"--st-active clair mesuré (§ 2), carte active claire sans fond teinté (§ 5)" \
  "$(grep -c "intention d'élévation" "$DESIGN")|$(grep -c 'rangée de liste dense' "$DESIGN")\
|$(grep -c 'a37100' "$DESIGN")|$(grep -c 'jamais fond teinté' "$DESIGN")" "1|1|1|1"
assert_eq "JT3.2 — table de 80-UI-SPEC.md § 5 remesurée en rendu : texte ≥ 4,5:1, non-texte ≥ 3:1, "\
"--st-active ≥ 3,5:1 sur --bg et ≥ 3:1 sur --surface, deux thèmes" \
  "$(E '["clair", "sombre"].map((t) => [Object.values(j[t].texte).every((v) => v >= 4.5),
    Object.values(j[t].nonTexte).every((v) => v >= 3), j[t].actif.bg >= 3.5, j[t].actif.surface >= 3])' "$RJ3")" \
  '[[true,true,true,true],[true,true,true,true]]'
assert_eq "JT3.3 — css-jetons.mjs sur 01-vf-ensemble.js rend 0 (aucune couleur littérale, grille d'espacement)" \
  "$([ -f "$ENS" ] && node "$HERE_T/css-jetons.mjs" "$ENS" > /dev/null 2>&1 && echo 0 || echo non)" "0"
echo "     valeurs mesurées (SUMMARY) : $(printf '%s' "$RJ3" | node -e 'let s="";process.stdin.on("data",d=>s+=d)
.on("end",()=>{try{const j=JSON.parse(s);console.log(JSON.stringify({clair:j.clair,sombre:j.sombre}))}
catch{console.log("illisible")}})')"
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
