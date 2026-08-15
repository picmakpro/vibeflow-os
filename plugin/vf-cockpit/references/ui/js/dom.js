// dom.js — petits utilitaires DOM partagés. Jamais d'innerHTML sur du contenu de
// fichier lab (voir la note de sécurité dans equipe.js pour l'unique exception).

export const STATUS_GLYPH = { done: '●', running: '◉', ready: '○', blocked: '┄', failed: '✕', stale: '⚠' };
export const STATUS_TEXT = { done: 'terminé', running: 'en cours', ready: 'prêt', blocked: 'en attente', failed: 'échoué', stale: 'périmé' };
export const STATUS_SET = new Set(Object.keys(STATUS_GLYPH));

export const $ = (sel, root = document) => root.querySelector(sel);

export function clearNode(node) {
  while (node.firstChild) node.removeChild(node.firstChild);
}

export function el(tag, opts = {}) {
  const e = document.createElement(tag);
  if (opts.class) e.className = opts.class;
  if (opts.attrs) for (const [k, v] of Object.entries(opts.attrs)) e.setAttribute(k, v);
  if (opts.text !== undefined) e.textContent = opts.text;
  return e;
}

export function pad2(n) { return String(n).padStart(2, '0'); }
export function formatTime(d) { return `${pad2(d.getHours())}:${pad2(d.getMinutes())}:${pad2(d.getSeconds())}`; }

export function flashElement(node) {
  if (!node) return;
  node.classList.remove('vf-flash-changed');
  void node.offsetWidth;
  node.classList.add('vf-flash-changed');
  setTimeout(() => node.classList.remove('vf-flash-changed'), 640);
}
