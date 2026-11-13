// VibeFlow (78-04) : en-tête Git — le nom du dépôt principal sur les trois onglets, la branche et le worktree sur une seconde ligne.
// Donnée : G.meta.vfGit (vf-cockpit-git-entete.mjs). Sans git (état « absent ») ou sans donnée : ni seconde ligne, ni ouvreur, ni bloc .vf-nom ;
// seul le nom change. Tout texte venu de git s'écrit en textContent / setAttribute, jamais en innerHTML. Ne touche pas au viewer.
// Contrat d'événements (sur window) : vf-git:basculer (émis ici, detail.source = ligne | ouvreur) · vf-git:etat (reçu, detail.ouvert) ·
// vf-git:entete (reçu, detail = objet d'en-tête) · vf-git:signal (reçu SUR document, sans bubbles, comme l'émet 70-vf-live.js : relecture de /api/vf/git/entete, schéma vibeflow/cockpit-git-entete@1).
(() => {
  const SC = window.Floorplan;
  if (!SC) return;
  const G = SC.graph;
  let V = G.meta && G.meta.vfGit; // lu à l'assemblage, puis remplacé par chaque lecture réelle (chargement, signal, tiroir) : la branche d'un `git switch` n'attend pas le signal suivant
  const nom = document.querySelector('#proj-name');
  if (!nom) return;
  const SUFFIXE = / — (Projet|Équipe)$/;
  nom.textContent = String(V && V.depot ? V.depot : nom.textContent).replace(SUFFIXE, ''); // GITC-01 : même nom sur les trois onglets, aucun suffixe
  // P78-D-01, P78-D-09 : le panneau de droite lit le même nom que l'en-tête (dépôt principal, jamais « wt-a — Projet »). Posé APRÈS 00-vibeflow.js : le titre de l'onglet, déjà écrit, et les clés
  // enregistrées par nom (flux, visite) gardent leur valeur d'avant.
  G.project.name = nom.textContent;
  // AUDC-X7 : le titre de l'onglet du navigateur (« <Onglet> · <nom> », écrit par 00-vibeflow.js avec le nom du graphe : dossier sur Code, titre de PROJECT.md sur Projet et Équipe) reprend le nom que l'en-tête affiche, le même sur les trois pages
  { const b = window.__vfTitreBase; if (b) b.nom = nom.textContent; } // 73-06 : le nom du dépôt va à la base du titre, que compose 90-vf-titre.js

  // ---------- bloc de vue racine (P78-D-03) : dit ce que montre la vue, jamais le nom du projet — même sans git ----------
  const TAB = G.meta.vfTab === 'project' ? 'project' : G.meta.vfTab === 'equipe' ? 'equipe' : 'code';
  const pl = (n, mot) => `${n} ${mot}${n > 1 ? 's' : ''}`;
  const AIDE_BRANCHE = "Branche : une ligne de travail du dépôt. HEAD détaché : le dossier n'est sur aucune branche, il est posé sur un commit précis.";
  const AIDE_MISSIONS = "Missions : les plans de bataille en cours dans .planning/missions. Les agents (sessions et sous-agents) sont comptés à part, dans la ligne du dessous et sur les cartes.";
  const texteVue = () => {
    const VF = G.meta.vf || {}, depot = V && (V.etat === 'ok' || V.etat === 'indisponible'); // un dépôt détecté ; sinon « dossier »
    if (TAB === 'code') {
      const b = V && V.etat === 'ok' ? (V.detache ? 'HEAD détaché' : V.branche ? `branche ${V.branche}` : '') : '';
      return { k: 'Code', h1: b ? `Le code, ${b}` : 'Le code du projet', aide: b ? AIDE_BRANCHE : '', // PU-G-193 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-06, Q3) : les termes Git restent, définis au survol
        p: `${pl((G.files || []).length, 'fichier')} et ${pl((G.routes || []).length, 'route')} lus dans le ${depot ? 'dépôt' : 'dossier'}.` };
    }
    if (TAB === 'project') { // P78-D-03 : le sous-titre résume la vue (phase en cours, phases faites sur le total du jalon), il ne redit jamais le titre
      const L = Array.isArray(VF.milestones) ? VF.milestones : [], m = L.find((x) => x.key === VF.milestone && x.st !== 'done') || L.find((x) => x.st === 'active') || L[L.length - 1], fait = m && m.total > 0 ? `${pl(m.done, 'phase')} ${m.done > 1 ? 'faites' : 'faite'} sur ${m.total}` : '';
      const c = VF.counts || {}, tout = typeof c.phases === 'number' && typeof c.plans === 'number' ? `${pl(c.phases, 'phase')} · ${pl(c.plans, 'plan')}` : '';
      const p = [VF.phase ? `Phase ${VF.phase}${/^(executing|in_progress|verifying)$/.test(String(VF.status)) ? ' en cours' : ''}` : '', fait].filter(Boolean).join(', ');
      return { k: 'Projet', h1: VF.milestone ? `Jalon ${VF.milestone}` : 'Le projet', p: p ? p + '.' : tout ? tout + '.' : '' };
    }
    const M = Array.isArray(VF.missions) ? VF.missions : [], c = VF.compte || {};
    const repos = !M.length && !c.actif && !c.enAttente && !c.attend; // aucune mission et personne au travail (ni qui vous attende)
    // PU-G-166 : le titre compte les MISSIONS (nœuds `mission` actifs du graphe Projet, un plan = une mission) ; « actifs » compte les AGENTS (sessions et sous-agents actifs de l'écoute des sessions) : la ligne le dit
    const R = window.__vfEquipeRendu, agents = typeof c.actif === 'number' && R ? R.ligneAgents(c) : G.project.summary || '';
    return { k: 'Équipe', h1: R ? R.titreEquipe(M, c) : M.length === 1 ? `Mission : ${M[0]}` : M.length > 1 ? `${M.length} missions en cours` : 'Aucune mission en cours', aide: AIDE_MISSIONS, p: repos ? "L'équipe est au repos." : agents };
  };
  // S6 (revue de la recette du 2026-11-08) : tiroir Git ouvert (body.vf-git-ouvert), le titre est masqué dessous (opacity 0, 77-vf-git-tiroir.js) ; il ne reste pas un arrêt de Tab (focus invisible, bulle par-dessus le tiroir) ; le tabindex revient à la fermeture ; F6a (3e tour) : il ne revient que si le titre porte encore une définition (data-vf-aide), jamais sur le seul fait qu'il en a porté une (un dépôt « indisponible » la retire : le titre n'est alors plus un arrêt)
  const tabTitre = () => { const h1 = document.querySelector('#context h1'); if (!h1 || !h1.dataset.vfAide) return; if (document.body.classList.contains('vf-git-ouvert')) h1.removeAttribute('tabindex'); else h1.tabIndex = 0; };
  new MutationObserver(tabTitre).observe(document.body, { attributes: true, attributeFilter: ['class'] });
  const ecrireVue = () => { // réécrit le bloc que renderContext vient de poser ; sous-vues et réponses (q:answer) inchangées
    const ctx = document.querySelector('#context'), k = ctx && ctx.querySelector('.k'), h1 = ctx && ctx.querySelector('h1');
    if (!k || !h1) return;
    const t = texteVue();
    k.textContent = t.k; h1.classList.add('vf-ctx-titre');
    // PU-G-193 (recette du 2026-11-08) : la définition du titre (Branche, HEAD détaché ; Missions) se montre aussi au focus clavier : le titre est atteignable par Tab et sa bulle lit la définition de la vue courante
    const R = window.VFGitRendu;
    if (t.aide) { h1.setAttribute('title', t.aide); h1.setAttribute('aria-description', t.aide); h1.dataset.vfAide = t.aide; if (R && R.aideFocus && !h1.dataset.vfAideLie) { h1.dataset.vfAideLie = '1'; R.aideFocus(h1, () => h1.dataset.vfAide || ''); } tabTitre(); }
    else { h1.removeAttribute('title'); h1.removeAttribute('aria-description'); delete h1.dataset.vfAide; if (h1.dataset.vfAideLie) h1.removeAttribute('tabindex'); } // aide en texte constant, jamais le nom de la branche
    h1.replaceChildren(); // F13, PU-G-042 : le titre se coupe d'abord après « / » (un <wbr>, élément DOM, jamais de HTML) ; un morceau à traits d'union (.vf-ctx-seg, inline-block) reste d'un bloc tant qu'il tient, et ne se coupe après un trait d'union que s'il dépasse seul la ligne ; textContent reste le texte exact
    t.h1.split(/(?<=[ /])/).forEach((m, i, a) => {
      const [, mot, esp] = /^([^ ]*)( *)$/.exec(m) || [, m, ''];
      if (i && a[i - 1].endsWith('/')) h1.appendChild(document.createElement('wbr'));
      if (mot.includes('-')) { const sg = document.createElement('span'); sg.className = 'vf-ctx-seg'; // bloc insécable : le trait d'union ne coupe que si le morceau seul dépasse la ligne
        mot.split(/(?<=-)/).forEach((x, j) => { if (j) sg.appendChild(document.createElement('wbr')); sg.appendChild(document.createTextNode(x)); }); h1.appendChild(sg); } else h1.appendChild(document.createTextNode(mot));
      if (esp) h1.appendChild(document.createTextNode(esp));
    });
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
  // Le rendu du viewer cadre la vue (fit) avec le bloc NATIF, puis émet « render » en microtâche : ecrireVue raccourcit alors le bloc, et le haut de la zone libre (freeArea) bouge sous une vue cadrée pour l'ancien.
  // Une vue qui était exactement le cadrage de l'ancienne zone est recadrée sur la nouvelle ; toute autre vue (déplacée, zoomée par la personne) reste où elle est.
  const cadrage = () => { const b = SC.state && SC.state.bounds, T = SC.state && SC.state.t; if (!b || !T) return null; const a = SC.freeArea(), k = Math.min(a.w / (b.w + 40), a.h / (b.h + 20), 1.1); return { y: a.y, cadree: Math.abs(T.k - k) <= k * 0.005 && Math.abs(T.x - (a.x + (a.w - b.w * k) / 2 - b.x * k)) <= 1 && Math.abs(T.y - (a.y + Math.max(0, (a.h - b.h * k) / 2) - b.y * k)) <= 1 }; };
  const ecrireEtRecadrer = () => { const avant = cadrage(); ecrireVue(); const apres = avant && avant.cadree ? cadrage() : null; if (apres && apres.y !== avant.y) SC.fit(false); };
  const styleVue = document.createElement('style');
  styleVue.textContent = '.vf-ctx-titre { display: -webkit-box; -webkit-box-orient: vertical; -webkit-line-clamp: 2; overflow: hidden; overflow-wrap: anywhere; }\n.vf-ctx-seg { display: inline-block; max-width: 100%; vertical-align: top; overflow-wrap: anywhere; }';
  document.head.appendChild(styleVue);
  // le premier rendu attend DOMContentLoaded (donc ce fichier) ; la réécriture à l'arrivée du fichier est un garde défensif et idempotent, puis « render » et « ready » prennent le relais
  SC.on('render', (e) => { if (e && e.container === 'root') ecrireEtRecadrer(); });
  SC.on('ready', () => { if (SC.state && SC.state.container === 'root') ecrireEtRecadrer(); });
  if (SC.state && SC.state.container === 'root') ecrireEtRecadrer();
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
    .vf-git-ligne-etat { flex: none; white-space: pre; }
    .vf-git-wt { flex: 0 2 auto; white-space: pre; } /* l'espace avant le point médian est le premier caractère de l'élément : sans white-space: pre il s'effondre en tête d'élément flex */
    .vf-git-ligne .kbd { color: var(--text-2); margin-left: 6px; opacity: 0; transition: opacity 150ms var(--ease); flex: none; }
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
    /* P78-D-39 (amende P70-D-16, arbitrage Samuel, AskUserQuestion session principale, 2026-11-06) : 152 px de plancher et une invite courte, de 1000 à 1279 px et seulement quand l'ouvreur est posé (header[data-vf-git]) ;
       l'invite d'origine est masquée, jamais réécrite : hors de la plage ou sans Git, la requête ne s'applique plus et l'original (et ses 200 px) reviennent */
    @media (min-width: 1000px) and (max-width: 1279px) and (not (pointer: coarse)) {
      header[data-vf-git] .hc { min-width: 152px; }
      header[data-vf-git] #search-btn[data-vf-invite] .st { display: none; }
      header[data-vf-git] #search-btn[data-vf-invite]::after { content: attr(data-vf-invite); order: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
      header[data-vf-git] #search-btn[data-vf-invite] .kbd { order: 2; }
    }
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
  const spEtat = document.createElement('span'); spEtat.className = 'vf-git-ligne-etat';
  const kbd = document.createElement('span'); kbd.className = 'kbd'; kbd.textContent = 'g'; kbd.setAttribute('aria-hidden', 'true');
  ligne.append(spBranche, spWt, spEtat, kbd);
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

  const entete = document.querySelector('header'), recherche = document.querySelector('#search-btn');
  if (recherche) recherche.setAttribute('data-vf-invite', 'Chercher…'); // P78-D-39 : libellé court, lu par la requête de 1000 à 1279 px (voir le style) ; inerte ailleurs
  const sans = (o) => { const c = Object.assign({}, o); delete c.schema; return JSON.stringify(c); };
  let connue = V && V.etat === 'ok' ? V : null; // PU-G-003 : dernière lecture CONFIRMÉE (branche, worktree) ; une lecture « indisponible » (git muet, machine chargée) ne l'efface jamais
  const lire = (d) => {
    const change = sans(V) !== sans(d); V = d;
    if (change && TAB === 'code') ecrireEtRecadrer(); // le bloc de vue Code cite la branche de la même lecture que la seconde ligne
    if (entete) entete.toggleAttribute('data-vf-git', d.etat !== 'absent'); // l'ouvreur est posé : le plancher et l'invite courts s'appliquent
    if (d.etat === 'absent') { connue = null; ligne.hidden = true; ouvreur.hidden = true; return; } // le dépôt a disparu en cours de route : tout se tait
    ligne.hidden = false; ouvreur.hidden = false;
    if (d.etat === 'ok') connue = d;
    const indispo = d.etat === 'indisponible' && !connue; // rien de connu : « Branche indisponible »
    const nonConfirme = d.etat === 'indisponible' && !!connue; // dernière valeur gardée, un glyphe et un mot en texte neutre (ni halo, ni couleur)
    const c = connue && d.etat === 'indisponible' ? connue : d;
    const nomBranche = c.detache ? `HEAD détaché · ${c.sha7 || ''}` : String(c.branche || '');
    const texteBranche = indispo ? 'Branche indisponible' : nonConfirme ? `○ ${nomBranche}` : nomBranche;
    spBranche.textContent = texteBranche;
    spWt.textContent = c.worktree && !indispo ? ` · worktree ${c.worktree}` : '';
    spEtat.textContent = nonConfirme ? ' · non confirmée' : '';
    const lisible = indispo ? 'branche indisponible' : (c.detache ? 'HEAD détaché' : 'branche ' + c.branche) + (nonConfirme ? ', lecture non confirmée' : '');
    ligne.title = texteBranche + spWt.textContent + spEtat.textContent;
    ligne.setAttribute('aria-label', `Historique Git, ${lisible}. Ouvrir (g)`);
    ouvreur.setAttribute('aria-label', `Historique Git, ${lisible}. Ouvrir (g)`); ouvreur.title = ouvreur.getAttribute('aria-label');
    ligne.classList.toggle('vf-git-detache', !!c.detache && !indispo);
    ligne.classList.toggle('vf-git-indispo', indispo || nonConfirme);
  };
  lire(V);

  const basculer = (source) => window.dispatchEvent(new CustomEvent('vf-git:basculer', { detail: { source } }));
  ligne.addEventListener('click', () => basculer('ligne'));
  ouvreur.addEventListener('click', () => basculer('ouvreur'));
  window.addEventListener('vf-git:etat', (e) => { const o = String(!!(e.detail && e.detail.ouvert)); ligne.setAttribute('aria-expanded', o); ouvreur.setAttribute('aria-expanded', o); });
  const valide = (d) => d && typeof d === 'object' && (d.etat === 'ok' || d.etat === 'indisponible' || d.etat === 'absent');
  window.addEventListener('vf-git:entete', (e) => { if (valide(e.detail)) lire(e.detail); });
  const relire = () => { // GET /api/vf/git/entete avec le jeton ; réponse hors schéma : ignorée
    const SRV = window.FLOORPLAN_SERVER;
    if (!SRV || !SRV.token) return;
    fetch('/api/vf/git/entete', { headers: { 'x-floorplan-token': SRV.token }, cache: 'no-store' })
      .then((r) => (r.ok ? r.json() : null)).then((j) => { if (j && j.schema === 'vibeflow/cockpit-git-entete@1' && valide(j)) lire(j); }).catch(() => {});
  };
  document.addEventListener('vf-git:signal', () => { // relecture de l'en-tête (le serveur vérifie le jeton) ; réponse hors schéma : ignorée
    relire();
  });
  relire(); // chargement : la page assemblée peut dater d'avant un `git switch`, une seule lecture par chargement
})();
