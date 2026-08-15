---
phase: 260815-tl6
plan: 01
subsystem: infra
tags: [github-actions, gh-cli, jq, bash, ci, observability]

# Dependency graph
requires: []
provides:
  - "scripts/traffic-snapshot.sh — script bash idempotent qui interroge l'API GitHub traffic (clones/vues) et ajuste le comptage du bruit CI"
  - "scripts/tests/test-traffic-snapshot.sh — suite TDD sur fixtures verbatim, 9 cas + 1 contrôle négatif"
  - ".github/workflows/traffic-snapshot.yml — workflow cron hebdomadaire qui persiste traffic.json sur la branche orpheline traffic-data"
  - "ci.yml amendé : plus jamais déclenché par push sur traffic-data"
affects: [ci, observability, github-actions]

# Actuals (#2632)
actuals:
  tokens: 4814
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Couture de test par variable d'env (VF_TRAFFIC_FIXTURES) : les fonctions d'appel réseau rendent leurs payloads verbatim depuis des fixtures sur disque, jamais un résultat pré-calculé — parsing/agrégation restent le chemin de production"
    - "Séparation des jetons par portée d'appel : TRAFFIC_PAT scopé à l'env de la commande gh pour les deux seuls endpoints qui l'exigent, authentification ambiante partout ailleurs"
    - "Fenêtre de calcul dérivée du payload (jamais date -d/date -v) pour la portabilité macOS ↔ ubuntu-latest"

key-files:
  created:
    - scripts/traffic-snapshot.sh
    - scripts/tests/test-traffic-snapshot.sh
    - scripts/tests/fixtures/traffic-snapshot/clones.json
    - scripts/tests/fixtures/traffic-snapshot/views.json
    - scripts/tests/fixtures/traffic-snapshot/runs.json
    - scripts/tests/fixtures/traffic-snapshot/jobs/1001.json
    - scripts/tests/fixtures/traffic-snapshot/jobs/1002.json
    - scripts/tests/fixtures/traffic-snapshot/jobs/1003.json
    - .github/workflows/traffic-snapshot.yml
  modified:
    - .github/workflows/ci.yml

key-decisions:
  - "Prérequis `gh` sauté sous VF_TRAFFIC_FIXTURES (trouvé par TDD, hors plan initial) — sinon la couture de test ne pouvait pas prouver sa propre discriminance (T9)"
  - "Permissions du workflow posées au niveau du JOB, pas du workflow (moindre privilège, conforme au registre STRIDE T-TL6-03)"
  - "Fixtures écrites dans le désordre chronologique délibérément, pour que le tri final (jq -S) soit réellement discriminant plutôt que coïncidentiellement correct"

requirements-completed: [TL6-01, TL6-02, TL6-03]

coverage:
  - id: D1
    description: "scripts/traffic-snapshot.sh produit un traffic.json keyé par date avec 6 métriques (clones, clones_uniques, views, views_uniques, ci_jobs, clones_adjusted), clones_adjusted = max(0, clones - ci_jobs)"
    requirement: "TL6-01"
    verification:
      - kind: unit
        ref: "scripts/tests/test-traffic-snapshot.sh#T2 ajustement nominal, T3 borne à zéro"
        status: pass
      - kind: integration
        ref: "bash scripts/traffic-snapshot.sh --dry-run contre l'API vivante picmakpro/vibeflow-os"
        status: pass
    human_judgment: false
  - id: D2
    description: "Fusion idempotente : deux passages successifs conservent les dates hors fenêtre et rafraîchissent celles dans la fenêtre, sortie stable octet pour octet"
    requirement: "TL6-01"
    verification:
      - kind: unit
        ref: "scripts/tests/test-traffic-snapshot.sh#T5 conservation, T6 rafraîchissement, T7 stabilité"
        status: pass
    human_judgment: false
  - id: D3
    description: "Workflow traffic-snapshot.yml (cron hebdomadaire + workflow_dispatch) écrit traffic.json sur la branche traffic-data sans jamais déclencher la CI du repo ; ci.yml exclut traffic-data de on.push.branches"
    requirement: "TL6-02, TL6-03"
    verification:
      - kind: other
        ref: "python3 -c \"import yaml; yaml.safe_load(open('.github/workflows/traffic-snapshot.yml'))\" + grep -c '\"!traffic-data\"' .github/workflows/ci.yml"
        status: pass
      - kind: manual_procedural
        ref: "Aucun run GitHub Actions réel de ce workflow n'a eu lieu (déclenchement cron/dispatch hors périmètre de l'exécution) — comportement en production non observé"
        status: unknown
    human_judgment: true
    rationale: "Le workflow n'a jamais tourné réellement sur GitHub Actions (pas de TRAFFIC_PAT posé, pas de workflow_dispatch lancé) — la structure YAML et la logique bash sont vérifiées, mais l'exécution end-to-end sur le runner reste un geste humain listé dans <gestes_humains> du plan."
  - id: D4
    description: "Sans le secret TRAFFIC_PAT, le workflow échoue avec un message qui nomme le secret et la permission Administration: read requise (jamais un vert silencieux)"
    requirement: "TL6-02"
    verification:
      - kind: other
        ref: "grep -q 'TRAFFIC_PAT' + grep -q 'Administration' .github/workflows/traffic-snapshot.yml (garde du secret : ::error:: + exit 1, pas de continue-on-error)"
        status: pass
    human_judgment: true
    rationale: "La garde est lue par lecture de code (step \"Garde du secret TRAFFIC_PAT\", échec franc), mais son déclenchement réel (workflow lancé sans secret) n'a pas été exécuté sur un runner Actions."

duration: 18min
completed: 2026-08-15
status: complete
---

# Quick Task 260815-tl6: Snapshot hebdomadaire traffic/clones GitHub avec ajustement CI Summary

**Script bash + suite TDD sur fixtures + workflow cron hebdomadaire qui persistent l'historique des stats GitHub traffic (clones/vues) du repo, corrigées du biais des checkouts CI (`clones_adjusted = max(0, clones - ci_jobs)`), sur une branche `traffic-data` isolée qui ne déclenche jamais la CI.**

## Performance

- **Duration:** ~18 min (21:24 → 21:42, incluant un checkpoint de validation humaine sur le tracer)
- **Started:** 2026-08-15T19:24:26Z
- **Completed:** 2026-08-15T19:42:10Z
- **Tasks:** 3/3
- **Files modified:** 10

## Accomplishments
- `scripts/traffic-snapshot.sh` vérifié contre l'API vivante `picmakpro/vibeflow-os` : reproduit exactement le biais mesuré au cadrage (2026-08-02 : 61 clones / 45 jobs CI → 16 ajustés ; 2026-08-04 : 227 / 63 → 164)
- Suite de 9 cas (+1 contrôle négatif) sur fixtures verbatim, tous vus rouges au moins une fois avant d'être verts — dont deux bugs réels trouvés en cours de route, pas simulés
- Workflow `traffic-snapshot.yml` (cron lundi 06:00 UTC + `workflow_dispatch`) et exclusion chirurgicale de `traffic-data` dans `ci.yml` (une seule ligne de contenu modifiée)

## Task Commits

Each task was committed atomically:

1. **Task 1: `scripts/traffic-snapshot.sh` — un passage complet API → fusion → fichier** - `0df78e5` (feat) — tracer, `<verify>` exécuté contre l'API vivante, checkpoint humain rendu par le coordinateur
2. **Task 2: suite de tests sur fixtures — arithmétique d'ajustement et idempotence de la fusion** - `4d94292` (test) — TDD, inclut le fix Rule 1 sur `traffic-snapshot.sh`
3. **Task 3: workflow hebdomadaire `traffic-snapshot.yml` + exclusion de `traffic-data` dans `ci.yml`** - `73363c1` (feat)

**Plan metadata:** commit du docs du plan `427412d` (posé avant l'exécution, hors périmètre de ce SUMMARY)

_Note: Task 2 (`tdd="true"`) est un unique commit `test(...)` car le script implémenté n'était pas dans les `<files>` de la tâche — le fix qu'elle a rendu nécessaire est inclus dans ce même commit._

## Files Created/Modified
- `scripts/traffic-snapshot.sh` - Script bash idempotent : API → fusion → fichier, séparation des jetons, diagnostic 403, écriture atomique
- `scripts/tests/test-traffic-snapshot.sh` - Suite de 9 cas + contrôle négatif, PATH restreint sans `gh` pour prouver la discriminance de la couture
- `scripts/tests/fixtures/traffic-snapshot/{clones,views,runs}.json`, `jobs/{1001,1002,1003}.json` - Fixtures verbatim, 3 jours / 3 runs
- `.github/workflows/traffic-snapshot.yml` - Workflow cron hebdomadaire, garde de secret en échec franc, clone ou création orpheline de `traffic-data`, commit conditionnel
- `.github/workflows/ci.yml` - Ajout de `"!traffic-data"` à `on.push.branches` (1 ligne de contenu + commentaire explicatif)

## Decisions Made
- Permissions du workflow posées au niveau du **job** (`snapshot:`), pas du workflow entier — moindre privilège explicite, conforme à `T-TL6-03` du registre STRIDE du plan
- Fixtures de test écrites en ordre chronologique **volontairement mélangé** (clones et vues insérés dans un ordre différent), pour que le test T8 (tri) soit réellement discriminant plutôt que coïncidentiellement vert
- Runs CI répartis 1 run (1001, 84 jobs) sur le jour nominal et 2 runs (1002+1003, 4+5 jobs) sur le jour à borne zéro, pour couvrir aussi l'agrégation multi-runs par jour au passage

## Deviations from Plan

### Amendement post-livraison (2026-08-15, demandé par Samuel)

**Passage du workflow en mode dormant « NON ACTIVÉ ».** Samuel n'a pas le temps de créer le PAT
`TRAFFIC_PAT` : la garde du secret dans `traffic-snapshot.yml` a été assouplie — un run **cron**
sans secret sort désormais en vert avec un `::warning::` « non activé » (au lieu d'un échec rouge
chaque lundi), et seuls les trois steps de collecte sont sautés (`if: steps.garde.outputs.actif`).
Un **workflow_dispatch** sans secret continue d'échouer explicitement (on teste activement, on veut
le rappel de la marche à suivre). L'activation reste un pur geste de données : poser le secret
suffit, aucun changement de code. État tracé dans STATE.md → Deferred Items.

### Auto-fixed Issues

**1. [Rule 1 - Bug] `traffic-snapshot.sh` exigeait `gh` même sous couture de test**
- **Found during:** Task 2 (écriture de T9, discriminance de la couture)
- **Issue:** Le script vérifiait `command -v gh` inconditionnellement au démarrage, alors que les quatre fonctions d'appel ne sollicitent jamais `gh` quand `VF_TRAFFIC_FIXTURES` est défini. Résultat : T9 (suite tournant sans `gh` sur le PATH) rougissait à cause du prérequis, pas d'un vrai appel réseau manqué — la discriminance visée par le test était cassée dès le départ.
- **Fix:** Le check `command -v gh` est désormais sauté quand `VF_TRAFFIC_FIXTURES` est non vide ; `jq` reste requis dans tous les cas (utilisé même sous fixtures pour le parsing).
- **Files modified:** scripts/traffic-snapshot.sh
- **Verification:** T9 passe désormais avec un PATH restreint (jq, mktemp, mv, cat, mkdir, rm, bash…) sans `gh` ; T9b (contrôle négatif) confirme que le même PATH restreint rougit bien sans la couture — la discriminance est réelle, pas accidentelle.
- **Committed in:** 4d94292 (commit de la Task 2)

**2. [Correction de test, pas du script] Comparaison de clés non triées dans l'assertion T5**
- **Found during:** Task 2, premier passage de la suite
- **Issue:** L'assertion de conservation (T5) comparait un objet JSON attendu écrit à la main dans un ordre de clés arbitraire contre `jq -Sc` (qui trie) — faux négatif sur mon propre test, pas un bug du script.
- **Fix:** L'objet attendu est désormais lui-même normalisé via `jq -Sc` avant comparaison.
- **Files modified:** scripts/tests/test-traffic-snapshot.sh
- **Verification:** T5 passe ; re-confirmé par la passe de mutation batch qui a ensuite fait rougir T5 pour de vraies raisons (fusion inversée) et revert.

---

**Total deviations:** 1 auto-fix de script (Rule 1) + 1 correction de test propre à la tâche 2.
**Impact on plan:** Le fix Rule 1 est nécessaire à la correction du prérequis affiché par `--help` du contrat de couture de test lui-même (sans lui, T9 ne mesure rien) ; aucun scope creep, aucun fichier hors du périmètre des `<files>` déclarés touché.

## Issues Encountered

Pour satisfaire l'exigence du plan « chaque cas a été vu rouge au moins une fois avant d'être vert » (Task 2), et parce que le script de Task 1 (tracer) était déjà correct et vérifié contre l'API vivante avant l'écriture de la suite, deux cas (T5, T9) ont produit des rouges réels via de vrais bugs trouvés en construisant les tests. Les sept autres cas (T1, T2, T3, T4, T6, T7, T8) sont passés du premier coup ; conformément à l'instruction explicite du plan (« si l'un des cas passe du premier coup […] le muter pour obtenir la trace du rouge »), une passe de mutation batch temporaire a cassé chacun d'eux un par un (aide au diagnostic du header --help, formule d'ajustement CI, défauts d'union par date, ordre de fusion idempotente, champ non déterministe, tri final), confirmé leur rougissement dans la même exécution, puis entièrement reverti avant le commit — le diff final ne porte que le fix Rule 1 légitime.

## User Setup Required

**Deux gestes humains hors périmètre de l'exécution** (déjà notés dans `<gestes_humains>` du plan, non automatisables) :
1. Créer le PAT fine-grained (`Administration: read` + `Metadata: read`, dépôt `picmakpro/vibeflow-os` seul) et le poser en secret de dépôt `TRAFFIC_PAT` (Settings → Secrets and variables → Actions → New repository secret).
2. Lancer le workflow une fois en `workflow_dispatch` pour créer la branche orpheline `traffic-data` et vérifier le premier `traffic.json` réel produit en CI.

Sans le secret, une exécution du workflow échouera en émettant `::error::` nommant `TRAFFIC_PAT` et la permission `Administration: read` requise, puis sort en 1 — jamais un vert silencieux.

Aucun bump de `VERSION` : ce plan ne livre pas de module, la discipline de release du `CLAUDE.md` racine ne s'applique pas ici.

## Next Phase Readiness

- `scripts/traffic-snapshot.sh` est utilisable dès maintenant en local (`bash scripts/traffic-snapshot.sh --dry-run`), avant même la pose du secret `TRAFFIC_PAT` — l'authentification ambiante de `gh` sur le poste de Samuel suffit.
- Le workflow ne tournera en production qu'après les deux gestes humains listés ci-dessus ; jusque-là, il échouera proprement à la garde du secret (comportement voulu, pas un bug).
- Aucun blocage pour la suite du milestone `fiabilite-v1.0` — ce quick task est indépendant des phases 30-35.

---
*Quick task: 260815-tl6*
*Completed: 2026-08-15*

## Self-Check: PASSED

All 10 files created/modified confirmed tracked via `git ls-files`; all 3 task commit hashes (`0df78e5`, `4d94292`, `73363c1`) confirmed present via `git cat-file -e`. No missing items.
