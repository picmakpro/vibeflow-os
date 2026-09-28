---
phase: quick/260928-ol3-correction-de-classe-lot-5-environnement-maitrise
verified: 2026-09-28T00:00:00Z
status: passed
score: 11/11 must-haves verified
covered_files:
  - .planning/workstreams/gouvernance/quick/260928-ol3-correction-de-classe-lot-5-environnement-maitrise/260928-ol3-PLAN.md
  - .planning/workstreams/gouvernance/quick/260928-ol3-correction-de-classe-lot-5-environnement-maitrise/260928-ol3-SUMMARY.md
  - plugin/planning-core/CHANGELOG.md
  - plugin/planning-core/references/modele-cycles.md
  - plugin/planning-core/scripts/recalc-planning.sh
  - plugin/planning-core/scripts/tests/test-recalc-planning.sh
covered_digest: "v1:sha256:d78bda25d83980224f1c56ed13d3e6abfad4d51354a74b46bb49c49130dcb9ff"
behavior_unverified: 0
overrides_applied: 0
---

# Quick Task 260928-ol3 — Vérification

**Goal:** Correction de classe (lot 5) : l'environnement « maîtrisé » du sous-processus détecteur
GSD (`detection_gsd`) est construit DE ZÉRO (liste blanche `PATH_MAITRISE` + `GSD_HOME`), jamais
`dict(os.environ)` — un `PATH` hérité empoisonné ne peut plus changer le verdict d'écriture — plus
cinq correctifs voisins de la même correction ciblée (F2, F44-05/F7, F5, F6, F44-06).

**Verified:** 2026-09-28
**Status:** passed
**Method:** Vérification directe sur le codebase du worktree `gouvernance-44` (HEAD = `9fe4a42`),
sans confiance dans la prose du SUMMARY.md — chaque commande de vérification du PLAN.md a été
rejouée indépendamment, plus une reproduction adversariale indépendante (PATH empoisonné réel,
awk factice, marqueur `gsd_state_version` réel) hors du texte du plan.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | L'environnement du sous-processus détecteur est construit DE ZÉRO (liste blanche PATH_MAITRISE + GSD_HOME), jamais `dict(os.environ)` | ✓ VERIFIED | Lecture directe (l. 403-404) : `env_maitrise = {"PATH": PATH_MAITRISE}` puis `env_maitrise["GSD_HOME"] = os.path.dirname(detect_sh)`. `grep -n "dict(os.environ)"` : 2 occurrences, toutes deux dans des commentaires (l. 90, l. 360 — narration de l'ancien bug du lot 4), 0 en code actif |
| 2 | `bash` résolu par liste fixe de deux chemins absolus (`CANDIDATS_BASH`), chacun validé par `lstat` ; jamais `shutil.which` ; aucun candidat valide → refus fail-closed nommé | ✓ VERIFIED | Lecture directe : `CANDIDATS_BASH = ("/bin/bash", "/usr/bin/bash")` (l. 88) ; `_bash_candidat_valide` (l. 305-329, lstat + branche lien symbolique root) ; `_resoudre_bash` (l. 332-342) itère `CANDIDATS_BASH`, rend `None` si épuisé ; `detection_gsd` (l. 390-397) refuse nommément (`motif-bash-introuvable`) si `bash_bin is None`. `grep -c shutil.which` sur le fichier réel (hors tests) → 0 |
| 3 | Preuve par exécution sur entrée adverse : PATH empoisonné par un `awk` factice écrivait avant ce lot, refuse après | ✓ VERIFIED | Reproduction indépendante (hors suite, hors PLAN.md) : lab avec `.planning/STATE.md` portant `gsd_state_version` + `config.json` adhérent, `subprocess.run` avec `PATH=<poison-bin>:/usr/bin:/bin:/usr/sbin:/sbin` (faux `awk` en tête, `exit 1`) → `rc=3`, stderr `refus d'écriture (P44-D-02a)`, `STATE.md` identique octet pour octet avant/après. Contrôle supplémentaire : le faux `awk` instrumenté (journal d'appel) n'est **jamais invoqué** — confirme que `env_maitrise` (liste blanche) ne laisse aucune chance au `PATH` empoisonné d'atteindre le sous-processus détecteur |
| 4 | `_jeton_journal` échappe `not caractere.isprintable()` en plus de `isspace()`/`=`/`%` | ✓ VERIFIED | Lecture directe (l. 1309) : `if caractere == "%" or caractere == "=" or caractere.isspace() or not caractere.isprintable():` |
| 5 | `_jeton_journal` ne rend jamais un jeton vide : repli falsy → `ValueError` | ✓ VERIFIED | Lecture directe (l. 1305) : `if not repli: raise ValueError("_jeton_journal : 'repli' doit toujours être non vide (contrat interne)")` ; assertion de garde supplémentaire l. 1315 (`assert jeton, ...`) |
| 6 | Détecteur absent et détecteur non régulier portent deux messages stderr distincts | ✓ VERIFIED | Lecture directe (l. 382-389) : `except OSError` → `"détecteur absent : " + detect_sh"` (motif-detecteur-absent) ; `not stat.S_ISREG(...)` → `"détecteur non régulier : " + detect_sh"` (motif-detecteur-irregulier) — deux branches, deux messages |
| 7 | `ecrire_si_different` lit l'existant par `os.open(..., O_RDONLY \| O_NOFOLLOW)`, jamais `open()` nu | ✓ VERIFIED | Lecture directe (l. 1437) : `descripteur_existant = os.open(chemin, os.O_RDONLY \| SANS_SUIVI_DE_LIEN)` (`SANS_SUIVI_DE_LIEN = getattr(os, "O_NOFOLLOW", 0)`, l. 83). Aucun `open(chemin` nu dans la fonction (l. 1424-1461 relue intégralement) |
| 8 | Point du mandat explicitement NON retenu (gate stderr sur code 3), documenté avec preuve | ✓ VERIFIED | Docstring de `detection_gsd` (l. 374-378) et commentaire au site du `return "non-gsd"` (l. 417-425) expliquent la mesure (`hors-modele-racine`, `.planning/workstreams/` vide, `vf_ws_enumerate` écrit sur stderr sous `--quiet` sans casser le code 3) ; même explication reprise dans `modele-cycles.md` (l. 117-123) |
| 9 | `test-recalc-planning.sh` passe à ≥ 270 OK / 0 KO, sans ligne en échec ni mutant survivant ; `MUT-ENV-OS-ENVIRON`/`MUT-BASH-VIA-PATH` tués | ✓ VERIFIED | Suite rejouée par le vérificateur : `== Résultat : 270 OK · 0 KO ==`, 0 ligne `✗`/`NON TUÉ`. `grep` confirme `MUT-ENV-OS-ENVIRON` (l. 2767) et `MUT-BASH-VIA-PATH` (l. 2789) présents et câblés sur le scénario `R-MATRICE-ENV` (5 colonnes adverses : `awk-piege`, `bash-piege`, `bash-env-awk`, `bash-func-awk`, `env-var`, l. 2693) |
| 10 | Aucune régression hors périmètre : `detect-gsd-engine.sh`/`workstream-policy.sh` octet pour octet inchangés depuis `424cb23` ; 8 suites sœurs inchangées et vertes | ✓ VERIFIED | `git diff --stat 424cb23..HEAD -- .../detect-gsd-engine.sh .../workstream-policy.sh` → vide. Les 8 suites sœurs rejouées une à une par le vérificateur rendent exactement les comptes attendus : 19 ok/0 ko, 26 ok/0 ko, 10 passés/0 échoués, 38 passés/0 échoués, 14 passés/0 échoués, 42 PASS/0 FAIL, 22 ok/0 ko/0 skip, 10 ok/0 ko |
| 11 | `modele-cycles.md` et le `CHANGELOG` (paragraphe Lot 5 sous l'entrée v2.8.0 existante, aucun bump) décrivent le comportement réel | ✓ VERIFIED | `modele-cycles.md` l. 87 : section « Correction de classe F1/F44-07 (lot 5) » présente, décrit fidèlement le bug (`dict(os.environ)` réel malgré le nom « maîtrisé ») et le correctif. `CHANGELOG.md` : un seul en-tête `## [v2.8.0]` (l. 3), paragraphe « Lot 5 (F1/F44-07, correction de CLASSE — audit + revue) » ajouté dessous (l. 87). Le commit `9fe4a42` lui-même ne touche que les 4 fichiers de `files_modified` (`git show --stat` confirmé) — aucun `VERSION`/`module.json`/`plugin.json`/`marketplace.json` dedans. **Nuance mesurée, non un gap** : `git diff --stat 424cb23..HEAD -- plugin/planning-core/VERSION plugin/planning-core/module.json` montre 2 fichiers changés dans la plage complète `424cb23..HEAD` — mais ce changement est le commit `feb0d13` (« chore(planning-core v2.8.0) »), le bump mineur **initial et légitime** de livraison de la Phase 44 (nouvelle capacité, `CLAUDE.md` § Numérotation), antérieur à toute la série de lots de correction (mgu lot 4, ol3 lot 5) — pas un second bump introduit par ce lot |

**Score:** 11/11 truths verified (0 present-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `plugin/planning-core/scripts/recalc-planning.sh` | `CANDIDATS_BASH`, `PATH_MAITRISE`, `_resoudre_bash()`, `_bash_candidat_valide()`, `env_maitrise` construit de zéro ; `_jeton_journal` étendu (isprintable) et jeton jamais vide (ValueError) ; détecteur absent/irrégulier distincts ; `ecrire_si_different` par O_NOFOLLOW | ✓ VERIFIED | `bash -n` OK ; tous les symboles présents et câblés (voir Observable Truths 1-8) ; commit `9fe4a42` ne porte que ce fichier + les 3 autres déclarés |
| `plugin/planning-core/scripts/tests/test-recalc-planning.sh` | 5 nouvelles colonnes R-MATRICE-ENV, `MUT-ENV-OS-ENVIRON`, `MUT-BASH-VIA-PATH`, cas F5/F6/F44-06 | ✓ VERIFIED | Suite exécutée par le vérificateur : 270 OK/0 KO ; tous les motifs recherchés présents |
| `plugin/planning-core/references/modele-cycles.md` | Section « Correction de classe F1/F44-07 (lot 5) » | ✓ VERIFIED | Section présente (l. 87-123), décrit fidèlement le comportement réel du code |
| `plugin/planning-core/CHANGELOG.md` | Paragraphe « Lot 5 » sous l'entrée v2.8.0 existante | ✓ VERIFIED | Paragraphe présent (l. 87-102), un seul en-tête `[v2.8.0]` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `recalc-planning.sh` (`detection_gsd`) | `detect-gsd-engine.sh` | `subprocess.run([bash_bin, "--noprofile", "--norc", detect_sh, "--quiet", "--path", planning_abs], env=env_maitrise)` — `env_maitrise` construit de zéro | ✓ WIRED | Lecture directe l. 406-410 : `env=env_maitrise` passé au `subprocess.run` ; `env_maitrise = {"PATH": PATH_MAITRISE}` (l. 403) ne contient jamais `os.environ`. Reproduction adversariale (truth 3) confirme qu'un `PATH` empoisonné de l'appelant n'atteint jamais ce sous-processus |
| `test-recalc-planning.sh` (R-MATRICE-ENV) | `recalc-planning.sh` (`detection_gsd`) | 5 nouvelles colonnes d'environnement adverse, même verdict que la colonne normale | ✓ WIRED | Colonnes `awk-piege bash-piege bash-env-awk bash-func-awk env-var` (l. 2693) présentes et exécutées dans la suite rejouée verte |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Suite complète `test-recalc-planning.sh` (single full run) | `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` | `== Résultat : 270 OK · 0 KO ==` | ✓ PASS |
| 8 suites sœurs (une exécution chacune) | `bash .../test-*.sh` ×8 | comptes exacts attendus (19/0, 26/0, 10/0, 38/0, 14/0, 42/0, 22/0/0, 10/0) | ✓ PASS |
| Non-régression détecteurs | `git diff --stat 424cb23..HEAD -- detect-gsd-engine.sh workstream-policy.sh` | vide | ✓ PASS |
| `check-machine-paths.sh` | `bash scripts/check-machine-paths.sh` | `✓ 1695 fichier(s) suivi(s) balayé(s), aucun chemin absolu de machine` | ✓ PASS |
| `check-version-sync.sh` | `bash scripts/check-version-sync.sh` | `✓ sources synchronisées (v2.66.0, 17 modules)` | ✓ PASS |
| `check-planning-consumers-registered.sh` | `bash plugin/conductor/scripts/check-planning-consumers-registered.sh` | `✓ ... 21 consommateur(s) détecté(s), tous recensés` | ✓ PASS |
| **Reproduction adversariale indépendante** (hors PLAN.md, probe Python maison) : lab GSD réel + `PATH` empoisonné par un faux `awk` (`exit 1` inconditionnel) prépendu, marqueur `gsd_state_version` présent | `subprocess.run(["bash", recalc_sh, "--planning=.planning"], cwd=lab, env={"PATH": poison+":/usr/bin:/bin:/usr/sbin:/sbin", "HOME": ...})` | `rc=3`, stderr `refus d'écriture (P44-D-02a)`, `STATE.md` octet pour octet identique avant/après ; le faux `awk` instrumenté n'est **jamais appelé** (aucune ligne dans son journal d'invocation) | ✓ PASS |

### Anti-Patterns Found

Aucun marqueur de dette (`TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER`) réel dans les 4 fichiers
modifiés. Les seules occurrences de la chaîne `XXX` sont le motif de formatage `\uXXXX`/`\UXXXXXXXX`
(échappement Unicode documenté, non lié à une dette), présentes dans `recalc-planning.sh` et
`modele-cycles.md` (préexistantes, hors périmètre de ce lot), et une référence `DEC-XXX` dans une
entrée `CHANGELOG.md` très antérieure (l. 378, hors périmètre).

### Structure du commit

Un seul commit `9fe4a42` portant exactement les 4 fichiers de `files_modified` (541 insertions,
92 suppressions cumulées sur `recalc-planning.sh` + `test-recalc-planning.sh` + `modele-cycles.md`
+ `CHANGELOG.md`), écart de méthode assumé et documenté dans le SUMMARY.md (correctifs trop
imbriqués dans `detection_gsd()` et son voisinage pour se découper proprement). `git status --short`
sur les 4 fichiers déclarés est vide — rien en attente, tout committé. Message de commit porte la
citation d'arbitrage (« Décision du head sous délégation technique de Willy, session principale,
2026-09-28 ») et les deux lignes d'attribution.

### Requirements Coverage

| Requirement | Description | Status | Evidence |
|-------------|-------------|--------|----------|
| MOTR-02, MOTR-04, MOTR-11, MOTR-12, MOTR-16, MOTR-18 | Déjà `✓ SATISFIED` (Phase 44, `44-VERIFICATION.md`) | ✓ SATISFIED (pré-existant, consolidé) | Ce lot 5 est une correction de classe ciblée sur du code déjà couvert par ces exigences ; il ne les rouvre pas, il corrige un défaut de fiabilité de l'implémentation (`env_maitrise` réellement maîtrisé, résolution de `bash` indépendante du PATH hérité) |

### Human Verification Required

Aucune. Tous les contrôles sont automatisables et ont été rejoués directement par ce vérificateur,
indépendamment du SUMMARY.md, y compris une reproduction adversariale indépendante non prescrite
par le PLAN.md (attaque PATH réelle sur un lab de test frais, marqueur GSD réel, `awk` factice
instrumenté pour confirmer qu'il n'est jamais invoqué).

## Gaps Summary

Aucun écart bloquant. Les onze truths dérivées du frontmatter `must_haves` du plan sont toutes
vérifiées directement dans le code (lecture des lignes concernées de `recalc-planning.sh`), par
exécution réelle de la suite de tests (270 OK / 0 KO, 0 échec, les deux nouveaux mutants du lot 5
tués), par exécution des 8 suites sœurs (vertes, non modifiées), par les trois gates transverses
(`check-machine-paths.sh`, `check-version-sync.sh`, `check-planning-consumers-registered.sh`,
tous verts), et par une reproduction adversariale indépendante du claim de sécurité central (F1) :
un `PATH` empoisonné par un faux `awk` instrumenté ne fait plus écrire le moteur et n'est jamais
invoqué par le sous-processus détecteur — confirmant que `env_maitrise` est réellement une liste
blanche construite de zéro, pas une copie déguisée de l'environnement hérité. Une nuance a été
relevée et documentée (truth 11) sur le bump de version `v2.8.0` : il existe dans la plage
`424cb23..HEAD`, mais provient du commit `feb0d13`, la livraison initiale légitime de la Phase 44
— antérieure à toute la série de lots de correction — et non du commit `9fe4a42` de ce lot, qui ne
touche aucun fichier de version. Ce n'est pas un gap.

---

_Verified: 2026-09-28_
_Verifier: Claude (gsd-verifier)_
