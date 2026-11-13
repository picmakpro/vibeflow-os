#!/usr/bin/env bash
# test-cockpit-activite-empreinte.sh — Phase 75, plan 75-03 tâches 2 et 3 (ACTV-08, ACTV-09, ACTV-10 : sources « agents » et « plans ») : degrés, noms, mentions de limite,
# collisions d'agents et de plans ; node seul, aucun processus laissé, horloge injectée.
#   M1 degrés et fenêtre de 24 h · M2 lectures ≠ écritures · M3 noms, jamais l'identifiant brut · M4 en construction, tronqué · M5 compteurs et limite · M6 tuples, aucune clé dynamique
#   M7 aucun argument d'outil (M7b : le témoin positif) · M8 2 000 voies · M9 worktree vérifié hors lab · K1 deux arbres · K2 même arbre, parent-enfant · K3 lectures · K4 plans
#   K5 forme et états incomplets · K6 sentinelle · K7 témoins croisés
# Mutants : une copie des modules, une retouche d'une ligne, la suite rejouée ; « MUTANT-ROUGE — <nom> » quand le témoin visé rougit.
# Sortie : « PASS — <id> : … », « ❌ FAIL — <id> : … », « BILAN : n PASS, m FAIL » ; sort avec un code non nul au premier FAIL.

set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/75-03-empreinte.XXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/mut.mjs" <<'JS'
// mut.mjs <dossier> <fichier> <de> <vers> [<de> <vers> ...] : retouche chaque occurrence UNIQUE ; sort 2 si une chaîne manque ou n'est pas unique
import fs from 'node:fs';
const [, , dir, fichier, ...paires] = process.argv;
let t = fs.readFileSync(`${dir}/${fichier}`, 'utf8');
for (let i = 0; i < paires.length; i += 2) {
  if (t.split(paires[i]).length !== 2) { console.error(`introuvable ou multiple : ${paires[i]}`); process.exit(2); }
  t = t.replace(paires[i], () => paires[i + 1]);
}
fs.writeFileSync(`${dir}/${fichier}`, t);
JS

cat > "$WORK/h.mjs" <<'JS'
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , MOD, SCR] = process.argv;
const imp = (d, f) => import(pathToFileURL(path.join(d, f)).href);
const EM = await imp(MOD, 'vf-cockpit-activite-empreinte.mjs');
const CO = await imp(MOD, 'vf-cockpit-activite-collisions.mjs');
const FV = await imp(SCR, 'vf-cockpit-frise-voie.mjs');
const CI = await imp(SCR, 'vf-cockpit-cible.mjs');
const J = JSON.stringify;
const ok = (id, t) => console.log(`PASS — ${id} : ${t}`);
const ko = (id, t, att, obt) => { console.log(`❌ FAIL — ${id} : ${t}`); console.log(`     attendu: ${att}`); console.log(`     obtenu:  ${obt}`); };
const eq = (id, t, obt, att) => (J(obt) === J(att) ? ok(id, t) : ko(id, t, J(att), J(obt)));
const vrai = (id, t, c, obt = '') => (c ? ok(id, t) : ko(id, t, 'vrai', `faux ${obt}`));
async function cas(id, f) { try { await f(); } catch (e) { ko(id, 'exception', 'aucune', String((e && e.stack) || e).split('\n').slice(0, 3).join(' | ')); } }

const HORS = CI.HORS, T = 1e12, H = 3600000;
const ent = (arbre, cible, dernierMs = 0) => ({ arbre, cible, n: 1, dernierMs });
function voie(o) {
  const p = { id: o.id, kind: o.kind ?? 'subagent', session: o.session ?? 's-' + o.id, parent: o.parent ?? null, depth: 1, role: o.role ?? 'vf-coder', background: false, debut: o.debut ?? 0,
    fin: o.fin ?? null, dispatchA: null, fini: o.etat === 'termine', arrete: false, modeles: [], compteurs: {}, jetons: {}, durees: {}, segments: [], evenements: [], enCours: null };
  return FV.projeterVoie(p, { arbre: o.arbre ?? null, etatOfficiel: o.etat ?? 'actif', rattachement: o.rat === undefined ? { dag: 'd', noeud: 'N1', source: 'registre' } : o.rat,
    cibles: { etat: o.etatC ?? 'ok', tronque: o.tronque === true, ecritures: o.e ?? [], lectures: o.l ?? [] } });
}
const ctx = (plus = {}) => ({ cartes: new Set(['src/a.mjs', 'src/b.mjs', 'src/c.mjs', 'src/p.mjs', 'src/d.mjs', 'src/e.mjs', 'last.mjs', HORS]), worktreesVerifies: ['wt-a'], nomPrincipal: 'depot', maintenant: T, ...plus });
const m = (r) => r.marques.map((x) => [x[0], x[1], x[2]]);

await cas('M1', () => {
  const A = voie({ id: 'A', role: 'vf-coder', rat: { dag: 'd', noeud: 'NA', source: 'registre' }, e: [ent(null, 'src/p.mjs', 300), ent(null, 'src/a.mjs', 100)], l: [ent(null, 'src/a.mjs', 50), ent(null, 'src/c.mjs', 60)] });
  const B = voie({ id: 'B', role: 'vf-reviewer', rat: { dag: 'd', noeud: 'NB', source: 'registre' }, e: [ent(null, 'src/p.mjs', 200), ent(null, 'src/b.mjs', 400)] });
  const C = voie({ id: 'C', role: 'vf-auditer', rat: { dag: 'd', noeud: 'NC', source: 'registre' }, l: [ent(null, 'src/p.mjs', 10)] });
  const D = voie({ id: 'D', role: 'gsd-verifier', rat: { dag: 'd', noeud: 'ND', source: 'registre' }, etat: 'termine', fin: T - 3 * H, e: [ent(null, 'src/p.mjs', 5), ent(null, 'src/d.mjs', 5)] });
  const E = voie({ id: 'E', role: 'gsd-planner', rat: { dag: 'd', noeud: 'NE', source: 'registre' }, etat: 'termine', fin: T - 25 * H, e: [ent(null, 'src/e.mjs', 5)] });
  const r = EM.empreinte([A, B, C, D, E], ctx());
  eq('M1', 'priorité en-cours > modifié > lu > fini sur un même chemin ; dernière écriture de la voie active = en-cours ; terminé dans les 24 h = fini ; terminé depuis 25 h = absent', m(r),
    [['src/a.mjs', 'modifie', ['vf-coder · nœud NA']], ['src/b.mjs', 'en-cours', ['vf-reviewer · nœud NB']], ['src/c.mjs', 'lu', ['vf-coder · nœud NA']], ['src/d.mjs', 'fini', ['gsd-verifier · nœud ND']], ['src/p.mjs', 'en-cours', ['vf-coder · nœud NA']]]);
  eq('M1', 'l\'horloge est injectée : sans `maintenant`, une voie terminée n\'est jamais devinée dans la fenêtre', m(EM.empreinte([D], ctx({ maintenant: undefined }))), []);
});

await cas('M2', () => {
  const r = EM.empreinte([voie({ id: 'A', e: [ent(null, 'src/b.mjs', 10)], l: [ent(null, 'src/c.mjs', 99)] })], ctx());
  eq('M2', 'un fichier seulement lu ne devient jamais modifié ni en-cours', m(r), [['src/b.mjs', 'en-cours', ['vf-coder · nœud N1']], ['src/c.mjs', 'lu', ['vf-coder · nœud N1']]]);
});

await cas('M3', () => {
  const a = voie({ id: 'agent-SECRET-001', role: 'vf-coder', rat: { dag: 'd', noeud: 'N7', source: 'registre' }, e: [ent(null, 'src/a.mjs', 1)] });
  const b = voie({ id: 'agent-SECRET-002', role: 'vf-auditer', rat: null, e: [ent(null, 'src/b.mjs', 1)] });
  const c = voie({ id: 'agent-SECRET-003', role: 'vf-reviewer', rat: { dag: 'd', noeud: null, source: 'enfants' }, e: [ent(null, 'src/c.mjs', 1)] });
  const d = voie({ id: 'agent-SECRET-004', role: 'vf-reviewer', arbre: 'wt-a', rat: { dag: 'd', noeud: null, source: 'enfants' }, e: [ent('wt-a', 'src/d.mjs', 1)] });
  const s1 = voie({ id: 'agent-SECRET-005', kind: 'session', session: 'sess-titree', role: 'session', rat: null, e: [ent(null, 'src/e.mjs', 1)] });
  const s2 = voie({ id: 'agent-SECRET-006', kind: 'session', session: 'sess-sans', role: 'session', arbre: 'wt-a', rat: null, e: [ent('wt-a', 'last.mjs', 1)] });
  const r = EM.empreinte([a, b, c, d, s1, s2], ctx({ titres: new Map([['sess-titree', 'Ma session']]) }));
  eq('M3', 'rôle + nœud ; non rattaché dit tel ; arbre ajouté seulement si deux voies vivantes partagent le rôle ; session = titre, sinon « session · arbre »',
    Object.fromEntries(r.marques.map((x) => [x[0], x[2][0]])),
    { 'last.mjs': 'session · wt-a', 'src/a.mjs': 'vf-coder · nœud N7', 'src/b.mjs': 'vf-auditer · non rattaché', 'src/c.mjs': 'vf-reviewer · depot', 'src/d.mjs': 'vf-reviewer · wt-a', 'src/e.mjs': 'Ma session' });
  vrai('M3', 'l\'identifiant brut n\'apparaît nulle part dans la sortie', !J(r).includes('SECRET'), J(r).slice(0, 200));
});

await cas('M4', () => {
  const v = voie({ id: 'A', etatC: 'en-construction', e: [ent(null, 'src/a.mjs', 1)] });
  const r = EM.empreinte([v], ctx());
  eq('M4', 'en construction : état dit, marques connues conservées, jamais un compte vide présenté comme complet', [r.etat, r.incomplet, r.limite.includes('en-construction'), m(r).length], ['en-construction', true, true, 1]);
  const t = EM.empreinte([voie({ id: 'A', e: [ent(null, 'src/a.mjs', 1)] })], ctx({ friseTronque: true }));
  eq('M4', 'historique tronqué : état tronque, radar dit incomplet', [t.etat, t.incomplet, t.limite.includes('tronque')], ['tronque', true, true]);
  eq('M4', 'complet : état ok, rien d\'incomplet', (({ etat, incomplet }) => [etat, incomplet])(EM.empreinte([voie({ id: 'A', e: [ent(null, 'src/a.mjs', 1)] })], ctx())), ['ok', false]);
});

await cas('M5', () => {
  const long = 'd/' + 'f'.repeat(117) + '…';
  const v = voie({ id: 'A', e: [ent(null, 'src/a.mjs', 9), ent(null, 'zz/inconnu.mjs', 8), ent(null, HORS, 7), ent('fantome', 'src/a.mjs', 6), ent(null, long, 5), ent(null, '../x', 4)] });
  const r = EM.empreinte([v], ctx());
  eq('M5', 'compteurs exacts : hors carte, hors du lab (sentinelle + worktree absent), coupées, rejetées', [r.horsCarte, r.horsLab, r.coupees, r.rejetes], [1, 2, 1, 1]);
  eq('M5', 'limite : écritures par commande non vues, toujours présente', r.limite[0], 'ecritures-par-commande-non-vues');
  vrai('M5', 'aucun chemin hors carte, hors lab, coupé ou rejeté dans la sortie', !J(r).includes('inconnu') && !J(r).includes('fantome') && !J(r).includes('../x') && !J(r).includes('ffff'));
});

await cas('M6', () => {
  const noms = ['__proto__', 'fil', 'messages'];
  const vs = noms.map((n, i) => voie({ id: 'v' + i, role: n, e: [ent(null, ['src/a.mjs', 'src/b.mjs', 'src/c.mjs'][i], 1)] }));
  const r = EM.empreinte(vs, ctx()), cles = new Set();
  const parcours = (x) => { if (Array.isArray(x)) x.forEach(parcours); else if (x && typeof x === 'object') for (const k of Object.keys(x)) { cles.add(k); parcours(x[k]); } };
  parcours(JSON.parse(J(r)));
  eq('M6', 'les clés de la sortie sont fixes ; un rôle hostile reste une valeur', [[...cles].sort(), r.marques.map((x) => x[2][0])],
    [['etat', 'horsCarte', 'horsLab', 'ignorees', 'incomplet', 'limite', 'marques', 'rejetes', 'voiesTronquees', 'coupees'].sort(), ['__proto__ · nœud N1', 'fil · nœud N1', 'messages · nœud N1']]);
  eq('M6', 'forme [chemin, degré, [noms]]', r.marques[0], ['src/a.mjs', 'en-cours', ['__proto__ · nœud N1']]);
});

await cas('M7', () => {
  const v = { ...voie({ id: 'A', e: [ent(null, 'src/a.mjs', 1), ent(null, 'src/MARQ-7f3a/x.mjs', 2)] }), entree: { file_path: 'MARQ-ARG-7f3a', content: 'MARQ-ARG-7f3a' }, sortie: 'MARQ-ARG-7f3a' };
  const r = EM.empreinte([v], ctx({ cartes: new Set(['src/a.mjs', 'src/MARQ-7f3a/x.mjs']) }));
  vrai('M7', 'aucun champ ni argument d\'outil, aucune sortie d\'outil dans la sortie', !J(r).includes('MARQ-ARG'), J(r));
  vrai('M7b', 'le même marqueur placé dans un chemin cible légitime apparaît bien (le témoin n\'est pas vert à vide)', J(r).includes('MARQ-7f3a'));
});

await cas('M8', () => {
  const vs = Array.from({ length: 2001 }, (_, i) => voie({ id: 'v' + i, e: [ent(null, i === 2000 ? 'last.mjs' : `src/z${i}.mjs`, 1)] }));
  const r = EM.empreinte(vs, ctx());
  eq('M8', '2 001 voies : 2 000 traitées, la dernière jamais lue, voiesTronquees vrai', [r.voiesTronquees, m(r).some((x) => x[0] === 'last.mjs'), r.horsCarte], [true, false, 2000]);
  eq('M8', '2 000 voies : rien de tronqué', EM.empreinte(vs.slice(0, 2000), ctx()).voiesTronquees, false);
});

await cas('M9', () => {
  const r = EM.empreinte([voie({ id: 'A', arbre: 'wt-a', e: [ent('wt-a', 'src/a.mjs', 1)] })], ctx());
  eq('M9', 'un worktree vérifié hors du dossier du lab est vu et jamais compté hors du lab', [r.horsLab, m(r).map((x) => x[0])], [0, ['src/a.mjs']]);
});

await cas('K1', () => {
  const P = voie({ id: 'P', e: [ent(null, 'src/a.mjs', 1)] }), W = voie({ id: 'W', role: 'vf-reviewer', arbre: 'wt-a', e: [ent('wt-a', 'src/a.mjs', 2)] });
  const r = CO.collisionsAgents([P, W], ctx());
  eq('K1', 'deux arbres, même cible : signal arbres, jamais agents', r.collisions.map((x) => [x[0], x[1], x[2], x[3]]), [['src/a.mjs', 'arbres', ['vf-coder · nœud N1', 'vf-reviewer · nœud N1'], null]]);
  eq('K1', 'un des deux worktrees supprimé : plus de signal', CO.collisionsAgents([P, W], ctx({ worktreesVerifies: [] })).collisions, []);
  eq('K1', 'les deux voies terminées dans la fenêtre : le signal reste tant que les worktrees existent', CO.collisionsAgents([{ ...P, etatOfficiel: 'termine', fin: T - H }, { ...W, etatOfficiel: 'termine', fin: T - H }], ctx()).collisions.map((x) => x[1]), ['arbres']);
});

await cas('K2', () => {
  const A = voie({ id: 'A', e: [ent(null, 'src/a.mjs', 1)] }), B = voie({ id: 'B', role: 'vf-reviewer', e: [ent(null, 'src/a.mjs', 2)] });
  eq('K2', 'même arbre, deux voies vivantes non parent-enfant : agents', CO.collisionsAgents([A, B], ctx()).collisions.map((x) => [x[1], x[2]]), [['agents', ['vf-coder · nœud N1', 'vf-reviewer · nœud N1']]]);
  eq('K2', 'parent et enfant : aucune collision', CO.collisionsAgents([A, { ...B, parent: 'A' }], ctx()).collisions, []);
  const G = voie({ id: 'G', role: 'vf-auditer', parent: 'B', e: [ent(null, 'src/a.mjs', 3)] });
  eq('K2', 'petit-enfant et aïeul : aucune collision', CO.collisionsAgents([A, { ...B, parent: 'A' }, G], ctx()).collisions, []);
  eq('K2', 'une des deux terminée : aucune collision', CO.collisionsAgents([A, { ...B, etatOfficiel: 'termine', fin: T - H }], ctx()).collisions, []);
});

await cas('K3', () => {
  const A = voie({ id: 'A', e: [ent(null, 'src/a.mjs', 1)] }), B = voie({ id: 'B', role: 'vf-reviewer', l: [ent(null, 'src/a.mjs', 2)] }), C = voie({ id: 'C', role: 'vf-auditer', l: [ent(null, 'src/a.mjs', 3)] });
  eq('K3', 'une lecture et une écriture : aucune collision', CO.collisionsAgents([A, B], ctx()).collisions, []);
  eq('K3', 'deux lectures : aucune collision', CO.collisionsAgents([B, C], ctx()).collisions, []);
});

await cas('K4', () => {
  const pl = (p, vague, touched, plus = {}) => ({ p: `ph/${p}-PLAN.md`, n: 'phase-75', st: 'todo', vague, touched, ...plus });
  const r = CO.collisionsPlans([pl('75-01', 1, ['x.mjs', 'y.mjs']), pl('75-02', 1, ['x.mjs']), pl('75-03', 2, ['x.mjs'])]);
  eq('K4', 'deux plans non faits de la même vague : collision avec la vague ; vague différente : aucune', r.collisions, [['x.mjs', 'plans', ['75-01-PLAN.md', '75-02-PLAN.md'], 1]]);
  eq('K4', 'un plan fait est exclu', CO.collisionsPlans([pl('75-01', 1, ['x.mjs']), pl('75-02', 1, ['x.mjs'], { st: 'done' })]).collisions, []);
  eq('K4', 'phases différentes, même vague : aucune', CO.collisionsPlans([pl('75-01', 1, ['x.mjs']), pl('76-01', 1, ['x.mjs'], { n: 'phase-76' })]).collisions, []);
  const s = CO.collisionsPlans([pl('75-01', null, ['x.mjs']), pl('75-02', null, ['x.mjs'])]);
  eq('K4', 'vague absente : plan ignoré et compté sansVague, jamais devinée', [s.collisions, s.sansVague], [[], 2]);
  eq('K4', 'un chemin rejeté (..) n\'entre jamais, il est compté', (({ collisions, rejetes }) => [collisions, rejetes])(CO.collisionsPlans([pl('75-01', 1, ['../x']), pl('75-02', 1, ['../x'])])), [[], 2]);
});

await cas('K5', () => {
  const A = voie({ id: 'A', role: '__proto__', e: [ent(null, 'src/a.mjs', 1)] }), B = voie({ id: 'B', role: 'fil', e: [ent(null, 'src/a.mjs', 2)] });
  const r = CO.collisionsAgents([A, B], ctx());
  eq('K5', 'tuples [chemin, source, [noms], vague|null] ; noms hostiles en valeurs', [r.collisions, Object.keys(r).sort()],
    [[['src/a.mjs', 'agents', ['__proto__ · nœud N1', 'fil · nœud N1'], null]], ['collisions', 'coupees', 'horsCarte', 'horsLab', 'ignorees', 'incomplet', 'raisons', 'rejetes', 'voiesTronquees'].sort()]);
  eq('K5', 'complet : incomplet faux', r.incomplet, false);
  const c = CO.collisionsAgents([voie({ id: 'A', etatC: 'en-construction', e: [ent(null, 'src/a.mjs', 1)] })], ctx());
  eq('K5', 'en construction : incomplet, raison en-construction, jamais « aucune collision »', [c.collisions, c.incomplet, c.raisons], [[], true, ['en-construction']]);
  const k = CO.collisionsAgents([voie({ id: 'A', e: [ent(null, 'd/' + 'f'.repeat(117) + '…', 1)] })], ctx());
  eq('K5', 'cible coupée parmi les écritures : incomplet, raison cibles-coupees', [k.incomplet, k.raisons], [true, ['cibles-coupees']]);
});

await cas('K6', () => {
  const A = voie({ id: 'A', e: [ent(null, HORS, 1)] }), B = voie({ id: 'B', role: 'vf-reviewer', e: [ent(null, HORS, 2)] });
  const r = CO.collisionsAgents([A, B], ctx());
  eq('K6', 'deux écritures non prouvées (sentinelle) : aucune collision, comptées à part', [r.collisions, r.horsLab], [[], 2]);
});

await cas('K7', () => {
  const a = voie({ id: 'a', e: [ent(null, 'src/a.mjs', 1)] }), b = voie({ id: 'b', role: 'vf-reviewer', e: [ent(null, 'src/a.mjs', 2)] }), w = voie({ id: 'w', role: 'vf-auditer', arbre: 'wt-a', e: [ent('wt-a', 'src/a.mjs', 3)] });
  eq('K7', 'même cible, même arbre : agents', CO.collisionsAgents([a, b], ctx()).collisions.map((x) => x[1]), ['agents']);
  eq('K7', 'même cible, deux arbres : arbres et JAMAIS agents', CO.collisionsAgents([a, w], ctx()).collisions.map((x) => x[1]), ['arbres']);
  eq('K7', 'deux agents dans un arbre ET un troisième ailleurs : les deux signaux, distincts', CO.collisionsAgents([a, b, w], ctx()).collisions.map((x) => x[1]).sort(), ['agents', 'arbres']);
});
JS

OUT="$WORK/reel.out"
node "$WORK/h.mjs" "$SCRIPTS" "$SCRIPTS" > "$OUT" 2>&1
cat "$OUT"
NB=$(grep -c '^PASS — ' "$OUT"); NF=$(grep -c '^❌ FAIL — ' "$OUT")
if [ "$NF" -gt 0 ] || [ "$NB" -eq 0 ]; then echo "BILAN : $NB PASS, $((NF > 0 ? NF : 1)) FAIL"; exit 1; fi

MU=0
mutant() { # mutant <nom> <témoin attendu rouge> <fichier> <de> <vers> [<de> <vers>]
  local nom="$1" id="$2" f="$3"; shift 3
  local d="$WORK/m-$MU"; MU=$((MU+1)); mkdir -p "$d"
  cp "$SCRIPTS"/vf-cockpit-activite-chemins.mjs "$SCRIPTS"/vf-cockpit-activite-empreinte.mjs "$SCRIPTS"/vf-cockpit-activite-collisions.mjs "$d/"
  if ! node "$WORK/mut.mjs" "$d" "$f" "$@" 2> "$d/err"; then echo "❌ FAIL — MUT : $nom : retouche impossible ($(cat "$d/err"))"; echo "BILAN : $NB PASS, 1 FAIL"; exit 1; fi
  node "$WORK/h.mjs" "$d" "$SCRIPTS" > "$d/out" 2>&1
  if grep -q "^❌ FAIL — $id " "$d/out"; then echo "MUTANT-ROUGE — $nom ($id rouge)"; else echo "❌ FAIL — MUT : $nom : le témoin $id reste vert"; echo "BILAN : $NB PASS, 1 FAIL"; exit 1; fi
}
CH=vf-cockpit-activite-chemins.mjs; EMP=vf-cockpit-activite-empreinte.mjs; COL=vf-cockpit-activite-collisions.mjs

# tâche 2 : empreinte
mutant 'lectures-comptees-en-ecritures' M2 $EMP "ref: { k, sens: 'l', ms: e.dernierMs }" "ref: { k, sens: 'e', ms: e.dernierMs }"
mutant 'identifiant-brut-comme-nom' M3 $EMP "let n = typeof v.role === 'string' && v.role ? propre(v.role) : 'agent';" 'let n = v.id;'
mutant 'fenetre-de-24-h-retiree' M1 $EMP "(v.fin ?? v.debut ?? 0) >= t - FENETRE_MS" 'true'
mutant 'compteur-horsLab-omis' M5 $CH 'compte.horsLab++; continue;' 'continue;'
mutant 'borne-de-2000-voies-retiree' M8 $EMP 'liste.slice(0, VOIES_MAX)' 'liste.slice()'
mutant 'worktree-verifie-compte-horsLab' M9 $CH 'return n === 1;' 'return false;'
# tâche 3 : collisions
mutant 'worktree-supprime-ignore' K1 $CH 'return n === 1;' 'return n <= 1;'
mutant 'exclusion-parent-enfant-retiree' K2 $COL '!liees(p.retenues[a].v, p.retenues[b].v, parId)' 'true'
mutant 'lectures-incluses' K3 $COL 'for (const e of v.cibles.ecritures || []) entrees.push' 'for (const e of [...(v.cibles.ecritures || []), ...(v.cibles.lectures || [])]) entrees.push'
mutant 'vague-ignoree' K4 $COL 'parVague.get(x.vague)' 'parVague.get(0)' 'parVague.set(x.vague, parChemin)' 'parVague.set(0, parChemin)'
mutant 'plan-fait-compte' K4 $COL "x.st === 'done' ||" ''
mutant 'sentinelle-jointe' K6 $CH "if (cible === (contexte.libelleHorsLab ?? HORS_LAB)) return { etat: 'hors-lab', chemin: null };" ''
mutant 'arbres-confondus-un-seul-type' K7 $COL "tuples.push([chemin, 'arbres'," "tuples.push([chemin, 'agents',"
mutant 'arbre-ignore-collision-agents-entre-arbres' K7 $CH 'const cle = e.arbre ?? null;' 'const cle = null;'
mutant 'garde-arbre-admis-retiree' K1 $CH "if (!admis(entree.arbre, contexte)) return { etat: 'hors-lab', chemin: null };" ''

echo "BILAN : $NB PASS, 0 FAIL"
