// VibeFlow (80-08) : pile de sélections du panneau de Projet et bouton « Retour » (FORM-08, P80-C76-3, P80-C76-5, P80-D-33).
// Exposé : window.VF_PANNEAU = { retour(), empiler({ titre, rouvrir }), taille() } (gelé ; globale à part, l'objet du moteur est gelé), seulement sur
// l'onglet Projet : elle est recréée vide à chaque arrivée et retirée au départ. Les appelants la lisent au moment de l'appel, jamais en référence gardée.
// Origine d'un geste : un clic DANS #panel marque le prochain changement de sélection « depuis le panneau » (le panneau courant est empilé) ; tout autre
// changement (carte, rangée, canevas, remontée, touche) vide la pile. Retour dépile sans réempiler. Échap n'est jamais intercepté ici.
(() => {
  const SC = window.Floorplan;
  if (!SC || !SC.graph.meta || SC.graph.meta.vfTab !== 'project') return;
  const BORNE = 32, DELAI = 3000, COUPE = 24, NOM = 'vf-retour';
  const panneau = document.getElementById('panel');
  if (!panneau) return;
  let pile = [], vivant = false, geste = 0, explicite = 0, enRetour = 0, precedent = null, ferme = false, echap = 0, pose = [];

  const style = document.createElement('style');
  style.textContent = `
    .vf-retour-barre { display: flex; margin: 0 0 var(--sp-8); }
    .vf-retour { display: inline-flex; align-items: center; gap: var(--sp-4); min-height: 36px; max-width: 100%; padding: 0 var(--sp-8) 0 var(--sp-4);
      border: 0; border-radius: var(--r-ctl); background: none; color: var(--text-2); font: inherit; font-size: 13px; font-weight: 500;
      text-align: left; cursor: pointer; }
    .vf-retour svg.i { flex: none; width: 16px; height: 16px; }
    .vf-retour > span { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .vf-retour:hover { background: rgba(var(--ink), .08); color: var(--text); }
    .vf-retour:focus-visible { outline: 2px solid var(--ring); outline-offset: -2px; }
    .vf-retour[aria-disabled="true"] { color: var(--text-4); cursor: default; background: none; }
    @media (pointer: coarse) { .vf-retour { min-height: 44px; } }
    .vf-sheet-bar .vf-retour { position: absolute; left: var(--sp-4); top: 0; max-width: calc(50% - 32px); }
    .vf-retour-desc { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }`;

  // titre coupé au milieu à l'affichage (points de code, jamais au milieu d'un caractère), complet dans le nom accessible
  const coupe = (t) => { const a = Array.from(t); return a.length <= COUPE ? t : a.slice(0, 12).join('') + '…' + a.slice(-11).join(''); };
  const nomDe = (id) => { try { const i = SC.info(id); return String((i && i.name) || id); } catch { return String(id); } };

  const poser = () => {
    if (!vivant || !panneau.isConnected) return;
    const a = document.activeElement, avait = !!(a && a.classList && a.classList.contains(NOM)); // le focus suit le bouton reposé
    panneau.querySelectorAll('.' + NOM + ', .' + NOM + '-barre, .' + NOM + '-desc').forEach((e) => e.remove());
    const haut = pile[pile.length - 1], b = document.createElement('button');
    b.type = 'button'; b.className = NOM;
    const icone = document.createElement('span'); icone.setAttribute('aria-hidden', 'true'); icone.style.display = 'inline-flex';
    icone.innerHTML = SC.iconI('left'); // constante du moteur, aucune donnée de la page
    const texte = document.createElement('span');
    texte.textContent = haut ? 'Retour : ' + coupe(haut.titre) : 'Retour';
    b.append(icone, texte);
    const d = document.createElement('span'); d.className = NOM + '-desc'; d.id = NOM + '-desc'; d.textContent = 'Revenir à la sélection précédente';
    b.setAttribute('aria-describedby', d.id);
    b.setAttribute('aria-label', haut ? 'Retour : ' + haut.titre : 'Retour, indisponible');
    b.setAttribute('aria-disabled', haut ? 'false' : 'true');
    b.addEventListener('click', (ev) => { ev.preventDefault(); retour(); });
    // Entrée et Espace pressent ce bouton ; ils ne doivent pas aussi lancer l'Entrée globale du moteur (qui plonge dans la sélection), comme 05-theme.js
    b.addEventListener('keydown', (ev) => { if (ev.key === 'Enter' || ev.key === ' ') ev.stopPropagation(); });
    // dans la feuille de détail, le bouton rejoint la barre de la feuille, avant la croix ; sinon une barre en tête du panneau
    const barre = panneau.querySelector(':scope > .vf-sheet-bar'), croix = barre && barre.querySelector('.vf-sheet-x');
    if (barre) { barre.insertBefore(b, croix); barre.append(d); }
    else { const w = document.createElement('div'); w.className = NOM + '-barre'; w.append(b, d); panneau.insertBefore(w, panneau.firstChild); }
    if (avait) b.focus({ preventScroll: true });
  };
  const vider = () => { pile = []; explicite = 0; poser(); };
  const empiler = (e) => {
    if (!e || typeof e.rouvrir !== 'function' || e.titre == null) return;
    pile.push({ titre: String(e.titre), rouvrir: e.rouvrir });
    if (pile.length > BORNE) pile.shift();
    explicite = Date.now() + DELAI; poser();
  };
  const retour = () => {
    if (!pile.length) return; // pile vide : rien ne bouge, le focus reste sur le bouton
    const e = pile.pop(); enRetour = Date.now() + DELAI;
    try { e.rouvrir(); } catch (err) { enRetour = 0; console.error('VF_PANNEAU : entrée retirée', err); } // retirée ; le bouton passe à la suivante
    poser();
  };
  // quand le panneau est rendu : empile, laisse tel quel ou vide, selon l'origine du geste ; le bouton est reposé sur le contenu neuf
  const surPanneau = (d) => {
    const sel = d && d.selected, cle = sel == null ? 'c:' + (d && d.container) : JSON.stringify(sel), cont = d && d.container, maintenant = Date.now();
    if (precedent && (cle !== precedent.cle || cont !== precedent.cont) && maintenant >= enRetour) { // Retour : rien n'est réempilé, rien n'est vidé
      if (sel == null || typeof sel !== 'string' || maintenant >= geste) vider(); // venu d'ailleurs (carte, rangée, canevas, remontée) : on repart de zéro
      else if (cle === precedent.cle) { /* le même nœud change de conteneur (reveal passe par le jalon) : rien */ }
      else if (maintenant < explicite) explicite = 0; // l'appelant a empilé lui-même le panneau courant
      else if (typeof precedent.sel === 'string') {
        const id = precedent.sel; pile.push({ titre: nomDe(id), rouvrir: () => SC.reveal(id) });
        if (pile.length > BORNE) pile.shift();
      }
    }
    precedent = { cle, cont, sel: typeof sel === 'string' ? sel : null };
    queueMicrotask(poser); // après l'observateur de la barre de la feuille (02-vf-telephone.js), qui la repose en tête
  };
  const init = () => {
    if (vivant) return undefined;
    vivant = true; pile = []; geste = explicite = echap = enRetour = 0; precedent = null; ferme = document.body.classList.contains('no-panel');
    window.VF_PANNEAU = Object.freeze({ retour, empiler, taille: () => pile.length });
    document.head.append(style);
    const sur = (cible, ev, f, opt) => { cible.addEventListener(ev, f, opt); pose.push(() => cible.removeEventListener(ev, f, opt)); };
    sur(panneau, 'click', (ev) => { if (ev.target.closest && ev.target.closest('.' + NOM)) return; geste = Date.now() + DELAI; enRetour = 0; }, true);
    const dehors = (ev) => { if (!panneau.contains(ev.target)) { geste = 0; explicite = 0; enRetour = 0; } };
    sur(document, 'pointerdown', dehors, true); sur(document, 'keydown', dehors, true);
    sur(window, 'keydown', (ev) => { if (ev.key === 'Escape') echap = Date.now(); }, true);
    sur(document, 'vf:onglet', vider);
    const obs = new MutationObserver(() => { // panneau fermé (touche p, bouton, croix) : vidé ; Échap de la feuille : la pile reste
      const f = document.body.classList.contains('no-panel'); if (f === ferme) return; ferme = f;
      if (!f || Date.now() - echap < 300) return;
      setTimeout(() => { if (vivant && document.body.classList.contains('no-panel')) vider(); }, 400); // un go() referme et rouvre la feuille : on attend
    });
    obs.observe(document.body, { attributes: true, attributeFilter: ['class'] }); pose.push(() => obs.disconnect());
    SC.on('panel', surPanneau);
    return () => { vivant = false; pile = []; pose.splice(0).forEach((f) => f()); style.remove(); delete window.VF_PANNEAU; poser(); };
  };
  const C = window.VF_COQUILLE;
  if (C && typeof C.surOnglet === 'function') C.surOnglet(init); // P80-D-42 : la coquille, sinon `ready` (ou le premier rendu, s'il l'a devancé)
  else if (SC.state.layout) init(); else { SC.on('ready', init); SC.on('render', init); }
})();
