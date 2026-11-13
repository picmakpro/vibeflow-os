// vf-cockpit-trace-chaine — maillons, premier trou et mot de ligne d'une exigence, depuis l'instantané projet (TRAC-01, TRAC-02 ; P76-D-14).
// Exports : MAILLONS, ligneExigence, lignesDePhase, vueExigence.
// Module pur : lit la forme posée par projeterTrace (nodes[].trace, meta.vf.trace). Des codes, jamais de texte français (la page écrit le copy).
export const MAILLONS = ['plan', 'summary', 'verification', 'recette'];

// (exigence de meta.vf.trace.exigences, trace de sa phase | null) -> { id, ws, cle, libelle, coche, maillons, mot, contradictions, mentions, niveauPhase }
export function ligneExigence(exigence, tracePhase) {
  const tp = tracePhase || { plans: [], correctifs: [], verification: null, recette: null };
  const id = exigence.id;
  const plansCitant = tp.plans.filter((p) => p.exigences && p.exigences.includes(id));
  const sommes = [...tp.plans.map((p) => p.summary), ...tp.correctifs].filter(Boolean).filter((s) => s.exigences && s.exigences.includes(id));
  const maillons = {
    plan: plansCitant.length ? { etat: 'lu', niveau: 'exigence', sources: plansCitant.map((p) => p.fichier) } : { etat: 'manque', niveau: null, sources: [] },
    summary: sommes.length ? { etat: 'lu', niveau: 'exigence', sources: sommes.map((s) => s.fichier) } : { etat: 'manque', niveau: null, sources: [] },
    verification: tp.verification ? { etat: 'lu', niveau: tp.verification.cites.includes(id) ? 'exigence' : 'phase', sources: [tp.verification.fichier] } : { etat: 'manque', niveau: null, sources: [] },
    recette: { etat: 'manque', niveau: null, sources: [] },
  };
  const premier = MAILLONS.find((m) => maillons[m].etat !== 'lu');
  return { id, ws: exigence.ws, cle: `${exigence.ws || ''}|${id}`, libelle: exigence.libelle, coche: exigence.coche, maillons,
    mot: premier ? { maillon: premier, etat: maillons[premier].etat } : null, contradictions: [], mentions: [], niveauPhase: MAILLONS.filter((m) => maillons[m].etat === 'lu' && maillons[m].niveau === 'phase') };
}

const duPhase = (ex, noeud) => ex.phase === noeud.num && (ex.ws === '*' || (ex.ws || null) === (noeud.ws || null));
// toutes les exigences rattachées à une phase, dans l'ordre du ledger
export function lignesDePhase(projet, noeudPhase) {
  const ex = projet.meta?.vf?.trace?.exigences || [];
  return ex.filter((e) => duPhase(e, noeudPhase)).map((e) => ligneExigence(e, noeudPhase.trace));
}

// une exigence par sa clé `<ws>|<id>` : sa ligne et le nœud de sa phase
export function vueExigence(projet, cle) {
  const e = (projet.meta?.vf?.trace?.exigences || []).find((x) => `${x.ws || ''}|${x.id}` === cle);
  if (!e) return null;
  const noeud = projet.nodes.find((n) => n.kind === 'phase' && duPhase(e, n)) || null;
  return { ...ligneExigence(e, noeud && noeud.trace), exigence: { id: e.id, ws: e.ws, phase: e.phase, phasesParPlan: e.phasesParPlan, statut: e.statut, fait: e.fait, rattachement: e.rattachement, fichier: e.fichier, cites: e.cites }, noeud: noeud ? noeud.id : null };
}
