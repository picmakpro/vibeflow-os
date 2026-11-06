// VibeFlow (spike 002) : trois onglets sur le même viewer — Code (la carte floorplan), Projet
// (jalons → phases → plans, exigences, missions, backlog) et Équipe (qui est au travail). Statuts sur les cartes, panneau
// d'ensemble du projet, et pont entre les onglets Code et Projet : un plan ou un nœud de mission renvoie aux
// fichiers qu'il touche, un fichier de code renvoie aux plans qui l'ont touché.
// Ne parle au viewer que par window.Floorplan (+ patchs P1-P4, cf. VENDORED.txt).
(() => {
  const SC = window.Floorplan;
  if (!SC) return;
  const { h, graph: G } = SC;
  const TAB = G.meta.vfTab === 'project' ? 'project' : G.meta.vfTab === 'equipe' ? 'equipe' : 'code';
  document.body.classList.add('vf-tab-' + TAB); // 70-12 (P70-D-20) : marqueur de l'onglet sur le corps de page (`vf-tab-code`, `vf-tab-project`, `vf-tab-equipe`), pour les règles de mise en page propres à un onglet
  // titre de l'onglet du navigateur : « <nom> — Code », « <nom> — Projet » ou « Équipe · <nom> » (le viewer écrit « <nom> map », qui devenait le nom seul)
  { const nom = String(G.project.name || '').replace(/ — (Projet|Équipe)$/, ''); document.title = TAB === 'equipe' ? `Équipe · ${nom}` : `${nom} — ${TAB === 'project' ? 'Projet' : 'Code'}`; }
  const ST = { done: 'Fait', active: 'En cours', recette: 'À recetter', todo: 'À faire', blocked: 'Bloqué' };
  // P67-D-04 : logo VibeFlow clair ou sombre selon le thème du viewer (meta.vfLogos est posé par l'assemblage)
  const LOGOS = G.meta.vfLogos;
  if (LOGOS) {
    const mark = document.querySelector('.brand .mark');
    const sync = () => { if (mark) mark.src = document.documentElement.getAttribute('data-theme') === 'dark' ? LOGOS.sombre : LOGOS.clair; };
    sync(); window.addEventListener('floorplan-theme-change', sync);
  }

  // 71.5 (P71.5-D-18, D-20) : le glyphe d'une pastille est un masque SVG teinté par --c-st (seule couleur de la pastille). encodeURIComponent : jamais de `#` littéral dans la source (M5.3)
  const GLYPHE = (corps) => 'url("data:image/svg+xml,' + encodeURIComponent("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'>" + corps + '</svg>') + '")';
  const ANNEAU = "<circle cx='8' cy='8' r='6' fill='none' stroke='black' stroke-width='1.75'/>";
  const G_ST = {
    done: GLYPHE("<path d='M3.5 8.5l3 3 6-7' fill='none' stroke='black' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'/>"),
    active: GLYPHE(ANNEAU + "<path d='M8 4a4 4 0 0 1 0 8z' fill='black'/>"),
    recette: GLYPHE(ANNEAU + "<circle cx='8' cy='8' r='2.2' fill='black'/>"),
    todo: GLYPHE(ANNEAU),
    blocked: GLYPHE(ANNEAU + "<path d='M4.5 8h7' stroke='black' stroke-width='1.75' stroke-linecap='round'/>"),
    abandonnee: GLYPHE(ANNEAU + "<path d='M4.2 11.8L11.8 4.2' stroke='black' stroke-width='1.75' stroke-linecap='round'/>"),
  };
  const style = document.createElement('style');
  style.textContent = `
    :root { --st-done: var(--recent); --st-active: var(--sev-medium); --st-todo: var(--text-4); --st-blocked: var(--sev-high); --st-recette: var(--st-active); }
    .vf-tabs { display: inline-flex; gap: var(--sp-2); padding: var(--sp-4); margin-left: var(--sp-12); border-radius: 12px; background: var(--raise); flex: none; }
    .vf-tabs a { padding: var(--sp-4) var(--sp-12); border-radius: 9px; font-size: 13px; font-weight: 500; color: var(--text-3); text-decoration: none; line-height: 1.4; }
    .vf-tabs a:hover { color: var(--text); }
    .vf-tabs a.on { background: var(--surface); color: var(--text); box-shadow: var(--shadow-card); }
    /* 71.5 (P71.5-D-18, N1) : pastille sans fond : un glyphe coloré (--c-st) puis le mot en --text-2. Hauteur 20 = 16 + 2 x 2, jamais de height ; padding horizontal nul hors paliers lod, pour que le bord visible s'aligne sur le titre */
    .vst { display: inline-flex; align-items: center; gap: var(--sp-4); font-size: 11px; font-weight: 500; padding: var(--sp-2) 0; line-height: 16px; border-radius: 999px; white-space: nowrap; color: var(--text-2); background: none; }
    .vst::before { content: ""; width: 1.45em; height: 1.45em; flex: none; background: var(--c-st); -webkit-mask: var(--g-st) center / contain no-repeat; mask: var(--g-st) center / contain no-repeat; }
    .vst-done { --c-st: var(--st-done); --g-st: ${G_ST.done}; } .vst-active { --c-st: var(--st-active); --g-st: ${G_ST.active}; } .vst-todo { --c-st: var(--st-todo); --g-st: ${G_ST.todo}; } .vst-blocked { --c-st: var(--st-blocked); --g-st: ${G_ST.blocked}; }
    .vst-recette { --c-st: var(--st-recette); --g-st: ${G_ST.recette}; }
    /* 71.5 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-06 : « Griser les points seuls ») : le point d'une phase dans les listes du panneau (Contenu, Utilisé par, Dépend de) est gris neutre, plus violet ; --n-phase garde sa valeur (cartes, icônes, barre de langage). !important : le point porte sa couleur en style en ligne (viewer.html rowFor). */
    #panel .row[data-go^="n:ph-"] > .dot { background: var(--text-4) !important; }
    /* recette 68 R5 (P68-D-35, arbitrage Samuel, AskUserQuestion session principale Claude Code, 2026-11-04 : « Tout selon les recos ») : une mission abandonnée dit « Abandonnée » ; 71.5 : gris neutre (--text-3), anneau barré d'une diagonale (distinct de « bloqué » et de « à faire ») */
    .vst-abandonnee { --c-st: var(--text-3); --g-st: ${G_ST.abandonnee}; }
    /* recette 68 R7 (même arbitrage) : le pied d'une carte (« 0/2 nœuds · abandonnée, nœuds non refermés ») passe à la ligne au lieu de pousser la pastille hors de la carte ; la pastille garde sa taille */
    .foot .meta { white-space: normal; min-width: 0; border-radius: 12px; }
    .foot .vst { flex: none; }
    /* 71.5 (P71.5-D-18, D-28, N2) : ni anneau ni halo, une seule élévation ; l'état se lit dans le pied (glyphe + mot) et la graisse du titre. « En cours » : palier neutre plus marqué (--raise allégé), car --surface-hover ne se voit pas en clair */
    .card.st-active, .card.st-recette, .node:hover .card.st-active, .node:hover .card.st-recette { background: color-mix(in srgb, var(--raise) 70%, var(--surface)); }
    .card.st-active, .card.st-recette, .card.st-blocked { box-shadow: var(--shadow-card); }
    .card.st-active .title, .card.st-recette .title, .card.st-blocked .title { font-weight: 600; color: var(--text); }
    .card.st-done .title, .card.st-todo .title { font-weight: 500; color: var(--text-2); }
    .card.st-done .desc { color: var(--text-3); }
    /* piste --raise-2, remplissage neutre ; seule la barre « en cours » prend --warn-text (une teinte d'état ne se pose pas sur --raise-2 en clair, 71.5 §1.2) */
    .vf-bar { height: 6px; border-radius: 99px; background: var(--raise-2); overflow: hidden; margin-top: var(--sp-6); }
    .vf-bar i { display: block; height: 100%; border-radius: 99px; background: var(--text-3); }
    .vf-bar.st-active i { background: var(--warn-text); }
    .vf-ms { padding: var(--inset-row); border-radius: 14px; cursor: pointer; margin-bottom: var(--sp-2); margin-inline: calc(-1 * var(--sp-12)); }
    .vf-ms:hover { background: var(--surface-hover); }
    .vf-ms .t { display: flex; justify-content: space-between; gap: var(--sp-8); font-size: 13px; font-weight: 500; }
    .vf-ms .t span:last-child { color: var(--text-3); font-weight: 400; font-variant-numeric: tabular-nums; }
    .vf-now { padding: var(--sp-12) 0 0; border-top: 1px solid var(--hair); background: none; font-size: 13px; line-height: 1.55; }
    .vf-now b { display: block; font-size: 12px; color: var(--text-3); margin-bottom: var(--sp-4); font-weight: 500; }
    .vf-link { display: flex; gap: var(--sp-8); align-items: baseline; padding: var(--inset-row); margin-inline: calc(-1 * var(--sp-12)); border-radius: 10px; font-size: 12.5px; color: inherit; text-decoration: none; }
    .vf-link:hover { background: var(--surface-hover); }
    .sec > .vf-link + .vf-link { margin-top: var(--sp-2); } /* lignes de liste : 2 */
    .vf-link code { font-family: 'JetBrains Mono', monospace; font-size: 11.5px; color: var(--text-2); word-break: break-all; }
    /* I2 (recette 2026-11-02, reprise 2026-11-03, avis de Samuel, Wispr Flow, session principale, 2026-11-03 : « pas de bordure, un flou dégradé qui part du haut gauche et descend, comme le header, en mode iOS 26 ») :
       le titre et le sous-titre de la vue d'ensemble se mélangeaient aux graphes que l'on fait glisser dessous. Plus de carte : #context n'a ni fond, ni bordure, ni rayon, ni ombre.
       Le flou vit sur #context::before (qui déborde du texte pour un fondu doux) : backdrop-filter blur + saturate (la recette de .glass) et un fond --bg-rgb léger (le matériau du header),
       le tout masqué par un dégradé radial ancré en haut à gauche : plein derrière le début du titre, il s'estompe vers le bas et vers la droite. Les deux thèmes suivent --bg-rgb.
       Reprise (avis de Samuel, Wispr Flow, session principale, 2026-11-03 : « un gap sans flou entre le texte et le header, allonger le flou jusqu'au header ») : le dégradé de l'en-tête s'estompe sur sa hauteur et laissait voir la carte nette
       entre le bas de la couche et ce fondu ; la couche monte donc jusqu'au haut de l'en-tête (inset relatif à --hh, jamais une valeur calée sur une largeur), DERRIÈRE lui (z-index 10), et le dégradé garde sa taille d'avant (masque en deux couches : le radial sur la hauteur d'avant, calé en bas ; au-dessus, la bande reprend son profil de bord haut, plein puis estompé vers la droite) : l'aspect autour du titre ne change pas.
       isolation: isolate garde la couche derrière le texte. #context ne capte aucun événement (pointer-events: none, hérité du viewer) : la carte reste glissable sous la zone. */
    #context { isolation: isolate; background: none; border: 0; border-radius: 0; box-shadow: none; }
    #context::before { inset: calc(-1 * (var(--hh, 64px) + 8px)) -80px -64px -36px; /* dérivé : halo, déborde du bloc */ background: rgba(var(--bg-rgb), .28); -webkit-backdrop-filter: blur(22px) saturate(1.6); backdrop-filter: blur(22px) saturate(1.6); -webkit-mask-image: radial-gradient(ellipse 100% 100% at 0% 0%, #000 40%, transparent 100%), linear-gradient(to right, #000 40%, transparent 100%); mask-image: radial-gradient(ellipse 100% 100% at 0% 0%, #000 40%, transparent 100%), linear-gradient(to right, #000 40%, transparent 100%); -webkit-mask-size: 100% calc(100% - var(--hh, 64px) + 14px), 100% calc(var(--hh, 64px) - 14px); mask-size: 100% calc(100% - var(--hh, 64px) + 14px), 100% calc(var(--hh, 64px) - 14px); -webkit-mask-position: 0 100%, 0 0; mask-position: 0 100%, 0 0; -webkit-mask-repeat: no-repeat; mask-repeat: no-repeat; border: 0; border-radius: 0; box-shadow: none; } /* vf-couleur-ok: masque, seul l'alpha compte, jamais affiché */
    #context:empty { display: none; }
    /* 71.5 (N5) : au survol, le trait vert/neutre des boutons passe en --text-2 (le trait d'état tombe à 2,68:1 sur le fond de survol en clair) */
    #btn-recent:hover svg.i, #btn-health.calm:hover svg.i { color: var(--text-2); }
  `;
  // spike 005 : la barre de question reste visible quand serve.mjs (P7) sert l'onglet Projet
  // recette 69 : au zoom d'ouverture du jalon (lod-mid, ou lod-low plus loin) le pied des cartes (« à recetter · 9/9 plans … » et la pastille d'état) était masqué ou à 5 px :
  // on le regrandit en unités du graphe (l'échelle le ramène à ~9-10 px à l'écran), sur deux lignes si besoin, et il reste visible à lod-low
  if (TAB === 'project') style.textContent += `
    svg.lod-mid .foot, svg.lod-low .foot { flex-wrap: wrap; row-gap: var(--sp-4); } svg.lod-mid .desc { display: none; }
    svg.lod-mid .foot .meta, svg.lod-low .foot .meta { visibility: visible; font-size: 19px; line-height: 20px; padding: var(--sp-4) var(--sp-12); white-space: normal; }
    svg.lod-mid .foot .vst, svg.lod-low .foot .vst { font-size: 17px; padding: var(--sp-4) var(--sp-12); line-height: 20px; }`;
  /* UIFN-11 (+ onglet Équipe) : le texte du pied cède devant la pastille d'état (elle gardait sa largeur et se faisait rogner : « En cour », et sur un pied long elle sortait de la carte) */
  if (TAB !== 'code') style.textContent += `.foot .meta { min-width: 0; overflow: hidden; text-overflow: ellipsis; } .foot .vst { flex: none; } .ico { --c: var(--text-2) !important; }`; // 71.5 : hors de l'onglet Code, icône nue de la couleur de son texte
  /* UIFN-09 : la ligne « Terminés… » de « Contenu » colorait son point par var(--n-terminés), définie nulle part (point invisible) : le statut « fait » de DESIGN.md §9 */
  if (TAB === 'equipe') style.textContent += `:root { --n-terminés: var(--st-done); }`;
  if (TAB === 'project') style.textContent += `#btn-health${window.FLOORPLAN_SERVER ? '' : ', #ask'} { display: none !important; } #panel .stats:not(.vf-stats) { display: none; }`;
  // onglet Équipe (69-05, P69-PL-09) : ni bouton de santé ni barre de question (la question porte sur le code ou le projet)
  if (TAB === 'equipe') style.textContent += '#btn-health, #ask { display: none !important; } #panel .stats:not(.vf-stats) { display: none; }';
  document.head.appendChild(style);

  // ---------- onglets ----------
  const brand = document.querySelector('header .brand');
  if (brand) {
    const tabs = document.createElement('nav');
    tabs.className = 'vf-tabs';
    tabs.innerHTML = `<a href="index.html" class="${TAB === 'code' ? 'on' : ''}">Code</a><a href="project.html" class="${TAB === 'project' ? 'on' : ''}">Projet</a><a href="equipe.html" class="${TAB === 'equipe' ? 'on' : ''}">Équipe</a>`;
    brand.after(tabs);
  }

  // ---------- onglet Projet : panneau d'ensemble ----------
  // statuts de STATE affichés en français (valeur inconnue : omise ; recette 68 R11, P68-D-35, arbitrage Samuel, AskUserQuestion session principale Claude Code, 2026-11-04 : jamais le statut STATE brut)
  const STATUT = { planning: 'en planification', ready_to_plan: 'prête à planifier', ready_to_execute: 'prête à exécuter', executing: 'en exécution', in_progress: 'en cours', verifying: 'en vérification', ready_for_verification: 'prête à vérifier', paused: 'en pause', blocked: 'bloqué', complete: 'terminée', completed: 'terminée', closed: 'clos', milestone_complete: 'jalon terminé' }; // recette 68 R11 (P68-D-35) : genre de la phase (« prête ») ; Phase 70 : table complète, valeur inconnue omise (jamais affichée brute)
  const statut = (x) => (Object.hasOwn(STATUT, x) ? STATUT[x] : '');
  // dérive de format de la planification (vf-cockpit-drift.mjs) : rien n'est corrigé d'ici, le panneau donne la commande
  const NIV = { bloquant: 'blocked', 'toléré': 'todo', info: 'todo' };
  const derive = (D) => !D || !D.regles || !D.regles.length ? '' : `<div class="sec"><h3>Format de la planification <span class="c">${D.regles.reduce((s, r) => s + (Number(r.n) || 0), 0)}</span></h3>
      ${D.regles.map((r) => `<div class="vf-link"><span class="vst vst-${NIV[r.niveau] || 'todo'}">${h(r.niveau)}</span><span>${h(r.message)} <span style="color:var(--text-3)">(${Number(r.n) || 0} · ${h(r.fichier)})</span></span></div>`).join('')}
      ${D.corrigeable ? `<p class="pd" style="margin-top:var(--sp-12)">Correctif proposé, jamais appliqué d'ici : <code>node vf-cockpit-drift.mjs &lt;lab&gt; --diff</code>, à relire puis appliquer avec <code>git apply</code>.</p>` : ''}</div>`;
  const V = G.meta.vf;
  if (TAB === 'project' && V) {
    SC.setOverview(() => {
      const V = G.meta.vf; // relu à chaque rendu : le direct (70-vf-live.js) remplace G.meta.vf sur un patch
      const ms = V.milestones.map((m) => {
        const pc = m.total ? Math.round((100 * m.done) / m.total) : 0;
        return `<div class="vf-ms" data-vf-go="${h(m.id)}"><div class="t"><span>${h(m.key)}</span><span>${Number(m.done) || 0}/${Number(m.total) || 0} · ${pc} %</span></div><div class="vf-bar st-${h(m.st).replace(/[^\w-]/g, '')}"><i style="width:${pc}%"></i></div></div>`;
      }).join('');
      // état réel de chaque phase (avancement.etat) ; classes existantes seulement, valeur inconnue -> « À faire »
      const ETAT_UI = { 'a-faire': ['vst-todo', 'À faire'], 'en-cours': ['vst-active', 'En cours'], 'a-recetter': ['vst-recette', 'À recetter'] };
      const next = V.next.map((n) => { const u = Object.prototype.hasOwnProperty.call(ETAT_UI, n.etat) ? ETAT_UI[n.etat] : ETAT_UI['a-faire']; return `<a class="vf-link" data-vf-go="${h(n.id)}"><span class="vst ${u[0]}">${u[1]}</span><span>${h(n.label)}</span></a>`; }).join('');
      const c = V.counts;
      // « Maintenant » : seulement les champs connus (un lab sans STATE.md n'a ni jalon, ni phase, ni statut)
      const desc = V.lastDesc || '';
      const now = V.milestone || V.phase || V.status
        ? `<div class="vf-now" style="margin-top:var(--sp-12)"><b>Maintenant${V.milestone ? ' · ' + h(V.milestone) : ''}</b>${V.phase ? `Phase ${h(V.phase)}${V.phaseName ? ' — ' + h(V.phaseName) : ''} ` : ''}${statut(V.status) ? `<span class="vst vst-${V.status === 'closed' ? 'done' : 'active'}">${h(statut(V.status))}</span>` : ''}${desc ? `<div style="margin-top:var(--sp-6);color:var(--text-3);font-size:12px">${h(desc.slice(0, 260))}${desc.length > 260 ? '…' : ''}</div>` : ''}</div>`
        : '';
      return `<div class="sec"><h2 class="pt">${h(G.project.name)}</h2>
          ${now}
          <div class="stats vf-stats" style="margin-top:var(--sp-12)"><div><b>${Number(c.phases) || 0}</b><span>phases</span></div><div><b>${Number(c.plans) || 0}</b><span>plans</span></div><div><b>${Number(c.reqsDone) || 0}/${Number(c.reqs) || 0}</b><span>exigences</span></div></div></div>
        <div class="sec"><h3>Prochaines phases <span class="c">${V.next.length}</span></h3>${next || '<p class="pd">Rien en attente dans le jalon en cours.</p>'}</div>
        <div class="sec"><h3>Jalons <span class="c">${V.milestones.length}</span></h3>${ms}</div>
        ${derive(V.drift)}
        <div class="sec" style="color:var(--text-3);line-height:1.7;font-size:12px">Double-clic sur une carte pour plonger · <span class="kbd">⌫</span> remonter · <span class="kbd">/</span> chercher</div>`;
    });
  }
  document.addEventListener('click', (ev) => {
    const a = ev.target.closest('[data-vf-go]');
    if (a) { ev.preventDefault(); SC.reveal(a.dataset.vfGo); }
  });

  // ---------- pont entre onglets ----------
  const fileOf = (id) => id && id.startsWith('f:') ? SC.files.get?.(id.slice(2)) || (G.files || []).find((f) => 'f:' + f.p === id) : null;
  if (TAB === 'project') {
    SC.addPanelSection('item', (id) => {
      const f = fileOf(id);
      if (!f || !f.touched || !f.touched.length) return '';
      const rows = f.touched.slice(0, 40).map((p) => `<a class="vf-link" href="index.html#r=${encodeURIComponent(p)}"><span>→</span><code>${h(p)}</code></a>`).join('');
      return `<div class="sec"><h3>Fichiers touchés dans l'onglet Code <span class="c">${f.touched.length}</span></h3>${rows}</div>`;
    });
  } else if (TAB === 'code') {
    const touch = G.meta.vfTouch || {};
    SC.addPanelSection('item', (id) => {
      const f = fileOf(id);
      const list = f && touch[f.p];
      if (!list || !list.length) return '';
      const rows = list.slice(0, 30).map((t) => `<a class="vf-link" href="project.html#r=${encodeURIComponent(t.ref)}"><span class="vst vst-${h(t.st).replace(/[^\w-]/g, '')}">${h(ST[t.st] || t.st)}</span><span>${h(t.label)}</span></a>`).join('');
      return `<div class="sec"><h3>Touché par <span class="c">${list.length}</span></h3>${rows}</div>`;
    });
  }
  // arrivée par `#r=<chemin ou id>` : depuis l'autre onglet (à `ready`) ET par un lien de la même page (clic sur un lien de nœud ou d'agent du tiroir ou d'un panneau :
  // seul le fragment change, la page ne se recharge pas, `ready` n'est pas rejoué et le viewer, à `popstate`, revient à la vue d'ensemble : on révèle la cible après lui)
  const arriver = () => {
    const r = new URLSearchParams(location.hash.slice(1)).get('r');
    if (!r) return;
    const id = /^[nf]:/.test(r) ? r : 'f:' + r;
    if (SC.exists(id)) SC.reveal(id); else SC.toast(`Pas sur cette carte : ${r}`);
  };
  // recette 68 R5 : la carte d'une mission abandonnée porte `st: todo` (le viewer n'a pas d'état « abandonnée ») et sa pastille disait « À faire ». Le socle écrit « abandonnée » dans le pied de la carte
  // (LIBELLES_MISSION) : la pastille de CETTE carte est réécrite en « Abandonnée », avant lecture par un lecteur d'écran. Idempotent : une pastille réécrite n'est plus `vst-todo`.
  if (TAB === 'project') {
    const ABANDON = /(?:^|· )abandonnée(?:,|$)/;
    const dire = () => { for (const f of document.querySelectorAll('.card .foot')) { const p = f.querySelector('.vst.vst-todo'), m = f.querySelector('.meta'); if (p && m && ABANDON.test(m.textContent)) { p.classList.replace('vst-todo', 'vst-abandonnee'); p.textContent = 'Abandonnée'; } } };
    let tour = 0; new MutationObserver(() => { if (!tour) tour = requestAnimationFrame(() => { tour = 0; dire(); }); }).observe(document.body, { childList: true, subtree: true }); dire();
  }
  SC.on('ready', arriver);
  window.addEventListener('hashchange', arriver);
})();
