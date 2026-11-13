#!/usr/bin/env bash
# test-cockpit-synthese-cout.sh — le bloc « Coût par phase et par étage · dernières 24 h » de la Synthèse (77-07, SYNT-10 ; P77-D-15, D-16, D-20, D-28, D-29, D-32).
#   S  statique : fichier ui/74-vf-synthese-cout.js (jeton, eval, on*, plafonds, ligne AJOUT, champs de voie lus, symboles de monnaie, « Aucune activité » une seule fois)
#   CO0..CO12 sous `vm` (jamais de document) sur une frise figée (chrome-synthese-cout-fix.mjs), avec ET sans l'agrégat de la 74 (74-vf-frise-calculs.js)
#   B  sondes positives des outils neufs du banc (interceptions, symbole de monnaie vu) · CO12, CO13, CO14 et W17 dans Chrome (module complet, charge prouvée) · M-INNER
# Régime allégé (2026-11-13) : seule la garde d'échappement du texte rendu a son mutant (M-INNER) ; les autres mutants du plan ne sont pas joués.
# Chrome headless ; sans navigateur la partie navigateur est SAUTÉE hors CI, et ÉCHOUE en CI (jamais un vert à vide).
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE GIT_CEILING_DIRECTORIES
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; TESTS="$SCRIPTS/tests"; MOD="$(cd "$SCRIPTS/.." && pwd -P)"; ENG="$MOD/skills/cockpit-moteur"; UI="$ENG/assets/ui"
BANC="$TESTS/chrome-synthese.mjs"; COUT="$UI/74-vf-synthese-cout.js"; CALC="$UI/74-vf-frise-calculs.js"; MODELE="$UI/74-vf-frise-modele.js"; FIX="$TESTS/chrome-synthese-cout-fix.mjs"
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
REAL_HOME="$(node -e 'console.log(require("os").userInfo().homedir)')"; export HOME="$WORK/home"
trap 'vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"
PASS=0; FAIL=0
assert_eq() { if [ "$#" -ne 3 ]; then echo "  ❌ FAIL — $1 (assert_eq a reçu $# arguments au lieu de 3)"; FAIL=$((FAIL+1)); elif [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [${3:0:300}]"; echo "     obtenu:  [${2:0:300}]"; FAIL=$((FAIL+1)); fi; }
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; let j; try { j = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { console.log('illisible'); process.exit(0); }
let v; try { v = new Function('j', 'return (' + process.argv[2] + ')')(j); } catch (e) { v = 'erreur:' + e.message; } console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/largeur.mjs" <<'JS'
import fs from 'node:fs'; for (const f of process.argv.slice(2)) { const l = fs.readFileSync(f, 'utf8').split('\n'); if (l.at(-1) === '') l.pop(); console.log(f, l.length, Math.max(0, ...l.map((x) => [...x.replace(/\r$/, '')].length))); }
JS
# ---- CO sous vm : le module chargé SANS document, avec et sans l'agrégat de la 74 ; les attendus viennent d'une table écrite à la main (jamais du module) ----
cat > "$AUX/co.mjs" <<'JS'
import fs from 'node:fs'; import vm from 'node:vm'; import { pathToFileURL } from 'node:url';
const [, , MOD, CALC, MODELE, FIX] = process.argv, F = await import(pathToFileURL(FIX).href), lire = (f) => fs.readFileSync(f, 'utf8'), out = {}, js = (x) => JSON.parse(JSON.stringify(x));
const monde = (avec) => { const window = {}, ctx = vm.createContext({ window, console }); if (avec) { vm.runInContext(lire(CALC), ctx); vm.runInContext(lire(MODELE), ctx); } vm.runInContext(lire(MOD), ctx); return { window, ctx }; };
let M0, M1; try { M0 = monde(false); M1 = monde(true); } catch (e) { console.log(JSON.stringify({ chargement: 'erreur:' + e.message })); process.exit(0); }
const C0 = M0.window.__vfSyntheseCout, C1 = M1.window.__vfSyntheseCout, K = M1.window.__vfFriseCalculs, brut = js(F.voies());
const same = (a, b) => (JSON.stringify(a) === JSON.stringify(b) ? 'ok' : JSON.stringify(a) + ' != ' + JSON.stringify(b));
const G = { 'sess-1': 'non', 'mg-77': '77', 'wk-77a': '77', 'wk-77b': '77', 'wk-78': '78', 'wk-60': 'hors', 'wk-x': 'non', 'wk-sans': 'non', 'wk-nul': 'non', 'wk-mx': 'non' };
const E = { 'sess-1': 'Tête de session', 'mg-77': 'Manager', 'wk-77a': 'Codeur', 'wk-77b': 'Revue', 'wk-78': 'Codeur', 'wk-60': 'Audit', 'wk-x': 'Codeur', 'wk-sans': 'Vérification', 'wk-nul': 'Vérification', 'wk-mx': 'Autres' };
const CLES = ['entree', 'sortie', 'cacheLu', 'cacheCree', 'travailS'], par = (g, vs = brut) => vs.filter((v) => G[v.id] === g);
const S = (vs, k) => vs.reduce((s, v) => s + (k === 'travailS' ? v.durees.travailS : v.jetons[k]), 0), att = (vs) => Object.fromEntries(CLES.map((k) => [k, S(vs, k)]));
const vue = (l) => (l ? Object.fromEntries(CLES.map((k) => [k, l[k]])) : l);
const O = { missions: F.MISSIONS, phases: F.PHASES, jalon: F.JALONS[0].phases };
const A = C0.agreger(js(brut), O), B = C1.agreger(js(brut), O), les2 = (f) => same([f(A), f(B)], [f(A), f(A)]) === 'ok' ? f(A) : [f(A), f(B)];
const ligne = (R, cle) => R.lignes.find((l) => l.cle === cle);
out.co0 = same([Object.keys(C0).sort(), typeof document], [['ETAGES', 'agreger', 'depuisAgregat', 'etage', 'etatDeSource', 'fmtDuree', 'fmtJetons', 'minorant'], 'undefined']);
const reg = M1.window.__vfSyntheseBlocs || [], b = reg.filter((x) => x.id === 'cout');
vm.runInContext(lire(MOD), M1.ctx); // ré-exécution (script par onglet) : l'entrée est remplacée, jamais doublée
out.co0b = same([b.length, b[0] && b[0].titre, ['installer', 'present', 'rendre', 'ouvrir'].map((n) => typeof b[0][n]), Object.isFrozen(C0), (M1.window.__vfSyntheseBlocs || []).filter((x) => x.id === 'cout').length],
  [1, 'Coût par phase et par étage · dernières 24 h', ['function', 'function', 'function', 'function'], true, 1]);
out.co1 = same(les2((R) => [vue(ligne(R, 'fiabilite|77')), vue(ligne(R, 'fiabilite|78')), R.lignes.map((l) => l.cle)]), [att(par('77')), att(par('78')), ['fiabilite|77', 'fiabilite|78']]);
const et = (R, cle, nom) => (ligne(R, cle).etages.find((e) => e.etage === nom) || {});
out.co2 = same(les2((R) => ['Manager', 'Codeur', 'Revue'].map((n) => et(R, 'fiabilite|77', n).entree)), [2000, 30000, 4000]);
const tpl = brut.find((v) => v.id === 'wk-x'), p78 = brut.find((v) => v.id === 'wk-78');
const sent = (r) => { const v = js(tpl); v.id = 's'; if (r === 'ABSENT') delete v.rattachement; else v.rattachement = r; return v; };
for (const [cle, r] of [['co3a', 'ABSENT'], ['co3b', null], ['co3c', { dag: 'inconnu.md', noeud: null, source: 'registre' }]]) {
  const f = (C) => { const R = C.agreger([js(p78), sent(r)], O); return [R.lignes.map((l) => l.cle), vue(R.lignes[0]), vue(R.nonRattache), R.horsJalon, vue(R.total)]; };
  out[cle] = same([f(C0), f(C1)], [[['fiabilite|78'], att([p78]), att([tpl]), null, att([p78, tpl])], [['fiabilite|78'], att([p78]), att([tpl]), null, att([p78, tpl])]]);
}
const r77 = A.lignes[0], p77 = par('77'), tot = att(brut);
out.co4 = same([r77.jetons, r77.cacheLu, r77.cacheCree, r77.travailS, A.total.jetons, A.total.cacheCree, A.total.travailS],
  [S(p77, 'entree') + S(p77, 'sortie'), S(p77, 'cacheLu'), S(p77, 'cacheCree'), S(p77, 'travailS'), tot.entree + tot.sortie, tot.cacheCree, tot.travailS]);
out.co5 = same([brut.map((v) => C0.etage(v)), C0.ETAGES, ['gsd-executor', 'vf-crafter', 'vf-app-fixer'].map((role) => C0.etage({ kind: 'subagent', role })),
  ['vf-design-manager', 'content-clarity-judge', 'gsd-code-reviewer', 'gsd-security-auditor', 'prd-gate', 'quality-gate-client', 'vf-business-finance'].map((role) => C0.etage({ kind: 'subagent', role })),
  C0.etage({ kind: 'subagent', role: null }), C0.etage({ kind: 'session', role: 'vf-coder' })],
  [brut.map((v) => E[v.id]), ['Manager', 'Codeur', 'Revue', 'Audit', 'Vérification', 'Tête de session', 'Autres'], ['Codeur', 'Codeur', 'Codeur'],
    ['Manager', 'Revue', 'Revue', 'Audit', 'Vérification', 'Vérification', 'Autres'], 'Autres', 'Tête de session']);
const inc = js(F.friseInconnu().voies), partout = (C) => { const R = C.agreger(js(inc), O); return [ligne(R, 'fiabilite|78').entree, ligne(R, 'fiabilite|78').jetons, ligne(R, 'fiabilite|78').sortie, R.total.entree, R.total.sortie, R.inconnus]; };
out.co6 = same([partout(C0), partout(C1)], Array(2).fill([null, null, 2500, att(brut).entree - 10000, att(brut).sortie, 1]));
const inv = (R) => CLES.every((k) => R.lignes.reduce((s, l) => s + (l[k] ?? 0), 0) + (R.horsJalon ? R.horsJalon[k] : 0) + (R.nonRattache ? R.nonRattache[k] : 0) === R.total[k]);
const corrompu = js(A), doublon = js(A); corrompu.lignes.shift(); doublon.lignes.push(js(A.lignes[0]));
const T74 = K.agreger(js(M1.window.__vfFriseModele.lire(F.frise()).frise.voies), 'mission', { missions: F.MISSIONS, phases: F.PHASES, tronque: true });
const Bt = C1.agreger(js(brut), { ...O, tronque: true }), At = C0.agreger(js(brut), { ...O, tronque: true });
out.co7 = same([inv(A), inv(B), inv(corrompu), inv(doublon), JSON.stringify(A) === JSON.stringify(B), JSON.stringify(vue(B.total)) === JSON.stringify(vue(T74.total)), Bt.inconnus === T74.inconnus, Bt.incomplet, At.incomplet, A.incomplet],
  [true, true, false, false, true, true, true, true, true, false]);
out.co7b = same(JSON.stringify(C1.agreger(js(M1.window.__vfFriseModele.lire(F.frise()).frise.voies), O)) === JSON.stringify(B), true);
const NB = ' ';
out.co8 = same([[1234567, 340000, 950, 47400].map(C0.fmtJetons), [11400, 2520, 42, 100, 3599].map(C0.fmtDuree), [C0.fmtJetons(NaN), C0.fmtDuree(undefined)],
  [1234567, 340000, 47400].map(C1.fmtJetons), [11400, 2520, 100].map(C1.fmtDuree)],
  [[`1,2${NB}M`, `340${NB}k`, '950', `47,4${NB}k`], [`3${NB}h 10`, `42${NB}min`, `42${NB}s`, `2${NB}min`, `1${NB}h 00`], [null, null],
    [`1,2${NB}M`, `340${NB}k`, `47,4${NB}k`], [`3${NB}h 10`, `42${NB}min`, `2${NB}min`]]);
out.co10 = same([vue(A.horsJalon), A.horsJalon.libelle, A.nonRattache.libelle, vue(A.nonRattache), A.lignes.some((l) => l.cle === 'fiabilite|60'), Object.keys(A).filter((k) => !['total', 'inconnus', 'incomplet'].includes(k))],
  [att(par('hors')), 'Hors jalon', 'Non rattaché', att(par('non')), false, ['lignes', 'horsJalon', 'nonRattache']]);
const T = A.total, J = (n) => K.fmtJetons(n), D = (n) => K.fmtDuree(n), m = (r) => C0.minorant(r, T), inconnu = `Total partiel : au moins ${J(T.jetons)} jetons hors cache et ${D(T.travailS)}, nombre de voies omises inconnu.`;
out.co11 = same([m({ tronque: false, voiesOmises: 5 }), m({ tronque: true, voiesOmises: 3 }), m({ tronque: true, voiesOmises: 1 }).phrase, [0, null, undefined, 2.5, -2, '4'].map((n) => m({ tronque: true, voiesOmises: n })),
  m({ tronque: true, voiesOmises: 0 }).phrase.includes(' 0 voie')],
  [{ complet: true, phrase: '' }, { complet: false, phrase: `Total partiel : au moins ${J(T.jetons)} jetons hors cache et ${D(T.travailS)}, 3 voies omises.` },
    `Total partiel : au moins ${J(T.jetons)} jetons hors cache et ${D(T.travailS)}, 1 voie omise.`, Array(6).fill({ complet: false, phrase: inconnu }), false]);
const etat = C0.etatDeSource;
out.co12 = same([etat({ etat: 'ok' }, [1]), etat({ etat: 'ok' }, []), etat({ etat: 'en-construction' }, []), etat({ etat: 'en-construction' }, [1]), etat({ etat: 'partielle' }, []), etat({ etat: 'partielle' }, [1]),
  etat({ etat: 'forme-inconnue' }, []), etat({ etat: 'indisponible' }, []), etat(undefined, []), etat({ etat: 'zzz' }, [1]), etat({ etat: 'ok' }, undefined)],
  ['ok-avec-voies', 'ok-vide', 'en-construction', 'en-construction', 'partielle', 'partielle', 'forme-inconnue', 'indisponible', 'forme-inconnue', 'forme-inconnue', 'ok-vide']);
console.log(JSON.stringify(out));
JS
cat > "$AUX/attendu.mjs" <<'JS'
// l'oracle du rendu navigateur : les chaînes attendues du cas « complet », construites depuis la table écrite à la main (pas depuis le module)
import fs from 'node:fs'; import vm from 'node:vm'; import { pathToFileURL } from 'node:url';
const [, , CALC, FIX, tronque] = process.argv, F = await import(pathToFileURL(FIX).href), win = {}; vm.runInContext(fs.readFileSync(CALC, 'utf8'), vm.createContext({ window: win }));
const K = win.__vfFriseCalculs, brut = JSON.parse(JSON.stringify(F.voies())), pre = tronque === 'oui' ? 'au moins ' : '';
const G = { 'sess-1': 'non', 'mg-77': '77', 'wk-77a': '77', 'wk-77b': '77', 'wk-78': '78', 'wk-60': 'hors', 'wk-x': 'non', 'wk-sans': 'non', 'wk-nul': 'non', 'wk-mx': 'non' };
const E = { 'sess-1': 'Tête de session', 'mg-77': 'Manager', 'wk-77a': 'Codeur', 'wk-77b': 'Revue', 'wk-78': 'Codeur', 'wk-60': 'Audit', 'wk-x': 'Codeur', 'wk-sans': 'Vérification', 'wk-nul': 'Vérification', 'wk-mx': 'Autres' };
const ORDRE = ['Manager', 'Codeur', 'Revue', 'Audit', 'Vérification', 'Tête de session', 'Autres'];
const S = (vs, k) => vs.reduce((s, v) => s + (k === 'travailS' ? v.durees.travailS : v.jetons[k]), 0), J = (n) => K.fmtJetons(n), D = (n) => K.fmtDuree(n);
const cache = (vs) => `lu ${J(S(vs, 'cacheLu'))} · créé ${J(S(vs, 'cacheCree'))}`, tete = (g) => brut.filter((v) => G[v.id] === g);
const ligne = (lib, vs) => [lib, J(S(vs, 'entree') + S(vs, 'sortie')) + '|' + cache(vs), D(S(vs, 'travailS'))];
const etages = (vs) => ORDRE.filter((n) => vs.some((v) => E[v.id] === n)).map((n) => { const g = vs.filter((v) => E[v.id] === n);
  return `${n} : entrée ${J(S(g, 'entree'))}, sortie ${J(S(g, 'sortie'))}, cache lu ${J(S(g, 'cacheLu'))}, cache créé ${J(S(g, 'cacheCree'))}`; });
const GR = [['Phase 77 · Santé de la méthode', '77'], ['Phase 78 · Équipe en direct', '78'], ['Hors jalon', 'hors'], ['Non rattaché', 'non']];
console.log(JSON.stringify({ lignes: GR.map(([l, g]) => ligne(l, tete(g))), etages: GR.map(([, g]) => etages(tete(g))),
  total: ['Total', pre + J(S(brut, 'entree') + S(brut, 'sortie')) + '|' + pre + cache(brut), pre + D(S(brut, 'travailS'))], jetons: J(S(brut, 'entree') + S(brut, 'sortie')), duree: D(S(brut, 'travailS')) }));
JS
CO="$(node "$AUX/co.mjs" "$COUT" "$CALC" "$MODELE" "$FIX" 2>&1)"; JC() { printf '%s' "$CO" | node "$AUX/ev.mjs" "$1"; }
MON() { node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(/[€$£]|\b(euros?|dollars?|USD|EUR)\b|coût estimé/i.test(s)?1:0))'; }
NC() { node -e 'const fs=require("fs");console.log((fs.readFileSync(process.argv[1],"utf8").match(new RegExp(process.argv[2],process.argv[3]||"g"))||[]).length)' "$1" "$2" "${3:-}"; }

echo "=== S — le fichier neuf, statiquement ==="
assert_eq "S0 — témoin : le fichier et ses deux dépendances de test existent (jamais un vert à vide)" "$([ -f "$COUT" ] && [ -f "$CALC" ] && [ -f "$MODELE" ] && echo oui || echo non)" "oui"
assert_eq "S1 — aucun en-tête de jeton, eval, new Function, blob:, attribut on*, ni route de dernière commande ou de transcript" "$(/usr/bin/grep -cE 'x-floorplan-token|x-vf-cockpit-token|eval\(|new Function|blob:| on[a-z]+=|/api/vf/(doing|transcript)|localStorage|sessionStorage|fetch\(' "$COUT" 2>/dev/null)" "0"
assert_eq "S2 — première ligne « // VibeFlow ( », au plus 299 lignes, 160 points de code par ligne (mesure en points de code)" "$([ -f "$COUT" ] && head -n 1 "$COUT" | /usr/bin/grep -q '^// VibeFlow (' && node "$AUX/largeur.mjs" "$COUT" | awk '$2 > 299 || $3 > 160 { print $1 }' || echo faux)" ""
assert_eq "S3 — ligne AJOUT de VENDORED.txt : une, et les lignes AJOUT restent triées" "$(/usr/bin/grep -c -E '^AJOUT assets/ui/74-vf-synthese-cout\.js$' "$ENG/VENDORED.txt")|$(/usr/bin/grep '^AJOUT ' "$ENG/VENDORED.txt" | LC_ALL=C sort -c 2>&1 | wc -l | tr -d ' ')" "1|0"
assert_eq "CO9 — aucun champ de voie hors kind, role, jetons, durees, rattachement : ni verbe en cours, cibles, événements, segments, ni transcript ou doing" "$(NC "$COUT" 'enCours|cibles|evenements|segments|dispatchA|etatOfficiel|compteurs|transcript|doing|modeles|\.parent\b|\.arbre\b|\.session\b')" "0"
assert_eq "S4 — aucun symbole ni mot de monnaie dans le fichier" "$(sed 's/\${//g' "$COUT" | MON)" "0"
assert_eq "S4b — sonde positive de la regex de monnaie : elle voit « 12 € et 3 dollars » et rien dans « Jetons, hors cache 3 k »" "$(printf '12 € et 3 dollars' | MON)|$(printf 'Jetons, hors cache 3 k, Cache lu et créé' | MON)" "1|0"
assert_eq "S7 — l'ancre de M-INNER est unique dans les fichiers ui/ (le mutant ne peut viser que ce bloc)" "$(cat "$UI"/*.js | NC /dev/stdin "e\.textContent = '' \+ texte")" "1"
assert_eq "S5 — « Aucune activité » écrit une seule fois (l'état ok sans voie, le seul qui le dit)" "$(NC "$COUT" 'Aucune activité')" "1"
cat > "$AUX/sonde.css" <<'CSS'
.x { padding: 10px; color: #123456; }
CSS
node "$TESTS/css-jetons.mjs" "$AUX/sonde.css" > /dev/null 2>&1; CJ_ROUGE=$?; [ -f "$COUT" ] && { node "$TESTS/css-jetons.mjs" "$COUT" > /dev/null 2>&1; CJ_VERT=$?; } || CJ_VERT=9
assert_eq "S6 — css-jetons : rouge sur un espacement de 10 px et une couleur injectés, vert sur le fichier" "$CJ_ROUGE|$CJ_VERT" "1|0"

echo "=== CO — calculs purs sous vm (sans document), avec et sans l'agrégat de la 74 ==="
assert_eq "CO chargement — le module se charge sans erreur dans les deux mondes" "$(JC 'j.chargement || ""')" ""
assert_eq "CO0 — exports exacts (ETAGES, etage, agreger, depuisAgregat, minorant, etatDeSource, fmtJetons, fmtDuree), aucun document" "$(JC 'j.co0')" "ok"
assert_eq "CO0b — une seule entrée « cout » au registre, titre exact, quatre fonctions, gelé ; ré-exécution : remplacée, jamais doublée" "$(JC 'j.co0b')" "ok"
assert_eq "CO1 — une voie dont rattachement.dag égale missions[].fichier va à la phase de phaseKey (sommes exactes, ordre des phases)" "$(JC 'j.co1')" "ok"
assert_eq "CO2 — le manager { noeud: null, source: 'enfants' } va à la phase de son plan, à l'étage Manager" "$(JC 'j.co2')" "ok"
assert_eq "CO3a — une voie SANS clé rattachement va à « Non rattaché », jamais à une phase, comptée au total" "$(JC 'j.co3a')" "ok"
assert_eq "CO3b — rattachement: null : « Non rattaché »" "$(JC 'j.co3b')" "ok"
assert_eq "CO3c — mission introuvable (dag inconnu) : « Non rattaché »" "$(JC 'j.co3c')" "ok"
assert_eq "CO4 — quatre compteurs sommés séparément (cache créé compris) ; chiffre principal = entrée + sortie sans cache ; durée = Σ travailS" "$(JC 'j.co4')" "ok"
assert_eq "CO5 — table des étages : sept étages dans l'ordre, rôle inconnu → Autres, session → Tête de session" "$(JC 'j.co5')" "ok"
assert_eq "CO6 — champ de jetons absent : null sur la ligne, exclu du total, inconnus = 1 (jamais 0)" "$(JC 'j.co6')" "ok"
assert_eq "CO7 — Σ phases + Hors jalon + Non rattaché = total (cinq colonnes), avec et sans la 74 ; sonde positive : une ligne perdue ou doublée le rougit ; incomplet = tronque" "$(JC 'j.co7')" "ok"
assert_eq "CO7b — avec la 74 : des voies passées par __vfFriseModele.lire() donnent le même résultat" "$(JC 'j.co7b')" "ok"
assert_eq "CO8 — formats « 1,2 M », « 340 k », « 3 h 10 », « 42 min » (espace insécable), identiques à ceux de la 74" "$(JC 'j.co8')" "ok"
assert_eq "CO10 — « Hors jalon » (phase connue hors du jalon) et « Non rattaché » (horsMission, mission sans phase) séparés, hors jalon jamais dans une phase ni dans « Non rattaché »" "$(JC 'j.co10')" "ok"
assert_eq "CO11 — minorant : « au moins » et le nombre de voies omises (singulier à 1) ; absent, 0, non entier ou négatif : « inconnu », jamais « 0 voie » ; tronque faux : complet" "$(JC 'j.co11')" "ok"
assert_eq "CO12 — état de source : cinq états, « ok » seul peut dire « Aucune activité », en-construction jamais" "$(JC 'j.co12')" "ok"

if [ -z "$CHROME" ]; then
  . "$(dirname "$0")/chrome-saut.sh"; vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur — le bloc de coût dans Chrome (CO12, CO13, CO14, W15c, W17) n'est PAS vérifié, non comptée comme réussie"
  vf_hyg_assert; echo ""; echo "  Résultats : $PASS PASS / $FAIL FAIL"; [ "$FAIL" -eq 0 ]; exit $?
fi
echo "=== navigateur — module complet servi, frise et état interceptés ==="
LAB="$(node "$BANC" lab "$WORK")"; node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
COP="$(cockpit_module_copie "$WORK/mod-cout")"; export COCKPIT_MODULE="$COP"; cockpit_lancer "$LAB"; RL=$?; PORT="${VF_PORT:-0}"
assert_eq "B0 — le serveur du module complet est prêt et charge la copie visée" "$RL|$([ "$PORT" -gt 0 ] && echo prêt)|$(cockpit_module_charge "$COP" && echo charge)" "0|prêt|charge"
RV="$(REAL_HOME="$REAL_HOME" node "$BANC" cout "$CHROME" "$PORT")"; [ -n "${DBG:-}" ] && echo "RAW: $RV"
cockpit_arreter
JV() { printf '%s' "$RV" | node "$AUX/ev.mjs" "$1"; }
ATT="$(node "$AUX/attendu.mjs" "$CALC" "$FIX" non)"; ATT_T="$(node "$AUX/attendu.mjs" "$CALC" "$FIX" oui)"; JA() { printf '%s' "$ATT" | node "$AUX/ev.mjs" "$1"; }; JT() { printf '%s' "$ATT_T" | node "$AUX/ev.mjs" "$1"; }
RMON="$(printf '%s' "$RV" | node "$AUX/ev.mjs" 'j.sondes.monnaie')"
assert_eq "B1 — le banc : la réponse interceptée est vue par la page (schéma et 10 voies) et comptée ; la regex de monnaie voit un symbole injecté et rien dans le bloc réel" "$(JV 'j.erreur || ""')|$(JV 'j.sondes.intercepte')|$(JV 'j.sondes.vues >= 1')|$(printf '%s' "$RMON" | MON)|$(JV 'j.cas.complet.texte' | MON)" "|vibeflow/cockpit-frise@1:10|true|1|0"

echo "=== CO13 — réponses de la route : 404 et schéma inconnu retirent le bloc, tout autre échec le dit ==="
for c in absent404 schemaInconnu; do
  assert_eq "CO13 ($c) — aucun nœud DOM du bloc ; les trois autres blocs sont là, dans l'ordre" "$(JV "j.cas.$c.present + '|' + j.cas.$c.nbCout + '|' + j.cas.$c.blocs.join('-')")" "false|0|visite-burnup-methode"
done
for c in b400bornes b400champs b403 b503 b500 echeance; do
  assert_eq "CO13 ($c) — « Coût indisponible : la frise n'a pas répondu. », aucun tableau, jamais un bloc vide" "$(JV "j.cas.$c.present + '|' + j.cas.$c.tables + '|' + j.cas.$c.notes.join('/')")" "true|0|Coût indisponible : la frise n'a pas répondu."
done
assert_eq "CO13 (indisponibleEtat) — source.etat « indisponible » : même phrase" "$(JV "j.cas.indisponibleEtat.tables + '|' + j.cas.indisponibleEtat.notes.join('/')")" "0|Coût indisponible : la frise n'a pas répondu."
echo "=== CO12 — les cinq états de source.etat dans la page ==="
assert_eq "CO12 (ok sans voie) — « Aucune activité dans les dernières 24 h. » et aucun tableau" "$(JV "j.cas.okVide.tables + '|' + j.cas.okVide.notes.join('/')")" "0|Aucune activité dans les dernières 24 h."
for c in enConstruction enConstructionVoies; do
  assert_eq "CO12 ($c) — son texte propre, jamais « Aucune activité »" "$(JV "j.cas.$c.tables + '|' + j.cas.$c.notes.join('/') + '|' + j.cas.$c.texte.includes('Aucune activité')")" "0|L'index des sessions est en cours de construction : le coût apparaîtra à la fin de la lecture.|false"
done
assert_eq "CO12 (forme-inconnue) — « Le cockpit ne reconnaît pas la forme des sessions de cette version de Claude Code. »" "$(JV "j.cas.formeInconnue.tables + '|' + j.cas.formeInconnue.notes.join('/')")" "0|Le cockpit ne reconnaît pas la forme des sessions de cette version de Claude Code."
assert_eq "CO12 (partielle) — le tableau ET « Lecture partielle : certaines sessions n'ont pas été lues. »" "$(JV "j.cas.partielle.tables + '|' + j.cas.partielle.notes.includes(\"Lecture partielle : certaines sessions n'ont pas été lues.\")")" "1|true"

echo "=== W17 — le bloc, le tableau, les phases, le minorant ==="
assert_eq "W17.1 — route présente : le bloc suit le bloc 3 (ordre visite, burnup, methode, cout), titre exact, un seul bloc" "$(JV "j.cas.complet.blocs.join('-') + '|' + j.cas.complet.titre + '|' + j.cas.complet.nbCout")" "visite-burnup-methode-cout|Coût par phase et par étage · dernières 24 h|1"
assert_eq "W17.2 — un tableau nommé par le h3 (aria-labelledby), trois en-têtes th scope=col : Phase, Jetons hors cache, Durée (le cache est la seconde ligne de la cellule des jetons)" "$(JV "j.cas.complet.tables + '|' + j.cas.complet.labelled + '|' + j.cas.complet.labelledOk + '|' + j.cas.complet.ths.join(',')")" "1|vf-sy-t-cout|true|Phase|col,Jetons, hors cache|col,Durée|col"
assert_eq "W17.3 — lignes : phases du jalon dans l'ordre (77, 78), puis « Hors jalon », puis « Non rattaché » en dernier ; jetons (entrée + sortie), cache lu et créé, durée" "$(JV 'j.cas.complet.lignes')" "$(JA 'j.lignes')"
assert_eq "W17.4 — chaque ligne se déplie (details) en une ligne par étage, dans l'ordre fixe : entrée, sortie, cache lu, cache créé" "$(JV 'j.cas.complet.etages')|$(JV 'j.cas.complet.details')" "$(JA 'j.etages')|[1,1,1,1]"
assert_eq "W17.5 — ligne de total sans « au moins » quand tout est complet ; aucune phrase de minorant" "$(JV 'j.cas.complet.total')|$(JV 'j.cas.complet.notes.filter((n) => /Total partiel/.test(n)).length')" "$(JA 'j.total')|0"
assert_eq "W17.6 — aucun symbole ni mot de monnaie dans le texte du bloc (cas complet, tronqué, partiel)" "$(for c in complet tronque3 partielle inconnu; do JV "j.cas.$c.texte" | MON; done | tr '\n' ',')" "0,0,0,0,"
assert_eq "W17.7 — la voie sans rattachement tombe sur « Non rattaché » (comptée au total), jamais dans une phase : la ligne porte ses jetons" "$(JV "j.cas.complet.lignes[3][0]")|$(JV "j.cas.complet.lignes[0][0] + '/' + j.cas.complet.lignes[1][0]")" "Non rattaché|Phase 77 · Santé de la méthode/Phase 78 · Équipe en direct"
assert_eq "W17.8 — l'aide dit « Jamais de montant » et que les jetons couvrent la vie de chaque agent dans l'index des 24 h, sans coupe à la seconde" "$(JV "j.cas.complet.notes[0]")" "Jetons et durée de travail. Jamais de montant. Les jetons couvrent la vie de chaque agent dans l'index des dernières 24 h, sans coupe à la seconde."
for c in tronque3 tronque1 tronque0; do
  case "$c" in tronque3) ph="3 voies omises.";; tronque1) ph="1 voie omise.";; *) ph="nombre de voies omises inconnu.";; esac
  assert_eq "W17.9 ($c) — le total est un minorant (« au moins » devant chaque total) et la phrase le dit : « …, $ph »" "$(JV "j.cas.$c.total")|$(JV "j.cas.$c.notes.filter((n) => n.startsWith('Total partiel')).join('/')")" "$(JT 'j.total')|Total partiel : au moins $(JT 'j.jetons') jetons hors cache et $(JT 'j.duree'), $ph"
done
assert_eq "W17.10 — frise tronquée à 0 voie omise : jamais « 0 voie omise » ; complète : aucun « au moins »" "$(JV "j.cas.tronque0.texte.includes(' 0 voie')")|$(JV "j.cas.complet.texte.includes('au moins')")" "false|false"
assert_eq "W17.11 — champ de jetons absent : « inconnu » sur la ligne, total sans lui avec « 1 voie sans mesure, non comptée. »" "$(JV "j.cas.inconnu.lignes[1][1].split('|')[0]")|$(JV "j.cas.inconnu.notes.includes('1 voie sans mesure, non comptée.')")" "inconnu|true"
assert_eq "W17.12 — état d'index indisponible pour les missions (GET /api/vf/state en 500) : tout est « Non rattaché », jamais une phase devinée" "$(JV "j.cas.sansEtat.lignes.map((l) => l[0]).join('/')")" "Non rattaché"
assert_eq "W17.13 — les ordonnées des blocs 1 à 3 ne bougent pas que le bloc existe ou non (même page : 404 puis route présente après un cycle d'onglets)" "$(JV 'JSON.stringify(j.retour.avant.tops) === JSON.stringify(j.retour.apres.tops)')|$(JV 'j.retour.avant.present + "," + j.retour.apres.present')" "true|false,true"
assert_eq "W17.14 — lisible à la largeur du panneau (360 px) : cache sur une seule ligne dans chaque cellule, détail des étages (ligne dépliée) à la largeur du tableau, aucun débordement" "$(JV '[j.cas.complet.geo.panneau, j.cas.complet.geo.nCaches >= 5, j.cas.complet.geo.lignesCache, j.cas.complet.geo.detail === j.cas.complet.geo.table, j.cas.complet.geo.debordement, j.cas.complet.geo.ouvert].join()')" "360,true,1,true,false,true"
echo "=== CO14 / W15c / E0 ==="
assert_eq "CO14 — après deux cycles d'onglets : un seul bloc, un seul abonnement à frise (égal au chargement à froid), même document, écouteurs égaux, au plus une requête de frise à l'ouverture" "$(JV '[j.onglets.nbCout, j.onglets.abonnes === j.retour.abonnes0, j.onglets.memeDocument, JSON.stringify(j.onglets.ecoutAvant) === JSON.stringify(j.onglets.ecoutApres), j.onglets.reqOuverture <= 1, j.retour.abonnes1 === j.retour.abonnes0].join()')" "1,true,true,true,true,true"
assert_eq "W15c — la balise piégée posée dans un nom de phase est affichée en texte : window.__xss indéfini, aucune image ni script, aucun on*, aucune violation de CSP" "$(JV '[j.cas.xss.xss, j.cas.xss.imgs, j.cas.xss.on, j.cas.xss.texte.includes("PIEGE"), j.csp].join()')" "undefined,0,0,true,0"
assert_eq "W11 — aucun POST, aucune requête vers transcript ou doing, chaque lecture de l'API porte le jeton (témoin : le journal voit des GET)" "$(JV '[j.reseau.posts, j.reseau.interdites, j.reseau.sansJeton, j.reseau.gets >= 1].join()')" "0,0,0,true"
assert_eq "E0 — aucune exception de page" "$(JV 'j.erreursPage.length')" "0"

echo "=== M-INNER — la garde d'échappement : un nom de phase injecté sans échappement rougit W15c ==="
if cockpit_module_muter_page minner "s/e\.textContent = '' + texte/e.innerHTML = '' + texte/"; then
  cockpit_lancer "$LAB"; RLM=$?; PM="${VF_PORT:-0}"
  assert_eq "M-INNER.0 — le serveur du mutant est prêt et charge la copie mutée (charge prouvée)" "$RLM|$([ "$PM" -gt 0 ] && echo prêt)|$(cockpit_module_charge "$COCKPIT_MODULE" && echo charge)" "0|prêt|charge"
  RM="$(REAL_HOME="$REAL_HOME" node "$BANC" cout "$CHROME" "$PM")"; cockpit_arreter
  assert_eq "M-INNER — sur le mutant, la balise s'exécute (window.__xss posé ou image rendue) : W15c rougit, la sonde est donc capable d'échouer" "$(printf '%s' "$RM" | node "$AUX/ev.mjs" '(j.cas.xss.xss !== "undefined") || (j.cas.xss.imgs > 0)')" "true"
else assert_eq "M-INNER.0 — la mutation s'applique (ancre unique présente dans le fichier du bloc)" "refusée" "appliquée"; fi
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ "$FAIL" -eq 0 ]
