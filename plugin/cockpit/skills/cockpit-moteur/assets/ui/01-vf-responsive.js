// VibeFlow (CKPT-12, P67-D-21) : la fenêtre du cockpit est ajustable. Aucune modification du viewer : une feuille de style posée par
// cette extension, qui prend le pas sur la grille de l'en-tête du viewer (trois colonnes `1fr auto 1fr`, qui se disloque dès que le nom du
// projet ou le badge « au travail » sont longs) et sur la barre de question (largeur fixe moins 320 px). Mesuré par
// test-cockpit-responsive.sh : de 1 024 à 2 560 px, au chargement comme au redimensionnement, aucune superposition, aucun rognage.
//   - « souris » = tout sauf un écran tactile : `not (pointer: coarse)` est le complément exact de la règle tactile du viewer (`pointer: coarse` sous 1 280 px). Jamais `pointer: fine`, faux
//     sans périphérique de pointage (Chrome headless sous Linux : `pointer: none`), où l'en-tête restait en grille et débordait à 1 024 px (CI, run 41370886002) ;
//   - en-tête (>= 1 000 px) : une ligne souple ; la gauche cède la première (nom de projet tronqué avec une ellipse), la recherche garde 200 px,
//     la droite garde son contenu ; sous 1 600 px les boutons d'action passent en icône seule (le libellé reste dans l'infobulle) ;
//   - bornes mesurées à 1 024 px sur l'onglet Code AVEC ses boutons optionnels (Travail récent, Écrans) : aucun bouton ne sort de la fenêtre ;
//   - infobulle : tout bouton d'en-tête sans `title` reprend son libellé (le viewer n'en pose pas sur « Parcours »), car sous 1 600 px il n'est plus qu'une icône ;
//   - zoom au-dessus de la barre de question jusqu'à 1 279 px (comme le viewer le fait déjà sur écran tactile) ;
//   - logo VibeFlow : le viewer inverse le logo clair du thème (il attend un logo blanc) ; nos deux logos ont déjà le bon contraste ;
//   - sous 1 000 px : la barre de question range l'invite sur sa propre ligne ; sous 700 px le fil d'Ariane cède sa place au zoom.
//   - fil d'Ariane (O2, recette 2026-11-03 ; budget revu après la revue de la recette 3, F1/F2) : dès 1 280 px, la colonne gauche de l'en-tête prend la largeur naturelle de son contenu (`flex: 1 1 auto`) et c'est la RECHERCHE qui cède
//     la première (poids de rétrécissement 100 000, jamais sous 200 px) ; le nom du projet (100 000) cède avant le fil (1) ; la colonne de droite garde son contenu (badge « au travail » compris). Le fil prend donc ce qui reste, jamais plus : aucun `min-width` n'est dérivé de sa largeur.
//     Dans le fil, ordre de troncature : le nom du projet, puis les segments LONGS du milieu (poids 100 000), puis le premier et le dernier longs (poids 1 : ils ne cèdent qu'une fois le milieu à son plancher, à un centième de pixel près : un poids égal à 1 contre 1 000 laissait rogner le nom du projet de 1 px à 1 440 px), chaque segment long gardant 64 px ; un segment COURT (moins de 12 caractères, soit 11 au plus)
//     ne rétrécit jamais (poids 0). Si, tous les longs réduits à leur plancher, le fil déborde encore, les segments du milieu sont masqués un à un (du plus proche du premier) derrière un « … » (infobulle : leurs noms) ; le premier et le dernier restent.
//     Le masquage ne joue qu'à partir de 1 280 px et se rejoue au rendu du fil, au changement de nom, à la mise à jour de la largeur de la colonne gauche (badge, redimensionnement) et au chargement des polices.
(() => {
  const style = document.createElement('style');
  style.textContent = `
    .brand .mark, :root[data-theme="light"] .brand .mark, :root[data-theme="light"] #madewith .mark { filter: none !important; }
    @media (min-width: 1280px), (min-width: 1000px) and (not (pointer: coarse)) {
      header { display: flex; grid-template-columns: none; }
      header .hl { flex: 1 1 0; min-width: 280px; } /* marque 84 + onglets 143 (trois onglets resserrés sous 1 280 px, 69-05) + remonter 36 + marges : le plus étroit qui ne rogne pas ; 300 faisait sortir de 12 px le dernier bouton à 1 024 px (onglet Code avec Travail récent et Écrans) */
      header .hc { flex: 0 1 400px; min-width: 200px; justify-content: stretch; }
      header .hr { flex: 1 1 0; min-width: min-content; }
      header .brand { flex: 0 6 auto; min-width: 84px; }
      header #proj-name { min-width: 0; overflow: hidden; text-overflow: ellipsis; }
      header .vf-tabs, header #btn-up { flex: none; }
      header #crumbs { flex: 0 1 auto; min-width: 0; }
      header #search-btn { width: 100%; min-width: 0; overflow: hidden; }
      header #search-btn .st { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    }
    @media (max-width: 1599px) and (min-width: 1280px), (max-width: 1599px) and (min-width: 1000px) and (not (pointer: coarse)) {
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
    @media (min-width: 1280px) {
      header .hl { flex: 1 1 auto; } /* sa largeur naturelle ; il cède après la recherche */
      header .hc { flex: 0 100000 400px; } /* la recherche rétrécit la première, jusqu'à son plancher de 200 px */
      header .brand { flex: 0 100000 auto; } /* le nom du projet cède avant le fil (la somme des poids non gelés doit atteindre 1, sinon la flexbox n'absorbe qu'une fraction du manque) */
      header #crumbs { flex: 0 1 auto; }
      header #crumbs button:not([data-vf-court]) { flex: 0 1 auto; min-width: 64px; }
      header #crumbs button:not([data-vf-court]):not(:first-child):not(.cur) { flex: 0 100000 auto; }
      header #crumbs button[data-vf-court] { flex: 0 0 auto; } /* un segment court n'est jamais rogné */
      header #crumbs [data-vf-masque] { display: none; }
      header #crumbs .vf-ell { flex: none; color: var(--text-4); padding: 0 6px; cursor: default; }
    }
    @media (max-width: 999px) { #ask-input { flex: 1 1 100%; } }
    @media (max-width: 700px) { header #crumbs { display: none; } }
  `;
  document.head.appendChild(style);
  // fil d'Ariane : étiquette les segments courts (moins de 12 caractères), puis masque derrière « … » les segments du milieu tant que le fil déborde (CSS : un segment long garde 64 px)
  const fil = document.getElementById('crumbs'), nomProjet = document.getElementById('proj-name'), gauche = document.querySelector('header .hl');
  let obs = null;
  const ajuste = () => {
    if (!fil) return;
    if (obs) obs.disconnect(); // nos propres retouches du fil ne relancent pas l'ajustement
    for (const e of fil.querySelectorAll('[data-vf-masque]')) e.removeAttribute('data-vf-masque');
    fil.querySelector('.vf-ell')?.remove();
    const bs = [...fil.querySelectorAll('button')];
    for (const b of bs) { if (b.textContent.trim().length < 12) b.setAttribute('data-vf-court', ''); else b.removeAttribute('data-vf-court'); }
    if (matchMedia('(min-width: 1280px)').matches && bs.length > 2) {
      const ell = document.createElement('span'); ell.className = 'vf-ell'; ell.textContent = '…'; const noms = [];
      for (let k = 1; k < bs.length - 1 && fil.scrollWidth > fil.clientWidth + 1; k++) {
        const sep = bs[k].previousElementSibling;
        if (k === 1) fil.insertBefore(ell, bs[1]); else if (sep) sep.setAttribute('data-vf-masque', '');
        bs[k].setAttribute('data-vf-masque', ''); noms.push(bs[k].textContent.trim()); ell.title = noms.join(' / '); ell.setAttribute('aria-label', ell.title);
      }
    }
    if (obs) { obs.takeRecords(); obs.observe(fil, { childList: true, characterData: true, subtree: true }); }
  };
  if (fil) {
    obs = new MutationObserver(ajuste); ajuste();
    if (nomProjet) new MutationObserver(ajuste).observe(nomProjet, { childList: true, characterData: true, subtree: true });
    if (gauche && window.ResizeObserver) new ResizeObserver(ajuste).observe(gauche);
    window.addEventListener('resize', ajuste); window.addEventListener('load', ajuste); if (document.fonts?.ready) document.fonts.ready.then(ajuste);
  }
  // infobulle des boutons d'en-tête passés en icône seule : le libellé (traduit, donc relu après le traducteur) ; ne remplace jamais un title existant
  const hd = document.querySelector('header');
  const infobulles = () => { for (const b of hd.querySelectorAll('button')) { if (b.getAttribute('title')) continue; const t = b.getAttribute('aria-label') || b.querySelector('.bl')?.textContent.trim(); if (t) b.setAttribute('title', t); } };
  if (hd) { infobulles(); new MutationObserver(infobulles).observe(hd, { childList: true, subtree: true, attributes: true, attributeFilter: ['aria-label', 'title'] }); }
})();
