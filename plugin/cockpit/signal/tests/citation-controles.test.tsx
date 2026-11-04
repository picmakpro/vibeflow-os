import { expect, test } from 'claude-code/testing'
import type { On } from 'claude-code'

import { avec } from './fixture-signal'
import { BAND, CONTROLES, PANE, labFix, monter } from './lab-fix'

// Correction ciblée ST-3, ST-4 et ST-6 (68-FIX-MOD ; ADR-031) : toute valeur interpolée dans une commande destinée à un
// shell est citée ; toute chaîne affichée est débarrassée des caractères de contrôle, quelle qu'en soit la source ;
// le toast d'élagage dit ce que le script a rendu. Identifiants préfixés FX-.

const VERROU = { ws: 'fiabilite', scope: 'phase', phase: '68', tenu: true, stale: true, ageS: 97000, ttl: 1800, progressAgeS: null, owner: 'mgr68' }
const avecVerrou = (v: object = {}) => avec(s => { s.verrous.liste = [{ ...VERROU, ...v }] })
const SCRIPT = /driver-lock\.sh$/

// --- ST-3 : la commande copiée -------------------------------------------------------------------------------------

/** Découpe une commande comme `bash` le ferait, mais lève sur tout métacaractère non cité : ce qui reste est ce qu'il exécuterait. */
function mots(cmd: string): string[] {
  const texte = cmd.replace('--owner=<id>', '--owner=ID') // le seul gabarit voulu : à remplacer par la personne
  const out: string[] = []
  let cur = ''
  let dedans = false
  let ouvert = false
  for (let i = 0; i < texte.length; i++) {
    const c = texte[i]!
    if (dedans) { if (c === "'") dedans = false; else cur += c; continue }
    if (c === "'") { dedans = true; ouvert = true; continue }
    if (c === '\\' && texte[i + 1] === "'") { cur += "'"; ouvert = true; i++; continue } // `\'` hors guillemets : une apostrophe littérale
    if (c === ' ') { if (ouvert || cur) out.push(cur); cur = ''; ouvert = false; continue }
    if (/[;&|<>()$`\\"*?#!{}~[\]\n\t]/.test(c)) throw new Error(`métacaractère non cité : ${JSON.stringify(c)} dans ${cmd}`)
    cur += c
    ouvert = true
  }
  if (dedans) throw new Error(`guillemet simple non fermé : ${cmd}`)
  if (ouvert || cur) out.push(cur)
  return out
}

test('FX-3a — le découpeur du témoin voit un métacaractère non cité et un guillemet ouvert (il sait rougir)', () => {
  expect(() => mots('bash a;b')).toThrow()
  expect(() => mots("bash 'a")).toThrow()
  expect(mots("bash 'a b' --ws='x'\\''y'")).toEqual(['bash', 'a b', '--ws=x\'y'])
})

const WS_HOSTILE = "a b';touch /tmp/pwn;`id`$(id) #"

test('FX-3b — copier takeover : chemin à espace et ws hostile donnent une commande qui n’exécute que le script attendu', async ($, on) => {
  const lab = labFix(on, { root: '/lab dir', scripts: /^\/lab dir\/\.claude\/scripts\/driver-lock\.sh$/ })
  lab.emetteur.stdout = avecVerrou({ ws: WS_HOSTILE })
  const ui = await monter($)
  await ui.press({ key: 'takeover' })
  expect(lab.copies.length).toBe(1)
  expect(mots(lab.copies[0]!)).toEqual(['bash', '/lab dir/.claude/scripts/driver-lock.sh', 'takeover', '--owner=ID', `--ws=${WS_HOSTILE}`])
  await ui.unmount()
})

test('FX-3c — copier takeover : sans ws ni caractère spécial, la commande reste lisible (pas de guillemets inutiles)', async ($, on) => {
  const lab = labFix(on, { scripts: SCRIPT })
  lab.emetteur.stdout = avecVerrou({ ws: 'fiabilite' })
  const ui = await monter($)
  await ui.press({ key: 'takeover' })
  expect(lab.copies[0]).toMatch(/^bash \S+\/conductor\/scripts\/driver-lock\.sh takeover --owner=<id> --ws=fiabilite$/)
  await ui.unmount()
})

// --- ST-6 : le toast d'élagage -------------------------------------------------------------------------------------

test("FX-6c — toast d'élagage : « recover · exit <code> · <sortie> », la sortie bornée à 120 caractères", async ($, on) => {
  const lab = labFix(on, { scripts: SCRIPT })
  lab.emetteur.stdout = avecVerrou()
  lab.bash = { exitCode: 3, stdout: `  ${'x'.repeat(200)}\n` }
  const ui = await monter($)
  await ui.press({ key: 'elaguer' })
  expect(lab.toasts).toContain(`recover · exit 3 · ${'x'.repeat(120)}`)
  lab.bash = { exitCode: 0, stdout: 'verrou élagué\n' }
  await ui.press({ key: 'elaguer' })
  expect(lab.toasts).toContain('recover · exit 0 · verrou élagué')
  await ui.unmount()
})

test("FX-6d — toast d'élagage : script qui ne démarre pas", async ($, on) => {
  const lab = labFix(on, { scripts: SCRIPT })
  lab.emetteur.stdout = avecVerrou()
  lab.bash = { rejet: 'EACCES: spawn bash' }
  const ui = await monter($)
  await ui.press({ key: 'elaguer' })
  expect(lab.toasts).toContain('recover : driver-lock.sh ne démarre pas')
  await ui.unmount()
})

// --- ST-4 : aucun caractère de contrôle affiché, quelle que soit la source -----------------------------------------

const HOSTILE = 'rouge\u001b[31m fin\u001b]0;titre\u0007 c1\u009b31m bel\u0007'
const HOSTILE_NL = `${HOSTILE}\n- faux verrou : intrus`

async function brief($: any): Promise<string> {
  const r = await $.command.run({ command: 'vf-signal', args: 'brief' })
  return String(r.text)
}
function refuse(on: On) {
  on('tool.call', () => ({ deny: HOSTILE_NL }))
}

const SOURCES: [string, ($: any, on: On) => Promise<string>][] = [
  ["toast d'élagage (stdout du script)", async ($, on) => {
    const lab = labFix(on, { scripts: SCRIPT })
    lab.emetteur.stdout = avecVerrou()
    lab.bash = { stdout: HOSTILE_NL }
    const ui = await monter($)
    await ui.press({ key: 'elaguer' })
    await ui.unmount()
    return lab.toasts.find(t => t.startsWith('recover')) ?? ''
  }],
  ['brief : agent.description', async ($, on) => {
    labFix(on, { agents: [{ id: 'a1', type: 'vf-coder', description: HOSTILE_NL, status: 'running' }] })
    await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })
    return brief($)
  }],
  ['brief : raison de refus d’un hook', async ($, on) => {
    labFix(on)
    refuse(on)
    await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })
    await $.tool.call({ tool: 'Bash', tool_use_id: 'u1', command: 'ls' })
    return brief($)
  }],
  ['brief : projet du signal', async ($, on) => {
    labFix(on).emetteur.stdout = avec(s => { s.projet = HOSTILE_NL })
    await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })
    return brief($)
  }],
  ['brief : propriétaire du verrou', async ($, on) => {
    labFix(on).emetteur.stdout = avecVerrou({ owner: HOSTILE_NL })
    await $.session.start({ cwd: '/lab', surface: 'terminal', isInteractive: true })
    return brief($)
  }],
  ['bandeau : propriétaire du verrou périmé', async ($, on) => {
    labFix(on).emetteur.stdout = avecVerrou({ owner: HOSTILE })
    const ui = await monter($, BAND)
    const t = (await ui.find({ type: 'Text', text: /verrou périmé de/ }))?.text ?? ''
    await ui.unmount()
    return t
  }],
  ['pane : propriétaire du verrou périmé', async ($, on) => {
    labFix(on).emetteur.stdout = avecVerrou({ owner: HOSTILE })
    const ui = await monter($, PANE)
    const t = (await ui.find({ type: 'Text', text: /rouge/ }))?.text ?? ''
    await ui.unmount()
    return t
  }],
  ['pane : nom de la phase', async ($, on) => {
    labFix(on).emetteur.stdout = avec(s => { s.arbres.find((a: any) => a.courant).phaseActive.nom = HOSTILE_NL })
    const ui = await monter($, PANE)
    const t = (await ui.find({ type: 'Text', text: /rouge/ }))?.text ?? ''
    await ui.unmount()
    return t
  }],
]
for (const [i, [nom, jouer]] of SOURCES.entries()) {
  test(`FX-4a${i} — ${nom} : ESC [ et ESC ] disparaissent, le texte visible reste, aucune ligne n'est forgée`, async ($, on) => {
    const texte = await jouer($, on)
    expect(texte).toContain('rouge')
    expect(texte.replace(/\n/g, '')).not.toMatch(CONTROLES)
    expect(texte).not.toContain('\n- faux verrou')
  })
}
