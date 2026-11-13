// VibeFlow (80-04) : clavier des couloirs de Projet (FORM-05, P80-D-51, 80-UI-SPEC § 5) — un seul arrêt de tabulation par collection (un bloc de
// jalon, une liste), flèches par position
// à l'écran, Origine/Fin, Entrée plonge, Espace sélectionne, Échap désélectionne puis remonte, sélection qui suit le focus en panneau latéral. Ne
// parle au viewer que par window.Floorplan.
// Exposé : window.__vfProjetClavier { appliquer, poser, ramener, ordre, repli, memoire } lu à l'exécution par 41-vf-projet-vue.js (qui redessine et
// restitue le focus).
(() => {
  const SC = window.Floorplan;
  if (!SC || !SC.graph.meta || SC.graph.meta.vfTab !== 'project') return;
  const { state } = SC;
  // panneau latéral ; sinon feuille de détail (80-UI-SPEC § 0, point 6)
  const lateral = () => matchMedia('(min-width: 1000px) and (not (pointer: coarse))').matches;
  const section = () => document.querySelector('section.vf-projet');
  const memoire = new Map(); // collection (jalon ou liste) -> identifiant de l'arrêt itinérant
  let programme = false; // restitution programmée du focus : ne change jamais la sélection
  const cle = (el) => { const c = el.closest('.vp-jalon, .vp-details'); return c ? c.dataset.jalon || 'liste:' + c.dataset.cle : ''; };
  const membres = (el) => (el.classList.contains('vp-carte')
    // ordre de lecture, couloir par couloir
    ? [...el.closest('.vp-jalon').querySelectorAll('.vp-couloir .vp-carte')] : [...el.closest('.vp-details').querySelectorAll('.vp-rangee')]);
  const ordre = (el) => membres(el).map((e) => e.dataset.id);
  // seuls une carte et une rangée itinèrent : le h1 du repli, hors de toute collection, ne lève rien
  const itinerer = (el) => { if (!el.matches('.vp-carte, .vp-rangee')) return; for (const e of membres(el))e.setAttribute('tabindex', e === el ? '0' : '-1'); memoire.set(cle(el), el.dataset.id); };
  const appliquer = (racine) => { // après un rendu : l'arrêt mémorisé de chaque collection, sinon son premier élément
    for (const c of racine.querySelectorAll('.vp-jalon, .vp-details')) {
      const liste = [...c.querySelectorAll(c.classList.contains('vp-jalon') ? '.vp-couloir .vp-carte' : '.vp-rangee')];
      const el = liste.find((e) => e.dataset.id === memoire.get(c.dataset.jalon || 'liste:' + c.dataset.cle)) || liste[0];
      if (el) for (const e of liste) e.setAttribute('tabindex', e === el ? '0' : '-1');
    }
  };
  // instantané, jamais lissé
  const ramener = (el) => { if (el && el.scrollIntoView) el.scrollIntoView({ inline: 'nearest', block: 'nearest', behavior: 'auto' }); };
  const poser = (el, { suivre = false, defiler = true } = {}) => { // defiler: false : une restitution au redessin ne fait jamais défiler la vue
    programme = true;
    try { el.focus({ preventScroll: true }); itinerer(el); if (defiler) ramener(el); } finally { programme = false; }
    if (suivre && lateral() && el.classList.contains('vp-carte') && state.selected !== el.dataset.id) SC.select(el.dataset.id);
  };
  const repli = (opts) => { // l'élément sélectionné, sinon le h1 (tabindex=-1), jamais body
    const s = section(), id = typeof state.selected === 'string' ? state.selected : null;
    const q = id ? `.vp-carte[data-id="${CSS.escape(id)}"], .vp-rangee[data-id="${CSS.escape(id)}"]` : null;
    const el = (q && s && s.querySelector(q)) || (s && s.querySelector('#vf-projet-titre'));
    if (el) poser(el, opts);
    return el;
  };

  // position à l'écran : lignes et colonnes lues sur les rectangles des couloirs (4 côte à côte, 2 x 2, empilés : la même règle)
  const voisin = (el, dir) => {
    const bloc = el.closest('.vp-jalon'), cs = [...bloc.querySelectorAll('.vp-couloir')].map((c) => ({ c,
      cartes: [...c.querySelectorAll('.vp-carte')], r: c.getBoundingClientRect() }));
    const rang = (k) => [...new Set(cs.map((x) => Math.round(x.r[k])))].sort((a, b) => a - b);
    const tops = rang('top'), lefts = rang('left');
    for (const x of cs) { x.ligne = tops.indexOf(Math.round(x.r.top)); x.col = lefts.indexOf(Math.round(x.r.left)); }
    const cur = cs.find((x) => x.cartes.includes(el)), i = cur.cartes.indexOf(el), tous = cs.flatMap((x) => x.cartes);
    if (dir === 'debut') return tous[0];
    if (dir === 'fin') return tous[tous.length - 1];
    const proche = (liste) => liste.sort((a, b) => Math.abs(a.col - cur.col) - Math.abs(b.col - cur.col))[0];
    if (dir === 'haut' || dir === 'bas') {
      const s = dir === 'bas' ? 1 : -1;
      if (cur.cartes[i + s]) return cur.cartes[i + s];
      const cand = cs.filter((x) => x.cartes.length && (x.ligne - cur.ligne) * s > 0); // couloirs non vides sur une ligne d'écran plus basse (ou plus haute)
      if (!cand.length) return null;
      const d = Math.min(...cand.map((x) => (x.ligne - cur.ligne) * s)), cible = proche(cand.filter((x) => (x.ligne - cur.ligne) * s === d));
      return s > 0 ? cible.cartes[0] : cible.cartes[cible.cartes.length - 1];
    }
    const s = dir === 'droite' ? 1 : -1, cand = cs.filter((x) => x.cartes.length && x.ligne === cur.ligne && (x.col - cur.col) * s > 0);
    if (!cand.length) return null;
    const cible = proche(cand.filter((x) => (x.col - cur.col) * s === Math.min(...cand.map((y) => (y.col - cur.col) * s))));
    return cible.cartes[Math.min(i, cible.cartes.length - 1)]; // même rang, plafonné à la dernière carte
  };
  const voisinRangee = (el, dir) => {
    const l = membres(el), i = l.indexOf(el);
    return dir === 'debut' ? l[0] : dir === 'fin' ? l[l.length - 1] : dir === 'haut' ? l[i - 1] || null : dir === 'bas' ? l[i + 1] || null : null;
  };

  const TOUCHES = { ArrowLeft: 'gauche', ArrowRight: 'droite', ArrowUp: 'haut', ArrowDown: 'bas', Home: 'debut', End: 'fin' };
  const surTouche = (ev) => {
    if (ev.altKey || ev.ctrlKey || ev.metaKey) return;
    const el = ev.target.closest && ev.target.closest('.vp-carte, .vp-rangee'), s = section();
    if (!el || !s || !s.contains(el)) return;
    const carte = el.classList.contains('vp-carte');
    // plonge (l'Entrée du moteur ouvrirait state.selected)
    if (ev.key === 'Enter') { ev.preventDefault(); ev.stopPropagation(); if (carte) SC.go(el.dataset.id); else SC.open(el.dataset.id); return; }
    if (ev.key === ' ') { ev.preventDefault(); ev.stopPropagation(); SC.select(el.dataset.id); return; }
    if (ev.key === 'Escape') {
      const P = window.VF_SURCOUCHES;
      if ((P && P.couverte && P.couverte(s)) || (matchMedia('(max-width: 999px), (pointer: coarse)').matches
        && !document.body.classList.contains('no-panel'))) return; // une surcouche ou la feuille d'abord
      ev.preventDefault(); ev.stopPropagation();
      if (state.selected) SC.select(null); else SC.up(); // désélectionne (le focus reste), puis remonte ; sans effet à la racine
      return;
    }
    const dir = TOUCHES[ev.key];
    if (!dir) return;
    ev.preventDefault();
    const cible = carte ? voisin(el, dir) : voisinRangee(el, dir);
    if (cible && cible !== el) poser(cible, { suivre: true });
  };
  const surFocus = (ev) => {
    const el = ev.target.closest && ev.target.closest('.vp-carte, .vp-rangee'), s = section();
    if (!el || !s || !s.contains(el)) return;
    itinerer(el);
    // la sélection suit le focus de l'utilisateur
    if (!programme && lateral() && el.classList.contains('vp-carte') && state.selected !== el.dataset.id) SC.select(el.dataset.id);
  };
  const pose = [];
  const ecoute = (cible, type, fn, capture) => { cible.addEventListener(type, fn, capture); pose.push(() => cible.removeEventListener(type, fn, capture)); };
  let vivant = false;
  const init = () => {
    vivant = true;
    ecoute(document, 'keydown', surTouche); ecoute(document, 'keyup', (ev) => { if (ev.key === ' ' && ev.target.closest
      && ev.target.closest('section.vf-projet')) ev.preventDefault(); });
    ecoute(document, 'focusin', surFocus);
    return () => { vivant = false; pose.splice(0).forEach((f) => f()); };
  };
  window.__vfProjetClavier = Object.freeze({ appliquer, poser, ramener, ordre, repli, memoire, cle });
  const C = window.VF_COQUILLE, demarrer = () => (vivant ? undefined : init());
  if (C && typeof C.surOnglet === 'function') C.surOnglet(init, { cle: '41-vf-projet-clavier.js' }); // la coquille (A51), sinon `ready`
  else if (state.layout) demarrer(); else { SC.on('ready', demarrer); SC.on('render', demarrer); }
})();
