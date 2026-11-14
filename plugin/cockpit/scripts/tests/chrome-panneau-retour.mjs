// chrome-panneau-retour.mjs — mesures de la pile Retour du panneau de Projet (80-08, FORM-08) dans un vrai Chrome headless (vrais clics, vraies touches).
// Usage : node chrome-panneau-retour.mjs <chrome> <racine-du-serveur> <mode> [filtre]   Rend UNE ligne JSON { … } ou { erreur }.
// Modes : pr1 (PR1.x), pr2a (PR2.1 à PR2.5, PR2.7, PR2.8, PR2.9, PR2.11 à PR2.14), pr2d (PR2.15, PR2.16 : clavier),
// pr2b (PR2.6), pr2c (PR2.10, lab lancé avec --terminal). Chaque section est isolée (sec).
import fs from 'node:fs';
import zlib from 'node:zlib';
import { executer, pause, stabiliser, attendreValeur } from './chrome-session.mjs';
const [, , chrome, racine, mode, filtre] = process.argv;
// couleur de fond la plus fréquente d'une capture PNG (8 bits, RGB ou RGBA) : le fond réellement rendu sous le texte, « r,g,b »
function fondDominant(buf) {
  let o = 8, w = 0, h = 0, ct = 0; const idat = [];
  while (o < buf.length) {
    const n = buf.readUInt32BE(o), ty = buf.toString('latin1', o + 4, o + 8), d = buf.subarray(o + 8, o + 8 + n);
    if (ty === 'IHDR') { w = d.readUInt32BE(0); h = d.readUInt32BE(4); ct = d[9]; }
    if (ty === 'IDAT') idat.push(d);
    o += 12 + n;
  }
  const bpp = ct === 6 ? 4 : 3, raw = zlib.inflateSync(Buffer.concat(idat)), st = w * bpp, px = Buffer.alloc(h * st);
  const paeth = (a, b, c) => {
    const p = a + b - c, pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c);
    return pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
  };
  for (let y = 0; y < h; y++) {
    const f = raw[y * (st + 1)], l = raw.subarray(y * (st + 1) + 1, (y + 1) * (st + 1));
    for (let x = 0; x < st; x++) {
      const a = x >= bpp ? px[y * st + x - bpp] : 0, b = y ? px[(y - 1) * st + x] : 0, c = x >= bpp && y ? px[(y - 1) * st + x - bpp] : 0;
      px[y * st + x] = (l[x] + (f === 0 ? 0 : f === 1 ? a : f === 2 ? b : f === 3 ? (a + b) >> 1 : paeth(a, b, c))) & 255;
    }
  }
  const m = new Map();
  for (let i = 0; i < px.length; i += bpp) { const k = px[i] + ',' + px[i + 1] + ',' + px[i + 2]; m.set(k, (m.get(k) || 0) + 1); }
  return [...m.entries()].sort((a, b) => b[1] - a[1])[0][0];
}
const lum = (rgb) => {
  const [r, g, b] = rgb.map((v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4; });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
};
const rapport = (a, b) => { const x = lum(a), y = lum(b); return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05); };
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
    const qs = page === 'project.html' ? '?vue=couloirs' : ''; // la forme est explicite : le défaut est la liste à ≤ 700 px (80-07)
    await s.naviguer(`${racine}/${page}${qs}`, { brut: true }); await s.attendre(PRET, 'page prête');
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
      o.pr25.ferme = [av, await taille()]; await touche('p'); await pause(500); // le panneau rouvert : l'état se garde d'une page à l'autre
      await charger(); await carte(2); await deux(); await s.ev("document.dispatchEvent(new CustomEvent('vf:onglet'))"); await pause(200);
      o.pr25.onglet = await taille();
    });
    await sec('pr211', async () => { await charger(); await carte(2); await lien(1); await carte(3); o.pr211 = await taille(); });
    await sec('pr212', async () => {
      await charger(); await carte(2); await lien(1); const av = await taille(); await s.ev('VibeFlow.select(null)'); await pause(500);
      o.pr212 = [av, await taille()];
    });
    await sec('pr214', async () => {
      await charger(); await carte(2); await empile('0123456789ab-milieu-qui-depasse-cdefghijklm'); await pause(300);
      o.pr214 = await lire(`JSON.stringify(${BTN})`);
    });
    await sec('pr27', async () => { // contraste du texte désactivé sur le fond RENDU (pixels de la capture du bouton), pas sur un repli
      o.pr27 = {};
      for (const th of ['dark', 'light']) {
        await charger(); await s.ev(`document.documentElement.setAttribute('data-theme', '${th}')`); await carte(2); await pause(400);
        const r = await lire(`JSON.stringify((() => {
          const b = document.querySelector('#panel .vf-retour'), q = b.getBoundingClientRect(), c = getComputedStyle(b);
          return { x: q.x, y: q.y, w: q.width, h: q.height, c: getComputedStyle(b.lastElementChild).color, dis: b.getAttribute('aria-disabled'),
            poids: c.fontWeight, taille: c.fontSize }; })())`);
        const clip = { x: r.x, y: r.y, width: r.w, height: r.h, scale: 1 };
        const png = Buffer.from((await s.send('Page.captureScreenshot', { format: 'png', clip })).data, 'base64');
        const fond = fondDominant(png), txt = r.c.match(/\d+/g).slice(0, 3).map(Number);
        o.pr27[th] = { couleur: r.c, fond, ratio: rapport(txt, fond.split(',').map(Number)), dis: r.dis, poids: r.poids, taille: r.taille };
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
      await s.naviguer(`${racine}/project.html?vue=liste`, { brut: true }); await s.attendre(PRET, 'liste prête');
      await s.attendre("document.querySelectorAll('section.vf-projet .vp-ligne').length > 1", 'rangées'); await pause(600);
      const ligne = 'section.vf-projet .vp-ligne[data-id^="n:ph-"]'; // sélecteur annoncé par 80-07-PLAN
      await clic(ligne); await pause(600); await s.ev('VF_PANNEAU.empiler({ titre: "L", rouvrir: () => {} })'); const avant = await taille();
      const id = await s.ev(`document.querySelectorAll(${JSON.stringify(ligne)})[1].getAttribute('data-id')`);
      await clic(`${ligne}[data-id="${id}"]`); await pause(600); o.pr29 = { avant, apres: await etat(), id };
      await s.ev('VF_PANNEAU.empiler({ titre: "L", rouvrir: () => {} })'); // Entrée sur une rangée (clavier) : même vidage
      await s.ev(`document.querySelector(${JSON.stringify(ligne)}).focus()`); await touche('Enter'); await pause(600); o.pr29.entree = await etat();
    });
  }

  if (mode === 'pr2d') { // activation au clavier : Entrée et Espace pressent le bouton, jamais l'Entrée globale du moteur (qui plonge dans la sélection)
    const activer = async (nom) => {
      const sp = nom === 'Space';
      for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key: sp ? ' ' : 'Enter', code: nom,
        windowsVirtualKeyCode: sp ? 32 : 13, nativeVirtualKeyCode: sp ? 32 : 13, ...(type === 'keyDown' ? { text: sp ? ' ' : '\r' } : {}) });
    };
    const lecture = async () => ({ ...(await etat()), foc: await s.ev('document.activeElement.className'),
      meme: await s.ev('document.querySelector("#panel .vf-retour") === window.__b') });
    const cas = async (nom, touche, actif) => {
      await charger(); await carte(2); if (actif) await lien(1);
      await s.ev('window.__b = document.querySelector("#panel .vf-retour"); window.__b.focus()'); await activer(touche); await pause(700);
      const e = await lecture(); o[nom] = { sel: e.sel, cont: e.cont, taille: e.taille, foc: e.foc, meme: e.meme };
    };
    await sec('pr215a', async () => { await cas('pr215a', 'Enter', true); });
    await sec('pr215b', async () => { await cas('pr215b', 'Space', true); });
    await sec('pr215c', async () => { await cas('pr215c', 'Enter', false); });
    await sec('pr215d', async () => { await cas('pr215d', 'Space', false); });
    await sec('pr216', async () => { // retour() sur pile vide : le bouton n'est pas reconstruit, le focus reste dessus
      await charger(); await carte(2);
      await s.ev('window.__b = document.querySelector("#panel .vf-retour"); window.__b.focus(); VF_PANNEAU.retour()'); await pause(300);
      const e = await lecture(); o.pr216 = { foc: e.foc, meme: e.meme, taille: e.taille };
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
