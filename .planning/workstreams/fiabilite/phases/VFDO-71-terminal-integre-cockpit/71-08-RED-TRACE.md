# 71-08 — trace des rouges sur mutants (TERM-09 navigateur, TERM-10 comportement, TERM-12 / T16)

Le code de Q existait avant ce plan : chaque protection est donc prouvée par un MUTANT (copie de la sortie ou du moteur, jamais le module) qui rend
sa sonde rouge, puis par le vert sur le code livré. Chaque mutant vérifie qu'il a un effet (copie comparée à l'original ; sinon FAIL « mutant sans effet »).
Format : assertion · attendu (code sain) · obtenu (mutant). Navigateur : Chrome headless (macOS) ; suites jouées par `bash <suite>`.

## Suite `test-cockpit-terminal-xterm.sh`

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-terminal-xterm.sh` (25 s, 18 PASS / 0 FAIL sur le code livré).

| Mutant | Assertion rougie | attendu (code sain) | obtenu (mutant) |
|--------|------------------|---------------------|-----------------|
| M-CTRLC (copie du moteur, l'assistant PTY retire 0x03) | T13.8 `sigint=… debut_apres=…` | `sigint=true debut_apres=false` | `sigint=undefined debut_apres=undefined` (erreur nommée : attente de « SIGINT-RECU » dépassée) |
| M-DCS (gestionnaire DECRQSS retiré du client) | T14.1 `dcs=` (octets `1b50` dans l'entrée du PTY) | `dcs=non` | `dcs=oui` |
| M-WINOPT (`windowOptions` ouvertes) | T14.1 `taille=` (octets `1b5b383b`, réponse à CSI 18t) | `taille=non` | `taille=oui` |
| M-CLIP (gestionnaire OSC 52 qui écrit dans `navigator.clipboard`) | T14.2 `clip=` (appels comptés par l'espion) | `clip=0` | `clip=2` (OSC 52 écriture et lecture) |
| M-LIEN (`linkHandler` retiré : comportement natif de xterm) | T14.4 `confirm=` après le clic sur LIEN | `confirm=0` | `confirm=1` |

Verts sur le code livré : T13.6 (grille : `TEMOIN-PLEIN-ECRAN-DEBUT` puis `PRET`), T13.7 (`WINCH <lignes>x<colonnes>` aux dimensions de la grille, différent de `TAILLE`
de départ), T13.8 (`SIGINT-RECU`, écran normal rétabli), T13.9 (récepteur : exactement `1b 09 12 17 1b5b41 7a`, aucun `00` : Ctrl+Maj+Espace n'envoie aucun octet),
T14.1 (entrée = réponse à DA1 seule, `1b5b3f…63`, ni `1b50` ni `1b5d`), T14.2 (0 appel presse-papiers), T14.3 (0 `window.open`, 0 `confirm` sans clic),
T14.4 (un `window.open('https://exemple.test/','_blank','noopener')`, 0 `confirm`).
Témoins positifs : T14.1a (la réponse à DA1 est reçue : sans elle l'absence du reste ne prouverait rien), T14.5 (un appel délibéré à `navigator.clipboard.writeText` est compté : 1),
T13.0 / T14.0 (aucune erreur nommée du scénario).

### Mesure de A2 (gestionnaire DCS prioritaire, 71-RESEARCH)

CONFIRMÉE. Avec `registerDcsHandler({ intermediates: '$', final: 'q' }, () => true)` dans le client livré, l'entrée du PTY ne reçoit que la réponse à DA1 ;
sans lui (M-DCS), xterm répond `ESC P 1 $ r … ESC \` (`1b50`) dans l'entrée du shell : le gestionnaire de remplacement est donc bien ce qui ferme la voie DECRQSS.

### Écart de 71-RESEARCH mesuré ici : CSI 21t

Le `xterm.js` livré (`assets/vendor/xterm/xterm.js`) ne répond PAS à CSI 21t, même avec `windowOptions.getWinTitle: true` (la table `windowOptions` ne répond qu'à
14t, 16t et 18t). Un mutant `getWinTitle: true` seul est donc « sans réponse » (premier essai : `osc_l=non` des deux côtés, FAIL « identique »). La sonde qui discrimine est
CSI 18t (réponse `ESC [ 8 ; <lignes> ; <colonnes> t`, `1b5b383b`) ; `hostile.py` émet 21t, 18t, 14t et 16t, M-WINOPT ouvre les quatre options.
Conséquence pour le code livré : `windowOptions: {}` reste nécessaire (une version ultérieure de xterm pourrait répondre à 21t) ; aucun défaut.

## Suite `test-cockpit-terminal-xss.sh` (T16)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-terminal-xss.sh` (17 PASS / 0 FAIL ; avec `CHAINE_SANS_NAVIGATEUR=1` : 8 PASS, 6 « non vérifiées » annoncées, non comptées).
La charge s'exécute réellement dans P (mutants M-ESC + M-CSP, lab piégé de `test-cockpit-chaine-xss.sh`, charge `eval(atob(…))` posée par `onerror`).

| Manche | Contrôles de Q laissés | Mesure | Assertion |
|--------|-----------------------|--------|-----------|
| C0t (témoin) | aucun (M-ORIGINE-TERM + M-SECRET-TERM + M-ONGLET-TERM) | marqueur créé par le shell : `oui` | T16.6 attendu `oui`, obtenu `oui` : la chaîne SAIT aboutir (fetch POST `no-cors` depuis P, Origin de P) |
| C1t (code livré) | les trois | marqueur `non`, assistants `1/1`, stockage du cadre `SecurityError`, `window.open` sans geste `bloque`, avec geste `ouvert` + stockage `SecurityError`, postMessage `envoye` sans effet (session `vivante`) | T16.1 à T16.5 verts |
| C2t | Origin seule | marqueur `non` | T16.7 vert |
| C3t | secret seul | marqueur `non` | T16.7 vert |
| C4t | onglet seul | marqueur `non` | T16.7 vert |

Réponses de Q aux requêtes de la charge (simulation HTTP sans navigateur, mêmes requêtes) : C1t 403 (Origin) ; C2t 403 (Origin) ; C3t 401 (secret) ; C4t 409 (onglet) ; C0t 204 (écrit au shell).
Dans Chrome, la variante avec en-têtes forgés (`X-VF-Terminal` = jeton de P) est arrêtée avant d'atteindre Q : `TypeError` (pré-vérification CORS refusée, OPTIONS → 403).
Limite : les trois mutants de Q se jouent ensemble (C0t) ou deux par deux (C2t-C4t) ; aucun mutant n'est isolé (leur retrait seul laisse deux autres contrôles) — c'est le sens de « chaque contrôle, laissé seul, la casse ».

## Défaut constaté

Aucun défaut du code livré. Le seul écart est la réponse de xterm à CSI 21t (ci-dessus), documenté, sans effet sur la protection.
