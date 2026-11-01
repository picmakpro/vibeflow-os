// VibeFlow (spike 006) : le chrome du viewer en français, sans toucher au viewer. Un dictionnaire de
// phrases exactes et quelques motifs, appliqués aux nœuds de texte et aux attributs (placeholder, title,
// aria-label) au chargement puis à chaque mutation du DOM. Les données (noms de cartes, descriptions)
// sont déjà en français : on ne traduit qu'une phrase connue en entier, jamais un mot dans une phrase.
// Pose aussi les couleurs des types de l'onglet Projet (meta.kindColors, spike 006). ?lang=en désactive.
(() => {
  const SC = window.Floorplan;
  if (!SC || new URLSearchParams(location.search).get('lang') === 'en') return;
  const G = SC.graph;

  // couleurs des types : sombre par défaut, clair sous data-theme="light" (même règle que le viewer)
  const C = G.meta.kindColors || {};
  if (Object.keys(C).length) {
    const st = document.createElement('style');
    st.textContent = `:root { ${Object.entries(C).map(([k, [, d]]) => `--n-${k}: ${d};`).join(' ')} }
      :root[data-theme="light"] { ${Object.entries(C).map(([k, [l]]) => `--n-${k}: ${l};`).join(' ')} }`;
    document.head.appendChild(st);
  }

  // les libellés français sont plus longs : la grille « 1fr auto 1fr » du viewer pousse alors la recherche
  // sur les onglets. Au-dessus du gabarit mobile, la colonne centrale prend la place qui reste.
  const lay = document.createElement('style');
  lay.textContent = `@media (min-width: 701px) { header { grid-template-columns: auto minmax(0, 1fr) auto; } header #hc { display: flex; justify-content: center; min-width: 0; } header #search-btn { max-width: 100%; } }`;
  document.head.appendChild(lay);

  const T = {
    'Fit to screen (F)': "Ajuster à l'écran (F)", 'Fit to screen': "Ajuster à l'écran", 'Zoom in (+)': 'Zoom avant (+)', 'Zoom out (−)': 'Zoom arrière (−)',
    'Up one level (Backspace)': 'Remonter d\'un niveau (Retour arrière)', 'Up one level': "Remonter d'un niveau",
    'Search files, routes, modules': 'Chercher une carte, un plan, une exigence', Search: 'Chercher', 'No matches': 'Aucun résultat',
    'Nothing on the map matches that.': 'Rien sur la carte ne correspond.', Flows: 'Parcours', 'Guided flows': 'Parcours guidés',
    'Connection types': 'Types de liens', 'Toggle details (P)': 'Afficher ou masquer le détail (P)', 'Toggle details': 'Afficher ou masquer le détail',
    'Drag to resize': 'Glisser pour redimensionner', 'Show technical detail': 'Afficher le détail technique', 'Start here': 'Par où commencer', Export: 'Exporter',
    Overview: "Vue d'ensemble", 'Back to overview': "Retour à la vue d'ensemble", 'Back to map': 'Retour à la carte', Folder: 'Dossier', File: 'Élément', file: 'élément',
    Answer: 'Réponse', 'On this board': 'Sur ce tableau', Board: 'Tableau', 'Show answer board': 'Afficher le tableau de réponse', Walkthrough: 'Parcours pas à pas',
    'Thinking…': 'Réflexion…', Stop: 'Arrêter', Close: 'Fermer', Cancel: 'Annuler', Copy: 'Copier', Copied: 'Copié', 'Copy path': 'Copier le chemin', 'Copy name': 'Copier le nom',
    'Open in editor': "Ouvrir dans l'éditeur", Open: 'Ouvrir', 'Show on the map': 'Montrer sur la carte', 'Show on map': 'Montrer sur la carte', 'Show details': 'Voir le détail',
    'Ask about this': 'Poser une question sur ceci', 'Ask about this connection': 'Poser une question sur ce lien', 'Ask about this view': 'Poser une question sur cette vue', 'Ask about this…': 'Poser une question sur ceci…',
    Ask: 'Demander', 'Something went wrong.': "Quelque chose s'est mal passé.", 'Could not reach the map server.': 'Le serveur de la carte ne répond pas.',
    'The CLI ended without an answer.': "Le CLI s'est arrêté sans réponse.", 'Asking is unavailable': 'Questions indisponibles', 'Map updated': 'Carte mise à jour',
    'Recent work': 'Travail récent', 'Highlight recent work': 'Surligner le travail récent', New: 'Nouveau', Changed: 'Modifié', Added: 'Ajouté', Remove: 'Retirer',
    'Used by': 'Utilisé par', 'Depends on': 'Dépend de', Inside: 'Contenu', Files: 'Éléments', 'Files involved': 'Éléments concernés', 'Matched by': 'Trouvé par',
    'Show connections': 'Montrer les liens', Less: 'Moins', More: 'Plus', Details: 'Détail', Other: 'Autre', Systems: 'Ensembles', Tour: 'Visite', 'Laying out…': 'Mise en page…',
    'No description yet': 'Pas encore de description', 'No description yet.': 'Pas encore de description.', 'Click a card to inspect it · double-click to open it': 'Cliquer une carte pour la voir · double-cliquer pour y entrer',
    'Request a new flow…': 'Demander un parcours…', 'Build flow': 'Construire le parcours', 'Delete flow': 'Supprimer le parcours', Flow: 'Parcours', 'Go to source': "Aller à l'origine", 'Go to target': 'Aller à la cible',
    Health: 'Santé', 'Export a copy of this map to share': 'Exporter une copie de cette carte à partager', 'Start here tour': 'Visite guidée de départ',
    'Apps people use': 'Ce que les gens ouvrent', 'Behind the scenes': 'En coulisse', 'Outside services': 'Services extérieurs', 'Developer tools': 'Outils de développement',
    Repositories: 'Dépôts', Codebase: 'Base de code', 'The codebase': 'La base de code', 'You asked:': 'Vous avez demandé :', Skip: 'Passer', Next: 'Suivant', Back: 'Retour', Done: 'Terminé',
    'Got it': 'Compris', 'Install it': "L'installer", 'Copy command': 'Copier la commande', Contains: 'Contient', Theme: 'Thème', Light: 'Clair', Dark: 'Sombre',
  };
  // l'onglet Code garde des fichiers ; sur l'onglet Projet, un « fichier » est un plan, une exigence, une étape
  if (G.meta.vfTab !== 'project') Object.assign(T, { File: 'Fichier', file: 'fichier', Files: 'Fichiers', 'Files involved': 'Fichiers concernés', 'Search files, routes, modules': 'Chercher un fichier, une route, un module' });
  const R = [
    [/^Answer · (\d+) cards?$/, (_, n) => `Réponse · ${n} carte${n > 1 ? 's' : ''}`],
    [/^Ask anything about (.+?)…$/, (_, x) => `Posez une question sur ${x.replace(/ — Projet$/, '')}…`],
    [/^(.+) map$/, (_, x) => x],
    [/^Searching the map for "(.+)"$/, (_, x) => `Cherche « ${x} » dans la carte`],
    [/^Searching code for "(.+)"$/, (_, x) => `Cherche « ${x} » dans le code`],
    [/^Looking at (.+)$/, (_, x) => `Examine ${x}`], [/^Reading (.+)$/, (_, x) => `Lit ${x}`], [/^Listing (.+)$/, (_, x) => `Liste ${x}`],
    [/^Running a command$/, () => 'Lance une commande'], [/^Tracing a dependency path$/, () => 'Suit une chaîne de dépendances'],
    [/^\(\+(\d+) more\)$/, (_, n) => `(+${n} autres)`], [/^\+(\d+) more$/, (_, n) => `+${n} autres`],
    [/^(\d+) cards?$/, (_, n) => `${n} carte${n > 1 ? 's' : ''}`], [/^(\d+) files?$/, (_, n) => `${n} ${G.meta.vfTab === 'project' ? 'élément' : 'fichier'}${n > 1 ? 's' : ''}`],
    [/^Theme: (.+)\. Press for (.+)\.$/, (_, a, b) => `Thème : ${T[a] || a}. Appuyer pour ${(T[b.replace(/\.$/, '')] || b).toLowerCase()}.`],
  ];
  const tr = (s) => {
    const t = s.trim(); if (!t || t.length > 140 || !/[A-Za-z]/.test(t)) return null;
    let out = T[t];
    if (out == null) for (const [re, f] of R) { if (re.test(t)) { out = t.replace(re, f); break; } }
    return out == null || out === t ? null : s.replace(t, out);
  };
  const probe = (window.__vfFr = { nodes: 0, attrs: 0, passes: 0, ms: 0 });
  const ATTRS = ['placeholder', 'title', 'aria-label'];
  const SKIP = 'script,style,code,pre,textarea,.mono,.rp,.pp';
  const fix = (root) => {
    const t0 = performance.now();
    const w = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    for (let n = w.nextNode(); n; n = w.nextNode()) {
      if (n.parentElement?.closest(SKIP)) continue;
      const v = tr(n.nodeValue); if (v != null) { n.nodeValue = v; probe.nodes++; }
    }
    const els = root.nodeType === 1 ? [root, ...root.querySelectorAll('[placeholder],[title],[aria-label]')] : [];
    for (const el of els) for (const a of ATTRS) { const x = el.getAttribute?.(a); const v = x ? tr(x) : null; if (v != null) { el.setAttribute(a, v); probe.attrs++; } }
    probe.passes++; probe.ms += performance.now() - t0;
  };
  document.documentElement.lang = 'fr';
  // le viewer réécrit le titre après coup (« <nom> map ») : on le suit
  new MutationObserver(() => { const v = tr(document.title); if (v != null) document.title = v; }).observe(document.querySelector('title'), { childList: true });
  // regroupe les mutations d'une même frame : un rendu du viewer en produit des centaines
  let queued = new Set(), raf = 0;
  const flush = () => { raf = 0; const q = queued; queued = new Set(); for (const el of q) if (el.isConnected) fix(el); };
  new MutationObserver((ms) => {
    for (const m of ms) queued.add(m.type === 'characterData' ? m.target.parentElement : m.target);
    if (!raf) raf = requestAnimationFrame(flush);
  }).observe(document.body, { subtree: true, childList: true, characterData: true, attributes: true, attributeFilter: ATTRS });
  fix(document.body);
  const v = tr(document.title); if (v != null) document.title = v;
})();
