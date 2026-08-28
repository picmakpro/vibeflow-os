---
name: constant-flag-matrix-nondiscriminant
description: Une "matrice générique" à N dimensions peut figer une dimension à une valeur constante à travers ses deux appels — mutation révèle que la majorité des séquences ne mordent pas le correctif
metadata:
  type: feedback
---

Quand une suite affirme couvrir un espace produit (ex. "8 séquences forme x forme x flag") pour
prouver une propriété d'idempotence sur DEUX appels successifs, vérifier si le paramètre binaire
(ici `--settings-local` on/off) est appliqué **indépendamment par appel** ou **maintenu constant
aux deux appels dans chaque séquence**. La seconde forme réduit silencieusement le sous-espace
réellement exercé : elle rend indiscernables les transitions (paramètre change entre les deux
appels) des non-transitions (paramètre identique), alors que ce sont précisément les transitions
qui exercent le mécanisme de purge croisée visé par le correctif.

**Why:** phase 30, exec-30-01 (revue-30-01, comblement T19-T21 de `merge-hooks.sh`). T21 se
présentait comme une "matrice générique 8 séquences" (forme1 × forme2 × flag constant on/off).
Mutation (revert du correctif `3d6731a`, garder les tests) a montré que **6 des 8 séquences
restaient vertes sur le code cassé** — seules 2 (les deux transitions forme shell↔exec avec flag
constant à `on`) mordaient réellement, et ces deux-là dupliquaient déjà T19/T20. Les 4 séquences
à flag constant `off` n'exerçaient AUCUN code du correctif (le paramètre `other_hooks` reste `None`
aux deux appels, donc les lignes ajoutées par le fix ne s'exécutent jamais) — elles auraient été
vertes identiques sur n'importe quelle version du script, corrigée ou non.

Complément positif : sondage manuel de la transition non couverte par la suite mais réellement
atteignable (`exec+flag=off` → `exec+flag=on`, cf. [[feedback_mutation-test-regression-claims]])
a confirmé que le CORRECTIF lui-même généralise correctement au-delà des cas nommés — c'est la
SUITE qui sur-vend sa couverture, pas le correctif qui est incomplet. Distinguer les deux dans le
rapport : un correctif peut être juste avec une suite qui ne le prouve pas.

**How to apply:** sur toute suite qui prétend "matrice/produit cartésien" pour une propriété à
deux invocations (merge, sync, dédup...), 1) identifier si un paramètre est gelé identique aux
deux appels au lieu de varier indépendamment ; 2) muter le correctif visé et compter précisément
combien de séquences virent au rouge — rapporter ce ratio (ex. "2/8 discriminantes") plutôt que le
nombre brut de cas listés ; 3) si le paramètre gelé masque des transitions non testées mais
atteignables, les sonder soi-même en isolation avant de conclure sur la fermeture de la classe.
Voir [[feedback_mirror-gate-superset-drift]] (famille : couverture apparente qui masque une
divergence) et [[feedback_mutation-test-regression-claims]] (méthode de mutation).
