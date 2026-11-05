// vf-cockpit-lancer-cibles — cibles lançables des cartes du cockpit, action principale, pré-vols et projection fermée pour Q.
// Module PUR à lecteurs injectés : ni système de fichiers, ni environnement, ni horloge, ni hasard (P72-D-05, D-06, D-07, D-12, D-13, D-16).
// Interface : BLOQUANTS, AVERTISSEMENTS, AVERTISSEMENTS_RESERVES, RECENCE_MS, actionPrincipale(avancement, fichiersPhase),
//   calculerCibles({ gabarit, planning, fichiers, lancements, terminal, claude, python3, maintenant, travailNonCommite }),
//   listePourQ(cibles, gabarit), verdict(cibles, id, verbe).
// Aucun texte du lab ne traverse le canal vers Q : listePourQ ne rend que six champs fermés, et une phase ou un compartiment hors motif porte null.
// Le gabarit (motifs et verbes) est INJECTÉ par le paramètre `gabarit` : ce module ne charge pas le gabarit du plan 72-01.
import { trouverPhase } from './vf-cockpit-avancement.mjs';
import { ID_RE } from './vf-cockpit-lecture.mjs';

export const BLOQUANTS = Object.freeze(['phase-finie', 'terminal-absent', 'terminal-arrete', 'premier-plan-occupe', 'claude-introuvable', 'phase-hors-motif', 'compartiment-hors-motif', 'python3-absent', 'mission-hors-phase']);
export const AVERTISSEMENTS = Object.freeze(['dependance-non-close', 'mission-vivante', 'phase-plus-avancee-ailleurs', 'lancement-recent']);
export const AVERTISSEMENTS_RESERVES = Object.freeze(['travail-non-commite']);
export const RECENCE_MS = 900000;

const sur = (fn, repli) => { try { return fn(); } catch { return repli; } };
const motifOk = (m, v, max) => typeof v === 'string' && v.length > 0 && v.length <= max && !!m && new RegExp(m.source ?? m).test(v);
const finie = (p) => !!(p && (p.archive || p.done || p.avancement?.etat === 'fait'));
const nombre = (n) => parseFloat(n) || 0;
const cmp = (a, b) => (a < b ? -1 : a > b ? 1 : 0);
const ordonne = (codes, catalogue) => catalogue.filter((c) => codes.has(c));

// Action principale d'une phase selon son état (P72-D-05) ; null = aucune.
export function actionPrincipale(av, fichiers) {
  const etat = av?.etat;
  if (etat === 'a-recetter') return 'verifier';
  if (etat === 'en-cours') return 'executer';
  if (etat !== 'a-faire') return null;
  if ((av.plans?.total || 0) > 0) return 'executer';
  return (Array.isArray(fichiers) ? fichiers : []).some((f) => typeof f === 'string' && f.endsWith('-CONTEXT.md')) ? 'planifier' : 'cadrer';
}

// Liste des phases du planning (Map ou tableau), ou null si la forme est inattendue.
function phasesDe(pl) {
  const p = pl?.phases;
  const liste = p instanceof Map ? [...p.values()] : Array.isArray(p) ? p : null;
  if (!liste) return null;
  const objets = liste.filter((x) => x && typeof x === 'object' && typeof x.n === 'string');
  return { map: p instanceof Map ? p : new Map(objets.map((x) => [x.key, x])), liste: objets };
}

// Chaque lecteur est appelé UNE fois, sous try/catch : un lecteur qui lève vaut « absent », jamais une exception ni une porte ouverte.
// `travailNonCommite` est accepté et JAMAIS appelé (P72-D-07) : le code `travail-non-commite` n'existe que dans AVERTISSEMENTS_RESERVES ; son activation relève de la Phase 78.
export function calculerCibles(l = {}) {
  const g = l.gabarit || {}, V = Array.isArray(g.VERBES) ? g.VERBES : [];
  const t = sur(() => l.terminal(), 'indisponible'), terminal = t === 'actif' || t === 'arrete' ? t : 'indisponible';
  const claude = sur(() => l.claude() === true, false), python3 = sur(() => l.python3() === true, false);
  const pl = sur(() => l.planning(), null), ph = phasesDe(pl);
  const contexte = { terminal, claude, python3, planning: !!ph };
  if (!ph) return { cibles: [], contexte };
  const hors = new Set(); // bloquants du contexte, posés sur chaque cible ; premier-plan-occupe n'est calculé nulle part : Q le recalcule à la confirmation
  if (terminal === 'arrete') hors.add('terminal-arrete'); else if (terminal !== 'actif') hors.add('terminal-absent');
  if (!claude) hors.add('claude-introuvable');
  if (!python3) hors.add('python3-absent');
  const maintenant = sur(() => Number(l.maintenant()), NaN), reg = sur(() => l.lancements(), []);
  const registre = (Array.isArray(reg) ? reg : []).filter((e) => e && typeof e === 'object');
  const recent = (id) => Number.isFinite(maintenant) && registre.some((e) => e.cible === id && Number.isFinite(e.at) && maintenant - e.at >= 0 && maintenant - e.at < RECENCE_MS);
  // avertissements (jamais bloquants) : une dépendance introuvable n'avertit pas, l'heuristique de prose du ROADMAP pouvant se tromper
  const avertir = (id, p, vivante) => {
    const a = new Set();
    if (p && (p.depends || []).some((d) => { const dp = sur(() => trouverPhase(ph.map, d, p.ws), null); return !!dp && !finie(dp); })) a.add('dependance-non-close');
    if (vivante || p?.avancement?.mission?.etat === 'running') a.add('mission-vivante'); // la vie vient du verrou lu par readPlanning, jamais relu ici
    if (p?.avancement?.ailleurs) a.add('phase-plus-avancee-ailleurs');
    if (recent(id)) a.add('lancement-recent');
    return ordonne(a, AVERTISSEMENTS);
  };
  const lancee = (id) => registre.some((e) => e.cible === id);
  const compte = new Map(); for (const p of ph.liste) compte.set(p.n, (compte.get(p.n) || 0) + 1);
  const idPhase = (p) => (compte.get(p.n) > 1 && p.ws ? `ph-${p.n}@${p.ws}` : `ph-${p.n}`); // formule de buildProjectGraph : décompte sur TOUTES les phases
  const identite = (p) => { // phase et compartiment rendus seulement s'ils passent les motifs ; sinon null et le bloquant, jamais le texte brut
    const bloc = new Set(), ws = p.ws || null;
    const phase = motifOk(g.MOTIF_PHASE, p.n, 16) ? p.n : (bloc.add('phase-hors-motif'), null);
    const comp = ws === null ? null : motifOk(g.MOTIF_COMPARTIMENT, ws, 40) ? ws : (bloc.add('compartiment-hors-motif'), null);
    return { phase, ws: comp, bloc };
  };
  const cibles = [];
  for (const p of [...ph.liste].sort((a, b) => nombre(a.n) - nombre(b.n) || cmp(a.ws || '', b.ws || ''))) {
    const { phase, ws, bloc } = identite(p), fin = finie(p), id = idPhase(p);
    if (fin) bloc.add('phase-finie');
    for (const b of hors) bloc.add(b);
    const fich = fin ? [] : sur(() => l.fichiers(p), []);
    const principal = fin ? null : actionPrincipale(p.avancement, fich);
    cibles.push({ id, kind: 'phase', phase, ws, principal, verbes: principal ? [principal, ...V.filter((v) => v !== principal)] : [...V],
      bloquants: ordonne(bloc, BLOQUANTS), avertissements: avertir(id, p, false), lancee: lancee(id) });
  }
  const dags = Array.isArray(pl.dags) ? pl.dags.filter((d) => d && typeof d.name === 'string') : [];
  for (const d of [...dags].sort((a, b) => cmp(a.name, b.name))) {
    const p = d.phaseKey ? ph.map.get(d.phaseKey) : null, bloc = new Set(hors), id = `dag-${d.name}`;
    let phase = null, ws = null;
    if (!p) bloc.add('mission-hors-phase');
    else { const i = identite(p); phase = i.phase; ws = i.ws; for (const b of i.bloc) bloc.add(b); if (finie(p)) bloc.add('phase-finie'); }
    cibles.push({ id, kind: 'mission', phase, ws, principal: 'reprendre', verbes: ['reprendre'], bloquants: ordonne(bloc, BLOQUANTS), avertissements: avertir(id, p, d.etat === 'running'), lancee: lancee(id) });
  }
  return { cibles, contexte };
}

// Projection fermée vers Q (P72-D-13) : six champs, jamais un texte du lab ; toute valeur hors motif exclut la cible.
export function listePourQ(cibles, g = {}) {
  const V = Array.isArray(g.VERBES) ? g.VERBES : [], sortie = [];
  for (const c of Array.isArray(cibles) ? cibles : []) {
    if (!c || typeof c !== 'object' || typeof c.id !== 'string' || !V.includes(c.principal)) continue;
    if (Array.isArray(c.bloquants) && (c.bloquants.includes('phase-hors-motif') || c.bloquants.includes('compartiment-hors-motif'))) continue;
    if (!motifOk(g.MOTIF_PHASE, c.phase, 16) || (c.ws !== null && !motifOk(g.MOTIF_COMPARTIMENT, c.ws, 40))) continue;
    const coherent = c.kind === 'phase' ? c.id === `ph-${c.phase}` || (c.ws !== null && c.id === `ph-${c.phase}@${c.ws}`) : c.kind === 'mission' ? c.id.startsWith('dag-') && ID_RE.test(c.id.slice(4)) : false;
    if (!coherent) continue;
    sortie.push({ id: c.id, verbe: c.principal, verbes: (Array.isArray(c.verbes) ? c.verbes : []).filter((v) => V.includes(v)), phase: c.phase, ws: c.ws, kind: c.kind });
  }
  return sortie;
}

// Verdict d'une paire (cible, verbe) : null si la cible est inconnue ou si le verbe n'est pas dans ses verbes ; lancable = aucun bloquant (un avertissement ne bloque jamais).
export function verdict(cibles, id, verbe) {
  const c = (Array.isArray(cibles) ? cibles : []).find((x) => x && x.id === id);
  if (!c || !Array.isArray(c.verbes) || !c.verbes.includes(verbe)) return null;
  const bloquants = [...(c.bloquants || [])];
  return { lancable: bloquants.length === 0, bloquants, avertissements: [...(c.avertissements || [])] };
}
