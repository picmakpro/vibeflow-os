// vf-cockpit-lancer-ui — interface de lancement des cartes de l'onglet Projet (72-06 ; P72-D-04, D-05, D-06, D-07, D-09, D-17, D-18).
// Exports : LIBELLES_VERBES, MOTIFS, injectionLancer({ indisponible }) -> UNE balise <script> sans attribut (jamais de <style>), ou '' quand indisponible.
// Servi à la volée seulement sous --terminal (le branchement dans injection() est l'affaire de 72-09) : jamais dans un fichier de assets/ui, jamais dans l'export ;
// la CSP sans drapeau est celle de v2.75.0, octet pour octet. Le script s'enregistre par window.VibeFlow.addPanelSection : le viewer vendoré n'est pas touché.
// Contrat lu (72-CONTRATS.md §4) : GET /api/vf/lancer/cibles -> { actif:true, cibles:[{ id, kind, principal, verbes, bloquants, avertissements, lancee }] } ;
//   lancee : le booléen true (forme projetée par 72-09) ou la forme riche { etat, verbe } de 72-07 (etat : attendue, vue, terminee) ; toute autre forme n'affiche rien.
//   POST /api/vf/lancer, corps EXACTEMENT { cible, verbe } (plus `chat` seulement après une conversation du chat observée, 72-13) -> 202 ; un refus porte { refus: <code> } (72-04), `bloque` (409) vient de 72-09.
// Un clic ne lance RIEN : il PROPOSE un couple { cible, verbe } au serveur (« la page propose, le terminal dispose ») ; le serveur reste juge, la page n'est jamais la garde.
// Gardes (une instruction par ligne, marquée « garde:<nom> », mutants de la suite) : titre, entree, bloquants, corps, verbes, envol, jeton (deux lignes), chemin, cible, propose, activation (72-13 F-1).
// Le script est un fichier du moteur : ses commentaires sont servis tels quels, ils ne citent ni adresse web ni nom d'appel interdit.

import { lireFeuille, lireFonction } from './vf-cockpit-navigateur.mjs';

export const LIBELLES_VERBES = Object.freeze({ cadrer: 'Cadrer', planifier: 'Planifier', executer: 'Exécuter', verifier: 'Vérifier', reprendre: 'Reprendre' });
const ORDRE = Object.keys(LIBELLES_VERBES);

// table code de pré-vol -> motif (codes de 72-03) ; un code absent de la table s'affiche « Contrôle non reconnu. », jamais le code brut
export const MOTIFS = Object.freeze({
  'phase-finie': 'La phase est terminée.',
  'terminal-absent': 'Le terminal est indisponible sur ce poste.',
  'terminal-arrete': 'Le terminal est arrêté. Relancez /vf-cockpit --terminal.',
  'premier-plan-occupe': 'Un programme occupe déjà le terminal.',
  'claude-introuvable': 'La commande claude est introuvable.',
  'python3-absent': 'Python 3 est introuvable sur ce poste.',
  'phase-hors-motif': "Le numéro de phase n'est pas lançable.",
  'compartiment-hors-motif': "Le nom du compartiment n'est pas lançable.",
  'mission-hors-phase': "Cette mission n'est rattachée à aucune phase : le lancement depuis une carte ne part que d'un numéro de phase. Pour la reprendre, ouvrez une session Claude Code dans le terminal, tapez /vf-dev et nommez la mission.",
  'dependance-non-close': "Une phase dont celle-ci dépend n'est pas close (lecture de la prose du ROADMAP, indicative).",
  'mission-vivante': 'Une mission vivante travaille déjà sur cette phase.',
  'phase-plus-avancee-ailleurs': "Une version plus récente de ce travail existe à part (autre arbre de travail). Le lancement part du dossier principal, qui n'a pas cette avance : consultez cette version avant de lancer.",
  'phase-sans-plan': "Aucun plan à exécuter pour cette phase : cadrez puis planifiez d'abord.", // avertissement par verbe (Exécuter sur une phase sans plan) : posé par la page et par Q, jamais un bloquant
  'lancement-recent': 'Cette cible a déjà été lancée récemment.',
  'travail-non-commite': "Du travail non commité existe dans l'arbre de travail.", // P72-D-07 : emplacement réservé, rien ne l'alimente dans cette phase
});

const TEXTES = {
  titre: 'Lancer du travail', menu: 'Autres actions', aucune: 'Aucune action disponible.', inconnu: 'Contrôle non reconnu.', bloque: 'Bloqué : ', attention: 'Attention : ',
  envoi: ['Proposition envoyée au terminal : ', '. Confirmez-la dans le terminal.'], refuse: 'Le lancement a été refusé.', reseau: 'Le cockpit ne répond pas.',
  absent: "Le lancement n'est pas disponible. Relancez /vf-cockpit --terminal.", bloquant: 'Le lancement est bloqué : voyez les motifs ci-dessus.',
  preparee0: 'Préparée depuis la carte.', lanceeVerbe: 'Lancée : ', etats: { vue: 'session en cours.', terminee: 'session terminée.' },
  // « Lancée » n'est écrit qu'à un signal réel d'exécution (la session est vue) : une ligne seulement posée dans le terminal n'a rien démarré (double geste, Entrée dans le terminal)
  preparee: ['Commande préparée dans le terminal : ', '. Elle ne démarre qu\'avec Entrée dans le terminal ; en attente de la session.'],
  preparation: 'Préparation…', preparationStatut: 'Préparation de la proposition…', chargement: 'Chargement des actions…',
  // la page ne connaît pas la fin d'une proposition (annulée, expirée, remplacée) : le message d'envoi est borné à sa durée de validité, puis dit ce qu'il ne sait plus
  envoiFin: "La proposition envoyée il y a plus de deux minutes n'est plus valable : si elle n'a pas été confirmée dans le terminal, elle a expiré. Proposez-la de nouveau si besoin.",
  aide: {
    cadrer: 'Cadrer : échanger avec Claude sur la phase pour fixer ce qu\'elle doit livrer, avant de la planifier.',
    planifier: 'Planifier : faire écrire le plan détaillé de la phase, une fois celle-ci cadrée.',
    executer: 'Exécuter : faire réaliser les plans de la phase, étape par étape.',
    verifier: 'Vérifier : contrôler que la phase livre bien ce qui était promis.',
    reprendre: 'Reprendre : relancer une mission interrompue là où elle s\'était arrêtée.',
  },
  aideFin: ' Rien ne démarre avant votre confirmation dans le terminal.',
};
// Durée de validité d'une proposition dans Q : le cockpit la lit dans la MÊME variable que Q (VF_COCKPIT_LANCER_EXPIRE_MS, 1 000 à 600 000 ms ; 120 s par défaut), Q étant son enfant ; le module ne peut pas importer lancer-q (node:crypto) : il est aussi chargé hors de Node par les suites. Le paramètre expireMs de injectionLancer ne sert qu'aux suites
const EXPIRE_PAGE_MS = (() => { // mêmes lectures, mêmes bornes et même règle de cohérence que lancer-q (garde:env-bornes, garde:plancher, expire > arme) : une expiration qui n'excède pas l'armement reprend le défaut, comme dans Q
  const e = typeof process === 'object' && process && process.env ? process.env : {}, lire = (v, min, max, d) => { const n = Number(v); return Number.isInteger(n) && n >= min && n <= max ? n : d; };
  const arme = Math.max(1000, lire(e.VF_COCKPIT_LANCER_ARME_MS, 100, 10000, 1000)), expire = lire(e.VF_COCKPIT_LANCER_EXPIRE_MS, 1000, 600000, 120000); return expire > arme ? expire : 120000; })();

// Option « continuer le chat » (72-13 ; LANC-11, P72-D-03). Livrée parce que la sonde A5 est VERTE (2026-11-05, claude 2.1.318, 72-13-RED-TRACE.md) ; la vue de Q porte la même valeur.
export const CHAT_LIVRE = true;

// Le code servi vit dans assets/ui/tiroir/ (lancer.js, lancer-extraire-chat.js, lancer-observer-chat.js, lancer-proposition.js, lancer.css), lu comme texte par vf-cockpit-navigateur.mjs (79-11).

export function injectionLancer({ indisponible = false, expireMs = EXPIRE_PAGE_MS, moteur } = {}) {
  if (indisponible) return '';
  try {
    const lire = (nom) => lireFonction('tiroir', nom, { moteur });
    const borne = Number.isInteger(expireMs) && expireMs >= 100 && expireMs <= EXPIRE_PAGE_MS ? expireMs : EXPIRE_PAGE_MS;
    const css = lireFeuille('tiroir', 'lancer.css', { moteur });
    const cfg = JSON.stringify({ verbes: ORDRE, libelles: LIBELLES_VERBES, motifs: MOTIFS, textes: TEXTES, chatLivre: CHAT_LIVRE, expireMs: borne, css }).replace(/</g, '\\u003c');
    return `<script>// VibeFlow (72-06) : lancer du travail depuis les cartes\n(${lire('lancer.js')})(${cfg}, ${lire('lancer-extraire-chat.js')}, ${lire('lancer-observer-chat.js')}, ${lire('lancer-proposition.js')});\n</script>`;
  } catch (e) { process.stderr.write(`lancement indisponible : ${e.message}\n`); return ''; } // le serveur ne plante pas : pas de lancement
}
