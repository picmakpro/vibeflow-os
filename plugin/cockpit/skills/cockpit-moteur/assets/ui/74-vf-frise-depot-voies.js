// VibeFlow (74-07) : bandeau « Dépôt » de la frise, partie pure : rangement des commits par sous-voie, fusion des commits proches, noms accessibles, feuille.
// Chargé AVANT 74-vf-frise-depot.js (ordre lexical) : pose window.__vfDepotVoies, n'appelle rien. Aucun réseau, aucune couleur par branche
// (le champ de couleur du serveur n'est pas lu), jetons existants seulement.
(() => {
  'use strict';
  const NB = ' ', OUVRIR = 'Ouvrir dans le tiroir Git', OUVRIR_RECENT = 'Ouvrir le plus récent dans le tiroir Git';
  const heure = (M, ms) => M.fmtHeure(ms, { phrase: true });
  const pluriel = (n, un, plusieurs) => `${n} ${n > 1 ? plusieurs : un}`;

  // commits de la fenêtre, rangés par branche (74-01 : descente du premier parent) ; avant l'instant de couverture, rien n'est dessiné
  const preparer = (M, git, depuis, jusqua, couv) => {
    const { branches, autres } = M.commitsParBranche(git);
    const dans = (c) => c.atMs >= depuis && c.atMs <= jusqua && (!couv.incomplet || c.atMs >= couv.depuisMs);
    const voies = branches.map((b) => ({ nom: b.nom, commits: b.commits.filter(dans) })).filter((b) => b.commits.length);
    const reste = autres.commits.filter(dans);
    return { voies, autres: reste, total: voies.reduce((s, b) => s + b.commits.length, 0) + reste.length };
  };

  // un groupe tant que le centre reste à moins de `cible` du premier : le bouton est posé sur le plus ancien du groupe,
  // aucune zone de saisie n'en recouvre une autre
  const grouper = (commits, x, cible) => {
    const tri = commits.map((c) => ({ c, x: x(c.atMs) })).sort((a, b) => a.x - b.x || a.c.atMs - b.c.atMs), out = [];
    for (const e of tri) {
      const g = out[out.length - 1];
      if (g && e.x - g.x < cible) g.items.push(e.c); else out.push({ x: e.x, items: [e.c] });
    }
    for (const g of out) g.items.sort((a, b) => b.atMs - a.atMs); // le plus récent d'abord : c'est lui que le bouton ouvre
    return out;
  };

  const etiquette = (M, g, branche, ouvrable) => {
    const it = g.items, n = it.length, ou = branche ? `, branche ${branche}` : '';
    if (n === 1) return `Commit ${it[0].h7}${ou}, ${heure(M, it[0].atMs)}${ouvrable ? `. ${OUVRIR}` : ''}`;
    const liste = it.map((c) => c.h7).join(', ');
    return `${n} commits, de ${heure(M, it[n - 1].atMs)} à ${heure(M, it[0].atMs)}${ou}${NB}: ${liste}${ouvrable ? `. ${OUVRIR_RECENT}` : ''}`;
  };

  const feuille = () => {
    if (typeof document === 'undefined' || !document.head || document.head.querySelector('style[data-vf-frise-depot]')) return;
    const st = document.createElement('style');
    st.setAttribute('data-vf-frise-depot', '');
    st.textContent = `
      .vf-frise { --frise-depot: var(--sp-24); }
      @media (pointer: coarse) { .vf-frise { --frise-depot: 44px; } }
      .vf-frise-rang-depot { min-height: calc(var(--frise-depot) + var(--sp-16)); } /* l'état d'échec ou de chargement ne change pas la hauteur de la rangée */
      .vf-depot-tete { padding: var(--sp-4) var(--sp-8) var(--sp-4) 0; color: var(--text-3); }
      .vf-depot-titre { color: var(--text); font-weight: 500; }
      .vf-depot-compte, .vf-depot-mention { color: var(--text-3); }
      .vf-depot-voie { box-sizing: border-box; display: flex; align-items: center; height: var(--frise-depot); border-top: 1px solid var(--hair); }
      .vf-depot-autres { height: calc(var(--frise-depot) + var(--sp-8)); }
      .vf-depot-lib { flex-direction: column; align-items: flex-start; justify-content: center; }
      .vf-depot-nom, .vf-depot-n2 { max-width: 100%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; color: var(--text-3); }
      .vf-depot-nom { font: 400 11.5px/14px var(--mono); }
      .vf-depot-lib .vf-depot-nom { font: 400 12.5px/16px var(--sans); }
      .vf-depot-n2 { font: 400 11.5px/14px var(--mono); }
      .vf-depot-p { position: relative; }
      .vf-depot-pistes { position: relative; }
      .vf-depot-piste { position: relative; }
      .vf-depot-filet { position: absolute; top: 0; bottom: 0; width: 0; border-left: 1px solid var(--hair-2); pointer-events: none; }
      .vf-depot-commit { position: absolute; top: 0; box-sizing: border-box; display: flex; align-items: center; justify-content: center;
        width: var(--frise-depot); height: var(--frise-depot); margin-left: calc(var(--frise-depot) / -2);
        padding: 0; border: 0; background: transparent; color: var(--text-2); }
      button.vf-depot-commit { cursor: pointer; }
      .vf-depot-commit svg { width: var(--frise-glyphe); height: var(--frise-glyphe); }
      .vf-depot-commit .vf-frise-losange { fill: var(--text-2); stroke: none; }
      .vf-depot-n { position: absolute; left: 50%; margin-left: var(--sp-8); font: 400 11.5px/14px var(--mono); color: var(--text-2); pointer-events: none; }
      .vf-depot-etat { padding: var(--sp-8) var(--sp-8) var(--sp-4); color: var(--text-3); }
      .vf-depot-etat .vf-frise-reessayer { margin-left: var(--sp-12); }
      .vf-depot-plus { margin: var(--sp-4) 0 0; }
    `;
    document.head.appendChild(st);
  };
  feuille();

  window.__vfDepotVoies = Object.freeze({ NB, preparer, grouper, etiquette, pluriel, heure });
})();
