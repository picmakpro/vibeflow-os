// chrome-lien-vue.mjs — mesures du lien de vue (80-13, FORM-15, P80-D-21) dans un vrai Chrome headless, vrais clics.
// Usage : node chrome-lien-vue.mjs <chrome> <racine-du-serveur> <mode> [filtre]   Rend UNE ligne JSON { … } ou { erreur }.
// Modes : lv1 (LV1.x : vue, sélection, zoom), lv2 (LV2.x : tiroirs Git et « Au travail »), lv3 (LV3.x : liens forgés, Précédent, #r=).
// Une absence de rechargement se lit sur performance.timeOrigin, jamais sur une marque posée dans window (la portée d'onglet la retirerait).
import { executer, pause, stabiliser } from './chrome-session.mjs';
const [, , chrome, racine, mode, filtre] = process.argv;
const SEL = filtre ? new Set(filtre.split(',')) : null;
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) {"
  + " const vue = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0);"
  + " return vue ? 'true' : g.call(this, k); }; })()";
const NOM = "String((VibeFlow.graph.project || {}).name || '').replace(/ — (Projet|Équipe)$/, '')";
const ETAT = `({ h: location.hash, q: location.search, c: VibeFlow.state.container, s: VibeFlow.state.selected, t: VibeFlow.state.t,
  o: performance.timeOrigin, cad: VibeFlow.cadrage() })`;
const GIT = `(() => { const t = document.getElementById('vf-git-tiroir'), a = document.activeElement;
  return { n: document.querySelectorAll('#vf-git-tiroir').length, ouvert: !!t && !t.hidden, focus: !!t && !!a && t.contains(a),
    pile: window.VF_SURCOUCHES ? VF_SURCOUCHES.ouverte() : null }; })()`;
const TRAV = `(() => { const w = document.querySelector('#panel > .vf-whop'), a = document.activeElement;
  return { ouvert: !!w && !document.body.classList.contains('no-panel'), focus: !!w && !!a && w.contains(a) }; })()`;
const FORGES = ['#v=n:inconnu', '#z=99,0,0', '#z=0.01,0,0', '#z=1,NaN,Infinity', '#z=1,1000000000,0', '#z=1,0',
  '#git=%3Cimg%20src%3Dx%20onerror%3Dwindow.__g%3D1%3E&s=%3Cimg%20src%3Dx%20onerror%3Dwindow.__g%3D1%3E'];

await executer(chrome, async (s) => {
  const o = { erreurs: {} };
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  const taille = (width) => s.send('Emulation.setDeviceMetricsOverride', { width, height: 900, deviceScaleFactor: 1, mobile: false });
  await taille(1440);
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: SANS_VISITE });
  const sec = async (nom, f) => {
    if (SEL && !SEL.has(nom)) return;
    try { await f(); } catch (e) { o.erreurs[nom] = String(e.message).slice(0, 200); }
  };
  const lire = async (expr) => { const v = await s.ev(`JSON.stringify(${expr})`); return v === undefined ? null : JSON.parse(v); };
  const etat = () => lire(ETAT);
  // un absent se mesure vite, sans épuiser l'échéance
  const essayer = (expr, ms = 4000) => s.attendre(expr, expr.slice(0, 40), ms).then(() => true, () => false);
  const charger = async (chemin) => {
    await s.naviguer(`${racine}${chemin}`, { brut: true, garderTiroirs: true });
    await s.attendre('!!window.VibeFlow && !!VibeFlow.state', 'moteur');
    return stabiliser(etat, { pas: 250, max: 6000 });
  };
  const clic = async (sel) => {
    const r = await lire(`(() => { const e = document.querySelector(${JSON.stringify(sel)}); if (!e) return null;
      e.scrollIntoView({ block: 'nearest' });
      const b = e.getBoundingClientRect(); return { x: b.x + b.width / 2, y: b.y + b.height / 2 }; })()`);
    if (!r) throw new Error(`clic : « ${sel} » absent`);
    await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: r.x, y: r.y });
    for (const type of ['mousePressed', 'mouseReleased']) {
      await s.send('Input.dispatchMouseEvent', { type, x: r.x, y: r.y, button: 'left', clickCount: 1 });
    }
  };
  const choix = () => lire(`(() => { const k = (i) => VibeFlow.children(i).filter((j) => !j.startsWith('x:'));
    const c = k('root').find((i) => k(i).length >= 2); return c ? [c, ...k(c)] : null; })()`);
  const cle = async () => 'vf-tiroirs:' + (await lire(NOM));
  const memoire = async (v) => s.ev(`sessionStorage.setItem(${JSON.stringify(await cle())}, ${JSON.stringify(JSON.stringify(v))})`);
  const git = () => lire(GIT);
  const GIT_OUVERT = "!!document.getElementById('vf-git-tiroir') && !document.getElementById('vf-git-tiroir').hidden";
  const ouvrirGit = async () => { await clic('#vf-git-ligne'); await essayer(GIT_OUVERT); };
  const ouvrirTravail = async () => { await s.attendre("!!document.getElementById('vf-lock')", 'badge Au travail'); await clic('#vf-lock');
    await essayer("!!document.querySelector('#panel > .vf-whop')"); };
  const neuf = async () => { await charger('/'); await s.ev('sessionStorage.clear()'); return charger('/index.html'); }; // aucune mémoire de session
  const aller = (nom) => s.ev(`VF_ONGLETS.aller(${JSON.stringify(nom)}).then(() => 'ok', (e) => 'rejet : ' + e.message)`);

  if (mode === 'lv1') {
    await sec('lv1', async () => {
      await charger('/');
      const [cont, fich, autre] = await choix();
      await s.ev(`VibeFlow.go(${JSON.stringify(cont)})`); await essayer(`VibeFlow.state.container === ${JSON.stringify(cont)}`); await pause(600);
      await s.ev(`VibeFlow.select(${JSON.stringify(fich)})`); await pause(300);
      await clic('#z-in'); const z = await essayer('/(^#|&)z=/.test(location.hash)'); await pause(500);
      const av = await stabiliser(etat, { pas: 250, max: 4000 });
      await charger('/' + av.h); await essayer(`VibeFlow.state.container === ${JSON.stringify(cont)}`, 3000);
      const ap = await stabiliser(etat, { pas: 300, max: 5000 });
      o.lv11 = { av, ap, z, cont, fich };
      await charger('/' + av.h); await essayer(`VibeFlow.state.selected === ${JSON.stringify(fich)}`, 3000);
      await s.ev(`VibeFlow.select(${JSON.stringify(autre)})`); await pause(700);
      o.lv12 = { av: av.h, ap: await etat(), autre };
    });
    await sec('lv13', async () => {
      await charger('/project.html?vue=couloirs'); await s.attendre("document.querySelectorAll('.vp-carte').length > 0", 'couloirs');
      await clic('.vp-carte[data-id="n:ph-2"]'); await s.attendre("VibeFlow.state.selected === 'n:ph-2'", 'ph-2'); await pause(500);
      o.lv13 = await etat();
    });
  }

  if (mode === 'lv2') {
    await sec('lv21', async () => {
      await neuf(); await ouvrirGit(); await pause(300); const ouvert = { h: (await etat()).h, g: await git() };
      await clic('.vf-git-fermer'); await pause(300); const ferme = { h: (await etat()).h, g: await git() };
      await charger('/index.html#git=1'); await essayer(GIT_OUVERT);
      await pause(500); o.lv21 = { ouvert, ferme, lien: await git() };
    });
    await sec('lv22', async () => {
      await neuf(); await ouvrirGit(); await charger('/project.html');
      await essayer("!!document.getElementById('vf-git-tiroir') && !document.getElementById('vf-git-tiroir').hidden"); await pause(300);
      const cles = await lire("Object.keys(sessionStorage).filter((k) => k.indexOf('vf-tiroirs:') === 0)");
      o.lv22 = { git: await git(), cles, cle: await cle(), onglet: await lire('VibeFlow.graph.meta.vfTab') };
      await taille(1200); await neuf(); await ouvrirTravail(); await charger('/project.html');
      await essayer("!!document.querySelector('#panel > .vf-whop')"); await pause(500);
      o.lv22.travail = await lire(TRAV);
      o.lv22.cleT = (await lire("Object.keys(sessionStorage).filter((k) => k.indexOf('vf-tiroirs:') === 0)"))[0] === await cle();
      await taille(1440);
    });
    await sec('lv23', async () => {
      await charger('/'); const k = await cle(), pose = async (v, chemin) => { await memoire(v); await charger(chemin);
        await pause(500); return (await git()).ouvert; };
      o.lv23 = { memo: await pose({ git: true }, '/index.html'), lien: await pose({ git: false }, '/index.html#git=1'),
        aucun: await pose({ git: false }, '/index.html'), k };
      await memoire({ git: true }); await charger('/index.html'); await pause(500); o.lv23.focus = (await git()).focus;
    });
    await sec('lv24', async () => {
      await neuf(); await ouvrirGit(); const e0 = await etat(); const r1 = await aller('projet'); await pause(500);
      const p = { r: r1, e: await etat(), g: await git() };
      const r2 = await aller('code'); await pause(500); const c = { r: r2, g: await git() };
      await aller('projet'); await aller('code'); await pause(500); const f = await git();
      await clic('.vf-git-fermer'); await pause(300); const fin = await git();
      o.lv24 = { p, c, f, fin, origine: p.e.o === e0.o };
      await taille(1200); await neuf(); await ouvrirTravail(); const t0 = await etat(); const rt = await aller('projet'); await pause(600);
      const tp = { r: rt, t: await lire(TRAV), o: (await etat()).o === t0.o }; await aller('code'); await pause(600);
      o.lv24.travail = { ...tp, retour: await lire(TRAV), un: await lire("document.querySelectorAll('#panel > .vf-whop').length") };
      await taille(1440);
    });
  }

  if (mode === 'lv3') {
    await sec('lv31', async () => {
      o.lv31 = [];
      for (const f of FORGES) {
        await charger('/' + f); await pause(500);
        const e = await stabiliser(etat, { pas: 250, max: 4000 });
        o.lv31.push({ f, ok: e.c === 'root' && Math.abs(e.t.k - e.cad.k) <= 1e-3 && !(await git()).ouvert
          && !(await lire('window.__g')) && !(await lire("!!document.querySelector('img[src=\"x\"]')")) });
      }
      await charger('/#z=1.5,10.5,20.25'); await pause(500); // témoin : un z valide s'applique
      o.lv31t = (await stabiliser(etat, { pas: 250, max: 4000 })).t;
    });
    await sec('lv32', async () => {
      await charger('/'); const [, a, b] = await choix();
      for (const id of [a, b]) { await s.ev(`VibeFlow.select(${JSON.stringify(id)})`); await pause(300); }
      const avant = (await etat()).s; await s.ev('history.back()'); const ok = await essayer(`VibeFlow.state.selected === ${JSON.stringify(a)}`);
      o.lv32 = { avant, b, a, apres: (await etat()).s, ok };
      await charger('/#r=f:src/app/main.js'); await pause(800);
      o.lv32r = { existe: await lire("VibeFlow.exists('f:src/app/main.js')"), sel: (await etat()).s };
    });
  }
  return o;
});
