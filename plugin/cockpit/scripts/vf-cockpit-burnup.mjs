// vf-cockpit-burnup — burn-up du jalon mis en avant, lu sur les lignes de checklist du ROADMAP (Phase 77, plan 77-02 ; P77-D-13, P77-D-14, SYNT-08).
// Module pur : aucune dépendance, aucun accès au système de fichiers, à l'environnement, à l'horloge ni au hasard. Il ne calcule aucun pourcentage :
// la fonction `pct` du pied de jalon (CKPT-16, P69-D-06) lui est injectée, il n'en existe qu'une.
// Dates : celles de la ligne de checklist (clôture « — complete », « (completed », « (complete », « — close », « (close » ; inscription « inscrite »), première
// occurrence ancrée sur le mot-clé ; jamais la date d'un commit, jamais la table « Progress » ; une date de calendrier invalide donne null. Rien n'est estimé.
// Exports : CLOTURE, INSCRIPTION, dates(ligne), burnup({ jalon, phases, pct }).

export const CLOTURE = /(?:—|\()\s*(?:complete|completed|close)\s+(\d{4}-\d{2}-\d{2})/i;
export const INSCRIPTION = /inscrite\s+(\d{4}-\d{2}-\d{2})/i;

// jour de calendrier valide (années bissextiles comprises), sans objet horloge
function valide(s) {
  const [a, m, j] = s.split('-').map(Number);
  const max = [31, a % 4 === 0 && (a % 100 !== 0 || a % 400 === 0) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1];
  return m >= 1 && m <= 12 && j >= 1 && j <= max;
}
const lire = (re, ligne) => { const d = re.exec(String(ligne ?? ''))?.[1]; return d && valide(d) ? d : null; };

export const dates = (ligne) => ({ cloture: lire(CLOTURE, ligne), inscription: lire(INSCRIPTION, ligne) });

// phases : [{ n, nom, line, etat }] dans l'ordre du ROADMAP ; `clos` ne compte que l'état « fait » (jamais la case cochée)
export function burnup({ jalon, phases, pct } = {}) {
  if (!jalon || !Array.isArray(phases) || !phases.length) return null;
  const ps = phases.map((p) => {
    const d = dates(p.line), fait = p.etat === 'fait';
    return { n: p.n, nom: p.nom, fait, ins: d.inscription, clo: fait ? d.cloture : null };
  });
  const clos = ps.filter((p) => p.fait).length, total = ps.length;
  const connues = ps.flatMap((p) => [p.ins, p.clo]).filter(Boolean).sort();
  const ouverture = connues[0] ?? null;
  // entrée au périmètre : l'inscription, ramenée à la clôture si celle-ci est plus ancienne ; sans inscription : ouverture
  const entree = (p) => (p.ins ? (p.clo && p.clo < p.ins ? p.clo : p.ins) : ouverture);
  const jours = [...new Set(ps.flatMap((p) => [entree(p), p.clo]).filter(Boolean))].sort();
  const serie = ouverture === null ? [] : jours.map((d) => ({
    d,
    perimetre: ps.filter((p) => entree(p) <= d).length,
    clos: ps.filter((p) => p.clo && p.clo <= d).length,
    closes: ps.filter((p) => p.clo === d).map((p) => p.n),
  }));
  return {
    jalon, clos, total, pct: pct(clos, total), ouverture, serie,
    closesSansDate: ps.filter((p) => p.fait && !p.clo).map((p) => ({ n: p.n, nom: p.nom })),
    inscritesSansDate: ps.filter((p) => !p.ins).map((p) => ({ n: p.n, nom: p.nom })),
  };
}
