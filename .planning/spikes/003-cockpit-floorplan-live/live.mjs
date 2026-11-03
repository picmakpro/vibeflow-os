#!/usr/bin/env node
// Spike 003 — sidecar « direct » du cockpit floorplan (spike 002). Surveille .planning/ et le
// dossier des verrous (git-common-dir/vf-driver), régénère le graphe Projet (≈ 0,1 s), calcule
// le diff de statuts avec la version précédente et le pousse en SSE. Changement de structure
// (cartes ajoutées ou retirées) → project.html réécrit + événement `structural`.
// Lecture seule sur le dépôt observé, sauf floorplan/project.html. Zéro dépendance.
// usage: node live.mjs <root> [--port 4379] [--origin http://127.0.0.1:4378]
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { collect } from '../004-signal-au-travail/who.mjs'; // spike 004 : qui est au travail

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SPIKE2 = path.join(HERE, '..', '002-cockpit-code-projet');
const arg = (k, d) => { const i = process.argv.indexOf(k); return i > 0 ? process.argv[i + 1] : d; };
const root = path.resolve(process.argv[2] && !process.argv[2].startsWith('--') ? process.argv[2] : '.');
const PORT = Number(arg('--port', 4379));
const ORIGIN = arg('--origin', 'http://127.0.0.1:4378');
const LOCK_SCRIPT = [path.join(root, 'plugin/conductor/scripts/driver-lock.sh'), path.join(root, '.claude/scripts/driver-lock.sh')].find((p) => fs.existsSync(p));
const gitCommon = (() => { try { return path.resolve(root, execFileSync('git', ['-C', root, 'rev-parse', '--git-common-dir'], { encoding: 'utf8' }).trim()); } catch { return null; } })();
const DRIVER_DIR = process.env.VF_DRIVER_DIR || (gitCommon && path.join(gitCommon, 'vf-driver'));

// ---------- journal forensique ----------
const log = [];
const ev = (cat, msg, data) => { log.push({ ts: new Date().toISOString(), cat, msg, ...(data ? { data } : {}) }); if (log.length > 2000) log.shift(); };

// ---------- état ----------
const genGraph = () => JSON.parse(execFileSync(process.execPath, [path.join(SPIKE2, 'vf-project-graph.mjs'), root], { encoding: 'utf8', maxBuffer: 256 << 20, stdio: ['ignore', 'pipe', 'ignore'] }));
const lockStatus = () => {
  if (!LOCK_SCRIPT) return { available: false };
  try { return JSON.parse(execFileSync('bash', [LOCK_SCRIPT, 'status', '--all'], { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] })); }
  catch (e) { try { return JSON.parse(e.stdout); } catch { return { error: String(e.message).slice(0, 200) }; } }
};
const index = (g) => {
  const m = new Map();
  for (const n of g.nodes) m.set('n:' + n.id, { st: n.st || '', foot: n.foot || '' });
  for (const f of g.files) m.set('f:' + f.p, { st: f.st || '', foot: f.foot || '' });
  return m;
};
let graph = genGraph(), idx = index(graph), lock = lockStatus(), seq = 0;
// « qui » : on ne pousse que quand la liste change (pas à chaque seconde d'âge qui passe)
const whoNow = () => { try { return collect(root); } catch (e) { return { error: e.message, workers: [], sources: {} }; } };
const whoSig = (w) => JSON.stringify((w.workers || []).map((x) => [x.kind, x.id, x.tree, !!x.stale, x.doing || x.task || '']));
let who = whoNow();
ev('boot', 'état initial', { cards: idx.size, lockPresent: lock.present, driverDir: DRIVER_DIR, lockScript: LOCK_SCRIPT });

const diff = (a, b) => {
  const patch = [];
  let added = 0, removed = 0;
  for (const [ref, v] of b) { const o = a.get(ref); if (!o) { added++; continue; } if (o.st !== v.st || o.foot !== v.foot) patch.push({ ref, ...v }); }
  for (const ref of a.keys()) if (!b.has(ref)) removed++;
  return { patch, structural: added + removed > 0, onlyRemoved: removed > 0 && !added, added, removed };
};

// project.html : même épissure que build-cockpit.mjs (échappements écrits en ASCII, cf. CONVENTIONS)
const writeProjectHtml = (g) => {
  const f = path.join(root, 'floorplan', 'project.html');
  const html = fs.readFileSync(f, 'utf8');
  const A = '<script>window.FLOORPLAN = ', B = ';</script>';
  const a = html.indexOf(A), b = html.indexOf(B, a);
  if (a < 0 || b < 0) throw new Error('marqueur FLOORPLAN introuvable dans project.html');
  g.meta.root = root;
  const json = JSON.stringify(g).replace(/<\/(script)/gi, '<\\/$1').replace(/\u2028/g, '\\u2028').replace(/\u2029/g, '\\u2029');
  fs.writeFileSync(f + '.tmp', html.slice(0, a + A.length) + json + html.slice(b));
  fs.renameSync(f + '.tmp', f); // jamais de page à moitié écrite
};

// ---------- SSE ----------
const clients = new Set();
const send = (event, data) => { const s = `event: ${event}\ndata: ${JSON.stringify(data)}\n\n`; for (const c of clients) c.write(s); };

const refresh = (reasons) => {
  const t0 = performance.now();
  let g;
  try { g = genGraph(); } catch (e) { ev('error', 'graphe illisible, état précédent conservé', { e: String(e.message).slice(0, 200) }); return; }
  const tGraph = performance.now() - t0;
  const nidx = index(g);
  const { patch, structural, onlyRemoved, removed } = diff(idx, nidx);
  // dag.sh save() tronque puis écrit : une lecture en plein milieu fait « disparaître » une mission.
  // Un retrait pur n'est cru qu'après une seconde lecture identique, 600 ms plus tard.
  if (onlyRemoved && !reasons.includes('confirm')) { ev('hold', `${removed} carte(s) disparue(s) : seconde lecture avant de croire`, { reasons: reasons.slice(0, 3) }); setTimeout(() => refresh(['confirm', ...reasons]), 600); return; }
  const nlock = lockStatus();
  const lockChanged = JSON.stringify(nlock) !== JSON.stringify(lock);
  graph = g; idx = nidx; lock = nlock; seq++;
  if (structural) { try { writeProjectHtml(g); } catch (e) { ev('error', 'project.html non réécrit', { e: e.message }); } }
  const ms = Math.round(performance.now() - t0);
  ev('refresh', `${patch.length} patch(s)${structural ? ', structure' : ''}${lockChanged ? ', verrou' : ''}`, { seq, ms, graphMs: Math.round(tGraph), reasons: reasons.slice(0, 5), clients: clients.size });
  if (structural) send('structural', { seq, at: Date.now() });
  else if (patch.length) send('patch', { seq, at: Date.now(), patch });
  if (lockChanged) send('lock', { seq, at: Date.now(), lock });
};

// ---------- surveillance (debounce 300 ms, comme le spike 001) ----------
let timer = null, pending = [];
const poke = (src) => (_, file) => {
  if (file && /(^|\/)\.git(\/|$)|\.tmp$|~$|\.swp$/.test(file) && src === 'planning') return;
  pending.push(`${src}:${file || '?'}`);
  clearTimeout(timer);
  timer = setTimeout(() => { const r = pending; pending = []; refresh(r); }, 300);
};
const watched = new Map();
const attach = (src, dir, quiet) => {
  if (watched.has(src)) return;
  if (!dir || !fs.existsSync(dir)) { if (!quiet) ev('watch', `absent : ${src}`, { dir }); return; }
  try { const w = fs.watch(dir, { recursive: true }, poke(src)); watched.set(src, w); w.on('error', () => { watched.delete(src); ev('watch', `perdu : ${src}`); }); ev('watch', `surveille ${src}`, { dir }); }
  catch (e) { ev('watch', `recursive refusé pour ${src}`, { e: e.message }); }
};
attach('planning', path.join(root, '.planning'));
attach('driver', DRIVER_DIR);
// filet toutes les 5 s : l'âge du verrou avance sans écriture, et vf-driver/ peut naître après le démarrage
setInterval(() => {
  attach('driver', DRIVER_DIR, true);
  const nw = whoNow(); if (whoSig(nw) !== whoSig(who)) { who = nw; send('who', { seq: ++seq, at: Date.now(), who }); ev('who', `${who.workers.filter((x) => !x.stale).length} actif(s)`); }
  const n = lockStatus(); if (JSON.stringify(n) !== JSON.stringify(lock)) { lock = n; send('lock', { seq: ++seq, at: Date.now(), lock }); ev('pulse', 'verrou changé (scrutation)'); }
}, 5000).unref();

http.createServer((req, res) => {
  const cors = { 'Access-Control-Allow-Origin': ORIGIN, 'Cache-Control': 'no-store' };
  const u = new URL(req.url, 'http://x');
  if (u.pathname === '/events') {
    res.writeHead(200, { ...cors, 'Content-Type': 'text/event-stream', Connection: 'keep-alive' });
    res.write(`event: hello\ndata: ${JSON.stringify({ seq, lock, who })}\n\n`);
    clients.add(res); ev('sse', 'client connecté', { n: clients.size });
    const ka = setInterval(() => res.write(': ka\n\n'), 15000);
    req.on('close', () => { clearInterval(ka); clients.delete(res); ev('sse', 'client parti', { n: clients.size }); });
    return;
  }
  if (u.pathname === '/log') { res.writeHead(200, { ...cors, 'Content-Type': 'application/json' }); return res.end(JSON.stringify({ summary: summary(), log })); }
  if (u.pathname === '/state') { res.writeHead(200, { ...cors, 'Content-Type': 'application/json' }); return res.end(JSON.stringify({ seq, lock, cards: idx.size })); }
  res.writeHead(404, cors); res.end();
}).listen(PORT, '127.0.0.1', () => { ev('boot', `écoute 127.0.0.1:${PORT}`); console.log(`live : http://127.0.0.1:${PORT}/events (origine autorisée ${ORIGIN}) · ${idx.size} cartes · verrou ${lock.present ? 'tenu' : 'libre'}`); });

const summary = () => {
  const by = {}; for (const e of log) by[e.cat] = (by[e.cat] || 0) + 1;
  const ref = log.filter((e) => e.cat === 'refresh').map((e) => e.data.ms);
  return { events: log.length, byCategory: by, refreshes: ref.length, refreshMs: ref.length ? { min: Math.min(...ref), max: Math.max(...ref), avg: Math.round(ref.reduce((a, b) => a + b, 0) / ref.length) } : null, since: log[0]?.ts };
};
