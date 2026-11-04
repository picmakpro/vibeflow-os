import { expect, mock, test } from 'claude-code/testing'
import type { On } from 'claude-code'
import { apresDemarrage } from './apres-demarrage'

// Gating du mod embarqué (68-12 ; P68-D-18) : le registre `scripts/.vibeflow-installed` du scope projet
// (`<root>/.claude/scripts/`) puis du scope user (`<HOME>/.claude/scripts/`) doit porter une ligne `cockpit=`.

const BAND = {
  plugin: 'vibeflow',
  component: 'AbovePrompt',
  requestId: 'band',
  props: { hasSurvey: false, isWorking: false, maxRows: 4, bodyColumns: 80, scroll: { offset: 0, bodyRows: 4 }, view: {} },
} as const

const PANE = {
  plugin: 'vibeflow',
  component: 'Pane',
  requestId: 'vf-signal',
  props: { title: 'vf-signal', isFocused: false, bodyColumns: 60, placement: 'dock', scroll: { offset: 0, bodyRows: 40 }, view: {} },
} as const

const PROJET = '/lab/.claude/scripts/.vibeflow-installed'
const USER = '/home/user/.claude/scripts/.vibeflow-installed'
const ANCIEN = '/home/user/.claude/mods/vf-signal'

const LOCK = JSON.stringify({
  present: true,
  locks: [{ present: true, owner: 'mgr', step: 'mission', age_seconds: 97000, ttl: 1800, stale: true, children_running: 0, scope: 'compartiment', ws: 'fiabilite' }],
})
const STATE = ['---', 'milestone: m', 'current_phase: 68', 'current_phase_name: Signal', 'status: in_progress', '---'].join('\n')

type Appels = { commandes: number; ouvertures: number; ecritures: string[] }

/** Un lab dont les registres sont servis par `registres` (chemin -> contenu) ; l'ancien mod par `ancien`. */
function lab(on: On, registres: Record<string, string>, ancien = false): Appels {
  const appels: Appels = { commandes: 0, ouvertures: 0, ecritures: [] }
  mock.clock(on, { now: 1_000_000 })
  mock.env(on, { HOME: '/home/user' })
  on('command.register', () => {
    appels.commandes++
    return { value: { command: 'vf-signal' } }
  })
  on('ui.open', () => {
    appels.ouvertures++
    return { value: { isPlaced: true } }
  })
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('agent.list', () => ({ value: [] }))
  on('session.root', () => ({ value: '/lab' }))
  on('session.usage', () => ({ value: { startedAt: 0, context: { window: 200000, tokens: 50000, percent: 25 }, rateLimits: [], cost: { usd: 0.42 } } }))
  on('fs.exists', (_, e) => {
    const p = String(e.path)
    if (p.startsWith(ANCIEN)) return { value: ancien && p.endsWith('hooks/hooks.json') }
    return { value: /active-workstream|STATE\.md|driver-lock\.sh$/.test(p) && !p.includes('.claude/scripts') }
  })
  on('fs.read', (_, e) => {
    const p = String(e.path)
    if (p in registres) return { value: registres[p] }
    if (p.endsWith('.vibeflow-installed')) throw new Error('ENOENT')
    if (p.endsWith('active-workstream')) return { value: 'fiabilite' }
    if (p.endsWith('STATE.md')) return { value: STATE }
    return { value: '' }
  })
  on('fs.write', (_, e) => {
    appels.ecritures.push(String(e.path))
    return { value: undefined }
  })
  on('fs.list', () => ({ value: [] }))
  on('process.run', (_, e) => {
    const argv = (e.argv as readonly string[]).join(' ')
    if (argv.includes('vf-signal')) appels.ecritures.push(argv)
    return { value: { exitCode: 0, stdout: LOCK, stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
  })
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })
  return appels
}

test('E1 — sans ligne cockpit= (projet puis user), ni commande, ni pane, ni bandeau', async ($, on) => {
  const appels = lab(on, { [PROJET]: 'conductor=v1.0.0\n', [USER]: 'dev-orchestrator=v2.0.0\n' })
  await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })
  await apresDemarrage()
  expect(appels.commandes).toBe(0)
  expect(appels.ouvertures).toBe(0)
  const ui = await $.ui.mount({ ...BAND, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: /engine/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /verrou périmé/ })).toBeUndefined()
  await ui.unmount()
})

test('E2 — registre user avec cockpit=v1.2.0 : commande enregistrée, pane ouverte', async ($, on) => {
  const appels = lab(on, { [USER]: 'conductor=v1.0.0\ncockpit=v1.2.0\n' })
  await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })
  await apresDemarrage()
  expect(appels.commandes).toBe(1)
  expect(appels.ouvertures).toBe(1)
})

test('E3 — registre projet seul avec cockpit= : même résultat', async ($, on) => {
  const appels = lab(on, { [PROJET]: 'cockpit=v1.2.0\n' })
  await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })
  await apresDemarrage()
  expect(appels.commandes).toBe(1)
  expect(appels.ouvertures).toBe(1)
})

test("E4 — l'ancien mod hors dépôt est signalé dans la pane avec le risque de deux panes, sans rien retirer", async ($, on) => {
  const appels = lab(on, { [USER]: 'cockpit=v1.2.0\n' }, true)
  await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })
  await apresDemarrage()
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: /ancien mod vf-signal détecté/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /deux panes/ })).toBeDefined()
  await ui.unmount()
  expect(appels.ecritures).toEqual([])
})

test("E4b — sans ancien mod, la pane ne le mentionne pas", async ($, on) => {
  lab(on, { [USER]: 'cockpit=v1.2.0\n' }, false)
  await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })
  await apresDemarrage()
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: /ancien mod vf-signal détecté/ })).toBeUndefined()
  await ui.unmount()
})
