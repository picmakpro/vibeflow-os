---
name: sonde-claude-p-home-temporaire-sans-auth
description: `claude -p` sous HOME=$(mktemp -d) rend "Not logged in" — une sonde runtime hors HOME réel exige un jeton dédié (CLAUDE_CODE_OAUTH_TOKEN) fourni par l'humain, jamais copié
metadata:
  type: project
---

Une sonde qui lance `claude -p` (mesure du chargement de contexte d'un sous-agent, D-19 Phase 42) ne
s'authentifie pas sous `HOME=$(mktemp -d)`, même avec un `CLAUDE_CONFIG_DIR` jetable : rc=1,
`"Not logged in · Please run /login"` (Claude Code 2.1.282, 2026-09-24). Le poste n'expose ni
`ANTHROPIC_API_KEY` ni `CLAUDE_CODE_OAUTH_TOKEN`.

**Why:** la première sonde D-19 avait tourné avec le HOME réel de Willy sans que personne le note :
son contexte incluait peut-être `~/.claude/CLAUDE.md` et ses plugins. La seconde, mandatée « HOME
temporaire », a buté sur l'auth. Deux sondes au protocole différent sans que ce soit consigné.

**How to apply:** avant de mandater une sonde `claude -p` isolée, prévoir le jeton : l'humain lance
`claude setup-token` et dépose le jeton hors dépôt (choix de Willy, AskUserQuestion, session
principale, 2026-09-24 : `~/.vf-sonde-token`, chmod 600), puis
`HOME=$(mktemp -d) CLAUDE_CODE_OAUTH_TOKEN="$(cat ~/.vf-sonde-token)"`. Le jeton ne passe jamais par
le chat, une sortie, un fichier versionné ni un commit. Jamais de copie d'identifiants du HOME réel
par un worker. Consigner le HOME utilisé dans les limites de toute mesure. Voir
[[re-mesurer-la-premisse-d-un-arbitrage]].
