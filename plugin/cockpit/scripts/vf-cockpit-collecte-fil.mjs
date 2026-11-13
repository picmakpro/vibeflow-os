// vf-cockpit-collecte-fil — point d'entrée du fil de la collecte (79-09, P79-D-12). Les chaînes de `workerData` sont calculées par le serveur
// (jamais lues d'une variable d'environnement ni d'un fichier du lab). Traite les demandes UNE à UNE dans l'ordre de réception et poste leurs
// résultats ; il ne diffuse rien et n'importe que les étapes.
// Demande { id, planning, verrous, tour, motifs } -> messages { id, type: 'planning' (graphe | erreur, motifs) | 'verrous' (projection en liste
// blanche, A15) | 'tour' (verrous projetés, equipe, signal, erreurs, dureeMs) | 'index' (rapport en comptes, jamais les voies) |
// 'frise' (paquet de voies, 79-13) | 'fini' }. workerData.sansIndex : relance sans l'index.
// 73-03 : 'planning' et 'tour' portent aussi `lecturesPlanning` (compteur du fil).
import { parentPort, workerData } from 'node:worker_threads';
import { creerMemoire, etapePlanning, etapeVerrous, etapeTour } from './vf-cockpit-collecte-etapes.mjs';
import { tranche } from './vf-cockpit-collecte-frise.mjs';

const { racine, sortie, scriptsDir, home, sansIndex } = workerData, base = { racine, sortie, scriptsDir, home }, memo = creerMemoire();
const compte = () => ({ lecturesPlanning: memo.lecturesPlanning }); // 73-03

// passe de fond des cibles (79-13) : une tranche par rendez-vous de boucle, donc les messages entrants passent entre deux tranches
let chaine = false; // une seule chaîne de tranches à la fois
const enchainer = () => { chaine = true; setImmediate(() => {
  let t; try { t = tranche({ memo }); } catch { chaine = false; return; }
  for (const x of t.messages) parentPort.postMessage({ type: 'frise', id: 0, ...x });
  if (t.reste) enchainer(); else chaine = false;
}); };

parentPort.on('message', (m) => {
  const { id, motifs = [] } = m;
  if (m.planning) {
    try { const graphe = etapePlanning({ ...base, memo }); parentPort.postMessage({ type: 'planning', id, motifs, graphe, ...compte() }); }
    catch (e) { parentPort.postMessage({ type: 'planning', id, motifs, erreur: String(e.message).slice(0, 200), ...compte() }); }
  }
  if (m.verrous && !m.tour) {
    let verrous; try { verrous = etapeVerrous({ ...base, memo }); } catch { verrous = { etat: 'erreur', plat: false, liste: [] }; }
    parentPort.postMessage({ type: 'verrous', id, verrous });
  }
  if (m.tour) {
    // revue 73-03 : un fil relancé repart avec un memo vide ; sans regie, le tour la lit une fois
    // (même lecture que `planning`), jamais par tour de 5 s
    if (memo.regie === undefined && !memo.regieTentee) {
      memo.regieTentee = true;
      try { etapePlanning({ ...base, memo }); } catch { /* le tour dégrade */ }
    }
    let r; // un tour qui lève ne tue pas le fil : un tour neuf et neutre, `tour` dans les erreurs (la collecte devient `partielle`)
    try { r = etapeTour({ ...base, memo, sansIndex: !!sansIndex }); } catch { // garde:fil-tour
      r = { verrous: { etat: 'erreur', plat: false, liste: [] }, equipe: { workers: [], sources: {} }, signal: null, erreurs: ['tour'], dureeMs: 1,
        index: { etat: 'erreur', tronque: false, voies: 0, formeInconnue: 0, evinces: 0 } };
    }
    const { index, frise, ...tour } = r;
    parentPort.postMessage({ type: 'tour', id, ...tour, ...compte() }); parentPort.postMessage({ type: 'index', id, index });
    for (const f of (frise && frise.messages) || []) parentPort.postMessage({ type: 'frise', id, ...f }); // 79-13 : voies par paquets, avant `fini`
  }
  parentPort.postMessage({ type: 'fini', id });
  if (m.tour && !chaine && memo.frise && memo.frise.suivi.reste()) enchainer();
});
