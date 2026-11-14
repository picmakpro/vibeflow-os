// live-page.mjs <dossier ui/> — ui/70-vf-live.js hors navigateur (vm, d'après le harnais vm70 de test-cockpit-equipe.sh) : vrais 71-vf-equipe-rendu.js,
// 69-vf-flux.js (repli « page » : ni canal ni verrous dans le contexte), 70-vf-etat.js, puis 70-vf-live.js ; EventSource factice, horloge et minuteries pilotées.
// Cas : un patch dont st et foot sont vides (ce qu'émet le serveur quand un statut ou un pied disparaît) les retire de la carte.
// Sortie : une ligne JSON { retrait: { ok, detail } }, code 0 si le cas passe, 1 sinon, 2 si l'aide ne s'exécute pas.
import fs from 'node:fs'; import path from 'node:path'; import vm from 'node:vm';
const UI = process.argv[2];
const tick = () => new Promise((r) => setImmediate(r));
function page(vfTab, nodes) {
  const W = { t: 1700000000000, timers: [], nid: 0, reloads: 0, es: [] };
  const h = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  class ES { constructor(u) { this.u = u; this.l = {}; this.closed = false; W.es.push(this); } addEventListener(n, f) { (this.l[n] ||= []).push(f); } close() { this.closed = true; } }
  const el = () => ({ setAttribute() {}, appendChild() {}, append() {}, remove() {}, style: {}, classList: { toggle() {}, add() {}, remove() {} } });
  const SC = { graph: { meta: { vfTab }, nodes, files: [] }, h, toast() {}, rerender: async () => {}, on() {}, addPanelSection() {}, showPanel() {},
    addHeaderButton: (o) => ({ ...o, className: '', innerHTML: '', setAttribute() {} }) };
  const document = { createElement: el, head: { appendChild() {} }, body: { appendChild() {}, classList: { contains: () => false } }, documentElement: {}, hidden: false,
    addEventListener() {}, dispatchEvent: () => true, getElementById: () => null, querySelectorAll: () => [], querySelector: () => null };
  class D extends Date { static now() { return W.t; } }
  const setTimeout = (f, ms) => { const id = ++W.nid; W.timers.push({ id, f, due: W.t + Math.max(0, Number(ms) || 0) }); return id; };
  const clearTimeout = (id) => { W.timers = W.timers.filter((x) => x.id !== id); };
  const window = { Floorplan: SC, FLOORPLAN_SERVER: { token: 't' }, VF_COCKPIT_SERVER: { token: 't' } };
  const ctx = vm.createContext({ window, document, EventSource: ES, CustomEvent: class { constructor(t) { this.type = t; } }, location: { reload() { W.reloads++; } },
    fetch: () => Promise.reject(new Error('serveur arrêté')), setTimeout, clearTimeout, queueMicrotask, Date: D, console: { error() {}, log() {}, warn() {} }, encodeURIComponent, Promise, JSON, Math });
  for (const f of ['71-vf-equipe-rendu.js', '69-vf-flux.js', '70-vf-etat.js', '70-vf-live.js']) vm.runInContext(fs.readFileSync(path.join(UI, f), 'utf8'), ctx, { timeout: 5000 });
  const courant = () => W.es.filter((e) => !e.closed).at(-1);
  W.emettre = async (n, d) => { const e = courant(); for (const f of (e && e.l[n]) || []) f({ data: JSON.stringify(d) }); await tick(); };
  W.couper = async () => { const e = courant(); if (e && typeof e.onerror === 'function') e.onerror({}); await tick(); };
  W.avancer = async (ms, plafond = 3000) => { // rend false si le plafond d'exécutions est atteint (délai nul en boucle)
    const fin = W.t + ms; let n = 0;
    for (;;) { const p = W.timers.filter((x) => x.due <= fin).sort((a, b) => a.due - b.due || a.id - b.id)[0]; if (!p) break;
      if (++n > plafond) return false; W.timers = W.timers.filter((x) => x !== p); W.t = Math.max(W.t, p.due); try { p.f(); } catch { /* la page garde ses erreurs */ } await tick(); await tick(); }
    W.t = fin; await tick(); return true;
  };
  W.probe = () => window.__vfLive; W.SC = SC;
  return W;
}
const hello = (seq) => ({ seq, lock: { seq: 0, at: 1, verrous: { etat: 'absente', plat: false, liste: [] } }, who: { workers: [], sources: {} } });
const R = {};
try {
  {
    const W = page('project', [{ id: 'p1', st: 'done', foot: '3/3 plans' }]); await W.emettre('hello', hello(1));
    await W.emettre('patch', { seq: 2, at: W.t, patch: [{ ref: 'n:p1', st: '', foot: '' }] });
    const n = W.SC.graph.nodes[0]; R.retrait = { ok: W.probe().applied === 1 && n.st === undefined && n.foot === undefined, detail: { applied: W.probe().applied, st: n.st ?? null, foot: n.foot ?? null } };
  }
} catch (e) { console.log(JSON.stringify({ erreur: 'exécution : ' + String(e && e.message).slice(0, 200) })); process.exit(2); }
console.log(JSON.stringify(R));
process.exit(Object.values(R).length && Object.values(R).every((c) => c.ok) ? 0 : 1);
