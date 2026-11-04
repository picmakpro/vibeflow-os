# 71-FIX-W1 — Q dans son processus (E1), arrêt dit (G2 serveur), Python 3 absent (E4 serveur)

Arbitrages de Samuel, AskUserQuestion, session principale Claude Code, 2026-11-04 : P71-D-33 « Terminal dans son processus (Recommandé) », P71-D-34, P71-D-35.

## Ce qui change

- **Nouveau** `plugin/cockpit/scripts/vf-cockpit-terminal-processus.mjs` : le serveur Q (contrôles Host/Origin/jeton, P71-D-24, amorçage à usage unique 60 s, session unique, grâce 30 s, tampon 256 Kio, arrêt de toute la session) vit dans un processus enfant lancé par `child_process.fork`. Le code de Q est déplacé tel quel depuis `vf-cockpit-terminal.mjs`.
- `vf-cockpit-terminal.mjs` (dans le processus de `serve.mjs`) ne garde que les garde-fous de démarrage, le fork, `occupe()` (alimenté par l'enfant), `GET /api/vf/terminal` et l'écriture de `terminal.url` dans server.json. Interface exportée inchangée : le patch P25 de `serve.mjs` n'est PAS touché (diff, `VENDORED.txt` et `synchro.sh verifier` intacts).
- Canal parent/enfant = l'IPC de `fork` : `init` (moteur, lab, jetons, port de P, environnement d'origine du shell), `jetons`, `arret` ; en retour `pret`, `occupe`, `echec`. Aucun secret dans l'argv ni l'environnement de l'enfant (les jetons et l'environnement d'origine passent par l'IPC).
- Mort du parent (même SIGKILL) : l'IPC se ferme (`disconnect`), filet par changement de `ppid` toutes les 500 ms ; l'enfant arrête toute la session (assistant et shell) puis sort. Les fichiers d'amorçage ne sont PAS retirés dans ce cas (comme avant : un SIGKILL ne les retirait pas, et un serveur voisin peut avoir posé les siens au même chemin).
- **G2 serveur (P71-D-35)** : arrêt volontaire (SIGINT, SIGTERM, SIGHUP, ou sortie ordinaire de `serve.mjs`) -> message `arret` -> Q passe en état `arret`, ferme les flux, arrête la session, retire les fichiers d'amorçage, répond `GET /etat` -> `{"etat":"arret"}` pendant 2,5 s (`ARRET_MS`, plus de 1 s avec marge sous charge), puis sort. SIGKILL : comportement inchangé, aucun « arret » annoncé.
- **E4 serveur (P71-D-34)** : si `python3` est introuvable dans les éléments absolus du PATH d'origine, la ligne « python3 introuvable : le terminal est indisponible. » est journalisée UNE fois au démarrage de Q ; `GET /etat` -> `{"etat":"indisponible","raison":"python3-absent"}` ; `/flux` et les autres routes d'action -> 503 (plus de 500 muet) ; l'ENOTDIR synchrone de `spawn` est rattrapé (`lancer` rend null, l'attache rend 503).
- `vf-cockpit-terminal-session.mjs` : paramètre `env` (environnement d'origine du shell, P71-D-03) ; `arreterTout` ferme aussi le flux ouvert.

## Point pour le rebase sur la PR H-1 (message du manager)

L'environnement du processus enfant est choisi dans UNE seule fonction, `envDuProcessusTerminal(lab)` (`vf-cockpit-terminal.mjs`) : copie de `process.env` dont le PATH est assaini (éléments vides, relatifs ou sous le lab retirés, repli système). Au rebase, son corps devient `return envEnfant(lab, process.env)` (import de `vf-cockpit-env.mjs`, que cette branche ne crée pas). Le SHELL garde l'environnement d'origine (P71-D-03) : il lui arrive par l'IPC (`envOrigine`), filtré par `envShell` (CLAUDECODE, CLAUDE_CODE_*, VF_COCKPIT_*, jetons) ; `python3` est résolu par N8 sur le PATH d'origine. `fork` n'impose pas de `cwd` : l'enfant hérite du cwd de `serve.mjs` (le mutant M-CWD de la suite pty le suppose).

## Preuves

Rouge sur l'ancien code (HEAD avant correctif, sortie reconstruite avec `git show HEAD:` des deux modules) puis vert :

| sonde (suite `-session.sh`, section W1) | ancien code | nouveau code |
|---|---|---|
| E1.1 serveur gelé par SIGSTOP, trois frappes : trois échos < 1,5 s | FAIL (aucun écho) | PASS (3/3) |
| E1.3 SIGKILL du serveur : ni Q, ni assistant, ni shell ne survivent (E1.2 : témoin positif, tous vivants avant) | FAIL | PASS |
| G2.1 SIGTERM : `{"etat":"arret"}` vu, encore vu >= 1 s après le signal (poller démarré avant le signal) | FAIL | PASS |
| G2.2 puis Q, assistant sortis ; G2.3 flux fermé ; G2.4 SIGKILL : pas d'« arret », Q sort aussitôt | FAIL (G2.3 PASS) | PASS |
| E4.1 `/etat` indisponible, E4.2 journal une fois, E4.3 `/flux` 503 (E4.4 témoin : avec python3, `/etat` = état de session) | FAIL x3 | PASS |

Le gel est mesuré par SIGSTOP du processus du serveur (boucle bloquée de façon absolue, plus forte que 4 s de travail synchrone) : la discrimination ne dépend pas de la charge machine. Mutants ajoutés : M-PARENT-MORT (l'enfant ignore la mort du parent : survit au SIGKILL), M-SANS-ARRET (`{"etat":"arret"}` jamais vu), M-SANS-INDISPO. Chacun rougit sa sonde.

Bug trouvé et corrigé pendant la mise au point : `process.send` sur un canal fermé émet un `error` non rattrapé (l'enfant tombait environ 200 ms après l'arrêt volontaire, avant la fenêtre d'une seconde) ; garde `process.connected` + `process.on('error')`.

## Suites (toutes vertes en dernier rejeu, une à la fois)

`-serveur.sh` 208/0, `-session.sh` 54/0, `-activation.sh` 40/0, `-pty.sh` 63/0, `-xss.sh` rc 0, `-page.sh` rc 0, `-client.sh` 67/0, `test-cockpit-serveur.sh` 64/0, `test-cockpit-securite.sh` 88/0, `synchro.sh verifier` (retrouvé à l'octet, 48 fichiers), `check-machine-paths`, `check-file-size --all`, `check-python-isolation` : verts.

Réancrages de suites (aucune sonde affaiblie) : les mutants qui visaient `vf-cockpit-terminal.mjs` visent `vf-cockpit-terminal-processus.mjs` quand le code muté y a déménagé (origine, hôte, jeton, amorçage, journal, upgrade, Set-Cookie, X-Frame-Options, écoute) ; `pgrep -P` est enveloppé pour traverser le processus du terminal ; le compte d'écouteurs et d'assistants cherche aussi sous lui ; `-pty.sh` T14.1 tue aussi le processus du terminal (sans quoi l'enfant arrête l'assistant et le test ne mesurerait plus l'autonomie de l'assistant : M-ECRITURE-BLOQUANTE) ; M-PYTHON3-CWD suit la nouvelle signature de `resoudrePython3`.

## Phrases de doc à poser (README, CHANGELOG, passe finale)

- README : « Le serveur du terminal (Q) tourne dans un processus enfant dédié du serveur du cockpit : un travail synchrone du serveur (par exemple le calcul de qui travaille sur le lab) ne retarde plus ni les frappes ni la sortie du terminal. Si le serveur du cockpit meurt, même brutalement, l'enfant, l'assistant et le shell s'arrêtent avec lui. »
- README : « À l'arrêt volontaire du cockpit, le terminal affiche "Serveur arrêté" tout de suite : le serveur du terminal répond encore `arret` pendant environ 2,5 s avant de sortir. »
- README : « Sans python3 dans le PATH, le terminal est indisponible : un message "python3 introuvable" est écrit une fois dans serveur.log et la page l'annonce, au lieu d'un échec muet. »
- CHANGELOG : « Fix (P71-D-33, D-34, D-35) : le serveur du terminal tourne dans son propre processus ; arrêt volontaire et Python 3 absent sont annoncés par `GET /etat` (`{"etat":"arret"}`, `{"etat":"indisponible","raison":"python3-absent"}`). »

## Findings

- T12.5 (`-session.sh`, inactivité de 65 s) a rougi deux fois sous forte charge machine, puis vert sans changement de code (54/0) : flake de charge, non attribué au correctif.
- Le message d'arrêt volontaire part du `exit`/signal du parent par `child.send` : mesuré fiable (G2.1 vert), mais un arrêt par `process.exit` d'un autre chemin que ces signaux repose sur le `exit` handler.
