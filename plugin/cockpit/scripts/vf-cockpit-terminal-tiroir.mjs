// vf-cockpit-terminal-tiroir — tiroir du terminal dans les pages Projet et Code (71-07 ; P71-D-07, D-08, D-18, D-19 ; P71-D-20 : O1 option B ; P71-D-21 : O6, O8 ; P71-PL-03, PL-14, PL-15).
// serve.mjs ajoute `injectionTiroir` à `inject` seulement sous --terminal : jamais dans index.html sur disque, donc jamais dans l'export ni dans la CSP sans le drapeau.
// Exports : LISTE_MESSAGES, injectionTiroir({ indisponible }) -> `<style>` + `<script>` (vide si un fichier rangé est refusé).
// Le script est un fichier du moteur : ses commentaires sont servis tels quels, ils ne contiennent ni adresse web en entier, ni nom d'appel interdit.
import { lireFeuille, lireFonction } from './vf-cockpit-navigateur.mjs';

export const LISTE_MESSAGES = Object.freeze(['ready', 'etat:connecte', 'etat:reconnexion', 'etat:termine', 'etat:refuse', 'etat:expire', 'etat:arrete', 'toggle', 'proposition', 'annulation', 'retrait']);
// mesure O8 (71-06) : allow-popups ouvre une fenêtre dont l'opener est nul ; la décision du manager retient ces cinq jetons, aucun autre (jamais de navigation du haut, ni de formulaire)
const SANDBOX = 'allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox';
const TEXTES = {
  pastille: 'Terminal', titre: 'Terminal', ouvrir: 'Ouvrir le terminal (Ctrl+Maj+Espace)', ouvrirEnCours: 'Ouvrir le terminal, une session est en cours',
  windows: 'Terminal indisponible sous Windows.', localhost: "Ouvrez le cockpit à l'adresse 127.0.0.1 pour utiliser le terminal.",
  agrandir: 'Agrandir le terminal', reduire: 'Réduire le terminal', fermer: 'Fermer le terminal (Ctrl+Maj+Espace)', poignee: 'Hauteur du terminal',
  terminer: 'Terminer la session', terminerConfirme: 'Confirmer : terminer', terminerAide: 'Ferme le shell et ce qui y tourne ; le terminal pourra être rouvert.', annonceTermine: 'Fin de la session demandée', annonceConfirme: 'Confirmez pour terminer la session',
  charge: 'Ouverture du terminal…', injoignable: 'Le terminal ne répond pas. Relancez ', commande: '/vf-cockpit --terminal', annonceOuvert: 'Terminal ouvert', annonceFerme: 'Terminal fermé', annonceProposition: 'Proposition de lancement dans le terminal.',
  // table unique état -> libellé de la barre (J1 de la critique 71) : chaque état de la carte de Q a son mot ; « Arrêté » ne sert plus qu'à l'état arrêté
  etats: { connecte: 'Connecté', reconnexion: 'Reconnexion…', termine: 'Terminé', arrete: 'Arrêté', refuse: 'Déjà ouvert', expire: 'Session expirée' },
};

// Le code servi vit dans assets/ui/tiroir/ (tiroir.js, tiroir-message.js, tiroir-construire.js, tiroir.css), lu comme texte par vf-cockpit-navigateur.mjs (79-11).
// P71-D-18 (filtre de tiroir-message.js) : un message n'est accepté que s'il est fiable, d'origine exacte de Q, venu de la fenêtre du cadre de P, et de la liste fermée.

export function injectionTiroir({ indisponible = false, moteur } = {}) {
  const cfg = { indisponible: !!indisponible, sandbox: SANDBOX, liste: LISTE_MESSAGES, textes: TEXTES };
  try {
    const lire = (nom) => lireFonction('tiroir', nom, { moteur });
    const code = `// VibeFlow (71-07) : tiroir du terminal\n(${lire('tiroir.js')})(${JSON.stringify(cfg)}, ${lire('tiroir-message.js')}, ${lire('tiroir-construire.js')});\n`;
    return `<style>${lireFeuille('tiroir', 'tiroir.css', { moteur })}</style><script>${code}</script>`;
  } catch (e) { process.stderr.write(`tiroir du terminal indisponible : ${e.message}\n`); return ''; } // le serveur ne plante pas : pas de tiroir
}
