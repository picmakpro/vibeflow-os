# Livrer et relire

<!-- vf-manual:lang -->
**Français** · [English](../../en/04-development-cycle/shipping-and-reviewing.md)
<!-- /vf-manual:lang -->

C'est le temps le plus négligé du cycle, et celui qui décide de la qualité réelle de ce que tu
gardes. L'exécution a produit du code ; il reste à le faire relire par une machine, puis par toi,
avant qu'il n'entre dans ta branche principale.

Cette page contient la liste de ce que **tu** dois regarder. C'est la partie la plus utile du
manuel pour quelqu'un qui délègue du développement : personne d'autre ne peut faire cette relecture
à ta place, et elle prend dix minutes.

## L'étage de revue

Après l'exécution, le travail produit passe en revue avant d'être considéré comme fini. Ce n'est
pas une option qu'on active : c'est un étage de premier rang du cycle, au même titre que le plan ou
l'exécution.

La revue est faite par un relecteur qui n'a pas écrit le code. Il lit le diff de l'étape et
rapporte ce qu'il trouve, classé par gravité : bugs, problèmes de sécurité, écarts de qualité,
incohérences avec les conventions du projet. Si des correctifs bloquants remontent, ils sont
appliqués et le diff repasse en revue. La boucle a un plafond : au bout de trois tours sans
convergence, elle s'arrête et te remonte l'état plutôt que de tourner indéfiniment.

Ce qui suit la revue, c'est l'hygiène documentaire : le suivi du projet est mis à jour (l'étape
passe à terminée), et la documentation touchée par le changement est révisée. Concrètement, si tu
as ajouté une commande, le fichier qui documente les commandes le sait. Tu n'as pas à y penser,
mais tu dois savoir que ça arrive — c'est pour ça que le diff d'une étape contient parfois des
fichiers de documentation que tu n'avais pas demandés.

Un mot sur git : une mission longue travaille sur **sa propre branche**, jamais directement sur ta
branche principale, et laisse sa demande de fusion ouverte plutôt que de fusionner elle-même. C'est
délibéré, et c'est ce qui rend possible la relecture décrite ci-dessous. Le détail du mécanisme —
branches, copies de travail isolées, ce qui se passe quand deux sessions travaillent en même temps
— est traité dans le thème suivant, consacré à l'équipe d'agents.

## Ce que tu relis avant de fusionner

Voici la liste. Elle est courte volontairement : une liste longue ne se fait pas.

- **Le diff, en entier, une fois.** Pas ligne par ligne — en diagonale, en cherchant ce qui te
  surprend. Un fichier auquel tu ne t'attendais pas, une suppression que tu n'avais pas demandée, un
  fichier de configuration modifié. La surprise est le signal, pas l'erreur de syntaxe.
- **Ce qui a été supprimé.** Les ajouts se relisent tout seuls, les suppressions non. Regarde
  spécifiquement les lignes retirées : c'est là que se cachent les régressions silencieuses et les
  cas particuliers qui avaient une raison d'être.
- **Les tests.** Deux questions. Est-ce qu'il y en a pour ce qui a été ajouté ? Et est-ce qu'un test
  existant a été modifié ou désactivé ? Un test affaibli pour faire passer une étape est la faute la
  plus coûteuse qui soit, parce qu'elle se paie plus tard, sur autre chose.
- **Les valeurs en dur et les secrets.** Une clé d'API, une URL de production, un identifiant, un
  chemin propre à une machine. Ça se repère en quelques secondes et ça évite des accidents.
- **Le comportement, pour de vrai.** Lance l'application et fais le geste concerné. Une étape peut
  être verte à tous les contrôles et ne pas faire ce que tu voulais — les contrôles vérifient ce
  qu'on leur a dit de vérifier, pas ton intention.
- **Les critères de réussite du plan.** Reprends-les un par un et coche. C'est le contrôle qui
  ferme la boucle avec le cadrage : tu vérifies que le résultat correspond à ce que tu avais
  demandé, pas seulement à ce qui a été planifié.
- **Le message des commits.** Un historique lisible est ce qui te sauvera dans six mois. Si un
  commit dit « fix », c'est le moment de demander mieux, pas dans six mois.

Si quelque chose cloche, dis-le en langage naturel — « le nom de cette fonction ne va pas », « il
manque le cas où la liste est vide ». La correction repart dans le cycle, elle ne se bricole pas à
la main dans un coin.

## Après la fusion

Deux gestes valent la peine, et aucun n'est obligatoire.

**Regarde ce qui a été différé.** Les idées mises de côté au cadrage sont toujours là. C'est le bon
moment pour décider si l'une d'elles devient l'étape suivante, ou si elle peut rester en attente.
Une idée différée qui n'est jamais relue redevient une idée perdue.

**Demande où tu en es.** « On en est où ? » te rend l'état du projet : ce qui est fait, ce qui
reste, ce qui est bloqué. C'est plus fiable que ton souvenir, et ça coûte une phrase.

### Combien de temps y consacrer, honnêtement

La tentation est de sauter cette relecture quand tout est vert. C'est compréhensible et c'est une
mauvaise affaire : le vert dit que les contrôles passent, pas que le résultat est bon. Un test vérifie
ce qu'on lui a demandé de vérifier ; il ne sait rien de ton intention.

Une règle de pouce utile : consacre à la relecture **à peu près le temps qu'il te faudrait pour
refaire le travail à la main si tu découvrais un problème dans un mois**, divisé par dix. Pour une
petite étape, c'est cinq minutes. Pour un changement qui touche des données ou de l'argent, c'est
une demi-heure, et elle est très bien investie.

Et si tu n'as vraiment que deux minutes, fais deux choses seulement : regarde **ce qui a été
supprimé**, et lance l'application pour faire **le geste concerné**. Ces deux contrôles attrapent la
majorité de ce qui compte, et ils tiennent dans le
temps d'un café.

Le reste de la liste vaut la peine dès que le changement est plus gros, touche de l'argent ou des
données, ou part vers des gens qui ne sont pas toi. Cale la relecture sur l'ampleur de l'impact, pas
sur le nombre de lignes changées — une modification de trois lignes dans une règle de tarification
mérite plus de ton attention que trois cents lignes de nouveaux tests.

Et si tu ne veux pas mener ce cycle étape par étape, il existe un mode pour le déléguer en entier :
[mode-autonome.md](./mode-autonome.md). Il ne supprime aucun des points de contrôle ci-dessus — il
les regroupe.

<!-- vf-manual:nav -->
[← Précédent](../04-cycle-de-dev/executer.md) · [↑ Sommaire](../README.md) · [Suivant →](../04-cycle-de-dev/mode-autonome.md)
<!-- /vf-manual:nav -->
