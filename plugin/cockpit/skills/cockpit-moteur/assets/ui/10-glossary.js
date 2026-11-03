// floorplan glossary: explains the technical words a non-developer meets on the map.
// The first time a known term appears in a description (details panel, board title area), it gets a
// dotted underline; hovering or focusing it shows a one-sentence explanation. Off while
// "Show technical detail" is on. Talks to the viewer only through window.Floorplan.
(() => {
  const SC = window.Floorplan;
  if (!SC) return;

  // [display name, plain explanation, aliases...]. Aliases are matched as whole words, ignoring case,
  // except those marked with a leading "=" (matched exactly, so "REST" doesn't fire on "the rest").
  const TERMS = [
    ['API', 'The way programs talk to each other: one asks for something (prices, an order) and the other answers.', 'API', 'APIs', 'API client'],
    ['Endpoint', 'One specific request the app can receive, like "mark this order shipped"; each has its own web address.', 'endpoint', 'endpoints'],
    ['Webhook', 'A message another service sends your app automatically when something happens there, like "a payment went through".', 'webhook', 'webhooks'],
    ['Server', 'A computer in the cloud that runs your app\'s behind-the-scenes work and answers requests from the screens.', 'server', 'servers', 'main server'],
    ['Frontend', 'The part of the app people see and click: the screens, buttons and forms in the browser.', 'frontend', 'front end', 'front-end'],
    ['Backend', 'The behind-the-scenes part of the app that stores the records, applies the rules and talks to other services.', 'backend', 'back end', 'back-end'],
    ['Database', 'Where the app keeps its records (products, orders, customers) so nothing is lost when it restarts.', 'database', 'databases', 'DB'],
    ['Record', 'One saved entry in the database, like a single order or customer; a table is the list of all records of one kind.', 'database record', 'database records', 'database table', 'database tables'],
    ['Model', 'In code, a model describes how one kind of record (an order, a customer) is stored in the database.', 'model', 'models', 'ORM', 'ORM model', 'ORM models', 'data model'],
    ['Query', 'A question the app asks the database, like "all orders from today that haven\'t shipped".', 'query', 'queries'],
    ['Queue', 'A waiting line of tasks; work is dropped in and handled one by one in the background so nothing gets lost.', 'queue', 'queues', 'queued', 'outbox', 'message queue'],
    ['Background job', 'A task that runs on its own behind the scenes, so people don\'t have to wait for it on screen.', 'background job', 'background jobs', 'background task', 'background tasks', 'worker', 'workers'],
    ['Scheduled job', 'A task that runs automatically on a timetable, like every hour or every night.', 'cron', 'cron job', 'cron jobs', 'scheduled job', 'scheduled jobs', 'scheduler'],
    ['Environment variable', 'A setting stored outside the code, such as which database or account to use, so it can differ between test and live.', 'environment variable', 'environment variables', 'env var', 'env vars', '.env'],
    ['Secret', 'A password or key the app uses to sign in to another service; it must never be shared or put in the code.', 'secret', 'secrets', 'API key', 'API keys', 'credentials'],
    ['Deploy', 'Putting a new version of the app live so people start using it.', 'deploy', 'deploys', 'deployed', 'deployment', 'deployments'],
    ['Migration', 'A one-time change to how records are stored, like adding a new field to every order.', 'migration', 'migrations'],
    ['Cache', 'A saved copy of something kept close by so it loads faster instead of being worked out again.', 'cache', 'cached', 'caching'],
    ['Sign-in', 'Checking who someone is (usually with a password) before letting them in.', 'auth', 'authentication', 'login', 'log in', 'sign-in', 'sign in'],
    ['Permissions', 'The rules for who is allowed to do what, like only managers issuing refunds.', 'permissions', 'authorization', 'roles', 'RBAC'],
    ['Session', 'How the app remembers you are signed in, so you don\'t have to type your password on every screen.', 'session', 'sessions'],
    ['Token', 'A temporary digital pass the app hands out after sign-in and checks on every request.', 'token', 'tokens', 'bearer token', 'access token'],
    ['SDK', 'A ready-made kit of code a company provides so apps can talk to its service more easily.', 'SDK', 'SDKs'],
    ['Repository', 'The folder that holds all of a project\'s code and its full history of changes.', 'repository', 'repositories', 'repo', 'repos'],
    ['Component', 'A reusable building block of the screens, like a button, a table or a whole product editor.', 'component', 'components'],
    ['Route', 'A web address the app answers: on the screens it\'s a page, on the server it\'s a kind of request.', 'route', 'routes', 'routing', 'App Router'],
    ['Request', 'A message asking the server to do or fetch something; the server sends back a response with the result.', 'request', 'requests', 'response', 'responses'],
    ['JSON', 'A simple text format programs use to send data to each other, like a labelled list.', 'JSON'],
    ['REST', 'A common style for building APIs, where each web address stands for a kind of thing (orders, products).', '=REST', '=RESTful'],
    ['HTTP method', 'The kind of request: GET reads something, POST creates, PUT or PATCH changes, DELETE removes.', 'HTTP method', 'HTTP methods', '=GET', '=POST', '=PUT', '=PATCH', '=DELETE'],
    ['HTTP', 'The language browsers and servers use to talk over the web; HTTPS is the encrypted version.', 'HTTP', 'HTTPS'],
    ['CDN', 'A network of servers around the world that delivers images and files quickly from somewhere near the visitor.', 'CDN', 'CDNs'],
    ['Storage bucket', 'Cloud file storage for things like product images, uploads and exports.', 'storage bucket', 'bucket', 'buckets', 'S3', 'GCS', 'Cloud Storage'],
    ['Pub/Sub', 'Google\'s message service: one part of the app posts an event and others pick it up to handle in the background.', 'Pub/Sub', 'PubSub'],
    ['MCP', 'A standard way to connect AI assistants (like Claude or ChatGPT) to an app so they can look things up in it.', 'MCP', 'MCP server', 'Model Context Protocol'],
    ['Next.js', 'A popular toolkit for building websites and web apps with React.', 'Next.js', 'NextJS'],
    ['React', 'A popular library for building interactive screens out of reusable pieces.', '=React'],
    ['Flask', 'A Python toolkit for building web servers.', 'Flask'],
    ['SQLAlchemy', 'A Python toolkit that lets the code read and save database records without writing raw database commands.', 'SQLAlchemy'],
    ['Postgres', 'A widely used database; RDS and Cloud SQL are Amazon\'s and Google\'s hosted versions of it.', 'Postgres', 'PostgreSQL', 'RDS', 'Cloud SQL'],
    ['Docker', 'A way to package an app with everything it needs so it runs the same on any computer or cloud.', 'Docker', 'container', 'containers'],
    ['Cloud Run', 'Google\'s service for running an app\'s servers and background jobs in the cloud without managing machines.', 'Cloud Run'],
    ['Middleware', 'A check every request passes through on its way in, such as "is this person signed in?".', 'middleware'],
    ['Blueprint', 'In Flask, a group of related requests bundled together, like all the order requests.', 'blueprint', 'blueprints'],
    ['Tests', 'Automatic checks that the code still does what it should, run before changes go live.', 'test suite', 'unit test', 'unit tests', 'pytest', 'Vitest'],
    ['Script', 'A small program run by hand for a one-off job, like fixing or importing data.', 'script', 'scripts'],
    ['OAuth', 'The standard behind "Sign in with…" buttons: it lets one app use another on your behalf without sharing your password.', 'OAuth'],
  ];

  const exact = new Map(), loose = new Map(), alts = [];
  TERMS.forEach(([name, text, ...aliases], i) => {
    for (let a of aliases) {
      const strict = a.startsWith('=');
      if (strict) a = a.slice(1);
      (strict ? exact : loose).set(strict ? a : a.toLowerCase(), i);
      alts.push(a);
    }
  });
  const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  alts.sort((a, b) => b.length - a.length);
  const RE = new RegExp(`(?<![\\w./-])(?:${alts.map(esc).join('|')})(?![\\w/]|-\\w|\\.\\w)`, 'gi');
  const termOf = (m) => exact.has(m) ? exact.get(m) : loose.has(m.toLowerCase()) ? loose.get(m.toLowerCase()) : -1;

  // Where to look, and what to leave alone.
  const TARGETS = '.pd, .rd, .callout';
  const SKIP = 'a[href], button, code, pre, kbd, samp, input, textarea, select, [contenteditable], .tag, .rp, .pp, .method, .kbd, .sc-term, [data-noglossary]';
  const CLICKABLE = 'a, [data-go], [data-sel], [data-flow], [data-open], [role="button"]';
  const isMono = (el) => /mono|monospace/i.test(el.style?.fontFamily || '');

  function annotate(scope, targets) {
    if (!scope || SC.technical()) return;
    const used = new Set([...scope.querySelectorAll('.sc-term')].map((s) => +s.dataset.term)); // max one per term per scope
    const skipped = (from, stop) => { for (let p = from; p && p !== stop; p = p.parentElement) if (p.matches(SKIP) || isMono(p)) return true; return false; };
    for (const el of targets) {
      if (skipped(el, scope)) continue;
      const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT, {
        acceptNode: (t) => !t.nodeValue.trim() || skipped(t.parentElement, el) ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_ACCEPT,
      });
      const texts = [];
      while (walker.nextNode()) texts.push(walker.currentNode);
      for (const t of texts) wrapIn(t, used);
    }
  }
  function wrapIn(textNode, used) {
    let node = textNode;
    while (node) {
      RE.lastIndex = 0;
      let m, hit = null;
      while ((m = RE.exec(node.nodeValue))) {
        const i = termOf(m[0]);
        if (i >= 0 && !used.has(i)) { hit = { m, i }; break; }
      }
      if (!hit) return;
      used.add(hit.i);
      const word = node.splitText(hit.m.index);
      const rest = word.splitText(hit.m[0].length);
      const span = document.createElement('span');
      span.className = 'sc-term';
      span.dataset.term = String(hit.i);
      if (!word.parentElement.closest(CLICKABLE)) span.tabIndex = 0; // inside clickable rows: hover only, clicks pass through
      word.replaceWith(span);
      span.appendChild(word);
      node = rest;
    }
  }
  function strip(scope) {
    if (!scope) return;
    for (const s of scope.querySelectorAll('.sc-term')) s.replaceWith(...s.childNodes);
    scope.normalize();
  }

  const panelEl = () => document.getElementById('panel');
  const contextEl = () => document.getElementById('context');
  const doPanel = () => { const p = panelEl(); if (p) annotate(p, p.querySelectorAll(TARGETS)); };
  const doContext = () => { const c = contextEl(); if (c) annotate(c, c.querySelectorAll('p, .callout')); };

  // Run after the viewer and any other extension listeners have finished filling the DOM.
  SC.on('panel', () => { hide(true); queueMicrotask(doPanel); });
  SC.on('render', () => { hide(true); queueMicrotask(doContext); });
  SC.on('technical', (on) => {
    hide(true);
    if (on) { strip(panelEl()); strip(contextEl()); }
    else { queueMicrotask(() => { strip(panelEl()); strip(contextEl()); doPanel(); doContext(); }); }
  });

  // ---------- popover ----------
  const style = document.createElement('style');
  style.textContent = `
.sc-term { pointer-events: auto; cursor: help; border-radius: 4px; text-decoration-line: underline; text-decoration-style: dotted; text-decoration-thickness: 1px; text-underline-offset: 3px;
  text-decoration-color: rgba(var(--ink), .32); text-decoration-color: color-mix(in srgb, currentColor 45%, transparent); transition: text-decoration-color .2s var(--ease), color .2s var(--ease); }
.sc-term:hover, .sc-term.on { text-decoration-color: currentColor; color: var(--text); }
.callout .sc-term:hover, .callout .sc-term.on { color: inherit; }
.sc-term:focus { outline: none; }
.sc-term:focus-visible { box-shadow: 0 0 0 2px var(--focus); }
#sc-gloss { position: fixed; left: 0; top: 0; z-index: 55; max-width: 280px; padding: 11px 13px; border-radius: 14px; font-size: 12.5px; line-height: 1.5; color: var(--text-2);
  pointer-events: none; opacity: 0; transform: translateY(3px); transition: opacity .15s var(--ease), transform .25s var(--ease); }
#sc-gloss.on { opacity: 1; transform: none; }
#sc-gloss b { display: block; color: var(--text); font-weight: 600; margin-bottom: 2px; }`;
  document.head.appendChild(style);

  const pop = document.createElement('div');
  pop.id = 'sc-gloss';
  pop.className = 'glass';
  pop.setAttribute('role', 'tooltip');
  document.body.appendChild(pop);

  let current = null, showT = 0, hideT = 0;
  function show(el) {
    clearTimeout(hideT);
    if (current === el) return;
    const term = TERMS[+el.dataset.term];
    if (!term) return;
    current?.classList.remove('on'); current?.removeAttribute('aria-describedby');
    current = el;
    el.classList.add('on');
    el.setAttribute('aria-describedby', 'sc-gloss');
    pop.innerHTML = `<b>${SC.h(term[0])}</b>${SC.h(term[1])}`;
    const r = el.getClientRects()[0] || el.getBoundingClientRect();
    const pw = pop.offsetWidth, ph = pop.offsetHeight, gap = 8;
    const x = Math.max(12, Math.min(r.left, innerWidth - pw - 12));
    const below = r.bottom + gap + ph <= innerHeight - 12;
    const y = below ? r.bottom + gap : Math.max(12, r.top - gap - ph);
    pop.style.left = `${Math.round(x)}px`;
    pop.style.top = `${Math.round(y)}px`;
    pop.classList.add('on');
  }
  function hide(now) {
    clearTimeout(showT); clearTimeout(hideT);
    const go = () => { pop.classList.remove('on'); current?.classList.remove('on'); current?.removeAttribute('aria-describedby'); current = null; };
    if (now === true) go(); else hideT = setTimeout(go, 90);
  }
  const termAt = (ev) => ev.target instanceof Element ? ev.target.closest('.sc-term') : null;
  document.addEventListener('mouseover', (ev) => { const t = termAt(ev); if (!t) return; clearTimeout(showT); showT = setTimeout(() => show(t), current ? 0 : 140); });
  document.addEventListener('mouseout', (ev) => { const t = termAt(ev); if (t && !t.contains(ev.relatedTarget)) { clearTimeout(showT); hide(); } });
  document.addEventListener('focusin', (ev) => { const t = termAt(ev); if (t) show(t); });
  document.addEventListener('focusout', (ev) => { if (termAt(ev)) hide(); });
  document.addEventListener('keydown', (ev) => { if (ev.key === 'Escape' && current) hide(true); });
  document.addEventListener('scroll', () => { if (current) hide(true); }, true);
  addEventListener('resize', () => { if (current) hide(true); });

  // initial pass, in case the first render/panel happened before this script ran
  if (document.readyState !== 'loading') queueMicrotask(() => { doPanel(); doContext(); });
})();
