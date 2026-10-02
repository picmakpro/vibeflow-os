# Une mission longue, la mécanique

<!-- vf-manual:lang -->
**Français** · [English](../../en/05-agent-team/a-long-mission.md)
<!-- /vf-manual:lang -->

La page précédente a dit *pourquoi* une équipe se déploie sur une mission longue. Celle-ci dit
*comment* elle tient la route sur dix étapes sans que personne ne se marche dessus — réduit à ce
qui produit une conséquence observable pour toi. Le détail interne complet vit dans les ADR citées
plus bas ; ici, seulement ce qui change ce que tu vois.

Le vocabulaire de cette page (verrou de driver, DAG, rapport typé, digest de mission) est défini
une fois pour toutes dans le [glossaire](../02-concepts/glossaire.md) — cette page ne le redéfinit
pas, elle explique comment ces pièces s'assemblent.

Trois mécanismes composent cette mécanique, et ils s'enchaînent dans cet ordre : le graphe qui dit
quoi faire et dans quel ordre, le verrou qui dit qui a le droit de le piloter, et le rapport typé
qui dit ce qui s'est réellement passé une fois qu'un nœud est traité. Chacun a une limite honnête à
connaître, et les trois sont dites plus bas sans détour.

## Le plan de bataille : un graphe, pas une liste

Quand le manager reçoit ta mission, il ne produit pas une liste d'étapes à dérouler dans l'ordre.
Il produit un **DAG** : chaque étape devient un nœud, et ce nœud porte ses dépendances — les autres
nœuds qui doivent être terminés avant qu'il puisse démarrer.

Ça change deux choses pour toi. D'abord, le **parallélisme** : le manager dispatche toujours la
« frontière ready » — tous les nœuds dont les dépendances sont satisfaites — pas un seul à la fois.
Si l'étape 3 et l'étape 4 ne se recoupent pas, elles avancent en même temps, et ta mission va plus
vite qu'une exécution séquentielle sans rien y perdre en rigueur. Ensuite, la **ré-entrée** : si une
revue renvoie une étape déjà marquée terminée pour correction, ce n'est pas une exception bricolée —
le nœud repasse simplement à l'état « ready », et ses dépendants suivent. Le graphe absorbe le
retour en arrière au lieu de le traiter comme un accident.

Ce que tu en verras concrètement dans un rapport de mission : plusieurs étapes commitées la même
minute (le parallélisme), et parfois une étape qui réapparaît après avoir semblé finie (la
ré-entrée). Les deux sont normaux.

La revue elle-même est un nœud du graphe, pas une formalité laissée à l'appréciation de celui qui a
produit le travail. Le manager la pose systématiquement après chaque étape de production et la
dispatche en direct, à un relecteur qui n'a pas écrit le code — c'est le même principe que « le juge
n'est jamais l'auteur » vu dans [pourquoi-une-equipe.md](./pourquoi-une-equipe.md), appliqué ici à
l'intérieur même du graphe plutôt qu'au livrable final. Une jointure entre deux lots qui ont avancé
en parallèle déclenche elle aussi une revue dédiée, décidée par la forme du graphe et non par une
estimation de recouvrement — deux étapes qui n'ont techniquement touché aucun fichier commun peuvent
quand même mal s'assembler, et c'est précisément ce que cette revue de jointure attrape.

## Le verrou de driver : ce qu'il garantit, et ce qu'il ne garantit pas

Le **verrou de driver** existe pour une raison précise : empêcher que deux managers pilotent la
même étape en même temps sans le savoir. Le manager qui démarre une mission acquiert le verrou, le
rafraîchit pendant qu'il travaille (un battement de cœur), et le relâche à la fin — succès, échec
ou abandon confondus.

Il n'a pas toujours été contraignant. Il fut un temps où il restait **déclaratif** : une mission
a pu continuer à committer pendant qu'une autre tenait le verrou sur la même ressource, parce que
rien ne le faisait respecter. Ce n'est plus le cas : le verrou est désormais **appliqué**. Une
session qui n'est pas enregistrée sous le verrou d'un autre voit son commit, son changement de
branche, ses opérations de publication (`git push`, `gh pr`) ou son écriture dans `.planning/`
**refusés avant exécution**. Le message de refus nomme le détenteur, son étape, sa branche et son
âge, puis propose trois issues : se ré-attacher au verrou si c'est sa propre mission qui a changé
d'identifiant de session, travailler dans un arbre séparé (`git worktree add`, jamais refusé), ou
poser un marqueur de dérogation explicite sur ce geste précis — la dérogation est alors tracée dans
un journal à côté du verrou, jamais silencieuse.

Il faut être honnête sur ce que cette garde *ne* fait *pas*. C'est un garde-fou **anti-accident**,
pas anti-adversaire : il arrête le chemin de moindre résistance, pas une volonté de contourner. Il
ne voit pas une commande déguisée (interpréteur inline, script du dépôt qui committe en interne),
ni une écriture dans `.planning/` faite par un autre outil que Write ou Edit. Il est **aveugle hors
d'une session Claude Code où il est armé** : un terminal, un IDE, un client git tiers ou une autre
machine passent. Et il garantit qu'aucune *autre session* ne committe sous le verrou, pas qu'aucun
autre acteur de la *même* session ne le fait. Sa promesse réelle : une seule mission pilotée par ce
harness à la fois.

Il ne vise que le **lab**. Un geste dont la cible se résout avec certitude hors du lab — par
exemple un `cd` vers un autre dépôt suivi de `&&` et d'un commit — passe, parce que ce verrou ne
protège pas les dépôts voisins. À l'inverse, dès que la cible est ambiguë (variable, joker,
sous-shell, tube, arrière-plan), le geste reste sous le verrou : dans le doute, on refuse.

Le mécanisme a aussi été élargi : un claim de branche est consigné (arbre de travail, branche), et
une session ordinaire — pas seulement un manager — en est informée au démarrage si elle arrive sur
une branche déjà pilotée depuis un autre arbre. C'est ce que
[branches-et-worktrees.md](./branches-et-worktrees.md) détaille : la barrière la plus sûre contre
deux écrivains simultanés reste de travailler dans des arbres séparés.

Un mot sur la récupération. Rien ne garantit qu'un agent qui meurt en cours de route relâche
proprement ce qu'il tenait — un agent LLM peut s'arrêter sans exécuter sa dernière instruction. Le
filet est donc la durée de vie plus le battement de cœur. Un verrou dont le battement s'arrête trop
longtemps est considéré périmé, mais il ne se vole jamais en silence : l'acquisition ordinaire le
**refuse**, et le manager suivant le reprend par un geste explicite, tracé dans le rapport que tu
lis. Cette reprise ne s'arrête pas au verrou : chaque agent qu'un manager dispatche est inscrit dans
un **registre des agents**, rangé à côté du verrou et fermé quand l'agent rend son rapport. Quand
un pilote meurt, ses enfants encore « en cours » deviennent des orphelins : le successeur reprend le
verrou, reçoit l'inventaire, **arrête les orphelins avant tout nouveau dispatch**, puis seulement
redispatche à partir de l'état du dépôt — jamais de ce que l'ancien graphe croyait en cours.

## Le rapport typé, et une deuxième limite à connaître

Avant même de rendre son rapport, un worker démarre avec un **digest de mission** — un résumé de
trente lignes maximum, pas l'historique complet du projet. Il contient l'objectif de l'étape, le
périmètre de fichiers qui lui est assigné, les décisions déjà prises qui l'engagent et les verdicts
amont utiles à son mandat précis. C'est ce qui le garde net : un worker qui démarre sur un contexte
taillé pour lui travaille mieux qu'une session qui doit d'abord relire trois heures d'historique
pour comprendre ce qu'on attend d'elle. Le disque reste la source de vérité — si le digest et le
disque se contredisent, c'est le disque qui gagne, et le worker le signale plutôt que de trancher
seul.

Quand un worker termine son mandat, il ne rend pas un paragraphe de prose que le manager doit
interpréter. Il rend un **rapport typé** : un statut fermé, une liste de constats classés par
gravité, et la liste des nœuds que son travail débloque. Le manager fait un contrôle de flux
déterministe dessus — il n'a rien à deviner. C'est ce contrat qui rend le graphe fiable : un
statut `human_needed` remonte toujours jusqu'à toi, jamais une réponse inventée à ta place.

Un jugement (une revue, un audit, une critique scorée) peut aussi porter un champ optionnel
`confiance`, un nombre entre 0 et 1 : la marge que celui qui juge s'accorde. Il n'accompagne jamais
une preuve machine — un test ou un gate est vert ou rouge, quoi qu'on écrive à côté. Sous le seuil
de 0,6, un `passed` de jugement n'est **pas** un vert : il est requalifié en constat à trancher, et
remonte donc à toi. Absent, le champ ne veut rien dire (pas un 1,0 implicite). Le manager recopie
les valeurs reçues telles quelles dans son rapport de mission, sans jamais en faire une moyenne.

Ce contrat s'appuie sur un second mécanisme qui mérite lui aussi d'être présenté sans le flatter :
le **cloisonnement par outils**. Dans une équipe VibeFlow, celui qui corrige le code ne peut pas
toucher aux tests, celui qui écrit les tests ne peut pas toucher au code applicatif — la séparation
est portée par la liste d'outils que chaque agent a le droit d'invoquer. C'est réel et ça empêche la
triche la plus tentante (affaiblir un test pour le faire passer). Mais dis clairement ce que ce
n'est pas : une allowlist d'outils est **un contrat linté, pas un bac à sable runtime**. Rien
n'empêche techniquement un agent d'invoquer un outil qui ne figure pas dans sa liste déclarée —
c'est un gate de conformité vérifié à la pose du module, pas une barrière que le moteur d'exécution
fait respecter lui-même pendant que l'agent tourne. La discipline tient parce que les agents sont
écrits pour la respecter et parce que le gate refuse un module qui la viole, pas parce qu'un mur
technique l'impose en direct.

Ce que tu retrouves à la fin d'une mission, et où, c'est le sujet de la page suivante — celle qui
dit ce qu'on te demande, à toi, pendant que tout ça tourne.

Aucun des trois mécanismes ci-dessus ne te demande quoi que ce soit pendant qu'une mission tourne.
Ils sont décrits ici pour qu'un rapport de mission se lise comme un comportement attendu, pas comme
une surprise.

<!-- vf-manual:nav -->
[← Précédent](../05-equipe-agents/les-agents-livres.md) · [↑ Sommaire](../README.md) · [Suivant →](../05-equipe-agents/ce-qu-on-vous-demande.md)
<!-- /vf-manual:nav -->
