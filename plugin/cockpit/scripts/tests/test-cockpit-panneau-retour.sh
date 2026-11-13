#!/usr/bin/env bash
# test-cockpit-panneau-retour.sh — pile Retour du panneau de Projet (80-08, FORM-08, P80-C76-3, P80-C76-5, P80-D-33), un vrai Chrome, sans réseau.
#   PR1 un lien du panneau empile, Retour ramène la sélection d'avant sans réempiler (pilote : chrome-panneau-retour.mjs, mode pr1)
#   PR2 entrées génériques, borne de 32, vidages, Échap (panneau latéral, feuille de détail), contraste, absence hors de Projet, zone basse
#   Mutants (copie du module dans $WORK, jamais le module) : M-REEMPILE, M-HTML, M-BORNE, M-GLOBALE, M-DEHORS, M-NULL,
#   M-COUPE, M-ENTREE, M-VIDE.  PR_SCRIPTS = dossier de scripts à bâtir.
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
  vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — le Retour du panneau NON vérifié, non compté comme réussi"; exit 0
fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0; SC_BASE="${PR_SCRIPTS:-$SCRIPTS}"
. "$HERE_T/couloirs-commun.sh"
mesurer() {
  REAL_HOME="$REAL_HOME" PR_LISTE="$ENG/assets/ui/41-vf-projet-liste.js" \
    node "$HERE_T/$1" "$CHROME" "http://127.0.0.1:$PORT" "${2:-}" "${3:-}" 2>"$WORK/mesure.err"
}
sonde() { [ -n "${SONDE:-}" ] && { printf '%s\n' "$1"; cat "$WORK/mesure.err"; }; return 0; }
# le lab de couloirs, avec des dépendances entre phases (« Dépend de » : liens du panneau de la phase 2 vers la 1 et la 3)
mklabdep() {
  mklab "$1"
  printf '\n## Phase Details\n\n### Phase 1: Socle\n**Goal**: socle\n' >> "$1/.planning/ROADMAP.md"
  printf '\n### Phase 2: Écran\n**Goal**: écran\n**Depends on**: Phase 1\n' >> "$1/.planning/ROADMAP.md"
  printf '\n### Phase 3: Liens\n**Goal**: liens\n**Depends on**: Phase 2\n' >> "$1/.planning/ROADMAP.md"
  git -C "$1" add -A && git -C "$1" -c user.email=t@t -c user.name=t commit -q -m dependances
}
LAB="$WORK/lab"; mklabdep "$LAB"
build_serve "$LAB"
assert_eq "PR0 — serveur du lab démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"

echo "=== PR1 — un lien du panneau empile, Retour ramène la phase d'avant ==="
R1="$(mesurer chrome-panneau-retour.mjs pr1)"; sonde "$R1"; E1() { E "$1" "$R1"; }
assert_eq "PR1.1 — clic sur la carte de la phase 2 : bouton .vf-retour présent (un seul), aria-disabled=\"true\", nommé « Retour, indisponible »" \
  "$(E1 '[j.pr11.btn.n, j.pr11.btn.dis, j.pr11.btn.nom, j.pr11.taille]')" '[1,"true","Retour, indisponible",0]'
assert_eq "PR1.2 — clic sur le lien « Phase 1 » du panneau : panneau de la phase 1, bouton actif « Retour : Phase 2 · Écran », description liée" \
  "$(E1 '[j.pr12.sel, j.pr12.taille, j.pr12.btn.dis, j.pr12.btn.texte, j.pr12.btn.nom, j.pr12.btn.desc]')" \
  '["n:ph-1",1,"false","Retour : Phase 2 · Écran","Retour : Phase 2 · Écran","Revenir à la sélection précédente"]'
assert_eq "PR1.3 — clic sur Retour : panneau de la phase 2, pile à 0, bouton désactivé, ni le conteneur ni la forme ne changent" \
  "$(E1 '[j.pr13.sel, j.pr13.taille, j.pr13.btn.dis, [j.pr13.cont, j.pr13.forme].join() === j.pr13.avant.join()]')" '["n:ph-2",0,"true",true]'
assert_eq "PR1.9 — témoin : aucune section du pilote n'a échoué" "$(E1 'Object.keys(j.erreurs).join()')" ""

echo "=== PR2 — entrées génériques, borne, vidages, contraste, hors de Projet ==="
R2="$(mesurer chrome-panneau-retour.mjs pr2a)"; sonde "$R2"; E2() { E "$1" "$R2"; }
assert_eq "PR2.1 — empiler REQ-12 puis un lien du panneau : « Retour : REQ-12 » (rien d'autre empilé) ; Retour : rouvrir appelé une fois, pile vide" \
  "$(E2 '[j.pr21.avant.texte, j.pr21.ro, j.pr21.apres.taille]')" '["Retour : REQ-12","[\"REQ-12\"]",0]'
assert_eq "PR2.2 — une entrée dont rouvrir lève une erreur est retirée : C est appelée puis retirée, le bouton passe à B SANS la rouvrir" \
  "$(E2 '[j.pr22.avant.texte, j.pr22.ro, j.pr22.apres.btn.texte, j.pr22.apres.taille]')" '["Retour : C","[\"C\"]","Retour : B",2]'
assert_eq "PR2.3 — 40 empilements : 32 entrées, la plus ancienne (E0 à E7) a disparu, E39 en haut" \
  "$(E2 '[j.pr23.t, JSON.parse(j.pr23.ro).length, JSON.parse(j.pr23.ro)[0], JSON.parse(j.pr23.ro).at(-1), j.pr23.apres]')" '[32,32,"E39","E8",0]'
assert_eq "PR2.4 — T-80-17 : un titre « <img onerror> » reste du texte : 0 img dans #panel, aucun code exécuté, titre complet dans le nom accessible" \
  "$(E2 '[j.pr24.img, j.pr24.r, j.pr24.b.texte.startsWith("Retour : <img src=x"), j.pr24.b.nom]')" \
  '[0,"undefined",true,"Retour : <img src=x onerror=window.__r=1>"]'
assert_eq "PR2.5 — la pile se vide : clic sur une carte, remontée à la racine (Entrée puis Échap), fermeture du panneau (p), événement vf:onglet" \
  "$(E2 '[j.pr25.carte, j.pr25.racine, j.pr25.ferme, j.pr25.onglet]')" '[0,0,[2,0],0]'
for TH in dark light; do
  assert_eq "PR2.7 ($TH) — texte du bouton désactivé sur le fond RENDU (pixels de la capture) : contraste ≥ 4,5:1, 13 px / 500" \
    "$(E2 "[j.pr27.$TH.dis, j.pr27.$TH.ratio >= 4.5, j.pr27.$TH.poids, j.pr27.$TH.taille]")" '["true",true,"500","13px"]'
done
assert_eq "PR2.8 — equipe.html et index.html : aucun .vf-retour, window.VF_PANNEAU indéfini (la globale n'existe que sur Projet)" \
  "$(E2 '[j.pr28["equipe.html"], j.pr28["index.html"]]')" '[{"retour":0,"globale":"undefined"},{"retour":0,"globale":"undefined"}]'
if [ -f "$ENG/assets/ui/41-vf-projet-liste.js" ]; then
  assert_eq "PR2.9 — forme Liste (80-07) : un clic ou Entrée sur une rangée vide la pile, bouton désactivé, panneau ouvert sur la phase de la rangée" \
    "$(E2 '[j.pr29.avant >= 1, j.pr29.apres.taille, j.pr29.apres.btn.dis, j.pr29.apres.sel === j.pr29.id, j.pr29.entree.taille]')" '[true,0,"true",true,0]'
else
  echo "  ⏳ ATTENTE — PR2.9 (41-vf-projet-liste.js absent : couplage avec 80-07, exigé par 80-09)"
fi
assert_eq "PR2.11 — un lien du panneau (geste armé) puis, aussitôt, un clic sur une carte : la pile repart de zéro (écouteurs « dehors »)" \
  "$(E2 'j.pr211')" '0'
assert_eq "PR2.12 — un lien du panneau puis une désélection venue d'ailleurs (select(null)) : la pile est vidée, rien n'est empilé" \
  "$(E2 '[j.pr212[0], j.pr212[1]]')" '[1,0]'
assert_eq "PR2.14 — titre de 43 points de code : affiché 12 + « … » + 11, nom accessible complet" \
  "$(E2 '[j.pr214.texte, j.pr214.nom]')" '["Retour : 0123456789ab…cdefghijklm","Retour : 0123456789ab-milieu-qui-depasse-cdefghijklm"]'
assert_eq "PR2.9b — témoin : aucune section du pilote n'a échoué" "$(E2 'Object.keys(j.erreurs).join()')" ""
R3="$(mesurer chrome-panneau-retour.mjs pr2b)"; sonde "$R3"; E3() { E "$1" "$R3"; }
assert_eq "PR2.6a — 1440 px, pointeur fin, focus sur Retour : Échap ne ferme pas le panneau et ne dépile pas" \
  "$(E3 '[j.pr26a.avant, j.pr26a.apres.ouvert, j.pr26a.apres.taille]')" '[[true,2],true,2]'
for CLE in b c; do
  GAB="800 px pointeur fin"; [ $CLE = b ] && GAB="390 px tactile"
  assert_eq "PR2.6$CLE — feuille de détail ($GAB) : Échap ferme la feuille, la pile reste (après le délai de vidage)" \
    "$(E3 "[j.pr26$CLE.avant, j.pr26$CLE.apres.ouvert, j.pr26$CLE.apres.taille]")" '[[true,2],false,2]'
done
assert_eq "PR2.6d — témoin : aucune section du pilote n'a échoué" "$(E3 'Object.keys(j.erreurs).join()')" ""
R5="$(mesurer chrome-panneau-retour.mjs pr2d)"; sonde "$R5"; E5() { E "$1" "$R5"; }
AC='{"sel":"n:ph-2","cont":"root","taille":0,"foc":"vp-carte","meme":false}'; DE='{"sel":"n:ph-2","cont":"root","taille":0,"foc":"vf-retour","meme":true}'
for K in a:Entrée:Enter:actif b:Espace:Space:actif c:Entrée:Enter:désactivé d:Espace:Space:désactivé; do
  IFS=: read -r ID NOMT _ ETAT <<< "$K"; ATT="$AC"; [ "$ETAT" = désactivé ] && ATT="$DE"
  assert_eq "PR2.15$ID — $NOMT sur le bouton Retour $ETAT : retour() et rien d'autre (aucune plongée) ; focus : carte rouverte ou bouton" \
    "$(E5 "j.pr215$ID")" "$ATT"
done
assert_eq "PR2.16 — retour() sur pile vide : le bouton n'est pas reconstruit, le focus reste dessus, pile à 0" \
  "$(E5 'j.pr216')" '{"foc":"vf-retour","meme":true,"taille":0}'
assert_eq "PR2.16b — témoin : aucune section du pilote n'a échoué (clavier)" "$(E5 'Object.keys(j.erreurs).join()')" ""
vf_hyg_stop "$SRV"
LABT="$WORK/lab-term"; mklabdep "$LABT"; build_serve "$LABT" --terminal
R4="$(mesurer chrome-panneau-retour.mjs pr2c)"; sonde "$R4"; E4() { E "$1" "$R4"; }; vf_hyg_stop "$SRV"
for CLE in a b; do
  GAB="800 px"; HT=true; [ $CLE = a ] && { GAB="390 px tactile (appui ≥ 44 px)"; HT="j.pr210a.h >= 44"; }
  assert_eq "PR2.10$CLE — zone basse, feuille de détail à $GAB : le centre du bouton Retour lui appartient (ni #ask, ni la pastille, ni #vf-coin)" \
    "$(E4 "[j.pr210$CLE.couvert, j.pr210$CLE.dis, j.pr210$CLE.pastille, j.pr210$CLE.ask, $HT]")" '[false,"false",true,true,true]'
done
assert_eq "PR2.10c — témoin : aucune section du pilote n'a échoué" "$(E4 'Object.keys(j.erreurs).join()')" ""

echo "=== Mutants (copie du module dans \$WORK) ==="
UIF=42-vf-panneau-retour.js
mutant M-REEMPILE $UIF "const e = pile.pop(); enRetour = Date.now() + DELAI;" "const e = pile.pop(); enRetour = 0;" chrome-panneau-retour.mjs pr1 pr13
assert_eq "M-REEMPILE — le mutant rougit PR1.3 (Retour réempile : la pile n'est pas à 0) (témoin : la phase 2 est rouverte)" \
  "$(E "[j.pr13.taille !== 0, j.pr13.sel]" "$RM")" '[true,"n:ph-2"]'
mutant M-HTML $UIF "texte.textContent = haut ? t('Back: {}', coupe(haut.titre)) : t('Back');" "texte.innerHTML = haut ? t('Back: {}', haut.titre) : t('Back');" \
  chrome-panneau-retour.mjs pr2a pr24
assert_eq "M-HTML — le mutant rougit PR2.4 (titre par innerHTML : un img naît) (témoin : le bouton existe)" \
  "$(E "[j.pr24.img > 0, !!j.pr24.b]" "$RM")" '[true,true]'
mutant M-BORNE $UIF "BORNE = 32," "BORNE = 3200," chrome-panneau-retour.mjs pr2a pr23
assert_eq "M-BORNE — le mutant rougit PR2.3 (pile sans borne : 40 entrées) (témoin : 40 empilements faits)" \
  "$(E "[j.pr23.t, j.pr23.t !== 32]" "$RM")" '[40,true]'
mutant M-GLOBALE $UIF "if (!SC || !SC.graph.meta || SC.graph.meta.vfTab !== 'project') return;" \
  "window.VF_PANNEAU = {}; if (!SC || !SC.graph.meta || SC.graph.meta.vfTab !== 'project') return;" chrome-panneau-retour.mjs pr2a pr28
assert_eq "M-GLOBALE — le mutant rougit PR2.8 (VF_PANNEAU posé avant la garde d'onglet : défini sur Équipe) (témoin : aucun bouton posé)" \
  "$(E "[j.pr28['equipe.html'].globale === 'object', j.pr28['equipe.html'].retour]" "$RM")" '[true,0]'
mutant M-DEHORS $UIF "sur(document, 'pointerdown', dehors, true); sur(document, 'keydown', dehors, true);" "" chrome-panneau-retour.mjs pr2a pr211
assert_eq "M-DEHORS — le mutant rougit PR2.11 (plus d'écouteurs « dehors » : le geste reste armé, la carte empile) (témoin : 1 avant)" \
  "$(E "[j.pr211 !== 0, j.pr211]" "$RM")" '[true,2]'
mutant M-NULL $UIF "if (sel == null || typeof sel !== 'string' || maintenant >= geste) vider();" "if (maintenant >= geste) vider();" \
  chrome-panneau-retour.mjs pr2a pr212
assert_eq "M-NULL — le mutant rougit PR2.12 (clause « sélection absente ou non nœud » retirée : la désélection empile) (témoin : 1 avant)" \
  "$(E "[j.pr212[1] !== 0, j.pr212[0]]" "$RM")" '[true,1]'
mutant M-COUPE $UIF "a.length <= COUPE ? s :" "a.length <= 1e9 ? s :" chrome-panneau-retour.mjs pr2a pr214
assert_eq "M-COUPE — le mutant rougit PR2.14 (titre jamais coupé) (témoin : nom accessible complet)" \
  "$(E "[j.pr214.texte !== 'Retour : 0123456789ab…cdefghijklm', j.pr214.nom.length]" "$RM")" '[true,52]'
mutant M-ENTREE $UIF "b.addEventListener('keydown', (ev) => { if (ev.key === 'Enter' || ev.key === ' ') ev.stopPropagation(); });" "" \
  chrome-panneau-retour.mjs pr2d pr215c
assert_eq "M-ENTREE — le mutant rougit PR2.15c (l'Entrée du moteur plonge aussi) (témoin : la sélection existait)" \
  "$(E "[j.pr215c.cont !== 'root' || j.pr215c.sel !== 'n:ph-2', j.pr215c.sel]" "$RM")" '[true,null]'
mutant M-VIDE $UIF "if (!pile.length) return; // pile vide : rien ne bouge, le focus reste sur le bouton" "" chrome-panneau-retour.mjs pr2d pr216
assert_eq "M-VIDE — le mutant rougit PR2.16 (retour() sur pile vide reconstruit le bouton) (témoin : pile à 0)" \
  "$(E "[j.pr216.meme === false, j.pr216.taille]" "$RM")" '[true,0]'
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
