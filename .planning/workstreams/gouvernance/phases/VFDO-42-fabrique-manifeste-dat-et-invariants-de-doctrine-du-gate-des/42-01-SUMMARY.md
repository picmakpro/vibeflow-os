---
phase: 42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des
plan: 01
subsystem: governance-tooling
tags: [check-agents, manifest, json, gate, fail-closed, D-20, python, bash]

# Dependency graph
requires: []
provides:
  - "Manifeste daté versionné (check-agents-manifest.json) portant les six listes de référence du gate des agents"
  - "check-agents.sh lit ses six listes depuis le manifeste — plus aucune copie de repli, plus aucune énumération littérale"
  - "Installeur (copy_module_scripts) pose les fichiers de données *.json des modules dans un lab installé (Site #3bis, D-16)"
  - "Suite test-check-agents.sh rejouée contre un manifeste daté du jour (T77-T82) plutôt que contre le manifeste versionné brut"
  - "Invocation nue de check-agents.sh sur une cible absente rend désormais INDÉTERMINÉ (exit 3, CIBLE-ABSENTE) au lieu du faux vert historique (D-20)"
affects: [VFDO-42-04, VFDO-42-05, VFDO-42-06]

# Actuals (#2632)
actuals:
  tokens: 10166
  tasks: 3
  commits: 4

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Manifeste JSON daté co-localisé avec un gate (verifie_le + source par liste, valide_jours porté par le manifeste)"
    - "Chargement fail-closed paresseux (charger_referentiel appelé seulement s'il existe une cible à juger)"
    - "Harnais de test à manifeste du jour (mk_gate_dir/mk_manifest) plutôt qu'un test direct contre le manifeste versionné"

key-files:
  created:
    - plugin/conductor/scripts/check-agents-manifest.json
  modified:
    - plugin/conductor/scripts/check-agents.sh
    - plugin/conductor/scripts/tests/test-check-agents.sh
    - plugin/_internal/vibeflow-update.sh
    - plugin/_internal/tests/test-vibeflow-update.sh

key-decisions:
  - "D-01/D-02/D-03 tenus tels quels : source unique dans le manifeste, valide_jours porté par le manifeste, manifeste absent/illisible = refus explicite (MANIFESTE-ILLISIBLE, rc=1, rc=0 sous --hook)"
  - "D-17 tenu : seuls ListAgents, SendFeedback, SubagentHandback ajoutés aux outils — BashOutput/KillShell/SlashCommand écartés (déjà couverts ou non documentés officiellement)"
  - "D-16 tenu dans la même vague que la pose du manifeste (Site #3bis de copy_module_scripts, glob *.json, sans mode exec)"
  - "D-20 tenu : cible ABSENTE hors --hook rend désormais INDÉTERMINÉ (exit 3, CIBLE-ABSENTE) dans tous les modes, y compris sans --strict ; --allow-empty tolère aussi une cible absente (I2, revue 42b)"
  - "T76 non touché (D-13, sans objet — déjà corrigé par le hotfix v2.63.2 avant cette phase)"
  - "MANIFESTE-ILLISIBLE n'utilise jamais la séquence espace-deux-points-espace, pour que guard-agent-write.sh applique son fail-open documenté plutôt qu'un refus aveugle de toute écriture d'agent"

patterns-established:
  - "Un manifeste de données JSON co-localisé avec un gate porte sa propre validité (valide_jours) et sa propre traçabilité (verifie_le + source par liste) — le script hôte ne garde aucune valeur par défaut"
  - "mk_gate_dir/mk_manifest : la suite de test copie le gate réel + un manifeste re-daté du jour dans un dossier jetable, pour juger la LOGIQUE du gate indépendamment de la fraîcheur du fichier versionné"

requirements-completed: [FABR-01, FABR-05]

coverage:
  - id: D1
    description: "Manifeste daté versionné (six listes, verifie_le + source, valide_jours) — 46 outils, 18 champs, 6 types natifs, 5 modèles, 7 modes, 5 niveaux d'effort"
    requirement: FABR-01
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-agents.sh#T77-T82"
        status: pass
      - kind: other
        ref: "python3 -c 'import json;...' (comptage exact 30 6 46 18 6 5 7 5)"
        status: pass
    human_judgment: false
  - id: D2
    description: "check-agents.sh charge le manifeste, fail-closed et paresseux — plus aucune copie de repli des six listes"
    requirement: FABR-01
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-agents.sh#T77-T82"
        status: pass
      - kind: other
        ref: "grep -qE 'ShareOnboardingGuide|bypassPermissions|xhigh|claude-code-guide|initialPrompt' (absence confirmée)"
        status: pass
    human_judgment: false
  - id: D3
    description: "L'installeur pose le manifeste .json dans un lab fraîchement installé (Site #3bis, D-16)"
    requirement: FABR-01
    verification:
      - kind: unit
        ref: "plugin/_internal/tests/test-vibeflow-update.sh#T54"
        status: pass
      - kind: e2e
        ref: "tracer end-to-end (lab frais → gate vert → manifeste retiré → MANIFESTE-ILLISIBLE)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Une cible absente hors --hook rend INDÉTERMINÉ (exit 3, CIBLE-ABSENTE) dans tous les modes — ferme CONCERNS.md:349"
    requirement: FABR-05
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-agents.sh#T103"
        status: pass
      - kind: other
        ref: "acceptance_criteria D20-OK / D20-JUMEAU-VERT-OK"
        status: pass
    human_judgment: false
  - id: D5
    description: "Corpus réel conforme sous --strict sur les 6 dossiers plugin/*/agents et sous check-blueprints.sh"
    requirement: FABR-05
    verification:
      - kind: integration
        ref: "rejeu des 3 étapes CI check-agents (6 dossiers plugin/*/agents) + check-blueprints.sh (9 blueprints)"
        status: pass
    human_judgment: false

duration: ~90min
completed: 2026-09-24
status: complete
---

# Phase 42 Plan 01: Manifeste daté du gate des agents + D-20 (invocation nue sur cible absente) Summary

**Les six listes de référence de `check-agents.sh` sortent vers un manifeste JSON daté et versionné, chargé fail-closed et paresseusement ; l'installeur le pose dans tout lab frais ; une cible absente hors `--hook` rend désormais INDÉTERMINÉ au lieu du faux vert historique.**

## Performance

- **Duration:** ~90 min
- **Completed:** 2026-09-24T21:17:34Z
- **Tasks:** 3 (1 tracer + 2 tdd)
- **Files modified:** 5 (1 créé, 4 modifiés)

## Accomplishments

- `plugin/conductor/scripts/check-agents-manifest.json` créé : six listes (outils, champs de frontmatter, types natifs, modèles, modes de permission, niveaux d'effort), chacune datée (`verifie_le`) et sourcée (`source` https officielle), `valide_jours: 30` porté par le manifeste — comptage exact `30 6 46 18 6 5 7 5`.
- `check-agents.sh` ne porte plus aucune des six listes en dur : `charger_manifeste()` valide le schéma complet (fail-closed), `charger_referentiel()` les charge paresseusement (seulement s'il existe une cible à juger — la branche cible vide F13 reste inchangée). Un manifeste absent/illisible/invalide imprime une ligne `MANIFESTE-ILLISIBLE` sans jamais la séquence " : " (pour que `guard-agent-write.sh` applique son fail-open documenté), puis `exit 0` sous `--hook`, `exit 1` sinon.
- `copy_module_scripts()` de `vibeflow-update.sh` pose désormais les fichiers `*.json` des modules (Site #3bis, D-16) — sans quoi le manifeste n'atteindrait aucun lab installé et le gate refuserait partout.
- `test-check-agents.sh` rebranché sur un harnais à manifeste daté du jour (`mk_gate_dir`/`mk_manifest`, 11 opérations de mutation) — T77 à T82 prouvent le refus sur manifeste absent/illisible/invalide, la source unique (D-01), le contenu D-17, et le fail-open de la garde d'écriture sous `--hook`.
- D-20 fermé : `cible_absente = (not single) and not os.path.isdir(agents_dir)` dans la branche `else` de la boucle principale ; hors `--hook`, une cible absente rend `exit 3` avec le jeton `CIBLE-ABSENTE`, distinct du jeton F13 existant. Ferme `.planning/codebase/CONCERNS.md:349` (sévérité MEDIUM).

## Task Commits

Chaque tâche a été committée atomiquement :

1. **Tâche 1 (tracer) — commit (a) installeur + T54** — `672a8fe` (fix)
2. **Tâche 1 (tracer) — commit (b) manifeste + gate** — `ba312e0` (feat)
3. **Tâche 2 (tdd) — harnais à manifeste du jour, T77-T82** — `bb36787` (test)
4. **Tâche 3 (tdd) — D-20, cible absente hors --hook** — `a9e98ac` (fix)

_Note : tâche 1 est `type="tracer"` (deux commits, production-quality, jamais jetable) ; tâches 2 et 3 sont `tdd="true"` mais le plan spécifiait explicitement UN commit chacune (implémentation déjà posée en tâche 1 pour la tâche 2 ; implémentation + test couplés pour la tâche 3) — suivi tel qu'écrit dans `<action>` plutôt que le patron générique test→feat→refactor._

## Files Created/Modified

- `plugin/conductor/scripts/check-agents-manifest.json` — manifeste daté versionné (nouveau)
- `plugin/conductor/scripts/check-agents.sh` — chargement fail-closed du manifeste, D-20
- `plugin/conductor/scripts/tests/test-check-agents.sh` — harnais à manifeste du jour, T77-T82, T103
- `plugin/_internal/vibeflow-update.sh` — Site #3bis (boucle `*.json`)
- `plugin/_internal/tests/test-vibeflow-update.sh` — T54 (discriminant)

## Decisions Made

- Toutes les décisions de cadrage (D-01 à D-20) proviennent de `42-CONTEXT.md`, tranchées par Claude sur délégation explicite de Willy (AskUserQuestion session principale, 2026-09-23) — voir le champ `key-decisions` en frontmatter pour le détail par décision.
- Choix d'implémentation locaux (Claude's Discretion, dans le périmètre déjà cadré par le plan) : structure exacte de `charger_manifeste()`/`charger_referentiel()`, sanitation de la ligne `MANIFESTE-ILLISIBLE` (remplacement de toute séquence " : " par " - "), et les 11 opérations de mutation exposées par `mk_manifest` dans le harnais de test.

## Deviations from Plan

None — plan exécuté exactement comme écrit. Les 12 "correctifs de revue" déjà intégrés au texte du plan (W1-W6, I2, I3, corrections `revise-42b`/`revise-42c`) ont été suivis tels quels, pas redécouverts.

## Inventaire des appelants (tâche 3, D-20) — CONFIRMÉ appelant par appelant à l'exécution

1. **Hook SessionStart** (`hooks.json` l.22, `--hook --agents-dir=…`) — hors périmètre (D-20 exclut `--hook`), déjà couvert par T56 : **INCHANGÉ**. Confirmé par la suite `LAB-HOOK-SILENCIEUX-OK` (lab frais, `.claude/agents` retiré, `--hook` → rc=0, sortie vide).
2. **`guard-agent-write.sh`** — invoque le bloc Python en mode `--file` sur un fichier toujours présent : ne passe jamais par la branche `if not files:` : **INCHANGÉ**. Suite `test-guard-agent-write.sh` rejouée verte.
3. **`check-blueprints.sh`** — matérialise un frontmatter dans un fichier temporaire existant puis appelle le gate en `--file` : **INCHANGÉ**. Suite `test-check-blueprints.sh` rejouée verte, 9 blueprints toujours conformes.
4. **Les trois étapes `check-agents` du job `gates` de `ci.yml`** (bouclent sur `plugin/*/agents`, dossiers réels non vides, ou `--file` sur `AGENT.md` réels) : **INCHANGÉ**. Rejoué localement : `for d in plugin/*/agents; do check-agents.sh --strict --agents-dir="$d"; done` → rc=0 sur les 6 dossiers.
5. **L'étape « Gate C du lab frais »** (`ci.yml`, `.claude/scripts/check-agents.sh --strict` après install de conductor — `.claude/agents/conductor-references/` existe) : **INCHANGÉ**, et cet appel passe déjà `--strict` donc le régime F13 s'appliquait indépendamment de cette tâche.
6. **L'installeur** (`vibeflow-update.sh`) — n'invoque jamais le gate : **sans objet**.
7. **`scripts/tests/test-hook-exit-parc.sh`** (l.183-185) — invoque le gate réel avec `--strict --agents-dir="$FIX"` où `$FIX` est un `mktemp -d` PRÉSENT (cible vide, pas absente) : **INCHANGÉ**, confirmé en relisant le code (`FIX="$(mktemp -d -p "$CASES_DIR")"`, dossier créé donc `os.path.isdir` vrai, `cible_absente` reste `False`) et en rejouant la suite (verte).
8. **Les suites de module qui invoquent le gate réel sur leur propre dossier d'agents PRÉSENT** (`test-business-pilot-bundle.sh`, `test-content-bundle.sh`, `test-growth-bundle.sh`, `test-design-orchestrator.sh`, `test-dev-orchestrator.sh`, dont ses cas T8c/T20 sur `AGENT.md` réel) : cible toujours PRÉSENTE (le dossier du module existe dans ce dépôt) : **INCHANGÉ** — confirmé en rejouant les 5 suites (toutes vertes, 0 `SUITE-ROUGE`).
9. **Les auto-prescriptions imprimées par le gate lui-même** (texte affiché à l'utilisateur, jamais une invocation exécutée par le script) : **sans objet** pour le comportement — la forme reste bare aujourd'hui, cohérente avec l'invocation que cette tâche corrige.
10. **`.planning/codebase/CONCERNS.md:349`** (« Le gate ADR-044 est un faux vert dans son invocation nue », sévérité MEDIUM) : **FERMÉ** par cette tâche — l'entrée décrivait exactement le défaut corrigé (D20-OK confirmé).
11. **Aucun appelant du dépôt n'invoquait, avant cette tâche, le gate SANS `--strict` ET SANS `--hook` ET SANS `--file` sur une cible absente** — c'est le trou que `CONCERNS.md` nommait « invocation nue » et que T103 couvre désormais. Un lab frais sans `.claude/agents` ne rencontre cette branche que via l'appel `--hook` du SessionStart, qui reste exempté (point 1) — **aucun lab frais ne devient rouge par effet de bord**.
12. **`plugin/validator/AGENT.md:67`** (« Conformité agents » : `bash .claude/scripts/check-agents.sh --strict`) — prescription textuelle exécutée par un agent, pas par le harnais de test : `.claude/agents/` existe déjà dans tout lab où cet audit tourne : **INCHANGÉ**.
13. **`plugin/conductor/skills/vf-new-lab/SKILL.md:257`** (GATE C, étape 2 : `bash .claude/scripts/check-agents.sh --strict`) — même nature de prescription textuelle, exécutée après que l'installeur ait posé au moins `conductor-references/` sous `.claude/agents/` : **INCHANGÉ**.

**Résidu signalé, hors périmètre de ce plan (ne PAS corriger) :** le commentaire
`plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh:2291` (« check-agents.sh SANS
argument sort exit 0 trivialement sur ce dépôt … vert vide ») est PÉRIMÉ après D-20 — une
invocation nue sur cible absente hors `--hook` rend désormais INDÉTERMINÉ (exit 3,
CIBLE-ABSENTE), pas exit 0 vert vide. La ligne 2292 a été relue et citée verbatim ci-dessus.
T20 de ce fichier utilise `--file` (pas l'invocation nue) et reste inchangé — aucun fichier de
`dev-orchestrator` n'est touché par ce plan.

## Issues Encountered

None.

## User Setup Required

None - aucune configuration de service externe requise.

## Next Phase Readiness

- Le manifeste daté est en place et lu de bout en bout (jusqu'au lab installé) : 42-04 peut
  poser la fraîcheur (`--manifest-freshness=lenient|strict`, `MANIFESTE-PERIME`, rétrogradation
  D-05) sur cette fondation sans la redéfinir.
- `MUT-D20` (mutant de la ligne `cible_absente`) est explicitement laissé à 42-04 (helpers de
  mutation `make_gate_mutant`/`okmut`/`komut` posés en vague 2 de 42-04) — T103 de ce plan est
  une assertion directe (rc + sortie), pas un mutant, comme prescrit par le plan.
- `charger_manifeste()`/`charger_referentiel()` sont les points d'extension attendus par 42-04
  pour la fraîcheur (`manifest_perime()` s'appuiera sur les mêmes `verifie_le` déjà validés ici).
- Aucun blocage connu pour 42-02/42-03 (mise en conformité du corpus I3/I5/I6) ni pour 42-05/42-06
  (invariants I1-I7, découverte récursive) — ce plan ne les a pas touchés.

---
*Phase: 42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des*
*Completed: 2026-09-24*

## Self-Check: PASSED

- FOUND: plugin/conductor/scripts/check-agents-manifest.json
- FOUND: 42-01-SUMMARY.md (ce fichier)
- FOUND: commits 672a8fe, ba312e0, bb36787, a9e98ac, ef9a824
