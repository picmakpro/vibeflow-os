# Les neuf principes

<!-- vf-manual:lang -->
**Français** · [English](../../en/02-concepts/the-nine-principles.md)
<!-- /vf-manual:lang -->

VibeFlow suit **neuf principes**, sourcés du document canonique `VIBEFLOW_CORE.md`. C'est le
chiffre qui fait autorité aujourd'hui : si tu croises ailleurs une mention des « sept principes »
(dans `VIBEFLOW_PHILOSOPHY.md` ou `VIBEFLOW_EXPLAINED.md`), sache que le canon lui-même les
qualifie d'**historiques** — une version antérieure à la refonte qui a ajouté l'évaluation
qualitative (P8) puis la modularisation (P9). Cette page traduit les neuf pour toi, en langage
d'usage, pas de conception. Pour la version longue et les critères testables, le canon reste la
référence — cette page ne le recopie pas.

## Les neuf principes, un par un

### P1 — Capitaliser

Ton lab n'oublie rien : chaque décision structurante et chaque apprentissage sont tracés dans une
mémoire consultable, avec le raisonnement complet. Concrètement, tu peux comprendre pourquoi un
choix a été fait il y a trois semaines en lisant une seule entrée, sans reconstituer la
conversation.

### P2 — Structurer le contexte

Chaque agent ne reçoit que ce dont il a besoin pour sa tâche, pas un briefing exhaustif. Tu le
sens à un agent qui répond de façon concentrée plutôt que de digresser sur du contexte qui n'a
aucun rapport avec ce que tu lui as demandé.

### P3 — Orchestrer et exécuter

Un manager de mission planifie et délègue, il ne produit jamais lui-même. En pratique : quand une
décision sort du mandat d'un agent, il **s'arrête et te la remonte** plutôt que de l'étendre en
silence.

### P4 — Clarifier avant d'exécuter

Pas de travail lancé sur une consigne floue. Avant une action structurante, VibeFlow pose des
questions ou attend ta validation — c'est pour ça qu'une session commence parfois par des
questions plutôt que par de l'exécution immédiate.

### P5 — Vérifier en boucle

Aucune déclaration de « c'est fait » sans preuve produite dans la session en cours. Tu verras des
commandes exécutées, des exit codes, des fichiers relus — jamais un « ça devrait marcher » sans
vérification.

### P6 — Itérer par cycles courts

Le travail avance par petits cycles avec un livrable et une capitalisation à chaque fin, pas par
un unique bloc opaque de plusieurs heures. Tu peux interrompre, reprendre, et voir où on en est à
tout moment.

### P7 — Transposer, pas copier

VibeFlow ne recopie pas le vocabulaire du dev dans un lab business : chaque métier reçoit ses
propres mots. C'est pour ça que le lab de Karim parle de « clients » et de « séances », jamais de
« sprint » ou de « feature ».

### P8 — Évaluer la qualité cognitive

La qualité d'une réponse produite par l'IA est **mesurée**, pas présumée bonne parce qu'elle a l'air
convaincante. C'est ce qui fait qu'un juge frais note un livrable sur une rubric explicite plutôt
que de laisser l'agent producteur juger son propre travail.

### P9 — Modulariser pour la cognition

Aucun fichier, agent ou document ne dépasse sa capacité cognitive utile — une responsabilité par
unité, une limite appliquée par la machine. **Ce principe est le plus indirect des neuf pour toi** :
sa conséquence observable n'est pas un comportement que tu vois directement, mais un effet de
second ordre — des agents qui restent cohérents sur la durée plutôt que de dériver ou de se
contredire sur de longues instructions. Le dire franchement plutôt que d'inventer un bénéfice
immédiat : P9 protège la fiabilité du système qui te répond, pas une action que tu déclenches
toi-même.

### Un principe n'est pas un chiffre marketing

Chaque principe est écrit dans le canon comme un **contrat testable** : un critère binaire (fait /
pas fait), pas une intention vague. La version ci-dessus en donne la conséquence pour toi, pas la
liste des critères eux-mêmes — c'est volontaire, cette page reste à hauteur d'usage. Si tu veux
vérifier toi-même qu'un principe est appliqué sur un lab donné, c'est le canon qu'il faut ouvrir,
pas cette page.

## Pourquoi neuf, jamais sept

Le Core est passé par plusieurs éditions : sept principes en v3 (pré-Core, dev web uniquement),
huit avec l'ajout de P8-Évaluer (v4.0), puis neuf avec l'ajout de P9-Modulariser (v4.2, origine :
la doctrine d'architecture logicielle AI-Safe). `VIBEFLOW_PHILOSOPHY.md` et
`VIBEFLOW_EXPLAINED.md` n'ont pas suivi ces deux dernières éditions et parlent encore de « sept
principes » — le canon les qualifie lui-même d'historiques. Ce manuel ne corrige pas ces deux
fichiers (hors périmètre de cette phase) ; il documente simplement la version qui fait autorité
aujourd'hui.

Si un jour tu vois une dixième édition citée quelque part dans le repo sans que cette page ait
suivi, applique la même règle qu'on t'a appliquée ici : le canon fait foi, tout le reste se date.
Les éditions citées ci-dessus (v3, v4.0, v4.2) décrivent l'historique du canon lui-même, pas un
numéro de module ou de plugin — cette page ne fige donc rien qui te concerne directement. Cette
distinction entre le numéro d'édition du canon et la version livrée d'un module mérite d'être
gardée en tête dans tout le manuel : l'un date une idée, l'autre date un logiciel présent sur ton
disque. C'est exactement en confondant les deux que les anciennes pages « sept principes » ont fini
par périmer — elles ont figé un chiffre au lieu de pointer vers le canon.

<!-- vf-manual:nav -->
[← Précédent](../02-concepts/vibeflow-gsd-superpowers.md) · [↑ Sommaire](../README.md) · [Suivant →](../02-concepts/gates-et-validation-humaine.md)
<!-- /vf-manual:nav -->
