// Contrat d'état du mod vf-signal : chaque valeur gardée dans `$.state`.

/** Les cinq temps de la boucle VibeFlow. */
export type Stage = 'cadrer' | 'planifier' | 'executer' | 'verifier' | 'clore'

/** Les trois vues de la pane. */
export type View = 'mission' | 'equipe' | 'macro'

/** Un verrou de driver tel que `driver-lock.sh status --all` le rend. */
export type LockInfo = {
  scope: string
  ws: string
  owner: string
  step: string
  ageSeconds: number
  ttl: number
  isStale: boolean
  children: number
}

/** Un agent inscrit au registre de mission (`driver-lock.sh orphans`), d'une session ou d'une autre. */
export type RegistryAgent = {
  id: string
  parent: string
  role: string
  node: string
  owner: string
  ageSeconds: number
  depth: number
}

/** Un nœud du plan de bataille (DAG de mission). */
export type DagNode = {
  id: string
  step: string
  status: string
  deps: string[]
}

/** Ce que le disque dit de la mission : STATE.md, verrous, registre, dernier DAG. */
export type Disk = {
  readAt: number
  ws: string | null
  milestone: string | null
  phase: string | null
  phaseName: string | null
  status: string | null
  plansDone: number | null
  plansTotal: number | null
  stoppedAt: string | null
  locks: LockInfo[]
  registry: RegistryAgent[]
  dagName: string | null
  dagMtime: number
  nodes: DagNode[]
  script: string | null
  error: string | null
}

/** Une phase de la feuille de route. */
export type RoadmapPhase = {
  number: string
  name: string
  isDone: boolean
  plansDone: number
  plansTotal: number
}

/** Un jalon de la feuille de route et ses phases. */
export type Milestone = {
  name: string
  phases: RoadmapPhase[]
}

/** La vue macro : projet, jalons, backlog. */
export type Macro = {
  readAt: number
  project: string | null
  milestones: Milestone[]
  closed: string[]
  backlogCount: number
  backlogDeferred: number
  backlogHeads: string[]
}

/** Ce que la session a vu d'un agent : ses appels d'outils. */
export type AgentStat = {
  tools: number
  tool: string | null
  startedAt: number
  lastAt: number
  stage: Stage | null
}

/** Un agent de la session, tel que `$.agent.list()` le rend. */
export type RosterAgent = {
  id: string
  parentId: string | null
  type: string
  description: string
  status: string
  name: string | null
}

/** Ce que la session fait : le temps de la boucle, le tour. */
export type Loop = {
  stage: Stage | null
  isWorking: boolean
  turnStartedAt: number
  tools: number
  lastTurn: { seconds: number; tools: number; outputTokens: number } | null
}

/** Un appel d'outil refusé par un garde (hook VibeFlow ou mod). */
export type Refusal = {
  id: string
  tool: string
  reason: string
  at: number
}

/** Contexte, coût et fenêtres de rate limit, comme la status line les a. */
export type Usage = {
  percent: number | null
  tokens: number | null
  window: number
  usd: number | null
  limits: { kind: string; percent: number }[]
}

/** Miroir des champs lus de `vibeflow/cockpit-signal@1` (le schéma est celui de `cockpit/scripts/vf-cockpit-interface.json`). */
export type SignalNoeud = { id: string; status: string; step: string; stage: string; deps: string[] }
export type SignalMission = { nom: string; etat: string; libelle: string; noeuds?: SignalNoeud[] }
export type SignalPhase = {
  key: string
  n: string
  nom: string
  fait: boolean
  libelle: string
  avancement: { etat: string; plans: { faits: number; total: number }; mission: { nom: string; etat: string } | null }
}
export type SignalJalon = { key: string; icone: string; texte: string; ws: string | null; phases: string[] }
export type SignalVerrou = {
  ws: string | null
  scope: string
  phase: string | null
  tenu: boolean
  stale: boolean | null
  ageS: number | null
  ttl: number | null
  progressAgeS: number | null
  owner: string | null
}
export type SignalRetard = { base: string; main: number | null; origin: number | null; fetchAgeS: number | null }
export type SignalArbre = {
  label: string
  branche: string
  principal: boolean
  courant: boolean
  phaseActive: { key: string; n: string; nom: string; etat: string } | null
  retard: SignalRetard | null
}
export type Signal = {
  schema: string
  projet: string
  layout: { forme: string; actif: string | null }
  phases: SignalPhase[]
  jalons: SignalJalon[]
  missions: SignalMission[]
  verrous: { etat: string; liste: SignalVerrou[] }
  arbres: SignalArbre[]
}

declare module 'claude-code' {
  interface PluginState {
    vibeflow: {
      disk: Disk | null
      macro: Macro | null
      loop: Loop
      roster: RosterAgent[]
      stats: Record<string, AgentStat>
      refusals: Refusal[]
      loopAlert: string | null
      usage: Usage | null
      view: View
      bandHiddenFor: string | null
      /** Vrai si l'ancien mod `vf-signal` (hors dépôt) est présent sous HOME : risque de deux panes. */
      ancienMod: boolean
      /** Ce que l'émetteur du socle a rendu, ou null avant la première lecture ou après un échec. */
      signal: Signal | null
      /** Pourquoi la dernière lecture de l'émetteur a échoué, dite en clair ; null si elle a réussi. */
      signalErreur: string | null
    }
  }
}
