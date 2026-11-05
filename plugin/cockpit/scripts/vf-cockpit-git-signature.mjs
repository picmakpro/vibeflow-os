// vf-cockpit-git-signature — signature Git bon marché du lab, calculée dans le filet de 5 s du direct (78-09 ; GITC-11 ; P78-D-15, P78-D-23).
// Export : signatureGit(lab, { commun }) -> chaîne hexadécimale sha256, ou null (hors dépôt, ou lecture en échec : jamais un événement sur un doute).
// Lit : `for-each-ref` (refs et sha), `worktree list --porcelain -z` (arbres, branche et HEAD de chacun), les dates et tailles de l'index commun
// et de ceux de `<commun>/worktrees/*`. Jamais `log`, `status` ni `diff`. Lecture seule ; tout git passe par lancerGit (78-01).
// Limite assumée : un fichier modifié sans `git add` ne bouge aucun de ces éléments (le tiroir relit le status à l'ouverture).
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { lancerGit, gitCommonDir } from './vf-cockpit-paths.mjs';

const communs = new Map(); // dossier commun de chaque lab : il ne change pas ; un échec n'est jamais mémorisé (un dépôt peut naître plus tard)
const empreinte = (f) => { try { const s = fs.statSync(f); return `${f}:${s.mtimeMs}:${s.size}`; } catch { return `${f}:-`; } };

export function signatureGit(lab, { commun } = {}) {
  try {
    const dossier = commun || communs.get(lab) || gitCommonDir(lab);
    if (!dossier) return null;
    communs.set(lab, dossier);
    const refs = lancerGit(lab, ['for-each-ref', '--format=%(objectname) %(refname)']);
    const arbres = lancerGit(lab, ['worktree', 'list', '--porcelain', '-z']);
    if (!refs.ok || !arbres.ok) return null;
    const index = [empreinte(path.join(dossier, 'index'))];
    let noms = []; try { noms = fs.readdirSync(path.join(dossier, 'worktrees')).sort(); } catch {}
    for (const n of noms) index.push(empreinte(path.join(dossier, 'worktrees', n, 'index')));
    return crypto.createHash('sha256').update([refs.sortie, arbres.sortie, index.join('\n')].join('\0\0')).digest('hex');
  } catch { return null; }
}
