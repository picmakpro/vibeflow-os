# Handoff — mission pty-orphelin (2026-11-05)

Arrêt du manager au seuil de 600 000 tokens, comme le brief le demande (somme des sous-agents : environ 611 000).
Le mandat est hors phase, dans le jalon vibeflow-v2.0, compartiment fiabilite. Arbitrage de Samuel : AskUserQuestion en session principale, 2026-11-05.

## État
- Worktree : `~/Documents/dev/vibeflow-os/.claude/worktrees/fix-pty-orphelin`, branche `fix/cockpit-pty-orphelin`, base origin/main `d4171ded`. Rien n'est poussé, aucune PR n'est ouverte.
- Commits :
  - `0f556240` : sonde rouge, suite neuve `plugin/cockpit/scripts/tests/test-cockpit-terminal-pty-plantage.sh`, scénarios T12.8a/b/c/c'.
  - `5d2fda16` : correctif, un gardien dans `vf-cockpit-pty.py`.
  - `85e27f1f` : cockpit v1.3.1, CHANGELOG, compteur de suites 165 → 166.
- Verrou utilisé : `--ws=fiabilite --phase=71`. Le nom `pty-orphelin` est refusé (`phase-invalid`), car `--phase` attend un numéro. Le défaut appartient à la Phase 71. Le verrou est relâché à la sortie.

## Cause (mesurée sous macOS, sourcée pour Linux)
- Quand l'assistant plante (SIGKILL, ou exception autre qu'OSError), `arreter()` ne s'exécute pas.
- Seul reste le SIGHUP noyau envoyé au chef de session à la fermeture du maître : `ttymodem` sous XNU, `tty_vhangup` sous Linux.
- Le shell et `sleep &` meurent. Survivent `nohup … & disown` et `(trap '' HUP; exec …) &`.
- Sous Linux, les mêmes survivants restent, d'après la recherche doc. Le message de `a460dcb1`, qui disait que tout mourait sous Linux, est à nuancer.

## Correctif
- Un gardien est forké AVANT `pty.fork()`. Il passe par `setsid`, met 0/1/2 sur /dev/null et ferme tout le reste.
- Il reçoit `SID <pid>` puis `OK` par un tube. Si le tube se ferme sans `OK`, il fait SIGHUP, la grâce, puis SIGKILL, avec un `getsid` relu avant chaque envoi et sans repli `killpg`.
- Aucun `try/finally` : aucun mutant ne le discrimine.
- Témoin : T12.8a/b rouges à `0f556240` (2 survivants), verts à `5d2fda16`.
- Mutants M-GARDIEN-ABSENT et M-GARDIEN-SANS-SID : rouges pour la bonne raison.

## Vérifications faites
- Rejeu local du job `gates` (`replay-ci-jobs.sh --job gates`) à `85e27f1f` : 21 étapes rejouées, 4 sautées, 0 en échec.
- Suites, mesurées par le codeur : pty 63/0, session 57/0, serveur 208/0, plantage 7/0. La revue a rejoué session (57/0, rc=0) et plantage (7/0).
- Revue `vf-reviewer` : passed, 4 mineurs auto-fix, 1 no-op.
- Audit `vf-auditer` : gaps_found, aucun majeur, 1 mineur auto-fix, 3 no-op.

## Reste à faire, dans l'ordre
1. Correction ciblée (vf-coder), sans affaiblir aucune assertion. Ces correctifs fusionnent et dédupliquent les findings des deux juges :
   - a. `test-cockpit-terminal-session.sh:99` : `shell_de()` (`pgrep -P | sed -n 1p`) désigne désormais le GARDIEN, premier enfant de l'assistant. T12.2 et T12.3 observent donc le gardien en restant verts. Rétablir la désignation du shell. C'est à traiter en priorité : une assertion existante a changé de cible en silence.
   - b. Suite plantage : un témoin qui rougit si le gardien garde un fd 0/1/2/3 pendant son ménage. Mesure : la fin de fichier du serveur, avec un survivant têtu qui force la grâce de 3 s. La revue a mesuré 3,14 s de retard avec un mutant sans `dup2`, et la suite reste verte.
   - c. `dans-session=4` repose sur `ps -o sess=`, qui vaut 0 partout sous macOS : l'assertion est tautologique sur ce poste. Prouver la session par `os.getsid`.
   - d. Un mutant par étage du ménage (SIGHUP seul sans SIGKILL, contrôle getsid retiré) et un témoin hors session : un processus noté hors de la session doit survivre, et un mutant au ciblage trop large doit rougir.
   - e. Borne d'arrêt du gardien : la vérifier dans la suite.
   - f. Docstring : ajouter les limites signalées en no-op. Le chef non réapé par le gardien est visé par getsid seul. La borne de durée réelle dépend de `ps`. La fenêtre entre `pty.fork` et l'écriture de `SID` n'est pas couverte.
   - Commits par pathspec, avec un trailer `Gate-Touche:` pour chaque suite touchée.
2. Repasser devant un juge frais, scopé au diff de correction.
3. Rejouer le job `gates`, puis les suites cockpit `test-cockpit-terminal-*`.
4. Pousser, ouvrir la PR (ni merge, ni release, ni --admin) et suivre la CI jusqu'au vert. Sous Linux, le parsing de `ps -o pid=,ppid=,pgid=,sess=,tt=,stat=,command=` (procps ou uutils) n'est prouvé qu'en CI.
5. Prévenir la session principale par SendMessage.

## Pièges
- Le cwd des workers est hérité du worktree `phase-71-test4456` (cockpit de test, port 4456) : exiger un `cd` dans le worktree du correctif à chaque commande.
- Nettoyage des processus : uniquement par PID noté, jamais `pkill`, `killall` ni filtre awk.
- Le nœud de reproduction a duré 100 min, au-delà du TTL du verrou de 1 800 s : battre le cœur pendant les mandats longs.
