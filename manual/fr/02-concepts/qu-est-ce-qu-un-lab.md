# Qu'est-ce qu'un lab ?

<!-- vf-manual:lang -->
**Français** · [English](../../en/02-concepts/what-is-a-lab.md)
<!-- /vf-manual:lang -->

« Lab » est le mot le plus employé de VibeFlow — « il fabrique des labs », « ton lab », « lab
frais », « altitude lab » — et pourtant il n'était jusqu'ici défini nulle part dans le repo. Cette
page tranche, sans esquive.

## Un lab, concrètement

Un **lab**, c'est un dossier sur ton disque, associé à un **scope** Claude Code (voir
[choisir-son-scope.md](../01-demarrer/choisir-son-scope.md)), dans lequel VibeFlow a posé trois
choses : une **constitution** (`CLAUDE.md`, ce que ce dossier est et comment on y travaille), un ou
plusieurs **agents** spécialisés dans ton métier, et une **mémoire** qui commence vide et se
remplit avec l'usage. Ce n'est ni plus ni moins que ça — pas une notion abstraite, un dossier réel
avec des fichiers réels dedans.

Un lab **n'est pas forcément un dépôt git**. Deux exemples de nature différente le montrent :

- **`vibeflow-os` lui-même** est un lab dev : un dépôt git, un `CLAUDE.md` à la racine, des agents
  dans `plugin/*/agents/`, une mémoire de travail sous `.planning/` tenue par le moteur GSD. Le
  cycle de dev s'appuie sur des commits et des branches.
- **Le lab de Karim**, le coach sportif de
  [premier-lab.md](../01-demarrer/premier-lab.md), est un lab non-dev : un dossier avec un
  `CLAUDE.md` qui résume son métier, un ou deux agents pour le suivi client, une mémoire qui
  capitalise ce qui marche d'un client à l'autre — **sans qu'aucun dépôt git n'existe**. Rien à
  committer, rien à déployer : juste un espace de travail vivant.

Le point commun aux deux : dans les deux cas, ouvrir ce dossier dans Claude Code donne accès à des
agents qui connaissent déjà le métier du dossier, sans qu'il faille le leur réexpliquer à chaque
session.

### Ce que tu trouveras dans n'importe quel lab

Quel que soit le métier, les trois éléments matériels se retrouvent toujours, sous une forme
adaptée :

- **La constitution** — un `CLAUDE.md` court qui répond à trois questions : pourquoi ce lab existe,
  ce qu'il contient, comment on y travaille. C'est le seul document que tout intervenant, humain ou
  agent, doit lire avant de commencer.
- **Les agents** — un ou plusieurs spécialistes du métier du lab, chacun avec un mandat précis. Un
  lab dev en a souvent plusieurs (coder, reviewer, auditeur) ; un lab express fraîchement créé peut
  n'en avoir qu'un ou deux.
- **La mémoire** — des registres qui capitalisent ce qui se décide, s'apprend et se bloque, pour
  qu'un nouvel intervenant comprenne une décision passée en lisant l'entrée correspondante, sans
  devoir reconstituer le contexte de mémoire. Le vocabulaire précis de ces registres est couvert
  dans le glossaire de ce thème.

## Ce qui fait qu'un dossier devient un lab

Avant `/vf-new-lab` ou `/vibeflow-install`, un dossier est juste un dossier — vide, ou porteur de
fichiers quelconques. Ce qui le fait **devenir** un lab, c'est l'écriture effective des trois
éléments ci-dessus par VibeFlow : la constitution, au moins un agent, et l'amorce de mémoire. Un
dossier avec seulement un `CLAUDE.md` griffonné à la main n'est pas encore un lab au sens de
VibeFlow — il lui manque les agents et la mémoire structurée. C'est un critère matériel, pas une
intention : soit les fichiers sont là, soit ils n'y sont pas.

Cette fabrication est décrite en détail, avec l'inventaire exact des fichiers posés sur le disque,
dans le thème `07-sous-le-capot` du présent manuel — cette page-ci ne le duplique pas.

## Lab dev, lab non-dev, et ce qu'un lab n'est pas

**Un lab dev** ajoute une couche que les labs non-dev n'ont pas : le moteur de planning GSD
(`.planning/`), un cycle cadrage → plan → exécution outillé, et une convention où chaque étape se
termine par un commit. Il se distingue par la présence du module `dev-orchestrator` et de ses
dépendances externes, détaillées dans la page suivante de ce thème, consacrée à la relation entre
VibeFlow, GSD et Superpowers.

**Un lab non-dev** (contenu, business, growth, ou un métier sans module dédié) s'appuie sur le
module `planning-core` pour son propre socle de suivi — pas de `.planning/` au format GSD, pas de
notion de commit obligatoire. Le lab de Karim en est un exemple : sa mémoire vit, mais rien n'y
ressemble à un cycle de développement logiciel.

### Un troisième exemple, pour couper court à toute ambiguïté

Le lab de Karim pourrait laisser croire que « lab non-dev » veut dire « lab solo, sans agents
coordonnés ». Ce n'est pas le cas : un lab de contenu qui installe le bundle contenu obtient une
équipe complète — un manager de mission, des agents spécialistes cloisonnés (stratège, rédacteur,
repreneur de contenu), un juge de clarté en lecture seule — sans jamais toucher au moteur GSD ni à
un dépôt git. La complexité d'un lab (combien d'agents, combien de mémoire, quelle coordination)
est donc indépendante de la question dev/non-dev : les deux axes se croisent librement.

**Ce qu'un lab n'est pas :**

- **Un lab n'est pas un projet Claude Code générique.** N'importe quel dossier ouvert dans Claude
  Code est techniquement un « projet » pour l'outil — ça ne le rend pas lab. Un lab est un projet
  *dans lequel VibeFlow a posé sa structure*.
- **Un lab n'est pas un module.** Un module (voir
  [modules-et-bundles.md](./modules-et-bundles.md)) est une capacité que VibeFlow sait installer ;
  un lab est l'endroit où ces capacités sont installées et où elles agissent concrètement.
- **Un lab n'est pas figé.** Il grandit : de nouvelles capacités s'y ajoutent, sa mémoire
  s'épaissit, ses agents se spécialisent. Le mode express de `/vf-new-lab` en pose une version
  minimale volontairement incomplète, pensée pour grandir plus tard.

Retiens la question la plus simple pour trancher : « est-ce qu'un CLAUDE.md, un agent et une
mémoire ont réellement été posés dans ce dossier ? » Si oui, c'est un lab. Si non, c'est un dossier
qui attend de le devenir.

<!-- vf-manual:nav -->
[← Précédent](../01-demarrer/depannage-installation.md) · [↑ Sommaire](../README.md) · [Suivant →](../02-concepts/modules-et-bundles.md)
<!-- /vf-manual:nav -->
