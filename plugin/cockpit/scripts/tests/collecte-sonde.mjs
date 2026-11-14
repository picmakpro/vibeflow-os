// collecte-sonde — sonde de latence externe de la suite test-cockpit-collecte.sh (79-09, P79-D-12) : un GET léger périodique, la durée d'une
// requête allant de l'envoi à la fin de la réponse. Elle MESURE depuis le dehors (un autre processus que le serveur) : un moniteur interne à la
// boucle ne verrait pas un blocage qui retient aussi le moniteur.
// Usage : node collecte-sonde.mjs <port> <periodeMs> <dureeMs> [chemin]  ->  une ligne JSON { n, envoyees, erreurs, p50, p99, max, pics }
//   pics : les cinq plus longues latences (ms, ordre décroissant). Jamais de seuil ici : la suite juge.
import http from 'node:http';

const [, , port, periode, duree, chemin = '/zz-sonde-collecte'] = process.argv;
const lat = []; let erreurs = 0, envoyees = 0;
const un = () => {
  envoyees++; const t0 = Date.now();
  http.get({ host: '127.0.0.1', port: Number(port), path: chemin, headers: { Host: `127.0.0.1:${port}` } }, (r) => { r.resume(); r.on('end', () => lat.push(Date.now() - t0)); })
    .on('error', () => { erreurs++; });
};
const t = setInterval(un, Number(periode));
setTimeout(() => {
  clearInterval(t);
  setTimeout(() => { // laisse finir les requêtes en vol (un blocage long rend sa réponse tard)
    const s = [...lat].sort((a, b) => a - b), rang = (q) => s[Math.min(s.length - 1, Math.floor(s.length * q))] ?? -1;
    console.log(JSON.stringify({ n: lat.length, envoyees, erreurs, p50: rang(0.5), p99: rang(0.99), max: s[s.length - 1] ?? -1, pics: s.slice(-5).reverse() }));
    process.exit(0);
  }, 4000);
}, Number(duree));
