// chrome-coin.mjs — mesures du coin bas-droit, de la ligne d'état et des repères de bord (80-05, FORM-10, FORM-12), un vrai Chrome, sans réseau.
// Usage : node chrome-coin.mjs <chrome> <racine-du-serveur> <mode>   Rend UNE ligne JSON { … } ou { erreur }. Modes : cn1 · cn2 · cn3 · term (+ fr : défaut).
// Chaque section est isolée (sec) : une section qui échoue laisse ses champs vides, les autres sont mesurées. Gestes par Input.dispatch*.
import { executer, pause, stabiliser, positionPosee } from './chrome-session.mjs';
const [, , chrome, racine, modeArg, filtre] = process.argv, FR = /fr$/.test(modeArg || ''), mode = FR ? modeArg.slice(0, -2) : modeArg;
const SEC = new Set((filtre || '').split(',').filter(Boolean));
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
    const med = cs.slice().sort(par)[Math.floor(cs.length / 2)];
    const dx = m === 'coupeG' ? F.x - g(gau) : m === 'coupeD' ? F.x + F.w - g(dro) : m === 'milieu' ? F.x + F.w / 2 - g(med)
      : F.x + F.w + 40 - Math.min(...cs.map((c) => c.x * k + x));
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
  zone(e) { const b = e.getBoundingClientRect(), ny = Math.max(0, (44 - b.height) / 2), nx = Math.max(0, (44 - b.width) / 2);
    return { l: b.left - nx, t: b.top - ny, r: b.right + nx, b: b.bottom + ny, w: b.width + 2 * nx, h: b.height + 2 * ny, ny, nx }; },
  appui(e) { const z = this.zone(e), b = e.getBoundingClientRect(), cx = b.left + b.width / 2, cy = b.top + b.height / 2;
    return [[cx, z.t + 1], [cx, z.b - 1], [z.l + 1, cy], [z.r - 1, cy]].every(([x, y]) => {
      const q = document.elementFromPoint(x, y); return !!q && e.contains(q); }); },
  ecart(a, b) { const x = Math.max(a.l - b.r, b.l - a.r), y = Math.max(a.t - b.b, b.t - a.b); return Math.max(x, y); },
  repsel() { return [...document.querySelectorAll('button.vf-repere')]; },
  idDe(g) { for (const [i, x] of VibeFlow.state.chipEls) if (x === g) return i; return null; },
  actif() { const a = document.activeElement, g = a.closest ? a.closest('g.node') : null;
    return { tag: a.tagName.toLowerCase(), bord: a.dataset ? a.dataset.bord || null : null, id: g ? this.idDe(g) : null,
      itin: VF_CANEVAS.carteItinerante() }; },
  actives() { return document.getAnimations().filter((a) => a.playState === 'running' || a.playState === 'pending').length; } }`;
const KEYS = { Tab: 9, Enter: 13, Escape: 27 };

await executer(chrome, async (s) => {
  const o = { erreurs: {}, cn4: {} };
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  const sec = async (nom, f) => { if (SEC.size && !SEC.has(nom)) return; try { await f(); } catch (e) { o.erreurs[nom] = String(e.message).slice(0, 160); } };
  const lire = async (expr) => { const v = await s.ev(expr); return v === undefined ? null : JSON.parse(v); };
  const vue = (w, h, mobile) => s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile });
  const touche = async (nom) => { for (const type of ['keyDown', 'keyUp']) { const text = nom === 'Enter' && type === 'keyDown' ? '\r' : undefined;
    await s.send('Input.dispatchKeyEvent', { type, key: nom, code: nom, text, windowsVirtualKeyCode: KEYS[nom], nativeVirtualKeyCode: KEYS[nom] }); } };
  const souris = (type, x, y) => s.send('Input.dispatchMouseEvent', { type, x, y, button: type === 'mouseMoved' ? 'none' : 'left', clickCount: 1 });
  const clic = async (x, y) => { await souris('mouseMoved', x, y); await souris('mousePressed', x, y); await souris('mouseReleased', x, y); };
  const clicSur = async (sel) => { const p = await positionPosee(s.ev, `document.querySelector(${JSON.stringify(sel)})`);
    if (!p) throw new Error(`élément absent : ${sel}`); await clic(p.cx, p.cy); };
  const lireVue = () => s.ev('JSON.stringify([VibeFlow.state.container, document.querySelectorAll("#viewport .node").length])');
  const url = (p) => (FR ? `${racine}/${p}` : `${racine}/${p}${p.includes('?') ? '&' : '?'}lang=en`);
  const charger = async (page, w = 1440, h = 900, mobile = false) => {
    await vue(w, h, mobile); await s.naviguer(url(page));
    if (mode === 'term') { // le tiroir du terminal se rouvre de lui-même d'une page à l'autre (stockage) : chaque page part tiroir fermé
      await s.ev("localStorage.removeItem('vf.terminal.open'); localStorage.removeItem('vf.terminal.h')"); await s.naviguer(url(page));
    }
    await s.attendre(PRET, `page ${page}`); await s.attendre("!!document.querySelector('#viewport .node')", `cartes ${page}`);
    await s.attendre(POSEE, `vue posée ${page}`);
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

  const tactile = (on) => s.send('Emulation.setTouchEmulationEnabled', { enabled: on });
  if (mode === 'cn4') { // Projet en couloirs : le canevas n'est pas la forme affichée, ni minicarte ni repère, seule la ligne d'état reste
    for (const [cle, w, h, doigt] of [['1440', 1440, 900, false], ['390', 390, 844, true]]) {
      await sec('cn4', async () => {
        await tactile(doigt); await charger('project.html?vue=couloirs', w, h, doigt);
        await s.attendre("document.body.classList.contains('vf-forme-couloirs')", 'forme couloirs'); // la visite rend la forme en fermant
        for (let i = 0; i < 8; i++) await s.ev("document.getElementById('z-in').click()");
        await s.ev('VF_CANEVAS.deplacer({ x: -200, y: 0 })'); await pause(500);
        o.cn4[cle] = await lire(`JSON.stringify({ cache: getComputedStyle(document.getElementById('svg')).visibility === 'hidden',
          cartes: VibeFlow.state.layout.children.length, mini: !!__cn.r('#vf-minicarte'), reperes: __cn.repsel().length, etat: !!__cn.r('#vf-coin .vf-ls') })`);
      });
    }
    await tactile(false); return o;
  }
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
      await clicSur('button.vf-repere[data-bord=droite]'); const [hors] = await rep();
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
      const HACH = `JSON.stringify((() => { const q = (x) => document.querySelector('#vf-minicarte ' + x), h = q('rect[fill*=hachure]'), f = q('.vf-mf');
        const a = h.getBoundingClientRect(), b = f.getBoundingClientRect(), l = q('.vf-mh line'), p = document.createElement('i');
        p.style.color = 'var(--text-3)'; document.body.appendChild(p); const c = getComputedStyle(p).color; p.remove();
        return { affiche: h.style.display !== 'none' && a.width > 0, part: a.width / b.width, gauche: (a.left - b.left) / b.width,
          trait: getComputedStyle(l).stroke === c, vide: getComputedStyle(f).fill === 'none',
          nom: document.querySelector('#vf-minicarte').getAttribute('aria-label') }; })())`;
      const av = await lire(VUE), hf = await lire(HACH);
      await s.ev('VFGitTiroir.ouvrir()'); await s.attendre('VFGitTiroir.ouvert()', 'tiroir Git ouvert');
      await stabiliser(() => s.ev("JSON.stringify(document.getElementById('vf-git-tiroir').getBoundingClientRect())"), { pas: 150, max: 4000 });
      await pause(300); const ap = await lire(VUE), ho = await lire(HACH);
      const tr = await R('#vf-git-tiroir'), a = await lire('JSON.stringify(VibeFlow.freeArea())');
      const g = Math.max(tr.l, a.x); // la part du cadre sous le tiroir : de son bord gauche ou du cadre à son bord droit ou au cadre
      o.cn2.c23 = { av, ap, hf, ho, attendu: (Math.min(tr.r, a.x + a.w) - g) / a.w, debut: (g - a.x) / a.w };
      await s.ev('VFGitTiroir.fermer()'); await pause(400);
    });
    await sec('cn24', async () => { // la ligne d'état : branche, ellipse, direct, heure (horloge du pilote), branche hostile sans élément créé
      const LIRE = `JSON.stringify((() => { const q = (x) => document.querySelector(x), t = (x) => (q(x) ? q(x).textContent : null);
        return { titre: q('#vf-coin .vf-ls-br').title, nom: q('#vf-coin .vf-ls-br').getAttribute('aria-label'), vu: t('#vf-coin .vf-ls-nom'),
        status: [...document.querySelectorAll('#vf-coin [role=status]')].map((e) => e.textContent), mot: t('#vf-coin .vf-ls-dr .vf-ls-g + span'),
        heure: t('#vf-coin .vf-ls-hr'),
        xss: [window.__xss === undefined, document.querySelectorAll('#vf-coin img, #vf-coin [onerror], #vf-coin [onload]').length] }; })())`;
      const horloge = (h, m) => s.ev(`(() => { const V = window.__vraiDate || Date; window.__vraiDate = V;
        const t = new V(2026, 10, 12, ${h}, ${m}, 0).getTime();
        window.Date = class extends V { constructor(...a) { if (a.length) super(...a); else super(t); } static now() { return t; } };
        document.dispatchEvent(new CustomEvent('vf-who')); })()`);
      o.cn2.c24 = { base: await lire(LIRE) };
      await horloge(9, 5); await pause(150); o.cn2.c24.h1 = (await lire(LIRE)).heure;
      await horloge(21, 47); await pause(150); o.cn2.c24.h2 = (await lire(LIRE)).heure;
      await s.ev("document.getElementById('vf-lock').classList.add('off')"); await pause(200); o.cn2.c24.coupe = await lire(LIRE);
      await s.ev("document.getElementById('vf-lock').classList.remove('off'); window.Date = window.__vraiDate");
    });
    await sec('cn25', async () => {
      o.cn2.c25 = await lire(`JSON.stringify({ term: document.querySelectorAll('#vf-coin [class*=vf-term]').length,
        texte: /terminal/i.test(document.getElementById('vf-coin').textContent),
        commandes: document.querySelectorAll('#vf-coin code, #vf-coin kbd').length })`);
    });
    await sec('cn26', async () => { // bloc, zoom et barre de question disjoints ; à 900 px aucun bloc ; au doigt à 1100 px la ligne d'état seule
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
  const feuilleFermee = async () => {
    if (!await s.ev("document.body.classList.contains('no-panel')")) await s.ev("document.getElementById('btn-panel').click()");
    await s.attendre("document.body.classList.contains('no-panel')", 'feuille fermée');
  };
  // la zone basse en feuille de détail : repères et boutons de zoom (zones d'appui de 44, sans recouvrement, hors de la carte sélectionnée)
  const BASSE = `JSON.stringify((() => { const S = VibeFlow.state, g = S.chipEls.get(S.selected), c = g && g.querySelector('.card').getBoundingClientRect();
    const R = __cn.repsel(), Z = [...document.querySelectorAll('#zoom button')], tous = [...R, ...Z], zs = tous.map((e) => __cn.zone(e));
    let libre = true; for (let i = 0; i < zs.length; i++) for (let j = i + 1; j < zs.length; j++) if (__cn.ecart(zs[i], zs[j]) < -0.01) libre = false;
    const coupe = (e) => { const b = e.getBoundingClientRect(); return !!c && b.left < c.right && b.right > c.left && b.top < c.bottom && b.bottom > c.top; };
    return { n: R.length, appui: R.every((e) => __cn.appui(e)), zones: zs.map((z) => [Math.round(z.w), Math.round(z.h)]), libre,
      vue: !!c && c.right > 0 && c.left < innerWidth && c.bottom > 0 && c.top < innerHeight, couvre: tous.filter(coupe).length, zoom: Z.length }; })())`;
  if (mode === 'cn3') {
    o.cn3 = { f: {}, tabs: {}, orphelin: {}, ro: {}, paires: [] };
    for (const [cle, w, h, doigt] of [['tactile', 390, 844, true], ['moyen', 800, 900, false]]) {
      await sec('cn31', async () => {
        await tactile(doigt); await charger('index.html', w, h, doigt); await gros();
        if (await s.ev("document.body.classList.contains('no-panel')")) await s.ev("document.getElementById('btn-panel').click()");
        await s.attendre("!document.body.classList.contains('no-panel')", 'feuille ouverte'); await pause(400);
        const ouvert = await lire(`JSON.stringify({ ferme: document.body.classList.contains('no-panel'), n: __cn.repsel().length })`);
        await feuilleFermee(); await s.ev('VF_CANEVAS.amenerDansLeChamp(VibeFlow.state.selected)'); await rep();
        o.cn3.f[cle] = { ouvert, ferme: await lire(BASSE) };
      });
    }
    await sec('cn32', async () => { // onglets du téléphone : visuel de 36, zone d'appui de 44 (une sonde 3 px au-dessus et au-dessous reste dans l'onglet)
      await tactile(true); await charger('index.html', 390, 844, true);
      o.cn3.tabs = await lire(`JSON.stringify({ onglets: [...document.querySelectorAll('.vf-tabs a')].map((a) => {
        const b = a.getBoundingClientRect(), x = b.left + b.width / 2;
        const u = document.elementFromPoint(x, b.top - 3), d = document.elementFromPoint(x, b.bottom + 3);
        return { h: b.height, haut: !!u && a.contains(u), bas: !!d && a.contains(d) }; }),
        zoom: [...document.querySelectorAll('#zoom button')].map((e) => [e.offsetWidth, e.offsetHeight]) })`);
    });
    await tactile(false);
    await sec('cn34', async () => { // focus orphelin : fruit du geste, voisin, carte itinérante ; jamais body
      await charger('index.html'); await gros();
      const F = (b) => `(() => { const e = document.querySelector('button.vf-repere[data-bord=${b}]'); if (e) e.focus(); return !!e; })()`;
      const o4 = o.cn3.orphelin = { a: {}, b: {}, c: {}, d: {} }; await rep(); o4.a.focus = await s.ev(F('droite'));
      let proche = null, n = 0;
      const DR = "!!document.querySelector('button.vf-repere[data-bord=droite]')";
      for (; n < 12 && await s.ev(DR); n++) { proche = await s.ev('__cn.procheDroite()'); await touche('Enter'); await pause(200); }
      o4.a = { ...o4.a, n, dernier: proche, apres: await lire('JSON.stringify(__cn.actif())'), repere: await s.ev(DR) };
      await s.ev("document.getElementById('z-fit').click()"); await rep(); o4.b.focus = await s.ev(F('bas'));
      await s.ev('VF_CANEVAS.deplacer({ x: 0, y: -6000 })'); await rep();
      o4.b = { ...o4.b, apres: await lire('JSON.stringify(__cn.actif())'), restants: (await lire('JSON.stringify(__cn.reperes())')).map((r) => r.bord) };
      o4.c.focus = await s.ev(F('haut'));
      for (let i = 0; i < 10; i++) await s.ev("document.getElementById('z-out').click()");
      await s.ev(`(() => { const S = VibeFlow.state, F = VF_CANEVAS.champDeLecture(), cs = S.layout.children, { k, x, y } = S.t, m = (f) => Math[f];
        const x0 = m('min')(...cs.map((c) => c.x * k + x)), x1 = m('max')(...cs.map((c) => (c.x + c.width) * k + x));
        const y0 = m('min')(...cs.map((c) => c.y * k + y)), y1 = m('max')(...cs.map((c) => (c.y + c.height) * k + y));
        VF_CANEVAS.deplacer({ x: F.x + F.w / 2 - (x0 + x1) / 2, y: F.y + F.h / 2 - (y0 + y1) / 2 }); })()`);
      await rep(); o4.c = { ...o4.c, restants: (await lire('JSON.stringify(__cn.reperes())')).length, apres: await lire('JSON.stringify(__cn.actif())') };
      await s.ev("document.getElementById('z-fit').click()"); await rep(); // un nouveau bord ne déplace pas le repère focalisé
      o4.d = { focus: await s.ev(F('droite')) };
      await s.ev('VF_CANEVAS.deplacer({ x: 0, y: -300 })'); await rep();
      o4.d = { ...o4.d, apres: await lire('JSON.stringify(__cn.actif())'), bords: (await lire('JSON.stringify(__cn.reperes())')).map((r) => r.bord) };
    });
    for (const w of [1000, 1024]) {
      await sec('cn36', async () => { // panneau et tiroir Git ouverts : les repères gauche et droite ne se recouvrent pas (champ étroit)
        await charger('index.html', w, 800); await gros(); await s.ev('VFGitTiroir.ouvrir()'); await s.attendre('VFGitTiroir.ouvert()', 'tiroir Git ouvert');
        await pause(500); if (await s.ev("document.body.classList.contains('no-panel')")) await s.ev("document.getElementById('btn-panel').click()");
        await pause(600); await s.ev('__cn.place("milieu")'); await rep();
        const L = "__cn.repsel().map((e) => 'button.vf-repere[data-bord=' + e.dataset.bord + ']')";
        o.cn3.paires.push(await lire(`JSON.stringify({ w: ${w}, bords: __cn.repsel().map((e) => e.dataset.bord), ok: __cn.disjoints(${L}),
          deux: !document.body.classList.contains('no-panel') && VFGitTiroir.ouvert() })`));
      });
    }
    await sec('cn35', async () => { // mouvement réduit : aucune animation active après un repère, un clic de minicarte, l'ouverture du tiroir Git
      await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
      await charger('index.html'); await gros(); await s.ev('__cn.place("toutDroite")'); await rep(); o.cn3.ro = {};
      await clicSur('button.vf-repere[data-bord=droite]'); o.cn3.ro.repere = await s.ev('__cn.actives()');
      const m = await lire("JSON.stringify(__cn.r('#vf-minicarte'))"); await clic(m.l + m.w / 2, m.t + m.h / 2); o.cn3.ro.mini = await s.ev('__cn.actives()');
      await s.ev('VFGitTiroir.ouvrir()'); await pause(60); o.cn3.ro.tiroir = await s.ev('__cn.actives()');
      o.cn3.ro.media = await s.ev("matchMedia('(prefers-reduced-motion: reduce)').matches");
    });
    return o;
  }
  if (mode === 'term') { // le lab lancé avec --terminal : la pastille « Terminal » et le tiroir du terminal
    o.term = { a: null, b: [], c: {} };
    const OUV = "(() => { const r = document.querySelector('.vf-term-tiroir'); return !!r && !r.hidden && r.getBoundingClientRect().height > 0; })()";
    const DISJ = `JSON.stringify((() => { const L = ['.vf-term-pastille', '#vf-coin', '#zoom', '#ask', '.vf-term-tiroir',
      ...__cn.repsel().map((e) => 'button.vf-repere[data-bord=' + e.dataset.bord + ']')].filter((q) => __cn.r(q));
      return { noms: L, ok: __cn.disjoints(L) }; })())`;
    const ouvrirTiroir = async () => {
      await clicSur('button.vf-term-pastille'); await s.attendre(OUV, 'tiroir du terminal ouvert');
      await stabiliser(() => s.ev("JSON.stringify(__cn.r('.vf-term-tiroir'))"), { pas: 200, max: 5000 });
      await s.ev("document.getElementById('z-fit').click()"); await rep();
    };
    await sec('cn33a', async () => { await charger('index.html'); await gros(); await ouvrirTiroir(); o.term.a = await lire(DISJ); });
    await sec('cn33b', async () => {
      for (const w of [1440, 1024]) {
        await charger('index.html', w, 900); await gros(); await rep(); const ferme = await lire(DISJ); await ouvrirTiroir();
        o.term.b.push({ w, ferme, ouvert: await lire(DISJ) });
      }
    });
    for (const [cle, w, h, doigt] of [['tactile', 390, 844, true], ['moyen', 800, 900, false]]) {
      await sec('cn33c', async () => { // feuille de détail : chaque repère à 8 px au moins de la pastille et du zoom
        await tactile(doigt); await charger('index.html', w, h, doigt); await gros(); await feuilleFermee();
        await s.ev('VF_CANEVAS.amenerDansLeChamp(VibeFlow.state.selected)'); await rep();
        o.term.c[cle] = await lire(`JSON.stringify((() => { const p = __cn.r('.vf-term-pastille'), z = __cn.r('#zoom'), R = __cn.repsel();
          const bx = (e) => { const b = e.getBoundingClientRect(); return { l: b.left, t: b.top, r: b.right, b: b.bottom }; };
          return { pastille: !!p, zoom: !!z, n: R.length, ecarts: R.map((e) => [p ? __cn.ecart(bx(e), p) : null, z ? __cn.ecart(bx(e), z) : null]) }; })())`);
      });
    }
    await tactile(false);
    return o;
  }
  return o;
});
