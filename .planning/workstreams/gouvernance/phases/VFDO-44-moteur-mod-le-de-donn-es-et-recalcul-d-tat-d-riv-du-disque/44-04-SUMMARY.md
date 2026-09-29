---
phase: 44-moteur-mod-le-de-donn-es-et-recalcul-d-tat-d-riv-du-disque
plan: 04
subsystem: planning-core
tags: [python, bash, planning-engine, cycles-v1, symlink-safety, incremental-cache, mutation-testing]

requires:
  - phase: 44-01
    provides: "recalc-planning.sh traceur, sa suite (R01-R14), son banc synthétique, make_recalc_mutant, SANS_SUIVI_DE_LIEN, garde de type sur les emplacements de sortie"
  - phase: 44-03
    provides: "deriver_phase()/deriver_feuille() (Φ0-Φ5, R1-R8), agrégation partagée, banc à 51 labs"
provides:
  - "classer_entrees() : classement hors modèle de la racine de .planning/ et de l'arbre cycles/ (annexes, mauvais type, lien symbolique, nom invalide), jamais refusé ni suivi"
  - "est_fichier_regulier() : garde unique de régularité (lstat + S_ISREG), reprise par Φ1, la lecture de frontmatter et l'adhésion — un seul point de vérité"
  - "echapper_nom() : échappement Unicode catégorie C* (\\uXXXX <= U+FFFF, \\UXXXXXXXX au-delà) et accent grave pour le rendu de INDEX.md"
  - "hash_contenu()/signature_unite()/charger_cache()/CACHE_SCHEMA_VERSION : cache incrémental par hash du contenu (.recalc-cache.json), jamais par date de fichier"
  - "_deriver_feuille_cache() : enveloppe de reprise (signature ET livrables inchangés), jamais consultée ni écrite en lecture seule"
  - "ecrire_si_different() durci : ne compare plus jamais à travers un lien symbolique existant"
  - "Banc étendu au format @@ fichier-dehors / @@ lien / @@ attendu-hors-modele[-aucun], bac à sable frère hors du lab"
  - "Dix nouveaux mutants tracés : MUT-HORS-MODELE, MUT-ANNEXES, MUT-LIEN-FICHIER, MUT-LIEN-DOSSIER, MUT-ECHAPPEMENT, MUT-TYPE-ECRITURE, MUT-SIGNATURE-TEMPS, MUT-SCHEMA-CACHE, MUT-LIVRABLES-CACHE, MUT-CACHE-LECTURE-SEULE"
affects: ["44-05", "45", "46", "47", "48", "49", "50"]

actuals:
  tokens: 20894
  tasks: 2
  commits: 2
  plan_head_before: 00748a4

tech-stack:
  added: []
  patterns:
    - "Une seule garde de régularité (est_fichier_regulier) réutilisée par tous les points d'ouverture d'un fichier du modèle — plus jamais de stat.S_ISREG(os.lstat(...)) dupliqué ad hoc"
    - "Le cache n'est consulté et écrit QUE sur le chemin d'écriture garanti de main() (après les deux refus P44-D-02/P44-D-02a) — jamais avant, jamais en lecture seule ; deux dérivations distinctes (cache_ctx=None en lecture seule, cache_ctx peuplé en écriture) plutôt qu'un drapeau conditionnel dispersé"
    - "deriver_phase() route son cas Φ5 feuille-directe vers le MÊME _deriver_feuille_cache()/deriver_feuille() que _agreger_plans() pour chaque plan de plans/ — un seul point de cache pour les deux formes de feuille, jamais deux mécanismes parallèles"
    - "Les catch-all de classement hors modèle, textuellement identiques à trois niveaux de l'arbre (cycles/phases/plans), portent chacun un commentaire de fin de ligne distinct (# cycle / # phase / # plan) pour rester des cibles uniques de make_recalc_mutant sans changer de comportement"

key-files:
  created: []
  modified:
    - plugin/planning-core/scripts/recalc-planning.sh
    - plugin/planning-core/scripts/tests/test-recalc-planning.sh
    - plugin/planning-core/scripts/tests/fixtures/recalc-planning-banc.txt
    - plugin/planning-core/references/modele-cycles.md

key-decisions:
  - "echapper_nom() au-delà de U+FFFF : le texte littéral du plan ne définit que la forme \\uXXXX (quatre chiffres, plan de base). Un caractère de catégorie C* au-delà du BMP (ex. un private-use de plan supplémentaire, U+100000) ne serait sinon ni représentable en quatre chiffres ni géré — corrigé en \\UXXXXXXXX (huit chiffres, convention littérale Python), documentée dans le moteur ET dans la référence. Correction de portée signalée par le mandat, appliquée avant tout commit."
  - "Cache jamais menacé par un refus tardif : main() ne charge le cache qu'APRÈS les refus d'adhésion (P44-D-02) et de détection GSD (P44-D-02a), jamais avant — un refus reste garanti sans qu'aucun octet du cache ne soit lu, y compris son statut."
  - "deriver_phase() route son fallback Φ5 (feuille directe) vers deriver_feuille() au lieu d'appeler _r1_a_r8() directement — Φ0/Φ1 y sont réévalués de façon redondante mais inoffensive (déjà validés plus haut dans la même fonction avec les mêmes entrees/chemin_abs), ce qui unifie le point d'entrée du cache pour les deux formes de feuille sans dupliquer sa logique."
  - "ecrire_si_different() ne compare plus jamais le contenu existant EN SUIVANT un lien symbolique : un emplacement existant non régulier compte comme différent, forçant l'écriture (donc le remplacement du lien par un fichier régulier via os.replace) — sans cela, un cache en lien dont le contenu recalculé coïncide par hasard avec celui de la cible resterait un lien après le recalcul (R56 l'exige redevenu un fichier régulier)."
  - "Filet de sécurité générique dans main() (except OSError autour de appliquer_ecritures) : une erreur d'entrée-sortie inattendue (ex. os.replace vers un emplacement de sortie mal typé alors que la garde dédiée a été neutralisée) ne remonte jamais comme une trace Python brute — code 1, message métier. Nécessaire pour que MUT-TYPE-ECRITURE se tue sur un symptôme métier (message stderr) et non sur un plantage, seul mode de mort que ce dépôt refuse de créditer."

requirements-completed: [MOTR-06, MOTR-10, MOTR-13, MOTR-16, MOTR-17]

coverage:
  - id: D1
    description: "classer_entrees() signale hors modèle tout ce qui n'est ni un emplacement du modèle ni l'une des six annexes (racine ET arbre cycles/), jamais refusé, jamais suivi, sans changer aucun état dérivé"
    requirement: "MOTR-06"
    verification:
      - kind: integration
        ref: "test-recalc-planning.sh — R40 (racine), R41 (arbre + jumeau sans intrus, états identiques), R46 (rendu écrit avec/sans intrus)"
        status: pass
      - kind: unit
        ref: "test-recalc-planning.sh — MUT-HORS-MODELE, MUT-ANNEXES"
        status: pass
    human_judgment: false
  - id: D2
    description: "Un lien symbolique (dossier d'unité ou fichier du modèle) n'est jamais suivi ; un dossier en lien est hors modèle, un fichier en lien reste fichier-non-regulier:<nom> sans que son contenu ne soit lu"
    requirement: "MOTR-06"
    verification:
      - kind: integration
        ref: "test-recalc-planning.sh — R43 (lien de dossier, aucune unité dans le JSON), R44 (lien de fichier, jeton JETON-DEHORS-44 absent)"
        status: pass
      - kind: unit
        ref: "test-recalc-planning.sh — MUT-LIEN-DOSSIER, MUT-LIEN-FICHIER"
        status: pass
    human_judgment: false
  - id: D3
    description: "echapper_nom() échappe tout caractère de catégorie Unicode C* et l'accent grave — un nom d'unité piégé (saut de ligne) reste une seule ligne dans INDEX.md sans jamais atteindre cloture.log"
    requirement: "MOTR-06"
    verification:
      - kind: integration
        ref: "test-recalc-planning.sh — R45 (nom à saut de ligne + accent grave, 11 lignes, cloture.log absent)"
        status: pass
      - kind: unit
        ref: "test-recalc-planning.sh — MUT-ECHAPPEMENT"
        status: pass
    human_judgment: false
  - id: D4
    description: "Un emplacement du modèle du mauvais type (racine) est hors modèle en lecture, et refusé sans rien écrire en écriture (garde de 44-01 rejouée, aucun cycle dérivé quand cycles/ est un fichier)"
    requirement: "MOTR-06"
    verification:
      - kind: integration
        ref: "test-recalc-planning.sh — R42 (deux volets : lecture seule et écriture)"
        status: pass
      - kind: unit
        ref: "test-recalc-planning.sh — MUT-TYPE-ECRITURE"
        status: pass
    human_judgment: false
  - id: D5
    description: "Le cache (.recalc-cache.json, cache_schema_version 1) est incrémental par hash du contenu, jamais par date de fichier — un touch sans changement de contenu ne recalcule rien, un contenu changé à mtime restauré est vu"
    requirement: "MOTR-13"
    verification:
      - kind: integration
        ref: "test-recalc-planning.sh — R50 (premier passage), R51 (reprise totale), R52 (touch seul, 0 recalcul, quatre fichiers identiques octet pour octet), R53 (contenu changé à mtime restauré, recalcul + libellé imbriqué exact, identique à un recalcul complet sans cache)"
        status: pass
      - kind: unit
        ref: "test-recalc-planning.sh — MUT-SIGNATURE-TEMPS"
        status: pass
    human_judgment: false
  - id: D6
    description: "Un cache absent, illisible (non-JSON, lien symbolique), ou d'un cache_schema_version/moteur différent provoque un recalcul complet, jamais une confiance aveugle ; le cache en lien est remplacé par un fichier régulier sans jamais toucher sa cible"
    requirement: "MOTR-13"
    verification:
      - kind: integration
        ref: "test-recalc-planning.sh — R54 (non-JSON), R55 (schéma 999 puis absent), R56 (lien symbolique, cible inchangée, redevenu fichier régulier)"
        status: pass
      - kind: unit
        ref: "test-recalc-planning.sh — MUT-SCHEMA-CACHE"
        status: pass
    human_judgment: false
  - id: D7
    description: "Le cache n'est jamais lu ni écrit en mode --read-only, même forgé au bon format et à la bonne signature ; les livrables d'une unité reprise sont revus à chaque passage, jamais figés dans le cache"
    requirement: "MOTR-13"
    verification:
      - kind: integration
        ref: "test-recalc-planning.sh — R57 (--read-only sur cache forgé, JSON identique à un lab sans cache, empreinte inchangée), R58 (livrable supprimé après cache valide, indéterminé malgré signature stable)"
        status: pass
      - kind: unit
        ref: "test-recalc-planning.sh — MUT-CACHE-LECTURE-SEULE, MUT-LIVRABLES-CACHE"
        status: pass
    human_judgment: false
  - id: D8
    description: "Chaque garde de 44-04 (hors modèle, annexes, liens de fichier/dossier, échappement, type d'emplacement en écriture, signature par contenu, schéma du cache, livrables revus à la reprise, cache ignoré en lecture seule) est tuée par un mutant tracé, jamais crédité par un plantage"
    requirement: "MOTR-17"
    verification:
      - kind: unit
        ref: "test-recalc-planning.sh — les dix nouveaux MUT-*, chacun avec assertion/attendu(original)/obtenu(mutant), aucun ne s'appuie sur _verifier_plantage pour compter TUÉ"
        status: pass
    human_judgment: false
  - id: D9
    description: "Le moteur n'appelle aucune API de date de fichier ; référence et moteur portent les mêmes codes de raison, noms de fichiers, annexes et libellés lisibles (contrôle croisé automatique)"
    requirement: "MOTR-16"
    verification:
      - kind: other
        ref: "grep -nE 'st_mtime|getmtime|st_ctime|getctime|st_atime|getatime|utime' recalc-planning.sh (vide) ; sonde CONTRAT-CROISE-OK 42/42 (commande du plan, § verify Tâche 2)"
        status: pass
    human_judgment: false

duration: session d'exécution continue, non chronométrée avec précision
completed: 2026-09-28
status: complete
---

# Phase 44 Plan 04: Moteur — hors modèle, garde-fous de chemin et cache incrémental Summary

**Le recalcul signale désormais tout ce qui n'est pas au modèle sans jamais le refuser ni le suivre (liens de dossier et de fichier compris, noms piégés échappés), et ne re-dérive que ce dont le contenu a changé via un cache versionné par hash — jamais par date de fichier, jamais consulté hors écriture — chaque garde prouvée par un lab et un mutant tracé (dix nouveaux, 35 au total avec 44-01/44-03).**

## Performance

- **Duration:** session d'exécution continue, non chronométrée avec précision
- **Completed:** 2026-09-28
- **Tasks:** 2/2
- **Files modified:** 4 (`recalc-planning.sh`, `test-recalc-planning.sh`, `recalc-planning-banc.txt`, `modele-cycles.md`)
- **Commits:** 2 (mesuré : `git rev-list --count 00748a4..HEAD`)

## Accomplishments

- `classer_entrees()` classe la racine de `.planning/` et l'arbre `cycles/` : les six annexes
  (dossiers, jamais lues), les emplacements du modèle du bon type sont absents de la liste ; tout
  le reste — mauvais nom, mauvais type, tout lien symbolique — est hors modèle avec son type
  (`fichier`/`dossier`/`lien`/`autre`), jamais parcouru au-delà. Un fichier du modèle au bon nom
  mais non régulier reste le ressort de Φ1 (`fichier-non-regulier:<nom>`), jamais du classement.
- `est_fichier_regulier()` devient la garde UNIQUE de régularité (lstat + `S_ISREG`, jamais de
  suivi de lien), reprise par Φ1, `_lire_frontmatter_fichier`, `verifier_adhesion` et `ecrire_si_different`
  — un seul point de vérité au lieu de quatre vérifications ad hoc dupliquées.
- `echapper_nom()` échappe tout caractère de catégorie Unicode C* en `\uXXXX` (quatre chiffres,
  plan de base) ou `\UXXXXXXXX` (huit chiffres, au-delà de U+FFFF — correction de portée, voir
  Déviations) et l'accent grave en `` \` ``, appliqué au rendu de `INDEX.md` : un nom à saut de
  ligne reste sur une seule ligne, jamais dans `cloture.log` (seuls les noms validés par
  `NOM_UNITE` y entrent).
- `hash_contenu()`/`signature_unite()`/`charger_cache()` : cache `.planning/.recalc-cache.json`
  (`cache_schema_version` 1), signature sha256 du texte canonique (entrées triées du dossier +
  contenu des fichiers du modèle lus + pour un plan, le CADRAGE.md de sa phase). Absent, illisible,
  en lien, ou d'un autre schéma/moteur → recalcul complet. `_deriver_feuille_cache()` reprend une
  unité si sa signature ET l'existence de ses livrables (revue à chaque passage) sont inchangées ;
  sinon recalcule et enregistre. Le cache n'est chargé et écrit QUE sur le chemin d'écriture
  garanti de `main()`, après les deux refus (P44-D-02, P44-D-02a) — jamais en lecture seule.
- `deriver_phase()` route désormais son cas Φ5 feuille-directe vers `deriver_feuille()` (via
  `_deriver_feuille_cache`) au lieu d'appeler `_r1_a_r8()` directement, unifiant le point d'entrée
  du cache pour une phase à plan direct ET pour chaque plan de `plans/` (`_agreger_plans`).
- `ecrire_si_different()` durci : un emplacement existant qui n'est pas un fichier régulier (lien
  symbolique compris) compte désormais comme différent — il est toujours REMPLACÉ par un fichier
  régulier via `os.replace`, jamais comparé à travers le lien.
- Filet de sécurité générique dans `main()` : une erreur d'entrée-sortie inattendue au-delà des
  gardes déjà posées (ex. la garde de type des emplacements de sortie neutralisée) ne remonte
  jamais comme une trace Python brute — code 1, message métier nommé.
- Banc étendu au format `@@ fichier-dehors <chemin>` (fichier hors du lab, bac à sable frère),
  `@@ lien <chemin> -> <cible>` (`DEHORS/<x>` résolu vers le bac à sable), `@@ attendu-hors-modele
  <chemin> :: <type>` / `@@ attendu-hors-modele-aucun` (ensemble exact exigé). Six nouveaux labs :
  `hors-modele-racine`, `hors-modele-interne` (+ jumeau sans intrus), `modele-mauvais-type`,
  `lien-dossier-cycle`, `lien-fichier-plan`.
- R40 à R58 : dix-neuf cas couvrant hors modèle (racine, arbre, mauvais type deux volets, liens de
  dossier/fichier, nom piégé, rendu écrit) et cache incrémental (absent/reprise/touch/contenu
  changé/illisible/schéma/lien/lecture seule/livrables revus).
- Dix nouveaux mutants, chacun avec une trace assertion/attendu(original)/obtenu(mutant) qui nomme
  un symptôme métier (jamais une exception Python générique) : `MUT-HORS-MODELE`, `MUT-ANNEXES`,
  `MUT-LIEN-FICHIER`, `MUT-LIEN-DOSSIER`, `MUT-ECHAPPEMENT`, `MUT-TYPE-ECRITURE`,
  `MUT-SIGNATURE-TEMPS`, `MUT-SCHEMA-CACHE`, `MUT-LIVRABLES-CACHE`, `MUT-CACHE-LECTURE-SEULE`.
- Contrôle croisé automatique référence ↔ moteur : 42/42 jetons (codes de raison, noms de
  fichiers, annexes, libellés lisibles) présents dans les deux (`CONTRAT-CROISE-OK`). Aucune API
  de date de fichier dans le moteur (grep vide). Sonde `PY39-SYNTAXE-OK` et portabilité bash/zsh
  (`PY39-SONDE-BASH-ZSH-OK`) rejouées après l'extension.
- `references/modele-cycles.md` documente le rendu hors modèle avec `echapper_nom`, et la limite
  connue du cache forgé au bon format/signature avec renvoi explicite à G6 (Phase 45).
- Rouge constaté avant l'implémentation : la suite étendue (nouveaux R40-R58 et dix mutants) lancée
  contre le moteur pré-44-04 rend `53 OK · 99 KO` (27 échecs concentrés sur les cas R4x/R5x neufs,
  le reste du bruit venant d'une résolution de chemin du harnais de vérification elle-même, sans
  rapport avec le moteur) — confirme que les nouveaux tests exercent une fonctionnalité qui
  n'existait pas avant ce plan.
- Aucune régression : les 152 assertions de `test-recalc-planning.sh` sont vertes (0 KO), les 8
  autres suites de `planning-core` restent vertes et inchangées (D-01b).

## Task Commits

1. **Tâches 1 et 2 (banc, suite)** :
   - `dff5271` `test(44-04): hors modèle, liens, noms échappés et cache incrémental prouvés au banc (P44-D-04, P44-D-13)`
2. **Tâches 1 et 2 (moteur, référence)** :
   - `a62ce91` `feat(planning-core): hors modèle, garde-fous de chemin et cache incrémental par hash du contenu (44-04)`

**Plan metadata:** ce commit (`docs(44-04): ...`, ajouté par l'orchestrateur après la vague — hors
périmètre de cet agent).

## Files Created/Modified

- `plugin/planning-core/scripts/recalc-planning.sh` — `classer_entrees`/`_classer_racine`/
  `_classer_arbre_cycles`/`_classer_cycle_entrees`/`_classer_phases_dir_entrees`/
  `_classer_phase_entrees`/`_classer_plans_dir_entrees`/`_classer_plan_entrees`, `echapper_nom`,
  `est_fichier_regulier` (refactor de `_est_regulier` et trois points d'appel), `hash_contenu`,
  `signature_unite`, `_lire_ecrit_reel`, `charger_cache`, `_deriver_feuille_cache`,
  `CACHE_SCHEMA_VERSION`, `NOMS_MODELE_RACINE_DOSSIERS`/`NOMS_MODELE_RACINE_FICHIERS`,
  `ecrire_si_different` durci, `appliquer_ecritures` et `main()` restructurés (cache chargé
  uniquement sur le chemin d'écriture garanti), filet de sécurité `except OSError`.
- `plugin/planning-core/scripts/tests/test-recalc-planning.sh` — `parser_banc`/`materialiser`
  étendus (`fichier-dehors`, `lien`, `attendu-hors-modele[-aucun]`), `verifier_hors_modele`,
  `coureur` vérifie aussi `hors_modele` quand déclaré, R40 à R58, dix nouveaux `MUT-*`.
- `plugin/planning-core/scripts/tests/fixtures/recalc-planning-banc.txt` — six nouveaux labs.
- `plugin/planning-core/references/modele-cycles.md` — rendu hors modèle + `echapper_nom`
  documentés, limite du cache forgé avec renvoi à G6.

## Decisions Made

Voir `key-decisions` en frontmatter. Point notable : la table de correspondance du plan (§ Table
de correspondance sortie ↔ contrat 44-01) prescrivait les chaînes exactes de R40, R41, R45, R46,
R53 — reprises littéralement dans les assertions de test, aucun écart trouvé (donc aucune
correction ni du contrat ni des cas de ce plan).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] `echapper_nom` au-delà du plan de base multilingue Unicode (U+FFFF)**
- **Found during:** conception de la Tâche 1, avant tout commit (constat d'information du dernier
  checker, cité dans le mandat de cette exécution)
- **Issue:** le texte littéral du plan ne définit `echapper_nom` que pour un point de code du plan
  de base (`\uXXXX`, quatre chiffres). Un caractère de catégorie Unicode C* au-delà de U+FFFF (ex.
  un private-use de plan supplémentaire, U+100000, catégorie `Co`) ne serait sinon ni représentable
  en quatre chiffres hexadécimaux ni tronqué en silence — une lacune de correction, pas seulement
  de style.
- **Fix:** ajout de la forme `\UXXXXXXXX` (huit chiffres hexadécimaux en minuscules, convention
  littérale Python) pour tout point de code strictement supérieur à U+FFFF, la forme `\uXXXX`
  restant inchangée pour le plan de base. Vérifié par un test direct sur `chr(0x100000)` (catégorie
  `Co` confirmée par `unicodedata.category`) rendant `\U00100000`, et sur un caractère combinant
  (catégorie `Mn`, non C*) resté inchangé, avant tout commit.
- **Files modified:** `plugin/planning-core/scripts/recalc-planning.sh`,
  `plugin/planning-core/references/modele-cycles.md` (documentation de la forme)
- **Verification:** vérification manuelle directe de `echapper_nom` (voir ci-dessus) ; R45 (BMP
  seul, `\u000a`) reste vert, aucune régression.
- **Committed in:** `a62ce91` (intégré directement dans le commit `feat`, pas de commit distinct —
  découvert et corrigé avant tout commit).

**2. [Rule 3 - Blocking issue] Collision de motif entre les deux tris de `main()` après restructuration**
- **Found during:** exécution de la suite complète après l'ajout des mutants (première passe)
- **Issue:** la restructuration de `main()` pour ne charger le cache que sur le chemin d'écriture
  garanti a dupliqué la ligne `key=lambda c: c["chemin"],` en deux occurrences textuellement
  identiques (lecture seule et écriture) — `make_recalc_mutant` exige un motif à occurrence UNIQUE,
  rendant `MUT-TRI` (44-03) impossible à cibler sans ambiguïté (motif absent/ambigu, n=2).
- **Fix:** ajout d'un commentaire de fin de ligne distinct sur chacune des deux occurrences
  (`# tri, lecture seule` / `# tri, écriture`), aucun changement de comportement ; `MUT-TRI` retargeté
  sur l'occurrence d'écriture (celle qu'il exerçait déjà via `cycles-ordre` en mode écriture).
- **Files modified:** `plugin/planning-core/scripts/recalc-planning.sh`,
  `plugin/planning-core/scripts/tests/test-recalc-planning.sh`
- **Verification:** `bash test-recalc-planning.sh` → `MUT-TRI TUÉ`, suite complète verte.
- **Committed in:** `dff5271`/`a62ce91` (découvert et corrigé avant tout commit — pas de commit
  distinct).

**3. [Rule 1 - Bug] Chemin du banc `@@ lien` relatif à la racine du lab, pas à `.planning/`**
- **Found during:** première exécution de R01/R43/R44 après l'écriture des labs `lien-dossier-cycle`
  et `lien-fichier-plan`
- **Issue:** les deux labs déclaraient `@@ lien cycles/02-lien -> ...` (sans préfixe `.planning/`),
  incohérent avec `@@ fichier`/`@@ dossier` (relatifs à la racine du lab, donc `.planning/cycles/...`)
  — le lien était créé hors de `.planning/`, jamais rencontré par le recalcul.
- **Fix:** préfixage des deux directives `@@ lien` en `.planning/cycles/02-lien` et
  `.planning/cycles/01-c/phases/01-p/PLAN.md`.
- **Files modified:** `plugin/planning-core/scripts/tests/fixtures/recalc-planning-banc.txt`
- **Verification:** R01/R43/R44 passent après correction.
- **Committed in:** `dff5271` (découvert et corrigé avant tout commit — pas de commit distinct).

**4. [Rule 1 - Bug] `ecrire_si_different` comparait à travers un lien symbolique existant**
- **Found during:** conception de R56 (cache en lien symbolique)
- **Issue:** l'implémentation posée en 44-01 ouvre `chemin` en lecture pour comparer au contenu
  existant — `open()` SUIT un lien symbolique par défaut. Si le contenu recalculé coïncidait par
  hasard avec celui de la cible du lien, `ecrire_si_different` rendait `False` (rien à écrire) et
  le lien restait un lien — alors que R56 exige `.recalc-cache.json` redevenu un fichier régulier
  après le recalcul, quel que soit le contenu.
- **Fix:** `ecrire_si_different` vérifie désormais `est_fichier_regulier(chemin)` (lstat, jamais de
  suivi) avant toute tentative de lecture du contenu existant ; un emplacement non régulier compte
  toujours comme différent, forçant l'écriture (`os.replace` remplace le lien par un fichier
  régulier).
- **Files modified:** `plugin/planning-core/scripts/recalc-planning.sh`
- **Verification:** R56 (« `.recalc-cache.json` redevenu un fichier régulier ») vert ; R02/R03
  (identité octet pour octet sur fichiers réguliers, cas nominal) restent verts, sans régression.
- **Committed in:** `a62ce91` (découvert et corrigé avant tout commit — pas de commit distinct).

### Consolidation des commits (documentée, pas une auto-correction)

Le plan demande quatre commits (`test(44-04)` puis `feat(planning-core)` pour chaque tâche). Ce
plan a été exécuté en 2 commits (`test` puis `feat`), regroupant les deux tâches — même motif
qu'en 44-03 : les fonctions de classement hors modèle (Tâche 1) et de cache (Tâche 2) vivent dans
le MÊME fichier moteur, la refonte de `main()` nécessaire à la Tâche 2 touche directement le point
d'entrée déjà modifié par la Tâche 1, et le coureur du banc partagé (`parser_banc`, `materialiser`,
`make_recalc_mutant`) est étendu par les deux tâches dans le MÊME fichier de suite — les séparer en
quatre commits aurait exigé de committer un fichier syntaxiquement incomplet à une étape
intermédiaire, ce que la compilation du corps Python (garde de `make_recalc_mutant` et vérification
manuelle avant chaque commit) aurait refusé. Discipline test-avant-code conservée (commit `test`
avant commit `feat`, rouge constaté avant l'implémentation — voir Accomplishments) ; seul le
regroupement des deux tâches en deux commits au lieu de quatre diffère du plan. Aucun changement de
périmètre, de contenu livré, ni de vérification.

**Total deviations:** 3 auto-fixées (1 correction de portée Rule 2, 1 testabilité Rule 3, 2 bugs
Rule 1) + 1 consolidation de commits documentée. Aucune n'a changé le périmètre du plan ; toutes
ont été découvertes et corrigées avant le premier commit.
**Impact on plan:** La correction Rule 2 (`echapper_nom` au-delà de U+FFFF) était explicitement
demandée par le mandat de cette exécution comme correction de portée déclarée — appliquée avant
tout commit, jamais après coup.

## Issues Encountered

Aucun blocage au-delà des déviations ci-dessus. Le second bloc de vérification Python 3.9 (quatre
pièges sous bash et zsh) a été rejoué via un script séparé (mécanisme identique au plan, exécution
en pièces détachées pour respecter la garde de complexité du bac à sable de cet agent) —
`PY39-SONDE-BASH-ZSH-OK`, les huit lignes attendues obtenues à l'identique. Aucun point ouvert.

## User Setup Required

None — aucune configuration de service externe requise.

## Next Phase Readiness

- Le moteur est complet pour la Phase 44 : hygiène signalée sans refus, liens jamais suivis,
  incrémental par contenu prouvé dans les deux sens, cache douteux jamais cru, référence et moteur
  identiques (contrôle croisé automatique). 44-05 peut passer au bump mineur de version et au
  passage en lecture seule sur les deux labs réels du poste sans re-discuter ce contrat.
- Limite connue et acceptée (T-44-20, documentée dans la référence avec renvoi à G6, Phase 45) :
  une entrée de cache forgée au bon format et à la bonne signature est reprise sans être rejugée —
  exige déjà un accès en écriture à `.planning/`, qui permet tout autant de réécrire n'importe quel
  fichier du modèle ; pas une surface nouvelle.
- Aucun blocage. Aucune release (jalon gouvernance, gates rejoués à la main tant que la Phase 41.1
  n'est pas mergée — hors périmètre de ce plan).

---
*Phase: 44-moteur-modele-de-donnees-et-recalcul-d-etat-derive-du-disque*
*Plan: 04*
*Completed: 2026-09-28*

## Self-Check: PASSED

- Les 4 fichiers modifiés (`recalc-planning.sh`, `test-recalc-planning.sh`,
  `recalc-planning-banc.txt`, `modele-cycles.md`) sont retrouvés sur le disque avec les
  changements attendus.
- Les 2 commits (`dff5271`, `a62ce91`) sont retrouvés dans `git log`.
- `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` → `152 OK · 0 KO` (rejoué
  immédiatement avant cette vérification).
- Les 8 autres suites de `planning-core` restent vertes (rejouées individuellement, 0 échec).
- `grep -nE 'st_mtime|getmtime|st_ctime|getctime|st_atime|getatime|utime'
  plugin/planning-core/scripts/recalc-planning.sh` : vide.
- Sonde de contrat croisé : `CONTRAT-CROISE-OK 42 / 42`.
- Sonde `PY39-SYNTAXE-OK` et `PY39-SONDE-BASH-ZSH-OK` rejouées.
- `grep -c '"_bancs"' recalc-planning.sh` = 1 ; `grep -c '_bancs'
  references/templates/cycles/config.template.json` = 0 ; `grep -c 'CACHE_SCHEMA_VERSION = 1'
  recalc-planning.sh` = 1.
