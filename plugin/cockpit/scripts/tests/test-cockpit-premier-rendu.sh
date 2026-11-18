#!/usr/bin/env bash
# test-cockpit-premier-rendu.sh — sur téléphone le cockpit apparaît dans son état final
#   (demande de Samuel relayée par le brief de la session principale, 2026-11-18) :
#   PR1 en-tête : un seul état visible, et rien de visible avant « ready » (Code, Projet ; visite déjà vue, première visite)
#   PR2 zoom : une seule place visible tant que la visite n'est pas ouverte ; la visite s'ouvre après la révélation
#       (le zoom monte alors une fois au-dessus d'elle)
#   PR3 carte : visite déjà vue, une seule transformation visible (aucun saut des cartes au premier cadrage)
#   PR4 bureau (1 280 px, souris) : la porte ne masque rien, l'en-tête est visible pendant le chargement comme avant
#   PR5 échec de lecture : l'écran « Lecture impossible » est visible, la porte ouverte
# Mesure : chrome-premier-rendu.mjs, une image par requestAnimationFrame, scripts /_vf/ ralentis de 40 ms chacun (un tunnel).
# PR_SCRIPTS = dossier de scripts à bâtir (rejeu sur une autre copie, la base sans la porte rougit PR1 à PR3).
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
  vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — le premier rendu sur téléphone NON vérifié, non compté comme réussi"; exit 0
fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0; SC_BASE="${PR_SCRIPTS:-$SCRIPTS}"
. "$HERE_T/couloirs-commun.sh"
mesurer() { REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-premier-rendu.mjs" "$CHROME" "http://127.0.0.1:$PORT" "$1" 2>"$WORK/mesure.err"; }
sonde() { [ -n "${SONDE:-}" ] && { printf '%s\n' "$1"; cat "$WORK/mesure.err"; }; return 0; }
LAB="$WORK/lab"; mklab "$LAB"; mkdir -p "$LAB/src"
for i in 1 2 3 4; do printf 'export const v%s = %s;\n' "$i" "$i" > "$LAB/src/m$i.js"; done
git -C "$LAB" add -A && git -C "$LAB" -c user.email=t@t -c user.name=t commit -q -m fichiers
build_serve "$LAB"
assert_eq "PR0 — serveur du lab démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"
# une image : [t, pret, porte, en-tête visible, zoom visible, visite visible, transformation visible, écran d'échec visible]
DIST='(i, k) => [...new Set(i.map((x) => x[k]).filter(Boolean))]'
echo "=== PR1 à PR3 — téléphone (390 × 844, tactile) ==="
RT="$(mesurer telephone)"; sonde "$RT"
assert_eq "PR1.1 — en-tête : un seul état visible par chargement (Code, Projet ; visite vue, première visite)" \
  "$(E "Object.values(j).map((c) => ($DIST)(c.images, 3).length)" "$RT")" '[1,1,1,1]'
assert_eq "PR1.2 — rien de l'en-tête n'est visible avant « ready » (data-vf-pret = oui)" \
  "$(E "Object.values(j).map((c) => c.images.filter((x) => x[3]).every((x) => x[1] === 'oui'))" "$RT")" '[true,true,true,true]'
assert_eq "PR2.1 — zoom : une seule place visible, visite déjà vue" \
  "$(E "[j['code-vue'], j['projet-vue']].map((c) => ($DIST)(c.images, 4).length)" "$RT")" '[1,1]'
# h : première image où l'en-tête se voit, z : le zoom, v : la visite ; « avant » = les places du zoom avant l'image qui précède la visite
PR22='[j["code-premiere"], j["projet-premiere"]].map((c) => { const i = c.images, h = i.findIndex((x) => x[3]), z = i.findIndex((x) => x[4]);
  const v = i.findIndex((x) => x[5]), avant = (DIST)(i.slice(0, v - 1 > h ? v - 1 : h + 1), 4);
  return [h >= 0 && h === z, v > h, avant.length, (DIST)(i, 4).length <= 2]; })'
assert_eq "PR2.2 — première visite : le zoom paraît avec l'en-tête, à sa place, et ne bouge qu'une fois, quand la visite s'ouvre après la révélation" \
  "$(E "${PR22//DIST/$DIST}" "$RT")" '[[true,true,1,true],[true,true,1,true]]'
assert_eq "PR3.1 — carte : une seule transformation visible, visite déjà vue (aucun saut des cartes)" \
  "$(E "[j['code-vue'], j['projet-vue']].map((c) => ($DIST)(c.images, 6).length)" "$RT")" '[1,1]'
echo "=== PR4 — bureau (1 280 × 800, souris) ==="
RB="$(mesurer bureau)"; sonde "$RB"
assert_eq "PR4.1 — la porte ne masque rien au bureau : l'en-tête est visible pendant le chargement, la porte finit ouverte" \
  "$(E "Object.values(j).map((c) => [c.images.some((x) => x[3] && x[1] !== 'oui'), c.images.at(-1)[2]])" "$RB")" '[[true,"ouverte"],[true,"ouverte"]]'
echo "=== PR5 — échec de lecture (téléphone) ==="
RE="$(mesurer echec)"; sonde "$RE"
assert_eq "PR5.1 — l'écran « Lecture impossible » est visible, la porte ouverte" \
  "$(E "[j.echec.images.at(-1)[2], j.echec.images.at(-1)[7]]" "$RE")" '["ouverte",true]'
vf_hyg_stop "$SRV"
echo "--- premier rendu : $PASS PASS, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
