// VibeFlow (69-05, réduit en 73-08) : onglet Équipe. Depuis la Phase 73 la page n'a plus de canevas : la liste des agents, leurs états et le détail d'une ligne sont ceux de la régie
// (ui/72-vf-regie-*.js, lus depuis `who` par l'adaptateur de 72-vf-regie-source.js). Ne reste ici que le libellé de la recherche de l'onglet Équipe. Ce fichier ne se redessine
// jamais, ne recharge jamais la page, n'écrit rien dans le stockage du navigateur et n'ouvre aucun panneau d'agent. Ne fait rien hors de l'onglet Équipe.
(() => {
  const SC = window.Floorplan;
  if (!SC || !SC.graph?.meta || SC.graph.meta.vfTab !== 'equipe') return;
  // P69-D-33 : la recherche de cet onglet trouve des agents et des sessions, pas des fichiers, des routes ni des modules
  const LIB = 'Chercher un agent ou une session';
  const bouton = document.getElementById('search-btn'), champ = document.getElementById('search');
  if (bouton) { bouton.setAttribute('aria-label', LIB); bouton.title = LIB; const st = bouton.querySelector('.st'); if (st) st.textContent = LIB; }
  if (champ) champ.placeholder = 'Chercher par nom, rôle ou description';
})();
