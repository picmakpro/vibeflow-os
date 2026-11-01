// VibeFlow (67-04) : le direct, sur le port de la page. Écoute /api/vf/events (SSE, même origine, jeton de la
// page) et applique les statuts dans la page ouverte sans la recharger : on modifie le graphe en place puis
// Floorplan.rerender() garde le zoom, la position et la sélection. Changement de structure → rechargement (la
// vue vit dans le hash). Badge « au travail » dans l'en-tête, sur les deux onglets. La dernière commande d'une
// session n'est jamais dans le flux : elle se demande à l'unité (/api/vf/doing, jeton en en-tête), et reste
// dans la ligne cliquée (ni graphe, ni localStorage, ni export).
(() => {
  const SC = window.Floorplan, SRV = window.FLOORPLAN_SERVER;
  // page exportée ou ouverte en fichier : pas de serveur, pas de direct
  if (!SC || !SRV || !SRV.token || typeof EventSource === 'undefined') return;
  const G = SC.graph, h = SC.h;
  const TAB = G.meta.vfTab === 'project' ? 'project' : 'code';
  const probe = (window.__vfLive = { connected: false, patches: 0, applied: 0, lastLatencyMs: null, lock: null, structural: 0, who: null });
  const FRAICHEUR = 'sessions écrites depuis moins de 3 min';

  const style = document.createElement('style');
  style.textContent = `
    #vf-lock { font: 500 12px/1 var(--mono, monospace); gap: 6px; }
    #vf-lock .dot { width: 8px; height: 8px; border-radius: 50%; background: var(--text-4); display: inline-block; }
    #vf-lock.held .dot { background: var(--st-active, #f59e0b); animation: vfpulse 1.6s ease-in-out infinite; }
    #vf-lock.off .dot { background: var(--st-blocked, #ef4444); }
    @keyframes vfpulse { 50% { opacity: .25; } }
    .vf-whop h3 { margin: 0 0 4px; } .vf-whop h4 { margin: 16px 0 6px; color: var(--text-3); }
    .vf-whop .regle { color: var(--text-3); font-size: 12px; margin: 0 0 10px; }
    .vf-who { padding: 8px 0; border-top: 1px solid rgba(var(--ink), .08); font-size: 13px; }
    .vf-who span { color: var(--text-3); } .vf-who div { color: var(--text-2); margin-top: 2px; }
    .vf-who.stale { opacity: .55; }
    .vf-who button { margin-top: 6px; font: inherit; font-size: 12px; cursor: pointer; padding: 3px 10px; border-radius: 8px; border: 1px solid rgba(var(--ink), .15); background: transparent; color: var(--text-2); }
    .vf-who .vf-doing { margin-top: 6px; font-family: var(--mono, monospace); font-size: 12px; word-break: break-word; }
    .vf-whop .src { color: var(--text-4); font-size: 11px; margin-top: 14px; }`;
  document.head.appendChild(style);

  let badge = null, who = null;
  const lockText = (l) => {
    const held = (l?.locks || []).filter((x) => x.present);
    if (!held.length) return { cls: '', text: 'Driver libre', title: 'Aucun verrou de driver tenu' };
    const x = held[0];
    return { cls: 'held', text: `${x.owner || '?'} · ${x.step || ''} · ${x.age_seconds ?? '?'} s`, title: held.map((y) => `${y.scope}${y.ws ? ' ' + y.ws : ''} : ${y.owner} (${y.step})`).join('\n') };
  };
  const KIND = { session: 'Session', subagent: 'Sous-agent', lock: 'Verrou', registered: 'Enregistré', 'dag-node': 'Nœud de DAG' };
  const age = (s) => s == null ? '' : s < 90 ? `${s} s` : s < 5400 ? `${Math.round(s / 60)} min` : s < 172800 ? `${Math.round(s / 3600)} h` : `${Math.round(s / 86400)} j`;
  const whoPanel = () => {
    const ws = who?.workers || [], act = ws.filter((w) => !w.stale), old = ws.filter((w) => w.stale);
    const row = (w) => {
      const rev = w.kind === 'session' || w.kind === 'subagent';
      return `<div class="vf-who ${w.stale ? 'stale' : ''}"><b>${h(KIND[w.kind] || w.kind)}${w.role ? ' · ' + h(w.role) : ''}</b> <span>${h(w.tree || '')}${w.branch ? ' · ' + h(w.branch) : ''} · ${age(w.ageS)}${w.orphan ? ' · orphelin' : w.stale ? ' · périmé' : ''}</span>`
        + `<div>${h(w.task || '')}</div>${rev ? `<button type="button" data-vf-doing="${h(w.id)}">Voir la dernière commande</button><div class="vf-doing" hidden></div>` : ''}</div>`;
    };
    const src = Object.entries(who?.sources || {}).map(([k, v]) => `${k} : ${v.etat}`).join(' · ');
    SC.showPanel(`<div class="vf-whop"><h3>Au travail (${act.length})</h3><p class="regle">Règle de fraîcheur : ${FRAICHEUR}. La dernière commande n'est affichée que sur demande.</p>${act.map(row).join('') || '<p>Personne. Sources lues : ' + h(src) + '</p>'}${old.length ? `<h4>Signaux périmés (${old.length})</h4>${old.map(row).join('')}` : ''}<p class="src">${h(src)}</p></div>`);
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
      zone.textContent = d?.doing || (d?.erreur === 'inconnu' ? 'Plus active : rien à montrer.' : 'Indisponible.');
    } catch { zone.textContent = 'Indisponible.'; }
    zone.hidden = false; b.disabled = false;
  });
  const showLock = (l, off) => {
    if (l !== undefined) probe.lock = l;
    if (!badge) badge = SC.addHeaderButton({ id: 'vf-lock', label: '…', title: 'Qui est au travail', onClick: whoPanel });
    const t = off ? { cls: 'off', text: 'Direct coupé', title: 'Le serveur du cockpit ne répond pas' } : lockText(probe.lock);
    const n = (who?.workers || []).filter((w) => !w.stale).length;
    badge.className = 'btn ' + (n ? 'held' : t.cls); badge.title = t.title;
    badge.innerHTML = `<span class="dot"></span><span class="bl">${off ? t.text : `${n ? n + ' au travail' : 'Personne'} · ${h(t.text)}`}</span>`;
  };
  const setWho = (w) => { if (!w) return; who = probe.who = w; showLock(); };

  const find = (ref) => ref.startsWith('n:') ? G.nodes.find((n) => n.id === ref.slice(2)) : G.files.find((f) => f.p === ref.slice(2));
  const es = new EventSource('/api/vf/events?token=' + encodeURIComponent(SRV.token));
  es.addEventListener('hello', (e) => { probe.connected = true; const d = JSON.parse(e.data); setWho(d.who); showLock(d.lock); });
  es.addEventListener('who', (e) => setWho(JSON.parse(e.data).who));
  es.addEventListener('lock', (e) => showLock(JSON.parse(e.data).lock));
  es.addEventListener('patch', (e) => {
    const d = JSON.parse(e.data);
    probe.patches++;
    if (TAB !== 'project') return; // les refs du patch sont celles du graphe Projet
    let n = 0;
    for (const p of d.patch) { const x = find(p.ref); if (!x) continue; x.st = p.st || undefined; x.foot = p.foot || undefined; n++; }
    if (d.vf) { G.meta.vf = d.vf; n++; }
    probe.applied += n;
    probe.lastLatencyMs = Date.now() - d.at;
    if (n) { SC.rerender(); SC.toast(`${n} statut(s) mis à jour`); }
  });
  es.addEventListener('structural', () => { probe.structural++; if (TAB === 'project') { SC.toast('Projet modifié : rechargement'); setTimeout(() => location.reload(), 400); } });
  es.onerror = () => { probe.connected = false; showLock(null, true); };
})();
