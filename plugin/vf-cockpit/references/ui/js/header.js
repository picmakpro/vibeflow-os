// header.js — barre d'état sticky : badges milestone/verrou, horodatage, bandeaux
// d'erreur/hors-ligne (§4.1/§5 DESIGN-SPEC).
import { $, el, clearNode, formatTime } from './dom.js';

let esConnected = true;
let lastGoodAt = null;
let firstRenderDone = false;

export function markFirstRenderDone() { firstRenderDone = true; }
export function markGoodFetch() { lastGoodAt = new Date(); }

export function renderHeader(snap) {
  const badge = $('#milestone-badge');
  const state = snap.state;
  if (!state) {
    badge.textContent = 'aucun état — STATE.md absent';
  } else {
    const total = state.progress?.total_phases ?? '?';
    const done = state.progress?.completed_phases ?? '?';
    badge.textContent = `milestone · ${state.milestone || '?'} — phase ${state.current_phase ?? '?'} (${state.status || '?'}) · ${done}/${total} phases`;
  }
  renderLockBadge(snap.lock);
  renderTimestamp(snap.generatedAt);
}

export function renderLockBadge(lock) {
  const b = $('#lock-badge');
  clearNode(b);
  b.classList.remove('vf-lock-alive', 'vf-lock-stale', 'vf-lock-empty');
  if (!lock || lock.present === false) {
    b.classList.add('vf-lock-empty');
    b.appendChild(document.createTextNode('🔓 aucune mission'));
    return;
  }
  if (lock.stale) {
    b.classList.add('vf-lock-stale');
    b.appendChild(el('span', { class: 'vf-glyph', attrs: { 'aria-hidden': 'true' }, text: '⚠' }));
    b.appendChild(document.createTextNode(
      ` verrou périmé (${lock.age_seconds ?? '?'}s) — probablement une mission interrompue. Lecture seule, rien n'est bloqué ici.`,
    ));
    return;
  }
  b.classList.add('vf-lock-alive');
  b.appendChild(el('span', { class: 'vf-pulse-dot' + (esConnected ? '' : ' is-static'), attrs: { 'aria-hidden': 'true' } }));
  b.appendChild(document.createTextNode(` 🔒 ${lock.owner || '?'} · ${lock.step || '?'} · ${lock.age_seconds ?? '?'}s`));
}

function renderTimestamp(generatedAt) {
  const t = $('#updated-at');
  const d = new Date(generatedAt);
  const text = `maj ${formatTime(d)}`;
  if (t.textContent !== text) {
    t.textContent = text;
    if (firstRenderDone) {
      t.classList.remove('flash');
      void t.offsetWidth;
      t.classList.add('flash');
      setTimeout(() => t.classList.remove('flash'), 400);
    }
  }
}

export function setErrorBanner(show) {
  $('#error-banner').hidden = !show;
  $('#app-content').classList.toggle('vf-stale-data', show);
}

export function setOffline(isOffline, lastSnapshot) {
  esConnected = !isOffline;
  const banner = $('#offline-banner');
  if (isOffline) {
    const ts = lastGoodAt ? formatTime(lastGoodAt) : '--:--:--';
    banner.textContent = `connexion perdue — dernière donnée à ${ts}`;
    banner.hidden = false;
  } else {
    banner.hidden = true;
  }
  if (lastSnapshot) renderLockBadge(lastSnapshot.lock);
}
