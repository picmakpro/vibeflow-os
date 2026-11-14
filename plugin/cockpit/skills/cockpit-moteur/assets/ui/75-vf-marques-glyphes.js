// VibeFlow (75-07, P75-D-01, P75-D-03, P75-D-25) : l'habillage de la marque de carte, onglet Code seulement :
// glyphes en masque SVG, mot, place du pied, zooms, carte « prévue ».
// Le canal (75-vf-marques.js) pose le DOM (`.lmg` > `.lm` > `.lg lg-<clé>`, `.lw`, `.lc`) ; ce fichier ne pose que la feuille de
// style, par `VF_COQUILLE.surOnglet` (cle : le nom du fichier ; le nettoyage rendu retire la feuille).
// Aucun jeton nouveau, supprimé ni renommé (P71.5-D-29) ; aucune couleur littérale (M5.3) ; seule teinte : `--recent`.
(() => {
  'use strict';
  const CLE = '75-vf-marques-glyphes.js', ID = 'vf-marques-style';
  // encodeURIComponent : jamais de `#` littéral dans la source (M5.3) ; même technique que les glyphes d'état de 00-vibeflow.js
  const SVG = (corps) => "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'>" + corps + '</svg>';
  const MASQUE = (corps) => 'url("data:image/svg+xml,' + encodeURIComponent(SVG(corps)) + '")';
  const PLEIN = (d) => `<path d='${d}' fill='black'/>`;
  const TRAIT = (d, w) => `<path d='${d}' fill='none' stroke='black' stroke-width='${w}' stroke-linecap='round' stroke-linejoin='round'/>`;
  // barres de 3 de large, écart de 2 (1,5 à k = 0,42 : la colonne éteinte de S6b l'exige) : aires 15, 42, 81
  const B1 = 'M1.5 14.5V9.5H4.5V14.5Z', B2 = 'M6.5 14.5V5.5H9.5V14.5Z', B3 = 'M11.5 14.5V1.5H14.5V14.5Z';
  const BOUCLIER = 'M8 1.5L13.5 3.8V8C13.5 11.3 11.2 13.3 8 14.5C4.8 13.3 2.5 11.3 2.5 8V3.8Z';
  // le bouclier décalé de 1 vers l'intérieur : le trait de 2 reste dans [1,5 ; 14,5]
  const EVIDE = 'M8 2.5L12.5 4.4V8C12.5 10.8 10.6 12.5 8 13.5C5.4 12.5 3.5 10.8 3.5 8V4.4Z';
  const CARRE = "<rect x='4.25' y='4.25' width='7.5' height='7.5' fill='none' stroke='black' stroke-width='2.5'/>";
  const GLYPHES = {
    bas: PLEIN(B1), moyen: PLEIN(B1 + B2), haut: PLEIN(B1 + B2 + B3),
    confluent: TRAIT('M3 2.5L8 8.5L13 2.5M8 8.5V13.5', 2),
    bouclier: PLEIN(BOUCLIER),
    'sans-temoin': `<path d='${EVIDE}' fill='none' stroke='black' stroke-width='2' stroke-linejoin='round'/>` + TRAIT('M3.5 13L12.5 3', 2.5),
    'en-cours': "<circle cx='8' cy='8' r='5' fill='black'/>",
    modifie: PLEIN('M8 2.5L13.5 13.5H2.5Z'),
    lu: CARRE,
    fini: "<rect x='3' y='6.5' width='10' height='3' fill='black'/>",
    prevu: "<path d='M13.5 8A5.5 5.5 0 0 0 10.75 3.24M5.25 3.24A5.5 5.5 0 0 0 2.5 8M5.25 12.76A5.5 5.5 0 0 0 10.75 12.76'" +
      " fill='none' stroke='black' stroke-width='2'/>",
    neutre: CARRE, // une clé de glyphe inconnue (couche relecture de la Phase 74…) : le glyphe neutre, en --text-3
  };
  const masques = Object.entries(GLYPHES).map(([k, c]) => `.lg-${k} { --g-lg: ${MASQUE(c)}; }`).join('\n    ');
  const CSS = `
    ${masques}
    .vst-prevu { --c-st: var(--st-todo); --g-st: ${MASQUE(GLYPHES.prevu)}; }
    /* la marque : emplacement droit du pied, sans fond ni liseré ni halo ; le glyphe ne s'ellipse jamais, le mot oui ; elle rétrécit avant .meta */
    .foot { height: var(--sp-20); }
    .lmg { display: flex; align-items: center; gap: var(--sp-8); margin-left: auto; min-width: 0; flex: 0 1 auto; }
    .lmg-g { margin-left: 0; }
    .lm { display: inline-flex; align-items: center; gap: var(--sp-6); min-width: 0; flex: 0 1 auto; font-size: 11px; font-weight: 500; line-height: 16px;
      color: var(--text-2); padding: var(--sp-2) 0; white-space: nowrap; }
    .lm-n { flex: none; }
    .lw { min-width: 0; overflow: hidden; text-overflow: ellipsis; }
    .lm-n .lw { overflow: visible; }
    .lc { display: none; }
    .lg { width: 1.45em; height: 1.45em; flex: none; background: var(--c-lg, var(--text-3));
      -webkit-mask: var(--g-lg) center / contain no-repeat; mask: var(--g-lg) center / contain no-repeat; }
    .lg-lu, .lg-fini { --c-lg: var(--text-4); }
    .lg-prevu { --c-lg: var(--st-todo); }
    .lg-en-cours { --c-lg: var(--recent); animation: vfm-respire 2.4s ease-in-out infinite; }
    .card.module .lg-en-cours { --c-lg: var(--recent-text); } /* 2,91:1 de --recent sur --raise en clair : variante texte (§ 9) */
    @keyframes vfm-respire { 50% { transform: scale(.82); } }
    @media (prefers-reduced-motion: reduce) { .lg-en-cours { animation: none; } }
    /* zooms : un seul glyphe de 24 unités, pied de 28 fixe, padding 0 12, jamais de retour à la ligne */
    svg.lod-mid .foot, svg.lod-low .foot { height: calc(var(--sp-24) + var(--sp-4)); flex-wrap: nowrap; } /* dérivé : pastille du zoom d'éloignement */
    svg.lod-mid .lm, svg.lod-low .lm { font-size: 17px; line-height: 20px; padding: 0 var(--sp-12); }
    svg.lod-mid .vst, svg.lod-low .vst { font-size: 17px; line-height: 20px; padding: 0 var(--sp-12); }
    svg.lod-mid .lg, svg.lod-low .lg { width: var(--sp-24); height: var(--sp-24); }
    svg.lod-mid .foot .meta, svg.lod-low .foot .meta { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    svg.lod-mid .foot .lmg, svg.lod-mid .foot .lm, svg.lod-mid .foot .vst, svg.lod-low .foot .vst { flex: none; }
    svg.lod-mid .lw, svg.lod-low .lw, svg.lod-low .lc { display: none; }
    svg.lod-mid .lm-n .lw { display: inline; }
    svg.lod-mid .lc { display: inline; }
    /* carte « prévue » : fond transparent, bordure pointillée neutre, sans ombre ; le padding perd la bordure : le contenu ne bouge pas */
    .card.st-prevu { background: transparent; box-shadow: none; border: 1.5px dashed var(--hair-2); /* dérivé : bordure 1,5 */
      padding: calc(var(--inset-card) - 1.5px); }
    .node:hover .card.st-prevu, .node.sel .card.st-prevu { background: transparent; box-shadow: none; }
    .card.st-prevu .title { font-weight: 500; color: var(--text-2); }
    .card.st-prevu .ico { color: var(--text-3); }`;

  const arrivee = (ev) => {
    if (!ev || ev.onglet !== 'code') return () => {};
    document.getElementById(ID)?.remove();
    const s = document.createElement('style');
    s.id = ID; s.textContent = CSS; document.head.appendChild(s);
    return () => { s.remove(); };
  };
  if (window.VF_COQUILLE && typeof window.VF_COQUILLE.surOnglet === 'function') window.VF_COQUILLE.surOnglet(arrivee, { cle: CLE });
  else arrivee({ onglet: 'code' });
})();
