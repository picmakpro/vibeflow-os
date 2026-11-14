// mesures-pied.mjs — mesures navigateur du pied réservé, des glyphes et des zooms (tâche 2 du plan 75-07). Mêmes règles que mesures.mjs :
// une fonction par section, un objet JSON simple en retour, la mise en page (worker) attendue stable avant chaque relevé.
const DIR_A = 'd:d-src|src/a', DIR_B = 'd:d-src|src/b', NOEUD = 'n:d-src';
const CLES = ['bas', 'moyen', 'haut', 'confluent', 'bouclier', 'sans-temoin', 'en-cours', 'modifie', 'lu', 'fini', 'prevu'];
const ZOOMS = ['ouverture', 'mid', 'bas'];

// ---- silhouettes : le masque CSS de chaque glyphe est lu dans la page (style calculé) et rastérisé à k = 0,42 (24 unités = 10,08 px), couverture 0,5, quatre décalages
const rasterJs = (K, G) => `(async () => {
  const S = 16, K = ${K}, G = ${G}, DEC = [[0, 0], [0.5, 0], [0, 0.5], [0.5, 0.5]];
  const masque = (el, pseudo) => { const st = getComputedStyle(el, pseudo || null), v = st.maskImage && st.maskImage !== 'none' ? st.maskImage : st.webkitMaskImage; return v.replace(/^url\\("?/, '').replace(/"?\\)$/, ''); };
  const image = async (u) => { const i = new Image(); i.src = u; await i.decode(); return i; };
  const zone = document.createElement('div'); zone.style.cssText = 'position:fixed;left:0;top:0'; document.body.append(zone);
  const lectures = {};
  for (const k of ${JSON.stringify(CLES)}) { const lm = document.createElement('span'); lm.className = 'lm'; const g = document.createElement('i'); g.className = 'lg lg-' + k; lm.append(g); zone.append(lm); lectures[k] = masque(g); }
  for (const n of ['tolere', 'todo']) { const t = document.createElement('span'); t.className = 'vst vst-' + n; zone.append(t); lectures[n] = masque(t, '::before'); }
  const sortie = { sil: {}, ink: {} };
  for (const [k, u] of Object.entries(lectures)) {
    const img = await image(u); sortie.sil[k] = [];
    for (const [dx, dy] of DEC) {
      const c = document.createElement('canvas'); c.width = c.height = G * S; const x = c.getContext('2d', { willReadFrequently: true });
      x.drawImage(img, (1 + dx) * S, (1 + dy) * S, K * S, K * S); const d = x.getImageData(0, 0, G * S, G * S).data; let bits = '';
      for (let py = 0; py < G; py++) for (let px = 0; px < G; px++) { let a = 0; for (let yy = 0; yy < S; yy++) for (let xx = 0; xx < S; xx++) a += d[((py * S + yy) * G * S + px * S + xx) * 4 + 3]; bits += a / (S * S * 255) >= 0.5 ? '1' : '0'; }
      sortie.sil[k].push(bits);
    }
    const c = document.createElement('canvas'); c.width = c.height = 320; const x = c.getContext('2d', { willReadFrequently: true }); x.drawImage(img, 0, 0, 320, 320);
    const d = x.getImageData(0, 0, 320, 320).data; let x0 = 999, y0 = 999, x1 = -1, y1 = -1;
    for (let py = 0; py < 320; py++) for (let px = 0; px < 320; px++) if (d[(py * 320 + px) * 4 + 3] > 8) { x0 = Math.min(x0, px); y0 = Math.min(y0, py); x1 = Math.max(x1, px + 1); y1 = Math.max(y1, py + 1); }
    sortie.ink[k] = [x0 / 20, y0 / 20, x1 / 20, y1 / 20]; // unités du viewBox (320 px pour 16 unités)
  }
  zone.remove(); return JSON.stringify(sortie); })()`;
const dist = (a, b) => Math.min(...a.map((s, i) => { let n = 0, u = 0; for (let j = 0; j < s.length; j++) { if (s[j] === '1' && b[i][j] === '1') n++; if (s[j] === '1' || b[i][j] === '1') u++; } return u ? 1 - n / u : 0; }));
const encre = (a) => Math.min(...a.map((s) => (s.match(/1/g) || []).length)) / 100; // la boîte du glyphe fait 10 x 10 pixels à k = 0,42
const colonnes = (bits) => { const h = []; for (let x = 0; x < 12; x++) { let n = 0; for (let y = 0; y < 12; y++) if (bits[y * 12 + x] === '1') n++; h.push(n); } return h; };
// une barre = un groupe de colonnes non éteintes ; sa hauteur = sa colonne la plus haute (les colonnes de bord, à demi couvertes, varient d'un pixel : on ne les compte pas)
const barres = (h) => { const hs = []; for (let i = 0; i < h.length; i++) { if (h[i] > 0 && (i === 0 || h[i - 1] === 0)) hs.push(0); if (h[i] > 0) hs[hs.length - 1] = Math.max(hs[hs.length - 1], h[i]); } return { groupes: hs.length, hauteurs: new Set(hs).size }; };

// ---- contraste (WCAG 2.x) sur des sondes dans la page : chaque glyphe sur --surface, --raise (.module) et le canevas, en clair et en sombre
const lum = (c) => { const [r, g, b] = c.map((v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4; }); return 0.2126 * r + 0.7152 * g + 0.0722 * b; };
const contraste = (a, b) => { const [x, y] = [lum(a), lum(b)].sort((p, q) => q - p); return (x + 0.05) / (y + 0.05); };
const SONDES = (theme) => `(() => { document.documentElement.setAttribute('data-theme', ${JSON.stringify(theme)});
  const rgb = (v) => (v.match(/[\\d.]+/g) || []).slice(0, 3).map(Number), zone = document.createElement('div'); zone.style.cssText = 'position:fixed;left:0;top:0;width:300px'; document.body.append(zone);
  const carte = (cls) => { const c = document.createElement('div'); c.className = 'card ' + cls; const p = document.createElement('div'); p.className = 'foot'; c.append(p); zone.append(c); return { c, p }; };
  const out = { bg: rgb(getComputedStyle(document.body).backgroundColor), couleurs: {}, fond: {} };
  for (const [nom, cls] of [['surface', ''], ['raise', 'module']]) {
    const { c, p } = carte(cls); out.fond[nom] = rgb(getComputedStyle(c).backgroundColor); out.couleurs[nom] = {};
    for (const k of ${JSON.stringify(CLES)}) { const g = document.createElement('i'); g.className = 'lg lg-' + k; p.append(g); out.couleurs[nom][k] = rgb(getComputedStyle(g).backgroundColor); }
  }
  const t = document.createElement('i'); t.style.cssText = 'color:var(--recent)'; zone.append(t); out.recent = rgb(getComputedStyle(t).color); t.style.color = 'var(--recent-text)'; out.recentTexte = rgb(getComputedStyle(t).color);
  zone.remove(); return JSON.stringify(out); })()`;

const GEOM = `JSON.stringify({ L: VibeFlow.state.layout.children.map((c) => [c.id, Math.round(c.x), Math.round(c.y), c.width, c.height]), F: [...document.querySelectorAll('#viewport .node')].map((g) => { const f = g.querySelector('.card .foot'), c = g.querySelector('.card'); return [f ? f.offsetHeight : null, c ? c.offsetWidth : null, c ? c.offsetHeight : null]; }), k: Math.round(VibeFlow.state.t.k * 1000) / 1000, H: Math.round(VibeFlow.state.bounds.h), W: Math.round(VibeFlow.state.bounds.w) })`;

export const mesuresPied = {
  // D6, D7 : le pied est réservé dès la construction, sans lentille, à 20 puis 28 aux paliers lod ; connecteurs sans pied
  async d6(c) {
    const { s } = c; await c.vue(1440, 900); await c.charger('index.html'); const o = {};
    for (const cont of [DIR_A, DIR_B]) {
      await c.aller(cont); o[cont] = {};
      for (const z of ZOOMS) {
        await c.zoom(z); await c.poser();
        o[cont][z] = JSON.parse(await s.ev(`JSON.stringify([...document.querySelectorAll('#viewport .node')].map((g) => { const id = [...VibeFlow.state.chipEls].find(([, v]) => v === g)[0], f = g.querySelector('.card .foot'); return [id.slice(0, 2), f ? f.offsetHeight : null]; }))`));
      }
    }
    return o;
  },
  // D6b (F2), D8, D8b : la géométrie complète des cartes de Projet et d'Équipe, et du Code (k d'ouverture, hauteur du plan) ; la suite compare deux serveurs
  async d8(c) {
    const { s } = c, o = { code: [], projet: null, equipe: null };
    for (const [w, h] of [[1440, 900], [390, 844]]) {
      await c.vue(w, h, w < 500); await c.charger('index.html');
      for (const cont of ['root', NOEUD, DIR_A, DIR_B]) {
        await c.aller(cont); await c.stabiliser(() => s.ev(GEOM), { pas: 200, max: 12000 });
        const g = JSON.parse(await s.ev(GEOM)); o.code.push({ w, cont, k: g.k, H: g.H, W: g.W, sansPied: g.F.filter((f, i) => f[0] === null && !g.L[i][0].startsWith('x:')).length, cartes: g.L.length });
      }
    }
    await c.vue(1440, 900); await c.charger('project.html'); await c.stabiliser(() => s.ev(GEOM), { pas: 200, max: 12000 }); o.projet = await s.ev(GEOM);
    if (c.sid) { await c.charger('equipe.html'); await c.aller('n:ag-' + c.sid); await c.stabiliser(() => s.ev(GEOM), { pas: 200, max: 12000 }); o.equipe = await s.ev(GEOM); }
    return o;
  },
  // D9, D9b, D9d : silhouettes à k = 0,42, paliers de barres, pavé d'encre dans le viewBox
  async d9(c) {
    await c.vue(1440, 900); await c.charger('index.html');
    const r = JSON.parse(await c.s.ev(rasterJs(24 * 0.42, 12))), sil = r.sil, d = (a, b) => Math.round(dist(sil[a], sil[b]) * 1000) / 1000, pair = (xs) => xs.flatMap((a, i) => xs.slice(i + 1).map((b) => [a + '|' + b, d(a, b)]));
    return {
      empreinte: pair(['en-cours', 'modifie', 'lu', 'fini']), boucliers: pair(['bouclier', 'sans-temoin']), trio: pair(['confluent', 'bouclier', 'sans-temoin']),
      tolere: CLES.map((k) => [k, d(k, 'tolere')]), basFini: d('bas', 'fini'), encre: CLES.map((k) => [k, encre(sil[k])]),
      barres: ['bas', 'moyen', 'haut'].map((k, i) => [k, i + 1, sil[k].map((b) => barres(colonnes(b)))]), ink: r.ink,
    };
  },
  // D14 (S11) : la paire « Prévu » / « À faire » (anneau à trois arcs contre anneau) à 16 px, 10 px et k = 0,42
  async d14sil(c) {
    await c.vue(1440, 900); await c.charger('index.html'); const o = {};
    for (const [nom, K, G] of [['16px', 16, 18], ['10px', 10, 12], ['k042', 24 * 0.42, 12]]) { const sil = JSON.parse(await c.s.ev(rasterJs(K, G))).sil; o[nom] = Math.round(dist(sil.prevu, sil.todo) * 1000) / 1000; }
    return o;
  },
  // D10 : contraste des glyphes, deux thèmes ; --recent seulement pour « en cours », --recent-text sur .module
  async d10(c) {
    await c.vue(1440, 900); await c.charger('index.html'); const o = {};
    for (const th of ['dark', 'light']) {
      const p = JSON.parse(await c.s.ev(SONDES(th))), min = {}, recentHors = [];
      for (const [fond, cles] of Object.entries(p.couleurs)) for (const [k, col] of Object.entries(cles)) {
        const cibles = k === 'en-cours' ? (fond === 'raise' ? [p.fond.raise] : [p.fond.surface, p.bg]) : [p.fond.surface, p.fond.raise, p.bg];
        min[`${fond}:${k}`] = Math.round(Math.min(...cibles.map((b) => contraste(col, b))) * 100) / 100;
        if (k !== 'en-cours' && (col.join() === p.recent.join() || col.join() === p.recentTexte.join())) recentHors.push(`${fond}:${k}`);
      }
      o[th] = { min, recentHors, enCoursSurRaise: p.couleurs.raise['en-cours'].join() === p.recentTexte.join(), enCoursSurSurface: p.couleurs.surface['en-cours'].join() === p.recent.join() };
    }
    await c.s.ev("document.documentElement.setAttribute('data-theme', 'dark')");
    return o;
  },
  // D11, D3b (S8), D11b, D12 : les trois zooms, la largeur (mot ellipsé, jamais le glyphe), le CSS du pied, aucun fond ni liseré
  async d11(c) {
    const { s } = c; await c.vue(1440, 900); await c.charger('index.html'); await c.aller(NOEUD); const o = { zooms: {} };
    const LONG = 'modifié · vf-coder et 2 autres ' + 'très long '.repeat(30);
    const avant = await s.ev(`getComputedStyle(VibeFlow.state.chipEls.get(${JSON.stringify(DIR_A)}).querySelector('.card')).boxShadow`);
    await s.ev(`VF_MARQUES.poser('d11', [[${JSON.stringify(DIR_A)}, 'haut', 'en-cours', 'en écriture · vf-coder', 'info'], [${JSON.stringify(DIR_B)}, 'moyen', 'modifie', ${JSON.stringify(LONG)}, 'info']], { exclusif: true })`);
    const lire = (id) => `(() => { const g = VibeFlow.state.chipEls.get(${JSON.stringify(id)}), ca = g.querySelector('.card'), pi = g.querySelector('.card .foot'), lm = g.querySelector('.lm'), lg = g.querySelector('.lg'), lw = g.querySelector('.lw'), lc = g.querySelector('.lc'), me = g.querySelector('.meta');
      const rc = ca.getBoundingClientRect(), rp = pi.getBoundingClientRect(), rl = lm.getBoundingClientRect(), cs = getComputedStyle(lm), ls = getComputedStyle(lw);
      return { lg: Math.round(lg.getBoundingClientRect().width / (rc.width / ca.offsetWidth) * 100) / 100, lgPx: lg.offsetWidth, pied: pi.offsetHeight, lw: ls.display, lc: getComputedStyle(lc).display, ellipse: lw.scrollWidth > lw.clientWidth + 1 && ls.textOverflow === 'ellipsis',
        pad: cs.paddingLeft + '|' + cs.paddingRight + '|' + cs.paddingTop, droit: rl.right <= rc.right + 0.5, bas: rl.bottom <= rp.bottom + 0.5 && rl.top >= rp.top - 0.5, meta: me ? me.offsetWidth : 0, mot: lw.textContent.length }; })()`;
    await c.poser();
    for (const z of ZOOMS) { await c.zoom(z); await c.poser(); o.zooms[z] = { a: await s.ev(lire(DIR_A)), b: await s.ev(lire(DIR_B)) }; }
    // D11b : au palier lod-mid, un .meta long s'ellipse sans faire sortir la marque ni déborder le pied de 28
    await c.zoom('mid'); await s.ev(`VibeFlow.state.chipEls.get(${JSON.stringify(DIR_A)}).querySelector('.meta').textContent = ${JSON.stringify('x'.repeat(200))}`);
    o.metaLong = await s.ev(`(() => { const m = VibeFlow.state.chipEls.get(${JSON.stringify(DIR_A)}).querySelector('.meta'); const st = getComputedStyle(m); return { ...(${lire(DIR_A)}), ellipse: m.scrollWidth > m.clientWidth + 1 && st.textOverflow === 'ellipsis' }; })()`);
    // D12 : aucune ombre, aucun fond, aucun liseré ajouté par la marque
    await c.zoom('ouverture'); await c.poser();
    o.style = await s.ev(`(() => { const g = VibeFlow.state.chipEls.get(${JSON.stringify(DIR_A)}), r = []; for (const e of [g.querySelector('.lm'), g.querySelector('.lmg'), g.querySelector('.lw')]) { const t = getComputedStyle(e); r.push([t.backgroundColor, t.backgroundImage, t.boxShadow, t.borderTopWidth, t.outlineStyle, t.borderTopLeftRadius].join('|')); } return { marque: r, carteAvant: ${JSON.stringify(avant)}, carteApres: getComputedStyle(g.querySelector('.card')).boxShadow }; })()`);
    return o;
  },
  // D17 : la respiration du glyphe « en cours » (animation calculée), coupée sous prefers-reduced-motion
  async d17(c) {
    const { s } = c; await c.vue(1440, 900); await c.charger('index.html'); await c.aller(NOEUD);
    await s.ev(`VF_MARQUES.poser('d17', [[${JSON.stringify(DIR_A)}, 'haut', 'en-cours', 'en écriture', 'info']], { exclusif: true })`); await c.poser();
    const nom = () => s.ev(`getComputedStyle(VibeFlow.state.chipEls.get(${JSON.stringify(DIR_A)}).querySelector('.lg-en-cours')).animationName`);
    const o = { normal: await nom(), keyframeVfrespire: await s.ev("[...document.styleSheets].some((f) => { try { return [...f.cssRules].some((r) => r.name === 'vfrespire'); } catch { return false; } })") };
    await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
    o.reduit = await nom();
    await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'no-preference' }] });
    return o;
  },
};
