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
  // P78-D-01, P78-D-09 : le panneau de droite lit le même nom que l'en-tête (dépôt principal, jamais « wt-a — Projet »). Posé APRÈS 00-vibeflow.js : le titre de l'onglet, déjà écrit, et les clés
  // enregistrées par nom (flux, visite) gardent leur valeur d'avant.
  G.project.name = nom.textContent;

  // ---------- bloc de vue racine (P78-D-03) : dit ce que montre la vue, jamais le nom du projet — même sans git ----------
  const TAB = G.meta.vfTab === 'project' ? 'project' : G.meta.vfTab === 'equipe' ? 'equipe' : 'code';
  const pl = (n, mot) => `${n} ${mot}${n > 1 ? 's' : ''}`;
  const texteVue = () => {
    const VF = G.meta.vf || {}, depot = V && (V.etat === 'ok' || V.etat === 'indisponible'); // un dépôt détecté ; sinon « dossier »
    if (TAB === 'code') {
      const b = V && V.etat === 'ok' ? (V.detache ? 'HEAD détaché' : V.branche ? `branche ${V.branche}` : '') : '';
      return { k: 'Code', h1: b ? `Le code, ${b}` : 'Le code du projet',
        p: `${pl((G.files || []).length, 'fichier')} et ${pl((G.routes || []).length, 'route')} lus dans le ${depot ? 'dépôt' : 'dossier'}.` };
    }
    if (TAB === 'project') { // P78-D-03 : le sous-titre résume la vue (phase en cours, phases faites sur le total du jalon), il ne redit jamais le titre
      const L = Array.isArray(VF.milestones) ? VF.milestones : [], m = L.find((x) => x.key === VF.milestone && x.st !== 'done') || L.find((x) => x.st === 'active') || L[L.length - 1], fait = m && m.total > 0 ? `${pl(m.done, 'phase')} ${m.done > 1 ? 'faites' : 'faite'} sur ${m.total}` : '';
      const c = VF.counts || {}, tout = typeof c.phases === 'number' && typeof c.plans === 'number' ? `${pl(c.phases, 'phase')} · ${pl(c.plans, 'plan')}` : '';
      const p = [VF.phase ? `Phase ${VF.phase}${/^(executing|in_progress|verifying)$/.test(String(VF.status)) ? ' en cours' : ''}` : '', fait].filter(Boolean).join(', ');
      return { k: 'Projet', h1: VF.milestone ? `Jalon ${VF.milestone}` : 'Le projet', p: p ? p + '.' : tout ? tout + '.' : '' };
    }
    const M = Array.isArray(VF.missions) ? VF.missions : [], c = VF.compte || {};
    const repos = !M.length && !c.actif && !c.enAttente; // aucune mission et personne au travail
    return { k: 'Équipe', h1: M.length === 1 ? `Mission : ${M[0]}` : M.length > 1 ? `${M.length} missions en cours` : 'Aucune mission en cours', p: repos ? "L'équipe est au repos." : G.project.summary || '' };
  };
  const ecrireVue = () => { // réécrit le bloc que renderContext vient de poser ; sous-vues et réponses (q:answer) inchangées
    const ctx = document.querySelector('#context'), k = ctx && ctx.querySelector('.k'), h1 = ctx && ctx.querySelector('h1');
    if (!k || !h1) return;
    const t = texteVue();
    k.textContent = t.k; h1.classList.add('vf-ctx-titre');
    h1.replaceChildren(); // F13 : le titre ne se coupe qu'après « / » ou « - » : un <wbr> (élément DOM, jamais de HTML) suit chaque séparateur ; textContent reste le texte exact
    t.h1.split(/(?<=[/-])/).forEach((morceau, i) => { if (i) h1.appendChild(document.createElement('wbr')); h1.appendChild(document.createTextNode(morceau)); });
    let d = ctx.querySelector('.cd');
    if (!d) { d = document.createElement('p'); d.className = 'cd'; d.id = 'ctx-desc'; h1.after(d); }
    d.textContent = t.p;
    const more = ctx.querySelector('.ctx-more'); // même pliage que foldContext du viewer, relu sur le texte neuf
    if (more) {
      const ouvert = more.getAttribute('aria-expanded') === 'true';
      ctx.classList.add('folded');
      const long = d.scrollHeight > d.clientHeight + 1 || !!ctx.querySelector('.cx');
      ctx.classList.toggle('folded', !ouvert);
      more.hidden = !long;
    }
  };
  const styleVue = document.createElement('style');
  styleVue.textContent = '.vf-ctx-titre { display: -webkit-box; -webkit-box-orient: vertical; -webkit-line-clamp: 2; overflow: hidden; overflow-wrap: anywhere; }';
  document.head.appendChild(styleVue);
  // le premier rendu peut précéder ce fichier (l'analyseur rend la main entre deux scripts) : on réécrit aussi à l'arrivée du fichier, puis à « ready »
  SC.on('render', (e) => { if (e && e.container === 'root') ecrireVue(); });
  SC.on('ready', () => { if (SC.state && SC.state.container === 'root') ecrireVue(); });
  if (SC.state && SC.state.container === 'root') ecrireVue();
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
    .vf-git-ligne:focus-visible { outline: 2px solid var(--ring); outline-offset: -2px; } /* anneau DANS la pastille : à l'extérieur il mordait sur le nom juste au-dessus */
    .vf-git-branche, .vf-git-wt { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .vf-git-branche { flex: 0 1 auto; }
    .vf-git-wt { flex: 0 2 auto; }
    .vf-git-ligne .kbd { margin-left: 6px; opacity: 0; transition: opacity 150ms var(--ease); flex: none; }
    .vf-git-ligne:hover .kbd, .vf-git-ligne:focus-visible .kbd { opacity: 1; }
    .vf-git-ligne[hidden], #vf-git-ouvreur[hidden] { display: none !important; }
    #vf-git-ouvreur { display: none; }
    #vf-git-ouvreur:focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; }
    /* P78-D-34 (avis du juge de design) : la seconde ligne est illisible sous 1280 px ; l'ouvreur icône de 44 px la remplace de 701 à 1279 px */
    @media (max-width: 1279px) {
      .vf-git-ligne { display: none; }
      #vf-git-ouvreur { display: inline-flex; width: 44px; height: 44px; }
    }
    /* même requête que viewer.html (« phones and tablets ») : le nom et sa seconde ligne partent ensemble */
    @media (max-width: 999px), (max-width: 1279px) and (pointer: coarse) { .vf-nom { display: none; } }
    /* l'icône ajoute 48 px à droite (44 px et l'écart) ; comme pour le bouton Thème (viewer.html), la zone de recherche en cède autant, pour que l'en-tête passe sur deux rangées à la même largeur avec et sans git :
       rangée qui se replie (≤ 999 px, ou tactile ≤ 1279 px) = sa base flex ; ligne unique de bureau (1000 à 1279 px, 01-vf-responsive.js : plancher de 200 px) = son plancher, 152 px */
    @media (min-width: 701px) and (max-width: 999px), (min-width: 701px) and (max-width: 1279px) and (pointer: coarse) { .hc { flex-basis: calc(min(460px, 24vw) - 48px); } }
    @media (min-width: 1000px) and (max-width: 1279px) and (not (pointer: coarse)) { header .hc { min-width: 152px; } }
    /* téléphone (≤ 700 px, 02-vf-telephone.js, P70-D-01) : l'en-tête tient sur une rangée et les actions vivent dans le menu « ⋯ », qui reprend ce bouton (libellé .bl, clic relayé) */
    @media (max-width: 700px) { #vf-git-ouvreur { display: none !important; } }
    #vf-git-ouvreur .bl { display: none; }
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
  { const bl = document.createElement('span'); bl.className = 'bl'; bl.textContent = 'Historique Git'; ouvreur.appendChild(bl); } // libellé court lu par le menu « ⋯ » du téléphone
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
