// Ce que chaque vue reçoit, et les quelques dessins qu'elles partagent.

import type { UI } from '../ds'
import type { Palette } from '../tokens'
import type { AgentStat, Loop, Refusal, RosterAgent, Signal, Usage } from '../../types'

/** Ce qu'une vue lit. L'engine (`$`) voyage à part : il n'entre dans aucun objet. */
export type Ctx = {
  ui: UI
  /** Les couleurs du thème de la personne (tokens.ts). */
  pal: Palette
  width: number
  /** Pane posée au-dessus du prompt (terminal hors plein écran) : on montre moins. */
  compact: boolean
  now: number
  blink: boolean
  /** Ce que l'émetteur du socle a rendu ; null avant la première lecture ou après un échec. */
  s: Signal | null
  l: Loop
  roster: RosterAgent[]
  stats: Record<string, AgentStat>
  r: Refusal[]
  alert: string | null
  u: Usage | null
}

export const LABEL = 9

/** Une ligne « étiquette · contenu », l'étiquette en fantôme sur 9 colonnes. */
export function row(ui: UI, pal: Palette, label: string, content: JSX.Element): JSX.Element {
  const { Box, Text } = ui
  return (
    <Box>
      <Box width={LABEL}>
        <Text color={pal['text-3']}>{label}</Text>
      </Box>
      <Box flexGrow={1}>{content}</Box>
    </Box>
  )
}

/** Un titre de section : un mot en text-2, rien d'autre. */
export function head(ui: UI, pal: Palette, label: string): JSX.Element {
  const { Box, Text } = ui
  return (
    <Box marginTop={1}>
      <Text color={pal['text-2']}>{label}</Text>
    </Box>
  )
}

export function ghost(ui: UI, pal: Palette, text: string): JSX.Element {
  const { Text } = ui
  return <Text color={pal['text-3']}>{text}</Text>
}
