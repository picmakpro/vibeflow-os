// chrome-projet-liste.mjs — mesures de la forme Liste de Projet (80-07, FORM-09) : un vrai Chrome headless, de vraies touches, de vrais clics.
// Usage : node chrome-projet-liste.mjs <chrome> <racine-du-serveur> <mode> [sections]   Rend UNE ligne JSON { … } ou { erreur }.
// Modes : pl1 (racine en liste) · pl2 (intérieur de phase) · pl2b (lab sans exigences, porte substituée) · pl3a (touche v, mémoire, tri, largeurs)
//   · pl3b (focus orphelin) · pl3c (zone basse, lab lancé avec --terminal).
import fs from 'node:fs';
import { executer, pause, stabiliser } from './chrome-session.mjs';
const [, , chrome, racine, mode, filtre] = process.argv;
const SEL = filtre ? new Set(filtre.split(',')) : null;
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) {"
  + " const vue = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0);"
  + " return vue ? 'true' : g.call(this, k); }; try { localStorage.removeItem('floorplan:panel'); } catch (e) { void e; } })()";
const KEYS = { Tab: 9, ArrowRight: 39, ArrowLeft: 37, ArrowUp: 38, ArrowDown: 40, Home: 36, End: 35, Enter: 13, Space: 32, Escape: 27, v: 86 };
const ETAT = `window.__pl = { etat() { const a = document.activeElement, S = VibeFlow.state;
  return JSON.stringify({ id: a && a.dataset ? a.dataset.id || null : null, tri: a && a.dataset ? a.dataset.tri || null : null, tag: a ? a.tagName.toLowerCase() : '',
    hid: a ? a.id : '', conn: !!a && a.isConnected, sel: S.selected, c: S.container, forme: window.VF_PROJET ? VF_PROJET.forme() : null,
    cur: [...document.querySelectorAll('[aria-current=true]')].map((e) => e.dataset.id), panneau: !document.body.classList.contains('no-panel'),
    t0: [...document.querySelectorAll('section.vf-projet .vp-ligne[tabindex="0"]')].map((e) => e.dataset.id),
    statut: (document.querySelector('.vp-status') || {}).textContent || '' }); } }`;
const ACTIVES = "document.getAnimations().filter((a) => a.playState === 'running' || a.playState === 'pending')"
  + ".filter((a) => !(a.effect && a.effect.target && a.effect.target.closest && a.effect.target.closest('#panel'))).length";
const LIGNES = "[...document.querySelectorAll('section.vf-projet table:first-of-type .vp-ligne')].map((e) => e.dataset.id)";
const FILL = "(async () => { const G = VibeFlow.graph, b = G.nodes.find((n) => n.id === 'ph-1');"
  + " for (let i = 0; i < 24; i++) G.nodes.push({ ...b, id: 'ph-9' + i, label: 'Phase 9' + i + ' · Remplissage ' + i, num: '9' + i }); await VibeFlow.rerender(); })()";
const MESURE = `(() => { const R = (e) => { if (!e || e.hidden) return null; const b = e.getBoundingClientRect(); return b.width > 0 && b.height > 0
  ? { left: b.left, right: b.right, top: b.top, bottom: b.bottom, h: b.height } : null; }, v = document.querySelector('section.vf-projet'),
  cs = getComputedStyle(v), a = document.activeElement, k = a && a.closest ? a.closest('.vp-ligne') : null;
  const o = { ask: R(document.getElementById('ask')), coin: R(window.VF_COIN && VF_COIN.rectangle() ? document.getElementById('vf-coin') : null),
    pastille: R(document.querySelector('.vf-term-pastille')), tiroirTerm: R(document.querySelector('.vf-term-tiroir')),
    feuille: (() => { const p = document.getElementById('panel'), r = !document.body.classList.contains('no-panel') && R(p);
      return r && r.right - r.left >= document.getElementById('stage').getBoundingClientRect().width * 0.8 ? r : null; })() };
  const c = k ? R(k) : null, dock = R(document.getElementById('stage')).bottom < innerHeight - 1, inter = Object.keys(o).filter((n) => c && o[n]
    && (n !== 'tiroirTerm' || dock) && c.left < o[n].right && c.right > o[n].left && c.top < o[n].bottom && c.bottom > o[n].top);
  return JSON.stringify({ pb: parseFloat(cs.paddingBottom), spb: parseFloat(cs.scrollPaddingBlockEnd), id: k ? k.dataset.id : null, inter,
    haut: v.scrollHeight > v.clientHeight, somme: ['ask', 'coin', 'pastille', 'feuille'].reduce((n, x) => n + (o[x] ? o[x].h : 0), 0) }); })()`;

await executer(chrome, async (s) => {
  const o = { erreurs: {} };
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: SANS_VISITE });
  const sec = async (nom, f) => { if (SEL && !SEL.has(nom)) return; try { await f(); } catch (e) { o.erreurs[nom] = String(e.message).slice(0, 160); } };
  const lire = async (expr) => { const v = await s.ev(expr); return v === undefined ? null : JSON.parse(v); };
  const touche = async (nom, mod = 0, texte) => {
    for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key: nom === 'Space' ? ' ' : nom, code: nom, modifiers: mod,
      windowsVirtualKeyCode: KEYS[nom], nativeVirtualKeyCode: KEYS[nom], ...(type === 'keyDown' && (texte || nom === 'Enter') ? { text: texte || '\r' } : {}) });
  };
  const etat = async () => (await lire('__pl.etat()')) || {};
  const presser = async (nom, ms = 150, mod = 0, texte) => { await touche(nom, mod, texte); await pause(ms); return etat(); };
  const point = (sel) => lire(`(() => { const e = document.querySelector(${JSON.stringify(sel)}); if (!e) return 'null'; e.scrollIntoView({ block: 'nearest' });
    const b = e.getBoundingClientRect(); return JSON.stringify({ x: b.x + b.width / 2, y: b.y + b.height / 2 }); })()`);
  const clic = async (sel) => {
    const r = await point(sel); if (!r) throw new Error(`clic : « ${sel} » absent`);
    await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: r.x, y: r.y });
    for (const type of ['mousePressed', 'mouseReleased']) await s.send('Input.dispatchMouseEvent', { type, x: r.x, y: r.y, button: 'left', clickCount: 1 });
    await pause(250);
  };
  const toucher = async (sel) => {
    const r = await point(sel); if (!r) throw new Error(`toucher : « ${sel} » absent`);
    await s.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: r.x, y: r.y }] });
    await s.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] }); await pause(400);
  };
  const focus = (sel) => s.ev(`document.querySelector(${JSON.stringify(sel)}).focus()`);
  const ligne = (id) => `section.vf-projet .vp-ligne[data-id="${id}"]`;
  const compte = "JSON.stringify([document.querySelectorAll('.vp-ligne, .vp-carte').length, document.querySelectorAll('#viewport .node').length])";
  const charger = async (qs = '', w = 1440, h = 900, tactile = false, vide = false) => {
    await s.send('Emulation.setTouchEmulationEnabled', { enabled: tactile });
    await s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: tactile });
    await s.naviguer(`${racine}/project.html${qs}`, { brut: true }); await s.attendre(PRET, 'page prête');
    if (vide) { await s.ev('localStorage.clear()'); await s.naviguer(`${racine}/project.html${qs}`, { brut: true }); await s.attendre(PRET, 'page prête'); }
    await stabiliser(() => s.ev(compte), { pas: 120, max: 5000 }); await s.ev(ETAT); await pause(300);
  };
  const plonger = async (id) => { await focus(ligne(id)); await presser('Enter', 600); await s.attendre(`VibeFlow.state.container === '${id}'`, 'plongée ' + id); await pause(400); };
  const TR = "(t) => t.length";

  if (mode === 'pl1') {
    await sec('pl11', async () => {
      await charger('?vue=liste');
      o.pl11 = await lire(`JSON.stringify({ tables: document.querySelectorAll('section.vf-projet table').length, lignes: ${LIGNES},
        tri: [...document.querySelectorAll('section.vf-projet table:first-of-type th')].filter((t) => t.getAttribute('aria-sort') !== 'none')
          .map((t) => [t.querySelector('[data-tri]').dataset.tri, t.getAttribute('aria-sort')]) })`);
    });
    await sec('pl12', async () => {
      await charger('?vue=liste');
      o.pl12 = await lire(`JSON.stringify([...document.querySelectorAll('.vp-tete .vp-bascule button')].map((b) => [b.textContent, b.getAttribute('aria-pressed')]))`);
    });
    await sec('pl13', async () => {
      await charger('?vue=liste'); await clic(ligne('n:ph-2'));
      o.pl13 = await lire(`JSON.stringify({ sel: VibeFlow.state.selected, cur: [...document.querySelectorAll('[aria-current=true]')].map((e) => e.dataset.id) })`);
    });
  }

  if (mode === 'pl2') {
    await sec('pl21', async () => {
      await charger('?vue=liste'); await plonger('n:ph-1');
      o.pl21 = await lire(`JSON.stringify({ h1: document.getElementById('vf-projet-titre').textContent, h3: [...document.querySelectorAll('section.vf-projet h3')].map((e) => e.textContent),
        plans: [...document.querySelectorAll('section.vf-projet .vp-ligne[data-id^="f:"]')].map((e) => [(e.querySelector('.vp-pid') || {}).textContent,
          (e.querySelector('.vst') || {}).textContent, (e.querySelector('.vp-cov') || {}).textContent || '']) })`);
      o.pl22 = await lire(`JSON.stringify({ li: [...document.querySelectorAll('section.vf-projet ul.vp-exig li')].map((e) => e.textContent.replace(/\\s+/g, ' ').trim()),
        input: document.querySelectorAll('section.vf-projet input').length, img: document.querySelectorAll('section.vf-projet img').length, flag: String(window.__x),
        h2: [...document.querySelectorAll('section.vf-projet h2')].map((e) => e.textContent),
        fois: document.querySelector('section.vf-projet').textContent.split('onerror=window.__x=1').length - 1 })`);
      o.pl24a = (await etat()).hid;
      o.pl25 = await lire(`JSON.stringify([...document.querySelectorAll('.vp-tete .vp-bascule button')].map((b) => [b.textContent, b.getAttribute('aria-pressed')]))`);
    });
    await sec('pl23', async () => {
      await charger('?vue=liste'); await plonger('n:ph-1'); const suite = [], ids = await lire(`JSON.stringify([...document.querySelectorAll('section.vf-projet .vp-ligne[data-id^="f:"]')].map((e) => e.dataset.id))`);
      await focus(`section.vf-projet .vp-ligne[data-id="${ids[0]}"]`); const t0 = (await etat()).t0;
      for (const k of ['ArrowDown', 'ArrowDown', 'ArrowDown', 'ArrowUp', 'End', 'Home']) suite.push([k, (await presser(k)).id === null ? null : ids.indexOf((await etat()).id)]);
      o.pl23 = { n: ids.length, t0: t0.length, suite, sel: (await etat()).sel === ids[0] };
    });
    await sec('pl24', async () => {
      await charger('?vue=liste'); await plonger('n:ph-1'); const retours = [];
      for (let i = 0; i < 3 && (await etat()).c !== 'root'; i++) retours.push((await presser('Escape', 700)).c);
      await pause(400); o.pl24 = { retours, fin: await etat() };
    });
    await sec('pl25', async () => {
      await charger('?vue=liste'); await plonger('n:ph-1'); await clic('.vp-tete .vp-bascule button:last-child'); await pause(400);
      o.pl25g = await lire(`JSON.stringify({ svg: getComputedStyle(document.getElementById('svg')).visibility, noeuds: document.querySelectorAll('#viewport .node').length })`);
    });
    await sec('pl26', async () => {
      await charger('?vue=liste'); await plonger('n:ph-5');
      o.pl26 = await lire(`JSON.stringify({ texte: document.querySelector('section.vf-projet').textContent, plans: [...document.querySelectorAll('section.vf-projet h2')].map((e) => e.textContent) })`);
    });
    await sec('pl27', async () => {
      o.pl27 = {};
      const mes = (id) => `(() => { const l = document.querySelector('${ligne(id)}'), t = l.querySelector('.vp-titre'), d = l.getAttribute('aria-describedby');
        return JSON.stringify({ texte: t.textContent, hauteur: [t.scrollHeight, t.clientHeight], decrit: d ? document.getElementById(d).textContent : null,
          nom: l.getAttribute('aria-label') }); })()`;
      for (const [cle, w, tactile] of [['1000', 1000, false], ['390', 390, true]]) {
        await charger('?vue=liste', w, 800, tactile); const r = {};
        r.a52 = await lire(mes('n:ph-4')); r.m53 = await lire(mes('n:ph-6')); r.l70 = await lire(mes('n:ph-3'));
        await plonger('n:ph-1'); r.p70 = await lire(`(() => { const l = [...document.querySelectorAll('section.vf-projet .vp-ligne[data-id^="f:"]')].pop(), t = l.querySelector('.vp-titre'), d = l.getAttribute('aria-describedby');
          return JSON.stringify({ pid: l.querySelector('.vp-pid').textContent, texte: t.textContent, decrit: d ? document.getElementById(d).textContent : null }); })()`);
        o.pl27[cle] = r;
      }
    });
    await sec('pl28', async () => {
      await charger('?vue=liste'); const r = {};
      await focus(ligne('n:ph-3')); await s.ev('VibeFlow.select(null)'); await pause(200);
      await presser('Space', 300); r.espace = (await etat()).sel; r.cur = (await etat()).cur;
      await presser('Enter', 600); await s.attendre("VibeFlow.state.container === 'n:ph-3'", 'Entrée plonge'); r.entree = (await etat()).c;
      await charger('?vue=liste'); await plonger('n:ph-1');
      await s.ev("(() => { if (!document.body.classList.contains('no-panel')) document.getElementById('btn-panel').click(); })()"); await pause(400);
      r.ferme = !(await etat()).panneau;
      await s.ev("document.querySelector('section.vf-projet .vp-ligne[data-id^=\"f:\"]').focus()"); await s.ev('VibeFlow.select(null)'); await pause(200);
      await presser('Enter', 500); const e = await etat(); r.plan = [e.sel && e.sel.startsWith('f:'), e.panneau, e.c];
      await charger('?vue=liste', 390, 844, true); await toucher(ligne('n:ph-3'));
      const t = await etat(); r.touch = [t.sel, t.panneau, t.c, await lire("JSON.stringify(document.querySelectorAll('#panel [data-open=\"n:ph-3\"]').length)")];
      await focus(ligne('n:ph-4')); await presser('Space', 300); r.tesp = (await etat()).sel;
      await presser('Enter', 600); await s.attendre("VibeFlow.state.container === 'n:ph-4'", 'Entrée plonge au toucher'); r.tent = (await etat()).c;
      o.pl28 = r;
    });
  }

  if (mode === 'pl2b') {
    await sec('pl29', async () => {
      await charger('?vue=liste'); const r = {};
      r.graphe = await lire("JSON.stringify([VibeFlow.graph.nodes.filter((n) => n.kind === 'exigences').length, (VibeFlow.graph.links || []).filter((l) => l.label === 'couvre').length])");
      await plonger('n:ph-1');
      r.vraie = await lire(`JSON.stringify({ li: document.querySelectorAll('section.vf-projet ul.vp-exig li').length, cov: document.querySelectorAll('section.vf-projet .vp-cov').length })`);
      await s.ev(`(async () => { window.__vraie = window.VF_EXIGENCES.lireExigences; const e = [{ id: 'FX-1', texte: 'Premier texte factice', cochee: true, cible: null },
        { id: 'FX-2', texte: 'Second texte factice', cochee: false, cible: null }]; window.VF_EXIGENCES.lireExigences = (ph) => {
          const c = {}; for (const f of VibeFlow.graph.files) if (/-PLAN\\.md$/.test(f.p)) c['f:' + f.p] = e; return { exigences: e, couverture: c }; };
        await VibeFlow.rerender(); })()`); await pause(500);
      r.fausse = await lire(`JSON.stringify({ li: [...document.querySelectorAll('section.vf-projet ul.vp-exig li')].map((e) => e.textContent.replace(/\\s+/g, ' ').trim()),
        cov: [...document.querySelectorAll('section.vf-projet .vp-cov')].map((e) => e.textContent) })`);
      await s.ev(`(async () => { window.VF_EXIGENCES.lireExigences = window.__vraie; await VibeFlow.rerender(); })()`); await pause(500);
      r.restaure = await lire(`JSON.stringify({ li: document.querySelectorAll('section.vf-projet ul.vp-exig li').length })`);
      o.pl29 = r;
    });
  }

  if (mode === 'pl3a') {
    await sec('pl31', async () => {
      await charger('?vue=couloirs'); await focus('.vp-carte[data-id="n:ph-4"]'); const r = [];
      const noter = async () => { const e = await etat(); r.push([e.forme, e.id, e.statut, e.tag, e.hid]); };
      await presser('v', 300, 0, 'v'); await noter(); await presser('v', 300, 0, 'v'); await noter(); await presser('v', 300, 0, 'v'); await noter();
      o.pl31 = r;
    });
    await sec('pl32', async () => {
      await charger('?vue=couloirs');
      await s.ev("(() => { const t = document.createElement('textarea'); t.id = 'zone'; document.body.append(t); t.focus(); })()");
      await presser('v', 200, 0, 'v'); const saisie = await lire("JSON.stringify([VF_PROJET.forme(), document.getElementById('zone').value])");
      const mods = [];
      for (const m of [1, 2, 4]) { await s.ev('document.getElementById("zone").blur(); document.body.focus()'); await presser('v', 200, m); mods.push((await etat()).forme); }
      await s.ev('document.getElementById("zone").remove(); document.body.focus()'); await presser('v', 250, 0, 'v');
      o.pl32 = { saisie, mods, simple: (await etat()).forme };
    });
    await sec('pl33', async () => {
      const r = {}; await charger('', 390, 844, true, true); r.etroit = (await etat()).forme;
      await charger('', 1440, 900); r.large = (await etat()).forme; await clic('.vp-tete .vp-bascule button[data-forme="graphe"]');
      await charger('', 1440, 900); r.apres = (await etat()).forme;
      await charger('?vue=liste', 1440, 900); r.url = (await etat()).forme;
      await charger('', 1440, 900); r.memoire = (await etat()).forme;
      r.cles = await lire("JSON.stringify([Object.keys(localStorage).filter((k) => k.indexOf('vf-projet-forme') === 0), (VibeFlow.graph.project || {}).name || (VibeFlow.graph.meta || {}).rootName || 'map'])");
      o.pl33 = r;
    });
    await sec('pl34', async () => {
      await charger('?vue=liste'); const r = {};
      await clic('section.vf-projet table:first-of-type [data-tri="plans"]'); r.asc = await lire(`JSON.stringify([${LIGNES}, (document.querySelector('th[aria-sort="ascending"] [data-tri]') || {}).dataset.tri, (__pl.etat(), JSON.parse(__pl.etat()).statut)])`);
      await clic('section.vf-projet table:first-of-type [data-tri="plans"]'); r.desc = await lire(`JSON.stringify([${LIGNES}, document.querySelector('th[aria-sort="descending"]') ? 1 : 0, JSON.parse(__pl.etat()).statut])`);
      await s.ev("VibeFlow.graph.nodes.find((n) => n.id === 'ph-3').exigences = undefined"); await clic('section.vf-projet table:first-of-type [data-tri="exigences"]');
      r.abs = await lire(`JSON.stringify([${LIGNES}, (document.querySelector('${ligne('n:ph-3')}').closest('tr').querySelector('.vp-sr') || {}).textContent || null])`);
      o.pl34 = r;
    });
    await sec('pl35', async () => {
      const r = {}; await charger('?vue=liste', 390, 844, true);
      r.roles = await lire(`JSON.stringify(['table', 'row', 'cell', 'columnheader'].map((x) => document.querySelectorAll('section.vf-projet [role=' + x + ']').length > 0))`);
      r.tri = await lire(`JSON.stringify([...document.querySelectorAll('section.vf-projet table:first-of-type [data-tri]')].map((b) => Math.round(b.getBoundingClientRect().height)))`);
      r.bascule = await lire(`JSON.stringify((() => { const g = document.querySelector('.vp-tete .vp-bascule'), h = document.querySelector('.vp-tete h1'), v = document.querySelector('section.vf-projet').getBoundingClientRect(), b = g.getBoundingClientRect();
        return { hauteurs: [...g.querySelectorAll('button')].map((x) => x.getBoundingClientRect().height), dessous: b.top >= h.getBoundingClientRect().bottom - 1, largeur: Math.round(b.width), vue: Math.round(v.width) }; })())`);
      const defil = async () => lire(`JSON.stringify((() => { const v = document.querySelector('section.vf-projet'), c = getComputedStyle(v); return [v.scrollWidth <= v.clientWidth, ['auto', '0px'].includes(c.scrollPaddingInlineStart), ['auto', '0px'].includes(c.scrollPaddingInlineEnd)]; })())`);
      r.ferme390 = await defil(); await s.ev("VibeFlow.select('n:ph-3')"); await pause(500); r.ouvert390 = await defil();
      await charger('?vue=liste', 600, 900); r.ferme600 = await defil(); await s.ev("VibeFlow.select('n:ph-3')"); await pause(500); r.ouvert600 = await defil();
      await charger('?vue=liste', 800, 900); r.ferme800 = await defil();
      o.pl35 = r;
    });
    await sec('pl36', async () => {
      await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
      await charger('?vue=couloirs'); await presser('v', 300, 0, 'v'); const a = await lire(`JSON.stringify(${ACTIVES})`);
      await clic('section.vf-projet table:first-of-type [data-tri="plans"]'); const b = await lire(`JSON.stringify(${ACTIVES})`);
      o.pl36 = [a, b]; await s.send('Emulation.setEmulatedMedia', { features: [] });
    });
  }

  if (mode === 'pl3b') {
    await sec('pl37', async () => {
      await charger('?vue=liste'); const r = {};
      await focus('section.vf-projet table:first-of-type [data-tri="plans"]'); await presser('Enter', 300); r.entree = await etat();
      await clic('section.vf-projet table:first-of-type [data-tri="plans"]'); r.clic = await etat();
      await focus('section.vf-projet table:first-of-type [data-tri="etat"]'); await s.ev('VibeFlow.rerender()'); await pause(400); r.direct = await etat();
      r.sort = await lire(`JSON.stringify([...document.querySelectorAll('section.vf-projet table:first-of-type th')].map((t) => t.getAttribute('aria-sort')))`);
      await focus('details[data-cle="historique"] summary'); await s.ev('VibeFlow.rerender()'); await pause(400);
      r.hist = await lire(`JSON.stringify([document.activeElement.tagName, document.activeElement.parentNode.dataset.cle, document.activeElement.parentNode.open])`);
      await s.ev("document.querySelector('details[data-cle=\"backlog\"]').open = true"); await pause(150);
      await focus('details[data-cle="backlog"] summary'); await s.ev('VibeFlow.rerender()'); await pause(400);
      r.back = await lire(`JSON.stringify([document.activeElement.tagName, document.activeElement.parentNode.dataset.cle, document.activeElement.parentNode.open])`);
      o.pl37 = r;
    });
  }

  if (mode === 'pl3c') {
    o.pl38 = {};
    for (const [cle, w, h, tactile] of [['1440', 1440, 900, false], ['1024', 1024, 768, false], ['390', 390, 844, true]]) {
      await sec('pl38' + cle, async () => {
        await charger('?vue=liste', w, h, tactile); await s.ev(FILL); await pause(300); const r = {};
        const mesurer = async (nom) => { await focus('section.vf-projet .vp-ligne[tabindex="0"]'); await presser('End', 400); r[nom] = await lire(MESURE); };
        await mesurer('base');
        if (w < 1000) { await s.ev("VibeFlow.select('n:ph-3')"); await pause(500); await mesurer('feuille'); await s.ev('VibeFlow.select(null)'); await pause(200); }
        await s.ev("document.querySelector('.vf-term-pastille').click()");
        await s.attendre("document.body.classList.contains('vf-term-ouvert') && !document.querySelector('.vf-term-tiroir').hidden", 'terminal ouvert');
        await pause(600); await mesurer('terminal');
        await s.ev("document.querySelector('.vf-term-tiroir button[aria-label^=\"Fermer\"]').click()");
        await s.attendre("!document.body.classList.contains('vf-term-ouvert')", 'terminal refermé'); await pause(500); await mesurer('ferme');
        await plonger('n:ph-1'); await focus('section.vf-projet .vp-ligne[tabindex="0"]'); await presser('End', 400); r.phase = await lire(MESURE);
        o.pl38[cle] = r;
      });
    }
  }
  if (mode === 'png') { // captures de revue de design (PL_PNG = dossier) : liste, sombre et clair, 1440 et 390 px, une rangée focalisée au clavier, l'intérieur d'une phase
    const dir = process.env.PL_PNG; fs.mkdirSync(dir, { recursive: true }); o.png = [];
    const clip = async (nom) => { const r = await s.send('Page.captureScreenshot', { format: 'png' }); fs.writeFileSync(`${dir}/${nom}.png`, Buffer.from(r.data, 'base64')); o.png.push(nom); };
    const theme = (t) => s.ev(`document.documentElement.setAttribute('data-theme', '${t}')`);
    for (const [nom, w, h, tactile] of [['1440', 1440, 900, false], ['390', 390, 844, true]]) for (const t of ['sombre', 'clair']) await sec(`png${nom}${t}`, async () => {
      await charger('?vue=liste', w, h, tactile); await theme(t === 'sombre' ? 'dark' : 'light'); await pause(300); await clip(`liste-${nom}-${t}`);
    });
    await sec('pngfocus', async () => {
      await charger('?vue=liste', 1440, 900); await theme('dark'); await focus('section.vf-projet .vp-ligne[tabindex="0"]'); await presser('ArrowDown', 300); await clip('liste-1440-focus-clavier');
    });
    await sec('pngphase', async () => {
      await charger('?vue=liste', 1440, 900); await theme('dark'); await plonger('n:ph-1'); await pause(300); await clip('phase-1440-sombre');
    });
  }
  void TR;
  return o;
});
