// VibeFlow (80-21) : la rangée « Lecture impossible · Réessayer » du bloc #vf-coin, tant qu'un changement d'onglet en échec laisse l'onglet affiché
// (FORM-16, 80-UI-SPEC § 5). Le bloc n'existe qu'à partir de 1000 px : sous cette largeur l'annonce et la palette suffisent. Extension d'onglet (A51) :
// tout est posé dans le rappel de VF_COQUILLE.surOnglet et défait par la fonction rendue. Aucune requête : le bouton appelle VF_ONGLETS.reessayer.
// Texte posé par textContent seulement ; l'échec se lit dans VF_ONGLETS.echec() (rien n'est gardé ici). La zone d'appui de 44 est le pseudo-élément du
// bouton. 02-vf-coin.js et 02-vf-ligne-etat.js ne bougent pas.
(() => {
  const K = window.VF_COQUILLE;
  if (!K || typeof K.surOnglet !== 'function') return;
  const STYLE = `
    .vf-ech { display: flex; align-items: center; gap: var(--sp-4); min-height: 16px; font-size: 11px; line-height: 16px;
      color: var(--text-2); white-space: nowrap; }
    .vf-ech + .vf-ls, .vf-ls + .vf-ech { margin-top: var(--sp-4); }
    .vf-ech button { position: relative; padding: 0; border: 0; background: none; font: inherit; font-weight: 500; color: var(--text); cursor: pointer;
      text-decoration: underline; text-underline-offset: 2px; }
    .vf-ech button::after { content: ""; position: absolute; inset: -14px -12px; }
    .vf-ech button:focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; border-radius: 2px; }
  `;
  K.surOnglet(() => {
    const slot = document.getElementById('vf-coin-etat');
    if (!slot) return undefined;
    let ligne = null, style = null;
    const retirer = () => {
      if (ligne) { ligne.remove(); ligne = null; }
      if (style) { style.remove(); style = null; }
    };
    const poser = () => {
      const V = window.VF_ONGLETS;
      if (!V || typeof V.echec !== 'function' || !V.echec()) { retirer(); return; }
      if (ligne) return;
      style = document.createElement('style'); style.textContent = STYLE; document.head.appendChild(style);
      const b = document.createElement('button');
      ligne = document.createElement('div'); ligne.className = 'vf-ech';
      b.type = 'button'; b.textContent = 'Réessayer';
      b.addEventListener('click', () => { V.reessayer().catch(() => {}); });
      ligne.append(document.createTextNode('Lecture impossible · '), b);
      slot.appendChild(ligne); slot.hidden = false;
    };
    document.addEventListener('vf:coquille-echec', poser); document.addEventListener('vf:onglet', poser);
    poser();
    return () => {
      document.removeEventListener('vf:coquille-echec', poser); document.removeEventListener('vf:onglet', poser); retirer();
    };
  }, { cle: '02-vf-ligne-echec.js' });
})();
