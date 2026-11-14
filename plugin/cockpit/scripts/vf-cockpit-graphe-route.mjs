// vf-cockpit-graphe-route — le lecteur de GET /api/vf/graphe?onglet=code|projet|equipe (79-15, SOCL-19 ; C5, A10, A11, R1, R4, R5).
// Export : creerRouteGraphe({ graphes }) -> lecteur(ctx, req, url) de la table des routes ; `graphes.courant(onglet)` rend le mémo de l'onglet déjà
// mis à jour (vf-cockpit-graphe.mjs).
// Réponses : 200 (corps = la donnée que la page de l'onglet embarque, ETag = signature hors champs volatils), 304 sans corps, 400 `onglet-invalide`
// (ensemble fermé, valeur unique),
// 503 `graphe-indisponible` (graphe absent ou illisible) ou `emission-refusee` (garde d'émission, appliquée par la réponse gardée sur la projection).
// Jamais une collecte ni un fichier du lab lu ici.
import { reponse } from './vf-cockpit-routes.mjs';
import { ongletValide, etagDe, correspond, projectionGarde } from './vf-cockpit-graphe.mjs';

export function creerRouteGraphe({ graphes }) {
  return (ctx, req, url) => {
    const v = url.searchParams.getAll('onglet');
    if (v.length !== 1 || !ongletValide(v[0])) return reponse(400, { erreur: 'onglet-invalide' });
    const c = graphes.courant(v[0]);
    if (!c) return reponse(503, { erreur: 'graphe-indisponible' });
    if (c.interdit) return reponse(503, { erreur: 'emission-refusee' });
    const etag = etagDe(c.sig);
    // no-store gardé : le 304 répond à la requête conditionnelle explicite du script de page
    if (correspond(req.headers['if-none-match'], etag)) return reponse(304, undefined, { ETag: etag });
    return reponse(200, c.g, { ETag: etag }, { controle: projectionGarde(c.g), brut: c.brut() });
  };
}
