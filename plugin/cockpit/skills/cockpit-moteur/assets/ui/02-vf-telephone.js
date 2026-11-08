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
      #stage > #zoom { left: var(--sp-8); right: auto; top: auto; bottom: calc(var(--vf-ask-h, var(--sp-8)) + var(--sp-8)); flex-direction: column; border-radius: 26px; } /* --vf-ask-h : hauteur relue de la barre de question + sa marge */
      html[data-vf-visite] #stage > #zoom { bottom: calc(var(--vf-ask-h, var(--sp-8)) + var(--sp-8)) !important; } /* visite ouverte : le zoom reste au-dessus de la feuille, même quand le terminal l'a remonté au-dessus de sa pastille (style en ligne, vf-cockpit-terminal-tiroir.mjs) */
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
    if (phone.matches) { h1.setAttribute('role', 'button'); h1.tabIndex = 0; } else { h1.removeAttribute('role'); h1.removeAttribute('tabindex'); }
  };
  if (ctx) {
    new MutationObserver(titre).observe(ctx, { childList: true }); phone.addEventListener('change', titre); titre();
    ctx.addEventListener('click', (ev) => { if (phone.matches && ev.target.closest('h1')) bascule(true); });
    ctx.addEventListener('keydown', (ev) => { if (phone.matches && ev.target.closest?.('h1') && (ev.key === 'Enter' || ev.key === ' ')) { ev.preventDefault(); bascule(true); } });
  }
})();
