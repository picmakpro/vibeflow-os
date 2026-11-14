// VibeFlow (73-04) : feuille de la régie (onglet Équipe), jetons existants seuls ; toutes les règles de masquage vivent sous body.vf-regie-montee.
// Inerte tant que la page de la régie (73-05) n'a pas posé cette classe. Aucun style de bouton neuf : le .btn doux du viewer, 44 px en pointer: coarse.
(() => {
  if (typeof document === 'undefined' || !document.head || document.head.querySelector('style[data-vf-regie]')) return;
  const st = document.createElement('style');
  st.setAttribute('data-vf-regie', '');
  st.textContent = `
    /* Q9 et P73-D-19 : monochrome, la forme et le mot portent l'état ; ni fond teinté, ni liseré, ni anneau, ni halo */
    body.vf-tab-equipe.vf-regie-montee #stage, body.vf-tab-equipe.vf-regie-montee #zoom, body.vf-tab-equipe.vf-regie-montee #z-fit,
    body.vf-tab-equipe.vf-regie-montee #results, body.vf-tab-equipe.vf-regie-montee #crumbs { display: none; }
    /* le contenu par défaut du moteur (Base de code, Santé) n'a pas sa place sur Équipe ; la feuille ne s'affiche que pour le lecteur de repli
       (.vf-rg-lecteur) */
    body.vf-tab-equipe.vf-regie-montee #panel:not(.vf-rg-lecteur) { display: none; }
    body.vf-regie-montee.vf-git-ouvert #vf-equipe-entete { opacity: 0; pointer-events: none; }
    body.vf-regie-montee { overflow-y: auto; }
    body.vf-regie-montee #vf-equipe { --fil: rgba(var(--ink), .2); box-sizing: border-box; max-width: 960px; margin: 0; color: var(--text);
      padding-inline: var(--edge); padding-top: calc(var(--hh, 4rem) + var(--gap-section)); padding-bottom: var(--gap-section); }
    body.vf-regie-montee #vf-equipe[aria-busy=true] { color: var(--text-3); }
    body.vf-regie-montee #vf-equipe-entete { margin: 0 0 var(--gap-section); }
    body.vf-regie-montee #vf-equipe-entete h1 { margin: 0; font-size: 24px; line-height: 30px; font-weight: 600; letter-spacing: -.025em; color: var(--text); }
    body.vf-regie-montee .vf-rg-sous { margin: var(--sp-4) 0 0; font-size: 13.5px; line-height: 20px; color: var(--text-2); }
    body.vf-regie-montee .vf-rg-verrou { margin: var(--sp-8) 0 0; font-size: 12px; line-height: 16px; color: var(--text-2); }
    body.vf-regie-montee .vf-rg-direct { margin: var(--sp-4) 0 0; font-size: 12px; line-height: 16px; color: var(--text-3); }
    /* une section : surface, rayon et ombre de carte, lignes séparées par un filet (aucun gap ni marge qui s'additionne) */
    body.vf-regie-montee .vf-rg-sec { margin: 0 0 var(--gap-section); }
    body.vf-regie-montee .vf-rg-tete { display: flex; align-items: center; gap: var(--sp-8); margin: 0 0 var(--sp-8); }
    body.vf-regie-montee .vf-rg-tete h2 { margin: 0; font-size: 15px; line-height: 20px; font-weight: 600; color: var(--text); }
    body.vf-regie-montee .vf-rg-sec-avous .vf-rg-tete h2 { font-size: 18px; line-height: 24px; }
    body.vf-regie-montee .vf-rg-compte { font-size: 11px; line-height: 16px; padding: var(--inset-pill); border-radius: 999px; background: var(--note-bg);
      color: var(--text-3); font-variant-numeric: tabular-nums; }
    body.vf-regie-montee .vf-rg-aide { margin: 0; font-size: 12px; line-height: 16px; color: var(--text-3); }
    body.vf-regie-montee .vf-rg-corps { margin: 0; padding: var(--sp-8); list-style: none; background: var(--surface); border-radius: var(--r-card);
      box-shadow: var(--shadow-card); }
    body.vf-regie-montee .vf-rg-corps ul { margin: 0; padding: 0; list-style: none; }
    body.vf-regie-montee .vf-rg-vide { margin: 0; padding: var(--sp-12); font-size: 12px; line-height: 16px; color: var(--text-3); }
    body.vf-regie-montee .vf-rg-pied { margin: var(--sp-8) 0 0; font-size: 12px; line-height: 16px; color: var(--text-3); }
    body.vf-regie-montee .vf-rg-source { margin: var(--gap-section) 0 0; font-size: 12px; line-height: 16px; color: var(--text-4); }
    body.vf-regie-montee .vf-rg-note { margin: 0 0 var(--gap-section); padding: var(--inset-box); border-radius: var(--r-ctl); background: var(--note-bg);
      font-size: 12px; line-height: 16px; color: var(--text-2); }
    /* une ligne : cinq colonnes (glyphe, qui, quoi, durée, droite), 44 px au moins */
    body.vf-regie-montee .vf-rg-lig + .vf-rg-lig { border-top: 1px solid var(--hair); }
    body.vf-regie-montee .vf-rg-row { display: grid; grid-template-columns: 16px minmax(0, 1.3fr) minmax(0, 1.2fr) auto 152px; column-gap: var(--sp-12);
      align-items: start; box-sizing: border-box; min-height: 44px; padding: var(--inset-row); border-radius: var(--r-ctl); }
    body.vf-regie-montee .vf-rg-row:hover { background: rgba(var(--ink), .05); }
    body.vf-regie-montee .vf-rg-row .aw-g { margin-top: var(--sp-2); }
    body.vf-regie-montee .vf-rg-qui, body.vf-regie-montee .vf-rg-quoi { min-width: 0; display: flex; flex-direction: column; gap: var(--sp-2); }
    body.vf-regie-montee .vf-rg-nom { font-size: 13px; line-height: 20px; font-weight: 500; color: var(--text); overflow-wrap: anywhere; }
    body.vf-regie-montee .vf-rg-sess .vf-rg-nom { font-weight: 600; }
    body.vf-regie-montee .vf-rg-role { margin-right: var(--sp-6); font: 500 12px/16px var(--mono, monospace); color: var(--text-2); }
    body.vf-regie-montee .vf-rg-l2, body.vf-regie-montee .vf-rg-det { font-size: 12px; line-height: 16px; color: var(--text-3); overflow: hidden;
      text-overflow: ellipsis; white-space: nowrap; }
    body.vf-regie-montee .vf-rg-l2 .vf-link { font: 500 12px/16px var(--mono, monospace); }
    body.vf-regie-montee .vf-rg-mot { font-size: 13px; line-height: 20px; color: var(--text); }
    body.vf-regie-montee [data-vf-etat=attend] .vf-rg-mot, body.vf-regie-montee [data-vf-etat=attente] .vf-rg-mot,
    body.vf-regie-montee [data-vf-etat=repos] .vf-rg-mot { color: var(--text-2); }
    body.vf-regie-montee .vf-rg-fort .vf-rg-mot, body.vf-regie-montee [data-vf-etat=orphelin] .vf-rg-mot { font-weight: 600; }
    body.vf-regie-montee .vf-rg-dur { min-width: 96px; text-align: right; font: 500 12px/20px var(--mono, monospace); color: var(--text-3);
      font-variant-numeric: tabular-nums; white-space: nowrap; }
    body.vf-regie-montee .vf-rg-dur i { font-style: normal; font-family: var(--sans); font-weight: 400; }
    body.vf-regie-montee .vf-rg-act { min-width: 0; display: flex; justify-content: flex-end; }
    body.vf-regie-montee .vf-rg-grise .vf-rg-nom, body.vf-regie-montee .vf-rg-grise .vf-rg-mot { color: var(--text-3); font-weight: 400; }
    /* l'arbre : un enfant sous son parent, indenté par niveau, deux niveaux au plus */
    body.vf-regie-montee .vf-rg-n1 > .vf-rg-row { padding-inline-start: calc(var(--sp-12) + var(--sp-16)); }
    body.vf-regie-montee .vf-rg-n2 > .vf-rg-row { padding-inline-start: calc(var(--sp-12) + var(--sp-16) + var(--sp-16)); }
    /* le nom est le bouton d'ouverture : texte nu, sans cadre ; le caret n'existe que sur un parent et reste nu, de la couleur du nom */
    body.vf-regie-montee .vf-rg-l1 { display: flex; align-items: center; gap: var(--sp-4); min-width: 0; }
    body.vf-regie-montee .vf-rg-tog {
      min-width: 0; margin: 0; padding: 0; border: 0; background: none; font: inherit; color: inherit; text-align: start; cursor: pointer;
      border-radius: 8px;
    }
    body.vf-regie-montee .vf-rg-tog:hover .vf-rg-nom { text-decoration: underline; }
    body.vf-regie-montee .vf-rg-caret {
      flex: none; width: 44px; height: 44px; margin-block: calc(-1 * var(--sp-12)); display: flex; align-items: center; justify-content: center;
      padding: 0; border: 0; background: none; color: var(--text); cursor: pointer; border-radius: 8px; }
    body.vf-regie-montee .vf-rg-grise .vf-rg-caret { color: var(--text-3); }
    body.vf-regie-montee .vf-rg-caret:hover { background: rgba(var(--ink), .05); }
    body.vf-regie-montee .vf-rg-caret[aria-expanded=true] .r-caret { transform: rotate(90deg); }
    body.vf-regie-montee .vf-rg-replie { display: none; }
    /* le fil de l'arbre : 1 px (--fil), coude de rayon 8 ; c1 et c2 = le fil de ce niveau se poursuit sous la ligne ; les enfants n'ont pas de filet
       entre eux */
    body.vf-regie-montee .vf-rg-lig.vf-rg-n1, body.vf-regie-montee .vf-rg-lig.vf-rg-n2 { position: relative; border-top: 0; }
    body.vf-regie-montee .vf-rg-n1::after, body.vf-regie-montee .vf-rg-n2::after {
      content: ""; position: absolute; top: 0; width: var(--sp-8); height: calc(var(--sp-16) + var(--sp-2));
      border-left: 1px solid var(--fil); border-bottom: 1px solid var(--fil); border-bottom-left-radius: 8px; pointer-events: none; }
    body.vf-regie-montee .vf-rg-n1::after { left: calc(var(--sp-12) + var(--sp-8)); }
    body.vf-regie-montee .vf-rg-n2::after { left: calc(var(--sp-12) + var(--sp-8) + var(--sp-16)); }
    body.vf-regie-montee .vf-rg-n1.vf-rg-c1::before, body.vf-regie-montee .vf-rg-n2.vf-rg-c1::before {
      content: ""; position: absolute; bottom: 0; left: calc(var(--sp-12) + var(--sp-8));
      border-left: 1px solid var(--fil); pointer-events: none; }
    body.vf-regie-montee .vf-rg-n1.vf-rg-c1::before { top: calc(var(--sp-16) + var(--sp-2)); }
    body.vf-regie-montee .vf-rg-n2.vf-rg-c1::before { top: 0; }
    body.vf-regie-montee .vf-rg-n2.vf-rg-c2 > .vf-rg-row::before {
      content: ""; position: absolute; bottom: 0; top: calc(var(--sp-16) + var(--sp-2)); left: calc(var(--sp-12) + var(--sp-8) + var(--sp-16));
      border-left: 1px solid var(--fil); pointer-events: none; }
    body.vf-regie-montee .vf-rg-n2.vf-rg-c2 > .vf-rg-row { position: relative; }
    /* détail en flux : --raise, --r-ctl, --inset-box, gap --sp-8, 12 px --text-2, aligné sur la colonne du nom */
    body.vf-regie-montee .vf-rg-plus {
      display: flex; flex-direction: column; gap: var(--sp-8); box-sizing: border-box;
      margin: 0 var(--sp-12) var(--sp-8) calc(var(--sp-12) + var(--sp-16) + var(--sp-12));
      padding: var(--inset-box); border-radius: var(--r-ctl); background: var(--raise); font-size: 12px; line-height: 16px; color: var(--text-2); }
    body.vf-regie-montee .vf-rg-n1 > .vf-rg-plus { margin-left: calc(var(--sp-12) + var(--sp-16) + var(--sp-12) + var(--sp-16)); }
    body.vf-regie-montee .vf-rg-n2 > .vf-rg-plus { margin-left: calc(var(--sp-12) + var(--sp-16) + var(--sp-12) + var(--sp-16) + var(--sp-16)); }
    body.vf-regie-montee .vf-rg-plus .vf-rg-l2 { margin: 0; white-space: normal; overflow-wrap: anywhere; color: var(--text-2); }
    /* arbres de travail (pied) : gabarit du tiroir Git, bloc replié lisible, pastilles en texte neutre */
    body.vf-regie-montee .vf-rg-arbres > summary {
      display: flex; align-items: center; gap: var(--sp-8); min-height: 44px; margin: 0; cursor: pointer; font-size: 15px; line-height: 20px;
      font-weight: 600; color: var(--text); list-style: none; border-radius: 8px; }
    body.vf-regie-montee .vf-rg-arbres > summary::-webkit-details-marker { display: none; }
    body.vf-regie-montee .vf-rg-arbres > summary .r-caret { transition: transform .15s var(--ease); color: var(--text); }
    body.vf-regie-montee .vf-rg-arbres[open] > summary .r-caret { transform: rotate(90deg); }
    body.vf-regie-montee .vf-rg-arbres > summary:focus-visible { outline: 2px solid var(--ring); outline-offset: -2px; }
    body.vf-regie-montee .vf-rg-arbres-corps { margin: 0; }
    body.vf-regie-montee .vf-rg-arbres-liste { margin: 0; padding: 0; list-style: none; }
    body.vf-regie-montee .vf-rg-arbre {
      display: flex; flex-wrap: wrap; align-items: center; gap: var(--sp-4) var(--sp-8); box-sizing: border-box; min-height: 44px;
      padding: var(--inset-row);
    }
    body.vf-regie-montee .vf-rg-arbre-nom { font: 500 12px/16px var(--mono, monospace); color: var(--text); overflow-wrap: anywhere; }
    body.vf-regie-montee .vf-rg-arbre-br { font: 400 12px/16px var(--mono, monospace); color: var(--text-3); overflow-wrap: anywhere; }
    body.vf-regie-montee .vf-rg-arbre-pastille { font-size: 12px; line-height: 16px; color: var(--text-2); font-variant-numeric: tabular-nums; }
    /* ligne de mission et marques de gouvernance : texte neutre, glyphe devant, mot en 600, ni alerte ni fond ; elles ne reclassent rien */
    body.vf-regie-montee .vf-rg-mission { display: flex; flex-wrap: wrap; align-items: center; gap: var(--sp-4) var(--sp-12); padding: var(--inset-row);
      font-size: 12px; line-height: 16px; color: var(--text-2); }
    body.vf-regie-montee .vf-rg-marque { display: inline-flex; align-items: center; gap: var(--sp-6); font-weight: 600; color: var(--text); }
    /* glyphes d'état : ceux du lot 0 (71-vf-equipe-rendu.js), teintes reprises du tiroir ; sur --surface seulement */
    body.vf-regie-montee #vf-equipe .aw-g { width: 16px; height: 16px; flex: none; display: block; fill: none; stroke: currentColor; stroke-width: 1.75;
      stroke-linecap: round; stroke-linejoin: round; }
    body.vf-regie-montee [data-vf-etat=actif] > .vf-rg-row > .aw-g { color: var(--st-active); }
    body.vf-regie-montee [data-vf-etat=termine] > .vf-rg-row > .aw-g { color: var(--st-done); }
    body.vf-regie-montee [data-vf-etat=attend] > .vf-rg-row > .aw-g, body.vf-regie-montee [data-vf-etat=attente] > .vf-rg-row > .aw-g,
    body.vf-regie-montee [data-vf-etat=repos] > .vf-rg-row > .aw-g,
    body.vf-regie-montee [data-vf-etat=surveiller] > .vf-rg-row > .aw-g, body.vf-regie-montee .vf-rg-marque .aw-g { color: var(--text-2); }
    body.vf-regie-montee [data-vf-etat=orphelin] > .vf-rg-row > .aw-g { color: var(--text-3); }
    body.vf-regie-montee [data-vf-etat=actif] > .vf-rg-row > .aw-g.aw-pulse { animation: vfregie-respire 2.4s ease-in-out infinite; }
    @keyframes vfregie-respire { 50% { transform: scale(.82); } }
    body.vf-regie-montee a.vf-rg-row:focus-visible, body.vf-regie-montee .vf-rg-tog:focus-visible,
    body.vf-regie-montee .vf-rg-caret:focus-visible { outline: 2px solid var(--ring); outline-offset: -2px; border-radius: 8px; }
    body.vf-regie-montee .vf-rg-tete h2:focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; border-radius: 8px; }
    /* de 701 à 999 px (et tactile sous 1 280 px) : « droite » sous « quoi », trois colonnes ; jusqu'à 700 px : une colonne, un niveau d'indentation */
    @media (max-width: 999px), (pointer: coarse) and (max-width: 1279px) {
      body.vf-regie-montee .vf-rg-row { grid-template-columns: 16px minmax(0, 1fr) auto; row-gap: var(--sp-4);
        grid-template-areas: "g qui dur" ". quoi quoi" ". act act"; }
      body.vf-regie-montee .vf-rg-row > .aw-g { grid-area: g; } body.vf-regie-montee .vf-rg-qui { grid-area: qui; }
      body.vf-regie-montee .vf-rg-quoi { grid-area: quoi; } body.vf-regie-montee .vf-rg-dur { grid-area: dur; }
      body.vf-regie-montee .vf-rg-act { grid-area: act; }
    }
    @media (max-width: 700px) {
      body.vf-regie-montee .vf-rg-row { grid-template-columns: 16px minmax(0, 1fr); grid-template-areas: "g qui" ". quoi" ". dur" ". act"; }
      body.vf-regie-montee .vf-rg-dur { text-align: left; } body.vf-regie-montee .vf-rg-act { justify-content: flex-start; }
      body.vf-regie-montee .vf-rg-n2 > .vf-rg-row { padding-inline-start: calc(var(--sp-12) + var(--sp-16)); }
    }
    @media (pointer: coarse) { body.vf-regie-montee #vf-equipe .btn { height: 44px; } }
    @media (prefers-reduced-motion: reduce) {
      body.vf-regie-montee [data-vf-etat=actif] .aw-g.aw-pulse { animation: none; } body.vf-regie-montee .r-caret { transition: none; }
    }
  `;
  document.head.appendChild(st);
})();
