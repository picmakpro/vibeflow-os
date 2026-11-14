#!/usr/bin/env bash
# test-cockpit-onglets.sh — changer d'onglet sans recharger la page (80-10, FORM-16, P80-D-22, P80-D-42, P80-D-59), un vrai Chrome, sans réseau.
#   OG1 de Code à Projet sans rechargement, Précédent revient, focus, titre et annonce suivent (pilote : chrome-onglets-routage.mjs, modes og1, og2, og3, og2t)
#   OG2 vue et tiroir gardés, repli du focus, VF_ONGLETS.aller (promesse), script persistant, fragment d'adresse
#   OG3 chargement rejeté sans effet visible (adresse, onglet affiché, focus inchangés, promesse rejetée)
#   Mutants : levés (régime allégé de la Phase 80, ce plan n'est pas une garde).  OG_SCRIPTS = dossier de scripts à bâtir (rejeu sur la base).
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
  vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — le routage des onglets NON vérifié, non compté comme réussi"; exit 0
fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0; SC_BASE="${OG_SCRIPTS:-$SCRIPTS}"
. "$HERE_T/couloirs-commun.sh"
FICHIER="$SC_BASE/../skills/cockpit-moteur/assets/ui/00-vf-onglets.js"
mesurer() { REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-onglets-routage.mjs" "$CHROME" "http://127.0.0.1:$PORT" "$1" "$FICHIER" "${2:-}" 2>"$WORK/mesure.err"; }
sonde() { [ -n "${SONDE:-}" ] && { printf '%s\n' "$1"; cat "$WORK/mesure.err"; }; return 0; }
mklabcode() { # le lab de couloirs, avec quelques fichiers de code (l'onglet Code a des cartes) et un dépôt git
  mklab "$1"
  wr "$1/src/app/main.js" <<< 'export const a = 1;'; wr "$1/src/lib/util.js" <<< 'export const b = 2;'; wr "$1/README.md" <<< '# lab'
  git -C "$1" add -A && git -C "$1" -c user.email=t@t -c user.name=t commit -q -m code
}
LAB="$WORK/lab"; mklabcode "$LAB"
build_serve "$LAB"
assert_eq "OG0 — serveur du lab démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"

echo "=== OG1 — de Code à Projet sans rechargement ==="
R1="$(mesurer og1)"; sonde "$R1"; E1() { E "$1" "$R1"; }
assert_eq "OG1.1 — clic sur Projet : /project.html, même page (timeOrigin), aucun load, vf:onglet projet" \
  "$(E1 '[j.og1.e1.p, j.og1.e1.origine, j.og1.e1.loads, j.og1.e1.last]')" '["/project.html",true,0,"projet<code"]'
assert_eq "OG1.2 — history.back() : retour sur Code sans rechargement, vf:onglet code" \
  "$(E1 '[j.og1.e2.p, j.og1.e2.origine, j.og1.e2.loads, j.og1.e2.last]')" '["/",true,0,"code<projet"]'
assert_eq "OG1.3 — focus sur le h1 de Projet puis sur la carte itinérante ou #stage, jamais body ; la zone status dit le nom" \
  "$(E1 "[j.og1.e1.ae, j.og1.e1.live, ['carte','stage'].includes(j.og1.e2.ae), j.og1.e2.live]")" '["vf-projet-titre","Projet",true,"Code"]'
assert_eq "OG1.4 — document.title « Projet · <nom> » puis « Code · <nom> », même nom" \
  "$(E1 '[/^Projet · .+/.test(j.og1.e1.t), /^Code · .+/.test(j.og1.e2.t), j.og1.e1.t.split(" · ")[1] === j.og1.e2.t.split(" · ")[1]]')" '[true,true,true]'
assert_eq "OG2.8 — deux changements d'onglet de plus : un seul écouteur popstate posé par 00-vf-onglets.js, aucun load" \
  "$(E1 '[j.og28.pop, j.og1.e3.origine, j.og1.e4.origine, j.og28.nb]')" '[1,true,true,4]'

echo "=== OG2 — vue, repli du focus, aller, script persistant, fragment ==="
R2="$(mesurer og2)"; sonde "$R2"; E2() { E "$1" "$R2"; }
assert_eq "OG2.1 — tiroir Git ouvert gardé, sélection et transformation de Code rendues au retour (écart ≤ 1e-6), VF_ONGLETS de même identité" \
  "$(E2 '[j.og21.av[0], j.og21.ap[0], j.og21.ap[1] === j.og21.av[1] && j.og21.av[1] === j.og21.id,
    Math.abs(j.og21.ap[2].k - j.og21.av[2].k) <= 1e-6, j.og21.ident]')" \
  '["true","true",true,true,true]'
assert_eq "OG2.3 — Code : un seul arrêt de tabulation sur le canevas, #vf-coin ; Projet : couloirs rendus ; la pile Retour est vide" \
  "$(E2 '[j.og23.tabs, j.og23.coin, j.og23p.cartes > 0, j.og23p.taille]')" '[1,true,true,0]'
assert_eq "OG2.4 — Projet en couloirs, phase 2 sélectionnée : retour par history.back() et par clic, le focus est sur la carte de ph-2" \
  "$(E2 '[j.og24.code, j.og24.retour, j.og24.clic[0], j.og24.clic[1], j.og24.clic[2]]')" \
  '["/",["/project.html","n:ph-2",{"id":"n:ph-2","cur":"true"}],"/project.html","n:ph-2",{"id":"n:ph-2","cur":"true"}]'
assert_eq "OG2.4b — forme Liste : retour par history.back(), le focus est sur la rangée de ph-2" \
  "$(E2 '[j.og24l.p, j.og24l.sel, j.og24l.ae.id]')" '["/project.html","n:ph-2","n:ph-2"]'
assert_eq "OG2.5 — aller('projet') : résolue après le premier rendu (pas au tour suivant), vue de Projet et phase 2 restituées, action de l'appelant gardée" \
  "$(E2 '[j.og25.tot, j.og25.p, j.og25.pret, j.og25.evs.pop(), /^Projet · /.test(j.og25.t), j.og25.vue, j.og25.sel0, j.og25.sel1]')" \
  '[false,"/project.html","oui","projet<code",true,true,"n:ph-2","n:ph-3"]'
assert_eq "OG2.6 — aller('code') sur Code : résolue aussitôt, ni historique, ni vf:onglet, ni lecture" \
  "$(E2 '[j.og26.r, j.og26.apres.n === j.og26.avant.n, j.og26.apres.evs === j.og26.avant.evs,
    j.og26.apres.fetchs === j.og26.avant.fetchs]')" '[true,true,true,true]'
assert_eq "OG2.7 — noms refusés (equipe2, vide, __proto__, constructor, undefined, 7) : tous rejetés, rien ne change, aucun unhandledrejection" \
  "$(E2 '[j.og27.rs.join(), j.og27.apres.n === j.og27.avant.n, j.og27.apres.p === j.og27.avant.p,
    j.og27.apres.fetchs === j.og27.avant.fetchs, j.og27.apres.rej]')" \
  '["rejet,rejet,rejet,rejet,rejet,rejet",true,true,true,0]'
assert_eq "OG2.9 — évaluation isolée deux fois : une inscription popstate, une inscription surOnglet de clé 00-vf-onglets.js, aucune lecture du moteur" \
  "$(E2 '[j.og29.pop, j.og29.sur, j.og29.charger, j.og29.lectures, j.og29.un, j.og29.marqueur]')" '[1,["00-vf-onglets.js"],0,[],true,true]'
assert_eq "OG2.10 — le fragment courant n'est pas reporté ; au retour sur Projet, son fragment mémorisé" \
  "$(E2 '[j.og210.code, j.og210.projet]')" '[["/","","root",null],["/project.html","#v=liste&s=ph-2"]]'
assert_eq "OG2.11 — aller('equipe', { fragment }) : #vf-x à la résolution, un seul pushState ; fragments invalides rejetés sans effet" \
  "$(E2 '[j.og211.r.h, j.og211.r.p, j.og211.r.n - j.og211.e0.n, j.og211.r.push - j.og211.e0.push, j.og211.bad.join(),
    j.og211.apres.n === j.og211.r.n, j.og211.apres.fetchs - j.og211.e0.fetchs]')" \
  '["#vf-x","/equipe.html",1,1,"rejet,rejet,rejet,rejet,rejet",true,1]'
assert_eq "OG2.13 — modale ouverte puis aller('projet') : résolue, Projet chargé, focus posé, aucune erreur (hors 41-clavier), modale défaite" \
  "$(E2 '[j.og213.r[0], j.og213.p, /^Projet · /.test(j.og213.t), j.og213.ae !== "body",
    j.og213.cerr.filter((x) => !/querySelectorAll/.test(x)).join(), j.og213.modale]')" '["ok","/project.html",true,true,"",false]'
assert_eq "OG2.12 — history.back() : l'adresse de l'entrée (chemin et fragment) à l'identique, aucun replaceState du routeur" \
  "$(E2 '[j.og212.p, j.og212.h, j.og212.repl]')" '["/","#s=zz",0]'

R5="$(mesurer og214)"; sonde "$R5"
assert_eq "OG2.14 — z posé sur Code : le premier rendu de Projet ne l'applique pas, adresse d'arrivée sans fragment" \
  "$(E '[j.og214.p, j.og214.h, j.og214.tk.k === 1.5 && j.og214.tk.x === 10.5 && j.og214.tk.y === 20.25]' "$R5")" '["/project.html","",false]'
assert_eq "OG2.14b — chargement rejeté : le fragment (z) de l'adresse et l'historique reviennent à l'identique" \
  "$(E '[j.og214r.r, j.og214r.apres.h === j.og214r.avant.h, j.og214r.apres.n === j.og214r.avant.n, j.og214r.apres.p]' "$R5")" '["rejet",true,true,"/"]'
R6="$(mesurer og215)"; sonde "$R6"
assert_eq "OG2.15 — aller('projet') puis aller('equipe') coup sur coup : precedent juste, le z de Projet ne passe pas sur Équipe" \
  "$(E '[j.og215.evs, j.og215.p, j.og215.tk.k === 0.5 && j.og215.tk.x === 100, j.og215.dn]' "$R6")" '[["projet<code","equipe<projet"],"/equipe.html",false,2]'
assert_eq "OG2.16 — aller('code') puis aller('projet') : la dernière demande, vers l'onglet encore affiché, l'emporte, adresse et onglet concordent" \
  "$(E '[j.og216.evs, j.og216.p, j.og216.onglet]' "$R6")" '[["code<projet","projet<code"],"/project.html","projet"]'
assert_eq "OG2.17 — Précédent pendant un chargement en vol : la dernière demande l'emporte, adresse et onglet concordent" \
  "$(E '[j.og217.p, j.og217.onglet]' "$R6")" '["/project.html","projet"]'
R7="$(mesurer og218)"; sonde "$R7"
assert_eq "OG2.18 — palette ouverte (/ ou Ctrl+K) puis fermée par Échap, puis aller : promesse réglée, page réactive (quatre départs)" \
  "$(E 'j.og218.map((x) => [x.ouverte, x.r, x.vivante].join()).join(" ")' "$R7")" "true,regle,2 true,regle,2 true,regle,2 true,regle,2"
R8="$(mesurer og218d)"; sonde "$R8"
assert_eq "OG2.18d — « / », « > », Échap, puis aller aussitôt : promesse réglée, page réactive pendant l'attente, Projet chargé" \
  "$(E '[j.og218d.r, j.og218d.vivante, j.og218d.p]' "$R8")" '["regle",2,"/project.html"]'
echo "=== OG3 — chargement rejeté sans effet visible ==="
R3="$(mesurer og3)"; sonde "$R3"; E3() { E "$1" "$R3"; }
assert_eq "OG3.1 — lecture en échec, clic sur Projet : adresse, historique, titre, sélection, focus inchangés, aucun vf:onglet, aucun rejet non capté" \
  "$(E3 '[j.og31.e1.p === j.og31.e0.p, j.og31.e1.n === j.og31.e0.n, j.og31.e1.t === j.og31.e0.t, j.og31.e1.sel === j.og31.e0.sel,
    j.og31.e1.pret, j.og31.e1.ae === j.og31.e0.ae, j.og31.e1.evs === j.og31.e0.evs, j.og31.e1.rej]')" \
  '[true,true,true,true,"oui",true,true,0]'
assert_eq "OG3.2 — lecture rétablie, second clic : Projet se charge normalement, une entrée d'historique de plus" \
  "$(E3 '[j.og32.p, j.og32.dn, /^Projet · /.test(j.og32.t), j.og32.last]')" '["/project.html",1,true,"projet<code"]'
assert_eq "OG3.3 — aucune requête directe de 00-vf-onglets.js (les lectures passent par la coquille)" "$(E3 'j.og33')" "0"
assert_eq "OG3.4 — aller('projet') avec la lecture en échec : promesse rejetée au message fixe, jamais résolue, adresse inchangée" \
  "$(E3 '[j.og34.r[0], /^Lecture impossible/.test(j.og34.r[1] || ""), j.og34.apres.p === j.og34.avant.p,
    j.og34.apres.n === j.og34.avant.n, j.og34.apres.rej]')" \
  '["rejet",true,true,true,0]'
assert_eq "OG3.5 — popstate rejeté : adresse ramenée à celle de l'onglet affiché, ni vf:onglet ni focus déplacé ; Suivant ne mène plus à Projet" \
  "$(E3 '[j.og35.e1.p, j.og35.e1.evs === j.og35.e0.evs, j.og35.e1.ae === j.og35.e0.ae, j.og35.e2.p]')" '["/",true,true,"/"]'

echo "=== OG2.2 — terminal gardé (lab --terminal) ==="
LABT="$WORK/labt"; mklabcode "$LABT"; build_serve "$LABT" --terminal
assert_eq "OG2.2.0 — serveur du lab du terminal démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"
R4="$(mesurer og2t)"; sonde "$R4"
assert_eq "OG2.2 — le cadre du terminal est le même nœud, jamais rechargé, après un aller-retour d'onglet (tampon gardé)" \
  "$(E 'j.og22' "$R4")" '{"meme":true,"connecte":true,"charges":0}'
echo "=== Sans erreur de pilote ==="
ERR=""; for r in "$R1" "$R2" "$R3" "$R4" "$R5" "$R6" "$R7" "$R8"; do ERR="$ERR$(E 'Object.keys(j.erreurs).join()' "$r")"; done
assert_eq "OG9 — aucune section du pilote n'a échoué" "$ERR" ""
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
