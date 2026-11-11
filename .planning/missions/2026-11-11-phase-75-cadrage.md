# Mission Phase 75 — cadrage, recherche, spécification d'interface et plans (2026-11-11)

**Manager :** `vf-dev-manager`, dispatché par la session principale (head) pour Samuel, dans la vague de cadrage parallèle
des Phases 73, 74, 75, 76, 77, 79 et 80 (demande de Samuel, session principale Claude Code, 2026-11-11).
**Compartiment / jalon :** `fiabilite` / `vibeflow-v2.0`. **Mode :** autonome, design `auto`.
**Base :** `origin/integration/cockpit-audit` à `f763b556`. **Branche :** `feat/phase-75-activite-sur-le-code`, worktree
`.claude/worktrees/phase-75`. **Verrou :** de phase, `--ws fiabilite --phase 75`.
**PR :** #233 vers `integration/cockpit-audit` (ouverte, non mergée ; publications gelées).
**Périmètre :** cadrage, recherche, spécification d'interface, plans et leur vérification. Aucune exécution, aucun
fichier de code ni de test.

## Verdict

**Planifiée, prête à exécuter après les Phases 79 (22 plans), 80 et 74.** Cadrage `75-CONTEXT.md` (P75-D-01 à D-31 ;
P75-D-28 et P75-D-29 sont des arbitrages de Samuel, AskUserQuestion session principale, 2026-11-11 ; les autres sont
déléguées), famille d'exigences neuve **ACTV-01 à ACTV-12**, recherche `75-RESEARCH.md` avec une table de preuves
rejouable des commandes de vérification, spécification d'interface `75-UI-SPEC.md` acceptée à **81/100** au quatrième
tour (seuil 70), **12 plans en 9 vagues**. La dernière vérification fraîche (commit `f8cba978`) rend `passed` : 0 bloquant,
0 majeur ; ses deux mineurs de ponctuation sont corrigés, le troisième reste ouvert (ci-dessous). Revalidation contre la 79
à la tête `d4d0cd41` (79-01 à 79-22 écrits, A1 à A54), contre la 74 à `e3768442` et la 80 à `3e5db01f`. Aucune
exécution, aucun fichier de code ni de test ; STATE.md intact. Une question attend Samuel et bloque 75-10 seulement :
P75-Q-06, les neuf amendements de `DESIGN.md`.

## Reprise du 2026-11-11 (après les arbitrages de Samuel)

- **Q-75-3 et Q-75-4 tranchées** (arbitrage Samuel, AskUserQuestion session principale, 2026-11-11) : P75-D-28 (retrait
  ferme, P70-D-01 amendée dans cette mesure exacte) et P75-D-29 (worktree prouvé du dépôt = le lab, A45 de la 79).
  Conditions de départ levées, branche de repli retirée des plans (témoin : grep vide, commit `9ddbe831`).
- **Radar précisé** (P75-D-30, déléguée) : sentinelle « hors du lab » jamais jointe ; même cible dans deux arbres =
  « conflit de fusion possible », distinct de la collision dans un même arbre ; priorité agents > arbres > branches >
  prévu ; A46 (nom de worktree ambigu → sentinelle).
- **Contrats de la 79 jusqu'à A47** (`daae8bc9`) : clé de recalcul = `instantane().git.sig` (A31 tenue, aucune lecture
  git par requête) ; `git: null` → « en cours de lecture » ; `frise` jusqu'à 2 000 voies, `tronque` → « Radar
  incomplet : historique tronqué ». `compileGlob` corrigé par la 79 au point unique (79-21, P79-D-32) ; la 75 n'y pose
  plus de borne propre.
- **Canal de marquage** (P75-D-05 amendée, déléguée ; coordination tranchée par la session principale) : posé par la
  75 (75-07) ; le geste « Voir sur la carte » de la 74 est rebranché dessus dans le même lot (deux endroits de
  `ui/74-vf-frise-carte.js` : `voirSurLaCarte` et `finirRelecture` ; suite `test-cockpit-frise-curseur.sh`, C8b retiré,
  C8 étendu). API : `VF_MARQUES.poser(couche, entrées, { exclusif })`, `VF_MARQUES.retirer(couche)` (restitue la couche
  précédente), `active()`, `lire(id)`. Ordre de chargement indépendant du nom (résolution tardive, témoin). Fichiers
  neufs de la 75 renommés `ui/75-vf-*`.
- **« À Samuel » au format C76-Q1** : P75-Q-01 à P75-Q-06 ; P75-Q-06 (amendements de `DESIGN.md`) en attente, bloque 75-10,
  dont la tâche de point de contrôle humain est bloquante (`autonomous: false`).
- **Plans 75-05 à 75-10** : « à revalider à l'écriture de 79-15..21 » (seuls 79-01 à 79-14 sont écrits sur la branche
  de la 79 au moment de la reprise).

## Plan de bataille (DAG)

| Nœud | Contenu | Porteur | Issue |
|---|---|---|---|
| scout-sources, scout-code | Faits des sources de l'audit et du code présent, en lecture seule | 2 × general-purpose | fait |
| panels | 4 panels de zones grises : forme sur la carte, données git, empreinte et index, gardes et retrait | 4 × gsd-advisor-researcher | fait |
| discuss-75 | Cadrage : `75-CONTEXT.md`, ACTV-01..12, corps du ROADMAP | manager (Pattern F) | fait, poussé `a62a9dfb` |
| (temps 2 enchaîné sans rendre la main, consigne de la session principale) | | | |
| research-75 | `75-RESEARCH.md` | gsd-phase-researcher | fait `686df387` |
| uispec-75 / critique | `75-UI-SPEC.md`, 4 tours de craft, 4 juges neufs | vf-crafter, vf-design-judge | 67, 62, 69, puis **81/100 passed** (quatrième tour accordé par la session principale) ; 10 constats du juge final repris comme critères dans 75-07 et 75-08 |
| plan-75 | 12 plans, 9 vagues | vf-coder (planification seule) | fait `3a7094c7`, onze corrections ciblées jusqu'à `5f95f30b`, alignements du manager jusqu'à `f8cba978` |
| plancheck-75 | vérifications fraîches | gsd-plan-checker | 13 vérifications fraîches + 1 figée (voir Incidents) ; dernière **`passed`** sur `f8cba978` (0 bloquant, 0 majeur, 3 mineurs) |
| pr-rapport | PR vers `integration/cockpit-audit`, ce rapport | manager | fait |

## Décisions prises en autonomie

Toutes au registre `75-CONTEXT.md` (P75-D-01 à D-27), « décision déléguée par Samuel (message session principale,
2026-11-08), option recommandée » ; aucune ne vaut arbitrage de Samuel. Les plus engageantes :

- **Lecture du but** (P75-D-01) : « se colore » = « se marque » : glyphe à trois paliers neutre et mot, la teinte « en
  cours » réservée à l'écriture en direct ; Q9 et `DESIGN.md` § 9 tenus (panel forme).
- **Lentilles exclusives** dans le menu qui portait « Travail récent » ; géométrie invariante (place réservée dans le
  pied, onglet Code seulement) ; critère d'arrêt si le zoom d'ouverture change de palier (P75-D-02, D-03, D-25).
- **Données git** (panel git, mesures sur ce dépôt) : 90 jours plafonnés à 5 000 commits ; couplage aux seuils de
  code-maat ; collisions committées par paire de HEAD (merge-base), jamais `git status` périodique ni `git diff` contre
  l'arbre de travail ; tâche asynchrone sur la signature de HEAD et des refs, sans cache disque (P75-D-07 à D-10).
- **Empreinte en mémoire seulement** (AUDC-Q2 tenue), lue dans l'instantané de la 79 ; calcul côté serveur ; chemins
  ramenés à l'arbre, chemin réel (P75-D-12 à D-14, D-22, D-23).
- **Gardes** par la règle de citation de la CI réécrite en lecture ; zone sans témoin = « aucune suite ne le nomme » ;
  lentille absente hors lab VibeFlow (P75-D-16, D-17).
- **Cartes prévues** par un annotateur du graphe Code ; constats de l'auditeur en réserve (P75-D-18, D-19).
- **Retrait** (P75-D-20, P75-D-28) : la couche déclarative « Travail récent » et `scripts/recent.mjs`, retrait ferme depuis l'arbitrage Samuel, AskUserQuestion session principale, 2026-11-11 (Q-75-3, « La remplacer (Recommandé) ») ; P70-D-01 amendée dans cette mesure exacte. Entre-temps (mandat de clôture du même jour), le retrait avait été conditionné, parce qu'il touchait un arbitrage rendu et ne relevait pas de la délégation.
- **Worktrees du dépôt** (P75-D-29, P75-D-30) : un worktree prouvé du même dépôt compte comme le lab (arbitrage Samuel, AskUserQuestion session principale, 2026-11-11, Q-75-4 = S-3 de la 79, « Les compter comme le lab (Recommandé) ») ; forme A45 de la 79 ; sentinelle « hors du lab » écartée de la jointure ; même fichier dans deux arbres = « conflit de fusion possible », distinct de la collision dans un même arbre.
- **Partage avec la 80** : la 80 pose `vague`, la 75 n'ajoute que `files_modified` (P75-D-24, P80-D-44, partage arrêté
  par la session principale).
- **Étage design** : quatrième tour accordé par la session principale, dernier (P75-D-26) ; pastille de compte neutre
  sur la règle P71.5-D-19 (P75-D-27).

## À Samuel

**Tranchées le 2026-11-11** (arbitrage Samuel, AskUserQuestion session principale, 2026-11-11 ; identifiants C76-Q1 du CONTEXT entre parenthèses) : P75-Q-03 (Q-75-3) « La remplacer
(Recommandé) » (P75-D-28) ; P75-Q-04 (Q-75-4) « Les compter comme le lab (Recommandé) » (P75-D-29).

**Appliquées par délégation, contestables** (l'option recommandée est appliquée, rien n'est bloqué ; texte complet dans
`75-CONTEXT.md`) :
- **P75-Q-01 (Q-75-1)** Carte de chaleur à fond ou dégradé : non (recommandé), Q9 tient.
- **P75-Q-02 (Q-75-2)** Empreinte au-delà de 24 h : non (recommandé) ; renvoie à S-1 de la 79.
- **P75-Q-05 (Q-75-5)** Pastille de compte pleine `--recent` du bouton livré : neutre partout (recommandé, P71.5-D-19).

**En attente — P75-Q-06, bloque 75-10 (point de contrôle humain bloquant) — amendements de `DESIGN.md` à montrer à
Samuel avant application (neuf, et non huit : le planificateur a scindé le dernier) :**
1. § 2 « Graphe de code » : puce « Lentilles d'activité (Phase 75) ».
2. § 5 Carte : retrait de la variante `recent` (anneau, `.rw`, `.recent-in`) ; ajout de `st-prevu`.
3. § 5 Pastille de statut : `(.vst, .rw)` devient `(.vst)` ; ajout de la marque de lentille `.lm` et de ses glyphes.
4. § 4 Carte : pied de 28 unités réservé à toute carte marquable de l'onglet Code.
5. § 7 Icônes : liste des glyphes de pastille élargie ; l'exception « glyphe d'une pastille de statut » couvre le glyphe « en cours ».
6. § 9 Toujours : variante texte `--recent-text` sur `.card.module` en clair.
7. § 5 Composants : menu à rangées radio avec légende hors du `role="menu"` (`#lens-menu`), bouton-compte de la rangée `.k`, pastille neutre `--on` sans exception.
8. § 2 : `--recent` = « récent, succès, en cours d'écriture » ; § 6 : respiration du glyphe sur les cartes ; § 4 : compensation de la bordure de 1,5 px de la carte prévue.
9. Tableau « Statuts de travail » : aucune ligne `--st-prevu` ajoutée.

## Conditions Q-75-3 levées (2026-11-11)

Les conditions de départ posées au mandat de clôture (75-09a tâches 1a et 2b, 75-09b tâche 1, 75-09c entier, 75-10
tâche 2b) sont levées par P75-D-28 ; la branche de repli (lentille « Récent », blocs « Sous le repli ») est retirée des
plans, et avec elle les deux trous qu'elle aurait ouverts (75-07 : `.rw` et `.lm` sur le même emplacement ; 75-08 :
sixième lentille). Témoin : `rtk proxy grep -n 'repli\|Récent »\|Q-75-3'` sur les douze plans rend une sortie vide
(commit `9ddbe831`). `showBoard` (tableau générique du moteur, utilisé par la relecture de la 74) est préservé : témoin
Q8b de 75-09b, mutant « `showBoard` retiré avec la couche ».

**Canal de marquage des cartes (relevé sur `origin/feat/phase-74-equipe-dans-le-temps`, `1da6dcab`) :** la 74 ne crée
aucun canal ; sa relecture « Voir sur la carte » (P74-D-12) passe par `showBoard`. Le canal est créé par la 75, plan 75-07
(`ui/75-vf-marques.js`). Pas de trou. Les fichiers neufs de la 75 sont renommés `ui/75-vf-*` (la 74 occupe `ui/74-vf-*`).

## Carte des fichiers

### Fichiers partagés avec d'autres phases (en tête)

| Fichier | Plan(s) de la 75 | Partagé avec | Nature |
|---|---|---|---|
| `plugin/cockpit/scripts/vf-cockpit-server.mjs` (table `ROUTES` de 79-05 ; le mécanisme vit dans `vf-cockpit-routes.mjs`) | 75-05 | 79 (79-05), 76 (`/api/vf/tracabilite`), 77 (`/api/vf/methode`) | une ligne `[chemin, lecteur, régime?]`, place alphabétique (`/api/vf/activite`), après 79-22 |
| `plugin/cockpit/scripts/tests/test-cockpit-routes.sh` | 75-05 | 79 (79-05, 79-12, 79-13, 79-15), 76, 77 | une ligne dans la liste écrite à la main de RK.1, à sa place alphabétique |
| `plugin/cockpit/scripts/vf-cockpit-interface.json` | 75-05 | 79, 74, 76, 77 | schéma `vibeflow/cockpit-activite@1` |
| `plugin/cockpit/scripts/vf-cockpit-planning.mjs`, `vf-cockpit-project.mjs` | 75-04 | 79 (79-09), 80 (`vague`, `avancement`, `exigences`) | champ facultatif `files_modified` seulement |
| `plugin/cockpit/scripts/vf-cockpit-build.mjs` | 75-06 (annotateur `prevues`, 1 ligne, ordre alphabétique de nom), 75-09a (retrait) | 79 (79-05, table des annotateurs, A27/A34) | |
| `plugin/cockpit/scripts/vf-cockpit-git.mjs` | 75-01 (export de `monoVol`) | 79 (79-09) | à relire après 79-09 |
| Moteur : `skills/cockpit-moteur/scripts/build.mjs`, `scripts/lib/common.mjs`, `assets/serve.mjs` | 75-06, 75-09a | 79 (79-01, 79-06) | |
| `skills/cockpit-moteur/assets/viewer.html` | 75-07, 75-08, 75-09b | 79 (vague 3+), 80 (80-09, 11, 13, 14, 16, 19), 74 | plafond en cliquet de 79-11 |
| `skills/cockpit-moteur/VENDORED.txt` | 75-07, 75-08, 75-09b | 79 (79-01 le réduit) | forme à revalider |
| `skills/cockpit-moteur/assets/ui/02-vf-telephone.js` | 75-08, 75-09b | 79, 80 | entrée du « ⋯ » |
| `ui/00-vibeflow.js`, `ui/01-vf-responsive.js` | 75-09b | 79, 80 | migration `#btn-recent` → `#btn-lentilles` |
| Dictionnaires `ui/78-vf-fr-dict-a.js`, `ui/80-vf-fr.js` | 75-09c (un seul plan) | 79 (79-10), 80 | `79-vf-fr-dict-b.js` non touché |
| `plugin/cockpit/CHANGELOG.md`, `plugin/cockpit/README.md` | 75-10 (un seul plan) | toutes les phases du cockpit, 79-20 | |
| `DESIGN.md` | 75-10 (un seul plan) | 74, 79 (79-01), 80 | amendements du § 12 de la spec ; aucune exception de badge |
| `README.md`, `README.fr.md` (compteur de suites gaté par `scripts/check-version-sync.sh`) | 75-10 (un seul plan) | toute phase qui ajoute une suite | |
| Suites existantes adaptées (`test-cockpit-securite.sh`, `-onglet-code`, `-ecrans-recent` et sa fixture, `-moteur-carte`, `chrome-moteur-carte.mjs`, `-responsive`, `-chrome-fr`, `-chaine-xss`) | 75-09a, 75-09b, 75-09c, 75-10 | 79 (79-02 les migre vers `socle-serveur.sh`), 80 | adaptées, jamais supprimées |
| Canal de marquage des cartes (`VF_MARQUES`, `ui/75-vf-marques*.js`) | 75-07 | aucune (la 74 passe par `showBoard`) | créé par la 75 (P75-D-05, relevé du 2026-11-11) |

### Fichiers par plan

| Plan | Vague | Dépend de (75) | Après (autres phases) | Exigences | Fichiers créés ou modifiés |
|---|---|---|---|---|---|
| 75-01 Calcul git | 1 | — | 79-01, 79-07, 79-09 | ACTV-04, 05, 06, 10 | `scripts/vf-cockpit-activite-log.mjs`, `-activite-git.mjs`, `-activite-branches.mjs` (neufs) ; `vf-cockpit-git.mjs` ; `tests/test-cockpit-activite-git.sh` (neuf) |
| 75-02 Gardes | 1 | — | 79-01 | ACTV-07 | `vf-cockpit-activite-gardes.mjs`, `tests/test-cockpit-activite-gardes.sh` (neufs) |
| 75-03 Chemins, empreinte, collisions | 1 | — | 79-07, 79-09, 79-13 | ACTV-08, 09, 10 | `vf-cockpit-activite-chemins.mjs`, `-empreinte.mjs`, `-collisions.mjs`, `tests/test-cockpit-activite-chemins.sh`, `-empreinte.sh` (neufs) |
| 75-04 `files_modified` | 1 | — | 79-09 ; plan de la 80 qui pose `vague` | ACTV-10, 11 | `vf-cockpit-planning.mjs`, `vf-cockpit-project.mjs` ; `tests/test-cockpit-activite-planning.sh` (neuf) |
| 75-05 Route et schéma | 2 | 01-04 | 79-02, 79-05, 79-06, 79-09, 79-12, 79-13, 79-15 | ACTV-04, 08, 10, 12 | `vf-cockpit-activite.mjs` (neuf), `vf-cockpit-server.mjs` (1 ligne dans `ROUTES`), `vf-cockpit-interface.json`, `tests/test-cockpit-activite-route.sh` (neuf) |
| 75-06 Cartes prévues | 3 | 03, 04, 05 | 79-01, 79-02, 79-05, 79-09, 79-15 | ACTV-11 | `vf-cockpit-activite-prevues.mjs` (neuf), `vf-cockpit-build.mjs` (1 ligne) ; moteur `build.mjs`, `lib/common.mjs`, `serve.mjs` ; `tests/test-cockpit-activite-prevues.sh` (neuf) |
| 75-07 Canal, pied réservé, marques | 4 | 05, 06 | 79-01, 79-02, 79-11, 79-16, 79-17, 79-18 ; 74 ; clavier du canevas de la 80 | ACTV-01, 02, 03, 10, 11 | `viewer.html`, `ui/75-vf-marques.js`, `ui/75-vf-marques-glyphes.js` (neufs), `VENDORED.txt`, `tests/test-cockpit-activite-carte.sh`, `chrome-activite-carte.mjs` (neufs) |
| 75-08 Sélecteur, menu, panneau, radar | 5 | 05, 07 | 79-16, 79-17, 79-18 ; surcouches de la 80 ; 74 | ACTV-01, 02, 06, 07, 08, 10 | `ui/75-vf-activite.js`, `-menu.js`, `-tables.js`, `-panneau.js`, `-collisions.js` (neufs), `ui/02-vf-telephone.js`, `viewer.html`, `VENDORED.txt`, `tests/test-cockpit-activite-lentilles.sh`, `chrome-activite-lentilles.mjs` (neufs) |
| 75-09a Retrait, assemblage et moteur | 6 | 06, 07, 08 | 79-01, 79-15 | ACTV-12 | `vf-cockpit-build.mjs`, moteur `build.mjs`, `recent.mjs` (supprimé), `refresh.mjs`, `graph-query.js`, `ui/60-export.js`, `tests/test-cockpit-securite.sh`, `test-cockpit-onglet-code.sh` |
| 75-09b Retrait, page et jetons | 7 | 07, 08, 09a | 79-11, 79-16 ; plans de la 80 qui touchent `viewer.html` | ACTV-12, 01 | `viewer.html`, `ui/25-recent.js` (supprimé), `ui/00-vibeflow.js`, `ui/01-vf-responsive.js`, `ui/02-vf-telephone.js`, `VENDORED.txt`, `test-cockpit-ecrans-recent.sh` et sa fixture, `test-cockpit-responsive.sh` |
| 75-09c Retrait, dictionnaires et suites voisines | 8 | 09b | 79-10 ; dictionnaires de la 80 | ACTV-12 | `ui/78-vf-fr-dict-a.js`, `ui/80-vf-fr.js`, `test-cockpit-moteur-carte.sh`, `chrome-moteur-carte.mjs`, `test-cockpit-chrome-fr.sh` |
| 75-10 Non-régression et docs | 9 | 05-09c | 79-20 ; 74, 80 | ACTV-12 | `tests/test-cockpit-chaine-xss.sh`, `test-cockpit-activite-sans-git.sh` (neuf), `plugin/cockpit/CHANGELOG.md`, `plugin/cockpit/README.md`, `DESIGN.md`, `README.md`, `README.fr.md` |

Chaque plan écrit aussi sa trace de rouge `75-NN-RED-TRACE.md` dans le dossier de la phase. Chemins abrégés :
`scripts/` = `plugin/cockpit/scripts/`, `tests/` = `plugin/cockpit/scripts/tests/`, `ui/` et `viewer.html` sous
`plugin/cockpit/skills/cockpit-moteur/assets/`.

**Ordre des vagues :** 1 (01, 02, 03, 04, fichiers disjoints) → 2 (05) → 3 (06, qui dépend de 05 : les deux touchent
`test-cockpit-routes.sh`, RK.1 puis AN.1, A54) → 4 (07) → 5 (08) → 6 (09a) → 7 (09b) → 8 (09c) → 9 (10). Plans de la 80 cités d'après `origin/feat/phase-80-trois-formes` : 80-01 (clavier du canevas, nom de
carte), 80-02 (pile de surcouches), 80-03 (`vague`, avant 75-04) ; 80-09, 11, 13, 14, 16 et 19 touchent aussi
`viewer.html` (collision nommée, résolue par l'ordre des phases).
Toute la phase s'exécute après la Phase 79 entière et après la 74 (ordre du jalon). Aucun diff de patch régénéré
(`plugin/cockpit/amont/` retiré par 79-01) ; suites lancées par `plugin/cockpit/scripts/tests/socle-serveur.sh` (79-02).

**Ce que la 75 attend des autres :**
- 79 : C0-C6 et A1-A33 (`feat/phase-79-socle-cockpit`, `3119d82a`, `2ae6607a`, `6f66d878`, `74501bb0`, `e04c43e7`) ;
  en particulier l'instantané en mémoire (79-09, 79-13), la table des routes et des annotateurs et la réponse gardée
  (79-05), `socle-serveur.sh` (79-02), la coquille, `VF_ETAT` et `surOnglet` (79-16, 79-17), l'API du moteur en worker
  (79-18), le plafond en cliquet (79-11).
- 80 : `vague` sur le plan (P80-D-44), la pile `VF_SURCOUCHES`, la fonction unique de nom accessible des cartes.
- 74 : rien (le canal est créé par la 75) ; 79-21 : correction de `compileGlob` au point unique, dont dépend 75-06.

**Ce que la 75 fournit :** route `GET /api/vf/activite` (`vibeflow/cockpit-activite@1`), champ `files_modified` du
planning, canal de marquage des cartes réutilisable par la relecture de la 74, cartes « prévues » sur le graphe Code.

## À verser par la jointure (texte exact à poser par la session principale)

1. **ROADMAP, ligne de checklist de la Phase 75 :** `- [ ] **Phase 75: L'activité posée sur le code — hotspots, couplage, gardes, empreinte** — cadrée et planifiée le 2026-11-11 (12 plans, 9 vagues, ACTV-01..12)`.
2. **ROADMAP, table `## Progress`, ligne de la Phase 75 :** `| 75. L'activité posée sur le code | 0/12 | Planifiée | - |`.
3. **REQUIREMENTS, repères :** retirer `<!-- vf-cadrage:phase-75 -->` et la ligne repère « repère de cadrage, Phase 75 » de la table `## Traceability` ; compteurs globaux : + 12 exigences (ACTV-01..12, Pending).
4. **REGISTRE.md de l'audit :** AUDC-I12 et AUDC-I13 → « planifié (Phase 75, 2026-11-11) » ; AUDC-I36 → « planifié en partie (Phase 75 : cartes prévues, agent par zone) ; constats de l'auditeur sur les cartes en réserve (P75-D-19) ».
5. **BACKLOG, réserve :** « Constats de l'auditeur posés sur les cartes de l'onglet Code (AUDC-I36, troisième idée) — déclencheur : un fichier de constats de `vf-auditer` typé et versionné existe (P75-D-19, 2026-11-11). »
6. **STATE.md, décisions :** « 2026-11-11 — Phase 75 cadrée et planifiée (P75-D-01..31 ; P75-D-28 et P75-D-29 arbitrages Samuel, AskUserQuestion session principale, 2026-11-11) ; P75-Q-06 (amendements de DESIGN.md) en attente, bloque 75-10. »
7. **Recoupement avec la Phase 74 :** réglé — la 75 crée le canal (75-07), la 74 n'en crée aucun ; fichiers de la 75 sous `ui/75-vf-*`.
8. **Constat né de la planification, versé à la Phase 79 (P79-D-32, plan 79-21) et à verser au REGISTRE de l'audit (classe AUDC-A-02 / performance) :**
   « `compileGlob` du moteur (`plugin/cockpit/skills/cockpit-moteur/scripts/lib/common.mjs`) est super-linéaire sur un
   motif à plusieurs `**` : `compileGlob('**/a/**/b/**/*.js')` contre `'a/'.repeat(N)+'x'` mesure 855,0 ms à N = 20 000 et
   3 444,6 ms à N = 40 000 (mesure de planification, Phase 75, 2026-11-11). Pris par la 79 au point unique (P79-D-32, plan 79-21,
   `scripts/lib/vf-glob.mjs`) ; la 75 n'y pose plus de borne propre et garde un témoin de non-régression (75-06, V-N2N). »
9. **Durées des suites neuves** à inscrire dans `scripts/ci-shard-suites.sh` après exécution (touche un gate : trailer `Gate-Touche`).

## Mineur ouvert de la dernière vérification (non bloquant, à traiter en tête d'exécution)

1. 75-05 et 75-06 : le rouge de RK.1 (resp. AN.1) avant la mise à jour de la liste est exigé dans le comportement, mais
   aucun critère d'acceptation n'impose de le consigner dans la trace de rouge (attendu, obtenu). Le risque est faible :
   l'exactitude de la liste a déjà son témoin rouge dans 79-05.

## Incidents

- **Vérificateur de plans figé** : un gsd-plan-checker est resté bloqué sur une commande composée jamais démarrée (aucun
  fichier écrit, aucun processus, transcript immobile) ; remplacé par un vérificateur neuf, arrêté par la session
  principale à la demande du manager (un parent ne peut pas arrêter son enfant) ; aucun de ses résultats n'est repris.
- **Plafond d'agents simultanés de la session** (20, partagé par les sept missions) atteint à plusieurs reprises :
  dispatches retardés, jamais contournés ; relevé à 100 par Samuel le 2026-11-11.
- **Coupure de session** (quota du compte atteint, HTTP 429, vers 15 h 33) : manager et planificateur arrêtés net ;
  reprise sur un autre compte à la demande de Samuel ; état mesuré sur disque, rien de perdu (seul le rapport était non
  commité, il l'a été à la reprise) ; un enfant resté inscrit « en cours » au registre a été fermé.
- **Consignes relayées corrigées en cours de route** : la table `ROUTES` vit dans `vf-cockpit-server.mjs` (pas dans
  `vf-cockpit-routes.mjs`) et `test-cockpit-routes.sh` est à modifier (liste écrite à la main de RK.1 et AN.1, A54) ;
  les deux points, d'abord relayés autrement, ont été rétablis par les vérifications fraîches et corrigés.
- **Rapport de juge référencé avant d'exister** : le premier mandat de correction de la spec citait un fichier écrit par le
  manager quelques secondes plus tard ; le crafter a traité 7 constats sur 16 puis l'a signalé ; renvoyé au tour suivant.
- **Exception de badge retirée** : le manager avait d'abord tranché « exception de la 71.5 gardée » sur la foi d'une
  référence fausse ; la session principale a demandé de relire le texte ; décision retirée (P75-D-27, Q-75-5), rien
  n'a été écrit dans `DESIGN.md`.

## Limites

- Aucune exécution : les témoins sont décrits, aucun n'a été rejoué ; aucune sonde de navigateur (navigateur partagé).
- Points « à revalider » à l'exécution : format de la suite `test-cockpit-frise-curseur.sh` de la 74 (motifs repris de
  74-06, suite pas encore écrite) ; motifs RK.1, RK.7 et AN.1 prouvés contre le plan 79-05, à relire sur la suite livrée ;
  forme des lignes `AJOUT` de `VENDORED.txt` après 79-01 ; glyphe et mot de la couche `relecture`.
- Le gate de sortie rendra son contrôle E4 en manque ou indéterminé (plans non exécutés, STATE non marqué) : attendu,
  non verdi.
- Gate de sortie (`check-mission-exit.sh --ws fiabilite`, rejoué avant la remise) : E3 conforme après ajout des lignes
  « Porte » et « Rayon d'explosion » au corps de la PR ; E4 sans étape à vérifier (attendu) ; E1 lit le registre du
  verrou de COMPARTIMENT, où 6 agents d'autres managers de la vague sont « running » — le registre de la Phase 75 compte
  0 orphelin ; E7 lit un instantané de budget partagé par les sept missions (date seule). Verdict global INDÉTERMINÉ,
  attendu pour une mission de planification en verrou de phase.
- STATE.md jamais touché : `git diff --quiet origin/integration/cockpit-audit -- .planning/workstreams/fiabilite/STATE.md` rend 0.

## Décompte

- Minds dispatchés (mandats émis, comptés sur les mandats émis) : 53 — 27 agents neufs (2 éclaireurs, 4 panels,
  1 chercheur, 1 crafter, 4 juges, 2 planificateurs, 13 vérificateurs de plans dont le figé) et 26 messages de reprise ou
  de complément (planificateurs 18, crafter 5, juge 1, chercheur 1, vérificateur figé 1).
- Tours : spec d'interface 4 tours de craft, 4 juges neufs (67, 62, 69, 81) ; plans : 1 écriture + 11 corrections ciblées,
  14 vérifications fraîches (dont 1 figée, sans résultat repris).

## Preuves E6

Le contrôle des invariants rend 3 (SAIN, seul code « vérifié, conforme »). La vérification des plans et la critique de la spec
sont des jugements d'agents sans commande rejouable : leurs verdicts sont relayés plus haut, pas ici.

```json
{
  "preuves": [
    {
      "verdict": "gate:check-machine-paths",
      "commande": "bash scripts/check-machine-paths.sh",
      "exit_code": 0,
      "sha": "bfcf75e02f179907ac1017d85f93875c14f22b66"
    },
    {
      "verdict": "gate:state-intact",
      "commande": "git diff --quiet origin/integration/cockpit-audit -- .planning/workstreams/fiabilite/STATE.md",
      "exit_code": 0,
      "sha": "bfcf75e02f179907ac1017d85f93875c14f22b66"
    },
    {
      "verdict": "gate:mission-invariants",
      "commande": "bash plugin/conductor/scripts/check-mission-invariants.sh",
      "exit_code": 3,
      "sha": "bfcf75e02f179907ac1017d85f93875c14f22b66"
    }
  ]
}
```
