// VibeFlow (80-10) : changer d'onglet sans recharger la page (FORM-16, P80-D-22, P80-D-42, P80-D-59 b) — routage sur la coquille de la Phase 79.
// vf-coquille: persistant
// Un clic d'onglet, Précédent et Suivant, VF_ONGLETS.aller(nom) passent par une même fonction : VF_COQUILLE.chargerOnglet(nom) d'abord, puis, après sa
// résolution SEULEMENT, history.pushState du chemin (jamais depuis popstate : le navigateur a déjà changé l'adresse), puis la vue mémorisée, le titre,
// vf:onglet, le focus et l'annonce. Un chargement rejeté ne change ni l'adresse, ni l'onglet affiché, ni le focus (après un popstate rejeté, l'adresse
// est ramenée par replaceState) ; dire l'échec à l'écran n'est pas ici (80-21). Évaluation : l'objet, l'écouteur popstate et UNE inscription surOnglet ;
// tout ce qui dépend du document de l'onglet vit dans le rappel de surOnglet. Seule donnée gardée : la mémoire de vue par onglet (données simples).
(() => {
  if (window.VF_ONGLETS) return;
  const C = window.VF_COQUILLE;
  if (!C) return;
  const NOMS = ['code', 'projet', 'equipe'];
  const CHEMIN = { code: '/', projet: '/project.html', equipe: '/equipe.html' };
  const PAR_CHEMIN = { '/': 'code', '/index.html': 'code', '/project.html': 'projet', '/equipe.html': 'equipe' };
  const LIBELLE = { code: 'Code', projet: 'Projet', equipe: 'Équipe' };
  const vues = new Map(); // onglet -> { cont, sel, t, hash } : la vue quittée
  const hashes = new Map(); // onglet -> dernier fragment lu pour cet onglet (celui d'un départ par popstate est déjà celui de l'arrivée)
  const moteur = () => {
    return window.Floorplan || null;
  };
  const fragmentValide = (f) => typeof f === 'string' && f.length <= 1024 && /^#[^\s\u0000-\u001f\u007f]*$/.test(f);

  // la vue de l'onglet quitté, juste avant son démontage ; le fragment est lu avant tout changement d'adresse (sauf départ par popstate)
  const memoriser = (nom, depart) => {
    const SC = moteur(); if (!SC || !SC.state) return;
    const t = SC.state.t, v = { cont: SC.state.container, sel: typeof SC.state.selected === 'string' ? SC.state.selected : null, t: null };
    if (t && [t.k, t.x, t.y].every(Number.isFinite)) v.t = { k: t.k, x: t.x, y: t.y };
    vues.set(nom, v);
    if (depart !== 'popstate') hashes.set(nom, location.hash);
  };
  let depart = 'clic';

  const titrer = (nom) => {
    const SC = moteur(), p = SC && SC.graph && SC.graph.project, n = String((p && p.name) || '').replace(/ — (Projet|Équipe)$/, '');
    if (!document.title.startsWith(LIBELLE[nom] + ' · ')) document.title = LIBELLE[nom] + ' · ' + n;
  };
  const annoncer = (nom) => { const z = document.getElementById('ask-live'); if (z) z.textContent = LIBELLE[nom]; };
  // repli unique (80-UI-SPEC § 5) : l'élément sélectionné rendu, sinon le h1 ; Code et Graphe : la carte sélectionnée ou itinérante, sinon #stage ; jamais body
  const focaliser = () => {
    const SC = moteur(), P = window.__vfProjetClavier, K = window.VF_CANEVAS, F = window.VF_PROJET;
    const projet = !!SC && !!SC.graph.meta && SC.graph.meta.vfTab === 'project';
    if (projet && P && F && F.forme() !== 'graphe' && P.repli({ defiler: false })) return;
    const sel = SC && typeof SC.state.selected === 'string' ? SC.state.selected : null;
    if (K && sel && K.focaliser(sel)) return;
    const it = K ? K.carteItinerante() : null;
    if (K && it && K.focaliser(it)) return;
    const s = document.getElementById('stage');
    if (s) { if (!s.hasAttribute('tabindex')) s.tabIndex = -1; s.focus({ preventScroll: true }); }
  };
  // la vue mémorisée de l'onglet d'arrivée : conteneur et sélection (sauf si l'adresse porte la vue : popstate, fragment explicite), puis zoom
  const restituer = async (nom, avecVue) => {
    const SC = moteur(), v = vues.get(nom); if (!SC || !v) return;
    try {
      if (avecVue && (v.cont !== SC.state.container || v.sel !== SC.state.selected)) await SC.go(v.cont, { select: v.sel, push: false });
      if (v.t && v.cont === SC.state.container && typeof SC.transformer === 'function') SC.transformer(v.t);
    } catch (e) { console.error('VibeFlow onglets : vue non restituée : ' + (e && e.message)); }
  };
  const arriver = async (nom, precedent, avecVue) => {
    await restituer(nom, avecVue);
    titrer(nom); hashes.set(nom, location.hash);
    document.dispatchEvent(new CustomEvent('vf:onglet', { detail: { onglet: nom, precedent } }));
    focaliser(); annoncer(nom);
  };

  // la seule fonction de chargement : clic, popstate et aller. `pop` : le navigateur a déjà posé l'adresse ; `fragment` : posé tel quel (aller)
  const charger = (nom, { pop = false, fragment = null } = {}) => {
    const precedent = C.onglet();
    depart = pop ? 'popstate' : 'clic';
    return C.chargerOnglet(nom).then(() => {
      if (!pop) history.pushState(null, '', CHEMIN[nom] + (fragment !== null ? fragment : hashes.get(nom) || ''));
      return arriver(nom, precedent, !pop && fragment === null);
    }, (e) => {
      const a = C.onglet();
      if (pop && a) history.replaceState(null, '', CHEMIN[a] + (hashes.get(a) || ''));
      throw e;
    });
  };
  const aller = (nom, options) => {
    if (typeof nom !== 'string' || !NOMS.includes(nom)) return Promise.reject(new Error('Onglet inconnu.'));
    const avec = options !== null && typeof options === 'object' && options.fragment !== undefined;
    if (avec && !fragmentValide(options.fragment)) return Promise.reject(new Error('Fragment refusé.'));
    if (nom === C.onglet()) return Promise.resolve();
    return charger(nom, { fragment: avec ? options.fragment : null });
  };

  window.addEventListener('popstate', (ev) => {
    const nom = PAR_CHEMIN[location.pathname];
    if (!nom || nom === C.onglet()) return;
    ev.stopImmediatePropagation(); // le moteur de l'onglet affiché ne lit pas l'adresse d'un autre onglet
    charger(nom, { pop: true }).catch(() => {});
  });

  C.surOnglet(({ onglet }) => {
    const clic = (ev) => {
      const a = ev.target && ev.target.closest ? ev.target.closest('nav.vf-tabs a[href]') : null;
      if (!a || ev.defaultPrevented || ev.button !== 0 || ev.ctrlKey || ev.metaKey || ev.shiftKey || ev.altKey) return;
      const u = new URL(a.getAttribute('href'), document.baseURI), nom = u.origin === location.origin ? PAR_CHEMIN[u.pathname] : null;
      if (!nom) return;
      ev.preventDefault();
      if (nom !== C.onglet()) charger(nom).catch(() => {});
    };
    document.addEventListener('click', clic, true);
    return () => { document.removeEventListener('click', clic, true); memoriser(onglet, depart); depart = 'clic'; };
  }, { cle: '00-vf-onglets.js' });

  window.VF_ONGLETS = Object.freeze({ aller, courant: () => C.onglet() });
})();
