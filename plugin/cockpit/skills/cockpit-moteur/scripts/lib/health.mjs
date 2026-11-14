// vibeflow:allow-large-file (code vendorisé, VENDORED.txt)
// Health check: plain-language warnings about the codebase (secrets, endpoints anyone can call,
// the usual Supabase / Firebase / Stripe / CORS mistakes, unused files, oversized files), written for
// people who built an app with AI and don't know its insides. It's a check, not an audit. Precision
// beats recall: a false alarm costs this audience more than a missed one.
//
// findIssues(src, file)  — called by scan.mjs for every code/config/docs file with its source.
//                           Returns raw findings for that file, stored in scan.json files[].issues.
//                           Findings never contain a secret's value, only its line, kind and a masked hint.
// buildHealth(ctx)       — called by build.mjs with { graph, scan, arch, root } after the graph is built.
//                           Returns { summary: { high, medium, low }, issues: [...] }, stored as graph.health.

import fs from 'node:fs';
import path from 'node:path';
import { git, compileGlob } from './common.mjs';

const lineIndex = (src) => {
  const starts = [0];
  for (let i = 0; i < src.length; i++) if (src.charCodeAt(i) === 10) starts.push(i + 1);
  return (offset) => {
    let lo = 0, hi = starts.length - 1;
    while (lo < hi) { const mid = (lo + hi + 1) >> 1; if (starts[mid] <= offset) lo = mid; else hi = mid - 1; }
    return lo + 1;
  };
};

/** Shannon entropy in bits per character: random keys score ~4+, words and placeholders ~2-3. */
function entropy(s) {
  const counts = new Map();
  for (const c of s) counts.set(c, (counts.get(c) || 0) + 1);
  let e = 0;
  for (const n of counts.values()) { const p = n / s.length; e -= p * Math.log2(p); }
  return e;
}

// Files where keys are usually fake: tests, fixtures, examples, docs.
const TEST_FILE = /(^|\/)(tests?|__tests__|__mocks__|spec|specs|e2e|fixtures?|testdata|mocks?)\/|\.(test|spec|stories)\.[a-z]+$|(^|\/)test_[^/]*\.py$|_test\.(py|go)$|(^|\/)conftest\.py$/i;
// Third-party code checked into the repo (vendor folders, bundled or minified builds): not the project's own code, so
// "split this file" and "delete this file" advice would be wrong for it.
const THIRD_PARTY = /(^|\/)(vendors?|third[-_]party|node_modules|bower_components)\/|\.(bundled|min)\.[cm]?[jt]s$/i;
const EXAMPLE_FILE = /(^|\/)(examples?|samples?|docs?|demo)\/|\.(example|sample|template|dist|tmpl)(\.|$)|(^|\/)[^/]*example[^/]*$/i;
const PLACEHOLDER = /your|xxxx|example|changeme|change[-_]?me|placeholder|replace|dummy|fake|sample|redacted|insert|<[^>]*>|\$\{|\{\{|%\(|\*\*\*|0{8,}|1234567|abcdef|_here\b|-here\b/i;

// ---------- 1. secrets ----------

// Well-known key formats. `sev` defaults to high; `live` formats are flagged even in test files.
const FORMATS = [
  { re: /\bAKIA[0-9A-Z]{16}\b/g, what: 'une clé d’accès Amazon Web Services (AWS)', svc: 'AWS', live: true },
  { re: /\b(?:sk|rk)_live_[0-9a-zA-Z]{20,}/g, what: 'une clé secrète Stripe de production', svc: 'Stripe', live: true },
  { re: /\b(?:sk|rk)_test_[0-9a-zA-Z]{20,}/g, what: 'une clé de test Stripe', svc: 'Stripe', sev: 'medium' },
  { re: /\bwhsec_[A-Za-z0-9]{24,}/g, what: 'un secret de signature de webhook Stripe', svc: 'Stripe' },
  { re: /\bgh[pousr]_[A-Za-z0-9]{36,}\b/g, what: 'un jeton d’accès GitHub', svc: 'GitHub', live: true },
  { re: /\bgithub_pat_[A-Za-z0-9_]{50,}/g, what: 'un jeton d’accès GitHub', svc: 'GitHub', live: true },
  { re: /\bglpat-[A-Za-z0-9_-]{20,}/g, what: 'un jeton d’accès GitLab', svc: 'GitLab', live: true },
  { re: /\bxox[abposr]-[A-Za-z0-9-]{10,}/g, what: 'un jeton Slack', svc: 'Slack', live: true },
  { re: /https:\/\/hooks\.slack\.com\/services\/T[A-Z0-9]+\/B[A-Z0-9]+\/[A-Za-z0-9]{20,}/g, what: 'une adresse de webhook Slack (quiconque la possède peut écrire dans votre Slack)', svc: 'Slack', sev: 'medium' },
  { re: /\bAIza[0-9A-Za-z_\-]{35}\b/g, what: 'une clé d’API Google', svc: 'Google Cloud', sev: 'medium', skipIf: /firebase|authDomain|messagingSenderId/i },
  { re: /\bGOCSPX-[A-Za-z0-9_\-]{20,}/g, what: 'un secret client de connexion Google', svc: 'Google Cloud' },
  { re: /\bsk-ant-[a-z]+\d*-[A-Za-z0-9_\-]{40,}/g, what: 'une clé d’API Anthropic (Claude)', svc: 'Anthropic', live: true },
  { re: /\bsk-(?:proj-|svcacct-|admin-)?[A-Za-z0-9_\-]{16,}T3BlbkFJ[A-Za-z0-9_\-]{16,}/g, what: 'une clé d’API OpenAI', svc: 'OpenAI', live: true },
  { re: /\bsk-(?:proj|svcacct|admin)-[A-Za-z0-9_\-]{40,}/g, what: 'une clé d’API OpenAI', svc: 'OpenAI', live: true },
  { re: /-----BEGIN (?:RSA |EC |DSA |OPENSSH |PGP |ENCRYPTED )?PRIVATE KEY(?: BLOCK)?-----/g, what: 'une clé privée', svc: null, whole: true },
  { re: /\bSG\.[A-Za-z0-9_\-]{22}\.[A-Za-z0-9_\-]{43}\b/g, what: 'une clé d’API d’envoi d’e-mails SendGrid', svc: 'SendGrid', live: true },
  { re: /\bsq0csp-[0-9A-Za-z_\-]{40,}/g, what: 'un secret d’application Square', svc: 'Square', live: true },
  { re: /\bsq0atp-[0-9A-Za-z_\-]{20,}/g, what: 'un jeton d’accès Square', svc: 'Square', live: true },
  { re: /\bEAAA[A-Za-z0-9_\-]{60,}/g, what: 'un jeton d’accès Square', svc: 'Square', live: true },
  { re: /\bshp(?:at|ss|ca|pa)_[a-fA-F0-9]{32}\b/g, what: 'un jeton d’accès Shopify', svc: 'Shopify', live: true },
  { re: /\bhf_[A-Za-z0-9]{30,}\b/g, what: 'un jeton Hugging Face', svc: 'Hugging Face', live: true },
  { re: /\bnpm_[A-Za-z0-9]{36}\b/g, what: 'un jeton de publication npm', svc: 'npm', live: true },
  { re: /\bsbp_[a-f0-9]{40}\b/g, what: 'un jeton de compte Supabase', svc: 'Supabase', live: true },
  { re: /\bsb_secret_[A-Za-z0-9_\-]{20,}/g, what: 'une clé secrète Supabase', svc: 'Supabase', live: true },
  { re: /\b\d{8,10}:AA[0-9A-Za-z_\-]{33}\b/g, what: 'un jeton de bot Telegram', svc: 'Telegram', live: true },
  { re: /\bdop_v1_[a-f0-9]{64}\b/g, what: 'un jeton DigitalOcean', svc: 'DigitalOcean', live: true },
  { re: /\bpat[A-Za-z0-9]{14}\.[a-f0-9]{64}\b/g, what: 'un jeton Airtable', svc: 'Airtable', live: true },
];
const JWT = /\beyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{20,}/g;
const DB_URL = /\b(?:postgres(?:ql)?|mysql|mariadb|mongodb(?:\+srv)?|rediss?|amqps?)(?:\+\w+)?:\/\/([^:\s\/'"@]+):([^@\s'"]+)@([^\/\s'":?,]+)/g;
const LOCAL_HOST = /^(localhost|127\.0\.0\.1|0\.0\.0\.0|db|postgres|mysql|redis|mongo|database|host\.docker\.internal)$/i;

// Names that hold secrets (after camelCase → snake_case). Public-by-design keys are excluded below.
const SECRET_NAME = /(?:^|[_.-])(api_?key|apikey|secret(?:_?key)?|client_?secret|app_?secret|token|access_?token|refresh_?token|auth_?token|authtoken|bearer_?token|passw(?:or)?d|passwd|pwd|private_?key|secret_?access_?key|signing_?(?:key|secret)|signature_?key|webhook_?secret|encryption_?key|auth(?:orization)?_?key|master_?key|credentials?)$/i;
const PUBLIC_NAME = /(^|_)(public|publishable|anon|site_?key|example|sample|test|dummy|fake|mock|placeholder|default|field|label|header|name|type|url|uri|endpoint|path|file|env|var|prefix|length|len|min|max|regex|pattern|format|expires?|ttl)(_|$)|^(next_public|vite|react_app|expo_public|nuxt_public|gatsby)_/i;
const ENV_LOOKUP = /os\.environ|os\.getenv|getenv\(|process\.env|import\.meta\.env|ENV\[|ENV\.fetch|System\.getenv|Deno\.env|secrets\.|config\(\s*['"]|env\(\s*['"]|\$\{\{/;
const PASSWORD_NAME = /pass|pwd/i;
const CONFIG_LANGS = new Set(['yaml', 'yml', 'ini', 'cfg', 'conf', 'properties', 'env', 'toml']);

const snake = (s) => s.replace(/([a-z0-9])([A-Z])/g, '$1_$2').toLowerCase();
const kindFromName = (name) => {
  const n = snake(name);
  if (/pass|pwd/.test(n)) return 'un mot de passe';
  if (/private_?key/.test(n)) return 'une clé privée';
  if (/token/.test(n)) return 'un jeton d’accès';
  if (/api_?key|apikey/.test(n)) return 'une clé d’API';
  if (/credential/.test(n)) return 'des identifiants de connexion';
  return 'une clé secrète';
};
const mask = (v, password) => password || v.length < 12 ? `${v.length} caractères` : `commence par “${v.slice(0, 4)}…”, ${v.length} caractères`;

function valueLooksReal(v, name) {
  if (/\s/.test(v) || PLACEHOLDER.test(v)) return false;
  if (/^(none|null|nil|undefined|true|false|string|number|text|required|optional|bearer|basic|secret|token|password|test|dev|development|local|admin)$/i.test(v)) return false;
  if (/^[A-Z][A-Z0-9_]+$/.test(v)) return false;                 // the NAME of an env var
  if (/^env\([A-Za-z_][\w]*\)$/.test(v)) return false;           // Supabase config.toml reading one: "env(S3_SECRET_KEY)"
  if (/^[a-z_]+(\.[a-z_]+)+$/i.test(v)) return false;            // dotted identifier / key path
  if (/^(\.{0,2}\/|~\/|https?:\/\/|[a-z]:\\)/i.test(v)) return false; // paths and URLs
  if (/\.(json|pem|key|txt|ya?ml|env|crt|p12)$/i.test(v)) return false; // a file name, not the key
  if (/^x-[\w-]+$/i.test(v) || /^(application|text)\//.test(v)) return false;
  if (/^(.)\1+$/.test(v)) return false;
  if (/^(pass(word)?|secret|admin|test|user|changeit|letmein|qwerty|demo|guest|root|welcome)[\d!@#$._-]*$/i.test(v)) return false;
  if (PASSWORD_NAME.test(name)) return v.length >= 6 && !/^[a-z]+$/.test(v);
  return v.length >= 16 && entropy(v) >= 3.2 && /\d/.test(v) && /[a-zA-Z]/.test(v);
}

// Tokens that are public by design, because the browser has to send them: Cloudflare Web Analytics'
// beacon (data-cf-beacon='{"token":"…"}') and Mapbox public tokens (pk.…)
const PUBLIC_TOKEN_LINE = /data-cf-beacon|cloudflareinsights\.com/i;
const PUBLIC_TOKEN_VALUE = /^pk\.[\w-]{20,}\.[\w-]{10,}$/;

/** 1-based line numbers inside docstrings or block comments (examples there aren't real config). */
function docLines(src, lang) {
  const set = new Set();
  if (!['python', 'typescript', 'javascript', 'java', 'kotlin', 'go', 'csharp', 'php', 'rust', 'swift'].includes(lang)) return set;
  const re = lang === 'python' ? /("""|''')[\s\S]*?\1/g : /\/\*[\s\S]*?\*\//g;
  const at = lineIndex(src);
  for (const m of src.matchAll(re)) { const a = at(m.index), b = at(m.index + m[0].length); for (let l = a; l <= b; l++) set.add(l); }
  return set;
}

function findSecrets(src, f, out) {
  const at = lineIndex(src);
  const isTest = TEST_FILE.test(f.path) || EXAMPLE_FILE.test(f.path);
  const seenLines = new Set();
  const add = (line, rec) => { if (seenLines.has(line)) return; seenLines.add(line); out.push({ k: 'secret', line, ...rec }); };

  for (const fm of FORMATS) {
    if (fm.skipIf?.test(src)) continue;
    for (const m of src.matchAll(fm.re)) {
      const v = m[0];
      if (isTest && (!fm.live || fm.whole)) continue;
      if (!fm.whole && (/EXAMPLE|xxxx|XXXX|0{10,}/.test(v) || entropy(v) < 3)) continue;
      add(at(m.index), { what: fm.what, svc: fm.svc, sev: fm.sev || 'high', hint: fm.whole ? 'bloc de clé privée' : mask(v), ...(isTest ? { test: true } : {}) });
    }
  }
  if (!isTest) {
    for (const m of src.matchAll(JWT)) {
      let payload = null;
      try { payload = JSON.parse(Buffer.from(m[0].split('.')[1].replace(/-/g, '+').replace(/_/g, '/'), 'base64').toString('utf8')); } catch { continue; }
      if (payload?.role !== 'service_role') continue; // "anon" keys are public by design
      add(at(m.index), { what: 'une clé « service-role » Supabase (accès complet à votre base de données, sans aucune règle de sécurité)', svc: 'Supabase', sev: 'high', hint: mask(m[0]) });
    }
    for (const m of src.matchAll(DB_URL)) {
      const [, user, pw, host] = m;
      if (LOCAL_HOST.test(host) || PLACEHOLDER.test(pw) || /^[:$%{<]/.test(pw) || pw.length < 4 || /^(password|pass|postgres|root|secret|admin|user)$/i.test(pw)) continue;
      add(at(m.index), { what: 'un mot de passe de base de données dans une adresse de connexion', svc: 'votre base de données', sev: 'high', hint: mask(pw, true) });
    }
  }
  if (isTest || f.category === 'docs') return;

  // Assignments: api_key = "…", "password": "…", PASSWORD=… (config files may leave values unquoted).
  const lines = src.split('\n');
  const inDoc = docLines(src, f.lang);
  // CI / docker-compose database containers get throwaway passwords
  const throwawayDb = /(^|\/)\.github\/|(^|\/)(docker-)?compose[\w.-]*\.ya?ml$/i.test(f.path);
  const quoted = /(["']?)([A-Za-z_][\w.-]*)\1\s*(?::=|=>|=|:)\s*(?:[rbuRBU]{1,2})?(["'`])([^"'`\n]{6,200})\3/g;
  const unquoted = /^\s*(?:export\s+)?([A-Za-z_][\w.-]*)\s*[:=]\s*([^\s#'"]{6,200})\s*(?:#.*)?$/;
  lines.forEach((text, i) => {
    if (text.length > 400 || ENV_LOOKUP.test(text) || PUBLIC_TOKEN_LINE.test(text) || inDoc.has(i + 1) || /^\s*(#|\/\/|\*|\/\*|<!--)/.test(text)) return;
    const pairs = [...text.matchAll(quoted)].map((m) => [m[2], m[4]]);
    if (!pairs.length && (f.category === 'config' && CONFIG_LANGS.has(f.lang))) { const u = unquoted.exec(text); if (u) pairs.push([u[1], u[2]]); }
    for (const [name, value] of pairs) {
      const n = snake(name.split('.').pop());
      if (!SECRET_NAME.test(n) || PUBLIC_NAME.test(n) || PUBLIC_TOKEN_VALUE.test(value) || !valueLooksReal(value, n)) continue;
      if (throwawayDb && /^(postgres|mysql|mariadb|mongo(_initdb_root)?|redis|pg|rabbitmq_default|db|database)_(root_)?(password|pass|pwd)$/.test(n)) continue;
      add(i + 1, { what: kindFromName(name), name: name.split('.').pop(), sev: 'high', hint: mask(value, PASSWORD_NAME.test(n)), generic: true });
    }
  });
}

// ---------- 2. who may call each endpoint ----------

// Decorators / middleware / dependencies whose names say "check who is calling".
const GUARD_NAME = /(^|_)(login|auth|authenticated|authorized?|jwt|token|permission|permissions|perm|role|roles|staff|admin|superuser|owner|scope|scopes|session|api_?key|signature|signed|hmac|device|member|user)(_|$)|_required$|^requires?_|^ensure_|^verify_|^check_(auth|token|user|session|permission|role|api)|protect|^is_?authenticated|^is_?admin/i;
const NOT_GUARD = /^(route|get|post|put|patch|delete|cached?|limit|limiter|rate_?limit\w*|cross_origin|wraps|staticmethod|classmethod|property|retry|timed|log\w*|swag_from|validate\w*|expects|marshal\w*|doc|json_required|fields?_required|params?_required|body_required|transaction\w*|csrf\w*|exempt)$/i;
const isGuardName = (name) => !!name && !NOT_GUARD.test(name) && GUARD_NAME.test(snake(name));
// FastAPI dependencies that hand over a database session rather than check the caller
// (SessionDep, get_db, get_sql_session, SessionLocal, a unit of work), matched on the snake_case name
const DB_DEPENDENCY = /^(get_|new_|create_)?(async_)?(db|database|session|db_session|sessionmaker)$|(^|_)(db|database|sql\w*|engine|conn|connection|cursor|uow|unit_of_work)(_|$)|session_?(local|maker|factory)/i;
const isDbDep = (name) => DB_DEPENDENCY.test(snake(name));
const isGuardDep = (name) => isGuardName(name) && !isDbDep(name);
// A handler body that inspects the caller itself.
const INLINE_CHECK = /request\.headers(?:\.get)?\(?\s*\[?\s*['"](authorization|x-api-key|x-[\w-]*(token|key|secret|signature)[\w-]*)['"]|req\.headers(?:\.|\[\s*['"])(authorization|x-api-key)|\b(verify|check|require|validate|authenticate|authorize)_?\w*(auth|token|session|user|key|signature|webhook|hmac|jwt|device|staff|admin|permission|role|request|caller)\w*\s*\(|\bcurrent_user\b|get_jwt_identity|verify_jwt_in_request|compare_digest|abort\(\s*40[13]\b|,\s*40[13]\s*\)?\s*$|status(?:Code)?\s*[:=(]\s*40[13]\b|\.status\(\s*40[13]\s*\)|req\.user\b|req\.session\.user|req\.auth\b|jwt\.verify|jwtVerify|getServerSession|auth\(\)|currentUser\(|getAuth\(|auth\.getUser|getSession\(|verifyIdToken|getToken\(/m;
const FIREBASE_CHECK = /\b\w+\.auth\b(?!\s*\()|HttpsError\(\s*["'](unauthenticated|permission-denied)["']|enforceAppCheck\s*:\s*true|\b\w+\.app\b\s*(==|!=|===|!==)\s*(undefined|null)|!\s*\w+\.app\b/;
const SIGNATURE_CHECK =/hmac|signature|verify_?webhook|construct_?event|x-hub-signature|compare_digest|svix|webhooks?\.verify|jwt\.decode|oidc|id_token|authenticated|verify_\w*(token|request|push)/i;
const NEXT_GUARD = /getServerSession|\bauth\(\)|currentUser\(|getAuth\(|auth\.getUser|supabase\.auth\.get(User|Session)|getSession\(|verifyIdToken|jwt\.verify|jwtVerify|getToken\(|clerkClient|requireAuth|requireUser|withAuth|validateRequest|headers\(\)\.get\(\s*['"]authorization|status:\s*40[13]\b/;
const NEXT_MIDDLEWARE_GUARD = /getToken|withAuth|clerkMiddleware|authMiddleware|auth\(|supabase|getSession|jwtVerify|jwt\.verify|cookies\.get\([^)]*(session|token|auth)|redirect\([^)]*login/i;

function blockAfter(lines, defIdx) {
  // A Python def's body: every line after it that's more indented, up to 120 lines.
  const ind = /^\s*/.exec(lines[defIdx])[0].length;
  let end = defIdx + 1;
  while (end < lines.length && end < defIdx + 120 && (!lines[end].trim() || /^\s*/.exec(lines[end])[0].length > ind || /^\s*[)\]]/.test(lines[end]))) end++;
  return lines.slice(defIdx, end).join('\n');
}

function pyRoutes(src, f, out) {
  const lines = src.split('\n');
  // Blueprint / app-wide before_request hooks and router-level dependencies that check the caller.
  const guardedVars = new Map();
  for (const m of src.matchAll(/^@(\w+)\.before_(?:app_)?request\s*\n(?:@.*\n)*\s*def\s+(\w+)/gm)) {
    const defIdx = src.slice(0, m.index + m[0].length).split('\n').length - 1;
    const body = blockAfter(lines, defIdx);
    if (!/\b40[13]\b|Unauthorized|Forbidden|verify_jwt_in_request|login_required|is_authenticated|current_user/.test(body)) continue;
    guardedVars.set(m[1], m[2]);
    if (m[1] === 'app') out.push({ k: 'global-guard', framework: 'flask', name: m[2], line: defIdx + 1 });
  }
  for (const m of src.matchAll(/^\s*(\w+)\s*=\s*(?:\w+\.)?APIRouter\(([^)]*(?:\([^)]*\)[^)]*)*)\)/gm)) {
    const dep = /dependencies\s*=\s*\[[^\]]*Depends\(\s*([\w.]+)/.exec(m[2]);
    if (dep && isGuardDep(dep[1].split('.').pop())) guardedVars.set(m[1], dep[1]);
  }
  // FastAPI dependency aliases, `AdminUser = Annotated[Session, Depends(admin_user)]`, and the dependency
  // functions behind them. They're usually imported from a shared deps.py, so build decides repo-wide
  // which ones check the caller (see pyAliasGuards).
  const lineAt = (i) => src.slice(0, i).split('\n').length - 1;
  const sigAt = (idx) => lines.slice(idx, idx + 15).join('\n').split(/\)\s*(->[^:]*)?:\s*$/m)[0];
  const depsIn = (text) => [...text.matchAll(/\b(?:Depends|Security)\(\s*([\w.]+)/g)].map((m) => m[1].split('.').pop());
  const typesIn = (sig) => [...new Set([...sig.matchAll(/\b\w+\s*:\s*(?:[\w.]*Annotated\[\s*)?([A-Za-z_][\w.]*)/g)].map((m) => m[1].split('.').pop()))];
  if (/\b(Depends|Security)\(/.test(src)) {
    for (const m of src.matchAll(/^(?:type\s+)?(\w+)\s*(?::[^=\n]*)?=\s*(?:[\w.]+\.)?Annotated\[/gm)) {
      let depth = 1, j = m.index + m[0].length;
      while (j < src.length && depth && j - m.index < 800) { if (src[j] === '[') depth++; else if (src[j] === ']') depth--; j++; }
      const fn = depsIn(src.slice(m.index, j))[0];
      if (fn) out.push({ k: 'py-alias', name: m[1], fn, line: lineAt(m.index) + 1 });
    }
    // top-level functions that aren't routes, with the dependencies and types they take
    for (const m of src.matchAll(/^(?:async\s+)?def\s+(\w+)\s*\(/gm)) {
      const idx = lineAt(m.index);
      if (idx > 0 && /^\s*@/.test(lines[idx - 1])) continue;
      const sig = sigAt(idx), deps = depsIn(sig), types = typesIn(sig);
      if (deps.length || types.length) out.push({ k: 'py-dep-fn', name: m[1], ...(deps.length ? { deps } : {}), ...(types.length ? { types } : {}) });
    }
  }
  // Decorators defined here: auth-named ones, and project wrappers like `@endpoint(write=True)` whose
  // body applies an auth decorator itself. Repeat once so a wrapper of a wrapper counts too.
  const localGuards = new Set();
  const defs = [...src.matchAll(/^def\s+(\w+)\s*\(/gm)].map((m) => { const idx = src.slice(0, m.index).split('\n').length - 1; return { name: m[1], line: idx + 1, body: blockAfter(lines, idx) }; });
  const decoratorish = (body) => /wraps|decorat|def\s+\w+\(\s*\*args|return\s+\w+\s*$/m.test(body);
  for (let pass = 0; pass < 2; pass++) for (const d of defs) {
    if (localGuards.has(d.name) || !decoratorish(d.body)) continue;
    const applied = [...d.body.matchAll(/^\s*@([\w.]+)/gm)].map((m) => m[1].split('.').pop());
    const wraps = applied.some((a) => isGuardName(a) || localGuards.has(a));
    if (isGuardName(d.name) || wraps) { localGuards.add(d.name); out.push({ k: 'guard-def', name: d.name, line: d.line, ...(wraps && !isGuardName(d.name) ? { wrapper: true } : {}) }); }
  }

  for (const r of f.routes || []) {
    if (r.framework === 'django') continue;
    const i0 = r.line - 1;
    // decorators above the route decorator (wrong place in Flask/FastAPI: the route registers the unwrapped function)
    const above = [];
    for (let i = i0 - 1; i >= 0 && /^\s*@/.test(lines[i]); i--) above.push(/^\s*@([\w.]+)/.exec(lines[i])[1].split('.').pop());
    // decorators below it, up to the def
    const below = [];
    let defIdx = -1;
    for (let i = i0 + 1; i < lines.length && i < i0 + 30; i++) {
      if (/^\s*(async\s+)?def\s/.test(lines[i])) { defIdx = i; break; }
      const d = /^\s*@([\w.]+)/.exec(lines[i]);
      if (d) below.push(d[1].split('.').pop());
    }
    const decoText = lines.slice(i0, defIdx > 0 ? defIdx : i0 + 1).join('\n');
    const sig = defIdx > 0 ? lines.slice(defIdx, defIdx + 15).join('\n').split(/\)\s*(->[^:]*)?:\s*$/m)[0] : '';
    const body = defIdx > 0 ? blockAfter(lines, defIdx) : '';
    const rec = { k: 'route', line: r.line, method: r.method };
    const deco = below.find((d) => (isGuardName(d) || localGuards.has(d)) && !/^(route|get|post|put|patch|delete)$/.test(d));
    const dep = /Depends\(\s*([\w.]+)|Security\(\s*([\w.]+)/g;
    const deps = [...(decoText + '\n' + sig).matchAll(dep)].map((m) => (m[1] || m[2]).split('.').pop());
    if (deco) Object.assign(rec, { guard: deco, via: 'decorator' });
    else if (guardedVars.has(r.var)) Object.assign(rec, { guard: guardedVars.get(r.var), via: 'blueprint' });
    else if (deps.some(isGuardDep)) Object.assign(rec, { guard: deps.find(isGuardDep), via: 'dependency' });
    else if (INLINE_CHECK.test(body)) Object.assign(rec, { via: 'inline' });
    else {
      const misplaced = above.find((d) => isGuardName(d) && !/^(route|get|post|put|patch|delete)$/.test(d));
      if (misplaced) rec.misplaced = misplaced;
      // other decorators may be auth wrappers defined in another file; build resolves them
      const other = below.filter((d) => !/^(route|get|post|put|patch|delete|api_route|websocket)$/.test(d));
      if (other.length) rec.decos = other;
      // so may parameter types: `user: AdminUser`, a dependency alias (pyAliasGuards)
      const types = typesIn(sig);
      if (types.length) rec.types = types;
    }
    if (SIGNATURE_CHECK.test(body)) rec.signed = true;
    if (defIdx > 0) rec.fn = /def\s+(\w+)/.exec(lines[defIdx])[1];
    out.push(rec);
  }
}

function jsRoutes(src, f, out) {
  const routes = f.routes || [];
  if (!routes.length && !/\.use\(/.test(src) && !/(^|\/)middleware\.(t|j)s$/.test(f.path)) return;
  const lines = src.split('\n');
  // Next.js middleware.ts protecting the app
  if (/(^|\/)(src\/)?middleware\.(t|j)s$/.test(f.path) && NEXT_MIDDLEWARE_GUARD.test(src)) {
    const matcher = /matcher\s*:\s*([^\n]+)/.exec(src)?.[1] || '';
    if (!matcher || /api|\(\?!/.test(matcher)) out.push({ k: 'global-guard', framework: 'next', line: 1 });
  }
  // app.use(auth) / router.use(requireAuth) without a path guards everything registered after it
  const uses = [];
  for (const m of src.matchAll(/\b(\w+)\.use\(\s*([^'"`)][^)]*)\)/g)) {
    const names = m[2].match(/[A-Za-z_$][\w$]*/g) || [];
    if (names.some(isGuardName)) uses.push({ v: m[1], line: src.slice(0, m.index).split('\n').length, name: names.find(isGuardName) });
  }
  for (const u of uses) if (u.v === 'app' || u.v === 'server') out.push({ k: 'global-guard', framework: 'express', name: u.name, line: u.line });

  routes.forEach((r, idx) => {
    const rec = { k: 'route', line: r.line, method: r.method };
    if (r.framework === 'firebase') {
      // a callable checks request.auth (v1: context.auth) or turns on App Check; an onRequest function
      // checks a token or signature itself, like any other handler
      const next = routes.slice(idx + 1).find((x) => x.line > r.line)?.line || r.line + 80;
      const body = lines.slice(r.line - 1, Math.min(next - 1, r.line + 80)).join('\n');
      if (FIREBASE_CHECK.test(body) || INLINE_CHECK.test(body)) rec.via = 'inline';
      if (SIGNATURE_CHECK.test(body)) rec.signed = true;
      rec.fn = r.handler;
      out.push(rec);
      return;
    }
    if (r.framework === 'next') {
      if (NEXT_GUARD.test(src)) rec.via = 'inline';
      if (SIGNATURE_CHECK.test(src)) rec.signed = true;
      rec.fn = r.method;
      out.push(rec);
      return;
    }
    // the route call's own arguments: router.post('/x', requireAuth, async (req, res) => …)
    const head = lines.slice(r.line - 1, r.line + 4).join('\n');
    const args = (/\.\w+\(\s*["'`][^"'`]*["'`]\s*,([\s\S]*?)(?:async\s*)?(?:\(\s*req\b|function\b|\breq\s*=>|\(\s*\{|\(\s*c\s*\)|\(\s*ctx\b)/.exec(head)?.[1] || '');
    const mw = (args.match(/[A-Za-z_$][\w$.]*/g) || []).map((x) => x.split('.').pop()).find(isGuardName);
    const next = routes[idx + 1]?.line || r.line + 60;
    const body = lines.slice(r.line - 1, Math.min(next - 1, r.line + 60)).join('\n');
    const prior = uses.find((u) => u.v === r.var && u.line < r.line);
    if (mw) Object.assign(rec, { guard: mw, via: 'middleware' });
    else if (prior) Object.assign(rec, { guard: prior.name, via: 'router' });
    else if (INLINE_CHECK.test(body)) rec.via = 'inline';
    if (SIGNATURE_CHECK.test(body)) rec.signed = true;
    out.push(rec);
  });
}

/**
 * FastAPI dependency aliases that check the caller, per repo: Map(repo -> Map(alias -> file)).
 * An alias checks the caller when its dependency function does: by its name (admin_user), by taking a
 * checking dependency (Depends(require_login)), or by taking a checking alias itself, e.g.
 * `AdminOffice = Annotated[Office, Depends(admin_owned_office)]` where admin_owned_office takes `admin: AdminUser`.
 * An alias whose own name reads as a check counts too (`AdminAccess = Annotated[dict, Depends(check)]`),
 * unless either name says it's a database session (`SqlSessionDep` over `get_sql_session`).
 */
function pyAliasGuards(files, findings) {
  const byRepo = new Map(); // repo -> { aliases: Map(name -> {fn, file}), fns: Map(name -> {deps, types}) }
  for (const f of files) for (const x of findings(f.path)) {
    if (x.k !== 'py-alias' && x.k !== 'py-dep-fn') continue;
    const k = f.repo ?? '';
    if (!byRepo.has(k)) byRepo.set(k, { aliases: new Map(), fns: new Map() });
    const r = byRepo.get(k);
    if (x.k === 'py-alias') r.aliases.set(x.name, { fn: x.fn, file: f.path });
    else r.fns.set(x.name, { deps: x.deps || [], types: x.types || [] });
  }
  const out = new Map();
  for (const [repo, { aliases, fns }] of byRepo) {
    const ok = new Map();
    const checks = (fn) => isGuardDep(fn) || (!isDbDep(fn) && !!fns.get(fn) && (fns.get(fn).deps.some(isGuardDep) || fns.get(fn).types.some((t) => ok.has(t))));
    const aliasChecks = (name, fn) => checks(fn) || (isGuardDep(name) && !isDbDep(fn));
    // a few passes, so aliases built on other aliases resolve in any file order
    for (let pass = 0; pass < 3; pass++) for (const [name, a] of aliases) if (!ok.has(name) && aliasChecks(name, a.fn)) ok.set(name, a.file);
    if (ok.size) out.set(repo, ok);
  }
  return out;
}

// ---------- 3. the usual mistakes in apps built on Supabase, Firebase, Stripe, Next.js and Vite ----------

// Frontend build tools copy variables with these prefixes into the code every visitor downloads.
// (A bare PUBLIC_ prefix only means that to SvelteKit and Astro, so it counts only where they read it.)
const PUBLIC_PREFIX = /^(NEXT_PUBLIC|VITE|REACT_APP|EXPO_PUBLIC|NUXT_PUBLIC|GATSBY|PUBLIC)_/;
const CLIENT_ONLY_PREFIX = /^(VITE|REACT_APP|EXPO_PUBLIC|GATSBY|PUBLIC)_/; // these exist only in browser code
// After the prefix: names that hold something private…
const PRIVATE_NAME = /(^|_)(SECRETS?|SERVICE_ROLE|SERVICE_KEY|PRIVATE|PASSWORD|PASSWD|PWD|DATABASE_URL|DB_URL|CONNECTION_STRING|ADMIN_KEY|ADMIN_TOKEN|AUTH_TOKEN|JWT_SECRET)(_|$)/;
// …or a key or token for a service that charges you or acts as you (AI, email, messaging, code hosting)
const PRIVATE_SERVICE = /(^|_)(OPENAI|ANTHROPIC|CLAUDE|GEMINI|GROQ|GROK|XAI|MISTRAL|REPLICATE|ELEVEN_?LABS|SENDGRID|RESEND|POSTMARK|MAILGUN|BREVO|TWILIO|OPENROUTER|DEEPSEEK|PERPLEXITY|COHERE|TOGETHER|FIREWORKS|HUGGING_?FACE|HF|STABILITY|FAL|ASSEMBLY_?AI|DEEPGRAM|PINECONE|SERPAPI|TAVILY|FIRECRAWL|AIRTABLE|NOTION|GITHUB|SLACK|DISCORD|TELEGRAM|STRIPE)(_|$)/;
const KEYISH = /(^|_)(KEY|API_?KEY|TOKEN|SECRET)$/;
// Keys that are public by design: Supabase's anon key, Stripe's publishable key, reCAPTCHA site keys, IDs
const PUBLIC_BY_DESIGN = /(^|_)(PUBLISHABLE|ANON|PK|PUBLIC|SITE|CLIENT_ID|APP_ID|PROJECT_ID|MEASUREMENT_ID)(_|$)/;
const SERVICE_LABEL = { OPENAI: 'OpenAI', ANTHROPIC: 'Anthropic', CLAUDE: 'Anthropic', GEMINI: 'Google Gemini', GROQ: 'Groq', GROK: 'xAI', XAI: 'xAI', ELEVENLABS: 'ElevenLabs', ELEVEN_LABS: 'ElevenLabs', SENDGRID: 'SendGrid', OPENROUTER: 'OpenRouter', DEEPSEEK: 'DeepSeek', HF: 'Hugging Face', HUGGINGFACE: 'Hugging Face', HUGGING_FACE: 'Hugging Face', ASSEMBLYAI: 'AssemblyAI', ASSEMBLY_AI: 'AssemblyAI', SERPAPI: 'SerpApi', GITHUB: 'GitHub' };

/** For a variable like VITE_OPENAI_API_KEY: the service it unlocks ('OpenAI', or '' for a generic secret), or null when it's fine to be public. */
export function leakyPublicVar(name) {
  const m = PUBLIC_PREFIX.exec(name);
  if (!m) return null;
  const rest = name.slice(m[0].length);
  if (PUBLIC_BY_DESIGN.test(rest)) return null;
  const svc = PRIVATE_SERVICE.exec(rest)?.[2];
  if (svc && KEYISH.test(rest)) return SERVICE_LABEL[svc] || svc.charAt(0) + svc.slice(1).toLowerCase();
  if (PRIVATE_NAME.test(rest)) return /SERVICE_ROLE|SERVICE_KEY/.test(rest) ? 'Supabase' : '';
  return null;
}

function findPublicEnv(src, f, out) {
  const at = lineIndex(src);
  const seen = new Set();
  const add = (name, idx) => { if (leakyPublicVar(name) === null || seen.has(name)) return; seen.add(name); out.push({ k: 'public-env', name, line: at(idx) }); };
  for (const m of src.matchAll(/\b(process\.env\.|process\.env\[\s*['"]|import\.meta\.env\.)([A-Z][A-Z0-9_]*)/g)) {
    if (/^PUBLIC_/.test(m[2]) && m[1].startsWith('process')) continue; // PUBLIC_ means nothing to Node
    add(m[2], m.index);
  }
  for (const m of src.matchAll(/import\s*\{([^}]*)\}\s*from\s*['"]\$env\/(?:static|dynamic)\/public['"]/g)) for (const n of m[1].match(/[A-Z][A-Z0-9_]*/g) || []) add(n, m.index);
}

// Stripe: code that acts on payment events. Without checking Stripe's signature first, anyone can send
// a fake "payment succeeded" event to the webhook address.
const STRIPE_EVENT = /(?:\bcase\s*|[!=]==?\s*)["'](checkout\.session\.(?:completed|async_payment_succeeded)|payment_intent\.succeeded|invoice\.(?:paid|payment_succeeded|payment_failed)|customer\.subscription\.(?:created|updated|deleted)|charge\.(?:succeeded|refunded))["']/g;
const STRIPE_VERIFIED = /constructEvent(?:Async)?\s*\(|construct_event\s*\(|verifyHeader|verify_header|events\.retrieve\s*\(|Event\.retrieve\s*\(/;

function findStripeWebhook(src, f, out) {
  if (!/stripe/i.test(src) || STRIPE_VERIFIED.test(src)) return;
  const hits = [...src.matchAll(STRIPE_EVENT)];
  if (!hits.length) return;
  out.push({ k: 'stripe-unsigned', line: lineIndex(src)(hits[0].index), events: [...new Set(hits.map((m) => m[1]))].slice(0, 4) });
}

// CORS: a server that tells browsers any website may call it. Harmless for a public API without login
// cookies; with them, any site a signed-in visitor opens could act as them.
function findCors(src, f, out) {
  const at = lineIndex(src);
  const add = (idx, how, credentials) => out.push({ k: 'cors-any', line: at(idx), how, credentials });
  if (['typescript', 'javascript'].includes(f.lang)) {
    if (/require\(\s*['"]cors['"]\s*\)|from\s+['"]cors['"]/.test(src)) {
      for (const m of src.matchAll(/\bcors\(\s*\)/g)) add(m.index, 'cors()', false);
      for (const m of src.matchAll(/\bcors\(\s*\{([^}]*)\}/g)) {
        const origin = /\borigin\s*:\s*(?:(['"`])\*\1|(true)\b)/.exec(m[1]);
        // '*' with credentials is refused by browsers; origin: true echoes whichever site asks
        if (origin) add(m.index, origin[2] ? 'cors({ origin: true })' : "cors({ origin: '*' })", !!origin[2] && /\bcredentials\s*:\s*true/.test(m[1]));
      }
    }
    const credHeader = /['"]Access-Control-Allow-Credentials['"]\s*[,:]\s*['"`]?true/i.test(src);
    for (const m of src.matchAll(/['"]Access-Control-Allow-Origin['"]\s*[,:]\s*(?:(['"`])\*\1|(req(?:uest)?\.headers(?:\.origin\b|\[\s*['"]origin['"]\s*\]|\.get\(\s*['"]origin['"]\s*\))))/gi)) {
      add(m.index, m[2] ? 'Access-Control-Allow-Origin fixé à l’origine de l’appelant' : 'Access-Control-Allow-Origin: *', !!m[2] && credHeader);
    }
  } else if (f.lang === 'python') {
    for (const m of src.matchAll(/CORSMiddleware\s*,([\s\S]{0,800}?)\)\s*$/gm)) {
      if (/allow_origins\s*=\s*\[\s*(['"])\*\1\s*\]|allow_origin_regex\s*=\s*r?(['"])\.\*\2/.test(m[1])) add(m.index, 'CORSMiddleware avec allow_origins=["*"]', /allow_credentials\s*=\s*True/.test(m[1]));
    }
    for (const m of src.matchAll(/\bCORS\(\s*\w+\s*(?:\)|,([^)]*)\))/g)) {
      const opts = m[1] || '';
      if (/\borigins["']?\s*[:=]\s*(?!(['"])\*\1)/.test(opts)) continue; // a list of allowed sites (origins=… or "origins": …)
      add(m.index, 'CORS(app) avec toutes les origines autorisées', /supports_credentials\s*=\s*True/.test(opts));
    }
    const all = /^\s*CORS_(?:ALLOW_ALL_ORIGINS|ORIGIN_ALLOW_ALL)\s*=\s*True\b/m.exec(src);
    if (all) add(all.index, 'CORS_ALLOW_ALL_ORIGINS = True', /^\s*CORS_ALLOW_CREDENTIALS\s*=\s*True\b/m.test(src));
  }
}

// Supabase / Postgres migrations: tables, row-level security switched on or off, tables dropped or
// renamed, and security rules that let anyone change a table. build.mjs replays them in file order.
const SQL_ID = String.raw`(?:"[^"]+"|[A-Za-z_][\w$]*)`;
const SQL_NAME = String.raw`(?:${SQL_ID}\s*\.\s*)?${SQL_ID}`;
const sqlName = (raw) => {
  const parts = raw.split(/\s*\.\s*(?=(?:"[^"]*"|[^"])*$)/).map((p) => p.trim().replace(/^"|"$/g, '').toLowerCase());
  return parts.length > 1 ? `${parts[0]}.${parts[1]}` : `public.${parts[0]}`;
};

function findSql(src, f, out) {
  // blank out comments, keeping line breaks so line numbers stay right
  const s = src.replace(/--[^\n]*/g, (m) => ' '.repeat(m.length)).replace(/\/\*[\s\S]*?\*\//g, (m) => m.replace(/[^\n]/g, ' '));
  const at = lineIndex(s);
  const found = [];
  for (const m of s.matchAll(new RegExp(String.raw`\bcreate\s+(?:(temp|temporary)\s+|unlogged\s+)?table\s+(?:if\s+not\s+exists\s+)?(${SQL_NAME})`, 'gi'))) {
    if (!m[1]) found.push({ i: m.index, k: 'sql-table', table: sqlName(m[2]) });
  }
  for (const m of s.matchAll(new RegExp(String.raw`\balter\s+table\s+(?:if\s+exists\s+)?(?:only\s+)?(${SQL_NAME})\s+(enable|disable|force|no\s+force)\s+row\s+level\s+security`, 'gi'))) {
    found.push({ i: m.index, k: 'sql-rls', table: sqlName(m[1]), on: !/^(disable|no)/i.test(m[2]) });
  }
  for (const m of s.matchAll(new RegExp(String.raw`\balter\s+table\s+(?:if\s+exists\s+)?(?:only\s+)?(${SQL_NAME})\s+rename\s+to\s+(${SQL_ID})`, 'gi'))) {
    const from = sqlName(m[1]);
    found.push({ i: m.index, k: 'sql-rename', table: from, to: `${from.split('.')[0]}.${m[2].replace(/^"|"$/g, '').toLowerCase()}` });
  }
  for (const m of s.matchAll(new RegExp(String.raw`\bdrop\s+table\s+(?:if\s+exists\s+)?(${SQL_NAME}(?:\s*,\s*${SQL_NAME})*)`, 'gi'))) {
    for (const t of m[1].split(/\s*,\s*/)) found.push({ i: m.index, k: 'sql-drop', table: sqlName(t) });
  }
  // a permissive rule that lets signed-out visitors add, change or delete rows: `using (true)` / `with check (true)`
  for (const m of s.matchAll(new RegExp(String.raw`\bcreate\s+policy\s+(${SQL_ID})\s+on\s+(${SQL_NAME})([^;]*)`, 'gi'))) {
    const body = m[3];
    if (/\bas\s+restrictive\b/i.test(body)) continue;
    const cmd = (/\bfor\s+(all|select|insert|update|delete)\b/i.exec(body)?.[1] || 'all').toLowerCase();
    if (cmd === 'select') continue;
    const to = /\bto\s+([\w\s,"]+?)(?=\s+(?:using|with)\b|\s*$)/i.exec(body)?.[1];
    const roles = to ? to.split(/\s*,\s*/).map((r) => r.replace(/"/g, '').trim().toLowerCase()) : ['public'];
    if (!roles.some((r) => r === 'anon' || r === 'public')) continue;
    const yes = (clause) => new RegExp(String.raw`\b${clause}\s*\(\s*\(?\s*true\s*\)?\s*\)`, 'i').test(body);
    const open = cmd === 'insert' ? yes('with\\s+check') : cmd === 'all' ? yes('using') || yes('with\\s+check') : yes('using');
    if (open) found.push({ i: m.index, k: 'sql-open-policy', table: sqlName(m[2]), policy: m[1].replace(/^"|"$/g, ''), cmd, signedOut: roles.includes('anon') || !to });
  }
  for (const x of found.sort((a, b) => a.i - b.i)) { const { i, ...rest } = x; out.push({ ...rest, line: at(i) }); }
}

const USES_FIREBASE = /\bfrom\s+['"]firebase(?:-admin|-functions)?(?:\/[\w./-]+)?['"]|require\(\s*['"]firebase(?:-admin|-functions)?(?:\/[\w./-]+)?['"]\s*\)|^\s*(?:import|from)\s+firebase_admin\b|@firebase\//m;
const USES_STRIPE = /\bfrom\s+['"]stripe['"]|require\(\s*['"]stripe['"]\s*\)|^\s*import\s+stripe\b|@stripe\//m;
const USES_SUPABASE = /@supabase\/(?:supabase-js|ssr|auth-helpers[\w-]*)|from\s+supabase\s+import|^\s*import\s+supabase\b/m;

// ---------- per-file entry point ----------

export function findIssues(src, f) {
  const out = [];
  findSecrets(src, f, out);
  if (f.category !== 'code') return out;
  if (f.lang === 'sql') findSql(src, f, out);
  if (!TEST_FILE.test(f.path) && !EXAMPLE_FILE.test(f.path)) {
    if (['typescript', 'javascript', 'vue', 'svelte', 'astro'].includes(f.lang)) findPublicEnv(src, f, out);
    if (['typescript', 'javascript', 'python'].includes(f.lang)) { findStripeWebhook(src, f, out); findCors(src, f, out); }
  }
  if (['typescript', 'javascript', 'python'].includes(f.lang) && USES_SUPABASE.test(src)) out.push({ k: 'uses-supabase' });
  if (['typescript', 'javascript', 'python'].includes(f.lang) && USES_FIREBASE.test(src)) out.push({ k: 'uses-firebase' });
  if (['typescript', 'javascript', 'python'].includes(f.lang) && USES_STRIPE.test(src)) out.push({ k: 'uses-stripe' });
  if (f.lang === 'python') pyRoutes(src, f, out);
  else if (['typescript', 'javascript'].includes(f.lang)) jsRoutes(src, f, out);
  // run directly or registered by name (so "nothing imports it" doesn't mean unused)
  if (/^#!|if\s+__name__\s*==\s*['"]__main__['"]|@(?:\w+\.)*(?:task|shared_task|command|group|receiver|scheduled_job|on_event|listener|hookimpl|periodic_task|cli\.command)\b|require\.main\s*===\s*module|import\.meta\.main/m.test(src)) out.push({ k: 'runnable' });
  // a frontend calling a fixed localhost address (breaks once deployed)
  // (only in files with no environment / hostname switching, where it can't be a dev-only fallback)
  if (['typescript', 'javascript', 'vue', 'svelte'].includes(f.lang) && !TEST_FILE.test(f.path) && !/process\.env|import\.meta\.env|NODE_ENV|location\.(hostname|host|origin)|isDev|__DEV__/.test(src)) {
    src.split('\n').forEach((t, i) => {
      if (/["'`]https?:\/\/(localhost|127\.0\.0\.1):\d+/.test(t) && !/\?\?|\|\||local|dev|fallback|default|^\s*(\/\/|\*)/i.test(t.replace(/https?:\/\/(localhost|127\.0\.0\.1)/g, ''))) out.push({ k: 'localhost', line: i + 1 });
    });
  }
  return out;
}

// ======================= build: turn findings into issues =======================

const SEV_ORDER = { high: 0, medium: 1, low: 2 };
const PUBLIC_PATH = /(^|\/)(health|healthz|healthcheck|ping|status|ready|readiness|live|liveness|version|metrics|robots\.txt|sitemap[\w.]*|favicon[\w.]*|\.well-known|login|logout|signin|pair|sign-in|signout|signup|sign-up|register|forgot[\w-]*|reset[\w-]*|verify[\w-]*|oauth\w*|callback|auth|token|refresh|static|assets|public|newsletter|contact|wait[l]ist|unsubscribe|openapi\.json|docs|swagger[\w.]*|i|images?)(\/|$)/i;
const WEBHOOK_PATH = /webhook|\/hooks?\//i;
// endpoints under a webhook URL that manage the webhooks (create, list, test…) rather than receive them
const WEBHOOK_ADMIN = /\/(manage|admin|setup|settings|config|list|create|register|delete|test[\w-]*)(\/|$)/i;
const NOT_USED_KINDS = new Set(['test', 'script', 'infra', 'config', 'worker', 'external']);
const SPECIAL_FILE = /(^|\/)(index|main|app|server|cli|manage|wsgi|asgi|__init__|__main__|conftest|setup|config|settings|env|middleware|instrumentation|layout|page|route|loading|error|not-found|template|default|global-error|sitemap|robots|manifest|opengraph-image|twitter-image|icon|apple-icon|_app|_document|_error|404|500|models|admin|apps|views|urls|signals|tasks|forms|serializers|celery|gunicorn\.conf|vite-env\.d|worker|sw|service-worker)\.[a-z]+$|\.d\.ts$|\.config\.[a-z]+$|\.stories\.|(^|\/)(pages|migrations|alembic|versions|scripts|bin|tools|seeds?|fixtures?|examples?|docs?|public|static|templates|\.github|e2e|cypress|playwright)\//i;
const USED_LANGS = new Set(['typescript', 'javascript', 'python', 'vue', 'svelte', 'astro']);
const plural = (n, w, ws) => `${n} ${n === 1 ? w : ws || w + 's'}`;
const nl = (n) => `${n.toLocaleString('fr-FR')} ligne${n === 1 ? '' : 's'}`;

export function buildHealth({ graph, scan, arch, root }) {
  const issues = [];
  const nodeById = new Map(graph.nodes.map((n) => [n.id, n]));
  const fileByPath = new Map(graph.files.map((f) => [f.p, f]));
  const scanByPath = new Map(scan.files.map((f) => [f.path, f]));
  const lineage = (id) => { const out = []; let n = nodeById.get(id); while (n) { out.push(n); n = n.parent ? nodeById.get(n.parent) : null; } return out; };
  const kinds = (id) => lineage(id).map((n) => n.kind);
  const isFrontend = (p) => { const f = fileByPath.get(p); return !!f && kinds(f.n).includes('ui'); };
  const nameOf = (p) => fileByPath.get(p)?.name || p.split('/').pop();
  const label = (id) => nodeById.get(id)?.label || id;
  // Files outside the map (config, .env, Firebase rules) point at the module that owns their folder, or
  // failing that the most specific part of the map whose paths name them.
  const archGlobs = (arch?.nodes || []).filter((n) => n?.id && nodeById.has(n.id) && Array.isArray(n.paths)).flatMap((n) => n.paths.map((p) => ({ id: n.id, g: compileGlob(p) })));
  const globOwner = (p) => archGlobs.filter((x) => x.g.test(p)).sort((a, b) => b.g.specificity - a.g.specificity)[0]?.id;
  const dirOwner = new Map();
  for (const f of graph.files) { let d = f.p; while (d.includes('/')) { d = d.slice(0, d.lastIndexOf('/')); if (!dirOwner.has(d)) dirOwner.set(d, new Map()); const m = dirOwner.get(d); m.set(f.n, (m.get(f.n) || 0) + 1); } }
  const itemFor = (p) => {
    if (fileByPath.has(p)) return 'f:' + p;
    let d = p;
    while (d.includes('/')) {
      d = d.slice(0, d.lastIndexOf('/'));
      const m = dirOwner.get(d);
      const top = m && [...m.entries()].filter(([n]) => n !== 'unassigned').sort((a, b) => b[1] - a[1])[0];
      if (top) return 'n:' + top[0];
    }
    const owner = globOwner(p);
    return owner ? 'n:' + owner : null;
  };
  const findings = (p) => scanByPath.get(p)?.issues || [];

  // ---------- secrets in code and config ----------
  const secretFiles = [];
  for (const f of scan.files) {
    const s = findings(f.path).filter((x) => x.k === 'secret');
    if (s.length) secretFiles.push({ path: f.path, list: s });
  }
  // credential files (service-account JSON, .pem keys) that the scanner doesn't read as config
  for (const f of scan.files) {
    const base = f.path.split('/').pop();
    if (TEST_FILE.test(f.path) || EXAMPLE_FILE.test(f.path) || /\.pub$/.test(base)) continue;
    if (!/\.(pem|key|p12|pfx|jks|keystore)$|^id_(rsa|dsa|ecdsa|ed25519)$|service[-_]?account.*\.json$|^credentials?\.json$|firebase-adminsdk.*\.json$|^client_secret.*\.json$|-key\.json$/i.test(base)) continue;
    let head = '';
    try { head = readHead(path.join(root, f.path), 65536); } catch { continue; }
    if (/PRIVATE KEY|"private_key"\s*:\s*"-----|"client_secret"\s*:\s*"[^"]{8,}/.test(head) || /\.(p12|pfx|jks|keystore)$/i.test(base)) secretFiles.push({ path: f.path, list: [{ k: 'secret', line: 1, what: 'un fichier d’identifiants (une clé privée qui se connecte en tant que votre app)', sev: 'high', hint: 'fichier entier' }], file: true });
  }
  const secretIssue = (group) => {
    const locations = [], notes = {}, items = [];
    const kinds = new Set(), svcs = new Set();
    let frontend = false;
    for (const { path: p, list, file } of group) {
      list.sort((a, b) => a.line - b.line);
      const it = itemFor(p);
      if (it && !items.includes(it)) items.push(it);
      for (const s of list) {
        locations.push({ file: p, line: s.line });
        kinds.add(s.what);
        if (s.svc) svcs.add(s.svc);
      }
      if (isFrontend(p)) frontend = true;
      if (it) notes[it] = (notes[it] ? notes[it] + ' · ' : '') + list.slice(0, 4).map((s) => `${file ? p.split('/').pop() : `ligne ${s.line}`} : `
        + `${s.name ? `${s.name}, ` : ''}${s.what.replace(/ \(.*\)$/, '')} (${s.hint})`).join(' · ') + (list.length > 4 ? ` · +${list.length - 4} autres` : '');
    }
    const n = locations.length;
    // every hit sits in a test, fixture or example file: most likely a made-up key, so the tone drops (never above "worth fixing soon")
    const allTest = group.every((g) => g.list.every((s) => s.test));
    const sev = !allTest && group.some((g) => g.list.some((s) => s.sev === 'high')) ? 'high' : 'medium';
    const one = group.length === 1 ? group[0].path : null;
    const where = one ? one.split('/').pop() : `${group.length} autres fichiers`;
    const src = one ? `${nameOf(one)} (${one})` : plural(group.length, 'fichier');
    const kindText = kinds.size === 1 ? [...kinds][0].replace(/ \(.*\)$/, '') : 'des mots de passe ou des clés';
    const sing = n === 1;
    const testDetail = [
      `${src} ${one ? 'est un fichier de test ou d’exemple et contient' : 'sont des fichiers de test ou d’exemple et contiennent'}`,
      `${sing ? kindText : `${n} clés (${kindText})`} au format d’${sing ? 'un vrai secret' : 'de vrais secrets'}.`,
      sing ? 'Ce secret est probablement factice, inventé pour le test.' : 'Ces secrets sont probablement factices, inventés pour le test.',
      sing ? 'Si c’est un vrai secret, considérez-le comme divulgué et remplacez-le.' : 'Si ce sont de vrais secrets, considérez-les comme divulgués et remplacez-les.',
    ].join(' ');
    const target = svcs.size ? `à ${[...svcs].slice(0, 4).join(', ')}` : sing ? 'aux services qu’il ouvre' : 'aux services qu’ils ouvrent';
    const realDetail = `${src} ${one ? 'contient' : 'contiennent'} ${sing ? kindText : `${n} secrets (${kindText})`}. `
      + `Quiconque peut voir le code peut ${sing ? 'l’utiliser' : 'les utiliser'} pour accéder ${target} en se faisant passer pour vous`
      + `${frontend ? ', et ce code est envoyé au navigateur de chaque visiteur' : ''}. `
      + (sing ? 'Considérez ce secret comme divulgué : sortez-le du code et remplacez-le par un nouveau.'
        : 'Considérez ces secrets comme divulgués : sortez-les du code et remplacez-les par de nouveaux.');
    const hasPy = group.some((g) => /\.py$/.test(g.path)), hasJs = group.some((g) => /\.[jt]sx?$/.test(g.path));
    const envLookup = [hasPy ? 'os.environ["NAME"] en Python' : '', hasPy && hasJs ? ', ' : '', hasJs ? 'process.env.NAME en JavaScript/TypeScript' : '',
      !group.some((g) => /\.(py|[jt]sx?)$/.test(g.path)) ? 'ou une référence à un gestionnaire de secrets' : ''].join('');
    return {
      id: 'secret:' + (one || group.map((g) => g.path).join('|')),
      kind: 'secret', severity: sev,
      title: allTest
        ? (sing ? `Une clé dans ${where} est probablement factice` : `${n} clés dans ${where} sont probablement factices`)
        : sing ? `Une clé secrète est écrite dans ${where}` : `${n} mots de passe ou clés sont écrits dans ${where}`,
      detail: allTest ? testDetail : realDetail,
      items, notes, locations,
      fix: [
        `Correctif de sécurité : secrets écrits en dur. N’affiche, ne répète et n’écris jamais la valeur d’un secret dans tes réponses, tes commits `
          + `ou tes journaux.`,
        ``,
        `Ces lignes contiennent ${sing ? 'un secret écrit' : 'des secrets écrits'} directement dans le code :`,
        ...group.flatMap(({ path: p, list, file }) => list.map((s) => `- ${p}${file ? ' (le fichier entier)' : `:${s.line}`} : ${s.name ? `${s.name} `
          + `— ` : ''}${s.what.replace(/ \(.*\)$/, '')}`)),
        ``,
        `Pour chacun :`,
        `1. Remplace la valeur littérale par la lecture d’une variable d’environnement (${envLookup}), avec un nom de variable explicite. Si l’app ne `
          + `peut pas tourner sans elle, échoue avec une erreur claire quand elle manque au lieu de retomber sur une valeur écrite en dur.`,
        `2. Ajoute le nom de chaque variable (avec une valeur vide, jamais la vraie) à .env.example, et vérifie que .env figure dans .gitignore.`,
        frontend ? `3. Ce code part dans le navigateur. Déplace l’appel qui a besoin du secret vers une route ou une fonction côté serveur, pour que `
          + `la clé n’atteigne jamais les visiteurs.` : `3. Mets à jour la configuration de déploiement (Docker, Cloud Run, Vercel, etc.) pour que la `
          + `variable soit définie en production.`,
        group.some((g) => g.file) ? `4. Retire le fichier d’identifiants du dépôt (git rm --cached), ajoute son nom à .gitignore, et charge-le depuis `
          + `un chemin donné par une variable d’environnement.` : `4. Lance l’app ou ses tests pour confirmer qu’elle démarre encore avec les `
          + `variables définies.`,
        ``,
        `Puis donne-moi une courte liste de contrôle (sans les valeurs) des services auxquels ces clés appartiennent, pour que je les renouvelle une `
          + `à une : créer une nouvelle clé dans le tableau de bord du service, la mettre dans mon environnement, puis révoquer l’ancienne. Comme les `
          + `anciennes valeurs sont dans l’historique git, considère-les comme compromises.`,
      ].join('\n'),
    };
  };
  secretFiles.sort((a, b) => b.list.length - a.list.length);
  const MAX_SECRET_ISSUES = 8;
  secretFiles.slice(0, MAX_SECRET_ISSUES).forEach((g) => issues.push(secretIssue([g])));
  if (secretFiles.length > MAX_SECRET_ISSUES) issues.push(secretIssue(secretFiles.slice(MAX_SECRET_ISSUES)));

  // ---------- .env files that are (or will be) committed ----------
  for (const f of scan.files) {
    const base = f.path.split('/').pop();
    if (!/^\.env(\.[\w.-]+)?$/i.test(base) || /example|sample|template|dist|defaults?|schema|test/i.test(base)) continue;
    let src = '';
    try { src = readHead(path.join(root, f.path), 262144); } catch { continue; }
    const secretVars = [];
    src.split('\n').forEach((t, i) => {
      const m = /^\s*(?:export\s+)?([A-Za-z_][\w.]*)\s*=\s*["']?([^"'#\s]*)/.exec(t);
      if (!m || !m[2]) return;
      const n = snake(m[1]);
      const known = FORMATS.some((fm) => { fm.re.lastIndex = 0; const hit = fm.re.test(m[2]); fm.re.lastIndex = 0; return hit; });
      if (known || (SECRET_NAME.test(n) && !PUBLIC_NAME.test(n) && valueLooksReal(m[2], n)) || (/url|uri|dsn/i.test(n) && /:\/\/[^:\s\/]+:[^@\s]+@/.test(m[2]))) secretVars.push({ name: m[1], line: i + 1 });
    });
    if (!secretVars.length) continue;
    const repoAbs = f.repo ? path.join(root, f.repo) : root;
    const relInRepo = f.repo ? f.path.slice(f.repo.length + 1) : f.path;
    const tracked = !!git(repoAbs, ['ls-files', '--', relInRepo]);
    const it = itemFor(f.path);
    issues.push({
      id: 'env-file:' + f.path, kind: 'env-file', severity: tracked ? 'high' : 'medium',
      title: tracked ? 'Votre fichier de réglages privés est enregistré dans git' : 'Votre fichier de réglages privés n’est pas caché de git',
      detail: tracked
        ? `${f.path} contient ${plural(secretVars.length, 'mot de passe ou clé', 'mots de passe et clés')} et est commité : toute personne qui a accès au code `
          + `(et à son historique) peut ${secretVars.length === 1 ? 'le lire' : 'les lire'}. Ce fichier doit rester uniquement sur votre ordinateur.`
        : `${f.path} contient ${plural(secretVars.length, 'mot de passe ou clé', 'mots de passe et clés')} et n’est pas listé dans .gitignore : `
          + `le prochain commit ${secretVars.length === 1 ? 'l’enverra' : 'les enverra'} avec votre code.`,
      items: it ? [it] : [], notes: it ? { [it]: `${f.path} : `
        + `${secretVars.slice(0, 6).map((v) => v.name).join(', ')}${secretVars.length > 6 ? '…' : ''}` } : {},
      locations: secretVars.map((v) => ({ file: f.path, line: v.line })),
      fix: [
        `Correctif de sécurité : ${f.path} contient des secrets et ${tracked ? 'est commité dans git' : 'n’est pas ignoré par git'}. N’affiche et ne `
          + `répète aucune valeur qu’il contient.`,
        ``,
        `1. Ajoute ${base} (et .env*.local) à ${f.repo ? f.repo + '/' : ''}.gitignore, en gardant .env.example suivi.`,
        tracked ? `2. Arrête de le suivre sans supprimer ma copie locale : git rm --cached "${relInRepo}" (à lancer dans ${f.repo || 'le dépôt'}), `
          + `puis commite.` : `2. Vérifie avec git status que le fichier n’apparaît plus comme nouveau fichier.`,
        `3. Crée ou mets à jour .env.example à côté, avec les mêmes noms de variables et des valeurs vides : ${secretVars.map((v) => v.name).join(', ')}.`,
        tracked
          ? `4. Donne-moi une liste de contrôle (noms seulement, sans valeurs) des clés à renouveler dans le tableau de bord de chaque service, car `
            + `elles sont dans l’historique git. `
            + `Précise que les retirer de l’historique demande un outil comme git filter-repo, et demande-moi avant de le faire.`
          : `4. Dis-moi quels réglages de déploiement ont besoin de ces variables.`,
      ].join('\n'),
    });
  }

  // ---------- secret keys in variables the browser gets (NEXT_PUBLIC_, VITE_ …) ----------
  const live = (p) => !TEST_FILE.test(p) && !EXAMPLE_FILE.test(p);
  const publicVars = new Map(); // name -> { svc, refs: [{file, line}], defs: [{file, line}] }
  const publicVar = (name) => { if (!publicVars.has(name)) publicVars.set(name, { name, svc: leakyPublicVar(name), refs: [], defs: [] }); return publicVars.get(name); };
  for (const f of scan.files) if (live(f.path)) for (const x of findings(f.path)) if (x.k === 'public-env') publicVar(x.name).refs.push({ file: f.path, line: x.line });
  for (const f of scan.files) {
    const base = f.path.split('/').pop();
    if (!/^\.env(\.[\w.-]+)?$/i.test(base) || /example|sample|template|dist|schema/i.test(base) || !live(f.path)) continue;
    let src = '';
    try { src = readHead(path.join(root, f.path), 262144); } catch { continue; }
    src.split('\n').forEach((t, i) => {
      const m = /^\s*(?:export\s+)?([A-Z][A-Z0-9_]*)\s*=\s*["']?([^"'#\s]*)/.exec(t);
      if (m && m[2] && !PLACEHOLDER.test(m[2]) && !/^\$/.test(m[2]) && leakyPublicVar(m[1]) !== null) publicVar(m[1]).defs.push({ file: f.path, line: i + 1 });
    });
  }
  if (publicVars.size) {
    const vars = [...publicVars.values()];
    const browserSide = (p) => isFrontend(p) || /\.(jsx|tsx|vue|svelte|astro)$/.test(p);
    const sev = vars.some((v) => CLIENT_ONLY_PREFIX.test(v.name) || v.refs.some((r) => browserSide(r.file))) ? 'high' : 'medium';
    const svcs = [...new Set(vars.map((v) => v.svc).filter(Boolean))];
    const locations = vars.flatMap((v) => [...v.defs, ...v.refs]);
    const items = [], notes = {};
    for (const v of vars) for (const loc of [...v.refs, ...v.defs]) {
      const it = itemFor(loc.file);
      if (!it) continue;
      if (!items.includes(it)) items.push(it);
      const note = `ligne ${loc.line} : ${v.name}`;
      if (!(notes[it] || '').includes(note)) notes[it] = (notes[it] ? notes[it] + ' · ' : '') + note;
    }
    const names = vars.map((v) => v.name);
    issues.push({
      id: 'public-env', kind: 'public-env-secret', severity: sev,
      title: vars.length === 1 ? `Le réglage ${names[0]} est envoyé au navigateur de chaque visiteur` : `${vars.length} clés secrètes sont envoyées `
        + `au navigateur de chaque visiteur`,
      detail: `Les réglages dont le nom commence par NEXT_PUBLIC_, VITE_ et similaires sont copiés dans le code que votre site envoie à chaque visiteur, `
        + `où n’importe qui peut les lire dans les outils de développement de son navigateur. `
        + `${vars.length === 1 ? `${names[0]} ressemble à une clé secrète` : `${names.slice(0, 4).join(', ')}${vars.length > 4 ? '…' : ''} `
          + `ressemblent à des clés secrètes`}`
        + `${svcs.length ? ` (pour ${svcs.slice(0, 4).join(', ')})` : ''} : n’importe qui pourrait `
          + `${vars.length === 1 ? 'l’utiliser' : 'les utiliser'} en se faisant passer pour vous, `
        + `faire grimper votre facture, envoyer des messages en votre nom ou accéder à vos données.`
        + `${sev === 'medium' ? ' Pour l’instant, seul du code serveur semble le lire : il n’a peut-être pas encore atteint un navigateur, mais son nom y invite.' : ''}`,
      items, notes, locations,
      fix: [
        `Correctif de sécurité : clés secrètes dans des variables d’environnement publiques (le navigateur reçoit toute variable avec ces préfixes). `
          + `N’affiche, n’écris et ne répète aucune valeur de clé.`,
        ``,
        ...vars.map((v) => `- ${v.name}${v.svc ? ` (${v.svc})` : ''} : ${[...v.defs.map((d) => `défini dans `
          + `${d.file}:${d.line}`), ...v.refs.map((r) => `utilisé dans ${r.file}:${r.line}`)].slice(0, 6).join(', ')}`),
        ``,
        `Pour chacune :`,
        `1. Renomme-la sans le préfixe public (par exemple OPENAI_API_KEY au lieu de VITE_OPENAI_API_KEY) dans les fichiers .env, .env.example et les `
          + `réglages de l’hébergeur.`,
        `2. Déplace chaque endroit qui l’utilise dans du code côté serveur (un route handler ou une server action Next.js, une Edge Function Supabase, `
          + `une fonction serverless ou le backend existant) et fais appeler cela par le frontend, pour que la clé n’atteigne jamais le navigateur.`,
        vars.some((v) => v.svc === 'Supabase')
          ? `3. Pour la clé service-role Supabase : le code du navigateur doit utiliser la clé anon et s’appuyer sur la sécurité au niveau des lignes `
            + `(RLS) ; seul le code serveur peut utiliser la clé service-role.`
          : `3. Garde le frontend fonctionnel à l’identique, et lance l’app pour vérifier.`,
        ``,
        `Puis donne-moi une liste de contrôle (noms seulement, sans valeurs) des clés à renouveler dans le tableau de bord de chaque service : toute `
          + `personne qui a chargé le site a pu les copier.`,
      ].join('\n'),
    });
  }

  // ---------- Supabase tables anyone can read and change ----------
  const usesSupabase = scan.files.some((f) => /(^|\/)supabase\/(migrations\/|config\.toml$|functions\/)/.test(f.path) || findings(f.path).some((x) => x.k === 'uses-supabase'));
  if (usesSupabase) {
    const byRepo = new Map(); // repo -> [file, …] in path order (migrations are named by timestamp)
    for (const f of scan.files) if (f.lang === 'sql' && live(f.path) && findings(f.path).some((x) => x.k.startsWith('sql-'))) { const k = f.repo ?? ''; if (!byRepo.has(k)) byRepo.set(k, []); byRepo.get(k).push(f.path); }
    for (const [repo, sqlFiles] of byRepo) {
      const tables = new Map(); // table -> { file, line, rls, off }
      const policies = [];
      for (const p of sqlFiles.sort()) for (const x of findings(p)) {
        const t = tables.get(x.table);
        if (x.k === 'sql-table' && !t) tables.set(x.table, { file: p, line: x.line, rls: null });
        else if (x.k === 'sql-rls' && t) { t.rls = x.on; t.off = x.on ? null : { file: p, line: x.line }; }
        else if (x.k === 'sql-rename' && t) { tables.delete(x.table); tables.set(x.to, t); for (const pol of policies) if (pol.table === x.table) pol.table = x.to; }
        else if (x.k === 'sql-drop') tables.delete(x.table);
        else if (x.k === 'sql-open-policy') policies.push({ ...x, file: p });
      }
      const short = (t) => t.replace(/^public\./, '');
      const open = [...tables.entries()].filter(([name, t]) => name.startsWith('public.') && t.rls !== true);
      if (open.length) {
        const items = [], notes = {};
        for (const [name, t] of open) {
          const it = itemFor(t.file);
          if (!it) continue;
          if (!items.includes(it)) items.push(it);
          notes[it] = (notes[it] ? notes[it] + ' · ' : '') + `ligne ${t.line} : ${short(name)} (sécurité au niveau des lignes `
            + `${t.off ? 'désactivée' : 'jamais activée'})`;
        }
        const list = open.map(([name]) => short(name));
        issues.push({
          id: 'rls:' + repo, kind: 'database-rules', severity: 'high',
          title: open.length === 1 ? `N’importe qui peut lire et modifier votre table ${list[0]}` : `N’importe qui peut lire et modifier `
            + `${open.length} de vos tables`,
          detail: `Votre application parle à Supabase avec une clé publique que le navigateur de chaque visiteur possède. `
            + `La sécurité au niveau des lignes (RLS) empêche une personne de lire ou modifier les lignes d’une autre, et elle est désactivée pour `
            + `${open.length === 1 ? `la table ${list[0]}` : `${list.slice(0, 6).join(', ')}${list.length > 6 ? ` et ${list.length - 6} autres` : ''}`}. `
            + `Sans elle, n’importe qui peut utiliser cette clé pour lire, modifier ou supprimer chaque ligne${open.length === 1 ? '' : ' de ces tables'}. `
            + `Si votre application n’accède à la base que depuis son propre serveur, le risque est plus faible, mais l’activer reste le choix le plus sûr.`,
          items, notes,
          locations: open.map(([, t]) => t.off || { file: t.file, line: t.line }),
          fix: [
            `Correctif de sécurité : tables Supabase sans sécurité au niveau des lignes (RLS). N’affiche aucune clé.`,
            ``,
            `N’importe qui possédant la clé publique (anon) de l’app peut lire et modifier ces tables :`,
            ...open.map(([name, t]) => `- ${name} : créée dans ${t.file}:${t.line}${t.off ? `, sécurité au niveau des lignes désactivée dans `
              + `${t.off.file}:${t.off.line}` : ''}`),
            ``,
            `1. Lis comment l’app utilise chaque table : quelles pages la lisent ou l’écrivent, et si les lignes appartiennent à un utilisateur (par `
              + `exemple une colonne user_id qui doit correspondre à auth.uid()).`,
            `2. Écris une nouvelle migration (ne modifie pas les anciennes) qui exécute \`alter table <table> enable row level security;\` pour chaque table, `
              + `plus des policies pour que l’app continue de fonctionner : en général les utilisateurs connectés ne lisent et ne modifient que leurs `
                + `propres lignes `
              + `(\`using (auth.uid() = user_id)\`), et les tables faites pour être publiques reçoivent une policy en lecture seule. `
              + `Le code serveur qui utilise la clé service-role n’est pas affecté par ces règles.`,
            `3. Explique-moi les policies en langage simple avant d’appliquer quoi que ce soit, et n’assouplis aucune policy existante.`,
            `4. Dis-moi comment appliquer la migration (par exemple \`supabase db push\`) et comment vérifier, déconnecté, que je ne peux pas lire `
              + `les lignes des autres.`,
          ].join('\n'),
        });
      }
      const loose = policies.filter((pol) => tables.get(pol.table)?.rls === true);
      if (loose.length) {
        const rowsOf = (cmd, t) => ({ insert: `d’ajouter des lignes à ${t}`, update: `de modifier des lignes dans ${t}`, delete: `de supprimer des `
          + `lignes de ${t}` }[cmd]
          || `d’ajouter, de modifier et de supprimer des lignes dans ${t}`);
        const items = [], notes = {};
        for (const pol of loose) {
          const it = itemFor(pol.file);
          if (!it) continue;
          if (!items.includes(it)) items.push(it);
          notes[it] = (notes[it] ? notes[it] + ' · ' : '') + `ligne ${pol.line} : “${pol.policy}” permet à n’importe qui ${rowsOf(pol.cmd, short(pol.table))}`;
        }
        issues.push({
          id: 'open-policy:' + repo, kind: 'database-rules', severity: 'medium',
          title: loose.length === 1 ? `Une règle de base de données permet à n’importe qui de modifier votre table `
            + `${short(loose[0].table)}` : `${loose.length} règles de base de données permettent à n’importe qui de modifier vos données`,
          detail: `${loose.length === 1 ? `La règle “${loose[0].policy}” permet` : 'Ces règles permettent'} à n’importe `
            + `qui${loose.some((pol) => pol.signedOut) ? ', même aux personnes non connectées,' : ''} `
            + `${loose.length === 1 ? rowsOf(loose[0].cmd, short(loose[0].table)) : `d’ajouter, de modifier ou de supprimer des lignes dans `
              + `${[...new Set(loose.map((pol) => short(pol.table)))].slice(0, 5).join(', ')}`}. `
            + `Si une table est un formulaire public (liste de diffusion, formulaire de contact), laisser n’importe qui ajouter des lignes convient ; `
            + `sinon, limitez-le aux personnes connectées et à leurs propres lignes.`,
          items, notes,
          locations: loose.map((pol) => ({ file: pol.file, line: pol.line })),
          fix: [
            `Revue de sécurité : policies de sécurité au niveau des lignes Supabase qui permettent à n’importe qui de modifier des données (\`using `
              + `(true)\` / \`with check (true)\` pour anon ou public) :`,
            ...loose.map((pol) => `- “${pol.policy}” sur ${pol.table} (pour ${pol.cmd}) — ${pol.file}:${pol.line}`),
            ``,
            `Pour chacune, dis-moi en langage simple ce qu’elle autorise et si l’app en a besoin. Si la table n’est pas faite pour être publique, `
              + `remplace \`true\` par un contrôle comme \`auth.uid() = user_id\`, limité aux utilisateurs authentifiés, dans une nouvelle migration. `
              + `Si c’est un formulaire public, laisse l’ajout de lignes ouvert mais assure-toi que personne ne puisse lire, modifier ou supprimer `
                + `les lignes des autres. `
              + `Montre-moi la modification avant de l’appliquer.`,
          ].join('\n'),
        });
      }
    }
  }

  // ---------- Firebase security rules that let anyone in ----------
  const today = new Date();
  const longDate = (d) => d.toLocaleDateString('fr-FR', { timeZone: 'UTC', month: 'long', day: 'numeric', year: 'numeric' });
  for (const f of scan.files) {
    const base = f.path.split('/').pop();
    if (!live(f.path) || !(/\.rules$/i.test(base) || /^database(\.[\w-]+)?\.rules\.json$/i.test(base))) continue;
    let src = '';
    try { src = readHead(path.join(root, f.path), 262144); } catch { continue; }
    const rtdb = /\.json$/i.test(base);
    const service = rtdb ? 'Realtime Database' : /service\s+firebase\.storage/.test(src) ? 'Storage' : /service\s+cloud\.firestore/.test(src) ? 'Firestore' : null;
    if (!service) continue;
    const rules = rtdb ? firebaseRtdbRules(src, today) : firebaseRules(src, today);
    // the whole database, or (Firestore and Storage) any change beyond adding new records to one place
    const severe = (r) => r.wide || (!rtdb && !r.createOnly);
    const writes = rules.filter((r) => r.write && r.open !== 'expired' && severe(r));
    const deepWrites = rules.filter((r) => r.write && r.open === 'always' && !severe(r));
    const reads = rules.filter((r) => r.read && !r.write && r.open !== 'expired' && r.wide);
    const until = rules.find((r) => r.open === 'until');
    const expired = rules.find((r) => r.open === 'expired');
    if (!writes.length && !deepWrites.length && !reads.length && !expired) continue;
    const files = service === 'Storage';
    const what = files ? 'files' : 'data';
    const deploy = { Firestore: 'firestore:rules', Storage: 'storage', 'Realtime Database': 'database' }[service];
    const shown = [...writes, ...deepWrites, ...reads, ...(expired ? [expired] : [])];
    let title, detail, severity;
    if (until && writes.length) {
      severity = 'high';
      title = `Votre Firebase ${service} est ouvert à tous jusqu’au ${longDate(until.until)}`;
      detail = `${base} a encore les règles du « mode test » de Firebase : n’importe qui peut lire et modifier ${files ? 'tous les fichiers' : 'tout'} `
        + `jusqu’au ${longDate(until.until)}, sans se connecter ni passer par votre app. Après cette date, toute requête est refusée et l’app cesse `
          + `de fonctionner : `
        + `remplacez-les par de vraies règles plutôt que de repousser la date.`;
    } else if (writes.length) {
      severity = 'high';
      title = files ? 'N’importe qui peut envoyer, remplacer ou supprimer vos fichiers Firebase' : `N’importe qui peut modifier ou supprimer vos `
        + `données Firebase ${service}`;
      detail = `Une règle de ${base} (ligne ${writes[0].line}, à ${writes[0].where}) permet à n’importe qui, connecté ou non, `
        + `${files ? 'd’envoyer, de remplacer ou de supprimer des fichiers' : 'd’ajouter, de modifier ou de supprimer des données'}. `
        + `Les réglages Firebase de votre app sont dans le navigateur de chaque visiteur : n’importe qui peut s’en servir pour atteindre directement `
        + `votre ${service}, sans passer par votre app.`;
    } else if (deepWrites.length || reads.length) {
      severity = 'medium';
      title = reads.length && !deepWrites.length ? `N’importe qui peut tout lire dans votre Firebase ${service}` : `N’importe qui peut modifier une `
        + `partie de votre Firebase ${service}`;
      detail = [
        reads.length ? `Une règle de ${base} (ligne ${reads[0].line}) permet à n’importe qui de lire ${files ? 'chaque fichier' : 'chaque enregistrement'}, `
          + `y compris des données qui peuvent appartenir à vos utilisateurs. Si tout ce qui s’y trouve est fait pour être public, ce n’est pas grave `
            + `; sinon il faut une vérification de connexion.` : '',
        deepWrites.length ? `Une règle de ${base} (ligne ${deepWrites[0].line}) permet à n’importe qui `
          + `${deepWrites[0].createOnly ? 'd’ajouter à' : 'de modifier'} ${deepWrites[0].where} sans se connecter. `
          + `Si c’est un formulaire public (liste de diffusion, formulaire de contact), cela peut convenir ; sinon il faut une vérification de connexion.` : '',
      ].filter(Boolean).join(' ');
    } else {
      severity = 'medium';
      title = `Les règles « mode test » de votre Firebase ${service} ont expiré le ${longDate(expired.until)}`;
      detail = `${base} a les règles du « mode test » de Firebase, qui ont cessé d’autoriser l’accès le ${longDate(expired.until)}. `
        + `Toute lecture et toute écriture est désormais refusée : les parties de l’app qui utilisent ${service} ne fonctionneront pas. `
        + `Remplacez-les par de vraies règles plutôt que de repousser la date, ce qui rouvrirait tout à tout le monde.`;
    }
    const it = itemFor(f.path);
    issues.push({
      id: 'firebase-rules:' + f.path, kind: 'database-rules', severity, title, detail,
      items: it ? [it] : [], notes: it ? { [it]: shown.slice(0, 4).map((r) => `ligne ${r.line} : ${r.text}`).join(' · ') } : {},
      locations: shown.map((r) => ({ file: f.path, line: r.line })),
      fix: [
        `Correctif de sécurité : règles de sécurité Firebase ${service} dans ${f.path}.`,
        ``,
        `Ces règles laissent entrer n’importe qui (ou ont expiré) :`,
        ...shown.map((r) => `- ligne ${r.line} : ${r.text}`),
        ``,
        `1. Lis comment l’app utilise chaque ${rtdb ? 'chemin' : files ? 'dossier de stockage' : 'collection'} : ce que chaque écran lit et écrit, et `
          + `quelles données appartiennent à un utilisateur `
          + `(par exemple ${files ? 'des fichiers sous un dossier nommé d’après l’uid de l’utilisateur' : 'des documents indexés par l’uid de l’utilisateur, ou avec un champ ownerId'}).`,
        `2. Réécris les règles pour que les utilisateurs connectés ne lisent et n’écrivent que leurs propres ${files ? 'fichiers' : 'données'} `
          + `(${rtdb ? 'auth != null && auth.uid === $uid' : files ? 'request.auth != null && request.auth.uid == userId' : 'request.auth != null && request.auth.uid == resource.data.ownerId'}), `
          + `que le contenu public soit en lecture seule, et que tout le reste soit refusé. N’utilise pas de dates de mode test.`,
        `3. Explique-moi les nouvelles règles en langage simple et attends mon accord.`,
        `4. Puis déploie-les avec \`firebase deploy --only ${deploy}\` et vérifie-les dans le Rules Playground de la console Firebase (ou l’émulateur) : `
          + `un utilisateur déconnecté ne doit pouvoir rien lire ni modifier de privé.`,
      ].join('\n'),
    });
  }

  // ---------- Stripe webhooks that don't check Stripe's signature ----------
  const stripeFiles = new Map(); // file -> finding
  for (const f of scan.files) if (live(f.path)) { const x = findings(f.path).find((y) => y.k === 'stripe-unsigned'); if (x) stripeFiles.set(f.path, x); }
  for (const [file, x] of stripeFiles) {
    const routesHere = graph.routes.map((r, i) => ({ r, i })).filter(({ r }) => r.f === file && r.m !== 'GET');
    const it = itemFor(file);
    const items = [...(it ? [it] : []), ...routesHere.map(({ i }) => 'r:' + i)];
    const py = /\.py$/.test(file);
    const next = /(^|\/)app\/.*route\.[jt]s$|(^|\/)pages\/api\//.test(file);
    issues.push({
      id: 'stripe-webhook:' + file, kind: 'stripe-webhook', severity: 'high',
      title: `N’importe qui pourrait simuler un paiement Stripe dans ${nameOf(file)}`,
      detail: `${file.split('/').pop()} traite des événements Stripe (comme « ${x.events[0]} ») sans vérifier la signature de Stripe : `
        + `quiconque trouve l’adresse peut envoyer un faux message « paiement réussi » et obtenir gratuitement des commandes, des crédits ou un abonnement. `
        + `Stripe signe chaque vrai événement ; vérifier cette signature tient en quelques lignes.`,
      items, notes: Object.fromEntries(items.map((id) => [id, id.startsWith('r:') ? 'Reçoit des événements Stripe sans vérifier qu’ils sont authentiques' : `ligne ${x.line} : traite ${x.events.join(', ')} sans vérifier la signature Stripe`])),
      locations: [{ file, line: x.line }],
      fix: [
        `Correctif de sécurité dans ${file} : vérifier les signatures des webhooks Stripe avant d’agir sur un événement. N’affiche aucune valeur secrète.`,
        ``,
        `Il traite ${x.events.join(', ')} (ligne ${x.line}) sans appeler ${py ? 'stripe.Webhook.construct_event' : 'stripe.webhooks.constructEvent'}.`,
        ``,
        py
          ? `1. Lis le corps brut de la requête en octets (FastAPI : \`await request.body()\` ; Flask : \`request.get_data()\`), pas le JSON analysé.`
          : next ? `1. Lis le corps brut de la requête avec \`await req.text()\` (App Router) ou désactive le body parser pour cette route (Pages `
            + `Router), pas le JSON analysé.`
            : `1. Donne à cette route le corps brut : \`express.raw({ type: 'application/json' })\` sur elle, enregistré avant que \`express.json()\` `
              + `ne s’exécute pour elle.`,
        py
          ? `2. Appelle \`stripe.Webhook.construct_event(payload, request.headers["stripe-signature"], os.environ["STRIPE_WEBHOOK_SECRET"])\` et `
            + `renvoie 400 s’il lève une exception.`
          : `2. Appelle \`stripe.webhooks.constructEvent(rawBody, signatureHeader, process.env.STRIPE_WEBHOOK_SECRET)\` (l’en-tête `
            + `\`stripe-signature\`) et renvoie 400 s’il lève une erreur.`,
        `3. N’utilise ensuite que l’événement vérifié, et traite chaque événement une seule fois même si Stripe le renvoie.`,
        `4. Ajoute STRIPE_WEBHOOK_SECRET (vide) à .env.example et dis-moi où l’obtenir : le tableau de bord Stripe (Developers → Webhooks → le `
          + `endpoint → Signing secret), `
          + `ou \`stripe listen\` en test local.`,
      ].join('\n'),
    });
  }

  // ---------- servers that let any website call them (CORS) ----------
  const cors = [];
  for (const f of scan.files) if (live(f.path)) for (const x of findings(f.path)) if (x.k === 'cors-any') cors.push({ file: f.path, ...x });
  if (cors.length) {
    const cred = cors.filter((c) => c.credentials);
    const filesC = [...new Set(cors.map((c) => c.file))];
    const items = [], notes = {};
    for (const c of cors) {
      const it = itemFor(c.file);
      if (!it) continue;
      if (!items.includes(it)) items.push(it);
      notes[it] = (notes[it] ? notes[it] + ' · ' : '') + `ligne ${c.line} : ${c.how}${c.credentials ? ', avec les cookies de connexion' : ''}`;
    }
    issues.push({
      id: 'cors', kind: 'cors', severity: cred.length ? 'medium' : 'low',
      title: cred.length ? 'N’importe quel site web pourrait agir comme vos utilisateurs connectés' : 'N’importe quel site web peut appeler votre serveur depuis le navigateur d’un visiteur',
      detail: cred.length
        ? `${cred[0].file.split('/').pop()} permet à n’importe quel site web d’appeler ce serveur depuis le navigateur d’un visiteur et d’envoyer ses `
          + `cookies de connexion. `
          + `Un site qu’un utilisateur connecté visite par hasard pourrait donc lire discrètement ses données ou agir à sa place. Autorisez plutôt `
            + `uniquement l’adresse de votre propre app.`
        : `${filesC.length === 1 ? filesC[0].split('/').pop() : `${filesC.length} fichiers`} ${filesC.length === 1 ? 'indique' : 'indiquent'} aux `
          + `navigateurs que n’importe quel site web peut appeler ce serveur. `
          + `C’est acceptable pour une API publique qui n’utilise pas de cookies de connexion (par exemple une qui vérifie un jeton dans l’en-tête `
            + `Authorization) ; `
          + `sinon, autorisez uniquement l’adresse de votre propre app.`,
      items, notes,
      locations: cors.map((c) => ({ file: c.file, line: c.line })),
      fix: [
        `Revue de sécurité : réglages CORS qui autorisent tous les sites web :`,
        ...cors.map((c) => `- ${c.file}:${c.line} : ${c.how}${c.credentials ? ' (avec credentials)' : ''}`),
        ``,
        `Dis-moi d’abord en langage simple si ce serveur utilise des cookies de connexion ou des sessions, et quels sites web l’appellent légitimement. `
          + `Remplace ensuite le réglage « tout autoriser » par une liste explicite d’origines autorisées lue depuis une variable d’environnement `
          + `(par exemple ALLOWED_ORIGINS=https://myapp.com,http://localhost:3000). Garde les credentials seulement si l’app se connecte par cookies, `
          + `et ne les combine jamais avec "*" ni avec le renvoi de n’importe quelle origine qui le demande. `
          + `Montre-moi la modification avant de la faire, et ne change rien d’autre.`,
      ].join('\n'),
    });
  }

  // ---------- endpoints anyone can call ----------
  const routeFinding = new Map(); // `${file}|${line}|${method}` -> finding
  const globalGuards = new Map(); // repo -> [{framework, name, file}]
  const guardDefs = new Map();    // name -> [{ file, wrapper }]
  for (const f of scan.files) for (const x of findings(f.path)) {
    if (x.k === 'route') routeFinding.set(`${f.path}|${x.line}|${x.method}`, x);
    // app-wide checks count only from the app itself, not from scripts or tests that spin up their own
    if (x.k === 'global-guard' && !TEST_FILE.test(f.path) && !/(^|\/)(scripts?|tools|bin|examples?)\//.test(f.path) && !(fileByPath.has(f.path) && kinds(fileByPath.get(f.path).n).some((k) => NOT_USED_KINDS.has(k)))) { const k = f.repo ?? ''; if (!globalGuards.has(k)) globalGuards.set(k, []); globalGuards.get(k).push({ ...x, file: f.path }); }
    if (x.k === 'guard-def' && !TEST_FILE.test(f.path)) { if (!guardDefs.has(x.name)) guardDefs.set(x.name, []); guardDefs.get(x.name).push({ file: f.path, wrapper: !!x.wrapper }); }
  }
  const aliasGuards = pyAliasGuards(scan.files.filter((f) => !TEST_FILE.test(f.path)), findings);
  for (const [repo, aliases] of aliasGuards) for (const [name, file] of aliases) {
    if (!guardDefs.has(name)) guardDefs.set(name, []);
    guardDefs.get(name).push({ file, alias: true, repo });
  }
  // a sign-in check applied where the route's router is mounted: app.use('/admin', requireStaff, adminRouter),
  // or app.include_router(admin.router, dependencies=[Depends(require_admin)]) (a database session isn't one)
  const mountGuard = new Map((scan.routes || []).filter((r) => r.mountMw?.some(isGuardDep)).map((r) => [`${r.file}|${r.line}|${r.method}`, r.mountMw.find(isGuardDep)]));
  const perRepo = new Map(); // repo -> { guarded, open: [], guardCounts }
  graph.routes.forEach((r, i) => {
    const fnd = routeFinding.get(`${r.f}|${r.l}|${r.m}`);
    if (!fnd) return; // framework we don't analyse: say nothing
    const gf = fileByPath.get(r.f);
    if (!gf || kinds(gf.n).some((k) => NOT_USED_KINDS.has(k)) || TEST_FILE.test(r.f)) return;
    const repo = gf.r ?? '';
    if (!perRepo.has(repo)) perRepo.set(repo, { guarded: 0, total: 0, open: [], misplaced: [], guardCounts: new Map(), fileGuards: new Map(), guardedIn: new Map() });
    const pr = perRepo.get(repo);
    pr.total++;
    const global = (globalGuards.get(repo) || []).find((g) => g.framework === 'flask' || g.framework === 'express' || (g.framework === 'next' && fnd.fn === r.m));
    // an unrecognised decorator that turns out to be an auth wrapper defined elsewhere in the project
    const viaWrapper = !fnd.via && fnd.decos?.find((d) => guardDefs.get(d)?.some((g) => (g.file.split('/')[0] === r.f.split('/')[0])));
    const mounted = !fnd.via && mountGuard.get(`${r.f}|${r.l}|${r.m}`);
    // a parameter typed with a dependency alias that checks the caller: `user: AdminUser`
    const viaAlias = !fnd.via && fnd.types?.find((t) => aliasGuards.get(repo)?.has(t));
    if (fnd.via || global || viaWrapper || mounted || viaAlias) {
      pr.guarded++; pr.guardedIn.set(r.f, (pr.guardedIn.get(r.f) || 0) + 1);
      const name = fnd.guard || viaWrapper || mounted || viaAlias;
      if (name) {
        pr.guardCounts.set(name, (pr.guardCounts.get(name) || 0) + 1);
        if (!pr.fileGuards.has(r.f)) pr.fileGuards.set(r.f, new Map());
        pr.fileGuards.get(r.f).set(name, (pr.fileGuards.get(r.f).get(name) || 0) + 1);
      }
      return;
    }
    if (r.m === 'OPTIONS' || r.m === 'HEAD') return;
    // webhook receivers: by URL, or a webhook-ish handler in a webhook file (not that file's admin endpoints)
    const webhook = (WEBHOOK_PATH.test(r.p) && !WEBHOOK_ADMIN.test(r.p)) || (/webhook|hooks?\//i.test(r.f) && /webhook|hook|notify|event|ingress|pubsub|callback|receive|inbound/i.test(r.h || '') && !/create|list|manage|register|delete|test|setup|sync/i.test((r.h || '') + r.p));
    if (webhook && fnd.signed) return;
    // a Stripe webhook that doesn't check Stripe's signature has its own, more specific issue
    if (stripeFiles.has(r.f) && (webhook || /stripe|payment|hook/i.test(r.p) || graph.routes.filter((x) => x.f === r.f && x.m !== 'GET').length === 1)) return;
    if (!webhook && PUBLIC_PATH.test(r.p.replace(/<[^>]*>|\{[^}]*\}|:\w+|\[[^\]]*\]/g, 'x'))) return;
    if (r.p === '/' && r.m === 'GET') return;
    const entry = { i, r, fnd, write: !['GET', 'ANY'].includes(r.m), webhook };
    if (fnd.misplaced) pr.misplaced.push(entry); else pr.open.push(entry);
  });
  for (const [repo, pr] of perRepo) {
    const top = (m) => m && [...m.entries()].sort((a, b) => b[1] - a[1])[0]?.[0];
    // prefer what this file already uses, then the project's most common real (non-wrapper) check
    const guardHint = (file, lang) => {
      const local = top(pr.fileGuards.get(file));
      const name = local || top(new Map([...pr.guardCounts].filter(([n]) => !guardDefs.get(n)?.every((g) => g.wrapper))));
      if (!name) return `le contrôle de connexion existant du projet (trouve comment les autres points d’accès protégés vérifient l’utilisateur ; `
        + `s’il n’y en a pas, demande-moi avant d’en ajouter un)`;
      const defs = guardDefs.get(name) || [];
      const where = defs.find((g) => g.file === file) ? 'défini dans ce fichier' : defs.length ? `défini dans ${defs[0].file}` : '';
      const how = defs.some((g) => g.alias) ? `un paramètre typé ${name}` : `${lang === 'python' ? '@' : ''}${name}`;
      return `le même contrôle que ${local ? 'les autres points d’accès de ce fichier' : 'les points d’accès protégés'} utilisent déjà `
        + `(${how}${where ? ', ' + where : ''})`;
    };
    const routeLine = (e) => `- ${e.r.m} ${e.r.p} — ${e.r.f}:${e.r.l}${e.fnd.fn && !/^[A-Z]+$/.test(e.fnd.fn) ? ` (${e.fnd.fn})` : ''}`;
    if (pr.misplaced.length) {
      const list = pr.misplaced, un = list.length === 1;
      issues.push({
        id: 'misplaced-guard:' + repo, kind: 'unprotected-endpoint', severity: 'high',
        title: 'Une vérification de connexion est au mauvais endroit : elle ne sert à rien',
        detail: `Sur ${plural(list.length, 'point d’accès', 'points d’accès')}, la vérification de connexion (@${list[0].fnd.misplaced}) est écrite `
          + `au-dessus de la ligne de la route `
          + `au lieu d’en dessous. Flask ne voit que ce qui est en dessous : ${un ? 'il est ouvert' : 'ils sont ouverts'} à n’importe qui `
          + `alors ${un ? 'qu’il paraît protégé' : 'qu’ils paraissent protégés'}.`,
        items: list.slice(0, 24).map((e) => 'r:' + e.i),
        notes: Object.fromEntries(list.slice(0, 24).map((e) => ['r:' + e.i, `@${e.fnd.misplaced} est au-dessus de la ligne de la route : il est ignoré`])),
        locations: list.map((e) => ({ file: e.r.f, line: e.r.l })),
        fix: [`Correctif de sécurité : ces points d’accès ont leur décorateur d’authentification au-dessus du décorateur de route, si bien que le `
          + `framework enregistre la fonction non protégée :`, ...list.map(routeLine), ``,
          `Déplace chaque décorateur d’authentification juste sous la ligne @…route(...) (le décorateur de route d’abord, puis celui `
            + `d’authentification, puis def). Ne change rien d’autre, puis lance les tests qui couvrent ces points d’accès.`].join('\n'),
      });
    }
    if (!pr.open.length) continue;
    // Nothing in this repo checks the caller: probably protected elsewhere (gateway, private network) or not at all.
    if (pr.guarded === 0) {
      const list = pr.open.sort((a, b) => b.write - a.write);
      issues.push({
        id: 'no-auth:' + repo, kind: 'unprotected-endpoint', severity: 'medium',
        title: `Aucun des points d’accès ${repo ? `de ${repo}` : 'de votre app'} ne vérifie qui appelle`,
        detail: `${plural(list.length, 'point d’accès', 'points d’accès')} ${list.length === 1 ? 'répond' : 'répondent'} à quiconque connaît `
          + `l’adresse, sans aucune vérification de connexion dans le code. `
          + `Ce n’est acceptable que si ce serveur est privé (par exemple derrière un réseau d’entreprise ou une passerelle qui vérifie les connexions) ; `
          + `sinon n’importe qui pourrait lire ou modifier ses données.`,
        items: list.slice(0, 24).map((e) => 'r:' + e.i),
        notes: Object.fromEntries(list.slice(0, 24).map((e) => ['r:' + e.i, e.write ? 'Modifie des données, sans vérification de connexion' : 'Sans vérification de connexion'])),
        locations: list.map((e) => ({ file: e.r.f, line: e.r.l })),
        fix: [`Revue du contrôle d’accès${repo ? ` dans ${repo}` : ''}. Aucun de ces points d’accès ne vérifie l’appelant dans le code `
          + `:`, ...list.slice(0, 40).map(routeLine),
          list.length > 40 ? `- …et ${list.length - 40} autres` : null, ``,
          `Dis-moi d’abord en langage simple si ce serveur est joignable depuis internet et si quelque chose devant lui (passerelle, règles réseau) `
            + `vérifie les connexions. `
          + `S’il est public, propose le moyen le plus petit et le plus sûr d’exiger une connexion pour les points d’accès qui modifient des données `
            + `(POST/PUT/PATCH/DELETE) d’abord, `
          + `montre-moi le plan, et attends mon accord avant de modifier le code.`].filter((x) => x !== null).join('\n'),
      });
      continue;
    }
    // One issue per route file
    const byFile = new Map();
    for (const e of pr.open) { if (!byFile.has(e.r.f)) byFile.set(e.r.f, []); byFile.get(e.r.f).push(e); }
    for (const [file, list] of byFile) {
      list.sort((a, b) => b.write - a.write || a.r.l - b.r.l);
      const writes = list.filter((e) => e.write && !e.webhook), hooks = list.filter((e) => e.webhook), reads = list.filter((e) => !e.write && !e.webhook);
      // many providers can't sign webhooks at all, so an unsigned one alone stays low
      const sev = writes.length ? 'high' : reads.length > 2 ? 'medium' : 'low';
      const lang = scanByPath.get(file)?.lang;
      const fileGuarded = pr.guardedIn.get(file) || 0;
      const sv = (n, one, many) => `${n} ${n === 1 ? one : many}`;
      const parts = [];
      if (writes.length) parts.push(sv(writes.length, 'point d’accès qui modifie des données (créer, mettre à jour ou supprimer)', 'points d’accès qui modifient des données (créer, mettre à jour ou supprimer)'));
      if (reads.length) parts.push(sv(reads.length, 'point d’accès qui renvoie des données', 'points d’accès qui renvoient des données'));
      const nOpen = writes.length + reads.length;
      const hookText = hooks.length ? `${sv(hooks.length, 'webhook (un message automatique d’un autre service) est accepté', 'webhooks (des messages automatiques d’un autre service) sont acceptés')} `
        + `sans vérifier ${hooks.length === 1 ? 'qu’il vient bien' : 'qu’ils viennent bien'} de ce service : n’importe qui pourrait en envoyer de faux. `
        + `Certains fournisseurs ne peuvent pas signer leurs messages ; si c’est le cas, c’est normal.` : '';
      issues.push({
        id: 'open-endpoints:' + file, kind: 'unprotected-endpoint', severity: sev,
        title: writes.length ? `N’importe qui pourrait modifier des données via ${nameOf(file)}` : hooks.length ? `N’importe qui pourrait envoyer de `
          + `faux événements à ${nameOf(file)}` : `N’importe qui pourrait lire des données depuis ${nameOf(file)}`,
        detail: [
          parts.length ? `${file.split('/').pop()} a ${parts.join(' et ')} sans vérification de connexion : quiconque trouve l’adresse peut `
            + `${nOpen === 1 ? 'l’utiliser' : 'les utiliser'}`
            + `${fileGuarded > 0 ? ` (${sv(fileGuarded, 'autre point d’accès du même fichier est protégé', 'autres points d’accès du même fichier sont protégés')})` : ''}. `
            + `${nOpen === 1 ? 'S’il est fait pour être public, c’est acceptable ; sinon il lui faut une vérification de connexion.' : 'Si certains sont faits pour être publics, c’est acceptable ; sinon ils ont besoin d’une vérification de connexion.'}` : '',
          parts.length && hooks.length ? `Il accepte aussi ${sv(hooks.length, 'webhook', 'webhooks')} sans vérifier qui `
            + `${hooks.length === 1 ? 'l’a envoyé' : 'les a envoyés'}.` : hookText,
        ].filter(Boolean).join(' '),
        items: list.slice(0, 24).map((e) => 'r:' + e.i),
        notes: Object.fromEntries(list.slice(0, 24).map((e) => ['r:' + e.i, e.webhook ? 'Webhook sans vérification de signature visible' : e.write ? 'Modifie des données, sans vérification de connexion' : 'Renvoie des données, sans vérification de connexion'])),
        locations: list.map((e) => ({ file: e.r.f, line: e.r.l })),
        fix: [
          `Correctif de sécurité dans ${file} : ces points d’accès ne vérifient pas qui appelle :`,
          ...list.map((e) => routeLine(e) + (e.webhook ? ' [webhook]' : '')),
          ``,
          `Pour chaque point d’accès qui n’est pas fait pour être public, ajoute ${guardHint(file, lang)}.`,
          hooks.length ? `Pour les webhooks, vérifie la signature du fournisseur (avec son secret de signature pris dans une variable `
            + `d’environnement) avant de faire quoi que ce soit, et rejette les requêtes qui échouent.` : null,
          `Si un point d’accès est volontairement public (par exemple une page publique ou un contrôle de santé), laisse-le et dis-moi pourquoi. `
          + `Ne change rien d’autre ; ensuite liste exactement quels points d’accès tu as protégés et lance les tests associés.`,
        ].filter((x) => x !== null).join('\n'),
      });
    }
  }

  // ---------- unused files ----------
  const incoming = new Set();
  for (const l of graph.links) if (l.a !== l.b && l.b.startsWith('f:')) incoming.add(l.b.slice(2));
  const entry = new Set(graph.project?.entrypoints || []);
  const routeFiles = new Set(graph.routes.map((r) => r.f));
  for (const fl of graph.flows || []) for (const s of fl.steps || []) if (s.ref?.startsWith('f:')) entry.add(s.ref.slice(2));
  const candidates = graph.files.filter((f) => {
    if (incoming.has(f.p) || entry.has(f.p) || routeFiles.has(f.p) || !USED_LANGS.has(f.l)) return false;
    if (TEST_FILE.test(f.p) || THIRD_PARTY.test(f.p) || SPECIAL_FILE.test(f.p) || /(^|\/)app\/.*\/(page|layout|route|loading|error|template|default)\.[jt]sx?$/.test(f.p)) return false;
    if (/(^|\/)src\/routes\//.test(f.p) && /\+|\$|\[/.test(f.p.split('/').pop())) return false;
    if (kinds(f.n).some((k) => NOT_USED_KINDS.has(k))) return false;
    if (findings(f.p).some((x) => x.k === 'runnable' || x.k === 'route')) return false;
    return true;
  });
  // Safety net for dynamic loading: skip a file whose name appears in any other source file.
  if (candidates.length) {
    const want = new Map(candidates.map((f) => [stemOf(f.p), f.p]));
    const mentioned = new Set();
    for (const f of scan.files) {
      if (!['code', 'config', 'docs'].includes(f.category) || f.tooLarge) continue;
      let src;
      try { src = fs.readFileSync(path.join(root, f.path), 'utf8'); } catch { continue; }
      for (const tok of new Set(src.match(/[\w$-]+/g) || [])) { const p = want.get(tok); if (p && p !== f.path) mentioned.add(p); }
    }
    const unused = candidates.filter((f) => !mentioned.has(f.p));
    // A module where most files look unused is more likely loaded in a way we can't see; stay quiet.
    const byNode = new Map();
    for (const f of unused) { if (!byNode.has(f.n)) byNode.set(f.n, []); byNode.get(f.n).push(f); }
    const groups = [...byNode.entries()].filter(([n, list]) => { const total = graph.files.filter((f) => f.n === n).length; return n === 'unassigned' || list.length <= 3 || list.length / total <= 0.6; }).sort((a, b) => b[1].length - a[1].length);
    const MAX = 5;
    const merged = groups.length > MAX ? [...groups.slice(0, MAX - 1), ['', groups.slice(MAX - 1).flatMap(([, l]) => l)]] : groups;
    for (const [nid, list] of merged) {
      list.sort((a, b) => b.loc - a.loc);
      const where = nid ? label(nid) : 'd’autres zones';
      const lines = list.reduce((s, f) => s + f.loc, 0);
      issues.push({
        id: 'unused:' + (nid || 'other'), kind: 'unused-file', severity: 'low',
        title: list.length === 1 ? `Un fichier dans ${where} semble inutilisé` : `${list.length} fichiers dans ${where} semblent inutilisés`,
        detail: `Rien dans l’app n’importe ni n’appelle ${list.length === 1 ? 'ce fichier' : 'ces fichiers'} (${nl(lines)}). `
          + `Le code laissé de côté perturbe les assistants IA, qui peuvent modifier ou copier la mauvaise version. `
          + `Vérifiez avant de supprimer : certains fichiers sont chargés d’une façon que la carte ne voit pas.`,
        items: list.slice(0, 24).map((f) => 'f:' + f.p),
        notes: Object.fromEntries(list.slice(0, 24).map((f) => ['f:' + f.p, `Rien n’utilise ce fichier (${nl(f.loc)})`])),
        locations: list.map((f) => ({ file: f.p, line: 1 })),
        fix: [`Contrôle de nettoyage : ces fichiers semblent inutilisés (rien ne les importe ni ne les appelle) :`, ...list.slice(0, 40).map((f) => `- ${f.p}`),
          list.length > 40 ? `- …et ${list.length - 40} autres` : null, ``,
          `Pour chaque fichier, cherche dans tout le code (y compris configs, scripts, templates HTML et imports dynamiques) pour confirmer que rien `
            + `ne l’utilise. `
          + `Dis-moi ensuite lesquels peuvent être supprimés sans risque et lesquels sont en fait utilisés, avec une ligne de preuve chacun. Ne `
            + `supprime rien avant mon accord.`].filter((x) => x !== null).join('\n'),
      });
    }
  }

  // ---------- very large files ----------
  const big = graph.files.filter((f) => f.loc > 1000 && USED_LANGS.has(f.l) && !TEST_FILE.test(f.p) && !THIRD_PARTY.test(f.p) && !/(^|\/)(migrations|alembic|versions|fixtures?|seeds?|generated|__generated__)\//i.test(f.p) && !/\.d\.ts$/.test(f.p)).sort((a, b) => b.loc - a.loc);
  if (big.length) {
    const huge = big.filter((f) => f.loc >= 2000);
    issues.push({
      id: 'large-files', kind: 'large-file', severity: huge.length ? 'medium' : 'low',
      title: big.length === 1 ? 'Un fichier est très volumineux' : `${big.length} fichiers sont très volumineux`,
      detail: `${big.length === 1 ? 'Ce fichier compte' : 'Ces fichiers comptent chacun'} plus de 1 000 lignes${huge.length ? ` (le plus gros en `
        + `compte ${big[0].loc.toLocaleString('fr-FR')})` : ''}. `
        + `Les assistants IA lisent et modifient moins fiablement les gros fichiers : ils perdent le fil de ce qui est où et peuvent casser une `
          + `partie en en corrigeant une autre. `
        + `Les découper en fichiers plus petits, un par rôle, rend les futures modifications plus sûres.`,
      items: big.slice(0, 24).map((f) => 'f:' + f.p),
      notes: Object.fromEntries(big.slice(0, 24).map((f) => ['f:' + f.p, `${nl(f.loc)}`
        + `${f.tooLarge ? ' : trop gros pour être lu par VibeFlow, donc ce à quoi il se connecte et ses secrets éventuels n’ont pas été contrôlés' : ''}`])),
      locations: big.map((f) => ({ file: f.p, line: 1 })),
      fix: [`Plan de refactorisation : ces fichiers sont très volumineux :`, ...big.slice(0, 15).map((f) => `- ${f.p} `
        + `(${nl(f.loc)})`), ``,
        `Commence par ${big[0].p}. Lis-le et propose comment le découper en fichiers plus petits, chacun avec un rôle clair (par exemple par `
          + `fonctionnalité ou par type de travail), `
        + `en gardant chaque nom de fonction publique et chaque comportement identiques. Montre-moi d’abord le plan. `
        + `Après mon accord, déplace le code par petites étapes, mets à jour les imports et lance les tests après chaque étape. Ne change pas le `
          + `comportement.`].join('\n'),
    });
  }

  // ---------- frontend hard-coded to localhost ----------
  const local = [];
  for (const f of graph.files) if (isFrontend(f.p)) for (const x of findings(f.p)) if (x.k === 'localhost') local.push({ file: f.p, line: x.line });
  if (local.length) {
    const filesL = [...new Set(local.map((x) => x.file))];
    issues.push({
      id: 'localhost-url', kind: 'hardcoded-url', severity: 'low',
      title: 'L’app pointe vers l’adresse de votre propre ordinateur',
      detail: `${filesL.length === 1 ? 'Un fichier frontend appelle' : `${filesL.length} fichiers frontend appellent`} une adresse « localhost » fixe. `
        + `Cela ne fonctionne que sur votre machine ; une fois l’app en ligne, ces appels échoueront pour tout le monde.`,
      items: filesL.slice(0, 24).map((p) => 'f:' + p),
      notes: Object.fromEntries(filesL.slice(0, 24).map((p) => ['f:' + p, `adresse localhost, ligne `
        + `${local.filter((x) => x.file === p).map((x) => x.line).join(', ')}`])),
      locations: local,
      fix: [`Ces lignes du frontend utilisent une URL localhost écrite en dur :`, ...local.map((x) => `- ${x.file}:${x.line}`), ``,
        `Remplace chacune par le réglage d’URL de base de l’API déjà présent dans le projet (ou ajoutes-en un, lu depuis une variable d’environnement publique `
        + `comme NEXT_PUBLIC_API_URL / VITE_API_URL, avec la valeur localhost seulement dans .env.development). Ne change rien d’autre.`].join('\n'),
    });
  }

  const KIND_ORDER = ['secret', 'public-env-secret', 'database-rules', 'stripe-webhook', 'env-file', 'unprotected-endpoint', 'cors', 'large-file', 'hardcoded-url', 'unused-file'];
  issues.sort((a, b) => SEV_ORDER[a.severity] - SEV_ORDER[b.severity] || KIND_ORDER.indexOf(a.kind) - KIND_ORDER.indexOf(b.kind) || (b.locations?.length || 0) - (a.locations?.length || 0));
  const kept = issues.slice(0, 40);
  const summary = { high: 0, medium: 0, low: 0 };
  for (const i of kept) summary[i.severity]++;
  // the services this project really uses: the panel's introduction names only these
  const services = [];
  if (usesSupabase) services.push('Supabase');
  if (scan.files.some((f) => /(^|\/)(firebase\.json|\.firebaserc|firestore\.rules|storage\.rules|database\.rules\.json)$/.test(f.path) || findings(f.path).some((x) => x.k === 'uses-firebase'))) services.push('Firebase');
  if (issues.some((i) => i.kind === 'stripe-webhook') || scan.files.some((f) => findings(f.path).some((x) => x.k === 'uses-stripe'))) services.push('Stripe');
  return { summary, issues: kept, services };
}

/** Test mode, in Firestore/Storage rules (request.time < timestamp.date(Y, M, D)) or Realtime Database rules (now < ms). */
const testModeEnd = (cond) => {
  const d = /^request\.time\s*<\s*timestamp\.date\(\s*(\d{4})\s*,\s*(\d{1,2})\s*,\s*(\d{1,2})\s*\)$/.exec(cond);
  if (d) return new Date(Date.UTC(+d[1], +d[2] - 1, +d[3]));
  const ms = /^now\s*<\s*(\d{12,14})$/.exec(cond);
  return ms ? new Date(+ms[1]) : null;
};

/** Firestore / Storage rules that let anyone in: `allow …: if true`, `allow …;` (no condition) and test mode. */
function firebaseRules(src, now) {
  const s = src.replace(/\/\/[^\n]*/g, (m) => ' '.repeat(m.length));
  const at = lineIndex(s);
  const matches = [...s.matchAll(/\bmatch\s+(\/\S*)\s*\{/g)].map((m) => ({ i: m.index, path: m[1] }));
  const out = [];
  for (const m of s.matchAll(/\ballow\s+([a-z][a-z,\s]*?)\s*(?::\s*if\s+([^;]+?))?\s*;/g)) {
    const ops = m[1].split(/[\s,]+/).filter(Boolean);
    const cond = (m[2] || 'true').trim().replace(/\s+/g, ' ');
    const end = cond === 'true' ? null : testModeEnd(cond);
    if (cond !== 'true' && !end) continue;
    const where = matches.filter((x) => x.i < m.index).pop()?.path || '/';
    const writeOps = ops.filter((o) => /^(write|create|update|delete)$/.test(o));
    out.push({
      line: at(m.index), text: `allow ${ops.join(', ')}${m[2] ? ` : si ${cond}` : ' (sans condition)'} sur ${where}`,
      read: ops.some((o) => /^(read|get|list)$/.test(o)), write: writeOps.length > 0, createOnly: writeOps.length > 0 && writeOps.every((o) => o === 'create'),
      open: !end ? 'always' : end > now ? 'until' : 'expired', until: end, where,
      wide: /=\*\*\}/.test(where) || /\/documents$/.test(where) || where === '/',
    });
  }
  return out;
}

/** Realtime Database rules (database.rules.json) with ".read" / ".write" set to true or test mode. */
function firebaseRtdbRules(src, now) {
  const s = src.replace(/(^|[^:"])\/\/[^\n]*/g, (m, pre) => pre + ' '.repeat(m.length - pre.length));
  const at = lineIndex(s);
  const out = [];
  for (const m of s.matchAll(/"\.(read|write)"\s*:\s*(true\b|"([^"]*)")/g)) {
    const cond = m[2] === 'true' ? 'true' : (m[3] || '').trim();
    const end = cond === 'true' ? null : testModeEnd(cond);
    if (cond !== 'true' && !end) continue;
    // how deep it sits: { "rules": { ".read": … } } is the whole database
    let depth = 0;
    for (let i = 0; i < m.index; i++) { if (s[i] === '{') depth++; else if (s[i] === '}') depth--; }
    const keys = [...s.slice(0, m.index).matchAll(/"([^".][^"]*)"\s*:\s*\{/g)].map((k) => k[1]);
    const where = depth <= 2 ? 'toute la base de données' : '/' + keys.slice(-(depth - 2)).join('/');
    out.push({
      line: at(m.index), text: `"${m[1] === 'read' ? '.read' : '.write'}" : ${m[2]} pour ${where}`,
      read: m[1] === 'read', write: m[1] === 'write', createOnly: false,
      open: !end ? 'always' : end > now ? 'until' : 'expired', until: end, where, wide: depth <= 2, root: depth <= 2,
    });
  }
  return out;
}

function readHead(file, max) {
  const fd = fs.openSync(file, 'r');
  try { const buf = Buffer.alloc(max); const n = fs.readSync(fd, buf, 0, max, 0); return buf.subarray(0, n).toString('utf8'); } finally { fs.closeSync(fd); }
}
function stemOf(p) {
  const base = p.split('/').pop().replace(/\.[^.]+$/, '');
  return base === 'index' ? p.split('/').slice(-2, -1)[0] : base;
}
