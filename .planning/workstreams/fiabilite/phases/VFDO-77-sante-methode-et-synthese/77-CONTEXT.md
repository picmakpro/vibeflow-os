# Phase 77: Santé de la méthode et synthèse — jauges, dernière visite, burn-up - Context

**Gathered:** 2026-11-11
**Status:** Cadrée (2026-11-11). Frontière de questions vide ; deux questions non bloquantes à Samuel (section « À Samuel »).

Cadrage par le manager de la mission Phase 77 (`vf-dev-manager`, worktree `.claude/worktrees/phase-77`, branche
`feat/phase-77-sante-synthese`, base `origin/integration/cockpit-audit` `f763b556`). Jalon `vibeflow-v2.0`,
compartiment `fiabilite`. Cadrée en parallèle des Phases 73, 74, 75, 76, 79 et 80, sur demande de Samuel (session
principale Claude Code, 2026-11-11 : cadrer et planifier en parallèle toutes les phases de l'audit du cockpit).

Sources : bloc `### Phase 77:` du ROADMAP (but arbitré le 2026-11-03) ; `.planning/notes/2026-11-03-cockpit-idees-recherche.md`
(idées 12, 15, 16, complément du 2026-11-11) ; `.planning/research/2026-11-10-audit-cockpit-etude.md` § 8.2 ;
`.planning/research/2026-11-10-audit-cockpit/REGISTRE.md` (AUDC-I08, AUDC-I14, § 3, § 5) et `DESIGNS.md` § 1, § 7 à § 9 ;
rapport du lot 0 `.planning/missions/2026-11-11-audit-cockpit-lot-0.md` ; contrats de la Phase 79, figés au commit
`3119d82a` de la branche `feat/phase-79-socle-cockpit`, fichier
`.planning/workstreams/fiabilite/phases/VFDO-79-socle-du-cockpit-une-collecte-un-flux-une-route-d-tat/79-CONTEXT.md`,
section « Contrats fournis » (C0 à C6).

Faits établis avant le cadrage par deux éclaireurs en lecture seule (sur `f763b556`) et trois panels de recherche.
Les décisions ci-dessous s'appuient sur ces mesures ; aucune n'est un arbitrage de Samuel.

**Exigences :** SYNT-01 à SYNT-10. Préfixe neuf `SYNT`, vérifié libre le 2026-11-11 sur `f763b556` (aucune occurrence
de `SYNT` dans `.planning/`, ledgers de compartiment et archives compris).

<domain>
## Phase Boundary

Sur l'onglet Projet, un bouton « Synthèse » ouvre dans le panneau existant trois blocs, dans cet ordre :
1. **Depuis votre dernière visite** : phases avancées, commits arrivés, sessions finies, blocages nouveaux ou levés.
2. **Burn-up du jalon** : les phases closes dans le temps contre le périmètre du jalon, en pourcentage strict.
3. **Santé de la méthode** : des jauges sur les budgets que mesurent déjà les gates (STATE, ROADMAP, BACKLOG, index
   MEMORY, worktrees, densité des agents, skills, socle de démarrage, avec la ligne de baseline).

Un quatrième bloc, le **coût par phase et par étage** sur les dernières 24 h, attend la route de frise de la Phase 79
(AUDC-I08). Il est isolé dans un plan à part, à revalider quand la 79 aura livré.

**Retrait (un ajout, un retrait) :** la prose recopiée du STATE sous « Maintenant » (champ `lastDesc`), remplacée par
la synthèse datée (P77-D-12).

**Hors périmètre :**
- La Santé du code (onglet Code, `ui/20-health.js`, constats en anglais) : AUDC-M8, Phase 80. La 77 n'y touche pas.
- Le regroupement de l'en-tête (AUDC-M5, Phase 80).
- La régie et la section « À vous » de l'onglet Équipe (Phase 73).
- La frise et la fiche d'agent (Phase 74).
- Le coût en monnaie et les limites de 5 h et de 7 jours (ligne d'état, Phase 74).
- Toute fenêtre de sessions au-delà de 24 h (AUDC-Q2).
- La synthèse sur les onglets Code et Équipe.
- Un quatrième onglet (P78-D-04).
</domain>

<decisions>
## Implementation Decisions

Toutes les décisions de cette section sont des **décisions déléguées par Samuel (message session principale,
2026-11-08), option recommandée**. Elles sont prises par le manager sur la base des mesures des éclaireurs et des
panels. Aucune ne vaut arbitrage de Samuel, et aucune ne rouvre un arbitrage déjà rendu.

### Placement

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

### Jauges de la santé de la méthode

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

### Depuis votre dernière visite

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

### Burn-up du jalon

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

### Coût par phase et par étage (dépend de la Phase 79)

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

### Séquencement et fichiers partagés

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

- **P77-D-19 (installation par onglet).** Le bouton « Synthèse », la ligne-résumé, les jauges, la dernière visite et
  le burn-up s'installent par `VF_COQUILLE.surOnglet(rappel)` quand l'onglet vaut `projet`, et se retirent quand on le
  quitte. Le nettoyage rendu par le rappel retire écouteurs, minuteries et DOM posé. C'est la règle commune A30 de la
  Phase 79 (commit `74501bb0`, C5). L'objet global du moteur est gelé : rien ne s'y ajoute. Une surcouche, s'il en faut
  une, passe par `window.VF_SURCOUCHES` (Phase 80, P80-D-33 à P80-D-41). Témoin : quitter puis revenir sur l'onglet ne
  double ni le bouton ni les écouteurs.

- **P77-D-20 (accès aux données côté serveur, A31 et A32 de la Phase 79, commit `e04c43e7`).**
  - Burn-up et blocages du STATE : deux **champs facultatifs de `cockpit-project@1`**, ajoutés dans la lecture du
    planning de la collecte (A32), `burnup` (P77-D-13) et `blocagesState` (P77-D-10). Jamais une lecture propre à une
    route. La page les lit dans les données de Projet ; un serveur les lit par `instantane().projet` (plan 79-09).
  - Coût par phase et par étage : calculé **côté page** par un module pur, à partir de la frise
    (`VF_ETAT.lire('frise')` ou `GET /api/vf/frise`) et des missions de l'instantané d'état (jointure A8). Aucune route
    neuve. Dépend du plan 79-13, qui livre `frise`.
  - Jauges : la seule lecture propre à la phase, hors de la collecte, bornée ainsi :
    - aucun sous-processus au chargement d'une page ni à la collecte ; seulement à l'ouverture de la synthèse ;
    - au plus un lancement des deux gates en cours, que partagent les requêtes simultanées ;
    - résultat en cache 60 s ; une requête dans cette fenêtre ne lance rien ;
    - échéance de 10 s par gate, au-delà « indisponible » ;
    - lancement asynchrone, le serveur continue de répondre pendant ce temps.
    La réponse passe par la réponse gardée commune (A11). Cette décision fixe la durée du cache, laissée à discrétion
    plus bas.

### Décisions du manager après la recherche (2026-11-11, questions ouvertes de `77-RESEARCH.md`)

Mêmes régime et mention que plus haut : décisions déléguées par Samuel (message session principale, 2026-11-08),
option recommandée.

- **P77-D-21 (sommet de base, OQ-1).** `/api/vf/git` ne sert pas aujourd'hui le sha du sommet de la branche de base,
  que P77-D-08 met en mémoire. Il est ajouté en champ facultatif `base.h` (sha de 40 caractères) de `cockpit-git@1`.
  C'est un ajout facultatif, sans changement de version (règle C0 de la 79), dans le plan qui en a besoin.
- **P77-D-22 (sens de « commits arrivés », OQ-2).** Les commits arrivés sont les ancêtres du sommet courant de la
  branche de base, moins les ancêtres de `tete`, soit l'équivalent de `tete..sommet`. Les branches longues non
  fusionnées ne sont donc pas comptées à chaque visite. Ce sens précise P77-D-10 sans le changer : on ne filtre
  toujours pas sur la date, et la synthèse dit « plus de 500 » hors fenêtre.
- **P77-D-23 (mesures qui ne parlent qu'au dépassement, OQ-3).** « Paragraphe de STATE » et « lignes par entrée de
  BACKLOG » ne produisent une valeur qu'en cas de dépassement. En `--format=tsv`, le gate émet pour chacune la valeur
  la plus haute observée, calculée par le gate lui-même dans la boucle qui mesure déjà : ce n'est pas un recalcul côté
  cockpit. La sortie texte reste inchangée.
- **P77-D-24 (écarts constatés par la recherche).**
  - `vf-cockpit-paths.mjs` est à 296 lignes sur 300 (plafond du test de vendor). Le code neuf va dans des modules
    neufs ; ce fichier ne reçoit que l'`export` du lanceur asynchrone et le paramètre de nom de `driverLockScript`.
  - L'assertion R3.25 de `test-cockpit-projet-visite.sh` lit la prose `lastDesc`. Elle est réécrite dans le plan du
    retrait (P77-D-12), pour asserter l'absence du texte.

### Claude's Discretion

- Le numéro et le nom du fichier `ui/` neuf : un numéro libre au moment de l'exécution, à vérifier contre les fichiers
  posés par les autres phases.
- La forme exacte du TSV, sous réserve de P77-D-03 : en-tête versionné, chemins relatifs, un verdict par ligne.
- Le libellé exact du bouton et de la ligne-résumé, fixé par `77-UI-SPEC.md` dans les bornes de P77-D-02.
</decisions>

## À Samuel

Questions qui ne bloquent rien : l'arbitrage en vigueur tient et le plan est bâti dessus.

- **A77-1 — Coût par phase au-delà de 24 h (reprend S-2 de la Phase 79).** En vigueur : AUDC-Q2, la fenêtre de 24 h,
  donc le coût « des dernières 24 h » par phase et par étage. Avis du cadrage : sur 24 h, le bloc répond à « qu'est-ce
  qui consomme en ce moment ? », mais pas à « combien a coûté la Phase N ? ». Une phase du jalon a duré plusieurs jours
  (les clôtures datées du jalon s'étalent du 11-03 au 11-06, les inscriptions du 11-01 au 11-11). Options :
  - (a) garder 24 h ;
  - (b) un agrégat persisté par phase, étage et modèle (jetons et durées seulement, sans heure par agent), au-delà de
    24 h.
  **Recommandation :** (a) pour cette vague, avec le titre « dernières 24 h » ; (b) à instruire si la question « combien
  a coûté la phase » se pose réellement. (b) rouvre AUDC-Q2 : décision de Samuel seulement.
- **A77-2 — Le retrait de la prose « Maintenant » (P77-D-12).** Ce n'est pas une réouverture : aucune décision écrite
  ne porte sur ce texte. Il change pourtant ce que Samuel lit à l'ouverture de Projet. Recommandation : le retirer ; le
  repli est le trio de compteurs. Signalé pour la recette, pas à trancher avant.

<canonical_refs>
## Canonical References

- `.planning/workstreams/fiabilite/ROADMAP.md` § `### Phase 77:` ; `.planning/notes/2026-11-03-cockpit-idees-recherche.md`
  (idées 12, 15, 16).
- `.planning/research/2026-11-10-audit-cockpit-etude.md` § 3, § 7, § 8.2 ; `REGISTRE.md` AUDC-I08, AUDC-I14, § 3, § 5 ;
  `DESIGNS.md` § 1, § 8, § 9 ; `DESIGN.md` (direction « Graphite »).
- Phase 69 : `69-CONTEXT.md` (P69-D-05, P69-D-06, P69-D-08, P69-D-09) ; CKPT-16.
- Phase 79 : `79-CONTEXT.md` au commit `3119d82a` de `feat/phase-79-socle-cockpit`, contrats C0, C2, C3, C4, C6, question S-2.
- Code : `plugin/conductor/scripts/check-method-budget.sh`, `check-instruction-budget.sh` ;
  `plugin/cockpit/scripts/vf-cockpit-paths.mjs` (`driverLockScript`, `shBorne`), `vf-cockpit-project.mjs` (`piedJalon`,
  `pct`, `meta.vf`), `vf-cockpit-planning.mjs` (`ph.line`, `STATUS_SUFFIX`), `vf-cockpit-server.mjs`,
  `vf-cockpit-interface.json` ; `skills/cockpit-moteur/assets/ui/20-health.js` (patron du bouton, à ne pas modifier),
  `ui/75-vf-modele.js` (clé par lab).
</canonical_refs>

<deferred>
## Deferred Ideas

- La synthèse sur les onglets Code et Équipe.
- Un repère de visite commun à plusieurs navigateurs du poste : il passerait par un POST sans corps et un fichier dans
  `.vibeflow/cockpit/.cache/`, et demanderait un audit de sécurité.
- Le retrait de « Travail récent » (`ui/25-recent.js`, onglet Code) : seulement si la synthèse va un jour sur Code.
- Une sortie machine pour les linters `check-agents.sh` et `check-skills.sh` : ils ne comptent aucune ligne, la densité
  vit dans `check-instruction-budget.sh`.
- Un script de densité en lignes pour un lab tiers (agents de `.claude/agents`) : aujourd'hui, seul l'audit du
  validator la tient.
</deferred>
