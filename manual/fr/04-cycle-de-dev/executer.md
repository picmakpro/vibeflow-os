# Exécuter

<!-- vf-manual:lang -->
**Français** · [English](../../en/04-development-cycle/executing.md)
<!-- /vf-manual:lang -->

C'est la phase longue, et celle où tu peux partir faire autre chose. Le plan validé est déroulé
tâche par tâche : le code est écrit, les vérifications sont jouées, et chaque unité de travail est
commitée avant de passer à la suivante.

Cette page te dit ce qui se passe sans rien te demander, ce qui au contraire s'arrête pour te
demander, et comment lire ce qui défile — y compris deux comportements qui surprennent la première
fois qu'on les voit.

## Ce qui avance seul, ce qui s'arrête

**Ce qui avance seul** : écrire et modifier des fichiers prévus au plan, lancer les tests, les
lint, les vérifications de types, corriger ce qui échoue, et committer chaque tâche terminée.
Tout ça est dans le contrat que tu as validé en approuvant le plan — le redemander à chaque fois
n'apporterait rien.

**Ce qui s'arrête pour te demander** — et c'est la partie qui compte :

- **Une décision que le cadrage n'avait pas tranchée.** Le plan supposait quelque chose, la réalité
  du code dit autre chose. Plutôt que de choisir à ta place, l'exécution s'arrête et pose la
  question.
- **Une action destructive.** Une suppression massive, une réécriture d'historique, tout ce qui ne
  se défait pas. Ça demande ta confirmation explicite, toujours.
- **Un blocage qui ne se résout pas.** Après trois tentatives infructueuses sur le même point, la
  boucle abandonne au lieu d'essayer indéfiniment des variantes. Tu reçois l'état exact, pas un
  échec masqué.
- **Une dérive de périmètre.** Si l'exécution se retrouve à devoir toucher des fichiers hors du
  plan, elle s'arrête et te montre l'écart plutôt que de l'absorber.

Le point commun de ces quatre cas : ils transforment un dérapage silencieux en une question
explicite. C'est le même principe que celui décrit en
[gates-et-validation-humaine.md](../02-concepts/gates-et-validation-humaine.md).

## Deux comportements qui surprennent

Ces deux-là ne sont pas des bugs. Les connaître évite de croire que quelque chose ne va pas.

**La recherche de documentation avant de déboguer.** Quand un problème touche une bibliothèque, un
framework, une fonctionnalité native ou une histoire de version — ou simplement quand un premier
correctif a échoué — l'exécution **s'arrête de coder** et va d'abord chercher la documentation
officielle. Tu vas voir passer des recherches là où tu attendais des essais de code.

C'est délibéré. Le comportement par défaut d'un modèle face à un bug de bibliothèque est
d'essayer : changer un paramètre, inverser deux lignes, tenter une autre méthode. Ça marche parfois,
ça consomme énormément de temps quand ça ne marche pas, et surtout ça produit du code que personne
ne comprend, y compris quand il finit par fonctionner. Lire la documentation d'abord coûte deux
minutes et remplace vingt minutes de tâtonnement. Si la recherche ne donne rien, alors seulement le
débogage empirique commence.

**Le refus sur dépassement de taille.** Un fichier de code qui atteint trois cents lignes déclenche
un refus d'écriture. Pas un avertissement : un refus, appliqué par un garde-fou mécanique, pas par
la bonne volonté d'un agent.

La raison est spécifique à la façon dont on travaille ici. Un fichier trop long est difficile à
tenir en tête, pour toi comme pour un modèle : les modifications deviennent risquées, les effets de
bord invisibles. Le seuil force à découper avant que ça ne devienne ingérable. Quand tu le vois se
déclencher, l'exécution te proposera un découpage — c'est le moment de vérifier que la découpe a du
sens pour ton domaine, parce que c'est le genre de choix qui se prend mieux avec toi que sans toi.

## Lire ce qui défile, et gérer un échec

**Ce que tu vois.** Le fil affiche la tâche en cours, les fichiers touchés, le résultat des
vérifications, et le commit produit à la fin de chaque tâche. Tu n'as pas à tout lire en direct. Les
deux choses qui méritent ton œil sont les **questions** (elles attendent une réponse) et les
**commits** (ils te disent où en est le travail réel).

Si tu reprends après une absence, la question utile n'est pas « qu'est-ce qui s'est affiché » mais
« qu'est-ce qui a été commité ». L'historique du dépôt est le résumé le plus fiable de ce qui a
vraiment eu lieu.

**Quand une tâche échoue.** L'échec est rendu visible, jamais absorbé. Tu ne verras pas une tâche se
déclarer terminée avec un test désactivé ou un critère de réussite réécrit à la baisse — c'est un
interdit explicite, et c'est ce qui fait la différence entre une exécution en qui tu peux avoir
confiance et une qui te dit ce que tu veux entendre.

Concrètement, tu récupères le point exact d'échec, ce qui a été tenté, et l'état du dépôt. Les
tâches précédentes restent commitées : tu ne perds pas le travail réussi à cause d'une tâche qui ne
passe pas. Tu peux alors corriger le tir, demander une autre approche, ou reporter cette tâche et
continuer les suivantes si elles n'en dépendent pas.

Un dernier point sur l'interruption : tu peux couper une exécution à tout moment sans casser quoi
que ce soit. Les tâches déjà commitées restent commitées, et le plan sur le disque dit où on en
était. Reprendre plus tard ne redémarre pas au début — le travail fait est acquis.

Et une habitude qui vaut la peine : quand l'exécution te pose une question, réponds-y avec le même
soin qu'au cadrage. Une question qui surgit en cours d'exécution est une question que le plan
n'avait pas pu trancher — donc une vraie. Une réponse bâclée à ce moment-là produit exactement le
genre de résultat qu'on est ensuite tenté de reprocher à l'outil.

Ça vaut aussi pour les interruptions que tu déclenches toi-même : s'arrêter pour réfléchir ne coûte
rien, et c'est bien moins cher ici que de le découvrir trois tâches plus tard.

Rien n'est perdu quand tu mets en pause : les commits sont déjà là, et le plan sur le disque se
souvient du reste.

Une fois l'exécution terminée, il reste le temps le plus important pour toi :
[livrer et relire](./livrer-et-relire.md).

<!-- vf-manual:nav -->
[← Précédent](../04-cycle-de-dev/planifier.md) · [↑ Sommaire](../README.md) · [Suivant →](../04-cycle-de-dev/livrer-et-relire.md)
<!-- /vf-manual:nav -->
