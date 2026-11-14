// VibeFlow (79-16, SOCL-20) : le client de la coquille. Le document ne porte aucune donnée : la coquille lit celle d'un onglet par GET /api/vf/graphe,
// pose les scripts de /_vf/ (liste du manifeste ; classes : bibliothèque, persistant, i18n, moteur, onglet) puis le moteur, et rend la main quand il a
// fait son premier rendu. Ordre au premier chargement : bibliothèques, persistants (ordre d'octets du nom), puis l'onglet (i18n, moteur, extensions).
// Un changement d'onglet démonte l'onglet affiché (vf-coquille-portee.js), puis ré-exécute le moteur et les scripts d'onglet ; les persistants restent.
// Le fragment de l'adresse n'est jamais écrit ici. Premier script de la tête : son écoute de DOMContentLoaded précède celle du tiroir du terminal,
// donc le squelette du corps est pris avant qu'il y ajoute ses nœuds.
(() => {
  'use strict';
  if (window.VF_COQUILLE) return;
  const D = document, H = D.documentElement, ONGLETS = ['code', 'projet', 'equipe'];
  const PAR_ADRESSE = { '/': 'code', '/index.html': 'code', '/project.html': 'projet', '/equipe.html': 'equipe' };
  const TITRES = { code: 'VibeFlow · Code', projet: 'VibeFlow · Projet', equipe: 'VibeFlow · Équipe' };
  let cause = ''; // pourquoi la dernière lecture a échoué, dite sur l'écran d'échec
  const MESSAGE_LECTURE = 'Lecture impossible : les données de cet onglet n\'ont pas pu être lues.';
  const P = window.VF_PORTEE;
  let manifeste = null, squelette = null, affiche = null, porte = null, file = Promise.resolve(), enLot = false, enDemarrage = false;
  let etat = { onglet: null, phase: 'chargement', motif: null };
  const retenu = {}; // onglet -> { etag, texte } : la dernière réponse 200 (le 304 ré-analyse ce texte, jamais un objet muté par le moteur)
  const inscriptions = [], differes = [];
  const delai = () => { const n = window.VF_COQUILLE_REGLAGES?.delaiMs; return Number.isInteger(n) && n >= 1000 && n <= 120000 ? n : 30000; };
  const nomsDe = (...classes) => manifeste.fichiers.filter((f) => classes.includes(f.classe)).map((f) => f.nom);
  const erreur = (m, e) => console.error(`VibeFlow coquille : ${m} : ${e && e.message}`);

  const poser = (nom) => new Promise((ok, ko) => {
    const s = D.createElement('script');
    s.src = manifeste.prefixe + nom; s.onload = () => ok(); s.onerror = () => ko(new Error('script de la coquille illisible : ' + nom));
    D.head.appendChild(s);
  });
  const enchainer = async (noms) => { for (const n of noms) await poser(n); };

  // ---- surOnglet : rappels appelés une fois par arrivée, nettoyage rendu appelé avant le changement suivant ----
  const nettoyer = (ins) => { const f = ins.nettoyage; ins.nettoyage = null; if (f) { try { f(); } catch (e) { erreur('un nettoyage a levé', e); } } };
  const appeler = (ins) => {
    try { const r = ins.rappel({ onglet: affiche }); ins.nettoyage = typeof r === 'function' ? r : null; } catch (e) { erreur('un rappel a levé', e); }
  };
  // un rappel posé pendant un autre est appelé après le lot
  const lot = (appels) => {
    enLot = true; try { for (const ins of appels) if (ins.actif) appeler(ins); } finally { enLot = false; }
    if (differes.length) lot(differes.splice(0));
  };
  function surOnglet(rappel, options) {
    const cle = options && typeof options === 'object' && Object.hasOwn(options, 'cle') ? options.cle : undefined;
    const valide = cle === undefined || (typeof cle === 'string' && cle.length > 0 && cle.length < 100);
    if (typeof rappel !== 'function' || !valide) return () => {};
    const remplacee = cle === undefined ? null : inscriptions.find((i) => i.cle === cle); // garde:coquille-cle
    if (remplacee) { remplacee.actif = false; nettoyer(remplacee); inscriptions.splice(inscriptions.indexOf(remplacee), 1); }
    const ins = { rappel, cle, nettoyage: null, actif: true, demarrage: enDemarrage }; // posé au démarrage d'un onglet : par ses scripts, donc défait avec lui
    inscriptions.push(ins);
    if (etat.phase === 'pret' && affiche !== null) { if (enLot) differes.push(ins); else lot([ins]); }
    return () => {
      if (!ins.actif) return;
      ins.actif = false; nettoyer(ins);
      const i = inscriptions.indexOf(ins); if (i >= 0) inscriptions.splice(i, 1);
    };
  }

  // la lecture de l'onglet : jeton de l'onglet, étiquette retenue ; 200 garde le texte, 304 réutilise le texte retenu,
  // le reste est un échec au message fixe
  async function lireGraphe(nom) {
    const entetes = { 'x-vf-cockpit-token': window.VF_COCKPIT_SERVER?.jetons?.[nom] || '' };
    if (retenu[nom]) entetes['If-None-Match'] = retenu[nom].etag;
    let r;
    try { r = await fetch('/api/vf/graphe?onglet=' + nom, { headers: entetes }); } catch {
      cause = 'Le serveur du cockpit ne répond pas. Vérifiez qu\'il tourne toujours, puis réessayez.'; throw new Error(MESSAGE_LECTURE);
    }
    if (r.status === 200) { const texte = await r.text(); retenu[nom] = { etag: r.headers.get('ETag') || '', texte }; }
    else if (r.status !== 304 || !retenu[nom]) {
      cause = 'Le serveur du cockpit a répondu ' + r.status + ' au lieu des données. Relancez-le, puis réessayez.'; throw new Error(MESSAGE_LECTURE);
    }
    return JSON.parse(retenu[nom].texte);
  }

  // ---- l'échec d'un chargement (A55) : l'état, l'événement annulable, et au premier chargement le texte fixe avec « Réessayer » ----
  function afficherEchec(nom) {
    if (D.getElementById('vf-coquille-echec')) return;
    const n = D.createElement('div'), c = D.createElement('div'), h = D.createElement('h1'), t = D.createElement('p'), q = D.createElement('p'),
      b = D.createElement('button'), s = D.createElement('style');
    n.id = 'vf-coquille-echec'; n.setAttribute('role', 'alert'); n.lang = 'fr';
    // un écran propre à la coquille (DESIGN.md, « Graphite ») : plein viseur, fond plein (rien du cockpit qui n'a pas démarré ne reste visible),
    // police et jetons du cockpit, cible de 44 px, colonne lisible de 320 px à 1440 px
    s.textContent = '#vf-coquille-echec { position: fixed; inset: 0; z-index: 2147483000; display: flex; align-items: center; justify-content: center;'
      + ' box-sizing: border-box; padding: max(var(--sp-16, 16px), env(safe-area-inset-top, 0px)) var(--sp-16, 16px) var(--sp-16, 16px);'
      + ' overflow: auto; }'
      // le nœud reste sans fond ni couleur propres (il suit le thème) ; la carte porte la couleur et, par son ombre étalée, masque tout ce qui reste derrière
      + ' #vf-coquille-echec .vf-ce { width: 100%; max-width: 440px; box-sizing: border-box; display: flex; flex-direction: column; gap: var(--sp-12, 12px);'
      + ' padding: var(--sp-24, 24px); border-radius: var(--r-card, 14px); background: var(--surface, #1a1a1c); color: var(--text, #ededed);'
      + ' font-family: var(--sans, system-ui, sans-serif); box-shadow: var(--shadow-card, 0 1px 2px rgba(0, 0, 0, .3)); }'
      // le squelette (barre de recherche, panneau, flux…) n'a rien à montrer : ni visible, ni atteignable au clavier, tant que l'écran est là
      + ' body.vf-ce-actif > :not(#stage):not(script):not(style), body.vf-ce-actif #stage > :not(#vf-coquille-echec) { visibility: hidden !important; }'
      + ' body.vf-ce-actif #vf-coquille-echec { visibility: visible; }'
      + ' #vf-coquille-echec h1 { margin: 0; font-size: 20px; font-weight: 600; letter-spacing: -.015em; }'
      + ' #vf-coquille-echec p { margin: 0; font-size: 15px; line-height: 1.5; overflow-wrap: anywhere; }'
      + ' #vf-coquille-echec .vf-ce-cause { color: var(--text-2, #a8a8a8); }'
      + ' #vf-coquille-echec button { align-self: flex-start; min-height: 44px; min-width: 44px; margin-top: var(--sp-8, 8px); padding: 0 var(--sp-20, 20px);'
      + ' border: 1px solid var(--hair-2, #3a3a3d); border-radius: var(--r-ctl, 10px); background: var(--surface, #1a1a1c); color: inherit; font: inherit;'
      + ' font-weight: 600; cursor: pointer; }'
      + ' #vf-coquille-echec button:focus-visible { outline: 2px solid var(--ring, #8fb4ff); outline-offset: 2px; }'
      + ' @media (max-width: 700px) { #vf-coquille-echec { align-items: flex-start; } #vf-coquille-echec button { align-self: stretch; } }';
    h.textContent = 'Le cockpit n\'a pas pu démarrer';
    t.textContent = MESSAGE_LECTURE; // garde:coquille-echec-corps
    q.className = 'vf-ce-cause'; q.textContent = cause || 'La cause n\'a pas été relevée ; réessayez, puis consultez le terminal du cockpit.';
    b.type = 'button'; b.textContent = 'Réessayer';
    b.addEventListener('click', () => { chargerOnglet(nom).catch(() => {}); });
    c.className = 'vf-ce'; c.append(h, t, q, b); n.append(s, c); (D.getElementById('stage') || D.body).appendChild(n); D.body.classList.add('vf-ce-actif');
  }
  function echec(nom, motif) {
    etat = { onglet: nom, phase: 'echec', motif };
    if (motif !== 'lecture') return;
    const initial = affiche === null;
    const ev = new CustomEvent('vf:coquille-echec', { cancelable: true, detail: { onglet: nom, initial } });
    const annule = !D.dispatchEvent(ev); // garde:coquille-echec-emission
    if (initial && !annule) afficherEchec(nom); // garde:coquille-echec-prevent
  }

  async function demarrerOnglet(nom, graphe, initial) {
    window.VF_COCKPIT = graphe;
    if (window.VF_COCKPIT_SERVER) window.VF_COCKPIT_SERVER.token = window.VF_COCKPIT_SERVER.jetons[nom];
    D.title = TITRES[nom];
    // un téléphone démarre panneau fermé
    if (matchMedia('(max-width: 700px)').matches && !/[#&]s=/.test(location.hash)) D.body.classList.add('no-panel');
    let ouvrirPorte; porte = new Promise((ok) => { ouvrirPorte = ok; });
    await enchainer(nomsDe('i18n', 'moteur', 'onglet')); // garde:coquille-persistants
    const pret = new Promise((ok) => window.VibeFlow.on('ready', () => ok()));
    ouvrirPorte();
    let minuterie;
    const limite = new Promise((ok, ko) => {
      minuterie = setTimeout(() => ko(new Error('Le premier rendu de l\'onglet n\'a pas eu lieu à temps.')), delai());
    });
    try { await Promise.race([pret, limite]); } finally { clearTimeout(minuterie); }
  }

  // un démarrage en échec laisse la coquille pilotable : le nettoyage d'avant le démontage a défait les rappels (l'écouteur du routeur compris) ;
  // ceux des scripts de l'onglet raté s'en vont avec lui, les autres (persistants) sont rappelés : sinon plus aucun clic d'onglet ne passe par la coquille
  function reprendre() {
    for (const ins of inscriptions.splice(0)) if (ins.demarrage) ins.actif = false; else inscriptions.push(ins);
    lot([...inscriptions]); // garde:coquille-relance
  }

  async function sequence(nom, initial) {
    etat = { onglet: nom, phase: 'chargement', motif: null };
    let graphe;
    try { graphe = await lireGraphe(nom); } catch (e) { echec(nom, 'lecture'); throw e; }
    D.getElementById('vf-coquille-echec')?.remove(); D.body.classList.remove('vf-ce-actif');
    H.dataset.vfPret = 'non';
    for (const ins of [...inscriptions].reverse()) nettoyer(ins); // les fonctions rendues par les rappels, avant le démontage
    // les rappels inscrits par les scripts de l'onglet affiché (au démarrage) s'en vont avec lui : ses scripts sont ré-exécutés et s'inscriront de nouveau
    for (const ins of inscriptions.splice(0)) if (ins.demarrage) ins.actif = false; else inscriptions.push(ins);
    P.demonter();
    P.ouvrir(squelette); enDemarrage = true;
    try { await demarrerOnglet(nom, graphe, initial); } catch (e) {
      enDemarrage = false; etat = { onglet: nom, phase: 'echec', motif: null }; reprendre(); throw e;
    }
    enDemarrage = false;
    affiche = nom; etat = { onglet: nom, phase: 'pret', motif: null };
    H.dataset.vfPret = 'oui';
    lot([...inscriptions]);
  }

  function chargerOnglet(nom) {
    if (typeof nom !== 'string' || !ONGLETS.includes(nom)) return Promise.reject(new Error('Onglet inconnu.'));
    const p = file.then(() => sequence(nom, false));
    file = p.catch(() => {});
    return p;
  }

  window.VF_COQUILLE = Object.freeze({
    version: 1, chargerOnglet, surOnglet, onglet: () => affiche, etat: () => ({ ...etat }), natif: P.natif,
    porteMoteur: () => porte || Promise.resolve(),
  });

  D.addEventListener('DOMContentLoaded', () => {
    try { manifeste = JSON.parse(D.getElementById('vf-coquille-manifeste').textContent); } catch { return; }
    const orig = [...D.body.childNodes];
    squelette = { orig, copie: orig.map((n) => n.cloneNode(true)) };
    H.dataset.vfPret = 'non';
    file = enchainer(nomsDe('bibliotheque', 'persistant')).then(() => sequence(PAR_ADRESSE[location.pathname] || 'code', true)).catch(() => {});
  }, { once: true });
})();
