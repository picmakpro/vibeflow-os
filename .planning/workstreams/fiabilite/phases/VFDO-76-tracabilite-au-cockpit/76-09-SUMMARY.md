---
phase: 76
plan: "09"
requirements: [TRAC-13]
requirements-completed: [TRAC-13]
---

# 76-09 — Questions en attente lues dans la collecte (TRAC-13)

Exécuté le 2026-11-14 sur la branche `feat/phase-76-questions`, après fusion de 73-11 (`dfba4bd4`).

## Livré

- `plugin/cockpit/scripts/vf-cockpit-questions-attente.mjs` (144 lignes) : `lireQuestions` (pure : section `## À Samuel`, têtes `- **P<n>-Q-<nn> — <titre>.**`,
  champs fermés, défauts nommés, doublons sur l'ensemble des fichiers, citation incohérente, appliquées, tri, coupe à 200, arrêt à 2 000, texte passé par `servi`)
  et `projeterQuestions` (pose `meta.vf.questions`, `try`/`catch`, champ absent si aucun registre lu n'a de section).
- `plugin/cockpit/scripts/vf-cockpit-questions-champs.mjs` (58 lignes) : analyse des champs (options, recommandation, bloque, état) et liste fermée `DEFAUTS`.
- `vf-cockpit-trace-collecte.mjs` : un import et un appel dans `projeterTrace` (+2 lignes), la table clé → identifiant de nœud est celle des nœuds de phase.
- `vf-cockpit-interface.json` : `questions` ajouté à `optionnels.metaVf` de `cockpit-project@1` et à sa description ; la version ne monte pas. Liste fermée de
  `test-cockpit-projet-champs.sh` (PC3.2) mise à jour.
- `test-cockpit-questions-attente.sh` (34 assertions) ; compteur de suites des deux README recalé à 246.

## Mesures

- `POIDS-Q octets=22467` (`JSON.stringify` de `meta.vf.questions` du graphe réel du dépôt, mesure sans seuil).
- Corpus réel : `LUS=6` (CONTEXT des Phases 73, 74, 75, 77, 79, 80 portant une section « À Samuel » dans l'arbre fusionné) ; invariant « puces de premier niveau = entrées
  + non structurées » tenu sur les six, aucune puce hors grammaire en attente. `76-CONTEXT.md` : P76-Q-01 et P76-Q-02 `tranchee` (option a), P76-Q-03 `appliquee`
  (option a, décision `P76-D-31`), `nonStructurees` 0 (T13.14).

## Écarts

- Écart : les tâches 1 et 2 du plan sont livrées en un test (tous les cas écrits avant le code, rouge consigné dans `76-09-RED-TRACE.md`) et un code ; les trois
  commits sont : test, module + branchement, contrat + SUMMARY.
- Écart : un second module `vf-cockpit-questions-champs.mjs` (hors `files_modified`) tient l'analyse des champs : le plan l'autorisait au-delà de 250 lignes (« scinder dans un module voisin »).
- Écart : une entrée « mal formée » porte aussi `etat: 'mal-formee'` (la page de la 73 lit `etat === 'mal-formee'`) en plus de `id`, `phase`, `fichier`, `ligne`, `defauts`.
- Écart : les entrées complètes portent `ws` (nom du compartiment ou `null`), comme la forme de C76-Q2 du CONTEXT ; absent de la liste du mandat, sans effet sur la 73 (la page ne le lit pas).
- Écart : `a-verifier` = tous les défauts sont `citation-incoherente` ou `decision-introuvable` ; un mélange avec un autre défaut est `mal-formee` (défauts tous listés).
- Écart : le tri est numérique sur le `<n>` de l'identifiant, puis compartiment, puis identifiant naturel (la page de la 73 retrie de toute façon, P73-D-41).
- Contrat 73 : `meta.vf.questions` relu par `72-vf-regie-questions-lecture.js` (forme, états, `appliquee { option, decision }`, `bloque` plan/phase) : aucun écart de nom ni de forme ;
  aucun fichier de la 73 retouché. Défaut connu chez la 73, pas à la 76 : `00-vibeflow.js` annule le clic sous `[data-vf-section]`.
- Rituels levés : mutants (M-*), preuve générative, triple passe, rejeu des cas sautés en CI — rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).

## Suites jouées une fois sur la tête commitée

| Suite | Verdict | Durée |
|-------|---------|-------|
| test-cockpit-questions-attente.sh | vert (34 passés, 0 échoué) | 21 s |
| test-cockpit-tracabilite-collecte.sh | vert | 32 s |
| test-cockpit-projet-champs.sh (PC3.2 mise à jour) | vert | 6 s |
| test-cockpit-vendor.sh | vert | 123 s |
| test-cockpit-projet-graphe.sh | vert | 715 s |
| test-cockpit-questions.sh | vert | 20 s |
| test-cockpit-confinement.sh | vert | 69 s |
| test-cockpit-graphe.sh, test-cockpit-assemblage.sh, test-cockpit-activite-planning.sh (lisent `cockpit-project@1`) | verts | 54 s, 12 s, 0 s |
| test-cockpit-collecte.sh | C3.4 (latence maximale 150 ms pour un plafond de 100, sous charge) rouge au premier passage ; rejouée seule une fois : 149 passés, 0 échoué | 434 s puis 388 s |
| scripts/check-version-sync.sh | vert (compteur 246) | |

Temps passé dans les suites : environ 1 850 s au total, rejeu compris, sous charge du poste (moyenne de charge de 14 à 35). Chrome : aucune suite de ce plan n'en lance.
test-cockpit-magasin.sh (Chrome, par le jeton) a été jouée au moment de la fusion : 90 passés.

## À verser par la jointure

- C76-Q1 / C76-Q2 tels qu'exécutés : ordre des champs non contrôlé ; `phase: null` quand le dossier n'a pas de nœud ; `etat` présent sur une entrée mal formée ; `ws` sur les entrées complètes.
- Fichiers partagés : `vf-cockpit-trace-collecte.mjs` (un import, un appel), `vf-cockpit-interface.json` (`questions` sous `metaVf`).
