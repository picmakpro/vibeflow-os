// VibeFlow (76-06) : la traçabilité au cockpit côté page (P76-D-02) : lecture de la route par le magasin d'état, cache de page, zones rafraîchies par la clé
// `planning`, initialisation par onglet (A30 de la 79). Chargé en dernier des fichiers 74-vf-trace* : les autres ne font que déclarer leurs briques
// dans window.VFTrace. Les globales de la 79 et de la 80 (VF_ETAT, VF_COQUILLE, VF_PANNEAU, VF_SURCOUCHES) sont lues AU MOMENT de l'appel, jamais gardées.
(() => {
  const SC = window.Floorplan;
  const VT = (window.VFTrace = window.VFTrace || {});
  if (!SC || !SC.graph || !SC.graph.meta || SC.graph.meta.vfTab !== 'project') return;
  const cache = new Map(); // '<vue>|<cle>' -> { json, donnees } : une réponse déjà lue s'affiche tout de suite, la relecture la remplace
  const zones = new Set(), envol = new Map();
  const MOTIF = /^[A-Za-z0-9._@:/-]{1,200}$/;

  // toute lecture de la route passe par VF_ETAT.lireJson (A13) ; `cle` vient d'une réponse de la route ou d'un nœud, encodée, jamais construite hors
  // motif ; deux zones qui lisent la même chose en même temps partagent une seule requête
  VT.lire = (vue, cle) => {
    const E = window.VF_ETAT, k = vue + '|' + (cle == null ? '' : cle);
    if (!E || (cle != null && !MOTIF.test(cle))) return Promise.reject(Object.assign(new Error('lecture impossible'), { statut: 0 }));
    if (envol.has(k)) return envol.get(k);
    const p = E.lireJson('/api/vf/tracabilite?vue=' + encodeURIComponent(vue) + (cle != null ? '&cle=' + encodeURIComponent(cle) : ''));
    const fin = () => envol.delete(k);
    p.then(fin, fin); envol.set(k, p);
    return p;
  };

  // zone : un conteneur rempli d'une lecture asynchrone ; chargement montré après 150 ms seulement, séquence contre les réponses périmées,
  // cache, erreur avec « Réessayer » (sauf `sansEtat` : une zone qui reste cachée sans donnée)
  VT.zone = (cont, { cle, lire, rendre, ouvert, sansEtat }) => {
    const z = { cont, seq: 0, rendu: false, ouvert: ouvert || (() => true) };
    const reessayer = () => { z.rendu = false; z.charger(); };
    const afficher = (d) => {
      cont.removeAttribute('aria-busy');
      const cas = sansEtat ? null : VT.etatDe(d.principal);
      if (cas) cont.replaceChildren(VT.etat(cas.cas, { ...cas.donnees, surReessayer: reessayer })); else rendre(d, cont);
      z.rendu = true;
    };
    z.charger = () => {
      const mon = ++z.seq, hit = cache.get(cle); let minut = null;
      if (hit && !z.rendu) afficher(hit.donnees);
      else if (!hit && !z.rendu && !sansEtat) {
        minut = setTimeout(() => {
          if (mon !== z.seq || !cont.isConnected || z.rendu) return;
          cont.replaceChildren(VT.etat('chargement')); cont.setAttribute('aria-busy', 'true');
        }, 150);
      }
      lire().then((d) => {
        clearTimeout(minut);
        if (mon !== z.seq || !cont.isConnected) return;
        const json = JSON.stringify(d);
        if (hit && z.rendu && hit.json === json) return; // identique : rien ne bouge (défilement, focus)
        cache.set(cle, { json, donnees: d }); afficher({ ...d });
      }, () => {
        clearTimeout(minut);
        if (mon !== z.seq || !cont.isConnected || z.rendu || sansEtat) return; // une relecture en échec garde ce qui est à l'écran
        cont.removeAttribute('aria-busy'); cont.replaceChildren(VT.etat('erreur', { surReessayer: reessayer }));
      });
    };
    zones.add(z);
    return z;
  };
  // la clé `planning` de VF_ETAT relance les zones OUVERTES seulement
  VT.rafraichir = () => { for (const z of [...zones]) { if (!z.cont.isConnected) zones.delete(z); else if (z.ouvert()) z.charger(); } };

  // un nœud (phase, plan) s'ouvre par select : la pile commune de la Phase 80 empile elle-même le panneau quitté
  VT.allerNoeud = (id) => SC.select(id);

  const init = () => {
    if (!window.FLOORPLAN_SERVER || VT.installe) return undefined; // page autonome ou export : aucune section, aucune ligne « indisponible » (P76-D-11)
    VT.installe = true; let vivant = true;
    if (VT.style) VT.style();
    VT.sections(SC, () => vivant);
    // Entrée sur un bouton de la traçabilité ne doit pas lancer aussi l'Entrée globale du moteur, qui plonge dans la sélection et redessine le panneau
    const entree = (ev) => { if (ev.key === 'Enter' && ev.target.closest && ev.target.closest('#panel .vf-trace button, #panel .vf-trace summary')) ev.stopPropagation(); };
    document.addEventListener('keydown', entree);
    const E = window.VF_ETAT, off = E && E.abonner ? E.abonner('planning', VT.rafraichir) : null;
    return () => {
      vivant = false; VT.installe = false; if (off) off();
      document.removeEventListener('keydown', entree); zones.clear(); cache.clear(); envol.clear(); if (VT.retirerStyle) VT.retirerStyle();
    };
  };
  const C = window.VF_COQUILLE;
  if (C && typeof C.surOnglet === 'function') C.surOnglet(init, { cle: '74-vf-trace.js' });
  else if (SC.state.layout) init(); else SC.on('ready', init);
})();
