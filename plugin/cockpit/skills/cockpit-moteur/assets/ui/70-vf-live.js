// VibeFlow (67-04) : le direct, sur le port de la page. Écoute /api/vf/events (SSE, même origine, jeton de la
// page) et applique les statuts dans la page ouverte sans la recharger : on modifie le graphe en place puis
// Floorplan.rerender() garde le zoom, la position et la sélection. Changement de structure → rechargement (la
// vue vit dans le hash). Badge « au travail » dans l'en-tête, sur les trois onglets. La dernière commande d'une
// session n'est jamais dans le flux : elle se demande à l'unité (/api/vf/doing, jeton en en-tête), et reste
// dans la ligne cliquée (ni graphe, ni localStorage, ni export). Flux coupé : un seul sondage pour les deux flux (celui-ci et le
// rechargement du viewer), à recul — 1 s pendant 30 s, puis 5 s ; le message « Réessayer » arrive à 15 s et se retire seul au retour du serveur (AUDC-M9), le sondage s'arrête à 300 s (E-6).
(() => {
  const SC = window.Floorplan, SRV = window.FLOORPLAN_SERVER;
  // page exportée ou ouverte en fichier : pas de serveur, pas de direct
  if (!SC || !SRV || !SRV.token || typeof EventSource === 'undefined') return;
  const G = SC.graph, h = SC.h;
  const TAB = G.meta.vfTab === 'project' ? 'project' : 'code';
  const probe = (window.__vfLive = { connected: false, patches: 0, applied: 0, lastLatencyMs: null, lock: null, structural: 0, who: null, sondages: 0, abandon: false,
    reco: { vite: 1000, lent: 5000, bascule: 30000, banniere: 15000, fin: 300000 } }); // reco : en ms, modifiable par un test ; banniere : le message arrive à 15 s (AUDC-M9), le sondage s'arrête à fin
  const FRAICHEUR = 'Sessions écrites depuis moins de 3 min';
  const NB = '\u00a0';

  const style = document.createElement('style');
  style.textContent = `
    #vf-lock { font: 500 12px/1 var(--mono, monospace); gap: var(--sp-6); }
    #vf-lock .dot { width: 8px; height: 8px; border-radius: 50%; background: var(--text-4); display: inline-block; }
    #vf-lock.held .dot { background: var(--st-active); animation: vfpulse 1.6s ease-in-out infinite; }
    #vf-lock.off .dot { background: var(--st-blocked); }
    @keyframes vfpulse { 50% { opacity: .25; } }
    /* D2 (recette 2026-11-02) : le tiroir reprend la marge des panneaux ouverts par showPanel (.sec : 18px 20px 6px, 22 px en premier et dernier enfant) ; sur grand écran sa boîte suit son contenu (plafonnée à la fenêtre, défilement au-delà) au lieu de s'étirer jusqu'en bas.
       Sous 701 px le panneau est un tiroir du bas dont la mise en page appartient au viewer : on n'y touche pas. */
    .vf-whop { --fil: rgba(var(--ink), .2); padding: var(--inset-panel); }
    @media (min-width: 701px) { #panel:has(> .vf-whop) { bottom: auto; max-height: calc(100vh - var(--hh, 64px) - 20px); overflow: auto; } }
    .vf-whop h3 { margin: 0; } .vf-whop h4 { margin: var(--sp-16) 0 var(--sp-6); color: var(--text-3); }
    .vf-whop .sr { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }
    .sec button[data-vf-doing], .sec button[data-vf-transcript] { font: inherit; font-size: 12px; cursor: pointer; padding: var(--sp-4) var(--sp-12); border-radius: 8px; border: 1px solid rgba(var(--ink), .15); background: transparent; color: var(--text-2); margin: var(--sp-6) var(--sp-6) 0 0; transition: background .2s var(--ease), color .2s var(--ease); }
    .sec button[data-vf-doing]:hover, .sec button[data-vf-transcript]:hover { background: rgba(var(--ink), .07); color: var(--text); } .sec button[data-vf-doing]:focus-visible, .sec button[data-vf-transcript]:focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; }
    /* Q12a : les liens « Nœud … » et « Voir dans l'onglet Équipe » s'alignent sur la colonne de texte (le retrait de 12 px vient du padding de .vf-link, fait pour la liste « Sources lues ») */
    body.vf-tab-equipe .sec > a.vf-link { padding: var(--sp-6) 0; margin-inline: 0; }
    .vf-whop .src { color: var(--text-4); font-size: 11px; margin-top: var(--sp-16); }
    a.vf-link { text-decoration: underline; text-decoration-color: rgba(var(--ink), .35); text-underline-offset: 3px; }
    /* 71.5 (juge de rendu, 2026-11-06) : la pastille d'état (glyphe + mot) d'un lien n'est jamais soulignée ; seul le libellé qui l'accompagne l'est */
    a.vf-link:has(> .vst) { text-decoration: none; }
    a.vf-link:has(> .vst) > :not(.vst) { text-decoration: underline; text-decoration-color: rgba(var(--ink), .35); text-underline-offset: 3px; }
    a.vf-link:has(> .vst):hover > :not(.vst) { text-decoration-color: currentColor; }
    a.vf-link:hover { color: var(--text); text-decoration-color: currentColor; } a.vf-link:focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; }
    .vf-nr { white-space: nowrap; }
    .vf-transcript { max-height: 320px; overflow-y: auto; margin-top: var(--sp-8); font-size: 12px; color: var(--text-2); }
    .vf-transcript h4 { margin: var(--sp-12) 0 var(--sp-4); color: var(--text-3); } .vf-transcript > h4:first-child { margin-top: 0; } .vf-transcript p, .vf-transcript li { margin: var(--sp-2) 0; word-break: break-word; }
    .vf-transcript ul { margin: var(--sp-4) 0 0; padding-left: var(--sp-16); }
    .vf-transcript pre { margin: 0; white-space: pre-wrap; word-break: break-word; font-family: var(--mono, monospace); }
    #vf-reco { position: fixed; left: 50%; bottom: 96px; /* dérivé : au-dessus de la barre de question */ transform: translateX(-50%); z-index: 60; display: flex; align-items: center; gap: var(--sp-12); max-width: calc(100vw - 2 * var(--edge)); padding: var(--inset-box) var(--inset-box) var(--inset-box) var(--sp-16); border-radius: 20px; font-size: 13px; line-height: 1.5; color: var(--text); }
    #vf-reco button { flex: none; border: 0; border-radius: 999px; padding: var(--sp-8) var(--sp-16); cursor: pointer; font: inherit; font-size: 12.5px; background: var(--on); color: var(--on-text); }`;
  document.head.appendChild(style);

  let badge = null, who = null;
  const lockText = (l) => {
    const held = tenusDe(l);
    if (!held.length) return { cls: '', text: 'Driver libre', title: "Personne n'a la main" };
    const x = held[0];
    return { cls: 'held', text: `${x.owner || '?'} · ${x.step || ''} · ${x.ageS ?? '?'} s`, title: held.map((y) => `${[y.scope === 'depot' ? 'dépôt' : y.scope, y.ws].filter(Boolean).join(' ')}${y.scope || y.ws ? ' : ' : ''}${y.owner || '?'}${y.step ? ` (${y.step})` : ''}`).join('\n') }; // lab plat : pas de scope, jamais « undefined : … » ; recette 68 R12 (P68-D-35, arbitrage Samuel, AskUserQuestion session principale Claude Code, 2026-11-04) : la portée « depot » s'affiche « dépôt » (libellé seul, la valeur scope du JSON reste depot)
  };
  // A15 : le flux `lock` et `hello` portent { seq, at, verrous: { etat, plat, liste } }, liste blanche construite par le serveur
  // (owner, step, ageS, scope, ws, phase, leaseS, sansSession) ; une seule aide la lit
  const tenusDe = (l) => (Array.isArray(l?.verrous?.liste) ? l.verrous.liste.filter((x) => x && typeof x === 'object') : []);
  const KIND = { session: 'Session', subagent: 'Sous-agent', lock: 'Verrou', registered: 'Enregistré', 'dag-node': 'Nœud de DAG' };
  const duree = (s) => window.__vfEquipeRendu.duree(s); // le format vit dans 71-vf-equipe-rendu.js (chargé après ce fichier, appelé après)
  const AGENT = (w) => w.kind === 'session' || w.kind === 'subagent';
  // « au travail » : un agent (session ou sous-agent) `actif` ; ni verrou, ni nœud de DAG, ni terminé, ni agent en attente (P69-D-14, P69-D-33). Même prédicat que
  // les effectifs de l'onglet Équipe (71-vf-equipe-rendu.js) : pour une même collecte, le badge égale « actifs ».
  const auTravail = (w) => window.__vfEquipeRendu.actif(w);
  // P68-D-39 : le verrou se lit dans le flux `lock` (rafraîchi à chaque événement), jamais dans l'ageS du `who`, figé tant que la liste ne change pas (whoSig l'exclut) ;
  // il se retrouve par son propriétaire (et sa portée quand plusieurs verrous ont le même)
  const verrouDe = (w) => {
    const tenus = tenusDe(probe.lock).filter((x) => x.owner === w.id);
    // correspondance EXACTE sur la portée et le compartiment (M-3), jamais par sous-chaîne (`fiabilite` n'est pas `fiabilite-2`) : `tree` d'un compartiment se lit en mots
    // (mot 1 = le nom, mot 3 = la phase éventuelle, comme l'écrit vf-cockpit-who.mjs), celui d'un verrou sans compartiment est sa portée ; aucun libellé n'est reconstruit ici
    const mots = String(w.tree).split(' '), ph = (y) => /^[0-9]+(\.[0-9]+)*$/.test(String(y.phase)) ? String(y.phase) : '';
    return tenus.find((y) => y.ws ? mots[1] === y.ws && (mots[3] || '') === ph(y) : y.scope === w.tree) || (tenus.length === 1 ? tenus[0] : undefined);
  };
  // PU-G-179 : « tenu depuis » dit la date de PRISE (leaseS), jamais l'âge du dernier battement (ageS, qui repart à 0) ; absente : « tenu » sans durée
  const ageDe = (w) => (w.kind !== 'lock' ? w.ageS : typeof verrouDe(w)?.leaseS === 'number' ? verrouDe(w).leaseS : null);
  const tenuDepuis = (n) => (typeof n === 'number' ? 'tenu depuis' + NB + h(duree(n)) : 'tenu');
  // le détenteur d'un verrou (PU-G-177, 179) : une session de la collecte se nomme par son titre, jamais par son identifiant brut ; un verrou que le serveur dit sans session de la collecte (`sansSession`) dit « aucune session active »
  // (une session muette sans enfant n'est pas dans `who` : ni « orphelin » ni « introuvable » ; liste d'identifiants vide, ou collecte pas encore reçue : le serveur ne dit rien, aucun verdict)
  const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-/i;
  const sessions = () => (who?.workers || []).filter((w) => w.kind === 'session');
  const detenteur = (id) => (sessions().some((s) => s.id === id) ? window.__vfEquipeRendu.nomDeSession(who.workers, id) : UUID.test(String(id)) ? null : id || null);
  const sansSession = (x) => x?.sansSession === true;
  // verrous et nœuds : un verrou dit « tenu depuis … » (durée au sens explicite) ; un nœud de DAG périmé n'est plus montré (P71.5-D-14), un nœud récent reste (aucun agent ne le porte forcément)
  const ligneVerrou = (w) => { const nom = detenteur(w.id), vide = sansSession(verrouDe(w)), gl = window.__vfEquipeRendu.glyphe;
    return `<li><span>${vide ? gl('orphelin', 'aw-s-orphelin') : ''}<b>${h(w.kind === 'lock' && w.tree === 'depot' ? 'dépôt' : String(w.tree || '').replace(/^compartiment /, ''))}</b>${nom ? ' · ' + h(nom) : ''}</span><span class="n">${vide ? 'aucune session active · ' : ''}${tenuDepuis(ageDe(w))}</span></li>`; };
  const ligneOrph = (w) => `<li><span>${window.__vfEquipeRendu.glyphe('orphelin', 'aw-s-orphelin')}<b>${h(w.role || 'Agent')}</b>${w.task ? ' · ' + h(w.task) : ''}</span><span class="n">orphelin ?${typeof w.ageS === 'number' ? ` · consigné depuis${NB}${h(duree(w.ageS))}` : ''}</span></li>`; // PU-G-182 : le registre dit « jamais fermé », pas « processus mort » : le « ? » est exact
  const ligneNoeud = (w) => `<li><span><b>${h(KIND[w.kind] || w.kind)}${w.role ? ' · ' + h(w.role) : ''}</b>${w.task ? ' · ' + h(w.task) : ''}</span><span class="n">${h(duree(ageDe(w)))}</span></li>`;
  const pluriel = (n, un, plusieurs) => `${n} ${n > 1 ? plusieurs : un}`;
  const driverLigne = () => {
    const tenus = tenusDe(probe.lock);
    if (!tenus.length) return '<p class="aw-driver"><span class="t">' + "Personne n'a la main" + '</span></p>';
    const x = tenus[0], nom = detenteur(x.owner) || (UUID.test(String(x.owner)) ? 'non listée' : '?'); // PU-G-177 : la session qui pilote, en clair
    return `<p class="aw-driver"><span class="d"></span><span class="t">Session qui pilote : ${h(nom)}${x.step ? ' · ' + h(x.step) : ''}</span><span class="n">${tenuDepuis(x.leaseS)}</span></p>`;
  };
  // le CSS du tiroir vit avec ses rendus (71-vf-equipe-rendu.js, chargé après ce fichier) : posé une fois, au premier dessin
  let cssPose = false;
  const poserCss = () => { if (cssPose) return; cssPose = true; const st = document.createElement('style'); st.textContent = window.__vfEquipeRendu.css; document.head.appendChild(st); };
  const htmlTiroir = () => {
    poserCss();
    const ws = who?.workers || [], act = ws.filter(auTravail), reste = ws.filter((w) => !AGENT(w));
    const finis = ws.filter((w) => AGENT(w) && w.etat === 'termine').length;
    const verrous = reste.filter((w) => w.kind === 'lock'), orph = reste.filter((w) => w.orphan), autres = reste.filter((w) => w.kind !== 'lock' && !w.orphan && !w.stale && !(w.kind === 'dag-node' && act.length)); // un nœud en cours est déjà porté par l'agent qui le travaille
    const SOURCES = { sessions: 'Sessions et sous-agents', locks: 'Verrous du dépôt', dags: 'Plans de la mission' }; // clés de la collecte, jamais affichées telles quelles (P70-D-04)
    // PU-G-180 : le pied ne dit rien quand tout est lu et ne nomme qu'une source illisible (une source absente n'est pas une panne)
    const mal = Object.entries(who?.sources || {}).filter(([, v]) => v && (v.etat === 'erreur' || v.etat === 'forme-inconnue')).map(([k]) => SOURCES[k] || k);
    const src = mal.length ? `${mal.length > 1 ? 'Sources illisibles' : 'Source illisible'} : ${mal.join(', ')}` : '';
    const arbre = window.__vfEquipeRendu.arbre(ws, h);
    return (`<div class="vf-whop"><div class="aw-head"><h3>Au travail</h3><span class="aw-count"><b>${act.length}</b> ${act.length > 1 ? 'actifs' : 'actif'} · ${pluriel(finis, 'terminé', 'terminés')}</span></div>${window.__vfEquipeRendu.surveiller(ws)}${driverLigne()}`
      + `${act.length ? '' : '<p>Personne ne travaille en ce moment</p>'}${arbre}`
      + `${verrous.length ? `<div class="aw-sec2"><span>Qui a la main</span><span>${verrous.length}</span></div><p class="aw-aide">Un verrou évite que deux sessions modifient la même chose en même temps : rien à faire de votre côté.</p><ul class="r-verr">${verrous.map(ligneVerrou).join('')}</ul>` : ''}`
      + `${orph.length ? `<div class="aw-sec2"><span>Agents sans verrou tenu</span><span>${orph.length}</span></div><ul class="r-verr">${orph.map(ligneOrph).join('')}</ul>` : ''}`
      + `${autres.length ? `<div class="aw-sec2"><span>Nœuds du plan</span><span>${autres.length}</span></div><ul class="r-verr">${autres.map(ligneNoeud).join('')}</ul>` : ''}`
      + `<p class="aw-foot">${h(FRAICHEUR)}, terminés depuis moins de 24${NB}h. Transcript${NB}: dans l'onglet Équipe.</p>${src ? `<p class="src">${h(src)}</p>` : ''}</div>`);
  };
  // replis : l'ensemble des parents repliés vit dans la mémoire de la page (ni graphe, ni stockage, ni export) ; reposé après chaque dessin du tiroir
  const replies = new Set();
  const appliquerReplis = () => {
    for (const b of document.querySelectorAll('.vf-whop [data-vf-repli]')) {
      const clos = replies.has(b.dataset.vfRepli), ul = document.getElementById(b.getAttribute('aria-controls'));
      b.setAttribute('aria-expanded', String(!clos)); if (ul) ul.hidden = clos; b.closest('li')?.classList.toggle('closed', clos);
    }
  };
  let dernier = '';
  const whoPanel = () => { dernier = htmlTiroir(); SC.showPanel(dernier); appliquerReplis(); };
  // tant que le tiroir est ouvert il suit le flux : redessiné à chaque `who` qui change l'arbre, l'état ou la dernière action (pas d'image identique), en gardant le défilement
  // et l'état replié ou déplié des « Terminés » ; les commandes demandées sont reposées par le rappel de l'événement `panel` ci-dessous
  const cleDe = (d) => d.closest('[data-vf-agent]')?.dataset.vfAgent || ''; // le bloc « Terminés » est repéré par l'agent qui le porte (stable quand un terminé s'y ajoute)
  const redessiner = () => {
    if (!document.querySelector('.vf-whop') || document.body.classList.contains('no-panel')) return; // tiroir fermé ou remplacé : on ne le rouvre pas
    const html = htmlTiroir();
    if (html === dernier) return;
    const p = document.getElementById('panel'), haut = p ? p.scrollTop : 0;
    const ouverts = new Set([...document.querySelectorAll('.vf-whop details.vf-termines[open]')].map(cleDe));
    dernier = html; SC.showPanel(html); appliquerReplis();
    for (const d of document.querySelectorAll('.vf-whop details.vf-termines')) if (ouverts.has(cleDe(d))) d.open = true;
    for (const e of document.querySelectorAll('#panel > *')) e.style.animation = 'none';
    if (p) p.scrollTop = haut;
  };
  // AUDC-D3 : entre deux poussées, l'âge des agents avance dans la page : le tiroir ouvert est recalculé toutes les 30 s (aucun dessin si le texte est identique)
  if (typeof setInterval === 'function') setInterval(() => { if (!document.hidden) redessiner(); }, 30000); // `typeof` : le harnais vm de test-cockpit-equipe.sh (EUI) n'a pas de minuterie
  // révélation ponctuelle : la réponse reste affichée tant que sa ligne l'est. Elle est gardée en mémoire de la page seulement (ni graphe, ni stockage, ni export) et reposée
  // par l'événement `panel` du moteur dès que le panneau est redessiné : le tiroir et le panneau d'un agent sont redessinés à chaque `who`, et une réponse qui arrive pendant un redessin
  // ne doit pas tomber dans une ligne détachée (recette 2026-11-03)
  const demandes = new Map();
  const poser = (b) => {
    const t = demandes.get(b.dataset.vfDoing), z = b.nextElementSibling;
    if (t !== undefined && z && z.classList.contains('vf-doing') && z.textContent !== t) { z.textContent = t; z.hidden = false; }
  };
  // rien à reposer tant qu'aucune commande n'a été demandée
  // focus clavier (UIFN-12) : chaque `who` redessine le panneau et le tiroir, le bouton focalisé est remplacé et le focus tombe sur le corps de la page.
  // On retient la clé du bouton « Voir la dernière commande » / « Lire le transcript » qui a le focus ; après un redessin, si le focus est perdu, il revient au bouton de même clé.
  // Un focus qui s'en va ailleurs (bouton encore dans la page) efface la clé : jamais de focus volé à quelqu'un qui est parti.
  const BTN = '[data-vf-doing],[data-vf-transcript],[data-vf-repli]', DANS_PANNEAU = '#panel [data-vf-doing],#panel [data-vf-transcript],#panel [data-vf-repli]';
  const cleBtn = (b) => (b.dataset.vfDoing !== undefined ? 'doing:' + b.dataset.vfDoing : b.dataset.vfRepli !== undefined ? 'repli:' + b.dataset.vfRepli : 'transcript:' + b.dataset.vfTranscript);
  let cleFocus = null;
  document.addEventListener('focusin', (ev) => { const b = ev.target.closest?.(DANS_PANNEAU); cleFocus = b ? cleBtn(b) : ev.target.matches?.('#panel > .vf-whop h3') ? 'titre' : null; }); // 'titre' : le focus posé sur le titre du tiroir à son ouverture (73-vf-tiroir-travail.js, PU-G-203) survit lui aussi à un redessin
  document.addEventListener('focusout', (ev) => { const b = ev.target; if (b.matches?.(BTN)) queueMicrotask(() => { if (b.isConnected && document.activeElement !== b) cleFocus = null; }); });
  const rendreFocus = () => {
    if (!cleFocus || (document.activeElement && document.activeElement !== document.body)) return;
    const b = cleFocus === 'titre' ? document.querySelector('#panel > .vf-whop h3') : [...document.querySelectorAll(DANS_PANNEAU)].find((x) => cleBtn(x) === cleFocus);
    if (b) { if (cleFocus === 'titre') b.tabIndex = -1; b.focus({ preventScroll: true }); }
  };
  SC.on('panel', () => { rendreFocus(); if (demandes.size) for (const b of document.querySelectorAll('#panel [data-vf-doing]')) poser(b); }); // 79-17 : l'événement panel du moteur, synchrone après chaque dessin du panneau
  document.addEventListener('click', (ev) => {
    const r = ev.target.closest?.('.vf-whop [data-vf-repli]');
    if (!r) return;
    const id = r.dataset.vfRepli; if (replies.has(id)) replies.delete(id); else replies.add(id);
    appliquerReplis();
  });
  document.addEventListener('click', async (ev) => {
    const b = ev.target.closest?.('[data-vf-doing]');
    if (!b) return;
    const id = b.dataset.vfDoing;
    if (b.getAttribute('aria-disabled') === 'true') return; // lecture en cours : les clics répétés sont ignorés
    b.setAttribute('aria-disabled', 'true'); // jamais `disabled` : un bouton focalisé désactivé perd le focus clavier (UIFN-12, même défaut que « Lire le transcript »)
    let texte;
    try {
      const r = await fetch('/api/vf/doing?id=' + encodeURIComponent(id), { headers: { 'x-floorplan-token': SRV.token }, cache: 'no-store' });
      const d = r.ok ? await r.json() : null;
      // `doing` vide : le serveur remonte à la dernière commande Bash de la session ; sans appel Bash lisible il n'y a rien à montrer, jamais un texte de l'assistant en repli (D3)
      texte = d?.doing || (d?.erreur === 'inconnu' ? 'Plus active : rien à montrer.' : d?.erreur === 'sans-action' ? "Aucune commande récente." : 'Indisponible.');
    } catch { texte = 'Indisponible.'; }
    if (demandes.size >= 50) demandes.delete(demandes.keys().next().value);
    demandes.set(id, texte);
    for (const x of document.querySelectorAll('[data-vf-doing]')) if (x.dataset.vfDoing === id) { poser(x); x.removeAttribute('aria-disabled'); }
    b.removeAttribute('aria-disabled');
  });
  const showLock = (l, off) => {
    if (l !== undefined) probe.lock = l;
    if (!badge) badge = SC.addHeaderButton({ id: 'vf-lock', label: '…', title: 'Qui est au travail', onClick: whoPanel });
    const t = off ? { cls: 'off', text: 'Direct coupé', title: 'Le serveur du cockpit ne répond pas' } : lockText(probe.lock);
    const n = (who?.workers || []).filter(auTravail).length;
    badge.className = 'btn ' + (off ? 'off' : n ? 'held' : t.cls); badge.title = off ? t.title : `${n ? n + ' au travail' : 'Personne au travail'} · ${t.title}`;
    // compact : le détail (propriétaire du verrou, étape, durée) est dans l'infobulle et dans le panneau « Au travail »
    badge.setAttribute('aria-label', off ? t.text : n ? `${n} au travail` : 'Personne au travail'); // sinon figé à « … » (libellé de création) // AUDC-M9 : direct coupé = point « off » (jamais le point qui pulse « au travail »), même avec des agents actifs
    badge.innerHTML = `<span class="dot"></span><span class="bl">${off ? t.text : n ? `${n} au travail` : 'Personne'}</span>`;
    redessiner();
  };
  const setWho = (w) => { if (!w) return; who = probe.who = w; probe.whoAt = Date.now(); showLock(); document.dispatchEvent(new CustomEvent('vf-who')); }; // 69-05 : l'onglet Équipe (72-vf-equipe.js) suit le même flux

  // I3 (recette 2026-11-02) : une bascule en direct redessine la carte, qui rejouait son animation d'apparition (cartes, liens, colonnes,
  // panneau). On ne l'anime plus : les éléments redessinés portent `animation: none` en ligne AVANT la première image (la suite de
  // rerender() s'exécute en microtâche, avant la peinture), sauf les cartes dont l'état a basculé, qui reçoivent le clignotement du viewer
  // (`flash`). Zoom et position restent ceux de rerender() (keepTransform). Les éléments neufs d'une vraie navigation ne portent rien.
  const titreDe = (c) => c.querySelector('.title')?.textContent || '';
  const sansEntree = async () => {
    const avant = new Map([...document.querySelectorAll('#viewport .node .card')].map((c) => [titreDe(c), c.className]));
    await SC.rerender();
    for (const c of document.querySelectorAll('#viewport .node .card')) {
      const g = c.closest('g.node'), k = titreDe(c); // la carte porte aussi la classe node : on vise le groupe SVG
      if (g && avant.has(k) && avant.get(k) !== c.className) { g.classList.remove('flash'); g.classList.add('flash'); } else c.style.animation = 'none';
    }
    for (const e of document.querySelectorAll('#viewport .edges, #viewport .cols, #panel > *')) e.style.animation = 'none';
  };

  // onglet Projet, panneau d'un nœud de mission (`f:<dag>#<noeud>`) : les agents rattachés à ce nœud, lien vers leur carte (P69-D-15)
  if (G.meta.vfTab === 'project' && SC.addPanelSection) SC.addPanelSection('item', (id) => {
    if (typeof id !== 'string' || !id.startsWith('f:') || !id.includes('#')) return '';
    const l = window.__vfEquipeRendu.agentsDuNoeud(who?.workers, id, h);
    return l ? `<div class="sec"><h3>Agents sur ce nœud</h3>${l}</div>` : '';
  });
  const find = (ref) => ref.startsWith('n:') ? G.nodes.find((n) => n.id === ref.slice(2)) : G.files.find((f) => f.p === ref.slice(2));
  // ---------- reconnexion à recul : un seul sondage pour les deux flux ----------
  const lost = { t0: 0, timer: null, flux: new Map() };
  const sonder = async () => { // 'vivant' : même serveur, même jeton · 'redemarre' : le jeton a changé · 'coupe' : rien ne répond
    try { const r = await fetch('/api/vf/etat', { headers: { 'x-floorplan-token': SRV.token }, cache: 'no-store' }); return r.ok ? 'vivant' : 'redemarre'; } catch { return 'coupe'; }
  };
  const banniere = (on) => {
    let b = document.getElementById('vf-reco');
    if (!on) { b?.remove(); return; }
    if (b) return;
    b = document.createElement('div'); b.id = 'vf-reco'; b.className = 'glass'; b.setAttribute('role', 'alert');
    const t = document.createElement('span'); t.textContent = 'Le cockpit ne répond plus : le serveur est arrêté. Relancez-le (/vf-cockpit), puis réessayez.';
    const k = document.createElement('button'); k.type = 'button'; k.textContent = 'Réessayer'; k.onclick = () => { lost.t0 = Date.now(); probe.abandon = false; banniere(false); boucle(0); };
    b.append(t, k); document.body.appendChild(b);
  };
  const boucle = (delai) => {
    lost.timer = setTimeout(async () => {
      const age = Date.now() - lost.t0; probe.sondages++;
      const e = await sonder();
      if (e === 'redemarre') return location.reload(); // nouveau serveur, nouveau jeton : la page se recharge
      if (e === 'vivant') { for (const f of lost.flux.values()) f(); lost.flux.clear(); lost.timer = null; banniere(false); return; } // AUDC-M9 : le message se retire seul au retour du serveur
      if (Date.now() - lost.t0 >= probe.reco.fin) { lost.timer = null; probe.abandon = true; banniere(true); return; }
      if (Date.now() - lost.t0 >= probe.reco.banniere) banniere(true); // AUDC-M9 : dit à 15 s, pas à 300 s ; le sondage continue
      boucle(age < probe.reco.bascule ? probe.reco.vite : probe.reco.lent);
    }, delai);
  };
  // un flux qui tombe se ferme (le navigateur réessaierait chaque seconde, sans fin) et s'inscrit au sondage commun
  const perdu = (nom, reconnecter) => {
    probe.connected = false; showLock(null, true);
    lost.flux.set(nom, reconnecter);
    if (lost.timer === null && !probe.abandon) { lost.t0 = Date.now(); boucle(probe.reco.vite); }
  };
  window.FLOORPLAN_STREAM_LOST = perdu; // appelé par le rechargement automatique du viewer (patch P21)

  // resynchronisation : un `hello` dont la séquence a bougé depuis le dernier événement vu = des événements ont été manqués (coupure) : la page se recharge
  let lastSeq = null;
  const vu = (d) => { if (typeof d?.seq === 'number') lastSeq = d.seq; return d; };
  const connecter = () => {
    const es = window.VF_FLUX.ouvrir(SRV.token); // 79-14 : flux partagé entre les onglets (ui/69-vf-flux.js)
    es.addEventListener('hello', (e) => {
      probe.connected = true; const d = JSON.parse(e.data);
      if (TAB === 'project' && lastSeq !== null && typeof d.seq === 'number' && d.seq !== lastSeq) { probe.resync = (probe.resync || 0) + 1; location.reload(); return; }
      vu(d); // 79-17 : who et lock du hello sont posés par le magasin d'état (VF_ETAT), qui lit le même flux
    });
    es.addEventListener('reload', () => { if (window.FLOORPLAN_RELOAD) window.FLOORPLAN_RELOAD(); else location.reload(); }); // AUDC-H1 : la carte reconstruite recharge la page par ce flux (le viewer n'en ouvre plus un second)
    es.addEventListener('who', (e) => vu(JSON.parse(e.data))); // le magasin d'état pose le who ; ici seule la séquence est retenue (resynchronisation)
    es.addEventListener('lock', (e) => vu(JSON.parse(e.data))); // idem : seule la séquence est retenue ici
    es.addEventListener('git', (e) => { const d = vu(JSON.parse(e.data)); document.dispatchEvent(new CustomEvent('vf-git:signal', { detail: { sig: d.sig } })); }); // 78-09 : signal sans contenu, l'en-tête et le tiroir relisent leurs routes
    es.addEventListener('patch', (e) => {
      const d = vu(JSON.parse(e.data));
      probe.patches++;
      if (TAB !== 'project') return; // les refs du patch sont celles du graphe Projet
      let n = 0;
      for (const p of d.patch) { const x = find(p.ref); if (!x) continue; x.st = p.st || undefined; x.foot = p.foot || undefined; if (typeof p.sum === 'string') x.summary = p.sum; n++; }
      if (d.vf) { G.meta.vf = d.vf; n++; }
      probe.applied += n;
      probe.lastLatencyMs = Date.now() - d.at;
      if (n) { sansEntree().catch(() => {}); SC.toast(`${n} statut(s) mis à jour`); }
    });
    es.addEventListener('structural', (e) => { vu(JSON.parse(e.data)); probe.structural++; if (TAB === 'project') { SC.toast('Projet modifié : rechargement'); setTimeout(() => location.reload(), 400); } });
    es.onerror = () => { es.close(); perdu('direct', connecter); };
  };
  // 79-17 (SOCL-21) : who, lock et connexion se lisent dans le magasin d'état, puis on s'y abonne (perdu : « Direct coupé », ouvert : l'état courant).
  // Sous la coquille, une fois l'onglet rendu (71 se charge après ce fichier) ; la désinscription est rendue à `surOnglet` (79-16)
  const E = window.VF_ETAT, CQ = window.VF_COQUILLE;
  const surConnexion = (c) => { if (c === 'perdu') showLock(null, true); else if (c === 'ouvert') showLock(); };
  const brancher = () => {
    if (E.lire('who')) setWho(E.lire('who'));
    if (E.lire('lock')) showLock(E.lire('lock'));
    const off = [E.abonner('who', setWho), E.abonner('lock', (l) => showLock(l)), E.abonner('connexion', surConnexion)];
    return () => { for (const f of off) f(); };
  };
  if (CQ && typeof CQ.surOnglet === 'function') CQ.surOnglet(brancher); else brancher();
  connecter();
})();
