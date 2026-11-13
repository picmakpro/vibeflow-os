#!/usr/bin/env bash
# test-cockpit-neutre.sh — attribut neutre posé par le terminal sur ses éléments flottants (80-neutre), un vrai Chrome, sans réseau.
#   NE1 lecteurs : une région fixe étrangère n'est plus prise pour le tiroir du terminal (00 : la pile) ; un bouton fixe étranger n'est
#       plus un obstacle des repères (02) ; le même élément marqué data-vf-flottant l'est (témoins positifs, contre une lecture supprimée)
#   NE2 tiroir Git ouvert PUIS un petit élément fixe posé en bas à gauche (la pastille arrive après lui) : aucun chevauchement sans redimensionnement
#   (la lecture de 41-vf-projet-vue.js est gardée par CL4.3 de test-cockpit-couloirs.sh)
#   Mutants (copie COMPLÈTE du module, serveur lancé par cockpit_lancer, code 5 si la copie n'est pas celle qui est chargée) :
#   M-FORME-PILE, M-FORME-REPERES, M-EVITER-REJEU
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
  vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur — l'attribut neutre des flottants NON vérifié, non compté comme réussi"; exit 0
fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0; SC_BASE="${NE_SCRIPTS:-$SCRIPTS}"
. "$HERE_T/couloirs-commun.sh"
mesurer() { REAL_HOME="$REAL_HOME" node "$HERE_T/$1" "$CHROME" "http://127.0.0.1:$PORT" "${2:-}" "${3:-}" "${4:-}" 2>"$WORK/mesure.err"; }
LAB="$WORK/lab"; mklab "$LAB"
build_serve "$LAB"
assert_eq "NE0 — serveur du lab démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"

echo "=== NE1 — les lecteurs lisent l'attribut, jamais une forme ==="
RP="$(mesurer chrome-neutre.mjs pile)"; RPM="$(mesurer chrome-neutre.mjs pile-marque)"
RR="$(mesurer chrome-neutre.mjs reperes)"; RRM="$(mesurer chrome-neutre.mjs reperes-marque)"
RT="$(mesurer chrome-neutre.mjs tiroir)"; vf_hyg_stop "$SRV"
[ -z "${SONDE:-}" ] || { printf '%s\n' "$RP" "$RPM" "$RR" "$RRM" "$RT"; cat "$WORK/mesure.err"; }
assert_eq "NE1.1 — 00 : Échap tapé dans une région fixe ÉTRANGÈRE sous body ferme la palette (la pile ne la prend pas pour le tiroir du terminal)" \
  "$(E '[j.pris, j.palette]' "$RP")" '[true,false]'
assert_eq "NE1.2 — 00 (témoin positif) : la même région marquée data-vf-flottant=\"tiroir\" garde son Échap : la palette reste ouverte" \
  "$(E '[j.pris, j.palette]' "$RPM")" '[false,true]'
assert_eq "NE1.3 — 02 : un bouton fixe étranger couvrant la fenêtre n'est pas un obstacle : les repères restent posés ($(E 'j.avant + " -> " + j.apres' "$RR"))" \
  "$(E '[j.avant > 0, j.apres > 0]' "$RR")" '[true,true]'
assert_eq "NE1.4 — 02 (témoin positif) : le même bouton marqué data-vf-flottant=\"bouton\" est un obstacle : aucun repère n'a de place ($(E 'j.avant + " -> " + j.apres' "$RRM"))" \
  "$(E '[j.avant > 0, j.apres]' "$RRM")" '[true,0]'

echo "=== NE2 — le tiroir Git se rejoue à l'arrivée d'un élément flottant ==="
assert_eq "NE2.1 — tiroir Git ouvert, PUIS un bouton fixe en bas à gauche : aucun chevauchement sans redimensionnement ; témoin : le redimensionnement n'en lève aucun" \
  "$(E '[j.apres, j.temoin]' "$RT")" '[false,false]'

echo "=== Mutants (copie du module dans \$WORK) ==="
SEL_PILE="document.querySelector('[data-vf-flottant=\"tiroir\"]')"
FORME_PILE="[...document.body.children].find((e) => e.matches('section[role=\"region\"]') && getComputedStyle(e).position === 'fixed')"
mutant M-FORME-PILE 00-vf-surcouches.js "$SEL_PILE" "$FORME_PILE" chrome-neutre.mjs pile ""
echo "     trace M-FORME-PILE — sonde NE1.1 [prise, palette] : attendu [true,false], obtenu $(E '[j.pris, j.palette]' "$RM")"
assert_eq "M-FORME-PILE — le mutant (lecture revenue à la forme) rougit NE1.1 : la région étrangère reprend l'Échap de la palette (témoin : palette ouverte)" \
  "$(E '[typeof j.pris, j.pris, j.palette]' "$RM")" '["boolean",false,true]'
SEL_REP="[...document.querySelectorAll('[data-vf-flottant]')]"
FORME_REP="[...document.body.children].filter((e) => e.matches('button, div[role=\"status\"], section[role=\"region\"]') && getComputedStyle(e).position === 'fixed')"
mutant M-FORME-REPERES 02-vf-reperes.js "$SEL_REP" "$FORME_REP" chrome-neutre.mjs reperes ""
echo "     trace M-FORME-REPERES — sonde NE1.3 [avant, après] : attendu repères posés des deux côtés, obtenu $(E 'j.avant + " -> " + j.apres' "$RM")"
assert_eq "M-FORME-REPERES — le mutant (lecture revenue à la forme) rougit NE1.3 : le bouton étranger fait disparaître les repères (témoin : ils existaient avant)" \
  "$(E '[j.avant > 0, j.apres]' "$RM")" '[true,0]'
OBS_ANCIEN="{ childList: true, attributes: true, attributeFilter: ['class', 'style'] }"
mutant M-EVITER-REJEU 77-vf-git-tiroir.js "$OBS_ANCIEN" "{ attributes: true, attributeFilter: ['class', 'style'] }" chrome-neutre.mjs tiroir ""
echo "     trace M-EVITER-REJEU — sonde NE2.1 [chevauche, témoin] : attendu [false,false], obtenu $(E '[j.apres, j.temoin]' "$RM")"
assert_eq "M-EVITER-REJEU — le mutant (rejeu d'eviter retiré à l'arrivée d'un enfant de body) rougit NE2.1 : la pastille chevauche le tiroir ouvert avant elle (témoin : le redimensionnement la dégage)" \
  "$(E '[typeof j.apres, j.apres, j.temoin]' "$RM")" '["boolean",true,false]'
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
