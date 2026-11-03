// vf-cockpit-terminal-vue — vue du terminal dans la page de Q : thème xterm, cartes d'état, bandeau (71-05 pour l'amorce, 71-06 pour le contenu).
// Export : vueTerminal(cfg) -> rien ; pose window.vfTermVue = { theme(clair), carte(type, action), bandeau(type, detail, action), effacer() }.
// cfg = { origineP, theme }. Sérialisé par .toString() dans un <script> sans attribut, donc autonome : aucune référence à un identifiant du module.
// Textes de l'UI-SPEC §12, posés par textContent ; le seul nombre rendu (code ou signal) est converti en entier. Aucun innerHTML.
export function vueTerminal(cfg) {
  void cfg;
  const NS = 'http://www.w3.org/2000/svg';
  const el = (tag, cls, txt) => { const e = document.createElement(tag); if (cls) e.className = cls; if (txt !== undefined) e.textContent = txt; return e; };
  const picto = (d) => {
    const s = document.createElementNS(NS, 'svg'); s.setAttribute('class', 'i'); s.setAttribute('viewBox', '0 0 16 16'); s.setAttribute('aria-hidden', 'true');
    const p = document.createElementNS(NS, 'path'); p.setAttribute('d', d); s.appendChild(p); return s;
  };
  const bouton = (texte, action) => { const b = el('button', 'vf-q-bouton', texte); b.type = 'button'; b.addEventListener('click', () => action && action()); return b; };
  const zone = () => document.getElementById('etat');
  const vider = () => { const z = zone(); while (z.firstChild) z.removeChild(z.firstChild); return z; };
  const COMMANDE = '/vf-cockpit --terminal';
  const CARTES = {
    refuse: { role: 'status', titre: 'Terminal déjà ouvert', corps: ['Un terminal est déjà ouvert dans un autre onglet. Fermez-le, puis réessayez.'], bouton: 'Réessayer', d: 'M3 3h10v10H3z M6 8h4' },
    expire: { role: 'alert', titre: 'Session expirée', corps: ['Relancez ', COMMANDE, '.'], d: 'M8 2a6 6 0 1 0 0 12A6 6 0 0 0 8 2z M8 5v3.5l2 1.5' },
    arrete: { role: 'alert', titre: 'Serveur arrêté', corps: ['Le cockpit est arrêté. Relancez ', COMMANDE, '.'], d: 'M8 2v6 M4.5 4.5a5 5 0 1 0 7 0' },
  };
  const TEXTES = { fermee: 'La session a été fermée.', reconnexion: 'Reconnexion…' };
  const entier = (v) => String(Math.trunc(Number(v)) || 0);
  const SOMBRE = {
    background: '#191919', foreground: '#ececec', cursor: '#ececec', cursorAccent: '#0f0f0f', selectionBackground: 'rgba(255,255,255,.12)', selectionInactiveBackground: 'rgba(255,255,255,.07)',
    black: '#2b2b2b', red: '#f28b8b', green: '#4ade80', yellow: '#f0c36b', blue: '#7aa7ff', magenta: '#b49cff', cyan: '#63d2b8', white: '#b4b4b4',
    brightBlack: '#8b8b8b', brightRed: '#f6a5a5', brightGreen: '#86efac', brightYellow: '#f3d79b', brightBlue: '#9dbcff', brightMagenta: '#c7b8ff', brightCyan: '#86e3cd', brightWhite: '#ececec',
    scrollbarSliderBackground: 'rgba(255,255,255,.10)', scrollbarSliderHoverBackground: 'rgba(255,255,255,.18)', scrollbarSliderActiveBackground: 'rgba(255,255,255,.28)',
  };
  const CLAIR = {
    background: '#ffffff', foreground: '#161616', cursor: '#161616', cursorAccent: '#ffffff', selectionBackground: 'rgba(0,0,0,.08)', selectionInactiveBackground: 'rgba(0,0,0,.05)',
    black: '#161616', red: '#c94a4a', green: '#157a3a', yellow: '#946000', blue: '#1f5fd6', magenta: '#6a45d6', cyan: '#0b7f6b', white: '#3f3f3f',
    brightBlack: '#595959', brightRed: '#b42323', brightGreen: '#14603f', brightYellow: '#6b4500', brightBlue: '#1747a8', brightMagenta: '#5233b8', brightCyan: '#0a6a5a', brightWhite: '#161616',
    scrollbarSliderBackground: 'rgba(0,0,0,.10)', scrollbarSliderHoverBackground: 'rgba(0,0,0,.20)', scrollbarSliderActiveBackground: 'rgba(0,0,0,.30)',
  };
  window.vfTermVue = {
    theme: (clair) => Object.assign({}, clair ? CLAIR : SOMBRE),
    carte(type, action) {
      const c = CARTES[type]; if (!c) return;
      const z = vider(); z.hidden = false;
      z.appendChild(el('div', 'vf-q-voile'));
      const k = el('div', 'vf-q-carte'); k.setAttribute('role', c.role); k.tabIndex = -1;
      k.appendChild(picto(c.d)); k.appendChild(el('h1', 'vf-q-titre', c.titre));
      const corps = el('p', 'vf-q-corps'); for (const t of c.corps) corps.appendChild(t === COMMANDE ? el('span', 'vf-q-commande', t) : document.createTextNode(t)); k.appendChild(corps);
      const b = c.bouton ? bouton(c.bouton, action) : null; if (b) k.appendChild(b);
      z.appendChild(k); (b || k).focus();
    },
    bandeau(type, detail, action) {
      const z = vider(); z.hidden = false;
      let texte = TEXTES[type]; const d = detail || {};
      if (type === 'termine') texte = d.signal != null ? `Le shell a été interrompu (signal ${entier(d.signal)}).` : `Le shell s'est terminé (code ${entier(d.code)}).`;
      if (!texte) return;
      const b = el('div', 'vf-q-bandeau'); b.setAttribute('role', 'status');
      b.appendChild(el('span', 'vf-q-pastille' + (type === 'reconnexion' ? ' vf-q-attention' : '')));
      b.appendChild(el('span', 'vf-q-texte', texte));
      const r = type === 'reconnexion' ? null : bouton('Relancer le shell', action); if (r) b.appendChild(r);
      z.appendChild(b); if (r) r.focus();
    },
    effacer() { const z = vider(); z.hidden = true; },
  };
}
