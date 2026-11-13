// vf-cockpit-module — le MODULE du cockpit comme source du code qui s'exécute (79-06, P79-D-09, SOCL-07, SOCL-09).
// Première partie (tâche 3) : le dossier du module et le gabarit `<module>` des règles de confinement de l'agent « Demander ».
// Le jeton `<module>` désigne la racine du module : le dossier qui porte `scripts/` et `skills/cockpit-moteur/` (le dépôt de dev et
// un scope installé ont la même forme). La constante publique ARGS_CONFINEMENT et la mesure du confinement (79-MESURE-claude-p.md)
// l'écrivent à la place d'un chemin du poste ; il n'est remplacé par le vrai chemin qu'au lancement, dans l'argv et dans la consigne
// de l'agent, jamais dans un flux, une route ou un fichier de la sortie.
// Alphabet admis pour ce chemin : celui que la mesure a retenu (lettres, chiffres, `.` `-` `_` `/` `~` `@` `+`). La virgule, le signe
// égal, les deux-points et l'étoile ont passé en forme brute mais ne sont pas retenus (deux sont de la syntaxe des règles) ; l'espace,
// les parenthèses et tout autre caractère (dont les chemins Windows) sont refusés : l'agent est alors indisponible, dit en clair,
// jamais ouvert. La règle et la commande doivent porter le MÊME chemin textuel (un lien n'est pas résolu par la règle) : le chemin
// est donc le chemin réel du module, normalisé.
// Seconde partie (tâche 4a) : le code évalué du module (P79-D-09, P79-D-10, P79-D-31). L'ensemble des fichiers est TROUVÉ À L'EXÉCUTION par
// motif, jamais énuméré en dur : un module neuf `vf-cockpit-*.mjs` y entre sans retouche. Une seule empreinte, celle du lanceur ET du serveur.
// Exports : JETON, dossierModule, cheminAgentSur, substituerModule, OUTILS_ASSEMBLAGE, fichiersExecution, fichiersCodeEvalue, empreinteModule, moduleAdmis.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { FICHIERS_NAVIGATEUR } from './vf-cockpit-navigateur.mjs';

export const JETON = '<module>';
const JETON_RE = /<module>/g;
const ALPHABET = /^[A-Za-z0-9._\-/~@+]+$/;

// chemin réel du parent du dossier de scripts ; null si le dossier est absent ou introuvable (l'appelant ferme l'agent)
export function dossierModule(dossierScripts) {
  try {
    if (typeof dossierScripts !== 'string' || !dossierScripts) return null;
    return fs.realpathSync(path.resolve(dossierScripts, '..'));
  } catch { return null; }
}

// le dossier tel qu'il sera écrit dans la règle ; lève (message en français) s'il n'est pas sûr : fermé par défaut
export function cheminAgentSur(dossier) {
  if (typeof dossier !== 'string' || !dossier) throw new Error('dossier du module introuvable : l\'agent « Demander » est indisponible');
  if (!path.isAbsolute(dossier) || path.normalize(dossier) !== dossier) throw new Error('dossier du module refusé (chemin non absolu ou non normalisé) : l\'agent « Demander » est indisponible');
  if (!ALPHABET.test(dossier)) throw new Error('dossier du module refusé (un caractère hors de ceux que la mesure du confinement a retenus : lettres, chiffres, . - _ / ~ @ +) : l\'agent « Demander » est indisponible');
  return dossier;
}

// remplace chaque jeton par le dossier, PAR FONCTION (jamais par une chaîne qui interprète `$&` ou `$1`) ; lève si le dossier est refusé
// ou si un jeton reste après la substitution
export function substituerModule(texte, dossier) {
  const d = cheminAgentSur(dossier);
  const sortie = String(texte).replace(JETON_RE, () => d);
  if (sortie.includes(JETON)) throw new Error('jeton du module resté dans le texte après substitution : l\'agent « Demander » est indisponible');
  return sortie;
}

// outils d'assemblage et de test (jamais évalués par le serveur) ; le motif général les prendrait pour du code d'exécution
export const OUTILS_ASSEMBLAGE = [/^vf-cockpit-build\.mjs$/, /^vf-cockpit-rename\.mjs$/, /^vf-cockpit-code.*\.mjs$/, /^vf-cockpit-fr-.*\.mjs$/];
export const fichiersExecution = (scriptsDir) => fs.readdirSync(scriptsDir).filter((f) => /^vf-cockpit-.*\.mjs$/.test(f) && !OUTILS_ASSEMBLAGE.some((re) => re.test(f))).sort();

// motifs du code évalué (constantes : 79-16 y ajoutera les ressources de page) ; dossier de scripts puis assets du moteur, puis les fichiers de code navigateur
const MOTIFS_SCRIPTS = [/^vf-cockpit-.*\.mjs$/, /^vf-cockpit-interface\.json$/];
const MOTIFS_MOTEUR = [/^serve\.mjs$/, /^graph-query\.js$/, /^query-cli\.mjs$/];
const dedans = (d, motifs) => fs.readdirSync(d).filter((f) => motifs.some((re) => re.test(f)));

// [clé, chemin] triés par clé ; lève si un dossier est illisible
export function fichiersCodeEvalue(dossierScripts, dossierMoteur) {
  const lot = [];
  for (const f of dedans(dossierScripts, MOTIFS_SCRIPTS)) lot.push([`scripts/${f}`, path.join(dossierScripts, f)]);
  const assets = path.join(dossierMoteur, 'assets');
  for (const f of dedans(assets, MOTIFS_MOTEUR)) lot.push([`assets/${f}`, path.join(assets, f)]);
  // code navigateur rangé en fichiers (79-11) : une seule source, la liste close du lecteur ; un fichier illisible rend l'empreinte nulle
  for (const [dossier, nom] of FICHIERS_NAVIGATEUR) lot.push([`assets/ui/${dossier}/${nom}`, path.join(assets, 'ui', dossier, nom)]);
  return lot.sort((a, b) => (a[0] < b[0] ? -1 : a[0] > b[0] ? 1 : 0));
}

// sha1 sur la clé et le contenu de chaque fichier, 12 caractères hexadécimaux ; null si un fichier est illisible (fermé par défaut)
export function empreinteModule({ dossierScripts, dossierMoteur } = {}) {
  try {
    const h = crypto.createHash('sha1');
    for (const [cle, f] of fichiersCodeEvalue(dossierScripts, dossierMoteur)) h.update(cle).update('\0').update(fs.readFileSync(f)).update('\0');
    return h.digest('hex').slice(0, 12);
  } catch { return null; }
}

// refuse (erreur de code 3) un module dont le chemin réel est sous la sortie du lab ou sous son `.vibeflow/`. Résolution native, fermée par
// défaut : un échec de résolution vaut refus (A37 ; son passage à la résolution physique de 79-07 est porté par 79-16).
export function moduleAdmis(lab, dossierScripts, dossierMoteur) {
  const refus = (m) => Object.assign(new Error(m), { code: 3 });
  let vibeflow;
  try { vibeflow = path.join(fs.realpathSync(lab), '.vibeflow'); } catch { throw refus('lab introuvable : module refusé.'); }
  for (const d of [dossierScripts, dossierMoteur]) {
    let r;
    try { r = fs.realpathSync(d); } catch { throw refus('dossier du module introuvable : refus.'); }
    if (r === vibeflow || r.startsWith(vibeflow + path.sep)) throw refus('le module du cockpit se trouve sous le dossier .vibeflow du lab (la sortie ne peut pas être source de code) : refus.');
  }
}
