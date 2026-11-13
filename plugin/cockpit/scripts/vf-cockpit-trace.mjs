// vf-cockpit-trace — la route GET /api/vf/tracabilite (76-05 ; TRAC-10, TRAC-11 ; P76-D-06 à D-12, D-31).
// Exports : CHEMIN_TRACE, lireTracabilite(ctx, req, url, { instantane }) — la forme de lecteur de la table des routes (`lecteur(ctx, req, url)`) :
//   rend un corps JSON ou reponse(400, corps) ; jamais un en-tête ni un contrôle d'accès (le répartiteur applique la réponse gardée commune).
// Le planning se lit dans l'instantané de la collecte, en mémoire (vf-cockpit-instantane.mjs), jamais par HTTP ni par une relecture.
import { instantane as instantaneReel } from './vf-cockpit-instantane.mjs';
import { reponse } from './vf-cockpit-routes.mjs';
import { SCHEMA, VUES, MOTIFS_CLE, vue } from './vf-cockpit-trace-vues.mjs';

export const CHEMIN_TRACE = '/api/vf/tracabilite';
const CLE_MAX = 200;

// validation : liste fermée de vues, `cle` par motif propre à la vue, jamais un choix à la place de l'appelant
function parametres(url) {
  const p = url.searchParams;
  for (const k of p.keys()) if (k !== 'vue' && k !== 'cle') return { erreur: 'parametre-inconnu' };
  const vues = p.getAll('vue'), cles = p.getAll('cle');
  if (vues.length !== 1 || !VUES.includes(vues[0])) return { erreur: 'vue-invalide' };
  if (cles.length > 1) return { erreur: 'cle-invalide' };
  const v = vues[0], cle = cles.length ? cles[0] : null;
  if (cle !== null && (MOTIFS_CLE[v] === null || cle.length > CLE_MAX || !MOTIFS_CLE[v].test(cle))) return { erreur: 'cle-invalide' };
  if (cle === null && ['phase', 'exigence', 'decision', 'entree'].includes(v)) return { erreur: 'cle-requise' };
  return { v, cle };
}

export async function lireTracabilite(ctx, req, url, { instantane = instantaneReel } = {}) {
  const a = parametres(url);
  if (a.erreur) return reponse(400, { erreur: a.erreur });
  const { v, cle } = a;
  const snap = instantane();
  if (!snap || !snap.projet) {
    return { schema: SCHEMA, vue: v, ...(cle ? { cle } : {}), etat: 'vide', collecte: 'en-cours', bornes: { tronque: false } };
  }
  const r = vue({ vue: v, cle, projet: snap.projet });
  return r.statut === 200 ? r.corps : reponse(r.statut, r.corps);
}
