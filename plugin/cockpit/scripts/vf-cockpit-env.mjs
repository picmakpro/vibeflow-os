// vf-cockpit-env.mjs — environnement sûr des processus enfants du cockpit (audit 67-SECURITY H-1).
// Le serveur et ses modules lancent des outils par leur NOM (which, claude, git, bash, awk, tr, ps…). Un PATH qui contient un élément vide
// ou relatif (« . », « bin ») ou un dossier du lab fait exécuter à leur place un programme posé dans le lab. Un seul utilitaire, appliqué
// à l'environnement de chaque enfant ; le PATH du shell de l'utilisateur n'est jamais modifié (on rend une copie).
import fs from 'node:fs';
import path from 'node:path';

const WIN = process.platform === 'win32';
export const PATH_REPLI = WIN ? 'C:\\Windows\\System32;C:\\Windows' : '/usr/bin:/bin:/usr/sbin:/sbin';

const reel = (p) => { try { return fs.realpathSync(p); } catch { return null; } };
const sous = (el, dossier) => { const r = path.relative(dossier, el); return r === '' || (!r.startsWith('..') && !path.isAbsolute(r)); };

/** Retire du PATH tout élément vide, relatif ou situé sous le lab (lien symbolique résolu) ; repli sûr si plus rien ne reste. */
export function assainirPath(valeur, lab) {
  const dossiers = lab ? [path.resolve(lab), reel(lab)].filter(Boolean) : [];
  const gardes = String(valeur ?? '').split(path.delimiter).filter((el) => {
    if (!el.trim() || el.includes('\0') || !path.isAbsolute(el)) return false;
    const abs = path.resolve(el), vrai = reel(el);
    return !dossiers.some((d) => sous(abs, d) || (vrai && sous(vrai, d)));
  });
  return gardes.length ? gardes.join(path.delimiter) : PATH_REPLI;
}

/** Copie de l'environnement avec un PATH assaini (sous Windows la clé peut s'écrire Path). */
export function envEnfant(lab, env = process.env) {
  const cle = (WIN && Object.keys(env).find((k) => k.toUpperCase() === 'PATH')) || 'PATH';
  return { ...env, [cle]: assainirPath(env[cle], lab) };
}
