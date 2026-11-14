// VibeFlow (75-08, ACTV-01, P75-D-02) : le sélecteur de lentilles et le moteur de la phase côté page. Il s'initialise par VF_COQUILLE.surOnglet quand
// l'onglet vaut Code et se retire entièrement quand on le quitte (bouton, menu, marques, compte, écouteurs, minuteries ; jamais `#ask-live`, qui
// n'est pas à la 75).
// La donnée vient de GET /api/vf/activite (VF_ETAT.lireJson), relue à chaque événement `frise`, `git` ou `planning` et, tant que `calcul` vaut
// `en-cours`, une fois par seconde au plus 15 fois : AUCUN sondage permanent. Les marques passent par le canal figé VF_MARQUES (75-07) :
//   `activite` (couche exclusive : la lentille) et `activite-collisions` (couche non exclusive : le radar). Rien n'est mémorisé : « Aucune » à chaque
// ouverture.
// Les fichiers voisins (menu, panneau, collisions) se branchent par window.VF_ACTIVITE.brancher(nom, fabrique) ; ils ont chacun leur inscription de
// coquille.
(() => {
  'use strict';
  const CLE = '75-vf-activite.js', ROUTE = '/api/vf/activite', SCHEMA = 'vibeflow/cockpit-activite@1', MAX_RELECTURES = 15, ID = 'vfa-style';
  // cercle, arc de reflet (trait de .btn svg.i) et disque central : plein (r = 3) quand une lentille est active, absent (r = 0) sinon :
  // le signe de l'état actif, distinct du survol
  const LENTILLE = '<circle cx="12" cy="12" r="8"/><path d="M8.5 10a4 4 0 0 1 3-2.5"/>'
    + '<circle class="vfa-i" cx="12" cy="12" r="0" fill="currentColor" stroke="none"/>';
  // l'état actif : le libellé `.bl` le dit, ce fond neutre est celui du survol ; bouton carré (budget de l'en-tête à 1 024 px) dont la pastille se pose en coin
  const CSS = `#btn-lentilles.vfa-actif { background: rgba(var(--ink), .07); }
    #btn-lentilles { position: relative; }
    #btn-lentilles .bl { display: none; } /* le libellé suit la lentille : visible (1 600 px et plus), il ferait bouger l'en-tête ; le « ⋯ » le lit */
    #btn-lentilles .badge { position: absolute; top: var(--sp-4); right: var(--sp-2); }
    @media (min-width: 1000px) and (max-width: 1279px) { /* à 1 024 px l'en-tête n'a aucune marge : le bouton prend l'écart de son voisin */
      #vfa-rel { margin-left: calc(-1 * var(--sp-4)); } }`;
  const parties = new Map(); // nom -> { fabrique, inst }
  let session = null; // la session de l'onglet Code, ou null

  const demarrerPartie = (p) => {
    try { p.inst = p.fabrique(session.ctx); if (session.etat.m && p.inst.maj) p.inst.maj(session.etat.m);
      } catch (e) { console.error('VibeFlow activité : ' + (e && e.message)); p.inst = null; }
  };
  const brancher = (nom, fabrique) => {
    const p = { fabrique, inst: null };
    parties.set(nom, p);
    if (session) demarrerPartie(p);
    return () => { if (parties.get(nom) === p) parties.delete(nom); if (p.inst) { try { p.inst.detruire(); } catch { /* déjà défait */ } p.inst = null; } };
  };

  const demarrer = () => {
    const M = window.VibeFlow || window.Floorplan, E = window.VF_ETAT, T = window.VF_ACTIVITE_TABLES, S = window.VF_SURCOUCHES, MQ = window.VF_MARQUES;
    const hdr = document.getElementById('hdr-ext');
    if (!M || !E || !T || !MQ || !hdr || typeof M.addHeaderButton !== 'function') return () => {};
    const etat = { d: null, conn: E.lire('connexion'), lentille: 'aucune', filtre: null, sel: null, m: null, vivant: true };
    const minuteries = new Set(), offs = [], vus = { activite: '', collisions: '' };
    const fichiers = new Map();
    for (const f of (M.graph && M.graph.files) || []) if (f && typeof f.p === 'string') fichiers.set(f.p, f);
    const chain = (id) => { try { const c = M.chain(id); return Array.isArray(c) ? c : []; } catch { return []; } };
    const vue = () => ({
      fichier: (p) => fichiers.get(p) || null, existe: (id) => !!M.exists(id), selection: etat.sel,
      visible: (id) => !!(M.state && M.state.chipEls && M.state.chipEls.has(id)),
      ancetres: (id) => chain(id).filter((a) => typeof a === 'string' && a !== id && a !== 'root'),
    });
    const annoncer = (texte) => { const z = document.getElementById('ask-live'); if (z) z.textContent = texte; };
    const apres = (ms, f) => { const t = setTimeout(() => { minuteries.delete(t); if (etat.vivant) f(); }, ms); minuteries.add(t); return t; };

    const style = document.createElement('style');
    style.id = ID; style.textContent = CSS; document.head.appendChild(style);
    const racine = document.createElement('div');
    racine.className = 'rel'; racine.id = 'vfa-rel';
    const bouton = M.addHeaderButton({ id: 'btn-lentilles', label: T.F.bouton('Aucune'), svg: LENTILLE, title: T.TEXTES.infobulle,
      onClick: () => { const p = parties.get('menu'); if (p && p.inst) p.inst.basculer(); } });
    bouton.classList.add('icon'); // carré : l'étiquette `.bl` reste (le « ⋯ » la lit), l'en-tête garde son budget
    bouton.setAttribute('aria-haspopup', 'menu'); bouton.setAttribute('aria-expanded', 'false');
    racine.appendChild(bouton);
    const sante = document.getElementById('btn-health'); // le créneau : juste après Santé, avant « Par où commencer »
    if (sante && sante.parentNode === hdr) sante.after(racine); else hdr.appendChild(racine);

    const majBouton = (m) => {
      const bl = bouton.querySelector('.bl');
      if (bl) bl.textContent = m.bouton.libelle;
      bouton.setAttribute('aria-label', m.bouton.aria);
      bouton.classList.toggle('vfa-actif', m.lentille !== 'aucune');
      const disque = bouton.querySelector('.vfa-i');
      if (disque) disque.setAttribute('r', m.lentille === 'aucune' ? '0' : '3');
      let b = bouton.querySelector('.badge');
      if (m.pastille > 0) { if (!b) { b = document.createElement('span'); b.className = 'badge'; bouton.appendChild(b);
        } b.textContent = String(m.pastille); b.setAttribute('aria-hidden', 'true'); } else if (b) b.remove();
    };
    const poser = (nom, cle, rows, exclusif) => { // une couche n'est reposée que si sa table a changé
      const sig = JSON.stringify(rows);
      if (sig === vus[cle]) return;
      vus[cle] = sig;
      if (rows.length === 0) MQ.retirer(nom); else MQ.poser(nom, rows, { exclusif });
    };
    const calculer = () => {
      if (!etat.vivant) return;
      const v = vue(), m = T.modele({ d: etat.d, conn: etat.conn, lentille: etat.lentille, filtre: etat.filtre, vue: v });
      const avant = etat.m;
      etat.m = m; etat.lentille = m.lentille;
      // le filtre ne vit que sur Empreinte, avec un rattachement
      if (etat.filtre && !m.agents.includes(etat.filtre)) { etat.filtre = null; calculer(); return; }
      poser('activite', 'activite', m.lentille === 'aucune' || m.indispo ? [] : m.rows, true);
      poser('activite-collisions', 'collisions', etat.d ? T.tableCollisions(etat.d, v) : [], false);
      majBouton(m);
      if (avant && !avant.indispo && m.indispo) annoncer(m.annonce); // la lentille active devient indisponible : « Lentille Points chauds indisponible. »
      for (const p of parties.values()) if (p.inst && p.inst.maj) p.inst.maj(m);
    };

    // le palier de Points chauds est aussi dit par le texte : le canal réécrit le nom accessible de la carte à chaque passage, on y revient après lui
    const appliquerPaliers = () => {
      const cs = M.state && M.state.chipEls;
      if (!etat.m || etat.m.lentille !== 'chauds' || !(cs instanceof Map)) return;
      for (const r of etat.m.rows) {
        const g = cs.get(r[0]), a = g && g.getAttribute('aria-label'), mot = r[3], ajout = `${mot}, palier ${r[1]}`, i = a ? a.indexOf(mot) : -1;
        if (i >= 0 && !a.includes(ajout) && r[0].startsWith('f:')) g.setAttribute('aria-label', a.slice(0, i) + ajout + a.slice(i + mot.length));
      }
    };
    const vp = document.getElementById('viewport'), noms = new MutationObserver(appliquerPaliers);
    if (vp) noms.observe(vp, { attributes: true, attributeFilter: ['aria-label'], subtree: true });

    // la lecture : une requête en vol à la fois, une relance au plus ; jamais de sondage hors d'un calcul en cours (15 relectures, une par seconde)
    let envol = false, rattrape = false, essais = 0, minut = null;
    const lire = () => {
      if (!etat.vivant) return;
      if (envol) { rattrape = true; return; }
      envol = true; rattrape = false;
      E.lireJson(ROUTE).then((j) => {
        if (!etat.vivant || !j || j.schema !== SCHEMA) return;
        etat.d = j; calculer();
        if (minut) { clearTimeout(minut); minuteries.delete(minut); minut = null; }
        if (j.calcul === 'en-cours' && essais < MAX_RELECTURES) { essais++; minut = apres(1000, lire); } else if (j.calcul !== 'en-cours') essais = 0;
      }, () => {}).then(() => { envol = false; if (rattrape && etat.vivant) lire(); });
    };
    const relire = () => { essais = 0; lire(); };
    for (const cle of ['frise', 'git', 'planning']) offs.push(E.abonner(cle, relire));
    offs.push(E.abonner('connexion', (c) => { etat.conn = c; calculer(); if (c === 'ouvert') relire(); }));

    // la sélection : seul le couplage en dépend ; l'annonce de couplage est retardée de 300 ms (la sélection suivante la remplace)
    const idSel = (s) => (typeof s !== 'string' ? null : s.startsWith('m:') ? 'f:' + s.slice(2) : s);
    let annonceSel = null;
    const surSelection = () => {
      const s = idSel(M.state && M.state.selected);
      if (s === etat.sel) return;
      etat.sel = s; calculer();
      if (annonceSel) { clearTimeout(annonceSel); minuteries.delete(annonceSel); annonceSel = null; }
      if (etat.lentille === 'couplage' && s && s.startsWith('f:') && etat.m.rows.length) {
        annonceSel = apres(300, () => annoncer(T.F.annonceCouplage(etat.m.rows.length - 1)));
      }
    };
    M.on('panel', () => { if (etat.vivant) surSelection(); });
    M.on('render', () => { if (etat.vivant && etat.lentille === 'couplage') calculer(); });
    etat.sel = idSel(M.state && M.state.selected);

    const ctx = { M, T, E, S, MQ, bouton, racine, annoncer, apres, vue, partage: {}, filtre: () => etat.filtre, modele: () => etat.m,
      donnees: () => etat.d, conn: () => etat.conn,
      choisir: (id) => { etat.lentille = id; calculer(); annoncer(etat.m.annonce); },
      filtrer: (nom) => { etat.filtre = nom; calculer(); } };
    session = { ctx, etat };
    for (const p of parties.values()) demarrerPartie(p);
    calculer(); lire();

    return () => { // l'onglet change : tout ce qui est posé ici s'en va
      etat.vivant = false;
      for (const t of minuteries) clearTimeout(t);
      minuteries.clear();
      for (const o of offs) o();
      noms.disconnect();
      for (const p of [...parties.values()].reverse()) if (p.inst) { try { p.inst.detruire(); } catch { /* déjà défait */ } p.inst = null; }
      MQ.retirer('activite'); MQ.retirer('activite-collisions');
      racine.remove(); style.remove(); session = null;
    };
  };

  window.VF_ACTIVITE = Object.freeze({ brancher });
  const arrivee = (ev) => (!ev || ev.onglet !== 'code' ? () => {} : demarrer());
  if (window.VF_COQUILLE && typeof window.VF_COQUILLE.surOnglet === 'function') window.VF_COQUILLE.surOnglet(arrivee, { cle: CLE });
})();
