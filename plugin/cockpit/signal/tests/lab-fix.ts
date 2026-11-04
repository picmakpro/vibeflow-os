import { mock } from 'claude-code/testing'
import type { AgentInfo, On } from 'claude-code'

import { SIGNAL } from './fixture-signal'
import { apresDemarrage } from './apres-demarrage'

// Faux lab des témoins de la correction ciblée (68-FIX-MOD). Contrairement à `labSignal`, il rend l'émetteur et `bash`
// pilotables en cours de session, et espionne les toasts et les copies. La racine de session est un paramètre.

export const PANE = {
  plugin: 'vibeflow',
  component: 'Pane',
  requestId: 'vf-signal',
  props: { title: 'vf-signal', isFocused: false, bodyColumns: 60, placement: 'dock', scroll: { offset: 0, bodyRows: 40 }, view: {} },
} as const

export const BAND = {
  plugin: 'vibeflow',
  component: 'AbovePrompt',
  requestId: 'band',
  props: { hasSurvey: false, isWorking: false, maxRows: 4, bodyColumns: 80, scroll: { offset: 0, bodyRows: 4 }, view: {} },
} as const

export type Reponse = { exitCode?: number; stdout?: string; rejet?: string }
export type LabFix = {
  /** La réponse de l'émetteur (`node …`), modifiable entre deux lectures. */
  emetteur: Reponse
  /** La réponse de `bash …` (le geste d'élagage). */
  bash: Reponse
  /** La réponse du lanceur du cockpit. */
  lanceur: Reponse
  toasts: string[]
  copies: string[]
}
type Opts = { root?: string; home?: string; scripts?: RegExp; agents?: AgentInfo[] }

export function labFix(on: On, o: Opts = {}): LabFix {
  const lab: LabFix = { emetteur: { stdout: JSON.stringify(SIGNAL) }, bash: { stdout: '' }, lanceur: { stdout: '' }, toasts: [], copies: [] }
  const root = o.root ?? '/lab'
  mock.clock(on, { now: 1_000_000 })
  mock.env(on, { HOME: o.home ?? '/home/user' })
  on('command.register', () => ({ value: { command: 'vf-signal' } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('ui.toast', (_, e) => {
    lab.toasts.push(e.text)
    return { value: undefined }
  })
  on('ui.copy', (_, e) => {
    lab.copies.push(e.text)
    return { value: { isCopied: true } }
  })
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('agent.list', () => ({ value: o.agents ?? [] }))
  on('session.root', () => ({ value: root }))
  on('session.usage', () => ({ value: { startedAt: 0, context: { window: 200000, tokens: 50000, percent: 25 }, rateLimits: [], cost: { usd: 0.42 } } }))
  on('fs.stat', (_, e) => ({ value: { kind: 'file', size: 1, mtimeMs: 0, isLink: false, realPath: String(e.path) } }))
  on('fs.exists', (_, e) => ({ value: o.scripts?.test(String(e.path)) ?? false }))
  on('fs.read', (_, e) => {
    if (String(e.path).endsWith('.vibeflow-installed')) return { value: 'cockpit=v1.2.0\n' }
    throw new Error('ENOENT')
  })
  on('fs.list', () => ({ value: [] }))
  on('process.run', (_, e) => {
    const argv = e.argv as readonly string[]
    const r = argv[0] === 'bash' ? lab.bash : /vf-cockpit\.mjs$/.test(String(argv[1])) ? lab.lanceur : lab.emetteur
    if (r.rejet !== undefined) return { deny: r.rejet }
    return { value: { exitCode: r.exitCode ?? 0, stdout: r.stdout ?? '', stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
  })
  return lab
}

/** Laisse finir ce qu'un appui lance sans l'attendre (`void refresh()`). */
export const laisser = (ms = 200) => new Promise(r => setTimeout(r, ms))

export async function monter($: any, composant: typeof PANE | typeof BAND = PANE) {
  await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })
  await apresDemarrage()
  return $.ui.mount({ ...composant, surface: 'terminal' })
}

export const CONTROLES = /[\u0000-\u001f\u007f-\u009f]/
