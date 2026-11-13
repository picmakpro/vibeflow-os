// vf-cockpit-trace-ledger — lecture du registre des exigences (REQUIREMENTS.md) pour la traçabilité du cockpit (TRAC-01, TRAC-11 ; P76-D-12,
// P76-D-13, P76-D-38).
// Exports : traceDuLedger, statutFait, citationsLigne.
// Forme « Étape N » (gabarit planning-core, P76-D-12) : la constante ETAPE reprend la grammaire de reTraceabilite, le mot `Phase` remplacé par
// `Étape` ou `Etape` ; écrite une fois.
// Module pur : reçoit le texte du ledger, ne lit aucun fichier. Cases et lignes de traçabilité par les motifs de vf-cockpit-formats.mjs (reExigences,
// reTraceabilite) :
// aucun motif neuf pour la forme « Phase N », aucune RegExp construite depuis une valeur lue dans le lab.
import { ESP, normNum, texte, reExigences, idExigence, reTraceabilite } from './vf-cockpit-formats.mjs';

// vocabulaire du statut de la table, non fermé : seul le premier mot décide (minuscules, sans accent) ; « Complete—2026-11-05 (PR #203) » -> complete
const ETAPE = new RegExp(reTraceabilite().source.replace('Phase ', `(?:Étape|Etape)${ESP}+`), 'gim');
if (!ETAPE.source.includes('Etape')) throw new Error('vf-cockpit-trace-ledger : la grammaire de reTraceabilite a changé, ETAPE ne peut plus en dériver');
const FAIT = new Set(['complete', 'completed', 'done', 'livre', 'fait']);
export function statutFait(statut) {
  const mot = String(statut || '').normalize('NFD').replace(/\p{Mn}/gu, '').toLowerCase().split(/[^a-z]+/).find(Boolean);
  return mot !== undefined && FAIT.has(mot);
}

// { txt, ws, fichier, dossiers } -> { statuts: Map('<ws>|<id>' -> { phase, statut, fait, rattachement }), lignes: Map('<ws>|<id>' -> ligne complète
// de la case),
//   lignesSansExigence: [{ id, phase, ws }], etapes: { lues, sansDossier } }
// `ws` : '' (lab plat), nom du compartiment ou '*' (archive). `dossiers` : Map ou Set des clés `<ws>|<n>` des dossiers de phase existants.
// Une ligne de traçabilité dont l'identifiant n'a pas de case n'est jamais posée sur une exigence : elle est comptée par phase.
// Une ligne « Étape N » qui désigne un dossier de phase existant vaut « Phase N » (rattachement `etape`) ; les autres sont comptées « sans dossier ».
export function traceDuLedger({ txt, ws, dossiers }) {
  const t = texte(txt), w = ws || '';
  const ids = new Set(), lignes = new Map(), statuts = new Map(), sans = [], etapes = { lues: 0, sansDossier: 0 };
  for (const m of t.matchAll(reExigences())) { const id = idExigence(m); ids.add(id); if (!lignes.has(`${w}|${id}`)) lignes.set(`${w}|${id}`, m[0]); }
  const poser = (m, phase, rattachement) => {
    const id = m[1], cle = `${w}|${id}`;
    if (!ids.has(id)) { sans.push({ id, phase, ws: w }); return; }
    if (statuts.has(cle)) return; // la première ligne de la table décide
    const fin = t.indexOf('\n', m.index), ligne = t.slice(m.index, fin < 0 ? t.length : fin);
    const statut = (ligne.split('|')[3] || '').replace(/\*\*|__/g, '').trim();
    statuts.set(cle, { phase, statut, fait: statutFait(statut), rattachement });
  };
  for (const m of t.matchAll(reTraceabilite())) poser(m, normNum(m[2]), 'table');
  for (const m of t.matchAll(ETAPE)) {
    const n = normNum(m[2]); etapes.lues++;
    if (dossiers && (dossiers.has(`${w}|${n}`) || dossiers.has(`*|${n}`))) poser(m, n, 'etape');
    else { etapes.sansDossier++; poser(m, null, null); }
  }
  return { statuts, lignes, lignesSansExigence: sans, etapes };
}

// P76-D-38 : citations lues sur la LIGNE COMPLÈTE d'une exigence au ledger (jamais sur un libellé coupé, jamais devinées ni déduites d'un autre fichier).
// Préfixée (reliable, ADR-075) : `P<n>-D-<nn>` ; ADR : `ADR-<nnn>` ; nue : `D-<nn>` non précédée d'un préfixe, listée mais jamais reliée. Listes
// dédoublonnées, ordre de lecture.
// Motifs fixes : aucune RegExp construite depuis une valeur du lab.
const CITE_DECISION = /(?<![A-Za-z0-9.-])P[0-9]+(?:\.[0-9]+)*-D-[0-9]{2,}(?![0-9A-Za-z])/g;
const CITE_ADR = /(?<![A-Za-z0-9-])ADR-[0-9]{3}(?![0-9A-Za-z])/g;
const CITE_NUE = /(?<![A-Za-z0-9.-])D-[0-9]{2,}(?![0-9A-Za-z])/g;
const uniques = (ligne, re) => [...new Set([...String(ligne || '').matchAll(re)].map((m) => m[0]))];
export function citationsLigne(ligne) { return { decisions: uniques(ligne, CITE_DECISION), adrs: uniques(ligne, CITE_ADR), nues: uniques(ligne, CITE_NUE) }; }
