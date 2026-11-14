// vf-cockpit-trace-texte — texte lu dans le lab, servi ou projeté par la traçabilité du cockpit (TRAC-11 ; P76-D-11, T-76-14).
// Exports : sansCheminPoste(s, { racine, maison }), servi(s, n, { racine, maison, couper }).
// Un texte du lab ne sort jamais avec un secret, un caractère de contrôle ni un chemin du poste : le chemin du lab est rendu relatif, tout autre
// chemin du poste (maison, ~/, /Users, /home, /root, /private, /var/folders, /tmp, /Volumes, lecteur Windows) devient « un chemin hors du lab ».
// Aucune RegExp n'est construite depuis une valeur lue dans le lab ; celles de la racine et de la maison viennent du poste, échappées.
import fs from 'node:fs';
import os from 'node:os';
import { masque, MARGE_MASQUE } from './vf-cockpit-lecture.mjs';

const HORS = 'un chemin hors du lab';
const FIN = '[^\\s\'"`)\\]>,;]*'; // un chemin court jusqu'au premier espace ou séparateur de ponctuation
const RACINES = 'Users|home|root|private|var\\/folders|tmp|Volumes';
const POSTE = new RegExp(`(?<![\\w.~/-])(?:~\\/${FIN}|\\/(?:${RACINES})(?:\\/${FIN})?)|(?<![\\w])[A-Za-z]:\\\\${FIN}`, 'g');
const CTRL = /[\u0000-\u001f\u007f-\u009f\u2028\u2029\p{Cf}]/gu;
const echappe = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const reel = (p) => { try { return fs.realpathSync(p); } catch { return p; } };

export function sansCheminPoste(s, { racine, maison = os.homedir() } = {}) {
  let t = String(s ?? '');
  const racines = racine ? [...new Set([racine, reel(racine)])].filter((r) => r.length > 1).sort((a, b) => b.length - a.length) : [];
  for (const r of racines) t = t.split(`${r}/`).join('').replace(new RegExp(`${echappe(r)}(?![\\w.-])`, 'g'), '.');
  if (maison && maison.length > 1) t = t.replace(new RegExp(`${echappe(maison)}(?:\\/${FIN})?`, 'g'), HORS);
  return t.replace(POSTE, HORS);
}

// masque des secrets avant la coupe (marge), chemins retirés, puis coupe à n par `couper` (la coupe au mot de l'appelant, sinon la tranche)
export function servi(s, n, { racine, maison, couper } = {}) {
  const masquee = masque(String(s ?? '').replace(CTRL, ''), n + MARGE_MASQUE);
  const propre = sansCheminPoste(masquee, { racine, ...(maison ? { maison } : {}) });
  return typeof couper === 'function' ? couper(propre, n) : propre.slice(0, n);
}
