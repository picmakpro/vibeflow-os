import { expect, test } from 'claude-code/testing'

import { SIGNAL, avec, labSignal } from './fixture-signal'

// Appel de l'émetteur signal@1 par la pane (68-05 ; P68-D-02, P68-D-14). Sous `claude plugin test`, process.run
// n'atteint jamais la machine : on prouve l'argv, le cwd et l'analyse du stdout. Identifiant du témoin en tête de titre.

const PANE = {
  plugin: 'vibeflow',
  component: 'Pane',
  requestId: 'vf-signal',
  props: { title: 'vf-signal', isFocused: false, bodyColumns: 60, placement: 'dock', scroll: { offset: 0, bodyRows: 40 }, view: {} },
} as const

async function pane($: any, surface: 'terminal' | 'desktop' = 'terminal') {
  await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })
  return $.ui.mount({ ...PANE, surface })
}

test("K1 — argv de l'émetteur : node, le script du plugin, la racine de session ; cwd = racine du plugin", async ($, on) => {
  const lab = labSignal(on)
  const ui = await pane($)
  expect(lab.emetteur().length).toBeGreaterThan(0)
  const a = lab.emetteur()[0]!
  expect(a.argv).toEqual(['node', `${$.plugin.root}/cockpit/scripts/vf-cockpit-signal.mjs`, '/lab'])
  expect(a.cwd).toBe($.plugin.root)
  expect(a.timeoutMs).toBe(15000)
  await ui.unmount()
})

test('K2 — node absent du PATH (ENOENT) : la pane se dessine et le dit', async ($, on) => {
  labSignal(on, { rejet: { code: 'ENOENT', message: 'spawn node ENOENT' } })
  const ui = await pane($)
  expect(await ui.find({ type: 'Text', text: /node introuvable dans le PATH/ })).toBeDefined()
  await ui.unmount()
})

test('K3 — stdout tronqué : « sortie de l’émetteur tronquée », rien d’affiché à moitié', async ($, on) => {
  labSignal(on, { tronque: true, stdout: JSON.stringify(SIGNAL).slice(0, 200) })
  const ui = await pane($)
  expect(await ui.find({ type: 'Text', text: /sortie de l'émetteur tronquée/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /Embarquer le mod/ })).toBeUndefined()
  await ui.unmount()
})

test("K4 — stdout illisible : « sortie de l'émetteur illisible »", async ($, on) => {
  labSignal(on, { stdout: '{pas du json' })
  const ui = await pane($)
  expect(await ui.find({ type: 'Text', text: /sortie de l'émetteur illisible/ })).toBeDefined()
  await ui.unmount()
})

test("K5 — schéma inattendu : dit, avec la valeur bornée", async ($, on) => {
  labSignal(on, { stdout: avec(s => { s.schema = 'vibeflow/cockpit-signal@9' }) })
  const ui = await pane($)
  expect(await ui.find({ type: 'Text', text: /schéma inattendu : vibeflow\/cockpit-signal@9/ })).toBeDefined()
  await ui.unmount()
})

test("K6 — l'en-tête montre la phase active de l'arbre courant et son libellé d'avancement, jamais celle du STATE", async ($, on) => {
  labSignal(on)
  const ui = await pane($)
  expect(await ui.find({ type: 'Text', text: /phase 68 Embarquer le mod \(en cours\)/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /Bundle produit/ })).toBeUndefined()
  await ui.unmount()
})

test("K9 — code de sortie non nul : « émetteur en échec (code 1) »", async ($, on) => {
  labSignal(on, { exitCode: 1, stdout: '' })
  const ui = await pane($)
  expect(await ui.find({ type: 'Text', text: /émetteur en échec \(code 1\)/ })).toBeDefined()
  await ui.unmount()
})

test("K13 — rejet sans ENOENT (délai) : « émetteur sans réponse (délai dépassé) »", async ($, on) => {
  labSignal(on, { rejet: { message: 'process.run timed out after 15000 ms' } })
  const ui = await pane($)
  expect(await ui.find({ type: 'Text', text: /émetteur sans réponse \(délai dépassé\)/ })).toBeDefined()
  await ui.unmount()
})

test("K14 — deux rafraîchissements simultanés n'ouvrent qu'un seul processus (appel unique en vol)", async ($, on) => {
  const lab = labSignal(on, { delaiMs: 60 })
  const ui = await pane($)
  const avant = lab.emetteur().length
  await Promise.all([ui.press({ key: 'rafraichir' }), ui.press({ key: 'rafraichir' })])
  expect(lab.emetteur().length - avant).toBe(1)
  await ui.unmount()
})
