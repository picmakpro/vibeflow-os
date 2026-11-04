import { expect, test } from 'claude-code/testing'
import type { On } from 'claude-code'

import { avec, labSignal } from './fixture-signal'

// Correction ciblée du lot B (P68-D-35 : arbitrage Samuel, AskUserQuestion session principale, 2026-11-04) : R1, R4, R6, R9,
// R10, R11 de la recette de la Phase 68. Préfixe MB- (verdict.sh refuse un identifiant en double).

const SOMBRE = { active: '#f0c36b', todo: '#5c5c5c', blocked: '#f28b8b' }
const PANE = {
  plugin: 'vibeflow', component: 'Pane', requestId: 'vf-signal',
  props: { title: 'vf-signal', isFocused: false, bodyColumns: 80, placement: 'dock', scroll: { offset: 0, bodyRows: 40 }, view: {} },
} as const
const COMPACT = { ...PANE, props: { ...PANE.props, placement: 'inline' } } as const
const BAND = {
  plugin: 'vibeflow', component: 'AbovePrompt', requestId: 'band',
  props: { hasSurvey: false, isWorking: false, maxRows: 4, bodyColumns: 80, scroll: { offset: 0, bodyRows: 4 }, view: {} },
} as const

async function monte($: any, on: On, stdout: string, comp: any = PANE) {
  labSignal(on, { stdout })
  on('ui.render', ($, e) => { const { Text } = $.ui.resolve(e); return <Text>engine</Text> })
  await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })
  return $.ui.mount({ ...comp, surface: 'terminal' })
}
const texte = async (ui: any, re: RegExp): Promise<string[]> => (await ui.findAll({ type: 'Text', text: re })).map((f: any) => String(f.props.children ?? f.text ?? ''))
const couleurs = async (ui: any, re: RegExp): Promise<unknown[]> => {
  const found = await ui.findAll({ type: 'Text', text: re })
  expect(found.length).toBeGreaterThan(0)
  return found.map((f: any) => f.props.color)
}
const brief = async ($: any) => String((await $.command.run({ command: 'vf-signal', args: 'brief' })).text)

// R1 : le libellé ET la couleur d'une ligne de worktree viennent de l'état du worktree, jamais du ROADMAP de l'arbre courant.
const R1 = avec(s => {
  s.phases[1].libelle = 'à faire'
  s.phases[1].avancement.etat = 'a-faire'
})

test("MB-R1a — worktree « à recetter » sous un arbre courant où la phase est « à faire » : « à recetter », couleur de « à recetter »", async ($, on) => {
  const ui = await monte($, on, R1)
  expect((await texte(ui, /\(à recetter\)/)).length).toBeGreaterThan(0)
  expect(await texte(ui, /\(à faire\)/)).toEqual([])
  expect((await couleurs(ui, /^\(à recetter\)$/)).every(c => c === SOMBRE.active)).toBe(true)
  await ui.unmount()
})

test("MB-R1b — état « à faire » du worktree : libellé « à faire », grisé ; état inconnu : aucune parenthèse inventée", async ($, on) => {
  const ui = await monte($, on, avec(s => { s.arbres[0].phaseActive.etat = 'a-faire'; s.arbres[2].phaseActive = { key: 'fiabilite|70', n: '70', nom: 'X', etat: 'zzz' } }))
  expect((await couleurs(ui, /^\(à faire\)$/)).every(c => c === SOMBRE.todo)).toBe(true)
  expect(await texte(ui, /\(zzz\)/)).toEqual([])
  await ui.unmount()
})

// R4 : sans node, le brief dit la cause que la pane affiche.
test("MB-R4a — process.run rejeté en ENOENT : le brief dit « node introuvable dans le PATH »", async ($, on) => {
  labSignal(on, { rejet: { code: 'ENOENT', message: 'spawn node ENOENT' } })
  await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })
  expect(await brief($)).toContain('node introuvable dans le PATH')
})

test("MB-R4b — émetteur qui répond : le brief ne porte aucune erreur du socle", async ($, on) => {
  labSignal(on)
  await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })
  const b = await brief($)
  expect(b).not.toContain('introuvable')
  expect(b).toContain('projet : Lab d essai')
})

// R6 : la clé du jalon, puis son titre court sans markdown, sur une ligne, sans couper un mot.
const JALON = { key: 'vibeflow-v2.0', icone: '🚧', texte: '« le cockpit VibeFlow » — Phases 67-72 — **inscrit le 2026-11-01**, release `v2.76.0`, un très long complément qui ne tient pas', ws: 'fiabilite', phases: ['fiabilite|68', 'fiabilite|69'] }

test("MB-R6a — en-tête et brief : « jalon <clé> · <titre court> », sans ** ni backtick, une ligne", async ($, on) => {
  const ui = await monte($, on, avec(s => { s.jalons = [JALON] }))
  const lignes = await texte(ui, /^jalon vibeflow-v2\.0 · /)
  expect(lignes.length).toBe(1)
  expect(lignes[0]).toBe('jalon vibeflow-v2.0 · « le cockpit VibeFlow »')
  await ui.unmount()
  const b = await brief($)
  expect(b).toContain('jalon : vibeflow-v2.0 · « le cockpit VibeFlow »')
  expect(b).toContain('- jalon vibeflow-v2.0 · « le cockpit VibeFlow » : 0/2 phases')
  expect(b).not.toMatch(/\*\*|`/)
})

test("MB-R6b — titre sans tiret et trop long : coupé entre deux mots, jamais au milieu", async ($, on) => {
  const long = 'Consolidation des gardes de la gouvernance transverses du dépôt'
  const ui = await monte($, on, avec(s => { s.jalons = [{ ...JALON, texte: long }] }))
  const [l] = await texte(ui, /^jalon vibeflow-v2\.0 · /)
  const titre = l!.slice('jalon vibeflow-v2.0 · '.length).replace(/…$/, '')
  expect(l!.endsWith('…')).toBe(true)
  expect(long.startsWith(titre.trimEnd())).toBe(true)
  expect(long[titre.trimEnd().length]).toBe(' ')
  await ui.unmount()
})

// R9 : un worktree hors du dépôt dit le nom de son dossier.
test("MB-R9 — worktree hors du dépôt : le nom du dossier, jamais ../../..", async ($, on) => {
  const ui = await monte($, on, avec(s => { s.arbres[2].label = '../../../../outside/phase-71/'; s.arbres[0].label = '/srv/wt/autre' }))
  expect((await texte(ui, /· feat\/libre/)).join('|')).toMatch(/phase-71 · feat\/libre/)
  expect((await texte(ui, /\.\.\//)).length).toBe(0)
  expect((await texte(ui, /^. autre · main/)).length).toBeGreaterThan(0)
  expect((await texte(ui, /\.claude\/worktrees\/phase-68/)).length).toBeGreaterThan(0)
  await ui.unmount()
})

// R10 : la forme compacte garde le mot « toi ».
test("MB-R10 — pane compacte : « ■ toi · <action> »", async ($, on) => {
  const ui = await monte($, on, avec(s => { s.verrous.liste[0].stale = true }), COMPACT)
  expect((await texte(ui, /■ toi · verrou périmé de mgr68/)).length).toBeGreaterThan(0)
  await ui.unmount()
})

// R11 : les statuts de nœud sont dits en français ; la couleur reste celle des tokens.
const vivante = (status: string) => avec(s => { s.missions[0].etat = 'running'; s.missions[0].noeuds[1].status = status })

test("MB-R11a — nœud blocked : « nœud bloqué » dans le bandeau et dans la ligne « toi », jamais « blocked »", async ($, on) => {
  const band = await monte($, on, vivante('blocked'), BAND)
  expect((await texte(band, /nœud bloqué · exécution/)).length).toBe(1)
  expect(await texte(band, /blocked/)).toEqual([])
  await band.unmount()
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect((await texte(ui, /toi · nœud bloqué · exécution/)).length).toBe(1)
  expect(await texte(ui, /blocked/)).toEqual([])
  await ui.unmount()
})

for (const [en, fr] of [['failed', 'en échec'], ['error', 'en erreur'], ['red', 'rouge']] as const) {
  test(`MB-R11b-${en} — nœud ${en} : « nœud ${fr} » au bandeau`, async ($, on) => {
    const b = await monte($, on, vivante(en), BAND)
    expect((await texte(b, new RegExp(`nœud ${fr} · exécution`))).length).toBe(1)
    await b.unmount()
  })
}

// Passe 2 de R6 : la vue macro dit les jalons comme l'en-tête et le brief.
test("MB-R6c — vue macro : jalon courant et jalons ouverts en « <clé> · <titre court> », sans markdown", async ($, on) => {
  const autre = { key: 'autre-v1', icone: '🚧', texte: '**Gouvernance** — `Phases 40-50` — suite', ws: 'fiabilite', phases: ['fiabilite|70'] }
  const ui = await monte($, on, avec(s => { s.jalons = [JALON, autre] }))
  await ui.press({ key: 'onglet:macro' })
  expect((await texte(ui, /^■ vibeflow-v2\.0 · « le cockpit VibeFlow » · 0\/2 phases$/)).length).toBe(1)
  expect((await texte(ui, /^· autre-v1 · Gouvernance · 0\/1$/)).length).toBe(1)
  expect(await texte(ui, /\*\*|`/)).toEqual([])
  await ui.unmount()
})
