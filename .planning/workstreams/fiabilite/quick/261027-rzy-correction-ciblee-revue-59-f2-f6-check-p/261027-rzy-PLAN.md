---
quick_id: 261027-rzy
description: Correction ciblée revue-59 F2-F6 (check-prd, sondes, ancres, redirection)
---

# Plan — correction ciblée revue-59

Mandat `fix-revue-59` (nœud DAG), exécution inline par vf-coder (pas de planner/executor séparés).

1. F2/F3 : `check-prd.sh` — remplissage français en mots entiers, longueur en caractères, commentaires HTML, fence non fermée = INDETERMINE, cases non reconnues signalées.
2. F4 : `test-check-prd.sh` — onze sondes, mutants CPRD-MUT-9..26.
3. F5 : ancres de seuil par occurrence (`test-product-team-bundle.sh`) ; T44 (b2) clauses sémantiques.
4. F6 : `product-routing.md` §2, clause du skill absent.

Vérification : suites `test-check-prd`, `test-product-team-bundle`, `test-dev-orchestrator`, budget d'instructions (head 33), `check-version-sync`.
