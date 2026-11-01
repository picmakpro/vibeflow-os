#!/usr/bin/env node
// Spike 003 — sonde : branche un client SSE sur live.mjs, applique des mutations réelles au
// .planning/ d'un BAC À SABLE (jamais au dépôt) et mesure, pour chacune, le délai écriture →
// événement reçu, et la nature de l'événement. Sort un tableau JSON + exit 1 si une attente échoue.
// usage: node probe.mjs <sandbox-root> [--port 4379]
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const root = path.resolve(process.argv[2]);
if (!fs.existsSync(path.join(root, '.planning')) || root.includes('/vibeflow-os/.claude/worktrees/') || root.endsWith('/vibeflow-os')) { console.error('refus : bac à sable requis'); process.exit(2); }
const port = process.argv.includes('--port') ? process.argv[process.argv.indexOf('--port') + 1] : 4379;
const P = (...a) => path.join(root, '.planning', ...a);

// ---------- client SSE minimal (fetch + flux) ----------
const events = [];
const res = await fetch(`http://127.0.0.1:${port}/events`);
const reader = res.body.getReader();
(async () => {
  let buf = '';
  for (;;) {
    const { value, done } = await reader.read(); if (done) break;
    buf += new TextDecoder().decode(value);
    let i; while ((i = buf.indexOf('\n\n')) >= 0) {
      const chunk = buf.slice(0, i); buf = buf.slice(i + 2);
      const ev = /^event: (.*)$/m.exec(chunk)?.[1]; const data = /^data: (.*)$/m.exec(chunk)?.[1];
      if (ev) events.push({ ev, t: Date.now(), data: data ? JSON.parse(data) : null });
    }
  }
})();
const wait = (ms) => new Promise((r) => setTimeout(r, ms));
const until = async (pred, ms) => { const t0 = Date.now(); while (Date.now() - t0 < ms) { const e = events.find(pred); if (e) return e; await wait(20); } return null; };
await until((e) => e.ev === 'hello', 3000);

const results = [];
const step = async (name, expect, mutate, timeout = 4000) => {
  const from = events.length; const t0 = Date.now();
  const detail = mutate();
  const e = await until((x) => events.indexOf(x) >= from && expect.includes(x.ev), timeout);
  await wait(500);
  const extra = events.slice(from).map((x) => x.ev);
  results.push({ name, expect: expect.join('|'), got: e?.ev || 'RIEN', latencyMs: e ? e.t - t0 : null, events: extra, patch: e?.data?.patch?.length, detail, ok: !!e });
};

// M1 — un nœud de DAG passe en cours
const dagF = P('MISSION-38.dag.json');
const dag = JSON.parse(fs.readFileSync(dagF, 'utf8'));
const node = dag.nodes.find((n) => n.status === 'done') || dag.nodes[0];
await step('M1 nœud DAG → running', ['patch'], () => { node.status = 'running'; fs.writeFileSync(dagF, JSON.stringify(dag, null, 2)); return node.id; });
// M2 — une phase non cochée devient cochée dans la ROADMAP
const rmF = P('workstreams/fiabilite/ROADMAP.md');
const rm = fs.readFileSync(rmF, 'utf8'); const line = /^- \[ \] Phase (\d+(?:\.\d+)?):.*$/m.exec(rm);
await step('M2 phase cochée', ['patch'], () => { fs.writeFileSync(rmF, rm.replace(line[0], line[0].replace('- [ ]', '- [x]'))); return 'Phase ' + line[1]; });
// M3 — un PLAN ajouté dans un dossier de phase : structure
const phDir = path.join(P('workstreams/fiabilite/phases'), fs.readdirSync(P('workstreams/fiabilite/phases')).find((d) => /^VFDO-/.test(d)));
const newPlan = path.join(phDir, path.basename(phDir).replace(/^VFDO-([\d.]+)-.*/, 'VFDO-$1') + '-99-PLAN.md');
await step('M3 PLAN ajouté', ['structural'], () => { fs.writeFileSync(newPlan, '---\nwave: 9\n---\n# Plan sonde\n'); return path.basename(newPlan); });
// M4 — rafale : 20 écritures en 100 ms → un seul rafraîchissement attendu
const before = events.length;
await step('M4 rafale 20 écritures', ['patch'], () => { for (let i = 0; i < 20; i++) { node.status = i % 2 ? 'done' : 'running'; fs.writeFileSync(dagF, JSON.stringify(dag)); } node.status = 'failed'; fs.writeFileSync(dagF, JSON.stringify(dag)); return '21 écritures'; });
results.at(-1).refreshes = events.slice(before).filter((e) => e.ev === 'patch' || e.ev === 'structural').length;
// M5a — DAG corrompu 150 ms puis restauré (écriture non atomique de dag.sh) : AUCUN rechargement attendu
await step('M5a DAG illisible 150 ms (rien attendu)', ['structural'], () => { fs.writeFileSync(dagF, '{ "nodes": [ tronqué'); setTimeout(() => fs.writeFileSync(dagF, JSON.stringify(dag, null, 2)), 150); return 'transitoire'; }, 2000);
results.at(-1).ok = results.at(-1).got === 'RIEN';
// M5b — DAG durablement corrompu : la mission disparaît après la seconde lecture, le serveur survit
await step('M5b DAG illisible durable', ['structural'], () => { fs.writeFileSync(dagF, '{ "nodes": [ tronqué'); return 'durable'; }, 3000);
results.at(-1).serverAlive = !!(await (await fetch(`http://127.0.0.1:${port}/state`)).json()).cards;
fs.writeFileSync(dagF, JSON.stringify(dag, null, 2));
await wait(1200);
// M6 — verrou de driver réel (driver-lock.sh) : acquire puis heartbeat avec nouvelle étape
const DL = path.join(root, 'plugin/conductor/scripts/driver-lock.sh');
await step('M6 verrou acquis', ['lock'], () => execFileSync('bash', [DL, 'acquire', '--owner=sonde-003', '--step=mesure'], { cwd: root, encoding: 'utf8' }).trim().slice(0, 80), 7000);
await step('M7 heartbeat, étape changée', ['lock'], () => execFileSync('bash', [DL, 'heartbeat', '--owner=sonde-003', '--step=mesure-2'], { cwd: root, encoding: 'utf8' }).trim().slice(0, 80), 7000);
await step('M8 verrou relâché', ['lock'], () => execFileSync('bash', [DL, 'release', '--owner=sonde-003'], { cwd: root, encoding: 'utf8' }).trim().slice(0, 80), 7000);
// remise en état du bac à sable
fs.writeFileSync(rmF, rm); fs.rmSync(newPlan);
console.log(JSON.stringify(results, null, 1));
process.exit(results.every((r) => r.ok) ? 0 : 1);
