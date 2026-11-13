// vf-cockpit-voies-rattachement — la jointure du rattachement aux voies de l'index (79-09, A8, A14, AUDC-I37). Pur, aucune lecture disque.
// Export : rattacherVoies(voies, travailleurs) -> Map identifiant de voie -> { dag, noeud, source } | null.
// L'index ne persiste PAS le rattachement : la collecte le joint aux voies à chaque tour, depuis le `rattachement` des travailleurs de l'équipe.
//   - une voie de sous-agent dont le travailleur est rattaché à un nœud reçoit son propre rattachement (`source` `registre` ou `mandat`) ;
//   - sinon (A14), si TOUS ses enfants rattachés (leur propre nœud, jamais un plan dérivé) pointent le même plan de mission :
//     `{ dag, noeud: null, source: 'enfants' }` ;
//   - sinon `null` (enfants sur plusieurs plans, aucun enfant rattaché) ; une voie de session reste `null`.
// `dag` est le fichier du plan réduit comme `signal.missions[].fichier` (`nettoie(…, 200)`) : même source, même réduction (A8).
import { nettoie } from './vf-cockpit-arbres.mjs';

export function rattacherVoies(voies, travailleurs) {
  const propres = new Map(), plansDesEnfants = new Map(), sortie = new Map();
  for (const w of Array.isArray(travailleurs) ? travailleurs : []) {
    const r = w?.rattachement;
    if (w?.kind === 'subagent' && typeof w.id === 'string' && r?.etat === 'rattache' && typeof r.dag === 'string' && r.dag) {
      propres.set(w.id, { dag: nettoie(r.dag, 200), noeud: typeof r.noeud === 'string' ? r.noeud : null, source: r.source });
    }
  }
  for (const v of voies) {
    if (v.kind !== 'subagent' || !propres.has(v.id) || typeof v.parent !== 'string') continue;
    const plans = plansDesEnfants.get(v.parent) || new Set();
    plans.add(propres.get(v.id).dag); plansDesEnfants.set(v.parent, plans);
  }
  for (const v of voies) {
    if (v.kind !== 'subagent') { sortie.set(v.id, null); continue; }
    const propre = propres.get(v.id);
    if (propre) { sortie.set(v.id, propre); continue; }
    const plans = plansDesEnfants.get(v.id) || new Set();
    sortie.set(v.id, plans.size === 1 ? { dag: [...plans][0], noeud: null, source: 'enfants' } : null); // garde:rattachement-enfants
  }
  return sortie;
}
