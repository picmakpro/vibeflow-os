// vf-cockpit-state — l'état du cockpit en une seule route, GET /api/vf/state (79-12, SOCL-16 ; C2, P79-D-02, A31).
// Enveloppe vibeflow/cockpit-state@1 autour du `signal` du DERNIER instantané de la collecte (vf-cockpit-instantane.mjs), lu en mémoire : la route ne
// déclenche jamais de collecte et ne lit pas le lab. `collecte` est reconstruit champ par champ (liste blanche de cinq champs) : les diagnostics du direct
// (index, boucle, erreurs, relances, derniereMort) restent sur la route privée /api/vf/etat.
// Exports : SCHEMA_STATE, VOLATILS_ETAT, FENETRE_LECTEUR_MS, collecteDe(brut, { signalNul }), corpsState({ instantane, collecte, seq, now }),
//   sigState(signal), creerLecteurs({ fenetreMs }), LECTEURS, lireState(ctx, req, url) (le lecteur de la ligne de table).
import { instantane } from './vf-cockpit-instantane.mjs';

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

// signature, volatils et lecteurs : posés par la tâche 3 du plan
export const VOLATILS_ETAT = new Set();
export const sigState = () => null;
export const FENETRE_LECTEUR_MS = 30000;
export const creerLecteurs = () => ({ vu() {}, actif: () => false });
export const LECTEURS = creerLecteurs();

// le lecteur de la ligne de table : lit `etat()` du direct et `instantane()`, rien d'autre
export function lireState(ctx) {
  const e = ctx.live ? ctx.live.etat() : null; // garde:state-lecture
  const collecte = e ? e.collecte : { etat: 'indisponible', mode: 'absent', clients: ctx.clients.size };
  return corpsState({ instantane: instantane(), collecte, seq: e ? e.seq : 0, now: Date.now() });
}
