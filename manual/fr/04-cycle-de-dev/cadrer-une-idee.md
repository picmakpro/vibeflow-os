# Cadrer une idée

<!-- vf-manual:lang -->
**Français** · [English](../../en/04-development-cycle/framing-an-idea.md)
<!-- /vf-manual:lang -->

Le cadrage est le premier temps du cycle, et le plus souvent sauté. C'est une erreur qui se paie
comptant : une idée mal cadrée produit un plan qui a l'air correct, une exécution qui se déroule
sans erreur, et un résultat qui n'est pas ce que tu voulais. À ce stade, le travail est fait — le
refaire coûte cent fois ce qu'aurait coûté la conversation.

Le cadrage sert à une chose : transformer « je veux X » en un périmètre que quelqu'un d'autre
pourrait exécuter sans te redemander. Y compris toi-même dans trois semaines.

## Comment ça se passe

Tu ouvres le sujet en langage naturel — « je veux ajouter un export CSV », « le formulaire
d'inscription est trop long, il faut le repenser ». Le lab ne se met pas à écrire du code. Il te
pose des questions, et c'est le moment de répondre sérieusement.

Les questions ne sont pas génériques : elles portent sur ce que ton projet a d'ambigu. Le lab lit
ton code et ton suivi avant de demander, donc il ne te demandera pas ce qu'il peut déduire. Ce
qu'il te demande, c'est ce que **seul toi** peux trancher : un arbitrage entre deux comportements
acceptables, une contrainte que rien dans le code ne révèle, une priorité.

Trois choses ressortent de l'échange, et il vaut la peine de les distinguer :

**Une décision verrouillée** est un choix que tu as fait explicitement. Il est écrit, avec sa
raison. Il ne sera pas rediscuté à l'exécution, et si quelque chose plus tard le contredit, ce sera
signalé comme une contradiction, pas absorbé en silence.

**Une idée différée** est une idée qui est apparue pendant la conversation, qui est bonne, et qui
n'est **pas** dans cette étape. Elle est écrite aussi, dans une liste à part. C'est le mécanisme qui
protège du glissement de périmètre : une idée différée n'est pas une idée perdue, donc tu n'as
aucune raison de la faire rentrer de force maintenant « pendant qu'on y est ».

**Une hypothèse** est ce que le lab a supposé faute de réponse, écrit noir sur blanc pour que tu
puisses la contredire. Si une hypothèse te saute aux yeux comme fausse à la relecture, c'est le
cadrage qui a fait son travail.

Tout cela atterrit dans un fichier de contexte, sous le dossier de suivi du projet, à côté de
l'étape concernée. Ce n'est pas un artefact décoratif : c'est ce que le plan lira ensuite.

## Un exemple d'échange

Prenons « je veux ajouter un export CSV ». Un cadrage réel ressemblera à ça :

> **Toi** — Je veux permettre d'exporter la liste des clients en CSV.
>
> **Le lab** — J'ai regardé : la liste est paginée à cinquante entrées et le filtre de recherche
> est appliqué côté serveur. Deux choses à trancher. L'export porte-t-il sur la page affichée, sur
> le résultat filtré complet, ou sur toute la base ? Et un utilisateur qui n'a accès qu'à ses
> propres clients doit-il pouvoir exporter les autres ?
>
> **Toi** — Le résultat filtré complet. Et non, chacun n'exporte que ce qu'il peut déjà voir.
>
> **Le lab** — Noté, les deux points sont verrouillés. Une question de plus : un export de la base
> entière peut prendre du temps. On accepte que la requête bloque, ou il faut prévoir un export en
> arrière-plan avec notification ?
>
> **Toi** — Ça bloque, c'est bon pour l'instant. On verra si ça devient un problème.
>
> **Le lab** — Verrouillé : export synchrone. Je note « export asynchrone avec notification » en
> idée différée, avec ta raison — à reconsidérer si les volumes montent.

Quatre échanges, et le périmètre est net. Remarque le dernier point : l'idée d'export asynchrone
n'a pas été jetée, elle a été **rangée**. C'est exactement la différence entre un cadrage et une
liste de refus.

## Ce que tu apportes, ce que tu peux laisser

**Ce que tu apportes** : l'intention, les contraintes que le code ne dit pas (un client qui exige
tel format, une échéance, une décision passée qu'il ne faut pas défaire), et les arbitrages quand
deux options sont toutes les deux valables. Personne d'autre ne peut fournir ça.

**Ce que tu peux laisser** : l'état actuel du code, les dépendances existantes, la façon dont le
projet fait déjà des choses similaires, les conventions en vigueur. Le lab va les chercher.

Un mot sur le rythme : si tu n'as pas la réponse à une question, dis-le. Une hypothèse assumée et
écrite vaut mieux qu'une réponse inventée pour faire avancer la conversation — parce qu'une
hypothèse écrite, tu la reverras dans le plan et tu pourras encore la corriger. Une réponse
inventée, elle, devient une décision verrouillée sur du sable.

### Deux erreurs de cadrage qui coûtent cher

**Répondre « comme tu veux ».** C'est tentant quand la question porte sur un détail technique qui
te semble sans importance. Le problème est qu'une question posée au cadrage n'est presque jamais un
détail : elle est posée parce que deux comportements différents découlent des deux réponses. Si tu
n'as pas d'avis, dis plutôt « prends le plus simple et note-le comme hypothèse » — tu obtiens le
même résultat, mais tu le reverras écrit et tu pourras encore le corriger.

**Cadrer trois choses à la fois.** Une conversation de cadrage qui couvre l'export CSV, la refonte
du menu et un problème de performance produira un périmètre mou et un plan bancal. Sépare. Trois
cadrages courts valent mieux qu'un long, et rien ne t'empêche de les enchaîner dans la même
session.

Le cadrage terminé, l'étape suivante est le [plan](./planifier.md).

<!-- vf-manual:nav -->
[← Précédent](../04-cycle-de-dev/le-cycle-en-bref.md) · [↑ Sommaire](../README.md) · [Suivant →](../04-cycle-de-dev/planifier.md)
<!-- /vf-manual:nav -->
