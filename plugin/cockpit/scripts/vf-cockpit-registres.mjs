// vf-cockpit-registres — décisions et ADR lues dans du texte (76-02 ; TRAC-05 ; P76-D-16, D-17, D-18).
// Module PUR : aucune lecture, aucun git, seul import vf-cockpit-formats.mjs.
// La Phase 73 l'importe pour ses définitions de registres (P76-D-18) : signature et exports sont un contrat.
// Exports : sectionsAdr(txt), definitionsRegistre(txt, { phase, ws, fichier, couper }), citations(message), relier({ adrs, definitions, commits }).
//   cle d'une décision = `<ID>:<phase>`, phase = identifiant de nœud (`ph-<N>` ou `ph-<N>@<ws>`) reçu de l'appelant, jamais calculé ici.
// Une arête est lue dans un texte, jamais inférée ; une citation nue (`D-04`) n'est jamais retenue ni reliée à un commit (ADR-075).
import { ESP, COLON } from './vf-cockpit-formats.mjs';

// une seule classe de préfixe, partagée par les définitions, les citations et le --grep git (point admis : `P71.5-D-04`)
export const PREFIXE = '[A-Z][A-Z0-9.]*';
const ID_DEC = `(?:${PREFIXE}-)*D-\\d+[a-z]?(?:bis)?`;
const ID_PREFIXE = `(?:${PREFIXE}-)+D-\\d+[a-z]?(?:bis)?`;
const FIN_TITRE = `(?:${COLON}|${ESP}*[—–-]|${ESP}*$)`;
const SECTION_ADR = new RegExp(`^##${ESP}+(ADR-\\d{3})${FIN_TITRE}${ESP}*(.*)$`);
const DEF = new RegExp(`^[-*+] \\*\\*(${ID_DEC})`);
const CIT_ADR = /(?<![A-Za-z0-9-])ADR-\d{3}(?![A-Za-z0-9])/g;
const CIT_DEC = new RegExp(`(?<![A-Za-z0-9.-])${ID_PREFIXE}(?![A-Za-z0-9])`, 'g');
const FENCE = /^\s*(```|~~~)/;

const nettoyer = (s) => String(s).replace(/\*\*/g, '').replace(/`/g, '').replace(/^[\s—–:-]*(?:\([^)]*\))?[\s—–:-]*/, '').replace(/\s+/g, ' ').trim();
const uniques = (a) => [...new Set(a)];

// lignes hors blocs de code : [{ l, n }] (n = numéro de ligne 1-based)
function lignesHorsCode(txt) {
  const out = []; let dedans = false;
  const lignes = String(txt ?? '').replace(/\r\n?/g, '\n').split('\n');
  lignes.forEach((l, i) => {
    if (FENCE.test(l)) { dedans = !dedans; return; }
    if (!dedans) out.push({ l, n: i + 1 });
  });
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

// Lignes de définition `- **<ID>` d'un registre (hors blocs de code et hors titres `###`), quel que soit le préfixe.
// Première définition gardée, suivantes comptées en `amendee`. `phase` (identifiant de nœud) et `couper` (coupe au mot)
// viennent de l'appelant ; `ws` et `fichier` lui restent, ils ne servent pas la clé.
export function definitionsRegistre(txt, { phase, couper } = {}) {
  const coupe = typeof couper === 'function' ? couper : (s, n) => s.slice(0, n);
  const vues = new Map(), out = [];
  for (const { l, n } of lignesHorsCode(txt)) {
    const m = DEF.exec(l); if (!m) continue;
    const id = m[1], deja = vues.get(id);
    if (deja) { deja.amendee = true; continue; }
    const reste = l.slice(m[0].length);
    const d = { id, cle: `${id}:${phase}`, nue: id.startsWith('D-'), titre: coupe(nettoyer(reste), 80), adr: citations(l).adr, amendee: false, ligne: n };
    vues.set(id, d); out.push(d);
  }
  return out;
}

// { adrs, definitions, commits } -> { parAdr: Map(id -> { decisions: [cle], commits: [h7] }),
//   parDecision: Map(cle -> { adr: [ids], commits: [h7] }), adrSansSection: [ids] }
export function relier({ adrs = [], definitions = [], commits = [] } = {}) {
  const parAdr = new Map(), parDecision = new Map(), adrSansSection = [];
  for (const a of adrs) parAdr.set(a.id, { decisions: [], commits: [] });
  const fiche = (id) => { if (!parAdr.has(id)) { parAdr.set(id, { decisions: [], commits: [] }); adrSansSection.push(id); } return parAdr.get(id); };
  const ajoute = (liste, v) => { if (!liste.includes(v)) liste.push(v); };
  const parId = new Map(); // identifiant préfixé -> clés des définitions qui le portent
  for (const d of definitions) {
    parDecision.set(d.cle, { adr: [...d.adr], commits: [] });
    for (const id of d.adr) ajoute(fiche(id).decisions, d.cle); // arête lue dans la ligne de définition
    if (!d.nue) parId.set(d.id, [...(parId.get(d.id) || []), d.cle]);
  }
  for (const c of commits) {
    for (const id of c.adr || []) ajoute(fiche(id).commits, c.h7);
    // une nue n'a jamais de commit (ADR-075) : parId ne contient que des identifiants préfixés
    for (const id of c.decisions || []) for (const cle of parId.get(id) || []) ajoute(parDecision.get(cle).commits, c.h7);
  }
  return { parAdr, parDecision, adrSansSection };
}
