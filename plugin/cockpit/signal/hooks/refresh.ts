// Les rafraîchissements : chacun lit une source (disque, engine) et pose la
// valeur dans `$.state`, ce qui redessine la pane.

import { atom, update } from 'claude-code'
import type { EngineInterface } from 'claude-code'

import { stageOf } from './derive'
import { readDisk, readMacro } from './disk'
import { lireSignal } from './socle'
import type { Refusal, Usage } from '../types'

const disk = atom({ plugin: 'vibeflow', key: 'disk' } as const, null)
const macro = atom({ plugin: 'vibeflow', key: 'macro' } as const, null)
const loop = atom({ plugin: 'vibeflow', key: 'loop' } as const, { stage: null, isWorking: false, turnStartedAt: 0, tools: 0, lastTurn: null })
const roster = atom({ plugin: 'vibeflow', key: 'roster' } as const, [])
const stats = atom({ plugin: 'vibeflow', key: 'stats' } as const, {})
const refusals = atom({ plugin: 'vibeflow', key: 'refusals' } as const, [])
const usage = atom({ plugin: 'vibeflow', key: 'usage' } as const, null)
const signal = atom({ plugin: 'vibeflow', key: 'signal' } as const, null)
const signalErreur = atom({ plugin: 'vibeflow', key: 'signalErreur' } as const, null)

export async function refreshDisk($: EngineInterface, home: string | undefined): Promise<void> {
  const d = await readDisk($, home)
  await update($, disk, () => d)
}

/** L'émetteur du socle ; en cas d'échec plus aucune donnée n'est gardée, l'erreur est dite à côté. */
export async function refreshSignal($: EngineInterface, pluginRoot: string, root: string | undefined): Promise<void> {
  const lecture = root ? await lireSignal($, pluginRoot, root) : { erreur: 'racine de session inconnue' }
  if ('signal' in lecture) {
    await update($, signal, () => lecture.signal)
    await update($, signalErreur, () => null)
  } else {
    await update($, signal, () => null)
    await update($, signalErreur, () => lecture.erreur)
  }
}

export async function refreshMacro($: EngineInterface): Promise<void> {
  const m = await readMacro($)
  await update($, macro, () => m)
}

export async function refreshRoster($: EngineInterface): Promise<void> {
  const list = await $.agent.list().catch(() => [])
  await update($, roster, () =>
    list.map(a => ({
      id: a.id,
      parentId: a.parentId ?? null,
      type: a.type,
      description: a.description,
      status: String(a.status),
      name: a.name ?? null,
    })),
  )
}

export async function refreshUsage($: EngineInterface): Promise<void> {
  const u = await $.session.usage().catch(() => undefined)
  if (!u) return
  const next: Usage = {
    percent: u.context.percent ?? null,
    tokens: u.context.tokens ?? null,
    window: u.context.window,
    usd: u.cost?.usd ?? null,
    limits: u.rateLimits.map(r => ({ kind: r.kind, percent: r.percentUsed })),
  }
  await update($, usage, () => next)
}

export async function refreshAll($: EngineInterface, home: string | undefined): Promise<void> {
  const root = await $.session.root().catch(() => undefined)
  await Promise.all([refreshDisk($, home), refreshMacro($), refreshRoster($), refreshUsage($), refreshSignal($, $.plugin.root, root)])
}

/** Le disque et l'équipe seuls : ce qui bouge pendant qu'un tour tourne. */
export async function refreshLive($: EngineInterface, home: string | undefined): Promise<void> {
  const root = await $.session.root().catch(() => undefined)
  await Promise.all([refreshDisk($, home), refreshRoster($), refreshSignal($, $.plugin.root, root)])
}

/** Un agent ou un skill nommé signale un temps de la boucle. */
export async function setStage($: EngineInterface, name: string, agentId: string | undefined): Promise<void> {
  const stage = stageOf(name)
  if (!stage) return
  await update($, loop, l => (l.stage === stage ? l : { ...l, stage }))
  if (agentId) await update($, stats, s => (s[agentId] ? { ...s, [agentId]: { ...s[agentId]!, stage } } : s))
}

export async function recordRefusal($: EngineInterface, id: string, tool: string, reason: string): Promise<void> {
  const refusal: Refusal = { id, tool, reason, at: await $.clock.now() }
  await update($, refusals, list => (list.some(r => r.id === id) ? list : [...list, refusal].slice(-40)))
}
