// chrome-reco-onglets.mjs <chrome> <url> <pidServeur> — le serveur s'arrête pendant que DEUX onglets du même lab sont ouverts (79-14, SOCL-18, N5).
// L'onglet suiveur n'a construit aucun flux : il apprend la perte par le message `perdu` de l'élu, sans attendre la veille de 45 s.
// Relève la classe de la pastille des deux onglets toutes les 100 ms jusqu'à dix secondes. Rend { roles, tOff, fluxSuiveur, sondages } ou { erreur }.
import { executer, pause } from './chrome-session.mjs';
import { ouvrirOnglet, AMORCE_FLUX } from './chrome-onglets.mjs';
const [, , chrome, url, pid] = process.argv;
const OFF = "(() => { const b = document.getElementById('vf-lock'); return !!b && /(^| )off( |$)/.test(b.className); })()";
await executer(chrome, async (s) => {
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: AMORCE_FLUX });
  await s.naviguer(url);
  const o2 = await ouvrirOnglet(s, url, { amorce: AMORCE_FLUX });
  const onglets = [{ ev: s.ev }, o2];
  for (const o of onglets) await o.ev('0'); // onglet joignable
  await s.attendre('!!(window.__vfLive && window.__vfLive.connected) && window.VF_FLUX.role() !== null', 'onglet 1 connecté');
  await o2.attendre('!!(window.__vfLive && window.__vfLive.connected) && window.VF_FLUX.role() !== null', 'onglet 2 connecté');
  const roles = [await s.ev('window.VF_FLUX.role()'), await o2.ev('window.VF_FLUX.role()')];
  process.kill(Number(pid), 'SIGTERM');
  const t0 = Date.now(); const tOff = [null, null];
  while (Date.now() - t0 < 10000 && tOff.includes(null)) {
    for (const [i, o] of onglets.entries()) if (tOff[i] === null && (await o.ev(OFF))) tOff[i] = Date.now() - t0;
    if (tOff.includes(null)) await pause(100);
  }
  const suiveur = roles.indexOf('suiveur');
  const fluxSuiveur = suiveur < 0 ? null : (await onglets[suiveur].ev('window.__fluxUrl.length'));
  const sondages = [0, 0]; const finS = Date.now() + 10000; // attente active : le premier sondage part après le recul d'une seconde
  while (Date.now() < finS && sondages.some((n) => !(n >= 1))) { for (const [i, o] of onglets.entries()) sondages[i] = await o.ev('window.__vfLive.sondages'); if (sondages.some((n) => !(n >= 1))) await pause(200); }
  await o2.fermer();
  return { roles, tOff, fluxSuiveur, sondages };
});
