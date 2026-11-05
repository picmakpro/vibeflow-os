// Les couleurs de la pane (VFSG-07 ; P68-D-06) : le seul lieu d'une valeur de couleur du mod.
// Direction « Graphite » de DESIGN.md : monochrome, la couleur ne porte que le statut. Valeurs recopiées de DESIGN.md
// (§ 2, colonnes Sombre et Clair) : la suite statique (M10) rougit si l'un ou l'autre dérive, et M9 si une vue en porte une.
// Correspondance : st-done = --recent, st-active = --sev-medium, st-todo = --text-4, st-blocked = --sev-high,
// text, text-2, text-3, text-4 = les variables du même nom.

import type { Theme } from '../types'

export const TOKENS = {
  sombre: {
    'st-done': '#9ece6a',
    'st-active': '#ffe08a',
    'st-todo': '#828282',
    'st-blocked': '#ff9aa8',
    'text': '#ececec',
    'text-2': '#c6c6c6',
    'text-3': '#a8a8a8',
    'text-4': '#828282',
  },
  clair: {
    'st-done': '#009e5a',
    'st-active': '#b88100',
    'st-todo': '#666666',
    'st-blocked': '#f2384a',
    'text': '#161616',
    'text-2': '#3f3f3f',
    'text-3': '#595959',
    'text-4': '#666666',
  },
} as const

export type Palette = { readonly [K in keyof (typeof TOKENS)['sombre']]: string }

export const palette = (theme: Theme): Palette => TOKENS[theme === 'clair' ? 'clair' : 'sombre']

/** Le thème de la personne, lu dans les lignes de `$.config.list()` : une valeur de la ligne `theme` qui contient « light » donne le clair, tout le reste le sombre. */
export function themeDe(rows: readonly { key: string; value: unknown }[]): Theme {
  const v = rows.find(r => r.key === 'theme')?.value
  return typeof v === 'string' && /light/i.test(v) ? 'clair' : 'sombre'
}

const FAIT = /^(done|fait|complete|completed|skipped|skip)$/i
const ACTIF = /^(running|en-cours|a-recetter|in[-_ ]?progress|active|started)$/i
const BLOQUE = /^(failed|blocked|error|red)$/i

/** La couleur d'un statut : fait, en cours (« à recetter » compris), bloqué ; tout le reste (à faire, abandonnée, inconnu, terminé) est grisé. */
export function couleurEtat(etat: string | null | undefined, p: Palette): string {
  const e = etat ?? ''
  if (FAIT.test(e)) return p['st-done']
  if (ACTIF.test(e)) return p['st-active']
  if (BLOQUE.test(e)) return p['st-blocked']
  return p['st-todo']
}
