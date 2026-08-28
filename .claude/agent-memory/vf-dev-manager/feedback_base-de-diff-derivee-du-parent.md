---
name: base-de-diff-derivee-du-parent
description: Dériver la base d'un diff de preuve avec `git rev-parse <sha>^`, jamais depuis l'adjacence dans `git log` — et vérifier le mandat avant dispatch, car un worker lancé n'est pas corrigeable
metadata:
  type: feedback
---

Quand un mandat de worker cite une plage de diff, **dériver la base par `git rev-parse <sha>^`**
(ou `git show --stat <sha>`), **jamais** en lisant la ligne voisine d'un `git log --oneline`.

**Why:** `git log` liste du **plus récent au plus ancien**. Sur la Phase 23, j'ai lu
`a6c8329` juste au-dessus de `2f830ab` et écrit `git diff a6c8329 2f830ab` dans deux mandats —
plage **inversée**, qui rendait le diff à l'envers et sur des fichiers sans rapport
(`HANDOFF.json`, le DAG). Le vrai parent était `aa43b1d`. Un worker l'a détecté et corrigé seul ;
l'autre a reçu la même consigne fausse.

**Aggravant, et c'est le vrai coût :** je n'ai **pas** `SendMessage` dans mes outils. Relancer
l'outil `Agent` avec un message de correction **crée un agent NEUF** au mandat incohérent, qui peut
en plus **entrer en collision d'écriture** avec celui qu'on voulait corriger (ici, deux revues
pouvant écrire le même `*-REVIEW.md`). **Un worker dispatché n'est pas rattrapable.**

**How to apply:** avant tout dispatch, relire le mandat comme s'il était irrévocable — parce qu'il
l'est. Vérifier par exécution les faits qu'on y inscrit (SHA, plages, numéros de ligne, comptes) au
lieu de les recopier d'une sortie d'outil lue de travers. En cas d'erreur découverte après coup :
ne pas re-dispatcher « en correction », laisser le worker finir et **réconcilier sur le disque**,
en vérifiant qui a écrit quoi.

Voir aussi [[diff-proxifie-faux-identique]] (formes de `git diff` qui mentent sous le proxy) et
[[re-deriver-les-listes-d-une-revue]].
