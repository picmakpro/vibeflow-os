---
name: decision-ids-phase-local-not-global
description: Les identifiants D-NN de la doctrine dev-orchestrator (vibeflow-os) sont locaux à chaque phase/plan et RÉUTILISÉS d'une phase à l'autre — une collision de label brut n'est pas un bug en soi
metadata:
  type: project
---

Dans `plugin/dev-orchestrator/`, les identifiants de décision `D-NN` (ex. `D-06`, `D-09`) sont
mintés **par phase/plan**, pas dans un registre global unique. Constaté en Phase 23 (revue-05,
étape 23-05, 2026-08-04) : `D-09` désigne au moins trois décisions différentes selon le contexte —
(1) le repli « `AskUserQuestion` peut ne pas être fourni en sous-agent » de `vf-dev-manager.md`
§Entrée (miné en Phase 20, commit `d549b2d`) ; (2) « voie unique d'invocation des briques de cycle »
de `GSD-PIPELINE.md` §9 (miné en Phase 23, `23-CONTEXT.md`) ; (3) une référence au chaînage MCP
`--migrate-engine` dans les commentaires `T2h` du fichier de tests (`D-06/D-09`, phase antérieure à
19-02). Les trois cohabitent dans le même fichier de tests / la même toile de renvois croisés.

**Why:** ce n'est PAS un défaut introduit par un diff donné — c'est une convention établie et
tolérée dans tout l'historique du module (`T2g`/`T2h` en portent d'autres exemples bien antérieurs
à la Phase 23). Chaque occurrence est en général désambiguïsée PAR LE CONTEXTE IMMÉDIAT (nom de
fichier + section citée juste à côté, ex. « repli D-09 du manager (§Entrée) » vs « voie unique
d'invocation (D-09) » de `GSD-PIPELINE.md` §9) — un lecteur qui suit le renvoi complet (fichier +
section) ne se trompe pas, même si le token nu `D-09` seul est ambigu hors contexte.

**How to apply:** en revue (priorité 6 des mandats de revue, cohérence doctrinale des renvois
croisés), ne pas remonter une collision de label `D-NN` brut comme un finding majeur/bloquant tant
que (a) chaque occurrence porte sa propre qualification contextuelle suffisante (fichier + section)
et (b) aucune assertion d'ÉQUIVALENCE ou de GARANTIE fausse n'est bâtie dessus. Signaler seulement
en mineur/suggestion si un nouveau texte livré (ex. un Pattern de `mission-flow.md`) rapproche deux
significations différentes du même token dans un espace de quelques lignes SANS qualification —
c'est le seul cas où l'adjacence peut réellement induire en erreur. Voir [[mirror-gate-superset-drift]]
pour la famille voisine (dérive par sur-ensemble plutôt que par réutilisation de label).
