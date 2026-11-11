#!/usr/bin/env bash
# test-cockpit-index.sh — index incrémental des transcripts de Claude Code (C1, vibeflow/cockpit-index@1 ; P79-D-03, P79-D-13, P79-D-29 ; SOCL-12)
#   I0 modules et fixture · I1 une passe, fichier, trois lectures · I2 réduction (jetons, segments typés, durées, événements, compteurs, appels ouverts, sous-agents, lab, forme inconnue,
#   versions, ligne géante, alternance A-B-A) · I5 reprise depuis zéro · I8 fenêtre de 24 h et rétention (état officiel seul)
# Le code testé est celui du dossier de ce script (jamais un code installé). Valeurs attendues écrites à la main ; instants relatifs à T0 = 2026-11-01T09:00:00Z.
# Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
FIX="$SCRIPTS/tests/fixtures/test-cockpit-index"
WORK="$(mktemp -d)"; [ -n "${VF_GARDER_WORK:-}" ] || trap 'rm -rf "$WORK"' EXIT; WORK="$(cd "$WORK" && pwd -P)"
[ -n "${VF_GARDER_WORK:-}" ] && echo "WORK=$WORK" >&2
AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/lab"
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }

cat > "$AUX/get.mjs" <<'JS'
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const v = new Function('j', 'return (' + process.argv[3] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/cas.mjs" <<'JS'
// cas.mjs <scripts> <work> <fixtures> : joue les scénarios I0 à I8 et imprime { identifiant: valeur } (valeurs jugées par la suite, jamais ici)
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , SC, WORK, FIX] = process.argv; const R = {}; const T0 = Date.parse('2026-11-01T09:00:00Z'), H = 3600e3, LAB = path.join(WORK, 'lab');
const sessionFx = fs.readFileSync(path.join(FIX, 'projects', '-lab', 'sess-aaaa0001.jsonl'), 'utf8');
R['I0.2'] = ['MARQ-TEXTE', 'MARQ-COMMANDE', 'MARQ-CIBLE', 'MARQ-SORTIE', 'MARQ-TUR'].map((k) => (sessionFx.includes(k) ? 1 : 0)).join(',');
let M; try { const imp = (n) => import(pathToFileURL(path.join(SC, n)).href); M = { jet: await imp('vf-cockpit-jetons.mjs'), voie: await imp('vf-cockpit-index-voie.mjs'), cache: await imp('vf-cockpit-index-cache.mjs'), idx: await imp('vf-cockpit-index.mjs') }; R['I0.1'] = 'ok'; }
catch { R['I0.1'] = 'module absent'; console.log(JSON.stringify(R)); process.exit(0); }
const CC = JSON.parse(fs.readFileSync(path.join(SC, 'vf-cockpit-interface.json'), 'utf8')).claudeCode;
const arbreDe = (cwd) => (cwd === LAB ? { arbre: null } : cwd === LAB + '/wt-a' ? { arbre: 'wt-a' } : null);
const O = (x = {}) => ({ maintenant: T0 + H, arbreDe, memoHors: new Map(), CC, ...x });
const ls = (n) => ({ ...n });
const us = (i, o, cr = 0, cc = 0) => ({ input_tokens: i, output_tokens: o, cache_read_input_tokens: cr, cache_creation_input_tokens: cc });
const base = (id, t, o, cwd = LAB) => ({ cwd, sessionId: id, version: '2.1.322', timestamp: new Date(T0 + t).toISOString(), ...o });
const u = (id, t, content = 'x', x = {}) => base(id, t, { type: 'user', message: { role: 'user', content }, ...x });
const a = (id, t, mid, usage, content = [{ type: 'text', text: 'x' }], stop = null) => base(id, t, { type: 'assistant', message: { id: mid, model: 'claude-test-1', stop_reason: stop, usage, content } });
const appel = (cid, name) => ({ type: 'tool_use', id: cid, name, input: {} });
const res = (cid, err) => ({ type: 'tool_result', tool_use_id: cid, ...(err ? { is_error: true } : {}), content: 'x' });
const sys = (id, t, sub, x = {}) => base(id, t, { type: 'system', subtype: sub, ...x });
let n = 0;
function mk(lignes, { id = `sess-t${String(++n).padStart(4, '0')}`, mtime } = {}) { // un dossier de projets jetable avec un transcript
  const dir = path.join(WORK, `p-${id}`, 'projects', '-lab'); fs.mkdirSync(dir, { recursive: true });
  const f = path.join(dir, id + '.jsonl'); fs.writeFileSync(f, lignes(id).map((l) => (typeof l === 'string' ? l : JSON.stringify(l))).join('\n') + '\n');
  const t = (mtime ?? T0 + 600e3) / 1000; fs.utimesSync(f, t, t); return { projets: path.join(WORK, `p-${id}`, 'projects'), id, f };
}
const voieDe = (m, opts = {}) => M.idx.construire(M.idx.enumerer(m.projets), O(opts)).voies.find((v) => v.id === m.id);
const rel = (v) => v && v.segments ? v.segments.map(([d, f, g]) => [d - T0, f - T0, g]) : v?.segments;
const seg = (lignes) => JSON.stringify(rel(voieDe(mk((id) => lignes(id)))));
const strip = (i) => { const c = JSON.parse(JSON.stringify(i)); delete c.genereA; return JSON.stringify(c); };

// ---- projets de fixtures
const inst = (nom) => {
  const dest = path.join(WORK, nom, 'projects'); fs.cpSync(path.join(FIX, 'projects'), dest, { recursive: true });
  const walk = (d) => { for (const e of fs.readdirSync(d, { withFileTypes: true })) { const p = path.join(d, e.name); if (e.isDirectory()) walk(p); else { fs.writeFileSync(p, fs.readFileSync(p, 'utf8').replaceAll('@LAB@', LAB).replaceAll('@AUTRE@', path.join(WORK, 'autre'))); const t = (e.name.startsWith('sess-cccc') ? T0 - 30 * H + 6000 : T0 + H) / 1000; fs.utimesSync(p, t, t); } } };
  walk(dest); return dest;
};
const fixtures = inst('fx');
const cands = M.idx.enumerer(fixtures); const memo = new Map();
const idxFx = M.idx.construire(cands, O({ memoHors: memo })); const par = (i, id) => i.voies.find((v) => v.id === id);
const s1 = par(idxFx, 'sess-aaaa0001'); const pick = (v, ks) => JSON.stringify(Object.fromEntries(ks.map((k) => [k, k.includes('.') ? k.split('.').reduce((x, y) => x?.[y], v) : v[k]])));
R['I1.1'] = pick({ ...s1, rep: s1.compteurs.reponsesApi, dd: s1.debut - T0, ff: s1.fin - T0 }, ['kind', 'id', 'jetons', 'rep', 'dd', 'ff']);
const fichIdx = path.join(LAB, '.vibeflow', 'cockpit', '.cache', M.cache.FICHIER_INDEX);
R['I1.2a'] = String(M.cache.ecrireIndex(fichIdx, LAB, idxFx)); R['I1.2b'] = (fs.statSync(fichIdx).mode & 0o777).toString(8);
const ch = M.cache.chargerIndex(fichIdx, LAB, { maintenant: T0 + H }); R['I1.2c'] = ch.etat; R['I1.2d'] = String(JSON.stringify(ch.index) === JSON.stringify(idxFx));
// I1.3 : trois lectures, rechargées du disque ; coupes au milieu de la 3e ligne puis entre la 3e et la 4e
{
  const dir = path.join(WORK, 'p3', 'projects', '-lab'); fs.mkdirSync(dir, { recursive: true }); const f = path.join(dir, 'sess-aaaa0001.jsonl'); const buf = Buffer.from(sessionFx.replaceAll('@LAB@', LAB));
  const fin = (k) => { let p = -1; for (let i = 0; i < k; i++) p = buf.indexOf(10, p + 1); return p + 1; }; // fin de la ke ligne
  const coupes = [fin(2) + 40, fin(3), buf.length]; const cache = path.join(WORK, 'p3', 'index.json'); let sorties = [];
  for (const c of coupes) {
    fs.writeFileSync(f, buf.subarray(0, c)); fs.utimesSync(f, (T0 + H) / 1000, (T0 + H) / 1000);
    const l = M.cache.chargerIndex(cache, WORK, { maintenant: T0 + H }); const r = M.idx.mettreAJour(l.etat === 'lu' ? l.index : null, M.idx.enumerer(path.join(WORK, 'p3', 'projects')), O());
    M.cache.ecrireIndex(cache, WORK, r.index); sorties.push(r.index.voies[0]?.jetons.sortie);
  }
  const fin3 = M.cache.chargerIndex(cache, WORK, { maintenant: T0 + H }).index;
  R['I1.3a'] = JSON.stringify(sorties); R['I1.3b'] = String(strip(fin3) === strip(M.idx.construire(M.idx.enumerer(path.join(WORK, 'p3', 'projects')), O())));
}
// ---- I2.1 jetons
{ const v = voieDe(mk((id) => [u(id, 0), a(id, 1000, 'mx1', us(4000, 10, 1000, 0)), a(id, 2000, 'mx2', us(1500, 4, 0, 500))])); R['I2.1a'] = pick(v.jetons, ['contexteMax', 'contexteDernier', 'sortie']); R['I2.1b'] = pick(s1.jetons, ['contexteMax', 'contexteDernier']); }
// ---- I2.2 segments typés
const T = (c) => [u, a].length && c;
R['I2.2a'] = seg((id) => [u(id, 0), a(id, 1000, 'm1', us(1, 1), [appel('q1', 'AskUserQuestion')]), u(id, 401000, [res('q1')])]);
R['I2.2b'] = seg((id) => [u(id, 0), a(id, 1000, 'm1', us(1, 1), [appel('g1', 'Agent')]), u(id, 301000, [res('g1')])]);
R['I2.2c'] = seg((id) => [u(id, 0), a(id, 1000, 'm1', us(1, 1), [appel('b1', 'Bash')]), u(id, 601000, [res('b1')])]);
R['I2.2d1'] = seg((id) => [u(id, 0), a(id, 1000, 'm1', us(1, 1), undefined, 'end_turn'), sys(id, 1100, 'turn_duration', { pendingBackgroundAgentCount: 2 }), u(id, 401000)]);
R['I2.2d2'] = seg((id) => [u(id, 0), a(id, 1000, 'm1', us(1, 1), undefined, 'end_turn'), sys(id, 1100, 'turn_duration', { pendingBackgroundAgentCount: 0 }), u(id, 401000)]);
R['I2.2e1'] = seg((id) => [u(id, 0), a(id, 100000, 'm1', us(1, 1))]);
R['I2.2e2'] = seg((id) => [u(id, 0), a(id, 200000, 'm1', us(1, 1))]);
R['I2.2f'] = seg((id) => [u(id, 0), a(id, 200000, 'm1', us(1, 1)), u(id, 400000)]);
{ const v = voieDe(mk((id) => [u(id, 100000), a(id, 50000, 'm1', us(1, 1)), a(id, 100500, 'm2', us(1, 1))])); R['I2.2g'] = JSON.stringify([rel(v), v.fin - T0, Object.values(v.durees).every(Number.isFinite)]); }
R['I2.2h1'] = seg((id) => [u(id, 0), a(id, 180000, 'm1', us(1, 1))]);
R['I2.2h2'] = seg((id) => [u(id, 0), a(id, 181000, 'm1', us(1, 1))]);
R['I2.3'] = JSON.stringify([s1.durees.travailS, Object.values(s1.durees).reduce((x, y) => x + y, 0) === (s1.fin - s1.debut) / 1000]);
// ---- I2.4 / I2.5 / I2.6
{
  const v = voieDe(mk((id) => [u(id, 0, 'x', { origin: { kind: 'human' } }), a(id, 1000, 'r1', us(1, 1), [appel('t_ag', 'Agent')]), a(id, 2000, 'r2', us(1, 1), [appel('t_hb', 'SubagentHandback')]), u(id, 3000, [res('t_ag', true)]),
    u(id, 3500, 'x', { permissionDecision: { decision: 'reject' } }), a(id, 3600, 'r3', us(1, 1), [appel('t_q', 'AskUserQuestion')]), sys(id, 4000, 'compact_boundary'), sys(id, 4100, 'turn_duration', { pendingBackgroundAgentCount: 0 })]));
  R['I2.4'] = JSON.stringify(v.evenements.map(([t, g]) => [t - T0, g])); R['I2.5'] = JSON.stringify(v.compteurs);
}
{
  const r = voieDe(mk((id) => [u(id, 0), a(id, 1000, 'm1', us(1, 1), [appel('t1', 'Read')])])), m = voieDe(mk((id) => [u(id, 0), a(id, 1000, 'm1', us(1, 1), [appel('t1', 'mcp__srv__outil')])])), z = voieDe(mk((id) => [u(id, 0), a(id, 1000, 'm1', us(1, 1), [appel('t1', 'Read')]), u(id, 2000, [res('t1')])]));
  R['I2.6'] = JSON.stringify([r.enCours.verbe, Object.keys(M.voie.publique(r).enCours).sort().join(','), m.enCours.verbe, z.enCours, !/Read|mcp__/.test(JSON.stringify(r))]);
}
// ---- I2.7 sous-agents
const mg = par(idxFx, 'mgr00001'), wk = par(idxFx, 'wrk00001');
R['I2.7a'] = pick(mg, ['kind', 'parent', 'depth', 'role', 'background', 'evenements.0.1']); R['I2.7a2'] = String(mg.evenements.some((e) => e[1] === 'dispatch' && e[0] === T0 + 40000));
R['I2.7b'] = pick({ ...wk, rap: wk.evenements.map((e) => e[1]).join(',') }, ['parent', 'depth', 'fini', 'dispatchA', 'rap']); R['I2.7b2'] = String(wk.dispatchA === T0 + 40000);
// ---- I2.8 lab et worktrees prouvés
{
  const w = mk((id) => [u(id, 0, 'x', {}), a(id, 1000, 'm1', us(1, 1))], { id: 'sess-wwww0001' }), f = mk((id) => [u(id, 0), a(id, 1000, 'm1', us(1, 1))], { id: 'sess-ffff0001' });
  for (const [m, d] of [[w, LAB + '/wt-a'], [f, LAB + '/faux']]) fs.writeFileSync(m.f, fs.readFileSync(m.f, 'utf8').replaceAll(`"cwd":"${LAB}"`, `"cwd":"${d}"`));
  const memoH = new Map(), dir = path.join(WORK, 'p-sess-wwww0001', 'projects', '-lab'); fs.copyFileSync(f.f, path.join(dir, 'sess-ffff0001.jsonl')); fs.utimesSync(path.join(dir, 'sess-ffff0001.jsonl'), (T0 + 600e3) / 1000, (T0 + 600e3) / 1000);
  const i = M.idx.construire(M.idx.enumerer(w.projets), O({ memoHors: memoH }));
  R['I2.8a'] = JSON.stringify([arbreDe(LAB), arbreDe(LAB + '/wt-a'), arbreDe(WORK + '/autre'), arbreDe(LAB + '/faux')]);
  R['I2.8b'] = JSON.stringify([i.voies.map((v) => [v.id, v.arbre]), [...memoH.keys()].map((k) => path.basename(k))]);
  R['I2.8c'] = JSON.stringify([par(idxFx, 'sess-aaaa0001').arbre, par(idxFx, 'sess-bbbb0001') === undefined, [...memo.keys()].map((k) => path.basename(k))]);
  R['I2.8d'] = String(JSON.stringify(idxFx).includes(LAB) || JSON.stringify(idxFx).includes(WORK));
}
// ---- I2.9 forme inconnue
{
  const m = mk((id) => [u(id, 0), a(id, 1000, 'm1', us(1, 1)), { ...a(id, 2000, 'm2', us(1, 1)), message: { role: 'assistant', content: [] } }, a(id, 3000, 'm3', us(9, 9))]);
  const v = voieDe(m); R['I2.9a'] = JSON.stringify([v.forme, v.jetons, v.compteurs, v.segments, M.voie.publique(v).jetons]);
  const l = fs.readFileSync(m.f, 'utf8').split('\n'); l[2] = JSON.stringify(a(m.id, 2000, 'm2', us(2, 2))); l[0] = JSON.stringify(u(m.id, 1)); fs.writeFileSync(m.f, l.join('\n')); fs.utimesSync(m.f, (T0 + 600e3) / 1000, (T0 + 600e3) / 1000);
  const i = M.idx.construire(M.idx.enumerer(m.projets), O()); R['I2.9b'] = JSON.stringify([i.voies[0].forme, i.voies[0].jetons.entree]);
  const j = M.idx.mettreAJour(M.idx.construire(M.idx.enumerer(m.projets), O()), M.idx.enumerer(m.projets), O()); R['I2.9c'] = j.index.voies[0].forme;
}
// ---- I2.10 versions
{
  const m = mk((id) => [u(id, 0), { ...a(id, 1000, 'm1', us(1, 1)), version: '2.1.330' }]);
  const i = M.idx.construire(M.idx.enumerer(m.projets), O()); R['I2.10a'] = JSON.stringify([i.voies[0].versions, i.versionsVues]); R['I2.10b'] = JSON.stringify(M.idx.bilan(i).versionsHorsContrat);
  R['I2.10c'] = JSON.stringify(M.idx.bilan(idxFx).versionsHorsContrat);
}
// ---- I2.11 ligne géante, bloc de 7 octets ou 1 Mio
{
  const m = mk((id) => [u(id, 0), JSON.stringify(u(id, 500, 'x'.repeat(5000))), a(id, 1000, 'm1', us(3, 4))]); const r = [];
  for (const bloc of [7, 1048576]) { const v = voieDe(m, { bornes: { ligneMax: 2048, bloc } }); r.push(JSON.stringify([v.tronque, v.jetons.entree, v.debut - T0, v.fin - T0, v.curseur.octets])); }
  R['I2.11'] = JSON.stringify([r[0] === r[1], JSON.parse(r[0]).slice(0, 4)]);
}
// ---- I2.12 alternance A, B, A (jamais un comptage double silencieux)
{ const v = voieDe(mk((id) => [u(id, 0), a(id, 1000, 'mA', us(10, 5)), a(id, 2000, 'mB', us(20, 6)), a(id, 3000, 'mA', us(10, 7))])); R['I2.12'] = JSON.stringify([v.forme, v.jetons, v.compteurs]); }
// ---- I5 reprises depuis zéro
{
  const m = mk((id) => [u(id, 0), a(id, 1000, 'm1', us(1, 1)), a(id, 2000, 'm2', us(2, 2))]); const i0 = M.idx.construire(M.idx.enumerer(m.projets), O());
  const reecrit = (lignes) => { fs.writeFileSync(m.f, lignes.map((l) => JSON.stringify(l)).join('\n') + '\n'); fs.utimesSync(m.f, (T0 + 700e3) / 1000, (T0 + 700e3) / 1000); };
  const un = () => strip(M.idx.construire(M.idx.enumerer(m.projets), O()));
  reecrit([{ ...u(m.id, 0), cwd: LAB, pad: 'une tête plus longue' }, a(m.id, 1000, 'm1', us(1, 1)), a(m.id, 2000, 'm2', us(2, 2)), a(m.id, 3000, 'm3', us(4, 4))]);
  R['I5.1'] = String(strip(M.idx.mettreAJour(JSON.parse(JSON.stringify(i0)), M.idx.enumerer(m.projets), O()).index) === un());
  const i1 = M.idx.construire(M.idx.enumerer(m.projets), O()); reecrit([u(m.id, 0)]);
  R['I5.2'] = String(strip(M.idx.mettreAJour(JSON.parse(JSON.stringify(i1)), M.idx.enumerer(m.projets), O()).index) === un());
  fs.rmSync(m.f); R['I5.3'] = JSON.stringify(M.idx.mettreAJour(JSON.parse(JSON.stringify(i1)), M.idx.enumerer(m.projets), O()).index.voies.length);
}
// ---- I8 fenêtre et rétention
{
  const m = mk((id) => [u(id, 0), a(id, 1000, 'm1', us(1, 1))], { mtime: T0 + 1000 }); const fin = T0 + 1000, i0 = M.idx.construire(M.idx.enumerer(m.projets), O({ maintenant: fin + 2 * H }));
  const maj = (maintenant, x = {}) => M.idx.mettreAJour(JSON.parse(JSON.stringify(i0)), M.idx.enumerer(m.projets), O({ maintenant, ...x })).index;
  R['I8.1'] = JSON.stringify([maj(fin + 25 * H).voies.length, maj(fin + 23 * H).voies.length]);
  R['I8.2'] = JSON.stringify([maj(fin + 25 * H, { vivantes: new Set([m.id]) }).voies.length, maj(fin + 25 * H, { vivantes: new Set(['autre']) }).voies.length]);
  const c = mk((id) => [u(id, -30 * H), a(id, -30 * H + 5000, 'mc1', us(1, 1)), a(id, -30 * H + 6000, 'mc1', us(1, 2), [appel('toolu_c1', 'Bash')])], { mtime: T0 - 30 * H + 6000 }); const cf = T0 - 30 * H + 6000;
  const ic = M.idx.construire(M.idx.enumerer(c.projets), O({ maintenant: cf + H })), mc = (maintenant, x = {}) => M.idx.mettreAJour(JSON.parse(JSON.stringify(ic)), M.idx.enumerer(c.projets), O({ maintenant, ...x })).index;
  R['I8.3'] = JSON.stringify([ic.voies.length, ic.voies[0].enCours !== null, mc(cf + 25 * H).voies.length, mc(cf + 25 * H, { vivantes: new Set([c.id]) }).voies.length]);
  const fx2 = M.idx.construire(M.idx.enumerer(fixtures), O()); // le manager et le worker de la fixture : l'ancêtre hors fenêtre d'une voie gardée est gardé
  const cand = M.idx.enumerer(fixtures).filter((x) => x.kind === 'subagent'); const tard = M.idx.mettreAJour(JSON.parse(JSON.stringify(fx2)), cand, O({ maintenant: T0 + 25 * H + 62000, vivantes: new Set(['wrk00001']) }));
  R['I8.4'] = JSON.stringify(tard.index.voies.map((v) => v.id).sort());
  const f5 = path.join(WORK, 'p8', 'projects', '-lab'); fs.mkdirSync(f5, { recursive: true });
  for (let k = 0; k < 5; k++) { const id = `sess-v${k}`; const f = path.join(f5, id + '.jsonl'); fs.writeFileSync(f, [u(id, k * 1000), a(id, k * 1000 + 500, 'm', us(1, 1))].map((l) => JSON.stringify(l)).join('\n') + '\n'); fs.utimesSync(f, (T0 + k * 1000 + 500) / 1000, (T0 + k * 1000 + 500) / 1000); }
  const i5 = M.idx.construire(M.idx.enumerer(path.join(WORK, 'p8', 'projects')), O({ bornes: { voiesMax: 3 } }));
  R['I8.5'] = JSON.stringify([i5.voies.map((v) => v.id).sort(), i5.evinces, M.idx.bilan(i5).tronque, i5.fenetreS]);
}
console.log(JSON.stringify(R));
JS
node "$AUX/cas.mjs" "$SCRIPTS" "$WORK" "$FIX" > "$WORK/cas.json" 2> "$WORK/cas.err" || { echo "cas.mjs KO"; head -5 "$WORK/cas.err"; }
G() { node "$AUX/get.mjs" "$WORK/cas.json" "$@"; }
c() { assert_eq "$1" "$(G "j[\"$2\"]")" "$3"; }

echo "=== I0 — modules et fixture ==="
c "I0.1 — les quatre modules existent et s'importent" I0.1 "ok"
c "I0.2 — témoin positif d'entrée : la fixture de session porte chaque marqueur de contenu" I0.2 "1,1,1,1,1"
echo "=== I1 — une passe, fichier, trois lectures ==="
c "I1.1 — une passe : voie session, jetons, réponses, début et fin" I1.1 '{"kind":"session","id":"sess-aaaa0001","jetons":{"entree":150,"sortie":49,"cacheLu":3000,"cacheCree":300,"contexteMax":2350,"contexteDernier":2350},"rep":2,"dd":0,"ff":25000}'
c "I1.2a — ecrireIndex rend vrai" I1.2a true
c "I1.2b — le fichier d'index est en 0600" I1.2b 600
c "I1.2c — chargerIndex rend lu" I1.2c lu
c "I1.2d — l'index relu égale l'index écrit" I1.2d true
c "I1.3a — trois lectures coupées au milieu d'une ligne puis entre deux lignes du même message : jamais 49 plus une ligne déjà vue" I1.3a '[5,20,49]'
c "I1.3b — l'index final des trois lectures égale celui d'une passe (hors genereA)" I1.3b true
echo "=== I2 — réduction ==="
c "I2.1a — contexte 5000 puis 2000" I2.1a '{"contexteMax":5000,"contexteDernier":2000,"sortie":14}'
c "I2.1b — la fixture de session : contexte max et dernier" I2.1b '{"contexteMax":2350,"contexteDernier":2350}'
c "I2.2a — AskUserQuestion ouvert 400 s : attend-humain" I2.2a '[[0,1000,"travail"],[1000,401000,"attend-humain"]]'
c "I2.2b — Agent ouvert 300 s : attend-agents" I2.2b '[[0,1000,"travail"],[1000,301000,"attend-agents"]]'
c "I2.2c — Bash ouvert 600 s : travail (un seul segment fusionné)" I2.2c '[[0,601000,"travail"]]'
c "I2.2d1 — fin de tour avec 2 agents de fond puis 400 s : attend-agents" I2.2d1 '[[0,1000,"travail"],[1000,401000,"attend-agents"]]'
c "I2.2d2 — fin de tour sans agent de fond puis 400 s : repos" I2.2d2 '[[0,1000,"travail"],[1000,401000,"repos"]]'
c "I2.2e1 — écart de 100 s sans appel ni fin de tour : travail" I2.2e1 '[[0,100000,"travail"]]'
c "I2.2e2 — écart de 200 s : silence" I2.2e2 '[[0,200000,"silence"]]'
c "I2.2f — deux écarts de même genre fusionnent" I2.2f '[[0,400000,"silence"]]'
c "I2.2g — un horodatage qui recule ne crée aucun segment négatif ni NaN et ne fait pas reculer fin" I2.2g '[[[100000,100500,"travail"]],100500,true]'
c "I2.2h1 — 180 s exactement : travail" I2.2h1 '[[0,180000,"travail"]]'
c "I2.2h2 — 181 s : silence" I2.2h2 '[[0,181000,"silence"]]'
c "I2.3 — durées de la fixture : travailS 25 et somme égale à fin moins début" I2.3 '[25,true]'
c "I2.4 — un événement par genre, au bon instant" I2.4 '[[0,"humain"],[1000,"dispatch"],[2000,"rapport"],[3000,"erreur"],[4000,"compaction"]]'
c "I2.5 — compteurs du transcript riche" I2.5 '{"appels":3,"erreurs":1,"refus":1,"questions":1,"compactions":1,"tours":1,"reponsesApi":3}'
c "I2.6 — enCours : verbe de la table fermée, jamais l'entrée ni le nom de l'outil" I2.6 '["lit","depuisMs,verbe","utilise",null,true]'
c "I2.7a — manager : sous-agent, parent la session, profondeur 1, rôle, arrière-plan, premier événement dispatch" I2.7a '{"kind":"subagent","parent":"sess-aaaa0001","depth":1,"role":"vf-dev-manager","background":true,"evenements.0.1":"dispatch"}'
c "I2.7a' — le manager porte dispatch à l'instant de l'appel Agent" I2.7a2 true
c "I2.7b — worker : parent le manager, profondeur 2, fini, rapport" I2.7b '{"parent":"mgr00001","depth":2,"fini":true,"dispatchA":1793523640000,"rap":"rapport"}'
c "I2.7b' — dispatchA égale l'instant de l'appel Agent du manager" I2.7b2 true
c "I2.8a — arbreDe de la suite : principal, worktree prouvé, hors lab, faux worktree" I2.8a '[{"arbre":null},{"arbre":"wt-a"},null,null]'
c "I2.8b — worktree prouvé indexé sous son nom, faux worktree hors de l'index et dans memoHors" I2.8b '[[["sess-wwww0001","wt-a"]],["sess-ffff0001.jsonl"]]'
c "I2.8c — arbre principal null, transcript hors du lab absent et dans memoHors" I2.8c '[null,true,["sess-bbbb0001.jsonl"]]'
c "I2.8d — aucun chemin dans l'index" I2.8d false
c "I2.9a — ligne assistant sans message.id : forme inconnue, mesures nulles, jamais zéro, rien de plié ensuite" I2.9a '["inconnue",null,null,null,null]'
c "I2.9b — relecture depuis zéro d'un fichier corrigé : ok" I2.9b '["ok",12]'
c "I2.9c — une mise à jour sans changement garde ok" I2.9c ok
c "I2.10a — deux versions dans l'ordre d'apparition, en-tête triée" I2.10a '[["2.1.322","2.1.330"],["2.1.322","2.1.330"]]'
c "I2.10b — versionsHorsContrat rend la version différente du contrat d'essai" I2.10b '["2.1.330"]'
c "I2.10c — fixture sur la version du contrat : aucune version hors contrat" I2.10c '[]'
c "I2.11 — ligne géante sautée, voie tronquée, suite pliée, même résultat pour un bloc de 7 octets et de 1 Mio" I2.11 '[true,[true,3,0,1000]]'
c "I2.12 — alternance A, B, A : forme inconnue, jamais deux fois les jetons de A" I2.12 '["inconnue",null,null]'
echo "=== I5 — reprise depuis zéro ==="
c "I5.1 — première ligne changée (fichier plus grand) : relu depuis zéro" I5.1 true
c "I5.2 — taille inférieure au décalage : relu depuis zéro" I5.2 true
c "I5.3 — transcript absent des candidats : voie retirée" I5.3 0
echo "=== I8 — fenêtre de 24 h et rétention ==="
c "I8.1 — dernière ligne à 25 h : retirée ; à 23 h : gardée" I8.1 '[0,1]'
c "I8.2 — 25 h et dans vivantes : gardée ; autre identifiant vivant : retirée" I8.2 '[1,0]'
c "I8.3 — abandonné en plein appel : présent avec enCours à +1 h, purgé à +25 h, gardé si vivant (P79-D-29)" I8.3 '[1,true,0,1]'
c "I8.4 — le manager (ancêtre) hors fenêtre reste tant que le worker est gardé" I8.4 '["mgr00001","wrk00001"]'
c "I8.5 — voiesMax 3 sur 5 voies : les 3 plus récentes, evinces 2, tronque, fenetreS 86400" I8.5 '[["sess-v2","sess-v3","sess-v4"],2,true,86400]'

echo ""; echo "Résultats : $PASS PASS / $FAIL FAIL"
[ $((PASS+FAIL)) -eq 0 ] && { echo "aucune assertion jouée"; exit 1; }
[ "$FAIL" -eq 0 ]
