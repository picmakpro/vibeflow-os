# Phase 59 — Registre du planificateur (P59-PL-NN)

Décisions prises par le planificateur (conséquences de P59-D-01..23, aucune n'ouvre un choix neuf). Écrit le 2026-10-27.
Plan-checker : aucun BLOCKER, aucun WARNING, 3 INFO (preuve de mutation de 59-01 par `diff`, ordre commit/verify en 59-02 et 59-05, 59-04 à 5 tâches).
Gate de couverture des décisions (`check.decision-coverage-plan`) : `could-not-parse` (le parseur ne lit pas l'ID préfixé `P59-D-NN`) ; couverture vérifiée à la main : P59-D-01..23 et PRDT-01..12 cités dans au moins un plan.

| ID | Décision | Rationale | Plans |
|----|----------|-----------|-------|
| P59-PL-01 | Le bundle choisit le gabarit (le PM le lit par cascade) ; `vf-role.sh get` n'est qu'un avis ; `SKILL.md` et `PROFILES.md` de planning-core intacts | `vf-planning` route un lab GSD actif en Séquence B, où un sélecteur par poste serait mort | 01, 04, 05 |
| P59-PL-02 | Rubric /100 = 20/20/25/15/20 (BRIEF, exigences, critères, priorités, traçabilité) ; verdict JSON `statut/score/eliminatoire/detail/check_prd/findings` ; code 1 ⇒ éliminatoire, codes 3/5 ⇒ human_needed | Le poids va à l'éliminatoire principal ; seuil commun 80 | 04 |
| P59-PL-03 | `test-build-module-catalog.sh` non modifié ; preuve positive dans PTB-CATALOG ; pas de `Gate-Touche` | Mesure : 14 OK / 0 KO ; hors des six classes G-2 | 06, 08 |
| P59-PL-04 | `check-prd.sh --requirements/--brief`, aucun chemin par défaut, codes 0/1/3/5/64 (jamais 2), priorité 5>1>3>0, contenu jamais réimprimé, borne 1 Mio, aucune ligne citant `.planning/` et REQUIREMENTS ⇒ pas de recensement, conductor non bumpé | Convention Phase 58 ; lab partitionné | 02, 08 |
| P59-PL-05 | « Forme exec » = appel en arguments séparés, code de sortie non masqué, sans hook ; trois issues + mutation | ADR-071 vise les hooks (hypothèse A1) ; réversible | 02, 04 |
| P59-PL-06 | Deux suites séparées (gate à mutants / composition) ; +2 suites comptées par `find` | Sépare mutants et composition | 02, 06 |
| P59-PL-07 | Fixtures générées à l'exécution, aucun dossier `fixtures/` versionné | Octets CRLF/BOM exacts ; suite autonome à plat | 02 |
| P59-PL-08 | Le manager résout les chemins une fois (BRIEF racine ; PROJECT/REQUIREMENTS sous `.planning/` ou dans le compartiment nommé par `ws`) ; lab partitionné sans `ws` ⇒ une question | Même discipline que driver-lock | 04, 08 |
| P59-PL-09 | Trailers `Ajout-Retrait` à trois segments, un par chemin | La formule de P59-D-11 seule est `MARQUEUR-MAL-FORME` | 02, 05, 08 |
| P59-PL-10 | Head : référence `product-routing.md` + 1 pointeur + 1 ligne de carte + 1 ligne de Références ; cible 33 instructions ; repli ≤36 seulement sous la citation exacte | 0 instruction mesurée | 03 |
| P59-PL-11 | Test T44 dans `test-dev-orchestrator.sh` (présence, ordre, contenu, mutants `t414_*`, variables `*TMP*`) | Une redirection prouvée par présence seule ne peut pas rougir | 03 |
| P59-PL-12 | `test-module-roles.sh` adapté en 59-04 (table `PRODS`, cas MR-PRODUIT) ; pas de `Gate-Touche` | Aucune vague rouge ; hors G-2 | 04 |
| P59-PL-13 | Compteurs des README racine en 59-06, pas 59-07 | Évite une course sur `find` | 06, 07 |
| P59-PL-14 | Gabarit BRIEF en 59-05 ; `prd-gate` avec le manager en 59-04 | Monde fermé vert seulement si les cibles existent | 04, 05 |
| P59-PL-15 | Registre de baselines tenu par 59-06 seul ; états rouges intermédiaires nommés (version-sync, SANS-BASELINE) | Un seul propriétaire du fichier partagé | 01–06 |
| P59-PL-16 | README du bundle : `**Version** : v1.0.0` | Comme business-pilot-bundle ; version-sync | 05 |
| P59-PL-17 | Périmètre planning-core = 2 gabarits + `version` + VERSION + CHANGELOG + README ; identité à l'octet prouvée en 59-01, rejouée en 59-08 | Ne pas interdire les évolutions futures | 01, 06, 08 |
| P59-PL-18 | Forme `PRD-NN` + `Acceptation :` + `Priorité :` {must, should, could} ; critère mécanique = présent, ≥10 caractères, hors crochets/TBD/TODO | Le script tranche l'absence, le juge la testabilité | 01, 02 |
| P59-PL-19 | `vf-product-pm` reçoit `Edit` ; retirer une exigence ⇒ human_needed | Sur un lab GSD, PROJECT et REQUIREMENTS existent déjà | 04 |
| P59-PL-20 | Front door : geste simple produit en session puis passé à `check-prd.sh` ; mission ⇒ propose `Task(vf-product-manager)` | Jamais de vert auto-déclaré | 05 |
| P59-PL-21 | Porte = `replay-ci-jobs.sh --job gates` (`--list` d'abord), suites une à une sous alarme 600 s, liste blanche du diff, ledger à la main | « liste de gates ≠ référence » | 08 |
| P59-PL-22 | Poste illisible côté head (codes 1/5/64) ⇒ une phrase bruyante + une question, jamais de repli silencieux sur solo | P58-D-15 | 03 |
