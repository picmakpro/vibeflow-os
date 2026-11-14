// vf-cockpit-mise-en-page — le worker de mise en page du canevas : son entrée dans la table fermée de /_vf/ et les deux politiques de
// contenu qui le concernent (79-18, SOCL-22 ; C5, A40, P79-D-15). Bâti sur `prefixeScripts` de la coquille : une seule source du préfixe du module.
// Page : une directive `worker-src` limitée à l'URL exacte du worker (source sans barre finale : correspondance exacte, AU18-01 ; aucune autre entrée
// de la table n'est admise comme worker), ajoutée juste après `script-src` ; jamais la source d'origine du document, jamais une
// adresse d'objet local, jamais d'évaluation dynamique. Réponse du worker : sa PROPRE politique (rien par défaut, un seul script admis : l'URL exacte du
// paquet de mise en page du module) : ni réseau, ni autre import. Exports : NOM_FIL, ENTREE_FIL, directiveWorker(hote), cspFil(hote).
import { prefixeScripts } from './vf-cockpit-coquille.mjs';

export const NOM_FIL = 'elk-fil.js';
export const directiveWorker = (hote) => `worker-src ${prefixeScripts(hote)}${NOM_FIL}`; // garde:mep-worker-src
export const cspFil = (hote) => `default-src 'none'; script-src ${prefixeScripts(hote)}vendor/elk.bundled.js`; // garde:mep-csp-fil
// l'entrée de la table : classée à part (ni bibliothèque, ni persistant, ni par onglet : la coquille ne l'insère jamais), avec sa politique propre
export const ENTREE_FIL = Object.freeze({ nom: NOM_FIL, classe: 'fil', csp: cspFil });
