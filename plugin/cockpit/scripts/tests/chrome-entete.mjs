// chrome-entete.mjs — mesures en rendu du titre de vue et de l'en-tête (80-20, FORM-18, P80-D-52, P80-D-53, P80-D-56), un vrai Chrome headless.
// Usage : node chrome-entete.mjs <chrome> <racine-du-serveur> <mode>   Rend UNE ligne JSON { … } ou { erreur }. Modes :
//   en1  : zone du titre (Code à 1440, 800, 390 px, graphe de Projet à 1440) : cartes sous #context après un glisser puis « + » ;
//          mise en page ; couloirs et liste
//   en14 : zone basse (lab --terminal, feuille de détail ouverte) à 390 et 800 px
//   en15 : Code → Projet → Code par VF_ONGLETS.aller, sans rechargement
//   en16 : observateurs et écouteurs de 01-vf-ensemble.js et 01-vf-responsive.js (comptes vivants), à froid puis après deux changements d'onglet
//   en2  : groupes de l'en-tête (1440, 1600, 1279, 1100, 800, 390 px), chevron, icônes, point de #vf-lock, Santé et menu des parcours
//   en3  : ouvreur Git (dessin et zone d'appui) à 800, 1100 et 1279 px, souris et toucher ; animations actives
// Chaque section est isolée (sec) : une section qui échoue laisse ses champs vides. Aucun fichier de la sortie n'est lu.
import { executer, pause, stabiliser } from './chrome-session.mjs';
const [, , chrome, racine, mode] = process.argv;
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
const POSEE = "(() => { const v = document.querySelector('#viewport'); return !!v && v.style.opacity !== '0' && !v.classList.contains('anim'); })()";
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) {"
  + " const vue = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0);"
  + " return vue ? 'true' : g.call(this, k); }; })()";
// aides posées dans la page : zone du titre, cartes sous la zone, rectangle, animations actives
const AIDES = `window.__e = (() => {
  const rect = (s) => { const e = typeof s === 'string' ? document.querySelector(s) : s; if (!e || !e.getClientRects().length) return null;
    const b = e.getBoundingClientRect(); return [Math.round(b.left * 100) / 100, Math.round(b.top * 100) / 100, Math.round(b.right * 100) / 100,
      Math.round(b.bottom * 100) / 100]; };
  const zone = () => { const c = document.getElementById('context'), b = c.getBoundingClientRect();
    return { x: b.left, y: b.top, w: b.width, h: Math.min(130, b.height), brut: b.height }; };
  const sous = () => { const z = zone(); let n = 0, total = 0;
    for (let i = 0; i < 8; i++) for (let j = 0; j < 4; j++) { total++;
      const x = z.x + z.w * (i + 0.5) / 8, y = z.y + z.h * (j + 0.5) / 4;
      if (document.elementsFromPoint(x, y).some((e) => e.matches('.card, g.node') || (e.closest && e.closest('g.node')))) n++; }
    return { n, total, h: z.h }; };
  const cv = document.createElement('canvas').getContext('2d', { willReadFrequently: true });
  const norm = (c) => { cv.clearRect(0, 0, 1, 1); cv.fillStyle = '#000'; cv.fillStyle = c; cv.fillRect(0, 0, 1, 1); const d = cv.getImageData(0, 0, 1,
    1).data; return [d[0], d[1], d[2]]; };
  const lin = (v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4; };
  const lum = (c) => 0.2126 * lin(c[0]) + 0.7152 * lin(c[1]) + 0.0722 * lin(c[2]);
  const ratio = (a, b) => { const x = lum(norm(a)), y = lum(norm(b)); return Math.round(((Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05)) * 100) / 100; };
  const jeton = (j) => { const p = document.createElement('i'); p.style.color = 'var(' + j + ')'; document.body.appendChild(p);
    const c = getComputedStyle(p).color; p.remove(); return c; };
  const vis = (e) => e.getClientRects().length > 0;
  const actives = () => document.getAnimations().filter((a) => a.playState === 'running' || a.playState === 'pending').length;
  return { rect, zone, sous, actives, ratio, jeton, vis };
})()`;
const KEYS = { f: ['KeyF', 70], '+': ['Equal', 187], Escape: ['Escape', 27] };

await executer(chrome, async (s) => {
  const o = { erreurs: {} };
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: SANS_VISITE });
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  const sec = async (nom, f) => { try { await f(); } catch (e) { o.erreurs[nom] = String(e.message).slice(0, 160); } };
  const lire = async (expr) => { const v = await s.ev(expr); return v === undefined ? null : JSON.parse(v); };
  const J = (appel) => lire(`JSON.stringify(${appel})`);
  const touche = async (key) => {
    const [code, vk] = KEYS[key], text = key.length === 1 ? key : undefined;
    for (const type of ['keyDown', 'keyUp']) {
      await s.send('Input.dispatchKeyEvent', { type, key, code, text: type === 'keyDown' ? text : undefined, windowsVirtualKeyCode: vk,
        nativeVirtualKeyCode: vk });
    }
  };
  const souris = (type, x, y) => s.send('Input.dispatchMouseEvent', { type, x, y, button: type === 'mouseMoved' ? 'none' : 'left',
    buttons: type === 'mouseReleased' ? 0 : 1, clickCount: 1 });
  const charger = async (page, w, h, tactile = false) => {
    await s.send('Emulation.setTouchEmulationEnabled', { enabled: tactile });
    await s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: tactile });
    const url = page.includes('lang=') ? page : page + (page.includes('?') ? '&' : '?') + 'lang=en';
    await s.naviguer(`${racine}/${url}`, { brut: true }); await s.attendre(PRET, 'page prête');
    await stabiliser(() => s.ev("document.querySelectorAll('#viewport .node, .vp-carte').length"), { pas: 120, max: 5000 });
    await s.attendre(POSEE, 'vue posée'); await pause(500); await s.ev(AIDES);
  };
  const aller = async (nom) => {
    await s.ev(`VF_ONGLETS.aller(${JSON.stringify(nom)}).then(() => 1)`); await s.attendre(PRET, 'onglet ' + nom);
    await s.attendre(POSEE, 'onglet posé'); await pause(500); await s.ev(AIDES);
  };
  // glisser : la carte la plus haute est amenée au centre de la zone du titre (départ sur un point libre du canevas)
  const glisser = async () => {
    const p = await lire(`JSON.stringify((() => { const z = __e.zone(),
      cs = [...document.querySelectorAll('#viewport g.node .card')].map((c) => c.getBoundingClientRect()).filter((b) => b.width > 0);
      if (!cs.length) return null; cs.sort((a, b) => a.top - b.top); const c = cs[0], st = document.getElementById('svg').getBoundingClientRect();
      const dx = z.x + z.w / 2 - (c.left + c.width / 2), dy = z.y + z.h / 2 - (c.top + c.height / 2); let dep = null;
      for (let y = st.bottom - 60; y > st.top + 200 && !dep; y -= 24) for (let x = st.left + 24; x < st.right - 24 && !dep; x += 24) {
        if (x + dx > 8 && x + dx < innerWidth - 8 && y + dy > 8 && document.elementsFromPoint(x, y)[0] === document.getElementById('svg')) dep = [x, y]; }
      return { dep, dx, dy }; })())`);
    if (!p || !p.dep) return false;
    const [x, y] = p.dep;
    await souris('mousePressed', x, y);
    for (let i = 1; i <= 8; i++) await souris('mouseMoved', x + p.dx * i / 8, y + p.dy * i / 8);
    await souris('mouseReleased', x + p.dx, y + p.dy); await pause(300);
    return true;
  };
  const MISE = '({ t: VibeFlow.state.t, fa: VibeFlow.freeArea() })';
  const coupe = async () => J('({ clip: getComputedStyle(document.getElementById("svg")).clipPath, inline: document.getElementById("svg").style.clipPath })');

  if (mode === 'en1') {
    const cas = [['code1440', 'index.html', 1440, 900], ['code800', 'index.html', 800, 900], ['code390', 'index.html', 390, 844], ['graphe1440',
      'project.html?vue=graphe', 1440, 900]];
    o.zone = {};
    for (const [cle, page, w, h] of cas) {
      await sec(cle, async () => {
        await charger(page, w, h); await touche('f'); await pause(700); const r = o.zone[cle] = {};
        r.mise = await J(MISE); r.pose = await glisser(); r.apres_glisser = await J('__e.sous()'); r.coupe = await coupe();
        await touche('+'); await pause(700); r.apres_zoom = await J('__e.sous()');
        r.texte = await J("document.querySelector('#context h1').textContent");
        r.flou = await J("getComputedStyle(document.getElementById('context'), '::before').backdropFilter");
      });
    }
    await sec('couloirs', async () => {
      o.vues = {};
      for (const vue of ['couloirs', 'liste']) { await charger(`project.html?vue=${vue}`, 1440, 900); o.vues[vue] = await coupe(); }
    });
    return o;
  }

  if (mode === 'en14') {
    o.bas = {};
    for (const [w, h, doigt] of [[390, 844, true], [800, 900, false]]) {
      await sec('en14-' + w, async () => {
        await charger('project.html?vue=couloirs', w, h, doigt);
        await s.ev("localStorage.removeItem('vf.terminal.open'); localStorage.removeItem('vf.terminal.h')");
        await s.ev("VibeFlow.select('n:ph-3')"); await pause(800);
        o.bas[w] = await J(`(() => { const R = (q, mots) => { const r = __e.rect(q); return r && (mots ? r.map(Math.round) : [Math.round(r[0]),
          Math.round(r[1]), Math.round(r[3])]); };
          return { ask: R('#ask', 1), zoom: R('#zoom', 1), past: R('.vf-term-pastille'), feuille: R('#panel', 1),
          bas: document.querySelector('section.vf-projet').style.getPropertyValue('--vf-bas')
            .replace(/^calc\\((\\d+)px/, (m, n) => 'calc(' + (${w} < 500 ? 'N' : n) + 'px') }; })()`);
      });
    }
    return o;
  }

  if (mode === 'en15') {
    await sec('en15', async () => {
      await charger('index.html', 1440, 900); const t0 = await s.ev('performance.timeOrigin');
      await aller('projet'); o.projet = await coupe(); await aller('code'); await touche('f'); await pause(700);
      o.origine = (await s.ev('performance.timeOrigin')) === t0; await glisser(); o.sous = await J('__e.sous()'); o.coupe = await coupe();
    });
    return o;
  }
  if (mode === 'en16') { // comptes vivants des observateurs de taille et des écouteurs resize / change posés par les deux fichiers
    const AMORCE = `(() => { const C = window.__cnt = { ens: { ro: new Set(), ec: new Set() }, rsp: { ro: new Set(), ec: new Set() } };
      const qui = () => { const st = new Error().stack || '';
        return st.includes('01-vf-ensemble.js') ? 'ens' : st.includes('01-vf-responsive.js') ? 'rsp' : null; };
      const A = EventTarget.prototype.addEventListener, R = EventTarget.prototype.removeEventListener;
      EventTarget.prototype.addEventListener = function (t, f, op) { const q = qui(); if (q && (t === 'resize' || t === 'change')) C[q].ec.add(f);
        return A.call(this, t, f, op); };
      EventTarget.prototype.removeEventListener = function (t, f, op) { C.ens.ec.delete(f); C.rsp.ec.delete(f); return R.call(this, t, f, op); };
      const RO = window.ResizeObserver;
      window.ResizeObserver = class extends RO {
        constructor(cb) { super(cb); this.__q = qui(); }
        observe(e, op) { if (this.__q) C[this.__q].ro.add(this); return super.observe(e, op); }
        disconnect() { if (this.__q) C[this.__q].ro.delete(this); return super.disconnect(); } }; })()`;
    await s.send('Page.addScriptToEvaluateOnNewDocument', { source: AMORCE });
    await sec('en16', async () => {
      const compte = () => J('({ ens: [__cnt.ens.ro.size, __cnt.ens.ec.size], rsp: [__cnt.rsp.ro.size, __cnt.rsp.ec.size] })');
      await charger('index.html', 1440, 900); o.froid = await compte();
      await aller('projet'); await aller('code'); o.apres1 = await compte();
      await aller('projet'); await aller('code'); o.apres2 = await compte();
    });
    return o;
  }
  const theme = (n) => s.ev(`document.documentElement.setAttribute('data-theme', '${n === 'clair' ? 'light' : 'dark'}')`);
  const GROUPES = `(() => { const hr = document.querySelector('header .hr'), V = __e.vis;
    const bt = [...hr.querySelectorAll('button')].filter((b) => V(b) && !b.closest('.menu')), gs = [...hr.querySelectorAll(':scope > [role=group]')].filter(V);
    const lib = (g) => document.getElementById(g.getAttribute('aria-labelledby'));
    return { groupes: gs.length, libs: gs.map((g) => (lib(g) ? lib(g).textContent.trim() : '')), libVisibles: gs.every((g) => lib(g) && V(lib(g))),
      ratios: gs.map((g) => lib(g) && __e.ratio(getComputedStyle(lib(g)).color, __e.jeton('--bg'))),
        taille: gs.map((g) => lib(g) && getComputedStyle(lib(g)).fontSize),
      sansGroupe: bt.filter((b) => !b.closest('[role=group]')).length, boutons: bt.length,
      deborde: document.querySelector('header').scrollWidth > document.querySelector('header').clientWidth + 1,
        dehors: bt.filter((b) => b.getBoundingClientRect().right > innerWidth + 0.5).length }; })()`;
  const ORDRE = `(() => { const hr = document.querySelector('header .hr'), V = __e.vis;
    const ids = [...hr.querySelectorAll('button')].filter((b) => !b.closest('.menu')).map((b) => b.id);
    const bt = [...hr.querySelectorAll('button')].filter((b) => V(b) && !b.closest('.menu')).map((b) => { const r = b.getBoundingClientRect();
      return [b.id, Math.round(r.left), Math.round(r.top), Math.round(r.width), Math.round(r.height)]; });
    return { ids, bt, groupes: hr.querySelectorAll('[role=group]').length, libs: [...hr.querySelectorAll('.vf-hdr-lib')].filter(V).length }; })()`;
  if (mode === 'en2') {
    o.g = {}; o.inv = {};
    for (const w of [1440, 1600]) {
      await sec('g' + w, async () => {
        await charger('index.html', w, 900); const r = o.g[w] = {};
        await pause(500); await theme('sombre'); r.code = await J(GROUPES); await theme('clair'); r.codeClair = await J(GROUPES); await theme('sombre');
        await aller('projet'); r.projet = await J(GROUPES); await aller('equipe'); r.equipe = await J(GROUPES);
      });
    }
    for (const w of [1279, 1100, 800, 390]) {
      await sec('inv' + w, async () => { await charger('index.html', w, 900, w < 500); await pause(400); o.inv[w] = await J(ORDRE); });
    }
    await sec('fr', async () => { await charger('index.html?lang=fr', 1440, 900); await pause(500); o.fr = await J(GROUPES); });
    await sec('retour', async () => {
      await charger('index.html', 1440, 900); await pause(500); o.avantRetour = await J(GROUPES);
      await s.send('Emulation.setDeviceMetricsOverride', { width: 1100, height: 900, deviceScaleFactor: 1, mobile: false }); await pause(900);
        o.retour = await J(ORDRE);
    });
    await sec('chevron', async () => {
      o.chev = {};
      for (const w of [1440, 800, 390]) {
        await charger('index.html', w, 900, w < 500); await s.ev("VibeFlow.reveal('f:src/m1.js')"); await pause(900);
        o.chev[w] = await J(`(() => { const sp = [...document.querySelectorAll('#crumbs .sep')], h = document.querySelector('header');
          return { n: sp.length, svg: sp.every((e) => { const v = e.querySelector('svg'); return !!v && v.getAttribute('aria-hidden') === 'true'; }),
            texte: sp.map((e) => e.textContent.trim()).join(''), deborde: h.scrollWidth > h.clientWidth + 1 }; })()`);
      }
    });
    await sec('icones', async () => {
      await charger('index.html', 1100, 900); await pause(500);
      o.icones = await J(`({ flows: document.querySelector('#flows-btn svg path').getAttribute('d'),
        recent: document.querySelector('#btn-recent svg path').getAttribute('d') })`);
      const point = `(() => { const b = document.getElementById('vf-lock'), d = b.querySelector('.dot'), c = getComputedStyle(d),
        l = b.querySelector('.bl'), g = document.querySelector('.vf-git-ligne');
        return { clip: c.clipPath.slice(0, 5), w: Math.round(d.getBoundingClientRect().width), bl: getComputedStyle(l).display,
          ligne: g ? getComputedStyle(g).maxWidth : null,
          nom: getComputedStyle(document.querySelector('.vf-nom #proj-name')).maxWidth }; })()`;
      o.point1100 = await J(point);
      await charger('index.html', 1700, 900); await pause(500); o.point1700 = await J(point);
    });
    await sec('sante', async () => {
      await charger('index.html', 1440, 900); await pause(600); const R = {};
      await s.ev("document.getElementById('btn-health').focus(); document.getElementById('btn-health').click()"); await pause(700);
      R.ouvert = await s.ev("!document.body.classList.contains('no-panel')");
      await touche('Escape'); await pause(500); R.focus = await s.ev('document.activeElement && document.activeElement.id');
      await s.ev("document.getElementById('flows-btn').click()"); await pause(500);
      R.menu = await J(`(() => { const b = document.getElementById('flows-btn').getBoundingClientRect(), m = document.getElementById('flowmenu');
        return [m.classList.contains('open'), m.getBoundingClientRect().top >= b.bottom - 0.5]; })()`);
      await touche('Escape'); await pause(400);
      R.ferme = await s.ev("!document.getElementById('flowmenu').classList.contains('open')");
      o.sante = R;
    });
    return o;
  }

  if (mode === 'en3') {
    const OUVREUR = `(() => { const o = document.getElementById('vf-git-ouvreur'), r = o.getBoundingClientRect(), V = __e.vis;
      const v = [...document.querySelectorAll('header .hr .btn')].find((b) => b.id !== 'vf-git-ouvreur' && V(b)), vr = v.getBoundingClientRect(),
        cx = r.left + r.width / 2, cy = r.top + r.height / 2;
      const pts = [[-21, 0], [21, 0], [0, -21], [0, 21], [0, 0]].map(([a, b]) => { const e = document.elementFromPoint(cx + a, cy + b);
        return !!e && (e === o || o.contains(e)); });
      return { w: Math.round(r.width), h: Math.round(r.height), voisin: Math.round(vr.height), pts, premier: o.parentElement.firstElementChild === o,
        ordre: Math.round(r.left) < Math.round(vr.left) }; })()`;
    o.o = {};
    for (const [w, doigt] of [[800, false], [1100, false], [1279, false], [1100, true], [1279, true]]) {
      await sec(`o${w}${doigt ? 't' : ''}`, async () => { await charger('index.html', w, 900, doigt); await pause(500);
        o.o[`${w}${doigt ? 't' : ''}`] = await J(OUVREUR); });
    }
    await sec('anim', async () => {
      await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
      await charger('index.html', 1440, 900); await touche('f'); await pause(500); await glisser(); await touche('+'); await pause(700);
        o.actives = [await J('__e.actives()')];
      await s.send('Emulation.setDeviceMetricsOverride', { width: 1100, height: 900, deviceScaleFactor: 1, mobile: false }); await pause(900);
        o.actives.push(await J('__e.actives()'));
      await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'no-preference' }] });
    });
    return o;
  }

  return o;
});
