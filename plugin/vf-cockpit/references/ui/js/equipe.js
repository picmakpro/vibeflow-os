// equipe.js — niveau ③ : DAG de la mission active, Mermaid + liste accessible jumelle
// (§4.4/§4.6 DESIGN-SPEC). Seul module de toute l'app qui utilise innerHTML : la sortie
// SVG de mermaid.render() (securityLevel:'strict', libellés pré-échappés) — jamais du
// contenu de fichier brut.
import { $, el, clearNode, STATUS_GLYPH, STATUS_TEXT, STATUS_SET } from './dom.js';

let renderCounter = 0;

export function renderEquipe(snap, openNodeDrawer) {
  const dag = (snap.dags && snap.dags[0]) || null;
  const emptyBlock = $('#equipe-empty');
  const svgContainer = $('#equipe-svg');
  const listWrap = $('#equipe-list-wrap');

  if (!dag) {
    emptyBlock.hidden = false;
    svgContainer.hidden = true;
    listWrap.hidden = true;
    clearNode($('#equipe-list'));
    return;
  }
  emptyBlock.hidden = true;
  svgContainer.hidden = false;
  listWrap.hidden = false;
  renderMermaid(dag);
  renderNodeList(dag, openNodeDrawer);
}

function sanitizeMermaidLabel(s) {
  return String(s || '').replace(/[`"|{}[\]]/g, ' ').replace(/\n/g, ' ').trim().slice(0, 55);
}

function buildMermaidDef(dag) {
  const nodes = dag.nodes || [];
  const revMap = {};
  nodes.forEach((n, i) => { revMap[n.id] = `n${i}`; });
  const lines = ['flowchart LR'];
  nodes.forEach((n) => {
    const sid = revMap[n.id];
    const label = sanitizeMermaidLabel(n.step || n.id);
    const status = STATUS_SET.has(n.status) ? n.status : 'blocked';
    lines.push(`${sid}["${label}"]:::${status}`);
  });
  nodes.forEach((n) => {
    const sid = revMap[n.id];
    (n.deps || []).forEach((dep) => {
      const dsid = revMap[dep];
      if (dsid) lines.push(`${dsid} --> ${sid}`);
    });
  });
  lines.push('classDef done    fill:#10261a,stroke:#3fd67a,color:#3fd67a');
  lines.push('classDef running fill:#2b2109,stroke:#e0a92d,color:#e0a92d,stroke-width:2px');
  lines.push('classDef ready   fill:#0e1e33,stroke:#5aa9ff,color:#5aa9ff');
  lines.push('classDef blocked fill:#161a21,stroke:#7b8494,color:#7b8494');
  lines.push('classDef failed  fill:#2c1211,stroke:#f0605a,color:#f0605a,stroke-width:2px');
  lines.push('classDef stale   fill:#2c1c10,stroke:#d97a3d,color:#d97a3d,stroke-dasharray:3 2');
  return lines.join('\n');
}

async function renderMermaid(dag) {
  const container = $('#equipe-svg');
  if (!window.mermaid) {
    container.setAttribute('aria-busy', 'false');
    return;
  }
  container.setAttribute('aria-busy', 'true');
  const def = buildMermaidDef(dag);
  try {
    const id = `vf-dag-${renderCounter++}`;
    const { svg } = await window.mermaid.render(id, def);
    container.innerHTML = svg; // voir note de sécurité en tête de fichier
    tagSvgNodes(container);
  } catch {
    clearNode(container);
    container.appendChild(el('p', { class: 'vf-mermaid-error', text: "Le diagramme n'a pas pu être généré — voir le journal." }));
  } finally {
    container.removeAttribute('aria-busy');
  }
}

function tagSvgNodes(container) {
  container.querySelectorAll('g.node').forEach((g) => {
    const m = /-(n\d+)-\d+$/.exec(g.id);
    if (m) g.setAttribute('data-node-id', m[1]);
  });
}

function renderNodeList(dag, openNodeDrawer) {
  const list = $('#equipe-list');
  clearNode(list);
  (dag.nodes || []).forEach((n, i) => {
    const sid = `n${i}`;
    const status = STATUS_SET.has(n.status) ? n.status : 'blocked';
    const li = document.createElement('li');
    const btn = el('button', {
      class: `vf-node-item vf-status-${status}`,
      attrs: { type: 'button', 'data-node-id': sid },
    });
    btn.appendChild(el('span', { class: 'vf-glyph', attrs: { 'aria-hidden': 'true' }, text: STATUS_GLYPH[status] }));
    btn.appendChild(document.createTextNode(` ${n.id} — ${n.stage || '?'} — ${STATUS_TEXT[status]}`));
    btn.addEventListener('mouseenter', () => highlightSvgNode(sid, true));
    btn.addEventListener('mouseleave', () => highlightSvgNode(sid, false));
    btn.addEventListener('focus', () => highlightSvgNode(sid, true));
    btn.addEventListener('blur', () => highlightSvgNode(sid, false));
    btn.addEventListener('click', () => openNodeDrawer(dag, n, btn));
    li.appendChild(btn);
    list.appendChild(li);
  });
}

function highlightSvgNode(sid, on) {
  const target = $('#equipe-svg')?.querySelector(`[data-node-id="${sid}"]`);
  if (target) target.classList.toggle('vf-node-highlight', on);
}
