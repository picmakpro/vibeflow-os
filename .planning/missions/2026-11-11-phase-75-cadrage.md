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

**Planifiée, prête à exécuter après les Phases 79, 80 et 74.** Cadrage `75-CONTEXT.md` (P75-D-01 à D-27), famille
d'exigences neuve **ACTV-01 à ACTV-12**, recherche `75-RESEARCH.md` avec une table de preuves rejouable des commandes de
vérification, spécification d'interface `75-UI-SPEC.md` acceptée à **81/100** au quatrième tour (seuil 70), **12 plans en
8 vagues**, dont la dernière vérification fraîche rend `passed` (0 bloquant, 0 majeur, 6 mineurs ouverts ci-dessous).
Aucune exécution, aucun fichier de code ni de test ; STATE.md intact.

## Plan de bataille (DAG)

| Nœud | Contenu | Porteur | Issue |
|---|---|---|---|
| scout-sources, scout-code | Faits des sources de l'audit et du code présent, en lecture seule | 2 × general-purpose | fait |
| panels | 4 panels de zones grises : forme sur la carte, données git, empreinte et index, gardes et retrait | 4 × gsd-advisor-researcher | fait |
| discuss-75 | Cadrage : `75-CONTEXT.md`, ACTV-01..12, corps du ROADMAP | manager (Pattern F) | fait, poussé `a62a9dfb` |
| (temps 2 enchaîné sans rendre la main, consigne de la session principale) | | | |
| research-75 | `75-RESEARCH.md` | gsd-phase-researcher | fait `686df387` |
| uispec-75 / critique | `75-UI-SPEC.md`, 4 tours de craft, 4 juges neufs | vf-crafter, vf-design-judge | 67, 62, 69, puis **81/100 passed** (quatrième tour accordé par la session principale) ; 10 constats du juge final repris comme critères dans 75-07 et 75-08 |
| plan-75 | 12 plans, 8 vagues | vf-coder (planification seule) | fait `3a7094c7`, corrigé `f0a5c41d`, `370633f9`, `fb104665`, `e5efa88a`, `02f0c12b` |
| plancheck-75 | 3 vérifications fraîches | gsd-plan-checker | 5 vérifications fraîches + 1 figée (voir Incidents) : `issues_found` ×4 (6/16/11, 3/4/6, 3/4/5, 0/4/9), puis **`passed`** sur `3c260aa0` (0/0/6) |
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
- **Retrait** : couche déclarative « Travail récent » et `scripts/recent.mjs` (P75-D-20).
- **Partage avec la 80** : la 80 pose `vague`, la 75 n'ajoute que `files_modified` (P75-D-24, P80-D-44, partage arrêté
  par la session principale).
- **Étage design** : quatrième tour accordé par la session principale, dernier (P75-D-26) ; pastille de compte neutre
  sur la règle P71.5-D-19 (P75-D-27).

## À Samuel (non bloquant — l'arbitrage en vigueur tient, les plans sont bâtis dessus)

Texte complet et options : `75-CONTEXT.md` § « À Samuel ».

- **Q-75-1** Carte de chaleur à fond ou dégradé : non (recommandé), Q9 tient.
- **Q-75-2** Empreinte au-delà de 24 h : non (recommandé) ; renvoie à S-1 de la 79.
- **Q-75-3** Retrait du « Travail récent » (P70-D-01 lue comme emplacement) : retirer (recommandé).
- **Q-75-4** Worktrees hors du dossier du lab : avis de la 75 pour l'option (b) de S-3 de la 79 (un worktree du même
  dépôt compte comme le lab) ; aucun plan ne change.
- **Q-75-5** Pastille de compte pleine `--recent` du bouton livré : neutre partout (recommandé, P71.5-D-19).

## Carte des fichiers

### Fichiers partagés avec d'autres phases (en tête)

| Fichier | Plan(s) de la 75 | Partagé avec | Nature |
|---|---|---|---|
| `plugin/cockpit/scripts/vf-cockpit-routes.mjs` (module neuf de 79-05, A34) | 75-05 | 79 (79-05), 76 (`/api/vf/tracabilite`), 77 (`/api/vf/methode`) | une ligne, place alphabétique (`/api/vf/activite`) |
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
| Canal de marquage des cartes (`VF_MARQUES`, `ui/74-vf-marques*.js`) | 75-07 | 74 (relecture AUDC-I06) | qui le pose : la phase exécutée la première (P75-D-05) |

### Fichiers par plan

| Plan | Vague | Dépend de (75) | Après (autres phases) | Exigences | Fichiers créés ou modifiés |
|---|---|---|---|---|---|
| 75-01 Calcul git | 1 | — | 79-01, 79-07, 79-09 | ACTV-04, 05, 06, 10 | `scripts/vf-cockpit-activite-log.mjs`, `-activite-git.mjs`, `-activite-branches.mjs` (neufs) ; `vf-cockpit-git.mjs` ; `tests/test-cockpit-activite-git.sh` (neuf) |
| 75-02 Gardes | 1 | — | 79-01 | ACTV-07 | `vf-cockpit-activite-gardes.mjs`, `tests/test-cockpit-activite-gardes.sh` (neufs) |
| 75-03 Chemins, empreinte, collisions | 1 | — | 79-07, 79-09, 79-13 | ACTV-08, 09, 10 | `vf-cockpit-activite-chemins.mjs`, `-empreinte.mjs`, `-collisions.mjs`, `tests/test-cockpit-activite-chemins.sh`, `-empreinte.sh` (neufs) |
| 75-04 `files_modified` | 1 | — | 79-09 ; plan de la 80 qui pose `vague` | ACTV-10, 11 | `vf-cockpit-planning.mjs`, `vf-cockpit-project.mjs` ; `tests/test-cockpit-activite-planning.sh` (neuf) |
| 75-05 Route et schéma | 2 | 01-04 | 79-02, 79-05, 79-06, 79-09, 79-12, 79-13, 79-15 | ACTV-04, 08, 10, 12 | `vf-cockpit-activite.mjs` (neuf), `vf-cockpit-routes.mjs` (1 ligne), `vf-cockpit-interface.json`, `tests/test-cockpit-activite-route.sh` (neuf) |
| 75-06 Cartes prévues | 2 | 03, 04 | 79-01, 79-02, 79-05, 79-09, 79-15 | ACTV-11 | `vf-cockpit-activite-prevues.mjs` (neuf), `vf-cockpit-build.mjs` (1 ligne) ; moteur `build.mjs`, `lib/common.mjs`, `serve.mjs` ; `tests/test-cockpit-activite-prevues.sh` (neuf) |
| 75-07 Canal, pied réservé, marques | 3 | 05, 06 | 79-01, 79-02, 79-11, 79-16, 79-17, 79-18 ; 74 ; clavier du canevas de la 80 | ACTV-01, 02, 03, 10, 11 | `viewer.html`, `ui/74-vf-marques.js`, `ui/74-vf-marques-glyphes.js` (neufs), `VENDORED.txt`, `tests/test-cockpit-activite-carte.sh`, `chrome-activite-carte.mjs` (neufs) |
| 75-08 Sélecteur, menu, panneau, radar | 4 | 05, 07 | 79-16, 79-17, 79-18 ; surcouches de la 80 ; 74 | ACTV-01, 02, 06, 07, 08, 10 | `ui/74-vf-activite.js`, `-menu.js`, `-tables.js`, `-panneau.js`, `-collisions.js` (neufs), `ui/02-vf-telephone.js`, `viewer.html`, `VENDORED.txt`, `tests/test-cockpit-activite-lentilles.sh`, `chrome-activite-lentilles.mjs` (neufs) |
| 75-09a Retrait, assemblage et moteur | 5 | 06, 07, 08 | 79-01, 79-15 | ACTV-12 | `vf-cockpit-build.mjs`, moteur `build.mjs`, `recent.mjs` (supprimé), `refresh.mjs`, `graph-query.js`, `ui/60-export.js`, `tests/test-cockpit-securite.sh`, `test-cockpit-onglet-code.sh` |
| 75-09b Retrait, page et jetons | 6 | 07, 08, 09a | 79-11, 79-16 ; plans de la 80 qui touchent `viewer.html` | ACTV-12, 01 | `viewer.html`, `ui/25-recent.js` (supprimé), `ui/00-vibeflow.js`, `ui/01-vf-responsive.js`, `ui/02-vf-telephone.js`, `VENDORED.txt`, `test-cockpit-ecrans-recent.sh` et sa fixture, `test-cockpit-responsive.sh` |
| 75-09c Retrait, dictionnaires et suites voisines | 7 | 09b | 79-10 ; dictionnaires de la 80 | ACTV-12 | `ui/78-vf-fr-dict-a.js`, `ui/80-vf-fr.js`, `test-cockpit-moteur-carte.sh`, `chrome-moteur-carte.mjs`, `test-cockpit-chrome-fr.sh` |
| 75-10 Non-régression et docs | 8 | 05-09c | 79-20 ; 74, 80 | ACTV-12 | `tests/test-cockpit-chaine-xss.sh`, `test-cockpit-activite-sans-git.sh` (neuf), `plugin/cockpit/CHANGELOG.md`, `plugin/cockpit/README.md`, `DESIGN.md`, `README.md`, `README.fr.md` |

Chaque plan écrit aussi sa trace de rouge `75-NN-RED-TRACE.md` dans le dossier de la phase. Chemins abrégés :
`scripts/` = `plugin/cockpit/scripts/`, `tests/` = `plugin/cockpit/scripts/tests/`, `ui/` et `viewer.html` sous
`plugin/cockpit/skills/cockpit-moteur/assets/`.

**Ordre des vagues :** 1 (01, 02, 03, 04, fichiers disjoints) → 2 (05, 06) → 3 (07) → 4 (08) → 5 (09a) → 6 (09b) →
7 (09c) → 8 (10). Plans de la 80 cités d'après `origin/feat/phase-80-trois-formes` : 80-01 (clavier du canevas, nom de
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
- 74 : le canal de marquage s'il est posé en premier (P75-D-05).

**Ce que la 75 fournit :** route `GET /api/vf/activite` (`vibeflow/cockpit-activite@1`), champ `files_modified` du
planning, canal de marquage des cartes réutilisable par la relecture de la 74, cartes « prévues » sur le graphe Code.

## À verser par la jointure (texte exact à poser par la session principale)

1. **ROADMAP, ligne de checklist de la Phase 75 :** `- [ ] **Phase 75: L'activité posée sur le code — hotspots, couplage, gardes, empreinte** — cadrée et planifiée le 2026-11-11 (12 plans, 8 vagues, ACTV-01..12)`.
2. **ROADMAP, table `## Progress`, ligne de la Phase 75 :** `| 75. L'activité posée sur le code | 0/12 | Planifiée | - |`.
3. **REQUIREMENTS, repères :** retirer `<!-- vf-cadrage:phase-75 -->` et la ligne repère « repère de cadrage, Phase 75 » de la table `## Traceability` ; compteurs globaux : + 12 exigences (ACTV-01..12, Pending).
4. **REGISTRE.md de l'audit :** AUDC-I12 et AUDC-I13 → « planifié (Phase 75, 2026-11-11) » ; AUDC-I36 → « planifié en partie (Phase 75 : cartes prévues, agent par zone) ; constats de l'auditeur sur les cartes en réserve (P75-D-19) ».
5. **BACKLOG, réserve :** « Constats de l'auditeur posés sur les cartes de l'onglet Code (AUDC-I36, troisième idée) — déclencheur : un fichier de constats de `vf-auditer` typé et versionné existe (P75-D-19, 2026-11-11). »
6. **STATE.md, décisions :** « 2026-11-11 — Phase 75 cadrée et planifiée (P75-D-01..27, décisions déléguées) ; cinq questions non bloquantes à Samuel (Q-75-1..5). »
7. **Recoupement avec la Phase 74 :** qui pose le canal de marquage des cartes (`VF_MARQUES`) — la première des deux phases exécutée ; noms de fichiers `ui/74-vf-*` de la 75 à renuméroter si la 74 prend la même plage.
8. **Constat né de la planification, à verser au REGISTRE de l'audit et à la Phase 79 (classe AUDC-A-02 / performance) :**
   « `compileGlob` du moteur (`plugin/cockpit/skills/cockpit-moteur/scripts/lib/common.mjs`) est super-linéaire sur un
   motif à plusieurs `**` : `compileGlob('**/a/**/b/**/*.js')` contre `'a/'.repeat(N)+'x'` mesure 855,0 ms à N = 20 000 et
   3 444,6 ms à N = 40 000 (mesure de planification, Phase 75, 2026-11-11). La 75 s'en protège pour ses cartes prévues en
   bornant le chemin à 4 096 octets avant rattachement (75-06, V-N2N) ; les autres appelants du moteur ne le sont pas. »
9. **Durées des suites neuves** à inscrire dans `scripts/ci-shard-suites.sh` après exécution (touche un gate : trailer `Gate-Touche`).

## Mineurs ouverts de la dernière vérification (à traiter en tête d'exécution, non bloquants)

1. 75-09c : le filtre d'inventaire exempte en plus `DESIGN.md` et `plugin/cockpit/README.md` (provisoire jusqu'à 75-10) ;
   la prose dit « identiques dans les quatre plans » : le dire provisoire.
2. 75-06 : le mutant s'appelle encore « `lstat` omis » alors que la règle est la résolution physique de 79-07 (A37) ;
   renvoi de 75-03 à corriger.
3. 75-06 : citer 79-07 et 79-16 dans `cross_phase`.
4. 75-09a, 09b, 09c : rappeler dans chaque tâche qui adapte une assertion d'absence la règle du littéral en deux morceaux.
5. 75-09c, 75-10 : l'exception `--recent` n'est pas ancrée (elle masquerait un reste `#btn-recent { color: var(--recent) }`).
6. 75-10 : épingler la garde `PASS — Q1\.2 — mutant` au lieu de n'importe quel `Q.x`.

## Incidents

- **Vérificateur de plans figé** : un gsd-plan-checker est resté bloqué sur une commande composée jamais démarrée (aucun
  fichier écrit, aucun processus, transcript immobile) ; remplacé par un vérificateur neuf, arrêté par la session
  principale à la demande du manager (un parent ne peut pas arrêter son enfant) ; aucun de ses résultats n'est repris.
- **Plafond d'agents simultanés de la session** (20, partagé par les sept missions) atteint à plusieurs reprises :
  dispatches retardés, jamais contournés.
- **Rapport de juge référencé avant d'exister** : le premier mandat de correction de la spec citait un fichier écrit par le
  manager quelques secondes plus tard ; le crafter a traité 7 constats sur 16 puis l'a signalé ; renvoyé au tour suivant.
- **Exception de badge retirée** : le manager avait d'abord tranché « exception de la 71.5 gardée » sur la foi d'une
  référence fausse ; la session principale a demandé de relire le texte ; décision retirée (P75-D-27, Q-75-5), rien
  n'a été écrit dans `DESIGN.md`.

## Limites

- Aucune exécution : les témoins sont décrits, aucun n'a été rejoué ; aucune sonde de navigateur (navigateur partagé).
- Points « à revalider » à l'exécution : forme de `VENDORED.txt` après 79-01, nom du gate de plafond de 79-11, forme
  d'une ligne des tables de routes et d'annotateurs (79-05), numéros des plans de la 80, canal de la 74, plage `ui/74-*`.
- Le gate de sortie rendra son contrôle E4 en manque ou indéterminé (plans non exécutés, STATE non marqué) : attendu,
  non verdi.
- Gate de sortie (`check-mission-exit.sh --ws fiabilite`, rejoué avant la remise) : E3 conforme après ajout des lignes
  « Porte » et « Rayon d'explosion » au corps de la PR ; E4 sans étape à vérifier (attendu) ; E1 lit le registre du
  verrou de COMPARTIMENT, où 6 agents d'autres managers de la vague sont « running » — le registre de la Phase 75 compte
  0 orphelin ; E7 lit un instantané de budget partagé par les sept missions (date seule). Verdict global INDÉTERMINÉ,
  attendu pour une mission de planification en verrou de phase.
- STATE.md jamais touché : `git diff --quiet origin/integration/cockpit-audit -- .planning/workstreams/fiabilite/STATE.md` rend 0.

## Décompte

- Minds dispatchés (mandats émis, comptés) : 29 — 19 agents neufs (2 éclaireurs, 4 panels, 1 chercheur, 1 crafter, 4 juges, 1 planificateur, 6 vérificateurs de plans dont le figé) et 10 reprises par message (crafter 4, planificateur 5, juge 1).
- Tours : spec d'interface 4 tours de craft, 4 juges neufs (67, 62, 69, 81) ; plans : 1 écriture + 4 corrections ciblées, 6 vérifications fraîches (dont 1 figée, sans résultat repris).

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
