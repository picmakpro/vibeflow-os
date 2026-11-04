// Ce que la pane dit : glyphes, étapes, libellés, durées. Aucune couleur ici : elles vivent dans tokens.ts (P68-D-17).
// Mono, minuscules, angle droit, pas d'emoji.

import type { EngineInterface } from 'claude-code'

import type { Stage, View } from '../types'

/** Glyphes : le curseur bloc, le point qui avance, l'étape à venir. */
export const G = { done: '■', current: '▶', todo: '·', human: '■', rail: '──', branch: '↳' } as const

export const STAGES: readonly Stage[] = ['cadrer', 'planifier', 'executer', 'verifier', 'clore']

export const STAGE_LABEL: Record<Stage, string> = {
  cadrer: 'cadrer',
  planifier: 'planifier',
  executer: 'exécuter',
  verifier: 'vérifier',
  clore: 'clore',
}

export const VIEWS: readonly View[] = ['mission', 'equipe', 'macro']
export const VIEW_LABEL: Record<View, string> = { mission: 'mission', equipe: 'équipe', macro: 'macro' }

/** La table d'éléments de la surface qui dessine (Box, Text, Button…). */
export type UI = ReturnType<EngineInterface['ui']['resolve']>

export function cut(s: string, n: number): string {
  const max = Math.max(4, n)
  return s.length > max ? s.slice(0, max - 1) + '…' : s
}

export function age(seconds: number): string {
  if (seconds < 90) return `${Math.round(seconds)} s`
  if (seconds < 5400) return `${Math.round(seconds / 60)} min`
  if (seconds < 172800) return `${Math.round(seconds / 3600)} h`
  return `${Math.round(seconds / 86400)} j`
}

export function since(now: number, at: number): string {
  return age(Math.max(0, now - at) / 1000)
}

// Caractères de contrôle : C0 (ESC, BEL, saut de ligne…), DEL, C1, séparateurs de ligne Unicode. L'engine refuse la pane
// entière quand un texte en porte un : une seule valeur hostile éteindrait l'affichage.
const CONTROLES = /[\u0000-\u001f\u007f-\u009f\u2028\u2029]/g

/** La chaîne sans caractère de contrôle (chacun devient une espace) ; ne touche ni aux espaces ni à l'indentation. */
export function sansControle(s: string): string {
  return s.replace(CONTROLES, ' ')
}

/** Une ligne : sans contrôle, espaces repliées et bornées. */
export function oneLine(s: string): string {
  return sansControle(s).replace(/\s+/g, ' ').trim()
}

/** Une copie de la valeur dont chaque chaîne, à toute profondeur, est passée par `sansControle` (le socle, la liste des agents). */
export function nettoyer<T>(v: T): T {
  if (typeof v === 'string') return sansControle(v) as T
  if (Array.isArray(v)) return v.map(nettoyer) as T
  if (v !== null && typeof v === 'object') return Object.fromEntries(Object.entries(v).map(([k, x]) => [k, nettoyer(x)])) as T
  return v
}
