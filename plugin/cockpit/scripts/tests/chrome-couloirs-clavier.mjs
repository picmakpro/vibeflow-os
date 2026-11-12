// chrome-couloirs-clavier.mjs — mesures du clavier, du panneau par-dessus, de la zone basse, de la visite et du direct de Projet en couloirs
// (80-04, FORM-05, P80-D-29, D-43, D-50, D-51) : un vrai Chrome headless, de vraies touches, de vrais clics, de vrais touchers.
// Usage : node chrome-couloirs-clavier.mjs <chrome> <racine-du-serveur> <mode> [sections] [doublure]   Rend UNE ligne JSON { … } ou { erreur }.
// Modes : cl3a (clavier, sélection, plongée, toucher) · cl3b (panneau par-dessus, visite, direct, orphelin, bords) · cl3c (zone basse, lab lancé
// avec --terminal).
// Chaque section est isolée (sec) : une section qui échoue laisse ses champs vides, les autres sont mesurées. doublure=1 : #vf-coin posé par le
// pilote (80-05 absent).
import { executer, pause, stabiliser } from './chrome-session.mjs';
const [, , chrome, racine, mode, filtre, doublure] = process.argv;
const SEL = filtre ? new Set(filtre.split(',')) : null;
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) {"
  + " const vue = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0);"
  + " return vue ? 'true' : g.call(this, k); }; try { localStorage.removeItem('floorplan:panel'); } catch (e) { void e; } })()"; // panneau par défaut
const KEYS = { Tab: 9, ArrowRight: 39, ArrowLeft: 37, ArrowUp: 38, ArrowDown: 40, Home: 36, End: 35, Enter: 13, Space: 32, Escape: 27, Backspace: 8 };
const ETAT = `window.__cl = { etat() { const a = document.activeElement, S = VibeFlow.state;
  return JSON.stringify({ id: a && a.dataset ? a.dataset.id || null : null,
  tag: a ? a.tagName.toLowerCase() : '', hid: a ? a.id : '', ti: a ? a.getAttribute('tabindex') : null, sel: S.selected, c: S.container,
  t0: document.querySelectorAll('.vp-jalon .vp-carte[tabindex="0"]').length,
    cur: [...document.querySelectorAll('[aria-current=true]')].map((e) => e.dataset.id),
  panneau: !document.body.classList.contains('no-panel') }); } }`;
const ACTIVES = "document.getAnimations().filter((a) => a.playState === 'running' || a.playState === 'pending')"
  + ".filter((a) => !(a.effect && a.effect.target && a.effect.target.closest && a.effect.target.closest('#panel'))).length";
const COIN = "(() => { if (document.getElementById('vf-coin')) return; const d = document.createElement('div'); d.id = 'vf-coin';"
  + " d.style.cssText = 'position:absolute;right:16px;bottom:72px;width:176px;height:40px;z-index:4'; document.getElementById('stage').append(d); })()";

await executer(chrome, async (s) => {
  const o = { erreurs: {} };
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: SANS_VISITE });
  const sec = async (nom, f) => { if (SEL && !SEL.has(nom)) return; try { await f(); } catch (e) { o.erreurs[nom] = String(e.message).slice(0, 160); } };
  const lire = async (expr) => { const v = await s.ev(expr); return v === undefined ? null : JSON.parse(v); };
  const touche = async (nom, mod = 0) => {
    for (const type of ['keyDown', 'keyUp']) {
      await s.send('Input.dispatchKeyEvent', { type, key: nom === 'Space' ? ' ' : nom, code: nom, modifiers: mod, windowsVirtualKeyCode: KEYS[nom],
        nativeVirtualKeyCode: KEYS[nom] });
    }
  };
  const etat = async () => (await lire('__cl.etat()')) || {};
  const presser = async (nom, ms = 150) => { await touche(nom); await pause(ms); return etat(); };
  const point = (sel) => lire(`(() => { const e = document.querySelector(${JSON.stringify(sel)}); if (!e) return 'null';
    e.scrollIntoView({ block: 'nearest' }); const b = e.getBoundingClientRect();
    return JSON.stringify({ x: b.x + b.width / 2, y: b.y + b.height / 2 }); })()`);
  const clic = async (sel) => {
    const r = await point(sel); if (!r) throw new Error(`clic : « ${sel} » absent`);
    await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: r.x, y: r.y });
    for (const type of ['mousePressed', 'mouseReleased']) await s.send('Input.dispatchMouseEvent', { type, x: r.x, y: r.y, button: 'left', clickCount: 1 });
  };
  const toucher = async (sel) => {
    const r = await point(sel); if (!r) throw new Error(`toucher : « ${sel} » absent`);
    await s.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: r.x, y: r.y }] });
    await s.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
  };
  const carte = (id) => `.vp-carte[data-id="n:${id}"]`;
  const focus = (sel) => s.ev(`document.querySelector(${JSON.stringify(sel)}).focus()`);
  const muter = async (code) => { await s.ev(`(async () => { ${code}; await VibeFlow.rerender(); })()`); await pause(250); };
  const noeud = (id) => `VibeFlow.graph.nodes.find((n) => n.id === '${id}')`;
  const compte = "JSON.stringify([document.querySelectorAll('.vp-carte').length, document.querySelectorAll('#viewport .node').length])";
  const charger = async (qs = '', w = 1440, h = 900, tactile = false) => {
    await s.send('Emulation.setTouchEmulationEnabled', { enabled: tactile });
    await s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: tactile });
    await s.naviguer(`${racine}/project.html${qs}`, { brut: true }); await s.attendre(PRET, 'page prête');
    await stabiliser(() => s.ev(compte), { pas: 120, max: 5000 }); await s.ev(ETAT); await pause(300);
    if (doublure === '1') await s.ev(COIN);
  };

  if (mode === 'cl3a') {
    // ---------- CL3.1 à CL3.4 : un arrêt par bloc, flèches par position, sélection qui suit le focus, plongée, toucher ----------
    await sec('cl31', async () => {
      await charger('?vue=couloirs', 1024, 768);
      await focus('.vp-bascule button:last-child'); const a1 = await presser('Tab'), a2 = await presser('Tab'), suite = [];
      await focus(carte('ph-3'));
      for (const k of ['ArrowRight', 'ArrowRight', 'ArrowRight', 'ArrowLeft', 'End', 'Home', 'ArrowDown', 'ArrowDown', 'ArrowUp']) suite.push([k,
        (await presser(k)).id]);
      o.cl31 = { arret1: [a1.id, a1.t0], arret2: [a2.tag, a2.id], suite };
    });
    await sec('cl32', async () => {
      await charger('?vue=couloirs', 800, 900); const suite = [], seq = async (dep, ks) => { await focus(carte(dep));
        for (const k of ks) suite.push([k, (await presser(k)).id]); };
      await seq('ph-3', ['ArrowDown', 'ArrowDown', 'ArrowUp']); await seq('ph-4', ['ArrowDown', 'ArrowUp']);
      await muter(`${noeud('ph-6')}.st = 'done'`); await seq('ph-5', ['ArrowDown']);
      await charger('?vue=couloirs', 800, 900); await muter(`${noeud('ph-4')}.st = 'todo'`); await seq('ph-3', ['ArrowRight']);
      o.cl32 = { suite, corps: !suite.some(([, id]) => !id) };
    });
    await sec('cl33', async () => {
      await charger('?vue=couloirs', 1024, 768); await focus('.vp-bascule button:last-child'); await presser('Tab'); await presser('ArrowRight');
      const sel = await etat(), esc = await presser('Escape'), esp = await presser('Space');
      await presser('Enter', 600); await s.attendre("VibeFlow.state.container === 'n:ph-4'", 'plongée dans la phase 4'); await pause(500);
      const dedans = await etat(), retours = [];
      for (let i = 0; i < 3 && (await etat()).c !== 'root'; i++) { retours.push((await presser('Escape', 700)).c); }
      await pause(400); const dos = await etat();
      await presser('Enter', 600); await s.attendre("VibeFlow.state.container === 'n:ph-4'", 'seconde plongée'); await pause(500);
        await presser('Backspace', 700);
      await s.attendre("VibeFlow.state.container === 'root'", 'retour par Retour arrière'); await pause(400); const bs = await etat();
      await s.ev("VibeFlow.select('n:ph-4')"); await pause(300);
      await s.ev("(document.querySelector('#panel [data-open]') || document.querySelector('#panel a.row') || document.body).focus()");
      const foc = await etat(), depuis = await presser('Escape', 300);
      o.cl33 = { suit: [sel.sel, sel.cur], esc: [esc.sel, esc.id], esp: [esp.sel, esp.cur], dedans: dedans.c, retours, dos: [dos.c, dos.id],
        bs: [bs.c, bs.id], panneau: [depuis.sel, depuis.c], foc: [foc.tag, foc.sel] };
    });
    await sec('cl34', async () => {
      await charger('?vue=couloirs', 390, 844, true);
      await toucher(carte('ph-3')); await s.attendre("VibeFlow.state.selected === 'n:ph-3'", 'phase 3 sélectionnée au toucher'); await pause(400);
      const t = await etat(), ouvrir = await lire("JSON.stringify(document.querySelectorAll('#panel [data-open=\"n:ph-3\"]').length)");
      await focus(carte('ph-4')); const f = await etat(); await presser('Space'); const sp = await etat();
      await presser('Enter', 600); await s.attendre("VibeFlow.state.container === 'n:ph-4'", 'Entrée plonge au toucher'); const en = await etat();
      o.cl34 = { touch: [t.sel, t.panneau, t.c, ouvrir], focus: f.sel, espace: sp.sel, entree: en.c };
    });
  }

  if (mode === 'cl3b') {
    // ---------- CL3.5, CL3.7 à CL3.12 : panneau par-dessus, visite, direct, réveil, mouvement réduit, focus orphelin, bords latéraux ----------
    const POS = "JSON.stringify([...document.querySelectorAll('.vp-couloir')].map((c) => [c.offsetLeft, c.offsetTop, c.offsetWidth]))";
    await sec('cl35', async () => {
      await charger('?vue=couloirs'); const ouvert = await lire(POS), p0 = await etat();
      await clic('#btn-panel'); await pause(700); const ferme = await lire(POS), p1 = await etat();
      await clic('#btn-panel'); await pause(700); await s.ev("VibeFlow.select('n:ph-1')"); await pause(200);
      const m = await lire(`JSON.stringify((() => { try { const k = document.querySelector('${carte('ph-1')}'), v = document.querySelector('section.vf-projet');
        if (!k) return { absente: true, cartes: document.querySelectorAll('.vp-carte').length, forme: window.VF_PROJET && VF_PROJET.forme() };
        const c = k.getBoundingClientRect(), p = document.getElementById('panel').getBoundingClientRect();
        return { hors: c.right <= p.left + 0.5, gauche: c.left >= 0, defile: v.scrollLeft, mode: getComputedStyle(v).scrollBehavior };
          } catch (e) { return { err: e.message }; } })())`);
      o.cl35 = { ouvert, ferme, panneaux: [p0.panneau, p1.panneau], m, actives: await s.ev(ACTIVES) };
    });
    await sec('cl313', async () => { // 800 px, graphe, panneau ouvert : la bascule flottante ne chevauche pas le panneau
      await charger('?vue=graphe', 800, 900);
      if (await s.ev("document.body.classList.contains('no-panel')")) { await clic('#btn-panel'); await pause(700); }
      o.cl313 = await lire(`JSON.stringify((() => { const f = document.getElementById('vf-projet-flottant').getBoundingClientRect(),
        p = document.getElementById('panel').getBoundingClientRect(); return { fl: [f.left, f.right], panneau: [p.left, p.right],
        ouvert: !document.body.classList.contains('no-panel') }; })())`);
    });
    await sec('cl37', async () => {
      await charger('?vue=couloirs');
      const lire2 = () => lire("JSON.stringify({ f: VF_PROJET.forme(), actif: VibeFlowTour.active(), "
        + "svg: getComputedStyle(document.getElementById('svg')).visibility })");
      await clic('#tour-btn'); await s.attendre('VibeFlowTour.active()', 'visite ouverte'); const clicOuvre = await lire2();
      await s.ev('VibeFlowTour.end()'); await s.attendre("VF_PROJET.forme() === 'couloirs'", 'forme revenue'); const clicFin = await lire2();
      await s.ev('VibeFlowTour.start()'); await s.attendre('VibeFlowTour.active()', 'visite démarrée sans clic'); await pause(300); const auto = await lire2();
      await s.ev('VibeFlowTour.end()'); await s.attendre("VF_PROJET.forme() === 'couloirs'", 'forme revenue (démarrage sans clic)');
      o.cl37 = { clicOuvre, clicFin, auto, fin: (await lire2()).f, url: await s.ev('location.search') };
    });
    await sec('cl38', async () => {
      await charger('?vue=couloirs', 1024, 500); await s.ev("document.querySelector('[data-cle=backlog]').open = true"); await pause(150);
      await focus(carte('ph-3')); await pause(150);
      await s.ev("document.querySelector('section.vf-projet').scrollTop = 120"); await pause(100);
      const av = await lire("JSON.stringify([document.querySelector('section.vf-projet').scrollTop, document.querySelector('section.vf-projet').scrollLeft])");
      await muter(`${noeud('ph-3')}.st = 'recette'`);
      const e = await etat(), apres = await lire(`JSON.stringify([document.querySelector('section.vf-projet').scrollTop,
        document.querySelector('section.vf-projet').scrollLeft,
        document.querySelector('[data-cle=backlog]').open, document.querySelector('${carte('ph-3')}').closest('.vp-couloir').dataset.couloir,
        document.querySelector('${carte('ph-3')}').getAttribute('tabindex'), document.querySelector('.vp-status').textContent])`);
      o.cl38 = { id: e.id, cur: e.cur, av, apres };
    });
    await sec('cl39', async () => {
      await charger('?vue=couloirs');
      await s.ev("VibeFlow.addPanelSection('overview', () => '<div id=\"vf-test-ov\">section du pilote</div>')");
      await s.ev("VibeFlow.reveal('n:ph-2')"); await s.attendre("VibeFlow.state.selected === 'n:ph-2'", 'phase 2 révélée'); await pause(600);
      const r = await etat(); await s.ev('VibeFlow.select(null)'); await pause(300);
      const ov = await lire(`JSON.stringify((() => { const p = document.getElementById('panel'), l = p.lastElementChild;
        return { dernier: !!l && !!l.querySelector('#vf-test-ov'), avant: !!p.firstElementChild && !p.firstElementChild.querySelector('#vf-test-ov') }; })())`);
      o.cl39 = { c: r.c, sel: r.sel, cur: r.cur, ov };
    });
    await sec('cl310', async () => {
      await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
      await charger('?vue=couloirs'); o.cl310 = { charge: await s.ev(ACTIVES) };
      await clic(carte('ph-3')); await pause(500); o.cl310.selection = await s.ev(ACTIVES);
      await presser('Enter', 700); await s.attendre("VibeFlow.state.container === 'n:ph-3'", 'plongée'); await pause(600);
        o.cl310.plongee = await s.ev(ACTIVES);
      await presser('Backspace', 700); await s.attendre("VibeFlow.state.container === 'root'", 'remontée'); await pause(600);
        o.cl310.remontee = await s.ev(ACTIVES);
      await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'no-preference' }] });
    });
    // CL3.11 : le contrôle focalisé disparaît au redessin ; `retirer` retire des nœuds ou des fichiers du graphe puis relit
    const retirer = async (focalise, code) => { await charger('?vue=couloirs');
      await s.ev("document.querySelector('[data-cle=backlog]').open = true"); await pause(150);
      if (focalise) await focus(focalise); await pause(150); await muter(code); return etat(); };
    const RETIRE = (id) => `const G = VibeFlow.graph; G.nodes.splice(G.nodes.findIndex((n) => n.id === '${id}'), 1)`;
    const FICHIER = (i) => `const G = VibeFlow.graph, f = G.files.filter((x) => x.n === 'backlog')[${i}]; G.files.splice(G.files.indexOf(f), 1)`;
    await sec('cl311', async () => {
      o.cl311 = { a: await retirer(carte('ph-4'), RETIRE('ph-4')), b: await retirer(carte('ph-2'), RETIRE('ph-2')) };
      const rang = '[data-cle=backlog] .vp-rangee'; await charger('?vue=couloirs');
        await s.ev("document.querySelector('[data-cle=backlog]').open = true"); await pause(150);
      await focus(rang); await pause(100); await muter(FICHIER(0)); const c1 = await etat(); await muter(FICHIER(0)); const c2 = await etat();
      o.cl311.c = { suivante: c1, derniere: c2 };
      await charger('?vue=couloirs'); await s.ev("document.querySelector('[data-cle=backlog]').open = true"); await pause(150);
      await s.ev("VibeFlow.select('n:ph-3')"); await focus(rang); await pause(100); await muter(FICHIER(0)); await muter(FICHIER(0));
        o.cl311.cSel = await etat();
      o.cl311.d = await retirer(carte('ph-4'),
        "const G = VibeFlow.graph; G.nodes = G.nodes.filter((n) => !(n.parent === 'ms-v2.0-couloirs' && n.kind === 'phase'))");
      await charger('?vue=couloirs'); await focus('#ask-input'); await muter(RETIRE('ph-4')); o.cl311.champ = await etat();
    });
    await sec('cl312', async () => {
      const MES = `JSON.stringify((() => { const v = document.querySelector('section.vf-projet'), cs = getComputedStyle(v),
        t = document.querySelector('#vf-git-tiroir, .vf-git-tiroir'),
        tr = t && !t.hidden && t.offsetWidth ? t.getBoundingClientRect() : null, a = document.activeElement.closest('.vp-carte'),
          c = a ? a.getBoundingClientRect() : null,
        p = document.getElementById('panel').getBoundingClientRect(), fermee = document.body.classList.contains('no-panel');
        return { debut: cs.scrollPaddingInlineStart, fin: cs.scrollPaddingInlineEnd,
          pw: fermee ? 0 : innerWidth - p.left,
          tiroir: tr ? [tr.left, tr.right] : null, carte: c ? [c.left, c.right] : null, panneau: fermee ? null : [p.left, p.right],
            larg: v.scrollWidth <= v.clientWidth }; })())`;
      for (const [cle, w, h, tactile] of [['1440', 1440, 900, false], ['1024', 1024, 768, false], ['800', 800, 900, false], ['390', 390, 844, true],
        ['1100t', 1100, 800, true]]) {
        await charger('?vue=couloirs', w, h, tactile); const r = {};
        r.repos = await lire(MES); await focus(carte('ph-1')); await s.ev("VibeFlow.select('n:ph-1')"); await pause(300); r.panneau = await lire(MES);
        if (await s.ev('!!window.VFGitTiroir')) {
          await s.ev('VFGitTiroir.ouvrir()'); await pause(500); await focus(carte('ph-4')); await presser('ArrowLeft'); await pause(300);
            r.tiroir = await lire(MES);
          await s.ev('VFGitTiroir.fermer(true)'); await pause(400); r.ferme = await lire(MES);
        }
        o['cl312' + cle] = r;
      }
    });
  }

  if (mode === 'cl3c') {
    // ---------- CL3.6 : zone basse (80-UI-SPEC § 3) : #ask, #vf-coin, pastille « Terminal », feuille de détail, tiroir du terminal ----------
    const FILL = "(async () => { const G = VibeFlow.graph, b = G.nodes.find((n) => n.id === 'ph-1');"
      + " for (let i = 0; i < 24; i++) G.nodes.push({ ...b, id: 'ph-9' + i,"
      + " label: 'Phase 9' + i + ' · Remplissage ' + i, num: '9' + i }); await VibeFlow.rerender(); })()";
    const MESURE = `(() => { const R = (e) => { if (!e || e.hidden) return null; const b = e.getBoundingClientRect(); return b.width > 0
      && b.height > 0 ? { left: b.left, right: b.right, top: b.top,
        bottom: b.bottom, h: b.height } : null; }, v = document.querySelector('section.vf-projet'), cs = getComputedStyle(v),
          a = document.activeElement, k = a && a.closest ? a.closest('.vp-carte') : null;
      const o = { ask: R(document.getElementById('ask')), coin: R(document.getElementById('vf-coin')), pastille: R(document.querySelector('.vf-term-pastille')),
        tiroirTerm: R(document.querySelector('.vf-term-tiroir')), feuille: (() => { const p = document.getElementById('panel'),
          r = !document.body.classList.contains('no-panel') && R(p);
          return r && r.right - r.left >= document.getElementById('stage').getBoundingClientRect().width * 0.8 ? r : null; })() };
      const c = k ? R(k) : null, dock = R(document.getElementById('stage')).bottom < innerHeight - 1, inter = Object.keys(o).filter((n) => c && o[n]
        && (n !== 'tiroirTerm' || dock) && c.left < o[n].right && c.right > o[n].left && c.top < o[n].bottom
        && c.bottom > o[n].top);
      return JSON.stringify({ pb: parseFloat(cs.paddingBottom), spb: parseFloat(cs.scrollPaddingBlockEnd), id: k ? k.dataset.id : null,
        haut: v.scrollHeight > v.clientHeight, inter,
        somme: ['ask', 'coin', 'pastille', 'feuille'].reduce((n, x) => n + (o[x] ? o[x].h : 0), 0), vus: Object.keys(o).filter((n) => o[n]), dock, c,
          o }); })()`;
    o.cl36 = {};
    for (const [cle, w, h, tactile] of [['1440', 1440, 900, false], ['1024', 1024, 768, false], ['390', 390, 844, true], ['800', 800, 900, false],
      ['1100t', 1100, 800, true]]) {
      await sec('cl36' + cle, async () => {
        await charger('?vue=couloirs', w, h, tactile); await s.ev(FILL); await pause(300); const r = {};
        const mesurer = async (nom) => { await focus('.vp-carte[tabindex="0"]'); await presser('End', 400); r[nom] = await lire(MESURE); };
        await mesurer('base');
        if (w < 1100 || tactile) { await s.ev("VibeFlow.select('n:ph-3')"); await pause(500); await mesurer('feuille');
          await s.ev('VibeFlow.select(null)'); await pause(200); }
        if (await s.ev('!!window.VFGitTiroir')) { await s.ev('VFGitTiroir.ouvrir()'); await pause(500); await mesurer('git');
          await s.ev('VFGitTiroir.fermer(true)'); await pause(400); }
        await s.ev("document.querySelector('.vf-term-pastille').click()");
          await s.attendre("document.body.classList.contains('vf-term-ouvert') && !document.querySelector('.vf-term-tiroir').hidden", 'terminal ouvert');
        await pause(600); await mesurer('terminal');
        await s.ev("document.querySelector('.vf-term-tiroir button[aria-label^=\"Fermer\"]').click()");
          await s.attendre("!document.body.classList.contains('vf-term-ouvert')", 'terminal refermé');
        await pause(500); await mesurer('ferme'); o.cl36[cle] = r;
      });
    }
  }
  return o;
});
