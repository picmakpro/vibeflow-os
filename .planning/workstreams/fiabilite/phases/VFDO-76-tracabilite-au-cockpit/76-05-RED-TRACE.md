BASE=3c587121bc8c103bf28198b37a9d874a3e43c498

## Tâche 1 — témoin rouge de la route (suite lancée contre la base, route absente)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-tracabilite-route.sh` (serveur réel du lab L1, première collecte attendue 20 s).

```
  ✅ PASS — T10.0 — témoin : le serveur écoute (port et jeton lus)
  ❌ FAIL — T10.1 — jalon : 200, schema cockpit-trace@1, etat ok, phases ph-1 et ph-2 avec leur clé
     attendu: [200|vibeflow/cockpit-trace@1|ok|ph-1,ph-2]
     obtenu:  [404|corps-illisible]
  ✅ PASS — T10.2a — sans jeton : 403
  ✅ PASS — T10.2b — POST avec jeton : 405
  ✅ PASS — T10.2c — témoin positif : le même accès sur une route inconnue donne 404 (le 403 de T10.2a vient de l'absence de jeton)
```

T10.2a et T10.2b passent dès la base (témoins du chemin des contrôles communs, attendu par le plan) ; T10.1 est le rouge.
