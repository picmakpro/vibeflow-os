#!/usr/bin/env bash
# test-cockpit-ecrans-recent.sh — DG-02 (écran fantôme) et DG-03 (compteurs des cartes marquées), retours panel 2026-11-06 ; couche déclarative retirée en 75-09b.
#   E1 une route citée dans un commentaire n'est pas une route (// et /* */), la vraie route reste lue (témoin positif)
#   E2 la marque de taille n'est pas le résumé d'un écran (buildScreens)
#   E3 aucun écran : aucun bouton Écrans (rien à proposer, l'en-tête ne s'élargit pas) ; avec un écran, le bouton et le menu
#   E4 la marque de taille n'est pas la description d'une carte de fichier (extract.mjs)
#   R1 la pastille du sélecteur de lentilles compte des cartes (un fichier écrit par deux agents = une carte), lue sur la table des marques
#   R2 l'agrégat du nœud sur le canal VF_MARQUES compte les mêmes cartes (une marque par carte)
#   Q8 la page ne porte plus la couche retirée, le jeton --recent reste · Q8b le tableau générique showBoard reste · Q10 la fixture est une table de marques
# Variable ECRANS_MOTEUR : un autre arbre de moteur (le témoin rouge se rejoue sur la base cb499810).
# Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null VF_COCKPIT_GIT_DURCI=1
HERE="$(cd "$(dirname "$0")" && pwd)"
MOTEUR="${ECRANS_MOTEUR:-$HERE/../../skills/cockpit-moteur}"
FX="$HERE/fixtures/test-cockpit-ecrans-recent"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }

echo "== E1 routes dans les commentaires =="
LAB="$WORK/lab"; cp -R "$FX/lab" "$LAB"
( cd "$LAB" && git init -q . && git add -A && git -c user.email=t@t -c user.name=t commit -qm i ) >/dev/null 2>&1
node "$MOTEUR/scripts/scan.mjs" "$LAB" >/dev/null 2>&1
cat > "$WORK/hints.mjs" <<'JS'
import fs from 'node:fs';
const s = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const f = s.files.find((x) => x.path === process.argv[3]);
console.log(f ? (f.screens || []).map((x) => x.url).join(',') : 'FICHIER-ABSENT');
JS
SCAN="$LAB/.vibeflow/cockpit/.cache/scan.json"
assert_eq "E1.1 le commentaire // et le bloc /* */ ne donnent aucun écran" "$(node "$WORK/hints.mjs" "$SCAN" moteur/ecrans.mjs)" ""
assert_eq "E1.2 témoin positif : la vraie route est lue" "$(node "$WORK/hints.mjs" "$SCAN" 'routes/products.$id.tsx')" "/vraie/:id"

echo "== E2 marque de taille =="
cat > "$WORK/desc.mjs" <<'JS'
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const { buildScreens } = await import(pathToFileURL(path.join(process.argv[2], 'scripts/lib/screens.mjs')).href);
const mk = (d) => buildScreens({ root: null, arch: {}, scan: { files: [{ path: 'app/a/page.tsx', screens: [{ fw: 'next-app', url: '/a' }] }], edges: [], extEdges: [] },
  graph: { nodes: [{ id: 'app', label: 'App', kind: 'app' }], routes: [], links: [], files: [{ p: 'app/a/page.tsx', n: 'app', name: 'A', d, s: [] }] } });
const r = [mk('vibeflow:allow-large-file (code vendorisé, VENDORED.txt) Le vrai résumé.'), mk('Un résumé sans marque.'), mk('vibeflow:allow-large-file')];
console.log(r.map((x) => x.length + ':' + (x[0] ? x[0].description : '-')).join('|'));
JS
assert_eq "E2.1 la marque est retirée, le résumé voisin reste, un résumé sans marque est intact" "$(node "$WORK/desc.mjs" "$MOTEUR" 2>&1)" "1:Le vrai résumé.|1:Un résumé sans marque.|1:"

echo "== E3 aucun écran =="
H="$FX/ui-harness.mjs"
J0="$(node "$H" "$MOTEUR/assets/ui/30-screens.js" "$FX/ecrans-0.json" 2>&1)"
J1="$(node "$H" "$MOTEUR/assets/ui/30-screens.js" "$FX/ecrans-1.json" 2>&1)"
cat > "$WORK/j.mjs" <<'JS'
const j = JSON.parse(process.argv[2]);
console.log(new Function('j', 'return (' + process.argv[3] + ')')(j));
JS
q() { node "$WORK/j.mjs" "$1" "$2" 2>&1; }
assert_eq "E3.1 sans écran : aucun bouton Screens dans l'en-tête" "$(q "$J0" "j.buttons.length")" "0"
assert_eq "E3.2 un écran : le bouton Screens est posé" "$(q "$J1" "j.buttons.map((b)=>b.id).join()")" "screens-btn"
assert_eq "E3.3 sans écran : pas de section « Screens 0 » dans le panneau" "$(q "$J0" "j.sections.filter((s)=>s.html).length")" "0"
assert_eq "E3.4 un écran : le menu le liste" "$(q "$J1" "j.menuOuvert.join('').includes('/vraie/:id')")" "true"

echo "== R1/R2 comptes des cartes marquées (canal) =="
UI="$MOTEUR/assets/ui"
JR="$(node "$FX/canal-harness.mjs" "$UI/75-vf-activite-tables.js" "$UI/75-vf-marques.js" "$FX/recent-doublons.json" 2>&1)"
assert_eq "R1.1 pastille du sélecteur : 3 cartes (4 écritures d'agents, a.js écrit par deux agents)" "$(q "$JR" "j.pastille")" "3"
assert_eq "R1.2 table des marques : même nombre que la pastille, une rangée par carte" "$(q "$JR" "j.cartes")" "3"
assert_eq "R2.1 agrégat du nœud sur le canal : 3 en écriture, comme les cartes" "$(q "$JR" "j.noeud.join(';')")" "3|3 en écriture|true"
assert_eq "R2.2 canal : une seule marque sur la carte écrite par deux agents" "$(q "$JR" "j.fichier")" "1"

echo "== Q8/Q8b/Q10 la couche retirée, showBoard et la fixture =="
BTN="btn"; BTN="$BTN-recent"; NOR="no"; NOR="$NOR-recent"; TIP="recent"; TIP="${TIP}Tip"; HIL="Highlight"; HIL="$HIL recent work"
PAGE="$MOTEUR/assets/viewer.html"
assert_eq "Q8.1 aucune référence au bouton de l'ancienne couche dans la page ni dans ses modules (survol compris)" "$(grep -rl -- "$BTN" "$PAGE" "$UI" | wc -l | tr -d ' ')" "0"
assert_eq "Q8.2 ni pastille, ni bascule, ni infobulle de l'ancienne couche dans la page et ses modules (les dictionnaires français sont retirés par 75-09c)" "$(grep -rlE --exclude='*vf-fr*' -- "\\.rw\\b|class=\"rw|$NOR|$TIP|$HIL" "$PAGE" "$UI" | wc -l | tr -d ' ')" "0"
assert_eq "Q8.3 aucune règle de carte surlignée (.card.recent, .recent-in) n'est active" "$(grep -cE -- "\\.card\\.recent" "$PAGE")" "0"
assert_eq "Q8.4 le jeton --recent reste défini (clair et sombre) et sert le glyphe « en écriture »" "$(grep -c -E -- '^ *--recent: ' "$PAGE")|$(grep -c -- 'var(--recent)' "$UI/75-vf-marques-glyphes.js")" "2|1"
assert_eq "Q8b.1 showBoard (tableau générique du moteur) reste défini et exposé, appelé par Santé et par Écrans" "$(grep -c -E -- '^function showBoard|showBoard[,}]' "$PAGE" | awk '{print ($1>=2)?"ok":"non"}')|$(grep -c showBoard "$UI/20-health.js" | awk '{print ($1>=1)?"ok":"non"}')|$(grep -c showBoard "$UI/30-screens.js" | awk '{print ($1>=1)?"ok":"non"}')" "ok|ok|ok"
assert_eq "Q10.1 la fixture est une table de marques : 4 écritures d'agents sur 3 fichiers (témoin positif du doublon)" "$(q "$(cat "$FX/recent-doublons.json")" "j.marques.reduce((n,m)=>n+m[2].length,0)+'/'+j.marques.length")" "4/3"

echo "== E4 marque de taille dans la description d'une carte =="
cat > "$WORK/doc.mjs" <<'JS'
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const { extract } = await import(pathToFileURL(path.join(process.argv[2], 'scripts/lib/extract.mjs')).href);
const d = (src, lang, p) => (extract(src, lang, p).doc || '').replace(/\s+/g, ' ').trim();
console.log([
  d('// vibeflow:allow-large-file (code vendorisé, VENDORED.txt)\n// Le vrai résumé.\nexport const a = 1;\n', 'javascript', 'a.mjs'),
  d('// Un résumé sans marque.\nexport const a = 1;\n', 'javascript', 'b.mjs'),
  d('# vibeflow:allow-large-file (x)\n# Résumé hash.\nA=1\n', 'shell', 'c.sh'),
  d('// vibeflow:allow-large-file (x)\nexport const a = 1;\n', 'javascript', 'd.mjs'),
].join('|'));
JS
assert_eq "E4.1 marque retirée, résumé voisin gardé, fichier sans marque intact, marque seule = vide" "$(node "$WORK/doc.mjs" "$MOTEUR" 2>&1)" "Le vrai résumé.|Un résumé sans marque.|Résumé hash.|"

echo; echo "Résultat : $PASS réussis, $FAIL échecs"
[ "$FAIL" -eq 0 ]
