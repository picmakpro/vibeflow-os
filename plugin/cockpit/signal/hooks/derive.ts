// Lectures dérivées : l'ordre d'exécution du DAG, le temps de la boucle, la
// prochaine action humaine, le brief Markdown.

import { STAGE_LABEL, age } from './ds'
import type { AgentStat, DagNode, Disk, Loop, Macro, Refusal, RosterAgent, Stage, Usage } from '../types'

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

/** La prochaine action humaine, ou null quand l'équipe n'a besoin de personne. */
export function attention(d: Disk | null, l: Loop, r: Refusal[], alert: string | null, u: Usage | null): string | null {
  const recent = r.filter(x => x.at >= l.turnStartedAt)
  const last = recent[recent.length - 1]
  if (last) return `un garde a refusé ${last.tool} · lis la raison`
  if (alert) return `${alert} · interromps si ça tourne en rond`
  const stale = d?.locks.find(x => x.isStale)
  if (stale) return `verrou périmé de ${stale.owner} · élague ou reprends`
  const failed = d?.nodes.find(isFailed)
  if (failed) return `nœud ${failed.status} · ${failed.step || failed.id}`
  const node = d ? humanNode(d.nodes) : null
  if (node) return `arbitrage attendu · ${node.step}`
  if (u?.percent != null && u.percent >= 85) return `contexte à ${u.percent} % · compacter ?`
  return null
}

export function brief(d: Disk | null, m: Macro | null, l: Loop, roster: RosterAgent[], stats: Record<string, AgentStat>, r: Refusal[], u: Usage | null): string {
  const lines: string[] = ['# vf-signal — état de la boucle', '']
  if (m?.project) lines.push(`- projet : ${m.project}`)
  if (d) {
    lines.push(`- compartiment : ${d.ws ?? 'racine'} · jalon : ${d.milestone ?? '?'}`)
    lines.push(`- phase ${d.phase ?? '?'} · ${d.phaseName ?? ''} · ${d.status ?? '?'}`)
    if (d.plansTotal != null) lines.push(`- plans : ${d.plansDone ?? 0}/${d.plansTotal}`)
    if (d.stoppedAt) lines.push(`- arrêt : ${d.stoppedAt}`)
    for (const k of d.locks) {
      lines.push(`- verrou ${k.ws || 'dépôt'} : ${k.owner} · ${k.step} · ${age(k.ageSeconds)}${k.isStale ? ' · périmé' : ''} · ${k.children} enfant(s)`)
    }
    if (d.dagName) {
      lines.push(`- mission ${d.dagName} : ${d.nodes.filter(isDone).length}/${d.nodes.length} nœuds`)
      waves(d.nodes).forEach((wave, i) => {
        lines.push(`  - vague ${i + 1}`)
        for (const n of wave) lines.push(`    - [${isDone(n) ? 'x' : ' '}] ${n.id} — ${n.step}${isRunning(n) ? ' (en cours)' : ''}`)
      })
    }
    for (const a of d.registry) lines.push(`- registre : ${a.role} sur ${a.node || '?'} · ${age(a.ageSeconds)} · profondeur ${a.depth}`)
  }
  lines.push(`- temps de la boucle : ${l.stage ? STAGE_LABEL[l.stage] : 'inconnu'}`)
  for (const { agent, depth } of tree(roster)) {
    const s = stats[agent.id]
    lines.push(`${'  '.repeat(depth)}- ${agent.type} · ${agent.status} · ${agent.description}${s ? ` · ${s.tools} outils` : ''}`)
  }
  if (r.length) {
    lines.push(`- refus (${r.length}) :`)
    for (const x of r.slice(-10)) lines.push(`  - ${x.tool} — ${x.reason.slice(0, 160)}`)
  }
  if (u) {
    lines.push(`- contexte : ${u.percent ?? '?'} % de ${u.window} · coût : ${u.usd != null ? u.usd.toFixed(2) + ' $' : '?'}`)
    for (const lim of u.limits) lines.push(`- ${lim.kind} : ${lim.percent} %`)
  }
  if (m) {
    for (const ms of m.milestones) lines.push(`- jalon ${ms.name} : ${ms.phases.filter(p => p.isDone).length}/${ms.phases.length} phases`)
    lines.push(`- backlog : ${m.backlogCount} entrées, ${m.backlogDeferred} différées`)
  }
  return lines.join('\n')
}
