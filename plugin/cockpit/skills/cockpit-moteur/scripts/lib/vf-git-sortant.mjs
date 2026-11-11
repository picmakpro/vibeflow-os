// vf-cockpit-git-sortant — git lirait-il, pour ce dossier, autre chose que le dépôt du lab ? (AUDC-A-02, socle du cockpit.) Lecture seule, fs seul, aucun git.
// Export : gitSortant(dir, racineLab = dir) -> booléen (point central : les lanceurs git de vf-cockpit-paths.mjs ; copie octet pour octet dans le moteur : lib/vf-git-sortant.mjs).
// Règle à point fixe, sans liste de membres ni d'exclusion : git n'est lancé sur un dépôt que si
//  (1) son dossier git (G) et son dossier commun (C, `commondir` de G) RÉSOLUS sont dans la racine réelle du lab, ou désignent le lab en retour : worktree vérifié (<C>/worktrees/<x>, dont
//      `gitdir` = ce `.git` et dont le commun est <C>, comme worktreeVerifie), sous-module dont `core.worktree` résout vers ce dossier ;
//  (2) AUCUN lien symbolique ne sort de G ni de C, où que ce soit sous eux (parcours complet, borné : refus au-delà de NMAX entrées). Un lien dont la cible reste DANS le dossier git est
//      permis : le verrou de pilotage de VibeFlow (`.git/vf-driver/…/DRIVER.lock`) en est un, et il ne fait rien lire d'extérieur ;
//  (3) pas d'`objects/info/alternates` ; `core.worktree` (config, config.worktree, inclusions suivies) absent ou désignant ce dossier ; une inclusion de configuration
//      (`include.path`, `includeIf.<condition>.path`) n'est permise que si son fichier est dans le lab ou dans le dossier git, et ses propres inclusions sont suivies (profondeur bornée).
// Sinon le git de ce dépôt est ignoré. Limites résiduelles : un lien dont la cible est dans le dossier git mais dont un maillon intermédiaire change entre le contrôle et la lecture (course) ;
// la configuration globale et système, qui relève de l'environnement des lancements git (envGit) ; un dépôt --separate-git-dir sans lien retour est ignoré.
// Coût : un parcours par dossier, mis en cache par date de modification du dossier (jamais pour un dossier modifié depuis moins de 2 s) : un lstat par dossier à chaque appel.
import fs from 'node:fs';
import path from 'node:path';

const real = (p) => { try { return fs.realpathSync(p); } catch { return path.resolve(p); } };
const petit = (f) => { const st = fs.statSync(f); if (!st.isFile() || st.size > 65536) throw new Error('fichier git inattendu'); return fs.readFileSync(f, 'utf8'); };
const NMAX = 500000;
const dans = (p, d) => p === d || p.startsWith(d + path.sep);
const cache = new Map(); // g\0dossier -> { m, at, ok, subs, n } : résultat du parcours d'un dossier (ses entrées directes), valable tant que sa date de modification est la même et plus ancienne que le parcours de 2 s
// vrai si aucun lien symbolique ne sort de g sous d ; bud.v compte les entrées vues
function sansLienSortant(d, g, bud) {
  let st; try { st = fs.lstatSync(d, { bigint: true }); } catch (e) { return e.code === 'ENOENT'; }
  if (!st.isDirectory()) return !st.isSymbolicLink();
  const k = g + '\0' + d; let c = cache.get(k);
  if (!c || c.m !== st.mtimeNs || c.at - Number(st.mtimeMs) < 2000) {
    c = { m: st.mtimeNs, at: Date.now(), ok: true, subs: [], n: 0 };
    const es = fs.readdirSync(d, { withFileTypes: true }); c.n = es.length;
    for (const e of es) {
      if (e.isSymbolicLink()) { if (!dans(path.resolve(d, fs.readlinkSync(path.join(d, e.name))), g)) c.ok = false; }
      else if (e.isDirectory()) c.subs.push(path.join(d, e.name));
    }
    cache.set(k, c);
  }
  bud.v += c.n;
  return c.ok && bud.v <= NMAX && c.subs.every((s) => sansLienSortant(s, g, bud));
}
// core.worktree d'un fichier de configuration et des inclusions qu'il suit : la liste des chemins résolus ; null si une inclusion sort du lab et du dossier git, ou est trop profonde
function worktrees(f, g, racine, prof = 0) {
  let t; try { t = petit(f); } catch (e) { if (e.code === 'ENOENT') return []; throw e; }
  const out = []; let sec = '';
  for (const l of t.split(/\r?\n/)) {
    const h = /^\s*\[\s*([A-Za-z0-9.-]*)[^\]]*\](.*)$/.exec(l), reste = h ? h[2] : l;
    if (h) sec = h[1].toLowerCase();
    const w = sec === 'core' && /^\s*worktree\s*=\s*(.+?)\s*$/i.exec(reste);
    if (w) out.push(real(path.resolve(g, w[1])));
    const i = (sec === 'include' || sec === 'includeif') && /^\s*path\s*=\s*(.+?)\s*$/i.exec(reste);
    if (i) {
      const cible = real(path.resolve(path.dirname(f), i[1].replace(/^"(.*)"$/, '$1')));
      if (i[1].startsWith('~') || prof > 8 || !(dans(cible, racine) || dans(cible, g))) return null;
      const r = worktrees(cible, g, racine, prof + 1); if (r === null) return null; out.push(...r);
    }
  }
  return out;
}
const coreWorktree = (g, racine) => { const a = worktrees(path.join(g, 'config'), g, racine), b = worktrees(path.join(g, 'config.worktree'), g, racine); return a === null || b === null ? null : [...a, ...b]; };
// (2) et (3) pour un dossier git ou commun. `libre` : dossier d'un worktree vérifié (git ignore le core.worktree du commun)
function sain(g, dir, racine, libre, bud) {
  if (!sansLienSortant(g, g, bud)) return false;
  if (['alternates', 'http-alternates'].some((a) => fs.existsSync(path.join(g, 'objects', 'info', a)))) return false;
  const w = coreWorktree(g, racine);
  return w !== null && (libre || w.every((x) => x === real(dir)));
}
export function gitSortant(dir, racineLab = dir) {
  const dotgit = path.join(dir, '.git'); let st;
  try { st = fs.lstatSync(dotgit); } catch { return false; }
  const racine = real(racineLab); // le lab : un dépôt imbriqué ou un sous-module du lab reste lu
  const dedans = (p) => p === racine || p.startsWith(racine + path.sep);
  try {
    let g, gitfile = false;
    if (st.isSymbolicLink()) { g = fs.realpathSync(dotgit); if (!dedans(g)) return true; gitfile = fs.statSync(g).isFile(); }
    else if (st.isDirectory()) g = fs.realpathSync(dotgit);
    else if (st.isFile()) { g = dotgit; gitfile = true; }
    else return true;
    if (gitfile) {
      const m = /^gitdir:\s*(.+)$/m.exec(petit(g)); if (!m) return true;
      g = fs.realpathSync(path.resolve(dir, m[1].trim()));
    }
    let c = g; // dossier commun
    try { c = fs.realpathSync(path.resolve(g, petit(path.join(g, 'commondir')).trim())); } catch (e) { if (e.code !== 'ENOENT') return true; }
    let libre = false;
    if (!(dedans(g) && dedans(c))) {
      if (dedans(g)) return true; // le dossier git est dans le lab mais le commun n'y est pas
      if (path.basename(path.dirname(g)) === 'worktrees' && gitfile && st.isFile()) {
        if (c !== real(path.dirname(path.dirname(g))) || fs.realpathSync(petit(path.join(g, 'gitdir')).trim()) !== fs.realpathSync(dotgit)) return true;
        libre = true;
      } else { const w = c === g ? coreWorktree(g, racine) : null; if (!w || !w.length || !w.every((x) => x === real(dir))) return true; } // sous-module : lien retour obligatoire
    }
    const bud = { v: 0 };
    return !sain(g, dir, racine, false, bud) || (c !== g && !sain(c, dir, racine, libre, bud));
  } catch { return true; }
}
