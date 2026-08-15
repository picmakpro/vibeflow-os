// drawer-content.js — bâtisseurs de contenu du drawer : fiche de phase, fiche de nœud,
// journal, résolution des deep-links #/phase/N et #/node/<id> (§4.6 DESIGN-SPEC).
import { el, STATUS_GLYPH, STATUS_TEXT, STATUS_SET, formatTime } from './dom.js';
import { openDrawer } from './drawer-core.js';
import { renderLightMarkdown } from './markdown-light.js';
import { getPhaseDetailCache, setPhaseDetailCache } from './chantier.js';

export async function openPhaseDrawer(num, trigger, lastSnapshot) {
  const hash = `#/phase/${num}`;
  const cache = getPhaseDetailCache();
  let data = cache.num === num ? cache.data : null;
  if (!data) {
    try {
      const res = await fetch(`/api/phase?num=${num}`, { cache: 'no-store' });
      data = await res.json();
      setPhaseDetailCache({ num, data });
    } catch {
      data = null;
    }
  }
  const phaseListEntry = (lastSnapshot?.phases || []).find((p) => p.num === num);
  const title = `Phase ${num} — ${data?.name || phaseListEntry?.name || ''}`;
  const source = `source : ROADMAP.md + .planning/phases/${data?.dir || '?'}`;
  const notFoundMsg = "Pas de fiche trouvée pour cette phase dans ROADMAP.md — seules les phases documentées y ont une fiche détaillée.";
  openDrawer({
    title, source, trigger, hash,
    buildBody: (bodyEl) => {
      if (!data || data.error) {
        bodyEl.appendChild(el('p', { class: 'vf-empty-inline', text: notFoundMsg }));
        return;
      }
      if (data.dir && data.plans?.length) {
        const ul = document.createElement('ul');
        ul.className = 'vf-plan-list';
        data.plans.forEach((p) => {
          const li = document.createElement('li');
          li.appendChild(el('span', { class: 'vf-glyph', attrs: { 'aria-hidden': 'true' }, text: p.done ? '●' : '○' }));
          li.appendChild(document.createTextNode(` ${p.id} — ${p.done ? 'terminé' : 'à venir'}`));
          ul.appendChild(li);
        });
        bodyEl.appendChild(ul);
      } else {
        bodyEl.appendChild(el('p', { class: 'vf-empty-inline', text: "Aucun plan posé pour cette phase pour l'instant." }));
      }
      bodyEl.appendChild(data.body ? renderLightMarkdown(data.body) : el('p', { class: 'vf-empty-inline', text: notFoundMsg }));
    },
  });
}

export function openNodeDrawer(dag, node, trigger) {
  const hash = `#/node/${encodeURIComponent(node.id)}`;
  openDrawer({
    title: node.id,
    source: `source : .planning/${dag.file}`,
    trigger, hash,
    buildBody: (bodyEl) => {
      const dl = document.createElement('dl');
      appendField(dl, 'Mandat', node.step || '—');
      appendField(dl, 'Étage', node.stage || '—');
      const status = STATUS_SET.has(node.status) ? node.status : 'blocked';
      appendField(dl, 'Statut', `${STATUS_GLYPH[status]} ${STATUS_TEXT[status]}`);
      appendListField(dl, 'Dépend de', node.deps || []);
      appendListField(dl, 'Périmètre', node.scope || []);
      bodyEl.appendChild(dl);
    },
  });
}

export function openLogDrawer(trigger, lastLogEvents) {
  openDrawer({
    title: 'Journal',
    source: 'source : journal en mémoire du serveur (non persisté)',
    trigger, hash: null,
    buildBody: (bodyEl) => {
      if (!lastLogEvents.length) {
        bodyEl.appendChild(el('p', { class: 'vf-empty-inline', text: 'Aucun événement pour le moment.' }));
        return;
      }
      const ul = document.createElement('ul');
      ul.className = 'vf-log-list';
      lastLogEvents.slice().reverse().forEach((ev) => {
        const li = document.createElement('li');
        const isError = ev.cat === 'parse' || (ev.cat === 'watch' && ev.error);
        li.appendChild(document.createTextNode(`${formatTime(new Date(ev.ts))} `));
        li.appendChild(el('span', { class: isError ? 'vf-log-cat-error' : 'vf-log-cat', text: `[${ev.cat}] ` }));
        li.appendChild(document.createTextNode(ev.msg || ''));
        ul.appendChild(li);
      });
      bodyEl.appendChild(ul);
    },
  });
}

export function resolveDeepLink(lastSnapshot) {
  const h = location.hash;
  let m = /^#\/phase\/(\d+)$/.exec(h);
  if (m) { openPhaseDrawer(Number(m[1]), null, lastSnapshot); return; }
  m = /^#\/node\/(.+)$/.exec(h);
  if (m) {
    const nodeId = decodeURIComponent(m[1]);
    const dag = (lastSnapshot?.dags || []).find((d) => (d.nodes || []).some((n) => n.id === nodeId));
    const node = dag && dag.nodes.find((n) => n.id === nodeId);
    if (dag && node) openNodeDrawer(dag, node, null);
  }
}

function appendField(parent, label, value) {
  const wrap = document.createElement('div');
  wrap.className = 'vf-drawer-field';
  wrap.appendChild(el('dt', { text: label }));
  wrap.appendChild(el('dd', { text: value }));
  parent.appendChild(wrap);
}

function appendListField(parent, label, items) {
  const wrap = document.createElement('div');
  wrap.className = 'vf-drawer-field';
  wrap.appendChild(el('dt', { text: label }));
  if (!items.length) {
    wrap.appendChild(el('dd', { text: '—' }));
  } else {
    const dd = document.createElement('dd');
    const ul = document.createElement('ul');
    items.forEach((i) => ul.appendChild(el('li', { text: i })));
    dd.appendChild(ul);
    wrap.appendChild(dd);
  }
  parent.appendChild(wrap);
}
