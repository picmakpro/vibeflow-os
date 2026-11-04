// vf-cockpit-vie — la vie d'une mission : son verrou de driver est-il tenu, ou son progrès récent ? (VFSG-06 ; P68-D-05, P68-D-16, P68-D-22, P68-D-23, P68-D-26, P68-D-27)
// Exports : lireVerrous(root, { scriptsDir, home, sh }) -> { etat: 'lue'|'absente'|'erreur', plat, liste: [{ ws, scope, phase, tenu, stale, ageS, ttl, progressAgeS, owner }] }
//           vieDe({ ws, phase }, verrous) -> { tenu, stale, progressAgeS, ttl } | null (source illisible : la mission est « inconnu »)
//           estVivante(vie) · normPhase(valeur)
// Lecture du verrou par shell-out borné (driver-lock.sh status --all, script résolu hors de l'arbre observé : T-67-06) ;
// calcul pur dans vieDe et estVivante ; jamais la date de modification d'un DAG (le progrès vient du JSON du verrou).
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';
import { driverLockScript, resolveScriptsDir } from './vf-cockpit-paths.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const sh = (cmd, args, cwd) => { try { return execFileSync(cmd, args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], timeout: 10000 }); } catch (e) { return e.stdout || ''; } }; // un bash bloqué ne gèle pas la boucle
const PH_RE = /^[0-9]+(\.[0-9]+)*$/; // vf_dl_phase_valid de driver-lock.sh
const num = (v) => (typeof v === 'number' && Number.isFinite(v) ? v : null);
const bool = (v) => (typeof v === 'boolean' ? v : null);
const chaine = (v) => (typeof v === 'string' ? v : null);

// 069 -> 69, 41.1 -> 41.1 ; une valeur qui n'est pas une chaîne du motif de driver-lock.sh ne correspond à rien (null)
export function normPhase(v) {
  if (typeof v !== 'string' || !PH_RE.test(v)) return null;
  return v.split('.').map((s) => String(Number(s))).join('.');
}

// Un verrou est vivant s'il est tenu et non périmé, ou si son progrès date de moins que son ttl (types vérifiés, jamais un null pris pour 0).
export function estVivante(vie) {
  if (!vie || typeof vie !== 'object') return false;
  if (vie.tenu === true && vie.stale === false) return true;
  return typeof vie.progressAgeS === 'number' && typeof vie.ttl === 'number' && vie.progressAgeS < vie.ttl;
}

const garde = (l) => ({ ws: chaine(l.ws) ?? '', scope: chaine(l.scope), phase: chaine(l.phase), tenu: true, stale: bool(l.stale), ageS: num(l.age_seconds), ttl: num(l.ttl), progressAgeS: num(l.progress_age_seconds), owner: chaine(l.owner) });

// lireVerrous : `status --all` ; lab plat = l'objet d'UN verrou (plat: true) ; les entrées absentes sont écartées.
export function lireVerrous(root, { scriptsDir, home, sh: run = sh } = {}) {
  const dl = driverLockScript({ scriptsDir: scriptsDir || resolveScriptsDir(HERE), labRoot: root, home: home ?? os.homedir() });
  if (dl.etat === 'absent') return { etat: 'absente', plat: false, liste: [] };
  let st; try { st = JSON.parse(run('bash', [dl.chemin, 'status', '--all'], root)); } catch { return { etat: 'erreur', plat: false, liste: [] }; }
  if (!st || typeof st !== 'object' || Array.isArray(st)) return { etat: 'erreur', plat: false, liste: [] };
  if (Array.isArray(st.locks)) return { etat: 'lue', plat: false, liste: st.locks.filter((l) => l && typeof l === 'object' && l.present === true).map(garde) };
  if (st.present === true) return { etat: 'lue', plat: true, liste: [garde(st)] };
  if (st.present === false) return { etat: 'lue', plat: true, liste: [] };
  return { etat: 'erreur', plat: false, liste: [] };
}

const sans = { tenu: false, stale: null, progressAgeS: null, ttl: null };
const vieDeEntree = (e) => ({ tenu: e.tenu, stale: e.stale, progressAgeS: e.progressAgeS, ttl: e.ttl });

// vieDe : cascade verrou de la phase (même périmé), sinon verrou du compartiment (P68-D-26), sinon absent ; lab plat : le verrou unique.
// DAG hors phase (phase null) : compartiment, puis dépôt. Source illisible : null.
export function vieDe({ ws, phase } = {}, verrous) {
  if (!verrous || verrous.etat !== 'lue') return null;
  const { liste } = verrous;
  if (verrous.plat) return liste.length ? vieDeEntree(liste[0]) : sans;
  const ph = normPhase(phase == null ? null : String(phase));
  const vive = (e) => estVivante(vieDeEntree(e));
  const ePh = ph === null ? [] : liste.filter((e) => e.scope === 'phase' && (e.ws || '') === (ws || '') && ph !== null && normPhase(e.phase) === ph);
  if (ePh.length) return vieDeEntree(ePh.find(vive) || ePh[0]);
  const eCo = ws ? liste.find((e) => e.scope === 'compartiment' && e.ws === ws) : null;
  if (eCo) return vieDeEntree(eCo);
  const eDe = !ws ? liste.find((e) => e.scope === 'depot' && e.ws === '') : null;
  return eDe ? vieDeEntree(eDe) : sans;
}
