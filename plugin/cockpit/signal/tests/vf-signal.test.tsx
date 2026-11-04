import { expect, mock, test } from 'claude-code/testing'
import type { AgentInfo, On } from 'claude-code'

import { SIGNAL, avec } from './fixture-signal'

// Le retrait de la lecture maison du planning (68-06 ; P68-D-02, P68-D-13, P68-D-17, P68-D-24, P68-D-30) : la pane, le
// bandeau, `/vf-signal brief` et le bouton d'élagage ne lisent que `signal@1`. Identifiant du témoin en tête de titre
// (préfixe R6- : K5, K10 et K11 existent déjà dans socle.test.tsx, `verdict.sh` compare le titre par son début).

const PANE = {
  plugin: 'vibeflow',
  component: 'Pane',
  requestId: 'vf-signal',
  props: {
    title: 'vf-signal',
    isFocused: false,
    bodyColumns: 60,
    placement: 'dock',
    scroll: { offset: 0, bodyRows: 40 },
    view: {},
  },
} as const

const COMPACT = { ...PANE, props: { ...PANE.props, placement: 'inline' } } as const

const BAND = {
  plugin: 'vibeflow',
  component: 'AbovePrompt',
  requestId: 'band',
  props: { hasSurvey: false, isWorking: false, maxRows: 4, bodyColumns: 80, scroll: { offset: 0, bodyRows: 4 }, view: {} },
} as const

// Un verrou de phase tenu et périmé, tel que l'émetteur le range dans `verrous.liste`.
const VERROU_PERIME = { ws: 'fiabilite', scope: 'phase', phase: '68', tenu: true, stale: true, ageS: 97000, ttl: 1800, progressAgeS: null, owner: 'mgr68' }
const AVEC_VERROU = avec(s => { s.verrous.liste = [VERROU_PERIME] })

// L'ancienne lecture maison servait ceci : STATE.md, driver-lock.sh status, un DAG. Elle ne doit plus rien changer.
const STATE = ['---', 'milestone: equipe-produit-v1.0', 'current_phase: 59', 'current_phase_name: Bundle produit', 'status: in_progress', '---'].join('\n')
const LOCK_ANCIEN = JSON.stringify({
  present: true,
  locks: [{ present: true, owner: 'vf-dev-manager-p59', step: 'mission', age_seconds: 97000, ttl: 1800, stale: true, children_running: 1, scope: 'compartiment', ws: 'fiabilite' }],
})

type Lab = { lus: string[]; bash: { argv: readonly string[]; cwd: string | undefined }[]; racinePlugin: () => string | undefined }
type Opts = { stdout?: string; agents?: AgentInfo[]; scripts?: RegExp; leurre?: boolean }

/**
 * Un faux lab qui sert `signal@1` à l'émetteur et enregistre tout ce que le mod lit (`fs.*`) et lance (`bash`).
 * `scripts` dit quels `driver-lock.sh` existent. `leurre` sert en plus l'ancien disque (STATE.md, `status --all`) :
 * l'ancienne lecture maison aurait de quoi lire, la nouvelle n'y touche pas. (Local : `labSignal` est fermé aux espions,
 * un second `on('fs.exists')` est refusé par le moteur de test.)
 */
function lab(on: On, o: Opts = {}): Lab {
  const sp: Lab = { lus: [], bash: [], racinePlugin: () => undefined }
  let cwdEmetteur: string | undefined
  sp.racinePlugin = () => cwdEmetteur
  mock.clock(on, { now: 1_000_000 })
  mock.env(on, { HOME: '/home/user' })
  on('command.register', () => ({ value: { command: 'vf-signal' } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('agent.list', () => ({ value: o.agents ?? [] }))
  on('session.root', () => ({ value: '/lab' }))
  on('ui.toast', () => ({ value: undefined }))
  on('session.usage', () => ({ value: { startedAt: 0, context: { window: 200000, tokens: 50000, percent: 25 }, rateLimits: [], cost: { usd: 0.42 } } }))
  on('fs.exists', (_, e) => {
    const p = String(e.path)
    sp.lus.push(p)
    return { value: (o.leurre === true && /active-workstream|STATE\.md/.test(p)) || (o.scripts?.test(p) ?? false) }
  })
  on('fs.read', (_, e) => {
    const p = String(e.path)
    sp.lus.push(p)
    if (p.endsWith('.vibeflow-installed')) return { value: 'cockpit=v1.2.0\n' }
    if (o.leurre === true && p.endsWith('active-workstream')) return { value: 'fiabilite' }
    if (o.leurre === true && p.endsWith('STATE.md')) return { value: STATE }
    throw new Error('ENOENT')
  })
  on('fs.list', (_, e) => {
    sp.lus.push(String(e.path))
    return { value: [] }
  })
  on('process.run', (_, e) => {
    const argv = e.argv as readonly string[]
    const ok = (stdout: string) => ({ value: { exitCode: 0, stdout, stderr: '', isStdoutTruncated: false, isStderrTruncated: false } })
    if (argv[0] === 'node') {
      cwdEmetteur = e.init?.cwd
      return ok(o.stdout ?? JSON.stringify(SIGNAL))
    }
    if (argv[0] === 'bash') {
      sp.bash.push({ argv, cwd: e.init?.cwd })
      return ok(argv.includes('status') && o.leurre === true ? LOCK_ANCIEN : '{}')
    }
    return ok('')
  })
  return sp
}

/** Ce que l'engine dessinerait là où le mod laisse passer. */
function moteur(on: On) {
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })
}

async function demarrer($: any) {
  await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })
}

test("la pane montre la phase, la mission par vagues et le verrou périmé, sur chaque surface", async ($, on) => {
  lab(on, { stdout: AVEC_VERROU })
  moteur(on)
  await demarrer($)

  for (const surface of ['terminal', 'desktop', 'vscode', 'mobile'] as const) {
    const ui = await $.ui.mount({ ...PANE, surface })
    expect(await ui.find({ type: 'Text', text: /phase 68 Embarquer le mod/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /exécution/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /périmé/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /verrou périmé de mgr68/ })).toBeDefined()
    await ui.unmount()
  }
})

test('le bandeau porte la prochaine action humaine et se masque', async ($, on) => {
  lab(on, { stdout: AVEC_VERROU })
  moteur(on)
  await demarrer($)

  const ui = await $.ui.mount({ ...BAND, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: /verrou périmé de mgr68/ })).toBeDefined()
  await ui.press({ key: 'masquer' })
  expect(await ui.find({ type: 'Text', text: /verrou périmé/ })).toBeUndefined()
  await ui.unmount()
})

test("la vue équipe liste les agents en arbre, avec le geste d'arrêt", async ($, on) => {
  const w = (id: string, role: string, o = {}) => ({ kind: 'subagent', id, role, task: id, tree: 'arbre principal', source: 'sessions', etat: 'actif', ...o }) // 68-07 : l'arbre vient de signal@1.equipe (P68-D-03, P68-D-17)
  lab(on, {
    stdout: avec(s => { s.equipe.workers = [w('m1', 'vf-dev-manager'), w('c1', 'vf-coder', { parent: 'm1' })] }),
    agents: [{ id: 'm1', type: 'vf-dev-manager', description: 'mission 59', status: 'running' },
      { id: 'c1', parentId: 'm1', type: 'vf-coder', description: 'plan 59-01', status: 'running' }],
  })
  moteur(on)
  await demarrer($)

  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  await ui.press({ key: 'onglet:equipe' })
  expect(await ui.find({ type: 'Text', text: /vf-dev-manager/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /vf-coder/ })).toBeDefined()
  expect(await ui.find({ key: 'stop:c1' })).toBeDefined()
  // Par conception : la vue macro lit les jalons de signal@1 ; le bloc backlog (BACKLOG.md) n'existe plus (P68-D-24).
  await ui.press({ key: 'onglet:macro' })
  expect(await ui.find({ type: 'Text', text: /Jalon d essai/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /backlog/ })).toBeUndefined()
  await ui.unmount()
})

test("R6-K5 — aucune lecture sous .planning/ sur toute la session : démarrage, trois vues, bandeau, brief", async ($, on) => {
  const sp = lab(on, { stdout: AVEC_VERROU, leurre: true })
  moteur(on)
  await demarrer($)

  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  await ui.press({ key: 'onglet:macro' })
  await ui.press({ key: 'onglet:equipe' })
  await ui.unmount()
  const band = await $.ui.mount({ ...BAND, surface: 'terminal' })
  await band.unmount()
  const brief = await $.command.run({ command: 'vf-signal', args: 'brief' })

  // le témoin positif : l'espion a bien vu passer des lectures (le registre du gating), il ne compte pas à vide
  expect(sp.lus.filter(p => p.endsWith('.vibeflow-installed')).length).toBeGreaterThan(0)
  expect(sp.lus.filter(p => p.includes('/.planning'))).toEqual([])
  expect(String(brief.text)).toMatch(/phase 68/)
})

test("R6-K10 — le bouton d'élagage lance bash <racine du plugin>/conductor/scripts/driver-lock.sh recover --ws=<ws>", async ($, on) => {
  // les trois candidats existent : seul l'ordre de P68-D-13 désigne le script du plugin
  const sp = lab(on, { stdout: AVEC_VERROU, scripts: /driver-lock\.sh$/, leurre: true })
  moteur(on)
  await demarrer($)

  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  await ui.press({ key: 'elaguer' })
  const racinePlugin = sp.racinePlugin()
  expect(racinePlugin).toBeDefined()
  const recover = sp.bash.filter(b => b.argv.includes('recover'))
  expect(recover.length).toBe(1)
  expect(recover[0]!.argv).toEqual(['bash', `${racinePlugin}/conductor/scripts/driver-lock.sh`, 'recover', '--ws=fiabilite'])
  expect(recover[0]!.cwd).toBe('/lab')
  await ui.unmount()
})

test("R6-K10b — plugin amputé : le script du scope projet, puis celui du compte", async ($, on) => {
  const sp = lab(on, { stdout: AVEC_VERROU, scripts: /^\/lab\/\.claude\/scripts\/driver-lock\.sh$/ })
  moteur(on)
  await demarrer($)
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  await ui.press({ key: 'elaguer' })
  expect(sp.bash.filter(b => b.argv.includes('recover')).map(b => b.argv[1])).toEqual(['/lab/.claude/scripts/driver-lock.sh'])
  await ui.unmount()
})

test("R6-K10c — ni plugin ni projet : le script du compte", async ($, on) => {
  const sp = lab(on, { stdout: AVEC_VERROU, scripts: /^\/home\/user\/\.claude\/scripts\/driver-lock\.sh$/ })
  moteur(on)
  await demarrer($)
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  await ui.press({ key: 'elaguer' })
  expect(sp.bash.filter(b => b.argv.includes('recover')).map(b => b.argv[1])).toEqual(['/home/user/.claude/scripts/driver-lock.sh'])
  await ui.unmount()
})

test("R6-K11 — vue mission : les nœuds de la mission courante de signal@1 et son libellé « abandonnée, nœuds non refermés »", async ($, on) => {
  lab(on)
  moteur(on)
  await demarrer($)
  // posée au-dessus du prompt, l'en-tête dockée (qui dit déjà le libellé) n'est pas dessinée : le libellé vient de la vue
  const ui = await $.ui.mount({ ...COMPACT, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: /exécution/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /revue/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /abandonnée, nœuds non refermés/ })).toBeDefined()
  await ui.unmount()
  const dock = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await dock.find({ type: 'Text', text: /cadrage/ })).toBeDefined()
  await dock.unmount()
})

test("R6-K11b — mission d'état inconnu : « état inconnu » dans la vue (P68-D-23)", async ($, on) => {
  lab(on, {
    stdout: avec(s => { Object.assign(s.arbres.find((a: any) => a.courant), { phaseActive: { key: 'fiabilite|70', n: '70', nom: 'Cockpit inconnu', etat: 'en-cours' } }) }),
  })
  moteur(on)
  await demarrer($)
  const ui = await $.ui.mount({ ...COMPACT, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: /état inconnu/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /abandonnée/ })).toBeUndefined()
  await ui.unmount()
})

test("R6-J1 — l'en-tête dit le jalon de la phase active de l'arbre courant (P68-D-30)", async ($, on) => {
  lab(on)
  moteur(on)
  await demarrer($)
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: /jalon v1 · Jalon d essai/ })).toBeDefined()
  await ui.unmount()
})

test("R6-J2 — phase active hors de tout jalon, ou aucune : pas de jalon, jamais un repli sur le STATE (P68-D-30)", async ($, on) => {
  // phase 70 : aucun jalon de jalons[] ne la contient ; le STATE.md servi dit un autre jalon (leurre)
  lab(on, {
    leurre: true,
    stdout: avec(s => { Object.assign(s.arbres.find((a: any) => a.courant), { phaseActive: { key: 'fiabilite|70', n: '70', nom: 'Cockpit inconnu', etat: 'en-cours' } }) }),
  })
  moteur(on)
  await demarrer($)
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: /phase 70 Cockpit inconnu/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /jalon/ })).toBeUndefined()
  expect(await ui.find({ type: 'Text', text: /equipe-produit-v1/ })).toBeUndefined()
  await ui.unmount()
})

test("R6-J3 — arbre courant sans phase active : pas de jalon", async ($, on) => {
  lab(on, { stdout: avec(s => { s.arbres.find((a: any) => a.courant).phaseActive = null }) })
  moteur(on)
  await demarrer($)
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: /aucune phase en cours/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /jalon/ })).toBeUndefined()
  await ui.unmount()
})

test("R6-A1 — mission vivante avec un nœud en échec : le bandeau le dit", async ($, on) => {
  lab(on, {
    stdout: avec(s => {
      s.missions[0].etat = 'running'
      s.missions[0].noeuds[1].status = 'failed'
    }),
  })
  moteur(on)
  await demarrer($)
  const ui = await $.ui.mount({ ...BAND, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: /nœud en échec · exécution/ })).toBeDefined()
  await ui.unmount()
})

test("R6-A2 — mission abandonnée dont un nœud est resté en échec : le bandeau n'attend personne (P68-D-05)", async ($, on) => {
  lab(on, { stdout: avec(s => { s.missions[0].noeuds[1].status = 'failed' }) })
  moteur(on)
  await demarrer($)
  const ui = await $.ui.mount({ ...BAND, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: /nœud failed/ })).toBeUndefined()
  expect(await ui.find({ type: 'Text', text: /engine/ })).toBeDefined()
  await ui.unmount()
})
