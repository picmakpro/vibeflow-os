#!/usr/bin/env node
// Spike 005 — sonde : pose des questions à /api/ask comme le ferait la barre de question de chaque
// onglet (jeton lu dans la page servie), et mesure voie, délai, ids valides. Sort un tableau JSON.
// usage: node probe.mjs [--base http://127.0.0.1:4378] [--llm]   (--llm : inclut les questions qui vont à l'agent)
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const arg = (k, d) => { const i = process.argv.indexOf(k); return i > 0 ? process.argv[i + 1] : d; };
const base = arg('--base', 'http://127.0.0.1:4378'), withLlm = process.argv.includes('--llm');
const tokenOf = async (page) => JSON.parse(/window\.FLOORPLAN_SERVER=(\{.*?\});<\/script>/.exec(await (await fetch(base + page)).text())[1]).token;
const graphOf = async (page) => { const h = await (await fetch(base + page)).text(); const A = '<script>window.FLOORPLAN = '; const a = h.indexOf(A); return JSON.parse(h.slice(a + A.length, h.indexOf(';</script>', a))); };

async function ask(token, question, abortMs) {
  const t0 = Date.now(), ctl = new AbortController(); if (abortMs) setTimeout(() => ctl.abort(), abortMs);
  try { return await ask1(token, question, t0, ctl); } catch (e) { return { ms: Date.now() - t0, aborted: true, progress: [] }; }
}
async function ask1(token, question, t0, ctl) {
  const res = await fetch(base + '/api/ask', { signal: ctl.signal, method: 'POST', headers: { 'content-type': 'application/json', 'x-floorplan-token': token }, body: JSON.stringify({ question, mode: 'ask' }) });
  if (!res.ok) return { status: res.status, ms: Date.now() - t0 };
  const txt = await res.text(); const progress = [];
  let answer = null, failure = null;
  for (const block of txt.split('\n\n')) {
    const ev = /^event: (.*)$/m.exec(block)?.[1], data = /^data: (.*)$/m.exec(block)?.[1];
    if (ev === 'progress') progress.push(JSON.parse(data).text); else if (ev === 'answer') answer = JSON.parse(data); else if (ev === 'failure') failure = JSON.parse(data);
  }
  return { ms: Date.now() - t0, answer, failure, progress };
}

const [pt, ct] = [await tokenOf('/project.html'), await tokenOf('/')];
const GP = await graphOf('/project.html');
const ids = new Set([...GP.nodes.map((n) => 'n:' + n.id), ...GP.files.map((f) => 'f:' + f.p)]);
const cases = [
  ['local', 'Où en est-on ?'], ['local', "Qu'est-ce qui bloque ?"], ['local', "Qu'est-ce qui reste dans la phase 61 ?"],
  ['local', 'Quelles exigences pour la phase 61 ?'], ['local', 'COLB-08'], ['local', 'Qui a touché plugin/conductor/scripts/driver-lock.sh ?'],
  ['local', 'Mission 59'], ['local', 'Phase 999'],
  ...(withLlm ? [['agent', "Pourquoi la phase 62 a choisi l'option A ?"], ['agent', 'Quelles phases du jalon ecc-inspiration dépendent du verrou de driver, et dans quel ordre les faire ?']] : []),
];
const out = [];
// témoin : le jeton de l'onglet Code ne prend jamais la voie Projet (coupé à 2 s : l'agent de code n'a pas le temps de répondre)
const code = await ask(ct, 'Où en est-on ?', 2000);
for (const [expect, q] of cases) {
  const r = await ask(pt, q);
  const cited = [...new Set([...(r.answer?.answer || '').matchAll(/\[\[([^\]]+)\]\]/g)].map((m) => m[1]).concat((r.answer?.items || []).map((i) => i.id)))];
  const bad = cited.filter((id) => !ids.has(id));
  out.push({ q, expect, via: r.answer?.engine === 'local' ? 'local' : r.answer ? 'agent' : 'échec', ms: r.ms, title: r.answer?.title, items: r.answer?.items?.length || 0, invalidIds: bad, failure: r.failure?.code, progress: r.progress.slice(0, 6), answer: (r.answer?.answer || '').slice(0, 600) });
}
const forbidden = await fetch(base + '/api/ask', { method: 'POST', headers: { 'content-type': 'application/json', 'x-floorplan-token': 'faux' }, body: '{}' });
console.log(JSON.stringify({ codeTabNotLocal: { local: code.answer?.engine === 'local', aborted: !!code.aborted, ms: code.ms }, badTokenStatus: forbidden.status, results: out }, null, 1));
process.exit(out.every((r) => r.via === r.expect && !r.invalidIds.length) && forbidden.status === 403 && code.answer?.engine !== 'local' ? 0 : 1);
