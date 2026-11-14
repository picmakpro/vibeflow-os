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
//   - zoom en rangée au bord gauche, au-dessus de la pastille « Terminal » et de la barre de question, de 701 à 1 279 px (comme dès 1 280 px) ;
//   - logo VibeFlow : le viewer inverse le logo clair du thème (il attend un logo blanc) ; nos deux logos ont déjà le bon contraste ;
//   - sous 1 000 px : la barre de question range l'invite sur sa propre ligne ; sous 700 px le fil d'Ariane cède sa place au zoom.
//   - fil d'Ariane (O2, recette 2026-11-03 ; budget revu après la revue de la recette 3, F1/F2) : dès 1 280 px, la colonne gauche de l'en-tête prend la largeur naturelle de son contenu (`flex: 1 1 auto`) et c'est la RECHERCHE qui cède
//     la première (poids de rétrécissement 100 000, jamais sous 200 px) ; le nom du projet (100 000) cède avant le fil (1) ; la colonne de droite garde son contenu (badge « au travail » compris). Le fil prend donc ce qui reste, jamais plus : aucun `min-width` n'est dérivé de sa largeur.
//     Dans le fil, ordre de troncature : le nom du projet, puis les segments LONGS du milieu (poids 100 000), puis le premier et le dernier longs (poids 1 : ils ne cèdent qu'une fois le milieu à son plancher, à un centième de pixel près : un poids égal à 1 contre 1 000 laissait rogner le nom du projet de 1 px à 1 440 px), chaque segment long gardant 64 px ; un segment COURT (moins de 12 caractères, soit 11 au plus)
//     ne rétrécit jamais (poids 0). Si, tous les longs réduits à leur plancher, le fil déborde encore, les segments du milieu sont masqués un à un (du plus proche du premier) derrière un « … » (infobulle : leurs noms) ; le premier et le dernier restent.
//     Le masquage ne joue qu'à partir de 1 280 px et se rejoue au rendu du fil, au changement de nom, à la mise à jour de la largeur de la colonne gauche (badge, redimensionnement) et au chargement des polices.
//   - sous 1 280 px (PU-G-001, PU-G-002, coque étroite 2026-11-06) : la vue d'ensemble s'écrit « Ensemble » (le nom entier reste le nom accessible) ; le niveau COURANT du fil est toujours entier (flèche « Remonter » + niveau), les niveaux d'avant cèdent d'abord (masqués un à un, du plus proche de la racine), puis, de 1 000 à 1 279 px
//     (souris), le nom du dépôt cède au niveau courant tant qu'on est dans un dossier ; à la racine le nom du dépôt garde sa place et le libellé « Ensemble » est masqué plutôt que rogné. Le bouton Thème passe à 36 px (comme les autres boutons de la rangée) : 8 px rendus au nom ; l'ouvreur Git garde ses 44 px (P78-D-34).
(() => {
  const SESSIONS = 'M6 2.5a2.75 2.75 0 1 0 0 5.5 2.75 2.75 0 0 0 0-5.5zM1 14c0-2.8 2.2-4.5 5-4.5s5 1.7 5 4.5z'
    + 'M11.5 3.5a2.2 2.2 0 1 0 0 4.4 2.2 2.2 0 0 0 0-4.4zM12.2 9.7c1.8.3 3.3 1.6 3.3 4.3h-2.8c0-1.8-.4-3.2-.5-4.3z';
  const style = document.createElement('style');
  style.textContent = `
    .brand .mark, :root[data-theme="light"] .brand .mark, :root[data-theme="light"] #madewith .mark { filter: none !important; }
    @media (min-width: 1280px), (min-width: 1000px) and (not (pointer: coarse)) {
      header { display: flex; grid-template-columns: none; }
      header .hl { flex: 1 1 0; min-width: 342px; } /* P70-D-16 : marque 84 + écart 4 + marge des onglets 12 + onglets 196 (13 px, rail à 4 px, padding 12 px : 124 de texte, rail et écarts + 6 x 12) + écart 4 + remonter 36 = 336, borne gardée à 342 (6 de marge) : le plus étroit qui ne rogne ni les onglets ni « Remonter » (mesuré dans Chrome à 1 024 px, onglet Code avec Travail récent et Écrans, badge réduit à son point par P70-D-22) */
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
      .hr .btn .badge { position: absolute; top: var(--sp-2); right: 0; }
    }
    @media (min-width: 701px) and (max-width: 1639px) { /* P70-D-22 (« Badge réduit à son point (Recommandé) », arbitrage Samuel, AskUserQuestion session principale, 2026-11-04) : le badge « au travail » se réduit à son point et libère 92 px pour les onglets à 13 px. Seuil MESURÉ : à 1 600 px (et sous 1 635 px) le fil d'Ariane en parcours est rogné avec le badge entier (« 10 au travail ») ; il tient dès 1 635 px, 1 640 px garde 5 px de marge */
      #vf-lock { width: 36px; padding: 0; justify-content: center; }
      #vf-lock .bl { display: none; }
    }
    @media (min-width: 701px) { /* repli mesuré (70-04, P70-D-22) : l'en-tête déborde malgré la tranche ci-dessus (libellé plus long, bouton en plus) -> le badge se réduit à son point */
      #vf-lock[data-vf-point] { width: 36px; padding: 0; justify-content: center; }
      #vf-lock[data-vf-point] .bl { display: none; }
    }
    @media (min-width: 1000px) and (max-width: 1279px) {
      #ask { width: min(700px, calc(100% - var(--pw) - 48px)); }
    }
    /* 80-20 (P80-D-53 ; arbitrage Samuel, AskUserQuestion session principale, 2026-11-11, « Trois groupes libellés (Recommandé) ») : dès 1 280 px les boutons
       de .hr sont rangés en trois groupes libellés (ranger, plus bas) ; un groupe sans bouton affiché disparaît avec son libellé. Le point de « au travail »
       réduit prend un glyphe de sessions (deux silhouettes, tracé de 16 × 16 découpé dans le point : il garde la teinte de l'état). */
    :root { --vf-sessions: path('${SESSIONS}'); }
    .vf-hdr-groupe { display: flex; flex-direction: column; align-items: flex-start; gap: var(--sp-2); }
    .vf-hdr-groupe:not(:has(> .vf-hdr-rangee > :not([hidden]))) { display: none; }
    .vf-hdr-groupe + .vf-hdr-groupe { margin-inline-start: var(--sp-8); }
    header[data-vf-serre] .vf-hdr-groupe + .vf-hdr-groupe { margin-inline-start: 0; }
    .vf-hdr-lib { font-size: 12px; line-height: 1; color: var(--text-3); padding-inline: var(--sp-4); white-space: nowrap; }
    .vf-hdr-rangee { display: flex; align-items: center; gap: var(--sp-4); }
    @media (min-width: 701px) and (max-width: 1639px) { header #vf-lock .dot { width: 16px; height: 16px; border-radius: 0; clip-path: var(--vf-sessions); } }
    @media (min-width: 701px) { header #vf-lock[data-vf-point] .dot { width: 16px; height: 16px; border-radius: 0; clip-path: var(--vf-sessions); } }
    header #vf-lock:not(.held):not(.off) .dot { background: var(--text-3); }
    /* Zone basse, axe commun de 701 à 1 279 px (recette du 2026-11-08, lot C ; PU-G-021 ; arbitrage Samuel, AskUserQuestion session principale, 2026-11-08 : « La zone basse sous 1 280 px ») : le zoom n'est plus la pile
       verticale du haut à droite (celle du viewer sous 1 000 px et sur tactile, et celle de ce fichier de 1 000 à 1 279 px), mais la rangée de 1 280 px et plus, au bord gauche --edge ; il se pose au-dessus de la pastille « Terminal »
       (qui prend sa largeur, vf-cockpit-terminal-tiroir.mjs), elle-même au-dessus de la barre de question quand elles se recouvrent. Plus de bouton à droite : le titre retrouve sa largeur d'origine. Sous 701 px la pile du téléphone reste (P70-D-09). */
    @media (min-width: 701px) and (max-width: 1279px) {
      #zoom { left: var(--edge); right: auto; top: auto; bottom: calc(var(--edge) + var(--vf-ask-bas, 0px)); flex-direction: row; border-radius: 999px; } /* --vf-ask-bas : hauteur de la barre de question + 8, relue plus bas ; sans la pastille « Terminal » (cockpit sans --terminal) le zoom clôt déjà la barre */
      #context { max-width: min(520px, calc(100% - var(--pw) - 64px)); }
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
      header #crumbs .vf-ell { flex: none; color: var(--text-4); padding: 0 var(--sp-6); cursor: default; }
    }
    /* 70-12 (UIFN-14, P70-D-20 : choix du manager, vf-dev-manager, 2026-11-04) : l'onglet Équipe n'a pas de barre de question, donc rien ne gêne le bas de la scène ; dès 701 px le zoom y est la rangée en bas à gauche du viewer d'origine
       (celle de 1 440 px), jamais la colonne du haut qui recouvrait les cartes. Code et Projet gardent leur position (la barre de question occupe le bas) ; sous 701 px la pile verticale du téléphone (02-vf-telephone.js) reste seule. */
    @media (min-width: 701px) { body.vf-tab-equipe #zoom { left: var(--edge); right: auto; top: auto; bottom: var(--edge); flex-direction: row; border-radius: 999px; } }
    @media (max-width: 999px) { #ask-input { flex: 1 1 100%; } }
    #zoom[data-vf-replie] { display: none; } /* C-R6 : zoom replié, voir replier() plus bas */
    /* 72.1 (réglage du 2026-11-06, demande de Samuel) : la pastille « Terminal » et la barre de question se centrent sur le même axe horizontal, à la même marge du bord (--edge) ; le zoom (R17.2 en fixe la position et la taille) reste empilé 8 au-dessus de la pastille, au même bord gauche.
       Souris (>= 1 000 px, hors tactile) : la barre passe de 54 à 40 = 4 + 32 + 4 (invite et envoi de 32) et la pastille, qui garde ses 32 (T20.8), se pose à 16 + 4 = 20 du bas : (40 - 32) / 2 = 4, axe commun exact (cy identiques ; garde de l'axe : T21.12).
       Tactile ou < 1 000 px : les cibles font 44, donc 52 = 4 + 44 + 4 comme le zoom (barre : rembourrage de 4 autour de la ligne de 44 d'ask-mode ; pastille : 52). Le rembourrage gauche de la barre reste celui du viewer. Une barre sur deux lignes (< 1 000 px) garde sa face basse sur la ligne de base. */
    @media (min-width: 1000px) and (not (pointer: coarse)) {
      #ask-form { padding-top: var(--sp-4); padding-bottom: var(--sp-4); padding-right: var(--sp-4); }
      #ask-input, #ask-send { height: 32px; } #ask-send { width: 32px; }
    }
    @media (min-width: 701px) and (max-width: 1279px) { /* barre et pastille au même bord gauche (--edge) : la barre ne se centre plus dans l'aire laissée par le panneau (24 à 1 024 px, 28 à 768 px contre 16). Au-delà de 1 279 px elle reste centrée : la pastille ne la rencontre jamais. */
      #ask { left: var(--edge); transform: none; width: min(700px, calc(100% - var(--pw) - 2 * var(--edge))); }
    }
    @media (max-width: 999px), (pointer: coarse) {
      #ask-form { padding-top: var(--sp-4); padding-bottom: var(--sp-4); padding-right: var(--sp-4); }
    }
    @media (max-width: 700px) { header #crumbs { display: none; } }
    @media (max-width: 700px) { #ask { width: calc(100% - 2 * var(--edge)); bottom: var(--edge); } #ask-form { padding-left: var(--sp-16); } } /* correction ciblée du lot C (C-R2 et C-R4 : décisions déléguées par Samuel (message session principale, 2026-11-08, consignée en § 10 du rapport GLOBAL, 599a42a5), option recommandée ; ce ne sont ni 574c8b6f ni 70bf5046 ; juge de design 84/100) : --edge vaut pour tout bord de fenêtre (DESIGN.md § 4), le bas de la barre est donc à 16 comme ses côtés (la feuille de détail et le tiroir gardent 8, hors de ce lot) ; et un seul retrait intérieur gauche du champ, 16 à toutes les largeurs (le viewer le met à 12 sous 701 px : l'invite sautait de 4 px au passage de 700 à 701 px) */
    /* 1 280 px et plus (arbitrage Samuel, AskUserQuestion session principale, 2026-11-08, « À droite de la colonne (Recommandé) », consigné en § 10 du rapport GLOBAL de la recette (70bf5046)) : la barre part juste à droite de la colonne zoom/pastille, écart --sp-8 (x = 16 + 114 + 8 = 138), au lieu d'être centrée dans la carte (x = 160 à 1 280, 174 à 1 440 : l'écart variait avec la largeur). --vf-col : largeur de la colonne, relue sur le zoom (une seule source, plus bas). Elle finit à --edge du panneau. */
    @media (min-width: 1280px) { #ask { left: calc(var(--edge) + var(--vf-col, 114px) + var(--sp-8)); transform: none; width: min(700px, calc(100% - var(--pw) - 2 * var(--edge) - var(--vf-col, 114px) - var(--sp-8))); } }
    /* PU-G-001 / PU-G-002 : fil d'Ariane sous 1 280 px. Racine : libellé court (le nom entier reste le nom accessible, posé par ajuste0). Niveau courant : jamais rogné. Niveaux d'avant : les premiers à céder (masqués par ajuste0). */
    @media (max-width: 1279px) {
      header #crumbs button[data-vf-racine] { font-size: 0; flex: 0 1 auto; min-width: max-content; padding-inline: var(--sp-6); } /* jamais rogné : ajuste0 le masque s'il ne tient pas */
      header #crumbs button[data-vf-racine]::before { content: attr(data-vf-racine); font-size: 13.5px; }
      header #crumbs button.cur { flex: none; max-width: none; }
      header #crumbs button:not(.cur):not([data-vf-racine]) { flex: 0 100000 auto; min-width: 64px; }
      header #crumbs [data-vf-masque] { display: none; }
    }
    @media (min-width: 701px) and (max-width: 999px) { /* la colonne gauche garde la largeur de son contenu (nom accessible du niveau courant entier) et la recherche cède la première */
      header .hl { flex: 1 0 auto; }
      header .hc { flex: 2 100 120px; }
      header[data-vf-git] .hc { flex-basis: 72px; } /* l'ouvreur Git ajoute 48 px à la rangée : la recherche en cède autant (même règle que 76-vf-git-entete.js), pour que l'en-tête se replie aux MÊMES largeurs avec et sans Git (témoin F5, Phase 78) */
    }
    @media (min-width: 1000px) and (max-width: 1279px) and (not (pointer: coarse)) {
      header .hl { flex: 1 1 auto; } /* la colonne gauche prend la largeur naturelle de son contenu et c'est la RECHERCHE (poids 100 000, plancher de 152 px de P78-D-39) qui cède la première, comme dès 1 280 px */
      header .hc { flex: 0 100000 400px; }
      
      header:has(#btn-up:not([hidden])) .hl { min-width: calc(288px + var(--vf-cur, 0px)); } /* dans un dossier : 342 px moins les 54 px laissés au niveau courant, plus sa largeur (relevée par ajuste0 : --vf-cur) ... */
      header:has(#btn-up:not([hidden])) .brand { min-width: 30px; } /* ... et le nom du dépôt cède sa place au niveau courant */
    }
  `;
  document.head.appendChild(style);
  // hauteur de la barre de question + 8, pour poser le zoom au-dessus d'elle de 701 à 1 279 px (règle ci-dessus) : 0 quand la barre n'est pas affichée (tiroir du terminal ouvert, onglet Équipe). Observateur posé ici, avant celui du tiroir
  // (vf-cockpit-terminal-tiroir.mjs) : à chaque changement de taille de la barre la variable est à jour AVANT que la pastille et le zoom se replacent.
  const barreQ = document.getElementById('ask');
  if (barreQ) { const poser = () => document.documentElement.style.setProperty('--vf-ask-bas', barreQ.offsetHeight ? barreQ.offsetHeight + 8 + 'px' : '0px'); if (window.ResizeObserver) new ResizeObserver(poser).observe(barreQ); window.addEventListener('resize', poser); poser(); }
  // largeur de la colonne zoom/pastille (le zoom en rangée de 701 px et plus) : la barre de question part à sa droite dès 1 280 px (règle ci-dessus). Relue à chaque changement de taille du zoom, jamais recopiée.
  const zoomCol = document.getElementById('zoom');
  if (zoomCol) { const poserCol = () => { if (zoomCol.offsetWidth) document.documentElement.style.setProperty('--vf-col', zoomCol.offsetWidth + 'px'); }; poserCol(); if (window.ResizeObserver) new ResizeObserver(poserCol).observe(zoomCol); window.addEventListener('resize', poserCol); }
  // C-R6 (revue du lot C ; décision déléguée par Samuel (message session principale, 2026-11-08, consignée en § 10 du rapport GLOBAL, 599a42a5), option recommandée : le zoom se replie) : de 701 px à 1 440 px, dans une fenêtre assez basse pour que la rangée du zoom
  // ne tienne plus sans recouvrir le titre (h1, description) ou la carte de la visite guidée (tiroir du terminal ouvert, visite), le zoom se replie (data-vf-replie, display: none) tant que le recouvrement dure. Le zoom reste au clavier (+, − et f), à la souris (Ctrl+molette) et au toucher (pincement) ; « 0 » n'est lié à rien.
  // Mesure : on le déplie, on lit son rectangle, on le replie s'il recouvre : tout dans la même tâche, sans rendu entre les deux. Le titre ne dépend pas du zoom, la visite se replace d'elle-même autour de lui : pas de boucle.
  const mq701 = window.matchMedia('(min-width: 701px)');
  const replier = () => {
    const z = document.getElementById('zoom'); if (!z) return;
    const avant = z.getAttribute('data-vf-replie');
    const visite = document.getElementById('tour');
    const visiteLa = !!visite && visite.getBoundingClientRect().width > 0;
    if (avant === 'visite' && visiteLa && mq701.matches) return; // replié par la visite : il le reste tant qu'elle est là (la carte se replace autour du zoom : sans cela il clignoterait)
    z.removeAttribute('data-vf-replie');
    if (avant) window.dispatchEvent(new Event('vf-zoom-replie')); // I-2 : replié, le zoom n'avait plus de style en ligne ; déplié, la pastille et lui se replacent (vf-cockpit-terminal-tiroir.mjs, eviter) AVANT la mesure ci-dessous, sinon on le mesure à sa place de base, où il ne recouvre pas le titre, puis il se relève dessus
    let motif = null;
    if (mq701.matches || !document.body.classList.contains('no-panel')) { // I-2 : sous 701 px le zoom ne se replie que feuille de détail ouverte (relevé au-dessus d'elle, il peut recouvrir le titre dans une fenêtre basse)
      const b = z.getBoundingClientRect();
      if (b.width > 0 && b.height > 0) {
        const sur = (e) => { if (!e) return false; const c = e.getBoundingClientRect(); return c.width > 0 && c.height > 0 && getComputedStyle(e).visibility !== 'hidden' && b.left < c.right - 0.5 && b.right > c.left + 0.5 && b.top < c.bottom - 0.5 && b.bottom > c.top + 0.5; };
        if (sur(document.querySelector('#context h1')) || sur(document.querySelector('#context p'))) motif = 'titre'; else if (sur(visite)) motif = 'visite';
      }
    }
    if (motif) z.setAttribute('data-vf-replie', motif);
    if (motif !== avant) window.dispatchEvent(new Event('vf-zoom-replie')); // la pastille et la barre se replacent (vf-cockpit-terminal-tiroir.mjs)
  };
  let replierRaf = 0;
  const replierPlusTard = () => { cancelAnimationFrame(replierRaf); replierRaf = requestAnimationFrame(() => { replier(); setTimeout(replier, 450); }); }; // 450 : fin des transitions du tiroir et du panneau
  window.addEventListener('resize', replierPlusTard);
  new MutationObserver(replierPlusTard).observe(document.body, { childList: true, attributes: true, attributeFilter: ['class'] });
  if (barreQ && window.ResizeObserver) new ResizeObserver(replierPlusTard).observe(barreQ);
  setInterval(() => { if (document.getElementById('tour')) replier(); }, 500); // la carte de la visite se replace d'elle-même, sans mutation du corps de page : on la relit tant qu'elle est là
  replierPlusTard();
  // fil d'Ariane : étiquette les segments courts (moins de 12 caractères), puis masque derrière « … » les segments du milieu tant que le fil déborde (CSS : un segment long garde 64 px)
  const fil = document.getElementById('crumbs'), nomProjet = document.getElementById('proj-name'), gauche = document.querySelector('header .hl');
  let obs = null, replieRaf = null;
  const ajuste0 = () => {
    if (!fil) return;
    if (obs) obs.disconnect(); // nos propres retouches du fil ne relancent pas l'ajustement
    for (const e of fil.querySelectorAll('[data-vf-masque]')) e.removeAttribute('data-vf-masque');
    fil.querySelector('.vf-ell')?.remove();
    const bs = [...fil.querySelectorAll('button')];
    for (const b of bs) { if (b.textContent.trim().length < 12) b.setAttribute('data-vf-court', ''); else b.removeAttribute('data-vf-court'); }
    const racine = bs.length && bs[0] === fil.firstElementChild ? bs[0] : null; // PU-G-001 : seule la vue d'ensemble prend un libellé court
    if (racine && /^(Vue d'ensemble|Overview)$/.test(racine.textContent.trim())) { racine.setAttribute('data-vf-racine', 'Ensemble'); racine.setAttribute('aria-label', racine.textContent.trim()); }
    const cur = fil.querySelector('button.cur'); document.querySelector('header')?.style.setProperty('--vf-cur', (cur ? cur.offsetWidth : 0) + 'px'); // largeur naturelle du niveau courant (flex: none sous 1 280 px)
    if (!matchMedia('(min-width: 1280px)').matches && bs.length) { // PU-G-002 : le niveau courant reste entier ; les niveaux d'avant cèdent un à un, puis la racine seule si elle ne tient pas
      for (let k = 0; k < bs.length - 1 && fil.scrollWidth > fil.clientWidth + 1; k++) { bs[k].setAttribute('data-vf-masque', ''); bs[k].nextElementSibling?.setAttribute('data-vf-masque', ''); }
      if (bs.length === 1 && bs[0].hasAttribute('data-vf-racine') && (fil.scrollWidth > fil.clientWidth + 1 || (nomProjet && nomProjet.scrollWidth > nomProjet.clientWidth + 1))) bs[0].setAttribute('data-vf-masque', ''); // PU-G-001 : le nom du dépôt passe avant le libellé de la racine
    }
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
  const ajuste = () => { ajuste0(); if (replieRaf) replieRaf(); }; // chaque ajustement du fil relance, une fois par image, la mesure du badge
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
  // repli mesuré du badge « au travail » (70-04, P70-D-22 : « Badge réduit à son point (Recommandé) », arbitrage Samuel, AskUserQuestion session principale, 2026-11-04) : au-dessus de 700 px, si l'en-tête déborde
  // (un bouton hors de la fenêtre, l'en-tête plus large que la fenêtre, ou le fil d'Ariane rogné malgré son masquage), le badge se réduit à son point. Filet derrière la tranche 701-1 639 px : un libellé plus long
  // (« 99 au travail ») ou un bouton d'en-tête de plus ne dépend d'aucun seuil fixe. Rejoué comme le fil : rendu, changement du badge ou des boutons, redimensionnement, chargement, polices.
  const colDroite = document.querySelector('header .hr'); // le badge (#vf-lock) est ajouté plus tard par 70-vf-live.js : relu à chaque mesure
  // 80-20 (P80-D-53, P80-D-59) : trois groupes libellés dès 1 280 px. Les boutons sont DÉPLACÉS (jamais clonés : id, menu .rel et ordre relatif gardés) ;
  // un bouton posé plus tard rejoint son groupe par son id, sinon « Affichage ». Sous 1 280 px le rangement est défait (ordre et parents d'origine).
  // L'écouteur `change` vit dans le rappel de surOnglet.
  const GROUPES = [['lire', 'Read', ['flows-btn', 'screens-btn', 'filters-btn', 'tour-btn']],
    ['suivre', 'Follow', ['btn-recent', 'btn-health', 'btn-synthese', 'vf-lock']], // 77 : Synthèse juste après Santé
    ['affichage', 'Display', ['btn-export', 'theme-toggle', 'btn-panel']]];
  const mq1280 = window.matchMedia('(min-width: 1280px)'), tr = window.__vfFrT || ((x) => x), extHdr = document.getElementById('hdr-ext');
  let origine = null; // [unité, parent d'origine] dans l'ordre du document, relevé avant son rangement
  const SEL = ':scope > .rel, :scope > button, :scope > .vf-hdr-groupe > .vf-hdr-rangee > *, #hdr-ext > button';
  const unites = () => (colDroite ? [...colDroite.querySelectorAll(SEL)].filter((e) => e.id !== 'vf-plus' && e.id !== 'vf-git-ouvreur') : []);
  const cleDe = (e) => (e.classList.contains('rel') ? (e.querySelector('button') || e).id : e.id);
  const deranger = () => {
    if (!colDroite || !colDroite.querySelector(':scope > .vf-hdr-groupe')) return;
    const rang = (e) => { const i = (origine || []).findIndex((x) => x[0] === e); return i < 0 ? 1e6 : i; };
    for (const e of unites().sort((a, b) => rang(a) - rang(b))) {
      const o = (origine || []).find((x) => x[0] === e);
      if ((o ? o[1] : extHdr) === extHdr && extHdr) extHdr.appendChild(e); else colDroite.insertBefore(e, document.getElementById('vf-plus'));
    }
    for (const g of colDroite.querySelectorAll(':scope > .vf-hdr-groupe')) g.remove();
  };
  const ranger = () => {
    if (!colDroite) return;
    if (!mq1280.matches) { deranger(); return; }
    origine = origine || [];
    // un bouton posé plus tard suit les autres
    for (const e of unites()) if (!origine.some((x) => x[0] === e)) origine.push([e, e.parentElement === extHdr ? extHdr : colDroite]);
    const cibles = [];
    for (const [cle, lib] of GROUPES) {
      let g = colDroite.querySelector(`:scope > [data-vf-groupe="${cle}"]`);
      if (!g) {
        g = document.createElement('div'); g.className = 'vf-hdr-groupe'; g.setAttribute('role', 'group'); g.setAttribute('data-vf-groupe', cle);
        const l = document.createElement('span'), r = document.createElement('div');
        l.className = 'vf-hdr-lib'; l.id = 'vf-hdr-lib-' + cle; l.textContent = tr(lib);
        r.className = 'vf-hdr-rangee'; g.setAttribute('aria-labelledby', l.id); g.append(l, r);
        colDroite.insertBefore(g, document.getElementById('vf-plus'));
      }
      cibles.push([g.lastElementChild, []]);
    }
    unites().forEach((e, pos) => {
      const k = cleDe(e), gi = GROUPES.findIndex((x) => x[2].includes(k)), i = gi < 0 ? GROUPES.length - 1 : gi;
      cibles[i][1].push([gi < 0 ? 1e6 + pos : GROUPES[gi][2].indexOf(k), e]);
    });
    for (const [rangee, l] of cibles) {
      const voulu = l.sort((a, b) => a[0] - b[0]).map((x) => x[1]);
      if (voulu.length !== rangee.children.length || voulu.some((e, i) => rangee.children[i] !== e)) for (const e of voulu) rangee.appendChild(e);
    }
  };
  const initGroupes = () => {
    mq1280.addEventListener('change', ranger); ranger();
    return () => { mq1280.removeEventListener('change', ranger); deranger(); };
  };
  const coq = window.VF_COQUILLE;
  if (coq && typeof coq.surOnglet === 'function') coq.surOnglet(initGroupes, { cle: '01-vf-responsive.js' }); else initGroupes();
  const replie = () => {
    const badge = document.getElementById('vf-lock'); if (!badge || !hd) return;
    badge.removeAttribute('data-vf-point'); // on mesure avec le badge entier
    hd.removeAttribute('data-vf-serre');
    if (!matchMedia('(min-width: 701px)').matches) return;
    if (fil) ajuste0();
    const dehors = [...hd.querySelectorAll('button')].some((b) => b.offsetWidth > 0 && (b.getBoundingClientRect().right > innerWidth + 0.5 || b.getBoundingClientRect().left < -0.5));
    if (dehors || hd.scrollWidth > innerWidth + 1 || (fil && fil.offsetWidth > 0 && fil.scrollWidth > fil.clientWidth + 1)) badge.setAttribute('data-vf-point', '');
  };
  // Phase 80 : badge déjà au point et fil encore rogné (trois groupes de 80-20, « 99 au travail » + un bouton, 1 640 px) : l'écart entre groupes cède
  const serrer = () => {
    const badge = document.getElementById('vf-lock'); if (!badge || !hd || !mq1280.matches || !badge.hasAttribute('data-vf-point')) return;
    if (fil) ajuste0();
    const sorti = (x) => x.offsetWidth > 0 && (x.getBoundingClientRect().right > innerWidth + 0.5 || x.getBoundingClientRect().left < -0.5);
    const rogne = fil && fil.offsetWidth > 0 && fil.scrollWidth > fil.clientWidth + 1;
    if ([...hd.querySelectorAll('button')].some(sorti) || hd.scrollWidth > innerWidth + 1 || rogne) hd.setAttribute('data-vf-serre', '');
  };
  if (colDroite && hd) {
    let q = 0; replieRaf = () => { if (!q) q = requestAnimationFrame(() => { q = 0; ranger(); replie(); serrer(); }); };
    new MutationObserver(replieRaf).observe(colDroite, { childList: true, characterData: true, subtree: true }); // création du badge, changement de son libellé, bouton ajouté
    window.addEventListener('resize', replieRaf); window.addEventListener('load', replieRaf); if (document.fonts?.ready) document.fonts.ready.then(replieRaf);
    replieRaf();
  }
  // nom accessible des boutons de zoom (z-out, z-fit, z-in), à toutes les largeurs (70-05, P70-D-09) : le title sans son raccourci « (+) », relu quand le traducteur change le title ; un aria-label posé par autrui n'est jamais écrasé
  const zm = document.getElementById('zoom');
  const nomsZoom = () => { for (const b of zm.querySelectorAll('button')) { const t = (b.getAttribute('title') || '').replace(/\s*\([^)]*\)\s*$/, '').trim(), cur = b.getAttribute('aria-label'); if (t && t !== cur && (!cur || cur === b.dataset.vfNom)) { b.setAttribute('aria-label', t); b.dataset.vfNom = t; } } };
  if (zm) { nomsZoom(); new MutationObserver(nomsZoom).observe(zm, { childList: true, subtree: true, attributes: true, attributeFilter: ['title'] }); }
})();
