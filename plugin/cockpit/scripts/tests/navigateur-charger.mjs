// navigateur-charger.mjs — aide de test du code navigateur rangé en fichiers (79-11, AUDC-AM5). Les fonctions que le serveur mettait en ligne par conversion en
// chaîne sont des fichiers du moteur ; les suites les évaluent ici, dans le contexte courant (les doubles posés sur globalThis par la suite s'appliquent).
// texte(fichier)             : le texte du fichier avec une seule fin de ligne retirée, comme le lecteur du module (vf-cockpit-navigateur.mjs).
// chargerFonctions(fichiers) : { nom: fonction } pour chaque fichier (le nom est celui de la déclaration de tête) ; une erreur de syntaxe se propage.
// La production n'évalue rien : ce module n'est chargé que par les suites.
import fs from 'node:fs';
import vm from 'node:vm';

export const texte = (fichier) => { const t = fs.readFileSync(fichier, 'utf8'); return t.endsWith('\n') ? t.slice(0, -1) : t; };

export function chargerFonctions(fichiers) {
  const sortie = {};
  for (const f of fichiers) {
    const t = texte(f);
    const nom = /^function\s+([A-Za-z_$][\w$]*)/.exec(t);
    if (!nom) throw new Error(`navigateur-charger : ${f} ne commence pas par une déclaration de fonction`);
    sortie[nom[1]] = vm.runInThisContext(`(${t})`, { filename: f });
  }
  return sortie;
}
