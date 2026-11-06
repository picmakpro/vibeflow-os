# 72-14 — Trace du rouge (valeur fixe `proposition` côté P)

## Contrôle d'entrée

- Base : `origin/main` = 57e7957f0e0e59d31eacd9562aa80ed0c12226d2 ; `git merge-base --is-ancestor 078e58da HEAD` : oui (clôture 71 présente). Module cockpit `VERSION` : v1.3.3. Tiroir : `vf-cockpit-terminal-tiroir.mjs`, ligne 51 et 56 posent `z.style.bottom` (inversion de la pastille, la pastille est sous `#zoom`). Le tiroir mesure 215 lignes.
- Émetteur de Q (72-08) : clé `K` = `proposition` dans la table `MESSAGES` du client (`vf-cockpit-terminal-client.mjs` ligne 10) ; appel `emettre('proposition')` ligne 73 (`if (nouveau) emettre('proposition'); // garde:emission`).
- Cas froid : le sondage `lire(); setInterval(lire, PROPOSITION_MS)` est posé ligne 91, AVANT `Promise.all([polices, visible()]).then(demarrer)` (ligne 278). Donc, une fois la page de Q chargée et son cadre encadré, le message PEUT partir même si le cadre est de taille nulle. Verdict : « froid : le message peut partir », sous la condition que le cadre de Q existe. Reste le cas où P n'a jamais créé le cadre (tiroir jamais ouvert, pas d'amorçage) : l'écouteur de P exige `cadre` non nul (`if (!cadre || !accepte(...))`), et sans cadre Q n'est pas chargée : aucune proposition ne peut s'annoncer. Remontée au manager : seul le cas « cadre pas encore créé » reste non couvert (le plan ne le contourne pas : aucun canal P vers Q).

## Rouge

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-terminal-tiroir.sh` sur la base (aucun code du plan) : rc=1, 64 PASS / 11 FAIL, tous les FAIL portent TP. Les assertions existantes (TU, T8, T17, T20, T21, T22, mutants M-*) sont toutes vertes. La suite a été jouée sous bash.

- TP.1 — attendu `ajouts72=proposition` ; obtenu `ajouts72=` (ligne 2 identique à T17.4b).
- TP.2 — attendu `prop=oui …` ; obtenu `prop=non` (valeur absente de la liste ; les sept refus sont déjà vrais).
- TP.3 — attendu `q=9 p=9 egal=true cle=proposition appel=true` ; obtenu `q=9 p=8 egal=false cle=proposition appel=true` (Q émet déjà la valeur, P ne l'accepte pas).
- TP.4 — attendu `ouvre=true focus=temoin cadres=1 shell=meme annonce=Proposition de lancement dans le terminal.` ; obtenu `ouvre=false … annonce=Terminal fermé` (le message de Q est reçu par P, le tiroir reste fermé : raison valable, témoin TP.0 vert : scénario sans erreur, tiroir fermé avant, valeur parvenue à P).
- TP.5, TP.7, TP.8 — rouges parce que le tiroir ne s'ouvre pas (`ouvert=false`, `cycle=false`, `ouvre=false`) ; elles portent un témoin d'ouverture pour ne pas verdir à vide.
- TP.6 — refus tous vrais (`deP, forge, suffixe, majuscule, espace, long : true`), témoin positif `vivant` faux sur la base (le canal de Q n'ouvre rien) : rouge sur le seul témoin.
- Mutant M-MESSAGE-LIBRE (TP.9) : tué, ligne `prop-suffixe=oui` (la cible existe sur la base). M-LISTE-SANS-PROPOSITION (TP.10), M-PROPOSITION-COMME-ETAT (TP.11), M-FOCUS-VOLE (TP.12) : « sans effet » sur la base (le code qu'ils mutent n'existe pas encore), donc rouges, rejoués sur le code livré à la tâche 2.
