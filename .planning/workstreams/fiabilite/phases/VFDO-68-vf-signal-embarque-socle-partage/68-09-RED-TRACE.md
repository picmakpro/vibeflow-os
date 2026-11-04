# 68-09 — trace rouge

Tâche 1 (porte de légitimité du paquet) : en attente d'un arbitrage de Samuel. Parties 1 et 3 de la tâche 2 (sonde Linux, étape `ci.yml`) : idem, non traitées ici.

## Partie 2 — compte des suites

- **Commande** : `bash scripts/check-version-sync.sh` (compte = `find plugin scripts -path '*/tests/test-*.sh' | grep -c .`, première mention `N suites` de chaque README racine).
- **Attendu (rouge)** : seule la ligne « suites » rougit, `README.md` et `README.fr.md` à `149 suites` pour 153 réelles.
- **Obtenu (rouge)**, exit 1 :
  - `✗ README.md : '149 suites' ≠ réel=153 (find */tests/test-*.sh)`
  - `✗ README.fr.md : '149 suites' ≠ réel=153 (find */tests/test-*.sh)`
  - toutes les autres lignes `✓`.
- **Correctif** : `README.md:65` et `README.fr.md:67`, `149 suites` → `153 suites` (première mention seulement ; badge et historique intacts).
- **Obtenu (vert)** : `check-version-sync.sh` exit 0 ; `check-machine-paths.sh` exit 0.
