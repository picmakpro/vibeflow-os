# Où trouver quoi

<!-- vf-manual:lang -->
**Français** · [English](../../en/06-reference/where-to-find-what.md)
<!-- /vf-manual:lang -->

Ce manuel ne prétend pas tout dire. Certaines choses vivent ailleurs dans le dépôt, à jour en
permanence parce qu'elles sont maintenues au même endroit que ce qu'elles décrivent — recopier
leur contenu ici les ferait périmer, exactement le problème que
[où vit un module](../03-modules/ou-vit-un-module.md) détaille pour les numéros de version. Cette
page est le pont assumé vers ces endroits : une ligne chacun, plutôt qu'une explication redite.
C'est la dernière page du thème de référence, et c'est délibéré : elle referme le manuel en disant
où continuer à chercher une fois qu'il ne suffit plus.

## La carte des ressources

| Tu cherches | Regarde ici | Pas ici |
|---|---|---|
| La version installée d'un module et son historique | `module.json` du module, puis son `CHANGELOG.md` s'il en a un | Aucune page de ce manuel — voir [où vit un module](../03-modules/ou-vit-un-module.md) |
| Pourquoi une décision structurante a été prise | `docs/ADR.md`, le registre des décisions d'architecture du dépôt | Le README, qui n'en cite qu'un sous-ensemble |
| La doctrine méthodologique complète (principes, patterns, vocabulaire) | `plugin/reference/content/`, la source canonique | `docs/reference/` de ton propre lab, qui en est une copie |
| Ce qui a changé entre deux versions publiées de VibeFlow | `CHANGELOG.md`, à la racine du dépôt | Ce manuel, qui ne raconte jamais cet historique |
| Ce qu'un contrôle machine vérifie exactement | `scripts/` de chaque module (ex. `plugin/conductor/scripts/`) | Une paraphrase en langage courant, toujours moins précise que le script lui-même |
| Un exemple de lab construit de bout en bout | `plugin/reference/content/examples/PetitsCoursFlow/` | — |
| Les termes de licence | `LICENSE` (racine, licence du plugin lui-même) **et**, séparément, `plugin/reference/content/LICENSE.md` (licence d'usage propre à la doctrine méthodologique) | Un seul et même texte — ce sont deux licences distinctes, pour deux objets distincts |
| Comment le dépôt vérifie ses propres changements avant de les publier | `.github/workflows/ci.yml` | Une description informelle de ce que « la CI » fait |
| L'ordre et l'organisation de ce manuel lui-même | `manual/toc.yml` — la séquence canonique des thèmes et des pages | Une hiérarchie devinée depuis la navigation seule |

Chaque ligne répond à une question précise. Si ta question n'y correspond pas exactement, le
réflexe qui marche presque toujours est le même : demande à ton lab directement plutôt que de
chercher le fichier toi-même — un agent VibeFlow sait où lire ces sources, et te répond avec la
valeur exacte plutôt qu'une approximation. Ce tableau lui-même n'échappe pas à la règle qu'il
décrit : il pointe, il ne recopie jamais le contenu des fichiers qu'il nomme.

**Sur `plugin/reference/content/` et `docs/reference/` : lequel prime ?** Si ton lab a installé le
module `reference`, une copie de la doctrine vit dans ton propre projet, sous `docs/reference/`,
posée là au moment de l'installation. Cette copie peut légèrement retarder sur sa source si le
module a évolué depuis — c'est un doublon assumé, pas une erreur, mais **en cas de doute, la
source dans ce dépôt-ci (`plugin/reference/content/`) prime toujours**.

**Sur les deux licences.** `LICENSE` couvre le code du plugin que tu installes et exécutes.
`plugin/reference/content/LICENSE.md` couvre un objet différent : les conditions d'usage du contenu
méthodologique lui-même (les principes, les patterns, les templates), une fois qu'il a été copié
dans ton propre projet. Confondre les deux, c'est se tromper sur ce qu'on a le droit de faire avec
quoi — la distinction mérite d'être vue une fois, explicitement, plutôt que devinée.

### Le principe derrière cette page

Cette page applique à elle-même la règle qui gouverne tout ce thème de référence : ne jamais
recopier une information qui vit — et change — ailleurs. Un chiffre de version périme dès la
mise à jour suivante d'un module ; un extrait de doctrine périme dès que la source évolue sans que
la copie ne suive. Pointer vers la source coûte une ligne et reste vrai indéfiniment ; recopier son
contenu coûte plus de lignes et devient faux en silence, sans que rien ne le signale. C'est
exactement le choix qu'a fait [où vit un module](../03-modules/ou-vit-un-module.md) pour les
numéros de version, appliqué ici à toutes les autres ressources du dépôt.

## Pourquoi tu n'as normalement pas à ouvrir `docs/` ni `.planning/`

C'est la question que ce manuel existe pour résoudre, alors autant le dire explicitement, à
l'endroit précis où tu pourrais être tenté d'aller voir par toi-même.

`docs/` et `.planning/` — qu'ils soient à la racine de ce dépôt de distribution ou dans un lab que
tu as créé avec VibeFlow — sont écrits **pour les agents**, pas pour toi. Ce sont la mémoire de
travail : l'état d'avancement d'une étape, les décisions prises en cours de route, les blocages
identifiés, les traces de vérification. Un agent les relit en continu pour savoir où il en est et
ne pas te reposer une question déjà répondue. Le format y est optimisé pour cette relecture
mécanique — dense, indexé, plein de références internes — pas pour une lecture humaine confortable.

Toi, tu n'en as besoin que si tu veux littéralement inspecter le mécanisme : comprendre pourquoi
une mission a pris telle décision, ou vérifier un état brut plutôt que la version reformulée qu'un
agent t'en donnerait. Ce n'est jamais interdit — rien n'y est caché — mais ce n'est jamais non plus
nécessaire pour utiliser VibeFlow au quotidien. Si tu te surprends à ouvrir `.planning/` pour
comprendre *ce que fait* VibeFlow plutôt que *ce qu'une mission précise a fait*, c'est le signal
que la question appartient à ce manuel, pas à ces dossiers — et que cette page mérite peut-être un
signalement (section suivante) si elle n'y répond pas encore.

Ce manuel, à l'inverse, est écrit **pour toi** : ce que tu lis ici a été reformulé, structuré et
daté explicitement pour être lu par un humain qui découvre ou qui revient vérifier quelque chose de
précis — pas pour être relu en boucle par une machine. Si une page de ce manuel te renvoie vers
`docs/` ou `.planning/`, c'est toujours pour un besoin ponctuel et nommé (une décision d'archi, un
rapport de mission précis) — jamais comme une lecture attendue de ta part par défaut.

Concrètement, la frontière se trace ainsi : une question qui commence par « comment je fais pour »
ou « qu'est-ce que » relève de ce manuel. Une question qui commence par « qu'a fait exactement la
mission de mardi » ou « pourquoi cet agent a-t-il écrit ce fichier-là » relève de `.planning/` — et
encore, la plupart du temps, il est plus rapide de reposer la question à ton lab en langage
naturel que d'aller lire le fichier brut toi-même.

## Signaler un problème ou proposer une amélioration

Ce dépôt est public sur GitHub, à l'adresse `picmakpro/vibeflow-os`. Une anomalie de comportement,
une page de ce manuel qui a mal vieilli, ou une idée d'amélioration — la voie normale est une issue
GitHub sur ce dépôt.

Décris ce que tu observes plutôt que ce que tu supposes en être la cause : c'est ce qui permet de
le corriger le plus vite, pour la même raison qu'un symptôme précis va plus vite qu'une cause
devinée dans la page [dépannage](./depannage.md). Si ton signalement concerne précisément ce
manuel — une page manquante, un lien mort, un fait qui a changé sans que la page ne le reflète —
dis-le explicitement dans l'issue : le manuel évolue par vagues de rédaction distinctes de celles
du code, et un signalement clair sur son périmètre aide à le router vers la bonne vague.

Il n'existe pas, à la date où cette page a été écrite, de gabarit d'issue préformaté sur ce
dépôt — une issue en texte libre, décrivant clairement le contexte, suffit. Ce n'est ni un manque
ni une négligence : c'est simplement l'état du dépôt aujourd'hui, et cette page ne prétend pas
qu'il en existe un pour t'éviter d'en chercher un qui n'existe pas.

Ceci referme ce thème de référence, et avec lui, le parcours guidé de ce manuel à travers VibeFlow
tel qu'il existe aujourd'hui.

<!-- vf-manual:nav -->
[← Précédent](../06-reference/depannage.md) · [↑ Sommaire](../README.md) · [Suivant →](../07-sous-le-capot/anatomie-d-un-lab-installe.md)
<!-- /vf-manual:nav -->
