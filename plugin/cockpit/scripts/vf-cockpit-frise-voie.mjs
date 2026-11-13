// vf-cockpit-frise-voie — projection PUBLIQUE d'une voie de la frise, sérialisation canonique et signature (79-13, SOCL-17 ; C3, A21, A28, A31, A35, A47).
// Exports : VOIES_MAX (2 000 : borne de l'instantané), CHAMPS_VOIE (les 23 champs de C3), projeterVoie(publique, { arbre, etatOfficiel,
//  rattachement, cibles }),
//   canon(valeur) (clés triées à tout niveau, tableaux dans l'ordre), sigFrise({ source, tronque, voies }) -> 16 caractères hexadécimaux.
// Liste blanche champ par champ, sous-champs compris : jamais la voie brute étalée (curseur, forme, versions, entrée d'outil, texte n'en sortent
//  pas). `arbre` :
// nul (arbre principal) ou le nom d'un worktree PROUVÉ, jamais un libellé ni un chemin. La signature porte la projection entière, cibles
//  comprises, jamais l'instant.
import crypto from 'node:crypto';

export const VOIES_MAX = 2000;
export const CHAMPS_VOIE = Object.freeze(['id', 'kind', 'session', 'parent', 'depth', 'role', 'arbre', 'background', 'debut', 'fin', 'dispatchA', 'fini',
  'arrete', 'etatOfficiel', 'modeles', 'compteurs', 'jetons', 'durees', 'segments', 'evenements', 'enCours', 'rattachement', 'cibles']);

const COMPTEURS = ['appels', 'erreurs', 'refus', 'questions', 'compactions', 'tours', 'reponsesApi'];
const JETONS = ['entree', 'sortie', 'cacheLu', 'cacheCree', 'contexteMax', 'contexteDernier'];
const DUREES = ['travailS', 'attenteHumainS', 'attenteAgentsS', 'reposS', 'silenceS'];
const pick = (o, cles) => (o && typeof o === 'object' ? Object.fromEntries(cles.map((k) => [k, o[k]])) : null);
const cible = (e) => ({ arbre: e.arbre, cible: e.cible, n: e.n, dernierMs: e.dernierMs });

function ciblesDe(c) {
  if (!c || typeof c !== 'object') return null;
  return { etat: c.etat, tronque: c.tronque === true, ecritures: (c.ecritures || []).map(cible), lectures: (c.lectures || []).map(cible) };
}

export function projeterVoie(p, { arbre = null, etatOfficiel = null, rattachement = null, cibles = null } = {}) {
  const inc = p.forme === 'inconnue' || !p.compteurs; // forme inconnue : mesures et cibles nulles, jamais un zéro (P69-D-22)
  return { // garde:frise-liste-blanche
    id: p.id, kind: p.kind, session: p.session, parent: p.parent, depth: p.depth, role: p.role, arbre, background: p.background, debut: p.debut, fin: p.fin,
    dispatchA: p.dispatchA, fini: p.fini, arrete: p.arrete, etatOfficiel, modeles: Array.isArray(p.modeles) ? p.modeles.map(String) : [],
    compteurs: pick(p.compteurs, COMPTEURS), jetons: pick(p.jetons, JETONS), durees: pick(p.durees, DUREES),
    segments: Array.isArray(p.segments) ? p.segments.map((s) => [s[0], s[1], s[2]]) : null,
    evenements: Array.isArray(p.evenements) ? p.evenements.map((e) => [e[0], e[1]]) : null,
    enCours: p.enCours ? { verbe: p.enCours.verbe, depuisMs: p.enCours.depuisMs } : null,
    rattachement: rattachement ? { dag: rattachement.dag, noeud: rattachement.noeud, source: rattachement.source } : null,
    cibles: inc ? null : ciblesDe(cibles),
  };
}

export function canon(v) {
  if (Array.isArray(v)) return v.map(canon);
  if (v && typeof v === 'object') { const o = {}; for (const k of Object.keys(v).sort()) o[k] = canon(v[k]); return o; } // garde:frise-canon
  return v;
}

export function sigFrise({ source, tronque, voies }) {
  const corps = JSON.stringify(canon({ source, tronque, voies })); // garde:frise-sig
  return crypto.createHash('sha256').update(corps).digest('hex').slice(0, 16);
}
