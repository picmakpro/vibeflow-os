// vf-cockpit-lancer-mode — le mode de permission retenu au dernier lancement accepté, gardé d'une relance du cockpit à l'autre (Phase 72, plan 72-16 ; P72-D-02bis, P72-D-20).
// SEUL détenteur du chemin et de la forme du fichier : <sortie>/.cache/terminal-mode, UN mot de la liste fermée (0600, jamais de texte libre), dans le dossier
// que le build rend ignoré par git. Seul le processus de Q l'importe : jamais lu ni écrit par la page Projet, jamais transmis par l'IPC.
// Lecture : une seule fois, à la création (valeur gardée en mémoire ensuite), durcie comme l'amorçage : sans suivre de lien, sans bloquer, fstat sur le descripteur
// (fichier ordinaire, propriétaire = le compte de Q, aucun droit pour groupe ni autres, 32 octets au plus), puis égalité à l'un des quatre mots ; tout le reste vaut `default`.
// Écriture : fichier temporaire à création exclusive dans le MÊME dossier, puis rename (atomique) ; aucune ouverture en écriture de la cible. Aucune valeur ni aucun chemin n'est journalisé.
// Exports : FICHIER_MODE, MODES, creerMemoireMode({ fichier, fs, modes, os }) -> { lire(), ecrire(mode) }.
import nodeFs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { MODES } from './vf-cockpit-lancer-gabarit.mjs';

export { MODES };
export const FICHIER_MODE = 'terminal-mode';
const DEFAUT = 'default', MAX_OCTETS = 32;

function charger(fichier, fs, modes, os) {
  const c = fs.constants; let fd = null;
  try {
    const noFollow = c.O_NOFOLLOW || 0; // garde:mode-nofollow
    const nonBlock = c.O_NONBLOCK || 0; // garde:mode-nonblock
    fd = fs.openSync(fichier, c.O_RDONLY | noFollow | nonBlock);
    const st = fs.fstatSync(fd);
    if (!st.isFile()) return DEFAUT;
    if (typeof os.getuid === 'function' && st.uid !== os.getuid()) return DEFAUT; // garde:mode-uid
    if ((st.mode & 0o077) !== 0) return DEFAUT; // garde:mode-droits
    if (st.size > MAX_OCTETS) return DEFAUT; // garde:mode-taille
    const tampon = Buffer.alloc(MAX_OCTETS + 1), n = fs.readSync(fd, tampon, 0, tampon.length, 0);
    if (n > MAX_OCTETS) return DEFAUT;
    const txt = new TextDecoder('utf-8', { fatal: true }).decode(tampon.subarray(0, n));
    const mot = txt.endsWith('\n') ? txt.slice(0, -1) : txt;
    return modes.indexOf(mot) >= 0 ? mot : DEFAUT; // garde:mode-valide
  } catch { return DEFAUT; } finally { if (fd !== null) { try { fs.closeSync(fd); } catch {} } }
}

export function creerMemoireMode({ fichier, fs = nodeFs, modes = MODES, os = process } = {}) {
  let memoire = charger(fichier, fs, modes, os);
  const ecrire = (mode) => {
    if (typeof mode !== 'string' || modes.indexOf(mode) < 0) return false;
    memoire = mode;
    const dossier = path.dirname(fichier), tmp = path.join(dossier, `${FICHIER_MODE}.${process.pid}.${crypto.randomBytes(8).toString('hex')}.tmp`);
    let fd = null;
    try {
      fs.mkdirSync(dossier, { recursive: true });
      fd = fs.openSync(tmp, 'wx', 0o600);
      fs.writeSync(fd, mode + '\n'); fs.fsyncSync(fd); fs.closeSync(fd); fd = null;
      fs.renameSync(tmp, fichier); // garde:mode-rename
      return true;
    } catch {
      if (fd !== null) { try { fs.closeSync(fd); } catch {} }
      try { fs.unlinkSync(tmp); } catch {} // garde:mode-unlink
      console.error('vf-cockpit (terminal) : le mode retenu n\'a pas pu être enregistré.');
      return false;
    }
  };
  return { lire: () => memoire, ecrire };
}
