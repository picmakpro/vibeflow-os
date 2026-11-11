// vf-cockpit-git-sortant — git lirait-il, pour ce dossier, autre chose que le dépôt du lab ? (AUDC-A-02, socle du cockpit.) Lecture seule, fs seul, aucun git.
// Exports : cheminPhysique(chemin, { plusProcheParent = false } = {}) -> chaîne absolue résolue par le noyau, ou null (SOCL-10, P79-D-11 : la SEULE règle
// de résolution du socle et du moteur ;
//   interface de 79-13, figée par G17) ; gitSortant(dir, racineLab = dir) -> booléen (point central des lanceurs git de vf-cockpit-git-lanceur.mjs).
//   Copie octet pour octet dans le moteur : lib/vf-git-sortant.mjs.
// Règle à point fixe, sans liste de membres ni d'exclusion : git n'est lancé sur un dépôt que si
//  (1) son dossier git (G) et son dossier commun (C, `commondir` de G) RÉSOLUS PHYSIQUEMENT sont dans la racine réelle du lab, ou désignent le lab en
//      retour : worktree vérifié
//      (<C>/worktrees/<x>, dont `gitdir` = ce `.git` et dont le commun est <C>), sous-module dont `core.worktree` résout vers ce dossier ;
//  (2) AUCUN lien symbolique sous G ni sous C (parcours complet, borné : refus au-delà de NMAX entrées) ne résout hors de sa racine : le verdict est celui
//      du noyau sur le lien lui-même
//      (realpath natif), jamais celui de sa cible écrite. Un lien qui ne résout pas (pendant, boucle, droits) est sortant. Seule exception, la forme exacte
//      du verrou de pilotage
//      de VibeFlow, quand il est PENDANT : un lien `DRIVER.lock` sous `vf-driver/`, de cible `DRIVER.lock.gen.<n>.<n>` absente (driver-lock.sh : génération
//      en cours de publication) ;
//  (3) pas d'`objects/info/alternates` ; `core.worktree` (config, config.worktree, inclusions suivies) absent ou désignant ce dossier ; une inclusion de
//      configuration (`include.path`,
//      `includeIf.<condition>.path`) n'est permise que si son fichier, résolu physiquement, est dans le lab ou dans le dossier git, et ses propres
//      inclusions sont suivies (profondeur bornée).
// Valeurs de gitdir, commondir, core.worktree et include : jugées par la même fonction. Sinon le git de ce dépôt est ignoré.
// Limites résiduelles : la course entre le contrôle et la lecture (un maillon intermédiaire remplacé) ; une chaîne qui traverse un élément extérieur puis
// retombe dedans est jugée sur son
// résultat présent ; la configuration globale et système, qui relève de l'environnement des lancements git (envGit) ; un dépôt --separate-git-dir sans lien
// retour est ignoré.
// Coût : un parcours par dossier, mis en cache par date de modification du dossier (jamais pour un dossier modifié depuis moins de 2 s) ; le cache ne garde
// que la STRUCTURE d'un dossier,
// le verdict de chaque lien est recalculé à chaque appel (un maillon intermédiaire change sans modifier le dossier du lien).
import fs from 'node:fs';
import path from 'node:path';

const natif = (p) => fs.realpathSync.native(p); // le SEUL appel au realpath natif du fichier : resolution du noyau, `..` compris
const joindre = (base, valeur) => (path.isAbsolute(valeur) ? valeur : base + path.sep + valeur); // aucune normalisation : le noyau résout
const dans = (p, d) => p === d || p.startsWith(d + path.sep);
const petit = (f) => { const st = fs.statSync(f); if (!st.isFile() || st.size > 65536) throw new Error('fichier git inattendu'); return fs.readFileSync(f, 'utf8'); };
const NMAX = 500000;

// Chemin absolu physique de `chemin`, ou null. Strict : tout échec rend null, jamais la forme écrite. Un chemin relatif est pris au dossier courant, sans
// normalisation.
// plusProcheParent : cible d'un fichier ou d'un dossier à créer ou supprimé ; sur ENOENT seulement, remonte au plus proche parent qui se résout et ajoute
// le reste du nom.
// null si le reste contient `.` ou `..`, ou si un élément existant ne se résout pas (lien pendant, boucle, droits, ENOTDIR). Le chemin rendu reste interne
// : jamais émis tel quel.
export function cheminPhysique(chemin, { plusProcheParent = false } = {}) {
  if (typeof chemin !== 'string' || chemin === '' || chemin.includes('\0')) return null;
  const abs = joindre(process.cwd(), chemin);
  try { return natif(abs); } catch (e) { if (!plusProcheParent || e.code !== 'ENOENT') return null; }
  const reste = [];
  for (let cur = abs; ;) {
    try { fs.lstatSync(cur); return null; } catch (e) { if (e.code !== 'ENOENT') return null; } // l'entrée existe sans se résoudre : lien pendant ou en boucle
    const nom = path.basename(cur), haut = path.dirname(cur);
    if (nom === '..' || nom === '.' || nom === '' || haut === cur) return null;
    reste.unshift(nom); cur = haut;
    try { return path.join(natif(cur), ...reste); } catch (e) { if (e.code !== 'ENOENT') return null; }
  }
}

const VERROU = /^vf-driver(?:\/[^/]+)*\/DRIVER\.lock$/;
// la forme exacte du verrou de pilotage, pendant : emplacement, cible `DRIVER.lock.gen.<n>.<n>` (sans barre oblique), cible absente (lstat ENOENT : jamais
// une boucle ni un refus de droits)
function verrouPilotage(lien, rel) {
  if (!VERROU.test(rel.split(path.sep).join('/'))) return false;
  let cible; try { cible = fs.readlinkSync(lien); } catch { return false; }
  if (!/^DRIVER\.lock\.gen\.\d+\.\d+$/.test(cible)) return false;
  try { fs.lstatSync(joindre(path.dirname(lien), cible)); return false; } catch (e) { return e.code === 'ENOENT'; }
}
// un lien sous la racine : sa résolution physique est dans la racine ; sinon seule la forme du verrou de pilotage, pendant, est tolérée
function lienDedans(lien, racine) {
  const r = cheminPhysique(lien);
  return r === null ? verrouPilotage(lien, lien.slice(racine.length + 1)) : dans(r, racine);
}
// g\0dossier -> { m, at, liens, subs, n } : la structure d'un dossier (ses entrées directes), valable tant que sa date de modification est la même
// et plus ancienne que le parcours de 2 s
const cache = new Map();
// vrai si aucun lien sous d ne sort de racine ; bud.v compte les entrées vues
function sansLienSortant(d, racine, bud) {
  let st; try { st = fs.lstatSync(d, { bigint: true }); } catch (e) { return e.code === 'ENOENT'; }
  if (!st.isDirectory()) return !st.isSymbolicLink();
  const k = racine + '\0' + d; let c = cache.get(k);
  if (!c || c.m !== st.mtimeNs || c.at - Number(st.mtimeMs) < 2000) {
    c = { m: st.mtimeNs, at: Date.now(), liens: [], subs: [], n: 0 };
    const es = fs.readdirSync(d, { withFileTypes: true }); c.n = es.length;
    for (const e of es) { if (e.isSymbolicLink()) c.liens.push(path.join(d, e.name)); else if (e.isDirectory()) c.subs.push(path.join(d, e.name)); }
    cache.set(k, c);
  }
  bud.v += c.n;
  return bud.v <= NMAX && c.liens.every((l) => lienDedans(l, racine)) && c.subs.every((s) => sansLienSortant(s, racine, bud));
}
// core.worktree d'un fichier de configuration et des inclusions qu'il suit : la liste des chemins physiques (null pour une valeur qui ne se résout pas) ;
// null si une inclusion sort du lab et du dossier git, ne se résout pas, ou est trop profonde
function worktrees(f, g, racine, prof = 0) {
  let t; try { const st = fs.statSync(f); if (!st.isFile()) return []; /* tube, périphérique : aucun core.worktree ni inclusion à y lire (git, lui, est borné par ses échéances) */ t = petit(f); } catch (e) { if (e.code === 'ENOENT') return []; throw e; }
  const out = []; let sec = '';
  for (const l of t.split(/\r?\n/)) {
    const h = /^\s*\[\s*([A-Za-z0-9.-]*)[^\]]*\](.*)$/.exec(l), reste = h ? h[2] : l;
    if (h) sec = h[1].toLowerCase();
    const w = sec === 'core' && /^\s*worktree\s*=\s*(.+?)\s*$/i.exec(reste);
    if (w) out.push(cheminPhysique(joindre(g, w[1]), { plusProcheParent: true }));
    const i = (sec === 'include' || sec === 'includeif') && /^\s*path\s*=\s*(.+?)\s*$/i.exec(reste);
    if (i) {
      const cible = cheminPhysique(joindre(path.dirname(f), i[1].replace(/^"(.*)"$/, '$1')), { plusProcheParent: true });
      if (i[1].startsWith('~') || prof > 8 || cible === null || !(dans(cible, racine) || dans(cible, g))) return null;
      const r = worktrees(cible, g, racine, prof + 1); if (r === null) return null; out.push(...r);
    }
  }
  return out;
}
const coreWorktree = (g, racine) => { const a = worktrees(path.join(g, 'config'), g, racine), b = worktrees(path.join(g, 'config.worktree'), g, racine); return a === null || b === null ? null : [...a, ...b]; };
// (2) et (3) pour un dossier git ou commun. `libre` : dossier d'un worktree vérifié (git ignore le core.worktree du commun) ; `dirP` : le dossier du lab,
// physique
function sain(g, dirP, racine, libre, bud) {
  if (!sansLienSortant(g, g, bud)) return false;
  if (['alternates', 'http-alternates'].some((a) => fs.existsSync(path.join(g, 'objects', 'info', a)))) return false;
  const w = coreWorktree(g, racine);
  return w !== null && (libre || w.every((x) => x === dirP));
}
export function gitSortant(dir, racineLab = dir) {
  const dotgit = path.join(dir, '.git'); let st;
  try { st = fs.lstatSync(dotgit); } catch { return false; }
  const racine = cheminPhysique(racineLab), dirP = cheminPhysique(dir); // le lab : un dépôt imbriqué ou un sous-module du lab reste lu
  if (racine === null || dirP === null) return true;
  const dedans = (p) => dans(p, racine);
  try {
    let g, gitfile = false;
    if (st.isSymbolicLink()) { g = cheminPhysique(dotgit); if (g === null || !dedans(g)) return true; gitfile = fs.statSync(g).isFile(); }
    else if (st.isDirectory()) g = cheminPhysique(dotgit);
    else if (st.isFile()) { g = dotgit; gitfile = true; }
    else return true;
    if (g === null) return true;
    if (gitfile) {
      const m = /^gitdir:\s*(.+)$/m.exec(petit(g)); if (!m) return true;
      g = cheminPhysique(joindre(dirP, m[1].trim())); if (g === null) return true;
    }
    let c = g, cd = null; // dossier commun : fichier absent = le dossier git ; présent mais non résoluble = refus
    try { cd = petit(path.join(g, 'commondir')).trim(); } catch (e) { if (e.code !== 'ENOENT') return true; }
    if (cd !== null) { c = cheminPhysique(joindre(g, cd)); if (c === null) return true; }
    let libre = false;
    if (!(dedans(g) && dedans(c))) {
      if (dedans(g)) return true; // le dossier git est dans le lab mais le commun n'y est pas
      if (path.basename(path.dirname(g)) === 'worktrees' && gitfile && st.isFile()) {
        const haut = cheminPhysique(path.dirname(path.dirname(g))), retour = cheminPhysique(joindre(g, petit(path.join(g, 'gitdir')).trim()));
        if (c !== haut || retour === null || retour !== cheminPhysique(dotgit)) return true;
        libre = true;
      } else { // sous-module : lien retour obligatoire
        const w = c === g ? coreWorktree(g, racine) : null; if (!w || !w.length || !w.every((x) => x === dirP)) return true;
      }
    }
    const bud = { v: 0 };
    return !sain(g, dirP, racine, false, bud) || (c !== g && !sain(c, dirP, racine, libre, bud));
  } catch { return true; }
}
