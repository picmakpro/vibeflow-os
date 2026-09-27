---
name: phase42-corpus-ahead-of-invariant
description: Phase 42 (gouvernance) corrige le corpus d'agents pour I3/I6 avant que ces invariants ne soient armés dans check-agents.sh — séquence voulue, pas une incohérence
metadata:
  type: project
---

Phase 42 (jalon gouvernance-labs-v1.0, FABR-03) arme les invariants de doctrine du gate
`check-agents.sh` un par un. Constaté en 42-05 (revue du diff 13fcd27..2fca889) : les CHANGELOG de
business-pilot-bundle/content-bundle/growth-bundle/design-orchestrator citent « invariant I6,
D-07 » (ajout de `SendMessage` aux managers) et celui de mobile-test-team cite « invariant I3 »
(ajout de `vf-internal: true` + marqueur sur `vf-test-orchestrator`) — alors que `check-agents.sh`
à ce commit n'implémente QUE I1/I4/I7 (`grep invariant_i` ne rend rien pour i3/i5/i6). Ce n'est pas
une citation fabriquée : 42-CONTEXT.md D-06 à D-11 définit les sept invariants en doctrine, D-11
prescrit explicitement de corriger le corpus (I3, I6, et les 4 juges pour I5) AVANT d'armer le
gate correspondant, pour ne jamais laisser un armement immédiat casser la CI. I3/I6 restent non
armés dans le code au 2fca889 (SUMMARY 42-05 : Tâche 3 bloquée sur arbitrage Samuel D-08 absent,
`ARBITRAGE-ABSENT` rc=1 sur 42-D19-MESURE.md).

**Pourquoi ça compte** : une revue qui grep le nom d'un invariant dans check-agents.sh et ne le
trouve pas pourrait à tort lire une CHANGELOG citant cet invariant comme une preuve fabriquée.
Toujours croiser avec 42-CONTEXT.md (définitions D-06+) et le SUMMARY du plan en cours avant de
conclure à une incohérence — la séquence corpus-avant-armement est le mode opératoire assumé de
cette phase, pas un défaut.

**How to apply** : sur toute revue future touchant check-agents.sh / les CHANGELOG de modules
citant Ix pendant que la Phase 42 reste en vol, vérifier l'état d'armement réel (grep
`invariant_iN(` dans le script) avant de signaler un écart doctrine/code — recouper avec
[[project_d22-t19-frozen-violation-gate]] pour le même type de piège (gate qui n'existe pas encore
mais que la doc traite comme acquis).
