// vf-cockpit-git-sortant — le `.git` d'un dossier fait-il lire à git un dépôt hors de ce dossier ? (AUDC-A-02, socle du cockpit.) Lecture seule, fs seul, aucun git.
// Export : gitSortant(dir, racineLab = dir) -> booléen (point central : les lanceurs git de vf-cockpit-paths.mjs).
import fs from 'node:fs';
import path from 'node:path';

const real = (p) => { try { return fs.realpathSync(p); } catch { return path.resolve(p); } };
const petit = (f) => { const st = fs.statSync(f); if (!st.isFile() || st.size > 65536) throw new Error('fichier git inattendu'); return fs.readFileSync(f, 'utf8'); };
// AUDC-A-02 : le critère porte sur ce que git lit RÉELLEMENT, jamais sur la forme de `.git` : le dossier git (G) et le dossier commun (C, `commondir` de G s'il existe) résolus.
// Les deux dans la racine réelle du lab : lu. Sinon, lu seulement si le dépôt désigne ce dossier en retour : worktree vérifié (<C>/worktrees/<x>, dont `gitdir` désigne ce `.git`
// et dont le commun est bien <C>, comme worktreeVerifie) ou sous-module (`core.worktree` de G résolu = ce dossier, sans commun distinct). Un dépôt --separate-git-dir sans lien retour est ignoré.
// Même règle dans la copie vendorisée (scan, lib/common.mjs).
export function gitSortant(dir, racineLab = dir) {
  const dotgit = path.join(dir, '.git'); let st;
  try { st = fs.lstatSync(dotgit); } catch { return false; }
  const racine = real(racineLab); // le lab : un dépôt imbriqué ou un sous-module du lab reste lu, seul un dossier git hors du lab sort
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
    if (dedans(g) && dedans(c)) return false;
    if (dedans(g)) return true; // le dossier git est dans le lab mais le commun n'y est pas
    if (path.basename(path.dirname(g)) === 'worktrees' && gitfile && st.isFile()) {
      return c !== real(path.dirname(path.dirname(g))) || fs.realpathSync(petit(path.join(g, 'gitdir')).trim()) !== fs.realpathSync(dotgit);
    }
    if (c !== g) return true;
    const cfg = /^\[core\]\s*$([\s\S]*?)(?=^\[|(?![\s\S]))/m.exec(petit(path.join(g, 'config')));
    const wt = cfg && /^\s*worktree\s*=\s*(.+?)\s*$/m.exec(cfg[1]);
    return !(wt && fs.realpathSync(path.resolve(g, wt[1])) === real(dir));
  } catch { return true; }
}
