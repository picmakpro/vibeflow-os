// vf-cockpit-activite-git — points chauds, couplage et tâche git de la lentille « activité » (Phase 75, plan 75-01 ; ACTV-04, 05, 06 ; P75-D-07, D-08, D-09, D-11). LECTURE SEULE.
// Exports : FENETRE, PALIERS_MIN_FICHIERS, SEUILS_COUPLAGE, BRUIT, pointsChauds(commits, loc, { paliersMin }) -> { chauds, paliers }, couplage(commits, options) -> [[a, b, communes, degré]],
//           calculerGit(lab, options) -> Promise<{ etat, fenetre, chauds, couplage, paliers, cle, memo } | { etat: 'indisponible' | 'absent' }>.
// Seul point d'appel git : `lancerGitAsync` (vf-cockpit-git-lanceur.mjs : environnement durci, liste fermée de sous-commandes, filtres du dépôt vidés). Jamais `status`, `diff` contre l'arbre de travail,
// `fetch` ni `--follow` ; aucun réseau, rien d'écrit. Sans état global : l'état gardé (`memo`, <= 5 000 commits) vit chez l'appelant (75-05), qui le rend dans `etatPrecedent`.
// A-04 : `merge-base` n'est pas dans la liste fermée des sous-commandes : « l'ancien HEAD est un ancêtre » se lit par `rev-list --count HEAD..ancien` (0 = ancêtre).
// P75-D-11, P78-D-22 : erreur, délai, sortie tronquée ou désalignée = { etat: 'indisponible' } SANS champ partiel ; git absent, refusé ou hors dépôt = { etat: 'absent' }.
// Les chemins sont comparés BRUTS ; `nettoie` n'intervient qu'à l'affichage (côté page).
import fs from 'node:fs';
import { createHash } from 'node:crypto';
import { lancerGitAsync, finDans } from './vf-cockpit-git-lanceur.mjs';
import { MOTIF_SHA } from './vf-cockpit-git-graphe.mjs';
import { lireLog, resoudre, fusionner, purger } from './vf-cockpit-activite-log.mjs';

export const FENETRE = { jours: 90, plafond: 5000 };
export const PALIERS_MIN_FICHIERS = 12; // sous ce nombre de fichiers à score non nul, trois quantiles mettraient un fichier touché une fois au palier haut : un seul palier
// seuils par défaut de code-maat ; exportés et injectables : à 5 et 5 le contrôle « par fichier » est équivalent à celui des communes (75-RESEARCH O-3), un test lui donne un témoin avec d'autres valeurs
export const SEUILS_COUPLAGE = { minCommunes: 5, minRevs: 5, minDegre: 30, maxFichiers: 30, voisins: 5 };
// bruit de version et de verrou, mesuré sur ce dépôt (voir 75-01-SUMMARY.md) ; comparé au NOM de base du chemin
export const BRUIT = ['CHANGELOG.md', 'VERSION', 'plugin.json', 'marketplace.json', 'module.json', 'package-lock.json', 'pnpm-lock.yaml', 'yarn.lock', 'Cargo.lock', 'go.sum'];
const ECHEANCE_MS = 15000;
const cmp = (a, b) => (a < b ? -1 : a > b ? 1 : 0);

// loc : Map chemin -> lignes, ou liste de { p, loc } (forme de `graph.json`) ; jamais un objet à clés dynamiques
const locDe = (loc) => (loc instanceof Map ? loc : new Map((Array.isArray(loc) ? loc : []).filter((f) => f && typeof f.p === 'string').map((f) => [f.p, f.loc])));

// Point chaud = commits de la fenêtre x loc ; rang décroissant (égalité : chemin) ; trois paliers par quantiles (3 = chaud), égalités au même palier.
// Tuple servi : [chemin, commits, loc, rang, palier]. Un fichier sans modification dans la fenêtre, sans loc ou à loc nulle n'est pas rendu.
export function pointsChauds(commits, loc, { paliersMin = PALIERS_MIN_FICHIERS } = {}) {
  const nb = new Map(), L = locDe(loc), lignes = [];
  for (const c of commits) for (const p of c.chemins) nb.set(p, (nb.get(p) || 0) + 1);
  for (const [p, n] of nb) { const l = L.get(p); if (typeof l === 'number' && l > 0) lignes.push([p, n, l, n * l]); }
  lignes.sort((a, b) => b[3] - a[3] || cmp(a[0], b[0]));
  const n = lignes.length, paliers = n >= paliersMin ? 3 : 1;
  const seuil3 = n ? lignes[Math.ceil(n / 3) - 1][3] : 0, seuil2 = n ? lignes[Math.ceil((2 * n) / 3) - 1][3] : 0;
  const palier = (s) => (paliers === 1 ? 1 : s >= seuil3 ? 3 : s >= seuil2 ? 2 : 1);
  return { chauds: lignes.map(([p, c, l, s], i) => [p, c, l, i + 1, palier(s)]), paliers };
}

// Couplage : paires de fichiers co-modifiés. Le bruit est retiré AVANT tout comptage ; un commit de plus de `maxFichiers` fichiers (bruit retiré) est écarté ; révisions d'un fichier = commits gardés
// qui le touchent. Paire gardée si communes >= minCommunes, chaque fichier >= minRevs, degré (communes / moyenne des révisions des deux fichiers) >= minDegre %. `voisins` au plus par fichier : les
// paires, triées par degré décroissant puis chemins, sont retenues tant que les deux fichiers ont de la place. Tuple : [a, b, communes, degré arrondi], a < b ; chemins bruts, jamais clés d'objet.
export function couplage(commits, options = {}) {
  const o = { ...SEUILS_COUPLAGE, ...options }, bruit = new Set(o.bruit ?? BRUIT);
  const gardes = [], revs = new Map(), paires = new Map(), lignes = [], places = new Map(), rendu = [];
  for (const c of commits) {
    const f = [...new Set(c.chemins)].filter((p) => !bruit.has(p.slice(p.lastIndexOf('/') + 1)));
    if (f.length >= 1 && f.length <= o.maxFichiers) gardes.push(f);
  }
  for (const f of gardes) for (const p of f) revs.set(p, (revs.get(p) || 0) + 1);
  for (const f of gardes) {
    const g = f.filter((p) => revs.get(p) >= o.minRevs).sort(cmp);
    for (let i = 0; i < g.length; i++) for (let j = i + 1; j < g.length; j++) { const k = `${g[i]}\0${g[j]}`, e = paires.get(k); if (e) e[2]++; else paires.set(k, [g[i], g[j], 1]); }
  }
  for (const [a, b, n] of paires.values()) {
    const somme = revs.get(a) + revs.get(b);
    if (n >= o.minCommunes && n * 200 >= o.minDegre * somme) lignes.push([a, b, n, (n * 200) / somme]);
  }
  lignes.sort((x, y) => y[3] - x[3] || cmp(x[0], y[0]) || cmp(x[1], y[1]));
  for (const [a, b, n, d] of lignes) {
    if ((places.get(a) || 0) >= o.voisins || (places.get(b) || 0) >= o.voisins) continue;
    places.set(a, (places.get(a) || 0) + 1); places.set(b, (places.get(b) || 0) + 1);
    rendu.push([a, b, n, Math.round(d)]);
  }
  return rendu;
}

// absent : pas de git, refusé, hors dépôt ; tout le reste (délai, tronqué, erreur) : indisponible
const raison = (r) => (r.delai || r.tronque ? 'indisponible' : r.absent || r.refuse || r.code === 128 || r.code === null ? 'absent' : 'indisponible');
const ARGS_LOG = ['log', '--no-merges', '-M', '-l400', '--name-status', '-z', '--format=%x00%H%x00%ct'];
const lireCommits = async (lire, args) => { const r = await lire(args); const lu = r.ok && !r.tronque ? lireLog(r.sortie) : { ok: false }; return lu.ok ? lu.commits : null; };

// « historique partiel » SEULEMENT si la limite superficielle est plus récente que le début de la fenêtre (sinon la mention serait fausse en permanence sur un clone ancien)
async function historiquePartiel(lire, debut) {
  const s = await lire(['rev-parse', '--is-shallow-repository']);
  if (!s.ok) return null;
  if (s.sortie.trim() !== 'true') return false;
  const f = await lire(['rev-parse', '--path-format=absolute', '--git-path', 'shallow']);
  let limites = [];
  try { limites = f.ok ? fs.readFileSync(f.sortie.trim(), 'utf8').split('\n').filter((x) => MOTIF_SHA.test(x)).slice(0, 200) : []; } catch { /* illisible : partiel par prudence */ }
  if (!limites.length) return true;
  const d = await lire(['log', '--no-walk=unsorted', '--format=%ct', ...limites, '--']);
  const dates = d.ok ? d.sortie.split('\n').filter(Boolean).map(Number) : [];
  return dates.length === 0 || dates.some((t) => !Number.isFinite(t)) ? true : Math.max(...dates) > debut;
}

// Commits de la fenêtre depuis HEAD : incrémental quand l'ancien HEAD est un ancêtre (ancien..HEAD seul, préfixé, purgé, plafonné), relecture complète sinon (réécriture, ancien HEAD introuvable).
async function commitsDeLaFenetre(lire, tete, memo, { plafond, jours, debut }) {
  const since = `--since=${jours}.days`, ancien = memo?.tete;
  if (typeof ancien === 'string' && MOTIF_SHA.test(ancien)) {
    if (ancien === tete) return purger(memo.commits, debut);
    const anc = await lire(['rev-list', '--count', `${tete}..${ancien}`]);
    if (anc.ok && anc.sortie.trim() === '0') {
      const neufs = await lireCommits(lire, [...ARGS_LOG, since, '-n', String(plafond), `${ancien}..${tete}`, '--']);
      return neufs && fusionner(neufs, purger(memo.commits, debut), plafond);
    }
  }
  return lireCommits(lire, [...ARGS_LOG, since, '-n', String(plafond), tete, '--']);
}

export async function calculerGit(lab, { loc, etatPrecedent = null, binaire, fin = finDans(ECHEANCE_MS), plafond = FENETRE.plafond, jours = FENETRE.jours, options,
  paliersMin = PALIERS_MIN_FICHIERS, maxBuffer = 32 << 20, maintenant = Date.now() } = {}) {
  const lire = (args) => lancerGitAsync(lab, args, { fin, maxBuffer, binaire });
  const debut = Math.floor(maintenant / 1000) - jours * 86400;
  // clé de cache : condensat des refs et des worktrees (HEAD de chacun compris), RELUE à chaque appel (deux lectures, aucun `log`)
  const refs = await lire(['for-each-ref', '--format=%(refname)%00%(objectname)']);
  if (!refs.ok) return { etat: raison(refs) };
  const arbres = await lire(['worktree', 'list', '--porcelain', '-z']);
  if (!arbres.ok) return { etat: raison(arbres) };
  const cle = createHash('sha256').update(`${refs.sortie}\0\0${arbres.sortie}`).digest('hex');
  const avant = etatPrecedent?.memo ?? null;
  let memo, partiel;
  if (avant && avant.cle === cle) { memo = { ...avant, commits: purger(avant.commits, debut) }; partiel = avant.partiel; }
  else {
    const h = await lire(['rev-parse', '--verify', '--quiet', 'HEAD']);
    const tete = h.ok ? h.sortie.trim() : '';
    if (h.ok && !MOTIF_SHA.test(tete)) return { etat: 'indisponible' };
    if (!h.ok && !(h.code === 1 && !h.delai && !h.tronque)) return { etat: raison(h) };
    const commits = h.ok ? await commitsDeLaFenetre(lire, tete, avant, { plafond, jours, debut }) : [];
    if (commits === null) return { etat: 'indisponible' };
    partiel = h.ok ? await historiquePartiel(lire, debut) : false;
    if (partiel === null) return { etat: 'indisponible' };
    memo = { cle, tete: h.ok ? tete : null, commits, partiel };
  }
  const resolus = resoudre(memo.commits), p = pointsChauds(resolus, loc, { paliersMin });
  return { etat: memo.commits.length ? 'ok' : 'vide', fenetre: { jours, commits: memo.commits.length, plafond, plafondAtteint: memo.commits.length >= plafond, partiel },
    chauds: p.chauds, couplage: couplage(resolus, options), paliers: p.paliers, cle, memo };
}
