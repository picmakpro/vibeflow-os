import { expect, mock, test } from 'claude-code/testing'
import type { AgentInfo, On } from 'claude-code'

const PANE = {
  plugin: 'vibeflow',
  component: 'Pane',
  requestId: 'vf-signal',
  props: {
    title: 'vf-signal',
    isFocused: false,
    bodyColumns: 60,
    placement: 'dock',
    scroll: { offset: 0, bodyRows: 40 },
    view: {},
  },
} as const

const BAND = {
  plugin: 'vibeflow',
  component: 'AbovePrompt',
  requestId: 'band',
  props: { hasSurvey: false, isWorking: false, maxRows: 4, bodyColumns: 80, scroll: { offset: 0, bodyRows: 4 }, view: {} },
} as const

const DAG = JSON.stringify({
  nodes: [
    { id: 'cadrage', step: 'cadrage 59', deps: [], status: 'done' },
    { id: 'plan', step: 'plan Phase 59', deps: ['cadrage'], status: 'running' },
    { id: 'arbitrage', step: 'arbitrage Samuel sur le plan', deps: ['plan'], status: 'pending' },
  ],
})

const STATE = [
  '---',
  'milestone: equipe-produit-v1.0',
  'current_phase: 59',
  'current_phase_name: Bundle produit',
  'status: in_progress',
  'progress:',
  '  total_plans: 4',
  '  completed_plans: 1',
  '---',
  '# Project State',
].join('\n')

const LOCK = JSON.stringify({
  present: true,
  locks: [
    { present: true, owner: 'vf-dev-manager-p59', step: 'mission', age_seconds: 97000, ttl: 1800, stale: true, children_running: 1, scope: 'compartiment', ws: 'fiabilite' },
  ],
})

const ORPHANS = JSON.stringify({ present: true, orphans: [{ agent_id: 'a1', parent: '', role: 'vf-coder', node: 'plan', owner: 'vf-dev-manager-p59', age_seconds: 120, depth: 1 }] })

/** Un lab : le compartiment, un STATE.md, un DAG, un verrou périmé, des agents. */
function lab(on: On, agents: AgentInfo[] = []) {
  mock.clock(on, { now: 1_000_000 })
  mock.env(on, { HOME: '/home/user' })
  on('command.register', () => ({ value: { command: 'vf-signal' } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('agent.list', () => ({ value: agents }))
  on('session.root', () => ({ value: '/lab' }))
  on('session.usage', () => ({ value: { startedAt: 0, context: { window: 200000, tokens: 50000, percent: 25 }, rateLimits: [], cost: { usd: 0.42 } } }))
  on('fs.exists', (_, e) => ({ value: /active-workstream|STATE\.md|driver-lock\.sh$/.test(String(e.path)) && !String(e.path).includes('.claude/scripts') }))
  on('fs.read', (_, e) => {
    const path = String(e.path)
    if (path.endsWith('active-workstream')) return { value: 'fiabilite' }
    if (path.endsWith('STATE.md')) return { value: STATE }
    if (path.endsWith('.dag.json')) return { value: DAG }
    return { value: '' }
  })
  on('fs.list', (_, e) =>
    String(e.path).endsWith('/missions') ? { value: [{ name: 'p59.dag.json', kind: 'file', size: 1, mtimeMs: 5, isLink: false }] } : { value: [] },
  )
  on('process.run', (_, e) => {
    const argv = (e.argv as readonly string[]).join(' ')
    const stdout = argv.includes('orphans') ? ORPHANS : LOCK
    return { value: { exitCode: 0, stdout, stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
  })
  // Ce que l'engine dessinerait là où le mod laisse passer.
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })
}

test('la pane montre la phase, le DAG par vagues et le verrou périmé, sur chaque surface', async ($, on) => {
  lab(on)
  await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })

  for (const surface of ['terminal', 'desktop', 'vscode', 'mobile'] as const) {
    const ui = await $.ui.mount({ ...PANE, surface })
    expect(await ui.find({ type: 'Text', text: /equipe-produit-v1\.0/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /Bundle produit/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /plan Phase 59/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /vf-coder/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /périmé/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /verrou périmé de vf-dev-manager-p59/ })).toBeDefined()
    await ui.unmount()
  }
})

test('le bandeau porte la prochaine action humaine et se masque', async ($, on) => {
  lab(on)
  await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })

  const ui = await $.ui.mount({ ...BAND, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: /verrou périmé/ })).toBeDefined()
  await ui.press({ key: 'masquer' })
  expect(await ui.find({ type: 'Text', text: /verrou périmé/ })).toBeUndefined()
  await ui.unmount()
})

test("la vue équipe liste les agents en arbre, avec le geste d'arrêt", async ($, on) => {
  lab(on, [
    { id: 'm1', type: 'vf-dev-manager', description: 'mission 59', status: 'running' },
    { id: 'c1', parentId: 'm1', type: 'vf-coder', description: 'plan 59-01', status: 'running' },
  ])
  await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })

  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  await ui.press({ key: 'onglet:equipe' })
  expect(await ui.find({ type: 'Text', text: /vf-dev-manager/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /vf-coder/ })).toBeDefined()
  expect(await ui.find({ key: 'stop:c1' })).toBeDefined()
  await ui.press({ key: 'onglet:macro' })
  expect(await ui.find({ type: 'Text', text: /backlog/ })).toBeDefined()
  await ui.unmount()
})
