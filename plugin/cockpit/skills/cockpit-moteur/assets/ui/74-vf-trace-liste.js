// VibeFlow (76-06) : panneau de liste paginé de la traçabilité (UI-SPEC § 6) : 30 lignes par page, pagination sur deux lignes fixes, focus sur le titre
// au changement de page, ouverture positionnée sur une ligne (une preuve). Employé pour « Exigences de la Phase N », « Preuves de la Phase N »,
// « Plans de l'exigence X » et les décisions citées ; 76-07 l'emploie pour ses propres listes.
(() => {
  const VT = (window.VFTrace = window.VFTrace || {});
  const PAGE = 30;
  const GABARIT = '<div class="vf-trace" data-vf-trace-panneau><div class="ph"><span class="kindlabel">Liste</span></div>'
    + '<h2 class="pt" tabindex="-1"></h2><div data-vf-trace-corps></div></div>';

  // ouvrirListe({ titre, sorte: [singulier, pluriel], elements, rendreLigne(element) -> Node, visee(element) -> bool, avant() -> Node[], apres() -> Node[],
//   clavier, depuis })
  VT.ouvrirListe = (o) => {
    const etat = { page: 0 }, total = o.elements.length;
    if (o.visee) { const i = o.elements.findIndex(o.visee); if (i >= 0) etat.page = Math.floor(i / PAGE); }
    const bind = (panel) => {
      const racine = panel.querySelector('[data-vf-trace-panneau]'), t = racine.querySelector('.pt'), corps = racine.querySelector('[data-vf-trace-corps]');
      t.textContent = o.titre; t.id = 'vf-trace-liste-' + o.titre.replace(/[^\w-]/g, '_'); t.setAttribute('data-trace', 'liste:' + o.titre);
      const sec = VT.el('div', 'sec'), h = VT.el('h3', null, o.titre.split(' de ')[0]);
      h.append(document.createTextNode(' '), VT.el('span', 'c', VT.T(VT.N(total) + ' ' + VT.P(total, o.sorte[0], o.sorte[1]))));
      const rendre = (focusTitre) => {
        const debut = etat.page * PAGE, fin = Math.min(total, debut + PAGE), lignes = VT.el('div', 'vf-trace-lignes'), kids = [lignes];
        lignes.append(...o.elements.slice(debut, fin).map((e) => o.rendreLigne(e)));
        if (total > PAGE) {
          const nav = VT.el('nav', 'vf-trace-pages', null, { 'aria-label': 'Pagination', 'data-vf-trace-pages': '' }), b = VT.el('div', 'vf-trace-pages-b');
          const prec = VT.el('button', 'btn soft', 'Précédentes', { type: 'button' }), suiv = VT.el('button', 'btn soft', 'Suivantes', { type: 'button' });
          prec.disabled = etat.page === 0; suiv.disabled = fin >= total;
          prec.addEventListener('click', () => { etat.page--; rendre(true); }); suiv.addEventListener('click', () => { etat.page++; rendre(true); });
          b.append(prec, suiv);
          nav.append(VT.el('p', 'vf-trace-compte', VT.T((debut + 1) + ' à ' + fin + ' sur ' + VT.N(total) + ' ' + o.sorte[1]), { 'aria-live': 'polite' }), b);
          kids.push(nav);
        }
        sec.replaceChildren(h, ...(o.avant ? o.avant() : []), ...kids);
        if (o.apres) sec.append(...o.apres());
        if (focusTitre) t.focus();
        const vise = sec.querySelector('[aria-current="true"]');
        if (vise) { vise.scrollIntoView({ block: 'start' }); if (o.clavier) vise.querySelector('button, .vf-trace-ligne')
          && vise.querySelector('button, .vf-trace-ligne').focus(); }
      };
      corps.append(sec); rendre(false);
    };
    VT.ouvrirSurMesure({ html: GABARIT, bind, titre: o.titre, clavier: o.clavier, depuis: o.depuis });
  };

  VT.ouvrirListeExigences = (ph, clavier) => VT.ouvrirListe({ titre: 'Exigences de la Phase ' + ph.n, sorte: ['exigence', 'exigences'],
    elements: ph.exigences, clavier,
    rendreLigne: (l) => VT.ligneExigence(l, { surOuvrir: (ligne, kb, b) => VT.ouvrirExigence(ligne, kb, b) }) });

  // preuves d'une phase : portée, libellé, statut, chemin copiable ; les critères des plans en texte sous la liste ; `visee` = chemin de la preuve à amener
  // en haut
  VT.ouvrirListePreuves = (ph, visee, clavier, depuis) => VT.ouvrirListe({
    titre: 'Preuves de la Phase ' + ph.n, sorte: ['fichier de preuve', 'fichiers de preuve'], elements: VT.preuvesTriees(ph.preuves), clavier, depuis,
    visee: visee ? (p) => p.fichier === visee : null,
    rendreLigne: (p) => { const d = VT.ligneProuve(p); if (visee && p.fichier === visee) d.setAttribute('aria-current', 'true'); return d; },
    apres: () => (ph.plans || []).filter((p) => p.criteres && p.criteres.liste.length).map((p) => {
      const b = VT.el('div', 'vf-trace-bloc');
      b.append(VT.el('p', 'vf-trace-nom1', VT.T(p.id + ' · Critères du plan, ' + VT.N(p.criteres.n) + ' ' + VT.P(p.criteres.n, 'critère', 'critères'))));
      for (const c of p.criteres.liste) b.append(VT.el('p', 'vf-trace-critere', c));
      return b;
    }),
  });
})();
