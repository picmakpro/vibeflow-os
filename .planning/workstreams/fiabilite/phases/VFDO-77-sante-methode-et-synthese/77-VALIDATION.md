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

La table par tâche est tenue par les plans (`<automated>` + `<fails_when>` sur chaque tâche). Table de couverture par exigence :

| Exigence | Plan | Vague | Témoin rouge sur le code présent | Suite |
|----------|------|-------|----------------------------------|-------|
| SYNT-02 | 77-01 | 1 | `--format=tsv` rend 64 à la base ; sans l'option, sortie identique à la copie figée (`cmp`) ; `--auto`/`--archive` avec l'option rendent 64 | `test-check-method-budget.sh`, `test-check-instruction-budget.sh` |
| SYNT-08 (données), SYNT-09 | 77-02 | 1 | `meta.vf.burnup` absent à la base ; le texte de `last_activity_desc` est dans le graphe à la base, plus après | `test-cockpit-burnup.sh`, `test-cockpit-projet-visite.sh` |
| SYNT-03, SYNT-04 (données) | 77-03 | 2 | route 404 à la base ; 0 appel sans ouverture ; 1 appel pour 2 GET ; non-gel du serveur ; chemins absents ; lab tiers « non applicable » | `test-cockpit-jauges.sh` |
| SYNT-05 (forme), SYNT-07 (données) | 77-04 | 2 | modules purs absents à la base ; fixtures par catégorie ; filtre sur la date rougit | `test-cockpit-synthese.sh`, `test-cockpit-blocages.sh` |
| SYNT-01, 04, 05, 06, 07, 08 (page) | 77-05 | 3 | bouton et panneau absents à la base ; fichiers partagés intacts ; aucun fond teinté ; clé de stockage unique ; pas de doublon après changement d'onglet | `test-cockpit-synthese-page.sh` |
| SYNT-10 | 77-06 | 4 | module pur absent ; voie sans rattachement comptée « non rattaché » | `test-cockpit-synthese.sh` (plan dépendant, à revalider) |

*Le détail témoin / mutation / sonde positive par exigence est celui de la section « Validation Architecture » de `77-RESEARCH.md` ; chaque plan le recopie dans ses tâches.*

---

## Wave 0 Requirements

- [ ] copies figées des deux gates (A/B octet pour octet) et section « TSV » dans leurs suites — SYNT-02
- [ ] `test-cockpit-jauges.sh` + fixtures TSV figées ; faux gates et faux `gh` placés hors du lab — SYNT-03, 04
- [ ] `test-cockpit-burnup.sh` + lignes de checklist figées — SYNT-08
- [ ] `test-cockpit-synthese.sh` (calcul pur et mémoire) et `test-cockpit-synthese-page.sh` (navigateur) — SYNT-01, 05, 06, 07
- [ ] réécriture de l'assertion R3.25 de `test-cockpit-projet-visite.sh` — SYNT-09
- [ ] ligne de durée dans `scripts/ci-shard-suites.sh` pour chaque suite de page

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
