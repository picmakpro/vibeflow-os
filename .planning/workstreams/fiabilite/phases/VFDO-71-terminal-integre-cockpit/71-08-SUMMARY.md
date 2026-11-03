---
phase: 71
plan: 08
status: passed
requirements: [TERM-09, TERM-10, TERM-12]
commits: [a1b924f8, bde4fc2b, 5ecde006]
---

# 71-08 — bout en bout dans Chrome : plein écran, séquences hostiles, chaîne XSS vers le terminal

Trace des rouges sur mutants : `71-08-RED-TRACE.md`.

## Livré

- `plugin/cockpit/scripts/tests/temoins/hostile.py` : programme hostile (OSC 52 écriture et lecture, OSC 8, DCS, XTGETTCAP, CSI 21t/18t/14t/16t, DECRQSS, DA1) et récepteur d'entrée brute (`--recepteur`), relevé en hexadécimal.
- `test-cockpit-terminal-xterm.sh` (18 assertions) : T13.6-T13.9 (programme plein écran de 71-03 dans la page Q réelle ; redimensionnement, Ctrl-C, touches), T14.1-T14.5 (séquences hostiles, espions presse-papiers, `window.open`, `confirm`, clic sur le lien OSC 8). Mutants M-CTRLC, M-DCS, M-WINOPT, M-CLIP, M-LIEN : chacun rougit sa sonde.
- `test-cockpit-terminal-xss.sh` (17 assertions) : manches C0t à C4t sur le lab piégé, P compromise (M-ESC + M-CSP), session légitime tenue par un client Node, succès de la chaîne = fichier créé par le shell. Mutants de Q : M-ORIGINE-TERM, M-SECRET-TERM, M-ONGLET-TERM.
- `test-cockpit-chaine-xss.sh` : une ligne de commentaire d'en-tête (numstat `1 0`), assertions inchangées (22 PASS).

## Preuves

- TERM-12 : C0t (Q privée de ses trois contrôles) crée le marqueur par le shell, ce qui prouve que la sonde SAIT détecter un shell atteint ; sur le code livré, aucun marqueur, 1 assistant avant et après, stockage du cadre de Q en `SecurityError`, `window.open` sans geste bloqué et avec geste ouvert + stockage `SecurityError`, `postMessage` sans effet ; chaque contrôle laissé seul (Origin, secret, onglet) casse la chaîne.
- TERM-09 : `TEMOIN-PLEIN-ECRAN-DEBUT` et `PRET` dans la grille xterm ; `WINCH` aux dimensions de la grille après redimensionnement ; Ctrl-C donne `SIGINT-RECU` et l'écran normal ; Échap, Tab, Ctrl+R, Ctrl+W, flèche haut atteignent le shell (récepteur : exactement `1b 09 12 17 1b5b41 7a`), Ctrl+Maj+Espace n'envoie aucun octet.
- TERM-10 : l'entrée réinjectée dans le PTY est la réponse à DA1 seule ; presse-papiers 0 appel (espion éprouvé par un appel délibéré) ; lien OSC 8 ouvert une fois en `noopener`, 0 `confirm`.
- Mesure de A2 : CONFIRMÉE (sans le gestionnaire DCS du client, xterm répond `ESC P` dans l'entrée du shell).

## Écarts et limites

- CSI 21t : le `xterm.js` livré n'y répond pas, même avec `getWinTitle: true`. M-WINOPT mute donc les quatre `windowOptions` et la sonde qui discrimine est CSI 18t (`1b5b383b`). Aucun défaut du code livré.
- Le plan disait deux choses de C2t-C4t (« retirée seule » dans `<behavior>`, « un seul contrôle gardé » dans `<action>` et la carte). Suivi : un seul contrôle gardé, conforme à la demande « chacun des trois contrôles, laissé seul, la casse » ; le plan est à rectifier.
- Presse-papiers : mesuré par ses APPELS (espions posés avant la page), pas par son contenu (Chrome headless : pas de pointeur fin, presse-papiers du poste non observable). `Origin` jamais posée à la main dans un témoin de navigateur (P71-D-24) : la charge utilise `fetch` du navigateur.
- Sans Chrome, `test-cockpit-terminal-xterm.sh` sort 1 (« SUITE SAUTÉE ») ; `test-cockpit-terminal-xss.sh` joue une simulation HTTP et annonce 6 mesures non vérifiées, non comptées.

## Suites rejouées en fin de plan

xterm 18/0, xss 17/0, chaine-xss 22/0, terminal-client 35/0 ; `check-machine-paths.sh`, `check-file-size.sh --all`, `check-python-isolation.sh` : rc 0.
Aucune correction de code livré, aucun fichier hors liste.
