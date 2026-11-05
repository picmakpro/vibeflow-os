// vf-cockpit-git — topologie Git du lab pour le tiroir (78-05 ; GITC-05, 06, 08, 09, 10 ; P78-D-05, D-07, D-13, D-14, D-23). LECTURE SEULE.
// Exports : BORNES, lireGit(lab) -> objet vibeflow/cockpit-git@1, routeGit(req, res, url, { root, json }) -> true si la route est traitée.
//   GET /api/vf/git         graphe placé en couloirs, worktrees, mergées repliées, tags, stash, auteurs (ceux de la fenêtre lue), refsIgnorees (refs sans date écartées)
//   GET /api/vf/git/entete  { schema: 'vibeflow/cockpit-git-entete@1', ...enteteGit }
//   GET /api/vf/git/commit?sha=<40 hexa>  détail d'un commit sans diff (78-08, vf-cockpit-git-details.mjs) ; GET /api/vf/git/worktrees  état de chaque worktree, à la demande
// Seul point de lancement de git : lancerGit (vf-cockpit-paths.mjs : environnement durci, sortie tronquée signalée). Aucune sous-commande réseau ni d'écriture.
// Toute chaîne servie passe par nettoie ; une COMMANDE à copier n'y passe jamais (P78-D-27) : elle est servie telle quelle, ou null si un nom
// ressemble à un secret (masque(nom) !== nom). Refs passées à `log` : entièrement qualifiées (refs/…) ou sha de 40 caractères, jamais --all.
import fs from 'node:fs';
import path from 'node:path';
import { lancerGit, avecEcheance } from './vf-cockpit-paths.mjs';
import { nettoie, brancheBase } from './vf-cockpit-arbres.mjs';
import { masque } from './vf-cockpit-lecture.mjs';
import { enteteGit } from './vf-cockpit-git-entete.mjs';
import { detailCommit, etatWorktrees } from './vf-cockpit-git-details.mjs';
import { FORMAT_JOURNAL, CHAMPS_REFS, MOTIF_SHA, lireJournal, lireRefs, lireWorktrees, ordonner, placer, etiquettes, teinte } from './vf-cockpit-git-graphe.mjs';
import { cmdCd, cmdSwitch, cmdBranchSupprimer, cmdStashShow, cmdCommitInitial, cmdStatus } from './vf-cockpit-git-commandes.mjs';

export const BORNES = { base: 500, nonMergees: 500, tags: 200, stash: 50, refs: 2000, nom: 200, echeanceMs: 5000 };
const SCHEMA = 'vibeflow/cockpit-git@1', SCHEMA_ENTETE = 'vibeflow/cockpit-git-entete@1';
const SCHEMAS_ROUTES = { '/api/vf/git/entete': SCHEMA_ENTETE, '/api/vf/git/commit': 'vibeflow/cockpit-git-commit@1', '/api/vf/git/worktrees': 'vibeflow/cockpit-git-worktrees@1' };
const NUL = /^0+$/;
const net = (s) => nettoie(s, BORNES.nom);
const reel = (p) => { try { return fs.realpathSync(p); } catch { return path.resolve(p); } };
// commande à copier : jamais nettoyée ni masquée ; null si un des noms qui la composent serait masqué à l'affichage (la copie ne dirait pas ce que l'écran dit)
const commande = (cmd, ...noms) => (cmd !== null && noms.every((n) => masque(n) === n) ? cmd : null);

export function lireGit(lab) {
  try { return avecEcheance(BORNES.echeanceMs, () => assembler(lab)); } catch { return { schema: SCHEMA, etat: 'indisponible' }; }
}

const refLog = (r) => r.ref; // REF-QUALIFIEE : jamais un nom court (« -x » serait lu comme une option)
const court = (ref) => ref.replace(/^refs\/(heads|remotes)\//, '');
const compte = (s) => { const m = /^(\d+) (\d+)$/.exec(s ?? ''); return m ? { avance: Number(m[1]), retard: Number(m[2]) } : null; };
const brancheStash = (gs) => /^(?:WIP on|On) ([^:]+): /.exec(gs)?.[1]; // « On main: msg » ou « WIP on main: abc1234 msg »
const sansFormat = (r) => !!r && !/[%)]/.test(r); // un nom de ref ne s'insère dans %(ahead-behind:…) que s'il ne peut pas casser le format

// `stash list -z --format=%gd%x00%H%x00%ct%x00%gs` : 4 champs par entrée, terminés par NUL ; tout désalignement rend { ok: false }
function lireStash(sortie) {
  const j = sortie.split('\0'), n = j.length - 1, ko = { ok: false };
  if (j[n] !== '' || n % 4 !== 0) return ko;
  const stash = [];
  for (let i = 0; i < n; i += 4) {
    const [ref, h, ct, gs] = j.slice(i, i + 4);
    if (!/^stash@\{\d{1,4}\}$/.test(ref) || !MOTIF_SHA.test(h) || !/^\d+$/.test(ct)) return ko;
    stash.push({ ref, h, at: Number(ct), gs });
  }
  return { ok: true, stash };
}

// `for-each-ref` : une ligne par ref, 4e champ = date. Une date vide (tag vers un blob ou un arbre) écarte la ligne ; une ligne désalignée reste, `lireRefs` la refuse comme avant.
function sansDate(sortie) {
  const gardees = []; let ignorees = 0;
  for (const l of sortie.split('\n')) {
    if (l === '') continue;
    const f = l.split('\0');
    if (f.length >= 4 && f[0].startsWith('refs/') && f[3] === '') ignorees++; else gardees.push(l);
  }
  return { sortie: gardees.length ? gardees.join('\n') + '\n' : '', ignorees };
}

function assembler(lab) {
  const entete = enteteGit(lab);
  const commandes = (vide = null) => ({ vide, diagnostic: cmdStatus() });
  if (entete.etat === 'absent') return { schema: SCHEMA, etat: 'absent', entete };
  const ko = () => ({ schema: SCHEMA, etat: 'indisponible', entete, commandes: commandes() });
  const git = (...a) => lancerGit(lab, a);
  const nomBase = brancheBase(lab);
  const rb = git('for-each-ref', '--format=%(refname)', ...(nomBase ? [`refs/heads/${nomBase}`, `refs/remotes/origin/${nomBase}`] : []));
  const presentes = new Set(nomBase && rb.ok ? rb.sortie.split('\n') : []);
  const locale = `refs/heads/${nomBase}`, distante = `refs/remotes/origin/${nomBase}`;
  const refBase = presentes.has(locale) ? locale : presentes.has(distante) ? distante : null;
  const refOrigine = presentes.has(locale) && presentes.has(distante) ? distante : null;

  // un seul for-each-ref : refs, cible peelée, date, et le retard sur la base locale (puis sur origin/<base> quand elle existe) ; refusé par git (version, tag vers un arbre) : repli rev-list
  const avecAB = sansFormat(refBase) && (!refOrigine || sansFormat(refOrigine));
  const champs = [...CHAMPS_REFS, ...(avecAB ? ['ab', ...(refOrigine ? ['ab2'] : [])] : [])];
  const fmt = (ab) => '%(refname)%00%(objectname)%00%(*objectname)%00%(creatordate:unix)' + (ab ? `%00%(ahead-behind:${refBase})` + (refOrigine ? `%00%(ahead-behind:${refOrigine})` : '') : '');
  const motifs = ['refs/heads', 'refs/remotes', 'refs/tags'];
  let fer = git('for-each-ref', `--format=${fmt(avecAB)}`, ...motifs), repli = false;
  if (!fer.ok && avecAB) { repli = true; fer = git('for-each-ref', `--format=${fmt(false)}`, ...motifs); }
  const sd = fer.ok ? sansDate(fer.sortie) : { sortie: '', ignorees: 0 }; // P78-D-31 : une ref sans date (blob, arbre) est écartée et comptée, le reste du graphe est lu
  const lr = fer.ok ? lireRefs(sd.sortie, { champs: repli || !avecAB ? CHAMPS_REFS : champs }) : { ok: false };
  const wl = git('worktree', 'list', '--porcelain', '-z');
  const lw = wl.ok ? lireWorktrees(wl.sortie) : { ok: false };
  if (!lr.ok || !lw.ok) return ko();
  const refs = lr.refs.filter((r) => !/^refs\/remotes\/[^/]+\/HEAD$/.test(r.ref));
  const tronqueRefs = refs.length > BORNES.refs; refs.length = Math.min(refs.length, BORNES.refs);
  const worktrees = lw.worktrees;
  const branches = refs.filter((r) => r.ref.startsWith('refs/heads/') || r.ref.startsWith('refs/remotes/'));
  const estBase = (r) => r.ref === refBase;
  const gaucheDroite = (x, y) => { const r = git('rev-list', '--left-right', '--count', '--end-of-options', `${x}...${y}`); const m = /^(\d+)\t(\d+)\n$/.exec(r.sortie); return m ? [m[1], m[2]] : null; }; // [seulement à gauche, seulement à droite]
  if (repli && refBase) { // au plus 50 branches comptées, les autres sans compte (traitées comme non mergées)
    for (const r of branches.filter((x) => !estBase(x)).slice(0, 50)) { const c = gaucheDroite(refBase, r.ref); if (c) r.ab = `${c[1]} ${c[0]}`; }
    const b = refs.find(estBase), c = refOrigine && b ? gaucheDroite(refBase, refOrigine) : null;
    if (c) b.ab2 = `${c[0]} ${c[1]}`;
  }
  const avance = (r) => compte(r.ab)?.avance ?? null;

  // worktree « ici » : celui dont le chemin est le plus long préfixe du lab
  const labReel = reel(lab);
  const sous = (c) => labReel === reel(c) || labReel.startsWith(reel(c) + path.sep);
  const ici = worktrees.filter((w) => sous(w.chemin)).sort((a, b) => b.chemin.length - a.chemin.length)[0] || null;
  const head = ici ? (ici.branche || ici.head) : null;
  const enWorktree = new Set(worktrees.map((w) => w.branche).filter(Boolean));
  const shaRef = (r) => refs.find((x) => x.ref === r)?.sha ?? null;
  const tetes = [...new Set(worktrees.map((w) => w.head).filter((h) => h && !NUL.test(h)))];
  const racineLog = refBase || tetes[0] || null;
  if (!racineLog) return { schema: SCHEMA, etat: 'vide', entete, commandes: commandes(cmdCommitInitial()) };

  // non mergées : avance > 0 sur la base (origin/<base> comprise) ; mergées : avance 0, repliées en liste (ni étiquette ni rangée propre)
  const nonMergees = branches.filter((r) => !estBase(r) && (refBase ? (avance(r) ?? 1) > 0 : true));
  const mergees = refBase ? branches.filter((r) => !estBase(r) && r.ref !== refOrigine && avance(r) === 0 && !enWorktree.has(r.ref)) : [];
  const repliees = new Set(mergees);
  const aGarder = refs.filter((r) => !repliees.has(r));

  const log1 = git('log', '--topo-order', '-z', `--format=${FORMAT_JOURNAL}`, '-n', String(BORNES.base), racineLog, ...tetes);
  const j1 = log1.ok ? lireJournal(log1.sortie) : { ok: false };
  const log2 = nonMergees.length ? git('log', '--topo-order', '-z', `--format=${FORMAT_JOURNAL}`, '-n', String(BORNES.nonMergees), ...nonMergees.map(refLog), '--not', refBase) : { ok: true, sortie: '' }; // LOG2
  const j2 = log2.ok ? lireJournal(log2.sortie) : { ok: false };
  if (!j1.ok || !j2.ok) return ko();
  const commits = ordonner([j1.commits, j2.commits]);
  const pl = placer(commits);
  const parSha = new Map(commits.map((c) => [c.h, c]));
  const etiq = etiquettes(aGarder, { head, worktrees });
  const chaine = new Set();
  for (let c = parSha.get(shaRef(refBase) ?? tetes[0]); c && !chaine.has(c.h); c = parSha.get(c.p[0])) chaine.add(c.h);
  const couleur = new Map();
  const rangees = pl.rangees.map((r) => {
    const c = parSha.get(r.h), labels = etiq.get(r.h) || [];
    const tete = labels.find((e) => e.type === 'locale' || e.type === 'distante');
    const t = chaine.has(r.h) ? 0 : (couleur.get(r.h) ?? (tete ? teinte(tete.nom) : teinte(r.h)));
    if (c.p[0] && !couleur.has(c.p[0])) couleur.set(c.p[0], t);
    const liste = labels.map((e) => ({ type: e.type, nom: net(e.nom), courante: e.courante, worktree: e.worktree ? net(path.basename(e.worktree)) : null,
      commande: e.type !== 'locale' || e.courante ? null : commande(e.worktree ? cmdCd(e.worktree) : cmdSwitch(e.nom), e.nom, e.worktree ?? '') }));
    return { h: r.h, h7: r.h.slice(0, 7), p: c.p, at: c.at, an: net(c.an), s: net(c.s), col: r.col, entrants: r.entrants, sortants: r.sortants, largeur: r.largeur,
      ouvertBas: r.ouvertBas, fusion: r.fusion, racine: r.racine, teinte: t, refs: liste.slice(0, 12), refsPlus: Math.max(0, liste.length - 12) };
  });
  const ls = git('stash', 'list', '-z', '--format=%gd%x00%H%x00%ct%x00%gs', '-n', String(BORNES.stash));
  const st = ls.ok ? lireStash(ls.sortie) : { ok: false };
  if (!st.ok) return ko();
  const parAuteur = new Map(); // agrégé en JS sur les commits déjà lus (aucun outil de comptage git)
  for (const c of commits) { const a = parAuteur.get(c.an) || { nom: net(c.an), commits: 0, dernier: 0 }; a.commits++; a.dernier = Math.max(a.dernier, c.at); parAuteur.set(c.an, a); }
  const cb = refOrigine ? compte(refs.find(estBase)?.ab2) : null;
  const base = { nom: refBase ? net(court(refBase)) : null, locale: cb?.avance ?? null, distante: cb?.retard ?? null, divergent: !!cb && cb.avance > 0 && cb.retard > 0 };
  return { schema: SCHEMA, etat: 'ok', entete, base,
    worktrees: worktrees.map((w, i) => ({ nom: net(path.basename(w.chemin)), chemin: net(w.chemin), branche: w.branche ? net(court(w.branche)) : null, detache: w.detache, ici: w === ici, principal: i === 0,
      commande: w === ici ? null : commande(cmdCd(w.chemin), w.chemin) })),
    rangees, couloirsMax: pl.couloirsMax, replies: pl.replies, refsIgnorees: sd.ignorees,
    horsFenetre: nonMergees.filter((r) => !parSha.has(r.pelee || r.sha)).map((r) => ({ nom: net(court(r.ref)), h7: (r.pelee || r.sha).slice(0, 7), avance: avance(r), retard: compte(r.ab)?.retard ?? null })),
    mergees: mergees.slice(0, 200).map((r) => ({ nom: net(court(r.ref)), commande: r.ref.startsWith('refs/heads/') ? commande(cmdBranchSupprimer(court(r.ref)), court(r.ref)) : null })),
    bornes: { base: BORNES.base, nonMergees: BORNES.nonMergees, tronque: tronqueRefs || j1.commits.length >= BORNES.base || j2.commits.length >= BORNES.nonMergees },
    tags: refs.filter((r) => r.ref.startsWith('refs/tags/')).sort((a, b) => b.date - a.date || (a.ref < b.ref ? -1 : 1)).slice(0, BORNES.tags)
      .map((r) => ({ nom: net(r.ref.slice(10)), h7: (r.pelee || r.sha).slice(0, 7), at: r.date })),
    stash: st.stash.map((x) => ({ ref: x.ref, h7: x.h.slice(0, 7), at: x.at, message: net(x.gs), branche: brancheStash(x.gs) ? net(brancheStash(x.gs)) : null, commande: commande(cmdStashShow(x.ref), x.ref) })),
    auteurs: [...parAuteur.values()].sort((a, b) => b.commits - a.commits || (a.nom < b.nom ? -1 : 1)).slice(0, 50),
    parBranche: refs.filter((r) => r.ref.startsWith('refs/heads/')).sort((a, b) => b.date - a.date || (a.ref < b.ref ? -1 : 1)).slice(0, 50)
      .map((r) => ({ nom: net(court(r.ref)), avance: avance(r), dernier: r.date })),
    commandes: commandes() };
}

export function routeGit(req, res, url, { root, json }) {
  const p = url.pathname;
  if (p !== '/api/vf/git' && !p.startsWith('/api/vf/git/')) return false;
  if (req.method !== 'GET') { res.writeHead(405, { Allow: 'GET' }); res.end(); return true; } // contrôlé ici aussi : indépendant de la ligne commune du serveur
  try {
    if (p === '/api/vf/git') json(res, 200, lireGit(root));
    else if (p === '/api/vf/git/entete') json(res, 200, { schema: SCHEMA_ENTETE, ...enteteGit(root) });
    else if (p === '/api/vf/git/commit') { const r = detailCommit(root, url.searchParams.get('sha')); json(res, r.code, r.corps); }
    else if (p === '/api/vf/git/worktrees') etatWorktrees(root).then((c) => json(res, 200, c), () => json(res, 200, { schema: SCHEMAS_ROUTES[p] || SCHEMA, etat: 'indisponible' })); // P78-D-32 : asynchrone, la boucle reste libre
    else { res.writeHead(404); res.end(); }
  } catch { json(res, 200, { schema: SCHEMAS_ROUTES[p] || SCHEMA, etat: 'indisponible' }); }
  return true;
}
