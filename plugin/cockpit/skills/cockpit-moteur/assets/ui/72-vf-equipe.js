// VibeFlow (69-05) : onglet Équipe, troisième onglet du viewer (P69-D-17). Vue d'ensemble de l'équipe (effectifs, état des sources de la collecte) et
// mise à jour en direct : l'événement de document `vf-who`, émis par 70-vf-live.js à chaque `who` reçu, met l'état des cartes à jour en place ; la page
// ne se recharge que si l'ensemble des sessions et sous-agents change, au plus une fois par 15 s. Ne fait rien hors de l'onglet Équipe.
// 69-08 : pied des cartes (état, durée, dernière action), panneau d'un agent (nœud de mission, dernière commande, transcript lu à la demande, rendu en texte
// par 71-vf-equipe-rendu.js ; la réponse reste dans le conteneur, jamais dans le graphe, le stockage du navigateur ni l'export).
// Aucune couleur ni ombre en dur : les classes et les variables du thème du viewer. Toute valeur interpolée passe par h() (P23).
(() => {
  const SC = window.Floorplan;
  if (!SC || !SC.graph?.meta || SC.graph.meta.vfTab !== 'equipe') return;
  const { h, graph: G } = SC;
  const SRV = window.FLOORPLAN_SERVER;
  const R = () => window.__vfEquipeRendu;
  const ETATS = { lue: 'lue', absente: 'absente', erreur: 'illisible', 'forme-inconnue': 'forme changée' };
  const SOURCES = { sessions: 'Sessions et sous-agents', locks: 'Verrous du dépôt', dags: 'Plans de la mission' };
  const PAUSE_MS = 15000;
  const CLE = 'vf-equipe-rechargement';

  SC.setOverview(() => {
    const c = G.meta.vf?.compte || {};
    const n = (v) => Number(v) || 0;
    const mal = Object.entries(G.meta.vf?.sources || {}).filter(([, s]) => s?.etat === 'erreur' || s?.etat === 'forme-inconnue'); // PU-G-180 : tout est lu, rien à dire ; une source absente n'est pas une panne
    const src = mal.map(([k, s]) => `<div class="vf-link"><span>${h(Object.prototype.hasOwnProperty.call(SOURCES, k) ? SOURCES[k] : k)}</span><span class="vst vst-todo">${h(ETATS[s.etat])}</span></div>`).join('');
    return `<div class="sec"><div class="ph"><span class="kind">Équipe</span></div><h2 class="pt">${h(G.project.name)}</h2>
        <div class="stats vf-stats" style="margin-top:var(--sp-12)"><div><b>${n(c.actif)}</b><span>actifs</span></div><div><b>${n(c.enAttente)}</b><span>en attente</span></div><div><b>${n(c.termine)}</b><span>terminés depuis moins de 24 h</span></div></div>
        <p class="pd" style="margin-top:var(--sp-12)">Actifs et terminés depuis moins de 24 h ; le transcript d'un agent ne se lit qu'à la demande.</p></div>
      ${src ? `<div class="sec"><h3>${mal.length > 1 ? 'Sources illisibles' : 'Source illisible'} <span class="c">${mal.length}</span></h3>${src}</div>` : ''}`;
  });

  // P69-D-33 : la recherche de cet onglet trouve des agents et des sessions (les cartes), pas des fichiers, des routes ni des modules
  const LIB = 'Chercher un agent ou une session';
  const bouton = document.getElementById('search-btn'), champ = document.getElementById('search');
  if (bouton) { bouton.setAttribute('aria-label', LIB); bouton.title = LIB; const st = bouton.querySelector('.st'); if (st) st.textContent = LIB; }
  if (champ) champ.placeholder = 'Chercher par nom, rôle ou description';

  const idCarte = (w) => (w.kind === 'session' ? 'se-' : 'ag-') + w.id;
  const equipe = (who) => (Array.isArray(who?.workers) ? who.workers : []).filter((w) => w && (w.kind === 'session' || w.kind === 'subagent') && typeof w.id === 'string');
  // l'ensemble des agents, avec leur appartenance aux terminés (qui change leur place dans l'arbre des cartes)
  const signature = (liste) => liste.map(([id, fini]) => `${id}${fini ? '~' : ''}`).sort().join('|');
  // les cartes d'agent seulement : le bloc « Terminés » (`<carte>~termines`) n'est pas un agent et ne figure jamais dans la liste reçue
  const dansCarte = () => G.nodes.filter((x) => /^(se|ag)-/.test(x.id) && !x.id.includes('~')).map((x) => [x.id, x.st === 'done']);
  let minuterie = null;

  const recharger = () => {
    let dernier = 0;
    try { dernier = Number(sessionStorage.getItem(CLE)) || 0; } catch {}
    const reste = PAUSE_MS - (Date.now() - dernier);
    if (reste > 0) { // au plus un rechargement par 15 s : on revient vérifier plus tard
      if (!minuterie) minuterie = setTimeout(() => { minuterie = null; suivre(); }, reste + 50);
      return;
    }
    try { sessionStorage.setItem(CLE, String(Date.now())); } catch {}
    location.reload();
  };

  // le conteneur du transcript n'existe qu'une fois le transcript demandé : il suit son bouton
  const zoneDe = (b) => {
    let z = b.nextElementSibling;
    if (z && z.classList.contains('vf-transcript')) return z;
    z = document.createElement('div'); z.className = 'vf-transcript'; z.dataset.vfDe = b.dataset.vfTranscript; z.style.order = '4'; z.style.flex = '0 0 100%';
    b.after(z); return z;
  };
  // arrivée par un lien `equipe.html#r=n:<carte>` : 00-vibeflow.js la traite à `ready` et à chaque changement de fragment, mais un rerender() lancé pendant le premier rendu
  // annule son `after` et `ready` n'est alors jamais émis ; on révèle la carte visée après le premier rendu qui aboutit (une seule fois par page)
  // Q3b (voir ci-dessous) : appelée par arrivee() ET par `ready`, car l'un ou l'autre arrive en premier selon la course entre le flux `who` et le premier rendu
  let plafonne = false;
  const plafond = () => {
    if (plafonne) return;
    plafonne = true;
    // Q3b : sur un écran étroit l'ajustement à toute la scène réduisait les cartes à ~45 % (titres vers 7 px). La réduction ne descend jamais sous 0,75 : si l'ajustement tombe plus bas,
    // la scène est cadrée sur la première carte, sous le bas RÉEL de #context (titre, compteurs, lien « Plus » : freeArea() le sous-estime), carte entièrement visible.
    // Le viewer peut rejouer fit() après l'arrivée (rendu en cours, ouverture du panneau) : la transformation est surveillée jusqu'à la première action de l'utilisateur
    // (ou 5 s), et le cadrage est repris chaque fois qu'elle repasse sous 0,75.
    const st = SC.state, vp = document.getElementById('viewport'), svg = document.getElementById('svg');
    if (st && vp && SC.freeArea) {
      let actif = true;
      const cadrer = () => {
        if (!actif || !st.t || st.t.k > 0.75) return; // au-delà de 0,75 le viewer (ou l'utilisateur) a la main
        const cartes = (st.layout?.children || []).filter((c) => /^(n:)?(se|ag)-/.test(c.id) && !c.id.includes('~')), c = cartes.sort((x, y) => x.y - y.y || x.x - y.x)[0], a = SC.freeArea();
        if (!c || !svg) return;
        const haut = svg.getBoundingClientRect().top; let bas = 0;
        for (const e of [document.getElementById('context'), ...document.querySelectorAll('#context *')]) { const b = e?.getBoundingClientRect(); if (b && b.width && b.height) bas = Math.max(bas, b.bottom); }
        const y = Math.max(a.y, bas - haut + 12), tx = Math.max(a.x, 12) - c.x * 0.75, ty = y - c.y * 0.75;
        window.__vfCadrage = { k: st.t.k, bas: Math.round(bas), t: Math.round(performance.now()), polices: document.fonts?.status || '?' }; // relevé de diagnostic (EK13 en CI)
        if (st.t.k === 0.75 && Math.abs(st.t.x - tx) < 0.5 && Math.abs(st.t.y - ty) < 0.5) return; // déjà cadré : aucune écriture, donc aucune boucle de l'observateur
        st.t = { k: 0.75, x: tx, y: ty };
        vp.style.transform = `translate(${tx}px,${ty}px) scale(0.75)`;
        svg.classList.remove('lod-low', 'lod-mid');
      };
      cadrer();
      // le titre peut grandir après le cadrage (polices web chargées, police de repli plus large, compteurs qui changent) : il est recadré à chaque changement de sa taille et à la fin du chargement des polices
      const ctx = document.getElementById('context'), taille = typeof ResizeObserver === 'function' && ctx ? new ResizeObserver(cadrer) : null;
      const garde = new MutationObserver(cadrer), fin = () => { actif = false; garde.disconnect(); taille?.disconnect(); for (const ev of ['pointerdown', 'wheel', 'keydown', 'touchstart']) window.removeEventListener(ev, fin, true); };
      garde.observe(vp, { attributes: true, attributeFilter: ['style'] });
      taille?.observe(ctx);
      document.fonts?.ready?.then(cadrer);
      for (const ev of ['pointerdown', 'wheel', 'keydown', 'touchstart']) window.addEventListener(ev, fin, { capture: true, passive: true });
      setTimeout(fin, 10000);
    }
  };
  let arrive = false;
  const arrivee = () => {
    if (arrive) return;
    arrive = true;
    // 70-12 (UIFN-14, défaut E) : le rerender() de `suivre` annule le premier rendu du viewer (le jeton de rendu change), celui qui appelait fit(false) ; le rendu qui aboutit garde la
    // transformation d'origine et la première carte reste sous l'en-tête et le titre. On cadre donc la scène ici, une fois par page, avant la révélation éventuelle d'une carte visée.
    SC.fit?.(false); // `?.` : le faux viewer du harnais hors navigateur de test-cockpit-equipe.sh (EUI) ne porte pas fit
    plafond();
    const r = new URLSearchParams(location.hash.slice(1)).get('r');
    if (r && /^n:/.test(r) && SC.exists(r)) SC.reveal(r);
  };
  const parCarte = () => new Map(equipe(window.__vfLive?.who).map((w) => [idCarte(w), w]));

  // transcript lu : gardé en mémoire de la page seulement (jamais dans le graphe, le stockage ni l'export), reposé par un observateur chaque fois que le panneau est redessiné
  // (à chaque `who`, par le viewer, par l'arrivée sur une carte) ; il disparaît quand le panneau montre un autre agent. Seul l'identifiant de l'agent est gardé dans
  // sessionStorage, pour redemander le transcript après un rechargement de la page (structure de l'équipe changée, « Map updated »).
  const CLE_OUVERT = 'vf-equipe-ouvert';
  let lu = null, redemande = false;
  const marque = (id) => { try { if (id) sessionStorage.setItem(CLE_OUVERT, id); else sessionStorage.removeItem(CLE_OUVERT); } catch {} };
  const boutons = () => [...document.querySelectorAll('#panel [data-vf-transcript]')];
  const remettre = () => {
    const bs = boutons(); if (!bs.length) return;
    if (!lu) {
      let id = null; try { id = sessionStorage.getItem(CLE_OUVERT); } catch {}
      const b = id && !redemande ? bs.find((x) => x.dataset.vfTranscript === id) : null;
      if (b) { redemande = true; b.click(); }
      return;
    }
    const b = bs.find((x) => x.dataset.vfTranscript === lu.id);
    if (!b) { lu = null; marque(null); return; } // un autre agent : le transcript lu disparaît
    const z = zoneDe(b); if (!z.firstChild) z.replaceChildren(...lu.noeuds);
  };
  new MutationObserver(remettre).observe(document.getElementById('panel') || document.documentElement, { childList: true, subtree: true }); // le panneau seulement
  // AUDC-D2 : l'état écrit à l'assemblage dans le panneau (« État : actif » des détails, dernier mot du repli de la description) suit chaque poussée : un seul état affiché pour une session, celui de la carte
  const dirEtat = (x, w) => {
    const mot = R().etat(w);
    if (typeof x.details === 'string') x.details = x.details.replace(/^(État : ).*$/m, (_, p) => p + mot);
    if (typeof x.summary === 'string') x.summary = x.summary.replace(/^((?:Agent|Session) sans tâche annoncée · ).*$/, (_, p) => p + mot);
  };
  async function suivre() {
    const liste = equipe(window.__vfLive?.who);
    if (!window.__vfLive?.who) return;
    const direct = liste.map((w) => [idCarte(w), w.etat === 'termine']);
    if (signature(direct) !== signature(dansCarte())) { recharger(); return; }
    const parId = new Map(liste.map((w) => [idCarte(w), w]));
    const compte = { actif: 0, enAttente: 0, auRepos: 0, attend: 0, termine: 0 };
    for (const w of liste) { if (R().actif(w)) compte.actif++; else if (w.etat === 'termine') compte.termine++; else if (w.etat === 'au-repos') compte.auRepos++; else if (w.etat === 'attend') compte.attend++; else compte.enAttente++; } // même prédicat que le badge de l'en-tête (70-vf-live.js)
    for (const x of G.nodes) { const w = parId.get(x.id); if (w) { x.st = R().st(w); x.foot = R().piedCarte(w); dirEtat(x, w); } }
    G.meta.vf = { ...G.meta.vf, compte };
    await SC.rerender();
    arrivee();
  }
  document.addEventListener('vf-who', suivre);
  // AUDC-D3 : entre deux poussées l'âge avance dans les pieds de carte et la ligne « Activité » du panneau (le tiroir a sa propre minuterie, 70-vf-live.js) : toutes les 30 s, pieds recalculés et vue redessinée
  const rafraichirAges = async () => {
    if (document.hidden || !window.__vfLive?.who) return;
    const parId = new Map(equipe(window.__vfLive.who).map((w) => [idCarte(w), w]));
    for (const x of G.nodes) { const w = parId.get(x.id); if (w) x.foot = R().piedCarte(w); }
    await SC.rerender();
  };
  if (typeof setInterval === 'function') setInterval(rafraichirAges, 30000); // `typeof` : le harnais vm de test-cockpit-equipe.sh n'a pas de minuterie
  SC.on('ready', () => { arrive = true; plafond(); for (const [id, w] of parCarte()) { const x = G.nodes.find((n) => n.id === id); if (x) x.foot = R().piedCarte(w); } });

  // panneau d'une carte d'agent ou de session
  SC.addPanelSection('item', (id) => {
    const w = typeof id === 'string' && id.startsWith('n:') ? parCarte().get(id.slice(2)) : null;
    if (!w) return '';
    const vers = R().versNoeud(w, h);
    // PU-G-171 : les deux boutons restent côte à côte, les résultats (commande, transcript) s'affichent dessous (order) : « Lire le transcript » ne saute plus quand la commande arrive
    return `<div class="sec"><h3>Activité</h3><p class="pd">${h(R().pied(w))}</p>${vers}<div style="display:flex;flex-wrap:wrap">
      <button type="button" data-vf-doing="${h(w.id)}" style="order:1">Voir la dernière commande</button><div class="vf-doing" style="order:3;flex:0 0 100%" hidden></div>
      <button type="button" data-vf-transcript="${h(w.id)}" style="order:2">Lire le transcript</button></div></div>`;
  });
  // Entrée sur un de ces boutons : le viewer l'écoute aussi sur `window` (raccourci « ouvrir le nœud sélectionné »), descend dans le nœud et redessine le panneau ;
  // le bouton quitte le document avant que son clic ait lieu et le transcript n'est jamais lu (UIFN-12). L'évènement s'arrête au document, le clic du bouton reste.
  document.addEventListener('keydown', (ev) => {
    if (ev.keyCode === 13 && ev.target.closest?.('#panel [data-vf-transcript], #panel [data-vf-doing]')) ev.stopPropagation();
  });
  // lecture à la demande : requête authentifiée, texte seulement (createElement + textContent dans le rendu)
  document.addEventListener('click', async (ev) => {
    const b = ev.target.closest?.('[data-vf-transcript]');
    if (!b) return;
    const id = b.dataset.vfTranscript;
    if (b.getAttribute('aria-disabled') === 'true') return; // lecture en cours : les clics répétés sont ignorés
    b.setAttribute('aria-disabled', 'true'); // jamais `disabled` : un bouton désactivé perd le focus clavier (UIFN-12)
    b.textContent = 'Lecture du transcript…'; b.setAttribute('aria-busy', 'true'); // PU-G-172 : le serveur peut mettre ~3 s à répondre ; indicateur sur le bouton, jamais dans la zone (elle ne se remplit qu'avec le transcript lu)
    let d = null;
    try { const r = SRV && SRV.token ? await fetch('/api/vf/transcript?id=' + encodeURIComponent(id), { headers: { 'x-floorplan-token': SRV.token }, cache: 'no-store' }) : null; d = r && r.ok ? await r.json() : null; } catch {}
    lu = { id, noeuds: [...R().transcript(d, document).childNodes] }; marque(id);
    for (const x of boutons()) if (x.dataset.vfTranscript === id) { zoneDe(x).replaceChildren(...lu.noeuds); x.removeAttribute('aria-disabled'); }
    for (const x of boutons()) if (x.dataset.vfTranscript === id) { x.textContent = 'Lire le transcript'; x.removeAttribute('aria-busy'); }
    b.textContent = 'Lire le transcript'; b.removeAttribute('aria-busy'); b.removeAttribute('aria-disabled');
  });
})();
