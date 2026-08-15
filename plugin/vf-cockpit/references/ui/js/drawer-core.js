// drawer-core.js — mécanique du drawer : ouverture/fermeture, focus trap, deep-link
// (§Modèle d'interaction / §4.6 DESIGN-SPEC). Le contenu vit dans drawer-content.js.
import { $, clearNode } from './dom.js';

const state = { open: false, trigger: null, pushedHistory: false };

export function openDrawer({ title, source, buildBody, trigger, hash }) {
  const drawer = $('#drawer');
  const overlay = $('#drawer-overlay');
  $('#drawer-title').textContent = title;
  $('#drawer-source').textContent = source;
  const bodyEl = $('#drawer-body');
  clearNode(bodyEl);
  buildBody(bodyEl);

  drawer.hidden = false;
  if (window.innerWidth > 640) overlay.hidden = false;
  void drawer.offsetWidth; // force reflow avant la transition d'ouverture
  drawer.classList.add('is-open');
  document.body.classList.add('vf-drawer-open');

  if (hash && location.hash !== hash) {
    history.pushState(null, '', hash);
    state.pushedHistory = true;
  } else {
    state.pushedHistory = false;
  }
  state.open = true;
  state.trigger = trigger || null;

  $('#drawer-close').focus();
  document.addEventListener('keydown', onDrawerKeydown);
}

export function closeDrawer(viaHistory = true) {
  const drawer = $('#drawer');
  if (!state.open) return;
  drawer.classList.remove('is-open');
  $('#drawer-overlay').hidden = true;
  document.body.classList.remove('vf-drawer-open');
  document.removeEventListener('keydown', onDrawerKeydown);
  setTimeout(() => { drawer.hidden = true; }, 220);

  const trigger = state.trigger;
  const pushed = state.pushedHistory;
  state.open = false;
  state.trigger = null;

  if (viaHistory && pushed) {
    history.back();
  } else if (location.hash) {
    history.replaceState(null, '', location.pathname + location.search);
  }
  if (trigger && typeof trigger.focus === 'function') trigger.focus();
}

export function isDrawerOpen() { return state.open; }

function onDrawerKeydown(e) {
  if (e.key === 'Escape') { closeDrawer(true); return; }
  if (e.key === 'Tab') trapFocus(e);
}

function trapFocus(e) {
  const drawer = $('#drawer');
  const focusables = drawer.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
  if (!focusables.length) return;
  const first = focusables[0];
  const last = focusables[focusables.length - 1];
  if (e.shiftKey && document.activeElement === first) {
    e.preventDefault(); last.focus();
  } else if (!e.shiftKey && document.activeElement === last) {
    e.preventDefault(); first.focus();
  }
}
