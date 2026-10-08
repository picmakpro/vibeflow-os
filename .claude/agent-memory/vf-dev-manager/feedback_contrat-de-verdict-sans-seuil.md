---
name: contrat-de-verdict-sans-seuil
description: Un contrat de juge sans seuil explicite (quand un axe est « passed ») fait rougir sur le premier mineur — une sonde « passe A, rate B » devient inatteignable
metadata:
  type: feedback
---

Phase 41.4 (2026-10-06) : le contrat de revue à deux axes ne disait pas quand un axe est `passed`.
Les relecteurs le passaient `gaps_found` dès le premier mineur. Conséquence : deux tours de sonde
brûlés sur un diff « propre » qui ratait toujours l'axe Standards. Durcir la fixture faisait en
plus rougir l'axe Spec (« ajout non demandé »).

La cause racine n'a été vue qu'au tour 2. Elle a été tranchée par Samuel (P414-D-20 : passé
= ni bloquant ni majeur). Ajouter une seconde fixture en sens inverse (Spec passe, Standards
rate sur une convention écrite) a rendu la démonstration robuste.

**Why:** un verdict sans seuil est un jugement d'humeur. Toute preuve « l'un passe, l'autre
rate » en dépend, et l'ancien verdict unique « PASS / correctifs requis » avait le même trou.

**How to apply:** avant de dispatcher une sonde sur un contrat de juge, vérifier que le contrat
fixe le seuil de `passed`. Sinon, le poser en zone grise au cadrage. Pour démontrer
l'indépendance de deux axes, prévoir d'emblée les deux sens, avec une fixture à convention écrite
pour le sens « Standards rate ». Voir [[preuve-du-chemin-heureux-ne-couvre-pas-l-echec]].
