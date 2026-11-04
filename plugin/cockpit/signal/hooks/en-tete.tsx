// L'en-tête de la pane (VFSG-05, VFSG-06 ; P68-D-04, P68-D-05, P68-D-30) : ce que dit `signal@1`, jamais le STATE (P68-D-17).
// Chaque ligne est un seul `Text` : les libellés viennent du socle, ils ne sont pas recopiés ici.

import { atom, read } from 'claude-code'
import type { EngineInterface } from 'claude-code'

import { jalonCourant } from './derive'
import { G, age, oneLine, type UI } from './ds'
import { couleurEtat, palette } from './tokens'
import type { Signal, SignalArbre, SignalRetard } from '../types'

const signal = atom({ plugin: 'vibeflow', key: 'signal' } as const, null)
const signalErreur = atom({ plugin: 'vibeflow', key: 'signalErreur' } as const, null)
const theme = atom({ plugin: 'vibeflow', key: 'theme' } as const, 'sombre')

const courant = (s: Signal): SignalArbre | null => s.arbres.find(a => a.courant) ?? null

/** « phase <n> <nom> » et son libellé d'avancement (sans parenthèses) pour un arbre, ou « aucune phase en cours ». */
function phaseParts(s: Signal, a: SignalArbre): { debut: string; lib: string | null } {
  const p = a.phaseActive
  if (!p) return { debut: 'aucune phase en cours', lib: null }
  const lib = s.phases.find(x => x.key === p.key)?.libelle
  return { debut: `phase ${oneLine(p.n)} ${oneLine(p.nom)}`, lib: lib ? oneLine(lib) : null }
}

/** « phase <n> <nom> (<libellé d'avancement>) » ou « aucune phase en cours » pour un arbre. */
function phaseDe(s: Signal, a: SignalArbre): string {
  const { debut, lib } = phaseParts(s, a)
  return lib ? `${debut} (${lib})` : debut
}

const pos = (n: number | null | undefined): n is number => typeof n === 'number' && n > 0

/** « en retard de N commit(s) sur <base>, dernier fetch il y a X [· origin/<base> local : en retard de M] », ou null. */
function retardDe(r: SignalRetard | null): string | null {
  if (!r) return null
  const base = oneLine(r.base)
  const fetch = r.fetchAgeS === null ? 'aucun fetch connu' : `dernier fetch il y a ${age(r.fetchAgeS)}`
  const local = pos(r.origin) ? `origin/${base} local : en retard de ${r.origin}` : null
  const main = pos(r.main) ? `en retard de ${r.main} ${r.main === 1 ? 'commit' : 'commits'} sur ${base}, ${fetch}` : null
  return [main, local].filter(Boolean).join(' · ') || null
}

/** « mission <nom> · <libellé> » : la mission de la phase active de l'arbre courant, libellé pris du socle, et son état. */
function missionDe(s: Signal, a: SignalArbre | null): { texte: string; etat: string } | null {
  const nom = a?.phaseActive ? s.phases.find(x => x.key === a.phaseActive!.key)?.avancement.mission?.nom : undefined
  if (!nom) return null
  const m = s.missions.find(x => x.nom === nom)
  return { texte: `mission ${oneLine(nom)}${m?.libelle ? ` · ${oneLine(m.libelle)}` : ''}`, etat: m?.etat ?? 'inconnu' }
}

/** La ligne compacte : phase active de l'arbre courant, libellé, retard abrégé. */
export function resumeCompact(s: Signal | null): string {
  const a = s ? courant(s) : null
  if (!s || !a) return 'phase ?'
  const r = a.retard
  return `${phaseDe(s, a)}${pos(r?.main) ? ` · retard ${r!.main}` : ''}`
}

/** La ligne d'erreur du socle, ou rien. */
export async function erreurSocle($: EngineInterface, ui: UI): Promise<JSX.Element | null> {
  const [erreur, s, th] = await Promise.all([read($, signalErreur), read($, signal), read($, theme)])
  const dit = erreur ?? (s && s.verrous.etat !== 'lue' ? 'verrous illisibles' : null)
  if (!dit) return null
  const { Text } = ui
  return <Text color={palette(th)['st-blocked']} wrap="wrap">{`${G.human} ${dit}`}</Text>
}

/** L'en-tête dockée : l'espace de travail, le retard, un worktree par ligne, la mission courante. */
export async function enTete($: EngineInterface, ui: UI, cursor: string): Promise<JSX.Element> {
  const [s, th] = await Promise.all([read($, signal), read($, theme)])
  const p = palette(th)
  const { Box, Text } = ui
  const a = s ? courant(s) : null
  const retard = retardDe(a?.retard ?? null)
  const mission = s ? missionDe(s, a) : null
  // le jalon de la phase active de l'arbre courant, lu dans signal@1 ; aucun jalon sinon, jamais un repli sur le STATE (P68-D-30)
  const jalon = jalonCourant(s)
  return (
    <Box flexDirection="column">
      <Text color={p.text} wrap="wrap">{`${cursor} ${s?.layout.actif ?? 'lab'}`}</Text>
      {jalon ? <Text color={p['text-2']} wrap="wrap">{`jalon ${oneLine(jalon.texte)}`}</Text> : null}
      {retard ? <Text color={p['st-active']} wrap="wrap">{retard}</Text> : null}
      {(s?.arbres ?? []).map(t => {
        const { debut, lib } = phaseParts(s!, t)
        return (
          <Text color={t.courant ? p.text : p['text-2']} wrap="wrap">
            {`${t.courant ? G.current : G.todo} ${oneLine(t.label)} · ${oneLine(t.branche)} · ${debut}${lib ? ' ' : ''}`}
            {lib ? <Text color={couleurEtat(t.phaseActive?.etat, p)}>{`(${lib})`}</Text> : null}
          </Text>
        )
      })}
      {mission ? <Text color={couleurEtat(mission.etat, p)} wrap="wrap">{mission.texte}</Text> : null}
    </Box>
  )
}
