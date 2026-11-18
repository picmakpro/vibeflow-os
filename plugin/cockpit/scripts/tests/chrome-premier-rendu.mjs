// chrome-premier-rendu.mjs — le premier rendu du cockpit sur téléphone (porte de vf-coquille.js) : à chaque image, ce qui est VISIBLE à l'écran.
// Usage : node chrome-premier-rendu.mjs <chrome> <url> <mode>
//   telephone  390 × 844, tactile, scripts /_vf/ ralentis de 40 ms chacun (un tunnel) : Code et Projet, visite déjà vue puis première visite
//   bureau     1 280 × 800, souris, mêmes scripts ralentis : la porte n'y masque rien
//   echec      390 × 844, la lecture des données refusée : l'écran « Lecture impossible » visible, la porte ouverte
// Rend une ligne JSON { <cas>: { images: [[t, pret, porte, entete, zoom, visite, carte]], ... } } ou { erreur }.
// Visible = boîte non vide, ni display none, ni visibility hidden, et aucune opacité nulle sur la chaîne des ancêtres (la porte joue sur l'opacité).
import { executer, pause } from './chrome-session.mjs';
const [, , chrome, url, mode] = process.argv;

const AMORCE = (vue) => `(() => {
  ${vue ? '' : "try { localStorage.clear(); } catch { /* stockage refusé */ }"}
  const vue = ${vue ? 'true' : 'false'}, g = Storage.prototype.getItem; // visite déjà vue : la clé de la visite lue « vue »
  if (vue) Storage.prototype.getItem = function (k) { return /^vibeflow-cockpit:visite:|tour-seen:/.test(String(k)) ? 'true' : g.call(this, k); };
  const t0 = performance.now(), images = window.__images = [];
  const vu = (e) => {
    if (!e || !e.isConnected) return false;
    const r = e.getBoundingClientRect(); if (!r.width || !r.height) return false;
    for (let x = e; x && x.nodeType === 1; x = x.parentElement) {
      const s = getComputedStyle(x); if (s.display === 'none' || Number(s.opacity) === 0) return false;
    }
    return getComputedStyle(e).visibility !== 'hidden';
  };
  const pos = (e) => { const r = e.getBoundingClientRect(); return Math.round(r.x) + ',' + Math.round(r.y); };
  const image = () => {
    const H = document.documentElement, hd = document.querySelector('body > header');
    const nom = (b) => (b.id || b.getAttribute('aria-label') || b.textContent.trim()).slice(0, 24);
    const entete = hd ? [...hd.querySelectorAll('button, a')].filter(vu).map((b) => nom(b) + '@' + pos(b)).join(' ') : '';
    const z = document.getElementById('zoom'), vp = document.getElementById('viewport'), svg = document.getElementById('svg');
    const ligne = [H.dataset.vfPret || '', H.dataset.vfPorte || '', entete, vu(z) ? pos(z) : '', vu(document.getElementById('tour')),
      vu(svg) && vp ? (vp.style.transform || vp.getAttribute('transform') || '') : '',
      vu(document.getElementById('vf-coquille-echec')) || vu(document.getElementById('vf-onglets-echec'))];
    const der = images.at(-1), cle = JSON.stringify(ligne);
    if (!der || JSON.stringify(der.slice(1)) !== cle) images.push([Math.round(performance.now() - t0), ...ligne]);
    if (performance.now() - t0 < 20000) requestAnimationFrame(image);
  };
  requestAnimationFrame(image);
})();`;

executer(chrome, async (s) => {
  const tel = mode !== 'bureau';
  const ecran = tel ? { width: 390, height: 844, deviceScaleFactor: 3, mobile: true } : { width: 1280, height: 800, deviceScaleFactor: 1, mobile: false };
  await s.send('Emulation.setDeviceMetricsOverride', ecran);
  if (tel) await s.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 });
  await s.send('Emulation.setEmitTouchEventsForMouse', { enabled: tel });
  let refuser = false;
  s.ecouter('Fetch.requestPaused', async (p) => {
    try {
      if (refuser && /\/api\/vf\/graphe/.test(p.request.url)) await s.send('Fetch.failRequest', { requestId: p.requestId, errorReason: 'ConnectionRefused' });
      else { if (/\/_vf\//.test(p.request.url)) await pause(40); await s.send('Fetch.continueRequest', { requestId: p.requestId }); }
    } catch { /* page déjà quittée */ }
  });
  await s.send('Fetch.enable', { patterns: [{ urlPattern: '*/_vf/*' }, { urlPattern: '*/api/vf/graphe*' }] });
  const cas = {};
  let amorce = null;
  const jouer = async (nom, chemin, vue, { echec = false, attente = 2500 } = {}) => {
    if (amorce) await s.send('Page.removeScriptToEvaluateOnNewDocument', { identifier: amorce });
    amorce = (await s.send('Page.addScriptToEvaluateOnNewDocument', { source: AMORCE(vue) })).identifier;
    refuser = echec;
    await s.naviguer(url + chemin, { echec });
    await pause(attente);
    cas[nom] = { images: await s.ev('window.__images') };
  };
  if (mode === 'echec') await jouer('echec', '/', true, { echec: true, attente: 800 });
  else {
    await jouer('code-vue', '/', true);
    await jouer('projet-vue', '/project.html', true);
    if (tel) { await jouer('code-premiere', '/', false); await jouer('projet-premiere', '/project.html', false); }
  }
  return cas;
});
