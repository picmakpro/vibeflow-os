#!/usr/bin/env node
// Prints whether a floorplan already exists here and how stale it is. Never fails.
// usage: node status.mjs [root]
import fs from 'node:fs';
import path from 'node:path';
import { git, mapDir, LEGACY_MAP_DIR, isMapDir } from './lib/common.mjs';

try {
  const root = path.resolve(process.argv[2] || '.');
  const legacy = !fs.existsSync(path.join(root, 'floorplan')) && isMapDir(path.join(root, LEGACY_MAP_DIR));
  if (legacy) console.log(`(a map from before the rename is in ${LEGACY_MAP_DIR}/; the next scan, build or refresh moves it to floorplan/)`);
  const dir = legacy ? path.join(root, LEGACY_MAP_DIR) : mapDir(root, { migrate: false });
  const graphFile = path.join(dir, 'graph.json');
  const hasArch = fs.existsSync(path.join(dir, 'architecture.json'));
  if (!fs.existsSync(graphFile)) {
    const hasPlan = fs.existsSync(path.join(dir, 'plan.json'));
    console.log(hasPlan ? 'a blueprint was started (plan.json) but never drawn: write architecture.json if it is missing, then run plan.mjs and build.mjs.' : hasArch ? 'architecture.json exists but was never built: run build.mjs.' : 'none: no floorplan here yet (fresh run).');
    process.exit(0);
  }
  const g = JSON.parse(fs.readFileSync(graphFile, 'utf8'));
  if (g.meta.blueprint) {
    console.log(`a blueprint (planned, not built${g.meta.blueprint.source ? `, from ${g.meta.blueprint.source}` : ''}) built ${g.meta.generatedAt}: ${g.meta.counts.files} planned files, ${g.nodes.length} nodes.\nTo change the plan, edit floorplan/plan.json and architecture.json, then run refresh.mjs (it redraws from plan.json). If the code now exists and the user wants a map of it, run refresh.mjs --from-code.`);
    process.exit(0);
  }
  const lines = [`map built ${g.meta.generatedAt} covering ${g.meta.counts.files} files, ${g.nodes.length} nodes.`];
  for (const r of g.meta.repos || []) {
    const abs = path.join(root, r.path);
    const head = git(abs, ['rev-parse', 'HEAD']);
    if (!head || !r.head) { lines.push(`  ${r.path}: not a git repo now`); continue; }
    const changed = head === r.head ? [] : (git(abs, ['diff', '--name-only', r.head, head]) || '').split('\n').filter(Boolean);
    const dirty = (git(abs, ['status', '--porcelain']) || '').split('\n').filter(Boolean).length;
    lines.push(`  ${r.path}: ${head === r.head ? 'same commit' : `${changed.length} file(s) changed since ${r.head.slice(0, 7)}`}${dirty ? `, ${dirty} uncommitted` : ''}`);
    if (changed.length) lines.push(`    e.g. ${changed.slice(0, 6).map((p) => (r.path === '.' ? p : `${r.path}/${p}`)).join(', ')}`);
  }
  lines.push('A map exists: update it with refresh.mjs (only changed files cost tokens) rather than starting over.');
  console.log(lines.join('\n'));
} catch (e) {
  console.log(`status unavailable (${e.message})`);
}
