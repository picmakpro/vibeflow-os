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
    const src = Object.entries(G.meta.vf?.sources || {}).map(([k, s]) => `<div class="vf-link"><span>${h(Object.prototype.hasOwnProperty.call(SOURCES, k) ? SOURCES[k] : k)}</span><span class="vst vst-${s?.etat === 'lue' ? 'done' : 'todo'}">${h(Object.prototype.hasOwnProperty.call(ETATS, s?.etat) ? ETATS[s.etat] : 'absente')}</span></div>`).join('');
    return `<div class="sec"><div class="ph"><span class="kind">Équipe</span></div><h2 class="pt">${h(G.project.name)}</h2>
        <div class="stats vf-stats" style="margin-top:14px"><div><b>${n(c.actif)}</b><span>actifs</span></div><div><b>${n(c.enAttente)}</b><span>en attente</span></div><div><b>${n(c.termine)}</b><span>terminés depuis moins de 24 h</span></div></div>
        <p class="pd" style="margin-top:12px">Actifs et terminés depuis moins de 24 h ; le transcript d'un agent ne se lit qu'à la demande.</p></div>
      <div class="sec"><h3>Sources lues <span class="c">${Object.keys(G.meta.vf?.sources || {}).length}</span></h3>${src || '<p class="pd">Aucune source lue.</p>'}</div>`;
  });

  const idCarte = (w) => (w.kind === 'session' ? 'se-' : 'ag-') + w.id;
  const equipe = (who) => (Array.isArray(who?.workers) ? who.workers : []).filter((w) => w && (w.kind === 'session' || w.kind === 'subagent') && typeof w.id === 'string');
  // l'ensemble des agents, avec leur appartenance aux terminés (qui change leur place dans l'arbre des cartes)
  const signature = (liste) => liste.map(([id, fini]) => `${id}${fini ? '~' : ''}`).sort().join('|');
  const dansCarte = () => G.nodes.filter((x) => /^(se|ag)-/.test(x.id)).map((x) => [x.id, x.st === 'done']);
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
    z = document.createElement('div'); z.className = 'vf-transcript'; z.dataset.vfDe = b.dataset.vfTranscript;
    b.after(z); return z;
  };
  const parCarte = () => new Map(equipe(window.__vfLive?.who).map((w) => [idCarte(w), w]));
  async function suivre() {
    const liste = equipe(window.__vfLive?.who);
    if (!window.__vfLive?.who) return;
    const direct = liste.map((w) => [idCarte(w), w.etat === 'termine']);
    if (signature(direct) !== signature(dansCarte())) { recharger(); return; }
    const parId = new Map(liste.map((w) => [idCarte(w), w]));
    const compte = { actif: 0, enAttente: 0, termine: 0 };
    for (const w of liste) { if (w.etat === 'termine') compte.termine++; else if (w.etat === 'en-attente') compte.enAttente++; else compte.actif++; }
    for (const x of G.nodes) { const w = parId.get(x.id); if (w) { x.st = w.etat === 'termine' ? 'done' : 'active'; x.foot = R().pied(w); } }
    G.meta.vf = { ...G.meta.vf, compte };
    // le panneau est redessiné par rerender() : le transcript déjà lu passe d'un conteneur à l'autre, en mémoire de la page seulement
    const ouvert = document.querySelector('.vf-transcript');
    const garde = ouvert ? { id: ouvert.dataset.vfDe, noeuds: [...ouvert.childNodes] } : null;
    await SC.rerender();
    const b = garde && [...document.querySelectorAll('[data-vf-transcript]')].find((x) => x.dataset.vfTranscript === garde.id);
    if (b) zoneDe(b).replaceChildren(...garde.noeuds);
  }
  document.addEventListener('vf-who', suivre);
  SC.on('ready', () => { for (const [id, w] of parCarte()) { const x = G.nodes.find((n) => n.id === id); if (x) x.foot = R().pied(w); } });

  // panneau d'une carte d'agent ou de session
  SC.addPanelSection('item', (id) => {
    const w = typeof id === 'string' && id.startsWith('n:') ? parCarte().get(id.slice(2)) : null;
    if (!w) return '';
    const n = w.rattachement && w.rattachement.etat === 'rattache' ? w.rattachement : null;
    const vers = n ? `<a class="vf-link" href="project.html#r=${encodeURIComponent('f:' + n.dag + '#' + n.noeud)}">Nœud ${h(n.noeud)}</a>`
      : w.kind === 'subagent' ? `<p class="pd">non rattaché (${h((w.rattachement && w.rattachement.raison) || 'inconnu')})</p>` : '';
    return `<div class="sec"><h3>Activité</h3><p class="pd">${h(R().pied(w))}</p>${vers}
      <button type="button" data-vf-doing="${h(w.id)}">Voir la dernière commande</button><div class="vf-doing" hidden></div>
      <button type="button" data-vf-transcript="${h(w.id)}">Lire le transcript</button></div>`;
  });
  // lecture à la demande : requête authentifiée, texte seulement (createElement + textContent dans le rendu), rien n'est conservé
  document.addEventListener('click', async (ev) => {
    const b = ev.target.closest?.('[data-vf-transcript]');
    if (!b) return;
    const zone = zoneDe(b);
    b.disabled = true;
    try {
      const r = SRV && SRV.token ? await fetch('/api/vf/transcript?id=' + encodeURIComponent(b.dataset.vfTranscript), { headers: { 'x-floorplan-token': SRV.token }, cache: 'no-store' }) : null;
      const d = r && r.ok ? await r.json() : null;
      if (d) zone.replaceChildren(R().transcript(d, document)); else zone.textContent = 'Indisponible.';
    } catch { zone.textContent = 'Indisponible.'; }
    b.disabled = false;
  });
  // un lien vers une autre carte de cette page (tiroir « Au travail ») ne recharge pas la page : on révèle la carte visée
  window.addEventListener('hashchange', () => {
    const r = new URLSearchParams(location.hash.slice(1)).get('r');
    if (r && /^n:/.test(r) && SC.exists(r)) SC.reveal(r);
  });
})();
