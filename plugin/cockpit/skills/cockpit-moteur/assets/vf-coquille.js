// VibeFlow (79-16, SOCL-20) : le client de la coquille. Le document ne porte aucune donnée : la coquille lit celle d'un onglet par GET /api/vf/graphe,
// pose les scripts de /_vf/ (liste du manifeste ; classes : bibliothèque, persistant, i18n, moteur, onglet) puis le moteur, et rend la main quand il a
// fait son premier rendu. Ordre au premier chargement : bibliothèques, persistants (ordre d'octets du nom), puis l'onglet (i18n, moteur, extensions).
// Le fragment de l'adresse n'est jamais lu ni écrit ici. Premier script de la tête : son écoute de DOMContentLoaded précède celle du tiroir du
// terminal, donc le squelette du corps est pris avant qu'il y ajoute ses nœuds.
(() => {
  'use strict';
  if (window.VF_COQUILLE) return;
  const D = document, H = D.documentElement, ONGLETS = ['code', 'projet', 'equipe'];
  const PAR_ADRESSE = { '/': 'code', '/index.html': 'code', '/project.html': 'projet', '/equipe.html': 'equipe' };
  const TITRES = { code: 'VibeFlow · Code', projet: 'VibeFlow · Projet', equipe: 'VibeFlow · Équipe' };
  const MESSAGE_LECTURE = 'Lecture impossible : les données de cet onglet n\'ont pas pu être lues.';
  let manifeste = null, affiche = null, porte = null, file = Promise.resolve();
  let etat = { onglet: null, phase: 'chargement', motif: null };
  const retenu = {}; // onglet -> { etag, texte } : la dernière réponse 200 (le 304 ré-analyse ce texte, jamais un objet muté par le moteur)
  const delai = () => { const n = window.VF_COQUILLE_REGLAGES?.delaiMs; return Number.isInteger(n) && n >= 1000 && n <= 120000 ? n : 30000; };
  const attendreMs = (ms) => new Promise((ok) => setTimeout(ok, ms));
  const nomsDe = (...classes) => manifeste.fichiers.filter((f) => classes.includes(f.classe)).map((f) => f.nom);

  const poser = (nom) => new Promise((ok, ko) => {
    const s = D.createElement('script');
    s.src = manifeste.prefixe + nom; s.onload = () => ok(); s.onerror = () => ko(new Error('script de la coquille illisible : ' + nom));
    D.head.appendChild(s);
  });
  const enchainer = async (noms) => { for (const n of noms) await poser(n); };

  // la lecture de l'onglet : jeton de l'onglet, étiquette retenue ; 200 garde le texte, 304 réutilise le texte retenu, le reste est un échec au message fixe
  async function lireGraphe(nom) {
    const jeton = window.VF_COCKPIT_SERVER?.jetons?.[nom];
    const entetes = { 'x-vf-cockpit-token': jeton || '' };
    if (retenu[nom]) entetes['If-None-Match'] = retenu[nom].etag;
    let r; try { r = await fetch('/api/vf/graphe?onglet=' + nom, { headers: entetes }); } catch { throw new Error(MESSAGE_LECTURE); }
    if (r.status === 200) { const texte = await r.text(); retenu[nom] = { etag: r.headers.get('ETag') || '', texte }; }
    else if (r.status !== 304 || !retenu[nom]) throw new Error(MESSAGE_LECTURE);
    return JSON.parse(retenu[nom].texte);
  }

  // le démontage de l'onglet affiché : à la tâche suivante, la portée défait ce que le moteur et les extensions ont posé
  function demonter() {}

  async function demarrerOnglet(nom, graphe) {
    window.VF_COCKPIT = graphe;
    if (window.VF_COCKPIT_SERVER) window.VF_COCKPIT_SERVER.token = window.VF_COCKPIT_SERVER.jetons[nom];
    D.title = TITRES[nom];
    if (matchMedia('(max-width: 700px)').matches && !/[#&]s=/.test(location.hash)) D.body.classList.add('no-panel'); // un téléphone démarre panneau fermé
    let ouvrirPorte; porte = new Promise((ok) => { ouvrirPorte = ok; });
    await enchainer(nomsDe('i18n', 'moteur', 'onglet')); // l'ordre du manifeste : i18n, moteur, extensions
    const V = window.VibeFlow;
    const pret = new Promise((ok) => V.on('ready', () => ok()));
    ouvrirPorte();
    const limite = attendreMs(delai()).then(() => { throw new Error('Le premier rendu de l\'onglet n\'a pas eu lieu à temps.'); });
    await Promise.race([pret, limite]);
  }

  async function sequence(nom, initial) {
    etat = { onglet: nom, phase: 'chargement', motif: null };
    const graphe = await lireGraphe(nom);
    H.dataset.vfPret = 'non';
    demonter();
    await demarrerOnglet(nom, graphe);
    affiche = nom; etat = { onglet: nom, phase: 'pret', motif: null };
    H.dataset.vfPret = 'oui';
  }

  async function initial() {
    await enchainer(nomsDe('bibliotheque', 'persistant')); // garde:coquille-persistants
    await sequence(PAR_ADRESSE[location.pathname] || 'code', true);
  }

  function chargerOnglet(nom) {
    if (typeof nom !== 'string' || !ONGLETS.includes(nom)) return Promise.reject(new Error('Onglet inconnu.'));
    const p = file.then(() => sequence(nom, false));
    file = p.catch(() => {});
    return p;
  }

  window.VF_COQUILLE = Object.freeze({
    version: 1, chargerOnglet, onglet: () => affiche, etat: () => ({ ...etat }),
    porteMoteur: () => porte || Promise.resolve(),
  });

  D.addEventListener('DOMContentLoaded', () => {
    try { manifeste = JSON.parse(D.getElementById('vf-coquille-manifeste').textContent); } catch { return; }
    file = initial().catch(() => {});
  }, { once: true });
})();
