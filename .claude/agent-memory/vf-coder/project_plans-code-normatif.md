---
name: plans-code-normatif
description: Les blocs de code des plans docs/superpowers/plans/ sont normatifs byte-à-byte — un correctif de revue doit être répercuté dans le plan
metadata:
  type: project
---

Dans `vibeflow-os`, les plans détaillés de `docs/superpowers/plans/` contiennent le **code exact**
à poser, et les livrables sont attendus byte-identiques à ces blocs. Les `must_haves` du
`.planning/phases/<étape>/<n>-PLAN.md` en sont la spec de plus haut niveau.

**Why:** les plans suivants (ex. 14-03 câblant un script écrit en 14-01) s'appuient sur le plan
détaillé comme source de vérité, pas sur le fichier livré. Corriger le fichier sans corriger le
plan fait diverger les deux et casse silencieusement l'étage aval.

**How to apply:** quand une revue trouve un défaut dans du code dicté par un plan, ne pas patcher
le livrable seul. Si le défaut contredit un `must_have`, c'est une contradiction PLAN vs Task →
remonter au manager (ADR-031, jamais de fix sans validation humaine). Si le fix est validé, il va
dans le plan détaillé **et** dans le fichier, même commit.

**Corollaire (14-05)** : la *prose* d'un plan qui décrit le comportement d'un script écrit dans un
plan antérieur de la même phase peut être **factuellement fausse** — le script a évolué en cours de
phase, le plan pas. Toute phrase de doc qui affirme un exit code, un flag ou une condition se relit
contre le script sur disque avant d'être posée. Là, le plan faisait écrire « un lab de contenu avec
un `package.json` sort en exit 2 » alors que `detect-gsd-engine.sh` exige une **conjonction** (socle
`planning-core` ET signal de code) — exit 3 dans le cas le plus courant. Quand le périmètre interdit
de toucher au plan détaillé, corriger le livrable et **remonter la dérive du plan au manager**.
