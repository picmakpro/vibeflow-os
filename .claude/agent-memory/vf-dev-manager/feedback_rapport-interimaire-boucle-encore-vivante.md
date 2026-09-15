---
name: rapport-interimaire-boucle-encore-vivante
description: Un worker peut finir son tour en disant « la boucle tourne encore, je rapporte après » — il a ENDED ; son fichier de sortie est partiel et un décompte partiel se lit exactement comme un décompte final
metadata:
  type: feedback
---

Quand un worker rend un rapport **intérimaire** (« 10/11 étapes faites, la boucle des 78 suites
tourne encore, je rapporte quand elle finit »), ne pas attendre une seconde notification
spontanément : son tour est **terminé**, et le processus d'arrière-plan a pu mourir avec lui. Le
réveiller par `SendMessage` sur son agentId, jamais dispatcher un remplaçant.

**Why:** Phase 25 (2026-09-15), nœud de non-régression. Le worker a rendu un intérimaire pendant que
la boucle complète tournait. Deux pièges se superposaient : d'une part, un résultat **partiel** se lit
trait pour trait comme un résultat final (« 0 échec » sur 12 suites exécutées ressemble à « 0 échec »
sur 78) ; d'autre part, sur ce poste `timeout`/`gtimeout` sont absents, donc un décompte tronqué ne
produit aucune erreur. Réveillé avec la consigne explicite de vérifier l'intégrité du processus et de
relancer au moindre doute, il a rendu 78 découvertes / 78 exécutées / 0 échec, avec les deux ensembles
comparés par `comm` (0 ligne d'écart) plutôt que par égalité de nombres.

**How to apply:** au réveil, trois consignes non négociables dans le message — **(1)** ne pas supposer
que le processus d'arrière-plan a survécu, relancer entièrement au moindre doute ; **(2)** compter les
unités RÉELLEMENT exécutées par `awk 'END{print NR}'` sur un fichier de résultats, jamais sur une
sortie pipée ; **(3)** comparer l'ensemble exécuté à l'ensemble découvert par `comm`, jamais leurs
cardinalités. Complète [[transcript-fige-ne-prouve-pas-worker-mort]] (là, l'agent semblait mort et ne
l'était pas ; ici il annonce lui-même une suite qui n'arrivera jamais seule) et
[[non-regression-sur-la-decouverte-complete]].
