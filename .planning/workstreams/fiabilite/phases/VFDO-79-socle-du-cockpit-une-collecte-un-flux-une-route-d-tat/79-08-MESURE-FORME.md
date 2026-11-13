# 79-08 — Mesure de la forme des transcripts Claude Code lus par l'index (P79-D-30, SOCL-12)

Date : 2026-11-11. Lecture seule de `~/.claude/projects`, aucun contenu lu ni écrit (texte, entrée ou sortie d'outil, chemin, identifiant) : seulement des noms de clés, des types et des effectifs. Script de mesure jetable, hors du dépôt.
Version de Claude Code : 2.1.322

Précondition (au moins 20 transcripts modifiés depuis moins de 24 h, `claude --version` de forme N.N.N) : tenue.

## Population (transcripts modifiés depuis moins de 24 h)

367 fichiers : 16 sessions, 351 sous-agents. Lignes par `type` : `user` 23 720, `assistant` 37 920, `system` 354 ; le reste (`attachment`, `api-request*`, `queue-operation`, `last-prompt`, `mode`, `permission-mode`, `session-owner`, `pr-link`, `frame-link`, `ai-title`, `custom-title`, `file-history-*`, etc.) ne porte aucune mesure. Lignes JSON illisibles : 0.

## Présence des champs candidats (n/N, type)

| Champ | Sorte de ligne | n/N | Type |
|-------|----------------|-----|------|
| `type` | toutes | 100 % | string |
| `timestamp` | `user` | 23 720/23 720 | string, lisible (ms) 23 720 |
| `timestamp` | `assistant` | 37 920/37 920 | string, lisible (ms) 37 920 |
| `version` | `user` et `assistant` | 61 640/61 640 | string (voir comptes par version) |
| `message.id` | `assistant` | 37 920/37 920 | string |
| `message.usage.input_tokens` | `assistant` | 37 920/37 920 | number |
| `message.usage.output_tokens` | `assistant` | 37 920/37 920 | number |
| `message.usage.cache_read_input_tokens` | `assistant` | 37 920/37 920 | number |
| `message.usage.cache_creation_input_tokens` | `assistant` | 37 920/37 920 | number |
| `message.model` | `assistant` | 37 920/37 920 | string |
| `message.stop_reason` | `assistant` | 37 920/37 920 | string (jamais null ni absent) |
| `message.content` | `assistant` | 37 920/37 920 | array |
| `id` d'un bloc `tool_use` | `assistant` | 22 649/22 649 | string |
| `name` d'un bloc `tool_use` | `assistant` | 22 649/22 649 | string |
| `tool_use_id` d'un bloc `tool_result` | `user` | 22 642/22 642 | string |
| `is_error` d'un bloc `tool_result` | `user` | 16 369/22 642 | boolean |
| `subtype` | `system` | 354/354 | string |
| `pendingBackgroundAgentCount` | `system` `turn_duration` | 104/154 | number |
| `origin.kind` | `user` | 528/23 720 | string |
| `permissionDecision.decision` | `user` | 22 567/23 720 | string |

Comptes par valeur : `origin.kind` : `peer` 279, `task-notification` 147, `human` 80, `coordinator` 22 ; `permissionDecision.decision` : `accept` 22 556, `reject` 11 ; `subtype` : `stop_hook_summary` 161, `turn_duration` 154, `away_summary` 16, `informational` 7, `local_command` 6, `compact_boundary` 8, `bridge_status` 2. Part des tours dont `turn_duration` porte `pendingBackgroundAgentCount` supérieur à 0 : 104/154.

## Comptes par version vue (lignes `user` et `assistant`)

2.1.322 : 61 452 · 2.1.321 : 84 · 2.1.318 : 104. Aucune ligne sans `version`.

## Contiguïté des lignes d'un même `message.id`

Messages (un `message.id` par message) : 19 870 ; à plusieurs lignes : 14 857 (75 %).

- Messages à plusieurs lignes dont une autre ligne datée s'intercale entre la première et la dernière : **2 040 sur 14 857 (13,7 %)**. Écart avec l'hypothèse du plan (« moins de 1 % »).
- Nature de ce qui s'intercale (seconde passe, lignes datées seulement, 14 876 messages à plusieurs lignes, les sessions vivantes ayant grossi) : une ligne `user` (résultat d'outil rendu pendant que le message se poursuit) dans 2 043 messages ; une ligne `assistant` d'un autre `message.id` : **0** ; un `message.id` qui réapparaît après un autre `message.id` (suite A, B, A) : **0**.
- Parmi les lignes d'un même message : `output_tokens` jamais décroissant (0 cas) ; `input_tokens`, `cache_read_input_tokens` et `cache_creation_input_tokens` identiques sur toutes les lignes (0 cas de différence).

## `stop_reason`

Dernière ligne de chaque message : `tool_use` 19 018, `end_turn` 822, `stop_sequence` 30. Lignes précédentes du même message : `tool_use` 17 719, `end_turn` 331. Chaque ligne porte donc un `stop_reason` chaîne (le plan supposait « nul » sur les lignes non finales de sa fixture : forme synthétique, sans effet sur la règle R7, la dernière ligne l'emporte).

## Conclusion — listes de forme retenues (sous réserve de la décision sur la contiguïté)

- `requis` : `type` ; `timestamp` des lignes `user` et `assistant` ; `message.id`, `message.usage.input_tokens`, `message.usage.output_tokens` des lignes `assistant` ; `id` et `name` d'un bloc `tool_use` ; `tool_use_id` d'un bloc `tool_result` (100 % de leurs lignes).
- `facultatifs` : `message.usage.cache_read_input_tokens`, `message.usage.cache_creation_input_tokens`, `message.model`, `message.stop_reason` (100 % ce jour, mais hors du plancher du plan : un champ qui manquerait ne doit pas rendre la voie inconnue), `is_error`, `subtype`, `pendingBackgroundAgentCount`, `origin.kind`, `permissionDecision.decision`, `version`.
- Condition d'arrêt de la tâche 1 : le critère écrit (« au moins 1 % des messages à plusieurs lignes ont des lignes non contiguës ») est atteint à la lettre (13,7 %) ; ce qui s'intercale n'est que des lignes `user`, jamais une ligne `assistant` d'un autre message : le dédoublonnage par `dernierMsgId` (R3, qui ne se met à jour que sur les lignes `assistant`) n'est pas contredit. La tâche s'est arrêtée ici, l'écart est remonté au manager avant toute écriture de code.
