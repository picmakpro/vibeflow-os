// VibeFlow (74-04) : feuille de la frise (classes vf-frise-*), jetons existants seulement : aucune couleur, ombre ni rayon neufs, une seule taille de mono
// (11,5 px).
// La couleur dit l'état (--st-active, --sev-high, --recent portés par les formes seules) ; aucun fond, contour ni halo teinté d'état, aucune couleur par nœud.
// Toutes les règles vivent sous .vf-frise, inertes tant que la vue n'est pas montée. Le mouvement réduit coupe toute transition.
(() => {
  if (typeof document === 'undefined' || !document.head || document.head.querySelector('style[data-vf-frise]')) return;
  const st = document.createElement('style');
  st.setAttribute('data-vf-frise', '');
  st.textContent = `
    .vf-frise { --frise-voie: var(--sp-32); --frise-barre: var(--sp-8); --frise-glyphe: var(--sp-12); --frise-trait: var(--sp-2); --frise-col: 240px;
      --frise-courbe: calc(var(--sp-24) * 2); --frise-axe: var(--sp-24); box-sizing: border-box; margin: 0 0 var(--gap-section); padding: var(--inset-card);
      background: var(--surface); border-radius: var(--r-card); box-shadow: var(--shadow-card); color: var(--text); font-size: 12.5px; line-height: 16px;
        outline: none; }
    @media (pointer: coarse) { .vf-frise { --frise-voie: 44px; } }
    @media (max-width: 700px) { .vf-frise { --frise-col: 120px; } }
    .vf-frise [hidden] { display: none; }
    .vf-frise line, .vf-frise polyline { fill: none; }
    .vf-frise .sr { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }
    .vf-frise .mono { font-family: var(--mono); font-size: 11.5px; line-height: 14px; }
    .vf-frise .vf-donnee { font-family: var(--sans); font-size: 12.5px; line-height: 16px; }
    .vf-frise-sonde { position: absolute; visibility: hidden; height: 0; }
    .vf-frise-outils { display: flex; flex-wrap: wrap; align-items: center; gap: var(--sp-8) var(--sp-12); margin: 0 0 var(--sp-8); }
    .vf-frise-lib { color: var(--text-3); font-size: 12.5px; line-height: 16px; }
    .vf-frise-groupe { display: inline-flex; gap: var(--sp-2); padding: var(--sp-4); background: var(--raise); border-radius: var(--r-ctl); }
    .vf-frise-radio { min-height: 28px; padding: var(--sp-4) var(--sp-12); border: 0; border-radius: 8px; background: transparent; color: var(--text-3);
      font: 500 13px/18px var(--sans); cursor: pointer; }
    .vf-frise-radio:hover { background: rgba(var(--ink), .06); color: var(--text); }
    .vf-frise-radio[aria-checked=true] { background: var(--surface); color: var(--text); box-shadow: var(--shadow-card); }
    .vf-frise button:focus-visible, .vf-frise-defil:focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; }
    @media (pointer: coarse) { .vf-frise-radio { min-height: 44px; } }
    .vf-frise-lignes p { margin: 0 0 var(--sp-4); color: var(--text-3); }
    .vf-frise-carte { margin: var(--sp-8) 0; padding: var(--inset-box); background: var(--warn-bg); border-radius: var(--r-ctl); }
    .vf-frise-carte-titre { font: 600 13px/18px var(--sans); color: var(--text); }
    .vf-frise-carte-cause { margin: var(--sp-4) 0 var(--sp-8); color: var(--text-3); }
    .vf-frise-reessayer { min-height: 28px; padding: var(--sp-4) var(--sp-12); border: 0; border-radius: 8px; background: var(--raise); color: var(--text);
      font: 500 13px/18px var(--sans); cursor: pointer; }
    .vf-frise-vide-titre { margin: var(--sp-8) 0 var(--sp-4); font: 600 15px/20px var(--sans); letter-spacing: -.015em; color: var(--text); }
    .vf-frise-vide-texte, .vf-frise-chargement-texte { margin: 0; color: var(--text-3); }
    .vf-frise-fantome { height: var(--frise-voie); margin: 0 0 var(--sp-4); background: var(--raise); border-radius: 8px; }
    .vf-frise-defil { overflow-x: auto; position: relative; }
    .vf-frise-corps { position: relative; min-width: calc(var(--frise-col) + 480px); background: var(--surface); }
    .vf-frise-rang { display: flex; background: var(--surface); }
    .vf-frise-c { position: sticky; left: 0; z-index: 1; flex: 0 0 var(--frise-col); width: var(--frise-col); box-sizing: border-box;
      background: var(--surface); }
    .vf-frise-p { position: relative; flex: 1 1 auto; min-width: 480px; background: var(--surface); }
    .vf-frise-p svg { display: block; }
    .vf-frise-rang-courbe .vf-frise-c, .vf-frise-rang-axe .vf-frise-c { color: var(--text-3); }
    .vf-frise-rang-courbe .vf-frise-c { height: var(--frise-courbe); padding-top: var(--sp-8); }
    .vf-frise-rang-axe .vf-frise-c { height: var(--frise-axe); }
    .vf-frise-bandeau-t { color: var(--text); font-weight: 500; }
    .vf-frise-axe-t, .vf-frise-bandeau-s { color: var(--text-3); }
    .vf-frise-couche { position: absolute; top: 0; bottom: 0; right: 0; left: var(--frise-col); pointer-events: none; }
    .vf-frise-zone { position: relative; width: 100%; height: 100%; }
    .vf-frise-voies { margin: 0; padding: 0; list-style: none; }
    .vf-frise-voie, .vf-frise-repli-ligne { box-sizing: border-box; height: var(--frise-voie); display: flex; align-items: center; background: var(--surface); }
    .vf-frise-cell { display: flex; align-items: center; gap: var(--sp-8); width: 100%; height: 100%; box-sizing: border-box; border: 0;
      background: transparent;
      padding: 0 var(--sp-4) 0 calc(var(--niv, 0) * var(--sp-16) + var(--sp-4)); color: var(--text); text-align: left; font: inherit; cursor: pointer; }
    .vf-frise-cell:hover, .vf-frise-cell:active, .vf-frise-cell:focus-visible { background: transparent; }
    .vf-frise-cell:focus-visible, .vf-frise-repli:focus-visible { outline-offset: -2px; }
    .vf-frise-cell:hover .vf-frise-nom { text-decoration: underline; }
    .vf-frise-glyphe { flex: none; width: 16px; height: 16px; fill: none; stroke: currentColor; stroke-width: 1.5; stroke-linecap: round;
      stroke-linejoin: round; color: var(--text-3); }
    .vf-frise-glyphe[data-glyphe=actif], .vf-frise-glyphe[data-glyphe=attend] { color: var(--st-active); }
    .vf-frise-textes { display: flex; flex-direction: column; min-width: 0; }
    .vf-frise-nom { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-weight: 500; color: var(--text); }
    .vf-frise-sous { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font: 500 11.5px/14px var(--sans); color: var(--text-3); }
    .vf-frise-repli { margin-left: var(--sp-16); padding: var(--sp-4) var(--sp-8); border: 0; border-radius: 8px; background: transparent;
      color: var(--text-2); font: 500 12.5px/16px var(--sans); cursor: pointer; }
    .vf-frise-repli:hover { background: rgba(var(--ink), .06); }
    .vf-frise-repli-n { color: var(--text-3); margin-left: var(--sp-4); }
    .vf-frise-pistes text, .vf-frise-axe-svg text, .vf-frise-legende text { font: 400 11.5px/14px var(--mono); fill: var(--text-3); }
    .vf-frise-trait { stroke: var(--hair); stroke-width: 1; }
    .vf-frise-filet { stroke: var(--hair-2); stroke-width: 1; }
    .vf-frise-maintenant { stroke: var(--text-3); stroke-width: 1; fill: none; }
    .vf-frise-seg { fill: var(--st-active); stroke: none; }
    .vf-frise-coupe { stroke: none; }
    .vf-frise-hachure { stroke: var(--st-active); }
    [data-etat=agents], [data-ech=agents] { stroke: var(--text-3); stroke-width: var(--sp-2); }
    [data-etat=repos], [data-ech=repos] { stroke: var(--text-4); stroke-width: var(--sp-2); }
    [data-evt] path, [data-evt] circle { fill: none; stroke-width: 1.5; stroke-linecap: round; stroke-linejoin: round; }
    [data-evt=compaction] path { stroke: var(--text-2); }
    [data-evt=erreur] path { stroke: var(--sev-high); }
    [data-evt=rapport] path { stroke: var(--recent); }
    [data-evt=humain] circle { fill: var(--text); stroke: none; }
    .vf-frise-dispatch { stroke: var(--text-4); stroke-width: 1.5; }
    .vf-frise-losange { fill: var(--text-2); }
    .vf-frise .vf-frise-plus { fill: var(--text-3); }
    .vf-frise-courbe-fond { fill: var(--raise-2); stroke: none; }
    .vf-frise-courbe-trait { fill: none; stroke: var(--text-3); stroke-width: 1.5; }
    .vf-frise-legende { display: flex; flex-wrap: wrap; gap: var(--sp-8) var(--sp-16); margin: var(--sp-12) 0 0; color: var(--text-3); }
    .vf-frise-leg { display: inline-flex; align-items: center; gap: var(--sp-6); }
    .vf-frise-emplacement:empty { display: none; }
    @media (prefers-reduced-motion: reduce) { .vf-frise, .vf-frise * { transition: none; animation: none; scroll-behavior: auto; } }
  `;
  document.head.appendChild(st);
})();
