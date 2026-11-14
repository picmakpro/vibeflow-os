// R26 (passe finale, EX-01) : écouteurs `change` des listes de requêtes média, comptés vivants (posés - retirés) par script d'origine, au chargement puis après six changements d'onglet.
// Corps joué par coquille-chrome.mjs « avec » ; la portée de la coquille ne défait pas ces écouteurs : chaque script d'onglet ré-exécuté les retire lui-même.
// amorce: (() => { const P = MediaQueryList.prototype, A = P.addEventListener, R = P.removeEventListener, m = new WeakMap(); const q = window.__mq = { add: {}, rem: {} }; const src = () => { const r = /ui\/([0-9]{2}-[A-Za-z0-9-]+\.js)/.exec(new Error().stack || ''); return r ? r[1] : 'autre'; }; P.addEventListener = function (t, f, o) { if (t !== 'change' || typeof f !== 'function') return A.call(this, t, f, o); const n = src(); q.add[n] = (q.add[n] || 0) + 1; let e = m.get(f); if (!e) { e = { n, w: function (ev) { return f.call(this, ev); } }; m.set(f, e); } return A.call(this, t, e.w, o); }; P.removeEventListener = function (t, f, o) { const e = typeof f === 'function' && m.get(f); if (t === 'change' && e) { q.rem[e.n] = (q.rem[e.n] || 0) + 1; return R.call(this, t, e.w, o); } return R.call(this, t, f, o); }; })()
const vivants = async () => JSON.parse(await s.ev(`JSON.stringify((() => { const q = window.__mq, v = {}; for (const n of new Set([...Object.keys(q.add), ...Object.keys(q.rem)])) v[n] = (q.add[n] || 0) - (q.rem[n] || 0); return v; })())`));
const avant = await vivants();
const tours = [];
for (const o of ['projet', 'code', 'projet', 'code', 'projet', 'code']) {
  tours.push(await s.ev(`window.VF_COQUILLE.chargerOnglet('${o}').then(() => 'ok', (e) => 'ko:' + String(e && e.message))`));
  await pause(400);
}
return { tours, avant, apres: await vivants() };
