---
name: strict-branch-fallback-audit
description: Quand une assertion choisit entre une sonde stricte et un repli permissif via un compteur, mesurer sur CHAQUE cible quelle branche est réellement prise — le repli peut être la branche par défaut partout
metadata:
  type: feedback
---

Une sonde de test qui dit « si le bloc énumère plusieurs valeurs, j'isole le segment strict ; sinon
le bloc EST le segment » n'est stricte que sur les cibles où le compteur dépasse le seuil. Avant de
valider ce genre d'assertion, instrumenter le compteur sur **chacune** des cibles réelles et
constater la branche prise. Ne jamais déduire la couverture du fait que la mutation témoin (choisie
par l'auteur, sur la cible qui déclenche la branche stricte) rougit bien.

**Why:** phase 23 nœud `revue-01`, `test-dev-orchestrator.sh` T24 : le compteur ne reconnaissait le
statut que dans la graphie backtickée nue (`` `human_needed` ``), alors que la doctrine du module
l'écrit en graphie JSON (`` `statut: "human_needed"` ``). Résultat : 0 mention comptée sur 2 des 3
fichiers cibles, repli sur la co-présence dans tout le bloc — exactement la faille que la refonte
prétendait fermer —, et l'inversion sémantique du fichier de RÉFÉRENCE laissait la suite à 87 OK /
0 KO. Seule la 3e cible (forme énumérative) prenait la branche stricte, et c'est celle sur laquelle
l'auteur avait construit sa table de mutations.

**How to apply:** signal d'alerte = un `if [ "$compteur" -le N ]` qui choisit entre sonde stricte et
repli, avec un extracteur de tokens ancré sur UNE graphie. Vérifier aussi que la forme rhétorique du
texte visé correspond au modèle de la sonde : une sonde « étiquette d'abord, mapping ensuite » ne
mesure rien sur un texte écrit « prémisse ⇒ conséquence » (le statut y est en fin de phrase, les
motifs avant). Deux formes rhétoriques = deux sondes, pas un compteur élargi. Voir
[[mutation-test-regression-claims]] pour la famille voisine.
