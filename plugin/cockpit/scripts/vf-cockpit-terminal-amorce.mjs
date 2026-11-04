// vf-cockpit-terminal-amorce — amorçage à usage unique et secret de session du terminal intégré (71-01 ; P71-D-10, P71-D-11).
// L'amorçage est écrit par le lanceur dans <sortie>/.cache/terminal-amorce (0600), lu puis supprimé par le serveur du terminal à
// l'échange ; le secret de session est tiré au démarrage du serveur. Aucune valeur n'est jamais journalisée ni rendue dans server.json.
// P71-D-27 : l'amorçage expire 60 s après sa création (mtime du fichier, écrit une seule fois), côté serveur.
// Exports : FICHIER_AMORCE, FICHIER_OUVRIR, DUREE_AMORCE_MS, nouveauSecret(), egal(a, b), consommerAmorce(fichier, presente, { maintenant }).
import fs from 'node:fs';
import crypto from 'node:crypto';

export const FICHIER_AMORCE = 'terminal-amorce';
export const FICHIER_OUVRIR = 'terminal-ouvrir.html'; // page de redirection que le lanceur remet à l'ouvreur (jamais l'amorçage dans l'argv)
export const DUREE_AMORCE_MS = 60000;

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

// vrai si l'amorçage présenté est celui du fichier ; le fichier est alors supprimé (usage unique). Lecture durcie (P71-D-11) : ouverture sans suivre
// de lien symbolique (O_NOFOLLOW) ni bloquer (O_NONBLOCK), puis fstat sur le descripteur ouvert : fichier ordinaire, propriétaire = le compte du
// serveur, aucun droit pour le groupe ni les autres, 128 octets au plus. Tout manquement, toute exception : faux, et le fichier reste.
const MAX_AMORCE = 128;
export function consommerAmorce(fichier, presente, { maintenant = Date.now } = {}) {
  if (typeof presente !== 'string' || presente === '' || presente.length > MAX_AMORCE) return false;
  const c = fs.constants;
  if (!c.O_NOFOLLOW || typeof process.getuid !== 'function') return false; // plateforme sans ces garanties : refus
  let fd = null, attendu;
  try {
    fd = fs.openSync(fichier, c.O_RDONLY | c.O_NOFOLLOW | (c.O_NONBLOCK || 0));
    const st = fs.fstatSync(fd);
    if (!st.isFile() || (st.mode & 0o077) !== 0 || st.uid !== process.getuid() || st.size === 0 || st.size > MAX_AMORCE) return false;
    const age = maintenant() - st.mtimeMs; // expiré (ou daté du futur) : refus, le fichier reste et le balayage le retirera
    if (!(age >= -1000 && age <= DUREE_AMORCE_MS)) return false;
    const tampon = Buffer.alloc(MAX_AMORCE + 1), n = fs.readSync(fd, tampon, 0, tampon.length, 0);
    attendu = tampon.subarray(0, n).toString('utf8').trim();
  } catch { return false; } finally { if (fd !== null) { try { fs.closeSync(fd); } catch {} } }
  if (attendu === '' || !egal(attendu, presente)) return false;
  try { fs.unlinkSync(fichier); } catch { return false; }
  return true;
}
