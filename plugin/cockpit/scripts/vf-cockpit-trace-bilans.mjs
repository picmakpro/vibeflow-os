// vf-cockpit-trace-bilans — bilans exclusifs, vue de phase et vue de jalon de la traçabilité (TRAC-03 ; P76-D-14, UI-SPEC § 10.1).
// Exports : bilanExigences, vuePhase, vueJalon.
import { lignesDePhase } from './vf-cockpit-trace-chaine.mjs';

const noeudPhase = (projet, cle) => projet.nodes.find((n) => n.kind === 'phase' && `${n.ws || ''}|${n.num}` === cle) || null;

// forme minimale du tracer : la phase, ses lignes d'exigence, ses plans et ses preuves (bilans et tri : tâche 3)
export function vuePhase(projet, cle) {
  const n = noeudPhase(projet, cle);
  if (!n) return null;
  return { phase: { id: n.id, cle, n: n.num, ws: n.ws || null, nom: n.label }, bilan: null, exigences: lignesDePhase(projet, n), plans: n.trace ? n.trace.plans : [], preuves: n.trace ? n.trace.preuves : [] };
}
