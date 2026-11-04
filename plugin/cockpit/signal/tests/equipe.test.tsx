import { expect, test } from 'claude-code/testing'

import { avec, labSignal } from './fixture-signal'
import { apresDemarrage } from './apres-demarrage'

// La vue Équipe lit `signal@1.equipe` (who@2) : toutes sessions, tous worktrees (68-07 ; P68-D-03, P68-D-17, VFSG-04).
// Les gestes « voir » et « demander l'arrêt » ne s'offrent qu'aux agents de la session courante (`$.agent.list()`).
// Identifiant du témoin en tête de titre (lu par verdict.sh).

const PANE = {
  plugin: 'vibeflow',
  component: 'Pane',
  requestId: 'vf-signal',
  props: { title: 'vf-signal', isFocused: false, bodyColumns: 60, placement: 'dock', scroll: { offset: 0, bodyRows: 40 }, view: {} },
} as const
const COMPACT = { ...PANE, props: { ...PANE.props, placement: 'inline' } } as const

const w = (o: Record<string, unknown>) => ({ source: 'sessions', tree: 'arbre principal', etat: 'actif', ageS: 30, ...o })
// m1 > c1 : la session courante ; x9 : un sous-agent d'une autre session, dans un autre worktree ; r0 : un agent terminé ; o1 : un orphelin du registre
const WORKERS = [
  w({ kind: 'subagent', id: 'm1', role: 'vf-dev-manager', task: 'mission soixante-huit' }),
  w({ kind: 'subagent', id: 'c1', parent: 'm1', role: 'vf-coder', task: 'plan sept' }),
  w({ kind: 'subagent', id: 'x9', role: 'vf-coder', task: 'plan autre-session', tree: '.claude/worktrees/autre', branch: 'feat/autre' }),
  w({ kind: 'subagent', id: 'r0', role: 'vf-reviewer', task: 'revue finie', etat: 'termine' }),
  w({ kind: 'registered', id: 'o1', role: 'vf-auditer', task: 'audit perdu', source: 'registre', stale: true, orphan: true, etat: undefined }),
]
const STDOUT = avec(s => { s.equipe.workers = WORKERS })
const AGENTS = [
  { id: 'm1', type: 'vf-dev-manager', description: 'mission 68', status: 'running' },
  { id: 'c1', parentId: 'm1', type: 'vf-coder', description: 'plan 68-07', status: 'running' },
]

async function pane($: any, props: any = PANE) {
  await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })
  await apresDemarrage()
  const ui = await $.ui.mount({ ...props, surface: 'terminal' })
  // la vue choisie reste d'un montage à l'autre : l'onglet courant n'a pas de bouton
  if (await ui.find({ key: 'onglet:equipe' })) await ui.press({ key: 'onglet:equipe' })
  return ui
}

test("Q1 — l'agent d'une autre session est montré, sans geste ; ceux de la session ont voir et arrêt", async ($, on) => {
  labSignal(on, { stdout: STDOUT, agents: AGENTS as any })
  const ui = await pane($)
  expect(await ui.find({ type: 'Text', text: /plan autre-session/ })).toBeDefined()
  expect(await ui.find({ key: 'stop:x9' })).toBeUndefined()
  expect(await ui.find({ key: 'voir:x9' })).toBeUndefined()
  expect(await ui.find({ key: 'stop:c1' })).toBeDefined()
  expect(await ui.find({ key: 'voir:c1' })).toBeDefined()
  await ui.unmount()
})

test("Q1b — un orphelin du registre est montré comme tel, sans geste", async ($, on) => {
  labSignal(on, { stdout: STDOUT, agents: AGENTS as any })
  const ui = await pane($)
  expect(await ui.find({ type: 'Text', text: /audit perdu/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /orphelin/ })).toBeDefined()
  expect(await ui.find({ key: 'stop:o1' })).toBeUndefined()
  await ui.unmount()
})

test("Q1c — la liste de la session seule ne fait plus l'arbre : un agent de $.agent.list absent de who@2 n'est pas montré", async ($, on) => {
  labSignal(on, { stdout: avec(s => { s.equipe.workers = [] }), agents: AGENTS as any })
  const ui = await pane($)
  expect(await ui.find({ type: 'Text', text: /plan 68-07/ })).toBeUndefined()
  expect(await ui.find({ key: 'stop:c1' })).toBeUndefined()
  await ui.unmount()
})

test("Q2 — un agent terminé est écrit « terminé » en dock, absent en compact", async ($, on) => {
  labSignal(on, { stdout: STDOUT, agents: AGENTS as any })
  const dock = await pane($)
  // replié derrière « 1 terminé » (P68-D-35, R3) ; déplié, il est écrit « terminé »
  expect(await dock.find({ type: 'Text', text: /revue finie/ })).toBeUndefined()
  await dock.press({ key: 'finis' })
  expect(await dock.find({ type: 'Text', text: /revue finie/ })).toBeDefined()
  expect(await dock.find({ type: 'Text', text: /terminé/ })).toBeDefined()
  await dock.unmount()
  const compact = await pane($, COMPACT)
  expect(await compact.find({ type: 'Text', text: /revue finie/ })).toBeUndefined()
  expect(await compact.find({ type: 'Text', text: /plan autre-session/ })).toBeDefined()
  await compact.unmount()
})

test("Q3 — un enfant est écrit sous son parent, en retrait ; un parent absent laisse l'enfant à la racine", async ($, on) => {
  labSignal(on, { stdout: avec(s => { s.equipe.workers = [...WORKERS, w({ kind: 'subagent', id: 'e5', parent: 'disparu', role: 'vf-reviewer', task: 'parent disparu' })] }) })
  const ui = await pane($)
  expect(await ui.find({ type: 'Text', text: /↳ .* vf-coder/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /↳ .* vf-dev-manager/ })).toBeUndefined()
  expect(await ui.find({ type: 'Text', text: /↳ .* vf-reviewer/ })).toBeUndefined()
  await ui.unmount()
})
