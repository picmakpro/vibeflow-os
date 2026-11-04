// Vue macro : le projet, le jalon de la phase active et ses phases, la phase active et ses plans, les autres jalons.
// Tout vient de `signal@1` (P68-D-02) ; le bloc backlog n'existe plus (P68-D-24).

import { G, oneLine } from '../ds'
import { couleurEtat } from '../tokens'
import { arbreCourant, jalonCourant } from '../derive'
import { ghost, head } from './common'
import type { Ctx } from './common'
import type { SignalPhase } from '../../types'

const plans = (p: SignalPhase): string => (p.avancement.plans.total > 0 ? ` · ${p.avancement.plans.faits}/${p.avancement.plans.total} plans` : '')

export function macro(ctx: Ctx): JSX.Element {
  const { ui, pal, s, compact } = ctx
  const { Box, Text } = ui
  const jalons = s?.jalons ?? []
  const current = jalonCourant(s) ?? jalons[jalons.length - 1] ?? null
  const active = arbreCourant(s)?.phaseActive ?? null
  const activePhase = active ? s?.phases.find(p => p.key === active.key) : undefined
  const phasesOf = (keys: string[]): SignalPhase[] => keys.map(k => s?.phases.find(p => p.key === k)).filter((p): p is SignalPhase => p !== undefined)
  const faites = (keys: string[]) => phasesOf(keys).filter(p => p.fait).length

  // En compact : la phase active et ses deux voisines seulement.
  const phases = current ? phasesOf(current.phases) : []
  const at = phases.findIndex(p => p.key === active?.key)
  const shown = compact && phases.length > 5 ? phases.slice(Math.max(0, at - 2), Math.max(0, at - 2) + 5) : phases

  return (
    <Box flexDirection="column">
      {s?.projet && !compact ? (
        <Text color={pal.text} wrap="wrap">
          {oneLine(s.projet)}
        </Text>
      ) : null}
      {current ? (
        <Text color={pal.text} wrap="wrap">
          {`${G.done} ${oneLine(current.texte)} · ${faites(current.phases)}/${current.phases.length} phases`}
        </Text>
      ) : (
        ghost(ui, pal, 'aucun jalon ouvert')
      )}
      {shown.map(p => {
        const isNow = active !== null && p.key === active.key
        const color = couleurEtat(p.fait ? 'fait' : p.avancement.etat, pal)
        const glyph = p.fait ? G.done : isNow ? G.current : G.todo
        return (
          <Box paddingLeft={2}>
            <Text color={color} bold={isNow} wrap="wrap">
              {`${glyph} ${p.n} ${oneLine(p.nom)} · ${oneLine(p.libelle)}${plans(p)}`}
            </Text>
          </Box>
        )
      })}

      {compact ? null : head(ui, pal, 'phase')}
      {compact ? null : (
        <Text color={pal.text} wrap="wrap">
          {`${active ? `${active.n} ${oneLine(active.nom)}` : 'aucune phase en cours'}${activePhase ? ` · ${oneLine(activePhase.libelle)}${plans(activePhase)}` : ''}${s?.layout.actif ? ` · ${s.layout.actif}` : ''}`}
        </Text>
      )}

      {!compact && jalons.length > 1 ? head(ui, pal, 'jalons ouverts') : null}
      {compact
        ? null
        : jalons
            .filter(j => j !== current)
            .map(j => (
              <Box paddingLeft={2}>
                <Text color={pal['text-3']} wrap="wrap">
                  {`${G.todo} ${oneLine(j.texte)} · ${faites(j.phases)}/${j.phases.length}`}
                </Text>
              </Box>
            ))}
    </Box>
  )
}
