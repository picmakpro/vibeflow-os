// vf-cockpit-git — topologie Git du lab pour le tiroir (78-05 ; GITC-05, 06, 08, 09, 10 ; P78-D-05, D-07, D-13, D-14, D-23). LECTURE SEULE.
// Exports : BORNES, lireGit(lab) -> objet vibeflow/cockpit-git@1, routeGit(req, res, url, { root, json }) -> true si la route est traitée.
//   GET /api/vf/git         graphe placé en couloirs, worktrees, mergées repliées, tags, stash, auteurs
//   GET /api/vf/git/entete  { schema: 'vibeflow/cockpit-git-entete@1', ...enteteGit }
// Seul point de lancement de git : lancerGit (vf-cockpit-paths.mjs : environnement durci, sortie tronquée signalée). Aucune sous-commande réseau ni d'écriture.
// Toute chaîne servie passe par nettoie ; une COMMANDE à copier n'y passe jamais (P78-D-27) : elle est servie telle quelle, ou null si un nom
// ressemble à un secret (masque(nom) !== nom). Refs passées à `log` : entièrement qualifiées (refs/…) ou sha de 40 caractères, jamais --all.
import fs from 'node:fs';
import path from 'node:path';
import { lancerGit, avecEcheance } from './vf-cockpit-paths.mjs';
import { nettoie, brancheBase } from './vf-cockpit-arbres.mjs';
import { masque } from './vf-cockpit-lecture.mjs';
import { enteteGit } from './vf-cockpit-git-entete.mjs';
import { FORMAT_JOURNAL, lireJournal, lireRefs, lireWorktrees, ordonner, placer, etiquettes, teinte } from './vf-cockpit-git-graphe.mjs';
import { cmdCd, cmdSwitch } from './vf-cockpit-git-commandes.mjs';

export const BORNES = { base: 500, nonMergees: 500, tags: 200, stash: 50, refs: 2000, nom: 200, echeanceMs: 5000 };
const SCHEMA = 'vibeflow/cockpit-git@1', SCHEMA_ENTETE = 'vibeflow/cockpit-git-entete@1';
const NUL = /^0+$/;
const net = (s) => nettoie(s, BORNES.nom);
const reel = (p) => { try { return fs.realpathSync(p); } catch { return path.resolve(p); } };
// commande à copier : jamais nettoyée ni masquée ; null si un des noms qui la composent serait masqué à l'affichage (la copie ne dirait pas ce que l'écran dit)
const commande = (cmd, ...noms) => (cmd !== null && noms.every((n) => masque(n) === n) ? cmd : null);

export function lireGit(lab) {
  try { return avecEcheance(BORNES.echeanceMs, () => assembler(lab)); } catch { return { schema: SCHEMA, etat: 'indisponible' }; }
}

function assembler(lab) {
  const entete = enteteGit(lab);
  if (entete.etat === 'absent') return { schema: SCHEMA, etat: 'absent', entete };
  const ko = () => ({ schema: SCHEMA, etat: 'indisponible', entete });
  const git = (...a) => lancerGit(lab, a);
  const nomBase = brancheBase(lab);
  const refsBase = git('for-each-ref', '--format=%(refname)', ...(nomBase ? [`refs/heads/${nomBase}`, `refs/remotes/origin/${nomBase}`] : []));
  const presentes = new Set(nomBase && refsBase.ok ? refsBase.sortie.split('\n') : []);
  const refBase = presentes.has(`refs/heads/${nomBase}`) ? `refs/heads/${nomBase}` : presentes.has(`refs/remotes/origin/${nomBase}`) ? `refs/remotes/origin/${nomBase}` : null;

  const fer = git('for-each-ref', '--format=%(refname)%00%(objectname)%00%(*objectname)%00%(creatordate:unix)', 'refs/heads', 'refs/remotes', 'refs/tags');
  const lr = fer.ok ? lireRefs(fer.sortie) : { ok: false };
  const wl = git('worktree', 'list', '--porcelain', '-z');
  const lw = wl.ok ? lireWorktrees(wl.sortie) : { ok: false };
  if (!lr.ok || !lw.ok) return ko();
  const refs = lr.refs.filter((r) => !/^refs\/remotes\/[^/]+\/HEAD$/.test(r.ref)).slice(0, BORNES.refs);
  const worktrees = lw.worktrees;

  // worktree « ici » : celui dont le chemin est le plus long préfixe du lab
  const labReel = reel(lab);
  const sous = (c) => labReel === reel(c) || labReel.startsWith(reel(c) + path.sep);
  const ici = worktrees.filter((w) => sous(w.chemin)).sort((a, b) => b.chemin.length - a.chemin.length)[0] || null;
  const head = ici ? (ici.branche || ici.head) : null;
  const shaRef = (r) => refs.find((x) => x.ref === r)?.sha ?? null;
  const tetes = [...new Set(worktrees.map((w) => w.head).filter((h) => h && !NUL.test(h)))];
  const racineLog = refBase || tetes[0] || null;
  if (!racineLog) return { schema: SCHEMA, etat: 'vide', entete, commandes: { vide: null, diagnostic: null } };

  const log1 = git('log', '--topo-order', '-z', `--format=${FORMAT_JOURNAL}`, '-n', String(BORNES.base), racineLog, ...tetes);
  const j1 = log1.ok ? lireJournal(log1.sortie) : { ok: false };
  if (!j1.ok) return ko();
  const commits = ordonner([j1.commits]);
  const pl = placer(commits);
  const parSha = new Map(commits.map((c) => [c.h, c]));
  const etiq = etiquettes(refs, { head, worktrees });
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
  return { schema: SCHEMA, etat: 'ok', entete, rangees, couloirsMax: pl.couloirsMax, replies: pl.replies, bornes: { base: BORNES.base, nonMergees: BORNES.nonMergees, tronque: commits.length >= BORNES.base } };
}

export function routeGit(req, res, url, { root, json }) {
  const p = url.pathname;
  if (p !== '/api/vf/git' && !p.startsWith('/api/vf/git/')) return false;
  if (req.method !== 'GET') { res.writeHead(405, { Allow: 'GET' }); res.end(); return true; } // contrôlé ici aussi : indépendant de la ligne commune du serveur
  try {
    if (p === '/api/vf/git') json(res, 200, lireGit(root));
    else if (p === '/api/vf/git/entete') json(res, 200, { schema: SCHEMA_ENTETE, ...enteteGit(root) });
    else { res.writeHead(404); res.end(); }
  } catch { json(res, 200, { schema: p === '/api/vf/git/entete' ? SCHEMA_ENTETE : SCHEMA, etat: 'indisponible' }); }
  return true;
}
