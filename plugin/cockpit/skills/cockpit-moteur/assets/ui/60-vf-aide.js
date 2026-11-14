// VibeFlow (80-15) : l'aide des raccourcis, ouverte par « ? » (FORM-03, P80-D-13). Chaque rangée vient du registre unique VF_RACCOURCIS
// (07-vf-raccourcis.js) : ni libellé ni touche n'est écrit ici, y compris la ligne d'information sur le terminal (P80-D-55).
// Exposé : window.VF_AIDE = Object.freeze({ ouvrir(), fermer(), ouverte() }). La boîte est une modale de la pile VF_SURCOUCHES : piège à Tab,
// inert derrière, focus sur le titre, Échap la ferme et rend le focus à l'ouvreur ; fermée, elle ne laisse aucune entrée dans la pile.
// Script par onglet (A51) : l'écouteur de « ? » est posé dans surOnglet (clé), retiré avec l'onglet ; rien n'est lu au chargement.
(() => {
  const C = window.VF_COQUILLE, SC = window.Floorplan;
  if (!SC || !window.VF_SURCOUCHES) return;
  const LIB = { code: 'Code', projet: 'Projet', equipe: 'Équipe' };
  const ORDRE = ['Partout', 'La carte', 'Projet : couloirs et liste'];
  const GLYPHES = { '←': 'flèche gauche', '↑': 'flèche haut', '↓': 'flèche bas', '→': 'flèche droite' };
  const mac = () => /Mac|iPhone|iPad/.test(navigator.platform || navigator.userAgent || '');
  let boite = null, style = null, ecouteur = null, secours = 'code';
  const onglet = () => {
    const o = window.VF_ONGLETS && window.VF_ONGLETS.courant();
    return LIB[o] ? o : secours;
  };
  const el = (tag, classe, texte) => {
    const e = document.createElement(tag);
    if (classe) e.className = classe;
    if (texte !== undefined) e.textContent = texte;
    return e;
  };
  const touche = (t) => { // une touche : kbd ; les glyphes de flèche portent leur nom parlé
    const k = el('kbd', '', mac() ? t : t.replace('⌘', 'Ctrl '));
    if (GLYPHES[t]) k.setAttribute('aria-label', GLYPHES[t]);
    return k;
  };
  const touches = (texte) => {
    const dd = el('dd', 'vf-aide-t');
    texte.split(' ou ').forEach((alt, i) => {
      if (i) dd.appendChild(el('span', 'vf-aide-ou', 'ou'));
      (alt === '← ↑ ↓ →' ? alt.split(' ') : [alt]).forEach((t) => dd.appendChild(touche(t)));
    });
    return dd;
  };
  const rangee = (e) => {
    const r = el('div', e.info ? 'vf-aide-r vf-aide-info' : 'vf-aide-r');
    r.appendChild(el('dt', '', e.libelle));
    if (e.touche && !e.info) r.appendChild(touches(e.touche));
    return r;
  };
  const groupes = (o) => { // ordre fixe des groupes connus, puis ceux que les extensions ajoutent, dans l'ordre du registre
    const R = window.VF_RACCOURCIS, noms = [], par = new Map();
    for (const e of R ? R.entrees(o) : []) {
      if (!par.has(e.groupe)) { par.set(e.groupe, []); noms.push(e.groupe); }
      par.get(e.groupe).push(e);
    }
    const rang = (n) => (ORDRE.includes(n) ? ORDRE.indexOf(n) : ORDRE.length + noms.indexOf(n));
    return noms.sort((a, b) => rang(a) - rang(b)).map((n) => [n, par.get(n)]);
  };
  const CSS = `
    .vf-aide-modale { position: fixed; z-index: 60; top: 50%; left: 50%; transform: translate(-50%, -50%); box-sizing: border-box;
      width: min(720px, calc(100vw - 32px)); max-height: 80vh; overflow-x: hidden; overflow-y: auto; padding: var(--sp-24);
      background: var(--surface); color: var(--text); border: 1px solid var(--hair-2); border-radius: var(--r-panel);
      box-shadow: var(--shadow-float); }
    .vf-aide-modale:focus, .vf-aide-modale h2:focus { outline: none; }
    .vf-aide-modale h2:focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; }
    .vf-aide-tete { display: flex; align-items: baseline; gap: var(--sp-12); flex-wrap: wrap; margin-bottom: var(--sp-16); }
    .vf-aide-modale h2 { margin: 0; font-size: 18px; font-weight: 600; }
    .vf-aide-vue { color: var(--text-3); font-size: 13px; flex: 1; }
    .vf-aide-fermer { font: inherit; font-size: 13px; color: var(--text); background: var(--raise); border: 1px solid var(--hair-2);
      border-radius: var(--r-ctl); padding: var(--sp-6) var(--sp-12); cursor: pointer; }
    .vf-aide-modale h3 { margin: var(--sp-16) 0 var(--sp-8); font-size: 12px; font-weight: 600; color: var(--text-3); text-transform: none; }
    .vf-aide-modale dl { margin: 0; display: grid; grid-template-columns: minmax(0, 1fr); column-gap: var(--sp-24); }
    .vf-aide-r { display: flex; align-items: center; justify-content: space-between; gap: var(--sp-12); min-height: 32px; min-width: 0; }
    .vf-aide-modale dt { font-size: 13px; color: var(--text-2); min-width: 0; overflow-wrap: anywhere; }
    .vf-aide-modale dd { margin: 0; display: flex; align-items: center; gap: var(--sp-4); flex: none; }
    .vf-aide-modale kbd { font-family: var(--mono); font-size: 11px; line-height: 20px; padding: 0 var(--sp-6); color: var(--text-2);
      border: 1px solid var(--hair-2); border-radius: 8px; white-space: nowrap; }
    .vf-aide-ou { font-size: 11px; color: var(--text-4); }
    .vf-aide-info dt { color: var(--text-3); }
    .vf-aide-pied { margin: var(--sp-16) 0 0; padding-top: var(--sp-12); border-top: 1px solid var(--hair); font-size: 12px; color: var(--text-3); }
    @media (min-width: 600px) { .vf-aide-modale dl { grid-template-columns: repeat(2, minmax(0, 1fr)); } }`;
  const construire = (o) => {
    const b = el('div', 'vf-aide-modale'), tete = el('div', 'vf-aide-tete'), h2 = el('h2', '', 'Raccourcis clavier'),
      fermer = el('button', 'vf-aide-fermer', 'Fermer');
    b.setAttribute('role', 'dialog'); b.setAttribute('aria-modal', 'true'); b.setAttribute('aria-labelledby', 'vf-aide-titre');
    h2.id = 'vf-aide-titre'; h2.tabIndex = -1; fermer.type = 'button'; fermer.addEventListener('click', () => api.fermer());
    tete.append(h2, el('span', 'vf-aide-vue', 'Vue : ' + LIB[o]), fermer); b.appendChild(tete);
    for (const [nom, liste] of groupes(o)) {
      const dl = el('dl'); b.appendChild(el('h3', '', nom));
      liste.forEach((e) => dl.appendChild(rangee(e))); b.appendChild(dl);
    }
    b.appendChild(el('p', 'vf-aide-pied', 'Tout est aussi dans la palette : ' + (mac() ? '⌘K' : 'Ctrl K') + ' ou /.'));
    return b;
  };
  const api = {
    ouvrir() {
      if (boite) return;
      const actif = document.activeElement, p = document.getElementById('palette');
      const ouvreur = actif && actif !== document.body && !(p && p.contains(actif)) ? actif : null;
      if (!style) { style = el('style', '', CSS); document.head.appendChild(style); }
      boite = construire(onglet()); document.body.appendChild(boite);
      window.VF_SURCOUCHES.ouvrir(boite, { modale: true, ouvreur, fermer: () => api.fermer() });
      boite.querySelector('h2').focus({ preventScroll: true });
    },
    fermer() {
      if (!boite) return;
      const b = boite; boite = null;
      window.VF_SURCOUCHES.fermer(b); b.remove();
    },
    ouverte: () => !!boite };
  window.VF_AIDE = Object.freeze(api);

  if (C && typeof C.surOnglet === 'function') {
    C.surOnglet(({ onglet: o }) => {
      if (LIB[o]) secours = o;
      if (ecouteur) document.removeEventListener('keydown', ecouteur); // un rappel rejoué ne double jamais l'écouteur
      ecouteur = (ev) => { // « ? » seul : ni champ de saisie, ni ⌘, Ctrl ou Alt (P80-D-12)
        if (ev.key !== '?' || ev.defaultPrevented || ev.metaKey || ev.ctrlKey || ev.altKey || SC.enSaisie(ev) || boite) return;
        ev.preventDefault(); api.ouvrir();
      };
      document.addEventListener('keydown', ecouteur);
      return () => {
        document.removeEventListener('keydown', ecouteur); ecouteur = null;
        api.fermer(); if (style) { style.remove(); style = null; }
      };
    }, { cle: '60-vf-aide.js' });
  }
})();
