// Route /api/vf/ailleurs (sessions d'autres labs), extraite de vf-cockpit-server.mjs : plafond de 250 lignes (test-cockpit-routes F.1).
import os from 'node:os';
import { ailleurs, demander, REPIT_MS } from './vf-cockpit-etat-officiel.mjs';
import { arbresGitAsync } from './vf-cockpit-arbres.mjs';
import { finDans } from './vf-cockpit-paths.mjs';

// GET /api/vf/ailleurs (73-02, P73-D-16, P73-D-35) : sessions d'AUTRES labs qui vous attendent, par NOM de lab seulement ; dérive de
// la dernière lecture officielle gardée en mémoire de CE processus (la collecte lit la sienne dans son fil : invisible ici ;
// `demander` relance la lecture au plus une fois par REPIT_MS, jamais une par requête). Les arbres du lab sont relus au plus une
// fois par REPIT_MS ; jamais de git dans un autre dépôt ; la route attend (BORNE_AILLEURS_MS) les lectures en vol, null si aucune lecture fraîche n'aboutit.
// Garde d'émission propre à ailleurs@1 (audit 73-02) : la liste d'interdits de who@2 (porteInterdit) ne dit rien de ce contrat ;
// chaque entrée a EXACTEMENT les clés { lab, n }, sinon elle ne sort pas.
const exacte = (e) => !!e && typeof e === 'object' && Object.keys(e).sort().join() === 'lab,n';
const racinesLab = new Map(); // racine du lab -> { at, liste }
const BORNE_AILLEURS_MS = 3000; // revue 73 : la route attend les lectures en vol, au plus ce temps (la boucle reste libre : attente asynchrone)
export const lireAilleurs = async (c) => {
  const now = Date.now();
  const officiel = demander({ home: os.homedir(), cwd: c.root });
  let m = racinesLab.get(c.root);
  if (!m) { m = { at: 0, liste: null, enCours: false, vol: null }; racinesLab.set(c.root, m); }
  if (!m.enCours && now - m.at >= REPIT_MS) { // lecture ASYNCHRONE (P78-D-41) ; la route attend sa fin, bornée
    m.enCours = true; m.at = now;
    m.vol = arbresGitAsync(c.root, { fin: finDans(5000) }).then((a) => { m.liste = a.map((t) => t.chemin); }, () => { m.liste = null; })
      .finally(() => { m.enCours = false; });
  }
  let minuteur; // lectures en vol (état officiel, arbres du lab) attendues ensemble ;
  // au-delà de la borne : ce que la mémoire porte déjà (null si rien de frais)
  await Promise.race([Promise.all([officiel, m.enCours ? m.vol : null]), new Promise((fin) => { minuteur = setTimeout(fin, BORNE_AILLEURS_MS); })]);
  clearTimeout(minuteur);
  const l = ailleurs(os.homedir(), { racines: m.liste });
  return { schema: 'vibeflow/cockpit-ailleurs@1', ailleurs: Array.isArray(l) ? l.filter(exacte) : l };
};
