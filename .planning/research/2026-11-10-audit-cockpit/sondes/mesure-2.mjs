// Mesure en lecture seule (GET uniquement) : (1) fuites après N rerender, ramasse-miettes forcé ; (2) saturation SSE et reprise.
// Chrome headless propre à cette mesure, profil jetable dans le scratchpad, fermé à la fin.
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
const BASE = process.argv[2], SCRATCH = process.argv[3];
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const dir = fs.mkdtempSync(path.join(SCRATCH, 'chrome-profil-'));
const ch = spawn(CHROME, ['--headless=new', '--disable-gpu', '--no-first-run', '--no-default-browser-check', '--remote-debugging-port=0', `--user-data-dir=${dir}`, '--window-size=1440,900', 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
const sortie = {};
const nettoyer = () => { try { ch.kill('SIGKILL'); } catch {} try { fs.rmSync(dir, { recursive: true, force: true }); } catch {} };
const garde = setTimeout(() => { console.error('échéance globale'); nettoyer(); console.log(JSON.stringify(sortie)); process.exit(3); }, 110000);
const pause = (ms) => new Promise((r) => setTimeout(r, ms));
const dire = (x) => console.error(new Date().toISOString().slice(11, 19) + ' ' + x);
const wsUrl = await new Promise((ok, ko) => { let buf = ''; ch.stderr.on('data', (d) => { buf += d; const m = /DevTools listening on (ws:\/\/\S+)/.exec(buf); if (m) ok(m[1]); }); setTimeout(() => ko(new Error('Chrome muet')), 30000); });
const ws = new WebSocket(wsUrl); await new Promise((ok, ko) => { ws.onopen = ok; ws.onerror = () => ko(new Error('WebSocket')); });
let id = 0; const attente = new Map(); const ecoute = new Set();
ws.onmessage = (e) => { const m = JSON.parse(e.data); if (m.id && attente.has(m.id)) { const { ok, ko } = attente.get(m.id); attente.delete(m.id); m.error ? ko(new Error(m.error.message)) : ok(m.result); } else for (const f of ecoute) f(m); };
const send = (method, params = {}, sessionId) => new Promise((ok, ko) => { const i = ++id; attente.set(i, { ok, ko }); ws.send(JSON.stringify({ id: i, method, params, ...(sessionId ? { sessionId } : {}) })); });
const borne = (p, ms, nom) => Promise.race([p, pause(ms).then(() => { throw new Error(`${nom} : sans réponse en ${ms} ms`); })]);
async function ouvrir(url) {
  const { targetId } = await send('Target.createTarget', { url: 'about:blank' });
  const { sessionId } = await send('Target.attachToTarget', { targetId, flatten: true });
  await send('Page.enable', {}, sessionId); await send('Runtime.enable', {}, sessionId); await send('Performance.enable', {}, sessionId); await send('HeapProfiler.enable', {}, sessionId);
  let charge = false; const f = (m) => { if (m.sessionId === sessionId && m.method === 'Page.loadEventFired') charge = true; }; ecoute.add(f);
  await borne(send('Page.navigate', { url }, sessionId), 15000, 'navigation ' + url);
  const t0 = Date.now(); while (!charge && Date.now() - t0 < 15000) await pause(50); ecoute.delete(f);
  return { targetId, sessionId, charge };
}
const ev = (s, expr, ms = 30000) => borne(send('Runtime.evaluate', { expression: expr, awaitPromise: true, returnByValue: true }, s).then((r) => { if (r.exceptionDetails) throw new Error(r.exceptionDetails.exception?.description || r.exceptionDetails.text); return r.result.value; }), ms, 'évaluation');
const fermer = (p) => send('Target.closeTarget', { targetId: p.targetId }).catch(() => {});
const releve = async (s) => { for (let i = 0; i < 3; i++) { await send('HeapProfiler.collectGarbage', {}, s); await pause(150); } const m = Object.fromEntries((await send('Performance.getMetrics', {}, s)).metrics.map((x) => [x.name, x.value])); return { noeuds: m.Nodes, ecouteurs: m.JSEventListeners, tasMo: Math.round(m.JSHeapUsedSize / 104857.6) / 10, documents: m.Documents }; };
const RER = (n) => `(async () => { const SC = window.VibeFlow || window.Floorplan; for (let i = 0; i < ${n}; i++) { await SC.rerender(); await new Promise((r) => requestAnimationFrame(() => setTimeout(r, 0))); } return document.getElementsByTagName('*').length; })()`;
try {
  sortie.fuites = {};
  for (const [nom, chemin, n] of [['projet', '/project.html', 60], ['code', '/', 25]]) {
    dire('fuites ' + nom); const p = await ouvrir(BASE + chemin); await pause(2500);
    const a = await releve(p.sessionId); const d1 = await ev(p.sessionId, RER(n), 60000);
    const b = await releve(p.sessionId); const d2 = await ev(p.sessionId, RER(n), 60000);
    const c = await releve(p.sessionId);
    sortie.fuites[nom] = { rerenderParSerie: n, avant: a, apresSerie1: b, apresSerie2: c, domVivant: [d1, d2] }; dire('  ' + JSON.stringify(sortie.fuites[nom]));
    await fermer(p); await pause(300);
  }
  dire('saturation');
  const A = await ouvrir(BASE + '/'), B = await ouvrir(BASE + '/project.html'), C = await ouvrir(BASE + '/equipe.html'); await pause(3000);
  const sonde = (p, ms) => ev(p.sessionId, `(async () => { const t = performance.now(); try { const r = await fetch('/api/vf/etat', { headers: { 'x-vf-cockpit-token': window.VF_COCKPIT_SERVER.token }, cache: 'no-store', signal: AbortSignal.timeout(${ms}) }); const j = await r.json(); return { ok: r.ok, ms: Math.round(performance.now() - t), clientsSSE: j.clients }; } catch (e) { return { ok: false, ms: Math.round(performance.now() - t), erreur: e.name }; } })()`, ms + 5000);
  const flux = (p) => ev(p.sessionId, `(() => ({ direct: !!(window.__vfLive && window.__vfLive.connected), sse: performance.getEntriesByType('resource').filter((r) => /\\/api\\/(vf\\/)?events/.test(r.name)).map((r) => r.name.replace(/\\?.*/, '')) }))()`);
  sortie.saturation = { pages: [await flux(A), await flux(B), await flux(C)] };
  sortie.saturation.sondeAvec3Pages = [await sonde(C, 4000), await sonde(B, 4000)];
  await fermer(A); await pause(1500);
  sortie.saturation.sondeAvec2Pages = [await sonde(C, 4000), await sonde(B, 4000)];
  dire('  ' + JSON.stringify(sortie.saturation));
  await fermer(B); await fermer(C);
} catch (e) { sortie.erreur = String(e.message || e); dire('ERREUR ' + sortie.erreur); }
finally { try { await Promise.race([send('Browser.close'), pause(3000)]); } catch {} await Promise.race([new Promise((r) => ch.on('exit', r)), pause(4000)]); nettoyer(); clearTimeout(garde); }
console.log(JSON.stringify(sortie, null, 1)); process.exit(0);
