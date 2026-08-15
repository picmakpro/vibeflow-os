// historique.js — milestones clos, repliés par défaut (§4/§5 DESIGN-SPEC).
import { $, el, clearNode } from './dom.js';

// `aria-disabled` ne suffit pas sur un <details> natif : le clic souris est bloqué par
// `pointer-events: none` (styles.css), mais l'activation clavier (Entrée/Espace sur <summary>
// focalisé) déclenche quand même `toggle`. Cette garde referme immédiatement toute ouverture
// survenue pendant que l'historique est vide, sans jamais piéger le focus.
let toggleGuardWired = false;
function guardDisabledToggle(det) {
  if (toggleGuardWired) return;
  toggleGuardWired = true;
  det.addEventListener('toggle', () => {
    if (det.classList.contains('is-disabled') && det.open) {
      det.removeAttribute('open');
    }
  });
}

export function renderHistorique(snap) {
  const det = $('#historique-details');
  const body = $('#historique-body');
  guardDisabledToggle(det);
  clearNode(body);
  const milestones = snap.milestones || [];
  const closed = milestones.filter((m) => m.closed);
  if (!snap.availability.milestones || closed.length === 0) {
    det.classList.add('is-disabled');
    det.removeAttribute('open');
    const summary = det.querySelector('summary');
    summary.title = "Historique vide : ce lab n'a pas encore clos de jalon.";
    summary.setAttribute('aria-disabled', 'true');
    return;
  }
  det.classList.remove('is-disabled');
  const summary = det.querySelector('summary');
  summary.removeAttribute('title');
  summary.removeAttribute('aria-disabled');
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
