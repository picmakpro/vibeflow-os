---
name: ship-jamais-auto-autorise
description: Le ship n'est jamais auto-autorisé — solliciter l'humain explicitement, jamais via une mention noyée dans un rapport
metadata:
  type: feedback
---

Le **ship n'est JAMAIS auto-autorisé**. L'humain est sollicité **explicitement à chaque fois**,
par une question directe — **jamais** par une mention noyée dans un rapport de fin de mandat.
Une autorisation donnée vaut **pour ce ship précis et rien d'autre** : elle ne se reconduit pas
sur une seconde phase, un second ship, ou un geste adjacent.

**Why:** règle posée par Samuel le 2026-08-05 en autorisant le ship de la Phase 24. Un rapport qui
glisse « je vais shipper » au milieu d'un pavé n'est pas un consentement : l'humain ne le voit pas
passer. Le ship touche le dépôt public et enclenche la discipline de release du `CLAUDE.md`.

**How to apply:** un mandat de ship porte son autorisation ou n'existe pas. Si le workflow propose
un second ship, une autre phase, un bump de `VERSION`, un tag, une release GitHub, un merge ou un
push non listés au mandat → s'arrêter et remonter en `finding` (`action: ask-user`), jamais
enchaîner. Voir aussi [[gate-jamais-de-repli]] : un gate de ship ne se contourne pas non plus.
