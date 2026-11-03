# 69-03 — Mesure de la forme des sous-agents Claude Code (P69-PL-16)

Date : 2026-11-03. Lecture seule de `~/.claude/projects`, aucun contenu lu ni écrit (mandat, description, chemin) : seulement des noms de clés, des types et des effectifs.
Version de Claude Code : 2.1.317 (`claude --version` ; les premières lignes de transcript des candidats portent `version` 2.1.316 pour 45 d'entre elles et 2.1.317 pour 21).

Population : 1 006 `agent-*.meta.json` sur le poste ; **66 candidats de la fenêtre** (le `.jsonl` voisin modifié il y a moins de 86 400 s), 940 hors fenêtre (jamais comptés dans `requis`). Forme arrêtée `{agentType, stoppedByUser}` dans la fenêtre : 0. La précondition (au moins 20 candidats) est tenue : la mesure s'appuie sur le poste, pas sur R5.1.

## Présence des clés de `meta.json`, par profondeur (candidats de la fenêtre, n/N)

| Clé | `spawnDepth` = 1 (N = 14) | `spawnDepth` >= 2 (N = 52) | Type |
|-----|---------------------------|----------------------------|------|
| `agentType` | 14/14 | 52/52 | string |
| `description` | 14/14 | 52/52 | string |
| `spawnDepth` | 14/14 | 52/52 | number |
| `toolUseId` | 14/14 | 52/52 | string |
| `requestShape` | 14/14 | 52/52 | string |
| `parentAgentId` | 0/14 (absent par construction) | 52/52 | string |
| `finished` | 12/14 | 50/52 | boolean (toujours `true` quand présent) |
| `isBuiltIn` | 14/14 | 52/52 | boolean |
| `launchedWithDefaults` | 14/14 | 48/52 | boolean |
| `requestNonInteractive` | 14/14 | 52/52 | boolean |

- Valeurs de `requestShape` : `background` pour 66/66.
- `parentAgentId` désigne un agent du même dossier de sous-agents : 52/52 (à `spawnDepth` >= 2). Aucun candidat n'a de `spawnDepth` >= 2 sans `parentAgentId`.
- Aucune base vide (N = 0) : tous les effectifs sont >= 14. Aucun écart avec R5.1 : aucune question pour Samuel.

## Première ligne du transcript voisin (66 candidats, lecture bornée à 256 Kio)

| Clé | Présence | Détail |
|-----|----------|--------|
| `isSidechain` | 66/66 | booléen 66/66, `true` 66/66 |
| `agentId` | 66/66 | égal à l'identifiant du fichier 66/66 |

## Conclusion — listes de forme retenues

- `metaSousAgent.requis` = `agentType`, `description`, `spawnDepth`, `toolUseId`, `requestShape` (100 % des deux profondeurs, N >= 14).
- `metaSousAgent.requisSiProfondeur` = `{ "parentAgentId": 2 }` (52/52, N = 52).
- `metaSousAgent.booleensFacultatifs` = `["finished"]` (présent à 62/66, booléen chaque fois qu'il l'est : un type autre sort l'agent de l'arbre).
- `isBuiltIn`, `launchedWithDefaults`, `requestNonInteractive` ne sont pas lues par le cockpit : hors `requis` (un champ non lu ne casse rien en disparaissant).
- `transcriptSousAgent.requis` = `isSidechain`, `agentId` (66/66).
- `verifieSur` = 2.1.317.

## Informatif — ce que la fenêtre écarte (jamais une entrée de `requis`)

Effectif par ensemble de clés de `meta.json` sur tout l'historique (1 006 fichiers, fenêtre comprise), 6 ensembles les plus fréquents :

| Effectif | Ensemble de clés |
|----------|------------------|
| 217 | agentType, description, parentAgentId, requestNonInteractive, requestShape, spawnDepth, toolUseId |
| 164 | agentType, description, finished, isBuiltIn, launchedWithDefaults, parentAgentId, requestNonInteractive, requestShape, spawnDepth, toolUseId |
| 121 | agentType, description, requestNonInteractive, requestShape, spawnDepth, toolUseId |
| 82 | agentType, description, finished, isBuiltIn, launchedWithDefaults, requestNonInteractive, requestShape, spawnDepth, toolUseId |
| 51 | agentType, description, finished, launchedWithDefaults, parentAgentId, requestNonInteractive, requestShape, spawnDepth, toolUseId |
| 48 | agentType, description, inheritedWorktreePath, parentAgentId, requestNonInteractive, requestShape, spawnDepth, spawnedWithWorktree, toolUseId |

L'historique varie (clés `model`, `pickedEffortModel`, worktree, absence de `finished`), mais ces variations portent sur des clés non lues ; les cinq clés de `requis` y sont présentes dans les ensembles les plus fréquents. La clé `stoppedByUser` figure dans 5 fichiers de l'historique, tous hors fenêtre (0 candidat de forme arrêtée) : si elle réapparaît dans la fenêtre, c'est un agent `termine` (forme arrêtée), jamais une forme inconnue.
