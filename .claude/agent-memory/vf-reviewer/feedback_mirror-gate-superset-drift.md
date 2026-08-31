---
name: mirror-gate-superset-drift
description: Un moteur factice de fixture modelé « proprement » masque la divergence même qu'il devrait attraper — comparer les ensembles réels par calcul, pas par échantillon
metadata:
  type: feedback
---

Quand une suite teste un gate qui **reproduit** un verdict amont, ne jamais se fier au moteur factice
de la fixture : il est écrit par la même personne que le gate, donc il partage ses hypothèses.

**Why:** phase 23 / 23-02. Le moteur factice de `test-check-gsd-config.sh` déclare un
`CONFIG_DEFAULTS` dont tous les premiers segments (`mode`, `project_code`, `parallelization`,
`planning`, `workflow`) sont **aussi** dans `VALID_CONFIG_KEYS`. Dans le vrai moteur ils ne le sont
pas : 6 clés de premier niveau divergent. La suite était donc structurellement **incapable** de voir
le faux négatif — 26 cas verts, y compris deux cas « contre le moteur réel », et le bug est passé
deux tours de revue. Les deux cas contre le moteur réel échantillonnaient (`depth`,
`branching_strategy`, un bloc bidon) au lieu de mesurer la **différence d'ensembles**.

**How to apply:** sur tout gate-mirroir,
1. calculer soi-même `set(script) ∖ set(amont)` **et** `set(amont) ∖ set(script)` sur les sources
   réelles, et exiger que les deux directions soient nommées dans la doc du script ;
2. exiger que la sonde d'atteinte porte sur cette différence, pas sur des littéraux choisis — un
   littéral **ajouté** en amont est le cas de dérive le plus probable et l'échantillonnage y est
   aveugle ;
3. exécuter le **correctif** comme un mutant : s'il laisse la suite verte, la suite n'enshrine pas le
   bug (bon signe) ; s'il la rend rouge, la suite protège le bug (à corriger d'abord).

Complète [[feedback_mutation-test-regression-claims]] (muter le code pour prouver qu'une assertion
mord) et [[feedback_strict-branch-fallback-audit]]. Cas concret :
[[project_gsdc-07-federated-schema-gap]].
