# 71-FIX-B2 — arrêt de la session complète (S1, P71-D-28) et résolution de `python3` (F3, P71-D-25)

Correction ciblée du lot B2. Validation de Samuel : P71-D-25 et P71-D-28 (AskUserQuestion, session principale Claude Code, 2026-11-04).
Fichiers : `terminal/vf-cockpit-pty.py`, `vf-cockpit-terminal-session.mjs`, suite `test-cockpit-terminal-pty.sh`. Commit de code : voir le journal git (`fix(71): arrêt de la session complète…`).

## S1 — aucun membre de la session ne survit (TERM-08, P71-D-28)

Cause : la phase SIGKILL visait `gs`, l'ensemble de groupes figé au départ. Un travail `commande &` a son propre groupe, absent de `gs` ; il ne mourait que si bash relayait SIGHUP à temps (T12.4 rouge 3 fois sur 6 à froid selon la revue). `nohup` et `disown` y échappaient toujours.

Correctif : l'assistant relève, au moment de l'arrêt, les membres de la session du terminal (`pty.fork()` fait du shell le chef de session : sid = son PID), leur envoie SIGHUP, attend la grâce (3 s ; 0,5 s si le shell est déjà sorti), puis SIGKILL, relevé répété jusqu'à ce qu'il n'en reste aucun. Le chemin « le shell est sorti de lui-même » est couvert aussi.

Énumération (mesurée) : `ps -o sess` ne sert à rien sous macOS (colonne à 0 pour tous les PID relevés). Retenu : liste des PID par `/proc` (Linux) sinon `/bin/ps -A -o pid=` en chemin absolu avec `PATH` neutre, puis `os.getsid(pid) == sid` pour chacun (getsid fonctionne sur un PID d'une autre session sous macOS : vérifié). Relevé impossible : repli sur les groupes (ancien comportement). Chaque envoi relit `getsid` juste avant (PID réutilisé : ignoré). Jamais de motif de nom, jamais de groupe figé en mode nominal.

Témoin rouge sur `c00d534a` (T12.5 ajoutée, code d'avant) : `attendu: [4 0 oui oui]  obtenu: [4 4 oui oui]` : les quatre processus nohup/disown survivent ; et `M-GROUPES-FIGES` « sans effet » (le mutant est l'ancien code).
Vert : `T12.5 PASS` (quatre processus nohup/disown morts, `setsid` vivant, leurre vivant). T12.4 reste verte.
Mutant : `M-GROUPES-FIGES` (`ms = None` dans `sigkill_session` : repli sur les groupes) rend T12.5 `4 4 oui oui` = rouge détecté, assertion verte.
Borne : le leurre (`sleep 303` lancé par la suite, hors session du terminal) survit ; le `setsid` (hors session) survit.

## F3 — le serveur n'exécute jamais un `python3` du lab

Choix motivé : résolution en chemin absolu par le serveur (plutôt que cwd neutre + `chdir` dans l'assistant) : le contrat d'appel de l'assistant (`<lignes> <colonnes> <shell>`) reste inchangé, donc les suites et pilotes qui l'appellent seuls aussi. `resoudrePython3()` ne retient que les éléments ABSOLUS du `PATH`, jamais un élément vide ou relatif ; introuvable : chemin impossible, l'événement `error` habituel (« python3 est introuvable… »), jamais de repli sur le cwd. Le `PATH` du shell est inchangé (P71-D-03), vérifié (`echo $PATH` dans le shell garde le préfixe).

Témoin rouge sur `c00d534a` : sonde `p10.mjs` : `PATH=.:…` et `PATH=:…` → « python3 du lab execute : OUI ». Après : « non » pour les trois PATH.
Suite : T15.1 (`.:`), T15.2 (`:`), T15.3 (`relatif/../.:`) : le leurre `<lab>/python3` n'est pas exécuté, le terminal démarre, le shell garde le PATH. Mutant `M-PYTHON3-CWD` (`spawn('python3')`) : `execute non non` = rouge détecté.
Leçon de test : un premier T15.1 avec le préfixe `.` sans `:` produisait `./usr/bin` (élément relatif quelconque) et restait vert ET le mutant sans effet : le mutant a révélé la vacuité, corrigée (`.:`).

## Limites (à écrire au README par B1)

- Un processus sorti de la session par `setsid` (ou double fork suivi de `setsid`) échappe à l'arrêt : assertion T12.5 qui le documente.
- Un élément ABSOLU du `PATH` situé dans le lab reste cherché (choix de l'utilisateur, hors F3).
- Arrêt avec survivants `nohup` : l'assistant attend la grâce de 3 s avant le SIGKILL (HUP ignoré), dans la marge de fermeture du serveur (6 s).
- Sans `/proc` ni `/bin/ps` lisibles, repli sur les groupes relevés au départ (ancien comportement, plus de garantie sur nohup).

## Suites

- `test-cockpit-terminal-pty.sh` : 49 PASS / 0 FAIL, **10 rejeux consécutifs sans rouge** (rc 0 ×10).
- `test-cockpit-terminal-session.sh` : 38 PASS / 0 FAIL ; `-activation.sh` rc 0 ; `test-cockpit-vendor.sh` rc 0 ; `synchro.sh verifier` rc 0 (`vf-cockpit-pty.py` est un AJOUT sans empreinte : aucune mise à jour).
- Gates : `check-machine-paths.sh` 0, `check-file-size.sh --all` 0, `check-python-isolation.sh` 0.
