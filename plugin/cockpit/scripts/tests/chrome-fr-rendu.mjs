// chrome-fr-rendu.mjs — texte VISIBLE des onglets Code et Projet, tel que Chrome le rend (70-01, UIFN-06, UIFN-07). Aucune dépendance.
// Usage : node chrome-fr-rendu.mjs <chrome> <urlCode> <urlProjet>
// `innerText` applique la capitalisation CSS (text-transform) : c'est ce que lit l'œil, pas le nœud de texte de l'inventaire statique.
// Rend sur une ligne { code: { sante, corps }, projet: { sousTitre, ensemble, corps } } ou { erreur } nommée.
import { executer, stabiliser } from './chrome-session.mjs';
const [, , chrome, urlCode, urlProjet] = process.argv;
const PRET = `document.readyState === 'complete' && document.documentElement.lang === 'fr' && !!document.querySelector('header .brand .mark') && !!document.getElementById('panel')`;
await executer(chrome, async (s) => {
  await s.naviguer(urlCode);
  await s.attendre(PRET, 'onglet Code prêt, en français');
  await s.attendre(`!!document.getElementById('btn-health')`, 'bouton Santé');
  await s.attendre("!!window.VibeFlow && !!window.VibeFlow.state && !!window.VibeFlow.state.layout", 'viewer prêt (gestionnaire du bouton Santé posé)');
  await s.ev(`document.getElementById('btn-health').click()`);
  const sante = await s.attendre(`(() => { const k = [...document.querySelectorAll('#panel .kindlabel')].find((e) => /sant|health/i.test(e.textContent)); return k ? k.innerText : false; })()`, 'en-tête du panneau Santé');
  const code = { sante, corps: await s.stable(`document.body.innerText`, 'texte visible du Code') };
  await s.naviguer(urlProjet);
  await s.attendre(PRET, 'onglet Projet prêt, en français');
  await s.attendre(`!!document.getElementById('context') && document.getElementById('context').innerText.trim().length > 0 && document.getElementById('panel').innerText.trim().length > 0`, 'sous-titre et panneau d\'ensemble');
  const projet = await s.stable(`({ sousTitre: document.getElementById('context').innerText, ensemble: document.getElementById('panel').innerText, corps: document.body.innerText })`, 'texte visible du Projet');
  return { code, projet };
});
