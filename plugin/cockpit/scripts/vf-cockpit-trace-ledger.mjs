// vf-cockpit-trace-ledger — lecture du registre des exigences (REQUIREMENTS.md) pour la traçabilité du cockpit (TRAC-01, TRAC-11 ; P76-D-12, P76-D-13, P76-D-38).
// Exports : traceDuLedger, statutFait.
// Module pur : reçoit le texte du ledger, ne lit aucun fichier. Cases et lignes de traçabilité par les motifs de vf-cockpit-formats.mjs (reExigences, reTraceabilite) :
// aucun motif neuf pour la forme « Phase N », aucune RegExp construite depuis une valeur lue dans le lab.
import { normNum, texte, reExigences, idExigence, reTraceabilite } from './vf-cockpit-formats.mjs';

// vocabulaire du statut de la table, non fermé : seul le premier mot décide (minuscules, sans accent) ; « Complete—2026-11-05 (PR #203) » -> complete
const FAIT = new Set(['complete', 'completed', 'done', 'livre', 'fait']);
export function statutFait(statut) {
  const mot = String(statut || '').normalize('NFD').replace(/\p{Mn}/gu, '').toLowerCase().split(/[^a-z]+/).find(Boolean);
  return mot !== undefined && FAIT.has(mot);
}

// { txt, ws, fichier, dossiers } -> { statuts: Map('<ws>|<id>' -> { phase, statut, fait, rattachement }), lignes: Map('<ws>|<id>' -> ligne complète de la case),
//   lignesSansExigence: [{ id, phase, ws }] }
// `ws` : '' (lab plat), nom du compartiment ou '*' (archive). Une ligne de traçabilité dont l'identifiant n'a pas de case n'est jamais posée sur une exigence : elle est comptée par phase.
export function traceDuLedger({ txt, ws }) {
  const t = texte(txt), w = ws || '';
  const ids = new Set(), lignes = new Map(), statuts = new Map(), sans = [];
  for (const m of t.matchAll(reExigences())) { const id = idExigence(m); ids.add(id); if (!lignes.has(`${w}|${id}`)) lignes.set(`${w}|${id}`, m[0]); }
  for (const m of t.matchAll(reTraceabilite())) {
    const id = m[1], phase = normNum(m[2]), cle = `${w}|${id}`;
    if (!ids.has(id)) { sans.push({ id, phase, ws: w }); continue; }
    if (statuts.has(cle)) continue; // la première ligne de la table décide
    const fin = t.indexOf('\n', m.index), ligne = t.slice(m.index, fin < 0 ? t.length : fin);
    const statut = (ligne.split('|')[3] || '').replace(/\*\*|__/g, '').trim();
    statuts.set(cle, { phase, statut, fait: statutFait(statut), rattachement: 'table' });
  }
  return { statuts, lignes, lignesSansExigence: sans };
}
