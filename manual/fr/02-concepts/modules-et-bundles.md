# Modules et bundles

<!-- vf-manual:lang -->
**Français** · [English](../../en/02-concepts/modules-and-bundles.md)
<!-- /vf-manual:lang -->

VibeFlow s'installe par briques. Cette page définit le vocabulaire de l'installation — module,
socle obligatoire, dépendances, bundle métier, scope — **depuis le disque**, jamais depuis une
description approximative : le catalogue complet des modules a son propre thème
(`03-modules/catalogue.md`), cette page ne le recopie pas et ne porte aucun numéro de version.

## Module, socle, dépendances

Un **module** est une unité installable : un dossier sous `plugin/` qui porte son propre
`module.json` (nom, version, description, dépendances). C'est l'unité que tu actives ou
désactives — chaque module ajoute une capacité précise (une équipe d'agents, un skill, un
outillage de vérification) sans toucher aux autres.

Le champ `module.json` qui compte le plus est `requires` : la liste des autres modules dont celui-ci
a besoin pour fonctionner. Par exemple, le module `conductor` — la porte d'entrée de tout lab —
déclare `requires: [planning-core, validator, skill-creator]`. Installer `conductor` entraîne donc
mécaniquement ces trois modules, sans que tu aies à les demander toi-même : l'installeur résout la
**fermeture transitive** des `requires` et te récapitule ce qui va être posé avant de le faire.

Un seul module porte aujourd'hui `"mandatory": true` : `conductor`. C'est le **socle obligatoire**
d'un lab — sans lui (et donc sans ses dépendances), il n'y a pas de lab au sens de
[qu-est-ce-qu-un-lab.md](./qu-est-ce-qu-un-lab.md). Tous les autres modules sont optionnels : tu
choisis ceux qui correspondent à ton métier.

### La fermeture transitive, en pratique

La résolution ne s'arrête pas au premier niveau. `conductor` requiert `validator` ; `validator`
requiert à son tour `consolidator`, `infrastructure-audit` et `audit-architecture`. Installer
`conductor` seul pose donc, en réalité, sept modules sur le disque — jamais un de plus, jamais un
de moins que ce que la chaîne des `requires` déclare. Tu n'as jamais à calculer cette chaîne
toi-même : le résolveur de l'installeur la parcourt et t'annonce la liste complète **avant**
d'écrire quoi que ce soit, pour que tu saches ce qui arrive sur ton disque.

### Obligatoire ne veut pas dire suffisant

Le socle obligatoire donne un lab **capable de se gouverner** — créer, vérifier, mettre à jour —
mais pas encore un lab productif dans un métier donné. `planning-core`, par exemple, fait partie du
socle : il porte le suivi à l'altitude lab, quel que soit le métier. Mais un lab dev n'en tire sa
vraie capacité de production qu'en ajoutant `dev-orchestrator` par-dessus ; un lab business,
qu'en ajoutant `business-pilot-bundle`. Le socle est la fondation commune à tous les labs, pas la
capacité qui les distingue les uns des autres.

## Bundle métier

Un **bundle** est un module particulier : au lieu d'ajouter une seule capacité, il pose une
**équipe complète** prête à l'emploi pour un métier donné — un manager de mission, plusieurs
agents spécialistes cloisonnés, un juge de qualité en lecture seule, et un skill d'entrée simple.
Trois bundles existent aujourd'hui : business, contenu, growth. Chacun déclare dans son
`module.json` les mêmes dépendances de fond (`conductor`, `planning-core`, `consolidator`,
`audit-architecture`, `validator`) — un bundle s'installe **sur** le socle, jamais à sa place.

Un module ordinaire ajoute une capacité ponctuelle (par exemple, `mobile-test` sait faire tourner
une app sur simulateur). Un bundle ajoute une **organisation de travail** — plusieurs agents qui se
coordonnent entre eux sur une mission longue, avec verrou de driver et rapports typés (ce que ça
garantit à l'utilisateur est détaillé plus loin dans ce thème, dans la page sur les gates et la
validation humaine).

### Une loi de fer par bundle

Chaque bundle porte au moins une règle non négociable, appliquée par son juge frais plutôt que
laissée à la bonne volonté d'un agent : le bundle business n'envoie **jamais** rien au client sans
validation humaine et n'invente **jamais** un chiffre financier ; le bundle growth bloque tout
envoi réel derrière le même geste humain et refuse toute campagne dont un chiffre n'est pas
sourcé ; le bundle contenu ne distribue rien sans validation humaine non plus. Ce ne sont pas des
promesses en prose — ce sont des critères éliminatoires dans la rubric du juge de chaque bundle,
qui fait échouer le livrable quel que soit le reste du score.

### Le scope, une notion indépendante

Le **scope** est indépendant du choix des modules : c'est **où** VibeFlow écrit ce qu'il installe
(compte, projet, ou projet sans commit). Le même jeu de modules peut être posé à trois scopes
différents pour trois labs différents — le scope ne change pas *quoi* tu installes, seulement *où*
ça atterrit. Le détail des trois scopes et comment choisir est couvert dans
[choisir-son-scope.md](../01-demarrer/choisir-son-scope.md), pas ici.

## Ce que cette page ne fait pas

Volontairement : pas de tableau des modules existants (le catalogue vit ailleurs et se dérive du
disque à chaque lecture, jamais recopié — treize versions sur dix-sept étaient déjà périmées dans
l'ancien README au moment d'écrire cette page, la preuve que recopier une version est une dette
qui se paie). Pas de numéro de version en dur : cette page pointe vers `module.json` et
`CHANGELOG.md` de chaque module pour l'information à jour.

Si tu veux savoir précisément ce qu'un module fait avant de l'installer, la source la plus fiable
reste son propre `README.md` sous `plugin/<module>/` — pas un tableau récapitulatif ailleurs dans
le repo, aussi tentant soit-il à lire d'un coup d'œil. Un README de module peut se mettre à jour
sans que rien d'autre n'ait besoin de suivre.

C'est le même réflexe qui doit guider ta lecture de ce manuel lui-même : chaque fois qu'une
information peut se périmer (une version, un compte de modules, une liste), ce manuel préfère
pointer vers le disque plutôt que la figer dans une phrase — le disque a toujours raison ; un
chiffre recopié, tôt ou tard, ne l'a plus.

<!-- vf-manual:nav -->
[← Précédent](../02-concepts/qu-est-ce-qu-un-lab.md) · [↑ Sommaire](../README.md) · [Suivant →](../02-concepts/agents-skills-commandes.md)
<!-- /vf-manual:nav -->
