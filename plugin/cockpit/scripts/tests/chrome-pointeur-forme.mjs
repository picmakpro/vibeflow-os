// chrome-pointeur-forme.mjs — témoins de pointeur des modules de Projet et du coin (Phase 80, P80-D-50 b) dans un vrai Chrome headless.
// Usage : node chrome-pointeur-forme.mjs <chrome> <racine-du-serveur> <mode> <sonde>   (ou <mode>:<sonde> en un seul argument)   Rend UNE ligne JSON { … } ou { erreur }.
//   mode  none   : <chrome> est lancé SANS aucun pointeur (le Chrome sans tête de Linux : pointer none), pas de toucher émulé
//         coarse : toucher émulé (pointer: coarse)
//   sonde liste   : 41-vf-projet-liste.js    — le focus d'une rangée `.vp-ligne` la sélectionne-t-il (panneau latéral) ?
//         clavier : 41-vf-projet-clavier.js  — le focus d'une carte `.vp-carte` la sélectionne-t-il (panneau latéral) ?
//         coin    : 02-vf-coin.js            — la minicarte `#vf-minicarte` est-elle posée (souris) ?
// Toutes les sondes rendent aussi le pointeur annoncé (fine, coarse) et la largeur : le témoin se lit sur sa propre fixture.
import { executer, pause, stabiliser } from './chrome-session.mjs';
const [, , chrome, racine, modeArg, sondeArg] = process.argv;
const [mode, sonde] = sondeArg ? [modeArg, sondeArg] : modeArg.split(':'); // « mode:sonde » en un seul argument (les mesurer qui n'en passent qu'un)
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) {"
  + " const vue = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0);"
  + " return vue ? 'true' : g.call(this, k); }; })()";
const VUES = { liste: 'liste', clavier: 'couloirs', coin: 'graphe' };
await executer(chrome, async (s) => {
  const o = { sonde };
  const tactile = mode === 'coarse';
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: SANS_VISITE });
  await s.send('Emulation.setTouchEmulationEnabled', { enabled: tactile });
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: tactile });
  await s.naviguer(`${racine}/project.html?vue=${VUES[sonde]}&lang=en`, { brut: true }); await s.attendre(PRET, 'page prête');
  const sel = sonde === 'liste' ? '.vp-ligne' : sonde === 'clavier' ? '.vp-carte' : '#vf-minicarte';
  await stabiliser(() => s.ev(`document.querySelectorAll('.vp-ligne, .vp-carte, #viewport .node').length`), { pas: 120, max: 5000 }); await pause(600);
  o.pointeur = JSON.parse(await s.ev("JSON.stringify({ fine: matchMedia('(pointer: fine)').matches, coarse: matchMedia('(pointer: coarse)').matches, larg: innerWidth })"));
  if (sonde === 'coin') {
    o.mini = JSON.parse(await s.ev(`JSON.stringify((() => { const m = document.querySelector('#vf-minicarte'); return { existe: !!m, cache: !!m && m.hasAttribute('hidden'),
      pose: !!m && m.getClientRects().length > 0, cartes: VibeFlow.state.layout.children.length }; })())`));
  } else {
    // une rangée / carte NON sélectionnée prend le focus par le chemin des évènements (jamais par la sélection) : la sélection suit-elle le focus ?
    o.focus = JSON.parse(await s.ev(`(() => { if (window.Floorplan) Floorplan.select(null); const els = [...document.querySelectorAll('section.vf-projet ${sel}')];
      const el = els.find((e) => e.dataset.id) || null; if (!el) return JSON.stringify({ n: els.length });
      el.focus(); return JSON.stringify({ n: els.length, id: el.dataset.id, actif: document.activeElement === el, sel: VibeFlow.state.selected }); })()`));
  }
  return o;
});
