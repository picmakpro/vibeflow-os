---
name: cout-correction-ciblee-vf-coder
description: une correction ciblée vf-coder à 4 arbitrages avec témoins rouges et mutants coûte ~200k tokens — un budget de 300k ne loge pas aussi une revue
metadata:
  type: project
---

Une correction ciblée de vf-coder (BL35 relève 3, 2026-11-05) portant 4 arbitrages, chacun avec témoin rouge sur le SHA d'avant, mutants et rejeu de 10 suites, a consommé 203 k tokens à elle seule. Budget du mandat : 300 k cumulés. La re-revue ne tenait plus.

**Why:** l'exigence de preuve (rouge sur l'ancien SHA via git archive, mutant par arbitrage, rejeu de toutes les suites qui exercent la fonction) multiplie le coût, bien au-delà du diff (155 lignes).

**How to apply:** avec un budget serré, chiffrer ~50 k par arbitrage prouvé et annoncer d'emblée à la session principale si worker + revue + livraison ne tiennent pas, ou borner explicitement les preuves (mutants seulement sur les arbitrages de sécurité). Voir [[revue-obligatoire-cout-erreur-asymetrique]].
