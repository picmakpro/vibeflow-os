// vf-cockpit-collecte-etapes — les étapes SYNCHRONES de la collecte, appelables sans fil (79-09, P79-D-12, A32). Le fil (vf-cockpit-collecte-fil.mjs)
// les appelle ; les suites les appellent directement. Aucun changement de dossier courant de processus : tout `cwd` passe en option. Aucune
// diffusion : une étape rend un résultat.
// Exports : creerMemoire() (état du fil entre deux demandes), etapePlanning({ racine }) (graphe Projet, lu une fois : A32, lieu unique de la
//           lecture du planning), etapeVerrous({ racine, scriptsDir, home, memo }) (`driver-lock.sh status --all` lu puis PROJETÉ en liste blanche :
//           { etat, plat, liste }, A15 ; la sortie brute ne quitte jamais l'étape),
//           etapeTour({ racine, sortie, scriptsDir, home, memo, maintenant, sansIndex })
//           (verrou lu une fois ; équipe avec l'état officiel et CE MÊME verrou ; verrous projetés avec les sessions de la collecte ; signal construit sur
//           cette équipe et ces verrous ; puis l'index des transcripts, sauf sansIndex) -> { verrous, equipe, signal, erreurs, dureeMs, index }
//           (index : rapport en comptes ; les voies restent dans memo.index ; memo.sessions : sessions de la dernière équipe lue).
// `erreurs` : noms d'étapes d'une liste fermée (`verrous`, `equipe`, `signal`, `index`, et `tour` posté par le fil quand le tour entier lève) ;
// un échec laisse un résultat neutre, comme la collecte d'avant : le tour dégrade, il ne lève jamais.
import { buildProjectGraph } from './vf-cockpit-project.mjs';
import { collectWho } from './vf-cockpit-who.mjs';
import { driverLockScript, shBorne } from './vf-cockpit-paths.mjs';
import { etapeIndex } from './vf-cockpit-collecte-index.mjs';
import { verrousDe } from './vf-cockpit-vie.mjs';
import { collectSignal, projeterVerrous } from './vf-cockpit-signal.mjs';

export const creerMemoire = () => ({});

export const etapePlanning = ({ racine }) => buildProjectGraph(racine);

// forme `{ available: false }` si le script est absent, `{ error }` si la sortie est illisible, sinon l'objet de `status --all`
// (BRUT : reste dans l'étape et dans `who`)
function lireBrut({ racine, scriptsDir, home }) {
  const dl = driverLockScript({ scriptsDir, labRoot: racine, home });
  if (dl.etat === 'absent') return { available: false };
  const sortie = shBorne('bash', [dl.chemin, 'status', '--all'], racine, racine);
  try { return JSON.parse(sortie); } catch { return { error: 'sortie du verrou illisible' }; }
}

const projeter = (brut, memo) => projeterVerrous(verrousDe(brut, { sessions: memo.sessions }));
export function etapeVerrous({ racine, scriptsDir, home, memo = creerMemoire() }) { return projeter(lireBrut({ racine, scriptsDir, home }), memo); }

export function etapeTour({ racine, sortie, scriptsDir, home, memo = creerMemoire(), maintenant = Date.now(), sansIndex = false }) { // garde:etape-tour
  const t0 = Date.now(), erreurs = [];
  let brut = { available: false };
  try { brut = lireBrut({ racine, scriptsDir, home }); } catch { erreurs.push('verrous'); }
  let equipe;
  try { equipe = collectWho(racine, { scriptsDir, verrous: brut, officiel: true, home }); } catch (e) {
    erreurs.push('equipe'); equipe = { workers: [], sources: {}, error: String(e.message).slice(0, 200) };
  }
  // sansSession se décide sur les sessions de CETTE équipe ; équipe illisible : aucun verdict (l'ensemble reste celui du tour précédent, ou absent)
  if (!equipe.error) memo.sessions = new Set(equipe.workers.filter((w) => w.kind === 'session').map((w) => w.id));
  let verrous = { etat: 'erreur', plat: false, liste: [] };
  try { verrous = projeter(brut, memo); } catch { erreurs.push('verrous'); } // garde:etape-projeter
  let signal = null;
  try { signal = collectSignal(racine, { home, scriptsDir, equipe, verrous }); } catch { erreurs.push('signal'); }
  let index;
  const VIDE = { etat: 'erreur', tronque: false, voies: 0, formeInconnue: 0, evinces: 0 };
  try { index = etapeIndex({ racine, sortie, home, memo, who: equipe.workers, maintenant, sansIndex }); } catch { erreurs.push('index'); index = VIDE; }
  return { verrous, equipe, signal, erreurs, dureeMs: Math.max(1, Date.now() - t0), index };
}
