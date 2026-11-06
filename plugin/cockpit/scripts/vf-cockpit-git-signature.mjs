// vf-cockpit-git-signature — signature Git bon marché du lab, calculée dans le filet de 5 s du direct (78-09 ; GITC-11 ; P78-D-15, P78-D-23).
// Export : signatureGit(lab, { commun, echeanceMs }) -> Promise<chaîne hexadécimale sha256 | null> (hors dépôt, lecture en échec, git muet, retrait en cours : jamais un événement sur un doute).
// Lit : `for-each-ref` (refs et sha), `worktree list --porcelain -z` (arbres, branche et HEAD de chacun), les dates et tailles de l'index commun
// et de ceux de `<commun>/worktrees/*`. Jamais `log`, `status` ni `diff`. Lecture seule ; tout git passe par lancerGitAsync (78-01).
// A5 (audit 2026-11-06) : la signature est ASYNCHRONE (la boucle du serveur reste libre pendant que git travaille), bornée par UNE échéance globale courte pour tout le tick, jamais un appel en
// double (un tick ne relance rien tant que le précédent n'est pas revenu) et, après un git qui ne répond pas (include.path vers un FIFO, volume réseau figé…), elle se met en RETRAIT
// (5 s, puis 10 s, 20 s… au plus 2 min) : aucun nouveau git n'est lancé pendant le retrait. Un git qui échoue vite (hors dépôt) ne déclenche pas de retrait : un dépôt peut naître plus tard.
// Limite assumée : un fichier modifié sans `git add` ne bouge aucun de ces éléments (le tiroir relit le status à l'ouverture).
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { lancerGitAsync, finDans } from './vf-cockpit-paths.mjs';

export const ECHEANCE_TICK_MS = 2000, RETRAIT_MIN_MS = 5000, RETRAIT_MAX_MS = 120000;
const communs = new Map(); // dossier commun de chaque lab : il ne change pas ; un échec n'est jamais mémorisé (un dépôt peut naître plus tard)
const etats = new Map(); // lab -> { enVol, echecs, jusqu } : garde contre le recouvrement et retrait après un git muet
const empreinte = (f) => { try { const s = fs.statSync(f); return `${f}:${s.mtimeMs}:${s.size}`; } catch { return `${f}:-`; } };

export async function signatureGit(lab, { commun, echeanceMs = ECHEANCE_TICK_MS, maintenant = Date.now } = {}) {
  const e = etats.get(lab) || { enVol: false, echecs: 0, jusqu: 0 };
  etats.set(lab, e);
  if (e.enVol || maintenant() < e.jusqu) return null; // un tick précédent est encore en vol, ou retrait en cours : aucun git
  e.enVol = true;
  let muet = false;
  try {
    const fin = finDans(echeanceMs); // échéance globale du tick : tous les git de la signature s'y rangent
    let dossier = commun || communs.get(lab);
    if (!dossier) {
      const r = await lancerGitAsync(lab, ['rev-parse', '--path-format=absolute', '--git-common-dir'], { fin });
      muet = muet || r.delai === true;
      dossier = r.ok ? r.sortie.trim() : '';
    }
    if (!dossier) return null;
    communs.set(lab, dossier);
    const refs = await lancerGitAsync(lab, ['for-each-ref', '--format=%(objectname) %(refname)'], { fin });
    const arbres = await lancerGitAsync(lab, ['worktree', 'list', '--porcelain', '-z'], { fin });
    muet = muet || refs.delai === true || arbres.delai === true;
    if (!refs.ok || !arbres.ok) return null;
    const index = [empreinte(path.join(dossier, 'index'))];
    let noms = []; try { noms = fs.readdirSync(path.join(dossier, 'worktrees')).sort(); } catch {}
    for (const n of noms) index.push(empreinte(path.join(dossier, 'worktrees', n, 'index')));
    return crypto.createHash('sha256').update([refs.sortie, arbres.sortie, index.join('\n')].join('\0\0')).digest('hex');
  } catch { return null; }
  finally {
    e.enVol = false;
    if (muet) { e.echecs++; e.jusqu = maintenant() + Math.min(RETRAIT_MAX_MS, RETRAIT_MIN_MS * 2 ** (e.echecs - 1)); }
    else { e.echecs = 0; e.jusqu = 0; }
  }
}
