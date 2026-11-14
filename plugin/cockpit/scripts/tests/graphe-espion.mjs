// graphe-espion.mjs — sonde de test-cockpit-graphe.sh (79-15), chargée par `node --import` : compte les lectures d'un fichier `project.html` par le processus.
// Elle enveloppe `readFileSync` de `node:fs` (objet par défaut) et ajoute une ligne à GRAPHE_ESPION_FICHIER par lecture ; elle ne modifie jamais la lecture et ne lève jamais.
import fs from 'node:fs';

const sortie = process.env.GRAPHE_ESPION_FICHIER;
const lire = fs.readFileSync;
if (sortie) {
  fs.readFileSync = function espionnee(chemin, ...args) {
    try { if (typeof chemin === 'string' && /[\\/]project\.html$/.test(chemin)) fs.appendFileSync(sortie, 'lecture\n'); } catch {}
    return lire.call(this, chemin, ...args);
  };
}
