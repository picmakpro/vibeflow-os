// vf-cockpit-paths — résolution des chemins du socle du cockpit (P67-D-12). Lecture seule.
// Exports : findLabRoot, planningLayout, stateFile, resolveScriptsDir, trustedScriptsDir, driverLockScript,
//           engineDir, outputDir, resoudreBinaire, pathAssaini, gitCommonDir, confiner, verifierSortie, realUnder,
//           GIT_SUR (préfixe d'arguments de tout appel git), avecEcheance(ms, fn) et shBorne(cmd, args, cwd) (sous-processus bornés, échéance globale : F-06),
//           envGit / lancerGit / filtresDeclares / configFiltres / argsGit / OPTIONS_LECTURE / SOUS_COMMANDES_FILTRANTES / GIT_HERITE (environnement git unique, P78-D-25).
// Aucun nom de compartiment, de jalon ou de projet codé en dur : tout vient du disque.
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync, execFile } from 'node:child_process';
import { envEnfant } from './vf-cockpit-env.mjs';
import { gitSortant } from './vf-cockpit-git-sortant.mjs';

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
// --no-optional-locks : `git status` ne réécrit pas .git/index (l'émetteur est en lecture seule, audit F-5)
export const GIT_SUR = ['--no-optional-locks', '-c', 'core.fsmonitor=false'];

// ---- Environnement git unique (GITC-13, P78-D-21, D-22, D-25) : tout git du socle passe par `shBorne` ou `lancerGit`, donc par ce seul point ----
// Un enfant git ne reçoit AUCUNE variable GIT_* héritée (GIT_DIR l'emporte sur `-C` : un dépôt leurre détourne la lecture) ; fsmonitor et verrous optionnels sont réglés par
// l'environnement (GIT_CONFIG_COUNT), ce qui couvre aussi un enfant qui ne reçoit pas nos arguments (le moteur d'assemblage). GIT_SUR reste en arguments (défense en profondeur).
export const GIT_HERITE = /^GIT_/i;
export function envGit(lab, { env = process.env, config = [] } = {}) {
  const e = {};
  for (const [k, v] of Object.entries(envEnfant(lab, env))) if (!GIT_HERITE.test(k)) e[k] = v;
  const paires = [['core.fsmonitor', 'false'], ...config];
  e.GIT_OPTIONAL_LOCKS = '0'; e.GIT_CONFIG_COUNT = String(paires.length);
  paires.forEach(([k, v], i) => { e[`GIT_CONFIG_KEY_${i}`] = k; e[`GIT_CONFIG_VALUE_${i}`] = v; });
  e.VF_COCKPIT_GIT_DURCI = '1'; // lu par la garde du moteur (plan 78-07)
  return e;
}
// `--no-ext-diff --no-textconv` se placent APRÈS la sous-commande (options de la sous-commande, pas de git : `git --no-ext-diff log` rend 129). L'environnement retire GIT_CONFIG_GLOBAL, la
// config de l'utilisateur s'applique : `log.showSignature=true` ajouterait la sortie gpg et désalignerait les parseurs, d'où `--no-show-signature` (que `diff-tree` refuse).
// A2 (audit 2026-11-06) : `status` et `diff` ne descendent JAMAIS dans les sous-modules. Sinon git relance un `status` dans chaque sous-module, avec la configuration de `.git/modules/<n>/config`
// et SANS les filtres vidés par l'environnement (git retire GIT_CONFIG_COUNT/KEY/VALUE de l'environnement des processus de sous-module) : un filtre déclaré là s'exécuterait. Contrepartie : l'état modifié
// d'un sous-module n'est plus compté (il n'est pas lu, pas « propre » : simplement ignoré).
export const IGNORER_SOUS_MODULES = '--ignore-submodules=all';
export const OPTIONS_LECTURE = { log: ['--no-ext-diff', '--no-textconv', '--no-show-signature'], show: ['--no-ext-diff', '--no-textconv', '--no-show-signature'], 'diff-tree': ['--no-ext-diff', '--no-textconv'],
  diff: ['--no-ext-diff', '--no-textconv', IGNORER_SOUS_MODULES], status: [IGNORER_SOUS_MODULES] };
export const SOUS_COMMANDES_FILTRANTES = ['status', 'diff', 'ls-files', 'stash']; // sous-commandes qui relisent le contenu d'un fichier suivi (filtres clean/process du dépôt)
// repère la sous-commande après les options globales (--no-optional-locks, -c <v>, -C <dir>) et y insère les options de lecture
export function argsGit(args) {
  let i = 0, dir = null;
  while (i < args.length && String(args[i]).startsWith('-')) { if (args[i] === '-C') dir = args[i + 1]; i += args[i] === '-c' || args[i] === '-C' ? 2 : 1; }
  const sous = args[i], ins = OPTIONS_LECTURE[sous] || [];
  return { argv: [...args.slice(0, i + 1), ...ins, ...args.slice(i + 1)], sous, dir };
}

// Échéance globale (F-06) : `avecEcheance(ms, fn)` pose une date butoir pour tout appel de `shBorne` exécuté pendant `fn` ; passée la date, `shBorne` ne lance plus rien et rend ''
// (sortie vide : chaque appelant en tire sa valeur « inconnu », null, jamais 0). Chaque appel reste borné à 10 s, et au temps restant s'il est plus court.
let FIN = null;
export function avecEcheance(ms, fn) {
  const avant = FIN; FIN = Date.now() + ms;
  try { return fn(); } finally { FIN = avant; }
}
// exécuteur interne unique (shBorne, lancerGit, filtresDeclares) : échéance respectée, jamais `timeout: 0` ; rend { sortie, code, tronque (ENOBUFS), absent (ENOENT), echeance }
function lancer(cmd, args, cwd, env, maxBuffer) {
  const reste = FIN === null ? 10000 : Math.min(10000, FIN - Date.now());
  if (!(reste >= 1)) return { sortie: '', code: null, tronque: false, absent: false, echeance: true, delai: true }; // échéance atteinte (ou valeur non numérique) : rien n'est lancé
  try { return { sortie: execFileSync(cmd, args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], timeout: Math.floor(reste), env, maxBuffer }), code: 0, tronque: false, absent: false, echeance: false, delai: false }; }
  catch (e) { return { sortie: e.stdout || '', code: typeof e.status === 'number' ? e.status : null, tronque: e.code === 'ENOBUFS', absent: e.code === 'ENOENT', echeance: false, delai: e.code === 'ETIMEDOUT' }; } // delai : le processus n'a pas répondu à temps (tué)
}
// Variante ASYNCHRONE de l'exécuteur (P78-D-32) : mêmes options, même environnement, même sémantique de résultat que `lancer`, mais la boucle du serveur reste libre pendant que git travaille.
// L'échéance globale `FIN` est une variable de portée synchrone : elle ne survit pas à un `await`. L'appelant asynchrone passe donc sa date butoir (`fin`, en ms epoch) à chaque appel.
export const finDans = (ms) => Date.now() + ms;
function lancerAsync(cmd, args, cwd, env, maxBuffer, fin) {
  const reste = Math.min(10000, (fin ?? Date.now() + 10000) - Date.now());
  if (!(reste >= 1)) return Promise.resolve({ sortie: '', code: null, tronque: false, absent: false, echeance: true, delai: true });
  return new Promise((resolve) => {
    let enfant;
    try {
      enfant = execFile(cmd, args, { cwd, encoding: 'utf8', timeout: Math.floor(reste), env, maxBuffer }, (e, sortie) => {
        if (!e) return resolve({ sortie, code: 0, tronque: false, absent: false, echeance: false, delai: false });
        resolve({ sortie: sortie || '', code: typeof e.code === 'number' ? e.code : null, tronque: e.code === 'ERR_CHILD_PROCESS_STDIO_MAXBUFFER' || e.code === 'ENOBUFS', absent: e.code === 'ENOENT', echeance: false, delai: e.killed === true });
      });
      enfant.stdin?.end(); // l'exécuteur synchrone ferme l'entrée standard (stdio 'ignore')
    } catch { resolve({ sortie: '', code: null, tronque: false, absent: true, echeance: false, delai: false }); }
  });
}
// A1 (audit 2026-11-06) : AUCUN filtre déclaré n'est exécuté, quel que soit leur nombre. La liste n'est donc jamais tronquée. La seule borne est celle de l'environnement transmis à git (4 paires par filtre) :
// au-delà de MAX_FILTRES, `status`/`diff`/`ls-files`/`stash` ne sont PAS lancés (refus : ok=false, sortie vide, comptes « inconnus » chez l'appelant), jamais « le reste n'est pas vidé ».
// Même refus quand la liste elle-même n'est pas lisible (git config en échec, tronquée, hors délai) : un filtre inconnu n'est pas un filtre absent.
export const MAX_FILTRES = 256;
const motifFiltre = /^filter\.(.+)\.[^.]+$/;
const lireFiltres = (r) => ({ noms: [...new Set(r.sortie.split('\n').map((l) => motifFiltre.exec(l.trim())?.[1]).filter(Boolean))],
  fiable: !r.echeance && !r.tronque && !r.absent && (r.code === 0 || r.code === 1) }); // git config --get-regexp : 0 = trouvé, 1 = aucun filtre ; tout autre code = liste inconnue
const argsFiltres = (dir) => [...GIT_SUR, '-C', dir, 'config', '--name-only', '--get-regexp', '^filter\\.'];
const refus = (noms, fiable) => !fiable || noms.length > MAX_FILTRES;
export async function filtresDeclaresAsync(dir, lab = dir, fin) {
  return lireFiltres(await lancerAsync('git', argsFiltres(dir), dir, envGit(lab), 1 << 20, fin)).noms;
}
// R6 (revue serveur 2026-11-06, S9) : l'état des filtres pour un lancement qui ne passe pas par lancerGit (le moteur d'assemblage, vf-cockpit-build.mjs) : mêmes règles que A1.
// { noms, fiable (liste lue), refus (liste illisible ou au-delà de MAX_FILTRES : rien de ce qui pourrait exécuter un filtre ne se lance) }
export function filtresEtat(dir, lab = dir) {
  const f = lireFiltres(lancer('git', argsFiltres(dir), dir, envGit(lab), 1 << 20));
  return { noms: f.noms, fiable: f.fiable, refus: refus(f.noms, f.fiable) };
}
// pilotes de filtre déclarés par le dépôt (et la config de l'utilisateur) : `filter.<x>.<clé>`, x = tout ce qui sépare le premier `filter.` de la dernière `.clé`
export function filtresDeclares(dir, lab = dir) {
  return lireFiltres(lancer('git', argsFiltres(dir), dir, envGit(lab), 1 << 20)).noms;
}
// chaque pilote vidé, par paires clé/valeur de GIT_CONFIG_* : clean, smudge, process vides et required=false (status rend 0 et n'exécute rien, mesuré)
export const configFiltres = (noms) => noms.flatMap((x) => [['clean', ''], ['smudge', ''], ['process', ''], ['required', 'false']].map(([k, v]) => [`filter.${x}.${k}`, v]));
// Seul point de lancement des sous-processus du socle (git, bash driver-lock.sh) : un processus bloqué ne gèle pas la boucle, le total ne dépasse pas l'échéance.
// L'environnement de l'enfant a un PATH assaini (H-1, vf-cockpit-env.mjs) : `lab` (par défaut `cwd`) est le dossier dont aucun élément ne doit rester dans le PATH.
// Pour `git` : envGit (GIT_* retirés), options de lecture insérées, filtres du dépôt vidés pour les sous-commandes filtrantes.
export function shBorne(cmd, args, cwd, lab = cwd) {
  if (cmd !== 'git') return lancer(cmd, args, cwd, envEnfant(lab), 1 << 20).sortie;
  const { argv, sous, dir } = argsGit(args), base = dir ? path.resolve(cwd || '.', dir) : cwd || process.cwd();
  if (gitSortant(base, lab)) return ''; // AUDC-A-02 : point central — un .git qui désigne un dossier git hors du lab n'est jamais lu (lancerGit et lancerGitAsync de même)
  let config = [];
  if (SOUS_COMMANDES_FILTRANTES.includes(sous)) {
    const f = lireFiltres(lancer('git', argsFiltres(base), base, envGit(lab), 1 << 20));
    if (refus(f.noms, f.fiable)) return ''; // A1 : filtres en nombre ou en état indéterminable, rien n'est lancé
    config = configFiltres(f.noms);
  }
  return lancer('git', argv, cwd, envGit(lab, { config }), 1 << 20).sortie;
}

// lecture git bornée pour les modules du socle (tiroir Git, plans 78-05 et 78-08) : GIT_SUR et `-C dir` posés ici, même exécuteur et même échéance que shBorne.
// { ok (code 0 sans sortie tronquée, sans échéance), sortie, code, tronque (ENOBUFS : sortie partielle, jamais présentée comme complète), absent (ENOENT) } ; `binaire` ne sert qu'aux tests, jamais lu d'une variable d'environnement.
export function lancerGit(dir, args, { lab = dir, maxBuffer = 4 << 20, binaire = 'git' } = {}) {
  if (!isDir(dir)) return { ok: false, sortie: '', code: null, tronque: false, absent: false, delai: false };
  if (gitSortant(dir, lab)) return { ok: false, sortie: '', code: null, tronque: false, absent: false, delai: false, refuse: true }; // AUDC-A-02 : voir shBorne
  const { argv, sous } = argsGit([...GIT_SUR, '-C', dir, ...args]);
  let config = [];
  if (SOUS_COMMANDES_FILTRANTES.includes(sous)) {
    const f = lireFiltres(lancer('git', argsFiltres(dir), dir, envGit(lab), 1 << 20));
    if (refus(f.noms, f.fiable)) return { ok: false, sortie: '', code: null, tronque: false, absent: false, delai: f.fiable ? false : true, refuse: true }; // A1 : jamais lancé
    config = configFiltres(f.noms);
  }
  const r = lancer(binaire, argv, dir, envGit(lab, { config }), maxBuffer);
  return { ok: r.code === 0 && !r.tronque && !r.echeance, sortie: r.sortie, code: r.code, tronque: r.tronque, absent: r.absent, delai: r.delai };
}

// Même contrat et mêmes arguments que `lancerGit`, rendu en promesse ; `fin` : date butoir de l'appelant (voir `finDans`).
export async function lancerGitAsync(dir, args, { lab = dir, maxBuffer = 4 << 20, binaire = 'git', fin } = {}) {
  if (!isDir(dir)) return { ok: false, sortie: '', code: null, tronque: false, absent: false, delai: false };
  if (gitSortant(dir, lab)) return { ok: false, sortie: '', code: null, tronque: false, absent: false, delai: false, refuse: true }; // AUDC-A-02 : voir shBorne
  const { argv, sous } = argsGit([...GIT_SUR, '-C', dir, ...args]);
  let config = [];
  if (SOUS_COMMANDES_FILTRANTES.includes(sous)) {
    const f = lireFiltres(await lancerAsync('git', argsFiltres(dir), dir, envGit(lab), 1 << 20, fin));
    if (refus(f.noms, f.fiable)) return { ok: false, sortie: '', code: null, tronque: false, absent: false, delai: f.fiable ? false : true, refuse: true };
    config = configFiltres(f.noms);
  }
  const r = await lancerAsync(binaire, argv, dir, envGit(lab, { config }), maxBuffer, fin);
  return { ok: r.code === 0 && !r.tronque && !r.echeance, sortie: r.sortie, code: r.code, tronque: r.tronque, absent: r.absent, delai: r.delai };
}

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
