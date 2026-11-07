#!/usr/bin/env bash
# test-cockpit-chrome-fr.sh — chrome en français, zéro anglais visible non traité (CKPT-09 ; P67-D-03, P67-D-18).
#   F1 l'inventaire du rendu servi compte au moins 200 chaînes (repère du spike 006 : 258)
#   F2 « non traduits » = inventaire − dictionnaire − gabarits − motifs − exclusions = vide (témoin : retrait d'une entrée)
#   F3 témoin du détecteur : une chaîne anglaise inventée ajoutée au rendu est listée
#   F4 chaque exclusion a une raison et son texte figure encore dans l'inventaire (témoin : une exclusion inventée)
#   F5 valeurs du dictionnaire : sans le nom amont, sans balise, ≠ de leur clé, sans `{}` en trop (témoin : valeurs fautives)
#   F6 fonction pure __vfFrTraduire testée hors navigateur (vm) : dictionnaire, gabarit, motif, chaîne vide
#   F7 les exclusions du mode plan tiennent : le graphe servi ne porte jamais meta.blueprint
#   F10 chaque gabarit du dictionnaire est servi par sa propre valeur · F11 formes rendues (corpus) sans mot anglais ni faute d'élision, de contraction, d'accord
#   F12 rendu dans Chrome (capitalisation, statut de STATE, texte visible) ; sautée audiblement sans navigateur
#   F9 l'inventaire voit les mots isolés, les mots courts et les pluriels construits (UIFN-07, 70-01) ; F3 et le témoin de F2 comparent aux non-traduits de base
# L'inventaire se calcule sur le rendu SERVI (après renommage) : les clés du dictionnaire sont les phrases affichées.
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
EXCL="$SCRIPTS/vf-cockpit-fr-exclusions.json"
WORK="$(mktemp -d)"; AUX="$WORK/aux"; mkdir -p "$AUX"
PIDS=()
trap 'type vf_hyg_fin >/dev/null 2>&1 && vf_hyg_fin; rm -rf "$WORK"' EXIT

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
// F10 (UIFN-07, P70-D-04) : chaque gabarit du dictionnaire, instancié (chaque {} -> « 2 »), doit être servi par SA valeur ; un gabarit
// capturé par un plus court (« {} and {} » avant une phrase longue) est mal servi. Forme attendue : la forme plurielle d'une valeur « sg|pl » (le compte vaut 2).
const mauvaisGabarits = Object.entries(dico).filter(([k]) => k.includes('{}')).flatMap(([k, v]) => {
  const f = v.split('|'), attendu = f[f.length > 1 ? 1 : 0].replace(/\{\}/g, '2'), obtenu = tr(k.replace(/\{\}/g, '2'));
  return (obtenu ?? '').trim() === attendu.trim() ? [] : [k];
});
// F11 (UIFN-07) : formes RENDUES (variables remplies, pluriels composés) ; chaque sortie est jugée sur des défauts de langue précis
const TEMOINS = /\b(and|of|the|at|top|up|here|calls?|steps?|show|changes|endpoints|uses|resolve|still|generated|names|again|worth|fixing|minor|inside|updated|click|recent|work)\b/i;
const FAUTES = [[/\bde (le|les)\b/i, '« de le » / « de les » non contracté'], [/\bde [aeiouyàâéèêîôû]/i, '« de » devant voyelle non élidé'], [/(^|[^\d])1 [a-zàâéèêîôû]+s\b/i, '« 1 » suivi d\'un pluriel'], [/Utilise liens|Appuyez sur Lecture/, 'valeur fautive connue'], [/mis à jour (minutes|heures|jours|secondes)/i, 'ordre des gabarits : « mis à jour » coupe l\'expression de durée'], [/^(.+) : \1$/, 'doublon « X : X »']];
const CORPUS = ['Calls · 3', 'up ·', '3 calls', '1 call', 'Show 2 changes', '1 step', 'Affects 2 places in here', '1 important · 1 worth fixing · 1 minor', '3 endpoints', 'Uses connection', 'Resolve on the map',
  'Claude Code and GSD', '3 files and endpoints still use generated names: they are named after their file, with no description. To describe them, run this command again.', 'Press Play to follow it through the code, one step at a time.',
  'It also relies on Stripe and Postgres. They sit at the edge of the map; the lines show which parts talk to them.', 'Replay this tour any time from', 'at the top.', 'the tour button (icon)', 'There is no tour for the Team tab', 'A one-minute tour of this project',
  'Answers come from the Claude Code CLI on this computer, which can read the source', 'Nothing stood out. This is a quick automatic check, not a full Anthropic review.',
  'Inside kpi-analyst', 'Updated 3 minutes ago', 'Recent work: Recent work', '2×click', 'right-click', 'click'];
const jugement = (e) => { const o = tr(e); if (o == null || o === e) return `non traduit : [${e}]`; const pb = [TEMOINS.test(o) && `mot anglais « ${(TEMOINS.exec(o) || [])[0]} »`, ...FAUTES.map(([re, nom]) => re.test(o) && nom)].filter(Boolean); return pb.length ? `[${e}] → [${o}] : ${pb.join(', ')}` : 'ok'; };
const f11 = CORPUS.map(jugement);
// recette 2026-11-04 (juge Playwright, P70-D-04) : formes exactes ; l'ordre des gabarits ne doit pas faire revenir « il y a 3 mis à jour minutes »
const suite = [tr('Updated 3 minutes ago'), tr('Inside kpi-analyst'), tr('Inside equipe-produit'), tr('Recent work: Recent work'), tr('2×click'), tr('right-click'), tr('Top of the world'), tr('click')];
// lot Langue (rcm lot 4, 2026-11-06) : formes lues par le panel — LG1 anglais résiduel, LG2 libellés reformulés
const lg = ['Readme and 7 more', 'A, B and 1 more', 'You asked: foo', 'You asked:', 'Exported Nov 5, 2026', 'Unassigned', 'Everything behind /products/:id', 'The screen itself', '9 connections.', '1 connection.', 'Calls connection', '115 files · 48k lines', '1.3k lines', '1 lines', 'Changed · Phase 61', '10 changed', '1 changed', 'Matched by', 'more', 'Back to map', 'Nothing stood out. This is a quick automatic check, not a full security review.', '10 changed inside · Phase 61', "Qu'est-ce qui bloque ?", "Qu'est-ce qui est en cours ?"].map((e) => tr(e));
console.log(JSON.stringify({ mauvaisGabarits, f11, suite, lg, svc: [code.__vfFrType('service'), code.__vfFrType('Service')], corpus: CORPUS, inventaire: inv.length, liste: inv, dict: Object.keys(dico).length, motifs: code.__vfFrTraduire.motifs, gabarits: code.__vfFrTraduire.gabarits, exclusions: excl.length,
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

echo "[F10] chaque gabarit est servi par sa propre valeur (UIFN-07, P70-D-04 : « {} and {} » ne capture plus une phrase longue)"
assert_eq "F10 : aucun gabarit du dictionnaire n'est capturé par un gabarit plus court ou mal servi (UIFN-07)" "$(lire "$WORK/m.json" 'j.mauvaisGabarits')" "[]"

echo "[F11] formes rendues : aucun mot anglais, aucune faute d'élision, de contraction ni d'accord (UIFN-07)"
NC=$(lire "$WORK/m.json" 'j.corpus.length')
assert_ge "F11.0 : le corpus des formes rendues est exécuté" "$NC" 25
for i in $(seq 0 $((NC-1))); do
  assert_eq "F11.$((i+1)) : $(lire "$WORK/m.json" "j.corpus[$i]")" "$(lire "$WORK/m.json" "j.f11[$i]")" "ok"
done

echo "[F13] recette 2026-11-04 : durée, en-tête de carte, doublon de fil d'Ariane, indications de souris (P70-D-04)"
assert_eq "F13.1 : « Updated 3 minutes ago » → la durée n'est pas coupée (« Mis à jour il y a 3 minutes »)" "$(lire "$WORK/m.json" 'j.suite[0]')" "Mis à jour il y a 3 minutes"
assert_eq "F13.2 : « Inside <nom du lab> » → « Dans <nom> », le nom du lab reste intact" "$(lire "$WORK/m.json" 'j.suite.slice(1,3)')" '["Dans kpi-analyst","Dans equipe-produit"]'
assert_eq "F13.3 : « Recent work: Recent work » (fil d'Ariane) ne dit qu'une fois « Travail récent »" "$(lire "$WORK/m.json" 'j.suite[3]')" "Travail récent"
assert_eq "F13.4 : indications de souris « 2×click », « right-click », « click » en français" "$(lire "$WORK/m.json" '[...j.suite.slice(4,6), j.suite[7]]')" '["2×clic","clic droit","clic"]'
assert_eq "F13.5 : le gabarit libre « Inside {} » n'abîme pas une autre donnée (« Top of the world » reste intacte)" "$(lire "$WORK/m.json" 'j.suite[6]')" "null"

echo "[F14] lot Langue : anglais résiduel et libellés reformulés (PU-G-060 à 064, 066, 070, 078, 055, 036, 148, 161) ; DG-14 apostrophe"
assert_eq "F14.1 : « Readme and 7 more » → « Readme et 7 autres » ; « 1 more » au singulier" "$(lire "$WORK/m.json" 'j.lg.slice(0,2)')" '["Readme et 7 autres","A, B et 1 autre"]'
assert_eq "F14.2 : une seule formule, « Demande d'origine », pour « You asked: » avec ou sans suite (PU-G-062, PU-G-063)" "$(lire "$WORK/m.json" 'j.lg.slice(2,4)')" '["Demande d'"'"'origine : foo","Demande d'"'"'origine :"]'
assert_eq "F14.3 : « Exported <date> » → « Exporté le 5 nov. 2026 » (PU-G-161)" "$(lire "$WORK/m.json" 'j.lg[4]')" "Exporté le 5 nov. 2026"
assert_eq "F14.4 : « Unassigned », « Everything behind … », « The screen itself » (PU-G-060, PU-G-078)" "$(lire "$WORK/m.json" 'j.lg.slice(5,8)')" '["Non classés","Tout ce qu'"'"'il y a derrière /products/:id","L'"'"'écran lui-même"]'
assert_eq "F14.5 : « 9 connections. » (point final), « 1 connection. », « Calls connection » (PU-G-064)" "$(lire "$WORK/m.json" 'j.lg.slice(8,11)')" '["9 liens.","1 lien.","Appels entre modules"]'
assert_eq "F14.6 : chiffres : « 48 k lignes », « 1,3 k lignes », « 1 ligne » au singulier (PU-G-066)" "$(lire "$WORK/m.json" 'j.lg.slice(11,14).map((x) => x.replace(/\u00a0/g, "_"))')" '["115 fichiers · 48_k lignes","1,3_k lignes","1 ligne"]'
assert_eq "F14.7 : « Changed » ne veut plus dire « modifié » : « Touché par : … », « 10 récents », « 1 récent » (PU-G-055)" "$(lire "$WORK/m.json" 'j.lg.slice(14,17)')" '["Touché par : Phase 61","10 récents","1 récent"]'
assert_eq "F14.8 : « Matched by » → « Détecté via » ; hint « more » → « plus d'actions » ; « Back to map » sans le mot carte (PU-G-070, PU-G-036, PU-G-148)" "$(lire "$WORK/m.json" 'j.lg.slice(17,20)')" '["Détecté via","plus d'"'"'actions","Quitter le tableau"]'
assert_eq "F14.9 : « revue de sécurité complète » ; « 10 récents à l'intérieur » (PU-G-161, PU-G-055)" "$(lire "$WORK/m.json" '[j.lg[20], j.lg[21]]')" '["Rien de saillant. C'"'"'est un contrôle automatique rapide, pas une revue de sécurité complète.","10 récents à l'"'"'intérieur · Phase 61"]'
assert_eq "F14.10 : PU-G-071 — le type « service » (module à agents, kindOf de vf-cockpit-code-vf.mjs) s'affiche « module » / « Module » ; le kind, lui, ne change pas (icône, légende)" "$(lire "$WORK/m.json" 'j.svc')" '["module","Module"]'
# DG-14 : la pastille « Qu'est-ce qui bloque ? » garde son apostrophe de bout en bout ; l'apostrophe perdue du panel venait du FAUX claude du banc (« Qu est-ce qui bloque ? » écrit sans apostrophe dans sa sortie JSON), pas du cockpit
assert_eq "DG-14.1 : la couche française n'altère pas une phrase de relance française (rend null, texte intact)" "$(lire "$WORK/m.json" 'j.lg.slice(22,24)')" "[null,null]"
assert_eq "DG-14.2 : la source des relances locales porte l'apostrophe (vf-cockpit-ask.mjs)" "$(grep -cF "Qu'est-ce qui bloque ?" "$SCRIPTS/vf-cockpit-ask.mjs")" "1"
assert_eq "DG-14.3 : le chip du viewer écrit le texte reçu tel quel (h() n'ôte pas l'apostrophe) — témoin : une entrée sans apostrophe reste sans apostrophe" "$(node -e 'const u=(s)=>s.replace(/&#39;/g,String.fromCharCode(39));console.log(u("Qu&#39;est-ce qui bloque ?")+"|"+u("Qu est-ce qui bloque ?"))')" "Qu'est-ce qui bloque ?|Qu est-ce qui bloque ?"

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

echo "[F12] rendu dans Chrome : capitalisation, statut de STATE, texte visible (UIFN-06, UIFN-07)"
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then
  echo "  ⊘ F12 SAUTÉ : aucun navigateur (Chrome, Chromium) — le rendu visible NON vérifié, non compté comme réussi"
else
  . "$SCRIPTS/tests/hygiene.sh"; vf_hyg_init
  libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
  REAL_HOME="$HOME"; mkdir -p "$WORK/home/.claude/scripts"
  printf '#!/usr/bin/env bash\ncase "$1" in status) echo %s ;; orphans) echo %s ;; esac\n' "'{\"locks\":[]}'" "'{\"orphans\":[]}'" > "$WORK/home/.claude/scripts/driver-lock.sh"
  # lab jetable GSD : STATE.md en statut brut « ready_to_execute », jalon dont le nom commence par une voyelle
  LAB12="$WORK/lab12"; mkdir -p "$LAB12/src" "$LAB12/.planning/phases/01-socle"
  printf 'export const u = () => 1;\n' > "$LAB12/src/util.js"
  printf '# Roadmap\n\n## Jalon Atelier\n\n- [ ] **Phase 1: Socle** - premier jet\n' > "$LAB12/.planning/ROADMAP.md"
  printf '<objective>Faire le socle</objective>\n' > "$LAB12/.planning/phases/01-socle/01-01-PLAN.md"
  printf -- '---\ngsd_state_version: 1.0\nmilestone: Atelier\nstatus: ready_to_execute\ncurrent_phase: 1\nlast_activity: 2026-11-04\n---\n\n# State\n' > "$LAB12/.planning/STATE.md"
  git -C "$LAB12" init -q && git -C "$LAB12" add -A && git -C "$LAB12" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB12" --quiet >/dev/null 2>&1 || echo "  assemblage du lab F12 impossible"
  O12="$LAB12/.vibeflow/cockpit"; ln -s "$SCRIPTS" "$WORK/scripts-hote"; rm -f "$O12/.cache/server.json"
  ( cd "$LAB12" && HOME="$WORK/home" VF_COCKPIT_ENGINE_DIR="$SCRIPTS/../skills/cockpit-moteur" VF_COCKPIT_SCRIPTS_DIR="$WORK/scripts-hote" exec node "$O12/serve.mjs" --no-open --port "$(libre)" > "$WORK/serve12.out" 2>&1 ) </dev/null >/dev/null 2>&1 &
  SRV12=$!; PIDS+=($SRV12)
  for _ in $(seq 1 300); do grep -q '"port"' "$O12/.cache/server.json" 2>/dev/null && break; sleep 0.1; done
  P12="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$O12/.cache/server.json','utf8')).port)" 2>/dev/null || echo 0)"
  assert_eq "F12.0 : serveur du lab jetable démarré" "$([ "$P12" -gt 0 ] && echo oui || echo non)" "oui"
  REAL_HOME="$REAL_HOME" node "$SCRIPTS/tests/chrome-fr-rendu.mjs" "$CHROME" "http://127.0.0.1:$P12/index.html" "http://127.0.0.1:$P12/project.html" > "$WORK/rendu12.json" 2>"$WORK/rendu12.err"
  [ -n "${KEEP_F12:-}" ] && cp "$WORK/rendu12.json" "$KEEP_F12"
  assert_eq "F12.0b : la mesure du rendu a eu lieu (aucune erreur nommée)" "$(lire "$WORK/rendu12.json" 'j.erreur || "aucune"')" "aucune"
  assert_eq "F12.1 : l'en-tête du panneau Santé n'a pas de majuscule au milieu (« Contrôle de santé »)" "$(lire "$WORK/rendu12.json" 'j.code.sante')" "Contrôle de santé"
  assert_eq "F12.2 : sous-titre et panneau d'ensemble de l'onglet Projet sans statut brut (mot à tiret bas, statut en capitales)" "$(lire "$WORK/rendu12.json" '[j.projet.sousTitre, j.projet.ensemble].join("\n").match(/\b[a-z]+_[a-z_]+\b|\b(READY_TO_EXECUTE|EXECUTING|PLANNING|VERIFYING|PAUSED|COMPLETED?|CLOSED)\b/g) || []')" "[]"
  assert_eq "F12.2b : témoin — le sous-titre montre bien le jalon du lab" "$(lire "$WORK/rendu12.json" '/Jalon Atelier/.test(j.projet.sousTitre)')" "true"
  TEMOINS12='\b(and|of|the|at|top|up|here|calls?|steps?|show|changes|endpoints|uses|resolve|still|generated|names|again|worth|fixing|minor)\b'
  assert_eq "F12.3a : témoin — le texte visible relevé n'est pas vide (Code et Projet, plus de 500 caractères chacun)" "$(lire "$WORK/rendu12.json" 'j.code.corps.length > 500 && j.projet.corps.length > 500')" "true"
  assert_eq "F12.3 : le texte visible des onglets Code et Projet ne contient aucun mot témoin anglais" "$(lire "$WORK/rendu12.json" "[j.code.corps, j.projet.corps].join(' ').match(new RegExp('$TEMOINS12', 'gi')) || []")" "[]"
  vf_hyg_stop "$SRV12"; vf_hyg_assert
fi

echo "[F9] recette 68 R11 (P68-D-35) : le statut STATE brut n'est jamais affiché sur la page Projet (navigateur)"
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then echo "  ⊘ F9 SAUTÉ : aucun navigateur — le statut affiché n'est PAS vérifié, non compté comme réussi"; else
L9="$WORK/lab9"; mkdir -p "$L9/.planning"; printf -- '- [ ] **Phase 1: Socle** - premier jet\n' > "$L9/.planning/ROADMAP.md"
printf -- '---\nmilestone: v1\nstatus: ready_to_plan\ncurrent_phase: 1\ncurrent_phase_name: Socle\n---\n' > "$L9/.planning/STATE.md"; git -C "$L9" init -q 2>/dev/null
node "$SCRIPTS/vf-cockpit-build.mjs" "$L9" --quiet >/dev/null 2>&1 || { echo "assemblage F9 impossible"; exit 1; }
perl -e 'alarm 300; exec @ARGV' node "$SCRIPTS/tests/chrome-statut.mjs" "$CHROME" "file://$L9/.vibeflow/cockpit/project.html" > "$WORK/f9.json" 2>/dev/null
assert_eq "F9.1 : aucun texte visible de la page Projet ne porte « ready_to_plan »" "$(lire "$WORK/f9.json" '(j.erreur||j.visibles)')" "[]"
assert_eq "F9.2 : sous-titre et pastille en français" "$(lire "$WORK/f9.json" '[j.sousTitre, j.pastille]')" '["Phase 1, 0 phase faite sur 1.","À faire"]'
# F10 : N2 (P68-D-38) — le tiroir « Au travail » dit « dépôt » (serveur réel, flux `who` simulé)
export VF_COCKPIT_PORT_BASE=$((30000 + (RANDOM * 11) % 30000))
U10="$(node "$SCRIPTS/vf-cockpit.mjs" open --no-open --lab "$L9" 2>/dev/null | sed -En 's#^Cockpit : (http://127\.0\.0\.1:[0-9]+)/ .*#\1/project.html#p' | head -1)"
perl -e 'alarm 300; exec @ARGV' node "$SCRIPTS/tests/chrome-verrou.mjs" "$CHROME" "$U10" > "$WORK/f10.json" 2>/dev/null
perl -e 'alarm 300; exec @ARGV' node "$SCRIPTS/tests/chrome-verrou-prefixe.mjs" "$CHROME" "$U10" > "$WORK/f10c.json" 2>/dev/null
node "$SCRIPTS/vf-cockpit.mjs" stop --lab "$L9" >/dev/null 2>&1; unset VF_COCKPIT_PORT_BASE
assert_eq "F10 : le verrou du dépôt s'affiche « dépôt » dans le tiroir « Au travail » (jamais « depot »)" "$(lire "$WORK/f10.json" '(j.erreur||String(j.lignes[0]).replace(/ · .*$/, ""))')" "dépôt"
# F10b : P68-D-39 — le travailleur de type verrou et l'en-tête du tiroir affichent le même âge (le `who` figé à 1 s, le flux `lock` à 57 s)
assert_eq "F10b : l'âge du verrou dans la ligne du tiroir égale celui de l'en-tête (57 s)" "$(lire "$WORK/f10.json" '(j.erreur||[/57 s/.test(j.regle), /1 min|57 s/.test(String(j.lignes[0])), /(^|[^0-9])1 s/.test(String(j.lignes[0]))].join())')" "true,true,false"
# F10c : M-3 (P68-D-39) — deux verrous d'un même propriétaire dont un compartiment est préfixe de l'autre (`fiabilite`, `fiabilite-2`) : chaque ligne garde SON âge (40 s et 10 min), correspondance exacte
assert_eq "F10c : fiabilite garde 40 s, fiabilite-2 garde 10 min (jamais l'âge du verrou voisin)" "$(lire "$WORK/f10c.json" '(j.erreur||[/fiabilite · .*40 s/.test(String(j.lignes[0])) && !/fiabilite-2/.test(String(j.lignes[0])), /fiabilite-2 · .*10 min/.test(String(j.lignes[1])) && !/40 s/.test(String(j.lignes[1]))].join())')" "true,true"
fi

echo ""
echo "  Résultats : $PASS PASS / $FAIL FAIL"
[ $((PASS + FAIL)) -gt 0 ] || { echo "ÉCHEC ANTI-VERT-À-VIDE : aucun cas exécuté"; exit 1; }
[ "$FAIL" -eq 0 ]
