// chrome-statut.mjs — recette 68 R11 : le statut STATE brut (« ready_to_plan ») n'est jamais affiché sur la page Projet.
// Usage : node chrome-statut.mjs <chrome> <url file:// de project.html>. Rend { visibles } : les textes VISIBLES (hors script/style) qui contiennent un statut brut, et { sousTitre } le sous-titre relevé.
import { executer } from './chrome-session.mjs';
const [, , chrome, url] = process.argv;
await executer(chrome, async (s) => {
  await s.naviguer(url);
  await s.attendre("document.readyState === 'complete' && !!window.VibeFlow && !!window.__vfFrTraduire && !!document.querySelector('.vf-now .vst')", 'page Projet rendue');
  return await s.ev(`(() => { const w = document.createTreeWalker(document.body, 4); const visibles = [], sous = [];
    while (w.nextNode()) { const n = w.currentNode, p = n.parentElement; if (!p || /^(SCRIPT|STYLE)$/.test(p.tagName)) continue; const t = n.nodeValue.trim();
      if (/\\b(ready_to_plan|ready_to_execute|milestone_complete)\\b/.test(t)) visibles.push(t.slice(0, 120)); if (/^Jalon .* · phase /.test(t)) sous.push(t.slice(0, 120)); }
    return { visibles, sousTitre: sous[0] || null, pastille: document.querySelector('.vf-now .vst')?.textContent || null }; })()`);
});
