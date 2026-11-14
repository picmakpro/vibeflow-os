// chrome-reco-onglets.mjs <chrome> <url> <pidServeur> — le serveur s'arrête pendant que DEUX onglets du même lab sont ouverts (79-14, SOCL-18, N5).
// L'onglet suiveur n'a construit aucun flux : il apprend la perte par le message `perdu` de l'élu, sans attendre la veille de 45 s.
// Relève la classe de la pastille des deux onglets toutes les 100 ms jusqu'à dix secondes. Rend { roles, tOff, fluxSuiveur, sondages } ou { erreur }.
import { executer, pause } from './chrome-session.mjs';
import { ouvrirOnglet, AMORCE_FLUX } from './chrome-onglets.mjs';
const [, , chrome, url, pid] = process.argv;
// SONDE TEMPORAIRE (76) : état de la pastille et du magasin de chaque onglet, avant l'arrêt et au verdict ; à retirer avec le correctif
const ERR = `(() => { window.__erreursSonde = []; const ps = (m) => window.__erreursSonde.push(String(m).slice(0, 160));
  addEventListener('error', (e) => ps(e.message)); const ce = console.error;
  console.error = (...a) => { ps(a.map(String).join(' ')); ce.apply(console, a); }; })()`;
const DIAG = `(() => { const b = document.getElementById('vf-lock'), E = window.VF_ETAT, P = window.__vfLive, C = window.VF_COQUILLE, F = window.Floorplan;
  let ab = null; try { ab = E.abonnes(); } catch (x) { ab = String(x); }
  return { badge: b ? b.className : null, aria: b ? b.getAttribute('aria-label') : null, connexion: E ? E.lire('connexion') : 'sans-magasin', abonnes: ab,
    connected: P ? P.connected : null, abandon: P ? P.abandon : null, sondages: P ? P.sondages : null, role: window.VF_FLUX ? window.VF_FLUX.role() : null,
    coquille: C ? Object.keys(C).join('|') : null, fenetre: !!(F && F.state && F.state.layout), hdr: !!document.querySelector('header .hr'),
    scripts: document.scripts.length, erreurs: window.__erreursSonde || [] }; })()`;
const OFF = "(() => { const b = document.getElementById('vf-lock'); return !!b && /(^| )off( |$)/.test(b.className); })()";
await executer(chrome, async (s) => {
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: AMORCE_FLUX + ';' + ERR });
  await s.naviguer(url);
  const o2 = await ouvrirOnglet(s, url, { amorce: AMORCE_FLUX + ';' + ERR });
  const onglets = [{ ev: s.ev }, o2];
  for (const o of onglets) await o.ev('0'); // onglet joignable
  await s.attendre('!!(window.__vfLive && window.__vfLive.connected) && window.VF_FLUX.role() !== null', 'onglet 1 connecté');
  await o2.attendre('!!(window.__vfLive && window.__vfLive.connected) && window.VF_FLUX.role() !== null', 'onglet 2 connecté');
  const roles = [await s.ev('window.VF_FLUX.role()'), await o2.ev('window.VF_FLUX.role()')];
  const avant = [await s.ev(DIAG), await o2.ev(DIAG)];
  process.kill(Number(pid), 'SIGTERM');
  const t0 = Date.now(); const tOff = [null, null];
  while (Date.now() - t0 < 10000 && tOff.includes(null)) {
    for (const [i, o] of onglets.entries()) if (tOff[i] === null && (await o.ev(OFF))) tOff[i] = Date.now() - t0;
    if (tOff.includes(null)) await pause(100);
  }
  const apres = [await s.ev(DIAG), await o2.ev(DIAG)];
  const suiveur = roles.indexOf('suiveur');
  const fluxSuiveur = suiveur < 0 ? null : (await onglets[suiveur].ev('window.__fluxUrl.length'));
  const sondages = [0, 0]; const finS = Date.now() + 10000; // attente active : le premier sondage part après le recul d'une seconde
  while (Date.now() < finS && sondages.some((n) => !(n >= 1))) { for (const [i, o] of onglets.entries()) sondages[i] = await o.ev('window.__vfLive.sondages'); if (sondages.some((n) => !(n >= 1))) await pause(200); }
  await o2.fermer();
  return { roles, tOff, fluxSuiveur, sondages, sonde: { avant, apres } };
});
