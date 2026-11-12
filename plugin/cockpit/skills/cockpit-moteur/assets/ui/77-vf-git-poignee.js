// VibeFlow (80-06) : poignée de largeur du tiroir Git (P80-D-19, P80-D-39, FORM-13) — au clavier et à la souris, bornée, mémorisée par lab.
// Chargée avant le tiroir : elle s'expose (window.VFGitPoignee.monter(tiroir)) et le tiroir l'appelle une fois posé. Aucune écriture hors localStorage.
// La largeur vit dans la variable CSS --vf-git-l posée sur le tiroir ; le tiroir est posé par-dessus la carte, rien ne la recadre (PU-G-204).
(() => {
  const SC = window.Floorplan;
  if (!SC) return;
  const MIN = 280, DEFAUT = 360, PAS = 16, GRAND = 64, MARGE = 312;
  const MOBILE = window.matchMedia('(max-width: 999px), (pointer: coarse)');
  const lab = () => (SC.graph.project && SC.graph.project.name) || (SC.graph.meta && SC.graph.meta.rootName) || 'lab';
  const cle = () => 'vf-git-largeur:' + lab(); // la clé porte le nom du lab : deux labs ne partagent pas leur largeur
  const panneau = () => { // largeur du panneau du moteur quand il est ouvert
    if (document.body.classList.contains('no-panel')) return 0;
    const v = parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--panel-w'));
    return v > 0 ? v : 360;
  };
  const maximum = () => Math.max(MIN, Math.round(window.innerWidth - panneau() - MARGE));
  const borner = (v) => Math.max(MIN, Math.min(maximum(), Math.round(v)));
  const defaut = () => Math.min(DEFAUT, maximum());
  let choisie = null; // largeur voulue (non plafonnée) : elle revient quand la place revient
  const lue = () => { // valeur mémorisée ramenée dans les bornes à chaque lecture ; non numérique : le défaut (T-80-14)
    let v = NaN;
    try { v = Number(window.localStorage.getItem(cle())); } catch (e) { v = NaN; }
    return Number.isFinite(v) && v > 0 ? borner(v) : defaut();
  };

  const style = document.createElement('style');
  style.textContent = `
    .vf-git-poignee { position: absolute; top: 24px; bottom: 24px; right: 2px; width: 12px; z-index: 3; cursor: ew-resize; touch-action: none;
      display: flex; align-items: center; justify-content: center; }
    .vf-git-poignee::before { content: ''; width: 4px; height: 32px; border-radius: 2px; background: var(--text-4); }
    .vf-git-poignee:hover::before, .vf-git-poignee.vf-git-tire::before { width: 6px; background: var(--text-3); }
    .vf-git-poignee:focus-visible { outline: none; }
    .vf-git-poignee:focus-visible::before { width: 6px; background: var(--text-3); box-shadow: 0 0 0 2px var(--ring); }
    @media (max-width: 999px), (pointer: coarse) { .vf-git-poignee { display: none; } }
  `;
  document.head.appendChild(style);

  const monter = (tiroir) => {
    if (!tiroir || tiroir.querySelector('.vf-git-poignee')) return;
    const p = document.createElement('div');
    p.className = 'vf-git-poignee';
    const at = { role: 'separator', 'aria-orientation': 'vertical', tabindex: '0', 'aria-label': "Largeur de l'historique Git" };
    for (const k of Object.keys(at)) p.setAttribute(k, at[k]);
    const poser = (v, memoriser, garder) => { // pose la largeur dans les bornes, met à jour les attributs ; la mémorise quand le geste est fini
      const w = borner(v);
      if (garder !== false) choisie = Math.round(v);
      tiroir.style.setProperty('--vf-git-l', w + 'px');
      p.setAttribute('aria-valuemin', String(MIN)); p.setAttribute('aria-valuemax', String(maximum()));
      p.setAttribute('aria-valuenow', String(w)); p.setAttribute('aria-valuetext', w + ' pixels');
      if (memoriser) { try { window.localStorage.setItem(cle(), String(w)); } catch (e) { void e; } }
      return w;
    };
    const courante = () => Math.round(tiroir.getBoundingClientRect().width) || lue();
    p.addEventListener('keydown', (e) => {
      if (e.ctrlKey || e.altKey || e.metaKey) return;
      const pas = e.shiftKey ? GRAND : PAS, w = courante();
      const v = { ArrowLeft: w - pas, ArrowRight: w + pas, Home: MIN, End: maximum(), Enter: defaut() }[e.key];
      if (v === undefined) return;
      e.preventDefault(); e.stopPropagation(); poser(v, true);
    });
    p.addEventListener('dblclick', () => poser(defaut(), true));
    p.addEventListener('pointerdown', (e) => {
      if (e.button !== 0 || MOBILE.matches) return;
      e.preventDefault(); p.setPointerCapture(e.pointerId); p.classList.add('vf-git-tire'); p.focus({ preventScroll: true });
      const gauche = tiroir.getBoundingClientRect().left;
      const bouge = (ev) => poser(ev.clientX - gauche, false);
      const fin = () => {
        p.classList.remove('vf-git-tire');
        for (const [n, f] of [['pointermove', bouge], ['pointerup', fin], ['pointercancel', fin]]) p.removeEventListener(n, f);
        poser(courante(), true);
      };
      for (const [n, f] of [['pointermove', bouge], ['pointerup', fin], ['pointercancel', fin]]) p.addEventListener(n, f);
    });
    tiroir.appendChild(p);
    poser(lue(), false);
    const relire = () => poser(choisie == null ? lue() : choisie, false, false); // bornes à jour, choix gardé : il revient avec la place
    for (const ev of ['resize', 'vf-git:etat']) window.addEventListener(ev, relire);
  };
  window.VFGitPoignee = Object.freeze({ monter, lue, maximum });
})();
