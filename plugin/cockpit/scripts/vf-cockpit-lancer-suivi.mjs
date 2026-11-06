// vf-cockpit-lancer-suivi — suivi des lancements depuis les cartes (LANC-10 ; P72-D-06, P72-D-16, P72-D-18).
// Exports : creerSuivi({ maintenant }) -> { noter(msg, ctx), lancements(), etats(who), lancees(), taille() },
//           ATTENTE_MAX_MS, TTL_MS, MAX_ENTREES, LIBELLES_VERBES, entreeLanceeValide({ phase, ws, verbe }).
// EN MÉMOIRE seulement : jamais écrit, jamais journalisé, jamais diffusé (journal, SSE, export). Le contrat `interdits` de
// vf-cockpit-interface.json (doing, mandat, messages, outils) vaut pour tout objet rendu. Module pur : aucun import, aucune lecture d'environnement.
// L'horodatage d'une entrée est l'horloge de P, jamais le champ `at` du message. Le rattachement à la collecte Équipe se fait par
// l'IDENTIFIANT de session SEUL (nom du transcript) : un nom de session, un rôle, un titre, une tâche ne sont jamais une clé.
// La fenêtre de récence (« lancement récent ») vit dans vf-cockpit-lancer-cibles.mjs (RECENCE_MS) : une seule source, ce module n'en juge pas.
export const ATTENTE_MAX_MS = 600000; // dix minutes : une ligne laissée à l'invite sans Entrée, ou la boîte de confiance du dossier qui attend l'utilisateur (P72-D-19)
export const TTL_MS = 86400000; // la fenêtre de 24 h de la collecte Équipe (FENETRE × 1000) : au-delà, une session absente de `who` n'est plus visible
export const MAX_ENTREES = 200;
export const LIBELLES_VERBES = Object.freeze({ cadrer: 'Cadrer', planifier: 'Planifier', executer: 'Exécuter', verifier: 'Vérifier', reprendre: 'Reprendre' });

const CIBLE_RE = /^[A-Za-z0-9][A-Za-z0-9._@:-]{0,127}$/;
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;
const PHASE_RE = /^\d+(?:\.\d+)?$/;
const WS_RE = /^[a-z0-9][a-z0-9-]{0,39}$/;
const verbeOk = (v) => typeof v === 'string' && Object.hasOwn(LIBELLES_VERBES, v);
const phaseOk = (p) => typeof p === 'string' && PHASE_RE.test(p);
const wsOk = (w) => w === null || w === undefined || w === '' || (typeof w === 'string' && WS_RE.test(w));

// Seuls des types `string` sont lus, aucune coercition : un objet à `toString` piégé est refusé.
export function entreeLanceeValide(e) {
  if (!e || typeof e !== 'object') return false;
  const { phase, ws, verbe } = e;
  return phaseOk(phase) && wsOk(ws) && verbeOk(verbe);
}

export function creerSuivi({ maintenant = Date.now } = {}) {
  const entrees = new Map(); // session -> { cible, verbe, session, at, phase, ws, vue_a } (ordre d'insertion = ordre chronologique)
  const purge = () => {
    const now = maintenant();
    for (const [k, e] of entrees) {
      if (now - e.at >= TTL_MS) entrees.delete(k); // garde:ttl
      if (e.vue_a === null && now - e.at >= ATTENTE_MAX_MS) entrees.delete(k); // garde:attente-max
    }
  };
  const noter = (msg, ctx = {}) => {
    const { cible, verbe, session } = msg && typeof msg === 'object' ? msg : {};
    if (!(typeof cible === 'string' && CIBLE_RE.test(cible) && verbeOk(verbe) && typeof session === 'string' && UUID_RE.test(session))) return { ok: false, motif: 'forme' }; // garde:forme
    if (entrees.has(session)) return { ok: true, deja: true };
    const c = ctx && typeof ctx === 'object' ? ctx : {};
    entrees.set(session, { cible, verbe, session, at: maintenant(), phase: phaseOk(c.phase) ? c.phase : null, ws: typeof c.ws === 'string' && c.ws !== '' && wsOk(c.ws) ? c.ws : null, vue_a: null }); // garde:at-de-p
    while (entrees.size > MAX_ENTREES) entrees.delete(entrees.keys().next().value); // garde:max
    return { ok: true };
  };
  const lancements = () => { purge(); return [...entrees.values()].map((e) => ({ cible: e.cible, verbe: e.verbe, at: e.at })); };
  const etats = (who) => {
    purge();
    const sessions = (Array.isArray(who?.workers) ? who.workers : []).filter((w) => w && w.kind === 'session' && typeof w.id === 'string');
    const out = new Map();
    for (const e of entrees.values()) { // du plus ancien au plus récent : le plus récent d'une cible décide
      const w = sessions.find((w) => w.id === e.session); // garde:session-id
      if (w && e.vue_a === null) e.vue_a = maintenant();
      const etat = w ? (w.etat === 'termine' ? 'terminee' : 'vue') : e.vue_a !== null ? 'terminee' : 'attendue'; // garde:termine
      out.set(e.cible, { etat, verbe: e.verbe });
    }
    return out;
  };
  const lancees = () => { purge(); return new Map([...entrees.values()].map((e) => [e.session, { phase: e.phase, ws: e.ws, verbe: e.verbe }])); };
  const taille = () => { purge(); return entrees.size; };
  return { noter, lancements, etats, lancees, taille };
}
