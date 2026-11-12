// chrome-couloirs.mjs — mesures de Projet en couloirs (80-04, FORM-05, FORM-07) dans un vrai Chrome headless, de vraies touches et de vrais clics.
// Usage : node chrome-couloirs.mjs <chrome> <racine-du-serveur> <mode>   Rend UNE ligne JSON { … } ou { erreur }. Un mode = un Chrome : cl1, cl2, cl3a, cl3b, cl3c.
// Chaque section est isolée (sec) : une section qui échoue (module absent ou muté) laisse ses champs vides, les autres sont mesurées.
import { executer, pause, stabiliser } from './chrome-session.mjs';
const [, , chrome, racine, mode] = process.argv;
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
// la visite du premier passage s'ouvre d'elle-même : la clé « tour-seen » est lue comme posée (la suite ne mesure que la page)
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) { return typeof k === 'string' && k.indexOf('floorplan:tour-seen:') === 0 ? 'true' : g.call(this, k); }; })()";
const KEYS = { Tab: 9, ArrowRight: 39, ArrowLeft: 37, ArrowUp: 38, ArrowDown: 40, Home: 36, End: 35, Enter: 13, Space: 32, Escape: 27, Backspace: 8 };

await executer(chrome, async (s) => {
  const o = { erreurs: {} };
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: SANS_VISITE });
  const sec = async (nom, f) => { try { await f(); } catch (e) { o.erreurs[nom] = String(e.message).slice(0, 160); } };
  const lire = async (expr) => { const v = await s.ev(expr); return v === undefined ? null : JSON.parse(v); };
  const vue = (w, h, tactile = false) => s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: tactile });
  const touche = async (nom) => {
    for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key: nom === 'Space' ? ' ' : nom, code: nom, windowsVirtualKeyCode: KEYS[nom], nativeVirtualKeyCode: KEYS[nom] });
  };
  const clic = async (sel) => {
    const r = await lire(`(() => { const e = document.querySelector(${JSON.stringify(sel)}); if (!e) return 'null'; const b = e.getBoundingClientRect(); return JSON.stringify({ x: b.x + b.width / 2, y: b.y + b.height / 2 }); })()`);
    if (!r) throw new Error(`clic : « ${sel} » absent`);
    await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: r.x, y: r.y });
    for (const type of ['mousePressed', 'mouseReleased']) await s.send('Input.dispatchMouseEvent', { type, x: r.x, y: r.y, button: 'left', clickCount: 1 });
  };
  const compte = "JSON.stringify([document.querySelectorAll('.vp-carte').length, document.querySelectorAll('#viewport .node').length])";
  const charger = async (qs = '', w = 1440, h = 900, tactile = false, brut = true) => {
    await s.send('Emulation.setTouchEmulationEnabled', { enabled: tactile }); await vue(w, h, tactile);
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
      o.cl12 = await lire(`JSON.stringify({ svg: getComputedStyle(document.getElementById('svg')).visibility, cartes: document.querySelectorAll('#viewport .node').length,
        vue: (() => { const v = document.querySelector('section.vf-projet'); return !v || getComputedStyle(v).display === 'none' || v.hidden; })() })`);
    });
    await sec('cl13', async () => {
      await charger();
      await s.ev("VibeFlow.addPanelSection('item', (c) => { window.__cible = c; return '<div id=\"vf-test-sec\">section du pilote</div>'; })");
      await clic('.vp-carte[data-id=\"n:ph-1\"]'); await s.attendre("!!document.querySelector('#panel #vf-test-sec')", 'section de panneau');
      o.cl13 = await lire("JSON.stringify({ dans: !!document.querySelector('#panel #vf-test-sec'), cible: window.__cible })");
    });
    await sec('cl14', async () => {
      await s.naviguer(`${racine}/project.html#s=x`); await s.attendre(PRET, 'page prête (cl14)');
      o.cl14 = await lire('JSON.stringify([location.search, location.hash])');
      await s.naviguer(`${racine}/project.html?vue=couloirs#s=x`); await s.attendre(PRET, 'page prête (cl14b)');
      o.cl14b = await lire('JSON.stringify([location.search, location.hash])');
    });
  }
  return o;
});
