// Ce que chaque vue reçoit, et les quelques dessins qu'elles partagent.

import { C } from '../ds'
import type { UI } from '../ds'
import type { AgentStat, Disk, Loop, Macro, Refusal, RosterAgent, Usage } from '../../types'

/** Ce qu'une vue lit. L'engine (`$`) voyage à part : il n'entre dans aucun objet. */
export type Ctx = {
  ui: UI
  width: number
  /** Pane posée au-dessus du prompt (terminal hors plein écran) : on montre moins. */
  compact: boolean
  now: number
  blink: boolean
  d: Disk | null
  m: Macro | null
  l: Loop
  roster: RosterAgent[]
  stats: Record<string, AgentStat>
  r: Refusal[]
  alert: string | null
  u: Usage | null
}

export const LABEL = 9

/** Une ligne « étiquette · contenu », l'étiquette en fantôme sur 9 colonnes. */
export function row(ui: UI, label: string, content: JSX.Element): JSX.Element {
  const { Box, Text } = ui
  return (
    <Box>
      <Box width={LABEL}>
        <Text color={C.fg3}>{label}</Text>
      </Box>
      <Box flexGrow={1}>{content}</Box>
    </Box>
  )
}

/** Un titre de section : un mot en fg2, rien d'autre. */
export function head(ui: UI, label: string): JSX.Element {
  const { Box, Text } = ui
  return (
    <Box marginTop={1}>
      <Text color={C.fg2}>{label}</Text>
    </Box>
  )
}

export function ghost(ui: UI, text: string): JSX.Element {
  const { Text } = ui
  return <Text color={C.fg3}>{text}</Text>
}
