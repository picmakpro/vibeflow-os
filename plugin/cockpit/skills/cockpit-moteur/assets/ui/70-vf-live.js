// VibeFlow (67-04) : le direct, sur le port de la page. Écoute /api/vf/events (SSE, même origine, jeton de la
// page) et applique les statuts dans la page ouverte sans la recharger : on modifie le graphe en place puis
// Floorplan.rerender() garde le zoom, la position et la sélection. Changement de structure → rechargement (la
// vue vit dans le hash). Badge « au travail » dans l'en-tête, sur les trois onglets. La dernière commande d'une
// session n'est jamais dans le flux : elle se demande à l'unité (/api/vf/doing, jeton en en-tête), et reste
// dans la ligne cliquée (ni graphe, ni localStorage, ni export). Flux coupé : un seul sondage pour les deux flux (celui-ci et le
// rechargement du viewer), à recul — 1 s pendant 30 s, puis 5 s, puis arrêt avec un message et « Réessayer » (E-6).
(() => {
  const SC = window.Floorplan, SRV = window.FLOORPLAN_SERVER;
  // page exportée ou ouverte en fichier : pas de serveur, pas de direct
  if (!SC || !SRV || !SRV.token || typeof EventSource === 'undefined') return;
  const G = SC.graph, h = SC.h;
  const TAB = G.meta.vfTab === 'project' ? 'project' : 'code';
  const probe = (window.__vfLive = { connected: false, patches: 0, applied: 0, lastLatencyMs: null, lock: null, structural: 0, who: null, sondages: 0, abandon: false,
    reco: { vite: 1000, lent: 5000, bascule: 30000, fin: 300000 } }); // reco : en ms, modifiable par un test
  const FRAICHEUR = 'sessions écrites depuis moins de 3 min';

  const style = document.createElement('style');
  style.textContent = `
    #vf-lock { font: 500 12px/1 var(--mono, monospace); gap: 6px; }
    #vf-lock .dot { width: 8px; height: 8px; border-radius: 50%; background: var(--text-4); display: inline-block; }
    #vf-lock.held .dot { background: var(--st-active, #f59e0b); animation: vfpulse 1.6s ease-in-out infinite; }
    #vf-lock.off .dot { background: var(--st-blocked, #ef4444); }
    @keyframes vfpulse { 50% { opacity: .25; } }
    /* D2 (recette 2026-11-02) : le tiroir reprend la marge des panneaux ouverts par showPanel (.sec : 18px 20px 6px, 22 px en premier et dernier enfant) ; sur grand écran sa boîte suit son contenu (plafonnée à la fenêtre, défilement au-delà) au lieu de s'étirer jusqu'en bas.
       Sous 701 px le panneau est un tiroir du bas dont la mise en page appartient au viewer : on n'y touche pas. */
    .vf-whop { padding: 22px 20px; }
    @media (min-width: 701px) { #panel:has(> .vf-whop) { bottom: auto; max-height: calc(100vh - var(--hh, 64px) - 20px); overflow: auto; } }
    .vf-whop h3 { margin: 0 0 4px; } .vf-whop h4 { margin: 16px 0 6px; color: var(--text-3); }
    .vf-whop .regle { color: var(--text-3); font-size: 12px; margin: 0 0 10px; }
    .vf-who { padding: 8px 0; border-top: 1px solid rgba(var(--ink), .08); font-size: 13px; }
    .vf-who span { color: var(--text-3); } .vf-who div { color: var(--text-2); margin-top: 2px; }
    .vf-who.stale { opacity: .55; }
    .vf-who button { margin-top: 6px; font: inherit; font-size: 12px; cursor: pointer; padding: 3px 10px; border-radius: 8px; border: 1px solid rgba(var(--ink), .15); background: transparent; color: var(--text-2); }
    .vf-who .vf-doing { margin-top: 6px; font-family: var(--mono, monospace); font-size: 12px; word-break: break-word; }
    .vf-whop .src { color: var(--text-4); font-size: 11px; margin-top: 14px; }
    .vf-arbre-enfants { margin-left: 14px; padding-left: 10px; border-left: 1px solid rgba(var(--ink), .12); }
    .vf-who .vf-pied { color: var(--text-3); font-size: 12px; } .vf-who .vf-link { display: inline-block; margin: 4px 10px 0 0; font-size: 12px; color: var(--text-2); }
    .vf-termines > summary { cursor: pointer; padding: 8px 0; color: var(--text-3); font-size: 12px; }
    .vf-transcript { max-height: 320px; overflow-y: auto; margin-top: 8px; font-size: 12px; color: var(--text-2); }
    .vf-transcript h4 { margin: 10px 0 4px; color: var(--text-3); } .vf-transcript p, .vf-transcript li { margin: 2px 0; word-break: break-word; }
    .vf-transcript pre { margin: 0; white-space: pre-wrap; word-break: break-word; font-family: var(--mono, monospace); }
    #vf-reco { position: fixed; left: 50%; bottom: 96px; transform: translateX(-50%); z-index: 60; display: flex; align-items: center; gap: 12px; max-width: calc(100vw - 32px); padding: 12px 14px 12px 18px; border-radius: 20px; font-size: 13px; line-height: 1.5; color: var(--text); }
    #vf-reco button { flex: none; border: 0; border-radius: 999px; padding: 7px 14px; cursor: pointer; font: inherit; font-size: 12.5px; background: var(--on); color: var(--on-text); }`;
  document.head.appendChild(style);

  let badge = null, who = null;
  const lockText = (l) => {
    const held = (Array.isArray(l?.locks) ? l.locks : l?.present ? [l] : []).filter((x) => x.present); // lab plat : un seul verrou, sans `locks`
    if (!held.length) return { cls: '', text: 'Driver libre', title: 'Aucun verrou de driver tenu' };
    const x = held[0];
    return { cls: 'held', text: `${x.owner || '?'} · ${x.step || ''} · ${x.age_seconds ?? '?'} s`, title: held.map((y) => `${[y.scope, y.ws].filter(Boolean).join(' ')}${y.scope || y.ws ? ' : ' : ''}${y.owner || '?'}${y.step ? ` (${y.step})` : ''}`).join('\n') }; // lab plat : pas de scope, jamais « undefined : … »
  };
  const KIND = { session: 'Session', subagent: 'Sous-agent', lock: 'Verrou', registered: 'Enregistré', 'dag-node': 'Nœud de DAG' };
  const duree = (s) => window.__vfEquipeRendu.duree(s); // le format vit dans 71-vf-equipe-rendu.js (chargé après ce fichier, appelé après)
  const AGENT = (w) => w.kind === 'session' || w.kind === 'subagent';
  // « au travail » : un agent `actif` non périmé ; un terminé ou un agent en attente n'y est jamais compté (P69-D-14)
  const auTravail = (w) => !w.stale && (w.etat || 'actif') === 'actif';
  const whoPanel = () => {
    const ws = who?.workers || [], act = ws.filter(auTravail), reste = ws.filter((w) => !AGENT(w));
    const row = (w) => `<div class="vf-who ${w.stale ? 'stale' : ''}"><b>${h(KIND[w.kind] || w.kind)}${w.role ? ' · ' + h(w.role) : ''}</b> <span>${h(w.tree || '')}${w.branch ? ' · ' + h(w.branch) : ''} · ${duree(w.ageS)}${w.orphan ? ' · orphelin' : w.stale ? ' · périmé' : ''}</span><div>${h(w.task || '')}</div></div>`;
    const src = Object.entries(who?.sources || {}).map(([k, v]) => `${k} : ${v.etat}`).join(' · ');
    const arbre = window.__vfEquipeRendu.arbre(ws, h);
    SC.showPanel(`<div class="vf-whop"><h3>Au travail (${act.length})</h3><p class="regle">${h(lockText(probe.lock).text)}.</p><p class="regle">Règle de fraîcheur : ${FRAICHEUR}, actifs et terminés depuis moins de 24 h ; la dernière commande et le transcript ne s'affichent que sur demande.</p>${arbre || (reste.length ? '' : '<p>Personne. Sources lues : ' + h(src) + '</p>')}${reste.length ? `<h4>Verrous et nœuds</h4>${reste.map(row).join('')}` : ''}<p class="src">${h(src)}</p></div>`);
  };
  // révélation ponctuelle : la réponse reste dans la ligne cliquée
  document.addEventListener('click', async (ev) => {
    const b = ev.target.closest?.('[data-vf-doing]');
    if (!b) return;
    const zone = b.nextElementSibling;
    b.disabled = true;
    try {
      const r = await fetch('/api/vf/doing?id=' + encodeURIComponent(b.dataset.vfDoing), { headers: { 'x-floorplan-token': SRV.token }, cache: 'no-store' });
      const d = r.ok ? await r.json() : null;
      // `doing` vide : le serveur remonte à la dernière commande Bash de la session ; sans appel Bash lisible il n'y a rien à montrer, jamais un texte de l'assistant en repli (D3)
      zone.textContent = d?.doing || (d?.erreur === 'inconnu' ? 'Plus active : rien à montrer.' : d?.erreur === 'sans-action' ? "Aucune commande Bash dans la fin du journal de cette session." : 'Indisponible.');
    } catch { zone.textContent = 'Indisponible.'; }
    zone.hidden = false; b.disabled = false;
  });
  const showLock = (l, off) => {
    if (l !== undefined) probe.lock = l;
    if (!badge) badge = SC.addHeaderButton({ id: 'vf-lock', label: '…', title: 'Qui est au travail', onClick: whoPanel });
    const t = off ? { cls: 'off', text: 'Direct coupé', title: 'Le serveur du cockpit ne répond pas' } : lockText(probe.lock);
    const n = (who?.workers || []).filter(auTravail).length;
    badge.className = 'btn ' + (n ? 'held' : t.cls); badge.title = off ? t.title : `${n ? n + ' au travail' : 'Personne au travail'} · ${t.title}`;
    // compact : le détail (propriétaire du verrou, étape, durée) est dans l'infobulle et dans le panneau « Au travail »
    badge.setAttribute('aria-label', off ? t.text : n ? `${n} au travail` : 'Personne au travail'); // sinon figé à « … » (libellé de création)
    badge.innerHTML = `<span class="dot"></span><span class="bl">${off ? t.text : n ? `${n} au travail` : 'Personne'}</span>`;
  };
  const setWho = (w) => { if (!w) return; who = probe.who = w; showLock(); document.dispatchEvent(new CustomEvent('vf-who')); }; // 69-05 : l'onglet Équipe (72-vf-equipe.js) suit le même flux

  // I3 (recette 2026-11-02) : une bascule en direct redessine la carte, qui rejouait son animation d'apparition (cartes, liens, colonnes,
  // panneau). On ne l'anime plus : les éléments redessinés portent `animation: none` en ligne AVANT la première image (la suite de
  // rerender() s'exécute en microtâche, avant la peinture), sauf les cartes dont l'état a basculé, qui reçoivent le clignotement du viewer
  // (`flash`). Zoom et position restent ceux de rerender() (keepTransform). Les éléments neufs d'une vraie navigation ne portent rien.
  const titreDe = (c) => c.querySelector('.title')?.textContent || '';
  const sansEntree = async () => {
    const avant = new Map([...document.querySelectorAll('#viewport .node .card')].map((c) => [titreDe(c), c.className]));
    await SC.rerender();
    for (const c of document.querySelectorAll('#viewport .node .card')) {
      const g = c.closest('g.node'), k = titreDe(c); // la carte porte aussi la classe node : on vise le groupe SVG
      if (g && avant.has(k) && avant.get(k) !== c.className) { g.classList.remove('flash'); g.classList.add('flash'); } else c.style.animation = 'none';
    }
    for (const e of document.querySelectorAll('#viewport .edges, #viewport .cols, #panel > *')) e.style.animation = 'none';
  };

  // onglet Projet, panneau d'un nœud de mission (`f:<dag>#<noeud>`) : les agents rattachés à ce nœud, lien vers leur carte (P69-D-15)
  if (G.meta.vfTab === 'project' && SC.addPanelSection) SC.addPanelSection('item', (id) => {
    if (typeof id !== 'string' || !id.startsWith('f:') || !id.includes('#')) return '';
    const l = window.__vfEquipeRendu.agentsDuNoeud(who?.workers, id, h);
    return l ? `<div class="sec"><h3>Agents sur ce nœud</h3>${l}</div>` : '';
  });
  const find = (ref) => ref.startsWith('n:') ? G.nodes.find((n) => n.id === ref.slice(2)) : G.files.find((f) => f.p === ref.slice(2));
  // ---------- reconnexion à recul : un seul sondage pour les deux flux ----------
  const lost = { t0: 0, timer: null, flux: new Map() };
  const sonder = async () => { // 'vivant' : même serveur, même jeton · 'redemarre' : le jeton a changé · 'coupe' : rien ne répond
    try { const r = await fetch('/api/vf/etat', { headers: { 'x-floorplan-token': SRV.token }, cache: 'no-store' }); return r.ok ? 'vivant' : 'redemarre'; } catch { return 'coupe'; }
  };
  const banniere = (on) => {
    let b = document.getElementById('vf-reco');
    if (!on) { b?.remove(); return; }
    if (b) return;
    b = document.createElement('div'); b.id = 'vf-reco'; b.className = 'glass'; b.setAttribute('role', 'alert');
    const t = document.createElement('span'); t.textContent = 'Le cockpit ne répond plus : le serveur est arrêté. Relancez-le (/vf-cockpit), puis réessayez.';
    const k = document.createElement('button'); k.type = 'button'; k.textContent = 'Réessayer'; k.onclick = () => { lost.t0 = Date.now(); probe.abandon = false; banniere(false); boucle(0); };
    b.append(t, k); document.body.appendChild(b);
  };
  const boucle = (delai) => {
    lost.timer = setTimeout(async () => {
      const age = Date.now() - lost.t0; probe.sondages++;
      const e = await sonder();
      if (e === 'redemarre') return location.reload(); // nouveau serveur, nouveau jeton : la page se recharge
      if (e === 'vivant') { for (const f of lost.flux.values()) f(); lost.flux.clear(); lost.timer = null; return; }
      if (Date.now() - lost.t0 >= probe.reco.fin) { lost.timer = null; probe.abandon = true; banniere(true); return; }
      boucle(age < probe.reco.bascule ? probe.reco.vite : probe.reco.lent);
    }, delai);
  };
  // un flux qui tombe se ferme (le navigateur réessaierait chaque seconde, sans fin) et s'inscrit au sondage commun
  const perdu = (nom, reconnecter) => {
    probe.connected = false; showLock(null, true);
    lost.flux.set(nom, reconnecter);
    if (lost.timer === null && !probe.abandon) { lost.t0 = Date.now(); boucle(probe.reco.vite); }
  };
  window.FLOORPLAN_STREAM_LOST = perdu; // appelé par le rechargement automatique du viewer (patch P21)

  // resynchronisation : un `hello` dont la séquence a bougé depuis le dernier événement vu = des événements ont été manqués (coupure) : la page se recharge
  let lastSeq = null;
  const vu = (d) => { if (typeof d?.seq === 'number') lastSeq = d.seq; return d; };
  const connecter = () => {
    const es = new EventSource('/api/vf/events?token=' + encodeURIComponent(SRV.token));
    es.addEventListener('hello', (e) => {
      probe.connected = true; const d = JSON.parse(e.data);
      if (TAB === 'project' && lastSeq !== null && typeof d.seq === 'number' && d.seq !== lastSeq) { probe.resync = (probe.resync || 0) + 1; location.reload(); return; }
      vu(d); setWho(d.who); showLock(d.lock);
    });
    es.addEventListener('who', (e) => setWho(vu(JSON.parse(e.data)).who));
    es.addEventListener('lock', (e) => showLock(vu(JSON.parse(e.data)).lock));
    es.addEventListener('patch', (e) => {
      const d = vu(JSON.parse(e.data));
      probe.patches++;
      if (TAB !== 'project') return; // les refs du patch sont celles du graphe Projet
      let n = 0;
      for (const p of d.patch) { const x = find(p.ref); if (!x) continue; x.st = p.st || undefined; x.foot = p.foot || undefined; if (typeof p.sum === 'string') x.summary = p.sum; n++; }
      if (d.vf) { G.meta.vf = d.vf; n++; }
      probe.applied += n;
      probe.lastLatencyMs = Date.now() - d.at;
      if (n) { sansEntree().catch(() => {}); SC.toast(`${n} statut(s) mis à jour`); }
    });
    es.addEventListener('structural', (e) => { vu(JSON.parse(e.data)); probe.structural++; if (TAB === 'project') { SC.toast('Projet modifié : rechargement'); setTimeout(() => location.reload(), 400); } });
    es.onerror = () => { es.close(); perdu('direct', connecter); };
  };
  connecter();
})();
