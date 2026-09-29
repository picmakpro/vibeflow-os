---
name: plafond-en-division-entiere
description: Un plafond de ratio écrit en division entière (`x >= total / 4`) est TOUJOURS vrai sur une petite cible — l'exprimer en multiplication ; et un extracteur de table markdown attrape les lignes de bloc de code
metadata:
  type: feedback
---

Deux modes de défaut **silencieux** mesurés en écrivant un gate qui juge un fichier (plan 41.1-05,
2026-09-24). Tous deux passent la recette sur la cible réelle et ne cassent que sur les fixtures —
ou masquent sans bruit.

**1. Un plafond de ratio en division entière est toujours vrai sur une petite cible.**
`[ "$exemptees" -ge $((total / 4)) ]` vaut `-ge 0` dès que `total < 4` : toute fixture de quelques
lignes sort en NON VÉRIFIABLE alors qu'elle est conforme. Écrire `[ $((exemptees * 4)) -ge "$total" ]`
— même énoncé, aucun arrondi. **Why** : la recette du plan ne jouait le plafond que sur le fichier
réel (2306 lignes), où la division ne pose pas de problème ; c'est la suite du module, qui fabrique
des fixtures minuscules, qui a révélé le défaut. **How to apply** : dès qu'un seuil s'écrit en
fraction d'un total, le tester sur une cible de 1 à 5 unités, pas seulement sur la vraie.

**2. Un extracteur de table markdown attrape aussi les lignes de bloc de code.** Filtrer sur
`/^[[:space:]]*\|/` suffit à avaler une continuation de pipeline shell (`  | awk '…'`) écrite dans
un bloc ` ```bash `, et les lignes d'une table VOISINE. Mesuré : 23 entrées « recensées » au lieu de
21, dont un fragment de programme awk. **Why** : un ensemble de référence pollué ne rougit jamais —
il ne peut que masquer un oubli en le déclarant connu. **How to apply** : filtrer en plus sur le
nombre de champs (`NF >= 5` pour une table à 3 colonnes) et sur la FORME de la première cellule
(un chemin n'a pas d'espace) ; et rédiger les blocs de code de façon qu'aucune ligne ne commence
par `|`.

Voisines : [[project-awk-pieges-mesures]], [[gate-jamais-de-repli]],
[[existence-au-lieu-de-relation]].
