// Health check panel: plain-language warnings from graph.health (lib/health.mjs) — leaked keys,
// endpoints anyone can call, unused and oversized files — each with "Show on map" and a ready
// prompt to paste into Claude Code or Codex. Talks to the viewer only through window.Floorplan.
(() => {
  const SC = window.Floorplan;
  // an exported copy without Health leaves the button out: an empty list would read as "all clear"
  if (!SC || (SC.exported && !SC.graph.health)) return;
  const { h } = SC;
  const t = window.__vfFrT;
  const A = SC.agent || { name: 'Claude', app: 'Claude Code' };
  const issues = (SC.graph.health && SC.graph.health.issues) || [];
  // a blueprint (planned, not built) gets a design review of the plan instead of a code check
  const PLAN = !!SC.graph.meta.blueprint;
  const FIX = PLAN ? 'Resolve' : t('Fix');

  const SEV = {
    high: { color: 'var(--sev-high)', group: t('Fix these first'), word: (n) => t('{} important', n) },
    medium: { color: 'var(--sev-medium)', group: t('Worth fixing soon'), word: (n) => t('{} worth fixing', n) },
    low: { color: 'var(--sev-low)', group: t('Good to tidy up'), word: (n) => t('{} minor', n) },
  };
  const ORDER = ['high', 'medium', 'low'];
  const count = (sev) => issues.filter((i) => i.severity === sev).length;
  const urgent = count('high') + count('medium');
  // one number everywhere: the title, the badge and the legend (important + worth fixing + minor) all add up to the same total
  const total = issues.length;
  // services this project really uses (graph.health.services): the intro only names those, never a stock list
  const services = ((SC.graph.health && SC.graph.health.services) || []).filter((x) => typeof x === 'string');
  const SECTION = SC.graph.meta && SC.graph.meta.vfTab === 'project' ? t('Health (security only)') : t('Health'); // the project tab's other gaps are not in this check

  SC.icons.health = '<path d="M3 12h4l2.5-6 4 12 2.5-6H21"/>';
  SC.icons.check = '<path d="m5 12.5 4.5 4.5L19 7.5"/>';

  const style = document.createElement('style');
  style.textContent = `
    .hc-issue { padding: var(--inset-box); border-radius: 16px; background: rgba(var(--ink), .04); margin-bottom: var(--sp-12); }
    .hc-issue:last-child { margin-bottom: 0; }
    .hc-t { display: flex; gap: var(--sp-8); align-items: flex-start; font-weight: 500; line-height: 1.4; }
    .hc-t .dot { margin-top: var(--sp-6); }
    .hc-d { color: var(--text-2); font-size: 12.5px; line-height: 1.55; margin: var(--sp-6) 0 0 var(--sp-16); }
    .hc-n { color: var(--text-3); font-size: 12.5px; line-height: 1.45; margin: var(--sp-6) 0 0 var(--sp-16); }
    .hc-w { font-family: var(--mono); font-size: 11px; color: var(--text-3); margin: var(--sp-6) 0 0 var(--sp-16); word-break: break-all; line-height: 1.5; }
    .hc-a { display: flex; gap: var(--sp-6); flex-wrap: wrap; margin: var(--sp-12) 0 0 var(--sp-16); }
    .hc-a .btn { height: 30px; padding: 0 var(--sp-12); font-size: 12.5px; gap: var(--sp-6); }
    .hc-a .btn svg.i { width: 14px; height: 14px; }
    .hc-calm { margin-top: var(--sp-16); padding: var(--inset-box); border-radius: 14px; background: var(--ok-bg); color: var(--ok-text); font-size: 13px; line-height: 1.55; }
    .hc-sub { display: flex; flex-wrap: wrap; gap: var(--sp-4) var(--sp-12); margin-top: var(--sp-12); font-size: 12px; color: var(--text-2); }
    .hc-sub span { display: inline-flex; align-items: center; gap: var(--sp-6); }
    #btn-health .badge { background: var(--hc-badge, var(--on)); color: var(--hc-badge-text, var(--on-text)); }
    #btn-health.calm svg.i { color: var(--ok); }
    #modal .hc-hint { margin: 0; }
    #modal .hc-hint b { color: var(--text); font-weight: 500; }
  `;
  document.head.appendChild(style);

  // ---------- actions ----------
  let isOpen = false, openedAt = null;
  const where = () => JSON.stringify([SC.state.selected, SC.state.container]);
  function closeList() { isOpen = false; SC.closePanel(); }
  function showOnMap(issue) {
    const items = (issue.items || []).filter((id) => SC.exists(id)).map((id) => ({ id, note: (issue.notes && issue.notes[id]) || '' }));
    if (!items.length) { SC.toast(t('This one isn’t on the map. Use “{} with {}” instead.', FIX, A.name)); return; }
    if (isOpen) closeList();
    SC.showBoard({ title: issue.title, question: issue.detail, items });
  }
  // a served blueprint settles review items on the map: the request goes into the Ask bar's Change mode,
  // for the person to finish (an open question needs their answer) or edit, then send
  const here = (issue) => PLAN && !!issue.change && !!SC.canChange?.();
  function resolveHere(issue) {
    if (isOpen) closeList();
    if (!SC.draftChange(issue.change)) { fixWith(issue); return; }
    SC.toast(issue.kind === 'question' ? t('Type your answer, then press Enter') : t('Edit the request if you like, then press Enter'));
  }
  function fixWith(issue) {
    SC.modal({
      title: t('{} with {}', FIX, A.name),
      html: `<p class="hc-hint">${t('Copy this request and paste it into')} <b>${A.app}</b>${t(
        ', opened in your project folder. It explains what to change and asks before anything risky.')}</p><pre>${h(issue.fix)}</pre>`,
      actions: [{ label: t('Copy prompt'), primary: true, icon: 'copy', onClick: () => { SC.copy(issue.fix); SC.toast(t('Copied. Paste it into {}.', A.app)); } }],
    });
  }
  const onMap = (issue) => (issue.items || []).some((id) => SC.exists(id));

  // ---------- html ----------
  const locText = (issue) => {
    const locs = issue.locations || [];
    if (!SC.technical() || !locs.length) return '';
    const shown = locs.slice(0, 3).map((l) => `${l.file}${l.line > 1 ? ':' + l.line : ''}`);
    return `<div class="hc-w">${shown.map(h).join('<br>')}${locs.length > 3 ? `<br>${t('+{} more', locs.length - 3)}` : ''}</div>`;
  };
  const issueHtml = (issue, idx, note) => `<div class="hc-issue">
      <div class="hc-t"><span class="dot" style="background:${SEV[issue.severity].color}"></span><span>${h(t.constat(issue.title))}</span></div>
      ${note ? `<div class="hc-n">${h(t.constat(note))}</div>` : `<div class="hc-d">${h(t.constat(issue.detail))}</div>`}
      ${locText(issue)}
      <div class="hc-a">
        ${onMap(issue) ? `<button class="btn soft" data-hc-show="${idx}">${SC.iconI('search')}${t('Show on map')}</button>` : ''}
        ${SC.exported ? '' : here(issue) ? `<button class="btn soft" data-hc-here="${idx}">${SC.iconI('spark')}${t('Resolve on the map')}</button>` : `<button class="btn soft" data-hc-fix="${idx}">${SC.iconI('spark')}${t('{} with {}', FIX, A.name)}</button>`}
      </div>
    </div>`;
  const bindIssues = (el) => {
    el.querySelectorAll('[data-hc-show]').forEach((b) => b.addEventListener('click', (ev) => { ev.stopPropagation(); showOnMap(issues[+b.dataset.hcShow]); }));
    el.querySelectorAll('[data-hc-fix]').forEach((b) => b.addEventListener('click', (ev) => { ev.stopPropagation(); fixWith(issues[+b.dataset.hcFix]); }));
    el.querySelectorAll('[data-hc-here]').forEach((b) => b.addEventListener('click', (ev) => { ev.stopPropagation(); resolveHere(issues[+b.dataset.hcHere]); }));
  };
  const headline = () => urgent ? t('{} need{} attention', t.pl(total, 'thing'), total === 1 ? 's' : '')
    : issues.length ? t('Nothing urgent') : t('No problems found');
  const breakdown = () => `<div class="hc-sub">${ORDER.filter(count).map((s) => `<span><i class="dot" style="background:${SEV[s].color}"></i>${SEV[s].word(count(s))}</span>`).join('')}</div>`;

  function listHtml() {
    const top = `<div class="sec">
        <div class="ph"><span class="ico" style="--c:${urgent ? SEV[count('high') ? 'high' : 'medium'].color : 'var(--ok)'}">${SC.icon('health')}</span><span class="kindlabel">${PLAN ? 'Design review' : t('Health check')}</span></div>
        <h2 class="pt">${h(headline())}</h2>
        <p class="pd">${PLAN ? 'We checked the plan for parts anyone on the internet could use, decisions the PRD leaves open, and pieces nothing connects to. Settling these now is cheaper than after it’s built.' : t('We looked for keys left in the code or sent to the browser, data and parts of your app anyone on the internet can reach, leftover files and files too big to edit safely. It’s a quick check, not a security audit.')}</p>
        ${!PLAN && services.length ? `<p class="pd">${h(t('Checks specific to what this project uses: {}.', services.join(', ')))}</p>` : ''}
        ${issues.length ? breakdown() : `<div class="hc-calm">${PLAN ? t('Nothing stood out. This is a quick automatic check, not a full design review.')
          : t('Nothing stood out. This is a quick automatic check, not a full security review.')}</div>`}
        <div class="actions"><button class="btn soft" data-hc-back>${SC.iconI('left')}${t('Back')}</button></div>
      </div>`;
    const groups = ORDER.map((sev) => {
      const list = issues.map((i, idx) => [i, idx]).filter(([i]) => i.severity === sev);
      return list.length ? `<div class="sec"><h3>${h(SEV[sev].group)} <span class="c">${list.length}</span></h3>${list.map(([i, idx]) => issueHtml(i, idx)).join('')}</div>` : '';
    }).join('');
    const foot = !issues.length ? '' : SC.exported ? `<div class="sec" style="color:var(--text-3);font-size:12px;line-height:1.6">${t('These are automatic hints from when this copy was exported.')}</div>` : `<div class="sec" style="color:var(--text-3);font-size:12px;line-height:1.6">${t('These are automatic hints. {}', issues.some(here)
      ? `“Resolve on the map” puts a request in the Ask bar’s Change mode: finish or edit it, press Enter, and ${A.name} updates the plan and redraws the map. Undo puts it back.`
      : t('“{} with {}” gives you a request to paste into {}; {}.', FIX, A.name, A.app,
        PLAN ? 'it explains the choice and updates the plan once you decide' : t('it checks the code before changing anything')))}</div>`;
    return top + groups + foot;
  }
  function openList() {
    isOpen = true;
    openedAt = where();
    SC.showPanel(listHtml(), (panel) => {
      panel.querySelector('[data-hc-back]')?.addEventListener('click', closeList);
      bindIssues(panel);
    });
  }

  // ---------- chrome ----------
  const btn = SC.addHeaderButton({
    id: 'btn-health', label: PLAN ? 'Review' : t('Health'), icon: urgent ? 'health' : 'check',
    title: `${PLAN ? 'Design review' : t('Health check')}${t.langue ? ' : ' : ': '}${urgent ? headline() : t('nothing urgent')}`,
    onClick: () => (isOpen ? closeList() : openList()),
  });
  if (urgent) {
    const b = document.createElement('span');
    b.className = 'badge';
    b.textContent = total > 99 ? '99+' : String(total);
    btn.style.setProperty('--hc-badge', count('high') ? SEV.high.color : SEV.medium.color);
    btn.style.setProperty('--hc-badge-text', 'var(--on-sev-text)');
    btn.appendChild(b);
  } else btn.classList.add('calm');
  btn.setAttribute('aria-label', btn.title); // keeps its name, with the count, when only the icon shows

  // Selecting something else on the map while the list is open shows that item instead.
  SC.on('panel', () => { if (isOpen && openedAt && where() !== openedAt) { isOpen = false; SC.closePanel(); } });

  SC.addPanelSection('overview', () => ({
    html: `<div class="sec"><h3>${PLAN ? 'Design review' : SECTION}</h3><div class="list"><a class="row" data-hc-open>
        <span class="dot" style="background:${urgent ? SEV[count('high') ? 'high' : 'medium'].color : 'var(--ok)'}"></span>
        <span class="rt"><div class="rn">${h(headline())}</div><div class="rd">${issues.length ? ORDER.filter(count).map((s) => SEV[s].word(count(s))).join(' · ')
          : PLAN ? 'Quick automatic check of the plan' : t('Quick automatic check of secrets, open endpoints and leftover files')}</div></span>
        <span class="rc">${SC.iconI('right')}</span></a></div></div>`,
    bind: (el) => el.querySelector('[data-hc-open]')?.addEventListener('click', (ev) => { ev.preventDefault(); openList(); }),
  }));

  SC.addPanelSection('item', (itemId) => {
    if (!itemId || typeof itemId !== 'string' || !issues.length) return '';
    const hits = [];
    issues.forEach((issue, idx) => {
      const inside = (issue.items || []).filter((id) => id === itemId || (SC.exists(id) && SC.chain(id).includes(itemId)));
      if (!inside.length) return;
      const exact = issue.notes && inside.includes(itemId) ? issue.notes[itemId] : '';
      hits.push(issueHtml(issue, idx, exact || (inside.length > 1 || inside[0] !== itemId ? t('Affects {} in here', t.pl(inside.length, 'place')) : '')));
    });
    if (!hits.length) return '';
    return { html: `<div class="sec"><h3>${PLAN ? 'Design review' : t('Health')} <span class="c">${hits.length}</span></h3>${hits.slice(0, 6).join('')}${hits.length > 6 ? `<div class="more" data-hc-open style="cursor:pointer">${t('+{} more in the {}', hits.length - 6, PLAN ? 'design review' : t('health check'))}</div>` : ''}</div>`, bind: (el) => { bindIssues(el); el.querySelector('[data-hc-open]')?.addEventListener('click', openList); } };
  });
})();
