# 72-CORRECTIFS-A — correction ciblée serveur et PTY (lot 1, revue et audit au SHA 84501819)

Mandat du manager (2026-11-06) : F3 (audit), ST-1, ST-3, ST-4 (revue). Chaque point : témoin d'abord, code ensuite, vert enfin ; un témoin qui ne peut pas rougir ne compte pas, donc son mutant est nommé.

## Point 1 — F3 : garde du propriétaire de POST /annuler, code terminal-indisponible

### 1a. Garde du propriétaire (`vf-cockpit-terminal-processus.mjs`, `if (onglet !== proprietaire) return refus(res, 409)`)
- Défaut : aucun témoin ; un mutant qui retire la garde laissait la suite processus à 42 PASS.
- Témoin ajouté : Q10b (`test-cockpit-lancer-processus.sh`) — l'onglet B, muni du secret, annule la proposition de l'onglet propriétaire A. Attendu : `409 en-attente true` (409, la proposition reste en attente, même id).
- Rouge avant (le code porte déjà la garde, donc le rouge est celui du mutant) : mutant M-ANNULER-PROPRIETAIRE (`s#if (onglet !== proprietaire) return refus(res, 409);##`). Attendu sain : `409`. Obtenu sous le mutant : `204`. La suite affirme ce 204 (« l'onglet B annule la proposition de l'onglet A »), donc Q10b rougit bien sous le mutant.
- Vert après : suite processus 44 PASS / 0 FAIL (42 + Q10b + le mutant), rc 0.
- Aucun code modifié : l'ajout est un témoin seul.

### 1b. Code `terminal-indisponible` de `proposer` (`vf-cockpit-lancer.mjs`)
- Défaut : le code n'était témoigné par rien (le test E1 acceptait « 409 ou 503 »).
- Choix : TÉMOIGNER, ne pas supprimer. Le contrat (72-CONTRATS.md ligne 68, en-tête de `vf-cockpit-lancer.mjs`) distingue trois états du terminal (`actif`, `arrete`, `indisponible`) et liste `terminal-arrete` ET `terminal-indisponible` comme deux codes fermés ; la garde n'est pas redondante : sans elle, un canal indisponible sortirait en `409 bloque` (le bloquant `terminal-absent` posé par le calcul des cibles), un code d'une autre famille, au lieu de 503.
- Témoin : E2b (`test-cockpit-lancer-serveur.sh`, mode `e4` du harnais) — canal `indisponible` : `503 terminal-indisponible` ; canal `arrete` : `503 terminal-arrete` ; canal `actif` : `202` (témoin positif).
- Mutants (copies de la sortie) :
  - M-CODE-INDISPONIBLE (le ternaire devient `'terminal-arrete'`) : obtenu `indisponible:503:terminal-arrete ...` au lieu de `indisponible:503:terminal-indisponible ...` → E2b rouge.
  - M-GARDE-ACTIF (la ligne de garde est retirée) : obtenu `indisponible:409:bloque arrete:409:bloque actif:202:` → E2b rouge.
- Vert après : suite serveur 79 PASS / 0 FAIL.
- Aucun code modifié.

## Point 2 — ST-1 : une seule source de règle (`cibles`, `suivi`, `lancer`)

### 2a. `RECENCE_MS` défini deux fois
- Choix : supprimer le code mort plutôt que faire importer. `suivi.recent()` et `suivi.RECENCE_MS` ne servaient à aucun code de production (la récence consommée est celle de `calculerCibles`, qui lit `suivi.lancements()`). Importer `RECENCE_MS` de `cibles` dans `suivi` aurait aussi rompu la pureté du module suivi (« aucun import », LS4.3). Retrait : `RECENCE_MS` et `recent()` ne sont plus dans `vf-cockpit-lancer-suivi.mjs` ; la seule définition est `vf-cockpit-lancer-cibles.mjs:14`.
- Témoin : LS2.1 réécrit (`test-cockpit-lancer-suivi.sh`) — le module suivi n'exporte ni `RECENCE_MS` ni `recent` (clés exactes de `creerSuivi` : `noter,lancements,etats,lancees,taille`) ET parmi `vf-cockpit-lancer*.mjs`, seul `vf-cockpit-lancer-cibles.mjs` définit `export const RECENCE_MS`.
- Rouge avant : l'état d'avant le correctif est reproduit par le mutant M-RECENCE-RETABLIE (`export const RECENCE_MS = 900000;` remis dans suivi) : LS2.1 rougit (relevé `number|undefined|…` au lieu de `undefined|undefined|…`).
- Tests retirés avec le code mort (et eux seuls) : l'ancien LS2.1 (fenêtre de `suivi.recent()`) et son mutant M-RECENCE-INFINIE. La fenêtre de récence reste témoignée là où elle sert : A3 et M-RECENCE-INFINIE de `test-cockpit-lancer-cibles.sh`, non modifiés. Les autres sondes qui lisaient `recent()` (LS2.2, LS3.5, LS4.4) gardent leur objet : LS2.2 vérifie l'heure de P sur `lancements()`, LS3.5 l'oubli à `ATTENTE_MAX_MS` sur `lancements().length` (même valeur 0), LS4.4 les constantes restantes.
- Vert après : suite suivi 37 PASS / 0 FAIL.

### 2b. `verdict()` exporté jamais utilisé, règles refaites dans `proposer()`
- Choix : `proposer()` s'appuie sur `verdict()`. Après la recherche de la cible (404 `cible-inconnue`), `verdict(liste, cible.id, verbe)` rend `null` (422 `verbe-refuse`) ou `{ lancable, bloquants }` (409 `bloque` + codes). Les deux règles « verbe permis » et « aucun bloquant » n'existent plus qu'une fois.
- Témoin : E2c (`test-cockpit-lancer-serveur.sh`, mode `e5`) — `404:cible-inconnue:`, `422:verbe-refuse:`, `409:bloque:claude-introuvable`, `202::` (témoin).
- Mutants : M-VERDICT-BLOQUE (verdict toujours lançable) : le 409 devient 202 → E2c rouge ; M-VERDICT-VERBE (verdict ne juge plus le verbe) : le 422 devient 202 → E2c rouge. Avant le correctif, ces deux mutants n'auraient pas pu rougir E2c, par construction (proposer ne lisait pas `verdict`, ses règles étaient écrites à la main) : non rejoué sur l'ancien code, seulement déduit.
- M-LISTE-PAGE (existant) : la forge de la cible dans `proposer` était désormais rattrapée par `verdict` (la cible forgée n'est pas dans la liste, 422 au lieu de +1 proposition). Le mutant retire désormais les DEUX gardes d'appartenance (la recherche et l'appel de `verdict`) : même propriété, même obtenu `+1`, attendu sain `+0`. Pas d'assertion affaiblie : l'assertion et son attendu sont inchangés, seul le mutant a été complété pour retirer la garde qui a doublé.
- Vert après : suite serveur 79 PASS / 0 FAIL ; suite cibles inchangée.

## Point 3 — ST-3 : l'environnement ne peut que rallonger l'armement (`vf-cockpit-lancer-q.mjs`)
- Décision du manager (2026-11-06) : `VF_COCKPIT_LANCER_ARME_MS` plafonne par le bas à la valeur de production (1000 ms) ; `VF_COCKPIT_LANCER_EXPIRE_MS` inchangé.
- Rouge avant : LQ6.4 (nouveau, `test-cockpit-lancer-q.sh`). Attendu `1000,120000;1000,120000;1000,120000;1000,120000;1001,120000;` pour les valeurs 100, 250, 999, 1000, 1001. Obtenu avant le code : `100,120000;250,120000;999,120000;1000,120000;1001,120000;`.
- Code : `const arme0 = Math.max(ARME_DEF, depuisEnv(...)); // garde:plancher`.
- Mutant : M-ARME-ABAISSABLE (`Math.max(ARME_DEF,` devient `Math.max(0,`) : LQ6.4 rouge, témoin `5000` retenu (le mutant rallonge toujours).
- Sondes modifiées par la décision (et seulement elles) : LQ6.2 (`ARME_MS=250 -> 250` devient `ARME_MS=5000 -> 5000` : l'environnement rallonge) ; le témoin de M-ENV-SANS-BORNE passe de `250` à `5000` pour la même raison. Aucune autre suite ne pose une valeur inférieure à 1000 (processus et chat posent 2000).
- Piège rencontré : le marqueur a d'abord été nommé `garde:arme-plancher`, que le mutant existant `/garde:arme/d` de M-SANS-CONFIRM-STATE supprimait aussi (module cassé, témoin faux). Renommé `garde:plancher`.
- Vert après : suite q 71 PASS / 0 FAIL.

## Point 4 — ST-4 : `LANCE ok` seulement pour une ligne réellement poussée (`vf-cockpit-pty.py`)
- Défaut : `lancer_ligne` avalait `OSError` sur l'écriture et répondait `ok`.
- Rouge avant : L10.1 (`test-cockpit-lancer-pty.sh`, assistant importé, `premier_plan_libre` forcé à vrai, `pousser` qui lève `BrokenPipeError` puis `OSError(EIO)`). Attendu : `casse:ecriture:0 eio:ecriture:0 temoin:ok:0 | LANCE ecriture`. Obtenu : `casse:ok:66 eio:ok:66 temoin:ok:0 | LANCE ok` (la ligne reste de plus en file, 66 octets).
- Code : sur `OSError`, la file est vidée (`del vers_shell[:]`) et la fonction rend le NOUVEAU MOTIF `ecriture`.
- NOUVEAU MOTIF À INSCRIRE AU CONTRAT : `ecriture` (réponse de l'assistant `LANCE ecriture`, motif de refus de `sessions.lancer`).
  - `vf-cockpit-terminal-session.mjs` : regex `^LANCE (ok|premier-plan|alphabet|invalide|ecriture)$`.
  - `vf-cockpit-terminal-processus.mjs` : `STATUT_LANCER` gagne `ecriture: 410` (la session n'est plus utilisable ; l'état de Q est restitué par `lq.rendre`, comme pour tout refus d'écriture). Choix de 410 plutôt que 502 : c'est le statut de « pas de session », que la page traite déjà ; à amender si le manager préfère un autre.
- Témoin côté session : J8.1 — un assistant factice qui répond `LANCE ecriture` rend `{ok:false,motif:ecriture}` ; qui répond `LANCE ok` rend `{ok:true}` (témoin).
- Mutants : M-ECRITURE-AVALEE (`return 'ecriture'` devient `pass`) : L10.1 rouge ; M-REGEX-ECRITURE (la regex ne connaît plus `ecriture`) : J8.1 rouge, l'attente expire en `delai`.
- Vert après : voir le rapport (preuves).
