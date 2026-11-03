# 71-06 — trace du rouge du client de Q

- date : 2026-11-03
- empreinte du commit de tests : `f7e1f7d0` (`test(71-06): témoins rouges du client de Q …`)
- base : HEAD `6389c3d2` ; `vf-cockpit-terminal-client.mjs` et `-vue.mjs` = amorces vides de 71-05 ; Chrome 156 headless (macOS)
- commande : `bash plugin/cockpit/scripts/tests/test-cockpit-terminal-client.sh > 71-06-t1.out 2>&1` — rc=1, `Résultats : 8 PASS / 27 FAIL`, environ 4 min
- verts sur la base (témoins) : ST.0, T6.0, T9.0, T6.5 et M-SETCOOKIE (aucun set-cookie), T9.6 et M-ANCETRES (frame-ancestors déjà posé par 71-05)
- écart au plan : T14.S3 et T17.Q1 (absences) portent un garde de vivacité (`propres > 200` : les scripts propres ne sont plus vides) ; elles sont donc rouges sur la base au lieu de vertes, ce qui évite un vert à vide. Leurs mutants M-CLIP et M-ECOUTE sont « sans effet » sur la base (cible absente).

## Témoins rouges (attendu, obtenu)

### FAIL — T14.S1 — gestionnaire DCS de remplacement (registerDcsHandler sur $ et q) dans le client servi
- attendu : `[true]`
- obtenu : `[false]`

### FAIL — T14.S2 — windowOptions vide et macOptionIsMeta faux
- attendu : `[true/true]`
- obtenu : `[false/false]`

### FAIL — T14.S3 — aucun addon presse-papiers, navigator.clipboard ni execCommand dans les scripts propres (la page est vivante : propres > 200)
- attendu : `[0/true]`
- obtenu : `[0/false]`

### FAIL — T14.S4 — linkHandler avec activate qui ouvre en noopener ; aucun confirm(
- attendu : `[true/0]`
- obtenu : `[false/0]`

### FAIL — T17.Q1 — aucun écouteur de messages entrants dans Q (la page est vivante : propres > 200)
- attendu : `[0/true]`
- obtenu : `[0/false]`

### FAIL — T17.Q2 — au moins un postMessage( et aucun avec l'étoile
- attendu : `[true/0]`
- obtenu : `[false/0]`

### FAIL — T17.Q3 — les littéraux etat:* des scripts propres sont exactement les six valeurs de la liste
- attendu : `[arrete,connecte,expire,reconnexion,refuse,termine,]`
- obtenu : `[,]`

### FAIL — M-ETOILE — mutant sans effet (cible absente ou inchangée)
- attendu : `[effet]`
- obtenu : `[sans effet]`

### FAIL — M-ECOUTE — mutant sans effet (cible absente ou inchangée)
- attendu : `[effet]`
- obtenu : `[sans effet]`

### FAIL — M-CLIP — mutant sans effet (cible absente ou inchangée)
- attendu : `[effet]`
- obtenu : `[sans effet]`

### FAIL — T6.1 — Q/#t=… mène à P/project.html sans fragment ni paramètre ; aucune entrée d'historique ne porte #t=
- attendu : `[adresse=http://127.0.0.1:49153/project.html historique_avec_fragment=0]`
- obtenu : `[adresse=http://127.0.0.1:49156/#t=<amorce> historique_avec_fragment=1]`

### FAIL — T6.1b — échange refusé : Q reste, adresse sans fragment, carte « Session expirée »
- attendu : `[hash=[] port=49156 carte=oui]`
- obtenu : `[hash=[#t=<amorce>] port=49156 carte=non]`

### FAIL — T6.3 — le secret (64 hexadécimaux) est rangé dans le stockage de Q (Q en premier niveau), terminal vivant
- attendu : `[secret=oui invite=true]`
- obtenu : `[secret=non invite=false]`

### FAIL — T6.2 — document.cookie vide sur P et sur Q (témoin : le secret existe bien, sinon le vide ne prouve rien)
- attendu : `[P=[] Q=[] secret_connu=oui]`
- obtenu : `[P=[] Q=[] secret_connu=non]`

### FAIL — T6.4 — depuis P, le stockage du cadre de Q lève SecurityError (témoins : le secret est dans Q, le stockage de P est lisible)
- attendu : `[SecurityError/secret_dans_q=oui/stockage_p=lisible]`
- obtenu : `[SecurityError/secret_dans_q=non/stockage_p=lisible]`

### FAIL — T6.6 — le fichier d'amorçage est supprimé après l'échange
- attendu : `[supprime]`
- obtenu : `[present]`

### FAIL — T6.7 — ni l'amorçage ni le secret dans l'adresse, le DOM, le stockage ou les cookies de P (témoin : secret connu)
- attendu : `[adresse=0 dom=0 stockage=0 cookie=0/secret_connu=oui]`
- obtenu : `[adresse=0 dom=0 stockage=0 cookie=0/secret_connu=non]`

### FAIL — T9.5 — cadre sandbox="allow-scripts allow-same-origin" dans P : ready puis etat:connecte, tous d'origine Q
- attendu : `[ordre=ok origines=http://127.0.0.1:49562]`
- obtenu : `[ordre=ko origines=]`

### FAIL — T9.7 — 0 violation de CSP : P avec le cadre chargé et attaché, Q en premier niveau (témoins : connecté sous sandbox, invite du shell)
- attendu : `[connecte=oui P=0 Q=oui/0]`
- obtenu : `[connecte=non P=0 Q=non/0]`

### FAIL — TQ.1 — la saisie atteint le shell et sa sortie revient (POST /entree puis flux, Q en premier niveau)
- attendu : `[true]`
- obtenu : `[false]`

### FAIL — T17.Q4 — Ctrl+Maj+Espace dans le cadre : message toggle reçu par P, d'origine Q
- attendu : `[toggle=oui]`
- obtenu : `[toggle=non]`

### FAIL — T17.Q5 — tout message reçu par P est dans la liste fermée (au moins ready, etat:connecte et toggle ont été vus)
- attendu : `[hors_liste=0 vus=true]`
- obtenu : `[hors_liste=0 vus=false]`

### FAIL — O4.1 — même onglet = reprise : le second cadre se reconnecte (etat:connecte, pas etat:refuse)
- attendu : `[connecte=oui refuse=non]`
- obtenu : `[connecte=non refuse=non]`

### FAIL — O4.2 — autre onglet (sessionStorage vide) : carte « Terminal déjà ouvert »
- attendu : `[oui]`
- obtenu : `[non]`

### FAIL — M-COOKIE — mutant sans effet (cible absente ou inchangée)
- attendu : `[effet]`
- obtenu : `[sans effet]`

### FAIL — M-FRAGMENT — mutant sans effet (cible absente ou inchangée)
- attendu : `[effet]`
- obtenu : `[sans effet]`

### FAIL — M-STOCKAGE — mutant sans effet (cible absente ou inchangée)
- attendu : `[effet]`
- obtenu : `[sans effet]`

## MESURE-O8 (sur la base : le cadre de Q est servi mais le client est vide)

MESURE-O8 minimal=bloque popups=ouvert opener=nul

## Après la tâche 2
