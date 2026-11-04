// Les boutons humains de la pane : élaguer un verrou périmé, copier la commande de reprise, compacter, rafraîchir.
// Chaque geste est borné et lancé par une personne ; aucun n'écrit dans le planning.

import { atom, read, update } from 'claude-code'
import type { EngineInterface } from 'claude-code'

import { elaguer, ouvrirCockpit, resoudreDriverLock, resoudreLanceur } from './actions'
import { C } from './ds'
import type { UI } from './ds'
import type { Loop, SignalVerrou, Usage } from '../types'

const cockpitUrl = atom({ plugin: 'vibeflow', key: 'cockpitUrl' } as const, null)
const cockpitErreur = atom({ plugin: 'vibeflow', key: 'cockpitErreur' } as const, null)

type Args = { stale: SignalVerrou | null; l: Loop; u: Usage | null; home: string | undefined; refresh: () => Promise<void> }

export async function boutons($: EngineInterface, ui: UI, { stale, l, u, home, refresh }: Args): Promise<JSX.Element> {
  const { Box, Button, Text } = ui
  const [url, erreur] = await Promise.all([read($, cockpitUrl), read($, cockpitErreur)])
  const root = await $.session.root().catch(() => undefined)
  const script = stale && root ? await resoudreDriverLock($, $.plugin.root, root, home) : null
  const ws = stale?.ws ?? null
  const ouvrir = async () => {
    const res = root ? await ouvrirCockpit($, await resoudreLanceur($, $.plugin.root, root, home), root) : { erreur: 'cockpit : racine de session inconnue' }
    await update($, cockpitUrl, () => ('url' in res ? res.url : null))
    await update($, cockpitErreur, () => ('erreur' in res ? res.erreur : null))
    await $.ui.toast('url' in res ? `cockpit : ${res.url}` : res.erreur)
  }
  return (
    <Box flexDirection="column">
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
        <Button key="ouvrir-cockpit" hotkey="o" plain dimColor onPress={ouvrir}>
          Ouvrir le cockpit
        </Button>
        <Button key="rafraichir" hotkey="r" plain dimColor onPress={() => void refresh()}>
          rafraîchir
        </Button>
      </Box>
      {url ? <Text color={C.fg2} wrap="wrap">{`cockpit : ${url}`}</Text> : null}
      {erreur ? <Text color={C.human} wrap="wrap">{erreur}</Text> : null}
    </Box>
  )
}
