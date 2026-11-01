// vf-cockpit-planning — lecteurs de .planning (plat, partitionné, archivé) du socle du cockpit (CKPT-06).
// Export principal : readPlanning(root, layout) -> { phases, phaseDirs, reqs, milestones, state, dags,
//   backlog, seeds, tags, projectName }. Utilitaires partagés : fm, clip, sentence, list, num, normNum.
// Identité d'une phase = couple (compartiment, numéro) : `key` = `<ws>|<n>` ('' pour un lab plat).
// Aucun nom de compartiment, de jalon ou de projet codé en dur. Lecture seule.
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { planningLayout, stateFile } from './vf-cockpit-paths.mjs';

const read = (f) => { try { return fs.readFileSync(f, 'utf8'); } catch { return ''; } };
const ls = (d) => { try { return fs.readdirSync(d); } catch { return []; } };
export const clip = (s, n) => { s = String(s || '').replace(/\s+/g, ' ').replace(/\*\*/g, '').replace(/`/g, '').trim(); return s.length > n ? s.slice(0, n - 1).trimEnd() + '…' : s; };
export const sentence = (s, n = 200) => { s = String(s || '').replace(/\s+/g, ' ').replace(/\*\*/g, '').replace(/`/g, '').trim(); const i = s.search(/[.!?](\s|$)/); return clip(i > 25 ? s.slice(0, i + 1) : s, n); };
export const num = (s) => parseFloat(s);
export const normNum = (s) => { const [a, b] = String(s).split('.'); return `${Number(a)}${b !== undefined ? '.' + b : ''}`; }; // 01 -> 1, 02.1 -> 2.1
export const fm = (txt) => { const m = /^---\n([\s\S]*?)\n---/.exec(txt); const o = {}; if (!m) return o; for (const l of m[1].split('\n')) { const k = /^([\w-]+):\s*(.*)$/.exec(l); if (k) o[k[1]] = k[2].trim(); } return o; };
export const list = (v) => (v || '').replace(/^\[|\]$/g, '').split(',').map((s) => s.trim().replace(/^["']|["']$/g, '')).filter(Boolean);
const NUM = '(\\d+(?:\\.\\d+)?)';
const STATUS_SUFFIX = /\s*\((inscrite|completed|INSERTED|exécutée|cadrée|complete|clôturée|clos|CLOSE).*$/i;

function parseRoadmap(txt, ws, rel, phases) {
  // cases de phase : avec ou sans gras autour de « Phase N: nom », suffixe « - … » ou « — … » retiré
  for (const m of txt.matchAll(new RegExp(`^- \\[([ x])\\]\\s+(?:\\*\\*)?Phase ${NUM}:\\s*(.*)$`, 'gm'))) {
    const n = normNum(m[2]); const key = `${ws || ''}|${n}`;
    if (phases.has(key)) continue;
    let name = m[3].includes('**') ? m[3].split('**')[0] : m[3].replace(/\s+[-—]\s.*$/, '');
    name = name.replace(STATUS_SUFFIX, '').replace(/\s+—\s+(complete|clôturée|CLOSE).*$/, '').replace(/^\[|\]$/g, '');
    phases.set(key, { key, n, ws: ws || null, name: clip(name, 90), done: m[1] === 'x', line: m[3], roadmap: rel, goal: '', depends: [] });
  }
  // sections « ### Phase N: nom » ou « #### … » : corps jusqu'au prochain en-tête de niveau 2 à 4
  for (const m of txt.matchAll(new RegExp(`^#{3,4} Phase ${NUM}:\\s*(.*)\\n([\\s\\S]*?)(?=^#{2,4} |(?![\\s\\S]))`, 'gm'))) {
    const n = normNum(m[1]); const key = `${ws || ''}|${n}`;
    let ph = phases.get(key);
    if (!ph) { ph = { key, n, ws: ws || null, name: clip(m[2].replace(/^\[|\]$/g, ''), 90), done: false, line: '', roadmap: rel, goal: '', depends: [] }; phases.set(key, ph); }
    if (ph.goal) continue;
    ph.goal = (/\*\*Goal(?::\*\*|\*\*:)\s*([\s\S]*?)(?=\n\*\*|\n\n|(?![\s\S]))/.exec(m[3])?.[1] || '').trim();
    const dep = /\*\*Depends on(?::\*\*|\*\*:)\s*(.*)/.exec(m[3])?.[1] || '';
    ph.depends = /^\s*nothing/i.test(dep) ? [] : [...dep.matchAll(/\b(\d+(?:\.\d+)?)\b/g)].map((x) => normNum(x[1])).filter((x) => x !== n);
  }
}

// jalons de la section « ## Milestones » : tiret simple ou cadratin, clé pouvant contenir des espaces
function parseMilestones(txt, ws, phases, out) {
  const sec = /## Milestones\n([\s\S]*?)(?=\n## |\n> |(?![\s\S]))/.exec(txt)?.[1] || '';
  for (const entry of ('\n' + sec).split(/\n(?=- )/).filter((e) => e.startsWith('- '))) {
    const m = /^- (\S+) \*\*([^*]+)\*\*\s+[-—]\s+([\s\S]*)$/.exec(entry.trim());
    if (!m) continue;
    const key = m[2].trim();
    if (out.some((x) => x.key === key && x.ws === (ws || null))) continue;
    const text = m[3].replace(/\s+/g, ' ');
    const range = (/Phases? ([^—(]*)/.exec(text)?.[1] || '').replace(/Phases?|\*\*/g, '');
    const set = new Set();
    for (const part of range.split(/,|\+|\bet\b/)) {
      const r = new RegExp(`${NUM}\\s*(?:-|→)\\s*${NUM}`).exec(part);
      if (r) { for (const ph of phases.values()) if (ph.ws === (ws || null) && num(ph.n) >= num(r[1]) && Math.floor(num(ph.n)) <= num(r[2])) set.add(ph.key); }
      else for (const x of part.matchAll(/\d+(?:\.\d+)?/g)) { const k = `${ws || ''}|${normNum(x[0])}`; if (phases.has(k)) set.add(k); }
    }
    for (const k of set) for (const o of out) if (o.ws === (ws || null)) o.phases.delete(k); // la phase appartient au dernier jalon qui la cite
    out.push({ key, id: 'ms-' + key.toLowerCase().replace(/[^a-z0-9.]/g, '-'), icon: m[1], text, phases: set, ws: ws || null });
  }
}

export function readPlanning(root, layout) {
  root = path.resolve(root); layout = layout || planningLayout(root);
  const B = path.join(root, '.planning');
  const rel = (abs) => path.relative(root, abs).split(path.sep).join('/');
  const archives = ls(path.join(B, 'milestones'));
  const phases = new Map(), reqs = new Map(), milestones = [], phaseDirs = new Map();
  const comps = layout.compartiments.length ? layout.compartiments : [];

  for (const c of comps) parseRoadmap(read(path.join(c.dir, 'ROADMAP.md')), c.ws, rel(path.join(c.dir, 'ROADMAP.md')), phases);
  const activeKeys = new Set(phases.keys());
  for (const f of archives.filter((x) => x.endsWith('-ROADMAP.md'))) {
    const tmp = new Map(); parseRoadmap(read(path.join(B, 'milestones', f)), null, rel(path.join(B, 'milestones', f)), tmp);
    for (const ph of tmp.values()) if (![...phases.values()].some((p) => p.n === ph.n)) phases.set(ph.key, { ...ph, archive: true });
  }
  for (const c of comps) parseMilestones(read(path.join(c.dir, 'ROADMAP.md')), c.ws, phases, milestones);
  for (const ms of milestones) for (const k of [...ms.phases]) if (!phases.has(k)) ms.phases.delete(k);

  // dossiers de phase : NN-slug ou PREFIXE-NN-slug ; clé `<ws>|<n>`, repli `*|<n>` pour les archives
  const bases = [...comps.map((c) => [c.ws || '', path.join(c.dir, 'phases')]), ...archives.filter((d) => d.endsWith('-phases')).map((d) => ['*', path.join(B, 'milestones', d)])];
  for (const [ws, base] of bases) for (const d of ls(base)) {
    const m = /^(?:[A-Z][A-Z0-9]*-)?(\d+(?:\.\d+)?)-/.exec(d);
    if (m && !phaseDirs.has(`${ws}|${normNum(m[1])}`)) phaseDirs.set(`${ws}|${normNum(m[1])}`, path.join(base, d));
  }

  // exigences : cases à cocher et table de traçabilité, rattachées dans le compartiment du fichier porteur
  const reqFiles = [...comps.map((c) => [c.ws || '', path.join(c.dir, 'REQUIREMENTS.md')]), ...archives.filter((f) => f.endsWith('-REQUIREMENTS.md')).map((f) => ['*', path.join(B, 'milestones', f)])];
  for (const [ws, f] of reqFiles) {
    const txt = read(f);
    for (const m of txt.matchAll(/^- \[([ x])\] \*\*([A-Z][A-Z0-9]*-\d+[a-z]?)\*\*:?\s*(.*)$/gm)) if (!reqs.has(`${ws}|${m[2]}`)) reqs.set(`${ws}|${m[2]}`, { id: m[2], ws: ws || null, wsKey: ws, done: m[1] === 'x', text: m[3], file: rel(f) });
    for (const m of txt.matchAll(new RegExp(`^\\|\\s*([A-Z][A-Z0-9]*-\\d+[a-z]?)\\s*\\|\\s*Phase ${NUM}`, 'gm'))) { const r = reqs.get(`${ws}|${m[1]}`); if (r && !r.phase) r.phase = normNum(m[2]); }
  }

  // état : frontmatter du STATE du compartiment actif, repli sur la ligne de corps « Phase: N »
  const sf = stateFile(root, layout); const sTxt = sf ? read(sf) : '';
  const state = fm(sTxt);
  if (!state.current_phase) { const b = new RegExp(`^Phase:\\s*${NUM}`, 'm').exec(sTxt)?.[1]; if (b) state.current_phase = normNum(b); }

  // DAG : .planning, chaque compartiment, .planning/missions (JSON illisible ignoré)
  const dags = []; const seen = new Set();
  for (const [ws, d] of [...comps.map((c) => [c.ws, c.dir]), [null, B], [null, path.join(B, 'missions')]]) {
    if (seen.has(d)) continue; seen.add(d);
    for (const f of ls(d).filter((x) => x.endsWith('.dag.json'))) {
      let j; try { j = JSON.parse(read(path.join(d, f))); } catch { continue; }
      if (j && Array.isArray(j.nodes)) dags.push({ name: f.replace(/\.dag\.json$/, ''), ws, file: rel(path.join(d, f)), nodes: j.nodes });
    }
  }
  const backlog = read(path.join(B, 'BACKLOG.md'));
  const seeds = ls(path.join(B, 'seeds')).filter((f) => f.endsWith('.md')).map((f) => ({ file: rel(path.join(B, 'seeds', f)), text: read(path.join(B, 'seeds', f)) }));
  let tags = [];
  try {
    const out = execFileSync('git', ['-C', root, 'for-each-ref', '--sort=-creatordate', '--count=30', '--format=%(refname:short)\t%(creatordate:short)\t%(contents:subject)', 'refs/tags/v*'], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] });
    tags = out.trim().split('\n').filter(Boolean).map((l) => { const [tag, date, subject] = l.split('\t'); return { tag, date, subject }; });
  } catch {}
  const title = /^# (.*)$/m.exec(read(path.join(B, 'PROJECT.md')))?.[1];
  const projectName = (title ? title.replace(/^(Project|Roadmap):\s*/i, '').trim() : '') || path.basename(root);
  return { phases, phaseDirs, reqs, milestones, state, dags, backlog, seeds, tags, projectName, activeKeys, rel };
}
