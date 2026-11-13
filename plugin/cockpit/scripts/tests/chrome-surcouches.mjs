// chrome-surcouches.mjs — mesures de la pile de surcouches (80-02 : FORM-02, AUDC-M6), dans un vrai Chrome sans tête.
// Usage : node chrome-surcouches.mjs <chrome> <racine> <source-pile> [<racine-terminal>] [<sections>]
//   <source-pile> : texte du module ui/00-vf-surcouches.js (SU1.3 le réévalue) ; <sections> : su1,su2,su3,su4,su6,su7 (défaut : toutes).
// Rend une ligne JSON { su1, su2, su3, su4, su6, su7 } ; chaque section est lisible seule (su6 : la coquille de la 79, deux allers-retours Code / Projet).
import fs from 'node:fs';
import { executer, pause } from './chrome-session.mjs';
const [, , chrome, racine, source, racineTerm, quoi = 'su1,su2,su3,su4,su7'] = process.argv;
const veut = (k) => quoi.split(',').includes(k);
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlow.state && !!window.VibeFlow.state.layout";
const SEL = "a[href], button, input, select, textarea, summary, [tabindex]";

// posé avant tout script de la page : journal des écouteurs (type, capture, cible, fichier de l'extension qui l'a posé) + écouteur du « cas interdit »
function espion() {
  window.__ec = []; window.__interdit = []; window.__su6 = null; // __su6 : posée AVANT toute portée d'onglet, donc jamais défaite par la coquille
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
    await pause(1300); // la visite guidée démarre seule 700 ms après `ready` au premier passage : on la laisse venir, puis Échap la ferme
    if (!o.auto) {
      o.auto = JSON.parse(await s.ev(`JSON.stringify({ actif: !!(window.VibeFlowTour && window.VibeFlowTour.active()),
        inert: document.querySelectorAll('[inert]').length })`));
    }
    if (await s.ev('!!(window.VibeFlowTour && window.VibeFlowTour.active())')) await echap();
    await s.attendre("!(window.VibeFlowTour && window.VibeFlowTour.active())", `visite fermée (${page})`); await pause(300);
    await s.ev('document.activeElement && document.activeElement.blur()');
  };
  const palette = "document.getElementById('palette').classList.contains('open')";
  const dansBoite = (b) => `(() => { const a = document.activeElement; return !!a && !!a.closest(${JSON.stringify(b)}); })()`;
  const entree = cle('Enter', 'Enter', 13, { text: '\r' });
  const inerts = "[...document.querySelectorAll('[inert]')].map((e) => e.id || e.tagName).join(',')";
  const clic = async (sel) => {
    const lire = `(() => { const b = document.querySelector(${JSON.stringify(sel)}).getBoundingClientRect();
      return JSON.stringify([b.x + b.width / 2, b.y + b.height / 2]); })()`;
    const [x, y] = JSON.parse(await s.ev(lire));
    for (const type of ['mousePressed', 'mouseReleased']) await s.send('Input.dispatchMouseEvent', { type, x, y, button: 'left', clickCount: 1 });
  };
  const poser = () => s.ev(`(() => { window.__temoin = []; window.__vue = 0; if (window.__poses) return; window.__poses = true;
    window.addEventListener('keydown', (e) => { if (e.key === 'Escape') window.__temoin.push(e.defaultPrevented); }, true);
    document.addEventListener('keydown', (e) => { if (e.key === 'Escape') window.__vue++; }); })()`);
  const relever = () => s.ev('JSON.stringify({ t: window.__temoin, v: window.__vue, i: window.__interdit })').then(JSON.parse);

  if (veut('su1')) {
    await charger('index.html'); const r = {};
    await s.ev("document.getElementById('btn-export').focus()"); await barre(); await s.attendre(palette, 'palette ouverte');
    await pause(100); await tab(); await s.ev('document.activeElement.blur()'); await pause(100); // focus hors du champ (la croix n'existe qu'au toucher)
    await echap(); await pause(300);
    r.ferme = !(await s.ev(palette)); r.retour = await s.ev('document.activeElement && document.activeElement.id');
    await s.ev("document.getElementById('pal-x').click()"); await s.attendre(`!(${palette})`, 'palette refermée'); // départ d'un état connu
    await s.ev("document.getElementById('btn-export').focus()"); await barre(); await s.attendre(palette, 'palette rouverte');
    await pause(100); await echap(); await pause(300); r.champ = !(await s.ev(palette));
    r.api = await s.ev('typeof window.VF_SURCOUCHES');
    await s.ev('window.__id = window.VF_SURCOUCHES'); const avant = await s.ev('window.__ec.length');
    const src = lire(source); if (!src.trim()) throw new Error(`module des surcouches illisible ou vide (${source}) : SU1.3 ne prouverait rien`);
    await s.ev(src.replace(/Floorplan/g, 'VibeFlow'));
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
    if (await s.ev(ferme)) await s.ev("document.getElementById('btn-panel').click()");
    await pause(700); await s.ev("document.getElementById('btn-panel').click()"); await pause(80);
    r.reduit = await s.ev("document.body.classList.contains('no-panel') ? getComputedStyle(document.getElementById('panel')).visibility : 'ouvert'");
    await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'no-preference' }] });
    o.su3 = r;
  }

  if (veut('su4') || veut('su4i')) { // su4i : Code seulement (les mutants tournent sur une copie sans session d'équipe)
    const r = {};
    await charger('index.html');
    await s.ev("VibeFlow.reveal('f:src/util.js')"); await pause(800); const sel = await s.ev('JSON.stringify(VibeFlow.state.selected)');
    await s.ev('document.activeElement && document.activeElement.blur()'); await g();
    await s.attendre("!!document.getElementById('vf-git-tiroir') && !document.getElementById('vf-git-tiroir').hidden", 'tiroir Git ouvert');
    await pause(300); await s.ev('document.activeElement && document.activeElement.blur()');
    r.dessusTiroir = await s.ev("!!window.VF_SURCOUCHES && window.VF_SURCOUCHES.dessus() === document.getElementById('vf-git-tiroir')");
    await barre(); await s.attendre(palette, 'palette sur le tiroir'); await pause(100);
    r.dessusPalette = await s.ev("!!window.VF_SURCOUCHES && window.VF_SURCOUCHES.dessus() === document.getElementById('palette')");
    await s.ev("document.getElementById('search').blur()"); await tab(); await s.ev('document.activeElement.blur()'); await echap(); await pause(300);
    r.palFerme = !(await s.ev(palette)); r.tiroirResteOuvert = await s.ev("!document.getElementById('vf-git-tiroir').hidden");
    await s.ev('document.activeElement && document.activeElement.blur()');
    if (process.env.SU_DIAG) { // mise au point seulement
      r.diag = await s.ev('JSON.stringify({ a: document.activeElement.tagName, o: window.VF_SURCOUCHES.ouverte() })');
    }
    await echap(); await pause(400);
    r.tiroirFerme = await s.ev("document.getElementById('vf-git-tiroir').hidden");
    r.selGardee = (await s.ev('JSON.stringify(VibeFlow.state.selected)')) === sel;
    await s.ev('document.activeElement && document.activeElement.blur()'); await echap(); await pause(400); // le tiroir a rendu le focus à son ouvreur
    r.selLevee = (await s.ev('VibeFlow.state.selected')) == null;
    // SU4.4 à SU4.6 : contrat Échap consommé, sur le Code puis sur l'Équipe
    for (const page of veut('su4i') ? ['index.html'] : ['index.html', 'equipe.html']) {
      await charger(page); await poser(); const k = page.split('.')[0];
      await barre(); await s.attendre(palette, `palette (${k})`); await pause(100); await tab(); await s.ev('document.activeElement.blur()'); await pause(100);
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
        const t = await relever(); r.terminal = { temoin: t.t, vue: t.v, ouverte: await s.ev('!!window.VF_SURCOUCHES && window.VF_SURCOUCHES.ouverte()'),
          dessus: await s.ev('(() => { const d = window.VF_SURCOUCHES.dessus(); return d ? d.tagName + "#" + d.id + "." + d.className : null; })()') };
      } catch (e) { r.terminal = { sautee: String(e.message) }; }
    }
    o.su4 = r;
  }
  if (veut('su6')) { // coquille de la 79 : la pile est un persistant ; deux allers-retours Code / Projet ne la recréent pas, ne doublent pas son écouteur
    const r = {}; const tiroir = "document.getElementById('vf-git-tiroir')";
    await charger('index.html', racineTerm || racine);
    await s.ev('window.__su6 = window.VF_SURCOUCHES; window.VFGitTiroir.ouvrir(); 1');
    await s.attendre(`!!${tiroir} && !${tiroir}.hidden`, 'tiroir Git ouvert avant le départ');
    r.avant = await s.ev(`!!window.VF_SURCOUCHES && window.VF_SURCOUCHES.dessus() === ${tiroir}`);
    for (const nom of ['projet', 'code', 'projet', 'code']) { await s.ev(`VF_COQUILLE.chargerOnglet('${nom}').then(() => 1)`); await pause(300); }
    await s.attendre("!!window.VibeFlow && !!window.VibeFlow.state && !!window.VibeFlow.state.layout", 'moteur rendu sur Code');
    const ec = await s.ev('JSON.stringify(window.__ec)').then(JSON.parse), N = 'nom';
    r.pile = ec.filter((x) => x[N] === '00-vf-surcouches.js' && x.t === 'keydown' && x.cap && x.cible === 'window').length;
    r.identite = await s.ev('!!window.__su6 && window.VF_SURCOUCHES === window.__su6');
    r.onglet = await s.ev('window.VF_COQUILLE.onglet()');
    r.retire = await s.ev(`${tiroir}.hidden === true && !window.VF_SURCOUCHES.ouverte() && window.VF_SURCOUCHES.dessus() === null`);
    if (racineTerm) { // le Terminal, posé une fois : ouvert (ou resté ouvert), un Échap dans sa région passe intact à la vue
      try {
        if (!(await s.ev("document.body.classList.contains('vf-term-ouvert')"))) {
          await s.attendre("!!document.querySelector('.vf-term-pastille') && !document.querySelector('.vf-term-pastille').hidden", 'pastille', 15000);
          await s.ev("document.querySelector('.vf-term-pastille').click()");
        }
        await s.attendre("document.body.classList.contains('vf-term-ouvert') && !document.querySelector('.vf-term-tiroir').hidden", 'Terminal ouvert');
        await s.ev("document.querySelector('.vf-term-tiroir .vf-term-poignee').focus()"); await poser(); await echap(); await pause(300);
        const q = await relever(); r.terminal = { temoin: q.t, vue: q.v };
      } catch (e) { r.terminal = { sautee: String(e.message) }; }
    }
    o.su6 = r;
  }
  if (veut('su7')) { // corrections de la revue : inert qui reste, deux propriétaires, tiroirs couverts, gardes d'Échap, visite modale
    const r = {}; const tiroirOuvert = "!document.getElementById('vf-git-tiroir').hidden";
    await charger('index.html'); await s.ev("document.getElementById('btn-export').focus()"); await barre(); await s.attendre(palette, 'palette (su7)');
    await pause(150); await s.send('Input.insertText', { text: 'zzzzqq' }); await pause(150); await entree(); await pause(300);
    r.entree = { ouverte: await s.ev(palette), inert: await s.ev(inerts) };
    await clic('#results'); await pause(300); r.clic = { ouverte: await s.ev(palette), inert: await s.ev(inerts) };
    await echap(); await pause(300); r.fin = { ouverte: await s.ev(palette), inert: await s.ev(inerts) };
    await barre(); await s.attendre(palette, 'palette (su7 b)'); await pause(150);
    await s.ev(`(() => { document.getElementById('pal-x').click();
      window.VibeFlow.modal({ title: 'T', html: '<p>x</p><button id="zz">b</button>' }); })()`); await pause(400);
    r.deux = { inert: await s.ev(inerts), modale: await s.ev("document.getElementById('modal').classList.contains('open')") };
    await echap(); await pause(400); r.deuxFin = await s.ev(inerts);
    // deux tiroirs : « Au travail » puis Git, focus dans « Au travail », Échap
    await charger('index.html'); await s.ev("document.getElementById('vf-lock').click()"); await pause(600);
    await s.ev('document.activeElement && document.activeElement.blur()'); await g(); await pause(500);
    await s.ev("(() => { const h = document.querySelector('#panel > .vf-whop h3'); h.tabIndex = -1; h.focus(); })()"); await pause(100);
    await echap(); await pause(400);
    r.tiroirs = await s.ev(`JSON.stringify({ git: ${tiroirOuvert},
      whop: !!document.querySelector('#panel > .vf-whop') && !document.body.classList.contains('no-panel') })`);
    // gardes d'Échap : tiroir Git ouvert, focus sur body, un parcours / une bulle ; focus sur un bouton ; le tiroir doit rester
    await charger('index.html'); await s.ev('document.activeElement && document.activeElement.blur()'); await g(); await pause(500);
    const garde = async (prepare, defait) => {
      await s.ev('document.activeElement && document.activeElement.blur()'); await s.ev(prepare); await echap(); await pause(300);
      const ouvert = await s.ev(tiroirOuvert); await s.ev(defait); return ouvert;
    };
    r.flux = await garde('window.VibeFlow.state.flow = { faux: true }', 'window.VibeFlow.state.flow = null');
    r.bulle = await garde("(() => { const b = document.createElement('div'); b.id = 'zz-bulle'; b.className = 'vf-git-bulle';"
      + " document.body.appendChild(b); })()",
      "document.getElementById('zz-bulle').remove()");
    r.rien = await garde("document.getElementById('btn-export').focus()", 'void 0');
    // un dialogue non modal visible (la feuille du téléphone) n'est pas une surcouche
    await s.send('Emulation.setDeviceMetricsOverride', { width: 600, height: 900, deviceScaleFactor: 1, mobile: false });
    await charger('index.html'); await s.ev("VibeFlow.reveal('f:src/util.js')"); await pause(900);
    r.feuille = await s.ev(`JSON.stringify({ role: document.getElementById('panel').getAttribute('role') + ':'
      + !!document.getElementById('panel').getClientRects().length,
      ouverte: !!window.VF_SURCOUCHES && window.VF_SURCOUCHES.ouverte() })`);
    await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
    // retour du focus à l'ouvreur d'une modale inscrite par l'API
    await charger('index.html');
    r.rendre = await s.ev(`(() => { const o = document.createElement('button'), d = document.createElement('div'), i = document.createElement('button');
      o.id = 'zz-o'; document.body.appendChild(o); d.appendChild(i); document.body.appendChild(d); o.focus();
      window.VF_SURCOUCHES.ouvrir(d, { modale: true, ouvreur: o }); i.focus(); window.VF_SURCOUCHES.fermer(d); return document.activeElement === o; })()`);
    // visite ouverte par son bouton : modale ; d'elle-même : non modale
    await charger('index.html'); await s.ev("document.getElementById('tour-btn').click()"); await pause(900);
    r.tour = { actif: await s.ev('!!(window.VibeFlowTour && window.VibeFlowTour.active())'), inert: await s.ev(inerts), arrets: [] };
    for (let i = 0; i < 25; i++) { await tab(); r.tour.arrets.push(await s.ev("!!document.activeElement.closest('#tour')")); }
    await echap(); await pause(500); r.tour.fin = { actif: await s.ev('!!(window.VibeFlowTour && window.VibeFlowTour.active())'), inert: await s.ev(inerts) };
    o.su7 = r;
  }
  return o;
});
