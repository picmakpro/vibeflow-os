// VibeFlow (78-04) : en-tête Git — le nom du dépôt principal sur les trois onglets, la branche et le worktree sur une seconde ligne.
// Donnée : G.meta.vfGit (vf-cockpit-git-entete.mjs). Sans git (état « absent ») ou sans donnée : ni seconde ligne, ni ouvreur, ni bloc .vf-nom ;
// seul le nom change. Tout texte venu de git s'écrit en textContent / setAttribute, jamais en innerHTML. Ne touche pas au viewer.
// Contrat d'événements (sur window) : vf-git:basculer (émis ici, detail.source = ligne | ouvreur) · vf-git:etat (reçu, detail.ouvert) ·
// vf-git:entete (reçu, detail = objet d'en-tête) · vf-git:signal (reçu : relecture de /api/vf/git/entete, schéma vibeflow/cockpit-git-entete@1).
(() => {
  const SC = window.Floorplan;
  if (!SC) return;
  const G = SC.graph, V = G.meta && G.meta.vfGit;
  const nom = document.querySelector('#proj-name');
  if (!nom) return;
  const SUFFIXE = / — (Projet|Équipe)$/;
  nom.textContent = String(V && V.depot ? V.depot : nom.textContent).replace(SUFFIXE, ''); // GITC-01 : même nom sur les trois onglets, aucun suffixe
  if (!V || V.etat === 'absent' || !V.depot) return; // P78-D-11 : rien d'autre dans le DOM
  nom.title = nom.textContent; // nom entier, la troncature est visuelle

  const style = document.createElement('style');
  style.textContent = `
    .vf-nom { display: flex; flex-direction: column; min-width: 0; }
    .vf-nom #proj-name { max-width: 220px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .vf-git-ligne { display: inline-flex; align-items: center; max-width: 220px; padding: 2px 6px; margin-left: -6px; border: 0; border-radius: 999px; background: transparent;
      font-family: var(--mono); font-size: 11px; font-weight: 500; line-height: 1.4; color: var(--text-3); cursor: pointer; text-align: left; }
    .vf-git-ligne:hover { background: rgba(var(--ink), .06); color: var(--text); }
    .vf-git-ligne[aria-expanded="true"] { background: rgba(var(--ink), .1); color: var(--text); }
    .vf-git-ligne:focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; }
    .vf-git-ligne.vf-git-detache { color: var(--warn-text); }
    .vf-git-ligne.vf-git-indispo { color: var(--text-4); }
    .vf-git-branche, .vf-git-wt { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .vf-git-branche { flex: 0 1 auto; }
    .vf-git-wt { flex: 0 2 auto; }
    .vf-git-ligne .kbd { margin-left: 6px; opacity: 0; transition: opacity 150ms var(--ease); flex: none; }
    .vf-git-ligne:hover .kbd, .vf-git-ligne:focus-visible .kbd { opacity: 1; }
    .vf-git-ligne[hidden], #vf-git-ouvreur[hidden] { display: none !important; }
    #vf-git-ouvreur { display: none; }
    #vf-git-ouvreur:focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; }
    /* même requête que viewer.html (« phones and tablets ») : la seconde ligne part avec le nom, l'ouvreur icône prend le relais */
    @media (max-width: 999px), (max-width: 1279px) and (pointer: coarse) {
      .vf-nom { display: none; }
      #vf-git-ouvreur { display: inline-flex; width: 44px; height: 44px; }
    }
  `;
  document.head.appendChild(style);

  const brand = nom.parentElement;
  const bloc = document.createElement('div');
  bloc.className = 'vf-nom';
  brand.insertBefore(bloc, nom);
  bloc.appendChild(nom);
  const ligne = document.createElement('button');
  ligne.type = 'button'; ligne.id = 'vf-git-ligne'; ligne.className = 'vf-git-ligne';
  ligne.setAttribute('aria-expanded', 'false'); ligne.setAttribute('aria-controls', 'vf-git-tiroir');
  const spBranche = document.createElement('span'); spBranche.className = 'vf-git-branche';
  const spWt = document.createElement('span'); spWt.className = 'vf-git-wt';
  const kbd = document.createElement('span'); kbd.className = 'kbd'; kbd.textContent = 'g'; kbd.setAttribute('aria-hidden', 'true');
  ligne.append(spBranche, spWt, kbd);
  bloc.appendChild(ligne);

  // ouvreur tactile : bouton icône (glyphe branche, constant) en tête de .hr ; caché au-dessus de 1000 px
  const ouvreur = document.createElement('button');
  ouvreur.type = 'button'; ouvreur.id = 'vf-git-ouvreur'; ouvreur.className = 'btn icon';
  ouvreur.setAttribute('aria-expanded', 'false'); ouvreur.setAttribute('aria-controls', 'vf-git-tiroir');
  { const NS = 'http://www.w3.org/2000/svg', svg = document.createElementNS(NS, 'svg');
    svg.setAttribute('class', 'i'); svg.setAttribute('viewBox', '0 0 24 24'); svg.setAttribute('aria-hidden', 'true');
    for (const [t, a] of [['circle', { cx: 6, cy: 6, r: 2 }], ['circle', { cx: 6, cy: 18, r: 2 }], ['circle', { cx: 18, cy: 8, r: 2 }], ['path', { d: 'M6 8v8M18 10c0 4-6 3-12 6' }]]) {
      const e = document.createElementNS(NS, t); for (const k in a) e.setAttribute(k, String(a[k])); svg.appendChild(e); }
    ouvreur.appendChild(svg); }
  const hr = document.querySelector('header .hr');
  if (hr) hr.insertBefore(ouvreur, hr.firstChild);

  const lire = (d) => {
    if (d.etat === 'absent') { ligne.hidden = true; ouvreur.hidden = true; return; } // le dépôt a disparu en cours de route : tout se tait
    ligne.hidden = false; ouvreur.hidden = false;
    const indispo = d.etat === 'indisponible';
    const texteBranche = indispo ? 'Branche indisponible' : d.detache ? `HEAD détaché · ${d.sha7 || ''}` : String(d.branche || '');
    spBranche.textContent = texteBranche;
    spWt.textContent = d.worktree && !indispo ? ` · worktree ${d.worktree}` : '';
    const lisible = indispo ? 'branche indisponible' : d.detache ? 'HEAD détaché' : 'branche ' + d.branche;
    ligne.title = texteBranche + spWt.textContent;
    ligne.setAttribute('aria-label', `Historique Git, ${lisible}. Ouvrir (g)`);
    ouvreur.setAttribute('aria-label', `Historique Git, ${lisible}. Ouvrir (g)`); ouvreur.title = ouvreur.getAttribute('aria-label');
    ligne.classList.toggle('vf-git-detache', !!d.detache);
    ligne.classList.toggle('vf-git-indispo', indispo);
  };
  lire(V);

  const basculer = (source) => window.dispatchEvent(new CustomEvent('vf-git:basculer', { detail: { source } }));
  ligne.addEventListener('click', () => basculer('ligne'));
  ouvreur.addEventListener('click', () => basculer('ouvreur'));
  window.addEventListener('vf-git:etat', (e) => { const o = String(!!(e.detail && e.detail.ouvert)); ligne.setAttribute('aria-expanded', o); ouvreur.setAttribute('aria-expanded', o); });
  const valide = (d) => d && typeof d === 'object' && (d.etat === 'ok' || d.etat === 'indisponible' || d.etat === 'absent');
  window.addEventListener('vf-git:entete', (e) => { if (valide(e.detail)) lire(e.detail); });
  window.addEventListener('vf-git:signal', () => { // relecture de l'en-tête (le serveur vérifie le jeton) ; réponse hors schéma : ignorée
    const SRV = window.FLOORPLAN_SERVER;
    if (!SRV || !SRV.token) return;
    fetch('/api/vf/git/entete', { headers: { 'x-floorplan-token': SRV.token }, cache: 'no-store' })
      .then((r) => (r.ok ? r.json() : null)).then((j) => { if (j && j.schema === 'vibeflow/cockpit-git-entete@1' && valide(j)) lire(j); }).catch(() => {});
  });
})();
