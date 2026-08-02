# L'engine d'installation

<!-- vf-manual:lang -->
**Français** · [English](../../en/07-under-the-hood/the-install-engine.md)
<!-- /vf-manual:lang -->

La page précédente a montré **ce que** l'installation dépose sur ton disque. Celle-ci montre
**comment** elle le fait — pour qui veut auditer avant d'exécuter, ou simplement comprendre
pourquoi une réinstallation ne casse jamais rien. Tout ce qui suit se lit directement dans le
script d'installation lui-même : rien n'est caché derrière une interface.

## Le principe : un scope, une racine, un cache local

Chaque commande d'installation part d'un **scope** explicite (voir
[choisir-son-scope.md](../01-demarrer/choisir-son-scope.md)), qui fixe une seule racine cible pour
toute l'opération. Aucune ambiguïté possible : deux exécutions avec le même scope écrivent
toujours au même endroit.

La source des modules eux-mêmes est un **cache local** préparé par `/vibeflow-install` à partir du
plugin que Claude Code a déjà téléchargé — il n'y a pas de second téléchargement au moment de
l'install, et pas de dépôt git cloné en coulisses. Si ce cache manque, l'installation s'arrête
immédiatement avec une erreur explicite plutôt que d'improviser une source de remplacement.

### Le socle obligatoire

Un module peut être marqué **obligatoire** dans son propre manifeste — c'est le cas du socle de
gouvernance qui héberge les scripts partagés entre modules. Si ce socle venait à manquer sur un lab
déjà configuré (par exemple parce qu'il a été publié après ta première installation), une mise à
jour globale le rattrape automatiquement, avec toute sa fermeture de dépendances. C'est la seule
forme d'ajout automatique que l'engine s'autorise : jamais un module de fonctionnalité que tu
n'aurais pas choisi, seulement le socle sans lequel les autres modules ne peuvent pas fonctionner
correctement.

## Ce que chaque opération garantit

Trois propriétés tiennent quel que soit le module ou le scope :

- **L'idempotence.** Relancer une installation ou une mise à jour sur un module déjà présent ne le
  casse jamais : soit rien ne change parce que la version est identique (auquel cas seule la
  gouvernance — scripts et hooks — est resynchronisée, sans re-copie complète), soit le module est
  remplacé proprement par sa nouvelle version.
- **La sauvegarde avant modification.** Avant d'écraser un module déjà installé, l'engine copie
  d'abord ce qui existe dans un dossier de sauvegarde horodaté, à l'écart de tout ce qui est
  activement utilisé. Une commande de restauration dédiée peut ramener la dernière sauvegarde d'un
  module en un geste, si une mise à jour se passe mal.
- **Le retrait symétrique.** Désinstaller un module ne retire que les fichiers que **ce module**
  possède — jamais un fichier partagé posé par un autre module, même s'ils vivent dans le même
  dossier (`scripts/`, `agents/`, `rules/`). Cette symétrie entre pose et retrait est ce qui rend
  la page précédente de ce thème fiable : l'inventaire qu'elle décrit est exactement ce qu'une
  désinstallation retire, module par module.
- **La fermeture de dépendances, jamais silencieuse.** Installer un module avec ses dépendances
  calcule la liste complète des modules requis avant de poser quoi que ce soit. Si ce calcul ne
  peut pas se faire correctement, l'installation ne continue jamais en silence sur une liste
  incomplète : elle affiche un avertissement visible et explicite plutôt que de risquer un lab à
  moitié équipé sans que tu le saches.

## Ce que VibeFlow n'exécute pas

C'est ici, et nulle part ailleurs dans ce manuel, que vit cette promesse — formulée une seule fois
pour ne jamais être répétée à moitié ailleurs.

**Aucun comportement automatique au démarrage de session n'existe avant que tu n'aies toi-même
choisi de l'installer.** Un module peut déclarer un fragment de configuration qui se déclenche à
certains moments (l'ouverture d'une session, l'édition d'un fichier précis) — mais ce fragment
n'est fusionné dans ta configuration Claude Code **qu'au moment où tu installes ce module**, jamais
avant, et jamais par un module que tu n'as pas choisi. Avant de fusionner quoi que ce soit, l'engine
sauvegarde ta configuration existante — le même filet de sécurité que pour tout le reste. Retirer le
module retire le fragment correspondant, et seulement lui.

Concrètement, ça veut dire trois choses simples à vérifier toi-même : (1) rien ne se déclenche au
démarrage d'une session Claude Code tant qu'aucun module capable de le faire n'est installé ; (2) le
contenu exact de ce qui va se déclencher est lisible en clair, en texte, avant même que tu
installes le module qui le porte ; (3) si tu désinstalles ce module plus tard, ce comportement
disparaît avec lui — rien ne reste accroché à ta configuration.

### Ce que tu peux lire toi-même pour vérifier

L'engine d'installation est un script shell unique, appelé par le skill d'installation — pas un
binaire compilé, pas un service distant. Tout ce que cette page et la précédente affirment se
vérifie en le lisant directement : quels dossiers il crée, quand il sauvegarde, quand il fusionne un
comportement automatique, quand il s'arrête plutôt que d'improviser. Si un mécanisme optionnel (la
génération de commande d'incarnation, la régénération d'un index de référence) est absent de ton
environnement, l'installation continue sans lui plutôt que d'échouer — ces gestes sont annoncés
comme secondaires précisément parce qu'ils ne conditionnent jamais la réussite globale de
l'installation.

Rien de tout ça ne demande un outil spécial : l'engine est un script shell classique, appelable
directement en ligne de commande (statut, installation, mise à jour, désinstallation, restauration)
si tu préfères ce chemin à la conversation en langage naturel. Le lire ne demande que de savoir lire
du shell — aucune connaissance interne à VibeFlow n'est requise pour vérifier ce que ces deux pages
affirment.

Aucun numéro de version n'apparaît dans cette page à dessein (D-11) : consulte le `module.json` d'un
module, ou le `CHANGELOG.md` du dépôt, pour savoir exactement ce qui est actuellement disponible.

Une dernière chose à savoir sur l'esprit de cet engine : il constate, il ne décide jamais à ta
place. Une commande de statut existe pour comparer, module par module, ce qui est installé à ce qui
est disponible — mais elle ne déclenche jamais elle-même une mise à jour. C'est exactement la même
retenue que tu retrouveras dans les gates machine décrites à la page suivante de ce thème : détecter
et afficher un fait, jamais agir dessus sans que tu l'aies demandé.

Retiens la question la plus simple pour trancher si un comportement de l'installation te semble
étrange : « est-ce que ce geste a une trace lisible dans le script, avec une raison écrite à côté ? »
Si oui, ce n'est pas un bug caché — c'est une décision assumée, documentée là où elle s'exécute.
Cette lisibilité est délibérée : un mécanisme d'installation qui ne se comprend qu'en le regardant
tourner ne serait pas auditable, seulement observable.

Rien ici n'est décrit de mémoire, à partir de ce que le comportement était par le passé : chaque
affirmation ci-dessus est vérifiée directement contre le code source actuel du script d'installation
avant que cette page ne soit finalisée, pour qu'elle reste fidèle à ce qui tourne réellement sur ta
machine, pas au comportement d'une release passée. Si jamais un décalage apparaît, le réflexe est de
relire le script, pas de deviner. C'est une meilleure habitude que de faire confiance indéfiniment à
une seule page, y compris celle-ci.

<!-- vf-manual:nav -->
[← Précédent](../07-sous-le-capot/anatomie-d-un-lab-installe.md) · [↑ Sommaire](../README.md) · [Suivant →](../07-sous-le-capot/les-gates-machine.md)
<!-- /vf-manual:nav -->
