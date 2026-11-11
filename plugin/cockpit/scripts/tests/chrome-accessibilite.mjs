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
  o.m7.petit = await mesurerNiveau("VibeFlow.go('root')", 'racine');

  const touche = async (key, code, vk) => { await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key, code, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk }); await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key, code, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk }); };
  // ---------- X7 : un seul format de titre d'onglet, repères d'accessibilité des trois pages ----------
  o.x7 = {};
  for (const [cle, page] of [['code', 'index.html'], ['projet', 'project.html'], ['equipe', 'equipe.html']]) {
    await charger(page, page);
    o.x7[cle] = JSON.parse(await s.ev(`JSON.stringify({ titre: document.title, main: document.querySelectorAll('main').length, courants: [...document.querySelectorAll('[aria-current]')].map((e) => e.textContent.trim() + '=' + e.getAttribute('aria-current')), nom: document.querySelector('#proj-name').textContent })`));
  }

  return o;
});
