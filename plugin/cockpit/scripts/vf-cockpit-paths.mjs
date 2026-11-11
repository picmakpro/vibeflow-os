// vf-cockpit-paths — résolution des chemins du socle du cockpit (P67-D-12). Lecture seule.
// Exports : findLabRoot, planningLayout, stateFile, resolveScriptsDir, trustedScriptsDir, driverLockScript,
//           engineDir, outputDir, resoudreBinaire, pathAssaini, gitCommonDir, confiner, verifierSortie, realUnder,
//           + tout vf-cockpit-git-lanceur.mjs, ré-exporté (P79-D-25) : GIT_SUR, avecEcheance, shBorne, envGit, lancerGit, lancerGitAsync,
//             filtresDeclares, configFiltres, argsGit, OPTIONS_LECTURE, GIT_HERITE…
// Aucun nom de compartiment, de jalon ou de projet codé en dur : tout vient du disque.
import fs from 'node:fs';
import path from 'node:path';
import { shBorne, GIT_SUR } from './vf-cockpit-git-lanceur.mjs';
import { cheminPhysique } from './vf-cockpit-git-sortant.mjs';
export * from './vf-cockpit-git-lanceur.mjs'; // lancement borné de git (P79-D-25) : tous les noms déplacés restent importables d'ici

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
    const pf = path.join(base, 'active-workstream'); if (!realUnder(pf, root)) throw 0; const st = fs.statSync(pf); // AUDC-A-02 : un pointeur lié hors du lab est ignoré comme absent
    // jamais un fichier non régulier ni démesuré (un lien vers /dev/zero ne finit pas)
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

// SOCL-10 : un chemin n'est jugé que par sa résolution physique (cheminPhysique) ; un échec rend `siEchec` (faux : « pas dedans », pour les gardes
// de lecture ; vrai pour les appelants de polarité inverse, qui écartent un candidat quand il est dedans). Le dossier peut être encore absent :
// il ne contient alors rien.
export const realUnder = (p, dir, { siEchec = false } = {}) => {
  const r = cheminPhysique(p), d = cheminPhysique(dir, { plusProcheParent: true });
  return r === null || d === null ? siEchec : r === d || r.startsWith(d + path.sep);
};
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
    if (labRoot && module && sortie && realUnder(c, sortie, { siEchec: true })) continue;
    if (labRoot && !module && realUnder(c, labRoot, { siEchec: true })) continue;
    return { chemin: c, etat: 'trouve' };
  }
  return { chemin: null, etat: 'absent' };
}

// garde partagée (67-SECURITY M4) : <sortie> ne doit être, ni lui ni aucun de ses fichiers, un lien symbolique sortant du lab.
// confiner(lab, cible) : le plus proche parent existant de la cible est dans le lab (résolution physique) ; refuse un lien symbolique ou un fichier
// qui en sort. Lève sinon.
export function confiner(lab, cible) {
  let st = null; try { st = fs.lstatSync(cible); } catch {}
  if (st?.isSymbolicLink()) throw Object.assign(new Error(`lien symbolique refusé dans la sortie du cockpit : ${cible}`), { code: 4 });
  const parent = cheminPhysique(path.dirname(cible), { plusProcheParent: true }), racine = cheminPhysique(lab);
  if (parent === null || racine === null || (parent !== racine && !parent.startsWith(racine + path.sep))) {
    throw Object.assign(new Error(`écriture hors du lab refusée : ${cible}`), { code: 4 });
  }
  return cible;
}

// verifierSortie(lab, sortie) : la sortie est sous le lab (résolution physique) et aucun de ses éléments n'est un lien symbolique ; lève sinon.
export function verifierSortie(lab, sortie) {
  const racine = cheminPhysique(lab), r = cheminPhysique(sortie);
  if (racine === null || r === null || (r !== racine && !r.startsWith(racine + path.sep))) {
    throw Object.assign(new Error(`sortie du cockpit hors du lab : ${sortie}`), { code: 4 });
  }
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

// P71-D-29 (N2) : le lanceur s'exécute depuis la racine du lab. Un binaire lancé par son NOM est cherché par le système dans le PATH, où « . », un élément
// vide (« : » en tête ou en queue) ou relatif désigne le lab : il exécuterait un `open`, un `ps` ou un `git` posé là. Le lanceur ne lance donc jamais un nom nu :
// il résout le binaire dans les seuls éléments ABSOLUS du PATH (sans toucher au PATH, que les enfants, shell du terminal compris, reçoivent tel quel : P71-D-03)
// et lance son chemin absolu. Introuvable : null, jamais un repli sur la résolution par le cwd. Sous Windows, CreateProcess cherche d'abord le cwd : `cmd` est résolu
// par ComSpec / SystemRoot, les autres par les éléments absolus du PATH (.exe).
// Pour les enfants du lanceur qui ne sont PAS le shell de l'utilisateur (le moteur d'assemblage) : même PATH sans ses éléments relatifs ou vides, afin que leurs
// propres `git` à nom nu ne cherchent plus dans le lab. Jamais passé au shell du terminal (P71-D-03).
// N8 : un PATH assaini VIDE n'est jamais rendu tel quel. Node transmet alors `PATH=''` à l'enfant et libuv le lit comme le cwd, c'est-à-dire le lab : le `git` à nom nu du moteur
// y serait exécuté (PATH absent, `env -i`, ou PATH entièrement relatif). On rend donc un PATH système ABSOLU par défaut, /usr/bin:/bin : il porte `git` sous macOS et Linux, et
// ne désigne que des dossiers du système. Sous Windows aucun défaut POSIX ne vaut : '' signale « omettre la clé » (envMoteur, vf-cockpit-build.mjs).
export const PATH_SYSTEME = '/usr/bin:/bin';
export const pathAssaini = (pathVar = process.env.PATH) => {
  const p = String(pathVar || '').split(path.delimiter).filter((d) => d && path.isAbsolute(d)).join(path.delimiter);
  return p || (process.platform === 'win32' ? '' : PATH_SYSTEME);
};
export function resoudreBinaire(nom, pathVar = process.env.PATH) {
  if (process.platform === 'win32') {
    if (nom === 'cmd') {
      const c = process.env.ComSpec || (process.env.SystemRoot ? path.join(process.env.SystemRoot, 'System32', 'cmd.exe') : '');
      return c && path.isAbsolute(c) ? c : null;
    }
  }
  // Aucun élément absolu (PATH absent, vide ou entièrement relatif) : repli sur les répertoires système, comme H-1 (PATH_REPLI) et N8 ; jamais sur le cwd.
  const absolus = String(pathVar || '').split(path.delimiter).filter((d) => d && path.isAbsolute(d));
  for (const d of absolus.length || process.platform === 'win32' ? absolus : PATH_SYSTEME.split(':')) {
    const c = path.join(d, process.platform === 'win32' ? `${nom}.exe` : nom);
    try { if (fs.statSync(c).isFile()) { fs.accessSync(c, fs.constants.X_OK); return c; } } catch {}
  }
  return null;
}

export function gitCommonDir(root) {
  return shBorne('git', [...GIT_SUR, '-C', root, 'rev-parse', '--path-format=absolute', '--git-common-dir'], undefined, root).trim() || null;
}
