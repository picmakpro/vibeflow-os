// VibeFlow (80-04) : vue DOM de Projet en couloirs (FORM-05, P80-D-01, P80-D-02) — montée dans main#stage par-dessus la scène du moteur, qui
// continue de rendre dessous.
// Modèle et rendu : 41-vf-projet-modele.js, 41-vf-projet-rendu.js ; clavier : 41-vf-projet-clavier.js. Ne parle au viewer que par window.Floorplan,
// sans patch ni requête.
// Exposé : window.VF_PROJET { formes(), forme(), basculer(nom), carteDe(id) } (gelé). `?vue=` : liste fermée (couloirs, graphe ici ; 80-07 y inscrit
// « liste »), sinon la forme par défaut.
(() => {
  const SC = window.Floorplan, M = window.__vfProjetModele, R = window.__vfProjetRendu;
  if (!SC || !M || !R || !SC.graph.meta || SC.graph.meta.vfTab !== 'project') return;
  const { graph: G, state } = SC;
  const stage = document.getElementById('stage');
  if (!stage) return;
  const FORMES = ['couloirs', 'graphe'], LIBELLES = { couloirs: 'Couloirs', graphe: 'Graphe' };
  // T-80-08 : une valeur hors de la liste vaut la forme par défaut, jamais insérée dans le DOM
  const demandee = new URLSearchParams(location.search).get('vue');
  let forme = FORMES.includes(demandee) ? demandee : 'couloirs', vivant = false, section = null, corps = null, statut = null, flottant = null,
    conteneur = null, avantVisite = null, ro = null, debutPose = 0, precedents = new Map();
  const ouverts = new Set(), noeuds = () => new Map((G.nodes || []).map((n) => [n.id, n]));
  const conteneurJalon = () => { const c = String(state.container); const n = c.startsWith('n:') ? noeuds().get(c.slice(2)) : null;
    return c === 'n:history' || (!!n && n.kind === 'jalon'); };
  const affichee = () => forme === 'couloirs' && (state.container === 'root' || conteneurJalon()); // un jalon vu en couloirs est ramené à la racine (P80-C76-3)

  const style = document.createElement('style');
  style.textContent = `
    section.vf-projet { position: absolute; inset: 0; z-index: 1; overflow: auto; box-sizing: border-box; scroll-behavior: auto;
      font-family: var(--sans); color: var(--text);
      padding: calc(var(--hh) + var(--sp-16)) var(--edge) var(--vf-bas, var(--sp-32)); scroll-padding-block-end: var(--vf-bas, var(--sp-32));
        scroll-padding-block-start: calc(var(--hh) + var(--sp-16)); }
    body:not(.vf-forme-couloirs) section.vf-projet { display: none; }
    body.vf-forme-couloirs #stage { background-image: none; } body.vf-forme-couloirs #svg { visibility: hidden; } body.vf-forme-couloirs #zoom,
      body.vf-forme-couloirs #context { display: none; }
    section.vf-projet button { font: inherit; color: inherit; text-align: left; cursor: pointer; }
    /* la bascule et la barre de jalon suivent le titre à gauche : à droite, le panneau ouvert les recouvrirait (80-UI-SPEC § 2.1 les aligne à droite : écart assumé) */
    .vp-tete { display: flex; align-items: center; gap: var(--sp-24); margin-bottom: var(--sp-16); flex-wrap: wrap; }
    .vp-tete h1 { margin: 0; font-size: 22px; font-weight: 600; letter-spacing: -.02em; } .vp-tete h1:focus { outline: none; }
    .vp-bascule { display: inline-flex; gap: var(--sp-2); padding: var(--sp-4); border-radius: var(--r-ctl); background: var(--raise); flex: none; }
    .vp-bascule button { min-height: 36px; padding: 0 var(--sp-12); border: 0; border-radius: 8px; background: none; font-size: 13px;
      font-weight: 500; color: var(--text-3); }
    .vp-bascule button[aria-pressed="true"] { background: var(--surface); color: var(--text); font-weight: 600; box-shadow: var(--shadow-card); }
    .vp-bascule button:focus-visible, .vp-carte:focus-visible, .vp-rangee:focus-visible,
      .vp-details summary:focus-visible { outline: 2px solid var(--ring); outline-offset: var(--sp-2); }
    #vf-projet-flottant { position: absolute; z-index: 3; left: var(--edge); top: calc(var(--hh, 64px) + var(--sp-8));
      } body.vf-forme-couloirs #vf-projet-flottant { display: none; }
    .vp-status { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }
    .vp-info { padding: var(--inset-box); border-radius: var(--r-ctl); background: var(--surface); font-size: 13px; color: var(--text-2);
      margin-bottom: var(--gap-section); }
    .vp-info p { margin: 0; } .vp-info p + p { margin-top: var(--sp-4); }
    .vp-jalon { margin-bottom: var(--gap-section); }
    .vp-jt { display: flex; align-items: flex-end; gap: var(--sp-24); flex-wrap: wrap; margin-bottom: var(--sp-16); }
    .vp-jn h2 { margin: 0; font-size: 18px; font-weight: 600; letter-spacing: -.015em; } .vp-syn { margin: var(--sp-2) 0 0; font-size: 13px;
      color: var(--text-2); }
    .vp-barre { display: flex; align-items: center; gap: var(--sp-12); } .vp-barre .vf-bar { width: 180px; margin-top: 0; }
    .vp-pc { font-family: var(--mono); font-size: 12px; font-weight: 500; color: var(--text-3); }
    .vp-couloirs { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: var(--sp-16); }
    .vp-ch { display: flex; align-items: center; gap: var(--sp-4); margin: 0 0 var(--sp-12); padding-bottom: var(--sp-8);
      border-bottom: 1px solid var(--hair-2); font-size: 13px; font-weight: 500; color: var(--text); }
    .vp-ch .vp-mot { flex: 1; } .vp-n { font-family: var(--mono); font-size: 12px; font-weight: 500; color: var(--text-3); }
    .vp-cartes, .vp-rangees { list-style: none; margin: 0; padding: 0; } .vp-cartes { display: flex; flex-direction: column; gap: var(--sp-8); }
    .vp-vide { margin: var(--sp-8) 0 0; font-size: 12px; color: var(--text-3); }
    .vp-carte { display: grid; grid-template-columns: min-content minmax(0, 1fr); column-gap: var(--sp-8); row-gap: var(--sp-2);
      align-items: baseline; width: 100%; min-height: 44px; box-sizing: border-box;
      padding: var(--sp-12) var(--inset-card); border: 1.5px solid transparent; border-radius: var(--r-card); background: var(--surface);
        box-shadow: var(--shadow-card); }
    .vp-num { min-width: 5ch; font-family: var(--mono); font-size: 12.5px; font-weight: 500; color: var(--text-3); }
    .vp-titre { display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; overflow-wrap: anywhere;
      font-size: 13px; line-height: 1.4; font-weight: 500; color: var(--text-2); }
    [data-couloir="en-cours"] .vp-titre, [data-couloir="a-recetter"] .vp-titre { font-weight: 600; color: var(--text); }
    .vp-etat { grid-column: 2; min-height: 1.4em; font-size: 12px; font-weight: 400; color: var(--text-3); } .vp-preuve { font-weight: 500;
      color: var(--text-2); }
    .vp-carte[aria-current="true"], .vp-rangee[aria-current="true"] { background: var(--surface-hover); box-shadow: none; border-color: var(--text-3); }
    .vp-listes { display: flex; flex-direction: column; gap: var(--sp-8); }
    .vp-details { border-radius: var(--r-card); background: var(--surface); } .vp-details summary { display: flex; align-items: center;
      justify-content: space-between; gap: var(--sp-12); min-height: 44px; padding: 0 var(--inset-card); cursor: pointer; font-size: 13px; font-weight: 500; }
    .vp-rangee { display: flex; align-items: center; justify-content: space-between; gap: var(--sp-12); width: 100%; min-height: 44px;
      padding: var(--inset-row); border: 1.5px solid transparent; background: none; font-size: 13px; color: var(--text); }
    .vp-rangees li + li { border-top: 1px solid var(--hair); } .vp-r-t { min-width: 0; overflow-wrap: anywhere; } .vp-r-d { font-family: var(--mono);
      font-size: 12px; color: var(--text-3); }
    /* panneau latéral : le panneau se pose PAR-DESSUS ; une extrémité défilable (hors flux) permet d'amener une carte hors de lui */
    @media (min-width: 1000px) and (pointer: fine) {
      section.vf-projet { scroll-padding-inline-end: var(--pw, 0px); }
      section.vf-projet::after { content: ""; position: absolute; top: 0; left: 100%; width: var(--pw, 0px); height: var(--sp-2); }
      section.vf-projet.vp-tiroir { scroll-padding-inline-start: var(--vp-debut, 0px);
        } section.vf-projet.vp-tiroir .vp-corps { margin-inline-start: var(--vp-debut, 0px); width: var(--vp-larg, auto); }
    }
    @media (hover: hover) { .vp-carte, .vp-rangee { transition: background-color 150ms var(--ease), box-shadow 150ms var(--ease);
      } .vp-carte:hover:not([aria-current="true"]) { background: var(--surface-hover); box-shadow: var(--shadow-lift); } }
    @media (max-width: 999px) { .vp-couloirs { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
    @media (max-width: 700px) { .vp-couloirs { grid-template-columns: minmax(0, 1fr); } .vp-barre, .vp-barre .vf-bar { width: 100%;
      } .vp-barre .vf-bar { flex: 1; } }
    @media (pointer: coarse), (max-width: 700px) { .vp-bascule button { min-height: 44px; } }
    @media (prefers-reduced-motion: reduce) { .vp-carte, .vp-rangee { transition: none; } }
  `;
  document.head.appendChild(style);

  const outils = () => `<div class="vp-bascule" role="group" aria-label="Forme de l'affichage">${FORMES.map((f) =>
    `<button type="button" data-forme="${f}" aria-pressed="${f === forme}">${LIBELLES[f]}</button>`).join('')}</div>`;
  const classes = () => { document.body.classList.toggle('vf-forme-couloirs', affichee()); document.body.classList.toggle('vf-forme-graphe', !affichee()); };
  const marquerBascule = () => document.querySelectorAll('[data-forme]').forEach((b) => b.setAttribute('aria-pressed', String(b.dataset.forme === forme)));
  const K = window.__vfProjetClavier || { appliquer() {}, poser() {}, ramener() {}, ordre: () => [], repli: () => null, memoire: new Map(), cle: () => '' };
  const selectionnee = () => (typeof state.selected === 'string' ? state.selected : null);
  const carteDe = (id) => (section ? section.querySelector(`.vp-carte[data-id="${CSS.escape(id)}"]`) : null);
  const annoncer = (txt) => { if (statut) { statut.textContent = ''; statut.textContent = txt; } };
  const couloirsDe = () => { const m = new Map(); for (const b of M.blocs(G)) for (const [c,
    l] of Object.entries(b.couloirs)) for (const k of l) m.set(k.id, [c, k]); return m; };
  const quitteLaVue = (a) => !!a && (a === document.body || !!(a.closest && a.closest('#svg')));

  const dessiner = () => {
    if (!vivant) return;
    const a = document.activeElement, dans = !!a && corps.contains(a) && a.matches('.vp-carte, .vp-rangee, summary');
    const memo = dans ? { id: a.dataset.id || null, resume: a.tagName === 'SUMMARY' ? a.parentNode.dataset.cle : null,
      ordre: a.dataset.id ? K.ordre(a) : [], cle: a.dataset.id ? K.cle(a) : '' } : null;
    const avant = section.scrollTop, avantG = section.scrollLeft, vus = precedents; // les couloirs du rendu précédent
    const modele = { blocs: M.blocs(G), historique: M.historique(G), listes: M.listes(G) };
    corps.innerHTML = R.vue(modele, { sel: selectionnee(), ouverts });
    K.appliquer(corps);
    section.scrollTop = avant; section.scrollLeft = avantG;
    const apres = couloirsDe(), suivi = memo && memo.id || selectionnee();
    precedents = apres;
    if (suivi && vus.has(suivi) && apres.has(suivi) && vus.get(suivi)[0] !== apres.get(suivi)[0]) { // une seule annonce : la phase suivie qui change de couloir
      const mot = M.COULOIRS.find((c) => c[0] === apres.get(suivi)[0])[1];
      annoncer(`Phase ${apres.get(suivi)[1].num} : ${mot}`);
    }
    if (memo) restituer(memo);
  };
  const restituer = (m) => { // le focus d'un contrôle de la vue survit au redessin ; un contrôle disparu suit l'ordre unique de la famille (80-UI-SPEC § 5)
    if (m.resume) { const s = corps.querySelector(`details[data-cle="${m.resume}"] summary`); if (s) { s.focus({ preventScroll: true }); return; } }
    const par = (id) => (id ? corps.querySelector(`[data-id="${CSS.escape(id)}"]`) : null);
    let cible = par(m.id);                                    // (1) l'équivalent par clé stable
    if (!cible && m.id) {                                     // (3) le voisin suivant, puis précédent, de la même collection
      const i = m.ordre.indexOf(m.id), suite = m.ordre.slice(i + 1).map(par).find(Boolean), avant = m.ordre.slice(0, i).reverse().map(par).find(Boolean);
      cible = suite || avant || null;
    }
    if (!cible && m.cle) { // (4) l'arrêt itinérant de la collection
      const q = m.cle.startsWith('liste:') ? `details[data-cle="${m.cle.slice(6)}"] .vp-rangee` : `.vp-jalon[data-jalon="${m.cle}"] .vp-carte`;
      cible = corps.querySelector(q + '[tabindex="0"]');
    }
    if (cible) K.poser(cible, { defiler: false }); else K.repli({ defiler: false }); // (5) l'élément sélectionné, sinon le h1 : jamais body
  };

  // zone basse (80-UI-SPEC § 3) : la vue ne passe jamais sous #ask, #vf-coin, la pastille « Terminal » ni la feuille de détail ; le tiroir du
  // terminal relève #stage, la vue monte avec lui
  const hauteur = (e) => { const b = e && !e.hidden && e.isConnected ? e.getBoundingClientRect() : null; return b && b.width > 0 ? Math.round(b.height) : 0; };
  const QS = ['#ask', '#vf-coin', '#panel', '.vf-term-pastille', '#vf-git-tiroir', '.vf-git-tiroir'];
  const mesurerBas = () => {
    if (!vivant) return;
    // un élément né après le montage (pastille, coin) est observé dès qu'il existe
    for (const q of QS) { const e = document.querySelector(q); if (e && ro) ro.observe(e); }
    const panneau = document.getElementById('panel'), p = panneau && !document.body.classList.contains('no-panel') ? panneau.getBoundingClientRect() : null;
    // la feuille de détail est le panneau posé en bas, pleine largeur
    const feuille = p && p.width >= stage.getBoundingClientRect().width * 0.8 ? Math.round(p.height) : 0;
    const bas = hauteur(document.getElementById('ask')) + hauteur(document.getElementById('vf-coin'))
      + hauteur(document.querySelector('.vf-term-pastille')) + feuille;
    // dérivé : #ask + #vf-coin + feuille + pastille mesurés
    section.style.setProperty('--vf-bas', `calc(${bas}px + var(--edge) + var(--sp-8) + var(--edge) + env(safe-area-inset-bottom, 0px))`);
    const t = document.querySelector('#vf-git-tiroir, .vf-git-tiroir'), ouvert = !!t && !t.hidden && t.offsetWidth > 0
      && matchMedia('(min-width: 1000px) and (pointer: fine)').matches;
    const d = ouvert ? t.offsetLeft + t.offsetWidth + 16 : 0, avant = debutPose; // en mise en page, jamais en position animée
    if (d !== debutPose) { // le tiroir Git recouvre le bord gauche : une extrémité de début, la vue ne bouge pas
      debutPose = d; section.style.setProperty('--vp-debut', d + 'px'); section.style.setProperty('--vp-larg',
        ouvert ? section.clientWidth - 2 * 16 + 'px' : 'auto');
      // les couloirs gardent leur place à l'écran
      section.classList.toggle('vp-tiroir', ouvert); section.scrollLeft = Math.max(0, section.scrollLeft + d - avant);
    }
  };
  const surRender = () => {
    if (!vivant) return;
    const avant = conteneur; conteneur = state.container;
    if (forme === 'couloirs' && state.container !== 'root' && conteneurJalon()) { SC.go('root', { select: state.selected, push: false }); return; } // P80-C76-3
    const a = document.activeElement, venaitDeLaVue = !!a && section.contains(a), changeNiveau = avant !== null && avant !== state.container;
    classes(); dessiner(); mesurerBas();
    if (!affichee()) { // plongée : le focus va à la première carte du niveau d'arrivée (le canevas, qu'il montre)
      const C = window.VF_CANEVAS, id = C && C.carteItinerante && C.carteItinerante();
      if (venaitDeLaVue && changeNiveau) { if (!(id && C.focaliser(id))) stage.focus({ preventScroll: true }); }
    } else if (changeNiveau && quitteLaVue(a)) K.repli(); // retour à la racine : la carte de la phase quittée
  };
  const basculer = (nom, { url = true } = {}) => {
    if (!FORMES.includes(nom) || nom === forme) return false;
    forme = nom; marquerBascule(); classes(); mesurerBas();
    if (url) { try { const u = new URL(location.href); u.searchParams.set('vue', nom); history.replaceState(history.state, '',
      u.pathname + u.search + u.hash); } catch (e) { void e; } }
    const n = M.blocs(G).reduce((s, b) => s + b.total, 0);
    annoncer(nom === 'graphe' ? 'Affichage en graphe' : `Affichage en couloirs, ${n} phase${n > 1 ? 's' : ''}`);
    return true;
  };

  const pose = [];
  const ecoute = (cible, type, fn, capture) => { cible.addEventListener(type, fn, capture); pose.push(() => cible.removeEventListener(type, fn, capture)); };
  const init = () => {
    vivant = true;
    section = document.createElement('section'); section.className = 'vf-projet'; section.setAttribute('aria-labelledby', 'vf-projet-titre');
    section.innerHTML = `<div class="vp-tete"><h1 id="vf-projet-titre" tabindex="-1">Projet</h1>${outils()}</div>`
      + '<div class="vp-status" role="status" aria-live="polite" aria-atomic="true"></div><div class="vp-corps"></div>';
    corps = section.querySelector('.vp-corps'); statut = section.querySelector('.vp-status');
    corps.innerHTML = R.etatVue('Chargement du projet');
    flottant = document.createElement('div'); flottant.id = 'vf-projet-flottant'; flottant.innerHTML = outils();
    stage.append(section, flottant); classes();
    ecoute(document, 'click', (ev) => { const b = ev.target.closest && ev.target.closest('[data-forme]'); if (b) basculer(b.dataset.forme); });
    ecoute(section, 'click', (ev) => { const c = ev.target.closest && ev.target.closest('[data-id]'); if (c && section.contains(c)) SC.select(c.dataset.id); });
    ecoute(section, 'dblclick', (ev) => { const c = ev.target.closest && ev.target.closest('.vp-carte'); if (c) SC.go(c.dataset.id); });
    ecoute(section, 'toggle', (ev) => { const d = ev.target; if (d.dataset && d.dataset.cle) { if (d.open) ouverts.add(d.dataset.cle);
      else ouverts.delete(d.dataset.cle); } }, true);
    // visite (P80-D-09, P80-D-38) : elle se joue sur le graphe, sans patch de 40-tour.js ; la forme d'avant revient à sa fin
    const tourActif = () => !!(window.FloorplanTour && window.FloorplanTour.active && window.FloorplanTour.active());
    const versGraphe = () => { if (affichee() && avantVisite === null) { avantVisite = forme; basculer('graphe', { url: false }); } };
    ecoute(document, 'click', (ev) => { if (ev.target.closest && ev.target.closest('#tour-btn') && !tourActif()) versGraphe(); }, true);
    const carteVisite = document.getElementById('tour');
    if (carteVisite) {
      const mo = new MutationObserver(() => { if (tourActif()) versGraphe(); else if (avantVisite !== null) { const f = avantVisite;
        avantVisite = null; basculer(f, { url: false }); } });
      mo.observe(carteVisite, { attributes: true, attributeFilter: ['hidden', 'class', 'style'] }); pose.push(() => mo.disconnect());
    }
    ro = new ResizeObserver(mesurerBas); const mo2 = new MutationObserver(mesurerBas);
    ro.observe(stage); mo2.observe(document.body, { attributes: true, attributeFilter: ['class'] }); mo2.observe(stage, { childList: true });
    pose.push(() => { ro.disconnect(); mo2.disconnect(); ro = null; });
    ecoute(window, 'vf-git:etat', mesurerBas); ecoute(window, 'resize', mesurerBas);
    let derniere = null;
    // la sélection vient de l'état du panneau : aria-current suit, et la carte choisie est ramenée hors du panneau et du tiroir (instantané)
    SC.on('render', surRender); SC.on('panel', () => {
      if (!vivant) return; const sel = selectionnee();
      section.querySelectorAll('[data-id]').forEach((e) => { if (e.dataset.id === sel) e.setAttribute('aria-current', 'true');
        else e.removeAttribute('aria-current'); });
      if (sel !== derniere) { derniere = sel; const e = sel && section.querySelector(`[data-id="${CSS.escape(sel)}"]`); if (e && affichee()) K.ramener(e); }
      mesurerBas();
    });
    mesurerBas(); surRender();
    return () => { vivant = false; pose.splice(0).forEach((f) => f()); section.remove(); flottant.remove(); };
  };
  window.VF_PROJET = Object.freeze({ formes: () => FORMES.slice(), forme: () => forme, basculer, carteDe });
  classes();
  const C = window.VF_COQUILLE;
  const demarrer = () => (vivant ? undefined : init());
  if (C && typeof C.surOnglet === 'function') C.surOnglet(init); // P80-D-42 : la coquille, sinon `ready` (ou le premier rendu, s'il l'a devancé)
  else if (state.layout) demarrer(); else { SC.on('ready', demarrer); SC.on('render', demarrer); }
})();
