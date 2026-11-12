// chrome-panneau-retour.mjs — mesures de la pile Retour du panneau de Projet (80-08, FORM-08) dans un vrai Chrome headless, de vrais clics, de vraies touches.
// Usage : node chrome-panneau-retour.mjs <chrome> <racine-du-serveur> <mode> [filtre]   Rend UNE ligne JSON { … } ou { erreur }.
// Modes : pr1 (PR1.x), pr2a (PR2.1 à PR2.5, PR2.7, PR2.8, PR2.9), pr2b (PR2.6), pr2c (PR2.10, lab lancé avec --terminal). Chaque section est isolée (sec).
import fs from 'node:fs';
import { executer, pause, stabiliser, attendreValeur } from './chrome-session.mjs';
const [, , chrome, racine, mode, filtre] = process.argv;
const SEL = filtre ? new Set(filtre.split(',')) : null;
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) {"
  + " const vue = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0);"
  + " return vue ? 'true' : g.call(this, k); }; })()";
const KEYS = { Escape: 27, Enter: 13, p: 80 };
const BTN = `(() => { const b = document.querySelector('#panel .vf-retour'); if (!b) return null;
  const d = document.getElementById(b.getAttribute('aria-describedby'));
  return { dis: b.getAttribute('aria-disabled'), texte: b.textContent.trim(), nom: b.getAttribute('aria-label'), desc: d ? d.textContent : null,
    h: Math.round(b.getBoundingClientRect().height), n: document.querySelectorAll('#panel .vf-retour').length }; })()`;
const ETAT = `JSON.stringify({ sel: VibeFlow.state.selected, cont: VibeFlow.state.container, forme: window.VF_PROJET ? VF_PROJET.forme() : null,
  taille: window.VF_PANNEAU ? VF_PANNEAU.taille() : null, btn: ${BTN}, ouvert: !document.body.classList.contains('no-panel') })`;

await executer(chrome, async (s) => {
  const o = { erreurs: {} };
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: SANS_VISITE });
  const sec = async (nom, f) => { if (SEL && !SEL.has(nom)) return; try { await f(); } catch (e) { o.erreurs[nom] = String(e.message).slice(0, 160); } };
  const lire = async (expr) => { const v = await s.ev(expr); return v === undefined ? null : JSON.parse(v); };
  const etat = () => lire(ETAT);
  const charger = async (page = 'project.html', w = 1440, h = 900, tactile = false) => {
    await s.send('Emulation.setTouchEmulationEnabled', { enabled: tactile });
    await s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: tactile });
    await s.naviguer(`${racine}/${page}`, { brut: true }); await s.attendre(PRET, 'page prête');
    if (page === 'project.html') await s.attendre("document.querySelectorAll('.vp-carte').length > 0", 'couloirs');
    await pause(400);
  };
  const touche = async (nom) => { for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key: nom, code: nom,
    windowsVirtualKeyCode: KEYS[nom], nativeVirtualKeyCode: KEYS[nom], ...(nom.length === 1 ? { text: nom } : {}) }); };
  const clic = async (sel) => {
    const r = await lire(`(() => { const e = document.querySelector(${JSON.stringify(sel)}); if (!e) return 'null'; e.scrollIntoView({ block: 'nearest' });
      const b = e.getBoundingClientRect(); return JSON.stringify({ x: b.x + b.width / 2, y: b.y + b.height / 2 }); })()`);
    if (!r) throw new Error(`clic : « ${sel} » absent`);
    await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: r.x, y: r.y });
    for (const type of ['mousePressed', 'mouseReleased']) await s.send('Input.dispatchMouseEvent', { type, x: r.x, y: r.y, button: 'left', clickCount: 1 });
  };
  const posee = (cond) => attendreValeur(etat, cond, { max: 8000 }).then(() => stabiliser(etat, { pas: 150, max: 4000 }));
  const carte = async (n) => { await clic(`.vp-carte[data-id="n:ph-${n}"]`); return posee((e) => e && e.sel === `n:ph-${n}`); };
  const lien = async (n) => { await clic(`#panel a.row[data-go="n:ph-${n}"]`); return posee((e) => e && e.sel === `n:ph-${n}`); };
  const empile = (titre, extra = '') => s.ev(`((t) => VF_PANNEAU.empiler(
    { titre: t, rouvrir: () => { (window.__ro ||= []).push(t); ${extra} } }))(${JSON.stringify(titre)})`);
  const taille = () => s.ev('VF_PANNEAU.taille()');
  const retourClic = async () => { await clic('#panel .vf-retour'); await pause(500); return stabiliser(etat, { pas: 150, max: 4000 }); };

  if (mode === 'pr1') {
    await sec('pr11', async () => { await charger(); o.pr11 = await carte(2); });
    await sec('pr12', async () => { await charger(); await carte(2); o.pr12 = await lien(1); });
    await sec('pr13', async () => {
      await charger(); const av = await carte(2); await lien(1); o.pr13 = await retourClic(); o.pr13.avant = [av.cont, av.forme];
    });
  }

  if (mode === 'pr2a') {
    await sec('pr21', async () => {
      await charger(); await carte(2); await empile('REQ-12'); await lien(1); const avant = await etat();
      const r = await retourClic(); o.pr21 = { avant: avant.btn, apres: r, ro: await s.ev('JSON.stringify(window.__ro)') };
    });
    await sec('pr22', async () => {
      await charger(); await carte(2); await empile('A'); await empile('B'); await empile('C', 'throw new Error("rouvrir défaillant")'); await lien(1);
      const avant = await etat(); const r = await retourClic(); o.pr22 = { avant: avant.btn, apres: r, ro: await s.ev('JSON.stringify(window.__ro)') };
    });
    await sec('pr23', async () => {
      await charger(); await carte(2);
      await s.ev('for (let i = 0; i < 40; i++) VF_PANNEAU.empiler({ titre: "E" + i, rouvrir: () => { (window.__ro ||= []).push("E" + i); } })');
      const t = await taille(); await s.ev('for (let i = 0; i < 32; i++) VF_PANNEAU.retour()');
      o.pr23 = { t, ro: await s.ev('JSON.stringify(window.__ro)'), apres: await taille() };
    });
    await sec('pr24', async () => {
      await charger(); await carte(2); await empile('<img src=x onerror=window.__r=1>'); await pause(300);
      o.pr24 = await lire(`JSON.stringify({ img: document.querySelectorAll('#panel img').length, r: typeof window.__r, b: ${BTN} })`);
    });
    await sec('pr25', async () => {
      const deux = async () => { await empile('X'); await empile('Y'); };
      await charger(); await carte(2); await deux(); await carte(3); o.pr25 = { carte: await taille() };
      await charger(); await carte(4); await deux(); await touche('Enter'); await posee((e) => e && e.cont !== 'root');
      await touche('Escape'); await posee((e) => e && e.cont === 'root'); o.pr25.racine = await taille();
      await charger(); await carte(2); await deux(); const av = await taille(); await touche('p'); await attendreValeur(taille, (t) => t === 0, { max: 3000 });
      o.pr25.ferme = [av, await taille()];
      await charger(); await carte(2); await deux(); await s.ev("document.dispatchEvent(new CustomEvent('vf:onglet'))"); await pause(200);
      o.pr25.onglet = await taille();
    });
    await sec('pr27', async () => {
      o.pr27 = {};
      for (const th of ['dark', 'light']) {
        await charger(); await s.ev(`document.documentElement.setAttribute('data-theme', '${th}')`); await carte(2); await pause(300);
        o.pr27[th] = await lire(`JSON.stringify((() => { const L = (c) => { const m = c.match(/[\\d.]+/g).map(Number); const f = (v) => { v /= 255;
          return v <= .03928 ? v / 12.92 : ((v + .055) / 1.055) ** 2.4; }; return .2126 * f(m[0]) + .7152 * f(m[1]) + .0722 * f(m[2]); };
          const mix = (c, f) => { const m = c.match(/[\\d.]+/g).map(Number); const a = m.length > 3 ? m[3] : 1; const g = f.match(/[\\d.]+/g).map(Number);
            return 'rgb(' + [0, 1, 2].map((i) => Math.round(m[i] * a + g[i] * (1 - a))).join(',') + ')'; };
          const R = (a, b) => { const x = L(a), y = L(b); return (Math.max(x, y) + .05) / (Math.min(x, y) + .05); };
          const t = document.querySelector('#panel .vf-retour > span:last-child'), p = document.getElementById('panel');
          let fond = getComputedStyle(p).backgroundColor, base = getComputedStyle(document.body).backgroundColor;
          if (!/^rgb\\(/.test(base)) base = th === 'dark' ? 'rgb(18,18,18)' : 'rgb(255,255,255)'; fond = mix(fond, base);
          const c = getComputedStyle(t).color; return { couleur: c, fond, ratio: R(c, fond), dis: t.parentNode.getAttribute('aria-disabled') }; })())`);
      }
    });
    await sec('pr28', async () => {
      o.pr28 = {};
      for (const page of ['equipe.html', 'index.html']) {
        await charger(page); await pause(500);
        o.pr28[page] = await lire("JSON.stringify({ retour: document.querySelectorAll('.vf-retour').length, globale: typeof window.VF_PANNEAU })");
      }
    });
    await sec('pr29', async () => {
      if (!fs.existsSync(process.env.PR_LISTE || '/nonexistent')) { o.pr29 = { attente: true }; return; }
      await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
      await s.naviguer(`${racine}/project.html?vue=liste`, { brut: true }); await s.attendre(PRET, 'liste prête'); await pause(600);
      const ligne = 'section.vf-projet [data-id^="n:ph-"]:not(.vp-carte)';
      await clic(ligne); await pause(600); await s.ev('VF_PANNEAU.empiler({ titre: "L", rouvrir: () => {} })');
      await clic('#panel a.row[data-go^="n:ph-"]'); await pause(600); const avant = await taille();
      await clic(`${ligne}:last-of-type`); await pause(600); o.pr29 = { avant, apres: await etat() };
    });
  }

  if (mode === 'pr2b') {
    const cas = async (nom, w, h, tactile) => {
      await charger('project.html', w, h, tactile); await carte(2); await empile('A'); await empile('B'); await lien(1);
      await s.ev("document.querySelector('#panel .vf-retour').focus()"); const avant = await etat(); await touche('Escape'); await pause(900);
      o[nom] = { avant: [avant.ouvert, avant.taille], apres: await etat() };
    };
    await sec('pr26a', async () => { await cas('pr26a', 1440, 900, false); });
    await sec('pr26b', async () => { await cas('pr26b', 390, 844, true); });
    await sec('pr26c', async () => { await cas('pr26c', 800, 900, false); });
  }

  if (mode === 'pr2c') {
    const cas = async (nom, w, h, tactile) => {
      await charger('project.html', w, h, tactile); await carte(2); await empile('A'); await lien(1); await pause(400);
      o[nom] = await lire(`JSON.stringify((() => { const b = document.querySelector('#panel .vf-retour'); b.scrollIntoView({ block: 'nearest' });
        const r = b.getBoundingClientRect(), e = document.elementFromPoint(r.x + r.width / 2, r.y + r.height / 2);
        return { couvert: !(e && (e === b || b.contains(e))), sur: e ? (e.id || e.className || e.tagName) : null, h: Math.round(r.height),
          dis: b.getAttribute('aria-disabled'),
          pastille: !!document.querySelector('.vf-term-pastille'), ask: !!document.getElementById('ask'), coin: !!document.getElementById('vf-coin') }; })())`);
    };
    await sec('pr210a', async () => { await cas('pr210a', 390, 844, true); });
    await sec('pr210b', async () => { await cas('pr210b', 800, 900, false); });
  }

  return o;
});
