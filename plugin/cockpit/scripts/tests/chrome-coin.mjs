// chrome-coin.mjs — mesures du coin bas-droit, de la ligne d'état et des repères de bord (80-05, FORM-10, FORM-12), un vrai Chrome, sans réseau.
// Usage : node chrome-coin.mjs <chrome> <racine-du-serveur> <mode>   Rend UNE ligne JSON { … } ou { erreur }. Modes : cn1 · cn2 · cn3 · term.
// Chaque section est isolée (sec) : une section qui échoue laisse ses champs vides, les autres sont mesurées. Gestes par Input.dispatch*.
import { executer, pause, stabiliser, positionPosee } from './chrome-session.mjs';
const [, , chrome, racine, mode] = process.argv;
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
const POSEE = "(() => { const v = document.querySelector('#viewport'); return !!v && v.style.opacity !== '0' && !v.classList.contains('anim'); })()";
const OUTIL = `window.__cn = {
  hors() { const S = VibeFlow.state, F = VF_CANEVAS.champDeLecture(), { k, x, y } = S.t, n = { gauche: 0, droite: 0, haut: 0, bas: 0 };
    for (const c of S.layout.children) { const l = c.x * k + x, t = c.y * k + y, r = l + c.width * k, b = t + c.height * k;
      if (r <= F.x) n.gauche++; if (l >= F.x + F.w) n.droite++; if (b <= F.y) n.haut++; if (t >= F.y + F.h) n.bas++; }
    return n; },
  reperes() { return [...document.querySelectorAll('button.vf-repere')].map((b) => ({ bord: b.dataset.bord, n: parseInt(b.textContent, 10),
    texte: b.textContent, nom: b.getAttribute('aria-label') })); },
  place(m) { const S = VibeFlow.state, F = VF_CANEVAS.champDeLecture(), { k, x } = S.t, cs = S.layout.children;
    const g = (c) => (c.x + c.width / 2) * k + x, par = (a, b) => (a.x - b.x), gau = cs.slice().sort(par)[0], dro = cs.slice().sort((a, b) => par(b, a))[0];
    const dx = m === 'coupeG' ? F.x - g(gau) : m === 'coupeD' ? F.x + F.w - g(dro) : F.x + F.w + 40 - Math.min(...cs.map((c) => c.x * k + x));
    VF_CANEVAS.deplacer({ x: dx, y: 0 }); },
  actives() { return document.getAnimations().filter((a) => a.playState === 'running' || a.playState === 'pending').length; } }`;
const KEYS = { Tab: 9, Enter: 13, Escape: 27 };

await executer(chrome, async (s) => {
  const o = { erreurs: {} };
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  const sec = async (nom, f) => { try { await f(); } catch (e) { o.erreurs[nom] = String(e.message).slice(0, 160); } };
  const lire = async (expr) => { const v = await s.ev(expr); return v === undefined ? null : JSON.parse(v); };
  const vue = (w, h, mobile) => s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile });
  const touche = async (nom) => {
    for (const type of ['keyDown', 'keyUp']) {
      await s.send('Input.dispatchKeyEvent', { type, key: nom, code: nom, windowsVirtualKeyCode: KEYS[nom], nativeVirtualKeyCode: KEYS[nom] });
    }
  };
  const souris = (type, x, y) => s.send('Input.dispatchMouseEvent', { type, x, y, button: type === 'mouseMoved' ? 'none' : 'left', clickCount: 1 });
  const clic = async (x, y) => { await souris('mouseMoved', x, y); await souris('mousePressed', x, y); await souris('mouseReleased', x, y); };
  const clicSur = async (sel) => {
    const p = await positionPosee(s.ev, `document.querySelector(${JSON.stringify(sel)})`);
    if (!p) throw new Error(`élément absent : ${sel}`);
    await clic(p.cx, p.cy);
  };
  const lireVue = () => s.ev('JSON.stringify([VibeFlow.state.container, document.querySelectorAll("#viewport .node").length])');
  const charger = async (page, w = 1440, h = 900, mobile = false) => {
    await vue(w, h, mobile); await s.naviguer(`${racine}/${page}?lang=en`); await s.attendre(PRET, `page ${page}`);
    await s.attendre("!!document.querySelector('#viewport .node')", `cartes ${page}`); await s.attendre(POSEE, `vue posée ${page}`);
    await stabiliser(lireVue, { pas: 120, max: 5000 });
    await pause(1200); // la visite guidée du premier passage démarre après le chargement : Échap jusqu'à sa fermeture
    for (let i = 0; i < 5 && await s.ev('!!(window.VibeFlowTour && VibeFlowTour.active())'); i++) { await touche('Escape'); await pause(400); }
    await s.ev(OUTIL);
  };
  const gros = async () => { // le niveau de 70 notes, ajusté
    await s.ev("VibeFlow.reveal('f:lots/n05.md')");
    await s.attendre("VibeFlow.state.container !== 'root' && document.querySelectorAll('#viewport .node').length >= 70", 'niveau de 70 notes');
    await stabiliser(lireVue, { pas: 120, max: 5000 }); await s.ev("document.getElementById('z-fit').click()");
    await stabiliser(() => s.ev('JSON.stringify(VibeFlow.state.t)'), { pas: 150, max: 4000 });
  };
  const rep = () => stabiliser(() => s.ev('JSON.stringify([__cn.hors(), __cn.reperes()])'), { pas: 120, max: 3000 }).then((v) => JSON.parse(v));

  if (mode === 'cn1') {
    await charger('index.html'); o.cn1 = { etats: [], clic: {}, tab: {} };
    await sec('cn1', async () => {
      await gros();
      for (const m of ['fit', 'coupeG', 'coupeD', 'toutDroite']) {
        if (m !== 'fit') await s.ev(`__cn.place(${JSON.stringify(m)})`);
        const [hors, reperes] = await rep(); o.cn1.etats.push({ m, hors, reperes });
      }
      const av = await lire('JSON.stringify({ k: VibeFlow.state.t.k, sel: VibeFlow.state.selected, hors: __cn.hors() })');
      await clicSur('button.vf-repere[data-bord=droite]');
      const [hors] = await rep();
      const ap = await lire(`JSON.stringify({ k: VibeFlow.state.t.k, sel: VibeFlow.state.selected, hors: ${JSON.stringify(hors)} })`);
      o.cn1.clic = { avant: av, apres: ap };
      await s.ev('__cn.place("toutDroite")'); await rep();
      await s.ev("(() => { const g = VF_CANEVAS.carteItinerante(); VibeFlow.state.chipEls.get(g).focus(); })()");
      await touche('Tab'); await pause(150);
      o.cn1.tab = await lire(`JSON.stringify((() => { const a = document.activeElement;
        return { repere: a.matches('button.vf-repere'), nom: a.getAttribute('aria-label'), texte: a.textContent, bord: a.dataset.bord }; })())`);
    });
    return o;
  }
  return o;
});
