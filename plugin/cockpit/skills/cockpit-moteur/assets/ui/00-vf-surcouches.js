// VibeFlow (80-02) : pile unique des surcouches (FORM-02, P80-D-11, P80-D-33, P80-D-34). Elle décide de l'ordre d'Échap, du piège à Tab et de l'inert des
// modales ; les tiroirs et les feuilles s'y inscrivent au lieu de recopier une liste de « surcouches ouvertes ». Chargée avant toute autre extension.
// vf-coquille: persistant
// Contrat d'Échap : une surcouche que la pile ferme consomme l'appui (preventDefault puis stopPropagation) ; sans surcouche, ou terminal au-dessus,
// l'appui passe intact. À l'évaluation : l'objet VF_SURCOUCHES et un écouteur de touches en capture sur window ; ce qui lit le moteur est dans `accroches`.
(() => {
  if (window.VF_SURCOUCHES) return;
  const pile = [], refs = { moteur: null }, FOC = 'a[href], button, input, select, textarea, summary, [tabindex]';
  const par = (id) => document.getElementById(id);
  const ouvert = (id) => { const x = par(id); return x && x.classList.contains('open') ? x : null; };
  const visible = (x) => !!x && x.isConnected && x.getClientRects().length > 0 && getComputedStyle(x).visibility !== 'hidden';
  const focalisables = (b) => [...b.querySelectorAll(FOC)].filter((x) => !x.disabled && x.tabIndex >= 0 && visible(x) && !x.closest('[inert]'));
  const consomme = (ev) => { ev.preventDefault(); ev.stopPropagation(); };
  const canevas = () => { const C = window.VF_CANEVAS; return C && C.carteItinerante ? C.carteItinerante() : null; };
  // menus, visite et boîtes de dialogue que le moteur tient lui-même : ils couvrent la pile mais elle ne les ferme pas
  const vivantes = () => {
    const l = ['flowmenu', 'legend'].map(ouvert).filter(Boolean), c = par('ctxmenu'), T = window.FloorplanTour;
    if (c && !c.hidden) l.push(c);
    if (T && T.active()) l.push(par('tour') || document.body);
    for (const d of document.querySelectorAll('[role="dialog"], [aria-modal="true"]')) { // la feuille de détail (#panel) n'est pas une surcouche ici
      if (d.id !== 'panel' && visible(d) && !pile.some((e) => e.el.contains(d)) && !l.some((x) => x.contains(d))) l.push(d);
    }
    return l;
  };
  const actives = () => pile.filter((e) => e.fermer && e.el.isConnected); // sans `fermer` : la région du terminal, présente mais jamais fermée par la pile
  const dessus = () => { const v = vivantes(), a = actives(); return v.length ? v[v.length - 1] : a.length ? a[a.length - 1].el : null; };
  const ouverte = () => vivantes().length > 0 || actives().length > 0;
  const couverte = (el) => {
    if (vivantes().some((x) => x !== el && !el.contains(x) && !x.contains(el))) return true;
    return pile.slice(pile.findIndex((e) => e.el === el) + 1).some((e) => e.fermer && e.el.isConnected && e.el !== el);
  };
  // modale : l'inert tombe sur les FRÈRES de la boîte au niveau de body (jamais un ancêtre : un inert d'ancêtre ne se lève pas dessous) ; liste tenue à part
  const prop = new Map(); // élément inerté par la pile -> nombre de surcouches qui le demandent (il ne se lève qu'à zéro)
  const inerter = (e) => {
    for (const o of pile) o.inertes = (o.inertes || []).filter((x) => x !== e.el); // la boîte qui s'ouvre ne reste pas inerte d'une autre
    if (prop.has(e.el)) { prop.delete(e.el); e.el.removeAttribute('inert'); }
    e.inertes = [];
    for (const c of document.body.children) {
      if (c === e.el || c.contains(e.el) || c.hidden || c.matches('script, style, link, template')) continue;
      if (prop.has(c)) { prop.set(c, prop.get(c) + 1); e.inertes.push(c); continue; }
      if (c.inert) continue; // déjà inerte d'un autre (région du terminal fermée) : jamais le nôtre
      c.inert = true; prop.set(c, 1); e.inertes.push(c);
    }
  };
  const lever = (e) => { // seulement ce que cette modale a posé ; un élément fermé de lui-même (région du terminal) garde son inert
    for (const x of e.inertes) {
      const n = (prop.get(x) || 1) - 1;
      if (n > 0) { prop.set(x, n); continue; }
      prop.delete(x); if (!x.hidden) x.removeAttribute('inert');
    }
    e.inertes = [];
  };
  // le moteur rend le focus EN fermant : l'inert est levé avant ; si la surcouche reste ouverte après l'évènement, il est reposé
  const levee = (h) => { lever(h); setTimeout(() => { if (pile.includes(h) && h.modale && !h.inertes.length) inerter(h); }, 0); };
  const rendre = (e) => {
    const a = document.activeElement;
    if (a && a !== document.body && !e.el.contains(a)) return; // le focus est déjà ailleurs : rien à rendre
    const c = [e.ouvreur, canevas(), par('stage')].find((x) => x && visible(x) && !x.closest('[inert]'));
    if (c) { if (!c.hasAttribute('tabindex') && c.tabIndex < 0) c.tabIndex = -1; c.focus({ preventScroll: true }); }
  };
  const ouvrir = (el, { modale = false, ouvreur = document.activeElement, fermer, persistant = false, rendu = true } = {}) => {
    if (!el || pile.some((e) => e.el === el)) return;
    const e = { el, modale: !!modale, ouvreur, fermer, persistant: !!persistant, rendu };
    pile.push(e); if (e.modale) inerter(e);
  };
  const retirer = (el) => {
    const i = pile.findIndex((e) => e.el === el); if (i < 0) return;
    const [e] = pile.splice(i, 1);
    if (e.modale) { lever(e); if (e.rendu) rendre(e); }
  };
  const piege = (ev, m) => { // Tab et Maj+Tab bouclent sur les éléments focalisables visibles de la boîte
    const l = focalisables(m.el), a = document.activeElement;
    if (!l.length) { ev.preventDefault(); return; }
    if (!m.el.contains(a)) { ev.preventDefault(); l[0].focus(); }
    else if (ev.shiftKey && (a === l[0] || !l.includes(a))) { ev.preventDefault(); l[l.length - 1].focus(); }
    else if (!ev.shiftKey && a === l[l.length - 1]) { ev.preventDefault(); l[0].focus(); }
  };
  const rien = (t) => t === document.body || t === document.documentElement || !!(t.closest && t.closest('#svg, #stage'));
  const echap = (ev) => { // vf-echap
    const t = ev.target, a = actives(), h = a[a.length - 1];
    if (ev.defaultPrevented || !h || vivantes().length || pile.some((e) => !e.fermer && e.el.contains(t))) return;
    if (h.modale) {
      levee(h);
      if (h.el === par('palette') && t.id === 'search') return; // le champ garde son propre Échap
      consomme(ev); h.fermer(); return;
    }
    const flux = refs.moteur && refs.moteur.state && refs.moteur.state.flow; // un parcours, une bulle d'aide : ils prennent l'Échap avant le tiroir
    if (rien(t) && !flux && !document.querySelector('.vf-git-bulle:not([hidden]), #sc-gloss.on')) { consomme(ev); h.fermer(); return; }
    const d = a.find((e) => !e.modale && e !== h && e.el.contains(t)); // focus dans un tiroir couvert par un autre : son propre Échap se tait, la pile le ferme
    if (d) { consomme(ev); d.fermer(); }
  };
  let avant = null, courant = null; // les deux derniers éléments focalisés : l'ouvreur d'une modale ouverte par le moteur
  window.addEventListener('focusin', (ev) => { avant = courant; courant = ev.target; }, true);
  window.addEventListener('mousedown', (ev) => { // clic sur le fond ou sur la croix : même raison que pour Échap
    const h = [...pile].reverse().find((e) => e.modale && e.el.isConnected);
    if (h && (ev.target === h.el || (ev.target.closest && ev.target.closest('#pal-x, #results')))) levee(h);
  }, true);
  window.addEventListener('keydown', (ev) => {
    const modale = [...pile].reverse().find((e) => e.modale && e.el.isConnected);
    if (ev.key === 'Enter' && modale && modale.el === par('palette')) levee(modale); // choisir un résultat : le moteur rend le focus au panneau dans la foulée
    if (ev.key === 'Tab' && modale) piege(ev, modale);
    else if (ev.key === 'Escape') echap(ev);
  }, true);
  window.VF_SURCOUCHES = Object.freeze({ ouvrir, fermer: retirer, dessus, ouverte, couverte });

  const CSS = `@media (min-width: 701px) {
    body.no-panel #panel { visibility: hidden; transition: transform .45s var(--ease), opacity .3s var(--ease), visibility 0s linear .45s; }
    body:not(.no-panel) #panel { visibility: visible; transition-delay: 0s; } }`;
  // vf-surcouches:accroches
  const accroches = () => { // tout ce qui dépend du document de l'onglet ; rend le nettoyage
    refs.moteur = window.Floorplan || null;
    const st = document.createElement('style'); st.textContent = CSS; document.head.appendChild(st);
    const SUIVIES = [['modal', () => par('modal').querySelector('[data-close]').click(), true], ['palette', () => par('pal-x').click(), false]];
    let sansPanneau = document.body.classList.contains('no-panel');
    const synchro = () => {
      for (const [id, fermer, rendu] of SUIVIES) { // la pile OBSERVE la classe `open` : elle ne ferme rien d'elle-même (sauf la palette, par Échap)
        const x = par(id), dedans = !!x && pile.some((e) => e.el === x);
        if (x && x.classList.contains('open') && !dedans) ouvrir(x, { modale: true, ouvreur: x.contains(courant) ? avant : courant, fermer, rendu });
        else if (x && !x.classList.contains('open') && dedans) retirer(x);
      }
      const T = par('tour'); // créée après la pile : suivie dès qu'elle existe
      if (T && !T.vfSuivie) { T.vfSuivie = true; obs.observe(T, { attributes: true }); }
      const dT = !!T && pile.some((e) => e.el === T), tv = !!T && (dT || !!refs.tourBtn) && visible(T); // aucune lecture de mise en page sans bouton ni entrée
      if (tv && !dT && refs.tourBtn) { // visite ouverte par le bouton : modale ; ouverte d'elle-même : jamais (Q5)
        ouvrir(T, { modale: true, ouvreur: refs.tourBtn, fermer: () => window.FloorplanTour.end() }); refs.tourBtn = null;
      } else if (!tv && dT) retirer(T);
      const r = [...document.body.children].find((e) => e.matches('section[role="region"]') && getComputedStyle(e).position === 'fixed') || null, on = !!r && !r.hidden, dedansT = !!r && pile.some((e) => e.el === r);
      if (on && !dedansT) ouvrir(r, { persistant: true }); else if (r && !on && dedansT) retirer(r);
      const ferme = document.body.classList.contains('no-panel'), p = par('panel'), a = document.activeElement;
      if (ferme && !sansPanneau && p && a && p.contains(a) && !pile.some((e) => e.el === p)) {
        // le panneau qui se ferme ne garde pas le focus (jamais body) ; un tiroir inscrit dedans (« Au travail ») rend le sien
        const c = [par('btn-panel'), canevas(), par('stage')].find(visible);
        if (c) { if (!c.hasAttribute('tabindex') && c.tabIndex < 0) c.tabIndex = -1; c.focus({ preventScroll: true }); }
      }
      sansPanneau = ferme;
    };
    const bouton = (ev) => { // la visite ouverte par son bouton se retient 1,5 s : au-delà, une ouverture est celle de la visite d'elle-même
      const b = ev.target.closest && ev.target.closest('#tour-btn');
      if (b) { refs.tourBtn = b; setTimeout(() => { if (refs.tourBtn === b) refs.tourBtn = null; }, 1500); }
    };
    window.addEventListener('click', bouton, true);
    const obs = new MutationObserver(synchro);
    for (const id of ['modal', 'palette']) obs.observe(par(id), { attributes: true, attributeFilter: ['class'] });
    obs.observe(document.body, { childList: true, attributes: true, attributeFilter: ['class'] }); // une seule inscription : une seconde remplace la première
    synchro();
    return () => {
      obs.disconnect(); st.remove(); window.removeEventListener('click', bouton, true); for (const e of pile.slice()) if (!e.persistant) retirer(e.el); };
  };
  if (window.VF_COQUILLE && window.VF_COQUILLE.surOnglet) window.VF_COQUILLE.surOnglet(accroches, { cle: '00-vf-surcouches.js' });
  else accroches();
})();
