// vf-cockpit-etat-ecrire — écriture de server.json, l'état qui porte le jeton de la page (79-06, fix2-x06 ; P71-D-25 : le dossier est non fiable).
// Deux écrivains s'en servent, avec la même fermeture : serve.mjs au démarrage, vf-cockpit-terminal.mjs quand Q publie son adresse.
//   - jamais à travers un lien : le contenu part dans un temporaire CRÉÉ À NEUF (O_EXCL : un chemin déjà occupé, lien compris, est refusé, jamais suivi ;
//     O_NOFOLLOW en plus), au nom non prévisible ; le rename remplace l'état sans suivre un lien posé à sa place ; le mode 0600 est donné à la création.
//   - jamais vu à moitié écrit : le fichier d'état ne change que par rename, atomique.
//   - rien ne survit à un arrêt brutal : retirerTemporairesEtat balaie les `server.json.*.tmp` (au démarrage, à l'arrêt).
// Exports : ecrireEtat(f, texte), retirerTemporairesEtat(f).
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const NEUF = fs.constants.O_WRONLY | fs.constants.O_CREAT | fs.constants.O_EXCL | (fs.constants.O_NOFOLLOW || 0);

// lève si l'écriture échoue (chemin du temporaire déjà occupé, dossier absent…) ; l'état précédent reste alors intact
export function ecrireEtat(f, texte) {
  const tmp = path.join(path.dirname(f), `${path.basename(f)}.${process.pid}.${crypto.randomBytes(12).toString('hex')}.tmp`);
  try {
    fs.writeFileSync(tmp, texte, { flag: NEUF, mode: 0o600 });
    fs.renameSync(tmp, f);
  } catch (e) {
    if (e.code !== 'EEXIST') { try { fs.unlinkSync(tmp); } catch {} } // un chemin déjà occupé n'est pas le nôtre : on ne le supprime pas
    throw e;
  }
}

// retire les temporaires d'état laissés à côté de f (un SIGKILL entre l'écriture et le rename les laisse avec le jeton) ; unlink ne suit jamais un lien
export function retirerTemporairesEtat(f) {
  const dir = path.dirname(f), base = path.basename(f);
  let noms = []; try { noms = fs.readdirSync(dir); } catch { return; }
  for (const n of noms) if (n.startsWith(`${base}.`) && n.endsWith('.tmp')) { try { fs.unlinkSync(path.join(dir, n)); } catch {} }
}
