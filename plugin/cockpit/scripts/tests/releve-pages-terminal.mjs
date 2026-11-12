// releve-pages-terminal.mjs — relevé des pages du terminal et de ses injections (79-11, P79-D-19) : une ligne par unité, « <nom> <longueur> <sha256> ».
// Usage : node releve-pages-terminal.mjs <racine d'un module>. La racine porte scripts/ et skills/cockpit-moteur/ ; rien n'est lu ailleurs.
import path from 'node:path';
import crypto from 'node:crypto';
import { pathToFileURL } from 'node:url';

const racine = path.resolve(process.argv[2] || '.');
const scripts = path.join(racine, 'scripts');
const charger = (nom) => import(pathToFileURL(path.join(scripts, nom)).href);

const page = await charger('vf-cockpit-terminal-page.mjs');
const tiroir = await charger('vf-cockpit-terminal-tiroir.mjs');
const lancer = await charger('vf-cockpit-lancer-ui.mjs');
page.preparerPage({ engineDir: path.join(racine, 'skills', 'cockpit-moteur') });

const ORIGINE = 'http://127.0.0.1:4100';
const ligne = (nom, texte) => {
  const t = String(texte);
  const empreinte = crypto.createHash('sha256').update(t).digest('hex');
  console.log(`${nom} ${Buffer.byteLength(t)} ${empreinte}`);
};
const sombre = page.pageTerminal({ theme: 'dark', origineP: ORIGINE });
const clair = page.pageTerminal({ theme: 'light', origineP: ORIGINE });
ligne('q-sombre-html', sombre.html); ligne('q-sombre-csp', sombre.csp);
ligne('q-clair-html', clair.html); ligne('q-clair-csp', clair.csp);
ligne('p-tiroir', tiroir.injectionTiroir());
ligne('p-tiroir-indispo', tiroir.injectionTiroir({ indisponible: true }));
ligne('p-lancer', lancer.injectionLancer());
ligne('p-lancer-indispo', lancer.injectionLancer({ indisponible: true }));
ligne('p-lancer-expire', lancer.injectionLancer({ expireMs: 5000 }));
