// chrome-neutre.mjs — attribut neutre des éléments flottants (80-neutre) : lecteurs (00 pile, 02 repères), tiroir Git, un vrai Chrome.
// Usage : node chrome-neutre.mjs <chrome> <racine-du-serveur> <mode>   Rend UNE ligne JSON { … } ou { erreur }.
//   tiroir         : tiroir Git ouvert, PUIS un petit bouton fixe posé sous body en bas à gauche (comme la pastille) :
//                    chevauche-t-il, sans redimensionnement ? (témoin : un redimensionnement le dégage)
//   pile           : palette ouverte, Échap tapé dans une région fixe ÉTRANGÈRE sous body : la pile la ferme-t-elle ?
//   pile-marque    : la même région porte data-vf-flottant="tiroir" : la pile la laisse à son Échap (palette encore ouverte)
//   reperes        : cartes hors champ, un bouton fixe étranger couvre la fenêtre : les repères restent-ils posés ?
//   reperes-marque : le même bouton porte data-vf-flottant="bouton" : c'est un obstacle, aucun repère ne trouve de place
//   reperes-sans   : témoin de méthode, le même geste sans aucun élément posé : les repères restent
import { executer, pause, stabiliser } from './chrome-session.mjs';
const [, , chrome, racine, mode] = process.argv;
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) {"
  + " const vue = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0);"
  + " return vue ? 'true' : g.call(this, k); }; })()";
const POSER = (balise, style, attrs = '') => `(() => { const b = document.createElement('${balise}'); b.id = 'flottant-etranger';
  b.textContent = 'étranger'; ${attrs} b.style.cssText = '${style}'; document.body.appendChild(b); return true; })()`;
const TIROIR = "document.getElementById('vf-git-tiroir')";
const BOITE = `JSON.stringify(${TIROIR}.getBoundingClientRect())`;
const CHEVAUCHE = `JSON.stringify((() => { const a = ${TIROIR}.getBoundingClientRect();
  const b = document.getElementById('flottant-etranger').getBoundingClientRect();
  return a.left < b.right && a.right > b.left && a.top < b.bottom && a.bottom > b.top; })())`;
const PALETTE = "document.getElementById('palette').classList.contains('open')";
await executer(chrome, async (s) => {
  const o = {};
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: SANS_VISITE });
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  await s.naviguer(`${racine}/index.html?lang=en`, { brut: true }); await s.attendre(PRET, 'page prête');
  await s.attendre("!!document.querySelector('#viewport .node')", 'cartes');
  await stabiliser(() => s.ev("document.querySelectorAll('#viewport .node').length"), { pas: 120, max: 5000 }); await pause(300);
  if (mode === 'tiroir') {
    await s.attendre('!!window.VFGitTiroir', 'tiroir Git');
    await s.ev('VFGitTiroir.ouvrir()');
    await s.attendre(`!!${TIROIR} && !${TIROIR}.hidden && ${TIROIR}.getBoundingClientRect().height > 0`, 'tiroir ouvert');
    // la lecture du tiroir finit d'abord (elle rejoue eviter à son retour) : le geste mesuré est l'arrivée de l'élément, jamais cette lecture
    await s.attendre("VFGitTiroir.donnees() !== null && !document.querySelector('#vf-git-tiroir .vf-git-corps[aria-busy]')", 'lecture rendue');
    await stabiliser(() => s.ev(BOITE), { pas: 150, max: 4000 }); await pause(300);
    await s.ev(POSER('button', 'position: fixed; left: 16px; bottom: 80px; width: 120px; height: 32px; z-index: 6'));
    await stabiliser(() => s.ev(BOITE), { pas: 150, max: 4000 }); await pause(300);
    o.apres = JSON.parse(await s.ev(CHEVAUCHE)); // sans redimensionnement
    await s.ev("window.dispatchEvent(new Event('resize'))"); await pause(300);
    o.temoin = JSON.parse(await s.ev(CHEVAUCHE)); // témoin : le redimensionnement, lui, dégage le tiroir (l'élément est de ceux qu'il évite)
  } else if (mode === 'pile' || mode === 'pile-marque') {
    await s.ev('document.activeElement && document.activeElement.blur()');
    for (const type of ['keyDown', 'keyUp']) {
      await s.send('Input.dispatchKeyEvent', { type, key: '/', code: 'Slash', windowsVirtualKeyCode: 191, nativeVirtualKeyCode: 191, text: '/' });
    }
    await s.attendre(PALETTE, 'palette ouverte'); await pause(150);
    const marque = mode === 'pile-marque' ? "b.setAttribute('data-vf-flottant', 'tiroir');" : '';
    await s.ev(`(() => { const b = document.createElement('section'); b.id = 'region-etrangere'; b.setAttribute('role', 'region');
      b.setAttribute('aria-label', 'étranger'); ${marque}
      b.style.cssText = 'position: fixed; left: 400px; bottom: 100px; width: 200px; height: 40px; z-index: 5';
      const f = document.createElement('button'); f.id = 'region-fils'; f.textContent = 'x';
      b.appendChild(f); document.body.appendChild(b); return true; })()`);
    await pause(400); // la pile observe les enfants de body : elle a statué
    o.pris = JSON.parse(await s.ev(`JSON.stringify((() => { const e = new KeyboardEvent('keydown', { key: 'Escape', bubbles: true, cancelable: true });
      document.getElementById('region-fils').dispatchEvent(e); return e.defaultPrevented; })())`));
    await pause(300); o.palette = JSON.parse(await s.ev(`JSON.stringify(${PALETTE})`));
  } else if (mode === 'reperes' || mode === 'reperes-marque' || mode === 'reperes-sans') {
    await s.ev('VF_CANEVAS.deplacer({ x: 3000, y: 0 })'); await pause(300);
    const n = () => s.ev("document.querySelectorAll('button.vf-repere').length");
    o.avant = await stabiliser(n, { pas: 150, max: 4000 });
    const marque = mode === 'reperes-marque' ? "b.setAttribute('data-vf-flottant', 'bouton');" : '';
    const plein = 'position: fixed; inset: 0; width: 100vw; height: 100vh; opacity: 0; pointer-events: none; z-index: 5';
    if (mode !== 'reperes-sans') await s.ev(POSER('button', plein, marque));
    await s.ev("document.body.classList.add('sonde-neutre')"); await pause(300); // 02 réévalue à tout changement de classe du corps
    o.apres = await stabiliser(n, { pas: 150, max: 4000 });
  }
  return o;
});
