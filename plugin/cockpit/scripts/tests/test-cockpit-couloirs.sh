#!/usr/bin/env bash
# test-cockpit-couloirs.sh — Projet en couloirs (80-04, FORM-05, FORM-07, P80-D-01..D-04, D-07, D-28..D-30, D-37, D-50, D-51), un vrai Chrome, sans réseau.
#   CL1 couloirs par défaut, graphe à ?vue=graphe, section de panneau, adresse de naviguer
#   CL2 en-tête de jalon, ligne d'état, troncature, listes, XSS, contrastes, mouvement réduit
#   CL3 clavier, panneau par-dessus, zone basse, visite, direct, focus orphelin, bords latéraux (pilote : chrome-couloirs-clavier.mjs)
#   Mutants (copie du module dans $WORK, jamais le module) : M-FOOT, M-XSS, M-POUSSE, M-ORPHELIN, M-EXTREMITE, M-POINTEUR (CL4).
#   CL_SCRIPTS = dossier de scripts à bâtir (rejeu sur la base).
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
  vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — les couloirs de Projet NON vérifiés, non comptés comme réussis"; exit 0
fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0; SC_BASE="${CL_SCRIPTS:-$SCRIPTS}"
. "$HERE_T/couloirs-commun.sh"
mesurer() { REAL_HOME="$REAL_HOME" node "$HERE_T/$1" "$CHROME" "http://127.0.0.1:$PORT" "${2:-}" "${3:-}" "${4:-}" 2>"$WORK/mesure.err"; }
sonde() { [ -n "${SONDE:-}" ] && { printf '%s\n' "$1"; cat "$WORK/mesure.err"; }; return 0; }
LAB="$WORK/lab"; mklab "$LAB"
build_serve "$LAB"
assert_eq "CL0 — serveur du lab démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"

echo "=== CL1 — couloirs par défaut, graphe à la demande ==="
R1="$(mesurer chrome-couloirs.mjs cl1)"; sonde "$R1"; E1() { E "$1" "$R1"; }
assert_eq "CL1.1 — project.html (adresse brute) : 4 couloirs dans le bloc du jalon en cours, canevas caché (visibility hidden)" \
  "$(E1 '[j.cl11.groupes, j.cl11.svg, j.cl11.jalons >= 1]')" '[4,"hidden",true]'
assert_eq "CL1.2 — ?vue=graphe : canevas visible (cartes rendues), section.vf-projet masquée" \
  "$(E1 '[j.cl12.svg, j.cl12.cartes > 0, j.cl12.vue]')" '["visible",true,true]'
assert_eq "CL1.3 — P80-C76-1 : après un clic sur la carte de la phase 3, la section du pilote est dans #panel, cible n:ph-3" \
  "$(E1 '[j.cl13.dans, j.cl13.cible]')" '[true,"n:ph-3"]'
assert_eq "CL1.4 — naviguer sans option ajoute vue=graphe avant le fragment ; une adresse qui a vue= reste telle quelle" \
  "$(E1 '[j.cl14, j.cl14b]')" '[["?vue=graphe","#s=x"],["?vue=couloirs","#s=x"]]'
assert_eq "CL1.5 — 390 px : aucun descendant du canevas caché ne reste visible (00-vibeflow.js force visibility: visible sur certains pieds de carte)" \
  "$(E1 'j.cl15.visibles')" "0"
assert_eq "CL1.6 — bascule dans les deux sens : le focus va au segment équivalent du groupe visible, l'annonce vit hors de la section masquée" \
  "$(E1 '[j.cl16.vers.id, j.cl16.vers.flottant, j.cl16.vers.texte, j.cl16.vers.dansSection, j.cl16.retour.id, j.cl16.retour.flottant, j.cl16.retour.texte]')" \
  '["graphe",true,"Affichage en graphe",false,"couloirs",false,"Affichage en couloirs, 6 phases"]'
assert_eq "CL1.9 — témoin : aucune section du pilote n'a échoué" "$(E1 'Object.keys(j.erreurs).join()')" ""

echo "=== CL2 — en-tête de jalon, couloirs, ligne d'état, troncature, listes, sécurité du rendu ==="
R2="$(mesurer chrome-couloirs.mjs cl2)"; sonde "$R2"; E2() { E "$1" "$R2"; }
Z1='j.cl21.synth, j.cl21.now, j.cl21.larg, j.cl21.pc.replace(/\s/g, " "), j.cl21.pcMasque, j.cl21.fond === j.cl21.avertissement, j.cl21.libelle, j.cl21.texte'
assert_eq "CL2.1 — jalon en cours : « 2 phases faites sur 6, 1 à recetter », 33 %, remplissage 33 % en --warn-text, pourcentage masqué, barre nommée" \
  "$(E2 "[$Z1]")" '["2 phases faites sur 6, 1 à recetter","33","33%","33 %","true",true,"Avancement du jalon","2 phases faites sur 6"]'
assert_eq "CL2.1b — jalon à 0 % puis à 100 % : remplissage neutre (--text-3), 100 % seulement si tout est fait" \
  "$(E2 '[j.cl21z.now, j.cl21z.synth, j.cl21z.fond === j.cl21z.neutre, j.cl21c.now, j.cl21c.synth, j.cl21c.fond === j.cl21c.neutre]')" \
  '["0","0 phase faite sur 6, 1 à recetter",true,"100","6 phases faites sur 6",true]'
assert_eq "CL2.2 — quatre couloirs dans l'ordre fixe, compte affiché = cartes, glyphe et mot à chaque en-tête, nom « À faire, 2 phases »" \
  "$(E2 '[j.cl22.map((c) => c.mot).join(), j.cl22.map((c) => c.n).join(), j.cl22.map((c) => c.cartes).join(), j.cl22.every((c) => c.glyphe), j.cl22[0].nom]')" \
  '["À faire,En cours,À recetter,Fait","2,1,1,2","2,1,1,2",true,"À faire, 2 phases"]'
assert_eq "CL2.2b — un couloir vide garde son en-tête (compte 0), dit « aucune phase » et ne contient aucun contrôle focalisable" \
  "$(E2 '[j.cl22v.texte, j.cl22v.boutons, j.cl22v.nom]')" '["aucune phase",0,"En cours, 0 phase"]'
assert_eq "CL2.3 — lignes d'état : « 2 plans sur 2 · 1 exigence sur 2 », « pas de plan · non cadrée » ; le nom de carte commence par le numéro et le titre" \
  "$(E2 '[j.cl23[0], j.cl23[1], j.cl23[2]]')" \
  '["2 plans sur 2 · 1 exigence sur 2","pas de plan · non cadrée","5 <img src=x onerror=window.__x=1>, pas de plan · non cadrée, phase, À faire"]'
assert_eq "CL2.3b — donnée absente n'est pas zéro : sans avancement ni exigences, ligne vide (hauteur réservée, masquée), couloir tiré de st" \
  "$(E2 '[j.cl23b.texte, j.cl23b.couloir, j.cl23b.h > 10, j.cl23b.masque]')" '["","a-faire",true,"true"]'
CUT='(t) => { const a = Array.from(t); return a.slice(0, 31).join("") + "…" + a.slice(-20).join(""); }'
T24="j.cl24.a52.plein, j.cl24.a52.lignes <= 3, j.cl24.a52.larg >= 222 && j.cl24.a52.larg <= 230, j.cl24.a52.decrit, j.cl24.a52.titre === j.cl24.A52"
L24="Array.from(j.cl24.M53).length === 53 && Array.from(j.cl24.L70).length === 70, j.cl24.m53.titre === cut(j.cl24.M53), j.cl24.m53.decrit === j.cl24.M53"
N24="j.cl24.l70.titre === cut(j.cl24.L70), j.cl24.l70.decrit === j.cl24.L70, j.cl24.m53.nom.startsWith('6 ' + cut(j.cl24.M53) + ','),
  j.cl24.l70.nom.startsWith('3 ' + cut(j.cl24.L70) + ',')"
assert_eq "CL2.4 — titre de 52 caractères entier en ≤ 3 lignes à ≈ 226 px ; 53 et 70 : 31 + « … » + 20, texte complet décrit, nom accessible" \
  "$(E2 "((cut) => [$T24, $L24, $N24])($CUT)")" '[true,true,true,null,true,true,true,true,true,true,true,true]'
assert_eq "CL2.5 — Historique, Backlog, Graines, Releases : details repliés et comptés, aucune carte de canevas, jamais « DIFFÉRÉ » ; clic = sélection" \
  "$(E2 '[j.cl25.liste, j.cl25.cartesFile, j.cl25.differe, j.cl25c[0].startsWith("f:.planning/BACKLOG.md#"), j.cl25c[1]]')" \
  '[[["historique",false,"1 jalon · 1 phase"],["backlog",false,"2 entrées"],["graines",false,"2 graines"],["releases",false,"0 tag"]],0,false,true,true]'
assert_eq "CL2.6 — T-80-07 : un titre de phase « <img onerror> » du ROADMAP : 0 img, aucun code exécuté, texte rendu tel quel" \
  "$(E2 '[j.cl26.img, j.cl26.flag, j.cl26.texte]')" '[0,"undefined,undefined,undefined,undefined",true]'
UIS="$SC_BASE/../skills/cockpit-moteur/assets/ui"
JETONS="$(node "$HERE_T/css-jetons.mjs" "$UIS"/41-vf-projet-*.js 2>&1; echo "rc=$?")"
assert_eq "CL2.7a — css-jetons.mjs sur tous les 41-vf-projet-*.js présents : aucune valeur fautive (au moins trois fichiers)" \
  "$(ls "$UIS"/41-vf-projet-*.js 2>/dev/null | awk 'END { print (NR >= 4) }')|${JETONS##*$'\n'}" "1|rc=0"
for TH in sombre clair; do
  C="j.cl27.$TH"
  assert_eq "CL2.7b ($TH) — contrastes rendus : texte de carte ≥ 4,5:1, glyphes ≥ 3:1, bordure de sélection de 1,5 px ≥ 3:1, segment actif cerné" \
    "$(E2 "[Math.min(...$C.textes) >= 4.5, $C.glyphes.length === 4 && Math.min(...$C.glyphes) >= 3, $C.bordure >= 3, $C.largeur,
      $C.segment !== 'rgba(0, 0, 0, 0)']")" '[true,true,true,"1.5px",true]'
done
assert_eq "CL2.8 — mouvement réduit : aucune animation active après chargement, après la bascule vers le graphe et au retour" \
  "$(E2 '[j.cl28.charge, j.cl28.graphe, j.cl28.retour]')" '[0,0,0]'
assert_eq "CL2.9 — témoin : aucune section du pilote n'a échoué" "$(E2 'Object.keys(j.erreurs).join()')" ""

echo "=== CL3 — clavier, sélection et plongée, toucher (panneau latéral, feuille de détail) ==="
R3="$(mesurer chrome-couloirs-clavier.mjs cl3a)"; sonde "$R3"; E3() { E "$1" "$R3"; }
assert_eq "CL3.1 — 1024 px : un arrêt de tabulation par bloc ; → parcourt les quatre couloirs, ← revient, Fin, Origine, ↑/↓ restent dans le couloir" \
  "$(E3 '[j.cl31.arret1, j.cl31.arret2, j.cl31.suite.map((x) => x[1]).join()]')" \
  '[["n:ph-3",1],["summary",null],"n:ph-4,n:ph-6,n:ph-1,n:ph-6,n:ph-2,n:ph-3,n:ph-5,n:ph-5,n:ph-3"]'
assert_eq "CL3.2 — 800 px (2 × 2) : ↓ d'À faire va à À recetter, ↓ d'En cours à Fait, ↑ symétrique ; couloir vide sauté ; En cours vide : → ne bouge pas" \
  "$(E3 '[j.cl32.suite.map((x) => x[1]).join(), j.cl32.corps]')" '["n:ph-5,n:ph-6,n:ph-5,n:ph-1,n:ph-4,n:ph-1,n:ph-3",true]'
assert_eq "CL3.3a — panneau latéral : Tab et flèche sélectionnent (aria-current) ; Échap désélectionne, le focus reste ; Espace resélectionne" \
  "$(E3 '[j.cl33.suit, j.cl33.esc, j.cl33.esp]')" '[["n:ph-4",["n:ph-4"]],[null,"n:ph-4"],["n:ph-4",["n:ph-4"]]]'
assert_eq "CL3.3b — Entrée plonge ; Échap (ou Retour arrière) revient à la racine, focus sur la carte quittée ; Échap du panneau : ni désélection ni remontée" \
  "$(E3 '[j.cl33.dedans, j.cl33.retours.length >= 1 && j.cl33.retours.length <= 2, j.cl33.retours[j.cl33.retours.length - 1],
    j.cl33.dos, j.cl33.bs, j.cl33.panneau, j.cl33.foc[0]]')" \
  '["n:ph-4",true,"root",["root","n:ph-4"],["root","n:ph-4"],["n:ph-4","root"],"button"]'
assert_eq "CL3.4 — 390 px tactile : un toucher sélectionne (feuille ouverte, bouton d'ouvrir dedans) sans plonger ; Espace sélectionne ; Entrée plonge" \
  "$(E3 '[j.cl34.touch[0], j.cl34.touch[1], j.cl34.touch[2], j.cl34.touch[3] >= 1, j.cl34.focus, j.cl34.espace, j.cl34.entree]')" \
  '["n:ph-3",true,"root",true,"n:ph-3","n:ph-4","n:ph-4"]'
assert_eq "CL3.9a — témoin : aucune section du pilote n'a échoué (clavier)" "$(E3 'Object.keys(j.erreurs).join()')" ""

echo "=== CL3 — panneau par-dessus, visite, direct, réveil, mouvement réduit, focus orphelin, bords latéraux ==="
R4="$(mesurer chrome-couloirs-clavier.mjs cl3b)"; sonde "$R4"; E4() { E "$1" "$R4"; }
assert_eq "CL3.5 — 1440 px : couloirs identiques panneau ouvert et fermé ; une carte sous le panneau est ramenée hors de lui, sans animation" \
  "$(E4 '[j.cl35.panneaux, j.cl35.ouvert.join() === j.cl35.ferme.join(), j.cl35.m.hors, j.cl35.m.defile > 0, j.cl35.m.mode,
    j.cl35.actives]')" '[[true,false],true,true,true,"auto",0]'
V37="[j.cl37.clicOuvre.f, j.cl37.clicOuvre.actif, j.cl37.clicOuvre.svg, j.cl37.clicFin.f, j.cl37.clicFin.actif, j.cl37.auto.f,
  j.cl37.auto.actif, j.cl37.fin, j.cl37.url]"
assert_eq "CL3.7 — la visite bascule en graphe avant de jouer (clic ou démarrage sans clic) ; à sa fin la forme d'avant revient ; adresse non réécrite" \
  "$(E4 "$V37")" '["graphe",true,"visible","couloirs",false,"graphe",true,"couloirs","?vue=couloirs"]'
assert_eq "CL3.8 — direct : une phase focalisée change de couloir au redessin ; focus, arrêt, sélection, défilement, details restent ; une annonce" \
  "$(E4 '[j.cl38.id, j.cl38.cur, j.cl38.av[0] > 0, j.cl38.apres[0] === j.cl38.av[0], j.cl38.apres[1] === j.cl38.av[1], j.cl38.apres.slice(2)]')" \
  '["n:ph-3",["n:ph-3"],true,true,true,[true,"a-recetter","0","Phase 3 : À recetter"]]'
assert_eq "CL3.9 — P80-C76-3 : reveal d'une phase en couloirs sélectionne sa carte à la racine ; P80-C76-2 : la section overview suit le corps" \
  "$(E4 '[j.cl39.c, j.cl39.sel, j.cl39.cur, j.cl39.ov]')" '["root","n:ph-2",["n:ph-2"],{"dernier":true,"avant":true}]'
assert_eq "CL3.10 — mouvement réduit : aucune animation active (hors panneau) après sélection, plongée et remontée" \
  "$(E4 '[j.cl310.charge, j.cl310.selection, j.cl310.plongee, j.cl310.remontee]')" '[0,0,0,0]'
O3="j.cl311"
assert_eq "CL3.11a — focus orphelin : la carte retirée rend le focus à la suivante du bloc (ordre de lecture), sinon à la précédente ; jamais body" \
  "$(E4 "[$O3.a.id, $O3.a.ti, $O3.b.id, $O3.b.ti]")" '["n:ph-6","0","n:ph-1","0"]'
assert_eq "CL3.11b — rangée de Backlog retirée : la suivante ; la dernière : l'élément sélectionné rendu, sinon le h1 « Projet » ; toutes les phases : le h1" \
  "$(E4 "[$O3.c.suivante.id, $O3.c.suivante.ti, $O3.c.derniere.hid, $O3.cSel.id, $O3.d.hid]")" \
  '["f:.planning/BACKLOG.md#autre-entrée","0","vf-projet-titre","n:ph-3","vf-projet-titre"]'
assert_eq "CL3.11c — le focus d'un champ n'est jamais volé par un redessin" "$(E4 "$O3.champ.hid")" "ask-input"
for CLE in 1440 1024; do
  X="j.cl312$CLE"
  assert_eq "CL3.12 ($CLE) — panneau latéral : extrémité de fin, carte hors du panneau ; tiroir Git : extrémité de début, carte ramenée hors de lui" \
    "$(E4 "[parseFloat($X.panneau.fin) >= $X.panneau.pw, $X.panneau.pw >= 360, $X.panneau.carte[1] <= $X.panneau.panneau[0] + 0.5,
      parseFloat($X.tiroir.debut) >= $X.tiroir.tiroir[1] - $X.tiroir.tiroir[0] + 16, $X.tiroir.carte[0] >= $X.tiroir.tiroir[1] - 0.5]")" \
    '[true,true,true,true,true]'
done
for CLE in 800 390 1100t; do
  X="j.cl312$CLE"
  assert_eq "CL3.12 ($CLE) — feuille de détail : ni extrémité ni scroll-padding-inline ; aucun défilement horizontal (panneau et tiroir Git ouverts ou non)" \
    "$(E4 "[$X.repos, $X.panneau, $X.tiroir, $X.ferme].every((m) => ['auto', '0px'].includes(m.debut) && ['auto', '0px'].includes(m.fin) && m.larg)")" "true"
done
assert_eq "CL3.13 — 800 px, graphe, panneau ouvert : la bascule flottante ne chevauche pas le panneau" \
  "$(E4 '[j.cl313.ouvert, j.cl313.fl[1] <= j.cl313.panneau[0]]')" '[true,true]'
assert_eq "CL3.9b — témoin : aucune section du pilote n'a échoué (panneau, visite, direct, orphelin, bords)" "$(E4 'Object.keys(j.erreurs).join()')" ""
vf_hyg_stop "$SRV"

echo "=== CL3.6 — zone basse (lab lancé avec --terminal : pastille « Terminal », tiroir du terminal) ==="
DBL=1; [ -f "$SC_BASE/../skills/cockpit-moteur/assets/ui/02-vf-coin.js" ] && DBL=0
[ "$DBL" = 1 ] && echo "  #vf-coin : doublure (assets/ui/02-vf-coin.js absent de l'arbre : la fusion de la vague 2 le pose)"
LABT="$WORK/lab-term"; mklab "$LABT"; build_serve "$LABT" --terminal
R5="$(mesurer chrome-couloirs-clavier.mjs cl3c "" "$DBL")"; sonde "$R5"; E5() { E "$1" "$R5"; }; vf_hyg_stop "$SRV"
for CLE in 1440 1024 390 800 1100t; do
  X="j.cl36['$CLE']"
  assert_eq "CL3.6 ($CLE) — padding-bottom = scroll-padding-block-end ≥ #ask + #vf-coin + pastille (+ feuille) ; aucun recouvrement (Git, terminal)" \
    "$(E5 "[Object.values($X).every((m) => m && m.pb === m.spb && m.pb >= m.somme && m.inter.length === 0), $X.base.haut,
      $X.base.vus.includes('pastille'), $X.terminal.vus.includes('tiroirTerm')]")" '[true,true,true,true]'
done
assert_eq "CL3.6b — témoins : la feuille de détail est mesurée à 390 px ; #ask et la pastille sont mesurés à 1440 px ; aucune section du pilote n'a échoué" \
  "$(E5 "[j.cl36['390'].feuille.vus.includes('feuille'), j.cl36['1440'].base.vus.includes('ask'), Object.keys(j.erreurs).join()]")" '[true,true,""]'

echo "=== CL4 — témoins de pointeur (le poste voit ce que la CI Linux voit : Chrome sans tête = aucun pointeur) ==="
# décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée ; prise par la session principale le 2026-11-12
printf '#!/bin/bash\nexec "%s" --blink-settings=primaryPointerType=1,availablePointerTypes=1,primaryHoverType=1,availableHoverTypes=1 "$@"\n' "$CHROME" > "$AUX/chrome-sans-pointeur"; chmod +x "$AUX/chrome-sans-pointeur"
build_serve "$LAB"
RPN="$(node "$HERE_T/chrome-pointeur.mjs" "$AUX/chrome-sans-pointeur" "http://127.0.0.1:$PORT" none 2>/dev/null)"
RPC="$(node "$HERE_T/chrome-pointeur.mjs" "$CHROME" "http://127.0.0.1:$PORT" coarse 2>/dev/null)"
RPE="$(node "$HERE_T/chrome-pointeur.mjs" "$CHROME" "http://127.0.0.1:$PORT" etranger 2>/dev/null)"
RPD="$(node "$HERE_T/chrome-pointeur.mjs" "$CHROME" "http://127.0.0.1:$PORT" div 2>/dev/null)"
RPF="$(node "$HERE_T/chrome-pointeur.mjs" "$CHROME" "http://127.0.0.1:$PORT" nonfixe 2>/dev/null)"
RKN="$(node "$HERE_T/chrome-pointeur-forme.mjs" "$AUX/chrome-sans-pointeur" "http://127.0.0.1:$PORT" none clavier 2>/dev/null)"
RKC="$(node "$HERE_T/chrome-pointeur-forme.mjs" "$CHROME" "http://127.0.0.1:$PORT" coarse clavier 2>/dev/null)"; vf_hyg_stop "$SRV"
assert_eq "CL4.1 — sans aucun pointeur (Chrome de la CI Linux) : ni fine ni coarse, et le panneau latéral s'applique (scroll-padding de fin posé, pas auto)" \
  "$(E '[j.pointeur.fine, j.pointeur.coarse, j.spie !== "auto" && j.spie !== ""]' "$RPN")" '[false,false,true]'
assert_eq "CL4.2 — pointeur grossier (toucher émulé) : coarse vrai, la feuille de détail s'applique, aucun scroll-padding de fin (auto)" \
  "$(E '[j.pointeur.coarse, j.spie]' "$RPC")" '[true,"auto"]'
# CL4.3 fige en POSITIF une limite connue : à la jointure, quand le terminal posera son attribut neutre (contrat Phase 79), il devra être INVERSÉ
# (un bouton fixe étranger laissera la zone basse inchangée) ; CL4.3b/c (négatifs voisins) resteront valables tels quels.
# limite connue, dite : la pastille « Terminal » est lue par sa nature (bouton fixe sous body), pas par un attribut neutre posé par le terminal
# (contrat porté à la jointure avec la Phase 79). Un bouton fixe étranger EST donc pris pour elle : #ask + #vf-coin + pastille croissent.
assert_eq "CL4.3 — limite connue : un bouton fixe étranger sous body est pris pour la pastille (la zone basse de la vue grandit : $(E 'j.avant + " -> " + j.apres' "$RPE"))" \
  "$(E '[j.avant !== j.apres]' "$RPE")" '[true]'
assert_eq "CL4.3b — négatif : un DIV fixe étranger sous body (pas un bouton) n'est pas pris pour la pastille : la zone basse reste inchangée ($(E 'j.avant + " -> " + j.apres' "$RPD"))" \
  "$(E '[j.avant !== "", j.avant === j.apres]' "$RPD")" '[true,true]'
assert_eq "CL4.3c — négatif : un BOUTON étranger non fixe sous body n'est pas pris pour la pastille : la zone basse reste inchangée ($(E 'j.avant + " -> " + j.apres' "$RPF"))" \
  "$(E '[j.avant !== "", j.avant === j.apres]' "$RPF")" '[true,true]'
CHROME_REEL="$CHROME"; CHROME="$AUX/chrome-sans-pointeur"
mutant M-POINTEUR 41-vf-projet-vue.js "@media (min-width: 1000px) and (not (pointer: coarse)) {" "@media (min-width: 1000px) and (pointer: fine) {" chrome-pointeur.mjs none ""
CHROME="$CHROME_REEL"
assert_eq "M-POINTEUR — le mutant (ancienne requête (pointer: fine)) rougit CL4.1 : sans pointeur le panneau latéral ne s'applique plus (témoin : le Chrome est bien sans pointeur)" \
  "$(E '[j.pointeur.fine, j.pointeur.coarse, j.spie === "auto" || j.spie === ""]' "$RM")" '[false,false,true]'
CL44='[j.pointeur.fine, j.pointeur.coarse, j.focus.n > 0, j.focus.actif, j.focus.sel === j.focus.id]'
assert_eq "CL4.4 — 41-vf-projet-clavier.js, sans aucun pointeur (Chrome de la CI Linux) : ni fine ni coarse ; le focus d'une carte la sélectionne (panneau latéral, la sélection suit le focus)" \
  "$(E "$CL44" "$RKN")" '[false,false,true,true,true]'
assert_eq "CL4.5 — 41-vf-projet-clavier.js, pointeur grossier (toucher émulé) : coarse vrai ; le focus d'une carte ne la sélectionne pas (feuille de détail)" \
  "$(E '[j.pointeur.coarse, j.focus.n > 0, j.focus.actif, j.focus.sel]' "$RKC")" '[true,true,true,null]'
CHROME_REEL="$CHROME"; CHROME="$AUX/chrome-sans-pointeur"
mutant M-POINTEUR-CLAVIER 41-vf-projet-clavier.js "(min-width: 1000px) and (not (pointer: coarse))" "(min-width: 1000px) and (pointer: fine)" chrome-pointeur-forme.mjs none clavier
CHROME="$CHROME_REEL"
echo "     trace M-POINTEUR-CLAVIER — sonde CL4.4 [fine, coarse, cartes, focus posé, sélection = carte] : attendu [false,false,true,true,true], obtenu $(E "$CL44" "$RM")"
assert_eq "M-POINTEUR-CLAVIER — le mutant (ancienne requête (pointer: fine)) rougit CL4.4 : sans pointeur la sélection ne suit plus le focus de la carte (témoin : Chrome sans pointeur, carte focalisée)" \
  "$(E '[j.pointeur.fine, j.pointeur.coarse, j.focus.n > 0, j.focus.actif, j.focus.sel === j.focus.id]' "$RM")" '[false,false,true,true,false]'
CHROME="$CHROME_REEL"
mutant M-PASTILLE-DIV 41-vf-projet-vue.js "find((e) => e.matches('button') && getComputedStyle(e).position === 'fixed')" "filter((e) => getComputedStyle(e).position === 'fixed').pop()" chrome-pointeur.mjs div ""
echo "     trace M-PASTILLE-DIV — sonde CL4.3b [avant, après] : attendu égaux, obtenu $(E 'j.avant + " -> " + j.apres' "$RM")"
assert_eq "M-PASTILLE-DIV — le mutant (reconnaissance élargie : le dernier élément fixe, bouton ou non) rougit CL4.3b : le div fixe fait grandir la zone basse (témoin : mesure avant lue)" \
  "$(E '[j.avant !== "", j.avant === j.apres]' "$RM")" '[true,false]'
mutant M-PASTILLE-NONFIXE 41-vf-projet-vue.js "find((e) => e.matches('button') && getComputedStyle(e).position === 'fixed')" "find((e) => e.matches('button'))" chrome-pointeur.mjs nonfixe ""
echo "     trace M-PASTILLE-NONFIXE — sonde CL4.3c [avant, après] : attendu égaux, obtenu $(E 'j.avant + " -> " + j.apres' "$RM")"
assert_eq "M-PASTILLE-NONFIXE — le mutant (reconnaissance élargie : tout bouton) rougit CL4.3c : le bouton non fixe fait grandir la zone basse (témoin : mesure avant lue)" \
  "$(E '[j.avant !== "", j.avant === j.apres]' "$RM")" '[true,false]'

echo "=== Mutants (copie du module dans \$WORK) ==="
mutant M-FOOT 41-vf-projet-modele.js "const av = n && n.avancement, ex = n && n.exigences, seg = [];" \
  "if (n && n.foot !== undefined) return n.foot; const av = n && n.avancement, ex = n && n.exigences, seg = [];" chrome-couloirs.mjs cl2 cl23
assert_eq "M-FOOT — le mutant rougit CL2.3 (ligne d'état lue dans foot) (témoin : le nom de carte garde son numéro)" \
  "$(E "[j.cl23[0] !== '2 plans sur 2 · 1 exigence sur 2', j.cl23[2].startsWith('5 ')]" "$RM")" "[true,true]"
mutant M-XSS 41-vf-projet-rendu.js '<span class="vp-titre">${h(c.titre)}</span>' '<span class="vp-titre">${c.titre}</span>' chrome-couloirs.mjs cl2 cl26
assert_eq "M-XSS — le mutant rougit CL2.6 (titre inséré sans h() : un img naît) (témoin : la section existe)" \
  "$(E "[j.cl26.img > 0, j.cl26.texte === false]" "$RM")" "[true,true]"

mutant M-POUSSE 41-vf-projet-vue.js "inset: 0; z-index: 1;" "inset: 0 var(--pw, 0px) 0 0; z-index: 1;" chrome-couloirs-clavier.mjs cl3b cl35
assert_eq "M-POUSSE — le mutant rougit CL3.5 (rail rétréci panneau ouvert : les couloirs bougent) (témoin : la carte reste atteignable)" \
  "$(E "[j.cl35.ouvert.join() !== j.cl35.ferme.join(), j.cl35.panneaux[0]]" "$RM")" "[true,true]"
mutant M-ORPHELIN 41-vf-projet-vue.js "cible = suite || avant || null;" "cible = null;" chrome-couloirs-clavier.mjs cl3b cl311,cl38
assert_eq "M-ORPHELIN — le mutant rougit CL3.11 (voisin suivant puis précédent retiré : le focus va à l'arrêt) (témoin : repli et CL3.8 verts)" \
  "$(E "[j.cl311.a.id !== 'n:ph-6', j.cl311.a.tag, j.cl38.id === 'n:ph-3', j.cl311.d.hid]" "$RM")" '[true,"button",true,"vf-projet-titre"]'
mutant M-EXTREMITE 41-vf-projet-vue.js "left: 100%; width: var(--pw, 0px);" "left: 100%; width: 0px;" chrome-couloirs-clavier.mjs cl3b cl312
assert_eq "M-EXTREMITE — le mutant rougit CL3.12 (extrémité de fin retirée : la carte reste sous le panneau) (témoin : scroll-padding gardé)" \
  "$(E "[j.cl3121440.panneau.carte[1] > j.cl3121440.panneau.panneau[0] + 0.5,
    parseFloat(j.cl3121440.panneau.fin) >= j.cl3121440.panneau.pw]" "$RM")" "[true,true]"
mutant M-XSS-ID 41-vf-projet-rendu.js 'data-id="${h(r.id)}" tabindex="-1"${decrit(r)}' 'data-id="${r.id}" tabindex="-1"${decrit(r)}' \
  chrome-couloirs.mjs cl2 cl26
assert_eq "M-XSS-ID — le mutant rougit CL2.6 (identifiant de rangée sans h() : un nom de graine injecte un img)" "$(E "[j.cl26.img > 0]" "$RM")" "[true]"
mutant M-XSS-HIST 41-vf-projet-rendu.js '<span class="vp-r-t">${h(r.titre)}</span>' '<span class="vp-r-t">${r.titre}</span>' chrome-couloirs.mjs cl2 cl26
assert_eq "M-XSS-HIST — le mutant rougit CL2.6 (nom de jalon clos ou de backlog sans h() : un img naît)" "$(E "[j.cl26.img > 0]" "$RM")" "[true]"
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
