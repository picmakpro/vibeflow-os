#!/usr/bin/env node
// Orchestrateur de test mobile — module VibeFlow `mobile-test`.
//
// Partie MÉCANIQUE et déterministe du pipeline. La couche jugement (diagnostic
// visuel via mobile-mcp sur échec, rédaction du rapport) est portée par l'agent
// et le skill `vf-mobile-test`, pas par ce script.
//
// Sous-commandes :
//   detect
//     -> imprime en JSON les cibles bootées (simulateurs iOS + émulateurs Android).
//        N'ouvre ni ne boote rien. L'agent lit et décide la cible (demande si ambigu).
//
//   run --platform <ios|android> [--target <udid|serial>] [--stamp <YYYY-MM-DD-HHMM>]
//       [--skip-build] [--keep-metro] [--config <path>]
//     -> résout le bundle id, boote la cible si besoin, build/install l'app si absente,
//        joue la régression Maestro, collecte les artefacts, scaffolde le rapport,
//        et imprime un JSON { platform, target, results[], artifactDir, reportPath }.
//
// Aucune valeur machine/projet n'est codée en dur : tout vient d'un fichier de config
// résolu en cascade (voir resolveConfigPath). Copier `config/mobile-test.example.json`.

import { execFileSync, spawn } from 'node:child_process';
import { readFileSync, mkdirSync, writeFileSync, existsSync, openSync } from 'node:fs';
import { join } from 'node:path';

const ROOT = process.cwd();

// --- résolution de config (portable, sans chemin machine en dur) ------------

/** Résout le fichier de config en cascade :
 *  --config <path>  >  $VF_MOBILE_TEST_CONFIG  >  ./.vibeflow/mobile-test.json  >  ./mobile-test.json.
 *  Renvoie le premier chemin existant, ou null. */
function resolveConfigPath(explicit) {
  const candidates = [];
  if (explicit) candidates.push(explicit.replace(/^~/, process.env.HOME || ''));
  if (process.env.VF_MOBILE_TEST_CONFIG) candidates.push(process.env.VF_MOBILE_TEST_CONFIG);
  candidates.push(join(ROOT, '.vibeflow', 'mobile-test.json'));
  candidates.push(join(ROOT, 'mobile-test.json'));
  for (const c of candidates) if (c && existsSync(c)) return c;
  return null;
}

// --- utilitaires ------------------------------------------------------------

function loadConfig(explicit) {
  const path = resolveConfigPath(explicit);
  if (!path) {
    fail(
      'Config introuvable. Cherché (dans l\'ordre) : --config <path>, $VF_MOBILE_TEST_CONFIG, ' +
      './.vibeflow/mobile-test.json, ./mobile-test.json.\n' +
      'Copie le template du module (config/mobile-test.example.json) vers ' +
      './.vibeflow/mobile-test.json et renseigne bundleIdBase, android.avdName, ios.preferredSimulator, etc.'
    );
  }
  return JSON.parse(readFileSync(path, 'utf8'));
}

/** Exécute une commande, renvoie stdout (string) ou null si échec. */
function run(cmd, args, opts = {}) {
  try {
    return execFileSync(cmd, args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], ...opts });
  } catch {
    return null;
  }
}

/** Sleep synchrone (le script est séquentiel, pas d'event loop async ici). */
function sleepSync(ms) {
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
}

/** Lance une commande détachée (chef de groupe de process), sortie -> logPath.
 *  Renvoie le pid. Sert à démarrer Metro / expo run sans bloquer le script. */
function spawnDetached(cmd, args, logPath) {
  const out = openSync(logPath, 'a');
  const child = spawn(cmd, args, { detached: true, stdio: ['ignore', out, out] });
  child.unref();
  return child.pid;
}

/** Tue le groupe de process d'un pid détaché (Metro + ses enfants). */
function killGroup(pid) {
  try { process.kill(-pid, 'SIGTERM'); }
  catch { try { process.kill(pid, 'SIGTERM'); } catch { /* déjà mort */ } }
}

/** Metro répond-il ? (le dev build a besoin de Metro pour charger le JS) */
function metroUp(cfg) {
  const port = cfg.metroPort || 8081;
  const code = run('curl', ['-s', '-o', '/dev/null', '-w', '%{http_code}', `http://localhost:${port}/status`]);
  return !!(code && code.trim() === '200');
}

function fail(msg) {
  console.error('Erreur : ' + msg);
  process.exit(1);
}

function parseArgs(argv) {
  const out = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith('--')) {
      const key = a.slice(2);
      const next = argv[i + 1];
      if (next && !next.startsWith('--')) { out[key] = next; i++; }
      else out[key] = true;
    } else out._.push(a);
  }
  return out;
}

function pad(n) { return String(n).padStart(2, '0'); }
function defaultStamp() {
  const d = new Date();
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}-${pad(d.getHours())}${pad(d.getMinutes())}`;
}

// --- détection des cibles ---------------------------------------------------

function detectIos() {
  const out = run('xcrun', ['simctl', 'list', 'devices', 'booted', '--json']);
  if (!out) return [];
  let data;
  try { data = JSON.parse(out); } catch { return []; }
  const res = [];
  for (const runtime of Object.keys(data.devices || {})) {
    for (const dev of data.devices[runtime]) {
      if (dev.state === 'Booted') res.push({ udid: dev.udid, name: dev.name, state: dev.state });
    }
  }
  return res;
}

function detectAndroid() {
  const out = run('adb', ['devices']);
  if (!out) return [];
  const res = [];
  for (const line of out.split('\n').slice(1)) {
    const m = line.match(/^(\S+)\s+device$/);
    if (!m) continue;
    const serial = m[1];
    const avdOut = run('adb', ['-s', serial, 'emu', 'avd', 'name']);
    const avd = avdOut ? avdOut.split('\n')[0].trim() : null;
    res.push({ serial, avd });
  }
  return res;
}

function cmdDetect() {
  console.log(JSON.stringify({ ios: detectIos(), android: detectAndroid() }, null, 2));
}

// --- boot / install / régression -------------------------------------------

function ensureIosTarget(cfg, target) {
  let booted = detectIos();
  if (target) {
    const found = booted.find((d) => d.udid === target);
    if (found) return found;
  }
  if (booted.length > 0) return booted[0];
  // aucun sim booté : booter le préféré
  const name = cfg.ios?.preferredSimulator;
  if (!name) fail('Aucun simulateur iOS booté et ios.preferredSimulator absent de la config.');
  const listOut = run('xcrun', ['simctl', 'list', 'devices', 'available', '--json']);
  const data = listOut ? JSON.parse(listOut) : { devices: {} };
  let udid = null;
  for (const rt of Object.keys(data.devices || {})) {
    const hit = data.devices[rt].find((d) => d.name === name);
    if (hit) { udid = hit.udid; break; }
  }
  if (!udid) fail(`Simulateur "${name}" introuvable (xcrun simctl list).`);
  run('xcrun', ['simctl', 'boot', udid]);
  run('xcrun', ['simctl', 'bootstatus', udid, '-b']);
  return { udid, name, state: 'Booted' };
}

function ensureAndroidTarget(cfg, target) {
  let booted = detectAndroid();
  if (target) {
    const found = booted.find((d) => d.serial === target);
    if (found) return found;
  }
  if (booted.length > 0) return booted[0];
  // aucun émulateur booté : à lancer manuellement (processus long, détaché).
  const avd = cfg.android?.avdName;
  fail(`Aucun émulateur Android booté. Lance-le d'abord :\n  emulator -avd ${avd || '<avdName>'}\npuis relance run --platform android.`);
}

function isInstalledIos(udid, bundleId) {
  return run('xcrun', ['simctl', 'get_app_container', udid, bundleId]) !== null;
}

function isInstalledAndroid(serial, bundleId) {
  const out = run('adb', ['-s', serial, 'shell', 'pm', 'path', bundleId]);
  return !!(out && out.includes('package:'));
}

/** Build + install + démarre Metro, en DÉTACHÉ (expo run ne rend jamais la main :
 *  il garde Metro au premier plan). Renvoie le pid à nettoyer en fin de run. */
function buildInstall(platform, target, logPath) {
  const device = platform === 'ios' ? target.udid : target.serial;
  console.error(`App absente : build/install via expo run:${platform} --device ${device} en arrière-plan (Metro inclus, plusieurs minutes). Log : ${logPath}`);
  return spawnDetached('npx', ['expo', `run:${platform}`, '--device', device], logPath);
}

/** Attend que l'app apparaisse installée (poll), jusqu'à un timeout généreux (build long). */
function waitForInstall(platform, target, bundleId) {
  const deadline = Date.now() + 20 * 60 * 1000; // 20 min
  while (Date.now() < deadline) {
    sleepSync(5000);
    const ok = platform === 'ios'
      ? isInstalledIos(target.udid, bundleId)
      : isInstalledAndroid(target.serial, bundleId);
    if (ok) { console.error('App installée.'); return; }
  }
  fail('Timeout : app non installée après 20 min de build.');
}

/** S'assure que Metro tourne. Ne démarre rien si déjà up (ne touche pas un Metro
 *  lancé par ailleurs). Renvoie le pid démarré, ou null. */
function ensureMetro(cfg, logPath) {
  if (metroUp(cfg)) return null;
  console.error('Metro non détecté : démarrage (npx expo start) en arrière-plan...');
  const pid = spawnDetached('npx', ['expo', 'start'], logPath);
  const deadline = Date.now() + 180000; // 3 min
  while (Date.now() < deadline) {
    sleepSync(3000);
    if (metroUp(cfg)) { console.error('Metro prêt.'); return pid; }
  }
  fail('Metro ne répond pas après 3 min.');
}

/** Résout le binaire maestro : config.maestroBin, puis ~/.maestro/bin/maestro,
 *  puis "maestro" sur le PATH en dernier recours. Le PATH d'un shell non
 *  interactif n'inclut pas toujours ~/.maestro/bin. */
function resolveMaestro(cfg) {
  const home = process.env.HOME || '';
  const candidates = [];
  if (cfg.maestroBin) candidates.push(cfg.maestroBin.replace(/^~/, home));
  if (home) candidates.push(join(home, '.maestro', 'bin', 'maestro'));
  for (const c of candidates) if (existsSync(c)) return c;
  return 'maestro';
}

/** Résout JAVA_HOME requis par Maestro : $JAVA_HOME, config.javaHome,
 *  /usr/libexec/java_home, puis openjdk@17 homebrew. Le shell non interactif
 *  n'exporte pas toujours JAVA_HOME. Renvoie null si rien trouvé (Maestro
 *  tentera java sur le PATH). */
function resolveJavaHome(cfg) {
  const home = process.env.HOME || '';
  const candidates = [];
  if (process.env.JAVA_HOME) candidates.push(process.env.JAVA_HOME);
  if (cfg.javaHome) candidates.push(cfg.javaHome.replace(/^~/, home));
  const jh = run('/usr/libexec/java_home', ['-v', '17']);
  if (jh && jh.trim()) candidates.push(jh.trim());
  candidates.push('/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home');
  candidates.push('/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home');
  for (const c of candidates) if (c && existsSync(join(c, 'bin', 'java'))) return c;
  return null;
}

/** Parse un JUnit Maestro (sans dépendance XML). */
function parseJunit(xmlPath) {
  if (!existsSync(xmlPath)) return [];
  const xml = readFileSync(xmlPath, 'utf8');
  const results = [];
  const caseRe = /<testcase\b([^>]*)>([\s\S]*?)<\/testcase>|<testcase\b([^>]*)\/>/g;
  let m;
  while ((m = caseRe.exec(xml)) !== null) {
    const attrs = m[1] || m[3] || '';
    const body = m[2] || '';
    const name = (attrs.match(/name="([^"]*)"/) || [])[1] || 'unknown';
    const time = parseFloat((attrs.match(/time="([^"]*)"/) || [])[1] || '0');
    const failed = /<failure|<error/.test(body);
    results.push({ flow: name, status: failed ? 'fail' : 'pass', durationMs: Math.round(time * 1000) });
  }
  return results;
}

function scaffoldReport(cfg, { platform, target, results, artifactDir, reportPath, bundleId, freshBuild }) {
  const commit = (run('git', ['rev-parse', '--short', 'HEAD']) || 'inconnu').trim();
  const targetLabel = platform === 'ios' ? `${target.name} (${target.udid})` : `${target.avd || target.serial} (${target.serial})`;
  const rows = results.map((r) => `| ${r.flow} | ${r.status === 'pass' ? 'PASS' : 'FAIL'} | ${r.durationMs} ms |`).join('\n');
  const failures = results.filter((r) => r.status === 'fail');
  const failSections = failures.length
    ? failures.map((r) => `### Échec : ${r.flow}\n\n- Erreur Maestro : voir \`maestro-junit.xml\`\n- Diagnostic mobile-mcp : _(à compléter par l'agent : cause probable, écran, artefacts avant/après)_\n- Artefacts : _(liens vers ${r.flow}-before.png / ${r.flow}-after.png / logs)_`).join('\n\n')
    : '_Aucun échec._';

  const md = `# Rapport de test mobile : ${platform} (${cfg.__stamp})

- Date : ${cfg.__stamp}
- Plateforme : ${platform}
- Cible : ${targetLabel}
- Bundle id : ${bundleId}
- Build : ${freshBuild ? 'fraîchement buildé (expo run)' : 'déjà installé'}
- Commit : ${commit}

## Récapitulatif

| Flow | Résultat | Durée |
|------|----------|-------|
${rows || '| _(aucun flow)_ | - | - |'}

## Échecs

${failSections}

## Artefacts

Dossier : \`${artifactDir}\`
- \`maestro-junit.xml\` (sortie Maestro brute)
`;
  writeFileSync(reportPath, md);
}

function cmdRun(args) {
  const cfg = loadConfig(args.config);
  const platform = args.platform;
  if (platform !== 'ios' && platform !== 'android') fail('run exige --platform ios|android');

  const stamp = args.stamp || defaultStamp();
  cfg.__stamp = stamp;
  const bundleId = `${cfg.bundleIdBase}${cfg.debugSuffix || ''}`;

  // 1. cible
  const target = platform === 'ios'
    ? ensureIosTarget(cfg, args.target)
    : ensureAndroidTarget(cfg, args.target);

  // artefacts (créés tôt pour y logger le build)
  const reportsDir = join(ROOT, cfg.reportsDir || 'test-runs');
  const artifactDir = join(reportsDir, stamp);
  mkdirSync(artifactDir, { recursive: true });
  const junitPath = join(artifactDir, 'maestro-junit.xml');
  const reportPath = join(reportsDir, `${stamp}.md`);
  const expoLog = join(artifactDir, 'expo.log');

  const spawnedPids = [];
  let freshBuild = false;
  try {
    // 2. install / build + Metro (le dev build a besoin de Metro pour charger le JS)
    const installed = platform === 'ios'
      ? isInstalledIos(target.udid, bundleId)
      : isInstalledAndroid(target.serial, bundleId);

    if (!installed && args['skip-build']) {
      fail(`App ${bundleId} absente et --skip-build fourni : rien à tester.`);
    }
    if (!installed) {
      const pid = buildInstall(platform, target, expoLog); // démarre aussi Metro
      if (pid) spawnedPids.push(pid);
      freshBuild = true;
      waitForInstall(platform, target, bundleId);
      const deadline = Date.now() + 120000;
      while (!metroUp(cfg) && Date.now() < deadline) sleepSync(3000);
    } else {
      const pid = ensureMetro(cfg, expoLog);
      if (pid) spawnedPids.push(pid);
    }

    // 3. régression Maestro
    const flowsDir = join(ROOT, cfg.maestroFlowsDir || '.maestro');
    const maestroBin = resolveMaestro(cfg);
    const javaHome = resolveJavaHome(cfg);
    const env = { ...process.env };
    if (javaHome) {
      env.JAVA_HOME = javaHome;
      env.PATH = `${join(javaHome, 'bin')}:${process.env.PATH || ''}`;
    } else {
      console.error('Attention : JAVA_HOME introuvable, Maestro peut échouer (requiert un JDK).');
    }
    console.error(`Régression Maestro (${maestroBin}, JAVA_HOME=${javaHome || 'PATH'}) sur ${flowsDir} ...`);
    runInheritSafe(maestroBin, ['test', flowsDir, '--format', 'junit', '--output', junitPath], { env });

    // 4. parse + rapport + sortie
    const results = parseJunit(junitPath);
    scaffoldReport(cfg, { platform, target, results, artifactDir, reportPath, bundleId, freshBuild });
    console.log(JSON.stringify({ platform, target, results, artifactDir, reportPath }, null, 2));
  } finally {
    if (spawnedPids.length && !args['keep-metro']) {
      for (const pid of spawnedPids) killGroup(pid);
      console.error('Metro/expo arrêté (process démarrés par le script).');
    } else if (spawnedPids.length) {
      console.error(`Metro laissé actif (--keep-metro), pids : ${spawnedPids.join(', ')}`);
    }
  }
}

/** Comme runLoud mais ne throw pas : Maestro sort non-zéro si un flow échoue,
 *  ce qui est un résultat légitime (pas une erreur d'orchestration). */
function runInheritSafe(cmd, args, opts = {}) {
  try { execFileSync(cmd, args, { stdio: 'inherit', ...opts }); } catch { /* échec de flow = normal */ }
}

// --- entrée -----------------------------------------------------------------

const argv = process.argv.slice(2);
const sub = argv[0];
const args = parseArgs(argv.slice(1));

switch (sub) {
  case 'detect': cmdDetect(); break;
  case 'run': cmdRun(args); break;
  default:
    console.error('Usage :\n  mobile-test-run.mjs detect\n  mobile-test-run.mjs run --platform <ios|android> [--target <id>] [--stamp <YYYY-MM-DD-HHMM>] [--skip-build] [--keep-metro] [--config <path>]');
    process.exit(1);
}
