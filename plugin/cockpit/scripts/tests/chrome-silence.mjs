// chrome-silence.mjs <chrome> <url> <scénario> — la veille de 45 s dans Chrome SANS attendre 46 s (79-14, SOCL-18, D-M2 côté page).
// L'horloge de la page est décalée DEPUIS L'EXTÉRIEUR : une amorce, posée par le protocole avant les scripts de la page, remplace Date.now par une version
// décalée de window.__decalage et enveloppe EventSource pour que les écouteurs ne reçoivent rien tant que window.__muet est vrai (le flux reste ouvert,
// la page ne reçoit rien). Aucun réglage ni porte dans le code de production, qui ne lit que Date.now.
//   « muet »  : S1.1 avant le silence la pastille n'est pas « coupé » et la connexion vaut ouvert · S1.2 silence de 44 s : pas coupé après 2,5 s réelles
//               S1.3 silence de 46 s : pastille « Direct coupé » (classe off) en quelques secondes réelles, connexion perdu · S1.4 muet levé : flux rouvert, retour à ouvert
//   « sain »  : S1.5 flux sain, battement du vrai serveur : recus.vie au moins 1 en 18 s, la pastille n'est jamais passée en off
// Rend { avant, a44, a46, tCoupe, reouvert, vie, jamaisOff } ou { erreur }. Attentes actives et bornées.
import { executer, pause } from './chrome-session.mjs';
const [, , chrome, url, scenario = 'muet'] = process.argv;
const AMORCE = `(() => { window.__muet = false; window.__decalage = 0; window.__es = []; const D = Date.now.bind(Date); Date.now = () => D() + window.__decalage;
  const O = window.EventSource; if (!O) return;
  window.EventSource = class extends O { constructor(u, o) { super(u, o); window.__es.push(this); }
    addEventListener(n, f, ...r) { super.addEventListener(n, (e) => { if (!window.__muet) f(e); }, ...r); } }; })();`;
const PASTILLE = "(() => { const b = document.getElementById('vf-lock'); return { off: !!b && /(^| )off( |$)/.test(b.className), txt: b ? b.textContent : null, conn: window.VF_FLUX.connexion() }; })()";
await executer(chrome, async (s) => {
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: AMORCE });
  await s.naviguer(url);
  await s.attendre('!!(window.__vfLive && window.__vfLive.connected) && window.VF_FLUX.connexion() === "ouvert"', 'direct connecté, connexion ouverte');
  if (scenario === 'sain') {
    await s.ev("window.__off = false; new MutationObserver(() => { const b = document.getElementById('vf-lock'); if (b && /(^| )off( |$)/.test(b.className)) window.__off = true; })"
      + ".observe(document.body, { subtree: true, attributes: true, childList: true })");
    let vie = 0; const fin = Date.now() + 18000;
    while (Date.now() < fin && vie < 1) { await pause(250); vie = (await s.ev('window.VF_FLUX.diagnostic().recus.vie || 0')) || 0; }
    return { vie, jamaisOff: !(await s.ev('window.__off')), avant: await s.ev(PASTILLE) };
  }
  const avant = await s.ev(PASTILLE);
  // silence effectif réglé d'après l'instant du dernier événement lu dans la page : 41 s (et 2,5 s réelles d'observation : < 45 s), puis 46 s
  const regler = (silence) => s.ev(`window.__decalage = ${silence} - (Date.now() - window.__decalage - window.VF_FLUX.diagnostic().derniereA)`);
  await s.ev('window.__muet = true'); await regler(41000); await pause(2500); const a44 = await s.ev(PASTILLE);
  await regler(46000); const t0 = Date.now(); let a46 = await s.ev(PASTILLE); const limite = t0 + 8000;
  while (!a46.off && Date.now() < limite) { await pause(100); a46 = await s.ev(PASTILLE); }
  const tCoupe = a46.off ? Date.now() - t0 : null;
  await s.ev('window.__muet = false; window.__decalage = 0');
  const limiteR = Date.now() + 20000; let apres = null; let nbFlux = 0;
  while (Date.now() < limiteR) {
    apres = await s.ev(PASTILLE); nbFlux = await s.ev('window.__es.length');
    if (nbFlux >= 2 && !apres.off && apres.conn === 'ouvert') break;
    await pause(200);
  }
  return { avant, a44, a46, tCoupe, reouvert: nbFlux >= 2 && !apres.off && apres.conn === 'ouvert', fluxConstruits: nbFlux };
});
