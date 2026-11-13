// VibeFlow (76-06) : les sections de la traçabilité posées dans le panneau du moteur (UI-SPEC § 2, § 3, § 4.1) : addPanelSection seulement (la fonction qui
// remplace la vue d'ensemble n'est jamais appelée),
// Le rappel rend un gabarit statique (aucune donnée du lab dans le HTML) ; `bind` remplit en place par le DOM (textContent).
(() => {
  const VT = (window.VFTrace = window.VFTrace || {});
  const ouvert = { preuves: false, jalon: false }; // l'état d'un repli est tenu ici et restauré à chaque rendu : un re-rendu ne referme rien
  const phaseDe = (cible) => (typeof cible === 'string' && /^n:ph-\d/.test(cible) ? cible.slice(2) : null);
  const etroit = () => window.matchMedia('(max-width: 700px)').matches;
  const lirePhase = (id) => () => VT.lire('phase', id).then((p) => ({ principal: p }));

  // repli « Preuves attachées » : fermé par défaut, plafonné ouvert à 6 lignes (4 sous 700 px), la phase d'abord puis chaque plan
  const preuves = (ph) => {
    const el = VT.el, ps = VT.preuvesTriees(ph.preuves);
    const max = etroit() ? 4 : 6, d = el('details', 'vf-trace-repli'), s = el('summary', 'vf-trace-sec-t', 'Preuves attachées');
    s.append(document.createTextNode(' '), el('span', 'c', VT.T(VT.N(ps.length) + ' ' + VT.P(ps.length, 'fichier', 'fichiers'))));
    d.append(s);
    if (!ps.length) d.append(VT.etat('aucune-preuve'));
    else {
      for (const p of ps.slice(0, max)) d.append(VT.ligneProuve(p));
      const ouvrir = (clavier) => VT.ouvrirListePreuves(ph, null, clavier);
      if (ps.length > max) d.append(VT.plus(['fichier de preuve', 'fichiers de preuve'], ps.length - max, ouvrir));
    }
    d.open = ouvert.preuves; d.addEventListener('toggle', () => { ouvert.preuves = d.open; });
    return d;
  };

  // section « Traçabilité » d'une phase : bilan, légende, au plus 5 lignes (3 sous 700 px), « + N autres exigences », preuves attachées
  VT.phaseSection = (racine, id) => {
    const corps = racine.querySelector('[data-vf-trace-corps]'), compte = racine.querySelector('h3 .c');
    VT.zone(corps, {
      cle: 'phase|' + id, lire: lirePhase(id),
      rendre: (d, cont) => {
        const ph = d.principal.phase, ex = ph.exigences, max = etroit() ? 3 : 5, kids = [];
        compte.textContent = VT.T(VT.N(ex.length) + ' ' + VT.P(ex.length, 'exigence', 'exigences'));
        if (!ex.length) kids.push(VT.etat('vide-phase'));
        else {
          const surOuvrir = (ligne, clavier, b) => VT.ouvrirExigence(ligne, clavier, b);
          const lignes = VT.el('div', 'vf-trace-lignes');
          lignes.append(...ex.slice(0, max).map((l) => VT.ligneExigence(l, { surOuvrir })));
          kids.push(VT.el('p', 'vf-trace-bilan', VT.T(VT.bilanPhase(ph.bilan))), VT.legende(), lignes);
          const ouvrir = (clavier) => VT.ouvrirListeExigences(ph, clavier);
          if (ex.length > max) kids.push(VT.plus(['exigence', 'exigences'], ex.length - max, ouvrir));
        }
        if (ex.length || ph.preuves.length) kids.push(preuves(ph));
        cont.replaceChildren(...kids);
      },
    }).charger();
  };

  // entrée haute : un seul bouton qui mène à la section ; rendue seulement si la phase a au moins une exigence
  VT.entreeSection = (racine, id) => {
    const cont = racine.querySelector('[data-vf-trace-entree]');
    VT.zone(cont, {
      cle: 'phase|' + id, lire: lirePhase(id), sansEtat: true,
      rendre: (d, c) => {
        const ph = d.principal.phase;
        c.hidden = !ph.exigences.length;
        if (c.hidden) return c.replaceChildren();
        const b = VT.el('button', 'vf-trace-ligne', null, { type: 'button', 'data-vf-section': 'vf-trace-phase' });
        b.append(VT.el('span', 'vf-trace-nom1', 'Traçabilité'), document.createTextNode(' '), VT.el('span', 'vf-trace-bilan', VT.resume(ph.bilan)),
          document.createTextNode(' '), VT.el('span', 'vf-trace-sr', 'Aller à la section.'));
        return c.replaceChildren(b);
      },
    }).charger();
  };

  // section « Jalon » de la vue d'ensemble : repliée par défaut, lue à la première ouverture, relue seulement ouverte
  VT.jalonSection = (racine) => {
    const d = racine.querySelector('details'), corps = racine.querySelector('[data-vf-trace-corps]'), compte = racine.querySelector('summary .c');
    const z = VT.zone(corps, {
      cle: 'jalon|', ouvert: () => d.open, lire: () => VT.lire('jalon').then((p) => ({ principal: p })),
      rendre: (r, cont) => {
        const j = r.principal.jalon, ph = j && j.phases ? j.phases : [];
        compte.textContent = VT.T(VT.N(ph.length) + ' ' + VT.P(ph.length, 'phase', 'phases'));
        if (!j || !j.jalon || !ph.length) return cont.replaceChildren(VT.etat('jalon-vide'));
        const surOuvrir = (p) => VT.allerNoeud('n:' + p.id), lignes = VT.el('div', 'vf-trace-lignes');
        lignes.append(...ph.slice(0, 30).map((p) => VT.ligneJalon(p, { surOuvrir })));
        const kids = [VT.el('p', 'vf-trace-bilan vf-trace-bilan-4', VT.T(VT.bilanJalon(j.bilan))), lignes];
        if (ph.length > 30) kids.push(VT.plus(['phase', 'phases'], ph.length - 30, () => VT.allerNoeud('n:' + ph[30].id)));
        return cont.replaceChildren(...kids);
      },
    });
    d.open = ouvert.jalon;
    d.addEventListener('toggle', () => { ouvert.jalon = d.open; if (d.open) z.charger(); });
    if (d.open) z.charger();
  };

  VT.sections = (SC, vivant) => {
    SC.addPanelSection('item', (cible) => {
      const id = phaseDe(cible);
      if (!id || !vivant()) return '';
      return { top: true, html: '<div class="sec vf-trace" data-vf-trace-entree hidden></div>', bind: (racine) => VT.entreeSection(racine, id) };
    });
    SC.addPanelSection('item', (cible) => {
      const id = phaseDe(cible);
      if (!id || !vivant()) return '';
      return { html: '<div class="sec vf-trace" id="vf-trace-phase"><h3>Traçabilité <span class="c"></span></h3><div data-vf-trace-corps></div></div>',
        bind: (racine) => VT.phaseSection(racine, id) };
    });
    SC.addPanelSection('overview', () => {
      if (!vivant()) return '';
      return { html: '<div class="sec vf-trace"><details class="vf-trace-repli" data-vf-trace-jalon>'
        + '<summary class="vf-trace-sec-t">Jalon <span class="c"></span></summary>'
        + '<div data-vf-trace-corps></div></details></div>', bind: (racine) => VT.jalonSection(racine) };
    });
  };
})();
