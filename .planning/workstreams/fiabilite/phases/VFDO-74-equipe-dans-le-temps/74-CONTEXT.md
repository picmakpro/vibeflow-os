# Phase 74: L'équipe dans le temps — swim-lanes, coût, replay - Context

**Gathered:** 2026-11-11
**Status:** Cadrée (2026-11-11), premier temps — frontière de questions vide ; planification au second temps, après les
contrats de la Phase 79

Cadrage par le manager de la mission Phase 74 (`vf-dev-manager`, worktree `.claude/worktrees/phase-74`, branche
`feat/phase-74-equipe-dans-le-temps`, base `origin/integration/cockpit-audit` = `f763b556`). Jalon `vibeflow-v2.0`,
compartiment `fiabilite`. Cadrée en même temps que les Phases 73, 75, 76, 77, 79 et 80, dans la vague lancée par Samuel le
2026-11-11 (session principale Claude Code : « lancer en parallèle les cadrages et plans de toutes les phases »).

**Sources :** but arbitré le 2026-11-03 (bloc Phase 74 du ROADMAP) ; note `.planning/notes/2026-11-03-cockpit-idees-recherche.md`
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

**Dépend de :** Phase 79 (index des transcripts sur disque, segments et compteurs par agent, route de frise, extension du
contrat de forme) ; Phase 73 (régie de l'onglet Équipe : point d'ouverture de la fiche, place de la bascule) ; Phase 69
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
  (AUDC-V6) : une note de lecture y renvoie à cette décision. Remonté à Samuel (section « À Samuel », point 1).
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
  Les **commits** sont posés sur un bandeau « Dépôt » en tête de frise, par branche, jamais attribués à une voie d'agent :
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
- **P74-D-11 (direct).** La frise suit le flux partagé de la Phase 79 (un événement sans contenu, puis une lecture
  authentifiée de la route de frise) ; le trait « maintenant » avance ; aucune donnée de frise ne passe dans le flux.

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
  jetons et verbes (AUDC-Q2). Si la Phase 79 persiste les cibles des écritures pour la Phase 75, la 74 peut les lire, sans
  l'exiger.

### Fiche d'agent et lecteur

- **P74-D-15 (faits).** Rattachement (« Worker de <parent> · nœud <id> · Phase <n> », chaque terme ouvre sa cible : fiche
  du parent, carte de mission, phase — les trois graphes reliés, AUDC-I21) ; nom, nœud, arbre, modèle ; puis : durée au
  travail dont temps à attendre l'humain ; contexte au dernier tour (en jetons) et nombre de compactions ; appels d'outil
  dont erreurs ; jetons (entrée, sortie, cache lu, cache écrit) ; fichiers écrits et lus (comptes). Une donnée que la
  source ne donne pas s'écrit « inconnu », jamais un zéro (même règle que la Phase 52 : « jamais estimé »).
- **P74-D-16 (part du contexte).** En pourcentage seulement si la taille de la fenêtre de contexte vient d'une source
  documentée ; sinon en jetons. Le pourcentage tiré d'une fenêtre supposée est heuristique (A1 § 3) : il n'est pas affiché.
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
  phase) ; par étage (tête = session, manager, worker, d'après le rôle et la profondeur). Les agents non rattachés forment
  une ligne « hors mission », comptée à part, jamais répartie. Chaque agrégat porte sa fenêtre (« sur les dernières 6 h ») :
  un coût de phase sur 24 h n'est jamais présenté comme le coût de la phase.
- **P74-D-22 (le calcul partagé avec la Phase 52).** Un seul calcul : **la somme des jetons de `message.usage`,
  dédoublonnée par identifiant de message (2 à 8 lignes par message, A1 § 3), par transcript, posée dans l'index de la
  Phase 79**. La 74 l'agrège, elle ne recompte jamais les transcripts. La Phase 52 réutilise cette fonction (ou lit
  l'index quand le cockpit est installé) au lieu d'en écrire une seconde : consigné pour son cadrage (« À verser par la
  jointure » du rapport).
- **P74-D-23 (temps perdu à attendre l'humain).** Somme des segments « vous attend » d'un agent ou d'une fenêtre, tirés
  de l'état officiel (« bloquée », AUDC-Q4) et, en repli et pour l'historique, d'une question ou d'une permission sans
  réponse dans le transcript (déduction, dite comme telle dans la fiche).
- **P74-D-24 (limites d'abonnement).** Les limites de 5 h et de 7 jours ne sont pas dans la 74 : publiées pour la session
  principale seulement, pour trois abonnements, via la ligne d'état (A6 § 3), elles demandent un relais par le script de
  ligne d'état, hors de ce que lit le socle. Elles restent avec le plafond de coût (réserve, AUDC-I35). Signalé à Samuel
  (point 3).

### Données, contrat, bornes

- **P74-D-25 (lecture par le socle seul).** La 74 ne lit aucun transcript elle-même : elle consomme la route de frise et
  l'index de la Phase 79, la route d'état, et la route de transcript existante (`/api/vf/transcript`). Toute clé lue est
  déclarée au contrat de forme (`vf-cockpit-interface.json`) ; l'extension pour `usage`, `compact_boundary`, `is_error`,
  les horodatages et l'appariement `tool_use` ↔ `tool_result` appartient à la 79 (qui écrit l'index) ; la 74 vérifie
  que chaque champ affiché y figure.
- **P74-D-26 (durées par segments, AUDC-D9).** La durée affichée d'un agent est la somme de ses segments au travail
  (et non `dureeS`, qui compte les veilles d'un agent réveillé, jusqu'à 101 h). Le retrait de `dureeS` des consommateurs
  de la 74 suit la politique de version des schémas ; si `vf-signal` le lit encore, il est gardé côté émetteur et retiré
  par la 79 (à régler entre les deux phases).
- **P74-D-27 (bornes d'émission).** Routes en GET seul, derrière Host, Origin et jeton ; clés `doing`, `mandat`,
  `messages`, `outils`, `fil` refusées dans le flux ; l'export ne contient ni frise, ni fiche, ni fil ; aucune lecture
  réseau ; la dernière commande n'apparaît nulle part. La chaîne XSS des suites est étendue aux données de la frise et de
  la fiche (nom d'agent, nœud, titre, message hostiles).

### Un ajout, un retrait

- **P74-D-28 (retraits de la 74).** (1) La boîte de transcript du panneau (320 px, défilement imbriqué) et son bouton
  « Lire le transcript » : remplacés par la fiche plein cadre. (2) La durée unique d'un agent qui compte ses veilles :
  remplacée par la durée par segments. (3) Partagé avec la 73 (registre § 3) : la carte « Terminés depuis moins de 24 h ».
  La 73 la retire avec le canevas de l'onglet ; la 74 en porte la compensation pour l'historique (la frise sur 24 h,
  P69-D-18 tenue). Si la 73 ne la retire pas, la 74 le fait.

### Claude's Discretion

Laissés à la spécification d'interface et à la planification, dans les bornes ci-dessus : la géométrie de la frise
(hauteur de voie, graduations, densité des étiquettes), la forme exacte de l'encart « À cet instant », le seuil de repli des
voies (P74-D-10), le mécanisme de mise en évidence sur la carte Code (P74-D-12), la pagination du fil au-delà du plafond.
</decisions>

<specifics>
## À Samuel

Trois points, aucun ne bloque la planification ; l'arbitrage en vigueur tient et le plan est bâti dessus.

1. **« Colorée par nœud de DAG »** (but de la Phase 74, ton arbitrage du 2026-11-03) contredit `DESIGN.md` § 9 et Q9.
   La frise est bâtie sur `DESIGN.md` : le nœud s'écrit sur la voie, la couleur reste aux trois états (P74-D-01). Options :
   (a) garder `DESIGN.md` (recommandé : une couleur par nœud demanderait une palette libre que Graphite interdit, et
   la couleur cesserait de dire l'état) ; (b) colorer par nœud, en rouvrant Q9. À voir à la recette.
2. **Pas de montant en devise** (P74-D-20) : le coût se lit en jetons et en durée, comme le dit le but. DESIGNS § 5
   proposait un « coût estimé au tarif public ». Recommandé : ne pas l'ajouter (table de tarifs à tenir, estimation que la
   Phase 52 refuse). Si tu le veux, il entre dans une phase ultérieure, pas dans la 74.
3. **Limites de 5 h et de 7 jours hors de la 74** (P74-D-24), alors que AUDC-I07 les plaçait ici. Recommandé : en réserve
   avec le plafond de coût (AUDC-I35), parce qu'elles ne concernent que la session principale et demandent un relais par
   la ligne d'état.
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
