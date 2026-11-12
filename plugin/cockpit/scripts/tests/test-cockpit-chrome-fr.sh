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
#   F16 toute clé passée à t() a une entrée de table ou une exclusion (la liste nomme celles qui manquent) · F17 zéro littéral anglais libre, aucune clé non littérale, aucun t qui masque · F18 les blocs vibeflow:fr précèdent le script principal
#   F19 la mécanique de t hors navigateur (table d'essai puis vraie table) · F20 aucun observateur global, une donnée posée hors des anciens sélecteurs reste intacte · F21 sondes en français et sous ?lang=en · F22 parité avec le relevé « avant » (VF_FR_AVANT, VF_FR_ADMIS ; VF_FR_RELEVE écrit le relevé)
#   F23 (A43) un constat de Santé de fixture s'affiche comme avant (VF_FR_F23_MUTANT=retrait|affichage rejoue la sonde sur une copie mutée)
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
  ctx.window = ctx; ctx.VibeFlow = { graph: { meta: { vfTab: tab, kindColors: {} } } }; ctx.VF_COCKPIT = { meta: { vfTab: tab, kindColors: {} } }; // 79-10 : la donnée de la page, sous son nom d'assemblage (le traducteur la lit, jamais l'objet du moteur)
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
const balises = (x) => (x.match(/<\/?[a-z][^>]*>/gi) || []).join(''); // 79-10 (F5 relâchée) : une valeur porte les MÊMES balises que sa clé, jamais d'autres ; ni « " », ni « < », ni « > » hors de celles-là
const controler = (d) => Object.entries(d).flatMap(([k, v]) => [AMONT.test(v) && `nom amont : ${k}`, (balises(v) !== balises(k) || /["<>]/.test(v.replace(/<\/?[a-z][^>]*>/gi, ''))) && `balise : ${k}`, v === k && !IDENTIQUES.includes(k) && `valeur = clé : ${k}`, ajoute(k, v) && `{} en trop dans la valeur : ${k}`].filter(Boolean));
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
const { extraireGraphe } = await import(pathToFileURL(path.join(process.env.VF_BP_SCRIPTS, 'vf-cockpit-embed.mjs')).href);
for (const f of ['index.html', 'project.html']) console.log(f, Object.prototype.hasOwnProperty.call(extraireGraphe(fs.readFileSync(path.join(process.argv[2], f), 'utf8')).meta, 'blueprint') ? 'blueprint' : 'sans');
JS
export VF_BP_SCRIPTS="$SCRIPTS"   # 79-06 : blueprint.mjs importe l'embarquement du module, la sortie ne porte que des données (index.html, project.html)
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
assert_eq "F9.2 : mots de sévérité de Santé — « {} important », « {} minor », « {} worth fixing » (UIFN-07 ; clés de t depuis 79-10, le compte y entre en variable)" "$(lire "$WORK/m.json" "['{} important', '{} minor', '{} worth fixing'].map((x) => j.liste.includes(x))")" "[true,true,true]"
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

echo "[F15] recette 2026-11-08 : les phrases que la bibliothèque du terminal dit d'elle-même sont posées en français (« Terminal input », annoncé à chaque entrée dans le terminal)"
XTERM="$SCRIPTS/../skills/cockpit-moteur/assets/vendor/xterm/xterm.js"; CLIENT="$SCRIPTS/vf-cockpit-terminal-client.mjs"
cat > "$AUX/biblio.mjs" <<'JS'
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scriptsDir, xtermF, clientF, mode] = process.argv;
const { chainesBibliotheque, bibliothequeNonTraitee } = await import(pathToFileURL(path.join(scriptsDir, 'vf-cockpit-fr-inventaire.mjs')).href);
const x = fs.readFileSync(xtermF, 'utf8'), c = fs.readFileSync(clientF, 'utf8');
if (mode === 'defauts') console.log(JSON.stringify(Object.keys(chainesBibliotheque(x)).sort()));
else if (mode === 'reel') console.log(JSON.stringify(bibliothequeNonTraitee(x, c)));
else if (mode === 'sans') console.log(JSON.stringify(bibliothequeNonTraitee(x, c.replace(/^.*Terminal\.strings\..*$/gm, ''))));
else if (mode === 'anglais') console.log(JSON.stringify(bibliothequeNonTraitee(x, c.replace("'Saisie du terminal'", "'Terminal input'"))));
else if (mode === 'autre-langue') console.log(JSON.stringify(bibliothequeNonTraitee(x, c.replace("'Saisie du terminal'", "'Keyboard entry field'"))));
JS
assert_eq "F15.1 : l'inventaire voit les deux phrases d'interface du bundle xterm (nom du champ de saisie, sortie trop abondante)" "$(node "$AUX/biblio.mjs" "$SCRIPTS" "$XTERM" "$CLIENT" defauts)" '["promptLabel","tooMuchOutput"]'
assert_eq "F15.2 : le client du terminal les pose toutes en français (aucune clé non traitée)" "$(node "$AUX/biblio.mjs" "$SCRIPTS" "$XTERM" "$CLIENT" reel)" '[]'
assert_eq "F15.3 témoin : sans surcharge, les deux sont signalées" "$(node "$AUX/biblio.mjs" "$SCRIPTS" "$XTERM" "$CLIENT" sans)" '["promptLabel","tooMuchOutput"]'
assert_eq "F15.4 témoin : la valeur d'origine « Terminal input » reposée à l'identique est signalée" "$(node "$AUX/biblio.mjs" "$SCRIPTS" "$XTERM" "$CLIENT" anglais)" '["promptLabel"]'
assert_eq "F15.5 témoin : une autre valeur anglaise est signalée aussi" "$(node "$AUX/biblio.mjs" "$SCRIPTS" "$XTERM" "$CLIENT" autre-langue)" '["promptLabel"]'
assert_eq "F15.6 : le libellé français du champ de saisie est posé tel quel dans le client" "$(grep -cF "Terminal.strings.promptLabel = 'Saisie du terminal'" "$CLIENT")" "1"

echo "[F16 à F19] traduction au point d'émission : clés de t, sites libres, ordre de chargement, mécanique de t (79-10, SOCL-14, P79-D-16, P79-D-24)"
cat > "$AUX/sites.mjs" <<'JS'
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { pathToFileURL } from 'node:url';
const [, , pagesCsv, scriptsDir, exclFile] = process.argv;
const inv = await import(pathToFileURL(path.join(scriptsDir, 'vf-cockpit-fr-inventaire.mjs')).href);
if (typeof inv.inventaireSites !== 'function') { console.log(JSON.stringify({ fn: 'absent' })); process.exit(0); }
const pages = pagesCsv.split(',').map((f) => fs.readFileSync(f, 'utf8'));
const serveur = fs.readFileSync(path.join(scriptsDir, '..', 'skills', 'cockpit-moteur', 'assets', 'serve.mjs'), 'utf8');
const r = inv.inventaireSites({ html: pages, serveur });
const noop = () => {}; const el = () => ({ style: {}, textContent: '', appendChild: noop, setAttribute: noop, getAttribute: () => null, querySelectorAll: () => [], closest: () => null });
const ctx = { console, URLSearchParams, location: { search: '' }, performance: { now: () => 0 }, NodeFilter: { SHOW_TEXT: 4 }, requestAnimationFrame: noop, MutationObserver: class { observe() {} }, document: { documentElement: {}, head: el(), body: el(), title: '', createElement: el, querySelector: () => el(), createTreeWalker: () => ({ nextNode: () => null }) } };
ctx.window = ctx; ctx.VF_COCKPIT = { meta: { vfTab: 'code', kindColors: {} } }; vm.createContext(ctx);
for (const b of [...pages[0].matchAll(/<script>(?:\/\* ui\/[\w.-]+ \*\/\s*)?\/\/ vibeflow:fr[\s\S]*?<\/script>/g)].map((m) => m[0].replace(/^<script>|<\/script>$/g, ''))) vm.runInContext(b, ctx);
const dico = ctx.__vfFrDict || {}; const excl = new Set(JSON.parse(fs.readFileSync(exclFile, 'utf8')).exclusions.map((e) => e.texte));
const sans = (x) => !Object.prototype.hasOwnProperty.call(dico, x) && !excl.has(x.split('@')[0]) && !excl.has(x);
console.log(JSON.stringify({ fn: 'ok', n: r.cles.length, sansEntree: [...new Set([...r.cles, ...r.squelette])].filter(sans).sort(), libres: r.libres.filter((x) => !excl.has(x)).sort(), nonLitterales: r.nonLitterales, ombres: r.ombres }));
JS
cat > "$AUX/ordre.mjs" <<'JS'
import fs from 'node:fs';
const h = fs.readFileSync(process.argv[2], 'utf8');
const rang = (re) => { const m = re.exec(h); return m ? m.index : -1; };
const fr = [...h.matchAll(/<script>(?:\/\* ui\/[\w.-]+ \*\/\s*)?\/\/ vibeflow:fr/g)].map((m) => m.index);
const principal = rang(/window\.VibeFlow = Object\.freeze\(/), ui00 = rang(/<script>\/\* ui\/00-vibeflow\.js \*\//);
console.log(JSON.stringify({ blocs: fr.length, avantPrincipal: fr.length > 0 && principal > 0 && fr.every((i) => i < principal), avant00: fr.length > 0 && ui00 > 0 && fr.every((i) => i < ui00), marqueurRestant: /__UI_I18N__/.test(h) }));
JS
cat > "$AUX/t19.mjs" <<'JS'
import fs from 'node:fs';
import vm from 'node:vm';
const [, , page, mode] = process.argv; // mode : essai (table d'essai posée par la suite, bloc 80 seul) | reelle (les trois blocs, table de production)
const html = fs.readFileSync(page, 'utf8');
const blocs = [...html.matchAll(/<script>(?:\/\* ui\/[\w.-]+ \*\/\s*)?\/\/ vibeflow:fr[\s\S]*?<\/script>/g)].map((m) => m[0].replace(/^<script>|<\/script>$/g, ''));
const moteur = blocs.find((b) => /__vfFrTraduire\s*=/.test(b));
const ESSAI = { Hello: 'Bonjour', '{} call': '{} appel|{} appels', 'Nothing stood out. This is a quick automatic check, not a full {} review.': "Rien de saillant. C'est un contrôle automatique rapide, pas une revue complète de {}.", Changed: 'Touché', 'Changed@pastille': 'Récent', lines: 'lignes' };
function monde(tab, anglais, essai) {
  const noop = () => {}; const el = () => ({ style: {}, textContent: '', appendChild: noop, setAttribute: noop, getAttribute: () => null, querySelectorAll: () => [], closest: () => null });
  const ctx = { console, URLSearchParams, location: { search: anglais ? '?lang=en' : '' }, performance: { now: () => 0 }, NodeFilter: { SHOW_TEXT: 4 }, requestAnimationFrame: noop, MutationObserver: class { observe() {} }, document: { documentElement: {}, head: el(), body: el(), title: '', createElement: el, querySelector: () => el(), createTreeWalker: () => ({ nextNode: () => null }) } };
  ctx.window = ctx; ctx.VF_COCKPIT = { meta: { vfTab: tab, kindColors: {} } }; vm.createContext(ctx);
  if (essai) { ctx.__vfFrDict = { ...ESSAI }; vm.runInContext(moteur, ctx); } else for (const b of blocs) vm.runInContext(b, ctx);
  return ctx;
}
const sur = (f) => { try { return f(); } catch (e) { return 'erreur:' + String(e.message).slice(0, 80); } };
const T = (c) => (typeof c.__vfFrT === 'function' ? c.__vfFrT : null);
const out = {};
if (mode === 'essai') {
  const fr = monde('code', false, true), en = monde('code', true, true), t = T(fr), e = T(en);
  const A = "Nothing stood out. This is a quick automatic check, not a full {} review.";
  out.fonction = typeof fr.__vfFrT;
  out.cle = t ? sur(() => t('Hello')) : 'absent';
  out.formes = t ? sur(() => [t('{} call', 1), t('{} call', 3)]) : 'absent';
  out.liaison = t ? sur(() => [t(A, 'Anthropic'), t(A, 'le CLI')]) : 'absent';
  out.contexte = t ? sur(() => [t('Changed@pastille'), t('Changed@autre')]) : 'absent';
  out.pluriels = t ? sur(() => [t.pl(1, 'call'), t.pl(3, 'call'), t.mot(1, 'lines'), t.mot(3, 'lines')]) : 'absent';
  out.k = t ? sur(() => t.k('1.3k')) : 'absent';
  out.type = t ? sur(() => [t.type('Library'), t.type('Ma donnée')]) : 'absent';
  out.constat = t ? sur(() => [t.constat('Readme and 7 more'), t.constat('Une phrase que personne ne connaît')]) : 'absent';
  out.absente = t ? sur(() => t('Un {} inconnu', 'x')) : 'absent';
  out.anglais = e ? sur(() => [e('Hello'), e('{} call', 3), e('Changed@pastille'), e.pl(3, 'call'), e.pl(1, 'call'), e.mot(1, 'lines'), e.k('1.3k'), e.constat('Readme and 7 more'), e.type('Library'), typeof e.langue, e('Un {} inconnu', 'x')]) : 'absent';
} else {
  const code = monde('code', false, false), proj = monde('project', false, false), t = T(code), tp = T(proj);
  out.reelle = t ? sur(() => [t('Fit to screen'), t('File'), tp('File'), t('Ma phrase de données'), code.__vfFrTraduire('Ma phrase de données'), t.constat('src.js contains util.js')]) : 'absent';
}
console.log(JSON.stringify(out));
JS
cat > "$AUX/fixture-sante.mjs" <<'JS'
import fs from 'node:fs';
const [, , src, dst] = process.argv; const html = fs.readFileSync(src, 'utf8'); const D = '<script>window.VF_COCKPIT = ';
const a = html.indexOf(D), b = html.indexOf(';</script>', a); const g = JSON.parse(html.slice(a + D.length, b));
// un constat dont le détail est une phrase que la reconnaissance actuelle change (« X contains … »), un titre qu'elle laisse intact, six localisations (la liste en coupe trois), puis un constat de contrôle ; données jetables
g.health = { summary: { high: 1, medium: 1, low: 0 }, services: [], issues: [
  { id: 'fixture:1', kind: 'fixture', severity: 'high', title: 'Anyone could change data through util.js', detail: 'src.js contains util.js', items: ['f:src/util.js'], notes: {}, fix: 'Security fix: ne rien afficher.',
    locations: [{ file: 'src/a.js', line: 3 }, { file: 'src/b.js', line: 1 }, { file: 'src/c.js', line: 9 }, { file: 'src/d.js', line: 2 }, { file: 'src/e.js', line: 5 }, { file: 'src/f.js', line: 7 }] },
  { id: 'fixture:2', kind: 'fixture', severity: 'medium', title: 'A file in src looks unused', detail: 'Nothing in the app imports or calls this file.', items: ['f:src/open.mjs'], notes: {}, fix: 'Cleanup : ne rien afficher.', locations: [] }] };
fs.writeFileSync(dst, html.slice(0, a + D.length) + JSON.stringify(g).replace(/</g, '\\u003c') + html.slice(b));
JS
sites() { node "$AUX/sites.mjs" "$1" "$SCRIPTS" "$EXCL" 2>"$WORK/sites.err" || echo '{"fn":"erreur"}'; }
PAGES="$SORTIE/index.html,$SORTIE/project.html"
SITES="$(sites "$PAGES")"; echo "$SITES" > "$WORK/sites.json"
assert_eq "F16.0 : inventaireSites est exportée par l'inventaire" "$(lire "$WORK/sites.json" 'j.fn')" "ok"
assert_ge "F16.1 : clés de t relevées dans le rendu servi (au moins 200, jamais un vert à vide)" "$(lire "$WORK/sites.json" '(j.n || 0)')" 200
assert_eq "F16.2 : toute clé de t, et tout texte du balisage statique, a une entrée de table ou une exclusion (la liste nomme celles qui manquent)" "$(lire "$WORK/sites.json" 'j.sansEntree || "calcul impossible : " + j.fn')" "[]"
T16="$WORK/t16"; mkdir -p "$T16"; cp "$SORTIE/index.html" "$SORTIE/project.html" "$T16/"
node -e 'const f=process.argv[1],fs=require("fs");fs.writeFileSync(f,fs.readFileSync(f,"utf8").replace("</body>","<script>const m = t(\"Chaîne neuve sans entrée\");</script></body>"))' "$T16/index.html"
SITES16="$(sites "$T16/index.html,$T16/project.html")"; echo "$SITES16" > "$WORK/sites16.json"
assert_eq "F16.3 témoin : un t('…') neuf sans entrée est nommé, lui seul" "$(node -e 'const a=JSON.parse(require("fs").readFileSync(process.argv[1])),b=JSON.parse(require("fs").readFileSync(process.argv[2]));const s=new Set(a.sansEntree||[]);console.log(JSON.stringify((b.sansEntree||["calcul impossible"]).filter((x)=>!s.has(x))))' "$WORK/sites.json" "$WORK/sites16.json")" '["Chaîne neuve sans entrée"]'
assert_eq "F17.1 : aucun littéral anglais libre, aucune clé non littérale, aucun t local qui masque le traducteur (hors exclusions motivées)" "$(lire "$WORK/sites.json" 'j.fn === "ok" ? [...j.libres.map((x) => "libre : " + x), ...j.nonLitterales.map((x) => "clé non littérale : " + x), ...j.ombres.map((x) => "ombre : " + x)] : "calcul impossible : " + j.fn')" "[]"
T17="$WORK/t17"; mkdir -p "$T17"; cp "$SORTIE/index.html" "$SORTIE/project.html" "$T17/"
node -e 'const f=process.argv[1],fs=require("fs");fs.writeFileSync(f,fs.readFileSync(f,"utf8").replace("</body>","<script>const m = \"Pending approval from the review board\"; t(maVariableNeuve);</script></body>"))' "$T17/index.html"
SITES17="$(sites "$T17/index.html,$T17/project.html")"; echo "$SITES17" > "$WORK/sites17.json"
nouv() { node -e 'const a=JSON.parse(require("fs").readFileSync(process.argv[1])),b=JSON.parse(require("fs").readFileSync(process.argv[2]));const k=process.argv[3];const s=new Set(a[k]||[]);console.log(JSON.stringify((b[k]||["calcul impossible"]).filter((x)=>!s.has(x))))' "$WORK/sites.json" "$1" "$2"; }
assert_eq "F17.2 témoin : un littéral anglais ajouté à une copie de la page est nommé, lui seul" "$(nouv "$WORK/sites17.json" libres)" '["Pending approval from the review board"]'
assert_eq "F17.3 témoin : un t(variable) ajouté à une copie est nommé « clé non littérale »" "$(nouv "$WORK/sites17.json" nonLitterales)" '["maVariableNeuve"]'
T17b="$WORK/t17b"; mkdir -p "$T17b"; cp "$SORTIE/index.html" "$SORTIE/project.html" "$T17b/"
node -e 'const f=process.argv[1],fs=require("fs");fs.writeFileSync(f,fs.readFileSync(f,"utf8").replace("</body>","<script>(() => { const t = window.__vfFrT; return (() => { const t = (x) => x; return t; })(); })();</script></body>"))' "$T17b/index.html"
sites "$T17b/index.html,$T17b/project.html" > "$WORK/sites17b.json"
assert_eq "F17.4 témoin : un t local qui masque le traducteur (ombre) est nommé, lui seul" "$(nouv "$WORK/sites17b.json" ombres)" '["const t"]'
node "$AUX/ordre.mjs" "$SORTIE/index.html" > "$WORK/ordre.json"
assert_eq "F18.1 : les blocs vibeflow:fr (78, 79, 80) précèdent le script principal et ui/00-vibeflow.js dans la page assemblée" "$(lire "$WORK/ordre.json" '[j.blocs, j.avantPrincipal, j.avant00, j.marqueurRestant].join()')" "3,true,true,false"
# F18.2 : un gabarit sans l'emplacement garde l'ancien ordre (copie du module, jamais une édition du module) ; jouée sur une copie du module (même copie que cockpit_module_copie)
M18="$WORK/mod-f18"; mkdir -p "$M18"; ( cd "$SCRIPTS/.." && tar -cf - --exclude='scripts/tests' scripts skills ) | ( cd "$M18" && tar -xf - ); L18="$WORK/lab18"; mkdir -p "$L18"; ( cd "$LAB" && tar -cf - --exclude=.vibeflow . ) | ( cd "$L18" && tar -xf - )
grep -v '<!--__UI_I18N__-->' "$M18/skills/cockpit-moteur/assets/viewer.html" > "$M18/viewer.sans" && mv "$M18/viewer.sans" "$M18/skills/cockpit-moteur/assets/viewer.html"
node "$M18/scripts/vf-cockpit-build.mjs" "$L18" --quiet >/dev/null 2>&1; node "$AUX/ordre.mjs" "$L18/.vibeflow/cockpit/index.html" > "$WORK/ordre18.json"
assert_eq "F18.2 : sans l'emplacement dans le gabarit, la page garde l'ancien ordre (blocs après le script principal, aucun marqueur laissé)" "$(lire "$WORK/ordre18.json" '[j.blocs, j.avantPrincipal, j.avant00, j.marqueurRestant].join()')" "3,false,false,false"
node "$AUX/t19.mjs" "$SORTIE/index.html" essai > "$WORK/t19e.json" 2>"$WORK/t19.err" || echo '{}' > "$WORK/t19e.json"
node "$AUX/t19.mjs" "$SORTIE/index.html" reelle > "$WORK/t19r.json" 2>>"$WORK/t19.err" || echo '{}' > "$WORK/t19r.json"
assert_eq "F19.1 : __vfFrT est une fonction" "$(lire "$WORK/t19e.json" 'j.fonction')" "function"
assert_eq "F19.2 : clé exacte (« Hello » : « Bonjour »)" "$(lire "$WORK/t19e.json" 'j.cle')" "Bonjour"
assert_eq "F19.3 : variables et formes (« {} call » : 1 appel, 3 appels)" "$(lire "$WORK/t19e.json" 'j.formes')" '["1 appel","3 appels"]'
assert_eq "F19.4 : élision et contraction de « de » devant la variable (d'Anthropic, du CLI)" "$(lire "$WORK/t19e.json" 'j.liaison')" '["Rien de saillant. C'"'"'est un contrôle automatique rapide, pas une revue complète d'"'"'Anthropic.","Rien de saillant. C'"'"'est un contrôle automatique rapide, pas une revue complète du CLI."]'
assert_eq "F19.5 : @contexte (« Changed@pastille » : Récent) et repli sur la clé sans contexte (Touché)" "$(lire "$WORK/t19e.json" 'j.contexte')" '["Récent","Touché"]'
assert_eq "F19.6 : t.pl et t.mot, singulier à 1" "$(lire "$WORK/t19e.json" 'j.pluriels')" '["1 appel","3 appels","ligne","lignes"]'
assert_eq "F19.7 : t.k (« 1.3k » : « 1,3 k », espace insécable)" "$(lire "$WORK/t19e.json" 'String(j.k).replace(/\u00a0/g, "_")')" "1,3_k"
assert_eq "F19.8 : t.type (« Library » : « Bibliothèque », une donnée inconnue : null)" "$(lire "$WORK/t19e.json" 'j.type')" '["Bibliothèque",null]'
assert_eq "F19.9 : t.constat (forme rendue reconnue, phrase inconnue inchangée)" "$(lire "$WORK/t19e.json" 'j.constat')" '["Readme et 7 autres","Une phrase que personne ne connaît"]'
assert_eq "F19.10 : une clé absente de la table rend la clé, variables remplies" "$(lire "$WORK/t19e.json" 'j.absente')" "Un x inconnu"
assert_eq "F19.11 : sous ?lang=en, la clé remplie, aucune valeur de table lue, t.pl en anglais, t.mot, t.k, t.type et t.constat neutres" "$(lire "$WORK/t19e.json" 'j.anglais')" '["Hello","3 call","Changed","3 calls","1 call","lines","1.3k","Readme and 7 more",null,"undefined","Un x inconnu"]'
assert_eq "F19.12 : sur la vraie table (« Fit to screen », File par onglet, une donnée, un constat reconnu)" "$(lire "$WORK/t19r.json" 'j.reelle')" '["Ajuster à l'"'"'écran","Fichier","Élément","Ma phrase de données",null,"src.js contient util.js"]'

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
  . "$SCRIPTS/tests/chrome-saut.sh"; vf_chrome_saut "  ⊘ F12 SAUTÉ : aucun navigateur (Chrome, Chromium) — le rendu visible NON vérifié, non compté comme réussi"
else
  . "$SCRIPTS/tests/hygiene.sh"; vf_hyg_init
  . "$SCRIPTS/tests/socle-serveur.sh"
  REAL_HOME="$HOME"; mkdir -p "$WORK/home/.claude/scripts"
  printf '#!/usr/bin/env bash\ncase "$1" in status) echo %s ;; orphans) echo %s ;; esac\n' "'{\"locks\":[]}'" "'{\"orphans\":[]}'" > "$WORK/home/.claude/scripts/driver-lock.sh"
  # lab jetable GSD : STATE.md en statut brut « ready_to_execute », jalon dont le nom commence par une voyelle
  LAB12="$WORK/lab12"; mkdir -p "$LAB12/src" "$LAB12/.planning/phases/01-socle"
  printf 'export const u = () => 1;\n' > "$LAB12/src/util.js"; printf 'import { u } from "./util.js";\nexport const ouvrir = u() + 2;\n' > "$LAB12/src/open.mjs" # 79-10 : un lien (open → util) pour les états « lien » du relevé
  printf '# Roadmap\n\n## Jalon Atelier\n\n- [ ] **Phase 1: Socle** - premier jet\n' > "$LAB12/.planning/ROADMAP.md"
  printf '<objective>Faire le socle</objective>\n' > "$LAB12/.planning/phases/01-socle/01-01-PLAN.md"
  printf -- '---\ngsd_state_version: 1.0\nmilestone: Atelier\nstatus: ready_to_execute\ncurrent_phase: 1\nlast_activity: 2026-11-04\n---\n\n# State\n' > "$LAB12/.planning/STATE.md"
  git -C "$LAB12" init -q && git -C "$LAB12" add -A && git -C "$LAB12" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB12" --quiet >/dev/null 2>&1 || echo "  assemblage du lab F12 impossible"
  O12="$LAB12/.vibeflow/cockpit"; ln -s "$SCRIPTS" "$WORK/scripts-hote"
  cockpit_lancer "$LAB12" HOME="$WORK/home" VF_COCKPIT_ENGINE_DIR="$SCRIPTS/../skills/cockpit-moteur" VF_COCKPIT_SCRIPTS_DIR="$WORK/scripts-hote"
  SRV12="${VF_PID:-}"; P12="${VF_PORT:-0}"
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
  echo "[F20 à F23] sondes de la page dans Chrome (79-10) : aucun observateur, ?lang=en gardé, parité de rendu, constats de Santé"
  ET="$SCRIPTS/tests/chrome-fr-etats.mjs"
  assert_eq "F20.1 : le code de 80-vf-fr.js (commentaires exclus) ne construit aucun observateur de mutations" "$(sed -E 's#^[[:space:]]*//.*##' "$UI/80-vf-fr.js" | grep -c 'new MutationObserver')" "0"
  REAL_HOME="$REAL_HOME" node "$ET" donnee "$CHROME" "file://$O12/index.html" > "$WORK/f20.json" 2>/dev/null
  assert_eq "F20.2 : un « Health » posé dans le panneau (hors des anciens sélecteurs listés) reste « Health »" "$(lire "$WORK/f20.json" '(j.erreur || j.texte)')" "Health"
  T20="$WORK/t20"; mkdir -p "$T20"; cp "$O12/index.html" "$T20/index.html"
  node -e 'const f=process.argv[1],fs=require("fs");fs.writeFileSync(f,fs.readFileSync(f,"utf8").replace("</body>","<script>new MutationObserver((ms) => { for (const m of ms) for (const n of m.addedNodes) if (n.nodeType === 1 && n.textContent === \"Health\") n.textContent = \"Santé\"; }).observe(document.body, { subtree: true, childList: true });</script></body>"))' "$T20/index.html"
  REAL_HOME="$REAL_HOME" node "$ET" donnee "$CHROME" "file://$T20/index.html" > "$WORK/f20c.json" 2>/dev/null
  assert_eq "F20.3 témoin : sur une copie portant un observateur générique de réécriture, la même sonde lit « Santé » (elle sait voir la réécriture)" "$(lire "$WORK/f20c.json" '(j.erreur || j.texte)')" "Santé"
  REAL_HOME="$REAL_HOME" node "$ET" sondes "$CHROME" "file://$O12/index.html" > "$WORK/f21f.json" 2>/dev/null
  REAL_HOME="$REAL_HOME" node "$ET" sondes "$CHROME" "file://$O12/index.html?lang=en" > "$WORK/f21e.json" 2>/dev/null
  assert_eq "F21.1 : sondes en français (zoom, recherche vide, export et son title, Santé)" "$(lire "$WORK/f21f.json" '(j.erreur || [j.fit, /Aucun résultat/.test(j.vide), j.export, j.exportTitre, j.sante])')" '["Ajuster à l'"'"'écran (F)",true,"Exporter","Exporter une copie de cette carte à partager","Santé"]'
  assert_eq "F21.2 : les mêmes sondes sous ?lang=en : les libellés sources" "$(lire "$WORK/f21e.json" '(j.erreur || [j.fit, /No matches/.test(j.vide), j.export, j.exportTitre, j.sante])')" '["Fit to screen (F)",true,"Export","Export a copy of this map to share","Health"]'
  T21="$WORK/t21"; mkdir -p "$T21"; cp "$O12/index.html" "$T21/index.html"
  node -e 'const f=process.argv[1],fs=require("fs");const l=fs.readFileSync(f,"utf8").split("\n");const i=l.findIndex((x)=>x.includes("// garde:lang-en"));if(i<0){console.log("ancre absente");process.exit(3)}const n=l[i].replace("=== \"en\"","=== \"zz\"").replace("=== '"'"'en'"'"'","=== '"'"'zz'"'"'");if(n===l[i]){console.log("ancre sans effet");process.exit(4)}l[i]=n;fs.writeFileSync(f,l.join("\n"))' "$T21/index.html" > "$WORK/f21m.txt" 2>&1; RC21=$?
  REAL_HOME="$REAL_HOME" node "$ET" sondes "$CHROME" "file://$T21/index.html?lang=en" > "$WORK/f21m.json" 2>/dev/null
  assert_eq "F21.3 témoin : avec la ligne de garde « // garde:lang-en » neutralisée, les sondes anglaises lisent du français (la mutation a eu lieu : $(cat "$WORK/f21m.txt"))" "$([ "$RC21" = 0 ] && lire "$WORK/f21m.json" '(j.erreur || j.fit)' || echo "mutation impossible : $(cat "$WORK/f21m.txt")")" "Ajuster à l'écran (F)"
  # F22 : parité de rendu avec le relevé « avant » (hors CI : variables d'environnement) ; VF_FR_RELEVE écrit le relevé et ne compare pas
  FSANTE="$WORK/sante-fixture.html"; node "$AUX/fixture-sante.mjs" "$O12/index.html" "$FSANTE"
  if [ -n "${VF_FR_RELEVE:-}" ] || [ -n "${VF_FR_AVANT:-}" ]; then
    REAL_HOME="$REAL_HOME" node "$ET" releve "$CHROME" "$O12/index.html" "$O12/project.html" "$FSANTE" > "$WORK/releve.json" 2>"$WORK/releve.err"
    assert_eq "F22.0 : le relevé des états a eu lieu (aucune erreur nommée)" "$(lire "$WORK/releve.json" 'j.erreur || "aucune"')" "aucune"
    if [ -n "${VF_FR_RELEVE:-}" ]; then cp "$WORK/releve.json" "$VF_FR_RELEVE"; echo "  (relevé des états écrit : $(node -e 'const j=JSON.parse(require("fs").readFileSync(process.argv[1]));console.log(Object.values(j).reduce((n,e)=>n+Object.keys(e).length,0)+" états")' "$WORK/releve.json" 2>/dev/null))"
    else assert_eq "F22 : le rendu de chaque état (Code, Projet, constats de Santé ; français et ?lang=en) égale le relevé d'avant, aux écarts admis nommés près" "$(node "$ET" comparer "$VF_FR_AVANT" "$WORK/releve.json" "${VF_FR_ADMIS:-}" 2>&1 | head -c 1500)" "[]"; fi
  fi
  # F23 (A43) : un constat de Santé de fixture s'affiche comme avant le plan ; valeurs recopiées du relevé « avant » (jamais calculées par le code éprouvé)
  case "${VF_FR_F23_MUTANT:-}" in
    retrait) F23P="$WORK/t23.html"; node -e 'const f=process.argv[1],o=process.argv[2],fs=require("fs");fs.writeFileSync(o,fs.readFileSync(f,"utf8").replace(/new MutationObserver\(/g,"new (class { observe() {} })(").replace(/SC\.on\?\.\(.(?:panel|render)., zones\);?/g,""))' "$FSANTE" "$F23P" ;; # retrait = les deux observateurs ET les deux écouteurs de rendu du moteur (l'observateur seul ne suffit pas : `panel` rappelle fix sur le panneau)
    affichage) F23P="$WORK/t23.html"; node -e 'const f=process.argv[1],o=process.argv[2],fs=require("fs");fs.writeFileSync(o,fs.readFileSync(f,"utf8").replace(/t\.constat\(/g,"((x) => x)("))' "$FSANTE" "$F23P" ;;
    *) F23P="$FSANTE" ;;
  esac
  REAL_HOME="$REAL_HOME" node "$ET" sante "$CHROME" "file://$F23P" > "$WORK/f23.json" 2>/dev/null
  assert_eq "F23.1 : constat de Santé — le détail « X contains … » s'affiche « X contient … » (valeur du relevé avant)" "$(lire "$WORK/f23.json" '(j.erreur || j.liste[0].detail)')" "src.js contient util.js"
  assert_eq "F23.2 : constat de Santé — le titre (phrase que le moteur ne reconnaît pas) reste tel quel, et le constat de contrôle aussi" "$(lire "$WORK/f23.json" '(j.erreur || [j.liste[0].titre, j.liste[1].titre, j.liste[1].detail])')" '["Anyone could change data through util.js","A file in src looks unused","Nothing in the app imports or calls this file."]'
  assert_eq "F23.3 : constat de Santé — localisations coupées à trois, « +3 autres » (valeur du relevé avant)" "$(lire "$WORK/f23.json" '(j.erreur || j.liste[0].lieux)')" "src/a.js:3
src/b.js
src/c.js:9
+3 autres"
  assert_eq "F23.4 : tableau « Montrer sur la carte » — titre et question tels que le relevé avant les montre (donnée du panneau, jamais réécrite : A43, AUDC-H4)" "$(lire "$WORK/f23.json" '(j.erreur || [j.tableau.titre, j.tableau.question])')" '["Anyone could change data through util.js","src.js contains util.js"]'
  vf_hyg_stop "$SRV12"; vf_hyg_assert
fi

echo "[F9] recette 68 R11 (P68-D-35) : le statut STATE brut n'est jamais affiché sur la page Projet (navigateur)"
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then . "$SCRIPTS/tests/chrome-saut.sh"; vf_chrome_saut "  ⊘ F9 SAUTÉ : aucun navigateur — le statut affiché n'est PAS vérifié, non compté comme réussi"; else
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
