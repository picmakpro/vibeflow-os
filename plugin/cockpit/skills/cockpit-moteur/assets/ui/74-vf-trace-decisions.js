// VibeFlow (76-07) : décisions de la traçabilité (UI-SPEC § 4.2, § 5.2, § 5.5) : section « Décisions » de la vue d'ensemble, panneau d'une ADR,
// ligne de commit.
// Chargé avant 74-vf-trace.js : ne déclare que des briques dans window.VFTrace, appelées plus tard ; les ouvreurs se posent par `VT.poseDecisions`, que
// 74-vf-trace.js appelle. Tout texte du lab est posé en textContent (P76-D-11) ; toute ouverture passe par ouvrirSurMesure ou allerNoeud (aucune pile propre).
(() => {
  const VT = (window.VFTrace = window.VFTrace || {});
  const ouvert = { decisions: false }; // l'état d'un repli est tenu ici et restauré à chaque rendu
  const BORNE = 'Lecture bornée : la liste peut être incomplète. Une lecture plus courte, ou moins de commits, la lèverait.';
  const GAB = (kind) => '<div class="vf-trace" data-vf-trace-panneau><div class="ph"><span class="kindlabel">' + kind
    + '</span></div><h2 class="pt" tabindex="-1"></h2><p class="pd"></p><div data-vf-trace-corps></div></div>';
  const fr = new Intl.DateTimeFormat('fr-FR', { day: 'numeric', month: 'short', year: 'numeric', timeZone: 'UTC' });
  VT.jourFr = (j) => { const d = /^\d{4}-\d{2}-\d{2}$/.test(String(j)) ? new Date(j + 'T00:00:00Z') : null; return d && !isNaN(d) ? fr.format(d) : ''; };
  const phrase = (t) => VT.el('p', 'vf-trace-etat', VT.T(t));
  const pluriel = (n, un, plu) => VT.N(n) + ' ' + VT.P(n, un, plu);
  VT.sec = (titre, compte) => {
    const s = VT.el('div', 'sec'), h = VT.el('h3', null, titre);
    if (compte) h.append(document.createTextNode(' '), VT.el('span', 'c', VT.T(compte)));
    s.append(h); return s;
  };
  // une ligne de voisin : bouton, identifiant mono puis titre, sans glyphe ; son nom accessible dit ce qu'elle ouvre
  VT.ligneVoisin = (id, titre, trace, nom, ouvrir) => {
    const b = VT.el('button', 'vf-trace-ligne', null, { type: 'button', 'data-trace': trace }), l1 = VT.el('span', 'vf-trace-l1');
    l1.append(VT.el('span', 'vf-trace-id', id), VT.el('span', 'vf-trace-tt', titre || '', { title: titre || '' }));
    b.append(l1, VT.el('span', 'vf-trace-sr', VT.T(nom)));
    b.addEventListener('click', (ev) => ouvrir(ev.detail === 0, b)); return b;
  };
  // au plus 30 lignes d'une sorte, puis « + N autres <sorte> » qui ouvre la liste paginée ; `extra` : avant, apres de ouvrirListe
  VT.liste30 = (els, sorte, rendre, titreListe, extra = {}) => {
    const l = VT.el('div', 'vf-trace-lignes'), k = [l]; l.append(...els.slice(0, 30).map((e) => rendre(e)));
    if (els.length > 30) k.push(VT.plus(sorte, els.length - 30, (clavier) => VT.ouvrirListe({ titre: titreListe, sorte, elements: els, rendreLigne: rendre,
      clavier, ...extra })));
    return k;
  };
  VT.borne = () => VT.el('p', 'vf-trace-borne', VT.T(BORNE));
  VT.pied = (chemin) => { const p = VT.el('p', 'vf-trace-pied'); p.append(document.createTextNode('Lu dans '), VT.chemin(chemin)); return p; };
  // panneau d'objet : titre, ancre par objet, zone lue par la route ; rendre(d, cont, { t, p }) remplit le corps
  VT.panneauObjet = (panel, { vue, cle, titre, lire, rendre }) => {
    const r = panel.querySelector('[data-vf-trace-panneau]'), t = r.querySelector('.pt'), p = r.querySelector('.pd');
    t.textContent = titre; t.id = 'vf-trace-' + vue + '-' + String(cle).replace(/[^\w-]/g, '_'); t.setAttribute('data-trace', vue + ':' + cle); p.hidden = true;
    VT.zone(r.querySelector('[data-vf-trace-corps]'), { cle: vue + '|' + cle, lire, rendre: (d, cont) => rendre(d, cont, { t, p }) }).charger();
  };
  VT.gabarit = GAB;

  // ligne de commit (§ 5.5) : sha court, jour français, sujet ; un bouton si le tiroir Git existe, du texte sinon
  VT.ligneCommit = (c) => {
    const T = window.VFGitTiroir, actif = !!(T && typeof T.ouvrir === 'function'), jour = VT.jourFr(c.jour);
    const nom = 'Commit ' + c.h7 + ', ' + jour + ', ' + c.sujet + ". Ouvrir dans l'historique Git.";
    const e = VT.el(actif ? 'button' : 'div', 'vf-trace-commit' + (actif ? ' vf-trace-ligne' : ''), null,
      actif ? { type: 'button', 'aria-label': nom, 'data-trace': 'commit:' + c.h7 } : { 'data-trace': 'commit:' + c.h7 });
    const l1 = VT.el('span', 'vf-trace-c1'); l1.append(VT.el('span', 'vf-trace-id', c.h7), document.createTextNode(' '), VT.el('span', 'vf-trace-jour', jour));
    e.append(l1, VT.el('span', 'vf-trace-sujet', c.sujet, { title: c.sujet }));
    if (actif) e.addEventListener('click', () => {
      const G = window.VFGitTiroir;
      if (!G) return;
      if (typeof G.ouvrirSur !== 'function') { G.ouvrir(); return; }
      Promise.resolve(G.ouvrirSur(c.h7)).then((ok) => { if (!ok && !(G.ouvert && G.ouvert())) G.ouvrir(); }, () => G.ouvrir());
    });
    return e;
  };
  // « Commits qui la citent » : la route ne sert jamais le corps du message ; une liste bornée le dit au-dessus d'elle
  VT.sectionCommits = (d, id) => {
    const cs = d.commits || [], s = VT.sec('Commits qui la citent', pluriel(cs.length, 'commit', 'commits'));
    const tronque = !!(d.bornes && d.bornes.tronque);
    if (d.absences && d.absences.git) {
      s.append(phrase("Git n'est pas disponible : les commits qui citent cet objet ne sont pas lus. Un dépôt git les rend lisibles.")); return s;
    }
    if (tronque) s.append(VT.borne());
    if (!cs.length) s.append(phrase('Aucun commit ne cite cet objet. Un message de commit qui nomme son identifiant le relierait.'));
    else s.append(...VT.liste30(cs, ['commit', 'commits'], VT.ligneCommit, id, { avant: () => (tronque ? [VT.borne()] : []) }));
    return s;
  };

  // panneau d'une ADR (§ 5.2) : décisions qui la citent, commits qui la citent, pied « Lu dans docs/ADR.md »
  VT.ouvrirAdr = (cle, { clavier, depuis } = {}) => VT.ouvrirSurMesure({ html: GAB('ADR'), titre: cle, clavier, depuis,
    bind: (panel) => VT.panneauObjet(panel, {
    vue: 'adr', cle, titre: cle, lire: () => VT.lire('adr', cle).then((p) => ({ principal: p })),
    rendre: (d, cont, { p }) => {
      const r = d.principal, a = r.adr, kids = [], dec = a.decisions || [];
      p.textContent = a.titre || ''; p.hidden = !a.titre;
      if (dec.length) {
        const s = VT.sec('Décisions qui la citent', pluriel(dec.length, 'décision', 'décisions'));
        s.append(...VT.liste30(dec, ['décision', 'décisions'], (x) => VT.ligneVoisin(x.id, x.titre, 'decision:' + x.cle, 'Décision ' + x.id + ', ' + x.titre
          + '. Ouvrir la décision.', (kb, b) => VT.ouvrir('decision', x.cle, { clavier: kb, depuis: b })), "Décisions de l'ADR " + cle));
        kids.push(s);
      }
      kids.push(VT.sectionCommits(r, "Commits de l'ADR " + cle), VT.pied('docs/ADR.md'));
      cont.replaceChildren(...kids);
    } }) });

  // section « Décisions » de la vue d'ensemble (§ 4.2) : un bilan fermé, une ligne par ADR (≤ 30)
  const rendreSection = (p, cont, compte) => {
    const adrs = p.adrs.filter((a) => a.cle), regs = p.registres || [], nd = regs.reduce((n, r) => n + r.decisions.length, 0);
    compte.textContent = VT.T(pluriel(adrs.length, 'ADR', 'ADR'));
    const kids = [VT.el('p', 'vf-trace-bilan vf-trace-bilan-2', VT.T(pluriel(adrs.length, 'ADR', 'ADR') + ' · ' + pluriel(nd, 'décision', 'décisions')
      + ' · ' + pluriel(regs.length, 'registre de phase', 'registres de phase')))];
    if (p.absences && p.absences.adr) kids.push(phrase('Pas de docs/ADR.md dans ce dossier. Les sections ADR-NNN de ce fichier apparaîtraient ici.'));
    else {
      kids.push(...VT.liste30(adrs, ['ADR', 'ADR'], (a) => VT.ligneVoisin(a.id, a.titre, 'adr:' + a.id, a.id + ', ' + a.titre + ". Ouvrir l'ADR.",
        (kb, b) => VT.ouvrir('adr', a.cle, { clavier: kb, depuis: b })), 'ADR'));
    }
    cont.replaceChildren(...kids);
  };
  VT.sectionDecisions = (SC, vivant) => {
    SC.addPanelSection('overview', () => {
      if (!vivant()) return '';
      return { html: '<div class="sec vf-trace"><details class="vf-trace-repli" data-vf-trace-decisions><summary class="vf-trace-sec-t">Décisions '
        + '<span class="c"></span></summary><div data-vf-trace-corps></div></details></div>',
      bind: (racine) => {
        const d = racine.querySelector('details'), compte = racine.querySelector('summary .c');
        const z = VT.zone(racine.querySelector('[data-vf-trace-corps]'), { cle: 'adr|', ouvert: () => d.open,
          lire: () => VT.lire('adr').then((p) => ({ principal: p })), rendre: (r, cont) => rendreSection(r.principal, cont, compte) });
        d.open = ouvert.decisions; d.addEventListener('toggle', () => { ouvert.decisions = d.open; if (d.open) z.charger(); });
        if (d.open) z.charger();
      } };
    });
  };
  VT.poseDecisions = (O) => { O.adr = VT.ouvrirAdr; };
})();
