// vf-cockpit-code-vf — extracteur VibeFlow de l'onglet Code, sans modèle (67-05, P67-D-17 ; promu du spike 002).
// Le moteur ne voit presque rien de ce qui relie un lab VibeFlow (7 liens sur 2 002 fichiers au spike) : cet extracteur ajoute
// ce qui manque — dispatch entre agents (`Agent(...)` du frontmatter `tools`), scripts appelés ou sourcés depuis un script, un
// agent, un skill ou une référence (mention d'un *.sh). Choisi par vf-cockpit-code.mjs quand le lab porte au moins un
// plugin/*/module.json. Aucune table de noms de modules : la nature d'un module vient du champ `type` de son module.json.
// Export : architectureVibeflow({ lab, sortie }) -> { extracteur: 'vibeflow', noeuds, liens }. Écrit <sortie>/architecture.json.
import fs from 'node:fs';
import path from 'node:path';

const IGNORE = ['.planning/**', 'docs/**', '.claude/**', 'manual/**', 'reports/**', '.vibeflow/**',
  '**/tests/fixtures/**', 'plugin/reference/content/examples/**', '**/CHANGELOG.md'];
const re = (g) => new RegExp('^' + g.replace(/[.+^${}()|[\]\\]/g, '\\$&').replace(/\*\*\//g, '\u0001').replace(/\*\*/g, '\u0002').replace(/\*/g, '[^/]*').replace(/\u0001/g, '(?:.*/)?').replace(/\u0002/g, '.*') + '$');
const IGN = IGNORE.map(re);
const SUB = { agents: ['Agents', 'ui', 'Les rôles incarnés ou dispatchés.'], skills: ['Skills', 'feature', 'Les gestes invocables.'],
  scripts: ['Scripts', 'script', 'Gates, moteurs et outils en shell.'], 'scripts/tests': ['Tests', 'test', 'Suites qui prouvent les scripts.'],
  references: ['Références', 'config', 'Doctrine chargée à la demande.'], hooks: ['Hooks', 'worker', 'Ce qui se déclenche sur les événements de session.'],
  content: ['Contenu', 'config', 'Ressources installées dans le lab.'] };
// nature d'un module : lue dans son module.json (champ type), jamais dans une liste de noms
const kindOf = (type) => (/doc-only/.test(type) ? 'config' : /agent/.test(type) ? 'service' : 'library');
const firstSentence = (s, n = 170) => { s = String(s || '').replace(/\s+/g, ' ').trim(); const i = s.search(/[.!?](\s|$)/); s = i > 20 ? s.slice(0, i + 1) : s; return s.length > n ? s.slice(0, n - 1) + '…' : s; };

export function architectureVibeflow({ lab, sortie }) {
  const read = (p) => { try { return fs.readFileSync(path.join(lab, p), 'utf8'); } catch { return ''; } };
  const scan = JSON.parse(fs.readFileSync(path.join(sortie, '.cache', 'scan.json'), 'utf8'));
  const files = scan.files.filter((f) => ['code', 'docs'].includes(f.category) && !IGN.some((r) => r.test(f.path))).map((f) => f.path);
  const has = (dir) => files.some((f) => f.startsWith(dir + '/'));
  const dirs = (p) => { try { return fs.readdirSync(path.join(lab, p), { withFileTypes: true }).filter((e) => e.isDirectory() && !e.name.startsWith('.')).map((e) => e.name); } catch { return []; } };

  // ---------- nœuds : un par module (plugin/*/module.json), ses dossiers types en enfants ----------
  const nodes = [];
  for (const m of dirs('plugin')) {
    let mj; try { mj = JSON.parse(read(`plugin/${m}/module.json`)); } catch { continue; }
    const id = 'm-' + m.replace(/[^a-z0-9]+/gi, '-').replace(/^-/, '');
    nodes.push({ id, label: m, kind: kindOf(String(mj.type || '')), summary: firstSentence(mj.description) || `Module ${m}.`, paths: [`plugin/${m}`], tags: [read(`plugin/${m}/VERSION`).trim()].filter(Boolean) });
    for (const [sub, [label, kind, summary]] of Object.entries(SUB)) {
      const dir = `plugin/${m}/${sub}`;
      if (!has(dir)) continue;
      nodes.push({ id: `${id}.${sub.replace('/', '-')}`, parent: sub === 'scripts/tests' && nodes.some((n) => n.id === `${id}.scripts`) ? `${id}.scripts` : id, label, kind, summary, paths: [dir] });
    }
  }
  if (dirs('.').includes('scripts') || dirs('.').includes('.github') || fs.existsSync(path.join(lab, '.github'))) {
    nodes.push({ id: 'ci', label: 'Gates du dépôt', kind: 'infra', summary: 'Scripts et hooks que la CI rejoue sur chaque PR.', paths: ['scripts', '.github'] });
    if (has('scripts/tests')) nodes.push({ id: 'ci.tests', parent: 'ci', label: 'Tests des gates', kind: 'test', summary: 'Suites des gates du dépôt.', paths: ['scripts/tests'] });
  }
  if (files.some((f) => !f.includes('/') && f.endsWith('.md'))) nodes.push({ id: 'root-docs', label: 'Racine du dépôt', kind: 'config', summary: 'README, CLAUDE.md, contribution, sécurité.', paths: ['*.md'] });

  // ---------- liens ----------
  const edges = [], seen = new Set(), externes = new Set();
  const edge = (from, to, kind, label) => { const k = `${from}>${to}>${kind}`; if (from === to || seen.has(k)) return; seen.add(k); edges.push({ from, to, kind, label }); };
  const ext = (id, label, summary) => { if (!externes.has(id)) { externes.add(id); nodes.push({ id, label, kind: 'external', summary }); } return id; };
  const agentFiles = new Map();
  for (const f of files) if (/\/agents\/[^/]+\.md$/.test(f) && f.startsWith('plugin/')) agentFiles.set(path.basename(f, '.md'), f);
  for (const [, f] of agentFiles) { // dispatch : Agent(a, b, …) dans le frontmatter d'un agent
    const fm = /^---\n([\s\S]*?)\n---/.exec(read(f))?.[1] || '';
    const inside = /Agent\(([^)]*)\)/.exec(/^tools:\s*(.*)$/m.exec(fm)?.[1] || '')?.[1];
    if (!inside) continue;
    for (const t of inside.split(',').map((s) => s.trim()).filter(Boolean)) {
      if (agentFiles.has(t)) edge(f, agentFiles.get(t), 'call', 'dispatche');
      else if (t.startsWith('gsd-')) edge(f, ext('gsd', 'GSD (gsd-core)', 'Moteur de planning et ses agents gsd-*, dispatchés par nos agents.'), 'call', 'dispatche ' + t);
      else edge(f, ext('claude', 'Claude Code', 'Le harness : agents génériques (general-purpose) et outils.'), 'call', 'dispatche ' + t);
    }
  }
  const byBase = new Map(); // scripts mentionnés : *.sh cité dans un script, un agent, un skill, une référence
  for (const f of files) if (f.endsWith('.sh')) { const b = path.basename(f); if (!byBase.has(b)) byBase.set(b, []); byBase.get(b).push(f); }
  const resolve = (from, base) => { // nom ambigu : le même module d'abord, jamais /tests/
    const c = byBase.get(base); if (!c) return null;
    if (c.length === 1) return c[0];
    const mod = from.split('/').slice(0, 2).join('/');
    return c.filter((p) => !p.includes('/tests/')).find((p) => p.startsWith(mod + '/')) || c.find((p) => p.startsWith(mod + '/')) || null;
  };
  for (const f of files) {
    if (!/\.(sh|md)$/.test(f) || (f.endsWith('.md') && !f.startsWith('plugin/') && !f.startsWith('scripts/'))) continue;
    const txt = read(f);
    for (const m of new Set(txt.match(/[\w.-]+\.sh\b/g) || [])) {
      const to = resolve(f, m);
      if (!to || to === f) continue;
      const isSource = new RegExp(`(^|\\n)\\s*(source|\\.)\\s+[^\\n]*${m.replace(/\./g, '\\.')}`).test(txt);
      edge(f, to, isSource ? 'import' : 'call', isSource ? 'source' : 'appelle');
    }
  }
  const arch = { project: { name: path.basename(lab), summary: 'Carte du code d\'un lab VibeFlow : un nœud par module, leurs agents, skills, scripts et gates, reliés par le dispatch et les appels de script.', entrypoints: [] },
    audience: 'developers', include: ['code', 'docs'], ignore: IGNORE, nodes, edges };
  fs.writeFileSync(path.join(sortie, 'architecture.json'), JSON.stringify(arch, null, 2));
  return { extracteur: 'vibeflow', noeuds: nodes.length, liens: edges.length };
}
