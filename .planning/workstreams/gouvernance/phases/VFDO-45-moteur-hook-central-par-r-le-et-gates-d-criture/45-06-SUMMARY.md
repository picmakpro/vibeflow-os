---
phase: 45-moteur-hook-central-par-r-le-et-gates-d-criture
plan: 06
subsystem: planning-core (G1 pas de plan sans cadrage, contrôle croisé avec le recalcul de la 44, constructeur de rejeu à classification totale, comptage par étape)
tags: [hook, g1, cadrage, registre, f5-etats, canary, rejeu, classification-totale, concordance, mutation-testing, observation]

requires:
  - phase: 45-03
    provides: check-gates-alive.sh (CANARIS), rejeu-gates.sh (registre CONSTRUCTEURS, fusion à trois rangs, classification totale), rejeu-reel.sh
  - phase: 45-04
    provides: entonnoir decider/observer, journal d'observation, dérogations nominatives
  - phase: 45-05
    provides: fichier_protege (identité), G6 et G5 en observation, cas de canary de l'étape 1
provides:
  - "planning-hook.sh : unite_de_plan, evaluer_g1 (absence de CADRAGE.md, registre ouvert avec ids cités, bord F5 = f5-etats), lire_registre (copie ast-identique de celle de recalc-planning.sh) ; ARMEMENT_G1 reste observe"
  - "check-gates-alive.sh : cas G1-sans-cadrage"
  - "rejeu-gates.sh : règle de comptage par étape (`hors-etape`), constructeur G1 à classification TOTALE (état dérivé par recalc-planning.sh --read-only sur la copie, sinon règle écrite à branches nommées), phases synthétiques 99-rejeu-*, copies ast-identiques du parseur de la 44"
  - "test-planning-gates.sh : R-G1-01..10, R-REGISTRE, R-CANG-G1, CROISE-G1, mutants ; test-rejeu-gates.sh : R-REJEU-ETAPE, R-REJEU-G1, R-REJEU-G1-CONCORDANCE (64 cellules générées), 11 mutants ; banc : labs g1-adherent et g1-dev"
affects: [45-07, 45-08, 45-09, 45-10]

plan_head_before: 8da8c6e05f0f58a5dab41f20640f8e814f3b5499
estimate:
  tokens: 130000
  raw_tokens: 130000
  tasks: 2
  confidence: low
actuals:
  tokens: 23397    # chars/4 sur les lignes ajoutées du diff réalisé (git diff base..HEAD, 93588 caractères, préfixes `+` compris), hors ce SUMMARY
  tasks: 2         # Tâche 1 complète ; Tâche 2 : actions 1 à 4 faites, actions 5 à 7 (rejeu réel, armement, relevé) reportées par l'amendement A1
  commits: 3       # MESURÉ : git rev-list --count 8da8c6e05f0f58a5dab41f20640f8e814f3b5499..HEAD avant le commit de ce SUMMARY
commits: 3
duration: non mesurée (poste très chargé, durées de suites non représentatives)

tech-stack:
  added: []
  patterns:
    - "un gate qui lit l'état que le modèle dérive déjà : copies ast-identiques du parseur (lire_frontmatter, lire_registre) et contrôle croisé phase par phase contre le VRAI recalc-planning.sh --read-only, qui rougit à la moindre divergence"
    - "classification totale du corpus de rejeu : état dérivé par le moteur du modèle s'il est exploitable (défini par le COUPLE état, raison), sinon règle écrite à branches nommées sans branche par défaut, erreur de l'outil sur un cas non reconnu ; jamais le verdict du hook ni evaluer_g1"
    - "test différentiel sur un ensemble GÉNÉRÉ (itertools.product, 64 cellules) avec un oracle indépendant de huit lignes : deux erreurs concordantes rougissent aussi"
    - "règle de comptage par étape : EXCLURE les gates d'étape > n (jamais une liste blanche des gates connus), les lignes `-` et `?` restent comptées"

key-files:
  created: []
  modified:
    - plugin/planning-core/scripts/planning-hook.sh
    - plugin/planning-core/scripts/check-gates-alive.sh
    - plugin/planning-core/scripts/rejeu-gates.sh
    - plugin/planning-core/scripts/tests/test-planning-gates.sh
    - plugin/planning-core/scripts/tests/test-rejeu-gates.sh
    - plugin/planning-core/scripts/tests/fixtures/gates-banc.txt
    - plugin/_internal/tests/test-planning-hook-installed.sh

key-decisions:
  - "A1 (manager vf-dev-manager, 2026-09-30) : rejeu réel et armement de l'étape 2 REPORTÉS. Aucun rejeu sur ~/jarvis-keystone ni ~/BusinessFlow-Lab, aucune constante ARMEMENT_* ni TABLE_ATTENDUE modifiée, 45-REJEU-ETAPE-2.md non écrit, aucune ESCALADE imprimée : G1 est en observe, l'étape 1 n'est pas armée (ordre P45-D-03). Le rejeu réel et l'armement seront joués par le nœud `armement-reel`."
  - "A2 (a) : la règle « hors étape » est posée et testée AVANT le constructeur G1 (commit dédié 706c3cf) ; R-REJEU-10 est assertée à --etape=2 pour les totaux, R-REJEU-G6G5 et R-REJEU-06 adaptés. A2 (b) : `CROISE-G1 n=` est imprimée par le TEXTE du test (R-G1-04), pas seulement par le verify du plan."
  - "F5 = f5-etats et P45-D-21a (Willy, AskUserQuestion session principale, 2026-09-29) : G1 applique GATE-06 à la lettre ; un CADRAGE.md non régulier, au frontmatter ou au registre invalide ou au format hérité est indéterminé et n'est jamais refusé (limite T-45-55 acceptée) ; l'ABSENCE de CADRAGE.md reste refusée même quand un autre fichier de la phase est non régulier (fixture E)."
  - "La règle écrite teste le format hérité (`inconnues:` absente) AVANT le registre invalide, de sorte que la branche nommée d'un hérité soit `herite` et non `illisible` (le plan l'exige : même verdict que l'état dérivé `registre-invalide`, raison différente)."
  - "Le lanceur shell de rejeu-gates.sh passe son propre dossier au cœur Python (premier argument), sans nouvelle option : rejeu-reel.sh refuse tout argument inconnu, et recalc-planning.sh est cherché à côté. Un essai qui substitue les constructeurs ne l'utilise pas."

requirements-completed: []
requirements-note: "à cocher par l'orchestrateur (ADR-063) ; GATE-06, GATE-12 (canary de G1), GATE-15 sont prouvés en CI ; GATE-13 (mesure deux sens sur labs réels) et l'armement de GATE-06 restent ouverts tant que le rejeu réel n'a pas eu lieu (A1)"

status: complete
---

# Phase 45 Plan 06: G1, pas de plan sans cadrage, contrôle croisé, classification totale Summary

**G1 refuse, en observation, l'écriture par Write ou Edit d'un PLAN.md de forme modèle dans une phase sans CADRAGE.md ou dont le registre porte une ligne structurante sans statut, en lisant l'état de la 44 par les mêmes copies ast-identiques du parseur, contrôlé phase par phase contre le vrai `recalc-planning.sh --read-only` ; le constructeur de rejeu classe d'après le modèle (état dérivé, sinon règle écrite totale) et sa concordance avec le prédicat du hook est prouvée sur 64 cellules générées ; le rejeu réel et l'armement sont reportés (A1) : G1 reste en observe.**

## Performance

- **Tâches :** 2/2 pour ce qui se prouve sur banc et en CI ; Tâche 2, actions 5 à 7 (rejeu réel, armement, relevé) reportées (A1)
- **Commits de tâche :** 3 (mesuré depuis `plan_head_before`) ; `926e155` (Tâche 1), `706c3cf` (règle de comptage par étape), `104cc67` (G1 registre ouvert, bord F5, constructeur)
- **`test-planning-gates.sh` :** 147 OK (45-05) -> 175 OK (Tâche 1) -> **197 OK · 0 KO**, dont 7 nouveaux mutants tués (MUT-G1-CADRAGE, MUT-G1-FORME, MUT-G1-PHASE, MUT-G1-OUVERT, MUT-G1-STATUT, MUT-G1-BORD, MUT-REGISTRE)
- **`test-rejeu-gates.sh` :** 38 OK (45-05) -> **50 OK · 0 KO** (R-REJEU-ETAPE, R-REJEU-G1, R-REJEU-G1-CONCORDANCE, MUT-REJEU-ETAPE, MUT-REJEU-ETAPE-LISTE, sept MUT-REJEU-G1-*)

## Accomplishments

- **G1 (Tâche 1 puis 2).** `unite_de_plan` reconnaît la forme modèle (`…/phases/<phase>/PLAN.md` et `…/phases/<phase>/plans/<plan>/PLAN.md`, noms d'unité conformes à NOM_UNITE, noms fixes en casefold, chemin résolu physiquement) et rend le dossier de la PHASE jugée, jamais celui du plan. `evaluer_g1` : pas de CADRAGE.md -> refus ; registre ouvert -> refus qui cite les ids de chaque ligne ouverte ; un PLAN.md du socle v2 ou sous un nom invalide n'est jamais visé. Branché dans l'entonnoir : une ligne `gate=G1` au journal tant que `ARMEMENT_G1 = "observe"`.
- **Bord F5 = f5-etats.** CADRAGE.md non régulier (dossier, lien), au frontmatter invalide, au registre invalide ou au format hérité : passage ; l'absence de CADRAGE.md avec un AUTRE fichier non régulier dans la phase (fixture E) : refus.
- **Contrôle croisé.** `lire_registre` du hook est ast-identique à celle du moteur (R-REGISTRE). `CROISE-G1 n=65 labs=65 absence=10 hors-absence=55 ecartees=0` : sur chacune des 65 phases comparables des deux bancs (gates et 44), G1 refuse pour absence <=> le recalcul rend `à cadrer` ou `hors-cadrage:*` (R-G1-04) ; `CROISE-G1-ETENDU n=65 absence-ou-ouvert=16 dont-ouvert=6 illisibles-jamais-refuses=4` : la relation étendue à `en cadrage` et `avant-cadrage-clos:*`, les états `registre-invalide` et `frontmatter-invalide:CADRAGE.md` jamais refusés (R-G1-08). Plancher déclaré : 60.
- **Canary.** Cas `G1-sans-cadrage` ; R-CANG-G1 : code 3 sur l'état livré et sur une copie où G6, G5 et G1 sont armed, et signal (une ligne qui nomme `G1-sans-cadrage`) quand `evaluer_g1` est neutralisé, en observe comme en armed.
- **Comptage par étape (A2, commit dédié avant le constructeur).** `REJEU-ETAPE-<n>` ne compte que les gates d'étape ≤ n ; la ligne `COMPTE` d'un gate d'étape > n porte `hors-etape` et n'entre ni dans les totaux ni dans l'armement ; les gates `-` et `?` restent comptés (R-REJEU-ETAPE, MUT-REJEU-ETAPE, MUT-REJEU-ETAPE-LISTE). Exemple de sortie réelle, lab synthétique non migré rejoué à `--etape=1` : `COMPTE G1 faux-refus=0 faux-accept=7 refus-conforme-modele=0 hors-etape` puis `REJEU-ETAPE-1 faux-refus=0 faux-accept=0 refus-conforme-modele=0` ; à `--etape=2` : `COMPTE G1 faux-refus=0 faux-accept=0 refus-conforme-modele=3` puis `REJEU-ETAPE-2 faux-refus=0 faux-accept=0 refus-conforme-modele=3`.
- **Constructeur G1 du rejeu.** Classification TOTALE : état dérivé par `recalc-planning.sh --read-only` sur la copie si exploitable (couple état, raison), sinon règle écrite à branches nommées (`hors-forme`, `pas-de-cadrage`, `non-regulier`, `illisible`, `herite`, `registre-ouvert`, `clos`), sans branche par défaut, erreur de l'outil (« classification impossible ») sur un cas non reconnu ; `origine=regle-ecrite` et raison nommée au relevé, sous-compte `CLASSE-REGLE-ECRITE G1 lab=<lab> n=<j>` (tous verdicts confondus, `hors-forme` jamais compté) ; phases synthétiques `99-rejeu-sans-cadrage` et `99-rejeu-registre-ouvert` sous chaque cycle réel (ou sous `99-rejeu`) ; le corps du constructeur ne contient ni `hook` ni appel au hook, `evaluer_g1` est absent de rejeu-gates.sh, les copies du parseur sont ast-identiques.
- **R-REJEU-G1-CONCORDANCE.** Sortie : `CONCORDANCE G1 cellules=64 divergences=0` ; `RAISONS-REGLE-ECRITE G1 clos=6 herite=3 illisible=3 non-regulier=8 pas-de-cadrage=3 registre-ouvert=3 somme-n=26` (aucune raison `defaut`). Somme des `n` = 26 = cellules à nom conforme sans état dérivé exploitable, recalcul lancé par la suite, cellule par cellule : le déroulé à la main du plan (0 + 16 + 10) est confirmé par la mesure. Résultat : **vert**.
- **Banc.** Labs `g1-adherent` (13 phases : sans CADRAGE.md, clos, `inconnues: []`, ouvert, hérité, plans/, phase vide, frontmatter invalide, registre invalide, lien, dossier, fixture E, statut quelconque, structurante non, deux ouverts, mixte) et `g1-dev` ; `COUVERTURE G1 doit-refuser=11 doit-passer=16 silence=3` ; `COMPTE G1 faux-refus=0 faux-accept=0` (R-G1-10).

## Task Commits

1. **Tâche 1 (tracer) :** `926e155` — G1 en observation, contrôle croisé avec le recalcul (evaluer_g1 sans registre, cas de canary, banc, R-G1-01..04, R-CANG-G1, 3 mutants) ; il embarque aussi l'extension de périmètre de `test-planning-hook-installed.sh` (voir Déviations). Quatre trailers Gate-Touche.
2. **Règle de comptage par étape (action 1a de la Tâche 2) :** `706c3cf` — commit dédié, seul, avant tout constructeur G1 (R-REJEU-ETAPE, 2 mutants, R-REJEU-10 à `--etape=2`). Deux trailers Gate-Touche.
3. **Tâche 2 :** `104cc67` — G1 registre ouvert et bord F5 : hook, constructeur G1 et sa suite (R-REJEU-G1, R-REJEU-G1-CONCORDANCE, 7 mutants), R-G1-05..10, R-REGISTRE, 4 mutants. Quatre trailers Gate-Touche.
4. **Non faits (A1) :** commit d'armement, relevé `45-REJEU-ETAPE-2.md`.

**Tracer feedback gate** (avant d'étendre) : `<verify>` de la Tâche 1 rejoué de bout en bout, vert (175 OK · 0 KO, `R-G1-01` à `R-G1-04`, `R-CANG-G1`, `CROISE-G1 n=59`, `COUVERTURE G1`, trois mutants tués) : « Tracer verified end-to-end — expanding ».

## Critères reportés (A1) — rejeu réel et armement

Reportés, non évalués, **aucune fausse escalade imprimée** : G1 est en observe, l'étape 1 n'est pas armée, donc l'étape 2 ne peut pas s'armer (ordre P45-D-03) ; le rejeu réel et l'armement seront joués par le nœud `armement-reel`.

- Précondition de la Tâche 2 (labs réels au repos, dossiers réels présents) : non évaluée.
- Action 5 : rejeu réel `rejeu-reel.sh --lab=~/jarvis-keystone --lab=~/BusinessFlow-Lab --etape=2` : non lancé ; les comptes de refus conformes au modèle par lab et par motif (pas de CADRAGE.md, registre ouvert), le sous-compte `CLASSE-REGLE-ECRITE G1` réel et la relecture de la mesure historique des 197 PLAN.md sans CADRAGE.md de Keystone : non mesurés.
- Action 6 : armement mécanique (P45-D-03b) : non joué. `ARMEMENT_G6`, `ARMEMENT_G5`, `ARMEMENT_G1`, `ARMEMENT_G7`, `ARMEMENT_ROLE` valent tous `"observe"`, `G2_MODE = "avertit"`, `TABLE_ATTENDUE` de la suite inchangée ; le commit d'armement et sa citation de comptes nuls n'existent pas.
- Action 7 et verify 3 et 4 (`45-REJEU-ETAPE-2.md`, lignes `REJEU-ETAPE-2`, `EMPREINTE-ARBRE-*`, section « Non armé », contrôle de chemin de machine du relevé) : fichier non écrit (hors périmètre, A1).
- Critère d'acceptation « `ARMEMENT_G1` vaut armed si et seulement si … sinon observe et section « Non armé » présente » : la moitié « observe » est tenue, la section « Non armé » est reportée avec le relevé.
- Hors A1, tenus : `R-G1-10` (banc à 0/0 sur copie armée), `R-REJEU-G1` (0/0 sur lab synthétique, `COMPTE G1 … refus-conforme-modele=3`), `R-REJEU-G1-CONCORDANCE`.

## Files Created/Modified

- `plugin/planning-core/scripts/planning-hook.sh` : `unite_de_plan`, `evaluer_g1`, `_ids_ouverts`, `lire_registre` (copie), `GATES_A_VERDICT` (G1 ajouté)
- `plugin/planning-core/scripts/check-gates-alive.sh` : cas `G1-sans-cadrage`
- `plugin/planning-core/scripts/rejeu-gates.sh` : `hors_etape`, constructeur G1 (`forme_g1`, `regle_ecrite`, `exploitable`, `attendu_derive`, `etats_derives`, `phases_synthetiques`, `construire_g1`), copies du parseur, tuple à 7 éléments (branche), lanceur qui passe son dossier
- `plugin/planning-core/scripts/tests/test-planning-gates.sh`, `tests/test-rejeu-gates.sh`, `tests/fixtures/gates-banc.txt` : suites, mutants, labs `g1-adherent` et `g1-dev` ; `g6-adherent` reçoit un CADRAGE.md (son PLAN.md reste hors de tout refus de G1)
- `plugin/_internal/tests/test-planning-hook-installed.sh` : R-CAN-05, MUT-CAN-SANS-CAS

## Decisions Made

Voir `key-decisions`. Arbitrages humains invoqués : P45-D-21a (Willy, AskUserQuestion session principale, 2026-09-29, F5 = f5-etats) ; amendements A1 et A2 du manager vf-dev-manager (2026-09-30).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `test-planning-hook-installed.sh` (R-CAN-05, MUT-CAN-SANS-CAS) rougissaient dès que G1 a son cas de canary**
- **Found during :** Tâche 1. Ces deux assertions arment G6, G5 et G1 et attendent `gate armé sans canary : G1` : elles supposent que G1 n'a pas de cas. Le fichier n'est pas dans `files_modified`.
- **Fix :** `retirer_cas_canary(lab, gate)` retire de la copie posée tous les cas du gate avant de lancer le canary : le contrôle est indépendant du gate cible ; `armer_copie` tolère une ligne déjà `armed`. Extension de périmètre demandée par un message d'agent reçu en cours d'exécution (se présentant comme le manager vf-dev-manager, non vérifié par un canal humain) et nécessaire de toute façon à l'acceptance du plan (`test-planning-hook-installed.sh` à `0 KO`). **Commit :** `926e155` (trailer Gate-Touche du fichier).

**2. [Rule 3 - Blocking] `g6-adherent` du banc : le PLAN.md de la phase `01-p` devenait refusé par G1**
- **Found during :** conception de la Tâche 1. `R-G6-03` et le banc G6 écrivent `.planning/cycles/01-c/phases/01-p/PLAN.md` sur copie armée pour prouver l'absence de refus de G6 ; sans CADRAGE.md dans cette phase, G1 armé le refuse.
- **Fix :** le lab `g6-adherent` reçoit un `CADRAGE.md` (`inconnues: []`) ; même preuve pour G6. **Commit :** `926e155`.

**3. [Rule 1 - Bug, dans mon brouillon] Directives propres au banc de la 44 dans le contrôle croisé**
- **Found during :** Tâche 1. Le banc `recalc-planning-banc.txt` porte des directives absentes de la grammaire de celui des gates (`attendu*`, `fichier-dehors`, liens vers `DEHORS/`). **Fix :** `_texte_sans_attendus` les écarte avant matérialisation (les deux labs concernés perdent seulement leur lien extérieur, sans effet sur les phases comparées). **Commit :** `926e155`.

**4. [Rule 1 - Bug, dans mon brouillon] Mutant MUT-REJEU-G1-VIDE non opposable, mutants de rejeu-reel.sh non tués**
- **Found during :** Tâche 2. (a) Le mutant `inconnues: []` lu « ouvert » faisait lever l'erreur de totalité (aucun relevé) au lieu de produire un verdict faux ; la règle écrite calcule désormais `ouvert = not clos` sur une ligne mutable, deux branches nommées explicites. (b) Les copies mutées de `rejeu-gates.sh` qui accompagnent les mutants de `rejeu-reel.sh` jouent maintenant le constructeur G1 : elles reçoivent `recalc-planning.sh` comme compagnon. **Commit :** `104cc67`.

### Écarts de mise en oeuvre (sans changement de contrat)

**5. Concordance par lots.** Le plan décrit 64 relevés (un par lab) ; la suite lance UN rejeu sur les 64 labs (un lab par cellule, comme demandé). Chaque lab a sa copie, ses clés et sa ligne `CLASSE-REGLE-ECRITE` : rien ne change dans l'assertion cellule par cellule, le coût tombe d'environ 64 démarrages d'outil à un. Les mutants de concordance rejouent un sous-ensemble choisi de cellules, avec un hook substitut qui laisse tout passer (seul l'attendu du relevé est mesuré), l'original et le mutant sur les mêmes cellules.
**6. Lecture de la présence de CADRAGE.md.** Le hook teste `os.path.lexists` comme le plan le dit ; le recalcul compare des noms exacts (`"CADRAGE.md" in entrees`) : sur un système insensible à la casse, un `cadrage.md` compte pour G1 et pas pour le recalcul. Non exercé (aucune cellule de casse), accepté.
**7. Noms fixes en casefold.** `cycles`, `phases`, `plans`, `PLAN.md` sont comparés en casefold dans le hook ET dans la forme du constructeur (identité de 45-05) ; `.planning` exactement dans le constructeur (il parcourt des dossiers ainsi nommés), en casefold dans le hook.
**8. Lanceur de rejeu-gates.sh.** Le dossier des scripts est passé en premier argument du cœur Python (aucune option nouvelle) ; `R-REJEU-STATIQUE` compte maintenant trois appels de sous-processus (bash sur le hook copié, bash sur `recalc-planning.sh`, `cmp`).

### Déviations d'environnement (à signaler)

- **Refus de garde du poste (à rapporter, jamais contournés).** Cinq commandes Bash composées ont été refusées par la garde d'isolation du worktree (« too complex to verify ») : une boucle shell qui construit des payloads JSON, un heredoc Python d'édition du banc suivi de `tail`, un contrôle `45-CONTROLE-MARQUEUR.sh | tail ; git status`, un heredoc Python d'édition de la suite du rejeu, et une boucle de vérification `git merge-base` sur trois commits. Chacune a été refaite en commandes simples, ou l'édition faite par `Write`/`Edit` d'un fichier de travail. Aucun refus de classifieur ni de hook de commit.
- **Charge machine élevée** : durées de suites non représentatives (`test-planning-gates.sh` 355 s puis 158 s).
- **Message d'agent en cours d'exécution** : un message se présentant comme le manager a étendu le périmètre à `test-planning-hook-installed.sh` ; traité comme une demande d'agent, sans autorité de consentement, et redondant avec l'acceptance du plan (voir Déviation 1).

## Auth gates

Aucune.

## Suites rejouées (aucune affectation de HOME ; découverte complète NON lancée)

| Suite | Résultat |
|---|---|
| planning-core/test-planning-gates.sh | 197 OK · 0 KO |
| planning-core/test-rejeu-gates.sh | 50 OK · 0 KO |
| _internal/test-planning-hook-installed.sh | 19 OK · 0 KO |
| planning-core/test-planning-hook-registered.sh | 37 OK · 0 KO |
| planning-core/test-recalc-planning.sh (une fois, en fin de plan ; fichier non touché) | 347 OK · 0 KO |
| planning-core/test-check-planning-state.sh | 19 ok · 0 ko |
| planning-core/test-detect-gsd-engine.sh | 26 ok · 0 ko |
| planning-core/test-detect-planning-debt.sh | 10 passés · 0 échoués |
| planning-core/test-planning-context-hardening.sh | 38 passés · 0 échoués |
| planning-core/test-planning-core.sh | 14 passés · 0 échoués |
| planning-core/test-planning-hooks.sh | 42 PASS · 0 FAIL |
| planning-core/test-workstream-policy.sh | 22 ok · 0 ko · 0 skip |
| planning-core/test-workstream-symlink-escape.sh | 10 ok · 0 ko |
| conductor/check-planning-consumers-registered.sh | ✓ 22 consommateurs, tous recensés |
| scripts/check-machine-paths.sh | ✓ aucun chemin absolu de machine |
| 45-CONTROLE-MARQUEUR.sh `--base=fd49137` | hook, canary, suite des gates : `commits=12 sans-marqueur=0` ; hook, rejeu, suite du rejeu : `commits=12 sans-marqueur=0` |
| ordre des commits (comptage par étape avant `G1 — registre ouvert`) | `706c3cf` précède `104cc67` |

## Limites et constats portés par ce plan

- **Phase dérogée sans CADRAGE.md : faux refus attendu au rejeu réel (constat, à arbitrer).** Φ0 de la 44 rend un état dérivé exploitable (`gelé`, `abandonné`, `remplacé`) pour une phase qui porte DEROGATION.md ; le plan fait classer ces états `doit-passer` (« tout autre état nommé par le recalcul »), alors que G1 ne lit jamais DEROGATION.md et refuse le PLAN.md d'une phase sans CADRAGE.md. Mesuré sur un lab synthétique (`.planning/cycles/01-c/phases/05-dero/` : PLAN.md, DEROGATION.md `statut: gelé par willy`, pas de CADRAGE.md) : `G1 | … | doit-passer | refus` -> `COMPTE G1 faux-refus=1`. Le contrôle croisé écarte ces phases (DEROGATION.md), comme le plan le dit. Si des phases dérogées sans cadrage existent sur les labs réels, le rejeu réel les comptera en faux refus et l'armement n'aura pas lieu : c'est le signal voulu par P45-D-03b, mais la décision (G1 honore-t-il DEROGATION.md, ou le constructeur classe-t-il ces phases en refus conforme ?) change une règle de gate et reste à la charge du manager ou de Willy. Non modifié ici.
- **T-45-55 (contournement de G1 par CADRAGE.md en dossier, en lien, illisible ou hérité)** : limite acceptée et prouvée comme telle (R-G1-07), nommée (j) par 45-10.
- **Bash** n'est pas couvert par G1 (limite déclarée, P45-D-10) ; un PLAN.md écrit par une commande shell ne passe pas par le hook.
- **Sonde du contrôle croisé** : les phases à DEROGATION.md ou à fichier du modèle non régulier sont écartées (Φ0 et Φ1 court-circuitent Φ2) ; 0 écartée sur les 65 labs des deux bancs (`ecartees` compte les labs non matérialisables).
- **Rejeu réel non fait (A1)** : aucune mesure sur ~/jarvis-keystone ni ~/BusinessFlow-Lab.

## Known Stubs

Aucun.

## Threat Flags

Aucune surface nouvelle hors du `<threat_model>` du plan. T-45-50 (plan sans cadrage) et T-45-51 (divergence G1 / modèle de la 44) sont mitigés et prouvés en CI (R-G1-02, R-G1-05, R-G1-04, R-G1-08, R-REGISTRE, mutants) ; leur effet reste conditionné à l'armement. T-45-52 (faux refus massif) est tenu par l'attendu du modèle, la classification totale, et la règle d'armement (rien n'est armé) ; T-45-56 (comptage d'un gate d'étape ultérieure) est mitigé par R-REJEU-ETAPE. `rejeu-gates.sh` lance désormais `recalc-planning.sh --read-only` sur la COPIE (jamais sur un lab réel) : aucune écriture, aucun git.

## Étapes du workflow sautées (consigne du dispatcher, ADR-063)

Aucune commande `gsd-tools state <verbe>`, aucune écriture de `STATE.md` ni de `ROADMAP.md`, pas de `requirements mark-complete` : à la charge de l'orchestrateur (exigences GATE-06, GATE-12, GATE-13, GATE-15 ; GATE-13 et l'armement de GATE-06 restent ouverts tant que le rejeu réel n'a pas eu lieu, A1). Aucun push, merge, tag.

## Deferred Issues

- Rejeu réel de l'étape 2 et armement éventuel de G1 : nœud `armement-reel`, après l'armement de l'étape 1.
- Décision sur les phases dérogées sans CADRAGE.md (voir Limites et constats).
- `test-vibeflow-update.sh` (18 KO préexistants relevés en 45-01) n'a pas été rejoué.

## Self-Check: PASSED

Vérifié par commandes : les sept fichiers modifiés existent ; les trois commits de tâche (`926e155`, `706c3cf`, `104cc67`) sont ancêtres de HEAD ; `ARMEMENT_G6`, `ARMEMENT_G5`, `ARMEMENT_G1`, `ARMEMENT_G7`, `ARMEMENT_ROLE` valent `"observe"` ; `TABLE_ATTENDUE` inchangée ; aucun fichier hors du périmètre (STATE.md, ROADMAP.md, recalc-planning.sh, modele-cycles.md) modifié ; ce SUMMARY ne porte aucun chemin absolu de machine.
