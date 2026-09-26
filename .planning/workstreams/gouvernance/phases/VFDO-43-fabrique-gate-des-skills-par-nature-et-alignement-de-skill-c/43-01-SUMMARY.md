---
phase: 43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-creator
plan: 01
subsystem: infra
tags: [gate, skills, frontmatter, manifest, bash, python, mutation-testing]

# Dependency graph
requires:
  - phase: 42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des
    provides: "check-agents.sh (contrat 0/1/3, découverte récursive, manifeste daté), check-agents-manifest.json (six listes natives)"
provides:
  - "check-skills.sh : gate des skills par nature (vf-nature, défaut « outil »), refus d'une procédure sans ecrit:/vf-rubrique-juge (FABR-06)"
  - "Manifeste daté étendu à sept listes (champs_frontmatter_skills), validé identiquement par check-agents.sh et check-skills.sh (FABR-09)"
  - "Contrat de clés VIBEFLOW_SKILL_FIELDS (vf-nature, ecrit, vf-rubrique-juge, vf-gate-bloquant, vf-livrable-tiers, vf-couche-qualite) consommé par 43-02/43-03"
affects: [43-02, 43-03, 44, 50]

# Actuals (#2632)
actuals:
  tokens: 17745
  tasks: 3
  commits: 4

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Gate miroir de check-agents.sh (contrat 0/1/3, hook_exit, découverte récursive avec deux exclusions mutation-prouvées, F13, --file, --third-party-prefix)"
    - "Code Python embarqué via here-document à délimiteur quoté (aucune interpolation shell), paramètres passés en variables d'environnement VF_*"
    - "Harnais de mutation avec vérification à deux étages (bash -n puis compilation du corps Python extrait du here-document) — un mutant tronqué ne peut jamais passer pour tué"

key-files:
  created:
    - plugin/conductor/scripts/check-skills.sh
    - plugin/conductor/scripts/tests/test-check-skills.sh
    - .planning/workstreams/gouvernance/phases/VFDO-43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-c/43-BASE-PHASE.md
  modified:
    - plugin/conductor/scripts/check-agents-manifest.json
    - plugin/conductor/scripts/check-agents.sh
    - plugin/conductor/scripts/tests/test-check-agents.sh

key-decisions:
  - "Contrat de clés (D-Q1, costly) : six clés VibeFlow (vf-nature, ecrit, vf-rubrique-juge, vf-gate-bloquant, vf-livrable-tiers, vf-couche-qualite) en dur dans VIBEFLOW_SKILL_FIELDS — jamais dans le manifeste daté (même frontière que D-01 de la Phase 42)"
  - "Manifeste unique (Claude's Discretion) : septième liste native champs_frontmatter_skills ajoutée au MÊME check-agents-manifest.json ; check-agents.sh élargi en lockstep (cles_listes à sept clés) dans le même commit que la liste"
  - "Découverte générique : l'exclusion du module doc-only plugin/reference n'est jamais un nom de module en dur dans check-skills.sh — elle est portée par l'invocation (qui lit module.json avant d'appeler le gate)"
  - "Identité dans les messages : chemin relatif à --skills-dir (jamais le seul nom de base SKILL.md, qui n'identifie rien) ; --file conserve le chemin tel que passé"
  - "Fraîcheur scopée : seule la liste champs_frontmatter_skills est jugée par check-skills.sh (les six autres restent hors périmètre, jugées par check-agents.sh) ; pas d'option --manifest-freshness — la péremption reste toujours un avertissement, jamais un exit 3"

patterns-established:
  - "Toute valeur de frontmatter imprimée passe par une fonction unique d'échappement (repr Python tronqué à 80 caractères) — jamais réinjectée telle quelle dans la sortie ni passée à un shell"
  - "Harnais de test make_gate_mutant : le refus d'un mutant (motif absent, mutation non opposable, bash -n en échec, corps Python non compilable) est TOUJOURS un KO visible — jamais appelé en substitution de commande (bug I1 documenté et gardé par MUT-REFUS-COMPTE)"

requirements-completed: [FABR-06, FABR-09]

coverage:
  - id: D1
    description: "check-skills.sh découvre récursivement les SKILL.md, lit le manifeste daté à sept listes, et refuse une procédure sans ecrit:/vf-rubrique-juge (tracer)"
    requirement: "FABR-06"
    verification:
      - kind: integration
        ref: "plugin/conductor/scripts/tests/test-check-skills.sh#T1-T5"
        status: pass
    human_judgment: false
  - id: D2
    description: "Validation stricte des valeurs (vf-nature, ecrit:, vf-rubrique-juge, marqueurs, champ inconnu, frontmatter adverse)"
    requirement: "FABR-06"
    verification:
      - kind: integration
        ref: "plugin/conductor/scripts/tests/test-check-skills.sh#T6-T13,MUT-S1-S3"
        status: pass
    human_judgment: false
  - id: D3
    description: "Parité de contrat avec check-agents.sh : découverte à trois profondeurs, exclusions, liens symboliques, tiers, F13, --hook, --file, fraîcheur"
    verification:
      - kind: integration
        ref: "plugin/conductor/scripts/tests/test-check-skills.sh#T14-T21,MUT-SD1-SD2,MUT-SYNTAXE,MUT-REFUS-COMPTE"
        status: pass
    human_judgment: false
  - id: D4
    description: "Manifeste daté étendu à sept listes (champs_frontmatter_skills), check-agents.sh élargi en lockstep, non-régression du gate des agents"
    requirement: "FABR-09"
    verification:
      - kind: integration
        ref: "plugin/conductor/scripts/tests/test-check-agents.sh#T107"
        status: pass
      - kind: integration
        ref: "plugin/conductor/scripts/tests/test-check-agents.sh (suite complète)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Lab frais posé par l'installeur (module conductor) : check-skills.sh et le manifeste à sept listes sont présents et rendent rc 0 en --strict, check-agents.sh du même lab reste rc 0"
    verification:
      - kind: e2e
        ref: "témoin TRACER-SKILLS-OK (verify de la Tâche 1)"
        status: pass
    human_judgment: false

duration: ~40min
completed: 2026-09-26
status: complete
---

# Phase 43 Plan 01: Gate des skills par nature (check-skills.sh) — tracer, validation stricte, parité de contrat

**Nouveau gate `check-skills.sh`, miroir de `check-agents.sh`, qui lit un manifeste daté étendu à sept listes et refuse toute procédure déclarée sans `ecrit:`/`vf-rubrique-juge:`, avec 21 cas de test et sept mutants.**

## Performance

- **Duration:** ~40 min (estimation — l'heure de début exacte de la lecture initiale n'a pas été horodatée ; les commits git couvrent 15:47–16:13 CEST)
- **Started:** ~2026-09-26T13:35:00Z
- **Completed:** 2026-09-26T14:14:51Z
- **Tasks:** 3
- **Files modified:** 6 (3 créés, 3 modifiés)

## Accomplishments

- `check-skills.sh` posé de bout en bout : découverte récursive (`decouvrir_skills`, deux exclusions mutation-prouvées), manifeste daté partagé à sept listes (`champs_frontmatter_skills`), `vf-nature` en énumération stricte (défaut « outil » sur clé absente, jamais sur valeur invalide), `vf-nature: procedure` refusée sans `ecrit:` ni `vf-rubrique-juge:` (FABR-06)
- Validation stricte des valeurs (V5, énumération/refus explicite) : `ecrit:` et `vf-rubrique-juge:` en chemins relatifs propres (charset Unicode-aware, refus de `..`, `/` et `~` initiaux), les trois marqueurs `vf-gate-bloquant`/`vf-livrable-tiers`/`vf-couche-qualite` en `true|false` strict, avertissement « champ inconnu », aucun octet ESC brut réinjecté dans la sortie
- Parité de contrat complète avec `check-agents.sh` : F13 (cible absente/vide), silence de code sous `--hook`, `--file`, exclusion des skills tiers par préfixe (compteur séparé), fraîcheur de la seule liste `champs_frontmatter_skills` (avertissement, jamais un refus)
- `check-agents-manifest.json` étendu d'une septième liste native (champs de frontmatter d'un SKILL.md, doc Anthropic relue le 2026-09-26) ; `check-agents.sh` élargi en lockstep (T107 : un manifeste amputé de cette liste reste refusé)
- 53 cas verts dans `test-check-skills.sh` (T1 à T21, 7 mutants) ; `test-check-agents.sh` reste à 177 OK · 0 KO (176 préexistants + T107) ; corpus réel (15 modules non doc-only, 21 SKILL.md) jugé vert ; témoin lab frais `TRACER-SKILLS-OK`

## Task Commits

Chaque tâche a été commitée atomiquement, plus le commit de base de phase préalable :

0. **Base de phase (Tâche 1, étape 0)** — `76937d7` (docs) : `.planning/.../43-BASE-PHASE.md`, fichier unique, commit séparé, sujet exact `docs(43): base de phase figée`
1. **Tâche 1 : tracer — check-skills.sh, manifeste à sept listes, découverte, refus FABR-06 (T1-T5)** — `c22e265` (feat)
2. **Tâche 2 : validation stricte des valeurs (T6-T13, MUT-S1 à MUT-S3)** — `a07bdcc` (feat)
3. **Tâche 3 : parité de contrat avec check-agents.sh (T14-T21, MUT-SD1/SD2, gardes du harnais)** — `b2ad140` (test)

**Plan metadata:** ce fichier + STATE/ROADMAP/REQUIREMENTS sont commités par l'orchestrateur après la vague (mode parallèle — worktree)

## Files Created/Modified

- `plugin/conductor/scripts/check-skills.sh` — nouveau gate des skills par nature (executable, ~514 lignes)
- `plugin/conductor/scripts/tests/test-check-skills.sh` — nouvelle suite (T1-T21, MUT-S1-S3, MUT-SD1/SD2, MUT-SYNTAXE, MUT-REFUS-COMPTE ; ~867 lignes)
- `plugin/conductor/scripts/check-agents-manifest.json` — septième liste `champs_frontmatter_skills` (verifie_le 2026-09-26, source https://code.claude.com/docs/en/skills, 20 valeurs)
- `plugin/conductor/scripts/check-agents.sh` — `cles_listes` élargie à sept clés, trois commentaires « six »→« sept » corrigés
- `plugin/conductor/scripts/tests/test-check-agents.sh` — T107 (manifeste amputé de la septième liste refusé), libellé de succès de T84 sans glyphe de croix
- `.planning/workstreams/gouvernance/phases/VFDO-43-.../43-BASE-PHASE.md` — base de phase figée (SHA 22179fa5...)

## Decisions Made

Voir `key-decisions` en frontmatter (contrat de clés, manifeste unique, découverte générique, identité dans les messages, fraîcheur scopée). Toutes reprises telles qu'arbitrées dans le corps du plan (43-01-PLAN.md, action de la Tâche 1, étape 1) — aucune décision nouvelle prise pendant l'exécution.

## Deviations from Plan

### Auto-fixed Issues

None au sens des Règles 1-3 (aucun bug, aucune fonctionnalité critique manquante, aucun blocage) — le gate a été écrit conformément au plan et tous les cas de test sont passés au premier essai après les seuls ajustements de fixtures ci-dessous.

**1. [Ajustement de process, sans impact fonctionnel] Fixture T14 complétée d'un SKILL.md à la racine**
- **Found during:** vérification de MUT-SD1 (Tâche 3)
- **Issue:** la fixture T14 initiale ne portait aucun SKILL.md directement à la racine de `--skills-dir` ; sous le mutant qui vide la liste des sous-dossiers (plus aucune descente), la découverte devenait totalement vide, ce qui bascule le gate sur la branche F13 (`--strict` → rc=3) au lieu du rc=0 attendu par MUT-SD1 (« mutant opposable, aucune violation vue »)
- **Fix:** ajout d'un SKILL.md conforme à la racine de `T14_DIR` (survit à la neutralisation de l'élagage puisqu'aucune descente n'est nécessaire pour le découvrir) — n'affecte aucune assertion de T14 elle-même (toujours rc=1, toujours cite `c/sub/deep/SKILL.md`, toujours ignore README.md/notes.md)
- **Files modified:** `plugin/conductor/scripts/tests/test-check-skills.sh` (fixture uniquement, aucun changement au gate)
- **Verification:** MUT-SD1 TUE (`rc_mutant=0`, `rc_original=1`)
- **Committed in:** `c22e265` (fixture posée dès la Tâche 1, réutilisée par MUT-SD1 en Tâche 3)

**2. [Écart de trailer, documenté] Aucun `Gate-Touche:` pour check-skills.sh dans le commit de la Tâche 3**
- **Found during:** commit de la Tâche 3
- **Issue:** le plan (action, étape 4) prescrit verbatim un trailer `Gate-Touche:` pour `check-skills.sh` ET pour `test-check-skills.sh` sur le commit de la Tâche 3. En pratique, `check-skills.sh` a été livré COMPLET dès la Tâche 1 (découverte, F13, `--hook`, `--file`, tiers, fraîcheur — tout ce que la Tâche 3 vérifie existait déjà) ; le commit de la Tâche 3 ne touche donc RÉELLEMENT que `test-check-skills.sh` (`git diff --stat` : 1 fichier changé)
- **Fix:** trailer `Gate-Touche:` posé uniquement pour `plugin/conductor/scripts/tests/test-check-skills.sh` sur ce commit — un trailer citant un chemin absent du diff aurait été une déclaration inexacte (« un trailer = un chemin réellement touché »). `check-skills.sh` reste couvert par les trailers des commits de la Tâche 1 (`c22e265`) et de la Tâche 2 (`a07bdcc`) ; G-2 (`check-gate-touche.sh`) juge la couverture à l'échelle de la BRANCHE, pas du commit (voir son en-tête, § « PORTEE BRANCHE, PAS COMMIT »), donc cette omission ne dégrade aucune garde
- **Files modified:** aucun (choix de rédaction du message de commit)
- **Verification:** `git diff --stat` du commit `b2ad140` ne montre que `test-check-skills.sh` ; `bash scripts/check-gate-touche.sh` (hors périmètre de vérification de ce plan, non rejoué ici) resterait vert grâce aux trailers déjà posés en Tâches 1/2
- **Committed in:** `b2ad140` (Tâche 3)

**3. [Révision ciblée du témoin `MERGES-DANS-LA-PLAGE`, post-vague 2] Restriction aux merges de l'amont uniquement**
- **Found during:** révision ciblée pré-vague 4 (43-06), après le constat que `B43..HEAD` contient 3 merges INTERNES à la vague 2 (`f8cba29`, `40b0da8`, `450ab9c`), dont tous les parents ont B43 pour ancêtre — le témoin d'origine les comptait tous, ce qui aurait fait rougir 43-06 à coup sûr sans qu'aucun commit étranger à la Phase 43 n'ait été introduit
- **Issue:** le témoin d'origine (`git rev-list --merges "$B43"..HEAD | grep -c .`) ne distinguait pas un merge interne d'une vague (tous parents descendants de B43, inoffensif) d'un merge qui fait entrer l'amont (au moins un parent qui n'a pas B43 pour ancêtre, la vraie menace que le témoin doit garder)
- **Fix:** le témoin compte désormais, parmi les commits de merge de `B43..HEAD`, ceux dont AU MOINS UN parent échoue `git merge-base --is-ancestor "$B43" <parent>` — un merge interne de vague reste admis, un merge de l'amont continue de faire rougir le témoin (VOULU, retour à l'humain). Forme de commande portable zsh/bash : `while IFS= read -r … ; done <<< "$var"` (pas de `for x in $var`, pas de compteur perdu dans un pipe). Décision : option A, « décision du head sous délégation technique de Willy, session principale, 2026-09-26 »
- **Files modified:** `43-01-PLAN.md` (texte du témoin + commande), `43-06-PLAN.md` (commande du verify, `<fails_when>` correspondant)
- **Verification:** sur une copie jetable clonée depuis ce HEAD — ancienne commande sur HEAD (3 merges internes) : `MERGES-DANS-LA-PLAGE 3` ; nouvelle commande sur le même HEAD : `MERGES-DANS-LA-PLAGE 0`, rejouée sous `zsh` ET `bash` ; nouvelle commande après fabrication d'un merge amont jetable (branche forkée depuis `af0acb5`, parent de B43) : `MERGES-DANS-LA-PLAGE 1`, rejouée sous `zsh` ET `bash`. La règle « intégration amont par rebase uniquement » (43-01) reste inchangée — un merge de l'amont fait toujours rougir le témoin.
- **Committed in:** commit de cette révision (voir `git log`)

---

**Total deviations:** 3 ajustements documentés, aucun auto-fix au sens des Règles 1-4 (aucun bug, aucune fonctionnalité manquante, aucun blocage, aucun changement architectural).
**Impact on plan:** Aucun — le gate final, les 53 cas de `test-check-skills.sh` et les 177 cas de `test-check-agents.sh` (dont T107) sont conformes à toutes les `<acceptance_criteria>` des trois tâches, vérifiées ci-dessous.

## Issues Encountered

None — hormis la correction de process suivante, sans impact sur le résultat livré : le premier jet d'exécution avait écrit `check-skills.sh` et `test-check-skills.sh` avec la portée COMPLÈTE des trois tâches (T1 à T21, sept mutants) en un seul commit, violant la granularité par tâche exigée par le plan et le protocole d'exécution (un commit par tâche). Corrigé par `git reset --soft` vers le commit de base de phase puis reconstruction incrémentale en trois commits fidèles à la portée de chaque tâche (Tâche 1 : T1-T5 seulement, `errors.extend` limité à `valider_nature`/`invariant_procedure` ; Tâche 2 : ajout de `valider_ecrit`/`valider_rubrique_juge`/`valider_marqueurs`/champ-inconnu + T6-T13 + MUT-S1-S3 ; Tâche 3 : ajout de T14-T21 + MUT-SD1/SD2/SYNTAXE/REFUS-COMPTE, sans nouveau code de gate). Le fichier final est identique à celui du premier jet (vérifié par `diff`) ; seule la découpe en commits a changé. Toutes les suites ont été rejouées vertes après chaque commit reconstruit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Le contrat de clés (`vf-nature`, `ecrit`, `vf-rubrique-juge`, `vf-gate-bloquant`, `vf-livrable-tiers`, `vf-couche-qualite`) et la septième liste du manifeste sont posés et stables — 43-02 (détection de dérive FABR-07) et 43-03 (alignement `skill-creator`) peuvent s'appuyer dessus sans réouvrir ce contrat.
- `requirements.mark-complete` n'a PAS été appelé par cet exécuteur (mode parallèle — worktree ; mandat de dispatch : ne pas toucher STATE.md/ROADMAP.md, l'orchestrateur les met à jour après la vague). FABR-06 et FABR-09 sont à cocher à la main dans `REQUIREMENTS.md` du compartiment `gouvernance`, comme précédent établi pour FABR-02 (Phase 42, vague 2, note STATE.md du 2026-09-25).
- Aucun câblage CI (`.github/workflows/ci.yml`) ni hook (`plugin/conductor/hooks/hooks.json`) n'a été posé pour `check-skills.sh` — hors `files_modified` de ce plan (43-CONTEXT.md/43-PATTERNS.md le notent explicitement comme à trancher séparément) ; un futur plan devra le faire pour que ce gate soit réellement invoqué en CI/SessionStart plutôt que seulement disponible.
- Blocage connu du jalon (rappel non modifié par ce plan) : aucune exécution ultérieure de la Phase 43 avant la clôture de `fiabilite-v1.0` — voir `STATE.md` du compartiment `gouvernance`.

---
*Phase: 43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-creator*
*Completed: 2026-09-26*

## Self-Check: PASSED

- Fichiers créés présents sur disque : `plugin/conductor/scripts/check-skills.sh`, `plugin/conductor/scripts/tests/test-check-skills.sh`, `43-BASE-PHASE.md` — tous trouvés.
- Commits trouvés dans `git log --oneline --all` : `76937d7` (base de phase), `c22e265` (Tâche 1), `a07bdcc` (Tâche 2), `b2ad140` (Tâche 3).
- `bash plugin/conductor/scripts/tests/test-check-skills.sh` : 53 OK · 0 KO (T1-T21, MUT-S1-S3, MUT-SD1/SD2, MUT-SYNTAXE, MUT-REFUS-COMPTE).
- `bash plugin/conductor/scripts/tests/test-check-agents.sh` : 177 OK · 0 KO (T107 compris, non-régression confirmée).
- Témoin lab frais (HOME temporaire) : `TRACER-SKILLS-OK`.
- Toutes les `<acceptance_criteria>` des trois tâches rejouées vertes (BASE-PHASE-OK, T84-LOGIQUE-IDENTIQUE, MANIFESTE-7-OK, greps `errors.extend(...)`/`cles_listes`/exclusions, couverture Gate-Touche du commit de la Tâche 1).
- `git diff --stat 22179fa5..HEAD` ne montre que les 6 fichiers déclarés dans `files_modified` du plan — aucun fichier hors périmètre touché.
