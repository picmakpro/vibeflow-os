// L'appel du socle (P68-D-02, P68-D-14) : `node <plugin>/cockpit/scripts/vf-cockpit-signal.mjs <racine de session>`.
// Aucune option, aucun chemin de node configurable ; le lancement part de la racine du plugin, jamais de la racine du lab.
// Toute panne devient un message en clair, jamais une donnée affichée à moitié.

import type { EngineInterface } from 'claude-code'

import { oneLine } from './ds'
import type { Signal } from '../types'

const SCHEMA = 'vibeflow/cockpit-signal@1'

export type Lecture = { signal: Signal } | { erreur: string }

export function argvEmetteur(pluginRoot: string, root: string): string[] {
  return ['node', `${pluginRoot.replace(/\/+$/, '')}/cockpit/scripts/vf-cockpit-signal.mjs`, root]
}

const DELAI = /timed? ?out|timeout|délai/i

/** Dit un rejet de `process.run` : node absent, vrai délai, ou autre échec nommé tel quel (jamais un délai par défaut). */
export function classerEchec(err: unknown, sujet: string): string {
  const e = err as { code?: unknown; message?: unknown } | null
  // l'engine préfixe le rejet de « <plugin>: $.process.run: » : bruit, pas information
  const trace = oneLine(`${String(e?.code ?? '')} ${String(e?.message ?? '')}`).replace(/^[\w-]+: \$\.[\w.]+: /, '')
  if (trace.includes('ENOENT')) return 'node introuvable dans le PATH'
  if (DELAI.test(trace)) return `${sujet} sans réponse (délai dépassé)`
  return `${sujet} non lancé (${trace.slice(0, 60)})`
}

const obj = (x: unknown): x is Record<string, unknown> => typeof x === 'object' && x !== null && !Array.isArray(x)
const tab = (x: unknown): x is unknown[] => Array.isArray(x)
const chaines = (o: Record<string, unknown>, ...cles: string[]) => cles.every(k => typeof o[k] === 'string')
const nombres = (o: Record<string, unknown>, ...cles: string[]) => cles.every(k => typeof o[k] === 'number')

/** La forme que les vues lisent sans garde : un signal au bon schéma mais incomplet est « illisible », jamais un rendu qui lève. */
function complet(o: Record<string, unknown>): boolean {
  const { layout, phases, jalons, missions, verrous, arbres, equipe } = o
  return (
    obj(layout) &&
    tab(phases) && phases.every(p => obj(p) && chaines(p, 'key', 'n', 'nom', 'libelle') && obj(p.avancement) && obj(p.avancement.plans) && nombres(p.avancement.plans, 'faits', 'total')) &&
    tab(jalons) && jalons.every(j => obj(j) && chaines(j, 'key', 'texte') && tab(j.phases)) &&
    tab(missions) && missions.every(m => obj(m) && chaines(m, 'nom', 'libelle') && (m.noeuds === undefined || (tab(m.noeuds) && m.noeuds.every(n => obj(n) && chaines(n, 'id', 'step', 'status') && tab(n.deps))))) &&
    obj(verrous) && tab(verrous.liste) && verrous.liste.every(k => obj(k) && chaines(k, 'scope')) &&
    tab(arbres) && arbres.every(a => obj(a) && chaines(a, 'label', 'branche') && (a.phaseActive === null || obj(a.phaseActive)) && (a.retard === null || (obj(a.retard) && chaines(a.retard, 'base')))) &&
    obj(equipe) && tab(equipe.workers) && equipe.workers.every(w => obj(w) && chaines(w, 'id'))
  )
}

async function lire($: EngineInterface, pluginRoot: string, root: string): Promise<Lecture> {
  let ran
  try {
    ran = await $.process.run(argvEmetteur(pluginRoot, root), { cwd: pluginRoot, timeoutMs: 15000 })
  } catch (err) {
    return { erreur: classerEchec(err, 'émetteur') }
  }
  if (ran.exitCode !== 0) return { erreur: `émetteur en échec (code ${ran.exitCode})` }
  if (ran.isStdoutTruncated) return { erreur: "sortie de l'émetteur tronquée" }
  let brut: unknown
  try {
    brut = JSON.parse(ran.stdout)
  } catch {
    return { erreur: "sortie de l'émetteur illisible" }
  }
  const o = brut as Record<string, unknown> | null
  if (!o || typeof o !== 'object') return { erreur: "sortie de l'émetteur illisible" }
  if (o.schema !== SCHEMA) return { erreur: `schéma inattendu : ${oneLine(String(o.schema)).slice(0, 40)}` }
  // phases, arbres, missions manquants ou mal formés : même réponse que tout signal incomplet
  if (!complet(o)) return { erreur: "sortie de l'émetteur illisible" }
  return { signal: o as unknown as Signal }
}

let enVol: Promise<Lecture> | null = null

/** Une seule exécution à la fois : un second appel pendant le vol reçoit la même promesse. */
export function lireSignal($: EngineInterface, pluginRoot: string, root: string): Promise<Lecture> {
  if (enVol) return enVol
  const p = lire($, pluginRoot, root).finally(() => {
    enVol = null
  })
  enVol = p
  return p
}
