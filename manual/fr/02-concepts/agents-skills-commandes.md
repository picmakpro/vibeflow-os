# Agents, skills et commandes

<!-- vf-manual:lang -->
**Français** · [English](../../en/02-concepts/agents-skills-and-commands.md)
<!-- /vf-manual:lang -->

Ouvre `plugin/*/agents/` et tu trouveras des dizaines de fichiers `.md` — mais très peu ont une
commande qui leur correspond. Ce n'est pas un oubli : c'est une distinction volontaire entre ce que
tu **invoques** et ce qui **travaille pour toi en coulisse**. Cette page pose le vocabulaire ; les
listes exhaustives (quelle commande, quel skill, quel agent existe précisément) vivent dans
`06-reference/`, pas ici.

Retiens l'ordre de grandeur : sept commandes contre plus d'une quinzaine de skills livrés et
vingt-deux agents. Ce déséquilibre volontaire est la clé de lecture de toute cette page — la
plupart de ce que VibeFlow fait pour toi n'est **jamais** tapé, il se déclenche.

## Trois portes d'entrée : commande, skill, agent

### Une commande, ça se tape

Une **commande** (`/vibeflow`, `/vf-new-lab`, `/vf-audit`…) est un point d'entrée explicite : tu la
tapes, elle démarre une action précise. Il en existe six dans VibeFlow, chacune un geste que tu
choisis délibérément — créer un lab, auditer un lab, mettre à jour, etc.

### Un skill, ça se déclenche

Un **skill** est une base de connaissance que Claude Code charge quand ton intention **exprimée en
langage naturel** correspond à sa description — tu n'as pas besoin de connaître son nom. Dire
« aide-moi à développer cette fonctionnalité » suffit à déclencher le skill `vf-dev`, sans jamais
taper `/vf-dev`. C'est pour ça que VibeFlow porte beaucoup plus de skills livrés que de commandes :
la commande est le geste volontaire, le skill est la réponse à une intention. La règle qui régit ce
déclenchement est volontairement permissive : si une situation correspond ne serait-ce qu'à 1 % à
la description d'un skill, il doit se déclencher — mieux vaut un skill invoqué à tort qu'un skill
pertinent ignoré.

### Un agent, c'est une session avec son propre contexte

Un **agent** est une session Claude Code distincte, avec son propre mandat, ses propres outils
autorisés, et son propre contexte — séparé de ta conversation principale. Quand un skill ou une
commande a besoin d'un travail spécialisé (écrire du code, juger un livrable, auditer une
architecture), il **dispatche** un agent plutôt que de tout faire dans la même session : ça garde
chaque contexte petit et concentré sur une seule responsabilité — c'est le principe P9 du canon,
détaillé plus loin dans ce thème.

## Orchestrateur, worker, juge

Trois rôles reviennent dans presque toute équipe VibeFlow :

- **L'orchestrateur** planifie et délègue, mais **ne produit jamais** de livrable final lui-même —
  c'est un chef d'équipe, pas un exécutant.
- **Le worker** exécute une tâche précise dans un périmètre défini (écrire, corriger, tester).
- **Le juge** évalue un livrable produit par un worker, sur une rubric explicite, et **n'a aucun
  outil d'écriture** — il ne peut techniquement pas corriger ce qu'il note, pour qu'il reste
  impartial (le détail vit dans la page de ce thème consacrée aux gates et à la validation
  humaine).

### Un exemple concret de la chaîne

Sur une équipe de dev, `vf-dev-manager` (l'orchestrateur) reçoit une étape à réaliser, la découpe,
et dispatche `vf-coder` (le worker) pour l'écrire. Une fois le code produit, `vf-reviewer` (un
juge) le relit sur des critères explicites et rend un verdict — sans jamais modifier une ligne
lui-même, faute d'outil d'écriture. Si le verdict est un retour, le manager redispatche `vf-coder`
en mandat de correction ciblée. Le manager, lui, n'écrit jamais de code : son rôle est de
planifier, distribuer et reconcilier les rapports qui reviennent.

## Pourquoi certains agents n'ont aucune commande d'incarnation

C'est la question que se pose quiconque ouvre `plugin/*/agents/` sans y retrouver ses commandes :
sur les vingt-deux agents livrés, la grande majorité n'a **aucune** commande `/<nom-agent>`
associée. C'est voulu, pas un manque. Un **worker interne** — par exemple `vf-coder`, qui écrit le
code d'une étape de dev, ou `quality-gate-client`, le juge des livrables business — n'est dispatché
que par son orchestrateur (`vf-dev-manager`, `vf-business-manager`…), jamais directement par toi.
Ces agents portent `vf-internal: true` dans leur frontmatter, précisément pour qu'aucune commande
publique ne soit générée pour eux : ils n'ont de sens que dans le mandat que leur donne leur
orchestrateur, pas en usage isolé. Tu ne perds rien en ne les invoquant jamais toi-même — c'est
exactement leur mode de fonctionnement prévu.

Cette réserve n'est pas qu'une convention de nommage : un orchestrateur ne peut dispatcher que la
liste exacte d'agents qu'il déclare dans son propre frontmatter — pas un agent arbitraire de ton
choix. `vf-internal: true` et cette liste fermée sont les deux faces d'une même garantie : un
worker interne reste dans le couloir de son équipe, jamais un point d'entrée que tu pourrais
appeler seul et sortir de son contexte prévu.

### Une limite assumée, pas cachée

Il n'existe, à ce jour, aucun champ natif de Claude Code qui rende un agent strictement invocable
« seulement par un autre agent, jamais par toi ». La garantie décrite ci-dessus (allowlist côté
orchestrateur + `vf-internal` + description dissuasive) est une heuristique robuste, pas une
barrière technique absolue — un utilisateur qui connaît le nom exact d'un worker interne pourrait
en théorie forcer son invocation. VibeFlow choisit de le documenter plutôt que de prétendre à une
étanchéité qu'aucun outil actuel ne garantit.

En pratique, tu n'as jamais besoin de connaître ce nom : les commandes et skills documentés dans
`06-reference/` couvrent tout ce que tu es censé déclencher toi-même. Si un agent n'y figure pas,
c'est qu'il travaille pour un orchestrateur, pas pour toi directement.

Retiens la règle simple qui résume toute cette page : tape une commande pour un geste que tu
choisis, laisse un skill se déclencher sur ce que tu dis naturellement, et ne cherche jamais à
invoquer un agent listé nulle part — il a un travail à faire, ailleurs.

<!-- vf-manual:nav -->
[← Précédent](../02-concepts/modules-et-bundles.md) · [↑ Sommaire](../README.md) · [Suivant →](../02-concepts/vibeflow-gsd-superpowers.md)
<!-- /vf-manual:nav -->
