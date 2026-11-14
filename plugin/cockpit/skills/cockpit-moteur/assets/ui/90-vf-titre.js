// VibeFlow (73-06) : le compositeur unique du titre de l'onglet du navigateur, la pastille de favicon et l'état « lu » de la régie
// (P73-D-14, P73-D-15, P73-D-38). Dernier fichier ui/ exécuté (tri par nom).
// 00-vibeflow.js et 76-vf-git-entete.js lui laissent leur part dans window.__vfTitreBase { onglet, nom } sans écrire le titre.
// Aucun observateur du <title> : il est appelé à chaque `who`, à `vf-git:signal`, au changement de thème, à chaque arrivée d'onglet
// et à `ready` (sans coquille). Ré-exécuté par onglet (pas de marqueur persistant) : l'inscription passe par VF_COQUILLE.surOnglet,
// son nettoyage défait tout (écouteurs, abonnements, icône).
// « Lu » : rapport ouvert explicitement dans ce navigateur (jamais au survol), localStorage, une clé par lab ;
// identifiants et heure seulement, rien d'autre.
(() => {
  'use strict';
  const W = window, D = document, CLE = '90-vf-titre.js', JOUR = 86400000, MAX = 200, PREFIXE = 'vf-regie-lus:';
  const ID = /^[A-Za-z0-9_-]{1,128}$/, LAB = /^[A-Za-z0-9_-]{1,64}$/;

  // ---------- titre et pastille ----------
  const compte = () => {
    const M = W.__vfRegieModele, E = W.VF_ETAT, who = E ? E.lire('who') : (W.__vfLive || {}).who;
    const Q = W.__vfRegieQuestions; // 73-11 : les questions en attente sont des lignes de « À vous », donc comptées (jamais les appliquées)
    try { return (M && typeof M.aVous === 'function' ? M.aVous(who || null) : 0) + (Q && typeof Q.compte === 'function' ? Q.compte() : 0); } catch { return 0; }
  };
  const point = () => { // un point plein neutre, couleur du texte du thème, calculé ici : aucune requête, aucun chiffre
    const c = W.getComputedStyle(D.body).color;
    const svg = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'><circle cx='8' cy='8' r='6' fill='" + c + "'/></svg>";
    return 'data:image/svg+xml,' + encodeURIComponent(svg);
  };
  const pastille = (actif) => {
    let l = D.querySelector('link[rel~="icon"]');
    if (!l) { if (!actif) return; l = D.createElement('link'); l.rel = 'icon'; D.head.appendChild(l); }
    if (l.dataset.vfIconeOrigine === undefined) l.dataset.vfIconeOrigine = l.getAttribute('href') || '';
    const voulu = actif ? point() : l.dataset.vfIconeOrigine;
    if (!voulu) l.removeAttribute('href'); else if (l.getAttribute('href') !== voulu) l.setAttribute('href', voulu);
  };
  const composer = () => {
    const b = W.__vfTitreBase;
    if (!b || typeof b.onglet !== 'string') return;
    const n = compte(), prefixe = n > 0 ? `(${n}) ${n > 1 ? 'vous attendent' : 'vous attend'} · ` : '';
    const voulu = prefixe + `${b.onglet} · ${String(b.nom || '')}`;
    if (D.title !== voulu) D.title = voulu; // jamais d'écriture inutile
    pastille(n > 0);
  };
  W.__vfTitre = { composer };
  composer(); // 00-vibeflow.js et 76-vf-git-entete.js ont posé la base : le titre se compose tout de suite

  // ---------- « lu » : valeurs relues comme des données non fiables ----------
  // lus : Map id -> heure ; null tant que le stockage n'est pas lu (ou s'il est refusé) : tout est alors à relire
  const ST = { cle: null, lus: null, attente: new Set() };
  const redessiner = () => D.dispatchEvent(new CustomEvent('vf-regie:redessiner'));
  const recents = () => [...ST.lus].sort((a, b) => b[1] - a[1]);
  const ecrire = () => {
    try {
      if (ST.lus.size) W.localStorage.setItem(ST.cle, JSON.stringify(Object.fromEntries(ST.lus)));
      else W.localStorage.removeItem(ST.cle);
    } catch { /* refusé : rien ne se garde */ }
  };
  const poser = (ids) => {
    const maintenant = Date.now();
    for (const id of ids) if (typeof id === 'string' && ID.test(id)) ST.lus.set(id, maintenant);
    for (const [id] of recents().slice(MAX)) ST.lus.delete(id);
    ecrire(); redessiner();
  };
  const marquer = (id) => {
    if (typeof id !== 'string' || !ID.test(id)) return;
    if (ST.lus) poser([id]); else if (ST.attente.size < MAX) ST.attente.add(id); // avant la lecture du stockage : gardé pour plus tard
  };
  const toutMarquer = (ids) => { if (ST.lus && Array.isArray(ids)) poser(ids); };
  const lire = (cle) => { // la valeur rangée, purgée (plus de 24 h, forme, heure) ; null si le stockage est refusé
    let brut = null, objet = null;
    try { brut = W.localStorage.getItem(cle); } catch { return null; }
    try { objet = brut ? JSON.parse(brut) : null; } catch { objet = null; }
    const valide = objet !== null && typeof objet === 'object' && !Array.isArray(objet), maintenant = Date.now(), lus = new Map();
    if (valide) {
      for (const [id, h] of Object.entries(objet)) {
        if (ID.test(id) && typeof h === 'number' && Number.isFinite(h) && h <= maintenant && h > maintenant - JOUR) lus.set(id, h);
      }
    }
    return { brut, lus, avant: valide ? Object.keys(objet).length : 0, valide };
  };
  const charger = (lab) => {
    if (typeof lab !== 'string' || !LAB.test(lab)) return;
    const r = lire(PREFIXE + lab);
    if (!r) return; // refusé : pas de module « lu », pas de bouton « Tout marquer comme relu »
    ST.cle = PREFIXE + lab; ST.lus = new Map(r.lus); ST.lus = new Map(recents().slice(0, MAX));
    for (const id of ST.attente) if (ID.test(id)) ST.lus.set(id, Date.now());
    ST.attente.clear();
    if (ST.lus.size !== r.avant || (r.brut !== null && !r.valide)) ecrire(); // jamais de clé créée à vide
    W.__vfRegieLu.toutMarquer = toutMarquer;
    redessiner();
  };
  W.__vfRegieLu = { lus: () => (ST.lus ? new Set(ST.lus.keys()) : null), marquer };

  // ---------- inscription par onglet ----------
  const monter = () => {
    const defaire = [], E = W.VF_ETAT, S = W.FLOORPLAN_SERVER;
    const ecouter = (cible, type, f) => { cible.addEventListener(type, f); defaire.push(() => cible.removeEventListener(type, f)); };
    let vivant = true;
    if (E) defaire.push(E.abonner('who', composer)); else ecouter(D, 'vf-who', composer);
    ecouter(D, 'vf-git:signal', composer);
    ecouter(D, 'vf-regie:redessiner', composer); // 73-11 : l'état des questions a changé
    ecouter(W, 'floorplan-theme-change', composer); // la couleur du point suit le thème
    ecouter(D, 'vf-agent:lu', (e) => marquer(e.detail && e.detail.id));
    if (!W.VF_COQUILLE && W.Floorplan && typeof W.Floorplan.on === 'function') W.Floorplan.on('ready', composer);
    composer();
    const entete = { headers: { 'x-floorplan-token': (S && S.token) || '' }, cache: 'no-store' };
    const lecture = E ? (E.jeton() ? E.lireJson('/api/vf/modeles') : Promise.resolve(null))
      : S && S.token ? W.fetch('/api/vf/modeles', entete).then((r) => (r.ok ? r.json() : null)) : Promise.resolve(null);
    lecture.then((d) => { if (vivant && d && typeof d === 'object') charger(d.lab); }, () => {});
    return () => {
      vivant = false;
      for (const f of defaire.splice(0)) f();
      const l = D.querySelector('link[rel~="icon"]');
      if (l && l.dataset.vfIconeOrigine !== undefined) pastille(false); // l'icône d'origine revient avec l'onglet
    };
  };
  const C = W.VF_COQUILLE;
  if (C && typeof C.surOnglet === 'function') C.surOnglet(monter, { cle: CLE }); else monter();
})();
