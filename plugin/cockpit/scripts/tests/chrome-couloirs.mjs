// chrome-couloirs.mjs — mesures de Projet en couloirs (80-04, FORM-05, FORM-07) dans un vrai Chrome headless, de vraies touches et de vrais clics.
// Usage : node chrome-couloirs.mjs <chrome> <racine-du-serveur> <mode>   Rend UNE ligne JSON { … } ou { erreur }. Un mode = un Chrome : cl1, cl2,
// cl3a, cl3b, cl3c.
// Chaque section est isolée (sec) : une section qui échoue (module absent ou muté) laisse ses champs vides, les autres sont mesurées.
import { executer, pause, stabiliser } from './chrome-session.mjs';
const [, , chrome, racine, mode, filtre] = process.argv; // filtre : sections à mesurer (ex. « cl23,cl26 »), sinon toutes celles du mode
const SEL = filtre ? new Set(filtre.split(',')) : null;
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
// la visite du premier passage s'ouvre d'elle-même (40-tour.js : « tour-seen », 75-vf-modele.js : « vibeflow-cockpit:visite ») : ces clés sont lues
// comme posées
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) {"
  + " const vue = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0);"
  + " return vue ? 'true' : g.call(this, k); }; })()";
const KEYS = { Tab: 9, ArrowRight: 39, ArrowLeft: 37, ArrowUp: 38, ArrowDown: 40, Home: 36, End: 35, Enter: 13, Space: 32, Escape: 27, Backspace: 8 };

await executer(chrome, async (s) => {
  const o = { erreurs: {} };
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: SANS_VISITE });
  const sec = async (nom, f) => { if (SEL && !SEL.has(nom)) return; try { await f(); } catch (e) { o.erreurs[nom] = String(e.message).slice(0, 160); } };
  const lire = async (expr) => { const v = await s.ev(expr); return v === undefined ? null : JSON.parse(v); };
  const vue = (w, h, tactile = false, dsf = 1) => s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: dsf,
    mobile: tactile });
  const touche = async (nom) => {
    for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key: nom === 'Space' ? ' ' : nom, code: nom,
      windowsVirtualKeyCode: KEYS[nom], nativeVirtualKeyCode: KEYS[nom] });
  };
  const clic = async (sel) => {
    const r = await lire(`(() => { const e = document.querySelector(${JSON.stringify(sel)}); if (!e) return 'null';
      const b = e.getBoundingClientRect(); return JSON.stringify({ x: b.x + b.width / 2, y: b.y + b.height / 2 }); })()`);
    if (!r) throw new Error(`clic : « ${sel} » absent`);
    await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: r.x, y: r.y });
    for (const type of ['mousePressed', 'mouseReleased']) await s.send('Input.dispatchMouseEvent', { type, x: r.x, y: r.y, button: 'left', clickCount: 1 });
  };
  const compte = "JSON.stringify([document.querySelectorAll('.vp-carte').length, document.querySelectorAll('#viewport .node').length])";
  const charger = async (qs = '', w = 1440, h = 900, tactile = false, brut = true, dsf = 1) => {
    await s.send('Emulation.setTouchEmulationEnabled', { enabled: tactile }); await vue(w, h, tactile, dsf);
    await s.naviguer(`${racine}/project.html${qs}`, { brut }); await s.attendre(PRET, 'page prête');
    await stabiliser(() => s.ev(compte), { pas: 120, max: 5000 }); await pause(300);
  };

  if (mode === 'cl1') {
    // ---------- CL1 : forme par défaut, graphe à la demande, section du panneau, adresse de naviguer ----------
    await sec('cl11', async () => {
      await charger();
      o.cl11 = await lire(`JSON.stringify({ groupes: (document.querySelector('.vp-jalon') || document.body).querySelectorAll('[role=group]').length,
        svg: getComputedStyle(document.getElementById('svg')).visibility, jalons: document.querySelectorAll('.vp-jalon').length })`);
    });
    await sec('cl12', async () => {
      await charger('?vue=graphe');
      o.cl12 = await lire(`JSON.stringify({ svg: getComputedStyle(document.getElementById('svg')).visibility,
        cartes: document.querySelectorAll('#viewport .node').length,
        vue: (() => { const v = document.querySelector('section.vf-projet'); return !v || getComputedStyle(v).display === 'none' || v.hidden; })() })`);
    });
    await sec('cl13', async () => {
      await charger();
      await s.ev("VibeFlow.addPanelSection('item', (c) => { window.__cible = c; return '<div id=\"vf-test-sec\">section du pilote</div>'; })");
      await clic('.vp-carte[data-id=\"n:ph-3\"]'); await s.attendre("!!document.querySelector('#panel #vf-test-sec')", 'section de panneau');
      o.cl13 = await lire("JSON.stringify({ dans: !!document.querySelector('#panel #vf-test-sec'), cible: window.__cible })");
    });
    await sec('cl14', async () => {
      await s.naviguer(`${racine}/project.html#s=x`); await s.attendre(PRET, 'page prête (cl14)');
      o.cl14 = await lire('JSON.stringify([location.search, location.hash])');
      await s.naviguer(`${racine}/project.html?vue=couloirs#s=x`); await s.attendre(PRET, 'page prête (cl14b)');
      o.cl14b = await lire('JSON.stringify([location.search, location.hash])');
    });
    await sec('cl15', async () => { // 390 px : rien du canevas caché ne doit rester visible (00-vibeflow.js force `visibility: visible` sur des pieds)
      await charger('?vue=couloirs', 390, 844, true);
      o.cl15 = await lire("JSON.stringify({ visibles: [...document.querySelectorAll('#svg *')]"
        + ".filter((e) => getComputedStyle(e).visibility === 'visible').length })");
    });
    await sec('cl16', async () => { // la bascule : le focus va au segment équivalent du groupe visible, l'annonce vit hors du conteneur masqué
      await charger();
      const etat = `JSON.stringify({ id: document.activeElement.dataset.forme || null, flottant: !!document.activeElement.closest('#vf-projet-flottant'),
        texte: document.querySelector('.vp-status') ? document.querySelector('.vp-status').textContent : null,
        dansSection: !!document.querySelector('section.vf-projet .vp-status') })`;
      await clic('.vp-bascule [data-forme=graphe]'); await pause(300); o.cl16 = { vers: await lire(etat) };
      await clic('#vf-projet-flottant [data-forme=couloirs]'); await pause(300); o.cl16.retour = await lire(etat);
    });
  }

  // rend le graphe muté puis relu par la vue : `code` modifie VibeFlow.graph, la vue se redessine sur `render`
  const muter = async (code) => { await s.ev(`(async () => { ${code}; await VibeFlow.rerender(); })()`); await pause(250); };
  const COULEUR = "((v) => { const e = document.createElement('i'); e.style.color = `var(${v})`; document.body.append(e);"
    + " const c = getComputedStyle(e).color; e.remove(); return c; })";
  const NID = (id) => `VibeFlow.graph.nodes.find((n) => n.id === '${id}')`;
  const jalon = `(() => { const j = document.querySelector('.vp-jalon'), b = j.querySelector('[role=progressbar]'), i = b.querySelector('i');
    return { synth: j.querySelector('.vp-syn').textContent, now: b.getAttribute('aria-valuenow'), larg: i.style.width,
      pc: j.querySelector('.vp-pc').textContent,
      pcMasque: j.querySelector('.vp-pc').getAttribute('aria-hidden'), fond: getComputedStyle(i).backgroundColor,
        avertissement: ${COULEUR}('--warn-text'), neutre: ${COULEUR}('--text-3'),
      libelle: b.getAttribute('aria-label'), texte: b.getAttribute('aria-valuetext') }; })()`;

  if (mode === 'cl2') {
    // ---------- CL2 : en-tête de jalon, couloirs, ligne d'état, troncature, listes, XSS ----------
    await sec('cl21', async () => {
      await charger(); o.cl21 = await lire(`JSON.stringify(${jalon})`);
      await muter("for (const id of ['ph-1', 'ph-2']) " + NID('ph-1').replace("'ph-1'", 'id') + ".st = 'todo'");
        o.cl21z = await lire(`JSON.stringify(${jalon})`);
      await muter("for (const n of VibeFlow.graph.nodes) if (n.parent === 'ms-v2.0-couloirs') n.st = 'done'"); o.cl21c = await lire(`JSON.stringify(${jalon})`);
    });
    await sec('cl22', async () => {
      await charger();
      o.cl22 = await lire(`JSON.stringify([...document.querySelectorAll('.vp-jalon:first-of-type .vp-couloir')].map((c) => ({
        mot: c.querySelector('.vp-mot').textContent, n: +c.querySelector('.vp-n').textContent,
        cartes: c.querySelectorAll('.vp-carte').length, glyphe: getComputedStyle(c.querySelector('.vp-gl'), '::before').webkitMaskImage !== 'none',
          nom: c.getAttribute('aria-label') })))`);
      await muter(NID('ph-4') + ".st = 'todo'");
      o.cl22v = await lire(`JSON.stringify((() => { const c = document.querySelector('[data-couloir=en-cours]');
        return { texte: c.querySelector('.vp-vide').textContent, boutons: c.querySelectorAll('button').length, nom: c.getAttribute('aria-label') }; })())`);
    });
    await sec('cl23', async () => {
      await charger();
      const ligne = (id) => `document.querySelector('.vp-carte[data-id="n:${id}"]').querySelector('.vp-etat').textContent`;
      o.cl23 = await lire(`JSON.stringify([${ligne('ph-1')}, ${ligne('ph-5')},
        document.querySelector('.vp-carte[data-id="n:ph-5"]').getAttribute('aria-label')])`);
      await muter(`const n = ${NID('ph-3')}; delete n.avancement; delete n.exigences`);
      o.cl23b = await lire(`JSON.stringify((() => { const c = document.querySelector('.vp-carte[data-id="n:ph-3"]'); const e = c.querySelector('.vp-etat');
        return { texte: e.textContent, couloir: c.closest('.vp-couloir').dataset.couloir, h: e.getBoundingClientRect().height,
          masque: e.getAttribute('aria-hidden') }; })())`);
    });
    await sec('cl24', async () => {
      await charger('', 1000, 800);
      const sb = await s.ev("document.querySelector('section.vf-projet').offsetWidth - document.querySelector('section.vf-projet').clientWidth");
      // barre de défilement classique de 15 px : la plus petite carte
      await s.ev(`document.querySelector('section.vf-projet').style.paddingRight = 'calc(var(--edge) + ${Math.max(0, 15 - sb)}px)'`);
      const A52 = 'identifiant-long-sans-espace-72-cockpit-couloirs-ok1'.slice(0, 52),
        M53 = 'Lancer du travail depuis les cartes du cockpit en direct sans tarder'.slice(0, 53),
        L70 = ('Un titre trop long pour tenir, qui garde sa fin distinctive ' + 'Z'.repeat(20)).slice(0, 70);
      await muter(`${NID('ph-4')}.label = 'Phase 4 · ${A52}'; ${NID('ph-6')}.label = 'Phase 6 · ${M53}'; ${NID('ph-3')}.label = 'Phase 3 · ${L70}'`);
      const mesure = (id) => `(() => { const c = document.querySelector('.vp-carte[data-id="n:${id}"]'), t = c.querySelector('.vp-titre'),
        d = c.getAttribute('aria-describedby');
        return { larg: Math.round(c.closest('.vp-couloir').getBoundingClientRect().width), plein: t.scrollHeight === t.clientHeight,
          lignes: Math.round(t.clientHeight / parseFloat(getComputedStyle(t).lineHeight)),
          titre: t.textContent, decrit: d ? document.getElementById(d).textContent : null, nom: c.getAttribute('aria-label') }; })()`;
      o.cl24 = { a52: await lire(`JSON.stringify(${mesure('ph-4')})`), m53: await lire(`JSON.stringify(${mesure('ph-6')})`),
        l70: await lire(`JSON.stringify(${mesure('ph-3')})`), M53, L70, A52 };
    });
    await sec('cl25', async () => {
      await charger();
      const det = (c) => `document.querySelector('[data-cle=${c}]')`;
      o.cl25 = await lire(`JSON.stringify({ liste: [...document.querySelectorAll('.vp-details')].map((d) => [d.dataset.cle, d.open,
        d.querySelector('.vp-n').textContent]), cartesFile: document.querySelectorAll('section.vf-projet .card').length,
        differe: /DIFFÉRÉ/.test(document.querySelector('section.vf-projet').textContent) })`);
      await s.ev(`${det('backlog')}.open = true`); await pause(100); await clic('[data-cle=backlog] .vp-rangee');
      await s.attendre("String(VibeFlow.state.selected).startsWith('f:.planning/BACKLOG.md')", 'rangée du backlog sélectionnée');
      o.cl25c = await lire("JSON.stringify([VibeFlow.state.selected, document.querySelector('[data-cle=backlog] .vp-rangee[aria-current=true]') !== null])");
    });
    await sec('cl26', async () => {
      await charger(); await pause(500);
      o.cl26 = await lire(`JSON.stringify({ img: document.querySelectorAll('section.vf-projet img').length,
        flag: ['__x', '__y', '__z', '__w'].map((k) => typeof window[k]).join(),
        texte: [...document.querySelectorAll('.vp-titre')].some((t) => t.textContent === '<img src=x onerror=window.__x=1>') })`);
    });
    await sec('cl27', async () => {
      const LUM = '((c) => { const [r, g, b] = c.match(/[\\d.]+/g).slice(0, 3).map((x) => { x /= 255;'
        + ' return x <= 0.03928 ? x / 12.92 : ((x + 0.055) / 1.055) ** 2.4; }); return 0.2126 * r + 0.7152 * g + 0.0722 * b; })';
      const RATIO = `((a, b) => { const x = ${LUM}(a), y = ${LUM}(b); return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05); })`;
      o.cl27 = {};
      for (const th of ['sombre', 'clair']) {
        await charger(); await s.ev(`document.documentElement.setAttribute('data-theme', '${th === 'sombre' ? 'dark' : 'light'}')`); await pause(300);
        await s.ev("VibeFlow.select('n:ph-3')"); await pause(200);
        o.cl27[th] = await lire(`JSON.stringify((() => { const bg = getComputedStyle(document.getElementById('stage')).backgroundColor, R = ${RATIO},
          out = { textes: [], glyphes: [] };
          for (const c of document.querySelectorAll('.vp-carte')) { const f = getComputedStyle(c).backgroundColor;
            out.textes.push(R(getComputedStyle(c.querySelector('.vp-titre')).color, f), R(getComputedStyle(c.querySelector('.vp-etat')).color, f)); }
          for (const g of document.querySelectorAll('.vp-gl')) out.glyphes.push(R(getComputedStyle(g, '::before').backgroundColor, bg));
          out.segment = getComputedStyle(document.querySelector('.vp-bascule [aria-pressed=true]')).borderTopColor;
          const s = document.querySelector('.vp-carte[aria-current=true]'); out.bordure = R(getComputedStyle(s).borderTopColor, bg);
            out.largeur = ((r) => (r ? r.style.getPropertyValue('border-top-width') : null))([...document.styleSheets]
            .flatMap((sh) => { try { return [...sh.cssRules]; } catch (e) { return []; } })
            .find((r) => r.selectorText === '.vp-carte')); return out; })())`);
      }
    });
    await sec('cl28', async () => {
      await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
      const actives = "document.getAnimations().filter((a) => a.playState === 'running' || a.playState === 'pending').length";
      await charger(); o.cl28 = { charge: await s.ev(actives) };
      await clic('.vp-bascule [data-forme=graphe]'); await pause(500); o.cl28.graphe = await s.ev(actives);
      await clic('#vf-projet-flottant [data-forme=couloirs]'); await pause(500); o.cl28.retour = await s.ev(actives);
      await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'no-preference' }] });
    });
  }
  return o;
});
