---
phase: "77"
slug: "sante-methode-et-synthese"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-11"
---

# Phase 77 — Validation Strategy

> Contrat de validation par phase. Source : section « Validation Architecture » de `77-RESEARCH.md`. Chaque témoin est d'abord joué rouge sur le code présent, avec la mutation qui prouve qu'il sait rougir, la trace étant gardée dans `77-NN-RED-TRACE.md` du plan ; une sonde positive précède tout témoin négatif. Les sondes de `sondes/` mesurent, elles ne prouvent pas.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | suites bash maison (`assert_eq`, `assert`, `kills`), node pour les modules purs, Chrome headless par l'aide de session partagée pour les suites de page |
| **Config file** | aucun ; découverte `*/tests/test-*.sh` (`scripts/ci-shard-suites.sh`) |
| **Quick run command** | la suite visée seule : `bash plugin/conductor/scripts/tests/test-check-method-budget.sh` ; `bash plugin/cockpit/scripts/tests/test-cockpit-jauges.sh` (noms proposés) |
| **Full suite command** | suites touchées + consommateurs (`test-cockpit-projet-visite.sh`, `test-cockpit-projet-graphe.sh`, `test-cockpit-vendor.sh`, `test-cockpit-chrome-fr.sh`, `test-cockpit-securite.sh`, `test-cockpit-serveur.sh`) ; en CI, les shards |
| **Estimated runtime** | gates et modules purs : secondes ; suites de page : à mesurer au premier rouge (ligne de durée dans `ci-shard-suites.sh`) |

---

## Sampling Rate

- **Après chaque commit de tâche :** la suite visée seule.
- **Après chaque vague :** les suites touchées et leurs consommateurs.
- **Avant la vérification de phase :** `scripts/check-version-sync.sh`, `scripts/check-machine-paths.sh`, gardes G-1/G-2/G-3 localement, suites complètes en CI.
- **Latence maximale de retour :** 60 s hors suites de page.

---

## Per-Task Verification Map

La table par tâche est tenue par les plans (`<automated>` + `<fails_when>` sur chaque tâche). Table de couverture par exigence, réalignée le 2026-11-11 sur 8 plans en 6 vagues (scission de 77-05, P77-D-30 ; revalidation contre la Phase 79 à `c19c7461`, la Phase 74 à `33bb4aad`) :

| Exigence | Plan | Vague | Témoin rouge sur le code présent | Suite |
|----------|------|-------|----------------------------------|-------|
| SYNT-02, SYNT-04 (côté gate) | 77-01 | 1 | `--format=tsv` rend 64 à la base ; sans l'option, sortie identique à la copie figée (`cmp`) ; `--auto`/`--archive`/`--dry-run`/`--format=json` rendent 64 ; ligne `NON-APPLICABLE` en lab tiers ; invariants « inchangé » mesurés depuis `AVANT` (RED-TRACE) | `test-check-method-budget.sh` (TF1..TF13, MF1..MF8), `test-check-instruction-budget.sh` (TI1..TI9, MI1..MI6) |
| SYNT-07 (blocages), SYNT-08 (données), SYNT-09 | 77-02 | 1 | champs `burnup` et `blocagesState` absents du graphe à la base ; texte de `last_activity_desc` présent à la base, absent après ; BU11 sur `instantane().projet` (conditionné à 79-09) ; facultatifs déclarés dans `meta.vf.optionnels` | `test-cockpit-burnup.sh`, `test-cockpit-blocages.sh` (rangé ici, plus à 77-04), `test-cockpit-projet-visite.sh` (R3.25 réécrite) |
| SYNT-03, SYNT-04 (côté route) | 77-03 | 2 | route 404 à la base ; ligne de `ROUTES` (dépendances DURES sur 79-05 et 79-07) ; 0 appel sur 3 tours de collecte ; 1 appel pour 2 GET simultanés et dans les 60 s ; non-gel du serveur < 200 ms ; chemins absents ; lab tiers « non applicable » ; faux `gh` hors du lab ; JR1..JR9 plus JR10 (environnement git durci) ; mutants dont M-ENV-GIT et M-COLLECTE (`vf-cockpit-collecte-etapes.mjs`, `live.mjs`) | `test-cockpit-jauges.sh` |
| SYNT-05, SYNT-06, SYNT-07 (calcul pur et mémoire) | 77-04 | 2 | modules purs absents à la base ; fixtures par catégorie ; filtre sur la date rougit ; `base.h` ; section SV ; lignes `AJOUT`, plafond de 299, cliquet de 160 points de code ; mutants par `cockpit_module_copie` | `test-cockpit-synthese.sh` |
| SYNT-01 (coquille) | 77-05 | 3 | bouton et panneau absents à la base ; fichiers partagés intacts depuis `AVANT` ; registre de blocs inscrit avant ou après la coquille (RB1) ; pas de doublon après changement d'onglet (O1) ; aucun jeton ni requête interdite (W11a, CS1) ; ligne-résumé prouvée par un bloc témoin du banc (W18) ; banc `chrome-synthese.mjs` créé avec sonde positive par outil | `test-cockpit-synthese-page.sh` |
| SYNT-01, SYNT-04, SYNT-08 (page : burn-up et jauges) | 77-06 | 4 | blocs 2 et 3 absents à la base ; « N sur M · P % » égal au pied de jalon ; verdicts en mot et glyphe ; aucune lecture des gates au chargement (JA1) ; mutants sur copie de module chargée | `test-cockpit-synthese-blocs.sh` |
| SYNT-05, SYNT-06, SYNT-07 (page : dernière visite) | 77-08 | 5 | bloc 1 absent à la base ; clé de stockage unique (W11) ; aucun fond teinté (W4) ; XSS inerte (W15) ; « Tout vu » et `storage` sans vol de focus (W13v) ; ordre final des blocs (OB1) ; documentation de l'effacement, de la persistance et de `base.h` (D1) ; rejeu de la suite de 77-05 | `test-cockpit-synthese-visite.sh` |
| SYNT-10 | 77-07 | 6 | module pur absent ; voie sans rattachement comptée « non rattaché » (trois cas) ; aucune monnaie ; total coupé dit minorant avec le nombre de voies omises (CO11) ; cinq états de la frise (CO12) ; `voiesOmises` à 0 sans nombre affiché (CO11) ; agrégat réel de la 74 consommé (CO7) ; deux changements d'onglet sans doublon (CO14, BO1, V10, O1) ; phase hors jalon (CO10) ; plan à revalider après les Phases 79 et 74 | `test-cockpit-synthese-cout.sh` |

À réaligner après exécution : les identifiants de témoins de 77-01 à 77-04 sont ceux des plans à leur état commité ; la colonne ci-dessus les cite sans les redéfinir.

*Le détail témoin / mutation / sonde positive par exigence est celui de la section « Validation Architecture » de `77-RESEARCH.md` ; chaque plan le recopie dans ses tâches.*

---

## Wave 0 Requirements

- [ ] copies figées des deux gates (A/B octet pour octet) et section « TSV » dans leurs suites — SYNT-02
- [ ] `test-cockpit-jauges.sh` + fixtures TSV figées ; faux gates et faux `gh` placés hors du lab — SYNT-03, 04
- [ ] `test-cockpit-burnup.sh` + lignes de checklist figées — SYNT-08
- [ ] `test-cockpit-synthese.sh` (calcul pur et mémoire), `test-cockpit-synthese-page.sh`, `test-cockpit-synthese-blocs.sh`, `test-cockpit-synthese-visite.sh` et `test-cockpit-synthese-cout.sh` (navigateur) — SYNT-01, 04, 05, 06, 07, 08, 10
- [ ] banc `chrome-synthese.mjs` (77-05) : chaque outil sous sonde positive ; mutants d'interface sur une copie du module (`COCKPIT_MODULE`, `cockpit_module_copie`) chargée de façon prouvée
- [ ] « N suites » des deux README racine remesuré au compte du gate par chaque plan qui ajoute une suite (P77-D-33)
- [ ] réécriture de l'assertion R3.25 de `test-cockpit-projet-visite.sh` — SYNT-09
- [ ] ligne de durée dans `scripts/ci-shard-suites.sh` et ligne `AJOUT` dans `VENDORED.txt` (fichiers `ui/` neufs) pour chaque suite et chaque fichier de page

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Lecture du panneau Projet sans la prose « Maintenant » (A77-2) | SYNT-09 | goût de lecture de Samuel | recette de fin de jalon, juges à captures d'abord |

---

## Validation Sign-Off

- [ ] Toutes les tâches ont un `<automated>` ou une dépendance de Wave 0
- [ ] Pas de 3 tâches consécutives sans vérification automatisée
- [ ] Wave 0 couvre toutes les références MISSING
- [ ] Aucun drapeau de mode surveillance
- [ ] `nyquist_compliant: true` posé après la vérification des plans

**Approval:** en attente
