# Branches et worktrees

<!-- vf-manual:lang -->
**Français** · [English](../../en/05-agent-team/branches-and-worktrees.md)
<!-- /vf-manual:lang -->

C'est la page la plus opérationnelle de ce thème, parce qu'elle t'impose une pratique concrète dès
que tu travailles en parallèle d'une mission. Les pages précédentes ont dit *pourquoi* une équipe se
déploie et *comment* elle avance ; celle-ci dit ce que ça change pour ton usage quotidien de git.

## Pourquoi une mission ne travaille jamais sur ta branche courante

Une mission d'équipe produit des dizaines de commits sans supervision directe. Rien ne garantit
qu'ils soient tous bons, et le seul recours après coup, si elle avait commité sur ta branche
principale, serait un `revert` en masse d'un historique déjà public — potentiellement déjà consommé
par d'autres clones. C'est un vrai incident constaté sur ce dépôt : une mission a un jour produit 32
commits directement sur `main`, sans dégât, mais par chance et non par construction.

La règle qui en découle (ADR-059) : **toute mission d'équipe crée sa branche avant son premier
commit, y tient tous ses commits, et termine par une pull request laissée ouverte.** Le manager ne
fusionne jamais lui-même — le merge t'appartient, comme toute action qui engage ton historique
public. Sur une branche, le recours n'est plus un revert massif : c'est simplement de ne pas
fusionner. La PR donne en prime un point de relecture groupée qu'un rapport de fin de mission,
rédigé par celui qui a fait le travail, ne remplace pas.

Le nom de la branche suit une convention lisible (`feat/<périmètre-en-kebab>`), et une mission n'a
qu'une seule branche, même si elle couvre plusieurs étapes de ta feuille de route. Si le dépôt cible
n'a pas de remote, ou que l'outil de gestion de PR n'est pas disponible, la mission se replie
proprement et te le dit dans son rapport plutôt que d'échouer — le détail des replis est couvert par
[ce-qu-on-vous-demande.md](./ce-qu-on-vous-demande.md), pas répété ici.

Ce qui déclenche cette règle, c'est le **dispatch d'un manager**, pas la nature du travail. Un
correctif rapide, une mise à jour de doc ou un cadrage menés directement dans ta conversation restent
hors de cette règle — sinon chaque échange créerait une branche, ce qui alourdirait le quotidien
sans rien protéger de plus. La règle vise spécifiquement le travail non supervisé en volume.

## Un écrivain = un worktree

La branche seule protège contre un cas : une mission qui commiterait par erreur sur ta branche
principale. Elle ne protège pas contre l'autre cas, plus insidieux, constaté lui aussi sur ce
dépôt : **deux acteurs qui partagent la même branche depuis le même arbre de travail sans le
savoir.** Le 2026-07-31, une mission pilotée par un manager et une session conversationnelle
ordinaire ont écrit sur la même branche en parallèle — trois commits hors périmètre se sont
retrouvés dans la PR d'une mission qui ne les avait pas produits. Le verrou de driver existait déjà,
mais il ne protégeait qu'une étape, et surtout il n'était consulté que par les managers ; une
session ordinaire passe par-dessus sans même le savoir.

La règle qui en découle (ADR-064) : **dès que deux acteurs travaillent en parallèle sur le même
dépôt — deux missions, une mission et une session conversationnelle, deux vagues d'une même
mission — chacun tient son propre arbre de travail.** C'est la seule barrière qui ne repose pas sur
la bonne volonté de celui qui écrit : deux arbres distincts ne peuvent physiquement pas se marcher
dessus, quelles que soient les intentions de leurs occupants. La branche reste nécessaire (ADR-059),
elle n'est simplement pas suffisante à elle seule.

**Ce que tu vois si tu ouvres une seconde session sur le même dépôt.** Si tu démarres une session
ordinaire sur une branche déjà pilotée par un lock actif posé depuis un autre arbre, un signal
apparaît au démarrage — quelque chose comme : *« cette branche est déjà pilotée depuis un autre
arbre de travail (par tel owner, sur telle étape, depuis N minutes) — un écrivain = un worktree »*.
Ce signal est **advisory** : il constate, il ne bloque rien, et deux sessions volontairement sur la
même branche restent un cas légitime et fréquent — le jugement te revient (ADR-031), un hook qui
refuserait d'écrire casserait des usages parfaitement normaux. Deux sessions dans le *même* arbre ne
déclenchent jamais ce signal : c'est l'écriture depuis un arbre tiers qui surprend, pas la
coexistence en soi.

**Créer et retirer un worktree**, dans les grandes lignes :

```bash
# depuis le dépôt principal, crée un arbre isolé sur une nouvelle branche
git worktree add ../mon-repo-mission feat/ma-mission

# une fois le travail terminé et fusionné, retire l'arbre proprement
git worktree remove ../mon-repo-mission
```

Le principe VibeFlow ici n'est pas de réimplémenter cette mécanique : c'est celle du harness
lui-même (`isolation: worktree` au dispatch d'une mission), pas une refabrication maison. Ce que
VibeFlow ajoute, c'est le signal qui te prévient quand quelqu'un d'autre en tient déjà un sur ta
branche.

Tu peux aussi constater la situation toi-même avant de committer sur une branche que tu n'as pas
créée, plutôt que d'attendre le signal automatique : le même script qui pose ce signal au démarrage
peut être appelé directement, et il répond par un verdict net — personne d'autre ne pilote, quelqu'un
d'autre la pilote depuis un autre arbre, ou rien n'a pu être vérifié. Ce dernier cas — l'indéterminé
— ne veut jamais dire « la voie est libre » : c'est une absence de certitude, pas un feu vert.

## Quand un claim est refusé

Il y a une différence entre le signal advisory décrit plus haut — qui informe une session ordinaire
— et un vrai refus, qui s'applique entre managers de mission. Quand un manager tente de démarrer et
que l'étape qu'il vise est déjà pilotée par un verrou actif, l'acquisition **échoue franchement** :
la seconde mission ne démarre pas en silence à côté de la première, elle reçoit un refus explicite
(qui pilote, depuis quand) et s'arrête plutôt que de continuer en aveugle.

Dans ce cas, ce que tu vois dépend de la fraîcheur du verrou. S'il est actif et récent, la mission
qui a été refusée te le dit et attend ton arbitrage — relancer plus tard, ou confirmer que la
première mission est bien celle qui doit continuer. S'il est périmé (le porteur a disparu sans le
relâcher), le mécanisme de récupération décrit dans
[une-mission-longue.md](./une-mission-longue.md) prend le relais tout seul, et la reprise est tracée
dans le rapport — tu n'as rien à débloquer à la main dans ce cas précis.

Une fois la mission terminée et sa PR fusionnée, le geste de nettoyage est court : retire le
worktree qui lui était dédié (`git worktree remove`), et supprime la branche mergée si tu ne comptes
pas la réutiliser. Rien de tout ça n'est automatique — c'est délibéré, pour que la suppression d'un
arbre de travail reste toujours un geste que tu poses, jamais un geste que la mission pose pour
elle-même.

Prises ensemble, les trois règles de cette page te coûtent une seule habitude à prendre : avant de
démarrer un travail en parallèle sur un dépôt qu'une mission pourrait utiliser, prends un instant
pour vérifier si elle tient déjà son propre arbre. C'est cette habitude, à elle seule, qui
transforme un mécanisme d'isolation physique en pratique dont tu profites réellement, plutôt qu'en
filet de sécurité que tu ne découvres qu'après l'avoir déclenché.

<!-- vf-manual:nav -->
[← Précédent](../05-equipe-agents/ce-qu-on-vous-demande.md) · [↑ Sommaire](../README.md) · [Suivant →](../05-equipe-agents/equipes-specialisees.md)
<!-- /vf-manual:nav -->
