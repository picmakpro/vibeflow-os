// vf-cockpit-git-sortant — le `.git` d'un dossier désigne-t-il un dossier git hors de ce dossier ? (AUDC-A-02, socle du cockpit.) Lecture seule, fs seul, aucun git.
// Export : gitSortant(dir) -> booléen.
import fs from 'node:fs';
import path from 'node:path';

const real = (p) => { try { return fs.realpathSync(p); } catch { return path.resolve(p); } };
// AUDC-A-02 : vrai quand `<dir>/.git` existe et désigne un dossier git HORS de la racine réelle de `dir` — lien symbolique sortant, ou fichier `gitdir:` sortant qui n'est pas un worktree
// vérifié (lien retour de <admin>/gitdir = ce `.git`, comme worktreeVerifie). Un dépôt ordinaire du lab et un worktree légitime restent lus. Même règle dans la copie vendorisée (scan, lib/common.mjs).
export function gitSortant(dir) {
  const dotgit = path.join(dir, '.git'); let st;
  try { st = fs.lstatSync(dotgit); } catch { return false; }
  const racine = real(dir);
  const dedans = (p) => p === racine || p.startsWith(racine + path.sep);
  try {
    if (st.isDirectory()) return false;
    if (st.isSymbolicLink()) return !dedans(fs.realpathSync(dotgit));
    if (!st.isFile() || st.size > 4096) return true;
    const m = /^gitdir:\s*(.+)$/m.exec(fs.readFileSync(dotgit, 'utf8')); if (!m) return true;
    const admin = fs.realpathSync(path.resolve(dir, m[1].trim()));
    if (dedans(admin)) return false;
    if (path.basename(path.dirname(admin)) !== 'worktrees') return true;
    return fs.realpathSync(fs.readFileSync(path.join(admin, 'gitdir'), 'utf8').trim()) !== fs.realpathSync(dotgit);
  } catch { return true; }
}
