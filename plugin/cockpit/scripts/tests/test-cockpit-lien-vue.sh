#!/usr/bin/env bash
# test-cockpit-lien-vue.sh — un lien qui rend la vue (80-13, FORM-15, P80-D-21, P80-D-39), un vrai Chrome, sans réseau.
#   LV1 le fragment porte la vue, la sélection et le zoom ; rejouer le lien rend la même vue ; ?vue= survit (pilote : chrome-lien-vue.mjs, modes lv1 à lv3)
#   LV2 le tiroir Git est dans le lien, les tiroirs (Git, « Au travail ») sont gardés par sessionStorage et d'un onglet à l'autre, sans prendre le focus
#   LV3 liens forgés bornés, Précédent et #r= comme avant
#   Mutants M-ZHORS, M-EFFACE, M-FOCUS-TIROIR : levés (régime allégé de la Phase 80, ce plan n'est pas une garde).
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
  vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — le lien de vue NON vérifié, non compté comme réussi"; exit 0
fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0; SC_BASE="$SCRIPTS"
. "$HERE_T/couloirs-commun.sh"
mesurer() { REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-lien-vue.mjs" "$CHROME" "http://127.0.0.1:$PORT" "$1" "${2:-}" 2>"$WORK/mesure.err"; }
sonde() { [ -n "${SONDE:-}" ] && { printf '%s\n' "$1"; cat "$WORK/mesure.err"; }; return 0; }
mklabcode() { # le lab de couloirs, avec quelques fichiers de code (l'onglet Code a des cartes) et un dépôt git
  mklab "$1"
  wr "$1/src/app/main.js" <<< 'export const a = 1;'; wr "$1/src/lib/util.js" <<< 'export const b = 2;'; wr "$1/README.md" <<< '# lab'
  git -C "$1" add -A && git -C "$1" -c user.email=t@t -c user.name=t commit -q -m code
}
LAB="$WORK/lab"; mklabcode "$LAB"
build_serve "$LAB"
assert_eq "LV0 — serveur du lab démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"

echo "=== LV1 — la vue, la sélection et le zoom dans l'adresse ==="
R1="$(mesurer lv1)"; sonde "$R1"; E1() { E "$1" "$R1"; }
assert_eq "LV1.1 — le fragment porte v, s et z ; rouvrir ce lien : même conteneur, même sélection, transformation à 1e-3 près" \
  "$(E1 '[/(^#|&)v=/.test(j.lv11.av.h), /(^#|&)s=/.test(j.lv11.av.h), j.lv11.z, j.lv11.ap.c === j.lv11.av.c, j.lv11.ap.s === j.lv11.av.s,
    Math.abs(j.lv11.ap.t.k - j.lv11.av.t.k) <= 1e-3, Math.abs(j.lv11.ap.t.x - j.lv11.av.t.x) <= 1e-3, Math.abs(j.lv11.ap.t.y - j.lv11.av.t.y) <= 1e-3]')" \
  '[true,true,true,true,true,true,true,true]'
assert_eq "LV1.2 — après une nouvelle sélection, le même z est toujours dans le fragment et s a changé" \
  "$(E1 '[(j.lv12.av.match(/(?:^#|&)z=([^&]+)/) || [])[1] === (j.lv12.ap.h.match(/(?:^#|&)z=([^&]+)/) || [])[1], !!j.lv12.ap.h.match(/(?:^#|&)z=/),
    j.lv12.ap.s === j.lv12.autre]')" '[true,true,true]'
assert_eq "LV1.3 — ?vue=couloirs d'une adresse de Projet survit à la réécriture du fragment (sélection écrite)" \
  "$(E1 '[j.lv13.q, /(^#|&)s=/.test(j.lv13.h), j.lv13.s]')" '["?vue=couloirs",true,"n:ph-2"]'

echo "=== LV2 — les tiroirs : dans le lien, gardés d'un onglet à l'autre, sans focus ==="
R2="$(mesurer lv2)"; sonde "$R2"; E2() { E "$1" "$R2"; }
assert_eq "LV2.1 — Git ouvert : git=1 dans le fragment ; fermé : plus de git ; un lien git=1 ouvre le tiroir au chargement, focus hors du tiroir" \
  "$(E2 '[/(^#|&)git=1/.test(j.lv21.ouvert.h), j.lv21.ouvert.g.ouvert, /git=/.test(j.lv21.ferme.h), j.lv21.ferme.g.ouvert, j.lv21.lien.ouvert, j.lv21.lien.focus]')" \
  '[true,true,false,false,true,false]'
assert_eq "LV2.2 — Git ouvert sur Code, rechargement complet sur Projet : ouvert ; « Au travail » sous 1 280 px de même ; clé de session au nom du lab" \
  "$(E2 '[j.lv22.onglet, j.lv22.git.ouvert, j.lv22.cles.length, j.lv22.cles[0] === j.lv22.cle, j.lv22.travail.ouvert, j.lv22.travail.focus, j.lv22.cleT]')" \
  '["project",true,1,true,true,false,true]'
assert_eq "LV2.3 — lien sans git + mémoire ouverte : ouvert ; lien git=1 + mémoire fermée : ouvert (le lien prime) ; rien : fermé ; sans focus" \
  "$(E2 '[j.lv23.memo, j.lv23.lien, j.lv23.aucun, j.lv23.focus, j.lv23.k.indexOf("vf-tiroirs:") === 0]')" '[true,true,false,false,true]'
assert_eq "LV2.4 — Git ouvert, aller(projet) sans rechargement : ouvert, hors focus ; retour ; deux allers-retours : un seul tiroir ; fermé : plus de surcouche" \
  "$(E2 '[j.lv24.origine, j.lv24.p.r, j.lv24.p.g.ouvert, j.lv24.p.g.focus, j.lv24.c.g.ouvert, j.lv24.f.ouvert, j.lv24.f.n, j.lv24.fin.ouvert, j.lv24.fin.pile]')" \
  '[true,"ok",true,false,true,true,1,false,false]'
assert_eq "LV2.4b — « Au travail » sous 1 280 px : gardé par aller(projet) sans rechargement, hors focus, un seul tiroir au retour" \
  "$(E2 '[j.lv24.travail.o, j.lv24.travail.r, j.lv24.travail.t.ouvert, j.lv24.travail.t.focus, j.lv24.travail.retour.ouvert, j.lv24.travail.un]')" \
  '[true,"ok",true,false,true,1]'

echo "=== LV3 — liens forgés, Précédent, #r= ==="
R3="$(mesurer lv3)"; sonde "$R3"; E3() { E "$1" "$R3"; }
assert_eq "LV3.1 — liens forgés (v inconnu, z hors bornes, non fini, mal formé, git hostile) : racine, cadrage, tiroir fermé, rien inséré dans le DOM" \
  "$(E3 'j.lv31.map((x) => x.ok)')" '[true,true,true,true,true,true,true]'
assert_eq "LV3.1b — témoin positif : #z=1.5,10.5,20.25 (valide) s'applique à la transformation" \
  "$(E3 '[j.lv31t.k, j.lv31t.x, j.lv31t.y]')" '[1.5,10.5,20.25]'
assert_eq "LV3.2 — Précédent après une sélection rend la sélection d'avant ; #r= révèle toujours sa cible" \
  "$(E3 '[j.lv32.ok, j.lv32.apres === j.lv32.a, j.lv32r.existe, j.lv32r.sel]')" '[true,true,true,"f:src/app/main.js"]'

echo "=== Sans erreur de pilote ==="
ERR=""; for r in "$R1" "$R2" "$R3"; do ERR="$ERR$(E 'Object.keys(j.erreurs).join()' "$r")"; done
assert_eq "LV9 — aucune section du pilote n'a échoué" "$ERR" ""
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
