# 78-06 — traces des rouges (tiroir Git de la page)

Reprise après crash (2026-11-05) : `temoins/git-tiroir.json` laissé par le prédécesseur a été relu contre `vibeflow/cockpit-git@1` servi (`vf-cockpit-interface.json`, 78-05) : toutes les clés requises de la réponse et de chaque rangée y sont (le champ `suite`, issu de `placer`, n'est pas servi : le témoin le porte en trop, le rendu ne le lit pas). Gardé tel quel.
Un brouillon de `77-vf-git-rendu.js` a été écrit par erreur AVANT le témoin ; il a été déplacé hors dépôt (scratchpad `78-06-brouillon/`) avant tout rouge, et n'a servi qu'ensuite (même geste que 78-02).

## Tâche 1 — D1 (tiroir ouvert depuis la seconde ligne, schéma vérifié)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-git-tiroir.sh`
Assertions : D1.0 à D1.2 et D1.x (clic sur `#vf-git-ligne` -> `aside#vf-git-tiroir` visible avec 40 rangées ; GET avec jeton ; schéma refusé -> carte indisponible).
Attendu : tout vert. Obtenu (état sans fichier 77) : `scénario interrompu : attente de « tiroir ouvert avec ses rangées » dépassée (25000 ms)` — la page se rend, la seconde ligne existe (l'attente précédente est passée), le clic n'ouvre rien ; 8 échoués, 1 réussi (H0 hygiène). Raison correcte : aucun tiroir.
