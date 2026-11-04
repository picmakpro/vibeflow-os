#!/usr/bin/env bash
# test-cockpit-chrome-fr.sh — chrome en français, zéro anglais visible non traité (CKPT-09 ; P67-D-03, P67-D-18).
#   F1 l'inventaire du rendu servi compte au moins 200 chaînes (repère du spike 006 : 258)
#   F2 « non traduits » = inventaire − dictionnaire − gabarits − motifs − exclusions = vide (témoin : retrait d'une entrée)
#   F3 témoin du détecteur : une chaîne anglaise inventée ajoutée au rendu est listée
#   F4 chaque exclusion a une raison et son texte figure encore dans l'inventaire (témoin : une exclusion inventée)
#   F5 valeurs du dictionnaire : sans le nom amont, sans balise, ≠ de leur clé, sans `{}` en trop (témoin : valeurs fautives)
#   F6 fonction pure __vfFrTraduire testée hors navigateur (vm) : dictionnaire, gabarit, motif, chaîne vide
#   F7 les exclusions du mode plan tiennent : le graphe servi ne porte jamais meta.blueprint
#   F9 l'inventaire voit les mots isolés, les mots courts et les pluriels construits (UIFN-07, 70-01) ; F3 et le témoin de F2 comparent aux non-traduits de base
# L'inventaire se calcule sur le rendu SERVI (après renommage) : les clés du dictionnaire sont les phrases affichées.
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
EXCL="$SCRIPTS/vf-cockpit-fr-exclusions.json"
WORK="$(mktemp -d)"; AUX="$WORK/aux"; mkdir -p "$AUX"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_ge() { if [ "$2" -ge "$3" ] 2>/dev/null; then echo "  ✅ PASS — $1 ($2)"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 ($2 < $3)"; FAIL=$((FAIL+1)); fi; }
AMONT="floor""plan"

# calcul.mjs <sortie> <scriptsDir> <exclusions.json> [<dico-fautif.json>] : imprime un JSON de mesures
cat > "$AUX/calcul.mjs" <<'JS'
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { pathToFileURL } from 'node:url';
const [, , sortie, scriptsDir, exclFile, fautif] = process.argv;
const { inventaireDeSortie } = await import(pathToFileURL(path.join(scriptsDir, 'vf-cockpit-fr-inventaire.mjs')).href);
const inv = inventaireDeSortie(sortie);
const page = fs.readFileSync(path.join(sortie, 'project.html'), 'utf8');
const blocs = [...page.matchAll(/<script>(?:\/\* ui\/[\w.-]+ \*\/\s*)?\/\/ vibeflow:fr[\s\S]*?<\/script>/g)].map((m) => m[0].replace(/^<script>|<\/script>$/g, ''));
function contexte(tab) { // talons minimaux : fenêtre, document, observateur, requestAnimationFrame, location
  const noop = () => {};
  const el = () => ({ style: {}, textContent: '', appendChild: noop, setAttribute: noop, getAttribute: () => null, querySelectorAll: () => [], closest: () => null });
  const ctx = { console, URLSearchParams, location: { search: '' }, performance: { now: () => 0 }, NodeFilter: { SHOW_TEXT: 4 }, requestAnimationFrame: noop,
    MutationObserver: class { observe() {} }, document: { documentElement: {}, head: el(), body: el(), title: '', createElement: el, querySelector: () => el(), createTreeWalker: () => ({ nextNode: () => null }) } };
  ctx.window = ctx; ctx.VibeFlow = { graph: { meta: { vfTab: tab, kindColors: {} } } };
  vm.createContext(ctx);
  for (const b of blocs) vm.runInContext(b, ctx);
  return ctx;
}
const code = contexte('code'), proj = contexte('project');
const tr = (s) => code.__vfFrTraduire(s) || proj.__vfFrTraduire(s) || null;
const sonde = (s) => s.replace(/\{\}/g, '7'); // une variable de gabarit prend une valeur quelconque
const excl = JSON.parse(fs.readFileSync(exclFile, 'utf8')).exclusions;
const nonTraduits = inv.filter((s) => !tr(sonde(s)) && !excl.some((e) => e.texte === s));
const sansObjet = excl.filter((e) => !String(e.raison || '').trim() || !inv.includes(e.texte)).map((e) => e.texte);
const AMONT = new RegExp('floor' + 'plan', 'i');
const IDENTIQUES = []; // termes écrits pareil dans les deux langues autorisés comme valeur du dictionnaire : aucun, ils vont en exclusion
const nb = (s) => (s.match(/\{\}/g) || []).length;
const ajoute = (k, v) => v.split('|').some((f) => nb(f) > nb(k)); // une valeur peut omettre des {}, jamais en ajouter
const controler = (d) => Object.entries(d).flatMap(([k, v]) => [AMONT.test(v) && `nom amont : ${k}`, /</.test(v) && `balise : ${k}`, v === k && !IDENTIQUES.includes(k) && `valeur = clé : ${k}`, ajoute(k, v) && `{} en trop dans la valeur : ${k}`].filter(Boolean));
const dico = code.__vfFrDict;
const fautive = fautif ? controler(JSON.parse(fs.readFileSync(fautif, 'utf8'))) : [];
console.log(JSON.stringify({ inventaire: inv.length, liste: inv, dict: Object.keys(dico).length, motifs: code.__vfFrTraduire.motifs, gabarits: code.__vfFrTraduire.gabarits, exclusions: excl.length,
  nonTraduits, sansObjet, problemesDico: controler(dico), problemesTemoin: fautive,
  f6: { etapes: [tr('Previous step'), tr('Next step')], motif: tr('Answer · 3 cards'), exact: tr('Fit to screen'), gabarit: tr('Your Claude session expired. Sign in again.'), vide: tr(''), espaces: tr('   '), inconnu: tr('Ma phrase de données'), projet: proj.__vfFrTraduire('File'), code: code.__vfFrTraduire('File'), pluriels: [proj.__vfFrTraduire('files'), code.__vfFrTraduire('files')], donnees: [tr('Top of the world'), tr('Fix with Claude Code'), tr('3 of 4'), tr('Health check: nothing urgent')],
    types: typeof code.__vfFrType === 'function' ? [code.__vfFrType('library'), code.__vfFrType('Library'), code.__vfFrType('Ma donnée'), code.__vfFrType('config'), tr('library')] : 'absent' }}));
JS
cat > "$AUX/lire.mjs" <<'JS'
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const v = new Function('j', 'return (' + process.argv[3] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/blueprint.mjs" <<'JS'
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const { extraireGraphe } = await import(pathToFileURL(path.join(process.argv[2], 'vf-cockpit-embed.mjs')).href);
for (const f of ['index.html', 'project.html']) console.log(f, Object.prototype.hasOwnProperty.call(extraireGraphe(fs.readFileSync(path.join(process.argv[2], f), 'utf8')).meta, 'blueprint') ? 'blueprint' : 'sans');
JS
lire() { node "$AUX/lire.mjs" "$1" "$2"; }
# nouveaux <mesure.json> : les non-traduits de la copie témoin qui n'étaient pas déjà ceux du rendu de base ($WORK/m.json) ;
# F3 et le témoin de F2 prouvent le DÉTECTEUR, ils ne doivent pas rougir quand F2 rougit sur autre chose (70-01)
cat > "$AUX/nouveaux.mjs" <<'JS'
import fs from 'node:fs';
const lire = (f) => JSON.parse(fs.readFileSync(f, 'utf8')).nonTraduits;
const base = new Set(lire(process.argv[2]));
console.log(JSON.stringify(lire(process.argv[3]).filter((x) => !base.has(x))));
JS
nouveaux() { node "$AUX/nouveaux.mjs" "$WORK/m.json" "$1"; }

# lab neutre, assemblé
LAB="$WORK/lab"; mkdir -p "$LAB/src" "$LAB/.planning/phases/01-x"
printf 'import { u } from "./util.js";\nconsole.log(u());\n' > "$LAB/src/app.js"; printf 'export const u = () => 1;\n' > "$LAB/src/util.js"
printf -- '- [x] **Phase 1: Socle** - premier jet\n' > "$LAB/.planning/ROADMAP.md"
printf '<objective>Faire le socle</objective>\n' > "$LAB/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$LAB/.planning/phases/01-x/01-01-SUMMARY.md"
git -C "$LAB" init -q 2>/dev/null
SORTIE="$LAB/.vibeflow/cockpit"
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet >/dev/null 2>&1 || { echo "assemblage impossible"; exit 1; }

echo "[F1/F2/F4/F5/F6] mesures sur le rendu servi"
node "$AUX/calcul.mjs" "$SORTIE" "$SCRIPTS" "$EXCL" > "$WORK/m.json" 2> "$WORK/m.err" || { echo "calcul impossible : $(tail -2 "$WORK/m.err")"; exit 1; }
N=$(lire "$WORK/m.json" 'j.inventaire')
assert_ge "F1 : chaînes d'interface anglaises inventoriées sur le rendu servi" "$N" 200
echo "     dictionnaire $(lire "$WORK/m.json" 'j.dict') entrées · $(lire "$WORK/m.json" 'j.gabarits') gabarits · $(lire "$WORK/m.json" 'j.motifs') motifs · $(lire "$WORK/m.json" 'j.exclusions') exclusions"
assert_eq "F2 : non traduits = vide ($N chaînes, $(lire "$WORK/m.json" 'j.exclusions') exclusions)" "$(lire "$WORK/m.json" 'j.nonTraduits')" "[]"
assert_eq "F4 : chaque exclusion a une raison et son texte figure dans l'inventaire" "$(lire "$WORK/m.json" 'j.sansObjet')" "[]"
assert_eq "F5 : valeurs du dictionnaire sans nom amont, sans balise, ≠ clé, sans {} en trop" "$(lire "$WORK/m.json" 'j.problemesDico')" "[]"
# le rendu est renommé à l'assemblage : le nom amont d'une valeur y disparaîtrait ; on le cherche donc aussi dans les SOURCES du dictionnaire
UI="$SCRIPTS/../skills/cockpit-moteur/assets/ui"
assert_eq "F5.2 : sources 78 et 79 du dictionnaire sans le nom amont (insensible à la casse)" "$(cat "$UI"/78-vf-fr-dict-a.js "$UI"/79-vf-fr-dict-b.js | grep -ci "$AMONT")" "0"
assert_eq "F5.3 : témoin — le compte voit bien un nom amont dans un texte jetable" "$(printf '"a": "Le %s de a"\n' "$AMONT" | grep -ci "$AMONT")" "1"
assert_eq "F6.1 : motif « Answer · 3 cards »" "$(lire "$WORK/m.json" 'j.f6.motif')" "Réponse · 3 cartes"
assert_eq "F6.2 : entrée exacte du dictionnaire" "$(lire "$WORK/m.json" 'j.f6.exact')" "Ajuster à l'écran"
assert_eq "F6.3 : gabarit à variable (texte fixe long)" "$(lire "$WORK/m.json" 'j.f6.gabarit')" "Votre session Claude a expiré. Reconnectez-vous."
assert_eq "F6.4 : chaîne vide → rien (garde contre la boucle des attributs vides)" "$(lire "$WORK/m.json" '[j.f6.vide, j.f6.espaces]')" "[null,null]"
assert_eq "F6.5 : une phrase inconnue (donnée du lab) reste intacte" "$(lire "$WORK/m.json" 'j.f6.inconnu')" "null"
assert_eq "F6.6 : « File » → Élément sur l'onglet Projet, Fichier sur l'onglet Code" "$(lire "$WORK/m.json" '[j.f6.projet, j.f6.code]')" '["Élément","Fichier"]'

assert_eq "F6.7 : pluriel composé à l'exécution (« files » → éléments sur Projet, fichiers sur Code)" "$(lire "$WORK/m.json" 'j.f6.pluriels')" '["éléments","fichiers"]'
assert_eq "F6.8 : un gabarit court n'abîme pas une donnée (« Top of the world » reste intacte)" "$(lire "$WORK/m.json" 'j.f6.donnees[0]')" "null"
assert_eq "F6.9 : le même gabarit s'applique si une variable se traduit ou est un nombre" "$(lire "$WORK/m.json" 'j.f6.donnees.slice(1)')" "[\"Corriger avec Claude Code\",\"3 sur 4\",\"Contrôle de santé : rien d'urgent\"]"
assert_eq "F6.10 : types fixes de carte (recette 2026-11-02, « Library ») : traduits par emplacement, capitale conservée, donnée inconnue intacte, JAMAIS par le dictionnaire (un dossier « library » reste « library »)" "$(lire "$WORK/m.json" 'j.f6.types')" '["bibliothèque","Bibliothèque",null,"configuration",null]'
assert_eq "F6.11 : O6 (recette 3, arbitrage Samuel, AskUserQuestion session principale, 2026-11-03) — les chevrons de la Trajectoire (« Previous step », « Next step ») sont traduits en « Étape précédente » et « Étape suivante »" "$(lire "$WORK/m.json" 'j.f6.etapes')" '["Étape précédente","Étape suivante"]'

echo "[F9] l'inventaire voit les formes d'anglais résiduel du cadrage (UIFN-07, P70-D-04)"
assert_eq "F9.1 : mot isolé — le libellé de type « Calls » (UIFN-07)" "$(lire "$WORK/m.json" "j.liste.includes('Calls')")" "true"
assert_eq "F9.2 : mots de sévérité de Santé — « important », « minor », « worth fixing » (UIFN-07)" "$(lire "$WORK/m.json" "['important', 'minor', 'worth fixing'].map((x) => j.liste.includes(x))")" "[true,true,true]"
assert_eq "F9.3 : mot court — l'aide au clavier « ⌫ up » rend le nœud « up · » (UIFN-07)" "$(lire "$WORK/m.json" "j.liste.includes('up ·')")" "true"
assert_eq "F9.4 : pluriel construit à l'exécution par plural(n, mot) — « {} calls », « {} steps », « {} changes » (UIFN-07)" "$(lire "$WORK/m.json" "['{} calls', '{} steps', '{} changes'].map((x) => j.liste.includes(x))")" "[true,true,true]"

echo "[F3] témoin du détecteur : une chaîne anglaise inventée"
T3="$WORK/t3"; cp -R "$SORTIE" "$T3"
node -e 'const f=process.argv[1],fs=require("fs");let h=fs.readFileSync(f,"utf8");h=h.replace("</body>","<script>const m = \"Pending approval from the review board\";</script></body>");fs.writeFileSync(f,h)' "$T3/project.html"
node "$AUX/calcul.mjs" "$T3" "$SCRIPTS" "$EXCL" > "$WORK/m3.json" 2>/dev/null
assert_eq "F3 : la chaîne ajoutée est listée parmi les non-traduits" "$(nouveaux "$WORK/m3.json")" '["Pending approval from the review board"]'

echo "[F2 témoin] retrait d'une entrée du dictionnaire"
T2="$WORK/t2"; cp -R "$SORTIE" "$T2"
node -e 'const f=process.argv[1],fs=require("fs");let h=fs.readFileSync(f,"utf8");const n=h.split("\n").filter((l)=>!l.startsWith("  \"Copy endpoint\":")).join("\n");if(n===h)process.exit(3);fs.writeFileSync(f,n)' "$T2/project.html"; RC=$?
assert_eq "F2 témoin : la ligne du dictionnaire a bien été retirée de la copie" "$RC" "0"
node "$AUX/calcul.mjs" "$T2" "$SCRIPTS" "$EXCL" > "$WORK/m2.json" 2>/dev/null
assert_eq "F2 témoin : F2 rougit en nommant l'entrée retirée" "$(nouveaux "$WORK/m2.json")" '["Copy endpoint"]'

echo "[F4 témoin] exclusion inventée ; [F5 témoin] valeurs fautives"
node -e 'const fs=require("fs");const e=JSON.parse(fs.readFileSync(process.argv[1]));e.exclusions.push({texte:"Une chaîne qui n existe pas dans le rendu",raison:"inventée"},{texte:"Download",raison:""});fs.writeFileSync(process.argv[2],JSON.stringify(e))' "$EXCL" "$WORK/excl-fautive.json"
printf '{"Hello there":"Bonjour %s","Other thing":"<b>Autre</b>","Same":"Same","One {}":"Un {} et {}"}' "$AMONT" > "$WORK/dico-fautif.json"
node "$AUX/calcul.mjs" "$SORTIE" "$SCRIPTS" "$WORK/excl-fautive.json" "$WORK/dico-fautif.json" > "$WORK/m4.json" 2>/dev/null
assert_eq "F4 témoin : une exclusion sans objet et une exclusion sans raison sont signalées" "$(lire "$WORK/m4.json" 'j.sansObjet')" '["Une chaîne qui n existe pas dans le rendu","Download"]'
assert_eq "F5 témoin : nom amont, balise, valeur = clé, {} en trop : 4 problèmes" "$(lire "$WORK/m4.json" 'j.problemesTemoin.length')" "4"

echo "[F7] mode plan inatteignable"
assert_eq "F7 : aucun graphe servi (Code, Projet) ne porte meta.blueprint" "$(node "$AUX/blueprint.mjs" "$SORTIE" | tr '\n' ' ')" "index.html sans project.html sans "

echo "[F8] hors du rendu : l'outil d'inventaire n'est pas recopié dans le lab, le dictionnaire ne porte pas le nom amont"
assert_eq "F8.1 : <sortie>/vf-cockpit-fr-inventaire.mjs absent" "$([ -e "$SORTIE/vf-cockpit-fr-inventaire.mjs" ] && echo present || echo absent)" "absent"
assert_eq "F8.2 : témoin — l'outil existe bien dans les scripts du module" "$([ -f "$SCRIPTS/vf-cockpit-fr-inventaire.mjs" ] && echo existe || echo absent)" "existe"
assert_eq "F8.3 : le rendu servi ne contient pas le nom amont (hors lignes de licence)" "$(grep -v 'vibeflow:licence-tierce' "$SORTIE/project.html" | grep -ci "$AMONT")" "0"

echo ""
echo "  Résultats : $PASS PASS / $FAIL FAIL"
[ $((PASS + FAIL)) -gt 0 ] || { echo "ÉCHEC ANTI-VERT-À-VIDE : aucun cas exécuté"; exit 1; }
[ "$FAIL" -eq 0 ]
