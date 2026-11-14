// VibeFlow (77-05, SYNT-01 ; P77-D-01, P77-D-19, P77-D-30) : la coquille de la Synthèse sur l'onglet Projet. Le bouton « Synthèse » d'en-tête, le panneau
// à blocs ordonnés, le registre des blocs et la ligne-résumé de l'aperçu. Script PAR ONGLET (ré-exécuté à chaque onglet, 79-16) : tout s'installe par
// VF_COQUILLE.surOnglet quand l'onglet est « projet » et se retire par le nettoyage rendu ; rien ne se dessine au chargement. Les lectures passent par
// VF_ETAT.lireJson (jamais un jeton lu ici) ; aucune écriture.
// Registre : window.__vfSyntheseBlocs (tableau créé s'il manque, jamais réaffecté) ; chaque fichier frère 74-vf-synthese-*.js y pousse son bloc,
// avant ou après ce fichier :
//   { id, titre, installer(ctx) -> nettoyer, present(ctx) -> booléen, rendre(corps, ctx), ouvrir(corps, ctx) }
//   id ∈ visite, burnup, methode, cout (ordre fixe, jamais trié par importance) ; un id inconnu est ignoré.
//   `corps` est le conteneur du bloc SOUS son h3 (la coquille pose le h3, la `section.sec.vf-sy` et son aria-labelledby) : un rafraîchissement en
//   remplace le contenu, jamais le panneau. `installer` est appelé à chaque arrivée sur l'onglet Projet ; `rendre` puis `ouvrir` à l'ouverture.
//   ctx = { SC, graphe(), lireJson(chemin) (null sur tout échec), annoncer(texte), majResume({ texte, titre }), ouvert() }
//   majResume : `texte` est la ligne-résumé, `titre` le résumé du nom accessible du bouton (« Synthèse : {titre} depuis votre dernière visite »).
(() => {
  'use strict';
  const SC = window.VibeFlow, CQ = window.VF_COQUILLE, E = window.VF_ETAT;
  if (!SC || !CQ || typeof CQ.surOnglet !== 'function' || !E || typeof E.lireJson !== 'function') return; // page exportée ou sans coquille : rien
  window.__vfSyntheseBlocs = window.__vfSyntheseBlocs || [];
  const ORDRE = ['visite', 'burnup', 'methode', 'cout'], ICONE = '<path d="M4 19h16M5 15h4v-4h4V8h4V5"/>', panneau = document.getElementById('panel');
  let installe = false, resume = null, bouton = null, suivi = null, ctx = null, ouvertA = null, premiere = false;
  const nettoyages = [];

  const lieu = () => JSON.stringify([SC.state.selected, SC.state.container]);
  const ouverte = () => !!panneau.querySelector(':scope > .vf-sy') && !document.body.classList.contains('no-panel');
  // une surcouche ouverte prend l'Échap d'abord
  const couverte = () => { const S = window.VF_SURCOUCHES; return !!S && typeof S.couverte === 'function' && S.couverte(panneau); };
  const nom = () => {
    if (!resume) return 'Synthèse du projet';
    return resume.titre ? `Synthèse : ${resume.titre} depuis votre dernière visite` : `Synthèse : ${resume.texte}`;
  };
  const etiqueter = () => { if (bouton) { const n = nom(); bouton.title = n; bouton.setAttribute('aria-label', n); } };
  const sur = (b, f, ...a) => {
    try { return typeof b[f] === 'function' ? b[f](...a) : undefined; } catch (e) {
      console.error('Synthèse : un bloc a levé : ' + (e && e.message)); return undefined;
    }
  };
  const blocs = () => { // registre lu à chaque usage : id connu, un seul bloc par id, ordre fixe
    const vus = new Set(), reg = Array.isArray(window.__vfSyntheseBlocs) ? window.__vfSyntheseBlocs : [];
    return reg.filter((b) => b && typeof b === 'object' && ORDRE.includes(b.id) && !vus.has(b.id) && vus.add(b.id))
      .sort((a, b) => ORDRE.indexOf(a.id) - ORDRE.indexOf(b.id));
  };

  // icône seule à toute largeur (règle de #btn-synthese .bl) : avec son libellé (1 600 px et plus) le fil d'Ariane de Projet était rogné (R21, R22) ;
  // le nom reste au title et à l'aria-label
  const feuille = () => {
    if (document.getElementById('vf-sy-coquille')) return;
    const st = document.createElement('style'); st.id = 'vf-sy-coquille';
    st.textContent = `.vf-sy .sr { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); clip-path: inset(50%);
        white-space: nowrap; }
      .vf-sy h2:focus-visible, .vf-sy h3:focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; border-radius: 8px; }
      .vf-sy h2:focus:not(:focus-visible), .vf-sy h3:focus:not(:focus-visible) { outline: none; }
      #btn-synthese .bl { display: none; }
      button.vf-rep { background: none; border: 0; font: inherit; color: inherit; text-align: left; width: 100%; cursor: pointer; }
      @media (pointer: coarse), (max-width: 999px) { #btn-synthese, .vf-sy .btn, button.row[data-vf-sy-resume] { min-height: 44px; } }`;
    document.head.appendChild(st);
  };

  // ---------- résumé : le nom du bouton et la ligne de l'aperçu, mis à jour en place, sans toucher au panneau ouvert ----------
  const vueApercu = () => !SC.state.selected && SC.state.container === 'root' && !ouverte();
  function majResume(r) {
    const ok = r && typeof r === 'object' && typeof r.texte === 'string' && r.texte;
    resume = ok ? { texte: r.texte, titre: typeof r.titre === 'string' ? r.titre : '' } : null; etiqueter();
    const rn = panneau.querySelector('[data-vf-sy-resume] .rn');
    if (rn && resume) rn.textContent = resume.texte; // mise à jour en place
    else if (!!rn !== !!resume && vueApercu() && !panneau.contains(document.activeElement)) SC.refreshPanel(); // la ligne apparaît ou disparaît
  }

  // ---------- panneau ----------
  const tete = '<div class="sec vf-sy"><h2 class="pt" tabindex="-1">Synthèse</h2>'
    + '<p class="pd">Ce qui a bougé, où en est le jalon, et si les règles de méthode tiennent.</p>'
    + '<div class="sr" role="status" aria-live="polite" aria-atomic="true"></div>';
  const section = (b) => `<section class="sec vf-sy" data-vf-sy-bloc="${b.id}" aria-labelledby="vf-sy-t-${b.id}">`
    + `<h3 id="vf-sy-t-${b.id}" tabindex="-1"></h3><div class="vf-sy-corps"></div></section>`;
  const html = () => tete
    + `<div class="actions"><button type="button" class="btn soft" data-vf-sy-fermer>${SC.iconI('x')}Fermer la synthèse</button></div></div>`
    + blocs().filter((b) => sur(b, 'present', ctx) !== false).map(section).join('');
  function lier(el) { // bind du viewer : appelé à chaque rendu du panneau ouvert ; focus et `ouvrir` des blocs à la première ouverture seulement
    if (!el.querySelector(':scope > .vf-sy')) return;
    const debut = premiere; premiere = false;
    el.querySelector('[data-vf-sy-fermer]').addEventListener('click', () => { SC.closePanel(); if (bouton) bouton.focus({ preventScroll: true }); });
    for (const b of blocs()) {
      const sec = el.querySelector(`section[data-vf-sy-bloc="${b.id}"]`); if (!sec) continue;
      const corps = sec.querySelector('.vf-sy-corps'); sec.querySelector('h3').textContent = String(b.titre || '');
      sur(b, 'rendre', corps, ctx); if (debut) sur(b, 'ouvrir', corps, ctx);
    }
    if (debut) el.querySelector('.vf-sy h2').focus({ preventScroll: true });
  }
  function ouvrir() { if (!installe) return; ouvertA = lieu(); premiere = true; SC.showPanel(html(), lier); }
  const fermerAuClavier = (e) => {
    if (e.key !== 'Escape' || e.defaultPrevented || !ouverte() || couverte()) return;
    e.stopPropagation(); e.preventDefault(); SC.closePanel(); if (bouton) bouton.focus({ preventScroll: true });
  };
  const surBouton = (e) => { if (bouton && e.target === bouton) fermerAuClavier(e); };

  // ---------- installation par onglet ----------
  function nettoyer() {
    installe = false;
    for (const n of nettoyages.splice(0).reverse()) { try { n(); } catch (e) { console.error('Synthèse : un nettoyage a levé : ' + (e && e.message)); } }
    if (suivi) suivi.disconnect(); suivi = null;
    panneau.removeEventListener('keydown', fermerAuClavier); document.removeEventListener('keydown', surBouton, true);
    if (ouverte()) SC.closePanel();
    if (bouton) bouton.remove();
    bouton = null; resume = null; ctx = null;
  }
  function installer() {
    installe = true; feuille();
    bouton = SC.addHeaderButton({ id: 'btn-synthese', label: 'Synthèse', svg: ICONE, title: nom(), onClick: () => (ouverte() ? SC.closePanel() : ouvrir()) });
    const sante = document.getElementById('btn-health'); if (sante) sante.after(bouton); // sinon la fin de l'en-tête : l'API fait foi, jamais une position
    bouton.setAttribute('aria-controls', 'panel'); etiqueter();
    const etat = () => { if (bouton) bouton.setAttribute('aria-expanded', String(ouverte())); };
    suivi = new MutationObserver(etat); suivi.observe(panneau, { childList: true });
    suivi.observe(document.body, { attributes: true, attributeFilter: ['class'] }); etat();
    panneau.addEventListener('keydown', fermerAuClavier); document.addEventListener('keydown', surBouton, true);
    const annoncer = (t) => { const sr = panneau.querySelector(':scope > .vf-sy .sr'); if (sr) sr.textContent = String(t); };
    const lireJson = (chemin) => { try { return E.lireJson(chemin).then((j) => j, () => null); } catch { return Promise.resolve(null); } };
    ctx = { SC, graphe: () => SC.graph, ouvert: ouverte, majResume, annoncer, lireJson };
    for (const b of blocs()) { const n = sur(b, 'installer', ctx); if (typeof n === 'function') nettoyages.push(n); }
    return nettoyer;
  }
  if (SC.graph.meta && SC.graph.meta.vfTab === 'project') {
    // le viewer n'offre aucun retrait : inscrites une fois par exécution du fichier, sur un moteur neuf à chaque onglet, et muettes hors de l'onglet installé
    SC.addPanelSection('overview', () => (!installe || !resume ? '' : { top: true,
      html: '<div class="sec"><h3>Synthèse</h3><button type="button" class="row vf-rep" data-vf-sy-resume><span class="rt"><div class="rn"></div>'
        + `<div class="rd">Burn-up du jalon et santé de la méthode</div></span><span class="rc">${SC.iconI('right')}</span></button></div>`,
      bind: (el) => {
        const b = el.querySelector('[data-vf-sy-resume]'); b.querySelector('.rn').textContent = resume.texte; b.addEventListener('click', ouvrir);
      } }));
    SC.on('panel', () => { // une autre carte est choisie : la Synthèse se ferme
      if (installe && ouvertA !== null && ouverte() && lieu() !== ouvertA) { ouvertA = null; SC.closePanel(); }
    });
  }
  CQ.surOnglet(({ onglet }) => (onglet === 'projet' && E.jeton() !== null ? installer() : undefined), { cle: '74-vf-synthese.js' });
})();
