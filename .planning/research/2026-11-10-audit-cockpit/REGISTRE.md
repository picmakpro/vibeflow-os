# Registre de suivi de l'audit du cockpit (2026-11-10)

> Annexe de `.planning/research/2026-11-10-audit-cockpit-etude.md`. **C'est la table qui se tient à jour** : chaque
> constat et chaque idée de l'audit y a un identifiant, une destination et un état. Quand une mission ou une phase
> livre une ligne, elle passe son état à `fait (AAAA-MM-JJ, <sha ou PR>)` ; quand une ligne est écartée, elle dit
> pourquoi. Tout est `ouvert` au versement.

## Lire ce registre

- **Identifiants.** Préfixe `AUDC-` (audit cockpit). Ils reprennent ceux de la page de l'audit, sauf trois familles
  renommées parce qu'elles se confondaient : les constats moyens et bas d'architecture (M1 à M7, B1 de la page)
  deviennent `AUDC-AM1` à `AUDC-AM7` et `AUDC-AB1` ; les mineurs d'interface (m1 à m8 du rapport A4) deviennent
  `AUDC-X1` à `AUDC-X8` ; les finitions sont numérotées `AUDC-F1` à `AUDC-F7`.
- **« Q1 » à « Q14 » sans préfixe** désignent les réponses de Samuel du 2026-11-06 (AskUserQuestion, session
  principale ; `plugin/cockpit/CHANGELOG.md` § Non publié). Les décisions ouvertes par cet audit s'écrivent toujours
  `AUDC-Q1` à `AUDC-Q5`.
- **Gravité.** Données, architecture et sécurité : critique, haute, moyenne, basse (A1 note les siens critique,
  majeur, moyen, mineur ; le registre les aligne sur l'échelle de la page). Interface : bloquant, majeur, mineur,
  finition (barème du rapport A4).
- **Preuve.** `mesuré` ou `sondé` : exécuté pendant l'audit. `lu` : lu dans le code. `inféré` : déduit.
- **Chemins.** `scripts/…` et `signal/…` sont sous `plugin/cockpit/` ; `serve.mjs`, `viewer.html` et `ui/…` sous
  `plugin/cockpit/skills/cockpit-moteur/assets/` ; `scan.mjs` sous `plugin/cockpit/skills/cockpit-moteur/scripts/`.
- **Captures.** Les `ux-NN` cités en preuve ne sont pas au dépôt : elles sont sur le poste de l'audit (dossier non
  suivi `.playwright-mcp/audit/` de l'arbre principal). Six sont versées sous `page/`, identifiants masqués :
  `entete.png` = ux-03, `equipe-aujourdhui.png` = ux-39, `equipe-plongee.png` = ux-43, `lancer-bandeau.png` = ux-60,
  `projet-ouverture.png` = ux-36, `projet-telephone.png` = ux-71.
- **Effort.** S : un commit. M : un lot. L : une phase.
- **Destination.** `Lot 0` : mission de corrections hors phase (mandat : `LOT-0-MANDAT.md`). `Phase N` : phase du
  jalon `vibeflow-v2.0`. `Réserve` : gardé ici, sans phase. `Samuel` : attend une décision listée au § 5. `BACKLOG` : déjà consigné au
  BACKLOG, rien à ajouter.

Décompte au versement : 60 constats (28 au lot 0, en tout ou en partie), 40 idées, 5 décisions de fond (tranchées le 2026-11-11) et
8 réouvertures pour Samuel.

## 1. Constats

### 1.1 Données des agents et des sessions (rapport A1)

| Id | Gravité | Constat | Preuve | Correction | Effort | Destination | État |
|---|---|---|---|---|---|---|---|
| AUDC-D1 | Critique | Un sous-agent non fini, muet depuis 180 s, est exclu de l'écran, et sa session avec lui si rien d'autre n'y est affiché. Sondé : un worker dans une commande depuis 10 min donne « Personne au travail » ; avec un frère terminé, tout s'affiche sauf lui. 35 % des sous-agents du dépôt ont connu un tel silence, 133 de plus de 10 min. `vf-signal` hérite du trou alors que `$.agent.list()` connaît le statut. | `scripts/vf-cockpit-equipe.mjs:72-76`, `signal/hooks/views/equipe.tsx:53-66` · sondé (`sondes/sonde-visibilite.mjs`) | Un agent non fini reste affiché tant que sa session vit, avec « outil en cours depuis N » tiré de l'appel d'outil sans résultat. | S | Lot 0 | ouvert |
| AUDC-D2 | Haute | La fenêtre de 24 h ne vaut que pour les sous-agents : une session au repos disparaît après 3 minutes. Quatre sessions du dépôt écrites depuis moins de 24 h étaient absentes, dont une vivante. Aucun état « attend l'humain » ; une session au repos dont des agents ont fini est dite « terminé ». C'est la cause des « sessions des autres worktrees absentes » (la portée par worktree, elle, est correcte). | `scripts/vf-cockpit-equipe.mjs:76,83,86` · mesuré | Garder la session listée, avec un état lu et non deviné : occupée, au repos, vous attend, close. | S | Lot 0 | ouvert |
| AUDC-D3 | Haute | « À surveiller » et « commande en cours depuis 15 min » exigent un agent actif depuis 120 s ou 900 s, alors que le collecteur borne « actif » à 180 s : l'alerte est inatteignable de bout en bout. Les tests passent sur des données écrites à la main. L'âge affiché est figé entre deux poussées. | `ui/71-vf-equipe-rendu.js:55-61,109-113`, `scripts/tests/test-cockpit-equipe.sh:1146,1158`, `ui/70-vf-live.js:65` · lu | Âge recalculé dans la page ; un test qui traverse le collecteur réel. | S | Lot 0 | ouvert |
| AUDC-D4 | Haute | Un worker encore actif sous un manager terminé est rangé dans « Terminés ». Le contrôle « orphelin ? » ne regarde qu'un parent de type session, et un agent du registre présent en collecte n'est jamais dit orphelin. C'est le cas de l'issue #223. | `scripts/vf-cockpit-equipe-carte.mjs:47-49,67`, `ui/71-vf-equipe-rendu.js:85`, `scripts/vf-cockpit-who.mjs:118` · sondé | Orphelin = parent terminé et enfant vivant, nommé comme tel. | S | Lot 0 (nommage) ; Phase 73 (ligne de régie) ; l'arrêt d'un orphelin relève de AUDC-I11 | ouvert |
| AUDC-D5 | Haute | Le lien entre un agent et sa mission tient à un fil : 143 mandats sur 1 005 citent leur nœud (14 %) ; le registre du verrou n'est lu que pour ses entrées en cours, puis supprimé au relâchement ; 20 plans de mission sur 55 s'appellent `dag-*.json` et seul `*.dag.json` est lu. D'où « pas lié à une phase » et « Aucune mission en cours » avec des agents actifs. | `scripts/vf-cockpit-planning.mjs:98`, `scripts/vf-cockpit-who.mjs:113-132`, `plugin/conductor/scripts/driver-lock.sh:1240` · mesuré | Lire les deux nommages (S). Conserver le registre après relâchement (M, `plugin/conductor`). Faire écrire le nœud dans chaque mandat (M : doctrine `plugin/conductor/references/team-kernel.md`, managers de `plugin/dev-orchestrator` et `plugin/design-orchestrator`). | S puis M | Lot 0 (deux nommages) ; Phase 79 (registre, mandat) | ouvert |
| AUDC-D6 | Moyenne | « New session » est une valeur par défaut de `custom-title` (407 lignes dans une session ouverte depuis l'application de bureau), prise pour un renommage. | `scripts/vf-cockpit-lecture.mjs:96` · mesuré ; origine inférée | Ignorer les valeurs par défaut ; ne garder qu'un nom choisi (borne : PU-G-162, jamais de titre généré). | S | Lot 0 | ouvert |
| AUDC-D7 | Moyenne | « Mandat » est vide par construction pour une session : le mandat est la première ligne du transcript si elle vient de l'utilisateur, et aucune des 63 sessions ne commence ainsi. L'intertitre s'affiche quand même. | `scripts/vf-cockpit-transcript.mjs:95`, `ui/71-vf-equipe-rendu.js:146` · mesuré | Pas de mandat pour une session ; pour un agent, le lire dans son dispatch. | S | Lot 0 | ouvert |
| AUDC-D8 | Moyenne | Le transcript réduit sépare messages et outils en deux listes et jette l'heure, présente sur toutes les lignes. Le graphe Équipe n'a aucun lien : la hiérarchie n'est qu'un emboîtement. | `scripts/vf-cockpit-transcript.mjs:99-114`, `scripts/vf-cockpit-equipe-carte.mjs:83` · lu | Un seul fil ordonné et daté (DESIGNS § 5). | S | Lot 0 (fil daté) ; Phase 74 (lecteur) | ouvert |
| AUDC-D9 | Basse | États et durées approximatifs : un chemin de worktree cité dans un transcript réattribue session et branche (inféré) ; la durée inclut les veilles d'un agent réveillé (jusqu'à 101 h) ; l'état « bloqué » n'est jamais produit ; le champ de fin manque pour 38 agents sur 888 depuis Claude Code 2.1.308 ; le contrat de forme est vérifié sur la 2.1.317 alors que les sessions tournent en 2.1.322. | `scripts/vf-cockpit-interface.json:92-113` · mesuré, en partie inféré | Durées par segments d'activité tirées de l'index ; « bloqué » lu dans l'état officiel ; contrat revérifié à chaque version. | M | Phase 79 puis 74 | ouvert |

### 1.2 Architecture et performance (rapport A2)

| Id | Gravité | Constat | Preuve | Correction | Effort | Destination | État |
|---|---|---|---|---|---|---|---|
| AUDC-H1 | Haute | Chaque page tient deux flux d'événements et Chrome plafonne à six connexions par origine. Code, Projet et Équipe ouverts : une requête d'état reste sans réponse, une quatrième page ne charge jamais ; un onglet fermé, 2 ms. Tiroir Git, questions et « dernière commande » figés, sans message. | `viewer.html:1958`, `ui/70-vf-live.js:257` · mesuré (`sondes/mesure-page.mjs`, `sondes/mesure-2.mjs`) | Un seul flux par page (porter `reload` dans `/api/vf/events`), puis un flux partagé entre onglets. | S puis M | Lot 0 (un flux) ; Phase 79 (partage) | ouvert |
| AUDC-H2 | Haute | Le serveur est sourd 9 % du temps. Toutes les 5 s, la collecte bloque la boucle 318 ms (87 % en sous-processus, 1 959 lectures d'état de fichier, 9,8 Mio de fins de transcripts), même sans onglet : requêtes à 2,6 ms de médiane, pics de 416 à 470 ms. Un changement de planning ajoute 901 ms (planning lu deux fois, verrou interrogé quatre fois). Connu : recette de la 71 (« se bloque toujours toutes les 5 s »), P78-D-41 (filet synchrone assumé, décision de manager). | `scripts/vf-cockpit-live.mjs:62-67,142-153`, `scripts/vf-cockpit-project.mjs:64-66` · mesuré (`sondes/sonde-boucle.mjs`, `sondes/cout-direct.mjs`) | Un seul appel au verrou par cycle, planning lu une fois, aucune collecte sans client (S). Lectures asynchrones et cache par date de modification (M). | S puis M | Lot 0 (trois gestes) ; Phase 79 | ouvert |
| AUDC-H3 | Haute | Le serveur s'arrête et se remplace sans trace. Une relance avec une option différente, ou toute reconstruction, l'arrête et le relance avec un jeton neuf. L'arrêt sur inactivité (60 minutes) ne compte que les flux de page ; une session de terminal ouverte le bloque (lu). Le journal ne porte ni date ni motif, rien n'empêche deux lanceurs de se croiser, l'empreinte du code écrite au démarrage n'est jamais relue, et un `server.json` perdu laisse un serveur orphelin jusqu'à l'inactivité (195 + 58 Mo de mémoire par lab). Observé pendant l'audit. | `scripts/vf-cockpit.mjs:176,239-250`, `serve.mjs:88,91,220,521,601` · lu et observé | Journal daté avec motif d'arrêt ; verrou de lanceur ; une relance à options et code identiques ne remplace pas le serveur, une relance qui change une option le remplace en l'écrivant au journal ; toute requête authentifiée compte comme activité. Proposé au versement pour les deux derniers points du constat : écrire au journal qu'un terminal ouvert retient l'arrêt, et chercher un serveur déjà à l'écoute sur le port du lab avant d'en lancer un second. | S | Lot 0 | ouvert |
| AUDC-H4 | Haute | La traduction réécrit les données du lab : le dictionnaire s'applique à tout texte après rendu (463 entrées, 99 clés d'un seul mot). `tokens.ts` s'affiche « Jetons », `open.mjs` « Ouvrir », `health.mjs` « Santé » ; 11 libellés de données sur 1 547 sont touchés. À l'inverse, une chaîne nouvelle du moteur reste en anglais sans alerte. | `ui/80-vf-fr.js:36,142-146` · mesuré | Exclure titres et descriptions de cartes (S), puis traduire au point d'émission (M). | S puis M | Lot 0 (exclusion) ; Phase 79 | ouvert |
| AUDC-H5 | Haute | Le couplage au moteur vendorisé coûtera cher à la première montée de version : 83 modifications sur l'amont, dont 63 dans `viewer.html` (+483 −297 sur 2 573 lignes) ; dix lignes portent un marqueur maison ; la base n'a jamais bougé depuis la v0.6.0. Plusieurs jours de fusions (inféré). | `plugin/cockpit/amont/patches/` · lu | Sortir le CSS dans une extension, proposer les patchs génériques à l'amont, marquer chaque ligne maison, jouer une synchro à blanc ; ou assumer le fork et retirer l'appareil de patchs. | M à L | Phase 79 (fork assumé : AUDC-Q5 tranchée le 2026-11-11) | ouvert |
| AUDC-AM1 | Moyenne | La page sert de base de données : le graphe Projet ne vit que dans `project.html`, chaque mise à jour relit puis réécrit 3,66 Mo. Aucune route JSON n'expose les schémas pourtant décrits (`project@1`, `who@2`, `signal@1`) ; `vf-signal` refait donc toute la collecte dans un processus neuf (0,82 s, toutes les 10 s). | `scripts/vf-cockpit-live.mjs:78-85`, `scripts/vf-cockpit-server.mjs:40-45`, `scripts/vf-cockpit-query.mjs:19` · lu | Une coquille statique et des données en JSON ; une route d'état. | M | Phase 79 | ouvert |
| AUDC-AM2 | Moyenne | 3,37 Mo par page : mise en page 47,7 %, données 26,6 %, extensions 11,6 %, polices 7,5 %. 2,47 Mo sont identiques dans les trois pages et renvoyés à chaque navigation. Environ 11 Mo en ligne pour 10 000 fichiers (inféré). | `serve.mjs:500` · mesuré | La même coquille, mise en cache une fois. | M | Phase 79 | ouvert |
| AUDC-AM3 | Moyenne | La mise en page tourne sur le fil principal : 1,2 s de gel pour 100 cartes et 216 liens. Même cause que AUDC-M7. La politique de contenu actuelle n'autorise pas de worker. | `viewer.html:678` · mesuré | La déplacer dans un worker (politique de contenu à étendre). | M | Phase 79 | ouvert |
| AUDC-AM4 | Moyenne | Le code exécuté n'est pas celui du dépôt : 52 modules sont copiés dans chaque lab puis renommés par expression régulière, et le renommage est porteur (chemins, en-tête de jeton, variables globales). Un serveur vivant garde l'ancien code après une mise à jour du plugin. | `scripts/vf-cockpit-build.mjs:111-117`, `scripts/vf-cockpit-rename.mjs:11-19` · lu | Lancer le serveur depuis le module. Corrige aussi AUDC-A-03. | M | Phase 79, première vague | ouvert |
| AUDC-AM5 | Moyenne | Le plafond de lignes est tenu par des lignes longues : 13 % des lignes dépassent 160 caractères (jusqu'à 761) ; à 100 colonnes, 6 831 lignes en feraient 9 667. Environ 1 100 lignes de code de navigateur vivent côté serveur et partent sérialisées, sans import ni fermeture possibles. | `scripts/vf-cockpit-lancer-ui.mjs:250` · mesuré | Plafonner aussi en colonnes ; ranger ce code sous `ui/`. | M | Phase 79 | ouvert |
| AUDC-AM6 | Moyenne | Pas d'état côté page : 21 observateurs maison réparent focus, défilement et replis après chaque redessin ; `fetch` est enveloppé et le magasin du moteur remplacé. Chaque nouvelle vue recode sa propre réparation. | `ui/70-vf-live.js:115-161`, `ui/75-vf-modele.js:14-39` · lu | Un magasin d'état alimenté par le flux, des panneaux abonnés rendus par clés. | M | Phase 79 | ouvert |
| AUDC-AM7 | Moyenne | Des tests solides mais chers et parfois muets : 68 suites, 4 130 assertions, des mutants dans 52 suites ; en face 77 % du temps de CI, 400 pauses fixes, des ancres de mutants collées au texte source. Sans Chrome, 28 suites sautent leur moitié navigateur et sortent 0, sans garde en CI. Non couverts : trois onglets, deux lanceurs, collision de port, réactivité pendant la collecte, budgets de poids. | `.github/workflows/ci.yml:402-446` · compté, non rejoué | Exiger Chrome en CI et ajouter deux scénarios (trois onglets, deux lanceurs) (S) ; un socle de test partagé (M). | S puis M | Lot 0 (S) ; Phase 79 | ouvert |
| AUDC-AB1 | Basse | Assemblage complet à chaque ouverture, scan sans cache : sur 4,7 s, la construction du graphe Projet pèse 0,9 s, dont 0,74 s de verrous ; le reste n'a pas été mesuré. `claude --version` est lancé en synchrone avant d'écouter (délai de 15 s). Une collision de port change l'origine, donc le stockage local (inféré). | `serve.mjs:168,590-593` · lu, en partie mesuré | Cache de scan par date de modification ; version lue en asynchrone. | S | Phase 79 | ouvert |

### 1.3 Sécurité (rapport A3)

Aucun constat critique ni haut. Le périmètre réseau tient sur les seize sondes hostiles : écoute sur 127.0.0.1 seul,
hôte exact, origine et jeton de 128 bits sur les routes, aucun en-tête de partage inter-origine, politique de contenu
fermée, secret de 256 bits à usage unique pour le terminal. Les risques déjà acceptés par arbitrage ne sont pas
rouverts (liste : A3 § « Déjà acceptés »).

| Id | Gravité | Constat | Preuve | Correction | Effort | Destination | État |
|---|---|---|---|---|---|---|---|
| AUDC-A-01 | Moyenne | « Demander » peut reprendre n'importe quelle session du lab : le serveur ne contrôle que le format de l'identifiant reçu. Qui tient le jeton d'une page peut faire répondre le modèle avec tout le contexte d'une session de travail, sorties d'outils comprises, et son tour s'ajoute à cette session. Élargit la portée du risque accepté « jeton lisible par tout processus local ». | `serve.mjs:280,288` · lu, non sondé | N'accepter que les identifiants que ce serveur a lui-même rendus. | S | Lot 0 | ouvert |
| AUDC-A-02 | Moyenne | Les liens symboliques du lab sont suivis à l'assemblage : le début d'un fichier extérieur peut entrer dans les pages servies sans jeton, puis dans l'export partagé. Le confinement n'est actif que sur une partie des lectures. | `scripts/vf-cockpit-planning.mjs:18-21`, `scripts/vf-cockpit-build.mjs:87-94`, `scan.mjs:69-75`, `serve.mjs:57` · sondé | Confiner par défaut à la racine réelle du lab, ne pas suivre les liens dans le scan, masquer les descriptions. | M | Lot 0 | ouvert |
| AUDC-A-03 | Moyenne | Le dossier de sortie du lab est exécuté comme du code : un agent qui n'a que le droit d'écrire dans le projet peut y modifier un module que le serveur évalue, hors de tout contrôle de permission. Le README affirme l'inverse (l. 204). | `serve.mjs:183-184,214-219`, `scripts/vf-cockpit-query.mjs:21-22`, `scripts/vf-cockpit-agent.mjs:17` · lu, non sondé | Charger ce code depuis le module du plugin ; la sortie ne porte plus que des données. | M | Phase 79, première vague (avec AUDC-AM4) | ouvert |
| AUDC-B-01 | Basse | Un worktree forgé élargit « qui est au travail » : une archive de lab peut déclarer un worktree qui pointe vers un autre projet, dont les sessions et le transcript réduit apparaissent alors. Même famille que P78-D-38, corrigé pour le tiroir Git seulement. | `scripts/vf-cockpit-arbres.mjs:25-33`, `scripts/vf-cockpit-who.mjs:57-65,219-228` · sondé | Appliquer aux arbres le contrôle déjà fait pour le tiroir Git. | S | Lot 0 | ouvert |
| AUDC-B-02 | Basse | « Demander » n'a ni plafond ni délai : chaque requête lance un processus Claude. | `serve.mjs:323-363,564-568` · lu | Deux exécutions au plus, un délai global, réponse 429. | S | Lot 0 | ouvert |
| AUDC-B-03 | Basse | Les pages sans jeton sont joignables depuis un site tiers, et la page Équipe (2,5 Mo) est reconstruite à chaque requête. | `scripts/vf-cockpit-server.mjs:136-143`, `serve.mjs:491-498,572` · mesuré, rafale non jouée | Refuser les requêtes inter-sites hors des routes d'API ; mémoriser la page. | S | Lot 0 | ouvert |
| AUDC-B-04 | Basse | L'export emporte les métadonnées VibeFlow quel que soit le choix d'export : titres et chemins de plans (532 entrées), dépôt, worktree, branche. | `serve.mjs:51-60`, `scripts/vf-cockpit-build.mjs:100` · vérifié sur l'instance | Retirer ces clés par défaut. | S | Lot 0 | ouvert |
| AUDC-B-05 | Basse | Le mode de lancement mémorisé peut arriver avec une archive du lab : son fichier n'est pas purgé au démarrage. Le clic et la touche Entrée restent requis. | `scripts/vf-cockpit-lancer-mode.mjs:24-27`, `serve.mjs:380` · lu | Les deux corrections du rapport (purger à l'assemblage, ranger le fichier hors du lab) défont P72-D-20, « Fichier du lab », qui veut que le mode survive aux relances : à trancher par Samuel. | S | Samuel (rouvre P72-D-20), à trancher avec AUDC-Q1 | ouvert |
| AUDC-B-06 | Basse | Durcissements : une injection de version n'échappe pas `<` ; le jeton du serveur n'est pas comparé en temps constant ; le lanceur croit une variable de dossier de scripts héritée ; la citation shell diffère sous fish pour un chemin portant une barre oblique inverse (inféré) ; `CLAUDE_EFFORT` et `CLAUDE_PID` passent au terminal. Sans gravité : une amorce de terminal non consommée reste dans `.cache`, périmée. | `serve.mjs:174,514`, `scripts/vf-cockpit-paths.mjs:57-63`, `scripts/vf-cockpit-git-commandes.mjs:10`, `scripts/vf-cockpit-terminal-env.mjs:18` · lu | Cinq retouches. | S | Lot 0 | ouvert |

### 1.4 Interface (rapport A4)

Notes du parcours : Graphite 74, Terminal 72, Lancer 70, Git 68, Code 62, Téléphone 44, Équipe 40, Accessibilité 36,
Projet 34 (90 : livrable tel quel ; 70 : utilisable avec frictions ; 50 : tâche principale gênée ; 30 : en échec).

| Id | Gravité | Constat | Preuve | Correction | Effort | Destination | État |
|---|---|---|---|---|---|---|---|
| AUDC-BL1 | Bloquant | Projet est illisible à l'ouverture : titres de carte à 7,1 px à 1440 (échelle 0,475), 5,4 px dans le jalon v2.0, 6,2 px à 1024, 1,9 px au téléphone. Les cartes occupent 12 % puis 4 % de la zone libre ; zoomé à taille lisible, on ne voit que trois phases. Connu du panel pour 8 juges (PU-G-026). | captures `ux-25`, `ux-27`, `ux-63-1024-projet`, `ux-71` · mesuré | Les couloirs par état (DESIGNS § 6). À défaut : plancher de lisibilité, mise en page compacte, liste par défaut sous 1 100 px (rouvre PU-G-026). | M | Phase 80 | ouvert |
| AUDC-BL2 | Bloquant | Le canevas est hors du clavier et de l'arbre d'accessibilité : aucune carte parmi les 54, 22 et 17 arrêts de tabulation des trois onglets ; les cartes sont sans rôle ni nom ; flèches et Entrée sont sans effet. Connu du panel (PU-G-031), non livré. | mesuré | Rôle de bouton, nom accessible, tabulation itinérante, flèches entre voisins, Entrée pour plonger. | M | Phase 80 | ouvert |
| AUDC-M1 | Majeur | « Ajuster » ne montre pas l'ensemble sur Code : plafond à 0,846, 6 cartes sur 26 entièrement visibles à 1440 (2 à 1024), 16 hors écran, 2 sous le panneau. Six crans de molette et le canevas est vide, sans repère. | `ux-01`, `ux-06`, `ux-37` · mesuré | Ajuster sur la zone libre, minicarte, compteur de cartes hors champ. | S puis M | Phase 80 | ouvert |
| AUDC-M2 | Majeur | Le bloc de titre de la vue, sans fond, se superpose aux cartes. | `ux-22-etape2`, `ux-30`, `ux-38`, `ux-67` · observé | Zone réservée, ou titre dans l'en-tête. Rouvre Q10 (« Flou gardé, texte court ») : goût de Samuel. | S | Phase 80, après avis de Samuel | ouvert |
| AUDC-M3 | Majeur | Équipe dit l'inverse de ce qu'elle montre : « Aucune mission en cours » avec sept agents actifs, une carte sur un canevas vide à 93 %, « Santé : aucun problème trouvé » quand Code affiche quatre points. Ni « Demander » ni terminal sur cet onglet : ce sont deux choix (plan 69-05 pour la question, « qui porte sur le code ou le projet » ; Q8 pour le terminal). | `ux-39`, `ux-48` · observé | Titre vrai (« N agents actifs ») et santé alignée ou retirée (S) ; la régie (M). | S puis M | Lot 0 (titre, santé) ; Phase 73 (régie) | ouvert |
| AUDC-M4 | Majeur | Fiche de session et transcript pauvres : branche écrite trois fois ; ni modèle, ni durée, ni jetons, ni fichiers ; transcript dans une boîte de 320 px à défilement imbriqué, large de 308 px, en markdown brut, trois listes sans heure ; sur la session principale, « Lire le transcript » ne change rien de visible. Markdown connu du panel (PU-G-168). | `ux-40` à `ux-46` · observé | Lecteur large, fil chronologique unique, bandeau de faits (DESIGNS § 5). | M | Phase 74 | ouvert |
| AUDC-M5 | Majeur | L'en-tête se décode mal : neuf icônes sans libellé sur Code, sept ailleurs ; le triangle ouvre « Parcours », l'icône « Travail récent » ressemble à un chargement, un point beige vaut « N au travail » ; « Vue d'ensemble » est à 8 px des onglets dans le même corps ; la branche est tronquée malgré la place. Connu du panel (PU-G-001, PU-G-007). | `ux-03` · observé | Trois groupes libellés au-delà de 1 280 px ; fil d'Ariane avec chevron. Rouvre en partie P70-D-22 (badge « au travail » réduit à son point) et la réponse « Garder ce compromis » sur la troncature (PU-G-001). | M | Phase 80, après avis de Samuel | ouvert |
| AUDC-M6 | Majeur | Les surcouches ne retiennent pas le focus : Tab sort de la recherche restée ouverte, puis Échap ne la ferme plus (reproduit deux fois) ; Tab sort de l'export ; le focus n'entre pas dans la visite ; panneau fermé, 43 arrêts invisibles. | `ux-76`, `ux-77` · reproduit | Rendre inerte ce qui est masqué ou derrière ; Échap au niveau du document. | S à M | Phase 80, première vague | ouvert |
| AUDC-M7 | Majeur | Un gel de 2,3 s : ouvrir un résultat de recherche dans un niveau de 70 cartes bloque l'onglet, canevas blanc ; « Mise en page… » ne s'affiche jamais. | `ux-11` · mesuré | Poser l'indicateur avant le calcul (S) ; mise en page dans un worker (AUDC-AM3). | S puis M | Lot 0 (indicateur) ; Phase 79 | ouvert |
| AUDC-M8 | Majeur | La santé parle anglais dans une interface française, et son introduction cite des services que le dépôt n'utilise probablement pas (supposé). | `ux-16` · observé | Traduire les gabarits ; fonder la détection sur les dépendances. Rouvre P70-D-04 (constats de Santé laissés en anglais). | S à M | Phase 80, après avis de Samuel | ouvert |
| AUDC-M9 | Majeur | Une coupure du serveur reste muette cinq minutes : la pastille ne change ni de classe, ni de libellé ; la bannière arrive à 300 s et reste après le retour, jusqu'à un clic. Voisin de PU-G-202 (« serveur arrêté » et non « Git est indisponible »). | `ux-80`, `ux-81` · simulé | « Direct coupé » à 5 s, bannière à 15 s, qui se retire seule. | S | Lot 0 | ouvert |
| AUDC-M10 | Majeur | Terminal : absence muette, puis message trompeur. Sans l'option, ni pastille ni « Lancer », sans explication. Avec l'option, un onglet ouvert à la main lit « non disponible » alors que le serveur l'a : la vraie cause est l'amorce à usage unique de 60 s. Fermer le tiroir ne termine pas le shell et rien ne permet de le terminer. | `ux-01`, `ux-18`, `ux-52`, `ux-62` · observé | Dire la vraie cause ; une action « Terminer la session » ; une pastille expliquée sans l'option (touche P71-D-02). | S | Lot 0 (cause, « Terminer ») ; Phase 80 pour la pastille, après avis de Samuel | ouvert |
| AUDC-M11 | Majeur | Bandeau de lancement rogné, état périmé : à la hauteur par défaut il prend 173 px sur 288, la phrase « écrit cette ligne sans la lancer » est coupée, les modes sont sous le pli ; après « Annuler », le panneau dit toujours « Confirmez-la ». Connu du panel (PU-G-113, partiel). | `ux-60`, `ux-61` · observé | Un tiroir qui s'ajuste au bandeau ; un statut remis à zéro ; la phrase visible. | S | Lot 0 | ouvert |
| AUDC-M12 | Majeur | Tiroir Git étroit : à 1024 × 768 un seul commit est visible ; le détail s'ouvre sous le pli sur 313 px ; les sujets sont coupés vers 22 caractères ; 653 rangées rendues d'un coup (9 138 nœuds). Voisin de PU-G-195 (étiquettes de branche tronquées). | `ux-50`, `ux-64` · mesuré | Worktrees repliés, détail dans le panneau, liste virtualisée, largeur réglable (borne : Q12, le tiroir ne pousse jamais la carte). | M | Phase 80 | ouvert |
| AUDC-X1 | Mineur | Le vocabulaire du Code est appliqué au planning (« Élément », « module », « Utilisé par ») ; le panneau d'un plan ou d'une exigence n'affiche ni statut ni vague ; le même texte est trois fois à l'écran. | `ux-27`, `ux-31`, `ux-33` | Vocabulaire propre au planning ; statut et vague dans le panneau. | S | Phase 80 | ouvert |
| AUDC-X2 | Mineur | Backlog et Releases en vignettes à 8 px qui doublent la liste du panneau ; « DIFFÉRÉ » et « À faire » sur la même carte. | `ux-34`, `ux-35` | Une liste, pas des vignettes. | S | Phase 80 | ouvert |
| AUDC-X3 | Mineur | Le zoom « + » vise le centre de l'écran : la carte sélectionnée sort du champ. `+` et `-` ne sont pas documentés, pas d'aide `?`. | `ux-28` | Zoom centré sur la sélection ; aide des raccourcis. | S | Phase 80 | ouvert |
| AUDC-X4 | Mineur | Deux anneaux de focus différents, aucun sur le champ de question ; pas d'`aria-current`, pas de `<main>`. | `ux-75` | Un seul anneau ; repères d'accessibilité. | S | Lot 0 | ouvert |
| AUDC-X5 | Mineur | Thème clair : la carte active est grise et se lit comme désactivée ; glyphe « En cours » à 3,01 de contraste ; cartes estompées en sombre à 2,97. | `ux-48` · mesuré | Reprendre les jetons concernés, contraste mesuré dans les deux thèmes. | S | Phase 80 | ouvert |
| AUDC-X6 | Mineur | En mouvement réduit, la plongée garde son fondu (0,5 s) et 23 animations restent actives. | mesuré | Respecter la préférence de mouvement réduit. | S | Lot 0 | ouvert |
| AUDC-X7 | Mineur | Trois formats de titre d'onglet ; le tiroir Git se ferme à chaque changement d'onglet, parce que la page se recharge en entier (2,5 à 3,6 Mo). | observé | Un format de titre (S) ; onglets sans rechargement (M, après le socle). | S puis M | Lot 0 (titres) ; Phase 80 | ouvert |
| AUDC-X8 | Mineur | Au téléphone, le zoom et la pastille Terminal recouvrent la carte sélectionnée ; les onglets font 26 px de haut. | `ux-67` | Zone basse dégagée ; cibles tactiles à taille. | S | Phase 80 | ouvert |
| AUDC-F1 | Finition | Triangles natifs des blocs repliables et sélecteur natif du bandeau. | observé | Composants à la charte. | S | Phase 80 | ouvert |
| AUDC-F2 | Finition | Trois styles de bouton dans le panneau Équipe. | observé | Un style. | S | Phase 73 | ouvert |
| AUDC-F3 | Finition | Bouton de thème de 44 px parmi des boutons de 36 px. | observé | Une taille. | S | Phase 80 | ouvert |
| AUDC-F4 | Finition | Chiffres en police à chasse fixe dans des phrases en police de texte (« 19 s »). | observé | Chiffres tabulaires de la police de texte. | S | Phase 80 | ouvert |
| AUDC-F5 | Finition | Pastilles ambre et verte au bureau, noires au téléphone. | observé | Mêmes teintes aux deux largeurs. | S | Phase 80 | ouvert |
| AUDC-F6 | Finition | « Verifie » sans accent dans la commande de lancement. Voulu : alphabet fermé de la ligne (LANC-05), déjà consigné comme point de goût au BACKLOG (« résiduels de la Phase 72 »). | observé | Aucune sans décision : attend la prochaine recette de Samuel sur le lancement. | S | BACKLOG (point de goût déjà consigné ; hors réouvertures) | ouvert |
| AUDC-F7 | Finition | L'historique du terminal est perdu au changement d'onglet. | observé | Suit les onglets sans rechargement. | M | Phase 80 | ouvert |

## 2. Idées

Statut : `nouveau`, `précise` une phase inscrite, ou `rouvre` une décision de Samuel. Les seize idées déjà inscrites
(Phases 73 à 77, note `.planning/notes/2026-11-03-cockpit-idees-recherche.md`) ne sont pas recopiées.

| Id | Idée | Ce qu'elle apporte | Statut | Effort | Destination | État |
|---|---|---|---|---|---|---|
| AUDC-I01 | Régie : une liste par état, « À vous » en tête, à la place du canevas de l'onglet Équipe | Répond d'abord à « qui a besoin de moi » ; DESIGNS § 3. | nouveau | M | Phase 73 | ouvert |
| AUDC-I02 | File « À vous » classée par impact | Les attentes triées par le nombre de nœuds du plan qu'elles retiennent en aval. Aucun des quinze outils examinés ne le fait (A5 § 2). | nouveau, précise l'idée 9 | M | Phase 73 | ouvert |
| AUDC-I03 | États lus et vivacité | Un état « au travail » qui décroît vers « silencieux » puis « suspect » faute de signe de vie ; un orphelin nommé. | nouveau | S puis M | Lot 0, par AUDC-D1, D2 et D4 ; Phase 73 (décroissance) | ouvert |
| AUDC-I04 | Fiche d'agent avec fil daté | Durée, contexte, outils, erreurs, jetons, fichiers, dans l'ordre et à l'heure ; DESIGNS § 5. | nouveau | S puis M | Lot 0, par AUDC-D8 ; Phase 74 | ouvert |
| AUDC-I05 | Frise des sessions à horloge commune | Toutes les sessions du dépôt sur un axe, attentes hachurées, commits, compactions, erreurs et réponses humaines posés dessus ; modes Horloge et Événements ; DESIGNS § 4. | précise l'idée 1 (Phase 74) | M | Phase 74 | ouvert |
| AUDC-I06 | Relecture d'une mission au curseur | Le curseur de la frise allume en même temps les fichiers touchés sur la carte Code et le nœud du plan. | précise l'idée 3, lien nouveau | L | Phase 74 | ouvert |
| AUDC-I07 | Coût, contexte et limites par agent | Jetons, durée, coût estimé, part du contexte, limites de 5 h et de 7 jours, temps d'agent perdu à attendre l'humain. Réserve : les limites ne sont publiées que pour les abonnements Pro, Max et Ultra, après la première réponse, sans compter les sous-agents (A6 § 3). | étend l'idée 2 | M | Phase 74 | ouvert |
| AUDC-I08 | Coût par phase et par étage | Agrégé par tête, manager et worker, puis par mission et par phase. Ailleurs le coût s'arrête à la session. Recoupe la Phase 52 (télémétrie et coût de mission, jalon ECC) : un seul calcul à partager. | nouveau | M | Phase 74 puis 77 | ouvert |
| AUDC-I09 | Notifications | Titre d'onglet « (2) vous attendent », pastille sur l'icône, notification du système en option. Trois motifs seulement : besoin d'une réponse, fin, échec. | nouveau | S | Phase 73 | ouvert |
| AUDC-I10 | « Ailleurs sur ce poste » | Une ligne qui dit qu'une session d'un autre lab vous attend (c'était le cas pendant l'audit). À borner : nombre et nom du lab seulement. | nouveau | S | Phase 73 | ouvert |
| AUDC-I11 | Agir sur une session : ouvrir, écrire, arrêter, bifurquer | Chaque action prépare une commande dans le terminal ; la touche Entrée l'exécute. Comprend « Demander l'arrêt » d'un orphelin (AUDC-D4). | rouvre Q8, P68-D-03 et la frontière de la Phase 72 (AUDC-Q3) | M | Phase 81, reportée (AUDC-Q3 : plus tard) | ouvert |
| AUDC-I12 | Radar de collisions | Deux agents, ou deux worktrees, sur le même fichier ou module, signalés avant la fusion sur la carte Code. Sources locales : cibles des outils d'écriture, fichiers modifiés de chaque arbre, `files_modified` des plans d'une même vague (collisions prévues). Un petit projet s'en approche (A5 § 2). | nouveau, prolonge l'idée 8 | M | Phase 75 | ouvert |
| AUDC-I13 | Empreinte en direct sur la carte Code | Les fichiers en cours d'écriture s'allument, avec le nom de l'agent. | précise l'idée 8 | M | Phase 75 | ouvert |
| AUDC-I14 | « Depuis votre dernière visite » | Phases avancées, commits, sessions finies, nouveaux blocages. À avancer : c'est la troisième question d'un pilote. | précise l'idée 15, à avancer | S puis M | Phase 77 | ouvert |
| AUDC-I15 | Résumé d'une session à la demande | « Que s'est-il passé ? » en cinq lignes, écrit par l'agent des questions à partir du fil réduit. | à arbitrer (PU-G-162 : pas de titre généré) | M | Réserve | ouvert |
| AUDC-I16 | Revue par agent | Le diff de ce qu'un agent a changé, portée « dernier tour ». Goulot réel au-delà de cinq à sept agents (A5 § 3). | rouvre P78-D-06 (détail sans diff) | L | Réserve | ouvert |
| AUDC-I17 | Vue de plusieurs labs | Une coquille, plusieurs sources ; simple une fois les données sorties de la page. | nouveau | L | Réserve, après la Phase 79 | ouvert |
| AUDC-I18 | Journal d'événements par les hooks officiels | Un fichier en ajout seul, écrit même quand le serveur est arrêté ; le serveur le suit au lieu de relire les transcripts. | nouveau, socle | M | Phase 79 | ouvert |
| AUDC-I19 | Route d'état en JSON | `vf-signal`, la page et un futur client lisent la même chose ; fin de la collecte en double. | nouveau, socle | M | Phase 79 | ouvert |
| AUDC-I20 | Index incrémental des transcripts et route de frise | Une voie par transcript, lue par décalage d'octets ; parent, rôle, modèle, début, fin, compteurs, segments. Prototype : 147 Ko pour 1 068 transcripts (`sondes/index-proto.mjs`). | nouveau, socle | M | Phase 79 | ouvert |
| AUDC-I21 | Trois graphes reliés | Qui a lancé qui, quel nœud du plan chacun porte, quelle phase avance : aucun outil examiné ne relie les trois, le cockpit les a déjà, séparés. | principe | — | Phases 73 et 74 | ouvert |
| AUDC-I22 | Flux partagé entre onglets | Un seul flux d'événements pour tous les onglets du cockpit. | nouveau, socle | M | Phase 79 | ouvert |
| AUDC-I23 | Projet en couloirs | Les phases rangées par état, lisibles à toute largeur, barre d'avancement par jalon ; le graphe reste à la demande ; DESIGNS § 6. | nouveau | M | Phase 80 | ouvert |
| AUDC-I24 | Palette de commandes | Fichiers, phases, agents et actions dans un seul champ ; le clavier atteint tout. | nouveau | M | Phase 80 | ouvert |
| AUDC-I25 | Bascule liste ou tableau à chaque niveau | Triable, par défaut au téléphone ; les exigences se lisent comme une liste à cocher. | connu du panel (PU-G-033) | M | Phase 80 | ouvert |
| AUDC-I26 | Minicarte et repères de bord | « 16 cartes par là » : on ne se perd plus sur la carte du code. | nouveau | S puis M | Phase 80 | ouvert |
| AUDC-I27 | Mode focus | Sélectionner une carte recompose son seul voisinage, à taille lisible. | nouveau | M | Phase 80 | ouvert |
| AUDC-I28 | Lecteur de transcript plein cadre | Fil daté, filtres (messages, outils, erreurs), suivi en direct. | nouveau | M | Phase 74 | ouvert |
| AUDC-I29 | Barre d'état en pied | Branche entière, état du direct, shell vivant avec « Terminer », heure de la dernière mise à jour. Prolonge M9 et M10. | nouveau | S | Phase 80 | ouvert |
| AUDC-I30 | Onglets sans rechargement et liens de vue | Tiroirs et zoom survivent au changement d'onglet ; « copier le lien de cette vue ». | nouveau, après le socle | M | Phase 80 | ouvert |
| AUDC-I31 | Données hors de la page | Une coquille statique mise en cache, le graphe et l'équipe en JSON ; mise en page en worker au même moment. | nouveau, socle | M | Phase 79 | ouvert |
| AUDC-I32 | Magasin d'état côté page | Alimenté par le flux, panneaux abonnés ; supprime les observateurs de réparation. | nouveau, socle | M | Phase 79 | ouvert |
| AUDC-I33 | Preuves de vérification sur la carte | Critères de validation, captures et rapports préparés par les agents, attachés à la phase ou au nœud (motif 5 de la veille). | précise l'idée 10 | M | Phase 76 | ouvert |
| AUDC-I34 | Bouton de l'étape suivante sur la ligne | « Lire le rapport » d'abord, en lecture seule. « Répondre » et « Recetter » agissent sur une session : par le double geste, et seulement si AUDC-Q3 (motif 4 de la veille). | nouveau | S | Phase 73 | ouvert |
| AUDC-I35 | Plafond de coût par agent ou par mission | Un budget visible, puis une alerte au dépassement (motif 8 de la veille). | nouveau | M | Réserve, avec la Phase 52 | ouvert |
| AUDC-I36 | Cartes « prévues », agent par zone, constats de l'auditeur sur les cartes | Trois idées de l'étude floorplan du 2026-11-01, jamais livrées. | antérieur | M | Phase 75 | ouvert |
| AUDC-I37 | Rattachement durable d'un agent à son nœud | Le nœud est écrit dans chaque mandat ; le registre du verrou survit au relâchement. Fait passer 14 % à 100 %. | nouveau | M | Phase 79 | ouvert |
| AUDC-I38 | État « attend ses agents » | Distinguer une session qui attend ses agents de fond d'une session terminée ou au repos. Sources : la ligne de fin de tour des transcripts (nombre d'agents de fond en attente, sessions seules), ou l'état officiel (`waiting`, `waitingFor` : sens de ces champs à vérifier, A6 ne fait que les lister). | nouveau | S | Phase 73 | ouvert |
| AUDC-I39 | Télémétrie OpenTelemetry comme source du coût par sous-agent | Ses événements portent l'agent et son parent (A5, A6 § 2). Non retenue au versement : aucun exporteur vers un fichier n'est documenté, il faudrait un collecteur local. | à rouvrir si les transcripts ne suffisent pas | M | Réserve | ouvert |
| AUDC-I40 | Motifs moins répandus de la veille | Saisie de tâches en rafale, comparaison de plusieurs essais d'une même tâche, bifurcation et reprise, routines planifiées (A5 § 1). La bifurcation est déjà dans AUDC-I11. | relevé, non instruit | — | Réserve | ouvert |

Deux pistes écartées pour l'instant, gardées pour mémoire :

| Id | Piste | Pourquoi pas maintenant |
|---|---|---|
| AUDC-N1 | Répondre à une permission depuis la page (ou aperçu et réponse sur place, motif 2 de la veille) | Techniquement possible par les hooks, mais cela fait du cockpit un organe de décision, à l'opposé du double geste. À reprendre seulement après un audit de sécurité dédié. |
| AUDC-N2 | Badge de PR et de CI | Les meilleurs outils dérivent l'état de preuves git et CI ; ici il faudrait lire le réseau, écarté par P67-D-02. L'équivalent local existe : l'état des gardes du dépôt et des hooks. |

## 3. Un ajout, un retrait

Chaque phase nomme son retrait au cadrage (contrainte commune du jalon). L'audit en a identifié sept ; deux sont
ajoutés au versement pour la Phase 80.

| Retrait | Compense | Destination |
|---|---|---|
| Le canevas de l'onglet Équipe et sa mise en page pour deux cartes | la régie | Phase 73 |
| Le nom de chaque agent écrit trois fois (titre, description, panneau) | la ligne de régie | Phase 73 |
| La carte « Terminés depuis moins de 24 h » | « Terminé, à relire » et la frise | Phases 73 et 74 |
| La page Équipe reconstruite à chaque requête et rechargée en entier | la route d'état | Phase 79 |
| La collecte refaite par `vf-signal` toutes les dix secondes | la route d'état | Phase 79 |
| Le second flux d'événements de chaque page | un flux par page | Lot 0, par AUDC-H1 |
| La copie renommée de 52 modules dans chaque lab | le serveur lancé depuis le module | Phase 79 |
| Le canevas comme vue par défaut de l'onglet Projet (ajouté au versement) | les couloirs | Phase 80 |
| Les vignettes Backlog et Releases (ajouté au versement) | une liste | Phase 80 |

## 4. Sujets du BACKLOG recoupés

« Clôt par » : le sujet se ferme quand la ligne nommée est livrée. « Recoupe » : la ligne touche le sujet sans le
régler ; il reste ouvert et gagne un renvoi. « Voisin » : même zone, autre problème, aucun effet. « Déjà consigné » :
le sujet dit déjà ce que dit la ligne. Rien ne se ferme d'office.

| Sujet du BACKLOG | Ligne du registre | Effet |
|---|---|---|
| « mineurs d'affichage et sécurité basse », ligne « Carte Session » (badge « En cours » pour tout état non terminé) | — | déjà corrigée dans le code (`c7d96740`, 2026-11-06, PU-G-165 : « en attente » n'a plus de badge) ; ligne du BACKLOG périmée, à clore à sa prochaine passe |
| même sujet, ligne R8 (la carte de mission de l'onglet Projet ne dit pas son état) | AUDC-M3 | voisin |
| « un script de la page Projet peut piloter le chat (`POST /api/ask`) » | AUDC-A-01, AUDC-B-02 | recoupe : le sujet vise le pilotage par script, ces lignes bornent la reprise et le débit |
| « le `claude` lancé depuis le terminal reçoit `CLAUDE_EFFORT` et `CLAUDE_PID` » | AUDC-B-06 | clôt par AUDC-B-06, si les deux variables sont filtrées |
| « état « bloqué » du tiroir « Au travail » sans source (contrat `who@2`) » | AUDC-D9 | clôt par AUDC-D9 : l'état officiel donne la source |
| « distinguer « attend une tâche de fond » de « terminé » (#223, cause 3) » | AUDC-I38 | clôt par AUDC-I38 |
| « Hook `SubagentStop` : bloquer la fin d'un agent tant que `background_tasks` n'est pas vide » | AUDC-D4 | voisin : il prévient l'orphelin à la source, AUDC-D4 le rend visible |
| « synchronisation complète des états de lancement (PU-G-113) » | AUDC-M11 | recoupe : AUDC-M11 ne traite que l'annulation |
| « résumé en langage courant (PU-G-104) et titres de santé à variables (PU-G-080 part C) » | AUDC-M8 | recoupe : la part PU-G-080 seulement |
| « classes C de l'onglet Équipe et du tiroir Git (195, 007, 202, 168) » | PU-G-168 : AUDC-M4 ; PU-G-007 : AUDC-M5 ; PU-G-202 : AUDC-M9 ; PU-G-195 : AUDC-M12 | recoupe, proposition par proposition |
| « résiduels de la Phase 72 », point de goût « intentions en ASCII sans accent » | AUDC-F6 | déjà consigné : AUDC-F6 n'ajoute rien |
| « titre « Health (security only) » et témoin S5.1 visent un bloc masqué sur Projet (DG-15) » | AUDC-M3 | voisin : même bloc Santé, à trancher ensemble |
| « Mod vf-signal : version minimale de Claude Code pour ses hooks » | A6 § 7 | réponse documentaire (mods : Claude Code 2.1.287 ou plus), non mesurée |
| « plusieurs terminaux » | AUDC-I11 | voisin |

## 5. Décisions

### 5.1 À Samuel

Les cinq décisions de fond ont été tranchées le 2026-11-11 : Samuel a retenu l'avis de la session principale (Samuel, session principale Claude Code, 2026-11-11, mot pour mot : « Prends ton avis pour chaque point que tu m'as demandé. »). La direction des quatre formes (régie, frise, fiche d'agent, Projet en couloirs) est retenue de la même façon ; leur détail reste à recetter. Les huit réouvertures plus bas restent ouvertes.

| Id | Décision | Ce qui en dépend | Ce que l'audit en dit | Tranché le 2026-11-11 |
|---|---|---|---|---|
| AUDC-Q1 | Le mode de lancement « hérité du poste » peut valoir le mode sans permissions. Il vient de la réponse libre « choix + hérité don bypass », lue ainsi par le manager sans nouvelle question (P72-D-02). | Rien dans les lots ; c'est un comportement déjà livré. | À confirmer, ou à retirer. | Laissé tel que livré : le mode reste dans la liste, rien ne change dans le code. L'avis de la session principale n'avait pas été écrit avant la délégation : à reconfirmer à la prochaine recette du lancement. |
| AUDC-Q2 | Conserver un index des sessions sur disque : une donnée persistée nouvelle (heures, durées, jetons, verbes). | Le cadrage de la Phase 79. Sans lui, l'index se recalcule depuis les transcripts à chaque démarrage (9,4 s pour 2,6 Go, à borner à la fenêtre affichée). Une fenêtre au-delà de 24 h rouvre en plus P69-D-18. | Heures, durées, jetons et verbes tiennent dans les limites de confidentialité actuelles ; les sorties d'outil restent dehors. | Oui : index sur disque, borné à heures, durées, jetons et verbes. La fenêtre de 24 h est gardée : P69-D-18 n'est pas rouverte, la fenêtre « 7 j » sort du périmètre. |
| AUDC-Q3 | Des actions depuis l'onglet Équipe (ouvrir, écrire, arrêter une session). | La Phase 81 et « Demander l'arrêt » d'un orphelin (AUDC-D4). Rouvre Q8 (pas de terminal sur l'onglet Équipe), P68-D-03 (gestes réservés aux agents de la session courante) et la frontière de la Phase 72 (« Reprendre » sur les cartes Équipe, hors périmètre). | Possible par le double geste ; à décider après la régie. | Plus tard : la Phase 81 et les gestes sur une session restent hors des vagues en cours. |
| AUDC-Q4 | Faire de la vue d'agents de Claude Code (`claude agents --json`) la source de référence de l'état. | Le cadrage des Phases 73 et 74. La commande est documentée mais en aperçu : son format peut changer. | Les transcripts restent le repli, derrière le contrat de forme existant. | Oui : source de référence, derrière le contrat de forme, transcripts en repli. |
| AUDC-Q5 | Moteur vendorisé : suivre l'amont, ou assumer le fork. | AUDC-H5 et le cadrage de la Phase 79. | Les deux se défendent. Ce qui coûte, c'est de ne pas choisir. | Assumer le fork. |

Réouvertures, à trancher au cadrage de la phase qui porte la ligne, ou avant de la sortir de la réserve :

| Ligne | Décision rouverte |
|---|---|
| AUDC-M2 | Q10, « Flou gardé, texte court » |
| AUDC-M5 | P70-D-22 (badge « au travail » réduit à son point) et « Garder ce compromis » sur la troncature de l'en-tête (PU-G-001) |
| AUDC-M8 | P70-D-04, constats de Santé laissés en anglais |
| AUDC-M10 (pastille) | P71-D-02, rien sans l'option `--terminal` |
| AUDC-B-05 | P72-D-20, le mode retenu vit dans un fichier du lab et survit aux relances ; à trancher avec AUDC-Q1 |
| AUDC-BL1 (plan B) | PU-G-026, plancher de zoom sur Code seul |
| AUDC-I15 | PU-G-162, pas de titre généré |
| AUDC-I16 | P78-D-06, détail de commit sans diff |

### 5.2 Prises au versement

Décisions déléguées par Samuel (message session principale, 2026-11-08), option recommandée ; le versement lui-même
est une demande de Samuel (session principale, 2026-11-10).

| Id | Choix |
|---|---|
| AUDC-V1 | L'audit vit sous `.planning/research/`, dans la forme « étude et annexes » déjà utilisée. |
| AUDC-V2 | Le lot 0 se traite en mission hors phase ; ses lignes n'entrent pas au ledger d'exigences, ce registre les suit. |
| AUDC-V3 | Le socle est une phase à part (79), et non la première vague de la 74 comme la page de l'audit le proposait : les Phases 75 et 77 en dépendent aussi. La 73 n'en dépend pas : elle part des états lus par le lot 0. |
| AUDC-V4 | Les Phases 79, 80 et 81 sont inscrites au jalon `vibeflow-v2.0` ; la 81 ne démarre pas sans AUDC-Q3. |
| AUDC-V5 | Ordre recommandé : lot 0, puis 79 et 80 en parallèle, 73 dès le lot 0 livré, 74 après la 79, puis 75, 76, 77. |
| AUDC-V6 | Les buts des Phases 73 à 77, arbitrés le 2026-11-03, ne sont pas réécrits : l'audit s'y ajoute comme source de cadrage, et leurs dépendances gagnent le lot 0 ou la Phase 79. |
| AUDC-V7 | Dépôt public : dans les fichiers versés, les scénarios de AUDC-A-01, A-02, A-03, B-01 et B-05 sont ramenés à leur classe et les captures ont leurs identifiants masqués. Le détail de reproduction reste sur le poste de l'audit (copie des rapports bruts dans le dossier non suivi `.playwright-mcp/audit/rapports-bruts/` de l'arbre principal, transcripts de la session) jusqu'aux correctifs. |
| AUDC-V8 | Pour le lot 0, l'état officiel des sessions est un enrichissement optionnel, jamais la source unique : absent ou illisible, le cockpit garde sa lecture actuelle. AUDC-Q4 reste entière pour la suite. |
| AUDC-V9 | Le lot 0 versé (28 lignes) est plus large que celui de la page de l'audit (13 lignes) : il prend aussi les corrections de la taille d'un commit qui ne demandent aucune décision de conception (sécurité basse, états muets, accessibilité immédiate), et AUDC-A-02, que la page plaçait au lot 1, parce que c'est une fuite de données hors du lab. |
| AUDC-V10 | Les fichiers internes de Claude Code (`~/.claude/sessions`) ne sont pas lus, à rebours de la recommandation 1 du rapport A1 : leur format n'est pas documenté, et la commande officielle donne les mêmes états. |
| AUDC-V11 | La phrase de Samuel du 2026-11-10, « Et que ça soit corrigé et qu'on applique les choses qui ont été vues », est lue comme la validation humaine (ADR-031) des corrections du lot 0. C'est une lecture de la session principale : si Samuel ne voulait que l'inscription au planning, la mission s'arrête et la branche reste sans suite. Intention confirmée par Samuel le 2026-11-11 (session principale Claude Code) : « L'objectif sera de lancer plusieurs managers sur tous les points de l'audit pour faire une release le plus propre possible du cockpit, d'après ce que l'audit nous a conseillé. » |
| AUDC-V12 | AUDC-H3 : la règle « une relance qui change une option remplace le serveur et l'écrit au journal » précise la correction du rapport A2 (« relance seulement si le code a changé »), qui ne disait rien d'une option ajoutée comme `--terminal`. |
