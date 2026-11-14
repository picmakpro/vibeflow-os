---
name: vert-par-effet-de-bord-produit
description: Un juge peut être vert parce que le produit fait la même chose tout seul (D3.3 : auto-fit de la visite) — exiger le mutant « fonction morte » avant de croire un rouge corrigé
metadata:
  type: feedback
---

Quand une sonde mesure « le geste X produit l'effet E », exiger un mutant qui rend X inopérant et vérifier qu'il rougit :
si le produit produit E par un autre chemin (animation, auto-ajustement, relecture périodique), le cas est vert à vide.

**Why:** mission sondes-stables (2026-11-08), git-tiroir D3.3 : `f` (ajustement) « marchait » parce que la visite guidée
relançait `SC.fit(true)` d'elle-même à 450 ms (`ui/40-tour.js:249`) ; le cas était déjà non discriminant à a286f0fa et a
rougi en CI quand la sonde a été rendue plus stricte. Preuve par mutant `f` mort : D3.3 restait vert. Correctif : `#t`
(pas de visite), exiger changement + animation pendant `f`, mutant M-AJUSTEMENT ajouté (149f762d). Même famille que H8.1
(git-entete) : seconde lecture légitime provoquée par le scénario lui-même (tick du filet après `git switch`).

**How to apply:** à chaque correction d'un rouge de sonde, demander « quel autre mécanisme du produit produit le même
observable ? » et le mutant de la propriété avant d'accepter le vert. Voir [[mutation-qui-echoue-pour-la-mauvaise-raison]].
