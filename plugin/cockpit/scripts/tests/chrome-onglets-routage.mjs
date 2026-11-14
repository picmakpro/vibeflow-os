// chrome-onglets-routage.mjs — mesures du routage des onglets sans rechargement (80-10, FORM-16) dans un vrai Chrome headless (vrais clics).
// Usage : node chrome-onglets-routage.mjs <chrome> <racine-du-serveur> <mode> <fichier-00-vf-onglets.js> [filtre]   Rend UNE ligne JSON { … } ou { erreur }.
// Modes : og1 (OG1.x, OG2.8), og2 (OG2.1, OG2.3 à OG2.7, OG2.9 à OG2.12), og3 (OG3.x), og2t (OG2.2, lab lancé avec --terminal).
// Aucune absence de rechargement n'est lue sur une marque posée dans window (la portée d'onglet la retirerait) : performance.timeOrigin et les
// évènements Page.loadEventFired du protocole. Les instruments (compteurs, échec forcé de GET /api/vf/graphe) sont posés avant la page, dans __o.
import fs from 'node:fs';
import vm from 'node:vm';
import { executer, pause, stabiliser } from './chrome-session.mjs';
const [, , chrome, racine, mode, fichier, filtre] = process.argv;
const SEL = filtre ? new Set(filtre.split(',')) : null;
const AMORCE = `(() => { const A = window.__o = { pop: 0, push: 0, repl: 0, fetchs: [], directs: 0, evs: [], rej: 0, echec: 0, cerr: [] };
  const ce = console.error; console.error = function (...a) { A.cerr.push(String(a[0]).slice(0, 120)); return ce.apply(this, a); };
  const ael = EventTarget.prototype.addEventListener;
  EventTarget.prototype.addEventListener = function (t, ...r) {
    if (t === 'popstate' && /00-vf-onglets/.test(new Error().stack)) A.pop++; return ael.call(this, t, ...r); };
  for (const k of ['pushState', 'replaceState']) { const o = History.prototype[k];
    History.prototype[k] = function (...a) { A[k === 'pushState' ? 'push' : 'repl']++; return o.apply(this, a); }; }
  const f = window.fetch;
  window.fetch = function (u, ...r) { if (String(u).includes('/api/vf/graphe')) { A.fetchs.push(String(u));
    if (/00-vf-onglets/.test(new Error().stack)) A.directs++;
    if (A.echec) return Promise.reject(new TypeError('forcé')); } return f.call(this, u, ...r); };
  addEventListener('unhandledrejection', () => A.rej++);
  document.addEventListener('vf:onglet', (e) => A.evs.push(e.detail.onglet + '<' + e.detail.precedent)); })()`;
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) {"
  + " const vue = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0);"
  + " return vue ? 'true' : g.call(this, k); }; })()";
const ETAT = `({ p: location.pathname, h: location.hash, n: history.length, t: document.title, o: performance.timeOrigin,
  pret: document.documentElement.dataset.vfPret, evs: __o.evs.length, last: __o.evs[__o.evs.length - 1] || null, push: __o.push, repl: __o.repl,
  fetchs: __o.fetchs.length, rej: __o.rej, directs: __o.directs, sel: VibeFlow.state.selected, cont: VibeFlow.state.container, tk: VibeFlow.state.t,
  git: (document.querySelector('#vf-git-ligne') || { getAttribute: () => null }).getAttribute('aria-expanded'),
  live: (document.querySelector('.vp-status') || document.getElementById('ask-live') || {}).textContent || '', ae: (() => { const a = document.activeElement;
    return !a ? null : a === document.body ? 'body' : a.id || (a.dataset && a.dataset.id) || (a.closest && a.closest('svg') ? 'carte' : a.tagName); })() })`;
const TAB = { code: 'index.html', projet: 'project.html', equipe: 'equipe.html' };

function evalIsolee() { // OG2.9 : le fichier évalué deux fois dans un contexte vide : rien d'autre que les trois poses de l'évaluation
  const src = fs.readFileSync(fichier, 'utf8'), c = { pop: 0, sur: [], charger: 0, lectures: [] }, w = { VF_COQUILLE: {
    chargerOnglet: () => { c.charger++; return Promise.resolve(); }, surOnglet: (f, o) => { c.sur.push(o && o.cle); return () => {}; }, onglet: () => null },
  addEventListener: (t) => { if (t === 'popstate') c.pop++; } };
  for (const k of ['Floorplan', 'VibeFlow']) Object.defineProperty(w, k, { get() { c.lectures.push(k); return undefined; } });
  w.window = w; const ctx = vm.createContext(w); vm.runInContext(src, ctx); const un = w.VF_ONGLETS; vm.runInContext(src, ctx);
  return { pop: c.pop, sur: c.sur, charger: c.charger, lectures: c.lectures, un: !!un && un === w.VF_ONGLETS,
    marqueur: src.split('\n').slice(0, 8).some((l) => l.includes('vf-coquille: persistant')) };
}

await executer(chrome, async (s) => {
  const o = { erreurs: {} }; let loads = 0;
  s.ecouter('Page.loadEventFired', () => { loads++; });
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: SANS_VISITE });
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: AMORCE });
  const sec = async (nom, f) => { if (SEL && !SEL.has(nom)) return; try { await f(); } catch (e) { o.erreurs[nom] = String(e.message).slice(0, 200); } };
  const lire = async (expr) => { const v = await s.ev(`JSON.stringify(${expr})`); return v === undefined ? null : JSON.parse(v); };
  const etat = () => lire(ETAT);
  const charger = async (chemin) => {
    await s.naviguer(`${racine}${chemin}`, { brut: true }); loads = 0; await s.attendre('!!window.VF_ONGLETS', 'VF_ONGLETS'); await pause(300); };
  const clic = async (sel) => {
    const r = await lire(`(() => { const e = document.querySelector(${JSON.stringify(sel)}); if (!e) return null; e.scrollIntoView({ block: 'nearest' });
      const b = e.getBoundingClientRect(); return { x: b.x + b.width / 2, y: b.y + b.height / 2 }; })()`);
    if (!r) throw new Error(`clic : « ${sel} » absent`);
    await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: r.x, y: r.y });
    for (const type of ['mousePressed', 'mouseReleased']) await s.send('Input.dispatchMouseEvent', { type, x: r.x, y: r.y, button: 'left', clickCount: 1 });
  };
  const arrivee = async (n, nom) => {
    await s.attendre(`__o.evs.length >= ${n}`, `vf:onglet n° ${n} (${nom})`, 15000); return stabiliser(etat, { pas: 200, max: 4000 }); };
  const onglet = async (nom, n) => { await clic(`nav.vf-tabs a[href="${TAB[nom]}"]`); return arrivee(n, nom); };
  const rien = async (ms = 600) => { await pause(ms); return etat(); }; // une absence ne se prouve que par la durée
  const retour = async (cmd, n) => { await s.ev(cmd); return arrivee(n, cmd); };
  const premier = () => lire(`(() => { const c = VibeFlow.children('root'); return c.find((x) => !x.startsWith('x:')) || null; })()`);
  const noms = () => lire('VibeFlow.children("root").length');

  if (mode === 'og1') {
    await sec('og1', async () => {
      await charger('/'); const e0 = await etat(); o.l0 = loads; o.og1 = { e0 };
      const e1 = await onglet('projet', 1);
      o.og1.e1 = { ...e1, loads, origine: e1.o === e0.o, forme: await lire('window.VF_PROJET ? VF_PROJET.forme() : null') };
      const e2 = await retour('history.back()', 2); o.og1.e2 = { ...e2, loads, origine: e2.o === e0.o };
      const e3 = await onglet('projet', 3); o.og1.e3 = { ...e3, origine: e3.o === e0.o };
      const e4 = await onglet('code', 4); o.og1.e4 = { ...e4, origine: e4.o === e0.o };
      o.og28 = { pop: await lire('__o.pop'), nb: e4.evs };
    });
  }

  if (mode === 'og2') {
    await sec('og29', async () => { o.og29 = evalIsolee(); });
    await sec('og21', async () => {
      await charger('/'); await s.ev(`window.__o.id = window.VF_ONGLETS`); const id = await premier(); o.og21 = { id, nbRoot: await noms() };
      await s.ev(`document.querySelector('#vf-git-ligne') && document.querySelector('#vf-git-ligne').click()`); await pause(500);
      await s.ev(`VibeFlow.select(${JSON.stringify(id)}); VibeFlow.transformer({ k: 0.5, x: 11, y: 23 })`); await pause(300);
      const av = await etat(); await onglet('projet', 1); const mid = await etat(); const ap = await onglet('code', 2);
      o.og21 = { ...o.og21, av: [av.git, av.sel, av.tk], mid: mid.git, ap: [ap.git, ap.sel, ap.tk], ident: await lire('window.__o.id === window.VF_ONGLETS') };
      o.og23 = await lire(`({ tabs: [...document.querySelectorAll('#viewport [tabindex="0"]')].length, coin: !!document.getElementById('vf-coin'),
        taille: window.VF_PANNEAU ? VF_PANNEAU.taille() : null })`);
    });
    await sec('og23', async () => {
      await onglet('projet', 3); await s.attendre("document.querySelectorAll('.vp-carte').length > 0", 'couloirs');
      o.og23p = await lire(`({ cartes: document.querySelectorAll('.vp-carte').length, taille: window.VF_PANNEAU ? VF_PANNEAU.taille() : null })`);
    });
    await sec('og24', async () => {
      await charger('/project.html?vue=couloirs'); await s.attendre("document.querySelectorAll('.vp-carte').length > 0", 'couloirs');
      await clic('.vp-carte[data-id="n:ph-2"]'); await s.attendre(`VibeFlow.state.selected === 'n:ph-2'`, 'ph-2'); await pause(300);
      const e1 = await onglet('code', 1); const e2 = await retour('history.back()', 2); await pause(300);
      const a = await lire(`(() => { const e = document.activeElement; return { id: e.dataset.id || e.id, cur: e.getAttribute('aria-current') }; })()`);
      await onglet('code', 3); const e4 = await onglet('projet', 4); await pause(300);
      const b = await lire(`(() => { const e = document.activeElement; return { id: e.dataset.id || e.id, cur: e.getAttribute('aria-current') }; })()`);
      o.og24 = { code: e1.p, retour: [e2.p, e2.sel, a], clic: [e4.p, e4.sel, b], h: e4.h };
    });
    await sec('og24l', async () => {
      await charger('/project.html?vue=liste'); await s.attendre("document.querySelectorAll('.vp-ligne').length > 0", 'liste');
      await clic('.vp-ligne[data-id="n:ph-2"]'); await s.attendre(`VibeFlow.state.selected === 'n:ph-2'`, 'ph-2'); await pause(300);
      await onglet('code', 1); const e2 = await retour('history.back()', 2); await pause(300);
      o.og24l = { p: e2.p, sel: e2.sel, ae: await lire(`(() => { const e = document.activeElement; return { id: e.dataset.id, tag: e.tagName }; })()`) };
    });
    await sec('og25', async () => {
      await charger('/project.html?vue=couloirs'); await s.attendre("document.querySelectorAll('.vp-carte').length > 0", 'couloirs');
      await clic('.vp-carte[data-id="n:ph-2"]'); await s.attendre(`VibeFlow.state.selected === 'n:ph-2'`, 'ph-2'); await onglet('code', 1);
      const e0 = await etat();
      o.og25 = JSON.parse(await s.ev(`(async () => { let r = false; const p = VF_ONGLETS.aller('projet').then(() => { r = true; });
        await new Promise((ok) => setTimeout(ok, 0)); const tot = r; await p; const forme = window.VF_PROJET ? VF_PROJET.forme() : null;
        const res = { tot, p: location.pathname,
        pret: document.documentElement.dataset.vfPret, evs: __o.evs.slice(), t: document.title, vue: !!document.querySelector('section.vf-projet'), forme,
        sel0: VibeFlow.state.selected, dernier: __o.evs.length }; VibeFlow.select('n:ph-3'); await new Promise((ok) => setTimeout(ok, 700));
        res.sel1 = VibeFlow.state.selected; return JSON.stringify(res); })()`));
      o.og25.avant = e0;
    });
    await sec('og26', async () => {
      await charger('/'); const e0 = await etat();
      o.og26 = JSON.parse(await s.ev(`(async () => { let r = false; const p = VF_ONGLETS.aller('code').then(() => { r = true; });
        await new Promise((ok) => setTimeout(ok, 0)); return JSON.stringify({ r }); })()`));
      o.og26.apres = await rien(300); o.og26.avant = e0;
    });
    await sec('og27', async () => {
      const e0 = await etat();
      o.og27 = JSON.parse(await s.ev(`(async () => { const rs = []; for (const x of ['equipe2', '', '__proto__', 'constructor', undefined, 7])
        rs.push(await VF_ONGLETS.aller(x).then(() => 'ok', () => 'rejet')); return JSON.stringify(rs); })()`));
      o.og27 = { rs: o.og27, apres: await rien(300), avant: e0 };
    });
    await sec('og210', async () => {
      await charger('/project.html?vue=couloirs'); await s.attendre("document.querySelectorAll('.vp-carte').length > 0", 'couloirs');
      await s.ev(`history.replaceState(null, '', '/project.html#v=liste&s=ph-2')`);
      const e1 = await onglet('code', 1); const e2 = await onglet('projet', 2);
      o.og210 = { code: [e1.p, e1.h, e1.cont, e1.sel], projet: [e2.p, e2.h] };
    });
    await sec('og211', async () => {
      await charger('/'); await s.ev(`history.replaceState(null, '', '/#s=zz')`); const e0 = await etat();
      const r = JSON.parse(await s.ev(`(async () => { await VF_ONGLETS.aller('equipe', { fragment: '#vf-x' });
        return JSON.stringify({ h: location.hash, p: location.pathname,
        n: history.length, push: __o.push }); })()`));
      const bad = JSON.parse(await s.ev(`(async () => { const rs = []; for (const x of ['vf-x', '', '#a b', '#' + 'x'.repeat(1024), 7])
        rs.push(await VF_ONGLETS.aller('projet', { fragment: x }).then(() => 'ok', () => 'rejet')); return JSON.stringify(rs); })()`));
      o.og211 = { r, bad, e0, apres: await etat() };
    });
    await sec('og212', async () => {
      const av = await etat(); const r0 = av.repl; const e = await retour('history.back()', (await lire('__o.evs.length')) + 1);
      o.og212 = { p: e.p, h: e.h, repl: e.repl - r0 };
    });
    await sec('og213', async () => { // une modale ouverte (invite du panneau Santé) : aller charge Projet, la surcouche est défaite avec l'onglet
      await charger('/'); await s.ev(`VibeFlow.modal({ title: 'T', html: '<p>x</p>', actions: [] })`); await pause(400);
      const r = JSON.parse(await s.ev(`(async () => JSON.stringify(await VF_ONGLETS.aller('projet').then(() => ['ok'], (e) => ['rejet', e.message])))()`));
      const e = await arrivee(1, 'projet'); o.og213 = { r, p: e.p, t: e.t, ae: e.ae, cerr: await lire('__o.cerr'),
        modale: await lire(`!!document.querySelector('#modal.open')`) };
    });
  }

  if (mode === 'og214') {
    await sec('og214', async () => { // un z posé sur Code ne s'applique pas au premier rendu de Projet ; un rejet rend l'adresse à l'identique
      await charger('/'); await s.ev(`history.replaceState(null, '', '/#z=1.5,10.5,20.25')`); const e0 = await etat(); await s.ev('__o.echec = 1');
      const r = JSON.parse(await s.ev(`(async () => JSON.stringify(await VF_ONGLETS.aller('projet').then(() => 'ok', () => 'rejet')))()`));
      o.og214r = { r, apres: await rien(300), avant: e0 }; await s.ev('__o.echec = 0');
      await s.ev(`VF_ONGLETS.aller('projet')`); const e1 = await arrivee(1, 'projet');
      o.og214 = { p: e1.p, h: e1.h, tk: e1.tk, cont: e1.cont };
    });
  }

  if (mode === 'og215') { // demandes coup sur coup : la file, la dernière demande l'emporte
    const deux = (a, b) => s.ev(`(async () => { const p = [VF_ONGLETS.aller(${a}), VF_ONGLETS.aller(${b})];
      await Promise.all(p.map((x) => x.catch(() => 0))); return 1; })()`);
    await sec('og215', async () => { // un z mémorisé sur Projet ne passe pas sur Équipe ; precedent juste
      await charger('/project.html?vue=couloirs'); await s.attendre("document.querySelectorAll('.vp-carte').length > 0", 'couloirs');
      await s.ev(`history.replaceState(null, '', '/project.html#z=0.5,100,100')`); await onglet('code', 1); const n0 = (await etat()).n;
      await deux("'projet'", "'equipe'"); const e = await arrivee(3, 'equipe'); await pause(500);
      o.og215 = { evs: await lire('__o.evs.slice(-2)'), p: e.p, tk: (await etat()).tk, dn: e.n - n0 };
    });
    await sec('og216', async () => { // aller('code') puis aller('projet') : la seconde, vers l'onglet encore affiché, gagne
      await charger('/project.html?vue=couloirs'); await s.attendre("document.querySelectorAll('.vp-carte').length > 0", 'couloirs');
      await deux("'code'", "'projet'"); await s.attendre('__o.evs.length >= 2', 'deux arrivées'); await pause(500);
      o.og216 = { ...(await etat()), evs: await lire('__o.evs.slice(-2)'), onglet: await lire('VF_COQUILLE.onglet()') };
    });
    await sec('og217', async () => { // Précédent pendant un chargement en vol : l'adresse et l'onglet affiché concordent, Précédent l'emporte
      await charger('/'); await onglet('projet', 1); await onglet('code', 2);
      await s.ev(`(() => { VF_ONGLETS.aller('equipe').catch(() => 0); history.back(); })()`);
      await s.attendre('__o.evs.length >= 4', 'deux arrivées'); await pause(800);
      o.og217 = { ...(await etat()), onglet: await lire('VF_COQUILLE.onglet()') };
    });
  }

  if (mode === 'og218') { // palette ouverte puis fermée par Échap, puis aller : la promesse se règle et la page répond (bornes : un gel ne gèle pas la suite)
    const borne = (p, ms = 8000) => Promise.race([p, pause(ms).then(() => 'gel')]);
    const touche = async (key, code, vk, text, modifiers = 0) => {
      for (const type of ['keyDown', 'keyUp']) {
        const txt = text && type === 'keyDown' ? { text } : {};
        await s.send('Input.dispatchKeyEvent', { type, key, code, windowsVirtualKeyCode: vk, modifiers, ...txt });
      }
    };
    await sec('og218', async () => {
      o.og218 = [];
      const cas = [['/', '/', 'projet'], ['/', 'k', 'equipe'], ['/project.html?vue=couloirs', '/', 'code'], ['/equipe.html', 'k', 'projet']];
      for (const [depart, ouvrir, cible] of cas) {
        await charger(depart); await s.ev('document.body.focus()');
        if (ouvrir === 'k') await touche('k', 'KeyK', 75, 'k', 2); else await touche('/', 'Slash', 191, '/');
        await pause(500); const ouverte = await lire(`document.getElementById('palette').classList.contains('open')`);
        await touche('Escape', 'Escape', 27); await pause(500);
        const attente = `new Promise((ok) => setTimeout(() => ok('attente'), 5000))`;
        const aller = `VF_ONGLETS.aller('${cible}').then(() => 'regle', () => 'rejet')`;
        const r = await borne(s.ev(`(async () => JSON.stringify(await Promise.race([${aller}, ${attente}])))()`), 12000);
        const vivante = await borne(s.ev('1 + 1'), 5000);
        o.og218.push({ depart, ouvrir, cible, ouverte, r: typeof r === 'string' ? JSON.parse(r) : r, vivante });
        if (o.og218[o.og218.length - 1].vivante === 'gel') break;
      }
    });
  }

  if (mode === 'og3') {
    await sec('og3', async () => {
      await charger('/'); const id = await premier(); await s.ev(`VibeFlow.select(${JSON.stringify(id)})`); await pause(300);
      await s.ev(`document.querySelector('nav.vf-tabs a[href="project.html"]').focus()`); // le clic ne déplace alors pas le focus de lui-même
      const e0 = await etat(); await s.ev('__o.echec = 1'); const nf = e0.fetchs;
      await clic('nav.vf-tabs a[href="project.html"]'); await s.attendre(`__o.fetchs.length > ${nf}`, 'lecture tentée'); const e1 = await rien(700);
      o.og31 = { e0, e1 }; await s.ev('__o.echec = 0');
      const e2 = await onglet('projet', 1); o.og32 = { p: e2.p, dn: e2.n - e1.n, t: e2.t, last: e2.last };
      o.og33 = e2.directs;
    });
    await sec('og34', async () => {
      await charger('/'); await s.ev('__o.echec = 1'); const e0 = await etat();
      const r = JSON.parse(await s.ev(`(async () => JSON.stringify(await VF_ONGLETS.aller('projet').then(() => ['ok'], (e) => ['rejet', e.message])))()`));
      o.og34 = { r, avant: e0, apres: await rien(400) }; await s.ev('__o.echec = 0');
    });
    await sec('og35', async () => {
      await charger('/'); await onglet('projet', 1); await onglet('code', 2); const e0 = await etat(); await s.ev('__o.echec = 1');
      await s.ev('history.back()'); await s.attendre(`location.pathname === '/'`, 'adresse ramenée'); const e1 = await rien(700);
      await s.ev('history.forward()'); const e2 = await rien(700); await s.ev('__o.echec = 0');
      o.og35 = { e0, e1, e2 };
    });
  }

  if (mode === 'og2t') {
    await sec('og22', async () => {
      await charger('/index.html'); await s.attendre("!!document.querySelector('button.vf-term-pastille')", 'pastille du terminal');
      await clic('button.vf-term-pastille'); await s.attendre("!!document.querySelector('iframe')", 'cadre du terminal');
      await s.ev(`(() => { const f = document.querySelector('iframe'); f.__vf = { charges: 0 };
        f.addEventListener('load', () => { f.__vf.charges++; }); window.__o.cadre = f; })()`);
      await pause(2500); await s.ev('__o.cadre.__vf.c0 = __o.cadre.__vf.charges'); // le premier chargement du cadre est fini
      await onglet('projet', 1); await onglet('code', 2);
      o.og22 = await lire(`(() => { const f = document.querySelector('iframe');
        return { meme: f === __o.cadre, connecte: !!f && f.isConnected, charges: f && f.__vf ? f.__vf.charges - f.__vf.c0 : -1 }; })()`);
    });
  }
  return o;
});
