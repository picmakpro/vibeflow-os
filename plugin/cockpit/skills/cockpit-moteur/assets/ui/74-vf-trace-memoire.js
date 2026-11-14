// VibeFlow (76-07) : mémoire des agents de la traçabilité (UI-SPEC § 1.3, § 4.3, § 5.4, § 6) : section « Mémoire des agents » de la vue d'ensemble, liste d'un
// agent, panneau d'une entrée. La structure seule : jamais le texte d'un fichier de mémoire, un chemin absolu ni un verdict de vieillissement
// (P76-D-20, P76-D-22).
// Chargé avant 74-vf-trace.js : ne déclare que des briques dans window.VFTrace, appelées plus tard (les briques de 74-vf-trace-decisions.js et
// -rendu.js sont lues AU MOMENT de l'appel) ; les ouvreurs se posent par `VT.poseMemoire`. Tout texte du lab est posé en textContent ; les compteurs
// sont ceux de la route.
(() => {
  const VT = (window.VFTrace = window.VFTrace || {});
  const ouvert = { memoire: false }; // l'état d'un repli est tenu ici et restauré à chaque rendu
  const el = (...a) => VT.el(...a), pl = (n, un, plu) => VT.pluriel(n, un, plu), esp = () => document.createTextNode(' ');
  const ouvrirX = (sorte, cle) => (kb, b) => VT.ouvrir(sorte, cle, { clavier: kb, depuis: b });
  const nomDe = (e) => e.name || String(e.cle).split('/').pop();
  const joindre = (a) => a.join(' · ');

  // contradictions (derrière l'octogone) et mentions neutres d'un agent : nuls omis
  const comptes = (a) => {
    const d = (n, un, plu) => (n > 0 ? [pl(n, un, plu)] : []);
    return { c: [...d(a.horsIndex, 'entrée hors index', 'entrées hors index'), ...d(a.liensCasses, 'lien cassé', 'liens cassés'),
      ...d(a.cheminsAbsents, 'chemin cité absent', 'chemins cités absents')],
    k: [...d(a.sansEntrant, 'entrée sans lien entrant', 'entrées sans lien entrant'), ...d(a.resolusParNom, 'lien résolu par nom de fichier',
      'liens résolus par nom de fichier')] };
  };
  // une ligne d'agent : gabarit fermé de trois lignes au plus (§ 4.3)
  const ligneAgent = (a) => {
    const b = el('button', 'vf-trace-ligne', null, { type: 'button', 'data-trace': 'agent:' + a.agent }), l1 = el('span', 'vf-trace-a1'), { c, k } = comptes(a);
    l1.append(el('span', 'vf-trace-m1', a.agent, { title: a.agent }), el('span', 'vf-trace-nb', VT.T(pl(a.entrees, 'entrée', 'entrées')))); b.append(l1);
    if (!c.length && !k.length) b.append(el('span', 'vf-trace-l3', 'aucun écart'));
    else {
      if (c.length) {
        const l2 = el('span', 'vf-trace-mot');
        l2.append(VT.glyphe('contradiction'), esp(), document.createTextNode(VT.T(joindre(c)))); b.append(l2);
      }
      if (k.length) b.append(el('span', 'vf-trace-l3', VT.T(joindre(k))));
    }
    b.append(el('span', 'vf-trace-sr', VT.T(" Ouvrir les entrées de l'agent.")));
    b.addEventListener('click', (ev) => VT.ouvrirAgent(a.agent, { clavier: ev.detail === 0, depuis: b })); return b;
  };
  // une ligne d'entrée (§ 6) : nom mono et type ; « modifiée le … » ; contradictions derrière l'octogone puis « sans lien entrant » (filtre neutre)
  const ligneEntree = (e) => {
    const b = el('button', 'vf-trace-ligne', null, { type: 'button', 'data-trace': 'entree:' + e.cle }), l1 = el('span', 'vf-trace-a1'), nom = nomDe(e);
    l1.append(el('span', 'vf-trace-m1', nom, { title: nom })); if (e.type) l1.append(el('span', 'tag', e.type));
    const jour = VT.jourFr(e.jour);
    b.append(l1, el('span', 'vf-trace-l3', VT.T((jour ? 'modifiée le ' + jour + ' · ' : '') + pl(e.nbEntrants, 'lien entrant', 'liens entrants') + ' · '
      + pl(e.nbSortants, 'lien sortant', 'liens sortants'))));
    const casses = e.sortants.filter((s) => s.etat === 'casse').length, c = [];
    if (e.horsIndex) c.push('hors index');
    if (casses) c.push(pl(casses, 'lien cassé', 'liens cassés'));
    if (e.cheminsAbsents.length) c.push(pl(e.cheminsAbsents.length, 'chemin cité absent', 'chemins cités absents'));
    if (c.length || e.sansEntrant) {
      const l3 = el('span', 'vf-trace-l3 vf-trace-l3t');
      if (c.length) {
        l3.append(VT.glyphe('contradiction'), esp(), el('span', 'vf-trace-contra', VT.T(joindre(c))));
        if (e.sansEntrant) l3.append(document.createTextNode(' · '));
      }
      if (e.sansEntrant) l3.append(document.createTextNode('sans lien entrant'));
      b.append(l3);
    }
    b.append(el('span', 'vf-trace-sr', VT.T(' Ouvrir l\'entrée.')));
    b.addEventListener('click', (ev) => VT.ouvrir('entree', e.cle, { clavier: ev.detail === 0, depuis: b })); return b;
  };

  // liste d'un agent (§ 6) : ses entrées (30 par page) ; une lecture bornée le dit au-dessus d'elle, un agent sans entrée dit pourquoi
  VT.ouvrirAgent = (agent, opts = {}) => VT.lire('memoire', agent).then((r) => {
    const els = r.agent ? r.agent.entrees : [];
    VT.ouvrirListe({ titre: 'Entrées de ' + agent, sorte: ['entrée', 'entrées'], elements: els, rendreLigne: ligneEntree,
      clavier: opts.clavier, depuis: opts.depuis,
      avant: () => (r.bornes && r.bornes.tronque ? [VT.borne()] : []),
      apres: () => (els.length ? [] : [VT.phrase(
        'Aucune entrée suivie pour cet agent. Un fichier de mémoire suivi par git sous son dossier apparaît ici.')]) });
  }, () => {});

  // lignes d'un lien sortant : nom cible mono, état en dessous ; cible résolue : bouton ; cassée : texte non interactif (§ 5.4)
  const ligneSortant = (s) => {
    const casse = s.etat === 'casse', b = casse || !s.vers ? el('div', 'vf-trace-inerte', null, { 'data-trace': 'lien:' + s.cible })
      : el('button', 'vf-trace-ligne', null, { type: 'button', 'data-trace': 'entree:' + s.vers }), l2 = el('span', 'vf-trace-l2e');
    if (casse) l2.append(VT.glyphe('contradiction'), esp());
    else if (s.etat === 'resolu-par-nom') l2.append(VT.glyphe('resolu'), esp());
    l2.append(document.createTextNode(casse ? 'lien cassé' : s.etat === 'resolu-par-nom' ? 'résolu par nom de fichier' : 'résolu'));
    b.append(el('span', 'vf-trace-m1', s.cible, { title: s.cible }), l2);
    if (b.tagName === 'BUTTON') b.addEventListener('click', (ev) => VT.ouvrir('entree', s.vers, { clavier: ev.detail === 0, depuis: b })); return b;
  };
  const ligneEntrant = (cle) => {
    const b = el('button', 'vf-trace-ligne', null, { type: 'button', 'data-trace': 'entree:' + cle });
    b.append(el('span', 'vf-trace-m1', cle, { title: cle }));
    b.addEventListener('click', (ev) => VT.ouvrir('entree', cle, { clavier: ev.detail === 0, depuis: b })); return b;
  };
  const ligneAbsent = (chemin) => {
    const d = el('div', 'vf-trace-inerte vf-trace-absent'), c = el('div', 'vf-trace-chem');
    c.append(VT.glyphe('contradiction'), el('span', null, chemin, { title: chemin }));
    d.append(c, el('div', 'vf-trace-l2e', "absent de HEAD, présent dans l'historique lu")); return d;
  };
  // panneau d'une entrée (§ 5.4) : fiche, état (de l'entrée seulement), liens sortants et entrants, chemins absents, pied de source
  const corpsEntree = (e, nom) => {
    const fiche = VT.sec('Fiche'), dl = el('dl', 'vf-trace-fiche');
    const kids = [el('p', 'vf-trace-note', 'Seule la structure est lue : ni description ni contenu.')];
    const ligne = (k, v) => dl.append(el('dt', null, k), el('dd', null, v, { title: v }));
    dl.append(el('dt', null, 'Agent'), el('dd', 'vf-trace-m1', e.agent, { title: e.agent }));
    if (e.type) { const dd = el('dd'); dd.append(el('span', 'tag', e.type)); dl.append(el('dt', null, 'Type'), dd); }
    if (VT.jourFr(e.jour)) ligne('Dernier commit', VT.jourFr(e.jour));
    ligne('Liens sortants', VT.T(pl(e.nbSortants, 'lien', 'liens'))); ligne('Liens entrants', VT.T(pl(e.nbEntrants, 'lien', 'liens')));
    fiche.append(dl); kids.push(fiche);
    const etat = VT.sec('État'), mots = [e.horsIndex ? ['hors index', true] : null, e.sansEntrant ? ['sans lien entrant', false] : null].filter(Boolean);
    if (!mots.length) etat.append(VT.phrase("Dans l'index, avec au moins un lien entrant."));
    for (const [m, g] of mots) {
      const w = el('div', 'vf-trace-etatm');
      if (g) w.append(VT.glyphe('contradiction'));
      w.append(el('span', null, m)); etat.append(w);
    }
    kids.push(etat);
    const bloc = (titre, els, sorte, rendre) => {
      if (!els.length) return;
      const s = VT.sec(titre, VT.T(pl(els.length, sorte[0], sorte[1]))); s.append(...VT.liste30(els, sorte, rendre, titre + ' de ' + nom)); kids.push(s);
    };
    bloc('Liens sortants', e.sortants, ['lien', 'liens'], ligneSortant); bloc('Liens entrants', e.entrants, ['lien', 'liens'], ligneEntrant);
    bloc('Chemins cités et absents de HEAD', e.cheminsAbsents, ['chemin', 'chemins'], ligneAbsent);
    kids.push(VT.pied(e.chemin)); return kids;
  };
  // le nom (`name`) titre le panneau et la pile commune : il est lu avant l'ouverture ; une entrée disparue s'ouvre sous son nom de fichier
  VT.ouvrirEntree = (cle, { clavier, depuis } = {}) => {
    const ouvrir = (titre) => VT.ouvrirSurMesure({ html: VT.gabarit('Mémoire'), titre, clavier, depuis, bind: (panel) => VT.panneauObjet(panel, {
      vue: 'entree', cle, titre, lire: () => VT.lire('entree', cle).then((p) => ({ principal: p })),
      rendre: (d, cont, { t }) => {
        const e = d.principal.entree, nom = nomDe(e); t.textContent = nom; t.title = nom; t.classList.add('vf-trace-nom-m');
        cont.replaceChildren(...corpsEntree(e, nom));
      } }) });
    return VT.lire('entree', cle).then((r) => ouvrir(r.entree ? nomDe(r.entree) : String(cle).split('/').pop()), () => ouvrir(String(cle).split('/').pop()));
  };

  // section « Mémoire des agents » (§ 4.3) : un bilan fermé de six emplacements (chiffres de la route), une ligne par agent (≤ 30)
  const rendreSection = (p, cont, compte) => {
    const a = p.absences || {}, phrase = (t) => cont.replaceChildren(VT.phrase(t));
    compte.textContent = '';
    if (a.git) return phrase("Git n'est pas disponible : la mémoire des agents n'est pas lue. Un dépôt git la rend lisible.");
    if (a.memoire === 'ignoree') {
      return phrase(".claude/ n'est pas suivi par git : " + pl(a.nonSuivis, 'fichier non suivi', 'fichiers non suivis')
        + ', aucune entrée à lire. Suivre .claude/agent-memory/ dans git les rend lisibles.');
    }
    if (a.memoire === 'absente') return phrase('Pas de .claude/agent-memory/ dans ce dossier. Les fichiers de mémoire suivis par git apparaîtraient ici.');
    const c = p.memoire.compteurs, agents = p.memoire.agents;
    compte.textContent = VT.T(pl(c.entrees, 'entrée', 'entrées'));
    return cont.replaceChildren(el('p', 'vf-trace-bilan vf-trace-bilan-4', VT.T(joindre([pl(c.entrees, 'entrée', 'entrées'), pl(c.agents, 'agent', 'agents'),
      pl(c.horsIndex, 'entrée hors index', 'entrées hors index'), pl(c.liensCasses, 'lien cassé', 'liens cassés'),
      pl(c.cheminsAbsents, 'chemin cité absent', 'chemins cités absents'), pl(c.sansEntrant, 'entrée sans lien entrant', 'entrées sans lien entrant')]))),
    ...VT.liste30(agents, ['agent', 'agents'], ligneAgent, 'Agents'));
  };
  VT.sectionMemoire = (SC, vivant) => {
    SC.addPanelSection('overview', () => {
      if (!vivant()) return '';
      return { html: '<div class="sec vf-trace"><details class="vf-trace-repli" data-vf-trace-memoire><summary class="vf-trace-sec-t">Mémoire des agents '
        + '<span class="c"></span></summary><div data-vf-trace-corps></div></details></div>',
      bind: (racine) => {
        const d = racine.querySelector('details'), compte = racine.querySelector('summary .c');
        const z = VT.zone(racine.querySelector('[data-vf-trace-corps]'), { cle: 'memoire|', ouvert: () => d.open,
          lire: () => VT.lire('memoire').then((p) => ({ principal: p })), rendre: (r, cont) => rendreSection(r.principal, cont, compte) });
        d.open = ouvert.memoire; d.addEventListener('toggle', () => { ouvert.memoire = d.open; if (d.open) z.charger(); });
        if (d.open) z.charger();
      } };
    });
  };
  VT.poseMemoire = (O) => { O.entree = VT.ouvrirEntree; O.agent = VT.ouvrirAgent; };
})();
