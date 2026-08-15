# Catalogue des modules

<!-- vf-manual:lang -->
**Français** · [English](../../en/03-modules/catalog.md)
<!-- /vf-manual:lang -->

Cette page liste les modules livrés par VibeFlow, avec pour chacun **ce qu'il t'apporte** — pas ce
qu'il contient. Elle a été écrite en lisant les fichiers `module.json` présents sur le disque, un
par module : c'est la seule source qui ne se périme pas. Tu peux refaire la même lecture toi-même
à tout moment, et c'est même conseillé si tu lis ces lignes longtemps après leur écriture.

Ce que tu ne trouveras **pas ici** : des numéros de version. Aucun. Le manuel n'en cite jamais,
par construction — la raison est expliquée dans [ou-vit-un-module.md](./ou-vit-un-module.md), qui
te dit aussi où lire la version réelle d'un module en trois secondes.

Si le vocabulaire (module, socle, bundle, scope) n'est pas encore clair, commence par
[modules-et-bundles.md](../02-concepts/modules-et-bundles.md) — cette page-ci suppose ces mots
acquis.

## Le socle de gouvernance et ses auditeurs

Ces sept modules forment le socle : `conductor` est le seul déclaré obligatoire, les six autres
arrivent avec lui par la chaîne des dépendances. Ils ne produisent rien pour ton métier — ils
donnent au lab de quoi se créer, se vérifier et se réparer. Le détail de qui entraîne qui est en
[socle-et-dependances.md](./socle-et-dependances.md).

- **`conductor`** — la porte d'entrée. C'est lui que tu appelles pour créer un lab, ajouter ou
  retirer un module, vérifier que tout est cohérent, ou recaler un lab après une évolution de
  VibeFlow. Il ne fait pas ton travail métier : il tient la maison.
- **`planning-core`** — le socle de suivi. Il pose la structure `.planning/` qui fait qu'une
  session peut reprendre là où la précédente s'est arrêtée : charte du projet, exigences,
  trajectoire, état, étapes. Il s'adapte au métier du lab au lieu d'imposer un gabarit de dev.
- **`validator`** — l'auditeur en chef. Tu l'appelles quand tu veux savoir si ton lab est encore
  aligné avec la méthode : il orchestre cinq audits complémentaires et te propose des corrections,
  sans jamais les appliquer tout seul.
- **`skill-creator`** — la fabrique de capacités. Quand un geste revient trop souvent dans ton
  travail, ce module t'aide à en faire un skill propre, testé, réutilisable.
- **`consolidator`** — la mémoire du lab. Il range les registres de décisions, d'apprentissages et
  de blocages pour qu'ils restent lisibles et consultables au lieu de gonfler jusqu'à devenir
  illisibles.
- **`infrastructure-audit`** — le garde-fou technique. Il détecte les régressions silencieuses :
  un hook cassé après une mise à jour de Claude Code, un script disparu, une convention Anthropic
  qui a bougé sous tes pieds.
- **`audit-architecture`** — le concepteur de structures d'audit. Chaque fois qu'un process
  transforme un brief en livrable, ce module en dérive la structure de contrôle adaptée, quel que
  soit le métier.

## Les orchestrateurs et les équipes métier

Ici commence la production. Ces cinq modules sont ceux qui font vraiment le travail — tu en
installes un, deux, ou aucun selon ton métier.

- **`dev-orchestrator`** — le cycle de développement complet. Tu parles en langage naturel
  (« code ça », « on est où », « fais tout en autonomie ») et l'orchestrateur route vers le bon
  geste. Il embarque aussi l'équipe de mission dev, capable de tenir une mission longue seule. Un
  thème entier du manuel lui est consacré, plus loin.
- **`design-orchestrator`** — la même idée pour le design et l'UI. Définir une direction
  artistique, refondre un écran, critiquer une page, ou corriger un détail de typo. Il produit des
  specs génériques plutôt que du code verrouillé sur un framework. `dev-orchestrator` en dépend :
  installer le dev entraîne le design.
- **`content-bundle`** — l'équipe éditoriale : cadrage, rédaction, déclinaison, avec un juge de
  clarté qui refuse une pièce faible. Rien n'est jamais publié sans ton accord.
- **`business-pilot-bundle`** — l'équipe business : pipeline commercial, delivery, facturation,
  avec un gate qualité sur les livrables client. Rien n'est jamais envoyé sans ton accord, et
  aucun chiffre financier n'est inventé.
- **`growth-bundle`** — l'équipe acquisition : choix de canal, séquences, créatives, mesure. Tout
  envoi réel reste derrière ton geste, et une campagne dont un chiffre n'est pas sourcé échoue au
  juge.

Les trois bundles ont leur page dédiée : [bundles-metier.md](./bundles-metier.md). Lequel choisir,
et s'il faut seulement en choisir un, c'est le sujet de
[choisir-ses-modules.md](./choisir-ses-modules.md).

## Les capacités spécialisées et la documentation

Ces six-là s'ajoutent au cas par cas. Deux d'entre eux portent un **statut expérimental** déclaré
dans leur propre `module.json` — c'est dit ici parce que ça change ce que tu peux en attendre.

- **`software-architecture`** — la doctrine d'architecture. Elle s'invoque quand tu crées ou
  modifies du code, quand un fichier grossit, ou quand tu sens une dette structurelle. Elle
  embarque des garde-fous mécaniques, pas seulement des conseils.
- **`kpi-analyst`** — les vrais indicateurs d'un lab. Il déduit un schéma d'indicateurs, valide ce
  schéma une fois avec toi, puis en extrait les valeurs de façon déterministe. Aucun chiffre n'est
  inventé : une valeur introuvable reste marquée comme introuvable.
- **`mobile-test`** *(expérimental)* — faire tourner pour de vrai une app mobile sur simulateur ou
  émulateur, jouer une régression et rendre un rapport avec captures. « Expérimental » signifie ici
  que le module attend son premier run réellement vert pour perdre ce statut.
- **`mobile-test-team`** *(expérimental)* — la boucle autonome au-dessus du précédent : teste,
  corrige, re-teste jusqu'au vert ou jusqu'à épuisement du budget. Il dépend de `mobile-test`.
- **`reference`** — le module de documentation. Il ne pose ni agent ni script : il apporte la
  méthodologie VibeFlow et ses patterns d'architecture, à lire quand tu veux comprendre *pourquoi*
  le framework est fait comme ça.
- **`vf-cockpit`** — une page web locale qui affiche en direct le `.planning/` du lab courant :
  les phases du milestone, les plans de la phase active, et le DAG de l'équipe en mission avec son
  driver lock. Strictement en lecture seule, aucun accès réseau au-delà de `127.0.0.1`.

Une précision utile pour ta lecture : ces modules **ne partagent pas tous la même structure de
documentation**. La plupart ont un `README.md`, un `CHANGELOG.md` et un `VERSION` au même endroit,
mais quelques-uns s'en écartent — dont, ironiquement, deux des plus structurants. Ne pars donc pas
du principe qu'un fichier trouvé chez l'un existe forcément chez l'autre ; regarde le dossier du
module, il te dira ce qu'il porte. C'est le dossier, pas cette page, qui a le dernier mot.

<!-- vf-manual:nav -->
[← Précédent](../02-concepts/glossaire.md) · [↑ Sommaire](../README.md) · [Suivant →](../03-modules/socle-et-dependances.md)
<!-- /vf-manual:nav -->
