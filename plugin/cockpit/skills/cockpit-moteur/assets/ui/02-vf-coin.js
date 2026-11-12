// VibeFlow (80-05) : le coin bas-droit (FORM-10, P80-D-16, P80-D-18). Un bloc #vf-coin dans #stage : une minicarte (cartes, cadre du champ, hachure de la part
// du cadre sous le tiroir Git ouvert) au-dessus de la ligne d'état (02-vf-ligne-etat.js remplit #vf-coin-etat). Il se pose par-dessus la carte
// sans la pousser ni changer freeArea() ; il monte avec #stage quand le tiroir du terminal s'ouvre. Seule la transformation de #viewport
// le fait redessiner : aucune animation.
// Expose window.VF_COIN = { rectangle() } : le rectangle écran du bloc (DOMRect), null s'il n'est pas affiché. Lit window.VF_CANEVAS à l'exécution.
(() => {
  const SC = window.Floorplan;
  if (!SC) return;
  const { graph: G, state } = SC;
  const svg = document.getElementById('svg'), stage = document.getElementById('stage'), vp = document.getElementById('viewport');
  if (!svg || !stage || !vp) return;
  const equipe = () => !!G.meta && G.meta.vfTab === 'equipe';
  const style = document.createElement('style');
  style.textContent = `
    #vf-coin { position: absolute; z-index: 3; right: calc(var(--pw) + var(--edge)); bottom: var(--vf-coin-bas, var(--edge)); width: 176px;
      padding: var(--sp-8); border-radius: var(--r-ctl); transition: right .45s var(--ease); }
    #vf-coin[hidden], .vf-mini[hidden] { display: none; }
    .vf-mini { display: block; width: 144px; height: 96px; border-radius: 8px; background: rgba(var(--ink), .06); }
    .vf-mini .vf-mc rect:not(.vf-mf) { fill: var(--text-4); } .vf-mini .vf-mc rect.sel { fill: var(--text); }
    .vf-mini .vf-mf { fill: none; stroke: var(--text-2); stroke-width: 1.5; vector-effect: non-scaling-stroke; }
    .vf-mini .vf-mh line { stroke: var(--text-3); stroke-width: 1; }
    .vf-coin-etat:not(:empty) { margin-top: var(--sp-8); padding-top: var(--sp-8); border-top: 1px solid var(--hair); }
    .vf-mini[hidden] + .vf-coin-etat { margin-top: 0; padding-top: 0; border-top: 0; }
    @media (max-width: 999px) { #vf-coin { display: none; } } /* feuille de détail : aucun bloc, les repères seuls */
    @media (pointer: coarse) { .vf-mini { display: none; } } /* au doigt : la ligne d'état seule */
    @media (max-width: 700px) { /* téléphone (AUDC-X8) : onglet visuel de 36, piste de 44, zone d'appui de 44 par un pseudo-élément */
      header .vf-tabs { padding: var(--sp-4); }
      header .vf-tabs a { position: relative; display: inline-flex; align-items: center; box-sizing: border-box; min-height: 36px; padding: 0 var(--sp-8); }
      header .vf-tabs a::after { content: ""; position: absolute; inset: -4px 0; }
    }
  `;
  document.head.appendChild(style);

  const NS = 'http://www.w3.org/2000/svg', C = () => window.VF_CANEVAS;
  const el = (t, a) => { const e = document.createElementNS(NS, t); for (const k in a) e.setAttribute(k, a[k]); return e; };
  const coin = document.createElement('div'); coin.id = 'vf-coin'; coin.className = 'glass'; coin.hidden = true;
  const mini = el('svg', { id: 'vf-minicarte', class: 'vf-mini', role: 'img', width: 144, height: 96, viewBox: '0 0 144 96' });
  const hach = el('pattern', { id: 'vf-hachure', width: 4, height: 4, patternUnits: 'userSpaceOnUse', patternTransform: 'rotate(45)' });
  const groupe = el('g', { class: 'vf-mc' }), cadre = el('rect', { class: 'vf-mf', rx: 2 }), hachure = el('rect', { fill: 'url(#vf-hachure)' });
  const trait = el('g', { class: 'vf-mh' }); trait.appendChild(el('line', { x1: 0, y1: 0, x2: 0, y2: 4 })); hach.appendChild(trait);
  mini.append(el('defs', {}), groupe, hachure); mini.firstChild.appendChild(hach); groupe.appendChild(cadre); hachure.style.display = 'none';
  const etat = document.createElement('div'); etat.id = 'vf-coin-etat'; etat.className = 'vf-coin-etat';
  coin.append(mini, etat);

  let rects = new Map(), faite = null, gel = null, vivant = false; // gel : la mise à l'échelle, figée pendant un glissement
  const fenetre = () => { const a = SC.freeArea(), { k, x, y } = state.t; return { l: (a.x - x) / k, t: (a.y - y) / k, w: a.w / k, h: a.h / k }; };
  const echelle = () => { // le rapport de la carte entière tient dans la surface (marge de 4) : cartes et cadre du champ
    const f = fenetre(); let x0 = f.l, y0 = f.t, x1 = f.l + f.w, y1 = f.t + f.h;
    for (const c of state.layout.children) {
      x0 = Math.min(x0, c.x); y0 = Math.min(y0, c.y); x1 = Math.max(x1, c.x + c.width); y1 = Math.max(y1, c.y + c.height);
    }
    const s = Math.min(136 / (x1 - x0), 88 / (y1 - y0));
    return { s, ox: 72 - ((x0 + x1) / 2) * s, oy: 48 - ((y0 + y1) / 2) * s, f };
  };
  const reconstruire = () => { // les rectangles ne changent qu'avec le niveau (render) ; la transformation du groupe suffit au reste
    for (const r of rects.values()) r.remove();
    rects = new Map(); faite = state.layout;
    for (const c of state.layout.children) {
      const r = el('rect', { x: c.x, y: c.y, width: c.width, height: c.height, rx: 8 }); rects.set(c.id, r); groupe.insertBefore(r, cadre);
    }
    marquer();
  };
  const marquer = () => { for (const [id, r] of rects) r.classList.toggle('sel', id === state.selected); };
  const dessiner = () => {
    if (!vivant || mini.hasAttribute('hidden') || !state.layout) return;
    if (faite !== state.layout) reconstruire();
    const m = gel || echelle(), f = fenetre(), a = SC.freeArea(), { k, x, y } = state.t;
    groupe.setAttribute('transform', `translate(${m.ox} ${m.oy}) scale(${m.s})`);
    for (const [n, v] of [['x', f.l], ['y', f.t], ['width', f.w], ['height', f.h]]) cadre.setAttribute(n, v);
    const t = document.getElementById('vf-git-tiroir'), r = t && !t.hidden && t.offsetWidth ? t.getBoundingClientRect() : null;
    const x0 = r ? Math.max(a.x, r.left) : 0, x1 = r ? Math.min(a.x + a.w, r.right) : 0;
    const y0 = r ? Math.max(a.y, r.top) : 0, y1 = r ? Math.min(a.y + a.h, r.bottom) : 0;
    const dessous = !!r && x1 > x0 && y1 > y0;
    hachure.style.display = dessous ? '' : 'none';
    if (dessous) { // la part du cadre sous le tiroir Git, en pixels de minicarte
      const px = (sx) => ((sx - x) / k) * m.s + m.ox, py = (sy) => ((sy - y) / k) * m.s + m.oy;
      for (const [n, v] of [['x', px(x0)], ['y', py(y0)], ['width', px(x1) - px(x0)], ['height', py(y1) - py(y0)]]) hachure.setAttribute(n, v);
    }
    const lec = C() ? C().champDeLecture() : a, n = state.layout.children.length;
    const vis = state.layout.children.filter((c) => c.x * k + x < lec.x + lec.w && (c.x + c.width) * k + x > lec.x
      && c.y * k + y < lec.y + lec.h && (c.y + c.height) * k + y > lec.y).length;
    const s = vis > 1 ? 's' : '', git = dessous ? " ; une partie du champ est sous l'historique Git" : '';
    mini.setAttribute('aria-label', `Minicarte : ${vis} carte${s} visible${s} sur ${n}${git}`);
  };
  const bloc = () => { // place, présence de la minicarte, mode compact ; la hauteur de #ask est relue à chaque changement
    const ask = document.getElementById('ask'), h = ask && ask.offsetHeight ? ask.offsetHeight : 0;
    coin.style.setProperty('--vf-coin-bas', h ? `calc(${h}px + var(--edge) + var(--sp-8))` : 'var(--edge)');
    const utile = stage.clientHeight - (h ? h + 24 : 16), souris = matchMedia('(min-width: 1000px) and (pointer: fine)').matches;
    mini.toggleAttribute('hidden', !(!equipe() && svg.getClientRects().length && state.layout && state.layout.children.length && souris && utile >= 360));
    coin.toggleAttribute('data-compact', utile < 480);
    coin.hidden = mini.hasAttribute('hidden') && (etat.hidden || !etat.childElementCount);
    dessiner();
  };
  const recentrer = (ev, m) => { // centre le cadre du champ sur le point touché ; le zoom ne change jamais
    const S = C(), r = mini.getBoundingClientRect(); if (!S) return;
    const wx = (ev.clientX - r.left - m.ox) / m.s, wy = (ev.clientY - r.top - m.oy) / m.s, a = SC.freeArea(), { k, x, y } = state.t;
    S.deplacer({ x: a.x + a.w / 2 - (wx * k + x), y: a.y + a.h / 2 - (wy * k + y) });
  };

  const pose = [];
  const init = () => {
    vivant = true; stage.appendChild(coin);
    const sur = (cible, type, fn, o) => { cible.addEventListener(type, fn, o); pose.push(() => cible.removeEventListener(type, fn, o)); };
    const observer = (O, cible, opts, fn) => { const o = new O(fn); o.observe(cible, opts); pose.push(() => o.disconnect()); };
    observer(MutationObserver, vp, { attributes: true, attributeFilter: ['style'] }, dessiner);
    observer(MutationObserver, document.body, { attributes: true, attributeFilter: ['class'] }, bloc);
    observer(MutationObserver, etat, { childList: true, attributes: true, attributeFilter: ['hidden'] }, bloc);
    if (window.ResizeObserver) {
      for (const q of ['#ask', '#context']) { const e = document.querySelector(q); if (e) observer(ResizeObserver, e, undefined, bloc); }
    }
    sur(window, 'resize', bloc); sur(window, 'vf-git:etat', bloc);
    for (const e of ['transitionend', 'animationend']) { // le tiroir Git entre par une animation, le panneau et la barre par des transitions
      sur(document, e, (ev) => { if (ev.target.closest && ev.target.closest('#vf-git-tiroir, #panel, #ask')) bloc(); });
    }
    sur(mini, 'pointerdown', (ev) => {
      if (ev.button || !state.layout) return;
      ev.preventDefault(); gel = echelle(); mini.setPointerCapture(ev.pointerId); recentrer(ev, gel);
    });
    sur(mini, 'pointermove', (ev) => { if (gel && mini.hasPointerCapture(ev.pointerId)) recentrer(ev, gel); });
    for (const t of ['pointerup', 'pointercancel']) sur(mini, t, () => { gel = null; dessiner(); });
    SC.on('render', bloc); SC.on('panel', () => { marquer(); dessiner(); });
    bloc();
    return () => { vivant = false; pose.splice(0).forEach((f) => f()); coin.remove(); };
  };
  window.VF_COIN = Object.freeze({ rectangle: () => (coin.isConnected && coin.getClientRects().length ? coin.getBoundingClientRect() : null) });
  const K = window.VF_COQUILLE;
  const demarrer = () => (vivant ? undefined : init());
  if (K && typeof K.surOnglet === 'function') K.surOnglet(init); // P80-D-42 : la coquille, sinon `ready` (ou le premier rendu, s'il l'a devancé)
  else if (state.layout) demarrer(); else { SC.on('ready', demarrer); SC.on('render', demarrer); }
})();
