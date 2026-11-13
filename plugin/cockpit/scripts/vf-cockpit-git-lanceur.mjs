// vf-cockpit-git-lanceur — lancement borné de git et des enfants du socle (extrait de vf-cockpit-paths.mjs, P79-D-25, plan 79-07).
// Exports : GIT_SUR (préfixe d'arguments de tout appel git), GIT_HERITE, envGit (environnement git unique, P78-D-25), OPTIONS_LECTURE,
//           argsGit, avecEcheance(ms, fn), finDans(ms), MAX_FILTRES, PILOTES_TTL_MS, filtresDeclares, filtresDeclaresAsync, filtresEtat,
//           configFiltres, shBorne(cmd, args, cwd), lancerGit, lancerGitAsync.
// A-04 (79-07) : pilotes nommés vidés pour tout lancement, liste fermée de sous-commandes (vf-cockpit-git-durci.mjs), enfants non git sous envGit.
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
import { DURCISSEMENT_CONFIG, DURCISSEMENT_ENV, SOUS_COMMANDES_AUTORISEES, PILOTES_NOMMES } from './vf-cockpit-git-durci.mjs';

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
// A-04 (79-07) : TOUS les pilotes nommés déclarés (filter.*, diff.*.textconv, diff.*.command, merge.*.driver) sont lus puis vidés par l'environnement,
// pour tout lancement de git et quelle que soit la sous-commande. Unité : `filter.<nom>` (quatre clés), ou la clé elle-même (diff, merge : une clé).
// AUCUN pilote déclaré n'est exécuté, quel que soit leur nombre : la liste n'est jamais tronquée. La seule borne est celle de l'environnement transmis
// à git : au-delà de MAX_FILTRES unités, rien n'est lancé (refus : sortie vide, comptes « inconnus » chez l'appelant), jamais « le reste n'est pas vidé ».
// Même refus quand la liste n'est pas lisible (git config en échec, tronquée, hors délai) : un pilote inconnu n'est pas un pilote absent.
export const MAX_FILTRES = 256;
const motifFiltre = /^filter\.(.*)\.[^.]+$/;
const motifDiff = /^diff\..*\.(textconv|command)$/;
const motifFusion = /^merge\..*\.driver$/;
const unite = (cle) => {
  const f = motifFiltre.exec(cle);
  return f ? `filter.${f[1]}` : motifDiff.test(cle) || motifFusion.test(cle) ? cle : null;
};
// un nom de pilote peut être vide (clé `filter..clean`) ; une clé listée que l'analyse ne comprend pas rend la liste non fiable (refus)
// --get-regexp : code 0 = trouvé, 1 = aucun ; autre code = liste inconnue
// git absent (ENOENT à la lecture) : `absent` est propagé, le refus ne se dit pas « délai » (enteteGit : « absent », pas « indisponible »)
const lirePilotes = (r) => {
  const us = r.sortie.split('\n').map((l) => l.trim()).filter(Boolean).map(unite);
  const lue = !r.echeance && !r.tronque && !r.absent && (r.code === 0 || r.code === 1);
  return { unites: [...new Set(us.filter(Boolean))], fiable: lue && us.every(Boolean), absent: r.absent };
};
const argsPilotes = (dir) => [...GIT_SUR, '-C', dir, 'config', '--name-only', '--get-regexp', PILOTES_NOMMES];
const refus = (noms, fiable) => !fiable || noms.length > MAX_FILTRES;
const nomsFiltres = (unites) => unites.filter((u) => u.startsWith('filter.')).map((u) => u.slice('filter.'.length));
export async function filtresDeclaresAsync(dir, lab = dir, fin) {
  return nomsFiltres(lirePilotes(await lancerAsync('git', argsPilotes(dir), dir, envGit(lab), 1 << 20, fin)).unites);
}
// R6 (revue serveur 2026-11-06, S9) : l'état des pilotes pour un lancement qui ne passe pas par lancerGit
// (le moteur d'assemblage, vf-cockpit-build.mjs) : mêmes règles.
// { noms (toutes les unités), fiable (liste lue), refus (liste illisible ou au-delà de MAX_FILTRES : rien de ce qui pourrait exécuter un pilote ne se lance) }
export function filtresEtat(dir, lab = dir) {
  const f = lirePilotes(lancer('git', argsPilotes(dir), dir, envGit(lab), 1 << 20));
  return { noms: f.unites, fiable: f.fiable, refus: refus(f.unites, f.fiable) };
}
// noms des filtres déclarés par le dépôt (et la config de l'utilisateur) : `filter.<x>.<clé>`,
// x = tout ce qui sépare le premier `filter.` de la dernière `.clé`
export function filtresDeclares(dir, lab = dir) {
  return nomsFiltres(lirePilotes(lancer('git', argsPilotes(dir), dir, envGit(lab), 1 << 20)).unites);
}
// chaque pilote vidé, par paires clé/valeur de GIT_CONFIG_* : filtre = clean, smudge, process vides et required=false
// (status rend 0 et n'exécute rien, mesuré) ; diff.<n>.textconv, diff.<n>.command et merge.<n>.driver : une paire à valeur vide
const PAIRES_FILTRE = [['clean', ''], ['smudge', ''], ['process', ''], ['required', 'false']];
export const configFiltres = (noms) =>
  noms.flatMap((u) => (u.startsWith('filter.') ? PAIRES_FILTRE.map(([k, v]) => [`${u}.${k}`, v]) : [[u, '']]));
// Mémo de la lecture des pilotes (une lecture coûte autant qu'un lancement) : un seul pour le synchrone et l'asynchrone,
// par couple dossier et lab, jamais pour une liste illisible.
// Limite écrite et testée (D6.5) : un pilote déclaré dans les PILOTES_TTL_MS qui suivent une lecture n'est pas vidé
// pour les lancements de la fenêtre ; restent fermés alors la liste fermée des sous-commandes,
// `--no-ext-diff --no-textconv` sur celles qui comparent, et l'absence de toute sous-commande qui lancerait un pilote de fusion.
export const PILOTES_TTL_MS = 2000;
const MEMO = new Map();
const cleMemo = (dir, lab) => `${dir}\0${lab}`;
function memoLu(cle) {
  const m = MEMO.get(cle);
  return m && Date.now() - m.t < PILOTES_TTL_MS ? m.p : null;
}
function memoPose(cle, p) {
  if (p.fiable) MEMO.set(cle, { t: Date.now(), p });
  return p;
}
const pilotes = (dir, lab) => memoLu(cleMemo(dir, lab)) ?? memoPose(cleMemo(dir, lab), lirePilotes(lancer('git', argsPilotes(dir), dir, envGit(lab), 1 << 20)));
async function pilotesAsync(dir, lab, fin) {
  const c = cleMemo(dir, lab), m = memoLu(c);
  return m ?? memoPose(c, lirePilotes(await lancerAsync('git', argsPilotes(dir), dir, envGit(lab), 1 << 20, fin)));
}
const REFUS_GIT = { ok: false, sortie: '', code: null, tronque: false, absent: false, delai: false, refuse: true };
const autorisee = (sous) => SOUS_COMMANDES_AUTORISEES.includes(sous);
// Seul point de lancement des sous-processus du socle (git, bash driver-lock.sh) : un processus bloqué ne gèle pas la boucle, le total ne dépasse pas l'échéance.
// L'environnement de l'enfant a un PATH assaini (H-1, vf-cockpit-env.mjs) : `lab` (par défaut `cwd`) est le dossier dont aucun élément ne doit rester dans le PATH.
// Pour `git` : sous-commande hors de la liste fermée refusée (sortie vide), envGit (GIT_* retirés),
// options de lecture insérées, tous les pilotes du dépôt vidés.
// Pour tout autre enfant (bash driver-lock.sh, qui appelle git) : envGit(lab) aussi, donc aucun GIT_* hérité (SOCL-11, T-79-706).
export function shBorne(cmd, args, cwd, lab = cwd) {
  // AUDC-A-02 : l'enfant (bash driver-lock.sh) lance son propre git ; un lab dont le .git désigne un dépôt hors du lab ne le voit jamais
  // (sortie vide, comme un git refusé)
  if (cmd !== 'git' && gitSortant(lab || cwd || process.cwd(), lab || cwd || process.cwd())) return ''; // garde:lanceur-enfant-sortant
  if (cmd !== 'git') return lancer(cmd, args, cwd, envGit(lab), 1 << 20).sortie;
  const { argv, sous, dir } = argsGit(args), cour = cwd || process.cwd();
  // -C jugé tel quel par gitSortant, sans normalisation lexicale
  const base = dir ? (path.isAbsolute(dir) ? dir : cour + path.sep + dir) : cour;
  if (!autorisee(sous)) return ''; // A-04 : liste fermée (un alias déclaré par le dépôt n'est pas un nom de la liste)
  if (gitSortant(base, lab)) return ''; // AUDC-A-02 : point central — un .git qui désigne un dossier git hors du lab n'est jamais lu (lancerGit et lancerGitAsync de même)
  const p = pilotes(base, lab);
  if (refus(p.unites, p.fiable)) return ''; // A1 : pilotes en nombre ou en état indéterminable, rien n'est lancé
  return lancer('git', argv, cwd, envGit(lab, { config: configFiltres(p.unites) }), 1 << 20).sortie;
}

// lecture git bornée pour les modules du socle (tiroir Git, plans 78-05 et 78-08) : GIT_SUR et `-C dir` posés ici, même exécuteur et même échéance que shBorne.
// { ok (code 0 sans sortie tronquée, sans échéance), sortie, code, tronque (ENOBUFS : sortie partielle, jamais présentée comme complète), absent (ENOENT) } ; `binaire` ne sert qu'aux tests, jamais lu d'une variable d'environnement.
export function lancerGit(dir, args, { lab = dir, maxBuffer = 4 << 20, binaire = 'git' } = {}) {
  if (!isDir(dir)) return { ok: false, sortie: '', code: null, tronque: false, absent: false, delai: false };
  const { argv, sous } = argsGit([...GIT_SUR, '-C', dir, ...args]);
  if (!autorisee(sous)) return { ...REFUS_GIT }; // A-04 : liste fermée
  if (gitSortant(dir, lab)) return { ...REFUS_GIT }; // AUDC-A-02 : voir shBorne
  const p = pilotes(dir, lab);
  if (refus(p.unites, p.fiable)) return { ...REFUS_GIT, absent: p.absent, delai: !p.fiable && !p.absent }; // A1 : jamais lancé
  const r = lancer(binaire, argv, dir, envGit(lab, { config: configFiltres(p.unites) }), maxBuffer);
  return { ok: r.code === 0 && !r.tronque && !r.echeance, sortie: r.sortie, code: r.code, tronque: r.tronque, absent: r.absent, delai: r.delai };
}

// Même contrat et mêmes arguments que `lancerGit`, rendu en promesse ; `fin` : date butoir de l'appelant (voir `finDans`).
export async function lancerGitAsync(dir, args, { lab = dir, maxBuffer = 4 << 20, binaire = 'git', fin } = {}) {
  if (!isDir(dir)) return { ok: false, sortie: '', code: null, tronque: false, absent: false, delai: false };
  const { argv, sous } = argsGit([...GIT_SUR, '-C', dir, ...args]);
  if (!autorisee(sous)) return { ...REFUS_GIT };
  if (gitSortant(dir, lab)) return { ...REFUS_GIT }; // AUDC-A-02 : voir shBorne
  const p = await pilotesAsync(dir, lab, fin);
  if (refus(p.unites, p.fiable)) return { ...REFUS_GIT, absent: p.absent, delai: !p.fiable && !p.absent };
  const r = await lancerAsync(binaire, argv, dir, envGit(lab, { config: configFiltres(p.unites) }), maxBuffer, fin);
  return { ok: r.code === 0 && !r.tronque && !r.echeance, sortie: r.sortie, code: r.code, tronque: r.tronque, absent: r.absent, delai: r.delai };
}
