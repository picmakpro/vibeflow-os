// chrome-zoom-garde.mjs — cadrage unique, zoom centré, garde de saisie, idiome A51 du clavier du canevas (80-09), un vrai Chrome, sans réseau.
// Usage : node chrome-zoom-garde.mjs <chrome> <racine-du-serveur> <mode>
//   Rend UNE ligne JSON { zg1 … zg5 } ou { erreur }. Modes : base · term (lab --terminal).
// Chaque section est isolée (sec) : une section qui échoue laisse ses champs vides, les autres sont mesurées. Les gestes passent par Input.dispatchKeyEvent.
import { executer, pause, stabiliser } from './chrome-session.mjs';
const [, , chrome, racine, mode] = process.argv;
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
const POSEE = "(() => { const v = document.querySelector('#viewport'); return !!v && v.style.opacity !== '0' && !v.classList.contains('anim'); })()";
const OUTIL = `window.__zg = {
  centre(id) { const g = VibeFlow.state.chipEls.get(id), c = g && g.querySelector('.card'); if (!c) return null;
    const b = c.getBoundingClientRect(); return [b.x + b.width / 2, b.y + b.height / 2]; },
  rect(s) { const e = typeof s === 'string' ? document.querySelector(s) : s; if (!e || !e.getClientRects().length) return null;
    const b = e.getBoundingClientRect(); return { l: b.left, t: b.top, r: b.right, b: b.bottom }; },
  coupe(a, b) { return !(a.r <= b.l || b.r <= a.l || a.b <= b.t || b.b <= a.t); },
  champ() { const f = window.VF_CANEVAS && VF_CANEVAS.champsDeCadrage ? [].concat(VF_CANEVAS.champsDeCadrage()) : [VibeFlow.freeArea()];
    return f.sort((p, q) => q.w * q.h - p.w * p.h)[0]; },
  monde(px, py) { const t = VibeFlow.state.t; return [(px - t.x) / t.k, (py - t.y) / t.k]; },
  premiere() { return VibeFlow.state.layout.children.slice().sort((a, b) => a.y - b.y || a.x - b.x)[0].id; },
  actives() { return document.getAnimations().filter((a) => a.playState === 'running' || a.playState === 'pending').length; } }`;
const KEYS = { f: ['KeyF', 70], p: ['KeyP', 80], '+': ['Equal', 187], '-': ['Minus', 189], Backspace: ['Backspace', 8], Escape: ['Escape', 27] };
const proche = (a, b, e) => !!a && !!b && a.every((v, i) => Math.abs(v - b[i]) <= e);

await executer(chrome, async (s) => {
  const o = { erreurs: {}, zg1: {}, zg2: {}, zg3: {}, zg4: {}, zg5: {} };
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  const sec = async (nom, f) => { try { await f(); } catch (e) { o.erreurs[nom] = String(e.message).slice(0, 160); } };
  const lire = async (expr) => { const v = await s.ev(expr); return v === undefined ? null : JSON.parse(v); };
  const vue = (w, h, mobile) => s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile });
  const touche = async (key, mod = 0) => {
    const [code, vk] = KEYS[key], text = key.length === 1 && !mod ? key : undefined;
    for (const type of ['keyDown', 'keyUp']) {
      const e = { type, key, code, text: type === 'keyDown' ? text : undefined, modifiers: mod, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk };
      await s.send('Input.dispatchKeyEvent', e);
    }
  };
  const lireVue = () => s.ev('JSON.stringify([VibeFlow.state.container, document.querySelectorAll("#viewport .node").length])');
  const posee = async () => {
    await s.attendre(POSEE, 'vue posée'); await stabiliser(() => s.ev('JSON.stringify(VibeFlow.state.t)'), { pas: 150, max: 4000 });
  };
  const T = () => lire('JSON.stringify(VibeFlow.state.t)');
  const sansVisite = async () => {
    await pause(1200); // la visite guidée du premier passage démarre après le chargement : Échap jusqu'à sa fermeture
    for (let i = 0; i < 5 && await s.ev('!!(window.VibeFlowTour && VibeFlowTour.active())'); i++) { await touche('Escape'); await pause(400); }
    await s.ev(OUTIL);
  };
  const charger = async (page, w = 1440, h = 900, mobile = false) => {
    await vue(w, h, mobile); await s.naviguer(`${racine}/${page}${page.includes('?') ? '&' : '?'}lang=en`);
    if (mode === 'term') { // le tiroir du terminal se rouvre d'une page à l'autre (stockage) : chaque page part tiroir fermé
      await s.ev("localStorage.removeItem('vf.terminal.open'); localStorage.removeItem('vf.terminal.h')"); await s.naviguer(`${racine}/${page}?lang=en`);
    }
    await s.attendre(PRET, `page ${page}`); await s.attendre("!!document.querySelector('#viewport .node')", `cartes ${page}`);
    await s.attendre(POSEE, `vue posée ${page}`); await stabiliser(lireVue, { pas: 120, max: 5000 }); await sansVisite();
  };
  const gros = async () => { // le niveau de 70 notes
    await s.ev("VibeFlow.reveal('f:lots/n05.md')");
    await s.attendre("VibeFlow.state.container !== 'root' && document.querySelectorAll('#viewport .node').length >= 70", 'niveau de 70 notes');
    await stabiliser(lireVue, { pas: 120, max: 5000 }); await s.ev('VibeFlow.fit(false)'); await posee();
  };
  const onglet = async (nom) => {
    await s.ev(`VF_COQUILLE.chargerOnglet(${JSON.stringify(nom)})`); await s.attendre(PRET, `onglet ${nom}`);
    await s.attendre(POSEE, `onglet ${nom} posé`); await stabiliser(lireVue, { pas: 120, max: 5000 }); await s.ev(OUTIL);
  };
  const kFit = "(() => { const a = VibeFlow.freeArea(), b = VibeFlow.state.bounds; return Math.min(a.w / (b.w + 40), a.h / (b.h + 20), 1.1); })()";
  const KF = `(typeof VibeFlow.cadrage === 'function' ? VibeFlow.cadrage({ plancher: false }).k : ${kFit})`;

  if (mode === 'term') { // ZG2.4 : zone basse à 390 et 800 px, feuille ouverte puis fermée, pastille « Terminal » comprise
    const cas = [['tactile', 390, 844, true], ['moyen', 800, 900, false]];
    for (const [cle, w, h, doigt] of cas) {
      await sec('zg24', async () => {
        await s.send('Emulation.setTouchEmulationEnabled', { enabled: doigt }); await charger('index.html', w, h, doigt); await gros();
        const r = o.zg2[cle] = {};
        for (const ouverte of [true, false]) {
          await s.ev(`(() => { if (document.body.classList.contains('no-panel') === ${ouverte}) document.getElementById('btn-panel').click(); })()`);
          await s.attendre(`document.body.classList.contains('no-panel') === ${!ouverte}`, 'feuille'); await pause(600);
          await s.ev('VibeFlow.select(__zg.premiere())'); await s.ev('VF_CANEVAS.amenerDansLeChamp(VibeFlow.state.selected)'); await posee();
          const id = await s.ev('VibeFlow.state.selected'), q = (x) => lire(`JSON.stringify(${x})`);
          // au téléphone #zoom est une colonne à gauche DANS la zone libre (freeArea ne la déduit pas) : hors du contrat de ce plan
          const L = ['#ask', doigt ? null : '#zoom', '.vf-term-pastille', ouverte ? '#panel' : null].filter(Boolean);
          const dis = () => q(`(() => { const L = ${JSON.stringify(L)};
            const c = __zg.rect(VibeFlow.state.chipEls.get(${JSON.stringify(id)}).querySelector('.card'));
            return L.map((x) => [x, __zg.rect(x)]).filter((p) => p[1] && __zg.coupe(c, p[1])).map((p) => p[0]); })()`);
          const c0 = await q(`__zg.centre(${JSON.stringify(id)})`), d0 = await dis();
          const cc = () => q(`__zg.centre(${JSON.stringify(id)})`);
          await touche('+'); const c1 = await cc(); await touche('-'); const c2 = await cc();
          const d2 = await dis(), t0 = await T();
          await s.ev('VibeFlow.select(null)'); const ch = await q('__zg.champ()'), m0 = await q(`__zg.monde(${ch.x + ch.w / 2}, ${ch.y + ch.h / 2})`);
          await touche('+'); const m1 = await q(`__zg.monde(${ch.x + ch.w / 2}, ${ch.y + ch.h / 2})`); await touche('-');
          r[ouverte ? 'ouverte' : 'fermee'] = { pastille: !!(await q("__zg.rect('.vf-term-pastille')")), fixe: proche(c0, c1, 0.5) && proche(c2, c0, 0.5),
            libre: d0.length === 0 && d2.length === 0, touche: [d0, d2], centre: proche(m0, m1, 0.5), retour: Math.abs((await T()).k - t0.k) <= 1e-6 };
        }
      });
    }
    await s.send('Emulation.setTouchEmulationEnabled', { enabled: false }); return o;
  }

  await sec('zg1', async () => { // cadrage unique : « f » = VibeFlow.cadrage(), plancher 11/13, #vf-coin évité, tiroir Git sans effet
    await charger('index.html'); await gros(); await touche('f'); await posee();
    const c = await lire(`JSON.stringify({ fn: typeof VibeFlow.cadrage, t: VibeFlow.state.t,
      c: typeof VibeFlow.cadrage === 'function' ? VibeFlow.cadrage() : null })`);
    o.zg1.a = { fn: c.fn, egal: !!c.c && proche([c.t.k, c.t.x, c.t.y], [c.c.k, c.c.x, c.c.y], 1e-6), plancher: c.t.k >= 11 / 13 - 1e-9 };
    o.zg1.coin = await lire(`JSON.stringify((() => { const k = __zg.rect('#vf-coin'); if (!k) return { coin: false };
      const o = document.getElementById('svg').getBoundingClientRect(); // une carte ENTIÈRE dans le champ de lecture (un candidat) ne passe jamais sous le coin
      const champs = (window.VF_CANEVAS && VF_CANEVAS.champsDeCadrage ? [].concat(VF_CANEVAS.champsDeCadrage()) : [VibeFlow.freeArea()])
        .map((a) => ({ l: o.left + a.x, t: o.top + a.y, r: o.left + a.x + a.w, b: o.top + a.y + a.h }));
      const v = [...document.querySelectorAll('#viewport g.node .card')].map(__zg.rect)
        .filter((r) => r && champs.some((a) => r.l >= a.l && r.t >= a.t && r.r <= a.r && r.b <= a.b));
      return { coin: true, entieres: v.length, touchent: v.filter((r) => __zg.coupe(r, k)).length }; })())`);
    const av = await lire('JSON.stringify({ t: VibeFlow.state.t, w: VibeFlow.freeArea().w })');
    await s.ev('VFGitTiroir.ouvrir()'); await s.attendre('VFGitTiroir.ouvert()', 'tiroir Git'); await pause(500);
    const ou = await lire('JSON.stringify({ t: VibeFlow.state.t, w: VibeFlow.freeArea().w })');
    await s.ev('VFGitTiroir.fermer()'); await pause(500);
    const fe = await lire('JSON.stringify({ t: VibeFlow.state.t, w: VibeFlow.freeArea().w })');
    o.zg1.tiroir = JSON.stringify(av) === JSON.stringify(ou) && JSON.stringify(av) === JSON.stringify(fe);
  });
  await sec('zg14', async () => { // la coquille ré-exécute le moteur et le fichier : le premier rendu est déjà cadré, un seul fournisseur
    await charger('index.html'); await touche('f'); await posee(); const t0 = await T();
    await onglet('projet'); await onglet('code'); await s.attendre(POSEE, 'posée'); const t1 = await T();
    const c = await lire(`JSON.stringify(typeof VibeFlow.cadrage === 'function' ? VibeFlow.cadrage() : null)`);
    await touche('f'); await posee(); const t2 = await T();
    const n = await lire(`JSON.stringify((() => {
      if (typeof VibeFlow.setReadingArea !== 'function' || !window.VF_CANEVAS || !VF_CANEVAS.champsDeCadrage) return null;
      const vrai = VF_CANEVAS.champsDeCadrage; let n = 0; VibeFlow.setReadingArea(() => { n++; return vrai(); });
      VibeFlow.cadrage(); const a = n; VibeFlow.fit(false); return [a, n - a]; })())`);
    o.zg1.rt = { premier: !!c && proche([t1.k, t1.x, t1.y], [c.k, c.x, c.y], 1e-6), f: proche([t2.k, t2.x, t2.y], [t0.k, t0.x, t0.y], 1e-6), appels: n };
  });
  await sec('zg15', async () => { // plancher choisi sur l'onglet chargé, jamais sur l'adresse : Code sous /project.html, Projet sous /
    const sans = "(() => { const C = window.VF_COQUILLE; window.__c0 = C; window.VF_COQUILLE = Object.freeze({ ...C, onglet: undefined }); })()";
    const k = async () => lire(`JSON.stringify({ k: VibeFlow.state.t.k, kfit: ${KF}, chemin: location.pathname,
      onglet: window.VF_COQUILLE.onglet ? VF_COQUILLE.onglet() : null })`);
    await charger('project.html'); await onglet('code'); await gros(); await touche('f'); await posee();
    const a1 = await k(); await s.ev(sans); await touche('f'); await posee(); const a2 = await k(); await s.ev('window.VF_COQUILLE = window.__c0');
    o.zg1.a1 = [a1, a2].map((x) => ({ chemin: x.chemin, plafonne: x.k >= 11 / 13 - 1e-9, bas: x.kfit < 11 / 13 }));
    await charger('', 900, 520); await onglet('projet');
    await s.ev("VF_PROJET.basculer('graphe', { memoriser: false })"); await s.attendre(POSEE, 'forme graphe'); await touche('f'); await posee();
    const b1 = await k(); await s.ev(sans); await touche('f'); await posee(); const b2 = await k(); await s.ev('window.VF_COQUILLE = window.__c0');
    o.zg1.b1 = [b1, b2].map((x) => ({ chemin: x.chemin, libre: Math.abs(x.k - x.kfit) <= 1e-6, bas: x.kfit < 11 / 13, onglet: x.onglet }));
    o.zg1.b1trace = [b1, b2];
  });

  await sec('zg2', async () => { // zoom centré et réversible
    await charger('index.html'); await gros();
    const id = await s.ev('__zg.premiere()'); await s.ev(`VibeFlow.select(${JSON.stringify(id)})`);
    await s.ev(`VF_CANEVAS.amenerDansLeChamp(${JSON.stringify(id)})`); await posee();
    const t0 = await T(), c0 = await lire(`JSON.stringify(__zg.centre(${JSON.stringify(id)}))`);
    await touche('+'); const t1 = await T(), c1 = await lire(`JSON.stringify(__zg.centre(${JSON.stringify(id)}))`);
    await touche('-'); const t2 = await T();
    o.zg2.a = { retour: proche([t0.k, t0.x, t0.y], [t2.k, t2.x, t2.y], 1e-6), facteur: Math.abs(t1.k / t0.k - 1.25) < 1e-9, fixe: proche(c0, c1, 0.5) };
    await s.ev('VibeFlow.select(null)'); const ch = await lire('JSON.stringify(__zg.champ())'), px = ch.x + ch.w / 2, py = ch.y + ch.h / 2;
    const mo = () => lire(`JSON.stringify(__zg.monde(${px}, ${py}))`);
    const m0 = await mo(); await touche('+'); const m1 = await mo(); await touche('-');
    await s.ev("document.getElementById('z-in').click()"); const t3 = await T(), m2 = await mo();
    await s.ev("document.getElementById('z-out').click()"); const t4 = await T();
    const retour = proche([t0.k, t0.x, t0.y], [t4.k, t4.x, t4.y], 1e-6);
    o.zg2.b = { touches: proche(m0, m1, 0.5), boutons: proche(m0, m2, 0.5) && Math.abs(t3.k / t0.k - 1.25) < 1e-9, retour };
  });
  await sec('zg3', async () => { // garde de saisie : aucun raccourci depuis un champ, ni avec ⌘, Ctrl, Alt
    await charger('index.html'); await gros();
    const ETAT = 'JSON.stringify({ t: VibeFlow.state.t, c: VibeFlow.state.container, p: document.body.classList.contains("no-panel") })';
    const CHAMPS = { textarea: "document.createElement('textarea')",
      select: "(() => { const e = document.createElement('select'); e.innerHTML = '<option>a</option><option>b</option>'; return e; })()",
      editable: "(() => { const e = document.createElement('div'); e.contentEditable = 'true'; e.style.minHeight = '20px'; return e; })()" };
    o.zg3.champs = {};
    for (const [nom, fab] of Object.entries(CHAMPS)) {
      await s.ev(`(() => { const e = ${fab}; e.id = 'zg-champ'; document.body.appendChild(e);
        e.style.cssText += ';position:fixed;left:8px;top:8px;z-index:99;background:#fff;color:#000'; e.focus(); })()`);
      const avant = await s.ev(ETAT); for (const k of ['f', 'p', '+', 'Backspace']) await touche(k);
      const apres = await s.ev(ETAT), texte = await s.ev("(() => { const e = document.getElementById('zg-champ'); return e.value ?? e.textContent; })()");
      o.zg3.champs[nom] = { inchange: avant === apres, texte };
      await s.ev("document.getElementById('zg-champ').remove()");
    }
    await s.ev('document.activeElement && document.activeElement.blur()'); const av = await s.ev(ETAT);
    await touche('p', 2); await touche('f', 1); await touche('f', 4); o.zg3.modif = av === await s.ev(ETAT);
    o.zg3.fn = await lire(`JSON.stringify(typeof VibeFlow.enSaisie === 'function' ? [
      document.createElement('input'), document.createElement('textarea'), document.createElement('select'),
      Object.assign(document.createElement('div'), { contentEditable: 'true' }), document.createElement('div')
    ].map((e) => VibeFlow.enSaisie({ target: e })) : null)`);
  });
  await sec('zg4', async () => { // mouvement réduit : aucune animation neuve
    await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
    await charger('index.html'); await gros(); o.zg4.reduit = await s.ev("matchMedia('(prefers-reduced-motion: reduce)').matches"); o.zg4.actives = [];
    for (const k of ['+', '-', 'f']) { await touche(k); o.zg4.actives.push(await s.ev('__zg.actives()')); }
    await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'no-preference' }] });
  });
  await sec('zg5', async () => { // A51 : un seul écouteur de document du clavier du canevas, après deux allers-retours d'onglet
    const AMORCE = `(() => { const A = EventTarget.prototype.addEventListener, R = EventTarget.prototype.removeEventListener; window.__ec = new Set();
      const mien = (t, c, f) => c === document && t === 'pointerdown' && typeof f === 'function' && String(f).includes('focusDans');
      EventTarget.prototype.addEventListener = function (t, f, op) { if (mien(t, this, f)) window.__ec.add(f); return A.call(this, t, f, op); };
      EventTarget.prototype.removeEventListener = function (t, f, op) { if (mien(t, this, f)) window.__ec.delete(f); return R.call(this, t, f, op); }; })()`;
    await s.send('Page.addScriptToEvaluateOnNewDocument', { source: AMORCE });
    await charger('index.html'); const n = [await s.ev('window.__ec.size')];
    await onglet('projet'); n.push(await s.ev('window.__ec.size')); await onglet('code'); n.push(await s.ev('window.__ec.size'));
    await onglet('projet'); await onglet('code'); n.push(await s.ev('window.__ec.size')); o.zg5.actifs = n;
  });
  return o;
});
