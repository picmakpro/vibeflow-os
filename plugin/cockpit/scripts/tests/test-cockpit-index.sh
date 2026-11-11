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

cat > "$AUX/subst.mjs" <<'JS'
// subst.mjs fichier marqueur de vers : remplace, sur la ligne qui porte le marqueur, la première occurrence de `de` par `vers` ; exit 1 si rien n'a changé
import fs from 'node:fs';
const [, , f, marq, de, vers] = process.argv; let ok = false;
const l = fs.readFileSync(f, 'utf8').split('\n').map((x) => { if (!ok && x.includes(marq) && x.includes(de)) { ok = true; return x.replace(de, vers); } return x; });
if (!ok) process.exit(1); fs.writeFileSync(f, l.join('\n'));
JS
PROP="$SCRIPTS/tests/index-propriete.mjs"
prop() { local d="$1" m="$2"; shift 2; node "$PROP" "$d" "$m" "$@" 2>/dev/null | tail -1 > "$WORK/prop.json"; }
pj() { node "$AUX/get.mjs" "$WORK/prop.json" "$1"; }
# mutant NOM FICHIER DE VERS : copie du module sans tests/, une substitution sur la ligne `garde:index-NOM` ; rend le dossier, ou vide si le mutant est sans effet ou ne compile pas
mutant() { local nom="$1" fichier="$2" de="$3" vers="$4" d; d="$WORK/mut-$1"; rm -rf "$d"; mkdir -p "$d"; cp "$SCRIPTS"/*.mjs "$SCRIPTS"/*.json "$d"/
  node "$AUX/subst.mjs" "$d/$fichier" "garde:index-$nom" "$de" "$vers" || return 1; cmp -s "$SCRIPTS/$fichier" "$d/$fichier" && return 1; node --check "$d/$fichier" 2>/dev/null || return 1; echo "$d"; }
VERT='j.plantage===null&&j.echecs.length===0'
echo "=== I3 — propriété d'incrémentalité (générative, graine imprimée) ==="
GF="${VF_SEED:-$((RANDOM * 32768 + RANDOM))}"; echo "graine=$GF (rejouable : VF_SEED=$GF)"
for g in 1 2 3 "$GF"; do prop "$SCRIPTS" incrementalite --graine=$g --n=40; assert_eq "P1.1 — graine $g : 40 transcripts, coupes tirées, l'index par ajouts égale l'index d'une passe (invariants P1.3 compris : durées, segments, jetons et compteurs contre l'oracle du générateur)" "$(pj "$VERT&&j.couverture.manque.length===0")" "true"; done
prop "$SCRIPTS" incrementalite --graine=1 --n=40; assert_eq "P1.4 — chaque classe de coupe observée au moins 8 fois (oracle du générateur)" "$(pj 'j.couverture.manque.join(",")+"|"+Object.keys(j.couverture.comptes).length')" "|10"
prop "$SCRIPTS" couverture-temoin --graine=1 --n=40 --genere=degenere; assert_eq "P1.5a — témoin : un générateur aux seules fins de ligne et bloc de 1 Mio manque milieu-de-ligne, ligne-geante et bloc-coupe-une-ligne" "$(pj 'j.couverture.manque.filter((k)=>["milieu-de-ligne","bloc-coupe-une-ligne","ligne-geante"].includes(k)).length')" "3"
prop "$SCRIPTS" couverture-temoin --graine=1 --n=40 --genere=une-coupe; assert_eq "P1.5b — témoin : une coupe unique en fin de fichier manque toutes les classes" "$(pj 'j.couverture.manque.length')" "9"
prop "$SCRIPTS" cout --graine=2; assert_eq "P1.6 — un ajout lit au plus les octets restants plus 1 024 ; témoin positif : la première lecture compte plus de zéro octet" "$(pj 'j.plantage===null&&j.echecs.length===0&&j.octetsLus.premiere.every((n)=>n>0)&&j.octetsLus.ajout.every((n)=>n>0)')" "true"
for g in 1 2 3 "$GF"; do prop "$SCRIPTS" retention --graine=$g --n=40; assert_eq "P1.7 — graine $g : rétention générative (fenêtre, état officiel, ancêtre ; un transcript abandonné en plein appel depuis plus de 24 h n'est jamais gardé seul)" "$(pj "$VERT")" "true"; done
for g in 1 2 3 "$GF"; do prop "$SCRIPTS" reecritures --graine=$g --n=40; assert_eq "P2.1 — graine $g : suites d'ajouts, raccourcissements, réécritures de tête et recréations, égalité avec une passe sur l'état courant" "$(pj "$VERT")" "true"; done
echo "=== Mutants — chacun rouge pour sa seule raison ==="
M="$(mutant msgid vf-cockpit-index.mjs 'c.dernierMsgId = travail.dernierMsgId; c.usage = travail.usage; c.maxClos = travail.maxClos;' 'c.dernierMsgId = null; c.usage = null; c.maxClos = 0;')" || M=""
if [ -n "$M" ]; then prop "$M" incrementalite --graine=1 --n=40; assert_eq "M-MSGID — P1 rouge : sans plantage, champs en écart seulement jetons, réponses ou état du message (curseur), tout échec qui compte deux fois la sortie porte un message à cheval, la passe unique reste juste" "$(pj 'j.plantage===null&&j.echecs.length>0&&j.echecs.every((e)=>e.champs.every((c)=>/^(jetons\..*|compteurs\.reponsesApi|curseur\.(dernierMsgId|usage(\..*)?|maxClos|clos(\..*)?)|invariant\.(jetons|compteurs))$/.test(c)))&&j.echecs.filter((e)=>e.champs.includes("jetons.sortie")).every((e)=>e.classes.includes("message-a-cheval"))&&j.echecs.some((e)=>e.classes.includes("message-a-cheval"))')" "true"; else assert_eq "M-MSGID — mutant applicable (sans effet ou illisible)" "non" "oui"; fi
M="$(mutant octets vf-cockpit-index.mjs 'c.octets = fin;' 'c.octets = pos;')" || M=""
if [ -n "$M" ]; then prop "$M" incrementalite --graine=1 --n=40; assert_eq "M-OCTETS — P1 rouge : sans plantage, chaque échec porte une coupe au milieu d'une ligne" "$(pj 'j.plantage===null&&j.echecs.length>0&&j.echecs.every((e)=>e.classes.includes("milieu-de-ligne"))')" "true"; else assert_eq "M-OCTETS — mutant applicable" "non" "oui"; fi
M="$(mutant tete vf-cockpit-index.mjs 'voie.curseur.tete !== null && tete !== voie.curseur.tete' 'false')" || M=""
if [ -n "$M" ]; then prop "$M" reecritures --graine=1 --n=40; assert_eq "M-TETE — P2.1 rouge : sans plantage, chaque suite en échec porte une réécriture de première ligne" "$(pj 'j.plantage===null&&j.echecs.length>0&&j.echecs.every((e)=>e.classes.includes("reecrire-tete"))')" "true"; else assert_eq "M-TETE — mutant applicable" "non" "oui"; fi
M="$(mutant relit vf-cockpit-index.mjs 'teteDiff || voie.curseur.octets > o.st.size' 'true')" || M="$(mutant relit vf-cockpit-index.mjs 'teteDiff || o.st.size < voie.curseur.octets' 'true')" || M=""
if [ -n "$M" ]; then prop "$M" incrementalite --graine=1 --n=40; A="$(pj "$VERT")"; prop "$M" reecritures --graine=1 --n=40; B="$(pj "$VERT")"; prop "$M" cout --graine=2; assert_eq "M-RELIT — l'égalité tient (P1.1 et P2.1 verts) et seul P1.6 (le coût) rougit" "$A,$B,$(pj 'j.plantage===null&&j.echecs.length>0')" "true,true,true"; else assert_eq "M-RELIT — mutant applicable" "non" "oui"; fi
cas() { local d="$WORK/m-$1"; mkdir -p "$d/lab"; node "$AUX/cas.mjs" "$2" "$d" "$FIX" 2>/dev/null > "$d/cas.json"; }
diffcles() { node -e 'const a=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")),b=JSON.parse(require("fs").readFileSync(process.argv[2],"utf8"));console.log(JSON.stringify(Object.keys(a).filter((k)=>JSON.stringify(a[k])!==JSON.stringify(b[k])).sort()))' "$1" "$2"; }
M="$(mutant retention vf-cockpit-index.mjs '|| vivantes.has(v.id)' '|| vivantes.has(v.id) || Object.keys(v.curseur.ouverts).length > 0')" || M=""
if [ -n "$M" ]; then prop "$M" retention --graine=1 --n=40; A="$(pj 'j.plantage===null&&j.echecs.length>0&&j.echecs.every((e)=>e.classes.includes("abandonne-en-plein-appel")&&e.champs.length===1&&e.champs[0]==="gardee-a-tort")')"; prop "$M" incrementalite --graine=1 --n=40; B="$(pj "$VERT")"; prop "$M" reecritures --graine=1 --n=40; C="$(pj "$VERT")"; cas ouvert "$M"
  assert_eq "M-OUVERT — P1.7 rouge (voies gardées à tort : toutes abandonnées en plein appel hors fenêtre), I8.3 rouge et seul I8.3, l'égalité d'incrémentalité reste verte" "$A,$B,$C,$(diffcles "$WORK/m-ouvert/cas.json" "$WORK/cas.json")" 'true,true,true,["I8.3"]'; else assert_eq "M-OUVERT — mutant applicable" "non" "oui"; fi
M="$(mutant clos vf-cockpit-index-voie.mjs 'travail.clos.includes(id)' 'false')" || M=""
if [ -n "$M" ]; then cas clos "$M"; assert_eq "M-CLOS — I2.12 rouge, et seul I2.12 : sans la garde, les jetons de A sont comptés deux fois, sans plantage" "$(diffcles "$WORK/m-clos/cas.json" "$WORK/cas.json")" '["I2.12"]'; else assert_eq "M-CLOS — mutant applicable" "non" "oui"; fi

cat > "$AUX/hostile.mjs" <<'JS'
// hostile.mjs <scripts> <work> <fixtures> : charge des fichiers d'index hostiles et imprime { cas: "etat|raison" } (jugé par la suite)
import fs from 'node:fs'; import path from 'node:path'; import { execFileSync } from 'node:child_process'; import { pathToFileURL } from 'node:url';
const [, , SC, WORK, FIX] = process.argv; const imp = (n) => import(pathToFileURL(path.join(SC, n)).href); const idx = await imp('vf-cockpit-index.mjs'), ca = await imp('vf-cockpit-index-cache.mjs');
const T0 = Date.parse('2026-11-01T09:00:00Z'), H = 3600e3, LAB = path.join(WORK, 'lab'), R = {}, MAINT = T0 + H;
const dest = path.join(WORK, 'hx', 'projects'); fs.cpSync(path.join(FIX, 'projects'), dest, { recursive: true });
const walk = (d) => { for (const e of fs.readdirSync(d, { withFileTypes: true })) { const p = path.join(d, e.name); if (e.isDirectory()) walk(p); else { fs.writeFileSync(p, fs.readFileSync(p, 'utf8').replaceAll('@LAB@', LAB).replaceAll('@AUTRE@', WORK + '/autre')); fs.utimesSync(p, (T0 + H) / 1000, (T0 + H) / 1000); } } }; walk(dest);
const O = { maintenant: MAINT, arbreDe: (c) => (c === LAB ? { arbre: null } : null), memoHors: new Map() };
const base = idx.construire(idx.enumerer(dest), O); const dir = path.join(WORK, 'hostile'); fs.mkdirSync(dir, { recursive: true }); let n = 0;
const essai = (nom, mut, opts = {}, mode = 0o600) => { const m = JSON.parse(JSON.stringify(base)); mut(m); const f = path.join(dir, `i${++n}.json`); fs.writeFileSync(f, JSON.stringify(m), { mode }); fs.chmodSync(f, mode); const r = ca.chargerIndex(f, LAB, { maintenant: MAINT, ...opts }); R[nom] = `${r.etat}|${r.raison}`; return f; };
essai('I6.0', () => {});
essai('I6.1', (m) => { m.schema = 'autre'; }); essai('I6.2', (m) => { m.schema = 'vibeflow/cockpit-index@2'; }); essai('I6.3', (m) => { m.voies = {}; });
essai('I6.4', () => {}, { bornes: { voiesMax: 1 } }); essai('I6.5', (m) => { m.voies[0].id = '../x'; });
essai('I6.6a', (m) => { m.voies[0].arbre = '/etc'; }); essai('I6.6b', (m) => { m.voies[0].arbre = 'a/b'; }); essai('I6.6c', (m) => { m.voies[0].arbre = 'a\\b'; }); essai('I6.6d', (m) => { m.voies[0].arbre = '..'; });
const v0 = (m) => m.voies.find((v) => v.id === 'sess-aaaa0001');
essai('I6.7', (m) => { v0(m).segments = [[T0 + 10, T0 + 20, 'travail'], [T0 + 1, T0 + 5, 'silence']]; });
essai('I6.8', (m) => { v0(m).segments = Array.from({ length: 501 }, (_, i) => [T0 + i * 10, T0 + i * 10 + 5, i % 2 ? 'travail' : 'silence']); });
essai('I6.9', (m) => { v0(m).debut = 1000; }); essai('I6.10', (m) => { v0(m).fin = MAINT + 2 * 86400e3; });
essai('I6.11a', (m) => { v0(m).curseur.octets = -1; }); essai('I6.11b', (m) => { v0(m).curseur.octets = 1.5; }); essai('I6.11c', (m) => { v0(m).curseur.octets = v0(m).curseur.taille + 1; });
essai('I6.12', (m) => { v0(m).curseur.ouverts = Object.fromEntries(Array.from({ length: 65 }, (_, i) => [`t${i}`, { v: 'lit', t: T0, c: 'autre' }])); });
essai('I6.13', (m) => { v0(m).curseur.etat.doing = 1; }); essai('I6.14', (m) => { v0(m).cibles = { ecritures: [] }; });
essai('I6.15', () => {}, { bornes: { fichierOctets: 100 } });
const ok = essai('I6.16', () => {}); const lien = path.join(dir, 'lien.json'); fs.symlinkSync(ok, lien); const rl = ca.chargerIndex(lien, LAB, { maintenant: MAINT }); R['I6.16'] = `${rl.etat}|${rl.raison}`;
const tube = path.join(dir, 'tube.json'); execFileSync('mkfifo', [tube]); const rt = ca.chargerIndex(tube, LAB, { maintenant: MAINT }); R['I6.17'] = `${rt.etat}|${rt.raison}`;
essai('I6.18', () => {}, {}, 0o644); essai('I6.19', () => {}, { uid: process.getuid() + 1 });
const f = path.join(dir, 'reconstruit.json'); fs.writeFileSync(f, '{"schema":"x"}', { mode: 0o600 }); const ch = ca.chargerIndex(f, LAB, { maintenant: MAINT });
const strip = (i) => { const c = JSON.parse(JSON.stringify(i)); delete c.genereA; return JSON.stringify(c); };
R['I6.20'] = `${ch.etat}|${strip(idx.mettreAJour(ch.index, idx.enumerer(dest), O).index) === strip(base)}`;
console.log(JSON.stringify(R));
JS
cat > "$AUX/fuite.mjs" <<'JS'
// fuite.mjs <scripts> <work> <fixtures> <tests> : balayage de contenu de l'index écrit sur disque (marqueurs posés dans chaque champ hors liste blanche)
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , SC, WORK, FIX, TESTS] = process.argv; const imp = (n) => import(pathToFileURL(path.join(SC, n)).href); const idx = await imp('vf-cockpit-index.mjs'), ca = await imp('vf-cockpit-index-cache.mjs'), voie = await imp('vf-cockpit-index-voie.mjs');
const { gen, T0 } = await import(pathToFileURL(path.join(TESTS, 'index-generateur.mjs')).href); const LAB = path.join(WORK, 'lab'), R = {}, H = 3600e3;
const dest = path.join(WORK, 'fu', 'projects'); fs.cpSync(path.join(FIX, 'projects'), dest, { recursive: true });
const walk = (d) => { for (const e of fs.readdirSync(d, { withFileTypes: true })) { const p = path.join(d, e.name); if (e.isDirectory()) walk(p); else { fs.writeFileSync(p, fs.readFileSync(p, 'utf8').replaceAll('@LAB@', LAB).replaceAll('@AUTRE@', WORK + '/autre')); fs.utimesSync(p, (T0 + H) / 1000, (T0 + H) / 1000); } } }; walk(dest);
const txt = []; for (let k = 0; k < 30; k++) { const id = `sess-f${k}`, g = gen(900 + k, { lab: LAB, id }), f = path.join(dest, '-lab', id + '.jsonl'); fs.writeFileSync(f, g.buf); fs.utimesSync(f, (T0 + H) / 1000, (T0 + H) / 1000); txt.push(g.buf.toString()); }
const tout = txt.join('') + fs.readFileSync(path.join(dest, '-lab', 'sess-aaaa0001.jsonl'), 'utf8') + fs.readFileSync(path.join(dest, '-lab', 'sess-aaaa0001', 'subagents', 'agent-mgr00001.meta.json'), 'utf8');
R.presents = ['MARQ-TEXTE', 'MARQ-COMMANDE', 'MARQ-CIBLE', 'MARQ-SORTIE', 'MARQ-TUR', 'MARQ-BRANCHE', 'MARQ-TITRE'].filter((m) => !tout.includes(m)).concat(tout.includes(LAB) ? [] : ['lab']);
const index = idx.construire(idx.enumerer(dest), { maintenant: T0 + 2 * H, arbreDe: (c) => (c === LAB ? { arbre: null } : null), memoHors: new Map() });
const fich = path.join(LAB, '.vibeflow', 'cockpit', '.cache', 'index-transcripts.json'); ca.ecrireIndex(fich, LAB, index);
const disque = JSON.parse(fs.readFileSync(fich, 'utf8')), brut = fs.readFileSync(fich, 'utf8');
const fuites = (o, p = []) => { const r = []; if (typeof o === 'string' && (o.includes('MARQ-') || o.includes(LAB) || o.includes(WORK))) r.push(p.join('.').replace(/^voies\.\d+\./, '').replace(/\.\d+(?=\.|$)/g, '.#')); else if (o && typeof o === 'object') for (const k of Object.keys(o)) r.push(...fuites(o[k], [...p, k])); return r; };
const INTERD = [...JSON.parse(fs.readFileSync(path.join(SC, 'vf-cockpit-interface.json'), 'utf8')).schemas['vibeflow/cockpit-who@2'].interdits, 'cibles', 'ecritures', 'lectures', 'cible'];
const cles = (o, d = 0) => { const r = []; if (d > 14 || !o || typeof o !== 'object') return r; for (const k of Object.keys(o)) { if (INTERD.includes(k)) r.push(k); r.push(...cles(o[k], d + 1)); } return r; };
R.voies = disque.voies.length; R.fuites = [...new Set(fuites(disque))]; R.brut = /MARQ-|doing/.test(brut) || brut.includes(LAB);
R.temoinMarqueur = fuites({ voies: [{ id: 'x', role: 'MARQ-TEXTE' }] }).join(','); R.temoinCle = cles({ a: { b: { doing: 1 } } }).join(','); R.temoinCible = cles({ a: [{ b: { cibles: 1 } }] }).join(',');
R.cles = [...new Set(cles(disque))]; const pub = disque.voies.map((v) => voie.publique(v)); const C3 = ['id', 'kind', 'session', 'parent', 'depth', 'role', 'arbre', 'background', 'debut', 'fin', 'dispatchA', 'fini', 'arrete', 'modeles', 'compteurs', 'jetons', 'durees', 'segments', 'evenements', 'enCours', 'rattachement'];
R.publique = pub.every((p) => Object.keys(p).every((k) => C3.includes(k)) && !('curseur' in p) && !('etatOfficiel' in p) && !('cibles' in p) && p.rattachement === null);
console.log(JSON.stringify(R));
JS
cc() { node "$AUX/$1.mjs" "${2:-$SCRIPTS}" "$3" "$FIX" "$SCRIPTS/tests" 2>/dev/null; }
echo "=== I6 — fichier d'index hostile ==="
mkdir -p "$WORK/h1/lab" && ( cd "$WORK" && node "$AUX/hostile.mjs" "$SCRIPTS" "$WORK/h1" "$FIX" > "$WORK/hostile.json" 2>"$WORK/hostile.err" ) ; hj() { node "$AUX/get.mjs" "$WORK/hostile.json" "j[\"$1\"]"; }
assert_eq "I6.0 — témoin positif : l'index valide produit par le module est accepté" "$(hj I6.0)" "lu|"
assert_eq "I6.1 — mauvais schéma écarté" "$(hj I6.1)" "ecarte|schema: version inconnue"
assert_eq "I6.2 — mauvaise version écartée" "$(hj I6.2)" "ecarte|schema: version inconnue"
assert_eq "I6.3 — voies qui n'est pas une liste" "$(hj I6.3)" "ecarte|voies: pas une liste"
assert_eq "I6.4 — plus de voiesMax voies (borne d'essai abaissée)" "$(hj I6.4)" "ecarte|voies: trop nombreuses"
assert_eq "I6.5 — identifiant à forme de chemin relatif" "$(hj I6.5)" "ecarte|voie: id: identifiant"
for k in a b c d; do assert_eq "I6.6$k — arbre à forme de chemin" "$(hj I6.6$k)" "ecarte|voie: arbre: forme de chemin"; done
assert_eq "I6.7 — segments non croissants" "$(hj I6.7)" "ecarte|voie: segments: forme ou ordre"
assert_eq "I6.8 — segments en nombre excessif" "$(hj I6.8)" "ecarte|voie: segments: nombre"
assert_eq "I6.9 — instant avant 2020" "$(hj I6.9)" "ecarte|voie: debut: instant"
assert_eq "I6.10 — instant à plus d'un jour dans le futur" "$(hj I6.10)" "ecarte|voie: fin: instant"
assert_eq "I6.11a — curseur.octets négatif" "$(hj I6.11a)" "ecarte|voie: curseur.octets: forme"
assert_eq "I6.11b — curseur.octets non entier" "$(hj I6.11b)" "ecarte|voie: curseur.octets: forme"
assert_eq "I6.11c — curseur.octets supérieur à la taille" "$(hj I6.11c)" "ecarte|voie: curseur.octets: au-delà de la taille"
assert_eq "I6.12 — plus de 64 appels ouverts" "$(hj I6.12)" "ecarte|voie: curseur.ouverts: forme"
assert_eq "I6.13 — clé interdite à toute profondeur" "$(hj I6.13)" "ecarte|cle-interdite: doing"
assert_eq "I6.14 — clé de cible" "$(hj I6.14)" "ecarte|cle-interdite: cibles"
assert_eq "I6.15 — fichier de plus de fichierOctets" "$(hj I6.15)" "ecarte|fichier trop gros"
assert_eq "I6.16 — lien symbolique refusé" "$(hj I6.16)" "ecarte|ouverture refusée (lien ou fichier illisible)"
assert_eq "I6.17 — tube (fichier non ordinaire) refusé sans bloquer" "$(hj I6.17)" "ecarte|pas un fichier ordinaire"
assert_eq "I6.18 — mode 0644 refusé" "$(hj I6.18)" "ecarte|droits trop larges"
assert_eq "I6.19 — propriétaire différent refusé" "$(hj I6.19)" "ecarte|autre propriétaire"
assert_eq "I6.20 — après écart, la mise à jour reconstruit un index égal à celui d'une passe" "$(hj I6.20)" "ecarte|true"
echo "=== P3 — fuzz du chargement ==="
GC="${VF_SEED:-$((RANDOM * 32768 + RANDOM))}"; echo "graine=$GC (rejouable : VF_SEED=$GC)"
for g in 1 2 "$GC"; do prop "$SCRIPTS" chargement --graine=$g; assert_eq "P3.1 — graine $g : 200 mutations d'un index valide, zéro index accepté qui viole un invariant (vérificateur écrit à part)" "$(pj "$VERT")" "true"; done
prop "$SCRIPTS" chargement --graine=1; assert_eq "P3.2 — couverture du fuzz : au moins 20 % de mutations écartées et 5 % acceptées" "$(pj 'j.couverture.comptes.ecartees>=40&&j.couverture.comptes.acceptees>=10')" "true"
M="$(mutant valide vf-cockpit-index-cache.mjs 'return r;' "return { ok: true, raison: '' };")" || M=""
if [ -n "$M" ]; then prop "$M" chargement --graine=1; assert_eq "M-VALIDE — P3.1 rouge : sans plantage, un index accepté viole un invariant" "$(pj 'j.plantage===null&&j.echecs.length>0&&j.echecs.every((e)=>e.classes.includes("index-accepte"))')" "true"; else assert_eq "M-VALIDE — mutant applicable" "non" "oui"; fi
echo "=== I7 — aucun contenu de transcript dans l'index ==="
mkdir -p "$WORK/f1/lab"; cc fuite "$SCRIPTS" "$WORK/f1" > "$WORK/fuite.json"; fj() { node "$AUX/get.mjs" "$WORK/fuite.json" "$1"; }
assert_eq "I7.0 — témoins : un marqueur injecté est trouvé, une clé interdite à profondeur 3 et une clé de cible aussi" "$(fj '[j.temoinMarqueur,j.temoinCle,j.temoinCible].join("|")')" "role|doing|cibles"
assert_eq "I7.1 — témoin positif : chaque marqueur est présent dans les transcripts générés et le chemin du lab aussi" "$(fj 'j.presents')" "[]"
assert_eq "I7.1 — balayage génératif : 30 transcripts générés et les fixtures, aucun marqueur ni chemin du lab dans l'index écrit" "$(fj 'JSON.stringify([j.voies>=30,j.fuites,j.brut])')" "[true,[],false]"
assert_eq "I7.2 — aucune des cinq clés du contrat ni clé de cible à toute profondeur du fichier" "$(fj 'j.cles')" "[]"
assert_eq "I7.3 — publique(voie) : champs de C3 seulement, sans curseur ni etatOfficiel ni cibles, rattachement nul" "$(fj 'j.publique')" "true"
M="$(mutant role vf-cockpit-index.mjs 'meta.agentType' 'meta.description')" || M=""
if [ -n "$M" ]; then mkdir -p "$WORK/f2/lab"; cc fuite "$M" "$WORK/f2" > "$WORK/fuite2.json"; assert_eq "M-FUITE — I7.1 rouge et nomme role (le rôle prend la description de tâche)" "$(node "$AUX/get.mjs" "$WORK/fuite2.json" 'j.fuites')" '["role"]'; else assert_eq "M-FUITE — mutant applicable" "non" "oui"; fi

echo ""; echo "Résultats : $PASS PASS / $FAIL FAIL"
[ $((PASS+FAIL)) -eq 0 ] && { echo "aucune assertion jouée"; exit 1; }
[ "$FAIL" -eq 0 ]
