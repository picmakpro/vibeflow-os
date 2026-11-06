// VibeFlow (EA3, PU-G-189 et PU-G-190) : le clavier et l'état du tiroir « Au travail ». Le tiroir lui-même se dessine dans 70-vf-live.js (chargé avant ce fichier) ;
// ici seulement ce qui l'entoure : le bouton « N au travail » dit s'il est ouvert (aria-expanded) et ce qu'il ouvre (aria-controls, comme la ligne Git), et Échap
// ferme ce tiroir-là, seul, sans faire remonter le canevas, puis rend le focus au bouton. Rien ne se pose hors du direct (page exportée ou ouverte en fichier).
(() => {
  const SC = window.Floorplan, SRV = window.FLOORPLAN_SERVER;
  if (!SC || !SRV || !SRV.token || typeof EventSource === 'undefined') return; // même garde que 70-vf-live.js
  const panneau = document.getElementById('panel'), entete = document.getElementById('hdr-ext');
  if (!panneau || !entete) return;
  const bouton = () => document.getElementById('vf-lock');
  const ouvert = () => !!panneau.querySelector(':scope > .vf-whop') && !document.body.classList.contains('no-panel'); // le tiroir « Au travail » occupe le panneau, et le panneau est ouvert
  const etat = () => { const b = bouton(); if (!b) return; b.setAttribute('aria-controls', 'panel'); b.setAttribute('aria-expanded', String(ouvert())); };
  const surcouche = () => !!document.querySelector('#palette.open, #flowmenu.open, #legend.open, #ctxmenu:not([hidden]), [role="dialog"]:not([hidden]), [aria-modal="true"]'); // une palette ou un menu ouvert prend l'Échap d'abord
  const echap = (e) => {
    if (e.key !== 'Escape' || e.defaultPrevented || !ouvert() || surcouche()) return;
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
