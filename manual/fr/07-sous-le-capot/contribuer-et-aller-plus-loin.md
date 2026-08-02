# Contribuer et aller plus loin

<!-- vf-manual:lang -->
**Français** · [English](../../en/07-under-the-hood/contributing-and-going-further.md)
<!-- /vf-manual:lang -->

Cette page ferme le manuel. Elle ne t'apprend plus rien sur l'usage de VibeFlow — les six thèmes
précédents ont couvert ça — elle te dit plutôt comment lire le dépôt lui-même si tu veux comprendre
plus profondément, contribuer, ou simplement signaler quelque chose qui ne va pas. Trois questions
la structurent : comment lire ce dépôt, ce que contiennent ses dossiers internes, et par où sortir
de ce manuel une fois que tu l'as fini.

## Lire ce dépôt pour comprendre ou contribuer

Le dépôt VibeFlow est organisé en deux publics distincts, et ce manuel appartient au premier :

- **Ce manuel, et le `README` du dépôt**, s'adressent à toi — un humain qui installe et utilise
  VibeFlow. Tout y est écrit en phrases complètes, sans jargon non défini.
- **`docs/` et `.planning/`**, à l'inverse, sont la mémoire de travail des agents et des
  contributeurs du dépôt lui-même — pas les tiens, ceux qui font évoluer VibeFlow. Tu n'as
  normalement jamais besoin de les ouvrir pour utiliser le produit ; la page
  [ou-trouver-quoi.md](../06-reference/ou-trouver-quoi.md) explique déjà pourquoi en détail.

Si malgré tout tu veux lire le code source d'un module, d'un agent ou d'un gate, rien ne t'en
empêche : chaque module vit sous `plugin/<nom-du-module>/`, avec son propre historique de version.
C'est exactement la matière que les pages précédentes de ce thème t'ont déjà montré comment lire —
l'engine d'installation, les gates, la doctrine — cette page n'ajoute rien de nouveau à cette
méthode, elle en confirme juste la généralité : tout ce qui s'exécute chez toi est lisible avant de
s'exécuter.

### Contribuer, concrètement

Contribuer à VibeFlow ne demande pas de connaître son fonctionnement interne dans le détail avant de
commencer — la même doctrine qui structure tes propres labs structure ce dépôt : chaque module a son
propre historique de version et son propre périmètre, les gates qui protègent ton code protègent
aussi celui du dépôt lui-même, et une modification suit le même cycle que celui décrit dans le thème
[Cycle de développement](../04-cycle-de-dev/le-cycle-en-bref.md) — cadrer, planifier, exécuter,
livrer. Un bon point de départ, si tu veux proposer un changement, est de commencer petit : une
correction de doc, un skill isolé, avant un changement d'architecture plus large.

## Ce que sont `docs/` et `.planning/`

Pour être précis sur ce que ces deux dossiers contiennent, sans jamais te demander de les ouvrir :

- **`docs/`** porte le registre des décisions d'architecture du dépôt — la source complète derrière
  la page précédente de ce thème — ainsi que la bibliothèque méthodologique et des spécifications
  techniques internes. C'est une mémoire à destination de qui conçoit VibeFlow, pas de qui l'utilise,
  même si rien n'y est confidentiel.
- **`.planning/`** est la mémoire de travail du moteur de planification qui pilote le développement
  du dépôt lui-même — feuille de route, état d'avancement, exigences, phases en cours. C'est
  exactement le même type de dossier que celui qu'un **lab dev** que tu crées avec VibeFlow obtient
  pour son propre projet (voir
  [vibeflow-gsd-superpowers.md](../02-concepts/vibeflow-gsd-superpowers.md)) — sauf que celui-ci
  documente le développement de VibeFlow, pas le tien.

Ces deux dossiers restent lisibles si la curiosité te prend — rien n'y est caché — mais ils ne sont
jamais la référence pour un usage normal du produit. Si tu ouvres `.planning/` un jour, tu y
retrouveras une structure familière si tu as déjà utilisé VibeFlow sur un projet de code : c'est
littéralement le même format que celui que le moteur de planification pose pour toi, appliqué ici au
développement du produit lui-même.

## La sortie du manuel

**Où signaler un problème.** Une issue GitHub sur le dépôt du projet est le canal ouvert
aujourd'hui, sans formulaire préformaté — décris ce que tu observais, ce que tu attendais, et ce que
tu as réellement vu. Un cas reproductible (le scope utilisé, le module concerné, la commande exacte)
vaut toujours mieux qu'une description générale. Ce canal permet aussi de savoir si ce que tu as
rencontré est une limite connue ou un vrai bug à corriger.

**Ce que source-available permet.** Le code et l'historique de VibeFlow sont publics et lisibles,
mais l'usage reste soumis à une licence propre au projet plutôt qu'à une licence open source
classique — ce que ça autorise exactement, et dans quelles limites, est écrit noir sur blanc dans le
fichier `LICENSE` à la racine du dépôt. Cette page ne le résume pas davantage : la licence est un
texte juridique, elle se lit dans son intégralité, pas par extraits.

**La promesse de confiance**, déjà formulée une fois au `README` du dépôt sous cette forme exacte,
n'est pas répétée ici mot pour mot — tu l'as déjà croisée, incarnée en détail, tout au long de ce
thème :

- Des scripts auditables plutôt qu'une boîte noire — vu en détail à
  [l-engine-d-install.md](./l-engine-d-install.md).
- Une installation idempotente, avec sauvegarde automatique avant tout écrasement — même page.
- Rien qui s'exécute avant que tu ne l'aies toi-même choisi, y compris les comportements
  automatiques de démarrage de session — vu à
  [anatomie-d-un-lab-installe.md](./anatomie-d-un-lab-installe.md) et confirmé par le principe du
  fail-open détaillé dans [les-gates-machine.md](./les-gates-machine.md).
- Un routage entre agents et skills qui s'appuie sur un inventaire réel du disque plutôt que sur une
  promesse marketing — vu dans le thème [Référence](../06-reference/ou-trouver-quoi.md).

Ce dépôt s'applique d'ailleurs sa propre doctrine : les mêmes gates qui protègent ton code protègent
le sien, et une nouvelle installation du socle est vérifiée automatiquement dans un environnement
vierge avant chaque publication — la meilleure preuve qu'une promesse tient est de se l'appliquer à
soi-même en premier.

Et maintenant ? Si une question te reste après ce manuel, le point de départ le plus fiable est
toujours le même : relis le sommaire, choisis le thème le plus proche de ta question, et si la
réponse n'y est pas, le dépôt lui-même — code, gates, doctrine — reste à un `Read` de distance.

Résumé du chemin parcouru par ce manuel, du premier thème au dernier : tu es parti d'une installation
en deux commandes, tu as traversé les concepts qui donnent leur sens aux mots que VibeFlow emploie,
le catalogue des modules disponibles, le cycle de développement au quotidien, la mécanique d'une
équipe d'agents, la référence rapide pour retrouver une commande ou dépanner une panne, et tu
termines ici, sous le capot, avec de quoi auditer ce qui tourne réellement chez toi. Ce manuel
s'arrête à ce dernier thème ; le produit, lui, continue, et rien ne t'empêche de revenir piocher une
page précise le jour où tu en as besoin plutôt que de tout relire.

C'est tout. Sept thèmes, deux langues, un seul sommaire, et un dépôt qui reste lisible jusqu'au bout.

Bon usage.

<!-- vf-manual:nav -->
[← Précédent](../07-sous-le-capot/decisions-d-architecture.md) · [↑ Sommaire](../README.md)
<!-- /vf-manual:nav -->
