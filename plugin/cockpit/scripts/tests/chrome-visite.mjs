// chrome-visite.mjs — la visite « Par où commencer » ne revient pas d'elle-même, par lab, d'un chargement et d'un lancement du serveur à l'autre (recette 3, O4).
// Usage : node chrome-visite.mjs <chrome> <urlA> <urlC> <urlE> <relance>
//   urlA, urlC, urlE : trois labs distincts, chacun sur son port · relance : exécutable qui arrête les trois serveurs puis les relance DANS UN AUTRE ORDRE (C, E, A) et rend trois lignes :
//   les adresses (index.html) de A, de C et de E après relance. Avec un port qui dépend de l'ordre de lancement, A change de port ; avec le port stable par lab, aucune adresse ne change.
//   UN seul Chrome, donc un seul profil : le localStorage de l'origine de A y persiste d'un chargement à l'autre.
//   Rend sur une ligne { premiere, croix, echap, relance, bouton, autreLab, passee, temoins, cookies, urlRelance } ou { erreur }.
//   Les valeurs ci-dessous disent « la visite REVIENT » (attendu : false), sauf premiere, bouton et autreLab (attendu : true).
//   premiere = visite affichée au premier chargement · croix = revient au rechargement après l'avoir FERMÉE par « Skip » · echap = idem après Échap (marque effacée d'abord : témoin qu'elle revient)
//   relance = revient après arrêt + relance du serveur du même lab (même port stable) · bouton = « Par où commencer » la rouvre · autreLab = affichée sur un AUTRE lab
//   passee = revient après l'avoir PASSÉE jusqu'au bout (autre lab) · temoins = chaque page « sans visite » avait fini son initialisation (lab connu : sélecteur de modèle posé)
//   cookies = valeur de document.cookie relevée sur chaque page chargée (attendu : toutes vides).
import { execFileSync } from 'node:child_process';
import { executer, pause, attendreValeur } from './chrome-session.mjs';
const [, , chrome, urlA, urlC, urlE, relance] = process.argv;
const VISIBLE = "(() => { const t = document.getElementById('tour'); return !!t && !t.hidden; })()";
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlowTour && !!document.getElementById('tour-btn')";
const INIT = "!!window.__vfModele && !!window.__vfModele.modele"; // 75-vf-modele.js a lu le lab : la décision de la visite est prise
await executer(chrome, async (s) => {
  const cookies = []; let temoins = true;
  const charge = async (url) => { await s.naviguer(url); await s.attendre(PRET, `page prête (${url})`); await s.attendre(INIT, `lab connu (${url})`); cookies.push(await s.ev('document.cookie')); };
  const absente = async () => { await pause(2500); return !(await s.ev(VISIBLE)); }; // le démarrage d'office attend 700 ms après le rendu ; 2,5 s de marge
  const visible = (nom) => s.attendre(VISIBLE, nom, 15000).then(() => true, () => false);
  const sansVisite = async (url) => { await charge(url); const a = await absente(); temoins = temoins && (await s.ev("document.getElementById('vf-modele') !== null")); return !a; };
  await charge(urlA);
  const premiere = await visible('visite affichée au premier chargement');
  await s.ev("document.querySelector('#tour [data-x]').click()"); // la croix : « Skip » du premier pas
  await attendreValeur(() => s.ev(VISIBLE), (v) => v === false, { max: 5000 }); // on ne recharge qu'une fois la fermeture lue (à l'échéance on recharge quand même : la lecture suivante juge)
  const croix = await sansVisite(urlA);
  // Échap : un troisième lab, vu pour la première fois (témoin : la visite s'affiche), fermée au clavier, puis rechargé sur le même port
  await charge(urlE); const echapVue = await visible('visite affichée sur le troisième lab');
  await s.ev("window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }))");
  if (echapVue) await attendreValeur(() => s.ev(VISIBLE), (v) => v === false, { max: 5000 });
  const echap = echapVue ? await sansVisite(urlE) : 'témoin manquant';
  // relance des serveurs, dans un autre ordre : le lab A doit retrouver son adresse
  const [urlRelance, urlC2] = execFileSync(relance, { encoding: 'utf8', timeout: 120000 }).trim().split('\n');
  const apresRelance = await sansVisite(urlRelance);
  await s.ev("document.getElementById('tour-btn').click()"); const bouton = await visible('visite rouverte par le bouton');
  await s.ev('window.VibeFlowTour.end()');
  // un AUTRE lab la voit, puis on la passe jusqu'au bout (flèche droite jusqu'à la fermeture)
  await charge(urlC2); const autreLab = await visible('visite affichée sur un autre lab');
  for (let i = 0; i < 40 && (await s.ev(VISIBLE)); i++) { await s.ev("window.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowRight', bubbles: true }))"); await pause(150); }
  const finie = !(await s.ev(VISIBLE));
  const passee = finie ? await sansVisite(urlC2) : 'non terminée';
  return { premiere, croix, echap, relance: apresRelance, bouton, autreLab, passee, temoins, cookies, urlRelance };
});
