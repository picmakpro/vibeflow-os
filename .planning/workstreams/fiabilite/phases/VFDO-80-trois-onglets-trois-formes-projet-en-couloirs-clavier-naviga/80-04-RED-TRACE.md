# 80-04 — RED-TRACE (P80-D-25)

Trace du rouge sur la base `integration/cockpit-audit` (tête de la vague 1, `chrome-session.mjs` inchangé, aucun fichier `41-vf-projet-*`).
Les chemins du poste sont remplacés par `<tmp>`.

## Tâche 1 : CL1 (3 PASS / 4 FAIL)

Suite : `test-cockpit-couloirs.sh`, lab de 6 phases (2 faites, 1 en cours, 1 à recetter, 2 à faire), un jalon clos, backlog de 2 entrées, une graine.
Raison du rouge : la page se charge (CL0 vert, canevas rendu), la vue n'existe pas. Le fixture n'est pas mort : CL1.2 (témoin) rend `visible`, des cartes de canevas.

| Cas | Attendu | Obtenu | Raison |
|---|---|---|---|
| CL1.1 | `[4,"hidden",true]` | `[0,"visible",false]` | aucun couloir, canevas visible |
| CL1.2 | `["visible",true,true]` | PASS (témoin) | `?vue=graphe` : canevas, pas de section |
| CL1.3 | `[true,"n:ph-1"]` | section absente (le clic échoue : aucune carte `.vp-carte[data-id="n:ph-1"]`) | aucune carte de couloir |
| CL1.4 | `[["?vue=graphe","#s=x"],["?vue=couloirs","#s=x"]]` | `[["","#s=x"],["?vue=couloirs","#s=x"]]` | `naviguer` n'ajoute pas `vue=graphe` |
| CL1.9 | `[]` | `[cl13]` | la section cl13 a échoué (cause : CL1.3) |
