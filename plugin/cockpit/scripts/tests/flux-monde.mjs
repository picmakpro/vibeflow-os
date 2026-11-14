// flux-monde.mjs — navigateur simulé pour ui/69-vf-flux.js (79-14) : une origine, des verrous à file d'attente (steal, ifAvailable, signal), des canaux par nom,
// une horloge et des minuteries pilotées (régime réglable par onglet, gel et dégel), un Math.random à graine, un EventSource factice, un contexte `vm`
// PAR ONGLET qui exécute le VRAI fichier de la page. Le journal garde tous les messages postés (onglet émetteur compris).
// creerMonde({ graine }) -> { M, ouvrirOnglet(f69, opts), avancer(ms), vide(), fermer(t), geler(t), degeler(t), emettre(t, nom, data), erreurFlux(t), injecter(nom, m), visibilite(t, etat) }
import fs from 'node:fs';
import vm from 'node:vm';

export const vide = () => new Promise((r) => setImmediate(r));
const abandon = () => new DOMException('verrou perdu', 'AbortError');
const mulberry = (a) => () => { a |= 0; a = (a + 0x6D2B79F5) | 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };

export function creerMonde({ graine = 1, helloAuto = false } = {}) { // helloAuto : le serveur factice envoie un hello 5 ms après chaque connexion
  const M = { now: 1700000000000, timers: [], nt: 0, canaux: [], verrous: new Map(), journal: [], flux: [], onglets: [], fetchs: [], vols: 0, alea: mulberry(graine) };
  const differer = (t, f) => { if (t.gele) t.differes.push(f); else f(); };
  const vl = (nom) => { if (!M.verrous.has(nom)) M.verrous.set(nom, { det: null, file: [] }); return M.verrous.get(nom); };
  const liberer = (v, req) => {
    if (v.det === req) v.det = null;
    while (!v.det && v.file.length) { const n = v.file.shift(); if (!n.tab.ferme) accorder(v, n); }
  };
  const accorder = (v, req) => {
    v.det = req;
    Promise.resolve().then(() => req.cb({ name: 'verrou' })).then((r) => { liberer(v, req); req.resolve(r); }, (e) => { liberer(v, req); req.reject(e); });
  };
  const demander = (tab) => (nom, a, b) => {
    const opts = typeof a === 'function' ? {} : a; const cb = typeof a === 'function' ? a : b;
    return new Promise((resolve, reject) => {
      const v = vl(nom); const req = { tab, cb, resolve, reject };
      if (opts.signal) {
        if (opts.signal.aborted) return reject(abandon());
        opts.signal.addEventListener('abort', () => { const i = v.file.indexOf(req); if (i >= 0) { v.file.splice(i, 1); reject(abandon()); } });
      }
      if (opts.steal) {
        M.vols++; const d = v.det; v.det = null;
        if (d) differer(d.tab, () => d.reject(abandon()));
        return accorder(v, req);
      }
      if (!v.det) return accorder(v, req);
      if (opts.ifAvailable) return Promise.resolve().then(() => cb(null)).then(resolve, reject);
      v.file.push(req);
    });
  };
  const livrer = (c, m) => {
    if (c.tab.ferme || c.tab.sourd) return;
    differer(c.tab, () => { if (typeof c.onmessage === 'function') c.onmessage({ data: m }); });
  };
  const creerCanal = (tab) => class BC {
    constructor(nom) { this.nom = nom; this.tab = tab; M.canaux.push(this); }
    postMessage(m) {
      const copie = structuredClone(m); M.journal.push({ de: tab.id, nom: this.nom, m: copie });
      for (const c of M.canaux) if (c !== this && c.nom === this.nom) { const x = structuredClone(m); Promise.resolve().then(() => livrer(c, x)); }
    }
    close() { M.canaux = M.canaux.filter((c) => c !== this); }
  };
  const creerFlux = (tab) => class ES {
    constructor(url) {
      this.url = String(url); this.l = {}; this.closed = false; this.tab = tab; M.flux.push(this); tab.flux.push(this);
      if (helloAuto) minuteur(tab, () => { if (!this.closed) for (const f of (this.l.hello || [])) f({ data: '{"seq":1}' }); }, 5, false);
    }
    addEventListener(n, f) { (this.l[n] = this.l[n] || []).push(f); }
    close() { this.closed = true; }
  };

  function minuteur(tab, f, ms, repete) {
    const t = { id: ++M.nt, tab, f, ms, repete, due: M.now + Math.max(ms, repete ? tab.minMin : 0) };
    M.timers.push(t); return t.id;
  }
  const retirer = (id) => { M.timers = M.timers.filter((t) => t.id !== id); };

  function ouvrirOnglet(f69, { jeton, lab = 'a1b2c3d4e5f6', locks = true, canal = true, sur = true, minuterie = true, minMin = 0 } = {}) {
    const tab = { id: M.onglets.length + 1, jeton, lab, gele: false, ferme: false, sourd: false, decalage: 0, minMin, flux: [], recus: [], differes: [], conns: [], pertes: 0,
      src: null, doc: {}, visibilite: 'visible', vm: null };
    const fetchSim = (url, o = {}) => {
      M.fetchs.push({ de: tab.id, url, entetes: JSON.stringify(o.headers || {}) });
      if (lab instanceof Error) return Promise.reject(lab);
      if (lab === 'http') return Promise.resolve({ ok: false, json: async () => ({}) });
      return Promise.resolve({ ok: true, json: async () => ({ lab }) });
    };
    const g = { window: {}, document: { get visibilityState() { return tab.visibilite; }, addEventListener: (t, f) => { (tab.doc[t] = tab.doc[t] || []).push(f); } },
      EventSource: creerFlux(tab), fetch: fetchSim, Date: { now: () => M.now + tab.decalage }, Math: { random: M.alea, floor: Math.floor }, JSON, Object, Array, Promise, Map, Set,
      Error, RangeError, TypeError, AbortController, encodeURIComponent, console, setTimeout: (f, ms) => minuteur(tab, f, ms, false), clearTimeout: retirer };
    if (minuterie) { g.setInterval = (f, ms) => minuteur(tab, f, ms, true); g.clearInterval = retirer; }
    if (locks) g.navigator = { locks: { request: demander(tab) } };
    if (canal) g.BroadcastChannel = creerCanal(tab);
    if (sur) g.isSecureContext = true;
    const ctx = vm.createContext(g);
    vm.runInContext(fs.readFileSync(f69, 'utf8'), ctx, { timeout: 5000 });
    tab.vm = ctx.window.VF_FLUX;
    tab.ouvrir = () => { // ce que fait ui/70-vf-live.js : une source, des abonnements, onerror
      const src = tab.vm.ouvrir(tab.jeton); tab.src = src;
      for (const nom of tab.vm.EVENEMENTS) src.addEventListener(nom, (e) => tab.recus.push({ nom, data: e.data, src }));
      src.onerror = () => { tab.pertes++; src.close(); };
      return src;
    };
    tab.vm.surConnexion((e) => tab.conns.push(e));
    M.onglets.push(tab); return tab;
  }

  async function avancer(ms) {
    const fin = M.now + ms;
    for (;;) {
      const pret = M.timers.filter((t) => !t.tab.gele && !t.tab.ferme && t.due <= fin).sort((a, b) => a.due - b.due || a.id - b.id)[0];
      if (!pret) break;
      M.now = Math.max(M.now, pret.due);
      if (pret.repete) pret.due = M.now + Math.max(pret.ms, pret.tab.minMin); else retirer(pret.id);
      try { pret.f(); } catch { /* la page garde ses erreurs */ }
      await vide();
    }
    M.now = fin; await vide();
  }
  const courant = (t) => [...t.flux].reverse().find((e) => !e.closed);
  return { M, ouvrirOnglet, avancer, vide,
    fermer: async (t) => { t.ferme = true; for (const v of M.verrous.values()) { if (v.det && v.det.tab === t) liberer(v, v.det); v.file = v.file.filter((r) => r.tab !== t); }
      M.canaux = M.canaux.filter((c) => c.tab !== t); M.timers = M.timers.filter((x) => x.tab !== t); for (const e of t.flux) e.closed = true; await vide(); },
    geler: (t) => { t.gele = true; },
    degeler: async (t) => { t.gele = false; const d = t.differes.splice(0); for (const f of d) f(); for (const x of M.timers) if (x.tab === t && x.due < M.now) x.due = M.now; await vide(); },
    emettre: async (t, nom, data) => { const e = courant(t); if (e && !t.gele) for (const f of (e.l[nom] || [])) f({ data: typeof data === 'string' ? data : JSON.stringify(data) }); await vide(); },
    erreurFlux: async (t) => { const e = courant(t); if (e && typeof e.onerror === 'function') e.onerror({}); await vide(); },
    injecter: async (nom, m) => { for (const c of [...M.canaux]) if (c.nom === nom) livrer(c, m); await vide(); },
    visibilite: async (t, etat) => { t.visibilite = etat; for (const f of (t.doc.visibilitychange || [])) f(); await vide(); },
    fluxOuverts: () => M.flux.filter((e) => !e.closed) };
}
