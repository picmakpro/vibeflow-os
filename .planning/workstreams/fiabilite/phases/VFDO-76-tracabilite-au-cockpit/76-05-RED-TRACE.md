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
     obtenu:  [1|$WORK/l3/.planning/workstreams/x/phases/01-un/01-01-PLAN.md:1|1|1]
  ❌ FAIL — T11.1c — témoin positif : les réponses portent bien les textes (titre d'ADR, sujet, critère) sans leur chemin
     attendu: [3]
     obtenu:  [0]
  ❌ FAIL — M-ABSOLU — chemins du poste non retirés (copie jetable de trace-texte) : T11.1 rougit, la sonde voit la fuite
     attendu: [fuite]
     obtenu:  [propre]
```

Le reste des FAIL (T10.3h à T10.3j, T10.4a à T10.4e, T11.2a à T11.2k, T11.1c, M-ABSOLU) suit la même forme : obtenu `absent` (vue servie `indisponible`, sans clé de vue). T11.1b : le harnais comptait avec `grep -rcF` (corrigé en `grep -cF` avant le vert). T11.2d à T11.2f : code 0, le lab sans `.planning` ne démarre pas encore (à traiter côté lab, voir SUMMARY si écart).

## Tâche 3 — témoins rouges du contrat, de la garde, du cache et du calcul unique (contre le code de la tâche 2 : ni schéma déclaré, ni garde locale, ni cache, ni borne de test)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-tracabilite-route.sh` ; 61 PASS, 12 FAIL. Assertion, attendu, obtenu :

```
  ❌ FAIL — T10.6 — chaque réponse des sept vues (neuf requêtes) passe le contrat cockpit-trace@1 (requis, optionnels, états, sous-formes, interdits)
     attendu: [OK (vue=jalon)]
     obtenu:  [KO schéma absent (vue=jalon)]
  ❌ FAIL — T10.7a — vue piégée (clé corps ajoutée) : 503 emission-refusee ; témoin positif : la vue normale rend 200
     attendu: [503|emission-refusee|200]
     obtenu:  [200|absent|200]
  ❌ FAIL — T10.7b — contrat illisible (copie sans vf-cockpit-interface.json) : 503 emission-refusee, jamais une réponse
     attendu: [503|emission-refusee]
     obtenu:  [200|undefined]
  ❌ FAIL — T10.8a — deux requêtes simultanées après une modification de docs/ADR.md : un seul calcul (+K, jamais +2K), les deux servent le nouveau titre
     attendu: [true]
     obtenu:  [false]
  ❌ FAIL — T10.8b — une troisième requête identique : aucun appel git (aucun rev-parse par requête)
     attendu: [true]
     obtenu:  [false]
  ❌ FAIL — T10.8e — titre d'ADR modifié sans commit : nouveau titre servi (date de docs/ADR.md), +K
     attendu: [true]
     obtenu:  [false]
  ❌ FAIL — T10.8g — fichier ajouté sous .planning/ sans changement de seq : aucun recalcul
     attendu: [true]
     obtenu:  [false]
  ❌ FAIL — M-VOL — partage du calcul retiré : T10.8a rougit — le mutant ne rougit pas (obtenu = nominal [true,true,false,false,true,true,false,true,false,true])
  ❌ FAIL — M-EMPREINTE — empreinte réduite à seq (sans les dates) : T10.8 rougit — le mutant ne rougit pas (obtenu = nominal [true,true,false,false,true,true,false,true,false,true])
  ❌ FAIL — M-SIG — git.sig retirée de l'empreinte : T10.8d rougit — le mutant ne rougit pas (obtenu = nominal [true,true,false,false,true,true,false,true,false,true])
  ❌ FAIL — M-EMPREINTE-PLANNING — parcours des dates de .planning/ ajouté à l'empreinte : la dernière assertion de T10.8 rougit — le mutant ne rougit pas (obtenu = nominal [true,true,false,false,true,true,false,true,false,true])
=== T10.9 — borne des commits citants (lab L9, cinq commits citants) ===
  ❌ FAIL — T10.9 — borne abaissée à 2 : bornes.tronque vrai (deux commits servis) ; borne normale : faux (cinq commits)
     attendu: [true|2 false|5]
     obtenu:  [false|5 false|5]
```

Les quatre mutants de cache (M-VOL, M-EMPREINTE, M-SIG, M-EMPREINTE-PLANNING) ne rougissent pas encore : leur ancre (`enVol`, `const parties = [`) n'existe pas dans le code de la tâche 2 (« ancre introuvable »). Le harnais mesure K = 8 appels git par calcul sur le code naïf (aucun cache) ; T10.8a, T10.8b, T10.8g rouges (chaque requête relance git). M-GARDE, M-CLE, M-NUE-RELIEE-EXIG, M-CONFINE : leur sonde nominale est atteinte, le mutant a un effet une fois la garde posée (voir le vert).
