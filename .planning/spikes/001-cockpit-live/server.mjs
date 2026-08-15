// Spike 001 — cockpit-live : serveur zéro-dépendance pour /vf-cockpit
// Lecture seule de .planning/ ; http + SSE + fs.watch, aucun npm install.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, '../../..'); // racine du repo
const PLANNING = path.join(ROOT, '.planning');
const PORT = Number(process.env.VF_COCKPIT_PORT || 4680);
const LOCK_TTL = 1800;

// ---------- couche forensique ----------
const LOG = [];
function logEvent(cat, msg, meta = {}) {
  LOG.push({ ts: new Date().toISOString(), cat, msg, ...meta });
  if (LOG.length > 2000) LOG.shift();
}

// ---------- parsers (volontairement rustiques, grade spike) ----------
function readIf(p) {
  try { return fs.readFileSync(p, 'utf8'); } catch { return null; }
}

function parseState() {
  const raw = readIf(path.join(PLANNING, 'STATE.md'));
  if (!raw) return null;
  const m = raw.match(/^---\n([\s\S]*?)\n---/);
  if (!m) return null;
  const out = {};
  let inProgress = false;
  for (const line of m[1].split('\n')) {
    const sub = line.match(/^  (\w+): *(.*)$/);
    if (inProgress && sub) { (out.progress ??= {})[sub[1]] = Number(sub[2]); continue; }
    const kv = line.match(/^(\w+): *(.*)$/);
    if (!kv) continue;
    inProgress = kv[1] === 'progress';
    if (!inProgress) out[kv[1]] = kv[2].replace(/^"|"$/g, '');
  }
  return out;
}

function parseRoadmapChecklist() {
  const raw = readIf(path.join(PLANNING, 'ROADMAP.md'));
  if (!raw) return [];
  const phases = [];
  const re = /^- \[([ x])\] Phase ([\d]+): (.+?)(?: \(completed ([^)]+)\))?$/gm;
  let m;
  while ((m = re.exec(raw)) !== null) {
    phases.push({ done: m[1] === 'x', num: Number(m[2]), name: m[3].trim(), completed: m[4] || null });
  }
  return phases;
}

function parseMilestones() {
  const raw = readIf(path.join(PLANNING, 'MILESTONES.md'));
  if (!raw) return [];
  const out = [];
  const re = /^## (✅|🚧)?\s*([^\n]+)$/gm;
  let m;
  while ((m = re.exec(raw)) !== null) {
    const title = m[2].trim();
    const dates = [...title.matchAll(/(\d{4}-\d{2}-\d{2})/g)].map(d => d[1]);
    out.push({ closed: m[1] === '✅', title: title.replace(/\s*\(.*\)\s*$/, ''), when: dates.at(-1) || null });
  }
  return out;
}

function parseDags() {
  let files = [];
  try { files = fs.readdirSync(PLANNING).filter(f => /^MISSION-.*\.dag\.json$/.test(f)); } catch {}
  return files.map(f => {
    try { return { file: f, ...JSON.parse(fs.readFileSync(path.join(PLANNING, f), 'utf8')) }; }
    catch (e) { logEvent('parse', `dag invalide: ${f}`, { error: String(e) }); return null; }
  }).filter(Boolean);
}

function parseLock() {
  const meta = readIf(path.join(PLANNING, 'DRIVER.lock', 'meta'));
  if (!meta) return { present: false };
  const out = { present: true };
  for (const line of meta.split('\n')) {
    const kv = line.match(/^(\w+)=(.*)$/);
    if (kv) out[kv[1]] = kv[2];
  }
  const hb = Number(out.heartbeat_epoch || out.acquired_epoch || 0);
  out.age_seconds = hb ? Math.max(0, Math.floor(Date.now() / 1000) - hb) : null;
  out.stale = out.age_seconds !== null ? out.age_seconds > LOCK_TTL : null;
  return out;
}

function snapshot() {
  const t0 = Date.now();
  const snap = {
    generatedAt: new Date().toISOString(),
    state: parseState(),
    phases: parseRoadmapChecklist(),
    milestones: parseMilestones(),
    dags: parseDags(),
    lock: parseLock(),
  };
  logEvent('snapshot', 'construit', { ms: Date.now() - t0, phases: snap.phases.length, dags: snap.dags.length });
  return snap;
}

// ---------- SSE + fs.watch ----------
const clients = new Set();
let debounce = null;
function broadcast(reason) {
  logEvent('sse', `broadcast → ${clients.size} client(s)`, { reason });
  for (const res of clients) res.write(`data: ${JSON.stringify({ reason, at: Date.now() })}\n\n`);
}
try {
  fs.watch(PLANNING, { recursive: true }, (_ev, fname) => {
    if (fname && /spikes\//.test(String(fname))) return; // ne pas s'auto-réveiller
    clearTimeout(debounce);
    debounce = setTimeout(() => broadcast(String(fname || 'unknown')), 300);
  });
  logEvent('watch', `fs.watch actif sur ${PLANNING}`);
} catch (e) { logEvent('watch', 'fs.watch indisponible', { error: String(e) }); }

// ---------- http ----------
const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  logEvent('http', `${req.method} ${url.pathname}`);
  if (url.pathname === '/') {
    res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
    res.end(fs.readFileSync(path.join(HERE, 'index.html')));
  } else if (url.pathname === '/api/state') {
    res.writeHead(200, { 'content-type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify(snapshot()));
  } else if (url.pathname === '/api/log') {
    res.writeHead(200, { 'content-type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({ count: LOG.length, events: LOG }));
  } else if (url.pathname === '/events') {
    res.writeHead(200, { 'content-type': 'text/event-stream', 'cache-control': 'no-cache', connection: 'keep-alive' });
    res.write('retry: 1000\n\n');
    clients.add(res);
    req.on('close', () => clients.delete(res));
  } else {
    res.writeHead(404); res.end('not found');
  }
});
server.listen(PORT, () => {
  logEvent('boot', `cockpit sur http://localhost:${PORT} — racine ${ROOT}`);
  console.log(`vf-cockpit (spike) → http://localhost:${PORT}`);
});
