// The Theme button: Auto (follows your device) -> Light -> Dark -> Auto. The choice is remembered on this
// device. The theme itself is picked by a tiny script at the top of viewer.html, before anything is drawn,
// so the page never flashes the wrong colours; this file only adds the button and keeps it in step.
(() => {
  const SC = window.Floorplan;
  const T = window.floorplanTheme;
  if (!SC || !T) return;

  const ICON = {
    auto: '<circle cx="12" cy="12" r="8"/><path d="M12 4a8 8 0 0 1 0 16z" fill="currentColor"/>',
    light: '<circle cx="12" cy="12" r="4"/><path d="M12 3v2M12 19v2M3 12h2M19 12h2M5.6 5.6 7 7M17 17l1.4 1.4M5.6 18.4 7 17M17 7l1.4-1.4"/>',
    dark: '<path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"/>',
  };
  const NAME = { auto: 'Auto (follows your device)', light: 'Light', dark: 'Dark' };
  const WORD = { auto: 'Auto', light: 'Light', dark: 'Dark' };
  const NEXT = { auto: 'light', light: 'dark', dark: 'auto' };

  const style = document.createElement('style');
  style.textContent = `
    /* a 44 px target; the round hover shape stays 36 px like the buttons beside it */
    #theme-toggle { position: relative; flex: none; width: auto; min-width: 44px; height: 44px; padding: 0 var(--sp-12) 0 var(--sp-12); gap: var(--sp-6); background: none; }
    .theme-word { position: relative; font-size: 12px; color: var(--text-2); white-space: nowrap; }
    #theme-toggle::before { content: ""; position: absolute; inset: var(--sp-4) var(--sp-4); border-radius: 999px; transition: background .2s var(--ease); }
    #theme-toggle:hover { background: none; }
    #theme-toggle:hover::before { background: rgba(var(--ink), .07); }
    #theme-toggle svg { position: relative; width: 18px; height: 18px; }
    #theme-toggle:focus-visible { outline: 2px solid var(--ring); outline-offset: -3px; }
    .theme-status { position: fixed; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }
    @media (prefers-reduced-motion: reduce) { #theme-toggle, #theme-toggle::before { transition: none; } #theme-toggle:active { transform: none; } }`;
  document.head.appendChild(style);

  // read out by screen readers when the theme changes
  const status = document.createElement('span');
  status.className = 'theme-status';
  status.setAttribute('role', 'status');
  document.body.appendChild(status);

  const btn = SC.addHeaderButton({ id: 'theme-toggle', svg: ICON.auto, onClick: () => {
    const next = NEXT[T.get()];
    T.set(next);
    status.textContent = `Theme is now ${next === 'auto' ? 'Auto, following your device' : WORD[next]}.`;
  } });

  const word = document.createElement('span');
  word.className = 'theme-word';
  btn.appendChild(word);

  // Le mot n'est montré que si l'en-tête a la place : il ne doit ni rogner l'en-tête ni rétrécir la recherche (sinon l'icône seule ; l'état reste dit par title et aria-label).
  const fit = () => {
    const h = document.querySelector('header'), cr = document.getElementById('crumbs'); if (!h) return;
    const larges = () => ['.hl', '.hc', '#crumbs'].map((q) => { const e = document.querySelector(q); return e ? e.getBoundingClientRect().width : 0; });
    word.style.display = ''; const avec = larges(), deborde = h.scrollWidth > h.clientWidth || (cr && cr.scrollWidth > cr.clientWidth + 1) || btn.scrollWidth > btn.clientWidth; // le bouton lui-même ne doit pas rogner son mot (de 1 000 à 1 279 px, `header #theme-toggle` le ramène à 36 px : P78-D-34)
    word.style.display = 'none'; const sans = larges();
    word.style.display = !deborde && avec.every((w, i) => w >= sans[i] - 0.5) ? '' : 'none';
  };
  let attente = 0; const refit = () => { if (!attente) attente = requestAnimationFrame(() => { attente = 0; fit(); }); };

  const show = () => {
    const c = T.get();
    btn.querySelector('svg').innerHTML = ICON[c];
    word.textContent = WORD[c]; // l'état courant en texte, à côté de l'icône, quand l'en-tête a la place (PU-G-009)
    refit();
    const text = `Theme: ${NAME[c]}. Press for ${WORD[NEXT[c]]}.`;
    btn.title = text;
    btn.setAttribute('aria-label', text);
  };
  // Enter and Space press this button; they must not also run the page's own "open the selected box" key
  btn.addEventListener('keydown', (ev) => { if (ev.key === 'Enter' || ev.key === ' ') ev.stopPropagation(); });
  window.addEventListener('floorplan-theme-change', show);
  show();
  window.addEventListener('resize', fit);
  const hd = document.querySelector('header'); // le contenu de l'en-tête arrive après le thème (branche Git, badges, libellés traduits) : on revoit la place à chaque changement
  if (hd) { new MutationObserver(fit).observe(hd, { childList: true, subtree: true, characterData: true, attributes: true, attributeFilter: ['class', 'hidden'] }); const ro = new ResizeObserver(refit); for (const e of hd.querySelectorAll('.hl, .hc, .hr, #hdr-ext')) ro.observe(e); }
  refit();
})();
