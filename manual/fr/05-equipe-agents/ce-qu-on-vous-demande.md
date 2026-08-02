# Ce qu'on vous demande

<!-- vf-manual:lang -->
**Français** · [English](../../en/05-agent-team/what-is-asked-of-you.md)
<!-- /vf-manual:lang -->

Les deux pages précédentes ont dit qui compose l'équipe et comment elle tient la route. Celle-ci
prend le point de vue inverse : le cycle de vie d'une mission longue **vu de l'extérieur**, comme
un protocole que tu peux suivre plutôt qu'une description du système. Elle complète
[mode-autonome.md](../04-cycle-de-dev/mode-autonome.md), qui couvre les déclencheurs d'arrêt
génériques de toute boucle autonome — ici, ce qui est spécifique à une mission pilotée par une
équipe de plusieurs agents, pas une seule session qui boucle.

Lis-la avant de lancer ta première mission d'équipe, pas après. Elle tient en six points : quand tu
es sollicité, ce qui arrête tout, comment mettre en pause, comment reprendre depuis rien, où
atterrit le travail produit, et ce que tu dois relire avant de dire oui.

## Ce qui vous sollicite, et ce qui arrête la mission

Pendant qu'une équipe travaille, tu es sollicité à des moments précis, jamais au hasard. Le plus
fréquent : un rapport typé de worker revient avec le statut `human_needed` — une zone grise que
personne dans l'équipe n'a le mandat de trancher seul. Ça remonte immédiatement jusqu'à toi, sous
forme de question structurée, pas d'une remarque noyée dans un long compte rendu.

Ce qui **arrête** franchement la mission, sans tentative de contournement, ce sont les halt
conditions décrites en détail dans
[gates-et-validation-humaine.md](../02-concepts/gates-et-validation-humaine.md) — une action
destructive non réversible, un blocage qui persiste après plusieurs tentatives sans progrès, une
divergence de plan qui ne converge pas, un écart entre les fichiers touchés et le périmètre
convenu, une ressource externe manquante. Sur une mission d'équipe, il faut y ajouter un cas propre
au travail en groupe : un **conflit de coordination** — deux nœuds du DAG qui touchent la même
ressource d'une façon que le graphe n'avait pas anticipée, ou une branche déjà pilotée par un autre
acteur, détectée au démarrage (voir
[branches-et-worktrees.md](./branches-et-worktrees.md)). Dans tous les cas, l'arrêt s'accompagne
d'un message structuré : ce qui était en cours, ce qui a déclenché l'arrêt, l'état exact (étapes
terminées, commits faits), et des options concrètes entre lesquelles choisir. Jamais un silence,
jamais un « ça a planté » sans contexte.

Une garantie qui vaut d'être répétée ici parce qu'elle s'applique intégralement à une mission
d'équipe : **aucune suppression de contenu, aucune correction risquée, aucune action irréversible
n'est jamais accordée en autonomie.** Un manager qui a besoin de supprimer massivement, de forcer
une réécriture d'historique, ou d'envoyer quelque chose vers l'extérieur s'arrête et te le demande,
sans exception et sans que le volume de travail restant y change quoi que ce soit.

Ce que ça donne concrètement dans ta boîte de réception : jamais un message vague du type « ça
coince, que fait-on ? ». Toujours un contexte en une phrase, l'observation factuelle qui a déclenché
l'arrêt, l'état exact du travail à cet instant, et des options nommées entre lesquelles trancher —
souvent en moins d'une minute, parce que le contexte n'est pas à reconstruire.

## Mettre en pause, et reprendre depuis une session vierge

Tu peux interrompre une mission d'équipe à tout moment. Ce qui est déjà commité reste commité —
rien ne se défait à l'interruption. Ce qui distingue une **coupure nette** d'une **pause propre**,
c'est que la seconde se demande explicitement : dis-le, et le manager écrit un point de reprise sur
le disque avant de s'arrêter — l'état du DAG (quels nœuds sont faits, lesquels sont en cours), les
décisions déjà prises pendant la mission, et ce qui restait à faire. Une coupure nette laisse
l'état tel quel sur le disque ; une pause demandée le rend lisible pour qui reprend.

**Reprendre depuis une session vierge** fonctionne parce que le disque, pas la conversation, est la
source de vérité de toute mission VibeFlow. Une nouvelle session qui redémarre le même manager n'a
besoin d'aucun contexte que tu lui répéterais : il relit lui-même l'état du projet
(`.planning/ROADMAP.md`, `.planning/STATE.md`) et le graphe de la mission, reconstruit sa position,
et reprend le dispatch là où il s'était arrêté — y compris en récupérant un verrou de driver périmé
si la coupure a été assez longue pour ça (voir
[une-mission-longue.md](./une-mission-longue.md)). Tu n'as rien à reconstituer toi-même ; c'est
précisément ce que le rapport de la session précédente et l'état sur disque rendent possible.

Une nuance à connaître : une coupure nette (fermer l'onglet, couper le processus) ne relâche pas
forcément le verrou de driver proprement — c'est la limite déjà dite dans
[une-mission-longue.md](./une-mission-longue.md). Ce n'est pas grave : le mécanisme de récupération
sur verrou périmé existe justement pour ce cas, et une session suivante qui relance la même mission
le récupère automatiquement, avec la reprise consignée. Tu n'as rien à nettoyer toi-même à la main.

## Où atterrissent les artefacts, et ce qu'on relit avant d'accepter

Trois endroits, toujours les mêmes. Le suivi de la mission (plans, rapports détaillés, décisions)
vit sous `.planning/` dans le dépôt cible. Le travail lui-même vit sur **sa propre branche**,
jamais sur ta branche principale (ADR-059) — le détail de ce que ça implique pour toi est dans
[branches-et-worktrees.md](./branches-et-worktrees.md). Et la mission se termine par une **PR
laissée ouverte**, jamais fusionnée toute seule : le merge t'appartient.

Si le projet n'est pas un dépôt git, ou n'a pas de remote configuré, ou que l'outil de gestion de PR
n'est pas disponible, la mission ne s'arrête pas pour autant — elle applique un repli et **te le
dit** dans son rapport plutôt que d'échouer en silence ou de faire semblant que la branche et la PR
existent. C'est une garantie explicite : une mission d'équipe n'échoue jamais à cause de la
mécanique git, seulement à cause du contenu du travail lui-même.

Ce que tu relis avant d'accepter reprend, sans le redire intégralement, la liste de
[livrer-et-relire.md](../04-cycle-de-dev/livrer-et-relire.md) — le diff, ce qui a été supprimé, les tests, les
critères de réussite du plan. Une mission d'équipe ajoute une pièce propre : le **rapport de
mission** rendu à la fin, qui résume le verdict global, le détail par étape (fait / verdicts /
commits), les décisions prises en autonomie et par quel mécanisme, et les points qui attendent
explicitement ton arbitrage. Commence toujours par ce dernier point — c'est lui qui bloque la
suite, exactement comme en mode autonome simple.

Une dernière chose à vérifier, propre aux missions les plus longues : si le plan portait une
estimation de coût, le rapport porte le résultat réel en face, recopié tel quel plutôt que
recalculé ou arrondi. Un écart important entre les deux n'est pas une faute — c'est une information
utile pour calibrer la prochaine mission de taille comparable.

Retiens l'idée qui traverse toute cette page : une mission d'équipe ne te retire aucun des points de
contrôle que tu aurais eus en travaillant seul. Elle les regroupe et les rend traçables sur disque,
pour que tu puisses les honorer même en ayant été absent pendant qu'elle tournait.

C'est ce déplacement — de la surveillance continue à la relecture ciblée au bon moment — qui rend
une mission longue viable sans te river à l'écran. C'est aussi toute la raison pour laquelle la
page précédente a pris la peine de nommer les limites honnêtes du mécanisme : savoir où il peut
dériver en silence, c'est ce qui te permet de relire au bon moment plutôt qu'à chaque instant.

<!-- vf-manual:nav -->
[← Précédent](../05-equipe-agents/une-mission-longue.md) · [↑ Sommaire](../README.md) · [Suivant →](../05-equipe-agents/branches-et-worktrees.md)
<!-- /vf-manual:nav -->
