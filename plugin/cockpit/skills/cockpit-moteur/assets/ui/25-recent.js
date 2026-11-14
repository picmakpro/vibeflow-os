// Recent work: what Claude just changed (graph.recent, from floorplan/recent-work.json), framed against
// what the user asked for. Cards carry the green tag and hover note (core viewer); this adds the header
// button that lays the changed cards out on one board, and the panel sections. Talks to the viewer only
// through window.Floorplan.
(() => {
  const SC = window.Floorplan;
  const R = SC && SC.graph.recent;
  if (!R || !R.items || !R.items.length) return;
  const t = window.__vfFrT;
  const { h } = SC;
  const tasks = R.tasks || [];
  const items = R.items.filter((it) => SC.exists(it.id));
  if (!items.length) return;

  // 80-20 (P80-D-53) : une horloge qui revient en arrière, plus l'air d'un chargement
  SC.icons.recent = '<path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/><path d="M12 7v5l4 2"/>';

  const style = document.createElement('style');
  style.textContent = `
    #btn-recent svg.i { color: var(--recent); }
    #btn-recent .badge { background: var(--recent); color: var(--on-recent-text); }
    .rw-task { padding: var(--inset-box); border-radius: 16px; background: var(--note-bg); color: var(--text); margin-bottom: var(--sp-12); }
    .rw-task:last-child { margin-bottom: 0; }
    .rw-tt { display: flex; gap: var(--sp-8); align-items: center; font-weight: 600; line-height: 1.4; }
    .rw-tt::before { content: ""; width: 8px; height: 8px; border-radius: 50%; background: var(--recent); flex: none; }
    .rw-q { color: var(--text-3); font-size: 12.5px; line-height: 1.5; margin: var(--sp-6) 0 0 var(--sp-16); }
    .rw-q b { color: var(--text-2); font-weight: 500; }
    .rw-s { color: var(--text-2); font-size: 12.5px; line-height: 1.55; margin: var(--sp-6) 0 0 var(--sp-16); }
    .rw-a { display: flex; gap: var(--sp-6); margin: var(--sp-12) 0 0 var(--sp-16); }
    .rw-a .btn { height: 30px; padding: 0 var(--sp-12); font-size: 12.5px; gap: var(--sp-6); }
    .rw-note { margin-top: var(--sp-12); padding: var(--sp-8) var(--sp-12); border-radius: 14px; background: var(--note-bg); color: var(--text); font-size: 13px; line-height: 1.55; }
    .rw-note .rw-h { color: var(--text-2); font-size: 11.5px; font-weight: 600; margin-bottom: var(--sp-4); }
    .rw-when { color: var(--text-3); font-size: 12px; margin-top: var(--sp-4); }
  `;
  document.head.appendChild(style);

  const ago = (iso) => {
    const ms = Date.parse(iso); if (!ms) return '';
    const m = Math.round((Date.now() - ms) / 60000);
    if (m < 2) return t('just now');
    return m < 60 ? t('{} minutes ago', m) : m < 48 * 60 ? t('{} hours ago', Math.round(m / 60)) : t('{} days ago', Math.round(m / 1440));
  };
  const itemsOf = (ti) => items.filter((it) => ti == null || it.task === ti);
  // one entry per (file, task): a file touched by two tasks is still one card. Every count shown is in cards.
  const uniq = (list) => { const seen = new Set(); return list.filter((it) => !seen.has(it.id) && seen.add(it.id)); };
  const nCards = (list) => uniq(list).length;

  /** One board with just the changed cards (and how they connect), each with its note. */
  function showRecent(ti) {
    const one = ti != null ? tasks[ti] : tasks.length === 1 ? tasks[0] : null;
    SC.showBoard({
      kind: t('Recent work'), icon: 'recent',
      title: one ? one.title : t('Recent work'),
      question: one ? (one.request ? t('You asked: {}', one.request) : '') : tasks.map((k) => k.title).join(' · '),
      answer: one ? one.summary : tasks.map((k) => `**${k.title}.** ${k.summary}`).join('\n\n'),
      items: uniq(itemsOf(ti != null ? ti : null)).map((it) => ({ id: it.id, note: it.note || (it.change === 'new' ? t('New') : t('Changed')) })),
    });
  }

  const btn = SC.addHeaderButton({ id: 'btn-recent', label: t('Recent work'), icon: 'recent', title: t('What was just worked on, on one board'), onClick: () => showRecent() });
  const b = document.createElement('span');
  b.className = 'badge';
  b.textContent = String(nCards(items));
  btn.appendChild(b);

  // codebase panel: each task, what was asked, what was done, and a way to see its cards
  SC.addPanelSection('overview', () => ({
    top: true,
    html: `<div class="sec"><h3>${t('Recent work')} <span class="c">${nCards(items)}</span></h3>${R.updatedAt ? `<div class="rw-when">${t('Updated {}', h(ago(R.updatedAt)))}</div>` : ''}
      <div style="margin-top:var(--sp-12)">${tasks.map((k, i) => itemsOf(i).length ? `
      <div class="rw-task"><div class="rw-tt">${h(k.title)}</div>
        ${k.request ? `<div class="rw-q"><b>${t('You asked:')}</b> ${h(k.request)}</div>` : ''}
        ${k.summary ? `<div class="rw-s">${h(k.summary)}</div>` : ''}
        <div class="rw-a"><button class="btn soft" data-rw="${i}">${SC.iconI('recent')}${t('Show {}', t.pl(nCards(itemsOf(i)), 'card'))}</button></div></div>` : '').join('')}</div></div>`,
    bind: (el) => el.querySelectorAll('[data-rw]').forEach((x) => x.addEventListener('click', () => showRecent(+x.dataset.rw))),
  }));

  // a selected card that changed: the full note, and which request it was for. A part that
  // contains changes: what changed inside it, each a click away.
  SC.addPanelSection('item', (id) => {
    const key = id.startsWith('m:') ? 'f:' + id.slice(2) : id;
    const mine = items.filter((it) => it.id === key);
    const inside = uniq(items.filter((it) => it.id !== key && SC.chain(it.id).includes(key)));
    if (!mine.length && !inside.length) return '';
    if (!mine.length) return { top: true, html: `<div class="sec"><h3>${t('Recent work inside')} <span class="c">${inside.length}</span></h3><div class="list">${inside.map((it) => {
      return `<a class="row" data-go="${h(it.id)}"><span class="dot" style="background:var(--recent)"></span><span class="rt"><div class="rn">${h(SC.shownName ? SC.shownName(it.id) : SC.info(it.id).name)}</div>${it.note ? `<div class="rd">${h(it.note)}</div>` : ''}</span></a>`;
    }).join('')}</div></div>` };
    return { top: true, html: `<div class="sec">${mine.map((it) => {
      const k = tasks[it.task] || {};
      const head = it.change === 'new' ? `${t('New')} · ${h(k.title || t('Recent work'))}` : t('Changed · {}', h(k.title || t('Recent work')));
      return `<div class="rw-note"><div class="rw-h">${head}</div>${h(it.note || '')}${k.request ? `<div class="rw-q" style="margin:var(--sp-6) 0 0"><b>${t('You asked:')}</b> ${h(k.request)}</div>` : ''}</div>`;
    }).join('')}</div>` };
  });

  window.FloorplanRecent = { show: showRecent, items, tasks };
})();
