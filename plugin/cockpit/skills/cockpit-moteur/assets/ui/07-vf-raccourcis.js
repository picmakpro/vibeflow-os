// VibeFlow (80-14) : le registre unique des raccourcis (P80-D-13) et les sources de la palette de commandes (P80-D-14, P80-D-55).
// Exposé : window.VF_RACCOURCIS = Object.freeze({ entrees(onglet?), libelle(id), ajouter(entree) -> retirer }) (globale à part).
//   entrée = { id, groupe, onglets, touche, libelle, action, palette, [usuelle], [info], [visible], [libre], [avant] }
//   `groupe` : celui de l'aide `?` ; `onglets` : sous-ensemble de code, projet, equipe ; `touche` : texte affiché (« F »,
//   « Retour arrière », « / ou ⌘K »), null s'il n'y en a pas ; `palette: false` : rangée d'aide seule ; `usuelle` : rang (1 à 8)
//   des huit actions du champ vide ; `info` : ligne de texte seul, jamais une action ; `visible()` : l'action a un effet sur la
//   vue courante (sinon elle est absente de la palette) ; `avant` : le focus d'avant revient avant l'action.
// Une extension ajoute une entrée par VF_RACCOURCIS.ajouter({...}) (rend la fonction qui la retire).
// Script par onglet (A51) : le registre est refait avec le moteur. Rien n'est lu au chargement : l'onglet, la sélection et
// VF_ETAT le sont à l'appel. Aucune requête, aucun envoi : une action ne soumet jamais la barre de question (Q4).
(() => {
  const SC = window.Floorplan;
  if (!SC || typeof SC.ajouterSource !== 'function') return;
  const C = window.VF_COQUILLE, $ = (s) => document.querySelector(s);
  const NOMS = ['code', 'projet', 'equipe'], CARTE = ['code', 'projet'], LIB = { code: 'Code', projet: 'Projet', equipe: 'Équipe' };
  let vivant = !C, attente = null, minuterie = null;
  const norm = (s) => String(s).normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();
  const meta = () => SC.graph.meta || {};
  const onglet = () => {
    const o = window.VF_ONGLETS && window.VF_ONGLETS.courant();
    return NOMS.includes(o) ? o : meta().vfTab === 'project' ? 'projet' : meta().vfTab === 'equipe' ? 'equipe' : 'code';
  };
  // le canevas est affiché : ni sur Équipe, ni sous les couloirs ou la liste de Projet (body.vf-forme-couloirs)
  const canevas = () => onglet() !== 'equipe' && !document.body.classList.contains('vf-forme-couloirs');
  const carteSel = () => canevas() && typeof SC.state.selected === 'string' && !!SC.state.chipEls && SC.state.chipEls.has(SC.state.selected);
  const focCarte = () => { const V = window.VF_CANEVAS, id = V && V.carteItinerante(); if (id) V.focaliser(id); };
  // une action qui re-rend (Monter) pose son focus après le rendu : un seul rappel, borné à 1,5 s
  const apresRendu = (f) => { attente = f; clearTimeout(minuterie); minuterie = setTimeout(() => { attente = null; }, 1500); };
  // (après les autres écouteurs de render : celui du clavier du canevas, posé à l'arrivée de l'onglet, pose la carte itinérante)
  SC.on('render', () => { const f = attente; attente = null; if (vivant && f) queueMicrotask(f); });
  const clic = (sel) => () => { const b = $(sel); if (b) b.click(); };

  // ---- les actions ----
  const monter = () => { apresRendu(focCarte); SC.up(); };
  const zoom = (sel) => () => { clic(sel)(); focCarte(); };
  const ajuster = () => { clic('#z-fit')(); focCarte(); };
  const cadrer = () => { const V = window.VF_CANEVAS; if (V) V.cadrerVoisins(); };
  const detail = () => { const b = $('#btn-panel'); if (b) { b.click(); b.focus({ preventScroll: true }); } };
  const git = () => { const G = window.VFGitTiroir; if (G) G.ouvrir(); };
  const aide = () => { const A = window.VF_AIDE; if (A && typeof A.ouvrir === 'function') A.ouvrir(); };
  const basculer = () => {
    const P = window.VF_PROJET; if (!P) return;
    const l = P.niveau() === 'racine' ? ['couloirs', 'liste', 'graphe'] : ['liste', 'graphe'], i = l.indexOf(P.forme());
    P.basculer(l[(i + 1) % l.length], { memoriser: true, equivalent: true });
  };
  const copier = () => { // l'adresse complète, fragment compris ; jamais d'exception ni de rejet
    const ok = () => SC.toast('Lien copié'), ko = () => SC.toast('Copie impossible. Le lien est dans la barre d\'adresse.');
    try { navigator.clipboard.writeText(location.href).then(ok, ko); } catch (e) { void e; ko(); }
  };
  const question = (q, libelle) => { // remplit la barre de question et y pose le focus : jamais d'envoi (Q4)
    const i = $('#ask-input'); if (!i || i.disabled) return;
    const t = String(q || '').replace(/^\s*>?\s*/, '');
    const reste = norm(t).startsWith(norm(libelle)) ? t.slice(libelle.length).trim() : '';
    i.value = reste; i.dispatchEvent(new Event('input', { bubbles: true })); i.focus(); i.setSelectionRange(reste.length, reste.length);
  };

  // ---- le registre ----
  const entrees = [];
  const def = (id, groupe, onglets, touche, libelle, o = {}) => entrees.push({ id, groupe, onglets, touche, libelle,
    action: o.action || null, palette: !!o.palette, ...(o.usuelle ? { usuelle: o.usuelle } : {}), ...(o.info ? { info: true } : {}),
    ...(o.visible ? { visible: o.visible } : {}), ...(o.libre ? { libre: true } : {}), ...(o.avant ? { avant: true } : {}) });
  const P = (action, usuelle, visible) => ({ action, palette: true, usuelle, visible });
  const TOUS = NOMS, PR = ['projet'], PARTOUT = 'Partout', LA_CARTE = 'La carte', COULOIRS = 'Projet : couloirs et liste';
  const L_QUESTION = 'Poser une question à l\'agent', TEXTE_TERMINAL = 'Le terminal s\'active avec --terminal';
  def('rechercher', PARTOUT, TOUS, '/ ou ⌘K', 'Rechercher');
  def('aide', PARTOUT, TOUS, '?', 'Afficher les raccourcis', { ...P(aide, 8, () => !!window.VF_AIDE), avant: true });
  def('git', PARTOUT, TOUS, 'G', 'Ouvrir l\'historique Git', P(git, 7, () => !!window.VFGitTiroir));
  def('echap', PARTOUT, TOUS, 'Échap', 'Fermer ou remonter d\'un cran');
  def('tab', PARTOUT, TOUS, 'Tab', 'Zone suivante');
  def('carte-voisine', LA_CARTE, CARTE, '← ↑ ↓ →', 'Carte voisine');
  def('carte-premiere', LA_CARTE, CARTE, 'Origine', 'Première carte');
  def('carte-derniere', LA_CARTE, CARTE, 'Fin', 'Dernière carte');
  def('carte-plonger', LA_CARTE, CARTE, 'Entrée', 'Plonger dans la carte');
  def('carte-selectionner', LA_CARTE, CARTE, 'Espace', 'Sélectionner la carte'); // P80-D-51 : toute largeur, rangée d'aide seule
  def('monter', LA_CARTE, CARTE, 'Retour arrière', 'Monter d\'un niveau', P(monter, 3, () => canevas() && SC.state.container !== 'root'));
  def('ajuster', LA_CARTE, CARTE, 'F', 'Ajuster à l\'écran', P(ajuster, 1, canevas));
  def('cadrer', LA_CARTE, CARTE, 'C', 'Cadrer la sélection et ses voisins', P(cadrer, 2, carteSel));
  def('zoom-avant', LA_CARTE, CARTE, '+', 'Zoom avant', P(zoom('#z-in'), 5, canevas));
  def('zoom-arriere', LA_CARTE, CARTE, '-', 'Zoom arrière', P(zoom('#z-out'), 6, canevas));
  def('detail', LA_CARTE, CARTE, 'P', 'Afficher ou masquer le détail', P(detail, 4, () => onglet() !== 'equipe'));
  def('basculer', COULOIRS, PR, 'V', 'Basculer couloirs, liste, graphe', P(basculer, 0, () => onglet() === 'projet' && !!window.VF_PROJET));
  def('phase-voisine', COULOIRS, PR, '← ↑ ↓ →', 'Phase voisine');
  def('phase-premiere', COULOIRS, PR, 'Origine', 'Première phase');
  def('phase-derniere', COULOIRS, PR, 'Fin', 'Dernière phase');
  def('phase-plonger', COULOIRS, PR, 'Entrée', 'Plonger dans la phase'); // P80-D-51 : sans distinction de largeur
  def('phase-selectionner', COULOIRS, PR, 'Espace', 'Sélectionner la phase');
  def('phase-echap', COULOIRS, PR, 'Échap', 'Désélectionner puis monter d\'un niveau');
  def('question', PARTOUT, TOUS, null, L_QUESTION, { action: (q) => question(q, L_QUESTION), palette: true, libre: true,
    visible: () => { const i = $('#ask-input'); return !!i && !i.disabled; } });
  def('lien', PARTOUT, TOUS, null, 'Copier le lien de cette vue', { action: copier, palette: true, avant: true });
  // P80-D-55 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-11) : texte constant, aucune action, rien lu sur le terminal
  def('terminal', PARTOUT, TOUS, null, TEXTE_TERMINAL, { palette: true, info: true });
  const copie = (e) => Object.freeze({ ...e, onglets: Object.freeze(e.onglets.slice()) });
  // ajouter : une entrée valide est copiée champ par champ (liste fermée) ; un champ facultatif invalide est neutralisé, une entrée invalide refusée,
  // chaque cas avec un console.error : une entrée d'extension ne retire ni ne casse jamais les actions natives
  const refus = (m) => { console.error('VF_RACCOURCIS.ajouter : ' + m); return () => {}; };
  const ajouter = (e) => {
    if (!e || typeof e !== 'object') return refus('entrée absente');
    if (typeof e.id !== 'string' || !e.id) return refus('id manquant');
    if (entrees.some((x) => x.id === e.id)) return refus('id déjà pris : ' + e.id);
    if (typeof e.libelle !== 'string' || !e.libelle) return refus('libellé manquant : ' + e.id);
    if (!Array.isArray(e.onglets) || !e.onglets.length || !e.onglets.every((o) => NOMS.includes(o))) return refus('onglets invalides : ' + e.id);
    if (e.touche != null && typeof e.touche !== 'string') return refus('touche invalide : ' + e.id);
    if (e.action != null && typeof e.action !== 'function') return refus('action invalide : ' + e.id);
    const x = { id: e.id, groupe: PARTOUT, onglets: e.onglets.slice(), touche: e.touche == null ? null : e.touche, libelle: e.libelle, action: e.action ||
        null, palette: false };
    if (typeof e.groupe === 'string' && e.groupe) x.groupe = e.groupe;
        else if (e.groupe !== undefined) console.error('VF_RACCOURCIS.ajouter : groupe ignoré : ' + e.id);
    if (e.palette === true && (x.action || e.info === true)) x.palette = true;
    else if (e.palette !== undefined && e.palette !== false) console.error('VF_RACCOURCIS.ajouter : palette ignorée (sans action) : ' + e.id);
    if (typeof e.visible === 'function') x.visible = e.visible;
        else if (e.visible !== undefined) console.error('VF_RACCOURCIS.ajouter : visible ignoré : ' + e.id);
    if (Number.isInteger(e.usuelle) && e.usuelle >= 1 && e.usuelle <= 8) x.usuelle = e.usuelle;
        else if (e.usuelle !== undefined) console.error('VF_RACCOURCIS.ajouter : usuelle ignorée : ' + e.id);
    for (const k of ['info', 'libre', 'avant']) if (e[k] === true) x[k] = true;
    entrees.push(x);
    return () => { const k = entrees.indexOf(x); if (k >= 0) entrees.splice(k, 1); };
  };
  window.VF_RACCOURCIS = Object.freeze({
    entrees: (o) => entrees.filter((e) => o === undefined || e.onglets.includes(o)).map(copie),
    libelle: (id) => { const e = entrees.find((x) => x.id === id); return e ? e.libelle : null; },
    ajouter });

  // ---- les sources de la palette : { groupe, titre, id, libelle, detail, touches, icone, executer, avant, info } ----
  const ICONES = { aide: 'spark', git: 'open', monter: 'left', ajuster: 'fit', cadrer: 'fit', 'zoom-avant': 'search',
    'zoom-arriere': 'search', detail: 'panel', basculer: 'panel', question: 'spark', lien: 'copy' };
  const accepte = (e, c) => {
    const l = norm(e.libelle);
    return c.termes.every((t) => l.includes(norm(t))) || (!!e.libre && norm(c.q.trim()).startsWith(l));
  };
  const rang = (e) => (e.usuelle ? e.usuelle : 100);
  const sourceActions = (c) => {
    const o = onglet(), vu = (e) => { try { return !e.visible || !!e.visible(); } catch (x) { console.error('VF_RACCOURCIS : visible() a levé : ' + e.id);
        return false; } };
    const liste = entrees.filter((e) => e.palette && e.onglets.includes(o) && vu(e));
    const gardes = liste.filter((e) => (c.vide ? (c.actions ? !e.info : !!e.usuelle) : accepte(e, c)));
    return gardes.sort((a, b) => rang(a) - rang(b)).map((e) => ({ groupe: 'actions', titre: 'Actions', id: e.id, libelle: e.libelle,
      touches: e.touche && !e.info ? [e.touche.split(' ou ')[0]] : [], icone: ICONES[e.id] || 'right', info: !!e.info, avant: !!e.avant,
      executer: (q) => (e.action ? e.action(q) : undefined) }));
  };
  const sourceOnglets = (c) => {
    const V = window.VF_ONGLETS, o = onglet();
    if (c.actions || !V) return [];
    return NOMS.filter((n) => n !== o).map((n) => ({ groupe: 'onglets', titre: 'Onglets', id: 'onglet-' + n,
      libelle: 'Aller à ' + LIB[n], icone: 'right', executer: () => V.aller(n) }))
      .filter((x) => c.termes.every((t) => norm(x.libelle).includes(norm(t))));
  };
  const etat = (cle) => { try { return window.VF_ETAT ? window.VF_ETAT.lire(cle) : null; } catch (e) { void e; return null; } };
  const idPhase = (ph) => {
    const S = window.Floorplan, a = `n:ph-${ph.n}@${ph.ws}`, b = `n:ph-${ph.n}`;
    return S && S.exists(a) ? a : S && S.exists(b) ? b : null;
  };
  const sourcePhases = (c) => {
    const e = etat('etat'), L = e && e.signal && Array.isArray(e.signal.phases) ? e.signal.phases : [];
    if (c.actions || c.vide || onglet() === 'projet') return [];
    const dit = (ph) => c.termes.every((t) => norm(`phase ${ph.n} ${ph.nom}`).includes(norm(t)));
    const aller = (ph) => () => window.VF_ONGLETS.aller('projet').then(() => {
      const id = idPhase(ph); if (id) window.Floorplan.reveal(id, { focus: true });
    });
    return L.filter((ph) => ph && typeof ph.nom === 'string' && /^[0-9][0-9.]*$/.test(String(ph.n)) && dit(ph)).slice(0, 8)
      .map((ph) => ({ groupe: 'phases', titre: 'Phases', id: 'phase-' + ph.key, libelle: `Phase ${ph.n} · ${ph.nom}`,
        icone: 'right', executer: aller(ph) }));
  };
  const sourceAgents = (c) => { // le rôle et le nom court seulement : jamais un mandat ni une commande (P69-D-16)
    const w = etat('who'), L = w && Array.isArray(w.workers) ? w.workers : [];
    if (c.actions || c.vide || onglet() === 'equipe') return [];
    const court = (x) => String(x.id).slice(0, 8), role = (x) => (typeof x.role === 'string' && x.role ? x.role : 'Agent');
    const aller = (x) => () => window.VF_ONGLETS.aller('equipe').then(() => {
      const S = window.Floorplan, id = ['n:ag-', 'n:se-'].map((p) => p + x.id).find((i) => S.exists(i));
      if (id) S.reveal(id, { focus: true });
    });
    return L.filter((x) => x && typeof x.id === 'string' && (x.kind === 'session' || x.kind === 'subagent'))
      .filter((x) => c.termes.every((t) => norm(`${role(x)} ${court(x)}`).includes(norm(t)))).slice(0, 8)
      .map((x) => ({ groupe: 'agents', titre: 'Agents', id: 'agent-' + x.id, libelle: role(x), detail: court(x),
        icone: 'right', executer: aller(x) }));
  };
  for (const f of [sourceActions, sourceOnglets, sourcePhases, sourceAgents]) SC.ajouterSource(f);

  if (C && typeof C.surOnglet === 'function') {
    C.surOnglet(() => { vivant = true; return () => { vivant = false; attente = null; clearTimeout(minuterie); }; }, { cle: '07-vf-raccourcis.js' });
  }
})();
