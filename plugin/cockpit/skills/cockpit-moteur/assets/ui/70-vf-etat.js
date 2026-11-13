// VibeFlow (79-17, SOCL-21) : le magasin d'état de la page, window.VF_ETAT (C4, A13). Huit clés fermées, alimentées par le flux partagé (window.VF_FLUX,
// ui/69-vf-flux.js) : les vues lisent par lire(cle) et observent par abonner(cle, rappel) ; jeton() et lireJson(chemin) sont la seule porte d'un script de page
// vers les routes /api/vf/* de la même origine. Persistant : il survit aux changements d'onglet ; une vue ré-exécutée par onglet rend sa désinscription
// à VF_COQUILLE.surOnglet. Il lit le flux, il n'en émet rien : aucun événement de document, aucun écouteur, aucune minuterie.
// vf-coquille: persistant
(() => {
  'use strict';
  if (window.VF_ETAT) return;
  const CLES = Object.freeze(['connexion', 'etat', 'frise', 'git', 'graphe', 'lock', 'planning', 'who']);
  const ENTREES = new Map(CLES.map((c) => [c, { valeur: null, abonnes: [] }]));
  const SCHEMA_ETAT = 'vibeflow/cockpit-state@1', SCHEMA_FRISE = 'vibeflow/cockpit-frise@1';
  const CONNEXIONS = ['ouvert', 'perdu', 'reprise'];
  const ROUTE = /^\/api\/vf\/[A-Za-z0-9_-]+(\/[A-Za-z0-9_-]+)*(\?[A-Za-z0-9_.~%=&,-]*)?$/;
  const MAX_CHEMIN = 2048;

  const entree = (cle) => { if (typeof cle !== 'string' || !ENTREES.has(cle)) throw new RangeError('VF_ETAT : clé inconnue'); return ENTREES.get(cle); };
  const objet = (v) => v !== null && typeof v === 'object' && !Array.isArray(v);
  const entier = (v) => Number.isSafeInteger(v) && v >= 0;
  const instant = (v) => (Number.isFinite(v) && v >= 0 ? v : Date.now());

  // ---------- lecture, abonnement, notification ----------
  const notifier = (e, valeur) => { // instantané de la liste : un abonné inscrit pendant la notification n'est appelé qu'aux suivantes
    for (const a of e.abonnes.slice()) {
      if (!a.actif) continue; // désinscrit avant son tour
      try { a.rappel(valeur); } catch (x) { console.error('VF_ETAT : un rappel a levé : ' + (x && x.message)); }
    }
  };
  const poser = (cle, valeur) => { const e = ENTREES.get(cle); e.valeur = valeur; notifier(e, valeur); };
  const lire = (cle) => entree(cle).valeur;
  const abonner = (cle, rappel) => {
    const e = entree(cle);
    if (typeof rappel !== 'function') throw new TypeError('VF_ETAT : rappel attendu');
    const a = { rappel, actif: true }; e.abonnes.push(a);
    if (cle === 'frise') surInscriptionFrise();
    return () => { a.actif = false; const i = e.abonnes.indexOf(a); if (i >= 0) e.abonnes.splice(i, 1); };
  };
  const abonnes = () => Object.fromEntries(CLES.map((c) => [c, ENTREES.get(c).abonnes.length]));

  // ---------- jeton et lecture JSON bornée à l'API de la même origine ----------
  const jeton = () => { const S = window.VF_COCKPIT_SERVER; return S && typeof S.token === 'string' && S.token ? S.token : null; };
  const erreur = (statut) => { const e = new Error('VF_ETAT : lecture impossible'); e.statut = statut; return e; };
  const lireJson = (chemin) => {
    if (typeof chemin !== 'string' || chemin.length > MAX_CHEMIN || !ROUTE.test(chemin)) return Promise.reject(erreur(0));
    const t = jeton(); if (t === null) return Promise.reject(erreur(0));
    const options = { method: 'GET', headers: { 'x-vf-cockpit-token': t }, cache: 'no-store', redirect: 'error' };
    let envoi;
    try { envoi = Promise.resolve(window.fetch ? window.fetch(chemin, options) : fetch(chemin, options)); } catch { return Promise.reject(erreur(0)); }
    return envoi.then((r) => {
      if (!r || !r.ok) throw erreur(r && typeof r.status === 'number' ? r.status : 0);
      return r.json().then((j) => j, () => { throw erreur(-1); });
    }, () => { throw erreur(0); });
  };

  // ---------- lectures d'état et de frise : une requête en vol par clé, une lecture de rattrapage au plus ----------
  const lecteur = (cle, chemin, valide) => {
    let envol = false, rattrape = false;
    const lancer = () => {
      if (envol) { rattrape = true; return; }
      envol = true; rattrape = false;
      lireJson(chemin).then((j) => { if (valide(j)) poser(cle, j); }).catch(() => {}).then(() => { envol = false; if (rattrape) lancer(); });
    };
    return lancer;
  };
  const lireEtat = lecteur('etat', '/api/vf/state', (j) => objet(j) && j.schema === SCHEMA_ETAT && typeof j.seq === 'number');
  const lireFrise = lecteur('frise', '/api/vf/frise', (j) => objet(j) && j.schema === SCHEMA_FRISE);
  let frisePerimee = false;
  const surInscriptionFrise = () => { if (ENTREES.get('frise').valeur === null || frisePerimee) { frisePerimee = false; lireFrise(); } };
  const lireFriseSiInscrit = () => { if (ENTREES.get('frise').abonnes.length) lireFrise(); else frisePerimee = true; };

  // ---------- alimentation par le flux partagé : chaque charge est une donnée non fiable, ignorée sans lever si elle est mal formée ----------
  const connexion = (e) => { if (CONNEXIONS.includes(e) && ENTREES.get('connexion').valeur !== e) poser('connexion', e); };
  const sans = (c, noms) => noms.every((n) => entier(c[n]));
  const surHello = (c) => {
    if (!objet(c)) return;
    if (objet(c.who)) poser('who', c.who);
    if (objet(c.lock) && objet(c.lock.verrous)) poser('lock', c.lock);
    connexion('ouvert'); lireEtat();
    if (ENTREES.get('frise').abonnes.length) lireFrise();
  };
  const SURFLUX = {
    hello: surHello,
    who: (c) => { if (objet(c) && objet(c.who)) poser('who', c.who); },
    lock: (c) => { if (objet(c) && sans(c, ['seq']) && objet(c.verrous)) poser('lock', c); },
    git: (c) => { if (objet(c) && sans(c, ['seq']) && typeof c.sig === 'string') poser('git', { seq: c.seq, at: instant(c.at), sig: c.sig }); },
    graphe: (c) => {
      if (!objet(c) || !sans(c, ['seq']) || typeof c.onglet !== 'string' || typeof c.sig !== 'string') return;
      poser('graphe', { seq: c.seq, at: instant(c.at), onglet: c.onglet, sig: c.sig });
    },
    structural: (c) => { if (objet(c) && sans(c, ['seq'])) poser('planning', { seq: c.seq, at: instant(c.at) }); },
    etat: (c) => { if (objet(c)) lireEtat(); },
    frise: (c) => { if (objet(c)) lireFriseSiInscrit(); },
  };
  const F = window.VF_FLUX;
  if (F && typeof F.ecouter === 'function') {
    for (const [nom, f] of Object.entries(SURFLUX)) {
      const rappel = (charge) => { try { f(charge); } catch (x) { console.error('VF_ETAT : charge illisible : ' + (x && x.message)); } };
      try { F.ecouter(nom, rappel); } catch { /* événement hors liste du flux */ }
    }
    if (typeof F.surConnexion === 'function') F.surConnexion(connexion);
  }

  window.VF_ETAT = Object.freeze({ CLES, lire, abonner, jeton, lireJson, abonnes });
})();
