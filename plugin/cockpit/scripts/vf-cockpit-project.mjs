#!/usr/bin/env node
// vf-cockpit-project — graphe Projet du cockpit (promu du spike 002, généralisé : lab plat, partitionné, sans jalons).
// Export : buildProjectGraph(root, { layout }) -> schéma vibeflow/cockpit-project@1 (format du viewer :
//   nodes, files, links, flows, tour, routes, meta, project). CLI : node vf-cockpit-project.mjs <root> (JSON compact).
// Hiérarchie : jalon -> phase -> plans + exigences ; missions (DAG) rattachées à leur phase ; backlog, graines, releases.
// Identité d'une phase = (compartiment, numéro) : `ph-<N>` si le numéro est unique dans le lab, sinon `ph-<N>@<ws>`.
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { planningLayout } from './vf-cockpit-paths.mjs';
import { readPlanning, clip, sentence, num, normNum, fm, list } from './vf-cockpit-planning.mjs';
import { KIND_ICONS, KIND_COLORS } from './vf-cockpit-types.mjs';

const read = (f) => { try { return fs.readFileSync(f, 'utf8'); } catch { return ''; } };
const ls = (d) => { try { return fs.readdirSync(d); } catch { return []; } };
const DST = { done: 'done', running: 'active', ready: 'todo', blocked: 'todo', failed: 'blocked' }; // dag.sh : blocked = en attente des deps
const pct = (a, b) => (b ? Math.round((100 * a) / b) : 0);

export function buildProjectGraph(root, { layout } = {}) {
  root = path.resolve(root); layout = layout || planningLayout(root);
  const P = readPlanning(root, layout); const { rel, state, phases, reqs } = P;
  const nodes = [], files = [], links = [];
  const node = (o) => { nodes.push({ details: '', tags: [], paths: [], packages: [], hosts: [], stats: { files: 0, loc: 0, langs: {}, repos: ['.'] }, ...o }); return o.id; };
  const file = (o) => { files.push({ r: '.', l: null, loc: 0, h: '', sig: '', ...o }); for (let n = o.n; n; n = nodes.find((x) => x.id === n)?.parent) { const x = nodes.find((y) => y.id === n); if (x) x.stats.files++; } return 'f:' + o.p; };
  const link = (a, b, k, label) => links.push({ a, b, k, w: 1, ...(label ? { label } : {}) });
  const curPhase = String(state.current_phase || '');
  const count = new Map(); for (const ph of phases.values()) count.set(ph.n, (count.get(ph.n) || 0) + 1);
  const phId = (ph) => (count.get(ph.n) > 1 && ph.ws ? `ph-${ph.n}@${ph.ws}` : `ph-${ph.n}`);
  // une référence se résout d'abord dans le compartiment qui la porte, sinon par numéro unique dans le lab
  const findPhase = (n, ws) => { const c = [...phases.values()].filter((p) => p.n === normNum(n)); return c.find((p) => (p.ws || '') === (ws || '')) || (c.length === 1 ? c[0] : null); };
  const dirOf = (ph) => P.phaseDirs.get(`${ph.ws || ''}|${ph.n}`) || P.phaseDirs.get(`*|${ph.n}`);
  const reqOf = (id, ws) => reqs.get(`${ws || ''}|${id}`) || reqs.get(`*|${id}`);
  const reqPath = (r) => `req/${r.ws ? r.ws + '/' : ''}${r.id}`;
  const ownReqs = (ph) => [...reqs.values()].filter((r) => r.phase === ph.n && (r.wsKey === '*' || r.wsKey === (ph.ws || '')));
  const activeWs = layout.forme === 'partitionne' ? layout.actif : null;
  const phaseStatus = (ph) => ph.done ? 'done' : (ph.n === curPhase && state.status !== 'closed' && (!activeWs || ph.ws === activeWs)) ? 'active' : 'todo';

  // jalons : ceux de la section « ## Milestones », sinon un jalon synthétique « Phases » ; les phases orphelines y vont aussi
  const inMs = new Set(P.milestones.flatMap((m) => [...m.phases]));
  const loose = [...phases.values()].filter((p) => !p.archive && !inMs.has(p.key));
  const ms0 = [...P.milestones];
  if (loose.length) ms0.push({ key: 'Phases', id: 'ms-phases', icon: '', text: 'Phases du lab', phases: new Set(loose.map((p) => p.key)), ws: null, synthetic: true });
  const sortPh = (a, b) => num(a.n) - num(b.n);
  const msList = ms0.map((ms) => {
    const ks = [...ms.phases].map((k) => phases.get(k)).filter(Boolean).sort(sortPh);
    const done = ks.filter((p) => p.done).length;
    const st = ms.icon === '✅' ? 'done' : done > 0 && done < ks.length ? 'active' : done === ks.length && ks.length ? 'done' : ms.icon === '🚧' || (ms.synthetic && ks.length) ? 'active' : 'todo';
    return { ...ms, ks, done, st };
  });
  const closed = msList.filter((m) => m.st === 'done');
  const hist = closed.length ? node({ id: 'history', parent: null, label: 'Historique', kind: 'historique', summary: `Les ${closed.length} jalons clos, du premier au dernier.`, st: 'done', foot: `${closed.length} jalons · ${closed.reduce((s, m) => s + m.ks.length, 0)} phases` }) : null;
  const prev = new Map(); // enchaînement « puis » limité à un même compartiment
  for (const ms of msList) {
    const wk = ms.ws || '';
    const msId = node({ id: ms.id, parent: ms.st === 'done' ? hist : null, label: ms.key, kind: 'jalon', summary: sentence(ms.text.replace(/^[^—]*—\s*/, ''), 180) || ms.text, details: ms.text, st: ms.st,
      foot: `${ms.done}/${ms.ks.length} phases · ${pct(ms.done, ms.ks.length)} %`, tags: [ms.ws ? 'compartiment ' + ms.ws : ''].filter(Boolean) });
    const pv = prev.get(wk);
    if (pv && ms.st !== 'done' && closed.some((m) => m.id === pv)) { link('n:history', 'n:' + msId, 'event', 'puis'); prev.set(wk, msId); }
    else if (pv && pv !== msId) { link('n:' + pv, 'n:' + msId, 'event', 'puis'); prev.set(wk, msId); }
    else if (!pv) prev.set(wk, msId);
    for (const ph of ms.ks) addPhase(ph, msId);
  }
  function addPhase(ph, msId) {
    const st = phaseStatus(ph), dir = dirOf(ph);
    const planFiles = ls(dir).filter((f) => /-PLAN\.md$/.test(f)).sort();
    const sums = new Set(ls(dir).filter((f) => /-SUMMARY\.md$/.test(f)).map((f) => f.replace('-SUMMARY.md', '')));
    const phReqs = ownReqs(ph); const id = phId(ph);
    node({ id, parent: msId, label: `Phase ${ph.n} · ${ph.name}`, kind: 'phase', num: ph.n, ws: ph.ws, summary: sentence(ph.goal || ph.line || ph.name, 200),
      details: [ph.goal, ph.depends.length ? `Dépend de : Phase ${ph.depends.join(', ')}.` : '', ph.line ? `Ligne de ROADMAP : ${ph.line}` : '', `Source : ${ph.roadmap}${dir ? ` · dossier ${rel(dir)}` : ''}`].filter(Boolean).join('\n\n'),
      st, foot: [planFiles.length ? `${sums.size}/${planFiles.length} plans` : '', phReqs.length ? `${phReqs.filter((r) => r.done).length}/${phReqs.length} exigences` : ''].filter(Boolean).join(' · ') || 'pas de plan', paths: dir ? [rel(dir)] : [] });
    for (const pf of planFiles) {
      const txt = read(path.join(dir, pf)); const meta = fm(txt); const pid = pf.replace('-PLAN.md', '');
      const obj = /<objective>\s*([\s\S]*?)<\/objective>/.exec(txt)?.[1] || /^#\s+(.*)$/m.exec(txt)?.[1] || '';
      const touched = list(meta.files_modified); const p = rel(path.join(dir, pf));
      file({ p, n: id, name: `${pid} — ${clip(obj.split('\n').find((l) => l.trim()) || '', 70)}`, d: sentence(obj, 220), st: sums.has(pid) || ph.done ? 'done' : st === 'active' ? 'active' : 'todo',
        foot: `vague ${meta.wave || '?'}${touched.length ? ` · ${touched.length} fichiers` : ''}`, note: touched.length ? `Fichiers touchés : ${touched.slice(0, 12).join(', ')}${touched.length > 12 ? ` … (+${touched.length - 12})` : ''}` : undefined, touched });
      for (const dep of list(meta.depends_on)) { const dp = planFiles.find((x) => x.startsWith(dep.length <= 3 ? `${pf.split('-')[0]}-${dep.padStart(2, '0')}` : dep)); if (dp) link('f:' + rel(path.join(dir, dp)), 'f:' + p, 'import', 'puis'); }
      for (const r of list(meta.requirements)) { const rq = reqOf(r, ph.ws); if (rq) link('f:' + p, 'f:' + reqPath(rq), 'data', 'couvre'); }
    }
    if (phReqs.length) {
      const rId = node({ id: `${id}.req`, parent: id, label: 'Exigences', kind: 'exigences', summary: `${phReqs.filter((r) => r.done).length} cochées sur ${phReqs.length}.`, foot: `${phReqs.filter((r) => r.done).length}/${phReqs.length}`, st: phReqs.every((r) => r.done) ? 'done' : phReqs.some((r) => r.done) ? 'active' : 'todo' });
      for (const r of phReqs) file({ p: reqPath(r), n: rId, name: r.id, d: sentence(r.text, 220), st: r.done ? 'done' : 'todo', foot: r.file.split('/').pop() });
    }
  }
  for (const ph of phases.values()) for (const d of ph.depends) { const dp = findPhase(d, ph.ws); if (dp && nodes.some((n) => n.id === phId(dp)) && nodes.some((n) => n.id === phId(ph))) link('n:' + phId(dp), 'n:' + phId(ph), 'import', 'dépend de'); }

  // missions : chaque DAG rattaché à sa phase quand son nom le dit, sinon « hors phase »
  let orphan = null;
  for (const d of P.dags) {
    const k = /^MISSION-(\d+(?:\.\d+)?)/.exec(d.name)?.[1];
    const tp = k ? findPhase(k, d.ws) : null;
    let parent = tp && nodes.some((n) => n.id === phId(tp)) ? phId(tp) : null;
    if (!parent) { orphan ||= node({ id: 'missions', parent: null, label: 'Missions hors phase', kind: 'mission', summary: 'Plans de bataille de missions qui ne portent pas un numéro de phase.' }); parent = orphan; }
    const doneN = d.nodes.filter((x) => x.status === 'done').length;
    const mId = node({ id: 'dag-' + d.name, parent, label: `Mission ${d.name.replace(/^MISSION-/, '')}`, kind: 'mission', summary: `Plan de bataille : ${d.nodes.length} nœuds, ${doneN} faits.`,
      st: doneN === d.nodes.length ? 'done' : d.nodes.some((x) => x.status === 'running') ? 'active' : d.nodes.some((x) => x.status === 'failed') ? 'blocked' : 'todo', foot: `${doneN}/${d.nodes.length} nœuds`, paths: [d.file] });
    for (const x of d.nodes) file({ p: `${d.file}#${x.id}`, n: mId, name: x.id, d: sentence(x.step, 200), st: DST[x.status] || 'todo', foot: x.stage || '', note: x.scope?.length ? `Périmètre : ${x.scope.join(', ')}` : undefined, touched: x.scope });
    for (const x of d.nodes) for (const dep of x.deps || []) link(`f:${d.file}#${dep}`, `f:${d.file}#${x.id}`, 'queue', 'puis');
  }
  if (orphan) nodes.find((x) => x.id === 'missions').foot = `${nodes.filter((x) => x.parent === 'missions').length} missions`;

  // backlog, graines, releases
  const bl = node({ id: 'backlog', parent: null, label: 'Backlog', kind: 'backlog', summary: 'Ce qui est consigné, différé ou investigué, hors des jalons.' });
  for (const m of P.backlog.matchAll(/^## (.*)\n([\s\S]*?)(?=^## |(?![\s\S]))/gm)) {
    const [title, status] = m[1].split(/\s+—\s+(?=[A-ZÉ]{4,}|consigné|mesuré)/);
    file({ p: `.planning/BACKLOG.md#${title.toLowerCase().replace(/[^a-z0-9à-ÿ]+/g, '-').slice(0, 60)}`, n: bl, name: clip(title, 80), d: sentence(m[2].replace(/^>.*$/gm, ''), 220), st: /INVESTIGUÉ|mesuré/i.test(status || '') ? 'done' : 'todo', foot: clip(status || '', 40) });
  }
  const sd = node({ id: 'seeds', parent: null, label: 'Graines', kind: 'graine', summary: 'Idées de jalons futurs, avec leurs déclencheurs.' });
  for (const s of P.seeds) file({ p: s.file, n: sd, name: clip(/^#\s+(.*)$/m.exec(s.text)?.[1] || path.basename(s.file), 80), d: sentence(s.text.replace(/^---[\s\S]*?---/, '').replace(/^#.*$/gm, ''), 220), st: 'todo' });
  const rl = node({ id: 'releases', parent: null, label: 'Releases', kind: 'release', summary: 'Les 30 derniers tags publiés.' });
  for (const t of P.tags) file({ p: `tag/${t.tag}`, n: rl, name: t.tag, d: clip(t.subject, 200), st: 'done', foot: t.date });
  for (const [id, unit] of [['backlog', 'entrées'], ['seeds', 'graines']]) nodes.find((x) => x.id === id).foot = `${files.filter((f) => f.n === id).length} ${unit}`;
  nodes.find((n) => n.id === 'releases').foot = `${P.tags.length} tags`;

  const active = msList.find((m) => m.st === 'active') || msList.at(-1);
  const flows = active ? [{ id: 'trajectoire', title: `Trajectoire de ${active.key}`, description: "Les phases du jalon en cours, dans l'ordre.", steps: active.ks.map((p) => ({ ref: 'n:' + phId(p), note: `${p.done ? '✓' : '○'} ${p.name}` })) }] : [];
  const ids = new Set(nodes.map((n) => 'n:' + n.id)), fids = new Set(files.map((f) => 'f:' + f.p));
  return {
    schema: 'vibeflow/cockpit-project@1',
    meta: { generatedAt: new Date().toISOString(), rootName: path.basename(root), root, audience: 'everyone', agent: 'claude', repos: [], counts: { files: files.length, loc: 0 }, vfTab: 'project',
      kindIcons: KIND_ICONS, kindColors: KIND_COLORS,
      kindLabels: { import: 'Dépend de', event: 'Enchaînement', data: 'Couvre', queue: 'Étape suivante', call: 'Dispatche', contains: 'Contient' },
      vf: { milestone: state.milestone, phase: curPhase, phaseName: state.current_phase_name, status: state.status, lastActivity: state.last_activity, lastDesc: state.last_activity_desc, progress: state.progress,
        milestones: msList.map((m) => ({ key: m.key, st: m.st, done: m.done, total: m.ks.length, id: 'n:' + m.id })),
        next: active ? active.ks.filter((p) => !p.done).map((p) => ({ id: 'n:' + phId(p), label: `Phase ${p.n} · ${p.name}` })) : [],
        counts: { phases: phases.size, plans: files.filter((f) => f.p.endsWith('-PLAN.md')).length, reqs: reqs.size, reqsDone: [...reqs.values()].filter((r) => r.done).length, dags: P.dags.length } },
      layout: { forme: layout.forme, actif: layout.actif } },
    project: { name: `${P.projectName} — Projet`, summary: `Jalon ${state.milestone || '?'} · phase ${curPhase || '?'} (${state.current_phase_name || ''}) · ${state.status || ''}.` },
    nodes, files, routes: [], links: links.filter((l) => [l.a, l.b].every((x) => (x.startsWith('n:') ? ids.has(x) : fids.has(x)))), flows, tour: [],
  };
}

if (process.argv[1] && import.meta.url === pathToFileURL(fs.realpathSync(process.argv[1])).href) process.stdout.write(JSON.stringify(buildProjectGraph(process.argv[2] || '.')));
