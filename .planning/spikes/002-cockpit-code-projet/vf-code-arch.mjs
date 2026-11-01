#!/usr/bin/env node
// Spike 002 — onglet Code : écrit floorplan/architecture.json pour un dépôt VibeFlow, sans LLM.
// Floorplan ne voit presque rien de ce qui relie VibeFlow (7 liens sur 2 002 fichiers) : ce script
// ajoute l'extracteur qui manque — dispatch entre agents (Agent(...) du frontmatter), scripts
// appelés depuis un script, un agent, un skill ou une référence (mention d'un *.sh).
// usage: node vf-code-arch.mjs <root>
import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(process.argv[2] || '.');
const scan = JSON.parse(fs.readFileSync(path.join(root, 'floorplan/.cache/scan.json'), 'utf8'));
const IGNORE = ['.planning/**', 'docs/**', '.claude/**', 'manual/**', 'reports/**', 'floorplan/**',
  '**/tests/fixtures/**', 'plugin/reference/content/examples/**', '**/CHANGELOG.md'];
const ignored = (p) => IGNORE.some((g) => {
  const re = new RegExp('^' + g.replace(/[.+^${}()|[\]\\]/g, '\\$&').replace(/\*\*\//g, '\u0001').replace(/\*\*/g, '\u0002').replace(/\*/g, '[^/]*')
    .replace(/\u0001/g, '(?:.*/)?').replace(/\u0002/g, '.*') + '$');
  return re.test(p);
});
const files = scan.files.filter((f) => ['code', 'docs'].includes(f.category) && !ignored(f.path)).map((f) => f.path);
const read = (p) => { try { return fs.readFileSync(path.join(root, p), 'utf8'); } catch { return ''; } };

// ---------- nœuds : un par module du plugin, ses dossiers types en enfants ----------
const KIND = {
  conductor: 'infra', 'dev-orchestrator': 'service', 'design-orchestrator': 'service', 'planning-core': 'library',
  consolidator: 'data', validator: 'test', 'infrastructure-audit': 'test', 'audit-architecture': 'test',
  _internal: 'script', installer: 'script', reference: 'config', 'software-architecture': 'config',
  'skill-creator': 'library', 'mobile-test': 'worker', 'mobile-test-team': 'worker', commands: 'ui',
};
const SUB = { agents: ['Agents', 'ui', 'Les rôles incarnés ou dispatchés.'], skills: ['Skills', 'feature', 'Les gestes invocables.'],
  scripts: ['Scripts', 'script', 'Gates, moteurs et outils en shell.'], 'scripts/tests': ['Tests', 'test', 'Suites qui prouvent les scripts.'],
  references: ['Références', 'config', 'Doctrine chargée à la demande.'], hooks: ['Hooks', 'worker', 'Ce qui se déclenche sur les événements de session.'],
  content: ['Contenu', 'config', 'Ressources installées dans le lab.'] };
const nodes = [];
const modDesc = (m) => { try { return JSON.parse(read(`plugin/${m}/module.json`)).description || ''; } catch { return ''; } };
const firstSentence = (s, n = 170) => { s = String(s || '').replace(/\s+/g, ' ').trim(); const i = s.search(/[.!?](\s|$)/); s = i > 20 ? s.slice(0, i + 1) : s; return s.length > n ? s.slice(0, n - 1) + '…' : s; };
const mods = fs.readdirSync(path.join(root, 'plugin')).filter((m) => !m.startsWith('.') && fs.statSync(path.join(root, 'plugin', m)).isDirectory());
const ver = (m) => read(`plugin/${m}/VERSION`).trim();
for (const m of mods) {
  const id = 'm-' + m.replace(/[^a-z0-9]+/gi, '-').replace(/^-/, '');
  nodes.push({ id, label: m === '_internal' ? 'Engine d\'install' : m, kind: KIND[m] || (m.endsWith('bundle') || m.endsWith('team') ? 'feature' : 'library'),
    summary: firstSentence(modDesc(m)) || `Module ${m}.`, paths: [`plugin/${m}`], tags: [ver(m)].filter(Boolean) });
  for (const [sub, [label, kind, summary]] of Object.entries(SUB)) {
    const dir = `plugin/${m}/${sub}`;
    if (!files.some((f) => f.startsWith(dir + '/'))) continue;
    nodes.push({ id: `${id}.${sub.replace('/', '-')}`, parent: sub === 'scripts/tests' && nodes.some((n) => n.id === `${id}.scripts`) ? `${id}.scripts` : id, label, kind, summary, paths: [dir] });
  }
}
nodes.push({ id: 'ci', label: 'Gates du dépôt', kind: 'infra', summary: 'Scripts et hooks que la CI rejoue sur chaque PR.', paths: ['scripts', '.github'] });
nodes.push({ id: 'ci.tests', parent: 'ci', label: 'Tests des gates', kind: 'test', summary: 'Suites des gates du dépôt.', paths: ['scripts/tests'] });
nodes.push({ id: 'root-docs', label: 'Racine du dépôt', kind: 'config', summary: 'README, CLAUDE.md, contribution, sécurité.', paths: ['*.md'] });
nodes.push({ id: 'gsd', label: 'GSD (gsd-core)', kind: 'external', summary: 'Moteur de planning et ses agents gsd-*, dispatchés par nos agents.' });
nodes.push({ id: 'claude', label: 'Claude Code', kind: 'external', summary: 'Le harness : agents génériques (general-purpose) et outils.' });

// ---------- liens VibeFlow ----------
const edges = [];
const seen = new Set();
const edge = (from, to, kind, label) => { const k = `${from}>${to}>${kind}`; if (from === to || seen.has(k)) return; seen.add(k); edges.push({ from, to, kind, label }); };
// dispatch : Agent(a, b, …) dans le frontmatter d'un agent
const agentFiles = new Map();
for (const f of files) if (/\/agents\/[^/]+\.md$/.test(f) && f.startsWith('plugin/')) agentFiles.set(path.basename(f, '.md'), f);
for (const [name, f] of agentFiles) {
  const fm = /^---\n([\s\S]*?)\n---/.exec(read(f))?.[1] || '';
  const tools = /^tools:\s*(.*)$/m.exec(fm)?.[1] || '';
  const inside = /Agent\(([^)]*)\)/.exec(tools)?.[1];
  if (!inside) continue;
  for (const t of inside.split(',').map((s) => s.trim()).filter(Boolean)) {
    if (agentFiles.has(t)) edge(f, agentFiles.get(t), 'call', 'dispatche');
    else if (t.startsWith('gsd-')) edge(f, 'gsd', 'call', 'dispatche ' + t);
    else edge(f, 'claude', 'call', 'dispatche ' + t);
  }
}
// scripts mentionnés : *.sh cité dans un script, un agent, un skill, une référence
const byBase = new Map();
for (const f of files) if (f.endsWith('.sh')) { const b = path.basename(f); if (!byBase.has(b)) byBase.set(b, []); byBase.get(b).push(f); }
const resolve = (from, base) => {
  const c = byBase.get(base); if (!c) return null;
  if (c.length === 1) return c[0];
  const mod = from.split('/').slice(0, 2).join('/');
  return c.filter((p) => !p.includes('/tests/')).find((p) => p.startsWith(mod + '/')) || c.find((p) => p.startsWith(mod + '/')) || null;
};
for (const f of files) {
  if (!/\.(sh|md)$/.test(f)) continue;
  if (f.endsWith('.md') && !f.startsWith('plugin/') && !f.startsWith('scripts/')) continue;
  const txt = read(f);
  for (const m of new Set(txt.match(/[\w.-]+\.sh\b/g) || [])) {
    const to = resolve(f, m);
    if (!to || to === f) continue;
    const isSource = new RegExp(`(^|\\n)\\s*(source|\\.)\\s+[^\\n]*${m.replace(/\./g, '\\.')}`).test(txt);
    edge(f, to, isSource ? 'import' : 'call', isSource ? 'source' : 'appelle');
  }
}

const arch = {
  $schema: 'floorplan/architecture@1',
  project: { name: 'VibeFlow', summary: 'Le plugin VibeFlow : modules toggables (gouvernance, équipes de dev et de design, planning, audits), leurs agents, skills, scripts et gates.', entrypoints: [] },
  audience: 'developers', include: ['code', 'docs'], ignore: IGNORE, nodes, edges,
  flows: [{ id: 'mission-dev', title: 'Une mission de dev', steps: [
    { node: 'm-dev-orchestrator.agents', note: 'vibeflow-head détecte l\'intention et lance un manager' },
    { node: 'm-conductor.scripts', note: 'Le manager prend le verrou de driver et tient le DAG' },
    { node: 'gsd', note: 'vf-coder délègue cadrage, plan et exécution aux agents GSD' },
    { node: 'ci', note: 'La PR rejoue les gates du dépôt' } ] }],
};
fs.writeFileSync(path.join(root, 'floorplan/architecture.json'), JSON.stringify(arch, null, 2));
console.log(`architecture.json : ${nodes.length} nœuds, ${edges.length} liens VibeFlow (${edges.filter((e) => e.label?.startsWith('dispatche')).length} dispatchs, ${edges.filter((e) => e.kind === 'import').length} source, ${edges.filter((e) => e.label === 'appelle').length} appels de script)`);
