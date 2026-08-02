# Dépannage — au-delà de l'installation

<!-- vf-manual:lang -->
**Français** · [English](../../en/06-reference/troubleshooting.md)
<!-- /vf-manual:lang -->

[depannage-installation.md](../01-demarrer/depannage-installation.md) couvre ce qui peut casser
**pendant** l'installation. Cette page couvre l'inverse : ton lab est installé, il fonctionne, et
c'est **après**, une fois que tu l'utilises au quotidien, qu'un comportement inattendu apparaît.
Les deux pages ne se recouvrent jamais — si ton problème ressemble à un souci d'installation, c'est
l'autre page qu'il te faut.

Chaque panne ci-dessous suit le même patron : le symptôme exact tel que tu le vois, la cause la
plus fréquente, le geste à faire, et comment vérifier que c'est réglé. Aucun geste proposé ici
n'est destructeur sans que la page ne dise explicitement ce qu'il détruit.

## Les six pannes connues

### L'agent ne s'est pas déclenché

**Symptôme.** Tu formules une phrase qui devrait déclencher un skill précis — « améliore le
design », « lance une campagne cold email » — et rien de spécifique ne se passe : une réponse
générique arrive à la place, ou rien du tout.

**Cause la plus fréquente.** Le module correspondant n'est pas installé dans ce lab — un skill ne
peut jamais se déclencher s'il n'est pas là. Deuxième cause possible : ta phrase reste trop vague
pour matcher la description du skill, même si le module est bien présent.

**Geste.** Vérifie d'abord quels modules sont installés (le
[catalogue des modules](../03-modules/catalogue.md) et
[où vit un module](../03-modules/ou-vit-un-module.md) expliquent comment lire ça). Si le module y
est, reformule en nommant plus explicitement le geste que tu veux — pas besoin de connaître un nom
technique, juste d'être plus concret sur l'intention.

**Vérification.** Retente la même phrase. Si ça persiste malgré un module confirmé installé, passe
par `/vibeflow` suivi de ta demande : elle route toujours vers `vibeflow-conductor`, qui peut
diagnostiquer pourquoi le routage direct n'a pas fonctionné.

### Une mission est bloquée

**Symptôme.** Une mission longue semble suspendue — plus de mise à jour, pas de nouveau rapport,
silence apparent.

**Cause la plus fréquente.** Elle attend une validation humaine (statut `human_needed`) déjà
remontée plus haut dans la conversation, ou une halte s'est déclenchée et son message d'escalade
est passé inaperçu au milieu d'une longue réponse.

**Geste.** Remonte dans les derniers messages de la mission : l'escalade est **toujours explicite**
— jamais un silence sans message. Réponds à la question posée. Si tu ne trouves vraiment aucune
trace d'escalade, demande simplement au manager « où en est la mission ? » — il doit pouvoir
répondre immédiatement avec son état courant, sans redémarrer quoi que ce soit.

**Vérification.** Le manager reprend la main dès que tu réponds à ce qui bloquait ; s'il ne le fait
pas, c'est que le blocage était ailleurs — vois « le verrou de driver est coincé » ci-dessous.

### Une halte a gelé un nœud (halt condition)

**Symptôme.** L'exécution s'arrête net avec un message qui nomme explicitement un déclencheur
d'arrêt : trop d'itérations sans converger entre plan et revue, une boucle sans progrès mesurable,
une action jugée non réversible détectée avant de l'exécuter, une ressource externe manquante, ou
un fichier modifié hors du périmètre prévu.

**Cause.** C'est **volontaire, pas une panne** : cinq déclencheurs universels existent précisément
pour arrêter net une exécution autonome plutôt que de la laisser improviser silencieusement.

**Geste.** Lis le message d'escalade en entier — il nomme le déclencheur et pourquoi il s'est
activé. Réponds à la question posée précisément. **Ne réponds jamais par un « continue » générique
sans avoir lu le motif** : si le déclencheur porte sur une action non réversible, ta confirmation
va faire exécuter exactement ce que le message décrit noir sur blanc — relis-le avant de valider.

**Vérification.** L'exécution ne reprend qu'après ta réponse explicite ; rien ne redémarre tout
seul, à aucun moment.

### Le verrou de driver est coincé

**Symptôme.** Une nouvelle mission refuse de démarrer sur une étape donnée, avec un message
indiquant qu'un verrou de driver est déjà tenu.

**Cause la plus fréquente.** Une session précédente a été interrompue brutalement (fermeture de
terminal, crash) sans relâcher son verrou. Le verrou porte une durée de vie par défaut de trente
minutes : tant que ce délai n'est pas dépassé, il reste considéré comme vivant — à raison, une
mission peut légitimement prendre son temps.

**Geste.** Ne force jamais rien avant d'avoir vérifié l'état. Demande à ton lab l'état du verrou,
ou si tu es à l'aise avec le terminal, lance `driver-lock.sh status` depuis les scripts du module
`conductor`. S'il indique un verrou **périmé**, une récupération (`driver-lock.sh recover`) le
retire proprement — ce geste ne détruit que l'entrée du verrou lui-même, jamais un commit ou un
fichier produit par la mission qui le tenait. S'il n'est **pas** périmé, ne force rien : une autre
mission le tient légitimement, laisse-la terminer ou relâcher elle-même.

**Vérification.** L'état repasse à absent, ou affiche un nouvel owner si une autre mission a repris
la main entre-temps.

### Le claim de branche est refusé

**Symptôme.** Tu commites sur une branche et un signal t'indique qu'elle est déjà « revendiquée »
par un autre arbre de travail.

**Cause.** Deux acteurs — une mission en cours et toi, ou deux sessions distinctes — travaillent
sur ce dépôt sans être chacun dans son propre arbre de travail (worktree). C'est un signal
**informatif**, jamais un blocage : il ne t'empêche à aucun moment de committer.

**Geste.** Si c'est volontaire (tu sais que c'est bien toi, dans une autre fenêtre), continue
simplement, rien à corriger. Sinon, ouvre ton propre `git worktree` plutôt que de continuer à
écrire dans le même arbre qu'une mission active — c'est exactement l'usage que la règle vise à
éviter : deux acteurs qui mélangent leurs commits sans s'en rendre compte.

**Vérification.** Le signal disparaît une fois que chaque acteur travaille depuis son propre arbre.

### Une PR de mission reste ouverte

**Symptôme.** Une mission d'équipe se termine, son rapport donne l'URL d'une pull request, mais
cette PR n'est ni fusionnée ni fermée — et rien ne semble se passer ensuite.

**Cause.** Ce n'est pas un oubli : une mission d'équipe ne fusionne **jamais** elle-même sa propre
PR. Le merge t'appartient — c'est la validation humaine finale sur un historique de plusieurs
commits produits sans supervision continue à chaque étape.

**Geste.** Relis la PR (les diffs, et le rapport de mission dont son titre et son corps sont
dérivés), puis fusionne-la toi-même une fois satisfait — ou demande des corrections avant de le
faire. Ce geste-ci n'a rien de destructeur : ne rien faire, ou fermer la PR sans fusionner,
n'efface aucun commit déjà poussé sur la branche.

**Vérification.** La PR passe à fusionnée ou fermée seulement après ton geste explicite ; rien ne
l'automatise à ta place.

## Si le problème ne ressemble à aucune de ces six pannes

Décris exactement ce que tu vois — le message complet, la phrase que tu as tapée — plutôt que de
deviner une cause : c'est ce qui permet de retrouver le plus vite lequel des mécanismes ci-dessus
est réellement en jeu. Si le problème persiste sans correspondre à aucun cas connu, la page
[où trouver quoi](./ou-trouver-quoi.md) dit comment le signaler.

<!-- vf-manual:nav -->
[← Précédent](../06-reference/couts-et-modeles.md) · [↑ Sommaire](../README.md) · [Suivant →](../06-reference/ou-trouver-quoi.md)
<!-- /vf-manual:nav -->
