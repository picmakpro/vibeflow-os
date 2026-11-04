// La pane : l'en-tête (le disque), le fil de la boucle, les onglets, la vue,
// puis « toi » — la prochaine action humaine et ses boutons — et le contexte.
// Dockée (plein écran, ≥ 110 colonnes) elle montre tout ; posée au-dessus du
// prompt (inline) elle se fait compacte : une ligne d'en-tête, la vue, « toi ».

import { atom, read, update } from 'claude-code'
import type { EngineInterface, RenderInput } from 'claude-code'

import { C, G, STAGES, STAGE_LABEL, VIEWS, VIEW_LABEL } from './ds'
import { PHRASE_ANCIEN_MOD } from './ancien-mod'
import { attention } from './derive'
import { enTete, erreurSocle, resumeCompact } from './en-tete'
import { refreshAll } from './refresh'
import type { Ctx } from './views/common'
import { equipe } from './views/equipe'
import { macro as macroView } from './views/macro'
import { mission } from './views/mission'

const disk = atom({ plugin: 'vibeflow', key: 'disk' } as const, null)
const macro = atom({ plugin: 'vibeflow', key: 'macro' } as const, null)
const loop = atom({ plugin: 'vibeflow', key: 'loop' } as const, { stage: null, isWorking: false, turnStartedAt: 0, tools: 0, lastTurn: null })
const roster = atom({ plugin: 'vibeflow', key: 'roster' } as const, [])
const stats = atom({ plugin: 'vibeflow', key: 'stats' } as const, {})
const refusals = atom({ plugin: 'vibeflow', key: 'refusals' } as const, [])
const loopAlert = atom({ plugin: 'vibeflow', key: 'loopAlert' } as const, null)
const usage = atom({ plugin: 'vibeflow', key: 'usage' } as const, null)
const view = atom({ plugin: 'vibeflow', key: 'view' } as const, 'mission')
const ancienMod = atom({ plugin: 'vibeflow', key: 'ancienMod' } as const, false)
const signal = atom({ plugin: 'vibeflow', key: 'signal' } as const, null)

type PaneInput = Extract<RenderInput, { component: 'Pane' }>

export async function pane($: EngineInterface, e: PaneInput, blink: boolean, home: string | undefined): Promise<JSX.Element> {
  const refresh = () => refreshAll($, home)
  const ui = $.ui.resolve(e)
  const { Box, Button, Text } = ui
  const [d, m, l, agents, agentStats, r, alert, u, current, ancien, sig] = await Promise.all([
    read($, disk), read($, macro), read($, loop), read($, roster), read($, stats),
    read($, refusals), read($, loopAlert), read($, usage), read($, view), read($, ancienMod), read($, signal),
  ])
  const erreur = await erreurSocle($, ui)
  const now = await $.clock.now()
  const width = Math.max(24, e.props.bodyColumns - 1)
  const compact = e.props.placement === 'inline' || width < 48
  const ctx: Ctx = { ui, width, compact, now, blink, s: sig, d, m, l, roster: agents, stats: agentStats, r, alert, u }
  const action = attention(d, l, r, alert, u)
  const currentIndex = l.stage ? STAGES.indexOf(l.stage) : -1
  const cursor = l.isWorking ? (blink ? G.current : ' ') : G.done
  const stale = d?.locks.find(k => k.isStale) ?? null

  const tabs = (
    <Box gap={1} flexWrap="wrap">
      {VIEWS.map((v, i) =>
        v === current ? (
          <Text color={C.signal} bold>
            {G.done} {VIEW_LABEL[v]}
          </Text>
        ) : (
          <Button key={`onglet:${v}`} hotkey={String(i + 1)} plain dimColor onPress={() => void update($, view, () => v)}>
            {VIEW_LABEL[v]}
          </Button>
        ),
      )}
    </Box>
  )

  const body = current === 'equipe' ? equipe($, ctx) : current === 'macro' ? macroView(ctx) : mission(ctx)

  const noteAncienMod = ancien ? (
    <Text color={C.human} wrap="wrap">
      {G.human} {PHRASE_ANCIEN_MOD}
    </Text>
  ) : null

  const buttons = (
    <Box gap={1} flexWrap="wrap">
      {stale && d?.script ? (
        <Button
          key="elaguer"
          hotkey="e"
          variant="primary"
          onPress={async () => {
            const argv = ['bash', d.script as string, 'recover', ...(stale.ws ? [`--ws=${stale.ws}`] : [])]
            const ran = await $.process.run(argv, { cwd: await $.session.root(), timeoutMs: 15000 }).catch(() => undefined)
            $.ui.toast(ran ? `recover · exit ${ran.exitCode} · ${ran.stdout.trim().slice(0, 120)}` : 'recover : driver-lock.sh ne démarre pas')
            await refresh()
          }}
        >
          élaguer le verrou périmé
        </Button>
      ) : null}
      {stale ? (
        <Button
          key="takeover"
          hotkey="t"
          plain
          dimColor
          onPress={press =>
            void $.ui
              .copy({ text: `bash ${d?.script ?? 'driver-lock.sh'} takeover --owner=<id>${stale.ws ? ` --ws=${stale.ws}` : ''}`, surface: press.surface })
              .then(() => $.ui.toast('commande takeover copiée'))
          }
        >
          copier takeover
        </Button>
      ) : null}
      {u?.percent != null && u.percent >= 85 && !l.isWorking ? (
        <Button
          key="compacter"
          hotkey="c"
          plain
          dimColor
          onPress={() => void $.session.compact().then(() => $.ui.toast('compaction lancée')).catch(() => $.ui.toast('compaction refusée (un tour tourne ?)'))}
        >
          compacter
        </Button>
      ) : null}
      <Button key="rafraichir" hotkey="r" plain dimColor onPress={() => void refresh()}>
        rafraîchir
      </Button>
    </Box>
  )

  if (compact) {
    return (
      <Box flexDirection="column">
        <Text color={C.fg} wrap="wrap">
          <Text color={C.signal}>{cursor} </Text>
          <Text bold>{sig?.layout.actif ?? 'lab'}</Text>
          <Text color={C.fg2}> · {resumeCompact(sig)} · {l.stage ? STAGE_LABEL[l.stage] : 'en attente'}</Text>
          {u?.percent != null ? <Text color={u.percent >= 85 ? C.human : C.fg3}> · {u.percent} %</Text> : null}
        </Text>
        {erreur}
        {tabs}
        {body}
        {action ? (
          <Text color={C.human} wrap="wrap">
            {G.human} {action}
          </Text>
        ) : null}
        {noteAncienMod}
        {buttons}
      </Box>
    )
  }

  return (
    <Box flexDirection="column">
      {await enTete($, ui, cursor)}
      {erreur}

      {/* le fil */}
      <Box marginTop={1} flexWrap="wrap">
        {STAGES.map((stage, i) => (
          <Box>
            {i > 0 ? <Text color={C.line}>{G.rail}</Text> : null}
            <Text color={i === currentIndex ? C.signal : i < currentIndex ? C.fg2 : C.fg3} bold={i === currentIndex}>
              {STAGE_LABEL[stage]}
            </Text>
          </Box>
        ))}
      </Box>

      <Box marginTop={1}>{tabs}</Box>
      <Box marginTop={1}>{body}</Box>

      {/* toi */}
      <Box marginTop={1} flexDirection="column">
        <Text color={action ? C.human : C.fg3} wrap="wrap">
          {G.human} toi · {action ?? 'rien à valider'}
        </Text>
        <Box paddingLeft={2}>{buttons}</Box>
      </Box>

      {/* contexte, coût, limites */}
      <Box marginTop={1}>
        <Text color={C.fg3} wrap="wrap">
          contexte{' '}
          <Text color={u?.percent != null && u.percent >= 85 ? C.human : C.fg2}>{u?.percent != null ? `${u.percent} %` : '—'}</Text>
          {' · '}
          <Text color={C.fg2}>{u?.usd != null ? `${u.usd.toFixed(2)} $` : '—'}</Text>
          {(u?.limits ?? []).map(lim => (
            <Text color={lim.percent >= 80 ? C.human : C.fg3}>
              {' · '}
              {lim.kind === 'five_hour' ? '5 h' : lim.kind === 'seven_day' ? '7 j' : lim.kind} {Math.round(lim.percent)} %
            </Text>
          ))}
        </Text>
      </Box>
      {noteAncienMod}
      {d?.error ? (
        <Text color={C.fg3} wrap="wrap">
          disque · {d.error}
        </Text>
      ) : null}
    </Box>
  )
}
