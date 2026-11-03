#!/usr/bin/env node
// Spike 002 — onglet Projet : lit .planning/ (et les tags git) et rend un graphe au format
// floorplan/graph@1, que le viewer de floorplan affiche tel quel. Aucun LLM, lecture seule.
// Hiérarchie : jalon → phase → plans + exigences + mission (DAG) ; à côté : backlog, graines, releases.
// usage: node vf-project-graph.mjs <root> > project-graph.json
import fs from 'node:fs';
import path from 'node:path';
const TYPES = await import('../006-types-et-chrome-fr/vf-types.mjs').catch(() => null); // spike 006
import { execFileSync } from 'node:child_process';

const root = path.resolve(process.argv[2] || '.');
const P = (...a) => path.join(root, '.planning', ...a);
const rel = (abs) => path.relative(root, abs).split(path.sep).join('/');
const read = (f) => { try { return fs.readFileSync(f, 'utf8'); } catch { return ''; } };
const ls = (d) => { try { return fs.readdirSync(d); } catch { return []; } };
const clip = (s, n) => { s = String(s || '').replace(/\s+/g, ' ').replace(/\*\*/g, '').replace(/`/g, '').trim(); return s.length > n ? s.slice(0, n - 1).trimEnd() + '…' : s; };
const sentence = (s, n = 200) => { s = String(s || '').replace(/\s+/g, ' ').replace(/\*\*/g, '').replace(/`/g, '').trim(); const i = s.search(/[.!?](\s|$)/); return clip(i > 25 ? s.slice(0, i + 1) : s, n); };
const num = (s) => String(Number(s)) === s ? Number(s) : parseFloat(s);
const fm = (txt) => { const m = /^---\n([\s\S]*?)\n---/.exec(txt); const o = {}; if (!m) return o; for (const l of m[1].split('\n')) { const k = /^([\w-]+):\s*(.*)$/.exec(l); if (k) o[k[1]] = k[2].trim(); } return o; };
const list = (v) => (v || '').replace(/^\[|\]$/g, '').split(',').map((s) => s.trim().replace(/^["']|["']$/g, '')).filter(Boolean);

// ---------- sources ----------
const wsDirs = ls(P('workstreams')).filter((w) => fs.existsSync(P('workstreams', w, 'ROADMAP.md')));
const roadmaps = [...wsDirs.map((w) => P('workstreams', w, 'ROADMAP.md')), ...ls(P('milestones')).filter((f) => f.endsWith('-ROADMAP.md')).map((f) => P('milestones', f))];
const state = fm(read(P('workstreams', read(P('active-workstream')).trim() || 'fiabilite', 'STATE.md')));
const stateBody = read(P('workstreams', read(P('active-workstream')).trim() || 'fiabilite', 'STATE.md'));

// phases : checklist (nom + coché) et section ### Phase N (goal, depends, requirements)
const phases = new Map();
for (const f of roadmaps) {
  const txt = read(f);
  const ws = f.includes('/workstreams/') ? f.split('/workstreams/')[1].split('/')[0] : null;
  for (const m of txt.matchAll(/^- \[([ x])\] Phase (\d+(?:\.\d+)?): (.*)$/gm)) {
    if (phases.has(m[2])) continue;
    const name = m[3].replace(/\s*\((inscrite|completed|INSERTED|exécutée|cadrée|complete|clôturée|clos|CLOSE).*$/i, '').replace(/\s+—\s+(complete|clôturée|CLOSE).*$/i, '');
    phases.set(m[2], { n: m[2], name: clip(name, 90), done: m[1] === 'x', line: m[3], ws, roadmap: rel(f) });
  }
  for (const m of txt.matchAll(/^### Phase (\d+(?:\.\d+)?):\s*(.*)\n([\s\S]*?)(?=^### |^## |(?![\s\S]))/gm)) {
    const ph = phases.get(m[1]) || (phases.set(m[1], { n: m[1], name: clip(m[2], 90), done: false, line: '', ws, roadmap: rel(f) }), phases.get(m[1]));
    if (ph.goal) continue;
    const body = m[3];
    ph.goal = (/\*\*Goal:?\*\*:?\s*([\s\S]*?)(?=\n\*\*|\n\n)/.exec(body)?.[1] || '').trim();
    ph.depends = [...((/\*\*Depends on:?\*\*:?\s*(.*)/.exec(body)?.[1] || '').matchAll(/\b(\d+(?:\.\d+)?)\b/g))].map((x) => x[1]).filter((x) => x !== m[1]);
  }
}
// dossiers de phase (plans, SUMMARY) — compartiments actifs d'abord, archives ensuite
const phaseDir = new Map();
for (const base of [...wsDirs.map((w) => P('workstreams', w, 'phases')), ...ls(P('milestones')).filter((d) => d.endsWith('-phases')).map((d) => P('milestones', d))])
  for (const d of ls(base)) { const m = /^VFDO-(\d+(?:\.\d+)?)-/.exec(d); if (m && !phaseDir.has(m[1])) phaseDir.set(m[1], path.join(base, d)); }
// exigences : cases à cocher + table de traçabilité (exigence → phase)
const reqs = new Map();
const reqFiles = [...wsDirs.map((w) => P('workstreams', w, 'REQUIREMENTS.md')), ...ls(P('milestones')).filter((f) => f.endsWith('-REQUIREMENTS.md')).map((f) => P('milestones', f))];
for (const f of reqFiles) {
  const txt = read(f);
  for (const m of txt.matchAll(/^- \[([ x])\] \*\*([A-Z][A-Z0-9]*-\d+[a-z]?)\*\*:?\s*(.*)$/gm)) if (!reqs.has(m[2])) reqs.set(m[2], { id: m[2], done: m[1] === 'x', text: m[3], file: rel(f) });
  for (const m of txt.matchAll(/^\|\s*([A-Z][A-Z0-9]*-\d+[a-z]?)\s*\|\s*Phase (\d+(?:\.\d+)?)/gm)) { const r = reqs.get(m[1]); if (r && !r.phase) r.phase = m[2]; }
}
// jalons : la liste ## Milestones, avec leurs plages de phases
const milestones = [];
for (const f of roadmaps.slice(0, wsDirs.length)) {
  const sec = /## Milestones\n([\s\S]*?)(?=\n## |\n> )/.exec(read(f))?.[1] || '';
  for (const m of sec.matchAll(/^- (\S+) \*\*([\w.-]+)\*\* — ([\s\S]*?)(?=\n- |(?![\s\S]))/gm)) {
    if (milestones.some((x) => x.key === m[2])) continue;
    const text = m[3].replace(/\s+/g, ' ');
    // « Phases 30-35, 37-41.4 + Phases 18 et 25 héritées — … » : tout jusqu'au premier — ou (
    const range = (/Phases? ([^—(]*)/.exec(text)?.[1] || '').replace(/Phases?|\*\*/g, '');
    const set = new Set();
    for (const part of range.split(/,|\+|\bet\b/)) {
      const r = /(\d+(?:\.\d+)?)\s*(?:-|→)\s*(\d+(?:\.\d+)?)/.exec(part);
      if (r) { for (const k of phases.keys()) if (num(k) >= num(r[1]) && Math.floor(num(k)) <= num(r[2])) set.add(k); }
      else for (const x of part.matchAll(/\d+(?:\.\d+)?/g)) set.add(x[0]);
    }
    // une phase « héritée » plus loin appartient au jalon qui la cite en dernier
    for (const k of set) for (const o of milestones) o.phases.delete(k);
    milestones.push({ key: m[2], icon: m[1], text, phases: set, ws: f.split('/workstreams/')[1]?.split('/')[0] });
  }
}
for (const ms of milestones) for (const k of [...ms.phases]) if (!phases.has(k)) ms.phases.delete(k);

// ---------- graphe ----------
const nodes = [], files = [], links = [];
const node = (o) => { nodes.push({ details: '', tags: [], paths: [], packages: [], hosts: [], stats: { files: 0, loc: 0, langs: {}, repos: ['.'] }, ...o }); return o.id; };
const file = (o) => { files.push({ r: '.', l: null, loc: 0, h: '', sig: '', ...o }); for (let n = o.n; n; n = nodes.find((x) => x.id === n)?.parent) { const x = nodes.find((y) => y.id === n); if (x) x.stats.files++; } return 'f:' + o.p; };
const link = (a, b, k, label) => links.push({ a, b, k, w: 1, ...(label ? { label } : {}) });
const pct = (a, b) => b ? Math.round((100 * a) / b) : 0;
const curPhase = String(state.current_phase || '');

const sortPh = (a, b) => num(a) - num(b);
const phaseStatus = (ph) => ph.done ? 'done' : (ph.n === curPhase && state.status !== 'closed') ? 'active' : 'todo';
const order = ['active', 'todo', 'done'];
const msList = milestones.map((ms) => {
  const ks = [...ms.phases].sort(sortPh);
  const done = ks.filter((k) => phases.get(k).done).length;
  const st = ms.icon === '✅' ? 'done' : done > 0 && done < ks.length ? 'active' : done === ks.length && ks.length ? 'done' : ms.icon === '🚧' ? 'active' : 'todo';
  return { ...ms, ks, done, st };
});
// les jalons clos se rangent dans « Historique » : la racine ne garde que ce qui vit
const closed = msList.filter((m) => m.st === 'done');
const hist = closed.length ? node({ id: 'history', parent: null, label: 'Historique', kind: 'historique', summary: `Les ${closed.length} jalons clos, du premier au dernier.`,
  st: 'done', foot: `${closed.length} jalons · ${closed.reduce((s, m) => s + m.ks.length, 0)} phases` }) : null;
let prevMs = null;
for (const ms of msList) {
  if (prevMs && ms.st !== 'done' && prevMs.startsWith('ms-') && closed.some((m) => 'ms-' + m.key === prevMs)) { link('n:history', 'n:ms-' + ms.key, 'event', 'puis'); prevMs = 'ms-' + ms.key; }
  const msId = node({ id: 'ms-' + ms.key, parent: ms.st === 'done' ? hist : null, label: ms.key, kind: 'jalon', summary: sentence(ms.text.replace(/^[^—]*—\s*/, ''), 180) || ms.text,
    details: ms.text, st: ms.st, foot: `${ms.done}/${ms.ks.length} phases · ${pct(ms.done, ms.ks.length)} %`, tags: [ms.ws ? 'compartiment ' + ms.ws : ''].filter(Boolean) });
  if (prevMs && prevMs !== msId && !ms.key.startsWith('gouvernance')) link('n:' + prevMs, 'n:' + msId, 'event', 'puis');
  if (!ms.key.startsWith('gouvernance')) prevMs = msId;
  for (const k of ms.ks) {
    const ph = phases.get(k);
    const st = phaseStatus(ph);
    const dir = phaseDir.get(k);
    const planFiles = ls(dir).filter((f) => /-PLAN\.md$/.test(f)).sort();
    const sums = new Set(ls(dir).filter((f) => /-SUMMARY\.md$/.test(f)).map((f) => f.replace('-SUMMARY.md', '')));
    const phReqs = [...reqs.values()].filter((r) => r.phase === k);
    const phId = node({ id: `ph-${k}`, parent: msId, label: `Phase ${k} · ${ph.name}`, kind: 'phase', summary: sentence(ph.goal || ph.line || ph.name, 200),
      details: [ph.goal, ph.depends?.length ? `Dépend de : Phase ${ph.depends.join(', ')}.` : '', ph.line ? `Ligne de ROADMAP : ${ph.line}` : '', `Source : ${ph.roadmap}${dir ? ` · dossier ${rel(dir)}` : ''}`].filter(Boolean).join('\n\n'),
      st, foot: [planFiles.length ? `${sums.size}/${planFiles.length} plans` : '', phReqs.length ? `${phReqs.filter((r) => r.done).length}/${phReqs.length} exigences` : ''].filter(Boolean).join(' · ') || 'pas de plan', paths: dir ? [rel(dir)] : [] });
    // plans
    for (const pf of planFiles) {
      const txt = read(path.join(dir, pf));
      const meta = fm(txt);
      const id = pf.replace('-PLAN.md', '');
      const obj = /<objective>\s*([\s\S]*?)<\/objective>/.exec(txt)?.[1] || /^#\s+(.*)$/m.exec(txt)?.[1] || '';
      const touched = list(meta.files_modified);
      const p = rel(path.join(dir, pf));
      file({ p, n: phId, name: `${id} — ${clip(obj.split('\n')[0], 70)}`, d: sentence(obj, 220), st: sums.has(id) || ph.done ? 'done' : st === 'active' ? 'active' : 'todo',
        foot: `vague ${meta.wave || '?'}${touched.length ? ` · ${touched.length} fichiers` : ''}`, note: touched.length ? `Fichiers touchés : ${touched.slice(0, 12).join(', ')}${touched.length > 12 ? ` … (+${touched.length - 12})` : ''}` : undefined, touched });
      for (const dep of list(meta.depends_on)) { const dp = planFiles.find((x) => x.startsWith(dep.length <= 3 ? `${k.split('.')[0]}-${dep.padStart(2, '0')}` : dep)); if (dp) link('f:' + rel(path.join(dir, dp)), 'f:' + p, 'import', 'puis'); }
      for (const r of list(meta.requirements)) if (reqs.has(r)) link('f:' + p, `f:req/${r}`, 'data', 'couvre');
    }
    // exigences de la phase
    if (phReqs.length) {
      const rId = node({ id: `ph-${k}.req`, parent: phId, label: 'Exigences', kind: 'exigences', summary: `${phReqs.filter((r) => r.done).length} cochées sur ${phReqs.length}.`, foot: `${phReqs.filter((r) => r.done).length}/${phReqs.length}`, st: phReqs.every((r) => r.done) ? 'done' : phReqs.some((r) => r.done) ? 'active' : 'todo' });
      for (const r of phReqs) file({ p: `req/${r.id}`, n: rId, name: r.id, d: sentence(r.text, 220), st: r.done ? 'done' : 'todo', foot: r.file.split('/').pop() });
    }
  }
}
// dépendances entre phases
for (const ph of phases.values()) for (const d of ph.depends || []) if (nodes.some((n) => n.id === 'ph-' + d) && nodes.some((n) => n.id === 'ph-' + ph.n)) link('n:ph-' + d, 'n:ph-' + ph.n, 'import', 'dépend de');
// missions : chaque DAG rattaché à sa phase quand son nom le dit, sinon « hors phase »
const dags = [...ls(P()).filter((f) => /\.dag\.json$/.test(f)).map((f) => P(f)), ...wsDirs.flatMap((w) => ls(P('workstreams', w)).filter((f) => /\.dag\.json$/.test(f)).map((f) => P('workstreams', w, f))), ...ls(P('missions')).filter((f) => /\.dag\.json$/.test(f)).map((f) => P('missions', f))];
const DST = { done: 'done', running: 'active', ready: 'todo', blocked: 'todo', failed: 'blocked' }; // dag.sh : blocked = en attente des deps
let loose = null;
for (const d of dags) {
  let j; try { j = JSON.parse(read(d)); } catch { continue; }
  if (!Array.isArray(j.nodes)) continue;
  const name = path.basename(d, '.dag.json');
  const k = /^MISSION-(\d+(?:\.\d+)?)/.exec(name)?.[1];
  let parent = k && nodes.some((n) => n.id === 'ph-' + k) ? 'ph-' + k : null;
  if (!parent) loose ||= node({ id: 'missions', parent: null, label: 'Missions hors phase', kind: 'mission', summary: 'Plans de bataille de missions qui ne portent pas un numéro de phase.' }), parent = loose;
  const doneN = j.nodes.filter((x) => x.status === 'done').length;
  const mId = node({ id: 'dag-' + name, parent, label: `Mission ${name.replace(/^MISSION-/, '')}`, kind: 'mission', summary: `Plan de bataille : ${j.nodes.length} nœuds, ${doneN} faits.`,
    st: doneN === j.nodes.length ? 'done' : j.nodes.some((x) => x.status === 'running') ? 'active' : j.nodes.some((x) => x.status === 'failed') ? 'blocked' : 'todo',
    foot: `${doneN}/${j.nodes.length} nœuds`, paths: [rel(d)] });
  for (const x of j.nodes) file({ p: `${rel(d)}#${x.id}`, n: mId, name: x.id, d: sentence(x.step, 200), st: DST[x.status] || 'todo', foot: x.stage || '', note: x.scope?.length ? `Périmètre : ${x.scope.join(', ')}` : undefined, touched: x.scope });
  for (const x of j.nodes) for (const dep of x.deps || []) link(`f:${rel(d)}#${dep}`, `f:${rel(d)}#${x.id}`, 'queue', 'puis');
}
// backlog, graines, releases
const bl = node({ id: 'backlog', parent: null, label: 'Backlog', kind: 'backlog', summary: 'Ce qui est consigné, différé ou investigué, hors des jalons.' });
for (const m of read(P('BACKLOG.md')).matchAll(/^## (.*)\n([\s\S]*?)(?=^## |(?![\s\S]))/gm)) {
  const [title, status] = m[1].split(/\s+—\s+(?=[A-ZÉ]{4,}|consigné|mesuré)/);
  const st = /DIFFÉRÉ|consigné|REPORTÉ/i.test(status || '') ? 'todo' : /INVESTIGUÉ|mesuré/i.test(status || '') ? 'done' : 'todo';
  file({ p: `.planning/BACKLOG.md#${title.toLowerCase().replace(/[^a-z0-9à-ÿ]+/g, '-').slice(0, 60)}`, n: bl, name: clip(title, 80), d: sentence(m[2].replace(/^>.*$/gm, ''), 220), st, foot: clip(status || '', 40) });
}
const sd = node({ id: 'seeds', parent: null, label: 'Graines', kind: 'graine', summary: 'Idées de jalons futurs, avec leurs déclencheurs.' });
for (const f of ls(P('seeds')).filter((f) => f.endsWith('.md'))) { const t = read(P('seeds', f)); file({ p: rel(P('seeds', f)), n: sd, name: clip(/^#\s+(.*)$/m.exec(t)?.[1] || f, 80), d: sentence(t.replace(/^---[\s\S]*?---/, '').replace(/^#.*$/gm, ''), 220), st: 'todo' }); }
const rl = node({ id: 'releases', parent: null, label: 'Releases', kind: 'release', summary: 'Les 30 derniers tags publiés.' });
try {
  const out = execFileSync('git', ['-C', root, 'for-each-ref', '--sort=-creatordate', '--count=30', '--format=%(refname:short)\t%(creatordate:short)\t%(contents:subject)', 'refs/tags/v*'], { encoding: 'utf8' });
  for (const l of out.trim().split('\n').filter(Boolean)) { const [t, date, subj] = l.split('\t'); file({ p: `tag/${t}`, n: rl, name: t, d: clip(subj, 200), st: 'done', foot: date }); }
} catch {}
const relCount = files.filter((f) => f.n === rl).length;
for (const [id, unit] of [['backlog', 'entrées'], ['seeds', 'graines']]) { const n = nodes.find((x) => x.id === id); n.foot = `${files.filter((f) => f.n === id).length} ${unit}`; }
if (loose) { const n = nodes.find((x) => x.id === 'missions'); n.foot = `${nodes.filter((x) => x.parent === 'missions').length} missions`; }
Object.assign(nodes.find((n) => n.id === 'releases'), { foot: `${relCount} tags`, kind: 'release' });

// ---------- liens entre onglets : plan ou nœud de mission → fichiers de code touchés ----------
const active = msList.find((m) => m.st === 'active' && !m.key.startsWith('gouvernance')) || msList.at(-1);
const flows = [];
if (active) flows.push({ id: 'trajectoire', title: `Trajectoire de ${active.key}`, description: 'Les phases du jalon en cours, dans l\'ordre.',
  steps: active.ks.map((k) => ({ ref: 'n:ph-' + k, note: `${phases.get(k).done ? '✓' : '○'} ${phases.get(k).name}` })) });
const G = {
  schema: 'floorplan/graph@1',
  meta: { generatedAt: new Date().toISOString(), rootName: path.basename(root), root, audience: 'everyone', agent: 'claude', repos: [], counts: { files: files.length, loc: 0 },
    vfTab: 'project',
    kindIcons: TYPES?.KIND_ICONS, kindColors: TYPES?.KIND_COLORS, // spike 006 : pictogrammes (patch P8) et couleurs des types
    kindLabels: { import: 'Dépend de', event: 'Enchaînement', data: 'Couvre', queue: 'Étape suivante', call: 'Dispatche', contains: 'Contient' },
    vf: { milestone: state.milestone, phase: curPhase, phaseName: state.current_phase_name, status: state.status, lastActivity: state.last_activity, lastDesc: state.last_activity_desc,
      progress: state.progress, milestones: msList.map((m) => ({ key: m.key, st: m.st, done: m.done, total: m.ks.length, id: 'n:ms-' + m.key })),
      next: active ? active.ks.filter((k) => !phases.get(k).done).map((k) => ({ id: 'n:ph-' + k, label: `Phase ${k} · ${phases.get(k).name}` })) : [],
      counts: { phases: phases.size, plans: files.filter((f) => f.p.endsWith('-PLAN.md')).length, reqs: reqs.size, reqsDone: [...reqs.values()].filter((r) => r.done).length, dags: dags.length } } },
  project: { name: 'VibeFlow — Projet', summary: `Jalon ${state.milestone || '?'} · phase ${curPhase} (${state.current_phase_name || ''}) · ${state.status || ''}.` },
  nodes, files, routes: [], links: links.filter((l) => [l.a, l.b].every((x) => x.startsWith('n:') ? nodes.some((n) => 'n:' + n.id === x) : files.some((f) => 'f:' + f.p === x))),
  flows, tour: [],
};
process.stdout.write(JSON.stringify(G));
console.error(`projet : ${msList.length} jalons, ${nodes.filter((n) => n.id.startsWith('ph-') && !n.id.includes('.')).length} phases, ${G.meta.vf.counts.plans} plans, ${files.filter((f) => f.p.startsWith('req/')).length} exigences rattachées, ${dags.length} DAG, ${G.links.length} liens`);
