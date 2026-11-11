// chrome-fr-donnees.mjs — la traduction du chrome ne réécrit pas les données du lab (AUDC-H4).
// Usage : node chrome-fr-donnees.mjs <chrome> <url> <idConteneur>
//   charge la page, ouvre le conteneur (ex. n:d-src), laisse le temps à la traduction de passer, puis relève pour chaque carte son titre, sa description
//   (vide ou non) et le texte du bouton de santé (témoin : le chrome, lui, est bien traduit). Rend { cartes: [{ titre, desc, vide }], temoin, descPosee } ou { erreur }.
import { executer, stabiliser } from './chrome-session.mjs';
const [, , chrome, url, conteneur] = process.argv;
await executer(chrome, async (s) => {
  await s.naviguer(url);
  await s.attendre("document.documentElement.lang === 'fr' && !!window.VibeFlow && !!window.VibeFlow.state && !!window.VibeFlow.state.layout", 'page prête, en français');
  await s.ev(`window.VibeFlow.go(${JSON.stringify(conteneur)})`);
  await s.attendre(`window.VibeFlow.state.container === ${JSON.stringify(conteneur)} && document.querySelectorAll('#viewport .node .card').length > 1`, `cartes de ${conteneur}`);
  const lire = `({ cartes: [...document.querySelectorAll('#viewport .node .card')].map((c) => ({ titre: c.querySelector('.title') ? c.querySelector('.title').textContent : null, desc: c.querySelector('.desc') ? c.querySelector('.desc').textContent : null, vide: !!c.querySelector('.desc.empty') })), temoin: (document.getElementById('btn-health') || {}).textContent || '' })`;
  const cartes = await stabiliser(() => s.ev(lire), { pas: 400, max: 8000 });
  // une description de carte qui est, mot pour mot, une phrase du dictionnaire (« Health ») : posée comme le fait un rendu, puis laissée à la traduction
  await s.ev("(() => { const d = document.querySelector('#viewport .node .card .desc'); d.classList.remove('empty'); d.textContent = 'Health'; })()");
  const desc = await stabiliser(() => s.ev("document.querySelector('#viewport .node .card .desc').textContent"), { pas: 400, max: 6000 });
  return { ...cartes, descPosee: desc };
});
