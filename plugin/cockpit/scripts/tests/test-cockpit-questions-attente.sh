#!/usr/bin/env bash
# test-cockpit-questions-attente.sh — les questions en attente des sections « À Samuel » lues dans la collecte (TRAC-13 ; P76-D-34 à D-37, C76-Q1, C76-Q2)
#   T13.1-T13.3 de la collecte au graphe : champ posé, état tranché, champ absent sans section
#   T13.4-T13.12 cas limites fermés par défaut : défauts nommés, doublons, citation incohérente, autres formats, fichiers, bornes, nettoyage, texte, panne
#   T13.17-T13.19 questions appliquées sous délégation, archives non lues, ordre des champs non contrôlé
#   T13.13-T13.16 contrat de forme, corpus réel, poids
# Labs fabriqués dans mktemp (aucun chemin du poste dans les fichiers écrits). Exit 0 si tout passe, 1 sinon.

set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(cd "$SCRIPTS/../../.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"
AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
export HOME="$WORK/home"
trap 'vf_hyg_fin; [ -n "${KEEP:-}" ] || { chmod -R u+rwx "$WORK" 2>/dev/null; rm -rf "$WORK"; }' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 — attendu: [$3] obtenu: [$2]"; FAIL=$((FAIL+1)); fi; }

# --- outils node écrits par la suite ---
# j.mjs <fichier> <expression sur j> : « absent » si l'expression échoue ou rend undefined, « illisible » si le JSON ne se lit pas
cat > "$AUX/j.mjs" <<'JS'
import fs from 'node:fs';
let j; try { j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8')); } catch { console.log('illisible'); process.exit(0); }
let v; try { v = new Function('j', 'return (' + process.argv[3] + ')')(j); } catch { console.log('absent'); process.exit(0); }
console.log(v === undefined ? 'absent' : typeof v === 'string' ? v : JSON.stringify(v));
JS
J() { node "$AUX/j.mjs" "$1" "$2" 2>/dev/null || echo "illisible"; }
# graphe.mjs <scripts> <lab> : meta.vf.questions du graphe Projet réel ({"absent":true} sans le champ, {"erreur":…} si le module manque ou échoue),
#   plus les clés de contextes lus et les identifiants des nœuds de phase
cat > "$AUX/graphe.mjs" <<'JS'
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, lab] = process.argv;
const imp = (n) => import(pathToFileURL(path.join(scripts, n)).href);
try {
  const { buildProjectGraph } = await imp('vf-cockpit-project.mjs'); const { readPlanning } = await imp('vf-cockpit-planning.mjs');
  const racine = fs.realpathSync(lab); const g = buildProjectGraph(racine);
  const P = readPlanning(racine, undefined, { trace: true, sansTags: true });
  const q = g.meta && g.meta.vf && g.meta.vf.questions;
  console.log(JSON.stringify({ q: q === undefined ? null : q, absent: q === undefined, cles: ((P.trace && P.trace.contextes) || []).map((c) => c.key),
    noeuds: g.nodes.filter((n) => n.kind === 'phase').map((n) => n.id), traceOk: !!(g.meta.vf.trace && !g.meta.vf.trace.erreur), registres: Array.isArray(g.meta.vf.registres), graphe: process.argv[4] === 'complet' ? g : undefined }));
} catch (e) { console.log(JSON.stringify({ erreur: 'echec ' + String(e && e.message).slice(0, 160) })); }
JS
G() { local f; f="$WORK/g-$(basename "$2")-$(basename "$1")-${3:-x}.json"; node "$AUX/graphe.mjs" "$1" "$2" "${3:-}" > "$f" 2>/dev/null; echo "$f"; }

# cas.mjs <scripts> : lecture pure (lireQuestions) sur des entrées fabriquées ; chaque groupe rend la liste des étiquettes en échec (vide = vert)
cat > "$AUX/cas.mjs" <<'JS'
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts] = process.argv;
let M, T;
try { M = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-questions-attente.mjs')).href); T = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-trace-texte.mjs')).href); }
catch { console.log(JSON.stringify({ erreur: 'module-absent' })); process.exit(0); }
const { lireQuestions, DEFAUTS } = M;
const G = {}; const chk = (g, lib, c) => { (G[g] ||= []); if (!c) G[g].push(lib); };
const E = (o = {}) => {
  const f = { id: 'P90-Q-01', titre: 'Titre', q: 'Question sur\n  deux lignes.', opt: 'Options : (a) un ; (b) deux .', reco: 'Recommandation : (a) — motif.', blq: 'Bloque : 90-02, Phase 91',
    etat: 'État : en attente', extra: [], ...o };
  return [`- **${f.id} — ${f.titre}.** ${f.q}`, ...[f.opt, f.reco, f.blq, f.etat, ...f.extra].filter((x) => x !== null).map((x) => '  ' + x)].join('\n');
};
const SEC = (entrees, avant = '') => `# Contexte\n\n${avant}## À Samuel\n\nIntro.\n\n${entrees.join('\n')}\n\n## Autre\n\ntexte\n`;
const CTX = (txt, key = '|90', ws = '', fichier = 'p/90-CONTEXT.md') => ({ key, ws, fichier, txt });
const PH = new Map([['|90', 'ph-90'], ['a|90', 'ph-90@a'], ['b|90', 'ph-90@b'], ['fiabilite|76', 'ph-76@fiabilite']]);
const L = (ctxs, o = {}) => lireQuestions({ contextes: ctxs, phases: PH, ...o });
const un = (entree, avant) => { const r = L([CTX(SEC([entree], avant))]); return { r, e: r.liste[0] }; };
const MAL = ['id', 'phase', 'fichier', 'ligne', 'etat', 'defauts']; // + etat : la page lit etat === 'mal-formee'

// T13.4 — un cas par valeur fermée de defauts, tous mal formés, témoin positif voisin
const cas4 = [
  ['etat-absent', { etat: null }, ['etat-absent']],
  ['etat-invalide peut-être', { etat: 'État : peut-être' }, ['etat-invalide']],
  ['etat-invalide date', { etat: 'État : tranchée — arbitrage Samuel, canal x, 2026-13-45 — option (a) — « T. »' }, ['etat-invalide']],
  ['etat-invalide option hors liste', { etat: 'État : tranchée — arbitrage Samuel, canal x, 2026-11-11 — option (d) — « T. »' }, ['etat-invalide']],
  ['etat-invalide sans canal', { etat: 'État : tranchée' }, ['etat-invalide']],
  ['options une seule', { opt: 'Options : (a) seule .' }, ['options-invalides']],
  ['options lettres a,c', { opt: 'Options : (a) un ; (c) trois .' }, ['options-invalides']],
  ['options sans lettre', { opt: 'Options : rien du tout' }, ['options-invalides']],
  ['reco (d) de deux options', { reco: 'Recommandation : (d) — motif.' }, ['recommandation-hors-options']],
  ['reco illisible', { reco: 'Recommandation : bof' }, ['recommandation-hors-options']],
  ['bloque et', { blq: 'Bloque : 76-06 et 76-07' }, ['bloque-invalide']],
  ['bloque rien + plan', { blq: 'Bloque : rien, 76-04' }, ['bloque-invalide']],
  ['bloque Phase sans numéro', { blq: 'Bloque : Phase' }, ['bloque-invalide']],
  ['champ-repete', { extra: ['Options : (a) x ; (b) y .'] }, ['champ-repete']],
  ['champ-manquant Bloque', { blq: null }, ['champ-manquant']],
  ['champ-manquant Options', { opt: null }, ['champ-manquant']],
  ['champ-manquant Recommandation', { reco: null }, ['champ-manquant']],
  ['phase-incoherente', { id: 'P77-Q-01' }, ['phase-incoherente']],
  ['plusieurs défauts dans l’ordre de DEFAUTS', { etat: null, blq: 'Bloque : x', id: 'P77-Q-01' }, ['etat-absent', 'bloque-invalide', 'phase-incoherente']],
];
for (const [lib, o, att] of cas4) {
  const { r, e } = un(E(o));
  chk('t4', lib, e && e.etat === 'mal-formee' && JSON.stringify(e.defauts) === JSON.stringify(att) && JSON.stringify(Object.keys(e).sort()) === JSON.stringify([...MAL].sort())
    && r.bilan.enAttente === 0 && r.bilan.malFormees === 1);
}
chk('t4', 'témoin positif : l’entrée corrigée reste en attente', un(E()).e.etat === 'en-attente');
chk('t4', 'chaque valeur de DEFAUTS est un défaut attendu quelque part ou nommée par le contrat', DEFAUTS.length === 12 && Object.isFrozen(DEFAUTS));
{ const { e } = un(E()); chk('t4', 'forme complète d’une en-attente', e.id === 'P90-Q-01' && e.phase === 'ph-90' && e.ws === null && e.recommandation === 'a' && e.tranchee === null && e.appliquee === null
  && JSON.stringify(e.bloque) === JSON.stringify([{ type: 'plan', id: '90-02' }, { type: 'phase', n: '91' }]) && e.question === 'Question sur deux lignes.' && e.options.length === 2 && e.ligne === 7); }

// T13.5 — doubles
{ const r = L([CTX(SEC([E(), E({ id: 'P90-Q-02' })]), 'a|90', 'a'), CTX(SEC([E()]), 'b|90', 'b')]);
  const pQ1 = r.liste.filter((x) => x.id === 'P90-Q-01'), q2 = r.liste.find((x) => x.id === 'P90-Q-02');
  chk('t5', 'deux fichiers : toutes les occurrences mal formées', pQ1.length === 2 && pQ1.every((x) => x.etat === 'mal-formee' && JSON.stringify(x.defauts) === '["identifiant-double"]'));
  chk('t5', 'témoin positif : l’identifiant voisin unique reste en attente', q2 && q2.etat === 'en-attente');
  const s = L([CTX(SEC([E(), E()]))]);
  chk('t5', 'un fichier, deux fois', s.liste.length === 2 && s.liste.every((x) => x.etat === 'mal-formee' && x.defauts.includes('identifiant-double'))); }

// T13.6 — citation incohérente
{ const dec = '## Décisions\n\n- **P90-D-05 — Choix.** arbitrage Samuel, AskUserQuestion session principale, 2026-11-11, réponse à P90-Q-01.\n\n';
  const { r, e } = un(E(), dec);
  chk('t6', 'a-verifier, champs gardés', e.etat === 'a-verifier' && JSON.stringify(e.defauts) === '["citation-incoherente"]' && e.titre === 'Titre' && e.options.length === 2 && e.recommandation === 'a'
    && e.bloque.length === 2 && e.ligne > 0 && e.phase === 'ph-90' && e.fichier === 'p/90-CONTEXT.md');
  chk('t6', 'bilan : aVerifier 1, enAttente 0', r.bilan.aVerifier === 1 && r.bilan.enAttente === 0);
  chk('t6', 'positif : sans « arbitrage Samuel » reste en attente', un(E(), dec.replace('arbitrage Samuel', 'avis')).e.etat === 'en-attente');
  chk('t6', 'positif : une décision qui cite un autre identifiant laisse en attente', un(E(), dec.replace('P90-Q-01', 'P90-Q-02')).e.etat === 'en-attente'); }

// T13.7 — autres formats
{ const txt = `## À Samuel\n\n- **S-1 — Titre.** texte\n- **P90-Q-1 — Titre.** un chiffre\n- **P90-Q-02 – Titre.** demi-cadratin\n- puce sans gras\nde la prose\n  - **P90-Q-05 — Imbriquée.**\n\n${E({ id: 'P90-Q-09' })}\n`;
  const r = L([CTX(txt)]);
  chk('t7', 'seule l’entrée bien formée est lue', r.liste.length === 1 && r.liste[0].id === 'P90-Q-09' && r.liste[0].etat === 'en-attente');
  chk('t7', 'quatre puces de premier niveau non structurées (ni prose ni puce imbriquée)', r.bilan.nonStructurees === 4); }

// T13.8 — fichiers
{ const vide = L([CTX('# x\n\n## À Samuel\n\n## Autre\n')]);
  chk('t8', 'section vide : lue et comptée, aucune entrée', vide.bilan.registresLus === 1 && vide.liste.length === 0);
  chk('t8', 'section absente : non comptée', L([CTX('# x\n\n## Autre\n')]).bilan.registresLus === 0);
  chk('t8', 'fichier illisible (texte vide) : non compté, le voisin lisible l’est', (() => { const r = L([CTX(''), CTX(SEC([E()]), 'a|90', 'a')]); return r.bilan.registresLus === 1 && r.liste.length === 1; })());
  chk('t8', 'section répétée : seule la première est lue', (() => { const r = L([CTX(SEC([E()]) + '\n## À Samuel\n\n' + E({ id: 'P90-Q-02' }) + '\n')]); return r.liste.length === 1 && r.liste[0].id === 'P90-Q-01'; })());
  chk('t8', 'un bloc de code fermé ne compte pas comme titre', L([CTX('## À Samuel\n\n```\n## faux titre\n```\n' + E() + '\n')]).liste.length === 1); }

// T13.9 — borne à 200
{ const n = (k) => Array.from({ length: k }, (_, i) => E({ id: `P90-Q-${String(i + 1).padStart(3, '0')}` }));
  const a = L([CTX(SEC(n(205)))]), b = L([CTX(SEC(n(200)))]), c = L([CTX(SEC(n(201)))]);
  chk('t9', '205 : 200 servies, tronqué, bilan 205', a.liste.length === 200 && a.tronque === true && a.bilan.enAttente === 205);
  chk('t9', 'tri par identifiant', a.liste[0].id === 'P90-Q-001' && a.liste[199].id === 'P90-Q-200');
  chk('t9', 'frontière : 200 non tronqué, 201 tronqué', b.tronque === false && b.liste.length === 200 && c.tronque === true); }

// T13.10 — nettoyage et longueurs
{ const sv = (s, k) => T.servi(s, k, { racine: '/lab/racine' }); const home = os.homedir(); const long = 'x'.repeat(400);
  const o = E({ titre: `Chemin /lab/racine/.planning/a et ${home}/z et ~/.claude/x et /var/folders/x ${long}`, q: `Voir /lab/racine/y ${long}`,
    opt: `Options : (a) ${long} ; (b) ${home}/o .`,
    etat: `État : tranchée — arbitrage Samuel, canal x, 2026-11-11 — option (a) — « ${long} »` });
  const r = lireQuestions({ contextes: [CTX(SEC([o]))], phases: PH, servi: sv }); const e = r.liste[0], ser = JSON.stringify(r);
  chk('t10', 'aucun chemin du poste ni ~/', !ser.includes('/lab/racine/') && !ser.includes(home) && !ser.includes('~/') && !ser.includes('/var/folders/') && e.etat === 'tranchee');
  chk('t10', 'longueurs : 80, 240, 160, 240', e.titre.length <= 80 && e.question.length <= 240 && e.options[0].texte.length <= 160 && e.tranchee.citation.length <= 240);
  const p = L([CTX(SEC([E({ titre: 'Un chemin /lab/racine/ici sans nettoyage' })]))]);
  chk('t10', 'témoin positif : sans servi injecté le texte passe tel quel', p.liste[0].titre.includes('/lab/racine/')); }

// T13.11 — texte non interprété
{ const t = '<img src=x onerror=alert(1)>'; const { e } = un(E({ titre: t })); chk('t11', 'titre chaîne pour chaîne', e.titre === t); }

// T13.17 — appliquée sous délégation
{ const ap = (opt, dec = 'P90-D-03', date = '2026-11-08') => `État : appliquée — décision déléguée par Samuel (message session principale, ${date}), option (${opt}) — ${dec}`;
  const reg = '## Décisions\n\n- **P90-D-03 — Choix.** appliqué.\n\n';
  const { r, e } = un(E({ etat: ap('a') }), reg);
  chk('t17', 'appliquée bien formée', e.etat === 'appliquee' && JSON.stringify(e.appliquee) === JSON.stringify({ canal: 'message session principale', date: '2026-11-08', option: 'a', decision: 'P90-D-03' })
    && e.tranchee === null && r.bilan.appliquees === 1 && r.bilan.enAttente === 0 && r.bilan.tranchees === 0 && e.defauts.length === 0);
  const d = (o, avant) => un(E(o), avant).e;
  const hr = d({ etat: ap('b') }, reg); chk('t17', 'option (b) ≠ recommandation : mal formée, un seul défaut', hr.etat === 'mal-formee' && JSON.stringify(hr.defauts) === '["appliquee-hors-recommandation"]');
  const au = d({ etat: ap('a'), reco: 'Recommandation : aucune — goût.' }, reg); chk('t17', 'recommandation aucune : mal formée', au.etat === 'mal-formee' && JSON.stringify(au.defauts) === '["appliquee-hors-recommandation"]');
  const di = d({ etat: ap('a', 'P90-D-77') }, reg); chk('t17', 'décision non définie : a-verifier, champs gardés', di.etat === 'a-verifier' && JSON.stringify(di.defauts) === '["decision-introuvable"]' && di.options.length === 2 && di.appliquee.decision === 'P90-D-77');
  const hl = d({ etat: ap('d') }, reg); chk('t17', 'option absente des options : etat-invalide seul', hl.etat === 'mal-formee' && JSON.stringify(hl.defauts) === '["etat-invalide"]');
  const dt = d({ etat: ap('a', 'P90-D-03', '2026-02-30') }, reg); chk('t17', 'date impossible : etat-invalide seul', dt.etat === 'mal-formee' && JSON.stringify(dt.defauts) === '["etat-invalide"]');
  chk('t17', 'positif : la même entrée en attente redevient en attente', d({}, reg).etat === 'en-attente'); }

// T13.18 — archives non lues
{ const r = L([CTX(SEC([E()])), CTX(SEC([E({ id: 'P80-Q-01' })]), '*|80', '*', 'm/80-CONTEXT.md')]);
  chk('t18', 'la clé *| est écartée avant toute lecture', r.liste.length === 1 && r.liste[0].id === 'P90-Q-01' && r.bilan.registresLus === 1);
  chk('t18', 'positif : sans la clé joker la même entrée est lue', L([CTX(SEC([E({ id: 'P80-Q-01' })]), '|80', '', 'm/80-CONTEXT.md')]).liste.length === 1); }

// T13.19 — l'ordre des champs n'est pas contrôlé
{ const o = un(E({ opt: 'Options : (a) un ; (b) deux .' })).e; const a = [E().split('\n')[0], '  État : en attente', '  Bloque : 90-02, Phase 91', '  Recommandation : (a) — motif.', '  Options : (a) un ; (b) deux .'];
  const e = un(a.join('\n').replace(/^(- \*\*.*)$/m, '$1\n  deux lignes.')).e;
  chk('t19', 'ordre inversé : en attente sans défaut', e.etat === 'en-attente' && e.defauts.length === 0 && o.etat === 'en-attente'); }

console.log(JSON.stringify(G));
JS
CAS="$WORK/cas.json"; node "$AUX/cas.mjs" "$SCRIPTS" > "$CAS" 2>/dev/null || true
KO() { J "$CAS" "j.$1.join(' | ')"; }

# --- fabrication des labs ---
wr() { mkdir -p "$(dirname "$1")"; cat > "$1"; }
lab_q() { # lab racine : phase 90, registre en phases/90-x ; archive d'un jalon clos si $2 non vide
  local d="$1"; mkdir -p "$d/.planning/phases/90-x"
  printf '# Roadmap\n\n## Milestones\n\n- 🚧 **v1** - Phases 90-90 (in progress)\n\n## Phases\n\n- [ ] **Phase 90: P90** - p\n\n### Phase 90: P90\n**Goal**: but\n**Depends on**: Nothing\n' > "$d/.planning/ROADMAP.md"
  printf -- '---\nmilestone: v1\nstatus: executing\ncurrent_phase: 90\n---\n' > "$d/.planning/STATE.md"
}
ENT='- **P90-Q-01 — Une question.** Que faire ?
  Options : (a) un ; (b) deux .
  Recommandation : (a) — motif.
  Bloque : 90-02, Phase 91
  État : en attente'

echo "=== T13.1 à T13.3 — de la collecte au graphe ==="
LQ="$WORK/lq"; lab_q "$LQ"
printf '# Contexte\n\n## À Samuel\n\n%s\n- **P90-Q-02 — Tranchée.** Déjà répondue.\n  Options : (a) un ; (b) deux .\n  Recommandation : (a) — motif.\n  Bloque : rien\n  État : tranchée — arbitrage Samuel, AskUserQuestion session principale, 2026-11-11 — option (b) — « Texte exact. »\n' "$ENT" > "$LQ/.planning/phases/90-x/90-CONTEXT.md"
GQ="$(G "$SCRIPTS" "$LQ")"
assert_eq "T13.1a la question en attente est dans meta.vf.questions du vrai graphe" "$(J "$GQ" "j.q.liste[0].id+'|'+j.q.liste[0].phase+'|'+j.q.liste[0].etat+'|'+j.q.liste[0].recommandation")" "P90-Q-01|ph-90|en-attente|a"
assert_eq "T13.1b bloque, défauts, ligne et bilan" "$(J "$GQ" "JSON.stringify([j.q.liste[0].bloque, j.q.liste[0].defauts, j.q.liste[0].ligne, j.q.bilan.enAttente, j.q.bilan.registresLus, j.q.tronque])")" '[[{"type":"plan","id":"90-02"},{"type":"phase","n":"91"}],[],5,1,1,false]'
assert_eq "T13.1c témoin positif : la ligne du fichier porte la tête de l'entrée" "$(sed -n '5p' "$LQ/.planning/phases/90-x/90-CONTEXT.md" | cut -c1-24)" '- **P90-Q-01 — Une quest'
assert_eq "T13.2a la question tranchée porte canal, date, option et citation" "$(J "$GQ" "JSON.stringify(j.q.liste[1].tranchee)+'|'+j.q.liste[1].etat+'|'+j.q.bilan.tranchees")" '{"canal":"AskUserQuestion session principale","date":"2026-11-11","option":"b","citation":"Texte exact."}|tranchee|1'
sed -i.bak 's/^  État : tranchée.*$/  État : en attente/' "$LQ/.planning/phases/90-x/90-CONTEXT.md"; rm -f "$LQ/.planning/phases/90-x/90-CONTEXT.md.bak"
assert_eq "T13.2b témoin positif : la même entrée en attente redevient en attente" "$(J "$(G "$SCRIPTS" "$LQ")" "j.q.liste[1].etat")" "en-attente"
L3="$WORK/l3"; lab_q "$L3"; printf '# Contexte\n\n## Décisions\n\n- **P90-D-01 — x.** y\n' > "$L3/.planning/phases/90-x/90-CONTEXT.md"
assert_eq "T13.3a aucun registre avec section « À Samuel » : champ absent" "$(J "$(G "$SCRIPTS" "$L3")" "j.absent")" "true"
printf '# Contexte\n\n## À Samuel\n\n## Autre\n' > "$L3/.planning/phases/90-x/90-CONTEXT.md"
assert_eq "T13.3b section vide : champ présent, liste vide, registre compté" "$(J "$(G "$SCRIPTS" "$L3")" "j.q.liste.length+'|'+j.q.bilan.registresLus")" "0|1"

echo "=== T13.4 à T13.11, T13.17 à T13.19 — cas limites, lecture pure ==="
assert_eq "T13.4 chaque valeur fermée de defauts, mal formée, réduite à id/phase/fichier/ligne/defauts" "$(KO t4)" ""
assert_eq "T13.5 identifiant double : toutes les occurrences mal formées" "$(KO t5)" ""
assert_eq "T13.6 citation incohérente : a-verifier avec ses champs, témoins positifs" "$(KO t6)" ""
assert_eq "T13.7 puce d'un autre format, prose, puce imbriquée : jamais une question" "$(KO t7)" ""
assert_eq "T13.8 section vide, absente, illisible, répétée, bloc de code" "$(KO t8)" ""
assert_eq "T13.9 plus de 200 entrées : coupe, drapeau, frontières" "$(KO t9)" ""
assert_eq "T13.10 aucun chemin du poste, longueurs coupées, témoin positif" "$(KO t10)" ""
assert_eq "T13.11 un titre balisé ressort tel quel, jamais interprété" "$(KO t11)" ""
assert_eq "T13.11b le module ne construit aucun balisage" "$(grep -c 'innerHTML\|insertAdjacentHTML\|<span\|<div' "$SCRIPTS/vf-cockpit-questions-attente.mjs" 2>/dev/null || true)" "0"
assert_eq "T13.17 appliquée : forme canonique, hors recommandation, décision introuvable, défauts univoques" "$(KO t17)" ""
assert_eq "T13.18a archives écartées par la clé joker" "$(KO t18)" ""
LA="$WORK/la"; lab_q "$LA"; mkdir -p "$LA/.planning/milestones/v0-phases/80-y"
printf '## À Samuel\n\n%s\n' "$ENT" > "$LA/.planning/phases/90-x/90-CONTEXT.md"
printf '## À Samuel\n\n%s\n' "$(printf '%s' "$ENT" | sed 's/P90-Q-01/P80-Q-01/')" > "$LA/.planning/milestones/v0-phases/80-y/80-CONTEXT.md"
GA="$(G "$SCRIPTS" "$LA")"
assert_eq "T13.18b dans le lab : seule la question du dossier vivant est lue, l'archive est bien présente dans les contextes de la collecte" "$(J "$GA" "j.cles.join()+'|'+(j.q?j.q.liste.map(x=>x.id).join():'absent')+'|'+(j.q?j.q.bilan.registresLus:'absent')")" "|90,*|80|P90-Q-01|1"
assert_eq "T13.18c témoin positif : le fichier d'archive contient l'entrée" "$(grep -c 'P80-Q-01 — ' "$LA/.planning/milestones/v0-phases/80-y/80-CONTEXT.md")" "1"
assert_eq "T13.19 l'ordre des champs n'est pas contrôlé" "$(KO t19)" ""
# T13.8 dans le lab : un registre rendu illisible n'est pas compté, son voisin lisible l'est
LI="$WORK/li"; lab_q "$LI"; printf '## À Samuel\n\n%s\n' "$ENT" > "$LI/.planning/phases/90-x/90-CONTEXT.md"
printf '## À Samuel\n\n%s\n' "$ENT" > "$LI/.planning/phases/90-x/90-b-CONTEXT.md"; chmod 000 "$LI/.planning/phases/90-x/90-b-CONTEXT.md"
assert_eq "T13.8b registre illisible (chmod 000) : sans erreur, non compté ; le voisin lisible est lu" "$(J "$(G "$SCRIPTS" "$LI")" "(j.q?j.q.bilan.registresLus+'|'+j.q.liste.length:'absent')")" "1|1"
chmod 644 "$LI/.planning/phases/90-x/90-b-CONTEXT.md"

echo "=== T13.12 — une panne de la lecture ne casse pas la collecte ==="
MUT="$WORK/mut"; mkdir -p "$MUT"; cp "$SCRIPTS"/*.mjs "$SCRIPTS/vf-cockpit-interface.json" "$MUT/" 2>/dev/null
cat > "$AUX/panne.mjs" <<'JS'
import fs from 'node:fs';
const f = process.argv[2]; const t = fs.readFileSync(f, 'utf8'); const de = 'export function lireQuestions(';
if (!t.includes(de)) { console.log('ancre introuvable'); process.exit(1); }
fs.writeFileSync(f, t.replace(de, "export function lireQuestions() { throw new Error('panne injectée'); }\nfunction lireQuestionsInerte(")); console.log('panne posée');
JS
assert_eq "T13.12a panne injectée dans la copie jetable" "$(node "$AUX/panne.mjs" "$MUT/vf-cockpit-questions-attente.mjs" 2>/dev/null || echo absent)" "panne posée"
GM="$(G "$MUT" "$LQ")"
assert_eq "T13.12b graphe construit, trace et registres intacts, champ absent" "$(J "$GM" "j.noeuds.join()+'|'+j.traceOk+'|'+j.registres+'|'+j.absent")" "ph-90|true|true|true"
assert_eq "T13.12c témoin positif : sans panne le champ est présent" "$(J "$GQ" "j.absent")" "false"

echo "=== T13.13 à T13.16 — contrat de forme, corpus réel, poids ==="
cat > "$AUX/validate.mjs" <<'JS'
// validate.mjs <interface.json> <sortie.json> — clés requises de cockpit-project@1, clés interdites (liste de cockpit-who@2) à toute profondeur, valeurs fermées de questions
import fs from 'node:fs';
const [, , ifaceF, outF, injecte] = process.argv;
const iface = JSON.parse(fs.readFileSync(ifaceF, 'utf8')); const spec = iface.schemas['vibeflow/cockpit-project@1'];
const interdits = iface.schemas['vibeflow/cockpit-who@2'].interdits; const out = JSON.parse(fs.readFileSync(outF, 'utf8')); const errs = [];
const type = (v) => (Array.isArray(v) ? 'array' : v === null ? 'null' : typeof v);
const g = out.graphe; if (injecte === 'mandat') g.meta.vf.questions.liste[0].mandat = 'x';
for (const [k, t] of Object.entries(spec.requis)) { if (!(k in g)) errs.push(`clé requise absente : ${k}`); else if (type(g[k]) !== t) errs.push(`type de ${k}`); }
const deep = (o, f) => { if (o && typeof o === 'object') for (const [k, v] of Object.entries(o)) { f(k); deep(v, f); } };
deep(g, (k) => { if (interdits.includes(k)) errs.push(`clé interdite présente : ${k}`); });
if (!spec.optionnels.metaVf.includes('questions')) errs.push('meta.vf.questions non déclaré');
const q = g.meta.vf.questions; if (!q) errs.push('champ absent');
else {
  const ETATS = ['en-attente', 'appliquee', 'tranchee', 'a-verifier', 'mal-formee'];
  for (const e of q.liste) { if (!ETATS.includes(e.etat)) errs.push('etat ' + e.etat); }
  for (const k of ['liste', 'bilan', 'tronque']) if (!(k in q)) errs.push('questions.' + k + ' absent');
}
console.log(errs.length ? 'KO ' + errs.join(' | ') : 'OK');
JS
GC="$(G "$SCRIPTS" "$LQ" complet)"
assert_eq "T13.13a le graphe réel valide ses clés requises et la déclaration de meta.vf.questions" "$(node "$AUX/validate.mjs" "$SCRIPTS/vf-cockpit-interface.json" "$GC" 2>&1 | tail -1)" "OK"
assert_eq "T13.13b témoin positif : la même validation rougit sur une clé interdite injectée" "$(node "$AUX/validate.mjs" "$SCRIPTS/vf-cockpit-interface.json" "$GC" mandat 2>&1 | tail -1 | cut -c1-2)" "KO"
assert_eq "T13.13c la clé de version de cockpit-project@1 est inchangée (pas de @2)" "$(grep -c 'cockpit-project@2' "$SCRIPTS/vf-cockpit-interface.json" || true)" "0"
# corpus réel 1 : la section « À Samuel » de 76-CONTEXT.md
CTX76="$(find "$REPO/.planning/workstreams" -path '*VFDO-76-*' -name '76-CONTEXT.md' | head -1)"
cat > "$AUX/corpus.mjs" <<'JS'
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, mode, ...fichiers] = process.argv;
let M; try { M = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-questions-attente.mjs')).href); } catch { console.log(JSON.stringify({ erreur: 'module-absent' })); process.exit(0); }
const lire = (f, txt) => M.lireQuestions({ contextes: [{ key: 'fiabilite|' + (/(?:VFDO-)?(\d+)-/.exec(path.basename(path.dirname(f))) || [, 0])[1], ws: 'fiabilite', fichier: path.basename(f), txt }], phases: new Map() });
const sortie = {};
if (mode === '76') {
  const f = fichiers[0]; const txt = fs.readFileSync(f, 'utf8'); const r = lire(f, txt);
  const par = (x) => Object.fromEntries(x.liste.map((e) => [e.id, e]));
  const sans = par(lire(f, txt.split('\n').filter((l) => !/^ {2}Bloque : rien$/.test(l)).join('\n')));
  const att = par(lire(f, txt.replace(/^ {2}État : appliquée.*$/m, '  État : en attente')));
  Object.assign(sortie, { q1: r.liste[0] && [r.liste[0].etat, r.liste[0].tranchee], q2: r.liste[1] && r.liste[1].etat, q3: r.liste[2] && [r.liste[2].etat, r.liste[2].appliquee],
    bilan: r.bilan, sansBloque: sans['P76-Q-03'] && [sans['P76-Q-03'].etat, sans['P76-Q-03'].defauts], enAttente: att['P76-Q-03'] && att['P76-Q-03'].etat });
} else {
  let lus = 0; const ko = [];
  for (const f of fichiers) {
    const txt = fs.readFileSync(f, 'utf8').replace(/\r\n?/g, '\n'); const lignes = txt.split('\n'); const d = lignes.findIndex((l) => /^##\s+À Samuel/.test(l));
    if (d < 0) continue; let e = lignes.findIndex((l, i) => i > d && /^## /.test(l)); if (e < 0) e = lignes.length;
    const puces = lignes.slice(d + 1, e).filter((l) => /^[-*+]\s/.test(l)).length; const r = lire(f, txt); lus++;
    if (puces !== r.liste.length + r.bilan.nonStructurees) ko.push(path.basename(f) + ' invariant ' + puces + '≠' + r.liste.length + '+' + r.bilan.nonStructurees);
    for (const q of r.liste) if (q.etat === 'en-attente' && !/^- \*\*P[0-9.]+-Q-[0-9]{2,} — /.test(lignes[q.ligne - 1] || '')) ko.push(path.basename(f) + ' en-attente hors grammaire ' + q.id);
  }
  Object.assign(sortie, { lus, ko });
}
console.log(JSON.stringify(sortie));
JS
C76="$WORK/c76.json"; node "$AUX/corpus.mjs" "$SCRIPTS" 76 "$CTX76" > "$C76" 2>/dev/null || true
assert_eq "T13.14a P76-Q-01 et P76-Q-02 tranchées (option a), P76-Q-03 appliquée (a, P76-D-31), jamais en attente" "$(J "$C76" "JSON.stringify([j.q1,j.q2,j.q3])")" '[["tranchee",{"canal":"AskUserQuestion session principale","date":"2026-11-11","option":"a","citation":"Marque neutre (Recommandé)"}],"tranchee",["appliquee",{"canal":"message session principale","date":"2026-11-08","option":"a","decision":"P76-D-31"}]]'
assert_eq "T13.14b bilan : appliquées 1, tranchées 2, en attente 0, non structurées 0" "$(J "$C76" "[j.bilan.appliquees,j.bilan.tranchees,j.bilan.enAttente,j.bilan.nonStructurees].join()")" "1,2,0,0"
assert_eq "T13.14c témoins positifs : sans la ligne Bloque, mal formée ; avec l'état remplacé, en attente" "$(J "$C76" "JSON.stringify([j.sansBloque,j.enAttente])")" '[["mal-formee",["champ-manquant"]],"en-attente"]'
CTXS="$(find "$REPO/.planning/workstreams" -name '*-CONTEXT.md' \( -path '*VFDO-73-*' -o -path '*VFDO-74-*' -o -path '*VFDO-75-*' -o -path '*VFDO-77-*' -o -path '*VFDO-79-*' -o -path '*VFDO-80-*' \) | sort)"
C15="$WORK/c15.json"; # shellcheck disable=SC2086
node "$AUX/corpus.mjs" "$SCRIPTS" autres $CTXS > "$C15" 2>/dev/null || true
LUS="$(J "$C15" "j.lus")"; echo "LUS=$LUS"
assert_eq "T13.15a chaque puce de premier niveau est une entrée ou comptée non structurée ; aucune puce hors grammaire en attente" "$(J "$C15" "j.ko.join(' | ')")" ""
assert_eq "T13.15b le corpus lu atteint au moins 2 fichiers (jamais un vert à vide)" "$([ "$LUS" -ge 2 ] 2>/dev/null && echo oui || echo "non ($LUS)")" "oui"
PQ="$(node --input-type=module -e "
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const imp = (n) => import(pathToFileURL(path.join('$SCRIPTS', n)).href);
const { buildProjectGraph } = await imp('vf-cockpit-project.mjs'); const g = buildProjectGraph(fs.realpathSync('$REPO'));
console.log(Buffer.byteLength(JSON.stringify(g.meta.vf.questions === undefined ? null : g.meta.vf.questions)));" 2>/dev/null || echo erreur)"
echo "POIDS-Q octets=$PQ"
assert_eq "T13.16 la mesure du poids de meta.vf.questions sur le dépôt est lue (mesure, jamais un seuil)" "$(printf '%s' "$PQ" | grep -c '^[0-9][0-9]*$')" "1"

# --- FIN-SECTIONS ---
echo
echo "Résultats : $PASS passés, $FAIL échoués"
# garde anti-vert-à-vide : le nombre d'assertions jouées doit atteindre l'attendu
ATTENDU=34
[ $((PASS + FAIL)) -ge "$ATTENDU" ] || { echo "  ❌ FAIL — anti-vert-à-vide : $((PASS + FAIL)) assertions jouées, $ATTENDU attendues"; FAIL=$((FAIL+1)); }
[ "$FAIL" -eq 0 ]
