---
name: prose-du-manager-entre-dans-le-recensement
description: Le texte de suivi que j'écris dans STATE.md peut créer une occurrence que le recensement de la phase compte, sans qu'aucun plan puisse la traiter
metadata:
  type: feedback
---

Quand une phase recense un motif dans tout le dépôt (ancien plafond, nom retiré), mon propre texte de suivi (STATE.md, rapport de mission) ne doit pas citer ce motif sous sa forme brute. Je le décris au lieu de le recopier.

**Why:** Phase 40.1, 2026-09-16. En STATE.md, j'avais écrit « `git grep -w 250` en donnait bien moins ». Le checker frais du tour 4 l'a relevé comme bloquant : 115 lignes sur la branche contre 114 sur main. Aucun plan n'écrit STATE.md, donc la clôture aurait rougi et exigé un arbitrage.

**How to apply:**
- Avant de commiter du suivi pendant une phase de recensement, rejouer le recensement, ou au moins vérifier que mon texte ne contient pas le motif.
- Écrire par exemple « la valeur de l'ancien plafond ».
- Voir aussi [[preuve-du-chemin-heureux-ne-couvre-pas-l-echec]].
