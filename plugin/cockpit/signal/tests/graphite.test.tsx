import { expect, test } from 'claude-code/testing'
import type { On } from 'claude-code'

import { avec, labSignal } from './fixture-signal'

// La direction « Graphite » dans la pane (68-08 ; VFSG-07, VFSG-06 ; P68-D-05, P68-D-06, P68-D-17, P68-PL-10) : la couleur ne
// porte que le statut, deux thèmes. Les valeurs ci-dessous sont recopiées de `DESIGN.md` (sombre, clair) ; la suite statique
// (M10) garde `tokens.ts` contre `DESIGN.md`, ces tests gardent le rendu contre ces valeurs. Préfixe R8- (verdict.sh refuse un
// identifiant en double).

const SOMBRE = { done: '#4ade80', active: '#f0c36b', todo: '#5c5c5c', blocked: '#f28b8b', text: '#ececec', t2: '#b4b4b4', t3: '#8b8b8b', t4: '#5c5c5c' }
const CLAIR = { done: '#157a3a', active: '#946000', todo: '#666666', blocked: '#c94a4a', text: '#161616', t2: '#3f3f3f', t3: '#595959', t4: '#666666' }

const PANE = {
  plugin: 'vibeflow',
  component: 'Pane',
  requestId: 'vf-signal',
  props: { title: 'vf-signal', isFocused: false, bodyColumns: 80, placement: 'dock', scroll: { offset: 0, bodyRows: 40 }, view: {} },
} as const

type Vue = 'mission' | 'equipe' | 'macro'

/** Monte la pane sur la vue demandée ; `theme` est la valeur de la ligne `theme` de `$.config.list()` (absente : aucune ligne). */
async function monte($: any, on: On, stdout: string, o: { theme?: string; vue?: Vue; agents?: any[] } = {}) {
  labSignal(on, { stdout, agents: o.agents })
  if (o.theme) on('config.list', () => ({ value: [{ key: 'theme', label: 'Theme', kind: 'choice', value: o.theme, provider: { kind: 'engine' } }] as any }))
  await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  if (o.vue && o.vue !== 'mission') await ui.press({ key: `onglet:${o.vue}` })
  return ui
}

/** Les couleurs des `Text` dont le texte entier correspond à `re` ; au moins un, sinon le témoin ne prouve rien. */
async function couleurs(ui: any, re: RegExp): Promise<unknown[]> {
  const found = await ui.findAll({ type: 'Text', text: re })
  expect(found.length).toBeGreaterThan(0)
  return found.map((f: any) => f.props.color)
}
const toutes = (cs: unknown[], v: string) => expect(cs.every(c => c === v)).toBe(true)

const INCONNU = avec(s => { s.arbres[1].phaseActive = { key: 'fiabilite|70', n: '70', nom: 'Cockpit inconnu', etat: 'en-cours' } })
const ILLISIBLE = avec(s => { s.verrous.etat = 'illisible'; s.verrous.liste = [] })
// une mission vivante : un nœud fait, un en cours, un en échec, un à venir
const VIVANTE = avec(s => {
  s.missions[0].etat = 'running'; s.missions[0].libelle = 'en cours'; s.phases[0].avancement.mission.etat = 'running'
  s.missions[0].noeuds = [
    { id: 'noeud-fait', status: 'done', step: 'cadrage', stage: '', deps: [] },
    { id: 'noeud-cours', status: 'running', step: 'exécution', stage: '', deps: ['noeud-fait'] },
    { id: 'noeud-rate', status: 'failed', step: 'revue', stage: '', deps: ['noeud-fait'] },
    { id: 'noeud-venir', status: 'pending', step: 'clôture', stage: '', deps: ['noeud-cours'] },
  ]
})
const PHASES = avec(s => { s.phases[0].fait = true; s.phases[0].libelle = 'fait'; s.phases[0].avancement.etat = 'fait' })
const w = (o: Record<string, unknown>) => ({ source: 'sessions', tree: 'arbre principal', etat: 'actif', ageS: 30, kind: 'subagent', ...o })
const EQUIPE = avec(s => {
  s.equipe.workers = [
    w({ id: 'e1', role: 'role-actif', task: 'tâche une' }),
    w({ id: 'e2', role: 'role-fini', task: 'tâche deux', etat: 'termine' }),
    w({ kind: 'registered', id: 'e3', role: 'role-orphelin', task: 'tâche trois', source: 'registre', orphan: true, stale: true, etat: undefined }),
  ]
})

test("R8-G1 — la mission abandonnée est grisée (st-todo) avec son libellé, dans l'en-tête", async ($, on) => {
  const ui = await monte($, on, avec(() => {}))
  toutes(await couleurs(ui, /^mission MISSION-68 · abandonnée, nœuds non refermés$/), SOMBRE.todo)
  await ui.unmount()
})

test("R8-G1b — la mission d'état inconnu prend le neutre st-todo, ni st-active ni st-blocked", async ($, on) => {
  const ui = await monte($, on, INCONNU)
  toutes(await couleurs(ui, /^mission MISSION-70 · état inconnu$/), SOMBRE.todo)
  await ui.unmount()
})

test("R8-G2 — « à recetter » en st-active, le retard en st-active, l'erreur du socle en st-blocked", async ($, on) => {
  const ui = await monte($, on, ILLISIBLE)
  toutes(await couleurs(ui, /^\(à recetter\)$/), SOMBRE.active)
  toutes(await couleurs(ui, /^en retard de 3 commits sur main/), SOMBRE.active)
  toutes(await couleurs(ui, /verrous illisibles/), SOMBRE.blocked)
  await ui.unmount()
})

test("R8-G3 — thème clair : les mêmes éléments prennent les valeurs claires ; un thème « dark » reste sombre", async ($, on) => {
  const ui = await monte($, on, ILLISIBLE, { theme: 'light' })
  toutes(await couleurs(ui, /^mission MISSION-68 · abandonnée, nœuds non refermés$/), CLAIR.todo)
  toutes(await couleurs(ui, /^\(à recetter\)$/), CLAIR.active)
  toutes(await couleurs(ui, /^en retard de 3 commits sur main/), CLAIR.active)
  toutes(await couleurs(ui, /verrous illisibles/), CLAIR.blocked)
  await ui.unmount()
})

test("R8-G3b — thème « dark » : valeurs sombres", async ($, on) => {
  const ui = await monte($, on, ILLISIBLE, { theme: 'dark' })
  toutes(await couleurs(ui, /^\(à recetter\)$/), SOMBRE.active)
  await ui.unmount()
})

test("R8-G4 — vue mission : en cours st-active, en échec st-blocked, fait st-done, à venir st-todo ; le fil n'emploie que le texte", async ($, on) => {
  const ui = await monte($, on, VIVANTE)
  toutes(await couleurs(ui, /noeud-cours/), SOMBRE.active)
  toutes(await couleurs(ui, /noeud-rate/), SOMBRE.blocked)
  toutes(await couleurs(ui, /noeud-fait/), SOMBRE.done)
  toutes(await couleurs(ui, /noeud-venir/), SOMBRE.todo)
  const fil = await couleurs(ui, /^(cadrer|planifier|exécuter|vérifier|clore)$/)
  expect(fil.every(c => [SOMBRE.text, SOMBRE.t3, SOMBRE.t4].includes(c as string))).toBe(true)
  await ui.unmount()
})

test("R8-G4b — vue mission : une mission abandonnée grise ses nœuds en cours (st-todo), le fait reste st-done", async ($, on) => {
  const ui = await monte($, on, avec(() => {}))
  toutes(await couleurs(ui, / b · exécution/), SOMBRE.todo)
  toutes(await couleurs(ui, /^mission 1\/3 · MISSION-68 · abandonnée/), SOMBRE.todo)
  await ui.unmount()
})

test("R8-G5 — vue macro : phase faite st-done, phase à recetter st-active et écrite en toutes lettres", async ($, on) => {
  const ui = await monte($, on, PHASES, { vue: 'macro' })
  toutes(await couleurs(ui, /68 Embarquer le mod · fait/), SOMBRE.done)
  toutes(await couleurs(ui, /69 Suivi du travail · à recetter/), SOMBRE.active)
  await ui.unmount()
})

test("R8-G5b — vue équipe : agent actif st-active, terminé st-todo, orphelin st-active (attention)", async ($, on) => {
  const ui = await monte($, on, EQUIPE, { vue: 'equipe' })
  toutes(await couleurs(ui, /role-actif/), SOMBRE.active)
  toutes(await couleurs(ui, /role-fini/), SOMBRE.todo)
  toutes(await couleurs(ui, /role-orphelin/), SOMBRE.active)
  await ui.unmount()
})
