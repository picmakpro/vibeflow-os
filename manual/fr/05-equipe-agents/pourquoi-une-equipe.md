# Pourquoi une équipe

<!-- vf-manual:lang -->
**Français** · [English](../../en/05-agent-team/why-a-team.md)
<!-- /vf-manual:lang -->

Sur une petite tâche, une seule session fait très bien l'affaire. Sur une mission longue — dix
étapes, une refonte, une nuit de travail délégué — elle se dégrade. Cette page explique pourquoi,
et ce qu'un découpage en rôles change concrètement pour toi.

Si les mots « agent », « skill » et « commande » ne sont pas encore nets, commence par
[agents-skills-commandes.md](../02-concepts/agents-skills-commandes.md) — cette page ne les
redéfinit pas.

Ce choix ne dépend pas d'une estimation à l'œil. Le nombre d'étapes restantes est compté sur ta
feuille de route, comparé à un seuil fixe, et une équipe se déploie dès qu'il est atteint — ou dès
que tu signales une durée (« la nuit », « je reviens demain ») même sur un petit périmètre, parce
que le signal de durée l'emporte toujours sur le comptage. En dessous du seuil et sans ce signal,
une seule boucle traite la demande directement : c'est moins cher, et c'est suffisant tant que la
dégradation décrite plus bas n'a pas le temps de s'installer.

## Ce qui se dégrade quand une seule session fait tout

Trois choses, et elles arrivent toujours dans le même ordre.

**La mémoire se remplit.** Une session accumule tout : le code lu, les échanges, les erreurs, les
tentatives abandonnées. Au bout d'un moment, les informations importantes du début sont noyées sous
le bruit du milieu. Ce qui a été décidé à l'étape deux devient flou à l'étape huit — non pas oublié,
mais dilué au point de ne plus peser sur les décisions.

**L'attachement s'installe.** Une session qui a écrit du code a des raisons de le trouver bon : ce
sont les siennes. Lui demander de relire son propre travail donne une relecture de complaisance —
pas par malhonnêteté, mais parce que relire sa propre logique avec la même logique ne peut rien
révéler d'autre que des fautes de frappe.

**Le périmètre glisse.** Sans quelqu'un qui tient la carte d'ensemble, chaque étape hérite du
contexte de la précédente et dérive un peu. Au bout de dix étapes, la dérive n'est plus petite.

## Le découpage en rôles

Une équipe VibeFlow répond à ces trois problèmes par trois rôles distincts, chacun dans sa propre
session avec son propre contexte.

**Un manager pilote.** Il ne produit rien lui-même. Il lit l'état du projet, découpe la mission en
nœuds, décide ce qui peut avancer en parallèle, distribue le travail, et lit les rapports qui
reviennent. C'est lui qui garde la carte d'ensemble, précisément parce qu'il ne se salit pas les
mains dans le détail d'une tâche.

**Des workers produisent.** Chacun reçoit un mandat court — pas toute l'histoire de la mission, un
résumé compact de ce qu'il a besoin de savoir. C'est ce qui les garde nets : un worker qui démarre
sur trente lignes de contexte pertinent travaille mieux qu'une session qui traîne trois heures
d'historique. Ils sont cloisonnés : celui qui écrit le code n'écrit pas les tests, celui qui teste
ne corrige pas l'application.

**Un juge évalue.** Il découvre le résultat fini, sans avoir vu comment il a été fabriqué, et il
rend un verdict.

### Le juge n'est jamais l'auteur

C'est la conséquence la plus importante pour toi, et elle mérite d'être dite seule.

Dans toutes les équipes VibeFlow, l'agent qui évalue un livrable n'est jamais celui qui l'a
produit. Ce n'est pas une convention d'écriture : c'est appliqué par la structure. Le juge est
dispatché dans une session fraîche, il ne voit que le résultat sur le disque, et — pour les juges
de qualité — il n'a même pas les outils d'écriture. Il ne *peut pas* corriger ce qu'il critique, il
ne peut que le signaler.

Ce que ça change : la revue que tu lis n'est pas une auto-satisfaction. Quand un rapport te dit
« conforme », ça a été constaté par quelqu'un qui n'avait aucune raison de le trouver conforme. Et
quand un juge refuse un livrable, la correction repart chez le producteur, puis repasse devant le
juge — jusqu'au vert ou jusqu'au plafond de tours.

C'est le même principe que la revue de plan décrite en
[planifier.md](../04-cycle-de-dev/planifier.md), appliqué cette fois au résultat plutôt qu'à
l'intention.

## Ce que ça te coûte, et ce que ça ne résout pas

Il faut être honnête sur les deux.

**Ça coûte.** Plusieurs sessions, c'est plus de travail machine qu'une seule pour la même tâche. Le
gain n'apparaît que sur une mission assez longue pour que la dégradation décrite plus haut se
produise. Sur une mission courte, l'équipe est un handicap — c'est pourquoi le lab n'en déploie une
que quand la taille le justifie, comme expliqué en
[mode-autonome.md](../04-cycle-de-dev/mode-autonome.md).

**Ça ne résout pas tout.** Une équipe bien organisée exécute fidèlement ce qu'on lui a demandé. Si
le cadrage était mou, elle produira du travail bien fait sur la mauvaise chose, avec plus de
constance qu'une session seule. Le découpage en rôles protège de la dégradation, pas de l'erreur de
départ.

Et une limite structurelle qu'il vaut mieux connaître : les mécanismes de coordination entre
sessions sont **déclaratifs**. Ils supposent que chaque acteur les consulte. Une session qui les
ignore n'est pas arrêtée — c'est détaillé, sans détour, en
[une-mission-longue.md](./une-mission-longue.md) et
[branches-et-worktrees.md](./branches-et-worktrees.md).

Rien de tout ça n'est une raison de te méfier du mécanisme — c'est une raison de lire les deux
pages qui suivent avant de lui faire confiance les yeux fermés sur quelque chose qui compte.

C'est tout l'arbitrage de ce thème : moins de supervision à chaque étape, en échange de la lecture
des quelques endroits où le mécanisme te dit, sans détour, ce qu'il ne garantit pas.

<!-- vf-manual:nav -->
[← Précédent](../04-cycle-de-dev/mode-autonome.md) · [↑ Sommaire](../README.md) · [Suivant →](../05-equipe-agents/les-agents-livres.md)
<!-- /vf-manual:nav -->
