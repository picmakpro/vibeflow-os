// trajectoire.js — niveau ① : chaîne de phases du milestone courant (§4.2 DESIGN-SPEC).
import { $, el, clearNode } from './dom.js';

export function renderTrajectoire(snap, openPhaseDrawer) {
  const body = $('#trajectoire-body');
  clearNode(body);
  const phases = snap.phases || [];
  if (!snap.availability.roadmap || phases.length === 0) {
    body.appendChild(el('p', { class: 'vf-empty-inline', text: "Aucune phase trouvée dans ROADMAP.md — ce lab n'a pas encore de feuille de route GSD." }));
    return;
  }
  const currentNum = snap.state?.current_phase ?? null;
  const done = phases.filter((p) => p.done);
  const notDone = phases.filter((p) => !p.done);
  const chantier = notDone.filter((p) => currentNum === null || p.num >= currentNum).sort((a, b) => a.num - b.num);
  const heritees = notDone.filter((p) => currentNum !== null && p.num < currentNum).sort((a, b) => a.num - b.num);

  if (notDone.length === 0) {
    body.appendChild(el('p', { class: 'vf-empty-inline', text: 'Toutes les phases du milestone sont terminées.' }));
  } else {
    const chain = el('div', { class: 'vf-phase-chain' });
    chantier.forEach((p) => chain.appendChild(buildPhaseChip(p, p.num === currentNum, openPhaseDrawer)));
    body.appendChild(chain);
  }

  if (heritees.length) {
    const group = el('div', { class: 'vf-phase-heritees' });
    group.appendChild(el('span', { class: 'vf-heritees-label', text: 'héritées' }));
    const row = el('div', { class: 'vf-phase-chain vf-phase-chain-heritees' });
    heritees.forEach((p) => row.appendChild(buildPhaseChip(p, false, openPhaseDrawer)));
    group.appendChild(row);
    body.appendChild(group);
  }

  const det = el('details', { class: 'vf-terminees' });
  const summary = document.createElement('summary');
  summary.textContent = `◈ Terminées (${done.length})`;
  det.appendChild(summary);
  const list = el('div', { class: 'vf-phase-chain vf-phase-chain-done' });
  done.forEach((p) => list.appendChild(buildPhaseChip(p, false, openPhaseDrawer)));
  det.appendChild(list);
  body.appendChild(det);
}

function buildPhaseChip(phase, isCurrent, openPhaseDrawer) {
  const statusClass = phase.done ? 'is-done' : isCurrent ? 'is-current' : 'is-ready';
  const btn = el('button', {
    class: `vf-phase-chip ${statusClass}`,
    attrs: { type: 'button', 'data-phase-num': String(phase.num) },
  });
  const glyph = phase.done ? '●' : isCurrent ? '◉' : '○';
  const statusText = phase.done ? 'terminé' : isCurrent ? 'en cours' : 'prêt';
  btn.appendChild(el('span', { class: 'vf-glyph', attrs: { 'aria-hidden': 'true' }, text: glyph }));
  btn.appendChild(document.createTextNode(` Phase ${phase.num}`));
  btn.appendChild(el('span', { class: 'sr-only', text: ` — ${phase.name} — ${statusText}` }));
  btn.title = `${phase.name} — ${statusText}`;
  btn.addEventListener('click', () => openPhaseDrawer(phase.num, btn));
  return btn;
}
