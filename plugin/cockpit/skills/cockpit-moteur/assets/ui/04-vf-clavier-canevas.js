// VibeFlow (80-01) : clavier du canevas (FORM-01) — un seul arrêt de tabulation, flèches vers le voisin spatial, rôles et noms pour un lecteur d'écran.
// Ne parle au viewer que par window.Floorplan. Expose window.VF_CANEVAS (gelé), lu à l'exécution par les autres extensions, jamais au chargement.
(() => {
  const SC = window.Floorplan;
  if (!SC) return;
  const { graph: G, state } = SC;
  const t = window.__vfFrT;
  const svg = document.getElementById('svg'), stage = document.getElementById('stage'), vp = document.getElementById('viewport');
  if (!svg || !stage || !vp) return;
  const equipe = () => !!G.meta && G.meta.vfTab === 'equipe'; // Équipe : ses vues décident seules de leur clavier (EK18, jamais de rôle ni de tabindex ici)
  const feuille = () => matchMedia('(max-width: 999px), (pointer: coarse)').matches; // feuille de détail ; sinon panneau latéral
  const tour = () => !!(window.FloorplanTour && window.FloorplanTour.active && window.FloorplanTour.active());
  const style = document.createElement('style');
  style.textContent = `
    g.node:focus, #stage:focus, #stage:focus-visible { outline: none; }
    g.node:focus-visible .card { outline: 2px solid var(--ring); outline-offset: 2px; }
    g.node:focus-visible.sel .card, g.node:focus-visible.sel .card.external { box-shadow: var(--shadow-card); } /* anneau seul, ombre du repos */
    svg.dim g.node:focus-visible:not(.hl) .card > *, html.wk svg.dim g.node:focus-visible:not(.hl) foreignObject { opacity: 1; }
    #vf-canevas-live { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }
  `;
  document.head.appendChild(style);
  const live = document.createElement('div');
  live.id = 'vf-canevas-live'; live.setAttribute('aria-live', 'polite');
  document.body.appendChild(live);

  let conteneur = null, memo = null, focusDans = false, vivant = false;
  const ids = new WeakMap(); // g.node -> identifiant de carte
  const rect = (id) => (state.layout ? state.layout.children : []).find((c) => c.id === id);
  const cartes = () => (state.chipEls ? [...state.chipEls.keys()] : []).filter((id) => rect(id));
  const lecture = (a, b) => rect(a).y - rect(b).y || rect(a).x - rect(b).x; // ordre de lecture : haut puis gauche
  const ordre = () => cartes().sort(lecture);
  const centre = (c) => ({ x: c.x + c.width / 2, y: c.y + c.height / 2 });
  const niveau = () => { try { return SC.shownName(state.container); } catch (e) { return String(state.container); } };

  // voisin spatial, sur les positions de state.layout.children : ←/→ la couche voisine puis la carte la plus proche en y ; ↑/↓ la plus proche de la colonne
  const voisin = (id, dir) => {
    const tous = ordre(), moi = rect(id);
    if (!moi || !tous.length) return null;
    if (dir === 'debut') return tous[0];
    if (dir === 'fin') return tous[tous.length - 1];
    const c0 = centre(moi), autres = tous.filter((i) => i !== id).map((i) => ({ i, r: rect(i), c: centre(rect(i)) }));
    if (dir === 'gauche' || dir === 'droite') {
      const s = dir === 'droite' ? 1 : -1, cand = autres.filter((o) => (o.c.x - c0.x) * s > 1);
      if (!cand.length) return null;
      const dx = Math.min(...cand.map((o) => (o.c.x - c0.x) * s));
      return cand.filter((o) => (o.c.x - c0.x) * s <= dx + 40).sort((a, b) => Math.abs(a.c.y - c0.y) - Math.abs(b.c.y - c0.y))[0].i;
    }
    const s = dir === 'bas' ? 1 : -1;
    const cand = autres.filter((o) => (o.c.y - c0.y) * s > 1 && o.r.x < moi.x + moi.width && o.r.x + o.r.width > moi.x);
    return cand.length ? cand.sort((a, b) => Math.abs(a.c.y - c0.y) - Math.abs(b.c.y - c0.y))[0].i : null;
  };

  // nom accessible : UNE fonction (la Phase 75 peut l'envelopper pour y ajouter un mot d'activité) ; du texte, jamais de HTML (T-80-01)
  const liens = (id) => {
    const l = new Set();
    for (const x of (state.edgeEls ? state.edgeEls.values() : [])) if (x.e.a === id || x.e.b === id) l.add(x.e.a === id ? x.e.b : x.e.a);
    return l.size;
  };
  const nomDeCarte = (id) => {
    const g = state.chipEls && state.chipEls.get(id), carte = g && g.querySelector('.card');
    if (!carte) return '';
    const txt = (q) => { const e = carte.querySelector(q); return e ? e.textContent.trim() : ''; };
    let titre = ''; try { titre = SC.shownName(id); } catch (e) { void e; }
    if (id.startsWith('x:')) { // carte connecteur : nom affiché de l'entité liée et direction, jamais l'identifiant interne
      const c = ((state.view && state.view.connectors) || []).find((x) => x.id === id);
      titre = `${c && c.side === 'in' ? t('From@connector') : t('To')} ${txt('.lbl')}`;
    }
    const mot = txt('.vst') || ((carte.className.match(/\bst-([\w-]+)/) || [])[1] || ''); // mot d'état : la pastille de la carte rendue, à défaut son statut
    const n = liens(id);
    return [titre || txt('.title'), mot, txt('.foot .meta'), n ? `reliée à ${n} carte${n > 1 ? 's' : ''}` : 'aucune liaison'].filter(Boolean).join(', ');
  };

  const itinerante = (g, tous) => { for (const o of tous) o.setAttribute('tabindex', o === g ? '0' : '-1'); };
  const poser = (liste, cible) => {
    const tous = liste.map((id) => state.chipEls.get(id));
    svg.setAttribute('role', 'listbox');
    svg.setAttribute('aria-label', t('Map: {}, {}', niveau(), t('{} card', liste.length)));
    liste.forEach((id, i) => {
      const g = state.chipEls.get(id);
      ids.set(g, id);
      g.setAttribute('role', 'option'); g.setAttribute('aria-label', nomDeCarte(id));
      g.setAttribute('aria-posinset', String(i + 1)); g.setAttribute('aria-setsize', String(liste.length));
    });
    itinerante(state.chipEls.get(cible), tous);
    svg.querySelectorAll('.cols, .edges').forEach((e) => e.setAttribute('aria-hidden', 'true')); // fond, arêtes et ports : décor
    // Chrome ne rend le rôle option d'un g que si la listbox en est le propriétaire direct :
    // les deux g de structure (#viewport, calque des cartes) sont neutralisés
    vp.setAttribute('role', 'none'); tous[0].parentNode.setAttribute('role', 'none');
    surPanel();
  };
  const surPanel = () => { for (const [id, g] of state.chipEls || []) g.setAttribute('aria-selected', String(state.selected === id)); };

  const surRender = () => {
    if (!vivant || equipe()) return;
    const avant = conteneur, liste = ordre(); conteneur = state.container;
    const sel = typeof state.selected === 'string' && liste.includes(state.selected) ? state.selected : null;
    const cible = avant !== conteneur ? sel || (liste.includes(avant) ? avant : liste[0]) : liste.includes(memo) ? memo : sel || liste[0];
    memo = cible;
    live.textContent = liste.length ? '' : `Niveau ${niveau()}, aucune carte`;
    if (liste.length) poser(liste, cible);
    else { svg.removeAttribute('role'); svg.removeAttribute('aria-label'); } // niveau sans carte : plus de listbox, la région live parle
    if (!focusDans) return;
    const g = liste.length ? state.chipEls.get(cible) : stage; // jamais body : une carte, sinon #stage
    if (g && document.activeElement !== g) g.focus({ preventScroll: true });
  };

  // champ de lecture : la zone libre moins le tiroir Git ouvert et le bord de carte ; la carte focalisée y est ramenée sans changer le zoom
  const champDeLecture = () => {
    const a = SC.freeArea(), tir = document.getElementById('vf-git-tiroir'), coin = document.getElementById('vf-coin');
    let { x, y, w, h } = a;
    if (tir && !tir.hidden && tir.offsetWidth) { const d = tir.getBoundingClientRect().right + 16; w = Math.max(120, x + w - d); x = Math.max(x, d); }
    if (coin && !coin.hidden && coin.offsetWidth) {
      const r = coin.getBoundingClientRect();
      if (r.top > y + h / 2) h = Math.max(120, r.top - 16 - y); else if (r.left > x + w / 2) w = Math.max(120, r.left - 16 - x);
    }
    return { x, y, w, h };
  };
  const deplacer = ({ x = 0, y = 0 }) => { // seule écriture de translation de la couche VF : le zoom (state.t.k) ne bouge jamais
    if (!x && !y) return;
    const bulle = document.getElementById('tooltip'); if (bulle && !bulle.hidden) bulle.hidden = true; // comme applyTransform : la carte bouge sous la bulle
    const { k } = state.t, nx = state.t.x + x, ny = state.t.y + y;
    state.t = { k, x: nx, y: ny };
    vp.style.transform = `translate(${nx}px,${ny}px) scale(${k})`;
  };
  const amenerDansLeChamp = (id) => {
    const c = rect(id); if (!c) return;
    const a = champDeLecture(), { k, x, y } = state.t, l = c.x * k + x, ty = c.y * k + y, w = c.width * k, h = c.height * k;
    let dx = 0, dy = 0;
    if (l + w > a.x + a.w) dx = a.x + a.w - (l + w);
    if (l + dx < a.x) dx = a.x - l;
    if (ty + h > a.y + a.h) dy = a.y + a.h - (ty + h);
    if (ty + dy < a.y) dy = a.y - ty;
    deplacer({ x: dx, y: dy });
  };
  const focaliser = (id) => {
    const g = state.chipEls && state.chipEls.get(id); if (!g) return false;
    itinerante(g, [...state.chipEls.values()]); memo = id;
    g.focus({ preventScroll: true }); amenerDansLeChamp(id);
    return true;
  };
  const carteItinerante = () => {
    const g = [...(state.chipEls ? state.chipEls.values() : [])].find((o) => o.getAttribute('tabindex') === '0');
    return g ? ids.get(g) || null : null;
  };

  const TOUCHES = { ArrowLeft: 'gauche', ArrowRight: 'droite', ArrowUp: 'haut', ArrowDown: 'bas', Home: 'debut', End: 'fin' };
  const surTouche = (ev) => {
    if (!vivant || equipe() || ev.altKey || ev.ctrlKey || ev.metaKey) return;
    const g = ev.target.closest && ev.target.closest('g.node'), id = g && ids.get(g);
    if (!id) return;
    if (ev.key === 'Enter') { ev.preventDefault(); ev.stopPropagation(); SC.open(id); return; } // plonge ; l'Entrée du moteur ouvrirait state.selected
    if (ev.key === ' ') {
      ev.preventDefault(); ev.stopPropagation(); SC.select(id); // le moteur ouvre lui-même la feuille de détail (téléphone)
      return;
    }
    const dir = TOUCHES[ev.key];
    if (!dir || state.flow || tour()) return;
    ev.preventDefault();
    const cible = voisin(id, dir);
    if (cible && cible !== id && focaliser(cible) && !feuille()) SC.select(cible); // panneau latéral : la sélection suit le focus
  };
  // Échap depuis #stage (cible de repli) : même cran que depuis le canevas, si aucun cran supérieur n'est ouvert (un appui, un cran)
  const surEchap = (ev) => {
    if (!vivant || equipe() || ev.key !== 'Escape' || ev.target !== stage) return;
    const ouvert = (q, c) => { const e = document.querySelector(q); return !!e && (c ? e.classList.contains(c) : !e.hidden); };
    const S = window.VF_SURCOUCHES;
    if (ouvert('#ctxmenu') || ouvert('#flowmenu', 'open') || ouvert('#legend', 'open') || ouvert('#palette', 'open') || state.flow || tour()) return;
    if (matchMedia('(max-width: 700px)').matches && !document.body.classList.contains('no-panel')) return;
    if (S && typeof S.ouverte === 'function' && S.ouverte()) return;
    if (state.selected) SC.select(null); else SC.up();
  };

  const pose = [];
  const ecoute = (cible, type, fn, capture) => { cible.addEventListener(type, fn, capture); pose.push(() => cible.removeEventListener(type, fn, capture)); };
  const init = () => {
    if (equipe()) return undefined; // Équipe : rien n'est posé, aucun écouteur (EK18) ; même l'écouteur de focus du canevas y ferait de #svg un arrêt de Tab
    vivant = true;
    if (!stage.hasAttribute('tabindex')) stage.setAttribute('tabindex', '-1'); // cible de repli du focus (80-UI-SPEC § 5) ; absent du moteur
    svg.setAttribute('tabindex', '-1'); // Chrome fait du canevas un arrêt de Tab à lui seul : l'arrêt unique est la carte itinérante
    ecoute(svg, 'keydown', surTouche); ecoute(stage, 'keydown', surEchap);
    ecoute(svg, 'focusin', (ev) => { // le focus vient de nous poser, ou d'un clic : la carte focalisée devient l'arrêt unique
      focusDans = true; const g = ev.target.closest && ev.target.closest('g.node'), id = g && ids.get(g);
      if (id && state.chipEls) { itinerante(g, [...state.chipEls.values()]); memo = id; }
    });
    ecoute(svg, 'focusout', (ev) => { if (ev.relatedTarget && !svg.contains(ev.relatedTarget) && ev.relatedTarget !== stage) focusDans = false; });
    ecoute(document, 'pointerdown', (ev) => { if (!stage.contains(ev.target)) focusDans = false; }, true);
    ecoute(svg, 'click', (ev) => { // un clic met aussi le focus DOM sur la carte (sans anneau : :focus-visible) pour que les flèches marchent ensuite
      const g = ev.target.closest && ev.target.closest('g.node');
      if (g && ids.has(g) && document.activeElement !== g) g.focus({ preventScroll: true });
    }, true);
    SC.on('render', surRender); SC.on('panel', () => { if (vivant && !equipe()) surPanel(); });
    surRender();
    return () => { vivant = false; pose.splice(0).forEach((f) => f()); };
  };
  window.VF_CANEVAS = Object.freeze({ nomDeCarte, carteItinerante, focaliser, champDeLecture, amenerDansLeChamp, deplacer, voisin });
  const C = window.VF_COQUILLE;
  // `ready` peut être passé avant l'exécution de ce fichier (seconde page d'une session) : le moteur a alors déjà rendu
  const demarrer = () => (vivant ? undefined : init());
  if (C && typeof C.surOnglet === 'function') C.surOnglet(init); // P80-D-42 : la coquille, sinon `ready` (ou le premier rendu, s'il l'a devancé)
  else if (state.layout) demarrer(); else { SC.on('ready', demarrer); SC.on('render', demarrer); }
})();
