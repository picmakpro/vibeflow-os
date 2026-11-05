// vf-cockpit-git-graphe.mjs — sorties git -> graphe, en JS pur (Phase 78, GITC-06 ; P78-D-22, P78-D-23).
// Module pur : aucun appel à git ici (ils sont au module serveur), aucune exception levée sur une entrée inattendue,
// tout écart d'alignement rend { ok: false, raison }. Placement des couloirs maison, déterministe, sans ELK.

export const FORMAT_JOURNAL = '%H%x00%P%x00%at%x00%an%x00%s';
export const MOTIF_SHA = /^[0-9a-f]{40}$/;
const ENTIER = /^[0-9]+$/;
const ko = (raison) => ({ ok: false, raison });

// ---- journal : `git log -z --format=FORMAT_JOURNAL`, 5 champs par commit, terminés par NUL ----
export function lireJournal(sortie, { motif = MOTIF_SHA } = {}) {
  if (typeof sortie !== 'string') return ko('sortie absente');
  const j = sortie.split('\0');
  const n = j.length - 1;
  if (j[n] !== '' || n % 5 !== 0) return ko('sortie désalignée'); // GARDE-ALIGNEMENT
  const commits = [];
  for (let i = 0; i + 5 <= n; i += 5) {
    const [h, ps, at, an, s] = j.slice(i, i + 5);
    const p = ps === '' ? [] : ps.split(' ');
    if (!motif.test(h) || !p.every((x) => motif.test(x)) || !ENTIER.test(at)) return ko('paquet ' + i / 5 + ' mal formé');
    commits.push({ h, p, at: Number(at), an, s });
  }
  return { ok: true, commits };
}

// ---- refs : une ligne par ref, champs séparés par NUL, nombre exact ----
export const CHAMPS_REFS = ['ref', 'sha', 'pelee', 'date'];
export function lireRefs(sortie, { champs = CHAMPS_REFS, motif = MOTIF_SHA } = {}) {
  if (typeof sortie !== 'string') return ko('sortie absente');
  if (sortie === '') return { ok: true, refs: [] };
  if (!sortie.endsWith('\n')) return ko('dernière ligne coupée');
  const refs = [];
  for (const ligne of sortie.slice(0, -1).split('\n')) {
    const f = ligne.split('\0');
    if (f.length !== champs.length || !f[0].startsWith('refs/')) return ko('ligne de refs désalignée');
    const o = {};
    for (let i = 0; i < champs.length; i++) {
      const nom = champs[i], v = f[i];
      if (nom === 'sha' && !motif.test(v)) return ko('sha de ref mal formé');
      if (nom === 'pelee' && v !== '' && !motif.test(v)) return ko('sha pelé mal formé');
      if (nom === 'date' && !ENTIER.test(v)) return ko('date de ref mal formée');
      o[nom] = nom === 'date' ? Number(v) : v;
    }
    refs.push(o);
  }
  return { ok: true, refs };
}

// ---- worktrees : `worktree list --porcelain -z`, champs NUL, enregistrements séparés par un champ vide ----
export function lireWorktrees(sortie, { motif = MOTIF_SHA } = {}) {
  if (typeof sortie !== 'string' || !sortie.endsWith('\0\0')) return ko('sortie des worktrees coupée');
  const worktrees = [];
  for (const rec of sortie.slice(0, -2).split('\0\0')) {
    const champs = rec.split('\0');
    if (!champs[0].startsWith('worktree ') || champs[0].length < 10) return ko('enregistrement de worktree désaligné');
    const w = { chemin: champs[0].slice(9), head: '', branche: null, detache: false, nu: false, verrouille: false };
    for (const c of champs.slice(1)) {
      if (c.startsWith('HEAD ')) { w.head = c.slice(5); if (!motif.test(w.head)) return ko('HEAD de worktree mal formé'); }
      else if (c.startsWith('branch ')) w.branche = c.slice(7);
      else if (c === 'detached') w.detache = true;
      else if (c === 'bare') w.nu = true;
      else if (c === 'locked' || c.startsWith('locked ')) w.verrouille = true;
    }
    worktrees.push(w);
  }
  return { ok: true, worktrees };
}

// ---- fusion topologique : enfants avant parents, date décroissante puis sha ; indépendante de l'ordre d'entrée ----
const avant = (a, b) => (a.at !== b.at ? a.at > b.at : a.h < b.h);
function pousser(tas, c) {
  let i = tas.push(c) - 1;
  while (i > 0) { const pere = (i - 1) >> 1; if (!avant(tas[i], tas[pere])) break; [tas[i], tas[pere]] = [tas[pere], tas[i]]; i = pere; }
}
function retirer(tas) {
  const tete = tas[0], fin = tas.pop();
  if (tas.length) {
    tas[0] = fin;
    for (let i = 0; ;) {
      let m = i; const g = 2 * i + 1, d = g + 1;
      if (g < tas.length && avant(tas[g], tas[m])) m = g;
      if (d < tas.length && avant(tas[d], tas[m])) m = d;
      if (m === i) break;
      [tas[i], tas[m]] = [tas[m], tas[i]]; i = m;
    }
  }
  return tete;
}
export function ordonner(listes) {
  const par = new Map();
  for (const l of listes) for (const c of l) if (!par.has(c.h)) par.set(c.h, c);
  const enfants = new Map([...par.keys()].map((h) => [h, 0]));
  for (const c of par.values()) for (const p of new Set(c.p)) if (par.has(p)) enfants.set(p, enfants.get(p) + 1);
  const tas = [], sortie = [];
  for (const c of par.values()) if (enfants.get(c.h) === 0) pousser(tas, c);
  while (tas.length) {
    const c = retirer(tas);
    sortie.push(c);
    for (const p of new Set(c.p)) {
      if (!par.has(p)) continue;
      const reste = enfants.get(p) - 1;
      enfants.set(p, reste);
      if (reste === 0) pousser(tas, par.get(p));
    }
  }
  if (sortie.length < par.size) { // entrée cyclique (forgée) : rien n'est perdu, ordre canonique
    const vus = new Set(sortie.map((c) => c.h));
    sortie.push(...[...par.values()].filter((c) => !vus.has(c.h)).sort((a, b) => (avant(a, b) ? -1 : 1)));
  }
  return sortie;
}

