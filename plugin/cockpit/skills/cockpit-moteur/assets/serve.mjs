#!/usr/bin/env node
// vibeflow:allow-large-file (code vendorisé, VENDORED.txt)
// serve.mjs: serve the map of a lab locally and answer questions about the codebase through the Claude Code CLI or Codex.
// Needs only Node 18+ and a signed-in `claude` or `codex`. VibeFlow 79-06 : this file runs FROM THE MODULE (never from the lab's
// output folder, which holds data only); the output folder is given by --sortie=<dossier>, always the LAST argument.
//
// usage: node serve.mjs [--port 4378] [--engine claude|codex] [--model <model>] [--claude <path>] [--codex <path>]
//                       [--no-open] [--idle-exit <minutes>] [--terminal] --sortie=<lab>/.vibeflow/cockpit
//        node serve.mjs --stop --sortie=<lab>/.vibeflow/cockpit
//        node serve.mjs --export [<file>] [--include flows,notes,recent,health] --sortie=<lab>/.vibeflow/cockpit   (a copy to share; default flows,notes)
//
// The server listens on 127.0.0.1 only. Each question runs in the codebase root, on your own account:
// `claude -p` with read-only tools (Read, Grep, Glob, and Bash limited to the module's two query scripts), or
// `codex exec` in its read-only sandbox. It uses the one that built the map, else whichever is installed.
// When the map is rebuilt, open tabs reload in place. The running server is recorded in .cache/server.json.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawn, execFile, execFileSync } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';

const code = path.dirname(fileURLToPath(import.meta.url)); // dossier du CODE (le moteur du module) : jamais la sortie
const moduleRoot = path.resolve(code, '..', '..', '..'); // racine du module : porte scripts/ et skills/cockpit-moteur/
const scriptsDir = path.join(moduleRoot, 'scripts');
const moteurDir = path.join(moduleRoot, 'skills', 'cockpit-moteur');
const argv = process.argv.slice(2);
const refus = (m) => { console.error(`vf-cockpit : ${m}`); process.exit(1); };
// la sortie : --sortie=<chemin réel> en DERNIER argument, de la forme <lab>/.vibeflow/cockpit, sans lien (résolution native : un échec vaut refus, A37)
const sortieArg = argv[argv.length - 1]?.startsWith('--sortie=') ? argv[argv.length - 1].slice('--sortie='.length) : '';
if (!sortieArg) refus('--sortie=<dossier> est absent (dernier argument) : refus de servir sans connaître la sortie du lab.');
let here;
try { here = fs.realpathSync(sortieArg); } catch { refus('la sortie désignée par --sortie= est introuvable : refus.'); }
if (here !== sortieArg || path.basename(here) !== 'cockpit' || path.basename(path.dirname(here)) !== '.vibeflow') refus('--sortie= doit être le chemin réel de <lab>/.vibeflow/cockpit : refus.');
const root = path.resolve(here, '..', '..'); // vibeflow P10 : la sortie est sous <lab>/.vibeflow/cockpit
for (const f of ['vf-cockpit-env.mjs', 'vf-cockpit-module.mjs', 'vf-cockpit-server.mjs']) if (!fs.existsSync(path.join(scriptsDir, f))) refus(`${f} est absent du module : refus de servir (réinstaller le module cockpit).`);
const depuisModule = (f) => import(pathToFileURL(path.join(scriptsDir, f)).href);
const MOD = await depuisModule('vf-cockpit-module.mjs');
try { MOD.moduleAdmis(root, scriptsDir, moteurDir); } catch (e) { refus(e.message); } // défense en profondeur : jamais de code pris sous la sortie ni sous .vibeflow/
if (process.env.VF_COCKPIT_SCRIPTS_DIR === undefined) process.env.VF_COCKPIT_SCRIPTS_DIR = scriptsDir; if (process.env.VF_COCKPIT_ENGINE_DIR === undefined) process.env.VF_COCKPIT_ENGINE_DIR = moteurDir; // posées quand elles manquent (jamais un repli sur la sortie) ; une valeur passée, même vide, est respectée : l'agent est alors indisponible (fermé par défaut, Q13.3)
// 79-06 F2 : un dossier de scripts passé par l'environnement, différent de celui du module et situé SOUS <lab>/.vibeflow/ (les données du lab, jamais du code), est refusé ; les autres valeurs gardent leur effet (une pose de projet vit sous <lab>/.claude/, le moteur sous .vibeflow/ est refusé plus loin par le terminal)
{ let r = null; try { r = process.env.VF_COCKPIT_SCRIPTS_DIR ? fs.realpathSync(process.env.VF_COCKPIT_SCRIPTS_DIR) : null; } catch {} if (r && r !== fs.realpathSync(scriptsDir) && r.startsWith(path.join(root, '.vibeflow') + path.sep)) refus('VF_COCKPIT_SCRIPTS_DIR désigne un dossier de données du lab (.vibeflow) : refus (le code qui sert le lab vient du module).'); }

process.env.PATH = (await depuisModule('vf-cockpit-env.mjs')).assainirPath(process.env.PATH, root); // vibeflow P25 : jamais d'outil du lab (H-1) ; ce processus seul, pas le shell
const opt = (name, dflt) => { const i = argv.indexOf('--' + name); return i < 0 ? dflt : argv[i + 1]; };
const has = (name) => argv.includes('--' + name);
const stateFile = path.join(here, '.cache', 'server.json');
// vibeflow AUDC-H3 : le journal (serveur.log) porte la date et le motif de chaque arrêt ; jamais un jeton ni un contenu
const journal = (m) => console.log(`${new Date().toISOString()} ${m}`);
let motifArret = 'fin du processus';
const readState = () => { try { return JSON.parse(fs.readFileSync(stateFile, 'utf8')); } catch { return null; } };
if (has('stop')) {
  const s = readState();
  let stopped = false;
  // vibeflow P18 : pid entier > 1 seulement (le fichier vient du lab) ; 79-06 F3 : et seulement s'il est CE serveur (ce serve.mjs du module ET --sortie=<ce dossier>), comme le lanceur (estNotre)
  const identite = (pid) => { if (pid === process.pid) return false; if (process.platform === 'win32') return true; const ps = ['/bin/ps', '/usr/bin/ps'].find((f) => fs.existsSync(f)); if (!ps) return false; try { const c = ` ${execFileSync(ps, ['-o', 'command=', '-p', String(pid)], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], timeout: 5000 }).trimEnd()} `; return c.includes(` ${path.join(code, 'serve.mjs')} `) && c.endsWith(` --sortie=${here} `); } catch { return false; } };
  if (Number.isInteger(s?.pid) && s.pid > 1) { let vit = true; try { process.kill(s.pid, 0); } catch { vit = false; } if (vit && !identite(s.pid)) { console.error(`PID ${s.pid} non reconnu comme le serveur de ce cockpit : rien n'a été arrêté.`); process.exit(5); } if (vit) { try { process.kill(s.pid); stopped = true; } catch {} } }
  try { fs.unlinkSync(stateFile); } catch {}
  console.log(stopped ? `Stopped the map server (${s.url}).` : 'The map server was not running.');
  process.exit(0);
}

// ---------- export: a copy of the map to share ----------
// The same self-contained page, marked as exported: no Ask bar, no requests for Claude or Codex, no links into
// this computer, and only the extras asked for. Used by the map's Export button and by --export.
const EXPORT_PARTS = ['flows', 'notes', 'recent', 'health'];
const EXPORT_DEFAULT = ['flows', 'notes'];
const DATA_START = '<script>window.VF_COCKPIT = ';
function exportMap(include, extraFlows = []) {
  const html = fs.readFileSync(path.join(here, 'index.html'), 'utf8');
  const a = html.indexOf(DATA_START), b = html.indexOf(';</script>', a);
  if (a < 0 || b < 0) {
    const dit = "Cette carte est trop ancienne pour être exportée. Demandez d'abord à Claude ou à Codex de mettre le cockpit à jour.";
    throw Object.assign(new Error(dit), { plain: true });
  }
  const g = JSON.parse(html.slice(a + DATA_START.length, b));
  const on = EXPORT_PARTS.filter((p) => include.includes(p));
  const out = {
    ...g,
    // the remote can carry a sign-in token; the folder path is this computer's
    meta: { ...(({ vfTouch, vfGit, ...m }) => m)(g.meta), root: null, repos: (g.meta.repos || []).map(({ remote, ...r }) => r), exported: { at: new Date().toISOString(), include: on } }, // vibeflow AUDC-B-04 : ni les plans touchés par fichier (vfTouch) ni dépôt, worktree et branche (vfGit)
    flows: on.includes('flows') ? [...g.flows, ...extraFlows.filter((f) => !g.flows.some((x) => x.id === f.id))] : [],
    tour: on.includes('flows') ? g.tour : [],
    files: on.includes('notes') ? g.files : g.files.map(({ note, ...f }) => f),
  };
  if (!on.includes('recent')) delete out.recent;
  if (!on.includes('health')) delete out.health;
  const json = JSON.stringify(out).replace(/</g, '\\u003c').replace(/\u2028/g, '\\u2028').replace(/\u2029/g, '\\u2029');
  const slug = String(g.project?.name || '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '') || 'vibeflow';
  return { html: html.slice(0, a + DATA_START.length) + json + html.slice(b), name: `${slug}-carte.html`, include: on, plan: !!g.meta?.blueprint };
}
/** Flows requested from the map since it was last built, as the page sends them: checked and trimmed. */
const cleanFlows = (list) => (Array.isArray(list) ? list : []).slice(0, 50)
  .filter((f) => f && typeof f.id === 'string' && Array.isArray(f.steps))
  .map((f) => ({
    id: f.id.slice(0, 100), title: String(f.title || 'Parcours').slice(0, 200), description: String(f.description || '').slice(0, 1000), custom: true,
    steps: f.steps.slice(0, 60).filter((s) => s && typeof s.ref === 'string').map((s) => ({ ref: s.ref.slice(0, 300), note: String(s.note || '').slice(0, 2000) })),
  }))
  .filter((f) => f.steps.length >= 2);
if (has('export')) {
  const dest = opt('export');
  const include = String(opt('include', EXPORT_DEFAULT.join(','))).split(',').map((s) => s.trim().toLowerCase());
  try {
    const x = exportMap(include);
    const file = path.resolve(dest && !dest.startsWith('--') ? dest : path.join(here, x.name));
    fs.writeFileSync(file, x.html);
    console.log(`Exported the map to ${file}`);
    const label = { flows: 'flows and the tour', notes: 'notes', recent: 'recent work', health: x.plan ? 'the design review' : 'the health check' };
    console.log(`Includes: the map${x.include.map((p) => ', ' + label[p]).join('')}. One file that opens in any browser, with no Ask bar.`);
    if (x.include.includes('health') && !x.plan) console.log('It includes the health check: which endpoints are open and where secrets sit in the code (never their values). Share it only with people you trust.');
    process.exit(0);
  } catch (e) { console.error(`✗ Couldn't export the map: ${e.message}`); process.exit(1); }
}
const wantPort = Number(opt('port', 4378));
const idleExit = Number(opt('idle-exit', 0)) * 60000; // stop this long after the last tab closes (0 = never)
const selfHash = MOD.empreinteModule({ dossierScripts: scriptsDir, dossierMoteur: moteurDir }); // même fonction que le lanceur (SOCL-08) : l'empreinte de TOUT le code évalué du module
const model = opt('model', process.env.VF_COCKPIT_MODEL || '');
const token = crypto.randomBytes(16).toString('hex');
const TYPES = { '.html': 'text/html; charset=utf-8', '.json': 'application/json', '.js': 'text/javascript', '.mjs': 'text/javascript', '.css': 'text/css', '.svg': 'image/svg+xml' };

// ---------- find the CLI that answers: Claude Code or Codex ----------
function which(cmd) {
  try {
    const out = execFileSync(process.platform === 'win32' ? 'where' : 'which', [cmd], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], timeout: 5000 }); // vibeflow P18 : timeout
    return out.split(/\r?\n/).map((s) => s.trim()).filter(Boolean);
  } catch { return []; }
}
/** Returns { cmd, args, path } to spawn, or null. Handles native installs, npm shims on Windows, and .js entry points. */
function resolveCli(candidates, npmEntry) {
  for (const c of candidates) {
    if (!c || !fs.existsSync(c)) continue;
    if (/\.(m?js)$/i.test(c)) return { cmd: process.execPath, args: [c], path: c };
    if (/\.(cmd|bat|ps1)$/i.test(c) || (process.platform === 'win32' && !path.extname(c))) {
      // npm shim: run its JS entry point with node directly (spawning .cmd files needs a shell)
      const cli = path.join(path.dirname(c), 'node_modules', ...npmEntry);
      if (fs.existsSync(cli)) return { cmd: process.execPath, args: [cli], path: c };
      const exe = c.replace(/\.(cmd|bat|ps1)$/i, '.exe');
      if (exe !== c && fs.existsSync(exe)) return { cmd: exe, args: [], path: exe };
      // newer npm installs ship a real program inside the package (bin/claude.exe) and no JS entry point; the shim beside it can't be spawned
      const pkgExe = path.join(path.dirname(c), 'node_modules', ...npmEntry.slice(0, 2), 'bin', path.basename(c).replace(/\.[^.]*$/, '') + '.exe');
      if (fs.existsSync(pkgExe)) return { cmd: pkgExe, args: [], path: pkgExe };
      continue;
    }
    return { cmd: c, args: [], path: c };
  }
  return null;
}
const HOME = process.env.HOME || process.env.USERPROFILE || '';
const given = (name) => { const p = opt(name, process.env['VF_COCKPIT_' + name.toUpperCase()]); return p ? [p] : null; };
/** The Codex desktop app keeps its CLI in a versioned folder; newest first. */
function codexApp() {
  if (process.platform === 'darwin') return ['/Applications/Codex.app/Contents/Resources/codex'];
  if (process.platform !== 'win32') return [];
  const base = path.join(process.env.LOCALAPPDATA || '', 'OpenAI', 'Codex', 'bin');
  try {
    return fs.readdirSync(base).map((d) => path.join(base, d, 'codex.exe')).filter((f) => fs.existsSync(f))
      .sort((a, b) => fs.statSync(b).mtimeMs - fs.statSync(a).mtimeMs);
  } catch { return []; }
}
// The agents that can answer, one entry each: what it's called, where to get it, how to find its CLI, how to
// run one request (run, below), and whether its answers are held to a schema (structured). Changing a
// blueprint from the map needs that, so Change is offered only with a structured engine. schemaFile: the
// CLI reads its schema from a file rather than the command line.
const ENGINES = {
  claude: {
    name: 'Claude Code CLI', site: 'https://docs.claude.com/en/docs/claude-code', structured: true,
    find: () => resolveCli(given('claude') || [
      ...which('claude'),
      path.join(HOME, '.local', 'bin', process.platform === 'win32' ? 'claude.exe' : 'claude'),
      ...(process.platform === 'win32' ? [path.join(process.env.APPDATA || '', 'npm', 'claude.cmd')] : []),
    ], ['@anthropic-ai', 'claude-code', 'cli.js']),
    run: claudeRun,
  },
  codex: {
    name: 'Codex', site: 'https://developers.openai.com/codex', structured: true, schemaFile: true,
    find: () => resolveCli(given('codex') || [...which('codex'), ...codexApp()], ['@openai', 'codex', 'bin', 'codex.js']),
    run: codexRun,
  },
};
// --engine (or VF_COCKPIT_ENGINE) decides; otherwise the agent that built the map, then the others in order
const builtBy = (() => { try { return JSON.parse(fs.readFileSync(path.join(here, 'graph.json'), 'utf8')).meta?.agent; } catch { return null; } })();
const asked = opt('engine', process.env.VF_COCKPIT_ENGINE);
const isEngine = (k) => typeof k === 'string' && Object.hasOwn(ENGINES, k);
const want = 'claude'; // vibeflow P14 : Claude Code seul est un agent admis (aucun autre appel sortant) ; --engine et le repli sur codex sont ignorés
let engine = null, cli = null;
for (const k of ['claude']) { cli = ENGINES[k].find(); if (cli) { engine = k; break; } } // vibeflow P14
const canChange = !engine || ENGINES[engine].structured;
// Started from inside a Claude Code or Codex session? Don't let the CLI think it's nested in it.
function cliEnv() {
  const env = { ...process.env };
  for (const k of Object.keys(env)) if (/^CLAUDE_?CODE_(SESSION|ENTRYPOINT|CHILD|MESSAGING|HOST|SDK)|^CLAUDECODE$|^CODEX_(THREAD_ID|SESSION_ID|TOOL_CALL_ID|CI$|SANDBOX)/.test(k)) delete env[k];
  return env;
}
let version = null;
// vibeflow AUDC-AB1 : lue en asynchrone, le démarrage n'attend jamais `claude --version` ; `version` reste null jusqu'à la réponse (/api/health la rend)
if (cli) { try { const v = execFile(cli.cmd, [...cli.args, '--version'], { encoding: 'utf8', timeout: 15000, windowsHide: true }, (err, out) => { if (!err) version = String(out).trim(); }); v.stdin?.end(); } catch {} }

// The page, the graph, and the instructions and answer schema (from query.mjs's inlined graph-query
// code). Loaded at start and again whenever the map is rebuilt.
let TERM = null; // vibeflow P26 : terminal intégré, chargé seulement avec --terminal (second écouteur 127.0.0.1, aucun effet sans le drapeau)
if (has('terminal')) { try { TERM = (await depuisModule('vf-cockpit-terminal.mjs')).preparerTerminal({ here, root, jetons: () => [token, VF?.ptoken] }); } catch (e) { console.error(`vf-cockpit : terminal indisponible : ${e.message}. Relancer « vf-cockpit build ».`); } } // vibeflow P26
const inject = `<script>window.VF_COCKPIT_SERVER=${JSON.stringify({ token, cli: !!cli, engine, want, model: model || null, change: canChange, unFlux: true }).replace(/</g, '\\u003c')};</script>` + (TERM ? TERM.injection() : ''); // vibeflow P26
let page, G, core, MODES;
// vibeflow P13 : serveur unique. Le direct, « au travail » et la page Projet vivent dans vf-cockpit-server.mjs, posé à côté de
// vibeflow P13 : ce fichier ; absent, le serveur reste celui de l'amont. Même port que la page, aucun en-tête CORS.
// vibeflow P18 : jamais de repli sur l'agent amont non confiné (vf-cockpit-server.mjs absent du module : refus plus haut)
const VF = (await depuisModule('vf-cockpit-server.mjs')).attach({ here, root, token, inject, log: (cat, msg) => { if (cat === 'error' || cat === 'warn') console.error(`vf-cockpit : ${msg}`); } }); // vibeflow P13
function load() {
  const html = fs.readFileSync(path.join(here, 'index.html'), 'utf8');
  const g = JSON.parse(fs.readFileSync(path.join(here, 'graph.json'), 'utf8'));
  const coreSrc = fs.readFileSync(path.join(code, 'graph-query.js'), 'utf8'); // le cœur de requête vient du module, jamais de la sortie (AM4.2)
  const c = new Function(`${coreSrc.replace(/^import .*$/gm, '')}; return { VF_COCKPIT_ANSWER_SCHEMA, VF_COCKPIT_FLOW_SCHEMA, VF_COCKPIT_CHANGE_SCHEMA, vfCockpitAskInstructions, vfCockpitFlowInstructions, vfCockpitChangeInstructions, createGraphQuery };`)();
  c.q = c.createGraphQuery(g);
  page = html.replace('</head>', inject + '</head>');
  G = g; core = c;
  // kinds of request: a question (answer + board), a new guided flow, and for a blueprint, a change to the
  // plan. Codex reads its schema from a file.
  MODES = {
    ask: { instructions: core.vfCockpitAskInstructions(G, 'cli'), schema: core.VF_COCKPIT_ANSWER_SCHEMA, file: path.join(here, '.cache', 'answer-schema.json') },
    flow: { instructions: core.vfCockpitFlowInstructions(G, 'cli'), schema: core.VF_COCKPIT_FLOW_SCHEMA, file: path.join(here, '.cache', 'flow-schema.json') },
    ...(G.meta?.blueprint && canChange ? { change: { instructions: core.vfCockpitChangeInstructions(G), schema: core.VF_COCKPIT_CHANGE_SCHEMA, file: path.join(here, '.cache', 'change-schema.json') } } : {}),
  };
  VF?.load(); // vibeflow P13 : la page Projet est relue avec la carte
  if (ENGINES[engine]?.schemaFile) {
    fs.mkdirSync(path.join(here, '.cache'), { recursive: true });
    for (const m of Object.values(MODES)) fs.writeFileSync(m.file, JSON.stringify(strict(m.schema)));
  }
}
/** OpenAI structured outputs want every property required and nothing extra; optional lists just come back empty. */
function strict(s) {
  if (s?.type === 'object' && s.properties) return { ...s, properties: Object.fromEntries(Object.entries(s.properties).map(([k, v]) => [k, strict(v)])), required: Object.keys(s.properties), additionalProperties: false };
  if (s?.type === 'array') return { ...s, items: strict(s.items) };
  return s;
}
load();

// ---------- open tabs: live reload, and idle shutdown ----------
const tabs = new Set();
let lastTab = Date.now();
const broadcast = (event, data = {}) => { for (const t of tabs) t.write(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`); VF?.diffuserCarte?.(event, data); }; // vibeflow AUDC-H1 : la page n'ouvre qu'un flux, celui du direct : le rechargement de la carte y passe aussi
let reloadTimer = null;
fs.watchFile(path.join(here, 'index.html'), { interval: 1000 }, (cur, prev) => {
  if (cur.mtimeMs === prev.mtimeMs) return;
  // build writes several files; wait for it to finish, and keep serving the old map if the new one is half-written
  clearTimeout(reloadTimer);
  reloadTimer = setTimeout(() => { try { load(); broadcast('reload'); console.log('map rebuilt: reloaded open tabs'); } catch {} }, 800);
});
// vibeflow P26 : une session de terminal ouverte empêche l'arrêt pour inactivité ; AUDC-H3 : toute requête authentifiée et tout flux de page ouvert comptent comme activité, et la rétention par le terminal est écrite au journal
let retenuDit = false;
if (idleExit) setInterval(() => {
  if (tabs.size || running.size || VF?.ouverts?.() || Date.now() - Math.max(lastTab, VF?.dernierFlux?.() || 0) <= idleExit) return;
  if (TERM?.occupe()) { if (!retenuDit) { retenuDit = true; journal("arrêt sur inactivité retenu : un terminal est ouvert"); } return; }
  motifArret = `inactivité (${idleExit / 60000} min sans requête authentifiée ni onglet)`; process.exit(0);
}, (() => { const n = Number(process.env.VF_COCKPIT_IDLE_TICK_MS); return Number.isInteger(n) && n >= 100 && n < 60000 ? n : 60000; })()).unref(); // période de contrôle : 60 s, réglage de test seulement
const flowsFile = path.join(here, 'custom-flows.json');
const readFlows = () => { try { return JSON.parse(fs.readFileSync(flowsFile, 'utf8')).flows || []; } catch { return []; } };

// vibeflow P11 : la fonction Cloud amont (liste d'attente, e-mail du compte, réglages personnels) est retirée : aucune donnée ne sort.

// ---------- asking ----------
const nameFor = (id) => { try { return core.q.brief(id)?.name || id; } catch { return id; } };
const running = new Map();
const lingering = new Map(); // vibeflow AUDC-B-02 : agents qui ont répondu sans être sortis : hors du plafond, mais atteignables par /api/cancel et bornés par le délai global
const rel = (p) => String(p || '').replace(/\\/g, '/').replace(root.replace(/\\/g, '/') + '/', '');
/** A shell command, in words: map lookups by name, then searches, file reads and listings. */
function describeCommand(command) {
  let c = String(command || '');
  // Codex wraps each command in a shell: bash -lc '…' or powershell.exe -Command "…"
  const wrapped = /\s-(?:l?c|Command)\s+(["'])([\s\S]*)\1\s*$/i.exec(c);
  if (wrapped) c = wrapped[2].replace(/\\(["'])/g, '$1');
  const cmds = c.split(/\s*(?:&&|;|\|\|?)\s*/).filter(Boolean);
  // agents often chain several lookups in one command; describe each one, by name
  const parts = cmds.map((x) => /query(?:-cli)?\.mjs\s+(\w+)\s*(.*)$/.exec(x)).filter(Boolean); // vibeflow 79-06 : aussi query-cli.mjs, le script de requête du moteur
  if (parts.length) {
    const one = ([, cmd, rest]) => {
      const a = rest.replace(/--\w+\s+\S+/g, '').replace(/["']/g, '').trim();
      return { overview: "Lit l'aperçu de la carte", find: a ? `Cherche « ${a} » dans la carte` : 'Cherche dans la carte', show: `Examine ${a.split(/\s+/).map(nameFor).join(', ')}`,
        path: `Suit un chemin ${a.split(/\s+/).map(nameFor).join(' → ')}` }[cmd] || 'Interroge la carte';
    };
    return parts.slice(0, 2).map(one).join(' · ') + (parts.length > 2 ? ` (+${parts.length - 2} more)` : '');
  }
  const first = cmds[0] || '';
  if (/^(rg|grep|git grep|Select-String|findstr)\b/i.test(first) && !/\s--files\b/.test(first)) {
    const pat = /\s(["'])(.+?)\1/.exec(first)?.[2] || /\s(?:-Pattern\s+)?([^\s-][^\s]*)/i.exec(first.replace(/^\S+(\s+-\S+)*/, ''))?.[1];
    return pat ? `Cherche « ${pat} » dans le code` : 'Cherche dans le code';
  }
  if (/^(rg\s.*--files|ls|dir|Get-ChildItem|gci|find|tree)\b/i.test(first)) return 'Liste des fichiers';
  if (/^(cat|type|Get-Content|gc|sed|head|tail|nl|more|less)\b/i.test(first)) {
    const file = [...first.matchAll(/[\w@.\\/-]+\.\w{1,6}\b/g)].map((m) => m[0]).pop();
    return file ? `Lit ${rel(file)}` : 'Lit un fichier';
  }
  return 'Lance une commande';
}
function describeTool(name, input = {}) {
  if (name === 'Bash') return describeCommand(input.command);
  // a long result the CLI saved to read back in parts lives outside the project
  if (name === 'Read') return /[\\/]tool-results[\\/]/.test(input.file_path || '') ? "Lit la suite d'un long fichier" : `Lit ${rel(input.file_path)}`;
  if (name === 'Grep') return `Cherche « ${input.pattern} » dans le code`;
  if (name === 'Glob') return `Liste ${input.pattern}`;
  return name;
}
function parseAnswer(ev) {
  if (ev.structured_output && typeof ev.structured_output === 'object') return ev.structured_output;
  const t = String(ev.result || '');
  const fence = /```(?:json)?\s*([\s\S]*?)```/.exec(t);
  for (const cand of [t, fence?.[1], t.slice(t.indexOf('{'), t.lastIndexOf('}') + 1)]) { try { const v = JSON.parse(cand); if (v && typeof v === 'object') return v; } catch {} }
  return { title: 'Réponse', answer: t, items: [] };
}
const failCode = (msg) => /not logged in|logged out|\/login|log ?in again|sign in|authenticat|unauthori[sz]ed|\b401\b/i.test(msg) ? 'not_logged_in'
  : /usage limit|rate limit|too many requests|\b429\b/i.test(msg) ? 'rate_limited' : 'cli_error';
// Claude Code: `claude -p` with read-only tools, answering in the schema; follow-ups resume its session
const issued = new Set(); // vibeflow AUDC-A-01 : les identifiants de session que CE serveur a rendus ; « Demander » ne reprend rien d'autre
const noteSession = (id) => { if (typeof id !== 'string' || !/^[0-9a-f-]{36}$/i.test(id)) return; issued.add(id); if (issued.size > 500) issued.delete(issued.values().next().value); };
function claudeRun(body, mode) {
  const args = [...cli.args, '-p', '--output-format', 'stream-json', '--verbose',
    '--json-schema', JSON.stringify(mode.schema), '--append-system-prompt', mode.instructions,
    '--tools', 'Read,Grep,Glob,Bash']; // vibeflow 79-06 : les outils et leurs règles viennent de VF.argsAgent (liste mesurée, scripts du module) ; aucune règle relative à la sortie ici
  if (typeof body.session === 'string' && /^[0-9a-f-]{36}$/i.test(body.session) && issued.has(body.session)) args.push(`--resume=${body.session}`); // vibeflow P18 : un identifiant de session, jamais un drapeau
  if (model) args.push('--model', model);
  return {
    args: VF ? VF.argsAgent(args, body) : args, input: String(body.question || '').slice(0, 4000), // vibeflow P14 : confinement mesuré et modèle validé
    onEvent(ev, out) {
      if (ev.type === 'assistant') for (const c of ev.message?.content || []) if (c.type === 'tool_use') out.progress(describeTool(c.name, c.input));
      if (ev.type !== 'result') return;
      if (ev.is_error) out.fail(String(ev.result || ev.subtype || 'Claude Code reported an error'));
      else { noteSession(ev.session_id); out.answer({ ...parseAnswer(ev), session: ev.session_id }); }
    },
  };
}
// Codex: `codex exec` in its read-only sandbox, answering in the schema. Runs are ephemeral (nothing lands
// in the person's Codex history), so a follow-up carries the last few questions and answers with it.
const convos = new Map();
function codexRun(body, mode) {
  const session = convos.has(body.session) ? body.session : crypto.randomBytes(8).toString('hex');
  const turns = convos.get(session) || [];
  const question = String(body.question || '').slice(0, 4000);
  const earlier = turns.length ? `\n\nEarlier in this conversation:\n${turns.map((t) => `Q: ${t.q}\nA: ${t.a}`).join('\n\n')}` : '';
  const args = [...cli.args, 'exec', '--json', '--sandbox', 'read-only', '--skip-git-repo-check', '--ephemeral',
    '--output-schema', mode.file, '-C', root];
  if (model) args.push('--model', model);
  args.push('-');
  let last = '', error = '';
  return {
    args, input: `${mode.instructions}${earlier}\n\nThe question:\n${question}`,
    onEvent(ev, out) {
      if (ev.type === 'item.started' && ev.item?.type === 'command_execution') out.progress(describeCommand(ev.item.command));
      if (ev.type === 'item.completed' && ev.item?.type === 'agent_message') last = String(ev.item.text || '');
      if (ev.type === 'error') error = String(ev.message || error);
      if (ev.type === 'turn.failed') out.fail(String(ev.error?.message || error || 'Codex reported an error'));
      if (ev.type === 'turn.completed') {
        const a = parseAnswer({ result: last });
        convos.set(session, [...turns, { q: question.slice(0, 500), a: String(a.answer || '').slice(0, 1500) }].slice(-4));
        out.answer({ ...a, session });
      }
    },
    lastError: () => error,
  };
}
const CLOSED = Symbol('closed'); // the browser went away mid-request
const MAX_ASK = 2; // vibeflow AUDC-B-02 : deux exécutions de l'agent au plus en même temps (429 au-delà), chacune bornée par un délai global
const ASK_DELAI = (() => { const n = Number(process.env.VF_COCKPIT_ASK_DELAI_MS); return Number.isInteger(n) && n >= 1000 && n <= 3600000 ? n : 600000; })();
/** Runs the agent once for a request and resolves with its answer, streaming progress through `send`. */
function runAgent(res, send, body) {
  return new Promise((resolve, reject) => {
    if (running.size >= MAX_ASK) return reject(new Error('Deux questions sont déjà en cours : attendez la fin de l’une d’elles.')); // vibeflow AUDC-B-02 : la borne tient aussi au second essai de « modifier le plan »
    const M = VF ? VF.modes(MODES, body) : MODES; // vibeflow P14 : consigne de l'onglet Projet
    const run = ENGINES[engine].run(body, Object.hasOwn(M, body.mode) ? M[body.mode] : M.ask);
    const child = spawn(cli.cmd, run.args, { cwd: root, env: cliEnv(), stdio: ['pipe', 'pipe', 'pipe'], windowsHide: true });
    const id = crypto.randomBytes(6).toString('hex');
    running.set(id, child);
    const limit = setTimeout(() => { child.kill(); if (!done) { done = true; clearTimeout(quiet); reject(new Error(`Délai dépassé : la question est arrêtée après ${Math.round(ASK_DELAI / 1000)} s.`)); } }, ASK_DELAI); // vibeflow AUDC-B-02 : le délai court jusqu'à la sortie de l'agent, réponse rendue ou non
    send('start', { id });
    child.stdin.end(run.input);
    let buf = '', stderr = '', done = false;
    // working out and writing a whole updated plan has long stretches with nothing to report: say so after a quiet spell
    let quiet = null, said = '';
    const say = (text) => { if (!done && text !== said) { said = text; send('progress', { text }); } };
    const hush = () => { clearTimeout(quiet); if (body.mode === 'change' && !done) quiet = setTimeout(() => say('Working on the updated plan'), 12000); };
    const out = {
      progress: (text) => { if (!done) { say(text); hush(); } },
      answer: (data) => { if (!done) { done = true; clearTimeout(quiet); running.delete(id); lingering.set(id, child); resolve(data); } },
      fail: (message) => { if (!done) { done = true; clearTimeout(quiet); running.delete(id); lingering.set(id, child); reject(new Error(message)); } },
    };
    hush();
    child.stdout.on('data', (d) => {
      buf += d;
      let nl;
      while ((nl = buf.indexOf('\n')) >= 0) {
        const line = buf.slice(0, nl).trim(); buf = buf.slice(nl + 1);
        if (!line) continue;
        let ev; try { ev = JSON.parse(line); } catch { continue; }
        run.onEvent(ev, out);
      }
    });
    child.stderr.on('data', (d) => { stderr = (stderr + d).slice(-2000); });
    child.on('error', (e) => out.fail(e.message));
    child.on('close', (code) => {
      running.delete(id); lingering.delete(id); clearTimeout(limit);
      out.fail(run.lastError?.() || stderr.trim() || `${engine} exited with code ${code}`);
    });
    // the browser went away (closed tab, Stop): don't leave the CLI working. Note req 'close' fires as soon as
    // the body is read, so watch the response instead.
    res.on('close', () => { if (!done) { done = true; clearTimeout(quiet); child.kill(); reject(CLOSED); } });
  });
}
function ask(req, res, body) {
  let ouvert = false; // vibeflow AUDC-B-02 : le flux s'ouvre à la première émission, pour qu'un refus puisse encore être un 429
  const send = (event, data) => { if (!ouvert) { ouvert = true; res.writeHead(200, { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-store', Connection: 'keep-alive' }); } if (!res.writableEnded) res.write(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`); };
  if (VF && VF.avantQuestion({ req, body, send }) === 'repondu') return res.end(); // vibeflow P14 : réponse locale ou refus de modèle
  if (!cli) { send('failure', { code: 'cli_missing', message: `${ENGINES[want].name} introuvable.` }); return res.end(); }
  if (running.size >= MAX_ASK) { res.writeHead(429, { 'Content-Type': 'application/json', 'Retry-After': '5' }); return res.end(JSON.stringify({ error: 'Deux questions sont déjà en cours : attendez la fin de l’une d’elles.' })); } // vibeflow AUDC-B-02
  if (body.mode === 'change') return changePlan(res, send, body);
  if (engine === 'claude' && typeof body.session === 'string' && body.session && !issued.has(body.session)) { send('failure', { code: 'session_inconnue', message: 'Cette conversation n’a pas été ouverte par ce serveur : rechargez la page pour en commencer une nouvelle.' }); return res.end(); } // vibeflow AUDC-A-01
  runAgent(res, send, body)
    .then((a) => send('answer', a), (e) => { if (e !== CLOSED) send('failure', { code: failCode(e.message), message: e.message }); })
    .finally(() => res.end());
}

// ---------- changing a blueprint from the map ----------
// The agent stays read-only: it returns the whole updated plan.json and architecture.json, and this server
// checks them with the skill's plan.mjs and build.mjs (build.mjs records where they are), saves them and
// redraws the map, which reloads every open tab. Each change keeps the files it replaced, for Undo.
const historyDir = path.join(here, '.cache', 'history');
try { fs.rmSync(path.join(here, '.cache', 'skill.json'), { force: true }); fs.rmSync(historyDir, { recursive: true, force: true }); } catch {} // vibeflow P15 : l'état d'un lab n'est jamais cru
const PLAN_FILES = ['plan.json', 'architecture.json', 'recent-work.json'];
let changing = false;
function snapshot() {
  const dir = path.join(historyDir, Date.now().toString(36));
  fs.mkdirSync(dir, { recursive: true });
  for (const f of PLAN_FILES) if (fs.existsSync(path.join(here, f))) fs.copyFileSync(path.join(here, f), path.join(dir, f));
  for (const old of fs.readdirSync(historyDir).sort().slice(0, -20)) fs.rmSync(path.join(historyDir, old), { recursive: true, force: true });
  return dir;
}
function restore(dir) {
  for (const f of PLAN_FILES) { const from = path.join(dir, f), to = path.join(here, f); if (fs.existsSync(from)) fs.copyFileSync(from, to); else fs.rmSync(to, { force: true }); }
}
/** Runs one of the skill's scripts on this project; throws with its output when it fails. */
// vibeflow P15 : jamais un script désigné par le lab. Le moteur vient du module (VF_COCKPIT_ENGINE_DIR, posé par le lanceur) et seuls
// plan.mjs et build.mjs s'exécutent ; .cache/skill.json et .cache/history/ préexistants sont ignorés (supprimés au démarrage).
const engineDirFromLauncher = () => { const d = process.env.VF_COCKPIT_ENGINE_DIR; return d && path.isAbsolute(d) ? d : null; };
function skillScript(name, ...args) {
  const dir = engineDirFromLauncher();
  if (!['plan.mjs', 'build.mjs'].includes(name) || !dir || !fs.existsSync(path.join(dir, 'scripts', name))) throw new Error('Le serveur du cockpit ne trouve pas les scripts VibeFlow. Demandez à Claude Code ou à Codex de mettre le cockpit à jour une fois, puis réessayez.');
  try { return execFileSync(process.execPath, [path.join(dir, 'scripts', name), root, ...args], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], windowsHide: true, timeout: 120000 }); }
  catch (e) { throw Object.assign(new Error(String(e.stdout || '') + String(e.stderr || '') || e.message), { checks: true }); }
}
/** The "  - …" lines under the scripts' "✗ N error(s)" heading (warnings follow under "!"). */
function problems(text) {
  const out = [];
  let inErrors = false;
  for (const l of String(text || '').split('\n')) {
    if (/^✗/.test(l)) inErrors = true;
    else if (/^\S/.test(l)) inErrors = false;
    else if (inErrors && /^\s+- /.test(l)) out.push(l.trim().slice(2));
  }
  return out;
}
/** Checks and saves an updated plan. Returns { ok, undo } or { errors } with nothing changed. */
function applyChange(data, request, lastTry) {
  const parse = (name, text) => { try { const v = JSON.parse(String(text || '')); return v && typeof v === 'object' && !Array.isArray(v) ? v : null; } catch { return null; } };
  const plan = parse('plan', data.plan), arch = parse('architecture', data.architecture);
  if (!plan || !arch) return { errors: [`${!plan ? 'plan' : 'architecture'} isn't a complete JSON object`] };
  const snap = snapshot();
  const write = (f, v) => fs.writeFileSync(path.join(here, f), JSON.stringify(v, null, 2) + '\n');
  try {
    write('plan.json', plan);
    write('architecture.json', arch);
    const items = (Array.isArray(data.changes) ? data.changes : []).filter((c) => c && typeof c.ref === 'string').map((c) => ({ ref: c.ref, change: c.change === 'changed' ? 'changed' : 'new', note: String(c.note || '') }));
    // the Recent work panel shows plain text: the summary's first paragraph, without Markdown marks
    const plain = String(data.summary || '').split(/\n\s*\n/)[0].replace(/\*\*|__|`/g, '').replace(/\s+/g, ' ').trim();
    write('recent-work.json', { updatedAt: new Date().toISOString(), tasks: [{ title: String(data.title || 'Changed the plan').slice(0, 80), request, summary: plain, status: 'planned, not built', items }] });
    skillScript('plan.mjs');
    const check = skillScript('build.mjs', '--check');
    const unassigned = +(/(\d+) unassigned/.exec(check)?.[1] || 0);
    if (unassigned && !lastTry) throw Object.assign(new Error(''), { checks: true, list: [`${unassigned} planned file(s) fall under no node's paths in architecture.json (add or widen globs)`] });
    skillScript('build.mjs', '--no-claude-md');
    return { ok: true, undo: path.basename(snap) };
  } catch (e) {
    restore(snap);
    fs.rmSync(snap, { recursive: true, force: true });
    try { skillScript('plan.mjs'); } catch {}
    if (!e.checks) throw e;
    return { errors: e.list || problems(e.message).slice(0, 12).concat(problems(e.message).length ? [] : [e.message.trim().split('\n').pop()]) };
  }
}
async function changePlan(res, send, body) {
  const request = String(body.question || '').slice(0, 4000);
  if (!MODES.change) { send('failure', { code: 'cli_error', message: G.meta?.blueprint ? `${ENGINES[engine].name} can't change a plan from the map.` : 'Only a blueprint can be changed from the map.' }); return res.end(); }
  if (changing) { send('failure', { code: 'busy', message: 'Another change to this plan is still being made. Try again when it’s done.' }); return res.end(); }
  changing = true;
  let session, errors = null;
  try {
    for (let attempt = 0; attempt < 2; attempt++) {
      const question = errors
        ? `Your updated plan didn't pass the checks, so nothing was saved:\n${errors.map((e) => `- ${e}`).join('\n')}\n\nFix these and reply again with the complete files. The request was: ${request}`
        : request;
      const data = await runAgent(res, send, { question, session, mode: 'change' });
      session = data.session || session;
      send('progress', { text: 'Checking the updated plan' });
      const r = applyChange(data, request, attempt === 1);
      if (r.ok) {
        console.log(`plan changed: ${data.title || request.slice(0, 60)}`);
        send('answer', { title: String(data.title || ''), summary: String(data.summary || ''), changes: (data.changes || []).length, followups: Array.isArray(data.followups) ? data.followups.map(String).slice(0, 3) : [], undo: r.undo });
        return;
      }
      errors = r.errors;
      send('progress', { text: `Fixing ${errors.length === 1 ? 'a problem' : `${errors.length} problems`} the checks found` });
    }
    send('failure', { code: 'change_invalid', message: `The updated plan didn't pass the checks, so nothing changed:\n${errors.slice(0, 6).map((e) => `- ${e}`).join('\n')}` });
  } catch (e) {
    if (e !== CLOSED) send('failure', { code: failCode(String(e.message || e)), message: String(e.message || e) });
  } finally { changing = false; res.end(); }
}
/** Puts back the files a change replaced (the newest first), and redraws. */
function undoChange() {
  const all = fs.existsSync(historyDir) ? fs.readdirSync(historyDir).sort() : [];
  if (!all.length) return { ok: false, error: 'Rien à annuler.' };
  const dir = path.join(historyDir, all[all.length - 1]);
  restore(dir);
  try { skillScript('plan.mjs'); skillScript('build.mjs', '--no-claude-md'); } catch (e) {
    console.error(`✗ Undo couldn't redraw the plan: ${e.message || e}`);
    return { ok: false, error: 'Couldn’t redraw the previous plan. The details are in the map server’s output.' };
  }
  fs.rmSync(dir, { recursive: true, force: true });
  return { ok: true, left: all.length - 1 };
}

// ---------- http ----------
// vibeflow P18 : un corps n'est cru que s'il est un objet JSON (null, 5, "s", [..] : 400, jamais une exception)
const parseBody = (raw) => { try { const b = JSON.parse(raw); return b && typeof b === 'object' && !Array.isArray(b) ? b : null; } catch { return null; } };
const sameToken = (a, b) => { if (typeof a !== 'string' || typeof b !== 'string') return false; const x = Buffer.from(a), y = Buffer.from(b); return x.length === y.length && crypto.timingSafeEqual(x, y); }; // vibeflow AUDC-B-06 : comparaison en temps constant
const bad = (res) => { res.writeHead(400, { 'Content-Type': 'application/json' }); res.end(JSON.stringify({ error: 'Requête invalide : un objet JSON est attendu.' })); };
// vibeflow P17 : en-têtes de toutes les réponses. La page ne charge que ses scripts en ligne (empreintes), aucune origine tierce,
// ne se laisse pas encadrer, n'envoie aucun formulaire. Les polices et logos sont des data: ; les styles en ligne sont admis (36 attributs style).
const BASE_CSP = "default-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'";
const cspMemo = new Map(); // les pages pèsent ~2 Mo : une empreinte par contenu, pas par requête
const pageCsp = (html) => {
  if (cspMemo.has(html)) return cspMemo.get(html);
  const hashes = [...String(html).matchAll(/<script>([\s\S]*?)<\/script>/g)].map((m) => `'sha256-${crypto.createHash('sha256').update(m[1]).digest('base64')}'`);
  const csp = `default-src 'none'; script-src ${[...new Set(hashes)].join(' ')}; style-src 'unsafe-inline'; img-src 'self' data:; font-src data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'; object-src 'none'`;
  if (cspMemo.size >= 4) cspMemo.clear();
  cspMemo.set(html, csp);
  return csp;
};
const sendPage = (res, html) => { res.setHeader('Content-Security-Policy', pageCsp(html) + (TERM ? TERM.frameSrc() : '')); res.writeHead(200, { 'Content-Type': TYPES['.html'], 'Cache-Control': 'no-store' }); return res.end(html); }; // vibeflow P26 : frame-src de la CSP de page s'ajoute hors de pageCsp (v2.75.0 intacte)
const server = http.createServer((req, res) => {
  res.setHeader('Content-Security-Policy', BASE_CSP); res.setHeader('X-Content-Type-Options', 'nosniff'); res.setHeader('X-Frame-Options', 'DENY');
  try { route(req, res); } catch (e) { console.error(`vf-cockpit : requête en échec : ${e?.message || e}`); try { if (!res.headersSent) res.writeHead(500); res.end(); } catch {} }
});
// vibeflow AUDC-B-03 bis : la page de redirection que le lanceur remet à l'ouvreur du poste est un fichier local (file://, origine opaque) : son saut vers la page
// Projet part toujours en `Sec-Fetch-Site: cross-site`, comme celui d'un lien d'un autre site. Un seul chemin est rouvert : GET /project.html, navigation de premier
// niveau (Mode navigate, Dest document : ni cadre, ni script, ni image, ni fetch) qui porte le SECRET D'OUVERTURE (`?o=`) écrit par le lanceur, valide tant que la clé
// d'amorçage du terminal est armée, à usage unique, comparé en temps constant (TERM.ouvertureLanceur, vf-cockpit-terminal-amorce.mjs). Sans le secret, une page d'un
// autre site n'obtient ni la page ni l'effet d'état qu'un chargement de la page Projet peut avoir. Sans --terminal, aucune exception.
const ouvertureLanceur = (req, url) => req.method === 'GET' && url.pathname === '/project.html' && req.headers['sec-fetch-mode'] === 'navigate' && req.headers['sec-fetch-dest'] === 'document' && !!TERM?.ouvertureLanceur?.(url.searchParams.get('o'));
function route(req, res) {
  // only this machine's own names: a website that points its domain at 127.0.0.1 (DNS rebinding) would
  // otherwise count as the same origin as the map, and could read its token from the page
  if (![`127.0.0.1:${port}`, `localhost:${port}`].includes(String(req.headers.host || '').toLowerCase())) { res.writeHead(403); return res.end('unknown host'); }
  const url = new URL(req.url, `http://${req.headers.host}`);
  const sameOrigin = !req.headers.origin || req.headers.origin === `http://${req.headers.host}`;
  if (!url.pathname.startsWith('/api/') && req.headers['sec-fetch-site'] === 'cross-site' && !ouvertureLanceur(req, url)) { res.writeHead(403); return res.end(); } // vibeflow AUDC-B-03 : une page d'un autre site n'obtient ni page ni fichier du cockpit (seule exception : ouvertureLanceur, AUDC-B-03 bis)
  if (url.pathname.startsWith('/api/')) {
    // EventSource can't send headers, so the events stream takes the token in the query string
    const given = req.headers['x-vf-cockpit-token'] || (url.pathname === '/api/events' || url.pathname === '/api/vf/events' ? url.searchParams.get('token') : null); // vibeflow P13
    if (!sameOrigin || (!sameToken(given, token) && !VF?.jetonValide(given))) { res.writeHead(403); return res.end(); } // vibeflow P13
    lastTab = Date.now(); // vibeflow AUDC-H3 : une requête authentifiée est une activité (l'arrêt sur inactivité ne regarde plus les seuls flux de page) ; après le refus 403, une requête non authentifiée ne compte jamais
    if (TERM && req.method === 'GET' && url.pathname === '/api/vf/terminal') return TERM.routeP(req, res); // vibeflow P26 : état du terminal (jamais un secret), après le Host et le jeton
    if (VF && url.pathname.startsWith('/api/vf/') && VF.route(req, res, url)) return; // vibeflow P13 : routes du serveur unique, après le Host et le jeton
    if (req.method === 'GET' && url.pathname === '/api/events') {
      res.writeHead(200, { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-store', Connection: 'keep-alive' });
      res.write('retry: 1000\n\n'); // reconnect quickly after a restart
      tabs.add(res);
      req.on('close', () => { tabs.delete(res); lastTab = Date.now(); });
      return;
    }
    if (req.method === 'GET' && url.pathname === '/api/status') { res.writeHead(200, { 'Content-Type': 'application/json' }); return res.end(JSON.stringify({ tabs: tabs.size + (VF?.nbPages?.() || 0), pid: process.pid, hash: selfHash, root })); }
    if (req.method === 'GET' && url.pathname === '/api/health') { res.writeHead(200, { 'Content-Type': 'application/json' }); return res.end(JSON.stringify({ cli: !!cli, engine, want, version, path: cli?.path || null })); }
    // requested flows are saved next to the map; build.mjs folds them into graph.json
    if (url.pathname === '/api/flows') {
      if (req.method === 'GET') { res.writeHead(200, { 'Content-Type': 'application/json' }); return res.end(JSON.stringify({ flows: readFlows() })); }
      if (req.method === 'POST' || req.method === 'DELETE') {
        let raw = '';
        req.on('data', (d) => { raw += d; if (raw.length > 50000) req.destroy(); });
        req.on('end', () => { try {
          const body = parseBody(raw); if (!body) return bad(res);
          let flows = readFlows().filter((x) => x.id !== body.id && x.id !== body.flow?.id);
          if (req.method === 'POST' && body.flow?.id && Array.isArray(body.flow.steps)) flows.push({ ...body.flow, createdAt: new Date().toISOString() });
          fs.writeFileSync(flowsFile, JSON.stringify({ flows }, null, 2) + '\n');
          res.writeHead(200, { 'Content-Type': 'application/json' }); res.end(JSON.stringify({ flows }));
        } catch (e) { console.error(`vf-cockpit : /api/flows : ${e.message}`); try { res.writeHead(500); res.end(); } catch {} } });
        return;
      }
    }
    if (req.method === 'POST' && url.pathname === '/api/plan/undo') {
      const r = changing ? { ok: false, error: 'Une modification est encore en cours.' } : undoChange();
      res.writeHead(200, { 'Content-Type': 'application/json' }); return res.end(JSON.stringify(r));
    }
    if (req.method === 'POST' && url.pathname === '/api/cancel') { for (const c of [...running.values(), ...lingering.values()]) c.kill(); res.writeHead(204); return res.end(); }
    if (req.method === 'POST' && url.pathname === '/api/export') {
      let raw = '';
      req.on('data', (d) => { raw += d; if (raw.length > 500000) req.destroy(); });
      req.on('end', () => {
        const body = parseBody(raw); if (!body) return bad(res);
        try {
          const x = exportMap(Array.isArray(body.include) ? body.include.map(String) : EXPORT_DEFAULT, cleanFlows(body.flows));
          res.writeHead(200, { 'Content-Type': TYPES['.html'], 'Content-Disposition': `attachment; filename="${x.name}"`, 'Cache-Control': 'no-store' });
          res.end(x.html);
        } catch (e) {
          console.error(`✗ Couldn't export the map: ${e.message}`);
          res.writeHead(500, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: e.plain ? e.message : "Le serveur du cockpit n'a pas pu l'exporter. Le détail est dans sa sortie." }));
        }
      });
      return;
    }
    if (req.method === 'POST' && url.pathname === '/api/ask') {
      let raw = '';
      req.on('data', (d) => { raw += d; if (raw.length > 20000) req.destroy(); });
      req.on('end', () => { const body = parseBody(raw); if (!body) return bad(res); try { ask(req, res, body); } catch (e) { console.error(`vf-cockpit : /api/ask : ${e.message}`); try { if (!res.headersSent) res.writeHead(500); res.end(); } catch {} } });
      return;
    }
    res.writeHead(404); return res.end();
  }
  if (url.pathname === '/equipe.html') { const pe = VF?.pageEquipe?.(); if (pe) return sendPage(res, pe); } // vibeflow P24
  if (url.pathname === '/project.html' && VF?.pageProjet()) return sendPage(res, VF.pageProjet()); // vibeflow P13, P17
  if (url.pathname === '/' || url.pathname === '/index.html') return sendPage(res, page);
  let file;
  try { file = path.join(here, decodeURIComponent(url.pathname)); } catch { res.writeHead(400); return res.end('bad address'); }
  // vibeflow P13 : jamais un segment caché (.cache/server.json porte le jeton, .gitignore) ni un segment qui sort du dossier
  if (path.relative(here, file).split(path.sep).some((seg) => seg.startsWith('.'))) { res.writeHead(404); return res.end('not found'); } // vibeflow P13
  // inside this folder only: a neighbour like ../vf-cockpit-old/ also starts with this folder's path
  if (!file.startsWith(here + path.sep) || !fs.existsSync(file) || !fs.statSync(file).isFile()) { res.writeHead(404); return res.end('not found'); }
  // vibeflow P19 : un lien symbolique n'est servi que s'il reste dans ce dossier (realpath), jamais vers un fichier du lab ou d'ailleurs
  try { if (!fs.realpathSync(file).startsWith(fs.realpathSync(here) + path.sep)) { res.writeHead(404); return res.end('not found'); } } catch { res.writeHead(404); return res.end('not found'); }
  res.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream', 'Cache-Control': 'no-store' }); // vibeflow P5
  fs.createReadStream(file).pipe(res);
}
// vibeflow P18 : une exception perdue se journalise, le serveur (détaché, personne ne le relance) ne meurt pas
process.on('uncaughtException', (e) => { console.error(`vf-cockpit : exception non rattrapée : ${e?.stack || e}`); });
process.on('unhandledRejection', (e) => { console.error(`vf-cockpit : promesse rejetée : ${e?.stack || e}`); });
// another map (or anything else) on the port: take the next free one
let port = wantPort;
server.on('error', (e) => {
  if (e.code === 'EADDRINUSE' && port < wantPort + 20) { port++; server.listen(port, '127.0.0.1'); return; }
  console.error(`✗ Couldn't start the map server: ${e.message}`);
  process.exit(1);
});
server.listen(port, '127.0.0.1');
server.on('listening', () => {
  const u = `http://127.0.0.1:${port}`;
  try {
    fs.mkdirSync(path.dirname(stateFile), { recursive: true });
    fs.writeFileSync(stateFile, JSON.stringify({ pid: process.pid, port, url: u, token, hash: selfHash, startedAt: new Date().toISOString() }, null, 2), { mode: 0o600 });
    fs.chmodSync(stateFile, 0o600); // vibeflow P18 : le jeton n'est lisible que du propriétaire (le fichier peut préexister en 0644)
  } catch {}
  TERM?.demarrer(port); // vibeflow P26 : second écouteur du terminal, une fois server.json écrit
  const forget = () => { try { if (readState()?.pid === process.pid) fs.unlinkSync(stateFile); } catch {} };
  process.on('exit', forget);
  process.on('exit', () => journal(`arrêt : ${motifArret} (PID ${process.pid})`)); // vibeflow AUDC-H3
  for (const sig of ['SIGINT', 'SIGTERM', 'SIGHUP']) process.on(sig, () => { motifArret = `signal ${sig}`; process.exit(0); });
  journal(`démarrage : PID ${process.pid}, port ${port}${TERM ? ', terminal' : ''}`);
  console.log(`VibeFlow: ${u}`);
  console.log(cli
    ? `asking via ${ENGINES[engine].name} ${version || ''} (${cli.path})${model ? `, model ${model}` : ''}`
    : `${ENGINES[want].name} not found: the map works, but asking questions needs it (${ENGINES[want].site}). Pass --${want} <path> if it is installed somewhere unusual.`);
  if (!has('no-open')) {
    const opener = process.platform === 'win32' ? ['cmd', ['/c', 'start', '', u]] : process.platform === 'darwin' ? ['open', [u]] : ['xdg-open', [u]];
    try { spawn(opener[0], opener[1], { stdio: 'ignore', detached: true }).unref(); } catch {}
  }
});
