import { expect, test } from 'claude-code/testing'

import { SIGNAL, avec } from './fixture-signal'
import { labFix, laisser, monter } from './lab-fix'

// Correction ciblée ST-5 et ST-6 (68-FIX-MOD ; P68-D-02, P68-D-14) : un signal incomplet est « illisible », un échec qui
// n'est pas un délai ne se dit pas « délai dépassé », et une lecture ratée après une réussie n'affiche plus l'ancienne
// donnée. Identifiants préfixés FX-.

const INCOMPLETS: [string, (s: any) => void][] = [
  ['sans verrous.liste', s => { delete s.verrous.liste }],
  ['sans jalons', s => { delete s.jalons }],
  ['sans layout', s => { delete s.layout }],
  ['sans equipe', s => { delete s.equipe }],
  ['avec un n numérique', s => { s.phases[0].n = 68 }],
  ['sans avancement.plans', s => { delete s.phases[0].avancement.plans }],
  ['avec un arbre sans label', s => { delete s.arbres[0].label }],
]
for (const [i, [dit, mute]] of INCOMPLETS.entries()) {
  test(`FX-5a${i} — signal au bon schéma mais ${dit} : « sortie de l'émetteur illisible », le rendu ne lève pas`, async ($, on) => {
    labFix(on).emetteur.stdout = avec(mute)
    const ui = await monter($)
    expect(await ui.find({ type: 'Text', text: /sortie de l'émetteur illisible/ })).toBeDefined()
    await ui.unmount()
  })
}

test("FX-5b — émetteur : un rejet EACCES n'est pas un délai dépassé", async ($, on) => {
  labFix(on).emetteur.rejet = 'EACCES: spawn node EACCES'
  const ui = await monter($)
  expect(await ui.find({ type: 'Text', text: /émetteur non lancé \(EACCES/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /délai dépassé/ })).toBeUndefined()
  await ui.unmount()
})

test("FX-5c — lanceur : un rejet EACCES n'est pas un délai dépassé", async ($, on) => {
  labFix(on).lanceur.rejet = 'EACCES: spawn node EACCES'
  const ui = await monter($)
  await ui.press({ key: 'ouvrir-cockpit' })
  expect(await ui.find({ type: 'Text', text: /lanceur non lancé \(EACCES/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /délai dépassé/ })).toBeUndefined()
  await ui.unmount()
})

test("FX-6a — lanceur : un vrai délai (timed out) se dit « lanceur sans réponse (délai dépassé) »", async ($, on) => {
  labFix(on).lanceur.rejet = 'process.run timed out after 60000 ms'
  const ui = await monter($)
  await ui.press({ key: 'ouvrir-cockpit' })
  expect(await ui.find({ type: 'Text', text: /lanceur sans réponse \(délai dépassé\)/ })).toBeDefined()
  await ui.unmount()
})

test("FX-6b — lecture réussie puis ratée : l'ancienne donnée n'est plus affichée comme fraîche, l'échec est dit", async ($, on) => {
  const lab = labFix(on)
  const ui = await monter($)
  expect(await ui.find({ type: 'Text', text: /phase 68 Embarquer le mod/ })).toBeDefined()
  lab.emetteur = { exitCode: 1, stdout: '' }
  await ui.press({ key: 'rafraichir' })
  await laisser()
  expect(await ui.find({ type: 'Text', text: /émetteur en échec \(code 1\)/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /phase 68 Embarquer le mod/ })).toBeUndefined()
  expect(await ui.find({ type: 'Text', text: /Jalon d essai/ })).toBeUndefined()
  lab.emetteur = { stdout: JSON.stringify(SIGNAL) }
  await ui.press({ key: 'rafraichir' })
  await laisser()
  expect(await ui.find({ type: 'Text', text: /phase 68 Embarquer le mod/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /émetteur en échec/ })).toBeUndefined()
  await ui.unmount()
})
