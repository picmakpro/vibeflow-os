// VibeFlow (80-21) : dire l'échec d'un chargement d'onglet (FORM-16, 80-UI-SPEC § 5 et § 7), un seul texte pour les trois onglets : celui de la coquille.
// vf-coquille: persistant
// La coquille signale chaque échec de lecture par `vf:coquille-echec` (annulable ; detail { onglet, initial }) et par VF_COQUILLE.etat(). Ce script écoute
// l'évènement, l'annule (jamais deux messages) puis : sans onglet affiché (`initial`), pose une boîte « Lecture impossible » dont « Réessayer » prend le
// focus ; avec un onglet affiché, annonce l'échec (VF_ONGLETS.annoncer) et laisse la palette et la ligne d'état offrir « Réessayer ».
// Évaluation : l'objet gelé, UNE écoute de document et UNE inscription surOnglet (la boîte et sa feuille de style s'en vont à toute arrivée, par ce
// script ou par un autre) ; ni style, ni nœud (posés au premier `montrer`), aucune lecture du moteur ; rien n'est gardé ici, l'échec se lit dans
// VF_COQUILLE.etat(). Texte posé par textContent seulement ; jamais le message de rejet ni le corps de la réponse (T-80-63).
(() => {
  if (window.VF_ONGLETS_ECHEC) return;
  const TEXTE = 'Lecture impossible : les données de cet onglet n\'ont pas pu être lues.';
  const LIBELLE = { code: 'Code', projet: 'Projet', equipe: 'Équipe' };
  const ID = 'vf-onglets-echec', ID_STYLE = 'vf-onglets-echec-style';
  const STYLE = `
    #${ID} { position: absolute; inset: 0; display: flex; align-items: center; justify-content: center; padding: var(--sp-24); pointer-events: none; }
    #${ID} .vf-oe-b { pointer-events: auto; display: flex; flex-direction: column; align-items: center; gap: var(--sp-12); max-width: 420px;
      padding: var(--inset-box); border-radius: var(--r-ctl); text-align: center; color: var(--text);
      background: linear-gradient(var(--warn-bg), var(--warn-bg)), var(--surface); }
    #${ID} .vf-oe-g { display: inline-flex; align-items: center; justify-content: center; width: 20px; height: 20px; border-radius: 999px;
      font-weight: 600; font-size: 13px; color: var(--text-2); box-shadow: inset 0 0 0 1.5px var(--text-3); }
    #${ID} p { margin: 0; font-size: 13px; line-height: 20px; }
    #${ID} button { min-width: 44px; min-height: 44px; padding: 0 var(--sp-16); border: 0; border-radius: var(--r-ctl); cursor: pointer;
      font: inherit; font-weight: 500; color: var(--text); background: rgba(var(--ink), .08); }
    #${ID} button:hover { background: rgba(var(--ink), .12); }
    #${ID} button:focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; }
    /* le gabarit brut (libellés anglais, dictionnaire non chargé, panneau sans contenu) ne dit rien : seul le nom du projet reste */
    #panel, #panel-resize, #ask, #zoom, #context, #loading, #flowbar, header .hc, header .hr, header #btn-up, header #crumbs { display: none !important; }
  `;
  const noeud = (balise, classe, texte) => {
    const n = document.createElement(balise);
    if (classe) n.className = classe;
    if (texte !== undefined) n.textContent = texte;
    return n;
  };
  const retirer = () => {
    for (const id of [ID, ID_STYLE]) { const n = document.getElementById(id); if (n) n.remove(); }
  };
  // la boîte autonome : dans la zone du canevas du gabarit (#stage), à défaut dans le corps ; « Réessayer » reçoit le focus
  const montrer = ({ texte, reessayer }) => {
    retirer();
    const s = noeud('style'); s.id = ID_STYLE; s.textContent = STYLE; document.head.appendChild(s);
    const boite = noeud('div'), corps = noeud('div', 'vf-oe-b'), b = noeud('button', '', 'Réessayer');
    boite.id = ID; boite.setAttribute('role', 'status');
    const g = noeud('span', 'vf-oe-g', '!'); g.setAttribute('aria-hidden', 'true');
    b.type = 'button';
    b.addEventListener('click', () => { retirer(); if (typeof reessayer === 'function') reessayer(); });
    corps.append(g, noeud('p', '', texte), b); boite.appendChild(corps);
    (document.getElementById('stage') || document.body).appendChild(boite);
    b.focus({ preventScroll: true });
  };
  const relancer = () => { const V = window.VF_ONGLETS; if (V && typeof V.reessayer === 'function') V.reessayer().catch(() => {}); };

  document.addEventListener('vf:coquille-echec', (ev) => {
    ev.preventDefault(); // la coquille ne pose pas son texte de repli : celui-ci est le seul message
    const d = ev.detail || {}, C = window.VF_COQUILLE, V = window.VF_ONGLETS;
    if (d.initial) { montrer({ texte: TEXTE, reessayer: relancer }); return; }
    const a = C && typeof C.onglet === 'function' ? C.onglet() : null;
    if (V && typeof V.annoncer === 'function') V.annoncer(a && LIBELLE[a] ? `${TEXTE} L'onglet ${LIBELLE[a]} reste affiché.` : TEXTE);
  });

  const K = window.VF_COQUILLE;
  if (K && typeof K.surOnglet === 'function') K.surOnglet(() => { retirer(); }, { cle: '00-vf-onglets-echec.js' });
  window.VF_ONGLETS_ECHEC = Object.freeze({ montrer, retirer });
})();
