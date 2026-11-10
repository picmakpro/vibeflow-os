---
name: redos-fix-probe-lookahead-and-sibling-regex
description: Après un correctif de coût quadratique de regex (cockpit parseurs, 2026-11-06), balayer toutes les regex de la même ligne et les lookaheads ; un test à 6 formes ne prouve pas la linéarité
metadata:
  type: feedback
---

Un correctif « coût linéaire » de regex laisse presque toujours des cousines : le test du codeur (P9.1, 100 000 espaces sur 6 formes) passe, et pourtant `**` + espaces dans un lookahead `\*\*[^*]+(?:ESP*:\*\*…)` reste quadratique (5,8 s à 100k), comme `\([^)]*\)` sur `((((`.

**Why:** le motif dangereux est deux quantificateurs adjacents sur classes qui se recouvrent (`[^*]+` puis `ESP*`) ; un `(?<!\s)` n'enlève que les départs multiples, pas le recouvrement interne. Une boucle `array.shift()` ajoutée par un correctif (lignes vides) a aussi rendu quadratique ce qui était linéaire.

**How to apply:** rejouer un harnais générique (N=20k puis 40k, ratio x4 = quadratique) sur chaque motif de formats ET chaque contexte de ligne (en-tête, valeur, puces, lignes vides, dernière ligne sans `\n`), lecture et diagnostic ; comparer à l'ancienne version extraite par `git archive` ; ne jamais conclure sur les seules formes du test du codeur. Voir [[feedback_fix-one-unclosed-delimiter-check-siblings]].
