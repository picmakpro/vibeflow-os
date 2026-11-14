// chrome-activite-lentilles.mjs — témoins navigateur de test-cockpit-activite-lentilles.sh (Phase 75, plan 75-08), dans un vrai Chrome headless sans affichage.
// Usage : node chrome-activite-lentilles.mjs <chrome> <racine-du-serveur> <sections>
//   <sections> : liste séparée par des virgules, parmi t1 (tâche 1), t2 (tâche 2), t3 (tâche 3) ; rend UNE ligne JSON { <section>: valeur } ou { erreur }.
// Le moteur de la page est lu tel quel ; la route /api/vf/activite est lue pour de vrai (lab construit par la suite) OU remplacée, à la demande d'une mesure,
// par `window.__act` (aide `pousser`) : un événement `git` du flux (`__emit`) déclenche alors la relecture, comme en production.
import { executer, stabiliser, pause } from './chrome-session.mjs';
import { AMORCE_FLUX } from './chrome-onglets.mjs';
import { sections } from './fixtures/test-cockpit-activite-lentilles/mesures.mjs';
const [, , chrome, racine, liste] = process.argv;
const voulues = new Set((liste || '').split(','));
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlow.state && !!window.VibeFlow.state.layout && document.documentElement.dataset.vfPret === 'oui'";
// la route : relevée (compteur de lectures) et, quand `window.__act` est posé, servie par la page à la place du serveur
const STUB = `(() => { window.__act = null; window.__reads = 0; const f0 = window.fetch;
  window.fetch = function (u, o) { if (String(u).includes('/api/vf/activite')) { window.__reads++; if (window.__act) return Promise.resolve(new Response(JSON.stringify(window.__act), { status: 200, headers: { 'content-type': 'application/json' } })); } return f0.apply(this, arguments); }; })();`;
// la visite du premier passage s'ouvre d'elle-même et prend Échap (40-tour.js : « tour-seen », 75-vf-modele.js : « vibeflow-cockpit:visite ») : ces clés sont lues comme posées
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) {"
  + " const vue = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0);"
  + " return vue ? 'true' : g.call(this, k); }; })()";
const KEYS = { ArrowDown: [40, ''], ArrowUp: [38, ''], Home: [36, ''], End: [35, ''], Enter: [13, '\r'], ' ': [32, ' '], Escape: [27, ''], Tab: [9, ''] };

await executer(chrome, async (s) => {
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: AMORCE_FLUX + ';' + STUB + ';' + SANS_VISITE });
  const vue = (w, h, tactile = false) => s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: tactile });
  const SNAP = `JSON.stringify([...VibeFlow.state.chipEls].map(([id, g]) => { const r = g.getBoundingClientRect(); return [id, Math.round(r.x * 10), Math.round(r.y * 10), Math.round(r.width * 10), Math.round(r.height * 10)]; }))`;
  const poser = async () => { await s.attendre("!!document.querySelector('#viewport .node') && document.querySelector('#viewport').style.opacity !== '0'", 'cartes dessinées'); return stabiliser(() => s.ev(SNAP), { pas: 150, max: 12000 }); };
  const charger = async (page = 'index.html') => {
    await s.naviguer(`${racine}/${page}?lang=fr`); await s.attendre(PRET, `page prête (${page})`);
    await s.ev("(() => { const t = document.querySelector('#tour'); if (t && !t.hidden) document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' })); })()");
    await s.attendre("!!document.getElementById('btn-lentilles') && window.__reads >= 1", 'sélecteur posé et première lecture');
    return poser();
  };
  const aller = async (id) => {
    await s.ev(`VibeFlow.go(${JSON.stringify(id)})`);
    await s.attendre(`VibeFlow.state.container === ${JSON.stringify(id)} && !!document.querySelector('#viewport .node')`, `vue ${id}`);
    return poser();
  };
  // une donnée de route poussée à la page : la relecture est déclenchée par un événement `git` du flux ; on attend qu'elle ait eu lieu, puis que le rendu se pose
  let seq = 9000;
  const pousser = async (d) => {
    const avant = await s.ev('window.__reads');
    await s.ev(`window.__act = ${JSON.stringify(d)}; window.__emit('git', { seq: ${++seq}, sig: 'sig${seq}', at: Date.now() })`);
    await s.attendre(`window.__reads > ${avant}`, 'relecture de la route');
    await pause(350);
  };
  const touche = async (key) => {
    const [vk, text] = KEYS[key];
    await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key, code: key === ' ' ? 'Space' : key, windowsVirtualKeyCode: vk, ...(text ? { text } : {}) });
    await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key, code: key === ' ' ? 'Space' : key, windowsVirtualKeyCode: vk });
    await pause(80);
  };
  const ouvrirMenu = async () => { if (!(await s.ev("document.getElementById('lens-menu').classList.contains('open')"))) { await s.ev("document.getElementById('btn-lentilles').click()"); await pause(120); } };
  const lentille = async (id) => { await ouvrirMenu(); await s.ev(`document.querySelector('#lens-menu .lr[data-id="${id}"]').click()`); await pause(250); };
  const ctx = { s, vue, charger, aller, poser, pousser, touche, ouvrirMenu, lentille, SNAP, racine, pause, stabiliser };
  const o = {};
  for (const [nom, mesure] of Object.entries(sections)) if (voulues.has(nom)) o[nom] = await mesure(ctx);
  return o;
});
