# Mission — Phase 77, cadrage et planification (2026-11-11)

**Verdict : cadrée, planifiée, puis revalidée.** 8 plans en 6 vagues (77-05 scindé en 77-05 et 77-08), 10
exigences `SYNT-01..10`, 36 décisions `P77-D-01..36` (toutes déléguées par Samuel, message session principale,
2026-11-08, option recommandée), deux questions au format C76-Q1 (`P77-Q-01`, `P77-Q-02`, appliquées par délégation).
Plans revalidés contre la Phase 79 à `cce6ed3f` (77-01, 77-02, 77-04), `677d19fa` et `e0336732` (77-03, A54) et `c19c7461` (77-05 à 77-08), et
contre la Phase 74 à `33bb4aad` ; vérification fraîche finale : voir « Preuves E6 ». Rien n'est exécuté.

- Compartiment `fiabilite`, jalon `vibeflow-v2.0`, mode autonome, design auto.
- Branche `feat/phase-77-sante-synthese`, base `origin/integration/cockpit-audit` `f763b556`.
- Verrou de phase `--ws fiabilite --phase 77`.
- Mission lancée par la session principale à la demande de Samuel (session principale Claude Code, 2026-11-11 : cadrer
  et planifier en parallèle toutes les phases de l'audit du cockpit).

## Plan de bataille (DAG)

```
scout-code ─┐
            ├─► panel (3 angles) ─► cadrage (manager) ─► plan (vf-coder) ─► plancheck (frais) ─► sortie
scout-sources┘
```

| Nœud | Exécutant | Résultat |
|---|---|---|
| `scout-code` | éclaireur en lecture seule | faits du cockpit : emplacements, persistance, avancement, gabarits partagés |
| `scout-sources` | éclaireur en lecture seule | faits sur les gates, le burn-up et le coût. Premier lancement refusé (limite de 20 sous-agents simultanés), relancé 150 s plus tard |
| `panel` | 3 chercheurs de décision en parallèle | dernière visite (A, stockage local par lab) ; source des jauges (A, sortie TSV des gates) ; placement, burn-up et retrait (B, a, R1) |
| `cadrage` | manager | `77-CONTEXT.md`, P77-D-01..18, puis amendé en P77-D-19..27 au fil des contrats de la Phase 79 et de la recherche |
| `plan` | `vf-coder` | `77-UI-SPEC.md`, `77-RESEARCH.md`, `77-PATTERNS.md`, `77-VALIDATION.md`, 7 plans. Premier passage bloqué par la limite de sous-agents, repris par SendMessage |
| `plancheck` | vérificateur de plans frais | `passed` : 0 bloquant, 2 FLAG mineurs. Correction ciblée par `vf-coder`, diff relu par le manager |
| `sortie` | manager | ROADMAP (corps de la section), ledger, rapport, PR |

## Décisions

Le registre complet est dans `77-CONTEXT.md`. Les décisions structurantes :

- **Placement (P77-D-01).** Un bouton « Synthèse » sur Projet ouvre le panneau en place, sur le patron de la Santé du
  code et à la place du bouton Santé masqué. Le code va dans un fichier `ui/` neuf ; `ui/00-vibeflow.js` et
  `ui/20-health.js` ne sont pas touchés.
- **Jauges (P77-D-03 à D-06, D-20, D-23).** Les gates gagnent une sortie `--format=tsv` en lecture seule ; la route
  `GET /api/vf/methode` les appelle à la demande. Bornes : cache de 60 s, un seul lancement en cours, échéance de 10 s,
  lancement asynchrone. « Non applicable » ou « indisponible », jamais 0.
- **Dernière visite (P77-D-07 à D-11, D-21, D-22).** Stockage local du navigateur sous la clé
  `vibeflow-cockpit:derniere-visite:<lab>`, la clé `visite:` étant déjà prise par la visite guidée. Contenu sur liste
  fermée, 8 Ko au plus. Rotation après 30 min d'absence ; geste « Tout vu ». Commits arrivés = `tete..sommet` de la
  branche de base.
- **Burn-up (P77-D-13, D-14).** Dates prises dans la checklist du ROADMAP (8 clôtures sur 8, 16 inscriptions sur 16),
  jamais la date d'un commit (fausse pour 5 phases sur 8). Le pourcentage strict vient de la fonction du pied de jalon.
- **Retrait (P77-D-12, D-26).** La prose `lastDesc` sous « Maintenant ».
- **Coût (P77-D-15, D-16).** Calculé à partir de la frise de la Phase 79, sur 24 h, sans monnaie. Une voie non
  rattachée est dite comme telle. Plan à part (77-07), à revalider.
- **Séquencement (P77-D-17, D-19, D-25).** Les plans du cockpit passent après la première vague de la 79 et dépendent
  de `VF_COQUILLE.surOnglet`.

Contrats de la Phase 79 intégrés au fil de la mission. Tous viennent de `feat/phase-79-socle-cockpit`, fichier
`79-CONTEXT.md`, relayés par la session principale :

| Commit | Contenu |
|---|---|
| `3119d82a` | C0 à C6 |
| `2ae6607a` | A8, A10 à A14 ; A10, A11 et A14 répondent aux trois manques remontés par la 77 |
| `74501bb0` | A30 |
| `e04c43e7` | A31, A32 |

## Revalidation (reprise du 2026-11-11, après le rendu de 15 h)

Mandat de la session principale : revalider les sept plans contre les contrats de la Phase 79 arrivés après le rendu
(A34 à A53, puis les plans 79-15 à 79-22), juger s'il fallait scinder 77-05, et refaire une vérification fraîche.
Aucune réponse de Samuel ne change la phase.

- **Vérifications de départ, en parallèle :** une contre la tête de la 79 (8 bloquants, 9 réserves), une de 77-07
  contre la frise et l'agrégat de la 74 (4 bloquants, 7 réserves), une analyse de scission. Verdict : scinder.
- **Décisions P77-D-28 à P77-D-36.** Les principales :
  - chiffre principal « Jetons, hors cache » ;
  - ligne « Hors jalon » ;
  - scission de 77-05 en 77-05 et 77-08, sans renumérotation (130 occurrences, identifiants de menace de même forme) ;
  - route en ligne de `ROUTES` avec dépendance dure sur 79-05 ;
  - sources et minorant du coût ;
  - compteur de suites remesuré ;
  - ce que la 79 change sous les pieds ;
  - cause `echec` pour des métadonnées git hors du lab ;
  - témoin de classe sur le canal réel de la route.
- **Section « À Samuel »** réécrite au format C76-Q1 de la Phase 76 : `P77-Q-01` et `P77-Q-02`, appliquées par
  délégation.
- **Corrections par deux `vf-coder` en parallèle**, sur des fichiers disjoints, en cinq passes ciblées entrecoupées de
  vérifications fraîches :
  - témoin aveugle de 77-03 remplacé par un journal des sous-commandes git sur le canal réel (P77-D-36) ;
  - agrégat de la 74 lu là où 74-01 le publie (`window.__vfFriseCalculs`) ;
  - `tronque` avec `voiesOmises` à 0 : nombre inconnu, jamais « 0 voie omise » ;
  - garde `AVANT` chaînée par `&&` partout, après un vert à vide mesuré sous bash et sous zsh ;
  - A51 (`surOnglet` avec `cle`) et A52 (ordre alphabétique) intégrés.
- **Coupure à 15 h 33** (quota du compte, HTTP 429). Les deux correcteurs ont été arrêtés net. À la reprise : rien
  écrit sous un mauvais nom, deux commits locaux poussés d'abord, agents fermés « stopped » puis repris par SendMessage
  avec leur contexte. Ensuite, commit et push à chaque étape.
- **Correction de la session principale sur A34** (la route va dans `vf-cockpit-server.mjs`, pas dans
  `vf-cockpit-routes.mjs`) : rien à défaire, les plans le disaient déjà.

## À Samuel (non bloquant, aussi dans `77-CONTEXT.md`, format C76-Q1 de la Phase 76)

- **P77-Q-01 (ancien A77-1) — coût par phase au-delà de 24 h** (reprend S-2 de la Phase 79). Options : (a) garder la
  fenêtre de 24 h ; (b) un agrégat persisté par phase, étage et modèle au-delà de 24 h, qui rouvre AUDC-Q2. État :
  appliquée, option (a), P77-D-15. Bloque : 77-07.
- **P77-Q-02 (ancien A77-2) — retrait de la prose « Maintenant »** (P77-D-12). Options : (a) retirer `lastDesc` ;
  (b) retirer le trio de compteurs ; (c) ne rien retirer. État : appliquée, option (a), P77-D-12. Bloque : 77-02.

## Carte des fichiers

Chemins relatifs à `plugin/cockpit/` quand ils y sont ; `ui/` = `skills/cockpit-moteur/assets/ui/` ; `RED-TRACE` =
`77-NN-RED-TRACE.md` du dossier de phase.

| Plan | Vague | Exigences | Fichiers créés (C) ou modifiés (M) |
|---|---|---|---|
| 77-01 | 1 | SYNT-02, 04 | M `plugin/conductor/scripts/check-method-budget.sh`, M `plugin/conductor/scripts/check-instruction-budget.sh`, M leurs deux suites `plugin/conductor/scripts/tests/test-check-*.sh`, C deux copies figées sous `plugin/conductor/scripts/tests/fixtures/`, M `plugin/conductor/CHANGELOG.md`, RED-TRACE |
| 77-02 | 1 | SYNT-07, 08, 09 | C `scripts/vf-cockpit-burnup.mjs`, C `scripts/vf-cockpit-blocages.mjs`, M `scripts/vf-cockpit-planning.mjs`, M `scripts/vf-cockpit-project.mjs`, M `scripts/vf-cockpit-interface.json`, C `scripts/tests/test-cockpit-burnup.sh`, C `scripts/tests/test-cockpit-blocages.sh`, M `scripts/tests/test-cockpit-projet-visite.sh` (R3.25), M `CHANGELOG.md`, M `README.md` et `README.fr.md` (racine, compteur de suites), RED-TRACE |
| 77-03 | 2 | SYNT-03, 04 | C `scripts/vf-cockpit-jauges.mjs`, C `scripts/vf-cockpit-methode.mjs`, M `scripts/vf-cockpit-git-lanceur.mjs` (export de `lancerAsync`, module livré par 79-07), M `scripts/vf-cockpit-paths.mjs` (0 ligne nette), M `scripts/vf-cockpit-server.mjs` (une ligne de `ROUTES`, fichier ≤ 299 lignes), M `scripts/vf-cockpit-interface.json`, C `scripts/tests/test-cockpit-jauges.sh`, M `scripts/tests/test-cockpit-routes.sh` (liste de RK.1, A54, `Gate-Touche:`), M `CHANGELOG.md`, M `scripts/ci-shard-suites.sh` (racine), M `README.md` et `README.fr.md` (racine), RED-TRACE |
| 77-04 | 2 | SYNT-05, 06, 07 | C `ui/74-vf-synthese-calcul.js`, C `ui/74-vf-synthese-memoire.js`, M `scripts/vf-cockpit-git.mjs` (`base.h`), M `skills/cockpit-moteur/VENDORED.txt` (lignes `AJOUT`), C `scripts/tests/test-cockpit-synthese.sh`, M `README.md` et `README.fr.md` (racine), RED-TRACE |
| 77-05 | 3 | SYNT-01 | C `ui/74-vf-synthese.js` (coquille, registre, ligne-résumé), M `VENDORED.txt`, C `scripts/tests/test-cockpit-synthese-page.sh`, C `scripts/tests/chrome-synthese.mjs` (banc), M `scripts/ci-shard-suites.sh`, M `README.md` et `README.fr.md` (racine), RED-TRACE |
| 77-06 | 4 | SYNT-01, 04, 08 | C `ui/74-vf-synthese-burnup.js`, C `ui/74-vf-synthese-jauges.js`, M `VENDORED.txt`, C `scripts/tests/test-cockpit-synthese-blocs.sh`, M `scripts/ci-shard-suites.sh`, M `CHANGELOG.md`, M `README.md` et `README.fr.md` (racine), RED-TRACE |
| 77-08 | 5 | SYNT-05, 06, 07 | C `ui/74-vf-synthese-visite.js`, C `ui/74-vf-synthese-style.js`, M `VENDORED.txt`, M `scripts/tests/chrome-synthese.mjs` (ajouts au banc), C `scripts/tests/test-cockpit-synthese-visite.sh`, M `scripts/ci-shard-suites.sh`, M `README.md` (module), M `CHANGELOG.md`, M `README.md` et `README.fr.md` (racine), RED-TRACE |
| 77-07 | 6 | SYNT-10 | C `ui/74-vf-synthese-cout.js`, M `VENDORED.txt`, C `scripts/tests/test-cockpit-synthese-cout.sh`, M `scripts/ci-shard-suites.sh`, M `CHANGELOG.md`, M `README.md` et `README.fr.md` (racine), RED-TRACE |

**Fichiers partagés avec d'autres phases**, du plus exposé au moins exposé :

- `README.md` et `README.fr.md` racine (compteur « N suites », 77-02 à 77-08) : chaque phase qui ajoute une suite
  remesure ; un conflit à la fusion se résout en remesurant par `check-version-sync.sh`, jamais en prenant un côté
  (P77-D-33).
- `plugin/cockpit/CHANGELOG.md` (77-02, 03, 06, 08, 07) : toutes les phases y ajoutent une entrée sous « Non publié »
  (79-20 en réécrit le titre).
- `plugin/cockpit/skills/cockpit-moteur/VENDORED.txt` (77-04 à 77-08) : une ligne `AJOUT` par fichier `ui/` neuf, à sa
  place alphabétique (A52), sans repère.
- `scripts/vf-cockpit-server.mjs` (77-03) : une ligne de la table `ROUTES` (79-05), à sa place alphabétique entre
  `/api/vf/journal` et `/api/vf/modeles`. Les Phases 75, 76 et 79-15 posent les leurs ailleurs dans la même table.
- `scripts/tests/test-cockpit-routes.sh` (77-03) : la liste écrite à la main de RK.1 reçoit `/api/vf/methode` à sa place
  alphabétique (A54) ; les Phases 75 et 76 y ajoutent les leurs ; conflit résolu par l'union triée.
- `scripts/vf-cockpit-git-lanceur.mjs` (77-03) : un mot `export` devant `lancerAsync` ; le module est créé par 79-07.
- `scripts/vf-cockpit-paths.mjs` (77-03) : paramètre `nom` de `driverLockScript`, 0 ligne nette ; descend sous 200
  lignes avec 79-07 (plafond effectif 299, A44).
- `scripts/vf-cockpit-project.mjs` et `scripts/vf-cockpit-planning.mjs` (77-02) : champs facultatifs de
  `cockpit-project@1` (A32), lus par `instantane().projet` (79-09) ; partagés avec 75, 76 et 80.
- `scripts/vf-cockpit-interface.json` (77-02, 77-03) : grammaire `optionnels` existante, déclaration de la route.
- `scripts/vf-cockpit-git.mjs` (77-04) : champ facultatif `base.h` de `cockpit-git@1` ; la 74 lit ce contrat.
- `scripts/ci-shard-suites.sh` racine (77-03, 05, 06, 08, 07) : table des durées, partagée par toutes les phases.
- `test-cockpit-projet-visite.sh` (77-02, assertion R3.25).
- `plugin/conductor/` (77-01) : deux gates, leurs suites et des fixtures (trailers `Gate-Touche:`), plus le CHANGELOG
  du module, partagé avec 79-03 et 79-04.
- Pas touchés : le dictionnaire de traduction, `viewer.html`, `ui/00-vibeflow.js`, `ui/20-health.js`, la liste
  `EVENEMENTS` de `ui/69-vf-flux.js` (aucun événement neuf, pas de repère `vf-repere:phase-77` utilisé).

**Ordre des vagues :**
1. Vague 1 : 77-01 (conductor, à tout moment) et 77-02 (données du cockpit), en parallèle.
2. Vague 2 : 77-03 et 77-04 (seuls fichiers communs : les deux README racine, conflit résolu par remesure).
3. Vague 3 : 77-05 (coquille et banc).
4. Vague 4 : 77-06 (burn-up et jauges).
5. Vague 5 : 77-08 (dernière visite), sérialisé derrière 77-06 sur les fichiers partagés.
6. Vague 6 : 77-07 (coût), après revalidation fraîche contre la 79 et la 74 livrées.

**Ce que la 77 attend d'une autre phase** (vagues de la 79 entre parenthèses) :

| Phase | Ce qu'elle doit livrer | Plans de la 77 concernés |
|---|---|---|
| 79 | 79-05 (v1) : table `ROUTES`, réponse gardée | 77-03, dure |
| 79 | 79-07 (v2) : lanceur `vf-cockpit-git-lanceur.mjs`, `envGit` | 77-03, dure |
| 79 | 79-02 (v1) et 79-06 (v2) : lancement des suites depuis le module, `cockpit_module_copie`, `COCKPIT_MODULE` | 77-03 à 77-08, dure |
| 79 | 79-01 (v1) et 79-11 (v4) : inventaire `AJOUT`, cliquet de colonnes | 77-04 à 77-08, dure |
| 79 | 79-09 (v3) : `instantane()` | 77-02 (douce), 77-03 (dure pour M-COLLECTE) |
| 79 | 79-12 (v4) : `GET /api/vf/state` | 77-08, 77-07 |
| 79 | 79-13 (v5) : frise (`tronque`, `voiesOmises`) | 77-07, dure |
| 79 | 79-15 (v6) : graphe servi | 77-05 |
| 79 | 79-16 (v7) : coquille, `surOnglet(rappel, {cle})` (A51), liste `/_vf/` | 77-05 à 77-08, dure, sans repli (P77-D-25) |
| 79 | 79-17 (v8) : `VF_ETAT` (`jeton`, `lireJson`, `lire`) | 77-05 à 77-08 |
| 79 | 79-22 (SOCL-27, non poussé) : à relire pour 77-07 | 77-07, à revalider |
| 74 | 74-01 : `window.__vfFriseCalculs.agreger` (sortie avec `inconnus`, `incomplet`) | 77-07, douce |

**Ce que la 77 fournit :**
- Aux autres phases :
  - `--format=tsv` des deux gates, utilisable par tout outil ;
  - champs facultatifs `burnup` et `blocagesState` de `cockpit-project@1` ;
  - champ `base.h` de `cockpit-git@1` ;
  - lanceur asynchrone borné exporté par `vf-cockpit-git-lanceur.mjs` (ré-exporté par `vf-cockpit-paths.mjs`).
- À la 80 : la ligne morte `ui/00-vibeflow.js:211` (lecture de `lastDesc`).

## À verser par la jointure

Texte exact à poser par la jointure, que la mission n'a pas touché (périmètre fermé) :

1. **ROADMAP, checklist du jalon** : la ligne de la Phase 77 garde sa forme et son état « à faire ». Si la jointure y
   porte l'état de planification, la mention à ajouter est « planifiée 2026-11-11 (8 plans) ».
2. **ROADMAP, table `## Progress`**, ligne de la Phase 77 : `0/8 | Planned | -`.
3. **REGISTRE.md** (`.planning/research/2026-11-10-audit-cockpit/REGISTRE.md`) :
   - colonne d'état d'AUDC-I14 : `cadrée et planifiée (Phase 77, 2026-11-11 : SYNT-05..07, plans 77-04 et 77-08)` ;
   - colonne d'état d'AUDC-I08 : `part Phase 77 cadrée et planifiée (2026-11-11 : SYNT-10, plan 77-07, dépend des Phases 79 et 74)`.
4. **REGISTRE.md § 3 (retraits)**, ligne à ajouter :
   `| La prose recopiée du STATE sous « Maintenant » (lastDesc) | la synthèse datée | Phase 77 |`.
5. **BACKLOG**, à ajouter, pour la Phase 80 ou la prochaine phase qui touche `ui/00-vibeflow.js` : « Retirer la
   lecture morte de `lastDesc` (`ui/00-vibeflow.js:211`), dont le producteur est retiré par la Phase 77 (P77-D-12). »
6. **STATE** (tenu par la session principale) : décision à consigner « Phase 77 cadrée et planifiée le 2026-11-11 :
   8 plans en 6 vagues, SYNT-01..10, deux questions appliquées par délégation (P77-Q-01, P77-Q-02) ».
7. **Repères** : retirer `<!-- vf-cadrage:phase-77 -->` et la ligne « repère de cadrage, Phase 77 » de la table de
   traçabilité, comme prévu à la jointure.
8. **REQUIREMENTS, pied « Last updated »** : `2026-11-11 — SYNT-01..10 posées au cadrage de la Phase 77 (P77-D-01..36, décisions déléguées par Samuel (message session principale, 2026-11-08), option recommandée)`.

## Limites et incidents

- **Limite de 20 sous-agents simultanés**, partagée par les sept missions. Elle a refusé un premier lancement
  d'éclaireur et deux lancements du planificateur. Le planificateur est reparti sur reprise du `vf-coder` par
  SendMessage (attente par tranches de 150 s, au plus 8 essais).
- **Vérificateur de plans du moteur** : un seul tour chez `vf-coder` (second tour refusé par la même limite), puis la
  vérification fraîche du manager. La commande `verify.plan-structure` du moteur a rendu une sortie vide : la structure
  a été contrôlée à la main par le vérificateur.
- **Gate de sortie, contrôle E4** : manque ou indéterminé attendu. Les plans ne sont pas exécutés et le STATE n'est
  pas marqué, par construction de la mission ; rien n'a été fait pour le verdir.
- **Budgets de méthode** : `check-method-budget.sh` n'a été joué qu'en constat (`--no-remote`, puis `--auto --dry-run`),
  jamais en archivage (consigne : rien n'est rangé par la mission ; dépassements du ROADMAP, du BACKLOG et des
  worktrees déjà connus et traités à part).
- **`check-ajout-retrait --ci`** (consultatif) : 30 ajouts non couverts, tous antérieurs à la branche (aucun ne
  concerne la Phase 77).
- **Étage design** : le contrat d'interface `77-UI-SPEC.md` est posé et vérifié (7 réserves non bloquantes). Les
  nœuds `craft` et `critique` de l'étage design sont à dispatcher dans la mission d'exécution (77-05, 77-06). Personne
  n'a ouvert le navigateur.
- **Estimation** : 1 030 000 jetons au total pour les 8 plans (150 000, 120 000, 160 000, 110 000, 110 000, 140 000,
  110 000, 130 000 de 77-01 à 77-08), confiance basse partout, relevée telle quelle dans les plans. 77-05 a été scindé
  (P77-D-30) : le plus lourd est désormais 77-03 (160 000). Un contrôle d'estimation reste à faire avant l'exécution.
- **Coupure de quota** à 15 h 33 (HTTP 429) pendant la revalidation : les deux correcteurs se sont arrêtés net,
  aucun fichier écrit sous un mauvais nom, reprise sans perte après changement de compte.
- **Têtes de la 79 citées** : elles ne sont pas uniformes entre plans, parce que la 79 a avancé pendant la
  revalidation. Chaque plan cite celle qu'il a relue (`cce6ed3f`, `677d19fa`, `e0336732`, `c19c7461`), toutes de la
  même lignée. Une vérification fraîche à l'exécution relira la tête du jour.

## Coût

- Minds dispatchés : 8 mandats émis, plus 2 reprises par SendMessage.
  - Mandats : 2 éclaireurs, 3 chercheurs de décision, 1 `vf-coder`, 1 vérificateur de plans, plus 1 lancement refusé
    par la plateforme.
  - Reprises : le `vf-coder`, pour la planification après le blocage de capacité, puis pour la correction ciblée.
- Jetons rapportés par la plateforme à chaque retour, relayés tels quels :

| Agent | Jetons |
|---|---|
| Éclaireur code | 225 876 |
| Éclaireur sources | 190 957 |
| Panel dernière visite | 68 416 |
| Panel jauges | 82 351 |
| Panel placement | 111 435 |
| `vf-coder`, premier retour | 277 214 |
| `vf-coder`, deuxième retour | 335 585 |
| `vf-coder`, troisième retour | 344 066 |
| Vérificateur frais | 87 762 |

  La plateforme ne dit pas si les compteurs du `vf-coder` sont cumulés d'un retour à l'autre : ces chiffres ne sont
  pas sommés.
- Revalidation (après-midi) :
  - 3 vérifications de départ en parallèle : 123 290, 250 351 et 159 395 jetons.
  - 2 `vf-coder` en parallèle, repris 5 et 4 fois par SendMessage ; derniers retours : 433 204 et 427 555 jetons,
    compteurs probablement cumulés, non sommés.
  - 7 vérifications fraîches : 133 531, 168 612, 142 233, 101 656, 82 173, 84 957 jetons, plus la dernière (voir
    « Preuves E6 »).
  - Une vérification lancée sur `351bc9e8` a été rendue en partie obsolète par la publication des plans 79-15 à 79-20.

## Preuves E6

Format : verdict, commande, code de sortie, SHA de la tête au moment du verdict.

```json
{
 "preuves": [
  {"verdict": "gate:check-machine-paths", "commande": "bash scripts/check-machine-paths.sh", "exit_code": 0, "sha": "9908f9ec"},
  {"verdict": "gate:check-divergence", "commande": "bash plugin/conductor/scripts/check-divergence.sh --path .", "exit_code": 0, "sha": "9908f9ec"},
  {"verdict": "gate:check-state-integrity", "commande": "GSD_WORKSTREAM=fiabilite bash plugin/conductor/scripts/check-state-integrity.sh", "exit_code": 0, "sha": "9908f9ec"},
  {"verdict": "gate:check-planning-consumers-registered", "commande": "bash plugin/conductor/scripts/check-planning-consumers-registered.sh", "exit_code": 0, "sha": "9908f9ec"},
  {"verdict": "gate:check-ajout-retrait", "commande": "bash plugin/conductor/scripts/check-ajout-retrait.sh --ci", "exit_code": 0, "sha": "9908f9ec"},
  {"verdict": "gate:state-inchange", "commande": "git diff --quiet origin/integration/cockpit-audit -- .planning/workstreams/fiabilite/STATE.md", "exit_code": 0, "sha": "9908f9ec"},
  {"verdict": "gate:plan-checker", "preuve": "amont"},
  {"verdict": "gate:ui-checker", "preuve": "amont"}
 ]
}
```

- Vérification fraîche des plans (`gsd-plan-checker`, lecture seule, sur `870fb29f`) : `passed`, 0 bloquant, 2 FLAG
  (77-02 : code de retour d'une suite ignoré, corrigé en `c1c77d63` ; estimation informative). Elle a vérifié au code
  présent que la prémisse « rouge aujourd'hui » de 4 témoins est vraie. Verdict relayé, sans commande rejouable.
- Contrat d'interface (vérificateur d'interface, chez `vf-coder`) : VERIFIED, 0 bloquant, 7 réserves. Verdict relayé.

## Prochaine étape

La jointure verse les sept branches de cadrage dans `integration/cockpit-audit`, avec la section « À verser » de chaque
rapport. Ensuite, l'exécution de la Phase 77 suit l'ordre du jalon, après la 76 et la première vague de la 79. Le plan
77-01 (gates du conductor) peut partir dès la jointure, puisqu'il ne dépend d'aucune phase.
