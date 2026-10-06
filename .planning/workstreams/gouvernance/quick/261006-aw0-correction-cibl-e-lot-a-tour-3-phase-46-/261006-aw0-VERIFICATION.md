---
phase: quick-261006-aw0
verified: 2026-10-06T09:40:00Z
status: passed
score: 4/4 must-haves verified
covered_files:
  - .planning/workstreams/gouvernance/quick/261006-aw0-correction-cibl-e-lot-a-tour-3-phase-46-/261006-aw0-PLAN.md
  - .planning/workstreams/gouvernance/quick/261006-aw0-correction-cibl-e-lot-a-tour-3-phase-46-/261006-aw0-SUMMARY.md
  - plugin/planning-core/references/modele-cycles.md
  - plugin/planning-core/scripts/poser-verdict.sh
  - plugin/planning-core/scripts/tests/test-cloture-gates.sh
  - plugin/planning-core/scripts/tests/test-d1-surveillance.sh
covered_digest: "v2:sha256:7af646ba9686c36ccd96e399debbfbe59d13d915f845148bb70d5ce793741e6e"
behavior_unverified: 0
overrides_applied: 0
re_verification: false
gaps: []
declared_points:
  - "REM-8 : G1, G3, G4 (et G7, même famille) lisent l'unité en NFC — refus, jamais passage (limite (bf))"
  - "REM-9 : `~ R-EMP-13 (c)` reste une ligne `~`, texte exact, non convertie"
  - "REM-10 : limites de la simulation ; la preuve sur ext4 réel est la CI Linux sur le commit"
---

# Quick 261006-aw0 (fix-46-a tour 3, NFD ext4) — Rapport de vérification

**Objectif :** diagnostiquer le rouge CI ext4 de R-BANC-NFD (« 31 / 29 »), corriger le code ET/OU le test sans relâcher d'attente, prouver sous simulation d'un FS sensible à la normalisation et sous APFS.
**Commit vérifié :** 18188d96 sur 1cbe7fd4 (HEAD actuel). **Vérifié :** 2026-10-06. **Re-vérification :** non.
**Verdict : PASSED.** Aucun trou réel. Les points REM-8..10 sont des points déclarés, confirmés tels quels dans le code.

## Contrôles demandés

### (1) Le diagnostic est-il juste ? — VERIFIED

- **Site corrigé** (`poser-verdict.sh`) : `inscrire_ecriture_moteur(racine, chemin_rel, par, chemin=None)` ; sans `chemin`, jonction `racine` + `chemin_rel` (marqueur `# d1-moteur-brut`, appelants à chemin ASCII : `.planning/derogations-gates.log`) ; l'appel `# d1-moteur-verdict` passe `chemin_verdict` = `os.path.join(unite, "VERDICT.md")` avec `unite = os.path.realpath(--unite)` (nom du disque). La clé inscrite reste `unite_rel`, composants NFC (`# nfc-verdict-unite`). I/O sur le nom brut du disque, clé du journal en NFC : conforme à la règle du mandat.
- **Preuve que la correction de code est nécessaire et non décorative** : copie du dépôt dans le scratchpad, appel `# d1-moteur-verdict` remis à sa forme d'avant (sans `chemin_verdict`), section `banc` rejouée SOUS SIMULATION : `✗ R-BANC-NFD` « journal de D1 différent (31 ligne(s) NFC, 29 disque NFD) ; NFC seul : moteur …/03-jugé/VERDICT.md, moteur …/04-échoué/VERDICT.md ; disque NFD seul : - » (26 OK · 1 KO). Le test corrigé rougit donc pour la bonne raison sur le code d'avant, et la copie a été supprimée (dépôt intact).
- **Recensement indépendant (grep `os.path.join(racine, *`, `*composants`, `composants_nfc`, `unicodedata`, `inscrire_ecriture_moteur`) sur planning-hook.sh, recalc-planning.sh, deroger-gate.sh, poser-verdict.sh :**

| Site | Chemin de l'I/O | Classe |
|---|---|---|
| poser-verdict.sh 786-795, 1081 | `chemin_verdict` (disque), clé NFC | corrigé |
| poser-verdict.sh 1078 / 557 | journal ASCII ; `_ouvrir_dossier_livrable` sur entrées `ecrit:` en forme déclarée | sans effet / limite (bf) (livrable absent, refus) |
| recalc-planning.sh 2310-2357 | `planning` (dossier du disque) + nom ASCII | brut, conforme |
| recalc-planning.sh 1150 | `_ouvrir_dossier_livrable`, forme déclarée | limite (bf) |
| deroger-gate.sh 224-229, 295 | journal ASCII ; NFC = clé de dérogation (pas d'I/O) | sans effet |
| planning-hook.sh 1145, 1496, 2616, 2972 | clé / comparaison NFC en mémoire ; 2972 = journal ASCII | sans effet |
| planning-hook.sh 1768, 1859, 1911 (G1, G3, G4) | `os.path.join(racine, *composants NFC)` | limite (bf) documentée : refus, jamais passage |
| planning-hook.sh 1965, 2037 (G7) | `lexists` / `porte_marqueur_code` / `lab_habite` sur `racine` + composants NFC | même famille que (bf) ; **fail-closed confirmé** : sur ext4 un ancêtre au nom NFD y est lu absent, donc création de `.planning` présumée et refus possible, jamais un passage. Non rouge sous simulation. Déclaré REM-8 |

  Aucun autre site de la classe « I/O sur chemin NFC suivie d'un effet » n'a été trouvé : pas de site oublié qui rougirait sous ext4. D1 (`_sous_dossiers`, `reconcilier`), G2 et le vérificateur de juges font leur I/O sur le nom du disque (confirmé par les suites sous simulation : liste surveillée de 29 chemins dont 24 en forme de disque NFD, G2 silencieux).

### (2) Aucune attente relâchée — VERIFIED

`git show 18188d96` sur `test-cloture-gates.sh` : lignes retirées = l'ancienne docstring, l'appel `materialiser_disque_nfd(...)` sans le paramètre, et l'ancien message d'écart (4 lignes). La comparaison `journal_d1(lab_d1_nfc) != journal_d1(lab_d1_nfd)` est inchangée ; `journal_d1` ne filtre aucun genre (`moteur` compris). Aucune ligne `~` ajoutée ni convertie (le seul `~` de R-BANC-NFD, G3/G4 sur disque NFD, est antérieur et inchangé). Le changement est un renforcement : les deux disques portent désormais les MÊMES verdicts (posés par la vraie poser-verdict.sh sur tout système), comparés en entier ; l'écart nomme les lignes d'un seul côté. `hors_planning_declare` ne touche que les chemins hors `.planning/` (livrables en forme déclarée, que D1 ne lit pas) ; les noms sous `.planning/` restent NFD (24 chemins en forme de disque NFD sur 29, observé). La preuve (3) G3/G4 NFD garde le comportement par défaut. Aucune assertion de `test-d1-surveillance.sh` retirée (ajouts seuls : R-D1-18, MUT-D1-MOTEUR-NFD).

### (3) Périmètre du commit — VERIFIED

- `git diff 1cbe7fd4 HEAD --name-only` : exactement `plugin/planning-core/references/modele-cycles.md`, `plugin/planning-core/scripts/poser-verdict.sh`, `plugin/planning-core/scripts/tests/test-cloture-gates.sh`, `plugin/planning-core/scripts/tests/test-d1-surveillance.sh`. Rien d'autre (STATE.md, ROADMAP.md, dag.json non touchés par le commit ; le dag.json modifié dans l'arbre de travail est antérieur et hors commit).
- 3 trailers `Gate-Touche:` (un par fichier sous `plugin/planning-core/scripts/`), forme `<chemin> — <raison>`.
- Bloc partagé ast-identique : `test-cloture-empreintes.sh` R-EMP-04 vert (« trois copies ast-identiques du bloc partagé », 49 OK).
- `scripts/check-machine-paths.sh` : rc 0, aucun chemin absolu de machine.
- Limite (bf) de `modele-cycles.md` : une proposition ajoutée, texte antérieur inchangé.

### (4) Rejeu au premier plan, un appel par suite — VERIFIED

| Suite | Mode | Résultat | Détail |
|---|---|---|---|
| test-cloture-gates.sh | APFS | rc 0, **73 OK · 0 KO** (72 s) | R-BANC-NFD vert (« journal identique ») ; MUT-NFD-CHEMIN, MUT-READDIR-NFC, MUT-RECENCE-NFC TUÉ |
| test-d1-surveillance.sh | APFS | rc 0, **37 OK · 0 KO** | R-D1-18 vert ; `✓ MUT-D1-MOTEUR-NFD non applicable ici` (déclaré) |
| test-cloture-empreintes.sh | APFS | rc 0, **49 OK · 0 KO** | R-EMP-04 vert, MUT-EMP-AST tué ; `~ R-EMP-10b` (axe non-UTF-8, hors périmètre) |
| test-cloture-gates.sh | SIMULATION (shim du scratchpad, autotest `SIMULATION ACTIVE` / `AUTOTEST CONFORME`, 887 appels interposés) | rc 0, **73 OK · 0 KO** | seule ligne `~` : `R-BANC-NFD (disque NFD, 11 écritures G3/G4) non exercé … limite (bf)` ; les trois mutants TUÉS POUR LEUR RAISON (lues dans « obtenu (mutant) » : « jumeau NFD de … », « liste surveillée de 5 chemin(s) sur le disque NFD », « (D1, égalité de préfixe) », témoin inchangé) |
| test-d1-surveillance.sh | SIMULATION (163 appels) | rc 0, **37 OK · 0 KO** | `~ R-D1-15` (légitime, lab créé en NFC) ; `✓ MUT-D1-MOTEUR-NFD TUÉ — R-D1-18 rougit … obtenu [] … 1 contournement(s)` : le mutant (appel d'avant) est tué pour sa raison |

`XDG_CACHE_HOME` = scratchpad `fix46a-verif-xdg`. Aucun background, nohup ou `&`.

## Vérité par vérité (must_haves du PLAN et mandat)

| # | Vérité | Statut | Preuve |
|---|---|---|---|
| 1 | Diagnostic tranché sur preuve : TEST ET CODE | VERIFIED | Copie avec l'ancien appel : « 31 / 29 », deux lignes `moteur` côté NFC seul ; code lu site par site |
| 2 | Après correction, sous simulation : suite verte, journal D1 comparé en entier, trois mutants tués pour leur raison ; APFS 73 OK | VERIFIED | Rejeux ci-dessus |
| 3 | Branche CODE : I/O sur le nom du disque, clé NFC ; R-D1-18 et MUT-D1-MOTEUR-NFD (tué sous simulation, « non applicable » sous APFS) ; (bf) complétée | VERIFIED | Diff, rejeux, R-REFERENCE non rejoué isolément mais le texte (bf) est présent et la suite d'empreintes verte |
| 4 | Un commit, trailers Gate-Touche, périmètre de 4 fichiers, machine-paths rc 0, rien poussé | VERIFIED | `git diff --name-only`, trailers comptés (3), `check-machine-paths.sh` rc 0 |

## Points déclarés (pas des trous)

- **REM-8** : G1, G3, G4 lisent l'unité en NFC : refus, jamais passage (limite (bf)). G7 (planning-hook.sh 1965, 2037) est de la même famille, fail-closed, non nommé par le texte de (bf) : confirmé dans le code, à remonter, hors tour 3.
- **REM-9** : `~ R-EMP-13 (c)` reste une ligne `~` au texte exact ; non convertie en assertion (élargissement refusé). Sous APFS la case (c) s'exerce (aucune ligne `~` correspondante dans mon rejeu) ; sous simulation, je n'ai pas rejoué test-cloture-empreintes.sh (le mandat de vérification ne le demandait qu'en APFS) : la ligne `~` sur système sensible vient des notes du tour.
- **REM-10** : la simulation émule (pas de couche shell, pas de casse ext4, pas de noms non UTF-8, jumeaux par alias). Aucun mode de simulation permanent dans le dépôt (confirmé : le diff ne touche aucun outil de simulation).

## Observations non bloquantes

- R-D1-18 est vert sous APFS même avec l'ancien code (la forme NFC y désigne le même dossier) : c'est le comportement déclaré (« non applicable ici »). Son pouvoir de détection n'existe que sur FS sensible (simulation, CI Linux). Pas un trou : le mutant est tué sous simulation et R-BANC-NFD couvre le même cas partout où la CI Linux tourne.
- La confirmation définitive sur ext4 réel reste la CI Linux sur ce commit après push (non fait : « rien poussé » est une exigence du mandat). Pas de décision humaine requise pour cette vérification.
- Écart de procédure déjà déclaré au SUMMARY (deux suites lancées en parallèle par l'exécutant, rejouées séquentiellement) : sans effet sur le résultat ; mes rejeux sont séquentiels.

---

_Verified: 2026-10-06T09:40:00Z_
_Verifier: Claude (gsd-verifier)_
