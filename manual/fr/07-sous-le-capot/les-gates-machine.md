# Les gates machine

<!-- vf-manual:lang -->
**Français** · [English](../../en/07-under-the-hood/the-machine-gates.md)
<!-- /vf-manual:lang -->

[gates-et-validation-humaine.md](../02-concepts/gates-et-validation-humaine.md) t'a expliqué
**pourquoi** VibeFlow préfère un script qui refuse à un paragraphe qui recommande. Cette page-ci ne
reprend pas ce pourquoi — elle répond à la question suivante, plus concrète : **quels gates
tournent réellement**, sur quoi, à quel moment, et que se passe-t-il quand l'un d'eux se déclenche.

## L'inventaire

Chaque module qui pose un gate le fait au moment où tu l'installes — jamais avant. Un lab minimal,
qui n'installe que le socle de gouvernance, hérite d'une poignée de ces gates ; un lab complet, avec
la plupart des modules, les cumule tous. Voici les familles de gates réellement livrées, avec ce
qu'elles vérifient, quand elles s'exécutent, et l'effet d'un échec.

| Gate | Ce qu'il vérifie | Quand | Si ça échoue |
|---|---|---|---|
| Conformité des agents | Un agent écrit sous `agents/` porte un frontmatter valide (nom, description, modèle, portée de mémoire) et ne déclare que des skills qui existent réellement | À l'écriture d'un agent (bloquant) + rappel au démarrage de session (avertissement) | L'écriture est refusée avec le détail précis du champ manquant ou invalide |
| Iron Law des 300 lignes | Un fichier de code édité ou créé ne dépasse pas le seuil de blocage sans porte d'échappement tracée | À chaque édition ou création d'un fichier de code | L'écriture est refusée ; une marque explicite dans les cinq premières lignes du fichier permet de tracer une dette assumée plutôt que de contourner le gate |
| Garde-fou du planning | Le suivi d'un compartiment de travail a été mis à jour avant la fin de la session | En fin de session | La session ne se termine pas tant que le suivi n'est pas à jour |
| Revendication de branche | La branche courante n'est pas déjà pilotée par une mission depuis un autre arbre de travail | Au démarrage de session | Un avertissement s'affiche ; rien n'est bloqué, la décision de continuer reste la tienne |
| Lecture et écriture des registres de mémoire | Un accès à un registre de mémoire respecte le protocole d'indexation attendu | Avant toute lecture ou modification d'un registre | L'accès est refusé si le protocole n'est pas respecté |
| Fraîcheur de la doctrine | Un document de cadrage ou de règle a dérivé de sa source sans mise à jour correspondante | Au démarrage de session, périodiquement | Un avertissement s'affiche, rien n'est modifié à ta place |
| Audit d'infrastructure | L'état réel de tes hooks, scripts et outillage n'a pas dérivé silencieusement d'une mise à jour | Au démarrage de session, si le dernier contrôle date de plus de deux semaines | Un avertissement s'affiche avec le détail de la dérive détectée |
| Recherche documentaire avant debug | Un debug intensif sur une bibliothèque, un framework ou un comportement natif est précédé d'une recherche documentaire | Au démarrage de session, en rappel | Un avertissement s'affiche, rien n'empêche de continuer sans avoir cherché |

Deux mécanismes complètent ce tableau sans en être des lignes à part entière. Le **verrou de
pilotage** empêche deux managers de mission de piloter la même étape en même temps : celui qui
arrive en second attend que le premier relâche le verrou, ou récupère un verrou abandonné après un
délai d'inactivité fixé par défaut à trente minutes. Et **le juge n'écrit jamais** : un agent qui
évalue un livrable (relecture, audit, gate qualité) reçoit un accès en lecture seule au code qu'il
juge — un garde-fou posé au niveau des outils qu'on lui donne, pas d'une règle qu'il pourrait
enfreindre sous pression.

### Le principe du fail-open

Un détail qui vaut la peine d'être su : un gate bloquant qui rencontre une erreur interne (un
interpréteur absent, une entrée illisible) **n'échoue jamais côté blocage** — il laisse passer,
silencieusement, plutôt que de figer ta session sur un problème qui n'a rien à voir avec ce qu'il
vérifie. Seul un **refus explicite**, avec un message qui dit précisément ce qui ne va pas, bloque
réellement une action. Un garde-fou cassé ne devient jamais un mur : au pire, il redevient
temporairement silencieux, jusqu'à ce que la cause de la panne soit corrigée. C'est un choix
délibéré, pas une faille — un gate n'a pas vocation à ajouter une nouvelle façon de te bloquer.

## Les contraintes de taille, visibles

Deux bornes de taille se voient concrètement, et méritent d'être nommées parce que c'est ce qui
explique un refus que tu pourrais prendre pour un caprice :

- **Le budget de préchargement des skills.** Quand un agent déclare un skill à précharger
  intégralement à son démarrage (plutôt qu'à charger à la demande), la taille cumulée de ces
  skills est mesurée et plafonnée — au-delà, l'écriture de l'agent est refusée. C'est la charte de
  densité rendue concrète : un agent qui charge trop de contenu au démarrage coûte cher à chaque
  invocation, pour un gain souvent nul.
- **Le seuil des 300 lignes de code**, déjà couvert dans le tableau ci-dessus, avec son
  avertissement à 250 lignes avant le blocage ferme.

**À ne pas surpromettre :** la charte qui recommande de garder un agent lui-même sous 250 lignes
n'est aujourd'hui **pas** vérifiée automatiquement par un gate posé par défaut dans ton lab — c'est
une doctrine documentée, appliquée par vigilance humaine et par revue, pas par un script bloquant.
Un gabarit existe dans la bibliothèque méthodologique pour qui veut se doter de ce contrôle
lui-même ; il n'est pas installé par défaut. Le dire clairement ici évite de te faire croire à une
garantie qui n'existe pas encore par défaut.

### Un exemple concret : le refus de l'Iron Law

Concrètement, voici ce que tu verrais si tu tentais d'écrire un fichier de code de 320 lignes sans
rien d'autre : l'écriture est refusée, avec le compte exact de lignes et le seuil dépassé. Deux
issues honnêtes s'offrent à toi — découper le fichier en plusieurs modules plus petits (la voie
recommandée), ou reconnaître explicitement la dette en ajoutant la marque d'échappatoire dans les
premières lignes du fichier, ce qui laisse le gate passer en avertissement plutôt qu'en blocage. Le
gate ne devine jamais laquelle des deux issues est la bonne pour ton cas — il force seulement le
choix à être **explicite**, jamais silencieux.

## Ce qui n'est pas contraignant

Tous les scripts de cette famille ne bloquent pas. Un détecteur de recouvrement entre une capacité
VibeFlow et une brique tierce déjà présente dans ta session (deux façons de faire une revue de code,
par exemple) **constate et affiche**, il ne refuse jamais une action — VibeFlow ne revendique jamais
l'exclusivité contre un outil qu'il ne contrôle pas. Ce script n'est d'ailleurs déclenché par aucun
comportement automatique de session par défaut : il s'invoque à la main, ou depuis une vérification
d'intégrité plus large, jamais au démarrage. C'est un choix assumé, pas un oubli : entre bloquer une
session à cause d'un outil qu'il ne contrôle pas et se contenter d'informer, VibeFlow choisit
d'informer.

Le même principe explique pourquoi certains gates existent en deux versions — l'une posée
automatiquement à un moment du cycle, l'autre invocable à la main pour un contrôle plus large. La
vérification de taille de fichier, par exemple, se déclenche à chaque édition en mode bloquant, mais
existe aussi comme commande autonome que tu peux lancer sur l'ensemble d'un projet avant un commit —
même seuil, même logique, deux points d'entrée pour deux usages différents.

Retiens la règle générale pour lire tout gate que tu croises : s'il **écrit un refus avec un code
d'erreur**, c'est bloquant — corrige et retente. S'il **affiche une ligne au démarrage**, c'est un
constat — à toi de décider d'agir ou non. La distinction n'est jamais ambiguë une fois que tu sais
la chercher.

Si un gate te semble se comporter différemment de ce que cette page décrit, la source de vérité
n'est jamais cette page : c'est le script lui-même, posé sous ton dossier de scripts après
installation, lisible en clair. Cette page en donne la carte, pas le détail d'implémentation — la
doctrine complète, avec le raisonnement derrière chaque gate, vit dans la bibliothèque
méthodologique couverte par la page suivante de ce thème. Un tableau, aussi soigné soit-il, reste
une carte — pas le territoire.

C'est aussi pourquoi cette page ne prétend jamais être exhaustive jusqu'au moindre drapeau : ce qui
compte pour qui découvre VibeFlow, c'est la forme du système — quels gates bloquent, lesquels se
contentent de constater, et pourquoi la frontière entre les deux est tracée là où elle l'est. En cas
de doute sur un gate précis que tu rencontres, lis le script — cette page sera toujours là à ton
retour, et elle n'aura pas dérivé de ce qui tourne réellement sur ta machine. C'est tout l'intérêt de
te renvoyer vers la source plutôt que vers un résumé qui pourrait devenir périmé — un résumé que tu
es justement en train de lire, et que cette page s'efforce de ne jamais être, en nommant toujours où
vit la vraie réponse.

<!-- vf-manual:nav -->
[← Précédent](../07-sous-le-capot/l-engine-d-install.md) · [↑ Sommaire](../README.md) · [Suivant →](../07-sous-le-capot/la-doctrine-et-ses-patterns.md)
<!-- /vf-manual:nav -->
