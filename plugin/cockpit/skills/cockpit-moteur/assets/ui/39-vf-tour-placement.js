// VibeFlow (J1, passe de suivi de la recette du 2026-11-08 ; revue finale, m3) : le placement de la carte de la visite guidée, sorti de 40-tour.js (fichier vendorisé, plafonné à 300 lignes).
// La carte ne recouvre aucune surface fixe (zoom, pastille du terminal, panneau de détail, bloc titre, en-tête, barre de question et ses avis, cible entourée). Chaque candidat (largeur, côté,
// hauteur au-dessus d'un obstacle) est noté par l'aire qu'il recouvre, puis par le texte rogné, puis par son éloignement de la place habituelle ; le coût le plus bas gagne, à égalité le premier
// de l'ordre fixe : rien d'autre que la mise en page ne décide (ni le moment, ni les polices, ni le pointeur).
// Chargé avant 40-tour.js (ordre des noms) ; 40-tour.js le crée avec sa carte et trois rappels (visible, fold, unfold).
(() => {
  const creer = ({ card, visible, fold, unfold }) => {
    let placedSig = '';
    let placedFit = '';
    let lastPlace = null;
    const sigOf = (obs) => obs.map((o) => [o.left, o.top, o.right, o.bottom].map(Math.round).join(',')).join('|');
    // J1 : la hauteur du texte de la carte, relue pendant la visite
    const fitOf = () => {
      const t = card.querySelector('.tb');
      return t ? t.scrollHeight + '/' + t.clientHeight : '';
    };
    // sur un téléphone le zoom monte de lui-même au-dessus de la feuille (--vf-ask-h, 02-vf-telephone.js) : ce n'est pas un obstacle ;
    // la pastille du terminal, elle, ne bouge pas : la feuille la laisse libre (T21.7)
    function obstacles(vis) {
      const ask = document.getElementById('ask');
      const name = (e) => e.id ? '#' + e.id : e.tagName.toLowerCase() + (typeof e.className === 'string' && e.className.trim() ? '.' + e.className.trim().split(/\s+/)[0] : '');
      // 71.5 : le sélecteur est assemblé (la page servie sans --terminal ne contient jamais le préfixe du terminal, T7.5) ;
      // la pastille du terminal (seulement avec --terminal ; absente ou masquée = ignorée par vis) est un obstacle comme le zoom, sans marge fixe
      return ['zoom', 'panel', 'context', 'ask'].map((id) => document.getElementById(id))
        .concat(document.querySelector('header'), [...document.querySelectorAll('.tour-target')], document.querySelector('.vf-' + 'term-pastille'), ask ? [...ask.children] : [])
        .filter(vis)
        .map((e) => {
          const r = e.getBoundingClientRect();
          return { n: name(e), left: r.left, top: r.top, right: r.right, bottom: r.bottom };
        })
        .filter((o) => innerWidth >= 701 || o.n !== '#zoom');
    }
    function place(folded) {
      if (!folded) unfold();
      const feuille = innerWidth < 701; // un téléphone : une feuille pleine largeur en bas, posée au-dessus de la barre de question (PU-G-090)
      const vis = visible;
      const obs = obstacles(vis);
      placedSig = sigOf(obs);
      lastPlace = { obs, topLimit: 0, best: null };
      const bas = (els) => els.filter(vis).reduce((m, e) => Math.max(m, e.getBoundingClientRect().bottom), 0) + 8;
      // en-tête et bloc titre (quelle que soit leur hauteur : une police large rend le titre plus haut) : la carte n'est jamais plus haute que la place sous eux, son texte défile
      const topLimit = bas([document.getElementById('context'), document.querySelector('header')]);
      // J1 : topHaut = sous l'en-tête seul, pour une carte posée à DROITE du bloc titre (fenêtre basse)
      const topHaut = bas([document.querySelector('header')]);
      const w0 = feuille ? innerWidth - 16 : Math.min(360, innerWidth - 32);
      const widths = feuille ? [w0] : [w0, 300, 260, 220, 200].filter((w, k, a) => w <= w0 && a.indexOf(w) === k);
      const bottoms = [76, ...obs.map((o) => Math.round(innerHeight - o.top + 12))].filter((b, k, a) => b >= 12 && b <= innerHeight - 120 && a.indexOf(b) === k).sort((a, b) => a - b);
      // I-3 : une fenêtre basse ne laisse, au bord gauche, que la colonne du zoom et de la pastille ;
      // la carte peut aussi se poser À DROITE de cette colonne (troisième côté, le moins favorisé), entre elle et le panneau ou le bord droit
      const colonne = feuille ? 0 : obs.filter((o) => (o.n === '#zoom' || o.n.indexOf('term-pastille') > 0) && o.left < 60).reduce((m, o) => Math.max(m, o.right + 8), 0);
      const titre = document.getElementById('context');
      const tr = titre && vis(titre) ? titre.getBoundingClientRect() : null;
      const gauche = tr && !feuille ? Math.max(Math.round(tr.right + 8), colonne) : 0;
      const panneau = obs.find((o) => o.n === '#panel' && o.left > gauche);
      const libre = (panneau ? panneau.left : innerWidth) - 8 - gauche;
      // J1 : une fenêtre basse laisse, À DROITE du bloc titre (entre lui et le panneau ou le bord), la plus grande place libre : 4e côté, borné par l'en-tête seul
      const droiteTitre = !!tr && !feuille && tr.left < 60 && libre >= 160;
      // px comptés autour de chaque surface : bordures et arrondis que la boîte de mise en page ne montre pas (6 faisait choisir des cartes inutilement étroites)
      const G6 = 2;
      const area = (a, b) => Math.max(0, Math.min(a.right, b.right + G6) - Math.max(a.left, b.left - G6)) * Math.max(0, Math.min(a.bottom, b.bottom + G6) - Math.max(a.top, b.top - G6));
      let best = null;
      // d'abord les largeurs ; quand rien ne tient sans recouvrir une surface, la carte raccourcit aussi (son texte défile), jusqu'à un plancher de 200 x 120 px
      // (feuille : au plus la moitié de l'écran, le texte défile, le reste montre la carte)
      for (const [lvl, hcap] of (feuille ? [Math.round(innerHeight * 0.5)] : [1e6, 240, 180, 120]).entries()) {
        const cotes = feuille ? ['left'] : [...colonne ? ['left', 'right', 'colonne'] : ['left', 'right'], ...droiteTitre ? ['titre'] : []];
        for (const w of widths) for (const side of cotes) for (const b of bottoms) {
          const haut = side === 'titre';
          const wc = haut ? Math.min(w, libre) : w;
          if (wc < 160) continue;
          card.style.width = wc + 'px';
          card.style.bottom = b + 'px';
          card.style.maxHeight = Math.min(hcap, Math.max(120, innerHeight - b - (haut ? topHaut : topLimit))) + 'px';
          card.classList.toggle('right', side === 'right');
          card.style.left = side === 'colonne' ? colonne + 'px' : haut ? gauche + 'px' : '';
          // la boîte de mise en page de la carte, pas sa boîte peinte : pendant l'animation d'entrée (98 %, 8 px plus bas) la boîte peinte est plus petite et montre un vide que la carte posée n'a pas
          const r = { left: card.offsetLeft, top: card.offsetTop, right: card.offsetLeft + card.offsetWidth, bottom: card.offsetTop + card.offsetHeight };
          // le coût : ce qu'elle recouvre d'abord (un pixel recouvert pèse plus que tout déplacement), puis son éloignement de la place habituelle (en bas à gauche, pleine largeur, pleine hauteur)
          const covered = obs.reduce((n, o) => n + area(r, o), 0);
          const tb = card.querySelector('.tb');
          const rogne = feuille || !tb ? 0 : Math.max(0, tb.scrollHeight - tb.clientHeight);
          const tn = card.querySelector('.tn');
          const tt = card.querySelector('.tt');
          // J1 : le texte rogné coûte, après le recouvrement et avant tout déplacement ; le titre entier et la première ligne de la description (l'essentiel) coûtent bien plus
          const essentiel = feuille || !tb ? 0 : Math.max(0, (tn ? tn.offsetTop + 22 : (tt.offsetTop + tt.offsetHeight)) - tb.offsetTop - tb.clientHeight);
          const sortie = r.top < 0 || r.left < -0.5 || r.right > innerWidth + 0.5 ? 1e12 : 0;
          const eloigne = Math.abs(b - 76) + (side === 'right' ? 40 : side === 'colonne' ? 60 : 0) + (haut ? 10 : 0) + (w0 - w) * 0.5 + lvl * 20;
          const score = covered * 1e5 + essentiel * 200 + rogne * 20 + sortie + eloigne;
          if (!best || score < best.score) best = { score, covered, essentiel, qualite: covered * 1e5 + essentiel * 200 + rogne * 20, w: wc, side, b, mh: card.style.maxHeight };
        }
        if (best.covered === 0) break;
      }
      lastPlace.best = best;
      lastPlace.topLimit = topLimit;
      card.style.width = best.w + 'px';
      card.style.bottom = best.b + 'px';
      card.style.maxHeight = best.mh;
      card.classList.toggle('right', best.side === 'right');
      card.style.left = best.side === 'colonne' ? colonne + 'px' : best.side === 'titre' ? gauche + 'px' : '';
      placedFit = fitOf();
      // toujours à recouvrir quelque chose, ou le titre ou le début de la description rogné : la description du titre est repliée et la recherche reprend ; gardée seulement si elle coûte moins, sinon remise
      if (!folded && (best.covered > 0 || best.essentiel > 0) && fold()) {
        const before = best.qualite;
        place(true);
        if (lastPlace.best.qualite >= before) { unfold(); place(true); }
      }
    }
    // une surface a bougé depuis le dernier placement, ou le texte de la carte a changé de hauteur
    const abouge = () => sigOf(obstacles(visible)) !== placedSig || fitOf() !== placedFit;
    // diagnostic des suites de tests (un échec sur un exécuteur que nous n'avons pas imprime ce que le placement a vu) : les obstacles du dernier placement et la position choisie
    const diag = () => JSON.stringify(!lastPlace ? { placed: false } : {
      obstacles: lastPlace.obs.map((o) => o.n + '[' + [o.left, o.top, o.right, o.bottom].map(Math.round).join(',') + ']'),
      topLimit: Math.round(lastPlace.topLimit),
      choice: lastPlace.best && { width: lastPlace.best.w, side: lastPlace.best.side, bottom: lastPlace.best.b, covered: Math.round(lastPlace.best.covered), essentiel: Math.round(lastPlace.best.essentiel), maxHeight: lastPlace.best.mh },
    });
    return { place, abouge, diag };
  };
  window.VibeFlowTourPlacement = { creer };
})();
