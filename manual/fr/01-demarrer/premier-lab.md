# Premier lab

<!-- vf-manual:lang -->
**Français** · [English](../../en/01-get-started/your-first-lab.md)
<!-- /vf-manual:lang -->

Cette page déroule la création d'un **lab** de bout en bout — le mot central de VibeFlow, que tu
vas voir revenir partout. Un lab, c'est l'espace de travail que VibeFlow construit sur mesure pour
un métier donné : sa mémoire, ses agents, ses garde-fous. Après cette page, tu auras créé le tien
et vu ce qu'il contient.

## Un cas concret : Karim, coach sportif indépendant

Pour rendre l'exemple concret, suivons un cas modeste et humain plutôt qu'une démonstration
technique abstraite. Karim est coach sportif indépendant : il suit une quinzaine de clients à
distance (programmes, suivi de progression, relances), et publie occasionnellement des conseils
sur les réseaux. Il n'a jamais utilisé VibeFlow et veut un lab simple pour commencer, pas une
usine à gaz.

### Lancer la création

Karim tape, en langage naturel (voir [premiere-session.md](./premiere-session.md) si tu veux
revoir pourquoi c'est la bonne porte d'entrée) :

```
je veux un lab pour suivre mes clients en coaching sportif
```

VibeFlow détecte qu'il s'agit d'une création de lab et lui propose un choix : un parcours complet
(cadrage approfondi, plusieurs capacités) ou un **mode express** — un lab opérationnel en moins
de 15 minutes, seulement 3 questions, le reste dérivé et clairement marqué comme tel. Comme Karim
découvre l'outil et veut juste voir ça tourner, il choisit l'express. Rien ne l'empêchera plus
tard de reprendre chaque point dérivé et de l'approfondir — le mode express est un point de départ
assumé, pas un plafond.

## Les trois questions, et des réponses plausibles

**1. « Ce lab fait quoi, comme métier ? »**
Karim répond : *« Coaching sportif à distance — suivi de programmes et de progression pour une
quinzaine de clients. »*

**2. « Son objectif, en une phrase ? »**
Karim répond : *« Garder une vue claire sur où en est chaque client, et ne rien oublier entre deux
séances. »*

**3. « Les 1 à 3 choses qu'il doit savoir faire en premier ? »**
Karim répond : *« Suivre la progression d'un client sur plusieurs semaines, et me rappeler les
points d'attention avant chaque séance. »*

Trois questions, pas une de plus — c'est tout le principe du mode express. Tout le reste (le
vocabulaire du métier, les contraintes, la définition du succès) est **déduit** de ces trois
réponses, et marqué explicitement comme une déduction plutôt que présenté comme une certitude.
C'est une nuance importante : une réponse déduite n'est pas une réponse devinée au hasard, c'est
une conséquence raisonnable des trois réponses que Karim a données lui-même.

## Ce qui a été créé

**Pendant que Karim attend.** VibeFlow construit le lab en tâche de fond : un fichier `CLAUDE.md`
qui résume le métier de Karim et ses règles de travail, un ou deux agents spécialisés dans le
suivi de client et la préparation de séance, une mémoire de travail pour capitaliser ce qui
fonctionne d'un client à l'autre. Karim peut commencer à parler à son lab pendant que la
fabrication se termine — il n'attend pas les bras croisés.

**Le récapitulatif final.** À la fin, un récapitulatif honnête liste : les 3 réponses sur
lesquelles le lab a été construit, chaque section déduite plutôt que confirmée (avec ce qui a été
déduit exactement), et comment affiner plus tard si un point déduit s'avère faux à l'usage.

**Ce que Karim se retrouve avec, en bref.** Sans entrer dans le détail technique (une page dédiée,
plus loin dans le manuel, décortique l'anatomie complète d'un lab installé sur disque), retiens
qu'il obtient :

- un dossier qui porte la **constitution** de son lab (les règles de travail, en une page courte) ;
- un ou plusieurs **agents** spécialisés, prêts à être sollicités en langage naturel ;
- une **mémoire** qui commence vide mais qui va se remplir : chaque décision structurante, chaque
  pattern observé sur plusieurs clients, chaque point de friction deviennent des entrées qu'on
  peut retrouver plus tard, plutôt que des choses qu'on doit se souvenir soi-même.

Ce n'est **pas** un squelette vide : Karim peut immédiatement dire « aide-moi à préparer la séance
de [client] » et obtenir une réponse qui s'appuie sur ce qui vient d'être construit.

**Et maintenant.** Le lab de Karim est volontairement minimal — c'est le principe du mode express.
Rien n'empêche de le faire grandir plus tard : reposer la même question avec plus de détails
permet de remonter le lab vers une version plus complète, capacité par capacité. C'est le sujet de
pages qui viendront plus loin dans le manuel, une fois que tu auras toi-même un lab qui tourne.

**À ton tour.** Si tu veux reproduire cet exemple pour de vrai plutôt que de simplement le lire,
tape la même phrase que Karim en l'adaptant à ton propre métier — remplace « coaching sportif » par
ce que tu fais réellement. Choisis le mode express si tu veux voir un résultat rapidement ; choisis
le parcours complet si tu préfères un cadrage plus poussé dès le départ. Les deux chemins mènent au
même type de lab, seule la profondeur de la clarification initiale change.

Il n'y a pas de mauvaise réponse aux trois questions de l'express : plus tes réponses sont
concrètes et précises, plus les capacités dérivées seront proches de ce dont tu as réellement
besoin — mais même des réponses approximatives donnent un lab exploitable, puisque tout ce qui est
dérivé reste modifiable ensuite. Le seul vrai risque, c'est de ne jamais essayer.

Karim aurait tout aussi bien pu répondre en une phrase plus courte ou plus longue : ce qui compte,
c'est que la réponse vienne de lui, pas qu'elle suive un format précis.

<!-- vf-manual:nav -->
[← Précédent](../01-demarrer/premiere-session.md) · [↑ Sommaire](../README.md) · [Suivant →](../01-demarrer/mettre-a-jour-et-desinstaller.md)
<!-- /vf-manual:nav -->
