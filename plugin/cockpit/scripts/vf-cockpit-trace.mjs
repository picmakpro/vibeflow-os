// vf-cockpit-trace — la route GET /api/vf/tracabilite (76-05 ; TRAC-10, TRAC-11 ; P76-D-06 à D-12, D-31).
// Exports : CHEMIN_TRACE, lireTracabilite(ctx, req, url, { instantane }) — la forme de lecteur de la table des routes (`lecteur(ctx, req, url)`) :
//   rend un corps JSON ou reponse(400, corps) ; jamais un en-tête ni un contrôle d'accès (le répartiteur applique la réponse gardée commune).
// Le planning se lit dans l'instantané de la collecte, en mémoire (vf-cockpit-instantane.mjs), jamais par HTTP ni par une relecture.
// Lectures propres de la route (ADR, commits citants, mémoire) : passages git d'abord (asynchrones), puis UN appel synchrone `lireConfine`.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { instantane as instantaneReel } from './vf-cockpit-instantane.mjs';
import { reponse } from './vf-cockpit-routes.mjs';
import { lireConfine, lister, read, fm } from './vf-cockpit-planning.mjs';
import { readJson } from './vf-cockpit-lecture.mjs';
import { finDans } from './vf-cockpit-paths.mjs';
import { teteSha, commitsCitants, BORNES_TRACE } from './vf-cockpit-trace-git.mjs';
import { fichiersSuivis, nonSuivis, cheminsHead, cheminsSupprimes, joursMemoire } from './vf-cockpit-trace-memoire-git.mjs';
import { entreesMemoire } from './vf-cockpit-trace-memoire.mjs';
import { sectionsAdr, relier } from './vf-cockpit-registres.mjs';
import { servi } from './vf-cockpit-trace-texte.mjs';
import { SCHEMA, VUES, MOTIFS_CLE, definitionsDe, vue } from './vf-cockpit-trace-vues.mjs';

export const CHEMIN_TRACE = '/api/vf/tracabilite';
const CLE_MAX = 200;
// borne de test des commits citants : lue une fois au chargement, entier de 1 à 2 000 seulement (jamais au-delà de la borne du module)
const MAX_COMMITS = (() => {
  const v = process.env.VF_COCKPIT_TRACE_MAX_COMMITS;
  return typeof v === 'string' && /^\d{1,4}$/.test(v) && Number(v) >= 1 && Number(v) <= BORNES_TRACE.commits ? Number(v) : BORNES_TRACE.commits;
})();
// garde locale (B3) : la liste d'interdits du schéma cockpit-trace@1, lue une fois au chargement ; contrat illisible ou liste vide : tout est refusé
const contrat = readJson(path.join(path.dirname(fileURLToPath(import.meta.url)), 'vf-cockpit-interface.json'));
const liste = (contrat && contrat.schemas && contrat.schemas[SCHEMA] && contrat.schemas[SCHEMA].interdits) || [];
const INTERDITS = liste.filter((k) => typeof k === 'string' && k);
const porte = (o, ban) => !!o && typeof o === 'object' && Object.entries(o).some(([k, v]) => ban.includes(k) || porte(v, ban));
// vrai = refuser : une clé interdite à toute profondeur, ou aucune liste d'interdits
export const gardeLocale = (corps, interdits) => !Array.isArray(interdits) || interdits.length === 0 || porte(corps, interdits);
// tout corps passe ici avant d'être rendu au répartiteur (la réponse gardée commune tient les cinq clés de C0, celle-ci les trois autres)
function sortir(corps, code = 200) {
  if (gardeLocale(corps, INTERDITS)) return reponse(503, { erreur: 'emission-refusee' });
  return code === 200 ? corps : reponse(code, corps);
}

// empreinte (P76-D-06 amendée, A47) : signature git et seq de l'instantané, dates de docs/ADR.md, de la racine de mémoire et de chaque dossier d'agent ;
// lstat (un lien n'est pas suivi), jamais un parcours du planning : le seq de l'instantané le couvre
function empreinte(root, snap) {
  const date = (p) => { try { return fs.lstatSync(p).mtimeMs; } catch { return 0; } };
  const mem = path.join(root, '.claude', 'agent-memory');
  const agents = lireConfine(root, () => lister(mem)).slice(0, 2000);
  const parties = [snap.git && snap.git.sig, snap.seq, date(path.join(root, 'docs', 'ADR.md')), date(mem), ...agents.map((a) => date(path.join(mem, a)))];
  return `${root}|${parties.join('|')}`;
}
// une entrée de cache, un seul calcul en vol : une requête de même empreinte rejoint le calcul en cours, une autre attend sa fin
let cache = null, enVol = null;
function modeleDe(emp, calculerModele) {
  if (cache && cache.emp === emp) return Promise.resolve(cache.modele);
  if (enVol && enVol.emp === emp) return enVol.p;
  const avant = enVol ? enVol.p.catch(() => {}) : Promise.resolve();
  const p = avant.then(calculerModele).then((m) => { cache = { emp, modele: m }; return m; });
  const suivi = { emp, p };
  enVol = suivi;
  const fini = () => { if (enVol === suivi) enVol = null; };
  p.then(fini, fini);
  return p;
}

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
  const cc = git ? await commitsCitants(root, sha, { fin, max: MAX_COMMITS }) : { commits: [], tronque: false };
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
  if (a.erreur) return sortir({ erreur: a.erreur }, 400);
  const { v, cle } = a, base = { schema: SCHEMA, vue: v, ...(cle ? { cle } : {}) };
  try {
    const snap = instantane();
    if (!snap || !snap.projet) return sortir({ ...base, etat: 'vide', collecte: 'en-cours', bornes: { tronque: false } });
    const modele = ['jalon', 'phase', 'exigence'].includes(v) ? null : await modeleDe(empreinte(ctx.root, snap), () => calculer(ctx.root, snap));
    const r = vue({ vue: v, cle, projet: snap.projet, modele });
    return sortir(r.corps, r.statut);
  } catch {
    return sortir({ ...base, etat: 'indisponible', bornes: { tronque: false } });
  }
}
