// Le coût de l'émetteur suit l'attention (P68-D-41, arbitrage Samuel « Rafraîchir si pane ouverte (Recommandé) », AskUserQuestion,
// session principale Claude Code, 2026-11-04). Le rafraîchissement continu n'existe que pane ouverte ET session interactive ;
// sinon un lancement après un tour, au plus un par minute. Les gestes explicites (commande, brief) ne passent pas ici : ils rafraîchissent aussitôt.
// L'API ne notifie pas l'ouverture de la pane par la personne : la pane se lit à la demande (`$.ui.panes()`), un minuteur la sonde.

import type { EngineInterface } from 'claude-code'

import { PANE } from './band'
import { refreshLive, refreshSignalAuto } from './refresh'

const MINUTE = 60000

let interactif = false
let dernierLancement: number | undefined

/** Posé en session.start ; le dernier lancement est oublié. */
export function poserSession(est: boolean): void {
  interactif = est
  dernierLancement = undefined
}

export const estInteractive = (): boolean => interactif

/** Vrai si la session est interactive ET que la pane est posée et dessinée. */
export async function paneOuverte($: EngineInterface): Promise<boolean> {
  return interactif && (await $.ui.panes().catch(() => [])).some(p => p.id === PANE && p.isPlaced)
}

/** Note un lancement fait hors de cette règle (démarrage, geste explicite) : la minute repart de là. */
export async function noter($: EngineInterface): Promise<void> {
  dernierLancement = await $.clock.now()
}

/** Lancement automatique de l'émetteur : libre pane ouverte, sinon au plus un par minute. */
export async function emetteurAuto($: EngineInterface): Promise<void> {
  const now = await $.clock.now()
  if (!(await paneOuverte($)) && dernierLancement !== undefined && now - dernierLancement < MINUTE) return
  dernierLancement = now
  await refreshSignalAuto($)
}

/** Le minuteur de 10 s : sans effet pane fermée ; il n'est posé qu'en session interactive. */
export async function pulsation($: EngineInterface): Promise<void> {
  if (await paneOuverte($)) await refreshLive($)
}

/** Lancement lié à un appel Bash du travail (verrou, commit…) : seulement pane ouverte. */
export async function apresBash($: EngineInterface): Promise<void> {
  if (await paneOuverte($)) await refreshSignalAuto($)
}
