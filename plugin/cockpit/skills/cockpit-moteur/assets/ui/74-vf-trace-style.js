// VibeFlow (76-06) : feuille de la traçabilité (UI-SPEC § 1.1, § 2.3, § Typography, § 13) : classes vf-trace-* sous un parent .vf-trace, cinq masques de
// glyphe.
// Aucune valeur de couleur, d'espacement ni de rayon en dur : jetons du moteur seulement ; exceptions écrites : glyphe 16 px, texte masqué 1 px, contrôles
// 32 et 44 px.
(() => {
  const VT = (window.VFTrace = window.VFTrace || {});
  // patron GLYPHE de 00-vibeflow.js (viewBox 16, trait noir explicite, teinté par --c-st) ; corps copiés tels quels de l'UI-SPEC § 1.1
  const GLYPHE = (corps) => 'url("data:image/svg+xml,' + encodeURIComponent("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'>" + corps
    + '</svg>') + '")';
  const CARRE = "<rect x='2.5' y='2.5' width='11' height='11' rx='1.5' fill='none' stroke='black' stroke-width='1.75'/>";
  const G = {
    lu: GLYPHE("<rect x='3' y='3' width='10' height='10' rx='1.5' fill='black'/>"),
    manque: GLYPHE(CARRE),
    nonlisible: GLYPHE(CARRE + "<circle cx='6' cy='8' r='1' fill='black'/><circle cx='10' cy='8' r='1' fill='black'/>"),
    resolu: GLYPHE(CARRE + "<path d='M5.5 6.2h5M5.5 9.8h5' fill='none' stroke='black' stroke-width='2' stroke-linecap='butt'/>"),
    contradiction: GLYPHE("<path d='M5 1.8h6l3.2 3.2v6L11 14.2H5L1.8 11V5z' fill='none' stroke='black' stroke-width='1.75' stroke-linejoin='round'/>"
      + "<rect x='5.5' y='5.5' width='5' height='5' rx='1' fill='black'/>"),
  };
  const CSS = `
    .vf-trace { font-size: 12.5px; line-height: 18px; }
    .vf-trace[hidden], .vf-trace [hidden] { display: none; }
    .vf-trace[data-vf-trace-panneau] { padding-inline: var(--inset-panel); } .vf-trace[data-vf-trace-panneau] .sec { padding-inline: 0; }
    .vf-trace-g { display: inline-block; flex: none; width: 16px; height: 16px; background: var(--c-st, var(--text-3));
      -webkit-mask: var(--g-st) center / contain no-repeat; mask: var(--g-st) center / contain no-repeat; }
    .vf-trace-g-lu { --g-st: ${G.lu}; --c-st: var(--text-2); } .vf-trace-g-manque { --g-st: ${G.manque}; --c-st: var(--st-todo); }
    .vf-trace-g-non-lisible { --g-st: ${G.nonlisible}; --c-st: var(--text-3); } .vf-trace-g-resolu { --g-st: ${G.resolu}; --c-st: var(--text-3); }
    .vf-trace-g-contradiction { --g-st: ${G.contradiction}; --c-st: var(--st-blocked); }
    .vf-trace-neutre .vf-trace-g { --c-st: var(--text-3); }
    .vf-trace-paire { display: inline-flex; align-items: flex-start; gap: var(--sp-4); white-space: nowrap; }
    .vf-trace-bande { display: inline-flex; align-items: flex-start; gap: var(--sp-4); flex: none; }
    .vf-trace-sr { position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%); white-space: nowrap; }
    .vf-trace-ligne { position: relative; display: flex; flex-direction: column; gap: var(--sp-2); width: calc(100% + 2 * var(--sp-12));
      margin-inline: calc(-1 * var(--sp-12)); padding: var(--inset-row); border: 0; border-radius: var(--r-ctl); background: none;
      color: inherit; font: inherit; text-align: left; cursor: pointer; box-sizing: border-box; }
    .vf-trace-ligne:hover { background: rgba(var(--ink), .06); }
    .vf-trace-ligne:focus-visible, .vf-trace-plus:focus-visible, .vf-trace-puce:focus-visible { outline: 2px solid var(--ring); outline-offset: -2px; }
    .vf-trace-ligne[aria-current="true"] { background: var(--surface-hover); }
    .vf-trace-lignes { display: flex; flex-direction: column; gap: var(--sp-2); margin: 0; padding: 0; list-style: none; }
    .vf-trace-l1 { display: flex; gap: var(--sp-6); align-items: baseline; min-width: 0; }
    .vf-trace-id { flex: none; font-family: var(--mono); font-size: 11.5px; line-height: 16px; font-weight: 500; color: var(--text-2); }
    .vf-trace-tx, .vf-trace-nom { min-width: 0; color: var(--text); overflow-wrap: anywhere; }
    .vf-trace-tx { display: -webkit-box; -webkit-box-orient: vertical; -webkit-line-clamp: 2; overflow: hidden; }
    .vf-trace-tt { min-width: 0; color: var(--text-2); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .vf-trace-l2 { display: flex; align-items: flex-start; gap: var(--sp-8); min-width: 0; }
    .vf-trace-mot, .vf-trace-l3, .vf-trace-cl2 { display: -webkit-box; -webkit-box-orient: vertical; -webkit-line-clamp: 2; overflow: hidden; min-width: 0;
      font-size: 11.5px; line-height: 16px; }
    .vf-trace-mot, .vf-trace-cl2 { font-weight: 500; color: var(--text-2); } .vf-trace-l3 { color: var(--text-3); }
    .vf-trace-nom1 { font-weight: 500; color: var(--text); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; min-width: 0; }
    .vf-trace-bilan { display: -webkit-box; -webkit-box-orient: vertical; -webkit-line-clamp: 3; overflow: hidden; margin: 0 0 var(--sp-8);
      color: var(--text-3); font-variant-numeric: tabular-nums; }
    .vf-trace-bilan-4 { -webkit-line-clamp: 4; }
    .vf-trace-legende { display: -webkit-box; -webkit-box-orient: vertical; -webkit-line-clamp: 4; overflow: hidden; margin: 0 0 var(--sp-8);
      font-size: 11.5px; line-height: 16px; color: var(--text-3); }
    .vf-trace-legende .vf-trace-paire { margin-inline-end: var(--sp-6); }
    .vf-trace-etat { margin: 0; color: var(--text-3); }
    .vf-trace-boite { display: flex; flex-direction: column; align-items: flex-start; gap: var(--sp-6); padding: var(--inset-box);
      border-radius: var(--r-ctl); background: var(--warn-bg); color: var(--text-2); }
    .vf-trace-boite strong { font-weight: 500; color: var(--text); }
    .vf-trace-fantome { height: 32px; margin-bottom: var(--sp-2); border-radius: var(--r-ctl); background: var(--raise); }
    .vf-trace-plus { display: block; max-width: 100%; height: 32px; margin-top: var(--sp-8); padding: 0 var(--sp-12); border: 0; border-radius: var(--r-ctl);
      background: none; font: inherit; font-weight: 500; color: var(--text-2); text-align: left; white-space: nowrap; overflow: hidden;
        text-overflow: ellipsis; cursor: pointer; }
    .vf-trace-plus:hover { background: rgba(var(--ink), .06); }
    .vf-trace-repli > summary { display: flex; align-items: center; gap: var(--sp-6); min-height: 32px; cursor: pointer; font-weight: 500;
      color: var(--text-3); }
    .vf-trace-repli > summary:hover { color: var(--text); }
    .vf-trace-repli > summary:focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; }
    .vf-trace-repli[open] > summary { margin-bottom: var(--sp-8); } .vf-trace-repli > summary .c { font-weight: 400; color: var(--text-4); }
    .vf-trace-preuve { display: flex; flex-direction: column; padding: var(--sp-8) 0 0; }
    .vf-trace-preuve[aria-current="true"] { background: var(--surface-hover); }
    .vf-trace-p1 { display: flex; gap: var(--sp-8); justify-content: space-between; padding-inline: var(--sp-12); min-width: 0; }
    .vf-trace-p1 .vf-trace-nom1 { flex: none; max-width: 100%; } .vf-trace-st { font-size: 11.5px; line-height: 16px; color: var(--text-3); }
    .vf-trace-critere { margin: 0; padding: var(--sp-2) var(--sp-12); color: var(--text-2); overflow-wrap: anywhere; }
    .vf-trace .vf-ref { display: flex; align-items: center; gap: var(--sp-8); min-height: 32px; border-radius: var(--r-ctl); }
    .vf-trace .vf-ref code { display: block; flex: 1 1 0; min-width: 0; font-size: 11.5px; line-height: 16px; white-space: nowrap; overflow: hidden;
      text-overflow: ellipsis; }
    .vf-trace .vf-ref .vf-copie-etat { float: none; margin: 0; flex: none; font-size: 11.5px; }
    .vf-trace .btn.soft { font-size: 12.5px; height: 32px; font-weight: 400; } .vf-trace .vst { font-size: 11.5px; } .vf-trace .tag { line-height: 16px; }
    .vf-trace-aide, .vf-trace-note, .vf-trace-pied { font-size: 11.5px; line-height: 16px; color: var(--text-3); }
    .vf-trace-maillon { display: flex; align-items: flex-start; gap: var(--sp-4); flex-wrap: wrap; padding: var(--sp-4) 0; }
    .vf-trace-maillon .vf-trace-nom { font-weight: 500; flex: none; } .vf-trace-maillon .vf-trace-note { flex: 1 1 0; min-width: 0; }
    .vf-trace-puces { display: flex; flex-wrap: wrap; gap: var(--sp-6); margin-top: var(--sp-6); }
    .vf-trace-puce { display: inline-flex; align-items: center; max-width: 100%; border: 0; cursor: pointer; overflow: hidden; text-overflow: ellipsis;
      white-space: nowrap; }
    .vf-trace-puce:hover { background: rgba(var(--ink), .1); }
    .vf-trace-pages { display: flex; flex-direction: column; row-gap: var(--sp-8); margin-top: var(--sp-8); }
    .vf-trace-pages-b { display: flex; gap: var(--sp-8); } .vf-trace-pages-b .btn { flex: 1 1 0; justify-content: center; white-space: nowrap; }
    .vf-trace-compte { display: -webkit-box; -webkit-box-orient: vertical; -webkit-line-clamp: 2; overflow: hidden; margin: 0; font-size: 11.5px;
      line-height: 16px;
      color: var(--text-3); font-variant-numeric: tabular-nums; }
    .vf-trace-bloc { margin-bottom: var(--sp-16); } .vf-trace-bloc h3 .c { font-weight: 400; color: var(--text-4); }
    .vf-trace-bilan-2 { -webkit-line-clamp: 2; }
    .vf-trace-commit { display: flex; flex-direction: column; gap: var(--sp-2); min-width: 0; padding: var(--inset-row); }
    div.vf-trace-commit { width: calc(100% + 2 * var(--sp-12)); margin-inline: calc(-1 * var(--sp-12)); box-sizing: border-box; }
    .vf-trace-c1 { display: flex; gap: var(--sp-6); align-items: baseline; }
    .vf-trace-jour { font-size: 11.5px; line-height: 16px; color: var(--text-3); }
    .vf-trace-sujet { min-width: 0; color: var(--text); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .vf-trace-borne { display: -webkit-box; -webkit-box-orient: vertical; -webkit-line-clamp: 3; overflow: hidden; margin: 0 0 var(--sp-8);
      font-size: 11.5px; line-height: 16px; color: var(--text-3); }
    .vf-trace-sous { margin-inline-start: var(--sp-12); } .vf-trace-sous > summary.vf-trace-sous-t { color: var(--text-2); }
    .vf-trace-inerte { width: calc(100% + 2 * var(--sp-12)); margin-inline: calc(-1 * var(--sp-12)); padding: var(--inset-row); box-sizing: border-box; }
    .vf-trace-m1 { min-width: 0; font-family: var(--mono); font-weight: 500; color: var(--text); overflow: hidden; text-overflow: ellipsis;
      white-space: nowrap; }
    .vf-trace-a1 { display: flex; justify-content: space-between; align-items: baseline; gap: var(--sp-8); min-width: 0; }
    .vf-trace-nb { flex: none; font-size: 11.5px; line-height: 16px; color: var(--text-3); font-variant-numeric: tabular-nums; }
    .vf-trace-l3t { -webkit-line-clamp: 3; } .vf-trace-contra { font-weight: 500; color: var(--text-2); }
    .vf-trace .pt.vf-trace-nom-m { display: -webkit-box; -webkit-box-orient: vertical; -webkit-line-clamp: 3; overflow: hidden; overflow-wrap: anywhere;
      font-family: var(--mono); }
    .vf-trace-fiche { display: grid; grid-template-columns: minmax(0, 40%) minmax(0, 1fr); column-gap: var(--sp-8); row-gap: var(--sp-2); align-items: baseline;
      margin: 0; }
    .vf-trace-fiche dt { font-size: 11.5px; line-height: 16px; color: var(--text-3); }
    .vf-trace-fiche dd { margin: 0; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; color: var(--text); }
    .vf-trace-fiche dd.vf-trace-m1 { font-weight: 400; }
    .vf-trace-etatm { display: flex; align-items: flex-start; gap: var(--sp-4); font-weight: 500; color: var(--text); }
    .vf-trace-l2e { display: flex; align-items: flex-start; gap: var(--sp-4); font-size: 11.5px; line-height: 16px; color: var(--text-3); white-space: nowrap; }
    .vf-trace-absent { display: flex; flex-direction: column; gap: var(--sp-2); }
    .vf-trace-absent .vf-trace-l2e { margin-inline-start: calc(var(--sp-16) + var(--sp-4)); white-space: normal; display: -webkit-box;
      -webkit-box-orient: vertical; -webkit-line-clamp: 2; overflow: hidden; }
    .vf-trace-absent .vf-trace-chem { display: flex; align-items: flex-start; gap: var(--sp-4); min-width: 0; font-family: var(--mono); font-size: 11.5px;
      line-height: 16px; color: var(--text-3); }
    .vf-trace-absent .vf-trace-chem span:last-child { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .vf-trace-jalon-l1 { display: flex; gap: var(--sp-6); align-items: center; min-width: 0; }
    .vf-trace-jalon-l1 .vf-trace-nom1 { flex: none; } .vf-trace-jalon-l1 .vst { flex: none; margin-inline-start: auto; }
    @media (max-width: 700px) { .vf-trace-tx { -webkit-line-clamp: 1; } }
    @media (max-width: 700px), (pointer: coarse) {
      .vf-trace-plus, .vf-trace-repli > summary, .vf-trace .btn.soft { min-height: 44px; height: 44px; }
      .vf-trace .vf-ref { min-height: 44px; } .vf-trace-puce { min-height: 44px; }
    }`;
  VT.style = () => {
    if (document.getElementById('vf-trace-style')) return;
    const s = document.createElement('style'); s.id = 'vf-trace-style'; s.textContent = CSS; document.head.append(s);
  };
  VT.retirerStyle = () => { const s = document.getElementById('vf-trace-style'); if (s) s.remove(); };
})();
