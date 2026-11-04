// Le bandeau au-dessus du prompt : une ligne orange, seulement quand c'est à toi.

import { atom, read, update } from 'claude-code'
import type { EngineInterface, RenderInput } from 'claude-code'

import { C, G } from './ds'
import { attention } from './derive'

export const PANE = 'vf-signal'

const disk = atom({ plugin: 'vibeflow', key: 'disk' } as const, null)
const loop = atom({ plugin: 'vibeflow', key: 'loop' } as const, { stage: null, isWorking: false, turnStartedAt: 0, tools: 0, lastTurn: null })
const refusals = atom({ plugin: 'vibeflow', key: 'refusals' } as const, [])
const loopAlert = atom({ plugin: 'vibeflow', key: 'loopAlert' } as const, null)
const usage = atom({ plugin: 'vibeflow', key: 'usage' } as const, null)
const bandHiddenFor = atom({ plugin: 'vibeflow', key: 'bandHiddenFor' } as const, null)

export async function band(
  $: EngineInterface,
  e: Extract<RenderInput, { component: 'AbovePrompt' }>,
): Promise<JSX.Element | null> {
  const [d, l, r, alert, u, hiddenFor] = await Promise.all([
    read($, disk), read($, loop), read($, refusals), read($, loopAlert), read($, usage), read($, bandHiddenFor),
  ])
  const action = attention(d, l, r, alert, u)
  if (e.props.hasSurvey || action === null || hiddenFor === action) return null
  const { Box, Button, Text } = $.ui.resolve(e)
  return (
    <Box>
      <Text color={C.human}>{G.human} </Text>
      <Text color={C.fg}>{action} </Text>
      <Button key="voir" plain dimColor onPress={() => void $.ui.open({ id: PANE, title: 'vf-signal', focus: true })}>
        voir
      </Button>
      <Text color={C.fg3}> · </Text>
      <Button key="masquer" plain dimColor onPress={() => void update($, bandHiddenFor, () => action)}>
        masquer
      </Button>
    </Box>
  )
}
