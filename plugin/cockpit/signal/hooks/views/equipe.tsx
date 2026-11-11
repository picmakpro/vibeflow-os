// Vue équipe : l'arborescence de TOUTE l'équipe au travail telle que le socle la voit (`signal@1.equipe`, who@2 :
// toutes sessions, tous worktrees, 24 h) — qui tourne, sous qui, sur quoi, depuis quand (P68-D-03).
// la liste de la session ne sert plus l'arbre (P68-D-17) : elle ne dit que quels agents sont ceux de CETTE session, les seuls
// à recevoir les deux gestes humains — voir la transcription, demander l'arrêt. Aucun rapprochement par description ni par rôle.

import type { EngineInterface } from 'claude-code'

import { G, age, libellePortee, libelleType, nOutils, oneLine } from '../ds'
import { ghost, head } from './common'
import type { Ctx } from './common'
import type { SignalWorker } from '../../types'

const STOP_TEXT =
  "vf-signal (geste humain) : arrête-toi proprement. Termine l'action en cours, écris ton rapport et rends la main sans entamer d'autre étape."

type Etat = 'actif' | 'en-attente' | 'au-repos' | 'attend' | 'termine'

// Statuts de `$.agent.list()` qui disent « fini » ; tout autre statut (running, …) est un agent vivant (P68-D-35, R2).
const STATUTS_FINIS = new Set(['completed', 'failed', 'killed'])

// Les terminés se replient derrière un compteur (P68-D-35, R3). Le choix tient au module, la pane se redessine par `invalidate`.
let deplie = false

/** L'état écrit par who@2 ; à défaut (verrou, nœud, registre) : périmé = en attente, sinon actif. */
const etatDe = (w: SignalWorker): Etat => (w.etat === 'actif' || w.etat === 'en-attente' || w.etat === 'au-repos' || w.etat === 'attend' || w.etat === 'termine' ? w.etat : w.stale ? 'en-attente' : 'actif')

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
  const { ui, pal, roster, s, l, blink, compact } = ctx
  const { Box, Button, Text } = ui
  const workers = s?.equipe?.workers ?? []
  const session = new Map(roster.map(a => [a.id, a]))
  // vivant pour la session : présent dans `$.agent.list()` et non fini, quel que soit l'état que who@2 lui donne
  const vivant = (w: SignalWorker) => {
    const a = session.get(w.id)
    return a !== undefined && !STATUTS_FINIS.has(a.status)
  }
  const replies = (w: SignalWorker) => etatDe(w) === 'termine' && !vivant(w)
  const finis = workers.filter(w => etatDe(w) === 'termine').length
  const live = workers.length - finis
  const nReplies = workers.filter(replies).length
  const rowsVifs = arbre(workers.filter(w => !replies(w)))
  const rowsFinis = !compact && deplie ? arbre(workers.filter(replies)) : []
  const rows = [...rowsVifs, ...rowsFinis]

  const ligne = ({ w, depth }: { w: SignalWorker; depth: number }) => {
    const etat = etatDe(w)
    const termine = etat === 'termine'
    const color = termine ? pal['st-todo'] : w.orphan || etat === 'actif' ? pal['st-active'] : pal['text-2']
    const glyph = termine ? G.done : w.orphan ? G.human : etat === 'actif' ? (blink ? G.current : ' ') : G.todo
    const mien = session.get(w.id)
    return (
      <Box flexDirection="column" paddingLeft={depth * 2}>
        <Text color={color} bold={etat === 'actif'} wrap="wrap">
          {depth > 0 ? `${G.branch} ` : ''}
          {glyph} {libelleType(w.role || w.kind)}
          <Text color={termine ? pal['text-3'] : pal['text-2']} bold={false}> · {oneLine(w.task ?? '')}</Text>
        </Text>
        {compact ? null : (
          <Box paddingLeft={depth > 0 ? 4 : 2}>
            <Text color={pal['text-3']} wrap="wrap">
              {w.orphan ? 'orphelin (registre)' : termine ? 'terminé' : etat === 'attend' ? 'vous attend' : etat === 'au-repos' ? 'au repos' : etat === 'en-attente' ? 'en attente' : 'actif'}
              {` · ${libellePortee(w.tree)}`}
              {w.branch ? ` · ${w.branch}` : ''}
              {w.ageS != null ? ` · ${age(w.ageS)}` : ''}
            </Text>
          </Box>
        )}
        {mien && !STATUTS_FINIS.has(mien.status) && !w.orphan ? (
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
  }

  return (
    <Box flexDirection="column">
      <Text color={l.isWorking ? pal['st-active'] : pal['text-2']} wrap="wrap">
        {l.isWorking
          ? `${blink ? G.current : ' '} l'équipe travaille · ${nOutils(l.tools)}`
          : l.lastTurn
            ? `${G.done} dernier tour · ${l.lastTurn.seconds} s · ${nOutils(l.lastTurn.tools)}`
            : `${G.done} prête`}
        <Text color={pal['text-3']}>
          {' · '}
          {workers.length ? `${live} en cours, ${finis} fini${finis > 1 ? 's' : ''}` : 'aucun agent vu'}
        </Text>
      </Text>

      {(rows.length > 0 || nReplies > 0) && !compact ? head(ui, pal, 'arbre') : null}
      {rowsVifs.map(ligne)}
      {!compact && nReplies > 0 ? (
        <Button
          key="finis"
          plain
          dimColor
          onPress={() => {
            deplie = !deplie
            $.ui.invalidate('ui.render')
          }}
        >
          {`${deplie ? '▾' : '▸'} ${nReplies} terminé${nReplies > 1 ? 's' : ''}`}
        </Button>
      ) : null}
      {rowsFinis.map(ligne)}
      {rowsVifs.length === 0 && (compact || nReplies === 0) ? (
        <Box marginTop={compact ? 0 : 1}>{ghost(ui, pal, compact ? 'aucun agent en cours' : 'les agents apparaissent ici dès que le socle en voit')}</Box>
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
