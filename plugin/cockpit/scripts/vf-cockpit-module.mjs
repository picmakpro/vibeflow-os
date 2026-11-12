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
// Exports : JETON, dossierModule(dossierScripts), cheminAgentSur(dossier), substituerModule(texte, dossier).
import fs from 'node:fs';
import path from 'node:path';

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
