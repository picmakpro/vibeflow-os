# 70-06 — trace rouge (P70-D-08)

Date : 2026-11-04 — commit de départ 0f01d442 (code applicatif d'avant, témoins ajoutés seuls).
Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-questions.sh` -> 57 PASS / 8 FAIL (Q1 à Q12 et Q11 inchangées, vertes).

| Assertion | Attendu | Obtenu |
|---|---|---|
| Q15.2 | aucun « ? » en valeur ni virgule orpheline | « Dernière phase :  · , le ?. » |
| Q15.3 | « pas de STATE.md » dit | absent |
| Q15.4 | pas de titre « À finir » sur liste vide | titre « À finir dans le jalon : » suivi de rien |
| Q16.1 | aucun statut brut dans la réponse locale | `ready_to_execute` brut |
| Q16.2 | « prêt à exécuter » | absent |
| Q16.3 | sous-titre du graphe en français | « Jalon j1 · phase 1 · ready_to_execute. » |
| Q16.4 | statut inconnu omis | affiché brut |
| Q17.1 | tables serveur et navigateur de mêmes clés | `STATUTS` non exporté (table vide) |

Réponse obtenue de Q15 en entier (lab sans STATE.md, question « Où en est-on ? ») :

```
Jalon en cours : non reconnu. Dernière phase :  · , le ?.

À finir dans le jalon :
```
