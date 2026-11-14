// VibeFlow (80-10) : changer d'onglet sans recharger la page (FORM-16, P80-D-22, P80-D-42, P80-D-59 b) — routage sur la coquille de la Phase 79.
// vf-coquille: persistant
// Un clic d'onglet, Précédent et Suivant, VF_ONGLETS.aller(nom) passent par une même fonction : VF_COQUILLE.chargerOnglet(nom) d'abord, puis, après sa
// résolution SEULEMENT, history.pushState du chemin (jamais depuis popstate : le navigateur a déjà changé l'adresse), puis la vue mémorisée, le titre,
// vf:onglet, le focus et l'annonce. Un chargement rejeté ne change ni l'adresse, ni l'onglet affiché, ni le focus (après un popstate rejeté, l'adresse
// est ramenée par replaceState) ; dire l'échec à l'écran est 00-vf-onglets-echec.js (80-21).
// Évaluation : l'objet, l'écouteur popstate et UNE inscription surOnglet ;
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
  const memoriser = (nom) => {
    const SC = moteur(); if (!SC || !SC.state) return;
    const t = SC.state.t, v = { cont: SC.state.container, sel: typeof SC.state.selected === 'string' ? SC.state.selected : null, t: null };
    if (t && [t.k, t.x, t.y].every(Number.isFinite)) v.t = { k: t.k, x: t.x, y: t.y };
    vues.set(nom, v);
  };

  // le titre est composé par 90-vf-titre.js (préfixe « vous attend » compris) : on lui donne l'onglet affiché ; sans lui, repli autonome
  const titrer = (nom) => {
    const SC = moteur(), p = SC && SC.graph && SC.graph.project, n = String((p && p.name) || '').replace(/ — (Projet|Équipe)$/, '');
    const T = window.__vfTitre, b = window.__vfTitreBase;
    if (T && typeof T.composer === 'function' && b) { b.onglet = LIBELLE[nom]; if (!b.nom) b.nom = n; T.composer(); return; }
    if (!document.title.startsWith(LIBELLE[nom] + ' · ')) document.title = LIBELLE[nom] + ' · ' + n;
  };
  const dire = (texte) => { // la zone status de Projet quand elle existe, sinon celle de la barre de question (aucune lecture ici)
    const F = window.VF_PROJET, z = document.getElementById('ask-live');
    if (F && typeof F.annoncer === 'function') F.annoncer(texte); else if (z) { z.textContent = ''; z.textContent = texte; } // remise à zéro
  };
  const annoncer = (nom) => dire(LIBELLE[nom]);
  // 80-21 : l'échec d'un chargement est lu dans la coquille à chaque appel (rien n'est gardé ici) ; `affiche` : l'onglet resté affiché, ou null
  const echec = () => {
    const e = C.etat();
    return e.phase === 'echec' && NOMS.includes(e.onglet) ? Object.freeze({ onglet: e.onglet, affiche: C.onglet() }) : null;
  };
  const reessayer = () => { const e = echec(); return e ? aller(e.onglet) : Promise.reject(new Error('Aucun échec à relancer.')); };
  // le tiroir Git se ferme avec l'onglet qu'il quitte (son nettoyage précède le nôtre) : l'état est lu au départ, avant tout chargement, et rendu à l'arrivée
  const gitOuvert = () => {
    const G = window.VFGitTiroir;
    return !!G && typeof G.ouvert === 'function' && G.ouvert();
  };
  const rouvrirGit = () => {
    const G = window.VFGitTiroir;
    if (G && typeof G.ouvrir === 'function' && !G.ouvert()) G.ouvrir();
  };
  // repli unique (80-UI-SPEC § 5) : l'élément sélectionné rendu, sinon le h1 ; Code et Graphe : la carte sélectionnée ou itinérante, sinon #stage ; jamais body
  const focaliser = () => {
    const SC = moteur(), K = window.VF_CANEVAS, F = window.VF_PROJET;
    const projet = !!SC && !!SC.graph.meta && SC.graph.meta.vfTab === 'project';
    const P = F && F.forme() === 'liste' ? window.__vfProjetListe : window.__vfProjetClavier; // la forme affichée a son propre repli
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
  const arriver = async (nom, precedent, avecVue, git) => {
    await restituer(nom, avecVue);
    // l'arrivée ne rejette jamais : un geste d'arrivée qui lève est consigné, la promesse de `aller` ne dit que le chargement
    for (const geste of [() => git && rouvrirGit(), () => titrer(nom), () => hashes.set(nom, location.hash),
      () => document.dispatchEvent(new CustomEvent('vf:onglet', { detail: { onglet: nom, precedent } })), focaliser, () => annoncer(nom)]) {
      try { geste(); } catch (e) { console.error('VibeFlow onglets : arrivée : ' + (e && e.message)); }
    }
  };

  // la seule fonction de chargement : clic, popstate et aller. `pop` : le navigateur a déjà posé l'adresse (`adresse`, lue à l'évènement) ;
  // `fragment` : posé tel quel (aller).
  // Les demandes passent en FILE : toute la comptabilité de départ (onglet quitté, fragment, tiroir Git, adresse) se fait quand le chargement démarre
  // vraiment, et la dernière demande l'emporte, y compris vers l'onglet encore affiché.
  let file = Promise.resolve(), enCours = 0;
  const charger = (nom, options) => {
    enCours++;
    const p = file.then(() => chargerMaintenant(nom, options || {}));
    file = p.then(() => { enCours--; }, () => { enCours--; });
    return p;
  };
  const chargerMaintenant = (nom, { pop = false, fragment = null, adresse = '' }) => {
    const ici = location.pathname + location.search + location.hash;
    if (pop && ici !== adresse) history.replaceState(null, '', adresse); // la dernière demande de l'humain gagne
    // après un échec de DÉMARRAGE (motif nul) onglet() garde l'ancien nom alors que son document est démonté : il faut le recharger
    const demonte = C.etat().phase === 'echec' && C.etat().motif === null;
    // une demande vers l'onglet affiché, devenue la dernière : rien à charger (un fragment n'y a pas d'effet)
    if (nom === C.onglet() && !demonte) return Promise.resolve();
    const precedent = C.onglet(), git = gitOuvert(), avant = location.hash;
    // le moteur d'arrivée lit l'adresse au premier rendu : le fragment de l'onglet quitté (v, s, z, git) ne doit pas s'y appliquer. Il est mémorisé, retiré
    // pendant le chargement (replaceState, aucune entrée d'historique) et remis à l'identique, chargement rejeté ou non (l'entrée quittée le garde).
    // Depuis popstate, l'adresse est déjà celle de l'arrivée.
    if (!pop) {
      if (precedent) hashes.set(precedent, avant);
      if (avant) history.replaceState(null, '', location.pathname + location.search);
    }
    return C.chargerOnglet(nom).then(() => {
      if (!pop && avant) history.replaceState(null, '', location.pathname + location.search + avant); // l'entrée quittée garde son fragment
      const chemin = CHEMIN[nom] + (fragment !== null ? fragment : hashes.get(nom) || '');
      if (!pop && PAR_CHEMIN[location.pathname] !== nom) history.pushState(null, '', chemin);
      else if (!pop && fragment !== null) history.replaceState(null, '', chemin); // relance après un échec : l'entrée existe déjà
      return arriver(nom, precedent, !pop && fragment === null, git);
    }, (e) => {
      const a = C.onglet();
      if (pop && a) history.replaceState(null, '', CHEMIN[a] + (hashes.get(a) || ''));
      if (!pop && avant) history.replaceState(null, '', location.pathname + location.search + avant);
      throw e;
    });
  };
  const aller = (nom, options) => {
    if (typeof nom !== 'string' || !NOMS.includes(nom)) return Promise.reject(new Error('Onglet inconnu.'));
    const avec = options !== null && typeof options === 'object' && options.fragment !== undefined;
    if (avec && !fragmentValide(options.fragment)) return Promise.reject(new Error('Fragment refusé.'));
    return charger(nom, { fragment: avec ? options.fragment : null });
  };

  window.addEventListener('popstate', (ev) => {
    const nom = PAR_CHEMIN[location.pathname];
    if (!nom || (nom === C.onglet() && !enCours)) return;
    ev.stopImmediatePropagation(); // le moteur de l'onglet affiché ne lit pas l'adresse d'un autre onglet
    charger(nom, { pop: true, adresse: location.pathname + location.search + location.hash }).catch(() => {});
  });

  C.surOnglet(({ onglet }) => {
    const clic = (ev) => {
      const a = ev.target && ev.target.closest ? ev.target.closest('nav.vf-tabs a[href]') : null;
      if (!a || ev.defaultPrevented || ev.button !== 0 || ev.ctrlKey || ev.metaKey || ev.shiftKey || ev.altKey) return;
      const u = new URL(a.getAttribute('href'), document.baseURI), nom = u.origin === location.origin ? PAR_CHEMIN[u.pathname] : null;
      if (!nom) return;
      ev.preventDefault();
      charger(nom).catch(() => {});
    };
    document.addEventListener('click', clic, true);
    return () => { document.removeEventListener('click', clic, true); memoriser(onglet); };
  }, { cle: '00-vf-onglets.js' });

  window.VF_ONGLETS = Object.freeze({ aller, courant: () => C.onglet(), echec, reessayer, annoncer: dire });
})();
