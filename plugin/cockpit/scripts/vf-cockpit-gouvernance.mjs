// vf-cockpit-gouvernance — calculs de gouvernance côté serveur, en fonctions pures
// (P73-D-06, P73-D-07, P73-D-09, P73-D-12, P73-D-31, P73-D-35 ; REGI-04, 05, 07, 10)
// Exports : aval(noeuds, depart) · restants(noeuds) · detention(idSession, verrous)
//           missionDe({ ws, phase }, { dags, phases }) · retientDe({ rattachement, detention }, { dags, phases })
//           enteteStatut(texte) · phasesHumaines({ phases, lire, fichiers }) · fenetreStall({ env, texteScript })
//           scriptGarde({ scriptsDir, labRoot, home }) · attendAgents(fichier)
// Aucune écriture, aucun processus : la lecture des fichiers est fournie par l'appelant (`lire`, `fichiers`), sauf le script de garde
// (texte lu, jamais exécuté) et le transcript (`cherche`, borné). Gardes de type champ par champ, jamais un null pris pour 0 ;
// graphes en Map et Set seulement (T-69-09).
import fs from 'node:fs';
import path from 'node:path';
import { cherche } from './vf-cockpit-lecture.mjs';
import { driverLockScript } from './vf-cockpit-paths.mjs';
import { trouverPhase, rattacherMission } from './vf-cockpit-avancement.mjs';

const WS_RE = /^[A-Za-z0-9][A-Za-z0-9._-]*$/, PH_RE = /^[0-9]+(\.[0-9]+)*$/; // grammaires de vf-cockpit-who.mjs
const liste = (v) => (Array.isArray(v) ? v : []);

// Graphe des nœuds valides (identifiant chaîne) : statut par identifiant, enfants par dépendance ;
// `deps` non tableau et dépendances non chaîne sont ignorés.
function graphe(noeuds) {
  const statut = new Map(), enfants = new Map();
  const valides = liste(noeuds).filter((n) => n && typeof n === 'object' && typeof n.id === 'string');
  for (const n of valides) statut.set(n.id, n.status);
  for (const n of valides) {
    for (const d of liste(n.deps)) {
      if (typeof d !== 'string') continue;
      if (!enfants.has(d)) enfants.set(d, new Set());
      enfants.get(d).add(n.id);
    }
  }
  return { statut, enfants };
}

// Nœuds non terminés atteignables depuis `depart` en suivant les dépendances à l'envers, `depart` exclu.
export function aval(noeuds, depart) {
  const { statut, enfants } = graphe(noeuds);
  if (typeof depart !== 'string' || !statut.has(depart)) return 0;
  const vus = new Set([depart]), pile = [depart];
  while (pile.length) for (const c of enfants.get(pile.pop()) || []) if (!vus.has(c)) { vus.add(c); pile.push(c); }
  vus.delete(depart);
  return [...vus].filter((id) => statut.get(id) !== 'done').length;
}

export const restants = (noeuds) => [...graphe(noeuds).statut.values()].filter((s) => s !== 'done').length;

// Détention : { ws, phase } du premier verrou PRÉSENT dont la liste d'identifiants de session contient `idSession` ;
// ws et phase revalidés, sinon null. `verrous` : l'objet brut de `status --all` ({ locks }), la liste de ses verrous,
// ou l'objet d'un verrou unique (lab plat).
export function detention(idSession, verrous) {
  if (typeof idSession !== 'string' || !idSession) return null;
  const locks = Array.isArray(verrous) ? verrous
    : Array.isArray(verrous?.locks) ? verrous.locks : verrous && typeof verrous === 'object' ? [verrous] : [];
  for (const l of locks) {
    if (!l || typeof l !== 'object' || l.present !== true || !liste(l.session_ids).includes(idSession)) continue;
    const ws = l.ws == null ? '' : l.ws, phase = l.phase == null ? '' : l.phase;
    if (typeof ws !== 'string' || (ws !== '' && (!WS_RE.test(ws) || ws.includes('..')))) return null;
    if (typeof phase !== 'string' || (phase !== '' && !PH_RE.test(phase))) return null;
    return { ws, phase };
  }
  return null;
}

// Nœuds de la mission rattachée à la phase (règles de rattacherMission) ; plusieurs missions : celle qui a un nœud `running`,
// puis la plus petite règle, puis le nom.
export function missionDe({ ws, phase } = {}, { dags, phases } = {}) {
  if (typeof phase !== 'string' || !PH_RE.test(phase) || !(phases instanceof Map)) return null;
  const p = trouverPhase(phases, phase, typeof ws === 'string' && ws ? ws : null);
  if (!p) return null;
  const l = [];
  for (const d of liste(dags)) {
    if (!d || typeof d !== 'object') continue;
    const r = rattacherMission(d, phases);
    if (!r || r.cle !== p.key) continue;
    const nodes = liste(d.nodes);
    l.push({ nodes, regle: r.regle ?? 9, run: nodes.some((x) => x?.status === 'running'), nom: String(d.name || '') });
  }
  l.sort((a, b) => (b.run - a.run) || (a.regle - b.regle) || (a.nom < b.nom ? -1 : a.nom > b.nom ? 1 : 0));
  return l.length ? l[0].nodes : null;
}

// Impact d'une session : aval du nœud rattaché dans son DAG ('noeuds'), sinon restants de la mission dont elle détient
// le verrou ('mission'), sinon null (inconnu, jamais deviné).
export function retientDe({ rattachement, detention: det } = {}, { dags, phases } = {}) {
  if (rattachement && typeof rattachement === 'object' && typeof rattachement.noeud === 'string') {
    const nom = rattachement.dag;
    const dag = typeof nom === 'string' ? liste(dags).find((d) => d && (d.name === nom || d.file === nom)) : nom;
    if (dag && liste(dag.nodes).some((n) => n && n.id === rattachement.noeud)) {
      return { n: aval(dag.nodes, rattachement.noeud), portee: 'noeuds' };
    }
  }
  if (det && typeof det === 'object') { const m = missionDe(det, { dags, phases }); if (m) return { n: restants(m), portee: 'mission' }; }
  return null; // impact inconnu : jamais deviné
}

// Valeur de `status:` du premier bloc YAML d'en-tête (deux lignes `---`), lu sur 4 Kio et 40 lignes au plus ;
// null si pas de bloc, bloc non fermé ou clé absente.
export function enteteStatut(texte) {
  if (typeof texte !== 'string') return null;
  const lignes = texte.slice(0, 4096).split('\n').slice(0, 40).map((x) => x.replace(/\r$/, ''));
  if (lignes[0] !== '---') return null;
  const fin = lignes.indexOf('---', 1);
  if (fin < 0) return null;
  const bloc = lignes.slice(1, fin);
  for (const x of bloc) {
    const m = /^status:[ \t]*(.*?)[ \t]*$/.exec(x);
    if (m) { const v = m[1].replace(/^(["'])(.*)\1$/, '$2'); return v === '' ? null : v; }
  }
  return null;
}

const cmp = (a, b) => {
  const x = String(a).split('.').map(Number), y = String(b).split('.').map(Number);
  for (let i = 0; i < Math.max(x.length, y.length); i++) if ((x[i] ?? -1) !== (y[i] ?? -1)) return (x[i] ?? -1) - (y[i] ?? -1);
  return 0;
};

// Phases ni cochées ni archivées dont un `*-VERIFICATION.md` a l'en-tête `status: human_needed` (A1).
// `fichiers(cle)` : noms du dossier de la phase ; `lire(cle, fichier)` : texte ; les deux sont fournis par l'appelant.
export function phasesHumaines({ phases, lire, fichiers } = {}) {
  const sortie = [];
  if (typeof lire !== 'function' || typeof fichiers !== 'function') return sortie;
  for (const p of phases instanceof Map ? phases.values() : liste(phases)) {
    if (!p || typeof p !== 'object' || typeof p.key !== 'string') continue;
    if (p.done || p.archive) continue;
    let noms;
    try { noms = liste(fichiers(p.key)).filter((f) => typeof f === 'string' && f.endsWith('-VERIFICATION.md')).sort(); } catch { continue; }
    for (const f of noms) {
      let t; try { t = lire(p.key, f); } catch { continue; }
      if (enteteStatut(t) === 'human_needed') { sortie.push({ phase: String(p.n), ws: p.ws || '', cle: p.key }); break; }
    }
  }
  return sortie.sort((a, b) => cmp(a.phase, b.phase) || (a.ws < b.ws ? -1 : a.ws > b.ws ? 1 : 0));
}

// Fenêtre de stall à source unique : VF_STALL_WINDOW (chiffres, > 0), sinon la seule ligne d'affectation par défaut de
// check-guard-health.sh, ancrée en début de ligne ; sinon null (inconnue, aucune valeur propre).
const LIGNE = /^STALL_WINDOW="\$\{VF_STALL_WINDOW:-(\d+)\}"$/m;
export function fenetreStall({ env = process.env, texteScript } = {}) {
  const e = env && env.VF_STALL_WINDOW;
  if (typeof e === 'string' && /^\d+$/.test(e) && Number(e) > 0) return Number(e);
  const m = typeof texteScript === 'string' ? LIGNE.exec(texteScript) : null;
  return m && Number(m[1]) > 0 ? Number(m[1]) : null;
}

// check-guard-health.sh voisin du driver-lock.sh résolu hors de l'arbre observé (T-67-06) ; null si absent ou résolution refusée.
export function scriptGarde({ scriptsDir, labRoot, home } = {}) {
  const dl = driverLockScript({ scriptsDir, labRoot, home });
  if (!dl.chemin) return null;
  const c = path.join(path.dirname(dl.chemin), 'check-guard-health.sh');
  try { return fs.statSync(c).isFile() ? c : null; } catch { return null; }
}

// « Attend ses agents » : la dernière ligne analysable du transcript décide ; turn_duration avec pendingBackgroundAgentCount
// entier > 0 (plafond 999), toute autre ligne : 0.
export const attendAgents = (fichier) => (cherche(fichier, (d) => {
  if (d.type === 'system' && d.subtype === 'turn_duration') {
    const n = d.pendingBackgroundAgentCount;
    return { n: Number.isInteger(n) && n > 0 ? Math.min(n, 999) : 0 };
  }
  return { n: 0 }; // toute autre ligne : la dernière écriture décide
}) || { n: 0 }).n;
