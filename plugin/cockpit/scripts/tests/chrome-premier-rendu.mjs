// chrome-premier-rendu.mjs — le premier rendu du cockpit sur téléphone (porte de vf-coquille.js) : à chaque image, ce qui est VISIBLE à l'écran.
// Usage : node chrome-premier-rendu.mjs <chrome> <url> <mode>
//   telephone  390 × 844, tactile, scripts /_vf/ ralentis de 40 ms chacun (un tunnel) : Code et Projet, visite déjà vue puis première visite
//   bureau     1 280 × 800, souris, mêmes scripts ralentis : la porte n'y masque rien
//   echec      390 × 844, la lecture des données refusée : l'écran « Lecture impossible » visible, la porte ouverte
//   tunnel, tunnel-bureau, tunnel-echec : scripts /_vf/ retenus 150 ms chacun (VF_PR_LATENCE_MS) ; Code, Projet, changement d'onglet (et mouvement réduit
//              sur téléphone) ; rend { <cas>: { porte, enVolMax, requetes, doubles, indic: [[t, visible, porte]], anim, surEchec, csp } }
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

// modes tunnel : chaque requête /_vf/ retenue LATENCE ms (un aller-retour de tunnel, pas de débit ; la limite de six connexions d'HTTP/1.1 n'est pas
// simulée, la pause précède l'envoi) ; relève le plus grand nombre de requêtes /_vf/ retenues en même temps (en vol), les fichiers demandés deux fois,
// les refus de la CSP et, dans la page, l'instant de l'ouverture de la porte et, à chaque image, l'indicateur de chargement (::after de la racine)
const LATENCE = Number(process.env.VF_PR_LATENCE_MS) || 150;
const AMORCE_TUNNEL = `(() => {
  try { localStorage.clear(); } catch { /* stockage refusé */ }
  const g = Storage.prototype.getItem; // visite déjà vue
  Storage.prototype.getItem = function (k) { return /^vibeflow-cockpit:visite:|tour-seen:/.test(String(k)) ? 'true' : g.call(this, k); };
  const T = window.__tunnel = { porte: [], indic: [], anim: [], echec: false };
  const vu = (e) => { if (!e || !e.isConnected) return false; const r = e.getBoundingClientRect(); if (!r.width || !r.height) return false;
    for (let x = e; x && x.nodeType === 1; x = x.parentElement) {
      const s = getComputedStyle(x); if (s.display === 'none' || s.visibility === 'hidden' || Number(s.opacity) === 0) return false;
    }
    return true; };
  // la porte : relevée à chaque écriture de l'attribut (une image peut la manquer), l'indicateur : à chaque image
  // (le document entier est observé : la racine n'existe pas encore quand cette amorce s'exécute)
  const porte = () => T.porte.push([Math.round(performance.now()), document.documentElement?.dataset.vfPorte || '']);
  new MutationObserver(porte).observe(document, { attributes: true, subtree: true, attributeFilter: ['data-vf-porte'] });
  const image = () => {
    const H = document.documentElement, p = H.dataset.vfPorte || '', a = getComputedStyle(H, '::after'), d = T.indic.at(-1);
    const v = a.content !== 'none' && a.display !== 'none' && a.visibility === 'visible' && parseFloat(a.width) > 0;
    if (!d || d[1] !== v) T.indic.push([Math.round(performance.now()), v, p]);
    if (v && !T.anim.includes(a.animationName)) T.anim.push(a.animationName);
    if (vu(document.getElementById('vf-coquille-echec')) && v) T.echec = true; // l'indicateur visible avec l'écran d'échec
    requestAnimationFrame(image);
  };
  requestAnimationFrame(image);
})();`;
async function tunnel(s, { tel, echec = false }) {
  const ecran = tel ? { width: 390, height: 844, deviceScaleFactor: 3, mobile: true } : { width: 1280, height: 800, deviceScaleFactor: 1, mobile: false };
  await s.send('Emulation.setDeviceMetricsOverride', ecran);
  let enVol = 0, max = 0, n = 0, refuser = false, urls = [];
  s.ecouter('Fetch.requestPaused', async (p) => {
    try {
      if (refuser && /\/api\/vf\/graphe/.test(p.request.url)) {
        await s.send('Fetch.failRequest', { requestId: p.requestId, errorReason: 'ConnectionRefused' }); return;
      }
      if (!/\/_vf\//.test(p.request.url)) { await s.send('Fetch.continueRequest', { requestId: p.requestId }); return; }
      n++; enVol++; max = Math.max(max, enVol); urls.push(p.request.url.replace(/^.*\/_vf\//, ''));
      await pause(LATENCE); enVol--;
      await s.send('Fetch.continueRequest', { requestId: p.requestId });
    } catch { /* page déjà quittée */ }
  });
  await s.send('Fetch.enable', { patterns: [{ urlPattern: '*/_vf/*' }, { urlPattern: '*/api/vf/graphe*' }] });
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: AMORCE_TUNNEL });
  const cas = {}, ouverte = "document.documentElement.dataset.vfPorte === 'ouverte'";
  const releve = async (porte) => {
    await pause(400); const t = await s.ev('window.__tunnel');
    return { porte, enVolMax: max, requetes: n, doubles: urls.filter((u, i) => urls.indexOf(u) !== i), indic: t.indic, anim: t.anim, surEchec: t.echec,
      csp: s.violations.slice() };
  };
  const jouer = async (nom, chemin) => {
    max = 0; n = 0; urls = [];
    await s.naviguer(url + chemin, { echec });
    await s.attendre(ouverte, 'porte ouverte', 60000);
    cas[nom] = await releve((await s.ev('window.__tunnel.porte')).find((x) => x[1] === 'ouverte')?.[0] ?? -1);
  };
  if (echec) { refuser = true; await jouer('echec', '/'); return cas; }
  await jouer('code', '/');
  await jouer('projet', '/project.html');
  // changement d'onglet : Projet -> Code par la coquille, porte refermée puis rouverte
  max = 0; n = 0; urls = [];
  const t0 = await s.ev("window.__tunnel.indic.length = 0, window.__tunnel.anim.length = 0, performance.now()");
  await s.ev("VF_COQUILLE.chargerOnglet('code').then(() => true)");
  await s.attendre(ouverte, 'porte rouverte', 60000);
  cas.changement = await releve(Math.round((await s.ev('performance.now()')) - t0));
  if (tel) { // mouvement réduit : l'indicateur paraît, immobile
    await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
    await jouer('reduit', '/');
    await s.send('Emulation.setEmulatedMedia', { features: [] });
  }
  return cas;
}

executer(chrome, async (s) => {
  if (/^tunnel/.test(mode)) return tunnel(s, { tel: mode !== 'tunnel-bureau', echec: mode === 'tunnel-echec' });
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
}, { csp: /^tunnel/.test(mode) });
