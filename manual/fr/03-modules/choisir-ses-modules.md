# Choisir ses modules

<!-- vf-manual:lang -->
**Français** · [English](../../en/03-modules/choosing-your-modules.md)
<!-- /vf-manual:lang -->

Le [catalogue](./catalogue.md) te dit ce qui existe. Cette page te dit **quoi prendre**, selon ce
que tu fais. C'est un guide de décision, pas une liste : tu devrais en sortir avec une composition
assumée et la raison qui va avec.

Une chose que cette page ne traite pas : **où** VibeFlow écrit ce qu'il installe. C'est le scope,
une question indépendante du choix des modules, et elle a sa propre page —
[choisir-son-scope.md](../01-demarrer/choisir-son-scope.md). Tu peux poser exactement la même
composition à trois scopes différents.

Rappel utile avant de composer : le socle arrive de toute façon. Les sept modules décrits en
[socle-et-dependances.md](./socle-et-dependances.md) sont posés sans que tu les demandes. Tout ce
qui suit s'ajoute **par-dessus**.

## Quatre profils, quatre compositions

**Tu codes seul, sur tes projets.** Prends `dev-orchestrator` et rien d'autre au départ. Il
entraîne `design-orchestrator` avec lui, ce qui te donne déjà le cycle complet — cadrage, plan,
exécution, revue — plus la capacité de traiter une phase d'interface sans changer d'outil. Ajoute
`software-architecture` dès que ton projet dépasse quelques fichiers : c'est le module qui
t'empêche de laisser grossir une god class pendant six semaines. Ce que tu ne prends pas : les
bundles métier, qui poseraient des équipes d'agents que tu n'appelleras jamais.

**Vous êtes plusieurs sur un dépôt partagé.** Même base que ci-dessus, avec deux différences de
posture. D'abord le scope : installe au niveau du projet pour que la configuration soit versionnée
avec le code et identique pour tout le monde — c'est la seule façon d'éviter que chacun ait son
propre VibeFlow légèrement différent. Ensuite, ne néglige pas le `consolidator` : à plusieurs, les
registres de décisions et d'apprentissages deviennent le seul endroit où l'historique du
« pourquoi » survit au départ d'une personne. Il arrive avec le socle, mais il ne sert que si vous
l'appelez.

**Tu tiens un lab non-dev — contenu, vente, acquisition.** Ne prends aucun orchestrateur de dev.
Prends le bundle qui correspond à ton métier, un seul : `content-bundle`, `business-pilot-bundle`
ou `growth-bundle`. Chacun pose une équipe complète et un juge de qualité — le détail est en
[bundles-metier.md](./bundles-metier.md). Ajoute `kpi-analyst` seulement quand tu as déjà de la
matière à mesurer : posé trop tôt, il n'a rien à lire et ne produit qu'un tableau vide.

**Tu veux juste voir à quoi ça ressemble.** Ne prends rien de plus que le socle. Il suffit à créer
un lab, à le faire vérifier, à comprendre la structure `.planning/` et le geste de mise à jour. Tu
ajouteras un orchestrateur quand tu sauras ce que tu veux lui demander — l'ajout après coup est
une opération banale, traitée en [activer-desactiver.md](./activer-desactiver.md).

**Un cas particulier, si tu fais du mobile.** `mobile-test` et `mobile-test-team` existent et
fonctionnent, mais leurs propres `module.json` les déclarent **expérimentaux** : ils attendent leur
premier run réellement vert pour perdre ce statut. Concrètement, ça veut dire que tu peux les
essayer, mais ne construis pas ton processus de livraison autour d'eux avant de les avoir vus
tourner sur ton projet à toi. Un module expérimental n'est pas un module cassé — c'est un module
dont la promesse n'a pas encore été vérifiée en conditions réelles assez souvent.

### Comment savoir qu'il te manque quelque chose

Tu n'as pas à anticiper. Le signal est presque toujours le même : tu demandes quelque chose à ton
lab, et il te répond correctement mais **à la main**, en improvisant, au lieu de dérouler un geste
outillé. Un lab qui te propose de « regarder les fichiers un par un » là où un module aurait
produit un rapport structuré, c'est un lab à qui il manque ce module.

Le second signal est la répétition. Si tu réexpliques la même contrainte de qualité à chaque
livrable — « source tes chiffres », « ne publie pas sans me montrer » — c'est qu'un juge ferait ce
travail mieux que toi, et un bundle en porte un.

## Pourquoi ne pas tout installer

C'est la question qu'on se pose toujours, et la réponse n'est pas « pour économiser de l'espace
disque » — les modules pèsent quelques centaines de kilo-octets.

La vraie raison est le **routage**. Chaque module pose des agents et des skills, et chacun décrit
en langage naturel les situations où il doit se déclencher. Plus tu en poses, plus ces
descriptions se ressemblent et se chevauchent, et plus le risque augmente qu'une demande parte
vers la mauvaise brique. Un lab qui porte les trois bundles métier plus les deux orchestrateurs
doit arbitrer entre beaucoup plus de candidats à chaque phrase que tu tapes. Les modules que tu
n'utilises pas ne sont pas neutres : ils sont du bruit dans la décision.

La deuxième raison est la **charge de compréhension**. Un lab que tu as composé toi-même, module
par module, tu sais l'expliquer. Un lab où tout est coché, tu ne sais plus qui a produit quoi le
jour où un résultat te surprend — et c'est précisément le jour où tu as besoin de le savoir.

La troisième est la **maintenance**. Chaque module posé est un module à faire évoluer quand
VibeFlow bouge. Retirer un module que tu n'utilises pas est un geste sain, pas un aveu d'échec — et
[activer-desactiver.md](./activer-desactiver.md) montre que ça tient en une commande, avec une
sauvegarde prise avant toute suppression.

Le bon réflexe, donc : pars petit, ajoute quand un manque se fait sentir. VibeFlow est conçu pour
que l'ajout après coup soit trivial — bien plus trivial que de démêler un lab surchargé.

Une dernière chose, qui rassure : **ce choix n'est pas définitif**. Aucune des compositions
proposées plus haut ne t'engage. Ajouter un module la semaine prochaine, en retirer un le mois
suivant, changer complètement d'orientation parce que ton projet a changé — tout cela se fait en
une commande, avec sauvegarde, et sans perdre le contenu de ton lab. Le travail que tu as accumulé
dans `.planning/` appartient au lab, pas aux modules ; il survit à leurs allées et venues.

Alors ne passe pas une heure à optimiser cette décision. Prends le profil qui te ressemble le plus,
commence à travailler, et ajuste quand la réalité t'aura appris quelque chose que cette page ne
pouvait pas t'apprendre.

<!-- vf-manual:nav -->
[← Précédent](../03-modules/socle-et-dependances.md) · [↑ Sommaire](../README.md) · [Suivant →](../03-modules/bundles-metier.md)
<!-- /vf-manual:nav -->
