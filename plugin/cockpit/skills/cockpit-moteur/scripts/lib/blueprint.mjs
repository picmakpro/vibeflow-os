// Blueprints: a floorplan of a system that hasn't been built yet, planned from a PRD or a description.
//
// planToScan(plan, root) — turns floorplan/plan.json (the planned files, endpoints and calls, written by
//                          the agent) into the same scan.json shape scan.mjs writes for real code, so
//                          build.mjs and the viewer work unchanged. Returns { scan, errors, warnings }.
// buildPlanHealth(ctx)   — called by build.mjs instead of buildHealth for a blueprint: a design review of
//                          the plan (who may call each endpoint, loose ends, open questions) in the same
//                          { summary, issues } shape, so the Health panel shows it.

import path from 'node:path';
import { classify, toPosix } from './common.mjs';
import { matchCalls } from './routes.mjs';

// who may use an endpoint. "team" is the people who run the service (its own admin pages), not the app's users.
export const ACCESS = ['public', 'signed-in', 'team', 'webhook', 'internal'];
const METHODS = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'CALL', 'ANY'];
const WRITE = new Set(['POST', 'PUT', 'PATCH', 'DELETE', 'CALL']);
const isStr = (v) => typeof v === 'string' && v.trim().length > 0;
const strArr = (v) => (Array.isArray(v) ? v.filter(isStr) : []);
const routeKey = (m, p) => `${m} ${p}`;

/** "POST /api/orders" -> { method, path }, or null. */
export function parseCall(s) {
  const m = /^\s*([A-Za-z]+)\s+(\/\S*)\s*$/.exec(String(s || ''));
  return m && METHODS.includes(m[1].toUpperCase()) ? { method: m[1].toUpperCase(), path: m[2] } : null;
}

export function planToScan(plan, root) {
  const errors = [], warnings = [];
  const err = (m) => errors.push(m), warn = (m) => warnings.push(m);
  if (!plan || typeof plan !== 'object') return { scan: null, errors: ['plan.json must be an object'], warnings };
  const files = Array.isArray(plan.files) ? plan.files : [];
  const endpoints = Array.isArray(plan.endpoints) ? plan.endpoints : [];
  if (!files.length) err('files must be a non-empty array of the files the system would have');

  const byPath = new Map();
  files.forEach((f, i) => {
    const where = `files[${i}]${f?.path ? ` ("${f.path}")` : ''}`;
    if (!isStr(f?.path)) return err(`${where}.path is required`);
    const p = toPosix(f.path.trim()).replace(/^\.\//, '');
    if (p.startsWith('/') || p.includes('..')) return err(`${where}.path must be relative to the project folder`);
    if (byPath.has(p)) return err(`${where}.path duplicates an earlier file`);
    if (!isStr(f.description)) warn(`${where} has no description`);
    byPath.set(p, f);
  });
  const known = [...byPath.keys()];
  const near = (p) => { const base = p.split('/').pop(); const hit = known.find((k) => k.split('/').pop() === base); return hit ? ` (did you mean "${hit}"?)` : ''; };

  // endpoints, keyed by "METHOD /path"
  const routes = [], access = {}, seen = new Set();
  endpoints.forEach((e, i) => {
    const where = `endpoints[${i}]${e?.method && e?.path ? ` ("${e.method} ${e.path}")` : ''}`;
    const method = String(e?.method || '').toUpperCase();
    if (!METHODS.includes(method)) return err(`${where}.method must be one of ${METHODS.join(', ')}`);
    if (!isStr(e.path) || !e.path.startsWith('/')) return err(`${where}.path must start with "/"`);
    if (!isStr(e.file)) return err(`${where}.file is required: the planned file that handles it`);
    const file = toPosix(e.file.trim()).replace(/^\.\//, '');
    if (!byPath.has(file)) return err(`${where}.file "${file}" is not one of the planned files${near(file)}`);
    const key = routeKey(method, e.path);
    if (seen.has(key)) return err(`${where} duplicates an earlier endpoint`);
    seen.add(key);
    if (e.access !== undefined && !ACCESS.includes(e.access)) err(`${where}.access "${e.access}" must be one of ${ACCESS.join(', ')}${e.access === 'staff' ? ' ("team" is your own team; for some of the app’s users, use "signed-in" with "who")' : ''}`);
    if (e.who !== undefined && !isStr(e.who)) err(`${where}.who must be a few words, e.g. "managers of that location"`);
    if (e.publicBecause !== undefined && !isStr(e.publicBecause)) err(`${where}.publicBecause must say why it is open to anyone`);
    if (ACCESS.includes(e.access)) access[key] = e.access;
    routes.push({ file, method, path: e.path, line: 0, ...(ACCESS.includes(e.access) ? { access: e.access } : {}), ...(isStr(e.who) ? { who: e.who.trim() } : {}), ...(isStr(e.publicBecause) ? { publicBecause: e.publicBecause.trim() } : {}), ...(isStr(e.name) ? { name: e.name.trim() } : {}), ...(isStr(e.description) ? { desc: e.description.trim() } : {}) });
  });
  const routeKeys = new Set(routes.map((r) => routeKey(r.method, r.path)));

  // imports, calls, and links to outside services and data stores
  const edges = [], nodeLinks = [], callFiles = [];
  for (const [p, f] of byPath) {
    for (const u of strArr(f.uses)) {
      const to = toPosix(u.trim()).replace(/^\.\//, '');
      if (!byPath.has(to)) { err(`files "${p}".uses "${u}" is not one of the planned files${near(to)}`); continue; }
      if (to !== p) edges.push({ from: p, to });
    }
    const calls = [];
    for (const c of strArr(f.calls)) {
      const pc = parseCall(c);
      if (!pc) { err(`files "${p}".calls "${c}" must look like "POST /api/orders"`); continue; }
      if (!routeKeys.has(routeKey(pc.method, pc.path))) warn(`files "${p}".calls "${c}" matches no planned endpoint`);
      calls.push({ path: pc.path, method: pc.method, line: 0 });
    }
    if (calls.length) callFiles.push({ path: p, calls });
    for (const s of strArr(f.services)) nodeLinks.push({ from: p, to: s.trim(), kind: 'http' });
    for (const d of strArr(f.data)) nodeLinks.push({ from: p, to: d.trim(), kind: 'data' });
  }
  // calls only reach the exact planned endpoint (method and path), never a near miss
  const http = matchCalls(callFiles, routes).filter((h) => routeKeys.has(routeKey(h.method, h.path)) && h.call === h.path);

  const questions = [];
  (Array.isArray(plan.questions) ? plan.questions : []).forEach((q, i) => {
    const text = isStr(q) ? q : q?.question;
    if (!isStr(text)) return err(`questions[${i}] needs a question`);
    questions.push({ question: text.trim(), about: strArr(q?.about) });
  });

  const scan = {
    version: 1,
    blueprint: {
      source: isStr(plan.source) ? plan.source.trim() : '',
      stack: strArr(plan.stack),
      assumptions: strArr(plan.assumptions),
      questions,
      access,
    },
    generatedAt: new Date().toISOString(),
    root: toPosix(root),
    rootName: path.basename(root),
    repos: [],
    files: [...byPath].map(([p, f]) => {
      const c = classify(p, 0);
      return {
        path: p, repo: null, category: 'code', lang: c.lang || path.posix.extname(p).slice(1) || null, loc: 0, bytes: 0,
        ...(isStr(f.name) ? { name: f.name.trim() } : {}),
        ...(isStr(f.description) ? { desc: f.description.trim() } : {}),
        ...(isStr(f.screen) && f.screen.startsWith('/') ? { screens: [{ fw: 'plan', url: f.screen.trim() }] } : {}),
      };
    }),
    edges,
    externals: [],
    extEdges: [],
    routes,
    http,
    hosts: [],
    nodeLinks,
  };
  return { scan, errors, warnings };
}

/** The design review shown in the Health panel for a blueprint. */
export function buildPlanHealth({ graph, scan }) {
  const bp = scan.blueprint || {};
  const issues = [];
  const routes = graph.routes || [];
  const ridOf = new Map(routes.map((r, i) => [routeKey(r.m, r.p), 'r:' + i]));
  const fileIds = new Set(graph.files.map((f) => 'f:' + f.p));
  const nodeIds = new Set(graph.nodes.map((n) => 'n:' + n.id));
  const refOf = (s) => {
    if (!isStr(s)) return null;
    const t = s.trim();
    if (nodeIds.has('n:' + t)) return 'n:' + t;
    if (fileIds.has('f:' + t)) return 'f:' + t;
    const pc = parseCall(t);
    return pc ? ridOf.get(routeKey(pc.method, pc.path)) || null : null;
  };
  const line = (r) => `- ${r.m} ${r.p} (${r.f})${r.name ? ` — ${r.name}` : ''}`;
  const rebuild = 'Then rebuild the blueprint: run plan.mjs and build.mjs from the Floorplan skill, as its instructions say.';
  // each item also carries `change`: a request to settle it from the map (the Ask bar's Change mode), for the person to finish or edit
  const names = (xs, max = 6) => { const l = xs.slice(0, max).concat(xs.length > max ? [`${xs.length - max} more`] : []); return l.length < 2 ? l.join('') : `${l.slice(0, -1).join(', ')} and ${l.at(-1)}`; };
  const ep = (r) => `${r.m} ${r.p}`;

  // ---------- who may call each endpoint ----------
  const accessOf = (r) => bp.access?.[routeKey(r.m, r.p)];
  // open on purpose, with a reason (publicBecause), counts as reviewed
  const openWrites = routes.map((r, i) => ({ r, i })).filter(({ r }) => accessOf(r) === 'public' && WRITE.has(r.m) && !r.publicBecause);
  if (openWrites.length) issues.push({
    id: 'plan-open-writes', kind: 'unprotected-endpoint', severity: 'medium',
    change: `Review who may use ${names(openWrites.map(({ r }) => ep(r)))}: anyone can change data through ${openWrites.length === 1 ? 'it' : 'them'} now. `,
    title: openWrites.length === 1 ? 'Anyone could change data through one planned endpoint' : `Anyone could change data through ${openWrites.length} planned endpoints`,
    detail: `The plan lets ${openWrites.length === 1 ? 'this endpoint' : 'these endpoints'} create, change or delete data with no sign-in. That's right for things like signing up or a guest checkout, but worth a second look before building: ${openWrites.length === 1 ? 'it is' : 'they are'} the easiest thing for a stranger to misuse.`,
    items: openWrites.slice(0, 24).map(({ i }) => 'r:' + i),
    notes: Object.fromEntries(openWrites.slice(0, 24).map(({ i }) => ['r:' + i, 'Planned as open to anyone, and changes data'])),
    locations: [],
    fix: [`Design review of floorplan/plan.json: these planned endpoints change data and are marked "access": "public":`, ...openWrites.map(({ r }) => line(r)), ``, `For each one, tell me in plain words whether a stranger should really be able to use it. Where they shouldn't, change its access to "signed-in" (with "who" if only some users may) in plan.json. Where it must stay public (sign-in, sign-up, guest checkout), set "publicBecause" to why, including what limits abuse (rate limits, a CAPTCHA, email confirmation). Ask me if you're unsure.`, rebuild].join('\n'),
  });
  const unknown = routes.map((r, i) => ({ r, i })).filter(({ r }) => !accessOf(r));
  if (unknown.length) issues.push({
    id: 'plan-no-access', kind: 'unprotected-endpoint', severity: 'medium',
    change: `Decide who may use ${names(unknown.map(({ r }) => ep(r)))}, going by the PRD. `,
    title: unknown.length === 1 ? 'The plan doesn’t say who may use one endpoint' : `The plan doesn’t say who may use ${unknown.length} endpoints`,
    detail: `Deciding who can use each part of the system now (anyone, signed-in customers, only managers, your own team, another service) is much easier than adding sign-in checks after it's built.`,
    items: unknown.slice(0, 24).map(({ i }) => 'r:' + i),
    notes: Object.fromEntries(unknown.slice(0, 24).map(({ i }) => ['r:' + i, 'Who may use this isn’t decided'])),
    locations: [],
    fix: [`Design review of floorplan/plan.json: these planned endpoints have no "access" set:`, ...unknown.map(({ r }) => line(r)), ``, `For each, choose who may use it: "public" (anyone), "signed-in" (plus "who" when only some users may, such as "managers of that location"), "team" (only the people who run the service), "webhook" (another company's service, which must prove it's them) or "internal" (only our own services). Base it on the PRD; ask me where the PRD doesn't say.`, rebuild].join('\n'),
  });

  // ---------- open questions from the PRD ----------
  bp.questions?.forEach((q, k) => {
    const items = [...new Set(q.about.map(refOf).filter(Boolean))];
    issues.push({
      id: 'plan-question:' + k, kind: 'question', severity: 'medium',
      change: `Open question: "${q.question}" My answer: `,
      title: q.question,
      detail: 'The PRD doesn’t answer this, and the answer changes what gets built. Decide it before building the parts it touches.',
      items, notes: Object.fromEntries(items.map((id) => [id, 'Depends on an open question'])),
      locations: [],
      fix: [`Open question in the blueprint (floorplan/plan.json): ${q.question}`, ``, `Explain the options to me in plain words, with what each would mean for the parts it touches${q.about.length ? ` (${q.about.join(', ')})` : ''}, and recommend one. After I decide, update plan.json and architecture.json to match and remove the question from plan.json's questions.`, rebuild].join('\n'),
    });
  });

  // ---------- loose ends ----------
  const called = new Set(graph.links.filter((l) => l.k === 'http' && l.calls).flatMap((l) => l.calls.map(([ri]) => ri)));
  const unusedRoutes = routes.map((r, i) => ({ r, i })).filter(({ r, i }) => !called.has(i) && !['webhook', 'internal', 'public'].includes(accessOf(r)));
  if (unusedRoutes.length) issues.push({
    id: 'plan-unused-endpoints', kind: 'unused-file', severity: 'low',
    change: `Nothing calls ${names(unusedRoutes.map(({ r }) => ep(r)))}. Add the screen or service that should use ${unusedRoutes.length === 1 ? 'it' : 'them'}, or remove ${unusedRoutes.length === 1 ? 'it' : 'them'} if not needed. `,
    title: unusedRoutes.length === 1 ? 'Nothing in the plan uses one endpoint' : `Nothing in the plan uses ${unusedRoutes.length} endpoints`,
    detail: `No planned page or service calls ${unusedRoutes.length === 1 ? 'it' : 'them'}. Either a screen that needs ${unusedRoutes.length === 1 ? 'it is' : 'them is'} missing from the plan, or ${unusedRoutes.length === 1 ? 'it isn’t' : 'they aren’t'} needed.`,
    items: unusedRoutes.slice(0, 24).map(({ i }) => 'r:' + i),
    notes: Object.fromEntries(unusedRoutes.slice(0, 24).map(({ i }) => ['r:' + i, 'No planned caller'])),
    locations: [],
    fix: [`Design review of floorplan/plan.json: nothing in the plan calls these endpoints:`, ...unusedRoutes.map(({ r }) => line(r)), ``, `For each, find which planned screen or service should call it and add it to that file's "calls", or tell me it isn't needed and remove it.`, rebuild].join('\n'),
  });
  const linked = new Set();
  for (const l of graph.links) { linked.add(l.a); linked.add(l.b); }
  const screenFiles = new Set((graph.screens || []).map((s) => s.file));
  const routeFiles = new Set(routes.map((r) => r.f));
  const loose = graph.files.filter((f) => !linked.has('f:' + f.p) && !screenFiles.has(f.p) && !routeFiles.has(f.p));
  if (loose.length) issues.push({
    id: 'plan-loose-files', kind: 'unused-file', severity: 'low',
    change: `${names(loose.map((f) => f.p))} ${loose.length === 1 ? 'isn’t' : 'aren’t'} connected to anything. Connect ${loose.length === 1 ? 'it' : 'them'} to what should use ${loose.length === 1 ? 'it' : 'them'}, or remove ${loose.length === 1 ? 'it' : 'them'}. `,
    title: loose.length === 1 ? 'One planned file isn’t connected to anything' : `${loose.length} planned files aren’t connected to anything`,
    detail: `Nothing in the plan uses ${loose.length === 1 ? 'it' : 'them'}, and ${loose.length === 1 ? 'it doesn’t' : 'they don’t'} use anything. That usually means a connection is missing from the plan.`,
    items: loose.slice(0, 24).map((f) => 'f:' + f.p),
    notes: Object.fromEntries(loose.slice(0, 24).map((f) => ['f:' + f.p, 'Not connected to anything in the plan'])),
    locations: [],
    fix: [`Design review of floorplan/plan.json: these planned files aren't connected to anything:`, ...loose.map((f) => `- ${f.p}`), ``, `Add the missing "uses", "calls", "services" or "data" entries, or remove files that aren't needed.`, rebuild].join('\n'),
  });

  const ORDER = { high: 0, medium: 1, low: 2 };
  issues.sort((a, b) => ORDER[a.severity] - ORDER[b.severity]);
  const summary = { high: 0, medium: 0, low: 0 };
  for (const i of issues) summary[i.severity]++;
  return { summary, issues: issues.slice(0, 40), review: true };
}
