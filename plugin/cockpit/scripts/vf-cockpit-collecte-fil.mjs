// vf-cockpit-collecte-fil — point d'entrée du fil de la collecte (79-09, P79-D-12). Les chaînes de `workerData` sont calculées par le serveur
// (jamais lues d'une variable d'environnement ni d'un fichier du lab). Traite les demandes UNE à UNE dans l'ordre de réception et poste leurs
// résultats ; il ne diffuse rien et n'importe que les étapes.
// Demande { id, planning, verrous, tour, motifs } -> messages { id, type: 'planning' (graphe | erreur, motifs) | 'verrous' | 'tour' (verrous,
// equipe, erreurs, dureeMs) | 'fini' }.
import { parentPort, workerData } from 'node:worker_threads';
import { creerMemoire, etapePlanning, etapeVerrous, etapeTour } from './vf-cockpit-collecte-etapes.mjs';

const { racine, scriptsDir, home } = workerData, base = { racine, scriptsDir, home }, memo = creerMemoire();

parentPort.on('message', (m) => {
  const { id, motifs = [] } = m;
  if (m.planning) {
    try { parentPort.postMessage({ type: 'planning', id, motifs, graphe: etapePlanning(base) }); }
    catch (e) { parentPort.postMessage({ type: 'planning', id, motifs, erreur: String(e.message).slice(0, 200) }); }
  }
  if (m.verrous && !m.tour) {
    let verrous; try { verrous = etapeVerrous(base); } catch { verrous = { error: 'lecture impossible' }; }
    parentPort.postMessage({ type: 'verrous', id, verrous });
  }
  if (m.tour) parentPort.postMessage({ type: 'tour', id, ...etapeTour({ ...base, memo }) });
  parentPort.postMessage({ type: 'fini', id });
});
