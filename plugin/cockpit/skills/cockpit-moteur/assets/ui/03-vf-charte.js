// VibeFlow (80-17, FORM-14, P80-D-20 : AUDC-F1, F3, F4) : la charte des finitions, dans un fichier à part (00-vibeflow.js tient sous le plafond de 299 lignes).
// Extension d'onglet (A51) : réexécutée à chaque arrivée, elle ne pose que sa feuille, à l'évaluation ; la portée de la coquille (vf-coquille-portee.js)
// retire la feuille au démontage, un seul élément `style[data-vf-charte]` vit donc à la fois. Ni écouteur, ni minuterie, ni observateur : les chevrons
// sont des pseudo-éléments (aucun nœud ajouté aux summary), dessinés par dégradés (aucune URL d'image, comme dans la feuille de la page du terminal).
//   F1 disclosures : les `summary` de « Détails techniques », de « Historique » (couloirs) et du menu du lancement perdent le triangle natif et portent
//      un chevron de 16 px de --text-3, tourné de 90° ouvert (150 ms, nul en mouvement réduit), sur une zone de 32 px (44 au toucher) ; l'anneau de focus
//      est décalé de -2. Les sections d'Équipe (.vf-termines) ont déjà leur chevron (71-vf-equipe-rendu.js) : elles ne sont pas reprises ici.
//      Sélecteur #vf-modele : apparence retirée, 28 px (36 au toucher), fond --raise, contour 1 px --hair-2, chevron bas, color-scheme du thème ;
//      désactivé en --text-4, sans opacité. Les règles se posent derrière `body` (ou un identifiant) pour passer devant celles de 00, 41 et 75.
//   F3 --hdr-btn : une seule hauteur de bouton d'en-tête (36 px en panneau latéral, 44 px en feuille de détail ou au pointeur grossier), l'ouvreur Git
//      (#vf-git-ouvreur) compris depuis 80-20 (P80-D-56) : son dessin la lit, sa zone d'appui reste de 44 × 44 (76-vf-git-entete.js).
//      Le bouton de thème la lit aussi (05-theme.js).
//   F4 chiffres des phrases : #vf-lock et les compteurs d'Équipe passent en police de texte, chiffres tabulaires, graisse 500 (70 et 71 restent intacts).
// Valeurs en dur seulement là où aucun jeton n'existe (boîte du chevron, hauteurs de contrôle) ; la page du terminal reprend celles du sélecteur dans sa
// propre feuille (assets/ui/terminal/q.css, autre origine).
(() => {
  if (!window.Floorplan) return;
  const DIS = ['body #panel details.vf-tech > summary', 'body .vp-details > summary', 'body [data-vf-lancer] details > summary'];
  const PETIT = [DIS[0], DIS[2]]; // « Historique » garde sa zone de 44 px (41-vf-projet-vue.js)
  const liste = (l, fin = '') => l.map((s) => s + fin).join(', ');
  const TRAIT = 'transparent calc(50% - .75px), var(--vf-chev) calc(50% - .75px), var(--vf-chev) calc(50% + .75px), transparent calc(50% + .75px)';
  const style = document.createElement('style');
  style.setAttribute('data-vf-charte', '');
  style.textContent = `
    /* F1 : la disclosure ; le chevron est un V de deux traits en dégradé (« > » fermé, « v » ouvert après 90°) */
    :root { --vf-trait: transparent calc(50% - .75px), currentcolor calc(50% - .75px), currentcolor calc(50% + .75px), transparent calc(50% + .75px); }
    ${liste(DIS)} { list-style: none; display: flex; align-items: center; gap: var(--sp-6); cursor: pointer; }
    ${liste(DIS, '::-webkit-details-marker')} { display: none; }
    ${liste(DIS, '::marker')} { content: ""; }
    ${liste(PETIT)} { min-height: 32px; padding-top: 0; padding-bottom: 0; }
    body .vp-details > summary { justify-content: flex-start; }
    body .vp-details > summary .vp-n { margin-left: auto; }
    ${liste(DIS, '::before')} { content: ""; flex: none; width: 16px; height: 16px; color: var(--text-3); transition: transform 150ms var(--ease);
      background: linear-gradient(to bottom left, var(--vf-trait)) 6px 3px / 5px 5px no-repeat,
        linear-gradient(to bottom right, var(--vf-trait)) 6px 8px / 5px 5px no-repeat; }
    body details[open] > summary::before { transform: rotate(90deg); }
    ${liste(DIS, ':focus-visible')} { outline-offset: -2px; }
    @media (pointer: coarse) { ${liste(PETIT)} { min-height: 44px; } }
    @media (prefers-reduced-motion: reduce) { ${liste(DIS, '::before')} { transition: none; } }
    /* F1 : le sélecteur du modèle de l'agent (barre de question) ; chevron bas en dégradé, jamais une image */
    body #vf-modele { appearance: none; -webkit-appearance: none; box-sizing: border-box; height: 28px; max-width: 140px; text-overflow: ellipsis;
      padding: 0 var(--sp-24) 0 var(--sp-8); border: 1px solid var(--hair-2); border-radius: 8px; background-color: var(--raise); color-scheme: inherit;
      --vf-chev: var(--text-3); --vf-trait: ${TRAIT};
      background-image: linear-gradient(to bottom left, var(--vf-trait)), linear-gradient(to bottom right, var(--vf-trait));
      background-repeat: no-repeat; background-size: 5px 5px; background-position: right 14px center, right 9px center; }
    body #vf-modele:disabled { color: var(--text-4); opacity: 1; cursor: default; --vf-chev: var(--text-4); --vf-trait: ${TRAIT}; }
    @media (pointer: coarse) { body #vf-modele { height: 36px; } }
    /* F3 : une seule hauteur de bouton d'en-tête */
    :root { --hdr-btn: 36px; }
    @media (max-width: 999px), (pointer: coarse) { :root { --hdr-btn: 44px; } }
    header .hr .btn, header #hdr-ext > button { height: var(--hdr-btn); }
    header #theme-toggle { min-width: var(--hdr-btn); }
    @media (min-width: 1000px) and (max-width: 1279px) and (not (pointer: coarse)) {
      header #theme-toggle { width: var(--hdr-btn); padding: 0; justify-content: center; } /* le mot du thème ne tient pas ici : l'icône seule, carrée */
    }
    /* F4 : les chiffres d'une phrase se lisent dans la police du texte, alignés ; le mono reste pour sha, chemins, branche et touches */
    header #vf-lock { font-family: inherit; font-variant-numeric: tabular-nums; font-weight: 500; }
    body .aw-driver .n, body .r-t, body .r-meta b, body .r-verr .n { font-family: inherit; font-variant-numeric: tabular-nums; font-weight: 500; }
  `;
  document.head.appendChild(style);
})();
