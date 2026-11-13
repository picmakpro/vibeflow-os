// VibeFlow (77-08, SYNT-01 ; P77-D-02) : la feuille NEUTRE de la Synthèse. Une feuille injectée une fois (identifiant fixe), toutes les règles
// sous `.vf-sy` : neutres de « Graphite » seulement (aucun fond teinté, aucune couleur d'alerte : le glyphe de forme et le mot disent l'état),
// espacements par les jetons --sp-* de la grille fermée, quatre tailles (20, 13,5, 12,5, 11 px), deux graisses (500, 600), aucun mouvement,
// aucune règle sur le panneau du viewer. Script PAR ONGLET : le garde de l'identifiant évite la seconde injection.
// Les blocs de burn-up et de santé (77-06) portent leur feuille propre.
(() => {
  'use strict';
  if (document.getElementById('vf-sy-style')) return;
  const st = document.createElement('style'); st.id = 'vf-sy-style';
  st.textContent = `
    .vf-sy .vst { --c-st: var(--text-2); }
    .vf-sy .sr { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); clip-path: inset(50%); white-space: nowrap; }
    .vf-sy .pd { font-size: 13.5px; }
    .vf-sy .btn { font-size: 12.5px; }
    .vf-sy .vf-sy-note { margin: var(--sp-2) 0 0; font-size: 12.5px; line-height: 1.45; color: var(--text-3); }
    .vf-sy .vf-sy-fort { margin: 0; font-size: 12.5px; font-weight: 500; line-height: 1.4; color: var(--text); }
    .vf-sy .vf-sy-tete { margin: 0; font-size: 12.5px; font-weight: 500; line-height: 1.4; color: var(--text); font-variant-numeric: tabular-nums; }
    .vf-sy .vf-sy-grp { margin-top: var(--sp-12); }
    .vf-sy .vf-sy-grp > .vf-link + .vf-link { margin-top: var(--sp-2); }
    .vf-sy .vf-sy-ligne { display: flex; gap: var(--sp-8); align-items: baseline; padding: var(--sp-2) 0; }
    .vf-sy .vf-sy-ligne { font-size: 12.5px; line-height: 1.4; color: var(--text-2); }
    .vf-sy .vf-sy-micro { font-size: 11px; font-weight: 500; line-height: 1.45; color: var(--text-3); font-variant-numeric: tabular-nums; }
    .vf-sy .more { margin: 0; padding: var(--sp-6) 0 0; font-size: 12.5px; color: var(--text-4); }
    .vf-sy .vf-link { color: var(--text-2); }
    .vf-sy .vf-link > span:not(.vst) { min-width: 0; overflow-wrap: anywhere; }
    @media (pointer: coarse), (max-width: 999px) { .vf-sy .vf-link, .vf-sy summary { min-height: 44px; align-items: center; } }`;
  document.head.appendChild(st);
})();
