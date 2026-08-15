// historique.js — milestones clos, repliés par défaut (§4/§5 DESIGN-SPEC).
import { $, el, clearNode } from './dom.js';

export function renderHistorique(snap) {
  const det = $('#historique-details');
  const body = $('#historique-body');
  clearNode(body);
  const milestones = snap.milestones || [];
  const closed = milestones.filter((m) => m.closed);
  if (!snap.availability.milestones || closed.length === 0) {
    det.classList.add('is-disabled');
    det.removeAttribute('open');
    det.querySelector('summary').title = "Historique vide : ce lab n'a pas encore clos de jalon.";
    return;
  }
  det.classList.remove('is-disabled');
  det.querySelector('summary').removeAttribute('title');
  const ul = document.createElement('ul');
  ul.className = 'vf-historique-list';
  closed.forEach((m) => {
    const li = document.createElement('li');
    li.appendChild(el('span', { class: 'vf-glyph', attrs: { 'aria-hidden': 'true' }, text: '✅' }));
    li.appendChild(document.createTextNode(` ${m.title}${m.when ? ` — ${m.when}` : ''}`));
    ul.appendChild(li);
  });
  body.appendChild(ul);
}
