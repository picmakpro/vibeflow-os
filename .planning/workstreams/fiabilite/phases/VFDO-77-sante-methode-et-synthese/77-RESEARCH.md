# Phase 77: Santé de la méthode et synthèse — jauges, dernière visite, burn-up - Research

**Researched:** 2026-11-11
**Domain:** cockpit VibeFlow (module `cockpit`, serveur Node + page, base `f763b556`) et gates du module `conductor` (bash). Aucun paquet externe.
**Confidence:** HIGH sur les faits de code relus à la base (cités avec fichier et ligne) ; MEDIUM sur les formes proposées (TSV, route, objet de burn-up : choix de plan, pas des faits) ; les points ouverts sont dans « Open Questions ».

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Toutes les décisions de cette section sont des **décisions déléguées par Samuel (message session principale,
2026-11-08), option recommandée**. Elles sont prises par le manager sur la base des mesures des éclaireurs et des
panels. Aucune ne vaut arbitrage de Samuel, et aucune ne rouvre un arbitrage déjà rendu.

#### Placement

- **P77-D-01 (placement).** Un bouton d'en-tête « Synthèse » sur l'onglet Projet ouvre la synthèse dans le panneau en
  place (`Floorplan.addHeaderButton` + `showPanel`), sur le patron de la Santé du code. Il occupe la place du bouton
  Santé masqué sur Projet (DG-15), donc le nombre d'icônes ne change pas. Une ligne-résumé neutre s'ajoute en section
  `overview` (par exemple « Depuis votre dernière visite : 2 phases, 14 commits »). Le code vit dans un fichier `ui/`
  neuf ; `ui/00-vibeflow.js`, que d'autres phases modifient, n'est pas touché.
  Écartés :
  - section `overview` seule : elle se rend sous « Jalons », hors de vue à l'arrivée ;
  - section de la carte de jalon : elle dépend du canevas, que la Phase 80 retire comme vue par défaut ;
  - troisième tiroir : exclusif avec les tiroirs Git et « Au travail » sous 1 280 px.
- **P77-D-02 (bornes visuelles).** Les jauges et la courbe n'utilisent que les tons neutres de la direction
  « Graphite ». Ni couleur d'alerte, ni pastille, ni fond teinté. Un état se dit par un glyphe et un mot (« dans le
  budget », « dépassé », « non applicable », « indisponible »). La grille d'espacements est fermée (P71.5-D-01). Le
  panneau ne pousse jamais la carte. Les libellés sont écrits en français au point d'émission, sans passer par le
  dictionnaire. Le détail visuel est fixé par `77-UI-SPEC.md`.

#### Jauges de la santé de la méthode

- **P77-D-03 (source : les gates, jamais un recalcul).** Les valeurs viennent de `check-method-budget.sh` et de
  `check-instruction-budget.sh`. Chacun reçoit une option de sortie machine **en lecture seule** (`--format=tsv`) :
  - une ligne d'en-tête versionnée, puis une ligne par mesure déjà calculée :
    `type, chemin relatif à la racine, valeur, budget, unité, verdict` ;
  - émise aux endroits où le script imprime déjà la mesure, budgets effectifs (variables `VF_*`) compris ;
  - `--auto` et `--archive` refusés avec `--format=tsv` (code 64) ;
  - pour `check-method-budget.sh`, `--no-remote` est implicite et la passe de rangement est sautée (elle lance des
    commandes git sur l'arbre observé) ;
  - sans l'option, la sortie texte reste identique octet pour octet, donc ses consommateurs (`guard-fin-de-geste.sh`,
    `check-mission-exit.sh` E7) sont inchangés.
  Touche des gates et de leurs suites : trailer `Gate-Touche:` obligatoire (G-2).
  Écartés :
  - lire la sortie texte : sa forme n'est pas sous contrat et elle porte des chemins absolus du poste ;
  - faire écrire un fichier de résultat aux gates : c'est une écriture neuve, et le cockpit ne saurait pas dater ce
    fichier ;
  - faire mesurer les fichiers par le cockpit : ce serait une deuxième vérité, interdite par le cadrage.
- **P77-D-04 (route et coût).** Une route `GET /api/vf/methode` sert les jauges **à la demande** (à l'ouverture de la
  synthèse). Ses règles :
  - jamais dans la collecte de 5 s ;
  - cache court ;
  - un seul appel des gates en cours ;
  - lancement **asynchrone** et borné (échéance, PATH assaini). `shBorne` appelle `execFileSync` hors git et figerait
    le serveur environ 1,75 s ; un lanceur asynchrone exporté est à poser.
  Le script est résolu comme `driverLockScript` : dossier du module, puis le `conductor/scripts` voisin, puis le dossier
  de scripts de l'installation, et jamais un script pris dans le lab observé ni dans `.vibeflow/` (T-67-06). La route
  suit les règles communes C0 de la Phase 79 et ne renvoie jamais un chemin du poste. Deux règles viennent de
  l'amendement de la 79 (commit `2ae6607a`), toutes deux livrées par le plan 79-05 en première vague :
  - A11 : la route appelle la fonction exportée unique qui applique les contrôles C0, la garde `porteInterdit`,
    `no-store` et le 503, sans en recopier aucun ;
  - A10 : elle s'ajoute par **une ligne** dans la table des routes de `vf-cockpit-server.mjs`, à sa place dans l'ordre
    alphabétique des chemins (`/api/vf/methode`). Les Phases 75 (`/api/vf/activite`) et 76 (`/api/vf/tracabilite`)
    ajoutent les leurs ailleurs dans la même table.
- **P77-D-05 (lab tiers, valeurs absentes).** Le gate de densité ne mesure que le corpus `plugin/*` du dépôt de
  distribution ; dans un autre lab, il rend le code 2. La jauge dit alors « non applicable dans ce lab », jamais 0. Un
  gate absent, une copie installée trop ancienne (code 64), une version d'en-tête inconnue ou une échéance dépassée
  donnent « indisponible », jamais 0. Chaque jauge montre la valeur, le budget et l'unité, plus la ligne de baseline
  quand le gate en a une (socle de démarrage).
- **P77-D-06 (budgets couverts).** Sont couverts tous les budgets que mesurent les deux gates, et aucun autre :
  - STATE (racine et compartiments, en Ko) ;
  - paragraphe de STATE (lignes) ;
  - BACKLOG (sujets ouverts, lignes par entrée, sujets clos encore présents) ;
  - ROADMAP (Ko) ;
  - index MEMORY (lignes) ;
  - worktrees actifs ;
  - agents (lignes : avertissement dès 251, blocage au-delà de 300) ;
  - skills (≤ 500 lignes) ;
  - socle de démarrage (≤ 2 000 jetons estimés, avec sa ligne de baseline).
  Pour le BACKLOG, le gate compte les sujets ouverts, pas sa taille en octets. La jauge reprend sa mesure et ne la
  recalcule pas.

#### Depuis votre dernière visite

- **P77-D-07 (où vit la donnée).** Dans le stockage local du navigateur, sous une clé **par lab**,
  `vibeflow-cockpit:derniere-visite:<lab>`, où `<lab>` est l'identifiant de lab que sert déjà `/api/vf/modeles`
  (précédent de `ui/75-vf-modele.js`). La clé `vibeflow-cockpit:visite:<lab>` est **déjà prise** par la visite guidée
  et ne doit pas être réutilisée. Lab inconnu (serveur muet, page exportée) : rien n'est rangé, et aucun repli sur une
  clé par origine. Ce choix n'ajoute aucune route d'écriture et n'écrit rien sur le disque du lab.
  Écartés :
  - un fichier disque écrit par une route POST neuve : surface d'écriture ;
  - un fichier disque écrit sur la connexion au flux : un GET qui écrit ;
  - l'heure du dernier chargement en stockage de session : elle meurt à la fermeture de l'onglet, alors que le cas
    visé est « je reviens demain ».
- **P77-D-08 (ce qu'elle contient).** Un objet `v: 1` de 8 Ko au plus, sur liste fermée :
  - `vu` : instant, en secondes ;
  - `phases` : table `<ws>|<n>` → état de la liste `a-faire|en-cours|a-recetter|fait` ;
  - `tete` : sha de 40 caractères du sommet de la branche de base, ou null ;
  - `blocages` : condensats de 12 caractères hexadécimaux, un par blocage normalisé.
  Exclus : titres et noms de phases, sujets et auteurs de commits, identifiants de session, dernière commande,
  transcript, chemins, montants, texte des blocages. Une valeur corrompue, trop grosse ou d'une version inconnue donne
  « première visite sur ce poste », sans exception.
- **P77-D-09 (quand le repère avance).** Deux instantanés sont gardés : `precedente`, la base de la synthèse, et
  `courante`.
  - Au chargement, si `courante.vu` date de plus de 30 minutes, `precedente` prend sa valeur. Sinon rien ne bouge : un
    rechargement ne vide pas la synthèse.
  - `courante` est réécrite quand la page passe en arrière-plan (`visibilitychange`, `pagehide`). Les écritures sont
    fusionnées, le `vu` le plus récent gagne : un onglet en retard ne recule jamais le repère.
  - Le geste « Tout vu » fait avancer `precedente` à maintenant ; les autres onglets le reçoivent par l'événement
    `storage`.
  - **Effacement :** « Tout vu » remet la synthèse à zéro. L'oubli complet passe par l'effacement des données du site
    dans le navigateur. La donnée reste dans le navigateur après la désinstallation du cockpit, et la documentation du
    module le dit. Elle est aussi perdue si le port du lab change ou si l'on change de navigateur : limite « poste
    mono-utilisateur », déjà assumée. Pas de bouton « Oublier » (un ajout, un retrait).
- **P77-D-10 (ce que dit la synthèse).**
  - **Phases avancées :** les différences d'état par phase entre `precedente` et l'état présent.
  - **Commits arrivés :** les rangées déjà lues par `/api/vf/git` qui ne sont pas des ancêtres de `tete`, en suivant
    les parents. On ne filtre jamais sur la date (la date d'auteur ferait manquer une branche fusionnée après la
    visite). Si `tete` sort de la fenêtre lue, la synthèse dit « plus de 500 ».
  - **Sessions finies :** les travailleurs `termine` dont la fin est postérieure à `vu`. Si la visite date de plus de
    24 h, la synthèse dit « au moins N » avec la réserve « seules les 24 dernières heures sont gardées » (AUDC-Q2,
    non rouverte). Jamais un « 0 » sans cette réserve.
  - **Blocages :** les missions dont un nœud a échoué, les agents qui attendent, et les entrées de la section des
    blocages du STATE du compartiment actif. Le STATE est lu côté serveur en lecture seule, par le point de lecture
    confiné du lab (A12 de la Phase 79), et le texte est nettoyé avant d'être servi. Les blocages nouveaux sont nommés avec leur texte présent ; les blocages levés sont seulement
    comptés, puisque leur texte n'est pas gardé.
  La synthèse ne dépend pas de la fenêtre de 24 h pour les phases, les commits et les blocages.
- **P77-D-11 (calcul pur).** Le calcul de la différence est un module pur, sans DOM ni stockage, testé sous node. Son
  entrée a la forme des phases et des jalons de `vibeflow/cockpit-signal@1` (forme inchangée par la Phase 79, C2), et
  la page lui passe les données de Projet par le chemin en vigueur au moment de l'exécution.

#### Burn-up du jalon

- **P77-D-12 (retrait).** Le champ `lastDesc` (prose recopiée du STATE sous « Maintenant ») n'est plus produit par
  `vf-cockpit-project.mjs`. La synthèse datée en prend la place. Le lecteur de `ui/00-vibeflow.js` tolère son absence,
  donc le fichier partagé n'est pas touché ; la ligne de lecture devenue morte sera retirée par la prochaine phase qui
  modifie ce fichier (à verser par la jointure). Repli, si la Phase 80 réécrit de toute façon le panneau Projet : le
  trio de compteurs `.vf-stats`.
- **P77-D-13 (dates).** Les dates viennent de la checklist du ROADMAP, que le cockpit lit déjà (`ph.line`) :
  - clôture : suffixes `— complete AAAA-MM-JJ`, `(completed AAAA-MM-JJ)` et `— close AAAA-MM-JJ` ;
  - entrée dans le périmètre : `inscrite AAAA-MM-JJ`.
  Mesure sur `f763b556` : 8 clôtures datées sur 8, 16 inscriptions sur 16. La date du commit qui coche la case n'est
  jamais utilisée : elle est fausse pour 5 phases closes sur 8 (cases cochées en rattrapage de registre). La table
  `## Progress` n'est pas lue non plus : rédigée pour les humains, elle est mise à jour par la jointure.
- **P77-D-14 (forme et pourcentage).** Courbe SVG en escalier à deux séries neutres, la série des clôtures en trait
  plein et le périmètre en tirets, avec des libellés directs et sans légende colorée. Un équivalent texte est fourni
  (liste datée et `aria-label`). En tête figure « N sur M · P % », produit par la même fonction que le pied de jalon
  (`piedJalon`/`pct`, CKPT-16, P69-D-06 : phases closes seulement, jamais pondéré).
  - Une phase close sans date écrite compte dans le pourcentage, n'a pas de marche sur la courbe, et une ligne neutre
    la nomme sous le graphe (« close, date non écrite »). Elle n'est jamais estimée.
  - Une phase inscrite sans date entre dans le périmètre à l'ouverture du jalon, et une note le dit.
  - Au téléphone (≤ 700 px), le bloc passe à la liste datée.
  La donnée est servie en champ facultatif `meta.vf.burnup` de `cockpit-project@1` : un ajout facultatif ne change pas
  la version (règle C0 de la 79).

#### Coût par phase et par étage (dépend de la Phase 79)

- **P77-D-15 (source et fenêtre).** La source est la route de frise `GET /api/vf/frise`
  (`vibeflow/cockpit-frise@1`, contrat C3 de la Phase 79 au commit `3119d82a`). Chaque voie porte `jetons` (entrée,
  sortie, cache lu et créé, dédoublonnés par message), `durees`, `modeles`, `role` et `rattachement`
  `{dag, noeud, source}`. Le coût s'exprime en jetons et en durée de travail, **jamais en monnaie**, sur les dernières
  24 h, et le bloc le dit dans son titre. L'arbitrage en vigueur est AUDC-Q2 (fenêtre de 24 h) ; la question d'un
  agrégat au-delà est S-2 de la Phase 79, reprise sous « À Samuel ».
- **P77-D-16 (agrégation).**
  - Une voie va à sa phase par la mission. `rattachement.dag` vaut exactement `signal.missions[].fichier` (A8 de la
    79), et la mission donne sa phase par la règle P69-D-05.
  - La voie du manager n'a pas de nœud propre. Elle se rattache par `{dag, noeud: null, source: "enfants"}` quand tous
    ses enfants rattachés pointent le même plan de mission (A14 de la 79).
  - L'étage est le rôle de la voie (`role` = type d'agent) : manager, codeur, revue, audit, vérification, tête de
    session, autres.
  - Une voie dont `rattachement` vaut `null` va dans une ligne « non rattaché », jamais dans une phase devinée. C'est
    le cas d'une voie sans mission, et d'un manager dont les enfants pointent plusieurs plans ou aucun. Ses jetons
    restent comptés dans le total.
  - Le calcul est un module pur partagé. Si la Phase 74 a déjà posé l'agrégat par phase (AUDC-I08 : « un seul calcul
    à partager »), la 77 n'ajoute que l'axe des étages et l'affichage.
  - Plan à part, déclaré dépendant de la Phase 79 (C3) et, pour l'agrégat, de la Phase 74. À revalider par une
    vérification de plan fraîche quand les deux auront livré.

#### Séquencement et fichiers partagés

- **P77-D-17 (de quel côté de la Phase 79).** Le plan des gates (sortie TSV, `plugin/conductor`) ne touche aucun
  fichier de la 79 et peut s'exécuter à tout moment. Les plans du cockpit s'exécutent **après la première vague de la
  79**, qui retire l'appareil de patchs du moteur (C6) : un fichier `ui/` neuf n'appelle donc ni ligne `AJOUT` dans
  `VENDORED.txt` ni diff amont. S'ils devaient passer avant, chaque fichier `ui/` neuf ajouterait sa ligne `AJOUT`, et
  la fusion avec la 79 garderait la suppression. Les jauges, la synthèse et le burn-up lisent les sources en vigueur à
  l'exécution, sans dépendre fonctionnellement des routes C2 et C4 de la 79. Seule exception, de forme : un script de
  page obtient le jeton par `VF_ETAT.jeton()` / `VF_ETAT.lireJson()` quand la coquille de la 79 les expose (A13), et
  par le chemin en vigueur sinon.
- **P77-D-18 (témoins).** Chaque comportement porte un témoin qui rougit sur le code présent, puis verdit. Chaque
  témoin est d'abord montré rouge par une mutation, sa trace (assertion, attendu, obtenu) gardée dans
  `77-NN-RED-TRACE.md`. Les témoins négatifs (réseau, écriture) ont d'abord une sonde positive ; par exemple, le faux
  `gh` placé **hors du lab**, sinon le PATH assaini le retire et le témoin ne peut jamais rougir.

### Claude's Discretion

- Le numéro et le nom du fichier `ui/` neuf : un numéro libre au moment de l'exécution, à vérifier contre les fichiers
  posés par les autres phases.
- La durée du cache de la route des jauges, entre 30 s et 5 min.
- La forme exacte du TSV, sous réserve de P77-D-03 : en-tête versionné, chemins relatifs, un verdict par ligne.
- Le libellé exact du bouton et de la ligne-résumé, fixé par `77-UI-SPEC.md` dans les bornes de P77-D-02.

### Deferred Ideas (OUT OF SCOPE)

- La synthèse sur les onglets Code et Équipe.
- Un repère de visite commun à plusieurs navigateurs du poste : il passerait par un POST sans corps et un fichier dans
  `.vibeflow/cockpit/.cache/`, et demanderait un audit de sécurité.
- Le retrait de « Travail récent » (`ui/25-recent.js`, onglet Code) : seulement si la synthèse va un jour sur Code.
- Une sortie machine pour les linters `check-agents.sh` et `check-skills.sh` : ils ne comptent aucune ligne, la densité
  vit dans `check-instruction-budget.sh`.
- Un script de densité en lignes pour un lab tiers (agents de `.claude/agents`) : aujourd'hui, seul l'audit du
  validator la tient.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SYNT-01 | Bouton « Synthèse », trois blocs, ligne-résumé, `00-vibeflow.js` et `20-health.js` intacts, tons neutres | § Verified Code Facts F3 (API `addHeaderButton`/`showPanel`/`addPanelSection`, règles de masquage DG-15, grille `css-jetons.mjs`, marqueur `// VibeFlow (`) ; Pattern 6 |
| SYNT-02 | `--format=tsv` lecture seule sur les deux gates | F1 (sites d'émission, X8, RO, mutants à lignes exactes, A/B figé, consommateurs à rejouer) ; Pattern 1 |
| SYNT-03 | Route `GET /api/vf/methode` | F2 (`driverLockScript`, `lancerAsync` non exporté, `paths.mjs` à 296/300 lignes, table de routes absente à la base) ; Pattern 2 |
| SYNT-04 | Jauges, « non applicable » / « indisponible », jamais 0 | F1 (rc 2 du gate de densité en lab tiers, STATE-prose et BACKLOG-entrée sans valeur sous le plafond) ; OQ-3 |
| SYNT-05 | Mémoire de la dernière visite | F3 (`75-vf-modele.js` n'exporte pas le lab), Pattern 3, F6 |
| SYNT-06 | Avance du repère, « Tout vu », documentation | Pattern 3 ; README du module (§ Confidentialité et réseau, § Limites connues, O6) |
| SYNT-07 | Contenu de la synthèse, module pur | F6 (formes `signal@1`, rangées de `/api/vf/git`, `finAt`, STATE), OQ-1, OQ-2, OQ-5 |
| SYNT-08 | Burn-up | F7 (grammaire mesurée, `STATUS_SUFFIX`, `piedJalon`, `pct`), Pattern 4 |
| SYNT-09 | Retrait de `lastDesc` | F2 (`vf-cockpit-project.mjs:199`), Pitfall 11 (R3.25 à retirer) |
| SYNT-10 | Coût par phase et par étage | F6 (C3 de la 79), plan dépendant, revalidation fraîche |
</phase_requirements>

## Summary

La phase tient en deux blocs de travail indépendants. (1) Côté `conductor` : une option `--format=tsv` ajoutée à deux gates bash, émise aux endroits où ils calculent déjà la mesure. La contrainte dure est la lecture seule et l'identité octet pour octet de la sortie texte : la suite du gate prouve déjà la lecture seule dynamiquement (enveloppe `git`/`gh` qui refuse tout verbe inconnu, comparaison d'arbre avant/après) et filtre statiquement toute redirection vers un fichier hors de la région d'archivage (X8). Le mode TSV doit donc imprimer sur la sortie standard, sans fichier, et sauter la passe de rangement. (2) Côté `cockpit` : une route à la demande qui lance le gate en asynchrone, un module pur de diff, un module pur de burn-up, un parseur de la section des blocages du STATE, et un petit jeu de fichiers `ui/` neufs.

Quatre faits de la base changent la forme du travail et ne figurent pas dans le cadrage : `vf-cockpit-paths.mjs` fait 296 lignes pour un plafond de 300 (test V4 de `test-cockpit-vendor.sh`), donc tout le code neuf va dans des modules neufs et `lancerAsync` n'est exporté que par l'ajout du mot `export` (zéro ligne) ; `/api/vf/git` ne sert pas le sha du sommet de la base ; les mesures « paragraphe de STATE » et « lignes par entrée de BACKLOG » ne produisent une valeur que lorsqu'elles dépassent leur plafond ; une assertion existante (R3.25 de `test-cockpit-projet-visite.sh`) lit la prose `lastDesc` et rougira avec SYNT-09 (le cadrage pensait qu'aucune suite ne la cherchait).

**Primary recommendation :** exécuter dans cet ordre, en vagues : (V1) gates + suites + fixture A/B figée ; (V2) modules purs serveur (`vf-cockpit-jauges.mjs`, `vf-cockpit-burnup.mjs`, `vf-cockpit-blocages.mjs`) et module de route `vf-cockpit-methode.mjs` branché par **une ligne** (aujourd'hui dans la chaîne `if` de `route()`, demain dans la table de la 79-05) ; (V3) fichiers `ui/` neufs (calcul pur, mémoire, rendu) et leurs suites ; (V4) retrait de `lastDesc` avec réécriture de R3.25 ; (V5, dépendant) coût par phase et par étage, à revalider après la 79 et la 74.

## Project Constraints (from CLAUDE.md)

Extraits actionnables de `CLAUDE.md` du dépôt [VERIFIED: CLAUDE.md du worktree] :

- Un commit qui touche un gate, sa suite, une fixture de ces suites, le workflow CI ou un hook porte un trailer `Gate-Touche: <chemin-ou-motif> — <raison de 10 caractères non blancs au moins>` (G-2). Portée branche : un seul commit de la branche suffit.
- Toute hausse d'une valeur de la baseline du budget d'instructions exige une citation d'arbitrage avec canal et date dans le commit (G-1). **Cette phase n'ajoute aucun agent ni skill : aucune hausse attendue** ; ne pas toucher `.planning/instruction-budget-baselines.tsv`.
- Densité (ADR-029) : agents 251/300 lignes, skills ≤ 500, socle de démarrage ≤ 2 000 jetons ; ne s'applique pas aux `.sh`/`.mjs` mais voir la règle des 300 lignes du module `cockpit` (Pitfall 1).
- Jamais de fix sans validation humaine (ADR-031) ; commits en français ; un commit qui invoque une décision humaine nomme canal et date ; identifiants de décision préfixés (`P77-D-xx`).
- Design : toute interface cockpit suit `DESIGN.md`, direction « Graphite ».
- Release : une version = un tag ; la 77 est une évolution fonctionnelle (elle déclenche une release), mais bump, tag et release sont des gestes humains hors phase (gel des publications en vigueur d'après STATE).
- Un ajout à la méthode (gate neuf, règle, mémoire d'agent, ADR) demande un trailer `Ajout-Retrait:` (SOBR-05, consultatif). Cette phase **ne crée aucun gate** (elle étend deux gates existants) ; si un plan crée un fichier `check-*.sh` ou une mémoire d'agent, le trailer devient nécessaire.
- Mémoires d'agent du dépôt à respecter (citées en Pitfalls) : `.claude/agent-memory/vf-coder/project_marqueur-vibeflow-extension-en-tete.md`, `project_sonde-estanglais-e23-7-mot-outil.md`, `project_vue-q-chargee-hors-page-par-t19.md`, `project_suites-navigateur-cockpit-sous-charge.md`, `feedback_libelles-ok-geles.md`, `feedback_durcir-un-gate-touche-fixtures-et-messages.md`, `project_awk-pieges-mesures.md` ; `.claude/agent-memory/vf-dev-manager/project_runner-ubuntu-26-uutils.md`, `project_fusion-suites-a-base-figee-rougissent-sans-conflit.md`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Mesure des budgets (valeur, budget, verdict) | Gates bash (`plugin/conductor/scripts`) | — | Seule vérité ; le cockpit ne recalcule rien (P77-D-03) |
| Lancement borné du gate, cache, un seul appel | Serveur Node du cockpit (module neuf) | — | Asynchrone, PATH assaini, résolution hors du lab (T-67-06) |
| Analyse du TSV, mots d'état, « non applicable » / « indisponible » | Serveur (module pur) | Page (libellés français) | Le serveur ne sert que des identifiants fermés et des nombres ; la page écrit les mots |
| Dates de clôture et d'inscription, série du burn-up | Serveur (module pur appelé par `buildProjectGraph`) | Page (SVG + équivalent texte) | La checklist est déjà lue côté serveur (`ph.line`) ; le champ rejoint `meta.vf` et le direct |
| Lecture de la section des blocages du STATE | Serveur (lecture confinée du planning) | Page (affichage en texte) | Texte nettoyé avant d'être servi (P77-D-10) |
| Mémoire de la dernière visite | Navigateur (stockage local, clé par lab) | — | Aucune écriture disque, aucune route d'écriture (P77-D-07) |
| Diff « depuis votre dernière visite », agrégat de coût | Page (module pur testable sous node) | Serveur (données sources) | Forme d'entrée = `signal@1` ; les données viennent de `G.meta.vf`, des nœuds, de `who`, de `/api/vf/git`, de `/api/vf/frise` |
| Placement (bouton, panneau, ligne-résumé) | Page (`ui/` neuf) | — | `Floorplan.addHeaderButton` + `showPanel`, `00-vibeflow.js` intact |

## Standard Stack

### Core

Aucun paquet externe. Briques internes, toutes lues à la base :

| Brique | Version / état | Rôle | Pourquoi |
|--------|---------------|------|----------|
| `check-method-budget.sh` (957 lignes), `check-instruction-budget.sh` (712 lignes) | module `conductor` v1.53.2 [VERIFIED: `plugin/conductor/VERSION`] | sources des jauges | Sources uniques imposées (P77-D-03) |
| `vf-cockpit-paths.mjs` (`driverLockScript` l.72, `lancerAsync` l.178 non exporté, `finDans` l.177, `shBorne` l.219) | module `cockpit` v1.4.0 [VERIFIED: `plugin/cockpit/VERSION`] | résolution du script, lancement borné | Précédent exact de la résolution hors du lab |
| `vf-cockpit-env.mjs` (`envEnfant`) | idem | PATH assaini des enfants | Retire du PATH tout élément vide, relatif ou sous le lab |
| `vf-cockpit-arbres.mjs` (`nettoie`, l.68) | idem | nettoyage et masque des chaînes servies | Même filet que `signal@1` |
| `vf-cockpit-planning.mjs` (`readPlanning`, `lireConfine`, `read`) | idem | lecture confinée du planning | API unique de lecture d'un fichier du lab (A12) |
| `window.Floorplan` (`addHeaderButton`, `showPanel`, `closePanel`, `addPanelSection`, `on`) | viewer vendorisé | placement | Patron de `ui/20-health.js` |
| `chrome-session.mjs`, `hygiene.sh`, `projet-commun.sh`, `css-jetons.mjs` | suites du cockpit | témoins | Socle de test déjà en place |

Environnement mesuré : Node v26.5.0, bash 3.2.57 (macOS ; les scripts et suites doivent rester compatibles bash 3.2), git 2.50.1, Chrome présent, `gh` et `jq` présents mais non requis [VERIFIED: commandes lancées dans cette session].

### Supporting / Alternatives Considered

| Au lieu de | Option | Verdict |
|------------|--------|---------|
| `--format=tsv` dans les gates | analyser la sortie texte | écarté par P77-D-03 ; la forme n'est pas sous contrat (seuls les jetons le sont, `check-method-budget.sh` l.100-103) |
| fichier `.mjs` pour le calcul de diff | fichier `ui/` pur chargé en `vm` | **recommandé** : précédent `71-vf-equipe-rendu.js` chargé par `vm.runInContext` dans `test-cockpit-equipe-etats.sh:71-72` ; le calcul reste côté page, où sont les données (voir OQ-1) |

**Installation :** aucune (`npm`, `pip`, `cargo` non concernés). **Version verification :** non applicable.

## Package Legitimacy Audit

Aucun paquet externe n'est installé par cette phase : audit non applicable. `package-legitimacy check` non lancé. **Packages removed due to [SLOP] verdict :** none. **Packages flagged as suspicious [SUS] :** none.

## Verified Code Facts

Section transversale : les faits dont un plan dépendra, à la base `f763b556`. Les chemins sont relatifs au dépôt ; `cockpit/` = `plugin/cockpit/`, `ui/` = `plugin/cockpit/skills/cockpit-moteur/assets/ui/`.

### F1 — Les deux gates, leurs suites, leur contrat

**`check-method-budget.sh`** [VERIFIED: lu en entier sur les zones citées]
- Arguments : `usage()` l.143 imprime le bloc d'en-tête entre `# Usage :` et `# Sortie standard` sur stderr puis `exit 64` ; boucle d'analyse l.145-164 ; options : `--root`, `--repo`, `--strict`, `--quiet`, `--owner`, `--no-remote`, `--archive <types>`, `--auto`, `--dry-run`, `--ws`, `-h|--help`, tout autre argument → `argument inconnu` + 64. Une option `--format=tsv` s'ajoute comme un `case` de plus ; une option inconnue d'une copie installée ancienne rend donc **64**.
- Sortie : `say()` l.196 = `[ "$QUIET" -eq 1 ] || echo "[budget] $*"` ; `flag()` l.197 imprime toujours. `--quiet` ne supprime que les lignes `say`.
- Codes (en-tête l.113-118, fin de script l.945-957) : 0, 1 (dépassement sous `--strict`), 2 (non vérifiable sous `--strict`, ou refus d'`--archive`), 64.
- Sites de mesure déjà calculée (à émettre en TSV à côté du `say`/`flag`) : STATE aucun fichier l.537 ; STATE Ko l.544/546 (`kb`, `STATE_KB`) ; `readable` illisible l.554 ; BACKLOG l.564-580 (`nopen`, `nclosed`, lignes d'entrée `L` l.569) ; ROADMAP l.588/590 ; prose de STATE l.596-602 ; MEMORY l.613/615 (`nl`, `MEMIDX_MAX`) ; worktrees l.939/941 (`active`, `WT_MAX`).
- **Lacune de mesure** : la prose de STATE (`AWK_STATE_PROSE`, `endrun()`) n'imprime une ligne que `si run > MAX` ; l'entrée de BACKLOG (`L`) idem. Sous le plafond, le gate ne calcule aucune valeur : voir OQ-3.
- Passe de rangement : `rangement()` l.864 est appelée l.945 dans la boucle des dépôts ; elle lance `stash list`, `config`, `ls-files`, `for-each-ref`, et `gh` hors `--no-remote`. La passe d'archivage `archive_pass` l.488, déclenchée l.535 seulement si `AUTO=1` ou `ARCHIVE_TYPES` non vide (écrit `.planning/archives/`, `INDEX.tsv`, `.planning/.archive.lock`). Le décompte de worktrees (l.878-942) ne lance que `worktree list --porcelain` ; `is_worked` (reflog) et `merge-base` n'y servent qu'à qualifier un worktree (texte `details`, `OVER`), pas à le compter.
- Mesuré par l'éclaireur : 1,00 s, 36 lignes, `--root <worktree> --no-remote`.

**`check-instruction-budget.sh`** [VERIFIED]
- Un seul argument utile : `--path <dir>` (boucle l.84-94 ; `-h|--help` imprime `grep '^# '` de l'en-tête et rend 0 ; autre argument → 64).
- Rapport imprimé **d'un bloc à la fin** (l.683-711) puis `exit "$RC"` l.712 : le mode TSV peut remplacer ce bloc. Les lignes d'agent sont écrites dans `$REPORT` (mktemp, dans `$TMPD`) l.479 (`rel | lines | bl_lines | instr | bl_instr | verdict`), les lignes de skill dans `$SKILL_REPORT` l.533, le socle l.704-710 (`tokens`, plafond, ligne de baseline, verdict). Le gate « n'écrit que dans un mktemp » : un TSV construit dans `$TMPD` puis imprimé est cohérent avec son contrat.
- Lab tiers : découverte vide l.156-160 → message **sur stderr**, **stdout vide**, `exit 2`. Le mode TSV devra émettre lui-même la ligne `NON-APPLICABLE` (distincte de `NON-VERIFIABLE`) tout en gardant le code 2 du mode texte.
- Constantes en dur, sans surcharge par l'environnement : `VF_BUDGET_LINE_CAP=300`, `VF_BUDGET_LINE_WARN_FROM=251`, `VF_SKILL_LINE_CAP=500`, `VF_BOOTSTRAP_TOKEN_CAP=2000` (l.111-125). Baseline `.planning/instruction-budget-baselines.tsv`, clé `@bootstrap:socle` (colonne 3 lue l.609). Sentinelle `.planning/.instruction-budget-armed`.
- Mesuré : 0,75 s ; 37 agents (max 250 lignes), 24 SKILL.md (max 494), socle 2 610 jetons pour une ligne de baseline à 2 610, plafond 2 000 (verdict `AU-DESSUS-PLAFOND-ADR029`, non bloquant).

**Suites** [VERIFIED: `plugin/conductor/scripts/tests/`]
- `test-check-method-budget.sh` (1 481 lignes) : `set -uo pipefail`, `mktemp -d` + `trap EXIT`, `assert`/`refute`/`assert_rc`/`assert_line`, `kills`/`kills_absent` (mutant tué), `mut`/`make_mutant`/`line_of` (**ligne exacte** ; un mutant dont la ligne cible a bougé échoue à « opposable » par `cmp` ou `bash -n`), `krun`/`kcommit` (archivage), enveloppe de lecture seule RO1-RO5, filet statique X8 (`ro_violations`, l.1077-), section L1 (aucun identifiant de cas réutilisé d'une section à l'autre), Q5 anti-vert-à-vide.
- `test-check-instruction-budget.sh` (1 399 lignes) : un cas par état du contrat, fixtures construites par `w_lines`, `w_baseline`, `std_agent`, gate appelé par `--path`, comparaisons par `cmp`/`comm`/`cksum` « jamais `diff` » (en-tête l.30-32).
- Fixtures : `plugin/conductor/scripts/tests/fixtures/` contient des copies figées `check-map-drift-pre-<sha>.sh` ; `test-check-map-drift.sh:363` les copie, avec repli `git show <sha>:...`. **C'est le précédent de la preuve octet pour octet** : copier le gate à `f763b556` en `fixtures/check-method-budget-pre-f763b556.sh` (idem instruction), jouer l'ancien et le nouveau sur les mêmes fixtures, comparer `cmp` sur la sortie normalisée (remplacer la racine de fixture par un jeton avant comparaison, les chemins imprimés étant absolus). Toute fixture de ces suites est dans la classe 6 de G-2 (trailer).
- X8 (`ro_violations`) lit le texte du script et signale : verbes `git` hors liste blanche (`rev-parse|symbolic-ref|for-each-ref|merge-base|ls-files|reflog show|stash list|worktree list|config`), appels `gh` hors `api user|pr list|repo view`, **toute redirection `>`/`>>` vers un fichier hors `/dev/null` hors de la région `vf-archive-writer`**. Conséquence : le TSV de `check-method-budget.sh` s'imprime sur la sortie standard par `printf`, jamais par `>> fichier`. (`>&2` n'est pas signalé.)
- Consommateurs à rejouer après toute modification : `plugin/dev-orchestrator/scripts/tests/test-check-mission-exit.sh`, `test-check-mission-exit-ws.sh`, `test-fin-de-mandat.sh`, `plugin/conductor/scripts/tests/test-guard-fin-de-geste.sh`, `test-check-divergence.sh` ; pour le gate de densité : `scripts/check-baseline-arbitrage.sh` (+ sa suite) et `plugin/conductor/scripts/check-blueprints.sh` ; l'étape `check-instruction-budget` du job `gates` de `.github/workflows/ci.yml` (l.942-1120) joue le gate réel et sept bascules : elle doit rester verte telle quelle.
- CHANGELOG du module : `plugin/conductor/CHANGELOG.md` s'ouvre sur `## [Non publié] — 2026-11-08 (fin de mandat, #223)` ; les entrées sont des puces par fichier, ouvertes par `**Patch**`/`**Minor**` et la mention « aucune release racine : groupée ». Ajouter une entrée sous « Non publié », sans bump de `VERSION` (même régime pour `plugin/cockpit/CHANGELOG.md`, section `## Non publié`, sous-section `### Ajouté`).
- Taille : les `.sh` ne sont pas soumis à `check-file-size.sh` (`CODE_EXT_RE` liste `ts|tsx|js|jsx|mjs|cjs|py|go|…`, pas `sh`). ADR-029 vise agents et skills. Aucun plafond de lignes ne contraint donc les deux gates ni leurs suites.

### F2 — Serveur du cockpit

[VERIFIED: `plugin/cockpit/scripts/`]
- Tailles : `vf-cockpit-paths.mjs` **296** lignes, `vf-cockpit-server.mjs` 164, `vf-cockpit-project.mjs` 239, `vf-cockpit-planning.mjs` 178, `vf-cockpit-signal.mjs` 88. Le test V4 de `scripts/tests/test-cockpit-vendor.sh` exige `<= 300` lignes pour chaque `scripts/*.mjs` et pour chaque `AJOUT` `.js`/`.mjs` de `VENDORED.txt`, et `check-file-size.sh` bloque au-delà de 300 (avertit dès 250).
- `driverLockScript({ scriptsDir, labRoot, home })` l.72-89 : candidats dans l'ordre (a) `<scriptsDir>/driver-lock.sh` (`module: true`), (b) `…/conductor/scripts/driver-lock.sh` seulement depuis un dossier nommé `…/cockpit/scripts`, (c) `<home>/.claude/scripts/driver-lock.sh` (`module: false`) ; un candidat `module` est refusé s'il est sous `<lab>/.vibeflow`, un candidat non-module s'il est sous le lab (comparaison par `realpath`). Rend `{ chemin, etat: 'trouve'|'absent' }`. Le nom de fichier est écrit trois fois en dur : **paramétrer par un argument `nom = 'driver-lock.sh'` modifie ces lignes en place et n'ajoute aucune ligne**. Le serveur obtient le dossier de module par `resolveScriptsDir(here)` (variable `VF_COCKPIT_SCRIPTS_DIR` posée par le lanceur, `vf-cockpit.mjs:188`). Précédent d'usage : `vf-cockpit-vie.mjs:38`.
- Lancement : `shBorne` (l.219) hors git appelle `lancer` (`execFileSync`, borné à 10 s) : il **gèle la boucle**. `lancerAsync(cmd, args, cwd, env, maxBuffer, fin)` l.178 est la variante `execFile` (échéance `fin` en millisecondes epoch, `finDans(ms)` l.177) mais n'est **pas exportée** ; `lancerGitAsync` (l.255) en est le seul exportateur indirect, réservé à git. L'échéance globale `FIN` est une variable de portée synchrone qui ne survit pas à un `await` (commentaire l.173-175) : passer `fin` à chaque appel. Environnement enfant : `envEnfant(lab)` ([VERIFIED: `vf-cockpit-env.mjs:26`]).
- Répartition des routes **à la base** : `route(req, res, url)` de `vf-cockpit-server.mjs` (l.80-119) est une chaîne de `if (url.pathname === …)` ; les modules à route propre s'y branchent par une ligne : `if (routeGit(req, res, url, { root, json })) return true;` (l.116), `if (lancer.get(req, res, url)) return true;` (l.117), puis `res.writeHead(404)` (l.118). Les contrôles d'accès sont **en amont, dans `serve.mjs`** (hôte exact l.526, `Origin` l.529, jeton en temps constant l.533, avant `VF.route`, l.537) : toute route ajoutée à cette chaîne hérite de C0 sans rien recopier. `json(res, code, obj)` (l.78) pose `Cache-Control: no-store` mais **n'applique pas `porteInterdit`** (const non exportée, l.35). Pour rester valide à l'arrivée de la table (79-05, A10/A11) : écrire la route comme une fonction `routeMethode(req, res, url, ctx)` dont la seule sortie passe par une fonction injectée `repondre(res, code, obj)` ; à la base, `ctx.repondre` applique `porteInterdit` puis `json` ; après la 79, la table référence le lecteur et la fonction exportée A11 remplace `repondre`. Le changement de branchement reste une ligne.
- Précédent de route asynchrone, à un appel à la fois : `routeGit` (`vf-cockpit-git.mjs:207`, promesses, `monoVol` l.38-50 : un appel en cours, les suivants partagent UNE lecture suivante). `monoVol` est privé ; écrire un helper local de quelques lignes (single-flight + cache à durée) dans le module neuf.
- `vf-cockpit-project.mjs` : `const pct = (a, b) => (b ? Math.round((100 * a) / b) : 0);` (l.20) ; `function piedJalon(ks)` (l.24, non exportée) calcule `clos` = phases dont `avancement.etat === 'fait'` (**pas** la case cochée) puis `pct(clos, ks.length)`. « Strict » veut dire « phases closes seulement, jamais pondéré » (P69-D-06), pas un plancher : `Math.round` s'applique (43,75 donne 44). `lastDesc: state.last_activity_desc,` est à la l.199, dans l'objet `meta.vf` ; le jalon mis en avant est la constante `active` (l.~167) ; `msList[].ks` = les phases du jalon, chacune avec `line`, `done`, `avancement`.
- `vf-cockpit-planning.mjs` : `STATUS_SUFFIX` l.34, `phases.set(key, { key, n, ws, name, done, line: m[3], roadmap, … })` l.44 (`line` = tout ce qui suit « Phase N: » sur la ligne de checklist, brut) ; point de lecture confiné : `read`/`lister`/`lireConfine` (l.14-24) ; le texte du STATE est lu dans `readPlanning` (`sTxt`, variable locale) : `state = fm(sTxt)` ne garde que le frontmatter. Ajouter la lecture des blocages = renvoyer un champ de plus de `readPlanning` (ex. `blocages: lireBlocages(sTxt)`), avec un module pur neuf.
- Contrat `vf-cockpit-interface.json` (120 lignes) : schéma de route déclaré comme `vibeflow/cockpit-git-worktrees@1` (clés `description`, `requis` typé, `etats`, `interdits`) ; un champ facultatif d'un nœud déclaré se met dans `optionnels` (ex. `travailleur`) ; `cockpit-project@1` ne déclare que `meta.requis: ["vfTab","vf","kindLabels"]` sans sous-champs de `meta.vf` : l'ajout facultatif `meta.vf.burnup` se dit en une phrase de `description` du schéma plus une clé `vfOptionnels` à introduire, sans monter la version (règle C0). Schéma neuf attendu : `vibeflow/cockpit-jauges@1`. Les suites valident par `validate.mjs` de `projet-commun.sh` (clés requises et typées, clés interdites à toute profondeur).
- `vf-cockpit-signal.mjs` (`collectSignal`, l.32) : `phases[{key, n, ws, nom, fait, avancement, libelle}]`, `jalons[{key, icone, texte, ws, phases:[key]}]`, `missions[{nom, fichier, phaseKey, ws, etat, libelle, vie, noeuds?}]` (`noeuds` seulement pour `running`, `abandonnee`, `inconnu`, `failed`), `equipe` = `cockpit-who@2` ; chaque chaîne passe par `nettoie`. **La page ne reçoit pas ce signal à la base** : voir F6.
- Toutes les `vf-cockpit-*.mjs` de `scripts/` sont copiées dans la sortie du lab à l'assemblage (`fichiersExecution`, `vf-cockpit-build.mjs:22`, hors `OUTILS_ASSEMBLAGE`) puis passent par `renommerTexte` : un module neuf est repris sans rien déclarer, et **toute occurrence de `floorplan` y est renommée** (règles de `vf-cockpit-rename.mjs`).

### F3 — Côté page

[VERIFIED: `ui/`, `viewer.html`]
- Assemblage : `skills/cockpit-moteur/scripts/build.mjs:447-448` inline tous les `ui/*.js` (`readdirSync`, filtre `.js`, `sort()` alphabétique), chacun dans un `<script>` préfixé de `/* ui/<nom> */`. Numéros d'`ui/` posés : 00, 01, 02, 03, 05, 06, 10, 20, 25, 30, 39, 40, 60, 70, 71, 72, 73, 75, 76, 77 (×3), 78, 79, 80. Libres : 74, 81 et plus, 04, 07-09, 11-19, 21-24, 26-29, 31-38, 41-59, 61-69. Le CONTEXT de la 76 annonce `ui/7x-vf-trace*.js`, « numéro libre sous 78, fixé au plan » ; les noms diffèrent, donc pas de collision de fichier, seulement d'ordre. À vérifier par `ls` à l'exécution.
- Contraintes d'un fichier `ui/` neuf : première ligne non vide **`// VibeFlow (`** (regex `MARQUEURS_FR`, `vf-cockpit-fr-inventaire.mjs:124`, sinon l'inventaire F2 de `test-cockpit-chrome-fr.sh` liste ses libellés comme anglais ; mémoire `project_marqueur-vibeflow-extension-en-tete.md`) ; `<= 300` lignes (V4) ; aucun des littéraux V5 (`run.app`, `waitlist`, `auth status`, `claudeEmail`, `cloud-card`, `50-cloud`, …) ; feuille de style conforme à `scripts/tests/css-jetons.mjs` (espacements `{2,4,6,8,12,16,20,24,32}`, aucun `#rrggbb` ni `rgb(` hors `var(`, rayons `{999px, 8px}` ou `var(--r-…)`) ; **avant la 79-01**, une ligne `AJOUT assets/ui/<nom>` dans `skills/cockpit-moteur/VENDORED.txt` (V7 vérifie son existence ; `amont/synchro.sh verifier` rejette un fichier non listé) ; après la 79-01 (`amont/` retiré, C6) plus rien à déclarer. Vérifier l'état à l'exécution : `plugin/cockpit/amont/` existe encore ou non.
- Marque blanche : le source s'écrit `window.Floorplan`, `window.FLOORPLAN_SERVER`, `'x-floorplan-token'` ; la page servie les voit sous `window.VibeFlow`, `window.VF_COCKPIT_SERVER`, `x-vf-cockpit-token` (`renommerTexte`). Les `ui/*.js` existants écrivent bien `x-floorplan-token` (ex. `ui/75-vf-modele.js:67`, `ui/76-vf-git-entete.js:198`). **C0 de la 79 écrit `x-vf-cockpit-token` : c'est la forme servie, pas celle à écrire dans le source.** Ne jamais écrire la chaîne `floorplan` dans un libellé ou une clé neuve (elle serait renommée).
- Bouton et panneau, patron de `ui/20-health.js` : `SC.addHeaderButton({ id, label, icon, title, onClick })` (`viewer.html:2546` ; ajoute au `#hdr-ext` dans l'ordre de chargement des fichiers, appelle `syncHeader()`) ; `SC.showPanel(html, bind)` (l.2556, `html` statique + `bind(panel)`) ; `SC.closePanel()` ; `SC.on('panel', fn)` pour se refermer quand on sélectionne autre chose (`20-health.js:147`) ; `SC.addPanelSection('overview', fn)` rendue **après** `ext.overview()` donc sous « Jalons » (`viewer.html:1655-1662`). `showPanel` est synchrone : afficher d'abord un état « chargement », puis rappeler `showPanel` quand la route répond.
- Masquage : `ui/00-vibeflow.js:132` cache `#btn-health` sur Projet (`display: none !important`), ainsi que `.stats:not(.vf-stats)` et la section santé ; `:134` cache `#btn-health, #ask` sur Équipe. Le nouveau bouton n'est posé que si `G.meta.vfTab === 'project'` (`00-vibeflow.js:12` lit `G.meta.vfTab`). `.vf-stats` est attendu par `test-cockpit-projet-visite.sh:309` et `test-cockpit-transcript.sh:551` (repli D-12, pas à toucher ici). `00-vibeflow.js` (298 lignes) et `70-vf-live.js` (285) sont proches du plafond : rien n'y est ajouté.
- Jeton et lab : `window.FLOORPLAN_SERVER.token` ; `ui/75-vf-modele.js` obtient l'identifiant de lab dans sa fonction `init` (GET `/api/vf/modeles`, `d.lab`, l.66-70) et **ne l'exporte pas** : le fichier neuf refait son propre `GET /api/vf/modeles` (réponse `{ modeles, defaut, lab }`, `vf-cockpit-server.mjs:110-114`, `lab` = `sha256(realpath)[0:12]`). Quand la 79 livre `VF_ETAT.lireJson(chemin)` (A13), l'utiliser s'il existe, sinon le `fetch` direct. Ne pas modifier `75-vf-modele.js` (listé parmi les fichiers de la 79, A7).
- Données de Projet à la page : `G = SC.graph` ; `G.meta.vf` (`milestones[{key,st,done,total,id}]`, `next`, `counts`, …) est **remplacé en entier** par le direct quand il change (`70-vf-live.js:276`, `if (d.vf) { G.meta.vf = d.vf; … }`) : lire `G.meta.vf` à chaque rendu (comme le fait `00-vibeflow.js:199-201`), jamais une copie mise en cache. Nœuds de phase : `kind: 'phase'`, `ws`, `num`, `st` ; `st` ↔ état par `PROJECTION_ST` (`vf-cockpit-project.mjs:22`) : `{ fait: 'done', 'a-recetter': 'recette', 'en-cours': 'active', 'a-faire': 'todo' }`, bijective, donc inversible côté page. Nœuds de mission : `id: 'dag-<nom>'`, `st: 'blocked'` si un nœud a échoué. Équipe : `window.__vfLive.who` (`70-vf-live.js:14, 199`) et l'événement document `vf-who` ; travailleurs `{ kind, id, etat, role, lastAt, finAt?, … }` avec `etat ∈ actif|en-attente|au-repos|attend|termine` ([VERIFIED: `vf-cockpit-interface.json`, `travailleur.etats`]).
- Précédent de module pur testé sous node : `71-vf-equipe-rendu.js` (IIFE sans dépendance au viewer ni au DOM au chargement, pose `window.__vfEquipeRendu`) chargé par `vm.createContext({ window: {}, document: {} })` + `vm.runInContext` (`test-cockpit-equipe-etats.sh:71-72`). Mémoire `project_vue-q-chargee-hors-page-par-t19.md` : tout écouteur posé à l'initialisation d'un module chargé hors page doit être gardé par `typeof document`.
- Mobile : sous 701 px le panneau est un tiroir du bas (`70-vf-live.js:29`, `@media (min-width: 701px)`) ; D-14 dit « ≤ 700 px ».

### F4 — Infrastructure de test du cockpit

[VERIFIED: `plugin/cockpit/scripts/tests/`, `scripts/ci-*.sh`]
- Nommage : `test-cockpit-<sujet>.sh` (bash) ; aides non-suites : `chrome-*.mjs`, `projet-commun.sh`, `hygiene.sh`, `css-jetons.mjs`, `projet-croissance.mjs`. Une suite : `set -uo pipefail`, `SCRIPTS` dérivé de `$0`, `WORK="$(mktemp -d)"` + `trap`, `. hygiene.sh; vf_hyg_init` (marque `tmp.<alnum>`, arrête et fait rougir tout survivant, jamais autre chose), `assert_eq` (PASS/FAIL, `Résultats : N PASS / M FAIL`), outils node écrits en `cat > "$AUX/x.mjs" <<'JS'` (jamais de long `node -e`), mutants par copie du module sous `$WORK/mut-<nom>/` avec ancre exacte (« un mutant sans effet est un FAIL »), `exit 0/1`. Bash 3.2 et 5.
- Suites navigateur : `chrome-session.mjs` (une instance Chrome headless par exécution, profil jetable, `executer(chrome, async (s) => …)`, `s.naviguer`, `s.attendre`, `s.ev`, `stabiliser`, `attendreValeur`, `attendreEtStabiliser`, `positionPosee` ; échéances `VF_CDP_*` ; « mesurer une fois posé », jamais de pause fixe qui juge). Chrome cherché par `CHROME_BIN`, le chemin macOS, puis `google-chrome`, `chromium`… (`test-cockpit-projet-visite.sh:9`). Serveur de lab lancé par `node "$SCRIPTS/vf-cockpit.mjs" open --no-open --lab <lab>` (URL imprimée), port et jeton lus dans `<lab>/.vibeflow/cockpit/.cache/server.json` (`pid4`, `j.port`) ; suites plus anciennes : `node "$OUT/serve.mjs" --no-open --port $(libre)` depuis la **copie de sortie** (la 79-06 fait lancer depuis le module ; l'aide `socle-serveur.sh` de A6 n'existe pas à la base). Pour injecter de faux gates : `env VF_COCKPIT_SCRIPTS_DIR=<dossier jetable>` devant le serveur (précédent T-67-06 : `test-cockpit-securite.sh` L1/L2, l.328-341, un script piège qui écrit un marqueur `EXEC-*` s'il est exécuté, placé dans `<lab>/.claude/scripts`, `<lab>/.vibeflow/cockpit`, et via un `HOME` dont `scripts/` pointe dans le lab).
- Sélection : découverte `find plugin scripts -type f -path '*/tests/test-*.sh'` (`scripts/ci-shard-suites.sh`) : **un `test-*.sh` neuf sous `plugin/cockpit/scripts/tests/` ou `plugin/conductor/scripts/tests/` est repris sans rien déclarer**. Durée absente de la table `durees()` = 7 s par défaut : ajouter une ligne `<secondes> <chemin>` pour une suite Chrome (sinon le partage entre shards la croit courte ; une suite estimée à plus de 600 s réserve un shard). Périmètre de PR (`scripts/ci-suites-perimetre.sh`) : suites du module touché **plus toute suite qui cite le chemin touché ou son nom de fichier** : une PR qui ne touche que `plugin/conductor/scripts/check-method-budget.sh` ne joue la suite cockpit de contrat TSV que si elle cite ce nom de fichier en toutes lettres (la nommer dans la suite, pas la composer). Le compteur « 213 suites » (`README.md:65`, `README.fr.md`) n'est vérifié par aucun gate.
- Précédent RED-TRACE : `.planning/workstreams/fiabilite/phases/VFDO-72-lancer-travail-depuis-cartes-cockpit/72-01-RED-TRACE.md` (aussi 69-01, 69-02, 69-04, 72-02 à 72-07). Format : titre `# NN-MM — trace du rouge (…)` ; en-tête `Commande`, HEAD, `Résultat : N PASS / M FAIL`, rc, durée, commit des témoins ; `## Rouges sur la base (assertion, attendu, obtenu)` (une puce par assertion, sous-puces `attendu` / `obtenu`) ; `## Verts sur la base (… ) et leur raison` (les témoins positifs, ce qui prouve que la sonde sait voir) ; `## Mutants rouges obtenus` (jouée sur le code livré, une entrée par mutant). Un rouge « module absent » est légitime si le chemin est le bon et si la sensibilité réelle est prouvée par les mutants.
- `.planning/research/2026-11-10-audit-cockpit/sondes/` : six scripts de **mesure** (`sonde-boucle.mjs` mesure la latence de la boucle d'événements toutes les 100 ms, `cout-direct.mjs` le coût d'un tour de collecte, …). Leur README dit qu'ils « n'affirment rien », ne sont « ni testés ni maintenus » : ils peuvent inspirer un témoin de non-gel, ils n'en sont pas un.

### F5 — Précédents de module pur

- `scripts/vf-cockpit-lancer-gabarit.mjs` (88 lignes) : en-tête qui dit « module pur : aucune dépendance, aucun accès au système de fichiers, à l'environnement, à l'horloge ni au hasard » ; sa suite `test-cockpit-lancer-gabarit.sh` : G0 (le module se charge, exporte exactement l'interface), oracle écrit **dans la suite** (littéraux indépendants du module), table de refus à code fermé, propriété sur 20 000 entrées à graine fixe, G14 (< 300 lignes, aucune dépendance, aucun accès système, comptage par `awk`), douze mutants nommés `M-*`. `scripts/vf-cockpit-avancement.mjs` (104 lignes) : états fermés exportés, règle de décision écrite en tête.
- Pour les modules purs de cette phase : exporter des listes gelées (`Object.freeze`), rendre une valeur de refus à code fermé plutôt que lever, ne jamais lire l'horloge (passer `now`).

### F6 — Faits pour le module pur de diff (P77-D-10, P77-D-11)

[VERIFIED]
- **Phases** : `signal.phases[{key, n, ws, nom, fait, avancement:{etat}, libelle}]`, clé `<ws>|<n>` (`ws` vide en lab plat), `etat ∈ a-faire|en-cours|a-recetter|fait` (`vf-cockpit-interface.json:8`). À la base la page n'a pas `signal` : l'adaptateur de page construit `{ key: (n.ws||'') + '|' + n.num, avancement: { etat } }` depuis les nœuds `kind: 'phase'` de `G.nodes` par l'inverse de `PROJECTION_ST` ; après la 79, il lit `VF_ETAT.lire('etat').signal.phases`. Le module pur ne voit que la forme `signal@1`.
- **Missions** : `signal.missions[{nom, fichier, phaseKey, etat, noeuds?:[{id,status,…}]}]` ; un nœud échoué = `status: 'failed'` (jeu fermé `missionEtats` du contrat : `running, abandonnee, inconnu, failed, done, ready`). À la base la page lit les nœuds de carte `id: 'dag-…'` à `st: 'blocked'`.
- **Équipe** : `workers[]` ; « agent qui attend » = `etat === 'attend'`. **Session finie** : `etat === 'termine'` ; **`finAt` (ISO) n'existe que sur les sous-agents** (`vf-cockpit-equipe.mjs:107`) ; une session a `lastAt` (dernière écriture du transcript). La « fin postérieure à `vu` » d'une session ne peut donc se lire que par `lastAt` : voir OQ-5. Fenêtre `FENETRE = 86400` (`vf-cockpit-equipe.mjs:12`) : une session finie depuis plus de 24 h n'est plus vue, d'où le « au moins N » + réserve.
- **Commits** : `GET /api/vf/git` (`cockpit-git@1`) sert `rangees[{h, h7, p, at, an, s, col, …}]` où `h` = sha de 40 caractères, `p` = tableau des parents (40 caractères), `at` = **secondes** Unix de l'heure d'auteur (`%at`, `FORMAT_JOURNAL = '%H%x00%P%x00%at%x00%an%x00%s'`, `vf-cockpit-git-graphe.mjs:5`) ; fenêtre `BORNES = { base: 500, nonMergees: 500, … }` (`vf-cockpit-git.mjs:19`). **L'objet `base` ne porte pas le sha du sommet** (`{ nom, locale, distante, divergent }`, l.192) : voir OQ-1.
- **STATE, section des blocages** : titre `### Blockers/Concerns` sous `## Accumulated Context` (`.planning/workstreams/fiabilite/STATE.md:72`), puces `- ` (deux à la base, éventuellement longues). Le fichier du compartiment actif est `stateFile(root, layout)` (`vf-cockpit-paths.mjs:50`). Aucun code ne lit aujourd'hui de blocages (`grep blocker` vide dans `scripts/`). **Normalisation proposée** (aucun précédent) : texte de la puce (suite de lignes indentées comprise), marques markdown et espaces repliés, minuscule, SHA-256 hexadécimal, 12 premiers caractères ; calculée **côté serveur** à côté du texte nettoyé (`nettoie`) pour ne pas dépendre de `crypto.subtle` dans la page.
- Coût (SYNT-10) : voie C3 de la 79 (`79-CONTEXT @ 2ae6607a`, section C3 et amendements A8, A14) ; la route n'existe pas à la base ; les amendements ultérieurs de la branche de la 79 (A15 à A28, commit `6f66d878`) ne changent rien à ce que consomme la 77, sauf **A25** : l'index, la frise et les cibles n'entrent jamais dans l'export autonome.

### F7 — Dates du burn-up

[VERIFIED: regex rejouée sur `.planning/workstreams/fiabilite/ROADMAP.md`]
- Checklist du compartiment, jalon `vibeflow-v2.0` : **16 lignes, 8 cochées, 8 clôtures datées, 16 inscriptions datées** (confirme P77-D-13). Sur toute la checklist (78 lignes) : 52 clôtures, 33 inscriptions, huit phases cochées sans suffixe de clôture (23, 36, 38, 39, 40, 40.1, 41, 41.1 : hors jalon, mais le cas « close sans date » existe donc).
- Formes de clôture observées : `— complete AAAA-MM-JJ` (13), `(completed AAAA-MM-JJ)` (34), `(complete …` (3), `(close …` (1), `— close …` (1). Inscription : `inscrite AAAA-MM-JJ` à l'intérieur d'une parenthèse, parfois précédée de `INSERTED,` (Phase 71.5 : `(INSERTED, inscrite 2026-11-05, élargie le même jour, jalon vibeflow-v2.0) — complete 2026-11-06 : …`). Une ligne peut porter d'autres dates plus loin (Phase 70 : `… (04, 06 et 07 le 2026-11-05 …`) : **ne retenir que la première occurrence ancrée sur le mot-clé**.
- Regex validées sur ces lignes : clôture `/(?:—|\()\s*(?:complete|completed|close)\s+(\d{4}-\d{2}-\d{2})/i`, inscription `/inscrite\s+(\d{4}-\d{2}-\d{2})/i`.
- `STATUS_SUFFIX` (`vf-cockpit-planning.mjs:34`) : `/\s*\((inscrite|completed|INSERTED|exécutée|cadrée|complete|clôturée|clos|CLOSE).*$/i` ; il ne sert qu'à **retirer** du nom le suffixe parenthésé ; `line: m[3]` (l.44) garde la ligne brute, intacte. Le second retrait, `/\s+—\s+(complete|clôturée|CLOSE).*$/` (sans `i`), ne retire pas `— close` en minuscule, mais le nom est déjà coupé au premier ` — ` (`reste.replace(/\s+[-—]\s.*$/, '')`).
- Clé de phase : `${ws||''}|${n}` avec `n = normNum(m[2])` ; `71.5` reste `71.5`. `fusionner` (`vf-cockpit-ailleurs.mjs`) copie les phases en gardant `line`.
- Une phase est « close » pour le burn-up si `avancement.etat === 'fait'` (comme `piedJalon`), pas si la case est cochée : une clôture lue seulement dans un worktree vaut `a-recetter` (`vf-cockpit-ailleurs.mjs`) et n'est pas close.

### F8 — Fichiers partagés avec les autres phases

[VERIFIED pour la 79 : `79-CONTEXT @ 2ae6607a`, A7 ; pour les autres : CONTEXT de leur branche lu en lecture seule par `git show`, sans fusion ; `git` seul, aucun autre worktree touché]

| Fichier | Touché par la 77 | Autres phases connues |
|---|---|---|
| `plugin/conductor/scripts/check-method-budget.sh`, `check-instruction-budget.sh` + leurs suites | oui (V1) | aucune autre phase ne les modifie ; la 76 cite `check-method-budget.sh` (P76-D-23, sans le toucher) |
| `plugin/cockpit/scripts/vf-cockpit-paths.mjs` | **un mot** (`export` devant `lancerAsync`) + un argument de nom dans `driverLockScript` (0 ligne net) | 75 (cite `envGit`, `lancerGitAsync`), 76 (deux mentions) ; la 79 l'utilise |
| `vf-cockpit-server.mjs` | **une ligne** de branchement | 73, 75 (`/api/vf/activite`), 76 (`/api/vf/tracabilite`), 79-05 (table des routes) |
| `vf-cockpit-project.mjs` | retrait de `lastDesc` (l.199) + appel du burn-up (`meta.vf.burnup`) | 75 (deux mentions), 76 (3), 80 (1) |
| `vf-cockpit-planning.mjs` | un champ de retour (`blocages`) | 76 (3 mentions : `lireConfine`, `read`, `lister`) ; A12 de la 79 |
| `vf-cockpit-interface.json` | schéma `cockpit-jauges@1` + mention de `meta.vf.burnup` | 73, 74, 75, 76, 80, 79 (tous) |
| `ui/` : fichiers **neufs** seulement | oui | 76 (`ui/7x-vf-trace*.js`), 73 (retouche `70-vf-live.js`, `72-vf-equipe.js`, `76-vf-git-entete.js`, `80-vf-fr.js`), 75 (retire `25-recent.js`), 80 (`00-vibeflow.js`, `70-vf-live.js`, `75-vf-modele.js`, `76-`, `77-`, `73-`, `02-`), 79 (`70-`, `75-`, `78-`, `79-`, `80-`) |
| `skills/cockpit-moteur/VENDORED.txt` | une ligne `AJOUT` **seulement si** la 79-01 n'a pas livré | 73, 75 ; la 79 la réduit (C6) |
| `plugin/cockpit/CHANGELOG.md`, `README.md` | une entrée, une section | 73, 75, 76, 80 (CHANGELOG) |
| `ui/00-vibeflow.js`, `ui/20-health.js` | **jamais** | 76, 80 (`00-`), 79/73 (`20-` patché par le moteur) |

### F9 — Pièges propres à ce dépôt

Voir « Common Pitfalls » (items 1 à 19), avec les mémoires citées.

## Architecture Patterns

### System Architecture Diagram

```
 gates (conductor)                    serveur du cockpit (Node)                     page (navigateur)
 ────────────────                     ────────────────────────                      ─────────────────
 check-method-budget.sh  ─┐           GET /api/vf/methode
   --root <lab> --no-remote│          (hôte, Origin, jeton : serve.mjs, C0)
   --format=tsv           ├─stdout──▶  routeMethode ── cache (30 s–5 min) ── un seul appel en vol
 check-instruction-budget.sh│              │  lancerAsync(bash, [script…], lab, envEnfant(lab), fin)
   --path <lab> --format=tsv ┘             │  script = driverLockScript({nom}) : module → conductor voisin → ~/.claude/scripts
                                           ▼  (jamais sous <lab> ni .vibeflow/)
                                      vf-cockpit-jauges.mjs (pur) : TSV → { schema, etat, jauges[] }
                                           │  rc 64 / absent / version inconnue / délai → « indisponible »
                                           │  rc 2 + ligne NON-APPLICABLE → « non applicable »
                                           └─ repondre(res, 200, obj)  [porteInterdit + no-store ; A11 après la 79] ──▶ jauges

 .planning/ROADMAP.md ─ readPlanning ─ ph.line ─▶ vf-cockpit-burnup.mjs (pur) ─▶ meta.vf.burnup ─ patch du direct ─▶ G.meta.vf (relu à chaque rendu)
 .planning/STATE.md ─ readPlanning(sTxt) ─▶ vf-cockpit-blocages.mjs (pur, nettoie, condensat 12 hex) ─▶ meta.vf.blocages ─▶ ──────────────────┘
                                                                                                           │
   G.nodes (phases, missions), __vfLive.who, GET /api/vf/git (rangées), [après 79 : VF_ETAT, /api/vf/frise]│
                                                                                                           ▼
                                         ui/NN-vf-synthese-calcul.js (pur, vm) ◀── adaptateur « signal@1 »
                                         ui/NN-vf-synthese-memoire.js : localStorage vibeflow-cockpit:derniere-visite:<lab> (v:1, 8 Ko, fusion `vu`)
                                         ui/NN-vf-synthese.js : bouton #btn-… (Projet seulement), showPanel : visite → burn-up → méthode ; ligne-résumé `overview`
```

### Recommended Project Structure

```
plugin/conductor/scripts/
├── check-method-budget.sh            # + --format=tsv (mesures émises à côté des say/flag)
├── check-instruction-budget.sh       # + --format=tsv (le rapport final remplacé par le TSV)
└── tests/
    ├── test-check-method-budget.sh        # section neuve « TSV » (A/B figé, lecture seule, 64, réseau)
    ├── test-check-instruction-budget.sh   # idem + lab tiers
    └── fixtures/check-{method,instruction}-budget-pre-f763b556.sh   # copies figées du gate (A/B)
plugin/cockpit/scripts/
├── vf-cockpit-jauges.mjs     # pur : TSV → jauges (liste fermée des types, versions, refus de tout champ « / » ou « ~ »)
├── vf-cockpit-methode.mjs    # E/S : résolution du script, lancement asynchrone, cache, un seul appel, routeMethode
├── vf-cockpit-burnup.mjs     # pur : suffixes de checklist → série en escalier + N sur M
├── vf-cockpit-blocages.mjs   # pur : section des blocages du STATE → [{h, t}]
└── tests/test-cockpit-{jauges,burnup,synthese,synthese-page}.sh, aides, fixtures TSV figées
plugin/cockpit/skills/cockpit-moteur/assets/ui/
├── 74-vf-synthese-calcul.js   # pur : diff, adaptateur, agrégat de coût (plan dépendant)
├── 74-vf-synthese-memoire.js  # stockage : clé, rotation, fusion, « Tout vu »
└── 74-vf-synthese.js          # bouton, panneau, SVG, ligne-résumé
```
(Numéro `74` = proposition ; l'ordre alphabétique `calcul` < `memoire` < `synthese` charge les dépendances d'abord.)

### Pattern 1 : émission TSV aux sites de mesure (bash 3.2)

**What :** un seul assistant `tsv_row` ; en mode TSV, les `say`/`flag` de mesure ne s'impriment pas (sinon la sortie mélange texte et TSV) ; le reste du script est inchangé. **When :** aux sites de F1. **Rappel :** pas de redirection vers un fichier dans `check-method-budget.sh` (X8).
```bash
# esquisse (valeurs d'en-tête et de colonnes = proposition de plan, pas des faits du dépôt)
FORMAT=text
case "$1" in --format=tsv) FORMAT=tsv; shift ;; --format=*) echo "[budget] format inconnu : $1" >&2; exit 64 ;; esac
tsv_row() { [ "$FORMAT" = tsv ] && printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5" "$6"; return 0; }
rel() { case "$1" in "$ROOT"/*) printf '%s' "${1#"$ROOT"/}" ;; "$ROOT") printf '.' ;; *) printf '-' ;; esac; }
# site STATE (l.544-546) : le say/flag existant reste, la ligne TSV s'ajoute à côté
tsv_row state "$(rel "$f")" "$kb" "$STATE_KB" Ko "$([ "$bytes" -gt $(( STATE_KB * 1024 )) ] && echo DEPASSE || echo OK)"
```
Refus à poser (code 64, avec message nommé) : `--format=tsv` combiné à `--auto`, `--archive`, `--dry-run`, `--ws` ; **recommandation** : `--no-remote` posé en dur en mode TSV ; la passe `rangement` sautée (`[ "$FORMAT" = tsv ] || rangement …`, l.945) ; `--quiet`, `--owner` sans effet ; format inconnu → 64 (jamais un repli silencieux sur le texte).

### Pattern 2 : route à la demande, asynchrone, bornée

**What :** module `vf-cockpit-methode.mjs` ; lancement `lancerAsync` (exporté par un mot) avec `envEnfant(root)` et `fin = finDans(8000)` ; cache à durée (recommandé : 60 s, dans [30 s, 5 min]) ; un seul appel en vol (les requêtes simultanées partagent la même promesse). **When :** à l'ouverture de la synthèse. Jamais dans `live`/collecte.
```js
// esquisse (signatures lues : lancerAsync(cmd, args, cwd, env, maxBuffer, fin) → Promise<{sortie, code, tronque, absent, echeance, delai}>)
export function creerMethode({ root, scriptsDir, home, lancer = lancerAsync, now = Date.now, ttlMs = 60000 }) {
  let cache = null, enVol = null;
  const lire = () => enVol ??= executer().finally(() => { enVol = null; });
  return async () => (cache && now() - cache.t < ttlMs ? cache.v : (cache = { t: now(), v: await lire() }).v);
}
// routeMethode(req, res, url, ctx) : GET seulement ; ctx.repondre est l'unique sortie (porteInterdit + no-store ; A11 après la 79)
```
Le PATH est celui de `envEnfant(root)` : un faux `gh` doit être posé **hors du lab** pour qu'un témoin puisse rougir.

### Pattern 3 : mémoire de la dernière visite

**What :** `JSON.parse` défensif sur liste fermée (`v === 1`, taille ≤ 8 192 octets avant parse, clés propres vérifiées, `phases` : clés `^[^|]*\|[0-9.]+$` et valeurs dans la liste fermée, `tete` 40 hex ou null, `blocages` ≤ N éléments de 12 hex), objet sans prototype ; deux instantanés `precedente`/`courante` ; rotation au chargement si `courante.vu` a plus de 1 800 s ; réécriture sur `visibilitychange` (état `hidden`) et `pagehide`, fusion « le `vu` le plus récent gagne » (relire avant d'écrire) ; « Tout vu » écrit `precedente = maintenant` et les autres onglets réagissent à `storage`. `now` et le magasin sont **injectés** pour le test sous `vm`. Aucun repli par origine : lab inconnu ⇒ aucune écriture. L'origine `localhost` est distincte de `127.0.0.1` (README, limite O6 : le stockage y est cloisonné autrement) : à écrire dans la limite documentée.

### Pattern 4 : burn-up pur

**What :** entrée `{ ks, pct }` où `ks` = les phases du jalon mis en avant (`{ n, nom, line, avancement }`), `pct` = la fonction de `vf-cockpit-project.mjs` (injectée : `piedJalon` n'est pas exportée, `pct` non plus ; ne pas la recopier). Sortie `meta.vf.burnup` facultatif : `{ jalon, clos, total, pct, serie:[{ d, perimetre, clos }], closesSansDate:[{ n, nom }], inscritesSansDate:[{ n, nom }] }`. Règles : clôture comptée seulement si `etat === 'fait'` ; première occurrence ancrée de chaque regex (F7) ; une phase close sans date : dans `clos`, pas dans `serie`, nommée dans `closesSansDate` ; une phase sans inscription entre à la **plus ancienne date connue du jalon** et la note le dit ; une clôture antérieure à l'inscription est un cas de bord à tester. Absent si le lab n'a pas de jalon mis en avant (`active` indéfini). **Jamais** `git log`.
```js
// regex validées sur la checklist réelle (F7)
const CLOT = /(?:—|\()\s*(?:complete|completed|close)\s+(\d{4}-\d{2}-\d{2})/i;
const INSC = /inscrite\s+(\d{4}-\d{2}-\d{2})/i;
```

### Pattern 5 : adaptateur de données et module de diff pur

`calcul(precedente, present, { git, who, frise })` rend `{ phases:[{key, de, vers}], commits:{ n, plusDe500 }, sessions:{ n, auMoins, reserve24h }, blocages:{ nouveaux:[texte], leves:n } }` ; aucune lecture de `window`, `document`, `localStorage`, de l'horloge. L'adaptateur de page (fichier à part, ou dans le rendu) convertit `G.nodes`, `__vfLive.who`, la réponse de `/api/vf/git` ; après la 79 il lit `VF_ETAT`. Entrée de la forme `signal@1` (D-11), même si la source est différente.

### Pattern 6 : placement

Bouton `SC.addHeaderButton({ id: 'btn-synthese', label: 'Synthèse', icon: …, title: … })` posé seulement si `G.meta.vfTab === 'project'` ; icône d'une liste existante (`SC.icons`) ; libellé écrit en français ; ligne-résumé neutre par `SC.addPanelSection('overview', …)` ; panneau par `showPanel` ; refermé par `SC.on('panel', …)` comme `20-health.js:147`. Le contenu du panneau se rend en `textContent`/`h()` (jamais `innerHTML` sur une donnée : texte de blocage, nom de phase, rôle d'agent).

### Anti-Patterns to Avoid

- **Analyser la sortie texte des gates** ou recalculer une mesure côté cockpit (P77-D-03) ; **afficher 0** pour une mesure absente ; **un fichier de résultat** écrit par un gate.
- **Ajouter du code à `vf-cockpit-paths.mjs`** (296/300) ou de la prose à `00-vibeflow.js` (298) / `70-vf-live.js` (285).
- **Exécuter le gate par `shBorne`** (gèle la boucle ≈ 1,75 s) ou le chercher dans le lab ou `.vibeflow/`.
- **Filtrer les commits sur `at`** (P77-D-10) ; **estimer** une date de clôture ; **utiliser la date d'un commit** de coche.
- **Réutiliser la clé `vibeflow-cockpit:visite:<lab>`** ; une clé par origine ; écrire quoi que ce soit sans lab connu.
- **Couleur d'alerte**, pastille, `--st-*`/`--sev` : états dits par un glyphe et un mot.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Résolution du gate hors du lab | une copie du parcours de candidats | `driverLockScript` paramétré par un nom (0 ligne net) | Les refus `realpath` (T-67-06) sont déjà prouvés par `test-cockpit-securite.sh` L1/L2 |
| Lancement non bloquant | un `spawn` maison | `lancerAsync` + `envEnfant` + `finDans` | Échéance, `maxBuffer`, PATH assaini, sémantique de résultat communes |
| Un seul appel en vol | un verrou fichier | le schéma de `monoVol` (`vf-cockpit-git.mjs:38`) en quelques lignes locales | Aucun état disque |
| Pourcentage de jalon | un second calcul de pourcentage | la fonction `pct` de `vf-cockpit-project.mjs` (injectée) | CKPT-16 : même règle, même arrondi |
| Nettoyage des textes servis | une regex maison | `nettoie` (`vf-cockpit-arbres.mjs:68`) | Contrôles, `Cf`, masque des secrets, borne |
| Lecture d'un fichier du lab | `fs.readFileSync` direct | `read`/`lister`/`lireConfine` (`vf-cockpit-planning.mjs`) | Lien symbolique sortant jamais suivi (A12) |
| Sélection d'un nombre de gabarit CSS | des px au hasard | `css-jetons.mjs` + `--sp-*`/`--inset-*` | Grille fermée (P71.5-D-01) |
| Attente dans une suite navigateur | `sleep` fixe | `attendre`/`stabiliser`/`attendreEtStabiliser` de `chrome-session.mjs` | « mesurer une fois posé » |
| Preuve de non-régression du texte | relecture visuelle | A/B contre une copie figée du gate, `cmp` | Précédent `check-map-drift-pre-<sha>.sh` |

**Key insight :** chaque garde de cette phase existe déjà quelque part (résolution hors du lab, lecture confinée, grille, A/B figé). Le travail est de les brancher, pas de les réécrire ; ce qu'on réécrit sans le tester se redécouvre rouge en CI.

## Runtime State Inventory

Non applicable : phase de création de capacité, pas de renommage ni de migration. Seul état durable neuf : la clé `vibeflow-cockpit:derniere-visite:<lab>` du stockage du navigateur (aucune donnée antérieure à migrer ; aucune clé existante renommée ; la clé `vibeflow-cockpit:visite:<lab>` de la visite guidée reste intacte).

## Common Pitfalls

### Pitfall 1 : `vf-cockpit-paths.mjs` plein (296/300)
**What goes wrong :** une fonction ajoutée fait dépasser 300 lignes : `test-cockpit-vendor.sh` V4 et `check-file-size.sh` rougissent. **How to avoid :** modules neufs pour tout code neuf ; dans `paths.mjs` seulement deux retouches **sans ligne ajoutée** (`export` devant `function lancerAsync` ; argument `nom` de `driverLockScript`). **Warning signs :** `awk 'END{print NR}' vf-cockpit-paths.mjs` > 300.

### Pitfall 2 : filet statique X8 et mutants à ligne exacte (suite de `check-method-budget.sh`)
**What goes wrong :** (a) une écriture par `>>` dans le script, hors région d'archivage, est signalée ; (b) un `make_mutant`/`mut`/`line_of` dont la ligne cible a été reformatée échoue à « opposable » ; (c) la section L1 refuse un identifiant de cas réutilisé ; (d) l'enveloppe RO refuse (rc 97) toute sous-commande `git` ou `gh` hors liste. **How to avoid :** TSV par `printf` stdout ; ne reformater aucune ligne ciblée par un mutant (lister d'abord les cibles : `grep -n "mut mu\|make_mutant\|line_of" tests/test-check-method-budget.sh`) ; étiquettes neuves uniques ; ne lancer aucun verbe `git` nouveau en mode TSV.

### Pitfall 3 : trailer `Gate-Touche:` manquant
**What goes wrong :** G-2 rougit la PR dès qu'un des quatre chemins suivants change : un gate (`plugin/conductor/scripts/check-*.sh`), sa suite (`…/tests/test-*.sh`), une fixture de ces suites (`…/tests/fixtures/**`, y compris les copies figées), le workflow CI. **How to avoid :** un commit de la branche porte `Gate-Touche: plugin/conductor/scripts/check-method-budget.sh, … — <raison ≥ 10 caractères>` (portée branche ; un trailer par motif, jamais de virgule dans un motif). Les suites du cockpit ne sont pas dans la surface de G-2.

### Pitfall 4 : identité octet pour octet et copies figées
**What goes wrong :** (a) le texte imprimé contient la racine absolue de la fixture : sans normalisation, deux exécutions ne se comparent pas ; (b) `diff` est « proxifié menteur » sur ce poste (en-tête de `test-check-instruction-budget.sh`) : comparer par `cmp`/`cksum` ; (c) une copie figée jouée sous le runner `ubuntu-latest` (coreutils uutils) peut diverger : mémoire `project_runner-ubuntu-26-uutils.md` ; juger la comparaison sous BSD, GNU et uutils (faux uutils en tête de PATH) ; (d) une fusion peut rendre rouge une suite à copie figée sans conflit textuel : mémoire `project_fusion-suites-a-base-figee-rougissent-sans-conflit.md`. **How to avoid :** comparer l'ancien et le nouveau gate sur **les mêmes** fixtures de la suite (celles des familles S, W, K…), sortie normalisée par un `sed` de la racine, et rejouer les consommateurs de F1.

### Pitfall 5 : le gate de densité en lab tiers parle sur stderr
**What goes wrong :** découverte vide ⇒ stdout vide, rc 2 (l.156-160) : un parseur naïf lit « rien » et affiche 0. **How to avoid :** en mode TSV, émettre `NON-APPLICABLE` explicitement et garder rc 2 (le mode texte est inchangé) ; côté cockpit, une réponse sans ligne de densité n'est jamais un 0.

### Pitfall 6 : valeurs absentes sous le plafond
STATE-prose et BACKLOG-entrée n'ont de valeur qu'au dépassement (F1). Ne pas inventer un maximum côté cockpit ; voir OQ-3.

### Pitfall 7 : marque blanche et jeton
Voir F3 : écrire `x-floorplan-token`, `window.Floorplan`, `FLOORPLAN_SERVER` dans le **source** ; ne pas écrire `floorplan` dans un libellé ; les suites navigateur lisent `window.VibeFlow` (mémoire `project_suites-navigateur-cockpit-sous-charge.md`) ; un `ev.mjs` qui plante imprime vide : `assert_eq … ""` passe à vide, donc poser un témoin « mesure obtenue » non vide.

### Pitfall 8 : marqueur d'en-tête et inventaire anglais
La première ligne non vide d'un `ui/*.js` doit rester `// VibeFlow (` (mémoire `project_marqueur-vibeflow-extension-en-tete.md`) ; un libellé sans accent ni mot-outil dans un fichier **non** marqué est jugé anglais par `estAnglais` (mémoire `project_sonde-estanglais-e23-7-mot-outil.md`). Le contrôle est statique : un texte composé à l'exécution lui échappe (mémoire `project_inventaire-statique-ne-voit-pas-l-execution.md`) : ajouter une assertion de rendu en navigateur.

### Pitfall 9 : module pur chargé hors page
Un fichier `ui/` pur chargé sous `vm` sans `document` ne doit poser aucun écouteur ni lire `window.Floorplan` à l'initialisation (mémoire `project_vue-q-chargee-hors-page-par-t19.md`).

### Pitfall 10 : le direct remplace `meta.vf`
Une copie de `G.meta.vf.burnup` prise au chargement devient périmée. Lire à chaque rendu. Le direct émet `vf` quand `JSON.stringify(g.meta.vf)` change et **réécrit `project.html` sur disque** (`vf-cockpit-live.mjs:103-109`) : tout champ de `meta.vf` (donc le texte des blocages) atterrit dans ce fichier et dans l'export, comme `lastDesc` jusqu'ici (voir OQ-4).

### Pitfall 11 : une suite lit `lastDesc`
**What goes wrong :** `test-cockpit-projet-visite.sh` (l.405 pose `last_activity_desc: $DESCM` ; R3.25, « M7a », attend la coupe au mot entier de la prose dans `.vf-now`) rougira avec SYNT-09. Le cadrage et l'éclaireur disaient « aucune suite ne le cherche ». **How to avoid :** retirer ou inverser R3.25 dans le même plan (« un ajout, un retrait »), garder R3.24 (message « STATE.md semble périmé », bloc `.vf-now` conservé), et ajouter le témoin SYNT-09. Rejouer aussi les suites qui comparent `meta.vf` à une copie figée (`test-cockpit-lancer-suivi.sh:243`, `normBase`).

### Pitfall 12 : le sha du sommet de la base n'est pas servi
Voir OQ-1.

### Pitfall 13 : « commits arrivés » et branches non fusionnées
Voir OQ-2 : « pas un ancêtre de `tete` » compte aussi toute branche non fusionnée de la fenêtre, à chaque visite.

### Pitfall 14 : `finAt` seulement sur les sous-agents
Voir OQ-5.

### Pitfall 15 : `execFile` et l'échéance
`lancerAsync` plafonne chaque appel à 10 s et prend `fin` en argument ; la variable globale `FIN` de `avecEcheance` ne traverse pas un `await`. Un gate plus lent que `fin` rend `delai: true` : « indisponible », jamais 0.

### Pitfall 16 : témoins négatifs aveugles
Le PATH de l'enfant est assaini : tout dossier **sous le lab** disparaît. Un faux `gh` ou un faux gate posé sous le lab ne prouve jamais rien. Poser `$WORK/fauxbin` (frère du lab, pas dedans), vérifier d'abord qu'il est **vu** (gate lancé **sans** `--no-remote` : le marqueur apparaît), puis juger l'absence via la route. Même règle pour « `.planning/` inchangé » : fixture où `--auto` archiverait réellement, prouvée par une exécution témoin sur une copie.

### Pitfall 17 : sélection CI
Voir F4 : citer `check-method-budget.sh` / `check-instruction-budget.sh` en toutes lettres dans la suite du cockpit ; ajouter une ligne de durée ; `bash scripts/ci-shard-suites.sh --all` doit lister la suite neuve.

### Pitfall 18 : commandes de vérification
Le crochet shell du poste réécrit les sorties de `grep` et de `git` (« 0 matches », sortie vide → une ligne). Une commande de comptage d'un plan doit appeler `/usr/bin/grep` ou `rtk proxy <cmd>` ; sinon `| wc -l` rend 1 au lieu de 0. [VERIFIED : observé dans cette session sur `grep -n 'x-floorplan-token'`]

### Pitfall 19 : double déclaration du contrat
`vf-cockpit-interface.json` est copié dans la sortie du lab ; `test-cockpit-serveur.sh` S7.3 exige qu'il soit identique octet pour octet à celui du module, et F4 vérifie qu'un lab sans contrat n'émet rien. Un schéma neuf ne doit pas casser `INTERDITS` (lu dans `cockpit-who@2`).

## Code Examples

Esquisses, non finales ; toutes les valeurs du dépôt qu'elles utilisent sont citées en § Verified Code Facts.

### Rotation et fusion de la mémoire (page, pur)
```js
// now et stockage injectés ; secondes entières ; objet sans prototype (clé `__proto__` inerte)
const SEUIL_S = 1800;
export const avancer = (pre, cou, maintenant) => (cou && maintenant - cou.vu > SEUIL_S ? { precedente: cou, courante: cou } : { precedente: pre, courante: cou });
export const fusionner = (sur_disque, local) => (sur_disque && sur_disque.vu > local.vu ? sur_disque : local); // le `vu` le plus récent gagne
```

### Chargement d'un `ui/` pur sous node
```js
// précédent : test-cockpit-equipe-etats.sh:71-72
const sb = { window: {}, document: {} }; vm.createContext(sb);
vm.runInContext(fs.readFileSync(path.join(ui, '74-vf-synthese-calcul.js'), 'utf8'), sb);
const calcul = sb.window.__vfSynthese;
```

### Témoin SYNT-09 (assemblage)
Lab fixture dont le STATE porte `last_activity_desc: MARQUEUR-UNIQUE-77` ; `JSON.stringify(buildProjectGraph(lab))` ne contient pas le marqueur (rouge à la base : `lastDesc` le reprend ; sonde positive : `current_phase_name` posé avec un autre marqueur **apparaît**, donc la recherche sait trouver).

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Prose du STATE recopiée sous « Maintenant » (`lastDesc`) | synthèse datée (faits) | cette phase | retrait nommé (SYNT-09) |
| Santé du code anglaise sur l'onglet Code | inchangée ici (AUDC-M8, Phase 80) | — | la 77 n'y touche pas |
| `shBorne` synchrone hors git | lanceur asynchrone borné | cette phase (précédent `lancerGitAsync`, P78-D-32) | le serveur répond pendant un gate |
| Appareil de patchs du moteur (`amont/`) | retiré en première vague de la 79 (C6) | 79-01 | pas de ligne `AJOUT` après |

**Deprecated/outdated :** la table `## Progress` du ROADMAP comme source de dates (P77-D-13 la écarte) ; la date d'un commit de coche (fausse pour 5 phases closes sur 8).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `execFile('bash', …)` cherche `bash` dans le PATH de `options.env` (assaini) comme le précédent `shBorne('bash', …)` de `vf-cockpit-vie.mjs:38` | Pattern 2 | un `bash` du lab pourrait être trouvé : à prouver par un témoin (faux `bash` sous le lab non exécuté) ; sinon résoudre par `resoudreBinaire('bash')` (export de `paths.mjs`) |
| A2 | Durée de cache recommandée 60 s (dans l'intervalle 30 s–5 min laissé à la discrétion) | Pattern 2 | aucune : discrétion |
| A3 | Forme du TSV (en-tête `#vf-budget@1`, types fermés, verdicts `OK`/`DEPASSE`/`NON-VERIFIABLE`/`NON-APPLICABLE`, ligne de baseline en ligne séparée) | Pattern 1 | discrétion (P77-D-03) ; la forme exacte est à poser au plan |
| A4 | Condensat de blocage : SHA-256 du texte normalisé (marques markdown retirées, espaces repliés, minuscule), 12 premiers hex | F6 | collisions ou instabilité à la reformulation d'une puce : acceptable (un blocage reformulé = levé + nouveau) |
| A5 | Fin d'une session finie lue sur `lastAt` | F6, OQ-5 | « sessions finies » surévalué ou sous-évalué de quelques minutes |
| A6 | `visibilitychange`/`pagehide` se déclenchent assez tôt pour écrire `courante` avant la fermeture de l'onglet | Pattern 3 | un instant perdu : la fusion « le plus récent gagne » borne le dégât |
| A7 | Le nom `74` est libre au moment de l'exécution | F3 | collision d'ordre seulement ; vérifier par `ls` |

## Open Questions

1. **OQ-1 — Sha du sommet de la base (SYNT-05, SYNT-07)**
   - Établi : `/api/vf/git` rend `base = { nom, locale, distante, divergent }` (`vf-cockpit-git.mjs:192`), sans sha ; `shaRef(refBase)` existe déjà dans la fonction (l.150) ; une rangée porte des `refs` étiquetées (`type: locale|distante`, `nom`).
   - Flou : `tete` (D-08) et « le sommet courant » (D-10) doivent venir d'un endroit.
   - Recommandation : ajouter un champ **facultatif** `base.h` (`shaRef(refBase)`) à `cockpit-git@1` (ajout facultatif, pas de nouvelle version, une ligne dans `vf-cockpit-git.mjs`) ; sinon dériver le sommet de la rangée qui porte une étiquette `locale|distante` de nom `base.nom`. Dans les deux cas, un témoin sur une fixture où la base a plusieurs étiquettes. À trancher au plan ; la 79 dit ne pas modifier `cockpit-git@1` (A9), un facultatif reste compatible.

2. **OQ-2 — Sens exact de « commits arrivés »**
   - Établi : D-10 dit « rangées qui ne sont pas des ancêtres de `tete` » ; une branche non fusionnée de la fenêtre n'est jamais ancêtre de `tete`.
   - Flou : lue littéralement, la liste compterait à chaque visite les commits d'une branche longue vivante.
   - Recommandation : arrivés = ancêtres du sommet **courant** moins ancêtres de `tete` mémorisé, en suivant `p` dans la fenêtre lue (une branche fusionnée après la visite entre, avec ses dates anciennes : c'est la raison de l'interdit de filtrer sur `at`) ; les branches non fusionnées ne comptent pas ici. Témoin : fixture avec une branche non fusionnée ancienne et une branche fusionnée après la visite. « plus de 500 » quand `tete` n'est pas dans la fenêtre.

3. **OQ-3 — Jauges sans valeur sous le plafond (SYNT-04)**
   - Établi : voir F1 (STATE-prose, BACKLOG-entrée).
   - Recommandation : une ligne TSV `ok` par budget **sans valeur** (champ vide) ; la jauge dit « dans le budget » et montre le plafond, jamais un nombre inventé ni 0 ; si le plan veut une valeur, l'ajouter dans l'awk du gate (une mesure de plus du **gate**, jamais du cockpit) et le dire. Les neuf budgets de D-06 restent tous couverts.

4. **OQ-4 — Où servir le texte des blocages**
   - Établi : D-10 ne nomme pas la route ; `meta.vf` rejoint le direct et `project.html` ; `lastDesc` (prose du STATE) y était déjà.
   - Recommandation : `meta.vf.blocages` facultatif `[{ h, t }]` (condensat, texte nettoyé et borné), produit par `readPlanning` ; retire d'un côté (`lastDesc`) ce qu'on ajoute de l'autre, même exposition. Alternative : un second champ de la route `methode`, mais elle ne rend que les jauges (D-04). Dire dans le CHANGELOG que le texte atterrit dans la page exportée.

5. **OQ-5 — Fin d'une session finie**
   - Établi : `finAt` n'existe que sur les sous-agents ; les sessions ont `lastAt`.
   - Recommandation : « fin » = `finAt ?? lastAt` ; compter les travailleurs `etat === 'termine'` des deux sortes ou, si le plan veut ne compter que les sessions, ne retenir que `kind: 'session'` avec `lastAt` ; le dire dans l'équivalent texte. Réserve des 24 h inchangée (« au moins N »).

6. **OQ-6 — Code de sortie du mode TSV**
   - Recommandation : rc 0 quand le TSV est émis (les verdicts sont dans les lignes), 64 pour l'usage ; rc 2 du gate de densité conservé en lab tiers (le cockpit lit la ligne `NON-APPLICABLE`) ; `--strict` accepté sans effet sur les lignes. Le cockpit tire « indisponible » de tout rc autre que 0 (ou 2 avec ligne `NON-APPLICABLE`).

7. **OQ-7 — Numéro et noms des fichiers `ui/`** (discrétion) : voir F3 et A7.

8. **OQ-8 — Revalidation du plan SYNT-10** : exécuter après la 79 (C3) et la 74 (agrégat par phase) ; une vérification de plan fraîche relit `rattachement` (A8, A14) et l'éventuel agrégat de la 74 avant d'écrire du code.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| bash | gates, suites | ✓ | 3.2.57 (macOS ; compatibilité 3.2 et 5 exigée) | — |
| Node.js | modules purs, serveur, suites | ✓ | v26.5.0 | — |
| git | gates, suites de fixture | ✓ | 2.50.1 | — |
| Chrome headless | suites navigateur (SYNT-01, 05, 06, 08) | ✓ | présent ; cherché par `CHROME_BIN`, chemin macOS, `google-chrome`, `chromium` | suites Chrome sautées par la suite si absent (voir en-tête de la suite choisie) |
| `gh`, `jq` | non requis (le mode TSV n'appelle ni l'un ni l'autre) | ✓ | — | — |

Aucune dépendance manquante.

## Validation Architecture

`workflow.nyquist_validation` vaut `true` dans `.planning/config.json` (lu). Pour chaque exigence : le témoin qui rougit **sur le code présent**, la mutation qui prouve qu'il sait rougir, la sonde positive jouée **avant** le témoin négatif. Chaque plan consigne ses rouges dans `77-NN-RED-TRACE.md` (format : F4). Tout est à jouer : **rien n'a été exécuté** dans cette recherche.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | suites bash maison (`assert_eq`, `assert`, `kills`), node pour les aides et les modules purs, Chrome headless par `chrome-session.mjs` |
| Config file | aucune ; découverte `*/tests/test-*.sh` (`scripts/ci-shard-suites.sh`) |
| Quick run command | `bash plugin/conductor/scripts/tests/test-check-method-budget.sh` ; `bash plugin/cockpit/scripts/tests/test-cockpit-jauges.sh` (noms proposés) |
| Full suite command | `bash scripts/ci-shard-suites.sh --all` (liste) puis la suite voulue ; en CI, les shards |

### Phase Requirements → Test Map

| Req ID | Témoin rouge sur le code présent | Mutation qui le prouve | Sonde positive d'abord | Suite |
|--------|----------------------------------|------------------------|-------------------------|-------|
| SYNT-01 | sur Projet, `#btn-synthese` et le panneau à trois blocs absents ; `git diff f763b556 -- <00-vibeflow.js, 20-health.js>` doit être vide ; `css-jetons.mjs` rend 0 sur les fichiers neufs ; position de la carte identique avant/après ouverture (`positionPosee`) ; aucun `--st-*`/`--sev`/`background` teinté | retirer `addHeaderButton` ; injecter `background: var(--st-active)` ; pousser la carte (largeur) | `#btn-health` trouvé sur Code par la même requête ; marqueur injecté dans une feuille test pour `css-jetons.mjs` | `test-cockpit-synthese-page.sh` |
| SYNT-02 | `--format=tsv` rend **64** à la base (« argument inconnu ») ; avec l'option : une ligne par mesure, en-tête de version, chemins relatifs ; sans option : sortie identique à la copie figée (`cmp`) sur toutes les fixtures de la suite ; `--format=tsv --auto`, `--archive x`, `--dry-run`, `--format=json` → 64 | forcer `AUTO=1` en mode TSV (RO3 : arbre modifié) ; retirer `--no-remote` implicite ; renommer un champ ; changer un `say` (l'A/B rougit) | gate **sans** `--no-remote` + faux `gh` hors du lab : marqueur présent ; texte de la même fixture contient bien la racine absolue (donc « aucun champ ne commence par `/` » est un vrai test) ; fixture où `--auto` archiverait (arbre change) | `test-check-method-budget.sh`, `test-check-instruction-budget.sh` |
| SYNT-03 | route 404 à la base ; avec : 200 `cockpit-jauges@1` ; 3 tours de collecte sans ouvrir la synthèse → 0 appel du faux gate ; 2 GET dans le cache → 1 appel ; 2 GET simultanés → 1 appel ; faux gate qui dort 2 s : `/api/vf/etat` répond en moins de 200 ms ; faux gate sous `<lab>/.claude/scripts` et `<lab>/.vibeflow` jamais exécuté ; corps sans la racine du lab ni `HOME` ; `.planning/` et `git status` identiques ; 403 sans jeton / hôte faux ; 405 sur POST ; `Cache-Control: no-store` | brancher l'appel dans la collecte ; remplacer `lancerAsync` par `execFileSync` (`/api/vf/etat` > 1 s) ; retirer `--no-remote` ; résoudre le gate dans le lab | un GET unique fait monter le compteur à 1 ; le faux gate en dossier de confiance **s'exécute** ; le faux gate à sortie « absolue » prouve que le corps peut contenir le marqueur de racine si on le laisse passer | `test-cockpit-jauges.sh` (cite `check-method-budget.sh`) |
| SYNT-04 | module pur absent à la base ; fixtures TSV figées : valeur+budget+unité+verdict en mot ; lab tiers → « non applicable » (assertion sur le mot **et** absence de `0`) ; rc 64, gate absent, version d'en-tête inconnue, `delai` → « indisponible » ; jeu de types de la jauge = jeu de types du gate sur une fixture riche (contrat dans les deux sens) | mapper rc 2 sur 0 ; accepter un champ `/…` ; renommer un type côté gate (rouge côté gate **et** côté cockpit) | TSV bien formé donne des nombres (le parseur n'est pas aveugle) | `test-cockpit-jauges.sh` |
| SYNT-05 | sous `vm` + magasin factice : lab connu ⇒ clé `vibeflow-cockpit:derniere-visite:<lab>` écrite, `v:1`, ≤ 8 Ko, liste fermée ; lab inconnu ⇒ **aucune** écriture ; valeur corrompue / trop grosse / `v:2` ⇒ « première visite » sans exception ; `__proto__` inerte ; ni titre, sujet, session, commande, chemin ni texte | écrire sous `vibeflow-cockpit:visite:` ; repli par origine ; élargir la liste de clés | clé écrite quand le lab est connu ; clé `visite:<lab>` de la visite guidée intacte après écriture | `test-cockpit-synthese.sh` (+ une vérification Chrome en stockage réel) |
| SYNT-06 | horloge injectée : 29 min 59 s ne tourne pas, 30 min 01 s tourne ; deux écritures concurrentes (la plus ancienne arrive en second) ⇒ le `vu` le plus récent reste ; « Tout vu » ⇒ `precedente = maintenant` ; événement `storage` reçu par le second contexte ; README : phrases sur l'effacement, la persistance après désinstallation, le port, le navigateur, `localhost` | seuil à 1 s ; écrire sans fusion ; ne pas écouter `storage` | une rotation réelle à 31 min est observée | `test-cockpit-synthese.sh` |
| SYNT-07 | module pur absent à la base ; phases : différences d'état sur fixtures ; commits : branche fusionnée après la visite **avec dates anciennes** présente (filtre par date ⇒ rouge), branche non fusionnée absente (OQ-2), `tete` hors fenêtre ⇒ « plus de 500 » ; sessions : visite à 25 h ⇒ « au moins N » + réserve, jamais « 0 » seul ; blocages : nouveaux nommés, levés comptés ; section STATE lue sur le STATE réel du compartiment (deux puces) | filtrer sur `at > vu` ; supprimer la réserve ; nommer un blocage levé | un jeu de fixtures où chaque catégorie est non vide | `test-cockpit-synthese.sh`, `test-cockpit-blocages` dans `test-cockpit-burnup.sh` ou propre |
| SYNT-08 | regex rejouées sur les lignes figées de la checklist : 8 clôtures, 16 inscriptions ; `meta.vf.burnup` du vrai `buildProjectGraph` ; « N sur M · P % » égal au pourcentage du pied de jalon (même nombre lu dans `foot`) ; phase close sans date : dans N, pas dans la série, nommée ; phase sans inscription : note ; `aria-label` + liste ; ≤ 700 px : liste seule ; aucun `git log` appelé | utiliser la date du commit ; pondérer le pourcentage ; estimer une date manquante | la même fixture avec date présente donne une marche (la sonde sait voir une marche) | `test-cockpit-burnup.sh`, `test-cockpit-synthese-page.sh` |
| SYNT-09 | graphe d'un lab au `last_activity_desc` marqué : le marqueur **est** dans le graphe à la base, **n'y est plus** après ; R3.25 retiré ou inversé ; R3.24 garde `.vf-now` | remettre `lastDesc` | `current_phase_name` marqué apparaît (la recherche sait trouver) | `test-cockpit-projet-visite.sh` + témoin d'assemblage |
| SYNT-10 (dépendant) | module pur absent à la base ; fixture `cockpit-frise@1` figée : voie rattachée par `dag` = `missions[].fichier`, manager par `enfants`, voie `null` ⇒ « non rattaché » mais comptée au total ; jetons (entrée, sortie, cache lu, cache créé) et durée de travail ; aucune monnaie ; titre « dernières 24 h » ; revalidation sur la vraie route après la 79 | attribuer une voie `null` à une phase devinée ; oublier le cache créé ; afficher une somme monétaire | fixture à voie rattachée ET voie non rattachée | `test-cockpit-synthese.sh` (plan dépendant) |

### Sampling Rate
- **Par commit de tâche :** la suite visée seule (modules purs et gates ≈ secondes ; suites Chrome plus longues, à mesurer au premier rouge).
- **Par vague :** les suites touchées + les consommateurs de F1 (gates) ou `test-cockpit-projet-visite.sh`, `test-cockpit-projet-graphe.sh`, `test-cockpit-vendor.sh`, `test-cockpit-chrome-fr.sh`, `test-cockpit-securite.sh`, `test-cockpit-serveur.sh` (cockpit).
- **Phase gate :** `scripts/check-version-sync.sh`, `scripts/check-machine-paths.sh`, G-1/G-2/G-3 localement, suites complètes en CI avant `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `fixtures/check-method-budget-pre-f763b556.sh`, `fixtures/check-instruction-budget-pre-f763b556.sh` — copies figées du gate (A/B, SYNT-02)
- [ ] section « TSV » dans les deux suites de gates (SYNT-02, 04, 05 côté gate)
- [ ] `test-cockpit-jauges.sh` + fixtures TSV figées (SYNT-03, 04) ; faux gates et faux `gh` hors du lab
- [ ] `test-cockpit-burnup.sh` (SYNT-08) ; lignes de checklist figées (copie des 16 lignes du jalon)
- [ ] `test-cockpit-synthese.sh` (vm : calcul pur + mémoire, SYNT-05, 06, 07, 10) ; `test-cockpit-synthese-page.sh` (Chrome, SYNT-01, 06, 08)
- [ ] ligne de durée dans `scripts/ci-shard-suites.sh` (`durees()`) pour chaque suite Chrome
- [ ] réécriture de R3.25 de `test-cockpit-projet-visite.sh` (SYNT-09)
- Aucun framework à installer.

## Security Domain

`security_enforcement` n'est pas `false` (niveau ASVS 1, blocage sur `high`) : section requise.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | non | — (jeton de page existant, comparaison en temps constant dans `serve.mjs`) |
| V3 Session Management | non | — |
| V4 Access Control | oui | contrôles C0 hérités de `serve.mjs` (hôte exact, `Origin`, jeton), GET seul (405 sinon), `no-store` ; lecture seule, aucune écriture |
| V5 Input Validation | oui | TSV du gate = entrée semi-fiable : liste fermée de types, nombres bornés, version d'en-tête vérifiée, tout champ commençant par `/` ou `~` rejeté ; `localStorage` : liste fermée, 8 Ko, objet sans prototype ; sortie en `textContent`/`h()` |
| V6 Cryptography | oui (minime) | SHA-256 du module `node:crypto` pour le condensat de 12 hex, pas de secret en jeu |
| V12 Files / V14 Config | oui | script résolu hors du lab (T-67-06), PATH assaini (`envEnfant`), pas de fichier écrit |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Exécuter un faux gate posé dans le lab ou `.vibeflow/` | Elevation | `driverLockScript` paramétré (comparaison `realpath`), témoin du type `test-cockpit-securite.sh` L1/L2 |
| PATH détourné (élément relatif, vide ou sous le lab) | Tampering | `envEnfant(lab)` ; faux binaire **hors** du lab pour que le témoin sache rougir |
| Fuite d'un chemin du poste dans la réponse | Information disclosure | `--format=tsv` en chemins relatifs, rejet côté serveur de tout champ absolu, témoin « racine marqueur » |
| Gate lent ou boucle de requêtes (DoS) | Denial | asynchrone, échéance `fin`, cache, un seul appel en vol |
| XSS par le texte d'un blocage, d'un nom de phase, d'un rôle d'agent | Tampering | `nettoie` côté serveur, rendu en `textContent`/`h()` côté page |
| Valeur de stockage forgée (autre onglet, extension) | Tampering | liste fermée, 8 Ko, `v:1`, pas de `__proto__`, repli « première visite » |
| Écriture accidentelle du gate (`--auto`, archive, verrou) | Tampering | `--format=tsv` refuse `--auto`/`--archive`/`--dry-run`, `.planning/` comparé avant/après |
| Texte du STATE exporté avec la page | Information disclosure | même exposition que `lastDesc` qu'on retire ; dite au CHANGELOG (OQ-4) |

## Sources

### Primary (HIGH confidence)
- Code du dépôt à `f763b556`, relu cette session : `plugin/conductor/scripts/check-method-budget.sh`, `check-instruction-budget.sh`, leurs suites et `fixtures/` ; `plugin/cockpit/scripts/vf-cockpit-{paths,server,project,planning,signal,vie,env,arbres,git,git-graphe,equipe,live,build,rename,fr-inventaire,interface.json}` ; `ui/{00,20,70,75}-*.js` et `viewer.html` (API d'extension) ; `skills/cockpit-moteur/VENDORED.txt` ; `scripts/tests/{test-cockpit-vendor,test-cockpit-projet-visite,test-cockpit-securite,test-cockpit-equipe-etats,test-cockpit-sante,projet-commun,hygiene,chrome-session,css-jetons}` ; `scripts/{ci-shard-suites,ci-suites-perimetre,check-gate-touche,check-machine-paths,check-version-sync}.sh` ; `.planning/workstreams/fiabilite/{ROADMAP,STATE,REQUIREMENTS}.md` ; `CLAUDE.md`.
- `77-CONTEXT.md` (décisions) ; `79-CONTEXT @ 2ae6607a` (C0 à C6, A8, A10 à A14), complété en lecture seule par le contenu de la branche de la 79 (A15 à A28) et par les CONTEXT des branches des Phases 73, 74, 75, 76, 80 pour la matrice F8.
- Rapports d'éclaireurs et de panels de la mission (mesures de F1 et F7 recoupées sur le code et par une exécution de regex sur le ROADMAP).

### Secondary (MEDIUM confidence)
- Mémoires d'agent du dépôt (`.claude/agent-memory/…`) citées en Pitfalls : consignes de pratique, relues.

### Tertiary (LOW confidence)
- Aucune source externe consultée (aucun appel web ni Context7 : la phase n'utilise aucune bibliothèque externe).

## Metadata

**Confidence breakdown :**
- Standard stack : HIGH — briques internes toutes relues.
- Architecture : MEDIUM — les formes (TSV, route, objet de burn-up, découpage des `ui/`) sont des propositions de plan ; les contraintes qui les motivent sont HIGH.
- Pitfalls : HIGH — chacun tient à une ligne ou à une mémoire citée.

**Research date :** 2026-11-11
**Valid until :** la première des deux échéances : fusion du plan 79-05 (table des routes) ou du plan 79-01 (retrait de `amont/`), qui changent le branchement de la route et la déclaration d'un fichier `ui/` ; sinon 30 jours.
