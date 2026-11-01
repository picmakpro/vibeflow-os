// vibeflow:fr
// VibeFlow (67-07) : le chrome du viewer en français, sans toucher au viewer. Le dictionnaire (phrases exactes, fichiers
// 78 et 79 → window.__vfFrDict) et les motifs ci-dessous sont appliqués aux nœuds de texte et aux attributs
// (placeholder, title, aria-label) au chargement puis à chaque mutation du DOM. Les données (noms de cartes,
// descriptions) sont déjà en français : on ne traduit qu'une phrase connue en entier, jamais un mot dans une phrase.
// Seuls `nodeValue` et les valeurs d'attribut sont écrits, jamais du HTML. Pose aussi les couleurs des types de
// l'onglet Projet (meta.kindColors). ?lang=en désactive. Fonction pure : window.__vfFrTraduire(texte) → phrase ou null.
(() => {
  const SC = window.Floorplan;
  const G = SC && SC.graph;
  const projet = () => G?.meta?.vfTab === 'project';
  const T = Object.assign({}, window.__vfFrDict || {});
  // clés à variables (`{}`) : une phrase de gabarit, la variable prise telle quelle puis traduite à son tour ; une valeur peut
  // porter « singulier|pluriel » (le premier `{}` est le compte, un « s » final facultatif est toléré dans la clé) et omettre
  // des `{}`, jamais en ajouter. Un gabarit au texte fixe court (< 16 caractères : « {} of {} », « {} with {} ») ne s'applique que si une variable
  // est un nombre ou se traduit elle-même : sans cela il abîmerait les données du lab (« Top of the world »).
  const P = [];
  const esc = (x) => x.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  for (const [k, v] of Object.entries(T)) if (k.includes('{}')) { delete T[k]; P.push([new RegExp('^' + k.split('{}').map(esc).join('(.*?)') + (v.includes('|') && /[a-z]$/.test(k) ? 's?' : '') + '$'), v.split('|').map((x) => x.split('{}')), k.replace(/\{\}/g, '').length]); }
  // l'onglet Code garde des fichiers ; sur l'onglet Projet, un « fichier » est un plan, une exigence, une étape
  Object.assign(T, projet()
    ? { File: 'Élément', file: 'élément', Files: 'Éléments', 'Files involved': 'Éléments concernés', 'Search files, routes, modules': 'Chercher une carte, un plan, une exigence' }
    : { File: 'Fichier', file: 'fichier', Files: 'Fichiers', 'Files involved': 'Fichiers concernés', 'Search files, routes, modules': 'Chercher un fichier, une route, un module' });
  const R = [
    [/^(\d+) things?$/, (_, n) => `${n} point${n > 1 ? 's' : ''}`],
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
  const noyau = (t) => {
    let out = T[t];
    if (out == null) for (const [re, formes, fixe] of P) { const m = re.exec(t); if (m && (fixe >= 16 || m.slice(1).some((c) => /^\d+$/.test(c.trim()) || noyau(c.trim()) != null))) { const parts = formes[formes.length > 1 && Number(m[1]) !== 1 ? 1 : 0]; out = parts.reduce((x, p, i) => x + (i ? (noyau(m[i].trim()) ?? m[i]) : '') + p, ''); break; } }
    if (out == null) for (const [re, f] of R) { if (re.test(t)) { out = t.replace(re, f); break; } }
    if (out == null && t.includes(' · ')) { const seg = t.split(' · ').map((x) => noyau(x)); if (seg.some((x) => x != null)) out = seg.map((x, i) => x ?? t.split(' · ')[i]).join(' · '); }
    if (out == null && /^[^:]{3,}: ./.test(t)) { const i = t.indexOf(': '); const g = noyau(t.slice(0, i)), d = noyau(t.slice(i + 2)); if (g != null || d != null) out = (g ?? t.slice(0, i)) + ' : ' + (d ?? t.slice(i + 2)); }
    // pluriel composé à l'exécution (« files », « screens ») : le singulier du dictionnaire, un « s » en plus
    if (out == null && /^[A-Za-z]{3,}s$/.test(t) && T[t.slice(0, -1)] != null) out = T[t.slice(0, -1)] + 's';
    return out;
  };
  const tr = (s) => {
    const t = typeof s === 'string' ? s.trim() : ''; if (!t || t.length > 600 || !/[A-Za-z]/.test(t)) return null; // chaîne vide → rien : garde contre la boucle des attributs vides
    const out = noyau(t);
    return out == null || out === t ? null : s.replace(t, out);
  };
  window.__vfFrTraduire = tr;
  tr.motifs = R.length; tr.gabarits = P.length; // lu par le test chrome-fr
  if (!SC || new URLSearchParams(location.search).get('lang') === 'en') return;

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
  // le glossaire découpe les nœuds de texte du panneau et du contexte dans une microtâche : traduire avant (écouteurs synchrones)
  const zones = () => { for (const id of ['panel', 'context']) { const z = document.getElementById(id); if (z) fix(z); } };
  SC.on?.('panel', zones); SC.on?.('render', zones);
  const v = tr(document.title); if (v != null) document.title = v;
})();
