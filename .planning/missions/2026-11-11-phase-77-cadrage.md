# Mission — Phase 77, cadrage et planification (2026-11-11)

**Verdict : cadrée et planifiée.** 7 plans en 5 vagues, 10 exigences `SYNT-01..10`, 27 décisions `P77-D-01..27`
(toutes déléguées par Samuel, message session principale, 2026-11-08, option recommandée), contrat d'interface vérifié,
plans vérifiés par une vérification fraîche (`passed`). Rien n'est exécuté.

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

## À Samuel (non bloquant, aussi dans `77-CONTEXT.md`)

- **A77-1 — coût par phase au-delà de 24 h** (reprend S-2 de la Phase 79). En vigueur : AUDC-Q2, la fenêtre de 24 h.
  Sur 24 h, le bloc dit ce qui consomme en ce moment, pas ce qu'a coûté une phase qui dure plusieurs jours.
  Recommandation : garder 24 h pour cette vague, avec le titre « dernières 24 h ». Un agrégat persisté par phase, étage
  et modèle n'est à instruire que si la question se pose ; il rouvrirait AUDC-Q2.
- **A77-2 — retrait de la prose « Maintenant »** (P77-D-12). Ce n'est pas une réouverture : aucune décision écrite ne
  porte sur ce texte. Il change pourtant ce que Samuel lit à l'ouverture de Projet. À voir à la recette ; le repli est
  le trio de compteurs.

## Carte des fichiers

Chemins relatifs à `plugin/cockpit/` quand ils y sont ; `ui/` = `skills/cockpit-moteur/assets/ui/` ; `RED-TRACE` =
`77-NN-RED-TRACE.md` du dossier de phase.

| Plan | Vague | Exigences | Fichiers créés (C) ou modifiés (M) |
|---|---|---|---|
| 77-01 | 1 | SYNT-02, 04 | M `plugin/conductor/scripts/check-method-budget.sh`, M `plugin/conductor/scripts/check-instruction-budget.sh`, M leurs deux suites `plugin/conductor/scripts/tests/test-check-*.sh`, C deux copies figées sous `plugin/conductor/scripts/tests/fixtures/`, M `plugin/conductor/CHANGELOG.md`, RED-TRACE |
| 77-02 | 1 | SYNT-07, 08, 09 | C `scripts/vf-cockpit-burnup.mjs`, C `scripts/vf-cockpit-blocages.mjs`, M `scripts/vf-cockpit-planning.mjs`, M `scripts/vf-cockpit-project.mjs`, M `scripts/vf-cockpit-interface.json`, C `scripts/tests/test-cockpit-burnup.sh`, C `scripts/tests/test-cockpit-blocages.sh`, M `scripts/tests/test-cockpit-projet-visite.sh` (R3.25), M `CHANGELOG.md`, RED-TRACE |
| 77-03 | 2 | SYNT-03, 04 | C `scripts/vf-cockpit-jauges.mjs`, C `scripts/vf-cockpit-methode.mjs`, M `scripts/vf-cockpit-paths.mjs` (2 retouches, reste à 296 lignes), M `scripts/vf-cockpit-server.mjs` (une ligne dans la table des routes), M `scripts/vf-cockpit-interface.json`, C `scripts/tests/test-cockpit-jauges.sh`, M `CHANGELOG.md`, M `scripts/ci-shard-suites.sh` (racine du dépôt), RED-TRACE |
| 77-04 | 2 | SYNT-05, 06, 07 | C `ui/74-vf-synthese-calcul.js`, C `ui/74-vf-synthese-memoire.js`, M `scripts/vf-cockpit-git.mjs` (`base.h`), C `scripts/tests/test-cockpit-synthese.sh`, RED-TRACE |
| 77-05 | 3 | SYNT-01, 05, 06, 07 | C `ui/74-vf-synthese.js`, C `ui/74-vf-synthese-visite.js`, C `ui/74-vf-synthese-style.js`, C `scripts/tests/test-cockpit-synthese-page.sh`, C `scripts/tests/chrome-synthese.mjs`, M `scripts/ci-shard-suites.sh`, M `README.md`, M `CHANGELOG.md` (dont `base.h`), RED-TRACE |
| 77-06 | 4 | SYNT-01, 04, 08 | C `ui/74-vf-synthese-burnup.js`, C `ui/74-vf-synthese-jauges.js`, C `scripts/tests/test-cockpit-synthese-blocs.sh`, M `scripts/ci-shard-suites.sh`, M `CHANGELOG.md`, RED-TRACE |
| 77-07 | 5 | SYNT-10 | C `ui/74-vf-synthese-cout.js`, C `scripts/tests/test-cockpit-synthese-cout.sh`, M `scripts/ci-shard-suites.sh`, M `CHANGELOG.md`, RED-TRACE |

**Fichiers partagés avec d'autres phases**, du plus exposé au moins exposé :

- `plugin/cockpit/CHANGELOG.md` (77-02, 03, 05, 06, 07) : sept phases y ajoutent une entrée sous « Non publié ».
- `scripts/vf-cockpit-server.mjs` (77-03) : une ligne dans la table des routes de la 79 (A10), à sa place
  alphabétique, `/api/vf/methode`. Les Phases 75 et 76 posent les leurs ailleurs.
- `scripts/vf-cockpit-paths.mjs` (77-03) : l'`export` de `lancerAsync` et un paramètre de nom sur
  `driverLockScript`. Fichier à 296/300 lignes ; la 79 le touche aussi.
- `scripts/vf-cockpit-project.mjs` et `scripts/vf-cockpit-planning.mjs` (77-02) : lecture du planning de la collecte,
  touchée par la 79 (A32) et vraisemblablement par la 80 (couloirs).
- `scripts/vf-cockpit-interface.json` (77-02, 77-03) : champs facultatifs de `cockpit-project@1`, déclaration de la
  route des jauges ; la 79 y ajoute le bloc de l'index.
- `scripts/vf-cockpit-git.mjs` (77-04) : champ facultatif `base.h` de `cockpit-git@1` ; la 74 lit ce contrat.
- `scripts/ci-shard-suites.sh` (77-03, 05, 06, 07) : table des durées de suites, partagée par toutes les phases.
- Suites : `test-cockpit-projet-visite.sh` (77-02, assertion R3.25), touchée par d'autres phases sur Projet.
- `plugin/conductor/` (77-01) : deux gates et leurs suites ; la 79 touche d'autres fichiers du conductor (registre du
  verrou), pas ceux-là.
- Pas touchés par la 77 : le dictionnaire de traduction (libellés écrits en français au point d'émission),
  `viewer.html`, les patchs du moteur et `VENDORED.txt` (les plans d'interface passent après leur retrait par la 79).
  Si l'ordre s'inversait, chaque fichier `ui/` neuf ajouterait sa ligne `AJOUT`.

**Ordre des vagues :**
1. Vague 1 : 77-01 (conductor, à tout moment) et 77-02 (données du cockpit), en parallèle.
2. Vague 2 : 77-03 et 77-04.
3. Vague 3 : 77-05.
4. Vague 4 : 77-06.
5. Vague 5 : 77-07, après revalidation.
Aucun fichier commun entre deux plans d'une même vague (vérifié par le vérificateur frais).

**Ce que la 77 attend d'une autre phase :**

| Phase | Ce qu'elle doit livrer | Plans de la 77 concernés |
|---|---|---|
| 79 | 79-05 : table des routes et réponse gardée commune | 77-03 |
| 79 | 79-09 : instantané | 77-02, dépendance douce |
| 79 | 79-01 : retrait de l'appareil de patchs | 77-04 à 77-06, dépendance dure |
| 79 | 79-16 : `VF_COQUILLE.surOnglet` | 77-05, 77-06, dépendance dure, sans repli (P77-D-25) |
| 79 | 79-17 : `VF_ETAT` | dépendance douce |
| 79 | 79-12 et 79-13 : missions côté page et frise | 77-07, dépendance dure |
| 74 | 74-01 : agrégat de coût par phase | 77-07, dépendance douce |
| 80 | P80-D-33 à D-41 : pile `VF_SURCOUCHES`, s'il faut une surcouche | — |

**Ce que la 77 fournit :**
- Aux autres phases :
  - `--format=tsv` des deux gates, utilisable par tout outil ;
  - champs facultatifs `burnup` et `blocagesState` de `cockpit-project@1` ;
  - champ `base.h` de `cockpit-git@1` ;
  - lanceur asynchrone borné exporté par `vf-cockpit-paths.mjs`.
- À la 80 : la ligne morte `ui/00-vibeflow.js:211` (lecture de `lastDesc`).

## À verser par la jointure

Texte exact à poser par la jointure, que la mission n'a pas touché (périmètre fermé) :

1. **ROADMAP, checklist du jalon** : la ligne de la Phase 77 garde sa forme et son état « à faire ». Si la jointure y
   porte l'état de planification, la mention à ajouter est « planifiée 2026-11-11 (7 plans) ».
2. **ROADMAP, table `## Progress`**, ligne de la Phase 77 : `0/7 | Planned | -`.
3. **REGISTRE.md** (`.planning/research/2026-11-10-audit-cockpit/REGISTRE.md`) :
   - colonne d'état d'AUDC-I14 : `cadrée et planifiée (Phase 77, 2026-11-11 : SYNT-05..07, plans 77-04 et 77-05)` ;
   - colonne d'état d'AUDC-I08 : `part Phase 77 cadrée et planifiée (2026-11-11 : SYNT-10, plan 77-07, dépend des Phases 79 et 74)`.
4. **REGISTRE.md § 3 (retraits)**, ligne à ajouter :
   `| La prose recopiée du STATE sous « Maintenant » (lastDesc) | la synthèse datée | Phase 77 |`.
5. **BACKLOG**, à ajouter, pour la Phase 80 ou la prochaine phase qui touche `ui/00-vibeflow.js` : « Retirer la
   lecture morte de `lastDesc` (`ui/00-vibeflow.js:211`), dont le producteur est retiré par la Phase 77 (P77-D-12). »
6. **STATE** (tenu par la session principale) : décision à consigner « Phase 77 cadrée et planifiée le 2026-11-11 :
   7 plans en 5 vagues, SYNT-01..10, deux questions non bloquantes à Samuel (A77-1, A77-2) ».
7. **Repères** : retirer `<!-- vf-cadrage:phase-77 -->` et la ligne « repère de cadrage, Phase 77 » de la table de
   traçabilité, comme prévu à la jointure.
8. **REQUIREMENTS, pied « Last updated »** : `2026-11-11 — SYNT-01..10 posées au cadrage de la Phase 77 (P77-D-01..27, décisions déléguées par Samuel (message session principale, 2026-11-08), option recommandée)`.

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
- **Estimation** : 940 000 jetons au total pour les 7 plans, confiance basse partout, relayée telle quelle par le
  vérificateur. Le plan le plus lourd est 77-05 (170 000). Un contrôle d'estimation reste à faire avant l'exécution.

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
