// Vue micro : la mission en cours — les verrous, puis le DAG par vagues (ordre d'exécution) de la mission de la phase
// active de l'arbre courant, avec le libellé du socle ; les refus. Tout vient de `signal@1` (P68-D-02, P68-D-05, P68-D-23).
// Mise en page fluide : une ligne par nœud, qui se replie plutôt que de se tronquer.

import { G, cut, oneLine } from '../ds'
import { couleurEtat } from '../tokens'
import { currentNode, detailVerrou, isDone, isFailed, isRunning, missionCourante, waves } from '../derive'
import { ghost, head, row } from './common'
import type { Ctx } from './common'
import type { SignalNoeud } from '../../types'

export function mission(ctx: Ctx): JSX.Element {
  const { ui, pal, s, l, r, alert, width, blink, compact } = ctx
  const { Box, Text } = ui
  const mis = missionCourante(s)
  // une mission abandonnée ou d'état inconnu n'avance pas : ses nœuds sont grisés, jamais présentés comme vivants (P68-D-05)
  const vivante = mis !== null && mis.etat !== 'abandonnee' && mis.etat !== 'inconnu'
  const nodes = mis?.noeuds ?? []
  const current = vivante ? currentNode(nodes) : null
  const doneCount = nodes.filter(isDone).length

  const glyphOf = (n: SignalNoeud) => {
    if (isDone(n)) return { g: G.done, color: pal['st-done'] }
    if (!vivante) return { g: G.todo, color: pal['st-todo'] }
    if (isFailed(n)) return { g: G.human, color: pal['st-blocked'] }
    if (isRunning(n)) return { g: blink ? G.current : ' ', color: pal['st-active'] }
    // le prochain nœud prêt n'est pas encore un statut : le texte courant et le curseur le désignent
    if (current && n.id === current.id) return { g: G.current, color: pal.text }
    return { g: G.todo, color: pal['st-todo'] }
  }

  const node = (n: SignalNoeud) => {
    const { g, color } = glyphOf(n)
    const isCur = current !== null && n.id === current.id
    return (
      <Text color={color} bold={isCur} wrap="wrap">
        {g} {n.id}
        <Text color={isDone(n) ? pal['text-3'] : pal['text-2']} bold={false}> · {oneLine(n.step)}</Text>
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
          <Text color={k.stale ? pal['st-blocked'] : pal.text} wrap="wrap">
            {G.done} {k.ws || 'dépôt'}
            <Text color={pal['text-2']}> · {detailVerrou(s, k, Math.max(12, width - 20)).join(' · ')}</Text>
            {k.stale ? <Text color={pal['st-blocked']}> · périmé</Text> : null}
          </Text>
        ))
      ) : (
        row(ui, pal, 'verrou', ghost(ui, pal, s?.verrous.etat === 'absente' ? 'driver-lock.sh introuvable' : 'libre'))
      )}

      {/* le DAG par vagues */}
      {mis ? (
        <Box flexDirection="column" marginTop={compact ? 0 : 1}>
          <Text color={couleurEtat(mis.etat, pal)} wrap="wrap">
            {`mission ${doneCount}/${nodes.length} · ${oneLine(mis.nom)} · ${oneLine(mis.libelle)}`}
          </Text>
          {folded.length > 0 ? (
            <Text color={pal['text-3']}>
              {G.done} v1{folded.length > 1 ? `–v${folded.length}` : ''} · {folded.flat().length} faits
            </Text>
          ) : null}
          {shown.map((wave, i) => {
            const index = (compact ? Math.max(0, firstOpen) : 0) + i
            const color = wave.every(isDone) || !vivante ? pal['text-3'] : wave.some(isRunning) ? pal['st-active'] : pal['text-2']
            return (
              <Box flexDirection="column">
                <Text color={color}>
                  v{index + 1} <Text color={pal['text-4']}>{G.rail}</Text>
                </Text>
                <Box flexDirection="column" paddingLeft={1}>
                  {wave.map(node)}
                </Box>
              </Box>
            )
          })}
          {compact && allWaves.length > Math.max(0, firstOpen) + 3 ? (
            <Text color={pal['text-3']}>{G.todo} {allWaves.length - Math.max(0, firstOpen) - 3} vague(s) à venir</Text>
          ) : null}
        </Box>
      ) : (
        row(ui, pal, 'mission', ghost(ui, pal, 'aucune mission pour la phase active'))
      )}

      {/* les refus et la boucle */}
      {!compact || r.length || alert ? head(ui, pal, 'gardes') : null}
      {!compact || r.length ? row(ui, pal, 'refus', <Text color={r.length ? pal.text : pal['text-3']}>{r.length || 'aucun'}</Text>) : null}
      {r.slice(compact ? -2 : -4).map(x => (
        <Box paddingLeft={2}>
          <Text color={x.at >= l.turnStartedAt ? pal['st-active'] : pal['text-2']} wrap="wrap">
            {x.tool}
            <Text color={pal['text-3']}> · {cut(oneLine(x.reason), compact ? width : width * 3)}</Text>
          </Text>
        </Box>
      ))}
      {!compact || alert ? row(ui, pal, 'boucle', <Text color={alert ? pal['st-active'] : pal['text-3']}>{alert ?? 'rien de répété'}</Text>) : null}
    </Box>
  )
}
