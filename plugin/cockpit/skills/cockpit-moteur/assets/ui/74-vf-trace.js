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

  // navigation unique (P80-C76-5) : `courant` = { titre, rouvrir } du panneau sur mesure de la 76 affiché, null quand le panneau montre un nœud.
  // Le panneau quitté est empilé UNE fois, par celui qui le quitte : la pile commune empile seule un nœud (select, reveal) ; la 76 empile le panneau sur
  // mesure qu'elle quitte et le nœud qu'elle quitte par SC.showPanel (que la pile commune ne voit pas, la sélection restant la même).
  // Jamais de bouton Retour, de fil d'Ariane ni de pile propre à la 76 (P76-D-30) ; `titre` d'une donnée du lab, borné à 40 caractères, rendu en texte.
  let courant = null, origine = null;
  const borne = (s) => { const a = Array.from(String(s)); return a.length <= 40 ? String(s) : a.slice(0, 39).join('') + '…'; };
  const noeudCourant = () => {
    const s = SC.state.selected, id = typeof s === 'string' ? s : SC.state.container;
    try { const i = SC.info(id); return { id, titre: (i && i.name) || id }; } catch { return { id, titre: id }; }
  };
  const empiler = (e) => { const P = window.VF_PANNEAU; if (P && typeof P.empiler === 'function') P.empiler({ titre: borne(e.titre), rouvrir: e.rouvrir }); };
  const poser = (html, bind, nouveau, clavier) => {
    courant = nouveau; SC.showPanel(html, bind);
    const t = clavier ? document.querySelector('#panel [data-vf-trace-panneau] .pt') : null;
    if (t) t.focus();
  };
  // ouvrirSurMesure({ html, bind, titre, clavier, depuis }) : ouvre un panneau sur mesure (html statique, bind remplit) ; 76-07 l'emploie pour les siens
  VT.ouvrirSurMesure = ({ html, bind, titre, clavier, depuis }) => {
    if (courant) empiler(courant);
    else { const n = noeudCourant(); if (n.id) empiler({ titre: n.titre, rouvrir: () => SC.reveal(n.id) }); origine = depuis && depuis.dataset
      ? depuis.dataset.trace : null; }
    const nouveau = { titre, rouvrir: () => poser(html, bind, nouveau, false) };
    poser(html, bind, nouveau, clavier);
  };
  // un nœud (phase, plan) s'ouvre par select : le panneau sur mesure quitté est empilé ici, le nœud quitté par la pile commune
  VT.allerNoeud = (id) => { if (courant) { empiler(courant); courant = null; } SC.select(id); };
  VT.ouvreurs = {}; // sorte (decision, adr, entree, commit, …) -> (cle, { clavier, depuis }) ; posés par 76-07
  for (const k of ['poseDecisions', 'poseMemoire']) if (typeof VT[k] === 'function') VT[k](VT.ouvreurs); // 74-vf-trace-decisions.js, -memoire.js
  VT.ouvrir = (sorte, cle, opts) => { const f = VT.ouvreurs[sorte]; if (f) f(cle, opts || {}); };
  // Échap (UI-SPEC § 8) : surcouche ouverte, rien ; pile commune non vide, Retour commun ; sinon fermeture du panneau d'objet et focus rendu à sa ligne
  // d'origine
  const echap = (ev) => {
    if (ev.key !== 'Escape' || ev.defaultPrevented) return;
    const a = document.activeElement;
    if (!a || !a.closest || !a.closest('#panel .vf-trace')) return;
    const S = window.VF_SURCOUCHES, P = window.VF_PANNEAU;
    if (S && typeof S.ouverte === 'function' && S.ouverte()) return;
    if (P && typeof P.taille === 'function' && P.taille() > 0) { ev.stopPropagation(); ev.preventDefault(); P.retour(); return; }
    if (!courant || window.matchMedia('(max-width: 700px)').matches) return; // téléphone, pile vide : le moteur ferme la feuille
    ev.stopPropagation(); ev.preventDefault();
    const o = origine; courant = null; SC.closePanel();
    const l = o ? document.querySelector('#panel [data-trace="' + o.replace(/["\\]/g, '') + '"]') : null;
    if (l) l.focus();
  };

  const init = () => {
    if (!window.FLOORPLAN_SERVER || VT.installe) return undefined; // page autonome ou export : aucune section, aucune ligne « indisponible » (P76-D-11)
    VT.installe = true; let vivant = true;
    if (VT.style) VT.style();
    VT.sections(SC, () => vivant);
    for (const k of ['sectionDecisions', 'sectionMemoire']) if (typeof VT[k] === 'function') VT[k](SC, () => vivant); // ordre : Jalon, Décisions, Mémoire
    // Entrée sur un bouton de la traçabilité ne doit pas lancer aussi l'Entrée globale du moteur, qui plonge dans la sélection et redessine le panneau
    const entree = (ev) => { if (ev.key === 'Enter' && ev.target.closest
      && ev.target.closest('#panel .vf-trace button, #panel .vf-trace summary')) ev.stopPropagation(); };
    document.addEventListener('keydown', entree); document.addEventListener('keydown', echap);
    SC.on('panel', () => { if (vivant && courant && !document.querySelector('#panel [data-vf-trace-panneau]')) courant = null; });
    const E = window.VF_ETAT, off = E && E.abonner ? E.abonner('planning', VT.rafraichir) : null;
    return () => {
      vivant = false; VT.installe = false; if (off) off();
      document.removeEventListener('keydown', entree); document.removeEventListener('keydown', echap); courant = null; zones.clear(); cache.clear();
        envol.clear(); if (VT.retirerStyle) VT.retirerStyle();
    };
  };
  const C = window.VF_COQUILLE;
  if (C && typeof C.surOnglet === 'function') C.surOnglet(init, { cle: '74-vf-trace.js' });
  else if (SC.state.layout) init(); else SC.on('ready', init);
})();
