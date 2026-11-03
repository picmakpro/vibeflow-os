// chrome-visite.mjs — la visite « Par où commencer » ne revient pas d'elle-même, par lab, d'un lancement du serveur à l'autre (recette 3, O4).
// Usage : node chrome-visite.mjs <chrome> <urlA> <urlB> <urlC>
//   urlA et urlB : le MÊME lab servi sur deux ports (deux lancements) ; urlC : un AUTRE lab. UN seul Chrome, donc un seul profil : le localStorage de A et de B sont deux origines.
//   Rend sur une ligne { premiere, memeOrigine, autrePort, autreLab, bouton, temoins } ou { erreur }.
//   premiere = visite affichée au premier chargement · memeOrigine = revient au rechargement de A · autrePort = revient sur B · autreLab = affichée sur C (le rangement est par lab, pas global)
//   bouton = « Par où commencer » la rouvre sur B · temoins = chaque page « sans visite » avait bien fini son initialisation (lab connu : sélecteur de modèle posé).
import { executer, pause } from './chrome-session.mjs';
const [, , chrome, urlA, urlB, urlC] = process.argv;
const VISIBLE = "(() => { const t = document.getElementById('tour'); return !!t && !t.hidden; })()";
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlowTour && !!document.getElementById('tour-btn')";
const INIT = "!!window.__vfModele && !!window.__vfModele.modele"; // 75-vf-modele.js a lu le lab : la décision de la visite est prise
await executer(chrome, async (s) => {
  const charge = async (url) => { await s.naviguer(url); await s.attendre(PRET, `page prête (${url})`); await s.attendre(INIT, `lab connu (${url})`); };
  const absente = async () => { await pause(2500); return !(await s.ev(VISIBLE)); }; // le démarrage d'office attend 700 ms après le rendu ; 2,5 s de marge
  await charge(urlA);
  const premiere = await s.attendre(VISIBLE, 'visite affichée au premier chargement', 15000).then(() => true, () => false);
  await s.ev('window.VibeFlowTour.end()');
  await charge(urlA); const memeOrigine = !(await absente());
  await charge(urlB); const autrePort = !(await absente());
  const temoinsB = await s.ev("document.getElementById('vf-modele') !== null");
  await s.ev("document.getElementById('tour-btn').click()"); const bouton = await s.attendre(VISIBLE, 'visite rouverte par le bouton', 5000).then(() => true, () => false);
  await s.ev('window.VibeFlowTour.end()');
  await charge(urlC); const autreLab = await s.attendre(VISIBLE, 'visite affichée sur un autre lab', 15000).then(() => true, () => false);
  return { premiere, memeOrigine, autrePort, autreLab, bouton, temoins: temoinsB };
});
