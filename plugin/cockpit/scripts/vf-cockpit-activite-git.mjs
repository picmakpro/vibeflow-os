// vf-cockpit-activite-git — points chauds, couplage et tâche git de la lentille « activité » (Phase 75, plan 75-01 ; ACTV-04, 05, 06 ; P75-D-07, D-08, D-09, D-11). LECTURE SEULE.
// Exports : FENETRE, PALIERS_MIN_FICHIERS, pointsChauds(commits, loc, { paliersMin }) -> { chauds, paliers }, calculerGit(lab, options) -> Promise<objet de la lentille git>.
// Seul point d'appel git : `lancerGitAsync` (vf-cockpit-git-lanceur.mjs : environnement durci, liste fermée de sous-commandes, filtres du dépôt vidés). Jamais `status`, `diff` contre l'arbre de travail,
// `fetch` ni `--follow` ; aucun réseau, rien d'écrit. Sans état global : l'état gardé (`memo`) vit chez l'appelant (75-05), qui le rend dans `etatPrecedent`.
// P75-D-11, P78-D-22 : erreur, délai, sortie tronquée ou désalignée = { etat: 'indisponible' } SANS champ partiel ; git absent, refusé ou hors dépôt = { etat: 'absent' }.
// Les chemins sont comparés BRUTS ; `nettoie` n'intervient qu'à l'affichage (côté page).
import fs from 'node:fs';
import { lancerGitAsync, finDans } from './vf-cockpit-git-lanceur.mjs';
import { MOTIF_SHA } from './vf-cockpit-git-graphe.mjs';
import { lireLog, resoudre } from './vf-cockpit-activite-log.mjs';

export const FENETRE = { jours: 90, plafond: 5000 };
export const PALIERS_MIN_FICHIERS = 12; // sous ce nombre de fichiers à score non nul, trois quantiles mettraient un fichier touché une fois au palier haut : un seul palier
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

// absent : pas de git, refusé, hors dépôt ; tout le reste (délai, tronqué, erreur) : indisponible
const raison = (r) => (r.delai || r.tronque ? 'indisponible' : r.absent || r.refuse || r.code === 128 || r.code === null ? 'absent' : 'indisponible');

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

export async function calculerGit(lab, { loc, binaire, fin = finDans(ECHEANCE_MS), plafond = FENETRE.plafond, jours = FENETRE.jours,
  paliersMin = PALIERS_MIN_FICHIERS, maxBuffer = 32 << 20, maintenant = Date.now() } = {}) {
  const lire = (args) => lancerGitAsync(lab, args, { fin, maxBuffer, binaire });
  const debut = Math.floor(maintenant / 1000) - jours * 86400;
  const h = await lire(['rev-parse', '--verify', '--quiet', 'HEAD']);
  const tete = h.sortie.trim();
  if (!h.ok) return h.code === 1 && !h.delai && !h.tronque ? { etat: 'vide', fenetre: { jours, commits: 0, plafond, plafondAtteint: false, partiel: false }, chauds: [], paliers: 1 } : { etat: raison(h) };
  if (!MOTIF_SHA.test(tete)) return { etat: 'indisponible' };
  const r = await lire(['log', '--no-merges', '-M', '-l400', '--name-status', '-z', '--format=%x00%H%x00%ct', `--since=${jours}.days`, '-n', String(plafond), tete, '--']);
  const lu = r.ok && !r.tronque ? lireLog(r.sortie) : { ok: false };
  if (!lu.ok) return { etat: 'indisponible' };
  const partiel = await historiquePartiel(lire, debut);
  if (partiel === null) return { etat: 'indisponible' };
  const commits = lu.commits, p = pointsChauds(resoudre(commits), loc, { paliersMin });
  return { etat: commits.length ? 'ok' : 'vide', fenetre: { jours, commits: commits.length, plafond, plafondAtteint: commits.length >= plafond, partiel }, chauds: p.chauds, paliers: p.paliers };
}
