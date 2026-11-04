// VibeFlow (70-04, P70-D-01 : arbitrage Samuel, AskUserQuestion session principale, 2026-11-03) : le téléphone (≤ 700 px). L'en-tête tient sur UNE rangée : logo, onglets, recherche, point « au travail »
// et un bouton « ⋯ ». Les autres actions d'en-tête (thème, Santé, Travail récent, Écrans, Visite, Exporter, Parcours, Types de liens, et toute action ajoutée plus tard) vivent dans le menu du « ⋯ »,
// avec un libellé visible ; leurs pastilles de compte sont reportées sur l'entrée et sur le « ⋯ ». Chaque entrée appelle .click() du bouton d'origine (son comportement, ses gardes, ses menus) ;
// le libellé est relu à l'ouverture (déjà traduit par 80-vf-fr.js). Au-dessus de 700 px, rien n'est posé. Hors de l'en-tête : le zoom retourne dans la scène (sa forme finale : 70-05) et le bouton
// Détail est masqué (le tiroir s'ouvre au tap d'une carte). Texte posé par createElement/textContent seulement ; couleurs : variables du thème.
(() => {
  const hr = document.querySelector('header .hr'), stage = document.getElementById('stage'), zoom = document.getElementById('zoom');
  if (!hr) return;
  const phone = matchMedia('(max-width: 700px)');
  const style = document.createElement('style');
  style.textContent = `
    #vf-plus { display: none; }
    #vf-plus-menu { display: none; }
    @media (max-width: 700px) {
      header { display: flex; flex-wrap: nowrap; align-items: center; }
      header .hl { flex: 1 1 auto; min-width: 0; }
      header .hc { flex: 0 0 44px; }
      header .hr { flex: 0 0 auto; justify-content: flex-end; }
      header #proj-name { display: none; }
      #stage > #zoom { left: 16px; right: auto; top: auto; bottom: 124px; } /* provisoire : hors du titre et de la barre de question ; la pile finale vient en 70-05 */
      header:has(#btn-up:not([hidden])) .brand { display: none; }
      .vf-tabs { margin-left: 6px; padding: 3px; } .vf-tabs a { padding: 5px 8px; font-size: 13px; }
      #hdr-ext > button:not(#vf-lock), #theme-toggle, #btn-health, #flows-btn, #filters-btn, #btn-panel { display: none !important; }
      #vf-plus { display: inline-flex; position: relative; }
      #vf-plus .badge, .vf-pl-i .badge { min-width: 16px; height: 16px; border-radius: 999px; background: var(--on); color: var(--on-text); font-size: 10px; font-weight: 600; display: grid; place-items: center; padding: 0 4px; }
      #vf-plus .badge { position: absolute; top: 4px; right: 2px; }
      #vf-plus-menu { display: block; position: fixed; z-index: 40; top: calc(var(--hh, 56px) + 4px); left: 8px; right: 8px; max-height: 60vh; overflow: auto; padding: 6px; border-radius: 18px; background: var(--menu-solid); box-shadow: var(--shadow-float); }
      .vf-pl-i { display: flex; align-items: center; gap: 10px; width: 100%; min-height: 44px; padding: 0 12px; border: 0; border-radius: 12px; background: none; color: var(--text); font: inherit; font-size: 14px; text-align: left; cursor: pointer; }
      .vf-pl-i:hover { background: rgba(var(--ink), .07); }
      .vf-pl-i:focus-visible { outline: 2px solid var(--ring); outline-offset: -2px; }
      .vf-pl-i .vf-pl-t { flex: 1; min-width: 0; }
    }`;
  document.head.appendChild(style);

  const lib = (b) => (b.querySelector('.bl')?.textContent || b.getAttribute('aria-label') || b.getAttribute('title') || '').trim();
  const pastille = (b) => (b.querySelector('.badge')?.textContent || '').trim();
  const actions = () => [...hr.querySelectorAll('button')].filter((b) => !['vf-lock', 'vf-plus', 'btn-panel'].includes(b.id) && !b.hidden && !b.closest('.menu'));

  const plus = document.createElement('button');
  plus.id = 'vf-plus'; plus.type = 'button'; plus.className = 'btn icon';
  plus.setAttribute('aria-label', "Plus d'actions"); plus.title = "Plus d'actions"; plus.setAttribute('aria-haspopup', 'menu'); plus.setAttribute('aria-expanded', 'false');
  const NS = 'http://www.w3.org/2000/svg', svg = document.createElementNS(NS, 'svg'); svg.setAttribute('class', 'i'); svg.setAttribute('viewBox', '0 0 24 24');
  for (const cx of [5, 12, 19]) { const c = document.createElementNS(NS, 'circle'); c.setAttribute('cx', cx); c.setAttribute('cy', 12); c.setAttribute('r', 1.6); svg.appendChild(c); }
  plus.appendChild(svg); hr.appendChild(plus);

  // pastille du « ⋯ » : la somme des pastilles numériques des actions, « • » si l'une n'est pas un nombre ; absente sans pastille
  const majPastille = () => {
    const ps = actions().map(pastille).filter(Boolean); let badge = plus.querySelector('.badge');
    const v = !ps.length ? '' : ps.every((p) => /^\d+$/.test(p)) ? String(ps.reduce((s, p) => s + Number(p), 0)) : '•';
    if (!v) { badge?.remove(); return; }
    if (!badge) { badge = document.createElement('span'); badge.className = 'badge'; plus.appendChild(badge); }
    if (badge.textContent !== v) badge.textContent = v;
  };
  new MutationObserver((ms) => { if (ms.some((m) => !plus.contains(m.target))) majPastille(); }).observe(hr, { childList: true, subtree: true, characterData: true });
  majPastille();

  let menu = null;
  const fermer = (rendre) => { if (!menu) return; menu.remove(); menu = null; plus.setAttribute('aria-expanded', 'false'); if (rendre) plus.focus(); };
  const ouvrir = () => {
    fermer(false);
    menu = document.createElement('div'); menu.id = 'vf-plus-menu'; menu.setAttribute('role', 'menu'); menu.setAttribute('aria-label', "Plus d'actions");
    for (const src of actions()) {
      const it = document.createElement('button'); it.type = 'button'; it.className = 'vf-pl-i'; it.setAttribute('role', 'menuitem');
      const t = document.createElement('span'); t.className = 'vf-pl-t'; t.textContent = lib(src); it.appendChild(t);
      const p = pastille(src); if (p) { const b = document.createElement('span'); b.className = 'badge'; b.textContent = p; it.appendChild(b); }
      it.onclick = (ev) => { ev.stopPropagation(); fermer(false); src.click(); };
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
  phone.addEventListener('change', () => { if (!phone.matches) fermer(false); scene(); }); scene();
})();
