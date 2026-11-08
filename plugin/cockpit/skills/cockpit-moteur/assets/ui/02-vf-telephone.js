// VibeFlow (70-04, P70-D-01 : arbitrage Samuel, AskUserQuestion session principale, 2026-11-03) : le téléphone (≤ 700 px). L'en-tête tient sur UNE rangée : logo, onglets, recherche, point « au travail »
// et un bouton « ⋯ ». Les autres actions d'en-tête (thème, Santé, Travail récent, Écrans, Visite, Exporter, Parcours, Types de liens, et toute action ajoutée plus tard) vivent dans le menu du « ⋯ »,
// avec un libellé visible ; leurs pastilles de compte sont reportées sur l'entrée et sur le « ⋯ ». Chaque entrée appelle .click() du bouton d'origine (son comportement, ses gardes, ses menus) ;
// le libellé est relu à l'ouverture (déjà traduit par 80-vf-fr.js). Au-dessus de 700 px, seul le menu « ⋯ » est posé, jusqu'à 999 px (amendement ci-dessous) ; au-dessus de 999 px, rien n'est posé. Hors de l'en-tête (70-05, P70-D-09 et P70-D-10 : choix du manager) : le zoom retourne dans la scène en pile verticale à gauche, au-dessus de la barre de question ; le bouton
// Détail est masqué : le tiroir s'ouvre au tap d'une carte ou du titre de la vue, et porte une poignée et une croix (« Fermer le détail ») ; ils passent par #btn-panel, donc par l'état du viewer. Texte posé par createElement/textContent seulement ; couleurs : variables du thème.
// AMENDEMENT de P70-D-01 (« Icônes dans le menu ⋯ », arbitrage Samuel, AskUserQuestion session principale, 2026-11-06) : le menu « ⋯ » n'est plus réservé au téléphone, il commence à 999 px et moins. De 701 à 999 px les icônes secondaires
// (thème, Santé, Travail récent, Écrans, Visite, Exporter, Parcours, Types de liens, et toute action ajoutée) y passent ; restent dehors la recherche, le point « au travail », le bouton Détail (le tiroir n'a pas, au-dessus de 700 px, de titre à toucher) et l'ouvreur Git
// (seule entrée du tiroir Git quand le nom du dépôt est masqué). De 1 000 px et plus, rien n'est posé.
// PU-G-001 (« Garder ce compromis (Recommandé) », arbitrage Samuel, AskUserQuestion session principale, 2026-11-06) : le nom du dépôt est entier à la racine ; il n'est abrégé que dans un dossier, où le niveau courant du fil a la priorité ; le menu « ⋯ » reste à 999 px et moins.
(() => {
  const hr = document.querySelector('header .hr'), stage = document.getElementById('stage'), zoom = document.getElementById('zoom');
  if (!hr) return;
  const phone = matchMedia('(max-width: 700px)'), tablette = matchMedia('(max-width: 999px)'); // menu dès 999 px (amendement de P70-D-01), téléphone seul à 700 px
  const style = document.createElement('style');
  style.textContent = `
    #vf-plus { display: none; }
    #vf-plus-menu { display: none; }
    .vf-nb { display: inline-block; max-width: 100%; word-break: break-all; } /* un mot à traits d'union tient en un bloc ; plus large que sa boîte, il se coupe n'importe où (70-05, P70-D-04) */
    @media (max-width: 999px) { /* amendement de P70-D-01 (2026-11-06) : le menu « ⋯ » dès 999 px */
      #hdr-ext > button:not(#vf-lock), #theme-toggle, #btn-health, #flows-btn, #filters-btn { display: none !important; }
      #vf-plus { display: inline-flex; position: relative; }
      #vf-plus .badge, .vf-pl-i .badge { min-width: 16px; height: 16px; border-radius: 999px; background: var(--on); color: var(--on-text); font-size: 10px; font-weight: 600; display: grid; place-items: center; padding: 0 var(--sp-4); }
      #vf-plus .badge { position: absolute; top: var(--sp-8); right: var(--sp-8); min-width: 0; width: 8px; height: 8px; padding: 0; }
      #vf-plus-voile { position: fixed; inset: 0; z-index: 39; background: var(--scrim); } /* DESIGN.md §5 : un menu se pose toujours sur un voile --scrim */
      #vf-plus-menu { display: block; position: fixed; z-index: 40; top: calc(var(--hh, 56px) + var(--sp-4)); left: var(--sp-8); right: var(--sp-8); max-height: 60vh; overflow: auto; padding: var(--sp-6); border-radius: 18px; background-color: var(--bg); background-image: linear-gradient(var(--menu-solid), var(--menu-solid)); box-shadow: var(--shadow-float); } /* PU-G-011 : --menu-solid est translucide (.94 en sombre), posé sur le fond plein du thème il devient opaque : le titre ne se lit plus à travers */
      .vf-pl-i { display: flex; align-items: center; gap: var(--sp-8); width: 100%; min-height: 44px; padding: 0 var(--sp-12); border: 0; border-radius: 12px; background: none; color: var(--text); font: inherit; font-size: 14px; text-align: left; cursor: pointer; }
      .vf-pl-i:hover { background: rgba(var(--ink), .07); }
      .vf-pl-i:focus-visible { outline: 2px solid var(--ring); outline-offset: -2px; }
      .vf-pl-i.vf-pl-off { opacity: .5; cursor: default; }
      .vf-pl-i.vf-pl-off:hover { background: none; }
      .vf-pl-i .vf-pl-t { flex: 1; min-width: 0; }
      .vf-pl-i .vf-pl-ic { flex: none; width: 18px; height: 18px; color: var(--text-2); } /* PU-G-011 / PU-G-007 : une icône par ligne, celle du bouton d'origine */
      .vf-pl-etat { padding: var(--sp-8) var(--sp-12); font-size: 12px; color: var(--text-3); } /* PU-G-012 : légende du point « au travail » */
    }
    @media (min-width: 701px) and (max-width: 999px) { #vf-plus-menu { left: auto; width: min(320px, calc(100% - 2 * var(--sp-8))); } }
    @media (max-width: 700px) {
      header { display: flex; flex-wrap: nowrap; align-items: center; }
      header .hl { flex: 1 1 auto; min-width: 0; }
      header .hc { flex: 0 0 44px; }
      header .hr { flex: 0 0 auto; justify-content: flex-end; }
      header #proj-name { display: none; }
      #stage > #zoom { left: var(--edge); right: auto; top: auto; bottom: calc(var(--vf-ask-h, var(--sp-8)) + var(--edge)); flex-direction: column; border-radius: 26px; } /* --vf-ask-h : hauteur relue de la barre de question + sa marge */
      body:not(.no-panel) #stage > #zoom { bottom: calc(var(--sp-8) + min(56vh, 480px) + var(--sp-8)); } /* I-2 (intégration ; décision déléguée par Samuel (message session principale, 2026-11-08, consignée en § 10 du rapport GLOBAL, 599a42a5), option recommandée : relevé au-dessus de la feuille) : feuille de détail ouverte, le zoom se pose comme la pastille « Terminal » (vf-cockpit-terminal-tiroir-style.mjs, même dérivé : min(56vh, 480px) = hauteur max du #panel de viewer.html), au-dessus d'elle ; la pastille est son obstacle et il la surmonte (eviter), et il se replie s'il recouvrirait le titre (01-vf-responsive.js, replier) */
      html[data-vf-visite] #stage > #zoom { bottom: calc(var(--vf-ask-h, var(--sp-8)) + var(--edge)) !important; } /* visite ouverte : le zoom reste au-dessus de la feuille, même quand le terminal l'a remonté au-dessus de sa pastille (style en ligne, vf-cockpit-terminal-tiroir.mjs) */
      #context h1 { pointer-events: auto; width: fit-content; max-width: 100%; cursor: pointer; }
      #context h1:focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; border-radius: 6px; }
      .vf-sheet-bar { position: sticky; top: 0; z-index: 2; height: 36px; margin-bottom: calc(-1 * var(--sp-4)); background: var(--menu-solid); }
      .vf-sheet-grip { position: absolute; top: var(--sp-8); left: 50%; width: 36px; height: 5px; transform: translateX(-50%); border-radius: 999px; background: rgba(var(--ink), .25); }
      .vf-sheet-x { position: absolute; top: 0; right: var(--sp-4); width: 44px; height: 36px; border: 0; border-radius: 999px; background: none; color: var(--text-2); display: grid; place-items: center; cursor: pointer; }
      .vf-sheet-x:hover { background: rgba(var(--ink), .08); color: var(--text); }
      .vf-sheet-x:focus-visible { outline: 2px solid var(--ring); outline-offset: -2px; }
      header:has(#btn-up:not([hidden])) .brand { display: none; }
      .vf-tabs { margin-left: var(--sp-6); padding: var(--sp-4); } .vf-tabs a { padding: var(--sp-4) var(--sp-8); font-size: 13px; }
      #btn-panel { display: none !important; }
    }`;
  document.head.appendChild(style);

  const lib = (b) => (b.querySelector('.bl')?.textContent || b.getAttribute('aria-label') || b.getAttribute('title') || '').trim();
  // Q11 (même arbitrage) : le thème dit son état seulement (« Thème : Auto »), pas l'infobulle entière (« … (suit votre appareil). Appuyer pour clair. »)
  const court = (b) => b.id === 'theme-toggle' ? lib(b).split(/[(.]/)[0].trim() : lib(b);
  const pastille = (b) => (b.querySelector('.badge')?.textContent || '').trim();
  const actions = () => [...hr.querySelectorAll('button')].filter((b) => !['vf-lock', 'vf-plus', 'btn-panel'].includes(b.id) && !b.hidden && !b.closest('.menu') && (phone.matches || b.id !== 'vf-git-ouvreur')); // de 701 à 999 px l'ouvreur Git reste dans l'en-tête

  const plus = document.createElement('button');
  plus.id = 'vf-plus'; plus.type = 'button'; plus.className = 'btn icon';
  plus.setAttribute('aria-label', "Plus d'actions"); plus.title = "Plus d'actions"; plus.setAttribute('aria-haspopup', 'menu'); plus.setAttribute('aria-expanded', 'false');
  const NS = 'http://www.w3.org/2000/svg', svg = document.createElementNS(NS, 'svg'); svg.setAttribute('class', 'i'); svg.setAttribute('viewBox', '0 0 24 24');
  for (const cx of [5, 12, 19]) { const c = document.createElementNS(NS, 'circle'); c.setAttribute('cx', cx); c.setAttribute('cy', 12); c.setAttribute('r', 1.6); svg.appendChild(c); }
  plus.appendChild(svg); hr.appendChild(plus);

  // pastille du « ⋯ » (Q8, « Tout selon les recos (Recommandé) », AskUserQuestion session principale, 2026-11-04) : un simple point de présence, jamais une somme ; les comptes restent sur les entrées du menu
  const majPastille = () => {
    const a = actions().some((b) => pastille(b)); let badge = plus.querySelector('.badge');
    const t = a ? "Plus d'actions, des compteurs à lire dans le menu" : "Plus d'actions"; plus.title = t; plus.setAttribute('aria-label', t); // PU-G-012 : la pastille dit ce qu'elle annonce
    if (!a) { badge?.remove(); return; }
    if (!badge) { badge = document.createElement('span'); badge.className = 'badge'; badge.setAttribute('aria-hidden', 'true'); plus.appendChild(badge); }
  };
  new MutationObserver((ms) => { if (ms.some((m) => !plus.contains(m.target))) majPastille(); }).observe(hr, { childList: true, subtree: true, characterData: true });
  majPastille();

  let menu = null, voile = null;
  const fermer = (rendre) => { if (!menu) return; menu.remove(); voile?.remove(); voile = null; menu = null; plus.setAttribute('aria-expanded', 'false'); if (rendre) plus.focus(); };
  const ouvrir = () => {
    fermer(false);
    voile = document.createElement('div'); voile.id = 'vf-plus-voile'; voile.setAttribute('aria-hidden', 'true'); document.body.appendChild(voile);
    menu = document.createElement('div'); menu.id = 'vf-plus-menu'; menu.setAttribute('role', 'menu'); menu.setAttribute('aria-label', "Plus d'actions");
    const lock = document.getElementById('vf-lock'), etat = lock && (lock.getAttribute('aria-label') || lock.title || '').trim(); // PU-G-012 : légende du point « au travail » (« Personne au travail », « 2 au travail »)
    if (etat) { const l = document.createElement('div'); l.className = 'vf-pl-etat'; l.setAttribute('role', 'none'); l.textContent = etat; menu.appendChild(l); }
    for (const src of actions()) {
      const it = document.createElement('button'); it.type = 'button'; it.className = 'vf-pl-i'; it.setAttribute('role', 'menuitem');
      const ic = src.querySelector('svg'); if (ic) { const c = ic.cloneNode(true); c.setAttribute('class', 'i vf-pl-ic'); c.setAttribute('aria-hidden', 'true'); it.appendChild(c); } // PU-G-011 : l'icône du bouton d'origine
      const t = document.createElement('span'); t.className = 'vf-pl-t'; t.textContent = court(src); it.appendChild(t);
      const p = pastille(src); if (p) { const b = document.createElement('span'); b.className = 'badge'; b.textContent = p; it.appendChild(b); }
      // Q13a : une action désactivée l'est aussi dans le menu (aria-disabled, atténuée, même infobulle) ; elle ne fait rien et ne ferme pas le menu
      const off = src.disabled || src.getAttribute('aria-disabled') === 'true';
      if (off) { it.setAttribute('aria-disabled', 'true'); it.classList.add('vf-pl-off'); if (src.title) it.title = src.title; }
      it.onclick = (ev) => { ev.stopPropagation(); if (off) return; fermer(false); src.click(); };
      menu.appendChild(it);
    }
    document.body.appendChild(menu); plus.setAttribute('aria-expanded', 'true'); menu.querySelector('button')?.focus();
  };
  plus.onclick = (ev) => { ev.stopPropagation(); if (menu) fermer(false); else ouvrir(); };
  document.addEventListener('pointerdown', (ev) => { if (menu && !menu.contains(ev.target) && !plus.contains(ev.target)) fermer(false); }, true);
  document.addEventListener('keydown', (ev) => {
    if (!menu) return;
    if (ev.key === 'Escape') { ev.stopPropagation(); ev.preventDefault(); fermer(true); return; }
    if (ev.key !== 'ArrowDown' && ev.key !== 'ArrowUp') return;
    const its = [...menu.querySelectorAll('button')], i = its.indexOf(document.activeElement); ev.preventDefault();
    its[(i + (ev.key === 'ArrowDown' ? 1 : -1) + its.length) % its.length]?.focus();
  }, true);

  // le viewer range le zoom dans l'en-tête sur un téléphone : il retourne dans la scène, après le geste du viewer (même requête, écouteur posé après le sien)
  const scene = () => { if (zoom && stage && phone.matches && zoom.parentNode !== stage) stage.insertBefore(zoom, document.getElementById('flowbar')); };
  phone.addEventListener('change', () => { scene(); }); tablette.addEventListener('change', () => { if (!tablette.matches) fermer(false); }); scene();

  // pile du zoom : la barre de question change de hauteur (invite, avertissement) et la visite guidée se pose au même endroit : on relit leurs hauteurs, le zoom reste au-dessus des deux
  const ask = document.getElementById('ask');
  if (ask) { // la visite (#tour) est créée à la volée : on la relie quand elle entre dans la page
    // la feuille de visite se pose au-dessus de la barre de question OU plus haut (au-dessus de la pastille du terminal, PU-G-090) : le zoom monte jusqu'à son bord HAUT réel, jamais à la hauteur supposée (sinon il la recouvre et elle rétrécit à 120 px)
    const h = () => { const v = document.getElementById('tour'); const bas = v && v.offsetHeight ? Math.max(ask.offsetHeight + 8, parseFloat(getComputedStyle(v).bottom) || 0) + v.offsetHeight + 8 : ask.offsetHeight + 8; document.documentElement.style.setProperty('--vf-ask-h', bas + 'px'); document.documentElement.toggleAttribute('data-vf-visite', !!(v && v.offsetHeight)); };
    let ro = null, vu = null;
    const mv = new MutationObserver(h); // la feuille change de place (style) ou apparaît (hidden) sans changer de taille : le ResizeObserver ne la voit pas
    const lier = () => { const v = document.getElementById('tour'); if (ro && v !== vu) { vu = v; ro.disconnect(); mv.disconnect(); ro.observe(ask); if (v) { ro.observe(v); mv.observe(v, { attributes: true, attributeFilter: ['style', 'hidden'] }); } } h(); };
    if (window.ResizeObserver) ro = new ResizeObserver(h);
    new MutationObserver(lier).observe(document.body, { childList: true }); lier(); window.addEventListener('resize', h);
  }

  // tiroir : #btn-panel (masqué) reste le seul chemin d'ouverture et de fermeture
  const btn = document.getElementById('btn-panel'), panel = document.getElementById('panel'), ctx = document.getElementById('context');
  const ouvert = () => !document.body.classList.contains('no-panel');
  const bascule = (voulu) => { if (btn && ouvert() !== voulu) btn.click(); };
  const barre = () => {
    if (!panel) return;
    const b = panel.querySelector(':scope > .vf-sheet-bar');
    if (!phone.matches) { b?.remove(); return; }
    if (b && panel.firstElementChild === b) return;
    b?.remove();
    const bar = document.createElement('div'); bar.className = 'vf-sheet-bar';
    const g = document.createElement('div'); g.className = 'vf-sheet-grip'; g.setAttribute('aria-hidden', 'true'); bar.appendChild(g);
    const x = document.createElement('button'); x.type = 'button'; x.className = 'vf-sheet-x'; x.setAttribute('aria-label', 'Fermer le détail'); x.title = 'Fermer le détail';
    const xs = document.createElementNS(NS, 'svg'); xs.setAttribute('class', 'i'); xs.setAttribute('viewBox', '0 0 24 24'); xs.setAttribute('aria-hidden', 'true');
    const xp = document.createElementNS(NS, 'path'); xp.setAttribute('d', 'M6 6l12 12M18 6L6 18'); xs.appendChild(xp); x.appendChild(xs);
    x.onclick = (ev) => { ev.stopPropagation(); bascule(false); };
    bar.appendChild(x); panel.insertBefore(bar, panel.firstChild);
  };
  if (panel) { new MutationObserver(barre).observe(panel, { childList: true }); phone.addEventListener('change', barre); barre(); }

  // titre de la vue : cliquable sur téléphone ; ses mots à traits d'union ne se coupent plus au trait d'union (aussi hors téléphone)
  const titre = () => {
    const h1 = ctx?.querySelector('h1'); if (!h1) return;
    if (!h1.dataset.vfNb) {
      h1.dataset.vfNb = '1';
      const tw = document.createTreeWalker(h1, NodeFilter.SHOW_TEXT), noeuds = []; let t; while ((t = tw.nextNode())) noeuds.push(t);
      for (const n of noeuds) {
        if (!/\S-\S/.test(n.data)) continue;
        const f = document.createDocumentFragment();
        for (const part of n.data.split(/(\s+)/)) {
          if (/\S-\S/.test(part)) { const sp = document.createElement('span'); sp.className = 'vf-nb'; sp.textContent = part; f.appendChild(sp); } else if (part) f.appendChild(document.createTextNode(part));
        }
        n.replaceWith(f);
      }
    }
    if (phone.matches) { h1.setAttribute('role', 'button'); h1.tabIndex = 0; } else { h1.removeAttribute('role'); if (!h1.dataset.vfAide) h1.removeAttribute('tabindex'); } // le titre à définition Git reste atteignable par Tab (76-vf-git-entete.js)
  };
  if (ctx) {
    new MutationObserver(titre).observe(ctx, { childList: true }); phone.addEventListener('change', titre); titre();
    ctx.addEventListener('click', (ev) => { if (phone.matches && ev.target.closest('h1')) bascule(true); });
    ctx.addEventListener('keydown', (ev) => { if (phone.matches && ev.target.closest?.('h1') && (ev.key === 'Enter' || ev.key === ' ')) { ev.preventDefault(); bascule(true); } });
  }
  // PU-G-045 (recette du 2026-11-08, arbitrage Samuel, AskUserQuestion session principale, 2026-11-08 : « Les partiels qui te concernaient ») : de 701 à 999 px le panneau est fermé par défaut (à garder), mais le viewer
  // ne l'ouvrait qu'au téléphone : choisir une carte ou un fichier n'y montrait rien. Ici le choix l'ouvre (souris, toucher, clavier), il se referme par son bouton « Détail » ou par Échap, et le focus revient où il était.
  // Pas de role=dialog : un dialogue visible empêcherait l'Échap des tiroirs « Au travail » et Git (leur « surcouche »).
  const mi = window.matchMedia('(min-width: 701px) and (max-width: 999px)'), SCm = window.Floorplan;
  if (btn && panel && SCm && SCm.on) {
    // P1 (revue du 2026-11-08) : la préférence « panneau ouvert » (SC.store, clé panel) est celle du BUREAU, et seul le bouton « Détail » l'écrit ; une ouverture ou une fermeture par sélection ou par Échap n'y touche pas
    // (sinon le rechargement à 768 px ouvrait le panneau d'office, et Échap à 768 px fermait celui du bureau à 1 440 px). Même procédé que 75-vf-modele.js : l'objet store est partagé, on enveloppe son écriture.
    let sansMemoire = false;
    if (SCm.store && SCm.store.set) { const ecrire = SCm.store.set; SCm.store.set = (k, v) => (sansMemoire && k === 'panel' ? undefined : ecrire(k, v)); }
    const sansTrace = (f) => { sansMemoire = true; try { f(); } finally { sansMemoire = false; } };
    // P3 : la règle s'ancre sur le CHOIX, pas sur une fenêtre de temps. Sans geste, seul un CHANGEMENT de sélection ouvre : un rendu de plus sur la même sélection (flux en direct) ne rouvre jamais ce que l'utilisateur vient de refermer, quel que soit le délai.
    // F1 (3e tour) : un geste armé « au pointeur posé » restait armé quand il n'aboutissait à aucune sélection (glisser sur le fond, pan, pincement) et le rendu suivant rouvrait le panneau. Sur la carte, le choix est donc
    // l'évènement en cours au moment de l'émission (window.event) : le clic de la carte, ou l'Entrée / Espace qui la choisit ; un glisser, un pan ou un pincement n'émettent aucun clic, rien ne reste armé.
    // La palette choisit plus tard (le viewer recentre d'abord) : son geste reste armé jusqu'au premier évènement « panel » qui le suit, et seulement lui (jamais le graphe).
    let choixPalette = null, clavier = false, versPanneau = false, precedent = null, retour = null, etaitOuvert = ouvert();
    const sur = (ev) => !!(ev && ev.target && ev.target.closest && ev.target.closest('#svg'));
    const dansPalette = (ev) => !!(ev.target && ev.target.closest && ev.target.closest('#palette'));
    document.addEventListener('pointerdown', (ev) => { clavier = false; choixPalette = dansPalette(ev) && ev.target.closest && ev.target.closest('#results .r') ? { clavier: false } : null; versPanneau = false; }, true);
    document.addEventListener('keydown', (ev) => {
      versPanneau = false;
      if (ev.key !== 'Enter' && ev.key !== ' ') return;
      clavier = sur(ev); choixPalette = dansPalette(ev) && document.querySelector('#results .r.active') ? { clavier: true } : null; // J6 : le geste de la palette n'est armé que s'il CHOISIT un résultat (saisie sans résultat, clic sur le fond ou sur la croix : rien)
    }, true);
    document.addEventListener('keyup', () => { clavier = false; }, true);
    // P2 : au clavier le focus entre dans le panneau. Par la palette (/, saisie, Entrée) le viewer rend ensuite le focus à la carte (reveal, après le recentrage) : tant que le geste du clavier court, un focus qui tombe sur le graphe est ramené au panneau.
    document.addEventListener('focusin', (ev) => {
      if (versPanneau && ev.target.closest && ev.target.closest('#svg')) { versPanneau = false; panel.tabIndex = -1; panel.focus({ preventScroll: true }); }
    }, true);
    SCm.on('panel', (d) => {
      const ev = window.event, sel0 = ev && ev.type === 'click' && sur(ev) ? { clavier } : ev && ev.type === 'keydown' && (ev.key === 'Enter' || ev.key === ' ') && sur(ev) ? { clavier: true } : null;
      const g = choixPalette || sel0; choixPalette = null; // le geste de la palette est consommé par le premier évènement « panel » qui le suit
      const sel = d && d.selected, cle = sel == null ? null : typeof sel === 'string' ? sel : JSON.stringify(sel), change = cle !== precedent;
      precedent = cle;
      if (!cle || !mi.matches || ouvert() || panel.querySelector(':scope > .vf-whop')) return;
      if (!change && !g) return;
      const a = document.activeElement; retour = a && a !== document.body && !panel.contains(a) ? a : null;
      sansTrace(() => bascule(true));
      if (g && g.clavier) { panel.tabIndex = -1; panel.focus({ preventScroll: true }); versPanneau = true; }
    });
    // P4 bis : la règle est symétrique, la dernière surface ouverte l'emporte. Git s'ouvre (touche g, ligne ou ouvreur) pendant que le panneau est ouvert : le panneau se replie, la sélection est gardée, la préférence n'est pas écrite ; il ne se rouvre pas à la fermeture de Git
    window.addEventListener('vf-git:etat', (e) => { if (e.detail && e.detail.ouvert && mi.matches && ouvert() && !panel.querySelector(':scope > .vf-whop')) sansTrace(() => bascule(false)); });
    new MutationObserver(() => {
      const o = ouvert(); if (o === etaitOuvert) return; etaitOuvert = o;
      // P4 et F5 : le tiroir Git (z 7) recouvrirait le panneau (z 5) ; un seul latéral à la fois, comme « Au travail » sous 1 280 px (73-vf-tiroir-travail.js). La règle se tient ICI, sur l'ouverture elle-même,
      // et non dans chaque chemin qui ouvre (sélection, « Détail » au clic ou au clavier, palette) : la dernière surface ouverte l'emporte par tous les chemins.
      if (o) { const git = window.VFGitTiroir; if (mi.matches && git && git.ouvert()) git.fermer(true); return; }
      if (!mi.matches || panel.querySelector(':scope > .vf-whop')) { retour = null; return; }
      const a = document.activeElement;
      if (a === document.body || panel.contains(a)) (retour && document.contains(retour) ? retour : btn).focus({ preventScroll: true });
      retour = null;
    }).observe(document.body, { attributes: true, attributeFilter: ['class'] });
    document.addEventListener('keydown', (ev) => {
      if (ev.key !== 'Escape' || ev.defaultPrevented || !mi.matches || !ouvert() || panel.querySelector(':scope > .vf-whop')) return;
      if (document.querySelector('#palette.open, #flowmenu.open, #legend.open, #ctxmenu:not([hidden])') || (window.FloorplanTour && window.FloorplanTour.active())) return; // une palette, un menu ou la visite prennent l'Échap d'abord
      if (ev.target && /^(INPUT|TEXTAREA|SELECT)$/.test(ev.target.tagName)) return;
      ev.stopPropagation(); ev.preventDefault(); sansTrace(() => bascule(false)); // le viewer n'entend pas cet Échap : il ne remonte pas le canevas ni n'efface la sélection (R15.8)
    });
  }
})();
