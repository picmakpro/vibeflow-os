// VibeFlow (80-06) : volet bas du tiroir Git — l'enveloppe du détail d'un commit (P80-D-19, FORM-13), jamais sous la rangée.
// Exposé : window.VFGitVolet = { ouvrir(sha, rangee) -> Promise<boolean>, fermer(focus), ouvert(), sha(), lier(), brancher(contenu) }.
// Le contenu (GET /api/vf/git/commit?sha=, rendu en textContent) vient de 77-vf-git-vue-detail.js par brancher(contenu(zone, sha, vivant)).
// `ouvrir` remplace le volet présent : jamais deux `.vf-git-detail`. Un sha hors motif : « Indisponible » local, aucune requête, false.
(() => {
  const R = window.VFGitRendu;
  if (!R) return; // sans dépôt, le tiroir n'existe pas
  const el = R.el;
  let courant = null, seq = 0, volet = null, zone = null, contenu = null;

  const style = document.createElement('style');
  style.textContent = `
    .vf-git-detail { flex: none; display: flex; flex-direction: column; min-height: 0; height: clamp(192px, 35%, 256px);
      padding: 0 16px 12px; border-top: 1px solid var(--hair); }
    .vf-git-det-barre { flex: none; display: flex; align-items: center; gap: 8px; height: 36px; font-size: 12.5px; color: var(--text-3); }
    .vf-git-det { flex: 1; min-height: 0; overflow-y: auto; display: flex; flex-direction: column; gap: 8px; padding: 12px;
      border-radius: var(--r-ctl); background: var(--raise); }
    @media (max-width: 999px), (pointer: coarse) { .vf-git-detail { height: clamp(160px, 45%, 320px); } }
  `;

  const tiroir = () => document.querySelector('#vf-git-tiroir');
  const lignes = () => [...document.querySelectorAll('#vf-git-tiroir li[role=option]')];
  const rangeDe = (sha) => lignes().find((l) => l.dataset.h === sha) || null;
  const lier = () => { // aria-controls sur la rangée du commit ouvert, quand elle est rendue
    for (const l of lignes()) l.removeAttribute('aria-controls');
    const r = courant && zone && rangeDe(courant);
    if (r) r.setAttribute('aria-controls', zone.id);
  };
  const monter = (sha) => {
    const T = tiroir(); if (!T) return null;
    for (const d of T.querySelectorAll('.vf-git-detail')) d.remove(); // un seul volet, même si l'appelant n'a pas fermé le précédent
    const barre = el('div', 'vf-git-det-barre'), f = el('button', 'vf-git-fermer', null, { type: 'button', 'aria-label': 'Fermer le détail' });
    const titre = el('span', null, 'Détail du commit ' + sha.slice(0, 7));
    f.appendChild(R.ico('M6 6l12 12M18 6L6 18'));
    barre.append(titre, f);
    zone = el('div', 'vf-git-det', null, { role: 'region', id: 'vf-git-detail-' + sha.slice(0, 7), 'aria-label': 'Détail du commit ' + sha.slice(0, 7) });
    volet = el('div', 'vf-git-detail'); volet.append(barre, zone);
    f.addEventListener('click', () => fermer(true));
    volet.addEventListener('keydown', (e) => { // cran 4 de la pile : le volet se ferme avant le tiroir (cran 5)
      if (e.key === 'Escape') { e.preventDefault(); e.stopPropagation(); fermer(true); }
    });
    T.insertBefore(volet, T.querySelector('.vf-git-live'));
    return zone;
  };
  const ouvrir = (sha, rangee) => {
    if (typeof sha !== 'string' || !contenu) return Promise.resolve(false);
    const moi = ++seq, z = monter(sha);
    if (!z) return Promise.resolve(false);
    courant = sha; lier(); void rangee;
    return Promise.resolve(contenu(z, sha, () => moi === seq && z.isConnected)).then((ok) => ok === true, () => false);
  };
  const fermer = (focus) => { // focus === true : le focus revient à la rangée du commit, à défaut au titre du tiroir
    const sha = courant, T = tiroir(); seq++; courant = null; volet = null; zone = null;
    for (const d of document.querySelectorAll('#vf-git-tiroir .vf-git-detail')) d.remove();
    for (const l of lignes()) l.removeAttribute('aria-controls');
    if (focus === true && sha) { // la rangée si elle est visible (section repliée : non), à défaut le titre du tiroir
      const r = rangeDe(sha), c = r && r.getClientRects().length ? r : T && T.querySelector('.vf-git-titre-t');
      if (c) c.focus({ preventScroll: false });
    }
  };
  // fermé, le volet quitte le DOM (`.vf-git-detail` : 0)
  const brancher = (f) => { if (typeof f === 'function') contenu = f; };
  window.VFGitVolet = Object.freeze({ ouvrir, fermer, ouvert: () => courant !== null, sha: () => courant, lier, brancher });
  const globaux = () => { document.head.appendChild(style); return () => { style.remove(); fermer(); }; }; // A51 : la feuille, et le volet avec l'onglet
  const C = window.VF_COQUILLE;
  if (C && typeof C.surOnglet === 'function') C.surOnglet(globaux, { cle: '77-vf-git-volet.js' }); else globaux();
})();
