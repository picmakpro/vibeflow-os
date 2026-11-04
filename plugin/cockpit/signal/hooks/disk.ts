// Lecture du disque — la source de vérité de VibeFlow. Jamais d'écriture ici.

import type { EngineInterface } from 'claude-code'

import type { DagNode, Disk, LockInfo, Macro, Milestone, RegistryAgent, RoadmapPhase } from '../types'

function field(text: string, key: string): string | null {
  const m = text.match(new RegExp(`^${key}:\\s*(.+?)\\s*$`, 'm'))
  if (!m?.[1]) return null
  return m[1].replace(/^["']|["']$/g, '')
}

function frontmatter(text: string): string {
  const m = text.match(/^---\r?\n([\s\S]*?)\r?\n---/)
  return m?.[1] ?? ''
}

async function readText($: EngineInterface, path: string): Promise<string | null> {
  if (!(await $.fs.exists(path).catch(() => false))) return null
  return $.fs.read(path).catch(() => null)
}

/** Où VibeFlow a posé `driver-lock.sh` : le lab, ce dépôt, ou le compte. */
export async function findScript($: EngineInterface, root: string, home: string | undefined): Promise<string | null> {
  const candidates = [
    `${root}/.claude/scripts/driver-lock.sh`,
    `${root}/plugin/conductor/scripts/driver-lock.sh`,
    home ? `${home}/.claude/scripts/driver-lock.sh` : '',
  ].filter(Boolean)
  for (const path of candidates) {
    if (await $.fs.exists(path).catch(() => false)) return path
  }
  return null
}

async function runJson($: EngineInterface, argv: string[], cwd: string): Promise<Record<string, unknown> | null> {
  const ran = await $.process.run(argv, { cwd, timeoutMs: 10000 }).catch(() => undefined)
  const line = ran?.stdout.trim().split('\n').find(l => l.startsWith('{'))
  if (!line) return null
  try {
    return JSON.parse(line) as Record<string, unknown>
  } catch {
    return null
  }
}

function toLock(raw: Record<string, unknown>): LockInfo | null {
  if (raw.present !== true) return null
  return {
    scope: String(raw.scope ?? 'depot'),
    ws: String(raw.ws ?? ''),
    owner: String(raw.owner ?? '?'),
    step: String(raw.step ?? ''),
    ageSeconds: Number(raw.age_seconds ?? 0),
    ttl: Number(raw.ttl ?? 0),
    isStale: raw.stale === true || raw.stale === 'true',
    children: Number(raw.children_running ?? 0),
  }
}

async function readLocks($: EngineInterface, script: string, root: string): Promise<LockInfo[]> {
  const parsed = await runJson($, ['bash', script, 'status', '--all'], root)
  if (!parsed) return []
  const rows = Array.isArray(parsed.locks) ? (parsed.locks as Record<string, unknown>[]) : [parsed]
  return rows.map(toLock).filter((l): l is LockInfo => l !== null)
}

async function readRegistry($: EngineInterface, script: string, root: string, locks: LockInfo[]): Promise<RegistryAgent[]> {
  const out: RegistryAgent[] = []
  const targets = locks.length ? locks : [{ ws: '' } as LockInfo]
  for (const lock of targets) {
    const argv = ['bash', script, 'orphans', ...(lock.ws ? [`--ws=${lock.ws}`] : [])]
    const parsed = await runJson($, argv, root)
    const rows = Array.isArray(parsed?.orphans) ? (parsed!.orphans as Record<string, unknown>[]) : []
    for (const r of rows) {
      out.push({
        id: String(r.agent_id ?? '?'),
        parent: String(r.parent ?? ''),
        role: String(r.role ?? '?'),
        node: String(r.node ?? ''),
        owner: String(r.owner ?? ''),
        ageSeconds: Number(r.age_seconds ?? 0),
        depth: Number(r.depth ?? 0),
      })
    }
  }
  return out
}

async function newestDag($: EngineInterface, dirs: string[]): Promise<{ name: string; path: string; mtimeMs: number } | null> {
  let best: { name: string; path: string; mtimeMs: number } | null = null
  for (const dir of dirs) {
    const entries = await $.fs.list(dir).catch(() => [])
    for (const entry of entries) {
      if (entry.kind !== 'file' || !entry.name.endsWith('.dag.json')) continue
      if (best === null || entry.mtimeMs > best.mtimeMs) {
        best = { name: entry.name.replace(/\.dag\.json$/, ''), path: `${dir}/${entry.name}`, mtimeMs: entry.mtimeMs }
      }
    }
  }
  return best
}

function toNodes(text: string): DagNode[] {
  const parsed = JSON.parse(text) as { nodes?: Record<string, unknown>[] }
  return (parsed.nodes ?? []).map(n => ({
    id: String(n.id ?? '?'),
    step: String(n.step ?? ''),
    status: String(n.status ?? 'pending'),
    deps: Array.isArray(n.deps) ? n.deps.map(String) : [],
  }))
}

/** Le compartiment actif et le dossier de planning qu'il désigne. */
async function planningBase($: EngineInterface, root: string): Promise<{ planning: string; base: string; ws: string | null }> {
  const planning = `${root}/.planning`
  const ws = (await readText($, `${planning}/active-workstream`))?.trim() || null
  return { planning, base: ws ? `${planning}/workstreams/${ws}` : planning, ws }
}

/** La mission : STATE.md, verrous, registre des agents, dernier DAG. */
export async function readDisk($: EngineInterface, home: string | undefined): Promise<Disk> {
  const out: Disk = {
    readAt: await $.clock.now(),
    ws: null, milestone: null, phase: null, phaseName: null, status: null,
    plansDone: null, plansTotal: null, stoppedAt: null,
    locks: [], registry: [], dagName: null, dagMtime: 0, nodes: [], script: null, error: null,
  }
  try {
    const root = await $.session.root()
    const { planning, base, ws } = await planningBase($, root)
    out.ws = ws

    const state = await readText($, `${base}/STATE.md`)
    if (state) {
      const fm = frontmatter(state)
      out.milestone = field(fm, 'milestone')
      out.phase = field(fm, 'current_phase')
      out.phaseName = field(fm, 'current_phase_name')
      out.status = field(fm, 'status')
      out.stoppedAt = field(fm, 'stopped_at')
      const done = fm.match(/^\s+completed_plans:\s*(\d+)/m)
      const total = fm.match(/^\s+total_plans:\s*(\d+)/m)
      out.plansDone = done?.[1] ? Number(done[1]) : null
      out.plansTotal = total?.[1] ? Number(total[1]) : null
    }

    out.script = await findScript($, root, home)
    if (out.script) {
      out.locks = await readLocks($, out.script, root)
      out.registry = await readRegistry($, out.script, root, out.locks)
    }

    const dag = await newestDag($, [`${planning}/missions`, base, planning])
    if (dag) {
      out.dagName = dag.name
      out.dagMtime = dag.mtimeMs
      try {
        out.nodes = toNodes(await $.fs.read(dag.path))
      } catch {
        out.error = `dag illisible : ${dag.name}`
      }
    }
  } catch (err) {
    out.error = err instanceof Error ? err.message : String(err)
  }
  return out
}

/** Les jalons et leurs phases, lus dans ROADMAP.md. */
function parseRoadmap(text: string): Milestone[] {
  const doneByNumber = new Set<string>()
  for (const m of text.matchAll(/^- \[x\] Phase ([\d.]+):/gim)) if (m[1]) doneByNumber.add(m[1])

  const milestones: Milestone[] = []
  const sections = text.split(/^(?=## )/m)
  for (const section of sections) {
    const head = section.match(/^## .*?Milestone\s+([^\s—]+)/i)
    if (!head?.[1]) continue
    const phases: RoadmapPhase[] = []
    const blocks = section.split(/^(?=### Phase )/m).slice(1)
    for (const block of blocks) {
      const title = block.match(/^### Phase ([\d.]+):\s*(.+)$/m)
      if (!title?.[1]) continue
      const plans = [...block.matchAll(/^- \[( |x)\] \S+-PLAN\.md/gim)]
      phases.push({
        number: title[1],
        name: (title[2] ?? '').trim(),
        isDone: doneByNumber.has(title[1]),
        plansDone: plans.filter(p => p[1]?.toLowerCase() === 'x').length,
        plansTotal: plans.length,
      })
    }
    milestones.push({ name: head[1], phases })
  }
  return milestones
}

/** La vue macro : PROJECT.md, ROADMAP.md, MILESTONES.md, BACKLOG.md. */
export async function readMacro($: EngineInterface): Promise<Macro> {
  const out: Macro = { readAt: await $.clock.now(), project: null, milestones: [], closed: [], backlogCount: 0, backlogDeferred: 0, backlogHeads: [] }
  try {
    const root = await $.session.root()
    const { planning, base } = await planningBase($, root)

    const project = await readText($, `${planning}/PROJECT.md`)
    out.project = project?.match(/^# (.+)$/m)?.[1]?.trim() ?? null

    const roadmap = (await readText($, `${base}/ROADMAP.md`)) ?? (await readText($, `${planning}/ROADMAP.md`))
    if (roadmap) out.milestones = parseRoadmap(roadmap)

    const milestones = await readText($, `${planning}/MILESTONES.md`)
    if (milestones) out.closed = [...milestones.matchAll(/^## \S*\s*([^\s—]+)\s+—/gm)].map(m => m[1] ?? '').filter(Boolean)

    const backlog = await readText($, `${planning}/BACKLOG.md`)
    if (backlog) {
      const heads = [...backlog.matchAll(/^## (.+)$/gm)].map(m => (m[1] ?? '').trim())
      out.backlogCount = heads.length
      out.backlogDeferred = heads.filter(h => /DIFF[ÉE]R/i.test(h)).length
      out.backlogHeads = heads.map(h => h.replace(/\s+—\s+.*$/, '')).slice(0, 8)
    }
  } catch {
    // la vue macro est un confort : rien à signaler
  }
  return out
}
