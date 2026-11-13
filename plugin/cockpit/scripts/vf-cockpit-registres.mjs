// vf-cockpit-registres — décisions et ADR lues dans du texte (76-02 ; TRAC-05 ; P76-D-16, D-17, D-18). Module PUR : aucune lecture, aucun git,
// seul import vf-cockpit-formats.mjs. La Phase 73 l'importe pour ses définitions de registres (P76-D-18) : signature et exports sont un contrat.
// Exports : sectionsAdr(txt), definitionsRegistre(txt, { phase, ws, fichier, couper }), citations(message), relier({ adrs, definitions, commits }).
//   cle d'une décision = `<ID>:<phase>`, phase = identifiant de nœud (`ph-<N>` ou `ph-<N>@<ws>`) reçu de l'appelant, jamais calculé ici.
// Une arête est lue dans un texte, jamais inférée ; une citation nue (`D-04`) n'est jamais retenue ni reliée à un commit (ADR-075).
import { ESP, COLON } from './vf-cockpit-formats.mjs';

// une seule classe de préfixe, partagée par les définitions, les citations et le --grep git (point admis : `P71.5-D-04`)
export const PREFIXE = '[A-Z][A-Z0-9.]*';
const ID_DEC = `(?:${PREFIXE}-)*D-\\d+[a-z]?(?:bis)?`;
const ID_PREFIXE = `(?:${PREFIXE}-)+D-\\d+[a-z]?(?:bis)?`;
const SECTION_ADR = new RegExp(`^##${ESP}+(ADR-\\d{3})(?:${COLON}|${ESP}*[—–-]|${ESP}*$)${ESP}*(.*)$`);
const DEF = new RegExp(`^[-*+] \\*\\*(${ID_DEC})`);
const CIT_ADR = /(?<![A-Za-z0-9-])ADR-\d{3}(?![A-Za-z0-9])/g;
const CIT_DEC = new RegExp(`(?<![A-Za-z0-9.-])${ID_PREFIXE}(?![A-Za-z0-9])`, 'g');
const FENCE = /^\s*(```|~~~)/;

const nettoyer = (s) => String(s).replace(/\*\*/g, '').replace(/`/g, '').replace(/^[\s—–:-]*(?:\([^)]*\))?[\s—–:-]*/, '').replace(/\s+/g, ' ').trim();
const uniques = (a) => [...new Set(a)];

// lignes hors blocs de code : [{ l, n }] (n = numéro de ligne 1-based)
function lignesHorsCode(txt) {
  const out = []; let dedans = false;
  String(txt ?? '').replace(/\r\n?/g, '\n').split('\n').forEach((l, i) => { if (FENCE.test(l)) { dedans = !dedans; return; } if (!dedans) out.push({ l, n: i + 1 }); });
  return out;
}

export function sectionsAdr(txt) {
  const out = [];
  for (const { l, n } of lignesHorsCode(txt)) { const m = SECTION_ADR.exec(l); if (m) out.push({ id: m[1], titre: nettoyer(m[2]), ligne: n }); }
  return out;
}

export function citations(message) {
  const s = String(message ?? '');
  return { adr: uniques(s.match(CIT_ADR) || []), decisions: uniques(s.match(CIT_DEC) || []) };
}

// 76-02 tâche 2 : écrite après son témoin rouge
export function definitionsRegistre(txt, { phase, ws, fichier, couper } = {}) { void phase; void ws; void fichier; void couper; void txt; void DEF; return []; }

// { adrs, definitions, commits } -> { parAdr: Map(id -> { decisions: [cle], commits: [h7] }), parDecision: Map(cle -> { adr: [ids], commits: [h7] }), adrSansSection: [ids] }
export function relier({ adrs = [], definitions = [], commits = [] } = {}) {
  const parAdr = new Map(), parDecision = new Map();
  for (const a of adrs) parAdr.set(a.id, { decisions: [], commits: [] });
  const adrSansSection = [];
  const fiche = (id) => { if (!parAdr.has(id)) { parAdr.set(id, { decisions: [], commits: [] }); adrSansSection.push(id); } return parAdr.get(id); };
  for (const c of commits) for (const id of c.adr || []) { const e = fiche(id); if (!e.commits.includes(c.h7)) e.commits.push(c.h7); }
  return { parAdr, parDecision, adrSansSection };
}
