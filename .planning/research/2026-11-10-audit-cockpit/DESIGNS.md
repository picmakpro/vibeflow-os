# Les formes imaginées par l'audit du cockpit (2026-11-10)

> Annexe de `.planning/research/2026-11-10-audit-cockpit-etude.md`. Ce fichier décrit en texte les maquettes de
> l'audit, pour qu'un cadrage, un `vf-crafter` ou un juge puisse les citer sans ouvrir la page. Les maquettes
> elles-mêmes sont dans `page/audit-cockpit.html` (sections « L'onglet Équipe, repensé » et « Interface et design »),
> à ouvrir dans un navigateur. Ce sont des **propositions** : aucune n'est arbitrée, et `DESIGN.md` (direction
> « Graphite ») reste la référence.

## 1. La décision de design : trois onglets, trois formes

Le défaut de fond relevé par le parcours est d'appliquer le canevas à cartes à tout. Chaque onglet répond à une
question différente et mérite la forme qui y répond.

| Onglet | Question | Forme | Ce qui change |
|---|---|---|---|
| Code | Où est quoi, et qu'est-ce qui dépend de quoi ? | Une carte : le graphe zoomable est la bonne forme. | Il lui manque une minicarte et un vrai « tout voir ». |
| Projet | Où en est-on ? | Des couloirs : les phases rangées par état. | Le graphe de dépendances reste accessible, à la demande. |
| Équipe | Qui m'attend, qui travaille, que s'est-il passé ? | Une régie (liste par état), puis une frise (le temps). | Le canevas disparaît de cet onglet. |

Les meilleures surfaces actuelles sont déjà les moins « graphe » : le tiroir Git, le terminal, le bandeau de
lancement, la recherche.

## 2. Quatre principes pour l'onglet Équipe

1. **Lire l'état au lieu de le deviner.** Claude Code publie la liste des sessions vivantes et leur état
   (`claude agents --json`, mesuré : 0,14 s, états occupée, au repos, bloquée).
2. **L'attention d'abord.** La première chose à l'écran est la liste de ceux qui attendent l'humain. Presque tous
   les outils examinés ouvrent sur ce motif ; aucun ne classe cette file par ce qu'elle retient en aval.
3. **Une liste et une frise à la place du canevas.** Pour deux à dix agents, une liste hiérarchique se lit d'un
   regard et une frise raconte la journée.
4. **Trois graphes reliés.** Qui a lancé qui, quel nœud du plan chacun porte, quelle phase avance.

### Vocabulaire des états

Chaque état garde un glyphe de forme distincte et un mot, sans fond teinté (DESIGN § 9, arbitrage Q9). Les teintes
restent les trois de Graphite : vert, jaune, corail, portées par le glyphe ou un trait.

| État | Glyphe (symbole de la page) | Teinte | Preuve qui le fonde |
|---|---|---|---|
| Au travail | anneau à demi plein (`g-active`) | jaune | écriture récente, ou appel d'outil sans résultat |
| Commande longue | le même, avec « commande en cours depuis N » | jaune | appel d'outil sans résultat ; le seuil existant de « commande longue » est de 15 min, à régler au cadrage |
| Silencieux, puis suspect | anneau en pointillé (`g-silent`) | neutre, puis corail | aucun signe de vie, session vivante ; l'état décroît avec le temps |
| Vous attend | anneau avec deux barres de pause (`g-pause`) | jaune | état officiel « bloquée », ou question ou permission sans réponse |
| Attend ses agents | anneau à demi plein, ligne fine sur la frise | jaune | fin de tour avec des agents de fond en cours |
| Au repos | anneau vide (`g-todo`) | neutre | session vivante, au repos |
| Terminé, à relire | coche (`g-done`) | vert | agent fini, rapport rendu, pas encore ouvert |
| Orphelin | anneau barré (`g-block`) | corail | parent terminé, enfant vivant |
| À recetter (Projet) | anneau avec point central (`g-wait`) | jaune | état dérivé existant de la Phase 69 |

« Vous attend » a son propre glyphe : il ne doit pas réutiliser l'anneau à point de « À recetter ». Les lignes
« Silencieux, puis suspect » et « Orphelin » sont proposées au versement : leurs symboles sont définis dans la page,
mais aucune maquette ne les montre ; glyphe, teinte et seuils restent à arbitrer (le seuil existant de « sans
nouvelle » est de 2 min).

## 3. Maquette 1 : la régie

Une liste en quatre sections, dans cet ordre. L'en-tête de l'onglet dit le compte : « 6 agents · 2 vous attendent ».

| Section | Contenu | Règle |
|---|---|---|
| À vous | Les agents et sessions qui attendent une réponse ou une permission. | Classée par ce que chaque attente retient dans le plan : « retient toute la mission · 4 nœuds en aval » passe avant « retient 1 nœud ». Action à droite : « Répondre », « Ouvrir ». |
| Au travail | L'arbre session, manager, workers, indenté. | Une ligne par agent ; l'enfant sous son parent ; un agent en attente y figure aussi, à sa place dans l'arbre. |
| Terminé, à relire | Les agents finis dont le rapport n'a pas été ouvert. | Remplace la carte « Terminés depuis moins de 24 h ». Action : « Lire le rapport ». |
| Au repos | Les sessions vivantes sans activité, autres arbres compris. | Elles restent listées (aujourd'hui elles disparaissent après 3 minutes). |

Une ligne porte, de gauche à droite : le glyphe d'état ; qui (nom en gras, puis rôle, nœud du plan, arbre ou modèle
sur une seconde ligne discrète) ; quoi (l'état en mots, puis un détail : « lance les tests · commande en cours depuis
7 min ») ; la durée ; le contexte (barre fine et pourcentage ; la barre se teinte quand le contexte est presque plein, 86 % dans
la maquette, seuil à fixer au cadrage) ou l'action. Sur une ligne, le nom d'un agent n'est écrit qu'une fois
(aujourd'hui trois : titre, description, panneau) ; un agent qui attend figure dans « À vous » et à sa place dans l'arbre.

Ce que la régie corrige : le worker qui lance des tests depuis sept minutes reste à l'écran ; la session au repos
reste listée ; le manager porte son nœud de plan ; l'attente est un état à part entière.

## 4. Maquette 2 : la frise des sessions

Une voie par agent, les enfants sous leur parent, une horloge commune à tout le dépôt.

- **Colonne de gauche** : nom de l'agent, nœud du plan ou arbre en seconde ligne, filets qui relient parent et enfants.
- **Bandeau haut** : la courbe du nombre d'agents actifs (« jusqu'à 4 en même temps »).
- **Segments d'une voie** : barre pleine arrondie = au travail ; trait fin = attend ses agents ; barre hachurée à
  contour jaune = vous attend ; pointillé = au repos.
- **Événements posés sur la voie** : losange vert = commit ; triangle vide = compaction ; croix corail = erreur
  d'outil ; point = message de l'humain ; coche = rapport rendu. Un trait vertical relie le parent à l'enfant à
  l'instant du dispatch.
- **Axe** : graduations régulières, trait « maintenant » à droite.
- **Deux lectures du même axe** : *Horloge* (les durées sont vraies) et *Événements* (les silences sont compressés,
  sinon une minute dense devient un trait et une nuit creuse un désert).
- **Fenêtres** : 1 h 30, 6 h, 24 h, 7 j. La dernière dépasse la fenêtre de 24 h de la Phase 69 (P69-D-18) ; conserver
  l'index sur disque est une décision à part (AUDC-Q2).
- **Gestes** : un clic sur une voie ouvre la fiche de l'agent ; un clic sur un commit ouvre le tiroir Git.

Ce que la frise répond : qui a tourné en parallèle, qui a attendu quoi, combien de temps d'agent a été perdu à
attendre l'humain, quand les commits sont tombés.

Trois précisions pour le cadrage de la Phase 74, qui prévoit déjà cette frise :
1. Sa note donne `meta.json` comme source des horodatages ; il n'en porte aucun, ils sont dans les transcripts.
2. « Colorée par nœud de DAG » contredit Graphite : le nœud s'écrit sur la voie, la couleur reste aux états.
3. Une frise au-delà de 24 heures rouvre la fenêtre décidée en Phase 69 (P69-D-18).

## 5. Maquette 3 : la fiche d'un agent

Deux colonnes.

- **À gauche, les faits** : rattachement (« Worker de vf-dev-manager · Phase 73 »), nom, nœud, arbre, modèle ; puis
  six chiffres : durée au travail dont temps à attendre l'humain ; part du contexte et nombre de compactions ;
  appels d'outil dont erreurs ; jetons produits ; coût estimé au tarif public ; fichiers écrits et lus.
- **Actions** (si AUDC-Q3) : « Ouvrir dans le terminal », « Lui écrire », « Demander l'arrêt », « Voir ses fichiers
  sur la carte ». Chaque action prépare une commande dans le terminal ; rien ne part sans la touche Entrée.
- **À droite, le fil** : une seule liste datée, du mandat à maintenant. Chaque ligne : heure, glyphe, verbe et cible
  réduite (« modifie `vf-cockpit-equipe.mjs` », « lance les tests · échec après 2 min », « commit `a1b2c3d` »,
  « compaction · 168 k puis 41 k jetons »). Jamais une sortie d'outil, jamais l'argument d'une commande (P69-D-16,
  P69-D-19). Le mandat se lit à la demande.

Aujourd'hui la fiche d'une session tient en quatre lignes, l'intertitre « Mandat » est toujours vide pour une
session, et messages et outils sont dans deux listes sans heure.

## 6. Maquette 4 : Projet en couloirs

- **En-tête du jalon** : nom, « 5 phases faites sur 12, 1 à recetter », barre d'avancement et pourcentage strict.
- **Colonnes par état** : À faire, En cours, À recetter, Fait (les quatre états dérivés de la Phase 69), chacune
  avec son glyphe, son mot et son compte. La maquette en montre trois : aucune phase n'était en cours ce jour-là.
- **Carte de phase** : numéro en police à chasse fixe, titre, une ligne d'état (« 16 plans sur 16 · 11 exigences
  sur 12 », « pas de plan · non cadrée »).
- **Téléphone** : les colonnes s'empilent ; aucune échelle de zoom.
- **Le graphe** de dépendances reste accessible par une bascule, à la demande.

Elle corrige AUDC-BL1 sans toucher au plancher de zoom (PU-G-026).

## 7. Les autres formes proposées

| Forme | Description | Registre |
|---|---|---|
| Palette de commandes | Un champ, ouvert au clavier : fichiers, phases, agents et actions. Le clavier atteint tout avant même que le canevas soit corrigé. | AUDC-I24 |
| Minicarte et repères de bord | Une vignette de la carte entière, et aux bords « 16 cartes par là ». | AUDC-I26 |
| Mode focus | Sélectionner une carte recompose son seul voisinage, à taille lisible. | AUDC-I27 |
| Liste ou tableau | Une bascule à chaque niveau (touche `v`), triable, par défaut au téléphone. | AUDC-I25 |
| Lecteur de transcript | Plein cadre, fil daté, filtres messages, outils, erreurs, suivi en direct. | AUDC-I28 |
| Barre d'état en pied | Branche entière, état du direct, shell vivant avec « Terminer », heure de la dernière mise à jour. | AUDC-I29 |
| Notifications | Titre d'onglet « (2) vous attendent », pastille sur l'icône, notification du système en option ; trois motifs seulement. | AUDC-I09 |
| En-tête | Trois groupes d'icônes libellés au-delà de 1 280 px ; fil d'Ariane avec chevron ; branche entière. | AUDC-M5 |

## 8. Critique de la direction artistique (parcours du 2026-11-10)

- **Ce qui a du caractère** : le graphite sombre ; les glyphes d'état (le couple forme et mot est la signature la
  plus solide) ; le tiroir Git en lecture seule, où chaque action est une commande à copier ; le lancement en deux temps.
- **Ce qui fait générique** : la grille de cartes sur fond pointé, pour tout.
- **Hiérarchie** : le même titre apparaît trois fois (fil d'Ariane, grand titre flottant, panneau), la description
  deux. Les paliers de zoom grossissent la légende et la pastille, pas le titre.
- **Densité** : deux extrêmes, un canevas vide à 70 ou 95 % et un panneau en murs de prose recopiée du ROADMAP. Les
  écarts de 130 px entre cartes font la largeur, donc l'échelle.
- **Typographie** : Inter et JetBrains Mono bien tenus, deux graisses. La troncature coupe la partie qui distingue
  (« 72-04 — Poser le… »).
- **Couleur** : en sombre tout tient (6 à 15 de contraste). En clair, la carte active devient grise et se lit comme
  désactivée ; le glyphe « En cours » est à 3,01. Les seules couleurs libres sont héritées du moteur : liens violets,
  barre de langages arc-en-ciel.
- **Icônes** : trois faux amis, un fichier pour les sessions et les agents, un triangle de lecture pour « Parcours »,
  une roue pour « récent ».
- **Mouvement** : le fondu de plongée et la caméra de la visite ont de la tenue ; le gel de 2,3 s et le zoom qui perd
  la carte sélectionnée les défont. En mouvement réduit, 23 animations restent actives.
- **Cohérence entre onglets** : jeu d'icônes variable (neuf ou sept), santé contradictoire, « Demander » et terminal
  absents d'Équipe.

## 9. Bornes à respecter

Arbitrages de Samuel qui encadrent toute mise en œuvre (sources : A7). « Q4 » à « Q14 » sans préfixe y désignent ses
réponses du 2026-11-06, pas les décisions `AUDC-Q…` ouvertes par l'audit.

- Ni couleur d'alerte, ni pastille orange, ni fond teinté : glyphe et mot neutre (Q9, DESIGN § 9). Palettes A2 et B2
  rejetées, « pastel lumineux » retenu, « le halo ne revient pas », plus d'anneau coloré, barres neutres sauf en cours
  (P71.5-D-12, D-19, D-21, D-27, D-28).
- Grille d'espacements fermée : « ni 10, ni 14, ni 22 » (P71.5-D-01).
- Points de rupture inchangés (Q11) ; le tiroir ne pousse jamais la carte (Q12) ; « Flou gardé, texte court » sous le titre (Q10).
- Le bouton n'exécute jamais (Q4) ; une proposition ne prend jamais le focus (Q5) ; pas de repli « copier la commande »
  pour un lancement (Q14).
- Transcript sans sortie d'outil, jamais exporté (P69-D-19) ; verbe et cible réduite, jamais un argument (P69-D-16).
- Titre par `custom-title` seul, jamais de titre généré (PU-G-162).
- Aucune lecture réseau (P67-D-02) ; lecture seule sur `.planning/`.
- Pas de quatrième onglet (P78-D-04) ; pas de terminal sur l'onglet Équipe (Q8), sauf décision AUDC-Q3.
