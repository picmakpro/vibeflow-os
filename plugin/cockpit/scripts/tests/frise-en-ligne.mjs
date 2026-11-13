// frise-en-ligne — serveur minimal de test-cockpit-frise.sh (79-13, F6.4) : comme collecte-mini.mjs, mais les étapes de la collecte (index et frise compris) tournent
// SUR LA BOUCLE (collecteur en ligne de 79-09) : la sonde de latence doit alors rougir, ce qui prouve qu'elle sait mesurer un gel.
// Usage : node frise-en-ligne.mjs <dossier-scripts> <lab> <sortie> <port> <fichier-etat>
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const [, , scripts, lab, sortie, port, fichier] = process.argv;
const { startLive } = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-live.mjs')).href);
const { creerCollecteEnLigne } = await import(pathToFileURL(path.join(scripts, 'tests', 'collecte-en-ligne.mjs')).href);
let live = null;
const srv = http.createServer((req, res) => { res.writeHead(200); res.end('ok'); });
srv.listen(Number(port), '127.0.0.1', () => {
  fs.writeFileSync(fichier, JSON.stringify({ pret: true, at: Date.now() }));
  live = startLive({ root: lab, sortie, onEvent: () => {}, log: () => {}, mode: 'poll', aClient: () => true, nbClients: () => 1, garde: () => true, collecteur: (o) => creerCollecteEnLigne(o) });
});
process.on('SIGTERM', () => { try { live?.stop(); } catch { /* arrêt */ } process.exit(0); });
