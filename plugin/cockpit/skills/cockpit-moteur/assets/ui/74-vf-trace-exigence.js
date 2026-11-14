// VibeFlow (76-06) : panneau d'une exigence (UI-SPEC § 5.1) : Chaîne, Décisions citées, Preuves, Mentions, Rattachement, pied « Lu dans … ».
// Ouvert par VT.ouvrirSurMesure : le panneau quitté est empilé une fois, par celui qui le quitte (la pile commune de la Phase 80 empile seule un nœud).
// Aucun contenu de fichier de preuve n'est rendu ; tout texte du lab est posé en textContent.
(() => {
  const VT = (window.VFTrace = window.VFTrace || {});
  const GABARIT = '<div class="vf-trace" data-vf-trace-panneau><div class="ph"><span class="kindlabel">Exigence</span></div>'
    + '<h2 class="pt" tabindex="-1"></h2><p class="pd"></p><div data-vf-trace-corps></div></div>';
  const CONTRA = {
    'cochee-sans-summary': 'contradiction : case cochée au registre des exigences, aucun SUMMARY lu',
    'complete-sans-plan': 'contradiction : statut Complete au tableau de traçabilité, aucun plan ne la cite',
  };
  const NEUTRES = { 'non-cochee-summary-lu': 'Case non cochée au registre des exigences, un SUMMARY est lu.',
    'sans-ligne-tracabilite': 'Aucune ligne du tableau de traçabilité ne la nomme.' };
  const planDe = (chemin) => String(chemin).split('/').pop().replace(/-PLAN\.md$/, '');

  VT.ouvrirExigence = (ligne, clavier, depuis) => VT.ouvrirSurMesure({ html: GABARIT, titre: ligne.id, clavier, depuis,
    bind: (panel) => VT.exigencePanel(panel, ligne.cle || ligne.id, ligne) });

  const section = (titre, compte) => {
    const s = VT.el('div', 'sec'), h = VT.el('h3', null, titre);
    if (compte) h.append(document.createTextNode(' '), VT.el('span', 'c', VT.T(compte)));
    s.append(h); return s;
  };
  const pluriel = (n, un, plu) => VT.N(n) + ' ' + VT.P(n, un, plu);
  // une ligne de voisin : bouton, identifiant mono puis titre, sans glyphe ; son nom accessible dit ce qu'elle ouvre
  const voisin = (id, titre, trace, nom, ouvrir) => {
    const b = VT.el('button', 'vf-trace-ligne', null, { type: 'button', 'data-trace': trace }), l1 = VT.el('span', 'vf-trace-l1');
    l1.append(VT.el('span', 'vf-trace-id', id), VT.el('span', 'vf-trace-tt', titre || '', { title: titre || '' }));
    b.append(l1, VT.el('span', 'vf-trace-sr', VT.T(nom)));
    b.addEventListener('click', (ev) => ouvrir(ev.detail === 0, b)); return b;
  };

  // « Chaîne » : l'aide, quatre maillons (état et niveau dits ici, seule source visible du niveau), leurs sources, les puces de plan
  const chaine = (e) => {
    const s = section('Chaîne');
    s.append(VT.el('p', 'vf-trace-aide',
      VT.T('Niveau exigence : le fichier lu cite cette exigence. Niveau phase : le fichier existe pour la phase sans la citer.')));
    for (const m of VT.MAILLONS) {
      const x = e.maillons[m], r = VT.el('div', 'vf-trace-maillon');
      const dit = x.etat === 'lu' ? 'lu, niveau ' + x.niveau : x.etat === 'non-lisible' ? 'non lisible' : x.etat === 'contradiction' ? (CONTRA[x.code]
        || 'contradiction') : 'manque';
      r.append(VT.glyphe(x.etat), VT.el('span', 'vf-trace-nom', VT.CAP[m]), document.createTextNode(' '), VT.el('span', 'vf-trace-note', VT.T(dit)));
      s.append(r);
      if (x.etat === 'lu' || x.etat === 'non-lisible') for (const f of x.sources.slice(0, 2)) s.append(VT.chemin(f));
      if (m === 'plan' && x.sources.length) {
        const puces = VT.el('div', 'vf-trace-puces'), plans = x.sources.map((f) => ({ f, id: planDe(f) }));
        for (const p of plans.slice(0, 3)) {
          const b = VT.el('button', 'tag vf-trace-puce', p.id, { type: 'button', title: p.id });
          b.addEventListener('click', () => VT.allerNoeud('f:' + p.f)); puces.append(b);
        }
        if (plans.length > 3) {
          const b = VT.el('button', 'tag vf-trace-puce', VT.T('+ ' + VT.N(plans.length - 3)), { type: 'button', title: 'Plans de l\'exigence ' + e.id });
          b.addEventListener('click', (ev) => VT.ouvrirListe({ titre: 'Plans de l\'exigence ' + e.id, sorte: ['plan', 'plans'], elements: plans,
            clavier: ev.detail === 0,
            depuis: b, rendreLigne: (p) => voisin(p.id, '', 'plan:' + p.f, 'Plan ' + p.id + '. Ouvrir le plan.', () => VT.allerNoeud('f:' + p.f)) }));
          puces.append(b);
        }
        s.append(puces);
      }
    }
    return s;
  };

  // « Décisions citées » : les identifiants cités dans la ligne de l'exigence ; une décision nue n'est jamais montrée (ADR-075)
  const decisions = (e, d) => {
    const ad = d.adr, defs = ad ? ad.registres.flatMap((r) => r.decisions) : [], items = [];
    for (const x of e.decisions) {
      const def = x.cle ? defs.find((y) => y.cle === x.cle) : null;
      items.push({ id: x.id, titre: def ? def.titre : '', actif: !!x.cle, trace: 'decision:' + x.cle, sorte: 'decision', cle: x.cle,
        inerte: 'sans définition lue' });
    }
    for (const x of e.adrs) {
      const a = ad ? ad.adrs.find((y) => y.id === x.id) : null;
      items.push({ id: x.id, titre: a && a.titre ? a.titre : '', actif: !ad || !!(a && a.cle), trace: 'adr:' + x.id, sorte: 'adr', cle: x.cle,
        inerte: 'sans section dans docs/ADR.md' });
    }
    const s = section('Décisions citées', pluriel(items.length, 'décision', 'décisions'));
    if (!items.length) {
      s.append(VT.el('p', 'vf-trace-etat',
        VT.T("aucune décision citée. Un identifiant Pnn-D-nn ou ADR-nnn dans la ligne de l'exigence au registre des exigences la relierait.")));
      return s;
    }
    const ligne = (i) => {
      if (!i.actif) { const p = VT.el('p', 'vf-trace-inerte vf-trace-etat'); p.append(VT.el('span', 'vf-trace-id', i.id), document.createTextNode(' '
        + i.inerte)); return p; }
      const nom = i.sorte === 'adr' ? i.id + ', ' + i.titre + ". Ouvrir l'ADR." : 'Décision ' + i.id + ', ' + i.titre + '. Ouvrir la décision.';
      return voisin(i.id, i.titre, i.trace, nom, (clavier, b) => VT.ouvrir(i.sorte, i.cle, { clavier, depuis: b }));
    };
    const liste = VT.el('div', 'vf-trace-lignes vf-trace-decisions');
    liste.append(...items.slice(0, 30).map(ligne)); s.append(liste);
    if (items.length > 30) {
      s.append(VT.plus(['décision', 'décisions'], items.length - 30, (clavier) => VT.ouvrirListe({ titre: 'Décisions citées par ' + e.id,
        sorte: ['décision', 'décisions'],
        elements: items, clavier, rendreLigne: ligne })));
    }
    return s;
  };

  // « Preuves » : une ligne par maillon de preuve lu ; un clic ouvre la liste des preuves de la phase, positionnée sur celle-ci
  const preuves = (e, d) => {
    const ph = d.ph ? d.ph.phase : null, plans = new Set(e.maillons.plan.sources.map(planDe)), lues = [];
    for (const m of ['verification', 'recette']) {
      if (e.maillons[m].etat !== 'lu') continue;
      for (const f of e.maillons[m].sources) lues.push((ph && ph.preuves.find((p) => p.fichier === f)) || { sorte: m, fichier: f, plan: null, statut: null });
    }
    if (ph) for (const p of ph.preuves) if (p.sorte === 'trace-rouge' && p.plan && plans.has(p.plan)) lues.push(p);
    const s = section('Preuves', pluriel(lues.length, 'fichier', 'fichiers'));
    if (!lues.length) { s.append(VT.etat('aucune-preuve-exigence')); return s; }
    const liste = VT.el('div', 'vf-trace-lignes'), cadre = ph || { n: e.phase, preuves: lues, plans: [] };
    for (const p of lues.slice(0, 30)) {
      const b = VT.el('button', 'vf-trace-ligne', null, { type: 'button', 'data-trace': 'preuve:' + p.fichier }), l2 = p.statut ? VT.T('statut : '
        + p.statut) : '';
      b.append(VT.el('span', 'vf-trace-nom1', VT.libelleProuve(p)), document.createTextNode(' '), VT.el('span', 'vf-trace-st vf-trace-tt', l2,
        { title: p.statut || '' }),
        VT.el('span', 'vf-trace-sr', ' Ouvrir la preuve.'));
      b.addEventListener('click', (ev) => VT.ouvrirListePreuves(cadre, p.fichier, ev.detail === 0, b)); liste.append(b);
    }
    s.append(liste);
    if (lues.length > 30) s.append(VT.plus(['fichier de preuve', 'fichiers de preuve'], lues.length - 30, (clavier) => VT.ouvrirListePreuves(cadre, null,
      clavier)));
    return s;
  };

  VT.exigencePanel = (panel, cle, ligne) => {
    const racine = panel.querySelector('[data-vf-trace-panneau]'), t = racine.querySelector('.pt'), pd = racine.querySelector('.pd');
    t.textContent = ligne.id; t.id = 'vf-trace-exigence-' + String(cle).replace(/[^\w-]/g, '_'); t.setAttribute('data-trace', 'exigence:' + cle);
    pd.textContent = ligne.libelle;
    VT.zone(racine.querySelector('[data-vf-trace-corps]'), {
      cle: 'exigence|' + cle,
      lire: async () => {
        const ex = await VT.lire('exigence', cle), e = ex.exigence;
        const [ph, adr] = await Promise.all([e && e.noeud ? VT.lire('phase', e.noeud).catch(() => null) : null,
          e && (e.decisions.length || e.adrs.length) ? VT.lire('adr').catch(() => null) : null]);
        return { principal: ex, ph, adr };
      },
      rendre: (d, cont) => {
        const e = d.principal.exigence, ph = d.ph ? d.ph.phase : null, kids = [chaine(e), decisions(e, d), preuves(e, d)];
        pd.textContent = e.libelle;
        const mentions = e.mentions.map((m) => NEUTRES[m]).filter(Boolean);
        if (mentions.length) { const s = section('Mentions'); s.append(...mentions.map((m) => VT.el('p', 'vf-trace-note', m))); kids.push(s); }
        const r = section('Rattachement'), nom = ph ? ph.nom : '', b = VT.el('button', 'vf-trace-ligne', null, { type: 'button', 'data-trace': 'phase:'
          + e.noeud });
        b.append(VT.el('span', 'vf-trace-nom1', 'Phase ' + e.phase + (nom ? ', ' + nom : '')));
        b.addEventListener('click', () => VT.allerNoeud('n:' + e.noeud));
        r.append(b, VT.el('p', 'vf-trace-note', VT.T(e.rattachement && e.rattachement !== 'plan' ? 'Ligne du tableau de traçabilité : Phase ' + e.phase
          + ', ' + (e.statut || 'sans statut')
          : 'Rattachée par le champ « requirements » d\'un plan.')));
        kids.push(r);
        if (e.fichier) { const p = VT.el('p', 'vf-trace-pied'); p.append(document.createTextNode('Lu dans '), VT.chemin(e.fichier)); kids.push(p); }
        cont.replaceChildren(...kids);
      },
    }).charger();
  };
})();
