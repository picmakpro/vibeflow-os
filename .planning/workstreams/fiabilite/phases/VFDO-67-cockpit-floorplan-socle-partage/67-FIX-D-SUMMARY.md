# 67-FIX-D — hygiène des tests du cockpit (4e tour hors budget, P67-G1)

Accord de Samuel, AskUserQuestion session principale, 2026-11-02 : « Oui, 4e tour (Recommandé) ». Périmètre : plugin/cockpit/scripts/tests/** uniquement, aucun code livré touché.

- `hygiene.sh` : marque = nom de base du mktemp -d, validée (tmp.+6 alphanumériques, ≥ 8) avant tout usage ; transmise à awk par l'environnement ; plafond de 20 processus (au-delà : rouge, aucun kill) ; jamais $$, $PPID, ancêtre, pid ≤ 1 ; VF_HYG_DRY=1 pour simuler. Garde awk dans END (un `exit` en BEGIN n'évite pas END).
- 11 suites câblées (assertion H0 de fin + filet EXIT) ; serveurs lancés en `exec` avec stdout détaché ; Chrome marqué par VF_CDP_TAG.
- Cause de la reconnexion bloquée 28 min : le sous-shell du lanceur gardait ouvert le tube de `$(reco …)` tant que le serveur vivait ; si Chrome échouait avant d'arrêter le serveur, la substitution ne revenait jamais.
- Témoin rouge : VF_TEST_INJECTER_FUITE=1 (serveur) ou =chrome nomme le seul processus injecté (pid + commande marquée).
- Preuve : 17 suites en séquence vertes à fuite nulle (deux fois) ; 5 suites navigateur en parallèle (3 flux) deux fois, 0 FAIL, 0 fuite.
- Reste hors périmètre : 86 serveurs `tmp.*/serve.mjs` orphelins antérieurs (non lancés par ce tour), à arrêter par leur propriétaire.
