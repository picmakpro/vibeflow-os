// chrome-cadrer.mjs — « Cadrer la sélection et ses voisins », touche C (80-12, FORM-11, P80-D-17/18/45/50), un vrai Chrome, sans réseau.
// Usage : node chrome-cadrer.mjs <chrome> <racine-du-serveur> <mode>
//   Rend UNE ligne JSON { ca1, ca2, erreurs } ou { erreur }. Modes : base · term (lab --terminal : zone basse à 390 et 800 px).
// Chaque section est isolée (sec) : une section qui échoue laisse ses champs vides, les autres sont mesurées. Les gestes passent par Input.dispatchKeyEvent.
import { executer, pause, stabiliser } from './chrome-session.mjs';
const [, , chrome, racine, mode] = process.argv;
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
const POSEE = "(() => { const v = document.querySelector('#viewport'); return !!v && v.style.opacity !== '0' && !v.classList.contains('anim'); })()";
const SEL = 'f:src/n05.js'; // trois voisins : n06, n07, n08 (imports)
const OUTIL = `window.__ca = {
  rect(s) { const e = typeof s === 'string' ? document.querySelector(s) : s; if (!e || !e.getClientRects().length) return null;
    const b = e.getBoundingClientRect(); return { l: b.left, t: b.top, r: b.right, b: b.bottom }; },
  coupe(a, b) { return !(a.r <= b.l || b.r <= a.l || a.b <= b.t || b.b <= a.t); },
  carte(id) { const g = VibeFlow.state.chipEls.get(id); return g && __ca.rect(g.querySelector('.card')); },
  groupe(id) { const s = new Set([id]);
    for (const x of VibeFlow.state.edgeEls.values()) { if (x.e.a === id) s.add(x.e.b); else if (x.e.b === id) s.add(x.e.a); }
    return [...s].filter((i) => VibeFlow.state.layout.children.some((c) => c.id === i)); },
  champs() { const o = document.getElementById('svg').getBoundingClientRect();
    return [].concat(window.VF_CANEVAS && VF_CANEVAS.champsDeCadrage ? VF_CANEVAS.champsDeCadrage() : [VibeFlow.freeArea()])
      .map((a) => ({ l: o.left + a.x, t: o.top + a.y, r: o.left + a.x + a.w, b: o.top + a.y + a.h })); },
  touchent(id, sels) { const L = sels.map((x) => [x, __ca.rect(x)]).filter((p) => p[1]); // les sélecteurs que touche une carte du groupe
    return __ca.groupe(id).map(__ca.carte).filter(Boolean).flatMap((c) => L.filter((p) => __ca.coupe(c, p[1])).map((p) => p[0])); },
  dedans(r, a) { return r.l >= a.l - 0.5 && r.t >= a.t - 0.5 && r.r <= a.r + 0.5 && r.b <= a.b + 0.5; },
  actives() { return document.getAnimations().filter((a) => a.playState === 'running' || a.playState === 'pending').length; } }`;
const KEYS = { c: ['KeyC', 67], escape: ['Escape', 27] };
const proche = (a, b, e) => !!a && !!b && a.every((v, i) => Math.abs(v - b[i]) <= e);
const tkxy = (t) => (t ? [t.k, t.x, t.y] : null);

await executer(chrome, async (s) => {
  const o = { erreurs: {}, ca1: {}, ca2: {} };
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  const sec = async (nom, f) => { try { await f(); } catch (e) { o.erreurs[nom] = String(e.message).slice(0, 160); } };
  const lire = async (expr) => { const v = await s.ev(expr); return v === undefined ? null : JSON.parse(v); };
  const vue = (w, h, mobile) => s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile });
  const touche = async (key, mod = 0) => { // mod : 1 Alt, 2 Ctrl, 4 ⌘, 8 Maj
    const [code, vk] = KEYS[key.toLowerCase()], text = key.length === 1 && !(mod & 7) ? key : undefined;
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
    await vue(w, h, mobile); await s.naviguer(`${racine}/${page}?lang=en`);
    if (mode === 'term') { // le tiroir du terminal se rouvre d'une page à l'autre : chaque page part tiroir fermé
      await s.ev("localStorage.removeItem('vf.terminal.open'); localStorage.removeItem('vf.terminal.h')"); await s.naviguer(`${racine}/${page}?lang=en`);
    }
    await s.attendre(PRET, `page ${page}`); await s.attendre("!!document.querySelector('#viewport .node')", `cartes ${page}`);
    await s.attendre(POSEE, `vue posée ${page}`); await stabiliser(lireVue, { pas: 120, max: 5000 }); await sansVisite();
  };
  const niveau = async () => { // le niveau de 70 fichiers, vue ajustée, la carte SEL sélectionnée sur une vue de départ qui n'est PAS son cadrage
    await s.ev(`VibeFlow.reveal(${JSON.stringify(SEL)})`);
    await s.attendre("VibeFlow.state.container !== 'root' && document.querySelectorAll('#viewport .node').length >= 70", 'niveau de 70 fichiers');
    await stabiliser(lireVue, { pas: 120, max: 5000 }); await s.ev('VibeFlow.fit(false)'); await posee();
  };
  const choisir = async () => { await s.ev('VibeFlow.fit(false)'); await s.ev(`VibeFlow.select(${JSON.stringify(SEL)})`); await posee(); };
  const onglet = async (nom) => {
    await s.ev(`VF_COQUILLE.chargerOnglet(${JSON.stringify(nom)})`); await s.attendre(PRET, `onglet ${nom}`);
    await s.attendre(POSEE, `onglet ${nom} posé`); await stabiliser(lireVue, { pas: 120, max: 5000 }); await s.ev(OUTIL);
  };
  const apres = async (mod, key = 'c') => { // la mesure d'un geste : t, mise en page, groupe attendu, cadrage de référence
    const l0 = await s.ev('JSON.stringify(VibeFlow.state.layout.children)'), t0 = await T();
    await touche(key, mod); await posee();
    return lire(`JSON.stringify({ t0: ${JSON.stringify(t0)}, t: VibeFlow.state.t,
      layout: JSON.stringify(VibeFlow.state.layout.children) === ${JSON.stringify(l0)},
      ref: VibeFlow.cadrage({ ids: __ca.groupe(${JSON.stringify(SEL)}) }), grp: __ca.groupe(${JSON.stringify(SEL)}),
      foc: document.activeElement === VibeFlow.state.chipEls.get(${JSON.stringify(SEL)}) })`);
  };

  if (mode === 'term') { // CA1.4 : zone basse à 390 et 800 px, feuille ouverte puis fermée, pastille « Terminal » comprise
    const cas = [['tactile', 390, 844, true], ['moyen', 800, 900, false]];
    for (const [cle, w, h, doigt] of cas) {
      await sec('ca14', async () => {
        await s.send('Emulation.setTouchEmulationEnabled', { enabled: doigt }); await charger('index.html', w, h, doigt); await niveau();
        const r = o.ca1[cle] = {};
        for (const ouverte of [true, false]) {
          await s.ev(`(() => { if (document.body.classList.contains('no-panel') === ${ouverte}) document.getElementById('btn-panel').click(); })()`);
          await s.attendre(`document.body.classList.contains('no-panel') === ${!ouverte}`, 'feuille'); await pause(600);
          await choisir();
          const m = await apres(0);
          const q = (x) => lire(`JSON.stringify(${x})`);
          const vers = ['#ask', ouverte ? '#panel' : '#ask'], touchent = await q(`__ca.touchent(${JSON.stringify(SEL)}, ${JSON.stringify(vers)})`);
          // le plancher 11/13 rogne un groupe plus large que le champ (écart de 80-09, ZG1.2) : alors seule la carte sélectionnée est tenue
          const tient = await q(`(() => { const ch = __ca.champs(); return __ca.groupe(${JSON.stringify(SEL)}).map(__ca.carte)
            .every((c) => c && ch.some((a) => __ca.dedans(c, a))); })()`);
          const dedans = await q(`(() => { const c = __ca.carte(${JSON.stringify(SEL)}); return __ca.champs().some((a) => __ca.dedans(c, a)); })()`);
          const sel = await q(`(() => { const c = __ca.carte(${JSON.stringify(SEL)});
            return ['#zoom', '.vf-term-pastille'].map((x) => [x, __ca.rect(x)]).filter((p) => p[1] && __ca.coupe(c, p[1])).map((p) => p[0]); })()`);
          r[ouverte ? 'ouverte' : 'fermee'] = { pastille: !!(await q("__ca.rect('.vf-term-pastille')")),
            groupeLibre: !tient || touchent.length === 0, selLibre: sel.length === 0 && dedans,
            rects: await q(`({ sel: __ca.carte(${JSON.stringify(SEL)}), champs: __ca.champs(), t: VibeFlow.state.t,
              zones: ['#ask', '#panel', '#zoom', '.vf-term-pastille'].map((x) => [x, __ca.rect(x)]) })`),
            k: Math.abs(m.t.k - m.ref.k) <= 1e-6, touche: [touchent, sel], sansRelayout: m.layout };
        }
      });
    }
    await s.send('Emulation.setTouchEmulationEnabled', { enabled: false }); return o;
  }

  await sec('ca11', async () => { // CA1.1, CA1.2, CA1.3 : Code, niveau de 70 cartes, la carte et ses trois voisins
    await charger('index.html'); await niveau(); await choisir();
    const m = await apres(0);
    const champs = await lire('JSON.stringify(__ca.champs())');
    const cartes = await lire(`JSON.stringify(__ca.groupe(${JSON.stringify(SEL)}).map(__ca.carte))`);
    o.ca1.a = { grp: m.grp.length, egal: !!m.ref && proche(tkxy(m.t), tkxy(m.ref), 1e-6), plancher: m.t.k >= 11 / 13 - 1e-9, layout: m.layout,
      dedans: cartes.every((c) => c && champs.some((a) => a && (c.l >= a.l - 0.5 && c.t >= a.t - 0.5 && c.r <= a.r + 0.5 && c.b <= a.b + 0.5))) };
    const m2 = await (async () => { await choisir(); return apres(8, 'C'); })();
    o.ca1.b = { egal: !!m2.ref && proche(tkxy(m2.t), tkxy(m2.ref), 1e-6), foc: m2.foc };
    await choisir(); await s.ev('VFGitTiroir.ouvrir()'); await s.attendre('VFGitTiroir.ouvert()', 'tiroir Git'); await pause(500);
    const m3 = await apres(0);
    o.ca1.c = await lire(`JSON.stringify((() => { const L = ['#vf-coin', '#vf-git-tiroir'].map((x) => [x, __ca.rect(x)]).filter((p) => p[1]);
      return { coin: L.some((p) => p[0] === '#vf-coin'), tiroir: L.some((p) => p[0] === '#vf-git-tiroir'),
        touchent: __ca.touchent(${JSON.stringify(SEL)}, ['#vf-coin', '#vf-git-tiroir']), changee: ${m3.t0.k !== m3.t.k || m3.t0.x !== m3.t.x} }; })())`);
    await s.ev('VFGitTiroir.fermer()');
  });
  await sec('ca21', async () => { // CA2.1 : ⌘C, Ctrl+C, Alt+C : rien ne bouge et la copie n'est pas empêchée
    await charger('index.html'); await niveau(); await choisir();
    await s.ev("window.__dp = []; window.addEventListener('keydown', (e) => window.__dp.push(e.defaultPrevented))");
    const r = [];
    for (const mod of [4, 2, 1]) { const m = await apres(mod); r.push(m.t0.k === m.t.k && m.t0.x === m.t.x && m.t0.y === m.t.y); }
    o.ca2.copie = { inchange: r, prevenue: await lire('JSON.stringify(window.__dp.some(Boolean))') };
  });
  await sec('ca22', async () => { // CA2.2 : dans un champ de saisie, « c » est tapé, la vue ne bouge pas
    await charger('index.html'); await niveau(); await choisir(); o.ca2.champs = {};
    const CHAMPS = { textarea: "document.createElement('textarea')",
      editable: "(() => { const e = document.createElement('div'); e.contentEditable = 'true'; e.style.minHeight = '20px'; return e; })()" };
    for (const [nom, fab] of Object.entries(CHAMPS)) {
      await s.ev(`(() => { const e = ${fab}; e.id = 'ca-champ'; document.body.appendChild(e);
        e.style.cssText += ';position:fixed;left:8px;top:8px;z-index:99;background:#fff;color:#000'; e.focus(); })()`);
      const m = await apres(0), texte = await s.ev("(() => { const e = document.getElementById('ca-champ'); return e.value ?? e.textContent; })()");
      o.ca2.champs[nom] = { inchange: m.t0.k === m.t.k && m.t0.x === m.t.x && m.t0.y === m.t.y, texte };
      await s.ev("document.getElementById('ca-champ').remove()");
    }
  });
  await sec('ca23', async () => { // CA2.3 : sans sélection, rien ; sur Équipe, rien
    await charger('index.html'); await niveau(); await s.ev('VibeFlow.select(null)'); await posee();
    const a = await apres(0); o.ca2.sans = a.t0.k === a.t.k && a.t0.x === a.t.x && a.t0.y === a.t.y;
    await onglet('equipe'); await s.ev('document.activeElement && document.activeElement.blur()');
    const eq = await lire('JSON.stringify({ t: VibeFlow.state.t, v: document.getElementById("viewport").style.transform })');
    await touche('c'); await pause(500);
    const eq2 = await lire('JSON.stringify({ t: VibeFlow.state.t, v: document.getElementById("viewport").style.transform })');
    o.ca2.equipe = JSON.stringify(eq) === JSON.stringify(eq2);
  });
  await sec('ca24', async () => { // CA2.4 : mouvement réduit, aucune animation après « c »
    await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
    await charger('index.html'); await niveau(); await choisir(); await touche('c');
    o.ca2.reduit = [await s.ev("matchMedia('(prefers-reduced-motion: reduce)').matches"), await s.ev('__ca.actives()')];
    await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'no-preference' }] });
  });
  await sec('ca25', async () => { // CA2.5 (A51) : un seul écouteur « keydown » du fichier après deux allers-retours d'onglet, et « c » cadre
    const AMORCE = `(() => { const A = EventTarget.prototype.addEventListener, R = EventTarget.prototype.removeEventListener; window.__ec = new Set();
      const mien = (t, c, f) => c === window && t === 'keydown' && typeof f === 'function' && String(f).includes('cadrerVoisins');
      EventTarget.prototype.addEventListener = function (t, f, op) { if (mien(t, this, f)) window.__ec.add(f); return A.call(this, t, f, op); };
      EventTarget.prototype.removeEventListener = function (t, f, op) { if (mien(t, this, f)) window.__ec.delete(f); return R.call(this, t, f, op); }; })()`;
    await s.send('Page.addScriptToEvaluateOnNewDocument', { source: AMORCE });
    await charger('index.html'); const n = [await s.ev('window.__ec.size')];
    await onglet('projet'); n.push(await s.ev('window.__ec.size')); await onglet('code'); n.push(await s.ev('window.__ec.size'));
    await onglet('projet'); await onglet('code'); n.push(await s.ev('window.__ec.size'));
    await niveau(); await choisir(); const m = await apres(0);
    o.ca2.actifs = n; o.ca2.cadre = !!m.ref && proche(tkxy(m.t), tkxy(m.ref), 1e-6);
  });
  return o;
});
