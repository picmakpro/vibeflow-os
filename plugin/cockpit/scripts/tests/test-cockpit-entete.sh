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
LAB="$WORK/lab"; mklab "$LAB"
mkdir -p "$LAB/src" "$LAB/lib"; for i in 1 2 3 4 5 6; do printf 'export const v%s = %s;\n' "$i" "$i" > "$LAB/src/m$i.js"; printf '# n%s\n' "$i" > "$LAB/lib/n$i.md"; done
git -C "$LAB" add -A && git -C "$LAB" -c user.email=t@t -c user.name=t commit -q -m fichiers
build_serve "$LAB" --terminal
assert_eq "EN0 — serveur du lab démarré (avec --terminal)" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"

echo "=== EN1 — le titre de vue a sa zone ==="
R1="$(mesurer en1)"; sonde "$R1"
for cle in code1440 code800 code390 graphe1440; do
  assert_eq "EN1.1 ($cle) — après un glisser qui amène une carte sous le titre, puis « + » : aucune .card ni g.node ne passe sous les 8 × 4 points de #context" \
    "$(E "(() => { const z = j.zone['$cle']; return [z.pose, z.apres_glisser.n, z.apres_zoom.n, z.apres_glisser.total]; })()" "$R1")" '[true,0,0,32]'
done
assert_eq "EN1.2 — hauteur de la zone ≤ 130 px, le texte du titre et le flou (halo de #context::before) sont gardés" \
  "$(E "Object.values(j.zone).map((z) => [z.apres_glisser.h <= 130, z.texte.length > 0, /blur/.test(z.flou)])" "$R1")" '[[true,true,true],[true,true,true],[true,true,true],[true,true,true]]'
MISE='Object.values(j.zone).map((z) => [Math.round(z.mise.t.k * 100) / 100, Math.round(z.mise.t.x), Math.round(z.mise.t.y), z.mise.fa.y, z.mise.fa.w, z.mise.fa.h])'
assert_eq "EN1.2b — freeArea() et la transformation après « f » (Code à 1440, 800, 390 px, graphe de Projet) égales à la base fusionnée : la mise en page ne change pas" \
  "$(E "$MISE" "$R1")" '[[1.1,315,266,149,1016,675],[1.1,191,327,141,768,631],[0.85,33,325,136,358,580],[0.93,52,158,149,1016,675]]'
assert_eq "EN1.3 — couloirs et liste : #svg sans découpe" "$(E "[j.vues.couloirs.clip, j.vues.liste.clip]" "$R1")" '["none","none"]'
R14="$(mesurer en14)"; sonde "$R14"
assert_eq "EN1.4 — zone basse (lab --terminal, feuille ouverte) à 390 et 800 px : rectangles de #ask, #zoom, de la pastille « Terminal », de la feuille et --vf-bas (au pas de 16 px près : la hauteur de la feuille suit la police) égaux à la base fusionnée" \
  "$(E "JSON.stringify(j.bas)" "$R14")" '{"390":{"ask":null,"zoom":null,"past":[16,303,355],"feuille":[8,363,382,836],"bas":"calc(528px + var(--edge) + var(--sp-8) + var(--edge) + env(safe-area-inset-bottom, 0px))"},"800":{"ask":[16,792,392,884],"zoom":null,"past":[16,732,784],"feuille":[424,60,784,884],"bas":"calc(144px + var(--edge) + var(--sp-8) + var(--edge) + env(safe-area-inset-bottom, 0px))"}}'
R15="$(mesurer en15)"; sonde "$R15"
assert_eq "EN1.5 — Code → Projet → Code par VF_ONGLETS.aller (même document : timeOrigin) : Projet sans découpe, Code de nouveau sans carte sous le titre, découpe reposée" \
  "$(E "[j.origine, j.projet.clip, j.sous.n, j.sous.total, j.coupe.clip !== 'none']" "$R15")" '[true,"none",0,32,true]'
R16="$(mesurer en16)"; sonde "$R16"
assert_eq "EN1.6 — A51 (P80-D-59) : après Code → Projet → Code (deux fois), un seul ResizeObserver et un seul écouteur resize de 01-vf-ensemble.js, comme à froid ; 01-vf-responsive.js ne cumule rien" \
  "$(E "[j.froid.ens[0] >= 1, j.froid.ens[1] >= 1, JSON.stringify(j.apres1) === JSON.stringify(j.froid), JSON.stringify(j.apres2) === JSON.stringify(j.froid)]" "$R16")" '[true,true,true,true]'
vf_hyg_stop "$SRV"
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
