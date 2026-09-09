---
name: pointeur-workstream-partage-par-les-sous-agents
description: Tous les sous-agents d'une session Claude Code héritent du CLAUDE_CODE_SESSION_ID du parent — donc UN SEUL pointeur de workstream pour toute l'équipe ; le dernier `workstream.set` gagne pour tout le monde
metadata:
  type: project
---

Mesuré le 2026-09-09 (gsd-core 1.13.0, cadrage Phase 39), par exécution : un sous-agent lancé
depuis une session rend **exactement le même `CLAUDE_CODE_SESSION_ID`** que son parent, avec
`CLAUDE_CODE_CHILD_SESSION=1` en plus.

Or le pointeur de workstream vit **hors du dépôt**, indexé par chemin ET par identité de session :
`os.tmpdir()/gsd-workstream-sessions/<sha1(realpath(<cwd>/.planning)).slice(0,16)>/<sessionKey>`
(`~/.claude/gsd-core/bin/lib/active-workstream-store.cjs:104-126`). L'identité vient de
`getWorkstreamSessionKey` (`:87-103`), qui parcourt 13 clés d'environnement dont
`GSD_SESSION_KEY` en **première** position (`:22`).

**Conséquence pour le modèle d'équipe VibeFlow** : un manager qui dispatche des workers — même sur
des worktrees différents — leur fait tous partager **son** pointeur. Le dernier `workstream.set`
gagne pour l'équipe entière. La collision avec ADR-064 (« un écrivain = un worktree ») est donc
**refermée entre deux sessions Claude distinctes** et **ouverte à l'intérieur d'une équipe**.

Deux régimes mesurés, selon que le worktree porte ou non son propre `.planning/` commité
(`gsd-tools.cjs:4567-4586` rebase le cwd sur la racine du worktree principal quand il ne le porte
pas) : `.planning/` commité → projectId distinct par arbre, isolation parfaite même à clé de
session identique ; `.planning/` non commité (le cas de vibeflow-os) → projectId unique, et deux
worktrees à même clé de session **s'écrasent** (`set alpha` puis `set beta` : les deux relisent
`beta`, l'un route sur le mauvais compartiment). Avec des clés distinctes, isolation préservée
dans les deux régimes.

**Why:** c'est le facteur discriminant réel — **la clé de session, pas le worktree**. Un plan
d'adoption qui raisonne « un worktree = un scope » est faux par construction dans une mission
d'équipe, et le symptôme (un worker qui lit le planning d'un autre compartiment) ne ressemble pas
à une erreur de scope : il ressemble à un planning vide ou à un fichier manquant.

**How to apply:** dans toute mission sur un dépôt partitionné, **ne jamais s'appuyer sur
`workstream.set`** pour scoper des workers. Deux gestes sûrs, cumulables : passer `--ws <nom>`
explicitement sur chaque appel `gsd_run` (le drapeau est **global** — parsé au point d'entrée
unique `gsd-tools.cjs:4733-4738` et reprojeté en `GSD_WORKSTREAM`, donc **toute** sous-commande
l'accepte, formes `--ws X` et `--ws=X`), ou exporter un `GSD_SESSION_KEY` distinct par mandat.

Deux pièges de diagnostic mesurés au même endroit, qui feront perdre du temps sinon :
- **`workstream.get` n'est PAS un oracle de résolution** : il lit le store seul et **ignore**
  `--ws` et `GSD_WORKSTREAM` (`workstream.cjs:346-350`). Mesuré : `workstream.get --ws default`
  rend `alpha` pendant que `phases.list --ws default` route correctement. Vérifier le scope sur une
  commande qui **route** (`phases.list`), jamais sur celle qui **rapporte**.
- **`--ws <nom-inexistant>` n'erreure jamais** (`:415-417` ne valide que le format) : une faute de
  frappe rend `{"directories":[],"count":0}` en **exit 0**. Un planning vide est un symptôme de
  typo autant que d'absence — cf. [[timeout-absent-faux-zero]], même famille de faux zéro.

Voir [[mesurer-le-moteur-gsd-corpus-hors-depot]] (le corpus se mesure hors dépôt) et
[[descripteur-gsd-core-non-probant]] (un descripteur amont n'est jamais une preuve — ici le niveau 4
du pointeur, lui, a bien été confirmé par exécution).
