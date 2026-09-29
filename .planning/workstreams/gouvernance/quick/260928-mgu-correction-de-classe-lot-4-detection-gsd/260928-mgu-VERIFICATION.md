---
phase: quick/260928-mgu-correction-de-classe-lot-4-detection-gsd
verified: 2026-09-28T00:00:00Z
status: passed
score: 7/7 must-haves verified
covered_files:
  - .planning/workstreams/gouvernance/quick/260928-mgu-correction-de-classe-lot-4-detection-gsd/260928-mgu-PLAN.md
  - .planning/workstreams/gouvernance/quick/260928-mgu-correction-de-classe-lot-4-detection-gsd/260928-mgu-SUMMARY.md
  - plugin/planning-core/CHANGELOG.md
  - plugin/planning-core/references/modele-cycles.md
  - plugin/planning-core/scripts/recalc-planning.sh
  - plugin/planning-core/scripts/tests/test-recalc-planning.sh
covered_digest: "v1:sha256:432690bb10dffd92a75ebdc399e73c37fd32e90369cb905790d6a69c2f0bc35b"
behavior_unverified: 0
overrides_applied: 0
---

# Quick Task 260928-mgu — Vérification

**Goal:** Correction de classe (lot 4) : `detection_gsd()` appelle le vrai
`detect-gsd-engine.sh` dans un environnement maîtrisé au lieu de réimplémenter ses priorités en
Python ; encodage injectif du journal `cloture.log`.

**Verified:** 2026-09-28
**Status:** passed
**Method:** Vérification directe sur le codebase du worktree `gouvernance-44` (HEAD =
`7f66a39`), sans confiance dans la prose du SUMMARY.md — chaque commande de vérification du
PLAN.md a été rejouée indépendamment.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `detection_gsd()` ne réimplémente plus aucune priorité du détecteur en Python ; appelle le VRAI `detect-gsd-engine.sh` en sous-processus | ✓ VERIFIED | `grep` post-commit : 0 occurrence de `_porte_marqueur_gsd`, `_porte_marqueur_partition`, `_porte_planning_version`, `_a_signal_de_code`, `_SIGNAUX_DE_CODE`, `_lister_compartiments`, `_JOURNAL_ESPACE_RE` hors commentaires. Lecture directe du code (l. 304-353) : `subprocess.run([bash_bin, detect_sh, "--quiet", "--path", planning_abs], ...)`. `detect-gsd-engine.sh` inchangé (`git diff --quiet c11a2b5 -- .../detect-gsd-engine.sh` → `DETECTEUR-INCHANGE`) |
| 2 | Sous-processus lancé sous environnement MAÎTRISÉ (copie de `os.environ`, seule surcharge `GSD_HOME` = dossier du détecteur) | ✓ VERIFIED | Lecture directe (l. 326-327) : `env_maitrise = dict(os.environ); env_maitrise["GSD_HOME"] = os.path.dirname(detect_sh)`, passé en `env=env_maitrise` au `subprocess.run` — jamais `os.environ` nu. `grep -c -F 'env=env_maitrise'` → 1 |
| 3 | Écriture autorisée SEULEMENT si le détecteur rend 3 ; tout autre code fail-closed en non-concluante, refus nommé | ✓ VERIFIED | Lecture directe : code 0 → `gsd`, code 3 → `non-gsd`, code 2 → `non-concluante` (`motif-code-2-migration`), code 1 → `non-concluante` (`motif-code-1-ferme`), tout autre → `non-concluante` (`motif-repli-generique`). Détecteur non régulier/en lien → `motif-detecteur-irregulier` ; bash introuvable → `motif-bash-introuvable` ; échec de lancement → `motif-sous-processus-en-echec`. `grep -c` positifs sur les motifs code-1-ferme et bash-introuvable → 1 chacun |
| 4 | `_jeton_journal` encode chaque champ en pourcent INJECTIF (isspace(), `=`, `%` → `%XX` par octet UTF-8) | ✓ VERIFIED | Lecture directe (l. 1189-1210) : boucle caractère par caractère, `caractere.isspace()` ou `== "%"` ou `== "="` → `"%{:02X}".format(octet)` par octet de `caractere.encode("utf-8")`. `grep -c -F '"%{:02X}".format(octet)'` → 1. Comportement prouvé par `R-INJECTIF-GENERATIF` (2000 paires, 0 collision) et `R-INJECTIF-ROUNDTRIP` (exécution réelle), tous deux verts dans la suite exécutée |
| 5 | `test-recalc-planning.sh` passe à ≥ 233 OK / 0 KO, 7 mutants orphelins retirés, R-ORACLE-DIFFERENTIEL / R-MATRICE-ENV couvrent la source unique de vérité | ✓ VERIFIED | Suite rejouée par le vérificateur : `== Résultat : 233 OK · 0 KO ==`, rc=0. 0 ligne `✗`/`NON TUÉ`. 5 mutants du lot 4 (`MUT-ENV-NON-MAITRISE`, `MUT-CODE1-NON-GSD`, `MUT-BASH-INTROUVABLE`, `MUT-SOUS-PROCESSUS`, `MUT-JOURNAL-SANITIZE`) tués. 57 lignes vertes des 8 cas R-* du lot 4. 0 invocation résiduelle des 7 mutants retirés. `R-ORACLE-DIFFERENTIEL` et `R-MATRICE-ENV` substantiellement implémentés (lignes 2589+, 2622+), comparant au vrai détecteur lancé directement |
| 6 | Aucune régression hors périmètre : `detect-gsd-engine.sh`, fixtures et 8 suites sœurs inchangés et verts | ✓ VERIFIED | `git diff --stat c11a2b5 -- plugin/planning-core/scripts/tests/` ne liste que `test-recalc-planning.sh`. `FIXTURES-INCHANGEES` imprimé. Les 8 suites sœurs rejouées une à une par le vérificateur rendent exactement les lignes vertes mesurées au plan (19/0, 26/0, 10/0, 38/0, 14/0, 42 PASS/0 FAIL, 22/0/0, 10/0) |
| 7 | `modele-cycles.md` et `CHANGELOG.md` décrivent le comportement réel, contrôle croisé 42/42, aucun bump de version | ✓ VERIFIED | Sonde de contrôle croisé rejouée : `CONTRAT-CROISE-OK 42 / 42`. `Source UNIQUE de vérité` et `Assainissement structurel INJECTIF` présents (1 chacun). Ligne unique `^| 1 | improbable` (1), ancien triplet `^| 1, ` absent (0). `Lot 4 (correction de CLASSE)` sous l'entrée `[v2.8.0]` existante (pas de nouvelle entrée). `AUCUN-BUMP` confirmé sur `VERSION`/`module.json`/`plugin.json`/`marketplace.json` |

**Score:** 7/7 truths verified (0 present-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `plugin/planning-core/scripts/recalc-planning.sh` | `detection_gsd()` par sous-processus, `env=env_maitrise`, `_jeton_journal` injectif | ✓ VERIFIED | `bash -n` OK ; `env=env_maitrise` présent ; réimplémentation Python retirée (0 occurrence) ; commit `b63da53` ne porte que ce fichier |
| `plugin/planning-core/scripts/tests/test-recalc-planning.sh` | 8 nouveaux cas R-*, 3 nouveaux mutants, 2 mutants recâblés, 7 mutants retirés | ✓ VERIFIED | Suite exécutée : 233 OK/0 KO ; tous les motifs recherchés présents avec les comptes attendus ; commit `2fbbd65` ne porte que ce fichier |
| `plugin/planning-core/references/modele-cycles.md` | Table des codes réduite, paragraphe « Source UNIQUE de vérité », section « Assainissement structurel INJECTIF » | ✓ VERIFIED | Les deux titres présents (1 chacun) ; table réduite à une ligne pour le code 1 |
| `plugin/planning-core/CHANGELOG.md` | Paragraphe « Lot 4 (correction de CLASSE) » sous v2.8.0, pas de bump | ✓ VERIFIED | Paragraphe présent, entrée `[v2.8.0]` unique (pas de doublon), `AUCUN-BUMP` confirmé ; commit `3d72452` ne porte que les 2 fichiers doc |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `recalc-planning.sh` (`detection_gsd`) | `detect-gsd-engine.sh` | `subprocess.run([bash_bin, detect_sh, "--quiet", "--path", planning_abs], env=env_maitrise)` | ✓ WIRED | Lecture directe du code, ligne 329-333 — code de sortie seul exploité, aucun sourcing |
| `_formater_ligne_journal` / `lignes_a_journaliser` | `_jeton_journal` | les 4 champs écrits ET la comparaison de dédoublonnage passent par la même fonction | ✓ WIRED | Ligne 1178-1179 (comparaison) et 1215-1218 (`_formater_ligne_journal`) appellent toutes `_jeton_journal` |
| `test-recalc-planning.sh` (R-ORACLE-DIFFERENTIEL) | `detect-gsd-engine.sh` | oracle différentiel, 5 scénarios | ✓ WIRED | Implémentation substantielle lignes 2589+, verte à l'exécution |
| `modele-cycles.md` | `recalc-planning.sh` | contrôle croisé 42 jetons | ✓ WIRED | Sonde rejouée : `CONTRAT-CROISE-OK 42 / 42` |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Suite complète `test-recalc-planning.sh` (single full run, comme prescrit) | `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` | `== Résultat : 233 OK · 0 KO ==`, rc=0 | ✓ PASS |
| 8 suites sœurs (une exécution chacune) | `bash .../test-*.sh` ×8 | lignes vertes identiques à celles mesurées au plan | ✓ PASS |
| Contrôle croisé référence↔moteur | sonde Python du plan | `CONTRAT-CROISE-OK 42 / 42` | ✓ PASS |
| `check-gate-touche.sh` | `bash scripts/check-gate-touche.sh` | `RIEN-A-JUGER: aucun chemin de la surface surveillee n'est touche entre 424cb23... et HEAD` | ✓ PASS |

### Anti-Patterns Found

Aucun marqueur de dette (`TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER`) réel dans les 4 fichiers
modifiés. Les seules occurrences de la chaîne `XXX` sont le motif de formatage `\uXXXX`/`\UXXXXXXXX`
(échappement Unicode, non lié à une dette) et une référence `DEC-XXX` dans une entrée CHANGELOG
bien antérieure (ligne 357, hors périmètre du lot 4) — aucune n'est un marqueur de dette réel.

### Structure des commits

Trois commits atomiques dans l'ordre prescrit, chacun ne portant que ses fichiers déclarés :
- `b63da53` — `fix(44)` : `plugin/planning-core/scripts/recalc-planning.sh` seul (56 insertions, 102 suppressions)
- `2fbbd65` — `test(44)` : `plugin/planning-core/scripts/tests/test-recalc-planning.sh` seul (423 insertions, 114 suppressions)
- `3d72452` — `docs(44)` : `CHANGELOG.md` + `modele-cycles.md` seuls

Plus `7f66a39` (hors plan, trace du quick task et mise à jour manuelle de `STATE.md` — pas de commande `state.*`, conforme aux notes de poste). Le fichier non suivi
`.planning/missions/2026-09-27-gouvernance-44.dag.json` reste hors périmètre, non indexé dans
aucun des quatre commits — confirmé par `git status --short` et par le `git diff --stat` cumulé
(seulement les 7 fichiers attendus). Chaque message de commit porte la citation d'arbitrage
(« Décision du head sous délégation technique de Willy, session principale, 2026-09-28 ») et les
deux lignes d'attribution.

### Requirements Coverage

| Requirement | Description | Status | Evidence |
|-------------|-------------|--------|----------|
| MOTR-02, MOTR-04, MOTR-11, MOTR-12, MOTR-16, MOTR-18 | Déjà marqués `Complete` (Phase 44, `44-VERIFICATION.md` 18/18) | ✓ SATISFIED (pré-existant, consolidé) | Ce lot 4 est une correction de classe sur du code déjà couvert par ces exigences ; il ne les rouvre pas, il en corrige la fiabilité d'implémentation (détection GSD fail-closed, journal append-only injectif) |

### Human Verification Required

Aucune. Tous les contrôles sont automatisables et ont été rejoués directement par ce
vérificateur, indépendamment du SUMMARY.md.

## Gaps Summary

Aucun écart. Les sept truths dérivées du frontmatter `must_haves` du plan sont toutes vérifiées
directement dans le code (lecture des lignes concernées de `recalc-planning.sh`), par exécution
réelle de la suite de tests (233 OK / 0 KO, 0 échec, mutants du lot 4 tués, mutants orphelins
retirés), par exécution des 8 suites sœurs (vertes, non modifiées), par la sonde de contrôle
croisé (42/42), et par les contrôles de non-régression de version (`AUCUN-BUMP`) et de gate
(`RIEN-A-JUGER`). Les trois commits sont atomiques et correctement scoppés ; le fichier hors
périmètre n'a pas été touché.

---

_Verified: 2026-09-28_
_Verifier: Claude (gsd-verifier)_
