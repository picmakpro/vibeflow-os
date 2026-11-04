// vf-cockpit-paths — résolution des chemins du socle du cockpit (P67-D-12). Lecture seule.
// Exports : findLabRoot, planningLayout, stateFile, resolveScriptsDir, trustedScriptsDir, driverLockScript,
//           engineDir, outputDir, gitCommonDir, confiner, verifierSortie, realUnder,
//           GIT_SUR (préfixe d'arguments de tout appel git), avecEcheance(ms, fn) et shBorne(cmd, args, cwd) (sous-processus bornés, échéance globale : F-06).
// Aucun nom de compartiment, de jalon ou de projet codé en dur : tout vient du disque.
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { envEnfant } from './vf-cockpit-env.mjs';

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
    const pf = path.join(base, 'active-workstream'); const st = fs.statSync(pf); // jamais un fichier non régulier ni démesuré (un lien vers /dev/zero ne finit pas)
    const nom = st.isFile() && st.size <= 4096 ? fs.readFileSync(pf, 'utf8').trim() : '';
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

// dossier des scripts du MODULE : VF_COCKPIT_SCRIPTS_DIR (posé par le lanceur) s'il pointe un dossier, sinon <here>. Le serveur,
// lui, ne se fie qu'à trustedScriptsDir() : un .cache/ ou un dossier du lab ne désigne jamais un dossier de scripts (67-SECURITY M3).
export function resolveScriptsDir(here) {
  return trustedScriptsDir() || here;
}
export function trustedScriptsDir() {
  const e = process.env.VF_COCKPIT_SCRIPTS_DIR;
  return e && path.isAbsolute(e) && isDir(e) ? e : null;
}

const real = (p) => { try { return fs.realpathSync(p); } catch { return path.resolve(p); } };
export const realUnder = (p, dir) => { const r = real(p), d = real(dir); return r === d || r.startsWith(d + path.sep); };

// T-67-06 : jamais un script pris dans l'arbre observé. Comparaison sur realpath (un lien `.claude/scripts -> plugin/x` ne passe pas) :
// aucun candidat sous le lab, sauf le dossier de scripts du module (posé par le lanceur) s'il n'est pas dans la sortie .vibeflow/ du lab.
export function driverLockScript({ scriptsDir, labRoot, home } = {}) {
  const sortie = labRoot ? path.join(labRoot, '.vibeflow') : null;
  const cands = [];
  if (scriptsDir) cands.push({ c: path.join(scriptsDir, 'driver-lock.sh'), module: true });
  // le conductor voisin du module (…/plugin/cockpit/scripts -> …/plugin/conductor/scripts) passe avant la copie installée, qui peut dater d'avant
  // les verrous par phase (recette 69) ; cherché seulement depuis un dossier nommé …/cockpit/scripts, jamais depuis un dossier de scripts quelconque
  if (scriptsDir && path.basename(scriptsDir) === 'scripts' && path.basename(path.dirname(scriptsDir)) === 'cockpit') cands.push({ c: path.join(scriptsDir, '..', '..', 'conductor', 'scripts', 'driver-lock.sh'), module: true });
  if (home) cands.push({ c: path.join(home, '.claude', 'scripts', 'driver-lock.sh'), module: false });
  for (const { c, module } of cands) {
    if (!isFile(c)) continue;
    if (labRoot && module && sortie && realUnder(c, sortie)) continue;
    if (labRoot && !module && realUnder(c, labRoot)) continue;
    return { chemin: c, etat: 'trouve' };
  }
  return { chemin: null, etat: 'absent' };
}

// garde partagée (67-SECURITY M4) : <sortie> ne doit être, ni lui ni aucun de ses fichiers, un lien symbolique sortant du lab.
// confiner(lab, cible) : cible dans le lab par realpath ; refuse un lien symbolique ou un fichier qui en sort. Lève sinon.
export function confiner(lab, cible) {
  let st = null; try { st = fs.lstatSync(cible); } catch {}
  if (st?.isSymbolicLink()) throw Object.assign(new Error(`lien symbolique refusé dans la sortie du cockpit : ${cible}`), { code: 4 });
  const parent = real(path.dirname(cible));
  const racine = real(lab);
  if (parent !== racine && !parent.startsWith(racine + path.sep)) throw Object.assign(new Error(`écriture hors du lab refusée : ${cible}`), { code: 4 });
  return cible;
}

// verifierSortie(lab, sortie) : la sortie est sous le lab (realpath) et aucun de ses éléments n'est un lien symbolique ; lève sinon.
export function verifierSortie(lab, sortie) {
  const racine = real(lab);
  const r = real(sortie);
  if (r !== racine && !r.startsWith(racine + path.sep)) throw Object.assign(new Error(`sortie du cockpit hors du lab : ${sortie}`), { code: 4 });
  const marche = (d) => {
    for (const e of ls(d)) {
      const p = path.join(d, e);
      let st; try { st = fs.lstatSync(p); } catch { continue; }
      if (st.isSymbolicLink()) throw Object.assign(new Error(`lien symbolique refusé dans la sortie du cockpit : ${p}`), { code: 4 });
      if (st.isDirectory()) marche(p);
    }
  };
  if (fs.lstatSync(sortie).isSymbolicLink()) throw Object.assign(new Error(`lien symbolique refusé : ${sortie}`), { code: 4 });
  marche(sortie);
}

// scripts/ et skills/ sont frères sous TARGET_ROOT (dépôt et trois scopes)
export function engineDir(scriptsDir) {
  const d = path.resolve(scriptsDir, '..', 'skills', 'cockpit-moteur');
  const ok = isFile(path.join(d, 'VENDORED.txt')) && isFile(path.join(d, 'assets', 'viewer.html'));
  return { chemin: ok ? d : null, etat: ok ? 'trouve' : 'absent' };
}

export const outputDir = (labRoot) => path.join(labRoot, '.vibeflow', 'cockpit');

// un `.git/config` écrit par d'autres peut déclarer un core.fsmonitor exécutable : chaque appel git du socle commence par ce préfixe (T-68-04, F-03)
export const GIT_SUR = ['-c', 'core.fsmonitor=false'];

// Échéance globale (F-06) : `avecEcheance(ms, fn)` pose une date butoir pour tout appel de `shBorne` exécuté pendant `fn` ; passée la date, `shBorne` ne lance plus rien et rend ''
// (sortie vide : chaque appelant en tire sa valeur « inconnu », null, jamais 0). Chaque appel reste borné à 10 s, et au temps restant s'il est plus court.
let FIN = null;
export function avecEcheance(ms, fn) {
  const avant = FIN; FIN = Date.now() + ms;
  try { return fn(); } finally { FIN = avant; }
}
// Seul point de lancement des sous-processus du socle (git, bash driver-lock.sh) : un processus bloqué ne gèle pas la boucle, le total ne dépasse pas l'échéance.
// L'environnement de l'enfant a un PATH assaini (H-1, vf-cockpit-env.mjs) : `lab` (par défaut `cwd`) est le dossier dont aucun élément ne doit rester dans le PATH.
export function shBorne(cmd, args, cwd, lab = cwd) {
  const reste = FIN === null ? 10000 : Math.min(10000, FIN - Date.now());
  if (!(reste >= 1)) return ''; // échéance atteinte (ou valeur non numérique) : rien n'est lancé ; jamais `timeout: 0`, qui voudrait dire « sans limite »
  try { return execFileSync(cmd, args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], timeout: Math.floor(reste), env: envEnfant(lab) }); } catch (e) { return e.stdout || ''; }
}

export function gitCommonDir(root) {
  return shBorne('git', [...GIT_SUR, '-C', root, 'rev-parse', '--path-format=absolute', '--git-common-dir'], undefined, root).trim() || null;
}
