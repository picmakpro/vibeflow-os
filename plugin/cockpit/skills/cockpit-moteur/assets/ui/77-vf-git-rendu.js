// VibeFlow (78-06) : rendus purs du tiroir Git — graphe SVG en couloirs, rangées, sections, commandes à copier, états (GITC-06, 08, 10 ; P78-D-14).
// Tout texte venu de git s'écrit en textContent, tout attribut par setAttribute, le SVG par createElementNS : aucune donnée ne devient du HTML.
// Les couleurs passent par des classes `vf-git-t0..t5` (feuille dans 77-vf-git-tiroir.js) ; le comportement (ouverture, GET, clavier) est dans ce fichier-là.
// Exposé : window.VFGitRendu (+ `section`, utilisé par le tiroir pour le Graphe). Point d'extension paresseux (78-10, détail d'un commit) : si window.VFGitExt existe à l'appel, ses crochets `rangee(li, r)` sont appelés ; jamais requis, aucun ordre de chargement imposé.
(() => {
  const COPIE = 'M9 9h10v10H9zM5 15V5h10', COCHE = 'M5 13l4 4L19 7', NS = 'http://www.w3.org/2000/svg', LARG = 16, NOEUD = 4, TRAIT = 1.75, RAYON = 16;
  const el = (tag, cls, txt, at) => {
    const e = document.createElement(tag);
    if (cls) e.className = cls;
    if (txt != null) e.textContent = String(txt);
    for (const k in at || {}) e.setAttribute(k, String(at[k]));
    return e;
  };
  const sv = (tag, at, parent) => {
    const e = document.createElementNS(NS, tag);
    for (const k in at) e.setAttribute(k, String(at[k]));
    if (parent) parent.appendChild(e);
    return e;
  };
  const crochet = (nom, ...a) => { const E = window.VFGitExt; if (E && typeof E[nom] === 'function') { try { E[nom](...a); } catch (e) { void e; } } };
  const ico = (d) => { const s = sv('svg', { class: 'i', viewBox: '0 0 24 24', 'aria-hidden': 'true' }); sv('path', { d }, s); return s; };
  const pl = (n, mot, plur) => `${n} ${n > 1 ? plur || mot + 's' : mot}`;
  const avance = (a) => a == null ? el('span', 'meta', '—', { role: 'img', 'aria-label': 'avance inconnue', title: 'avance inconnue' }) : el('span', 'meta', pl(a, 'commit')); // null = inconnu (dépôt sans base, au-delà de la limite) : jamais « 0 commit »
  // PU-G-193 et 196 (recette du 2026-11-08, arbitrage Samuel, AskUserQuestion session principale, 2026-11-08 : « Les partiels qui te concernaient ») : la définition d'un terme Git ne passait que par `title`, visible au survol de la souris
  // seulement. aideFocus la montre aussi au FOCUS clavier, dans une bulle visuelle unique (texte posé en textContent, jamais du HTML ; aria-hidden : le lecteur d'écran lit déjà la même phrase par aria-description ou aria-label).
  // Échap la ferme sans fermer le tiroir ; elle se ferme aussi au départ du focus et suit l'élément quand il défile.
  let bulle = null, ancre = null, clavier = false; // clavier : la dernière entrée était une touche (un focus posé par script ne vaut :focus-visible qu'après une touche ou sur un élément déjà visible au clavier) ; un clic de souris la remet à faux
  document.addEventListener('keydown', () => { clavier = true; }, true); document.addEventListener('pointerdown', () => { clavier = false; }, true);
  const cacher = () => { if (bulle) bulle.hidden = true; ancre = null; };
  const placer = () => {
    if (!bulle || bulle.hidden || !ancre) return;
    const r = ancre.getBoundingClientRect(), b = bulle.getBoundingClientRect(), bas = r.bottom + 6 + b.height <= window.innerHeight - 8;
    bulle.style.top = Math.max(8, bas ? r.bottom + 6 : r.top - 6 - b.height) + 'px';
    bulle.style.left = Math.max(8, Math.min(r.left, window.innerWidth - b.width - 8)) + 'px';
  };
  const montrer = (e, texte) => {
    if (!bulle) { bulle = el('div', 'vf-git-bulle glass', null, { role: 'tooltip', 'aria-hidden': 'true' }); bulle.hidden = true; document.body.appendChild(bulle); window.addEventListener('scroll', placer, true); } // le focus fait défiler l'élément dans sa fenêtre : la bulle le suit (elle ne se ferme pas au défilement, sinon le focus clavier d'un élément hors champ ne la montrerait jamais)
    bulle.textContent = texte; bulle.hidden = false; ancre = e; placer();
  };
  const aideFocus = (e, texte) => {
    e.setAttribute('tabindex', '0');
    e.addEventListener('focus', () => { if (clavier || e.matches(':focus-visible')) montrer(e, typeof texte === 'function' ? texte() : texte); }); // texte : une chaîne, ou une fonction quand la définition change avec la vue (titre de la vue)
    e.addEventListener('blur', cacher);
    e.addEventListener('keydown', (ev) => { if (ev.key === 'Escape' && bulle && !bulle.hidden && ancre === e) { ev.stopPropagation(); ev.preventDefault(); cacher(); } });
    return e;
  };
  const relatif = (at, maintenant) => {
    const s = Math.max(0, Math.floor(((maintenant == null ? Date.now() : maintenant) - at * 1000) / 1000)), m = Math.floor(s / 60), h = Math.floor(m / 60), j = Math.floor(h / 24);
    if (s < 60) return "à l'instant";
    if (m < 60) return `il y a ${m} min`;
    if (h < 24) return `il y a ${h} h`;
    if (j < 30) return `il y a ${j} j`;
    return j < 365 ? `il y a ${Math.floor(j / 30)} mois` : `il y a ${Math.floor(j / 365)} an${j >= 730 ? 's' : ''}`;
  };
  const complet = (at) => new Date(at * 1000).toLocaleString('fr-FR', { dateStyle: 'long', timeStyle: 'short' });

  // ---------- commande à copier : le texte copié est le textContent du <code> affiché, jamais une copie transformée (T-78-24) ----------
  // `nom` (200) : ce que fait la commande, court (« cd vers bisect-ci ») ; il n'entre que dans l'aria-label, par setAttribute, jamais en HTML ni dans la commande copiée
  const commande = (texte, annonce, nom) => {
    if (texte == null) return el('div', 'vf-git-sans', 'Aucune commande proposée');
    const ligne = el('div', 'vf-git-cmd'), code = el('code', null, texte, { title: texte }), retour = el('span', 'vf-git-retour');
    const b = el('button', 'vf-git-btn', null, { type: 'button', 'aria-label': 'Copier la commande' + (nom ? ' ' + nom : '') });
    b.appendChild(ico(COPIE));
    ligne.append(code, retour, b);
    let minuterie = null;
    const dire = (t, coche) => { retour.textContent = t; b.replaceChildren(ico(coche ? COCHE : COPIE)); clearTimeout(minuterie); minuterie = setTimeout(() => { retour.textContent = ''; b.replaceChildren(ico(COPIE)); }, 1600); }; // coche le temps du « Copiée »
    const refus = () => { // API presse-papiers refusée : la commande est sélectionnée, la rangée le dit
      const r = document.createRange(); r.selectNodeContents(code);
      const sel = window.getSelection(); sel.removeAllRanges(); sel.addRange(r);
      dire('Copie impossible, commande sélectionnée'); if (annonce) annonce('Copie impossible, commande sélectionnée');
    };
    b.addEventListener('click', () => {
      try { navigator.clipboard.writeText(code.textContent).then(() => { dire('Copiée', true); if (annonce) annonce('Commande copiée'); }, refus); } catch (e) { refus(); }
    });
    return ligne;
  };

  // ---------- graphe : une colonne SVG par rangée, l'état des couloirs est rejoué de haut en bas depuis les rangées servies ----------
  const refsDe = (r) => r.refs || [];
  const x = (k) => k * LARG + LARG / 2;
  const colonne = (r, avant, o) => {
    const H = o.hauteur, c = H / 2, W = o.largeur * LARG, svg = sv('svg', { class: 'vf-git-gcol', width: W, height: H, viewBox: `0 0 ${W} ${H}`, 'aria-hidden': 'true' });
    const trait = (d, t, tirets) => { const p = sv('path', { d, class: 'vf-git-t' + t, fill: 'none', stroke: 'currentColor', 'stroke-width': TRAIT, 'stroke-linecap': 'round' }, svg); if (tirets) p.setAttribute('stroke-dasharray', '3 3'); return p; };
    const dist = refsDe(r).some((e) => e.type === 'distante') && !refsDe(r).some((e) => e.type === 'locale' || e.type === 'head');
    avant.forEach((l, k) => { if (l && k !== r.col) trait(`M${x(k)} 0V${H}`, l.t); }); // couloirs qui traversent la rangée
    if (r.entrants.length) trait(`M${x(r.col)} 0V${c}`, (avant[r.col] || { t: r.teinte }).t, dist);
    if (o.suite) trait(`M${x(r.col)} ${c}V${H}`, r.teinte, dist);
    for (const s of r.sortants) { // quart de cercle de rayon 16 : horizontale puis arc puis verticale dans le couloir d'arrivée
      const sens = s.vers > s.de ? 1 : -1, t = (o.apres[s.vers] || { t: r.teinte }).t;
      if (s.vers === s.de) trait(`M${x(s.de)} ${c}V${H}`, t); else trait(`M${x(s.de)} ${c}H${x(s.vers) - sens * RAYON}A${RAYON} ${RAYON} 0 0 ${sens > 0 ? 1 : 0} ${x(s.vers)} ${c + RAYON}V${H}`, t);
    }
    const t = 't' + r.teinte, tete = refsDe(r).some((e) => e.type === 'head');
    if (tete) sv('circle', { cx: x(r.col), cy: c, r: NOEUD + 2.5, class: 'vf-git-anneau', fill: 'none', 'stroke-width': 1.5 }, svg);
    sv('circle', { cx: x(r.col), cy: c, r: NOEUD, class: `vf-git-noeud vf-git-${t}${tete ? ' vf-git-tete' : ''}${r.fusion ? ' vf-git-creux' : ''}`, 'stroke-width': TRAIT }, svg);
    return svg;
  };
  const etiquette = (e) => {
    const p = el('span', `vf-git-ref vf-git-ref-${e.type}${e.courante ? ' vf-git-ref-cur' : ''}`, null, { title: e.nom });
    p.appendChild(el('span', 'vf-git-ref-t', e.nom)); // le nom seul porte l'ellipse : HEAD (flex: none) reste entier, l'icône aussi
    if (e.type === 'tag') p.prepend(ico('M4 4h8l8 8-8 8-8-8z'));
    else if (e.worktree) p.prepend(ico('M3 7h7l2 2h9v10H3z'));
    return p;
  };
  const rangee = (r, o) => {
    o = o || {};
    const li = el('li', 'vf-git-rangee', null, { role: 'option', tabindex: '-1', 'aria-selected': 'false', 'data-h': r.h });
    const refs = refsDe(r), vus = refs.slice(0, 2), reste = refs.slice(2), plus = reste.length + (r.refsPlus || 0);
    const txt = el('div', 'vf-git-txt'), l1 = el('div', 'vf-git-l1'), l2 = el('div', 'vf-git-l2');
    for (const e of vus) l1.appendChild(etiquette(e));
    if (plus) l1.appendChild(el('span', 'meta', '+' + plus, { title: reste.map((e) => e.nom).join(', ') + (r.refsPlus ? `, et ${r.refsPlus} autres` : '') }));
    l1.appendChild(el('span', 'vf-git-msg', r.s));
    l2.append(el('span', 'vf-git-sha', r.h7), ` · ${r.an} · ${relatif(r.at)}`);
    txt.append(l1, l2);
    li.title = complet(r.at);
    li.setAttribute('aria-label', `${r.h7}, ${r.s}${refs.length ? ', ' + refs[0].nom : ''}, ${relatif(r.at)}`);
    li.append(o.colonne || colonne(r, [], { hauteur: o.tactile ? 44 : 40, largeur: 1, suite: false, apres: [] }), txt);
    crochet('rangee', li, r);
    return li;
  };
  const graphe = (rangees, o) => {
    o = o || {};
    const M = Math.max(1, o.couloirsMax || 6), H = o.tactile ? 44 : 40, largeur = Math.max(1, Math.min(M, ...[Math.max(...rangees.map((r) => r.largeur), 1)]));
    const tm = new Map(rangees.map((r) => [r.h, r.teinte])), lanes = [], ol = el('ol', 'vf-git-graphe', null, { role: 'listbox', 'aria-label': 'Commits' });
    let i = 0;
    ol.ajouter = (k) => { // 80-06 : rend les k rangées suivantes (l'état des couloirs se poursuit d'une tranche à l'autre) et les rend
      const fruit = [];
      for (const fin = Math.min(rangees.length, i + k); i < fin; i++) {
        const r = rangees[i], avant = lanes.slice(), suite = r.p.length > 0 && !r.sortants.some((s) => s.parent === r.p[0]);
        lanes[r.col] = suite ? { sha: r.p[0], t: r.teinte } : null;
        for (const s of r.sortants) if (!lanes[s.vers] || lanes[s.vers].sha !== s.parent) lanes[s.vers] = { sha: s.parent, t: tm.has(s.parent) ? tm.get(s.parent) : r.teinte };
        const li = rangee(r, { tactile: o.tactile, colonne: colonne(r, avant, { hauteur: H, largeur, suite, apres: lanes }) });
        ol.appendChild(li); fruit.push(li);
      }
      return fruit;
    };
    ol.ajouter(o.n == null ? rangees.length : o.n);
    return ol;
  };
  // P80-D-19 : au plus SEUIL rangées d'un coup, sinon PAGE ; « Afficher 100 de plus » rend la tranche suivante et met le focus sur la première rangée ajoutée.
  // o.etat = { n } (rangées montrées, gardé par le tiroir d'une relecture à l'autre) ; o.annoncer(texte) : région polie. Rend { bloc, pied }.
  const PAGE = 100, SEUIL = 110;
  const pages = (rangees, o) => {
    const total = rangees.length, et = o.etat || { n: 0 }, bloc = el('div', 'vf-git-pages'), pied = el('p', 'vf-git-note vf-git-pied');
    et.n = Math.min(total, Math.max(et.n || 0, total <= SEUIL ? total : PAGE));
    const ol = graphe(rangees, Object.assign({}, o, { n: et.n })), lb = el('span', 'vf-git-plus-l'), nb = el('span', 'vf-git-plus-n');
    const b = el('button', 'vf-git-plus-b', null, { type: 'button' });
    b.append(lb, nb); bloc.append(ol);
    const maj = () => {
      const reste = total - et.n;
      if (reste <= 0) b.remove(); else { lb.textContent = reste < PAGE ? (reste > 1 ? `Afficher les ${reste} derniers` : 'Afficher le dernier') : 'Afficher 100 de plus'; nb.textContent = pl(reste, 'restant'); }
      pied.textContent = reste > 0 ? `${et.n} commits affichés sur ${total}` : `Tous les ${total} commits sont affichés`;
      return reste;
    };
    if (maj() > 0) bloc.append(b);
    b.addEventListener('click', () => {
      const fruit = ol.ajouter(PAGE); et.n += fruit.length;
      for (const li of ol.children) li.setAttribute('tabindex', li === fruit[0] ? '0' : '-1');
      const reste = maj();
      if (fruit[0]) fruit[0].focus({ preventScroll: false });
      if (o.annoncer) o.annoncer(`${pl(fruit.length, 'commit')} de plus ${fruit.length > 1 ? 'affichés' : 'affiché'}, ${pl(reste, 'restant')}`);
    });
    return { bloc, pied };
  };

  // ---------- sections repliables et listes ----------
  const section = (titre, n, corps, ouvert, id, aide) => { // aide : définition en texte constant (title au survol, aria-description au focus), jamais une donnée lue de git
    const s = el('section', 'vf-git-sec'), b = el('button', 'vf-git-sec-t', null, { type: 'button', 'aria-expanded': String(!!ouvert), 'aria-controls': id });
    if (aide) { b.setAttribute('title', aide); b.setAttribute('aria-description', aide); aideFocus(b, aide); }
    b.append(el('span', 'vf-git-sec-n', titre));
    if (n != null) b.appendChild(el('span', 'meta', n));
    b.appendChild(ico('M9 6l6 6-6 6'));
    const c = el('div', 'vf-git-sec-c', null, { id, role: 'region', 'aria-label': titre });
    c.hidden = !ouvert; c.appendChild(corps);
    b.addEventListener('click', () => { const o = b.getAttribute('aria-expanded') !== 'true'; b.setAttribute('aria-expanded', String(o)); c.hidden = !o; if (o) s.scrollIntoView({ block: 'nearest' }); }); // à l'ouverture, la section se rend visible (197) : rien ne bouge si elle l'est déjà
    s.append(b, c);
    return s;
  };
  // Tags, Stash, Auteurs : même règle que le Graphe au-delà de SEUIL lignes (PAGE d'abord, « Afficher 100 de plus », focus sur la première ligne ajoutée).
  const paginer = (items, fabrique, annoncer) => {
    const d = el('div', 'vf-git-liste'), lb = el('span', 'vf-git-plus-l'), nb = el('span', 'vf-git-plus-n');
    const b = el('button', 'vf-git-plus-b', null, { type: 'button' });
    let n = 0;
    b.append(lb, nb);
    const ajouter = (k) => { const fruit = items.slice(n, n + k).map(fabrique); n += fruit.length; if (fruit.length) b.before(...fruit); return fruit; };
    const maj = () => {
      const reste = items.length - n;
      if (reste <= 0) { b.remove(); return 0; }
      lb.textContent = reste < PAGE ? (reste > 1 ? `Afficher les ${reste} derniers` : 'Afficher le dernier') : 'Afficher 100 de plus';
      nb.textContent = pl(reste, 'restant');
      return reste;
    };
    d.append(b); ajouter(items.length <= SEUIL ? items.length : PAGE); maj();
    b.addEventListener('click', () => {
      const fruit = ajouter(PAGE), reste = maj();
      if (fruit[0]) { fruit[0].setAttribute('tabindex', '-1'); fruit[0].focus({ preventScroll: false }); }
      if (annoncer) annoncer(`${pl(fruit.length, 'ligne')} de plus ${fruit.length > 1 ? 'affichées' : 'affichée'}, ${pl(reste, 'restant')}`);
    });
    return d;
  };
  const liste = (lignes) => { const d = el('div', 'vf-git-liste'); d.append(...lignes); return d; };
  const ligne = (...enfants) => { const d = el('div', 'vf-git-ligne-d'); d.append(...enfants); return d; };
  const mono = (t, cls) => el('span', 'vf-git-mono' + (cls ? ' ' + cls : ''), t, { title: t });
  const AIDE_DETACHE = "HEAD détaché : ce dossier n'est sur aucune branche, il est posé sur un commit précis.";
  const sectionWorktrees = (l, annonce) => {
    if (!l || !l.length) return null;
    const s = section('Worktrees', l.length, liste(l.map((w) => {
      const d = el('div', 'vf-git-wt-l'), t = ligne(mono(w.nom, 'vf-git-gras'));
      if (w.ici) t.appendChild(el('span', 'vf-git-ici', 'ici'));
      const br = mono(w.detache ? 'HEAD détaché' : w.branche || '—');
      if (w.detache) { br.setAttribute('title', AIDE_DETACHE); br.setAttribute('aria-description', AIDE_DETACHE); aideFocus(br, AIDE_DETACHE); } // PU-G-193 : le terme reste, sa définition au survol ET au focus
      d.append(t, ligne(br));
      if (!w.ici) d.appendChild(commande(w.commande, annonce, 'cd vers ' + w.nom));
      return d;
    })), false, 'vf-git-s-wt', "Worktrees : copies de travail du dépôt, chacune dans son propre dossier et sur sa propre branche. " + AIDE_DETACHE);
    s.querySelector('.vf-git-sec-t').setAttribute('aria-label', 'Worktrees · ' + l.length); // P80-D-19 : repliée au départ, le compte fait partie du nom
    return s;
  };
  const sectionTags = (l, annoncer) => !l || !l.length ? null : section('Tags', l.length,
    paginer(l, (t) => ligne(mono(t.nom, 'vf-git-gras'), mono(t.h7), el('span', null, relatif(t.at))), annoncer), false, 'vf-git-s-tags');
  const sectionStash = (l, annonce) => {
    if (!l || !l.length) return null;
    const fab = (s) => {
      const d = el('div', 'vf-git-st');
      d.append(ligne(mono(s.ref, 'vf-git-gras vf-git-entier'), el('span', 'vf-git-msg', s.message), mono(s.branche || ''), el('span', null, relatif(s.at))),
        commande(s.commande, annonce, 'pour voir le stash ' + s.ref));
      return d;
    };
    return section('Stash', l.length, paginer(l, fab, annonce), false, 'vf-git-s-stash');
  };
  const sectionAuteurs = (auteurs, parBranche, annoncer) => {
    if (!auteurs || !auteurs.length) return null;
    const max = Math.max(1, ...auteurs.map((a) => a.commits)), d = el('div', 'vf-git-liste');
    const fab = (a) => {
      const b = el('div', 'vf-bar'), i = el('i'); i.style.width = Math.round((100 * a.commits) / max) + '%'; b.appendChild(i);
      const x2 = el('div', 'vf-git-aut');
      x2.append(ligne(el('span', 'vf-git-gras', a.nom), el('span', 'meta', pl(a.commits, 'commit')), el('span', null, relatif(a.dernier))), b);
      return x2;
    };
    d.appendChild(paginer(auteurs, fab, annoncer));
    if (parBranche && parBranche.length) {
      d.appendChild(el('div', 'vf-git-sous', 'Par branche — avance sur la base'));
      for (const p of parBranche) d.appendChild(ligne(mono(p.nom), avance(p.avance), el('span', null, p.dernier ? relatif(p.dernier) : '')));
    }
    return section('Auteurs et activité', auteurs.length, d, false, 'vf-git-s-aut');
  };
  const mergees = (l, annonce) => {
    const d = el('div', 'vf-git-merg');
    if (!l || !l.length) return d;
    const b = el('button', 'vf-git-merg-b', pl(l.length, 'branche mergée', 'branches mergées'), { type: 'button', 'aria-expanded': 'false' }), c = el('div', 'vf-git-liste');
    c.hidden = true;
    for (const m of l) { const w = el('div', 'vf-git-wt-l'); w.append(ligne(mono(m.nom)), commande(m.commande, annonce, 'de suppression de la branche ' + m.nom)); c.appendChild(w); }
    b.addEventListener('click', () => { const o = b.getAttribute('aria-expanded') !== 'true'; b.setAttribute('aria-expanded', String(o)); c.hidden = !o; });
    d.append(b, c);
    return d;
  };

  // ---------- états : chargement, vide, indisponible ----------
  const etatChargement = () => { const d = el('div', 'vf-git-etat'); d.append(el('div', 'vf-git-fantome'), el('div', 'vf-git-fantome'), el('div', 'vf-git-fantome'), el('p', 'vf-git-note', 'Lecture du dépôt')); return d; };
  const etatVide = (cmd, annonce) => { const d = el('div', 'vf-git-etat'); d.append(el('h3', 'vf-git-titre', 'Aucun commit pour l\'instant'), el('p', 'vf-git-note', 'Le dépôt existe mais son historique est vide.'), commande(cmd, annonce, 'du premier commit')); return d; };
  const etatIndisponible = (cmd, reessayer, annonce, delai) => { // delai : git a répondu « indisponible » (muet ou trop lent) ; sinon aucune réponse exploitable
    const raison = delai ? 'Git a mis trop de temps à répondre (machine chargée ?). Réessayer.' : "La lecture du dépôt n'a pas abouti. Réessayer.";
    const d = el('div', 'vf-git-etat vf-git-carte'), b = el('button', 'btn soft', 'Réessayer', { type: 'button' });
    b.addEventListener('click', () => { if (reessayer) reessayer(); });
    d.append(el('h3', 'vf-git-titre', 'Git est indisponible'), el('p', 'vf-git-note', raison), b, commande(cmd, annonce, 'de diagnostic'));
    return d;
  };
  window.VFGitRendu = Object.freeze({
    graphe, pages, rangee, sectionWorktrees, sectionTags, sectionStash, sectionAuteurs, mergees, commande,
    etatChargement, etatVide, etatIndisponible, relatif, section, ico, el, aideFocus,
    motifSha: /^[0-9a-f]{40}$/, // définition unique du motif du sha (40 hexadécimaux minuscules), lue par le tiroir et le volet
  });
})();
