// collecte-fil-essai — fil d'essai du pilote de la collecte (79-09, tâche 2) : même protocole que vf-cockpit-collecte-fil.mjs, scénario lu dans
// le fichier `scenario` du dossier `sortie` (workerData) À CHAQUE demande (il change en cours de test) ; journal : `journal` du même dossier.
// Scénarios : ok · lent (300 ms) · mort-avec-index (sort tant qu'il reçoit l'index, répond sans) · mort-toujours (lève au chargement) · oom (alloue
// jusqu'à la limite) · ecrivain (tient une écriture de 400 ms dans un appel natif non interruptible) · interdit (rend une clé interdite à profondeur 3).
// Journal : « lancement <fil> », « exec-debut/exec-fin <fil> <ms> », « debut-ecriture/fin-ecriture <fil> <ms> » (la fin est écrite par le shell du
// fil : un fil terminé en cours d'écriture ne peut pas la raccourcir).
import { parentPort, workerData, threadId } from 'node:worker_threads';
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const { sortie, sansIndex } = workerData, J = path.join(sortie, 'journal');
const note = (l) => fs.appendFileSync(J, `${l} ${threadId} ${Date.now()}\n`);
const scenario = () => { try { return fs.readFileSync(path.join(sortie, 'scenario'), 'utf8').trim(); } catch { return 'ok'; } };
note(sansIndex ? 'lancement-sans-index' : 'lancement');
if (scenario() === 'mort-toujours') throw new Error('ne démarre pas');
const dormir = (ms) => Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);

parentPort.on('message', (m) => {
  const sc = scenario(), { id, motifs = [] } = m;
  note('exec-debut');
  if (sc === 'mort-avec-index' && !sansIndex) process.exit(1);
  if (sc === 'lent') dormir(300);
  if (sc === 'ecrivain') {
    note('debut-ecriture');
    execFileSync('sh', ['-c', `sleep 0.4; echo "fin-ecriture ${threadId} $(date +%s)000" >> "${J}"`]);
  }
  if (sc === 'oom') { const t = []; for (;;) t.push(new Array(1e6).fill(Math.random())); }
  if (m.planning) parentPort.postMessage({ type: 'planning', id, motifs, graphe: { nodes: [], files: [], meta: {} } });
  if (m.tour || m.verrous) {
    const equipe = { workers: sc === 'interdit' ? [{ id: 'w1', kind: 'worker', a: { b: { cleInterdite: 'x' } } }] : [{ id: 'w1', kind: 'worker' }], sources: {} };
    parentPort.postMessage({ type: 'tour', id, verrous: { etat: 'absente', plat: false, liste: [] }, equipe, erreurs: [], dureeMs: 1 });
    parentPort.postMessage({ type: 'index', id, index: sansIndex ? { etat: 'suspendu', voies: 0, formeInconnue: 0, evinces: 0 } : { etat: 'ok', voies: 0, formeInconnue: 0, evinces: 0 } });
  }
  parentPort.postMessage({ type: 'fini', id });
  note('exec-fin');
});
