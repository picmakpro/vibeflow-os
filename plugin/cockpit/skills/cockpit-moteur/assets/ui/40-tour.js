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
#tour { position: fixed; left: 16px; bottom: 76px; width: min(360px, calc(100vw - 32px)); max-height: calc(100vh - 170px); display: flex; flex-direction: column; padding: 16px 16px 12px 20px; border-radius: var(--r-panel); z-index: 6; animation: tourIn .4s var(--ease); }
#tour.right { left: auto; right: 16px; }
#tour .tb { flex: 1 1 auto; min-height: 0; overflow-y: auto; }
.tour-target { position: fixed; z-index: 5; pointer-events: none; outline: 2px solid var(--ring); outline-offset: 4px; border-radius: 10px; }
#tour[hidden] { display: none; }
#tour .tk { font-size: 12px; color: var(--text-3); margin-bottom: 4px; display: flex; gap: 6px; align-items: center; }
#tour .tk i { width: 3px; height: 3px; border-radius: 50%; background: var(--text-4); }
#tour .tt { font-size: 16px; font-weight: 600; letter-spacing: -.01em; line-height: 1.35; padding-right: 22px; }
#tour .tn { color: var(--text-2); line-height: 1.55; margin-top: 6px; font-size: 13.5px; }
#tour .tip { color: var(--text-3); font-size: 12px; line-height: 1.5; margin-top: 10px; }
#tour .tf { flex: none; display: flex; flex-direction: column; gap: 10px; margin-top: 14px; }
#tour .acts { display: flex; align-items: center; gap: 8px; }
#tour .acts [data-x] { margin-right: auto; }
#tour .dots { display: flex; gap: 4px; }
#tour .dots i { width: 14px; height: 3px; border-radius: 2px; background: rgba(var(--ink), .12); transition: background .3s var(--ease); }
#tour .dots i.on { background: var(--on); }
#tour .tf .btn { height: 32px; }
#tour .tf .btn.icon { width: 32px; }
#tour .tx { position: absolute; top: 10px; right: 10px; width: 28px; height: 28px; }
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
        ref: ext.length === 1 ? 'n:' + ext[0].id : 'root', kicker: 'Outside services', title: ext.length === 1 ? ext[0].label : `${ext.length} outside services`,
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
      .map((s) => (s.ref === 'root' && !s.cible ? { ...s, cible: '#context' } : s));
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
  let ringEl = null, ringSel = '', ringTimer = 0;
  function ringPlace() {
    let t = null; try { t = ringSel ? document.querySelector(ringSel) : null; } catch {}
    const b = t && t.getBoundingClientRect();
    if (!b || !b.width || !b.height) { if (ringEl) ringEl.style.display = 'none'; return; }
    Object.assign(ringEl.style, { display: '', left: b.left + 'px', top: b.top + 'px', width: b.width + 'px', height: b.height + 'px' });
  }
  function ring(sel) {
    clearInterval(ringTimer); ringTimer = 0;
    if (ringEl) { ringEl.remove(); ringEl = null; }
    ringSel = '';
    if (!sel) return;
    ringSel = sel; ringEl = document.createElement('div'); ringEl.className = 'tour-target'; ringEl.setAttribute('aria-hidden', 'true');
    document.body.appendChild(ringEl); ringPlace(); ringTimer = setInterval(ringPlace, 250);
  }
  // the free part of the map that the tour card does not cover: above the card or beside it, whichever is larger
  function zone() {
    const m = document.getElementById('svg').getBoundingClientRect(), a = SC.freeArea(), c = card.getBoundingClientRect();
    const l = m.left + a.x, t = m.top + a.y, r = l + a.w, b = t + a.h;
    const zs = [{ l, t, r, b: Math.min(b, c.top - 8) }, { l: Math.max(l, c.right + 8), t, r, b }].filter((z) => z.r - z.l > 40 && z.b - z.t > 40);
    return zs.sort((p, q) => (q.r - q.l) * (q.b - q.t) - (p.r - p.l) * (p.b - p.t))[0] || { l, t, r, b };
  }
  // put the card in the middle of that zone, zooming in on a small card and out on one wider than the zone, but never zooming in so far that the rest of the map leaves the free area;
  // the viewer's own wheel handler does the moving (pan, ctrl+wheel to zoom)
  function aim(id) {
    const g = SC.state.chipEls?.get(id); if (!g) return;
    const box = (e) => { const b = e.getBoundingClientRect(); return { l: b.left, t: b.top, r: b.right, b: b.bottom, w: b.width, h: b.height }; };
    const r = box(g), z = zone(), vp = document.getElementById('viewport'), svg = document.getElementById('svg');
    const m = svg.getBoundingClientRect(), a = SC.freeArea(), F = { l: m.left + a.x, t: m.top + a.y, r: m.left + a.x + a.w, b: m.top + a.y + a.h };
    const all = [...svg.querySelectorAll('g.node')].map(box).filter((x) => x.w > 0 && x.h > 0);
    const U = all.length ? { l: Math.min(...all.map((x) => x.l)), t: Math.min(...all.map((x) => x.t)), r: Math.max(...all.map((x) => x.r)), b: Math.max(...all.map((x) => x.b)) } : r;
    const cx = (r.l + r.r) / 2, cy = (r.t + r.b) / 2, zw = z.r - z.l, zh = z.b - z.t;
    let f = Math.max(1, Math.min(1.6, zw * 0.45 / r.w, zh * 0.45 / r.h)); // in on a small card...
    f = Math.min(f, Math.max(1, Math.min(F.w ? (F.r - F.l) / (U.r - U.l) : 1, (F.b - F.t) / (U.b - U.t)))); // ...not past the point where the whole map no longer fits
    f = Math.min(f, 0.92 * zw / r.w, 0.92 * zh / r.h); // ...and out on a card wider than its zone: it must fit whole
    const wheel = (o) => svg.dispatchEvent(new WheelEvent('wheel', { bubbles: true, cancelable: true, deltaMode: 0, ...o }));
    // where things land after the zoom (around the card's centre) and the move that centres the card
    const at = (k) => ({ l: cx + (k.l - cx) * f, r: cx + (k.r - cx) * f, t: cy + (k.t - cy) * f, b: cy + (k.b - cy) * f });
    const c = at(r), u = at(U), dx0 = (z.l + z.r) / 2 - cx, dy0 = (z.t + z.b) / 2 - cy;
    const clamp = (d, lo, hi) => (lo <= hi ? Math.min(hi, Math.max(lo, d)) : d);
    const dx1 = clamp(dx0, F.l - u.l, F.r - u.r), dy1 = clamp(dy0, F.t - u.t, F.b - u.b); // keep the whole map in the free area when it fits there
    const inZone = (dx, dy) => c.l + dx >= z.l - 1 && c.r + dx <= z.r + 1 && c.t + dy >= z.t - 1 && c.b + dy <= z.b + 1;
    const [dx, dy] = inZone(dx1, dy1) ? [dx1, dy1] : [dx0, dy0];
    vp.classList.add('anim');
    if (Math.abs(f - 1) > 0.02) wheel({ ctrlKey: true, deltaY: -Math.log(f) / 0.01, clientX: cx, clientY: cy });
    wheel({ deltaX: -dx || -0.01, deltaY: -dy }); // deltaX is never 0: a pure vertical wheel would be read as a zoom
    setTimeout(() => vp.classList.remove('anim'), 540);
  }
  function go(s) {
    const mine = ++token, vp = document.getElementById('viewport');
    const later = (fn, ms) => setTimeout(() => { if (mine === token && active()) fn(); }, ms);
    const slow = SC.state.container !== 'root' || vp.classList.contains('anim'); // the map is about to move on its own: wait for it before measuring
    ring(null);
    if (!s.ref || s.ref === 'root') {
      SC.go('root', { select: null });
      if (at > 0) later(() => SC.fit(true), slow ? 650 : 60);
    } else {
      // nothing is selected: the details panel keeps showing the overview, the card is lit with the viewer's own highlight (hl on the card, dim on the rest)
      const parent = SC.parentOf(s.ref) || 'root';
      SC.go(parent, { select: null, after: () => { document.getElementById('svg').classList.add('dim'); SC.state.chipEls?.get(s.ref)?.classList.add('hl'); } });
      later(() => aim(s.ref), parent !== 'root' || slow ? 650 : 60);
    }
    if (s.cible) ring(s.cible);
  }
  function render() {
    const s = steps[at], last = at === steps.length - 1;
    const tb = document.getElementById('tour-btn'); // on a phone the button sits behind the « ⋯ » menu, not at the top
    const tip = last ? `${tb && tb.offsetParent === null ? 'Replay this tour any time from <b>⋯ › Start here</b>.' : 'Replay this tour any time from <b>Start here</b> at the top.'}${window.FloorplanScreens ? ' <b>Screens</b> shows everything behind any page.' : ''}` : '';
    card.innerHTML = `<button class="btn icon tx" data-x title="Close (Esc)">${SC.iconI('x')}</button>
      <div class="tb"><div class="tk"><span>Start here</span><i></i><span>${at + 1} of ${steps.length}</span>${s.kicker ? `<i></i><span>${h(s.kicker)}</span>` : ''}</div>
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
  function place() {
    let bottom = 76;
    // a details panel beside the map: the card gets narrower rather than slide under it (the panel's width depends on fonts and platform)
    card.style.width = '';
    const pn = document.getElementById('panel'), pr = pn && pn.getBoundingClientRect();
    if (pr && pr.width > 0 && getComputedStyle(pn).visibility !== 'hidden') {
      const c0 = card.getBoundingClientRect();
      if (pr.left > c0.left && hit(c0, pr)) card.style.width = Math.max(200, pr.left - 12 - c0.left) + 'px';
    }
    const ask = document.getElementById('ask');
    if (ask) {
      const a = ask.getBoundingClientRect(), c = card.getBoundingClientRect();
      const top = [...ask.children].filter((x) => x.offsetParent && x.getBoundingClientRect().height > 0).reduce((m, x) => Math.min(m, x.getBoundingClientRect().top), a.bottom);
      if (a.width && a.left < 16 + c.width + 12 && top < innerHeight) bottom = Math.max(bottom, innerHeight - top + 12);
    }
    card.style.bottom = Math.min(bottom, Math.max(76, innerHeight - card.offsetHeight - 80)) + 'px';
    // an element of the page that the card would cover: the card moves to the other side
    card.classList.remove('right');
    const t = document.querySelector('.tour-target');
    if (t && hit(t.getBoundingClientRect(), card.getBoundingClientRect())) {
      card.classList.add('right');
      if (pr && pr.width > 0 && hit(card.getBoundingClientRect(), pr)) card.classList.remove('right'); // never onto the details panel
    }
  }
  window.addEventListener('resize', () => { if (active()) place(); });
  function show(i) {
    at = i;
    card.hidden = false;
    render();
    go(steps[at]);
    place();
    // the opening fit is only for a first step on the overview itself: after a card step it would undo the centring (a page already seen settles faster, so the card was measured before the fit)
    if (at === 0 && (!steps[0].ref || steps[0].ref === 'root')) setTimeout(() => { if (at === 0) SC.fit(true); }, 450);
  }
  function next() { if (at >= steps.length - 1) end(); else show(at + 1); }
  function back() { if (at > 0) show(at - 1); }
  function end(refit = true) {
    if (!active()) return;
    at = -1; token++;
    ring(null);
    card.hidden = true;
    SC.store.set(SEEN, true);
    // every way out gives back the overview, whole: a step on a card inside a group had opened that group, and it must not stay open at the zoom of the last card
    if (SC.state.container === 'root') { SC.select(null); if (refit) SC.fit(true); }
    else if (refit) SC.go('root', { select: null, after: () => SC.fit(true) });
  }
  function start(manual) {
    if (!manual && G.meta?.vfTab === 'equipe') return; // the Team tab has no tour of its own (its map is live sessions, not a codebase): it never opens by itself, whatever the timing
    steps = buildSteps();
    if (steps.length < 2) { SC.toast('There is not enough on this map for a tour yet.'); return; }
    SC.store.set(SEEN, true);
    show(0);
  }

  const tourBtn = SC.addHeaderButton({ id: 'tour-btn', label: 'Start here', icon: 'home', title: 'A one-minute tour of this codebase', onClick: () => (active() ? end() : start(true)) });
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

  window.FloorplanTour = { start, end, active };
})();
