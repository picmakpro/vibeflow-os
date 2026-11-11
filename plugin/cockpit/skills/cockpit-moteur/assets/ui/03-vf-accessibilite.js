// VibeFlow (AUDC-X4, AUDC-X6) : finitions d'accessibilité des trois onglets, dans un fichier à part (00-vibeflow.js tient sous le plafond de 300 lignes) :
// un seul anneau de focus, et le mouvement réduit (zéro mouvement, mais chaque repère utile reste visible, sous forme statique).
(() => {
  if (!window.Floorplan) return;
  const style = document.createElement('style');
  style.textContent = `
    /* AUDC-X4 : un seul anneau de focus, celui du jeton --ring (2 px, décalé de 2 px) : tout élément atteint au clavier le porte, onglets, fil d'Ariane, titre, « Demander » et définitions comprises (le bleu du navigateur et l'ombre des définitions disparaissent) ; :where() garde une spécificité nulle, les règles propres à un élément (décalage négatif d'une ligne, par exemple) l'emportent donc, et le champ de question, sans contour propre, le porte par son formulaire */
    :where(a, button, input, select, textarea, summary, [tabindex]):focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; }
    body .sc-term:focus-visible { box-shadow: none; outline: 2px solid var(--ring); outline-offset: 2px; }
    #ask-form:has(#ask-input:focus-visible) { outline: 2px solid var(--ring); outline-offset: 2px; }
    /* AUDC-X6 : mouvement réduit, à toute largeur et sur tout appareil (la règle du moteur ne couvrait que le téléphone) : ni fondu ni déplacement de plongée, ni apparition des cartes, ni pulsation ; la vue change d'un coup et garde son état final.
       Les repères utiles restent, STATIQUES : le contour d'une carte qui vient de changer d'état (retiré plus bas après le même délai que le clignotement), l'anneau d'attente de « Demander » (un quart coloré, sans rotation), le point d'un verrou tenu (plein, sans pulsation) */
    @media (prefers-reduced-motion: reduce) {
      *, *::before, *::after { animation: none !important; transition: none !important; scroll-behavior: auto !important; }
      .node.flash .card { outline-color: var(--ring); }
    }
  `;
  document.head.appendChild(style);
  // mouvement réduit : sans animation, aucun animationend ne vient plus ; les deux entrées (tiroir Git, tiroir du terminal) retirent leur classe sur cet évènement, il leur est donné tout de suite,
  // et le contour statique d'une carte (classe flash) est retiré après les 700 ms du clignotement qu'il remplace : aucun état ne reste posé
  const reduit = window.matchMedia('(prefers-reduced-motion: reduce)');
  const minuteries = new WeakMap();
  const regarder = (e) => {
    if (!e.classList) return;
    if (e.classList.contains('vf-git-entree') || e.classList.contains('vf-term-entree')) setTimeout(() => e.dispatchEvent(new Event('animationend', { bubbles: true })), 0);
    if (e.classList.contains('flash') && !minuteries.has(e)) minuteries.set(e, setTimeout(() => { minuteries.delete(e); e.classList.remove('flash'); }, 700));
    else if (!e.classList.contains('flash') && minuteries.has(e)) { clearTimeout(minuteries.get(e)); minuteries.delete(e); }
  };
  new MutationObserver((ms) => {
    if (!reduit.matches) return;
    for (const m of ms) { regarder(m.target); for (const n of m.addedNodes) { regarder(n); if (n.querySelectorAll) n.querySelectorAll('.vf-git-entree, .vf-term-entree, .flash').forEach(regarder); } }
  }).observe(document.documentElement, { attributes: true, attributeFilter: ['class'], childList: true, subtree: true });
})();
