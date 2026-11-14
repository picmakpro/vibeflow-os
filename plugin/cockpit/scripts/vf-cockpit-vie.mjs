// vf-cockpit-vie — la vie d'une mission : son verrou de driver est-il tenu, ou son progrès récent ? (VFSG-06 ; P68-D-05, P68-D-16, P68-D-22, P68-D-23, P68-D-26, P68-D-27, P68-D-33)
// Exports : lireVerrous(root, { scriptsDir, home, sh }) -> { etat: 'lue'|'absente'|'erreur', plat, liste: [{ ws, scope, phase, step, tenu, stale,
//             ageS, ttl, progressAgeS, owner, childrenRunning, leaseS, dag, sansSession? }] }
//           verrousDe(st, { sessions }) -> la même forme, depuis l'objet brut de `status --all` (pur ; `sessions` : ensemble des sessions de la
//             collecte, A15 : `sansSession`) ; dagDe(dag) -> plan revalidé ou null
//           vieDe({ ws, phase }, verrous) -> { tenu, stale, progressAgeS, ttl } | null (source illisible : la mission est « inconnu »)
//           estVivante(vie) · normPhase(valeur)
// Lecture du verrou par shell-out borné (driver-lock.sh status --all, repli sur status pour un script d'avant --all, script résolu hors de l'arbre observé : T-67-06) ;
// calcul pur dans vieDe et estVivante ; jamais la date de modification d'un DAG (le progrès vient du JSON du verrou).
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { driverLockScript, resolveScriptsDir, shBorne } from './vf-cockpit-paths.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const sh = shBorne; // un bash bloqué ne gèle pas la boucle, et l'échéance globale de l'émetteur s'applique (F-06)
const PH_RE = /^[0-9]+(\.[0-9]+)*$/; // vf_dl_phase_valid de driver-lock.sh
const num = (v) => (typeof v === 'number' && Number.isFinite(v) ? v : null);
const age = (v) => { const n = num(v); return n !== null && n >= 0 ? n : null; }; // F-8 : un âge négatif (horloge reculée, epoch futur) est incohérent : traité comme absent, jamais comme un progrès récent
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
  return typeof vie.progressAgeS === 'number' && vie.progressAgeS >= 0 && typeof vie.ttl === 'number' && vie.progressAgeS < vie.ttl;
}

// A15, A16 : le plan publié du verrou (`dag`) est relu et revalidé : jamais recopié. Identifiants et dépendances de forme `[A-Za-z0-9._:-]{1,64}`,
// statut de liste fermée, 200 nœuds et 32 dépendances au plus, `ws` et `phase` par les grammaires du script de verrou, `at` entier ;
// un nœud hors forme est écarté.
const ID_DAG = /^[A-Za-z0-9._:-]{1,64}$/, STATUTS_DAG = new Set(['blocked', 'ready', 'running', 'done', 'failed']);
const WS_RE = /^[A-Za-z0-9][A-Za-z0-9._-]*$/;
const idOk = (x) => typeof x === 'string' && ID_DAG.test(x);
export function dagDe(d) {
  if (!d || typeof d !== 'object' || !Array.isArray(d.nodes)) return null;
  const nodes = [];
  for (const n of d.nodes) {
    if (nodes.length >= 200) break;
    if (!n || !idOk(n.id) || !STATUTS_DAG.has(n.status)) continue;
    nodes.push({ id: n.id, deps: (Array.isArray(n.deps) ? n.deps : []).filter(idOk).slice(0, 32), status: n.status });
  }
  const ws = typeof d.ws === 'string' && WS_RE.test(d.ws) && !d.ws.includes('..') ? d.ws : '';
  return { ws, phase: typeof d.phase === 'string' && PH_RE.test(d.phase) ? d.phase : '', at: Number.isInteger(d.at) ? d.at : null, nodes };
}
const sansSession = (ids, sessions) => Array.isArray(ids) && ids.length > 0 && !ids.some((i) => sessions.has(i)); // garde:verrou-sanssession
const garde = (l, sessions) => ({
  ws: chaine(l.ws) ?? '', scope: chaine(l.scope), phase: chaine(l.phase), tenu: true, stale: bool(l.stale), ageS: num(l.age_seconds), ttl: num(l.ttl),
  progressAgeS: age(l.progress_age_seconds), owner: chaine(l.owner), step: chaine(l.step), childrenRunning: num(l.children_running),
  leaseS: num(l.lease_seconds), dag: dagDe(l.dag), ...(sessions ? { sansSession: sansSession(l.session_ids, sessions) } : {}),
});

// verrousDe : la sortie brute de `status --all` (ou de `status` en lab plat) rendue en liste de verrous TENUS ; seuls les champs ci-dessus en sortent
// (aucun chemin, aucun emplacement, aucune liste d'identifiants de session).
export function verrousDe(st, { sessions } = {}) {
  const vide = (etat, plat = false) => ({ etat, plat, liste: [] });
  if (!st || typeof st !== 'object' || Array.isArray(st)) return vide('erreur');
  if (st.available === false) return vide('absente');
  if (Array.isArray(st.locks)) {
    const tenus = st.locks.filter((l) => l && typeof l === 'object' && l.present === true);
    return { etat: 'lue', plat: false, liste: tenus.map((l) => garde(l, sessions)) };
  }
  if (st.present === true) return { etat: 'lue', plat: true, liste: [garde(st, sessions)] };
  if (st.present === false) return vide('lue', true);
  return vide('erreur');
}

// lireVerrous : `status --all` ; lab plat = l'objet d'UN verrou (plat: true) ; les entrées absentes sont écartées.
export function lireVerrous(root, { scriptsDir, home, lab = root, sh: run0 = sh } = {}) {
  const run = (cmd, args, cwd) => run0(cmd, args, cwd, lab); // `lab` : racine du LAB observé (H-1), distincte de `root` quand l'arbre lu est sous le lab
  const dl = driverLockScript({ scriptsDir: scriptsDir || resolveScriptsDir(HERE), labRoot: root, home: home ?? os.homedir() });
  if (dl.etat === 'absent') return { etat: 'absente', plat: false, liste: [] };
  const objet = (s) => { try { const o = JSON.parse(s); return o && typeof o === 'object' && !Array.isArray(o) ? o : null; } catch { return null; } };
  const brut = run('bash', [dl.chemin, 'status', '--all'], root);
  let st = objet(brut);
  // F-04 : un script d'avant `--all` (avant 32438005) répond « Unknown arg: --all » sur stderr, stdout vide ; en lab plat le verbe de base `status` répond alors l'objet d'UN verrou.
  // Repli seulement sur une sortie VIDE (un refus), et seulement si la réponse ne porte ni `scope` ni `locks` : un script qui connaît la portée aurait répondu à `--all`, son `status` nu ne dit qu'un verrou parmi d'autres.
  if (!st && brut.trim() === '') { st = objet(run('bash', [dl.chemin, 'status'], root)); if (st && ('scope' in st || 'locks' in st)) st = null; }
  return verrousDe(st);
}

const sans = { tenu: false, stale: null, progressAgeS: null, ttl: null };
const vieDeEntree = (e) => ({ tenu: e.tenu, stale: e.stale, progressAgeS: e.progressAgeS, ttl: e.ttl });

// vieDe : cascade verrou de la phase (même périmé), sinon verrou du compartiment (P68-D-26), sinon verrou de dépôt (P68-D-33), sinon absent ; lab plat : le verrou unique.
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
  // P68-D-33 : sans verrou de phase ni de compartiment, le verrou de dépôt couvre la mission (`acquire` sans --ws en lab partitionné le pose ; l'ancien .planning/DRIVER.lock en est une entrée aussi) ; le vivant l'emporte sur le périmé.
  const eDe = liste.filter((e) => e.scope === 'depot' && e.ws === '');
  return eDe.length ? vieDeEntree(eDe.find(vive) || eDe[0]) : sans;
}
