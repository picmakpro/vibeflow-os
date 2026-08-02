# Première session

<!-- vf-manual:lang -->
**Français** · [English](../../en/01-get-started/your-first-session.md)
<!-- /vf-manual:lang -->

Tu viens de finir `/vibeflow-install` (voir [installation.md](./installation.md)). Cette page
couvre le quart d'heure qui suit : ce qui se passe à l'ouverture de ta prochaine session Claude
Code, comment tu parles à VibeFlow, et ce que tu dois voir apparaître pour savoir que ça marche.

## Ce qui se passe à l'ouverture de la session suivante

Rien d'automatique ne se lance. Comme vu dans [installation.md](./installation.md), VibeFlow ne
s'ouvre jamais tout seul — c'est volontaire. Tu ouvres Claude Code normalement, dans le dossier
où tu as installé VibeFlow (ou n'importe où si tu as choisi le scope compte), et tu commences à
parler.

La seule chose qui change par rapport à avant l'installation : Claude Code connaît maintenant les
agents et les commandes que VibeFlow a posés. Tu n'as rien à activer.

## Comment on parle à VibeFlow

C'est le point le plus important à comprendre tout de suite : **tu parles en langage naturel, pas
en commandes**. Les commandes existent (`/vibeflow`, `/vf-new-lab`, `/vf-update`...), mais elles
ne sont pas la porte d'entrée principale — elles servent surtout de raccourcis pour qui les
connaît déjà. La vraie porte d'entrée, c'est de dire ce que tu veux, avec tes mots.

Concrètement, tu peux taper des phrases comme :
- « aide-moi à avancer sur ce projet »
- « crée-moi un lab pour organiser mes contenus »
- « vérifie que tout est bien configuré »
- « mets à jour VibeFlow »

VibeFlow détecte l'intention derrière ta phrase et route vers la bonne action tout seul. Tu n'as
pas besoin de savoir à l'avance quel agent ou quelle commande fait quoi.

### Tu n'as rien à mémoriser

Tu n'as pas besoin de connaître le nom d'un seul agent avant de commencer — c'est VibeFlow qui
choisit le bon agent pour ta demande, pas toi. Si ta phrase est imprécise ou mal formulée, ce
n'est pas grave : VibeFlow te pose une question de clarification plutôt que de deviner à ta place
et de partir dans la mauvaise direction. Et rien d'irréversible ne se produit sans que tu confirmes
d'abord — les actions qui modifient quelque chose (installer, mettre à jour, désinstaller) te
montrent toujours un récapitulatif avant de s'exécuter.

## Un premier échange concret

Voici un échange court, que tu peux recopier tel quel pour ta toute première interaction. Tape :

```
aide-moi à démarrer
```

Ce que tu vois généralement apparaître : VibeFlow identifie que tu ne lui as pas donné de tâche
précise, et te pose une question courte pour cerner ce que tu veux faire — par exemple, s'il
détecte que ce dossier est un projet de code, il peut proposer de t'aider à avancer dessus ; s'il
ne détecte rien de particulier, il te demande directement ce que tu cherches à faire (créer un
nouveau lab, vérifier une configuration, autre chose).

Réponds simplement à sa question, en une phrase, comme tu le ferais avec un collègue. Par exemple,
si tu veux découvrir la création d'un lab de A à Z :

```
je veux créer un lab pour piloter mes contenus
```

À partir de là, VibeFlow enchaîne un cadrage court — quelques questions pour comprendre ton métier
et ce que tu veux que ce lab sache faire — avant de construire quoi que ce soit. Tu n'as jamais à
deviner la prochaine étape : chaque réponse de VibeFlow se termine par une question ou une
proposition claire de ce qui vient ensuite.

**Si tu te trompes de formulation.** Rien de grave ne peut arriver en tapant une phrase maladroite
ou incomplète — au pire, VibeFlow te repose la question autrement. Tu peux aussi reformuler en
plein milieu d'un échange si tu changes d'avis sur ce que tu veux faire : dis-le simplement, comme
« en fait, laisse tomber, je veux plutôt... ».

**Ce qu'il ne faut pas faire tout de suite.** Ne cherche pas à mémoriser la liste des commandes ni
à lire toute la documentation avant de commencer : le langage naturel suffit à démarrer, et tu
apprendras les commandes au fur et à mesure si tu en as besoin. Ne lance pas non plus plusieurs
demandes en parallèle dans la même session tant que tu découvres l'outil — une intention à la
fois, jusqu'à ce que le fonctionnement te soit familier.

Une fois que tu as goûté à cet échange, la suite logique est de créer un premier lab complet de
bout en bout — c'est l'objet de la page suivante de ce thème.

### Ce que tu n'as pas besoin de savoir tout de suite

Tu vas croiser au fil de ce manuel des mots comme « lab », « scope » ou « registre ». Tu n'as pas
besoin de les maîtriser avant de commencer à parler à VibeFlow : ils se définissent au fur et à
mesure que tu les rencontres, et le premier échange ci-dessus fonctionne très bien sans eux. Le
mot le plus important pour l'instant, c'est « lab » — l'espace de travail que VibeFlow te
construit — et il est expliqué en détail dans la page suivante, à l'usage plutôt qu'en théorie.

Si un mot te bloque vraiment en cours de route, la manière la plus simple de lever le doute reste
de le demander directement à VibeFlow dans ta session — c'est plus rapide que de chercher dans le
manuel, et la réponse sera adaptée à ce que tu es en train de faire au moment où tu la poses. Il
n'existe pas de question de débutant qui ferait perdre du temps à qui que ce soit ici.

Prends ça comme la permission d'arrêter de lire et d'aller essayer — le reste de ce manuel sera
toujours là après.

<!-- vf-manual:nav -->
[← Précédent](../01-demarrer/choisir-son-scope.md) · [↑ Sommaire](../README.md) · [Suivant →](../01-demarrer/premier-lab.md)
<!-- /vf-manual:nav -->
