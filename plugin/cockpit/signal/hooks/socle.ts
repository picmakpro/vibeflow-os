// L'appel du socle (P68-D-02, P68-D-14) : `node <plugin>/cockpit/scripts/vf-cockpit-signal.mjs <racine de session>`.
// Aucune option, aucun chemin de node configurable ; le lancement part de la racine du plugin, jamais de la racine du lab.
// Toute panne devient un message en clair, jamais une donnée affichée à moitié.

import type { EngineInterface } from 'claude-code'

import { oneLine } from './ds'
import type { Signal } from '../types'

const SCHEMA = 'vibeflow/cockpit-signal@1'
const DELAI_MS = 15000

export type Lecture = { signal: Signal } | { erreur: string }

export function argvEmetteur(pluginRoot: string, root: string): string[] {
  return ['node', `${pluginRoot.replace(/\/+$/, '')}/cockpit/scripts/vf-cockpit-signal.mjs`, root]
}

function classer(err: unknown): string {
  const e = err as { code?: unknown; message?: unknown } | null
  const trace = `${String(e?.code ?? '')} ${String(e?.message ?? '')}`
  return trace.includes('ENOENT') ? 'node introuvable dans le PATH' : 'émetteur sans réponse (délai dépassé)'
}

async function lire($: EngineInterface, pluginRoot: string, root: string): Promise<Lecture> {
  let ran
  try {
    ran = await $.process.run(argvEmetteur(pluginRoot, root), { cwd: pluginRoot, timeoutMs: DELAI_MS })
  } catch (err) {
    return { erreur: classer(err) }
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
  if (!Array.isArray(o.phases) || !Array.isArray(o.arbres) || !Array.isArray(o.missions) || typeof o.verrous !== 'object' || o.verrous === null) {
    return { erreur: "sortie de l'émetteur illisible" }
  }
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
