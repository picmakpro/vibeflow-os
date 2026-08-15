# 27 — Audit amont `claude_orchestration` : contextes d'usage et chemin de merge

> ## 📋 STATUT DE CE DOCUMENT
>
> **Annexe d'instruction du refus motivé** consigné dans
> [`27-DECISION-claude-orchestration.md`](27-DECISION-claude-orchestration.md). Le refus reste en
> vigueur — ce document ne le rouvre pas : il instruit **comment** et **dans quels contextes** la
> capability pourrait être exploitée sans perte de travail, et fait avancer le déclencheur objectif
> de reprise. Audit conduit le 2026-08-06 sur gsd-core **1.9.1** (session du spike), révisé le
> 2026-08-10 après la mise à niveau du poste en **1.10.0** — la révision change un des trois
> constats (blocage n°1 levé par l'amont, issue #3021).
>
> Sources : code et doc amont `~/.claude/gsd-core` (1.10.0, re-vérifié sur le paquet npm publié) ·
> doc officielle Claude Code (`code.claude.com/docs/en/{workflows,sub-agents,worktrees}`) ·
> `.planning/research/2026-08-05-parallelisation-execution.md` · observations brutes du spike
> (`27-DECISION-claude-orchestration.md` §5).

---

## 1. Ce que le design amont prévoit réellement — et que le spike n'a pas testé

Le point d'accroche de production est le hook `execute:wave:pre` d'`execute-phase.md` : quand la
capability est active, un fragment (inline dans `capability-registry.cjs:686`) remplace le dispatch
`Agent()`-par-plan par `resolve-wave-dispatch` + un run de l'outil Workflow.

**Le manifeste `--waves` est construit par l'orchestrateur LLM à la volée**, depuis le
`PLAN_INDEX` — il n'existe aucun producteur programmatique. Et le contrat sur le brief est
explicite :

> « `brief` — MUST carry the same task content as step 3's inline `Agent()` prompt […] —
> **a short summary here would NOT reproduce step 3's behavior and would violate the
> "identical artifacts" contract.** »

Autrement dit : le brief de chaque plan doit être le **prompt executor complet** (objectif,
protocole de commit atomique, SUMMARY.md, fichiers à lire). Le corpus étalon du spike portait des
briefs d'une ligne — **la moitié « aucun commit de worker » du FAIL n°2 est donc reproductible mais
non représentative du chemin prévu** : elle se corrige en construisant le manifeste selon le
contrat. La divergence structurelle, elle, est ailleurs (§2).

Nuance de spec relevée : la liste des blocs que le fragment ordonne de recopier omet nommément
`<worktree_branch_check>` et `<parallel_execution>` — deux blocs que le chemin inline embarque.
`emitWorkflowScript` traite le brief comme une chaîne opaque (`quoteString(p.brief)`,
`claude-orchestration.cjs:496`) : rien ne vérifie leur présence.

## 2. Le trou de merge — état au 2026-08-10 (gsd-core 1.10.0)

Le fragment amont affirme que « the orchestrator still runs steps 4–5.8 […] **exactly as it does
for inline dispatch** », et le script émis promet en commentaire (`claude-orchestration.cjs:503-504`)
que les commits « are merged by the orchestrator exactly as in inline wave dispatch ». **Aucun code
n'étaye ces deux phrases.** Trois blocages constatés le 2026-08-06, dont un levé depuis :

| # | Blocage | État |
|---|---|---|
| 1 | **Namespace rejeté.** Les branches créées par l'outil Workflow (`worktree-wf_<runId>-<n>`) ne matchaient pas la regex de `record-agent`/`cleanup-wave` (`^(worktree-)?agent-…`) — toute entrée était rejetée à l'écriture ou droppée à la lecture. | **LEVÉ en 1.10.0** — issue amont [#3021](https://github.com/open-gsd/gsd-core/issues/3021) (fermée) : `worktree-safety.cjs:25` accepte `worktree-wf_*`, et la garde anti-dérive d'orchestrateur d'`execute-phase.md` reconnaît le namespace. #3021 couvrait les **gardes** (dont un path-guard qui *fail-open*), pas le merge. |
| 2 | **Manifeste jamais peuplé.** La chaîne de merge (`WAVE_WORKTREE_MANIFEST` → `worktree.record-agent` → `worktree.cleanup-wave`, seul chemin autorisé : « Do not fall back to broad worktree discovery ») est alimentée « **After each `Agent()` returns** » (`execute-phase.md:780`) depuis le bloc `<worktree_metadata>` de chaque retour. En backend Workflow, **un seul appel d'outil englobe toute la vague** : l'orchestrateur ne voit jamais ces blocs individuels, le manifeste reste `{worktrees: []}`, `cleanup-wave` ne merge rien. Le script émis ne retourne pas les résultats des agents, et gsd-core ignore l'existence du `journal.jsonl` du run. | **OUVERT en 1.10.0** — fragment et `claude-orchestration.cjs` byte-identiques à 1.9.1 sur ce point. Rapporté à l'amont le 2026-08-10 : [open-gsd/gsd-core#3302](https://github.com/open-gsd/gsd-core/issues/3302) (copie de référence : [`27-ISSUE-upstream-workflow-merge.md`](27-ISSUE-upstream-workflow-merge.md)). |
| 3 | **Pas de filet.** Le sweep d'orphelins amont (`reap-orphans`) exige un lock GSD et une branche déjà ancêtre de main (`branch_not_merged` → skip) ; le harnais Claude Code, doc officielle à l'appui, **ne merge jamais** — un worktree avec du travail « reste sur disque » et le balayage périodique l'épargne tant qu'il contient des changements. Un run resume aggrave le cas : les agents rejoués depuis le cache ne renvoient plus leurs métadonnées. | **OUVERT** — inchangé en 1.10.0. |

Le run réel du spike a montré empiriquement ce que cette analyse statique confirme : **personne ne
merge**. Le refus (critère FAIL n°2) reste donc fondé même avec des briefs corrects — tant que le
blocage n°2 tient, les commits d'un run Workflow restent orphelins sur leurs branches.

## 3. Contextes d'usage — ce que la doc autorise dès aujourd'hui, avec pont, ou jamais

| Contexte | Verdict | Pourquoi |
|---|---|---|
| **Lecture seule** : audits multi-fichiers, revues à vérification adversariale, recherche multi-sources, exploration | **Utilisable dès aujourd'hui, sans pont** | Rien à merger, rien à perdre. C'est l'usage mis en avant par la doc officielle (`/deep-research`, audits, revues de PR). Candidats immédiats côté lab : les mandats de revue/audit dispatchés par `vf-dev-manager` et `vf-reviewer`/`vf-auditer`. |
| **Écritures parallèles** : vagues de plans autonomes à périmètres disjoints | **Utilisable une fois le pont de merge en place** (§4) | Le gain est réel — compression d'étages mesurée 3,00× (Phase 24), horloge estimée 1,8-2,5× (jamais mesurée, protocole prêt dans `27-MESURE-GAIN.md` bloc 3). |
| **Checkpoints humains en cours de vague** | **Jamais** | « No mid-run user input » + subagents en `acceptEdits` (éditions auto-approuvées) — tension structurelle avec ADR-031. Règle : **un étage = un workflow**, arbitrage entre les runs. La sous-expérience Décision A du spike a prouvé que le repli est sûr (question remontée en rapport, rien d'écrit). |

Limitations amont documentées à garder en tête : plan-checker et verifier restent inline (la
capability ne couvre que le backend d'exécution) · BETA default-off, repli fail-closed byte-identique
à l'inline · la porte n°4 (« présence de l'outil Workflow ») est **codée en dur**
(`claude-orchestration-command-router.cjs:60` `CAPABLE_HOST`) et passe toujours — la seule
discrimination réelle est runtime + version SDK.

## 4. Le chemin de merge sans perte — trois pièces, deux voies

Les deux premières pièces sont **prouvées** (spike + tâche 1) ; la troisième est le pont manquant :

1. **Briefs complets** dans le manifeste de vague (contrat du fragment, §1) → les agents
   `gsd-executor` committent sur leur branche `worktree-wf_*`, écrivent SUMMARY.md et capturent
   leurs métadonnées (`<worktree_metadata_capture>` est déjà dans l'agent).
2. **Récupération post-run** : chaque run Workflow écrit un `journal.jsonl` (une ligne
   `{"type":"result",…}` par agent, lue avec succès pendant le spike). C'est le remplaçant naturel
   du « after each `Agent()` returns » : les chemins de worktree et branches s'y récupèrent.
3. **Merge gardé** : rejouer la séquence amont existante — `record-agent` par entrée (le namespace
   passe depuis #3021) puis `cleanup-wave` (vérification branche/base, refus si arbre sale,
   `merge --no-ff`, `worktree-safety.cjs:684`, suppression worktree + branche).

Deux voies pour la pièce 3 :

- **Voie amont (préférée, doctrine « on délègue, on n'absorbe pas »)** : spécifier chez OpenGSD le
  peuplement du manifeste sur le backend Workflow — issue rédigée, prête à poster :
  [`27-ISSUE-upstream-workflow-merge.md`](27-ISSUE-upstream-workflow-merge.md).
- **Voie locale (pont temporaire)** : un script de lab qui parse le `journal.jsonl` et **alimente**
  `record-agent`/`cleanup-wave` — sans réimplémenter la moindre logique de merge, juste le
  branchement d'entrée. À ne poser que si l'amont tarde et qu'une phase à forte parallélisation le
  justifie.

## 5. Findings annexes à verser au dossier amont

1. **Porte n°4 hardcodée** — `CAPABLE_HOST` (`router:60`, appliqué `:160`) : aucune détection
   effective de l'outil Workflow ; le descripteur runtime de la registry n'est jamais lu.
2. **Spec du brief incomplète** — le fragment omet `<worktree_branch_check>` (embed build-time avec
   `{EXPECTED_BASE}`) et `<parallel_execution>` de la liste des blocs à recopier (§1).
3. **Resume non traité** — `resumeFromRunId` est anti-re-dispatch, jamais anti-re-merge : les agents
   servis depuis le cache ne réémettent pas leurs métadonnées, leurs branches deviennent
   introuvables proprement (§2, blocage n°3).
4. **Mismatch de rôle** — la contribution est déclarée `into: "executor"` alors que tout son texte
   s'adresse à l'orchestrateur (contrat `loop-hook-dispatch.md`).

## 6. Articulation avec le déclencheur de reprise

Le déclencheur écrit dans la décision (deux faits à établir par un nouveau run réel : brief
embarquant le protocole complet · cycle de vie worktree équivalent à l'inline) correspond
exactement aux pièces 1 et 3 du §4 — il était bien calibré. Ordre de rentabilisation recommandé :

1. **Maintenant** : router les mandats read-only (revues, audits, recherche) vers des workflows —
   gain immédiat, zéro risque de perte.
2. **Poster l'issue amont** (§4, voie amont) avec les preuves de cet audit.
3. **Re-spiker** (briefs complets + pont de merge, amont ou local) quand l'une des deux voies est
   en place — et dérouler enfin l'A/B de `27-MESURE-GAIN.md` bloc 3, resté prêt.

## Références

`27-DECISION-claude-orchestration.md` (refus motivé, déclencheur) · `27-MESURE-GAIN.md` (protocole
A/B en attente) · `27-ISOLATION-PORTEE.md` (sondes A1/A2/A4/A5, soldées au spike) ·
`.planning/research/2026-08-05-parallelisation-execution.md` (cadrage, options 1-3) ·
[open-gsd/gsd-core#3021](https://github.com/open-gsd/gsd-core/issues/3021) (namespace, fermée,
1.10.0) · `capability-registry.cjs:686` (fragment) · `claude-orchestration.cjs:336-517`
(émetteur) · `worktree-safety.cjs:25,354,684` (regex, validation, merge) · `execute-phase.md:780`
(peuplement du manifeste, chemin inline).
