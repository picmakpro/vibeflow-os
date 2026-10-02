# Plusieurs sujets en parallèle

<!-- vf-manual:lang -->
**Français** · [English](../../en/05-agent-team/parallel-topics.md)
<!-- /vf-manual:lang -->

[branches-et-worktrees.md](./branches-et-worktrees.md) règle le cas de deux acteurs qui écrivent
dans le même dépôt. Cette page règle le cas voisin, côté **planning** : deux chantiers qui avancent
en même temps, chacun avec sa feuille de route et son état, sans que l'un attende la fin de
l'autre. VibeFlow appelle chaque chantier un **sujet** (le moteur de planning dit *workstream*).
Tu n'en as pas besoin tant que tu travailles seul sur un seul chantier — c'est le défaut, et il
convient à la plupart des labs.

## Un planning, ou plusieurs sujets

Par défaut, un lab a **un seul planning** : un `.planning/` avec une feuille de route, un état,
des phases. Quand « on sera plusieurs sur ce lab », ou que deux chantiers doivent avancer en
parallèle, tu peux séparer ce planning en sujets : chacun garde ses propres phases et son propre
état, sous `.planning/workstreams/<sujet>/`. La commande `/vf-split-planning` fait ce geste ; tu
peux aussi la déclencher en langage naturel (« sépare le planning en sujets »). Elle est aussi
proposée à la fin de l'initialisation d'un lab de code.

Elle pose **une seule question** — « plusieurs personnes ou agents vont-ils travailler en parallèle
sur des sujets séparés ? » — et la réponse par défaut est non. Tant que tu n'as pas dit oui, rien
n'est créé. En session non interactive, elle ne répond jamais à ta place : planning unique.

Ensuite, trois choses à savoir :

- **Elle refuse si une phase est en cours.** Une machine, pas ton souvenir, tranche : un état
  `executing`, une phase qui compte plus de plans que de comptes rendus, ou un dossier de phase
  avec un plan sans compte rendu suffisent. Termine la phase, puis relance. Si la vérification
  elle-même est impossible, elle ne change rien et le dit.
- **Le premier sujet est le sujet par défaut.** Sur un lab déjà démarré, le planning actuel est
  rangé dans un sujet — nommé d'après l'argument de la commande, sinon le titre du projet, sinon
  le dossier du lab — et elle te le dit avant de le faire, avec la possibilité de choisir un autre
  nom ou de renoncer. Ce sujet est repris d'une session à l'autre sans rien te demander. Un sujet
  ajouté plus tard ne change jamais le défaut.
- **Elle ne commite rien.** Seul le moteur de planning écrit ; la commande te propose ensuite de
  commiter les fichiers de planning modifiés, et te laisse décider.

Pour lancer le premier jalon d'un sujet suivant, la commande te donne la ligne à taper :
`/gsd-new-milestone --ws <sujet>`. Ce geste est interactif, il t'appartient.

## Travailler sur un sujet

Une fois le planning séparé, dis simplement « reprends le sujet X » ou « travaille sur le sujet X ».
L'équipe dispatchée reçoit alors le sujet dans son mandat : chaque appel au moteur de planning
porte `--ws X`, et la variable d'environnement `GSD_WORKSTREAM` est exportée dans le worktree de
la mission. Si X n'existe pas, VibeFlow te le dit et propose `/vf-split-planning`.

Tu peux poser le sujet toi-même quand tu lances un geste de planning à la main : `--ws mon-sujet`
sur la commande (par exemple `/gsd-new-milestone --ws mon-sujet`), ou, pour toute une session de
terminal :

```bash
export GSD_WORKSTREAM=mon-sujet
```

**Ce que tu vois au démarrage.** Sur un dépôt partitionné, si aucun sujet n'est résolu — ni
`GSD_WORKSTREAM`, ni le pointeur partagé `.planning/active-workstream` — la session ouverte te
signale l'absence et prescrit `export GSD_WORKSTREAM=<nom>`. Le motif : le moteur garde par
ailleurs un pointeur de session dans un dossier temporaire, effacé au redémarrage et distinct à
chaque worktree ; il n'est donc jamais hérité d'une session à l'autre, et un nom qui ne correspond
plus à un dossier est oublié sans un mot. Le signal est **informatif** : il constate, il ne bloque
rien. Sur un lab à planning unique, il ne dit rien.

## Ce qui veille sur la partition

Deux sujets qui avancent chacun sur sa branche peuvent diverger sans conflit visible : un
`git merge` fusionne en silence deux phases qui ont pris le même numéro. Un script de contrôle,
`check-divergence.sh`, sert de filet. Il ne modifie rien et cherche trois défauts :

- deux dossiers de phase d'un même sujet qui portent le même numéro ;
- un sujet qui compte plus de dossiers de phase (ou de phases terminées) que sa propre feuille de
  route n'en documente ;
- un numéro de phase possédé par un sujet qui réapparaît dans la feuille de route de la racine.

Aucun hook ne le lance dans ton lab : tu l'appelles à la main, depuis les scripts du module
`conductor`, quand tu fusionnes des branches qui touchent au planning.

```bash
bash .claude/scripts/check-divergence.sh --path .
```

Il répond `0` (conforme), `1` (divergence constatée, avec le ou les numéros en cause), `2` (non
vérifiable — jamais un vert de complaisance) ou `3` (le dépôt n'est pas partitionné, rien à
vérifier).

Les autres gardes du lab suivent, elles, le sujet actif : la vérification de l'état du planning ne
crie plus « STATE.md absent » sur un dépôt partitionné, et les exigences se lisent par sujet.

<!-- vf-manual:nav -->
[← Précédent](../05-equipe-agents/branches-et-worktrees.md) · [↑ Sommaire](../README.md) · [Suivant →](../05-equipe-agents/ranger-ce-qu-on-cree.md)
<!-- /vf-manual:nav -->
