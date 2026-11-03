---
created: 2026-11-01
source: spike 003 (cockpit-floorplan-live), note 2026-11-01-cockpit-facettes
priority: moyenne — correctif réel hors cockpit, à valider avant (ADR-031)
---

# Écriture atomique dans `dag.sh` `save()`

`save()` fait `open(file, "w")` puis `json.dump` : un lecteur concurrent (cockpit, vf-signal,
`who.mjs`, tout outil qui lit les DAG) peut lire un JSON tronqué. Reproduit au spike 003 : une
mission « disparaît » (32 cartes) le temps de l'écriture. Correctif proposé : écrire dans un
fichier temporaire du même dossier puis `os.replace`. L'hystérésis du sidecar reste en défense.
Prévoir un témoin rouge (lecture pendant une écriture lente) avant le correctif.
