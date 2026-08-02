# Coûts et modèles

<!-- vf-manual:lang -->
**Français** · [English](../../en/06-reference/cost-and-models.md)
<!-- /vf-manual:lang -->

VibeFlow n'a pas de tarif propre : tu paies ta consommation Claude, directement, comme pour
n'importe quelle session Claude Code. Cette page ne donne donc **aucun prix** — elle t'explique ce
qui fait varier ta consommation, et ce que tu peux réellement décider pour la maîtriser. Aucun
chiffre en euros ou en dollars n'apparaît ci-dessous, nulle part.

## Quel modèle tourne, et pourquoi

Les [31 agents](./agents.md) de VibeFlow ne tournent pas tous sur le même modèle. Le partage n'est
pas « juge contre exécutant » — sur ce dépôt, les juges de qualité tournent en sonnet, exactement
comme les workers qu'ils évaluent. Le vrai partage tient à la **nature du jugement demandé** :

- **Les agents « visage » et les managers de mission** (opus, dix agents au total) — router une
  demande dont l'intention n'est pas encore claire, planifier un graphe de tâches avec des
  dépendances croisées entre plusieurs pistes indépendantes, arbitrer un choix qu'aucune rubric
  explicite ne tranche à ta place. C'est un jugement ouvert, sur un périmètre qui peut changer en
  cours de mission.
- **Les workers et les juges** (sonnet, vingt-et-un agents) — produire un livrable précis contre un
  mandat déjà cadré, scorer un résultat contre une rubric écrite noir sur blanc, exécuter une étape
  déjà identifiée. C'est un périmètre borné, connu à l'avance.

Une exception notable confirme la règle plutôt qu'elle ne la brise : `vf-test-orchestrator` pilote
une mission comme les cinq autres managers, mais reste en sonnet — sa boucle (tester, corriger,
retester jusqu'au budget épuisé) est un périmètre borné dès le départ, sans les arbitrages ouverts
d'un plan de bataille multi-métier.

Le détail complet, agent par agent, vit sur [agents.md](./agents.md).

Tu n'as jamais à deviner ce fait : le champ `model:` du frontmatter de chaque fichier d'agent le
dit explicitement, et la [référence des agents](./agents.md) le reproduit pour les 31. Si tu veux
le lire toi-même sur le disque, `grep model: plugin/*/agents/*.md plugin/*/AGENT.md` depuis la
racine du dépôt donne la liste complète — la même commande qu'un mainteneur lancerait avant de
toucher à l'une des affirmations de cette page.

## Les leviers qui maîtrisent réellement ta dépense

**Le périmètre de ta demande.** Une phrase précise (« corrige ce test qui échoue dans
`auth.spec.ts` ») cadre le travail dès le départ. Une phrase ouverte (« améliore le projet ») force
l'agent qui te répond à explorer avant de pouvoir agir — ce n'est pas un défaut de VibeFlow, c'est
le coût normal de l'ambiguïté, le même que tu paierais en confiant la même phrase floue à n'importe
quel collaborateur humain.

**La longueur d'une mission.** Plus une mission couvre de pistes indépendantes, plus le manager qui
la pilote garde un contexte de planification large tout au long de son exécution — même si chaque
worker qu'il dispatche reste, lui, sur un mandat court et peu coûteux. Une mission de trois étapes
et une mission de vingt ne coûtent pas la même chose, et ce n'est pas linéaire : le manager relit
l'état d'avancement à chaque changement d'étage.

**Le choix du mode autonome.** Une mission lancée en [mode autonome](../04-cycle-de-dev/mode-autonome.md)
enchaîne cadrage, plan et exécution sans repasser par toi à chaque étape — tu accumules donc du
travail (et de la consommation) avant de le relire, plutôt que de le fractionner en points de
contrôle rapprochés. Ce n'est ni mieux ni pire : c'est un arbitrage entre ton temps de supervision
et ta visibilité en cours de route, que tu choisis en formulant ta demande.

**Les modules installés.** Chaque module ajoute ses propres agents et skills à ce que le lab peut
dispatcher. Une demande qui touche plusieurs métiers à la fois (dev **et** design, par exemple)
peut router à travers plusieurs équipes si les modules correspondants sont installés — un lab plus
riche a plus de chemins possibles, pas nécessairement plus chers par eux-mêmes, mais avec plus de
surface sur laquelle une demande large peut se déployer.

### Ce qui coûte plus cher qu'on ne l'imagine

**Une boucle de correction qui ne converge pas.** Un cycle de revue qui repart trois fois de suite
sans y arriver coûte évidemment trois fois plus que s'il avait convergé du premier coup. VibeFlow
plafonne ce risque par construction — une halte remonte la décision à toi au lieu de retenter
indéfiniment — mais le plafond limite la casse, il ne l'annule pas : les tentatives déjà faites
avant la halte restent consommées.

**Un audit large plutôt qu'un audit ciblé.** `/vf-audit` orchestre cinq audits complémentaires en
une seule fois — plus complet qu'un seul, et logiquement plus long. Si tu sais déjà quelle
dimension t'intéresse (sécurité, dette de mémoire), un argument optionnel resserre le focus plutôt
que de tout relancer.

**Une conversation fragmentée en beaucoup de petits échanges.** Dix demandes courtes et vagues,
posées une par une, forcent dix explorations séparées là où une seule demande bien formulée,
couvrant le même besoin, en aurait fait une.

## Cinq leviers d'efficience, chiffrés sur ce dépôt

Ce dépôt chiffre cinq leviers d'efficience de sa propre construction, tels que mesurés sur ce
dépôt au 2026-08-01 — reproduits ici comme une mesure observée à cette date, pas comme une
garantie valable pour toujours :

| Levier | Effet mesuré |
|---|---|
| Workers et juges en sonnet, opus réservé au manager | le gros du volume au juste prix |
| Digest de mission limité par construction, par mandat | de l'ordre de cent à deux-cents mille tokens de relecture évités par étape |
| Dispatch parallèle (juges en parallèle, nœuds de graphe disjoints en parallèle) | le mur d'attente séquentiel tombe |
| Cadrage de l'étape suivante pendant l'exécution de la précédente | zéro temps mort entre étapes |
| Chargement à la demande de la doctrine | elle reste hors contexte tant qu'elle ne sert pas |

Ce chiffrage reste une mesure datée de cette phase du dépôt, pas une promesse valable pour ton
propre lab — c'est pour ça que cette page ne le recopie jamais comme un fait acquis. Les cinq
leviers eux-mêmes restent documentés au fil de ce manuel, thème par thème, et c'est là qu'ils
restent vrais indépendamment de ce chiffrage précis ; pour ce qui a changé sur ce dépôt depuis
cette date, `CHANGELOG.md` (racine du dépôt) est la source qui, elle, continue de s'enrichir.

<!-- vf-manual:nav -->
[← Précédent](../06-reference/agents.md) · [↑ Sommaire](../README.md) · [Suivant →](../06-reference/depannage.md)
<!-- /vf-manual:nav -->
