---
name: transcripts-survivent-au-clear
description: Après un /clear, les rapports de sous-agents et les réponses relayées survivent dans ~/.claude/projects/<projet>/<session>/subagents/*.jsonl — les relire avant de rejouer une recherche, mais faire reconfirmer tout arbitrage relu
metadata:
  type: project
---

Un `/clear` de la session principale efface le contexte du manager, pas les transcriptions. Chaque
sous-agent laisse `agent-<id>.jsonl` + `.meta.json` (type, description, parent, profondeur) sous
`~/.claude/projects/<chemin-encodé>/<session_id>/subagents/`. Constaté le 2026-09-29 (Phase 45) : le
nœud `recherche-hooks` était `done` sans rien sur disque ; les deux rapports complets (~340k jetons
de recherche) ET le message de la session principale relayant les réponses de Willy ont été
retrouvés en filtrant les `.meta.json` du jour puis en extrayant `SubagentHandback`/`SendMessage`
par un script Python.

**Why:** le mandat de reprise disait « contexte perdu, rejoue la recherche, repose les questions ».
Rejouer aurait coûté ~340k jetons et un second aller-retour humain pour rien.

**How to apply:** à toute reprise après `/clear` ou coupure, chercher la session précédente
(`driver-lock.sh reclaim` rend `session_ids`) et relire ses transcriptions AVANT de redispatcher.
Reporter les rapports sur disque (fichier de phase) pour que le planificateur lise le disque. Mais
un arbitrage humain relu dans une transcription n'est pas une validation du jour : présenter les
réponses retrouvées et demander une **reconfirmation** (une seule question), citée avec la mention
« (reconfirmation après /clear) ». Voir [[relire-le-disque-avant-tout-rapport]].
