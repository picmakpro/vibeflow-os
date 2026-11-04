import { expect, test } from 'claude-code/testing'

import { SIGNAL_PLAT } from './fixture-plat'
import { avec } from './fixture-signal'
import { BAND, labFix, monter } from './lab-fix'

// Correction ciblée RV-1 et RV-3 (68-FIX-MOD, passe 2 ; P68-PL-05) : le mod accepte ce que l'émetteur réel garantit
// (`scope` et `retard.base` peuvent valoir null) et le dit sans lever ; U+2028 et U+2029 ne passent pas. Identifiants FX-.

const ILLISIBLE = /sortie de l'émetteur illisible/

test("FX-7a — sortie réelle d'un lab plat (verrou tenu, scope null, retard.base null) : la pane la montre, rien d'illisible", async ($, on) => {
  labFix(on).emetteur.stdout = SIGNAL_PLAT
  const ui = await monter($)
  expect(await ui.find({ type: 'Text', text: ILLISIBLE })).toBeUndefined()
  expect(await ui.find({ type: 'Text', text: /phase 1 Un/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /sans portée/ })).toBeDefined()
  await ui.press({ key: 'onglet:equipe' })
  await ui.press({ key: 'onglet:macro' })
  await ui.press({ key: 'onglet:mission' })
  expect(await ui.find({ type: 'Text', text: ILLISIBLE })).toBeUndefined()
  await ui.unmount()
})

test("FX-7b — sortie réelle d'un lab plat : le bandeau, le compact et le brief ne lèvent pas", async ($, on) => {
  labFix(on).emetteur.stdout = SIGNAL_PLAT
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })
  const band = await monter($, BAND)
  await band.unmount()
  await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })
  const compact = await $.ui.mount({ plugin: 'vibeflow', component: 'Pane', requestId: 'vf-signal', props: { title: 'vf-signal', isFocused: false, bodyColumns: 60, placement: 'inline', scroll: { offset: 0, bodyRows: 40 }, view: {} }, surface: 'terminal' })
  expect(await compact.find({ type: 'Text', text: /phase 1 Un/ })).toBeDefined()
  await compact.unmount()
  const brief = String((await $.command.run({ command: 'vf-signal', args: 'brief' })).text)
  expect(brief).toMatch(/phase 1 · Un/)
  expect(brief).toContain('verrou dépôt : t · sans portée')
  expect(brief).not.toMatch(/null/)
})

test('FX-7c — verrou plat sans portée (scope null) seul : accepté et affiché', async ($, on) => {
  labFix(on).emetteur.stdout = avec((s: any) => { s.verrous.liste[0].scope = null })
  const ui = await monter($)
  expect(await ui.find({ type: 'Text', text: ILLISIBLE })).toBeUndefined()
  expect(await ui.find({ type: 'Text', text: /mgr68/ })).toBeDefined()
  await ui.unmount()
})

test("FX-7d — retard.base null seul (ni origin/HEAD ni main) : accepté, aucun retard inventé", async ($, on) => {
  labFix(on).emetteur.stdout = avec((s: any) => { Object.assign(s.arbres.find((a: any) => a.courant).retard, { base: null, main: null, origin: null }) })
  const ui = await monter($)
  expect(await ui.find({ type: 'Text', text: ILLISIBLE })).toBeUndefined()
  expect(await ui.find({ type: 'Text', text: /phase 68 Embarquer le mod/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /en retard/ })).toBeUndefined()
  await ui.unmount()
})

test("FX-7e — un scope ou une base d'un autre type que chaîne/null reste illisible (la tolérance est bornée)", async ($, on) => {
  labFix(on).emetteur.stdout = avec((s: any) => { s.verrous.liste[0].scope = 7 })
  const ui = await monter($)
  expect(await ui.find({ type: 'Text', text: ILLISIBLE })).toBeDefined()
  await ui.unmount()
})

test('FX-8a — U+2028 et U+2029 dans une chaîne affichée (brief) : remplacés, aucune ligne forgée', async ($, on) => {
  labFix(on).emetteur.stdout = avec((s: any) => { s.projet = 'avant\u2028- faux\u2029apres' })
  await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })
  const texte = String((await $.command.run({ command: 'vf-signal', args: 'brief' })).text)
  expect(texte).toContain('- projet : avant - faux apres')
  expect(texte).not.toMatch(/[\u2028\u2029]/)
})
