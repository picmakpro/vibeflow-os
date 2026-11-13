// vf-cockpit-trace-vues — assemblage des vues de la route GET /api/vf/tracabilite (76-05 ; TRAC-05 à TRAC-07, TRAC-10 ; P76-D-06, D-07, D-12).
// Module PUR : aucune lecture, aucun git ; reçoit l'instantané `projet` et le modèle des lectures propres déjà calculés.
// Exports : VUES, MOTIFS_CLE, vue({ vue, cle, projet, modele, racine }) -> { statut: 200 | 400, corps }.
// Des codes d'état et des clés ouvrables, jamais de copy français : la page ne construit aucune clé (UI-SPEC § 5).
import { vueJalon } from './vf-cockpit-trace-bilans.mjs';

export const SCHEMA = 'vibeflow/cockpit-trace@1';
export const VUES = ['jalon', 'phase', 'exigence', 'decision', 'adr', 'memoire', 'entree'];
const WS = '[A-Za-z0-9][A-Za-z0-9._-]{0,63}';
const PH = `ph-\\d{1,4}(?:\\.\\d{1,3})?(?:@${WS})?`;
// motifs ancrés, longueur de `cle` bornée à 200 par l'appelant ; une `cle` ne sert qu'à chercher dans un ensemble déjà lu, jamais de chemin
export const MOTIFS_CLE = {
  jalon: null,
  phase: new RegExp(`^${PH}$`),
  exigence: new RegExp(`^[A-Z][A-Z0-9]{0,15}-\\d{1,4}[a-z]?(?:@${WS})?$`),
  adr: /^ADR-\d{3}$/,
  decision: new RegExp(`^(?:[A-Z][A-Z0-9.]{0,15}-){0,3}D-\\d{1,4}[a-z]?(?:bis)?(?::${PH})?$`),
  memoire: new RegExp(`^${WS}$`),
  entree: new RegExp(`^${WS}\\/[A-Za-z0-9][A-Za-z0-9._-]{0,127}\\.md$`),
};

const corps = (v, cle, c) => ({ schema: SCHEMA, vue: v, ...(cle ? { cle } : {}), bornes: { tronque: false }, ...c });

export function vue({ vue: v, cle, projet }) {
  if (v === 'jalon') {
    const j = vueJalon(projet);
    const phases = j.phases.map((p) => ({ ...p, cle: p.id })); // la clé ouvrable d'une phase est son identifiant de nœud
    return { statut: 200, corps: corps(v, null, { etat: j.jalon ? 'ok' : 'vide', jalon: { ...j, phases } }) };
  }
  return { statut: 200, corps: corps(v, cle, { etat: 'indisponible' }) };
}
