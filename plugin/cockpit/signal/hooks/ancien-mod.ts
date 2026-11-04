// L'ancien mod `vf-signal` vit hors dépôt, sous `<home>/.claude/mods/vf-signal` (P68-D-08).
// Détection en lecture seule : le mod embarqué le signale, il ne retire rien — le retrait est un geste humain.

import type { EngineInterface } from 'claude-code'

export const ANCIEN_MOD = '.claude/mods/vf-signal'

export const PHRASE_ANCIEN_MOD = 'ancien mod vf-signal détecté : deux panes possibles — le retrait est un geste humain, voir le README du module cockpit'

export async function ancienModPresent($: EngineInterface, home: string | undefined): Promise<boolean> {
  if (!home) return false
  const base = `${home.replace(/\/+$/, '')}/${ANCIEN_MOD}`
  for (const rel of ['hooks/hooks.json', '.claude-plugin/plugin.json']) {
    if (await $.fs.exists(`${base}/${rel}`).catch(() => false)) return true
  }
  return false
}
