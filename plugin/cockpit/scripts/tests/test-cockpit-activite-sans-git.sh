#!/usr/bin/env bash
# test-cockpit-activite-sans-git.sh — Phase 75, plan 75-10 : la dégradation sans git (ACTV-12, P78-D-11, P75-D-11) et le lab non VibeFlow.
# Trois labs de même contenu : A (hors dépôt git), B (dans un dépôt), N (un dépôt sans `.planning` : lab non VibeFlow). Un vrai Chrome sans affichage lit la page réelle.
#   X3 : A et B, lentille « Aucune » : mêmes cartes, mêmes liens (graph.json normalisé : les clés propres à git sont EXCLUES et NOMMÉES ci-dessous), même géométrie, même pied réservé ;
#        sélecteur : Points chauds et Couplage absents, Gardes et Empreinte présents ; aucune marque ; GET /api/vf/activite : git.etat « absent ».
#   X4 : lab non VibeFlow : ligne Gardes atténuée, « Gardes non lues sur ce lab », jamais « tout est sans témoin ».
# Clés de graph.json propres à git (exclues de la comparaison) : meta.* (horodatages, nom et chemin de la racine, repos, vfGit, vfPrevuAt), project (nom), nodes[].stats.repos, files[].r (dépôt du fichier).
# Mutants (`MUTANT-ROUGE — <nom>`, copie du module, la suite doit les VOIR rouges) : « pied réservé conditionné à git » et « lignes Points chauds et Couplage posées sans git ».
# Forme : « PASS — <id> : <texte> », « ❌ FAIL — <id> : <texte> », ligne finale « BILAN : <n> PASS, <m> FAIL » ; sort en 1 au premier FAIL. Sans navigateur : SAUTÉ (jamais réussi).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(cd "$HERE/.." && pwd)"
FX="$HERE/fixtures/test-cockpit-activite-carte"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"
PIDS=()
cleanup() { type vf_hyg_fin > /dev/null 2>&1 && vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
PASS=0; FAIL=0
NB=$'\xc2\xa0'
fin() { echo "BILAN : $PASS PASS, $FAIL FAIL"; [ "$FAIL" -eq 0 ]; exit $?; }
assert_eq() { # id texte obtenu attendu
  if [ "$3" = "$4" ]; then echo "  ✅ PASS — $1 : $2"; PASS=$((PASS+1))
  else echo "  ❌ FAIL — $1 : $2"; echo "     attendu: [${4:0:700}]"; echo "     obtenu:  [${3:0:700}]"; FAIL=$((FAIL+1)); fin; fi
}
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" > /dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then . "$HERE/chrome-saut.sh"; vf_chrome_saut "  ⊘ SAUTÉ : aucun navigateur (Chrome, Chromium) — la dégradation sans git NON vérifiée, non comptée comme réussie"; fin; fi

mkdir -p "$WORK/home/.claude" "$WORK/aux"; export REAL_HOME="$HOME"; export HOME="$WORK/home"; AUX="$WORK/aux"
. "$HERE/hygiene.sh"; vf_hyg_init
. "$HERE/socle-serveur.sh"
. "$FX/mk-lab.sh"
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; let j; try { j = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { console.log('sortie illisible'); process.exit(0); }
if (j && j.erreur) { console.log('mesure indisponible : ' + j.erreur); process.exit(0); }
const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
# normalisation de graph.json : retire les clés propres à git (nommées dans l'en-tête), rend le reste en JSON canonique
cat > "$AUX/norme.mjs" <<'JS'
import fs from 'node:fs';
const g = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
delete g.meta; delete g.project;
for (const n of g.nodes || []) if (n.stats) delete n.stats.repos;
for (const f of g.files || []) delete f.r;
const tri = (x) => (Array.isArray(x) ? x.map(tri) : x && typeof x === 'object' ? Object.fromEntries(Object.keys(x).sort().map((k) => [k, tri(x[k])])) : x);
process.stdout.write(JSON.stringify(tri(g)));
JS

mesurer() { # mesurer <lab> : serveur lancé DANS le shell courant, page mesurée, route lue, serveur arrêté ; résultats : MESURE (JSON de la page) et ROUTE (JSON de la route)
  local lab="$1" rc
  MESURE='{"erreur":"serveur-non-demarre"}'; ROUTE='{"erreur":"serveur-non-demarre"}'
  cockpit_lancer "$lab"; rc=$?
  [ "$rc" -eq 0 ] || return 0
  # la route lit git hors de la requête : on attend un état lu (ni « en-lecture » ni calcul en cours), 80 s au plus (un lab hors dépôt attend la grâce de 30 s avant de calculer) ; la page est mesurée ensuite
  local fin=$((SECONDS + 80))
  while [ "$SECONDS" -lt "$fin" ]; do
    cockpit_get /api/vf/activite > "$WORK/route.json"
    [ "$(node "$AUX/ev.mjs" 'j.git.etat !== "en-lecture" && j.calcul === "pret"' < "$WORK/route.json")" = "true" ] && break; sleep 0.3
  done
  ROUTE_CODE="$VF_CODE"
  MESURE="$(REAL_HOME="$REAL_HOME" node "$HERE/chrome-activite-sans-git.mjs" "$CHROME" "http://127.0.0.1:$VF_PORT" 2> "$WORK/mesure.err")"
  cockpit_get /api/vf/activite > "$WORK/route.json"; ROUTE="$(cat "$WORK/route.json")"
  cockpit_arreter
}

LABA="$WORK/laba"; LABB="$WORK/labb"; LABN="$WORK/labn"
# A et B sont des labs VibeFlow (un plugin/*/module.json : l'extracteur « vibeflow », donc les gardes sont lues) ; N est un lab brut (aucun module.json : « Gardes non lues »)
vflab() { mkdir -p "$1/plugin/demo"; printf '{"name":"demo","version":"1.0.0"}\n' > "$1/plugin/demo/module.json"; printf '1.0.0\n' > "$1/plugin/demo/VERSION"; }
vflab "$LABA"; mklab75 "$LABA" nogit; vflab "$LABB"; mklab75 "$LABB"; mklab75 "$LABN"
assert_eq X3 "témoin de montage : A et B sont des labs VibeFlow, N un lab brut (meta.vfCodeExtractor)" "$(for l in "$LABA" "$LABB" "$LABN"; do node -e "console.log(JSON.parse(require('fs').readFileSync('$l/.vibeflow/cockpit/graph.json','utf8')).meta.vfCodeExtractor)"; done | tr '\n' ',')" "vibeflow,vibeflow,brut,"

echo "== X3 graph.json : mêmes cartes et mêmes liens, hors clés propres à git =="
node "$AUX/norme.mjs" "$LABA/.vibeflow/cockpit/graph.json" > "$WORK/na.json"; node "$AUX/norme.mjs" "$LABB/.vibeflow/cockpit/graph.json" > "$WORK/nb.json"
assert_eq X3 "les deux graphes normalisés sont octet pour octet les mêmes (cartes, liens, états, plans prévus)" "$(cmp -s "$WORK/na.json" "$WORK/nb.json" && echo identiques || echo differents)" "identiques"
assert_eq X3 "témoin de normalisation : les clés exclues DIFFÈRENT bien (le dépôt git est visible dans meta.vfGit), sinon la comparaison est aveugle" \
  "$(node -e "const f=(p)=>JSON.parse(require('fs').readFileSync(p,'utf8')).meta.vfGit.etat; console.log(f('$LABA/.vibeflow/cockpit/graph.json')+'|'+f('$LABB/.vibeflow/cockpit/graph.json'))")" "absent|ok"
assert_eq X3 "le graphe n'est pas vide (des cartes et des liens existent des deux côtés)" "$(node -e "const g=JSON.parse(require('fs').readFileSync('$WORK/na.json','utf8')); console.log((g.files||[]).length>30 && (g.nodes||[]).length>=1)")" "true"

echo "== X3 lab hors dépôt (A) =="
mesurer "$LABA"; RA="$MESURE"; ROUTE_A="$ROUTE"; CODE_A="$ROUTE_CODE"; [ -z "${DEBOGUE:-}" ] || { printf "%s" "$ROUTE_A" | node "$AUX/ev.mjs" "JSON.stringify([j.gardes.etat, j.etat, j.empreinte.etat])" >&2; printf "%s" "$RA" | node "$AUX/ev.mjs" "JSON.stringify(j.menu)" >&2; }
assert_eq X3 "GET /api/vf/activite répond 200 (la route existe)" "$CODE_A" "200"
assert_eq X3 "la mesure du navigateur a abouti" "$(printf '%s' "$RA" | node "$AUX/ev.mjs" 'Object.keys(j).sort().join(",")')" "lentille,marques,menu,niveaux"
assert_eq X3 "GET /api/vf/activite : git.etat absent, et le champ « git » ne porte aucune ligne de Points chauds" "$(printf '%s' "$ROUTE_A" | node "$AUX/ev.mjs" '[j.git.etat, (j.git.chauds||[]).length, (j.git.couplage||[]).length]')" '["absent",0,0]'
assert_eq X3 "sélecteur : Points chauds et Couplage absents ; Aucune, Gardes et Empreinte présents" "$(printf '%s' "$RA" | node "$AUX/ev.mjs" 'j.menu.map((r) => r.id).join(",")')" "aucune,gardes,empreinte"
assert_eq X3 "aucune lentille active et aucune marque de lentille : seule la carte prévue du plan porte une marque (canal du plan)" "$(printf '%s' "$RA" | node "$AUX/ev.mjs" '[j.lentille, j.marques.filter((id) => !/neuf\.mjs|orphelin\.mjs/.test(id)).length]')" '[null,0]'
assert_eq X3 "la ligne Gardes dit l'état de la route, jamais un état inventé (hors dépôt, la route rend gardes.etat « indisponible » : la ligne est alors désactivée et le dit)" "$(printf '%s' "$RA" | node "$AUX/ev.mjs" 'j.menu.filter((r) => r.id === "gardes")[0].desactive'):$(printf '%s' "$ROUTE_A" | node "$AUX/ev.mjs" 'j.gardes.etat')" "true:indisponible"

echo "== X3 lab dans un dépôt (B), lentille « Aucune » : même géométrie, même pied réservé =="
mesurer "$LABB"; RB="$MESURE"; ROUTE_B="$ROUTE"
assert_eq X3 "témoin : le lab B voit git (route : git.etat ok) et le sélecteur y propose Points chauds et Couplage" "$(printf '%s' "$ROUTE_B" | node "$AUX/ev.mjs" 'j.git.etat'):$(printf '%s' "$RB" | node "$AUX/ev.mjs" 'j.menu.map((r) => r.id).join(",")')" "ok:aucune,chauds,couplage,gardes,empreinte"
assert_eq X3 "mêmes cartes à la même place, même taille, même hauteur de pied (nœud et dossier virtuel) : la géométrie ne dépend pas de git" \
  "$(printf '%s' "$RA" | node "$AUX/ev.mjs" 'JSON.stringify(j.niveaux)' | cksum)" "$(printf '%s' "$RB" | node "$AUX/ev.mjs" 'JSON.stringify(j.niveaux)' | cksum)"
assert_eq X3 "le pied est réservé à chaque carte de fichier du lab hors dépôt (hauteur de pied non nulle, jamais absente)" "$(printf '%s' "$RA" | node "$AUX/ev.mjs" 'Object.values(j.niveaux).flat().filter((c) => c[0].startsWith("f:")).every((c) => c[5] > 0)')" "true"
assert_eq X3 "la réserve du pied est la même des deux côtés (liste des hauteurs de pied)" "$(printf '%s' "$RA" | node "$AUX/ev.mjs" 'Object.values(j.niveaux).flat().map((c) => c[5]).join(",")')" "$(printf '%s' "$RB" | node "$AUX/ev.mjs" 'Object.values(j.niveaux).flat().map((c) => c[5]).join(",")')"
assert_eq X3 "sur B, lentille « Aucune » aussi : les mêmes cartes marquées que sur A (la carte prévue seulement)" "$(printf '%s' "$RB" | node "$AUX/ev.mjs" '[j.lentille, j.marques]')" "$(printf '%s' "$RA" | node "$AUX/ev.mjs" '[j.lentille, j.marques]')"

echo "== X4 lab non VibeFlow =="
mesurer "$LABN"; RN="$MESURE"; ROUTE_N="$ROUTE"
assert_eq X4 "route : gardes non lues (le lab n'est pas un lab VibeFlow)" "$(printf '%s' "$ROUTE_N" | node "$AUX/ev.mjs" 'j.gardes.etat')" "non-lues"
assert_eq X4 "la ligne Gardes est atténuée et dit « Gardes non lues sur ce lab »" "$(printf '%s' "$RN" | node "$AUX/ev.mjs" 'j.menu.filter((r) => r.id === "gardes").map((r) => [r.desactive, r.texte.includes("Gardes non lues sur ce lab")])[0]')" "[true,true]"
assert_eq X4 "jamais « tout est sans témoin » : aucune ligne ne le dit, aucune marque n'est posée" "$(printf '%s' "$RN" | node "$AUX/ev.mjs" '[j.menu.some((r) => /sans témoin|tout est/i.test(r.texte)), j.marques.filter((id) => !/neuf\.mjs|orphelin\.mjs/.test(id)).length]')" "[false,0]"

echo "== X5 mutants : la suite doit les VOIR rouges =="
mutant_rouge() { # mutant_rouge <nom> <sed> <labo> <expression vraie quand le mutant est vu> : lab mesuré avec la copie mutée
  local nom="$1" sed_="$2" lab="$3" vu="$4" RM
  if ! cockpit_module_muter_page "$nom" "$sed_"; then echo "  ❌ FAIL — MUTANT : $nom : la mutation n'a rien changé (ancre périmée)"; FAIL=$((FAIL+1)); fin; fi
  mesurer "$lab"; RM="$MESURE"; unset COCKPIT_MODULE
  if [ "$(printf '%s' "$RM" | node "$AUX/ev.mjs" "$vu")" = "true" ]; then echo "  MUTANT-ROUGE — $nom"; else echo "  ❌ FAIL — MUTANT : $nom : le mutant n'est pas vu rouge"; FAIL=$((FAIL+1)); fin; fi
}
HAUTEURS_B="$(printf '%s' "$RB" | node "$AUX/ev.mjs" 'Object.values(j.niveaux).flat().map((c) => c[5]).join(",")')"
mutant_rouge "pied réservé conditionné à git" "s#const reserve = !\\['project', 'equipe'\\]#const reserve = G.meta?.vfGit?.etat === 'ok' \\&\\& !['project', 'equipe']#" "$LABA" \
  "Object.values(j.niveaux).flat().map((c) => c[5]).join(',') !== '$HAUTEURS_B'"
mutant_rouge "lignes Points chauds et Couplage posées sans git" "s#e === 'absent' ? 'cachee'#e === 'absent' ? 'ok'#" "$LABA" \
  "j.menu.map((r) => r.id).join(',') !== 'aucune,gardes,empreinte'"
fin
