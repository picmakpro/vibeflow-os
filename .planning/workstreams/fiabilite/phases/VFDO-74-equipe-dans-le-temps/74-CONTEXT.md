# Phase 74: L'équipe dans le temps — swim-lanes, coût, replay - Context

**Gathered:** 2026-11-11
**Status:** Cadrée (2026-11-11) — frontière de questions vide ; alignée sur les contrats figés de la Phase 79 (branche
`feat/phase-79-socle-cockpit`, commit `3119d82a`, `79-CONTEXT.md` § « Contrats fournis », C0 à C6 ; amendement du
2026-11-11 au commit `2ae6607a`, A1 à A14)

Cadrage par le manager de la mission Phase 74 (`vf-dev-manager`, worktree `.claude/worktrees/phase-74`, branche
`feat/phase-74-equipe-dans-le-temps`, base `origin/integration/cockpit-audit` = `f763b556`). Jalon `vibeflow-v2.0`,
compartiment `fiabilite`. Cadrée en même temps que les Phases 73, 75, 76, 77, 79 et 80, dans la vague lancée par Samuel le
2026-11-11 (session principale Claude Code : « lancer en parallèle les cadrages et plans de toutes les phases »).

**Sources :** but arbitré le 2026-11-03 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03 ; bloc Phase 74 du ROADMAP) ; note `.planning/notes/2026-11-03-cockpit-idees-recherche.md`
(idées 1, 2, 3 et complément du 2026-11-11) ; étude `.planning/research/2026-11-10-audit-cockpit-etude.md` (§ 3, § 6, § 7,
§ 8.2) ; `REGISTRE.md` (AUDC-I04, I05, I06, I07, I08, I21, I28, M4, D8, D9 ; § 3 ; § 5) ; `DESIGNS.md` (§ 2, § 4, § 5, § 9) ;
annexes A1 (§ 3, § 4), A5 (§ 3), A6 (ligne d'état, transcripts) ; rapport du lot 0 `.planning/missions/2026-11-11-audit-cockpit-lot-0.md` ;
registres P67 à P78 ; `DESIGN.md` (fait foi).

**Exigences :** TEMP-01 à TEMP-12. Préfixe neuf, vérifié libre le 2026-11-11 dans tous les ledgers
(`.planning/workstreams/*/REQUIREMENTS.md`), sous `.planning/`, `docs/` et `plugin/`.

<domain>
## Phase Boundary

L'onglet Équipe raconte la journée de l'équipe. Une **frise** montre toutes les sessions et tous les agents du lab sur une
horloge commune (une voie par agent, l'enfant sous son parent), avec ce qui s'est passé dessus : travail, attente de
l'humain, attente des agents, repos, commits, compactions, erreurs, messages humains, rapports rendus. Un **curseur**
rejoue un instant : ce que chacun faisait, quels nœuds du plan étaient portés, quels fichiers venaient d'être écrits. La
**fiche d'un agent** s'ouvre en plein cadre depuis la frise ou la régie : ses faits (rattachement, durées, jetons, outils,
erreurs, fichiers) à gauche, son fil daté à droite (le lecteur). Le **coût** se lit en jetons et en durée, par agent, par
mission, par phase et par étage, sur la fenêtre affichée.

**Dépend de :** Phase 79 (contrats figés au commit `3119d82a` : C1 index privé, C3 route de frise
`GET /api/vf/frise` → `vibeflow/cockpit-frise@1`, C4 événement `frise` et magasin de page `window.VF_ETAT`, C6 contrat de
forme étendu par la 79 elle-même et retrait de `plugin/cockpit/amont/`) ; Phase 73 (régie de l'onglet Équipe : point d'ouverture de la fiche, place de la bascule) ; Phase 69
(onglet Équipe, lien agent ↔ nœud). Le lot 0 de l'audit, déjà dans la base, a livré le fil unique ordonné et daté
(`cockpit-transcript@2`) : la 74 n'en porte que le lecteur (reste de AUDC-D8).

**Hors périmètre :** toute fenêtre au-delà de 24 h, dont « 7 j » (AUDC-Q2) ; toute action sur une session (ouvrir, écrire,
arrêter : Phase 81, AUDC-Q3) ; la mise en évidence continue de l'activité sur la carte Code et le radar de collisions
(Phase 75, AUDC-I12, I13) ; le coût dans la synthèse du jalon (Phase 77) ; le journal de coût hors fenêtre et la relève de
fin de mission (Phase 52) ; les limites d'abonnement de 5 h et de 7 jours et le plafond de coût (réserve, AUDC-I35) ; la
collecte, l'index et leur persistance (Phase 79) ; la régie elle-même (Phase 73).
</domain>

<decisions>
## Implementation Decisions

Toutes les décisions ci-dessous sont des **décisions déléguées par Samuel (message session principale, 2026-11-08), option
recommandée**, prises par le manager de la mission sur les sources citées. Aucune ne vaut arbitrage de Samuel. Les panels
de recherche prévus n'ont pas pu être lancés (plafond de sous-agents simultanés de la session atteint par la vague des sept
cadrages) : les faits ont été relevés par le manager lui-même dans le code et les annexes, chaque décision cite sa source.

### Arbitrages en vigueur, repris sans les rouvrir

- AUDC-Q2 : index sur disque borné à heures, durées, jetons et verbes ; fenêtre de 24 h ; « 7 j » hors périmètre ;
  P69-D-18 non rouverte. AUDC-Q4 : `claude agents --json` source de référence de l'état, transcripts en repli, derrière
  le contrat de forme. AUDC-Q3 : aucune action sur une session. AUDC-Q5 : fork du moteur assumé.
- P67-D-02 (aucune lecture réseau) ; P67-D-14 (la dernière commande jamais dans le flux, un fichier ou l'export) ;
  P69-D-15 (rattachement jamais deviné : registre, puis nœud cité dans le mandat et présent dans un DAG connu) ;
  P69-D-16 (verbe et cible réduite, jamais un argument) ; P69-D-19 et P69-D-23 (messages et actions sans sortie d'outil,
  à la demande, jamais exportés, jamais dans le flux sans requête authentifiée) ; PU-G-162 (titre par `custom-title`
  seul).
- Q9 et `DESIGN.md` § 9 (ni couleur d'alerte, ni fond teinté, ni contour coloré, trois teintes d'état, état lisible sans
  la couleur) ; P71.5-D-01 (grille fermée 2, 4, 6, 8, 12, 16, 20, 24, 32) ; Q11 (points de rupture inchangés) ; Q12 (un
  tiroir latéral ne pousse jamais la carte ; P71-D-35 pour le tiroir du terminal) ; P78-D-04 (pas de quatrième onglet) ;
  Q8 (pas de terminal sur l'onglet Équipe) ; P68-D-03 (gestes de `vf-signal` réservés à la session courante).

### Forme et place

- **P74-D-01 (couleur de la frise).** Le but du ROADMAP (2026-11-03) dit « une ligne par agent, colorée par nœud de DAG ».
  Cette lecture contredit `DESIGN.md` § 9 (trois teintes d'état, une couleur ne code jamais une catégorie libre) et Q9.
  La frise est bâtie sur `DESIGN.md` : **le nœud du plan s'écrit sur la voie** (seconde ligne de la colonne de gauche,
  étiquette du segment quand il change), **la couleur reste aux trois états**. Le but du ROADMAP n'est pas réécrit
  (AUDC-V6) : une note de lecture y renvoie à cette décision. Confirmée par Samuel le 2026-11-11 (P74-D-46).
- **P74-D-02 (place de la frise).** Une bascule à deux positions dans l'en-tête de l'onglet Équipe, « Régie · Frise »,
  régie par défaut (l'attention d'abord, DESIGNS § 2). Pas de quatrième onglet (P78-D-04). La position choisie est
  gardée pour la page, jamais dans un fichier du lab. La bascule elle-même est posée avec la régie si la Phase 73 la livre
  d'abord ; sinon par la 74 (à régler à la jointure des plans, carte des fichiers du rapport).
- **P74-D-03 (fiche et lecteur, une seule surface).** La fiche d'un agent EST le lecteur plein cadre (AUDC-I04 et I28
  réunis) : une vue qui occupe la zone de contenu de l'onglet Équipe, deux colonnes — faits à gauche, fil daté à droite
  (DESIGNS § 5) —, en une colonne au téléphone (faits repliés en tête). Elle remplace la boîte de transcript de 320 px du
  panneau (AUDC-M4). Ce n'est pas un tiroir latéral : Q12 ne s'y applique pas ; elle ne recouvre jamais la carte d'un
  autre onglet. Échap ou « Retour » la ferme et rend le focus à l'élément qui l'a ouverte. Aucune adresse dans l'URL (les
  onglets sans rechargement, AUDC-I30, attendent le socle et la Phase 80).
- **P74-D-04 (ouverture).** La fiche s'ouvre depuis une voie de la frise (clic, Entrée) et depuis une ligne de la régie
  (Phase 73, même fonction d'ouverture). Une session et un sous-agent ont la même fiche ; pour une session, l'intertitre
  « Mandat » n'existe pas (AUDC-D7, lot 0).

### Frise

- **P74-D-05 (voies).** Une voie par agent ; les enfants sous leur parent, reliés par un trait vertical à l'instant du
  dispatch ; la colonne de gauche porte le nom (écrit une fois), le rôle, puis le nœud du plan ou l'arbre en seconde ligne
  discrète. Une session vivante sans activité dans la fenêtre reste listée, au repos (elle ne disparaît plus).
- **P74-D-06 (segments).** Quatre sortes de segment, chacune lisible sans la couleur par sa forme : au travail = barre
  pleine (teinte « en cours ») ; vous attend = barre hachurée de la même teinte, **sans contour coloré** (DESIGN § 9 :
  la couleur d'un état ne dessine pas un conteneur ; la maquette proposait un contour jaune, il est retiré) ; attend ses
  agents = trait fin ; au repos = pointillé neutre. Une erreur ne teinte jamais une voie : elle est un événement.
- **P74-D-07 (événements).** Posés sur la voie de l'agent : compaction (triangle vide), erreur d'outil (croix, teinte
  corail portée par le seul glyphe), message de l'humain (point), rapport rendu (coche), dispatch (trait vers l'enfant).
  Les **commits** sont posés sur un bandeau « Dépôt » en tête de frise, par branche, lus sur la route Git existante
  (`vibeflow/cockpit-git@1` ; les commits sont hors de la route de frise, C3), jamais attribués à une voie d'agent :
  aucune donnée ne relie un commit à l'agent qui l'a fait sans deviner (P69-D-15, P69-D-16 interdit de lire l'argument
  d'une commande). Un clic sur un commit ouvre le tiroir Git sur ce commit (Phase 78).
- **P74-D-08 (fenêtres).** 1 h 30 (défaut), 6 h, 24 h. Jamais au-delà (AUDC-Q2). Une mission plus longue que la fenêtre
  se lit tronquée à gauche, et le dit (« commencée avant la fenêtre »).
- **P74-D-09 (deux lectures).** Horloge (défaut : les durées sont vraies) et Événements (les silences de plus de 2 min,
  seuil existant de « sans nouvelle », sont compressés en un repère de largeur fixe qui dit leur durée). Le libellé de
  l'axe dit la lecture en cours ; en Événements, aucune durée ne se lit à la longueur d'un segment.
- **P74-D-10 (échelle).** Au-delà de douze voies visibles, les workers se replient sous leur manager (« + N agents »,
  dépliable) ; le bandeau haut porte la courbe du nombre d'agents au travail. Seuil à confirmer par la spécification
  d'interface ; il n'agrège jamais en silence (le compte replié est écrit).
- **P74-D-11 (direct).** La frise suit le flux partagé de la Phase 79 (C4 : événement `frise` porteur de la seule
  signature, puis relecture authentifiée de `GET /api/vf/frise` ; abonnement par `VF_ETAT.abonner('frise', …)`) ; tant que
  `source.etat` vaut `en-construction`, la frise le dit et montre les voies déjà connues ; le trait « maintenant » avance ; aucune donnée de frise ne passe dans le flux.

### Relecture au curseur (AUDC-I06, idée 3)

- **P74-D-12 (portée de la relecture).** Un curseur temporel sur la frise (pointeur, flèches au clavier). À l'instant t,
  un encart « À cet instant » dit : l'état de chaque voie, les **nœuds du plan portés par un agent au travail** à t, les
  fichiers écrits autour de t. Le geste « Voir sur la carte » ouvre l'onglet Code avec ces fichiers mis en évidence. La
  mise en évidence continue de l'activité sur la carte (empreinte en direct) reste à la Phase 75 (AUDC-I13) : la 74 ne
  pose qu'une mise en évidence ponctuelle, à la demande.
- **P74-D-13 (source des transitions de nœuds).** Les DAG de mission n'enregistrent aucun horodatage de transition
  (`dag.sh mark` n'en écrit pas ; mesuré dans `plugin/conductor/scripts/dag.sh`). L'état d'un nœud à t se **dérive** des
  voies des agents qui le portent (rattachement P69-D-15) : « porté par un agent au travail », « porté, agent au repos »,
  « aucun agent ». La relecture ne prétend jamais rejouer le statut du DAG (`ready`, `blocked`…) : elle ne l'a pas.
  `dag.sh` n'est pas modifié par la 74.
- **P74-D-14 (fichiers à l'instant t).** Lus à la demande depuis le fil réduit de l'agent (`cockpit-transcript@2` : heure,
  verbe, cible réduite), jamais depuis une cible persistée par la 74 : l'index sur disque reste borné à heures, durées,
  jetons et verbes (AUDC-Q2, C1). Les `cibles` de la voie (C3) sont des agrégats en mémoire (nombre, dernière écriture),
  sans heure par écriture : elles servent aux comptes de la fiche, pas à l'instant t.

### Fiche d'agent et lecteur

- **P74-D-15 (faits).** Rattachement (« Worker de <parent> · nœud <id> · Phase <n> », chaque terme ouvre sa cible : fiche
  du parent, carte de mission, phase — les trois graphes reliés, AUDC-I21) ; nom, nœud, arbre, modèle ; puis : durée au
  travail dont temps à attendre l'humain ; contexte au dernier tour (en jetons) et nombre de compactions ; appels d'outil
  dont erreurs ; jetons (entrée, sortie, cache lu, cache écrit) ; fichiers écrits et lus (comptes, depuis `cibles` de C3 ;
  « en cours de lecture » tant que `cibles.etat` vaut `en-construction`). Les compactions sont comptées, sans leurs tailles
  (absentes de C3). Une donnée que la
  source ne donne pas s'écrit « inconnu », jamais un zéro (même règle que la Phase 52 : « jamais estimé »).
- **P74-D-16 (part du contexte).** En pourcentage seulement si la taille de la fenêtre de contexte vient d'une source
  documentée ; sinon en jetons (`jetons.contexteDernier` de C3 ; `contexteMax` est le plus haut observé, pas la taille de
  la fenêtre). Le pourcentage tiré d'une fenêtre supposée est heuristique (A1 § 3) : il n'est pas affiché.
- **P74-D-17 (fil).** Une liste datée, du mandat à maintenant ; chaque ligne : heure, glyphe, verbe et cible réduite, ou
  message. Filtres : messages, outils, erreurs (cumulables). Suivi en direct : la liste reste collée en bas tant que
  l'utilisateur n'a pas remonté ; « Revenir au direct » sinon. Plafond de la réduction inchangé (50 messages, 200 outils,
  `vf-cockpit-transcript.mjs:16`) ; la coupe est dite (« plus ancien que la fenêtre lue »). Le mandat est replié, lu à la
  demande. Jamais une sortie d'outil, jamais l'argument d'une commande, jamais exporté.
- **P74-D-18 (markdown des messages).** Rendu en texte (PU-G-168 : plus de markdown brut) par un sous-ensemble fermé —
  paragraphes, listes, code en ligne et blocs de code, emphase — construit en nœuds DOM avec `textContent`, jamais par
  `innerHTML` d'une chaîne venue du transcript ; liens rendus en texte, non cliquables. CSP inchangée.
- **P74-D-19 (erreurs dans le fil).** Une erreur d'outil est un fait de l'index (`is_error`), pas une sortie : le fil dit
  « échec » sur la ligne de l'outil, jamais le texte de l'erreur.

### Coût (AUDC-I07, I08, idée 2)

- **P74-D-20 (unité).** Le coût se lit en **jetons et en durée**, comme le dit le but arbitré (« le coût en jetons et en
  durée par mission, phase et agent »). Aucun montant en devise dans la 74 : une estimation au tarif public demanderait une
  table de tarifs à tenir à jour dans le module, et la Phase 52 pose « jamais estimé ». La proposition « coût estimé au
  tarif public » de DESIGNS § 5 n'est pas reprise ; signalé à Samuel (point 2), sans bloquer.
- **P74-D-21 (agrégats).** Par agent ; par mission (agents rattachés à un nœud d'un DAG de mission) ; par phase (mission →
  phase) ; par étage (tête, manager, worker, selon la règle de P74-D-42 : jamais la profondeur seule). Les agents non rattachés forment
  une ligne « hors mission », comptée à part, jamais répartie. Chaque agrégat porte sa fenêtre (« sur les dernières 6 h ») :
  un coût de phase sur 24 h n'est jamais présenté comme le coût de la phase.
- **P74-D-22 (le calcul partagé avec la Phase 52).** Un seul calcul : **la somme des jetons de `message.usage`,
  dédoublonnée par identifiant de message (2 à 8 lignes par message, A1 § 3), par transcript, posée dans l'index de la
  Phase 79** (C1 : curseur `dernierMsgId` et son `usage` ; C3 : `jetons` de la voie). La 74 l'agrège, elle ne recompte jamais les transcripts. La Phase 52 réutilise cette fonction (ou lit
  l'index quand le cockpit est installé) au lieu d'en écrire une seconde : consigné pour son cadrage (« À verser par la
  jointure » du rapport).
- **P74-D-23 (temps perdu à attendre l'humain).** Somme des segments « vous attend » d'un agent ou d'une fenêtre, tirés
  de l'état officiel (« bloquée », AUDC-Q4) et, en repli et pour l'historique, d'une question ou d'une permission sans
  réponse dans le transcript. Les segments ne disent pas leur provenance (C3) : seule la mention de l'état présent d'une
  voie sans état officiel dit « déduit » (P74-D-39).
- **P74-D-24 (limites d'abonnement).** Les limites de 5 h et de 7 jours ne sont pas dans la 74 : publiées pour la session
  principale seulement, pour trois abonnements, via la ligne d'état (A6 § 3), elles demandent un relais par le script de
  ligne d'état, hors de ce que lit le socle. Elles restent avec le plafond de coût (réserve, AUDC-I35). Signalé à Samuel
  (point 3).

### Données, contrat, bornes

- **P74-D-25 (lecture par le socle seul).** La 74 ne lit aucun transcript elle-même : elle consomme la route de frise et
  l'index de la Phase 79, la route d'état, et la route de transcript existante (`/api/vf/transcript`). Toute clé lue est
  déclarée au contrat de forme (`vf-cockpit-interface.json`) ; l'extension pour `message.usage`, `message.id`,
  `compact_boundary`, `turn_duration` et les identifiants d'appel et de résultat d'outil est faite par la 79 (C6) ; la 74
  vérifie que chaque champ affiché y figure et lit `schema` avant tout champ (C0).
- **P74-D-26 (durées par segments, AUDC-D9).** La durée affichée d'un agent est la somme de ses segments au travail
  (et non `dureeS`, qui compte les veilles d'un agent réveillé, jusqu'à 101 h). Le retrait de `dureeS` des consommateurs
  de la 74 se fait côté page : la fiche et la frise lisent `durees` de C3 ; le champ `dureeS` de `cockpit-who@2` reste
  émis sans changement de forme (C0 : les schémas existants ne changent pas), pour ses autres lecteurs.
- **P74-D-27 (bornes d'émission).** Routes en GET seul, derrière Host, Origin et jeton ; clés `doing`, `mandat`,
  `messages`, `outils`, `fil` refusées dans le flux ; l'export ne contient ni frise, ni fiche, ni fil ; aucune lecture
  réseau ; la dernière commande n'apparaît nulle part. La chaîne XSS des suites est étendue aux données de la frise et de
  la fiche (nom d'agent, nœud, titre, message hostiles).

### Un ajout, un retrait

- **P74-D-28 (retraits de la 74).** (1) La boîte de transcript du panneau (320 px, défilement imbriqué) et son bouton
  « Lire le transcript » : remplacés par la fiche plein cadre. (2) La durée unique d'un agent qui compte ses veilles :
  remplacée par la durée par segments. (3) Partagé avec la 73 (registre § 3) : la carte « Terminés depuis moins de 24 h ».
  La 73 la retire avec le canevas de l'onglet ; la 74 en porte la compensation pour l'historique (la frise sur 24 h,
  P69-D-18 tenue). Si la 73 ne la retire pas, la 74 le fait. Le retrait vise la carte seule : le groupe repliable des
  terminés de moins de 24 h du tiroir « Au travail » (rendu livré de CKPT-20, P69-D-18) reste en place.

### Jointure avec la régie et la spécification d'interface

- **P74-D-29 (glyphes).** La frise et la fiche n'ont pas de jeu de glyphes propre : elles prennent la table unique de
  la régie (Phase 73) ou, à défaut, la table `GLYPHE` présente (`71-vf-equipe-rendu.js`). Un glyphe d'état n'existe qu'à
  un endroit.
- **P74-D-30 (choix de forme de la spécification d'interface, acceptés).** « Attend ses agents » en trait neutre (la
  couleur ne dit que ce qui appelle l'humain ou travaille) ; clic sur la colonne de gauche = fiche, clic dans la zone des
  segments = curseur ; faits de la fiche sur l'horizon de l'index (24 h), libellé visible ; « autour de t » = ± 2 min ;
  ligne de synthèse en entrée et sortie, cache dans le détail ; liens `#r=` du tiroir « Au travail » redirigés vers la
  fiche (jointure avec la 73) ; au téléphone, colonne de gauche collante et pistes en défilement horizontal propre à la
  frise ; position de la bascule en mémoire de la page (`sessionStorage`), jamais dans un fichier du lab.
- **P74-D-31 (moteur vendorisé).** La 74 ne modifie aucun fichier du moteur (`viewer.html`, `serve.mjs`, `scan.mjs`) :
  tout son rendu vit dans des modules `ui/*vf*` et ses lectures passent par les routes de la 79. Elle s'exécute après la
  première vague de la 79 (retrait de `plugin/cockpit/amont/`, C6) et ne régénère aucun diff de patch.

### Amendement de la Phase 79 (`2ae6607a`) et points de la spécification d'interface

- **P74-D-32 (jetons et fenêtre).** Les `jetons` d'une voie (C3) couvrent sa vie dans les 24 h de l'index ; seuls
  `segments` et `durees` sont coupés à la fenêtre demandée. Tout agrégat de jetons porte donc « sur les dernières 24 h »
  (agents présents dans la fenêtre), les durées portent la fenêtre affichée : deux libellés, jamais un seul qui mentirait
  pour l'un des deux. Aucun découpage des jetons n'est demandé à la 79.
- **P74-D-33 (commits, A9).** `rangees[].at` est en secondes Unix (× 1000 pour la frise). La marche de la route Git est
  bornée à 500 commits : la 74 mesure la couverture (commit le plus ancien lu postérieur au début de la fenêtre et borne
  atteinte) et le bandeau « Dépôt » dit alors « incomplet » avec l'heure à partir de laquelle il l'est.
- **P74-D-34 (voie du manager, A14).** `rattachement` `{ dag, noeud: null, source: "enfants" }` rattache le manager à la
  mission (coût de l'étage manager par mission et par phase) ; sur la voie, aucun nœud n'est écrit pour lui ; la fiche dit
  « rattaché par ses agents ». `rattachement.dag` vaut `signal.missions[].fichier` (A8) : la jointure mission → phase passe
  par `phaseKey`.
- **P74-D-35 (lectures du curseur).** Un déplacement du curseur relit au plus les fils réduits des voies au travail à
  l'instant t, au plus six par instant, mis en cache dans la page jusqu'à l'événement `frise` suivant ; au-delà, ou quand
  t est plus ancien que le fil réduit (plafond de 50 messages et 200 outils), l'encart dit « fichiers non lus ».
- **P74-D-36 (genre `silence`).** Le genre `silence` de C3 ne dessine rien (un blanc sur la voie), distinct du repos ;
  à confirmer à la recette.
- **P74-D-37 (règles communes de la 79).** Toute lecture par la page passe par `VF_ETAT.jeton()` et `VF_ETAT.lireJson()`
  (A13) ; « Voir sur la carte » passe par l'onglet Code tel que la coquille l'expose (A2, routage de la Phase 80) ; la 74
  ne pose aucune route serveur (la règle A10/A11 ne la concerne que si un plan en ajoute une, par une ligne de la table).

### Points de la recherche (`74-RESEARCH.md`)

- **P74-D-38 (fil réduit, trois ajouts facultatifs).** Le réducteur `cockpit-transcript@2` ne lit que les lignes de
  l'agent : il n'a ni l'issue d'un outil, ni les compactions, ni les messages de l'humain. Il gagne trois champs
  facultatifs, sans changement de version (C0) : `echec: true` sur une ligne d'outil dont le résultat apparié par
  identifiant porte le drapeau d'erreur (seul le drapeau est lu, jamais le contenu du résultat) ; une ligne
  `{ t, genre: 'compaction' }` ; une ligne `{ t, genre: 'humain' }` sans texte (« Message de l'humain »). Témoin : un
  résultat d'outil porteur d'un secret n'apparaît jamais dans la sortie.
- **P74-D-39 (« · déduit »).** Les segments de C3 ne disent pas leur provenance : la mention « déduit » ne s'applique
  qu'à l'état présent d'une voie dont `etatOfficiel` est nul, jamais à un segment passé.
- **P74-D-40 (tiroir Git ouvert sur un commit).** Le tiroir Git n'expose aucune ouverture sur un commit : la 74 ajoute
  une fonction publique `ouvrir(sha)` au module de détail du tiroir (Phase 78), sans changer son rendu. Les commits de
  la frise sont rangés par branche côté page, en descendant le premier parent depuis chaque branche (même règle que la
  teinte du graphe Git côté serveur).
- **P74-D-41 (retrait de la durée qui compte les veilles, précisé).** Dans l'onglet Équipe, toute durée affichée par la
  74 vient de `durees.travailS` ; la ligne du tiroir « Au travail » passe sur la même source dans le plan des retraits
  (après la 73). Si la régie de la 73 a remplacé ce tiroir, ce point tombe avec lui et le retrait (2) se limite à la
  fiche.
- **P74-D-42 (étages).** Tête = voie de genre session ; manager = sous-agent qui a au moins une voie enfant ; worker =
  sous-agent sans voie enfant. La profondeur seule classerait manager un worker lancé par la tête.
- **P74-D-43 (modules et traduction).** Tout le rendu de la 74 vit dans des modules neufs `ui/74-vf-*.js` (préfixe
  libre, inclus seuls par ordre alphabétique, CSP adaptée au service) qui commencent par `// VibeFlow (` et marquent
  leurs données pour que la traduction de la page (`80-vf-fr.js`, modifié par la 79) ne les réécrive pas. Rayons et
  espacements par variables seulement (garde `css-jetons.mjs`). Aucun bump de version du module dans la 74 : un seul
  pour la vague, à la jointure.

### Jointure avec la Phase 80 (surcouches)

- **P74-D-44 (fiche et pile de surcouches).** La fiche plein cadre est une vue de l'onglet Équipe, pas une surcouche :
  elle ne s'inscrit pas dans la pile `window.VF_SURCOUCHES` de la Phase 80 (P80-D-33 à D-41 annoncées). Sa touche Échap
  ne s'applique que si `VF_SURCOUCHES.ouverte()` est faux (une surcouche ouverte au-dessus garde Échap pour elle). Toute
  surcouche que la 74 viendrait à poser passe par `VF_SURCOUCHES.ouvrir(el, { modale, ouvreur, fermer })`, jamais par une
  gestion propre du focus et d'Échap. L'objet global du moteur est gelé : la 74 n'y ajoute rien, ses fonctions vivent
  sous un espace de noms à elle (`window.__vfFrise`, `window.__vfFiche`). À revalider sur la 80 quand son commit est poussé.

- **P74-D-45 (cycle de vie par onglet, A30 de la 79).** La frise, la fiche et le lecteur s'initialisent par
  `VF_COQUILLE.surOnglet(rappel)` (amendement A30, commit `74501bb0` de la branche de la 79), jamais au seul chargement de
  la page ; le rappel rend une fonction de nettoyage qui retire les abonnements à `VF_ETAT`, les minuteries, les
  écouteurs et le DOM posé quand on quitte l'onglet Équipe. Chaque plan qui pose du rendu l'écrit dans ses critères.

### Arbitrage de Samuel

- **P74-D-46 (couleur de la frise, confirme P74-D-01 ; question P74-Q-01).** Arbitrage Samuel, AskUserQuestion session principale,
  2026-11-11. Question telle qu'elle a été posée : le but écrit dit « une frise colorée par nœud du plan de bataille » ;
  `DESIGN.md` § 9 réserve la couleur aux états ; le cadrage a suivi la règle de design. Réponse, mot pour mot (libellé
  coché) : « Suivre la règle de design (Recommandé) » — option telle qu'elle a été présentée : « La couleur continue de
  dire l'état ; le nom du nœud s'écrit en toutes lettres sur chaque voie de la frise. C'est ce que les plans prévoient
  déjà. » Conséquence : P74-D-01 vaut arbitrage ; aucun plan ne change ; le but du ROADMAP n'est pas réécrit (AUDC-V6),
  sa note de lecture cite cet arbitrage. Les trois autres points « À Samuel » (devise, limites de 5 h et de 7 jours,
  relecture par dérivation) et le genre `silence` restent des décisions déléguées, option recommandée.

### Jointure avec la Phase 75 (canal de marquage)

- **P74-D-47 (canal de marquage des cartes).** Décision déléguée par Samuel (message session principale, 2026-11-08),
  option recommandée (coordination de détail entre deux phases, tranchée par la session principale le 2026-11-11). La
  Phase 75 pose le canal de marquage unique (P75-D-05 ; plan 75-07 : `ui/75-vf-marques.js`, `ui/75-vf-marques-glyphes.js`
  et l'accroche dans la page, noms au commit `9ddbe831` de la branche de la 75). La 74 ne le pose pas (P74-D-31 : aucun fichier du moteur). D'ici là, « Voir sur la carte »
  (74-06) passe par `showBoard` du moteur, mécanisme **provisoire** nommé comme tel ; dans le même lot que 75-07, la 75
  rebranche ce geste sur une couche temporaire du canal (une ligne dans `ui/74-vf-frise-carte.js`, à ses
  `files_modified`), avec un témoin que le geste marque bien les cartes. 74-06 écrit le contrat de branchement (point
  d'appel, liste de fichiers passée, témoin à adapter).
- **Ordre de chargement.** `ui/74-vf-frise-carte.js` se charge avant le canal (`ui/75-vf-*`) : il n'appelle rien du
  canal au chargement du script, seulement au geste. Le préfixe `ui/74-vf-` reste réservé à la 74 (P74-D-43).

### Reprise du 2026-11-11 : panels et revalidation sur les contrats voisins

Toutes « décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée », sur trois panels
(fil, relecture, Dépôt) et une revalidation contre les têtes des Phases 79 (`daae8bc9`, A15 à A47, P79-D-28 à D-33), 73
(`e4466eba`, P73-D-14, P73-D-20, P73-D-26, P73-D-33) et 80 (`c9ec8756`, 80-02, 80-06, 80-10). Elles amendent les
décisions citées ; le texte d'origine reste au-dessus pour l'historique.

- **P74-D-48 (fil réduit, amende P74-D-38).** Le réducteur ne gagne que `echec: true` (résultat apparié par identifiant,
  préfiltre sur le drapeau d'erreur vrai, `Map` des identifiants, un appel en échec jamais regroupé avec des appels
  réussis, seul le drapeau lu). Les lignes `compaction` et `humain` du fil sont fusionnées CÔTÉ PAGE depuis les
  `evenements` de la voie (C3), bornées au plus ancien horodatage du fil : une seule règle « humain » et « compaction »,
  celle de l'index de la 79. Le fichier `vf-cockpit-transcript.mjs` est modifié aussi par 79-13 (règle de chemin unique,
  `reduireCible`, forme `(worktree <nom>)`) : 74-02 s'exécute sur la base où 79-13 est fusionné, et le dit en précondition.
- **P74-D-49 (relecture au curseur, amende P74-D-12, D-14, D-35 ; D-13 gardée).** Les fichiers « autour de t » se
  cherchent sur les voies dont le travail recoupe [t − δ, t + δ], avec δ = max(2 min, pas du curseur / 2). Premier filtre :
  `cibles[].dernierMs` (C3, A45) — dans la fenêtre : écrit, certain ; avant : non écrit, certain ; après : incertain, et
  seul ce cas lit le fil réduit. Une entrée regroupée couvre l'intervalle jusqu'à l'élément suivant ; le fil est jugé trop
  court quand son premier élément est après t − δ et qu'il est tronqué. Lecture 250 ms après le dernier déplacement ou au
  relâché, au plus deux lectures en vol et six par instant, cache par (voie, `fin`) gardé tant que `fin` ne bouge pas ; au
  delà, liste partielle et « N voies non lues », jamais six lectures jetées. `noeudsPortes` rend l'état de la voie qui
  porte le nœud (travail, vous attend, attend ses agents, repos). L'issue d'un agent tirée du registre du verrou n'est
  affichée que si la 79 la publie.
- **P74-D-50 (Dépôt, amende P74-D-33 et D-40 ; D-07 gardée).** Couverture : le dépôt est « peut-être incomplet avant
  <heure> » quand la marche est tronquée et que le plus récent des instants entre le plus ancien commit lu et la plus
  récente rangée dont un parent n'a pas été lu (secondes × 1000) est dans la fenêtre — la marche est topologique, le plus
  ancien commit lu ne borne rien seul. Descente du premier parent : la chaîne de la base d'abord, puis les branches
  locales, puis les distantes ; les commits atteints par aucune forment une dernière ligne « Autres commits (branches
  fusionnées ou sans nom) », jamais pliée. La route Git se lit au montage puis sur `VF_ETAT.abonner('git')`, jamais au
  rythme de l'événement `frise`. Ouverture d'un commit : par le tiroir et le volet de détail de la Phase 80
  (`VFGitTiroir.ouvrir`, puis `VFGitVolet.ouvrir(sha, rangee)`, 80-06) ; la 74 ne modifie plus
  `ui/77-vf-git-vue-detail.js`.
- **P74-D-51 (jointure avec la régie, P73-D-20 ; amende P74-D-02, D-04, D-28 (3), D-30, D-41).** La frise se déclare
  comme une vue de la régie (`window.__vfEquipeVues.declarer({ id: 'frise', libelle: 'Frise', monter, demonter })`, dans
  `section#vf-equipe`) : la bascule est dessinée par la 73, la 74 n'en pose pas. La fiche s'ouvre en annulant l'événement
  de document `vf-agent:ouvrir` (déclencheurs convenus avec la 73) et émet `vf-agent:lu` à l'ouverture d'un agent
  terminé. La 74 ne modifie aucun fichier de la 73. Le pli « Terminés » du tiroir « Au travail » est retiré par la 73
  (P73-D-14, 73-10) et le tiroir quitte l'onglet Équipe : le retrait (3) de la 74 se réduit à la carte du canevas si elle
  existe encore, et la durée du tiroir (D-41) tombe. `__vfEquipeRendu.transcript` reste exporté tant que le lecteur de
  repli de la 73 l'utilise. Glyphes : `__vfEquipeRendu.GLYPHE_ETAT` (73-04).
- **P74-D-52 (contrats de la 79 et de la 80 depuis A15).** `arbre: null` désigne l'arbre principal (A45), jamais
  « inconnu » ; `cibles: null` = forme inconnue (A43) ; les comptes de fichiers se font par couple (`arbre`, `cible`) et
  disent « 200 ou plus » au plafond ; une cible du fil réduit de forme `<chemin> (worktree <nom>)` se lit
  `{ arbre: <nom>, cible }`, une cible coupée à 120 caractères ne se pose sur aucune carte. Quand `tronque` est vrai
  (dont la coupe à 500 voies, A43, A47), la frise dit que des voies ne sont pas montrées et les totaux de coût disent
  « incomplet ». Un 400 `bornes-invalides` donne l'état « indisponible ». Les phases lisent `VF_ETAT`, jamais `VF_FLUX`.
  « Voir sur la carte » passe par `VF_ONGLETS.aller('code')` (80-10) quand il existe. Un fichier de code fait 299 lignes
  au plus (A44) et aucune ligne de plus de 160 colonnes ; chaque module neuf a sa ligne `AJOUT` dans `VENDORED.txt`,
  posée par 74-09 seul (journal de vendoring, seule exception à P74-D-31). La suite de la frise de la 74 s'appelle
  `test-cockpit-frise-vue.sh` (`test-cockpit-frise.sh` appartient à 79-13). Les mutants se posent sur une copie du
  MODULE servie par l'aide commune des suites, jamais sur une copie de la sortie (79-06, 79-16, A41).

- **P74-D-53 (Échap, amende P74-D-44 ; contrats de la 80 au commit `95ab6578` et de la 73 au commit `b5abfeec`).**
  La fiche et le lecteur sont des vues de l'onglet Équipe, pas des surcouches. Échap s'écoute en phase de remontée (sur
  `document` ou la racine de la vue), jamais en capture sur `window` ; un appui dont `event.defaultPrevented` est vrai
  (une surcouche vient d'être fermée par la pile) est ignoré ; la vue ne lit jamais `VF_SURCOUCHES.ouverte()`. Sans
  surcouche, Échap ferme la fiche et rend le focus à l'élément ouvreur (`declencheur` quand la fiche vient de la régie).
  Ouverture d'un commit : la seule entrée publique `window.VFGitTiroir.ouvrirSur(sha)` (promesse vrai ou faux, jamais
  d'exception) remplace la composition interne écrite dans P74-D-50. Retrait du lecteur de repli de la 73 (P73-C2) :
  plan 74-10, en un geste (`ouvrirRepli` et son appel dans `ui/72-vf-regie-source.js`, propriété `transcript` de
  `__vfEquipeRendu`), après le témoin de l'annulation des trois déclencheurs `nom`, `ancre`, `rapport` ; seule exception
  à P73-D-20. Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.

### Claude's Discretion

Laissés à la spécification d'interface et à la planification, dans les bornes ci-dessus : la géométrie de la frise
(hauteur de voie, graduations, densité des étiquettes), la forme exacte de l'encart « À cet instant », le seuil de repli des
voies (P74-D-10), le mécanisme de mise en évidence sur la carte Code (P74-D-12), la pagination du fil au-delà du plafond.
</decisions>

<specifics>
## À Samuel

Format C76-Q1 (Phase 76, P76-D-34). Une question tranchée, quatre appliquées sous délégation ; aucune ne bloque un plan.

- **P74-Q-01 — Couleur de la frise.** Le but écrit dit « une frise colorée par nœud du plan de bataille » ; `DESIGN.md` § 9
  réserve la couleur aux états ; faut-il colorer les voies par nœud ?
  Options : (a) suivre la règle de design : la couleur dit l'état, le nom du nœud s'écrit sur chaque voie ; (b) colorer par nœud, en rouvrant Q9 .
  Recommandation : (a) — une couleur par nœud demanderait une palette libre que Graphite interdit, et la couleur cesserait de dire l'état.
  Bloque : rien
  État : tranchée — arbitrage Samuel, AskUserQuestion session principale, 2026-11-11 — option (a) — « Suivre la règle de design (Recommandé) »
- **P74-Q-02 — Montant en devise.** Le coût se lit-il seulement en jetons et en durée, ou aussi en devise, estimée au
  tarif public (proposition de DESIGNS § 5) ?
  Options : (a) jetons et durée seulement, comme le dit le but ; (b) ajouter un coût estimé au tarif public .
  Recommandation : (a) — une estimation demande une table de tarifs à tenir dans le module, et la Phase 52 pose « jamais estimé ».
  Bloque : rien
  État : appliquée — décision déléguée par Samuel (message session principale, 2026-11-08), option (a) — P74-D-20
- **P74-Q-03 — Limites de 5 h et de 7 jours.** AUDC-I07 plaçait ces limites dans la 74 ; les y garder ?
  Options : (a) en réserve avec le plafond de coût (AUDC-I35) ; (b) dans la 74, par un relais de la ligne d'état .
  Recommandation : (a) — elles ne concernent que la session principale, pour trois abonnements, et demandent un relais hors de ce que lit le socle.
  Bloque : rien
  État : appliquée — décision déléguée par Samuel (message session principale, 2026-11-08), option (a) — P74-D-24
- **P74-Q-04 — Relecture nœud par nœud.** Le but dit « rejoue une mission nœud par nœud » ; les plans de mission
  n'horodatent pas leurs transitions : l'état d'un nœud à l'instant t se dérive-t-il des voies des agents qui le portent ?
  Options : (a) dériver l'état des voies (porté par un agent au travail, au repos, ou par aucun) ; (b) horodater les transitions de `dag.sh` (conductor, hors de cette phase) pour rejouer le statut exact .
  Recommandation : (a) — aucune donnée nouvelle, rien d'inventé ; (b) touche le socle de gouvernance pour un gain que la recette dira.
  Bloque : rien
  État : appliquée — décision déléguée par Samuel (message session principale, 2026-11-08), option (a) — P74-D-13
- **P74-Q-05 — Genre `silence` sur la frise.** La route de frise distingue le silence du repos : comment le dessiner ?
  Options : (a) ne rien dessiner (un blanc sur la voie) ; (b) le dessiner comme le repos (pointillé neutre) .
  Recommandation : (a) — quatre sortes de segment restent lisibles sans la couleur ; un blanc peut se lire comme une donnée manquante, à voir à la recette.
  Bloque : rien
  État : appliquée — décision déléguée par Samuel (message session principale, 2026-11-08), option (a) — P74-D-36
</specifics>

<canonical_refs>
## Canonical References

- `DESIGN.md` (racine) — § 2 (teintes d'état), § 4 (espacements), § 6 (mouvement), § 9 (règles strictes).
- `.planning/research/2026-11-10-audit-cockpit/DESIGNS.md` — § 2 (vocabulaire des états), § 4 (frise), § 5 (fiche), § 9.
- `.planning/research/2026-11-10-audit-cockpit/REGISTRE.md` — lignes AUDC-I04, I05, I06, I07, I08, I21, I28, M4, D8, D9.
- `.planning/research/2026-11-10-audit-cockpit/A1-donnees-agents-sessions.md` — § 3 (champs disponibles), § 4 (frise).
- `.planning/research/2026-11-10-audit-cockpit/page/audit-cockpit.html` — maquettes 2 (frise) et 3 (fiche).
- `plugin/cockpit/scripts/vf-cockpit-transcript.mjs` — réducteur `cockpit-transcript@2` (fil daté, bornes).
- `plugin/cockpit/scripts/vf-cockpit-interface.json` — contrat de forme (à étendre par la 79).
- `plugin/cockpit/skills/cockpit-moteur/assets/ui/71-vf-equipe-rendu.js`, `72-vf-equipe.js` — fiche et transcript actuels.
- `.planning/workstreams/fiabilite/phases/VFDO-69-suivi-travail-en-cours-cockpit/69-CONTEXT.md` — P69-D-15 à D-19, D-23.
</canonical_refs>

<deferred>
## Deferred Ideas

- Coût estimé en devise ; limites de 5 h et de 7 jours ; plafond de coût (AUDC-I35) — réserve, sur décision de Samuel.
- Fenêtre au-delà de 24 h, coût complet d'une phase hors fenêtre — Phase 52 (journal) et Phase 77 (synthèse).
- Empreinte en direct sur la carte Code, radar de collisions — Phase 75.
- Actions sur une session depuis la fiche (« Ouvrir dans le terminal », « Lui écrire », « Demander l'arrêt ») — Phase 81.
- Horodatage des transitions dans les DAG de mission (`dag.sh`) — non retenu : la relecture dérive l'état des nœuds des
  voies ; à rouvrir seulement si la relecture du statut exact d'un nœud est demandée.
</deferred>

---

*Phase: 74-equipe-dans-le-temps*
*Context gathered: 2026-11-11*
