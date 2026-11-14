// vf-cockpit-frise — la route GET /api/vf/frise (79-13, SOCL-17 ; C3, A10, A11, A28, A31, A35, A47, A48-46).
// Exports : SCHEMA_FRISE, VOIES_REPONSE_MAX (500), lireBornes(url, now), projeterReponse(frise, bornes, champs, now, voiesMax),
//   creerLecteurFrise({ voiesMax, horloge }), lireFrise (le lecteur de la ligne de table).
// La route LIT l'instantané en mémoire (vf-cockpit-instantane.mjs) et la poignée du direct : elle ne déclenche jamais de collecte, ne lit ni
// fichier ni lab, ne fait aucun appel réseau. Sa réponse sort par la réponse gardée de 79-05 (accès contrôlé, garde d'émission, no-store).
// Paramètres : `depuis` et `jusqua` (entiers signés de 15 chiffres au plus, en millisecondes, chacun une seule fois), `champs=cibles`. Fenêtre
// bornée à 24 h ; une fenêtre vide après bornage est refusée. Corps d'erreur : `bornes-invalides`, `champs-invalides`.
import { instantane } from './vf-cockpit-instantane.mjs';
import { reponse } from './vf-cockpit-routes.mjs';

export const SCHEMA_FRISE = 'vibeflow/cockpit-frise@1';
export const VOIES_REPONSE_MAX = 500;
const FENETRE_MS = 86400000, ENTIER = /^-?[0-9]{1,15}$/;
const EN_CONSTRUCTION = Object.freeze({ etat: 'en-construction', ccVerifie: null, versionsVues: [] });
const DUREE_DE = { travail: 'travailS', 'attend-humain': 'attenteHumainS', 'attend-agents': 'attenteAgentsS', repos: 'reposS', silence: 'silenceS' };
const GH = 'attend-humain', cmp = (a, b) => (a < b ? -1 : a > b ? 1 : 0);
const vivante = (v) => !!v.etatOfficiel && v.etatOfficiel !== 'termine';
const chevauche = (v, b) => (v.debut ?? 0) <= b.jusqua && (v.fin ?? v.debut ?? 0) >= b.depuis;

// valeurs brutes validées d'abord (non entier, répété, vide : refus ; depuis >= jusqua : refus), puis bornage à 24 h et seconde validation ; null = refus
export function lireBornes(url, now) {
  const q = url.searchParams;
  const lire = (k) => { const v = q.getAll(k); return !v.length ? null : v.length === 1 && ENTIER.test(v[0]) ? +v[0] : NaN; }; // garde:frise-bornes
  let depuis = lire('depuis'), jusqua = lire('jusqua');
  if (Number.isNaN(depuis) || Number.isNaN(jusqua)) return null;
  if (depuis !== null && jusqua !== null && depuis >= jusqua) return null;
  depuis = Math.max(depuis ?? 0, now - FENETRE_MS); // garde:frise-fenetre
  jusqua = Math.min(jusqua ?? now, now);
  return depuis < jusqua ? { depuis, jusqua } : null;
}

// la voie coupée à la fenêtre : segments et événements, durées recalculées, queue d'attente de permission (A35, ajoutée à la réponse seulement)
function coupee(v, b) {
  if (!v.segments) return v;
  const segs = v.segments.map((s) => [Math.max(s[0], b.depuis), Math.min(s[1], b.jusqua), s[2]]).filter((s) => s[1] > s[0]);
  const attend = v.etatOfficiel === 'attend' && v.enCours !== null && !v.fini;
  const queue = attend && v.fin !== null && v.fin < b.jusqua ? [Math.max(v.fin, b.depuis), b.jusqua, GH] : null; // garde:frise-attend
  const dernier = segs[segs.length - 1];
  if (queue) { if (dernier && dernier[2] === queue[2] && dernier[1] === queue[0]) dernier[1] = queue[1]; else segs.push(queue); }
  const ms = {}; for (const [a, z, g] of segs) ms[g] = (ms[g] || 0) + (z - a);
  const durees = Object.fromEntries(Object.entries(DUREE_DE).map(([g, k]) => [k, Math.round((ms[g] || 0) / 1000)]));
  return { ...v, segments: segs, durees, evenements: (v.evenements || []).filter((e) => e[0] >= b.depuis && e[0] <= b.jusqua) };
}

export function projeterReponse(frise, bornes, champs, now, voiesMax = VOIES_REPONSE_MAX, indispo = false) {
  const f = frise || { source: EN_CONSTRUCTION, tronque: false, voies: [] };
  const dans = f.voies.filter((v) => vivante(v) || chevauche(v, bornes));
  const rang = [...dans].sort((a, b) => Number(vivante(b)) - Number(vivante(a)) || (b.fin ?? 0) - (a.fin ?? 0) || cmp(a.id, b.id));
  const gardees = rang.slice(0, voiesMax); // garde:frise-reponse-borne
  const omises = dans.length - gardees.length; // garde:frise-omises
  const voies = gardees.sort((a, b) => (a.debut ?? 0) - (b.debut ?? 0) || cmp(a.id, b.id)).map((v) => coupee(v, bornes))
    .map((v) => (champs === 'cibles' ? { id: v.id, arbre: v.arbre, cibles: v.cibles } : v));
  return { schema: SCHEMA_FRISE, at: new Date(now).toISOString(), depuis: bornes.depuis, jusqua: bornes.jusqua, fenetreS: 86400,
    source: indispo ? { ...f.source, etat: 'indisponible' } : f.source, tronque: !!f.tronque || omises > 0, voiesOmises: omises, voies };
}

export function creerLecteurFrise({ voiesMax = VOIES_REPONSE_MAX, horloge = Date.now } = {}) {
  return (ctx, req, url) => {
    const now = horloge(), inst = instantane(); // garde:frise-lecture
    const e = ctx.live ? ctx.live.etat() : null, c = e && e.collecte;
    const indispo = !!c && (c.etat === 'indisponible' || (!!c.index && c.index.etat === 'suspendu'));
    const ch = url.searchParams.getAll('champs');
    if (ch.length > 1 || (ch.length === 1 && ch[0] !== 'cibles')) return reponse(400, { erreur: 'champs-invalides' });
    const bornes = lireBornes(url, now);
    if (bornes === null) return reponse(400, { erreur: 'bornes-invalides' });
    return projeterReponse(inst && inst.frise, bornes, ch[0] || null, now, voiesMax, indispo);
  };
}
export const lireFrise = creerLecteurFrise();
