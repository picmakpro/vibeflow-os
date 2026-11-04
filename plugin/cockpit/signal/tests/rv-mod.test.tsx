import { expect, mock, test } from 'claude-code/testing'
import type { AgentInfo, On } from 'claude-code'

import { SIGNAL, avec } from './fixture-signal'

// Correction ciblée de la revue fraîche (68-FIX-RV-MOD ; P68-D-34, P68-D-37, P68-D-35 ; ADR-031). Identifiants RV-… (lus par verdict.sh).
//  - RV-Q41* : un fichier dont le realpath manque est refusé (le garde ne se rabat plus sur le chemin écrit).
//  - RV-Q42  : la racine du lab ouverte par un lien (`sous(c, base)`) refuse un lanceur qui y atterrit.
//  - RV-Q44  : « copier takeover » sans script résolu ne copie rien et le dit.
//  - RV-Q45* : les lancements du mod partent hors du lab, avec un PATH assaini (classe H-1).
//  - RV-R2*  : failed et killed n'ont aucun geste. RV-R3 : le fantôme compact. RV-R11 : statuts d'agent en français.

const PANE = {
  plugin: 'vibeflow',
  component: 'Pane',
  requestId: 'vf-signal',
  props: { title: 'vf-signal', isFocused: false, bodyColumns: 60, placement: 'dock', scroll: { offset: 0, bodyRows: 40 }, view: {} },
} as const
const COMPACT = { ...PANE, props: { ...PANE.props, placement: 'inline' } } as const
const COMPTE = '/home/user/.claude/scripts/vf-cockpit.mjs'
const VERROU = { ws: 'fiabilite', scope: 'phase', phase: '68', tenu: true, stale: true, ageS: 97000, ttl: 1800, progressAgeS: null, owner: 'mgr68' }
const STALE = avec(s => { s.verrous.liste = [VERROU] })

type Appel = { argv: readonly string[]; cwd: string | undefined; env: Record<string, string> | undefined }
type Opts = { poses?: RegExp; reels?: Record<string, string>; sansReelPour?: RegExp; stdout?: string; agents?: AgentInfo[]; path?: string }
type Lab = { appels: Appel[]; toasts: string[]; copies: string[]; racinePlugin: () => string | undefined }

function lab(on: On, o: Opts = {}): Lab {
  const sp: Lab = { appels: [], toasts: [], copies: [], racinePlugin: () => sp.appels.find(a => /signal\.mjs$/.test(String(a.argv[1])))?.cwd }
  mock.clock(on, { now: 1_000_000 })
  mock.env(on, { HOME: '/home/user', ...(o.path !== undefined ? { PATH: o.path } : {}) })
  on('command.register', () => ({ value: { command: 'vf-signal' } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('ui.toast', (_, e) => { sp.toasts.push(e.text); return { value: undefined } })
  on('ui.copy', (_, e) => { sp.copies.push(e.text); return { value: { isCopied: true } } })
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('agent.list', () => ({ value: o.agents ?? [] }))
  on('session.root', () => ({ value: '/lab' }))
  on('session.usage', () => ({ value: { startedAt: 0, context: { window: 200000, tokens: 50000, percent: 25 }, rateLimits: [], cost: { usd: 0.42 } } }))
  on('fs.exists', (_, e) => ({ value: o.poses?.test(String(e.path)) ?? false }))
  on('fs.stat', (_, e) => {
    const p = String(e.path)
    if (o.sansReelPour?.test(p)) return { value: { kind: 'file', size: 1, mtimeMs: 0, isLink: false } }
    return { value: { kind: 'file', size: 1, mtimeMs: 0, isLink: p in (o.reels ?? {}), realPath: o.reels?.[p] ?? p } }
  })
  on('fs.read', (_, e) => {
    if (String(e.path).endsWith('.vibeflow-installed')) return { value: 'cockpit=v1.2.0\n' }
    throw new Error('ENOENT')
  })
  on('fs.list', () => ({ value: [] }))
  on('process.run', (_, e) => {
    const argv = e.argv as readonly string[]
    sp.appels.push({ argv, cwd: e.init?.cwd, env: e.init?.env })
    const stdout = argv[0] === 'node' && /vf-cockpit\.mjs$/.test(String(argv[1])) ? 'Cockpit : http://127.0.0.1:4317/\n' : argv[0] === 'bash' ? 'ok' : (o.stdout ?? JSON.stringify(SIGNAL))
    return { value: { exitCode: 0, stdout, stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
  })
  return sp
}

async function monter($: any, props: any = PANE) {
  await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })
  const ui = await $.ui.mount({ ...props, surface: 'terminal' })
  if (await ui.find({ key: 'onglet:equipe' })) await ui.press({ key: 'onglet:equipe' })
  return ui
}
const lances = (sp: Lab) => sp.appels.filter(a => /vf-cockpit\.mjs$/.test(String(a.argv[1]))).map(a => a.argv[1])

// --- Q4-1 : realpath manquant => refus -----------------------------------------------------------------------------

test("RV-Q41a — le lanceur du compte existe mais son realpath manque : refusé, le lanceur du plugin prend le relais", async ($, on) => {
  const sp = lab(on, { poses: /vf-cockpit\.mjs$/, sansReelPour: /^\/home\/user\// })
  const ui = await monter($)
  await ui.press({ key: 'ouvrir-cockpit' })
  expect(lances(sp)).toEqual([`${sp.racinePlugin()}/cockpit/scripts/vf-cockpit.mjs`])
  await ui.unmount()
})

test("RV-Q41b — driver-lock.sh du compte sans realpath : aucun bouton d'élagage, rien lancé", async ($, on) => {
  const sp = lab(on, { stdout: STALE, poses: /^\/home\/user\/\.claude\/scripts\/driver-lock\.sh$/, sansReelPour: /^\/home\/user\// })
  const ui = await monter($)
  expect(await ui.find({ key: 'elaguer' })).toBeUndefined()
  await ui.unmount()
  expect(sp.appels.filter(a => a.argv[0] === 'bash')).toEqual([])
})

test("RV-Q41c — témoin positif : realpath présent hors du lab, le lanceur du compte est lancé", async ($, on) => {
  const sp = lab(on, { poses: /^\/home\/user\/\.claude\/scripts\/vf-cockpit\.mjs$/ })
  const ui = await monter($)
  await ui.press({ key: 'ouvrir-cockpit' })
  expect(lances(sp)).toEqual([COMPTE])
  await ui.unmount()
})

// --- Q4-2 : la racine du lab, ouverte par un lien ------------------------------------------------------------------

test("RV-Q42 — /lab est un lien vers /reel/lab ; le lanceur du compte atterrit sous /reel/lab : refusé", async ($, on) => {
  const sp = lab(on, { poses: /^\/home\/user\/\.claude\/scripts\/vf-cockpit\.mjs$/, reels: { '/lab': '/reel/lab', [COMPTE]: '/reel/lab/vendu/vf-cockpit.mjs' } })
  const ui = await monter($)
  await ui.press({ key: 'ouvrir-cockpit' })
  expect(lances(sp)).toEqual([`${sp.racinePlugin()}/cockpit/scripts/vf-cockpit.mjs`])
  await ui.unmount()
})

// --- Q4-4 : copier takeover sans script ----------------------------------------------------------------------------

test("RV-Q44 — aucun driver-lock.sh résolu : « copier takeover » ne copie rien et le dit", async ($, on) => {
  const sp = lab(on, { stdout: STALE })
  const ui = await monter($)
  await ui.press({ key: 'takeover' })
  expect(sp.copies).toEqual([])
  expect(sp.toasts.some(t => /driver-lock\.sh introuvable/.test(t))).toBe(true)
  await ui.unmount()
})

// --- Q4-5 : cwd et PATH des lancements du mod ----------------------------------------------------------------------

const PATH_HOTE = ['.', '', 'bin', '/lab/bin', '/lab', '/usr/local/bin', '/lab/../lab/x', '/usr/bin'].join(':')

test("RV-Q45a — « Ouvrir le cockpit » part de la racine du plugin, jamais du lab ; --lab suffit", async ($, on) => {
  const sp = lab(on)
  const ui = await monter($)
  await ui.press({ key: 'ouvrir-cockpit' })
  const l = sp.appels.find(a => /vf-cockpit\.mjs$/.test(String(a.argv[1])))!
  expect(l.cwd).toBe(sp.racinePlugin())
  expect(l.cwd).not.toBe('/lab')
  expect(l.argv.slice(2)).toEqual(['open', '--lab', '/lab'])
  await ui.unmount()
})

test("RV-Q45b — émetteur, lanceur et élagage reçoivent un PATH sans entrée vide, relative ou sous le lab", async ($, on) => {
  const sp = lab(on, { path: PATH_HOTE, stdout: STALE, poses: /^\/home\/user\/\.claude\/scripts\/driver-lock\.sh$/ })
  const ui = await monter($)
  await ui.press({ key: 'ouvrir-cockpit' })
  await ui.press({ key: 'elaguer' })
  expect(sp.appels.some(a => a.argv[0] === 'bash')).toBe(true)
  expect(sp.appels.some(a => a.argv[0] === 'node' && /signal\.mjs$/.test(String(a.argv[1])))).toBe(true)
  for (const a of sp.appels) expect(a.env?.PATH).toBe('/usr/local/bin:/usr/bin')
  await ui.unmount()
})

test("RV-Q45c — une entrée dont le realpath tombe sous le lab (ou sous le realpath du lab) est écartée", async ($, on) => {
  const sp = lab(on, { path: '/liens/a:/liens/b:/usr/bin', reels: { '/lab': '/reel/lab', '/liens/a': '/lab/vrai', '/liens/b': '/reel/lab/vrai' } })
  const ui = await monter($)
  await ui.press({ key: 'ouvrir-cockpit' })
  expect(sp.appels.length).toBeGreaterThan(0)
  for (const a of sp.appels) expect(a.env?.PATH).toBe('/usr/bin')
  await ui.unmount()
})

test("RV-Q45e — une entrée sous le lab dont le realpath ne se résout pas (dossier absent) est écartée sur son écriture, `..` compris", async ($, on) => {
  const sp = lab(on, { path: '/lab/bin:/usr/../lab/x:/usr/bin', sansReelPour: /^\/(lab|usr\/\.\.)\// })
  const ui = await monter($)
  await ui.press({ key: 'ouvrir-cockpit' })
  expect(sp.appels.length).toBeGreaterThan(0)
  for (const a of sp.appels) expect(a.env?.PATH).toBe('/usr/bin')
  await ui.unmount()
})

test("RV-Q45d — PATH entièrement douteux ou absent : repli sûr, jamais un PATH vide", async ($, on) => {
  const sp = lab(on, { path: '.:bin:/lab/bin' })
  const ui = await monter($)
  await ui.press({ key: 'ouvrir-cockpit' })
  for (const a of sp.appels) expect(a.env?.PATH).toBe('/usr/bin:/bin:/usr/sbin:/sbin')
  await ui.unmount()
})

// --- R2-1 : failed et killed ----------------------------------------------------------------------------------------

const w = (o: Record<string, unknown>) => ({ source: 'sessions', tree: 'arbre principal', etat: 'actif', ageS: 30, ...o })
const agent = (id: string, status: string) => ({ id, type: 'vf-coder', description: `agent ${id}`, status }) as AgentInfo

async function sansGeste(on: On, $: any, status: string) {
  lab(on, {
    stdout: avec(s => { s.equipe.workers = [w({ kind: 'subagent', id: 'c1', role: 'vf-coder', task: 'tache-c1-close', etat: 'termine' })] }),
    agents: [agent('c1', status)],
  })
  const ui = await monter($)
  expect(await ui.find({ key: 'voir:c1' })).toBeUndefined()
  expect(await ui.find({ key: 'stop:c1' })).toBeUndefined()
  await ui.unmount()
}

test("RV-R2-failed — agent terminé en échec des deux côtés : ni « voir » ni « arrêt »", ($, on) => sansGeste(on, $, 'failed'))
test("RV-R2-killed — agent arrêté des deux côtés : ni « voir » ni « arrêt »", ($, on) => sansGeste(on, $, 'killed'))
test("RV-R2-actif — témoin positif : le même agent en cours garde ses deux gestes", async ($, on) => {
  lab(on, {
    stdout: avec(s => { s.equipe.workers = [w({ kind: 'subagent', id: 'c1', role: 'vf-coder', task: 'tache-c1-close', etat: 'termine' })] }),
    agents: [agent('c1', 'running')],
  })
  const ui = await monter($)
  expect(await ui.find({ key: 'voir:c1' })).toBeDefined()
  expect(await ui.find({ key: 'stop:c1' })).toBeDefined()
  await ui.unmount()
})

// --- R3-1 : le fantôme compact -------------------------------------------------------------------------------------

test("RV-R3 — vue compacte, tous les agents terminés et non vivants : le fantôme « aucun agent en cours »", async ($, on) => {
  lab(on, { stdout: avec(s => { s.equipe.workers = [w({ kind: 'subagent', id: 'r0', role: 'vf-reviewer', task: 'revue-finie', etat: 'termine' })] }) })
  const ui = await monter($, COMPACT)
  expect(await ui.find({ type: 'Text', text: /aucun agent en cours/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /revue-finie/ })).toBeUndefined()
  await ui.unmount()
})

test("RV-R3b — vue compacte avec un agent vivant : pas de fantôme", async ($, on) => {
  lab(on, { stdout: avec(s => { s.equipe.workers = [w({ kind: 'subagent', id: 'a1', role: 'vf-coder', task: 'travail-vif' })] }) })
  const ui = await monter($, COMPACT)
  expect(await ui.find({ type: 'Text', text: /aucun agent en cours/ })).toBeUndefined()
  expect(await ui.find({ type: 'Text', text: /travail-vif/ })).toBeDefined()
  await ui.unmount()
})

// --- R11 : les statuts d'agent sont en français --------------------------------------------------------------------

const ANGLAIS = /\b(running|completed|failed|killed|pending|queued|cancell?ed|stopped)\b/i

test("RV-R11a — brief : chaque statut d'agent est dit en français, aucun mot anglais", async ($, on) => {
  const statuts = ['running', 'completed', 'failed', 'killed', 'pending']
  lab(on, { agents: statuts.map((s, i) => ({ id: `g${i}`, type: 'vf-coder', description: `tache ${i}`, status: s }) as AgentInfo) })
  await monter($)
  const r = await $.command.run({ command: 'vf-signal', args: 'brief' })
  const lignes = String(r.text).split('\n').filter(l => /tache \d/.test(l))
  expect(lignes.length).toBe(5)
  for (const l of lignes) expect(l).not.toMatch(ANGLAIS)
  expect(lignes.map(l => l.split(' · ')[1])).toEqual(['en cours', 'terminé', 'en échec', 'arrêté', 'en attente'])
})

test("RV-R11b — vue Équipe : aucun mot de statut anglais, un statut hors table reste tel quel dans le brief", async ($, on) => {
  lab(on, {
    stdout: avec(s => { s.equipe.workers = [w({ kind: 'subagent', id: 'c1', role: 'vf-coder', task: 'plan-sept' })] }),
    agents: [agent('c1', 'running'), agent('c2', 'hibernating')],
  })
  const ui = await monter($)
  expect(await ui.find({ type: 'Text', text: ANGLAIS })).toBeUndefined()
  await ui.unmount()
  const r = await $.command.run({ command: 'vf-signal', args: 'brief' })
  expect(String(r.text)).toContain('hibernating')
})
