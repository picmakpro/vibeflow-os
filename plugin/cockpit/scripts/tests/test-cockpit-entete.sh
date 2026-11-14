#!/usr/bin/env bash
# test-cockpit-entete.sh — le titre de vue et l'en-tête lisibles (80-20, FORM-18, P80-D-52, P80-D-53, P80-D-56), un vrai Chrome, sans réseau.
#   EN1 zone du titre : aucune carte dessinée ni atteignable sous #context (Code, graphe de Projet ; pan, zoom), mise en page inchangée, couloirs et liste
#       sans découpe, zone basse inchangée, aller-retour d'onglet, observateurs et écouteurs sans cumul (idiome A51, P80-D-59)
#   EN2 en-tête : trois groupes libellés au-delà de 1 280 px, chevron du fil d'Ariane, icônes justes, point de #vf-lock, Santé et menu des parcours
#   EN3 ouvreur Git dessiné à --hdr-btn, zone d'appui de 44 × 44, mouvement réduit
#   Régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) : pas de mutant.
#   EN_SCRIPTS = dossier de scripts à bâtir (rejeu sur la base).
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
  vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — le titre de vue et l'en-tête NON vérifiés, non comptés comme réussis"; exit 0
fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0; SC_BASE="${EN_SCRIPTS:-$SCRIPTS}"
. "$HERE_T/couloirs-commun.sh"
UIDIR="$ENG/assets/ui"
mesurer() { REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-entete.mjs" "$CHROME" "http://127.0.0.1:$PORT" "$1" 2>"$WORK/mesure.err"; }
sonde() { [ -n "${SONDE:-}" ] && { printf '%s\n' "$1"; cat "$WORK/mesure.err"; }; return 0; }
# un lab dont la racine de Code porte assez de cartes pour qu'un glisser en amène une sous le titre
LAB="$WORK/lab"; mklab "$LAB"; mkdir -p "$LAB/src" "$LAB/lib"
for i in 1 2 3 4 5 6; do
  printf 'export const v%s = %s;\n' "$i" "$i" > "$LAB/src/m$i.js"; printf '# n%s\n' "$i" > "$LAB/lib/n$i.md"
done
# un travail récent : le bouton « Travail récent » est posé
printf -- '---\nfiles_modified: [src/m1.js]\n---\n<objective>Écran</objective>\n' > "$LAB/.planning/phases/02-ecran/02-01-PLAN.md"
git -C "$LAB" add -A && git -C "$LAB" -c user.email=t@t -c user.name=t commit -q -m fichiers
build_serve "$LAB" --terminal
assert_eq "EN0 — serveur du lab démarré (avec --terminal)" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"
cat_json() { tr -d '\n'; } # une valeur attendue écrite sur plusieurs lignes

echo "=== EN1 — le titre de vue a sa zone ==="
R1="$(mesurer en1)"; sonde "$R1"
for cle in code1440 code800 code390 graphe1440; do
  assert_eq "EN1.1 ($cle) — après un glisser puis « + » : aucune .card ni g.node sous les 8 × 4 points de #context" \
    "$(E "(() => { const z = j.zone['$cle']; return [z.pose, z.apres_glisser.n, z.apres_zoom.n, z.apres_glisser.total]; })()" "$R1")" '[true,0,0,32]'
done
assert_eq "EN1.2 — hauteur de la zone ≤ 130 px, le texte du titre et le flou (halo de #context::before) sont gardés" \
  "$(E "Object.values(j.zone).map((z) => [z.apres_glisser.h <= 130, z.texte.length > 0, /blur/.test(z.flou)])" "$R1")" \
  '[[true,true,true],[true,true,true],[true,true,true],[true,true,true]]'
MISE='Object.values(j.zone).map((z) => [Math.round(z.mise.t.k * 100) / 100, Math.round(z.mise.t.x), Math.round(z.mise.t.y),
  z.mise.fa.y, z.mise.fa.w, z.mise.fa.h])'
assert_eq "EN1.2b — freeArea() et la transformation après « f » égales à la base fusionnée (mise en page inchangée)" \
  "$(E "$MISE" "$R1")" '[[1.1,315,266,149,1016,675],[1.1,191,327,141,768,631],[0.85,33,325,136,358,580],[0.93,52,158,149,1016,675]]'
assert_eq "EN1.3 — couloirs et liste : #svg sans découpe" "$(E "[j.vues.couloirs.clip, j.vues.liste.clip]" "$R1")" '["none","none"]'
R14="$(mesurer en14)"; sonde "$R14"
BAS='calc(@px + var(--edge) + var(--sp-8) + var(--edge) + env(safe-area-inset-bottom, 0px))'
BAS14="$(cat_json <<EOF
{"390":{"ask":null,"zoom":null,"past":[16,303,355],"feuille":[8,363,382,836],"bas":"${BAS/@/N}"},
"800":{"ask":[16,792,392,884],"zoom":null,"past":[16,732,784],"feuille":[424,60,784,884],"bas":"${BAS/@/144}"}}
EOF
)"
assert_eq "EN1.4 — zone basse à 390 et 800 px (lab --terminal, feuille ouverte) : rectangles et --vf-bas égaux à la base fusionnée" \
  "$(E "JSON.stringify(j.bas)" "$R14")" "$BAS14"
R15="$(mesurer en15)"; sonde "$R15"
assert_eq "EN1.5 — Code → Projet → Code par VF_ONGLETS.aller (même document) : zone absente de Projet, reposée sur Code" \
  "$(E "[j.origine, j.projet.clip, j.sous.n, j.sous.total, j.coupe.clip !== 'none']" "$R15")" '[true,"none",0,32,true]'
R16="$(mesurer en16)"; sonde "$R16"
assert_eq "EN1.6 — A51 : après deux allers-retours d'onglet, mêmes observateurs et écouteurs vivants qu'à froid, aucun cumul" \
  "$(E "[j.froid.ens[0] >= 1, j.froid.ens[1] >= 1, JSON.stringify(j.apres1) === JSON.stringify(j.froid),
    JSON.stringify(j.apres2) === JSON.stringify(j.froid)]" "$R16")" '[true,true,true,true]'

echo "=== EN2 — l'en-tête en trois groupes libellés, chevron, icônes, point de #vf-lock ==="
R2="$(mesurer en2)"; sonde "$R2"
GR='(() => { const g = j.g[@].#; return [g.groupes, ["Read,Follow,Display", "Lire,Suivre,Affichage"].includes(g.libs.join()), g.libVisibles,
  g.ratios.every((r) => r >= 4.5), g.taille.every((x) => x === "12px"), g.sansGroupe, g.deborde, g.dehors]; })()'
for w in 1440 1600; do for onglet in code codeClair projet equipe; do
  assert_eq "EN2.1 ($w px, $onglet) — trois groupes libellés (12 px, ≥ 4,5:1), noms accessibles, aucun bouton sans groupe, pas de débordement" \
    "$(E "$(printf '%s' "$GR" | sed "s/@/$w/; s/#/$onglet/")" "$R2")" '[3,true,true,true,true,0,false,0]'
done; done
assert_eq "EN2.1b — en français (?lang=fr) les libellés sont Lire, Suivre, Affichage (dictionnaire du chrome)" \
  "$(E "j.fr.libs.join()" "$R2")" "Lire,Suivre,Affichage"
IDS='["vf-git-ouvreur","theme-toggle","btn-health","btn-recent","tour-btn","btn-export","vf-lock","flows-btn","filters-btn","btn-panel","vf-plus"]'
for w in 1279 1100 800 390; do
  assert_eq "EN2.2 ($w px) — aucun groupe ni libellé, ordre DOM des boutons de .hr inchangé" \
    "$(E "[j.inv[$w].groupes, j.inv[$w].libs, JSON.stringify(j.inv[$w].ids)]" "$R2")" "[0,0,\"$(printf '%s' "$IDS" | sed 's/"/\\"/g')\"]"
done
RECTS="$(cat_json <<'EOF'
[[["vf-git-ouvreur",867,14,36,36],["theme-toggle",907,14,36,36],["btn-health",947,14,36,36],["btn-recent",987,14,36,36],
["tour-btn",1027,14,36,36],["btn-export",1067,14,36,36],["vf-lock",1107,14,36,36],["flows-btn",1147,14,36,36],
["filters-btn",1187,14,36,36],["btn-panel",1227,14,36,36]],
[["vf-git-ouvreur",688,14,36,36],["theme-toggle",728,14,36,36],["btn-health",768,14,36,36],["btn-recent",808,14,36,36],
["tour-btn",848,14,36,36],["btn-export",888,14,36,36],["vf-lock",928,14,36,36],["flows-btn",968,14,36,36],
["filters-btn",1008,14,36,36],["btn-panel",1048,14,36,36]],
[["vf-git-ouvreur",592,6,44,44],["vf-lock",640,6,44,44],["btn-panel",696,6,44,44],["vf-plus",744,6,44,44]],
[["vf-lock",282,6,44,44],["vf-plus",338,6,44,44]]]
EOF
)"
assert_eq "EN2.2b — rectangles des boutons de .hr égaux à la base de 1279 à 390 px (sauf l'ouvreur Git à 36 px : P80-D-56)" \
  "$(E "JSON.stringify([1279, 1100, 800, 390].map((w) => j.inv[w].bt))" "$R2")" "$RECTS"
assert_eq "EN2.2c — de 1440 à 1100 px sans recharger : les groupes sont défaits, ordre et rectangles ceux d'un chargement à 1100 px (déplacés, jamais clonés)" \
  "$(E "[j.avantRetour.groupes, JSON.stringify(j.retour.ids) === JSON.stringify(j.inv[1100].ids),
    JSON.stringify(j.retour.bt) === JSON.stringify(j.inv[1100].bt), j.retour.groupes]" "$R2")" '[3,true,true,0]'
assert_eq "EN2.3 — fil d'Ariane : chaque .sep porte un svg aria-hidden et aucun « / » ; l'en-tête ne déborde pas" \
  "$(E "[1440, 800].map((w) => [j.chev[w].n >= 1, j.chev[w].svg, j.chev[w].texte])
    .concat([[1440, 800, 390].map((w) => j.chev[w].deborde)])" "$R2")" '[[true,true,""],[true,true,""],[false,false,false]]'
assert_eq "EN2.4 — Parcours n'a plus le triangle de lecture, Travail récent n'a plus l'air d'un chargement" \
  "$(E "[j.icones.flows !== 'M7 5v14l11-7z', !/M12 3v3M12 18v3/.test(j.icones.recent), /^M3 12a9 9/.test(j.icones.recent)]" "$R2")" '[true,true,true]'
POINT='{"clip":"@","w":#,"bl":"%","ligne":"220px","nom":"220px"}'
POINT_A="$(printf '%s' "$POINT" | sed 's/@/path(/; s/#/16/; s/%/none/')"; POINT_B="$(printf '%s' "$POINT" | sed 's/@/none/; s/#/8/; s/%/block/')"
assert_eq "EN2.4b — #vf-lock : glyphe de sessions de 701 à 1 639 px (libellé masqué), point et libellé au-delà ; troncature à 220 px gardée" \
  "$(E "[j.point1100, j.point1700]" "$R2")" "[$POINT_A,$POINT_B]"
assert_eq "EN2.5 — à 1440 px : Santé s'ouvre, Échap la ferme et rend le focus à #btn-health ; le menu des parcours s'ouvre sous son bouton et Échap le ferme" \
  "$(E "[j.sante.ouvert, j.sante.focus, j.sante.menu[0], j.sante.menu[1], j.sante.ferme]" "$R2")" '[true,"btn-health",true,true,true]'

echo "=== EN3 — l'ouvreur Git dessiné comme ses voisins, zone d'appui de 44 px ==="
R3="$(mesurer en3)"; sonde "$R3"
CLES="['800', '1100', '1279', '1100t', '1279t']"
assert_eq "EN3.1 — boîte dessinée de l'ouvreur : 36 px au pointeur fin à partir de 1 000 px (comme ses voisins), 44 px en dessous et au toucher" \
  "$(E "$CLES.map((k) => [j.o[k].w, j.o[k].h, j.o[k].voisin])" "$R3")" '[[44,44,44],[36,36,36],[36,36,36],[44,44,44],[44,44,44]]'
assert_eq "EN3.2 — zone d'appui : les points à 1 px d'un carré de 44 × 44 centré sur l'ouvreur tombent sur lui, en tête de .hr" \
  "$(E "$CLES.map((k) => [j.o[k].pts.every((x) => x), j.o[k].premier])" "$R3")" '[[true,true],[true,true],[true,true],[true,true],[true,true]]'
assert_eq "EN3.3 — l'appui ne rend pas l'ouvreur « rogné » (scrollWidth et scrollHeight égaux à la boîte dessinée)" \
  "$(E "$CLES.map((k) => j.o[k].rogne)" "$R3")" '[false,false,false,false,false]'
assert_eq "EN3.4 — mouvement réduit : aucune animation active après un glisser, un zoom puis le passage de 1 440 à 1 100 px" \
  "$(E "j.actives" "$R3")" '[0,0]'
vf_hyg_stop "$SRV"
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
