// VibeFlow (80-16, P80-D-58 a, P80-D-59 d) : le pont entre les onglets Code et Projet, sorti de 00-vibeflow.js pour lui rendre de la place sous le plafond
// de 299 lignes. Un plan renvoie aux fichiers qu'il touche (onglet Projet), un fichier de code renvoie aux plans qui l'ont touché (onglet Code).
// Extension d'onglet : réexécutée avec le moteur à chaque arrivée, elle ne pose ni écouteur global, ni minuterie, ni observateur ; sa seule accroche est
// une section de panneau, posée à l'évaluation. Ne parle au viewer que par window.Floorplan.
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
})();
