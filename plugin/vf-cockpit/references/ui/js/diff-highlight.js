// diff-highlight.js — micro-signaux ciblés entre deux snapshots, jamais de flash
// pleine page (§0/§6 DESIGN-SPEC).
import { flashElement } from './dom.js';

export function highlightChanges(snap, prev) {
  if (!prev) return;
  const prevPhaseDone = new Map((prev.phases || []).map((p) => [p.num, p.done]));
  (snap.phases || []).forEach((p) => {
    if (prevPhaseDone.has(p.num) && prevPhaseDone.get(p.num) !== p.done) {
      flashElement(document.querySelector(`.vf-phase-chip[data-phase-num="${p.num}"]`));
    }
  });

  const prevDag = (prev.dags || [])[0];
  const curDag = (snap.dags || [])[0];
  if (prevDag && curDag) {
    const prevStatus = new Map((prevDag.nodes || []).map((n) => [n.id, n.status]));
    (curDag.nodes || []).forEach((n, i) => {
      if (prevStatus.has(n.id) && prevStatus.get(n.id) !== n.status) {
        const sid = `n${i}`;
        flashElement(document.querySelector(`#equipe-list [data-node-id="${sid}"]`));
        flashElement(document.querySelector(`#equipe-svg [data-node-id="${sid}"]`));
      }
    });
  }
}
