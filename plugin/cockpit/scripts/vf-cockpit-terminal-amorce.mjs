// vf-cockpit-terminal-amorce — amorçage à usage unique et secret de session du terminal intégré (71-01 ; P71-D-10, P71-D-11).
// L'amorçage est écrit par le lanceur dans <sortie>/.cache/terminal-amorce (0600), lu puis supprimé par le serveur du terminal à
// l'échange ; le secret de session est tiré au démarrage du serveur. Aucune valeur n'est jamais journalisée ni rendue dans server.json.
// Exports : FICHIER_AMORCE, nouveauSecret(), egal(a, b), consommerAmorce(fichier, presente).
import fs from 'node:fs';
import crypto from 'node:crypto';

export const FICHIER_AMORCE = 'terminal-amorce';

// 32 octets aléatoires, 64 caractères hexadécimaux
export const nouveauSecret = () => crypto.randomBytes(32).toString('hex');

const condense = (s) => crypto.createHash('sha256').update(s, 'utf8').digest();
// égalité en temps constant : les deux chaînes sont condensées (longueur fixe), toute exception ou tout type autre qu'une chaîne vaut faux
export function egal(a, b) {
  try {
    if (typeof a !== 'string' || typeof b !== 'string') return false;
    return crypto.timingSafeEqual(condense(a), condense(b));
  } catch { return false; }
}

// vrai si l'amorçage présenté est celui du fichier ; le fichier est alors supprimé (usage unique). Un fichier vide, absent ou différent : faux
// et le fichier reste. La lecture durcie (lien symbolique, mode, taille) vient avec la suite du serveur (71-02).
export function consommerAmorce(fichier, presente) {
  if (typeof presente !== 'string' || presente === '') return false;
  let attendu;
  try { attendu = fs.readFileSync(fichier, 'utf8').trim(); } catch { return false; }
  if (attendu === '' || !egal(attendu, presente)) return false;
  try { fs.unlinkSync(fichier); } catch { return false; }
  return true;
}
