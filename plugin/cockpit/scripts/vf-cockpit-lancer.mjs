// vf-cockpit-lancer — assemblage du lancement côté serveur P (72-09 ; P72-D-06, D-09 à D-12, D-16, D-17 ; LANC-01 à LANC-04, LANC-08, LANC-10).
// Routes (jamais sans le drapeau : le registre du canal est alors vide, voir vf-cockpit-lancer-canal.mjs) :
//   GET  /api/vf/lancer/cibles  { actif, terminal, claude, cibles } ; cible = { id, kind, principal, verbes, bloquants, avertissements, lancee } (jamais un titre, un Goal ni un nom)
//   POST /api/vf/terminal/terminer  {} -> 200 { termine:true } : ferme la session du shell (AUDC-M10), le serveur du terminal reste actif
//   POST /api/vf/lancer         { cible, verbe[, chat] } -> 202 { propose: true } : P PROPOSE seulement, la confirmation et l'écriture au PTY sont dans Q (72-10)
// Messages envoyés à Q par l'IPC : { t:'cibles', cibles } (liste fermée recalculée du disque, toujours AVANT une proposition) puis { t:'proposition', … }.
// Message reçu de Q : { t:'lancee', cible, verbe, session, at }, validé de façon fermée puis noté par le suivi (72-07). `lancee` d'une cible rendue : { etat, verbe } ou false.
// Refus du gestionnaire (corps { refus: <code fermé> }) : cible-inconnue 404, verbe-refuse 422, chat-invalide 422, bloque 409 (+ codes), terminal-arrete 503,
//   terminal-indisponible 503, cibles-indisponibles 503. Aucune ligne de commande n'est composée ici ; aucun texte du lab ne sort ; aucun journal (un avertissement sans donnée).
// Aucun effet de bord à l'import ni à la création : le disque n'est lu qu'à une requête servie. Pas de `git status` (P72-D-07).
import fs from 'node:fs';
import { planningLayout } from './vf-cockpit-paths.mjs';
import { readPlanning } from './vf-cockpit-planning.mjs';
import { lireAilleurs, fusionner } from './vf-cockpit-ailleurs.mjs';
import * as gabarit from './vf-cockpit-lancer-gabarit.mjs';
import { calculerCibles, listePourQ, verdict } from './vf-cockpit-lancer-cibles.mjs';
import { creerPost } from './vf-cockpit-lancer-post.mjs';
import { creerSuivi } from './vf-cockpit-lancer-suivi.mjs';
import { canal } from './vf-cockpit-lancer-canal.mjs';

const ROUTE_GET = '/api/vf/lancer/cibles', ROUTE_POST = '/api/vf/lancer', ROUTE_TERMINER = '/api/vf/terminal/terminer';
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/; // minuscules, comme le gabarit (MOTIF_UUID)
const CLES_LANCEE = 'at,cible,session,t,verbe';
const sur = (fn, repli) => { try { return fn(); } catch { return repli; } };

export function creerLancer({ root, here, ptoken, log = () => {} }) {
  const suivi = creerSuivi({ maintenant: Date.now });
  let dernier = null; // dernier résultat de readPlanning, fusionné avec les arbres voisins
  let envoyee = []; // dernière liste envoyée à Q : seule référence de ce que Q peut confirmer
  let dernierEnvoi = '', abonne = null, postObj = null, qui = null, avert = false;
  const servi = () => canal() !== null;

  const planning = () => {
    const P = readPlanning(root, planningLayout(root));
    P.phases = fusionner(P.phases, lireAilleurs(root)); dernier = P;
    return { phases: P.phases, dags: P.dags };
  };
  const fichiers = (ph) => { // noms du dossier de la phase, tels que relevés par readPlanning
    const d = dernier && dernier.phaseDirs && (dernier.phaseDirs.get(`${ph.ws || ''}|${ph.n}`) || dernier.phaseDirs.get(`*|${ph.n}`));
    return d ? sur(() => fs.readdirSync(d), []) : [];
  };
  function calculer() {
    const c = canal();
    const r = sur(() => calculerCibles({ gabarit, planning, fichiers, lancements: suivi.lancements, maintenant: Date.now,
      terminal: () => (c ? c.etat() : 'arrete'), claude: () => !!c && c.claude(), python3: () => !!c && c.python3() }), null);
    if (r && r.contexte && r.contexte.planning) return r;
    if (!avert) { avert = true; log('warn', 'calcul des cibles impossible'); }
    return null;
  }
  function publier(cibles, force) { // liste fermée vers Q : seules les cibles sans bloquant, six champs chacune
    const c = canal(); if (!c) return false;
    const pq = listePourQ(cibles.filter((x) => x.bloquants.length === 0), gabarit), cle = JSON.stringify(pq);
    if (!force && cle === dernierEnvoi) return true;
    if (!sur(() => c.envoyer({ t: 'cibles', cibles: pq }), false)) return false;
    dernierEnvoi = cle; envoyee = pq; return true;
  }
  const lanceeValide = (m) => !!m && typeof m === 'object' && !Array.isArray(m) && Object.keys(m).sort().join() === CLES_LANCEE && m.t === 'lancee'
    && typeof m.cible === 'string' && typeof m.verbe === 'string' && typeof m.session === 'string' && gabarit.MOTIF_UUID_V4.test(m.session) && Number.isInteger(m.at)
    && envoyee.some((e) => e.id === m.cible && e.verbes.includes(m.verbe));
  function surLancee(m) {
    if (!lanceeValide(m)) return;
    const e = envoyee.find((x) => x.id === m.cible);
    suivi.noter(m, { phase: e ? e.phase : null, ws: e ? e.ws : null });
  }
  const abonner = (c) => { if (c && abonne !== c) { abonne = c; sur(() => c.abonner(surLancee), null); } }; // à la première requête qui trouve le canal renseigné, jamais à la création

  function proposer(demande) {
    const c = canal(), etat = c ? c.etat() : 'arrete';
    if (etat !== 'actif') return { statut: 503, corps: { refus: etat === 'indisponible' ? 'terminal-indisponible' : 'terminal-arrete' } };
    abonner(c);
    const calcul = calculer(); if (!calcul) return { statut: 503, corps: { refus: 'cibles-indisponibles' } };
    const liste = calcul.cibles;
    const cible = liste.find((x) => x.id === demande.cible);
    if (!cible) return { statut: 404, corps: { refus: 'cible-inconnue' } };
    const v = verdict(liste, cible.id, demande.verbe); // l'unique règle « verbe permis, aucun bloquant » : jamais refaite ici
    if (!v) return { statut: 422, corps: { refus: 'verbe-refuse' } };
    if (!v.lancable) return { statut: 409, corps: { refus: 'bloque', bloquants: v.bloquants } };
    const chat = demande.chat;
    if (chat !== undefined && !UUID.test(chat)) return { statut: 422, corps: { refus: 'chat-invalide' } };
    if (!publier(liste, true)) return { statut: 503, corps: { refus: 'terminal-arrete' } };
    const msgProposition = { t: 'proposition', cible: cible.id, verbe: demande.verbe, bloquants: cible.bloquants, avertissements: cible.avertissements };
    if (chat) msgProposition.chat = chat;
    if (!sur(() => c.envoyer(msgProposition), false)) return { statut: 503, corps: { refus: 'terminal-arrete' } };
    return { statut: 202, corps: { propose: true } };
  }
  // AUDC-M10 : « Terminer la session » du tiroir ; mêmes contrôles que le lancement (hôte, origine, jeton de la page Projet, corps `{}`) ; ne passe que le message fermé { t:'terminer' } à Q, qui ferme le shell et garde son serveur
  const terminer = async () => (sur(() => canal().envoyer({ t: 'terminer' }), false) ? { statut: 200, corps: { termine: true } } : { statut: 503, corps: { refus: 'terminal-arrete' } });
  const routes = { [ROUTE_TERMINER]: { champs: {}, gestionnaire: terminer }, [ROUTE_POST]: { champs: { cible: { type: 'string', max: 128, requis: true }, verbe: { type: 'string', max: 16, requis: true }, chat: { type: 'string', max: 36, requis: false } },
    gestionnaire: async (demande) => proposer(demande) } };
  const post = () => (postObj ||= creerPost({ routes, jetons: () => [ptoken] })); // créé à la première requête servie ; seul le jeton de la page Projet est admis

  function get(req, res, url) {
    if (!servi() || url.pathname !== ROUTE_GET) return false;
    const c = canal(), etat = c ? c.etat() : 'arrete';
    if (etat !== 'actif') dernierEnvoi = ''; // un Q relancé n'a pas la liste : la prochaine lecture la renvoie
    abonner(c);
    const calcul = calculer(), liste = calcul ? calcul.cibles : [];
    if (calcul && etat === 'actif') publier(liste, false);
    const riche = suivi.etats(sur(() => (qui ? qui() : null), null));
    const cibles = liste.map((x) => ({ id: x.id, kind: x.kind, principal: x.principal, verbes: x.verbes, bloquants: x.bloquants, avertissements: x.avertissements, lancee: riche.get(x.id) || false }));
    res.writeHead(200, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' });
    res.end(JSON.stringify({ actif: true, terminal: etat, claude: !!c && sur(() => c.claude() === true, false), cibles }));
    return true;
  }
  return {
    get, lancees: () => suivi.lancees(),
    reconnait: (url) => servi() && post().reconnait(url),
    traiter: (req, res, url) => post().traiter(req, res, url),
    sourceWho: (fn) => { if (typeof fn === 'function') qui = fn; }, // le `who` de la collecte Équipe, pour les états attendue / vue / terminee
  };
}
