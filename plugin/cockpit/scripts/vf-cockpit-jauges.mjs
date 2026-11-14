// vf-cockpit-jauges — module PUR (aucune dépendance, aucun accès au disque, à l'environnement, à l'horloge ni au hasard) : le TSV des deux gates du
// conductor (contrat `#vf-budget@1`, plan 77-01) devient l'objet `vibeflow/cockpit-jauges@1` servi par GET /api/vf/methode (77-03, P77-D-03, P77-D-05).
// Il traduit des jetons, il ne recalcule jamais une mesure, un budget ni un verdict ; aucune valeur n'est jamais remplacée par 0.
// Export : SCHEMA, ENTETE, TYPES, VERDICTS, CAUSES, lireTsv(texte, gate), etatSource(lancement, gate), assembler({ methode, densite, at }).
export const SCHEMA = 'vibeflow/cockpit-jauges@1';
export const ENTETE = '#vf-budget@1';
const G_METHODE = 'check-method-budget', G_DENSITE = 'check-instruction-budget';
const T = (type, groupe, unite, gate) => Object.freeze({ type, groupe, unite, gate });
export const TYPES = Object.freeze([T('state', 'planning', 'Ko', G_METHODE), T('state-prose', 'planning', 'lignes', G_METHODE),
  T('backlog-ouverts', 'planning', 'sujets', G_METHODE),
  T('backlog-entree', 'planning', 'lignes', G_METHODE), T('backlog-clos', 'planning', 'sujets', G_METHODE), T('roadmap', 'planning', 'Ko', G_METHODE),
  T('memory-index', 'memoire', 'lignes', G_METHODE), T('worktrees', 'memoire', 'worktrees', G_METHODE), T('agent', 'instructions', 'lignes', G_DENSITE),
  T('skill', 'instructions', 'lignes', G_DENSITE), T('socle', 'instructions', 'jetons', G_DENSITE)]);
export const VERDICTS = Object.freeze(['ok', 'surveiller', 'depasse', 'na', 'indispo', 'format']);
export const CAUSES = Object.freeze(['absent', 'ancien', 'delai', 'format', 'echec']);
const TRAD = { OK: 'ok', AVERTISSEMENT: 'surveiller', DEPASSE: 'depasse', 'NON-APPLICABLE': 'na', 'NON-VERIFIABLE': 'indispo' };
const RELATIONS = { EGALE: 'egale', 'AU-DESSUS': 'au-dessus', 'EN-DESSOUS': 'en-dessous' };
const UNITES = Object.fromEntries([...TYPES.map((t) => [t.type, [t.unite, t.gate]]), ['socle-baseline', ['jetons', G_DENSITE]]]);
const MAX_LIGNES = 2000, MAX_CHAMP = 512, MAX_MESURES = 200, ENTIER = /^\d{1,15}$/;
const cheminRejete = (c) => c.startsWith('/') || c.startsWith('~') || /^[A-Za-z]:/.test(c) || c.split(/[\\/]/).includes('..');

// une ligne : { type, chemin (jamais un chemin du poste : null), valeur, budget, verdict, relation } ; « format » dès qu'un champ sort du contrat
function lireLigne(texte, gate) {
  const f = texte.split('\t').map((x) => x.slice(0, MAX_CHAMP));
  const type = f[0], u = UNITES[type];
  if (!u || u[1] !== gate) return null; // un type que ce gate n'émet pas : jamais attribué à une jauge
  const mauvais = { type, chemin: null, valeur: null, budget: null, verdict: 'format', relation: null };
  if (f.length !== 6) return mauvais;
  const [, chemin, valeur, budget, unite, jeton] = f, base = type === 'socle-baseline';
  const verdict = base ? 'ok' : TRAD[jeton];
  const sansValeur = !base && (jeton === 'NON-VERIFIABLE' || jeton === 'NON-APPLICABLE');
  if (unite !== u[0] || !verdict || (base && !RELATIONS[jeton])) return mauvais;
  if (sansValeur ? valeur !== '-' : !ENTIER.test(valeur)) return mauvais;
  if (base ? budget !== '-' : !ENTIER.test(budget)) return mauvais;
  if (cheminRejete(chemin)) return mauvais;
  const num = (x, nul) => (nul ? null : Number(x));
  const c = chemin === '-' ? null : chemin;
  return { type, chemin: c, valeur: num(valeur, sansValeur), budget: num(budget, base), verdict, relation: base ? RELATIONS[jeton] : null };
}

export function lireTsv(texte, gate) {
  const l = String(texte ?? '').split('\n');
  if (l[0] !== `${ENTETE}\t${gate}`) return { ok: false, cause: 'format' };
  const corps = l.slice(1).filter((x) => x !== ''), lignes = [];
  for (const x of corps.slice(0, MAX_LIGNES)) { const r = lireLigne(x, gate); if (r) lignes.push(r); }
  return { ok: true, lignes, tronque: corps.length > MAX_LIGNES };
}

const indispo = (cause) => ({ etat: 'indisponible', cause, lignes: [], tronque: false });
// lancement = { sortie, code, tronque, absent, echeance, delai } rendu par le lanceur, ou null/absent si le script n'a pas été résolu
export function etatSource(lancement, gate) {
  const s = lancement;
  if (!s || s.absent) return indispo('absent');
  if (s.delai || s.echeance) return indispo('delai');
  if (s.code === 64) return indispo('ancien');
  if (s.code === null && !s.sortie) return indispo('echec');
  const t = lireTsv(s.sortie, gate);
  if (!t.ok) return indispo(t.cause);
  if (s.tronque) return indispo('echec');
  const na = gate === G_DENSITE && s.code === 2 && t.lignes.some((x) => x.verdict === 'na');
  return { etat: na ? 'non-applicable' : 'ok', cause: null, lignes: t.lignes, tronque: t.tronque };
}

const RANG = { depasse: 0, surveiller: 1, indispo: 2, format: 3, ok: 4, na: 5 };
const rapport = (m) => (m.valeur === null || m.budget === null ? -1 : m.budget === 0 ? (m.valeur > 0 ? Infinity : 0) : m.valeur / m.budget);
const parChemin = (a, b) => (a === b ? 0 : a === null ? 1 : b === null ? -1 : a < b ? -1 : 1);
const comparer = (a, b) => (RANG[a.verdict] - RANG[b.verdict]) || (rapport(b) - rapport(a) || 0) || parChemin(a.chemin, b.chemin);
const sourceServie = (s) => ({ etat: s.etat, cause: s.cause ?? null });

export function assembler({ methode, densite, at }) {
  const src = { [G_METHODE]: methode, [G_DENSITE]: densite };
  const jauges = TYPES.map(({ type, groupe, unite, gate }) => {
    const s = src[gate], base = { type, groupe, unite, cause: null, mesures: [], tronque: false, baseline: null };
    if (s.etat === 'indisponible') return { ...base, verdict: 'indispo', cause: s.cause };
    const brutes = s.lignes.filter((x) => x.type === type);
    if (s.etat === 'non-applicable' || !brutes.length) return { ...base, verdict: 'na' };
    const tri = brutes.map(({ chemin, valeur, budget, verdict }) => ({ chemin, valeur, budget, verdict })).sort(comparer);
    const b = type === 'socle' ? s.lignes.find((x) => x.type === 'socle-baseline' && x.verdict === 'ok') : null;
    return { ...base, verdict: tri[0].verdict, mesures: tri.slice(0, MAX_MESURES), tronque: tri.length > MAX_MESURES || !!s.tronque,
      baseline: b ? { valeur: b.valeur, relation: b.relation } : null };
  });
  return { schema: SCHEMA, at, sources: { methode: sourceServie(methode), densite: sourceServie(densite) }, jauges };
}
