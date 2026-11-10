---
name: reprise-apres-crash-transcripts
description: Après un redémarrage, le scratchpad /private/tmp est vidé mais les transcripts des sous-agents morts survivent sous ~/.claude/projects/ ; où reconstituer mandats et maquettes perdus
metadata:
  type: reference
---

Le scratchpad des sessions (`/private/tmp/claude-501/<projet>/<session>/scratchpad/`) est effacé au redémarrage de macOS : maquettes, captures « avant », sondes et page démo d'une mission design disparaissent (constaté à la reprise de la Phase 71.5, 2026-11-05).

Les transcripts survivent : `~/.claude/projects/-Users-samuel-Documents-dev-vibeflow-os/<session-id>/subagents/agent-<id>.jsonl`, un par sous-agent, avec le premier message utilisateur (le mandat mot pour mot), les entrées des outils (`Write`, heredocs `cat > f <<EOF` dans `Bash`) et les sorties (`cat`, `sed -n` d'un fichier lu). Le `agent_id` du registre `driver-lock.sh orphans` donne directement le nom du fichier.

**Why:** reprendre un lot interrompu sans recommencer exige de savoir ce qu'il devait faire et où il en était ; le mandat, les derniers rouges de suite et la maquette de référence s'y retrouvent.

**How to apply:** à toute reprise après crash, extraire le mandat et les ~15 derniers résultats d'outil de chaque enfant fantôme avant de redispatcher ; reconstituer les fichiers de référence depuis les résultats de lecture, les copier dans le scratchpad de la nouvelle session et le dire au codeur (référence de balisage, pas programme à relancer). Voir aussi [[sessions-concurrentes-verifier-le-lock]].
