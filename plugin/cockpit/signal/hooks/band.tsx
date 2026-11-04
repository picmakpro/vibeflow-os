// Le bandeau au-dessus du prompt : une ligne, la marque en st-active, seulement quand c'est à toi.

import { atom, read, update } from 'claude-code'
import type { EngineInterface, RenderInput } from 'claude-code'

import { G } from './ds'
import { palette } from './tokens'
import { attention } from './derive'

export const PANE = 'vf-signal'

const signal = atom({ plugin: 'vibeflow', key: 'signal' } as const, null)
const loop = atom({ plugin: 'vibeflow', key: 'loop' } as const, { stage: null, isWorking: false, turnStartedAt: 0, tools: 0, lastTurn: null })
const refusals = atom({ plugin: 'vibeflow', key: 'refusals' } as const, [])
const loopAlert = atom({ plugin: 'vibeflow', key: 'loopAlert' } as const, null)
const usage = atom({ plugin: 'vibeflow', key: 'usage' } as const, null)
const theme = atom({ plugin: 'vibeflow', key: 'theme' } as const, 'sombre')
const bandHiddenFor = atom({ plugin: 'vibeflow', key: 'bandHiddenFor' } as const, null)

export async function band(
  $: EngineInterface,
  e: Extract<RenderInput, { component: 'AbovePrompt' }>,
): Promise<JSX.Element | null> {
  const [sig, l, r, alert, u, hiddenFor, th] = await Promise.all([
    read($, signal), read($, loop), read($, refusals), read($, loopAlert), read($, usage), read($, bandHiddenFor), read($, theme),
  ])
  const p = palette(th)
  const action = attention(sig, l, r, alert, u)
  if (e.props.hasSurvey || action === null || hiddenFor === action) return null
  const { Box, Button, Text } = $.ui.resolve(e)
  return (
    <Box>
      <Text color={p['st-active']}>{G.human} </Text>
      <Text color={p.text}>{action} </Text>
      <Button key="voir" plain dimColor onPress={() => void $.ui.open({ id: PANE, title: 'vf-signal', focus: true })}>
        voir
      </Button>
      <Text color={p['text-3']}> · </Text>
      <Button key="masquer" plain dimColor onPress={() => void update($, bandHiddenFor, () => action)}>
        masquer
      </Button>
    </Box>
  )
}
