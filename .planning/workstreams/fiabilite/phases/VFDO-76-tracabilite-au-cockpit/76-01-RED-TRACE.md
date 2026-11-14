# 76-01 — Témoins rouges (joués avant le code)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-tracabilite-chaine.sh` (régime allégé : pas de mutant, le témoin rouge est le seul témoin exigé).

## Tâche 1 — chaîne d'une exigence (T1.1, T1.2)

Les modules `vf-cockpit-trace-*.mjs` n'existent pas encore : le harnais attrape l'échec d'import et imprime `{"erreur":"module-absent"}`,
`assert_eq` rend « obtenu : absent » (échec d'assertion, pas plantage de la suite).

```
=== T1 — une exigence de bout en bout ===
  ❌ FAIL — T1.1 REQ-01 : mot de ligne = manque VERIFICATION (rien n'existe au-delà du SUMMARY) — attendu: [verification/manque] obtenu: [absent]
  ❌ FAIL — T1.1b REQ-01 : plan lu au niveau exigence — attendu: [lu/exigence] obtenu: [absent]
  ❌ FAIL — T1.1c REQ-01 : SUMMARY lu au niveau exigence (requirements-completed scalaire) — attendu: [lu/exigence] obtenu: [absent]
  ❌ FAIL — T1.1d REQ-01 : VERIFICATION et recette manquent — attendu: [manque/- manque/-] obtenu: [absent absent]
  ❌ FAIL — T1.2 REQ-02 : VERIFICATION citée dans la table, lue au niveau exigence (témoin positif voisin) — attendu: [lu/exigence] obtenu: [absent]

Résultats : 0 passés, 5 échoués
```

## Tâche 2 — maillons, contradictions, mentions, citations (T2.1 à T2.8)

Rejoué contre les modules de l'état de la tâche 1 (commit `5bc10acd`, extraits par `git archive` dans un dossier jetable) avec la suite corrigée : la première capture, faite
avec un harnais dont le compteur de fichiers de sortie ne survivait pas à la substitution de commande (les lectures se recouvraient), avait 23 rouges ; la capture ci-dessous est
la bonne (19 rouges, tous des échecs d'assertion `attendu` / `obtenu`, aucun plantage). Les sections déjà vertes (T2.4 reste(), T2.6 lecture seule, témoins positifs) sont des gardes de
non-régression, vertes avant et après par construction.

```
  ❌ FAIL — T2.1 REQ-03 : SUMMARY lu par requirements: (liste) — attendu: [lu/exigence] obtenu: [manque/-]
  ❌ FAIL — T2.1 REQ-10 : SUMMARY apparié sans frontmatter = non lisible, jamais manque — attendu: [non-lisible/-] obtenu: [manque/-]
  ❌ FAIL — T2.1 REQ-11 : frontmatter sans champ d'exigence = non lisible — attendu: [non-lisible/-] obtenu: [manque/-]
  ❌ FAIL — T2.2 REQ-16 : VERIFICATION sans frontmatter = non lisible — attendu: [non-lisible/-] obtenu: [lu/exigence]
  ❌ FAIL — T2.3 REQ-17 : recette qui cite l'identifiant = lu, niveau exigence — attendu: [lu/exigence] obtenu: [manque/-]
  ❌ FAIL — T2.3 REQ-18 : recette qui ne le cite pas = lu, niveau phase (témoin voisin) — attendu: [lu/phase] obtenu: [manque/-]
  ❌ FAIL — T2.3 recette de la phase 4 : faite, statut lu — attendu: [true/true] obtenu: [absent]
  ❌ FAIL — T2.3 REQ-19 : 05-RECETTE-JUGES.md sans ligne **Statut : = non lisible — attendu: [non-lisible/-] obtenu: [manque/-]
  ❌ FAIL — T2.4 ligneStatutRecette et recetteFaite exportées par avancement — attendu: [2] obtenu: [0]
  ❌ FAIL — T2.5 REQ-05 : cochée, plan citant, aucun SUMMARY = maillon SUMMARY en contradiction — attendu: [contradiction/- summary/contradiction] obtenu: [manque/- summary/manque]
  ❌ FAIL — T2.5 REQ-05 : le mot porte le code cochee-sans-summary — attendu: [cochee-sans-summary] obtenu: [absent]
  ❌ FAIL — T2.5 REQ-06 : Complete sans plan = maillon plan en contradiction, code complete-sans-plan — attendu: [contradiction/- complete-sans-plan] obtenu: [manque/- absent]
  ❌ FAIL — T2.5 REQ-07 : non cochée avec SUMMARY lu = mention neutre — attendu: [["non-cochee-summary-lu"]] obtenu: [[]]
  ❌ FAIL — T2.5 REQ-08 : rattachée par un PLAN seulement = mention sans-ligne-tracabilite — attendu: [["sans-ligne-tracabilite"] plan] obtenu: [[] plan]
  ❌ FAIL — T2.7 REQ-21 : premier maillon non lu = plan (manque) ; la contradiction du SUMMARY passe en contradictions — attendu: [plan/manque ["cochee-sans-summary"]] obtenu: [plan/manque []]
  ❌ FAIL — T2.7 REQ-22 : quatre maillons lus = chaîne complète (mot null) — attendu: [aucun] obtenu: [summary/manque]
  ❌ FAIL — T2.7 REQ-23 : chaîne complète, niveauPhase liste VERIFICATION et recette — attendu: [aucun ["verification","recette"]] obtenu: [summary/manque ["verification"]]
  ❌ FAIL — T2.8 REQ-30 : cites = préfixée, ADR, nue — attendu: [{"decisions":["P90-D-01"],"adrs":["ADR-001"],"nues":["D-04"]}] obtenu: [{"decisions":[],"adrs":[],"nues":[]}]
  ❌ FAIL — T2.8 décision non définie : reste une citation lue ; D-04 n'est jamais dans decisions — attendu: [["P95-D-09"] false] obtenu: [[] false]
Résultats : 24 passés, 19 échoués
```

## Tâche 3 — preuves, critères, bilans, jalon, « Étape N » (T3.1 à T3.6)

État après la tâche 2. Échecs d assertion (attendu / obtenu) ; les sondes négatives (aucun corps, aucune clé interdite) sont vertes à vide tant que rien n est produit, leurs témoins positifs sont dans la même section.

```
  ❌ FAIL — T3.1 cinq preuves en chemins relatifs au lab, sorte exacte, statut lu, plan de la trace rouge — attendu: [["verification|.planning/workstreams/x/phases/01-un/01-VERIFICATION.md||passed","recette|.planning/workstreams/x/phases/01-un/01-RECETTE-HUMAINE.md||FAITE — close le 2026-11-05.","trace-rouge|.planning/workstreams/x/phases/01-un/01-01-RED-TRACE.md|01-01|","securite|.planning/workstr
  ❌ FAIL — T3.2 critères : 4 comptés, guillemets retirés, le plus long coupé au mot à 200 au plus — attendu: [4|premier critère|deuxième critère sans guillemets|true|true] obtenu: [absent]
  ❌ FAIL — T3.2 critères : au plus 30 listés, le nombre est compté — attendu: [40/30] obtenu: [absent]
  ❌ FAIL — T3.2 valeurImbriquee et listeImbriquee ; frontmatter de 10 000 lignes rendu en moins d'une seconde sans exception — attendu: [project|a,b|null|null|true] obtenu: [absent]
  ❌ FAIL — T3.3 bilan exclusif : une exigence par catégorie, dans l'ordre contradiction, manque, non lisible, complète — attendu: [{"total":4,"contradiction":1,"manque":1,"nonLisible":1,"complete":1}] obtenu: [null]
  ❌ FAIL — T3.3 la somme des catégories égale le total — attendu: [true] obtenu: [absent]
  ❌ FAIL — T3.3 exigences triées : contradiction, manque, non lisible, complète (le ledger les liste à l'envers) — attendu: [REQ-41,REQ-42,REQ-43,REQ-44] obtenu: [REQ-44,REQ-43,REQ-42,REQ-41]
  ❌ FAIL — T3.4 jalon v1 : trois phases (id et cle), la phase du jalon v2 n'y est pas — attendu: [ph-1/x|1,ph-2/x|2,ph-3/x|3] obtenu: [absent]
  ❌ FAIL — T3.4 bilan de jalon exclusif par phase (pire exigence) plus sansExigence, somme = 3 — attendu: [{"total":3,"contradiction":1,"manque":1,"nonLisible":0,"sansExigence":1,"complete":0}] obtenu: [absent]
  ❌ FAIL — T3.4 maillonsEnDefaut phase 1 : un maillon en contradiction n'est pas compté manque — attendu: [{"plan":0,"summary":3,"verification":0,"recette":0,"manquants":1,"nonLisibles":1,"contradictions":1}] obtenu: [absent]
  ❌ FAIL — T3.4 maillonsEnDefaut phase 2 : comptes par maillon avec chevauchement — attendu: [{"plan":0,"summary":1,"verification":2,"recette":2,"manquants":5,"nonLisibles":0,"contradictions":0}] obtenu: [absent]
  ❌ FAIL — T3.4 exigencesEnContradiction compte des exigences ; lignesSansExigence vient de la phase — attendu: [1,0,0/0,0,2] obtenu: [absent]
  ❌ FAIL — T3.5 dépôt réel : vue de jalon non vide, la somme du bilan égale le nombre de phases — attendu: [true] obtenu: [absent]
  ❌ FAIL — T3.6 « Étape 1 » désigne un dossier existant : rattachement etape, phase 1 — attendu: [etape/1/false] obtenu: [plan/1/false]
  ❌ FAIL — T3.6 « Étape 7 » sans dossier : ni phase ni rattachement, statut Fait lu — attendu: [null/null/true] obtenu: [null/null/false]
  ❌ FAIL — T3.6 lignes Étape lues et sans dossier comptées — attendu: [{"lues":2,"sansDossier":1}] obtenu: [null]
Résultats : 50 passés, 16 échoués
```
