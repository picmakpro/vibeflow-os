// app.js — point d'entrée du cockpit. Orchestre le fetch/refresh, le SSE, et délègue
// le rendu de chaque niveau aux modules de ./js/ (voir DESIGN-SPEC.md pour le contrat).
import { $ } from './js/dom.js';
import { renderHeader, setErrorBanner, setOffline, markFirstRenderDone, markGoodFetch } from './js/header.js';
import { renderTrajectoire } from './js/trajectoire.js';
import { renderChantier } from './js/chantier.js';
import { renderEquipe } from './js/equipe.js';
import { renderHistorique } from './js/historique.js';
import { closeDrawer, isDrawerOpen } from './js/drawer-core.js';
import { openPhaseDrawer, openNodeDrawer, openLogDrawer, resolveDeepLink } from './js/drawer-content.js';
import { highlightChanges } from './js/diff-highlight.js';

let lastSnapshot = null;
let lastLogEvents = [];

document.addEventListener('DOMContentLoaded', () => {
  wireStaticHandlers();
  initMermaid();
  refresh().then(() => resolveDeepLink(lastSnapshot));
  connectEvents();
});

window.addEventListener('popstate', () => {
  if (!location.hash) {
    if (isDrawerOpen()) closeDrawer(false);
  } else {
    resolveDeepLink(lastSnapshot);
  }
});

function initMermaid() {
  if (!window.mermaid) return;
  window.mermaid.initialize({
    startOnLoad: false,
    theme: 'base',
    securityLevel: 'strict',
    themeVariables: {
      background:          '#12151b',
      primaryColor:         '#171b23',
      primaryTextColor:     '#e8ecf1',
      primaryBorderColor:   '#5a6479',
      lineColor:            '#5a6479',
      secondaryColor:       '#171b23',
      tertiaryColor:        '#12151b',
      fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
      fontSize:             '13px',
      edgeLabelBackground:  '#12151b',
      clusterBkg:           '#171b23',
      clusterBorder:        '#262c37',
    },
  });
}

async function refresh() {
  try {
    const [stateRes, logRes] = await Promise.all([
      fetch('/api/state', { cache: 'no-store' }),
      fetch('/api/log', { cache: 'no-store' }).catch(() => null),
    ]);
    if (!stateRes.ok) throw new Error(`http ${stateRes.status}`);
    const snap = await stateRes.json();
    let logCount = lastLogEvents.length;
    if (logRes && logRes.ok) {
      const logData = await logRes.json();
      logCount = logData.count;
      lastLogEvents = logData.events || [];
    }
    setErrorBanner(false);
    render(snap, lastSnapshot);
    $('#log-link').textContent = `voir le journal (${logCount} événements)`;
    lastSnapshot = snap;
    markGoodFetch();
    markFirstRenderDone();
  } catch {
    setErrorBanner(true);
  }
}

function connectEvents() {
  let es;
  try {
    es = new EventSource('/api/events');
  } catch {
    setOffline(true, lastSnapshot);
    return;
  }
  es.onopen = () => setOffline(false, lastSnapshot);
  es.onmessage = () => { setOffline(false, lastSnapshot); refresh(); };
  es.onerror = () => setOffline(true, lastSnapshot);
}

function render(snap, prev) {
  if (!snap.planningRoot) {
    $('#empty-state').hidden = false;
    $('#app-content').hidden = true;
    return;
  }
  $('#empty-state').hidden = true;
  $('#app-content').hidden = false;
  renderHeader(snap);
  renderTrajectoire(snap, (num, trigger) => openPhaseDrawer(num, trigger, lastSnapshot));
  renderChantier(snap, (num, trigger) => openPhaseDrawer(num, trigger, lastSnapshot));
  renderEquipe(snap, openNodeDrawer);
  renderHistorique(snap);
  highlightChanges(snap, prev);
}

function wireStaticHandlers() {
  $('#drawer-close').addEventListener('click', () => closeDrawer(true));
  $('#drawer-overlay').addEventListener('click', () => closeDrawer(true));
  $('#log-link').addEventListener('click', (e) => openLogDrawer(e.currentTarget, lastLogEvents));
  $('#historique-details summary').addEventListener('click', (e) => {
    if ($('#historique-details').classList.contains('is-disabled')) e.preventDefault();
  });
}
