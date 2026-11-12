// VibeFlow (80-05) : repères de bord « N cartes par là » (FORM-10, P80-D-16, P80-D-32). Un bouton par bord du champ de lecture qui a des cartes ENTIÈREMENT
// hors champ : le compte, la place (au milieu du bord, à 8 px des surcouches) et le geste (amener la plus proche dans le champ,
// sans toucher au zoom ni à la sélection).
// Lit window.VF_CANEVAS (04-vf-clavier-canevas.js, chargé après) à l'exécution, jamais au chargement. Aucune animation, aucune requête.
(() => {
  const SC = window.Floorplan;
  if (!SC) return;
  const { graph: G, state } = SC;
  const svg = document.getElementById('svg'), stage = document.getElementById('stage'), vp = document.getElementById('viewport');
  if (!svg || !stage || !vp) return;
  const ORDRE = ['gauche', 'droite', 'haut', 'bas'], DIT = { gauche: 'à gauche', droite: 'à droite', haut: 'en haut', bas: 'en bas' };
  const OBSTACLES = ['#vf-coin', '#zoom', '#ask'];
  // pastille, puce et tiroir d'un module de bas de page : lus par leur nature (fixes, posés directement sous body), jamais par leur nom
  const flottants = () => [...document.body.children].filter((e) => e.matches('button, div[role="status"], section[role="region"]') && getComputedStyle(e).position === 'fixed');
  const equipe = () => !!G.meta && G.meta.vfTab === 'equipe';
  const feuille = () => matchMedia('(max-width: 999px), (pointer: coarse)').matches; // feuille de détail ; sinon panneau latéral
  // la forme affichée est le canevas : #svg a une boîte et n'est pas masqué (couloirs, liste : visibility hidden)
  const canevas = () => svg.getClientRects().length > 0 && getComputedStyle(svg).visibility !== 'hidden';
  const tour = () => !!(window.FloorplanTour && window.FloorplanTour.active && window.FloorplanTour.active());
  const style = document.createElement('style');
  style.textContent = `
    .vf-repere { position: absolute; z-index: 3; display: inline-flex; align-items: center; gap: var(--sp-4); height: 28px; padding: 0 var(--sp-12);
      border: 0; border-radius: 999px; color: var(--text-2); font: 500 12px/16px var(--sans); white-space: nowrap; cursor: pointer; }
    .vf-repere::after { content: ""; position: absolute; inset: -8px; } /* zone d'appui : 28 + 2 x 8 = 44 */
    .vf-repere:hover { color: var(--text); }
    .vf-repere:focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; }
    .vf-repere[data-bord=gauche] svg { transform: rotate(180deg); } .vf-repere[data-bord=haut] svg { transform: rotate(-90deg); }
    .vf-repere[data-bord=bas] svg { transform: rotate(90deg); }
    @media (pointer: coarse) { .vf-repere { height: 32px; } .vf-repere::after { inset: -6px; } } /* 32 + 2 x 6 = 44 */
  `;
  document.head.appendChild(style);

  const els = {}; // bord -> button
  let vivant = false, fruit = null; // fruit : la carte que le geste en cours vient d'amener (focus orphelin, ordre unique de la famille)
  const C = () => window.VF_CANEVAS;
  const rectDe = (e) => {
    if (!e || e.hidden || !e.getClientRects().length) return null;
    const r = e.getBoundingClientRect(); return r.width && r.height ? r : null;
  };
  const boite = (id) => { // boîte écran d'une carte du niveau
    const c = (state.layout ? state.layout.children : []).find((x) => x.id === id); if (!c) return null;
    const { k, x, y } = state.t, l = c.x * k + x, t = c.y * k + y;
    return { left: l, top: t, right: l + c.width * k, bottom: t + c.height * k };
  };
  const analyser = (F) => { // par bord : combien de cartes entièrement au-delà, et la plus proche
    const { k, x, y } = state.t, res = {};
    for (const b of ORDRE) res[b] = { n: 0, d: Infinity, id: null };
    for (const c of state.layout.children) {
      const l = c.x * k + x, t = c.y * k + y;
      const d = { gauche: F.x - (l + c.width * k), droite: l - (F.x + F.w), haut: F.y - (t + c.height * k), bas: t - (F.y + F.h) };
      for (const b of ORDRE) {
        if (d[b] >= 0) { res[b].n++; if (d[b] < res[b].d) { res[b].d = d[b]; res[b].id = c.id; } }
      }
    }
    return res;
  };
  const inter = (a, b, m) => a.x < b.right + m && a.x + a.w > b.left - m && a.y < b.bottom + m && a.y + a.h > b.top - m;
  // place au milieu du bord, rentrée de 8 ; poussée à 8 px d'une surcouche ;
  // null s'il n'y a pas de place ou si elle recouvrirait une carte sélectionnée ou focalisée
  const placer = (bord, F, w, h, obs, cartes) => {
    const milieuY = F.y + F.h / 2 - h / 2, milieuX = F.x + F.w / 2 - w / 2;
    const p = { gauche: { x: F.x + 8, y: milieuY }, droite: { x: F.x + F.w - 8 - w, y: milieuY },
      haut: { x: milieuX, y: F.y + 8 }, bas: { x: milieuX, y: F.y + F.h - 8 - h } }[bord];
    p.w = w; p.h = h;
    for (let i = 0; i < 4; i++) {
      const o = obs.find((r) => inter(p, r, 8)); if (!o) break;
      if (bord === 'gauche' || bord === 'droite') {
        const a = o.top - 8 - h, z = o.bottom + 8; p.y = Math.abs(a - p.y) <= Math.abs(z - p.y) ? a : z;
      } else {
        const a = o.left - 8 - w, z = o.right + 8; p.x = Math.abs(a - p.x) <= Math.abs(z - p.x) ? a : z;
      }
    }
    const dedans = p.x >= F.x && p.y >= F.y && p.x + w <= F.x + F.w && p.y + h <= F.y + F.h;
    return dedans && !obs.some((r) => inter(p, r, 8)) && !cartes.some((c) => inter(p, c, 0)) ? p : null;
  };
  const creer = (bord) => {
    const el = document.createElement('button');
    el.type = 'button'; el.className = 'vf-repere glass'; el.dataset.bord = bord; el.style.left = '0px'; el.style.top = '0px';
    const NS = 'http://www.w3.org/2000/svg', ic = document.createElementNS(NS, 'svg'), tr = document.createElementNS(NS, 'path');
    ic.setAttribute('class', 'i'); ic.setAttribute('viewBox', '0 0 24 24'); ic.setAttribute('aria-hidden', 'true'); tr.setAttribute('d', 'M9 6l6 6-6 6');
    ic.appendChild(tr); el.appendChild(ic); el.appendChild(document.createElement('span'));
    el.addEventListener('click', () => activer(bord)); els[bord] = el;
    // posé tout de suite (sa taille se mesure attachée), avant son premier suivant : aucun repère déjà posé, focalisé ou non, ne bouge
    const suivant = ORDRE.slice(ORDRE.indexOf(bord) + 1).map((b) => els[b]).find(Boolean);
    const avant = ORDRE.slice(0, ORDRE.indexOf(bord)).reverse().map((b) => els[b]).find(Boolean);
    if (suivant) suivant.before(el); else (avant || svg).after(el);
    return el;
  };
  const rendreLeFocus = (bord, gardes) => { // ordre unique : fruit du geste, voisin suivant puis précédent, carte itinérante, #stage ; jamais body
    const S = C(), i = ORDRE.indexOf(bord);
    if (fruit && S && S.focaliser(fruit)) return;
    const voisins = [...ORDRE.slice(i + 1), ...ORDRE.slice(0, i).reverse()].filter((b) => gardes.includes(b));
    if (voisins.length) { els[voisins[0]].focus({ preventScroll: true }); return; }
    const id = S && S.carteItinerante(), g = id && state.chipEls && state.chipEls.get(id);
    if (g) g.focus({ preventScroll: true }); else stage.focus({ preventScroll: true });
  };
  const maj = () => {
    if (!vivant) return;
    const S = C(), F = !equipe() && !tour() && S && state.layout && canevas() && !(feuille() && !document.body.classList.contains('no-panel'))
      ? S.champDeLecture() : null;
    const res = F ? analyser(F) : null, obs = F ? [...OBSTACLES.map((q) => document.querySelector(q)), ...flottants()].map(rectDe).filter(Boolean) : [], gardes = [];
    const g = document.activeElement && document.activeElement.closest ? document.activeElement.closest('g.node') : null;
    const vues = F ? [state.selected, ...[...(state.chipEls || [])].filter(([, x]) => x === g).map(([i]) => i)].map((i) => boite(i)).filter(Boolean) : [];
    for (const b of ORDRE) {
      const r = res && res[b]; if (!r || !r.n) continue;
      const el = els[b] || creer(b), n = r.n;
      el.lastChild.textContent = `${n} carte${n > 1 ? 's' : ''} par là`;
      el.setAttribute('aria-label', `${n} carte${n > 1 ? 's' : ''} hors champ ${DIT[b]}. Aller à la plus proche.`);
      const p = placer(b, F, el.offsetWidth, el.offsetHeight, obs, vues); if (!p) continue;
      el.style.left = `${Math.round(p.x)}px`; el.style.top = `${Math.round(p.y)}px`; el.dataset.cible = r.id; gardes.push(b);
      obs.push({ left: p.x, top: p.y, right: p.x + p.w, bottom: p.y + p.h }); // un repère posé est un obstacle pour les suivants
    }
    const perdus = ORDRE.filter((b) => els[b] && !gardes.includes(b)), perdu = perdus.find((b) => els[b] === document.activeElement);
    if (perdu) rendreLeFocus(perdu, gardes);
    for (const b of perdus) { els[b].remove(); delete els[b]; }
    let ref = svg; // dans l'ordre de Tab, juste après le canevas ; un nœud n'est déplacé que s'il est mal placé (le focus y survit)
    for (const b of ORDRE) if (els[b]) { if (ref.nextElementSibling !== els[b]) ref.after(els[b]); ref = els[b]; }
  };
  const activer = (bord) => { // amener la carte la plus proche dans le champ ; ni la sélection ni le zoom ne changent
    const S = C(), id = els[bord] && els[bord].dataset.cible; if (!S || !id) return;
    S.amenerDansLeChamp(id); fruit = id; maj(); fruit = null;
  };

  const pose = [];
  const init = () => {
    vivant = true;
    const observer = (O, cible, opts, fn) => { const o = new O(fn); o.observe(cible, opts); pose.push(() => o.disconnect()); };
    observer(MutationObserver, vp, { attributes: true, attributeFilter: ['style'] }, maj); // la transformation : aucun événement du moteur
    observer(MutationObserver, document.body, { attributes: true, attributeFilter: ['class'] }, maj);
    if (window.ResizeObserver) {
      for (const q of ['#ask', '#vf-coin']) { const e = document.querySelector(q); if (e) observer(ResizeObserver, e, undefined, maj); }
    }
    const sur = (cible, type, fn) => { cible.addEventListener(type, fn); pose.push(() => cible.removeEventListener(type, fn)); };
    sur(window, 'resize', maj); sur(window, 'vf-git:etat', maj);
    for (const e of ['transitionend', 'animationend']) { // le tiroir Git entre par une animation : on relit une fois posé
      sur(document, e, (ev) => { if (ev.target.closest && ev.target.closest('#vf-git-tiroir, #panel, #ask, #vf-coin')) maj(); });
    }
    SC.on('render', maj); SC.on('panel', maj);
    maj();
    return () => { vivant = false; pose.splice(0).forEach((f) => f()); for (const b of ORDRE) if (els[b]) { els[b].remove(); delete els[b]; } };
  };
  const C0 = window.VF_COQUILLE;
  const demarrer = () => (vivant ? undefined : init());
  if (C0 && typeof C0.surOnglet === 'function') C0.surOnglet(init); // P80-D-42 : la coquille, sinon `ready` (ou le premier rendu, s'il l'a devancé)
  else if (state.layout) demarrer(); else { SC.on('ready', demarrer); SC.on('render', demarrer); }
})();
