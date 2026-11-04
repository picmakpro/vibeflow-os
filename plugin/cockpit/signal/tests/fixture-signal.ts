import { mock } from 'claude-code/testing'
import type { AgentInfo, On } from 'claude-code'

// Données d'essai partagées par les tests de 68-05 à 68-08 : un `signal@1` à la forme réelle de l'émetteur
// (vf-cockpit-signal.mjs, mesuré sur ce dépôt le 2026-11-04) et un faux lab qui le sert à `process.run`.

const VIE_MORTE = { tenu: false, stale: null, progressAgeS: null, ttl: null }

export const SIGNAL = {
  schema: 'vibeflow/cockpit-signal@1',
  at: '2026-11-04T05:54:40.611Z',
  root: '/lab',
  projet: 'Lab d essai',
  layout: { forme: 'partitionne', actif: 'fiabilite' },
  phases: [
    {
      key: 'fiabilite|68', n: '68', ws: 'fiabilite', nom: 'Embarquer le mod', fait: false, libelle: 'en cours',
      avancement: { version: 2, etat: 'en-cours', plans: { faits: 5, total: 13 }, correctifs: 0, mission: { nom: 'MISSION-68', etat: 'abandonnee', vie: VIE_MORTE }, reste: [] },
    },
    {
      key: 'fiabilite|69', n: '69', ws: 'fiabilite', nom: 'Suivi du travail', fait: false, libelle: 'à recetter',
      avancement: { version: 2, etat: 'a-recetter', plans: { faits: 4, total: 4 }, correctifs: 0, mission: null, reste: ['recette'] },
    },
    {
      key: 'fiabilite|70', n: '70', ws: 'fiabilite', nom: 'Cockpit inconnu', fait: false, libelle: 'en cours',
      avancement: { version: 2, etat: 'en-cours', plans: { faits: 1, total: 3 }, correctifs: 0, mission: { nom: 'MISSION-70', etat: 'inconnu', vie: null }, reste: [] },
    },
  ],
  jalons: [{ key: 'v1', icone: '🚧', texte: 'Jalon d essai', ws: 'fiabilite', phases: ['fiabilite|68', 'fiabilite|69'] }],
  missions: [
    {
      nom: 'MISSION-68', fichier: '.planning/workstreams/fiabilite/MISSION-68.dag.json', phaseKey: 'fiabilite|68', ws: 'fiabilite',
      etat: 'abandonnee', libelle: 'abandonnée, nœuds non refermés', vie: VIE_MORTE,
      noeuds: [
        { id: 'a', status: 'done', step: 'cadrage', stage: '', deps: [] },
        { id: 'b', status: 'running', step: 'exécution', stage: '', deps: ['a'] },
        { id: 'c', status: 'pending', step: 'revue', stage: '', deps: ['b'] },
      ],
    },
    { nom: 'MISSION-70', fichier: '.planning/workstreams/fiabilite/MISSION-70.dag.json', phaseKey: 'fiabilite|70', ws: 'fiabilite', etat: 'inconnu', libelle: 'état inconnu', vie: null, noeuds: [] },
  ],
  verrous: { etat: 'lue', plat: false, liste: [{ ws: 'fiabilite', scope: 'phase', phase: '68', tenu: true, stale: false, ageS: 51, ttl: 1800, progressAgeS: 4601, owner: 'mgr68' }] },
  arbres: [
    {
      label: 'arbre principal', branche: 'main', principal: true, courant: false,
      phaseActive: { key: 'fiabilite|69', n: '69', nom: 'Suivi du travail', etat: 'a-recetter' },
      retard: { base: 'main', main: 0, origin: 0, fetchAgeS: 7200 },
    },
    {
      label: '.claude/worktrees/phase-68', branche: 'feat/phase-68', principal: false, courant: true,
      phaseActive: { key: 'fiabilite|68', n: '68', nom: 'Embarquer le mod', etat: 'en-cours' },
      retard: { base: 'main', main: 3, origin: 0, fetchAgeS: 7200 },
    },
    { label: '.claude/worktrees/libre', branche: 'feat/libre', principal: false, courant: false, phaseActive: null, retard: { base: 'main', main: 0, origin: 0, fetchAgeS: 7200 } },
  ],
  equipe: { schema: 'vibeflow/cockpit-who@2', at: '2026-11-04T05:54:40.611Z', root: '/lab', trees: ['arbre principal'], fresh: 180, fenetre: 86400, busy: false, workers: [], sources: {} },
}

export type Signal = typeof SIGNAL

/** Une copie profonde de `SIGNAL`, modifiée par `f`. */
export function avec(f: (s: any) => void): string {
  const copie = JSON.parse(JSON.stringify(SIGNAL))
  f(copie)
  return JSON.stringify(copie)
}

export type Appel = { argv: readonly string[]; cwd: string | undefined; timeoutMs: number | undefined }
export type LabSignal = { appels: Appel[]; emetteur: () => Appel[] }

type Opts = { stdout?: string; rejet?: { code?: string; message: string }; exitCode?: number; tronque?: boolean; agents?: AgentInfo[]; delaiMs?: number }

/** Un lab : le registre porte `cockpit=`, l'émetteur (argv[0] = node) répond `stdout`, tout le reste reste vide. */
export function labSignal(on: On, o: Opts = {}): LabSignal {
  const appels: Appel[] = []
  mock.clock(on, { now: 1_000_000 })
  mock.env(on, { HOME: '/home/user' })
  on('command.register', () => ({ value: { command: 'vf-signal' } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('agent.list', () => ({ value: o.agents ?? [] }))
  on('session.root', () => ({ value: '/lab' }))
  on('session.usage', () => ({ value: { startedAt: 0, context: { window: 200000, tokens: 50000, percent: 25 }, rateLimits: [], cost: { usd: 0.42 } } }))
  on('fs.exists', () => ({ value: false }))
  on('fs.read', (_, e) => {
    if (String(e.path).endsWith('.vibeflow-installed')) return { value: 'cockpit=v1.2.0\n' }
    throw new Error('ENOENT')
  })
  on('fs.list', () => ({ value: [] }))
  on('process.run', async (_, e) => {
    const argv = e.argv as readonly string[]
    if (argv[0] !== 'node') return { value: { exitCode: 0, stdout: '', stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
    appels.push({ argv, cwd: e.cwd, timeoutMs: e.timeoutMs })
    if (o.delaiMs) await new Promise(r => setTimeout(r, o.delaiMs))
    if (o.rejet) throw Object.assign(new Error(o.rejet.message), o.rejet.code ? { code: o.rejet.code } : {})
    return { value: { exitCode: o.exitCode ?? 0, stdout: o.stdout ?? JSON.stringify(SIGNAL), stderr: '', isStdoutTruncated: o.tronque === true, isStderrTruncated: false } }
  })
  return { appels, emetteur: () => appels }
}
