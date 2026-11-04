import { expect, mock, test } from 'claude-code/testing'
import type { AgentInfo, On } from 'claude-code'

import { brief } from '../hooks/derive'
import { SIGNAL, avec } from './fixture-signal'
import { apresDemarrage } from './apres-demarrage'

// Correction finale (68-FIX-FIN) : P68-D-40 (VF_COCKPIT_SCRIPTS_DIR vidé), M-1 (bidi), M-7 (command.run sans catch),
// N2 (« depot » → « dépôt » dans la vue Équipe), brief aligné sur la pane. Identifiants FIN-2..FIN-6 (lus par verdict.sh).

const PANE = {
  plugin: 'vibeflow', component: 'Pane', requestId: 'vf-signal',
  props: { title: 'vf-signal', isFocused: false, bodyColumns: 80, placement: 'dock', scroll: { offset: 0, bodyRows: 40 }, view: {} },
} as const
const BIDI = /[‪-‮⁦-⁩]/
type Env = Record<string, string> | undefined
type Lab = { envs: Env[]; erreurOuvrir: { v: boolean } }

function lab(on: On, o: { stdout?: string; agents?: AgentInfo[]; refus?: string; limites?: { kind: string; percentUsed: number }[] } = {}): Lab {
  const sp: Lab = { envs: [], erreurOuvrir: { v: false } }
  mock.clock(on, { now: 1_000_000 })
  mock.env(on, { HOME: '/home/user', VF_COCKPIT_SCRIPTS_DIR: '/lab/.claude/scripts' })
  on('command.register', () => ({ value: { command: 'vf-signal' } }))
  on('ui.open', () => {
    if (sp.erreurOuvrir.v) throw new Error('panne-ouverture')
    return { value: { isPlaced: true } }
  })
  on('ui.toast', () => ({ value: undefined }))
  on('ui.status', () => ({ value: undefined }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('session.root', () => ({ value: '/lab' }))
  on('agent.list', () => ({ value: o.agents ?? [] }))
  on('session.usage', () => ({ value: { startedAt: 0, context: { window: 200000, tokens: 1, percent: 1 }, rateLimits: o.limites ?? [], cost: { usd: 0 } } }))
  on('fs.stat', (_, e) => ({ value: { kind: 'file', size: 1, mtimeMs: 0, isLink: false, realPath: String(e.path) } }))
  on('fs.exists', () => ({ value: false }))
  on('fs.read', (_, e) => {
    if (String(e.path).endsWith('.vibeflow-installed')) return { value: 'cockpit=v1.2.0\n' }
    throw new Error('ENOENT')
  })
  on('fs.list', () => ({ value: [] }))
  on('process.run', (_, e) => {
    sp.envs.push(e.init?.env)
    return { value: { exitCode: 0, stdout: (e.argv as readonly string[])[0] === 'node' && !/vf-cockpit\.mjs$/.test(String((e.argv as readonly string[])[1])) ? (o.stdout ?? JSON.stringify(SIGNAL)) : 'Cockpit : http://127.0.0.1:4317/ (Code)\n', stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
  })
  if (o.refus) on('tool.call', () => ({ deny: o.refus! }))
  on('turn.start', () => ({ turnId: 't1' }))
  on('turn.complete', () => ({ text: '' }))
  return sp
}
const demarrer = ($: any) => $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true }).then(apresDemarrage)
const ecrire = async ($: any, args = 'brief'): Promise<string> => (await $.command.run({ command: 'vf-signal', args })).text

test("FIN-2a — init.env de l'émetteur : VF_COCKPIT_SCRIPTS_DIR vaut la chaîne vide même quand l'hôte la pointe vers le lab", async ($, on) => {
  const sp = lab(on)
  await demarrer($)
  expect(sp.envs.length).toBeGreaterThan(0)
  for (const env of sp.envs) expect(env?.VF_COCKPIT_SCRIPTS_DIR).toBe('')
})

test("FIN-2b — init.env du lanceur du cockpit : même règle", async ($, on) => {
  const sp = lab(on)
  await demarrer($)
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  const avant = sp.envs.length
  await ui.press({ key: 'ouvrir-cockpit' })
  expect(sp.envs.length).toBeGreaterThan(avant) // témoin positif : le lanceur a bien tourné
  for (const env of sp.envs) expect(env?.VF_COCKPIT_SCRIPTS_DIR).toBe('')
  await ui.unmount()
})

test("FIN-3a — brief : une description d'agent et une raison de refus portant U+202E sont nettoyées (M-1)", async ($, on) => {
  lab(on, { agents: [{ id: 'a1', type: 'vf-coder', description: 'tâche‮gnirts', status: 'running' }] as AgentInfo[], refus: 'refusé‮raison⁦x⁩' })
  await demarrer($)
  await $.tool.call({ tool: 'Bash', tool_use_id: 'u1', command: 'ls' })
  const texte = await ecrire($)
  expect(texte).toMatch(/tâche/) // témoin positif : la description est bien dans le brief
  expect(texte).toMatch(/refusé/) // idem pour la raison de refus
  expect(texte).not.toMatch(BIDI)
})

test("FIN-3b — brief : U+202E dans le signal du socle (projet) est aussi retiré", async ($, on) => {
  lab(on, { stdout: avec(s => { s.projet = 'a‮b' }) })
  await demarrer($)
  const texte = await ecrire($)
  expect(texte).toMatch(/projet : a/)
  expect(texte).not.toMatch(BIDI)
})

test("FIN-4a — /vf-signal : une panne dans le geste est dite à l'utilisateur, jamais avalée", async ($, on) => {
  const sp = lab(on)
  await demarrer($)
  sp.erreurOuvrir.v = true
  const r = await $.command.run({ command: 'vf-signal', args: '' })
  expect(r?.text).toMatch(/vf-signal : erreur/)
  expect(r?.text).toMatch(/erreur — \S+/) // la cause suit, bornée (le moteur de test la réécrit : « no implementation for ui.open »)
})

test("FIN-5 — vue Équipe : le verrou de dépôt écrit « dépôt », jamais « depot »", async ($, on) => {
  lab(on, { stdout: avec(s => { s.equipe.workers = [{ kind: 'lock', id: 'p', task: 't', tree: 'depot', source: 'driver-lock', etat: 'actif', ageS: 46, stale: false }] }) })
  on('ui.render', ($, e) => { const { Text } = $.ui.resolve(e); return <Text>engine</Text> })
  await demarrer($)
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  await ui.press({ key: 'onglet:equipe' })
  expect(await ui.find({ type: 'Text', text: /actif · dépôt · 46 s/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /depot/ })).toBeUndefined()
  await ui.unmount()
})

const L = { stage: null, isWorking: false, turnStartedAt: 0, tools: 0, lastTurn: null }
const U = (limits: { kind: string; percent: number }[]) => ({ percent: 10, tokens: 1, window: 200000, usd: 0.1, limits })
const AG = { id: 'a1', parentId: null, type: 'vf-coder', description: 'd', status: 'running', name: null }
const stat = (tools: number) => ({ a1: { tools, tool: null, startedAt: 0, lastAt: 0, stage: null } })

test("FIN-6a — brief : les fenêtres de rate limit sont dites comme la pane (« 7 j », « 5 h »), jamais la clé brute", () => {
  const t = brief(null, L, [], {}, [], U([{ kind: 'seven_day', percent: 35 }, { kind: 'five_hour', percent: 12 }]))
  expect(t).toMatch(/- 7 j : 35 %/)
  expect(t).toMatch(/- 5 h : 12 %/)
  expect(t).not.toMatch(/seven_day|five_hour/)
})

test("FIN-6b — brief : une fenêtre inconnue garde son nom (rien d'inventé)", () => {
  expect(brief(null, L, [], {}, [], U([{ kind: 'weekly_opus', percent: 5 }]))).toMatch(/- weekly_opus : 5 %/)
})

test("FIN-6c — brief : « 1 outil » au singulier, « 2 outils » au pluriel", () => {
  expect(brief(null, L, [AG], stat(1), [], null)).toMatch(/ · 1 outil$/m)
  expect(brief(null, L, [AG], stat(2), [], null)).toMatch(/ · 2 outils$/m)
  expect(brief(null, L, [AG], stat(0), [], null)).toMatch(/ · 0 outil$/m)
})

test("FIN-6d — la pane et le brief disent la même fenêtre : « 7 j 35 % » / « - 7 j : 35 % »", async ($, on) => {
  lab(on, { limites: [{ kind: 'seven_day', percentUsed: 35 }] })
  await demarrer($)
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: /7 j 35 %/ })).toBeDefined()
  await ui.unmount()
  expect(await ecrire($)).toMatch(/- 7 j : 35 %/)
})
