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

### RK.1 constaté rouge (ligne de table posée, chemin pas encore dans la liste de RK.1)

```
  ❌ FAIL — RK.1 — les chemins de ROUTES égalent la liste écrite à la main (doing, etat, events, journal, modeles, state, transcript) ; ...
     attendu: [ok]
     obtenu:  [ko]      (chemin /api/vf/tracabilite présent dans ROUTES, absent de la liste)
  ❌ FAIL — RK.7 — ... témoin de couverture : toutes les routes sondées
     attendu: [aucun-echec|7|7]
     obtenu:  [aucun-echec|8|8]
```
(RK.7 : le compte de routes sondées passe de 7 à 8, aucun échec de sonde.) Les mutants M-LITTERAL, M-HISTORIQUE-NEUF, M-ORDRE rougissaient aussi pour la même raison (RK.1 hors liste).

## Tâche 2 — témoins rouges des vues, des chemins servis et des dégradations (contre le code de la tâche 1, vues autres que jalon absentes)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-tracabilite-route.sh` ; 12 PASS (témoins), 31 FAIL. Extraits (assertion, attendu, obtenu) :

```
  ❌ FAIL — T10.3a — phase ph-1 : exigences (REQ-01 avec sa clé), bilan, preuves
     attendu: [200|REQ-01:REQ-01|1|true|ph-1]
     obtenu:  [200|absent]
  ❌ FAIL — T10.3b — exigence REQ-01 : quatre maillons (plan et SUMMARY lus, VERIFICATION et recette manquantes) et ses sources
     attendu: [plan,summary,verification,recette|lu,lu,manque,manque|1|.planning/workstreams/x/REQUIREMENTS.md]
     obtenu:  [absent]
  ❌ FAIL — T10.3c — adr sans clé : adrs (clé ouvrable) et registres (phases 90 et 91)
     attendu: [ADR-001:ADR-001,ADR-002:ADR-002|ph-90,ph-91]
     obtenu:  [absent]
  ❌ FAIL — T10.3d — adr ADR-001 : sa décision citée et son commit citant (h7, jour, sujet)
     attendu: [P90-D-01:ph-90|1|true|2026-01-15|feat: met en oeuvre P90-D-01 et ADR-001]
     obtenu:  [absent]
  ❌ FAIL — T10.3e — décision préfixée : phase ph-90, ADR citée, un commit
     attendu: [ph-90|ADR-001|1|false]
     obtenu:  [absent]
  ❌ FAIL — T10.3f — décision nue : commits [] et nue true (jamais reliée, ADR-075)
     attendu: [[]|true]
     obtenu:  [absent]
  ❌ FAIL — T10.3g — memoire : agents et compteurs (huit clés de P76-D-23 et P77)
     attendu: [vf-auditer,vf-coder|agents,cheminsAbsents,entrees,entreesCitantAbsent,horsIndex,liensCasses,resolusParNom,sansEntrant]
     obtenu:  [absent]
  ❌ FAIL — T10.3h — compteurs de L2 : trois entrées, deux agents, b.md hors index, un lien cassé
     attendu: [3,2,1,1]
     obtenu:  [absent]
  ❌ FAIL — T10.3i — memoire de l'agent vf-coder : ses entrées avec leur clé
     attendu: [vf-coder/a.md,vf-coder/b.md]
     obtenu:  [absent]
  ❌ FAIL — T10.3j — fiche de l'entrée a.md : name, type, lien résolu, lien cassé, chemin relatif
     attendu: [a-nom|project|b-nom=resolu+nulle-part=casse|.claude/agent-memory/vf-coder/a.md]
     obtenu:  [absent]
  ❌ FAIL — T10.4b — identifiant préfixé seul et unique : 200, clé canonique rendue
     attendu: [200|ok|P90-D-01:ph-90]
     obtenu:  [200|absent]
  ❌ FAIL — T10.4c — identifiant défini dans deux registres sans :ph-… : 400 cle-ambigue, jamais un choix
     attendu: [400|cle-ambigue]
     obtenu:  [200|absent]
  ❌ FAIL — T10.4d — témoin positif : le même identifiant qualifié par sa phase : 200
     attendu: [200|ph-91]
     obtenu:  [200|absent]
  ❌ FAIL — T11.1b — témoin positif : les quatre chaînes sont bien dans les fichiers et messages du lab
     attendu: [1|1|1|1]
     obtenu:  [1|/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/a219f2f3-5094-402a-a8ad-667ce3f18b1a/scratchpad/exec-76/tmp/76-05/tmp.Iwvj6joD05/l3/.planning/workstreams/x/phases/01-un/01-01-PLAN.md:1|1|1]
  ❌ FAIL — T11.1c — témoin positif : les réponses portent bien les textes (titre d'ADR, sujet, critère) sans leur chemin
     attendu: [3]
     obtenu:  [0]
  ❌ FAIL — M-ABSOLU — chemins du poste non retirés (copie jetable de trace-texte) : T11.1 rougit, la sonde voit la fuite
     attendu: [fuite]
     obtenu:  [propre]
```

Le reste des FAIL (T10.3h à T10.3j, T10.4a à T10.4e, T11.2a à T11.2k, T11.1c, M-ABSOLU) suit la même forme : obtenu `absent` (vue servie `indisponible`, sans clé de vue). T11.1b : le harnais comptait avec `grep -rcF` (corrigé en `grep -cF` avant le vert). T11.2d à T11.2f : code 0, le lab sans `.planning` ne démarre pas encore (à traiter côté lab, voir SUMMARY si écart).
