---
quick_id: 260928-b4c
verified: 2026-09-28T08:15:00Z
status: passed
score: 11/11 must-haves verified
covered_files:
  - ".planning/BACKLOG.md"
  - ".planning/workstreams/gouvernance/ROADMAP.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-44-moteur-mod-le-de-donn-es-et-recalcul-d-tat-d-riv-du-disque/44-PASSAGE-LABS.md"
  - ".planning/workstreams/gouvernance/quick/260928-b4c-correction-cibl-e-lots-1-2-phase-44-gard/260928-b4c-PLAN.md"
  - ".planning/workstreams/gouvernance/quick/260928-b4c-correction-cibl-e-lots-1-2-phase-44-gard/260928-b4c-SUMMARY.md"
  - "plugin/planning-core/CHANGELOG.md"
  - "plugin/planning-core/module.json"
  - "plugin/planning-core/references/modele-cycles.md"
  - "plugin/planning-core/scripts/recalc-planning.sh"
  - "plugin/planning-core/scripts/tests/test-recalc-planning.sh"
covered_digest: "v1:sha256:9c9dd50337a59541d522280c624905e11f23f54c65e8f12e15782165e9d1c231"
behavior_unverified: 0
overrides_applied: 0
---

# Quick 260928-b4c — correction ciblée lots 1+2, Phase 44 — Vérification

**Objectif déclaré** : corriger F3/F4/F5/F6, couvrir les 9 marqueurs de `detection_gsd()` (F2),
scinder le code 2 du détecteur GSD (lot 2 L1), assainir `cloture.log` (lot 2 L2), et mettre à jour
la doc/hygiène associée — sans régression sur les 8 suites sœurs de `planning-core`.

**Vérifié le** : 2026-09-28
**Statut** : `passed`
**Racine du dépôt** : `.` (worktree `gouvernance-44`)
**Commits vérifiés (dans l'ordre)** : `e4898a0` (code), `aa8420d` (tests), `fda472a` (doc)

## Méthode

Chaque affirmation a été relue directement dans `recalc-planning.sh` (pas seulement dans le
SUMMARY), puis, pour les gardes de sécurité, reproduite manuellement dans un fixture isolé sous
`scratchpad/` (hors du dépôt), en plus de l'exécution réelle des deux suites de tests
(`test-recalc-planning.sh` et les 8 suites sœurs).

## Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | F3 : `_lister_entrees` consomme `os.scandir` entièrement dans son `try` | ✓ VERIFIED | `recalc-planning.sh:387-392` — `entrees = os.scandir(dossier); return {e.name for e in entrees}` **dans** le bloc `try`, `except OSError: return set()`. Test `F3 _lister_entrees` + `MUT-LISTER-ENTREES TUÉ` verts. |
| 2 | F4 : lien symbolique (ou non-régulier) à l'emplacement d'INDEX.md/STATE.md/cloture.log/.recalc-cache.json → refusé, exit 1, rien d'écrit, cible externe intacte | ✓ VERIFIED | `appliquer_ecritures` (`recalc-planning.sh:1364-1371`) teste les 4 noms via `est_fichier_regulier` (lstat, `recalc-planning.sh:245-252`), jamais `os.path.isfile`. **Reproduit manuellement** (hors suite) : symlink sur `STATE.md` puis sur `.recalc-cache.json` vers une cible externe → `exit=1`, message `emplacement occupé par autre chose qu'un fichier régulier`, cible externe et lien inchangés dans les deux cas. |
| 3 | F5 : `ecrire_si_different` ferme toujours son descripteur temporaire, y compris si `os.fchmod` lève avant `os.fdopen` | ✓ VERIFIED | `recalc-planning.sh:1330-1349` — `fd_non_adopte = True` posé avant `os.fchmod`, remis à `False` seulement après que `os.fdopen` a pris possession ; le `except` ferme `fd_tmp` si `fd_non_adopte` est encore vrai. Test `F5 ecrire_si_different` (200 échecs de fchmod injectés, pas d'épuisement) + `MUT-ECRIRE-SI-DIFFERENT-FD TUÉ` verts. |
| 4 | F2 : chacun des 9 marqueurs `# motif-*` de `detection_gsd()` a un mutant dédié, y compris `motif-partition-compartiment` | ✓ VERIFIED | 10 marqueurs recensés dans le code (`grep "# motif-"` → detecteur-irregulier, sous-processus-en-echec, code-0, code-3-terrain-libre, code-2-migration, marqueur-racine, marqueur-compartiment, partition-compartiment, code-1-sans-marqueur, repli-generique — 9 « historiques » + le code-2-ou-3 scindé en 2). Tous ont un mutant nommé dans `test-recalc-planning.sh` (`MUT-GSD`, `MUT-GSD-FERME`, `MUT-SOUS-PROCESSUS`, `MUT-MARQUEUR-RACINE`, `MUT-MARQUEUR-COMPARTIMENT`, `MUT-PARTITION-COMPARTIMENT`, `MUT-CODE1-SANS-MARQUEUR`, `MUT-REPLI-GENERIQUE`, `MUT-CODE3-TERRAIN-LIBRE`, `MUT-CODE2-MIGRATION`), tous « TUÉ » à l'exécution. |
| 5 | F6 : `combinaison-non-prevue` documenté (code + `modele-cycles.md`) comme garde-fou inatteignable avec R1-R8/Φ0-Φ5 actuels | ✓ VERIFIED | `recalc-planning.sh:99-104` (commentaire dans `LIBELLES`) et `modele-cycles.md` diff (`72eb408..fda472a`) — paragraphe ajouté § Défaut défensif : « ce libellé n'est donc produit par AUCUN chemin du code actuel (F6, 2026-09-28) ». |
| 6 | DOC-44-03 : la ligne d'usage de `modele-cycles.md` inclut `-h\|--help` | ✓ VERIFIED | `modele-cycles.md:478` (post-diff) : `recalc-planning.sh [--planning=<dossier>] [--read-only] [-h|--help]`. Confirmé aussi en exécutant `recalc-planning.sh --help` sous `/bin/zsh` : la même ligne d'usage s'imprime. |
| 7 | DOC-44-02 : `module.json` mentionne le moteur de recalcul d'état par cycles | ✓ VERIFIED | `module.json:5` — « Inclut un moteur de recalcul d'état dérivé du disque par cycles (recalc-planning.sh). » Version du module inchangée (`v2.8.0` avant/après — pas de release, conforme à ADR-073 / CLAUDE.md « Quand publier »). |
| 8 | Banc F1 : `44-PASSAGE-LABS.md` dit « environ 2 000 (2 021 mesurés) », plus « plusieurs milliers » | ✓ VERIFIED | `44-PASSAGE-LABS.md:55` : « une arborescence `.planning/` d'environ 2 000 (2 021 [mesurés]) ». |
| 9 | Lot 2 L1 : le code 2 du détecteur (migration) refuse l'écriture, distinct du code 3 | ✓ VERIFIED | `detection_gsd` (`recalc-planning.sh:344-352`) : `code == 3` → `"non-gsd"` (`motif-code-3-terrain-libre`, écriture autorisée) ; `code == 2` → `"non-concluante"` (`motif-code-2-migration`, écriture **refusée**). Tests `R-CODE2-MIGRATION` (rc=3, message P44-D-02a, empreinte `.planning/` identique avant/après) + `MUT-CODE3-TERRAIN-LIBRE`/`MUT-CODE2-MIGRATION` « TUÉ » verts. |
| 10 | Lot 2 L2 : chemin/auteur/verdict/tentative passent par `_jeton_journal` — un seul enregistrement lisible par `LIGNE_JOURNAL_RE` sur la valeur piégée | ✓ VERIFIED | `_formater_ligne_journal` (`recalc-planning.sh:1208-1215`) passe les 4 champs par `_jeton_journal` (`recalc-planning.sh:1195-1205`, réduit espaces/tabs/`\n` et `=` à `_`). Test `L2 _formater_ligne_journal` (MATCH=True, un seul enregistrement) + `MUT-JOURNAL-SANITIZE TUÉ` verts. |
| 11 | Aucune régression : les 8 suites sœurs restent vertes et non modifiées ; sonde PY39 verte sous bash et zsh | ✓ VERIFIED | Voir sections dédiées ci-dessous. |

**Score** : 11/11 truths vérifiées, 0 en attente de vérification humaine.

## Exécution réelle de `test-recalc-planning.sh`

```
bash plugin/planning-core/scripts/tests/test-recalc-planning.sh
== Résultat : 171 OK · 0 KO ==
```

Rejoué directement par le vérificateur (pas de confiance sur le chiffre du SUMMARY) — **171 OK / 0
KO**, conforme à la fois au SUMMARY et à la couverture attendue par le PLAN (F3/F5, 8 nouveaux
MUT- de `detection_gsd()`, R-CODE2-MIGRATION, L2/MUT-JOURNAL-SANITIZE, mises à jour R56/MUT-NOFOLLOW/
MUT-TYPE-ECRITURE).

## Les 8 suites sœurs

`git diff --stat 72eb408..fda472a -- plugin/planning-core/scripts/tests/ ':!.../test-recalc-planning.sh' ':!.../fixtures/recalc-planning-banc.txt'` → **vide** (aucune des 8 suites sœurs n'a été touchée par les 3 commits du lot).

| Suite | Commande | Résultat | Statut |
|---|---|---|---|
| `test-check-planning-state.sh` | `bash …` | 19 ok, 0 ko | ✓ PASS |
| `test-detect-gsd-engine.sh` | `bash …` | 26 ok, 0 ko | ✓ PASS |
| `test-detect-planning-debt.sh` | `bash …` | 10 passés, 0 échoués | ✓ PASS |
| `test-planning-context-hardening.sh` | `bash …` | 38 passés, 0 échoués | ✓ PASS |
| `test-planning-core.sh` | `bash …` | 14 passés, 0 échoués | ✓ PASS |
| `test-planning-hooks.sh` | `bash …` | 42 PASS, 0 FAIL | ✓ PASS |
| `test-workstream-policy.sh` | `bash …` | 22 ok, 0 ko, 0 skip | ✓ PASS |
| `test-workstream-symlink-escape.sh` | `bash …` | 10 ok, 0 ko | ✓ PASS |

Toutes vertes, toutes rejouées directement par le vérificateur (pas seulement citées du SUMMARY).

## Sonde PY39 (syntaxe Python 3.9, portabilité bash/zsh)

La sonde `PY39-SYNTAXE-OK`/`PY39-SONDE-BASH-ZSH-OK` documentée dans les plans 44-01/44-03/44-04
n'est pas câblée en suite automatisée (`test-recalc-planning.sh` ne la contient pas) — c'est un
contrôle manuel repris à l'identique à chaque plan de la Phase 44. Le vérificateur l'a rejouée
lui-même plutôt que de faire confiance à l'affirmation du SUMMARY :

- corps Python extrait de `recalc-planning.sh` (lignes 68-1512, entre les deux marqueurs
  `PY_RECALC_PLANNING_EOF`) et passé à `ast.parse(..., feature_version=(3, 9))` + au grep ciblé
  PEP 701 → **`PY39-SYNTAXE-OK`**.
- `bash plugin/planning-core/scripts/recalc-planning.sh --help` et
  `/bin/zsh plugin/planning-core/scripts/recalc-planning.sh --help` → sortie identique sous les
  deux shells (usage avec `-h|--help`), confirmant que le heredoc quoté (`<<'PY_RECALC_PLANNING_EOF'`)
  reste portable — aucune apostrophe/guillemet du corps Python n'a été introduite par les
  modifications de ce lot qui romprait ce quotage.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| F4 — symlink STATE.md refusé, cible intacte | reproduction manuelle (fixture scratch) : `bash recalc-planning.sh --planning=<fixture>` avec `STATE.md` en symlink externe | `exit=1`, message de refus, `external-target.txt` inchangé, symlink intact | ✓ PASS |
| F4 — symlink .recalc-cache.json refusé, cible intacte | idem, symlink sur `.recalc-cache.json` | `exit=1`, message de refus, cible externe inchangée | ✓ PASS |
| PY39 — corps Python conforme 3.9 | `ast.parse(feature_version=(3,9))` sur le corps extrait | `PY39-SYNTAXE-OK` | ✓ PASS |
| `--help` portable bash/zsh | `bash … --help` puis `/bin/zsh … --help` | usage identique, `-h\|--help` présent | ✓ PASS |
| Aucun motif dangereux introduit | `grep -nE 'import yaml\|shell=True\|eval(\|exec(\|gsd-core\|gsd-tools\|get-shit-done\|phases_trace' recalc-planning.sh` | rien imprimé | ✓ PASS |
| JSON `module.json` valide | `python3 -c "import json; json.load(open(...))"` | pas d'erreur | ✓ PASS |
| Synchronisation de version | `bash scripts/check-version-sync.sh` | `✓ sources synchronisées (v2.66.0, 17 modules)` | ✓ PASS |
| Chemins machine | `bash scripts/check-machine-paths.sh` | `✓ 1684 fichier(s) suivi(s) balayé(s), aucun chemin absolu de machine` | ✓ PASS |

## Périmètre des fichiers modifiés

`git diff --stat 72eb408..fda472a` : exactement les 8 fichiers déclarés dans `files_modified` du
SUMMARY (`recalc-planning.sh`, `test-recalc-planning.sh`, `modele-cycles.md`, `module.json`,
`CHANGELOG.md`, `44-PASSAGE-LABS.md`, `ROADMAP.md`, `BACKLOG.md`) — aucun fichier non déclaré
touché. `module.json` : version inchangée (`v2.8.0`), seule la description et le CHANGELOG ont
bougé — conforme à « aucune version publiée » (Task 3 `done`) et à la doctrine ADR-073.

## Anti-Patterns Found

Aucun `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER` introduit par les 3 commits dans
`recalc-planning.sh` ou `test-recalc-planning.sh` (les seules occurrences de `XXXX` relevées par le
grep sont des gabarits hexadécimaux dans une docstring — `\uXXXX`/`\UXXXXXXXX` — pas des marqueurs
de dette).

**Note informative (hors périmètre du lot, non bloquante)** : `ROADMAP.md` contient des lignes
`TBD (posés au cadrage)` pour les Phases 45-50 — convention de gabarit du roadmap GSD, présente
**avant** ce lot pour toutes les phases non encore planifiées (pas introduite ni touchée par ce
lot, qui n'a ajouté que 3 lignes à la Phase 45 sous forme de note « À envisager au cadrage »).

## Requirements Coverage

Ce quick task ne déclare pas de champ `requirements:` (correction ciblée post-hoc, pas un plan de
phase standard — cf. note de méthode du PLAN.md). Aucune exigence MOTR-01..18 orpheline détectée
dans ce périmètre.

## Human Verification Required

Aucune — toutes les truths sont vérifiables par lecture de code, exécution de test ou
reproduction manuelle déterministe.

## Gaps Summary

Aucun gap. Les 11 must-haves du frontmatter du PLAN sont vérifiés positivement dans le code livré
(pas seulement déclarés dans le SUMMARY) : les trois gardes de sécurité/robustesse (F3/F4/F5) sont
lues dans `recalc-planning.sh` et, pour F4, reproduites manuellement en dehors de la suite de
tests ; F2 couvre bien les 10 marqueurs actuels de `detection_gsd()` (9 historiques + le
scindage code-2/code-3 du lot 2) ; F6, DOC-44-02, DOC-44-03 et le Banc F1 sont confirmés dans la
documentation livrée ; le scindage lot 2 L1 (code 2 refusé, distinct du code 3) et
l'assainissement lot 2 L2 (`_jeton_journal` sur les 4 champs) sont confirmés dans le code et par
test dédié ; les 8 suites sœurs sont vertes et prouvées non modifiées par diff ; la sonde PY39 a
été rejouée indépendamment (pas seulement citée) et reste verte.

---

_Verified: 2026-09-28T08:15:00Z_
_Verifier: Claude (gsd-verifier)_
