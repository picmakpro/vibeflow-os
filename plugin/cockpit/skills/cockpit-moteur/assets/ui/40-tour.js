// "Start here": a calm one-minute tour on first open. What the app is, its main parts, the outside
// services it leans on, then one real path traced end to end. Steps come from graph.tour (written by
// Claude in architecture.json) or are built from the map itself.
(() => {
  const SC = window.Floorplan;
  if (!SC) return;
  const G = SC.graph;
  const { h } = SC;
  const SEEN = 'tour-seen:' + (G.project?.name || G.meta?.rootName || 'map');

  const style = document.createElement('style');
  style.textContent = `
#tour { position: fixed; left: var(--edge); bottom: 76px; /* dérivé : 16 + 42 de zoom + 18 ; la visite se place en JS (repli) */ width: min(360px, calc(100vw - 2 * var(--edge))); max-height: calc(100vh - 170px); display: flex; flex-direction: column; padding: var(--inset-panel); border-radius: var(--r-panel); z-index: 6; animation: tourIn .4s var(--ease); }
#tour.right { left: auto; right: var(--edge); }
#tour .tb { flex: 1 1 auto; min-height: 0; overflow-y: auto; }
.tour-target { position: fixed; z-index: 5; pointer-events: none; } /* repère de cadrage : sa boîte sert au placement de la carte, rien n'est dessiné autour d'un bloc de la page (PU-G-087, pas de halo) */ .tour-target.lit { border-radius: 999px; background: rgba(var(--ink), .1); } /* un bouton de l'en-tête présenté : une surbrillance neutre, ni contour ni teinte (PU-G-089) */
#tour[hidden] { display: none; }
#tour .tk { font-size: 12px; color: var(--text-3); margin-bottom: var(--sp-4); display: flex; flex-wrap: wrap; gap: var(--sp-2) var(--sp-6); align-items: center; padding-right: var(--sp-24); }
#tour .tk span { white-space: nowrap; } /* « Étape 1 sur 4 » ne se coupe jamais en trois lignes (PU-G-090) */
#tour .tk i { width: 3px; height: 3px; border-radius: 50%; background: var(--text-4); }
#tour .tt { font-size: 16px; font-weight: 600; letter-spacing: -.01em; line-height: 1.35; padding-right: var(--sp-20); }
#tour .tn { color: var(--text-2); line-height: 1.55; margin-top: var(--sp-6); font-size: 13.5px; }
#tour .tip { color: var(--text-3); font-size: 12px; line-height: 1.5; margin-top: var(--sp-8); }
#tour .tf { flex: none; display: flex; flex-direction: column; gap: var(--sp-8); margin-top: var(--sp-12); }
#tour .acts { display: flex; align-items: center; gap: var(--sp-8); }
#tour .acts [data-x] { margin-right: auto; }
#tour .dots { display: flex; gap: var(--sp-4); }
#tour .dots i { width: 14px; height: 3px; border-radius: 2px; background: rgba(var(--ink), .12); transition: background .3s var(--ease); }
#tour .dots i.on { background: var(--on); }
#tour .tf .btn { height: 32px; }
#tour .tf .btn.icon { width: 32px; }
#tour .tx { position: absolute; top: var(--sp-12); right: var(--sp-12); width: 28px; height: 28px; }
@keyframes tourIn { from { opacity: 0; transform: translateY(8px) scale(.98); } }
`;
  document.head.appendChild(style);

  // ---------- steps ----------
  const clip = (s) => String(s || '').trim(); // the whole text: a step is never cut short (P70-D-02)
  const okSel = (q) => { if (typeof q !== 'string' || !q) return false; try { return !!document.querySelector(q); } catch { return false; } }; // a selector from the data may be invalid
  const isProject = () => G.meta?.vfTab === 'project';
  const listOf = (names) => names.length <= 1 ? names.join('') : `${names.slice(0, -1).join(', ')} and ${names[names.length - 1]}`;
  const tops = G.nodes.filter((n) => !n.parent && n.id !== 'unassigned');
  const bySize = (a, b) => (b.stats?.files || 0) - (a.stats?.files || 0);
  const screensOf = (id) => (G.screens || []).filter((s) => s.app === id).length;

  function flowStep() {
    if (isProject()) return null; // the Project tab has no path through the code to follow
    const f = (G.flows || []).find((x) => !x.custom) || (G.flows || [])[0];
    if (!f || !f.steps?.length) return null;
    const first = f.steps[0]?.ref;
    return { ref: first && SC.exists(first) ? first : 'root', flow: f.id, kicker: 'One real path', title: f.title, note: `${f.description ? clip(f.description) + ' ' : ''}Press Play to follow it through the code, one step at a time.` };
  }
  function autoSteps() {
    const p = G.project || {};
    const steps = isProject()
      ? [{ ref: 'root', kicker: 'The project', title: p.name || 'This project', note: clip(p.summary) || 'The work of this project: milestones, phases, backlog and releases.' }]
      : [{ ref: 'root', kicker: 'The codebase', title: p.name || 'This codebase', note: clip(p.summary) || 'A map of the main parts of this app and how they talk to each other.' }];
    const ui = tops.filter((n) => n.kind === 'ui').sort(bySize).slice(0, 2);
    for (const n of ui) {
      const k = screensOf(n.id);
      steps.push({ ref: 'n:' + n.id, kicker: 'What people use', title: n.label, note: clip(n.summary) + (k > 1 ? ` It has ${k} screens.` : '') });
    }
    let back = tops.filter((n) => n.kind === 'service' || n.kind === 'worker').sort(bySize);
    if (!back.length) back = tops.filter((n) => !['ui', 'external', 'test', 'script', 'config', 'infra', 'misc'].includes(n.kind)).sort(bySize);
    for (const n of back.slice(0, ui.length > 1 ? 1 : 2)) steps.push({ ref: 'n:' + n.id, kicker: 'Behind the scenes', title: n.label, note: clip(n.summary) });
    const data = tops.find((n) => n.kind === 'data' && !back.includes(n));
    if (data && steps.length < 5) steps.push({ ref: 'n:' + data.id, kicker: 'Where the data lives', title: data.label, note: clip(data.summary) });
    const ext = tops.filter((n) => n.kind === 'external');
    if (ext.length) {
      steps.push({
        ref: ext.length === 1 ? 'n:' + ext[0].id : 'root', lit: ext.length === 1 ? undefined : ext.slice(0, 6).map((n) => 'n:' + n.id), kicker: 'Outside services', title: ext.length === 1 ? ext[0].label : `${ext.length} outside services`,
        note: ext.length === 1 ? clip(ext[0].summary) : `It also relies on ${listOf(ext.slice(0, 6).map((n) => n.label))}${ext.length > 6 ? ` and ${ext.length - 6} more` : ''}. They sit at the edge of the map; the lines show which parts talk to them.`,
      });
    }
    return steps;
  }
  function buildSteps() {
    const own = (G.tour || []).filter((s) => s && (s.ref ? (s.ref === 'root' || SC.exists(s.ref)) : okSel(s.cible))).map((s) => ({ ref: s.ref || 'root', cible: typeof s.cible === 'string' ? s.cible : '', title: s.title || (s.ref && s.ref !== 'root' ? SC.info(s.ref).name : ''), note: s.note || (s.ref && s.ref !== 'root' ? SC.info(s.ref).desc : '') || '', kicker: '' }));
    const steps = own.length >= 2 ? own : autoSteps();
    const fl = flowStep();
    if (fl && !steps.some((s) => s.flow) && steps.length < 9) steps.push(fl);
    // every step aims at something: a card, or an element of the page (the title of the overview by default); a selector that matches nothing is dropped
    return steps.filter((s) => s.ref === 'root' || SC.exists(s.ref)).slice(0, 9)
      .map((s) => (s.cible && !okSel(s.cible) ? { ...s, cible: '' } : s))
      .map((s) => (s.ref === 'root' && !s.cible && !s.lit?.length ? { ...s, cible: '#context' } : s)); // une étape qui éclaire des cartes vise ces cartes, pas le titre (PU-G-089)
  }

  // ---------- card ----------
  const card = document.createElement('div');
  card.id = 'tour';
  card.className = 'glass';
  card.hidden = true;
  card.setAttribute('role', 'dialog');
  card.setAttribute('aria-label', 'Start here tour');
  document.body.appendChild(card);
  let steps = [], at = -1;
  const active = () => at >= 0;

  // ---------- aiming: every step points at something ----------
  let token = 0; // a step that was left before its move was due must not move the map
  const hit = (a, b) => Math.min(a.right, b.right) - Math.max(a.left, b.left) > 1 && Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top) > 1;
  // the outline is its own element laid over the target, found again by its selector: the page may rewrite the target's classes or replace it (the live layer does) without losing the outline
  let rings = [], ringTimer = 0; // le premier repère est la cible de l'étape ; les suivants sont des boutons de l'en-tête éclairés (.lit)
  function ringPlace() {
    for (const r of rings) { let t = null; try { t = document.querySelector(r.sel); } catch {} const b = t && t.getBoundingClientRect(); if (!b || !b.width || !b.height) { r.el.style.display = 'none'; continue; } Object.assign(r.el.style, { display: '', left: b.left + 'px', top: b.top + 'px', width: b.width + 'px', height: b.height + 'px' }); }
  }
  function ring(sel, lits = []) {
    clearInterval(ringTimer); ringTimer = 0; for (const r of rings) r.el.remove(); rings = [];
    for (const [k, q] of [sel, ...lits].entries()) if (q) { const el = document.createElement('div'); el.className = 'tour-target' + (k > 0 || /^#(vf-lock|tour-btn|screens-btn|vf-plus)$/.test(sel) ? ' lit' : ''); el.setAttribute('aria-hidden', 'true'); document.body.appendChild(el); rings.push({ el, sel: q }); }
    if (rings.length) { ringPlace(); ringTimer = setInterval(ringPlace, 250); }
  }
  // the free part of the map that the tour card does not cover: above the card or beside it, whichever is larger
  function zone() {
    const m = document.getElementById('svg').getBoundingClientRect(), a = SC.freeArea(), c = card.getBoundingClientRect();
    const l = m.left + a.x, t = m.top + a.y, r = l + a.w, b = t + a.h;
    const zs = [{ l, t, r, b: Math.min(b, c.top - 8) }, { l: Math.max(l, c.right + 8), t, r, b }].filter((z) => z.r - z.l > 40 && z.b - z.t > 40);
    return zs.sort((p, q) => (q.r - q.l) * (q.b - q.t) - (p.r - p.l) * (p.b - p.t))[0] || { l, t, r, b };
  }
  // put the card in the middle of that zone, zooming in on a small card and out on one wider than the zone, but never zooming in so far that the rest of the map leaves the free area;
  function aim(ids, retry) {
    ids = [].concat(ids); const gs = ids.map((i) => SC.state.chipEls?.get(i)).filter(Boolean); if (!gs.length) return; const box = (e) => { const b = e.getBoundingClientRect(); return { l: b.left, t: b.top, r: b.right, b: b.bottom, w: b.width, h: b.height }; };
    const union = () => { const bs = gs.map(box); const l = Math.min(...bs.map((x) => x.l)), t = Math.min(...bs.map((x) => x.t)), r = Math.max(...bs.map((x) => x.r)), b = Math.max(...bs.map((x) => x.b)); return { l, t, r, b, w: r - l, h: b - t }; };
    const r = union(), z = zone(), vp = document.getElementById('viewport'), svg = document.getElementById('svg');
    const m = svg.getBoundingClientRect(), a = SC.freeArea(), F = { l: m.left + a.x, t: m.top + a.y, r: m.left + a.x + a.w, b: m.top + a.y + a.h };
    const all = [...svg.querySelectorAll('g.node')].map(box).filter((x) => x.w > 0 && x.h > 0);
    const U = all.length ? { l: Math.min(...all.map((x) => x.l)), t: Math.min(...all.map((x) => x.t)), r: Math.max(...all.map((x) => x.r)), b: Math.max(...all.map((x) => x.b)) } : r;
    const cx = (r.l + r.r) / 2, cy = (r.t + r.b) / 2, zw = z.r - z.l, zh = z.b - z.t, narrow = innerWidth < 701, lisible = !narrow && !isProject(); // sur l'onglet Code d'un gros lab le graphe entier tient à 0,3 : le plafond « tout le graphe reste dans la zone libre » laissait la carte présentée à 100 px, illisible ; la carte est alors cadrée (jusqu'à 60 % de sa zone) sans ce plafond, la vue d'ensemble revient à la sortie (PU-G-085) // on a phone the whole map is tiny: a small card is zoomed until it can be read, and the rest of the map may leave the screen
    let f = Math.max(1, Math.min(narrow || lisible ? 4 : 1.6, zw * (narrow || lisible ? 0.6 : 0.45) / r.w, zh * (narrow || lisible ? 0.6 : 0.45) / r.h)); // in on a small card...
    const fit = Math.min((F.r - F.l) / (U.r - U.l), (F.b - F.t) / (U.b - U.t)); // the zoom at which the whole map exactly fills the free area; zoom in only up to it (on a phone, down to a card readable at 120 px)
    f = lisible ? f : narrow ? Math.max(Math.min(f, Math.max(1, fit)), Math.min(f, 120 / r.w)) : Math.min(f, Math.max(1, fit));
    f = Math.min(f, 0.92 * zw / r.w, 0.92 * zh / r.h); // ...and out on a card wider than its zone: it must fit whole
    const wheel = (o) => svg.dispatchEvent(new WheelEvent('wheel', { bubbles: true, cancelable: true, deltaMode: 0, ...o })), dx0 = (z.l + z.r) / 2 - cx, dy0 = (z.t + z.b) / 2 - cy, cr = { left: card.offsetLeft, top: card.offsetTop, right: card.offsetLeft + card.offsetWidth, bottom: card.offsetTop + card.offsetHeight };
    // plan(k): the move, at zoom k (around the card's centre), nearest to centring in the zone that keeps the WHOLE map in the free area (strict: and the card visible, not under the tour card); null if none
    const plan = (k, strict) => {
      const sc = (b) => [cx + (b.l - cx) * k, cx + (b.r - cx) * k, cy + (b.t - cy) * k, cy + (b.b - cy) * k], [cl, cq, ct, cb] = sc(r), [ul, ur, ut, ub] = sc(U), xs = [F.l - ul, F.r - ur], ys = [F.t - ut, F.b - ub]; if (xs[0] > xs[1] + 0.5 || ys[0] > ys[1] + 0.5) return null;
      let best = null; const cl2 = (d, [lo, hi]) => Math.min(Math.max(hi, lo), Math.max(lo, d)), pts = [[cl2(dx0, xs), cl2(dy0, ys)]];
      for (let i = 0; i <= 12; i++) for (let j = 0; j <= 12; j++) pts.push([xs[0] + Math.max(0, xs[1] - xs[0]) * i / 12, ys[0] + Math.max(0, ys[1] - ys[0]) * j / 12]);
      for (const [x, y] of pts) {
        const vis = cl + x >= F.l - 1 && cq + x <= F.r + 1 && ct + y >= F.t - 1 && cb + y <= F.b + 1 && !(cl + x < cr.right && cq + x > cr.left && ct + y < cr.bottom && cb + y > cr.top);
        if (strict && !vis) continue; const d = Math.hypot(x - dx0, y - dy0) + (cl + x >= z.l - 1 && cq + x <= z.r + 1 && ct + y >= z.t - 1 && cb + y <= z.b + 1 ? 0 : 1e4); if (!best || d < best.d) best = { d, x, y };
      }
      return best && { k, dx: best.x, dy: best.y };
    };
    // above 701 px a state always exists: zoom out (down to 40 % of the size that just fills the area) until the whole map fits the free area with the card visible; if even that fails the card may stay under the tour card: the only exception
    const ladder = [f]; if (!narrow && !lisible) { for (let k = f * 0.92; k > Math.min(f, fit) * 0.4 && ladder.length < 30; k *= 0.92) ladder.push(k); ladder.push(Math.min(f, fit)); }
    const P = (lisible ? null : ladder.reduce((p, k) => p || plan(k, true), null)) || (narrow || lisible ? null : plan(Math.min(f, fit), false)) || { k: f, dx: dx0, dy: dy0 };
    f = P.k;
    vp.classList.add('anim');
    if (Math.abs(f - 1) > 0.02) wheel({ ctrlKey: true, deltaY: -Math.log(f) / 0.01, clientX: cx, clientY: cy });
    wheel({ deltaX: -P.dx || -0.01, deltaY: -P.dy }); // deltaX is never 0: a pure vertical wheel would be read as a zoom
    setTimeout(() => vp.classList.remove('anim'), 540);
    // once the move is over, measure again: a card that still sticks out of its zone (a wider font, a late layout) is aimed once more
    if (!retry) { const mine = token; setTimeout(() => { if (!active() || mine !== token) return; const b = union(), z2 = zone(); if (b.l < z2.l - 1 || b.r > z2.r + 1 || b.t < z2.t - 1 || b.b > z2.b + 1) aim(ids, true); }, 700); }
  }
  function go(s) {
    const mine = ++token, vp = document.getElementById('viewport');
    const later = (fn, ms) => setTimeout(() => { if (mine === token && active()) fn(); }, ms);
    const slow = SC.state.container !== 'root' || vp.classList.contains('anim'); // the map is about to move on its own: wait for it before measuring
    ring(null);
    if (!s.ref || s.ref === 'root') {
      SC.go('root', { select: null, after: () => { if (s.lit?.length) { document.getElementById('svg').classList.add('dim'); for (const id of s.lit) SC.state.chipEls?.get(id)?.classList.add('hl'); } } }); // a step about several cards lights them all
      if (s.lit?.length) later(() => aim(s.lit), slow ? 650 : 60); // les services éclairés sont cadrés, pas la carte entière (PU-G-089)
      else if (at > 0) later(() => SC.fit(true), slow ? 650 : 60);
    } else {
      // nothing is selected: the details panel keeps showing the overview, the card is lit with the viewer's own highlight (hl on the card, dim on the rest)
      const parent = SC.parentOf(s.ref) || 'root';
      SC.go(parent, { select: null, after: () => { document.getElementById('svg').classList.add('dim'); SC.state.chipEls?.get(s.ref)?.classList.add('hl'); } });
      later(() => aim(s.ref), parent !== 'root' || slow ? 650 : 60);
    }
    ring(s.cible || '', at === steps.length - 1 ? replayTargets() : []);
  }
  function replayTargets() { /* la dernière étape dit où relancer la visite : bouton de visite et « Écrans » éclairés (téléphone : le « ⋯ ») */ const tb = document.getElementById('tour-btn'); if (tb && tb.offsetParent === null) return document.getElementById('vf-plus') ? ['#vf-plus'] : []; return ['#tour-btn'].concat(window.FloorplanScreens ? ['#screens-btn'] : []).filter((q) => visible(document.querySelector(q))); }
  function render() {
    const s = steps[at], last = at === steps.length - 1;
    const tb = document.getElementById('tour-btn'); // on a phone the button sits behind the « ⋯ » menu, not at the top
    const bl = tb && tb.querySelector('.bl'), iconOnly = bl && getComputedStyle(bl).display === 'none'; // under 1 600 px the button shows its icon only
    const tip = last ? `${tb && tb.offsetParent === null ? 'Replay this tour any time from <b>⋯ › Start here</b>.' : iconOnly ? 'Replay this tour any time from <b>the tour button (icon)</b> at the top.' : 'Replay this tour any time from <b>Start here</b> at the top.'}${window.FloorplanScreens ? ' <b>Screens</b> shows everything behind any page.' : ''}` : '';
    card.innerHTML = `<button class="btn icon tx" data-x title="Close (Esc)" aria-label="Close tour">${SC.iconI('x')}</button>
      <div class="tb"><div class="tk"><span>Start here</span><i></i><span>Step ${at + 1} of ${steps.length}</span>${s.kicker ? `<i></i><span>${h(s.kicker)}</span>` : ''}</div>
      <div class="tt">${h(s.title)}</div>${s.note ? `<div class="tn">${h(s.note)}</div>` : ''}${tip ? `<div class="tip">${tip}</div>` : ''}</div>
      <div class="tf"><div class="dots">${steps.map((_, k) => `<i class="${k <= at ? 'on' : ''}"></i>`).join('')}</div>
        <div class="acts"><button class="btn" data-x>Skip</button>
        ${at > 0 ? `<button class="btn icon soft" data-back title="Back (←)">${SC.iconI('left')}</button>` : ''}
        ${s.flow ? `<button class="btn primary" data-play>${SC.iconI('right')}Play it</button>${last ? '' : '<button class="btn soft" data-next>Next</button>'}` : `<button class="btn primary" data-next>${last ? 'Done' : 'Next'}</button>`}
        </div>
      </div>`;
    card.querySelectorAll('[data-x]').forEach((b) => b.onclick = () => end());
    card.querySelector('[data-back]')?.addEventListener('click', back);
    card.querySelector('[data-next]')?.addEventListener('click', next);
    card.querySelector('[data-play]')?.addEventListener('click', () => { const id = s.flow; end(false); SC.startFlow(id); });
  }
  // sit above the zoom controls, and above the Ask bar (and its notices) where they overlap
  let placedSig = '', placeTimer = 0, lastPlace = null;
  const sigOf = (obs) => obs.map((o) => [o.left, o.top, o.right, o.bottom].map(Math.round).join(',')).join('|');
  function obstacles(vis) { // sur un téléphone le zoom monte de lui-même au-dessus de la feuille (--vf-ask-h, 02-vf-telephone.js) : ce n'est pas un obstacle ; la pastille du terminal, elle, ne bouge pas : la feuille la laisse libre (T21.7)
    const ask = document.getElementById('ask');
    const name = (e) => e.id ? '#' + e.id : e.tagName.toLowerCase() + (typeof e.className === 'string' && e.className.trim() ? '.' + e.className.trim().split(/\s+/)[0] : '');
    return ['zoom', 'panel', 'context', 'ask'].map((id) => document.getElementById(id)).concat(document.querySelector('header'), [...document.querySelectorAll('.tour-target')], document.querySelector('.vf-' + 'term-pastille'), ask ? [...ask.children] : []).filter(vis).map((e) => { const r = e.getBoundingClientRect(); return { n: name(e), left: r.left, top: r.top, right: r.right, bottom: r.bottom }; }).filter((o) => innerWidth >= 701 || o.n !== '#zoom'); // 71.5 : le sélecteur est assemblé (la page servie sans --terminal ne contient jamais le préfixe du terminal, T7.5) ; la pastille du terminal (seulement avec --terminal ; absente ou masquée = ignorée par vis) est un obstacle comme le zoom, sans marge fixe
  }
  const visible = (e) => { if (!e) return false; const r = e.getBoundingClientRect(), cs = getComputedStyle(e); return r.width > 0 && r.height > 0 && cs.visibility !== 'hidden' && cs.display !== 'none'; };
  // last resort when a title block taller than expected leaves no room: its description is folded away while the tour is open (the title stays), and put back when the tour moves on or ends
  function fold() { const p = document.querySelector('#context p'); if (!p || p.dataset.tourFold !== undefined || !visible(p)) return false; p.dataset.tourFold = p.style.display; p.style.display = 'none'; ringPlace(); return true; }
  function unfold() { const p = document.querySelector('#context p'); if (p && p.dataset.tourFold !== undefined) { p.style.display = p.dataset.tourFold; delete p.dataset.tourFold; ringPlace(); } }
  function place(folded) {
    if (!folded) unfold();
    // the card must not cover any fixed surface (zoom controls, details panel, title block, header, Ask bar and notices, the outlined target). Every candidate (width, side, height above an obstacle)
    // is scored by the area it covers, then by its distance from the usual place; lowest cost wins, ties go to the first in a fixed order: nothing but the layout decides (never timing, fonts or pointer)
    const feuille = innerWidth < 701; // un téléphone : une feuille pleine largeur en bas, posée au-dessus de la barre de question (PU-G-090)
    const vis = visible;
    const obs = obstacles(vis);
    placedSig = sigOf(obs);
    lastPlace = { obs, topLimit: 0, best: null };
    const topLimit = ['context'].map((id) => document.getElementById(id)).concat(document.querySelector('header')).filter(vis).reduce((m, e) => Math.max(m, e.getBoundingClientRect().bottom), 0) + 8; // header and title block (whatever their height: a wide font makes the title taller): the card is never taller than the room under them, its text scrolls
    const w0 = feuille ? innerWidth - 16 : Math.min(360, innerWidth - 32);
    const widths = feuille ? [w0] : [w0, 300, 260, 220, 200].filter((w, k, a) => w <= w0 && a.indexOf(w) === k);
    const bottoms = [76, ...obs.map((o) => Math.round(innerHeight - o.top + 12))].filter((b, k, a) => b >= 12 && b <= innerHeight - 120 && a.indexOf(b) === k).sort((a, b) => a - b);
    const colonne = feuille ? 0 : obs.filter((o) => (o.n === '#zoom' || o.n.indexOf('term-pastille') > 0) && o.left < 60).reduce((m, o) => Math.max(m, o.right + 8), 0); // I-3 : une fenêtre basse ne laisse, au bord gauche, que la colonne du zoom et de la pastille ; la carte peut aussi se poser À DROITE de cette colonne (troisième côté, le moins favorisé), entre elle et le panneau ou le bord droit
    const G6 = 2; // px counted around each surface: borders and rounding that the layout box does not show (6 made the search pick needlessly narrow cards and pushed the map out of the free area)
    const area = (a, b) => Math.max(0, Math.min(a.right, b.right + G6) - Math.max(a.left, b.left - G6)) * Math.max(0, Math.min(a.bottom, b.bottom + G6) - Math.max(a.top, b.top - G6));
    let best = null;
    // widths first; when nothing fits without covering a surface, the card also gets shorter (its text scrolls), down to a floor of 200 x 120 px
    for (const [lvl, hcap] of (feuille ? [Math.round(innerHeight * 0.5)] : [1e6, 240, 180, 120]).entries()) { // feuille : au plus la moitié de l'écran, le texte défile, le reste montre la carte
      for (const w of widths) for (const side of (feuille ? ['left'] : colonne ? ['left', 'right', 'colonne'] : ['left', 'right'])) for (const b of bottoms) {
        card.style.width = w + 'px'; card.style.bottom = b + 'px'; card.style.maxHeight = Math.min(hcap, Math.max(120, innerHeight - b - topLimit)) + 'px'; card.classList.toggle('right', side === 'right'); card.style.left = side === 'colonne' ? colonne + 'px' : '';
        // the card's layout box, not its painted box: during its entry animation (98 % size, 8 px down) the painted box is smaller and shows a gap that the finished card does not have
        const r = { left: card.offsetLeft, top: card.offsetTop, right: card.offsetLeft + card.offsetWidth, bottom: card.offsetTop + card.offsetHeight };
        // the cost: what it covers first (a covered pixel outweighs any move), then how far it is from the usual place (bottom left, full width, full height)
        const covered = obs.reduce((n, o) => n + area(r, o), 0);
        const score = covered * 1e3 + (r.top < 0 || r.left < -0.5 || r.right > innerWidth + 0.5 ? 1e12 : 0) + Math.abs(b - 76) + (side === 'right' ? 40 : side === 'colonne' ? 60 : 0) + (w0 - w) * 0.5 + lvl * 20;
        if (!best || score < best.score) best = { score, covered, w, side, b, mh: card.style.maxHeight };
      }
      if (best.covered === 0) break;
    }
    lastPlace.best = best; lastPlace.topLimit = topLimit;
    card.style.width = best.w + 'px'; card.style.bottom = best.b + 'px'; card.style.maxHeight = best.mh; card.classList.toggle('right', best.side === 'right'); card.style.left = best.side === 'colonne' ? colonne + 'px' : '';
    // still covering something: fold the title description and search again; kept only if that covers less, else put back
    if (!folded && best.covered > 0 && fold()) { const before = best.covered; place(true); if (lastPlace.best.covered >= before) { unfold(); place(true); } }
  }
  function cedeAuZoom() { const z = document.getElementById('zoom'), c = card.getBoundingClientRect(), b = z && z.getBoundingClientRect(); if (b && b.width && b.bottom > c.top && b.right > c.left && b.left < c.right) card.style.maxHeight = Math.max(120, c.height - (b.bottom - c.top) - 4) + 'px'; } // téléphone : le zoom monte avec la feuille, mais d'un cran en retard : la feuille lui cède la place
  window.addEventListener('resize', () => { if (active()) place(); });
  function show(i) {
    at = i;
    card.hidden = false;
    render();
    go(steps[at]);
    place();
    // the page lays itself out after the step and on its own (title block, zoom stack, Ask notices): while the tour is open, place again whenever a surface has moved
    if (!placeTimer) placeTimer = setInterval(() => { if (!active()) return; if (sigOf(obstacles(visible)) !== placedSig) place(); else if (innerWidth < 701) cedeAuZoom(); }, 200);
    // the opening fit is only for a first step on the overview itself: after a card step it would undo the centring (a page already seen settles faster, so the card was measured before the fit)
    if (at === 0 && (!steps[0].ref || steps[0].ref === 'root')) setTimeout(() => { if (at === 0) SC.fit(true); }, 450);
  }
  function next() { if (at >= steps.length - 1) end(); else show(at + 1); }
  function back() { if (at > 0) show(at - 1); }
  function end(refit = true) {
    if (!active()) return;
    at = -1; token++; clearInterval(placeTimer); placeTimer = 0; unfold();
    ring(null);
    card.hidden = true;
    SC.store.set(SEEN, true);
    // every way out gives back the overview, whole: a step on a card inside a group had opened that group, and it must not stay open at the zoom of the last card
    if (SC.state.container === 'root') { SC.select(null); if (refit) SC.fit(true); }
    else if (refit) SC.go('root', { select: null, after: () => SC.fit(true) });
  }
  function start() {
    if (G.meta?.vfTab === 'equipe') return; // the Team tab has no tour of its own (its map is live sessions, not a codebase): it never opens, by itself or by the button
    steps = buildSteps();
    if (steps.length < 2) { SC.toast('There is not enough on this map for a tour yet.'); return; }
    SC.store.set(SEEN, true);
    show(0);
  }

  const tourBtn = SC.addHeaderButton({ id: 'tour-btn', label: 'Start here', icon: 'home', title: isProject() ? 'A one-minute tour of this project' : 'A one-minute tour of this codebase', onClick: (ev) => { if (active()) end(); else { start(); if (ev && ev.detail > 0) tourBtn.blur(); } } }); // ouverte à la souris, le bouton ne garde pas le focus : le clavier utilisé ensuite dans la visite n'y fait pas apparaître d'anneau (PU-G-013)
  if (G.meta?.vfTab === 'equipe') { tourBtn.setAttribute('aria-disabled', 'true'); tourBtn.title = 'There is no tour for the Team tab'; tourBtn.style.opacity = '0.5'; tourBtn.style.cursor = 'default'; } // the Team tab has no tour designed: the button says so and does nothing
  const ic = tourBtn.querySelector('svg');
  if (ic) ic.innerHTML = '<circle cx="12" cy="12" r="9"/><path d="m15.5 8.5-2.2 4.8-4.8 2.2 2.2-4.8z"/>'; // compass
  window.addEventListener('keydown', (ev) => {
    if (!active() || ev.target?.tagName === 'INPUT' || ev.target?.tagName === 'TEXTAREA') return;
    if (ev.key === 'Escape') { ev.stopPropagation(); ev.preventDefault(); end(); }
    else if (!SC.state.flow && ev.key === 'ArrowRight') { ev.stopPropagation(); ev.preventDefault(); next(); }
    else if (!SC.state.flow && ev.key === 'ArrowLeft') { ev.stopPropagation(); ev.preventDefault(); back(); }
  }, true);
  // a guided flow takes over the canvas: step aside
  SC.on('render', () => { if (active() && SC.state.flow) end(false); });

  // first visit: start on its own, unless the link points somewhere specific
  let auto = false;
  const maybeAuto = () => {
    if (auto) return;
    auto = true;
    if (SC.store.get(SEEN, false) || location.hash.length > 1) return;
    setTimeout(() => { if (!active() && !SC.state.flow && SC.state.container === 'root') start(); }, 700);
  };
  SC.on('ready', maybeAuto);
  if (SC.state.layout) maybeAuto();

  // diagnostic for the test suites (a failure on a runner we do not have prints what the placement saw): the obstacles of the last placement and the position it chose
  const diag = () => JSON.stringify(!lastPlace ? { placed: false } : { obstacles: lastPlace.obs.map((o) => o.n + '[' + [o.left, o.top, o.right, o.bottom].map(Math.round).join(',') + ']'), topLimit: Math.round(lastPlace.topLimit), choice: lastPlace.best && { width: lastPlace.best.w, side: lastPlace.best.side, bottom: lastPlace.best.b, covered: Math.round(lastPlace.best.covered), maxHeight: lastPlace.best.mh } });
  window.FloorplanTour = { start, end, active, diag };
})();
