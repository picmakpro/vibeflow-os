// VibeFlow (80-07) : forme Liste de Projet à la racine (FORM-09, P80-D-05, P80-D-51, 80-UI-SPEC § 2.2) — un table par bloc de jalon, rangées triables
// (Phase, État, Plans, Exigences), tri stable non mémorisé, rangée = bouton. Chargé AVANT modele, rendu et vue : tout se lit à l'appel.
// Clavier commun des rangées `.vp-ligne` (racine ET plans d'une phase, 41-vf-projet-phase.js) : ↑/↓, Origine, Fin, Entrée plonge, Espace sélectionne.
// Exposé : window.__vfProjetListe { rendre, appliquer, poser, repli, ordre, cle, tri, trier } et, dans window.__vfProjetRegistre, la forme « liste:racine ».
(() => {
  const SC = window.Floorplan;
  if (!SC || !SC.graph.meta || SC.graph.meta.vfTab !== 'project') return;
  const { state } = SC, h = SC.h, sain = (id) => String(id).replace(/[^\w-]/g, '_');
  const registre = (window.__vfProjetRegistre = window.__vfProjetRegistre || {});
  const t = window.__vfFrT;
  const COLS = [['phase', t('Phase@project')], ['etat', t('Status')], ['plans', t('Plans@project')], ['exigences', t('Requirements')]];
  const RANG_ETAT = { 'en-cours': 0, 'a-recetter': 1, 'a-faire': 2, fait: 3 };
  let tri = { col: 'etat', sens: 1 }; // État croissant, puis numéro (non mémorisé)
  const P = () => window.VF_PROJET, M = () => window.__vfProjetModele, R = () => window.__vfProjetRendu;
  const noeud = (id) => (SC.graph.nodes || []).find((n) => 'n:' + n.id === id) || {};

  // donnée absente n'est pas zéro : rang 0 = fraction connue, 1 = total nul (pas de plan, aucune exigence), 2 = champ absent
  const fraction = (c) => (!c ? { rang: 2, f: 0 } : c.total > 0 ? { rang: 0, f: c.faits / c.total } : { rang: 1, f: 0 });
  const donnees = (c, i) => { const n = noeud(c.id);
    return { c, i, num: parseFloat(c.num), plans: n.avancement && n.avancement.plans, ex: n.exigences }; };
  const comparer = (a, b) => {
    const s = tri.sens; let d = 0;
    if (tri.col === 'etat') d = s * (RANG_ETAT[a.c.etat] - RANG_ETAT[b.c.etat]);
    else if (tri.col === 'phase') d = s * (a.num - b.num || 0);
    else { const x = fraction(tri.col === 'plans' ? a.plans : a.ex), y = fraction(tri.col === 'plans' ? b.plans : b.ex); d = x.rang - y.rang ||
      s * (x.f - y.f); }
    return d || (a.num - b.num) || (a.i - b.i); // égalité : numéro, puis ordre d'origine (tri stable)
  };
  const nombres = (c, unite) => (!c ? `<span class="vp-sr">donnée non disponible</span>` : c.total > 0
    ? `<span class="vp-nb">${c.faits}</span><span class="vp-u"> ${c.faits > 1 ? unite : unite.replace(/s$/, '')}</span>`
      + ` sur <span class="vp-nb">${c.total}</span>` : unite === 'plans' ?
      t('no plan') : `${t('no@requirements')}<span class="vp-u"> ${t('requirement')}</span>`);
  const cellule = (d, st, mot) => {
    const c = d.c, cache = c.coupe ? ` aria-describedby="vp-d-${sain(c.id)}"` : '', cur = state.selected === c.id ? ' aria-current="true"' : '';
    return `<tr role="row"><td role="cell"><button type="button" class="vp-ligne" data-id="${h(c.id)}" tabindex="-1" aria-label="${h(c.nom)}"${cache}${cur}>`
      + `<span class="vp-num">${h(c.num)}</span><span class="vp-titre">${h(c.titre)}</span></button>`
      + (c.coupe ? `<span id="vp-d-${sain(c.id)}" hidden>${h(c.complet)}</span>` : '') + '</td>'
      + `<td role="cell"><span class="vst vst-${h(st)}">${h(mot)}</span></td><td role="cell">${nombres(d.plans, 'plans')}</td>`
      + `<td role="cell">${nombres(d.ex, 'exigences')}</td></tr>`;
  };
  const entetes = () => COLS.map(([col, lib]) => { const actif = tri.col === col;
    const sens = tri.sens > 0 ? 'ascending' : 'descending';
    return `<th role="columnheader" scope="col" aria-sort="${actif ? sens : 'none'}"><button type="button" data-tri="${col}">`
      + `<span class="vp-sr">Trier par </span>${lib}`
      + (actif ? `<span class="vp-chev ${tri.sens > 0 ? 'haut' : 'bas'}" aria-hidden="true">${SC.iconI('drill')}</span>` : '')
      + '</button></th>'; }).join('');
  const table = (b) => {
    const cartes = Object.values(b.couloirs).flat(), defs = new Map(M().COULOIRS.map((c) => [c[0], c]));
    const lignes = cartes.map(donnees).sort(comparer).map((d) => { const def = defs.get(d.c.etat); return cellule(d, def[2], def[1]); }).join('');
    return `<table class="vp-table" role="table" aria-labelledby="vp-j-${sain(b.jalon)}" data-coll="t:${h(b.jalon)}">`
      + `<thead role="rowgroup"><tr role="row">${entetes()}</tr></thead>`
      + `<tbody role="rowgroup">${lignes}</tbody></table>`;
  };
  const rendre = (m, o) => {
    if (!m.blocs.length) return R().vue(m, o);
    const blocs = m.blocs.map((b) => { const bloc = R().blocJalon(b, o), i = bloc.indexOf('<div class="vp-couloirs">');
      return i < 0 ? bloc : bloc.slice(0, i) + table(b) + '</section>'; }).join('');
    return blocs + `<div class="vp-listes">${R().historique(m.historique, o)}${R().listes(m.listes, o)}</div>`;
  };

  // ---- rangées `.vp-ligne` : un arrêt de tabulation par collection (table, liste de plans), clavier, sélection qui suit le focus ----
  const memoire = new Map();
  let programme = false;
  const racine = () => document.querySelector('section.vf-projet');
  const lateral = () => matchMedia('(min-width: 1000px) and (not (pointer: coarse))').matches;
  const cle = (el) => { const c = el.closest('[data-coll]'); return c ? c.dataset.coll : ''; };
  const membres = (el) => [...el.closest('[data-coll]').querySelectorAll('.vp-ligne')];
  const ordre = (el) => membres(el).map((e) => e.dataset.id);
  const itinerer = (el) => { for (const e of membres(el)) e.setAttribute('tabindex', e === el ? '0' : '-1'); memoire.set(cle(el), el.dataset.id); };
  const appliquer = (corps) => { for (const c of corps.querySelectorAll('[data-coll]')) { const l = [...c.querySelectorAll('.vp-ligne')];
    const el = l.find((e) => e.dataset.id === memoire.get(c.dataset.coll)) || l[0]; if (el) for (const e of l) e.setAttribute('tabindex', e === el ? '0' :
      '-1'); } };
  const poser = (el, { suivre = false, defiler = true } = {}) => {
    programme = true;
    try { el.focus({ preventScroll: true }); itinerer(el); if (defiler) el.scrollIntoView({ inline: 'nearest', block: 'nearest',
      behavior: 'auto' }); } finally { programme = false; }
    if (suivre && lateral() && state.selected !== el.dataset.id) SC.select(el.dataset.id);
  };
  const repli = (opts) => { // l'élément sélectionné rendu, sinon le h1 (tabindex=-1), jamais body
    const s = racine(), id = typeof state.selected === 'string' ? state.selected : null;
    const el = (id && s && s.querySelector(`.vp-ligne[data-id="${CSS.escape(id)}"]`)) || (s && s.querySelector('#vf-projet-titre'));
    if (el) poser(el, opts);
    return el;
  };
  const trier = (col) => {
    tri = { col, sens: tri.col === col ? -tri.sens : 1 };
    const lib = COLS.find((c) => c[0] === col)[1];
    if (P()) { P().redessiner(); P().annoncer(`Trié par ${lib}, ${tri.sens > 0 ? 'croissant' : 'décroissant'}`); }
  };
  const TOUCHES = { ArrowUp: -1, ArrowDown: 1 };
  const surTouche = (ev) => {
    if (ev.altKey || ev.ctrlKey || ev.metaKey) return;
    const s = racine(), cible = ev.target, el = cible.closest && cible.closest('.vp-ligne');
    if (!s || !cible.closest || !s.contains(cible)) return;
    if (ev.key === 'Escape' && (el || cible.id === 'vf-projet-titre')) {
      const S = window.VF_SURCOUCHES;
      if ((S && S.couverte && S.couverte(s)) || (matchMedia('(max-width: 999px), (pointer: coarse)').matches &&
        !document.body.classList.contains('no-panel'))) return;
      ev.preventDefault(); ev.stopPropagation();
      if (state.selected) SC.select(null); else SC.up(); // désélectionne (le focus reste), puis remonte ; sans effet à la racine
      return;
    }
    if (!el) return;
    if (ev.key === 'Enter') { // plonge dans une phase ; sur un plan, sélectionne et ouvre le panneau s'il est fermé
      ev.preventDefault(); ev.stopPropagation();
      if (el.dataset.id.startsWith('n:')) SC.go(el.dataset.id);
      else { SC.select(el.dataset.id); if (document.body.classList.contains('no-panel')) { const b = document.getElementById('btn-panel'); if (b) b.click(); } }
      return;
    }
    if (ev.key === ' ') { ev.preventDefault(); ev.stopPropagation(); SC.select(el.dataset.id); return; }
    const l = membres(el), i = l.indexOf(el);
    const vers = ev.key === 'Home' ? l[0] : ev.key === 'End' ? l[l.length - 1] : TOUCHES[ev.key] ? l[i + TOUCHES[ev.key]] : null;
    if (!(ev.key in TOUCHES) && ev.key !== 'Home' && ev.key !== 'End') return;
    ev.preventDefault();
    if (vers && vers !== el) poser(vers, { suivre: true });
  };
  const surFocus = (ev) => {
    const el = ev.target.closest && ev.target.closest('.vp-ligne'), s = racine();
    if (!el || !s || !s.contains(el)) return;
    itinerer(el);
    if (!programme && lateral() && state.selected !== el.dataset.id) SC.select(el.dataset.id); // au bureau la sélection suit le focus
  };

  const style = `
    .vp-table { width: 100%; border-collapse: separate; border-spacing: 0; background: var(--surface); border-radius: var(--r-card);
      box-shadow: var(--shadow-card); }
    .vp-table th { padding: var(--sp-8) var(--sp-12); text-align: left; font-size: 12px; font-weight: 500; color: var(--text-3);
      border-bottom: 1px solid var(--hair); }
    .vp-table th button { min-height: 32px; padding: 0; border: 0; background: none; font: inherit; color: inherit; cursor: pointer; }
    .vp-chev { display: inline-block; margin-inline-start: var(--sp-4); } .vp-chev svg { width: 12px; height: 12px; vertical-align: -2px; }
    .vp-chev.haut { transform: rotate(-90deg); } .vp-chev.bas { transform: rotate(90deg); }
    .vp-table th[aria-sort="ascending"] button, .vp-table th[aria-sort="descending"] button { color: var(--text); font-weight: 600; }
    .vp-table th button:focus-visible { outline: 2px solid var(--ring); outline-offset: var(--sp-2); }
    .vp-table td { padding: var(--inset-row); font-size: 13px; color: var(--text-2); border-top: 1px solid var(--hair); vertical-align: baseline; }
    .vp-table tbody tr { position: relative; } .vp-table tbody tr:first-child td { border-top: 0; }
    .vp-table td:first-child { width: 42%; }
    .vp-ligne { display: flex; gap: var(--sp-8); align-items: baseline; width: 100%; padding: 0; border: 0; background: none; font: inherit;
      color: inherit; text-align: left;
      cursor: pointer; } .vp-ligne::after { content: ""; position: absolute; inset: 0; } .vp-ligne:focus-visible { outline: none; }
    /* sélection (1,5 px, --text-3) et focus (2 px, --ring) cernent la rangée entière : filets posés sur les cellules */
    .vp-table tbody tr:has(.vp-ligne[aria-current="true"]) td { background: var(--surface-hover); --vp-c: var(--text-3); --vp-e: 1.5px; }
    .vp-table tbody tr:has(.vp-ligne:focus-visible) td { --vp-c: var(--ring); --vp-e: 2px; }
    .vp-table tbody tr:has(.vp-ligne[aria-current="true"]) td, .vp-table tbody tr:has(.vp-ligne:focus-visible) td {
      box-shadow: inset 0 var(--vp-e) 0 var(--vp-c), inset 0 calc(-1 * var(--vp-e)) 0 var(--vp-c); }
    .vp-table tbody tr:has(.vp-ligne:focus-visible, .vp-ligne[aria-current="true"]) td:first-child { box-shadow: inset 0 var(--vp-e) 0 var(--vp-c),
      inset 0 calc(-1 * var(--vp-e)) 0 var(--vp-c), inset var(--vp-e) 0 0 var(--vp-c); }
    .vp-table tbody tr:has(.vp-ligne:focus-visible, .vp-ligne[aria-current="true"]) td:last-child { box-shadow: inset 0 var(--vp-e) 0 var(--vp-c),
      inset 0 calc(-1 * var(--vp-e)) 0 var(--vp-c), inset calc(-1 * var(--vp-e)) 0 0 var(--vp-c); }
    .vp-table .vp-titre { color: var(--text); } .vp-nb { font-family: var(--mono); font-size: 12.5px; } .vp-u { display: none; }
    .vp-sr { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }
    @media (hover: hover) { .vp-table tbody tr:hover td { background: var(--surface-hover); } }
    @media (pointer: coarse) { .vp-table th button, .vp-ligne { min-height: 44px; } }
    @media (max-width: 700px) {
      .vp-table, .vp-table tbody, .vp-table thead { display: block; } .vp-table thead tr { display: grid; grid-template-columns: 1fr 1fr; }
      .vp-table th { padding: 0 var(--sp-12); } .vp-table th button { min-height: 44px; width: 100%; }
      .vp-table tbody tr { display: grid; grid-template-columns: auto auto minmax(0,
        1fr); column-gap: var(--sp-12); align-items: baseline; border-top: 1px solid var(--hair); }
      .vp-table tbody tr:first-child { border-top: 0; } .vp-table td { border: 0; width: auto; padding: var(--sp-4) var(--sp-12); }
      .vp-table td:first-child { grid-column: 1 / -1; width: auto; padding-top: var(--sp-12); } .vp-ligne { min-height: 44px; align-items: center; }
      .vp-u { display: inline; } .vp-table td:nth-child(n+2) { padding-top: var(--sp-4); padding-bottom: var(--sp-12); }
    }`;
  const pose = [];
  let vivant = false;
  const init = () => {
    vivant = true;
    const st = document.createElement('style'); st.textContent = style; document.head.appendChild(st); pose.push(() => st.remove());
    const sur = (cible, type, fn) => { cible.addEventListener(type, fn); pose.push(() => cible.removeEventListener(type, fn)); };
    sur(document, 'keydown', surTouche); sur(document, 'focusin', surFocus);
    sur(document, 'keyup', (ev) => { if (ev.key === ' ' && ev.target.closest && ev.target.closest('.vp-ligne')) ev.preventDefault(); });
    sur(document, 'click', (ev) => { const b = ev.target.closest && ev.target.closest('section.vf-projet [data-tri]'); if (b) trier(b.dataset.tri); });
    return () => { vivant = false; pose.splice(0).forEach((f) => f()); };
  };
  registre['liste:racine'] = { rendre };
  window.__vfProjetListe = Object.freeze({ rendre, appliquer, poser, repli, ordre, cle, tri: () => ({ ...tri }), trier });
  const C = window.VF_COQUILLE, demarrer = () => (vivant ? undefined : init());
  if (C && typeof C.surOnglet === 'function') C.surOnglet(init, { cle: '41-vf-projet-liste.js' }); // la coquille (A51), sinon `ready`
  else if (state.layout) demarrer(); else { SC.on('ready', demarrer); SC.on('render', demarrer); }
})();
