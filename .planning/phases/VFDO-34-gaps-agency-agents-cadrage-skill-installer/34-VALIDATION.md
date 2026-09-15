---
phase: "34"
slug: "gaps-agency-agents-cadrage-skill-installer"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: true
created: "2026-09-15"
updated: "2026-09-15"
---

# Phase 34 — Stratégie de validation

> Contrat de validation de la phase : ce qui est échantillonné pendant l'exécution, à quelle
> fréquence, et par quelle commande. Phase **documentaire à une exception** (D-10) : il n'y a pas de
> code applicatif à tester, donc « la suite » est ici l'ensemble des **gates du dépôt** plus, pour
> chaque tâche, une **assertion de contenu falsifiable** sur l'artefact qu'elle produit.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | aucun framework de test applicatif — bash + `node` (assertions de contenu) + les gates du dépôt |
| **Config file** | `.github/workflows/ci.yml`, job `gates` — définition machine de ce qu'il faut rejouer |
| **Quick run command** | `bash scripts/check-version-sync.sh && bash scripts/check-machine-paths.sh` |
| **Full suite command** | rejeu du job `gates` : les 3 étapes `check-agents.sh` (par dossier d'agents, par `AGENT.md`, monde fermé) + `check-version-sync.sh` + `check-state-integrity.sh --file .planning/STATE.md` + `check-capability-activation.sh` + `check-machine-paths.sh` |
| **Estimated runtime** | ~45 secondes pour le rejeu complet du job `gates` ; < 5 s pour la commande rapide |

**Règle d'or de ce dépôt, appliquée ici :** on rejoue les **commandes du job CI**, jamais une liste
de gates recopiée dans un rapport (`check-machine-paths.sh` oublié a déjà fait rougir une PR).

---

## Sampling Rate

- **Après chaque commit de tâche :** la commande `<automated>` de la tâche (assertion de contenu sur
  l'artefact produit) — c'est elle qui peut rendre rouge, pas la relecture.
- **Après chaque vague de plans :** commande rapide (`check-version-sync.sh` + `check-machine-paths.sh`).
- **Avant la clôture de phase :** rejeu complet du job `gates`, vert obligatoire.
- **Latence de retour maximale :** 45 secondes.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 34-01-T1 (tracer) | 01 | 1 | AGTS-02 | T-34-01 / T-34-02 | aucun motif de remise à zéro d'état dans `.maestro` du lab ; prérequis poste absent ⇒ arrêt propre, jamais d'install | assertion de contenu + témoin de mutation | bloc `<automated>` de la tâche 1 de `34-01-PLAN.md` (sections de la note, UDID au format simctl, config projet parsable, `use_worktrees` à `false`, balayage `.maestro`, `detect` qui rend l'UDID) | ✅ (`34-RUN-MOBILE.md` créé par la tâche) | ⬜ pending |
| 34-01-T2 | 01 | 1 | AGTS-02 | T-34-01 / T-34-04 | le verdict EQUIPE exige un dispatch réel tracé ; session authentifiée intacte après le run | assertion de contenu + existence du rapport horodaté | bloc `<automated>` de la tâche 2 (`## Cycles`, `### Cycle `, `## Dispatch`, deux lignes de verdict, rapport nommé existant, balayage `.maestro`) | ✅ | ⬜ pending |
| 34-01-T3 | 01 | 1 | AGTS-02 | T-34-03 | trace publiée sans secret du lab ; report jamais silencieux | assertion de contenu + diff de périmètre | bloc `<automated>` de la tâche 3 (compte du chapeau à 1, cohérence VERT ⇒ deux verdicts VERT, déviations datées, diff scopé contre le SHA de base) | ✅ | ⬜ pending |
| 34-02-T1 (tracer) | 02 | 1 | SKIL-01 | T-34-05 / T-34-08 | la sonde n'écrit que sous des noms préfixés ; l'appareil de mesure est prouvé discriminant | assertion de contenu + contrôle négatif | bloc `<automated>` de la tâche 1 (sections, `SHA de base`, `CONTROLE-NEGATIF:`, noms de sonde, liste de nettoyage, diff scopé sur `plugin`) | ✅ (`34-SPIKE-SKIL.md`) | ⬜ pending |
| 34-02-T2 | 02 | 1 | SKIL-01 | T-34-06 / T-34-07 | nettoyage prouvé chemin par chemin ; le skill jetable ne porte que la sentinelle | assertion de contenu + vérification d'absence sur disque | bloc `<automated>` de la tâche 2 (`## Cas cible A`, `CAS-A:`, sentinelle, `Scope project :`, chaque chemin de `## Nettoyage` absent, ≥ 2 chemins listés) | ✅ | ⬜ pending |
| 34-02-CP | 02 | 1 | SKIL-01 | T-34-08 | verdict one-way pour un NO-GO : jamais auto-sélectionné | `checkpoint:decision` `gate="blocking-human"` | — (arrêt humain, non automatisable par construction) | — | ⬜ pending |
| 34-02-T3 | 02 | 1 | SKIL-01 | T-34-08 | zéro ligne de code d'installeur même sur GO (D-09) | assertion de contenu + cohérence machine verdict/mesures | bloc `<automated>` de la tâche 3 (compte du chapeau à 1, sections obligatoires, traçabilité d'arbitrage, diff scopé, cohérence `CONTROLE-NEGATIF`/verdict) | ✅ | ⬜ pending |
| 34-03-T1 (tracer) | 03 | 1 | AGTS-01 | T-34-09 / T-34-10 | aucun fichier sous `plugin/` ; la matrice est mesurée, pas recopiée | recomptage du dépôt + assertion de contenu | bloc `<automated>` de la tâche 1 (`## Corpus mesuré`, `SHA de base`, en-tête de matrice avec colonne Verdict, ≥ 11 lignes, ligne de corpus recomptée contre `plugin/`) | ✅ (`34-AUDIT-AGTS.md`) | ⬜ pending |
| 34-03-T2 | 03 | 1 | AGTS-01 | T-34-11 | chaque refus nomme la preuve qui manque | égalité de comptes + assertion de contenu | bloc `<automated>` de la tâche 2 (verdicts valides sur chaque ligne, `refuser` == `**Preuve manquante :**`, formule D-02 littérale, `web-test-team` en `reporter`) | ✅ | ⬜ pending |
| 34-03-T3 | 03 | 1 | AGTS-01 | T-34-09 | zéro agent créé, prouvé par diff | égalité de comptes + diff de périmètre | bloc `<automated>` de la tâche 3 (quatre sections, phrase complète du seuil, fan-out nommé, `combler` == items rédigés, diff scopé contre le SHA de base) | ✅ | ⬜ pending |
| 34-04-CP | 04 | 2 | AGTS-02 | T-34-13 | une trace interne ne devient une promesse distribuée que sous décision humaine | `checkpoint:decision` `gate="blocking-human"` | — (arrêt humain, non automatisable par construction) | — | ⬜ pending |
| 34-04-T1 (tracer) | 04 | 2 | AGTS-02 | T-34-13 / T-34-14 / T-34-15 | pas de suppression silencieuse de la réserve ; chaîne de version cohérente | assertion de contenu + gate machine | bloc `<automated>` de la tâche 1 (trois points de version à `v1.0.3`, réserve absente de `module.json` et du README, enregistrement daté + renvoi, entrée CHANGELOG, `check-version-sync.sh`) | ✅ | ⬜ pending |
| 34-04-T2 | 04 | 2 | AGTS-02 | T-34-13 / T-34-14 | limite Android dite ; triplet racine intact | assertion de contenu + deux gates machine | bloc `<automated>` de la tâche 2 (trois points à `v1.4.6`, réserve absente, `Android` nommé, CHANGELOG au format crocheté, `check-version-sync.sh`, `check-agents.sh --strict`, diff du triplet racine) | ✅ | ⬜ pending |
| 34-04-T3 | 04 | 2 | AGTS-02 | T-34-16 | le manuel ne promet pas plus que la mesure | balayage `manual/` en lecture directe (jamais `grep` en pipe) | bloc `<automated>` de la tâche 3 (zéro ligne « module + réserve » sous `manual/`, entrées réécrites non supprimées, `Android` présent, `check-version-sync.sh`) | ✅ | ⬜ pending |
| 34-05-T1 (tracer) | 05 | 3 | AGTS-02 | T-34-17 / T-34-18 / T-34-21 | aucune collision de `name` ; Pattern 12 intact ; densité ADR-029 | gates machine (dont monde fermé) + assertion de frontmatter | bloc `<automated>` de la tâche 1 (`v1.0.0`, `requires: []`, trois `name` renommés, `vf-internal: true` sur les workers, ≤ 250 lignes, `check-agents.sh --strict` par module ET en monde fermé) | ✅ | ⬜ pending |
| 34-05-T2 | 05 | 3 | AGTS-02 | T-34-19 | la rule ne se charge que sur un projet équipé d'un runner e2e | analyse du frontmatter `paths:` + assertion de contenu | bloc `<automated>` de la tâche 2 (quatre fichiers, ligne `**Version**`, renvoi à la trace, entrée CHANGELOG, aucun glob générique — le glob fautif est nommé) | ✅ | ⬜ pending |
| 34-05-T3 | 05 | 3 | AGTS-02 / QUAL-01 | T-34-20 | les compteurs du dépôt disent le parc réel | rejeu complet des gates du job `gates` | bloc `<automated>` de la tâche 3 (entrées de catalogue, `check-version-sync.sh`, `check-machine-paths.sh`, `check-state-integrity.sh --file`, `check-capability-activation.sh`, 3 étapes `check-agents.sh`, diff du triplet racine) | ✅ | ⬜ pending |
| 34-06-T1 (tracer) | 06 | 4 | AGTS-01 / AGTS-02 / SKIL-01 | T-34-22 | le ledger ne devance jamais la preuve | cohérence machine note ↔ ledger | bloc `<automated>` de la tâche 1 (ancre `34-06-BASE.sha`, notes citées, clôture de l'item ⇔ verdict NO-GO, report tracé ⇔ chapeau ROUGE, diff hors `.planning/`) | ✅ | ⬜ pending |
| 34-06-T2 | 06 | 4 | AGTS-01 / AGTS-02 / SKIL-01 | T-34-22 / T-34-26 | case ⇔ verdict ; anti-features intactes | cohérence machine + comparaison contre le SHA d'ancre | bloc `<automated>` de la tâche 2 (état de chaque case contre le chapeau de sa note, renvois nommés, traçabilité plus `Pending`, item `PROJECT.md`, anti-features inchangées) | ✅ | ⬜ pending |
| 34-06-T3 | 06 | 4 | AGTS-01 / AGTS-02 / SKIL-01 | T-34-23 / T-34-24 / T-34-25 | `STATE.md` jamais réécrit par un outil ; arbitrages traçables ; aucun chemin de poste versionné | gates machine + non-régression des compteurs | bloc `<automated>` de la tâche 3 (`check-state-integrity.sh --file`, `check-machine-paths.sh`, aucun compteur en régression contre l'ancre, entrée datée Phase 34, traçabilité d'arbitrage, cases de plans du ROADMAP, trois notes citées) | ✅ | ⬜ pending |

*Status : ⬜ pending · ✅ vert · ❌ rouge · ⚠️ instable*

---

## Wave 0 Requirements

L'infrastructure existante couvre toutes les exigences de la phase : aucun framework à installer,
aucune suite de tests à créer. Les gates du dépôt (`check-agents.sh`, `check-version-sync.sh`,
`check-state-integrity.sh`, `check-capability-activation.sh`, `check-machine-paths.sh`) sont déjà
posés et déjà câblés au job `gates` de la CI. `wave_0_complete: true` pour cette raison.

Deux artefacts de mesure sont néanmoins créés **par les plans eux-mêmes**, en tout début de leur
première tâche, parce qu'aucune vérification de périmètre n'est falsifiable sans eux :

- la ligne `SHA de base : <sha>` dans `34-RUN-MOBILE.md`, `34-SPIKE-SKIL.md` et `34-AUDIT-AGTS.md` ;
- le fichier d'ancre `34-06-BASE.sha` pour le plan de clôture.

---

## Témoins de mutation exigés (« une preuve doit pouvoir rendre rouge »)

Mode de défaut dominant de ce dépôt : un vérificateur incapable d'échouer. Trois témoins sont donc
**exécutés et consignés**, pas seulement prévus :

| Témoin | Plan / tâche | Mutation jouée | Signal attendu |
|---|---|---|---|
| Garde anti-destruction de session | 34-01 / T1 | flow jetable `zz-mutant-garde.yaml` portant un motif de remise à zéro d'état, puis supprimé | balayage propre → rouge → propre, les trois sorties consignées dans `## Témoin de la garde` |
| Contrôle négatif du spike | 34-02 / T1 | invocation d'un nom de skill prouvé absent des trois emplacements | échec de découverte ; un succès force `MESURE INVALIDE` |
| Ligne de corpus de l'audit | 34-03 / T1 | la vérification recompte `plugin/` et compare à la ligne écrite | un agent ajouté ou retiré après l'écriture rend la note rouge |

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|---|---|---|---|
| Le verdict du run correspond à ce qui a été observé, pas à ce qu'on espérait ; aucune cause d'arrêt vague ; aucun secret du lab recopié | AGTS-02 | jugement éditorial sur une trace publiée ; aucune machine ne distingue « précis » de « vague » | `<human-check>` de 34-01 / T3 — relire `34-RUN-MOBILE.md` en entier |
| Le verdict SKIL repose sur la mesure et non sur la documentation ; `## Conséquence ledger` est collable sans réinterprétation | SKIL-01 | jugement sur la qualité d'un raisonnement | `<human-check>` de 34-02 / T3 |
| Pour chaque gap refusé, un lecteur sait ce qui aurait changé le verdict ; le seuil d'ajout au catalogue ne se confond pas avec le fan-out d'exécution | AGTS-01 | lisibilité et absence d'ambiguïté, non mesurables | `<human-check>` de 34-03 / T3 |
| Les blocs `## Limites` disent ce qui est prouvé (iOS) et ce qui ne l'est pas (Android) | AGTS-02 | jugement sur une promesse faite à l'utilisateur | `<human-check>` de 34-04 / T2 et T3 |
| L'entrée de catalogue de `web-test-team` tient la même promesse que son README | AGTS-02 | cohérence éditoriale entre deux documents | `<human-check>` de 34-05 / T3 |
| `stopped_at` et l'entrée `Roadmap Evolution` suffisent à reprendre le projet dans trois mois | — | jugement sur la suffisance d'un résumé | `<human-check>` de 34-06 / T3 |

Ces vérifications sont récoltées en fin de phase (`workflow.human_verify_mode` par défaut =
`end-of-phase`) et consolidées dans `34-UAT.md` — aucune d'elles n'interrompt l'exécution.

---

## Points de vérification humaine bloquants (hors échantillonnage)

Deux `checkpoint:decision` en `gate="blocking-human"` : ils gardent le TRAVAIL, pas la vérification
a posteriori, et ne sont donc jamais auto-sélectionnés, même en mode autonome.

| Checkpoint | Plan | Ce qu'il garde |
|---|---|---|
| Verdict SKIL-01 (GO / NO-GO / MESURE INVALIDE) | 34-02 | un NO-GO est one-way (D-07) : il clôt l'item BACKLOG du 2026-06-04 et maintient l'anti-feature gravée |
| Sortie du statut expérimental (POURSUIVRE / NO-OP TRACÉ) | 34-04 | transforme une trace interne en promesse distribuée, et conditionne la construction de `web-test-team` |
