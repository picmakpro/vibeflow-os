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
    #theme-toggle { position: relative; flex: none; width: 44px; height: 44px; padding: 0; background: none; }
    #theme-toggle::before { content: ""; position: absolute; inset: 4px; border-radius: 999px; transition: background .2s var(--ease); }
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

  const show = () => {
    const c = T.get();
    btn.querySelector('svg').innerHTML = ICON[c];
    const text = `Theme: ${NAME[c]}. Press for ${WORD[NEXT[c]]}.`;
    btn.title = text;
    btn.setAttribute('aria-label', text);
  };
  // Enter and Space press this button; they must not also run the page's own "open the selected box" key
  btn.addEventListener('keydown', (ev) => { if (ev.key === 'Enter' || ev.key === ' ') ev.stopPropagation(); });
  window.addEventListener('floorplan-theme-change', show);
  show();
})();
