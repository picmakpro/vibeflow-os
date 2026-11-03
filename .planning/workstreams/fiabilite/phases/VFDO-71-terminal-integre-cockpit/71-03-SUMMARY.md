---
phase: 71
plan: 03
status: passed
requirements: [TERM-06, TERM-07, TERM-08, TERM-09]
commits:
  tests: 9ee45e09
  trace: [e1889155, 6592d233]
  code: 15a01a32
---

# 71-03 — assistant PTY complet et environnement du shell : résumé

L'assistant tient le contrôle de taille (descripteur 3), l'état de sortie (descripteur 2) et l'arrêt en deux temps sur le groupe du shell ET le
groupe de premier plan du terminal ; `envShell` filtre par liste noire (nom et valeur) et pose toujours `TERM` et `COLORTERM`. Un programme plein
écran témoin tourne normalement dans le flux direct (écran alterné, 256 couleurs, truecolor, SIGWINCH, SIGINT, retour de l'invite).

Trace du rouge : `71-03-RED-TRACE.md`. Vert : `Résultats : 32 PASS / 0 FAIL` (`test-cockpit-terminal-pty.sh`, aussi sous `/usr/bin/python3` 3.9.6),
`test-cockpit-terminal-activation.sh` : 40 PASS / 0 FAIL.

## Ordre des commits

| Commit | Empreinte | Contenu |
|--------|-----------|---------|
| `test(71-03)` | `9ee45e09` | `test-cockpit-terminal-pty.sh` (T10 à T13, neuf mutants) et `temoins/plein-ecran.py` |
| `docs(71-03)` x2 | `e1889155`, `6592d233` | `71-03-RED-TRACE.md`, puis un bloc attendu/obtenu par rouge |
| `feat(71-03)` | `15a01a32` | `vf-cockpit-pty.py` complet, `vf-cockpit-terminal-env.mjs` complet |

## Décisions citées

- **P71-D-23 (arbitrage de Samuel, AskUserQuestion, session principale Claude Code, 2026-11-03)** : `TERM=xterm-256color` et `COLORTERM=truecolor` toujours
  posés, écrasant l'hérité. Elle rend **définitive** P71-D-22 (décision du manager, qui n'était plus « provisoire »). Constante unique `AJOUTS_TOUJOURS`,
  réversible ; T10.8 et le mutant M-SI-ABSENT la gardent.
- P71-D-03, D-04, D-06 : arbitrages de Samuel (D-01..08, AskUserQuestion, session principale Claude Code, 2026-11-03) ; P71-D-14 : décision du manager.

## Mesure A5 : le relais de SIGHUP par le shell

Sur ce poste (macOS), un travail d'arrière-plan lancé depuis `bash` 3.2, `zsh` et `sh` disparaît quand l'assistant voit l'EOF de son entrée
(sonde isolée : `sleep` en arrière-plan, EOF, 0,6 s). Le relais est fait par le shell, mais seulement s'il reçoit SIGHUP : un `bash -i` se met
dans **son propre groupe**, donc le SIGHUP au seul groupe du shell lancé (comportement de la tranche 71-01) ne l'atteignait pas. T12.4 l'a montré
rouge sur la base (`5 survivants`) et vert avec le groupe de premier plan (`os.tcgetpgrp(maitre)`, qui fonctionne sur le maître sous macOS). La
CI Linux le rejouera. Limite inchangée, à écrire au README (71-09) : un `nohup`, `setsid`, `disown` ou un shell qui ne relaie pas SIGHUP (`dash`) peut survivre.

## Écarts et constats

- **T11.2 et T13.3 verts sur la base**, contrairement à ce que le plan annonçait : l'assistant de 71-01 applique déjà les lignes `R`. Ce ne sont pas des
  sondes aveugles (M-RESIZE les fait rougir, `ABSENT ABSENT`). La commande `<automated>` de la tâche 1, qui exige `❌ FAIL — T13.3`, ne peut donc pas
  répondre `OK-ROUGE-ATTENDU` ; la preuve de sensibilité est le mutant. À corriger dans la prose du plan si elle est rejouée.
- **T12.4 rouge sur la base** (le plan le voulait vert) : défaut réel de la tranche, corrigé ici (voir A5).
- **M-SI-ABSENT** « sans effet » sur la base : l'ancre (`Object.assign(sortie, AJOUTS_TOUJOURS)`) n'existe que dans le code final.
- Neuvième mutant ajouté, hors plan : **M-SANS-L** (shell lancé sans `-l`), pour que T10.4 ne soit pas un vert sans épreuve.
- Le shell de test lance `bash --rcfile <fichier sous $WORK> -i` : la marque de la suite figure dans sa ligne de commande, `hygiene.sh` le voit. Seul
  le `sleep` d'arrière-plan reste sans marque ; son PID est relevé et arrêté nommément si un mutant le laisse vivre.
- Le descripteur 3 n'est rendu non héritable qu'avant le `fork` ; sans canal de contrôle, le descripteur 3 peut être le maître lui-même (garde ajoutée).
- `T10.3` ne peut pas discriminer le lien symbolique lui-même : `serve.mjs` calcule `root` depuis un chemin que Node a déjà résolu. La sonde discrimine
  le `cwd` (serveur lancé hors du lab) ; M-CWD la fait rougir.

## Mesures

- `vf-cockpit-pty.py` : 201 lignes ; `vf-cockpit-terminal-env.mjs` : 38 lignes ; suite : 252 lignes ; `plein-ecran.py` : 39 lignes. Aucun fichier du dépôt hors liste.
- Gates : `check-file-size.sh` (fichiers du plan et `--all`), `check-python-isolation.sh --min-sites 40`, `check-machine-paths.sh` : verts.
- `python3 -I -m py_compile` sous Python 3.9.6 : vert. Aucun `match`, aucune dépendance hors bibliothèque standard.
