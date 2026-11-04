// Vue micro : la mission en cours — le verrou, le DAG par vagues (ordre
// d'exécution), les agents du registre sous le nœud qu'ils servent, les refus.
// Mise en page fluide : une ligne par nœud, qui se replie plutôt que de se tronquer.

import { C, G, age, cut, oneLine } from '../ds'
import { currentNode, isDone, isFailed, isRunning, waves } from '../derive'
import { ghost, head, row } from './common'
import type { Ctx } from './common'
import type { DagNode, RegistryAgent } from '../../types'

export function mission(ctx: Ctx): JSX.Element {
  const { ui, d, l, r, alert, width, blink, compact } = ctx
  const { Box, Text } = ui
  const nodes = d?.nodes ?? []
  const current = currentNode(nodes)
  const doneCount = nodes.filter(isDone).length
  const byNode = new Map<string, RegistryAgent[]>()
  for (const a of d?.registry ?? []) byNode.set(a.node, [...(byNode.get(a.node) ?? []), a])

  const glyphOf = (n: DagNode) => {
    if (isDone(n)) return { g: G.done, color: C.fg2 }
    if (isFailed(n)) return { g: G.human, color: C.human }
    if (isRunning(n)) return { g: blink ? G.current : ' ', color: C.signal }
    if (current && n.id === current.id) return { g: G.current, color: C.signal }
    return { g: G.todo, color: C.fg3 }
  }

  const node = (n: DagNode) => {
    const { g, color } = glyphOf(n)
    const agents = byNode.get(n.id) ?? []
    const isCur = current !== null && n.id === current.id
    return (
      <Box flexDirection="column">
        <Text color={color} bold={isCur} wrap="wrap">
          {g} {n.id}
          <Text color={isDone(n) ? C.fg3 : C.fg2} bold={false}> · {oneLine(n.step)}</Text>
        </Text>
        {agents.map(a => (
          <Box paddingLeft={2}>
            <Text color={C.signal} wrap="wrap">
              {G.branch} {a.role}
              <Text color={C.fg2}> · {age(a.ageSeconds)} · p{a.depth}</Text>
            </Text>
          </Box>
        ))}
      </Box>
    )
  }

  // En compact, les vagues entièrement faites se replient en une ligne.
  const allWaves = waves(nodes)
  const firstOpen = allWaves.findIndex(w => !w.every(isDone))
  const folded = compact && firstOpen > 0 ? allWaves.slice(0, firstOpen) : []
  const shown = compact ? allWaves.slice(Math.max(0, firstOpen), Math.max(0, firstOpen) + 3) : allWaves

  return (
    <Box flexDirection="column">
      {/* les verrous */}
      {d?.locks.length ? (
        d.locks.map(k => (
          <Text color={k.isStale ? C.human : C.fg} wrap="wrap">
            {G.done} {k.ws || 'dépôt'}
            <Text color={C.fg2}> · {cut(k.owner, Math.max(12, width - 20))} · {k.step} · {age(k.ageSeconds)}</Text>
            {k.isStale ? <Text color={C.human}> · périmé</Text> : null}
            {k.children > 0 ? <Text color={C.fg2}> · {k.children} enfant{k.children > 1 ? 's' : ''}</Text> : null}
          </Text>
        ))
      ) : (
        row(ui, 'verrou', ghost(ui, d?.script ? 'libre' : 'driver-lock.sh introuvable'))
      )}

      {/* le DAG par vagues */}
      {d?.dagName ? (
        <Box flexDirection="column" marginTop={compact ? 0 : 1}>
          <Text color={C.fg2} wrap="wrap">
            mission {doneCount}/{nodes.length}
            <Text color={C.fg3}> · {oneLine(d.dagName)}</Text>
          </Text>
          {folded.length > 0 ? (
            <Text color={C.fg3}>
              {G.done} v1{folded.length > 1 ? `–v${folded.length}` : ''} · {folded.flat().length} faits
            </Text>
          ) : null}
          {shown.map((wave, i) => {
            const index = (compact ? Math.max(0, firstOpen) : 0) + i
            const color = wave.every(isDone) ? C.fg3 : wave.some(isRunning) ? C.signal : C.fg2
            return (
              <Box flexDirection="column">
                <Text color={color}>
                  v{index + 1} <Text color={C.line}>{G.rail}</Text>
                </Text>
                <Box flexDirection="column" paddingLeft={1}>
                  {wave.map(node)}
                </Box>
              </Box>
            )
          })}
          {compact && allWaves.length > Math.max(0, firstOpen) + 3 ? (
            <Text color={C.fg3}>{G.todo} {allWaves.length - Math.max(0, firstOpen) - 3} vague(s) à venir</Text>
          ) : null}
          {d.registry.filter(a => !nodes.some(n => n.id === a.node)).map(a => (
            <Text color={C.signal} wrap="wrap">
              {G.branch} {a.role}
              <Text color={C.fg2}> · hors DAG · {age(a.ageSeconds)}</Text>
            </Text>
          ))}
        </Box>
      ) : (
        row(ui, 'mission', ghost(ui, 'aucun plan de bataille sur le disque'))
      )}

      {/* les refus et la boucle */}
      {!compact || r.length || alert ? head(ui, 'gardes') : null}
      {!compact || r.length ? row(ui, 'refus', <Text color={r.length ? C.fg : C.fg3}>{r.length || 'aucun'}</Text>) : null}
      {r.slice(compact ? -2 : -4).map(x => (
        <Box paddingLeft={2}>
          <Text color={x.at >= l.turnStartedAt ? C.human : C.fg2} wrap="wrap">
            {x.tool}
            <Text color={C.fg3}> · {cut(oneLine(x.reason), compact ? width : width * 3)}</Text>
          </Text>
        </Box>
      ))}
      {!compact || alert ? row(ui, 'boucle', <Text color={alert ? C.human : C.fg3}>{alert ?? 'rien de répété'}</Text>) : null}
      {!compact && d?.stoppedAt ? (
        <Text color={C.fg3} wrap="wrap">
          arrêt · {oneLine(d.stoppedAt)}
        </Text>
      ) : null}
    </Box>
  )
}
