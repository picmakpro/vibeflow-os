// vibeflow:fr
// VibeFlow (67-07, 79-10) : le chrome du viewer en français. Le traducteur `window.__vfFrT` (nommé `t` dans chaque fichier du moteur)
// traduit au point d'émission : la clé est le texte anglais source, la valeur vient de la table (fichiers 78 et 79 → window.__vfFrDict).
// Ce fichier est posé AVANT le script principal (emplacement UI_I18N de la page) : la table existe quand un fichier appelle `t` au chargement.
// Sous ?lang=en (ligne `garde:lang-en`), `t` rend la clé et rien d'autre n'est posé. Fonction pure : window.__vfFrTraduire(texte) → phrase ou null.
// Reste de l'ancien mécanisme (retiré à la tâche 6 du plan 79-10) : le moteur de reconnaissance d'une forme rendue (noyau, motifs R, gabarits P).
(() => {
  const EN = new URLSearchParams(location.search).get('lang') === 'en'; // garde:lang-en
  const D = window.FLOORPLAN; // la donnée de la page, posée avant ce script : l'onglet se lit là, jamais dans l'objet du moteur (absent à ce moment)
  const projet = () => D?.meta?.vfTab === 'project';
  const TBL = Object.assign({}, window.__vfFrDict || {}); // copie INTACTE de la table, clés à `{}` comprises
  const T = Object.assign({}, TBL);
  // l'onglet Code garde des fichiers ; sur l'onglet Projet, un « fichier » est un plan, une exigence, une étape (lue aussi par les gabarits ci-dessous)
  const SURCHARGE = projet()
    ? { File: 'Élément', file: 'élément', Files: 'Éléments', files: 'éléments', 'Files involved': 'Éléments concernés', 'Search files, routes, modules': 'Chercher une carte, un plan, une exigence', '{} file': '{} élément|{} éléments' }
    : { File: 'Fichier', file: 'fichier', Files: 'Fichiers', files: 'fichiers', 'Files involved': 'Fichiers concernés', 'Search files, routes, modules': 'Chercher un fichier, une route, un module', '{} file': '{} fichier|{} fichiers' };
  // clés à variables (`{}`) : une phrase de gabarit, la variable prise telle quelle puis traduite à son tour ; une valeur peut
  // porter « singulier|pluriel » (le premier `{}` est le compte, un « s » final facultatif est toléré dans la clé) et omettre
  // des `{}`, jamais en ajouter. Un gabarit au texte fixe court (< 16 caractères : « {} of {} », « {} with {} ») ne s'applique que si une variable
  // est un nombre ou se traduit elle-même : sans cela il abîmerait les données du lab (« Top of the world »).
  // gabarits dont une variable est une liste construite par le viewer (« A, B and C ») : le « and » final y est traduit, nulle part ailleurs
  const LISTES = ['It also relies on {}{}. They sit at the edge of the map; the lines show which parts talk to them.', 'How do {} relate?'];
  // gabarits dont la variable est un nom du lab, laissé intact : « Inside {} » (en-tête d'une carte ouverte) ; durées : la variable est un nombre ou rien
  const LIBRES = ['Inside {}', 'You asked: {}', 'Everything behind {}', 'Exported {}', 'Changed · {}', '{} contains {}'];
  // AUDC-H4 : gabarits dont les variables sont des noms (ou des phrases) du lab, jamais traduits : « Dans Tokens », « Tokens contient Open »
  const NOMS = ['Inside {}', 'You asked: {}', 'Everything behind {}', '{} contains {}'];
  const P = [];
  const esc = (x) => x.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  for (const [k, v] of Object.entries({ ...T, ...SURCHARGE })) if (k.includes('{}')) { delete T[k]; P.push([new RegExp('^' + k.split('{}').map(esc).join('(.*?)') + (v.includes('|') && /[a-z]$/.test(k) ? 's?' : '') + '$'), v.split('|').map((x) => x.split('{}')), k.replace(/\{\}/g, '').length, LISTES.includes(k), LIBRES.includes(k), /^\{\} \w+ ago$/.test(k), NOMS.includes(k)]); }
  P.sort((a, b) => b[2] - a[2]); // du plus précis au plus général : « {} and {} » ne capture plus une phrase longue qui contient « and »
  Object.assign(T, SURCHARGE);
  // sous-titre de la carte Projet (« Jalon v1 · phase 1 (Socle) · ready_to_plan. »), fabriqué par le socle avec le statut STATE brut : seul le dernier segment, un statut connu, est traduit (recette 68 R11, P68-D-35)
  const STATUTS = { ready_to_plan: 'prête à planifier', ready_to_execute: 'prête à exécuter', milestone_complete: 'jalon terminé', executing: 'en exécution', planning: 'en planification', verifying: 'en vérification', paused: 'en pause', completed: 'terminée', complete: 'terminée', closed: 'clos' };
  const R = [
    [/^(Jalon .+ · phase .+) · (ready_to_plan|ready_to_execute|milestone_complete|executing|planning|verifying|paused|completed|complete|closed)\.$/, (_, d, s) => `${d} · ${STATUTS[s]}.`],
    [/^(\d+) things?$/, (_, n) => `${n} point${n > 1 ? 's' : ''}`],
    [/^Answer · (\d+) cards?$/, (_, n) => `Réponse · ${n} carte${n > 1 ? 's' : ''}`],
    [/^Ask anything about (.+?)…$/, () => 'Posez une question sur ce projet…'], // le nom du projet est déjà dans l'en-tête : l'invite tient dans la barre à toute largeur
    [/^(.+) map$/, (_, x) => x],
    [/^Searching the map for "(.+)"$/, (_, x) => `Cherche « ${x} » dans la carte`],
    [/^Searching code for "(.+)"$/, (_, x) => `Cherche « ${x} » dans le code`],
    [/^Looking at (.+)$/, (_, x) => `Examine ${x}`], [/^Reading (.+)$/, (_, x) => `Lit ${x}`], [/^Listing (.+)$/, (_, x) => `Liste ${x}`],
    [/^Running a command$/, () => 'Lance une commande'], [/^Tracing a dependency path$/, () => 'Suit une chaîne de dépendances'],
    [/^(.+) and (\d+) more$/, (_, a, n) => `${a} et ${n} ${n > 1 ? 'autres' : 'autre'}`], // « Readme and 7 more » : liste de noms du viewer, le dernier segment est un compte
    [/^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) (\d{1,2}), (\d{4})$/, (_, m, d, y) => `${d} ${{ Jan: 'janv.', Feb: 'févr.', Mar: 'mars', Apr: 'avr.', May: 'mai', Jun: 'juin', Jul: 'juil.', Aug: 'août', Sep: 'sept.', Oct: 'oct.', Nov: 'nov.', Dec: 'déc.' }[m]} ${y}`], // date de l'en-tête d'export (toLocaleDateString en anglais)
    [/^\(\+(\d+) more\)$/, (_, n) => `(+${n} autres)`], [/^\+(\d+) more$/, (_, n) => `+${n} autres`],
    [/^(\d+) cards?$/, (_, n) => `${n} carte${n > 1 ? 's' : ''}`], [/^(\d+) files?$/, (_, n) => `${n} ${projet() ? 'élément' : 'fichier'}${n > 1 ? 's' : ''}`],
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
    if (out == null) for (const [re, formes, fixe, liste, libre, duree, nom] of P) {
      const m = re.exec(t); if (!m) continue;
      if (duree && !/^\d+$/.test(m[1].trim())) continue; // « Updated 3 minutes ago » n'est pas « {} minutes ago » : la durée porte un nombre seul
      if (formes.length > 1 && !/^\d+$/.test(m[1].trim()) && !/^\d+(\.\d)?k$/.test(m[1].trim())) continue; // « singulier|pluriel » : seulement derrière un nombre (« Uses connection » n'est pas « 1 connection »)
      if (!(fixe >= 16 || libre || m.slice(1).some((c) => /^\d+(\.\d)?k?$/.test(c.trim()) || noyau(c.trim()) != null))) continue;
      out = formes[formes.length > 1 && Number(m[1]) !== 1 ? 1 : 0].reduce((x, p, i) => { if (!i) return x + p; const [a, b] = lier(x, nom ? m[i] : liste ? enListe(noyau(m[i].trim()) ?? m[i]) : (noyau(m[i].trim()) ?? m[i])); return a + b + p; }, '');
      break;
    }
    if (out == null) for (const [re, f] of R) { if (re.test(t)) { out = t.replace(re, f); break; } }
    if (out == null && t.includes(' · ')) { const seg = t.split(' · ').map((x) => noyau(x)); if (seg.some((x) => x != null)) out = seg.map((x, i) => x ?? t.split(' · ')[i]).join(' · '); }
    if (out == null && /^[^:]{3,}: ./.test(t)) { const i = t.indexOf(': '); const g = noyau(t.slice(0, i)), d = noyau(t.slice(i + 2)); if (g != null || d != null) { const a = g ?? t.slice(0, i), b = d ?? t.slice(i + 2); out = a === b && t.slice(0, i) === t.slice(i + 2) ? a : a + ' : ' + b; } } // « Recent work: Recent work » (fil d'Ariane d'un tableau sans titre propre) ne le dit qu'une fois
    // pluriel composé à l'exécution (« files », « screens ») : le singulier du dictionnaire, un « s » en plus
    if (out == null && /^[A-Za-z]{3,}s$/.test(t) && T[t.slice(0, -1)] != null) out = T[t.slice(0, -1)] + 's';
    return out;
  };
  // « 1.3k » / « 48k » (fmt du viewer) → « 1,3 k » / « 48 k » : virgule décimale, espace insécable avant l'unité (PU-G-066)
  const kfr = (x) => x.replace(/(^|[^\w.,])(\d+)(?:\.(\d))?k\b/g, (_, a, i, d) => `${a}${i}${d ? ',' + d : ''}\u00a0k`);
  const SING = { lignes: 'ligne', fichiers: 'fichier', 'éléments': 'élément', "points d'accès": "point d'accès" };
  const tr = (s) => {
    const t = typeof s === 'string' ? s.trim() : ''; if (!t || t.length > 600 || !/[A-Za-z]/.test(t)) return null; // chaîne vide → rien : garde contre la boucle des attributs vides
    const brut = noyau(t), out = brut == null ? null : kfr(brut);
    return out == null || out === t ? null : s.replace(t, () => out); // une fonction : `$&`, `$'`, `$$` d'un chemin ne sont jamais interprétés
  };
  window.__vfFrTraduire = tr;
  tr.motifs = R.length; tr.gabarits = P.length; // lu par le test chrome-fr
  // Types fixes de carte (recette 2026-11-02 : « Library » au-dessus du dossier). Le viewer écrit le NOM DU TYPE tel quel (minuscule, ou 1re lettre
  // en capitale dans l'en-tête de la vue) à quatre endroits : libellé du panneau, en-tête de la vue, rang de la recherche, première partie de
  // l'infobulle. Ils sont traduits PAR EMPLACEMENT, jamais par le dictionnaire : un dossier du lab nommé « library » ou « config » est une donnée et reste intact.
  const TYPES = { ui: 'interface', service: 'module', worker: 'tâche de fond', library: 'bibliothèque', feature: 'fonctionnalité', data: 'données', config: 'configuration', test: 'test', script: 'script',
    infra: 'infrastructure', external: 'service externe', misc: 'divers', endpoint: "point d'accès", function: 'fonction', class: 'classe', route: 'route', dir: 'dossier', module: 'module' };
  const type = (s) => { const t = typeof s === 'string' ? s.trim() : '', k = Object.prototype.hasOwnProperty.call(TYPES, t.toLowerCase()) ? TYPES[t.toLowerCase()] : null; return k == null ? null : s.replace(t, () => (/^[A-Z]/.test(t) ? k[0].toUpperCase() + k.slice(1) : k)); };
  window.__vfFrType = type;
  // le traducteur (79-10, P79-D-24) : t(clé, ...variables). `{}` rempli dans l'ordre, forme « singulier|pluriel » choisie sur la PREMIÈRE variable,
  // « de » + variable lié (lier). `@contexte` en fin de clé : la clé complète puis la clé sans contexte. Clé sans valeur : la clé remplie.
  // Sous ?lang=en : la clé remplie, aucune valeur de table lue.
  const TT = { ...TBL, ...SURCHARGE }, a = (c) => Object.prototype.hasOwnProperty.call(TT, c), sans = (c) => c.replace(/@[\w-]+$/, '');
  const plein = (f, v) => f.split('{}').reduce((x, p, i) => (i ? x + String(v[i - 1] ?? '') + p : x + p), '');
  const lie = (f, v) => f.split('{}').reduce((x, p, i) => { if (!i) return x + p; const [m, w] = lier(x, String(v[i - 1] ?? '')); return m + w + p; }, '');
  const trad = (cle, ...v) => {
    if (EN) return plein(sans(cle), v);
    const val = a(cle) ? TT[cle] : a(sans(cle)) ? TT[sans(cle)] : sans(cle), f = val.split('|');
    return lie(f[f.length > 1 && Number(v[0]) !== 1 ? 1 : 0], v);
  };
  trad.pl = (n, mot) => (EN ? `${n} ${mot}${Number(n) === 1 ? '' : 's'}` : trad(`{} ${mot}`, n));
  trad.mot = (n, cle) => { if (EN) return cle; const v = trad(cle); return Number(n) === 1 && SING[v] ? SING[v] : v; };
  trad.k = (x) => (EN ? x : kfr(x));
  trad.type = (x) => (EN ? null : type(x));
  trad.constat = (x) => (EN ? x : (tr(x) ?? x));
  trad.langue = EN ? undefined : 'fr';
  window.__vfFrT = trad;
  const typeDuTexte = (n) => {
    const p = n.parentElement, t = n.nodeValue; if (!p) return null;
    if (p.matches('.kindlabel, #results .rk, #context .k')) return type(t);
    if (p.matches('#tooltip .td')) { const i = t.indexOf(' · '), k = type(i < 0 ? t : t.slice(0, i)); return k == null ? null : k + (i < 0 ? '' : t.slice(i)); }
    if (p.matches('.stats b') && /^\d+(\.\d)?k$/.test(t.trim())) return kfr(t); // chiffre abrégé d'un panneau
    if (p.matches('.stats span') && p.previousElementSibling?.matches('b') && p.previousElementSibling.textContent.trim() === '1') { const f = tr(t); return f != null && SING[f.trim()] ? SING[f.trim()] : null; } // « 1 ligne », « 1 fichier »
    if (p.matches('.rw') && t.trim() === 'Changed') return 'Récent'; // pastille d'une carte touchée par une phase récente (« modifié » reste l'état Git)
    if (p.matches('.tag')) { // « Détecté via » : l'origine de chaque correspondance, dite en toutes lettres (PU-G-070)
      const h3 = p.closest('.sec')?.querySelector('h3')?.textContent.trim();
      if (h3 === 'Matched by' || h3 === 'Détecté via') { const m = /^(pkg|host|#) ?(.+)$/.exec(t.trim()); if (m) return ({ pkg: 'paquet', host: 'hôte', '#': 'tag' })[m[1]] + ' ' + m[2]; }
    }
    return null;
  };
  if (EN) return;

  // squelette : le texte et les attributs du balisage statique de la page, en UNE passe, avant tout rendu de donnée (clé exacte seulement)
  const ATTRS = ['placeholder', 'title', 'aria-label'];
  const ecrit = (n, v) => { const x = v.trim(); if (x && a(x)) n.nodeValue = v.replace(x, () => trad(x)); };
  const marche = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  for (let n = marche.nextNode(); n; n = marche.nextNode()) if (!n.parentElement?.closest('script,style,textarea,pre,code')) ecrit(n, n.nodeValue);
  for (const el of document.body.querySelectorAll('[placeholder],[title],[aria-label]')) {
    for (const at of ATTRS) { const x = (el.getAttribute(at) || '').trim(); if (x && a(x)) el.setAttribute(at, trad(x)); }
  }

  // l'ancien glue (observateurs, écouteurs de rendu, couleurs, styles, lang) : tout de suite si l'objet du moteur existe, sinon au chargement de la page
  const glue = (SC) => { const G = SC.graph;
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
  // infobulle d'une carte : le viewer capitalise chaque mot (« 115 Fichiers · 48k Lignes ») ; en français, seule la première lettre l'est (PU-G-066, PU-G-161)
  sp.textContent += ' #tooltip .td[style*="capitalize"] { text-transform: none !important; } #tooltip .td[style*="capitalize"]::first-letter { text-transform: uppercase; }';
  document.head.appendChild(sp);

  // la mise en page de l'en-tête (libellés français plus longs) est le travail de 01-vf-responsive.js

  const probe = (window.__vfFr = { nodes: 0, attrs: 0, passes: 0, ms: 0 });
  // AUDC-H4 : le titre et la description d'une carte sont des DONNÉES du lab (« tokens.ts » ne devient pas « Jetons ») ; « No description yet » (.desc.empty) est du chrome et reste traduit
  // même propriété ailleurs où le viewer reprend ces données : titre et description du panneau de détail (.pt, .pd), nom et description d'une ligne de liste ou d'un résultat de recherche (.rn, .rd), nom d'une carte dans l'infobulle (.tt), fil d'Ariane
  const SKIP = 'script,style,code,pre,textarea,.mono,.rp,.pp,.card .title,.card .desc:not(.empty),#panel .pt,.row .rn,.row:not(.vf-rep) .rd,#results .rn,#results .rd';
  // deux emplacements mêlent donnée et chrome : l'infobulle d'une carte (le nom) et celle d'un lien (« A contains B », gabarit) ; le fil d'Ariane (« Overview », « Réponse : titre » sont du chrome, un nom de dossier est une donnée)
  // (« #panel .pd » : la description d'une carte ou d'un lien est une donnée ; le texte de repli que le viewer calcule pour un lien sans description (« 1 connection. », « 3 connections across 2 endpoints. ») n'en est pas une et reste traduit ; les rangées d'une réponse (.row.vf-rep) gardent leur NOM de carte intact, leur note reste traduite)
  const REPLI_LIEN = /^\d+ connections?( across \d+ endpoints?)?(, matched from call sites to route definitions)?\.$/;
  // le glossaire enveloppe un mot de la description (« endpoints ») dans un <span class="sc-term"> : c'est l'ANCÊTRE .pd, pas le parent du nœud, qui dit que le texte est une donnée (AUDC-H4, restes) ; le texte de repli se juge sur la description entière
  const DONNEE = (n) => { const p = n.parentElement, t = n.nodeValue, pd = p.closest('#panel .pd:not(.empty)'); return pd ? !REPLI_LIEN.test(pd.textContent.trim()) : p.matches('#tooltip .tt') ? !/ contains /.test(t) : p.matches('#crumbs button') ? t.trim() !== 'Overview' && !t.includes(': ') : false; };
  // « 42 files in plugin/cockpit/signal/ » : la description que le MOTEUR fabrique pour une carte dossier (viewer.html, `${plural(n, 'file')} in ${chemin}/`) ; le gabarit est du chrome, le chemin une donnée jamais traduite.
  // Forme stricte et entière : une description du lab qui ne la reproduit pas à l'identique n'est jamais touchée (AUDC-H4, restes ; la traduction au point d'émission relève de la Phase 79)
  const DOSSIER = /^(\d+) files? in (\S.*\/)$/;
  // l'IDENTITÉ de l'item, jamais la forme du texte : une description de carte FICHIER égale au gabarit est une donnée. Panneau : l'item sélectionné est un dossier (id « d: ») ; ligne de liste : son `data-go` est un dossier ; résultat de recherche : son type affiché est « dir » (ou « dossier » une fois traduit) — branche DÉFENSIVE : l'index de recherche du produit n'a pas de dossier, elle ne se déclenche pas aujourd'hui
  const estDossier = (p) => {
    if (p.matches('.row:not(.vf-rep) .rd')) return String(p.closest('.row').getAttribute('data-go') || '').startsWith('d:');
    if (p.matches('#results .rd')) return /^(dir|dossier)$/.test((p.closest('.r')?.querySelector('.rk')?.textContent || '').trim());
    if (!p.matches('#panel .pd:not(.empty)')) return false;
    // même cible que renderPanel() : `selected` s'il est une chaîne (connecteur « x:in:|x:out: » retiré, « m: » ramené à « f: »), sinon le CONTENEUR ouvert (dossier ouvert par go(), sans sélection) ; un objet (lien) n'est pas un dossier
    const st = window.VibeFlow?.state, sel = st?.selected;
    if (sel && typeof sel === 'object') return false;
    return (sel ? String(sel).replace(/^x:(?:in|out):/, '').replace(/^m:/, 'f:') : String(st?.container ?? '')).startsWith('d:');
  };
  const dossier = (n) => { const p = n.parentElement, t = n.nodeValue.trim(), m = DOSSIER.exec(t); if (!m || !p || !estDossier(p)) return null; const nom = projet() ? 'élément' : 'fichier'; return n.nodeValue.replace(t, () => `${m[1]} ${nom}${m[1] === '1' ? '' : 's'} dans ${m[2]}`); };
  const fix = (root) => {
    const t0 = performance.now();
    const w = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    for (let n = w.nextNode(); n; n = w.nextNode()) {
      const d = n.parentElement ? dossier(n) : null; if (d != null) { if (d !== n.nodeValue) { n.nodeValue = d; probe.nodes++; } continue; }
      if (n.parentElement?.closest(SKIP) || (n.parentElement && DONNEE(n))) continue;
      const k = typeDuTexte(n); if (k != null && k !== n.nodeValue) { n.nodeValue = k; probe.nodes++; continue; }
      const v = tr(n.nodeValue); if (v != null) { n.nodeValue = v; probe.nodes++; }
    }
    const els = root.nodeType === 1 ? [root, ...root.querySelectorAll('[placeholder],[title],[aria-label]')] : [];
    for (const el of els) for (const a of ATTRS) { if (a === 'title' && el.matches?.('.row.vf-rep')) continue; if (a === 'aria-label' && el.matches?.('#viewport .node')) continue; /* AUDC-H4 : le nom accessible d'une carte (posé par le viewer à l'atterrissage au clavier) est son nom de donnée */ /* AUDC-H4 : le `title` d'une rangée de réponse reprend le nom de la carte (et sa note) : donnée du lab */ const x = el.getAttribute?.(a); const v = x ? tr(x) : null; if (v != null) { el.setAttribute(a, v); probe.attrs++; } }
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
  };
  const lancer = () => { if (window.Floorplan) glue(window.Floorplan); };
  if (window.Floorplan || document.readyState !== 'loading') lancer(); else document.addEventListener('DOMContentLoaded', lancer, { once: true });
})();
