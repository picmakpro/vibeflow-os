// vf-cockpit-frise — la route GET /api/vf/frise (79-13, SOCL-17 ; C3, A10, A11, A28, A31, A35, A47).
// Exports : SCHEMA_FRISE, VOIES_REPONSE_MAX (500), lireBornes(url, now), projeterReponse(frise, bornes, champs, now),
//   creerLecteurFrise({ voiesMax, horloge }), lireFrise (le lecteur de la ligne de table).
// La route LIT l'instantané en mémoire (vf-cockpit-instantane.mjs) et la poignée du direct : elle ne déclenche jamais de collecte, ne lit ni
// fichier ni lab, ne fait aucun appel réseau. Sa réponse sort par la réponse gardée de 79-05 (accès contrôlé, garde d'émission, no-store).
import { instantane } from './vf-cockpit-instantane.mjs';

export const SCHEMA_FRISE = 'vibeflow/cockpit-frise@1';
export const VOIES_REPONSE_MAX = 500;
const FENETRE_MS = 86400000;
const EN_CONSTRUCTION = Object.freeze({ etat: 'en-construction', ccVerifie: null, versionsVues: [] });

export const lireBornes = (url, now) => ({ depuis: now - FENETRE_MS, jusqua: now });

export function projeterReponse(frise, bornes, champs, now) {
  return { schema: SCHEMA_FRISE, at: new Date(now).toISOString(), depuis: bornes.depuis, jusqua: bornes.jusqua, fenetreS: 86400,
    source: frise ? frise.source : EN_CONSTRUCTION, tronque: !!(frise && frise.tronque), voiesOmises: 0, voies: frise ? frise.voies : [] };
}

export function creerLecteurFrise({ horloge = Date.now } = {}) {
  return (ctx, req, url) => {
    const now = horloge(), inst = instantane(); // garde:frise-lecture
    return projeterReponse(inst && inst.frise, lireBornes(url, now), null, now);
  };
}
export const lireFrise = creerLecteurFrise();
