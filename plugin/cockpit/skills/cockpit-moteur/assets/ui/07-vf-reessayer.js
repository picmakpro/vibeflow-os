// VibeFlow (80-21) : « Réessayer » dans la palette de commandes, offert seulement tant qu'un chargement d'onglet est en échec (FORM-16, P80-D-14).
// Une source de la palette (VibeFlow.ajouterSource, 80-14) posée à l'évaluation : une extension d'onglet, refaite avec le moteur (A51), donc une seule
// source par moteur. Elle lit VF_ONGLETS.echec() à chaque appel et rend une rangée, ou rien. Elle n'est PAS dans le registre VF_RACCOURCIS : l'entrée est
// situationnelle et ne doit pas figurer dans l'aide « ? ». Aucune requête ni envoi : l'action relance la lecture que fait déjà le routeur (P80-D-26).
(() => {
  const SC = window.Floorplan || window.VibeFlow;
  if (!SC || typeof SC.ajouterSource !== 'function') return;
  const LIBELLE = { code: 'Code', projet: 'Projet', equipe: 'Équipe' };
  const norm = (s) => String(s).normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();
  SC.ajouterSource((c) => {
    const V = window.VF_ONGLETS, e = V && typeof V.echec === 'function' ? V.echec() : null;
    if (!e || !LIBELLE[e.onglet]) return [];
    if (!c.vide && !(c.termes || []).every((t) => norm('Réessayer').includes(norm(t)))) return [];
    return [{ groupe: 'actions', titre: 'Actions', id: 'reessayer', libelle: 'Réessayer', detail: LIBELLE[e.onglet], touches: [], icone: 'right', avant: true,
      executer: () => V.reessayer().catch(() => {}) }]; // un nouvel échec se dit déjà (annonce, ligne d'état) ; rien à rejeter de plus
  });
})();
