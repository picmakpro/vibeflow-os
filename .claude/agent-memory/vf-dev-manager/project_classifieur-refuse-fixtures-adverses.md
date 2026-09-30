---
name: classifieur-refuse-fixtures-adverses
description: Le classifieur du mode auto refuse (« Instruction Poisoning ») la lecture de blocs de tests à fixtures adverses de ce dépôt — un plan qui doit réécrire ces tests se bloque ; décision humaine, jamais un contournement
metadata:
  type: project
---

Phase 45 (2026-09-30) : l'exécuteur de 45-02 a été refusé par le classifieur de permissions du
mode auto, motif « Instruction Poisoning », sur `sed -n 2830,3010p
plugin/planning-core/scripts/tests/test-recalc-planning.sh` (cas R-LABS-ADVERSES,
R-CODE2-MIGRATION, écrits en Phase 44 avec du contenu adverse). Le plan exigeait de réécrire ce
bloc : toute la chaîne 45-04 → 45-10 s'est trouvée gelée derrière.

**Why:** un refus du classifieur est une décision de permission. Le faire relire par un autre agent,
ou par le manager, ou sous une autre forme de commande, serait du blanchiment de permission. Le
worker ne l'a pas contourné — correct — et seul l'humain peut lever le verrou.

**How to apply:** au plan-check d'une phase qui réécrit des tests adverses (injection, labs
hostiles), prévoir le refus : faire autoriser la lecture par l'humain AVANT l'exécution, ou
séquencer ce plan en premier. Au refus, escalader tout de suite (options : autorisation, geste
humain, report) et faire avancer les nœuds indépendants pendant l'attente. Voir
[[escalade-sendmessage-attendre-la-vraie-reponse]].
