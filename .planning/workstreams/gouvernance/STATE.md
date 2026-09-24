---
gsd_state_version: 1.0
workstream: gouvernance
milestone: gouvernance-labs-v1.0
milestone_name: « le planning métier tenu par une machine »
current_phase: 42
current_phase_name: Fabrique — manifeste daté et invariants de doctrine du gate des agents
status: executing
created: 2026-09-23
last_updated: "2026-09-25T00:00:00.000Z"
last_activity: 2026-09-25
last_activity_desc: >-
  Vague 2 exécutée (vf-coder, nœud exec-42-w2) : plan 42-04 (fraîcheur du manifeste, FABR-02) vert,
  3 commits sur gouvernance/phase-42-fabrique. Vague 3 (42-05, dépend de 42-04/42-02/42-03) non
  lancée — hors mandat. STATE tenu à la main (jamais state.begin-phase / state.record-session).
progress:
  total_phases: 9
  completed_phases: 0
  total_plans: 6
  completed_plans: 4
  percent: 67
---

# Project State

## Current Position

Phase: 42 (Fabrique — manifeste daté et invariants de doctrine du gate des agents) — EXECUTING (vague 2/4 terminée : 42-01, 42-02, 42-03, 42-04)
**Last Activity:** 2026-09-25
**Last Activity Description:** Vague 2 exécutée (nœud exec-42-w2) : 42-04 (fraîcheur du manifeste — détection D-02, rétrogradation D-05, INDÉTERMINÉ sous --manifest-freshness=strict, D-04 ; T83-T90, MUT-F1, MUT-F2, MUT-D20 ; les quatre appels CI durcis) — vert, 3 commits.

## Progress

**Phases Complete:** 0
**Current Plan:** Vague 3 (42-05, dépend de 42-04/42-02/42-03) — non lancée, hors mandat exec-42-w2

## Session Continuity

**Stopped At:** Fin de la vague 2 (42-04), mandat exec-42-w2 borné à cette seule vague
**Resume File:** None

## Note pour Willy (2026-09-23, partition D-02)

Ce compartiment reçoit le jalon `gouvernance-labs-v1.0` (Phases 42-50) — voir
`.planning/workstreams/gouvernance/ROADMAP.md` et `REQUIREMENTS.md` (`FABR-01..05`). Le contenu déjà
planifié de la Phase 42 (6 plans + `42-CONTEXT.md`/`42-RESEARCH.md`/`42-PATTERNS.md`/`42-VALIDATION.md`)
a été déplacé tel quel depuis la racine, rien réécrit. Détail complet de la partition :
`.planning/missions/2026-09-23-partition-planning-d02.md`.

**Ce qui change concrètement** : `.planning/active-workstream` (racine, partagé) pointe par défaut
sur `fiabilite` — toute commande `gsd-tools`/`gsd_run` qui ne précise rien résout `fiabilite`, PAS
`gouvernance`. Pour travailler ici, passe `--ws gouvernance` explicitement à chaque appel, ou exporte
`GSD_WORKSTREAM=gouvernance` dans ton worktree pour la durée de la mission (jamais les deux à la fois
sans vérifier lequel prime — `--ws` court-circuite toujours l'environnement).

**Amendé le 2026-09-24** — exécution en parallèle autorisée (autorisation Samuel du 2026-09-23 rapportée par Willy, session principale, 2026-09-24 (canal non précisé)) ; aucune release avant la clôture de `fiabilite-v1.0` (voir l'en-tête du jalon dans `ROADMAP.md`). Rappel d'origine :

**Rappel non modifié par cette partition** : aucune exécution du jalon avant la clôture de
`fiabilite-v1.0` (Samuel, WhatsApp, 2026-09-23) — être inscrite ici ne vaut pas feu vert.

**Ce fichier rend `rc=2` (« milestone introuvable ») si tu rejoues `check-state-integrity.sh`
dessus tel quel.** C'est attendu, pas une corruption : le frontmatter d'un compartiment tout juste
créé par le moteur n'a pas encore de champ `milestone:` ni de ligne `^Phase:` — c'est la
dégradation honnête d'un compartiment neuf. Ça se résorbe tout seul au premier geste GSD réel ici
(`gsd-new-milestone --ws gouvernance`, ou l'équivalent qui pose ces champs).

**La CI de ce dépôt ne vérifie QUE le compartiment `fiabilite`** (`ci.yml:353`, cible en dur
`.planning/workstreams/fiabilite/STATE.md` — choisie exprès pour qu'un `export GSD_WORKSTREAM` ne
puisse pas détourner le gate vers un autre fichier). Elle ne se prononcera donc JAMAIS sur l'état de
`gouvernance` — ni pour dire que c'est cassé, ni pour dire que c'est bon. Si tu veux savoir où en
est ton compartiment, rejoue le gate toi-même avec `--file .planning/workstreams/gouvernance/STATE.md`
explicitement ; n'attends rien de la CI sur ce point.

### Decisions

- **2026-09-24 — mission Phase 42 (vf-dev-manager)** : recouvrement avec la PR #100 (`fiabilite`, Samuel)
  mesuré avant le premier dispatch. Il est **numérique, pas sémantique** : les deux PR bumpent `conductor`
  (#100 : v1.40.0 → v1.41.0 ; 42-06 : mineure) et touchent `ci.yml` à des étapes différentes (#100 :
  intégrité du STATE ; 42 : étapes `check-agents`). Traité par le garde-fou de l'en-tête du jalon, sans
  arrêt de mission : la PR de la 42 se rebase et renumérote `conductor` après le merge de la #100. Un
  recouvrement de logique (même script, même étape) aurait été une condition d'arrêt.

- **2026-09-24 — vague 1 (vf-coder, nœud exec-42-w1)** : `gsd-execute-phase 42 --ws gouvernance
  --wave 1` a résolu l'isolation en `harness-worktree` puis dégradé automatiquement à `none`
  (`worktree.base-check` : HEAD 13fcd278 divergent d'`origin/HEAD` 3dc082ec — règle #683 documentée
  du moteur, pas une décision de ma part). Les trois plans de la vague (fichiers disjoints) ont donc
  tourné **séquentiellement** sur cette worktree au lieu de trois worktrees parallèles — même
  résultat, ordre 42-01 → 42-02 → 42-03. Le sentinel `dispatch-isolation` doit être re-persisté
  (`record-dispatch-isolation --isolation none`) avant chaque dispatch : `dispatch-isolation --raw`
  sans `--force-isolation` se re-résout à chaud depuis la capacité de l'hôte et efface le
  précédent, un garde `PreToolUse` bloquant sinon le dispatch suivant (observé entre 42-01 et
  42-02, corrigé avant 42-03).

- **2026-09-25 — vague 2 (vf-coder, nœud exec-42-w2)** : même dégradation d'isolation que la
  vague 1 (`worktree.base-check` : HEAD e3ba8f9 divergent d'`origin/HEAD` — attendu, sentinel
  re-persisté en `none` avant le dispatch de l'exécuteur de 42-04). La vague 1 avait touché
  `check-agents.sh` et `test-check-agents.sh` (commits ba312e0, bb36787, a9e98ac) sans trailer
  `Gate-Touche` — corrigé rétroactivement dans le premier commit de cette vague qui touche
  `check-agents.sh` (8c507e7), portée branche de la garde G-2 : `check-gate-touche.sh` confirme
  `marqueurs: lus=8 conformes=8`, `DECLARE`, `rc=0`. `requirements.mark-complete` non appelé par
  l'exécuteur (mandat override) : FABR-02 coché à la main ci-dessous dans `REQUIREMENTS.md`.
