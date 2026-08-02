---
phase: 21-alignement-du-moteur-gsd-sur-gsd-core-1-9-0
plan: 05
subsystem: governance
tags: [ci, version-sync, changelog, roadmap, state, release-discipline, windows]

requires:
  - phase: VFDO-21 (plan 21-01)
    provides: "inject-mcp-tools.sh union scope global/projet, WINDOWS #4 clos"
  - phase: VFDO-21 (plan 21-02)
    provides: "estimate:/actuals: relayés, ADR-061, hypothèse dispatch nommé"
  - phase: VFDO-21 (plan 21-03)
    provides: "purge dette version 1.8.0→1.9.0, ADR-062"
  - phase: VFDO-21 (plan 21-04)
    provides: "check-state-integrity.sh, ADR-063"
  - source: 21-VERIFICATION.md
    provides: "verdict PASS PARTIEL 7/8 — 3 lacunes (correctifs 1-3) + 4 warnings (W1-W4) nommés"
provides:
  - "CI remise au vert aujourd'hui (pas seulement à la release) : compteur de suites 44→45 dans les 2 README, WINDOWS.md recalé (entrée #5)"
  - "dev-orchestrator v2.9.0 (mineur, changement de contrat), planning-core v2.5.3 (correctif), conductor v1.18.0 vérifié cohérent"
  - "ROADMAP §Phase 21 recalé : 5/5 plans listés, Requirements tranchés sans ID REQ- inventé"
  - "W1-W4 traités : check-state-integrity.sh câblé au job gates de la CI, ADR-063 23→25 cas, team-kernel.md porte le recoupement #1995/#2608, inject-mcp-tools.sh nomme --force sur son rc=3 mode fichier unique"
  - "STATE.md recalé à la main : completed_phases 12→13, total_plans/completed_plans +1/+1, Phase 21 status complete"
  - "Release racine v2.45.0 préparée en commits locaux (triade + 2 historiques README + CHANGELOG racine) — aucun tag, aucun merge, aucun push"
affects: []

actuals:
  tokens: 26800
  tasks: 6
  commits: 6

tech-stack:
  added: []
  patterns:
    - "Chaque chiffre recompté au moment de l'exécution, jamais recopié du rapport de vérification (même leçon T-20-07-02 de 20-07) : le compte de suites a été revérifié (45) avant édition, le compte de cas ADR-063 recompté (25) via la suite réelle"
    - "Une régression corrigée doit être réenregistrée au ledger AVANT d'être refermée dans le même geste — WINDOWS.md porte désormais l'entrée #5 (44→45) au lieu d'un correctif silencieux"

key-files:
  created: []
  modified:
    - README.md
    - README.fr.md
    - .planning/WINDOWS.md
    - plugin/dev-orchestrator/VERSION
    - plugin/dev-orchestrator/module.json
    - plugin/dev-orchestrator/README.md
    - plugin/dev-orchestrator/CHANGELOG.md
    - plugin/planning-core/VERSION
    - plugin/planning-core/module.json
    - plugin/planning-core/README.md
    - plugin/planning-core/CHANGELOG.md
    - .planning/ROADMAP.md
    - .github/workflows/ci.yml
    - docs/ADR.md
    - plugin/conductor/references/team-kernel.md
    - plugin/dev-orchestrator/scripts/inject-mcp-tools.sh
    - .planning/STATE.md
    - VERSION
    - plugin/.claude-plugin/plugin.json
    - .claude-plugin/marketplace.json
    - CHANGELOG.md

key-decisions:
  - "Le compteur de suites (44→45) a été corrigé MAINTENANT, pas différé au commit de release — contrairement au patron P-03 de 20-07 (qui le réservait explicitement à la release). Le mandat de cette clôture était explicite : « la CI est rouge AUJOURD'HUI », pas seulement à la release. Les 2 occurrences historiques de « 44 suites » dans l'entrée v2.44.0 de l'historique README (décrivant un état PASSÉ) ont été restaurées après une première correction erronée par sed global — ce ne sont pas des affirmations courantes."
  - "WINDOWS.md reçoit une entrée #5 nommée (phase 21, deviation) pour la régression 44→45, statut fixed dans le même commit — pas une simple correction silencieuse. Le ledger doit porter la trace même quand la correction est immédiate, sinon la prochaine régression du même type reste indétectable au /gsd-ship."
  - "current_phase de STATE.md reste 21 (pas d'avance à 22) — patron vérifié sur pièce (git show c01f813 : clôture de la gouvernance de la Phase 20 sans publication de release, current_phase restait au numéro de la phase qui clôt sa gouvernance, status: complete). Le numéro n'avance qu'à l'OUVERTURE de la phase suivante, jamais à sa seule clôture."
  - "La ligne Requirements du ROADMAP §Phase 21 reprend EXACTEMENT la formule de la Phase 20 (ligne 868) après vérification sur pièce que .planning/REQUIREMENTS.md ne couvre aucune phase après la 14 (ALTI-05) — aucun ID REQ- inventé, conformément à P-06 du plan."
  - "Le message d'aide ajouté à inject-mcp-tools.sh (W4) évite toute apostrophe française — le bloc python embarqué est un bash `python3 -c '...'` à guillemets simples non-heredoc ; une première tentative avec « l'agent »/« l'installeur » a cassé la syntaxe bash (confirmé par bash -n, corrigé avant tout commit)."

requirements-completed: ["Correctif 1 (CI rouge)", "Correctif 2 (bumps de module)", "Correctif 3 (ROADMAP)", "W1 (CI gate)", "W2 (ADR-063 chiffre)", "W3 (team-kernel doctrine)", "W4 (message inject-mcp-tools)", "point hérité STATE.md (clôture)", "clause release G (préparation, pas publication)"]

coverage:
  - id: D1
    description: "CI rouge aujourd'hui corrigée : compteur de suites 44→45 dans les 2 README (4 occurrences courantes, 2 occurrences historiques v2.44.0 préservées), WINDOWS.md porte l'entrée #5"
    requirement: "Correctif 1"
    verification:
      - kind: unit
        ref: "bash scripts/check-version-sync.sh → rc=0 ; grep -c '45 suites' README.md/README.fr.md = 2 chacun"
        status: pass
    human_judgment: false
  - id: D2
    description: "dev-orchestrator v2.9.0 (mineur), planning-core v2.5.3 (correctif), conductor v1.18.0 vérifié — triade + CHANGELOG cohérents"
    requirement: "Correctif 2"
    verification:
      - kind: unit
        ref: "scripts/check-version-sync.sh → triade par module : 17 modules alignés"
        status: pass
    human_judgment: false
  - id: D3
    description: "ROADMAP §Phase 21 : 5/5 plans listés cochés, Requirements tranchés sans ID inventé"
    requirement: "Correctif 3"
    verification:
      - kind: other
        ref: "grep 'Plans: 5/5 plans executed' + 5 occurrences 21-0N-PLAN.md ; lecture REQUIREMENTS.md confirmant l'absence de couverture au-delà de Phase 14"
        status: pass
    human_judgment: false
  - id: D4
    description: "W1-W4 traités : check-state-integrity.sh câblé en CI, ADR-063 25 cas, team-kernel.md porte #1995/#2608, inject-mcp-tools.sh nomme --force"
    requirement: "W1, W2, W3, W4"
    verification:
      - kind: unit
        ref: "grep check-state-integrity ci.yml = 2 ; grep '25 cas' ADR.md = 1, '23 cas' = 0 ; grep '1995' team-kernel.md = 1 ; sonde réelle sur gsd-executor.md --verify --force absent → message --force affiché, rc=3"
        status: pass
    human_judgment: false
  - id: D5
    description: "STATE.md recalé à la main : completed_phases 13, total_plans 56, completed_plans 41, gate check-state-integrity.sh vert avant/après"
    requirement: "point hérité"
    verification:
      - kind: unit
        ref: "bash plugin/conductor/scripts/check-state-integrity.sh → rc=0 ; grep -c '^Phase:' STATE.md = 1"
        status: pass
    human_judgment: false
  - id: D6
    description: "Release v2.45.0 préparée (triade + 2 historiques + CHANGELOG), aucun tag, aucun push, aucun merge"
    requirement: "clause release G"
    verification:
      - kind: unit
        ref: "scripts/check-version-sync.sh → rc=0 (v2.45.0, 17 modules) ; git tag --points-at HEAD → vide ; aucun git push/gh pr/gh release exécuté"
        status: pass
    human_judgment: false

duration: ~1h
completed: 2026-07-31
status: complete
---

# Phase VFDO-21 Plan 05: Clôture de gouvernance — CI verte, 2 modules bumpés, ROADMAP/STATE recalés, 4 warnings traités, release v2.45.0 préparée Summary

**Les 3 lacunes et les 4 warnings de `21-VERIFICATION.md` (PASS PARTIEL 7/8) sont comblés : la CI
est verte aujourd'hui (pas seulement à la release), `dev-orchestrator` et `planning-core` sont
bumpés, le ROADMAP et STATE.md reflètent l'état réel des 5 plans, et la release v2.45.0 est
intégralement préparée en commits locaux — sans tag, sans merge, sans push.**

## Performance

- **Duration:** ~1h
- **Tasks:** 6/6
- **Files modified:** 21 (répartis sur 6 commits atomiques)

## Accomplishments

- **Correctif 1 (BLOQUANT).** `scripts/check-version-sync.sh` sortait en rc=1 sur cette branche :
  les 2 README annonçaient « 44 suites », le réel (recompté) est **45** depuis que 21-04 a ajouté
  `test-check-state-integrity.sh`. Les 4 occurrences courantes corrigées ; les 2 occurrences
  historiques de l'entrée v2.44.0 (décrivant un état passé) ont été **restaurées à 44** après
  qu'une première correction par `sed` globale les avait mutées à tort — un précédent qui décrit
  ce qui était vrai à la release v2.44.0 ne doit jamais changer rétroactivement. `.planning/WINDOWS.md`
  gagne l'entrée **#5** (phase 21, régression 44→45 après clôture de la fenêtre #2), statut `fixed`
  dans le même commit — le ledger porte désormais la trace au lieu d'un correctif silencieux.
- **Correctif 2.** `dev-orchestrator` v2.8.0 → **v2.9.0** (mineur — union de scope MCP global/projet,
  relais `estimate:`/`actuals:`, purge dette 1.8.0) ; `planning-core` v2.5.2 → **v2.5.3** (correctif
  — seul `detect-gsd-engine.sh` touché). `conductor` v1.18.0 vérifié cohérent, non re-bumpé.
- **Correctif 3.** `.planning/ROADMAP.md` §Phase 21 : « Plans: 0 plans » + case `TBD` → **5/5 plans
  listés et cochés**. « Requirements: TBD » → même convention que la Phase 20 (ligne 868) : les 6
  Changements + le point hérité servent d'IDs de traçabilité, aucun ID `REQ-` formel n'existe pour
  cette phase — vérifié sur pièce que `.planning/REQUIREMENTS.md` s'arrête à ALTI-05 (Phase 14).
- **W1.** `plugin/conductor/scripts/check-state-integrity.sh` était armé mais jamais dégainé
  automatiquement (seule sa propre suite, sur des dépôts synthétiques). Câblé au job `gates` de
  `.github/workflows/ci.yml`, entre `check-version-sync` et `check-release-tag`.
- **W2.** ADR-063 §Code Impacté disait « 23 cas », la suite en compte réellement **25** (recompté
  par exécution : `25 ok, 0 ko`) — chiffre corrigé.
- **W3.** Le recoupement #1995 (namespace de branche élargi `agent-*`/`worktree-agent-*`) / #2608
  (`staging_failed`/`staging_timeout` interne à `gsd-executor` amont) vérifié conforme par 21-02
  ne vivait que dans `21-02-SUMMARY.md`. Une nouvelle ligne de `team-kernel.md`, jumelle de la
  ligne « Dispatch nommé », porte désormais ce constat — il survivra au prochain delta amont.
- **W4.** Le message rc=3 « pas de ligne tools: exploitable » d'`inject-mcp-tools.sh --verify` en
  mode fichier unique nomme désormais la cause fréquente (agent réécrit par l'installeur amont,
  marqueur `vf-mcp-consumer: true` effacé) et le remède `--force`. **Vérifié sur le cas réel** cité
  par `21-VERIFICATION.md` : `--verify --target <copie de gsd-executor.md>` sans `--force` affiche
  désormais le message d'aide avant de sortir en rc=3.
- **Point hérité — STATE.md recalé à la main.** `completed_phases` 12→13, `total_plans` 55→56,
  `completed_plans` 40→41 (chaque incrément correspond au plan 21-05 lui-même, jamais un delta
  supposé). `status: complete`, `current_phase` **reste 21** (patron vérifié sur `git show c01f813` :
  le numéro n'avance qu'à l'ouverture de la phase suivante, pas à la seule clôture de gouvernance).
  `check-state-integrity.sh` rejoué après édition : rc=0.
- **Release v2.45.0 préparée, jamais publiée.** Triade racine (`VERSION`, `plugin.json`,
  `marketplace.json`), badges + historique des 2 README, `CHANGELOG.md` racine — tous à `2.45.0`.
  `check-version-sync.sh` : rc=0. **Aucun tag** (`git tag --points-at HEAD` vide), **aucun push**,
  **aucune PR**, **aucune release GitHub** — réservés à Samuel après merge.

## Task Commits

1. **Task 1 : CI rouge — compteur de suites, WINDOWS.md** — `2d76204` (fix)
2. **Task 2 : modules bumpés (dev-orchestrator, planning-core)** — `4f8aa3e` (chore)
3. **Task 3 : ROADMAP §Phase 21 recalé** — `390f5f4` (docs)
4. **Task 4 : W1-W4** — `b937515` (fix)
5. **Task 5 : STATE.md recalé à la main** — `6f0cfac` (docs)
6. **Task 6 : préparation release v2.45.0** — `4e422e1` (chore)

(Plus, avant le plan : `9179b3d` docs — commit du rapport `21-VERIFICATION.md` ; `6982ad3` docs —
commit de ce plan.)

## Gates de sortie de phase (rejoués, sortie réelle)

- **Boucle complète des suites** (`find plugin scripts -type f -path '*/tests/test-*.sh'`) :
  **45 suites, 0 échec.**
- **`check-agents.sh --strict` sur les 6 dossiers d'agents** (`dev-orchestrator`,
  `design-orchestrator`, `business-pilot-bundle`, `content-bundle`, `growth-bundle`,
  `mobile-test-team`) : **rc=0 sur les 6**, uniquement des warnings pré-existants (skills non
  câblés, agents cross-team hors périmètre du dossier scanné).
- **`check-agents.sh --strict --resolve-agents=strict` (monde fermé, comme le job CI)** : **rc=0
  sur les 6 dossiers.**
- **`scripts/check-version-sync.sh`** : **rc=0** — sources synchronisées (v2.45.0, 17 modules),
  aucun contrôle rouge (le seul rouge du jour, le compteur de suites, est résolu par Task 1).
- **`plugin/conductor/scripts/check-mission-invariants.sh`** : `SAIN` (rc=3, contrat propre du
  gate — 3 = sain/lu, distinct de 0 ; cf. son en-tête).
- **`plugin/conductor/scripts/check-state-integrity.sh`** (nouveau gate câblé en CI par ce plan,
  W1) : **rc=0**, conforme sur le vrai `.planning/STATE.md` après édition de Task 5.
- **Périmètre de release intact** : `git tag --points-at HEAD` vide. Aucun `git push`, `gh pr` ou
  `gh release` exécuté.

## Decisions Made

- Le compteur de suites a été corrigé **immédiatement**, pas différé au commit de release (contraste
  avec le patron P-03 de 20-07) : le mandat de cette clôture demandait explicitement de remettre la
  CI au vert **aujourd'hui**, la régression datant de la clôture 20-07 étant l'aggravant cité par la
  vérification.
- `current_phase` de `STATE.md` reste à **21** (pas d'avance à 22) — vérifié sur `git show c01f813`
  avant d'écrire : le numéro n'avance qu'à l'ouverture de la phase SUIVANTE, jamais à la seule
  clôture de gouvernance de la phase courante (Phase 19 shippée → `current_phase` restait 19 jusqu'à
  l'ouverture de la Phase 20 ; Phase 20 gouvernance close → `current_phase` devenait 20 dans le même
  geste, car c'est la phase elle-même qui se ferme).
- Aucun ID `REQ-` inventé pour le ROADMAP §Phase 21 : `.planning/REQUIREMENTS.md` a été relu en
  entier (308 lignes) avant d'écrire la ligne Requirements — le ledger n'a effectivement aucune
  entrée après ALTI-05 (Phase 14), constat identique à celui déjà écrit pour la Phase 20.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1] `sed -i 's/44 suites/45 suites/g'` a muté 2 occurrences historiques par erreur.**
- **Found during:** Task 1, vérification post-édition de `check-version-sync.sh` (le grep du
  compte de suites passait, mais une relecture du diff a montré que l'entrée d'historique
  v2.44.0 des 2 README — qui décrit un état PASSÉ — avait aussi été mutée à « 45 suites »/
  « 45 suites vertes ».
- **Issue:** un remplacement global sans ancrage sur les 2 occurrences COURANTES (mermaid diagram
  + section Trust) a aussi touché la 3e occurrence, dans le corps de texte de l'historique versionné
  — falsifiant rétroactivement ce que la release v2.44.0 affirmait au moment de sa publication.
- **Fix:** les 2 occurrences (une par README) restaurées à `44 suites`/`44 suites vertes` dans
  l'entrée `v2.44.0` de la table d'historique, par édition ciblée sur cette ligne précise.
- **Verification:** `sed -n '254p' README.md` / `sed -n '259p' README.fr.md` confirment `44` ; les
  2 occurrences courantes (mermaid + Trust) restent à `45`.
- **Committed in:** `2d76204` (Task 1 commit — corrigé avant tout commit, jamais poussé en l'état).

**2. [Rule 1] Message W4 cassait la syntaxe bash au premier essai (apostrophes françaises).**
- **Found during:** Task 4, `bash -n inject-mcp-tools.sh` immédiatement après l'édition.
- **Issue:** le message ajouté utilisait `l'agent`/`l'installeur` — le bloc concerné est un
  `python3 -c '...'` bash à guillemets SIMPLES (pas un heredoc) : une apostrophe française y ferme
  prématurément la chaîne bash et fait échouer le parsing (`syntax error near unexpected token '('`).
  Confirmé par lecture du reste du bloc python : aucune contraction française n'y est utilisée
  (`determinee`, `INDETERMINE` sans accents), convention jusque-là non documentée mais suivie
  partout ailleurs dans ce bloc précis.
- **Fix:** message reformulé sans article élidé (« agent reecrit par installeur amont » au lieu de
  « l'agent a perdu... l'installeur »), toujours sans accents pour rester dans la même convention.
- **Verification:** `bash -n` propre ; suite `test-inject-mcp-tools.sh` : 36 OK / 0 KO ; sonde
  réelle sur une copie de `gsd-executor.md` : message affiché, rc=3 inchangé.
- **Committed in:** `b937515` (Task 4 commit — corrigé avant tout commit).

**Total deviations:** 2 auto-fixées (Rule 1), toutes deux détectées et corrigées AVANT le commit
concerné — aucune n'a atteint l'historique git dans son état fautif.

## Issues Encountered

Aucun blocage. Les 2 déviations ci-dessus sont des corrections in-flight documentées, pas des
échecs de tâche — le plan n'a jamais eu besoin de remonter un `gaps_found`.

## Known Stubs

Aucun — ce plan ne produit que de la doctrine, des versions, un câblage CI et des messages d'aide ;
aucun code applicatif, aucune UI, aucune donnée simulée.

## User Setup Required

**Un seul geste, réservé à Samuel — la release v2.45.0 est intégralement préparée :**

1. Merger la PR de la branche `feat/phase-21-alignement-gsd-core-190` sur `main`.
2. `git tag -a v2.45.0 -m "v2.45.0 — alignement gsd-core 1.9.0" <commit-de-release>` puis
   `git push origin v2.45.0`.
3. `gh release create v2.45.0 --title "v2.45.0 — alignement gsd-core 1.9.0" --notes "..." --verify-tag`.
4. Vérifier : `bash scripts/check-release-tag.sh --remote` → doit sortir `✓`.

Aucun de ces 4 gestes n'a été exécuté par ce plan (P-01, discipline CLAUDE.md + ADR-031).

## Next Phase Readiness

- La Phase 21 est **complète** sur ses 5 plans : les 6 Changements + le point hérité vérifiés
  (`21-VERIFICATION.md`, PASS PARTIEL 7/8), la couche de clôture comblée par ce plan (CI verte,
  2 modules bumpés, ROADMAP/STATE exacts, 4 warnings traités), release v2.45.0 préparée.
- **Aucun blocage** pour les Phases 22+ — ce plan n'a touché aucun de leurs fichiers (P-03).
- Seul reste-à-faire : le merge + tag humain listé ci-dessus.

## Self-Check: PASSED

- `README.md`, `README.fr.md`, `.planning/WINDOWS.md` : FOUND
- `plugin/dev-orchestrator/CHANGELOG.md`, `plugin/planning-core/CHANGELOG.md` : FOUND
- `.planning/ROADMAP.md`, `.github/workflows/ci.yml`, `docs/ADR.md`,
  `plugin/conductor/references/team-kernel.md` : FOUND
- `.planning/STATE.md`, `VERSION`, `plugin/.claude-plugin/plugin.json`,
  `.claude-plugin/marketplace.json`, `CHANGELOG.md` : FOUND
- Commits `2d76204`, `4f8aa3e`, `390f5f4`, `b937515`, `6f0cfac`, `4e422e1` : FOUND dans `git log`
- `git tag --points-at HEAD` : vide (confirmé)

---
*Phase: VFDO-21-alignement-du-moteur-gsd-sur-gsd-core-1-9-0*
*Completed: 2026-07-31*
