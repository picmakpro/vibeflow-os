// Shared helpers: paths, globs, file classification, git, and codebase discovery.
// vibeflow:allow-large-file (code vendorisé, VENDORED.txt ; 75-06 : la règle de rattachement d'un fichier à un nœud, extraite de build.mjs)
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { gitSortant } from './vf-git-sortant.mjs'; // vibeflow AUDC-A-02
import { automateDe, MAX_MOTIF } from './vf-glob.mjs'; // vibeflow SOCL-26

export const toPosix = (p) => p.replace(/\\/g, '/');
export const rel = (from, to) => toPosix(path.relative(from, to)) || '.';

// ---------- globs ----------

const GLOB_CHARS = /[*?{[]/;

// Source de regex (sans ancres) d'un motif : le fragment que lit l'automate de vf-glob.mjs.
export function globSource(glob) {
  const g = toPosix(glob).replace(/^\.\//, '').replace(/\/$/, '');
  let re = '';
  let braces = 0;
  for (let i = 0; i < g.length; ) {
    const c = g[i];
    if (c === '*') {
      if (g[i + 1] === '*') {
        const atStart = i === 0 || g[i - 1] === '/';
        const atEnd = i + 2 === g.length || g[i + 2] === '/';
        if (atStart && atEnd) {
          if (i + 2 === g.length) { re += '.*'; i += 2; }
          else { re += '(?:.*/)?'; i += 3; }
          continue;
        }
        re += '.*'; i += 2; continue;
      }
      re += '[^/]*'; i++; continue;
    }
    if (c === '?') { re += '[^/]'; i++; continue; }
    if (c === '{') { braces++; re += '(?:'; i++; continue; }
    if (c === '}' && braces) { braces--; re += ')'; i++; continue; }
    if (c === ',' && braces) { re += '|'; i++; continue; }
    // a whole segment like [id], [...slug] or [[...slug]] is a folder name (Next.js, SvelteKit), not a character class
    if (c === '[' && (i === 0 || g[i - 1] === '/')) {
      const end = g.indexOf('/', i) < 0 ? g.length : g.indexOf('/', i);
      const seg = g.slice(i, end);
      if (/^\[\[?(\.\.\.)?[A-Za-z_$][\w$-]*\]\]?$/.test(seg)) { re += seg.replace(/[.[\]$\\]/g, '\\$&'); i = end; continue; }
    }
    if (c === '[') {
      const j = g.indexOf(']', i + 1);
      if (j > i) { re += '[' + g.slice(i + 1, j).replace(/^!/, '^').replace(/\\/g, '\\\\') + ']'; i = j + 1; continue; }
    }
    re += c.replace(/[.+^$()|\\\]]/g, '\\$&');
    i++;
  }
  return re;
}

/** Compile a glob. A pattern with no wildcards also matches everything under it as a directory. */
export function compileGlob(glob) {
  const g = toPosix(glob).replace(/^\.\//, '').replace(/\/$/, '');
  const premier = g.search(GLOB_CHARS); // vibeflow SOCL-26 : le préfixe littéral se lit sans découper le motif entier
  if (!GLOB_CHARS.test(g)) {
    return { glob, specificity: g.length, test: (p) => p === g || p.startsWith(g + '/') };
  }
  if (g.length > MAX_MOTIF) { // vibeflow SOCL-26 : motif au-delà du plafond, jamais traduit ; un avis d'une ligne, ne correspond à rien
    console.error(`cockpit : motif de plus de ${MAX_MOTIF} caractères ignoré (${JSON.stringify(g.slice(0, 40))}…)`);
    return { glob, specificity: premier, test: () => false };
  }
  // A glob that names directories (src/components/{a,b}) also matches everything beneath them.
  return { glob, specificity: premier, test: automateDe(globSource(g), globSource(g + '/**')) };
}

// ---------- rattachement d'un fichier à un nœud (vibeflow 75-06) : la règle de build.mjs, UNE fois, appelée par le moteur ET par l'annotateur des cartes prévues ----------
const strs = (v) => Array.isArray(v) && v.every((x) => typeof x === 'string');
/** Les motifs de chaque nœud, avec sa profondeur (chaîne de `parent`) ; le `exclude` d'un nœud vaut aussi pour ses descendants. */
export function regleDeNoeuds(nodes) {
  const byId = new Map(nodes.filter((n) => n && typeof n.id === 'string' && n.id).map((n) => [n.id, n]));
  const chaine = (n, seen = new Set()) => (!n || seen.has(n.id) ? [] : (seen.add(n.id), [n, ...chaine(byId.get(n.parent), seen)])); // le nœud et ses ancêtres, sans boucle
  return nodes.filter((n) => n?.id && strs(n.paths ?? [])).map((n, order) => {
    const ch = chaine(n);
    return { id: n.id, order, depth: ch.length - 1, paths: (n.paths || []).map(compileGlob), exclude: ch.flatMap((x) => (strs(x.exclude) ? x.exclude : [])).map(compileGlob),
      hits: new Array((n.paths || []).length).fill(0) };
  });
}
/** Le nœud d'un chemin : profondeur d'abord, puis spécificité. { id ('unassigned' sans nœud), tie (id d'un nœud à égalité parfaite, ou null) }. */
export function rattacher(matchers, chemin) {
  let best = null, bk = null, tie = null;
  for (const m of matchers) {
    if (m.exclude.some((g) => g.test(chemin))) continue;
    let spec = -1;
    m.paths.forEach((g, i) => { if (g.test(chemin)) { m.hits[i]++; spec = Math.max(spec, g.specificity); } });
    if (spec < 0) continue;
    if (!best || m.depth > bk[0] || (m.depth === bk[0] && spec > bk[1])) { best = m; bk = [m.depth, spec]; tie = null; }
    else if (m.depth === bk[0] && spec === bk[1]) tie = m.id;
  }
  return { id: best ? best.id : 'unassigned', tie };
}

// ---------- file classification ----------

const LANG_BY_EXT = {
  '.ts': 'typescript', '.tsx': 'typescript', '.mts': 'typescript', '.cts': 'typescript',
  '.js': 'javascript', '.jsx': 'javascript', '.mjs': 'javascript', '.cjs': 'javascript',
  '.vue': 'vue', '.svelte': 'svelte', '.astro': 'astro',
  '.py': 'python', '.pyi': 'python',
  '.go': 'go', '.rs': 'rust', '.java': 'java', '.kt': 'kotlin', '.kts': 'kotlin', '.scala': 'scala',
  '.cs': 'csharp', '.fs': 'fsharp', '.rb': 'ruby', '.php': 'php', '.swift': 'swift', '.dart': 'dart',
  '.c': 'c', '.h': 'c', '.cc': 'cpp', '.cpp': 'cpp', '.cxx': 'cpp', '.hpp': 'cpp', '.hh': 'cpp', '.m': 'objc', '.mm': 'objc',
  '.ex': 'elixir', '.exs': 'elixir', '.erl': 'erlang', '.clj': 'clojure', '.lua': 'lua', '.r': 'r', '.jl': 'julia',
  '.zig': 'zig', '.elm': 'elm', '.hs': 'haskell', '.ml': 'ocaml', '.groovy': 'groovy',
  '.sh': 'shell', '.bash': 'shell', '.zsh': 'shell', '.ps1': 'powershell', '.psm1': 'powershell',
  '.sql': 'sql', '.tf': 'terraform', '.proto': 'protobuf', '.graphql': 'graphql', '.gql': 'graphql',
  '.css': 'css', '.scss': 'css', '.sass': 'css', '.less': 'css',
  '.html': 'html', '.htm': 'html', '.ejs': 'html', '.hbs': 'html', '.jinja': 'html', '.j2': 'html', '.njk': 'html',
};
const CONFIG_EXT = new Set(['.json', '.yaml', '.yml', '.toml', '.ini', '.cfg', '.conf', '.xml', '.gradle', '.properties', '.env']);
const CONFIG_NAMES = /^(dockerfile.*|makefile|procfile|justfile|\.env\..*|\.?[\w-]*rc|gemfile|rakefile|cargo\.toml|go\.mod|pyproject\.toml|setup\.cfg|requirements.*\.txt)$/i;
const JSON_CONFIG = /^(package|tsconfig.*|jsconfig|composer|manifest|app|components|turbo|nx|lerna|angular|firebase|vercel|now|renovate|tslint|.?eslintrc|.?babelrc|.?prettierrc|.*.config|.*rc|settings|launch|tasks|deno|biome|project|workspace|devcontainer|cdk|serverless|appsettings.*|openapi|swagger).json$/i;
const DOC_EXT = new Set(['.md', '.mdx', '.rst', '.adoc', '.txt']);
const DATA_EXT = new Set(['.csv', '.tsv', '.jsonl', '.ndjson', '.parquet', '.sqlite', '.db', '.xlsx', '.xls', '.avro']);
const ASSET_EXT = new Set(['.png', '.jpg', '.jpeg', '.gif', '.svg', '.ico', '.webp', '.avif', '.bmp', '.woff', '.woff2', '.ttf', '.otf', '.eot',
  '.mp3', '.mp4', '.wav', '.webm', '.mov', '.pdf', '.zip', '.gz', '.tar', '.tgz', '.7z', '.jar', '.wasm', '.exe', '.dll', '.so', '.dylib', '.bin']);
const LOCK_NAMES = /^(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|bun\.lockb|poetry\.lock|pipfile\.lock|cargo\.lock|go\.sum|composer\.lock|gemfile\.lock|.*\.lock)$/i;
const GENERATED = /(\.min\.(js|css)$|\.map$|\.tsbuildinfo$|\.pyc$|\.pyo$|\.class$|\.o$|(^|\/)next-env\.d\.ts$)/i;

/** Directories never worth scanning, even if a repo tracks them. */
export const HARD_IGNORE_DIRS = new Set([
  'node_modules', '.git', '.pnpm-store', '.yarn', '__pycache__', '.venv', 'venv', 'site-packages',
  '.tox', '.mypy_cache', '.pytest_cache', '.ruff_cache', '.next', '.nuxt', '.svelte-kit', '.turbo',
  '.parcel-cache', '.gradle', '.idea',
]);

/** The folder the map lives in, at the codebase root. Maps made before the rename used show-code/. */
export const MAP_DIR = '.vibeflow/cockpit'; // vibeflow P10 : sortie du cockpit, deux niveaux sous la racine du lab
export const LEGACY_MAP_DIR = 'show-code';
/** True for a folder holding a map, so a project's own folder that happens to be called "floorplan" isn't taken for one. */
export const isMapDir = (d) => ['architecture.json', 'plan.json', 'graph.json', '.cache'].some((f) => fs.existsSync(path.join(d, f)));
/**
 * Keeps the map folder out of git: its own .gitignore ignores everything in it, itself included, so
 * nothing in the project's tracked files changes. Returns a warning when git already tracks files
 * there (ignoring doesn't untrack them), else null.
 */
export function keepOutOfGit(dir) {
  const gi = path.join(dir, '.gitignore');
  const want = '# Sortie générée par le cockpit VibeFlow : ignorée par git (ce fichier compris).\n*\n'; // vibeflow P10
  fs.mkdirSync(dir, { recursive: true });
  try { if (!fs.existsSync(gi) || fs.readFileSync(gi, 'utf8') !== want) fs.writeFileSync(gi, want); } catch {}
  const tracked = (git(dir, ['ls-files', '--', '.']) || '').split('\n').filter(Boolean);
  if (!tracked.length) return null;
  const rel = path.basename(dir);
  return `${tracked.length} file(s) in ${rel}/ were committed to git before; they stay tracked until you run: git rm -r --cached ${rel}  (this keeps the files on disk)`;
}

/** The map folder for a codebase root. Moves an old show-code/ map into place unless migrate is false. */
export function mapDir(root, { migrate = true } = {}) {
  const dir = path.join(root, MAP_DIR);
  const old = path.join(root, LEGACY_MAP_DIR);
  if (migrate && !fs.existsSync(dir) && isMapDir(old)) {
    fs.renameSync(old, dir);
    console.error(`(moved the existing map from ${LEGACY_MAP_DIR}/ to ${MAP_DIR}/)`);
  }
  if (fs.existsSync(dir) && !isMapDir(dir) && fs.readdirSync(dir).length) {
    console.error(`✗ ${MAP_DIR}/ already exists here and isn't a map (it's part of the project). Pass --out <folder> to put the map somewhere else.`);
    process.exit(1);
  }
  return dir;
}
/** Extra directories skipped when walking outside of git (where .gitignore can't help). */
export const WALK_IGNORE_DIRS = new Set([...HARD_IGNORE_DIRS, 'dist', 'build', 'out', 'target', 'coverage', '.cache', 'vendor', 'bin', 'obj', 'env', '.vscode', '.claude']);

export function classify(relPath, bytes) {
  const base = path.posix.basename(relPath).toLowerCase();
  const ext = path.posix.extname(base);
  if (GENERATED.test(relPath)) return { category: 'generated', lang: null };
  if (LOCK_NAMES.test(base)) return { category: 'lock', lang: null };
  if (ext === '.log' || base.endsWith('.log')) return { category: 'log', lang: null };
  if (ASSET_EXT.has(ext)) return { category: 'asset', lang: null };
  if (DATA_EXT.has(ext)) return { category: 'data', lang: null };
  if (LANG_BY_EXT[ext]) {
    if (ext === '.svg') return { category: 'asset', lang: null };
    return { category: 'code', lang: LANG_BY_EXT[ext] };
  }
  if (ext === '.json' && (bytes > 100_000 || !JSON_CONFIG.test(base))) return { category: 'data', lang: null };
  if (CONFIG_EXT.has(ext) || CONFIG_NAMES.test(base)) return { category: 'config', lang: ext ? ext.slice(1) : base };
  if (DOC_EXT.has(ext)) return { category: 'docs', lang: null };
  return { category: 'other', lang: null };
}

// ---------- git ----------

export function git(cwd, args) {
  // vibeflow P27 : git ne tourne que sous l'environnement durci posé par l'assemblage (envGit) ; sans ce marqueur, « hors dépôt » (P78-D-25)
  if (process.env.VF_COCKPIT_GIT_DURCI !== '1') return null;
  try {
    return execFileSync('git', ['-C', cwd, ...args], { encoding: 'utf8', maxBuffer: 256 * 1024 * 1024, stdio: ['ignore', 'pipe', 'ignore'] }).trimEnd();
  } catch {
    return null;
  }
}

export function gitInfo(dir) {
  const head = git(dir, ['rev-parse', 'HEAD']);
  const branch = git(dir, ['rev-parse', '--abbrev-ref', 'HEAD']);
  const remote = git(dir, ['config', '--get', 'remote.origin.url']);
  return { head, branch, remote: remote ? remote.replace(/\/\/[^@/]+@/, '//') : null };
}

/** Files git considers part of the repo: tracked + untracked-but-not-ignored. */
export function gitFiles(dir) {
  const out = git(dir, ['ls-files', '-co', '--exclude-standard', '-z']);
  if (out == null) return null;
  return [...new Set(out.split('\0').filter(Boolean))].map(toPosix);
}

/** If dir/.git is a file pointing into another repo's worktrees/, return that repo's working dir. */
function worktreeMain(dir) {
  const dotgit = path.join(dir, '.git');
  let st;
  try { st = fs.statSync(dotgit); } catch { return null; }
  if (!st.isFile()) return null;
  const m = /gitdir:\s*(.+)/.exec(fs.readFileSync(dotgit, 'utf8'));
  if (!m) return null;
  const gitdir = path.resolve(dir, m[1].trim());
  const idx = toPosix(gitdir).lastIndexOf('/.git/worktrees/');
  if (idx === -1) return null; // submodule or other indirection: treat as a normal repo
  return path.resolve(toPosix(gitdir).slice(0, idx));
}

// ---------- discovery ----------

/**
 * Walk the codebase root and find every git repo in it. Repos are not descended into
 * (git ls-files covers them). Loose files outside any repo are collected too.
 * Linked worktrees of a repo that is itself in the codebase are skipped as duplicates.
 */
export function discover(root, { includeWorktrees = false, maxLooseFiles = 5000 } = {}) {
  const repos = [];
  const loose = [];
  const skipped = [];

  // vibeflow AUDC-A-02 : un dépôt dont les métadonnées git ne sont pas celles du lab (dossier git ou commun hors du lab, lien symbolique, alternates, core.worktree étranger) n'est pas lu (lib/vf-git-sortant.mjs)
  const walk = (dir, depth) => {
    if (fs.existsSync(path.join(dir, '.git')) && !gitSortant(dir, root)) {
      repos.push({ abs: dir, path: rel(root, dir), worktreeOf: worktreeMain(dir) });
      return;
    }
    if (depth > 8) return;
    let entries;
    try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch { return; }
    if (entries.filter((e) => e.isFile()).length > 500) { skipped.push({ path: rel(root, dir), reason: 'over 500 files outside git (data dump?)' }); return; }
    for (const e of entries) {
      const abs = path.join(dir, e.name);
      if (e.isSymbolicLink()) continue;
      if (e.isDirectory()) {
        if (WALK_IGNORE_DIRS.has(e.name) || (e.name.startsWith('.') && e.name !== '.github')) {
          if (!['.git', 'node_modules', '__pycache__'].includes(e.name)) skipped.push({ path: rel(root, abs), reason: 'ignored directory' });
          continue;
        }
        walk(abs, depth + 1);
      } else if (e.isFile()) {
        if (loose.length < maxLooseFiles) loose.push(rel(root, abs));
      }
    }
  };
  walk(root, 0);

  // Drop worktree duplicates.
  const norm = (p) => toPosix(path.resolve(p)).toLowerCase();
  const primary = new Set(repos.filter((r) => !r.worktreeOf).map((r) => norm(r.abs)));
  const seenMains = new Set();
  const kept = [];
  for (const r of repos) {
    if (r.worktreeOf && !includeWorktrees && r.abs !== root) {
      const main = norm(r.worktreeOf);
      if (primary.has(main)) { skipped.push({ path: r.path, reason: `worktree of ${rel(root, r.worktreeOf)}` }); continue; }
      if (seenMains.has(main)) { skipped.push({ path: r.path, reason: `another worktree of ${r.worktreeOf}` }); continue; }
      seenMains.add(main);
    }
    kept.push(r);
  }
  return { repos: kept, loose, skipped };
}

// ---------- misc ----------

export function readJsonLoose(file) {
  try {
    const txt = fs.readFileSync(file, 'utf8')
      .replace(/^﻿/, '')
      .replace(/("(?:[^"\\]|\\.)*")|\/\*[\s\S]*?\*\/|\/\/[^\n]*/g, (m, str) => str ?? '')
      .replace(/,(\s*[}\]])/g, '$1');
    return JSON.parse(txt);
  } catch {
    return null;
  }
}

export function parseArgs(argv, defaults = {}) {
  const out = { _: [], ...defaults };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith('--')) {
      const [k, v] = a.slice(2).split('=');
      if (v !== undefined) out[k] = v;
      else if (argv[i + 1] && !argv[i + 1].startsWith('--')) out[k] = argv[++i];
      else out[k] = true;
    } else out._.push(a);
  }
  return out;
}

export const fmtNum = (n) => n >= 10000 ? (n / 1000).toFixed(0) + 'k' : n >= 1000 ? (n / 1000).toFixed(1) + 'k' : String(n);
