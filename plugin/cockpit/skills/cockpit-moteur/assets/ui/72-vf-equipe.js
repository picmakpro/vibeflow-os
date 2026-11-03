// VibeFlow (69-05) : onglet Équipe, troisième onglet du viewer (P69-D-17). Vue d'ensemble de l'équipe (effectifs, état des sources de la collecte) et
// mise à jour en direct : l'événement de document `vf-who`, émis par 70-vf-live.js à chaque `who` reçu, met l'état des cartes à jour en place ; la page
// ne se recharge que si l'ensemble des sessions et sous-agents change, au plus une fois par 15 s. Ne fait rien hors de l'onglet Équipe.
// Aucune couleur ni ombre en dur : les classes et les variables du thème du viewer. Toute valeur interpolée passe par h() (P23).
(() => {
  const SC = window.Floorplan;
  if (!SC || !SC.graph?.meta || SC.graph.meta.vfTab !== 'equipe') return;
  const { h, graph: G } = SC;
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

  function suivre() {
    const liste = equipe(window.__vfLive?.who);
    if (!window.__vfLive?.who) return;
    const direct = liste.map((w) => [idCarte(w), w.etat === 'termine']);
    if (signature(direct) !== signature(dansCarte())) { recharger(); return; }
    const parId = new Map(liste.map((w) => [idCarte(w), w]));
    const compte = { actif: 0, enAttente: 0, termine: 0 };
    for (const w of liste) { if (w.etat === 'termine') compte.termine++; else if (w.etat === 'en-attente') compte.enAttente++; else compte.actif++; }
    for (const x of G.nodes) { const w = parId.get(x.id); if (w) x.st = w.etat === 'termine' ? 'done' : 'active'; }
    G.meta.vf = { ...G.meta.vf, compte };
    SC.rerender();
  }
  document.addEventListener('vf-who', suivre);
})();
