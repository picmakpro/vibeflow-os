# Phase 41 — registre des mesures

Chaque ligne `CLE: valeur` est une mesure consignée au moment où elle est faite. Une valeur non
mesurée s'écrit `non_prouvee` ou `indetermine`, jamais supposée. Les sorties humaines sont
recopiées verbatim dans des lignes `…-MSG:`. Aucun chemin absolu de machine.

## 41-01 — préalables externes

CONTEXTES-CHECKS: sha=5238cba66c0d878a9ff4eb1c32757c21c64b454d n=4 app=15368 egal_ci=oui

## 41-14 — base de la garde de trace

BASE-TRACE-ARBITRAGE: f1d658957f7fe9c446b341bc447c19d6a0a0ed3a
Motif : les commits de cadrage et de planification antérieurs à cette valeur précèdent la garde G-1 et ne sont pas réécrits — seule la plage `<sha>..HEAD` sera jugée par le contrôle de trace du plan 41-15.

## 41-15 — outillage de preuve du périmètre sans admin

RECENSEMENT-FERMETURE: rc=0 fichiers=20 hits=0 allowlist_entrees=3 allowlist_appliquees=3
RECENSEMENT-CONTROLES: R0=0,R1=1,R2=1,R3=1,R4=0,R5=0,R6=0,R7=2,R8=64,R9=1,R10=0,R11=0 mutants_tues=3
TRACE-ARBITRAGE: rc=0 commits=17 citants=2 base=f1d6589
TRACE-CONTROLES: C0=0,C1=1,C2=1,C3=0,C4=1,C5=0,C6=0,C7=3,C8=2,C9=64,C10=0,C11=0,C12=2,C13=2 mutants_tues=6
OUTILS-PERIMETRE: distribues=non etapes_ci=0 decouverts_par_le_job_tests=non
LIMITE-DE-FOND: exiges=7 porteurs=4 manquants=aucun
BORNE-TRACE: sha=f1d6589 source=41-PREUVES.md commits_juges=17 commits_hors_borne=1255
Note : le compte de mutants de check-trace-arbitrage.sh est passé de 4 à 6 (mesuré) au tour
précédent de ce plan, resserrement du détecteur à une liste fermée de marqueurs d'invocation.
Les valeurs `commits=`/`citants=`/`commits_juges=` ci-dessus sont mesurées juste avant l'écriture
de cette section ; toute mesure ultérieure du même contrôle inclura, en plus, le commit qui
introduit cette section elle-même — propriété déjà présente pour `BASE-TRACE-ARBITRAGE` et non
un défaut de cette mesure.
