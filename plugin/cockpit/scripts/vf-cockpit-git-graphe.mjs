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

// ---- placement en couloirs : un passage, enfants avant parents, O(n x L), sans récursion ----
// sortants : arêtes vers un parent, SAUF la suite droite du premier parent dans le couloir de la rangée (champ `suite`).
export function placer(commits, { couloirsMax = 6 } = {}) {
  const lanes = [], origine = [], rangees = [];
  let racines = 0, vus = 0;
  const libre = () => { const k = lanes.indexOf(null); return k < 0 ? lanes.length : k; };
  for (const c of commits) {
    let col = lanes.indexOf(c.h);
    const entrants = col < 0 ? [] : [col];
    if (col < 0) col = libre();
    const sortants = [];
    let suite = false;
    if (c.p.length === 0) { lanes[col] = null; /* LIBERE-RACINE */ racines++; }
    else {
      const k0 = lanes.indexOf(c.p[0]);
      if (k0 < 0) { lanes[col] = c.p[0]; origine[col] = rangees.length; suite = true; }
      else { lanes[col] = null; sortants.push({ de: col, vers: k0, parent: c.p[0] }); }
      for (let i = 1; i < c.p.length; i++) {
        let k = lanes.indexOf(c.p[i]);
        if (k < 0) { k = libre(); lanes[k] = c.p[i]; origine[k] = rangees.length; }
        sortants.push({ de: col, vers: k, parent: c.p[i] });
      }
    }
    vus = Math.max(vus, lanes.length, col + 1);
    rangees.push({ h: c.h, col, entrants, sortants, largeur: Math.max(lanes.length, col + 1), ouvertBas: [], fusion: c.p.length > 1, racine: c.p.length === 0, suite });
    while (lanes.length && lanes[lanes.length - 1] === null) lanes.pop();
  }
  let ouvertsEnBas = 0;
  lanes.forEach((sha, k) => { if (sha !== null) { rangees[origine[k]].ouvertBas.push(k); ouvertsEnBas++; } });
  const m = Math.max(1, Math.floor(couloirsMax)), cl = (k) => Math.min(k, m - 1);
  let replies = 0;
  for (const r of rangees) {
    const tous = [r.col, ...r.entrants, ...r.ouvertBas, ...r.sortants.flatMap((s) => [s.de, s.vers])];
    if (r.largeur > m || tous.some((k) => k >= m)) replies++;
    r.col = cl(r.col); r.largeur = Math.min(r.largeur, m);
    r.entrants = r.entrants.map(cl); r.ouvertBas = r.ouvertBas.map(cl);
    r.sortants = r.sortants.map((s) => ({ de: cl(s.de), vers: cl(s.vers), parent: s.parent }));
  }
  return { rangees, couloirsMax: m, couloirsVus: vus, ouvertsEnBas, racines, replies };
}

// ---- étiquettes : regroupées par sha, ordre HEAD, locales, distantes, tags, puis nom (points de code) ----
const PREFIXES = [['refs/heads/', 'locale'], ['refs/remotes/', 'distante'], ['refs/tags/', 'tag']];
const RANG = { head: 0, locale: 1, distante: 2, tag: 3 };
function pointsDeCode(a, b) {
  const x = Array.from(a), y = Array.from(b);
  for (let i = 0; i < Math.min(x.length, y.length); i++) { const d = x[i].codePointAt(0) - y[i].codePointAt(0); if (d) return d; }
  return x.length - y.length;
}
const comparer = (a, b) => RANG[a.type] - RANG[b.type] || pointsDeCode(a.nom, b.nom) || Number(b.courante) - Number(a.courante);
export function etiquettes(refs, { head = null, worktrees = [] } = {}) {
  const chemins = new Map(worktrees.filter((w) => w.branche).map((w) => [w.branche, w.chemin]));
  const parRef = new Map(refs.map((r) => [r.ref, r]));
  const courante = typeof head === 'string' && head.startsWith('refs/') ? head : null;
  const tete = courante ? (parRef.get(courante)?.sha ?? null) : typeof head === 'string' ? head : null;
  const groupes = new Map();
  const ajouter = (sha, e) => { if (!groupes.has(sha)) groupes.set(sha, []); groupes.get(sha).push(e); };
  for (const r of refs) {
    const pre = PREFIXES.find(([p]) => r.ref.startsWith(p));
    if (!pre) continue;
    ajouter(r.pelee || r.sha, { type: pre[1], nom: r.ref.slice(pre[0].length), courante: r.ref === courante, worktree: chemins.get(r.ref) ?? null });
  }
  if (tete) ajouter(tete, { type: 'head', nom: 'HEAD', courante: true, worktree: null });
  const sortie = new Map();
  for (const sha of [...groupes.keys()].sort()) {
    const liste = groupes.get(sha);
    liste.sort(comparer); // TRI-ETIQUETTES
    sortie.set(sha, liste);
  }
  return sortie;
}

// ---- teinte : empreinte FNV-1a stable du nom de la ref de tête, 1 à 5 (0 réservé à la branche de base) ----
export function teinte(nom) {
  let h = 0x811c9dc5;
  for (const c of String(nom ?? '')) h = Math.imul(h ^ c.codePointAt(0), 0x01000193);
  return 1 + ((h >>> 0) % 5);
}
