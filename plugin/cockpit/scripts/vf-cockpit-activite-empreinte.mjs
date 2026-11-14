// vf-cockpit-activite-empreinte — l'empreinte des agents sur le code : degrés, noms, mentions de limite (75-03, ACTV-08, ACTV-09 ; P75-D-12,
//   P75-D-13, A24, A45, A47).
// Exports : VOIES_MAX (2 000), FENETRE_MS (24 h), LIMITE, vivante(voie), preparer(voies, contexte), empreinte(voies, contexte).
// Entrées : les voies de la PROJECTION de frise (79-13, `cibles` { etat, tronque, ecritures, lectures }, `etatOfficiel`, `rattachement`) ; jamais
//   une voie brute, jamais
//   l'argument ni la sortie d'un outil (aucun autre champ n'est lu). Lectures = `Read` seul, écritures = `Write`, `Edit`, `MultiEdit`,
//   `NotebookEdit` : la table
//   des outils est celle de 79-13, ce module ne la rejuge pas.
// contexte : { maintenant (ms, injecté : aucune horloge ici), cartes, libelleHorsLab, worktreesVerifies, nomPrincipal, friseTronque, titres: Map
//   session -> titre }.
// Sortie : { etat: 'ok'|'en-construction'|'tronque', incomplet, limite: [codes], marques: [[chemin, degre, [noms]]], horsCarte, horsLab, coupees,
//   rejetes, ignorees,
//   voiesTronquees } — des tableaux de tuples, jamais un chemin, un rôle ou un titre en clé d'objet. Pur : aucun disque, aucun git, aucune horloge.
import { rassembler } from './vf-cockpit-activite-chemins.mjs';

export const VOIES_MAX = 2000;
export const FENETRE_MS = 86400000;
export const LIMITE = 'ecritures-par-commande-non-vues';
const RANG = { 'en-cours': 3, modifie: 2, lu: 1, fini: 0 };
const cmp = (a, b) => (a < b ? -1 : a > b ? 1 : 0);
export const propre = (t) => String(t).replace(/[\u0000-\u001f\u007f-\u009f\u2028\u2029]/g, ' ').slice(0, 120);

export const vivante = (v) => !!v && typeof v.etatOfficiel === 'string' && v.etatOfficiel !== 'termine';

// les voies retenues : bornées à 2 000, vivantes ou terminées dans les 24 h ; une voie sans état officiel n'est jamais devinée
export function preparer(voies, contexte = {}) {
  const liste = Array.isArray(voies) ? voies : [];
  const brutes = liste.slice(0, VOIES_MAX); // garde:empreinte-borne
  const t = contexte.maintenant, retenues = [], r = {
    retenues, voiesTronquees: liste.length > brutes.length, ignorees: 0, enConstruction: false, cibleTronquee: false };
  for (const v of brutes) {
    if (!v || typeof v !== 'object') continue;
    const etat = vivante(v) ? 'vivante' : v.etatOfficiel === 'termine' && Number.isFinite(t)
      && (v.fin ?? v.debut ?? 0) >= t - FENETRE_MS ? 'finie' : null; // garde:empreinte-fenetre
    if (etat === null) continue;
    if (!v.cibles || typeof v.cibles !== 'object') { r.ignorees++; continue; } // A43 : forme inconnue, ignorée et comptée
    if (v.cibles.etat === 'en-construction') r.enConstruction = true;
    if (v.cibles.tronque === true) r.cibleTronquee = true;
    retenues.push({ v, etat });
  }
  r.noms = noms(retenues, contexte);
  return r;
}

// nom = rôle, puis « · nœud X », puis l'arbre si deux voies vivantes partagent le rôle ; session = titre, sinon « session · arbre » ; jamais
//   l'identifiant brut
function noms(retenues, c) {
  const roles = new Map();
  for (const { v, etat } of retenues) if (etat === 'vivante' && v.kind !== 'session') roles.set(v.role, (roles.get(v.role) || 0) + 1);
  const arbre = (v) => (typeof v.arbre === 'string' ? propre(v.arbre) : c.nomPrincipal ? propre(c.nomPrincipal) : 'principal');
  return retenues.map(({ v, etat }) => {
    if (v.kind === 'session') {
      const titre = c.titres instanceof Map ? c.titres.get(v.session) : undefined;
      return typeof titre === 'string' && titre.trim() ? propre(titre) : `session · ${arbre(v)}`;
    }
    let n = typeof v.role === 'string' && v.role ? propre(v.role) : 'agent';
    const r = v.rattachement;
    if (!r) n += ' · non rattaché'; else if (typeof r.noeud === 'string' && r.noeud) n += ` · nœud ${propre(r.noeud)}`; // garde:empreinte-nom
    if (etat === 'vivante' && roles.get(v.role) > 1) n += ` · ${arbre(v)}`;
    return n;
  });
}

export function raisons(p, compte) {
  const out = [];
  if (p.enConstruction) out.push('en-construction');
  if (p.contexteTronque) out.push('tronque');
  if (compte.coupees > 0 || p.cibleTronquee) out.push('cibles-coupees');
  return out;
}

export function empreinte(voies, contexte = {}) {
  const p = preparer(voies, contexte), entrees = [];
  p.contexteTronque = contexte.friseTronque === true;
  p.retenues.forEach(({ v }, k) => {
    for (const e of v.cibles.ecritures || []) entrees.push({ arbre: e.arbre, cible: e.cible, ref: { k, sens: 'e', ms: e.dernierMs } });
    for (const e of v.cibles.lectures || []) entrees.push({ arbre: e.arbre, cible: e.cible,
      ref: { k, sens: 'l', ms: e.dernierMs } }); // garde:empreinte-lectures
  });
  const r = rassembler(entrees, contexte);
  // la dernière écriture de chaque voie vivante : parmi celles qui se joignent (carte ou hors carte), la plus récente, à égalité la plus petite
  const derniere = new Map();
  entrees.forEach((e, i) => {
    const s = r.etats[i].etat;
    if (e.ref.sens !== 'e' || (s !== 'carte' && s !== 'hors-carte')) return;
    const d = derniere.get(e.ref.k);
    if (!d || e.ref.ms > d.ms || (e.ref.ms === d.ms && e.cible < d.cible)) derniere.set(e.ref.k, { ms: e.ref.ms, cible: e.cible, arbre: e.arbre ?? null });
  });
  const marques = new Map();
  for (const g of r.groupes) {
    if (!g.carte) continue;
    for (const ref of g.refs) {
      const { etat } = p.retenues[ref.k];
      const d = derniere.get(ref.k);
      const degre = etat === 'finie' ? 'fini' : ref.sens === 'l' ? 'lu'
        : d && d.cible === g.chemin && d.arbre === g.arbre && d.ms === ref.ms ? 'en-cours' : 'modifie';
      let m = marques.get(g.chemin);
      if (!m) { m = { rang: -1, noms: [] }; marques.set(g.chemin, m); }
      if (RANG[degre] > m.rang) { m.rang = RANG[degre]; m.noms = []; }
      if (RANG[degre] === m.rang && !m.noms.includes(p.noms[ref.k])) m.noms.push(p.noms[ref.k]);
    }
  }
  const nomDe = ['fini', 'lu', 'modifie', 'en-cours'];
  const tuples = [...marques].sort((a, b) => cmp(a[0], b[0])).map(([chemin, m]) => [chemin, nomDe[m.rang], m.noms.sort(cmp)]);
  const rs = raisons(p, r.compte);
  return { etat: p.enConstruction ? 'en-construction' : p.contexteTronque ? 'tronque' : 'ok',
    incomplet: rs.length > 0, limite: [LIMITE, ...rs], marques: tuples, horsCarte: r.compte.horsCarte, horsLab: r.compte.horsLab,
    coupees: r.compte.coupees, rejetes: r.compte.rejetes, ignorees: p.ignorees, voiesTronquees: p.voiesTronquees };
}
