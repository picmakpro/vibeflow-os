// L'environnement des processus que le mod lance (classe H-1 de l'audit 67-SECURITY ; PR 201 côté socle : `scripts/vf-cockpit-env.mjs`).
// Un PATH qui porte une entrée vide, relative ou sous le lab ferait exécuter à la place de `node`/`bash` un programme posé dans le lab.
// Même règle que le socle : on écarte ces entrées, et on retombe sur un PATH système si plus rien ne reste. `$.process.run` pose
// `init.env` PAR-DESSUS l'environnement du processus hôte : on ne passe donc que `PATH` et la variable vidée, jamais le reste. Le PATH de la personne n'est pas modifié.

import type { EngineInterface } from 'claude-code'

export const PATH_REPLI = '/usr/bin:/bin:/usr/sbin:/sbin'

const absolu = (el: string) => el.startsWith('/') || /^[A-Za-z]:[\\/]/.test(el)

/** Le chemin sans `.` ni `..` ni `/` répété ; le sens d'écriture (`/a/../b` → `/b`) est celui que le système donnera. */
function normaliser(el: string): string {
  const out: string[] = []
  for (const seg of el.split(/[\\/]+/)) {
    if (seg === '' || seg === '.') continue
    if (seg === '..') out.pop()
    else out.push(seg)
  }
  return `/${out.join('/')}`
}

const sous = (el: string, dir: string) => dir !== '/' && (el === dir || el.startsWith(`${dir}/`))

async function reel($: EngineInterface, chemin: string): Promise<string | undefined> {
  const st = await $.fs.stat(chemin, { resolve: true }).catch(() => undefined)
  return st?.realPath === undefined ? undefined : normaliser(st.realPath)
}

/** Les entrées du PATH de l'hôte qui ne tombent pas sous le lab (ni par leur écriture, ni par leur realpath). */
export async function pathSain($: EngineInterface, root: string): Promise<string> {
  const brut = (await $.env.get('PATH').catch(() => undefined)) ?? ''
  const delim = brut.includes(';') ? ';' : ':'
  const labs = [normaliser(root), await reel($, root)].filter((x): x is string => x !== undefined)
  const garde = await Promise.all(
    brut.split(delim).map(async el => {
      if (!el.trim() || el.includes('\0') || !absolu(el)) return null
      const vrai = await reel($, el)
      return [normaliser(el), vrai].some(c => c !== undefined && labs.some(d => sous(c, d))) ? null : el
    }),
  )
  const reste = garde.filter((x): x is string => x !== null)
  return reste.length ? reste.join(delim) : PATH_REPLI
}

/**
 * L'`init.env` des lancements du mod : le PATH assaini, et `VF_COCKPIT_SCRIPTS_DIR` vidée (P68-D-40). L'hôte peut la pointer vers le lab ;
 * le socle la lirait pour choisir `driver-lock.sh` et exécuterait un script planté. Vide, le socle retombe sur ses propres scripts.
 */
export async function envSain($: EngineInterface, root: string): Promise<Record<string, string>> {
  return { PATH: await pathSain($, root), VF_COCKPIT_SCRIPTS_DIR: '' }
}
