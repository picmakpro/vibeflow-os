// VibeFlow (80-04) : vue DOM de Projet en couloirs (FORM-05, P80-D-01, P80-D-02) — montée dans main#stage par-dessus la scène du moteur, qui continue de rendre dessous.
// Modèle et rendu : 41-vf-projet-modele.js, 41-vf-projet-rendu.js ; clavier : 41-vf-projet-clavier.js. Ne parle au viewer que par window.Floorplan, sans patch ni requête.
// Exposé : window.VF_PROJET { formes(), forme(), basculer(nom), carteDe(id) } (gelé). `?vue=` : liste fermée (couloirs, graphe ici ; 80-07 y inscrit « liste »), sinon la forme par défaut.
(() => {
  const SC = window.Floorplan, M = window.__vfProjetModele, R = window.__vfProjetRendu;
  if (!SC || !M || !R || !SC.graph.meta || SC.graph.meta.vfTab !== 'project') return;
  const { graph: G, state } = SC;
  const stage = document.getElementById('stage');
  if (!stage) return;
  const FORMES = ['couloirs', 'graphe'], LIBELLES = { couloirs: 'Couloirs', graphe: 'Graphe' };
  const demandee = new URLSearchParams(location.search).get('vue'); // T-80-08 : une valeur hors de la liste vaut la forme par défaut, jamais insérée dans le DOM
  let forme = FORMES.includes(demandee) ? demandee : 'couloirs', vivant = false, section = null, corps = null, statut = null, flottant = null;
  const ouverts = new Set(), noeuds = () => new Map((G.nodes || []).map((n) => [n.id, n]));
  const conteneurJalon = () => { const c = String(state.container); const n = c.startsWith('n:') ? noeuds().get(c.slice(2)) : null; return c === 'n:history' || (!!n && n.kind === 'jalon'); };
  const affichee = () => forme === 'couloirs' && (state.container === 'root' || conteneurJalon()); // un jalon vu en couloirs est ramené à la racine (P80-C76-3)

  const style = document.createElement('style');
  style.textContent = `
    section.vf-projet { position: absolute; inset: 0; z-index: 1; overflow: auto; box-sizing: border-box; scroll-behavior: auto; font-family: var(--sans); color: var(--text);
      padding: calc(var(--hh, 64px) + var(--sp-16)) var(--edge) var(--vf-bas, var(--sp-32)); scroll-padding-block-end: var(--vf-bas, var(--sp-32)); scroll-padding-block-start: calc(var(--hh, 64px) + var(--sp-16)); }
    body:not(.vf-forme-couloirs) section.vf-projet { display: none; }
    body.vf-forme-couloirs #svg { visibility: hidden; } body.vf-forme-couloirs #zoom, body.vf-forme-couloirs #context { display: none; }
    section.vf-projet button { font: inherit; color: inherit; text-align: left; cursor: pointer; }
    .vp-tete { display: flex; align-items: center; justify-content: space-between; gap: var(--sp-16); margin-bottom: var(--sp-16); flex-wrap: wrap; }
    .vp-tete h1 { margin: 0; font-size: 22px; font-weight: 600; letter-spacing: -.02em; } .vp-tete h1:focus { outline: none; }
    .vp-bascule { display: inline-flex; gap: var(--sp-2); padding: var(--sp-4); border-radius: var(--r-ctl); background: var(--raise); flex: none; }
    .vp-bascule button { min-height: 36px; padding: 0 var(--sp-12); border: 0; border-radius: 9px; background: none; font-size: 13px; font-weight: 500; color: var(--text-3); }
    .vp-bascule button[aria-pressed="true"] { background: var(--surface); color: var(--text); font-weight: 600; box-shadow: var(--shadow-card); }
    .vp-bascule button:focus-visible, .vp-carte:focus-visible, .vp-rangee:focus-visible, .vp-details summary:focus-visible { outline: 2px solid var(--ring); outline-offset: var(--sp-2); }
    #vf-projet-flottant { position: absolute; z-index: 3; left: var(--edge); top: calc(var(--hh, 64px) + var(--sp-8)); } body.vf-forme-couloirs #vf-projet-flottant { display: none; }
    .vp-status { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }
    .vp-info { padding: var(--inset-box); border-radius: var(--r-ctl); background: var(--surface); font-size: 13px; color: var(--text-2); margin-bottom: var(--gap-section); }
    .vp-info p { margin: 0; } .vp-info p + p { margin-top: var(--sp-4); }
    .vp-jalon { margin-bottom: var(--gap-section); }
    .vp-jt { display: flex; align-items: flex-end; justify-content: space-between; gap: var(--sp-16); flex-wrap: wrap; margin-bottom: var(--sp-16); }
    .vp-jn h2 { margin: 0; font-size: 18px; font-weight: 600; letter-spacing: -.015em; } .vp-syn { margin: var(--sp-2) 0 0; font-size: 13px; color: var(--text-2); }
    .vp-barre { display: flex; align-items: center; gap: var(--sp-12); } .vp-barre .vf-bar { width: 180px; margin-top: 0; }
    .vp-pc { font-family: var(--mono); font-size: 12px; font-weight: 500; color: var(--text-3); }
    .vp-couloirs { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: var(--sp-16); }
    .vp-ch { display: flex; align-items: center; gap: var(--sp-4); margin: 0 0 var(--sp-12); padding-bottom: var(--sp-8); border-bottom: 1px solid var(--hair-2); font-size: 13px; font-weight: 500; color: var(--text); }
    .vp-ch .vp-mot { flex: 1; } .vp-n { font-family: var(--mono); font-size: 12px; font-weight: 500; color: var(--text-3); }
    .vp-cartes, .vp-rangees { list-style: none; margin: 0; padding: 0; } .vp-cartes { display: flex; flex-direction: column; gap: var(--sp-8); }
    .vp-vide { margin: var(--sp-8) 0 0; font-size: 12px; color: var(--text-3); }
    .vp-carte { display: grid; grid-template-columns: min-content minmax(0, 1fr); column-gap: var(--sp-8); row-gap: var(--sp-2); align-items: baseline; width: 100%; min-height: 44px; box-sizing: border-box;
      padding: var(--sp-12) var(--inset-card); border: 1.5px solid transparent; border-radius: var(--r-card); background: var(--surface); box-shadow: var(--shadow-card); }
    .vp-num { min-width: 5ch; font-family: var(--mono); font-size: 12.5px; font-weight: 500; color: var(--text-3); }
    .vp-titre { display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; overflow-wrap: anywhere; font-size: 13px; line-height: 1.4; font-weight: 500; color: var(--text-2); }
    [data-couloir="en-cours"] .vp-titre, [data-couloir="a-recetter"] .vp-titre { font-weight: 600; color: var(--text); }
    .vp-etat { grid-column: 2; min-height: 1.4em; font-size: 12px; font-weight: 400; color: var(--text-3); } .vp-preuve { font-weight: 500; color: var(--text-2); }
    .vp-carte[aria-current="true"], .vp-rangee[aria-current="true"] { background: var(--surface-hover); box-shadow: none; border-color: var(--text-3); }
    .vp-listes { display: flex; flex-direction: column; gap: var(--sp-8); }
    .vp-details { border-radius: var(--r-card); background: var(--surface); } .vp-details summary { display: flex; align-items: center; justify-content: space-between; gap: var(--sp-12); min-height: 44px; padding: 0 var(--inset-card); cursor: pointer; font-size: 13px; font-weight: 500; }
    .vp-rangee { display: flex; align-items: center; justify-content: space-between; gap: var(--sp-12); width: 100%; min-height: 44px; padding: var(--inset-row); border: 1.5px solid transparent; border-radius: 0; background: none; font-size: 13px; color: var(--text); }
    .vp-rangees li + li { border-top: 1px solid var(--hair); } .vp-r-t { min-width: 0; overflow-wrap: anywhere; } .vp-r-d { font-family: var(--mono); font-size: 12px; color: var(--text-3); }
    @media (hover: hover) { .vp-carte, .vp-rangee { transition: background-color 150ms var(--ease), box-shadow 150ms var(--ease); } .vp-carte:hover:not([aria-current="true"]) { background: var(--surface-hover); box-shadow: var(--shadow-lift); } }
    @media (max-width: 999px) { .vp-couloirs { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
    @media (max-width: 700px) { .vp-couloirs { grid-template-columns: minmax(0, 1fr); } .vp-barre, .vp-barre .vf-bar { width: 100%; } .vp-barre .vf-bar { flex: 1; } }
    @media (pointer: coarse), (max-width: 700px) { .vp-bascule button { min-height: 44px; } }
    @media (prefers-reduced-motion: reduce) { .vp-carte, .vp-rangee { transition: none; } }
  `;
  document.head.appendChild(style);

  const outils = () => `<div class="vp-bascule" role="group" aria-label="Forme de l'affichage">${FORMES.map((f) =>
    `<button type="button" data-forme="${f}" aria-pressed="${f === forme}">${LIBELLES[f]}</button>`).join('')}</div>`;
  const classes = () => { document.body.classList.toggle('vf-forme-couloirs', affichee()); document.body.classList.toggle('vf-forme-graphe', !affichee()); };
  const marquerBascule = () => document.querySelectorAll('[data-forme]').forEach((b) => b.setAttribute('aria-pressed', String(b.dataset.forme === forme)));
  const selectionnee = () => (typeof state.selected === 'string' ? state.selected : null);
  const itinerante = () => { const a = section && section.querySelector('.vp-carte[tabindex="0"]'); return a ? a.dataset.id : null; };
  const carteDe = (id) => (section ? section.querySelector(`.vp-carte[data-id="${CSS.escape(id)}"]`) : null);

  const dessiner = () => {
    if (!vivant) return;
    const modele = { blocs: M.blocs(G), historique: M.historique(G), listes: M.listes(G) };
    const sel = selectionnee(), toutes = modele.blocs.flatMap((b) => Object.values(b.couloirs).flat()).map((c) => c.id);
    corps.innerHTML = R.vue(modele, { sel, iti: toutes.includes(sel) ? sel : itinerante() || toutes[0] || null, ouverts });
    if (!corps.querySelector('.vp-carte[tabindex="0"]')) { const c = corps.querySelector('.vp-carte'); if (c) c.setAttribute('tabindex', '0'); }
  };
  const surRender = () => {
    if (!vivant) return;
    if (forme === 'couloirs' && state.container !== 'root' && conteneurJalon()) { SC.go('root', { select: state.selected, push: false }); return; } // P80-C76-3
    classes(); dessiner();
  };
  const basculer = (nom) => {
    if (!FORMES.includes(nom) || nom === forme) return false;
    forme = nom; marquerBascule(); classes();
    try { const u = new URL(location.href); u.searchParams.set('vue', nom); history.replaceState(history.state, '', u.pathname + u.search + u.hash); } catch (e) { void e; }
    return true;
  };

  const pose = [];
  const ecoute = (cible, type, fn, capture) => { cible.addEventListener(type, fn, capture); pose.push(() => cible.removeEventListener(type, fn, capture)); };
  const init = () => {
    vivant = true;
    section = document.createElement('section'); section.className = 'vf-projet'; section.setAttribute('aria-labelledby', 'vf-projet-titre');
    section.innerHTML = `<div class="vp-tete"><h1 id="vf-projet-titre" tabindex="-1">Projet</h1>${outils()}</div><div class="vp-status" role="status" aria-live="polite" aria-atomic="true"></div><div class="vp-corps"></div>`;
    corps = section.querySelector('.vp-corps'); statut = section.querySelector('.vp-status'); void statut;
    corps.innerHTML = R.etatVue('Chargement du projet');
    flottant = document.createElement('div'); flottant.id = 'vf-projet-flottant'; flottant.innerHTML = outils();
    stage.append(section, flottant); classes();
    ecoute(document, 'click', (ev) => { const b = ev.target.closest && ev.target.closest('[data-forme]'); if (b) basculer(b.dataset.forme); });
    ecoute(section, 'click', (ev) => { const c = ev.target.closest && ev.target.closest('[data-id]'); if (c && section.contains(c)) SC.select(c.dataset.id); });
    ecoute(section, 'dblclick', (ev) => { const c = ev.target.closest && ev.target.closest('.vp-carte'); if (c) SC.go(c.dataset.id); });
    ecoute(section, 'toggle', (ev) => { const d = ev.target; if (d.dataset && d.dataset.cle) { if (d.open) ouverts.add(d.dataset.cle); else ouverts.delete(d.dataset.cle); } }, true);
    SC.on('render', surRender); SC.on('panel', () => { if (vivant) section.querySelectorAll('[data-id]').forEach((e) => { if (e.dataset.id === selectionnee()) e.setAttribute('aria-current', 'true'); else e.removeAttribute('aria-current'); }); });
    surRender();
    return () => { vivant = false; pose.splice(0).forEach((f) => f()); section.remove(); flottant.remove(); };
  };
  window.VF_PROJET = Object.freeze({ formes: () => FORMES.slice(), forme: () => forme, basculer, carteDe });
  classes();
  const C = window.VF_COQUILLE;
  const demarrer = () => (vivant ? undefined : init());
  if (C && typeof C.surOnglet === 'function') C.surOnglet(init); // P80-D-42 : la coquille, sinon `ready` (ou le premier rendu, s'il l'a devancé)
  else if (state.layout) demarrer(); else { SC.on('ready', demarrer); SC.on('render', demarrer); }
})();
