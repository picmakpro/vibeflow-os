// vf-cockpit-git-lanceur — lancement borné de git et des enfants du socle (extrait de vf-cockpit-paths.mjs, P79-D-25, plan 79-07).
// Exports : GIT_SUR (préfixe d'arguments de tout appel git), GIT_HERITE, envGit (environnement git unique, P78-D-25), OPTIONS_LECTURE,
//           SOUS_COMMANDES_FILTRANTES, argsGit, avecEcheance(ms, fn), finDans(ms), MAX_FILTRES, filtresDeclares, filtresDeclaresAsync,
//           filtresEtat, configFiltres, shBorne(cmd, args, cwd), lancerGit, lancerGitAsync.
// Importé et ré-exporté par vf-cockpit-paths.mjs (aucun consommateur ne change d'import).
// N'importe aucun module local autre que env, git-sortant et git-durci : aucun cycle.
// Ancres de test : test-cockpit-git-env.sh (E7, E9) et test-cockpit-git-details.sh mutent des copies de CE fichier par substitution
// de la première occurrence d'une ligne de code : elles doivent rester présentes à l'identique, une seule fois, dans le code
// (jamais citées en commentaire, la substitution toucherait le commentaire).
// Seul point de lancement des sous-processus du socle : la garde de test-cockpit-git-env.sh (E6)
// n'admet child_process que dans les modules de sa liste blanche.
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync, execFile } from 'node:child_process';
import { envEnfant } from './vf-cockpit-env.mjs';
import { gitSortant } from './vf-cockpit-git-sortant.mjs';
import { DURCISSEMENT_CONFIG, DURCISSEMENT_ENV } from './vf-cockpit-git-durci.mjs';

const isDir = (p) => { try { return fs.statSync(p).isDirectory(); } catch { return false; } };

// un `.git/config` écrit par d'autres peut déclarer un core.fsmonitor exécutable : chaque appel git du socle commence par ce préfixe (T-68-04, F-03)
// --no-optional-locks : `git status` ne réécrit pas .git/index (l'émetteur est en lecture seule, audit F-5)
export const GIT_SUR = ['--no-optional-locks', '-c', 'core.fsmonitor=false'];

// ---- Environnement git unique (GITC-13, P78-D-21, D-22, D-25) : tout git du socle passe par `shBorne` ou `lancerGit`, donc par ce seul point ----
// Un enfant git ne reçoit AUCUNE variable GIT_* héritée (GIT_DIR l'emporte sur `-C` : un dépôt leurre détourne la lecture) ; fsmonitor et verrous optionnels sont réglés par
// l'environnement (GIT_CONFIG_COUNT), ce qui couvre aussi un enfant qui ne reçoit pas nos arguments (le moteur d'assemblage). GIT_SUR reste en arguments (défense en profondeur).
export const GIT_HERITE = /^GIT_/i;
// AUDC-A-04 : la classe « une option de configuration du dépôt désigne un programme ou ouvre le réseau pendant une lecture » est fermée par vf-cockpit-git-durci.mjs (portée « commande » + environnement).
export function envGit(lab, { env = process.env, config = [] } = {}) {
  const e = {};
  for (const [k, v] of Object.entries(envEnfant(lab, env))) if (!GIT_HERITE.test(k)) e[k] = v;
  const paires = [...DURCISSEMENT_CONFIG, ...config];
  Object.assign(e, DURCISSEMENT_ENV); e.GIT_CONFIG_COUNT = String(paires.length);
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
  const { argv, sous, dir } = argsGit(args), cour = cwd || process.cwd();
  // -C jugé tel quel par gitSortant, sans normalisation lexicale
  const base = dir ? (path.isAbsolute(dir) ? dir : cour + path.sep + dir) : cour;
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
