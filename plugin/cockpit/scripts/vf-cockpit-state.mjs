// vf-cockpit-state — l'état du cockpit en une seule route, GET /api/vf/state (79-12, SOCL-16 ; C2, P79-D-02, A31).
// Enveloppe vibeflow/cockpit-state@1 autour du `signal` du DERNIER instantané de la collecte (vf-cockpit-instantane.mjs), lu en mémoire : la route ne
// déclenche jamais de collecte et ne lit pas le lab. `collecte` est reconstruit champ par champ (liste blanche de cinq champs) : les diagnostics du direct
// (index, boucle, erreurs, relances, derniereMort) restent sur la route privée /api/vf/etat.
// Exports : SCHEMA_STATE, VOLATILS_ETAT, FENETRE_LECTEUR_MS, collecteDe(brut, { signalNul }), corpsState({ instantane, collecte, seq, now }),
//   sigState(signal), creerLecteurs({ fenetreMs }), LECTEURS, lireState(ctx, req, url) (le lecteur de la ligne de table).
import crypto from 'node:crypto';
import { instantane } from './vf-cockpit-instantane.mjs';
import { CHAMPS_VOLATILS } from './vf-cockpit-who-signature.mjs';

export const SCHEMA_STATE = 'vibeflow/cockpit-state@1';
const ETATS = ['ok', 'en-cours', 'partielle', 'indisponible'], MODES = ['watch', 'poll', 'absent'];
const HEURE = 3600000, CLIENTS_MAX = 1000000;
const ent = (v, max) => (Number.isInteger(v) && v > 0 && v <= max ? v : 0);
const iso = (v) => (typeof v === 'string' && v.length <= 40 && /^\d{4}-\d{2}-\d{2}T[0-9:.]+Z$/.test(v) ? v : null);
const etatDe = (v) => (ETATS.includes(v) ? v : 'indisponible'), modeDe = (v) => (MODES.includes(v) ? v : 'absent');
const champs = (b) => ({ etat: etatDe(b.etat), derniereA: iso(b.derniereA), mode: modeDe(b.mode), // garde:state-liste-blanche
  dureeMs: ent(b.dureeMs, HEURE), clients: ent(b.clients, CLIENTS_MAX) });

export function collecteDe(brut, { signalNul = false } = {}) {
  const c = champs(brut && typeof brut === 'object' ? brut : {});
  if (signalNul && (c.etat === 'ok' || c.etat === 'partielle')) c.etat = 'en-cours'; // garde:state-coherence
  return c;
}

export const corpsState = ({ instantane: inst, collecte, seq, now = Date.now() } = {}) => {
  const signal = inst && inst.signal && typeof inst.signal === 'object' ? inst.signal : null;
  const c = collecteDe(collecte, { signalNul: signal === null });
  return { schema: SCHEMA_STATE, at: new Date(now).toISOString(), seq: ent(seq, Number.MAX_SAFE_INTEGER), collecte: c, signal };
};

// Signature (événement `etat`, C4) : 16 caractères hexadécimaux d'un sha256 du `signal` ramené à une forme canonique (clés triées à tout niveau, clés
// volatiles retirées à tout niveau, ordre des tableaux gardé). La liste nommée est la seule chose à tenir à jour : une clé qui varie avec le seul temps
// s'y inscrit, jamais une énumération de champs.
export const VOLATILS_ETAT = new Set([...CHAMPS_VOLATILS, 'progressAgeS', 'fetchAgeS']); // garde:state-volatils
const cles = (o) => Object.keys(o).sort().filter((k) => !VOLATILS_ETAT.has(k)); // garde:state-canonique
const canon = (v) => (Array.isArray(v) ? v.map(canon) : v && typeof v === 'object' ? Object.fromEntries(cles(v).map((k) => [k, canon(v[k])])) : v);
export const sigState = (signal) => (signal && typeof signal === 'object'
  ? crypto.createHash('sha256').update(JSON.stringify(canon(signal))).digest('hex').slice(0, 16) : null);

// Lecteurs d'état sans onglet (A31) : deux lectures à moins de la fenêtre l'une de l'autre arment le filet de collecte tant que la dernière est à moins
// de la fenêtre de `now` ; une lecture isolée (pane fermée, une émission par minute) ne l'arme pas. L'horloge est injectée (`now`).
export const FENETRE_LECTEUR_MS = 30000;
export function creerLecteurs({ fenetreMs = FENETRE_LECTEUR_MS } = {}) {
  let serie = 0, dernier = null;
  return {
    vu(now = Date.now()) { serie = dernier !== null && now >= dernier && now - dernier < fenetreMs ? serie + 1 : 1; dernier = now; }, // garde:lecteurs-fenetre
    actif(now = Date.now()) { return serie >= 2 && dernier !== null && now - dernier < fenetreMs; }, // garde:lecteurs-serie
  };
}
export const LECTEURS = creerLecteurs();

// le lecteur de la ligne de table : lit `etat()` du direct et `instantane()`, rien d'autre
export function lireState(ctx) {
  LECTEURS.vu(Date.now()); // appelé après le contrôle d'accès (le répartiteur) : un refus ne marque jamais un lecteur
  const e = ctx.live ? ctx.live.etat() : null; // garde:state-lecture
  const collecte = e ? e.collecte : { etat: 'indisponible', mode: 'absent', clients: ctx.clients.size };
  return corpsState({ instantane: instantane(), collecte, seq: e ? e.seq : 0, now: Date.now() });
}
