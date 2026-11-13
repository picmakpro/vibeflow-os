// VibeFlow (76-06) : les sections de la traçabilité posées dans le panneau du moteur (UI-SPEC § 2, § 3, § 4.1) : addPanelSection seulement, jamais setOverview.
// Le rappel rend un gabarit statique (aucune donnée du lab dans le HTML) ; `bind` remplit en place par le DOM (textContent), sans rerender de la carte.
(() => {
  const VT = (window.VFTrace = window.VFTrace || {});
  const phaseDe = (cible) => (typeof cible === 'string' && /^n:ph-\d/.test(cible) ? cible.slice(2) : null);

  // section « Traçabilité » d'une phase
  VT.phaseSection = (racine, id) => {
    const corps = racine.querySelector('[data-vf-trace-corps]'), compte = racine.querySelector('h3 .c');
    const z = VT.zone(corps, {
      cle: 'phase|' + id,
      lire: () => VT.lire('phase', id).then((p) => ({ principal: p })),
      rendre: (d, cont) => {
        const ph = d.principal.phase, ex = ph.exigences;
        compte.textContent = VT.T(VT.N(ex.length) + ' ' + VT.P(ex.length, 'exigence', 'exigences'));
        const surOuvrir = (ligne, clavier, b) => VT.ouvrirExigence && VT.ouvrirExigence(ligne, clavier, b);
        cont.replaceChildren(...ex.map((l) => VT.ligneExigence(l, { surOuvrir })));
      },
    });
    z.charger();
  };

  VT.sections = (SC, vivant) => {
    SC.addPanelSection('item', (cible) => {
      const id = phaseDe(cible);
      if (!id || !vivant()) return '';
      return { html: '<div class="sec vf-trace" id="vf-trace-phase"><h3>Traçabilité <span class="c"></span></h3><div data-vf-trace-corps></div></div>',
        bind: (racine) => VT.phaseSection(racine, id) };
    });
  };
})();
