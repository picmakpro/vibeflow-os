// flux-pastille.mjs <dossier ui> — la pastille #vf-lock d'un serveur arrêté entre le hello et le premier rendu de l'onglet (79-17, SOCL-21). Exécute les VRAIS
// 69-vf-flux.js, 70-vf-etat.js, 70-vf-live.js dans un vm : DOM minimal, horloge et minuteries pilotées, coquille dont les rappels surOnglet partent au premier rendu.
// Scénarios : A hello, arrêt, PUIS premier rendu (la pastille finit « off ») · B témoin : arrêt sans hello, puis rendu · C témoin : rendu, hello, puis arrêt.
// Rend UNE ligne JSON : [{ nom, trace, finale, connexion, banniere, sondages, erreurs }].
import fs from 'node:fs';
import vm from 'node:vm';
const UI = process.argv[2];
const src = (n) => fs.readFileSync(`${UI}/${n}`, 'utf8');
const vide = () => new Promise((r) => setImmediate(r));

async function scenario(nom, etapes) {
  const T = { now: 1700000000000, timers: [], nt: 0 };
  const els = new Map(); // id -> élément
  const mk = (tag) => {
    const e = { tag, id: '', className: '', title: '', attrs: {}, children: [], innerHTML: '', textContent: '', style: {}, hidden: false, dataset: {},
      setAttribute(k, v) { this.attrs[k] = String(v); if (k === 'id') this.id = v; }, getAttribute(k) { return this.attrs[k] ?? null; }, removeAttribute(k) { delete this.attrs[k]; },
      append(...c) { this.children.push(...c); }, appendChild(c) { this.children.push(c); if (c.id) els.set(c.id, c); return c; },
      remove() { if (this.id) els.delete(this.id); }, querySelector: () => null, querySelectorAll: () => [], classList: { contains: () => false, add() {}, remove() {}, toggle() {} } };
    return e;
  };
  const body = mk('body');
  const document = { head: mk('head'), body, hidden: false, visibilityState: 'visible', createElement: mk, getElementById: (id) => els.get(id) || null,
    querySelector: () => null, querySelectorAll: () => [], addEventListener() {}, dispatchEvent() { return true; }, activeElement: null };
  body.appendChild = (c) => { if (c.id) els.set(c.id, c); return c; };
  const flux = [];
  class ES { constructor(url) { this.url = url; this.l = {}; this.closed = false; flux.push(this); } addEventListener(n, f) { (this.l[n] ||= []).push(f); } close() { this.closed = true; } }
  const fetchs = [];
  let serveur = true;
  const fetchSim = (url) => { fetchs.push(url); return serveur ? Promise.resolve({ ok: true, status: 200, json: async () => ({}) }) : Promise.reject(new TypeError('Failed to fetch')); };
  const rappels = []; let pret = false;
  const minuteur = (f, ms) => { const id = ++T.nt; T.timers.push({ id, f, due: T.now + (ms || 0) }); return id; };
  const ctx = {
    console: { error: (...a) => ctx.__err.push(a.join(' ')), log() {}, warn() {} }, __err: [],
    document, EventSource: ES, fetch: fetchSim, setTimeout: minuteur, clearTimeout: (id) => { T.timers = T.timers.filter((t) => t.id !== id); },
    setInterval: () => 0, queueMicrotask, CustomEvent: class { constructor(t, o) { this.type = t; this.detail = o && o.detail; } },
    location: { reload: () => { ctx.__reload = (ctx.__reload || 0) + 1; } }, navigator: {}, Date: { now: () => T.now },
    Math, JSON, Object, Array, Promise, Map, Set, Error, RangeError, TypeError, Number, String, encodeURIComponent, AbortController,
  };
  ctx.window = ctx;
  ctx.FLOORPLAN_SERVER = { token: 'jeton-synthetique' };
  ctx.VF_COCKPIT_SERVER = { token: 'jeton-synthetique' };
  ctx.VF_COQUILLE = { surOnglet: (f) => { if (pret) f({}); else rappels.push(f); return () => {}; } };
  const listeners = {};
  ctx.Floorplan = { graph: { meta: { vfTab: 'code' }, nodes: [], files: [] }, h: (s) => String(s),
    addHeaderButton({ id }) { const b = mk('button'); b.id = id; els.set(id, b); return b; },
    on(ev, f) { (listeners[ev] ||= []).push(f); }, showPanel() {}, toast() {}, rerender: async () => {}, addPanelSection() {} };
  vm.createContext(ctx);
  for (const f of ['69-vf-flux.js', '70-vf-etat.js', '70-vf-live.js']) vm.runInContext(src(f), ctx, { filename: f });
  // 71-vf-equipe-rendu.js est chargé après 70 ; ses aides sont posées avant le premier rendu
  ctx.__vfEquipeRendu = { actif: (w) => w.etat === 'actif', duree: (s) => s + ' s', nomDeSession: () => 'x', glyphe: () => '', arbre: () => '', surveiller: () => '', css: '', agentsDuNoeud: () => '' };
  const avancer = async (ms) => {
    const fin = T.now + ms;
    for (;;) { await vide(); T.timers.sort((a, b) => a.due - b.due); const t = T.timers[0]; if (!t || t.due > fin) break; T.timers.shift(); T.now = t.due; t.f(); await vide(); }
    T.now = fin; await vide();
  };
  const es = () => flux.filter((x) => !x.closed).at(-1);
  const pastille = () => { const b = els.get('vf-lock'); return b ? b.className + ' | ' + (b.attrs['aria-label'] || '') : 'absente'; };
  const ops = {
    hello: () => { const e = es(); for (const f of e.l.hello || []) f({ data: JSON.stringify({ seq: 3, who: { workers: [{ kind: 'session', id: 's1', etat: 'actif' }] }, lock: { seq: 3, at: 1, verrous: { liste: [] } } }) }); },
    arret: () => { serveur = false; const e = es(); if (e && typeof e.onerror === 'function') e.onerror({}); },
    rendu: () => { pret = true; for (const f of rappels.splice(0)) f({}); },
  };
  const trace = [];
  await vide(); await vide();
  for (const op of etapes) { ops[op](); await vide(); await vide(); trace.push(op + ' -> ' + pastille()); }
  await avancer(20000);
  return { nom, trace, finale: pastille(), connexion: ctx.VF_ETAT.lire('connexion'), banniere: !!els.get('vf-reco'), sondages: ctx.__vfLive.sondages, erreurs: ctx.__err.length };
}

const out = [];
out.push(await scenario('A hello, arrêt, puis premier rendu', ['hello', 'arret', 'rendu']));
out.push(await scenario('B témoin : arrêt sans hello, puis premier rendu', ['arret', 'rendu']));
out.push(await scenario('C témoin : premier rendu, hello, puis arrêt', ['rendu', 'hello', 'arret']));
console.log(JSON.stringify(out));
process.exit(0);
