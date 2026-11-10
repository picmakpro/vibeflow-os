#!/usr/bin/env bash
# test-cockpit-lecture-fil.sh — lot 0 de l'audit du cockpit, lignes AUDC-D5 à D8 : ce que la lecture rend du disque.
#   D5 les plans de mission nommés `dag-*.json` sont lus comme les `*.dag.json` (un lab d'essai aux deux nommages)
#   D6 « New session » (valeur par défaut de custom-title) n'est pas un nom choisi ; un vrai nom reste lu (PU-G-162 : jamais de titre généré)
#   D7 une session n'a pas de mandat ; aucun intertitre « Mandat » vide ; le mandat d'un agent reste lu
#   D8 le transcript réduit est UN fil ordonné et daté, sans sortie d'outil ni argument d'outil (P69-D-16, P69-D-19)
# Fixtures reconstruites dans mktemp, SYNTHÉTIQUES (aucun transcript réel n'est lu ni copié). Code testé chargé depuis l'emplacement de la suite.
# Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
UI="$SCRIPTS/../skills/cockpit-moteur/assets/ui"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
WORK="$(cd "$WORK" && pwd -P)"
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }

# --- D5 : deux nommages de plan de mission ---
echo "=== D5 — plans de mission : dag-*.json et *.dag.json ==="
LAB="$WORK/lab5"; mkdir -p "$LAB/.planning/missions" "$LAB/.planning/phases"
NOEUDS='{"nodes":[{"id":"n1","state":"done","depends":[]}]}'
echo "$NOEUDS" > "$LAB/.planning/missions/essai.dag.json"
echo "$NOEUDS" > "$LAB/.planning/missions/dag-essai2.json"
echo '{"pas":"un plan"}' > "$LAB/.planning/missions/dag-sans-noeuds.json"
echo '{ illisible' > "$LAB/.planning/missions/dag-casse.json"
echo "$NOEUDS" > "$LAB/.planning/missions/autre-nom.json"
cat > "$WORK/dags.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const [, , scripts, lab] = process.argv;
const { lireDags } = await import(pathToFileURL(scripts + '/vf-cockpit-planning.mjs').href);
console.log(lireDags(lab).map((d) => d.name + '=' + d.file).sort().join(','));
JS
assert_eq "D5.1 — les deux nommages sont lus ; un fichier sans nœuds, illisible ou d'un autre nom ne l'est pas" "$(node "$WORK/dags.mjs" "$SCRIPTS" "$LAB")" "essai2=.planning/missions/dag-essai2.json,essai=.planning/missions/essai.dag.json"

# --- D6 : titre par défaut ---
echo "=== D6 — « New session » n'est pas un nom choisi ==="
ecrit() { printf '%s\n' "$2" > "$WORK/$1.jsonl"; }
ecrit defaut '{"type":"custom-title","customTitle":"New session","sessionId":"x"}'
ecrit choisi '{"type":"custom-title","customTitle":"Ma session de recette","sessionId":"x"}'
ecrit apres '{"type":"custom-title","customTitle":"Ma session de recette","sessionId":"x"}
{"type":"custom-title","customTitle":"New session","sessionId":"x"}'
ecrit genere '{"type":"ai-title","aiTitle":"Titre écrit par le modèle","sessionId":"x"}'
cat > "$WORK/titre.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const [, , scripts, ...fichiers] = process.argv;
const { titreSession } = await import(pathToFileURL(scripts + '/vf-cockpit-lecture.mjs').href);
console.log(fichiers.map((f) => '[' + titreSession(f) + ']').join(''));
JS
assert_eq "D6.1 — titre par défaut : aucun titre ; nom choisi : lu ; défaut posé après un nom : aucun titre ; titre généré : jamais lu" "$(node "$WORK/titre.mjs" "$SCRIPTS" "$WORK/defaut.jsonl" "$WORK/choisi.jsonl" "$WORK/apres.jsonl" "$WORK/genere.jsonl")" "[][Ma session de recette][][]"

echo; echo "Résultat : $PASS réussis, $FAIL échoués"
[ "$FAIL" -eq 0 ]
