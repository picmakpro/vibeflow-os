// chrome-entete.mjs — mesures en rendu du titre de vue et de l'en-tête (80-20, FORM-18, P80-D-52, P80-D-53, P80-D-56), un vrai Chrome headless.
// Usage : node chrome-entete.mjs <chrome> <racine-du-serveur> <mode>   Rend UNE ligne JSON { … } ou { erreur }. Modes :
//   en1  : zone du titre (Code à 1440, 800, 390 px, graphe de Projet à 1440) : cartes sous #context après un glisser puis « + » ; mise en page ; couloirs et liste
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
    const b = e.getBoundingClientRect(); return [Math.round(b.left * 100) / 100, Math.round(b.top * 100) / 100, Math.round(b.right * 100) / 100, Math.round(b.bottom * 100) / 100]; };
  const zone = () => { const c = document.getElementById('context'), b = c.getBoundingClientRect();
    return { x: b.left, y: b.top, w: b.width, h: Math.min(130, b.height), brut: b.height }; };
  const sous = () => { const z = zone(); let n = 0, total = 0;
    for (let i = 0; i < 8; i++) for (let j = 0; j < 4; j++) { total++;
      const x = z.x + z.w * (i + 0.5) / 8, y = z.y + z.h * (j + 0.5) / 4;
      if (document.elementsFromPoint(x, y).some((e) => e.matches('.card, g.node') || (e.closest && e.closest('g.node')))) n++; }
    return { n, total, h: z.h }; };
  const actives = () => document.getAnimations().filter((a) => a.playState === 'running' || a.playState === 'pending').length;
  return { rect, zone, sous, actives };
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
      await s.send('Input.dispatchKeyEvent', { type, key, code, text: type === 'keyDown' ? text : undefined, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk });
    }
  };
  const souris = (type, x, y) => s.send('Input.dispatchMouseEvent', { type, x, y, button: type === 'mouseMoved' ? 'none' : 'left', buttons: type === 'mouseReleased' ? 0 : 1, clickCount: 1 });
  const charger = async (page, w, h, tactile = false) => {
    await s.send('Emulation.setTouchEmulationEnabled', { enabled: tactile });
    await s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: tactile });
    const sep = page.includes('?') ? '&' : '?';
    await s.naviguer(`${racine}/${page}${sep}lang=en`, { brut: true }); await s.attendre(PRET, 'page prête');
    await stabiliser(() => s.ev("document.querySelectorAll('#viewport .node, .vp-carte').length"), { pas: 120, max: 5000 });
    await s.attendre(POSEE, 'vue posée'); await pause(500); await s.ev(AIDES);
  };
  const aller = async (nom) => {
    await s.ev(`VF_ONGLETS.aller(${JSON.stringify(nom)}).then(() => 1)`); await s.attendre(PRET, 'onglet ' + nom);
    await s.attendre(POSEE, 'onglet posé'); await pause(500); await s.ev(AIDES);
  };
  // glisser : la carte la plus haute est amenée au centre de la zone du titre (départ sur un point libre du canevas)
  const glisser = async () => {
    const p = await lire(`JSON.stringify((() => { const z = __e.zone(), cs = [...document.querySelectorAll('#viewport g.node .card')].map((c) => c.getBoundingClientRect()).filter((b) => b.width > 0);
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
    const cas = [['code1440', 'index.html', 1440, 900], ['code800', 'index.html', 800, 900], ['code390', 'index.html', 390, 844], ['graphe1440', 'project.html?vue=graphe', 1440, 900]];
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
        o.bas[w] = await J(`(() => { const R = (q, mots) => { const r = __e.rect(q); return r && (mots ? r.map(Math.round) : [Math.round(r[0]), Math.round(r[1]), Math.round(r[3])]); };
          return { ask: R('#ask', 1), zoom: R('#zoom', 1), past: R('.vf-term-pastille'), feuille: R('#panel', 1),
          bas: document.querySelector('section.vf-projet').style.getPropertyValue('--vf-bas').replace(/^calc\\((\\d+)px/, (m, n) => 'calc(' + Math.round(n / 16) * 16 + 'px') }; })()`);
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
      const qui = () => { const st = new Error().stack || ''; return st.includes('01-vf-ensemble.js') ? 'ens' : st.includes('01-vf-responsive.js') ? 'rsp' : null; };
      const A = EventTarget.prototype.addEventListener, R = EventTarget.prototype.removeEventListener;
      EventTarget.prototype.addEventListener = function (t, f, op) { const q = qui(); if (q && (t === 'resize' || t === 'change')) C[q].ec.add(f); return A.call(this, t, f, op); };
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
  return o;
});
