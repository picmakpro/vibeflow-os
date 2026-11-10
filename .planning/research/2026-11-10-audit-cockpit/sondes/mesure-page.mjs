// Mesure en lecture seule (GET uniquement) du cockpit servi : coût de chargement, mise en page ELK, traduction,
// rerender, et saturation des connexions SSE. Lance SON PROPRE Chrome headless (profil jetable dans le scratchpad),
// le ferme à la fin. Aucune écriture dans le dépôt, aucun POST.
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

const BASE = process.argv[2];
const SCRATCH = process.argv[3];
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const dir = fs.mkdtempSync(path.join(SCRATCH, 'chrome-profil-'));
const ch = spawn(CHROME, ['--headless=new', '--disable-gpu', '--no-first-run', '--no-default-browser-check', '--remote-debugging-port=0', `--user-data-dir=${dir}`, '--window-size=1440,900', 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
let sortie; const garde = setTimeout(() => { console.error('échéance globale : arrêt de Chrome'); try { ch.kill('SIGKILL'); } catch {} try { fs.rmSync(dir, { recursive: true, force: true }); } catch {} console.log(JSON.stringify(sortie || {}, null, 1)); process.exit(3); }, 170000);
const pause = (ms) => new Promise((r) => setTimeout(r, ms));
const wsUrl = await new Promise((ok, ko) => { let buf = ''; ch.stderr.on('data', (d) => { buf += d; const m = /DevTools listening on (ws:\/\/\S+)/.exec(buf); if (m) ok(m[1]); }); ch.on('exit', () => ko(new Error('Chrome est sorti avant d annoncer son port'))); setTimeout(() => ko(new Error('Chrome muet')), 30000); });
const ws = new WebSocket(wsUrl);
await new Promise((ok, ko) => { ws.onopen = ok; ws.onerror = () => ko(new Error('WebSocket')); });
let id = 0; const attente = new Map(); const ecoute = new Set();
ws.onmessage = (ev) => { const m = JSON.parse(ev.data); if (m.id && attente.has(m.id)) { const { ok, ko } = attente.get(m.id); attente.delete(m.id); m.error ? ko(new Error(m.error.message)) : ok(m.result); } else for (const f of ecoute) f(m); };
const send = (method, params = {}, sessionId) => new Promise((ok, ko) => { const i = ++id; attente.set(i, { ok, ko }); ws.send(JSON.stringify({ id: i, method, params, ...(sessionId ? { sessionId } : {}) })); });

const INIT = `
window.__audit = { lt: [], elk: [], firstCard: null };
try { new PerformanceObserver((l) => { for (const e of l.getEntries()) window.__audit.lt.push([Math.round(e.startTime), Math.round(e.duration)]); }).observe({ type: 'longtask', buffered: true }); } catch (e) {}
(() => { let reel; try { Object.defineProperty(window, 'ELK', { configurable: true, get() { return reel; }, set(v) {
  reel = function (...a) { const inst = new v(...a); const orig = inst.layout.bind(inst);
    inst.layout = (g, ...r) => { const t = performance.now(); const n = (g.children || []).length, e = (g.edges || []).length; return orig(g, ...r).then((res) => { window.__audit.elk.push([n, e, Math.round((performance.now() - t) * 10) / 10]); return res; }); };
    return inst; }; } }); } catch (e) {} })();
(() => { const tick = () => { if (document.querySelector && document.querySelector('#viewport .node')) window.__audit.firstCard = Math.round(performance.now()); else requestAnimationFrame(tick); }; requestAnimationFrame(tick); })();
`;
async function ouvrir(url, { attendreLoad = 20000 } = {}) {
  const { targetId } = await send('Target.createTarget', { url: 'about:blank' });
  const { sessionId } = await send('Target.attachToTarget', { targetId, flatten: true });
  await send('Page.enable', {}, sessionId); await send('Runtime.enable', {}, sessionId); await send('Performance.enable', {}, sessionId);
  await send('Page.addScriptToEvaluateOnNewDocument', { source: INIT }, sessionId);
  let charge = false; const f = (m) => { if (m.sessionId === sessionId && m.method === 'Page.loadEventFired') charge = true; }; ecoute.add(f);
  const t0 = Date.now();
  await send('Page.navigate', { url }, sessionId);
  while (!charge && Date.now() - t0 < attendreLoad) await pause(50);
  ecoute.delete(f);
  return { targetId, sessionId, charge, ms: Date.now() - t0 };
}
const dire = (x) => console.error(new Date().toISOString().slice(11, 19) + " " + x);
const evBrut = async (s, expr) => { const r = await send('Runtime.evaluate', { expression: expr, awaitPromise: true, returnByValue: true }, s); if (r.exceptionDetails) throw new Error(r.exceptionDetails.exception?.description || r.exceptionDetails.text); return r.result.value; };
const ev = (s, expr, ms = 25000) => Promise.race([evBrut(s, expr), pause(ms).then(() => { throw new Error("évaluation sans réponse en " + ms + " ms"); })]);
const metriques = async (s) => Object.fromEntries((await send('Performance.getMetrics', {}, s)).metrics.map((m) => [m.name, m.value]));
const fermer = (p) => send('Target.closeTarget', { targetId: p.targetId }).catch(() => {});
const r1 = (x) => Math.round(x * 10) / 10;

sortie = { base: BASE, pages: {} };
try {
  for (const [nom, chemin] of [['code', '/'], ['projet', '/project.html'], ['equipe', '/equipe.html']]) {
    dire("page " + nom); const p = await ouvrir(BASE + chemin); dire("  chargée=" + p.charge + " en " + p.ms + " ms");
    // prêt : première carte posée, puis 2 s de calme
    const t0 = Date.now(); while (Date.now() - t0 < 20000 && !(await ev(p.sessionId, '!!(window.__audit && window.__audit.firstCard)'))) await pause(100);
    await pause(2500);
    const m0 = await metriques(p.sessionId);
    const etat = await ev(p.sessionId, `(() => { const n = performance.getEntriesByType('navigation')[0] || {}; const SC = window.VibeFlow || window.Floorplan; const G = SC && SC.graph;
      return { nav: { reponse: Math.round(n.responseEnd), domInteractif: Math.round(n.domInteractive), dcl: Math.round(n.domContentLoadedEventEnd), load: Math.round(n.loadEventEnd), octets: n.decodedBodySize },
        premiereCarte: window.__audit.firstCard, tachesLongues: window.__audit.lt, elk: window.__audit.elk,
        fr: window.__vfFr ? { passes: window.__vfFr.passes, ms: Math.round(window.__vfFr.ms * 10) / 10, noeuds: window.__vfFr.nodes, attrs: window.__vfFr.attrs } : null,
        direct: window.__vfLive ? { connecte: window.__vfLive.connected, sondages: window.__vfLive.sondages } : null,
        dom: document.getElementsByTagName('*').length, styles: document.querySelectorAll('style').length, scripts: document.scripts.length, cartes: document.querySelectorAll('#viewport .node').length,
        graphe: G ? { noeuds: G.nodes.length, fichiers: G.files.length, liens: G.links.length } : null, lang: document.documentElement.lang, titre: document.title }; })()`);
    // rerender x5 : coût total et part de la traduction
    dire("  état relevé"); let rer = null; try { rer = await ev(p.sessionId, `(async () => { const SC = window.VibeFlow || window.Floorplan; const out = []; for (let i = 0; i < 5; i++) { const f0 = window.__vfFr ? window.__vfFr.ms : 0, p0 = window.__vfFr ? window.__vfFr.passes : 0, e0 = window.__audit.elk.length; const t = performance.now(); await SC.rerender(); await new Promise((r) => requestAnimationFrame(() => setTimeout(r, 0))); out.push({ total: Math.round((performance.now() - t) * 10) / 10, elk: (window.__audit.elk[e0] || [])[2] ?? null, fr: Math.round(((window.__vfFr ? window.__vfFr.ms : 0) - f0) * 10) / 10, passesFr: (window.__vfFr ? window.__vfFr.passes : 0) - p0 }); } return out; })()`, 30000); } catch (e) { rer = String(e.message); } dire("  rerender : " + JSON.stringify(rer).slice(0, 200));
    // plus gros conteneur (enfants directs) : mise en page d'une vue chargée
    let gros = null;
    if (nom !== 'equipe') try { gros = await ev(p.sessionId, `(async () => { const SC = window.VibeFlow || window.Floorplan; const G = SC.graph; const par = {}; for (const f of G.files) par[f.n] = (par[f.n] || 0) + 1; for (const n of G.nodes) if (n.parent) par[n.parent] = (par[n.parent] || 0) + 1;
      const top = Object.entries(par).sort((a, b) => b[1] - a[1])[0]; if (!top) return null; const e0 = window.__audit.elk.length, f0 = window.__vfFr ? window.__vfFr.ms : 0; const t = performance.now();
      await SC.go('n:' + top[0]); const fin = performance.now() + 15000; while (window.__audit.elk.length === e0 && performance.now() < fin) await new Promise((r) => setTimeout(r, 50)); await new Promise((r) => requestAnimationFrame(() => setTimeout(r, 0)));
      return { enfantsDirects: top[1], vue: window.__audit.elk[e0] || null, total: Math.round(performance.now() - t), fr: Math.round(((window.__vfFr ? window.__vfFr.ms : 0) - f0) * 10) / 10, cartes: document.querySelectorAll('#viewport .node').length, dom: document.getElementsByTagName('*').length }; })()`, 30000); } catch (e) { gros = String(e.message); } dire("  gros conteneur : " + JSON.stringify(gros));
    const m1 = await metriques(p.sessionId);
    sortie.pages[nom] = { loadMs: p.ms, ...etat, rerender: rer, plusGrosConteneur: gros,
      cdp: { scriptS: r1(m0.ScriptDuration * 1000), layoutMs: r1(m0.LayoutDuration * 1000), styleMs: r1(m0.RecalcStyleDuration * 1000), tachesMs: r1(m0.TaskDuration * 1000), tasMo: r1(m0.JSHeapUsedSize / 1048576), noeudsDom: m0.Nodes, ecouteurs: m0.JSEventListeners, ecouteursApres: m1.JSEventListeners, noeudsApres: m1.Nodes, tasApresMo: r1(m1.JSHeapUsedSize / 1048576) } };
    await fermer(p); await pause(300);
  }
  // ELK seul, à l'échelle : même algorithme que le viewer, graphes synthétiques (dans une page du cockpit, donc même moteur)
  { const p = await ouvrir(BASE + '/'); await pause(1500);
    sortie.elkEchelle = await ev(p.sessionId, `(async () => { const out = []; for (const n of [25, 50, 100, 200]) { const children = Array.from({ length: n }, (_, i) => ({ id: 'c' + i, width: 300, height: 120 })); const edges = []; for (let i = 0; i < Math.floor(n * 1.5); i++) { const a = (i * 7919) % n, b = (i * 104729 + 13) % n; if (a !== b) edges.push({ id: 'e' + i, sources: ['c' + a], targets: ['c' + b] }); }
      const t = performance.now(); try { await new ELK().layout({ id: 'g', children, edges, layoutOptions: { 'elk.algorithm': 'layered', 'elk.direction': 'RIGHT', 'elk.edgeRouting': 'ORTHOGONAL', 'elk.layered.nodePlacement.strategy': 'NETWORK_SIMPLEX', 'elk.layered.thoroughness': '12' } }); out.push([n, edges.length, Math.round(performance.now() - t)]); } catch (e) { out.push([n, edges.length, 'erreur ' + String(e.message).slice(0, 60)]); }
      if (performance.now() - t > 20000) break; } return out; })()`, 40000).catch((e) => String(e.message)); dire("elk échelle : " + JSON.stringify(sortie.elkEchelle));
    await fermer(p); await pause(300); }
  // saturation des connexions : 3 pages ouvertes = 6 flux SSE sur la même origine
  { dire("saturation"); const A = await ouvrir(BASE + '/'), B = await ouvrir(BASE + '/project.html'), C = await ouvrir(BASE + '/equipe.html'); await pause(3000);
    const flux = async (p) => ev(p.sessionId, `(() => performance.getEntriesByType('resource').filter((r) => /\\/api\\/(vf\\/)?events/.test(r.name)).length)()`);
    const sonde = (p, ms) => ev(p.sessionId, `(async () => { const t = performance.now(); try { const r = await fetch('/api/vf/etat', { headers: { 'x-vf-cockpit-token': window.VF_COCKPIT_SERVER.token }, cache: 'no-store', signal: AbortSignal.timeout(${ms}) }); const j = await r.json(); return { ok: r.ok, ms: Math.round(performance.now() - t), clients: j.clients }; } catch (e) { return { ok: false, ms: Math.round(performance.now() - t), erreur: e.name }; } })()`);
    const connectes = async (p) => ev(p.sessionId, '!!(window.__vfLive && window.__vfLive.connected)');
    sortie.saturation = { directConnecte: [await connectes(A), await connectes(B), await connectes(C)], sondeAvec3Pages: await sonde(C, 5000) };
    const D = await ouvrir(BASE + '/', { attendreLoad: 6000 });
    sortie.saturation.quatriemePageChargeeEn6s = D.charge; sortie.saturation.quatriemePageMs = D.ms;
    await fermer(A); await pause(1200);
    sortie.saturation.sondeApresFermetureDUnePage = await sonde(C, 5000);
    const t0 = Date.now(); let ok = D.charge; while (!ok && Date.now() - t0 < 6000) { ok = await ev(D.sessionId, "document.readyState === 'complete'").catch(() => false); await pause(100); }
    sortie.saturation.quatriemePageChargeeApresFermeture = ok;
    await fermer(B); await fermer(C); await fermer(D); }
} catch (e) { sortie.erreur = String(e.stack || e); dire("ERREUR " + sortie.erreur.slice(0, 300)); }
finally {
  try { await Promise.race([send('Browser.close'), pause(3000)]); } catch {}
  await Promise.race([new Promise((r) => ch.on('exit', r)), pause(4000)]);
  try { ch.kill('SIGKILL'); } catch {}
  try { fs.rmSync(dir, { recursive: true, force: true }); } catch {}
  clearTimeout(garde);
}
console.log(JSON.stringify(sortie, null, 1));
process.exit(0);
