import { expect, test } from 'claude-code/testing'
import type { On } from 'claude-code'

import { SIGNAL } from './fixture-signal'

// Correction ciblée ST-1 (68-FIX-MOD ; P68-D-18) : sans ligne `cockpit=` au registre, AUCUN événement de session
// ne fait travailler le mod — ni process.run, ni minuterie, ni invalidation de rendu, ni écriture d'état, ni lecture
// de l'engine. Identifiants préfixés FX- (verdict.sh compare le titre par son début).

type Espion = { process: string[]; minuteries: number; invalidations: number; ecritures: number; agentList: number; usage: number }

/** Un lab sans registre `cockpit=` (ou avec, selon `registre`) qui compte tout ce que le mod déclenche. */
function lab(on: On, registre: string | null): Espion {
  const sp: Espion = { process: [], minuteries: 0, invalidations: 0, ecritures: 0, agentList: 0, usage: 0 }
  on('clock.now', () => ({ value: 1_000_000 }))
  on('clock.every', () => {
    sp.minuteries++
    return { value: undefined }
  })
  on('ui.invalidate', () => {
    sp.invalidations++
    return { value: undefined }
  })
  on('state.set', () => {
    sp.ecritures++
    return { value: { isSet: true, version: 1 } }
  })
  on('env.get', (_, e) => ({ value: e.name === 'HOME' ? '/home/user' : undefined }))
  on('command.register', () => ({ value: { command: 'vf-signal' } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('ui.status', () => ({ value: undefined }))
  on('ui.toast', () => ({ value: undefined }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('session.root', () => ({ value: '/lab' }))
  on('agent.list', () => {
    sp.agentList++
    return { value: [] }
  })
  on('session.usage', () => {
    sp.usage++
    return { value: { startedAt: 0, context: { window: 200000, tokens: 1, percent: 1 }, rateLimits: [], cost: { usd: 0 } } }
  })
  on('fs.exists', () => ({ value: false }))
  on('fs.read', (_, e) => {
    if (registre !== null && String(e.path).endsWith('.vibeflow-installed')) return { value: registre }
    throw new Error('ENOENT')
  })
  on('fs.list', () => ({ value: [] }))
  on('process.run', (_, e) => {
    sp.process.push((e.argv as readonly string[]).join(' '))
    return { value: { exitCode: 0, stdout: JSON.stringify(SIGNAL), stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
  })
  on('turn.start', () => ({ turnId: 't1' }))
  on('turn.complete', () => ({ text: '' }))
  on('tool.call', () => ({ result: {} }))
  on('agent.spawn', () => ({ model: 'm', agentId: 'ag1' }))
  on('command.run', () => ({ text: 'engine' }))
  return sp
}

/** Un tour complet : début, appel d'outil à argument chargé, spawn, fin, puis la commande. */
async function tour($: any) {
  await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })
  await $.turn.start({ text: 'x', turnId: 't1' })
  await $.tool.call({ tool: 'Bash', tool_use_id: 'u1', command: 'bash driver-lock.sh status' })
  await $.agent.spawn({ tool_use_id: 'u2', prompt: 'p', description: 'd', subagentType: 'vf-coder' })
  await $.turn.complete({ answer: '', durationMs: 1000, isAborted: false, turnId: 't1', reason: 'end_turn' })
  await $.command.run({ command: 'vf-signal', args: 'brief' })
}

const PROPRIETES: [string, string, (sp: Espion) => unknown, unknown][] = [
  ['FX-1a', 'aucun process.run', sp => sp.process, []],
  ['FX-1e', 'aucune minuterie', sp => sp.minuteries, 0],
  ['FX-1f', "aucune invalidation de rendu", sp => sp.invalidations, 0],
  ['FX-1g', "aucune écriture d'état", sp => sp.ecritures, 0],
  ['FX-1h', "aucune lecture agent.list ni session.usage", sp => [sp.agentList, sp.usage], [0, 0]],
]
for (const [id, dit, lu, attendu] of PROPRIETES) {
  test(`${id} — sans cockpit= : un tour complet ne provoque ${dit}`, async ($, on) => {
    const sp = lab(on, 'conductor=v1.0.0\n')
    await tour($)
    expect(lu(sp)).toEqual(attendu)
  })
}

test("FX-1b — sans cockpit= : l'émetteur n'est jamais lancé, sous son vrai nom (vf-cockpit-signal.mjs)", async ($, on) => {
  const sp = lab(on, null)
  await tour($)
  expect(sp.process.filter(a => a.includes('vf-cockpit-signal.mjs'))).toEqual([])
})

test("FX-1c — sans cockpit= : /vf-signal brief rend la réponse de l'engine, pas celle du mod", async ($, on) => {
  lab(on, null)
  await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })
  expect(await $.command.run({ command: 'vf-signal', args: 'brief' })).toEqual({ text: 'engine' })
})

test("FX-1d — avec cockpit= : le même tour fait travailler le mod (le témoin n'est pas vide)", async ($, on) => {
  const sp = lab(on, 'cockpit=v1.2.0\n')
  await tour($)
  expect(sp.process.filter(a => a.includes('vf-cockpit-signal.mjs')).length).toBeGreaterThan(0)
  expect(sp.minuteries).toBeGreaterThan(0)
  expect(sp.ecritures).toBeGreaterThan(0)
  expect(sp.agentList).toBeGreaterThan(0)
})
