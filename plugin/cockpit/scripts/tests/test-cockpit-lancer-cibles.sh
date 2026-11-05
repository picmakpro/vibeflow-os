#!/usr/bin/env bash
# test-cockpit-lancer-cibles.sh — cibles lançables et pré-vols des cartes (LANC-04, LANC-08 ; P72-D-05, D-06, D-07, D-12, D-13, D-16).
#   Arguments : (aucun) tout · `cibles` = sondes C, P, Q, PAR, T et leurs mutants · `previols` = sondes B, A, R, X et leurs mutants.
#   C    identité des cartes (ph-<n>, ph-<n>@<compartiment>, dag-<nom>), kind, phase, compartiment, mission rattachée ou hors phase, hors motif
#   P    action principale selon l'état (table), verbes (principal en tête), phase finie
#   Q    projection fermée pour Q : six clés, exclusions par motif, aucun texte du lab
#   PAR  parité des identifiants avec le graphe RÉEL (buildProjectGraph) sur un lab partitionné et un lab plat construits par les vraies lectures
#   T    module pur : moins de 300 lignes, deux dépendances admises, aucun accès système
#   B    bloquants (chacun isolé, 120 combinaisons, `premier-plan-occupe` jamais émis) · A avertissements, récence, `lancee` · R réserve inactive · X lecteurs défaillants
#   M-*  dix mutants (copies du module ET de ses voisins sous $WORK) : M-ID-SANS-WS, M-PRINCIPAL-FIXE, M-HORS-MOTIF-FUITE, M-FAIT-LANCABLE,
#        M-TERMINAL-ARRETE-OUBLIE, M-MISSION-HORS-PHASE-OK, M-AVERT-BLOQUE, M-DEP-IGNORE, M-RECENCE-INFINIE, M-NONCOMMITE-ACTIF. Un mutant sans effet est un FAIL.
# Aucun port, aucun serveur : modules purs, lecteurs littéraux, sauf PAR (vraies lectures sur deux labs jetables). bash 3.2 et bash 5.
# Résultats : N PASS / M FAIL. Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
MOD="$SCRIPTS/vf-cockpit-lancer-cibles.mjs"
ARG="${1:-tout}"
case "$ARG" in tout|cibles|previols) ;; *) echo "argument inconnu : $ARG (tout, cibles, previols)"; exit 2 ;; esac
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX"
cleanup() { [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
PASS=0; FAIL=0
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }

# ---------- lab.mjs : deux labs jetables, vraies lectures (readPlanning, buildProjectGraph) -> $WORK/labs.json ----------
cat > "$AUX/lab.mjs" <<'JS'
// lab.mjs <scripts> <work> : labs jetables (partitionné avec les noms hostiles a$(id) et Alpha : la majuscule seule remplace « Fiabilite », qui désigne le même dossier que « fiabilite » sur un disque insensible à la casse ; plat), vraies lectures, écrit labs.json
import fs from 'node:fs'; import path from 'node:path'; import { execFileSync } from 'node:child_process'; import { pathToFileURL } from 'node:url';
const [, , scripts, work] = process.argv;
const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
const { planningLayout } = await imp('vf-cockpit-paths.mjs'); const { readPlanning } = await imp('vf-cockpit-planning.mjs'); const { buildProjectGraph } = await imp('vf-cockpit-project.mjs');
const wr = (f, t) => { fs.mkdirSync(path.dirname(f), { recursive: true }); fs.writeFileSync(f, t); };
const road = (cases, sections) => `## Phases\n\n${cases}\n\n${sections}\n`;
// --- lab partitionné : fiabilite (72 CONTEXT seul, 73, 74 plan non fait, 75 plan + SUMMARY, 76 cochée), gouvernance (73 plan non fait, 42), noms hostiles ---
const part = path.join(work, 'lab-part'); const B = path.join(part, '.planning', 'workstreams');
wr(path.join(B, 'fiabilite', 'ROADMAP.md'), road(['72: Lancer', '73: Doublon A', '74: Plan non fait', '75: Plan et summary'].map((x) => `- [ ] **Phase ${x}**`).join('\n') + '\n- [x] **Phase 76: Cochee**',
  [['72', 'Lancer', 'texte $(id) du lab'], ['73', 'Doublon A', 'but'], ['74', 'Plan non fait', 'but'], ['75', 'Plan et summary', 'but']].map(([n, t, g]) => `### Phase ${n}: ${t}\n**Goal:** ${g}\n**Depends on**: Phase ${Number(n) - 1}\n`).join('\n')));
wr(path.join(B, 'gouvernance', 'ROADMAP.md'), road('- [ ] **Phase 73: Doublon B**\n- [ ] **Phase 42: Gouvernance**', '### Phase 73: Doublon B\n**Goal:** but\n'));
wr(path.join(B, 'a$(id)', 'ROADMAP.md'), road('- [ ] **Phase 90: Hostile un**', '### Phase 90: Hostile un\n**Goal:** but\n'));
wr(path.join(B, 'Alpha', 'ROADMAP.md'), road('- [ ] **Phase 91: Hostile deux**', '### Phase 91: Hostile deux\n**Goal:** but\n'));
const ph = (ws, d, f) => wr(path.join(B, ws, 'phases', d, f), 'x\n');
ph('fiabilite', 'VFDO-72-lancer', '72-CONTEXT.md');
ph('fiabilite', 'VFDO-74-plan', '74-CONTEXT.md'); ph('fiabilite', 'VFDO-74-plan', '74-01-PLAN.md');
ph('fiabilite', 'VFDO-75-fait', '75-01-PLAN.md'); ph('fiabilite', 'VFDO-75-fait', '75-01-SUMMARY.md');
ph('gouvernance', 'VFDO-73-plan', '73-01-PLAN.md');
wr(path.join(B, 'fiabilite', 'MISSION-72.dag.json'), JSON.stringify({ phase: '72', nodes: [{ id: 'a', status: 'ready', step: 'x' }] }));
wr(path.join(part, '.planning', 'MISSION-LIBRE.dag.json'), JSON.stringify({ nodes: [{ id: 'a', status: 'ready', step: 'x' }] }));
// --- lab plat : trois phases, un DAG nommé MISSION-2 ---
const plat = path.join(work, 'lab-plat'); const P = path.join(plat, '.planning');
wr(path.join(P, 'ROADMAP.md'), road('- [x] Phase 1: Socle\n- [ ] Phase 2: Ecran\n- [ ] Phase 3: Fin', '### Phase 2: Ecran\n**Goal:** but\n**Depends on**: Phase 1\n'));
wr(path.join(P, 'phases', '01-socle', '01-01-PLAN.md'), 'x\n'); wr(path.join(P, 'phases', '01-socle', '01-01-SUMMARY.md'), 'x\n');
wr(path.join(P, 'phases', '02-ecran', '02-CONTEXT.md'), 'x\n');
wr(path.join(P, 'MISSION-2.dag.json'), JSON.stringify({ nodes: [{ id: 'a', status: 'ready', step: 'x' }] }));
for (const lab of [part, plat]) execFileSync('git', ['init', '-q', lab]);
const lire = (lab) => {
  const pl = readPlanning(lab, planningLayout(lab), { sansTags: true });
  const g = buildProjectGraph(lab);
  const fichiers = {};
  for (const p of pl.phases.values()) { const d = pl.phaseDirs.get(`${p.ws || ''}|${p.n}`) || pl.phaseDirs.get(`*|${p.n}`); try { fichiers[p.key] = fs.readdirSync(d); } catch { fichiers[p.key] = []; } }
  const parId = new Map(g.nodes.map((n) => [n.id, n]));
  const ref = g.nodes.filter((n) => n.kind === 'phase' || (n.kind === 'mission' && n.id.startsWith('dag-'))).map((n) => {
    const par = n.kind === 'mission' ? parId.get(n.parent) : n;
    return { id: n.id, kind: n.kind, phase: par && par.kind === 'phase' ? par.num : null, ws: par && par.kind === 'phase' ? par.ws : null };
  });
  return { ref, ids: g.nodes.filter((n) => n.kind === 'phase' || (n.kind === 'mission' && n.id.startsWith('dag-'))).map((n) => n.id).sort(), planning: { phases: [...pl.phases.entries()], dags: pl.dags }, fichiers };
};
fs.writeFileSync(path.join(work, 'labs.json'), JSON.stringify({ part: lire(part), plat: lire(plat) }));
JS

# ---------- cas.mjs : assertions de C, P, Q, PAR, B, A, R, X sur le module chargé depuis <dossier> ; une ligne « PASS|FAIL<TAB>libellé<TAB>attendu<TAB>obtenu » par assertion ----------
cat > "$AUX/cas.mjs" <<'JS'
// cas.mjs <dossier-du-module> <work> <mode> : mode = tout | cibles | previols
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , dir, work, mode] = process.argv;
let M = null;
try { M = await import(pathToFileURL(path.join(dir, 'vf-cockpit-lancer-cibles.mjs')).href); } catch { M = null; }
const LABS = JSON.parse(fs.readFileSync(path.join(work, 'labs.json'), 'utf8'));
const GAB = { MOTIF_PHASE: /^\d+(?:\.\d+)?$/, MOTIF_COMPARTIMENT: /^[a-z0-9][a-z0-9-]{0,39}$/, VERBES: ['cadrer', 'planifier', 'executer', 'verifier', 'reprendre'] };
const CAT = ['phase-finie', 'terminal-absent', 'terminal-arrete', 'premier-plan-occupe', 'claude-introuvable', 'phase-hors-motif', 'compartiment-hors-motif', 'python3-absent', 'mission-hors-phase'];
const T0 = 1_800_000_000_000;
const s = (v) => (typeof v === 'string' ? v : JSON.stringify(v)).replace(/[\t\n]/g, ' ');
const chk = (label, fn, att) => { let obt; try { obt = fn(); } catch (e) { obt = 'exception: ' + String(e && e.message || e).split('\n')[0]; } const a = s(att), o = s(obt); console.log(`${a === o ? 'PASS' : 'FAIL'}\t${label}\t${a}\t${o}`); };
// planning littéral au format de readPlanning
const av = (etat, o = {}) => ({ version: 2, etat, plans: { faits: 0, total: 0 }, correctifs: 0, mission: null, reste: [], ...o });
const ph = (n, ws, etat, o = {}) => ({ key: `${ws || ''}|${n}`, n, ws: ws || null, done: etat === 'fait', depends: [], avancement: av(etat, o.av), ...(o.ph || {}) });
const dag = (name, phaseKey, o = {}) => ({ name, ws: null, phaseKey, etat: 'ready', nodes: [], ...o });
const pl = (phs, dags = []) => ({ phases: new Map(phs.map((p) => [p.key, p])), dags });
const CTX = (planning, o = {}) => ({ gabarit: GAB, planning: () => planning, fichiers: () => [], lancements: () => [], terminal: () => 'actif', claude: () => true, python3: () => true, maintenant: () => T0, ...o });
const calc = (planning, o) => M.calculerCibles(CTX(planning, o));
const par = (r, id) => r.cibles.find((c) => c.id === id);
const ids = (r) => r.cibles.map((c) => c.id);
const VP = (c, id, v) => M.verdict(c.cibles, id, v);
const U = ph('72', 'fiabilite', 'a-faire'), U3f = ph('73', 'fiabilite', 'a-faire'), U3g = ph('73', 'gouvernance', 'a-faire'), U4 = ph('74', 'fiabilite', 'a-faire');
const HP = pl([U4, U3g, U3f, U], [dag('MISSION-72', 'fiabilite|72'), dag('LIBRE', null)]);

const C = () => {
  chk('C0 — le module se charge et exporte les huit noms', () => (M ? ['BLOQUANTS', 'AVERTISSEMENTS', 'AVERTISSEMENTS_RESERVES', 'RECENCE_MS', 'actionPrincipale', 'calculerCibles', 'listePourQ', 'verdict'].filter((k) => !(k in M)) : ['module absent']), []);
  chk('C1 — identifiants : ph-72 (numéro unique), ph-73@<ws> (numéro dans deux compartiments), dag-<nom>, tous uniques, phases par numéro puis compartiment, missions ensuite', () => { const r = calc(HP); return { ids: ids(r), uniques: new Set(ids(r)).size === ids(r).length }; },
    { ids: ['ph-72', 'ph-73@fiabilite', 'ph-73@gouvernance', 'ph-74', 'dag-LIBRE', 'dag-MISSION-72'], uniques: true });
  chk('C2 — kind, phase, ws (null en lab plat)', () => { const r = calc(HP), p = calc(pl([ph('1', null, 'a-faire')])); return [...r.cibles, ...p.cibles].map((c) => [c.id, c.kind, c.phase, c.ws].join(':')); },
    ['ph-72:phase:72:fiabilite', 'ph-73@fiabilite:phase:73:fiabilite', 'ph-73@gouvernance:phase:73:gouvernance', 'ph-74:phase:74:fiabilite', 'dag-LIBRE:mission::', 'dag-MISSION-72:mission:72:fiabilite', 'ph-1:phase:1:']);
  chk('C3 — mission rattachée : phase et compartiment de sa phase, principal et seul verbe reprendre', () => { const c = par(calc(HP), 'dag-MISSION-72'); return [c.phase, c.ws, c.principal, c.verbes]; }, ['72', 'fiabilite', 'reprendre', ['reprendre']]);
  chk('C4 — mission hors phase : bloquant mission-hors-phase, phase et ws null', () => { const c = par(calc(HP), 'dag-LIBRE'); return [c.bloquants, c.phase, c.ws]; }, [['mission-hors-phase'], null, null]);
  chk('C5 — phase hors motif ou compartiment hors motif : phase ou ws null, jamais le texte brut', () => {
    const r = calc(pl([ph('72;touch M', 'fiabilite', 'a-faire'), ph('73', 'a$(id)', 'a-faire'), ph('74', 'Fiabilite', 'a-faire')]));
    return { cibles: r.cibles.map((c) => [c.phase, c.ws, c.bloquants.join('+')].join('|')), brut: JSON.stringify(r).includes('touch') || JSON.stringify(r).includes('$(id)') || JSON.stringify(r).includes('Fiabilite') };
  }, { cibles: ['|fiabilite|phase-hors-motif', '73||compartiment-hors-motif', '74||compartiment-hors-motif'], brut: false });
};

const P = () => {
  const A = M && M.actionPrincipale;
  chk('P1 — table d\'états de actionPrincipale', () => [A(av('a-faire'), []), A(av('a-faire'), ['72-CONTEXT.md']), A(av('a-faire', { plans: { faits: 0, total: 1 } }), ['72-CONTEXT.md', '72-01-PLAN.md']), A(av('en-cours'), []), A(av('a-recetter'), []), A(av('fait'), [])],
    ['cadrer', 'planifier', 'executer', 'executer', 'verifier', null]);
  chk('P1 — au niveau des cartes : archivée et cochée avec avancement a-faire = aucune action', () => {
    const r = calc(pl([ph('77', null, 'a-faire', { ph: { archive: true } }), ph('78', 'fiabilite', 'a-faire', { ph: { done: true } }), ph('79', 'fiabilite', 'fait')]));
    return r.cibles.map((c) => [c.id, c.principal, c.bloquants.join('+')].join(':'));
  }, ['ph-77:null:phase-finie', 'ph-78:null:phase-finie', 'ph-79:null:phase-finie']);
  chk('P2 — verbes : le principal en tête puis les autres dans l\'ordre de la liste fermée', () => { const r = calc(pl([ph('1', 'fiabilite', 'en-cours'), ph('2', 'fiabilite', 'a-recetter')])); return r.cibles.map((c) => c.verbes.join(',')); },
    ['executer,cadrer,planifier,verifier,reprendre', 'verifier,cadrer,planifier,executer,reprendre']);
  chk('P3 — phase fait : principal null, verbes complets, bloquant phase-finie', () => { const c = calc(pl([ph('1', 'fiabilite', 'fait')])).cibles[0]; return [c.principal, c.verbes, c.bloquants]; }, [null, GAB.VERBES, ['phase-finie']]);
};

const bonne = { id: 'ph-72', kind: 'phase', phase: '72', ws: 'fiabilite', principal: 'planifier', verbes: GAB.VERBES, bloquants: [], avertissements: [], lancee: false, titre: 'Texte du lab' };
const miss = { id: 'dag-MISSION-72', kind: 'mission', phase: '72', ws: 'fiabilite', principal: 'reprendre', verbes: ['reprendre'], bloquants: [], avertissements: [], lancee: false, nom: 'Nom du lab' };
const Q = () => {
  chk('Q1 — la projection ne porte que les six clés et aucun texte du lab', () => { const l = M.listePourQ([bonne], GAB); return { cles: Object.keys(l[0] || {}).sort(), n: l.length, texte: JSON.stringify(l).includes('Texte du lab') }; }, { cles: ['id', 'kind', 'phase', 'verbe', 'verbes', 'ws'], n: 1, texte: false });
  chk('Q2 — exclut identifiant, phase ou compartiment hors motif, mission hors phase, phase sans principal, identifiant incohérent, carte déjà marquée hors motif', () => M.listePourQ([
    { ...bonne, ws: 'a$(id)' }, { ...bonne, phase: '72;touch M', id: 'ph-72;touch M' }, { ...miss, id: 'dag-a$(id)' }, { ...miss, id: 'dag-X', phase: null, ws: null }, { ...bonne, principal: null },
    { ...bonne, phase: '73' }, { ...bonne, id: 'ph-90', phase: '90', ws: null, bloquants: ['compartiment-hors-motif'] }, { ...bonne, id: 'ph-91', phase: null, ws: 'fiabilite', bloquants: ['phase-hors-motif'] }, bonne], GAB).map((x) => x.id), ['ph-72']);
  chk('Q3 — cas sains inclus (phase, mission, lab plat), verbe = principal', () => M.listePourQ([bonne, miss, { ...bonne, id: 'ph-1', phase: '1', ws: null, principal: 'cadrer' }], GAB).map((x) => [x.id, x.verbe, x.ws].join(':')), ['ph-72:planifier:fiabilite', 'dag-MISSION-72:reprendre:fiabilite', 'ph-1:cadrer:null']);
};

const PAR = () => {
  const lab = (L) => ({ phases: new Map(L.planning.phases), dags: L.planning.dags });
  const cibles = (L) => M.calculerCibles(CTX(lab(L), { fichiers: (p) => L.fichiers[p.key] || [] }));
  chk('PAR.0 — témoin : le graphe réel des deux labs fixtures porte les identifiants attendus (littéraux)', () => [LABS.part.ids, LABS.plat.ids],
    [['dag-MISSION-72', 'dag-MISSION-LIBRE', 'ph-42', 'ph-72', 'ph-73@fiabilite', 'ph-73@gouvernance', 'ph-74', 'ph-75', 'ph-76', 'ph-90', 'ph-91'], ['dag-MISSION-2', 'ph-1', 'ph-2', 'ph-3']]);
  const ecarts = (L) => { const r = cibles(L); const out = []; for (const n of L.ref) { const c = par(r, n.id); if (!c) { out.push('absente:' + n.id); continue; }
    const okP = /^\d+(?:\.\d+)?$/.test(String(n.phase)) ? n.phase : null, okW = n.ws && /^[a-z0-9][a-z0-9-]{0,39}$/.test(n.ws) ? n.ws : null;
    if (c.kind !== n.kind || c.phase !== okP || c.ws !== okW) out.push(`${n.id}:${c.kind}:${c.phase}:${c.ws}`); } return `refs=${L.ref.length} ecarts=${out.join(',') || 0}`; };
  chk('PAR.1 — chaque nœud phase ou mission du graphe réel a une cible d\'identifiant égal, kind, phase et ws cohérents (lab partitionné puis lab plat)', () => [ecarts(LABS.part), ecarts(LABS.plat)], ['refs=11 ecarts=0', 'refs=4 ecarts=0']);
  chk('PAR.2 — compartiments a$(id) et Alpha (majuscule) : ws null, compartiment-hors-motif, aucun texte brut, exclus de la projection pour Q', () => {
    const r = cibles(LABS.part), txt = JSON.stringify(r), q = M.listePourQ(r.cibles, GAB).map((x) => x.id);
    return { cibles: ['ph-90', 'ph-91'].map((i) => { const c = par(r, i); return [c.ws, c.bloquants.join('+')].join('|'); }), brut: txt.includes('$(id)') || txt.includes('Alpha'), q90: q.includes('ph-90') || q.includes('ph-91'), q72: q.includes('ph-72') };
  }, { cibles: ['|compartiment-hors-motif', '|compartiment-hors-motif'], brut: false, q90: false, q72: true });
  chk('PAR.3 — principaux attendus de la fixture (littéraux)', () => { const r = cibles(LABS.part); return r.cibles.map((c) => `${c.id}=${c.principal}`).join(' '); },
    'ph-42=cadrer ph-72=planifier ph-73@fiabilite=cadrer ph-73@gouvernance=executer ph-74=executer ph-75=verifier ph-76=null ph-90=cadrer ph-91=cadrer dag-MISSION-72=reprendre dag-MISSION-LIBRE=reprendre');
};

// ---- pré-vols ----
const ETATS_T = ['actif', 'arrete', 'indisponible'];
const attendus = (k) => CAT.filter((c) => ({ 'terminal-arrete': k.terminal === 'arrete', 'terminal-absent': k.terminal === 'indisponible', 'claude-introuvable': !k.claude, 'python3-absent': !k.python3, 'phase-finie': k.finie, 'phase-hors-motif': k.phaseHors, 'compartiment-hors-motif': k.wsHors, 'mission-hors-phase': k.horsPhase }[c]));
const B = () => {
  const un = (planning, id, o) => { const r = calc(planning, o); return { r, v: VP(r, id, id.startsWith('dag-') ? 'reprendre' : 'cadrer') }; };
  const sain = HP;
  chk('B1 — contexte sain : aucun bloquant, lancable vrai', () => { const x = un(sain, 'ph-72'); return [x.v.bloquants, x.v.lancable]; }, [[], true]);
  const iso = (label, planning, id, o, code) => chk(`B2 — ${label} : exactement ${code}, lancable faux`, () => { const x = un(planning, id, o); return [x.v.bloquants, x.v.lancable]; }, [[code], false]);
  iso('terminal arrêté', sain, 'ph-72', { terminal: () => 'arrete' }, 'terminal-arrete');
  iso('terminal indisponible', sain, 'ph-72', { terminal: () => 'indisponible' }, 'terminal-absent');
  iso('claude absent', sain, 'ph-72', { claude: () => false }, 'claude-introuvable');
  iso('python3 absent', sain, 'ph-72', { python3: () => false }, 'python3-absent');
  iso('phase finie', pl([ph('72', 'fiabilite', 'fait')]), 'ph-72', {}, 'phase-finie');
  iso('phase hors motif', pl([ph('72;x', 'fiabilite', 'a-faire')]), 'ph-72;x', {}, 'phase-hors-motif');
  iso('compartiment hors motif', pl([ph('72', 'A$b', 'a-faire')]), 'ph-72', {}, 'compartiment-hors-motif');
  iso('mission hors phase', sain, 'dag-LIBRE', {}, 'mission-hors-phase');
  chk('B2 — ordre du catalogue : phase-finie, terminal-arrete, claude-introuvable', () => un(pl([ph('72', 'fiabilite', 'fait')]), 'ph-72', { terminal: () => 'arrete', claude: () => false }).v.bloquants, ['phase-finie', 'terminal-arrete', 'claude-introuvable']);
  const tous = []; let nP = 0, nM = 0;
  for (const terminal of ETATS_T) for (const claude of [true, false]) for (const python3 of [true, false]) {
    for (const finie of [false, true]) for (const phaseHors of [false, true]) for (const wsHors of [false, true]) {
      nP++; const k = { terminal, claude, python3, finie, phaseHors, wsHors };
      tous.push(() => { const id = `ph-${phaseHors ? '72;x' : '72'}`, r = calc(pl([ph(phaseHors ? '72;x' : '72', wsHors ? 'A$b' : 'fiabilite', finie ? 'fait' : 'a-faire')]), { terminal: () => terminal, claude: () => claude, python3: () => python3 });
        const v = VP(r, id, 'cadrer'), att = attendus(k); return [JSON.stringify([...v.bloquants].sort()) === JSON.stringify([...att].sort()), v.lancable === (att.length === 0), v.bloquants]; });
    }
    for (const horsPhase of [false, true]) { nM++; const k = { terminal, claude, python3, horsPhase };
      tous.push(() => { const r = calc(pl([U], [dag('MISSION-72', horsPhase ? null : 'fiabilite|72')]), { terminal: () => terminal, claude: () => claude, python3: () => python3 }); const v = VP(r, 'dag-MISSION-72', 'reprendre'), att = attendus(k);
        return [JSON.stringify([...v.bloquants].sort()) === JSON.stringify([...att].sort()), v.lancable === (att.length === 0), v.bloquants]; }); }
  }
  chk('B3 — 120 combinaisons (96 de phase, 24 de mission) : l\'ensemble des bloquants égale les conditions levées, lancable = aucun bloquant', () => {
    const res = tous.map((f) => f()); return { phase: nP, mission: nM, total: res.length, ensemblesOk: res.filter((x) => x[0]).length, lancableOk: res.filter((x) => x[1]).length };
  }, { phase: 96, mission: 24, total: 120, ensemblesOk: 120, lancableOk: 120 });
  chk('B4 — premier-plan-occupe au catalogue (neuf codes) mais jamais émis sur les 120 combinaisons', () => ({ catalogue: [M.BLOQUANTS.length, M.BLOQUANTS.includes('premier-plan-occupe'), [...M.BLOQUANTS].sort().join() === [...CAT].sort().join()], emis: tous.map((f) => f()[2]).flat().includes('premier-plan-occupe') }), { catalogue: [9, true, true], emis: false });
};

const lancee = (extra, o = {}) => ph('72', 'fiabilite', 'a-faire', extra);
const A = () => {
  const warn = (planning, id, o) => { const r = calc(planning, o); return [par(r, id).avertissements, VP(r, id, id.startsWith('dag-') ? 'reprendre' : 'cadrer').lancable]; };
  const p71 = (etat, extra) => ph('71', 'fiabilite', etat, extra);
  const dep = (etat) => pl([p71(etat), ph('72', 'fiabilite', 'a-faire', { ph: { depends: ['71'] } })]);
  chk('A1 — chaque avertissement isolé donne exactement son code et lancable reste vrai', () => [
    warn(dep('a-faire'), 'ph-72'), warn(pl([lancee({ av: { mission: { nom: 'M', etat: 'running', vie: null } } })]), 'ph-72'), warn(pl([lancee({ av: { ailleurs: { arbre: 'x', branche: 'b' } } })]), 'ph-72'),
    warn(pl([U]), 'ph-72', { lancements: () => [{ cible: 'ph-72', verbe: 'cadrer', at: T0 - 1000 }] }),
    warn(pl([U], [dag('MISSION-72', 'fiabilite|72', { etat: 'running' })]), 'dag-MISSION-72'), warn(dep('a-faire'), 'ph-72')[1]],
  [[['dependance-non-close'], true], [['mission-vivante'], true], [['phase-plus-avancee-ailleurs'], true], [['lancement-recent'], true], [['mission-vivante'], true], true]);
  chk('A2 — dépendance close, introuvable, ou ambiguë entre deux autres compartiments : aucun avertissement', () => [
    warn(dep('fait'), 'ph-72')[0], warn(pl([ph('72', 'fiabilite', 'a-faire', { ph: { depends: ['99'] } })]), 'ph-72')[0],
    warn(pl([ph('71', 'alpha', 'a-faire'), ph('71', 'beta', 'a-faire'), ph('72', 'fiabilite', 'a-faire', { ph: { depends: ['71'] } })]), 'ph-72')[0]], [[], [], []]);
  const r = (at, cible = 'ph-72', v = 'cadrer') => warn(pl([U]), 'ph-72', { lancements: () => [{ cible, verbe: v, at }] })[0];
  chk('A3 — fenêtre de récence : RECENCE_MS = 900000, oui à RECENCE_MS moins une milliseconde, non au-delà, lancement futur ignoré, autre cible ignorée', () => [M.RECENCE_MS, r(T0 - 899999), r(T0 - 900001), r(T0 + 5000), r(T0 - 1000, 'ph-73')],
    [900000, ['lancement-recent'], [], [], []]);
  chk('A4 — lancee vrai dès qu\'un lancement de la cible existe, même hors fenêtre ; faux pour une autre cible', () => { const f = (reg) => par(calc(pl([U]), { lancements: () => reg }), 'ph-72').lancee; return [f([{ cible: 'ph-72', verbe: 'cadrer', at: T0 - 99999999 }]), f([{ cible: 'ph-73', verbe: 'cadrer', at: T0 }]), f([])]; }, [true, false, false]);
  chk('A5 — les quatre avertissements ensemble, dans l\'ordre du catalogue, ne rendent jamais lancable faux', () => warn(pl([p71('a-faire'), ph('72', 'fiabilite', 'a-faire', { ph: { depends: ['71'] }, av: { mission: { nom: 'M', etat: 'running', vie: null }, ailleurs: { arbre: 'x' } } })]), 'ph-72', { lancements: () => [{ cible: 'ph-72', verbe: 'cadrer', at: T0 - 5 }] }),
    [['dependance-non-close', 'mission-vivante', 'phase-plus-avancee-ailleurs', 'lancement-recent'], true]);
};

const R = () => {
  let appels = 0; const lecteur = () => { appels++; return true; };
  chk('R1 — travailNonCommite fourni et renvoyant vrai n\'est JAMAIS appelé, aucun travail-non-commite émis', () => { const r = calc(HP, { travailNonCommite: lecteur }); return { appels, emis: JSON.stringify(r).includes('travail-non-commite') }; }, { appels: 0, emis: false });
  chk('R2 — le code est dans AVERTISSEMENTS_RESERVES, absent de AVERTISSEMENTS et de BLOQUANTS', () => [M.AVERTISSEMENTS_RESERVES.includes('travail-non-commite'), M.AVERTISSEMENTS.includes('travail-non-commite'), M.BLOQUANTS.includes('travail-non-commite'), M.AVERTISSEMENTS.length], [true, false, false, 4]);
};

const X = () => {
  const boom = () => { throw new Error('lecteur en panne'); };
  chk('X1 — planning qui lève ou rend une forme inattendue : aucune cible, contexte.planning faux', () => [calc(null, { planning: boom }), calc(null, { planning: () => null }), calc(null, { planning: () => ({ phases: 3 }) })].map((r) => [r.cibles.length, r.contexte.planning]), [[0, false], [0, false], [0, false]]);
  chk('X2 — terminal, claude ou python3 qui lèvent : les bloquants correspondants, sans exception', () => [calc(HP, { terminal: boom }), calc(HP, { claude: boom }), calc(HP, { python3: boom })].map((r) => par(r, 'ph-72').bloquants), [['terminal-absent'], ['claude-introuvable'], ['python3-absent']]);
  chk('X3 — registre des lancements qui lève : aucun avertissement de récence, lancee faux', () => { const c = par(calc(HP, { lancements: boom }), 'ph-72'); return [c.avertissements, c.lancee]; }, [[], false]);
  chk('X4 — lecteur fichiers qui lève pour une phase : traité comme dossier vide', () => { const r = calc(HP, { fichiers: boom }); return [par(r, 'ph-72').principal, r.cibles.length]; }, ['cadrer', 6]);
};
const SECTIONS = { cibles: [C, P, Q, PAR], previols: [B, A, R, X] };
for (const sec of mode === 'tout' ? [...SECTIONS.cibles, ...SECTIONS.previols] : SECTIONS[mode]) { try { sec(); } catch (e) { console.log(`FAIL\t${sec.name} — section interrompue\t-\t${String(e && e.message || e).split('\n')[0]}`); } }
JS

# ---------- lecture des sorties de cas.mjs : une assertion par ligne ----------
lire_cas() { # lire_cas <dossier-du-module> <mode> : joue assert_eq sur chaque ligne ; remplit CAS_FAILS (sondes en échec, séparées par des espaces)
  local st lib att obt out; CAS_FAILS=""; out="$WORK/cas.out"; node "$AUX/cas.mjs" "$1" "$WORK" "$2" > "$out" 2>"$WORK/cas.err"
  if [ ! -s "$out" ]; then assert_eq "cas.mjs n'a rien produit ($(head -c 200 "$WORK/cas.err" | tr '\n' ' '))" "vide" "des assertions"; return; fi
  while IFS=$'\t' read -r st lib att obt; do
    if [ "$st" = "FAIL" ]; then CAS_FAILS="$CAS_FAILS ${lib%% *}"; fi
    assert_eq "$lib" "$obt" "$att"
  done < "$out"
}
lire_silencieux() { # même lecture sans assertion : CAS_FAILS seul (mutants)
  local st lib att obt; CAS_FAILS=""; node "$AUX/cas.mjs" "$1" "$WORK" "$2" 2>"$WORK/cas.err" > "$WORK/mut.out"
  while IFS=$'\t' read -r st lib att obt; do [ "$st" = "FAIL" ] && CAS_FAILS="$CAS_FAILS ${lib%% *}"; done < "$WORK/mut.out"
  CAS_FAILS="$(printf '%s\n' $CAS_FAILS | sort -u | tr '\n' ' ')"
}

node "$AUX/lab.mjs" "$SCRIPTS" "$WORK" 2>"$WORK/lab.err" || { echo "lab.mjs a échoué : $(head -c 300 "$WORK/lab.err")"; exit 2; }

if [ "$ARG" != previols ]; then
  echo "=== C, P, Q, PAR — cibles : identité, action principale, projection fermée, parité avec le graphe réel ==="
fi
if [ "$ARG" = tout ]; then lire_cas "$SCRIPTS" tout
elif [ "$ARG" = cibles ]; then lire_cas "$SCRIPTS" cibles
else echo "=== B, A, R, X — pré-vols : bloquants, avertissements, réserve inactive, lecteurs défaillants ==="; lire_cas "$SCRIPTS" previols; fi

# ---------- T — module pur ----------
if [ "$ARG" != previols ]; then
  echo "=== T — module pur, borné, deux dépendances ==="
  T1="absent"
  if [ -f "$MOD" ]; then
    T1="$(awk 'BEGIN{n=0} /^import /{ if ($0 !~ /from .\.\/vf-cockpit-(avancement|lecture)\.mjs./) n++ } /import\(|require\(|process\.|Date\.|Math\.random|node:|readFileSync/{n++} END{ printf "%s lignes=%s", (n==0 && NR>0 && NR<300) ? "ok" : "ko(violations=" n ")", NR }' "$MOD")"
    T1="${T1%% *}"
  fi
  assert_eq "T1 — le module existe, moins de 300 lignes, seules dépendances vf-cockpit-avancement.mjs et vf-cockpit-lecture.mjs, aucun accès système, horloge, hasard ni environnement" "$T1" "ok"
fi

# ---------- mutants : copies du module ET de ses voisins sous $WORK/mut-<nom>/ ----------
mut_dir() { local d="$WORK/mut-$1"; rm -rf "$d"; mkdir -p "$d"; cp "$SCRIPTS"/vf-cockpit-*.mjs "$d/" 2>/dev/null; echo "$d"; }
MUT_OK=""
mutant_const() { # mutant_const <nom> <CONSTANTE> <valeur> : remplace la ligne entière « export const CONSTANTE = … » ; MUT_OK=oui si la copie a changé
  local d f; d="$(mut_dir "$1")"; f="$d/vf-cockpit-lancer-cibles.mjs"; MUT_OK=""; MUT_D="$d"
  [ -f "$f" ] || return 1
  grep -q "^export const $2 = " "$f" || return 1
  sed "s|^export const $2 = .*|export const $2 = $3;|" "$f" > "$f.m" && mv "$f.m" "$f"
  cmp -s "$f" "$MOD" && return 1; MUT_OK=oui; return 0
}
mutant_fn() { # mutant_fn <nom> <fonction> <enveloppe JS> : l'original est renommé <fonction>_orig, l'enveloppe exportée est ajoutée en fin de fichier
  local d f; d="$(mut_dir "$1")"; f="$d/vf-cockpit-lancer-cibles.mjs"; MUT_OK=""; MUT_D="$d"
  [ -f "$f" ] || return 1
  grep -q "^export function $2(" "$f" || return 1
  sed "s|^export function $2(|export function ${2}_orig(|" "$f" > "$f.m" && mv "$f.m" "$f"
  printf '\n%s\n' "$3" >> "$f"; MUT_OK=oui; return 0
}
sans_effet() { assert_eq "$1 — mutant sans effet (ancre absente ou copie inchangée)" "sans effet" "effet"; }
tue() { # tue <nom> <mode> <sondes requises, séparées par des espaces> <description> : le mutant doit rougir TOUTES les sondes requises
  lire_silencieux "$MUT_D" "$2"; local r="" x; for x in $3; do case " $CAS_FAILS" in *" $x "*) r="$r $x";; esac; done
  assert_eq "$1 — $4 ; rouge sur$CAS_FAILS" "${r# }" "$3"
}
filtre() { echo "export function calculerCibles(l) { const r = calculerCibles_orig(l); return { ...r, cibles: r.cibles.map((c) => ({ ...c, $1 })) }; }"; }
if [ "$ARG" != previols ]; then
  echo "=== M-* — mutants des cibles ==="
  if mutant_fn idsansws calculerCibles "export function calculerCibles(l) { const r = calculerCibles_orig(l); return { ...r, cibles: r.cibles.map((c) => ({ ...c, id: c.id.replace(/@.*\$/, '') })) }; }"; then tue M-ID-SANS-WS cibles "C1 PAR.1" "le suffixe @<compartiment> disparaît des identifiants : doublon ph-73 et parité rompue"; else sans_effet M-ID-SANS-WS; fi
  if mutant_fn principalfixe actionPrincipale "export function actionPrincipale(a, f) { const r = actionPrincipale_orig(a, f); return a && a.etat === 'fait' ? r : 'executer'; }"; then tue M-PRINCIPAL-FIXE cibles "P1" "l'action principale vaut toujours executer sauf pour fait"; else sans_effet M-PRINCIPAL-FIXE; fi
  if mutant_fn horsmotiffuite listePourQ "export function listePourQ(c, g) { return c; }"; then tue M-HORS-MOTIF-FUITE cibles "Q1 Q2 Q3" "la projection rend toutes les cibles sans exclusion ni réduction"; else sans_effet M-HORS-MOTIF-FUITE; fi
fi
if [ "$ARG" != cibles ]; then
  echo "=== M-* — mutants des pré-vols ==="
  if mutant_fn faitlancable calculerCibles "$(filtre "bloquants: c.bloquants.filter((b) => b !== 'phase-finie')")"; then tue M-FAIT-LANCABLE previols "B2 B3" "phase-finie retiré de tous les bloquants"; else sans_effet M-FAIT-LANCABLE; fi
  if mutant_fn terminalarretemanque calculerCibles "$(filtre "bloquants: c.bloquants.filter((b) => b !== 'terminal-arrete')")"; then tue M-TERMINAL-ARRETE-OUBLIE previols "B2 B3" "terminal-arrete retiré de tous les bloquants"; else sans_effet M-TERMINAL-ARRETE-OUBLIE; fi
  if mutant_fn missionhorsphaseok calculerCibles "$(filtre "bloquants: c.bloquants.filter((b) => b !== 'mission-hors-phase')")"; then tue M-MISSION-HORS-PHASE-OK previols "B2 B3" "mission-hors-phase retiré de tous les bloquants"; else sans_effet M-MISSION-HORS-PHASE-OK; fi
  if mutant_fn avertbloque verdict "export function verdict(c, i, v) { const r = verdict_orig(c, i, v); return r && { ...r, lancable: r.lancable && r.avertissements.length === 0 }; }"; then tue M-AVERT-BLOQUE previols "A1 A5" "un avertissement rend lancable faux"; else sans_effet M-AVERT-BLOQUE; fi
  if mutant_fn depignore calculerCibles "$(filtre "avertissements: c.avertissements.filter((b) => b !== 'dependance-non-close')")"; then tue M-DEP-IGNORE previols "A1 A5" "dependance-non-close retiré de tous les avertissements"; else sans_effet M-DEP-IGNORE; fi
  if mutant_const recenceinfinie RECENCE_MS Infinity; then tue M-RECENCE-INFINIE previols "A3" "la fenêtre de récence n'a plus de fin"; else sans_effet M-RECENCE-INFINIE; fi
  if mutant_fn noncommiteactif calculerCibles "export function calculerCibles(l) { const r = calculerCibles_orig(l); if (typeof l.travailNonCommite === 'function' && l.travailNonCommite() === true) r.cibles.forEach((c) => c.avertissements.push('travail-non-commite')); return r; }"; then tue M-NONCOMMITE-ACTIF previols "R1" "le lecteur est appelé et l'avertissement réservé s'émet"; else sans_effet M-NONCOMMITE-ACTIF; fi
fi

echo ""
echo "Résultats : $PASS PASS / $FAIL FAIL"
[ "$FAIL" -eq 0 ]
