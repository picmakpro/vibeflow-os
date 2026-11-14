// vf-cockpit-agents-table — la table des agents de la collecte et la lecture d'un agent hors de la boucle (79-22, SOCL-27 ; A48 point 47, A50).
// Les routes /api/vf/transcript et /api/vf/doing ne lancent plus une collecte par requête : le tour du fil de collecte (79-09) bâtit une table
// identifiant -> { genre, fichier } ; la lecture du fichier se fait DANS LE FIL, avec les bornes d'avant (reduireTranscript, lastDoing).
// Exports : TABLE_MAX (2 000), creerTable({ max }) -> { remplacer(travailleurs, roles), chercher(id), roles } (côté fil ; les chemins n'en sortent jamais),
//           lireDansLeFil({ quoi, id, table, racine }) -> corps de `cockpit-doing@1` ou `cockpit-transcript@2` (côté fil ; toute exception :
//             corps `inconnu`, sans message, sans nom d'erreur, sans chemin), poserLecteurAgents(fn, sauf) (pilote : fn(quoi, id, signal) ->
//             promesse du corps ; nul retire, et `sauf` ne retire que si c'est encore ce lecteur), lireAgent(quoi, id, { horloge }) -> promesse
//             du corps (côté route : au plus 16 lectures en vol, 10 s, sinon le corps `inconnu` de l'ancien chemin ; jamais un code d'erreur de plus).
// Aucune écriture, aucune variable d'environnement, aucun lancement de processus, aucun réseau. Seul l'identifiant, déjà validé par ID_RE, sert de clé.
import fs from 'node:fs';
import { ID_RE } from './vf-cockpit-lecture.mjs';
import { revealDoing, revealTranscript } from './vf-cockpit-who.mjs';

export const TABLE_MAX = 2000;
const EN_VOL_MAX = 16, DELAI_MS = 10000;
const SCHEMAS = { doing: 'vibeflow/cockpit-doing@1', transcript: 'vibeflow/cockpit-transcript@2' };
// le corps d'un agent inconnu : celui de l'ancien chemin, le même pour « absent » et « lecture impossible » (le texte d'une erreur ne sort jamais)
const inconnu = (quoi, id) => {
  const i = String(id).slice(0, 128);
  return quoi === 'doing' ? { schema: SCHEMAS.doing, id: i, doing: null, erreur: 'inconnu' } : { schema: SCHEMAS.transcript, id: i, erreur: 'inconnu' };
};

export function creerTable({ max = TABLE_MAX } = {}) {
  let m = new Map(), roles = new Map();
  return {
    // les seuls travailleurs de genre session ou subagent, d'identifiant valide et de chemin chaîne ; les plus récents d'abord (tri stable
    // sur `ageS`) ; l'ensemble REMPLACE le précédent
    remplacer(travailleurs, rolesCarte) {
      const genre = (w) => w && (w.kind === 'session' || w.kind === 'subagent');
      const liste = Array.isArray(travailleurs) ? travailleurs : [];
      const ok = liste.filter((w) => genre(w) && typeof w.id === 'string' && ID_RE.test(w.id) && typeof w._tr === 'string');
      const age = (w) => (Number.isFinite(w.ageS) ? w.ageS : Infinity);
      const neuf = new Map();
      const tries = ok.map((x, i) => [x, i]).sort((a, b) => age(a[0]) - age(b[0]) || a[1] - b[1]).map((x) => x[0]);
      for (const w of tries) {
        if (neuf.size >= max) break; // garde:agents-borne
        if (!neuf.has(w.id)) neuf.set(w.id, { genre: w.kind, fichier: w._tr });
      }
      m = neuf; // garde:agents-remplace
      roles = new Map([...(rolesCarte instanceof Map ? rolesCarte : [])].filter(([id]) => neuf.has(id)));
    },
    chercher: (id) => m.get(id) || null,
    get roles() { return roles; },
  };
}

// côté fil : le corps lu dans la table, sans collecte ; le fichier disparu ou non ordinaire, comme toute exception, donne le corps `inconnu`
export function lireDansLeFil({ quoi, id, table, racine }) {
  const q = quoi === 'doing' ? 'doing' : 'transcript';
  try {
    const e = typeof id === 'string' && ID_RE.test(id) ? table.chercher(id) : null;
    if (!e || !fs.statSync(e.fichier).isFile()) return inconnu(q, id);
    const opts = { table: (i) => { const t = table.chercher(i); return t ? { ...t, roles: table.roles } : null; } };
    const corps = q === 'doing' ? revealDoing(racine, id, opts) : revealTranscript(racine, id, opts);
    return corps; // garde:agents-sortie
  } catch { return inconnu(q, id); } // garde:agents-erreur
}

// côté route : le lecteur posé par le pilote ; sans lui (fil absent), au-delà de 16 lectures en vol ou après 10 s : le corps `inconnu`
let lecteur = null, enVol = 0;
export function poserLecteurAgents(fn, sauf) {
  if (typeof fn === 'function') lecteur = fn; else if (sauf === undefined || sauf === lecteur) lecteur = null;
}
export async function lireAgent(quoi, id, { horloge = { setTimeout, clearTimeout } } = {}) {
  const vide = inconnu(quoi, id);
  if (!lecteur || typeof id !== 'string' || !ID_RE.test(id)) return vide;
  if (enVol >= EN_VOL_MAX) return vide; // garde:agents-file
  enVol++; const ctl = new AbortController();
  const delai = new Promise((res) => { ctl.signal.addEventListener('abort', () => res(null), { once: true }); });
  const t = horloge.setTimeout(() => ctl.abort(), DELAI_MS);
  try {
    const corps = await Promise.race([lecteur(quoi, id, ctl.signal), delai]); // garde:agents-table
    return corps && typeof corps === 'object' ? corps : vide;
  } catch { return vide; } finally { horloge.clearTimeout(t); ctl.abort(); enVol--; }
}
