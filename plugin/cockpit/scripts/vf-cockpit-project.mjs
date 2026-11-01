// vf-cockpit-project — graphe Projet du cockpit (tracer 67-02 tâche 1 ; généralisé en tâche 2).
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const read = (f) => { try { return fs.readFileSync(f, 'utf8'); } catch { return ''; } };
const ls = (d) => { try { return fs.readdirSync(d); } catch { return []; } };

export function buildProjectGraph(root) {
  root = path.resolve(root);
  const base = path.join(root, '.planning');
  const nodes = [], files = [];
  for (const m of read(path.join(base, 'ROADMAP.md')).matchAll(/^- \[([ x])\] \*\*Phase (\d+): ([^*]*)\*\*/gm)) {
    const n = String(Number(m[2]));
    nodes.push({ id: `ph-${n}`, label: `Phase ${n} · ${m[3].trim()}`, kind: 'phase', st: m[1] === 'x' ? 'done' : 'active' });
    const dir = ls(path.join(base, 'phases')).find((d) => d.startsWith(m[2].padStart(2, '0') + '-'));
    if (!dir) continue;
    for (const f of ls(path.join(base, 'phases', dir)).filter((x) => x.endsWith('-PLAN.md')))
      files.push({ p: `.planning/phases/${dir}/${f}`, n: `ph-${n}`, name: f.replace('-PLAN.md', ''), st: ls(path.join(base, 'phases', dir)).includes(f.replace('-PLAN', '-SUMMARY')) ? 'done' : 'active' });
  }
  return { schema: 'vibeflow/cockpit-project@1', meta: { vfTab: 'project', vf: {}, kindLabels: {} }, project: { name: path.basename(root) + ' — Projet' }, nodes, files, links: [], flows: [], routes: [], tour: [] };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) process.stdout.write(JSON.stringify(buildProjectGraph(process.argv[2] || '.')));
