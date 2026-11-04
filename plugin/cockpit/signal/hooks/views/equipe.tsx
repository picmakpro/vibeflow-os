// Vue équipe : l'arborescence de TOUTE l'équipe au travail telle que le socle la voit (`signal@1.equipe`, who@2 :
// toutes sessions, tous worktrees, 24 h) — qui tourne, sous qui, sur quoi, depuis quand (P68-D-03).
// la liste de la session ne sert plus l'arbre (P68-D-17) : elle ne dit que quels agents sont ceux de CETTE session, les seuls
// à recevoir les deux gestes humains — voir la transcription, demander l'arrêt. Aucun rapprochement par description ni par rôle.

import type { EngineInterface } from 'claude-code'

import { C, G, age, oneLine } from '../ds'
import { ghost, head } from './common'
import type { Ctx } from './common'
import type { SignalWorker } from '../../types'

const STOP_TEXT =
  "vf-signal (geste humain) : arrête-toi proprement. Termine l'action en cours, écris ton rapport et rends la main sans entamer d'autre étape."

type Etat = 'actif' | 'en-attente' | 'termine'

/** L'état écrit par who@2 ; à défaut (verrou, nœud, registre) : périmé = en attente, sinon actif. */
const etatDe = (w: SignalWorker): Etat => (w.etat === 'actif' || w.etat === 'en-attente' || w.etat === 'termine' ? w.etat : w.stale ? 'en-attente' : 'actif')

/** Racines : sans parent, ou parent absent de la liste ; un cycle ne fait jamais disparaître un travailleur. */
function arbre(workers: SignalWorker[]): { w: SignalWorker; depth: number }[] {
  const ids = new Set(workers.map(w => w.id))
  const enfants = new Map<string, number[]>()
  const racines: number[] = []
  workers.forEach((w, i) => {
    const p = w.parent && w.parent !== w.id && ids.has(w.parent) ? w.parent : null
    if (p === null) racines.push(i)
    else enfants.set(p, [...(enfants.get(p) ?? []), i])
  })
  const vus = new Set<number>()
  const out: { w: SignalWorker; depth: number }[] = []
  const marche = (i: number, depth: number) => {
    if (vus.has(i)) return
    vus.add(i)
    out.push({ w: workers[i]!, depth })
    for (const c of enfants.get(workers[i]!.id) ?? []) marche(c, depth + 1)
  }
  for (const i of racines) marche(i, 0)
  workers.forEach((_, i) => marche(i, 0))
  return out
}

export function equipe($: EngineInterface, ctx: Ctx): JSX.Element {
  const { ui, roster, s, l, blink, compact } = ctx
  const { Box, Button, Text } = ui
  const workers = s?.equipe?.workers ?? []
  const session = new Map(roster.map(a => [a.id, a]))
  const all = arbre(workers)
  const rows = compact ? all.filter(({ w }) => etatDe(w) !== 'termine') : all
  const finis = workers.filter(w => etatDe(w) === 'termine').length
  const live = workers.length - finis

  return (
    <Box flexDirection="column">
      <Text color={l.isWorking ? C.signal : C.fg2} wrap="wrap">
        {l.isWorking
          ? `${blink ? G.current : ' '} l'équipe travaille · ${l.tools} outil${l.tools > 1 ? 's' : ''}`
          : l.lastTurn
            ? `${G.done} dernier tour · ${l.lastTurn.seconds} s · ${l.lastTurn.tools} outils`
            : `${G.done} prête`}
        <Text color={C.fg3}>
          {' · '}
          {workers.length ? `${live} en cours, ${finis} fini${finis > 1 ? 's' : ''}` : 'aucun agent vu'}
        </Text>
      </Text>

      {rows.length > 0 && !compact ? head(ui, 'arbre') : null}
      {rows.map(({ w, depth }) => {
        const etat = etatDe(w)
        const termine = etat === 'termine'
        const color = termine ? C.fg3 : w.orphan ? C.human : etat === 'actif' ? C.signal : C.fg2
        const glyph = termine ? G.done : w.orphan ? G.human : etat === 'actif' ? (blink ? G.current : ' ') : G.todo
        const mien = session.get(w.id)
        return (
          <Box flexDirection="column" paddingLeft={depth * 2}>
            <Text color={color} bold={etat === 'actif'} wrap="wrap">
              {depth > 0 ? `${G.branch} ` : ''}
              {glyph} {w.role || w.kind}
              <Text color={termine ? C.fg3 : C.fg2} bold={false}> · {oneLine(w.task ?? '')}</Text>
            </Text>
            {compact ? null : (
              <Box paddingLeft={depth > 0 ? 4 : 2}>
                <Text color={C.fg3} wrap="wrap">
                  {w.orphan ? 'orphelin (registre)' : termine ? 'terminé' : etat === 'en-attente' ? 'en attente' : 'actif'}
                  {` · ${w.tree}`}
                  {w.branch ? ` · ${w.branch}` : ''}
                  {w.ageS != null ? ` · ${age(w.ageS)}` : ''}
                </Text>
              </Box>
            )}
            {mien && !termine && !w.orphan ? (
              <Box paddingLeft={depth > 0 ? 4 : 2} gap={1}>
                <Button key={`voir:${w.id}`} plain dimColor onPress={() => void $.ui.view({ agentId: w.id })}>
                  voir
                </Button>
                <Button
                  key={`stop:${w.id}`}
                  plain
                  dimColor
                  onPress={() =>
                    void $.session
                      .send({ to: { agentId: w.id }, text: STOP_TEXT })
                      .then(() => $.ui.toast(`arrêt demandé à ${mien.type}`))
                      .catch(err => $.ui.toast(`arrêt refusé : ${err instanceof Error ? err.message : String(err)}`))
                  }
                >
                  demander l'arrêt
                </Button>
              </Box>
            ) : null}
          </Box>
        )
      })}
      {rows.length === 0 ? (
        <Box marginTop={compact ? 0 : 1}>{ghost(ui, compact ? 'aucun agent en cours' : 'les agents apparaissent ici dès que le socle en voit')}</Box>
      ) : null}
      {compact ? null : (
        <Box marginTop={1}>
          <Button key="retour" plain dimColor onPress={() => void $.ui.view({})}>
            revenir à la conversation principale
          </Button>
        </Box>
      )}
    </Box>
  )
}
