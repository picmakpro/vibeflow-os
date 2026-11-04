// Les gestes humains qui lancent un processus : retrouver `driver-lock.sh` et élaguer un verrou périmé (P68-D-13).
// Jamais lancés par le mod seul : un bouton, appuyé par une personne.

import type { EngineInterface } from 'claude-code'

import { oneLine } from './ds'
import { classerEchec } from './socle'
/**
 * Où `driver-lock.sh` se trouve, dans l'ordre de P68-D-13 : la racine du plugin (toujours présente dans un plugin
 * installé), puis les scripts posés dans le lab, puis ceux du compte. Aucune recherche ailleurs ; null si rien n'existe.
 */
export async function resoudreDriverLock($: EngineInterface, pluginRoot: string, root: string, home: string | undefined): Promise<string | null> {
  const candidats = [
    `${pluginRoot.replace(/\/+$/, '')}/conductor/scripts/driver-lock.sh`,
    `${root}/.claude/scripts/driver-lock.sh`,
    home ? `${home}/.claude/scripts/driver-lock.sh` : '',
  ].filter(Boolean)
  for (const chemin of candidats) {
    if (await $.fs.exists(chemin).catch(() => false)) return chemin
  }
  return null
}

/** `driver-lock.sh recover [--ws=<ws>]` depuis la racine de session (exigée par le verrou) ; le code de sortie est dit en toast. */
export async function elaguer($: EngineInterface, script: string, ws: string | null, root: string): Promise<void> {
  const argv = ['bash', script, 'recover', ...(ws ? [`--ws=${ws}`] : [])]
  const ran = await $.process.run(argv, { cwd: root, timeoutMs: 15000 }).catch(() => undefined)
  $.ui.toast(ran ? `recover · exit ${ran.exitCode} · ${oneLine(ran.stdout).slice(0, 120)}` : 'recover : driver-lock.sh ne démarre pas')
}

/**
 * Où `vf-cockpit.mjs` se trouve, dans l'ordre du verbe `/vf-cockpit` et de P68-D-25 : le script posé dans le lab, puis celui du
 * compte, puis celui du plugin (`$.plugin.root`, toujours présent dans un plugin installé). Premier existant ; à défaut, celui du
 * plugin : la fonction rend toujours un chemin.
 */
export async function resoudreLanceur($: EngineInterface, pluginRoot: string, root: string, home: string | undefined): Promise<string> {
  const candidats = [`${root}/.claude/scripts/vf-cockpit.mjs`, home ? `${home}/.claude/scripts/vf-cockpit.mjs` : ''].filter(Boolean)
  for (const chemin of candidats) {
    if (await $.fs.exists(chemin).catch(() => false)) return chemin
  }
  return `${pluginRoot.replace(/\/+$/, '')}/cockpit/scripts/vf-cockpit.mjs`
}

// Les codes de sortie du lanceur, comme la table du README du module (le code 64 et les autres : « échec »).
const CODES: Record<number, string> = {
  2: 'lab sans dossier de planning',
  3: 'moteur absent (réinstaller le module)',
  4: 'assemblage en échec',
  5: 'serveur non démarré',
}

/**
 * `node <lanceur> open --lab <racine>` depuis la racine de session. Seule l'adresse `http://127.0.0.1:<port>` est prise du
 * stdout (motif fixe) : tout le reste de la sortie n'est jamais affiché. Geste humain seulement (ADR-031).
 */
export async function ouvrirCockpit($: EngineInterface, lanceur: string, root: string): Promise<{ url: string } | { erreur: string }> {
  let ran
  try {
    ran = await $.process.run(['node', lanceur, 'open', '--lab', root], { cwd: root, timeoutMs: 60000 })
  } catch (err) {
    return { erreur: classerEchec(err, 'lanceur') }
  }
  if (ran.exitCode !== 0) return { erreur: `cockpit : ${CODES[ran.exitCode] ?? 'échec'} (code ${ran.exitCode})` }
  const adresse = /http:\/\/127\.0\.0\.1:\d+/.exec(ran.stdout)
  return adresse ? { url: `${adresse[0]}/` } : { erreur: 'cockpit : adresse introuvable dans la sortie du lanceur' }
}
