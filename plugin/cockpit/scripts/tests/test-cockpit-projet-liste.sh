#!/usr/bin/env bash
# test-cockpit-projet-liste.sh — Projet en liste (80-07, FORM-09, P80-D-04, D-05, D-12, D-25, D-39, D-50, D-51, P80-C76-6), un vrai Chrome, sans réseau.
#   PL1 la bascule « Liste » : tables par jalon, tri par état, rangée = sélection
#   PL2 intérieur d'une phase (plans par vague, exigences par la porte unique), troncature, Entrée et Espace, porte substituée
#   PL3 touche v, mémoire par lab et par largeur, tri, rôles et cibles à 390 px, mouvement réduit, focus orphelin, zone basse
#   Mutants (copie complète du module par `cockpit_module_copie`, servie par `COCKPIT_MODULE` ; jamais le module, jamais un lien) :
#   M-CLE, M-TRI, M-SAISIE, M-ORPHELIN-TRI, M-PORTE. PL_SCRIPTS = dossier de scripts à bâtir (rejeu sur la base).
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
  vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — la liste de Projet NON vérifiée, non comptée comme réussie"; exit 0
fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0; SC_BASE="${PL_SCRIPTS:-$SCRIPTS}"
. "$HERE_T/couloirs-commun.sh"
mesurer() { REAL_HOME="$REAL_HOME" node "$HERE_T/$1" "$CHROME" "http://127.0.0.1:$PORT" "${2:-}" "${3:-}" 2>"$WORK/mesure.err"; }
sonde() { [ -n "${SONDE:-}" ] && { printf '%s\n' "$1"; cat "$WORK/mesure.err"; }; return 0; }
T52="Titre de cinquante-deux caractères pour la rangée..."; T53="${T52}."; T70="Titre de soixante-dix caractères, très long, pour tester la coupe....."
mklabl() { # mklab + titres de 52, 53 et 70 caractères ; phase 1 : trois plans (vagues 1, 2, aucune), exigences R-1 cochée et R-2 hostile non cochée
  local L="$1" B="$1/.planning"; mklab "$L"
  sed -i.bak -e "s/Phase 4: Reprise/Phase 4: $T52/" -e "s/Phase 6: Recette/Phase 6: $T53/" -e "s/Phase 3: Liens/Phase 3: $T70/" "$B/ROADMAP.md"; rm -f "$B/ROADMAP.md.bak"
  printf -- '- [x] **R-1**: premier texte\n- [ ] **R-2**: <img src=x onerror=window.__x=1>\n\n| R-1 | Phase 1 | Complete |\n| R-2 | Phase 1 | Pending |\n' | wr "$B/REQUIREMENTS.md"
  printf -- '---\nwave: 1\nrequirements: [R-1, R-2]\n---\n<objective>Plan un</objective>\n' | wr "$B/phases/01-socle/01-01-PLAN.md"
  printf -- '---\nwave: 2\nrequirements: [R-1]\n---\n<objective><img src=x onerror=window.__t=1></objective>\n' | wr "$B/phases/01-socle/01-02-PLAN.md"
  printf -- '<objective>%s</objective>\n' "$T70" | wr "$B/phases/01-socle/01-03-PLAN.md"; echo ok > "$B/phases/01-socle/01-03-SUMMARY.md"
  git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m liste
}
mklabs() { local L="$1"; mklab "$L"; rm -f "$L/.planning/REQUIREMENTS.md"; git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m sans; }
LAB="$WORK/lab"; mklabl "$LAB"
build_serve "$LAB"
assert_eq "PL0 — serveur du lab démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"

echo "=== PL1 — la forme Liste à la racine ==="
R1="$(mesurer chrome-projet-liste.mjs pl1)"; sonde "$R1"; E1() { E "$1" "$R1"; }
assert_eq "PL1.1 — ?vue=liste : un table par bloc, rangées En cours, À recetter, À faire, Fait puis numéro ; aria-sort ascendant sur État seul" \
  "$(E1 '[j.pl11.tables >= 1, j.pl11.lignes, j.pl11.tri]')" '[true,["n:ph-4","n:ph-6","n:ph-3","n:ph-5","n:ph-1","n:ph-2"],[["etat","ascending"]]]'
assert_eq "PL1.2 — la bascule a trois boutons aria-pressed, un seul à true (Liste)" \
  "$(E1 'j.pl12')" '[["Couloirs","false"],["Liste","true"],["Graphe","false"]]'
assert_eq "PL1.3 — clic sur la rangée de la phase 2 : sélection et aria-current sur la rangée" "$(E1 '[j.pl13.sel, j.pl13.cur]')" '["n:ph-2",["n:ph-2"]]'
assert_eq "PL1.4 — T-80-15 : un titre de phase hostile du ROADMAP est rendu en texte à la racine (0 img, rien d'exécuté)" \
  "$(E1 '[j.pl14.img, j.pl14.flag, j.pl14.titre]')" '[0,"undefined","<img src=x onerror=window.__x=1>"]'
assert_eq "PL1.9 — témoin : aucune section du pilote n'a échoué" "$(E1 'Object.keys(j.erreurs).join()')" ""

echo "=== PL2 — intérieur d'une phase en liste ==="
R2="$(mesurer chrome-projet-liste.mjs pl2)"; sonde "$R2"; E2() { E "$1" "$R2"; }
assert_eq "PL2.1 — phase 1 : h1 « Phase 1 », vagues 1, 2, Sans vague ; statut de chaque plan ; « 2 exigences couvertes », « 1 exigence couverte », aucun segment" \
  "$(E2 '[j.pl21.h1.startsWith("Phase 1"), j.pl21.h3, j.pl21.plans.map((p) => [p[0], p[2]])]')" \
  '[true,["Vague 1","Vague 2","Sans vague"],[["01-01","2 exigences couvertes"],["01-02","1 exigence couverte"],["01-03",""]]]'
assert_eq "PL2.2 — exigences : ul sans input, Cochée / Non cochée, texte une fois, rendu en texte (0 img, rien d'exécuté)" \
  "$(E2 '[j.pl22.li.length, j.pl22.li[0].includes("Cochée") && !j.pl22.li[0].includes("Non"), j.pl22.li[1].includes("Non cochée"), j.pl22.input, j.pl22.img, j.pl22.flag, j.pl22.fois, j.pl22.h2]')" \
  '[2,true,true,0,0,"undefined",1,["Plans","Exigences"]]'
assert_eq "PL2.10 — une seule source : les plans « Fait » de la vue de la phase sont ceux que dit la ligne d'état et la rangée de la racine (témoin rouge : plan sans SUMMARY sous une phase cochée)" \
  "$(E2 '[j.pl210.fait, Number(j.pl210.ligne.match(/^(\d+) plan/)[1]), Number(j.pl210r.match(/^(\d+)/)[1])]')" '[3,3,3]'
assert_eq "PL2.2b — T-80-15 : un titre de plan hostile est rendu en texte dans la phase (0 img, rien d'exécuté)" \
  "$(E2 '[j.pl22.img, j.pl22.t, j.pl22.titres.includes("<img src=x onerror=window.__t=1>")]')" '[0,"undefined",true]'
assert_eq "PL2.3 — un seul arrêt de tabulation pour les plans ; ↓ d'une vague à l'autre, ↑, Fin, Origine ; la sélection suit" \
  "$(E2 '[j.pl23.n, j.pl23.t0, j.pl23.suite.map((x) => x[1]), j.pl23.sel]')" '[3,1,[1,2,2,1,2,0],true]'
assert_eq "PL2.4 — à l'entrée le focus est sur le h1 ; Échap remonte à la racine, focus sur la rangée de la phase 1" \
  "$(E2 '[j.pl24a, j.pl24.retours.length >= 1 && j.pl24.retours.length <= 2, j.pl24.fin.c, j.pl24.fin.id]')" '["vf-projet-titre",true,"root","n:ph-1"]'
assert_eq "PL2.5 — dans une phase : deux segments (Liste, Graphe) ; Graphe rend le canevas" \
  "$(E2 '[j.pl25, j.pl25g.svg, j.pl25g.noeuds > 0]')" '[[["Liste","true"],["Graphe","false"]],"visible",true]'
assert_eq "PL2.6 — phase sans dossier : « pas de plan », aucune section Plans" \
  "$(E2 '[j.pl26.texte.includes("pas de plan"), j.pl26.plans.includes("Plans")]')" '[true,false]'
for CLE in 1000 390; do
  X="j.pl27['$CLE']"
  assert_eq "PL2.7 ($CLE) — 52 caractères entier sans ellipse, 53 et 70 : 31 + « … » + 20 et texte complet décrit ; plan : titre coupé, identifiant entier" \
    "$(E2 "((cut) => [$X.a52.texte.length === 52, $X.a52.hauteur[0] === $X.a52.hauteur[1], $X.m53.texte === cut($X.m53.decrit) && Array.from($X.m53.decrit).length === 53,
      $X.l70.texte === cut($X.l70.decrit) && Array.from($X.l70.decrit).length === 70, $X.a52.nom.startsWith('4 '), $X.p70.pid === '01-03',
      $X.p70.texte === cut($X.p70.decrit)])((t) => { const a = Array.from(t); return a.slice(0, 31).join('') + '…' + a.slice(-20).join(''); })")" '[true,true,true,true,true,true,true]'
done
assert_eq "PL2.8 — Espace sélectionne, Entrée plonge, sur un plan Entrée ouvre le panneau ; au toucher : sélection sans plongée, bouton d'ouverture, Entrée plonge" \
  "$(E2 '[j.pl28.espace, j.pl28.cur, j.pl28.entree, j.pl28.ferme, j.pl28.plan, j.pl28.touch, j.pl28.tesp, j.pl28.tent]')" \
  '["n:ph-3",["n:ph-3"],"n:ph-3",true,[true,true,"n:ph-1"],["n:ph-3",true,"root",1],"n:ph-4","n:ph-4"]'
assert_eq "PL2.9a — témoin : aucune section du pilote n'a échoué" "$(E2 'Object.keys(j.erreurs).join()')" ""
vf_hyg_stop "$SRV"
LABS="$WORK/lab-sans"; mklabs "$LABS"; build_serve "$LABS"
R2B="$(mesurer chrome-projet-liste.mjs pl2b)"; sonde "$R2B"; E2B() { E "$1" "$R2B"; }; vf_hyg_stop "$SRV"
assert_eq "PL2.9 — porte substituée : le lab n'a aucune exigence (témoin positif) ; avec la fausse porte, deux exigences et « 2 exigences couvertes » par plan ; restaurée : vide" \
  "$(E2B '[j.pl29.graphe, j.pl29.vraie.li, j.pl29.fausse.li.length, j.pl29.fausse.li[0].includes("Cochée") && j.pl29.fausse.li[1].includes("Non cochée"), j.pl29.fausse.cov.length > 0 && j.pl29.fausse.cov.every((c) => c === "2 exigences couvertes"), j.pl29.restaure.li]')" \
  '[[0,0],0,2,true,true,0]'
assert_eq "PL2.9b — témoin : aucune section du pilote n'a échoué" "$(E2B 'Object.keys(j.erreurs).join()')" ""

echo "=== PL3 — touche v, mémoire, tri, largeurs, focus orphelin, zone basse ==="
build_serve "$LAB"
[ -n "${PL_PNG:-}" ] && { PNG="$(PL_PNG="$PL_PNG" mesurer chrome-projet-liste.mjs png)"; echo "  captures : $(E 'j.png.join(" ")' "$PNG")"; } # PL_PNG = dossier des captures de revue
R3="$(mesurer chrome-projet-liste.mjs pl3a)"; sonde "$R3"; E3() { E "$1" "$R3"; }
assert_eq "PL3.1 — v : couloirs → liste → graphe → couloirs ; focus sur l'élément équivalent (même phase), jamais body ; annonce « Affichage en liste, 6 phases »" \
  "$(E3 '[j.pl31.map((x) => x[0]).join(), j.pl31[0][1], j.pl31[0][2], j.pl31.every((x) => x[3] !== "body")]')" '["liste,graphe,couloirs","n:ph-4","Affichage en liste, 6 phases",true]'
assert_eq "PL3.2 — v dans un TEXTAREA et avec Alt, Ctrl, ⌘ : aucune bascule, la lettre est tapée ; témoin : v seule bascule" \
  "$(E3 '[j.pl32.saisie, j.pl32.mods.join(), j.pl32.simple]')" '[["couloirs","v"],"couloirs,couloirs,couloirs","liste"]'
assert_eq "PL3.3 — mémoire par lab et par classe de largeur ; défaut liste à 390 px ; ?vue= prime sans écrire ; la clé porte le nom du lab" \
  "$(E3 '[j.pl33.etroit, j.pl33.large, j.pl33.apres, j.pl33.url, j.pl33.memoire, j.pl33.cles[0].length >= 1 && j.pl33.cles[0].every((k) => k.includes(j.pl33.cles[1]))]')" '["liste","couloirs","graphe","liste","graphe",true]'
assert_eq "PL3.3b — rien de neuf sous .planning/ du lab" "$(git -C "$LAB" status --porcelain -- .planning | wc -l | tr -d ' ')" "0"
assert_eq "PL3.4 — tri par Plans : ascendant puis descendant, annonces, sans plan en dernier ; donnée absente après « aucune », texte masqué" \
  "$(E3 '[j.pl34.asc[0].join(), j.pl34.asc[1], j.pl34.asc[2], j.pl34.desc[0].join(), j.pl34.desc[1], j.pl34.desc[2], j.pl34.abs[0].slice(-1)[0], j.pl34.abs[1]]')" \
  '["n:ph-3,n:ph-4,n:ph-1,n:ph-2,n:ph-6,n:ph-5","plans","Trié par Plans, croissant","n:ph-1,n:ph-2,n:ph-6,n:ph-4,n:ph-3,n:ph-5",1,"Trié par Plans, décroissant","n:ph-3","donnée non disponible"]'
assert_eq "PL3.4b — l'en-tête actif porte le chevron du moteur tourné, en graisse 600 ; un seul chevron" \
  "$(E3 '[j.pl34.chev[0], j.pl34.chev[1], j.pl34.chev[2], j.pl34.chev[3]]')" '[true,true,"600",1]'
assert_eq "PL3.5b — 390 px : « aucune exigence » dit son mot" "$(E3 'j.pl35.aucune')" 'aucune exigence'
assert_eq "PL3.10 — un choix fait dans une phase (v, v) ne réécrit ni la forme de la racine ni la mémoire" \
  "$(E3 '[j.pl39.v1, j.pl39.v2, j.pl39.racine, j.pl39.memoire]')" '["graphe","liste","couloirs",null]'
assert_eq "PL3.5 — 390 px : rôles posés, quatre boutons de tri ≥ 44 px, bascule à trois segments ≥ 44 px pleine largeur sous le h1 ; aucun défilement horizontal (390, 600 et 800 px, feuille ou panneau ouvert ou non : P80-D-50 b)" \
  "$(E3 '[j.pl35.roles.join(), j.pl35.tri.length, Math.min(...j.pl35.tri) >= 44, j.pl35.bascule.hauteurs.length, Math.min(...j.pl35.bascule.hauteurs) >= 44, j.pl35.bascule.dessous, j.pl35.bascule.largeur >= j.pl35.bascule.vue - 40, j.pl35.ferme390.join(), j.pl35.ouvert390.join(), j.pl35.ferme600.join(), j.pl35.ouvert600.join(), j.pl35.ferme800.join(), j.pl35.ouvert800.join()]')" \
  '["true,true,true,true",4,true,3,true,true,true,"true,true,true","true,true,true","true,true,true","true,true,true","true,true,true","true,true,true"]'
assert_eq "PL3.6 — mouvement réduit : aucune animation active après une bascule et un tri" "$(E3 'j.pl36.join()')" "0,0"
assert_eq "PL3.9 — témoin : aucune section du pilote n'a échoué (v, mémoire, tri, largeurs)" "$(E3 'Object.keys(j.erreurs).join()')" ""
R3B="$(mesurer chrome-projet-liste.mjs pl3b)"; sonde "$R3B"; E3B() { E "$1" "$R3B"; }
assert_eq "PL3.7 — focus orphelin : en-tête de tri (clic, Entrée, direct) et summary gardent le focus sur le même contrôle, état inchangé ; jamais body" \
  "$(E3B '[j.pl37.entree.tri, j.pl37.entree.conn, j.pl37.clic.tri, j.pl37.direct.tri, j.pl37.sort.join(), j.pl37.hist.join(), j.pl37.back.join()]')" \
  '["plans",true,"plans","etat","none,none,descending,none","SUMMARY,historique,false","SUMMARY,backlog,true"]'
assert_eq "PL3.9b — témoin : aucune section du pilote n'a échoué (focus orphelin)" "$(E3B 'Object.keys(j.erreurs).join()')" ""
vf_hyg_stop "$SRV"
echo "=== PL3.8 — zone basse (lab lancé avec --terminal) ==="
LABT="$WORK/lab-term"; mklabl "$LABT"; build_serve "$LABT" --terminal
R5="$(mesurer chrome-projet-liste.mjs pl3c)"; sonde "$R5"; E5() { E "$1" "$R5"; }; vf_hyg_stop "$SRV"
for CLE in 1440 1024 390; do
  X="j.pl38['$CLE']"
  assert_eq "PL3.8 ($CLE) — padding-bottom = scroll-padding-block-end ≥ #ask + #vf-coin + pastille (+ feuille) ; la dernière rangée après Fin ne recoupe rien (racine, terminal, phase)" \
    "$(E5 "[Object.values($X).every((m) => m && m.pb === m.spb && m.pb >= m.somme && m.inter.length === 0 && m.id), $X.base.haut]")" '[true,true]'
done
assert_eq "PL3.8z — témoin : aucune section du pilote n'a échoué (zone basse)" "$(E5 'Object.keys(j.erreurs).join()')" ""

echo "=== PL4 — témoins de pointeur (P80-D-50 b : le Chrome sans tête de la CI Linux n'annonce aucun pointeur) ==="
printf '#!/bin/bash\nexec "%s" --blink-settings=primaryPointerType=1,availablePointerTypes=1,primaryHoverType=1,availableHoverTypes=1 "$@"\n' "$CHROME" > "$AUX/chrome-sans-pointeur"; chmod +x "$AUX/chrome-sans-pointeur"
CHROME_REEL="$CHROME"; build_serve "$LAB"
CHROME="$AUX/chrome-sans-pointeur"; RLN="$(mesurer chrome-pointeur-forme.mjs none liste)"; CHROME="$CHROME_REEL"
RLC="$(mesurer chrome-pointeur-forme.mjs coarse liste)"; vf_hyg_stop "$SRV"
PL41='[j.pointeur.fine, j.pointeur.coarse, j.focus.n > 0, j.focus.actif, j.focus.sel === j.focus.id]'
assert_eq "PL4.1 — sans aucun pointeur (Chrome de la CI Linux) : ni fine ni coarse ; le focus d'une rangée la sélectionne (panneau latéral, la sélection suit le focus)" \
  "$(E "$PL41" "$RLN")" '[false,false,true,true,true]'
assert_eq "PL4.2 — pointeur grossier (toucher émulé) : coarse vrai ; le focus d'une rangée ne la sélectionne pas (feuille de détail)" \
  "$(E '[j.pointeur.coarse, j.focus.n > 0, j.focus.actif, j.focus.sel]' "$RLC")" '[true,true,true,null]'
CHROME="$AUX/chrome-sans-pointeur"
mutant M-POINTEUR-LISTE 41-vf-projet-liste.js "(min-width: 1000px) and (not (pointer: coarse))" "(min-width: 1000px) and (pointer: fine)" chrome-pointeur-forme.mjs none liste
CHROME="$CHROME_REEL"
echo "     trace M-POINTEUR-LISTE — sonde PL4.1 [fine, coarse, rangées, focus posé, sélection = rangée] : attendu [false,false,true,true,true], obtenu $(E "$PL41" "$RM")"
assert_eq "M-POINTEUR-LISTE — le mutant (ancienne requête (pointer: fine)) rougit PL4.1 : sans pointeur la sélection ne suit plus le focus (témoin : Chrome sans pointeur, rangée focalisée)" \
  "$(E '[j.pointeur.fine, j.pointeur.coarse, j.focus.n > 0, j.focus.actif, j.focus.sel === j.focus.id]' "$RM")" '[false,false,true,true,false]'

echo "=== PL5 — idiome A51 : deux allers-retours Projet / Code, extensions réévaluées (80-a51) ==="
. "$HERE_T/a51-commun.sh"
build_serve "$LAB"
a51_mesurer "$WORK/a51-pl.json" "http://127.0.0.1:$PORT/project.html?vue=liste" projet code \
  "41-vf-projet-liste.js,41-vf-projet-phase.js,41-vf-projet-formes.js" ".vp-table,.vp-etat-l" "section.vf-projet,.vp-table"
vf_hyg_stop "$SRV"
assert_eq "PL5.1 — deux allers-retours Projet / Code : écouteurs, observateurs, feuilles et nœuds de la liste comme à la première arrivée ; rien de la liste sur Code" \
  "$(a51_verdict "$WORK/a51-pl.json" retours --absent-ailleurs)" "ok"
assert_eq "PL5.2 — liste, phase et touche v réévaluées deux fois (même cle) : un seul branchement actif, une seule feuille chacune" \
  "$(a51_verdict "$WORK/a51-pl.json" rejeu)" "ok"
echo "=== Mutants (copie du module dans \$WORK) ==="
mutant M-CLE 41-vf-projet-formes.js "'vf-projet-forme:' + nom + ':' + classe()" "'vf-projet-forme:' + classe()" chrome-projet-liste.mjs pl3a pl33
assert_eq "M-CLE — le mutant rougit PL3.3 (clé sans le nom du lab) (témoin : la mémoire fonctionne encore)" \
  "$(E "[j.pl33.cles[0].every((k) => k.includes(j.pl33.cles[1])), j.pl33.apres]" "$RM")" '[false,"graphe"]'
mutant M-TRI 41-vf-projet-liste.js "let tri = { col: 'etat', sens: 1 };" "let tri = { col: 'phase', sens: 1 };" chrome-projet-liste.mjs pl1 pl11,pl12
assert_eq "M-TRI — le mutant rougit PL1.1 (tri par numéro seul) (témoin : la table existe)" \
  "$(E "[j.pl11.tables >= 1, JSON.stringify(j.pl11.tri) !== '[[\"etat\",\"ascending\"]]', j.pl11.lignes.join() === 'n:ph-1,n:ph-2,n:ph-3,n:ph-4,n:ph-5,n:ph-6']" "$RM")" '[true,true,true]'
mutant M-SAISIE 41-vf-projet-formes.js "return; // garde:saisie" "void 0; // garde:saisie" chrome-projet-liste.mjs pl3a pl32
assert_eq "M-SAISIE — le mutant rougit PL3.2 (v captée dans un TEXTAREA) (témoin : v seule bascule)" \
  "$(E "[j.pl32.saisie[0] !== 'couloirs', j.pl32.saisie[1] !== 'v', j.pl32.simple]" "$RM")" '[true,true,"graphe"]'
mutant M-ORPHELIN-TRI 41-vf-projet-vue.js "if (ent) { // garde:orphelin-tri" "if (false && ent) { // garde:orphelin-tri" chrome-projet-liste.mjs pl3b pl37
assert_eq "M-ORPHELIN-TRI — le mutant rougit PL3.7 (restitution du focus d'en-tête et de summary retirée) (témoin : la table existe)" \
  "$(E "[j.pl37.entree.tag !== 'button' || j.pl37.direct.tri !== 'etat', j.pl37.hist[0] !== 'SUMMARY', j.pl37.sort.length > 0]" "$RM")" '[true,true,true]'
LAB_SAUVE="$LAB"; LAB="$LABS" # PL2.9 se joue sur le lab sans exigence
mutant M-PORTE 41-vf-projet-phase.js "lu = window.VF_EXIGENCES.lireExigences(id); // garde:porte" \
  "lu = (() => { const G = window.Floorplan.graph, ex = (G.files || []).filter((f) => f.n === id + '.req').map((f) => ({ id: f.name, texte: f.d, cochee: f.st === 'done', cible: 'f:' + f.p })), c = {};
    for (const l of G.links || []) { const e = ex.find((x) => l.b === x.cible); if (e && l.label === 'couvre') (c[l.a] = c[l.a] || []).push(e); } return { exigences: ex, couverture: c }; })(); // garde:porte" \
  chrome-projet-liste.mjs pl2b pl29; LAB="$LAB_SAUVE"
assert_eq "M-PORTE — le mutant rougit PL2.9 (lecture directe du nœud) alors que le rendu avec la vraie porte reste identique (témoin : la section a joué)" \
  "$(E "[j.pl29.fausse.li.length !== 2, j.pl29.vraie.li === 0, !!j.pl29.graphe]" "$RM")" '[true,true,true]'
mutant M-XSS-LISTE 41-vf-projet-liste.js '<span class="vp-titre">${h(c.titre)}</span>' '<span class="vp-titre">${c.titre}</span>' chrome-projet-liste.mjs pl1 pl11,pl14
assert_eq "M-XSS-LISTE — le mutant rougit PL1.4 (titre de phase sans h() : un img naît à la racine) (témoin : la table existe)" \
  "$(E "[j.pl14.img > 0, j.pl11.tables >= 1]" "$RM")" "[true,true]"
mutant M-XSS-PLAN 41-vf-projet-phase.js '<span class="vp-titre">${h(tr.affiche)}</span>' '<span class="vp-titre">${tr.affiche}</span>' chrome-projet-liste.mjs pl2 pl21,pl22
assert_eq "M-XSS-PLAN — le mutant rougit PL2.2b (titre de plan sans h() : un img naît dans la phase) (témoin : les plans existent)" \
  "$(E "[j.pl22.img > 0, j.pl21.plans.length === 3]" "$RM")" "[true,true]"
mutant M-PHASE 41-vf-projet-vue.js "if (niveau() === 'racine') { forme = nom; if (memoriser && MEM) MEM.ecrire(nom); } else formePhase = nom;" \
  "forme = nom; if (memoriser && MEM) MEM.ecrire(nom);" chrome-projet-liste.mjs pl3a pl39
assert_eq "M-PHASE — le mutant rougit PL3.10 (le choix d'une phase réécrit la racine et la mémoire) (témoin : v bascule dans la phase)" \
  "$(E "[j.pl39.racine !== 'couloirs', j.pl39.v1 === 'graphe']" "$RM")" "[true,true]"
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
