# Les agents livrés

<!-- vf-manual:lang -->
**Français** · [English](../../en/05-agent-team/the-agents-that-ship.md)
<!-- /vf-manual:lang -->

Cette page est l'inventaire des agents que VibeFlow peut poser dans ton lab. Elle a été construite
en listant les fichiers d'agents présents sur le disque, module par module — pas en recopiant une
liste écrite ailleurs. Tu n'auras que ceux dont tu as installé le module ; le
[catalogue](../03-modules/catalogue.md) dit lequel apporte quoi.

Trois familles, et la différence entre elles compte plus que les noms. À la date où cette page a
été écrite, le disque de ce dépôt en porte trente-et-un au total, répartis dans ces trois familles —
un chiffre qui bouge à chaque module ajouté, jamais figé ici comme une promesse.

## Les agents que tu invoques

Ce sont les « visages » de VibeFlow. Chacun est le sommet d'un module, et tu peux lui parler
directement — soit en le nommant, soit simplement en formulant une demande qui relève de son
domaine.

- **`vibeflow-conductor`** — le gardien du lab. Créer un lab, installer ou retirer un module,
  vérifier la conformité, recaler après une mise à jour. Tout ce qui touche la configuration du lab
  lui-même passe par lui.
- **`vibeflow-dev`** — le routeur de développement. Il détecte ce que ta phrase appelle et invoque
  la brique correspondante. C'est l'interlocuteur par défaut de tout le
  [cycle de dev](../04-cycle-de-dev/le-cycle-en-bref.md).
- **`vibeflow-design`** — le même rôle pour le design et l'UI, de la direction artistique au détail
  de spacing.
- **`vibeflow-validator`** — l'auditeur. Il orchestre plusieurs audits complémentaires et te propose
  des remédiations, sans jamais les appliquer seul.
- **`vibeflow-kpi-analyst`** — les indicateurs réels du lab, extraits de façon déterministe.
- **`skill-creator`** — la fabrique de skills, quand un geste mérite de devenir une capacité.

Tu n'as pas à retenir ces noms. Ils sont là pour que tu saches à qui tu parles quand tu lis un
rapport, et pour les rares fois où tu veux court-circuiter le routage et t'adresser directement à
l'un d'eux.

## Les managers de mission

Une catégorie à part : ils pilotent une mission longue mais ne se convoquent pas comme les
précédents. C'est le mode autonome, ou le routeur du domaine, qui décide de les déployer quand la
taille du travail le justifie.

Il en existe un par domaine outillé : **`vf-dev-manager`** pour le développement,
**`vf-design-manager`** pour le design, **`vf-content-manager`**, **`vf-business-manager`** et
**`vf-growth-manager`** pour les trois métiers, et **`vf-test-orchestrator`** pour la boucle de
recette mobile.

Ce qu'ils ont tous en commun : ils **ne produisent rien eux-mêmes**. Ils planifient, distribuent,
lisent les rapports, et rendent compte. Si tu vois un manager écrire du code, c'est un bug, pas une
optimisation.

Chacun de ces six managers instancie le même noyau d'orchestration — verrou de driver, graphe de
mission, rapports typés — plutôt que de réinventer sa propre coordination d'équipe. C'est pour ça
qu'un rapport de mission design se lit comme un rapport de mission dev une fois qu'on a compris le
vocabulaire commun, détaillé dans le [glossaire](../02-concepts/glossaire.md).

## Les workers internes, et pourquoi tu ne peux pas les appeler

C'est la famille la plus nombreuse — une bonne vingtaine d'agents — et la seule que tu ne peux pas
invoquer. Ce sont les producteurs et les juges : celui qui écrit le code d'une étape, celui qui la
relit, celui qui audite la sécurité, celui qui rédige un contenu, celui qui le note, celui qui joue
les tests sur un simulateur, celui qui corrige l'application pour les faire passer.

Chacun de ces agents déclare dans son propre fichier qu'il est **interne**. La conséquence est
mécanique : aucune commande d'incarnation n'est générée pour lui. Tu ne trouveras pas de
`/vf-coder` dans ton lab, et ce n'est pas un oubli.

La raison est simple. Un worker interne reçoit son mandat d'un manager : un périmètre précis, un
résumé de contexte taillé pour lui, et un contrat de rapport. Invoqué directement, il n'aurait rien
de tout ça — il partirait sans savoir où il est dans le plan d'ensemble, sans savoir ce qu'il ne
doit pas toucher, et son rapport n'irait à personne. Le résultat serait moins bon qu'un simple
échange conversationnel, tout en ayant l'air plus sérieux.

Deux catégories méritent d'être nommées parmi eux, parce que tu verras leur nom dans les rapports :

**Les juges de qualité.** Chaque équipe métier en porte un — pour le contenu, pour les livrables
client, pour les campagnes — auxquels s'ajoutent le juge de design et, côté dev, le relecteur de
code et l'auditeur de sécurité. Tous découvrent le travail fini sans avoir vu sa fabrication, et
les juges de qualité n'ont pas d'outils d'écriture : ils ne peuvent pas corriger ce qu'ils
critiquent.

**Les workers cloisonnés.** Dans la boucle de recette mobile, par exemple, celui qui écrit les
tests ne touche jamais au code de l'application, et celui qui corrige l'application ne touche
jamais aux tests. Ce cloisonnement empêche la triche la plus tentante qui soit : faire passer un
test en l'affaiblissant.

Si tu veux savoir précisément ce qu'un agent a le droit de faire, ouvre son fichier dans le dossier
`agents/` de son module. C'est un texte lisible, et il dit noir sur blanc ce qui lui est interdit.

Cette liste n'est jamais recopiée depuis un README ou une doc marketing : elle vient du disque, à
chaque fois qu'elle est vérifiée. C'est délibéré (D-11) — un module retiré fait disparaître ses
agents de ton lab immédiatement, et rien dans ce manuel ne doit prétendre le contraire plus
longtemps qu'il ne le faut.

C'est aussi pour ça que cette page n'accole aucun numéro de version à un agent : le comportement
d'un agent, c'est ce que dit son fichier sur le disque à l'instant où tu le lis, pas ce qu'une
entrée de changelog a pu décrire un jour.

La page suivante prend le relais là où celle-ci s'arrête : elle montre comment ces trois familles se
mettent réellement au travail sur une mission longue — et ce que ça change pour toi pendant qu'elle
tourne.

Garde cet inventaire sous la main en la lisant : ce sont ces noms-là qu'un rapport de mission
citera.

<!-- vf-manual:nav -->
[← Précédent](../05-equipe-agents/pourquoi-une-equipe.md) · [↑ Sommaire](../README.md) · [Suivant →](../05-equipe-agents/une-mission-longue.md)
<!-- /vf-manual:nav -->
