# Équipes spécialisées

<!-- vf-manual:lang -->
**Français** · [English](../../en/05-agent-team/specialized-teams.md)
<!-- /vf-manual:lang -->

Tout ce que tu as lu jusqu'ici décrivait la mécanique commune — le team-kernel, réutilisé partout.
Cette page dit ce que ça donne concrètement au-delà du développement : trois autres domaines où
VibeFlow déploie une équipe plutôt qu'un seul agent. Le catalogue détaillé des modules qui les
posent vit dans [bundles-metier.md](../03-modules/bundles-metier.md) — ici, il s'agit de comment
ces équipes **fonctionnent**, pas de ce que chacune livre en détail.

## L'équipe design

Dès qu'un lab a une interface à concevoir, améliorer ou critiquer, l'agent `vibeflow-design` route
ta demande — dire « c'est moche », « on part sur quel style ? » ou « refais toute l'app » suffit,
tu n'as pas besoin de connaître le nom des étapes internes. Sur un chantier assez large, il déploie
une équipe : `vf-design-manager` planifie en DAG et dispatche `vf-crafter` (production d'écrans) et
`vf-design-judge` (critique scorée) en parallèle sur des écrans qui ne se recoupent pas.

Le « vert » de cette équipe a un seuil chiffré : un écran doit atteindre au moins 70 sur 100 contre
la direction artistique du lab pour passer, avec un plafond de trois tours de correction par écran
avant escalade. C'est le même principe de juge frais que partout ailleurs dans VibeFlow, appliqué
ici écran par écran plutôt qu'à la mission entière.

**Statut réel** : ce module est installé d'office avec `dev-orchestrator` sur tout lab de
développement, sans action supplémentaire de ta part. Il n'est pas marqué expérimental — c'est une
brique mature du socle dev.

Un détail qui compte pour toi : cette équipe produit des **specs et des tokens**, adaptés à la stack
détectée de ton projet (variables CSS, tokens Swift, objet de thème React Native ou Flutter selon
le cas), jamais du code framework imposé de force. La chaîne d'outils réelle qui travaille en
coulisse — référentiel UX, atelier de craft — reste invisible côté utilisateur : tout ce qu'elle
produit est reformulé dans le vocabulaire de VibeFlow avant de t'arriver, et le module dégrade
proprement sur les premiers principes de design si un outil tiers venait à manquer plutôt que
d'échouer sans explication.

## L'équipe de recette mobile

Un écran peut compiler, passer ses tests unitaires, et malgré ça crasher au runtime sur un vrai
téléphone. Deux modules distincts couvrent ce manque, et il faut connaître la frontière entre eux.

Le premier, `mobile-test`, est la **mécanique** : un script déterministe qui détecte la cible
(simulateur iOS ou émulateur Android), build si besoin, joue une régression Maestro, et diagnostique
visuellement les échecs. Le second, `mobile-test-team`, est la **boucle autonome** posée par-dessus :
`vf-test-orchestrator` pilote le cycle test → corrige → re-test, avec `vf-test-runner` et
`vf-app-fixer` cloisonnés l'un de l'autre — celui qui corrige le code applicatif ne touche jamais aux
tests, et inversement. C'est ce cloisonnement qui empêche la triche la plus tentante : affaiblir un
test pour le faire passer plutôt que de corriger le vrai problème.

Tu sollicites cette équipe soit directement par son skill, soit indirectement : une rule dédiée se
réveille toute seule dès que tu modifies du code d'écran mobile ou un flow Maestro, et rend active la
doctrine de vérification réelle pendant que tu développes.

**Statut réel, à ne pas maquiller** : les deux modules sont **explicitement expérimentaux**, et leur
propre documentation le dit sans détour. Le pipeline mécanique a été conçu et validé en conditions
réelles sur son projet d'origine, mais **aucun run réel vert n'a encore été tracé dans un contexte
VibeFlow** — c'est précisément la condition de sortie de ce statut. La boucle autonome porte un
risque supplémentaire, nommé tel quel par ses propres auteurs : un sous-agent qui en pilote d'autres
via des dispatches imbriqués n'a pas encore été prouvé par un run réel de bout en bout. Tant que ces
runs n'existent pas, considère les deux modules comme une base solide **à confirmer**, pas comme un
mécanisme éprouvé au même titre que l'équipe design ou les équipes métier ci-dessous.

Un prérequis pratique, propre à cette équipe : elle exige un fichier de configuration par projet
(bundle id, nom de l'émulateur Android, simulateur iOS préféré) — aucune valeur n'est codée en dur,
et le script refuse de tourner tant que cette configuration n'existe pas plutôt que de deviner. C'est
volontaire : une supposition fausse sur la cible produirait un rapport de test qui a l'air valide
sans l'être.

## Les équipes métier

Au-delà du code et du design, trois bundles posent une équipe complète pour un métier donné :
contenu, pilotage commercial, acquisition. Toutes les trois reposent sur la même ossature — un
manager qui planifie et distribue, des workers cloisonnés qui produisent chacun leur part, un juge
frais qui note le résultat sans avoir vu sa fabrication — et toutes les trois portent au moins une
règle éliminatoire dans leur grille de notation : un chiffre non sourcé ou une donnée financière
inventée fait échouer un livrable, quel que soit le reste de son score.

Chaque bundle a une chaîne différente — la chaîne éditoriale du contenu n'est pas celle du pilotage
commercial — mais l'ossature commune signifie que lire un rapport de mission de l'un te prépare à
lire celui d'un autre : mêmes rôles, même vocabulaire, mêmes points d'arrêt.

Ce qui vaut d'être répété ici, parce que c'est le point qui distingue une équipe métier d'un simple
paquet de prompts bien écrits : **rien ne part sans toi.** Aucun de ces bundles n'envoie, ne publie
ni ne lance quoi que ce soit vers l'extérieur. Le lab prépare le livrable, le juge le valide, et il
est marqué « prêt » — c'est toi qui l'envoies, depuis tes propres outils, avec tes propres
identifiants. Tu les sollicites par un skill au nom du métier (`vf-content`, `vf-business`,
`vf-growth`), en langage naturel, exactement comme pour une mission de développement.

**Statut réel** : les trois bundles sont des modules stables, pas expérimentaux — leur validation
ne dépend pas d'un run à venir, contrairement à l'équipe de recette mobile ci-dessus. Le détail de ce
que chacun livre, agent par agent, est dans
[bundles-metier.md](../03-modules/bundles-metier.md).

Une équipe n'est jamais présentée à égalité avec une autre si leur statut réel diffère. C'est
volontaire : savoir qu'un module est encore à confirmer change la façon dont tu lis ses rapports, et
te taire cette différence produirait un manuel qui promet plus que le produit ne tient.

Un lab peut installer plusieurs de ces équipes sans conflit — chacune déclare ses propres dépendances
de fond par-dessus le même socle — mais rien ne t'oblige à toutes les poser d'entrée. Une équipe
posée sur un lab qui n'a pas encore le contenu de cadrage nécessaire (positionnement, ton de voix,
direction artistique) produira du travail générique ; ce n'est pas un défaut de l'équipe, c'est un
manque de matière à lui donner, et ça se corrige en nourrissant le lab plutôt qu'en changeant de
module.

La même lecture s'applique aux quatre équipes de cette page : ce qu'elles peuvent faire est fixé
par leur conception, mais la qualité de ce qu'elles produisent dépend toujours de ce que tu as
raconté au lab sur ton activité avant de les lancer.

<!-- vf-manual:nav -->
[← Précédent](../05-equipe-agents/branches-et-worktrees.md) · [↑ Sommaire](../README.md) · [Suivant →](../06-reference/commandes.md)
<!-- /vf-manual:nav -->
