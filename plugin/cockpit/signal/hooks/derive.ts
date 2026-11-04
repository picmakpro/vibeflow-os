// Lectures dérivées : l'ordre d'exécution du DAG, le temps de la boucle, la
// prochaine action humaine, le brief Markdown.

import { STAGE_LABEL, age, oneLine, statutAgent, statutNoeud, titreCourt } from './ds'
import type { AgentStat, DagNode, Loop, Refusal, RosterAgent, Signal, SignalArbre, SignalJalon, SignalMission, SignalVerrou, Stage, Usage } from '../types'

// Quel temps de la boucle un agent ou un skill signale. Premier motif qui matche.
const STAGE_OF: readonly [RegExp, Stage][] = [
  [/^(gsd-)?(discuss-phase|new-project|new-milestone|explore|assumptions-analyzer|advisor-researcher|ingest-docs|import|spec-phase)$/, 'cadrer'],
  [/^(gsd-)?(plan-phase|planner|plan-checker|phase-researcher|pattern-mapper|roadmapper|ultraplan-phase|project-researcher)$/, 'planifier'],
  [/^(gsd-)?(execute-phase|executor|quick|quick-batch|fast)$|^vf-(coder|crafter|app-fixer)$/, 'executer'],
  [/^(gsd-)?(verify-work|verifier|code-reviewer|code-review|security-auditor|integration-checker|nyquist-auditor|validate-phase|ui-auditor)$|^vf-(reviewer|auditer|design-judge|test-orchestrator|test-runner)$/, 'verifier'],
  [/^(gsd-)?(ship|complete-milestone|pr-branch|docs-update|extract-learnings|audit-milestone|milestone-summary)$/, 'clore'],
]

// Un nœud de DAG dont l'étape attend un humain.
const HUMAN_STEP = /arbitrage|valid|samuel|willy|humain|décision|decision|go\/no-go|approb/i

export const isDone = (n: DagNode) => /^(done|complete|completed|skipped|skip)$/i.test(n.status)
export const isRunning = (n: DagNode) => /^(running|in[-_ ]?progress|active|started)$/i.test(n.status)
export const isFailed = (n: DagNode) => /^(failed|blocked|error|red)$/i.test(n.status)

export function stageOf(name: string): Stage | null {
  const short = name.replace(/^.*:/, '')
  for (const [re, stage] of STAGE_OF) if (re.test(short)) return stage
  return null
}

/** Les vagues du DAG : la profondeur d'un nœud est 1 + celle de sa dépendance la plus profonde. */
export function waves(nodes: DagNode[]): DagNode[][] {
  const byId = new Map(nodes.map(n => [n.id, n]))
  const depth = new Map<string, number>()
  const of = (n: DagNode, seen: Set<string>): number => {
    const known = depth.get(n.id)
    if (known !== undefined) return known
    if (seen.has(n.id)) return 0
    seen.add(n.id)
    let d = 0
    for (const dep of n.deps) {
      const parent = byId.get(dep)
      if (parent) d = Math.max(d, of(parent, seen) + 1)
    }
    depth.set(n.id, d)
    return d
  }
  const out: DagNode[][] = []
  for (const n of nodes) {
    const d = of(n, new Set())
    while (out.length <= d) out.push([])
    out[d]!.push(n)
  }
  return out
}

/** Les nœuds prêts : ni faits, ni en cours, toutes dépendances faites. */
export function ready(nodes: DagNode[]): DagNode[] {
  const done = new Set(nodes.filter(isDone).map(n => n.id))
  return nodes.filter(n => !isDone(n) && !isRunning(n) && n.deps.every(d => done.has(d)))
}

export function currentNode(nodes: DagNode[]): DagNode | null {
  return nodes.find(isRunning) ?? ready(nodes)[0] ?? null
}

export function humanNode(nodes: DagNode[]): DagNode | null {
  return ready(nodes).find(n => HUMAN_STEP.test(n.step)) ?? null
}

/** L'arbre des agents de la session : racines d'abord, enfants sous leur parent. */
export function tree(roster: RosterAgent[]): { agent: RosterAgent; depth: number }[] {
  const ids = new Set(roster.map(a => a.id))
  const children = new Map<string | null, RosterAgent[]>()
  for (const a of roster) {
    const parent = a.parentId && ids.has(a.parentId) ? a.parentId : null
    children.set(parent, [...(children.get(parent) ?? []), a])
  }
  const out: { agent: RosterAgent; depth: number }[] = []
  const walk = (parent: string | null, depth: number, seen: Set<string>) => {
    for (const a of children.get(parent) ?? []) {
      if (seen.has(a.id)) continue
      seen.add(a.id)
      out.push({ agent: a, depth })
      walk(a.id, depth + 1, seen)
    }
  }
  walk(null, 0, new Set())
  return out
}

/** L'arbre de travail de la session : celui que `signal@1` marque `courant`. */
export const arbreCourant = (s: Signal | null): SignalArbre | null => s?.arbres.find(a => a.courant) ?? null

/** La mission de la phase active de l'arbre courant (`avancement.mission` de la phase), ou null. */
export function missionCourante(s: Signal | null): SignalMission | null {
  const key = arbreCourant(s)?.phaseActive?.key
  const nom = key ? s!.phases.find(p => p.key === key)?.avancement.mission?.nom : undefined
  return nom ? (s!.missions.find(m => m.nom === nom) ?? null) : null
}

/** Le jalon de la phase active de l'arbre courant (P68-D-30) ; null sans phase active ou sans jalon qui la contienne. */
export function jalonCourant(s: Signal | null): SignalJalon | null {
  const key = arbreCourant(s)?.phaseActive?.key
  return key ? (s!.jalons.find(j => j.phases.includes(key)) ?? null) : null
}

/** « <clé> · <titre court> » : la ligne de jalon de l'en-tête et du brief, une ligne, jamais le texte brut du ROADMAP (R6). */
export const jalonLigne = (j: SignalJalon): string => `${oneLine(j.key)} · ${titreCourt(j.texte)}`

/** Le premier verrou de driver périmé de `signal@1`, ou null. */
export const verrouPerime = (s: Signal | null): SignalVerrou | null => s?.verrous.liste.find(k => k.stale === true) ?? null

// Une mission abandonnée ou d'état inconnu n'attend personne : ses nœuds ne dictent pas la prochaine action (P68-D-05, P68-D-23).
const sansHote = (m: SignalMission | null): boolean => m === null || m.etat === 'abandonnee' || m.etat === 'inconnu'

/** La prochaine action humaine, ou null quand l'équipe n'a besoin de personne. */
export function attention(sig: Signal | null, l: Loop, r: Refusal[], alert: string | null, u: Usage | null): string | null {
  const recent = r.filter(x => x.at >= l.turnStartedAt)
  const last = recent[recent.length - 1]
  if (last) return `un garde a refusé ${last.tool} · lis la raison`
  if (alert) return `${alert} · interromps si ça tourne en rond`
  const stale = verrouPerime(sig)
  if (stale) return `verrou périmé de ${stale.owner ?? '?'} · élague ou reprends`
  const mis = missionCourante(sig)
  const nodes = sansHote(mis) ? [] : (mis!.noeuds ?? [])
  const failed = nodes.find(isFailed)
  if (failed) return `nœud ${statutNoeud(failed.status)} · ${failed.step || failed.id}`
  const node = humanNode(nodes)
  if (node) return `arbitrage attendu · ${node.step}`
  if (u?.percent != null && u.percent >= 85) return `contexte à ${u.percent} % · compacter ?`
  return null
}

/** L'étape d'un verrou : son champ `step` s'il existe, sinon la tâche du travailleur « lock » (who@2) du même propriétaire (N2). */
export function etapeVerrou(s: Signal | null, k: SignalVerrou): string | null {
  const dite = k.step ?? s?.equipe?.workers.find(x => x.kind === 'lock' && x.id === k.owner)?.task
  return dite ? oneLine(dite) : null
}

/** Ce que dit un verrou après sa portée : propriétaire, phase, étape, âge. La portée (compartiment ou « dépôt ») est écrite une seule fois, par l'appelant. */
export function detailVerrou(s: Signal | null, k: SignalVerrou, borne = 80): string[] {
  const owner = oneLine(k.owner ?? '?')
  return [owner.length > borne ? `${owner.slice(0, borne - 1)}…` : owner, k.phase ? `phase ${oneLine(k.phase)}` : null, etapeVerrou(s, k), k.ageS != null ? age(k.ageS) : null].filter((x): x is string => x !== null)
}

/** La prochaine action est un nœud bloqué ou en échec : elle prend la couleur « bloqué » (--st-blocked), pas celle d'« attention » (N8). */
export const actionBloquee = (action: string | null): boolean => action !== null && /^nœud (bloqué|en échec|en erreur|rouge) ·/.test(action)

export function brief(sig: Signal | null, l: Loop, roster: RosterAgent[], stats: Record<string, AgentStat>, r: Refusal[], u: Usage | null, erreur: string | null = null): string {
  const lines: string[] = ['# vf-signal — état de la boucle', '']
  // la cause que la pane dit en tête (`erreurSocle`) : sans elle, un brief vide ne dit pas pourquoi (R4)
  if (erreur) lines.push(`- socle : ${oneLine(erreur)}`)
  if (sig) {
    lines.push(`- projet : ${sig.projet}`)
    const jalon = jalonCourant(sig)
    lines.push(`- compartiment : ${sig.layout.actif ?? 'racine'}${jalon ? ` · jalon : ${jalonLigne(jalon)}` : ''}`)
    const active = arbreCourant(sig)?.phaseActive ?? null
    const phase = active ? sig.phases.find(p => p.key === active.key) : undefined
    lines.push(active ? `- phase ${active.n} · ${active.nom}${phase ? ` · ${phase.libelle}` : ''}` : '- aucune phase en cours')
    if (phase) lines.push(`- plans : ${phase.avancement.plans.faits}/${phase.avancement.plans.total}`)
    for (const k of sig.verrous.liste) {
      lines.push(`- verrou ${k.ws || 'dépôt'} : ${detailVerrou(sig, k).join(' · ')}${k.stale ? ' · périmé' : ''}`)
    }
    const mis = missionCourante(sig)
    if (mis) {
      const nodes = mis.noeuds ?? []
      lines.push(`- mission ${mis.nom} · ${mis.libelle} : ${nodes.filter(isDone).length}/${nodes.length} nœuds`)
      waves(nodes).forEach((wave, i) => {
        lines.push(`  - vague ${i + 1}`)
        for (const n of wave) lines.push(`    - [${isDone(n) ? 'x' : ' '}] ${n.id} — ${n.step}${isRunning(n) ? ' (en cours)' : ''}`)
      })
    }
  }
  lines.push(`- temps de la boucle : ${l.stage ? STAGE_LABEL[l.stage] : 'inconnu'}`)
  for (const { agent, depth } of tree(roster)) {
    const s = stats[agent.id]
    lines.push(`${'  '.repeat(depth)}- ${agent.type} · ${statutAgent(agent.status)} · ${agent.description}${s ? ` · ${s.tools} outils` : ''}`)
  }
  if (r.length) {
    lines.push(`- refus (${r.length}) :`)
    for (const x of r.slice(-10)) lines.push(`  - ${x.tool} — ${x.reason.slice(0, 160)}`)
  }
  if (u) {
    lines.push(`- contexte : ${u.percent ?? '?'} % de ${u.window} · coût : ${u.usd != null ? u.usd.toFixed(2) + ' $' : '?'}`)
    for (const lim of u.limits) lines.push(`- ${lim.kind} : ${lim.percent} %`)
  }
  if (sig) {
    for (const j of sig.jalons) {
      const faites = j.phases.filter(k => sig.phases.find(p => p.key === k)?.fait).length
      lines.push(`- jalon ${jalonLigne(j)} : ${faites}/${j.phases.length} phases`)
    }
  }
  return lines.join('\n')
}
