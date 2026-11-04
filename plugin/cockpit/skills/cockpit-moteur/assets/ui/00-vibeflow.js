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
  // titre de l'onglet du navigateur : « <nom> — Code », « <nom> — Projet » ou « Équipe · <nom> » (le viewer écrit « <nom> map », qui devenait le nom seul)
  { const nom = String(G.project.name || '').replace(/ — (Projet|Équipe)$/, ''); document.title = TAB === 'equipe' ? `Équipe · ${nom}` : `${nom} — ${TAB === 'project' ? 'Projet' : 'Code'}`; }
  const ST = { done: 'Fait', active: 'En cours', todo: 'À faire', blocked: 'Bloqué' };
  // P67-D-04 : logo VibeFlow clair ou sombre selon le thème du viewer (meta.vfLogos est posé par l'assemblage)
  const LOGOS = G.meta.vfLogos;
  if (LOGOS) {
    const mark = document.querySelector('.brand .mark');
    const sync = () => { if (mark) mark.src = document.documentElement.getAttribute('data-theme') === 'dark' ? LOGOS.sombre : LOGOS.clair; };
    sync(); window.addEventListener('floorplan-theme-change', sync);
  }

  const style = document.createElement('style');
  style.textContent = `
    :root { --st-done: var(--recent); --st-active: var(--sev-medium); --st-todo: var(--text-4); --st-blocked: var(--sev-high); }
    .vf-tabs { display: inline-flex; gap: 2px; padding: 3px; margin-left: 14px; border-radius: 12px; background: var(--raise); flex: none; }
    .vf-tabs a { padding: 5px 13px; border-radius: 9px; font-size: 13px; font-weight: 500; color: var(--text-3); text-decoration: none; line-height: 1.4; }
    .vf-tabs a:hover { color: var(--text); }
    .vf-tabs a.on { background: var(--surface); color: var(--text); box-shadow: 0 1px 2px rgba(0,0,0,.18); }
    /* 69-05 : trois onglets au lieu de deux : resserrés à toute largeur pour tenir à côté de la marque, du fil d'Ariane, de la recherche et du zoom (mesuré par test-cockpit-responsive.sh) */
      .vf-tabs { margin-left: 10px; padding: 2px; } .vf-tabs a { padding: 5px 6px; font-size: 12px; }
    .vst { font-size: 11px; font-weight: 600; padding: 2px 8px; border-radius: 999px; white-space: nowrap;
      /* texte teinté vers --text : le statut seul passait sous 4,5:1 sur sa pastille en thème clair (recette 69) */
      color: color-mix(in srgb, var(--c-st) 68%, var(--text)); background: color-mix(in srgb, var(--c-st) 14%, transparent); }
    .vst-done { --c-st: var(--st-done); } .vst-active { --c-st: var(--st-active); } .vst-todo { --c-st: var(--st-todo); } .vst-blocked { --c-st: var(--st-blocked); }
    .card.st-active { box-shadow: 0 0 0 1.5px var(--st-active), 0 8px 28px color-mix(in srgb, var(--st-active) 22%, transparent); }
    .card.st-blocked { box-shadow: 0 0 0 1.5px var(--st-blocked); }
    .card.st-done .desc { opacity: .78; }
    .vf-bar { height: 6px; border-radius: 99px; background: var(--raise-2); overflow: hidden; margin-top: 6px; }
    .vf-bar i { display: block; height: 100%; border-radius: 99px; background: var(--c-st, var(--st-done)); }
    .vf-ms { padding: 9px 12px; border-radius: 14px; cursor: pointer; margin-bottom: 4px; }
    .vf-ms:hover { background: var(--surface-hover); }
    .vf-ms .t { display: flex; justify-content: space-between; gap: 8px; font-size: 13px; font-weight: 500; }
    .vf-ms .t span:last-child { color: var(--text-3); font-weight: 400; font-variant-numeric: tabular-nums; }
    .vf-now { padding: 12px 14px; border-radius: 16px; background: color-mix(in srgb, var(--st-active) 8%, transparent); font-size: 13px; line-height: 1.55; }
    .vf-now b { display: block; font-size: 11.5px; color: color-mix(in srgb, var(--st-active) 68%, var(--text)); margin-bottom: 3px; font-weight: 600; }
    .vf-link { display: flex; gap: 8px; align-items: baseline; padding: 6px 10px; border-radius: 10px; font-size: 12.5px; color: inherit; text-decoration: none; }
    .vf-link:hover { background: var(--surface-hover); }
    .vf-link code { font-family: 'JetBrains Mono', monospace; font-size: 11.5px; color: var(--text-2); word-break: break-all; }
    /* I2 (recette 2026-11-02, reprise 2026-11-03, avis de Samuel, Wispr Flow, session principale, 2026-11-03 : « pas de bordure, un flou dégradé qui part du haut gauche et descend, comme le header, en mode iOS 26 ») :
       le titre et le sous-titre de la vue d'ensemble se mélangeaient aux graphes que l'on fait glisser dessous. Plus de carte : #context n'a ni fond, ni bordure, ni rayon, ni ombre.
       Le flou vit sur #context::before (qui déborde du texte pour un fondu doux) : backdrop-filter blur + saturate (la recette de .glass) et un fond --bg-rgb léger (le matériau du header),
       le tout masqué par un dégradé radial ancré en haut à gauche : plein derrière le début du titre, il s'estompe vers le bas et vers la droite. Les deux thèmes suivent --bg-rgb.
       Reprise (avis de Samuel, Wispr Flow, session principale, 2026-11-03 : « un gap sans flou entre le texte et le header, allonger le flou jusqu'au header ») : le dégradé de l'en-tête s'estompe sur sa hauteur et laissait voir la carte nette
       entre le bas de la couche et ce fondu ; la couche monte donc jusqu'au haut de l'en-tête (inset relatif à --hh, jamais une valeur calée sur une largeur), DERRIÈRE lui (z-index 10), et le dégradé garde sa taille d'avant (masque en deux couches : le radial sur la hauteur d'avant, calé en bas ; au-dessus, la bande reprend son profil de bord haut, plein puis estompé vers la droite) : l'aspect autour du titre ne change pas.
       isolation: isolate garde la couche derrière le texte. #context ne capte aucun événement (pointer-events: none, hérité du viewer) : la carte reste glissable sous la zone. */
    #context { isolation: isolate; background: none; border: 0; border-radius: 0; box-shadow: none; }
    #context::before { inset: calc(-1 * (var(--hh, 64px) + 8px)) -80px -64px -36px; background: rgba(var(--bg-rgb), .28); -webkit-backdrop-filter: blur(22px) saturate(1.6); backdrop-filter: blur(22px) saturate(1.6); -webkit-mask-image: radial-gradient(ellipse 100% 100% at 0% 0%, #000 40%, transparent 100%), linear-gradient(to right, #000 40%, transparent 100%); mask-image: radial-gradient(ellipse 100% 100% at 0% 0%, #000 40%, transparent 100%), linear-gradient(to right, #000 40%, transparent 100%); -webkit-mask-size: 100% calc(100% - var(--hh, 64px) + 14px), 100% calc(var(--hh, 64px) - 14px); mask-size: 100% calc(100% - var(--hh, 64px) + 14px), 100% calc(var(--hh, 64px) - 14px); -webkit-mask-position: 0 100%, 0 0; mask-position: 0 100%, 0 0; -webkit-mask-repeat: no-repeat; mask-repeat: no-repeat; border: 0; border-radius: 0; box-shadow: none; }
    #context:empty { display: none; }
  `;
  // spike 005 : la barre de question reste visible quand serve.mjs (P7) sert l'onglet Projet
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
  // statuts de STATE affichés en français (valeur inconnue : telle quelle)
  const STATUT = { closed: 'clos', complete: 'terminée', completed: 'terminée', executing: 'en exécution', planning: 'en planification', paused: 'en pause', verifying: 'en vérification' };
  const statut = (x) => STATUT[x] || x || '';
  // dérive de format de la planification (vf-cockpit-drift.mjs) : rien n'est corrigé d'ici, le panneau donne la commande
  const NIV = { bloquant: 'blocked', 'toléré': 'todo', info: 'todo' };
  const derive = (D) => !D || !D.regles || !D.regles.length ? '' : `<div class="sec"><h3>Format de la planification <span class="c">${D.regles.reduce((s, r) => s + (Number(r.n) || 0), 0)}</span></h3>
      ${D.regles.map((r) => `<div class="vf-link"><span class="vst vst-${NIV[r.niveau] || 'todo'}">${h(r.niveau)}</span><span>${h(r.message)} <span style="color:var(--text-3)">(${Number(r.n) || 0} · ${h(r.fichier)})</span></span></div>`).join('')}
      ${D.corrigeable ? `<p class="pd" style="margin-top:8px">Correctif proposé, jamais appliqué d'ici : <code>node vf-cockpit-drift.mjs &lt;lab&gt; --diff</code>, à relire puis appliquer avec <code>git apply</code>.</p>` : ''}</div>`;
  const V = G.meta.vf;
  if (TAB === 'project' && V) {
    SC.setOverview(() => {
      const V = G.meta.vf; // relu à chaque rendu : le direct (70-vf-live.js) remplace G.meta.vf sur un patch
      const ms = V.milestones.map((m) => {
        const pc = m.total ? Math.round((100 * m.done) / m.total) : 0;
        return `<div class="vf-ms" data-vf-go="${h(m.id)}"><div class="t"><span>${h(m.key)}</span><span>${Number(m.done) || 0}/${Number(m.total) || 0} · ${pc} %</span></div><div class="vf-bar" style="--c-st:var(--st-${h(m.st).replace(/[^\w-]/g, '')})"><i style="width:${pc}%"></i></div></div>`;
      }).join('');
      // état réel de chaque phase (avancement.etat) ; classes existantes seulement, valeur inconnue -> « À faire »
      const ETAT_UI = { 'a-faire': ['vst-todo', 'À faire'], 'en-cours': ['vst-active', 'En cours'], 'a-recetter': ['vst-active', 'À recetter'] };
      const next = V.next.map((n) => { const u = Object.prototype.hasOwnProperty.call(ETAT_UI, n.etat) ? ETAT_UI[n.etat] : ETAT_UI['a-faire']; return `<a class="vf-link" data-vf-go="${h(n.id)}"><span class="vst ${u[0]}">${u[1]}</span><span>${h(n.label)}</span></a>`; }).join('');
      const c = V.counts;
      // « Maintenant » : seulement les champs connus (un lab sans STATE.md n'a ni jalon, ni phase, ni statut)
      const desc = V.lastDesc || '';
      const now = V.milestone || V.phase || V.status
        ? `<div class="vf-now" style="margin-top:12px"><b>Maintenant${V.milestone ? ' · ' + h(V.milestone) : ''}</b>${V.phase ? `Phase ${h(V.phase)}${V.phaseName ? ' — ' + h(V.phaseName) : ''} ` : ''}${V.status ? `<span class="vst vst-${V.status === 'closed' ? 'done' : 'active'}">${h(statut(V.status))}</span>` : ''}${desc ? `<div style="margin-top:6px;color:var(--text-3);font-size:12px">${h(desc.slice(0, 260))}${desc.length > 260 ? '…' : ''}</div>` : ''}</div>`
        : '';
      return `<div class="sec"><div class="ph"><span class="kind">Projet</span></div><h2 class="pt">${h(G.project.name)}</h2>
          ${now}
          <div class="stats vf-stats" style="margin-top:14px"><div><b>${Number(c.phases) || 0}</b><span>phases</span></div><div><b>${Number(c.plans) || 0}</b><span>plans</span></div><div><b>${Number(c.reqsDone) || 0}/${Number(c.reqs) || 0}</b><span>exigences</span></div></div></div>
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
  SC.on('ready', arriver);
  window.addEventListener('hashchange', arriver);
})();
