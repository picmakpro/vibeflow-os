---
name: attendre-un-worker-sleep-bloque
description: `sleep` nu est bloqué dans le Bash du manager — une boucle `until … sleep` tourne à vide et rend instantanément ; attendre par `python3 -c 'import time; time.sleep(N)'`
metadata:
  type: project
---

Dans le Bash du manager, un `sleep` en avant-plan est refusé. Résultat : une boucle `until <cond> || [ $i -ge 55 ]; do sleep 10; …; done` épuise ses 55 tours en une seconde et rend comme si l'attente avait abouti. Constaté le 2026-10-02 (mission manuel, PR #132). `python3 -c 'import time; time.sleep(420)'` avec un `timeout` d'outil suffisant fonctionne, et permet de battre le cœur du verrou entre deux attentes.

**Why:** une attente qui rend immédiatement ressemble à une condition remplie. On lit alors un état intermédiaire comme final.

**How to apply:** attendre un worker ou un rejeu détaché par `python3 … time.sleep`, en tranches inférieures au `timeout` de l'outil, avec un heartbeat du verrou à chaque tranche. Imposer la même consigne aux workers qui suivent un rejeu long. Voir [[rejeu-long-detache-nohup]], [[verrou-driver-non-contraignant]].
