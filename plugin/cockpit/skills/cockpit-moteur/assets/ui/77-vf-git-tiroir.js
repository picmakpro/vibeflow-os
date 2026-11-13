// VibeFlow (78-06) : tiroir Git à gauche — ouverture (vf-git:basculer, touche g), lecture de GET /api/vf/git, sections, clavier, focus, coexistence avec le Terminal et le zoom, mobile.
// Rendus : 77-vf-git-rendu.js (window.VFGitRendu). Lecture seule : un GET de même origine, aucune écriture, aucun postMessage ; l'état ouvert n'est pas mémorisé.
// Événements (sur window) : reçoit vf-git:basculer (76) · émet vf-git:etat {ouvert} (aria-expanded des ouvreurs) et vf-git:entete (objet d'en-tête lu dans la réponse).
// Point d'extension paresseux (78-10) : si window.VFGitExt existe, ses crochets `rendu(corps, donnees)` et `etat(ouvert)` sont appelés ; jamais requis.
(() => {
  const SC = window.Floorplan, R = window.VFGitRendu;
  if (!SC || !R) return;
  const t = window.__vfFrT;
  const V = SC.graph.meta && SC.graph.meta.vfGit;
  if (!V || V.etat === 'absent' || !V.depot) return; // sans dépôt : aucun tiroir, aucune touche g
  const MOBILE = window.matchMedia('(max-width: 999px), (pointer: coarse)');
  const CHAMPS = { base: 'object', worktrees: 'array', rangees: 'array', couloirsMax: 'number', replies: 'number', mergees: 'array', tags: 'array', stash: 'array', auteurs: 'array', parBranche: 'array', commandes: 'object' };
  const CHAMPS_RANGEE = { h: 'string', h7: 'string', p: 'array', at: 'number', an: 'string', s: 'string', col: 'number', largeur: 'number', entrants: 'array', sortants: 'array', teinte: 'number', refs: 'array' };
  const type = (v) => (Array.isArray(v) ? 'array' : v === null ? 'null' : typeof v);
  const conforme = (o, champs) => !!o && Object.keys(champs).every((k) => type(o[k]) === champs[k]);
  const valide = (j) => { // schéma vérifié avant tout rendu : jamais un rendu partiel
    if (!j || j.schema !== 'vibeflow/cockpit-git@1' || ['ok', 'vide', 'indisponible', 'absent'].indexOf(j.etat) < 0) return false;
    return j.etat !== 'ok' || (conforme(j, CHAMPS) && j.rangees.every((r) => conforme(r, CHAMPS_RANGEE) && r.sortants.every((s) => typeof s.de === 'number' && typeof s.vers === 'number')));
  };
  const crochet = (nom, ...a) => { const E = window.VFGitExt; if (E && typeof E[nom] === 'function') { try { E[nom](...a); } catch (e) { void e; } } };

  const style = document.createElement('style');
  style.textContent = `
    .vf-git-tiroir { position: fixed; left: 16px; top: calc(var(--hh, 64px) + 4px); bottom: 16px; width: var(--vf-git-l, 360px); z-index: 7;
      display: flex; flex-direction: column; border-radius: var(--r-panel); overflow: hidden; }
    body:not(.no-panel) .vf-git-tiroir { /* 80-06 : largeur réglable par la poignée, bornée par le panneau ouvert */
      width: min(var(--vf-git-l, 360px), max(280px, calc(100vw - var(--panel-w, 360px) - 312px))); }
    .vf-git-tiroir[hidden] { display: none; }
    .vf-git-tiroir.vf-git-entree { animation: vf-git-entree 250ms var(--ease) both; }
    @keyframes vf-git-entree { from { opacity: 0; transform: translateX(-16px); } to { opacity: 1; transform: none; } }
    .vf-git-barre { flex: none; display: flex; align-items: center; gap: 8px; height: 36px; padding: 0 8px 0 16px; background: var(--raise); border-bottom: 1px solid var(--hair); }
    .vf-git-titre-t { margin: 0; font: 600 13px var(--sans); color: var(--text); }
    .vf-git-titre-t:focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; border-radius: 4px; } /* 198 : le titre reçoit le focus à l'ouverture ; l'anneau se voit au clavier (DESIGN.md §9), jamais à la souris */
    .vf-git-titre-t:focus:not(:focus-visible) { outline: none; }
    .vf-git-fermer { margin-left: auto; }
    .vf-git-fermer, .vf-git-btn { flex: none; width: 28px; height: 28px; display: grid; place-items: center; border: 0; border-radius: 8px; background: none; color: var(--text-2); cursor: pointer; }
    .vf-git-fermer:hover, .vf-git-btn:hover { background: var(--raise-2); color: var(--text); }
    .vf-git-tiroir button:focus-visible, .vf-git-rangee:focus-visible { outline: 2px solid var(--ring); outline-offset: -2px; }
    .vf-git-bulle { position: fixed; z-index: 45; max-width: 280px; padding: 8px 12px; border-radius: 12px; font: 400 12.5px/1.5 var(--sans); color: var(--text-2); pointer-events: none; } /* PU-G-193, 196 : définition d'un terme Git au focus */
    .vf-git-bulle[hidden] { display: none; }
    .vf-git-mono[tabindex]:focus-visible, .vf-git-pastille[tabindex]:focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; border-radius: 4px; }
    .vf-git-aide { margin: 0; padding: 8px 16px; font-size: 12.5px; color: var(--text-3); }
    .vf-git-corps { flex: 1; min-height: 0; overflow-y: auto; padding: 0 16px 16px; font-family: var(--sans); overflow-x: hidden;
      margin-right: 14px; /* la poignée de largeur occupe cette bande : la barre de défilement reste saisissable */ }
    .vf-git-live { position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%); white-space: nowrap; }
    body.vf-git-ouvert #context { opacity: 0; }
    .vf-git-sec { margin-top: 12px; }
    .vf-git-sec-t, .vf-git-merg-b { display: flex; align-items: center; gap: 8px; width: 100%; padding: 4px 0; border: 0; background: none; color: var(--text-3); font: 600 11.5px var(--sans); letter-spacing: .02em; cursor: pointer; text-align: left; }
    .vf-git-merg-b { font-weight: 400; letter-spacing: 0; margin-top: 8px; }
    .vf-git-sec-t .meta { margin-left: auto; }
    .vf-git-sec-t svg { transition: transform 200ms var(--ease); }
    .vf-git-sec-t[aria-expanded="true"] svg { transform: rotate(90deg); }
    .vf-git-sec-c[hidden], .vf-git-liste[hidden] { display: none; }
    .vf-git-graphe { list-style: none; margin: 0; padding: 0; }
    .vf-git-rangee { display: flex; align-items: stretch; gap: 8px; height: 40px; border-radius: var(--r-ctl); }
    .vf-git-rangee:hover { background: rgba(var(--ink), .06); }
    .vf-git-rangee[aria-selected="true"] { background: var(--surface-hover); box-shadow: inset 0 0 0 1.5px rgba(var(--ink), .5); }
    .vf-git-gcol { flex: none; display: block; overflow: visible; }
    .vf-git-t0 { color: var(--text-3); } .vf-git-t1 { color: var(--k-http); } .vf-git-t2 { color: var(--k-call); } .vf-git-t3 { color: var(--k-data); } .vf-git-t4 { color: var(--k-event); } .vf-git-t5 { color: var(--k-queue); }
    .vf-git-noeud { fill: currentColor; stroke: currentColor; } .vf-git-creux { fill: var(--surface); } .vf-git-tete { fill: var(--text); } .vf-git-anneau { stroke: var(--ring); }
    .vf-git-txt { flex: 1; min-width: 0; display: flex; flex-direction: column; justify-content: center; }
    .vf-git-l1 { display: flex; align-items: center; gap: 4px; min-width: 0; overflow: hidden; font-size: 12.5px; color: var(--text); }
    .vf-git-l2 { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 11.5px; color: var(--text-3); }
    .vf-git-msg { flex: 1 1 auto; }
    .vf-git-msg, .vf-git-mono { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; min-width: 0; }
    .vf-git-sha, .vf-git-mono, .vf-git-ref, .vf-git-cmd code { font-family: var(--mono); }
    .vf-git-mono { font-size: 11.5px; }
    .vf-git-ref { flex: 0 1 auto; min-width: 0; max-width: 140px; display: inline-flex; align-items: center; gap: 4px; overflow: hidden; white-space: nowrap; padding: 2px 8px; border-radius: 999px; font-size: 11.5px; font-weight: 400; background: rgba(var(--ink), .06); color: var(--text-2); }
    .vf-git-ref-t { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; } /* seul le nom de la ref cède (ellipse) ; HEAD, l'icône et le message restent entiers */
    .vf-git-ref-head { flex: none; max-width: none; }
    .vf-git-ref:hover, .vf-git-rangee:focus-visible .vf-git-ref { flex: none; max-width: 100%; } /* 195 : l'étiquette tronquée se montre entière au survol de la pastille ou au focus de la rangée (le title porte déjà le nom) ; le message cède */
    .vf-git-ref svg { flex: none; width: 12px; height: 12px; }
    .vf-git-ref-cur { background: var(--on); color: var(--on-text); } .vf-git-ref-tag { background: var(--raise); }
    .vf-git-ref-distante { background: none; border: 1px solid var(--hair-2); color: var(--text-3); }
    .vf-git-plus { margin: 2px 0 0; font: 11.5px var(--mono); color: var(--text-4); }
    .vf-git-plus-b { display: flex; align-items: center; justify-content: space-between; gap: 8px; width: 100%; height: 36px; margin: 4px 0 12px;
      padding: 0 12px; border: 0; border-radius: var(--r-ctl); background: var(--raise); color: var(--text-2); font: 400 12.5px var(--sans); cursor: pointer; }
    .vf-git-plus-b:hover { background: var(--raise-2); color: var(--text); }
    .vf-git-plus-n { font: 11.5px var(--mono); font-variant-numeric: tabular-nums; color: var(--text-3); }
    .vf-git-pied { margin-top: 8px; font-variant-numeric: tabular-nums; }
    .vf-git-liste { display: flex; flex-direction: column; gap: 4px; }
    .vf-git-wt-l, .vf-git-st, .vf-git-aut { display: flex; flex-direction: column; gap: 4px; padding: 8px 12px; border-radius: var(--r-ctl); background: var(--raise); }
    .vf-git-ligne-d { white-space: nowrap; display: flex; align-items: center; gap: 8px; min-width: 0; padding: 6px 12px; border-radius: var(--r-ctl); font-size: 12.5px; color: var(--text-3); }
    .vf-git-liste > .vf-git-ligne-d:hover { background: rgba(var(--ink), .06); }
    .vf-git-wt-l .vf-git-ligne-d, .vf-git-st .vf-git-ligne-d, .vf-git-aut .vf-git-ligne-d { padding: 0; }
    .vf-git-gras { font-size: 12.5px; font-weight: 600; color: var(--text); }
    .vf-git-mono.vf-git-entier { flex: none; overflow: visible; } /* identifiant de stash : toujours entier, le message cède */
    .vf-git-ici { margin-left: auto; padding: 2px 8px; border-radius: 999px; background: var(--on); color: var(--on-text); font-size: 11.5px; font-weight: 600; }
    .vf-git-ligne-d .meta { margin-left: auto; } .vf-git-sous { margin-top: 8px; font-size: 11.5px; color: var(--text-3); }
    .vf-git-cmd { display: flex; flex-wrap: wrap; align-items: center; gap: 6px; min-height: 28px; padding: 4px 4px 4px 12px; border-radius: var(--r-ctl); background: var(--well); }
    .vf-git-cmd code { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 11.5px; color: var(--text-2); user-select: text; }
    .vf-git-retour { flex: none; font-size: 11.5px; color: var(--text-2); } .vf-git-retour:not(:empty) { order: 3; flex: 1 0 100%; }
    .vf-git-sans { font-size: 11.5px; color: var(--text-2); }
    #vf-git-tiroir .meta { color: var(--text-2); }
    #vf-git-tiroir .vf-bar i { background: var(--text-3); } /* activité des auteurs : remplissage neutre, jamais le vert d'état de .vf-bar (jetons figés de la 71.5) */
    .vf-git-etat { display: flex; flex-direction: column; gap: 8px; padding: 12px 0; }
    .vf-git-fantome { height: 40px; border-radius: var(--r-ctl); background: var(--raise); }
    .vf-git-titre { margin: 0; font-size: 15px; font-weight: 600; color: var(--text); }
    .vf-git-note { margin: 0; font-size: 12.5px; color: var(--text-3); }
    .vf-git-carte { align-items: flex-start; padding: 12px; border-radius: var(--r-ctl); background: var(--raise); } .vf-git-carte .vf-git-titre { font-size: 13px; }
    @media (max-width: 999px), (pointer: coarse) {
      .vf-git-tiroir, body:not(.no-panel) .vf-git-tiroir { left: 8px; right: 8px; width: auto; bottom: 8px; }
      body.vf-git-ouvert #ask { display: none; }
      .vf-git-corps { margin-right: 0; }
      .vf-git-rangee { height: 44px; } .vf-git-fermer, .vf-git-btn { width: 44px; height: 44px; } .vf-git-barre { height: 52px; }
      .vf-git-sec-t, .vf-git-merg-b, .vf-git-tiroir .btn, .vf-git-plus-b { min-height: 44px; } .vf-git-cmd { min-height: 44px; }
    }
    @media (max-width: 700px) { .vf-git-tiroir { top: calc(var(--hh, 56px) + 4px); } }
    @media (prefers-reduced-motion: reduce) { .vf-git-tiroir.vf-git-entree { animation: none; } .vf-git-sec-t svg { transition: none; } }
  `;

  const tiroir = R.el('aside', 'vf-git-tiroir glass', null, { id: 'vf-git-tiroir', role: 'complementary', 'aria-label': t('Git history') }), barre = R.el('div', 'vf-git-barre');
  const titre = R.el('h2', 'vf-git-titre-t', t('Git history'), { tabindex: '-1' }), fermerB = R.el('button', 'vf-git-fermer', null, { type: 'button', 'aria-label': t('Close the Git history') });
  const corps = R.el('div', 'vf-git-corps'), live = R.el('div', 'vf-git-live', null, { 'aria-live': 'polite' });
  fermerB.appendChild(R.ico('M6 6l12 12M18 6L6 18'));
  barre.append(titre, fermerB);
  tiroir.append(barre, R.el('p', 'vf-git-aide', 'Lecture seule. Chaque action est une commande à copier.'), corps, live);
  tiroir.hidden = true;

  let ouvert = false, donnees = null, seq = 0, avant = null;
  const etatPages = { n: 0 }; // rangées montrées (80-06) : gardé d'une relecture à l'autre
  const annoncer = (txt) => { live.textContent = txt; };
  const visible = (e) => !!e && !e.hidden && e.getClientRects().length > 0;
  const ligne = () => document.querySelector('#vf-git-ligne'), ouvreur = () => document.querySelector('#vf-git-ouvreur'), plus = () => document.querySelector('#vf-plus'); // plus : « Plus d'actions » du téléphone, qui porte l'ouvreur sous 700 px
  const emettre = (nom, detail) => window.dispatchEvent(new CustomEvent(nom, { detail }));

  const eviter = () => { // sans nommer personne : le tiroir se cale sur le bas de la scène (qui rétrécit quand un panneau bas s'ouvre) puis monte au-dessus de tout petit élément posé dans le coin bas-gauche (zoom, pastilles, puces) ; en mobile, aucun évitement
    tiroir.style.bottom = '';
    if (tiroir.hidden || MOBILE.matches) return;
    const a = tiroir.getBoundingClientRect(), sc = document.querySelector('#stage'), H = window.innerHeight;
    let haut = Infinity;
    if (sc && sc.getBoundingClientRect().bottom < H) haut = sc.getBoundingClientRect().bottom;
    for (const n of document.querySelectorAll('#stage > *, body > *')) {
      if (n === tiroir || !visible(n)) continue;
      const p = getComputedStyle(n).position, b = n.getBoundingClientRect();
      if ((p !== 'fixed' && p !== 'absolute') || b.height > 64 || b.top < H / 2) continue; // petit et bas : ni bandeau, ni panneau large
      if (a.left < b.right && a.right > b.left && a.top < b.bottom && a.bottom > b.top) haut = Math.min(haut, b.top);
    }
    if (haut < Infinity) tiroir.style.bottom = Math.max(16, Math.round(H - haut + 8)) + 'px';
  };

  const montrer = (j) => {
    donnees = j;
    corps.replaceChildren();
    if (j && j.entete && typeof j.entete === 'object') emettre('vf-git:entete', j.entete); // l'en-tête suit la lecture, même indisponible
    if (!j || (j.etat !== 'ok' && j.etat !== 'vide')) { corps.append(R.etatIndisponible(j && j.commandes ? j.commandes.diagnostic : 'git status', recharger, annoncer, !!j && j.etat === 'indisponible')); return; }
    if (j.etat === 'vide') { corps.append(R.etatVide(j.commandes.vide, annoncer)); return; }
    const g = R.el('div'), tronque = j.bornes && j.bornes.tronque;
    const pg = j.rangees.length ? R.pages(j.rangees, { couloirsMax: j.couloirsMax, replies: j.replies, tactile: MOBILE.matches, etat: etatPages, annoncer }) : null;
    g.append(pg ? pg.bloc : R.el('p', 'vf-git-note', 'Aucun commit à afficher.'));
    if (j.replies > 0) g.append(R.el('p', 'vf-git-plus', '+' + j.replies, { title: `${j.replies} rangées au-delà de ${j.couloirsMax} couloirs, repliées sur le dernier` }));
    g.append(R.mergees(j.mergees, annoncer));
    if (pg) g.append(pg.pied);
    if (tronque) g.append(R.el('p', 'vf-git-note', 'Historique tronqué : seuls les commits les plus récents sont lus.'));
    corps.append(...[R.sectionWorktrees(j.worktrees, annoncer), R.section(t('Graph'), null, g, true, 'vf-git-s-graphe'), R.sectionTags(j.tags, annoncer),
      R.sectionStash(j.stash, annoncer), R.sectionAuteurs(j.auteurs, j.parBranche, annoncer)].filter(Boolean));
    crochet('rendu', corps, j);
  };
  const focusOrphelin = () => { // ordre de la famille : l'équivalent (le bouton), le voisin précédent (la dernière rangée, arrêt itinérant), le titre ; jamais body
    const L = [...corps.querySelectorAll('li[role=option]')], b = corps.querySelector('.vf-git-plus-b'), cible = b || L[L.length - 1] || titre;
    if (!b && L.length) for (const l of L) l.setAttribute('tabindex', l === cible ? '0' : '-1');
    cible.focus({ preventScroll: true });
  };
  function recharger(relance) { // GET de même origine ; au-delà de 150 ms, rangées fantômes ; une réponse périmée est ignorée ; une réponse « indisponible » ou nulle est relancée UNE fois (191), jamais en boucle
    const moi = ++seq, SRV = window.FLOORPLAN_SERVER || {};
    const attente = setTimeout(() => { if (moi === seq) { corps.setAttribute('aria-busy', 'true'); corps.replaceChildren(R.etatChargement()); } }, 150);
    return fetch('/api/vf/git', { method: 'GET', headers: { 'x-floorplan-token': SRV.token || '' }, cache: 'no-store' })
      .then((r) => (r.ok ? r.json() : null)).catch(() => null)
      .then((j) => { // rend { ok, change } (null si périmée) : 77-vf-git-vue-detail n'annonce qu'une relecture réussie qui a changé quelque chose
        clearTimeout(attente); if (moi !== seq) return null;
        if (relance !== true && (!j || j.etat === 'indisponible' || !valide(j))) return recharger(true); // la relance prend la main : son propre ++seq périme celle-ci
        corps.removeAttribute('aria-busy');
        const bon = valide(j) && (j.etat === 'ok' || j.etat === 'vide'), change = !(bon && donnees && JSON.stringify(j) === JSON.stringify(donnees));
        const surBouton = !!document.activeElement && document.activeElement.classList.contains('vf-git-plus-b'); // P80-D-50 d : le bouton va disparaître sans clic
        montrer(valide(j) ? j : null); eviter(); if (surBouton) focusOrphelin();
        return { ok: bon, change };
      });
  }

  const ouvrir = () => {
    if (ouvert) return;
    ouvert = true; avant = document.activeElement;
    tiroir.hidden = false; tiroir.classList.add('vf-git-entree'); document.body.classList.add('vf-git-ouvert');
    if (!donnees) recharger();
    eviter(); titre.focus({ preventScroll: true });
    // 80-02 : le tiroir s'inscrit dans la pile (ordre d'Échap), sans piège ni prise de focus
    window.VF_SURCOUCHES.ouvrir(tiroir, { modale: false, ouvreur: avant, fermer: () => fermer() });
    emettre('vf-git:etat', { ouvert: true }); crochet('etat', true);
  };
  const fermer = (sansFocus) => { // sansFocus === true : un autre tiroir latéral s'ouvre (73-vf-tiroir-travail.js) et prend le focus
    if (!ouvert) return;
    ouvert = false; seq++; corps.removeAttribute('aria-busy');
    tiroir.hidden = true; tiroir.classList.remove('vf-git-entree'); document.body.classList.remove('vf-git-ouvert'); window.VF_SURCOUCHES.fermer(tiroir);
    const cible = [ligne(), ouvreur(), plus()].find(visible) || (avant && document.contains(avant) && visible(avant) ? avant : null);
    if (cible && sansFocus !== true) cible.focus({ preventScroll: true });
    emettre('vf-git:etat', { ouvert: false }); crochet('etat', false);
  };
  // Entrée publique pour les autres phases (74) : ouvre le tiroir et son volet sur un commit. Valide le sha avant tout effet ; ne pagine ni ne relit la liste ;
  // ne déplace pas le focus au-delà de ce que fait ouvrir() ; rend true quand le détail est affiché, false sinon ; jamais d'exception ni de rejet.
  // comparaison de dataset.h, jamais un sélecteur construit avec le sha
  const rangeDe = (sha) => [...tiroir.querySelectorAll('li[role=option]')].find((l) => l.dataset.h === sha) || null;
  const ouvrirSur = (sha) => {
    try {
      const V = window.VFGitVolet, D = window.VFGitDetail;
      if (typeof sha !== 'string' || !R.motifSha.test(sha) || !V) return Promise.resolve(false);
      ouvrir(); V.fermer();
      const li = rangeDe(sha);
      const p = V.ouvrir(sha, li);
      if (li && D) { D.selectionner(sha); li.scrollIntoView({ block: 'nearest' }); }
      return Promise.resolve(p).then((ok) => ok === true, () => false);
    } catch (e) { return Promise.resolve(false); }
  };
  const basculer = () => (ouvert ? fermer() : ouvrir());
  tiroir.addEventListener('animationend', () => tiroir.classList.remove('vf-git-entree'));
  fermerB.addEventListener('click', fermer);

  const echap = (e) => { if (ouvert && e.key === 'Escape' && !e.defaultPrevented && !window.VF_SURCOUCHES.couverte(tiroir)) { e.stopPropagation(); e.preventDefault(); fermer(); } };
  tiroir.addEventListener('keydown', echap);
  const surOuvreur = (e) => { const l = ligne(), o = ouvreur(), p = plus(); if ((l && l === e.target) || (o && o === e.target) || (p && p === e.target)) echap(e); };
  const surTouche = (e) => { // touche g : ni dans un champ, ni palette ouverte, ni avec Ctrl, Alt ou Meta, ni sans ouvreur
    if ((e.key !== 'g' && e.key !== 'G') || e.ctrlKey || e.altKey || e.metaKey || e.shiftKey || e.isComposing) return;
    const tg = e.target;
    if (tg && (tg.isContentEditable || ['INPUT', 'TEXTAREA', 'SELECT'].indexOf(tg.tagName) >= 0)) return;
    if (document.querySelector('#palette.open')) return;
    const l = ligne(), o = ouvreur();
    if (!(l && !l.hidden) && !(o && !o.hidden)) return;
    e.preventDefault(); basculer();
  };
  const reevaluer = () => { eviter(); if (donnees && donnees.etat === 'ok') montrer(donnees); };
  const brancher = () => { // A51 : tout ce qui se branche sur le global (feuille, nœud du corps, écouteurs, observateurs) est posé ici et retiré avec l'onglet
    const pose = [], sur = (c, ty, f, o) => { c.addEventListener(ty, f, o); pose.push(() => c.removeEventListener(ty, f, o)); };
    const obs = (O, cible, opts, fn) => { const o = new O(fn); o.observe(cible, opts); pose.push(() => o.disconnect()); };
    document.head.appendChild(style); document.body.appendChild(tiroir);
    const demonter = window.VFGitPoignee && window.VFGitPoignee.monter(tiroir); // 77-vf-git-poignee.js (chargée avant) : largeur réglable, 80-06
    const scene = document.querySelector('#stage'); // la scène bouge quand un panneau bas s'ouvre, se ferme ou se redimensionne
    if (window.ResizeObserver && scene) obs(ResizeObserver, scene, undefined, () => eviter());
    sur(window, 'vf-git:basculer', basculer); sur(document, 'keydown', surOuvreur, true); sur(window, 'keydown', surTouche);
    sur(window, 'resize', eviter); sur(MOBILE, 'change', reevaluer);
    obs(MutationObserver, document.body, { attributes: true, attributeFilter: ['class', 'style'] }, eviter); // le Terminal s'ouvre ou se ferme : la réserve basse change
    return () => {
      pose.splice(0).forEach((f) => f()); if (ouvert) fermer(true);
      if (demonter) demonter();
      tiroir.remove(); style.remove();
    };
  };
  const C = window.VF_COQUILLE;
  if (C && typeof C.surOnglet === 'function') C.surOnglet(brancher, { cle: '77-vf-git-tiroir.js' }); else brancher();
  window.VFGitTiroir = Object.freeze({ ouvrir, fermer, ouvert: () => ouvert, recharger, donnees: () => donnees, ouvrirSur });
})();
