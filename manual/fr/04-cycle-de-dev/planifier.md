# Planifier

<!-- vf-manual:lang -->
**Français** · [English](../../en/04-development-cycle/planning.md)
<!-- /vf-manual:lang -->

Le plan est le document le moins spectaculaire du cycle et le plus rentable à lire. C'est la
dernière fois où corriger une trajectoire ne coûte qu'une phrase. Passé ce point, corriger coûte du
code déjà écrit.

Un plan de phase prend le périmètre issu du [cadrage](./cadrer-une-idee.md) et le transforme en une
suite de tâches ordonnées : quels fichiers sont touchés, dans quel ordre, et — c'est le plus
important — **comment on saura que c'est réussi**.

## Ce qu'il y a dedans, et pourquoi c'est découpé

Un plan n'est pas écrit d'un bloc. Il est découpé en tâches, et chaque tâche est censée être
autonome : elle a ses fichiers, son action, et son critère de vérification.

Ce découpage n'est pas cosmétique. Il sert trois choses concrètes. D'abord, il permet un **commit
par tâche** : l'historique de ton dépôt raconte le travail au lieu de livrer un bloc opaque de
quatre cents lignes. Ensuite, il permet de **reprendre au milieu** : si une session s'arrête à la
tâche trois sur six, la suivante repart à la quatre, sans redémarrer. Enfin, il rend l'échec
**localisable** : quand quelque chose casse, tu sais quelle tâche l'a cassé.

Chaque tâche porte un critère de réussite qui doit être **vérifiable**, pas déclaratif. « Le
formulaire fonctionne » n'est pas un critère. « Soumettre le formulaire avec un e-mail invalide
affiche le message d'erreur et n'envoie aucune requête » en est un. Cette exigence est ce qui
empêche une exécution de se déclarer terminée sur une impression.

Le plan porte aussi ce qu'il ne fait pas : les idées différées au cadrage restent différées, et le
plan le dit. Si tu vois dans le plan une tâche qui traite une idée que tu avais explicitement
reportée, c'est un signal — signale-le.

## Ce que tu dois vérifier avant de lancer

Voici la relecture qui rapporte. Elle prend cinq minutes et t'en économise souvent plusieurs
heures.

- **L'objectif énoncé est-il vraiment ce que tu voulais ?** Relis la première phrase du plan et
  compare-la à l'intention que tu avais en tête. C'est le contrôle le plus bête et celui qui attrape
  le plus d'erreurs.
- **Les critères de réussite sont-ils vérifiables ?** Si l'un d'eux ne peut pas être constaté par
  quelqu'un d'autre que son auteur, il ne servira à rien.
- **La liste des fichiers touchés te surprend-elle ?** Un fichier auquel tu ne t'attendais pas est
  soit une découverte utile, soit un malentendu. Les deux méritent une question.
- **Y a-t-il une tâche qui déborde du périmètre cadré ?** C'est le glissement classique. Il se
  repère très bien à la lecture, très mal après coup.
- **Ce qui manque te saute-t-il aux yeux ?** Migration de données oubliée, cas d'erreur non traité,
  effet sur une autre partie de l'application. Tu connais ton produit mieux que n'importe quelle
  analyse de code.

Pour demander une modification, dis-la simplement : « la tâche trois devrait aussi couvrir le cas
où le champ est vide », « retire la partie sur les notifications, on avait dit plus tard ». Le plan
est réécrit, pas rafistolé à la marge, et tu peux le relire à nouveau. Tant que tu n'as pas dit d'y
aller, rien n'est exécuté.

## La revue de plan, et les plans trop gros

**La revue de plan.** Avant l'exécution d'un plan structurant, un relecteur qui n'a pas écrit le
plan le passe en revue. Le principe est simple et vieux comme le monde : on n'est pas juge et
partie. Quelqu'un qui vient d'écrire un plan y est attaché, et le relire lui-même ne révèle que les
fautes évidentes — pas les angles morts. Un relecteur frais, qui découvre le plan sans connaître le
raisonnement qui l'a produit, voit ce que l'auteur ne peut pas voir.

Ce que ça change pour toi : le plan que tu lis a déjà encaissé une critique. Les remarques et leur
traitement sont visibles. Ça ne remplace pas ta relecture — le relecteur vérifie la cohérence
interne et la solidité, il ne sait pas si le résultat est ce que tu voulais. Ça, toi seul le sais.

**Les plans trop gros.** Il arrive qu'une étape se révèle plus vaste que prévu à la planification.
Dans ce cas le plan est **scindé** en plusieurs plans qui s'enchaînent — jamais rétréci en
périmètre. La distinction est essentielle : rétrécir le périmètre en silence te livrerait quelque
chose d'incomplet en te laissant croire que c'est fini. Scinder te livre la même chose, en plusieurs
fois, et tu le sais.

Si on te propose un découpage en plusieurs plans, tu peux évidemment n'en lancer qu'un et voir. Le
reste attendra sans se perdre.

### Où vit le plan, et pourquoi ça compte

Le plan est un fichier, rangé avec le contexte de l'étape dans le dossier de suivi du projet. Il ne
vit pas dans la conversation, et c'est essentiel : une conversation se perd, un fichier non.

Trois conséquences pratiques. Tu peux **relire un plan des jours plus tard**, pour comprendre
pourquoi une chose a été faite comme ça. Une **autre session** peut exécuter un plan que tu as fait
écrire hier, sans rien redécouvrir. Et le plan reste consultable **après** l'exécution, ce qui en
fait le meilleur point de comparaison quand tu relis le résultat — c'est d'ailleurs le contrôle
recommandé en [livrer-et-relire.md](./livrer-et-relire.md).

C'est aussi pour ça qu'il vaut la peine de faire corriger un plan plutôt que de compenser
mentalement ses défauts. Un plan corrigé sert plusieurs fois ; une correction que tu gardes dans la
tête ne sert qu'une, et seulement si tu t'en souviens.

Un plan bien relu est le meilleur investissement du cycle. C'est la seule étape où cinq minutes
d'attention remplacent plusieurs heures de reprise — et la seule aussi où changer d'avis ne coûte
encore rien.

Le plan validé, place à l'[exécution](./executer.md).

<!-- vf-manual:nav -->
[← Précédent](../04-cycle-de-dev/cadrer-une-idee.md) · [↑ Sommaire](../README.md) · [Suivant →](../04-cycle-de-dev/executer.md)
<!-- /vf-manual:nav -->
