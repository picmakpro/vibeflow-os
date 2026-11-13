// vf-cockpit-trace-chaine — maillons, premier trou et mot de ligne d'une exigence, depuis l'instantané projet (TRAC-01, TRAC-02 ; P76-D-14).
// Exports : MAILLONS, ligneExigence, lignesDePhase, vueExigence.
// Module pur : lit la forme posée par projeterTrace (nodes[].trace, meta.vf.trace). Des codes, jamais de texte français (la page écrit le copy).
export const MAILLONS = ['plan', 'summary', 'verification', 'recette'];

const MANQUE = { etat: 'manque', niveau: null, sources: [] };
const lu = (niveau, sources) => ({ etat: 'lu', niveau, sources });
const nonLisible = (sources) => ({ etat: 'non-lisible', niveau: null, sources });
const contradiction = (code) => ({ etat: 'contradiction', niveau: null, sources: [], code });
// VERIFICATION et recette : lu seulement si le statut est lisible ; le niveau dit si le fichier cite l'identifiant (exigence) ou seulement existe
// pour la phase (phase)
const maillonFichier = (f, id, lisible) => (!f ? MANQUE : lisible ? lu(f.cites.includes(id) ? 'exigence' : 'phase', [f.fichier]) : nonLisible([f.fichier]));

// (exigence de meta.vf.trace.exigences, trace de sa phase | null) -> { id, ws, cle, libelle, coche, maillons, mot, contradictions, mentions, niveauPhase }
// Un maillon a UN état : lu, manque, non-lisible, contradiction (UI-SPEC § 10.1). Une contradiction est une liste fermée de deux codes, lus sur deux
// fichiers qui se contredisent ;
// un fichier illisible n'est jamais une contradiction (P76-D-04 « contradiction lue »), une absence simple non plus.
export function ligneExigence(exigence, tracePhase) {
  const tp = tracePhase || { plans: [], correctifs: [], verification: null, recette: null };
  const id = exigence.id;
  const citant = tp.plans.filter((p) => p.exigences && p.exigences.includes(id));
  const sommesLues = [...tp.plans.map((p) => p.summary), ...tp.correctifs].filter((s) => s && s.exigences && s.exigences.includes(id));
  const sommesIllisibles = citant.map((p) => p.summary).filter((s) => s && s.exigences === null);
  const plansIllisibles = tp.plans.filter((p) => p.exigences === null);
  const maillons = {
    plan: citant.length ? lu('exigence', citant.map((p) => p.fichier))
      : plansIllisibles.length ? nonLisible(plansIllisibles.map((p) => p.fichier))
        : exigence.fait ? contradiction('complete-sans-plan') : MANQUE,
    summary: sommesLues.length ? lu('exigence', sommesLues.map((s) => s.fichier))
      : sommesIllisibles.length ? nonLisible(sommesIllisibles.map((s) => s.fichier))
        : exigence.coche ? contradiction('cochee-sans-summary') : MANQUE,
    verification: maillonFichier(tp.verification, id, !!tp.verification && tp.verification.status !== null),
    recette: maillonFichier(tp.recette, id, !!tp.recette && tp.recette.statut !== null),
  };
  const premier = MAILLONS.find((m) => maillons[m].etat !== 'lu');
  // le mot de ligne 2 dit le premier maillon non lu ; toute autre contradiction passe en `contradictions` (UI-SPEC § 10) ; les mentions neutres
  // suivent (priorité b)
  return { id, ws: exigence.ws, cle: `${exigence.ws || ''}|${id}`, libelle: exigence.libelle, coche: exigence.coche, maillons,
    mot: premier ? { maillon: premier, etat: maillons[premier].etat, ...(maillons[premier].code ? { code: maillons[premier].code } : {}) } : null,
    contradictions: MAILLONS.filter((m) => m !== premier && maillons[m].etat === 'contradiction').map((m) => maillons[m].code),
    mentions: [!exigence.coche && maillons.summary.etat === 'lu' ? 'non-cochee-summary-lu' : '',
      exigence.rattachement === 'plan' ? 'sans-ligne-tracabilite' : ''].filter(Boolean),
    niveauPhase: MAILLONS.filter((m) => maillons[m].etat === 'lu' && maillons[m].niveau === 'phase') };
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
  const { id, ws, phase, phasesParPlan, statut, fait, rattachement, fichier, cites } = e;
  return { ...ligneExigence(e, noeud && noeud.trace), exigence: { id, ws, phase, phasesParPlan, statut, fait, rattachement, fichier, cites },
    noeud: noeud ? noeud.id : null };
}
