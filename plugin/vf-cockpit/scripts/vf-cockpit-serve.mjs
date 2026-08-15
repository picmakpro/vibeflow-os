#!/usr/bin/env node
// vf-cockpit-serve.mjs — serveur web local, lecture seule, du cockpit VibeFlow.
// Visualise le .planning/ du LAB COURANT (cwd de l'utilisateur), jamais celui de ce
// repo. Zéro dépendance npm (node:http/fs/path/url uniquement). N'écrit JAMAIS dans
// l'arbre : aucun fs.write*/mkdir/rm/appendFile nulle part dans ce fichier.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { snapshot, phaseDetail } from './vf-cockpit-parsers.mjs';
import { startWatch } from './vf-cockpit-watch.mjs';
import {
  resolvePlanningRoot,
  resolveReferencesDir,
  safeJoin,
  MIME_ALLOWLIST,
  escapeHtml,
} from './vf-cockpit-security.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const LOCK_TTL = 1800;
const HOST = '127.0.0.1'; // jamais 0.0.0.0 — cockpit strictement local.
const DEFAULT_PORT = 4680;

// ---------- couche forensique (EN MÉMOIRE uniquement, jamais sur disque) ----------
const LOG = [];
function logEvent(cat, msg, meta = {}) {
  LOG.push({ ts: new Date().toISOString(), cat, msg, ...meta });
  if (LOG.length > 2000) LOG.shift();
}

// ---------- SSE ----------
const clients = new Set();
function broadcast(reason) {
  logEvent('sse', `broadcast → ${clients.size} client(s)`, { reason });
  for (const res of clients) res.write(`data: ${JSON.stringify({ reason, at: Date.now() })}\n\n`);
}

// ---------- construction du serveur (exportée pour les tests) ----------
export function createCockpitServer({ planningRoot, referencesDir } = {}) {
  const watchState = startWatch(planningRoot, broadcast, logEvent);

  function fullSnapshot() {
    const snap = planningRoot
      ? snapshot(planningRoot, logEvent)
      : {
          generatedAt: new Date().toISOString(),
          state: null,
          phases: [],
          milestones: [],
          dags: [],
          lock: { present: false },
          availability: { state: false, roadmap: false, milestones: false, dags: false, lock: false },
        };
    return {
      ...snap,
      planningRoot,
      watch: { mode: watchState.mode },
      lock: { ...snap.lock, ttlSeconds: LOCK_TTL },
    };
  }

  const server = http.createServer((req, res) => {
    let url;
    try {
      url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
    } catch {
      res.writeHead(400);
      res.end('bad request');
      return;
    }
    logEvent('http', `${req.method} ${url.pathname}`);

    if (url.pathname === '/api/state') {
      res.writeHead(200, { 'content-type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify(fullSnapshot()));
      return;
    }

    if (url.pathname === '/api/phase') {
      const raw = url.searchParams.get('num');
      if (!planningRoot) {
        res.writeHead(200, { 'content-type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ num: null, name: null, goal: null, body: null, dir: null, plans: [], error: 'aucune racine .planning/ résolue' }));
        return;
      }
      if (raw === null || !/^\d+$/.test(raw)) {
        res.writeHead(400, { 'content-type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ error: 'paramètre num invalide — entier positif attendu' }));
        return;
      }
      res.writeHead(200, { 'content-type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify(phaseDetail(planningRoot, Number(raw), logEvent)));
      return;
    }

    if (url.pathname === '/api/log') {
      res.writeHead(200, { 'content-type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ count: LOG.length, events: LOG }));
      return;
    }

    if (url.pathname === '/api/events') {
      res.writeHead(200, {
        'content-type': 'text/event-stream',
        'cache-control': 'no-cache',
        connection: 'keep-alive',
      });
      res.write('retry: 1000\n\n');
      clients.add(res);
      req.on('close', () => clients.delete(res));
      return;
    }

    if (url.pathname === '/') {
      const indexPath = referencesDir ? safeJoin(referencesDir, path.join('ui', 'index.html')) : null;
      if (indexPath && fs.existsSync(indexPath)) {
        res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
        res.end(fs.readFileSync(indexPath));
        return;
      }
      res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
      res.end(
        `<!doctype html><html><head><meta charset="utf-8"><title>vf-cockpit</title></head>` +
        `<body><h1>vf-cockpit</h1><p>Interface non encore posée (references/ui/index.html manquant).</p>` +
        `<p>API disponible : <a href="/api/state">/api/state</a>, <a href="/api/log">/api/log</a>.</p>` +
        `<p>Racine .planning/ résolue : ${escapeHtml(planningRoot || 'aucune')}</p></body></html>`,
      );
      return;
    }

    // Assets statiques sous referencesDir (allowlist d'extension + garde anti-traversée).
    if (referencesDir && url.pathname.startsWith('/assets/')) {
      const rel = url.pathname.slice('/assets/'.length);
      const ext = path.extname(rel).toLowerCase();
      const mime = MIME_ALLOWLIST[ext];
      const target = mime ? safeJoin(referencesDir, rel) : null;
      if (target && fs.existsSync(target) && fs.statSync(target).isFile()) {
        res.writeHead(200, { 'content-type': mime });
        res.end(fs.readFileSync(target));
        return;
      }
      res.writeHead(404, { 'content-type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ error: 'not found' }));
      return;
    }

    res.writeHead(404, { 'content-type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({ error: 'not found' }));
  });

  return server;
}

// ---------- boot (seulement en exécution directe, pas quand importé par les tests) ----------
function isMainModule() {
  try {
    return import.meta.url === `file://${path.resolve(process.argv[1] || '')}`;
  } catch {
    return false;
  }
}

if (isMainModule()) {
  const planningRoot = resolvePlanningRoot(process.argv.slice(2), process.env);
  const referencesDir = resolveReferencesDir(HERE);
  if (!referencesDir) {
    logEvent('boot', 'aucun dossier de références trouvé (ni ../references ni ../skills/vf-cockpit/references)');
  }
  if (!planningRoot) {
    console.error(
      '[vf-cockpit] aucun dossier .planning/ trouvé en remontant depuis ' +
      `${process.cwd()}. Lance la commande depuis un lab VibeFlow, ou passe ` +
      '--planning-root=<chemin> / VF_COCKPIT_PLANNING_ROOT=<chemin>.',
    );
  }

  const requestedPort = Number(process.env.VF_COCKPIT_PORT || DEFAULT_PORT);
  const server = createCockpitServer({ planningRoot, referencesDir });

  function tryListen(port, attemptsLeft) {
    server.once('error', (err) => {
      if (err.code === 'EADDRINUSE' && attemptsLeft > 0) {
        logEvent('boot', `port ${port} occupé, tentative sur ${port + 1}`);
        tryListen(port + 1, attemptsLeft - 1);
        return;
      }
      console.error(`[vf-cockpit] impossible d'écouter sur le port ${port} : ${err.message}. ` +
        'Surcharge le port via VF_COCKPIT_PORT=<port>.');
      process.exitCode = 1;
    });
    server.listen(port, HOST, () => {
      logEvent('boot', `cockpit sur http://${HOST}:${port} — racine ${planningRoot || '(aucune)'}`);
      console.log(`vf-cockpit → http://${HOST}:${port}`);
    });
  }
  tryListen(requestedPort, 10);
}
