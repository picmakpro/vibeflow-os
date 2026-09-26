---
phase: 43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-creator
plan: 04
subsystem: infra
tags: [gate, skills, bootstrap, budget-instructions, bash, awk, mutation-testing, ratchet]

# Dependency graph
requires:
  - phase: 43-01
    provides: "43-BASE-PHASE.md (base de phase figée, seule source de la référence de phase B43)"
provides:
  - "check-instruction-budget.sh : seconde découverte récursive des SKILL.md (VF_SKILL_LINE_CAP=500, ADR-029), verdict DEPASSEMENT-SKILL-ADR029, lignes corpus/BILAN-SKILLS (FABR-09)"
  - "check-instruction-budget.sh : métrique bootstrap ratchet-socle (VF_BOOTSTRAP_TOKEN_CAP=2000), verdicts DEPASSEMENT-BOOTSTRAP (bloquant) et AU-DESSUS-PLAFOND-ADR029 (non bloquant), ligne BOOTSTRAP (FABR-09, D-Q4)"
  - "Ligne de baseline @bootstrap:socle dans .planning/instruction-budget-baselines.tsv (0, 2499), citée, signalée à la revue code owner de Samuel"
  - "Décision bootstrap (Q1, ratchet-socle) consignée avec sa citation exacte et ses trois motifs"
  - "Suite : SKILL-1 à SKILL-6, BOOT-1 à BOOT-5, mutants MUT-8 à MUT-12 (64 cas, 0 ko)"
affects: [43-06]

# Actuals (#2632) — chars/4 sur le diff réalisé (git diff, 3 fichiers), jamais un compte harnais.
actuals:
  tokens: 13054
  tasks: 3
  commits: 2
  plan_head_before: 25a916ba7dee9c2c866a150466f40c542ff44a37

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Extension additive d'un gate existant (Pattern 3, 43-RESEARCH.md) : la découverte D-03 des agents et ses fonctions génériques (frontmatter_state, lines_count) restent inchangées ; une seconde découverte et une seconde mesure s'ajoutent sans réécriture, leurs compteurs rejoignant les branches de code de sortie existantes (rc 0/1/2/3), aucun nouveau code"
    - "find avec parenthèses QUOTÉES ('(' ... ')'), jamais échappées (\\( ... \\)) : évite le piège de awk -v qui traite les séquences d'échappement non reconnues dans les valeurs -v et avale silencieusement un backslash suivi d'une parenthèse (mesuré cette session sur MUT-10, cf. Déviations)"
    - "Mesure de métadonnées de frontmatter par clé nommée (name/description/when_to_use) avec continuation, ancrée sur le même frontmatter_state (NR==1) que le reste du gate — une seule définition, testée indépendamment (BOOT-1) et sur le dépôt réel"

key-files:
  created: []
  modified:
    - plugin/conductor/scripts/check-instruction-budget.sh
    - plugin/conductor/scripts/tests/test-check-instruction-budget.sh
    - .planning/instruction-budget-baselines.tsv

key-decisions:
  - "Q1 (bootstrap) — TRANCHÉE avant exécution, non rouverte : option ratchet-socle, décision déléguée par Willy au head (/vf-decide), AskUserQuestion session principale, 2026-09-26. Consignée verbatim à la Tâche 2 (réponse, citation, trois motifs, application) avant toute écriture de baseline."
  - "Commit atomique unique pour le code de la métrique bootstrap, sa suite ET la ligne de baseline (Tâche 3, étape 7) — jamais deux commits : soit ordre laisserait un commit intermédiaire à rc 2 sur le dépôt réel armé (prouvé par le rejeu commit par commit, REJEU, rc 0 aux deux commits du plan)."
  - "Clé @bootstrap:socle exclue explicitement du calcul des entrées orphelines (comm -23 sur les chemins de baseline vs fichiers d'agents découverts) — sans cette exclusion, toute exécution armée aurait rendu rc 2 en classant la clé bootstrap comme orpheline (BOOT-2e)."
  - "find avec parenthèses quotées plutôt qu'échappées dans la seconde découverte des SKILL.md — auto-fix Rule 3 (bloquant) : awk -v absorbe les backslashes non reconnus des valeurs qu'il reçoit, ce qui rendait MUT-10 NON OPPOSABLE (mutation silencieusement absente) ; corrigé dans le script ET dans le test avant le premier commit, jamais contourné."

requirements-completed: [FABR-09]

coverage:
  - id: D1
    description: "Seconde découverte récursive des SKILL.md (trois profondeurs, exclusion module doc-only, élagage caché/-references, symlinks non suivis) et plafond ADR-029 de 500 lignes, bloquant"
    requirement: "FABR-09"
    verification:
      - kind: integration
        ref: "plugin/conductor/scripts/tests/test-check-instruction-budget.sh#SKILL-1..SKILL-6,MUT-8..MUT-10"
        status: pass
      - kind: integration
        ref: "dépôt réel : REEL rc=0 skills=21 (21 SKILL.md découverts, 4 exclus sous plugin/reference doc-only)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Métrique bootstrap ratchet-socle (définition octets/4 sur name/description/when_to_use du socle minimal), verdicts DEPASSEMENT-BOOTSTRAP bloquant et AU-DESSUS-PLAFOND-ADR029 non bloquant, ligne de baseline @bootstrap:socle citée et posée dans le même commit que la métrique"
    requirement: "FABR-09"
    verification:
      - kind: integration
        ref: "plugin/conductor/scripts/tests/test-check-instruction-budget.sh#BOOT-1..BOOT-5,MUT-11,MUT-12"
        status: pass
      - kind: integration
        ref: "dépôt réel : REEL-BOOT rc=0 mesure=2499 ligne=2499 ; scripts/check-baseline-arbitrage.sh CONFORME rc=0 ; REJEU rc=0 sur les deux commits du plan"
        status: pass
    human_judgment: false
  - id: D3
    description: "Décision bootstrap (Q1, ratchet-socle) consignée telle que déléguée par Willy, citation exacte, trois motifs, application, mesure du jour vs mesure de planification"
    requirement: "FABR-09"
    verification:
      - kind: other
        ref: "commande DECISION-Q1-FIN du verify de la Tâche 2 (grep -qF de la réponse, citation, motifs, @bootstrap:socle, AU-DESSUS-PLAFOND-ADR029)"
        status: pass
    human_judgment: false

duration: ~2h (session unique, forte densité de vérification indépendante)
completed: 2026-09-26
status: complete
---

# Phase 43 Plan 04: Plafond SKILL.md et métrique bootstrap ratchet-socle Summary

**Extension additive de check-instruction-budget.sh : plafond ADR-029 des SKILL.md (500 lignes, bloquant) et métrique bootstrap (octets/4 sur name/description/when_to_use du socle minimal), ratchet sur une ligne de baseline `@bootstrap:socle` citée et signalée à la revue de Samuel.**

Base du plan : 25a916ba7dee9c2c866a150466f40c542ff44a37

## Décision bootstrap (Q1)

**Réponse :** ratchet-socle

**Citation** (mot pour mot, seule sur sa ligne) :
décision déléguée par Willy au head (/vf-decide), AskUserQuestion session principale, 2026-09-26

**Motifs** (recopiés tels quels du bloc de contexte de `43-04-PLAN.md`) :
- Willy a choisi de couvrir réellement le bootstrap (Q4), ce qui écarte l'option « avertissement seul » ;
- un plafond dur bloquerait la Phase 43 sur des modules qui appartiennent à Samuel ;
- un ratchet sur tout le corpus distribué viserait un lab hypothétique, pas le socle réel que tout lab porte.

**Application retenue :** la mesure du jour devient la ligne `@bootstrap:socle` de
`.planning/instruction-budget-baselines.tsv` ; toute hausse bloque (verdict `DEPASSEMENT-BOOTSTRAP`,
rc 1 sous ratchet armé, rc 3 non armé — jamais rc 0, jamais un simple avertissement) ; une mesure
au-dessus de 2000 tokens mais sans hausse sur la ligne publie `AU-DESSUS-PLAFOND-ADR029`, non
bloquant : le plafond ADR-029 de 2000 reste un objectif, inscrit au BACKLOG (commit `433fea0`,
section « Ramener le socle du bootstrap sous 2 000 tokens (ADR-029) — DIFFÉRÉ (2026-09-26) »).

**Mesure du jour (2026-09-26, Tâche 2 — rejouée en lecture seule, définition unique du bloc de
contexte de `43-04-PLAN.md`)** — corpus = fermeture `VF_MODULES_ROOT=plugin bash
plugin/_internal/resolve-deps.sh conductor` (audit-architecture, conductor, consolidator,
infrastructure-audit, planning-core, skill-creator, validator), plus le skill désigné par le champ
`skills` de `plugin/.claude-plugin/plugin.json` (`./installer`), plus les 7 commandes
`plugin/commands/*.md` :

| Source | Octets | Tokens |
|---|---|---|
| conductor (vf-calibrate 1070, vf-new-lab 1174, vf-update 953, vf-notify 796) | 3 993 | 998 |
| planning-core | 1 075 | 268 |
| skill-creator (skill-creator-workflow 674, skill-creator 355) | 1 029 | 257 |
| consolidator | 884 | 221 |
| audit-architecture | 818 | 204 |
| infrastructure-audit | 487 | 121 |
| validator (aucun SKILL.md) | 0 | 0 |
| installer (skill exposé, sans `module.json`) | 535 | 133 |
| 7 commandes `plugin/commands/*.md` | 1 176 | 294 |
| **Total (11 SKILL.md + 7 commandes = 18 fichiers)** | **9 997** | **2 499** |

**Mesure de planification (2026-09-25, `43-CONTEXT.md`)** : ≈ 2 499 tokens (9 997 octets sur 11
SKILL.md + 1 176 octets de commandes). **Écart avec la mesure du jour : aucun** — les deux mesures
sont identiques au bit près (re-mesurée à l'identique le 2026-09-26, définition unique appliquée
telle quelle, aucun corpus ni méthode ajustés).

## Signalement à la revue de Samuel

Hash du commit qui ajoute la ligne `@bootstrap:socle` : `c3a62c9f0b2ec86da07d86df1bc3f77199ca6167`
(rendu par `git rev-list <Base du plan>..HEAD -- .planning/instruction-budget-baselines.tsv`).

Ligne ajoutée à `.planning/instruction-budget-baselines.tsv` : `@bootstrap:socle	0	2499` — colonne
lignes `0` (sans objet pour cette clé), colonne instructions `2499` (tokens estimés, octets/4).
C'est l'UNIQUE ligne ajoutée depuis la base du plan ; aucune autre valeur de la baseline n'a bougé.

Citation portée par ce commit, mot pour mot, seule sur sa ligne :
décision déléguée par Willy au head (/vf-decide), AskUserQuestion session principale, 2026-09-26

`.planning/instruction-budget-baselines.tsv` est un chemin CODEOWNERS : la PR qui porte ce commit
exige la revue code owner de Samuel, ou un contournement tracé (D-02bis, `CLAUDE.local.md`).

**Limite nommée** : `scripts/check-baseline-arbitrage.sh` (G-1) ne classe que les lignes présentes
à la fois à la base ET à HEAD de la plage jugée — une ligne AJOUTÉE (absente à la base, présente à
HEAD) n'est ni une hausse ni un retrait pour cette garde, elle lui échappe entièrement. Sa garde ne
porte que sur les HAUSSES FUTURES de la ligne `@bootstrap:socle`, une fois posée : c'est cette
revue-ci (code owner ou contournement tracé) qui couvre son introduction. `bash
scripts/check-baseline-arbitrage.sh` sur le dépôt réel après ce commit : `CONFORME`, rc 0.

**Mesure de la ligne BOOTSTRAP et écart avec la Tâche 2** : la ligne `BOOTSTRAP :` du script sur le
dépôt réel, après ce commit, rend `2499 tokens estimes (octets/4) sur socle (18 fichiers), plafond
2000, ligne 2499, verdict AU-DESSUS-PLAFOND-ADR029` — rc 0. Identique à la mesure de la Tâche 2
(2 499 tokens, 9 997 octets, 18 fichiers). **Écart : aucun**, sur aucune source (conductor,
planning-core, skill-creator, consolidator, audit-architecture, infrastructure-audit, installer,
commandes) — la métrique implémentée à la Tâche 3 applique exactement la définition rejouée en
lecture seule à la Tâche 2, sans qu'aucun corpus ni méthode n'ait été ajusté entre les deux.

## Performance

- **Tasks:** 3/3 completed
- **Files modified:** 3 (plugin/conductor/scripts/check-instruction-budget.sh, plugin/conductor/scripts/tests/test-check-instruction-budget.sh, .planning/instruction-budget-baselines.tsv)
- **Suite finale :** 64 cas, 0 ko (`== resultat : 64 ok, 0 ko ==`)

## Accomplishments

- Seconde découverte récursive des SKILL.md (trois profondeurs, module doc-only entièrement exclu, dossiers cachés et `*-references` élagués, symlinks retenus mais rendus NON-VERIFIABLE), plafond ADR-029 de 500 lignes bloquant, aucun seuil d'avertissement (ADR-029 n'en définit pas pour les skills).
- Métrique bootstrap ratchet-socle : définition unique (octets sous `LC_ALL=C` + 1 par ligne mesurée de frontmatter `name`/`description`/`when_to_use`, continuations comprises, ÷4), corpus résolu via `resolve-deps.sh conductor` + skill `installer` + commandes du plugin, verdicts `DEPASSEMENT-BOOTSTRAP` (bloquant) et `AU-DESSUS-PLAFOND-ADR029` (non bloquant, plafond 2000).
- Décision bootstrap (Q1, ratchet-socle) consignée avec sa citation exacte, ses trois motifs et la mesure du jour — identique au bit près à la mesure de planification (2 499 tokens, 9 997 octets, 18 fichiers).
- Ligne de baseline `@bootstrap:socle` (0, 2499) posée dans le même commit atomique que le code de la métrique et sa suite, citée, signalée à la revue code owner de Samuel avec le hash réel du commit.
- Dépôt réel : `check-instruction-budget.sh` rc 0 (21 SKILL.md, 4 exclus, ligne BOOTSTRAP = ligne baseline, verdict `AU-DESSUS-PLAFOND-ADR029`) ; `scripts/check-baseline-arbitrage.sh` (G-1) `CONFORME`, rc 0 ; rejeu commit par commit (REJEU) rc 0 aux deux commits du plan.

## Task Commits

Each task was committed atomically:

1. **Tâche 1 : seconde découverte récursive des SKILL.md et plafond de 500 lignes** - `fb097cc` (feat) — `plugin/conductor/scripts/check-instruction-budget.sh`, `plugin/conductor/scripts/tests/test-check-instruction-budget.sh` (SKILL-1 à SKILL-6, MUT-8 à MUT-10)
2. **Tâche 2 : décision bootstrap (Q1) consignée dans 43-04-SUMMARY.md** - pas de commit de code (fichier `.planning/` déféré au commit final de ce SUMMARY, `43-04-PLAN.md` ne l'exige pas à cette tâche)
3. **Tâche 3 : métrique bootstrap ratchet-socle, ligne @bootstrap:socle** - `c3a62c9` (feat) — commit ATOMIQUE unique portant le code, la suite (BOOT-1 à BOOT-5, MUT-11, MUT-12) ET la ligne de baseline, avec la citation de la décision et la ligne `Chemin CODEOWNERS`

**Plan metadata:** commit courant (docs: complete plan) — `43-04-SUMMARY.md`, `.planning/STATE.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md` exclus (mode worktree, propriété de l'orchestrateur)

## Files Created/Modified

- `plugin/conductor/scripts/check-instruction-budget.sh` - seconde découverte SKILL.md + plafond 500 lignes ; métrique bootstrap ratchet-socle
- `plugin/conductor/scripts/tests/test-check-instruction-budget.sh` - SKILL-1 à SKILL-6, BOOT-1 à BOOT-5, mutants MUT-8 à MUT-12
- `.planning/instruction-budget-baselines.tsv` - ligne `@bootstrap:socle	0	2499`, citée

## Decisions Made

Voir `key-decisions` en frontmatter : Q1 tranchée en amont (non rouverte), commit atomique de la métrique bootstrap et de sa ligne de baseline, exclusion de `@bootstrap:socle` du calcul des entrées orphelines, correction de la forme des parenthèses `find` (voir Déviations).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Parenthèses `find` échappées incompatibles avec `awk -v` dans le harnais de mutation (MUT-10)**
- **Found during:** Tâche 1, écriture du mutant MUT-10 (élagage `*-references`)
- **Issue:** la seconde découverte des SKILL.md utilisait `\( ... \)` (parenthèses échappées) dans la commande `find`. `awk -v old="..."` traite les séquences d'échappement non reconnues dans la valeur reçue et absorbe silencieusement le backslash devant une parenthèse — la comparaison exacte de ligne (`$0 == old`) du harnais de mutation ne matchait donc jamais cette ligne : MUT-10 rendait "mutant identique à l'original — NON OPPOSABLE" alors que le script vivant était intact.
- **Fix:** remplacé `\( ... \)` par des parenthèses **quotées** (`'('` ... `')'`) dans `check-instruction-budget.sh` — comportement `find` strictement identique (POSIX : les deux formes protègent la parenthèse du shell), mais la ligne devient reproductible telle quelle dans une valeur `awk -v`. `MUT10_OLD`/`MUT10_NEW` alignés en conséquence.
- **Files modified:** plugin/conductor/scripts/check-instruction-budget.sh, plugin/conductor/scripts/tests/test-check-instruction-budget.sh
- **Verification:** MUT-10 passe (`rc_original=0, rc_mutant=1`), suite complète à 0 ko, dépôt réel inchangé (rc 0, 21 SKILL.md).
- **Committed in:** fb097cc (commit de la Tâche 1)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Correction technique interne au harnais de test, sans effet sur le contrat public du gate (contrat de sortie, découverte, verdicts inchangés). Aucun élargissement de portée.

## Note d'écart — correctifs post-revue (3 tours, mandats vf-coder ciblés)

La revue sur `d7dc755` a rendu « correctifs requis » sur ce plan après sa clôture initiale. Trois
mandats de correction CIBLÉE (aucun cadrage, aucune replanification) ont suivi, tous confinés au
périmètre de ce plan (`check-instruction-budget.sh`, sa suite, `.planning/BACKLOG.md`) :

- **Tour 1** (commits `bb23de7`, `a2201c1`) : trois findings — (1) [majeur] oracle de test
  `boot_expected_bytes()` tautologique (copie littérale de `bootstrap_measure_file()` du script) ;
  remplacé par une somme arithmétique de longueurs de chaînes littérales (`boot_line_bytes`,
  `boot_expected_total`), indépendante du parseur ; nouveau mutant permanent `MUT-13` prouve la
  discrimination (attendu 107 / obtenu 97 tokens sur le script muté, même sous-compte reproduit
  par l'ancien oracle re-muté) ; (2) [majeur] code de sortie du `find` de découverte principale
  (l.192 à ce jour) jamais testé — corrigé, corpus SKILL bascule en NON-VÉRIFIABLE (rc 2) sur
  échec partiel ; (3) [mineur] `SKILL_FIELD_MOD` ne retirait pas un `/` final. Entrée BACKLOG
  distincte pour le faux vert connu et non corrigé d'`inject-mcp-tools.sh --verify` (hors
  périmètre `dev-orchestrator`, option B).
- **Tour 3** (commit à suivre après cette note, HEAD `e5288f3` → au-delà) : la re-revue a clos les
  findings 1 et 3 du tour 1 mais pas le 2 — incomplet : seul le `find` de la découverte principale
  était instrumenté, pas celui de la branche doc-only (l.191, comptage `SKILL_EXCLUDED`), qui
  partage exactement le même défaut de classe. Corrigé sur les DEUX sites d'appel de `find` du
  script (liste exhaustive vérifiée : ce sont les deux seuls). Nouveau cas `SKILL-DISC-2` (chmod
  000 sur un sous-dossier doc-only contenant un SKILL.md) : rouge avant (rc=0, « 0 exclu(s) »
  silencieux — repro confirmée), vert après (rc=2, NON-VÉRIFIABLE). `${SKILL_FIELD_MOD%/}` ne
  retirait qu'UNE occurrence de `/` final ; normalisé en boucle jusqu'à point fixe (cas `BOOT-7`,
  `"./installer//"`). En-tête de section de la suite (l.665-668 à l'état du tour 1) corrigé —
  nommait encore `boot_expected_bytes` (supprimée) et affirmait à tort « jamais recopiée en dur ».

**Impact sur le plan :** aucun élargissement de portée — corrections internes au gate et à sa
suite, contrat public (codes de sortie, verdicts, découverte) inchangé. Vérifié à chaque tour :
rc du gate sur le dépôt réel inchangé (0 avant/après), `check-gate-touche.sh` et
`check-baseline-arbitrage.sh` conformes.

## Issues Encountered

None - au-delà de la déviation ci-dessus, résolue avant le premier commit.

## User Setup Required

None - aucune configuration de service externe requise.

## Next Phase Readiness

- FABR-09 est couvert par ce plan pour son volet SKILL.md + bootstrap (le volet manifeste/champs de skills relève de 43-01, déjà livré).
- `43-06` (vague 4, garde G-2 `check-gate-touche.sh`) peut lire les trailers `Gate-Touche` des deux commits de ce plan.
- Le BACKLOG conserve, en lecture seule pour ce plan, l'entrée « Ramener le socle du bootstrap sous 2 000 tokens (ADR-029) — DIFFÉRÉ (2026-09-26) » (commit `433fea0`) : le plafond reste un objectif, non traité ici par décision du plan.
- Aucun blocage connu pour la suite de la Phase 43.

## Self-Check: PASSED

- FOUND: plugin/conductor/scripts/check-instruction-budget.sh (VF_SKILL_LINE_CAP=500, VF_BOOTSTRAP_TOKEN_CAP=2000, bootstrap_measure_file, BOOTSTRAP block)
- FOUND: plugin/conductor/scripts/tests/test-check-instruction-budget.sh (SKILL-1..6, BOOT-1..5, MUT-8..12 — 64 ok, 0 ko)
- FOUND: .planning/instruction-budget-baselines.tsv (`@bootstrap:socle	0	2499`)
- FOUND: commit fb097cc (`git log --oneline --all | grep fb097cc`)
- FOUND: commit c3a62c9 (`git log --oneline --all | grep c3a62c9`)

---
*Phase: 43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-creator*
*Plan: 04*
*Completed: 2026-09-26*
