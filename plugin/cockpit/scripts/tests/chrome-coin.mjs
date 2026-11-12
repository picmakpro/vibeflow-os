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
  procheDroite() { const S = VibeFlow.state, F = VF_CANEVAS.champDeLecture(), { k, x } = S.t; let b = null;
    for (const c of S.layout.children) { const l = c.x * k + x; if (l >= F.x + F.w && (!b || l < b.l)) b = { id: c.id, l }; }
    return b && b.id; },
  dedans(id) { const S = VibeFlow.state, F = VF_CANEVAS.champDeLecture(), { k, x, y } = S.t, c = S.layout.children.find((q) => q.id === id);
    if (!c) return false; const l = c.x * k + x, t = c.y * k + y;
    return l >= F.x && t >= F.y && l + c.width * k <= F.x + F.w && t + c.height * k <= F.y + F.h; },
  r(s) { const e = document.querySelector(s); if (!e || !e.getClientRects().length) return null; const b = e.getBoundingClientRect();
    return { l: b.left, t: b.top, r: b.right, b: b.bottom, w: b.width, h: b.height }; },
  disjoints(sels) { const rs = sels.map((s) => this.r(s)).filter(Boolean); let ok = rs.length === sels.length;
    for (let i = 0; i < rs.length; i++) for (let j = i + 1; j < rs.length; j++) { const a = rs[i], b = rs[j];
      if (!(a.r <= b.l || b.r <= a.l || a.b <= b.t || b.b <= a.t)) ok = false; }
    return ok; },
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
      const proche = await s.ev('__cn.procheDroite()');
      await clicSur('button.vf-repere[data-bord=droite]');
      const [hors] = await rep();
      const ap = await lire(`JSON.stringify({ k: VibeFlow.state.t.k, sel: VibeFlow.state.selected, hors: ${JSON.stringify(hors)},
        dedans: __cn.dedans(${JSON.stringify(proche)}) })`);
      o.cn1.clic = { avant: av, apres: ap };
      await s.ev('__cn.place("toutDroite")'); await rep();
      await s.ev("(() => { const g = VF_CANEVAS.carteItinerante(); VibeFlow.state.chipEls.get(g).focus(); })()");
      await touche('Tab'); await pause(150);
      o.cn1.tab = await lire(`JSON.stringify((() => { const a = document.activeElement;
        return { repere: a.matches('button.vf-repere'), nom: a.getAttribute('aria-label'), texte: a.textContent, bord: a.dataset.bord }; })())`);
    });
    return o;
  }
  if (mode === 'cn2') {
    await charger('index.html'); await gros(); o.cn2 = {};
    const R = (sel) => lire(`JSON.stringify(__cn.r(${JSON.stringify(sel)}))`);
    const posee = (sel) => stabiliser(() => s.ev(`JSON.stringify(__cn.r(${JSON.stringify(sel)}))`), { pas: 150, max: 4000 }).then((v) => JSON.parse(v));
    await sec('cn21', async () => {
      const c = await posee('#vf-coin');
      o.cn2.c21 = { coin: c, mini: await R('#vf-minicarte'), panel: await R('#panel'), ask: await R('#ask'), W: await s.ev('innerWidth') };
      await s.ev("document.getElementById('btn-panel').click()"); await s.attendre("document.body.classList.contains('no-panel')", 'panneau fermé');
      o.cn2.c21.ferme = await posee('#vf-coin'); await s.ev("document.getElementById('btn-panel').click()");
      await s.attendre("!document.body.classList.contains('no-panel')", 'panneau rouvert'); await posee('#vf-coin');
    });
    await sec('cn22', async () => { // le point touché devient le centre du cadre du champ ; la mise à l'échelle lue AVANT le clic, le zoom ne bouge pas
      const mp = await lire(`JSON.stringify((() => { const m = /translate\\(([-\\d.e]+) ([-\\d.e]+)\\) scale\\(([-\\d.e]+)\\)/.exec(
        document.querySelector('#vf-minicarte .vf-mc').getAttribute('transform')); return { ox: +m[1], oy: +m[2], s: +m[3], k: VibeFlow.state.t.k }; })())`);
      const m = await R('#vf-minicarte'); await clic(m.l + m.w / 2, m.t + m.h / 2);
      o.cn2.c22 = await lire(`JSON.stringify((() => { const S = VibeFlow.state, a = VibeFlow.freeArea(), mp = ${JSON.stringify(mp)};
        return { visee: [(${m.w / 2} - mp.ox) / mp.s, (${m.h / 2} - mp.oy) / mp.s], centre: [(a.x + a.w / 2 - S.t.x) / S.t.k, (a.y + a.h / 2 - S.t.y) / S.t.k],
        k: [mp.k, S.t.k] }; })())`);
      await s.ev("document.getElementById('z-fit').click()"); await posee('#vf-coin');
    });
    await sec('cn23', async () => { // PU-G-204 : le tiroir Git ne change ni freeArea() ni state.t ; la hachure couvre la part du cadre qu'il recouvre
      const VUE = `JSON.stringify({ w: VibeFlow.freeArea().w, t: VibeFlow.state.t, ouvert: !!window.VFGitTiroir && VFGitTiroir.ouvert() })`;
      const HACH = `JSON.stringify((() => { const h = document.querySelector('#vf-minicarte rect[fill*=hachure]'), f = document.querySelector('#vf-minicarte .vf-mf');
        const a = h.getBoundingClientRect(), b = f.getBoundingClientRect(), l = document.querySelector('#vf-minicarte .vf-mh line'), p = document.createElement('i');
        p.style.color = 'var(--text-3)'; document.body.appendChild(p); const c = getComputedStyle(p).color; p.remove();
        return { affiche: h.style.display !== 'none' && a.width > 0, part: a.width / b.width, gauche: a.left - b.left, trait: getComputedStyle(l).stroke === c,
          nom: document.querySelector('#vf-minicarte').getAttribute('aria-label') }; })())`;
      const av = await lire(VUE), hf = await lire(HACH);
      await s.ev('VFGitTiroir.ouvrir()'); await s.attendre('VFGitTiroir.ouvert()', 'tiroir Git ouvert');
      await stabiliser(() => s.ev("JSON.stringify(document.getElementById('vf-git-tiroir').getBoundingClientRect())"), { pas: 150, max: 4000 });
      await pause(300); const ap = await lire(VUE), ho = await lire(HACH);
      const tr = await R('#vf-git-tiroir'), a = await lire('JSON.stringify(VibeFlow.freeArea())');
      o.cn2.c23 = { av, ap, hf, ho, attendu: Math.min(tr.r - a.x, a.w) / a.w };
      await s.ev('VFGitTiroir.fermer()'); await pause(400);
    });
    await sec('cn24', async () => { // la ligne d'état : branche entière, ellipse au milieu, direct, heure (horloge du pilote), branche hostile sans élément créé
      const LIRE = `JSON.stringify((() => { const q = (x) => document.querySelector(x), t = (x) => (q(x) ? q(x).textContent : null);
        return { titre: q('#vf-coin .vf-ls-br').title, nom: q('#vf-coin .vf-ls-br').getAttribute('aria-label'), vu: t('#vf-coin .vf-ls-nom'),
        status: [...document.querySelectorAll('#vf-coin [role=status]')].map((e) => e.textContent), mot: t('#vf-coin .vf-ls-dr .vf-ls-g + span'),
        heure: t('#vf-coin .vf-ls-hr'), xss: [window.__xss === undefined, document.querySelectorAll('#vf-coin img, #vf-coin [onerror], #vf-coin [onload]').length] }; })())`;
      const horloge = (h, m) => s.ev(`(() => { const V = window.__vraiDate || Date; window.__vraiDate = V; const t = new V(2026, 10, 12, ${h}, ${m}, 0).getTime();
        window.Date = class extends V { constructor(...a) { if (a.length) super(...a); else super(t); } static now() { return t; } };
        document.dispatchEvent(new CustomEvent('vf-who')); })()`);
      o.cn2.c24 = { base: await lire(LIRE) };
      await horloge(9, 5); await pause(150); o.cn2.c24.h1 = (await lire(LIRE)).heure;
      await horloge(21, 47); await pause(150); o.cn2.c24.h2 = (await lire(LIRE)).heure;
      await s.ev("document.getElementById('vf-lock').classList.add('off')"); await pause(200); o.cn2.c24.coupe = await lire(LIRE);
      await s.ev("document.getElementById('vf-lock').classList.remove('off'); window.Date = window.__vraiDate");
    });
    await sec('cn25', async () => {
      o.cn2.c25 = await lire(`JSON.stringify({ term: document.querySelectorAll('#vf-coin [class*=vf-term]').length, texte: /terminal/i.test(document.getElementById('vf-coin').textContent),
        commandes: document.querySelectorAll('#vf-coin code, #vf-coin kbd').length })`);
    });
    await sec('cn26', async () => { // aucune intersection entre le bloc, le zoom et la barre de question ; à 900 px aucun bloc ; au doigt à 1100 px la ligne d'état seule
      o.cn2.c26 = [];
      await s.ev('VFGitTiroir.ouvrir()'); await pause(400);
      for (const [w, ferme] of [[1440, false], [1440, true], [1024, false], [1024, true]]) {
        await vue(w, 900, false); await pause(300);
        const clos = await s.ev("document.body.classList.contains('no-panel')");
        if (clos !== ferme) await s.ev("document.getElementById('btn-panel').click()");
        await stabiliser(() => s.ev("JSON.stringify([__cn.r('#vf-coin'), __cn.r('#ask')])"), { pas: 200, max: 5000 }); await pause(300);
        o.cn2.c26.push({ w, ferme, coin: !!await R('#vf-coin'), ok: await s.ev("__cn.disjoints(['#vf-coin', '#zoom', '#ask'])") });
      }
      await vue(900, 900, false); await pause(400); o.cn2.c26.push({ w: 900, coin: await R('#vf-coin') });
      await s.send('Emulation.setTouchEmulationEnabled', { enabled: true }); await vue(1100, 900, true); await pause(500);
      o.cn2.c26.push({ w: 1100, tactile: true, coin: !!await R('#vf-coin'), mini: !!await R('#vf-minicarte'), etat: !!await R('#vf-coin .vf-ls') });
      await s.send('Emulation.setTouchEmulationEnabled', { enabled: false });
    });
    return o;
  }
  return o;
});
