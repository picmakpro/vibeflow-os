// vf-cockpit-lancer-gabarit — gabarit de la ligne de commande lancée depuis une carte du cockpit (Phase 72, LANC-05 et LANC-09 ; P72-D-13, P72-D-19).
// C'est le SEUL endroit du dépôt où la forme de la ligne est écrite. Module pur : aucune dépendance, aucun accès au système de fichiers,
// à l'environnement, à l'horloge ni au hasard. La ligne est tapée dans le shell de l'utilisateur : elle ne dépend donc que de six variables fermées
// (phase, compartiment, verbe, mode, UUID de session, UUID de chat) et JAMAIS d'un titre, d'un Goal, d'un nom de mission ou de nœud.
// Forme : claude --session-id '<uuid4>' [-r '<uuid>' --fork-session] -n '<nom>' [--permission-mode '<mode>'] '/vf-dev <intention>'
//   chaque argument entre guillemets simples, alphabet fermé (aucun métacaractère de shell), 400 caractères au plus ; `herite` = aucun drapeau de mode (P72-D-02).
// Une valeur hors motif ou hors liste est REFUSÉE avec un code fermé : jamais nettoyée, jamais corrigée, aucune ligne rendue (P72-D-13).
// Exports : constantes (NOM_SKILL, motifs, listes, alphabet), intentionDe, nomSession, composerLigne, lignesParModes, validerLigne.

// P72-D-19 : l'engine pose les skills d'un module sous .claude/skills/<nom>/ sans préfixe de plugin (mesuré par une installation réelle, suite G12)
export const NOM_SKILL = 'vf-dev';
export const MOTIF_PHASE = /^\d+(?:\.\d+)?$/;
export const MOTIF_COMPARTIMENT = /^[a-z0-9][a-z0-9-]{0,39}$/;
export const MOTIF_UUID_V4 = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;
export const MOTIF_UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
export const VERBES = Object.freeze(['cadrer', 'planifier', 'executer', 'verifier', 'reprendre']);
export const MODES = Object.freeze(['default', 'acceptEdits', 'plan', 'herite']);
// littéral normatif, repris À L'IDENTIQUE par l'assistant du terminal (revalidation de son côté)
export const ALPHABET_CLASSE = "[A-Za-z0-9 ._:/'-]";
export const ALPHABET = new RegExp('^' + ALPHABET_CLASSE + '+$');
export const LIGNE_MAX = 400;
export const PREFIXE_LIGNE = "claude --session-id '";
export const MOTIFS_REFUS = Object.freeze(['phase', 'compartiment', 'verbe', 'mode', 'session', 'chat', 'forme']);

// P72-D-15 : une intention par verbe, en ASCII sans accent ni apostrophe, jamais une commande gsd-*
const IMPERATIFS = Object.freeze({ cadrer: 'Cadre', planifier: 'Planifie', executer: 'Execute', verifier: 'Verifie', reprendre: 'Reprends' });
const MODES_AVEC_DRAPEAU = 'default|acceptEdits|plan';
const frag = (re) => re.source.slice(1, -1);
// grammaire entière de la ligne, construite UNE fois à partir des fragments de motif
const GRAMMAIRE = new RegExp(`^${PREFIXE_LIGNE}${frag(MOTIF_UUID_V4)}'(?: -r '${frag(MOTIF_UUID)}' --fork-session)? -n 'vf-phase-\\d+(?:-\\d+)?(?:-${frag(MOTIF_COMPARTIMENT)})?'`
  + `(?: --permission-mode '(?:${MODES_AVEC_DRAPEAU})')? '/${NOM_SKILL} (?:${Object.values(IMPERATIFS).join('|')}) la Phase \\d+(?:\\.\\d+)?(?: du compartiment ${frag(MOTIF_COMPARTIMENT)})?'$`);

// la longueur est vérifiée AVANT toute expression régulière : une chaîne démesurée est refusée sans parcours
const conforme = (valeur, max, motif) => typeof valeur === 'string' && valeur.length <= max && motif.test(valeur);
const phaseOk = (phase) => conforme(phase, 16, MOTIF_PHASE);
const wsOk = (ws) => ws === null || conforme(ws, 40, MOTIF_COMPARTIMENT); // null = lab plat ; undefined et chaîne vide sont refusés
const refus = (motif) => ({ ok: false, motif });

// impératif + « la Phase <n> » + « du compartiment <ws> » si le lab est partitionné ; null si une valeur est hors motif
export function intentionDe(verbe, phase, ws) {
  if (!VERBES.includes(verbe) || !phaseOk(phase) || !wsOk(ws)) return null;
  return `${IMPERATIFS[verbe]} la Phase ${phase}` + (ws === null ? '' : ` du compartiment ${ws}`);
}

// P72-D-16 : -n ne porte que des identifiants ; le point d'une phase décimale devient un tiret
export function nomSession(phase, ws) {
  if (!phaseOk(phase) || !wsOk(ws)) return null;
  return 'vf-phase-' + phase.replace('.', '-') + (ws === null ? '' : '-' + ws);
}

// ne lit QUE session, verbe, mode, phase, ws, chat : tout autre champ de l'entrée est ignoré par construction
export function composerLigne(entree) {
  const { session, verbe, mode, phase, ws, chat } = entree || {};
  if (!phaseOk(phase)) return refus('phase');
  if (!wsOk(ws)) return refus('compartiment');
  if (!VERBES.includes(verbe)) return refus('verbe');
  if (!MODES.includes(mode)) return refus('mode');
  if (!conforme(session, 36, MOTIF_UUID_V4)) return refus('session');
  const avecChat = chat !== undefined && chat !== null;
  if (avecChat && !conforme(chat, 36, MOTIF_UUID)) return refus('chat'); // P72-D-03 : un chat mal formé est refusé, jamais écarté en silence
  const intention = intentionDe(verbe, phase, ws), nom = nomSession(phase, ws);
  let ligne = PREFIXE_LIGNE + session + "'";
  if (avecChat) ligne += ` -r '${chat}' --fork-session`;
  ligne += ` -n '${nom}'`;
  if (mode !== 'herite') ligne += ` --permission-mode '${mode}'`;
  ligne += ` '/${NOM_SKILL} ${intention}'`;
  return validerLigne(ligne).ok ? { ok: true, ligne, intention, nom } : refus('forme'); // garde interne : jamais atteinte avec des entrées valides
}

// une ligne par mode (le bandeau retient le mode au lancement, la ligne est précomposée), ou le premier refus
export function lignesParModes(entree) {
  const { session, verbe, phase, ws, chat } = entree || {};
  const lignes = {}; let intention = null, nom = null;
  for (const mode of MODES) {
    const r = composerLigne({ session, verbe, mode, phase, ws, chat });
    if (!r.ok) return r;
    lignes[mode] = r.ligne; intention = r.intention; nom = r.nom;
  }
  return { ok: true, lignes, intention, nom };
}

// grammaire entière : type, longueur, alphabet, forme (plus stricte que la revalidation de l'assistant du terminal)
export function validerLigne(ligne) {
  if (typeof ligne !== 'string') return refus('type');
  if (ligne.length === 0 || ligne.length > LIGNE_MAX) return refus('longueur');
  if (!ALPHABET.test(ligne)) return refus('alphabet');
  return GRAMMAIRE.test(ligne) ? { ok: true } : refus('forme');
}
