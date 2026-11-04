# 71-10 — trace du rouge du lanceur `--terminal`

- date : 2026-11-03
- base : HEAD `03518b44`, `vf-cockpit.mjs` sans `--terminal` (`argument inconnu : --terminal`, sortie 64)
- commande : suite jouée contre le lanceur de la base (copie du module dont `vf-cockpit.mjs` = `git show 03518b44:plugin/cockpit/scripts/vf-cockpit.mjs`) : `bash test-cockpit-terminal-lanceur.sh` — rc=1, `Résultats : 7 PASS / 27 FAIL`
- première passe (commit `26dd20d6`, avant correction de deux défauts de la suite : arguments du client `flux`, couche de garde de L4) : 8 PASS / 26 FAIL, mêmes causes ; la trace ci-dessous est celle de la suite finale.
- témoins verts sur la base (contrôles positifs) : L0 (build, status), L11 (garde existante sur PID leurre, `--rebuild`), L7 témoin (sans drapeau : sortie 0, pas de clé terminal), L6 témoin `--no-open`, L10 « aucun amorçage ».
- écart au plan : L11 est scindé en L11 (garde existante, vert sur la base) et L11b (même scénario avec `--terminal`, rouge sur la base) ; le plan demande un L11 vert sur la base ET `open --terminal`, ce que sortie 64 empêche.

Chaque rouge a la même cause racine : le lanceur rejette `--terminal` (sortie 64, « argument inconnu : --terminal »), donc aucun serveur avec terminal, aucun amorçage, aucune ouverture de Q ; les quatre mutants n'ont rien à muter (« mutant sans effet »).

## Témoins rouges (27)

### FAIL — L1 — open --terminal --no-open sort 0
- attendu : `[0]`
- obtenu : `[64]`

### FAIL — L2 — server.json porte terminal.url de forme http://127.0.0.1:<Q>, Q différent de P
- attendu : `[oui]`
- obtenu : `[non : ]`

### FAIL — L3 — le fichier d'amorçage est en mode 600
- attendu : `[600]`
- obtenu : `[absent]`

### FAIL — L5 — témoin : l'amorçage lu est 64 hexadécimaux
- attendu : `[oui]`
- obtenu : `[non : vide]`

### FAIL — L5 — témoin : la recherche trouve la valeur dans le fichier d'amorçage
- attendu : `[1]`
- obtenu : `[pas de valeur]`

### FAIL — L5 — l'amorçage n'est pas dans la sortie du lanceur
- attendu : `[0]`
- obtenu : `[pas de valeur]`

### FAIL — L5 — l'amorçage n'est pas dans le journal du serveur
- attendu : `[0]`
- obtenu : `[pas de valeur]`

### FAIL — L5 — l'amorçage n'est pas dans server.json
- attendu : `[0]`
- obtenu : `[pas de valeur]`

### FAIL — L5 — l'amorçage n'est pas dans la ligne de commande du serveur (témoin : elle cite serve.mjs)
- attendu : `[oui]`
- obtenu : `[non : ]`

### FAIL — L6 — une seule ouverture
- attendu : `[1]`
- obtenu : `[0]`

### FAIL — L6 — l'adresse ouverte est http://127.0.0.1:<Q>/#t=<amorçage du fichier>, Q ≠ P
- attendu : `[oui]`
- obtenu : `[non : [] Q= P=]`

### FAIL — L4 — serveur arrêté, lien préplacé : la cible est intacte, refus nommé ou fichier ordinaire
- attendu : `[sur]`
- obtenu : `[non]`

### FAIL — L4 — serveur vivant avec terminal (O2 c), lien préplacé : la cible est intacte, refus nommé ou fichier ordinaire
- attendu : `[sur]`
- obtenu : `[non]`

### FAIL — L7 — le PID du serveur a changé, l'ancien est mort, terminal.url est présent
- attendu : `[oui]`
- obtenu : `[non : 37270 -> 37270]`

### FAIL — L8 — l'amorçage 1 est accepté (200)
- attendu : `[200]`
- obtenu : `[ERREUR ECONNREFUSED]`

### FAIL — L8 — même PID de serveur, sortie 0
- attendu : `[0 37270]`
- obtenu : `[64 37270]`

### FAIL — L8 — nouvel amorçage en 600, différent du premier
- attendu : `[600 different]`
- obtenu : `[absent identique]`

### FAIL — L8 — l'ancien amorçage est refusé (403)
- attendu : `[403]`
- obtenu : `[ERREUR ECONNREFUSED]`

### FAIL — L8 — le nouvel amorçage est accepté (200, secret de 64 hexadécimaux)
- attendu : `[200 secret-64-hex]`
- obtenu : `[ERREUR invalide : ECONNREFUSED]`

### FAIL — L9 — une commande envoyée revient dans le flux (TRACEUR-OK)
- attendu : `[TROUVE]`
- obtenu : `[pas de secret]`

### FAIL — L9 — stop : serveur, assistant et shell disparus en moins de 5 s
- attendu : `[aucun]`
- obtenu : `[rien à surveiller (assistant=aucun shell=aucun)]`

### FAIL — L10 — le message « Terminal indisponible sous Windows. » est rendu
- attendu : `[Terminal indisponible sous Windows.]`
- obtenu : `[argument inconnu : --terminal Usage : node vf-cockpit.mjs [open|build|stop|status] [--lab <dossier>] [--no-open] [--port <p>] [--rebuild]   open    assemble le cockpit du lab s'il le faut, démarre le serveur local et rend l'adresse (défaut)   build   assemble`

### FAIL — L11b — avec --terminal (O2 a), le PID leurre n'est jamais arrêté : sortie 5, leurre vivant, aucun amorçage posé
- attendu : `[5 vivant sans-amorce]`
- obtenu : `[64 vivant sans-amorce]`

### FAIL — M-MODE — mutant sans effet (cible absente ou inchangée)
- attendu : `[effet]`
- obtenu : `[sans effet]`

### FAIL — M-SUIT-LIEN — mutant sans effet (cible absente ou inchangée)
- attendu : `[effet]`
- obtenu : `[sans effet]`

### FAIL — M-IMPRIME — mutant sans effet (cible absente ou inchangée)
- attendu : `[effet]`
- obtenu : `[sans effet]`

### FAIL — M-OUVRE-P — mutant sans effet (cible absente ou inchangée)
- attendu : `[effet]`
- obtenu : `[sans effet]`
