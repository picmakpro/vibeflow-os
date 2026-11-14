// VibeFlow (80-16, P80-D-58 a, P80-D-59 d) : le pont entre les onglets Code et Projet, sorti de 00-vibeflow.js pour lui rendre de la place sous le plafond
// de 299 lignes. Un plan renvoie aux fichiers qu'il touche (onglet Projet), un fichier de code renvoie aux plans qui l'ont touché (onglet Code).
// Extension d'onglet : réexécutée avec le moteur à chaque arrivée. Ses accroches : deux sections de panneau et l'accroche `render` de la zone du titre,
// posées à l'évaluation ; l'écouteur `resize` et l'observateur de taille de la zone vivent dans le rappel de surOnglet (A51, P80-D-59) et sont retirés
// avec lui. Ne parle au viewer que par window.Floorplan.
// 80-20 (P80-D-52, FORM-18 ; arbitrage Samuel, AskUserQuestion session principale, 2026-11-11, « Zone réservée (Recommandé) ») : le bloc de titre #context a
// une zone à lui, de la hauteur que freeArea() déduit déjà (min(130, hauteur du bloc)). Elle est retirée du dessin du canevas par une découpe de #svg : aucune
// carte n'y est dessinée ni atteignable au pointeur, après un pan comme après un zoom. Le flou (#context::before) et le texte sont gardés, la mise en page
// et `fit` ne changent pas. Couloirs et liste (#context masqué) : aucune découpe.
(() => {
  const SC = window.Floorplan;
  if (!SC) return;
  const { h, graph: G } = SC;
  const TAB = G.meta.vfTab === 'project' ? 'project' : G.meta.vfTab === 'equipe' ? 'equipe' : 'code';
  const ST = { done: 'Fait', active: 'En cours', recette: 'À recetter', todo: 'À faire', blocked: 'Bloqué' };
  const fileOf = (id) => id && id.startsWith('f:') ? SC.files.get?.(id.slice(2)) || (G.files || []).find((f) => 'f:' + f.p === id) : null;
  if (TAB === 'project') {
    SC.addPanelSection('item', (id) => {
      const f = fileOf(id);
      if (!f || !f.touched || !f.touched.length) return '';
      const rows = f.touched.slice(0, 40)
        .map((p) => `<a class="vf-link" href="index.html#r=${encodeURIComponent(p)}"><span>→</span><code>${h(p)}</code></a>`).join('');
      return `<div class="sec"><h3>Fichiers touchés dans l'onglet Code <span class="c">${f.touched.length}</span></h3>${rows}</div>`;
    });
  } else if (TAB === 'code') {
    const touch = G.meta.vfTouch || {};
    SC.addPanelSection('item', (id) => {
      const f = fileOf(id);
      const list = f && touch[f.p];
      if (!list || !list.length) return '';
      const rows = list.slice(0, 30).map((t) => `<a class="vf-link" href="project.html#r=${encodeURIComponent(t.ref)}">`
        + `<span class="vst vst-${h(t.st).replace(/[^\w-]/g, '')}">${h(ST[t.st] || t.st)}</span><span>${h(t.label)}</span></a>`).join('');
      return `<div class="sec"><h3>Touché par <span class="c">${list.length}</span></h3>${rows}</div>`;
    });
  }
  // la zone du titre : le rectangle de #context (hauteur plafonnée à celle que freeArea() déduit) est un trou dans la découpe de #svg
  const svg = document.getElementById('svg'), ctx = document.getElementById('context');
  const zone = () => {
    if (!svg || !ctx || TAB === 'equipe') return;
    const w = ctx.offsetWidth, hz = Math.min(130, ctx.offsetHeight);
    if (!w || !hz || !svg.getClientRects().length) { svg.style.removeProperty('clip-path'); return; }
    const s = svg.getBoundingClientRect(), b = ctx.getBoundingClientRect(), n = (v) => Math.round(v * 100) / 100;
    svg.style.clipPath = `path(evenodd, 'M0 0H${n(s.width)}V${n(s.height)}H0Z M${n(b.left - s.left)} ${n(b.top - s.top)}h${n(b.width)}v${hz}h${n(-b.width)}Z')`;
  };
  SC.on('render', zone);
  const init = () => {
    const ro = window.ResizeObserver && ctx ? new ResizeObserver(zone) : null;
    if (ro) ro.observe(ctx);
    window.addEventListener('resize', zone); zone();
    return () => { if (ro) ro.disconnect(); window.removeEventListener('resize', zone); if (svg) svg.style.removeProperty('clip-path'); };
  };
  const K = window.VF_COQUILLE;
  if (K && typeof K.surOnglet === 'function') K.surOnglet(init, { cle: '01-vf-ensemble.js' }); else init();
})();
