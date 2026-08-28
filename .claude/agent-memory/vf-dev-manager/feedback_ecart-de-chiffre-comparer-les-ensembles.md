---
name: ecart-de-chiffre-comparer-les-ensembles
description: Quand deux comptages divergent, comparer les ENSEMBLES en comm et expliciter la définition — l'écart est presque toujours définitionnel, pas arithmétique
metadata:
  type: feedback
---

Deux mesures qui donnent des chiffres différents ne se départagent **jamais** en rejouant la plus
autoritaire. On extrait les deux ensembles, on les compare en `comm`, on regarde **les éléments de
l'écart**, et on remonte à la **définition** que chaque motif encode.

**Why:** Phase 37 (2026-08-28). Trois parties, trois réponses sur « combien de SKILL.md appellent un
skill `gsd-*` » : le document disait 8, une revue adversariale disait 9 et accusait le document
d'avoir « corrigé à tort » le ROADMAP, ma propre re-vérification disait 9. J'allais faire corriger
une valeur **juste**. Le `comm` des deux ensembles a isolé **un seul fichier**,
`plugin/dev-orchestrator/skills/vf-dev/SKILL.md`, dont l'unique occurrence est le littéral
**générique** `gsd-*` — la famille, avec l'astérisque — qui ne matche pas `gsd-[a-z-]+` parce que
`*` n'est pas dans la classe. Ce fichier ne nomme aucun skill réel.

L'écart n'était donc pas arithmétique mais **définitionnel** : « mentionner la famille » ≠ « appeler
un skill ». Sous la lecture qu'impose le verbe, 8 est juste — c'est mon motif large (`grep -rl
'gsd-'`) qui comptait une mention générique comme un appel.

**How to apply:** trois gestes, dans cet ordre. (1) N'arbitre jamais un écart de comptage par
l'autorité de la source — extrais les ensembles et fais le `comm`. (2) Ouvre les éléments de
l'écart et **lis-les** : la ligne fautive dit presque toujours quelle définition chaque motif
encode. (3) Consigne dans le livrable **la commande exacte + la définition retenue**, pas seulement
le chiffre — un compteur sans sa définition sera re-contesté au tour suivant. Corollaire : exiger la
méthode plutôt que le chiffre est ce qui a permis de trancher ici. Voir
[[re-deriver-les-listes-d-une-revue]] et [[descripteur-gsd-core-non-probant]].
