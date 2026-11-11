// Contrat d'état du mod vf-signal : chaque valeur gardée dans `$.state`.

/** Les cinq temps de la boucle VibeFlow. */
export type Stage = 'cadrer' | 'planifier' | 'executer' | 'verifier' | 'clore'

/** Le thème de couleurs de la pane (VFSG-07) : sombre d'abord, clair si le thème de la personne est clair. */
export type Theme = 'sombre' | 'clair'

/** Les trois vues de la pane. */
export type View = 'mission' | 'equipe' | 'macro'

/** Un nœud du plan de bataille (DAG de mission). */
export type DagNode = {
  id: string
  step: string
  status: string
  deps: string[]
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
  /** null pour un verrou de lab plat : l'émetteur ne lui connaît pas de portée. */
  scope: string | null
  phase: string | null
  tenu: boolean
  stale: boolean | null
  ageS: number | null
  ttl: number | null
  progressAgeS: number | null
  owner: string | null
  /** L'étape que le verrou porte, quand l'émetteur la donne ; sinon `derive.etapeVerrou` la lit chez le travailleur « lock » du même propriétaire. */
  step?: string | null
}
/** `base` vaut null quand le dépôt n'a ni origin/HEAD ni main (P68-PL-05). */
export type SignalRetard = { base: string | null; main: number | null; origin: number | null; fetchAgeS: number | null }
export type SignalArbre = {
  label: string
  branche: string
  principal: boolean
  courant: boolean
  phaseActive: { key: string; n: string; nom: string; etat: string } | null
  retard: SignalRetard | null
}
/** Un travailleur de `who@2` (`signal@1.equipe`) : un agent de n'importe quelle session ou worktree, un verrou, un nœud, un orphelin du registre. */
export type SignalWorker = {
  kind: string
  id: string
  tree: string
  source: string
  role?: string
  task?: string
  /** Le nom donné à la session avec /rename (`custom-title` du transcript), jamais l'`ai-title`. */
  titre?: string
  parent?: string
  branch?: string
  ageS?: number
  stale?: boolean
  orphan?: boolean
  etat?: string
}
export type SignalEquipe = { busy: boolean; trees: string[]; workers: SignalWorker[] }
export type Signal = {
  schema: string
  projet: string
  layout: { forme: string; actif: string | null }
  phases: SignalPhase[]
  jalons: SignalJalon[]
  missions: SignalMission[]
  verrous: { etat: string; liste: SignalVerrou[] }
  arbres: SignalArbre[]
  equipe: SignalEquipe
}

declare module 'claude-code' {
  interface PluginState {
    vibeflow: {
      loop: Loop
      roster: RosterAgent[]
      stats: Record<string, AgentStat>
      refusals: Refusal[]
      loopAlert: string | null
      usage: Usage | null
      view: View
      /** Le thème de la personne, lu dans `$.config.list()` au démarrage de la session. */
      theme: Theme
      bandHiddenFor: string | null
      /** Vrai si l'ancien mod `vf-signal` (hors dépôt) est présent sous HOME : risque de deux panes. */
      ancienMod: boolean
      /** Ce que l'émetteur du socle a rendu, ou null avant la première lecture ou après un échec. */
      signal: Signal | null
      /** Pourquoi la dernière lecture de l'émetteur a échoué, dite en clair ; null si elle a réussi. */
      signalErreur: string | null
      /** L'adresse rendue par le lanceur du cockpit au dernier appui sur « Ouvrir le cockpit » ; null avant l'appui ou après un échec. */
      cockpitUrl: string | null
      /** Pourquoi le dernier lancement du cockpit a échoué, dit en clair ; null s'il a réussi ou n'a pas eu lieu. */
      cockpitErreur: string | null
    }
  }
}
