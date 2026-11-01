// VibeFlow (CKPT-12, P67-D-21) : la fenêtre du cockpit est ajustable. Aucune modification du viewer : une feuille de style posée par
// cette extension, qui prend le pas sur la grille de l'en-tête du viewer (trois colonnes `1fr auto 1fr`, qui se disloque dès que le nom du
// projet ou le badge « au travail » sont longs) et sur la barre de question (largeur fixe moins 320 px). Mesuré par
// test-cockpit-responsive.sh : de 1 024 à 2 560 px, au chargement comme au redimensionnement, aucune superposition, aucun rognage.
//   - en-tête (>= 1 000 px) : une ligne souple ; la gauche cède la première (nom de projet tronqué avec une ellipse), la recherche garde 200 px,
//     la droite garde son contenu ; sous 1 600 px les boutons d'action passent en icône seule (le libellé reste dans l'infobulle) ;
//   - zoom au-dessus de la barre de question jusqu'à 1 279 px (comme le viewer le fait déjà sur écran tactile) ;
//   - logo VibeFlow : le viewer inverse le logo clair du thème (il attend un logo blanc) ; nos deux logos ont déjà le bon contraste ;
//   - sous 1 000 px : la barre de question range l'invite sur sa propre ligne ; sous 700 px le fil d'Ariane cède sa place au zoom.
(() => {
  const style = document.createElement('style');
  style.textContent = `
    .brand .mark, :root[data-theme="light"] .brand .mark, :root[data-theme="light"] #madewith .mark { filter: none !important; }
    @media (min-width: 1280px), (min-width: 1000px) and (pointer: fine) {
      header { display: flex; grid-template-columns: none; }
      header .hl { flex: 1 1 0; min-width: 300px; }
      header .hc { flex: 0 1 400px; min-width: 200px; justify-content: stretch; }
      header .hr { flex: 1 1 0; min-width: min-content; }
      header .brand { flex: 0 6 auto; min-width: 84px; }
      header #proj-name { min-width: 0; overflow: hidden; text-overflow: ellipsis; }
      header .vf-tabs, header #btn-up { flex: none; }
      header #crumbs { flex: 0 1 auto; min-width: 0; }
      header #search-btn { width: 100%; min-width: 0; overflow: hidden; }
      header #search-btn .st { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    }
    @media (max-width: 1599px) and (min-width: 1280px), (max-width: 1599px) and (min-width: 1000px) and (pointer: fine) {
      .hr .btn { position: relative; }
      .hr .btn:not(.icon):not(#vf-lock) { width: 36px; padding: 0; justify-content: center; }
      .hr .btn:not(#vf-lock) .bl { display: none; }
      .hr .btn .badge { position: absolute; top: 2px; right: 0; }
    }
    @media (min-width: 1000px) and (max-width: 1279px) {
      #zoom { left: auto; right: calc(var(--pw) + 16px); bottom: auto; top: calc(var(--hh, 64px) + 8px); flex-direction: column; border-radius: 26px; }
      #context { max-width: min(520px, calc(100% - var(--pw) - 104px)); }
      #ask { width: min(700px, calc(100% - var(--pw) - 48px)); }
    }
    @media (max-width: 999px) { #ask-input { flex: 1 1 100%; } }
    @media (max-width: 700px) { header #crumbs { display: none; } }
  `;
  document.head.appendChild(style);
})();
