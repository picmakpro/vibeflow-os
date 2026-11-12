// vf-cockpit-collecte-etapes — les étapes SYNCHRONES de la collecte, appelables sans fil (79-09, P79-D-12, A32). Le fil (vf-cockpit-collecte-fil.mjs)
// les appelle ; les suites les appellent directement. Aucun changement de dossier courant de processus : tout `cwd` passe en option. Aucune
// diffusion : une étape rend un résultat.
// Exports : creerMemoire() (état du fil entre deux demandes), etapePlanning({ racine }) (graphe Projet, lu une fois : A32, lieu unique de la
//           lecture du planning), etapeVerrous({ racine, scriptsDir, home }) (lecture brute de `driver-lock.sh status --all`),
//           etapeTour({ racine, scriptsDir, home, memo }) (verrous puis équipe avec l'état officiel et CE MÊME verrou : un seul appel au
//           verrou par tour) -> { verrous, equipe, erreurs, dureeMs }.
// `erreurs` : noms d'étapes d'une liste fermée (`verrous`, `equipe`) ; un échec laisse un résultat neutre, comme la collecte d'avant.
import { buildProjectGraph } from './vf-cockpit-project.mjs';
import { collectWho } from './vf-cockpit-who.mjs';
import { driverLockScript, shBorne } from './vf-cockpit-paths.mjs';

export const creerMemoire = () => ({});

export const etapePlanning = ({ racine }) => buildProjectGraph(racine);

// forme `{ available: false }` si le script est absent, `{ error }` si la sortie est illisible, sinon l'objet de `status --all`
export function etapeVerrous({ racine, scriptsDir, home }) {
  const dl = driverLockScript({ scriptsDir, labRoot: racine, home });
  if (dl.etat === 'absent') return { available: false };
  const sortie = shBorne('bash', [dl.chemin, 'status', '--all'], racine, racine);
  try { return JSON.parse(sortie); } catch { return { error: 'sortie du verrou illisible' }; }
}

export function etapeTour({ racine, scriptsDir, home }) {
  const t0 = Date.now(), erreurs = [];
  let verrous = { available: false };
  try { verrous = etapeVerrous({ racine, scriptsDir, home }); } catch { erreurs.push('verrous'); }
  let equipe;
  try { equipe = collectWho(racine, { scriptsDir, verrous, officiel: true, home }); } catch (e) {
    erreurs.push('equipe'); equipe = { workers: [], sources: {}, error: String(e.message).slice(0, 200) };
  }
  return { verrous, equipe, erreurs, dureeMs: Math.max(1, Date.now() - t0) };
}
