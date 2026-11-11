// vf-cockpit-equipe-etat — ce que le transcript d'un agent dit de son état (AUDC-D1) : un appel d'outil lancé et sans résultat.
// Exports : SILENCE_MAX_S (1800 s), ATTEND_UN_ENFANT (outils dont l'appel sans résultat veut dire « j'attends un agent »), outilEnCours(fichier) -> { nom } | null.
// Lecture seule, aucun réseau ; seul le NOM de l'outil sort (jamais une entrée, un argument ou une sortie : P69-D-16, P69-D-19).
import { cherche } from './vf-cockpit-lecture.mjs';

// au-delà de ce silence, un agent non fini n'est plus dit vivant (le TTL des verrous de driver-lock.sh, la même borne que « session parente muette », PU-G-182)
export const SILENCE_MAX_S = 1800;
// un appel d'agent ou de message sans résultat : l'agent attend un autre agent, il ne travaille pas (état « en attente », jamais « actif »)
export const ATTEND_UN_ENFANT = new Set(['Agent', 'Task', 'SendMessage']);

// En remontant le transcript : un résultat d'outil rencontré d'abord ferme l'appel qui le précède ; le dernier appel d'outil d'une ligne assistant
// est « en cours » tant qu'aucun résultat de son identifiant ne le suit. Une ligne assistant sans appel d'outil, ou le mandat, clôt la recherche.
export function outilEnCours(fichier) {
  const resolus = new Set();
  const r = cherche(fichier, (d) => {
    const c = d?.message?.content;
    if (d.type === 'user') {
      if (!Array.isArray(c)) return { nom: null };
      for (const b of c) if (b?.type === 'tool_result' && typeof b.tool_use_id === 'string') resolus.add(b.tool_use_id);
      return null;
    }
    if (d.type !== 'assistant' || !Array.isArray(c)) return null;
    for (let k = c.length - 1; k >= 0; k--) {
      const b = c[k];
      if (b?.type === 'tool_use' && typeof b.name === 'string') return { nom: typeof b.id === 'string' && resolus.has(b.id) ? null : b.name };
    }
    return { nom: null };
  });
  return r && r.nom ? { nom: r.nom } : null;
}
