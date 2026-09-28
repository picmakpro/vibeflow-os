# Mission gouvernance-44 — reprise du 2026-09-28 (Phase 44, compartiment `gouvernance`)

- Manager : `vf-dev-manager`, identité de verrou `mgr-44-reprise` (reprise de `vf-dev-manager-g44`,
  interrompu au redémarrage de session). Mode : autonome, `design: off`.
- Worktree : `.claude/worktrees/gouvernance-44`, branche `gouvernance/phase-44-moteur`.
- Base de phase : `424cb23` (= `origin/main`). HEAD au départ de la reprise : `ca185e4`.
- Plan de bataille : `.planning/missions/2026-09-27-gouvernance-44.dag.json` (DAG repris, nœuds
  `exec-44` → `revue-44` ∥ `audit-44` ∥ `banc-44` ∥ `docs` → `livraison-44`).

## Plan de bataille (reprise)

1. Verrou : `takeover` du verrou périmé (âge 23 317 s), génération
   `DRIVER.lock.gen.1790603093.27261` (trailer `Fence:` posé sur `c11a2b5`). Un orphelin consigné
   (`vf-coder` du lot 4, dispatché 09:16:55, transcript figé 09:20, aucune écriture sur disque) :
   fermé `failed`, mandat relancé à l'identique plus l'exigence fail-closed du brief.
2. Gate d'invariants : `check-mission-invariants.sh` → 3 (SAIN). Flags d'enchaînement
   (`_auto_chain_active`, `auto_advance`) déjà à `false` dans `.planning/config.json` (lus).
3. Mémoires d'agents non commitées au départ : gardées, commit séparé `c11a2b5`.
4. `exec-44` (lot 4) → revue ∥ audit → boucle de correction ciblée jusqu'au vert, sous la règle
   d'arrêt du head → gates → ROADMAP/STATE à la main → PR hors brouillon.

## Déroulé

| Tour | HEAD jugé | Revue | Audit | Suite |
|---|---|---|---|---|
| Lot 4 (vrai détecteur, clé injective, fail-closed) | — | — | — | 180 → 233 OK |
| Juges 1 | `885d9b3` | correctifs requis (F1 bloquant : PATH/BASH_ENV hérités) | SECURED, A/B/C/D/T2 fermés, 3 LOW | 233 OK |
| Lot 5 (environnement construit de zéro, NUL, O_NOFOLLOW) | — | — | — | 270 OK |
| Juges 2 | `0be13a9` | PASS (F1-F7 fermés) | OPEN_THREATS : compartiment masqué par saut de ligne (HIGH) | 270 OK |
| Lot 6 (garde de fidélité d'énumération) | — | — | — | 285 OK |
| Juges 3 | `32b5d59` | correctifs requis (compartiment non traversable) | OPEN_THREATS : même constat (HIGH) | 285 OK |
| Escalade au head → option (a) | | | | |
| Lot 7 (garde de lecture du détecteur, tests génériques de permissions) | — | — | — | 303 OK |
| Juges 4 (tour unique, règle d'arrêt) | `345303e` | correctifs requis (lien cassé = sur-refus, catégorie clone) | SECURED, résidus locaux TOCTOU et FIFO | 303 OK |
| Escalade au head → option (a), lot 8 minimal sans nouveau tour de juges | | | | |
| Lot 8 (lien cassé = absent, FIFO non bloquante) | — | — | — | 313 OK |

Constats du tour 1 d'audit, rejoués sur le HEAD de code final jugé (`345303e`) avec commande et
sortie brute : **A fermé** (champ `tentative:` forgé : saut de ligne, `clé=`, espaces, U+2028,
U+0085, NUL — une seule ligne, séparateurs pourcent-encodés, aucun octet non imprimable brut),
**B fermé** (INDEX.md, STATE.md, cloture.log, .recalc-cache.json en lien vers un régulier externe
ou pendant : refus, victime intacte). Également fermés sur ce HEAD : PERM, LF, C, D, T2, F1-revue.
Le lot 8 postérieur a été vérifié par `gsd-verifier` (PASSED) et par tests rouge→vert, sans nouveau
tour de juges, par décision du head.

## Décisions

Toutes rendues par le head, canal : « décision du head sous délégation technique de Willy, session
principale, 2026-09-28 ».

- Lot 4 (brief) : vrai `detect-gsd-engine.sh` en environnement maîtrisé, recopie Python supprimée,
  écriture seulement sur code 3, clé injective, détecteur absent ou non exécutable → refus.
- Après juges 3 : option (a) — garde de CLASSE « le moteur n'écrit que s'il a pu lire tout ce que
  le détecteur devait lire », tests génériques de permissions, entrée BACKLOG (b) pour Samuel ;
  règle d'arrêt : un seul tour de juges après le lot 7, résidu local accepté, écart clone bloquant.
- Après juges 4 : option (a), lot 8 minimal sans nouveau tour de juges, trois tests rouge→vert
  (lien cassé compartiment, lien cassé racine, FIFO) + témoin différentiel ; résidus acceptés
  documentés (TOCTOU 1/15 sur `mv` concurrent local ; volume ~98 s à 3000 compartiments).

Choix de mise en œuvre du manager (discrétion technique déléguée, aucune décision de fond) :
environnement du sous-processus construit de zéro (lot 5) ; garde côté moteur plutôt que
correction de `workstream-policy.sh` (P44-D-01b) au lot 6 ; F3 (journal pré-lot-4) et F4 (TOCTOU
sur le chemin du détecteur) non retenus, motifs consignés dans les mandats (moteur jamais livré ;
écriture préalable dans `plugin/planning-core/scripts/` requise).

## Résidus acceptés (documentés dans `plugin/planning-core/references/modele-cycles.md` et `.planning/BACKLOG.md`)

- TOCTOU entre la garde et le détecteur : 1 écriture sur 15 essais avec un `mv` concurrent local
  (gsd-security-auditor, 2026-09-28). Aucun contenu versionné ne peut l'encoder.
- Volume : `vf_ws_enumerate` prend ~98 s à 3000 compartiments, au-delà du timeout de 30 s → refus
  fail-closed, jamais une écriture indue.
- Cause racine dans `workstream-policy.sh` (`found=1` même quand `cd` échoue ; saut de ligne dans
  un nom de compartiment) : transmise à Samuel au BACKLOG (P44-D-01b).

## Hors mission, consigné

- Entrée BACKLOG « hooks GSD introuvables dans les worktrees » (`0be13a9`), demandée par Willy,
  session principale, 2026-09-28 (relayée par la session principale).
- `check-dev-bootstrap.sh` (GSD_WORKSTREAM=gouvernance) rend 3 « frontmatter illisible ou
  invalide — silence (D-04) » : le champ `status` porte des accents (déjà le cas avant cette
  mission), refusés par `sanitize_value` ; exit 3 = silence nominal, pas un rouge.

## Gates

Tous rejoués avec leurs commandes canoniques.

- CI GitHub, run 36478501924 (push) sur `e273ce8` : **success**, 4 jobs verts (Gates de qualité,
  Suites de tests, Lab frais, Lab frais armé) ; 91 suites découvertes ; `test-recalc-planning.sh`
  : `313 OK · 0 KO` sous Linux. Le run précédent (36430707398, `ca185e4`) était rouge : R14, piège
  `stat -f` GNU/BSD de la suite, corrigé au quick `260928-uu0` (`ad0a0fc`), invisible sous macOS.
- Rejeu local du job `gates` (`replay-ci-jobs.sh --job gates`, outil suivi de la Phase 40.1) sur
  `17615b0` : `RC_GATES=0`, 17 étapes rejouées toutes `rc=0` (check-agents x3, check-blueprints,
  check-version-sync, check-state-integrity, check-capability-activation, check-machine-paths,
  check-instruction-budget, gates workstream-aware, check-divergence,
  check-planning-consumers-registered, check-baseline-arbitrage, check-gate-touche,
  check-affirmation-non-mesuree, check-push-sans-pr) ; `check-gate-touche` sur le dépôt réel :
  `RIEN-A-JUGER` (aucune surface gate touchée depuis 424cb23, aucun trailer `Gate-Touche:` requis).
  `check-baseline-arbitrage` : aucune hausse de baseline.
- Rejeu local du job `tests` : interrompu volontairement (lancé avec le vrai HOME). Contrôle de HOME
  fait en lecture seule, aucune écriture imputable (liste remontée au head). La CI Linux (HOME frais)
  fait foi pour ce job.
- Compartiment `gouvernance` (la CI ne vérifie que `fiabilite`), à la main :
  `bash plugin/conductor/scripts/check-state-integrity.sh --path . --file .planning/workstreams/gouvernance/STATE.md`
  : conforme (compteurs non régressés, 1 ligne `^Phase:`) ;
  `GSD_WORKSTREAM=gouvernance bash plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh --path .`
  : exit 3, silence D-04 (le `status` du frontmatter porte des accents que `sanitize_value` refuse,
  déjà le cas avant cette mission, exit 3 nominal) ; `check-workstream-pointer.sh` : conforme.
- Invariants : `check-mission-invariants.sh` : 3 (SAIN) au démarrage.
- PR : https://github.com/picmakpro/vibeflow-os/pull/114, passée hors brouillon après la CI verte.
  Aucun merge, aucun tag, aucune release.

## Coûts (relayés verbatim des blocs typés, jamais recalculés)

| Mandat | `estimate` | `actuals` | tokens du sous-agent (notification) |
|---|---|---|---|
| vf-coder lot 4 | `{"tokens": 40000, "raw_tokens": 40000, "tasks": 3, "confidence": "low"}` | `{}` | 524 655 |
| vf-reviewer juges 1 | — | — | 266 759 |
| vf-auditer juges 1 | — | — | 200 850 |
| vf-coder lot 5 | `{"tokens": 90000, "raw_tokens": 90000, "tasks": 6, "confidence": "low"}` | `{}` | 536 563 |
| vf-reviewer juges 2 | — | — | 180 973 |
| vf-auditer juges 2 | — | — | 202 401 |
| vf-coder lot 6 | `{"tokens": 70000, "raw_tokens": 70000, "tasks": 3, "confidence": "medium"}` | `{}` | 406 652 |
| vf-reviewer juges 3 | — | — | 159 637 |
| vf-auditer juges 3 | — | — | 191 599 |
| vf-coder lot 7 | `{"tokens": 90000, "raw_tokens": 90000, "tasks": 3, "confidence": "medium"}` | `{}` | 513 631 |
| vf-reviewer juges 4 | — | — | 144 689 |
| vf-auditer juges 4 | — | — | 231 548 |
| vf-coder lot 8 | `{}` | `{}` | 410 328 |
| vf-coder portabilité (quick 260928-uu0) | `{}` | `{}` | 276 134 |

Verdicts `verdicts` des blocs vf-coder : lots 4, 6, 8 `{}` ; lots 5 et 7 non portés ou
`{"code_review": "absent", "nyquist": "absent", "secure": "absent"}` (lot 5, lot 6).

Décompte : minds dispatchés par ce manager : 14 (6 vf-coder, 4 vf-reviewer, 4 vf-auditer),
plus 1 orphelin de l'ancien tenant fermé `failed`. Tours de juges : 4. Lots de correction : 5
(lots 4 à 8), plus 1 correctif de portabilité de la suite. Gates rejoués (E6) : 0.

## Preuves E6

```json
{
  "preuves": [
    {
      "verdict": "recette",
      "commande": "bash plugin/planning-core/scripts/tests/test-recalc-planning.sh",
      "exit_code": 0,
      "sha": "10b5bd6c8eacb266cd3d6333ff32d3d91dfd1902"
    },
    {
      "verdict": "recette",
      "commande": "bash plugin/planning-core/scripts/tests/test-recalc-planning.sh",
      "exit_code": 0,
      "sha": "e273ce8d45322a78d5d5741ba2a348ab13f7d09d"
    },
    {
      "verdict": "revue",
      "preuve": "amont"
    },
    {
      "verdict": "audit",
      "commande": "bash plugin/planning-core/scripts/tests/test-recalc-planning.sh",
      "exit_code": 0,
      "sha": "345303e6ca61f85ced5301c682d48975c3f4877c"
    },
    {
      "verdict": "audit",
      "preuve": "amont"
    },
    {
      "verdict": "gate:check-state-integrity",
      "commande": "bash plugin/conductor/scripts/check-state-integrity.sh --path . --file .planning/workstreams/gouvernance/STATE.md",
      "exit_code": 0,
      "sha": "9bed331caca7e2166f6e5a871784c4241a29080f"
    },
    {
      "verdict": "gate:replay-ci-gates",
      "commande": "bash .planning/workstreams/fiabilite/phases/VFDO-40.1-r-vision-adr-029-et-du-gate-du-budget-d-instructions/tools/replay-ci-jobs.sh --job gates",
      "exit_code": 0,
      "sha": "17615b0d5abe3037ad14b82e1939baffa9d630a7"
    },
    {
      "verdict": "gate:check-machine-paths",
      "commande": "bash scripts/check-machine-paths.sh",
      "exit_code": 0,
      "sha": "e273ce8d45322a78d5d5741ba2a348ab13f7d09d"
    },
    {
      "verdict": "gate:check-gate-touche",
      "commande": "bash scripts/check-gate-touche.sh",
      "exit_code": 3,
      "sha": "e273ce8d45322a78d5d5741ba2a348ab13f7d09d"
    },
    {
      "verdict": "gate:ci-github",
      "commande": "gh run view 36478501924 --json conclusion",
      "exit_code": 0,
      "sha": "e273ce8d45322a78d5d5741ba2a348ab13f7d09d"
    }
  ]
}
```
