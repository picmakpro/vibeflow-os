// vf-cockpit-trace — la route GET /api/vf/tracabilite (76-05 ; TRAC-10, TRAC-11 ; P76-D-06 à D-12, D-31).
// Exports : CHEMIN_TRACE, lireTracabilite(ctx, req, url, { instantane }) — la forme de lecteur de la table des routes (`lecteur(ctx, req, url)`) :
//   rend un corps JSON ou reponse(400, corps) ; jamais un en-tête ni un contrôle d'accès (le répartiteur applique la réponse gardée commune).
// Le planning se lit dans l'instantané de la collecte, en mémoire (vf-cockpit-instantane.mjs), jamais par HTTP ni par une relecture.
// Lectures propres de la route (ADR, commits citants, mémoire) : passages git d'abord (asynchrones), puis UN appel synchrone `lireConfine`.
import path from 'node:path';
import { instantane as instantaneReel } from './vf-cockpit-instantane.mjs';
import { reponse } from './vf-cockpit-routes.mjs';
import { lireConfine, read, fm } from './vf-cockpit-planning.mjs';
import { finDans } from './vf-cockpit-paths.mjs';
import { teteSha, commitsCitants, BORNES_TRACE } from './vf-cockpit-trace-git.mjs';
import { fichiersSuivis, nonSuivis, cheminsHead, cheminsSupprimes, joursMemoire } from './vf-cockpit-trace-memoire-git.mjs';
import { entreesMemoire } from './vf-cockpit-trace-memoire.mjs';
import { sectionsAdr, relier } from './vf-cockpit-registres.mjs';
import { servi } from './vf-cockpit-trace-texte.mjs';
import { SCHEMA, VUES, MOTIFS_CLE, definitionsDe, vue } from './vf-cockpit-trace-vues.mjs';

export const CHEMIN_TRACE = '/api/vf/tracabilite';
const CLE_MAX = 200;

// validation : liste fermée de vues, `cle` par motif propre à la vue, jamais un choix à la place de l'appelant
function parametres(url) {
  const p = url.searchParams;
  for (const k of p.keys()) if (k !== 'vue' && k !== 'cle') return { erreur: 'parametre-inconnu' };
  const vues = p.getAll('vue'), cles = p.getAll('cle');
  if (vues.length !== 1 || !VUES.includes(vues[0])) return { erreur: 'vue-invalide' };
  if (cles.length > 1) return { erreur: 'cle-invalide' };
  const v = vues[0], cle = cles.length ? cles[0] : null;
  if (cle !== null && (MOTIFS_CLE[v] === null || cle.length > CLE_MAX || !MOTIFS_CLE[v].test(cle))) return { erreur: 'cle-invalide' };
  if (cle === null && ['phase', 'exigence', 'decision', 'entree'].includes(v)) return { erreur: 'cle-requise' };
  return { v, cle };
}

// le calcul des lectures propres : git d'abord, puis une lecture synchrone confinée, puis les fonctions pures
async function calculer(root, snap) {
  const fin = finDans(BORNES_TRACE.echeanceMs), sv = (x, n) => (x == null ? x : servi(x, n, { racine: root }));
  const { sha } = await teteSha(root, { fin });
  const git = sha !== null;
  const cc = git ? await commitsCitants(root, sha, { fin }) : { commits: [], tronque: false };
  const suivis = git ? await fichiersSuivis(root, { fin }) : { chemins: [], tronque: false };
  const ns = git ? await nonSuivis(root, { fin }) : { n: 0 };
  const head = git ? await cheminsHead(root, sha, { fin }) : new Set();
  const sup = git ? await cheminsSupprimes(root, sha, { fin }) : { chemins: new Set(), tronque: false };
  const jours = git ? await joursMemoire(root, sha, { fin }) : new Map();
  const lu = lireConfine(root, () => ({ adr: read(path.join(root, 'docs', 'ADR.md')),
    fichiers: suivis.chemins.map((chemin) => ({ chemin, txt: read(path.join(root, chemin)) })) }));
  const adrs = sectionsAdr(lu.adr).map((a) => ({ id: a.id, titre: sv(a.titre, 200) }));
  const commits = cc.commits.map((c) => ({ ...c, sujet: sv(c.sujet, 200) }));
  const liens = relier({ adrs, definitions: definitionsDe(snap.projet), commits });
  const m = entreesMemoire({ fichiers: lu.fichiers, head, historique: sup.chemins, jours, fm });
  const entrees = m.entrees.map((e) => ({ ...e, name: sv(e.name, 120), type: sv(e.type, 60),
    sortants: e.sortants.map((s) => ({ ...s, cible: sv(s.cible, 128) })), cheminsAbsents: e.cheminsAbsents.map((c) => sv(c, 200)) }));
  return { adrs, liens, commits, memoire: { ...m, entrees },
    bornes: { tronque: Boolean(cc.tronque || suivis.tronque || sup.tronque) },
    absences: { adr: lu.adr === '', memoire: suivis.chemins.length ? null : ns.n > 0 ? 'ignoree' : 'absente', nonSuivis: ns.n, git: !git } };
}

export async function lireTracabilite(ctx, req, url, { instantane = instantaneReel } = {}) {
  const a = parametres(url);
  if (a.erreur) return reponse(400, { erreur: a.erreur });
  const { v, cle } = a, base = { schema: SCHEMA, vue: v, ...(cle ? { cle } : {}) };
  try {
    const snap = instantane();
    if (!snap || !snap.projet) return { ...base, etat: 'vide', collecte: 'en-cours', bornes: { tronque: false } };
    const modele = ['jalon', 'phase', 'exigence'].includes(v) ? null : await calculer(ctx.root, snap);
    const r = vue({ vue: v, cle, projet: snap.projet, modele });
    return r.statut === 200 ? r.corps : reponse(r.statut, r.corps);
  } catch {
    return { ...base, etat: 'indisponible', bornes: { tronque: false } };
  }
}
