---
name: summary-aggregate-counts-verify
description: Recompter soi-même les totaux agrégés (nb de suites, nb de tests) cités dans un SUMMARY plutôt que de faire confiance au récit — même quand le résultat qualitatif (0 FAIL) est vrai
metadata:
  type: feedback
---

Un SUMMARY de plan GSD peut citer un total agrégé faux (ex. « 37 suites toutes vertes ») alors que
le résultat qualitatif rapporté est correct (0 échec) — vérifié sur le plan 20-02 de la phase 20
(`vibeflow-os`, commit `dc84a92`) : `find plugin scripts -type f -path '*/tests/test-*.sh' | wc -l`
rendait 42 au moment de la revue, pas 37, alors qu'aucun commit n'avait été ajouté après le SUMMARY
pour expliquer l'écart.

**Why:** le chiffre agrégé n'est presque jamais vérifié par la suite (contrairement au 0 FAIL/0 KO
qui est la métrique qu'on rejoue systématiquement) — c'est le genre d'affirmation qui survit
plusieurs relectures sans jamais être recalculée, et qui finit citée ailleurs comme un fait.

**How to apply:** quand un SUMMARY affirme un total (nombre de suites, de fichiers, de tests) issu
d'une commande de découverte (`find`, `grep -c`, un compteur de boucle), rejoue la commande de
découverte telle qu'écrite dans la CI plutôt que de faire confiance au chiffre cité — même si le
verdict qualitatif (PASS/0 FAIL) est par ailleurs vérifié et correct. Un écart de comptage sans
commit explicatif est un signal (mineur, pas bloquant) que le chiffre a été recopié d'une exécution
antérieure ou mal recompté. Voir aussi [[mutation-test-regression-claims]] pour la même discipline
appliquée aux claims de mutation testing (celles-là, en revanche, se sont avérées exactes ici après
rejeu).
