// Vue équipe : l'arborescence des agents et sous-agents de la session, en
// direct — qui tourne, sous qui, sur quoi, depuis quand, avec quel outil.
// Deux gestes humains par agent : voir sa transcription, lui demander l'arrêt.

import type { EngineInterface } from 'claude-code'

import { C, G, STAGE_LABEL, oneLine, since } from '../ds'
import { tree } from '../derive'
import { ghost, head } from './common'
import type { Ctx } from './common'

const STOP_TEXT =
  "vf-signal (geste humain) : arrête-toi proprement. Termine l'action en cours, écris ton rapport et rends la main sans entamer d'autre étape."

export function equipe($: EngineInterface, ctx: Ctx): JSX.Element {
  const { ui, roster, stats, l, now, blink, compact } = ctx
  const { Box, Button, Text } = ui
  const all = tree(roster)
  const rows = compact ? all.filter(({ agent }) => agent.status === 'running' || agent.status === 'idle') : all
  const live = roster.filter(a => a.status === 'running').length

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
          {roster.length ? `${live} agent${live > 1 ? 's' : ''} en cours, ${roster.length - live} fini${roster.length - live > 1 ? 's' : ''}` : 'aucun agent lancé'}
        </Text>
      </Text>

      {rows.length > 0 && !compact ? head(ui, 'arbre') : null}
      {rows.map(({ agent, depth }) => {
        const s = stats[agent.id]
        const isLive = agent.status === 'running'
        const color = isLive ? C.signal : agent.status === 'idle' ? C.fg2 : C.fg3
        const glyph = isLive ? (blink ? G.current : ' ') : agent.status === 'idle' ? G.todo : G.done
        return (
          <Box flexDirection="column" paddingLeft={depth * 2}>
            <Text color={color} bold={isLive} wrap="wrap">
              {depth > 0 ? `${G.branch} ` : ''}
              {glyph} {agent.type}
              <Text color={C.fg2} bold={false}> · {oneLine(agent.description)}</Text>
            </Text>
            {compact ? null : (
              <Box paddingLeft={depth > 0 ? 4 : 2}>
                <Text color={C.fg3} wrap="wrap">
                  {agent.status}
                  {s ? ` · ${since(now, s.startedAt)} · ${s.tools} outil${s.tools > 1 ? 's' : ''}` : ''}
                  {s?.tool && isLive ? ` · ${s.tool}` : ''}
                  {s?.stage ? ` · ${STAGE_LABEL[s.stage]}` : ''}
                </Text>
              </Box>
            )}
            {isLive ? (
              <Box paddingLeft={depth > 0 ? 4 : 2} gap={1}>
                <Button key={`voir:${agent.id}`} plain dimColor onPress={() => void $.ui.view({ agentId: agent.id })}>
                  voir
                </Button>
                <Button
                  key={`stop:${agent.id}`}
                  plain
                  dimColor
                  onPress={() =>
                    void $.session
                      .send({ to: { agentId: agent.id }, text: STOP_TEXT })
                      .then(() => $.ui.toast(`arrêt demandé à ${agent.type}`))
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
        <Box marginTop={compact ? 0 : 1}>{ghost(ui, compact ? 'aucun agent en cours' : 'les agents apparaissent ici dès que la session en lance')}</Box>
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
