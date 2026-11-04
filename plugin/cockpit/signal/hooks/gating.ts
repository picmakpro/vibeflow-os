// Gating du mod embarqué (P68-D-18) : il ne s'affiche que si le module `cockpit` est installé.
// Le registre `scripts/.vibeflow-installed` (une ligne `module=version`) se lit dans le scope projet
// (`<root>/.claude/scripts/`) puis dans le scope user (`<home>/.claude/scripts/`). Lecture seule ;
// toute erreur de lecture vaut « absent ».

import type { EngineInterface } from 'claude-code'

const REGISTRE = '.claude/scripts/.vibeflow-installed'

async function porteCockpit($: EngineInterface, base: string | undefined): Promise<boolean> {
  if (!base) return false
  const texte = await $.fs.read(`${base.replace(/\/+$/, '')}/${REGISTRE}`).catch(() => null)
  return typeof texte === 'string' && texte.split('\n').some(l => l.trim().startsWith('cockpit='))
}

export async function cockpitInstalle($: EngineInterface, root: string | undefined, home: string | undefined): Promise<boolean> {
  return (await porteCockpit($, root)) || (await porteCockpit($, home))
}
