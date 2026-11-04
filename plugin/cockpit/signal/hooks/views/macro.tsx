// Vue macro : le projet, le jalon en cours et ses phases, la phase courante et
// ses plans, les jalons clos, le backlog. Tout vient du disque.

import { C, G, oneLine } from '../ds'
import { ghost, head } from './common'
import type { Ctx } from './common'

export function macro(ctx: Ctx): JSX.Element {
  const { ui, d, m, compact } = ctx
  const { Box, Text } = ui
  const current = m?.milestones.find(ms => ms.name === d?.milestone) ?? m?.milestones[m.milestones.length - 1] ?? null
  const phaseNow = d?.phase ?? null

  // En compact : la phase courante et ses deux voisines seulement.
  const phases = current?.phases ?? []
  const at = phases.findIndex(p => p.number === phaseNow)
  const shown = compact && phases.length > 5 ? phases.slice(Math.max(0, at - 2), Math.max(0, at - 2) + 5) : phases

  return (
    <Box flexDirection="column">
      {m?.project && !compact ? (
        <Text color={C.fg} wrap="wrap">
          {oneLine(m.project)}
        </Text>
      ) : null}
      {current ? (
        <Text color={C.fg} wrap="wrap">
          {G.done} {current.name}
          <Text color={C.fg2}> · {current.phases.filter(p => p.isDone).length}/{current.phases.length} phases</Text>
        </Text>
      ) : (
        ghost(ui, d?.milestone ?? 'aucun jalon ouvert')
      )}
      {shown.map(p => {
        const isNow = phaseNow !== null && p.number === phaseNow
        const color = isNow ? C.signal : p.isDone ? C.fg2 : C.fg3
        const glyph = p.isDone ? G.done : isNow ? G.current : G.todo
        return (
          <Box paddingLeft={2}>
            <Text color={color} bold={isNow} wrap="wrap">
              {glyph} {p.number} {oneLine(p.name)}
              {p.plansTotal > 0 ? <Text color={C.fg3} bold={false}> · {p.plansDone}/{p.plansTotal}</Text> : null}
            </Text>
          </Box>
        )
      })}

      {compact ? null : head(ui, 'phase')}
      {compact ? null : (
        <Text color={C.fg} wrap="wrap">
          {phaseNow ?? '?'} {oneLine(d?.phaseName ?? '—')}
          <Text color={C.fg2}> · {d?.status ?? '?'}</Text>
          {d?.plansTotal != null ? <Text color={C.fg2}> · plans {d.plansDone ?? 0}/{d.plansTotal}</Text> : null}
          {d?.ws ? <Text color={C.fg3}> · {d.ws}</Text> : null}
        </Text>
      )}

      {!compact && m && m.milestones.length > 1 ? head(ui, 'jalons ouverts') : null}
      {compact
        ? null
        : m?.milestones
            .filter(ms => ms !== current)
            .map(ms => (
              <Box paddingLeft={2}>
                <Text color={C.fg3} wrap="wrap">
                  {G.todo} {ms.name} · {ms.phases.filter(p => p.isDone).length}/{ms.phases.length}
                </Text>
              </Box>
            ))}

      {!compact && m?.closed.length ? head(ui, 'jalons clos') : null}
      {!compact && m?.closed.length ? (
        <Box paddingLeft={2}>
          <Text color={C.fg3} wrap="wrap">
            {G.done} {m.closed.join(' · ')}
          </Text>
        </Box>
      ) : null}

      {compact ? null : head(ui, 'backlog')}
      <Text color={C.fg2} wrap="wrap">
        {compact ? 'backlog ' : ''}
        {m ? m.backlogCount : '—'}
        {m ? ' entrées' : ''}
        {m?.backlogDeferred ? <Text color={C.fg3}> · {m.backlogDeferred} différées</Text> : null}
      </Text>
      {compact
        ? null
        : (m?.backlogHeads ?? []).map(h => (
            <Box paddingLeft={2}>
              <Text color={C.fg3} wrap="wrap">
                {G.todo} {oneLine(h)}
              </Text>
            </Box>
          ))}
    </Box>
  )
}
