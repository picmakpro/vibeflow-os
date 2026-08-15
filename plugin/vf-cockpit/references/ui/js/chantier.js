// chantier.js — niveau ② : carte de la phase courante et ses plans (§4.3 DESIGN-SPEC).
import { $, el, clearNode } from './dom.js';

let phaseDetailCache = { num: null, data: null };

export function getPhaseDetailCache() { return phaseDetailCache; }
export function setPhaseDetailCache(entry) { phaseDetailCache = entry; }

export async function renderChantier(snap, openPhaseDrawer) {
  const body = $('#chantier-body');
  clearNode(body);
  const state = snap.state;
  const num = state?.current_phase;
  if (num === undefined || num === null) {
    body.appendChild(el('p', { class: 'vf-empty-inline', text: 'Aucune phase courante.' }));
    return;
  }
  const card = buildPhaseCardSkeleton(num, state.current_phase_name, openPhaseDrawer);
  body.appendChild(card);

  if (phaseDetailCache.num !== num) {
    phaseDetailCache = { num, data: null };
    try {
      const res = await fetch(`/api/phase?num=${num}`, { cache: 'no-store' });
      const data = await res.json();
      phaseDetailCache = { num, data };
    } catch {
      phaseDetailCache = { num, data: null };
    }
  }
  if ($('#chantier-body').contains(card)) {
    fillPhaseCard(card, num, phaseDetailCache.data, openPhaseDrawer);
  }
}

function buildPhaseCardSkeleton(num, name, openPhaseDrawer) {
  const card = el('div', { class: 'vf-current-phase', attrs: { role: 'button', tabindex: '0' } });
  const title = document.createElement('h3');
  title.className = 'vf-current-phase-title';
  title.appendChild(el('span', { class: 'vf-glyph', attrs: { 'aria-hidden': 'true' }, text: '◉' }));
  title.appendChild(document.createTextNode(` Phase ${num} — ${name || '…'}`));
  card.appendChild(title);
  card.appendChild(el('p', { class: 'vf-current-phase-progress vf-skeleton', text: ' ' }));
  card.appendChild(el('ul', { class: 'vf-plan-chips vf-skeleton' }));
  card.appendChild(el('p', { class: 'vf-current-phase-goal vf-skeleton', text: ' ' }));
  const open = () => openPhaseDrawer(num, card);
  card.addEventListener('click', open);
  card.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); open(); }
  });
  return card;
}

function fillPhaseCard(card, num, data, openPhaseDrawer) {
  const progress = card.querySelector('.vf-current-phase-progress');
  const plansUl = card.querySelector('.vf-plan-chips');
  const goalP = card.querySelector('.vf-current-phase-goal');
  progress.classList.remove('vf-skeleton');
  plansUl.classList.remove('vf-skeleton');
  goalP.classList.remove('vf-skeleton');
  clearNode(plansUl);
  const existingEmpty = card.querySelector('.vf-plan-empty-inline');
  if (existingEmpty) existingEmpty.remove();

  if (!data || !data.dir || !data.plans || data.plans.length === 0) {
    progress.textContent = '';
    plansUl.hidden = true;
    const empty = el('p', { class: 'vf-empty-inline vf-plan-empty-inline', text: "Aucun plan posé pour cette phase pour l'instant." });
    card.insertBefore(empty, goalP);
  } else {
    plansUl.hidden = false;
    const doneN = data.plans.filter((p) => p.done).length;
    progress.textContent = `${doneN}/${data.plans.length} plans terminés — clic → fiche complète`;
    data.plans.forEach((p) => {
      const li = document.createElement('li');
      const btn = el('button', { class: `vf-plan-chip${p.done ? ' is-done' : ''}`, attrs: { type: 'button' } });
      btn.appendChild(el('span', { class: 'vf-glyph', attrs: { 'aria-hidden': 'true' }, text: p.done ? '●' : '○' }));
      btn.appendChild(document.createTextNode(` ${p.id}`));
      btn.addEventListener('click', (e) => { e.stopPropagation(); openPhaseDrawer(num, btn); });
      li.appendChild(btn);
      plansUl.appendChild(li);
    });
  }
  goalP.textContent = data?.goal || '';
}
