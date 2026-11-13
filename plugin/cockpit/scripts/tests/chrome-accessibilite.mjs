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
    // 79-16 : si la coquille ne se dit jamais prête, l'échec porte l'état de la page (diagnostic d'une panne vue seulement en CI, aucune assertion touchée)
    try { await s.naviguer(`${racine}/${page}?lang=en`); } catch (e) {
      let d = 'état illisible'; try { d = await s.ev("JSON.stringify({ href: location.href, rs: document.readyState, pret: document.documentElement.dataset.vfPret, etat: window.VF_COQUILLE && VF_COQUILLE.etat(), moteur: !!window.VibeFlow, erreurs: window.__err, scripts: document.scripts.length, t: Math.round(performance.now()) })"); } catch {}
      throw new Error(`${e.message} — ${d}`); }
    await s.attendre(PRET, `page prête (${nom})`);
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
    window.__err = []; addEventListener('error', (e) => window.__err.push(String(e.message) + ' ' + (e.filename || (e.target && e.target.src) || '')), true); addEventListener('unhandledrejection', (e) => window.__err.push('rejet ' + String(e.reason && e.reason.message || e.reason)));
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

  // ---------- X4 : un seul anneau de focus sur tout le parcours au clavier (trois pages) ----------
  // de vraies touches Tab depuis le début de la page ; à chaque arrêt, l'anneau réellement dessiné : le contour de l'élément, ou celui de son formulaire quand c'est lui qui entoure le champ (:has / :focus-within)
  o.x4 = {};
  for (const [cle, page] of [['code', 'index.html'], ['projet', 'project.html'], ['equipe', 'equipe.html']]) {
    await charger(page, 'x4 ' + page);
    const ANNEAU = `(() => { const a = document.activeElement; if (!a || a === document.body) return JSON.stringify({ fin: true });
      const sig = (e) => { const c = getComputedStyle(e); return (c.outlineStyle !== 'none' && parseFloat(c.outlineWidth) > 0) ? c.outlineWidth + ' ' + c.outlineStyle + ' ' + c.outlineColor : ''; };
      let r = sig(a); if (!r) { const f = a.closest('form'); if (f && sig(f)) r = sig(f); }
      if (!r && a.matches('g.node')) { const c = a.querySelector('.card'); if (c) r = sig(c); } // 80-01 (P80-D-36) : l'anneau d'une carte du canevas se dessine sur sa .card, jamais sur le g
      const W = (window.__tabIds ||= new WeakMap()); if (!W.has(a)) W.set(a, (window.__tabN = (window.__tabN || 0) + 1));
      return JSON.stringify({ n: W.get(a), cle: a.id || a.tagName.toLowerCase() + '.' + String(a.className && a.className.baseVal !== undefined ? a.className.baseVal : a.className || '').split(/\\s+/)[0], anneau: r }); })()`;
    await s.ev("(() => { document.activeElement && document.activeElement.blur(); const d = document.createElement('span'); d.id = 'vf-depart'; d.tabIndex = -1; d.setAttribute('style', 'position:fixed;left:0;top:0;width:0;height:0'); document.body.prepend(d); d.focus(); })()");
    const arrets = [], vus = new Set();
    for (let i = 0; i < 80; i++) { await touche('Tab', 'Tab', 9); const a = JSON.parse(await s.ev(ANNEAU)); if (a.fin || vus.has(a.n)) break; vus.add(a.n); arrets.push(a); }
    await s.ev("document.getElementById('vf-depart')?.remove()");
    o.x4[cle] = arrets;
  }

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
  // repères utiles, statiques : la carte repérée par la plongée porte un contour fixe (pas d'animation) puis le perd ; l'attente de « Demander » reste un anneau lisible ; les entrées qui retirent leur classe sur animationend la perdent quand même
  o.x6.reduit.flash = { pose: await s.attendre("!!document.querySelector('#viewport .node.flash')", 'carte repérée').then(() => true, () => false) };
  o.x6.reduit.flash.mesure = JSON.parse(await s.ev("JSON.stringify((() => { const c = document.querySelector('#viewport .node.flash .card'); if (!c) return null; const k = getComputedStyle(c); return { anim: k.animationName, contour: k.outlineColor, largeur: k.outlineWidth }; })())"));
  o.x6.reduit.flash.perdu = await s.attendre("!document.querySelector('#viewport .node.flash')", 'contour retiré', 4000).then(() => true, () => false);
  o.x6.reduit.attente = JSON.parse(await s.ev("JSON.stringify((() => { const e = document.createElement('span'); e.className = 'spin'; e.style.display = 'inline-flex'; document.body.appendChild(e); const k = getComputedStyle(e); const r = { anim: k.animationName, actives: e.getAnimations().length, largeur: e.getBoundingClientRect().width, quartColore: k.borderTopColor !== k.borderRightColor }; e.remove(); return r; })())"));
  await s.ev("(() => { const e = document.createElement('div'); e.id = 'vf-essai-entree'; e.className = 'vf-git-entree'; e.addEventListener('animationend', () => e.classList.remove('vf-git-entree')); document.body.appendChild(e); })()");
  o.x6.reduit.entree = await s.attendre("!document.getElementById('vf-essai-entree').classList.contains('vf-git-entree')", 'classe d\'entrée retirée', 3000).then(() => true, () => false);
  return o;
});
