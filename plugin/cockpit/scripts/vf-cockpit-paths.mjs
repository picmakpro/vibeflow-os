// vf-cockpit-paths — résolution des chemins du socle du cockpit (P67-D-12). Lecture seule.
// Exports : findLabRoot, planningLayout, stateFile, resolveScriptsDir, driverLockScript,
//           engineDir, outputDir, gitCommonDir.
// Aucun nom de compartiment, de jalon ou de projet codé en dur : tout vient du disque.
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const isDir = (p) => { try { return fs.statSync(p).isDirectory(); } catch { return false; } };
const isFile = (p) => { try { return fs.statSync(p).isFile(); } catch { return false; } };
const ls = (d) => { try { return fs.readdirSync(d); } catch { return []; } };

// premier ancêtre portant un dossier .planning, sinon null
export function findLabRoot(start) {
  let d = path.resolve(start || '.');
  for (;;) {
    if (isDir(path.join(d, '.planning'))) return d;
    const up = path.dirname(d);
    if (up === d) return null;
    d = up;
  }
}

// forme 'plat' | 'partitionne' | 'absent' ; compartiments énumérés sur le disque, triés
export function planningLayout(root) {
  const base = path.join(root, '.planning');
  if (!isDir(base)) return { forme: 'absent', actif: null, compartiments: [] };
  const wsRoot = path.join(base, 'workstreams');
  const compartiments = ls(wsRoot).sort()
    .filter((w) => isFile(path.join(wsRoot, w, 'ROADMAP.md')))
    .map((w) => ({ ws: w, dir: path.join(wsRoot, w) }));
  if (!compartiments.length) return { forme: 'plat', actif: null, compartiments: [{ ws: null, dir: base }] };
  let actif = null;
  try {
    const nom = fs.readFileSync(path.join(base, 'active-workstream'), 'utf8').trim();
    if (compartiments.some((c) => c.ws === nom)) actif = nom;
  } catch {}
  if (!actif && compartiments.length === 1) actif = compartiments[0].ws;
  return { forme: 'partitionne', actif, compartiments };
}

// STATE du compartiment actif (ou .planning/STATE.md en plat), sinon null
export function stateFile(root, layout) {
  const l = layout || planningLayout(root);
  let f = null;
  if (l.forme === 'plat') f = path.join(root, '.planning', 'STATE.md');
  else if (l.forme === 'partitionne' && l.actif) f = path.join(root, '.planning', 'workstreams', l.actif, 'STATE.md');
  return f && isFile(f) ? f : null;
}

// dossier des scripts : champ scriptsDir de <here>/.cache/vf-cockpit.json s'il pointe un dossier, sinon here
export function resolveScriptsDir(here) {
  try {
    const j = JSON.parse(fs.readFileSync(path.join(here, '.cache', 'vf-cockpit.json'), 'utf8'));
    if (j && typeof j.scriptsDir === 'string' && isDir(j.scriptsDir)) return j.scriptsDir;
  } catch {}
  return here;
}

// T-67-06 : jamais un script pris sous <labRoot>/plugin/ (arbre observé, potentiellement piégé)
export function driverLockScript({ scriptsDir, labRoot, home } = {}) {
  const cands = [];
  if (scriptsDir) cands.push(path.join(scriptsDir, 'driver-lock.sh'));
  if (labRoot) cands.push(path.join(labRoot, '.claude', 'scripts', 'driver-lock.sh'));
  if (home) cands.push(path.join(home, '.claude', 'scripts', 'driver-lock.sh'));
  const plugin = labRoot ? path.resolve(labRoot, 'plugin') + path.sep : null;
  for (const c of cands) {
    if (plugin && path.resolve(c).startsWith(plugin)) continue;
    if (isFile(c)) return { chemin: c, etat: 'trouve' };
  }
  return { chemin: null, etat: 'absent' };
}

// scripts/ et skills/ sont frères sous TARGET_ROOT (dépôt et trois scopes)
export function engineDir(scriptsDir) {
  const d = path.resolve(scriptsDir, '..', 'skills', 'cockpit-moteur');
  const ok = isFile(path.join(d, 'VENDORED.txt')) && isFile(path.join(d, 'assets', 'viewer.html'));
  return { chemin: ok ? d : null, etat: ok ? 'trouve' : 'absent' };
}

export const outputDir = (labRoot) => path.join(labRoot, '.vibeflow', 'cockpit');

export function gitCommonDir(root) {
  try {
    const out = execFileSync('git', ['-C', root, 'rev-parse', '--path-format=absolute', '--git-common-dir'],
      { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
    return out || null;
  } catch { return null; }
}
