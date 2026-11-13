// vf-cockpit-activite — l'objet de GET /api/vf/activite (Phase 75, plan 75-05 ; ACTV-04, ACTV-08, ACTV-10 ; P75-D-09, P75-D-22, P75-D-23, A31, A47).
// Exports : SCHEMA_ACTIVITE, creerActivite(options) -> activite(ctx), activite, routeActivite (le lecteur de la ligne de la table des routes).
const SCHEMA = 'vibeflow/cockpit-activite@1';
export const SCHEMA_ACTIVITE = SCHEMA;
const LECTURE = { etat: 'en-lecture' };
const EMPREINTE = { etat: 'en-construction', incomplet: true, limite: [], marques: [], horsCarte: 0, horsLab: 0, coupees: 0, rejetes: 0,
  ignorees: 0, voiesTronquees: false, voiesCiblesTronquees: 0 };
const RADAR = { incomplet: true, raisons: ['en-construction'], total: 0, tronque: false, sansVague: 0, plansTronques: false, limites: [] };

export function creerActivite({ horloge = Date.now } = {}) {
  return function activite() {
    return { schema: SCHEMA, at: new Date(horloge()).toISOString(), etat: 'en-calcul', calcul: 'en-cours', git: { ...LECTURE },
      branches: { ...LECTURE }, gardes: { ...LECTURE, gardes: [], estGarde: [], prevusIgnores: 0 }, empreinte: { ...EMPREINTE },
      collisions: [], radar: { ...RADAR } };
  };
}
export const activite = creerActivite();
export const routeActivite = (ctx) => activite(ctx);
