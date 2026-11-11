// vf-cockpit-git-sortant — git lirait-il, pour ce dossier, autre chose que le dépôt du lab ? (AUDC-A-02, socle du cockpit.) Lecture seule, fs seul, aucun git.
// Export : gitSortant(dir, racineLab = dir) -> booléen (point central : les lanceurs git de vf-cockpit-paths.mjs ; copie octet pour octet dans le moteur : lib/vf-git-sortant.mjs).
// Règle à point fixe, jamais une liste de cas : git n'est lancé sur un dépôt que si
//  (1) son dossier git (G) et son dossier commun (C, `commondir` de G) RÉSOLUS sont dans la racine réelle du lab, ou désignent le lab en retour : worktree vérifié (<C>/worktrees/<x>, dont
//      `gitdir` = ce `.git` et dont le commun est <C>, comme worktreeVerifie), sous-module dont `core.worktree` résout vers ce dossier ;
//  (2) aucun lien symbolique ne se trouve dans les métadonnées que git ouvre pour ce dépôt, G et C : membres de premier niveau, arbre `refs/`, `objects/` (fan-out, info, pack) ;
//  (3) pas d'`objects/info/alternates` ; `core.worktree` (config, config.worktree) absent ou désignant ce dossier.
// Sinon le git de ce dépôt est ignoré. Limites résiduelles : le contenu d'un objet isolé déjà lié (fichier d'un fan-out dont le SHA est connu par ailleurs) n'est pas parcouru ;
// un dépôt --separate-git-dir sans lien retour est ignoré ; les inclusions de configuration (`include.path`) ne sont pas suivies.
import fs from 'node:fs';
import path from 'node:path';

const real = (p) => { try { return fs.realpathSync(p); } catch { return path.resolve(p); } };
const petit = (f) => { const st = fs.statSync(f); if (!st.isFile() || st.size > 65536) throw new Error('fichier git inattendu'); return fs.readFileSync(f, 'utf8'); };
const NON_LUS = new Set(['hooks', 'description', 'logs', 'modules', 'worktrees']); // membres que les lectures du cockpit n'ouvrent pas (git est lancé sans hooks, en lecture)
const MAX = 20000; // bornes : au-delà, refus (jamais un parcours sans fin)
const entrees = (d) => { try { return fs.readdirSync(d, { withFileTypes: true }); } catch (e) { if (e.code === 'ENOENT' || e.code === 'ENOTDIR') return []; throw e; } };
// vrai si aucun lien symbolique sous d (profondeur bornée) ; n compte les entrées vues
function sansLien(d, n, prof = 0) {
  for (const e of entrees(d)) {
    if (e.isSymbolicLink() || ++n.v > MAX || prof > 12) return false;
    if (e.isDirectory() && !sansLien(path.join(d, e.name), n, prof + 1)) return false;
  }
  return true;
}
// core.worktree de <g>/config puis <g>/config.worktree, toutes sections [core] : la liste des chemins résolus (vide : absent)
function coreWorktree(g) {
  const out = [];
  for (const f of ['config', 'config.worktree']) {
    let t; try { t = petit(path.join(g, f)); } catch (e) { if (e.code === 'ENOENT') continue; throw e; }
    let core = false;
    for (const l of t.split(/\r?\n/)) {
      const h = /^\s*\[([^\]\s"]*)[^\]]*\](.*)$/.exec(l), reste = h ? h[2] : l;
      if (h) core = h[1].toLowerCase() === 'core';
      const w = core && /^\s*worktree\s*=\s*(.+?)\s*$/i.exec(reste);
      if (w) out.push(real(path.resolve(g, w[1])));
    }
  }
  return out;
}
// métadonnées d'un dossier git ou commun : (2) et (3). `libre` : le dossier est celui d'un worktree vérifié (git ignore le core.worktree du commun)
function sain(g, dir, libre) {
  const n = { v: 0 };
  for (const e of entrees(g)) if (!NON_LUS.has(e.name) && e.isSymbolicLink()) return false;
  if (!sansLien(path.join(g, 'refs'), n) || !sansLien(path.join(g, 'info'), n)) return false;
  const obj = path.join(g, 'objects');
  for (const e of entrees(obj)) { if (e.isSymbolicLink() || ++n.v > MAX) return false; if (e.name === 'info' || e.name === 'pack') { if (!sansLien(path.join(obj, e.name), n)) return false; } }
  if (['alternates', 'http-alternates'].some((a) => fs.existsSync(path.join(obj, 'info', a)))) return false;
  return libre || coreWorktree(g).every((w) => w === real(dir));
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
      } else if (c !== g || !coreWorktree(g).length || !coreWorktree(g).every((w) => w === real(dir))) return true; // sous-module : lien retour obligatoire
    }
    return !sain(g, dir, false) || (c !== g && !sain(c, dir, libre));
  } catch { return true; }
}
