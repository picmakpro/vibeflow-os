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
  // gabarits dont une variable est une liste construite par le viewer (« A, B and C ») : le « and » final y est traduit, nulle part ailleurs
  const LISTES = ['It also relies on {}{}. They sit at the edge of the map; the lines show which parts talk to them.', 'How do {} relate?'];
  const P = [];
  const esc = (x) => x.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  for (const [k, v] of Object.entries(T)) if (k.includes('{}')) { delete T[k]; P.push([new RegExp('^' + k.split('{}').map(esc).join('(.*?)') + (v.includes('|') && /[a-z]$/.test(k) ? 's?' : '') + '$'), v.split('|').map((x) => x.split('{}')), k.replace(/\{\}/g, '').length, LISTES.includes(k)]); }
  P.sort((a, b) => b[2] - a[2]); // du plus précis au plus général : « {} and {} » ne capture plus une phrase longue qui contient « and »
  // l'onglet Code garde des fichiers ; sur l'onglet Projet, un « fichier » est un plan, une exigence, une étape
  Object.assign(T, projet()
    ? { File: 'Élément', file: 'élément', Files: 'Éléments', 'Files involved': 'Éléments concernés', 'Search files, routes, modules': 'Chercher une carte, un plan, une exigence' }
    : { File: 'Fichier', file: 'fichier', Files: 'Fichiers', 'Files involved': 'Fichiers concernés', 'Search files, routes, modules': 'Chercher un fichier, une route, un module' });
  const R = [
    [/^(\d+) things?$/, (_, n) => `${n} point${n > 1 ? 's' : ''}`],
    [/^Answer · (\d+) cards?$/, (_, n) => `Réponse · ${n} carte${n > 1 ? 's' : ''}`],
    [/^Ask anything about (.+?)…$/, () => 'Posez une question sur ce projet…'], // le nom du projet est déjà dans l'en-tête : l'invite tient dans la barre à toute largeur
    [/^(.+) map$/, (_, x) => x],
    [/^Searching the map for "(.+)"$/, (_, x) => `Cherche « ${x} » dans la carte`],
    [/^Searching code for "(.+)"$/, (_, x) => `Cherche « ${x} » dans le code`],
    [/^Looking at (.+)$/, (_, x) => `Examine ${x}`], [/^Reading (.+)$/, (_, x) => `Lit ${x}`], [/^Listing (.+)$/, (_, x) => `Liste ${x}`],
    [/^Running a command$/, () => 'Lance une commande'], [/^Tracing a dependency path$/, () => 'Suit une chaîne de dépendances'],
    [/^\(\+(\d+) more\)$/, (_, n) => `(+${n} autres)`], [/^\+(\d+) more$/, (_, n) => `+${n} autres`],
    [/^(\d+) cards?$/, (_, n) => `${n} carte${n > 1 ? 's' : ''}`], [/^(\d+) files?$/, (_, n) => `${n} ${G.meta.vfTab === 'project' ? 'élément' : 'fichier'}${n > 1 ? 's' : ''}`],
    [/^Theme: (.+)\. Press for (.+)\.$/, (_, a, b) => `Thème : ${T[a] || a}. Appuyer pour ${(T[b.replace(/\.$/, '')] || b).toLowerCase()}.`],
  ];
    // « de » + variable : élision (« d'Anthropic »), contraction (« du CLI », « des … ») ; seulement là où la variable suit « de »
  const lier = (x, v) => {
    if (!/(^|[^\p{L}])de $/u.test(x)) return [x, v];
    if (/^le /.test(v)) return [x.slice(0, -3) + 'du ', v.slice(3)];
    if (/^les /.test(v)) return [x.slice(0, -3) + 'des ', v.slice(4)];
    return /^[aeiouyàâéèêîôû]/i.test(v) ? [x.slice(0, -3) + "d'", v] : [x, v];
  };
  const enListe = (v) => v.replace(/ and (\d+) more$/, ' et $1 autres').replace(/ and (?!.* and )/, ' et ');
  const noyau = (t) => {
    let out = T[t];
    if (out == null) for (const [re, formes, fixe, liste] of P) {
      const m = re.exec(t); if (!m) continue;
      if (formes.length > 1 && !/^\d+$/.test(m[1].trim())) continue; // « singulier|pluriel » : seulement derrière un nombre (« Uses connection » n'est pas « 1 connection »)
      if (!(fixe >= 16 || m.slice(1).some((c) => /^\d+$/.test(c.trim()) || noyau(c.trim()) != null))) continue;
      out = formes[formes.length > 1 && Number(m[1]) !== 1 ? 1 : 0].reduce((x, p, i) => { if (!i) return x + p; const [a, b] = lier(x, liste ? enListe(noyau(m[i].trim()) ?? m[i]) : (noyau(m[i].trim()) ?? m[i])); return a + b + p; }, '');
      break;
    }
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
    return out == null || out === t ? null : s.replace(t, () => out); // une fonction : `$&`, `$'`, `$$` d'un chemin ne sont jamais interprétés
  };
  window.__vfFrTraduire = tr;
  tr.motifs = R.length; tr.gabarits = P.length; // lu par le test chrome-fr
  // Types fixes de carte (recette 2026-11-02 : « Library » au-dessus du dossier). Le viewer écrit le NOM DU TYPE tel quel (minuscule, ou 1re lettre
  // en capitale dans l'en-tête de la vue) à quatre endroits : libellé du panneau, en-tête de la vue, rang de la recherche, première partie de
  // l'infobulle. Ils sont traduits PAR EMPLACEMENT, jamais par le dictionnaire : un dossier du lab nommé « library » ou « config » est une donnée et reste intact.
  const TYPES = { ui: 'interface', service: 'service', worker: 'tâche de fond', library: 'bibliothèque', feature: 'fonctionnalité', data: 'données', config: 'configuration', test: 'test', script: 'script',
    infra: 'infrastructure', external: 'service externe', misc: 'divers', endpoint: "point d'accès", function: 'fonction', class: 'classe', route: 'route', dir: 'dossier', module: 'module' };
  const type = (s) => { const t = typeof s === 'string' ? s.trim() : '', k = Object.prototype.hasOwnProperty.call(TYPES, t.toLowerCase()) ? TYPES[t.toLowerCase()] : null; return k == null ? null : s.replace(t, () => (/^[A-Z]/.test(t) ? k[0].toUpperCase() + k.slice(1) : k)); };
  window.__vfFrType = type;
  const typeDuTexte = (n) => {
    const p = n.parentElement, t = n.nodeValue; if (!p) return null;
    if (p.matches('.kindlabel, #results .rk, #context .k')) return type(t);
    if (p.matches('#tooltip .td')) { const i = t.indexOf(' · '), k = type(i < 0 ? t : t.slice(0, i)); return k == null ? null : k + (i < 0 ? '' : t.slice(i)); }
    return null;
  };
  if (!SC || new URLSearchParams(location.search).get('lang') === 'en') return;

  // couleurs des types : sombre par défaut, clair sous data-theme="light" (même règle que le viewer)
  const C = G.meta.kindColors || {};
  if (Object.keys(C).length) {
    const st = document.createElement('style');
    st.textContent = `:root { ${Object.entries(C).map(([k, [, d]]) => `--n-${k}: ${d};`).join(' ')} }
      :root[data-theme="light"] { ${Object.entries(C).map(([k, [l]]) => `--n-${k}: ${l};`).join(' ')} }`;
    document.head.appendChild(st);
  }

  // l'en-tête de panneau : le viewer capitalise chaque mot (« Contrôle De Santé ») ; en français, seule la première lettre l'est (P70-D-04)
  const sp = document.createElement('style');
  sp.textContent = '.ph .kindlabel { text-transform: none; display: inline-block; } .ph .kindlabel::first-letter { text-transform: uppercase; }';
  document.head.appendChild(sp);

  // la mise en page de l'en-tête (libellés français plus longs) est le travail de 01-vf-responsive.js

  const probe = (window.__vfFr = { nodes: 0, attrs: 0, passes: 0, ms: 0 });
  const ATTRS = ['placeholder', 'title', 'aria-label'];
  const SKIP = 'script,style,code,pre,textarea,.mono,.rp,.pp';
  const fix = (root) => {
    const t0 = performance.now();
    const w = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    for (let n = w.nextNode(); n; n = w.nextNode()) {
      if (n.parentElement?.closest(SKIP)) continue;
      const k = typeDuTexte(n); if (k != null && k !== n.nodeValue) { n.nodeValue = k; probe.nodes++; continue; }
      const v = tr(n.nodeValue); if (v != null) { n.nodeValue = v; probe.nodes++; }
    }
    const els = root.nodeType === 1 ? [root, ...root.querySelectorAll('[placeholder],[title],[aria-label]')] : [];
    for (const el of els) for (const a of ATTRS) { const x = el.getAttribute?.(a); const v = x ? tr(x) : null; if (v != null) { el.setAttribute(a, v); probe.attrs++; } }
    probe.passes++; probe.ms += performance.now() - t0;
  };
  document.documentElement.lang = 'fr';
  // le viewer réécrit le titre après coup (« <nom> map ») : on le suit
  new MutationObserver(() => { const v = tr(document.title); if (v != null) document.title = v; }).observe(document.querySelector('title'), { childList: true });
  // regroupe les mutations d'un même lot (un rendu du viewer en produit des centaines) et les traduit avant la peinture : le callback d'un
  // MutationObserver part en fin de tâche, avant l'image suivante ; passer par requestAnimationFrame laissait « Thinking… » une image en anglais
  new MutationObserver((ms) => {
    const q = new Set();
    for (const m of ms) q.add(m.type === 'characterData' ? m.target.parentElement : m.target);
    for (const el of q) if (el?.isConnected) fix(el);
  }).observe(document.body, { subtree: true, childList: true, characterData: true, attributes: true, attributeFilter: ATTRS });
  fix(document.body);
  // le glossaire découpe les nœuds de texte du panneau et du contexte dans une microtâche : traduire avant (écouteurs synchrones)
  const zones = () => { for (const id of ['panel', 'context']) { const z = document.getElementById(id); if (z) fix(z); } };
  SC.on?.('panel', zones); SC.on?.('render', zones);
  const v = tr(document.title); if (v != null) document.title = v;
})();
