---
name: feedback-armed-gesture-flag-stale-until-next-event
description: Un drapeau de geste armé au pointerdown et consommé au prochain évènement métier reste périmé si le geste n'en émet pas (pan, Entrée sans effet) ; sonder avec un glisser, pas un clic (cockpit 02-vf-telephone, lot B, 2026-11-08)
metadata:
  type: feedback
---

Quand un correctif remplace une fenêtre de temps par un drapeau « geste armé » (armé à `pointerdown`/`keydown`, consommé par le premier évènement `panel`), sonder le cas où le geste n'émet AUCUN évènement : un glisser (pan) sur le fond du graphe, une Entrée sans effet. Le drapeau reste armé et le rendu du flux en direct qui suit, parfois bien plus tard, agit comme si l'utilisateur venait de choisir (réouverture du panneau fermé par « Détail », focus volé si le geste était clavier).

**Why :** 02-vf-telephone.js (passe B2, 703afc91) : R15c.3 et son mutant p3 (retirer `if (!change && !g) return`) restent verts alors que `pointerdown` + glisser sur le fond puis `rerender()` rouvre le panneau (témoin sans glisser : reste fermé). Le test ne rougit que sur la forme « rendu 150 ms après Détail ».

**How to apply :** pour tout drapeau armé sur une entrée et consommé ailleurs, exiger (1) un témoin avec un geste qui n'émet rien, (2) un mutant qui vide le drapeau à `click`/`pointerup` en phase de bulle. Corriger en désarmant après le gestionnaire du viewer (écouteur bulle), pas en réintroduisant un délai.

Voir aussi [[feedback_constant-flag-matrix-nondiscriminant]] et [[feedback_retest-state-ignores-unflushed-input-buffer]].
