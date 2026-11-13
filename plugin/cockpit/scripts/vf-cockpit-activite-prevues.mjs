// vf-cockpit-activite-prevues — cartes « prévues » du graphe Code (ACTV-11, P75-D-18, AUDC-I36) : les fichiers que les plans NON faits vont créer.
// Annotateur du graphe Code (table de vf-cockpit-build.mjs, A27) : il tourne APRÈS la construction du graphe par le moteur et à chaque assemblage,
// modifie `g` en mémoire, jamais le scan (Santé compterait les prévues « inutilisées ») ni les statistiques de nœud du moteur.
// Exports : PLAFOND, annoterPrevues(g, ctx), nommerPlans(ids).
// ctx : { lab (racine du lab), project (graphe Projet : files[] {p, st, touched, touchedIgnores}), architecture (architecture.json lu),
//   sortie (à défaut d'architecture : <sortie>/architecture.json), maintenant (Date, essai) }.
// Carte : { p, n, r, l: 'prevu', loc: 0, name, d: 'Créé par le plan <id>', st: 'prevu', prevuPar: [ids triés] } ; `st: 'prevu'` est le marqueur que lit
//   calculerGardes (75-02) pour ne pas compter la carte comme du code sans témoin. Ni « ouvrir » ni « taille » : ni loc, ni description automatique.
// Chemins : forme jugée par gardeFilesModified (75-03) ; absolu, `..`, contrôle, > 4 096 octets, sous .planning/, hors du lab (résolution physique du
//   noyau, cheminPhysique de 79-07), dossier : ignorés ET COMPTÉS (meta.prevusIgnores) ; un chemin qui existe sous le lab (même ignoré par git, même un
//   doc) : aucune carte.
// Fraîcheur : la carte suit l'assemblage ; meta.vfPrevuAt (ISO) le dit, un changement de .planning/ seul ne reconstruit pas le graphe Code.
// Rattachement : la règle du moteur, UNE fois, dans lib/common.mjs (regleDeNoeuds, rattacher) — scripts/ et skills/ sont frères sous la racine du module.
import fs from 'node:fs';
import path from 'node:path';
import { cheminPhysique } from './vf-cockpit-git-sortant.mjs';
import { gardeFilesModified } from './vf-cockpit-activite-chemins.mjs';
// le moteur est le voisin du module (scripts/ et skills/ sont frères sous la racine) ; une copie des seuls scripts (essais) ne l'a pas : la règle est alors
// absente, ce que l'annotateur ne dit qu'au moment d'en avoir besoin (une carte à rattacher), jamais par un rattachement deviné
const moteur = await import('../skills/cockpit-moteur/scripts/lib/common.mjs').catch(() => null);

export const PLAFOND = 500; // cartes prévues par assemblage ; l'excédent est compté
const CANDIDATS_MAX = 20000; // chemins examinés (une résolution physique chacun) ; au-delà, comptés sans examen
const ID_PLAN = /^[A-Za-z0-9][A-Za-z0-9._-]{0,39}$/;
const octets = (a, b) => Buffer.compare(Buffer.from(a), Buffer.from(b));

export const nommerPlans = (ids) => (ids.length === 1 ? `Créé par le plan ${ids[0]}`
  : `Créé par les plans ${ids.slice(0, -1).join(', ')} et ${ids[ids.length - 1]}`);

const idDuPlan = (p) => { // « …/75-06-PLAN.md » -> « 75-06 » ; ce qui n'est pas un fichier de plan (nœud de DAG, exigence…) -> null
  if (typeof p !== 'string') return null;
  const nom = p.slice(p.lastIndexOf('/') + 1);
  const id = nom.endsWith('-PLAN.md') ? nom.slice(0, -8) : null;
  return id !== null && ID_PLAN.test(id) ? id : null;
};

const lireArchitecture = (sortie) => {
  try { return JSON.parse(fs.readFileSync(path.join(sortie, 'architecture.json'), 'utf8')); } catch { return null; }
};

// la forme normalisée d'un chemin de plan (relatif au lab, sans « ./ » ni « // »), ou null : à ignorer et compter
function forme(c) {
  if (typeof c !== 'string' || !gardeFilesModified(c)) return null;
  const n = path.posix.normalize(c);
  if (n === '.' || n.endsWith('/') || n === '.planning' || n.startsWith('.planning/') || n.startsWith('../')) return null;
  return n;
}

// 'existe' : une entrée du lab (jugée par le noyau, jamais par un lstat brut) · 'prevu' : absent, mais son plus proche parent résolu est dans le lab
// · 'ignore' : ne se résout pas (lien pendant, boucle, droits) ou sort du lab
function etat(lab, labPhys, n) {
  const abs = path.join(lab, n);
  if (cheminPhysique(abs) !== null) return 'existe';
  const proche = cheminPhysique(abs, { plusProcheParent: true });
  return proche !== null && (proche === labPhys || proche.startsWith(labPhys + path.sep)) ? 'prevu' : 'ignore';
}

export function annoterPrevues(g, ctx = {}) {
  const { lab, project } = ctx;
  const meta = g.meta || (g.meta = {});
  const arch = ctx.architecture !== undefined ? ctx.architecture : (ctx.sortie ? lireArchitecture(ctx.sortie) : null);
  const labPhys = typeof lab === 'string' ? cheminPhysique(lab) : null;
  const vus = new Set((g.files || []).map((f) => f && f.p));
  const voulus = new Map(); // chemin normalisé -> Set d'identifiants de plans non faits
  let ignores = 0;
  for (const f of (project && project.files) || []) {
    const id = idDuPlan(f && f.p);
    if (id === null || (f.st !== 'todo' && f.st !== 'active')) continue; // un plan fait ne crée plus rien
    if (Number.isInteger(f.touchedIgnores) && f.touchedIgnores > 0) ignores += f.touchedIgnores; // écartés plus haut (75-04) : comptés ici aussi
    for (const c of Array.isArray(f.touched) ? f.touched : []) {
      const n = forme(c);
      if (n === null) { ignores++; continue; }
      if (!voulus.has(n)) voulus.set(n, new Set());
      voulus.get(n).add(id);
    }
  }
  const cartes = [];
  let regle = null; // construite à la première carte
  const repo = Array.isArray(meta.repos) && meta.repos.length === 1 && meta.repos[0] ? (meta.repos[0].path ?? null) : null;
  let examines = 0;
  for (const n of [...voulus.keys()].sort(octets)) {
    if (vus.has(n)) continue;
    if (labPhys === null || ++examines > CANDIDATS_MAX) { ignores++; continue; }
    const e = etat(lab, labPhys, n);
    if (e === 'ignore') ignores++;
    if (e !== 'prevu') continue;
    const prevuPar = [...voulus.get(n)].sort(octets);
    if (!regle) {
      if (!moteur) throw new Error('règle de rattachement du moteur introuvable (skills/cockpit-moteur absent à côté de scripts/)');
      regle = moteur.regleDeNoeuds(Array.isArray(arch && arch.nodes) ? arch.nodes : []);
    }
    cartes.push({ p: n, n: moteur.rattacher(regle, n).id, r: repo, l: 'prevu', loc: 0, name: path.posix.basename(n),
      d: nommerPlans(prevuPar), st: 'prevu', prevuPar });
  }
  ignores += Math.max(0, cartes.length - PLAFOND);
  const gardees = cartes.slice(0, PLAFOND);
  if (gardees.some((c) => c.n === 'unassigned')) {
    g.nodes = g.nodes || [];
    if (!g.nodes.some((x) => x && x.id === 'unassigned')) { // jamais une carte vers un nœud absent ; sans statistique de fichier : la prévue n'est pas comptée
      g.nodes.push({ id: 'unassigned', parent: null, label: 'Unassigned', kind: 'misc', details: '', tags: [], paths: [], packages: [], hosts: [],
        summary: 'Files no node claims. Add globs in architecture.json to place them.', stats: { files: 0, loc: 0, langs: {}, repos: [] } });
    }
  }
  g.files = [...(g.files || []), ...gardees];
  meta.vfPrevuAt = (ctx.maintenant instanceof Date ? ctx.maintenant : new Date()).toISOString();
  meta.prevusIgnores = ignores;
  return gardees.length;
}
