// vf-cockpit-methode — GET /api/vf/methode : les jauges de la Santé de la méthode, à la demande (77-03, P77-D-04, P77-D-20).
// Lance les deux gates du conductor en `--format=tsv` (lecture seule, sans réseau), de façon ASYNCHRONE et bornée, hors de la collecte :
// jamais au chargement du module ni d'une page ; au plus un lancement en cours, partagé par les requêtes simultanées ; résultat gardé 60 s ;
// 10 s par gate. Le script est résolu comme driverLockScript (jamais sous le lab observé) ; tout enfant reçoit envGit(lab) (aucun GIT_*
// hérité) ; un dépôt dont les métadonnées sortent du lab n'est pas lu. Tout échec devient l'objet « tout indisponible » (cause `echec`) :
// lire() ne rejette jamais. La traduction du TSV est celle de vf-cockpit-jauges.mjs.
// Export : TTL_MS, ECHEANCE_MS, creerMethode({ root, scriptsDir, home, lancer, now }) -> { lire() }, lireMethode(ctx, req, url).
import os from 'node:os';
import { driverLockScript, resolveScriptsDir, envGit, lancerAsync, finDans } from './vf-cockpit-paths.mjs';
import { gitSortant } from './vf-cockpit-git-sortant.mjs';
import { assembler, etatSource } from './vf-cockpit-jauges.mjs';

export const TTL_MS = 60000, ECHEANCE_MS = 10000;
const MAX_SORTIE = 1 << 20;
const INDISPO = (cause) => ({ etat: 'indisponible', cause, lignes: [], tronque: false });
const toutIndispo = (cause, at) => assembler({ methode: INDISPO(cause), densite: INDISPO(cause), at });

export function creerMethode({ root, scriptsDir, home = os.homedir(), lancer = lancerAsync, now = Date.now }) {
  let cache = null, vol = null; // le dernier objet servi { t, o } ; la promesse du lancement en cours
  const gate = (gateNom, args, env) => {
    const s = driverLockScript({ scriptsDir, labRoot: root, home, nom: `${gateNom}.sh` });
    return s.chemin ? lancer('bash', [s.chemin, ...args], root, env, MAX_SORTIE, finDans(ECHEANCE_MS)) : Promise.resolve({ absent: true });
  };
  const mesurer = async () => {
    const t = now(), at = new Date(t).toISOString();
    try {
      if (gitSortant(root, root)) return { t, o: toutIndispo('echec', at) }; // dépôt dont les métadonnées sortent du lab : rien n'est lancé
      const env = envGit(root);
      const [m, d] = await Promise.all([
        gate('check-method-budget', ['--root', root, '--no-remote', '--format=tsv'], env),
        gate('check-instruction-budget', ['--path', root, '--format=tsv'], env)]);
      const methode = etatSource(m, 'check-method-budget'), densite = etatSource(d, 'check-instruction-budget');
      return { t, o: assembler({ methode, densite, at }) };
    } catch { return { t, o: toutIndispo('echec', at) }; }
  };
  return {
    lire() {
      const t = now();
      if (cache && t >= cache.t && t - cache.t < TTL_MS) return Promise.resolve(cache.o);
      if (vol) return vol;
      vol = mesurer().then((r) => { cache = r; return r.o; }, () => toutIndispo('echec', new Date(t).toISOString())).finally(() => { vol = null; });
      return vol;
    },
  };
}

const PAR_RACINE = new Map(); // une instance par racine, créée à la première lecture
export async function lireMethode(ctx) {
  try {
    if (!PAR_RACINE.has(ctx.root)) PAR_RACINE.set(ctx.root, creerMethode({ root: ctx.root, scriptsDir: resolveScriptsDir(ctx.here) }));
    return await PAR_RACINE.get(ctx.root).lire();
  } catch { return toutIndispo('echec', new Date().toISOString()); }
}
