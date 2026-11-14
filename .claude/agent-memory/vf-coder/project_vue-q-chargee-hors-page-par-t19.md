---
name: vue-q-chargee-hors-page-par-t19
description: La vue du terminal (vueTerminal) est aussi chargée dans Node sans document par la sonde de parité T19 de terminal-page ; tout écouteur posé à l'initialisation doit être gardé par typeof document.
metadata:
  type: project
---

Phase 72 lot 8 LB2 (2026-11-06) : `document.addEventListener(...)` au niveau de `vueTerminal` a rougi T19.0 à T19.5
de `test-cockpit-terminal-page.sh` (« Node.js v26 » + stack, attendu « PALETTE 15/15 », obtenu vide) alors que la
vue marchait en navigateur. T19 importe la vue seule pour lire `theme()` ; `theme` se gardait déjà par `typeof document`.

**Why:** la panne se lit dans la suite de PALETTE, loin de la cause (un écouteur ajouté pour le bandeau).
**How to apply:** dans `vf-cockpit-terminal-vue.mjs`, tout état ou écouteur posé hors des méthodes du bandeau est entouré
de `if (typeof document === 'object' && document && typeof document.addEventListener === 'function')`.
Autres gardes de la même famille mesurées par `test-cockpit-lancer-bandeau.sh` : LB.S1 (aucun `<chiffre>px`, `rgb(`
comptés), LB.S3 (plafond de lignes, relevé à 290/290 par LB2 faute de pouvoir faire tenir les textes arbitrés en 215),
LB.V5 (aucun `svg` hors `.vf-q-risque`).
