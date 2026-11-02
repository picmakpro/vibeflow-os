# 67-FIX-D — hygiène des tests du cockpit (4e tour hors budget, P67-G1)

Accord de Samuel, AskUserQuestion session principale, 2026-11-02 : « Oui, 4e tour (Recommandé) ». Périmètre : plugin/cockpit/scripts/tests/** uniquement, aucun code livré touché.

- `hygiene.sh` : marque = nom de base du mktemp -d, validée (tmp.+6 alphanumériques, ≥ 8) avant tout usage ; transmise à awk par l'environnement ; plafond de 20 processus (au-delà : rouge, aucun kill) ; jamais $$, $PPID, ancêtre, pid ≤ 1 ; VF_HYG_DRY=1 pour simuler. Garde awk dans END (un `exit` en BEGIN n'évite pas END).
- 11 suites câblées (assertion H0 de fin + filet EXIT) ; serveurs lancés en `exec` avec stdout détaché ; Chrome marqué par VF_CDP_TAG.
- Cause de la reconnexion bloquée 28 min : le sous-shell du lanceur gardait ouvert le tube de `$(reco …)` tant que le serveur vivait ; si Chrome échouait avant d'arrêter le serveur, la substitution ne revenait jamais.
- Témoin rouge : VF_TEST_INJECTER_FUITE=1 (serveur) ou =chrome nomme le seul processus injecté (pid + commande marquée).
- Preuve : 17 suites en séquence vertes à fuite nulle (deux fois) ; 5 suites navigateur en parallèle (3 flux) deux fois, 0 FAIL, 0 fuite.
- Reste hors périmètre : 86 serveurs `tmp.*/serve.mjs` orphelins antérieurs (non lancés par ce tour), à arrêter par leur propriétaire.

## Addendum — revue fix-67-d (gaps_found), correction ciblée (P67-G1, accord de Samuel, AskUserQuestion session principale, 2026-11-02)

- M1 : `vf_hyg_kill` vérifie la ligne de commande COURANTE (`ps -o args= -p`) avant CHAQUE signal ; plus de KILL sur la foi d'un `kill -0` ; `vf_hyg_stop` arrête un PID marqué et le retire de PIDS ; tous les `kill` par PID nu des suites y passent.
- m1 : cibles = descendants de la suite et arbres orphelins (sommet rattaché à pid 1 portant la marque), copies de nos propres sous-shells exclues. Limite : un orphelin n'est reconnu que rattaché à pid 1. m2 : témoin ps (H-0). m3 : en-tête G3 corrigé (la garde utile est H1). m5 : marque validée sur la chaîne entière. m6 : plafond de 20 conservé, limite documentée.
- m4 : `test-cockpit-hygiene.sh`, à sec, 10 mutants (G1, G2, G2-ancre, G3, G4-vivants, G4-kill, M1-kill, M1-purge, m1, m2), chacun tué par l'assertion visée. Compteur de suites : 142.
- Cause du rouge de securite X1-X3 et responsive R1/R2 sous HOME temporaire : `export REAL_HOME="$HOME"` prenait déjà le HOME vide ; Chrome ne répondait plus (« Page.navigate : pas de réponse en 90000 ms »). Mesuré : securite seule, HOME temporaire, ancien harnais, rouge en 190 s. Correctif de harnais : `chromeHome()` (HOME du compte). X1-X3 nomment l'erreur de mesure. Code livré non touché.
- Preuve (rejeu du 2026-11-02, 01:18-01:28) : securite puis responsive seules en HOME temporaire, vertes (37 s, 38 s) ; 18 suites en séquence, HOME temporaire puis HOME réel, 36 sur 36 rc 0, fuite marquée nulle, leurre non marqué vivant après chaque lancement ; 5 suites navigateur en parallèle (3 flux), rc 0, fuite 0, 75 s.
- Note de méthode : pendant la discrimination, mon script a temporairement remplacé `chrome-session.mjs` par la version de HEAD dans l'arbre, puis je l'ai rétabli depuis une copie du scratchpad (déclaré au manager).
