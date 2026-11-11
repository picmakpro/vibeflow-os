#!/usr/bin/env bash
# test-cockpit-visite-retours.sh — retours du panel utilisateurs, lot « visite et thème » (PU-G-009, 013, 018, 085, 087, 089, 090).
# Un lab jetable de forme VibeFlow (16 modules, deux services extérieurs : gsd et claude) servi par le VRAI lanceur ; un Chrome headless par mesure
# (chrome-visite-retours.mjs). Sans navigateur la suite est SAUTÉE, jamais comptée comme réussie.
# T1 bouton de thème : l'état courant en texte · T2 croix de la visite nommée · T3 anneau de focus du bouton de visite : clavier seulement
# T4 feuille de visite au téléphone : pleine largeur, « Étape n sur N » sur une ligne · T5 cadrage : la carte présentée est lisible, les services extérieurs sont cadrés
# T6 aucun cadre dessiné autour du titre ; boutons de rappel éclairés à la dernière étape · T7 tiroir Git ouvert pendant la visite : une seule Échap le ferme
set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export HOME="$WORK/home"; mkdir -p "$HOME"
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then . "$(dirname "$0")/chrome-saut.sh"; vf_chrome_saut "  ⊘ SAUTÉE : aucun navigateur — les retours de visite ne sont PAS vérifiés"; exit 0; fi
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
L="$WORK/lab"; mkdir -p "$L/.planning"
for i in $(seq -w 1 16); do
  M="$L/plugin/mod$i"; mkdir -p "$M/agents" "$M/scripts"
  printf '{"name":"mod%s","type":"agent-bundle","description":"Module numero %s du lab de test, qui fait une chose utile."}\n' "$i" "$i" > "$M/module.json"; echo 1.0.0 > "$M/VERSION"
  printf -- '---\nname: ag%s\ndescription: agent\ntools: Read, Agent(gsd-planner, general-purpose)\n---\ncorps\n' "$i" > "$M/agents/ag$i.md"
  printf '#!/usr/bin/env bash\necho %s\n' "$i" > "$M/scripts/run$i.sh"
done
printf '# Roadmap\n\n## Jalon demo\n\n- [ ] **Phase 1: Socle** - premier jet\n' > "$L/.planning/ROADMAP.md"
git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
# Moteur de questions : sans `claude` sur le PATH, la barre de question porte l'avis « no_engine » et mesure 44 à 56 px de plus (CI Linux, run 42486502412 : T9 à 701 et 760 px). La suite principale tourne AVEC un moteur
# (le faux claude des suites de lancement, identique sur un poste de dev et en CI) ; T9N, plus bas, rejoue la matrice basse SANS moteur.
FAUXBIN="$WORK/fauxbin"; mkdir -p "$FAUXBIN"; cp "$SCRIPTS/tests/temoins/fauxbin-claude/claude" "$FAUXBIN/claude"; chmod +x "$FAUXBIN/claude"; export PATH="$FAUXBIN:$PATH"
export VF_COCKPIT_PORT_BASE=$((30000 + (RANDOM * 11) % 30000))
trap 'node "$SCRIPTS/vf-cockpit.mjs" stop --lab "$L" >/dev/null 2>&1; vf_hyg_fin; rm -rf "$WORK"' EXIT
U="$(node "$SCRIPTS/vf-cockpit.mjs" open --no-open --terminal --lab "$L" | sed -En 's#^Cockpit : (http://127\.0\.0\.1:[0-9]+)/ .*#\1/index.html#p' | head -1)"
[ -n "$U" ] || { echo "  ❌ FAIL — le cockpit n'a pas démarré"; exit 1; }
AUX="$WORK/aux"; mkdir -p "$AUX"
cat > "$AUX/get.mjs" <<'JS'
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(process.argv[2] === '/dev/stdin' ? 0 : process.argv[2], 'utf8'));
console.log(String(Function('j', 'return (' + process.argv[3] + ')')(j)));
JS
mes() { node "$SCRIPTS/tests/chrome-visite-retours.mjs" "$CHROME" "$U" "$1" "$2" "${3:-}"; }
g() { printf '%s' "$1" | node "$AUX/get.mjs" /dev/stdin "$2"; }

echo "=== T1 — bouton de thème : l'état courant en texte ==="
X="$(mes 1440 theme)"; [ -n "${DBG:-}" ] && echo "RAW: $X"
assert_eq "T1.1 — mesure sans erreur, le texte du bouton suit le cycle Auto, Clair, Sombre, Auto" "$(g "$X" "j.erreur||j.textes.join(',')")" "Auto,Clair,Sombre,Auto"

echo "=== T3 — anneau de focus du bouton de visite ==="
X="$(mes 1280 focus)"; [ -n "${DBG:-}" ] && echo "RAW: $X"
assert_eq "T3.1 — visite rouverte à la souris puis une flèche : le bouton ne porte pas d'anneau (focus-visible faux) et la visite est ouverte" "$(g "$X" "j.erreur||[j.souris1.fv,j.souris1.ouverte].join(',')")" "false,true"
assert_eq "T3.2 — activé au clavier (Entrée), le bouton garde le focus et son anneau" "$(g "$X" "j.erreur||[j.clavier.actif,j.clavier.fv,j.clavier.ouverte].join(',')")" "true,true,true"

echo "=== T7 — tiroir Git ouvert pendant la visite : une seule Échap ==="
X="$(mes 1440 tiroir)"; [ -n "${DBG:-}" ] && echo "RAW: $X"
assert_eq "T7.1 — le tiroir est ouvert avant la touche (témoin) puis fermé par UNE Échap" "$(g "$X" "j.erreur||[j.avant.tiroir,j.apres.tiroir].join(',')")" "true,false"

echo "=== T2, T5, T6 — visite parcourue sur 1440 px ==="
X="$(mes 1440 visite)"; [ -n "${DBG:-}" ] && echo "RAW: $X"
assert_eq "T2.0 — témoin : visite parcourue sans erreur, au moins trois étapes" "$(g "$X" "j.erreur||(j.n>=3)")" "true"
assert_eq "T2.1 — la croix de la visite porte un nom accessible à chaque étape" "$(g "$X" "j.etapes.every((e)=>e.croix&&e.croix.length>3)")" "true"
assert_eq "T5.1 — la carte présentée aux étapes 2 et 3 mesure au moins 200 px de large à l'écran (lisible)" "$(g "$X" "j.etapes.slice(1,j.n-1).every((e)=>e.largeurCartes.length>0&&Math.max(...e.largeurCartes)>=200)")" "true"
assert_eq "T5.2 — la dernière étape éclaire les services extérieurs, tous dans la fenêtre et lisibles (≥ 150 px)" "$(g "$X" "[j.etapes[j.n-1].cartesEclairees>=2,j.etapes[j.n-1].dansFenetre,Math.min(...j.etapes[j.n-1].largeurCartes)>=150].join(',')")" "true,true,true"
assert_eq "T6.1 — aucune étape ne dessine de contour autour d'un bloc de la page" "$(g "$X" "j.etapes.every((e)=>e.contours.every((c)=>c==='none'))")" "true"
assert_eq "T6.2 — la dernière étape éclaire le bouton de visite (surbrillance posée sur lui)" "$(g "$X" "j.etapes[j.n-1].litSurTour")" "true"
assert_eq "T6.3 — la dernière étape ne vise pas le titre : aucun repère de cadrage sur #context quand des cartes sont éclairées" "$(g "$X" "j.etapes[j.n-1].cadreSurTitre")" "false"

echo "=== T4 — feuille de visite à 390 px ==="
X="$(mes 390 visite)"; [ -n "${DBG:-}" ] && echo "RAW: $X"
assert_eq "T4.0 — témoin : mesure sans erreur, au moins trois étapes" "$(g "$X" "j.erreur||(j.n>=3)")" "true"
assert_eq "T4.1 — la carte de visite est une feuille pleine largeur (≥ 370 px de large) à chaque étape" "$(g "$X" "j.etapes.every((e)=>e.carte.w>=370)")" "true"
assert_eq "T4.2 — la feuille est en bas : son bord bas est dans le dernier quart de l'écran" "$(g "$X" "j.etapes.every((e)=>e.carte.b>=e.ecran[1]*0.75)")" "true"
assert_eq "T4.3 — « Étape n sur N » tient sur une seule ligne (chaque segment du repère ≤ 20 px de haut)" "$(g "$X" "j.etapes.every((e)=>e.repereHauteurs.every((h)=>h<=20))")" "true"
# PU-G-090 (recette du 2026-11-08) : au téléphone AVEC la pastille Terminal, la feuille est posée au-dessus d'elle, plus haut que la barre de question ; le zoom doit rester au-dessus de la FEUILLE
# (et non d'une hauteur supposée), sinon il la recouvre et elle se réduit à 120 px : titre coupé, description sous « Passer / Suivant ».
# la suite lance elle-même le cockpit avec --terminal : une pastille absente est une panne du banc, jamais un saut (un saut rendrait T4.4 à T4.6 verts à vide)
assert_eq "T4.3b — témoin : la pastille Terminal est posée à chaque étape (la suite lance --terminal)" "$(g "$X" "j.etapes.every((e)=>e.lisible.pastille)")" "true"
assert_eq "T4.4 — le texte de la feuille se lit en entier à chaque étape (le titre et la description tiennent, rien ne défile ni n'est coupé)" "$(g "$X" "j.etapes.every((e)=>e.lisible.texteEntier)")" "true"
assert_eq "T4.5 — la rangée Passer / Suivant ne recouvre pas le texte (le bas du texte est au-dessus du haut des boutons) et la feuille dépasse 120 px" "$(g "$X" "j.etapes.every((e)=>e.lisible.texteBas<=e.lisible.boutonsHaut&&e.lisible.carteH>120)")" "true"
assert_eq "T4.6 — le zoom ne recouvre pas la feuille (son bord bas est au-dessus du bord haut de la feuille) et la feuille laisse la pastille libre" "$(g "$X" "j.etapes.every((e)=>e.lisible.zoomBas<=e.lisible.carteHaut&&e.carte.b<=e.lisible.pastilleHaut)")" "true"
echo "=== T8 — fin de visite avec le terminal : le zoom ne retombe pas sur la pastille (I-1, intégration) ==="
# la pastille Terminal est posée (--terminal) ; on juge APRÈS la fin de la visite, avec un redimensionnement pendant la visite (« fin ») ou sans (« fin-sans »), de 390 à 1 440 px
sans_recouvrement() { g "$1" "j.erreur||[j.pendant.pastille,j.apres.pastille,j.apres.visite,j.pendant.zoomPastille||j.pendant.zoomBarre||j.pendant.pastilleBarre||j.apres.zoomPastille||j.apres.zoomBarre||j.apres.pastilleBarre].join(',')"; }
for w in 390 768 1000 1280 1440; do
  X="$(mes $w fin)"; [ -n "${DBG:-}" ] && echo "RAW: $X"
  assert_eq "T8.fin.$w — pastille posée, visite finie, aucun recouvrement zoom / pastille / barre pendant et après la visite (redimensionnement pendant la visite)" "$(sans_recouvrement "$X")" "true,true,false,false"
done
for w in 390 768; do
  X="$(mes $w fin-sans)"; [ -n "${DBG:-}" ] && echo "RAW: $X"
  assert_eq "T8.sans.$w — pastille posée, visite finie, aucun recouvrement zoom / pastille / barre (sans redimensionnement)" "$(sans_recouvrement "$X")" "true,true,false,false"
done
echo "=== T9 — carte de visite : ni la pastille Terminal ni le titre recouverts, de 701 à 1 440 px, jusqu'à 390 px de haut (I-3, intégration) ==="
# la carte de visite se place là où elle recouvre le moins ; sur une fenêtre basse la colonne du zoom et de la pastille barrait le bord gauche et le panneau de détail (même fermé : O6.17 de la suite projet-visite
# le tient pour une surface) le côté droit : la carte retombait sur la pastille (Code, Projet) ou sur le titre (Projet). Elle peut maintenant se poser à droite de cette colonne. Chaque étape est jugée une fois posée ;
# la pastille est posée (--terminal), la visite compte au moins deux étapes.
# décision déléguée par Samuel (message session principale, 2026-11-08, consignée en § 10 du rapport GLOBAL, 599a42a5), option recommandée : placer la carte du côté libre (à droite de la colonne) plutôt que la réduire ou la rendre défilable
cote_attendu() { case "$1:$2" in index.html:701x390|index.html:760x390) echo colonne ;; *) echo titre ;; esac; }
for pg in index.html project.html; do
  for t in 701x390 760x390 844x390 1000x420 1100x390 1279x450 1440x390; do
    X="$(mes $t visite $pg)"; [ -n "${DBG:-}" ] && echo "RAW: $X"
    assert_eq "T9.$pg.$t — au moins deux étapes, pastille posée à chacune, la carte de visite ne recouvre ni la pastille ni le titre" "$(g "$X" "j.erreur||[j.n>=2,j.etapes.every((e)=>e.lisible.pastille),JSON.stringify(j.etapes.map((e)=>e.recouvre).filter((r)=>r.length))].join(',')")" "true,true,[]"
    # J1 (passe de suivi) : la carte se LIT aussi. À 844 x 390 elle restait à 121 px de haut, son texte rogné, alors que la place à droite du bloc titre était libre. À chaque étape le texte tient sans défiler ;
    # faute de toute place (701 px, panneau ouvert) au moins le titre entier et la première ligne de la description sont visibles .
    # M-B (revue finale) : le côté « titre » (à droite du bloc titre) sert dans une fenêtre basse quand la place libre le permet ; sans lui T9L restait vert (le critère se contente de 72 px de texte utile). Côté attendu par taille : la place
    # à droite du titre (entre lui et le panneau) fait au moins 160 px dès 844 px de large sur l'onglet Code, et à toute largeur sur l'onglet Projet (titre plus court) ; en dessous, sur Code, la colonne du zoom.
    assert_eq "T9S.$pg.$t — le côté de la carte à chaque étape ($(cote_attendu $pg $t))" "$(g "$X" "j.erreur||[...new Set(j.etapes.map((e)=>JSON.parse(e.placement).choice.side))].join(',')")" "$(cote_attendu $pg $t)"
    assert_eq "T9L.$pg.$t — à chaque étape la carte se lit : le texte tient sans défiler, ou à défaut le titre est entier et la première ligne de la description visible" "$(g "$X" "j.erreur||JSON.stringify(j.etapes.map((e,k)=>[k,e.lisible]).filter(([k,l])=>!(l.texteEntier||(l.titreEntier&&l.debutDescription))).map(([k,l])=>[k,l.utile,l.titreEntier,l.debutDescription]))")" "[]"
  done
done

echo "=== T10 — tailles normales : la carte est posée comme avant J1, jamais à droite du titre (revue finale, M-A) ==="
# Le côté « titre » (J1) ne sert que dans une fenêtre basse (<= 480 px, la borne de la règle @media de la carte). Avant la correction, à 1 440 x 900 la carte passait de 16,519,376,786 (bas à gauche) à 285,557,645,824 (« titre »), et la caméra
# de la carte bougeait avec. Valeurs : côté|gauche|droite|bas de la carte à la première étape, mesurées sur 0a0259b5 (avant J1) ; la colonne du zoom prend la place d'en bas à gauche sous 1 280 px (PU-G-021).
for spec in 1440x900:left\|16\|376\|786 1366x768:left\|16\|376\|654 1280x720:left\|16\|376\|606 1100x700:colonne\|138\|498\|624 1024x768:colonne\|138\|498\|692 901x800:colonne\|168\|528\|680; do
  t="${spec%%:*}"; att="${spec#*:}"; att="${att//\\/}"
  X="$(mes $t visite index.html)"; [ -n "${DBG:-}" ] && echo "RAW: $X"
  assert_eq "T10.$t — première étape : côté|gauche|droite|bas de la carte, comme avant J1" "$(g "$X" "j.erreur||[JSON.parse(j.etapes[0].placement).choice.side,j.etapes[0].carte.l,j.etapes[0].carte.r,j.etapes[0].carte.b].join('|')")" "$att"
done

echo "=== T9N — la matrice basse SANS moteur de questions : l'avis allonge la barre, la carte ne recouvre toujours ni le titre ni la pastille (CI Linux) ==="
# Sans `claude` (le cas de la CI et d'un poste neuf) la barre de question porte l'avis « no_engine » : 148 px au lieu de 92 à 701 px. La place sous le bloc titre tombait à 88 px, sous les 120 de la carte : elle recouvrait le titre
# aux quatre étapes à 701 et 760 px (Code). L'avis est le seul obstacle qui s'efface (il revient à la fin de la visite) : son aire compte dix fois moins. Le PATH du serveur est celui du système (aucun claude) plus un lien vers node.
SANS="$WORK/bin-sans-moteur"; mkdir -p "$SANS"; ln -sf "$(command -v node)" "$SANS/node"; PATH_SANS="$SANS:/usr/bin:/bin:/usr/sbin:/sbin"
PATH="$PATH_SANS" command -v claude >/dev/null 2>&1 && { echo "  ❌ FAIL — T9N : le PATH sans moteur porte un claude ($(PATH="$PATH_SANS" command -v claude))"; FAIL=$((FAIL+1)); }
L2="$WORK/lab2"; cp -R "$L" "$L2"; rm -rf "$L2/.vibeflow" # sinon le lanceur réutilise le serveur (avec moteur) de la copie
U2="$(PATH="$PATH_SANS" node "$SCRIPTS/vf-cockpit.mjs" open --no-open --terminal --lab "$L2" | sed -En 's#^Cockpit : (http://127\.0\.0\.1:[0-9]+)/ .*#\1/index.html#p' | head -1)"
[ -n "$U2" ] || { echo "  ❌ FAIL — le cockpit sans moteur n'a pas démarré"; FAIL=$((FAIL+1)); }
U1="$U"; U="$U2"
for pg in index.html project.html; do
  for t in 701x390 760x390 844x390; do
    X="$(mes $t visite $pg)"; [ -n "${DBG:-}" ] && echo "RAW: $X"
    assert_eq "T9N.0.$pg.$t — sans moteur : l'avis est affiché (la barre de question est plus haute que les 92 px d'une barre sans avis)" "$(g "$X" "j.erreur||j.etapes[0].placement.includes('#ask-warn')")" "true"
    assert_eq "T9N.$pg.$t — sans moteur : la carte ne recouvre ni la pastille ni le titre, à chaque étape" "$(g "$X" "j.erreur||[j.n>=2,j.etapes.every((e)=>e.lisible.pastille),JSON.stringify(j.etapes.map((e)=>e.recouvre).filter((r)=>r.length))].join(',')")" "true,true,[]"
    assert_eq "T9NL.$pg.$t — sans moteur : à chaque étape la carte se lit (texte entier, ou titre entier et début de la description)" "$(g "$X" "j.erreur||JSON.stringify(j.etapes.map((e,k)=>[k,e.lisible]).filter(([k,l])=>!(l.texteEntier||(l.titreEntier&&l.debutDescription))).map(([k,l])=>[k,l.utile,l.titreEntier,l.debutDescription]))")" "[]"
  done
done
U="$U1"; PATH="$PATH_SANS" node "$SCRIPTS/vf-cockpit.mjs" stop --lab "$L2" >/dev/null 2>&1
echo; echo "Résultat : $PASS passés, $FAIL en échec"; [ "$FAIL" -eq 0 ]
