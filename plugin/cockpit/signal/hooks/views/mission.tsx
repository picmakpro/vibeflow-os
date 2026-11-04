// Vue micro : la mission en cours — les verrous, puis le DAG par vagues (ordre d'exécution) de la mission de la phase
// active de l'arbre courant, avec le libellé du socle ; les refus. Tout vient de `signal@1` (P68-D-02, P68-D-05, P68-D-23).
// Mise en page fluide : une ligne par nœud, qui se replie plutôt que de se tronquer.

import { C, G, age, cut, oneLine } from '../ds'
import { currentNode, isDone, isFailed, isRunning, waves } from '../derive'
import { ghost, head, row } from './common'
import type { Ctx } from './common'
import type { Signal, SignalMission, SignalNoeud } from '../../types'

/** La mission de la phase active de l'arbre courant (provisoire : déplacée dans `derive.ts` par la tâche suivante). */
function missionDe(s: Signal | null): SignalMission | null {
  const key = s?.arbres.find(a => a.courant)?.phaseActive?.key
  const nom = key ? s!.phases.find(p => p.key === key)?.avancement.mission?.nom : undefined
  return nom ? (s!.missions.find(m => m.nom === nom) ?? null) : null
}

export function mission(ctx: Ctx): JSX.Element {
  const { ui, s, l, r, alert, width, blink, compact } = ctx
  const { Box, Text } = ui
  const mis = missionDe(s)
  // une mission abandonnée ou d'état inconnu n'avance pas : ses nœuds sont grisés, jamais présentés comme vivants (P68-D-05)
  const vivante = mis !== null && mis.etat !== 'abandonnee' && mis.etat !== 'inconnu'
  const nodes = mis?.noeuds ?? []
  const current = vivante ? currentNode(nodes) : null
  const doneCount = nodes.filter(isDone).length

  const glyphOf = (n: SignalNoeud) => {
    if (isDone(n)) return { g: G.done, color: C.fg2 }
    if (!vivante) return { g: G.todo, color: C.fg3 }
    if (isFailed(n)) return { g: G.human, color: C.human }
    if (isRunning(n)) return { g: blink ? G.current : ' ', color: C.signal }
    if (current && n.id === current.id) return { g: G.current, color: C.signal }
    return { g: G.todo, color: C.fg3 }
  }

  const node = (n: SignalNoeud) => {
    const { g, color } = glyphOf(n)
    const isCur = current !== null && n.id === current.id
    return (
      <Text color={color} bold={isCur} wrap="wrap">
        {g} {n.id}
        <Text color={isDone(n) ? C.fg3 : C.fg2} bold={false}> · {oneLine(n.step)}</Text>
      </Text>
    )
  }

  // En compact, les vagues entièrement faites se replient en une ligne.
  const allWaves = waves(nodes)
  const firstOpen = allWaves.findIndex(w => !w.every(isDone))
  const folded = compact && firstOpen > 0 ? allWaves.slice(0, firstOpen) : []
  const shown = compact ? allWaves.slice(Math.max(0, firstOpen), Math.max(0, firstOpen) + 3) : allWaves
  const verrous = s?.verrous.liste ?? []

  return (
    <Box flexDirection="column">
      {/* les verrous */}
      {verrous.length ? (
        verrous.map(k => (
          <Text color={k.stale ? C.human : C.fg} wrap="wrap">
            {G.done} {k.ws || 'dépôt'}
            <Text color={C.fg2}> · {cut(k.owner ?? '?', Math.max(12, width - 20))} · {k.scope}{k.ageS != null ? ` · ${age(k.ageS)}` : ''}</Text>
            {k.stale ? <Text color={C.human}> · périmé</Text> : null}
          </Text>
        ))
      ) : (
        row(ui, 'verrou', ghost(ui, s?.verrous.etat === 'absente' ? 'driver-lock.sh introuvable' : 'libre'))
      )}

      {/* le DAG par vagues */}
      {mis ? (
        <Box flexDirection="column" marginTop={compact ? 0 : 1}>
          <Text color={vivante ? C.fg2 : C.fg3} wrap="wrap">
            {`mission ${doneCount}/${nodes.length} · ${oneLine(mis.nom)} · ${oneLine(mis.libelle)}`}
          </Text>
          {folded.length > 0 ? (
            <Text color={C.fg3}>
              {G.done} v1{folded.length > 1 ? `–v${folded.length}` : ''} · {folded.flat().length} faits
            </Text>
          ) : null}
          {shown.map((wave, i) => {
            const index = (compact ? Math.max(0, firstOpen) : 0) + i
            const color = wave.every(isDone) || !vivante ? C.fg3 : wave.some(isRunning) ? C.signal : C.fg2
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
        </Box>
      ) : (
        row(ui, 'mission', ghost(ui, 'aucune mission pour la phase active'))
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
    </Box>
  )
}
