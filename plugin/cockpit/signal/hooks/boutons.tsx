// Les boutons humains de la pane : élaguer un verrou périmé, copier la commande de reprise, compacter, rafraîchir.
// Chaque geste est borné et lancé par une personne ; aucun n'écrit dans le planning.

import type { EngineInterface } from 'claude-code'

import { elaguer, resoudreDriverLock } from './actions'
import type { UI } from './ds'
import type { Loop, SignalVerrou, Usage } from '../types'

type Args = { stale: SignalVerrou | null; l: Loop; u: Usage | null; home: string | undefined; refresh: () => Promise<void> }

export async function boutons($: EngineInterface, ui: UI, { stale, l, u, home, refresh }: Args): Promise<JSX.Element> {
  const { Box, Button } = ui
  const root = await $.session.root().catch(() => undefined)
  const script = stale && root ? await resoudreDriverLock($, $.plugin.root, root, home) : null
  const ws = stale?.ws ?? null
  return (
    <Box gap={1} flexWrap="wrap">
      {stale && script && root ? (
        <Button
          key="elaguer"
          hotkey="e"
          variant="primary"
          onPress={async () => {
            await elaguer($, script, ws, root)
            await refresh()
          }}
        >
          élaguer le verrou périmé
        </Button>
      ) : null}
      {stale ? (
        <Button
          key="takeover"
          hotkey="t"
          plain
          dimColor
          onPress={press =>
            void $.ui
              .copy({ text: `bash ${script ?? 'driver-lock.sh'} takeover --owner=<id>${ws ? ` --ws=${ws}` : ''}`, surface: press.surface })
              .then(() => $.ui.toast('commande takeover copiée'))
          }
        >
          copier takeover
        </Button>
      ) : null}
      {u?.percent != null && u.percent >= 85 && !l.isWorking ? (
        <Button
          key="compacter"
          hotkey="c"
          plain
          dimColor
          onPress={() => void $.session.compact().then(() => $.ui.toast('compaction lancée')).catch(() => $.ui.toast('compaction refusée (un tour tourne ?)'))}
        >
          compacter
        </Button>
      ) : null}
      <Button key="rafraichir" hotkey="r" plain dimColor onPress={() => void refresh()}>
        rafraîchir
      </Button>
    </Box>
  )
}
