// VibeFlow (73-11) : lecture du champ meta.vf.questions (contrat C76-Q2) et état de source des questions en attente des cadrages.
// Complète window.__vfRegieQuestions { etat(), relire(), compte() } ; émet l'événement de document `vf-regie:redessiner` quand l'état change.
// Sources, dans l'ordre : l'enveloppe tenue par la page (window.Floorplan.graph.meta.vf.questions, seule source sur la page Projet et
// prioritaire ailleurs), puis la route GET /api/vf/graphe?onglet=projet par VF_ETAT.lireJson, relue quand VF_ETAT annonce un changement
// de la clé `planning`. Aucune écriture de stockage, aucune autre requête, jamais le jeton. Avec la coquille, la lecture
// part au rappel de surOnglet (nettoyage rendu : abonnement retiré) ; sans elle, à l'initialisation. Rien ne se dessine ici.
(() => {
  const W = window, CLE = '72-vf-regie-questions-source.js', ROUTE = '/api/vf/graphe?onglet=projet';
  const Q = W.__vfRegieQuestions = Object.assign(W.__vfRegieQuestions || {}, {});
  const norm = (v) => Q.normaliser(v);
  let etat = norm(undefined), sig = JSON.stringify(etat), enVol = false, vivant = true;

  const poser = (e) => {
    const s = JSON.stringify(e);
    if (s === sig) return;
    etat = e; sig = s;
    if (W.document && typeof W.CustomEvent === 'function') W.document.dispatchEvent(new W.CustomEvent('vf-regie:redessiner'));
  };
  const champ = (g) => { const v = g && g.meta && g.meta.vf; return v ? v.questions : undefined; };
  const graphe = () => (W.Floorplan && W.Floorplan.graph) || null;

  function relire() {
    const g = graphe(), ici = champ(g), E = W.VF_ETAT;
    if ((g && g.meta && g.meta.vfTab === 'project') || (ici !== undefined && ici !== null)) { poser(norm(ici)); return; }
    if (!E || typeof E.lireJson !== 'function') { poser(norm(undefined)); return; }
    if (enVol) return;
    enVol = true;
    if (etat.source !== 'lue') poser({ ...norm(undefined), source: 'lecture' }); // une relecture garde l'état lu : pas de clignotement
    let p;
    try { p = Promise.resolve(E.lireJson(ROUTE)); } catch { p = Promise.reject(new Error('lecture')); }
    p.then((j) => {
      enVol = false; if (!vivant) return;
      const apres = champ(graphe()); // un champ posé dans l'enveloppe pendant la lecture reste prioritaire
      poser(apres !== undefined && apres !== null ? norm(apres) : j !== null && typeof j === 'object' ? norm(champ(j)) : norm('illisible'));
    }, () => { enVol = false; if (vivant) poser(norm('illisible')); });
  }

  function demarrer() {
    vivant = true; relire();
    const E = W.VF_ETAT;
    const desabonner = E && typeof E.abonner === 'function' ? E.abonner('planning', () => relire()) : null;
    return () => { vivant = false; if (desabonner) desabonner(); };
  }

  Object.assign(Q, { etat: () => etat, relire, compte: () => Q.nEnAttente(etat) });
  const C = W.VF_COQUILLE;
  if (C && typeof C.surOnglet === 'function') C.surOnglet(() => demarrer(), { cle: CLE }); else demarrer();
})();
