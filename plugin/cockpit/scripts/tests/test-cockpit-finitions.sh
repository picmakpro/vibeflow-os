#!/usr/bin/env bash
# test-cockpit-finitions.sh — finitions de la charte (80-17, FORM-14, P80-D-20 : AUDC-F1, F3, F4, F5), un vrai Chrome, sans réseau.
#   FI1 disclosures et sélecteurs à la charte : summary sans marqueur natif, chevron de 16 px tourné de 90° ouvert, zone ≥ 32 px (44 au toucher) ;
#       #vf-modele et #proposition-mode (page de Q) aux mêmes valeurs ; mouvement réduit ; 03-vf-charte.js servi, chargé, sans doublon
#   FI2 une taille de bouton d'en-tête (36 en panneau latéral, 44 en feuille de détail ou au toucher), l'ouvreur Git laissé à 44 × 44
#   FI3 chiffres tabulaires en police de texte, pastilles du menu « ⋯ » aux teintes du bureau, zone basse (non-régression)
#   FI4 plafonds de lignes et de colonnes, grille des jetons, inventaire
#   Régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) : pas de mutant.
#   FI_SCRIPTS = dossier de scripts à bâtir (rejeu sur la base).
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
  vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — les finitions de la charte NON vérifiées, non comptées comme réussies"; exit 0
fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0; SC_BASE="${FI_SCRIPTS:-$SCRIPTS}"
. "$HERE_T/couloirs-commun.sh"
UIDIR="$ENG/assets/ui"; CHARTE="$UIDIR/03-vf-charte.js"; QCSS="$UIDIR/terminal/q.css"; VENDORED="$ENG/VENDORED.txt"
mesurer() { REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-finitions.mjs" "$CHROME" "http://127.0.0.1:$PORT" "$1" "$SC_BASE" 2>"$WORK/mesure.err"; }
sonde() { [ -n "${SONDE:-}" ] && { printf '%s\n' "$1"; cat "$WORK/mesure.err"; }; return 0; }
LAB="$WORK/lab"; mklab "$LAB"
build_serve "$LAB" --terminal
assert_eq "FI0 — serveur du lab démarré (avec --terminal)" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"

echo "=== FI1 — disclosures et sélecteurs à la charte ==="
R1="$(mesurer fi1)"; sonde "$R1"; R1T="$(mesurer fi1t)"; sonde "$R1T"; RQ="$(mesurer fi1q)"; sonde "$RQ"
cockpit_get /_vf/ui/03-vf-charte.js > /dev/null; CODE15="${VF_CODE:-000}"; R15="$(mesurer fi15)"; sonde "$R15"
SUMOK='[x && x.ls, x && x.marq, x && x.chev, x && x.h >= 32, x && x.ferme]'
for nom in historique tech lancer; do
  assert_eq "FI1.1 ($nom) — summary sans marqueur natif (list-style none, marqueur masqué), chevron de 16 × 16 px, zone ≥ 32 px, chevron fermé à 0°" \
    "$(E "(() => { const x = j.$nom; return $SUMOK; })()" "$R1")" '["none","none",["\"\"","16px","16px"],true,0]'
done
assert_eq "FI1.1b — une fois ouvert, le chevron a tourné de 90° (Historique, Détails techniques, menu du lancement ; transition de 150 ms passée)" \
  "$(E '[j.historiqueOuvert, j.techOuvert, j.lancerOuvert]' "$R1")" '[90,90,90]'
assert_eq "FI1.1c — au toucher, la zone du summary est de 44 px au moins et le sélecteur de 36 px" \
  "$(E '[j.historique && j.historique.h >= 44, j.select && j.select.h]' "$R1T")" '[true,36]'
SELOK='[x.app, x.h, x.fond === x.raise, x.bord, x.rayon, x.schema === x.racine, x.image, x.url, x.off[0] === x.off[1], x.off[2]]'
assert_eq "FI1.2 — #vf-modele, thèmes clair et sombre : appearance none, 28 px, fond --raise, contour 1 px, rayon 8, color-scheme du thème, chevron en dégradé sans URL, désactivé en --text-4 sans opacité" \
  "$(E "[1, 2].map((i) => { const x = j.modele[i]; return $SELOK; })" "$R1")" \
  '[["none",28,true,"1px","8px",true,true,false,true,"1"],["none",28,true,"1px","8px",true,true,false,true,"1"]]'
assert_eq "FI1.3 — page de Q : #proposition-mode aux mêmes valeurs calculées que #vf-modele (appearance, hauteur, fond, contour, rayon), chevron en dégradé et aucune URL d'image" \
  "$(E "(() => { const k = (x) => JSON.stringify([x.app, x.h, x.fond, x.bord, x.bordCouleur, x.rayon]), q = j.q;
    return [k(q) === k(j.lab), q.image, q.url, q.off[0] === q.off[1], q.off[2]]; })()" "$RQ")" '[true,true,false,true,"1"]'
assert_eq "FI1.3b — q.css ne gagne aucune URL (le chevron est dessiné par dégradés ; la forme de la CSP de la page ne change pas)" \
  "$(grep -c 'url(' "$QCSS")" "0"
assert_eq "FI1.4 — mouvement réduit : rotation du chevron instantanée (90° dans le même tour), aucune animation active" \
  "$(E 'j.reduit' "$R1")" '[90,0]'
assert_eq "FI1.5 — 03-vf-charte.js servi sous /_vf/ui/ (200), chargé par la page, un seul élément style après deux allers-retours d'onglet, aucun nœud ajouté aux summary, un seul chevron par summary" \
  "$CODE15|$(E '[j.charge[0] >= 1, j.charge[1], j.apres1[1], j.apres2[1], j.apres1[2] === j.apres2[2], j.chevron.length > 0 && j.chevron.every((c) => c === "\"\"")]' "$R15")" \
  '200|[true,1,1,1,true,true]'

echo "=== FI2 — une taille de bouton d'en-tête, l'ouvreur Git laissé à 44 px ==="
R2="$(mesurer fi2)"; sonde "$R2"; R2T="$(mesurer fi2t)"; sonde "$R2T"
for w in 1440 1100; do
  assert_eq "FI2.1 — à $w px au pointeur fin : tous les boutons d'en-tête (hors ouvreur Git) ont 36 px de haut, le bouton de thème compris" \
    "$(E "(() => { const b = j.b$w.boutons; return [b.length >= 5, b.some((e) => e[0] === 'theme-toggle'), b.every((e) => e[1] === 36)]; })()" "$R2")" '[true,true,true]'
done
assert_eq "FI2.2 — à 900 px (souris) puis à 1100 px au toucher : les boutons d'en-tête ont 44 px d'appui" \
  "$(E "(() => { const b = j.b900.boutons; return [b.length >= 2, b.every((e) => e[1] >= 44)]; })()" "$R2")|$(E "(() => { const b = j.b1100.boutons;
    return [b.length >= 5, b.every((e) => e[1] === 44)]; })()" "$R2T")" '[true,true]|[true,true]'
assert_eq "FI2.3 — de 701 à 1279 px, l'ouvreur Git reste à 44 × 44 (P78-D-34 ; P80-D-56 est porté par 80-20)" \
  "$(E '[j.b800.ouvreur, j.b1100.ouvreur]' "$R2")" '[[44,44],[44,44]]'

echo "=== FI3 — chiffres tabulaires, pastilles du menu « ⋯ », zone basse ==="
R3="$(mesurer fi3)"; sonde "$R3"
assert_eq "FI3.1 — #vf-lock : police du texte, chiffres tabulaires, graisse 500 ; la branche Git reste en mono" \
  "$(E '[j.lock, j.mono]' "$R3")" '[[true,true,"500"],true]'
assert_eq "FI3.1b — Équipe (.aw-driver .n, .r-t, .r-meta b, .r-verr .n) : police du texte, chiffres tabulaires, graisse 500" \
  "$(E 'j.equipe.map((e) => e.slice(1))' "$R3")" '[[true,true,"500"],[true,true,"500"],[true,true,"500"],[true,true,"500"]]'
assert_eq "FI3.2 — thème clair à 800 px : pastille Santé du menu « ⋯ » à la teinte --hc-badge (texte --on-sev-text), Récent à --recent (texte --on-recent-text), contraste ≥ 4,5:1, point de « ⋯ » de la teinte la plus haute" \
  "$(E '(() => { const p = j.pastilles, a = p.attendu; return [p.sante && p.sante.fond === a.sante[0], p.sante && p.sante.texte === a.sante[1], p.sante && p.sante.ratio >= 4.5,
    p.recent && p.recent.fond === a.recent[0], p.recent && p.recent.texte === a.recent[1], p.recent && p.recent.ratio >= 4.5, p.point === a.sante[0], p.point !== a.on]; })()' "$R3")" \
  '[true,true,true,true,true,true,true,true]'
R34="$(mesurer fi34)"; sonde "$R34"
assert_eq "FI3.4 — zone basse à 390 et 800 px (couloirs et liste, feuille de détail ouverte puis fermée, pastille « Terminal ») : après Fin, l'élément focalisé n'intersecte ni #ask, ni la pastille, ni la feuille ; aucun défilement horizontal" \
  "$(E 'Object.entries(j.zone).map(([k, v]) => [k, ["base", "feuille", "ferme"].every((n) => v[n] && v[n].focus && v[n].inter.length === 0 && v[n].pastille && v[n].large !== false)])' "$R34")" \
  '[["390-couloirs",true],["390-liste",true],["800-couloirs",true],["800-liste",true]]'
vf_hyg_stop "$SRV"

echo "=== FI4 — plafonds, jetons, inventaire ==="
LIG() { awk 'END { print NR }' "$1"; }
LONG() { node -e 'const t=require("fs").readFileSync(process.argv[1],"utf8").split("\n");console.log(t.filter((l)=>[...l.replace(/\r$/,"")].length>160).length)' "$1"; }
PIL="$HERE_T/chrome-finitions.mjs"; SUI="$HERE_T/test-cockpit-finitions.sh"
assert_eq "FI4.1 — fichiers créés ou modifiés ≤ 299 lignes ; aucune ligne de plus de 160 colonnes dans les fichiers neufs" \
  "$([ -f "$CHARTE" ] && [ "$(LIG "$CHARTE")" -le 299 ] && [ "$(LIG "$UIDIR/02-vf-telephone.js")" -le 299 ] && [ "$(LIG "$PIL")" -le 299 ] && echo ok || echo ko)|$([ -f "$CHARTE" ] && LONG "$CHARTE" || echo absent)|$(LONG "$PIL")" "ok|0|0"
assert_eq "FI4.2 — css-jetons.mjs : aucun littéral de couleur, espacements sur la grille, rayons permis dans 03-vf-charte.js" \
  "$([ -f "$CHARTE" ] && node "$HERE_T/css-jetons.mjs" "$CHARTE" >/dev/null 2>&1 && echo ok || echo ko)" "ok"
assert_eq "FI4.3 — VENDORED.txt déclare 03-vf-charte.js une fois, à sa place alphabétique (entre 02-vf-telephone.js et 03-vf-accessibilite.js : 03-vf-a < 03-vf-c)" \
  "$(grep -cx 'AJOUT assets/ui/03-vf-charte.js' "$VENDORED")|$(grep -n '^AJOUT assets/ui/0[23]-' "$VENDORED" | sed 's/^[0-9]*://' | tr '\n' ' ' | sed 's/AJOUT assets\/ui\///g')" \
  "1|02-vf-coin.js 02-vf-ligne-etat.js 02-vf-reperes.js 02-vf-telephone.js 03-vf-accessibilite.js 03-vf-charte.js "
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
