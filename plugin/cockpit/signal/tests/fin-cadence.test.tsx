import { expect, mock, test } from 'claude-code/testing'
import type { On } from 'claude-code'

import { SIGNAL } from './fixture-signal'

// Correction finale AD-1 (68-FIX-FIN ; P68-D-41, arbitrage Samuel « Rafraîchir si pane ouverte (Recommandé) », AskUserQuestion,
// session principale Claude Code, 2026-11-04) : le rafraîchissement continu (minuteur de 10 s) ne tourne que pane ouverte ET session
// interactive ; sinon un rafraîchissement après un tour, au plus une fois par minute ; session.start n'attend JAMAIS l'émetteur ;
// les gestes explicites (/vf-signal, brief) rafraîchissent aussitôt. Identifiants FIN-1* (verdict.sh lit le début du titre).

const PANE_ID = 'vf-signal'
type Opts = { ouverte?: boolean; retenir?: boolean; periodes?: number[]; temps?: { v: number } }
type Lab = { emetteur: () => number; ouverte: { v: boolean }; liberer: () => void; clk: ReturnType<typeof mock.clock> }

function lab(on: On, o: Opts = {}): Lab {
  const ouverte = { v: o.ouverte ?? false }
  let appels = 0
  let porte: (() => void) | null = null
  const attente = o.retenir ? new Promise<void>(r => (porte = r)) : null
  // avec `periodes`, une horloge à espion (chaque `clock.every` est noté, aucun ne tourne) ; sinon l'horloge simulée, qui avance
  const clk = o.periodes || o.temps ? (undefined as unknown as ReturnType<typeof mock.clock>) : mock.clock(on, { now: 1_000_000 })
  if (o.periodes || o.temps) {
    on('clock.now', () => ({ value: o.temps?.v ?? 1_000_000 }))
    on('clock.every', (_, e) => {
      o.periodes?.push(e.ms)
      return { value: undefined }
    })
  }
  mock.env(on, { HOME: '/home/user' })
  on('command.register', () => ({ value: { command: PANE_ID } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('ui.panes', () => ({ value: ouverte.v ? [{ id: PANE_ID, title: PANE_ID, isShown: true, isFocused: false, isPlaced: true }] : [] }))
  on('ui.status', () => ({ value: undefined }))
  on('ui.toast', () => ({ value: undefined }))
  on('ui.invalidate', () => ({ value: undefined }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('session.root', () => ({ value: '/lab' }))
  on('agent.list', () => ({ value: [] }))
  on('session.usage', () => ({ value: { startedAt: 0, context: { window: 200000, tokens: 1, percent: 1 }, rateLimits: [], cost: { usd: 0 } } }))
  on('fs.stat', (_, e) => ({ value: { kind: 'file', size: 1, mtimeMs: 0, isLink: false, realPath: String(e.path) } }))
  on('fs.exists', () => ({ value: false }))
  on('fs.read', (_, e) => {
    if (String(e.path).endsWith('.vibeflow-installed')) return { value: 'cockpit=v1.2.0\n' }
    throw new Error('ENOENT')
  })
  on('fs.list', () => ({ value: [] }))
  on('process.run', async (_, e) => {
    if ((e.argv as readonly string[])[0] === 'node') {
      appels++
      if (attente) await attente
    }
    return { value: { exitCode: 0, stdout: JSON.stringify(SIGNAL), stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
  })
  on('session.end', () => ({ sessionId: 's1' }))
  on('tool.call', () => ({ result: {} }))
  on('turn.start', () => ({ turnId: 't1' }))
  on('turn.complete', () => ({ text: '' }))
  return { emetteur: () => appels, ouverte, liberer: () => porte?.(), clk }
}

const demarrer = ($: any, interactif = true) => $.session.start({ cwd: '/lab', surface: interactif ? 'terminal' : null, isInteractive: interactif })
const tour = async ($: any) => {
  await $.turn.start({ text: 'x', turnId: 't1' })
  await $.turn.complete({ answer: '', durationMs: 1000, isAborted: false, turnId: 't1', reason: 'end_turn' })
}
const laisser = (ms = 150) => new Promise(r => setTimeout(r, ms))

test("FIN-1a — session.start rend la main sans attendre process.run de l'émetteur (premier rafraîchissement en arrière-plan)", async ($, on) => {
  const l = lab(on, { retenir: true })
  const course = await Promise.race([demarrer($).then(() => 'rendu'), laisser(3000).then(() => 'attendu')])
  l.liberer()
  await laisser()
  expect(course).toBe('rendu')
  expect(l.emetteur()).toBe(1) // témoin positif : l'émetteur est bel et bien lancé, derrière
})

test("FIN-1b — pane fermée : trois tours en moins d'une minute ne lancent l'émetteur qu'une fois", async ($, on) => {
  const l = lab(on)
  await demarrer($)
  await laisser()
  for (let i = 0; i < 3; i++) await tour($)
  await laisser()
  expect(l.emetteur()).toBe(1)
})

test("FIN-1b2 — pane fermée : une minute plus tard, un tour relance l'émetteur (la limite n'est pas un arrêt)", async ($, on) => {
  const l = lab(on)
  await demarrer($)
  await laisser()
  await tour($)
  await l.clk.advance(61000)
  await tour($)
  await laisser()
  expect(l.emetteur()).toBe(2)
})

test("FIN-1b3 — pane ouverte et session interactive : chaque tour rafraîchit aussitôt", async ($, on) => {
  const l = lab(on, { ouverte: true })
  await demarrer($)
  await laisser()
  for (let i = 0; i < 3; i++) await tour($)
  await laisser()
  expect(l.emetteur()).toBe(4)
})

test("FIN-1c — pane ouverte et session interactive : le minuteur de 10 s rafraîchit", async ($, on) => {
  const l = lab(on, { ouverte: true })
  await demarrer($)
  await laisser()
  const avant = l.emetteur()
  await l.clk.advance(10000)
  await laisser()
  expect(l.emetteur()).toBeGreaterThan(avant)
})

test("FIN-1c2 — pane fermée : le minuteur ne lance pas l'émetteur", async ($, on) => {
  const l = lab(on)
  await demarrer($)
  await laisser()
  const avant = l.emetteur()
  await l.clk.advance(30000)
  await laisser()
  expect(l.emetteur()).toBe(avant)
})

test("FIN-1d — session non interactive : aucun minuteur, même si la pane se dit ouverte", async ($, on) => {
  const l = lab(on, { ouverte: true })
  await demarrer($, false)
  await laisser()
  const avant = l.emetteur()
  await l.clk.advance(30000)
  await laisser()
  expect(l.emetteur()).toBe(avant)
})

test("FIN-1e — geste explicite : /vf-signal brief et /vf-signal rafraîchissent aussitôt, pane fermée et dans la minute", async ($, on) => {
  const l = lab(on)
  await demarrer($)
  await laisser()
  await tour($)
  const avant = l.emetteur()
  await $.command.run({ command: 'vf-signal', args: 'brief' })
  expect(l.emetteur()).toBe(avant + 1)
  await $.command.run({ command: 'vf-signal', args: '' })
  expect(l.emetteur()).toBe(avant + 2)
})

test("FIN-1d2 — aucune minuterie de 10 s en session non interactive ; une seule en session interactive", async ($, on) => {
  const non: number[] = []
  lab(on, { periodes: non, ouverte: true })
  await demarrer($, false)
  expect(non.filter(ms => ms === 10000)).toEqual([])
})

test("FIN-1d3 — témoin positif de l'espion : en session interactive, la minuterie de 10 s est bien posée (une fois)", async ($, on) => {
  const oui: number[] = []
  lab(on, { periodes: oui })
  await demarrer($)
  expect(oui.filter(ms => ms === 10000)).toEqual([10000])
})

// --- FND-1, FND-3, FND-4 (68-FIX-FND ; P68-D-41) : la propriété centrale « pane fermée, au plus un lancement automatique par minute,
// tours, /clear et Bash combinés » pour TOUTE la durée de la session, pas seulement la première minute. ---

test("FND-1a — pane fermée : après un lancement à t ≥ 61 s, un tour 5 s plus tard ne relance pas", async ($, on) => {
  const l = lab(on)
  await demarrer($)
  await laisser()
  await l.clk.advance(61000)
  await tour($)
  await laisser()
  expect(l.emetteur()).toBe(2) // témoin positif : le tour de t+61 s a bien lancé
  await l.clk.advance(5000)
  await tour($)
  await laisser()
  expect(l.emetteur()).toBe(2)
})

test("FND-1b — pane fermée : un /clear suivi d'un tour dans la minute ne donne qu'un seul lancement", async ($, on) => {
  const l = lab(on)
  await demarrer($)
  await laisser()
  await l.clk.advance(61000)
  await $.session.end({ reason: 'clear' })
  await laisser()
  expect(l.emetteur()).toBe(2) // témoin positif : le /clear a lancé
  await l.clk.advance(5000)
  await tour($)
  await laisser()
  expect(l.emetteur()).toBe(2)
  await $.session.end({ reason: 'clear' }) // et un second /clear dans la minute ne relance pas non plus
  await laisser()
  expect(l.emetteur()).toBe(2)
})

test("FND-1c — appel Bash qualifiant (git commit, gsd) : rien pane fermée, un lancement pane ouverte", async ($, on) => {
  const l = lab(on)
  await demarrer($)
  await laisser()
  const avant = l.emetteur()
  await $.tool.call({ tool: 'Bash', tool_use_id: 'u1', command: 'git commit -m x' })
  await $.tool.call({ tool: 'Bash', tool_use_id: 'u2', command: 'gsd-tools roadmap analyze' })
  await laisser()
  expect(l.emetteur()).toBe(avant)
  l.ouverte.v = true
  await $.tool.call({ tool: 'Bash', tool_use_id: 'u3', command: 'git commit -m y' })
  await laisser()
  expect(l.emetteur()).toBe(avant + 1) // témoin positif : pane ouverte, le même geste lance
})

test("FND-3 — l'horloge recule : une différence négative est une minute échue, le tour relance", async ($, on) => {
  const temps = { v: 1_000_000 }
  const l = lab(on, { temps })
  await demarrer($)
  await laisser()
  expect(l.emetteur()).toBe(1)
  temps.v = 500_000
  await tour($)
  await laisser()
  expect(l.emetteur()).toBe(2)
})

test("FND-4 — deux session.start : un seul minuteur de 10 s reste actif (le premier est annulé)", async ($, on) => {
  const l = lab(on, { ouverte: true })
  await demarrer($)
  await demarrer($)
  await laisser()
  const avant = l.emetteur()
  await l.clk.advance(10000)
  await laisser()
  expect(l.emetteur()).toBe(avant + 1)
})
