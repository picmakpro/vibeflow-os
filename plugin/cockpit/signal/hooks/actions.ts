// Les gestes humains qui lancent un processus : retrouver `driver-lock.sh` et élaguer un verrou périmé (P68-D-13).
// Jamais lancés par le mod seul : un bouton, appuyé par une personne.

import type { EngineInterface } from 'claude-code'

import { oneLine } from './ds'
import { envSain } from './env-sain'
import { classerEchec } from './socle'
const sansSlash = (c: string) => c.replace(/\/+$/, '')
const sous = (c: string, dir: string) => c === dir || c.startsWith(`${sansSlash(dir)}/`)

/** Où le chemin atterrit (liens suivis) : `$.fs.stat(…, { resolve })` ; undefined quand il ne mène nulle part (le garde refuse alors, comme le dit le d.ts). */
async function reel($: EngineInterface, chemin: string): Promise<string | undefined> {
  const st = await $.fs.stat(chemin, { resolve: true }).catch(() => undefined)
  return st?.realPath
}

/**
 * P68-D-34 (comme `realUnder` et la garde T-67-06 du socle) : un fichier du compte ou du plugin n'est pris que si ni son chemin ni
 * son realpath ne tombent sous le lab (`dir`) ; `module` (la racine du plugin, posée par l'installation) n'est refusé que sous la
 * sortie `<lab>/.vibeflow`. Un lien du compte qui mène dans le lab est donc refusé. Un fichier dont le realpath manque est refusé aussi
 * (P68-D-37 : la règle ne se rabat plus sur le chemin écrit) ; la racine du lab, elle, se rabat sur son écriture.
 */
async function admis($: EngineInterface, chemin: string, root: string, module: boolean): Promise<boolean> {
  const dir = sansSlash(module ? `${root}/.vibeflow` : root)
  const [cible, base] = await Promise.all([reel($, chemin), reel($, dir)])
  if (cible === undefined) return false
  return ![chemin, cible].some(c => sous(c, dir) || sous(c, base ?? dir))
}

/**
 * Où `driver-lock.sh` se trouve, dans l'ordre de P68-D-34 : la racine du plugin, puis les scripts du compte. Rien sous le lab :
 * le repli de P68-D-13 sur `<lab>/.claude/scripts` est retiré. Null si rien n'existe ou si tout tombe sous le lab.
 */
export async function resoudreDriverLock($: EngineInterface, pluginRoot: string, root: string, home: string | undefined): Promise<string | null> {
  const candidats = [
    { c: `${sansSlash(pluginRoot)}/conductor/scripts/driver-lock.sh`, module: true },
    { c: home ? `${home}/.claude/scripts/driver-lock.sh` : '', module: false },
  ].filter(x => x.c)
  for (const { c, module } of candidats) {
    if ((await $.fs.exists(c).catch(() => false)) && (await admis($, c, root, module))) return c
  }
  return null
}

/** `driver-lock.sh recover [--ws=<ws>]` depuis la racine de session (exigée par le verrou : le `cwd` y reste), PATH assaini ; le code de sortie est dit en toast. */
export async function elaguer($: EngineInterface, script: string, ws: string | null, root: string): Promise<void> {
  const argv = ['bash', script, 'recover', ...(ws ? [`--ws=${ws}`] : [])]
  const env = await envSain($, root)
  const ran = await $.process.run(argv, { cwd: root, env, timeoutMs: 15000 }).catch(() => undefined)
  $.ui.toast(ran ? `recover · exit ${ran.exitCode} · ${oneLine(ran.stdout).slice(0, 120)}` : 'recover : driver-lock.sh ne démarre pas')
}

/**
 * Où `vf-cockpit.mjs` se trouve, dans l'ordre de P68-D-34 (qui amende P68-D-25) : le script du compte, puis celui du plugin
 * (`$.plugin.root`, toujours présent dans un plugin installé). Rien sous le lab : le script posé dans le lab n'est jamais cherché.
 * Premier existant et admis ; à défaut, celui du plugin : la fonction rend toujours un chemin.
 */
export async function resoudreLanceur($: EngineInterface, pluginRoot: string, root: string, home: string | undefined): Promise<string> {
  const compte = home ? `${home}/.claude/scripts/vf-cockpit.mjs` : ''
  if (compte && (await $.fs.exists(compte).catch(() => false)) && (await admis($, compte, root, false))) return compte
  return `${sansSlash(pluginRoot)}/cockpit/scripts/vf-cockpit.mjs`
}

// Les codes de sortie du lanceur, comme la table du README du module (le code 64 et les autres : « échec »).
const CODES: Record<number, string> = {
  2: 'lab sans dossier de planning',
  3: 'moteur absent (réinstaller le module)',
  4: 'assemblage en échec',
  5: 'serveur non démarré',
}

/**
 * `node <lanceur> open --lab <racine>` depuis la racine du plugin (`--lab` suffit, jamais le lab comme `cwd`), PATH assaini. Seule l'adresse `http://127.0.0.1:<port>` est prise du
 * stdout (motif fixe) : tout le reste de la sortie n'est jamais affiché. Geste humain seulement (ADR-031).
 */
export async function ouvrirCockpit($: EngineInterface, lanceur: string, root: string, pluginRoot: string): Promise<{ url: string } | { erreur: string }> {
  let ran
  try {
    ran = await $.process.run(['node', lanceur, 'open', '--lab', root], { cwd: sansSlash(pluginRoot), env: await envSain($, root), timeoutMs: 60000 })
  } catch (err) {
    return { erreur: classerEchec(err, 'lanceur') }
  }
  if (ran.exitCode !== 0) return { erreur: `cockpit : ${CODES[ran.exitCode] ?? 'échec'} (code ${ran.exitCode})` }
  const adresse = /http:\/\/127\.0\.0\.1:\d+/.exec(ran.stdout)
  return adresse ? { url: `${adresse[0]}/` } : { erreur: 'cockpit : adresse introuvable dans la sortie du lanceur' }
}
