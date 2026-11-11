# Mission — Phase 79, cadrage et planification (2026-11-11)

**Statut :** cadrage et planification faits, aucune exécution. 22 plans écrits et commités ; quatorze vérifications
fraîches passées, dernière passe de correction commitée (`677d19fa`).

**Périmètre :** Phase 79 « Socle du cockpit — une collecte, un flux, une route d'état », compartiment `fiabilite`,
jalon `vibeflow-v2.0`. Manager : `vf-dev-manager`. Sortie : `79-CONTEXT.md` (contrats, amendements, décisions,
découpage), `79-RESEARCH.md`, les plans `79-NN-PLAN.md`, le corps de la Phase 79 au ROADMAP, le bloc `SOCL` de
REQUIREMENTS. Aucun fichier de code, aucune suite, aucun serveur lancé.

**Base et branche :** branche `feat/phase-79-socle-cockpit`, partie de `integration/cockpit-audit` (`f763b556` :
release v2.77.0 alignée + lot 0 de l'audit). 33 commits de planification au-dessus de la base au moment de la
rédaction (tête : `677d19fa`, dernière passe de correction). STATE.md : jamais réécrit (contrôle `git diff --quiet`
contre la base, rendu 0 avant chaque commit).

Dossier de phase : `.planning/workstreams/fiabilite/phases/VFDO-79-socle-du-cockpit-une-collecte-un-flux-une-route-d-tat/`.

## Résultat

- **Verdict :** phase cadrée et planifiée, prête pour l'exécution de sa vague 1 après assemblage des sept cadrages.
  Les `wave` des 22 frontmatters sont conformes au découpage ; deux écarts mineurs de `depends_on` restent nommés
  (« Carte des fichiers », b).
- **22 plans en 11 vagues** (découpage imposé de `79-CONTEXT.md`, colonne « Vague » amendée ; 79-22 sorti de 79-13
  par la vérification fraîche).
- **Exigences :** famille `SOCL-01` à `SOCL-27`, posée dans REQUIREMENTS.md, chacune portée par un plan (table de
  traçabilité : `Pending`).
- **Contrats fournis** aux Phases 73, 74, 75, 76, 77 et 80 : C0 à C6, puis 53 amendements (A1 à A55), figés dans
  `79-CONTEXT.md` § « Contrats fournis ».
- **Décisions :** P79-D-01 à P79-D-33. Une seule est un arbitrage de Samuel (P79-D-33) ; toutes les autres sont des
  décisions déléguées (option recommandée).
- **Questions à Samuel** (format C76-Q1, `P79-Q-01` à `Q-04`, anciens S-1 à S-4) : S-1 et S-2 appliquées par
  décision déléguée, option recommandée en vigueur ; S-3 tranchée (P79-D-33) ; S-4 en attente (modification de
  périmètre, liée à la sonde de 79-19).

## Plan de bataille (DAG)

| Nœud | Contenu | Dépend de | Agents |
|---|---|---|---|
| `scout-socle` | routes, schémas, flux, `vf-signal` | — | 1 éclaireur, lecture seule |
| `scout-index` | index, frise, besoins des Phases 74, 75, 77, bornes | — | 1 éclaireur, lecture seule |
| `scout-secu` | AM4 et A-03, reste d'A-02, H3, D-M13, D-M15, A-04, conductor | — | 1 éclaireur, lecture seule |
| `scout-front` | fork H5, H4, AM3 et M7, AM5, AM6, AM7, AB1, I18 | — | 1 éclaireur, lecture seule |
| `contrats` | `79-CONTEXT.md` « Contrats fournis », poussé (`3119d82a`), signal à la session principale | les 4 éclaireurs | manager |
| `discuss-79` | cadrage complet (décisions, retraits, À Samuel) + 3 panels | `contrats` | 3 panels de recherche |
| `research-79` | `79-RESEARCH.md` | `contrats` | 1 chercheur |
| `plan-79` | plans par 6 lots, puis 5 reprises et passes de correction après la coupure de quota | `discuss-79`, `research-79` | 11 mandats `vf-coder`, chacun lançant ses planificateurs |
| `plancheck-79` | vérifications fraîches, une par groupe, reprise après chaque passe de correction | `plan-79` | 14 vérifications de plan |
| `docs` | corps du ROADMAP, bloc `SOCL`, rapport, PR | `plancheck-79` | manager + rédacteur |

Les trois panels : renommage et code lancé depuis le module ; collecte, flux et fil de travail ; hooks, registre et
colonnes. Lots de planification : lot 1 (79-01 à 79-05), lot 2 (79-06, 79-07), lot 3 (79-08, 79-09, 79-12), lot 4
(79-10, 79-11, 79-13, 79-14), lot 5 (79-15 à 79-20), lot 6 (79-21) ; 79-22 sort de 79-13 lors d'une reprise.

Vérifications fraîches et bloquants fermés (les neuf premières, détaillées au journal du manager ; les cinq
suivantes, menées après la coupure de quota, n'y sont pas détaillées) :

| Groupe | Bloquants | Fermeture |
|---|---|---|
| 79-01 à 79-05 | 0 | recouvrement nommé 79-02 / 79-05 sur `test-cockpit-lancer-mode.sh` (zones non adjacentes) ; lignes d'usage de `--help` exigées de 79-03 pour 79-04 |
| 79-06 à 79-09 | 4 | suite de confinement commune à 79-06 et 79-07 (→ A37) ; taille de 79-06 (exécution en trois sessions) ; compteur de suites en littéral dans 79-08 |
| 79-06 / 79-07, 2ᵉ passe | 2 | vérification de la tâche 1 de 79-06 impossible à passer ; contrôles de 79-07 ancrés au merge-base ; 3ᵉ passe : neuf points fermés |
| 79-08 / 79-09 / 79-12 | 0 | 79-12 : mutants qui gardent l'identité du serveur, contrôles bornés à l'état d'avant |
| 79-10 / 79-11 / 79-15 / 79-16 | 1 | 79-16 étendait la CSP sans amendement (→ A40) ; 79-11 passé en vague 4 (fichier commun avec 79-10) |
| 79-13 / 79-14 | 1 | contrôle de périmètre de 79-14 qui passait sans ancre |
| 79-17 / 79-18 / 79-19 / 79-21 | 2 | fichiers communs 79-16 / 79-17 en vague 7 (→ 79-17 en vague 8, 79-18 en 9, 79-19 en 10, 79-20 en 11) ; contrôles de 79-17 et 79-18 sans ancre fermée ; 79-21 : contrôle automatique, motif exact retiré du texte public |
| Diff A45 | 1 | 79-13 cherchait l'arbre par l'ancien libellé → clé unique, règle de collision fermée (A46) |
| Cinq vérifications suivantes | non consigné | traces visibles dans l'historique : 79-22 sorti de 79-13 (`26019872`), ancres et règles de fusion avec la 80 portées aux plans (`8e7afec1`), dernière passe de correction (`677d19fa`) |

## Contrats et amendements

### Contrats (figés avant la recherche détaillée)

| Contrat | Objet |
|---|---|
| C0 | Règles communes : accès (hôte, `Origin`, jeton en temps constant), client hors navigateur, garde d'émission sur cinq clés interdites (503 fermé par défaut), bornes de contenu, versions de schéma, forme du temps |
| C1 | Index incrémental des transcripts `cockpit-index@1`, privé au serveur, 24 h, non fiable à la lecture, sans cible ni texte |
| C2 | `GET /api/vf/state` → `cockpit-state@1`, enveloppe autour d'un `cockpit-signal@1` inchangé ; `vf-signal` la lit quand un serveur vit |
| C3 | `GET /api/vf/frise` → `cockpit-frise@1` : voies, jetons, durées, segments, événements, rattachement, `cibles` en mémoire |
| C4 | Flux d'événements partagé entre onglets, événements `frise`, `etat`, `vie` ajoutés, magasin `window.VF_ETAT` côté page |
| C5 | Coquille statique servie du module, données en JSON (`GET /api/vf/graphe`), mise en page en worker |
| C6 | Ce que la 79 retire ou change sous les pieds des autres : `amont/` retiré, code évalué depuis le module, contrat de forme étendu |

### Amendements

| Id | Objet | Phase demandeuse |
|---|---|---|
| A1 | `/`, `/project.html`, `/equipe.html` servies par la même coquille ; fragment lu tel quel | 80 |
| A2 | `VF_COQUILLE.chargerOnglet(nom)` dans la coquille ; le routage reste à la 80 | 80 |
| A3 | Terminal posé une fois par chargement de coquille, jamais par onglet | 80 |
| A4 | API globale du moteur et événement `render` gardés avec la mise en page en worker | 80 |
| A5 | Événement `graphe` ajouté au flux ; payload `patch` inchangé | 80 |
| A6 | Aide commune des suites `socle-serveur.sh`, signature fixe, livrée par 79-02 | 80 |
| A7 | Ordre : `amont/` retiré par 79-01 en vague 1 ; liste des fichiers du moteur touchés | 80 |
| A8 | `rattachement.dag` = `signal.missions[].fichier` (même source, même réduction) | 74 |
| A9 | `cockpit-git@1` inchangé ; `rangees[].at` en secondes ; marche bornée à 500 commits | 74 |
| A10 | Une route neuve = une ligne de table, ordre alphabétique | 76, 77, toute phase |
| A11 | Réponse gardée commune exportée (contrôles C0, garde, `no-store`, 503) | 76, 77, toute phase |
| A12 | Point de lecture confiné du lab = API unique ; la 79 change le jugement du chemin, pas la couverture | 76 |
| A13 | `VF_ETAT.jeton()`, `VF_ETAT.lireJson(chemin)`, clé `planning` | 76 |
| A14 | `rattachement` peut valoir `{ dag, noeud: null, source: "enfants" }` (voie du manager) | 77 |
| A15 | Verrous projetés en liste blanche dans le flux et dans `signal.verrous` | 73 |
| A16 | Plan de mission publié à côté du verrou, rendu par `status --all` (79-03, 79-04) | 73 |
| A17 | Champs facultatifs de `cockpit-who@2` permis ; signature du `who` sur l'objet moins les champs volatils | 73 |
| A18 | `vf-cockpit-etat-officiel.mjs` touché par la collecte seule ; ajout de la 73 en fin de fichier | 73 |
| A19 | `cockpit-equipe@1` stable, servi tel quel par `graphe?onglet=equipe` | 73 |
| A20 | `sortisSilence` et `finMotif` ajoutés à `cockpit-who@2` | 73 |
| A21 | Signature de l'événement `frise` calculée `cibles` comprises | 75 |
| A22 | Cible relative à la racine réelle de l'arbre de la voie (précisée par A33, remplacée en partie par A45) | 75 |
| A23 | Cible sur la résolution physique complète ; échec → « un fichier hors du lab » | 75 |
| A24 | Outils comptés : `Read` en lecture ; `Write`, `Edit`, `MultiEdit`, `NotebookEdit` en écriture | 75 |
| A25 | Index, état, frise, cibles, verrous, plan de mission jamais dans l'export ; témoin à marqueur | 75 |
| A26 | `/api/vf/activite` par une ligne de table et la réponse gardée | 75 |
| A27 | `graphe?onglet=code` sert le `graph.json` construit ; annotateurs inscrits d'une ligne | 75 |
| A28 | `GET /api/vf/frise?champs=cibles` | 75 |
| A29 | `projet.json` écrit dans la sortie pour l'outil de requête | recherche (79) |
| A30 | Cycle de vie d'un onglet : `VF_COQUILLE.surOnglet(rappel)` ; règle commune aux extensions | 80, toute phase |
| A31 | Une collecte lue en mémoire : `vf-cockpit-instantane.mjs` (`instantane()`, `surInstantane()`) | 75, 76, 77, toute phase |
| A32 | Donnée de planning manquante ajoutée dans la lecture du planning de la collecte | 75 |
| A33 | Cible quand le lab est un sous-dossier du dépôt | 75 |
| A34 | Portail d'accès unique de `serve.mjs`, vérificateur intérieur, routes antérieures hors garde, module `vf-cockpit-routes.mjs` | 79-05 (planification) |
| A35 | Module `vf-cockpit-index-cache.mjs`, curseur complet, `rattachement` non persisté, bornes de sûreté | 79-08 (planification) |
| A36 | Verbe `registry`, `leaseS` et `sansSession`, `hello.lock` avant la première collecte, cache de scan par fichier | 79-09 (planification) |
| A37 | Une seule règle de chemin ; `test-cockpit-confinement.sh` touché par 79-06 seul en vague 2 | 79-06, 79-07, 79-16 (vérification fraîche) |
| A38 | Route `GET /api/vf/state` dans `vf-cockpit-state.mjs`, `/api/vf/etat` intacte ; limite des chemins absolus du schéma `@1` | 79-12 (planification) |

Amendements A39 à A53, avec les plans des autres phases à retoucher (relevés au journal du manager et au relevé
du manager en fin de mission ; « aucun relevé » là où rien n'est connu) :

| Id | Objet | Phase demandeuse | Plans des autres phases à retoucher |
|---|---|---|---|
| A39 | `ageS` = âge du dernier battement ; `leaseS` = temps depuis la prise | 73 | 73-04 (lisait `progressAgeS` en attendant ; doit lire `leaseS`) |
| A40 | Seconde extension de CSP : `script-src` et `worker-src` au préfixe `/_vf/` du module, liste fermée ; amende P79-D-15 | 79-16, 79-18 (vérification fraîche) | aucun plan à retoucher, sauf un plan des Phases 73, 74, 75 ou 80 qui supposerait un script en ligne ou l'origine `'self'` (un `ui/*.js` ajouté est servi sous `/_vf/` par la liste calculée au démarrage) |
| A41 | Service statique de la sortie retiré | 79-16 | aucun relevé |
| A42 | Réglage d'essai `VF_COCKPIT_DONNEES_GABARIT` ; pages en parties transitoires | 79-15 | aucun relevé |
| A43 | Écarts du lot 4 : tiroir rangé, attente de permission en segment de queue, `cibles` null pour forme inconnue, 500 voies, cible à 120 caractères, transcript à la même règle de chemin, porte `window.VF_FLUX`, deux flux pour deux origines, constats de Santé inchangés | 79-10, 79-11, 79-13, 79-14 | Phase 74 (lecteur et fiche : forme des cibles, chemin résolu dans le transcript ; relayé) ; Phase 75 (cibles) ; Phase 80 (constats de Santé laissés à AUDC-M8) — numéros de plans non relevés |
| A44 | Motifs R et P gardés en 79-10 ; `lib/vf-glob.mjs` ; plafond effectif de 299 lignes | 79-10, 79-21, tous | tout plan d'une autre phase qui vise « moins de 300 lignes » sur un fichier du module doit viser 299 — numéros non relevés |
| A45 | S-3 tranchée (P79-D-33) : cibles `{ arbre, cible, n, dernierMs }`, `arbre` = null ou `nom` de worktree prouvé | session principale (arbitrage) | Phase 75 (radar joint sur (`arbre`, `cible`)), Phase 73 (vue des worktrees), Phase 74 (fiche, transcript) — relayé par la session principale ; numéros non relevés |
| A46 | `nom` de worktree non unique (fermé par défaut : non admis) ; dernière action limitée à l'arbre principal | 79-13 | Phase 75 (collision), Phase 73 (régie : dernière action) — numéros non relevés |
| A47 | `instantane()` porte `git: { sig, at }` ; `instantane().frise` jusqu'à 2 000 voies avec `tronque`, 500 voies pour la seule réponse HTTP (livré par 79-09 et 79-13) | 75 | Phase 75 : 75-05 (`/api/vf/activite`) |
| A48 | Réponses aux points 41 à 50 de la 74 : copie du module mutable dans les suites, `ui/` neuf servi sans changer la CSP, cible coupée par `…`, `cibles.tronque` par voie, `voiesOmises`, transcript et détail par la table en mémoire (→ 79-22), `frise` une fois par tour | 74 | Phase 74 : 74-02 ; Phase 77 : 77-07 |
| A49 | Écarts propres aux plans de fin de phase (79-15 à 79-19) retenus tels qu'écrits ; aucun ne touche C0 à C6 | 79 (vérification fraîche) | aucun |
| A50 | Précisions d'A48 : `tronque` aussi au plafond de 20 000 entrées, corps `inconnu` dans quatre cas bornés, `frise` une fois par tour, module neuf `vf-cockpit-agents-table.mjs` | 79-13 (retouche A48) | Phase 74 (plans non relevés) |
| A51 | `VF_COQUILLE.surOnglet(rappel, { cle })` : une inscription de même `cle` remplace la précédente, nettoyage appelé avant ; idiome `cle` = nom du fichier | 73, toute phase | Phase 73 : 73-05 ; Phases 74, 75, 76, 77, 80 : leurs extensions `ui/` s'inscrivent par `surOnglet(…, { cle })` (plans non relevés) |
| A52 | Liste `EVENEMENTS` à repères par phase (`// vf-repere:phase-NN`) ; `ROUTES`, `ANNOTATEURS`, lignes `AJOUT` alphabétiques sans repère ; ancres de `vf-cockpit-interface.json` | 79-14 (fusion avec la 80) | Phase 80 : 80-03, 80-06 ; toute phase qui ajoute une ligne `AJOUT`, une route ou un nom d'`EVENEMENTS` |
| A53 | Scripts persistants de la coquille : marqueur `vf-coquille: persistant`, trois conditions, aucune liste fermée, ordre de premier chargement garanti ; 79-16 part de la base où 80-02 est fusionné | 80, toute phase | Phase 80 : 80-02, 80-10 |

- **A54** (73 à 77, 80) : ajouter une route ou un annotateur — listes RK.1 et AN.1 de `test-cockpit-routes.sh` écrites à la main, sondes RK.7 dérivées de `ROUTES` ; la phase porte la suite dans ses `files_modified`, constate le rouge, insère à sa place alphabétique, exige PASS RK.1, RK.7 (AN.1). Autres phases à retoucher : 75 (`/api/vf/activite`), 76 (`/api/vf/tracabilite`), 77 (`/api/vf/methode`), toute phase qui ajoute un annotateur.

- **A55** (80, toute phase) : échec d'un chargement d'onglet, premier compris — `VF_COQUILLE.etat()`, événement annulable `vf:coquille-echec` `{ onglet, initial }`, message fixe et « Réessayer » de la coquille si personne n'annule ; autres phases : 80 (80-21).

## Décisions

Toutes « décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée », sauf P79-D-33.

- **P79-D-01 (contrats)** — C0 à C6 figés ; un écart se consigne en amendement daté. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-02 (route d'état)** — enveloppe `cockpit-state@1` autour d'un `cockpit-signal@1` inchangé. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-03 (index)** — cache du lab, non fiable à la lecture, un écrivain, 24 h, sans cible. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-04 (cibles)** — en mémoire seulement (AUDC-Q2 en vigueur) ; question S-1. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-05 (coût)** — sur la fenêtre de 24 h ; question S-2. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-06 (amendements)** — A1 à A28 retenus tels qu'écrits, aucun retour refusé. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-07 (fork, AUDC-H5)** — appareil de patchs retiré en vague 1 (79-01), `VENDORED.txt` réduit, `DESIGN.md` § 9 réécrit. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-08 (renommage, AUDC-AM4)** — noms VibeFlow écrits une fois dans les six sources Node ; pages renommées comme du texte ; renommage complet après la fusion de la 80 (BACKLOG). Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-09 (code depuis le module, AUDC-A-03)** — `serve.mjs` du module avec `--sortie=` en dernier argument ; confinement de « Demander » remesuré ; dépendance dure avec C5. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-10 (empreinte et orphelin, H3, D-M13)** — une fonction d'empreinte pour tout le code évalué ; `status` et `stop` voient l'orphelin ; filtre d'hygiène jamais vide. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-11 (classe A-02, D-M15, A-04)** — résolution physique complète, fonction unique, preuve générative ; pilotes nommés vidés pour tout lancement de git. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-12 (collecte hors boucle, H2)** — un collecteur dans un `worker_threads`, garde au point d'émission ; p99 < 50 ms. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-13 (segments, D9)** — règle de typage des segments entre deux horodatages ; « bloqué » lu dans l'état officiel. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-14 (flux partagé, H1, D-M2)** — `BroadcastChannel` + élection par Web Locks, repli un flux par page, veille de 45 s. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-15 (mise en page en worker, AM3, M7)** — worker servi par le module, jamais `blob:` ; amendée par A40 (deux extensions de CSP). Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-16 (traduction au point d'émission, H4)** — chaînes du moteur en français dans leurs fichiers, observateur global retiré. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-17 (registre du verrou, D5)** — archive au relâchement, 24 h, 2 000 lignes, verbe `registry`. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-18 (nœud dans le mandat, I37)** — ligne `- Nœud :` au gabarit du digest et règle au kernel, jamais dans un corps d'agent. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-19 (plafond en colonnes, AM5)** — 160 colonnes en cliquet par fichier, code navigateur sérialisé rangé en fichiers. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-20 (socle de test, AM7)** — `socle-serveur.sh` en vague 1 ; pas de migration en masse (révisée par P79-D-23). Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-21 (démarrage, AB1)** — `claude --version` en asynchrone, cache du scan par date de modification. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-22 (journal des hooks, I18)** — journal d'attente minimal, détachable, en dernière vague, précédé d'une sonde. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-23 (aide de lancement, AM7)** — migration des suites qui lancent le serveur en une fois au plan 79-02. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-24 (`?lang=en`)** — gardé (P67-D-20, P70-D-03) : la clé anglaise est rendue. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-25 (plafond de 300 lignes)** — dur ; un fichier proche du plafond ne grossit que par extraction. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-26 (transition)** — ancienne forme de serveur reconnue une version ; purge du code laissé dans la sortie. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-27 (documentation)** — 79-20 seul touche CHANGELOG, README, `VERSION` et `module.json` du module ; version mineure sans release (ADR-073, gel). Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-28 (79-03)** — `registry --all` et deux variables de réglage de la rétention pour les suites. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-29 (rétention des voies, 79-08)** — au-delà de 24 h seulement si l'état officiel dit la voie vivante. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-30 (mesure de forme, 79-08)** — tâche automatique à précondition (version et au moins 20 transcripts récents) ; sinon arrêt et remontée. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-31 (empreinte, 79-06)** — calculée sur les fichiers de code du module trouvés à l'exécution, jamais une liste figée. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-32 (`compileGlob`, constat de la Phase 75)** — coût borné au point unique, plan neuf 79-21, preuve générative. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.
- **P79-D-33 (S-3, A45)** — un worktree prouvé du même dépôt compte comme le lab ; réponse cochée « Les compter comme le lab (Recommandé) ». Arbitrage Samuel, AskUserQuestion session principale, 2026-11-11.

## À Samuel

Format C76-Q1 (contrat de la Phase 76), tel que posé dans `79-CONTEXT.md` § « À Samuel ». Aucune ne bloque.

- **P79-Q-01 (S-1) — Persister les cibles réduites dans l'index ?** Appliquée : option (a), cibles en mémoire,
  reconstruites au démarrage (radar incomplet quelques secondes) — décision déléguée par Samuel (message session
  principale, 2026-11-08), P79-D-04. Samuel peut la rouvrir pour (b).
- **P79-Q-02 (S-2) — Coût par phase au-delà de 24 h (Phase 77) ?** Appliquée : option (a), fenêtre de 24 h —
  décision déléguée par Samuel (message session principale, 2026-11-08), P79-D-05. (b), agrégat persisté, à
  instruire avec la 77 si le coût sur 24 h ne répond pas.
- **P79-Q-03 (S-3) — Écriture dans un worktree hors du dossier du lab.** Tranchée : option (b), P79-D-33 / A45
  (arbitrage Samuel, AskUserQuestion session principale, 2026-11-11). Limites nommées en A46.
- **P79-Q-04 (S-4) — Réduire AUDC-I18 ?** En attente, modification de périmètre. La sonde, première tâche de 79-19,
  dit si `claude agents --json` voit déjà une attente de permission. Recommandation : (b) retirer I18 sur sonde
  verte, garder la forme minimale sinon.

Limites qui appellent son avis :

- Chemins absolus `signal.root`, `equipe.root`, `equipe.workers[].cwd` servis comme aujourd'hui ; les masquer
  demande un schéma `@2` (A38, BACKLOG).
- `127.0.0.1` et `localhost` restent deux origines, donc deux flux (A43).
- Messages de `serve.mjs` en français même sous `?lang=en` (A43).
- Pose projet ou locale : le module vit sous `.claude/` du lab ; la garantie devient « la sortie n'est jamais source
  de code » (P79-D-09).
- Mesure du confinement de « Demander » : un verdict « non confinable » remonte à Samuel (SOCL-09).

## Carte des fichiers

Abréviations : `S/` = `plugin/cockpit/scripts/`, `M/` = `plugin/cockpit/skills/cockpit-moteur/`, `T/` = `S/tests/`,
`P/` = dossier de la phase. Source : frontmatters `files_modified` des 22 plans, relus à la tête `677d19fa`.

### (a) Fichiers partagés avec d'autres phases

**Règle de fusion avec la Phase 80** (exécutée en parallèle ; A52, A53, commit `8e7afec1`) :

- `S/vf-cockpit-interface.json` : ancres fixes de 79-08 — le bloc `vibeflow/cockpit-index@1` s'insère après
  `vibeflow/cockpit-transcript@2`, le bloc `claudeCode.index` après `transcriptSousAgent` ; le bloc
  `vibeflow/cockpit-project@1` n'est pas touché par la 79.
- Lignes `AJOUT` de `M/VENDORED.txt`, table `ROUTES` (`S/vf-cockpit-routes.mjs`) et table `ANNOTATEURS`
  (`S/vf-cockpit-build.mjs`) : ordre alphabétique contrôlé, **sans repère**.
- Liste `EVENEMENTS` de `M/assets/ui/69-vf-flux.js` (79-14) : la seule à porter des repères, sous ce texte exact —
  `// vf-repere-regle : chaque phase insère ses noms derrière son repère ; les repères sont retirés à la clôture du jalon.`
  suivi de `// vf-repere:phase-73`, `// vf-repere:phase-74`, `// vf-repere:phase-75`, `// vf-repere:phase-76`,
  `// vf-repere:phase-77`, `// vf-repere:phase-80`, `// vf-repere:phase-81`.
- Précondition : 79-14, 79-16 et 79-18 partent d'une base où les vagues 1 à 3 de la Phase 80 sont fusionnées ;
  79-16 reprend `ui/` tel que 80-02 le livre, marqueur `vf-coquille: persistant` compris (A53).
- **79-19 et 79-20 ne touchent ni `viewer.html` ni la coquille** (`vf-coquille*.js`, `S/vf-cockpit-coquille*.mjs`) :
  vérifié sur leurs `files_modified`. `viewer.html` n'est touché que par 79-10, 79-16 et 79-18 ; la coquille par
  79-16 (et `S/vf-cockpit-coquille-assets.mjs` par 79-18).

| Fichier | Plans 79 | Phases concernées | Règle |
|---|---|---|---|
| `M/assets/viewer.html` | 79-10, 79-16, 79-18 (79-01 retire son diff) | 80, 73 | hunks ciblés, un commit par fichier en 79-10 ; garder la suppression d'`amont/` |
| `M/assets/serve.mjs` | 79-06, 79-10, 79-15, 79-16, 79-18 | 80, 74 | la 74 lit C3, ne crée pas de route |
| `M/VENDORED.txt` | 79-01, 79-11, 79-14, 79-16, 79-17, 79-18, 79-21 | 73, 74, 75, 80 (tout `ui/` ajouté) | après 79-01 : une ligne `AJOUT` par fichier, plus de diff |
| `plugin/cockpit/amont/**` (22 fichiers) | 79-01 (retrait) | 80, 73 | avant le merge de 79-01 une phase régénère son diff ; après, conflit résolu en gardant la suppression |
| Dictionnaire FR : `M/assets/ui/79-vf-fr-dict-b.js`, `M/assets/ui/80-vf-fr.js`, `S/vf-cockpit-fr-exclusions.json`, `S/vf-cockpit-fr-inventaire.mjs` | 79-10 (les quatre) ; 79-01 et 79-06 (inventaire) ; `78-vf-fr-dict-a.js` non touché | 80, 73, 74 | toute chaîne neuve s'écrit `t('texte anglais')` avec son entrée au dictionnaire |
| CHANGELOG, README, `VERSION`, `module.json` du module cockpit | 79-20 seul (P79-D-27), aucun autre plan | 73, 74, 75, 77, 80 | section « Non publié », ajouts en fin de section |
| Compteur de suites de `README.md` et `README.fr.md` racine | 79-05, 79-08, 79-09, 79-12, 79-13, 79-15, 79-16, 79-17, 79-18, 79-19, 79-20 | toute phase qui ajoute une suite | nombre réel du gate relu au merge, jamais un littéral |
| `T/test-cockpit-vendor.sh` | 79-01, 79-11, 79-20 | 80 (tout fichier du moteur ajouté) | une vague par plan, sections disjointes |
| `M/assets/ui/70-vf-live.js` | 79-09, 79-14, 79-17 | 73, 74 | 79-14 extrait la connexion : rebaser dessus |
| `S/vf-cockpit-server.mjs` | 79-05, 79-06, 79-09, 79-12, 79-13, 79-15, 79-16, 79-22 | 73, 74, 75, 76, 77 | une route = une ligne de table (A10) + réponse gardée (A11) |
| `S/vf-cockpit-live.mjs` | 79-09, 79-15 | 73, 74, 75, 80 (A5) | la collecte passe par le fil ; la 80 n'y touche pas |
| `S/vf-cockpit-interface.json` | 79-08, 79-09, 79-12, 79-13 | 73, 74, 80 | blocs neufs aux ancres d'A52 ; `cockpit-who@2` : seuls les ajouts d'A20 |
| `DESIGN.md` racine | 79-01 (§ 9) | 80 | ligne isolée |
| Collecte : `S/vf-cockpit-collecte*.mjs`, `S/vf-cockpit-instantane.mjs` | 79-09 (crée), 79-13, 79-22 (collecte seule) | 75, 76, 77 (lecture par A31, A47) | lecture en mémoire, jamais de collecte par requête |
| `M/assets/ui/69-vf-flux.js` | 79-14 (crée), 79-15, 79-16 | 73, 74, 75, 76, 77, 80, 81 | noms d'événements derrière le repère de sa phase (A52) |
| `S/vf-cockpit-who.mjs` | 79-09, 79-22 | 73 | ordre libre (A17, A18) |
| `S/vf-cockpit-equipe.mjs`, `S/vf-cockpit-etat-officiel.mjs` | 79-09 | 73 | ordre libre (A17, A18) |
| `S/vf-cockpit-build.mjs` | 79-05, 79-06, 79-09, 79-15 | 75 | un annotateur = une ligne (A27) |
| `T/socle-serveur.sh` | 79-02, 79-06, 79-11, 79-16, 79-18 | 80 | signature d'A6 fixe |
| `S/vf-cockpit-transcript.mjs` | 79-13 | 74 | rebaser sur la reprise de `cheminDuLab` |
| `plugin/conductor/scripts/driver-lock.sh` | 79-03 | 73 | lecture seule côté 73 |

### (b) Ordre des vagues

| Vague | Plans (découpage final) | Frontmatter `wave` relu |
|---|---|---|
| 1 | 79-01, 79-02, 79-03, 79-05 | conforme |
| 2 | 79-04, 79-06, 79-07, 79-08 | conforme |
| 3 | 79-09, 79-10, 79-21 | conforme |
| 4 | 79-11, 79-12 | conforme |
| 5 | 79-13, 79-14 | conforme |
| 6 | 79-15 | conforme |
| 7 | 79-16 | conforme |
| 8 | 79-17, 79-22 | conforme |
| 9 | 79-18 | conforme |
| 10 | 79-19 | conforme |
| 11 | 79-20 | conforme |

Les 22 `wave` relus sur les frontmatters sont ceux du découpage. Aucune vague n'a de fichier commun, sauf le
recouvrement nommé de la vague 1 (79-02 et 79-05 sur `T/test-cockpit-lancer-mode.sh`, hunks disjoints) ; 79-17 et
79-22 (vague 8) n'ont aucun fichier commun (comparaison des `files_modified`).

Écarts mineurs de `depends_on` entre frontmatter et découpage, sans effet sur l'ordre des vagues :

- 79-16 déclare `["79-11", "79-15"]`, le découpage dit 79-15 seul (79-11 est en vague 4, déjà fusionnée).
- 79-20 déclare les vingt plans 79-01 à 79-19 et 79-21, le découpage dit « tous » : **79-22 n'y est pas** (vague 8,
  donc fusionnée avant la vague 11 de toute façon).

### (c) Fichiers par plan

| Plan | Nb | Fichiers créés ou modifiés |
|---|---|---|
| 79-01 | 29 | `plugin/cockpit/amont/**` (22 fichiers retirés), `M/VENDORED.txt`, `T/test-cockpit-vendor.sh`, `T/test-cockpit-questions.sh`, `T/test-cockpit-git-env.sh`, `S/vf-cockpit-fr-inventaire.mjs`, `DESIGN.md`, `P/79-01-RED-TRACE.md` |
| 79-02 | 45 | `T/socle-serveur.sh`, 43 suites `T/test-cockpit-*.sh` (accessibilite, assemblage, chaine-xss, chrome-fr, cycle-serveur, demander-bornes, direct-coupe, direct, equipe, flux-unique, fr-donnees, git-details, git-e2e, git-entete, git-signature, git-tiroir, git, lancer-bout-en-bout, lancer-chat, lancer-mode, lancer-serveur, lancer-xss, marque-blanche, moteur-carte, path-enfants, reconnexion, reseau, responsive, robustesse, securite, serveur, terminal-activation, terminal-client, terminal-fin, terminal-page, terminal-pty, terminal-serveur, terminal-session, terminal-tiroir, terminal-xss, terminal-xterm, transcript, who), `P/79-02-RED-TRACE.md` |
| 79-03 | 8 | `plugin/conductor/scripts/driver-lock.sh`, `plugin/conductor/scripts/tests/test-driver-lock.sh`, `…/test-driver-lock-phase.sh`, `plugin/conductor/` `VERSION`, `module.json`, `CHANGELOG.md`, `README.md`, `P/79-03-RED-TRACE.md` |
| 79-04 | 12 | `plugin/dev-orchestrator/references/mission-contracts.md`, `plugin/conductor/references/team-kernel.md`, `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh`, `plugin/dev-orchestrator/` et `plugin/conductor/` (`VERSION`, `module.json`, `CHANGELOG.md`, `README.md`), `P/79-04-RED-TRACE.md` |
| 79-05 | 8 | `S/vf-cockpit-routes.mjs`, `S/vf-cockpit-server.mjs`, `S/vf-cockpit-build.mjs`, `T/test-cockpit-routes.sh`, `T/test-cockpit-lancer-mode.sh`, `README.md`, `README.fr.md`, `P/79-05-RED-TRACE.md` |
| 79-06 | 55 | `S/` : `vf-cockpit-module.mjs`, `-serveur-vivant.mjs`, `vf-cockpit.mjs`, `-lanceur-verrou.mjs`, `-build.mjs`, `-embed.mjs`, `-rename.mjs`, `-lancer-post.mjs`, `-server.mjs`, `-query.mjs`, `-agent.mjs`, `-ask.mjs`, `-terminal.mjs`, `-fr-inventaire.mjs` ; `M/assets/serve.mjs`, `M/assets/graph-query.js`, `M/assets/query-cli.mjs`, `M/scripts/build.mjs` ; `T/socle-serveur.sh` et 33 suites `T/test-cockpit-*.sh` ; `plugin/_internal/tests/test-vibeflow-update-cockpit.sh` ; `P/79-06-RED-TRACE.md`, `P/79-MESURE-claude-p.md` |
| 79-07 | 10 | `S/vf-cockpit-git-sortant.mjs`, `M/scripts/lib/vf-git-sortant.mjs`, `M/scripts/scan.mjs`, `S/vf-cockpit-paths.mjs`, `S/vf-cockpit-git-lanceur.mjs`, `S/vf-cockpit-git-durci.mjs`, `S/vf-cockpit-git-details.mjs`, `T/test-cockpit-git-config-depot.sh`, `T/test-cockpit-git-env.sh`, `P/79-07-RED-TRACE.md` |
| 79-08 | 20 | `S/vf-cockpit-jetons.mjs`, `-index-voie.mjs`, `-index-cache.mjs`, `-index.mjs`, `S/vf-cockpit-interface.json`, `T/test-cockpit-index.sh`, `T/index-generateur.mjs`, `T/index-propriete.mjs`, `T/test-cockpit-forme-claude.sh`, 7 fichiers de fixture `T/fixtures/test-cockpit-index/`, `README.md`, `README.fr.md`, `P/79-08-RED-TRACE.md`, `P/79-08-MESURE-FORME.md` |
| 79-09 | 37 | `S/` : `vf-cockpit-collecte.mjs`, `-collecte-fil.mjs`, `-collecte-etapes.mjs`, `-collecte-index.mjs`, `-instantane.mjs`, `-registre.mjs`, `-voies-rattachement.mjs`, `-who-signature.mjs`, `-code-cache.mjs`, `-live.mjs`, `-server.mjs`, `-who.mjs`, `-equipe.mjs`, `-etat-officiel.mjs`, `-vie.mjs`, `-signal.mjs`, `-build.mjs`, `-interface.json` ; `M/assets/ui/70-vf-live.js` ; `T/test-cockpit-collecte.sh` et 8 aides `T/collecte-*.mjs` ; `T/test-cockpit-cycle-serveur.sh`, `-who.sh`, `-equipe.sh`, `-robustesse.sh`, `T/chrome-verrou.mjs`, `T/chrome-verrou-prefixe.mjs` ; `README.md`, `README.fr.md`, `P/79-09-RED-TRACE.md` |
| 79-10 | 21 | `M/assets/viewer.html`, `M/assets/serve.mjs`, `M/assets/ui/` `05-theme.js`, `10-glossary.js`, `20-health.js`, `25-recent.js`, `30-screens.js`, `40-tour.js`, `60-export.js`, `79-vf-fr-dict-b.js`, `80-vf-fr.js` ; `M/scripts/build.mjs` ; `S/vf-cockpit-fr-inventaire.mjs`, `-fr-sources.mjs`, `-fr-exclusions.json` ; `T/test-cockpit-chrome-fr.sh`, `T/test-cockpit-fr-donnees.sh`, `T/chrome-fr-donnees.mjs`, `T/chrome-fr-etats.mjs` ; `P/79-10-RED-TRACE.md`, `P/79-10-RENDU-AVANT.json` |
| 79-11 | 43 | `T/test-cockpit-vendor.sh`, `T/colonnes-cliquet.mjs`, `T/colonnes-baseline.txt`, `T/releve-pages-terminal.mjs`, `T/navigateur-charger.mjs`, `T/socle-serveur.sh` ; 11 modules `S/vf-cockpit-navigateur.mjs`, `-module.mjs`, `-terminal-*.mjs`, `-lancer-ui.mjs`, `-lancer-style.mjs` ; `M/VENDORED.txt` ; `M/assets/ui/terminal/` (3) et `M/assets/ui/tiroir/` (9) ; 12 suites `T/test-cockpit-terminal-*`, `-lancer-*`, `-chrome-fr.sh` ; `P/79-11-RED-TRACE.md` |
| 79-12 | 16 | `S/vf-cockpit-state.mjs`, `-flux-etat.mjs`, `-signal-serveur.mjs`, `-server.mjs`, `-signal.mjs`, `-interface.json` ; `T/test-cockpit-etat.sh` et 5 aides `T/etat-*.mjs` ; `T/test-cockpit-routes.sh` ; `README.md`, `README.fr.md`, `P/79-12-RED-TRACE.md` |
| 79-13 | 23 | `S/vf-cockpit-cible.mjs`, `-cibles.mjs`, `-cibles-suivi.mjs`, `-frise-voie.mjs`, `-frise.mjs`, `-frise-direct.mjs`, `-collecte-frise.mjs`, `-instantane.mjs`, `-collecte.mjs`, `-collecte-fil.mjs`, `-collecte-etapes.mjs`, `-server.mjs`, `-transcript.mjs`, `-interface.json` ; `T/test-cockpit-frise.sh` et 3 aides `T/frise-*.mjs` ; `T/test-cockpit-routes.sh`, `T/test-cockpit-transcript.sh` ; `README.md`, `README.fr.md`, `P/79-13-RED-TRACE.md` |
| 79-14 | 17 | `M/assets/ui/69-vf-flux.js`, `M/assets/ui/70-vf-live.js`, `M/VENDORED.txt`, 5 aides `T/chrome-*.mjs`, 4 aides `T/flux-*.mjs`, `T/test-cockpit-flux-unique.sh`, `-direct-coupe.sh`, `-reconnexion.sh`, `-equipe.sh`, `P/79-14-RED-TRACE.md` |
| 79-15 | 24 | `S/vf-cockpit-graphe.mjs`, `-graphe-fichier.mjs`, `-graphe-route.mjs`, `-pages.mjs`, `-server.mjs`, `-live.mjs`, `-embed.mjs`, `-query.mjs`, `-build.mjs` ; `M/assets/serve.mjs`, `M/assets/ui/69-vf-flux.js` ; `T/test-cockpit-graphe.sh` et 3 aides `T/graphe-*.mjs` ; `T/test-cockpit-direct.sh`, `-git-entete.sh`, `-securite.sh`, `-demander-bornes.sh`, `-serveur.sh`, `-assemblage.sh` ; `README.md`, `README.fr.md`, `P/79-15-RED-TRACE.md` |
| 79-16 | 39 | `S/vf-cockpit-coquille.mjs`, `-coquille-assets.mjs`, `-pages.mjs`, `-server.mjs`, `-module.mjs`, `-serveur-vivant.mjs` ; `M/assets/serve.mjs`, `M/assets/viewer.html`, `M/assets/vf-coquille.js`, `M/assets/vf-coquille-portee.js`, `M/assets/ui/69-vf-flux.js`, `M/VENDORED.txt` ; `T/test-cockpit-coquille.sh` et 4 aides `T/coquille-*.mjs` ; `T/socle-serveur.sh`, `T/chrome-session.mjs`, `T/terminal-aux.mjs` ; 16 suites `T/test-cockpit-*.sh` retouchées ; `README.md`, `README.fr.md`, `P/79-16-RED-TRACE.md` |
| 79-17 | 16 | `M/assets/ui/70-vf-etat.js`, `70-vf-live.js`, `72-vf-equipe.js`, `76-vf-git-entete.js`, `M/VENDORED.txt` ; `T/test-cockpit-magasin.sh` et 3 aides `T/magasin-*.mjs`, `T/reposer-chrome.mjs`, `T/observateurs-cliquet.mjs`, `T/observateurs-baseline.txt`, `T/test-cockpit-equipe.sh` ; `README.md`, `README.fr.md`, `P/79-17-RED-TRACE.md` |
| 79-18 | 17 | `M/assets/elk-fil.js`, `M/assets/viewer.html`, `M/assets/serve.mjs`, `M/VENDORED.txt`, `S/vf-cockpit-mise-en-page.mjs`, `S/vf-cockpit-coquille-assets.mjs`, `T/test-cockpit-mise-en-page.sh` et 3 aides `T/mise-en-page-*.mjs`, `T/socle-serveur.sh`, `T/terminal-aux.mjs`, `T/test-cockpit-coquille.sh`, `T/chrome-accessibilite.mjs`, `README.md`, `README.fr.md`, `P/79-18-RED-TRACE.md` |
| 79-19 | 12 | `plugin/cockpit/hooks/hooks.json`, `S/vf-cockpit-attentes.mjs`, `S/vf-cockpit-attentes.sh`, `T/test-cockpit-journal-attentes.sh`, `T/journal-attentes-pose.mjs`, `T/journal-attentes-charges.mjs`, `T/test-cockpit-signal-mod.sh`, `docs/HOOKS-CONTRAT-SORTIE.md`, `README.md`, `README.fr.md`, `P/79-19-SONDE-S0.md`, `P/79-19-RED-TRACE.md` |
| 79-20 | 9 | `plugin/cockpit/README.md`, `plugin/cockpit/CHANGELOG.md`, `plugin/cockpit/VERSION`, `plugin/cockpit/module.json`, `T/test-cockpit-vendor.sh`, `T/doc-chiffres.sh`, `README.md`, `README.fr.md`, `P/79-20-RED-TRACE.md` |
| 79-21 | 5 | `M/scripts/lib/common.mjs`, `M/scripts/lib/vf-glob.mjs`, `M/VENDORED.txt`, `T/test-cockpit-confinement.sh`, `P/79-21-RED-TRACE.md` |
| 79-22 | 11 | `S/vf-cockpit-agents-table.mjs`, `S/vf-cockpit-who.mjs`, `S/vf-cockpit-collecte.mjs`, `-collecte-fil.mjs`, `-collecte-etapes.mjs`, `S/vf-cockpit-server.mjs`, `T/test-cockpit-frise.sh`, `T/frise-agents.mjs`, `T/test-cockpit-serveur.sh`, `T/test-cockpit-transcript.sh`, `P/79-22-RED-TRACE.md` |

### (d) Ce que la 79 attend d'une autre phase et ce qu'elle lui fournit

| Phase | La 79 attend d'elle | La 79 lui fournit |
|---|---|---|
| 73 | rien de bloquant (la 73 part du lot 0, AUDC-V3) ; ses ajouts en fin de `vf-cockpit-etat-officiel.mjs` et dans `cockpit-who@2` (A17, A18) ; retouches à faire chez elle : 73-04 lit `leaseS` (A39), 73-05 s'inscrit par `surOnglet(…, { cle })` (A51), vue des worktrees (A45), dernière action (A46) ; ses noms d'événements derrière `// vf-repere:phase-73` (A52) | C2, C4, verrous projetés en liste blanche (A15, 79-09), plan de mission publié (A16, 79-03 et 79-04), `leaseS` et `sansSession` (A36), `sortisSilence` et `finMotif` (A20), règle de routes (A10, A11) |
| 74 | mesure de la couverture des 24 h par la marche de 500 commits (A9) ; retouches du lecteur et de la fiche (A43, A45), de 74-02 (A48) et des plans touchés par A50 ; suite `test-cockpit-frise-vue.sh` chez elle (A48, point 50) | C1 (index, jetons sans étendre le contrat : C6), C3 (frise, 79-13 : `cibles.tronque`, `voiesOmises`), transcript et détail par la table en mémoire (79-22, A48, A50), `rattachement` (A8, A14), copie du module mutable dans les suites (A48, point 41) |
| 75 | sa route `/api/vf/activite` par une ligne (A26) — 75-05 lit `instantane().git` (A47) —, son annotateur (A27), ses champs de planning dans la collecte (A32) ; radar joint sur (`arbre`, `cible`), collision (A45, A46) ; plafond de 299 lignes (A44) | `cibles` (A21 à A24, A28, A33, A45), instantané en mémoire avec `git` et frise à 2 000 voies (A31, A47), coût borné de `compileGlob` (79-21, P79-D-32) |
| 76 | ses routes par la table et la réponse gardée (A10, A11) ; extensions `ui/` par `surOnglet(…, { cle })` (A51) | point de lecture confiné unique (A12), `VF_ETAT.jeton()`, `VF_ETAT.lireJson()`, clé `planning` (A13, 79-17), instantané (A31) |
| 77 | réponse à P79-Q-02 si le coût sur 24 h ne suffit pas ; retouche de 77-07 (A48) | voie du manager rattachée par ses enfants (A14), instantané (A31), table des routes (A10, A11) |
| 80 | vagues 1 à 3 fusionnées avant 79-14, 79-16 et 79-18 ; 80-02 livré avant 79-16 (A53) ; retouches de 80-02 et 80-10 (A53), 80-03 et 80-06 (A52) ; après sa fusion, le renommage complet des pages (P79-D-08, BACKLOG) ; constats de Santé à AUDC-M8 (A43) | coquille, `chargerOnglet`, `surOnglet` avec `cle`, scripts persistants (A1, A2, A30, A51, A53, 79-16), terminal posé une fois (A3), API du moteur avec le worker (A4, 79-18), événement `graphe` (A5, 79-15), `socle-serveur.sh` (A6, 79-02), ordre de retrait d'`amont/` (A7, 79-01), règle `t()` de traduction (79-10), repères d'`EVENEMENTS` (A52, 79-14) |

## À verser par la jointure

**ROADMAP — checklist** (remplace la ligne actuelle de la Phase 79) :

```
- [ ] **Phase 79: Socle du cockpit — une collecte, un flux, une route d'état** (inscrite 2026-11-11, jalon vibeflow-v2.0) — planifiée 2026-11-11, 22 plans en 11 vagues
```

**ROADMAP — table `## Progress`** (après la ligne de la Phase 78) :

```
| 79. Socle du cockpit — une collecte, un flux, une route d'état | vibeflow-v2.0 | 0/22 | Planned | - |
```

**ROADMAP et REQUIREMENTS — citations à mettre à jour :** l'encadré du corps de la Phase 79 au ROADMAP et l'en-tête
du bloc `SOCL` de REQUIREMENTS citent « amendements A1 à A48 » (et « P79-D-01 à D-33 » pour REQUIREMENTS) ; texte à
poser : « amendements A1 à A55, décisions P79-D-01 à P79-D-33 (P79-D-33 : arbitrage Samuel, AskUserQuestion session
principale, 2026-11-11) ».

**REGISTRE de l'audit** (`.planning/research/2026-11-10-audit-cockpit/REGISTRE.md`) — colonne « État » (§ 1, § 2),
« Destination » (constats nés du lot 0, § 3) :

| Ligne | Texte à poser |
|---|---|
| AUDC-D5 | remplacer « registre du verrou conservé après relâchement et nœud écrit dans le mandat restent à la Phase 79 » par « reste planifiée Phase 79, plans 79-03, 79-04 (lecture : 79-09) » |
| AUDC-D9 | planifiée Phase 79, plans 79-08, 79-13 (puis Phase 74) |
| AUDC-H1 | remplacer « flux partagé entre onglets à la Phase 79 » par « flux partagé entre onglets planifié Phase 79, plan 79-14 » |
| AUDC-H2 | remplacer « lectures asynchrones et cache à la Phase 79 » par « reste planifiée Phase 79, plans 79-09, 79-22 » |
| AUDC-H4 | remplacer « traduction au point d'émission à la Phase 79 » par « reste planifiée Phase 79, plan 79-10 » |
| AUDC-H5 | planifiée Phase 79, plan 79-01 |
| AUDC-AM1 | planifiée Phase 79, plans 79-12, 79-15 |
| AUDC-AM2 | planifiée Phase 79, plan 79-16 |
| AUDC-AM3 | planifiée Phase 79, plan 79-18 |
| AUDC-AM4 | planifiée Phase 79, plans 79-06, 79-16 |
| AUDC-AM5 | planifiée Phase 79, plan 79-11 |
| AUDC-AM6 | planifiée Phase 79, plan 79-17 |
| AUDC-AM7 | remplacer « socle de test partagé à la Phase 79 » par « socle de test partagé planifié Phase 79, plan 79-02 » |
| AUDC-AB1 | planifiée Phase 79, plans 79-06, 79-09 |
| AUDC-A-02 | remplacer « Suite : Phase 79, première vague » par « Suite : planifiée Phase 79, plan 79-07 » |
| AUDC-A-03 | planifiée Phase 79, plans 79-06, 79-16 |
| AUDC-M7 | remplacer « mise en page en worker à la Phase 79 » par « mise en page en worker planifiée Phase 79, plan 79-18 » |
| AUDC-I18 | planifiée Phase 79, plan 79-19 (forme réduite, question S-4) |
| AUDC-I19 | planifiée Phase 79, plan 79-12 |
| AUDC-I20 | planifiée Phase 79, plans 79-08, 79-13 |
| AUDC-I22 | planifiée Phase 79, plan 79-14 |
| AUDC-I31 | planifiée Phase 79, plans 79-15, 79-16 |
| AUDC-I32 | planifiée Phase 79, plan 79-17 |
| AUDC-I37 | planifiée Phase 79, plans 79-03, 79-04 |
| Lot 0, D-M2 | Phase 79, plans 79-12, 79-14 |
| Lot 0, D-M13 | Phase 79, plan 79-06 |
| Lot 0, D-M15 | Phase 79, plan 79-07 |
| Lot 0, H3 | Phase 79, plan 79-06 |
| Lot 0, A-04 | Phase 79, plan 79-07 |
| § 3, Équipe reconstruite à chaque requête | Phase 79, plan 79-15 |
| § 3, collecte refaite par `vf-signal` | Phase 79, plan 79-12 |
| § 3, copie renommée de 52 modules | Phase 79, plan 79-06 |

AUDC-H3 et AUDC-A-04 gardent leur état « fait » : leur reste est porté par les lignes du lot 0 ci-dessus.

**BACKLOG** — bloc neuf, même forme que celui du lot 0 :

```
## Cockpit : limites consignées par la Phase 79 — DIFFÉRÉ (2026-11-11)

**Origine :** cadrage de la Phase 79, `.planning/workstreams/fiabilite/phases/VFDO-79-socle-du-cockpit-une-collecte-un-flux-une-route-d-tat/79-CONTEXT.md`. Décisions déléguées par Samuel (message session principale, 2026-11-08), option recommandée.

### Chemins absolus dans la route d'état (A38)
**Priorité : moyenne.** `signal.root`, `equipe.root` et `equipe.workers[].cwd` restent des chemins absolus, de forme inchangée depuis la Phase 69, servis par `hello` et par `GET /api/vf/state`. Les masquer change la forme : schéma `@2`. **Déclencheur de reprise :** la prochaine version de `cockpit-signal` ou de `cockpit-who`.

### Renommage complet des pages et retrait de `vf-cockpit-rename.mjs` (P79-D-08)
**Priorité : basse.** La Phase 79 écrit les noms VibeFlow dans les sources exécutées par Node ; les pages restent renommées comme du texte. Le renommage complet de `viewer.html` et `ui/*.js`, puis le retrait de `vf-cockpit-rename.mjs`, se font en geste séparé. **Déclencheur de reprise :** la fusion de la Phase 80.

### Dernière action limitée à l'arbre principal, lab lui-même worktree lié (A46)
**Priorité : basse.** La dernière action d'un agent (`who`, `doing`) garde sa règle : un fichier d'un worktree hors de l'arbre principal y reste « un fichier hors du lab » ; l'étendre touche le collecteur `who`. Un lab qui est lui-même un worktree lié prend pour arbre principal le premier arbre de git, comme `who`. (Le `nom` de worktree non unique est fermé par défaut dans la phase : deux worktrees vérifiés au même `nom` ne sont pas admis.) **Déclencheur de reprise :** Phase 73 (régie).

### `127.0.0.1` et `localhost` tiennent deux flux (A43)
**Priorité : basse.** Deux origines distinctes : le flux partagé entre onglets ne les réunit pas. **Déclencheur de reprise :** la prochaine passe sur le flux partagé.

### Messages de `serve.mjs` en français sous `?lang=en` (A43)
**Priorité : basse.** Les messages du serveur sont écrits en français à la source et le restent en mode anglais. **Déclencheur de reprise :** la prochaine passe sur `?lang=en`.

### Identifiants de menace à aligner entre les plans de la Phase 79
**Priorité : basse.** Chaque plan numérote ses menaces dans sa propre plage (`T-79-1NN` pour 79-01, plan × 100 + rang) ; l'alignement de la forme entre les 22 plans n'a pas été vérifié à la planification. **Déclencheur de reprise :** l'audit de sécurité de la première vague exécutée.
```

Les entrées existantes du bloc « limites consignées par le lot 0 » dont le déclencheur est la Phase 79 (D-M2, D-M13,
D-M15, empreinte limitée à `serve.mjs`, AUDC-A-04, sixième onglet) gagnent leur plan : mêmes numéros que les lignes
du REGISTRE ci-dessus.

**Note STATE**, à poser par la session principale (STATE.md n'a pas été touché par la mission) :

```
- Phase 79 (socle du cockpit) : cadrée et planifiée le 2026-11-11 sur `feat/phase-79-socle-cockpit` (base `integration/cockpit-audit`), 22 plans en 11 vagues, SOCL-01..27 posées, contrats C0-C6 et amendements A1-A53 fournis aux Phases 73 à 77 et 80. P79-Q-03 (S-3) tranchée (P79-D-33, arbitrage Samuel, AskUserQuestion session principale, 2026-11-11) ; P79-Q-01 et Q-02 appliquées par décision déléguée ; P79-Q-04 (S-4, réduction d'I18) en attente, non bloquante. Aucune exécution ; rapport `.planning/missions/2026-11-11-phase-79-cadrage.md`.
```

Le compte « plans exécutés » du jalon est à recalculer à l'assemblage des sept cadrages (22 plans de la 79 s'y
ajoutent, non exécutés).

## Limites

- **E4 du gate de sortie** : manquant ou indéterminé, et c'est attendu. Les plans ne sont pas exécutés et STATE n'est
  pas marqué par la mission.
- **Plafond de sous-agents** : la limite de 20 sous-agents simultanés était partagée par les sept missions de
  cadrage. Deux lots ont été refusés au lancement puis lancés plus tard ; un lot a attendu environ 1 h 20 un
  planificateur ; un lot a rendu « blocked » sans rien écrire, relancé avec des lancements un par un. Limite levée à
  100 par Samuel en fin de mission (message session principale, 2026-11-11). Un planificateur de 79-07 s'est figé ;
  un second a repris sur le fichier existant.
- **Coupure de quota** : le quota du compte a coupé la mission vers 15 h 33 ; la reprise s'est faite sur un autre
  compte (cinq mandats `vf-coder` de reprise et de correction, cinq vérifications fraîches). Le journal du manager
  ne détaille pas ces passes.
- **Tailles des plans** : 79-06 (55 fichiers, dix tâches) est exécuté en trois sessions séparées par des points
  d'arrêt bloquants. 79-11, 79-15 et 79-19 se disent eux-mêmes au-dessus de la zone confortable et nomment leur coupe
  si l'exécution déborde. Ce sont des estimations hautes.
- **État de la planification au moment du rapport** : 22 plans commités, tête `677d19fa`, arbre de travail propre
  hors ce rapport. La carte est relue sur cet état.
- **Non vérifié** : le détail des cinq dernières vérifications fraîches n'est pas au journal ; les deux écarts de
  `depends_on` (79-16, 79-20 ; « Carte des fichiers », b) sont relevés ici, pas corrigés ; les identifiants de menace
  des plans restent à aligner (BACKLOG) ; les numéros de plans des autres phases pour A43 à A46, A50 et A51 (hors
  73-05) ne sont pas relevés ; aucune suite n'a été jouée (mission sans code).
- **Registre des agents incomplet** : trois planificateurs inscrits sur au moins 22 lancés (les lots ont inscrit
  irrégulièrement ; le lot 1 a inscrit quatre identifiants mal formés, fermés en `failed`) ; une vérification fraîche
  non inscrite (oubli du manager). Les comptes ci-dessous viennent des mandats émis, pas du registre.

## Coût

Comptés sur les mandats émis (journal et relevé du manager), jamais estimés :

| Rôle | Agents ou mandats | Détail |
|---|---|---|
| Éclaireurs (`general-purpose`, lecture seule) | 4 | 1 tour chacun |
| Panels de recherche (`gsd-advisor-researcher`) | 3 | 1 tour chacun |
| Recherche (`gsd-phase-researcher`) | 1 | 1 tour |
| Planification (`vf-coder`) | 11 mandats | 6 lots + 5 reprises ou passes de correction après la coupure ; reprises par message en cours de lot non comptées |
| Planificateurs (`gsd-planner`, lancés par les lots) | au moins 22 | d'après les rapports des lots ; registre incomplet (3 inscrits) |
| Vérifications fraîches (`gsd-plan-checker`, lancées par le manager) | 14 | 9 détaillées au journal, 5 après la coupure |
| Rédaction du rapport | 1 | 2 passes (rédaction, mise à jour à la tête `677d19fa`) |

Incidents de coût : plafond de 20 sous-agents simultanés (levé à 100), coupure de quota du compte vers 15 h 33
(reprise sur un autre compte), un planificateur figé, inscriptions irrégulières au registre des agents.

## Preuves E6

Format : verdict, commande, code de sortie, SHA de la tête au moment du verdict (commandes rejouées sur la tête d4d0cd41).

```json
{
 "preuves": [
  {"verdict": "state:inchange", "commande": "git diff --quiet origin/integration/cockpit-audit -- .planning/workstreams/fiabilite/STATE.md", "exit_code": 0, "sha": "d4d0cd41"},
  {"verdict": "gate:check-machine-paths", "commande": "bash scripts/check-machine-paths.sh", "exit_code": 0, "sha": "d4d0cd41"},
  {"verdict": "invariants:sain", "commande": "bash plugin/conductor/scripts/check-mission-invariants.sh", "exit_code": 3, "sha": "d4d0cd41"},
  {"verdict": "plans:22", "commande": "ls .planning/workstreams/fiabilite/phases/VFDO-79-*/ | grep -c PLAN.md", "exit_code": 0, "sha": "d4d0cd41"},
  {"verdict": "flags:desarmes", "commande": "bash plugin/dev-orchestrator/scripts/gsd-run.sh config-get workflow._auto_chain_active --ws fiabilite", "exit_code": 0, "sha": "d4d0cd41"},
  {"verdict": "plancheck:aucun-bloquant", "commande": "gsd-plan-checker frais sur les 22 plans (lecture seule)", "exit_code": 0, "sha": "677d19fa"}
 ]
}
```

`check-mission-invariants.sh` rend 3 pour SAIN (convention du script). La vérification finale par plan-checker est un
agent, pas une commande : son code est celui du verdict « aucun bloquant ».

Commandes jouées par le manager dans le worktree de la phase, sorties recopiées (chemins du poste retirés).

- `git diff --quiet origin/integration/cockpit-audit -- .planning/workstreams/fiabilite/STATE.md` → `rc=0` (STATE jamais touché), rejoué avant chaque commit.
- `bash scripts/check-machine-paths.sh` → `✓ … aucun chemin absolu de machine` (dernier passage avant la PR ; un rouge sur une ligne de motif de 79-20 a été corrigé avant).
- `bash plugin/conductor/scripts/check-mission-invariants.sh` → `SAIN — tous les globs … matchent encore au moins un fichier suivi.`
- `ls <dossier de phase> | grep -c PLAN.md` → `22`.
- `driver-lock.sh acquire --ws=fiabilite --phase=79` → `acquired: true`, génération `DRIVER.lock.gen.1794392995.74780` (trailer `Fence` du premier commit, 3119d82a) ; verrou tenu jusqu'au rendu, relâché en dernier geste.
- `gsd-run.sh config-get workflow._auto_chain_active` et `workflow.auto_advance` (`--ws fiabilite`) → `false` et `false` (lus avant tout dispatch, rien écrit).
- Vérifications fraîches par `gsd-plan-checker` (lecture seule) : 01-05 ; 06-09 ; 08/09/12 ; 06/07 (deux passes) ; 10/11/15/16 ; 13/14 ; 17/18/19/21 ; diff A45 ; 15-20 et recouvrements ; diff de la reprise (01, 02, 05, 08, 11, 14-18, 21) ; retouche A48 de 79-13 ; finale sur les 22 plans (tête 677d19fa) : aucun bloquant, un seul recouvrement de vague admis (79-02/79-05 sur `test-cockpit-lancer-mode.sh`), dépendances acycliques, SOCL-01 à SOCL-27 tous portés ; ses trois avertissements (79-20 sans 79-22, ancre de 79-12, texte périmé de 79-22) corrigés avant la PR.
- Contrôle E4 du gate de sortie : manquant ou indéterminé, attendu (plans non exécutés, STATE non marqué par la mission).

## Prochaine étape

Assembler les sept cadrages (73, 74, 75, 76, 77, 79, 80) sur `integration/cockpit-audit`, puis lancer l'exécution
de la **vague 1 de la Phase 79** (79-01, 79-02, 79-03, 79-05) **en parallèle de la Phase 80**. La 73, la 76 et la
80 placent leurs plans qui touchent les fichiers partagés après cette vague ; 79-14, 79-16 et 79-18 attendent les
vagues 1 à 3 de la 80 (précondition portée aux plans, `8e7afec1`).
