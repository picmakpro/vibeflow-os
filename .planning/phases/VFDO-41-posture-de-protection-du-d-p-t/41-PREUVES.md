# Phase 41 — registre des mesures

Chaque ligne `CLE: valeur` est une mesure consignée au moment où elle est faite. Une valeur non
mesurée s'écrit `non_prouvee` ou `indetermine`, jamais supposée. Les sorties humaines sont
recopiées verbatim dans des lignes `…-MSG:`. Aucun chemin absolu de machine.

## 41-01 — préalables externes

CONTEXTES-CHECKS: sha=5238cba66c0d878a9ff4eb1c32757c21c64b454d n=4 app=15368 egal_ci=oui

## 41-14 — base de la garde de trace

BASE-TRACE-ARBITRAGE: f1d658957f7fe9c446b341bc447c19d6a0a0ed3a
Motif : les commits de cadrage et de planification antérieurs à cette valeur précèdent la garde G-1 et ne sont pas réécrits — seule la plage `<sha>..HEAD` sera jugée par le contrôle de trace du plan 41-15.
