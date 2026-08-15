// markdown-light.js — rendu Markdown-léger (gras/code uniquement), jamais de Markdown
// complet, jamais d'innerHTML (§4.6 DESIGN-SPEC : "pas de rendu Markdown complet").
import { el } from './dom.js';

export function renderLightMarkdown(text) {
  const container = document.createElement('div');
  container.className = 'vf-md-body';
  text.split(/\n{2,}/).forEach((para) => {
    if (!para.trim()) return;
    const p = document.createElement('p');
    appendInlineTokens(p, para);
    container.appendChild(p);
  });
  return container;
}

function appendInlineTokens(parent, text) {
  const re = /(\*\*[^*]+\*\*|`[^`]+`)/g;
  let last = 0;
  let m;
  while ((m = re.exec(text)) !== null) {
    if (m.index > last) parent.appendChild(document.createTextNode(text.slice(last, m.index)));
    const token = m[0];
    if (token.startsWith('**')) {
      parent.appendChild(el('strong', { text: token.slice(2, -2) }));
    } else {
      parent.appendChild(el('code', { text: token.slice(1, -1) }));
    }
    last = re.lastIndex;
  }
  if (last < text.length) parent.appendChild(document.createTextNode(text.slice(last)));
}
