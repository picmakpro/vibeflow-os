// chrome-reco.mjs — le cockpit perd son serveur : combien de requêtes la page émet-elle, et que dit-elle à la fin ? (E-6, CKPT-05)
// Usage : node chrome-reco.mjs <chrome> <url> <pidServeur> <port>
//   charge la page, raccourcit les délais de recul (vite 200 ms jusqu'à 1,5 s, puis 600 ms, arrêt à 4 s), arrête le serveur, puis écoute son port :
//   chaque connexion entrante est comptée et coupée. Rend sur une ligne { rapide, lent, tard, banniere, bouton, apresClic } ou { erreur }.
//   rapide = connexions pendant les 1,5 s qui suivent l'arrêt · lent = entre 1,7 s et 3,9 s · tard = entre 5 s et 9 s (doit être 0 : arrêt)
//   banniere = texte du message d'arrêt · apresClic = connexions dans la seconde et demie qui suit le clic sur « Réessayer ».
import net from 'node:net';
import { executer, pause as attendre } from './chrome-session.mjs';
const [, , chrome, url, pid, port] = process.argv;
let ecouteur = null;
await executer(chrome, async (s) => {
  await s.naviguer(url);
  await s.attendre('!!(window.__vfLive && window.__vfLive.connected)', 'direct connecté avant la coupure');
  await s.ev('window.__vfLive.reco = Object.assign(window.__vfLive.reco || {}, { vite: 200, lent: 600, bascule: 1500, fin: 4000 })');
  process.kill(Number(pid), 'SIGTERM');
  const t0 = []; let t_kill = Date.now();
  for (let i = 0; i < 400 && !ecouteur; i++) { // le port se libère (jusqu'à 20 s sous charge), puis on l'écoute
    try { ecouteur = await new Promise((res, rej) => { const sv = net.createServer((c) => { t0.push(Date.now() - t_kill); c.on('error', () => {}); c.destroy(); }); sv.once('error', rej); sv.listen(Number(port), '127.0.0.1', () => res(sv)); }); } catch { await attendre(50); }
  }
  if (!ecouteur) throw new Error('port du serveur arrêté non récupéré en 20 s');
  t_kill = Date.now(); // l'écoute commence ici : les temps se comptent depuis cet instant
  await attendre(9000);
  const dans = (a, b) => t0.filter((x) => x >= a && x < b).length;
  const rapide = dans(0, 1500), lent = dans(1700, 3900), tard = dans(5000, 9000);
  const banniere = await s.ev("(document.getElementById('vf-reco')||{}).innerText || ''");
  const avant = t0.length;
  await s.ev("(document.querySelector('#vf-reco button')||{click(){}}).click()");
  await attendre(1500);
  return { rapide, lent, tard, banniere, bouton: await s.ev("!!document.querySelector('#vf-reco button') || (window.__vfLive.sondages > 0 && !window.__vfLive.abandon)"), apresClic: t0.length - avant, total: avant };
});
