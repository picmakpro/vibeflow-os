---
quick_id: 261001-wtd
date: 2026-10-01
mode: validate
workstream: gouvernance
---

# Quick 261001-wtd — correction ciblée du re-audit de sécurité (Phase 45)

Mandat du manager vf-dev-manager, nœud `fix-reaudit`, après le re-audit à regard frais (OPEN_THREATS). Exécution séquentielle directe, aucun sous-agent.

## Tâches

1. N-01 : le repli refuse toute valeur trop longue qui contient `.planning` ou `.claude` (tout cwd) ; le cœur décide dans le doute un chemin non analysable (jamais le code 3). Tests R-DOUTE-01, R-DOUTE-02 et mutants.
2. N-03 : `~` et `~/…` développés en HOME dans les deux couches, `~utilisateur` tranché dans le doute. Mêmes tests, limite (ab) réécrite.
3. N-05 : raison de G6 pour un `config.json` qui déclare `cycles-v1` hors de la forme du repli. Test R-ADH-REPLI et mutant.
4. N-02, N-04, N-06 : textes (limites (aa), (ab), (a), CHANGELOG, `poser-verdict.sh`).
5. Preuves : suites au premier plan, contrôle de marqueur, zéro régression dev, rejeu réel en lecture seule.

## Contraintes

Q-ARM : aucun cas ni mutant supprimé ou affaibli. P45-D-10 : Bash reste ouvert. GATE-03 : un lab non adhérent n'est pas refusé dans le cas courant. Aucune release, aucune constante `ARMEMENT_*`, `TABLE_ATTENDUE`, `VERSION`.
