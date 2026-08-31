---
name: pushnotification-absent-en-sous-agent
description: PushNotification existe dans le harness mais n'est jamais monté en sous-agent — aucun manager/worker ne peut pousser, le relais SendMessage(main) est le seul vecteur
metadata:
  type: project
---

`PushNotification` **existe** dans le harness Claude Code (`shouldDefer: true`) mais **n'est pas
fourni aux sous-agents**. Erreur littérale à l'appel réel : « No such tool available:
PushNotification. PushNotification is disabled for this session, in subagents as well as here. »
Ce n'est pas un bannissement explicite (absent de `ALL_AGENT_DISALLOWED_TOOLS`), c'est un
non-montage dans le pool. Et **ce n'est pas un problème de réglage** : mesuré alors que toute la
config de Samuel était déjà ON (`tengu_kairos_push_notifications`, `agentPushNotifEnabled`,
`remoteControlAtStartup`).

**Why:** mesuré le 2026-08-17 pendant le cadrage de la mission « notifications » (annexe Phase 33),
dont le brief supposait que les managers pousseraient les jalons vers l'app Claude. La prémisse
était fausse : `vf-dev-manager`, `vf-coder` et `dag.sh` sont tous des sous-agents. Un plan bâti
dessus aurait échoué en exécution. C'est le décalque exact de [[askuserquestion-absent-en-subagent]]
— déclaré au frontmatter, absent au runtime.

**How to apply:** ne jamais câbler un push dans `dag.sh`, dans un agent ou dans un étage
`ship:post` (qui dispatche lui aussi un sous-agent). Le seul vecteur est le relais déjà éprouvé
ici : le manager fait `SendMessage(main)` avec une ligne prête, **la session principale** émet.
Contrat à respecter si on l'utilise : un seul champ `message` < 200 caractères, sans markdown,
**pas de `title`** — la signature `notify.sh <TITLE> <BODY>` ne mappe pas 1:1. L'outil ne lève
jamais d'erreur : il rend toujours un succès porteur d'un `disabledReason`
(`config_off` / `user_present` / `no_transport`), et « push *requested* » n'est jamais « delivered »
— ne bâtis aucun contrôle de flux qui attend un accusé. Enfin `user_present` supprime toute
émission quand l'utilisateur est au terminal : toute recette manuelle est trompeuse tant qu'il
regarde l'écran.
