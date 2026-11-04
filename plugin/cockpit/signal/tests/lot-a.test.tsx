import { expect, mock, test } from 'claude-code/testing'
import type { AgentInfo, On } from 'claude-code'

import { SIGNAL, avec } from './fixture-signal'
import { apresDemarrage } from './apres-demarrage'

// Correction ciblée du lot A (68-FIX-MA ; P68-D-34, P68-D-35 ; ADR-031). Identifiants MA-… (lus par verdict.sh).
//  - MA-D34* : rien sous le lab (le lanceur « Ouvrir le cockpit » et le repli driver-lock.sh de l'élagage).
//  - MA-R2*  : un agent vivant de la session garde « voir » et « arrêt » même classé terminé par who@2.
//  - MA-R3*  : la vue Équipe replie les terminés derrière un compteur ; actifs et orphelins restent en tête.

const PANE = {
  plugin: 'vibeflow',
  component: 'Pane',
  requestId: 'vf-signal',
  props: { title: 'vf-signal', isFocused: false, bodyColumns: 60, placement: 'dock', scroll: { offset: 0, bodyRows: 40 }, view: {} },
} as const
const OK = 'Cockpit : http://127.0.0.1:4317/ (Code)\n'
const VERROU = { ws: 'fiabilite', scope: 'phase', phase: '68', tenu: true, stale: true, ageS: 97000, ttl: 1800, progressAgeS: null, owner: 'mgr68' }
const STALE = avec(s => { s.verrous.liste = [VERROU] })

type Opts = { sansReel?: boolean; poses?: RegExp; reels?: Record<string, string>; stdout?: string; agents?: AgentInfo[] }
type Lab = { lanceur: string[]; bash: string[]; racinePlugin: () => string | undefined }

/** Un faux lab : `poses` dit quels fichiers existent, `reels` ce que `fs.stat(…, { resolve: true })` rend comme realPath. */
function lab(on: On, o: Opts = {}): Lab {
  const sp: Lab = { lanceur: [], bash: [], racinePlugin: () => undefined }
  let cwdEmetteur: string | undefined
  sp.racinePlugin = () => cwdEmetteur
  mock.clock(on, { now: 1_000_000 })
  mock.env(on, { HOME: '/home/user' })
  on('command.register', () => ({ value: { command: 'vf-signal' } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('ui.toast', () => ({ value: undefined }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('agent.list', () => ({ value: o.agents ?? [] }))
  on('session.root', () => ({ value: '/lab' }))
  on('session.usage', () => ({ value: { startedAt: 0, context: { window: 200000, tokens: 50000, percent: 25 }, rateLimits: [], cost: { usd: 0.42 } } }))
  on('fs.exists', (_, e) => ({ value: o.poses?.test(String(e.path)) ?? false }))
  on('fs.stat', (_, e) => {
    if (o.sansReel) return { deny: 'ENOENT' }
    const p = String(e.path)
    return { value: { kind: 'file', size: 1, mtimeMs: 0, isLink: p in (o.reels ?? {}), realPath: o.reels?.[p] ?? p } }
  })
  on('fs.read', (_, e) => {
    if (String(e.path).endsWith('.vibeflow-installed')) return { value: 'cockpit=v1.2.0\n' }
    throw new Error('ENOENT')
  })
  on('fs.list', () => ({ value: [] }))
  on('process.run', (_, e) => {
    const argv = e.argv as readonly string[]
    const rendu = (stdout: string) => ({ value: { exitCode: 0, stdout, stderr: '', isStdoutTruncated: false, isStderrTruncated: false } })
    if (argv[0] === 'node' && /vf-cockpit\.mjs$/.test(String(argv[1]))) { sp.lanceur.push(String(argv[1])); return rendu(OK) }
    if (argv[0] === 'bash') { sp.bash.push(String(argv[1])); return rendu('ok') }
    cwdEmetteur ??= e.init?.cwd
    return rendu(o.stdout ?? JSON.stringify(SIGNAL))
  })
  return sp
}

async function pane($: any) {
  await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })
  await apresDemarrage()
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  if (await ui.find({ key: 'onglet:equipe' })) await ui.press({ key: 'onglet:equipe' })
  return ui
}

// --- P68-D-34 : le lanceur ----------------------------------------------------------------------------------------

test("MA-D34a — vf-cockpit.mjs planté sous <lab>/.claude/scripts : jamais lancé ; le lanceur du plugin le remplace", async ($, on) => {
  const sp = lab(on, { poses: /^\/lab\/\.claude\/scripts\/vf-cockpit\.mjs$/ })
  const ui = await pane($)
  await ui.press({ key: 'ouvrir-cockpit' })
  expect(sp.lanceur.filter(c => c.startsWith('/lab/'))).toEqual([])
  expect(sp.lanceur).toEqual([`${sp.racinePlugin()}/cockpit/scripts/vf-cockpit.mjs`])
  await ui.unmount()
})

test("MA-D34b — lanceur du compte qui est un lien dont le realpath tombe sous le lab : refusé, jamais lancé", async ($, on) => {
  const compte = '/home/user/.claude/scripts/vf-cockpit.mjs'
  const sp = lab(on, { poses: /vf-cockpit\.mjs$/, reels: { [compte]: '/lab/vendu/vf-cockpit.mjs' } })
  const ui = await pane($)
  await ui.press({ key: 'ouvrir-cockpit' })
  expect(sp.lanceur).not.toContain(compte)
  expect(sp.lanceur.some(c => c.startsWith('/lab/'))).toBe(false)
  expect(sp.lanceur).toEqual([`${sp.racinePlugin()}/cockpit/scripts/vf-cockpit.mjs`])
  await ui.unmount()
})

test("MA-D34c — témoin positif : le lanceur du compte est lancé, même avec un lanceur planté sous le lab", async ($, on) => {
  const sp = lab(on, { poses: /vf-cockpit\.mjs$/ })
  const ui = await pane($)
  await ui.press({ key: 'ouvrir-cockpit' })
  expect(sp.lanceur).toEqual(['/home/user/.claude/scripts/vf-cockpit.mjs'])
  await ui.unmount()
})

test("MA-D34d — sans realpath obtenable, le fichier est refusé (P68-D-37, d.ts de $.fs.stat) : ni le lab ni le compte, le lanceur du plugin", async ($, on) => {
  const sp = lab(on, { poses: /vf-cockpit\.mjs$/, sansReel: true })
  const ui = await pane($)
  await ui.press({ key: 'ouvrir-cockpit' })
  expect(sp.lanceur).toEqual([`${sp.racinePlugin()}/cockpit/scripts/vf-cockpit.mjs`])
  await ui.unmount()
})

// --- P68-D-34 : le repli driver-lock.sh de l'élagage --------------------------------------------------------------

test("MA-D34e — driver-lock.sh planté sous <lab>/.claude/scripts : jamais lancé (aucun bouton d'élagage)", async ($, on) => {
  const sp = lab(on, { stdout: STALE, poses: /^\/lab\/\.claude\/scripts\/driver-lock\.sh$/ })
  const ui = await pane($)
  expect(await ui.find({ key: 'elaguer' })).toBeUndefined()
  await ui.unmount()
  expect(sp.bash).toEqual([])
})

test("MA-D34f — driver-lock.sh du compte, lien dont le realpath tombe sous le lab : refusé", async ($, on) => {
  const compte = '/home/user/.claude/scripts/driver-lock.sh'
  const sp = lab(on, { stdout: STALE, poses: /^\/home\/user\/\.claude\/scripts\/driver-lock\.sh$/, reels: { [compte]: '/lab/vendu/driver-lock.sh' } })
  const ui = await pane($)
  expect(await ui.find({ key: 'elaguer' })).toBeUndefined()
  await ui.unmount()
  expect(sp.bash).toEqual([])
})

test("MA-D34g — témoin positif : driver-lock.sh du compte, hors du lab, est lancé par l'appui humain", async ($, on) => {
  const sp = lab(on, { stdout: STALE, poses: /^(\/home\/user|\/lab)\/\.claude\/scripts\/driver-lock\.sh$/ })
  const ui = await pane($)
  await ui.press({ key: 'elaguer' })
  expect(sp.bash).toEqual(['/home/user/.claude/scripts/driver-lock.sh'])
  await ui.unmount()
})

// --- P68-D-35 R2 : les gestes vont aux agents vivants de la session -----------------------------------------------

const w = (o: Record<string, unknown>) => ({ source: 'sessions', tree: 'arbre principal', etat: 'actif', ageS: 30, ...o })
const vivant = (id: string, status = 'running') => ({ id, type: 'vf-coder', description: `agent ${id}`, status }) as AgentInfo

test("MA-R2a — agent classé « termine » par who@2 mais vivant dans $.agent.list() : il garde voir et arrêt", async ($, on) => {
  lab(on, { stdout: avec(s => { s.equipe.workers = [w({ kind: 'subagent', id: 'c1', role: 'vf-coder', task: 'plan fini au premier tour', etat: 'termine' })] }), agents: [vivant('c1')] })
  const ui = await pane($)
  expect(await ui.find({ key: 'voir:c1' })).toBeDefined()
  expect(await ui.find({ key: 'stop:c1' })).toBeDefined()
  await ui.unmount()
})

test("MA-R2b — même agent terminé des deux côtés (list : completed) : aucun geste ; absent de la liste : aucun geste", async ($, on) => {
  lab(on, {
    stdout: avec(s => { s.equipe.workers = [
      w({ kind: 'subagent', id: 'c1', role: 'vf-coder', task: 'tache-c1-close', etat: 'termine' }),
      w({ kind: 'subagent', id: 'c2', role: 'vf-coder', task: 'tache-c2-close', etat: 'termine' }),
    ] }),
    agents: [vivant('c1', 'completed')],
  })
  const ui = await pane($)
  for (const id of ['c1', 'c2']) {
    expect(await ui.find({ key: `voir:${id}` })).toBeUndefined()
    expect(await ui.find({ key: `stop:${id}` })).toBeUndefined()
  }
  // un agent fini des deux côtés se replie avec les autres terminés
  expect(await ui.find({ type: 'Text', text: /tache-c[12]-close/ })).toBeUndefined()
  expect(await ui.find({ text: /2 terminés/ })).toBeDefined()
  await ui.unmount()
})

// --- P68-D-35 R3 : les terminés se replient ------------------------------------------------------------------------

const TERMINES = Array.from({ length: 150 }, (_, i) => w({ kind: 'subagent', id: `t${i}`, role: 'vf-reviewer', task: `tache-finie-${i}`, etat: 'termine' }))
const ACTIFS = [
  w({ kind: 'subagent', id: 'a1', role: 'vf-coder', task: 'travail-actif-un' }),
  w({ kind: 'subagent', id: 'a2', role: 'vf-coder', task: 'travail-actif-deux', etat: 'en-attente' }),
  w({ kind: 'registered', id: 'o1', role: 'vf-auditer', task: 'travail-orphelin', source: 'registre', stale: true, orphan: true, etat: undefined }),
]
// les terminés sont écrits AVANT les actifs : l'ordre du socle ne doit pas les faire passer devant
const NOMBREUX = avec(s => { s.equipe.workers = [...TERMINES, ...ACTIFS] })

test("MA-R3a — 150 terminés et 3 actifs : les 3 apparaissent dans la page rendue, les terminés se replient derrière « 150 terminés »", async ($, on) => {
  lab(on, { stdout: NOMBREUX })
  const ui = await pane($)
  for (const t of ['travail-actif-un', 'travail-actif-deux', 'travail-orphelin']) expect(await ui.find({ type: 'Text', text: new RegExp(t) })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /tache-finie-/ })).toBeUndefined()
  expect(await ui.find({ text: /150 terminés/ })).toBeDefined()
  await ui.unmount()
})

test("MA-R3b — le compteur se déplie (les terminés apparaissent) et se replie ; actifs toujours en tête", async ($, on) => {
  lab(on, { stdout: NOMBREUX })
  const ui = await pane($)
  await ui.press({ key: 'finis' })
  expect(await ui.find({ type: 'Text', text: /tache-finie-149/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /travail-actif-un/ })).toBeDefined()
  await ui.press({ key: 'finis' })
  expect(await ui.find({ type: 'Text', text: /tache-finie-/ })).toBeUndefined()
  await ui.unmount()
})

test("MA-R3c — sans terminé, pas de compteur", async ($, on) => {
  lab(on, { stdout: avec(s => { s.equipe.workers = ACTIFS }) })
  const ui = await pane($)
  expect(await ui.find({ key: 'finis' })).toBeUndefined()
  await ui.unmount()
})

test("MA-R3d — un seul terminé : « 1 terminé » au singulier", async ($, on) => {
  lab(on, { stdout: avec(s => { s.equipe.workers = [...TERMINES.slice(0, 1), ...ACTIFS] }) })
  const ui = await pane($)
  expect(await ui.find({ text: /1 terminé\b(?!s)/ })).toBeDefined()
  await ui.unmount()
})
