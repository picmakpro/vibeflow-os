// chrome-pointeur.mjs — témoins de pointeur de Projet (correction CI Phase 80, P80-D-50 b) dans un vrai Chrome headless.
// Usage : node chrome-pointeur.mjs <chrome> <racine-du-serveur> <mode>   Rend UNE ligne JSON { … } ou { erreur }.
//   none     : <chrome> est lancé SANS aucun pointeur (le Chrome sans tête de Linux : pointer none) ; mesure le panneau latéral à 1440 px
//   coarse   : toucher émulé (pointer: coarse) à 1440 px ; la feuille de détail s'applique, rien ne doit changer
//   etranger : un bouton fixe étranger sous body est-il pris pour la pastille « Terminal » ? (80-neutre : non, seul l'attribut data-vf-flottant la désigne)
//   marque   : le même bouton fixe porte data-vf-flottant="bouton" (l'attribut neutre posé par le terminal) : il est mesuré, la zone basse grandit
//   div      : un DIV fixe étranger sous body (pas un bouton) : la zone basse doit rester inchangée (témoin négatif)
//   nonfixe  : un BOUTON étranger non fixe sous body (pas position: fixed) : la zone basse doit rester inchangée (témoin négatif)
import { executer, pause, stabiliser } from './chrome-session.mjs';
const [, , chrome, racine, mode] = process.argv;
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) {"
  + " const vue = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0);"
  + " return vue ? 'true' : g.call(this, k); }; })()";
await executer(chrome, async (s) => {
  const o = {};
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: SANS_VISITE });
  const tactile = mode === 'coarse';
  await s.send('Emulation.setTouchEmulationEnabled', { enabled: tactile });
  await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: tactile });
  await s.naviguer(`${racine}/project.html?vue=couloirs`, { brut: true }); await s.attendre(PRET, 'page prête');
  await stabiliser(() => s.ev("document.querySelectorAll('.vp-carte').length"), { pas: 120, max: 5000 }); await pause(300);
  const bas = () => s.ev("getComputedStyle(document.querySelector('section.vf-projet')).getPropertyValue('--vf-bas')");
  if (['etranger', 'marque', 'div', 'nonfixe'].includes(mode)) {
    o.avant = await bas();
    const [balise, pos] = mode === 'div' ? ['div', 'fixed'] : mode === 'nonfixe' ? ['button', 'absolute'] : ['button', 'fixed'];
    await s.ev(`(() => { const b = document.createElement('${balise}'); b.id = 'etranger'; b.textContent = 'étranger';${mode === 'marque' ? " b.setAttribute('data-vf-flottant', 'bouton');" : ''}
      b.style.cssText = 'position: ${pos}; left: 16px; bottom: 16px; height: 120px; width: 120px; z-index: 5'; document.body.appendChild(b); window.dispatchEvent(new Event('resize')); })()`);
    await pause(500);
    o.apres = await bas();
  } else {
    o.pointeur = JSON.parse(await s.ev("JSON.stringify({ fine: matchMedia('(pointer: fine)').matches, coarse: matchMedia('(pointer: coarse)').matches })"));
    o.spie = await s.ev("getComputedStyle(document.querySelector('section.vf-projet')).scrollPaddingInlineEnd");
  }
  return o;
});
