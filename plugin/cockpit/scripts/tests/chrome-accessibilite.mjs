// chrome-accessibilite.mjs — mesures des finitions d'interface immédiates (lot 0 de l'audit, AUDC-M7, X4, X6, X7), dans un vrai Chrome headless.
// Usage : node chrome-accessibilite.mjs <chrome> <racine-du-serveur>
//   UN Chrome, plusieurs pages (?lang=en : les libellés du moteur tels qu'il les écrit). Rend une ligne JSON { <clé>: valeur } ou { erreur }.
//   Clés : m7 · x7 · x4 · x6
import { executer, pause, stabiliser, attendreValeur } from './chrome-session.mjs';
const [, , chrome, racine] = process.argv;
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlow.state && !!window.VibeFlow.state.layout";
const VUE_POSEE = "(() => { const v = document.querySelector('#viewport'); return !!v && v.style.opacity !== '0' && !v.classList.contains('anim'); })()";

await executer(chrome, async (s) => {
  const o = {};
  const vue = (w, h) => s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: false });
  const lireVue = () => s.ev("JSON.stringify({ c: VibeFlow.state.container, n: document.querySelectorAll('#viewport .node').length })");
  const charger = async (page, nom) => {
    await s.naviguer(`${racine}/${page}?lang=en`); await s.attendre(PRET, `page prête (${nom})`);
    await s.attendre("!!document.querySelector('#viewport .node')", `cartes (${nom})`); await s.attendre(VUE_POSEE, `vue posée (${nom})`); await stabiliser(lireVue, { pas: 120, max: 5000 });
    // la visite guidée s'ouvre au premier passage (profil jetable) : Échap la ferme, pour ne mesurer que la page
    await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key: 'Escape', code: 'Escape', windowsVirtualKeyCode: 27, nativeVirtualKeyCode: 27 }); await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key: 'Escape', code: 'Escape', windowsVirtualKeyCode: 27, nativeVirtualKeyCode: 27 });
    await pause(200);
  };
  await vue(1440, 900); await s.send('Emulation.setFocusEmulationEnabled', { enabled: true }); // sans lui, requestAnimationFrame ne tourne pas dans un Chrome sans tête non focalisé

  // ---------- M7 : l'indicateur de mise en page est posé et peint avant le calcul ----------
  // Le calcul (ELK) tourne sur le fil principal : tant qu'il dure, plus rien ne se peint. La sonde s'installe avant les scripts de la page,
  // enveloppe ELK.prototype.layout et relève, À L'INSTANT où le calcul démarre, l'état de #loading et le nombre d'images produites depuis qu'il est allumé.
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: `(() => {
    window.__img = 0; const tic = () => { window.__img++; requestAnimationFrame(tic); }; requestAnimationFrame(tic);
    new MutationObserver((ms) => { for (const m of ms) { const e = m.target; if (e.id === 'loading' && e.classList.contains('on') && window.__m7 && window.__m7.allume === undefined) window.__m7.allume = window.__img; } })
      .observe(document, { attributes: true, attributeFilter: ['class'], subtree: true });
    let E; Object.defineProperty(window, 'ELK', { configurable: true, get() { return E; }, set(v) { E = v; if (!v || !v.prototype || v.prototype.__vfSonde) return; v.prototype.__vfSonde = true; const orig = v.prototype.layout;
      v.prototype.layout = function (...a) { const m = window.__m7; if (m && m.calcul === undefined) { const l = document.querySelector('#loading'); m.calcul = { cartes: ((a[0] && a[0].children) || []).length, allume: !!l && l.classList.contains('on'), opacite: l ? getComputedStyle(l).opacity : null, images: m.allume === undefined ? null : window.__img - m.allume }; }
        return orig.apply(this, a); }; } });
  })()` });
  await charger('index.html', 'm7');
  const mesurerNiveau = async (aller, nom) => {
    const avant = await s.ev('VibeFlow.state.container'); await s.ev('window.__m7 = {}'); await s.ev(aller);
    await s.attendre(`VibeFlow.state.container !== ${JSON.stringify(avant)} && !!document.querySelector('#viewport .node')`, `niveau ${nom}`); await s.attendre(VUE_POSEE, `vue posée (${nom})`);
    return JSON.parse(await s.ev('JSON.stringify(window.__m7.calcul || null)'));
  };
  o.m7 = { gros: await mesurerNiveau("VibeFlow.reveal('f:lots/n05.md')", 'dossier de 70 notes') };
  // redessin en direct (poussée du serveur : VibeFlow.render) sur le même niveau de 70 cartes : même calcul, mais aucun indicateur d'avance (il ne vaut que pour une navigation)
  await s.ev('window.__m7 = {}'); await s.ev('VibeFlow.render()'); await s.attendre('!!window.__m7.calcul', 'calcul du redessin en direct');
  o.m7.direct = JSON.parse(await s.ev('JSON.stringify(window.__m7.calcul)')); await s.attendre(VUE_POSEE, 'vue posée après le redessin'); await pause(400);
  o.m7.petit = await mesurerNiveau("VibeFlow.go('root')", 'racine');

  const touche = async (key, code, vk) => { await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key, code, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk }); await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key, code, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk }); };
  // ---------- X7 : un seul format de titre d'onglet, repères d'accessibilité des trois pages ----------
  o.x7 = {};
  for (const [cle, page] of [['code', 'index.html'], ['projet', 'project.html'], ['equipe', 'equipe.html']]) {
    await charger(page, page);
    o.x7[cle] = JSON.parse(await s.ev(`JSON.stringify({ titre: document.title, main: document.querySelectorAll('main').length, courants: [...document.querySelectorAll('[aria-current]')].map((e) => e.textContent.trim() + '=' + e.getAttribute('aria-current')), nom: document.querySelector('#proj-name').textContent })`));
  }

  // ---------- X4 : un seul anneau de focus sur tout le parcours au clavier (page Code) ----------
  // de vraies touches Tab depuis le début de la page ; à chaque arrêt, l'anneau réellement dessiné : le contour de l'élément, ou celui de son formulaire quand c'est lui qui entoure le champ (:has / :focus-within)
  await charger('index.html', 'x4');
  const ANNEAU = `(() => { const a = document.activeElement; if (!a || a === document.body) return JSON.stringify({ fin: true });
    const sig = (e) => { const c = getComputedStyle(e); return (c.outlineStyle !== 'none' && parseFloat(c.outlineWidth) > 0) ? c.outlineWidth + ' ' + c.outlineStyle + ' ' + c.outlineColor : ''; };
    let r = sig(a); if (!r) { const f = a.closest('form'); if (f && sig(f)) r = sig(f); }
    const W = (window.__tabIds ||= new WeakMap()); if (!W.has(a)) W.set(a, (window.__tabN = (window.__tabN || 0) + 1));
    return JSON.stringify({ n: W.get(a), cle: a.id || a.tagName.toLowerCase() + '.' + String(a.className && a.className.baseVal !== undefined ? a.className.baseVal : a.className || '').split(/\\s+/)[0], anneau: r }); })()`;
  await s.ev("(() => { document.activeElement && document.activeElement.blur(); const d = document.createElement('span'); d.id = 'vf-depart'; d.tabIndex = -1; d.setAttribute('style', 'position:fixed;left:0;top:0;width:0;height:0'); document.body.prepend(d); d.focus(); })()");
  const arrets = [], vus = new Set();
  for (let i = 0; i < 80; i++) { await touche('Tab', 'Tab', 9); const a = JSON.parse(await s.ev(ANNEAU)); if (a.fin || vus.has(a.n)) break; vus.add(a.n); arrets.push(a); }
  await s.ev("document.getElementById('vf-depart')?.remove()");
  o.x4 = { arrets };

  // ---------- X6 : mouvement réduit ----------
  // animations actives (en cours ou sur le point de l'être) relevées dans la foulée d'une plongée : on attend que les cartes du niveau soient posées, puis on compte tout de suite
  const ANIMS = "document.getAnimations().filter((a) => a.playState === 'running' || a.playState === 'pending').length";
  const plonger = async () => {
    await s.ev("VibeFlow.go('root')"); await s.attendre(`VibeFlow.state.container === 'root' && ${VUE_POSEE}`, 'retour à la racine');
    await s.ev("VibeFlow.reveal('f:lots/n05.md')"); await s.attendre("VibeFlow.state.container !== 'root' && document.querySelectorAll('#viewport .node').length >= 70", 'cartes du niveau de 70 notes');
    return { actives: await s.ev(ANIMS), cartes: await s.ev("document.querySelectorAll('#viewport .node').length"), transitions: await s.ev("getComputedStyle(document.querySelector('#viewport')).transitionDuration") };
  };
  await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'no-preference' }] });
  await charger('index.html', 'x6 témoin'); o.x6 = { temoin: await plonger() };
  await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
  await charger('index.html', 'x6 réduit');
  o.x6.reduit = { repos: await s.ev(ANIMS), ...(await plonger()) };
  return o;
});
