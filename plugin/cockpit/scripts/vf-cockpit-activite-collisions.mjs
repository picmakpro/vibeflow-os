// vf-cockpit-activite-collisions — les sources « agents » et « plans » du radar de collisions (75-03, ACTV-10 ; P75-D-15, P75-D-24, P75-D-30,
//   P75-D-31).
// Exports : collisionsAgents(voies, contexte), collisionsPlans(plans).
// Tuples : [chemin, 'agents'|'arbres'|'plans', [noms], vagueOuNull] ; la source « branches » (75-01) est jointe par 75-05, jamais ici. Les LECTURES
//   n'entrent jamais.
//   - `arbres` : le même chemin écrit dans deux arbres différents (même fichier logique sur deux branches : conflit de fusion possible), tant que
//   les deux
//     worktrees existent (un worktree absent de `worktreesVerifies` rend ses cibles à la sentinelle, écartée) ; jamais `agents`.
//   - `agents` : le même chemin dans le MÊME arbre par deux voies vivantes en même temps, ni parent ni enfant.
//   - `plans` : deux plans NON faits de la même phase et de la même vague partageant un `files_modified` (« prévu »), `vague` absente : plan compté
//   `sansVague`.
// Seul un chemin qui a une carte est rendu pour les agents (les autres sont comptés `horsCarte`) ; la sentinelle « hors du lab » est comptée
//   `horsLab`.
// `incomplet` : cibles en construction, historique tronqué ou cible coupée / voie dont la liste est coupée — jamais « aucune collision » dans ces
//   cas.
import { rassembler, gardeFilesModified } from './vf-cockpit-activite-chemins.mjs';
import { preparer, raisons } from './vf-cockpit-activite-empreinte.mjs';

const cmp = (a, b) => (a < b ? -1 : a > b ? 1 : 0);
const PROFONDEUR_MAX = 50;

// parent ou enfant (directement ou par ancêtres) : bornée, sans récursion
function liees(a, b, parId) {
  for (const [x, y] of [[a, b], [b, a]]) {
    let id = parId.get(x.id), n = 0;
    while (typeof id === 'string' && n++ < PROFONDEUR_MAX) { if (id === y.id) return true; id = parId.get(id); }
  }
  return false;
}

export function collisionsAgents(voies, contexte = {}) {
  const p = preparer(voies, contexte), entrees = [];
  p.contexteTronque = contexte.friseTronque === true;
  p.retenues.forEach(({ v }, k) => {
    for (const e of v.cibles.ecritures || []) entrees.push({ arbre: e.arbre, cible: e.cible, ref: k }); // garde:collisions-ecritures-seules
  });
  const r = rassembler(entrees, contexte), parChemin = new Map(), parId = new Map();
  for (const { v } of p.retenues) if (typeof v.id === 'string') parId.set(v.id, v.parent);
  for (const g of r.groupes) {
    if (!g.carte) continue;
    let m = parChemin.get(g.chemin);
    if (!m) { m = new Map(); parChemin.set(g.chemin, m); }
    m.set(g.arbre, new Set(g.refs));
  }
  const tuples = [];
  for (const [chemin, arbres] of [...parChemin].sort((a, b) => cmp(a[0], b[0]))) {
    const nomsDe = (ks) => [...ks].map((k) => p.noms[k]).sort(cmp);
    if (arbres.size >= 2) tuples.push([chemin, 'arbres', nomsDe([...arbres.values()].flatMap((s) => [...s])), null]); // garde:collisions-arbres
    const enConflit = new Set();
    for (const ks of arbres.values()) {
      const vifs = [...ks].filter((k) => p.retenues[k].etat === 'vivante'); // garde:collisions-vivantes
      for (const a of vifs) for (const b of vifs) {
        if (a < b && !liees(p.retenues[a].v, p.retenues[b].v, parId)) { enConflit.add(a); enConflit.add(b); } // garde:collisions-parent-enfant
      }
    }
    if (enConflit.size >= 2) tuples.push([chemin, 'agents', nomsDe(enConflit), null]);
  }
  const rs = raisons(p, r.compte);
  return { collisions: tuples, incomplet: rs.length > 0, raisons: rs, horsCarte: r.compte.horsCarte, horsLab: r.compte.horsLab, coupees: r.compte.coupees,
    rejetes: r.compte.rejetes, ignorees: p.ignorees, voiesTronquees: p.voiesTronquees };
}

export const PLANS_MAX = 2000;

// plans : [{ p (chemin du plan), name?, n|phase (la phase), st, vague, touched: [chemins] }] — la projection Projet ; `vague` est posée par la
//   Phase 80
export function collisionsPlans(plans) {
  const liste = Array.isArray(plans) ? plans : [], bornes = liste.slice(0, PLANS_MAX);
  const r = { collisions: [], sansVague: 0, rejetes: 0, plansTronques: liste.length > bornes.length };
  const groupes = new Map(); // phase -> vague -> chemin -> [noms]
  for (const x of bornes) {
    if (!x || typeof x !== 'object' || x.st === 'done' || !Array.isArray(x.touched)) continue; // un plan fait est exclu
    if (!Number.isFinite(x.vague) && typeof x.vague !== 'string') { r.sansVague++; continue; } // jamais « vague ? » devinée
    const phase = x.phase ?? x.n ?? null, nom = typeof x.name === 'string' ? x.name : String(x.p ?? '').split('/').pop();
    let parVague = groupes.get(phase); if (!parVague) { parVague = new Map(); groupes.set(phase, parVague); }
    let parChemin = parVague.get(x.vague); if (!parChemin) { parChemin = new Map(); parVague.set(x.vague, parChemin); } // garde:collisions-vague
    for (const f of new Set(x.touched)) {
      if (!gardeFilesModified(f)) { r.rejetes++; continue; }
      const l = parChemin.get(f) || []; l.push([String(x.p ?? nom), nom]); parChemin.set(f, l);
    }
  }
  for (const parVague of groupes.values()) for (const [vague, parChemin] of parVague) for (const [chemin, plansDe] of parChemin) {
    if (new Set(plansDe.map((q) => q[0])).size >= 2) r.collisions.push([chemin, 'plans', plansDe.map((q) => q[1]).sort(cmp), vague]);
  }
  r.collisions.sort((a, b) => cmp(a[0], b[0]) || cmp(String(a[3]), String(b[3])));
  return r;
}
