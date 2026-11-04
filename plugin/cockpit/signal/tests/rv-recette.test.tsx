import { expect, test } from 'claude-code/testing'
import type { On } from 'claude-code'

import { avec, labSignal } from './fixture-signal'

// Écarts de recette N1, N2, N3, N8 (68-FIX-RV-MOD ; P68-D-38, arbitrage Samuel « Tout selon les recos (Recommandé) », AskUserQuestion,
// session principale Claude Code, 2026-11-04, relayé par le manager). Identifiants RV-N… (lus par verdict.sh).

const SOMBRE = { active: '#f0c36b', blocked: '#f28b8b' }
const PANE = {
  plugin: 'vibeflow', component: 'Pane', requestId: 'vf-signal',
  props: { title: 'vf-signal', isFocused: false, bodyColumns: 80, placement: 'dock', scroll: { offset: 0, bodyRows: 40 }, view: {} },
} as const
const COMPACT = { ...PANE, props: { ...PANE.props, placement: 'inline' } } as const
const BAND = {
  plugin: 'vibeflow', component: 'AbovePrompt', requestId: 'band',
  props: { hasSurvey: false, isWorking: false, maxRows: 4, bodyColumns: 80, scroll: { offset: 0, bodyRows: 4 }, view: {} },
} as const

async function monte($: any, on: On, stdout: string, comp: any = PANE, equipe = false) {
  labSignal(on, { stdout })
  on('ui.render', ($, e) => { const { Text } = $.ui.resolve(e); return <Text>engine</Text> })
  await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })
  const ui = await $.ui.mount({ ...comp, surface: 'terminal' })
  if (equipe) await ui.press({ key: 'onglet:equipe' })
  return ui
}
const w = (o: Record<string, unknown>) => ({ source: 'sessions', tree: 'arbre principal', etat: 'actif', ageS: 30, ...o })
const couleurs = async (ui: any, re: RegExp): Promise<unknown[]> => {
  const found = await ui.findAll({ type: 'Text', text: re })
  expect(found.length).toBeGreaterThan(0)
  return found.map((f: any) => f.props.color)
}

test("RV-N1 — un âge négatif (horloge décalée) est borné à 0 : jamais « -4 s »", async ($, on) => {
  const ui = await monte($, on, avec(s => { s.equipe.workers = [w({ kind: 'subagent', id: 'c1', role: 'vf-coder', task: 'plan', branch: 'main', ageS: -4 })] }), PANE, true)
  expect(await ui.find({ type: 'Text', text: /-\d+ s/ })).toBeUndefined()
  expect(await ui.find({ type: 'Text', text: /main · 0 s/ })).toBeDefined()
  await ui.unmount()
})

const VERROU_DEPOT = { ws: '', scope: 'depot', phase: null, tenu: true, stale: false, ageS: 15, ttl: 1800, progressAgeS: 0, owner: 'juge-q3' }

test("RV-N2a — verrou de dépôt : « dépôt » une seule fois, en français, la portée brute « depot » n'est pas écrite", async ($, on) => {
  const ui = await monte($, on, avec(s => { s.verrous.liste = [VERROU_DEPOT] }))
  expect(await ui.find({ type: 'Text', text: /^■ dépôt · juge-q3 · 15 s$/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /depot/ })).toBeUndefined()
  await ui.unmount()
})

test("RV-N2b — l'étape du verrou (travailleur « lock » du même propriétaire) est écrite quand elle existe", async ($, on) => {
  const ui = await monte($, on, avec(s => {
    s.verrous.liste = [VERROU_DEPOT]
    s.equipe.workers = [w({ kind: 'lock', id: 'juge-q3', task: 'revue-q3', source: 'driver-lock' })]
  }))
  expect(await ui.find({ type: 'Text', text: /^■ dépôt · juge-q3 · revue-q3 · 15 s$/ })).toBeDefined()
  await ui.unmount()
})

test("RV-N3 — vue Équipe : « verrou », « nœud », « exécution » ; aucun lock, dag-node ni exec", async ($, on) => {
  const ui = await monte($, on, avec(s => {
    s.equipe.workers = [
      w({ kind: 'lock', id: 'juge-q3', task: 'revue', source: 'driver-lock' }),
      w({ kind: 'dag-node', id: 'n1', role: 'exec', task: 'étape un', source: 'dag' }),
    ]
  }), PANE, true)
  expect(await ui.find({ type: 'Text', text: /verrou · revue/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /exécution · étape un/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /\b(lock|dag-node|exec)\b/ })).toBeUndefined()
  await ui.unmount()
})

const bloque = avec(s => { s.missions[0].etat = 'running'; s.missions[0].noeuds[1].status = 'blocked' })

test("RV-N8a — « toi · nœud bloqué » prend st-blocked (sev-high), pas st-active, en dock et en compact", async ($, on) => {
  const ui = await monte($, on, bloque)
  expect(await couleurs(ui, /toi · nœud bloqué/)).toEqual([SOMBRE.blocked])
  await ui.unmount()
  const compact = await $.ui.mount({ ...COMPACT, surface: 'terminal' })
  expect(await couleurs(compact, /toi · nœud bloqué/)).toEqual([SOMBRE.blocked])
  await compact.unmount()
})

test("RV-N8b — témoin : une autre attention (verrou périmé) garde st-active", async ($, on) => {
  const ui = await monte($, on, avec(s => { s.verrous.liste[0].stale = true }))
  expect(await couleurs(ui, /toi · verrou périmé/)).toEqual([SOMBRE.active])
  await ui.unmount()
})

test("RV-N8c — bandeau : la marque ■ d'un nœud bloqué prend st-blocked", async ($, on) => {
  const ui = await monte($, on, bloque, BAND)
  expect(await couleurs(ui, /^■ $/)).toEqual([SOMBRE.blocked])
  await ui.unmount()
})
