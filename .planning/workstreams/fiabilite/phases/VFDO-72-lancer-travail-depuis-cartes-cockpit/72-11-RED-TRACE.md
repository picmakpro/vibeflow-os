# 72-11 — trace : chaîne XSS prolongée jusqu'au lancement

Date : 2026-11-06. Commit A (suite et trois témoins, une seule fois pour les deux tâches) : `35d72e63`.
Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-lancer-xss.sh > <fichier> 2>&1`, sous Chrome (aucune ligne « NON vérifiée »).
Rejeu final : HEAD `a5805a81d72bc5bf2c2570db9fe454afcfb2497f`, sur un export `git archive` de ce SHA (arbre propre : les trois fichiers de 72-13 sont ceux de leur commit `78d79cfa`) : exit 0, `Résultats : 57 PASS / 0 FAIL (0 non vérifiées sans navigateur)`. Voisines au même SHA : `test-cockpit-terminal-xss.sh` 17 PASS, `test-cockpit-chaine-xss.sh` 22 PASS, `test-cockpit-lancer-serveur.sh` 73 PASS ; `test-cockpit-lancer-processus.sh` 42 PASS rejouée à `94bdb6e2` (avant le commit de 72-13, qui ne touche ni Q ni le processus).

## Le « rouge » de ce plan

Le plan ne modifie aucun code de production : son rouge n'est pas une suite qui échoue avant un code, c'est la chaîne qui ABOUTIT quand Q est privée de ses contrôles (C0l), puis chaque manche d'absence rougie quand on lui retire ce qui la garde.

### C0l — la chaîne aboutit (mutants : M-ESC M-CSP M-ORIGINE-TERM M-SECRET-TERM M-ONGLET-TERM M-ONGLET-LANCER M-ONGLET-SESSION M-ID-LIBRE)

- attendu : argv du faux claude PRÉSENT, ligne `claude --session-id` à l'invite, sans geste humain
- obtenu : `argv=oui ligne-à-l'invite=oui`, `propose=202`, `arme=armee`, `go=true`, `lancerNoCors1=envoye`, `lancerNoCors2=envoye`, `entree=envoye`, proposition ensuite `aucune` (consommée par la charge). La requête `lancerJeton` (en-têtes forgés, pré-vol) échoue en `TypeError` : seule la requête `no-cors` aboutit, comme dans la 71.

### C1l avec les contrôles retirés (démonstration que les sondes d'absence savent rougir ; script jetable, hors dépôt : C1l rejouée avec les mutants de C0l)

- C1l.1 — attendu `non/non`, obtenu `oui/oui` (argv et ligne présents)
- C1l.3 — attendu `en-attente phase=1 ws=fiabilite`, obtenu `aucune` (proposition consommée)
- C1l.5 — attendu `envoye/envoye/non/en-attente phase=1 ws=fiabilite`, obtenu `envoye/envoye/oui/aucune`
- C1l.6b — attendu `ouvert/SecurityError/SecurityError/1/1/non`, obtenu `ouvert/SecurityError/SecurityError/1/1/oui`
- Les sondes d'isolement (C1l.4a SecurityError en lecture et écriture, C1l.4b, C1l.5b) restent vertes : elles mesurent l'origine, pas les contrôles de Q.

### M-ESC et M-CSP — chacun, seul, rend le témoin T0 rouge (script jetable)

- M-ESC seul (CSP en place) : attendu `debut=true jeton=true terminal=actif propose=202 arme=armee go=true fin=true`, obtenu `attente de « la charge de P s'exécute (window.__xss.debut) » dépassée (25000 ms)`
- M-CSP seul (échappement en place) : même attendu, même obtenu

## Chaîne légitime (LEG), code livré

LEG.1 à LEG.7 verts : POST de P 202 ; proposition `phase=4 ws=fiabilite etat=en-attente` ; 204 après armement ; ligne `herite` à l'invite ; argv ABSENT après 2 s sans Entrée ; après `\r`, argv à cinq éléments (`--session-id`, UUID de la ligne, `-n`, `vf-phase-4-fiabilite`, `/vf-dev …`), ni `--permission-mode`, ni `bypassPermissions`, ni `touch` ; aucun fichier `MARQ-TITRE`. Le titre de la phase 4 est `x' --permission-mode 'bypassPermissions` : il n'entre pas dans la ligne.

- LEG.5 — attendu `non` (argv avant Entrée), obtenu `non`
- LEG.6 — attendu `oui n=5 forme=oui permission=non bypass=non touch=non`, obtenu `oui n=5 forme=oui permission=non bypass=non touch=non`

## Manches d'absence (code livré, un contrôle seul)

C1l (aucun contrôle retiré), C2l (Origin seule), C3l (secret seul), C4l (onglet seul), C5l (identifiant seul) : chacune a son témoin T0 (la charge s'exécute, proposition 202, armement passé), `argv=non ligne=non`. C1l : `contenu=null`, `stockageLecture=SecurityError`, `stockageEcriture=SecurityError`, `stockageP=lisible`, `clicCadre=envoye`, `postMessage=envoye`, `window.open` sans geste bloqué, avec geste `ouvert/SecurityError/SecurityError`, assistants 1/1, proposition ph-1 toujours en attente.

- C1l.1 — attendu `non/non`, obtenu `non/non` ; C2l, C3l, C4l, C5l — attendu `non/non`, obtenu `non/non` chacune
- C1l.4a — attendu `SecurityError/SecurityError/lisible`, obtenu `SecurityError/SecurityError/lisible`

## Mutants rejoués

| Mutant | Texte appliqué | Assertion rougie | attendu (code livré) | obtenu (mutant) |
|--------|----------------|------------------|----------------------|-----------------|
| M-ORIGINE-LANCER | `else if (o !== origineQ())` devient `… && !(url.pathname === '/lancer' && o === 'http://127.0.0.1:' + portP)` (processus de Q) | DORIG.1 | `403/ABSENT` | `204/TROUVE` (ligne à l'invite) |
| M-SANS-CONFIRM | `recevoirProposition` : Q appelle `lancer({ id: lireProposition().id, mode: "herite" }, proprietaire)` toutes les 200 ms | « une ligne à l'invite sans POST /lancer » | `ABSENT/en-attente phase=4 ws=fiabilite` | `TROUVE` (proposition `aucune`) |
| M-ENTREE-AUTO | `vers_shell += CTRL_C + ligne + bytes([13])` (copie du moteur, expression de 72-02) | LEG.5 | `204/non` (argv absent) | `204/oui` (argv présent sans Entrée) |
| M-INTERPOLE | trois remplacements, chacun contrôlé pour son effet : (P) `t: 'proposition', titre: …` dans `vf-cockpit-lancer.mjs` ; (Q1) `recevoirProposition` garde `m.titre` ; (Q2) `gabaritQ` insère le titre dans chaque ligne et ne revalide plus | LEG.6 | `n=5 forme=oui permission=non bypass=non touch=non` | `n=7 bypass=oui` |

## Titres hostiles (TIT)

Page P non compromise, `project.html#v=n:ph-3`, CSP en place : titre affiché en texte (témoin TIT.0 `true`), 0 violation, `window.__titre3` indéfini, témoin de mesure : une balise `<img onerror=void(0)>` insérée par la suite est comptée (`temoin=1`). CSP retirée (M-CSP) mais échappement en place : `window.__titre3` indéfini, titre affiché.

## Écarts avec le plan (suivi du code livré)

1. Armement : `arme_apres_ms` est une CONSTANTE de la réponse de `GET /proposition` (le délai court depuis la première lecture, `vue_a`), pas un compte à rebours. Le pilote lit la proposition (ce qui l'arme), puis attend `arme_apres_ms` lu plus 400 ms avant le signal `window.__go` (PL-11.5 adapté : aucune durée codée en dur, mais une attente bornée par la valeur lue). Le plan parlait de « sonde jusqu'à nul ».
2. Racine du lab : le moteur déduit la racine de l'emplacement de la sortie (`<lab>/.vibeflow/cockpit`) : chaque manche copie le lab ENTIER, et non la seule sortie (PL-11.2 : « sortie copiée »). Sans cela `GET /api/vf/lancer/cibles` rend une liste vide.
3. Mutant en plus : M-ONGLET-SESSION (`if (!actif(c) || c.onglet !== onglet) return non('absente');` de `sessions.lancer`, 72-02) : sans lui l'onglet reste gardé après M-ONGLET-LANCER et M-ONGLET-TERM. Posé partout où l'onglet est retiré (C0l, C2l, C3l, C5l), comme le plan l'autorise pour C0l.
4. LEG.2 : la réponse de `GET /proposition` ne porte pas `cible` ; l'assertion lit `phase=4 ws=fiabilite etat=en-attente`.
5. `POST /lancer` peut rendre 504 (délai de l'assistant), hors contrat §4 : non rencontré, aucune assertion n'en dépend.
6. Une seule commit de code pour les deux tâches (la suite a été écrite d'un jet) : les vérifications `OK-COMMIT-A` et `OK-PERIMETRE` portent sur ce commit et sur les commits « (72-11) » ; la tâche 2 n'a pas de commit A distinct.
7. Charge : la balise est assemblée en une ligne (les retours à la ligne sont supprimés) : un commentaire de fin de ligne avalait la suite de la charge (premier jet : `window.__xss` indéfini). Les commentaires sont donc des lignes entières, retirées par `payload.mjs`.

## Défaut constaté

Aucun défaut de code applicatif (Q, processus, serveur P, client) : toutes les sondes d'absence tiennent, tous les mutants rougissent pour la bonne raison.
Hors périmètre, constaté et non traité : `scripts/check-machine-paths.sh` a rendu rouge à un moment pour `72-12-RED-TRACE.md` (segment de compte) ; corrigé depuis par `0c164b5f` (docs 72-12).
