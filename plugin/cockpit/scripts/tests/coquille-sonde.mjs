// coquille-sonde.mjs — la sonde de la suite de la coquille (79-16, SOCL-20) : un script posé AVANT tout script de la page
// (Page.addScriptToEvaluateOnNewDocument), qui enveloppe les primitives natives pour compter, SANS passer par la coquille.
// Exporte SONDE (le texte du script). Elle publie window.__s :
//   ins        insertions de <script src> : [{ src, rang }] dans l'ordre (rang = ordre d'insertion)
//   ecout()    compte NET d'écouteurs de window, document, html, body : { 'window:keydown': 3, … } (clés triées)
//   vivants()  { intervalles, observateurs, flux } (instances vivantes)
//   props()    noms propres de window, triés
//   journal    suite ordonnée de marques : 'ready:<onglet>' (un « ready » du moteur), posée par le crochet de window.VibeFlow
//   prof       profondeur d'enveloppement de fetch au dernier appel (cadres venus de /_vf/ui/) ; sonder(fetch) la déclenche
//   req        adresses de /api/vf/graphe demandées (fetch)
//   empreinte()  l'état du document, par classes : corps (identifiants, balises), tete, classesBody, attrsHtml, props, ecouteurs, vivants
//   profondeurFetch()  appelle fetch et rend la profondeur d'enveloppement vue (cadres de /_vf/ui/ dans la pile)
//   depart     { href, longueur } de l'historique au premier script ; ins[].titre : document.title à l'insertion
export const SONDE = `(() => {
  const S = window.__s = { ins: [], journal: [], prof: -1, req: [] }; let rang = 0;
  const cible = (t) => (t === window ? 'window' : t === document ? 'document' : t === document.documentElement ? 'html' : t === document.body ? 'body' : null);
  const net = new Map(), add = EventTarget.prototype.addEventListener, rem = EventTarget.prototype.removeEventListener;
  const cle = (t, ty, f, o) => cible(t) + '|' + ty + '|' + (!!(o === true || (o && o.capture)));
  const reg = new Map(); // cle -> Set de fonctions
  EventTarget.prototype.addEventListener = function (ty, f, o) { const c = cible(this); if (c && typeof f === 'function') { const k = cle(this, ty, f, o); if (!reg.has(k)) reg.set(k, new Set()); reg.get(k).add(f); } return add.call(this, ty, f, o); };
  EventTarget.prototype.removeEventListener = function (ty, f, o) { const c = cible(this); if (c && reg.has(cle(this, ty, f, o))) reg.get(cle(this, ty, f, o)).delete(f); return rem.call(this, ty, f, o); };
  S.ecout = () => { const r = {}; for (const [k, v] of reg) if (v.size) { const [c, ty] = k.split('|'); r[c + ':' + ty] = (r[c + ':' + ty] || 0) + v.size; } return Object.fromEntries(Object.entries(r).sort()); };
  const inter = new Set(), obs = new Set(), flux = new Set();
  const si = window.setInterval, ci = window.clearInterval;
  window.setInterval = function (...a) { const id = si.apply(this, a); inter.add(id); return id; };
  window.clearInterval = function (id) { inter.delete(id); return ci.call(this, id); };
  for (const nom of ['MutationObserver', 'ResizeObserver', 'IntersectionObserver']) { const O = window[nom]; if (!O) continue;
    window[nom] = class extends O { constructor(...a) { super(...a); obs.add(this); } disconnect() { obs.delete(this); return super.disconnect(); } }; }
  { const E = window.EventSource; window.EventSource = class extends E { constructor(...a) { super(...a); flux.add(this); } close() { flux.delete(this); return super.close(); } }; }
  S.vivants = () => ({ intervalles: inter.size, observateurs: obs.size, flux: [...flux].filter((e) => e.readyState !== 2).length });
  S.props = () => Object.getOwnPropertyNames(window).filter((n) => n !== 'goog').sort(); // goog : posée par le navigateur lui-même, jamais par la page
  for (const m of ['appendChild', 'insertBefore']) { const o = Node.prototype[m]; Node.prototype[m] = function (n, ...r) { if (n && n.tagName === 'SCRIPT' && n.src) S.ins.push({ src: new URL(n.src).pathname, rang: rang++, titre: document.title }); return o.call(this, n, ...r); }; }
  { const f0 = window.fetch; window.fetch = function (u, ...r) { if (/\\/api\\/vf\\/graphe/.test(String(u))) S.req.push(String(u)); S.prof = (new Error().stack.match(/\\/_vf\\/ui\\//g) || []).length; return f0.call(this, u, ...r); }; }
  S.depart = { href: location.href, longueur: history.length };
  S.empreinte = () => {
    const sansId = (e) => e.tagName + (e.id ? '#' + e.id : '') + (e.src ? '@' + new URL(e.src).pathname : '');
    const balises = {}; for (const e of document.body.querySelectorAll('*')) balises[e.tagName] = (balises[e.tagName] || 0) + 1;
    const garde = ['data-theme', 'lang', 'data-vf-pret'];
    return { corps: { ids: [...document.body.querySelectorAll('[id]')].map((e) => e.id).sort(), balises }, tete: [...document.head.children].map(sansId).sort(),
      classesBody: [...document.body.classList].sort(), attrsHtml: Object.fromEntries([...document.documentElement.attributes].filter((a) => !garde.includes(a.name)).map((a) => [a.name, a.name === 'style' ? a.value.split(';').map((x) => x.trim()).filter(Boolean).sort().join(';') : a.value])),
      props: S.props(), ecouteurs: S.ecout(), vivants: S.vivants() };
  };
  S.profondeurFetch = async () => { try { await fetch('/api/status'); } catch { /* sans importance : on lit la pile */ } return S.prof; };
  let vf; Object.defineProperty(window, 'VibeFlow', { configurable: true, get: () => vf, set: (v) => { vf = v; try { v.on('ready', () => S.journal.push('ready:' + (v.graph?.meta?.vfTab || '?'))); } catch {} } });
})();`;
