// collecte-mini — serveur HTTP minimal de la suite test-cockpit-collecte.sh (79-09) : lance le VRAI `startLive` du dossier de scripts passé en
// argument (le code livré, une copie mutée ou le code de départ), avec un onglet simulé permanent. Il écoute PUIS démarre le direct dans le même
// tour : le démarrage synchrone du code de départ est donc, lui aussi, sous la sonde.
// Usage : node collecte-mini.mjs <dossier-scripts> <lab> <sortie> <port> <fichier-etat>
//   répond 200 « ok » à tout chemin, sauf /etat (JSON de `etat()` du direct) ; écrit <fichier-etat> = { pret: true } quand il écoute ; l'environnement
//   (VF_COCKPIT_SCRIPTS_DIR du faux verrou, HOME) vient de la suite ; s'arrête sur SIGTERM.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const [, , scripts, lab, sortie, port, fichier] = process.argv;
const { startLive } = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-live.mjs')).href); // chargé AVANT d'écouter : le chargement des modules n'est pas ce qu'on mesure
let live = null;
const srv = http.createServer((req, res) => {
  if (req.url === '/etat') { res.writeHead(200, { 'Content-Type': 'application/json' }); res.end(JSON.stringify(live ? live.etat() : null)); return; }
  res.writeHead(200); res.end('ok');
});
srv.listen(Number(port), '127.0.0.1', () => {
  fs.writeFileSync(fichier, JSON.stringify({ pret: true, at: Date.now() }));
  live = startLive({ root: lab, sortie, onEvent: () => {}, log: () => {}, mode: 'poll', aClient: () => true, nbClients: () => 1 });
});
process.on('SIGTERM', () => { try { live?.stop(); } catch {} process.exit(0); });
