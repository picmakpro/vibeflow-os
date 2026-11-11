# Phase 75: L'activité posée sur le code — hotspots, couplage, gardes, empreinte - Context

**Gathered:** 2026-11-11
**Status:** Cadrée (2026-11-11) — frontière de questions vide côté mission ; trois questions non bloquantes à Samuel encore ouvertes, Q-75-3 et Q-75-4 tranchées
le 2026-11-11 (section « À Samuel ») ; bâtie sur les contrats figés de la Phase 79 (branche `feat/phase-79-socle-cockpit`, commit
`3119d82a`, `79-CONTEXT.md` § « Contrats fournis », C0 à C6, amendés par `2ae6607a` (A1-A14) et `6f66d878` (A21-A28)) ;
les sept manques relayés à la 79 sont fermés par A21 à A27 (section « Contrats de la Phase 79 retenus »).

Cadrage par le manager de la mission Phase 75 (`vf-dev-manager`, worktree `.claude/worktrees/phase-75`, branche
`feat/phase-75-activite-sur-le-code`, base `origin/integration/cockpit-audit` à `f763b556` : release `v2.77.0` alignée,
lot 0 de l'audit fusionné). Jalon `vibeflow-v2.0`, compartiment `fiabilite`. Cadrée en parallèle des Phases 73, 74, 76,
77, 79 et 80 (vague de cadrage demandée par Samuel, session principale Claude Code, 2026-11-11). Mode autonome : les
zones grises ont été tranchées par quatre panels de recherche (forme, données git, empreinte, gardes et retrait), après
deux éclaireurs en lecture seule (sources, code présent).

**Exigences :** ACTV-01 à ACTV-12. Préfixe neuf, vérifié libre le 2026-11-11 sur tous les ledgers
`.planning/workstreams/*/REQUIREMENTS.md`, `.planning/` et `docs/` de la base.

**Sources :** ROADMAP § Phase 75 (but, inchangé) ; `.planning/notes/2026-11-03-cockpit-idees-recherche.md` idées 5 à 8 ;
`.planning/research/2026-11-10-audit-cockpit-etude.md` § 3, § 6, § 8.2 ; `REGISTRE.md` AUDC-I12, I13, I36 ;
`DESIGNS.md` § 9 ; `docs/research/2026-11-01-etude-floorplan-cockpit.md` (I36) ;
`.planning/missions/2026-11-11-audit-cockpit-lot-0.md` (AUDC-A-04, environnement git durci) ; registres 67, 69, 70,
71.5 et 78.

<domain>
## Phase Boundary

La carte Code reçoit des **lentilles d'activité**, une à la fois : **points chauds** (fréquence de changement croisée avec
la taille), **couplage** (fichiers qui changent ensemble, montrés autour de la carte sélectionnée), **gardes** (fichiers
qu'une suite ou un gate nomme, et zones sans témoin), **empreinte** (fichiers lus ou modifiés par les agents vivants ou
finis dans les 24 h, en direct). Un **radar de collisions** signale, sur la carte, un même fichier visé par deux agents,
deux branches ou deux plans d'une même vague, avant la fusion. Des **cartes « prévues »** montrent les fichiers que les
plans non faits vont créer. Tout se lit en glyphe et en mot, sans fond teinté ni couleur d'alerte ; rien n'est écrit dans
le lab ; aucune lecture réseau.

**Absorbe :** AUDC-I12 (radar de collisions), AUDC-I13 (empreinte en direct), AUDC-I36 pour deux idées sur trois (cartes
« prévues », agent par zone fondu dans l'empreinte) ; idées 5, 6, 7 et 8 de la note du 2026-11-03 ; la part « hotspots et
couplage » laissée à la 75 par P78-D-08.

**Retire (un ajout, un retrait) :** la couche déclarative « Travail récent » (fichiers des deux dernières phases faites :
`recent-work.json`, tableau `ui/25-recent.js`, classes `.recent`/`.recent-in`, bascule binaire) et `scripts/recent.mjs` du
moteur, jamais appelé. L'entrée du menu « ⋯ » qui la portait reste au même endroit, avec un libellé et une pastille de
compte, et devient le sélecteur de lentilles (P75-D-28, arbitrage Samuel, AskUserQuestion session principale, 2026-11-11).

**Hors périmètre :**
- Les constats de l'auditeur posés sur les cartes (troisième idée de AUDC-I36) : aucune source typée sur disque ; en
  réserve, déclencheur : un fichier de constats typé et versionné existe (P75-D-13).
- Une carte de chaleur à fond teinté ou dégradé (rouvrirait Q9 et `DESIGN.md` § 9 : question à Samuel, Q-75-1).
- L'empreinte au-delà de 24 h et les cibles de fichiers persistées sur disque (rouvrirait AUDC-Q2 : Q-75-2).
- Le travail non commité lu par `git status` périodique ou `git diff` contre l'arbre de travail (P75-D-09).
- La navigation de la carte (clavier, minicarte, ajustement, palette) : Phase 80. La frise et la relecture liée à la
  carte (AUDC-I06) : Phase 74. La collecte, l'index des transcripts et la route d'état : Phase 79.
- Toute action sur une session ou sur le dépôt (Phase 81, reportée ; P78-D-07).
</domain>

<decisions>
## Implementation Decisions

Aucune décision ci-dessous n'est un arbitrage de Samuel. Toutes sont des **décisions déléguées par Samuel (message session
principale, 2026-11-08), option recommandée**, prises sur la table comparative d'un panel de recherche (2026-11-11) et
contrôlées contre les arbitrages en vigueur cités. Les arbitrages de Samuel déjà rendus qui s'appliquent sont listés à part
et ne sont pas rouverts.

### Arbitrages en vigueur qui bornent la phase (rappel, non rouverts)

- **AUDC-Q2** (Samuel, 2026-11-11) : index des sessions sur disque borné à heures, durées, jetons et verbes ; fenêtre de
  24 h. **AUDC-Q4** : `claude agents --json` source de référence de l'état, transcripts en repli. **AUDC-Q5** : fork du
  moteur vendorisé assumé. **AUDC-Q3** : actions sur une session reportées.
- **Q9** (réponse du 2026-11-06) et `DESIGN.md` § 9 : ni couleur d'alerte ni fond teinté ; un glyphe seul porte la teinte,
  le mot reste neutre. **P71.5-D-19** (sans fond teinté), **D-21** (barres neutres sauf « en cours »), **D-28** (plus
  d'anneau coloré), **D-29** (aucun jeton supprimé ni renommé), **D-01** (grille d'espacements fermée).
- **Q11** (points de rupture inchangés), **Q12** (un tiroir latéral ne pousse jamais la carte ; le tiroir du terminal
  réserve sa place sous la carte, P71-D-35), **P78-D-04** (pas de 4ᵉ onglet), **P70-D-01** (composition du menu « ⋯ »).
- **P67-D-02, P69-D-09** (aucune lecture réseau), **P67-D-06** (rien écrit dans le lab hors `.vibeflow/cockpit/`),
  **P68-D-34** (aucun fichier du lab exécuté), **P69-D-16** (verbe et cible réduite, jamais l'argument), **P69-D-19**
  (jamais de sortie d'outil, jamais exporté), **P69-D-23** (calcul dans le socle, JSON versionné), **P67-D-14** (dernière
  commande jamais dans le flux, un fichier ou l'export).
- **P78-D-08** (Samuel, 2026-11-05) : « la Phase 75 garde hotspots et couplage ». **P78-D-21** (ratifiée par Samuel) :
  aucun filtre du dépôt exécuté, `git diff` contre l'arbre de travail proscrit.

### Forme sur la carte

- **P75-D-01 (lecture du but : « se colore » = « se marque »).** Une lentille marque une carte par un **glyphe à trois
  paliers en teinte neutre** (`--text-3` ou équivalent existant) suivi d'un **mot chiffré** (« 41 changements », « aucune
  suite ne le nomme », « écrit par vf-coder »), placé dans l'emplacement droit du pied de carte (celui qu'occupent `.rw` et
  `.vst`). La seule teinte employée est celle d'état « en cours » (`--recent`), réservée au fichier en cours d'écriture par
  un agent actif (P71.5-D-21). Ni fond, ni liseré, ni anneau, ni halo, ni dégradé, ni teinte d'état détournée en échelle
  d'intensité. Même lecture que DESIGNS:98 pour la Phase 74 ; le but n'est pas réécrit (AUDC-V6). Une vraie carte de
  chaleur est la question Q-75-1. (Panel A, option A.)
- **P75-D-02 (lentilles exclusives, sélecteur dans le menu existant).** Une lentille à la fois : Aucune, Points chauds,
  Couplage, Gardes, Empreinte. Le sélecteur vit dans le menu qui porte aujourd'hui la bascule « Travail récent » (menu
  « ⋯ » de P70-D-01 ; même emplacement en largeur de bureau) : aucun bouton d'en-tête ajouté, aucun 4ᵉ onglet, rien qui
  pousse la carte. La légende des paliers de la lentille active tient sous le sélecteur. Superposition de lentilles
  écartée (un seul emplacement de pied, encombrement). (Panel A.)
- **P75-D-03 (géométrie invariante).** Changer de lentille ne change ni la taille ni la position d'une carte : la place du
  glyphe et du mot est réservée dans le pied, ou le marquage remplace un contenu de même hauteur. Aucune relance du
  placement (ELK) au changement de lentille ni à une mise à jour en direct. Témoin exigé : géométrie mesurée avant et
  après bascule, identique. (Panel A, risque AUDC-AM3.)
- **P75-D-04 (fichier et agrégat aux ancêtres).** Les cartes de fichier portent leur palier ; une carte de nœud porte le
  palier maximal de ses fichiers et un compte (« 3 chauds », « 12 sans témoin », « 2 en écriture »). Pas de somme (biais
  de taille). Le couplage, relationnel, n'est pas agrégé. Le nœud « non assignés » (616 fichiers sur 1 397 ici) suit la
  même règle ; son poids est dit, pas corrigé (le rattachement relève de l'extracteur de la 67). (Panel A.)
- **P75-D-05 (canal de marquage unique).** Un seul mécanisme de la page pose les marques de carte : une couche nommée, une
  table `id → {palier, glyphe, mot, infobulle}`, l'agrégat aux ancêtres, une couche active à la fois. L'objet global du
  moteur est gelé (Phase 80) : le canal vit sous un espace de noms à part ; le point d'accroche dans le rendu des cartes,
  s'il en faut un, est posé dans le source du moteur (fork assumé, AUDC-Q5 ; après la vague 1 de la 79, aucun diff de
  patch). Il s'initialise par `VF_COQUILLE.surOnglet(rappel)` quand l'onglet vaut Code et se nettoie quand on le quitte
  (amendement A30 de la 79, `74501bb0`) ; une surcouche éventuelle passe par `window.VF_SURCOUCHES` (P80-D-33 à D-41).
  **Qui le pose — amendé le 2026-11-11 (décision déléguée par Samuel, message session principale, 2026-11-08, option
  recommandée ; coordination de détail entre la 74 et la 75 tranchée par la session principale le 2026-11-11) :** la 75
  pose le canal (plan 75-07) **et rebranche, dans le même lot, le geste « Voir sur la carte » de la 74** (74-06,
  `ui/74-vf-frise-carte.js`, P74-D-12) sur une **couche temporaire** du canal : une ligne dans ce fichier de la 74, ajoutée
  aux `files_modified` de 75-07, avec un témoin capable de rougir (le geste marque les cartes ; `showBoard` n'est plus
  appelé pour ce geste). Motif : la 74 passe avant la 75 mais P74-D-31 lui interdit tout fichier du moteur, donc
  l'accroche dans la page ; sans ce rebranchement, deux mécanismes coexisteraient (marque et tableau). Point d'appel,
  liste passée et témoin à adapter : ceux que la 74 écrit dans 74-06 (`origin/feat/phase-74-equipe-dans-le-temps`).
  L'accroche vit dans la coquille unique de la 79 (C5, `VF_COQUILLE.surOnglet`, A30), jamais dans une page que la 79
  remplace. Les fichiers d'interface neufs de la 75 sont nommés `ui/75-vf-*` (dont `ui/75-vf-marques.js` et
  `ui/75-vf-marques-glyphes.js`), hors de la plage `ui/74-vf-*` de la 74. `showBoard` reste dans le moteur pour ses
  autres appelants (Santé, Écrans). **Ordre de chargement indépendant du nom** (condition de la session principale,
  2026-11-11) : aucun consommateur n'appelle le canal au chargement de son script ; le canal n'est résolu qu'au geste ou
  à l'initialisation par `surOnglet`, par une recherche tardive de `window.VF_MARQUES` (absent → geste sans effet visible
  ni erreur, puis appliqué quand le canal s'enregistre) ; témoin capable de rougir : un consommateur chargé avant le canal
  ne casse rien, et le geste de la 74 marque bien les cartes. (Panel A.)
- **P75-D-06 (accessibilité).** Le mot de la lentille active entre dans le nom accessible de la carte (forme posée par la
  Phase 80, AUDC-BL2) ; toute marque se lit sans la couleur ; contraste du glyphe ≥ 3:1 sur `--raise` et `--canvas` dans
  les deux thèmes.

### Données git (points chauds, couplage, collisions committées)

- **P75-D-07 (fenêtre et formule des points chauds).** Commits hors merges des **90 derniers jours, plafonnés à 5 000**
  (mesuré ici : 3 371 commits, 0,18 s, 0,95 Mo ; `-n 500` ne couvre que cinq jours sur ce dépôt). Quand le plafond mord,
  la lentille l'écrit (« fenêtre réduite à N commits »). Point chaud = nombre de commits de la fenêtre × `loc` du scan,
  servi en rang et en trois paliers par quantiles. Renommages suivis par `-M` explicite (le chemin actuel hérite de
  l'historique) ; `--follow` écarté (un appel par chemin). Clone superficiel : mention « historique partiel ». `-n 500` de
  P78-D-23 reste la borne du graphe de la 78 ; c'est un autre appel, P78-D-23 n'est pas rouverte. (Panel B.)
- **P75-D-08 (couplage).** Paires co-changées aux seuils par défaut de code-maat : ≥ 5 révisions communes, ≥ 5 révisions
  par fichier, degré ≥ 30 %, commits de 30 fichiers au plus ; liste fixe de bruit (CHANGELOG, VERSION, manifestes de
  version, fichiers de verrou). Mesuré sur 90 jours ici : 165 paires, 6 voisins au plus par fichier. Montré **à la
  sélection d'une carte seulement** : ses voisins (5 au plus, avec leur %) portent la marque, et une section « Change
  souvent avec » s'ajoute au panneau de détail. Jamais de liens globaux ajoutés au graphe (1 905 liens déjà). (Panel B.)
- **P75-D-09 (calcul, cache, route).** Une tâche asynchrone recalcule points chauds, couplage, gardes et collisions
  committées sur la **signature de HEAD et des refs** (règle de P78-D-15, ~30 ms), en incrémental quand l'ancien HEAD est
  un ancêtre ; mono-vol ; résultat en mémoire, servi par une route GET bornée sous `/api/vf/`, derrière Host, Origin et
  jeton, schéma `vibeflow/cockpit-activite@1` déclaré dans `vf-cockpit-interface.json`. Hors de la boucle de collecte
  (cible AUDC-H2) ; une requête pendant le calcul répond. Toute lecture git passe par `envGit` et `lancerGitAsync`
  (`vf-cockpit-git-durci.mjs`, AUDC-A-04) ; sortie bornée, parseur vérifiant l'alignement. Aucun cache disque dans la 75
  (coût mesuré sous la seconde) ; s'il devient utile, il vivra sous `.vibeflow/cockpit/` (P67-D-06). Calcul hors de
  `graph.json`, dans le sens de la Phase 79 qui sort les données de la page. (Panel B.)
- **P75-D-10 (collisions committées).** Par **paire de HEAD distincts** des worktrees vérifiés (P78-D-38) :
  `merge-base A B`, puis `diff-tree -r --name-only -z` de chaque côté, intersection ; plafond de 12 HEAD (66 paires),
  plafond écrit quand il mord ; cache par paire de sha. La base unique `main` est écartée (319 fausses collisions mesurées
  sur 9 worktrees partis de la même branche d'intégration). Ni `git status` périodique ni `git diff` contre l'arbre de
  travail : P78-D-21 intacte, P78-D-23 et P78-D-32 (décisions de manager) gardées. Le non-committé passe par l'empreinte
  des agents (P75-D-12). (Panel B, option a'.)
- **P75-D-11 (dégradation).** Lab hors dépôt ou git absent : les lentilles git sont absentes du sélecteur, la carte est
  identique en données à celle d'un lab avec git en lentille « Aucune » : mêmes cartes, mêmes liens, aucune marque
  (P78-D-11). La réserve du pied (P75-D-03) est posée dans les deux cas, donc la géométrie ne dépend pas de git ; la
  lecture « octet pour octet » de la version d'avant la phase est abandonnée pour cette seule raison (75-RESEARCH.md O-1,
  critique de la spec F3). Erreur, délai, sortie trop longue : « indisponible » sur la lentille seule, jamais
  un résultat partiel présenté comme complet (P78-D-22). Fenêtre vide : « aucune modification sur 90 jours ».

### Empreinte des agents (direct)

- **P75-D-12 (source et mémoire).** L'empreinte vient du champ **`cibles` des voies de la route de frise de la Phase 79**
  (contrat C3, `vibeflow/cockpit-frise@1` : `{ etat: "ok" | "en-construction", ecritures: [{cible, n, dernierMs}] (≤ 200),
  lectures: [...] (≤ 200) }`), lu par la page via le magasin `window.VF_ETAT` (C4). **En mémoire seulement**, jamais dans
  l'index sur disque (C1, AUDC-Q2 tenue ; question S-1 de la 79). Pendant la reconstruction au démarrage
  (`cibles.etat: "en-construction"`), la lentille et le radar disent « empreinte en cours de relecture, radar incomplet »,
  jamais « aucune collision ». Fraîcheur : la signature de l'événement `frise` couvre les `cibles` (A21) ; la page relit
  `GET /api/vf/frise?champs=cibles` (A28) à son changement, jamais par sondage. Lectures = `Read` seul ; écritures =
  `Write`, `Edit`, `MultiEdit`, `NotebookEdit` ; `Grep`, `Glob`, `Bash` ne produisent aucune cible (A24). Jamais l'argument, jamais la sortie
  d'outil, jamais exporté ; section exclue de l'export (P69-D-16, D-19, P67-D-14). Limite dite sur la lentille :
  « écritures par commande non vues ». (Panel C, options a et b.)
- **P75-D-13 (états et noms).** Trois degrés, d'après l'état de l'agent tel que la 79 le publie (`claude agents --json`
  pour les sessions, AUDC-Q4 ; repli transcripts pour les sous-agents) : **en cours** (dernier fichier écrit d'un agent
  actif : glyphe à la teinte « en cours » + mot), **modifié** / **lu** (agent vivant, glyphe neutre ; « lu » plus discret
  que « modifié »), **fini** (agent terminé dans les 24 h, grisé, repliable, P69-D-18). Pas de minuteur côté page. Nom
  affiché : le rôle, puis « · nœud X » si le rattachement existe, puis l'arbre si deux agents du même rôle sont vivants ;
  pour une session, son titre, sinon « session · arbre » ; jamais l'identifiant brut. « La mission en cours » = tous les
  agents de l'équipe dans les arbres du lab ; un filtre par mission s'offre quand le rattachement existe ; un agent non
  rattaché est dit tel, jamais deviné (P69-D-15). « Agent par zone » (AUDC-I36) = l'agrégat de cette lentille sur les
  cartes de nœud. (Panel C ; panel D pour I36.)
- **P75-D-14 (normalisation des chemins).** Tout chemin est ramené à `{arbre, chemin relatif à l'arbre}`. La 79 fournit
  la cible relative à la racine réelle de l'arbre de la voie quand cet arbre est sous le lab (A22), calculée sur le
  chemin réel par la fonction unique de la classe AUDC-A-02 (A23). Depuis l'arbitrage Samuel du 2026-11-11 (Q-75-4 = S-3,
  P75-D-29) et l'amendement A45 de la 79 (P79-D-33) : un worktree **prouvé** du même dépôt (`verifie: true` dans
  `cockpit-git-worktrees@1`) compte comme le lab ; chaque cible arrive sous la forme `{ arbre, cible, n, dernierMs }`,
  `arbre` valant `null` pour l'arbre principal ou le `nom` du worktree vérifié, `cible` relative à la racine réelle de
  cet arbre ramenée au sous-dossier du lab ; le radar joint par le couple (`arbre`, `cible`) et voit ces worktrees. Un
  dossier qui n'est pas un worktree prouvé du dépôt reste « un fichier hors du lab » : la lentille et le radar le
  **disent** (« N écritures hors du lab, non vues par le radar »), jamais en silence. Une écriture dans un worktree retombe sur la carte du même chemin
  relatif. Seul un chemin qui a déjà une carte est dessiné ;
  les autres sont comptés (« N hors carte », « N hors du lab »), jamais affichés. Sorties de `diff-tree` : relatives au
  dépôt, préfixe du lab retiré si le lab n'est pas à la racine. (Panels B et C.)

### Radar de collisions

- **P75-D-15 (trois sources, une forme).** Signal quand un même fichier est visé par : (1) deux agents d'arbres différents
  dans la fenêtre, tant que les deux worktrees existent ; deux agents du même arbre seulement s'ils sont vivants en même
  temps et ne sont pas parent et enfant ; (2) deux branches (P75-D-10) ; (3) deux plans de la **même vague** de la même
  phase (`files_modified`, déjà lus par `vf-cockpit-project.mjs`) — signal « prévu ». Les lectures n'entrent jamais dans
  une collision. Forme : un glyphe neutre de forme distincte et un mot (« écrit par 2 agents », « modifié sur 2 branches »,
  « prévu par 2 plans, vague N ») dans le pied, une section du panneau de détail avec les noms, et un compte visible sans
  lentille active à un emplacement que fixe la spécification d'interface (jamais une couleur d'alerte). (Panels B et C.)

- **P75-D-30 (radar et forme A45 — précisions du 2026-11-11).** Décision déléguée par Samuel (message session principale,
  2026-11-08), option recommandée, sur les deux points relayés par la session principale :
  (1) la valeur « un fichier hors du lab » est une **sentinelle, pas une cible** : elle est écartée de toute jointure
  (deux écritures non prouvées de deux agents ne font jamais une collision, bien qu'elles portent le même couple
  (`null`, sentinelle)) et comptée à part (« N écritures hors du lab, non vues par le radar ») ; témoin capable de rougir
  (deux agents, deux écritures non prouvées → aucune collision ; mutant « sentinelle jointe » rouge) ;
  (2) le même chemin relatif dans deux arbres différents (`arbre` différent) n'est pas le même fichier sur le disque :
  c'est le **même fichier logique sur deux branches**, ce qui annonce un conflit de fusion ; le radar le signale sous un
  mot distinct (« modifié dans 2 arbres : conflit de fusion possible »), jamais confondu avec la collision dans un même
  arbre (« écrit en même temps par 2 agents ») ; la carte, elle, est retrouvée par `cible` seule, la classification de
  la collision par `arbre`. Témoins : un même `cible` dans deux arbres → signal « 2 arbres », pas « même arbre » ; le même
  `cible` dans le même arbre par deux agents vivants non parent-enfant → « même arbre » ; mutants croisés.

### Gardes

- **P75-D-16 (source).** Règle de citation déjà jouée par la CI (`scripts/ci-suites-perimetre.sh`, arbitrage Samuel,
  AskUserQuestion session principale, 2026-11-07, « Module + dépendances citées »), **réécrite en lecture dans le socle** :
  un fichier est **gardé** quand une suite découverte (même motif que `ci-shard-suites.sh --all`) ou un gate appelé par
  `ci.yml` nomme son chemin, ou son nom s'il n'est pas ambigu. La part « module » de la règle (sur-sélection voulue en
  CI) n'entre pas dans le témoin. Rien n'est exécuté (P68-D-34). Glyphe distinct « est une garde » pour les fichiers des
  six classes de `check-gate-touche.sh`, tiré du même motif de découverte (pas de seconde liste). Une suite d'équivalence
  compare le calcul du socle à `ci-suites-perimetre.sh` sur des diffs témoins (le script s'exécute dans les tests du
  dépôt, jamais par le cockpit). (Panel D, a + b réduite.)
- **P75-D-17 (zone sans témoin, labs non VibeFlow).** Zone sans témoin = carte de code (ni doc, ni suite, ni fixture)
  qu'aucune suite ni aucun gate ne nomme ; mot affiché « aucune suite ne le nomme », jamais « non testé » (P69-D-09) ; au
  nœud, « n fichiers sur m sans témoin ». Sur un lab qui n'est pas VibeFlow, la lentille est absente et le dit (« gardes
  non lues sur ce lab ») ; jamais « tout est sans témoin » (P67-D-01, « Code riche ici, brut ailleurs »). Calcul dans la
  tâche de P75-D-09, sur la signature de HEAD, jamais au tick du flux.

### Cartes « prévues » (AUDC-I36)

- **P75-D-18.** Les fichiers des `files_modified` des plans non faits qui n'existent pas encore (aujourd'hui jetés par le
  filtre de `vf-cockpit-build.mjs:77`) sont injectés par un **annotateur** inscrit d'une ligne dans la table de
  `vf-cockpit-build.mjs` (A27, plan 79-05), donc **après** la construction du graphe par le moteur et à chaque
  assemblage ; un changement de `.planning/` seul ne reconstruit pas le graphe Code : la carte prévue suit l'assemblage,
  tandis que la collision « prévue » (P75-D-15), calculée côté serveur sur les données Projet rafraîchies à chaque
  événement `structural`, reste fraîche. Statut
  `prévu` (mécanisme `st-*` et glyphe `.vst` existants), rattachés à un nœud par les globs du moteur, sinon « non
  assignés ». Jamais injectés dans le scan (Santé les compterait « inutilisés »). Les actions « ouvrir » et « taille »
  sont absentes sur une carte prévue. Chemin `files_modified` hors du lab ou malformé : ignoré, compté. (Panel D.)
- **P75-D-19 (constats de l'auditeur, report).** La troisième idée de AUDC-I36 part en réserve : `vf-auditer` n'écrit rien
  sur disque, ses constats ne vivent que dans des transcripts (sortie d'outil, interdite par P69-D-19) ou en prose dans les
  `*-SECURITY.md`. Déclencheur : un fichier de constats typé et versionné existe. Recoupe Santé (AUDC-M8, Phase 80).

### Retrait

- **P75-D-20 (retrait principal — ferme depuis P75-D-28).** Retirés : l'écriture de `recent-work.json`
  (`vf-cockpit-build.mjs:70-80`), le tableau `ui/25-recent.js` (patchs du moteur), les classes `.recent`/`.recent-in` et
  l'infobulle `recentTip`, la bascule binaire « Travail récent », et `scripts/recent.mjs` du moteur (jamais appelé par
  l'assemblage VibeFlow) ; une trace `RETRAIT` dans `VENDORED.txt` dans la forme que lui laisse 79-01. Le jeton `--recent`
  reste (P71.5-D-26, D-29 ; il porte la teinte « en cours »). L'entrée du menu « ⋯ » qui portait « Travail récent » reste
  au même endroit, avec un libellé et une pastille de compte, et devient le sélecteur de lentilles : P70-D-01 est amendée
  dans cette mesure exacte, pas au-delà (P75-D-28). Motif : la couche est une approximation déclarative que l'empreinte
  observée prend en charge. Retrait **dans le même lot** que la mise en service de l'empreinte, jamais avant. Suites qui
  la citent (`test-cockpit-ecrans-recent.sh`, `test-cockpit-onglet-code.sh` C6.3, `chrome-moteur-carte`, la sonde de lien
  symbolique de `test-cockpit-securite.sh`) **adaptées, jamais supprimées** ; la sonde de lien symbolique est reportée sur
  un autre fichier écrit par le socle (doctrine du 2026-09-16, « ne pas supprimer pour verdir »). Le tableau générique du
  moteur (`showBoard`) reste : la relecture de la 74 s'en sert. (Panel D.)

### Arbitrages de Samuel du 2026-11-11 (AskUserQuestion, session principale ; relayés mot pour mot)

- **P75-D-28 (Q-75-3, couche « Travail récent ») — arbitrage Samuel, AskUserQuestion session principale, 2026-11-11.**
  Réponse cochée : « La remplacer (Recommandé) ». Option telle qu'elle a été présentée : « L'empreinte observée prend sa
  place. L'entrée du menu « ⋯ » reste au même endroit, avec un libellé et une pastille de compte, et devient le sélecteur
  de vues. C'est aussi le retrait que le jalon demande à cette phase. » P70-D-01 est amendée dans cette mesure exacte, pas
  au-delà. Les conditions de départ posées le 2026-11-11 sur les tâches de retrait sont levées ; la branche de repli
  (lentille « Récent ») est retirée des plans.
- **P75-D-29 (Q-75-4 = S-3 de la 79, worktrees hors du dossier du lab) — arbitrage Samuel, AskUserQuestion session
  principale, 2026-11-11.** Réponse cochée : « Les compter comme le lab (Recommandé) ». Option telle qu'elle a été
  présentée : « Un worktree vérifié comme appartenant au même dépôt compte comme le lab : le fichier s'affiche par son
  chemin relatif à la racine du worktree, aucun chemin absolu ne sort. Le radar voit alors ces worktrees. Un dossier qui
  n'est pas un worktree du dépôt reste « hors du lab ». » CKPT-22 est précisée ainsi. Forme du contrat : amendement A45 de
  la 79 (P79-D-33, `origin/feat/phase-79-socle-cockpit`, `6fb94fb7`) ; voir P75-D-14.

### Calcul côté serveur

- **P75-D-22 (où se calculent empreinte, normalisation et collisions).** Côté serveur, dans la réponse de
  `/api/vf/activite`, pour être testés sans navigateur ; la page ne fait que poser les marques. Accès en mémoire à la
  projection de frise et aux données Projet demandés à la 79 (manques n° 8 et n° 9, 2026-11-11). Repli si refusé : la
  page lit `GET /api/vf/frise?champs=cibles` (A28) et le radar d'agents passe côté page, testé par sonde de navigateur.
  Le schéma `vibeflow/cockpit-activite@1` sert des tableaux de tuples, jamais un chemin comme clé d'objet (`porteInterdit`
  teste les clés : un fichier nommé `fil` ferait refuser la réponse). (75-RESEARCH.md O-2.)

- **P75-D-23 (accès en mémoire, amendements A31 à A33 de la 79, `e04c43e7`).** Le calcul côté serveur lit
  `vf-cockpit-instantane.mjs` (`instantane()`, `surInstantane(rappel)`) : `signal` et `projet` (plan 79-09), `frise` avec
  `etatOfficiel` et `cibles` (plan 79-13) ; jamais de collecte déclenchée, jamais de route rappelée par HTTP ; la réponse
  dérivée passe par la réponse gardée commune (A11). Lab en sous-dossier du dépôt : la cible est relative au lab tel qu'il
  apparaît dans l'arbre de la voie, même chemin que les cartes (A33). Le repli de P75-D-22 tombe.
- **P75-D-24 (champs du planning partagés avec la Phase 80).** Partage arrêté entre les deux phases par la session
  principale le 2026-11-11 (P80-D-44, `58881bd3` sur `feat/phase-80-trois-formes`) ; décision déléguée par Samuel
  (message session principale, 2026-11-08), option recommandée : la 80 pose `vague` sur le plan (et `avancement`,
  `exigences` sur le nœud de phase) dans `vf-cockpit-planning.mjs` (`readPlanning`), projetés par
  `vf-cockpit-project.mjs` ; la 75 n'y ajoute que `files_modified` (champ facultatif de `cockpit-project@1`, A32), et
  son plan des collisions « prévues » lit `vague` sans la poser et dépend du plan de la 80 qui la pose. Les deux
  fichiers sont partagés avec la 79 et la 80.

- **P75-D-25 (critère d'arrêt de la réserve du pied).** Si la réserve du pied (P75-D-03) fait changer de palier de
  niveau de détail le zoom d'ouverture de la carte Code (seuils k = 0,65 et 0,42) à 1440 ou à 390 px, ou fait rougir une
  suite voisine sur un chiffre de hauteur, l'exécution s'arrête et remonte au manager, sans réécrire d'attendu. Décision
  déléguée par Samuel (message session principale, 2026-11-08), option recommandée (critique de la spec, G19).

- **P75-D-26 (étage design, quatrième tour ; issue : 81/100, acceptée).** La spec d'interface a eu trois tours de critique par des juges neufs
  (67, 62, 69 sur 100, seuil 70). Quatrième tour accordé par la session principale ; décision déléguée par Samuel (message
  session principale, 2026-11-08), option recommandée. C'est le dernier : sous 70 au juge neuf suivant, la spec part avec
  sa note et ses constats ouverts, repris un par un comme critères dans les plans concernés ; pas de cinquième tour sans
  Samuel. Le juge neuf ne voit que la spec sur disque.
- **P75-D-27 (pastille de compte du sélecteur).** Neutre en bureau comme dans le « ⋯ » : la pastille `--on` sur
  `--on-text` déjà livrée dans le « ⋯ » (fond neutre, non teinté, jamais `--recent`) ; précision du 2026-11-11 après la
  critique finale de la spec. Règle en vigueur : P71.5-D-19 et l'interdit « fond teinté pour un état » de `DESIGN.md` ; la
  pastille pleine `--recent` de l'actuel bouton « Travail récent » s'en écarte (question Q-75-5).

### Vérification attendue des plans

- **P75-D-21.** Chaque comportement porte un témoin qui rougit sur la base et verdit après ; les mutants des suites du
  cockpit couvrent les règles de seuil (paliers, couplage, collisions, plafond, fenêtre) et la normalisation des chemins
  (preuve générative sur les formes de chemin : lien symbolique, `..`, worktree hors du lab, Unicode, U+2028). Chaîne XSS
  étendue : chemin de fichier, nom de branche, rôle et titre d'agent hostiles dans les marques, l'infobulle et le
  panneau. Les sondes de `sondes/` mesurent, elles ne prouvent pas. Navigateur partagé entre missions : aucune recette
  dans la planification ; les juges à captures viennent à l'exécution.

### Claude's Discretion

Découpage en modules sous `plugin/cockpit/scripts/` (limite de taille du dépôt), nom exact de la route, glyphes précis des
paliers (fixés par la spécification d'interface et sa critique), format interne des caches.
</decisions>

<to_samuel>
## À Samuel (non bloquant — l'arbitrage en vigueur tient, le plan est bâti dessus)

- **Q-75-1 — Carte de chaleur.** Le but dit « la carte Code se colore par l'activité ». Le cadrage le lit « se marque » :
  glyphe à paliers neutre et mot, la teinte « en cours » réservée à l'écriture en direct (P75-D-01), parce que Q9 et
  `DESIGN.md` § 9 interdisent couleur d'alerte et fond teinté. Options : (a) garder cette lecture **(recommandé : porte le
  sens sans rouvrir Q9)** ; (b) ouvrir une vraie carte de chaleur (fond ou dégradé), ce qui rouvre Q9 et § 9.
- **Q-75-2 — Empreinte au-delà de 24 h (renvoie à S-1, posée par la Phase 79).** L'empreinte est gardée en mémoire sur
  24 h, jamais écrite dans l'index sur disque (AUDC-Q2 : heures, durées, jetons, verbes ; C1). Avis de la 75 sur S-1 :
  l'option (a) de la 79 suffit au direct et au radar ; seule une empreinte de mission ancienne justifierait (b). Options : (a) garder **(recommandé : suffit au direct et au radar, aucune
  donnée nouvelle sur disque)** ; (b) persister les cibles de fichiers dans l'index pour voir l'empreinte d'une mission
  ancienne, ce qui rouvre AUDC-Q2.
- **Q-75-4 — Worktrees hors du dossier du lab — TRANCHÉE** : arbitrage Samuel, AskUserQuestion session principale,
  2026-11-11, « Les compter comme le lab (Recommandé) » (P75-D-29).
- **Q-75-5 — Pastille de compte pleine.** Le bouton « Travail récent » livré porte en largeur de bureau une pastille de
  compte à fond plein `--recent`, alors que P71.5-D-19 et `DESIGN.md` (interdits : « un fond teinté pour un état »)
  demandent une pastille sans fond. La 75 bâtit son sélecteur sur la règle (P75-D-27). Options : (a) pastille neutre
  partout **(recommandé : la règle écrite, et le « ⋯ » la tient déjà)** ; (b) garder la pastille pleine en bureau comme
  exception écrite dans `DESIGN.md`.
- **Q-75-3 — Retrait du « Travail récent » — TRANCHÉE** : arbitrage Samuel, AskUserQuestion session principale,
  2026-11-11, « La remplacer (Recommandé) » (P75-D-28).
</to_samuel>

<phase79_contract>
## Contrats de la Phase 79 retenus (`feat/phase-79-socle-cockpit`, `3119d82a`, `79-CONTEXT.md` § « Contrats fournis »)

**Consommés :** C0 (contrôles d'accès des routes `/api/vf/*`, en-tête `x-vf-cockpit-token`, garde d'émission
`porteInterdit` sur `doing`, `mandat`, `messages`, `outils`, `fil` — le schéma `vibeflow/cockpit-activite@1` n'emploie
aucune de ces clés ; versions des schémas) ; C1 (aucune cible dans l'index sur disque) ; C2 (`GET /api/vf/state`,
`signal.arbres` et `signal.equipe` au format who@2 avec l'état officiel) ; C3 (`GET /api/vf/frise`, voies : `role`,
`arbre`, `parent`, `etatOfficiel`, `rattachement`, `cibles`) ; C4 (magasin `window.VF_ETAT`, clés `frise`, `git`,
`connexion` ; événement `git` `{seq, at, sig}` qui déclenche la relecture des données git de la 75) ; C5 (graphe Code
servi par `GET /api/vf/graphe?onglet=code`) ; C6 (appareil de patchs `plugin/cockpit/amont/` retiré en vague 1 de la 79,
aide commune de lancement des suites).

**Placement par rapport à C6 :** tout plan de la 75 qui touche un fichier du moteur ou écrit une suite s'exécute **après**
la vague 1 de la 79 : aucun diff de patch régénéré, `VENDORED.txt` réduit (origine, sentinelle, plafond), suites lancées par
l'aide commune. La 75 ne s'exécute de toute façon qu'après la 79 (dépendance de jalon).

**Manques relayés à la 79 le 2026-11-11 (session principale), tous fermés par le second amendement `6f66d878` :**
1. Signature des `cibles` → A21 (la signature `frise` couvre la projection entière, cibles comprises).
2. Cible relative à l'arbre → A22 (sous le lab ; hors du lab : CKPT-22 en vigueur, S-3).
3. Chemin réel → A23.
4. Outils de lecture → A24 (`Read` seul).
5. Export → A25, devenue règle de C0 ; `/api/vf/activite` suit la même règle, avec son témoin à marqueur unique et son
   témoin positif.
6. Route neuve → A10, A11, A26 (une ligne de la table, réponse gardée commune).
7. Graphe Code → A27 (`graph.json` sur disque, annotateur inscrit d'une ligne).
Facultatif retenu : A28, `GET /api/vf/frise?champs=cibles`.

**Amendements suivants de la 79 (tête `29fd3e71`), pris en compte par les plans :** A30 (`VF_COQUILLE.surOnglet`), A31 à
A33 (instantané en mémoire, champs du planning, lab en sous-dossier), A34 (table des routes et réponse gardée dans le
module neuf `vf-cockpit-routes.mjs`, annotateurs par ordre alphabétique de nom, points d'extension `attach(…, routes)` et
`assembler(…, annotateurs)`, compteur de suites au nombre rendu par le gate), A35 et A36 (instantané avec `at`, sans
voies brutes ; `rattachement` joint par la projection ; 2 000 voies au plus), A37 (une seule règle de chemin).
</phase79_contract>

<canonical_refs>
## Canonical References

- `.planning/workstreams/fiabilite/ROADMAP.md` § Phase 75, § Phase 79, § Phase 80
- `.planning/research/2026-11-10-audit-cockpit-etude.md` § 3, § 6, § 8.2 ; `.planning/research/2026-11-10-audit-cockpit/REGISTRE.md` (AUDC-I12, I13, I36, Q2, Q4, D5) ; `DESIGNS.md` § 9 ; `sondes/index-proto.mjs`
- `.planning/notes/2026-11-03-cockpit-idees-recherche.md` (idées 5 à 8) ; `docs/research/2026-11-01-etude-floorplan-cockpit.md`
- `.planning/missions/2026-11-11-audit-cockpit-lot-0.md` (AUDC-A-04)
- `DESIGN.md` § 2 et § 9 ; `71.5-CONTEXT.md`, `71.5-SPEC-couleurs.md`, `71.5-SPEC-code.md` ; `70-CONTEXT.md` (P70-D-01) ; `69-CONTEXT.md` ; `78-CONTEXT.md` ; `67-CONTEXT.md`
- `plugin/cockpit/scripts/vf-cockpit-build.mjs`, `vf-cockpit-git.mjs`, `vf-cockpit-git-durci.mjs`, `vf-cockpit-paths.mjs` (`envGit`, `lancerGitAsync`), `vf-cockpit-transcript.mjs`, `vf-cockpit-project.mjs`, `vf-cockpit-interface.json`, `vf-cockpit-server.mjs`
- `plugin/cockpit/skills/cockpit-moteur/assets/viewer.html`, `VENDORED.txt`, `scripts/recent.mjs` ; `plugin/cockpit/ui/25-recent.js`, `ui/70-vf-live.js`, `ui/78-vf-fr-dict-a.js`, `ui/79-vf-fr-dict-b.js`, `ui/80-vf-fr.js`
- `scripts/ci-suites-perimetre.sh`, `scripts/ci-shard-suites.sh`, `scripts/check-gate-touche.sh`, `.github/workflows/ci.yml`
</canonical_refs>

<deferred>
## Deferred Ideas

- Constats de l'auditeur posés sur les cartes (AUDC-I36, troisième idée) — réserve, P75-D-19.
- Points chauds pondérés en lignes changées (`--numstat`, quatre fois plus cher) — si un manque est mesuré.
- Cache disque des données git sous `.vibeflow/cockpit/` — si un gros dépôt dépasse l'échéance.
- Travail non commité par `git status` (révision de P78-D-23) — si les écritures par commande manquent trop au radar.
- Empreinte au-delà de 24 h — Q-75-2.
</deferred>
