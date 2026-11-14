// VibeFlow (Phase 74, plan 74-05, TEMP-06) : feuille de la fiche d'agent, jetons existants seuls (UI-SPEC § 4, § 6). Inerte tant qu'aucune fiche n'existe :
// toutes les règles sont sous body.vf-regie-montee .vf-fiche. Aucune animation hors le fondu d'ouverture (200 ms), coupé sous prefers-reduced-motion.
(() => {
  if (typeof document === 'undefined' || !document.head || document.head.querySelector('style[data-vf-fiche]')) return;
  const st = document.createElement('style');
  st.setAttribute('data-vf-fiche', '');
  const F = 'body.vf-regie-montee .vf-fiche';
  st.textContent = `
    @keyframes vf-fiche-fondu { from { opacity: 0; } to { opacity: 1; } }
    ${F} { box-sizing: border-box; display: flex; flex-direction: column; background: var(--surface); color: var(--text); border-radius: var(--r-card);
      box-shadow: var(--shadow-card); height: calc(100vh - var(--hh, 4rem) - 12rem); min-height: 320px; animation: vf-fiche-fondu 200ms var(--ease); }
    @media (prefers-reduced-motion: reduce) { ${F} { animation: none; } }
    ${F} [hidden] { display: none !important; }
    ${F} :focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; }
    ${F} button { font: inherit; cursor: pointer; }
    ${F}-tete { flex: none; padding: var(--inset-panel); }
    ${F}-retour { display: inline-flex; align-items: center; gap: var(--sp-8); min-height: 36px; margin: 0 0 var(--sp-12); padding: var(--inset-pill);
      border: 0; border-radius: var(--r-ctl); background: rgba(var(--ink), .06); color: var(--text-2); font-size: 12.5px; }
    ${F}-titre { margin: 0; font-size: 20px; line-height: 28px; font-weight: 600; color: var(--text); overflow-wrap: anywhere; }
    ${F}-ratt { margin: var(--sp-4) 0 0; font-size: 12.5px; line-height: 20px; color: var(--text-2); overflow-wrap: anywhere; }
    ${F}-lien { padding: 0; border: 0; background: none; color: inherit; font-size: inherit; text-decoration: underline; }
    ${F}-ratt a { color: inherit; text-decoration: underline; }
    ${F}-corps { flex: 1; min-height: 0; display: grid; grid-template-columns: minmax(280px, 360px) minmax(0, 1fr); gap: var(--gap-section);
      padding: 0 var(--inset-panel) var(--inset-panel); }
    ${F}-faits, ${F}-fil { min-height: 0; min-width: 0; overflow-y: auto; overflow-wrap: anywhere; }
    ${F}-resume { display: none; }
    ${F}-sous { margin: 0 0 var(--sp-12); font-size: 12.5px; line-height: 16px; color: var(--text-3); }
    ${F}-etat { margin: var(--sp-8) 0; font-size: 12.5px; line-height: 20px; color: var(--text-2); }
    ${F}-kv { display: flex; justify-content: space-between; gap: var(--sp-12); padding: var(--sp-4) 0; font-size: 12.5px; line-height: 16px; }
    ${F}-kv dt { color: var(--text-3); }
    ${F}-kv dd { margin: 0; color: var(--text); text-align: right; font-variant-numeric: tabular-nums; }
    ${F}-id, ${F}-jetons, ${F}-fichiers { margin: 0 0 var(--sp-16); }
    ${F}-chiffres { display: grid; grid-template-columns: 1fr 1fr; gap: var(--sp-12); margin: 0 0 var(--sp-16); }
    ${F}-chiffre { display: flex; flex-direction: column; gap: var(--sp-2); }
    ${F}-lib { font-size: 12.5px; line-height: 16px; color: var(--text-3); }
    ${F}-val { font-size: 15px; line-height: 20px; font-weight: 600; color: var(--text); font-variant-numeric: tabular-nums; }
    ${F}-inconnu { color: var(--text-3); font-weight: 400; }
    ${F}-bloc { margin: 0 0 var(--sp-4); font-size: 12.5px; line-height: 16px; font-weight: 600; color: var(--text-2); }
    ${F}-mono, ${F}-heure, ${F}-cible, ${F}-texte code, ${F}-texte pre { font-family: var(--mono); font-size: 11.5px; line-height: 16px; }
    ${F}-fil-tete { display: flex; flex-wrap: wrap; align-items: center; gap: var(--sp-8); margin: 0 0 var(--sp-8); }
    ${F}-fil-tete h3 { margin: 0; font-size: 15px; line-height: 20px; font-weight: 600; }
    ${F}-compteur { font-size: 12.5px; line-height: 16px; color: var(--text-3); margin-right: auto; }
    ${F}-filtre { min-height: 28px; padding: var(--inset-pill); border: 0; border-radius: 999px; background: rgba(var(--ink), .06); color: var(--text-2);
      font-size: 11.5px; font-weight: 500; }
    ${F}-filtre[aria-pressed=true] { background: var(--on); color: var(--on-text); }
    ${F}-filtre[aria-pressed=true]::before { content: '\\2713\\00a0'; }
    ${F}-coupe { margin: 0 0 var(--sp-8); font-size: 12.5px; line-height: 16px; color: var(--text-3); }
    ${F}-mandat, ${F}-plus, ${F}-reessayer, ${F}-tout { margin: 0 0 var(--sp-8); padding: var(--inset-pill); border: 0; border-radius: var(--r-ctl);
      background: rgba(var(--ink), .06); color: var(--text-2); font-size: 12.5px; }
    ${F}-mandat-corps { margin: 0 0 var(--sp-8); padding: var(--inset-box); border-radius: var(--r-ctl); background: var(--well);
      white-space: pre-wrap; overflow-wrap: anywhere; }
    ${F}-lignes { margin: 0; padding: 0; list-style: none; }
    ${F}-ligne { display: grid; grid-template-columns: calc(var(--sp-24) * 3) 16px minmax(0, 1fr); gap: var(--sp-8); align-items: start; padding: var(--sp-4) 0;
      font-size: 12.5px; line-height: 20px; color: var(--text); }
    ${F}-ligne:hover { background: rgba(var(--ink), .06); }
    ${F}-ligne:has(.vf-fiche-echec):hover { background: none; }
    ${F}-heure { color: var(--text-3); }
    ${F}-ligne:has(.vf-fiche-echec):hover .vf-fiche-heure { color: var(--text); }
    ${F}-glyphe svg { width: 16px; height: 16px; fill: none; stroke: currentColor; stroke-width: 1.5; stroke-linecap: round; stroke-linejoin: round; }
    ${F}-glyphe svg.vf-fiche-croix { color: var(--sev-high); }
    ${F}-texte p { margin: 0 0 var(--sp-4); }
    ${F}-texte pre { margin: var(--sp-4) 0; padding: var(--inset-row); border-radius: var(--r-ctl); background: var(--well);
      white-space: pre-wrap; overflow-wrap: anywhere; }
    ${F}-texte code { padding: var(--sp-2) var(--sp-6); border-radius: 999px; background: rgba(var(--ink), .05); }
    ${F}-echec { color: var(--text-2); }
    ${F}-replie ${F}-texte { max-height: 120px; overflow: hidden; }
    ${F}-bas { position: sticky; bottom: var(--sp-16); display: flex; align-items: center; gap: var(--sp-8); padding-top: var(--sp-8); }
    ${F}-direct { min-height: 28px; padding: var(--inset-pill); border: 0; border-radius: 999px; background: var(--on); color: var(--on-text);
      font-size: 11.5px; font-weight: 500; }
    ${F}-annonce { font-size: 12.5px; color: var(--text-2); }
    ${F}-fantome { height: 20px; margin: 0 0 var(--sp-8); border-radius: var(--r-ctl); background: rgba(var(--ink), .06); }
    @media (max-width: 999px) { ${F}-corps { grid-template-columns: 280px minmax(0, 1fr); } }
    @media (max-width: 700px) {
      ${F} { height: auto; min-height: 0; }
      ${F}-corps { display: block; }
      ${F}-faits, ${F}-fil { overflow: visible; }
      ${F}-resume { display: flex; align-items: center; min-height: 44px; font-size: 12.5px; color: var(--text-2); }
      ${F}-retour, ${F}-filtre, ${F}-direct, ${F}-mandat, ${F}-plus, ${F}-reessayer, ${F}-tout { min-height: 44px; }
    }
  `;
  document.head.appendChild(st);
})();
