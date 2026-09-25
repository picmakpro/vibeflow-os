---
gsd_state_version: 1.0
workstream: gouvernance
milestone: gouvernance-labs-v1.0
milestone_name: « le planning métier tenu par une machine »
current_phase: 42
current_phase_name: Fabrique — manifeste daté et invariants de doctrine du gate des agents
status: executing
created: 2026-09-23
last_updated: "2026-09-25T18:45:00.000Z"
last_activity: 2026-09-25
last_activity_desc: >-
  Vague 4 (vf-coder, nœud exec-42-w4) : 42-06 exécuté intégralement (gsd-executor, mode
  séquentiel, sentinel dispatch-isolation re-persisté en none). Tâche 1 : découverte récursive
  (decouvrir_agents, os.walk followlinks=False, exclusions -references/ et dossiers cachés,
  index_agents partagé par la cible et resolve_agent_name) — T97-T99, MUT-D1/MUT-D2 tués,
  témoin lab frais LAB-RECURSIF-OK. Tâche 2 : invariants I2/I3 en monde fermé (D-09), actifs
  sous --resolve-agents=strict seulement, imputés au seul dossier linté — T100-T102,
  MUT-I2/MUT-I3 tués, rejeu CI monde fermé MONDE-FERME fail=0 (une fixture préexistante
  vf-coder.md rendue vf-internal pour rester cohérente avec le corpus réel). Tâche 3 : conductor
  bumpé en mineure v1.42.0 -> v1.43.0 (valeur sur disque + 0.1.0, jamais un numéro en dur) —
  VERSION, module.json, README, CHANGELOG, team-kernel.md (ligne Mobile) ; aucun bump racine.
  Suite complète 166 OK · 0 KO (onze mutants tués) ; rejeu des 9 suites voisines + budget +
  version-sync + blueprints tous verts (REJEU-FIN) ; check-gate-touche.sh rc=0 (18/18 marqueurs
  conformes). SUMMARY de clôture (42-06-SUMMARY.md) avec sections Relecture Samuel (D-12) et
  Résidus signalés. Vérification de phase dispatchée (gsd-verifier, nœud exec-42-w4) :
  42-VERIFICATION.md — 5/5 must-haves vérifiés (FABR-01 à FABR-05), statut human_needed (la
  relecture Samuel sur le chemin CODEOWNERS .github/workflows/ci.yml et les modules de sa
  polarité reste à obtenir avant merge — attendu par le plan lui-même, D-12, pas un manque).
  FABR-03/04/05 cochées à la main ci-dessous dans REQUIREMENTS.md (requirements.mark-complete
  résout vers fiabilite sur ce dépôt, jamais appelé). STATE tenu à la main (jamais
  state.begin-phase / state.record-session).
stopped_at: "42-06 complet, phase 42 exécutée et vérifiée (human_needed : relecture Samuel D-12 attendue avant merge) — prochain : revue par vf-reviewer puis clôture de phase par le manager"
progress:
  total_phases: 9
  completed_phases: 0
  total_plans: 6
  completed_plans: 6
  percent: 100
---

# Project State

## Current Position

Phase: 42 (Fabrique — manifeste daté et invariants de doctrine du gate des agents) — EXÉCUTÉE, EN ATTENTE DE REVUE/AUDIT (vague 4/4 : 42-06 COMPLET — découverte récursive D-10, I2/I3 monde fermé D-09, conductor v1.43.0)
**Last Activity:** 2026-09-25
**Last Activity Description:** Vague 4 (nœud exec-42-w4) : 42-06 exécuté intégralement par un gsd-executor séquentiel. Tâche 1 : découverte récursive (`decouvrir_agents`, `os.walk(followlinks=False)`, exclusions dossiers cachés et `-references/`, `index_agents` partagé par la cible et `resolve_agent_name`) — T97-T99, MUT-D1/MUT-D2 tués, témoin lab frais `LAB-RECURSIF-OK`. Tâche 2 : `invariant_i2`/`invariant_i3` en monde fermé (D-09), actifs sous `--resolve-agents=strict` seulement, imputés au seul dossier linté — T100-T102, MUT-I2/MUT-I3 tués, rejeu CI monde fermé `MONDE-FERME fail=0` (fixture préexistante `vf-coder.md` rendue `vf-internal` pour rester cohérente avec le corpus réel, déviation documentée au SUMMARY). Tâche 3 : conductor bumpé en mineure — valeur lue sur disque (v1.42.0, après merge de la PR #100) + 0.1.0 = v1.43.0 — VERSION, module.json, README, CHANGELOG, team-kernel.md (ligne Mobile) ; aucun bump racine. Suite complète `166 OK · 0 KO` (onze mutants tués) ; rejeu des 9 suites voisines + budget d'instructions + version-sync + blueprints tous verts (`REJEU-FIN`) ; `check-gate-touche.sh` rc=0 (18/18 marqueurs conformes). SUMMARY de clôture 42-06 avec sections « Relecture Samuel (D-12) » et « Résidus signalés ». Vérification de phase dispatchée (gsd-verifier) : `42-VERIFICATION.md` — 5/5 must-haves vérifiés (FABR-01 à FABR-05), statut `human_needed` : la relecture Samuel sur le chemin CODEOWNERS `.github/workflows/ci.yml` et les modules de sa polarité reste à obtenir avant merge — attendue par le plan lui-même (D-12), pas un manque d'implémentation. FABR-03/04/05 cochées à la main dans REQUIREMENTS.md (`requirements.mark-complete` résout vers `fiabilite` sur ce dépôt, jamais appelé).

## Progress

**Phases Complete:** 0 (Phase 42 exécutée et vérifiée, en attente de revue de code et de la relecture Samuel avant clôture)
**Current Plan:** 42-06 COMPLET (vague 4, dernier plan de la phase) — 6/6 plans

## Session Continuity

**Stopped At:** 42-06 complet, phase 42 exécutée et vérifiée (`human_needed` : relecture Samuel D-12 attendue avant merge, pas un manque d'implémentation) — prochain geste : revue de code par vf-reviewer (en direct par le manager) puis clôture de phase
**Resume File:** aucun — les 6 plans de la Phase 42 sont exécutés et vérifiés ; `42-VERIFICATION.md` posé sous `.planning/workstreams/gouvernance/phases/VFDO-42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des/`

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

- **2026-09-25 — reprise de mission (vf-dev-manager)** : la mission s'est interrompue sur une erreur
  API après le nœud `exec-42-w3a` ; verrou de driver repris par `takeover` (même owner, génération
  DRIVER.lock.gen.1790330288.41231), un seul orphelin (le relecteur, déjà rendu) fermé. **42-06
  (vague 4) est tenue derrière l'arbitrage D-08** : son frontmatter dépend de 42-05, qui n'est pas
  complet ; elle modifie le même `check-agents.sh` que la Tâche 3 de 42-05 et fige la mineure et le
  CHANGELOG de `conductor`, qui doivent décrire l'état d'I5/I6 après arbitrage. L'exécuter avant
  rendrait provisoire la Tâche 3 de 42-05.
- **2026-09-25 — seconde sonde D-19 (`sonde-d19b`, règles à `paths:`)** : décidée par Willy
  (AskUserQuestion, session principale, 2026-09-24). Bloquée une première fois : `claude -p` ne
  s'authentifie pas sous HOME temporaire. Willy a choisi un jeton dédié (AskUserQuestion, session
  principale, 2026-09-24), déposé hors dépôt ; la sonde tourne dès qu'il existe. Limite à
  consigner avec elle : la première sonde (`sonde-d19`) tournait avec le HOME réel.

### Dette / à rafraîchir

- **Manifeste daté de `check-agents` périmé le 2026-10-24** (`verifie_le` 2026-09-23 sur les six
  listes, `valide_jours` 30 : frais jusqu'au 2026-10-23 inclus). La CI passe
  `--manifest-freshness=strict` : sans rafraîchissement des six listes (sources officielles relues,
  `verifie_le` redaté), les étapes `check-agents` de la CI rendront INDÉTERMINÉ (rc=3, étape rouge)
  à partir de cette date. Relevé par la revue `revue-42-partiel` (2026-09-25).
