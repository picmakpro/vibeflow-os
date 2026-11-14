// chrome-statut.mjs — recette 68 R11 : le statut STATE brut (« ready_to_plan ») n'est jamais affiché sur la page Projet.
// Usage : node chrome-statut.mjs <chrome> <url file:// de project.html>. Rend { visibles } : les textes VISIBLES (hors script/style) qui contiennent un statut brut, et { sousTitre } le sous-titre relevé.
import { executer, attendreEtStabiliser } from './chrome-session.mjs';
const [, , chrome, url] = process.argv;
await executer(chrome, async (s) => {
  await s.naviguer(url);
  await s.attendre("document.readyState === 'complete' && !!window.VibeFlow && !!window.__vfFrTraduire && !!document.querySelector('.vf-now .vst')", 'page Projet rendue');
  const lire = () => s.ev(`(() => { const w = document.createTreeWalker(document.body, 4); const visibles = [], sous = [];
    while (w.nextNode()) { const n = w.currentNode, p = n.parentElement; if (!p || /^(SCRIPT|STYLE)$/.test(p.tagName)) continue; const t = n.nodeValue.trim();
      if (/\\b(ready_to_plan|ready_to_execute|milestone_complete)\\b/.test(t)) visibles.push(t.slice(0, 120)); }
    const d = document.querySelector('#ctx-desc'); if (d) sous.push(d.textContent.trim().slice(0, 120));
    return { visibles, sousTitre: sous[0] || null, pastille: document.querySelector('.vf-now .vst')?.textContent || null }; })()`);
  // la traduction française est appliquée en différé : on attend le sous-titre et la pastille que F9.2 attend, puis une lecture stable (le contrôle « aucun statut brut » se fait sur l'état posé)
  return await attendreEtStabiliser(lire, (v) => v && v.pastille === 'À faire' && v.sousTitre === 'Phase 1, 0 phase faite sur 1.', { pas: 150, max: 8000 });
});
