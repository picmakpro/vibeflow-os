// vf-signal — cockpit VibeFlow dans une pane.
//
// Règle : le mod observe et affiche, les hooks décident. Il ne touche jamais au
// code ni au planning, n'ouvre aucun réseau. Les seuls gestes qu'il offre sont
// humains (un bouton) et bornés : élaguer un verrou périmé, demander l'arrêt
// d'un agent, compacter, copier une commande.

import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

import { PANE, band } from './band'
import { brief, stageOf } from './derive'
import { PHRASE_ANCIEN_MOD, ancienModPresent } from './ancien-mod'
import { apresBash, emetteurAuto, estInteractive, noter, poserSession, pulsation } from './cadence'
import { cockpitInstalle } from './gating'
import { VIEWS, oneLine } from './ds'
import { themeDe } from './tokens'
import { pane } from './pane'
import { recordRefusal, refreshAll, refreshCheap, refreshRoster, refreshSignalAuto, setStage } from './refresh'
import type { AgentStat, View } from '../types'

// Les valeurs lues ici. Un atome se déclare dans le fichier qui le lit (règle
// du validateur) : la même référence désigne la même valeur partout.
const signal = atom({ plugin: 'vibeflow', key: 'signal' } as const, null)
const loop = atom({ plugin: 'vibeflow', key: 'loop' } as const, { stage: null, isWorking: false, turnStartedAt: 0, tools: 0, lastTurn: null })
const roster = atom({ plugin: 'vibeflow', key: 'roster' } as const, [])
const stats = atom({ plugin: 'vibeflow', key: 'stats' } as const, {})
const refusals = atom({ plugin: 'vibeflow', key: 'refusals' } as const, [])
const loopAlert = atom({ plugin: 'vibeflow', key: 'loopAlert' } as const, null)
const usage = atom({ plugin: 'vibeflow', key: 'usage' } as const, null)
const view = atom({ plugin: 'vibeflow', key: 'view' } as const, 'mission')
const ancienMod = atom({ plugin: 'vibeflow', key: 'ancienMod' } as const, false)
const theme = atom({ plugin: 'vibeflow', key: 'theme' } as const, 'sombre')
const signalErreur = atom({ plugin: 'vibeflow', key: 'signalErreur' } as const, null)

export const register: Register = on => {
  let home: string | undefined
  // Posé en session.start : sans `cockpit=` au registre, le mod n'enregistre ni commande, ni pane, ni bandeau (P68-D-18).
  let actif = false
  let blink = false
  let blinkTimer: { cancel: () => void } | null = null
  let refreshTimer: { cancel: () => void } | null = null
  let recentCalls: string[] = []
  // --- la session ------------------------------------------------------------

  on('session.start', async ($, e, next) => {
    home = await $.env.get('HOME')
    actif = await cockpitInstalle($, await $.session.root().catch(() => undefined), home)
    if (!actif) return next(e)
    // le thème de la personne, une fois ; toute erreur laisse le sombre (« sombre d'abord », P68-PL-10)
    const rows = await $.config.list().catch(() => [])
    await update($, theme, () => themeDe(rows))
    const ancien = await ancienModPresent($, home)
    await update($, ancienMod, () => ancien)
    if (ancien) $.ui.toast(PHRASE_ANCIEN_MOD)
    await $.command.register({
      name: 'vf-signal',
      description: 'Cockpit VibeFlow : mission, équipe, macro. « /vf-signal équipe », « macro », « mission », ou « brief » pour un Markdown.',
    })
    // P68-D-41 : jamais d'attente de l'émetteur au démarrage ; la liste des agents et le coût, eux, ne lancent aucun processus.
    poserSession(e.isInteractive)
    await noter($)
    void refreshSignalAuto($).catch(() => undefined)
    await refreshCheap($)
    refreshTimer?.cancel()
    refreshTimer = null
    // le minuteur n'existe qu'en session interactive, et ne rafraîchit que pane ouverte
    if (estInteractive()) refreshTimer = $.clock.every(10000, () => void pulsation($).catch(() => undefined))
    if (e.isInteractive) void $.ui.open({ id: PANE, title: 'vf-signal', rows: 18 })
    return next(e)
  })

  on('session.end', async ($, e, next) => {
    if (!actif) return next(e)
    blinkTimer?.cancel()
    blinkTimer = null
    blink = false
    // Un /clear ne rejoue pas session.start : on garde le rafraîchissement du
    // disque et on remet à zéro ce que la conversation portait.
    if (e.reason === 'clear') {
      recentCalls = []
      await update($, loop, () => ({ stage: null, isWorking: false, turnStartedAt: 0, tools: 0, lastTurn: null }))
      await update($, stats, () => ({}))
      await update($, refusals, () => [])
      await update($, loopAlert, () => null)
      await refreshCheap($)
      await emetteurAuto($)
      return next(e)
    }
    refreshTimer?.cancel()
    return next(e)
  })

  on('command.run', { command: 'vf-signal' }, async ($, e, next) => {
    if (!actif) return next(e)
    const arg = e.args.trim().toLowerCase().replace('équipe', 'equipe')
    // geste explicite : rafraîchissement aussitôt, sans la limite d'une minute (le brief doit rendre des données à jour)
    await noter($)
    if (arg === 'brief') {
      await refreshAll($)
      const [sig, l, agents, agentStats, r, u, erreur] = await Promise.all([
        read($, signal), read($, loop), read($, roster), read($, stats), read($, refusals), read($, usage), read($, signalErreur),
      ])
      return { text: brief(sig, l, agents, agentStats, r, u, erreur) }
    }
    if ((VIEWS as readonly string[]).includes(arg)) await update($, view, () => arg as View)
    await refreshAll($)
    const opened = await $.ui.open({ id: PANE, title: 'vf-signal', focus: true, rows: 18 })
    return { text: opened.isPlaced ? 'vf-signal : pane ouverte.' : `vf-signal : pane en attente (${opened.reason}).` }
  }).catch((_, e, next) => ({ text: `vf-signal : erreur — ${oneLine(next.error.message ?? 'cause inconnue').slice(0, 120)}` }))

  // --- le tour ---------------------------------------------------------------

  on('turn.start', async ($, e, next) => {
    if (!actif || e.agentId !== undefined) return next(e)
    recentCalls = []
    const now = await $.clock.now()
    await update($, loop, l => ({ ...l, isWorking: true, turnStartedAt: now, tools: 0 }))
    await update($, loopAlert, () => null)
    blinkTimer?.cancel()
    blinkTimer = $.clock.every(600, () => {
      blink = !blink
      $.ui.invalidate('ui.render')
    })
    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    if (!actif) return next(e)
    if (e.agentId !== undefined) {
      await refreshRoster($)
      return next(e)
    }
    blinkTimer?.cancel()
    blinkTimer = null
    blink = false
    const l = await read($, loop)
    const lastTurn = { seconds: Math.round(e.durationMs / 1000), tools: l.tools, outputTokens: e.usage?.output_tokens ?? 0 }
    await update($, loop, cur => ({ ...cur, isWorking: false, lastTurn }))
    await refreshCheap($)
    await emetteurAuto($)
    $.ui.status(undefined)
    return next(e)
  })

  // --- l'équipe --------------------------------------------------------------

  on('agent.spawn', async ($, e, next) => {
    if (!actif) return next(e)
    await setStage($, e.subagentType, e.parentAgentId)
    const startedAt = await $.clock.now()
    const ran = await next(e)
    if (!ran.deny && ran.agentId) {
      const id = ran.agentId
      const stat: AgentStat = { tools: 0, tool: null, startedAt, lastAt: startedAt, stage: stageOf(e.subagentType) }
      await update($, stats, s => ({ ...s, [id]: stat }))
      await refreshRoster($)
    }
    return ran
  }).catch(($, e, next) => next(e))

  on('skill.prompt', async ($, e, next) => {
    if (!actif) return next(e)
    await setStage($, e.skill, undefined)
    return next(e)
  })

  // --- les outils : compte, boucle, refus --------------------------------------

  on('tool.call', async ($, e, next) => {
    if (!actif) return next(e)
    const { tool, tool_use_id, agentId, requestMeta, ...args } = e
    void requestMeta
    const signature = `${agentId ?? 'main'}|${tool}|${JSON.stringify(args)}`
    recentCalls = [...recentCalls, signature].slice(-8)
    const same = recentCalls.filter(s => s === signature).length
    if (same >= 3) {
      await update($, loopAlert, () => `boucle · ${tool} ×${same}`)
      $.ui.status(`vf-signal : ${tool} appelé ${same} fois à l'identique`)
    }
    const now = await $.clock.now()
    if (agentId === undefined) {
      await update($, loop, l => ({ ...l, tools: l.tools + 1 }))
    } else {
      const id = agentId
      await update($, stats, s => {
        const cur = s[id] ?? { tools: 0, tool: null, startedAt: now, lastAt: now, stage: null }
        return { ...s, [id]: { ...cur, tools: cur.tools + 1, tool, lastAt: now } }
      })
    }

    const ran = await next(e)
    if (ran.deny !== undefined) {
      await recordRefusal($, tool_use_id ?? signature, tool, ran.deny)
    } else if (tool === 'Bash' && /driver-lock|dag\.sh|git (commit|checkout|switch|merge)|gsd|vf-/.test(e.command ?? '')) {
      void apresBash($).catch(() => undefined)
    }
    return ran
  }).catch(($, e, next) => next(e))

  // Les gardes VibeFlow (guard-driver-lock, guard-agent-write…) sont des hooks
  // classiques : leur `permissionDecision: deny` arrive ici, avec sa raison.
  on('classic.PreToolUse', async ($, e, next) => {
    if (!actif) return next(e)
    const ran = await next(e)
    if (ran.deny !== undefined) {
      await recordRefusal($, e.tool_use_id ?? `${e.tool}-${await $.clock.now()}`, e.tool, ran.deny)
      $.ui.status(`vf-signal : ${e.tool} refusé par un garde`)
    }
    return ran
  }).catch(($, e, next) => next(e))

  // --- les dessins -------------------------------------------------------------

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => (actif ? (await band($, e)) ?? next(e) : next(e)))

  on('ui.render', { component: 'Pane', requestId: PANE }, ($, e, next) => (actif ? pane($, e, blink, home) : next(e)))
}
