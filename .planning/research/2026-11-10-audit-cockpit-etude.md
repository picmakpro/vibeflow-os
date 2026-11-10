# Audit du cockpit VibeFlow — étude du 2026-11-10

**Statut :** versée au planning le 2026-11-11 ; rien n'était corrigé à cette date. Elle cadre le lot 0 (mission de
corrections hors phase) et les Phases 73 à 77 et 79 à 81 du jalon `vibeflow-v2.0`. Le suivi ligne à ligne se tient
dans `2026-11-10-audit-cockpit/REGISTRE.md`.

**Demande** (Samuel, session principale Claude Code, 2026-11-10) : un audit complet du cockpit, « que ça soit du
design », « les idées d'amélioration, les nouvelles features, les choses qui pourraient être mieux faites », avec
deux exemples : « la gestion des agents en cours, le fait d'avoir un graphe qui permette de suivre les sessions ».
Puis, même canal, même date : « Je veux que tu verses l'audit dans le planning pour cadrer les prochaines phases,
mais aussi pour ne rien perdre des bonnes idées qu'il y a eu, des designs qui ont été imaginés et des patterns
reconnus. […] Et trace-le, faut que ça survive. Et que ça soit corrigé et qu'on applique les choses qui ont été vues. »

**Objet audité :** `plugin/cockpit` v1.4.0 et les retours du panel non publiés, branche `release/v2.77.0`.

**Où lire quoi**

| Besoin | Fichier |
|---|---|
| Suivre un constat ou une idée jusqu'à sa livraison | `2026-11-10-audit-cockpit/REGISTRE.md` |
| Citer une maquette ou une règle de forme | `2026-11-10-audit-cockpit/DESIGNS.md` |
| Voir les maquettes et les captures | `2026-11-10-audit-cockpit/page/audit-cockpit.html` (à ouvrir dans un navigateur) |
| Lancer les corrections | `2026-11-10-audit-cockpit/LOT-0-MANDAT.md` |
| Lire un rapport d'agent en entier | annexes `A1` à `A7` du même dossier |
| Rejouer une mesure | `2026-11-10-audit-cockpit/sondes/` |

La page a aussi été remise à Samuel le 2026-11-10 sous la forme d'un artifact privé.

Dans ce document, « Q1 » à « Q14 » sans préfixe désignent les réponses de Samuel du 2026-11-06 ; les décisions
ouvertes par l'audit s'écrivent `AUDC-Q1` à `AUDC-Q5`.

## 1. Verdict en quatre causes

Sept audits ont tourné en parallèle, puis ont été recoupés dans le code : l'antériorité, la chaîne de données des
agents, l'architecture, la sécurité, un parcours complet dans le navigateur, une veille de quinze outils, et la
surface officielle de Claude Code. Ils ramènent presque tout à quatre causes.

1. **L'état des agents est deviné.** Le cockpit déduit l'activité de la date de modification des transcripts, avec
   un seuil de 180 secondes (`plugin/cockpit/scripts/vf-cockpit-equipe.mjs:61,72-86`,
   `plugin/cockpit/scripts/vf-cockpit-who.mjs:82,89`). Un agent qui lance des tests pendant dix minutes disparaît ;
   une session au repos n'existe plus après trois minutes. Claude Code publie pourtant l'état de chaque session.
2. **Le temps n'est pas gardé.** Rien n'est conservé d'une minute à l'autre : ni durée fiable, ni frise, ni coût.
   Tout est déjà écrit dans les transcripts (l'heure de chaque ligne, la durée de chaque outil, les jetons, les
   compactions). Il manque un index.
3. **Une seule boucle fait tout.** Le serveur collecte en bloquant toutes les cinq secondes. La page sert de base de
   données. Trois onglets ouverts épuisent les connexions du navigateur et figent le cockpit sans un message.
4. **Une seule forme pour tout.** Le canevas à cartes sert bien la carte du code. Appliqué à la feuille de route et
   à l'équipe, il échoue : des titres de 7 px à l'ouverture de Projet, une carte seule sur un canevas vide dans
   Équipe, et aucune carte atteignable au clavier.

| Mesure | Valeur |
|---|---|
| Sous-agents du dépôt ayant connu un silence de plus de 180 s, donc une disparition de l'écran | 35 % (133 de plus de 10 min) |
| Mandats qui citent leur nœud de plan ; les autres s'affichent sans mission | 14 % (143 sur 1 005) |
| Temps pendant lequel le serveur ne répond pas, bloqué par sa propre collecte | 9 % |
| Durée d'un appel à `claude agents --json` sur le poste de l'audit (Claude Code 2.1.322) | 0,14 s |
| Constats de sécurité critiques ou hauts | 0 (seize sondes hostiles refusées) |

Pendant l'audit, sept agents travaillaient et l'onglet Équipe affichait une carte, sous le titre « Aucune mission en cours ».

## 2. Méthode et limites

| Audit | Matière | Annexe |
|---|---|---|
| Données des agents | 63 sessions et 1 005 transcripts de sous-agents du dépôt ; collecteur réel rejoué sur un dossier personnel factice, avec témoin positif | A1 |
| Architecture | lecture du code, mesures par requêtes de lecture, un Chrome sans tête propre à la mesure | A2 |
| Sécurité | lecture du code, seize sondes HTTP hostiles sur l'instance de recette, sondes de lecture sur des labs jetables | A3 |
| Interface | parcours Playwright à 1440, 1024 et 390 px, clair et sombre, clavier seul, terminal et lancement ouverts ; 85 captures | A4 |
| Veille | quinze outils de pilotage d'agents, documentations et journaux de versions officiels | A5 |
| Surface officielle | documentation de Claude Code : hooks, télémétrie, ligne d'état, transcripts, vue d'agents, ligne de commande | A6 |
| Antériorité | panel du 2026-11-06, recette du 2026-11-08, registres des Phases 67 à 78, BACKLOG, Phases 73 à 77 | A7 |

Après le retour des agents, la session principale a relu de première main, dans le code, les constats AUDC-D1 et D2
(seuil et exclusion), D5 (nommage des plans de mission), D7 (mandat), H1 (deux flux), H3 (arrêt sur inactivité, en
minutes), H4 (dictionnaire) et A-01 (reprise de session). Le versement lui-même a été relu par un agent neuf, qui a
comparé les fichiers versés aux rapports.

**Non vérifié :**
- Windows et Linux, Safari et Firefox, un lecteur d'écran, un second compte sur le poste.
- AUDC-A-01 et AUDC-A-03 de bout en bout : lus dans le code, non exécutés. Aucune question n'a été envoyée à « Demander ».
- En sécurité (A3 § 3) : tout ce qui exige un vrai `claude` (effet réel d'une reprise de session, confinement de la
  lecture par lien symbolique) ; l'exécution réelle de la politique de contenu dans un navigateur ; les 28 points
  d'insertion de HTML de `viewer.html`, lus par échantillon ; `driver-lock.sh` ; le coût de trois scripts du moteur
  sur des fichiers hostiles.
- Les `fichier:ligne` du registre viennent des rapports ; hors des huit constats relus, ils n'ont pas été recontrôlés.
- Les suites de tests n'ont pas été rejouées ; leurs chiffres sont comptés.
- Les coûts en jours (montée de version du moteur, très gros dépôts) sont des estimations.
- Le parcours a porté sur un seul lab, ce dépôt.
- Le compte « 127 propositions du panel livrées » date du 2026-11-08 ; des correctifs sont passés depuis, sans recomptage.
- Dans A6, quatre points de documentation ne sont pas confirmés (dits en tête de l'annexe).
- Seuls quelques registres de phase ont été relus contre le lot 0 (P72-D-20, P70-D-22, P68-D-03, les réponses du
  2026-11-06) : d'autres rencontres avec un arbitrage passé restent possibles, à contrôler ligne par ligne à la correction.

## 3. Ce qui tient, à ne pas casser

- **Le périmètre réseau** : écoute sur 127.0.0.1 seul, hôte exact, origine et jeton sur les routes, politique de
  contenu fermée, secret à usage unique pour le terminal (A3 § 1).
- **La direction Graphite**, surtout en sombre : le couple glyphe et mot pour les états est la signature la plus
  solide de l'interface (note 74).
- **Le lancement en deux temps** : la commande exacte est montrée, rien ne part sans la touche Entrée.
- **Le tiroir Git en lecture seule**, où chaque action est une commande à copier.
- **Le vendoring reproductible** du moteur, rejoué en CI ; les routes Git asynchrones ; le terminal isolé dans son
  processus ; les schémas versionnés ; aucune fuite après 120 rendus.
- **Des tests qui savent rougir** : des mutants dans 52 suites sur 68.

## 4. Constats

Soixante constats, tous au registre avec preuve, correction, effort et destination.

| Domaine | Nombre | Les plus lourds |
|---|---|---|
| Données des agents | 9 | AUDC-D1 un agent qui travaille disparaît ; D2 une session au repos disparaît ; D4 orphelins rangés dans « Terminés » ; D5 lien agent et mission à 14 % |
| Architecture | 13 | AUDC-H1 trois onglets figent le cockpit ; H2 serveur sourd 9 % du temps ; H3 arrêt et remplacement sans trace ; H4 la traduction réécrit des noms de fichiers ; H5 couplage au moteur vendorisé |
| Sécurité | 9 | AUDC-A-01 « Demander » reprend toute session ; A-02 liens symboliques suivis ; A-03 dossier de sortie exécuté |
| Interface | 29 | AUDC-BL1 Projet illisible à l'ouverture ; BL2 canevas hors clavier ; M3 Équipe dit l'inverse de ce qu'elle montre ; M9 et M10 états muets |

Les dix à traiter d'abord, dans l'ordre : AUDC-D1, H1, D2 avec M3, D4, BL1, BL2, H2, H4, A-01, M9 avec M10.

## 5. Les formes proposées

Détail dans `DESIGNS.md`, maquettes dans `page/audit-cockpit.html`.

- **Trois onglets, trois formes** : Code reste une carte ; Projet devient des couloirs par état ; Équipe devient une
  régie et une frise.
- **La régie** (maquette 1) : « À vous » classée par ce que chaque attente retient dans le plan, puis l'arbre « Au
  travail », « Terminé, à relire », « Au repos ».
- **La frise des sessions** (maquette 2) : une voie par agent, une horloge commune, les attentes hachurées, les
  commits posés dessus, deux lectures (horloge, événements).
- **La fiche d'un agent** (maquette 3) : six faits, un fil daté, des actions par le double geste.
- **Projet en couloirs** (maquette 4) : les phases rangées par état, lisibles à toute largeur.

## 6. Motifs reconnus chez les autres

Veille de quinze outils (A5) : la vue d'agents et les Projects de Claude Code, Conductor, Cursor 3, Codex, GitHub
Agent HQ, Warp, Factory, Devin, Amp, Antigravity, Nimbalyst et Vibe Kanban, Langfuse, Braintrust, et trois projets
ouverts (zoetrope, agents-observe, le dépôt de disler). Tous convergent vers une liste d'agents groupée par état.

**Huit motifs, classés par la ressource rare (l'attention humaine d'abord), et ce qu'on en fait :**

| # | Motif | Vu chez | Ce qu'on en fait |
|---|---|---|---|
| 1 | Liste groupée par état, « ce qui m'attend » en tête, une phrase par agent | Claude Code, Conductor, Warp | Pris : la régie (AUDC-I01) |
| 2 | Aperçu et réponse sur place, sans ouvrir la session | Claude Code, GitHub | Écarté pour l'instant (AUDC-N1) : contraire au double geste |
| 3 | Revue de diff par agent, portée « dernier tour », badge dérivé de git | Codex, Claude Code, Conductor | En réserve (AUDC-I16) : rouvre « détail sans diff » ; badge réseau écarté (AUDC-N2) |
| 4 | Bouton de l'étape suivante sur la carte | Claude Code Projects | Pris, par le double geste (AUDC-I34) |
| 5 | Preuves de vérification préparées | Antigravity, Cursor, Factory | Pris pour la Phase 76 (AUDC-I33) |
| 6 | Hiérarchie compacte parent et enfants, jamais un grand graphe par défaut | Warp, Factory, Devin | Pris : l'arbre indenté de la régie |
| 7 | Une trace, plusieurs dispositions, relecture | Braintrust, Langfuse, zoetrope | Pris : régie, frise et fil sur les mêmes données (AUDC-I05, I06) |
| 8 | Coût visible et plafonné par agent | Devin, Factory, Conductor | Pris pour le coût (AUDC-I07, I08) ; plafond en réserve (AUDC-I35) |

Quatre motifs moins répandus sont relevés sans être instruits : la saisie de tâches en rafale, la comparaison de
plusieurs essais d'une même tâche, la bifurcation et la reprise, les routines planifiées (AUDC-I40).

**Cinq endroits où le cockpit peut être seul** (A5 § 2 : aucun des quinze outils ne le fait, et le cockpit a déjà la
matière ; deux petits projets s'en approchent, l'un pour les couloirs par session, l'autre pour les collisions) :

1. Une file d'attente classée par impact dans le plan (AUDC-I02).
2. Une frise du dépôt à horloge commune, avec commits, fusions et réponses humaines (AUDC-I05).
3. Un radar de collisions entre agents et entre worktrees (AUDC-I12). L'assemblage de la v2.76.0 avait révélé trois
   rencontres invisibles tant que chaque branche était verte seule.
4. La vivacité plutôt que le statut (AUDC-I03).
5. Le coût par phase et par étage (AUDC-I08).

S'y ajoute un principe : relier trois graphes que le cockpit a déjà, séparés (qui a lancé qui, quel nœud du plan,
quelle phase) (AUDC-I21).

**Sept pièges observés, à garder en tête au cadrage** (A5 § 3) :

| Piège | Parade |
|---|---|
| Graphes illisibles au-delà de quelques dizaines de nœuds (estimation de la veille, aucune source ne chiffre le seuil) | Agréger, figer la disposition, se limiter au voisinage |
| Frise en temps réel : une minute dense devient un trait, une nuit un désert | Deux lectures : horloge et événements |
| Bruit des notifications | Trois motifs seulement : besoin d'une réponse, fin, échec |
| Statut menteur : un travail mort reste « en cours » | Dériver l'état de preuves : commit, battement, résultat d'outil |
| Tout afficher | Une ligne par agent, le détail à la demande |
| Goulot de revue : une équipe dit tenir cinq à sept agents, qui attendent la revue plus qu'ils ne travaillent | Mesurer le temps perdu à attendre l'humain |
| Ressources : dix sessions consomment le quota environ dix fois plus vite | Afficher les limites de 5 h et de 7 jours |

## 7. D'où viennent les données

Aucune de ces sources ne demande de lecture réseau. Détail et stabilité : A6 ; champs disponibles et mesurés : A1 § 3.

| Besoin | Aujourd'hui | Source proposée | Stabilité |
|---|---|---|---|
| Qui est vivant, occupé, au repos | date de modification du transcript, seuil de 180 s | `claude agents --json` (états `working`, `blocked`, `done`, `failed`, `stopped` ; `status` `busy`, `waiting`, `idle` ; `waitingFor`) | documentée, en aperçu de recherche |
| Qui attend une permission ou une réponse | rien | hooks `PermissionRequest` et `Notification` ; en repli, une question sans résultat dans le transcript | documentée ; le repli est une déduction |
| Début et fin des sous-agents | balayage de 1 587 fichiers `meta.json` à chaque tour | hooks `SubagentStart` et `SubagentStop` ; le second donne le chemin du transcript | documentée |
| Durées, outils, erreurs, compactions, fichiers | non lus | transcripts, par un index incrémental (décalage d'octets par fichier) | format interne : derrière le contrat de forme existant (`plugin/cockpit/scripts/vf-cockpit-interface.json`) |
| Contexte, coût, limites de 5 h et de 7 jours | `vf-signal` seulement, session courante | le JSON passé au script de ligne d'état, relayé par ce script ; en repli, le champ `usage` des transcripts, dédoublonné par message | documentée ; repli interne ; limites publiées pour les abonnements Pro, Max et Ultra seulement |
| Agir sur une session | rien | `claude attach`, `claude --resume <id> "message"`, `claude stop`, `--fork-session` | documentée |

Trois réserves. Les fichiers internes de Claude Code donnent les mêmes états (`~/.claude/sessions`), mais leur format
n'est pas garanti et la documentation déconseille de lire le registre du démon : la commande est la voie stable
(AUDC-V10). Le format des transcripts change entre versions : tout champ lu passe par le contrat de forme. Et la
télémétrie OpenTelemetry, qui porte l'agent et son parent sur ses événements, n'est pas retenue : aucun exporteur
vers un fichier n'est documenté (AUDC-I39).

Conseil d'architecture de A6 : combiner les hooks de type `http` (événements en temps réel vers le serveur local),
`claude agents --json` (état d'ensemble) et la ligne d'état (coût, limites) ; garder les transcripts en secours.

## 8. Trajectoire

Ordre recommandé (AUDC-V5) : le lot 0 ; puis les Phases 79 et 80 en parallèle ; la 73 dès le lot 0 livré ; la 74
après la 79 ; puis 75, 76, 77 ; la 81 seulement si Samuel le décide (AUDC-Q3). Contraintes communes du jalon,
inchangées : traces locales, aucune lecture réseau, lecture seule, un ajout = un retrait.

### 8.1 Lot 0 — « dire vrai » (mission hors phase)

Vingt-huit constats, presque tous de la taille d'un commit, qui font dire vrai à l'écran actuel. C'est plus large
que le lot 0 de la page de l'audit, qui en comptait treize (AUDC-V9). Mandat : `LOT-0-MANDAT.md`. En bref : l'état
des sessions et des agents (AUDC-D1 à D8, M3), le serveur (H1, H2, H3, H4, AM7, M9), la sécurité (A-01, A-02, B-01 à
B-04, B-06), les états muets et l'accessibilité immédiate (M7, M10, M11, X4, X6, X7).

### 8.2 Entrée de cadrage par phase

Chaque bloc dit ce que l'audit apporte au cadrage de la phase : ce qu'elle absorbe du registre, la forme proposée,
les sources, les bornes, le retrait, et ce qui reste à décider. Le cadrage reste à faire, phase par phase.

**Phase 79 — Socle du cockpit : une collecte, un flux, une route d'état** (nouvelle)
- Absorbe : AUDC-D5 (registre, mandat), D9, H1 (flux partagé), H2 (asynchrone), H4 (traduction au point d'émission),
  H5 après AUDC-Q5, AM1 à AM7, AB1, A-03, M7 (worker) ; idées AUDC-I18 à I20, I22, I31, I32, I37.
- Première vague : AUDC-A-03 et AM4 (le serveur lancé depuis le module), parce que c'est le constat de sécurité.
- Forme : une collecte asynchrone hors de la boucle ; un curseur par transcript qui alimente un index incrémental ;
  une route `GET /api/vf/state` aux schémas existants, lue par la page et par `vf-signal` ; une route de frise ; une
  coquille statique et des données en JSON ; le serveur lancé depuis le module.
- Mesures de référence à tenir : passage complet sur 2,6 Go en 9,4 s (à sortir de la boucle, puis lecture des seuls
  octets ajoutés) ; index de 147 Ko pour 1 068 transcripts.
- Bornes : dernière commande jamais dans le flux, un fichier ou l'export (P67-D-14) ; messages et actions sans sortie
  d'outil, jamais exportés (P69-D-19, P69-D-23) ; clés `doing`, `mandat`, `messages`, `outils` refusées à l'émission.
- Retraits : la page Équipe reconstruite à chaque requête ; la collecte refaite par `vf-signal` ; la copie renommée
  de 52 modules.
- À décider au cadrage : AUDC-Q2 (index sur disque), AUDC-Q5 (fork ou amont). Touche aussi `plugin/conductor`
  (registre du verrou, doctrine du team-kernel) et les managers de `plugin/dev-orchestrator` et
  `plugin/design-orchestrator` (nœud écrit dans le mandat).

**Phase 80 — Trois onglets, trois formes : Projet en couloirs, clavier, navigation** (nouvelle)
- Absorbe : AUDC-BL1, BL2, M1, M2, M5, M6, M8, M10 (pastille), M12, X1 à X3, X5, X7 (onglets), X8, F1, F3 à F5, F7 ;
  idées AUDC-I23 à I27, I29, I30.
- Forme : DESIGNS § 6 (couloirs) et § 7 ; le canevas reçoit rôle, nom, tabulation itinérante et flèches.
- Première vague conseillée : BL2 et M6 (clavier), puis les couloirs.
- Bornes : points de rupture inchangés (Q11) ; le tiroir ne pousse jamais la carte (Q12) ; grille d'espacements
  fermée (P71.5-D-01) ; ni fond teinté ni couleur d'alerte (Q9).
- Retraits : le canevas comme vue par défaut de Projet ; les vignettes Backlog et Releases.
- À décider au cadrage : Q10 (AUDC-M2), P70-D-04 (AUDC-M8), P70-D-22 et « Garder ce compromis » (AUDC-M5), P71-D-02
  (pastille de AUDC-M10) ; PU-G-026 seulement si les couloirs sont refusés. Les onglets sans rechargement (AUDC-I30)
  attendent le socle.

**Phase 73 — Gouvernance au cockpit** (inscrite le 2026-11-03, but inchangé)
- L'audit y apporte : la régie (AUDC-I01, DESIGNS § 3) comme forme de l'onglet Équipe, dont la section « À vous »
  réalise l'idée 9 (ce qui attend une décision humaine) classée par impact (AUDC-I02) ; la vivacité (AUDC-I03) ;
  l'état « attend ses agents » (AUDC-I38) ; l'orphelin en ligne de régie (AUDC-D4) ; les notifications (AUDC-I09) ;
  « ailleurs sur ce poste » (AUDC-I10) ; le bouton de l'étape suivante (AUDC-I34) ; les trois graphes reliés
  (AUDC-I21) ; AUDC-M3, F2. « Répondre » et l'arrêt d'un orphelin attendent AUDC-Q3.
- Sources : état lu des sessions (lot 0), plan de mission déjà lu pour compter les nœuds en aval, registre du verrou.
- Ne dépend pas de la Phase 79 : la régie se construit sur le flux actuel, enrichi par le lot 0.
- Retraits : le canevas de l'onglet Équipe ; le nom écrit trois fois ; la carte « Terminés depuis moins de 24 h ».
- À décider au cadrage : AUDC-Q4. Recoupement déjà noté au ROADMAP avec la Phase 78 (état des worktrees).

**Phase 74 — L'équipe dans le temps** (inscrite le 2026-11-03, but inchangé)
- L'audit y apporte : la frise (AUDC-I05, DESIGNS § 4), la fiche d'agent et le lecteur (AUDC-I04, I28, M4, D8), les
  durées par segments (AUDC-D9), le coût et les limites (AUDC-I07, I08), la relecture liée à la carte Code
  (AUDC-I06), les trois graphes reliés (AUDC-I21).
- Trois corrections à la note d'origine : les horodatages sont dans les transcripts, pas dans `meta.json` ; « colorée
  par nœud de DAG » contredit DESIGN § 9, le nœud s'écrit sur la voie ; une frise au-delà de 24 h rouvre P69-D-18.
- Dépend de la Phase 79 (index, route de frise). Lire le champ `usage` demande d'étendre le contrat de forme.
- Hérite de AUDC-Q2 (tranchée au cadrage de la 79) pour les fenêtres au-delà de 24 h, et de AUDC-Q4 (tranchée au
  cadrage de la 73). Recoupement : Phase 52 (télémétrie et coût de mission), un seul calcul à partager.

**Phase 75 — L'activité posée sur le code** (inscrite le 2026-11-03, but inchangé)
- L'audit y apporte : le radar de collisions (AUDC-I12), l'empreinte en direct (AUDC-I13), les trois idées de
  l'étude floorplan jamais livrées (AUDC-I36).
- Sources : cibles des outils d'écriture dans l'index, fichiers modifiés de chaque arbre, `files_modified` des plans.
- Dépend de la Phase 79 (index).

**Phase 76 — Traçabilité au cockpit** (inscrite le 2026-11-03, but inchangé)
- L'audit y apporte : les preuves de vérification attachées à la phase ou au nœud (AUDC-I33).

**Phase 77 — Santé de la méthode et synthèse** (inscrite le 2026-11-03, but inchangé)
- L'audit y apporte : « depuis votre dernière visite » à avancer dans l'ordre (AUDC-I14) ; le coût par phase et par
  étage dans la synthèse (AUDC-I08). Dépend de la Phase 79 pour le coût.

**Phase 81 — Agir sur une session depuis le cockpit** (nouvelle, suspendue à AUDC-Q3)
- Absorbe : AUDC-I11 ; voisine du sujet BACKLOG « plusieurs terminaux ».
- Forme : chaque action prépare une commande dans le terminal (`claude attach`, `--resume`, `stop`,
  `--fork-session`) ; la touche Entrée l'exécute (DESIGNS § 5).
- Demande un audit de sécurité, comme la Phase 71. Elle rouvre Q8 (pas de terminal sur l'onglet Équipe), P68-D-03
  (gestes réservés aux agents de la session courante) et la frontière de la Phase 72 (« Reprendre » sur les cartes
  Équipe) : elle ne démarre pas sans la décision de Samuel.

### 8.3 En réserve

Sans phase, gardées au registre : le résumé d'une session à la demande (AUDC-I15), la revue par agent (I16), la vue
de plusieurs labs (I17), le plafond de coût (I35), la télémétrie OpenTelemetry (I39), les motifs moins répandus
(I40), et les deux pistes écartées (N1, N2).

## 9. Un ajout, un retrait

L'audit a identifié sept retraits (registre § 3) : le canevas de l'onglet Équipe ; le nom de chaque agent écrit
trois fois ; la carte « Terminés depuis moins de 24 h » ; la page Équipe reconstruite à chaque requête ; la collecte
refaite par `vf-signal` ; le second flux d'événements ; la copie renommée de 52 modules. Le versement en ajoute deux
pour la Phase 80 : le canevas comme vue par défaut de Projet, et les vignettes Backlog et Releases.

## 10. Décisions

Cinq décisions de fond reviennent à Samuel (registre § 5.1) : AUDC-Q1 le mode de lancement « hérité du poste », qui
peut valoir le mode sans permissions ; AUDC-Q2 l'index sur disque ; AUDC-Q3 des actions depuis l'onglet Équipe ;
AUDC-Q4 la vue d'agents de Claude Code comme source de référence ; AUDC-Q5 suivre l'amont du moteur ou assumer le
fork. Aucune ne bloque le lot 0 ni la Phase 80. AUDC-Q2 et AUDC-Q5 se tranchent au cadrage de la Phase 79, AUDC-Q4 à
celui de la 73, AUDC-Q3 conditionne la 81 ; AUDC-Q1 porte sur un comportement déjà livré.

Huit réouvertures d'arbitrages passés se tranchent au cadrage de la phase qui porte la ligne (registre § 5.1) ; l'une
a sorti une ligne du lot 0 (AUDC-B-05, à trancher avec AUDC-Q1). AUDC-F6 en est sortie aussi, sans être une
réouverture : c'est un point de goût déjà consigné au BACKLOG.

Douze choix ont été pris au versement, par l'option recommandée (registre § 5.2). Le plus engageant est AUDC-V11 : la
phrase « Et que ça soit corrigé » est lue comme la validation des corrections du lot 0 ; Samuel a confirmé cette
intention le 2026-11-11.

## 11. Annexes

| Fichier | Contenu |
|---|---|
| `REGISTRE.md` | constats, idées, retraits, sujets du BACKLOG recoupés, décisions |
| `DESIGNS.md` | les formes proposées, le vocabulaire des états, la critique de la direction artistique, les bornes |
| `LOT-0-MANDAT.md` | le mandat de la mission de corrections |
| `A1-donnees-agents-sessions.md` | modèle de données actuel, neuf défauts, données disponibles non exploitées |
| `A2-architecture-performance.md` | schéma, treize constats, cinq chantiers |
| `A3-securite.md` | dispositif en place, sondes, neuf constats, risques déjà acceptés |
| `A4-interface-parcours.md` | notes par zone, constats, direction artistique, dix idées, liste des captures |
| `A5-veille-pilotage-agents.md` | quinze références, huit motifs, angles libres, pièges |
| `A6-surface-claude-code.md` | hooks, télémétrie, ligne d'état, transcripts, vue d'agents, ligne de commande, mods |
| `A7-anteriorite.md` | ce qui existe, ce qui est proposé, ce qui est tranché, Phases 73 à 77, juges |
| `page/` | la page de l'audit et six captures, identifiants masqués |
| `sondes/` | six scripts de mesure rejouables |
