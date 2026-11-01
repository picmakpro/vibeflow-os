#!/usr/bin/env node
// Spike 002 — assemble le cockpit : floorplan/index.html (onglet Code) et floorplan/project.html
// (onglet Projet) sur le même viewer, sans LLM. Puis : node floorplan/serve.mjs
// usage: node build-cockpit.mjs <root>
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const FP = path.join(HERE, 'floorplan', 'scripts');
const root = path.resolve(process.argv[2] || '.');
const out = path.join(root, 'floorplan');
const run = (script, ...a) => execFileSync(process.execPath, [script, root, ...a], { encoding: 'utf8', maxBuffer: 256 << 20 });
const t0 = Date.now();

run(path.join(FP, 'scan.mjs'));
console.log(run(path.join(HERE, 'vf-code-arch.mjs')).trim());
const project = JSON.parse(execFileSync(process.execPath, [path.join(HERE, 'vf-project-graph.mjs'), root], { encoding: 'utf8', maxBuffer: 256 << 20, stdio: ['ignore', 'pipe', 'inherit'] }));

// Recent work de floorplan = les deux dernières phases exécutées du jalon en cours (plans à SUMMARY)
const phaseNodes = project.nodes.filter((n) => /^ph-[\d.]+$/.test(n.id));
const recentPhases = phaseNodes.filter((n) => project.files.some((f) => f.n === n.id && f.st === 'done' && f.touched?.length))
  .sort((a, b) => parseFloat(b.id.slice(3)) - parseFloat(a.id.slice(3))).slice(0, 2);
const scanFiles = new Set(JSON.parse(fs.readFileSync(path.join(out, '.cache', 'scan.json'), 'utf8')).files.map((f) => f.path));
fs.writeFileSync(path.join(out, 'recent-work.json'), JSON.stringify({ updatedAt: new Date().toISOString(), tasks: recentPhases.map((ph) => {
  const items = new Map();
  for (const f of project.files.filter((x) => x.n === ph.id && x.touched)) for (const p of f.touched) if (scanFiles.has(p) && !p.startsWith('.planning/') && !items.has(p)) items.set(p, { ref: p, change: 'changed', note: `${f.name}` });
  return { title: ph.label.slice(0, 60), request: ph.summary, summary: ph.foot, items: [...items.values()].slice(0, 40) };
}) }, null, 2));

const build = run(path.join(FP, 'build.mjs'), '--no-claude-md');
console.log(build.split('\n').filter((l) => /^(LINKS|RECENT|✓|✗|  - )/.test(l)).join('\n'));

// onglet Code : descriptions tirées du frontmatter (agents, skills) ou de l'en-tête des scripts,
// et l'index inverse fichier → plans / nœuds de mission qui l'ont touché
const g = JSON.parse(fs.readFileSync(path.join(out, 'graph.json'), 'utf8'));
const read = (p) => { try { return fs.readFileSync(path.join(root, p), 'utf8'); } catch { return ''; } };
const sentence = (s, n = 200) => { s = String(s || '').replace(/\s+/g, ' ').replace(/[`*]/g, '').trim(); const i = s.search(/[.!?](\s|$)/); s = i > 25 ? s.slice(0, i + 1) : s; return s.length > n ? s.slice(0, n - 1) + '…' : s; };
let described = 0;
for (const f of g.files) {
  const txt = read(f.p).slice(0, 6000);
  const fmBlock = /^---\n([\s\S]*?)\n---/.exec(txt)?.[1];
  let d = '';
  if (fmBlock) { d = /^description:\s*"?(.*?)"?\s*$/m.exec(fmBlock)?.[1] || ''; const nm = /^name:\s*(.*)$/m.exec(fmBlock)?.[1]; if (nm) f.name = nm.trim(); }
  else if (/\.(sh|bash)$/.test(f.p)) d = txt.split('\n').slice(txt.startsWith('#!') ? 1 : 0).filter((l, i, a) => /^#/.test(l) && a.slice(0, i).every((x) => /^#/.test(x))).map((l) => l.replace(/^#+\s?/, '')).join(' ');
  else if (f.p.endsWith('.md')) d = txt.replace(/^#.*$/gm, '').split(/\n\s*\n/).find((p) => p.trim().length > 30) || '';
  if (d) { f.d = sentence(d); f.auto = false; described++; }
}
const touch = {};
for (const f of project.files) for (const p of f.touched || []) (touch[p] ||= []).push({ ref: 'f:' + f.p, label: f.name.slice(0, 90), st: f.st });
g.meta.vfTab = 'code';
g.meta.vfTouch = touch;
fs.writeFileSync(path.join(out, 'graph.json'), JSON.stringify(g));

// les deux pages : même viewer, données différentes
const html = fs.readFileSync(path.join(out, 'index.html'), 'utf8');
const A = '<script>window.FLOORPLAN = ', B = ';</script>';
const a = html.indexOf(A), b = html.indexOf(B, a);
const embed = (data) => html.slice(0, a + A.length) + JSON.stringify(data).replace(/<\/(script)/gi, '<\\/$1').replace(/\u2028/g, '\\u2028').replace(/\u2029/g, '\\u2029') + html.slice(b);
fs.writeFileSync(path.join(out, 'index.html'), embed(g).replace(/<title>[^<]*<\/title>/, '<title>VibeFlow · Code</title>'));
project.meta.root = g.meta.root;
fs.writeFileSync(path.join(out, 'project.html'), embed(project).replace(/<title>[^<]*<\/title>/, '<title>VibeFlow · Projet</title>'));
// spike 005 : questions sur l'onglet Projet (serve.mjs P7 charge vf-ask.mjs ; l'agent appelle vf-query.mjs)
const S5 = path.join(HERE, '..', '005-questions-onglet-projet');
for (const f of ['vf-ask.mjs', 'vf-query.mjs']) if (fs.existsSync(path.join(S5, f))) fs.copyFileSync(path.join(S5, f), path.join(out, f));
console.log(`cockpit : Code ${g.files.length} fichiers (${described} décrits sans LLM), ${g.links.length} liens · Projet ${project.nodes.length} cartes de structure, ${project.files.length} éléments, ${project.links.length} liens · ${Object.keys(touch).length} fichiers reliés aux plans · ${((Date.now() - t0) / 1000).toFixed(1)} s`);
console.log(`→ node ${path.relative(process.cwd(), path.join(out, 'serve.mjs'))}   puis ouvrir / (Code) et /project.html (Projet)`);
