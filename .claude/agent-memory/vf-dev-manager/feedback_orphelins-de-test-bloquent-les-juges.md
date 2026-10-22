---
name: orphelins-de-test-bloquent-les-juges
description: un mutant qui bloque (FIFO, read) survit à perl alarm et tient le tube ; un juge qui lance la suite derrière | tail reste figé plus d une heure
metadata:
  type: feedback
---

Exiger dans tout mandat qui exécute des suites : jamais de suite derrière un tube (`| tail`, `| grep`), sortie redirigée vers un fichier ; bornes qui tuent le GROUPE de processus ; `ps` après chaque suite.

**Why:** Phase 58 (2026-10-16/17) : le mutant MUT-cfg-fifo ouvrait un FIFO et bloquait ; `perl -e 'alarm N; exec'` tuait le parent, pas le petit-enfant, qui gardait le descripteur hérité. 9 orphelins ont gelé une re-revue plus d'une heure (SendMessage sans effet : le juge était dans son appel d'outil). Il a fallu tuer les orphelins, puis lancer un relecteur de relève.

**How to apply:** quand un worker se tait plus de 30 min, lister les processus de test (`rtk proxy ps -axo pid,etime,command`) AVANT de le réveiller ou de le remplacer. Les orphelins de `/T/tmp.*/mut/` sont un défaut du harnais : on les corrige dans la suite. Voir [[trace-figee-ne-prouve-pas-worker-mort]].
