// L'en-tête de la pane (VFSG-05, VFSG-06 ; P68-D-04, P68-D-05) : ce que dit `signal@1`, jamais le STATE (P68-D-17).
// Chaque ligne est un seul `Text` : les libellés viennent du socle, ils ne sont pas recopiés ici.

import { atom, read } from 'claude-code'
import type { EngineInterface } from 'claude-code'

import { C, G, oneLine, type UI } from './ds'
import type { Signal, SignalArbre } from '../types'

const signal = atom({ plugin: 'vibeflow', key: 'signal' } as const, null)
const signalErreur = atom({ plugin: 'vibeflow', key: 'signalErreur' } as const, null)

const courant = (s: Signal): SignalArbre | null => s.arbres.find(a => a.courant) ?? null

/** « phase <n> <nom> (<libellé d'avancement>) » ou « aucune phase en cours » pour un arbre. */
function phaseDe(s: Signal, a: SignalArbre): string {
  const p = a.phaseActive
  if (!p) return 'aucune phase en cours'
  const lib = s.phases.find(x => x.key === p.key)?.libelle
  return `phase ${oneLine(p.n)} ${oneLine(p.nom)}${lib ? ` (${oneLine(lib)})` : ''}`
}

/** La phase active de l'arbre courant, pour la ligne compacte. */
export function resumeCompact(s: Signal | null): string {
  const a = s ? courant(s) : null
  return s && a ? phaseDe(s, a) : 'phase ?'
}

/** La ligne d'erreur du socle, ou rien. */
export async function erreurSocle($: EngineInterface, ui: UI): Promise<JSX.Element | null> {
  const [erreur, s] = await Promise.all([read($, signalErreur), read($, signal)])
  const dit = erreur ?? (s && s.verrous.etat !== 'lue' ? 'verrous illisibles' : null)
  if (!dit) return null
  const { Text } = ui
  return <Text color={C.human} wrap="wrap">{`${G.human} ${dit}`}</Text>
}

/** L'en-tête dockée : l'espace de travail, la phase active de l'arbre courant. */
export async function enTete($: EngineInterface, ui: UI, cursor: string): Promise<JSX.Element> {
  const s = await read($, signal)
  const { Box, Text } = ui
  const a = s ? courant(s) : null
  return (
    <Box flexDirection="column">
      <Text color={C.fg} wrap="wrap">{`${cursor} ${s?.layout.actif ?? 'lab'}`}</Text>
      {s && a ? <Text color={C.fg} wrap="wrap">{phaseDe(s, a)}</Text> : null}
    </Box>
  )
}
