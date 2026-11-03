---
name: bascule-verrou-phase-registre-non-transfere
description: Passer du verrou de compartiment au verrou --phase ne transfère pas le registre d'agents, et check-mission-exit lit encore le compartiment
metadata:
  type: project
---

Le 2026-11-03, pendant l'exécution de la Phase 69, la session principale m'a fait passer du verrou `--ws=fiabilite` au verrou `--ws=fiabilite --phase=69` (verrou par phase, PR #197). Le `release` du compartiment a gardé mes 2 workers vivants dans le registre du compartiment, listés comme `orphans`. Un manager qui aurait pris le compartiment ensuite les aurait arrêtés comme orphelins. En fin de mission, `check-mission-exit.sh` (E1, E7) lisait encore le registre du compartiment : il a signalé un agent d'une AUTRE mission (plancheck-68) comme si c'était le mien.

**Why:** le registre d'agents est rangé par portée de verrou, et la bascule n'est qu'un release suivi d'un acquire, sans aucune migration.

**How to apply:** à toute bascule de portée, réenregistre (`register`) chaque agent `running` sous la nouvelle portée, puis ferme-le (`close`) dans l'ancienne. Vérifie avec `orphans` des deux côtés. Repointe aussi le heartbeat détaché sur la nouvelle portée et le nouveau script. En fin de mission, lis E1 et E7 de `check-mission-exit` comme des artefacts de portée tant que le gate ne connaît pas `--phase`. Voir [[verrou-driver-non-contraignant]].
