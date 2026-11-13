// vf-cockpit-activite-branches — collisions COMMITTÉES entre branches, par paire de HEAD distincts de worktrees vérifiés (Phase 75, plan 75-01 ;
//   ACTV-10 ; P75-D-10, P75-D-11, P78-D-38). LECTURE SEULE.
// Exports : PLAFOND_TETES, collisionsBranches(lab, { worktrees, plafond, fin, cache }) -> { etat, tetes, plafond, plafondAtteint,
//   collisions: [[chemin, [branche, ...]]] } | { etat: 'indisponible' | 'absent' }.
// Par paire de HEAD (A, B) : base = meilleur ancêtre commun, puis `diff-tree -r --no-renames --name-only -z <base> <tête>` de chaque côté,
//   intersection. La base unique `main` est écartée
// (319 fausses collisions mesurées sur 9 worktrees partis de la même branche d'intégration). Jamais `status` ni `diff` contre l'arbre de travail : le
//   non-committé passe par l'empreinte des agents (P75-D-12).
// A-04 : `merge-base` n'est pas dans la liste fermée des sous-commandes du socle (vf-cockpit-git-durci.mjs) ; la base se lit par `rev-list --boundary
//   A...B` (les commits exclus qui bordent la différence
// symétrique sont les ancêtres communs les plus proches), les candidats qui descendent l'un de l'autre sont départagés par `rev-list --count`.
// Tout git passe par `lancerGitAsync`. Chemins comparés BRUTS, rendus relatifs au LAB (préfixe `rev-parse --show-prefix` retiré, fichiers hors du
//   sous-dossier ignorés) ; noms de branche et de fichier
// ne sont jamais des clés d'objet (tuples seulement). Erreur, délai, sortie tronquée ou désalignée : { etat: 'indisponible' } sur la source seule,
//   jamais un résultat partiel.
import path from 'node:path';
import { lancerGitAsync, finDans } from './vf-cockpit-git-lanceur.mjs';
import { MOTIF_SHA, lireWorktrees } from './vf-cockpit-git-graphe.mjs';
import { worktreeVerifie } from './vf-cockpit-git-details.mjs';

export const PLAFOND_TETES = 12; // 12 HEAD = 66 paires
const ECHEANCE_MS = 15000, CACHE_MAX = 2000;
// paire de sha triée -> fichiers modifiés des deux côtés (chemins du dépôt) ; un sha désigne un historique immuable, la clé ne dépend ni du lab ni des noms
const CACHE = new Map();
const cmp = (a, b) => (a < b ? -1 : a > b ? 1 : 0);
const raison = (r) => (r.delai || r.tronque ? 'indisponible' : r.absent || r.refuse || r.code === 128 || r.code === null ? 'absent' : 'indisponible');
const etiquette = (w) => (w.branche ? w.branche.replace(/^refs\/heads\//, '') : path.basename(w.chemin));

// sortie de `diff-tree -z --name-only` : noms terminés par NUL, aucun nom vide ; null = désalignée
const lireNoms = (sortie) => {
  if (typeof sortie !== 'string' || (sortie !== '' && !sortie.endsWith('\0'))) return null;
  const n = sortie.split('\0'); n.pop();
  return n.some((p) => p === '') ? null : n;
};

// '' : aucun ancêtre commun (historiques sans rapport : aucune collision n'est affirmée) ; null : lecture en échec
async function baseCommune(lire, a, b) {
  const r = await lire(['rev-list', '--boundary', `${a}...${b}`, '--']);
  if (!r.ok) return null;
  const cand = r.sortie.split('\n').filter((l) => l.startsWith('-')).map((l) => l.slice(1));
  if (cand.some((s) => !MOTIF_SHA.test(s))) return null;
  if (cand.length <= 1) return cand[0] ?? '';
  const gardes = [];
  for (const x of cand) {
    let descendu = false; // x est ancêtre d'un autre candidat : pas la meilleure base
    for (const y of cand) {
      if (y === x) continue;
      const q = await lire(['rev-list', '--count', `${y}..${x}`, '--']);
      if (!q.ok) return null;
      if (q.sortie.trim() === '0') descendu = true;
    }
    if (!descendu) gardes.push(x);
  }
  return gardes.sort(cmp)[0] ?? '';
}

const fichiers = async (lire, base, tete) => {
  const r = await lire(['diff-tree', '-r', '--no-renames', '--name-only', '-z', base, tete]);
  return r.ok && !r.tronque ? lireNoms(r.sortie) : null;
};

// fichiers (chemins du dépôt, bruts) modifiés des deux côtés depuis la base ; null = lecture en échec
async function paire(lire, a, b) {
  const base = await baseCommune(lire, a, b);
  if (base === null) return null;
  if (base === '') return [];
  const fa = await fichiers(lire, base, a);
  if (fa === null) return null;
  const fb = await fichiers(lire, base, b);
  if (fb === null) return null;
  const sb = new Set(fb);
  return fa.filter((p) => sb.has(p));
}

export async function collisionsBranches(lab, { worktrees, plafond = PLAFOND_TETES, fin = finDans(ECHEANCE_MS), cache = CACHE } = {}) {
  const lire = (args) => lancerGitAsync(lab, args, { fin, maxBuffer: 16 << 20 });
  const cm = await lire(['rev-parse', '--path-format=absolute', '--git-common-dir']);
  if (!cm.ok) return { etat: raison(cm) };
  const pf = await lire(['rev-parse', '--show-prefix']);
  if (!pf.ok) return { etat: raison(pf) };
  const prefixe = pf.sortie.replace(/\n$/, '');
  let liste = worktrees;
  if (!Array.isArray(liste)) {
    const w = await lire(['worktree', 'list', '--porcelain', '-z']);
    if (!w.ok) return { etat: raison(w) };
    const lu = lireWorktrees(w.sortie);
    if (!lu.ok) return { etat: 'indisponible' };
    liste = lu.worktrees;
  }
  // un HEAD par commit : deux worktrees au même HEAD comptent pour un ; seuls les worktrees dont le lien retour est vérifié (P78-D-38) entrent dans
  //   une paire
  const parTete = new Map();
  for (const w of liste) {
    if (w.nu || !MOTIF_SHA.test(w.head) || parTete.has(w.head) || !worktreeVerifie(cm.sortie.trim(), w.chemin)) continue;
    parTete.set(w.head, etiquette(w));
  }
  const tetes = [...parTete.keys()], retenues = tetes.slice(0, plafond), coll = new Map();
  for (let i = 0; i < retenues.length; i++) {
    for (let j = i + 1; j < retenues.length; j++) {
      const x = retenues[i], y = retenues[j], cle = x < y ? `${x}\0${y}` : `${y}\0${x}`;
      let f = cache.get(cle);
      if (!f) {
        f = await paire(lire, x, y);
        if (f === null) return { etat: 'indisponible' };
        if (cache.size >= CACHE_MAX) cache.delete(cache.keys().next().value);
        cache.set(cle, f);
      }
      for (const p of f) {
        if (prefixe && !p.startsWith(prefixe)) continue;
        const c = prefixe ? p.slice(prefixe.length) : p;
        if (!coll.has(c)) coll.set(c, new Set());
        coll.get(c).add(parTete.get(x)).add(parTete.get(y));
      }
    }
  }
  const collisions = [...coll].map(([p, s]) => [p, [...s].sort(cmp)]).sort((a, b) => cmp(a[0], b[0]));
  return { etat: 'ok', tetes: tetes.length, plafond, plafondAtteint: tetes.length > plafond, collisions };
}
