// Les gestes humains qui lancent un processus : retrouver `driver-lock.sh` et élaguer un verrou périmé (P68-D-13).
// Jamais lancés par le mod seul : un bouton, appuyé par une personne.

import type { EngineInterface } from 'claude-code'

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
  $.ui.toast(ran ? `recover · exit ${ran.exitCode} · ${ran.stdout.trim().slice(0, 120)}` : 'recover : driver-lock.sh ne démarre pas')
}
