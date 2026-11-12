// vf-cockpit-rename — marque blanche par renommage mécanique à l'assemblage (P67-D-03, forme A1).
// La copie amont reste intacte (patchée) dans le module ; ce module ne s'applique qu'à la SORTIE du lab :
// identifiants, globales, en-tête de jeton, clés de stockage, chemins, variables d'environnement. Jamais les
// données du lab (zone de données des pages épargnée). Une ligne portant `vibeflow:licence-tierce` n'est jamais
// touchée ni comptée (seule exemption : mention de licence).
// Exports : REGLES, renommerTexte(texte), renommerHtml(html), compterOccurrences(texte), MARQUEUR_LICENCE.
import { decouper } from './vf-cockpit-embed.mjs';

// marqueur de début de la zone de données de la page du MOTEUR (nom amont) : seul fichier, avec les règles ci-dessous, à le nommer
const DEBUT_PAGE_MOTEUR = '<script>window.FLOORPLAN = ';

export const MARQUEUR_LICENCE = 'vibeflow:licence-tierce';
// du plus spécifique au plus général : l'ordre fait le sens
export const REGLES = [
  { motif: /floorplan\/graph@1/g, remplacement: 'vf-cockpit/graph@1', raison: 'identifiant du format de graphe' },
  { motif: /\bfloorplan\//g, remplacement: '.vibeflow/cockpit/', raison: 'chemin du dossier de carte' },
  { motif: /__FLOORPLAN_/g, remplacement: '__VF_COCKPIT_', raison: 'jetons de gabarit' },
  { motif: /FLOORPLAN/g, remplacement: 'VF_COCKPIT', raison: 'globales de données et de serveur, variables d\'environnement' },
  { motif: /floorplan(?=[A-Z])/g, remplacement: 'vfCockpit', raison: 'identifiants camelCase' },
  { motif: /Floorplan/g, remplacement: 'VibeFlow', raison: 'API globale des extensions et prose' },
  { motif: /floorplan/g, remplacement: 'vf-cockpit', raison: 'clés de stockage, en-tête de jeton, événements, clés de thème, chaînes' },
];

const sansLicence = (l) => !l.includes(MARQUEUR_LICENCE);
export function renommerTexte(texte) {
  return texte.split('\n').map((l) => (sansLicence(l) ? REGLES.reduce((a, r) => a.replace(r.motif, r.remplacement), l) : l)).join('\n');
}

// seules les parties avant et après la zone de données sont renommées : les données du lab restent intactes
export function renommerHtml(html) {
  const { avant, donnees, apres } = decouper(html);
  return renommerTexte(avant) + donnees + renommerTexte(apres);
}

// la page produite par le moteur : renommée hors zone de données, qui est ensuite remplie sous son nom VibeFlow (A48 : le renommage précède l'insertion)
export function renommerPageMoteur(html) {
  const { avant, donnees, apres } = decouper(html, DEBUT_PAGE_MOTEUR);
  return renommerTexte(avant) + donnees + renommerTexte(apres);
}

export const compterOccurrences = (texte) => texte.split('\n').filter(sansLicence).reduce((n, l) => n + (l.match(/floorplan/gi) || []).length, 0);
