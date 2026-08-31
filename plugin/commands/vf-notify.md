---
description: "Active/désactive/vérifie/teste les notifications OS natives de mission (toast macOS/Windows/Linux, opt-in OFF par défaut)."
argument-hint: "[on|off|status|test]"
---

Invoque le skill **`vf-notify`** (toggle notifications OS de mission) : $ARGUMENTS

Le skill gère le fichier-sentinelle qui arme/désarme l'émission OS native de `notify.sh` aux
jalons `done`/`failed` d'une mission — **opt-in, OFF par défaut** (D-33-H). `test` envoie une
notification réelle sans jamais muter l'état persistant du toggle, et prévient au préalable du
piège `user_present` (aucun toast visible si l'utilisateur reste actif au terminal).

Si le module `conductor` n'est pas installé, lance d'abord `vibeflow-install`.
