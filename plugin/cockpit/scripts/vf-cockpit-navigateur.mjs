// vf-cockpit-navigateur — lecteur FERMÉ du code navigateur rangé en fichiers du moteur (79-11, SOCL-15, AUDC-AM5, P79-D-19, A37).
// Le code que le navigateur exécute (fonctions et feuilles de la page du terminal Q, du tiroir et du lancement de la page hôte P) vit dans des fichiers
// de skills/cockpit-moteur/assets/ui/<dossier>/, un fichier par fonction ou par feuille, lus ici comme TEXTE et mis en ligne par les modules qui servent
// les pages. Rien n'est évalué côté serveur. Aucune variable d'environnement ne localise ces fichiers : le module les trouve par import.meta.url, le
// serveur de Q par le dossier du moteur qu'il reçoit. Toute phase qui ajoute un fichier de code navigateur le déclare ici (liste close), inscrit sa
// ligne AJOUT dans VENDORED.txt et n'y met aucune ligne de plus de 160 colonnes.
// Exports : FICHIERS_NAVIGATEUR (paires [dossier, nom]) · lireFonction(dossier, nom, { moteur }) · lireFeuille(dossier, nom, { moteur }).
// Un échec est un refus (exception en français qui nomme le fichier) : fermé par défaut.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const TAILLE_MAX = 256 * 1024;
export const FICHIERS_NAVIGATEUR = Object.freeze([
  ['terminal', 'client.js'], ['terminal', 'q.css'], ['terminal', 'vue.js'],
  ['tiroir', 'lancer-extraire-chat.js'], ['tiroir', 'lancer-observer-chat.js'], ['tiroir', 'lancer-proposition.js'], ['tiroir', 'lancer.css'],
  ['tiroir', 'lancer.js'], ['tiroir', 'tiroir-construire.js'], ['tiroir', 'tiroir-message.js'], ['tiroir', 'tiroir.css'], ['tiroir', 'tiroir.js'],
].map((paire) => Object.freeze(paire)));

const MOTEUR_DU_MODULE = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', 'skills', 'cockpit-moteur');
const refus = (dossier, nom, cause) => new Error(`fichier du navigateur refusé (${dossier}/${nom}) : ${cause}`);

// texte UTF-8 d'un fichier de la liste close, après tous les contrôles ; rien n'est lu avant qu'ils passent
function lireTexte(dossier, nom, moteur) {
  if (!FICHIERS_NAVIGATEUR.some((p) => p[0] === dossier && p[1] === nom)) throw refus(dossier, nom, 'hors de la liste close des fichiers du navigateur');
  let reel, fichier, buf;
  try {
    const racine = fs.realpathSync.native(path.resolve(moteur || MOTEUR_DU_MODULE));
    reel = fs.realpathSync.native(path.join(racine, 'assets', 'ui', dossier));
    if (reel !== path.join(racine, 'assets', 'ui', dossier)) throw refus(dossier, nom, 'le dossier résolu sort du dossier du moteur');
    fichier = path.join(reel, nom);
    const etat = fs.lstatSync(fichier);
    if (!etat.isFile() || etat.isSymbolicLink()) throw refus(dossier, nom, 'ni un fichier ordinaire, ni sans lien symbolique');
    if (fs.realpathSync.native(fichier) !== fichier) throw refus(dossier, nom, 'le chemin réel sort du dossier');
    if (etat.size > TAILLE_MAX) throw refus(dossier, nom, 'plus de 256 Kio');
    buf = fs.readFileSync(fichier);
  } catch (e) {
    throw e.message.startsWith('fichier du navigateur refusé') ? e : refus(dossier, nom, 'illisible ou absent');
  }
  if (buf.includes(0)) throw refus(dossier, nom, 'octet nul');
  try { return new TextDecoder('utf-8', { fatal: true }).decode(buf); } catch { throw refus(dossier, nom, 'texte non UTF-8'); }
}

// une fonction : commence à « function », se termine par l'accolade fermante (une fin de ligne retirée), sans fermeture de script
export function lireFonction(dossier, nom, { moteur } = {}) {
  const brut = lireTexte(dossier, nom, moteur);
  const texte = brut.endsWith('\n') ? brut.slice(0, -1) : brut;
  if (/<\/script/i.test(texte) || texte.includes('<!--')) throw refus(dossier, nom, 'fermeture de script ou commentaire HTML dans la fonction');
  if (!texte.startsWith('function ') || !texte.endsWith('}')) throw refus(dossier, nom, 'ne commence pas à « function » ou ne finit pas par une accolade');
  return texte;
}

// une feuille : rendue telle quelle, sans fermeture de style
export function lireFeuille(dossier, nom, { moteur } = {}) {
  const texte = lireTexte(dossier, nom, moteur);
  if (/<\/style/i.test(texte)) throw refus(dossier, nom, 'fermeture de style dans la feuille');
  return texte;
}
