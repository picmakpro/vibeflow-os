// chrome-surcouches.mjs — mesures de la pile de surcouches (80-02 : FORM-02, AUDC-M6), dans un vrai Chrome sans tête.
// Usage : node chrome-surcouches.mjs <chrome> <racine> <source-pile> [<racine-terminal>] [<sections>]
//   <source-pile> : texte du module ui/00-vf-surcouches.js (SU1.3 le réévalue) ; <sections> : su1,su2,su3,su4 (défaut : toutes).
// Rend une ligne JSON { su1, su2, su3, su4 } ; chaque section est lisible seule. SU6 n'est pas mesuré ici (coquille de la 79).
import fs from 'node:fs';
import { executer, pause } from './chrome-session.mjs';
const [, , chrome, racine, source, racineTerm, quoi = 'su1,su2,su3,su4'] = process.argv;
const veut = (k) => quoi.split(',').includes(k);
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlow.state && !!window.VibeFlow.state.layout";
const SEL = "a[href], button, input, select, textarea, summary, [tabindex]";

// posé avant tout script de la page : journal des écouteurs (type, capture, cible, fichier de l'extension qui l'a posé) + écouteur du « cas interdit »
function espion() {
  window.__ec = []; window.__interdit = [];
  const nom = () => {
    const c = document.currentScript; if (!c) return '';
    if (c.src) return c.src.split('/').pop();
    const m = /^\s*\/\*\s*ui\/(\S+)\s*\*\//.exec(c.textContent || ''); return m ? m[1] : 'moteur';
  };
  const ajout = EventTarget.prototype.addEventListener;
  EventTarget.prototype.addEventListener = function (t, f, o) {
    const cible = this === window ? 'window' : this === document ? 'document' : 'autre';
    window.__ec.push({ t, cap: o === true || !!(o && o.capture), cible, nom: nom() });
    return ajout.call(this, t, f, o);
  };
  window.addEventListener('keydown', (e) => { if (e.key === 'Escape') window.__interdit.push(e.defaultPrevented); }, true);
}
const lire = (f) => { try { return fs.readFileSync(f, 'utf8'); } catch { return ''; } };

await executer(chrome, async (s) => {
  const o = {};
  const cle = (key, code, vk, extra = {}) => async () => {
    for (const type of ['keyDown', 'keyUp']) {
      await s.send('Input.dispatchKeyEvent', { type, key, code, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk, ...extra });
    }
  };
  const echap = cle('Escape', 'Escape', 27), tab = cle('Tab', 'Tab', 9), tabMaj = cle('Tab', 'Tab', 9, { modifiers: 8 });
  const barre = cle('/', 'Slash', 191, { text: '/' }), p = cle('p', 'KeyP', 80, { text: 'p' }), g = cle('g', 'KeyG', 71, { text: 'g' });
  await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: `(${espion.toString()})()` });
  const charger = async (page, base = racine) => {
    await s.naviguer(`${base}/${page}?lang=en`); await s.attendre(PRET, `page prête (${page})`);
    await s.attendre("!!document.querySelector('#viewport .node')", `cartes (${page})`);
    await pause(300); await echap(); // la visite guidée s'ouvre au premier passage : Échap la ferme
    await s.attendre("!(window.VibeFlowTour && window.VibeFlowTour.active())", `visite fermée (${page})`); await pause(150);
    await s.ev('document.activeElement && document.activeElement.blur()');
  };
  const palette = "document.getElementById('palette').classList.contains('open')";
  const dansBoite = (b) => `(() => { const a = document.activeElement; return !!a && !!a.closest(${JSON.stringify(b)}); })()`;
  const poser = () => s.ev(`(() => { window.__temoin = []; window.__vue = 0; if (window.__poses) return; window.__poses = true;
    window.addEventListener('keydown', (e) => { if (e.key === 'Escape') window.__temoin.push(e.defaultPrevented); }, true);
    document.addEventListener('keydown', (e) => { if (e.key === 'Escape') window.__vue++; }); })()`);
  const relever = () => s.ev('JSON.stringify({ t: window.__temoin, v: window.__vue, i: window.__interdit })').then(JSON.parse);

  if (veut('su1')) {
    await charger('index.html'); const r = {};
    await s.ev("document.getElementById('btn-export').focus()"); await barre(); await s.attendre(palette, 'palette ouverte');
    await pause(100); await tab(); await pause(100); await echap(); await pause(300);
    r.ferme = !(await s.ev(palette)); r.retour = await s.ev('document.activeElement && document.activeElement.id');
    await s.ev("document.getElementById('pal-x').click()"); await s.attendre(`!(${palette})`, 'palette refermée'); // départ d'un état connu
    await s.ev("document.getElementById('btn-export').focus()"); await barre(); await s.attendre(palette, 'palette rouverte');
    await pause(100); await echap(); await pause(300); r.champ = !(await s.ev(palette));
    r.api = await s.ev('typeof window.VF_SURCOUCHES');
    await s.ev('window.__id = window.VF_SURCOUCHES'); const avant = await s.ev('window.__ec.length');
    await s.ev(lire(source).replace(/Floorplan/g, 'VibeFlow') || 'void 0');
    r.identite = await s.ev('!!window.VF_SURCOUCHES && window.VF_SURCOUCHES === window.__id');
    r.nouveaux = await s.ev(`window.__ec.slice(${avant}).filter((x) => x.t === 'keydown' && x.cap && x.cible === 'window').length`);
    await s.ev("document.getElementById('btn-export').focus()"); await barre(); await s.attendre(palette, 'palette (après la réévaluation)');
    await pause(100); await tab(); await echap(); await pause(300); r.rejoue = !(await s.ev(palette));
    o.su1 = r;
  }

  if (veut('su2')) {
    await charger('index.html'); const r = {}; const libres = "[...document.querySelectorAll('[inert]')].map((e) => e.id || e.tagName).join(',')";
    await s.ev("(() => { const t = document.createElement('div'); t.id = 'vf-temoin-inert'; t.setAttribute('inert', ''); document.body.appendChild(t); })()");
    r.avant = await s.ev(libres);
    await s.ev("document.getElementById('btn-export').focus()"); await s.ev("document.getElementById('btn-export').click()");
    await s.attendre("document.getElementById('modal').classList.contains('open')", 'export ouvert'); await pause(200);
    r.pendant = await s.ev("['header', 'main#stage', '#panel'].map((q) => document.querySelector(q).inert).join(',')");
    r.arrets = [];
    for (let i = 0; i < 15; i++) { await tab(); r.arrets.push(await s.ev(dansBoite('#modal .box'))); }
    await s.ev(`(() => { const b = document.querySelector('#modal .box');
      const l = [...b.querySelectorAll(${JSON.stringify(SEL)})].filter((x) => x.tabIndex >= 0); window.__l = l; l[0].focus(); })()`);
    await tabMaj(); r.maj = await s.ev('document.activeElement === window.__l[window.__l.length - 1]');
    await echap(); await pause(300);
    r.ferme = !(await s.ev("document.getElementById('modal').classList.contains('open')"));
    r.apres = await s.ev(libres); r.focus = await s.ev('document.activeElement && document.activeElement.id');
    await s.ev("document.getElementById('btn-export').focus()"); await barre(); await s.attendre(palette, 'palette ouverte (su2)'); r.pal = [];
    for (let i = 0; i < 30; i++) { await tab(); r.pal.push(await s.ev(dansBoite('#palette .box'))); }
    o.su2 = r;
  }

  if (veut('su3')) {
    await charger('index.html'); const r = {};
    const nb = `[...document.querySelectorAll('#panel ${SEL.replace(/, /g, ', #panel ')}')]
      .filter((x) => getComputedStyle(x).visibility !== 'hidden' && x.tabIndex >= 0 && !x.closest('[inert]')).length`;
    const ferme = "document.body.classList.contains('no-panel')";
    if (await s.ev(ferme)) await s.ev("document.getElementById('btn-panel').click()");
    await pause(700); r.ouvert = await s.ev(nb);
    await s.ev("(() => { const b = document.querySelector('#panel button, #panel a[href]'); if (b) b.focus(); })()");
    r.dansPanneau = await s.ev("!!document.activeElement && !!document.activeElement.closest('#panel')");
    await p(); await pause(900); r.ferme = await s.ev(ferme); r.focalisables = await s.ev(nb);
    r.focus = await s.ev('document.activeElement && document.activeElement.id');
    await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
    await charger('index.html');
    if (!(await s.ev(ferme))) await s.ev("document.getElementById('btn-panel').click()");
    await pause(300); await s.ev("document.getElementById('btn-panel').click()"); await pause(80);
    r.reduit = await s.ev("document.body.classList.contains('no-panel') ? getComputedStyle(document.getElementById('panel')).visibility : 'ouvert'");
    await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'no-preference' }] });
    o.su3 = r;
  }

  if (veut('su4')) {
    const r = {};
    await charger('index.html');
    await s.ev("VibeFlow.reveal('f:src/util.js')"); await pause(800); const sel = await s.ev('JSON.stringify(VibeFlow.state.selected)');
    await s.ev('document.activeElement && document.activeElement.blur()'); await g();
    await s.attendre("!!document.getElementById('vf-git-tiroir') && !document.getElementById('vf-git-tiroir').hidden", 'tiroir Git ouvert');
    await pause(300); await s.ev('document.activeElement && document.activeElement.blur()');
    r.dessusTiroir = await s.ev("!!window.VF_SURCOUCHES && window.VF_SURCOUCHES.dessus() === document.getElementById('vf-git-tiroir')");
    await barre(); await s.attendre(palette, 'palette sur le tiroir'); await pause(100);
    r.dessusPalette = await s.ev("!!window.VF_SURCOUCHES && window.VF_SURCOUCHES.dessus() === document.getElementById('palette')");
    await s.ev("document.getElementById('search').blur()"); await tab(); await echap(); await pause(300);
    r.palFerme = !(await s.ev(palette)); r.tiroirResteOuvert = await s.ev("!document.getElementById('vf-git-tiroir').hidden");
    await s.ev('document.activeElement && document.activeElement.blur()'); await echap(); await pause(400);
    r.tiroirFerme = await s.ev("document.getElementById('vf-git-tiroir').hidden");
    r.selGardee = (await s.ev('JSON.stringify(VibeFlow.state.selected)')) === sel;
    await echap(); await pause(400); r.selLevee = (await s.ev('VibeFlow.state.selected')) == null;
    // SU4.4 à SU4.6 : contrat Échap consommé, sur le Code puis sur l'Équipe
    for (const page of ['index.html', 'equipe.html']) {
      await charger(page); await poser(); const k = page.split('.')[0];
      await barre(); await s.attendre(palette, `palette (${k})`); await pause(100); await tab(); await pause(100);
      await echap(); await pause(300); const a = await relever();
      r[`consomme_${k}`] = { ferme: !(await s.ev(palette)), temoin: a.t, vue: a.v, interdit: a.i };
      await poser(); r[`ouverte_${k}`] = await s.ev('!!window.VF_SURCOUCHES && window.VF_SURCOUCHES.ouverte()');
      await s.ev('document.activeElement && document.activeElement.blur()'); await echap(); await pause(200); const b = await relever();
      r[`vide_${k}`] = { temoin: b.t, vue: b.v };
    }
    await charger('index.html'); const ec = await s.ev('JSON.stringify(window.__ec)').then(JSON.parse); const N = 'nom';
    const pile = ec.filter((x) => x[N] === '00-vf-surcouches.js' && x.t === 'keydown' && x.cap && x.cible === 'window');
    const rang = pile.length ? ec.indexOf(pile[0]) : -1;
    const ext = (x) => /^\d\d-/.test(x[N]) && x[N] !== '00-vf-surcouches.js' && x[N] !== '00-vf-onglets.js';
    r.ordre = { pile: pile.length, avantTout: rang >= 0 && ec.every((x, i) => !(ext(x) && i < rang)), dernier: ec.filter(ext).length };
    if (racineTerm) {
      try {
        await charger('index.html', racineTerm);
        await s.attendre("!!document.querySelector('.vf-term-pastille') && !document.querySelector('.vf-term-pastille').hidden", 'pastille du Terminal', 15000);
        await s.ev("document.querySelector('.vf-term-pastille').click()");
        await s.attendre("document.body.classList.contains('vf-term-ouvert') && !document.querySelector('.vf-term-tiroir').hidden", 'Terminal ouvert');
        await s.ev("document.querySelector('.vf-term-tiroir .vf-term-poignee').focus()"); await poser(); await echap(); await pause(300);
        const t = await relever(); r.terminal = { temoin: t.t, vue: t.v, ouverte: await s.ev('!!window.VF_SURCOUCHES && window.VF_SURCOUCHES.ouverte()') };
      } catch (e) { r.terminal = { sautee: String(e.message) }; }
    }
    o.su4 = r;
  }
  return o;
});
