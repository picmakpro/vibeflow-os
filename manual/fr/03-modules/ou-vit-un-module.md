# Où vit un module, et où lire la vérité

<!-- vf-manual:lang -->
**Français** · [English](../../en/03-modules/where-a-module-lives.md)
<!-- /vf-manual:lang -->

Cette page est celle qui remplace, dans ce manuel, le tableau récapitulatif des versions que tu
t'attendais peut-être à trouver. Elle t'apprend à aller chercher l'information à sa source plutôt
qu'à faire confiance à une copie — et elle explique pourquoi cette différence compte plus qu'elle
n'en a l'air.

## Les quatre fichiers qui disent la vérité

Un module est un dossier. Dans ce dossier, quatre fichiers portent l'information de référence, et
chacun répond à une question différente.

**`module.json` — l'identité.** C'est le manifeste du module, celui que l'installeur lit. Il porte
le nom du module, son type, sa description en une phrase, son numéro de **version**, ses
**dépendances** (`requires`), et s'il est obligatoire (`mandatory`). C'est ici, et nulle part
ailleurs, qu'on lit la version installée d'un module. Le fichier fait une dizaine de lignes et se
lit d'un coup d'œil.

**`CHANGELOG.md` — l'histoire.** Ce que chaque version a changé, dans l'ordre inverse. C'est le
fichier à ouvrir quand un module se comporte autrement qu'avant, ou quand tu veux savoir si une
capacité que tu cherches existe déjà. Une entrée de changelog te dit *ce qui a bougé* ; le
`module.json` te dit seulement *où tu en es*.

**`README.md` — l'usage.** Ce que le module fait, comment on s'en sert, et quelles sont ses limites.
C'est la source la plus fiable pour comprendre un module en profondeur, parce qu'elle est écrite et
maintenue au même endroit que le code du module.

**`VERSION` — le numéro nu.** Un fichier d'une seule ligne, redondant avec le champ du manifeste,
qui existe pour être lu par des scripts sans parser de JSON.

Attention : **tous les modules ne portent pas ces quatre fichiers.** La majorité oui, mais quelques
modules s'en écartent — certains n'ont pas de `README.md`, d'autres organisent leur contenu
autrement. Ne présume pas ; ouvre le dossier du module, il te dira ce qu'il porte réellement.

## L'anatomie du reste

Autour de ces fichiers, un module range ses capacités dans des dossiers aux noms prévisibles. Tu
n'as jamais besoin d'y toucher, mais savoir où regarder aide à comprendre ce qu'un module a
réellement posé chez toi.

- **`skills/`** — les skills du module, un sous-dossier par skill, chacun avec son `SKILL.md`. Les
  modules qui n'en portent qu'un seul le mettent parfois directement à la racine.
- **`agents/`** — les agents internes de l'équipe, un fichier par agent. Un module peut aussi
  poser un agent principal à sa racine, distinct de ceux-là.
- **`scripts/`** — les scripts exécutables : gates machine, vérifications, générateurs. C'est ce
  qui fait qu'un contrôle rend un verdict binaire au lieu d'une opinion.
- **`references/`** — la documentation détaillée que les agents chargent à la demande, pour ne pas
  alourdir leur prompt en permanence.
- **`hooks/`, `rules/`, `config/`** — le câblage : ce qui se déclenche automatiquement, les règles
  applicables à certains chemins, les valeurs de configuration propres à un projet.

La distinction entre skill, agent et commande est expliquée en
[agents-skills-commandes.md](../02-concepts/agents-skills-commandes.md) si les trois mots se
mélangent encore.

### Lire une version en trois secondes

Le geste le plus simple reste de demander à ton lab : « quelle version du module de développement
est installée ? ». Il ira lire le manifeste et te répondra la valeur exacte, pas une valeur
approchée.

Si tu préfères regarder toi-même, le fichier se lit directement. Depuis la racine du dépôt du
plugin :

```bash
cat plugin/dev-orchestrator/module.json
```

Le champ `version` est là, entre le nom et la description. Remplace `dev-orchestrator` par le
module qui t'intéresse — les noms sont ceux du [catalogue](./catalogue.md), et ils correspondent
exactement aux noms de dossiers.

## Pourquoi ce manuel ne cite aucune version

Tu as peut-être remarqué qu'aucune page de ce manuel ne contient de numéro de version. Ce n'est pas
un oubli : c'est une règle, et un contrôle automatique la fait respecter à chaque relecture du
manuel. Voici pourquoi.

Un numéro recopié dans une page de documentation devient faux dès la mise à jour suivante du
module — et il devient faux **silencieusement**. Rien ne casse, rien ne prévient, personne ne le
voit. La page continue d'avoir l'air juste, et un lecteur qui s'y fie prend une décision sur une
information périmée.

Ce n'est pas une crainte théorique. Au moment où ces lignes ont été écrites, le README du dépôt
lui-même affichait des versions périmées pour la **grande majorité** des modules : un module
annoncé plusieurs versions mineures en retard de son état réel, un autre encore plus loin. Le
README n'avait rien fait de mal — il avait simplement été écrit un jour, et les modules avaient
continué d'avancer sans lui.

D'où la règle : le manuel ne fige jamais une information qui peut se périmer. Il pointe vers
l'endroit où elle vit. Pour une version, cet endroit est le `module.json` du module concerné, et
pour l'histoire de ses changements, son `CHANGELOG.md`. C'est un tout petit peu moins pratique à
lire, et c'est infiniment plus fiable.

Ce réflexe vaut au-delà de ce manuel. Chaque fois qu'un document t'annonce un chiffre, demande-toi
quand il a été écrit et si quelque chose l'oblige à rester vrai. Si rien ne l'y oblige, va lire la
source.

<!-- vf-manual:nav -->
[← Précédent](../03-modules/activer-desactiver.md) · [↑ Sommaire](../README.md) · [Suivant →](../04-cycle-de-dev/le-cycle-en-bref.md)
<!-- /vf-manual:nav -->
