// vf-cockpit-trace-vues — assemblage des sept vues de la route GET /api/vf/tracabilite (76-05 ; TRAC-05 à TRAC-07, TRAC-10 ; P76-D-06, D-07, D-12, D-38).
// Module PUR : aucune lecture, aucun git ; reçoit l'instantané `projet` et le modèle des lectures propres déjà calculés (texte déjà passé par `servi`).
// Exports : SCHEMA, VUES, MOTIFS_CLE, definitionsDe(projet), vue({ vue, cle, projet, modele }) -> { statut: 200 | 400, corps }.
// Des codes d'état et des clés ouvrables, jamais de copy français : la page ne construit aucune clé (UI-SPEC § 5). Aucune arête n'est déduite :
// une décision nue n'est jamais reliée (ADR-075).
import { vueJalon, vuePhase } from './vf-cockpit-trace-bilans.mjs';
import { vueExigence } from './vf-cockpit-trace-chaine.mjs';

export const SCHEMA = 'vibeflow/cockpit-trace@1';
export const VUES = ['jalon', 'phase', 'exigence', 'decision', 'adr', 'memoire', 'entree'];
const WS = '[A-Za-z0-9][A-Za-z0-9._-]{0,63}';
const PH = `ph-\\d{1,4}(?:\\.\\d{1,3})?(?:@${WS})?`;
// motifs ancrés, longueur de `cle` bornée à 200 par l'appelant ; une `cle` ne sert qu'à chercher dans un ensemble déjà lu, jamais de chemin
export const MOTIFS_CLE = {
  jalon: null,
  phase: new RegExp(`^${PH}$`),
  exigence: new RegExp(`^[A-Z][A-Z0-9]{0,15}-\\d{1,4}[a-z]?(?:@${WS})?$`),
  adr: /^ADR-\d{3}$/,
  decision: new RegExp(`^(?:[A-Z][A-Z0-9.]{0,15}-){0,3}D-\\d{1,4}[a-z]?(?:bis)?(?::${PH})?$`),
  memoire: new RegExp(`^${WS}$`),
  entree: new RegExp(`^${WS}\\/[A-Za-z0-9][A-Za-z0-9._-]{0,127}\\.md$`),
};

const ok = (corps) => ({ statut: 200, corps });
const refus = (erreur) => ({ statut: 400, corps: { erreur } });
const registres = (projet) => (projet.meta && projet.meta.vf && projet.meta.vf.registres) || [];
// toutes les définitions des registres, portant la phase (identifiant de nœud) et le compartiment du registre qui les définit
export const definitionsDe = (projet) => registres(projet).flatMap((r) => r.decisions.map((d) => ({ ...d, phase: r.phase, ws: r.ws })));

// la clé ouvrable d'une exigence : son identifiant, qualifié `@<compartiment>` quand l'identifiant existe dans plusieurs ledgers ; null si non représentable
const cleExigence = (projet) => {
  const ex = (projet.meta.vf.trace && projet.meta.vf.trace.exigences) || [], n = new Map();
  for (const e of ex) n.set(e.id, (n.get(e.id) || 0) + 1);
  return (l) => (n.get(l.id) > 1 ? (l.ws && l.ws !== '*' ? `${l.id}@${l.ws}` : null) : l.id);
};

function corpsDe(v, cle, projet, modele, c) {
  const vf = (projet.meta && projet.meta.vf) || {};
  const compartiment = !projet.nodes.some((n) => n.kind === 'phase');
  const absences = { compartiment, etapes: (vf.trace && vf.trace.etapes) || null, ...(modele ? modele.absences : {}) };
  return { schema: SCHEMA, vue: v, ...(cle ? { cle } : {}), bornes: { tronque: modele ? Boolean(modele.bornes.tronque) : false }, absences, ...c };
}
const commitsDe = (modele, h7s) => h7s.map((h) => modele.commits.find((c) => c.h7 === h)).filter(Boolean);

function vueDePlanning(v, cle, projet) {
  const vf = (projet.meta && projet.meta.vf) || {};
  const panne = !vf.trace || vf.trace.erreur;
  const c = (etat, x) => ok(corpsDe(v, cle, projet, null, { etat: panne ? 'indisponible' : etat, ...(panne ? {} : x) }));
  if (v === 'jalon') {
    const j = vueJalon(projet);
    // la clé ouvrable d'une phase est son identifiant de nœud
    return c(j.jalon ? 'ok' : 'vide', { jalon: { ...j, phases: j.phases.map((p) => ({ ...p, cle: p.id })) } });
  }
  const cx = cleExigence(projet);
  if (v === 'phase') {
    const n = projet.nodes.find((x) => x.kind === 'phase' && x.id === cle);
    if (!n) return c('absent', {});
    const p = vuePhase(projet, `${n.ws || ''}|${n.num}`);
    const exigences = p.exigences.map((l) => ({ ...l, cle: cx(l) }));
    return c('ok', { phase: { ...p.phase, cle: n.id, bilan: p.bilan, exigences, plans: p.plans, preuves: p.preuves } });
  }
  const [id, ws] = cle.split('@');
  const cand = ((vf.trace && vf.trace.exigences) || []).filter((e) => e.id === id && (ws === undefined || e.ws === ws));
  if (cand.length === 0) return c('absent', {});
  if (cand.length > 1) return refus('cle-ambigue');
  const e = cand[0], { exigence: x, noeud, ...ligne } = vueExigence(projet, `${e.ws || ''}|${e.id}`);
  const dd = definitionsDe(projet).filter((d) => !d.nue && (e.ws === '*' || (d.ws || null) === (e.ws || null)));
  const decisions = x.cites.decisions.flatMap((i) => {
    const m = dd.filter((d) => d.id === i);
    return m.length ? m.map((d) => ({ id: i, cle: d.cle, phase: d.phase })) : [{ id: i, cle: null }]; // définition absente : citée, sans panneau
  });
  const adrs = x.cites.adrs.map((i) => ({ id: i, cle: i }));
  return c('ok', { exigence: { ...ligne, cle: cx(ligne), phase: x.phase, phasesParPlan: x.phasesParPlan, statut: x.statut, fait: x.fait,
    rattachement: x.rattachement, fichier: x.fichier, noeud, decisions, adrs, decisionsNues: x.cites.nues.length,
    aucuneDecisionCitee: decisions.length + adrs.length === 0 } });
}

function vueDeLectures(v, cle, projet, modele) {
  const c = (etat, x) => ok(corpsDe(v, cle, projet, modele, { etat, ...x }));
  const adrIds = new Set(modele.adrs.map((a) => a.id)), defs = definitionsDe(projet), { parAdr, parDecision, adrSansSection } = modele.liens;
  const defDe = (k) => defs.find((d) => d.cle === k);
  const cible = (i) => ({ id: i, cle: adrIds.has(i) ? i : null });
  if (v === 'adr' && !cle) {
    const ligne = (i, titre, k) => ({ id: i, cle: k, titre, nbDecisions: parAdr.get(i).decisions.length, nbCommits: parAdr.get(i).commits.length });
    const adrs = [...modele.adrs.map((a) => ligne(a.id, a.titre, a.id)), ...adrSansSection.map((i) => ligne(i, null, null))];
    const regs = registres(projet).map((r) => ({ fichier: r.fichier, ws: r.ws, phase: r.phase, decisions: r.decisions }));
    return c(adrs.length || regs.length ? 'ok' : 'vide', { adrs, registres: regs });
  }
  if (v === 'adr') {
    const a = modele.adrs.find((x) => x.id === cle);
    if (!a) return c('absent', {});
    const decisions = parAdr.get(cle).decisions.map(defDe).filter(Boolean).map((d) => ({ id: d.id, cle: d.cle, phase: d.phase, nue: d.nue, titre: d.titre }));
    return c('ok', { adr: { id: cle, cle, titre: a.titre, decisions }, commits: commitsDe(modele, parAdr.get(cle).commits) });
  }
  if (v === 'decision') {
    const cand = cle.includes(':') ? defs.filter((d) => d.cle === cle) : defs.filter((d) => d.id === cle);
    if (cand.length === 0) return c('absent', {});
    if (cand.length > 1) return refus('cle-ambigue');
    const d = cand[0], rel = parDecision.get(d.cle) || { commits: [] };
    return c('ok', { decision: { id: d.id, cle: d.cle, nue: d.nue, titre: d.titre, amendee: d.amendee, phase: d.phase, ws: d.ws || null,
      adrs: d.adr.map(cible) }, commits: commitsDe(modele, rel.commits) });
  }
  const m = modele.memoire;
  if (v === 'memoire' && !cle) return c(m.compteurs.entrees || m.agents.length ? 'ok' : 'vide', { memoire: { agents: m.agents, compteurs: m.compteurs } });
  if (v === 'memoire') {
    const a = m.agents.find((x) => x.agent === cle);
    return a ? c('ok', { agent: { ...a, entrees: m.entrees.filter((e) => e.agent === cle) } }) : c('absent', {});
  }
  const e = m.entrees.find((x) => x.cle === cle);
  return e ? c('ok', { entree: e }) : c('absent', {});
}

export function vue({ vue: v, cle, projet, modele }) {
  return ['jalon', 'phase', 'exigence'].includes(v) ? vueDePlanning(v, cle, projet) : vueDeLectures(v, cle, projet, modele);
}
