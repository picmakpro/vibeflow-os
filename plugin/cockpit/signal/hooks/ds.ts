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
  // une horloge décalée (celle du socle d'un autre processus) peut rendre un âge négatif : on n'écrit jamais « -4 s » (N1)
  seconds = Math.max(0, seconds)
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

/** L'avancement d'une phase, dit en français (les états de `phaseActive.etat` ; le socle les libelle de même). Inconnu : null, rien d'inventé. */
const LIBELLE_ETAT: Record<string, string> = { 'a-faire': 'à faire', 'en-cours': 'en cours', 'a-recetter': 'à recetter', fait: 'fait' }
export const libelleEtat = (etat: string | null | undefined): string | null => LIBELLE_ETAT[etat ?? ''] ?? null

/** Le statut d'un nœud de DAG, dit en français ; un statut hors table reste tel que le DAG l'écrit. La couleur reste celle des tokens. */
const STATUT_NOEUD: Record<string, string> = {
  blocked: 'bloqué', failed: 'en échec', error: 'en erreur', red: 'rouge', pending: 'en attente', ready: 'prêt',
  running: 'en cours', inprogress: 'en cours', started: 'en cours', active: 'en cours', done: 'fait', complete: 'fait', completed: 'fait', skipped: 'ignoré', skip: 'ignoré',
}
export const statutNoeud = (status: string): string => STATUT_NOEUD[status.trim().toLowerCase().replace(/[-_ ]+/g, '')] ?? status

/** Le statut d'un agent de `$.agent.list()`, dit en français ; un statut hors table reste tel que l'engine l'écrit (R11). */
const STATUT_AGENT: Record<string, string> = {
  running: 'en cours', pending: 'en attente', queued: 'en attente', completed: 'terminé', failed: 'en échec', killed: 'arrêté', stopped: 'arrêté', cancelled: 'annulé', canceled: 'annulé',
}
export const statutAgent = (status: string): string => STATUT_AGENT[status.trim().toLowerCase()] ?? status

/** Le type d'un travailleur de `who@2` (ou son rôle quand il n'en est qu'un nom de temps), dit en français ; hors table, tel que le socle l'écrit (N3). */
const TYPE_TRAVAILLEUR: Record<string, string> = { lock: 'verrou', 'dag-node': 'nœud', exec: 'exécution', session: 'session', subagent: 'sous-agent', registered: 'enregistré' }
export const libelleType = (type: string): string => TYPE_TRAVAILLEUR[type.trim().toLowerCase()] ?? type

/** Le nom d'un arbre de travail : son chemin relatif au dépôt tel quel, le nom de son dossier s'il est hors du dépôt (`../…` ou absolu). */
export function nomArbre(label: string): string {
  if (!/^(\.\.(\/|$)|\/)/.test(label)) return label
  return label.split('/').filter(Boolean).pop() ?? label
}

/** Le titre court d'un jalon : son premier segment (« — ») qui n'est pas une plage de phases, sans markdown, coupé entre deux mots. */
export function titreCourt(texte: string, max = 40): string {
  const segs = oneLine(texte.replace(/\*\*|__|`/g, '')).split(' — ').filter(Boolean)
  const t = segs.find(x => !/^phases?\b/i.test(x)) ?? segs[0] ?? ''
  if (t.length <= max) return t
  const coupe = t.slice(0, max + 1).lastIndexOf(' ')
  return `${t.slice(0, coupe > 0 ? coupe : max).trimEnd()}…`
}
