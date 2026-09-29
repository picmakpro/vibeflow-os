---
name: cas-vert-des-deux-cotes-ne-garde-rien
description: Un cas de test vert avant comme après un correctif ne garde rien — le laisser porter un nom de témoin fait compter deux gardes là où il n'y en a qu'une
metadata:
  type: feedback
---

Un cas de test **vert avant comme après** le correctif ne garde rien. Ne pas le rendre discriminant
de force (ça n'ajoute aucune couverture, seulement du bruit) — mais **ne pas le laisser porter un
nom de témoin de bascule**. Le renommer pour dire ce qu'il est (une observation documentaire), et
nommer au SUMMARY la garde réellement effective.

**Why:** le coût n'est pas le cas inutile, c'est **le crédit qu'on lui accorde** : le prochain
lecteur compte deux gardes là où il n'y en a qu'une. Constaté le 2026-09-23 sur le plan 41.1-09 —
le cas `BASCULE-REL-ABS` est vert dans les deux états (les codes diffèrent de la valeur attendue
avant comme après : 0≠2 puis 64≠2), alors que `ABSOLU-64` est le seul témoin réellement mesuré
rouge contre le script pré-correctif. Ce dépôt a déjà payé dix vérificateurs incapables d'échouer
en Phase 39, tous invisibles à la relecture (cf. mémoire projet « une preuve doit pouvoir rendre
rouge »).

**How to apply:** quand un worker signale honnêtement qu'un de ses cas est vert des deux côtés —
et c'est un bon signe qu'il le signale — ne pas se contenter de le consigner : exiger le renommage.
Vérifier aussi qu'aucun `acceptance_criteria` ni SUMMARY ne le compte comme preuve de la propriété.
Symétriquement, ne pas exiger qu'il devienne discriminant si une autre assertion garde déjà la
propriété : mesurer laquelle rougit vraiment, et l'écrire.

Voir aussi [[feedback_phase-cree-ferme-revele-consigne]], [[feedback_mutation-qui-echoue-pour-la-mauvaise-raison]].
