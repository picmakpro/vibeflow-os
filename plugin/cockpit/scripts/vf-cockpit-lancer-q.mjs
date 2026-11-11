// vf-cockpit-lancer-q — état de la proposition de lancement dans le processus de Q (72-05 ; P72-D-02, D-03, D-10, D-12, D-13, D-14, D-16).
// Q retient la dernière liste fermée de cibles reçue de P, UNE proposition en attente, valide l'une contre l'autre, la précompose par le gabarit, l'arme,
// la fait expirer et la consomme une seule fois. Aucun octet ne peut partir au PTY pour une cible hors liste : sans ligne composée, rien à écrire.
// Exports : creerEtatLancer({ gabarit, maintenant, genId, uuid, armeMs, expireMs }) -> { definirCibles, proposer, lire, consommer, confirmer, rendre, annuler }, ARME_MS, EXPIRE_MS.
// Module pur : le seul import est node:crypto ; aucune écriture disque, aucun réseau, aucun journal ; deux variables d'environnement de test, lues une fois au chargement (l'armement ne peut qu'être rallongé, jamais abaissé sous 1000).
// Gabarit injecté (72-01, noms de référence) : lignesParModes({ session, verbe, phase, ws, chat }) -> { ok, lignes, intention, nom } ou { ok:false, motif },
//   validerLigne(ligne) -> { ok }, MODES, VERBES. Il est l'unique source de l'alphabet, du préfixe et de la longueur de la ligne : rien n'en est copié ici.
// Consommation en DEUX temps : consommer réserve (la ligne part à l'assistant), confirmer acte (message « lancee » pour P), rendre restitue la proposition
// quand l'écriture est refusée (premier plan occupé) : un refus d'écriture n'est pas un usage.
// ARME_MS = 1000 : délai de protection d'entrée, du même ordre que celui que les navigateurs imposent avant d'activer le bouton d'une boîte de confirmation
//   (0,5 à 1 s) [ASSUMED : ordre de grandeur non mesuré ici] ; assez court pour ne pas gêner une lecture attentive, assez long pour qu'un clic parti avant l'affichage
//   ne tombe pas sur « Lancer ». Compté depuis le PREMIER lire() qui rend la proposition, jamais depuis sa création.
// EXPIRE_MS = 120000 : le temps d'ouvrir le tiroir, de lire les pré-vols et de choisir un mode ; une proposition oubliée ne reste pas armée des heures dans Q.
// Motifs de refus -> statut HTTP que 72-10 en tire : inconnue, consommee, annulee, remplacee, expiree, absente -> 404 ; mode, chat -> 400 ; pas-arme -> 425 ; bloquee, occupee -> 409.
// Variante chat (72-13, additive, dormante sans `chat` dans la proposition) : deux jeux de lignes, MÊME session ; lire() ajoute chat:true et lignes_chat ; consommer(id, mode, chat) prend un booléen strict.
import crypto from 'node:crypto';

const depuisEnv = (v, min, max, defaut) => { const n = Number(v); return Number.isInteger(n) && n >= min && n <= max ? n : defaut; }; // garde:env-bornes
const ARME_DEF = 1000; const EXPIRE_DEF = 120000;
const arme0 = Math.max(ARME_DEF, depuisEnv(process.env.VF_COCKPIT_LANCER_ARME_MS, 100, 10000, ARME_DEF)); // garde:plancher — l'environnement ne peut que RALLONGER l'armement, jamais l'abaisser sous la valeur de production
const expire0 = depuisEnv(process.env.VF_COCKPIT_LANCER_EXPIRE_MS, 1000, 600000, EXPIRE_DEF);
const coherent = expire0 > arme0; // une expiration qui n'excède pas l'armement ne laisserait aucune fenêtre : les deux reprennent leur défaut
export const ARME_MS = coherent ? arme0 : ARME_DEF;
export const EXPIRE_MS = coherent ? expire0 : EXPIRE_DEF;

const ID_RE = /^[A-Za-z0-9][A-Za-z0-9._@:-]{0,127}$/;
const CODE_RE = /^[a-z][a-z0-9-]{0,39}$/;
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/; // minuscules, comme le gabarit (MOTIF_UUID)
const LISTE_MAX = 500; const CODES_MAX = 20; const FERMEES_MAX = 16;

const refus = (motif) => ({ ok: false, motif });
const codesOk = (c) => Array.isArray(c) && c.length <= CODES_MAX && c.every((x) => typeof x === 'string' && CODE_RE.test(x));
const formeOk = (m) => !!m && typeof m === 'object' && typeof m.cible === 'string' && typeof m.verbe === 'string' && codesOk(m.bloquants) && codesOk(m.avertissements)
  && (m.chat === undefined || (typeof m.chat === 'string' && UUID_RE.test(m.chat)));
const entreeOk = (e, verbes) => !!e && typeof e === 'object' && typeof e.id === 'string' && ID_RE.test(e.id) && (e.kind === 'phase' || e.kind === 'mission')
  && Array.isArray(e.verbes) && e.verbes.length >= 1 && e.verbes.length <= 5 && new Set(e.verbes).size === e.verbes.length && e.verbes.every((v) => verbes.includes(v))
  && typeof e.verbe === 'string' && e.verbes.includes(e.verbe);
// Exécuter sur une phase dont l'action principale est cadrer ou planifier (aucun plan) : avertissement ajouté, jamais un bloquant ; le même texte vit dans la page de P et dans la vue (terminal-vue)
const sansPlan = (msg, entree) => [...msg.avertissements, ...(msg.verbe === 'executer' && entree && (entree.principal === 'cadrer' || entree.principal === 'planifier') && !msg.avertissements.includes('phase-sans-plan') ? ['phase-sans-plan'] : [])];
const ligneOk = (gabarit, l) => { try { const r = gabarit.validerLigne(l); return !!r && r.ok === true; } catch { return false; } };

// Appelle le gabarit (une fois, deux avec un chat, même session) ; { ok:false } pour un refus, une exception, des lignes incomplètes ou des intentions divergentes.
function composer(gabarit, base, chat) {
  try {
    const jeu = (extra) => {
      const r = gabarit.lignesParModes({ ...base, ...extra });
      if (!r || r.ok !== true || typeof r.intention !== 'string' || !r.lignes || typeof r.lignes !== 'object') return null;
      if (!gabarit.MODES.every((m) => typeof r.lignes[m] === 'string')) return null;
      return { intention: r.intention, lignes: Object.fromEntries(gabarit.MODES.map((m) => [m, r.lignes[m]])) };
    };
    const a = jeu({}); if (!a) return { ok: false };
    if (chat === undefined) return { ok: true, lignes: a.lignes, intention: a.intention };
    const b = jeu({ chat }); if (!b || b.intention !== a.intention) return { ok: false };
    return { ok: true, lignes: a.lignes, intention: a.intention, lignesChat: b.lignes };
  } catch { return { ok: false }; }
}

export function creerEtatLancer({ gabarit, maintenant = Date.now, genId = () => crypto.randomBytes(16).toString('hex'), uuid = () => crypto.randomUUID(), armeMs = ARME_MS, expireMs = EXPIRE_MS } = {}) {
  let liste = null; // Map id -> { verbes, phase, ws } ; null = aucune liste valide
  let attente = null; let reservation = null;
  const fermees = new Map(); // id -> motif, bornée
  const fermer = (id, motif) => { fermees.set(id, motif); if (fermees.size > FERMEES_MAX) fermees.delete(fermees.keys().next().value); };
  const perimee = (p) => maintenant() - p.cree_a >= expireMs;
  const dansListe = (p) => { const e = liste ? liste.get(p.cible) : null; return !!e && e.verbes.includes(p.verbe); };
  const motifDe = (id) => (reservation && reservation.id === id ? 'consommee' : fermees.get(id) || 'inconnue');
  const pick = (l) => Object.fromEntries(gabarit.MODES.map((m) => [m, l[m]]));

  function definirCibles(l) {
    liste = null; // fail closed : une liste refusée écarte aussi la précédente
    if (!Array.isArray(l) || l.length > LISTE_MAX) return { ok: false, motif: 'liste' };
    const m = new Map(); let retenues = 0; let ecartees = 0;
    for (const e of l) {
      if (!entreeOk(e, gabarit.VERBES)) { ecartees += 1; continue; } // garde:entree-forme
      m.set(e.id, { verbes: [...e.verbes], phase: e.phase, ws: e.ws, principal: e.verbe }); retenues += 1;
    }
    liste = m; return { ok: true, retenues, ecartees };
  }

  function proposer(msg) {
    if (!liste) return refus('liste-absente');
    if (!formeOk(msg)) return refus('forme'); // garde:forme
    const entree = liste.get(msg.cible);
    if (!entree || !entree.verbes.includes(msg.verbe)) return refus('absente'); // garde:liste-proposer
    const { phase, ws } = entree || {};
    const session = uuid();
    const c = composer(gabarit, { session, verbe: msg.verbe, phase, ws }, msg.chat);
    if (!c.ok) return refus('compose'); // garde:compose
    if (![...Object.values(c.lignes || {}), ...Object.values(c.lignesChat || {})].every((l) => ligneOk(gabarit, l))) return refus('compose'); // garde:alphabet
    if (attente) fermer(attente.id, 'remplacee');
    const nouvelle = { id: genId(), cible: msg.cible, verbe: msg.verbe, phase, ws, session, cree_a: maintenant(), vue_a: null, bloquants: [...msg.bloquants], avertissements: sansPlan(msg, entree), lignes: c.lignes, intention: c.intention, chat: msg.chat !== undefined, lignes_chat: c.lignesChat }; // garde:vue-null
    attente = nouvelle; // garde:remplace
    return { ok: true, id: nouvelle.id };
  }

  function lire() {
    if (attente && perimee(attente)) { fermer(attente.id, 'expiree'); attente = null; } // garde:expire
    if (!attente) return { etat: 'aucune' };
    if (!dansListe(attente)) return { etat: 'aucune' }; // garde:liste-lire
    if (attente.vue_a === null) attente.vue_a = maintenant();
    const r = { etat: 'en-attente', id: attente.id, verbe: attente.verbe, intention: attente.intention, phase: attente.phase, ws: attente.ws, lignes: pick(attente.lignes), bloquants: [...attente.bloquants],
      avertissements: [...attente.avertissements], arme_apres_ms: armeMs, expire_ms: attente.cree_a + expireMs - maintenant(), duree_ms: expireMs };
    if (attente.chat) { r.chat = true; r.lignes_chat = pick(attente.lignes_chat); } // jamais l'identifiant du chat hors des lignes de reprise
    return r;
  }

  function consommer(id, mode, chat) {
    if (!attente || attente.id !== id) return refus(motifDe(id));
    if (perimee(attente)) { fermer(attente.id, 'expiree'); attente = null; return refus('expiree'); } // garde:expire
    if (!dansListe(attente)) return refus('absente'); // garde:liste-consommer
    if (!gabarit.MODES.includes(mode)) return refus('mode'); // garde:mode
    if (chat !== undefined && typeof chat !== 'boolean') return refus('chat'); // garde:chat-type
    if (chat === true && !attente.lignes_chat) return refus('chat'); // garde:chat-absent
    if (attente.bloquants.length > 0) return refus('bloquee');
    if (attente.vue_a === null || maintenant() - attente.vue_a < armeMs) return refus('pas-arme'); // garde:arme
    if (reservation) return refus('occupee'); // garde:occupee
    const ligne = chat === true ? attente.lignes_chat?.[mode] : attente.lignes[mode]; // garde:chat-ligne
    reservation = attente;
    attente = null; // garde:usage-unique
    return { ok: true, ligne, session: reservation.session, cible: reservation.cible, verbe: reservation.verbe };
  }

  function confirmer(id) {
    if (!reservation || reservation.id !== id) return null;
    const r = reservation; reservation = null; fermer(id, 'consommee');
    return { t: 'lancee', cible: r.cible, verbe: r.verbe, session: r.session, at: maintenant() };
  }

  function rendre(id) {
    if (!reservation || reservation.id !== id) return { restauree: false };
    const r = reservation; reservation = null;
    if (!perimee(r) && !attente) attente = r; // garde:rendre
    if (attente !== r) fermer(id, perimee(r) ? 'expiree' : 'remplacee');
    return { restauree: attente === r };
  }

  function annuler(id) {
    if (!attente || attente.id !== id) return { ok: false };
    fermer(id, 'annulee'); attente = null; return { ok: true };
  }

  return { definirCibles, proposer, lire, consommer, confirmer, rendre, annuler };
}
