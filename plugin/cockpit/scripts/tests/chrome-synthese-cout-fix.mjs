// chrome-synthese-cout-fix.mjs — fixtures du bloc « Coût » de la Synthèse (77-07), partagées par la suite (sections CO sous vm) et par le scénario navigateur
// (chrome-synthese-cout.mjs). Formes : `vibeflow/cockpit-frise@1` (fabrique de la 74, frise-fabrique.mjs) et `vibeflow/cockpit-state@1` (`signal.missions`,
// `signal.phases`, `signal.jalons`). Aucune horloge, aucun hasard. Tout est JSON : ce que la route rendrait, relu par JSON.parse.
import { fabrique, voie } from './frise-fabrique.mjs';

export const PHASES = [{ key: 'fiabilite|77', n: 77, ws: 'fiabilite', nom: 'Santé de la méthode', fait: false },
  { key: 'fiabilite|78', n: 78, ws: 'fiabilite', nom: 'Équipe en direct', fait: false },
  { key: 'fiabilite|60', n: 60, ws: 'fiabilite', nom: 'Ancienne phase', fait: true }];
export const JALONS = [{ key: 'Jalon courant', icone: '', texte: 'courant', ws: 'fiabilite', phases: ['fiabilite|77', 'fiabilite|78'] },
  { key: 'Jalon clos', icone: '', texte: 'clos', ws: 'fiabilite', phases: ['fiabilite|60'] }];
export const MISSIONS = [{ nom: 'Mission 77', fichier: 'm77.md', phaseKey: 'fiabilite|77' }, { nom: 'Mission 78', fichier: 'm78.md', phaseKey: 'fiabilite|78' },
  { nom: 'Mission 60', fichier: 'm60.md', phaseKey: 'fiabilite|60' }, { nom: 'Mission sans phase', fichier: 'mx.md', phaseKey: null }];

// [id, rôle, kind, rattachement, [entrée, sortie, cache lu, cache créé], travailS] : des nombres tous différents, pour qu'une somme fausse se voie
const LIGNES = [
  ['sess-1', null, 'session', null, [1000, 200, 30000, 1500], 600],
  ['mg-77', 'vf-dev-manager', 'subagent', { dag: 'm77.md', noeud: null, source: 'enfants' }, [2000, 500, 40000, 2500], 1200],
  ['wk-77a', 'vf-coder', 'subagent', { dag: 'm77.md', noeud: 'n1', source: 'registre' }, [30000, 8000, 900000, 40000], 3600],
  ['wk-77b', 'vf-reviewer', 'subagent', { dag: 'm77.md', noeud: 'n2', source: 'registre' }, [4000, 900, 60000, 3000], 900],
  ['wk-78', 'vf-coder', 'subagent', { dag: 'm78.md', noeud: 'n1', source: 'registre' }, [10000, 2500, 300000, 20000], 1800],
  ['wk-60', 'vf-auditer', 'subagent', { dag: 'm60.md', noeud: 'n1', source: 'registre' }, [700, 300, 5000, 400], 300],
  ['wk-x', 'vf-coder', 'subagent', { dag: 'm99.md', noeud: 'n1', source: 'registre' }, [111, 22, 333, 44], 55],
  ['wk-sans', 'gsd-verifier', 'subagent', 'ABSENT', [123, 45, 678, 90], 100],
  ['wk-nul', 'vf-test-runner', 'subagent', null, [222, 33, 444, 55], 66],
  ['wk-mx', 'agent-inconnu', 'subagent', { dag: 'mx.md', noeud: 'n1', source: 'registre' }, [5000, 600, 70000, 800], 700],
];
export const faire = ([id, role, kind, rattachement, [entree, sortie, cacheLu, cacheCree], travailS]) => {
  const o = { id, role, kind, jetons: { entree, sortie, cacheLu, cacheCree, contexteMax: 9, contexteDernier: 9 }, durees: { travailS, attenteHumainS: 0, attenteAgentsS: 0, reposS: 0, silenceS: 0 } };
  if (rattachement !== 'ABSENT') o.rattachement = rattachement; // « sans clé » : jamais `undefined` (la voie de la fabrique pose `rattachement: null` par défaut)
  const v = voie(o); if (rattachement === 'ABSENT') delete v.rattachement;
  return v;
};
export const voies = () => LIGNES.map(faire);
export const frise = (o = {}) => JSON.parse(JSON.stringify(fabrique({ voies: o.voies || voies(), tronque: !!o.tronque, voiesOmises: o.voiesOmises ?? 0, sourceEtat: o.etat || 'ok', schema: o.schema })));
// une voie sans mesure de jetons d'entrée (champ absent), dans la phase 78
export const friseInconnu = () => { const f = frise(); delete f.voies.find((v) => v.id === 'wk-78').jetons.entree; return f; };
export const signal = (o = {}) => ({ phases: PHASES.map((p) => (o.nom78 && p.n === 78 ? { ...p, nom: o.nom78 } : p)), jalons: JALONS, missions: MISSIONS });
export const etatCorps = (o = {}) => ({ schema: 'vibeflow/cockpit-state@1', at: '2026-11-13T14:00:00.000Z', seq: 1,
  collecte: { etat: 'ok', derniereA: null, dureeMs: 1, mode: 'poll', clients: 1 }, signal: signal(o) });
