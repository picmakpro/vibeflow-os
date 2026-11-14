// vf-cockpit-questions-champs — analyse des champs d'une question en attente (C76-Q1, 76-09 ; TRAC-13 ; P76-D-36, P76-D-37).
// Module PUR : aucune lecture, aucun import. Chaque analyse rend `null` quand le champ ne respecte pas la grammaire (jamais une valeur devinée).
// Exports : DEFAUTS, dateIso, lireOptions, lireReco, lireBloque, lireEtat.
// Aucune RegExp n'est construite depuis une valeur lue dans le lab.

// liste fermée de C76-Q2, dans l'ordre où les défauts d'une entrée sont rendus
export const DEFAUTS = Object.freeze(['etat-absent', 'etat-invalide', 'options-invalides', 'recommandation-hors-options', 'bloque-invalide', 'champ-repete',
  'champ-manquant', 'phase-incoherente', 'identifiant-double', 'citation-incoherente', 'appliquee-hors-recommandation', 'decision-introuvable']);

// date ISO calendaire valide (2026-02-30 et 2026-13-45 sont refusées)
export function dateIso(s) {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(s));
  if (!m) return false;
  const d = new Date(Date.UTC(+m[1], +m[2] - 1, +m[3]));
  return d.getUTCFullYear() === +m[1] && d.getUTCMonth() === +m[2] - 1 && d.getUTCDate() === +m[3];
}

// `(a) … ; (b) … .` : au moins deux options, lettres consécutives depuis `a`
export function lireOptions(v) {
  const parts = String(v).replace(/[ \t]*\.[ \t]*$/, '').split(/[ \t]*;[ \t]*(?=\([a-z]\)[ \t])/);
  const out = [];
  for (let i = 0; i < parts.length; i++) {
    const m = /^\(([a-z])\)[ \t]+(\S.*)$/.exec(parts[i]);
    if (!m || m[1] !== String.fromCharCode(97 + i)) return null;
    out.push({ cle: m[1], texte: m[2].trim() });
  }
  return out.length >= 2 ? out : null;
}

// `(<lettre>) — <motif>.` (lettre prise parmi les options) ou `aucune — <motif>.` ; { lettre } ou null
export function lireReco(v, options) {
  const m = /^\(([a-z])\)[ \t]+—[ \t]+\S/.exec(v);
  if (m) return !options || options.some((o) => o.cle === m[1]) ? { lettre: m[1] } : null;
  return /^aucune[ \t]+—[ \t]+\S/.test(v) ? { lettre: null } : null;
}

// plan `<NN>-<NN>` ou `<NN.N>-<NN>`, `Phase <N>`, ou le seul mot `rien` ; [] pour `rien`, null si un élément est illisible
export function lireBloque(v) {
  if (v === 'rien') return [];
  const out = [];
  for (const p of v.split(', ')) {
    const plan = /^(\d+(?:\.\d+)?-\d+)$/.exec(p), ph = /^Phase (\d+(?:\.\d+)*)$/.exec(p);
    if (plan) out.push({ type: 'plan', id: plan[1] }); else if (ph) out.push({ type: 'phase', n: ph[1] }); else return null;
  }
  return out;
}

const TRANCHEE = /^tranchée — arbitrage Samuel, ([^,]+), (\d{4}-\d{2}-\d{2}) — option \(([a-z])\) — « (.+) »$/;
const APPLIQUEE = /^appliquée — décision déléguée par Samuel \(([^,]+), (\d{4}-\d{2}-\d{2})\), option \(([a-z])\) — (P\d+(?:\.\d+)*-D-\d{2,})$/;
// `en attente`, forme tranchée canonique, forme appliquée canonique, sinon invalide ; date et option vérifiées ici (option parmi les options lues)
export function lireEtat(v, options) {
  if (v === 'en attente') return { kind: 'attente' };
  const t = TRANCHEE.exec(v), a = APPLIQUEE.exec(v), m = t || a;
  if (!m || !dateIso(m[2]) || (options && !options.some((o) => o.cle === m[3]))) return { kind: 'invalide' };
  const [, canal, date, option, fin] = m;
  if (t) return { kind: 'tranchee', tranchee: { canal, date, option, citation: fin } };
  return { kind: 'appliquee', appliquee: { canal, date, option, decision: fin } };
}
