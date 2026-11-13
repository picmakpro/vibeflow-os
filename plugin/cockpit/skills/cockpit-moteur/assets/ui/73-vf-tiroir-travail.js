// VibeFlow (EA3, PU-G-189 et PU-G-190) : le clavier et l'état du tiroir « Au travail ». Le tiroir lui-même se dessine dans 70-vf-live.js (chargé avant ce fichier) ;
// ici seulement ce qui l'entoure : le bouton « N au travail » dit s'il est ouvert (aria-expanded) et ce qu'il ouvre (aria-controls, comme la ligne Git), et Échap
// ferme ce tiroir-là, seul, sans faire remonter le canevas, puis rend le focus au bouton. Rien ne se pose hors du direct (page exportée ou ouverte en fichier).
// Q12 (PU-G-203) : sous 1280 px un seul tiroir latéral à la fois, Git (gauche) ou « Au travail » (droite) ; celui qui s'ouvre replie l'autre et prend le focus. Le détail d'une carte n'est pas concerné (question en attente).
// Q12, réponse de Samuel (AskUserQuestion, session principale, 2026-11-06, « Non, lecture étroite (Recommandé) ») : seuls le tiroir Git et « Au travail » s'excluent sous 1280 px ; le détail d'une carte reste ouvert à côté du tiroir Git (PU-G-203).
(() => {
  const SC = window.Floorplan, SRV = window.FLOORPLAN_SERVER;
  if (!SC || !SRV || !SRV.token || typeof EventSource === 'undefined') return; // même garde que 70-vf-live.js
  const panneau = document.getElementById('panel'), entete = document.getElementById('hdr-ext');
  if (!panneau || !entete) return;
  const st = document.createElement('style'); st.textContent = '.vf-whop h3:focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; border-radius: 4px; } .vf-whop h3:focus:not(:focus-visible) { outline: none; }'; document.head.appendChild(st); // le titre reçoit le focus à l\'ouverture (comme celui du tiroir Git) : l\'anneau se voit au clavier
  const bouton = () => document.getElementById('vf-lock');
  const ouvert = () => !!panneau.querySelector(':scope > .vf-whop') && !document.body.classList.contains('no-panel'); // le tiroir « Au travail » occupe le panneau, et le panneau est ouvert
  const ETROIT = window.matchMedia('(max-width: 1279px)'), git = () => window.VFGitTiroir; // 77-vf-git-tiroir.js se charge après ce fichier : lu à l'usage
  let etaitOuvert = ouvert(), aRestaurer = true, sansFocus = false;
  // 80-13 : l'état ouvert est gardé en mémoire de session (au nom du lab) ; rouvert à l'arrivée sur un onglet, sans focus (rien ne le demande à l'humain)
  const cleMemo = () => 'vf-tiroirs:' + String(((SC.graph || {}).project || {}).name || '').replace(/ — (Projet|Équipe)$/, '');
  const lireMemo = () => { try { const j = JSON.parse(sessionStorage.getItem(cleMemo())); return !!j && j.travail === true; } catch { return false; } };
  const ecrireMemo = (v) => {
    try {
      const k = cleMemo(), j = JSON.parse(sessionStorage.getItem(k));
      sessionStorage.setItem(k, JSON.stringify({ ...(j && typeof j === 'object' ? j : {}), travail: v }));
    } catch { /* stockage refusé */ }
  };
  const restaurer = (b) => { // une fois, au premier passage où le bouton existe (il est posé au premier événement du direct)
    aRestaurer = false;
    if (!lireMemo() || ouvert()) return;
    sansFocus = true; try { b.click(); etat(); } finally { sansFocus = false; }
  };
  const etat = () => {
    const b = bouton(); if (!b) return;
    if (aRestaurer) restaurer(b);
    const o = ouvert();
    b.setAttribute('aria-controls', 'panel'); b.setAttribute('aria-expanded', String(o));
    if (o !== etaitOuvert) { // 80-02 : le tiroir s'inscrit dans la pile à l'ouverture et s'en retire au repli
      ecrireMemo(o);
      if (o) window.VF_SURCOUCHES.ouvrir(panneau, { fermer: () => document.getElementById('btn-panel').click() });
      else window.VF_SURCOUCHES.fermer(panneau);
    }
    if (o && !etaitOuvert && ETROIT.matches) { // « Au travail » s'ouvre sous 1280 px : Git se replie s'il était ouvert (sans voler le focus à autre chose), et le focus va au tiroir qui s'ouvre (Q12, PU-G-203 ; recette du 2026-11-08 : il restait sur le bouton « N au travail », 15 à 20 Tab pour entrer)
      const gitOuvert = !!git() && git().ouvert(); if (gitOuvert) git().fermer(true);
      const a = document.activeElement, titre = panneau.querySelector(':scope > .vf-whop h3');
      // le tiroir « Au travail » porte toujours son titre (le gabarit de 70-vf-live.js, seul producteur de .vf-whop, le pose) : l'ancienne branche « sinon, Git vient de se replier, le focus au bouton » n'était atteinte dans aucun scénario (revue du 2026-11-08, S8)
      if (!sansFocus && titre && !panneau.contains(a) && (gitOuvert || a === b || a === document.body || !a)) { titre.tabIndex = -1; titre.focus({ preventScroll: true }); }
    }
    etaitOuvert = o;
  };
  window.addEventListener('vf-git:etat', (e) => { if (e.detail && e.detail.ouvert && ETROIT.matches && ouvert()) document.getElementById('btn-panel').click(); }); // Git s'ouvre (le focus est déjà sur son titre) : « Au travail » se replie
  const echap = (e) => {
    if (e.key !== 'Escape' || e.defaultPrevented || !ouvert() || window.VF_SURCOUCHES.couverte(panneau)) return; // la pile : une surcouche au-dessus prend l'Échap
    e.stopPropagation(); e.preventDefault(); // le viewer n'entend pas cet Échap : il ne remonte pas le canevas
    document.getElementById('btn-panel').click(); // la fermeture du viewer (animation, état mémorisé), pas une copie
    bouton()?.focus({ preventScroll: true });
  };
  panneau.addEventListener('keydown', echap); // focus dans le tiroir
  document.addEventListener('keydown', (e) => { if (e.target === bouton()) echap(e); }, true); // focus sur le bouton lui-même
  const suivi = new MutationObserver(etat); // le panneau change de contenu, la page ferme ou rouvre le panneau, le bouton est posé au premier événement du direct
  suivi.observe(panneau, { childList: true }); suivi.observe(entete, { childList: true }); suivi.observe(document.body, { attributes: true, attributeFilter: ['class'] });
  etat();
})();
