---
phase: 79
plan: "04"
requirements-completed: [SOCL-05]
commits: [2d37307c, 5f7cfe5a, 627c6cd1, 3ae10e13, 3919655e]
---

# 79-04 — Nœud dans le mandat, plan de mission publié (SOCL-05)

## Fait

- **Gabarit du digest** (`mission-contracts.md`) : ligne `- Nœud : <id du nœud DAG>` (accents graves) juste après `- Mission :`, et
  paragraphe « Nœud du mandat » (valeur = identifiant rendu par `dag.sh add`, même que `register --node` ; forme lue par
  `citationsDuMandat` ; fenêtre de 8 000 caractères ; limite du remap `id::étape`). Bloc de digest à 10 lignes (≤ 30).
- **Kernel** (`team-kernel.md`) : section « Nœud dans le mandat, plan de mission publié (Phase 79, SOCL-05) » ; ligne « Verrou de
  driver » alignée sur les treize verbes de `--help` (`mark-progress`, `registry`, `publish-plan` ajoutés ; aucune autre ligne de la
  table n'a changé).
- **Verbe de publication relevé** : `publish-plan`, forme d'appel `publish-plan --owner=<id> --file=<DAG de mission>
  [--ws=<sujet> [--phase=<N>]|--depot]` (identique à 79-03-SUMMARY, aucune différence à consigner).
- **Bloc T46** de `test-dev-orchestrator.sh` : 11 assertions (a1 à a5 dont le témoin de couverture, b1 à b4, c) et 31 mutants (13 de
  la partie a, 18 de la partie b) = 42 lignes vertes ; suite complète 490 OK / 0 KO / 0 SKIP ; `test-fin-de-mandat.sh` 56 ok / 0 ko.
  Aucune suite neuve, compteur de suites des README racine inchangé. Traces rouges et traces des mutants : `79-04-RED-TRACE.md`.
- **Versions** : `conductor` v1.54.1 (patch, partant de la v1.54.0 de 79-03), `dev-orchestrator` v2.32.0 (minor) ; VERSION,
  module.json, en-tête du README, section de CHANGELOG alignés ; `check-version-sync.sh`, `check-machine-paths.sh`,
  `check-ajout-retrait.sh --ci` verts. Aucun bump racine, aucun tag.

## Limites

- Remap : un identifiant `id::étape` (champ `remapped` vrai) est hors du motif du cockpit et n'est jamais rattaché par la citation
  du mandat (le registre le porte tel quel) ; mesuré par un vrai `dag.sh add` (a4), écrit au contrat. Élargir le motif du cockpit
  serait un changement de code de ce module, hors plan.
- La pose de la ligne et la publication du plan par un manager ne sont prouvées que par le texte et par l'aller-retour du gabarit
  avec le lecteur réel, jamais par une mission réelle. Les managers d'autres métiers ne l'ont que par la règle du kernel (leurs
  corps d'agent ne sont pas modifiables ici, budget d'instructions armé).
- Écart d'outillage : exécution inline (le garde d'isolation refuse `gsd-executor` hors worktree séparé, constat de 79-03).
- Écart d'ordre : la doctrine du kernel a été rédigée avant le commit des témoins de la partie b ; le rouge de la partie b a été
  constaté en rejouant les témoins contre le kernel de base (copie restaurée depuis HEAD, puis la doctrine remise), trace dans
  `79-04-RED-TRACE.md`.

Retiré : rien (doctrine de forme sans instruction ajoutée à un agent ; aucun fichier, aucune règle, aucune ligne existante supprimé).
